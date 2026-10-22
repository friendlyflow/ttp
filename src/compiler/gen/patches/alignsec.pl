# alignsec.pl: a global of a section may have its align first, before
# section and its name (test-string.h's IMPL entries are aligned to a
# word): secdefer, secis and secentry look past it (secpos), and its
# __start_ is placed as aligned as its first global (secplace). Run on ttpc.ff after
# align.pl. Test: calignattr.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# (the first child section, the name after it: t1 that name's node, else to $no)
sub check { my ($no) = @_; asm(8, "
    mv s4 a0
    call secpos
    li 3 t1
    bltu rel:$no t1 a1
    addi -16 sp sp
    sd 0 a0 sp
    ld 0 a0 a0
    call kwof
    ld 0 sp t0
    addi 16 sp sp
    li KW_section t1
    bne rel:$no t1 a0
    ld 8 t0 t1
") }
edit(\$t, 'cc/secdefer',
    "        mv\n          s4\n          a0\n        call\n          defkw\n        li\n          KW_section\n          t0\n        bne\n          rel\n            D8\n          t0\n          a0\n        lbu\n          NODE_children_len\n          s4\n          t0\n        li\n          3\n          t1\n        bltu\n          rel\n            D8\n          t1\n          t0\n        ld\n          NODE_children\n          s4\n          t0\n        ld\n          8\n          t0\n          t1\n",
    check('D8'));
edit(\$t, 'cc/secis',
    "        lbu\n          NODE_children_len\n          s4\n          t0\n        li\n          3\n          t1\n        bltu\n          rel\n            S8\n          t1\n          t0\n        mv\n          s4\n          a0\n        call\n          defkw\n        li\n          KW_section\n          t0\n        bne\n          rel\n            S8\n          t0\n          a0\n        ld\n          NODE_children\n          s4\n          t0\n        ld\n          8\n          t0\n          t1\n",
    check('S8'));
# secentry: the type of the bounds after section and its name, past an align
edit(\$t, 'cc/secentry',
    "          ld\n            NODE_children\n            s10\n            a0\n          lbu\n            NODE_children_len\n            s10\n            t1\n          slli\n            3\n            t1\n            t1\n          add\n            t1\n            a0\n            a1\n          addi\n            16\n            a0\n            a0\n",
    asm(10, "
    mv s10 a0
    call secpos
    slli 3 a1 t1
    add t1 a0 a1
    addi 16 a0 a0
"));
# secplace: __start_ as aligned as the section's first global (ld aligns the
# section to its most aligned input)
edit(\$t, 'cc/secplace',
    "          addi\n            32\n            s6\n            a0\n          call\n            cc\n",
    asm(10, "
    ld 16 s6 a0
    call gdalign
    la cur_pc t0
    ld 0 t0 t0
    remu a0 t0 t1
    beqz SAP t1
    sub t1 a0 a0
    call skip
") . "          SAP:\n" . asm(10, "
    addi 32 s6 a0
    call cc
"));
my $fns = cfn('secpos', "the children of definition a0 past an align first: a0 where they start, a1 how many", "
    enter1
    mv a0 s4
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call alskip
    ld NODE_children s4 t0
    lbu NODE_children_len s4 a1
    sub t0 a0 t0
    srli 3 t0 t0
    sub t0 a1 a1
    leave1
", 6);
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $fns;
save();
