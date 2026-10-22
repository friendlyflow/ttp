# align.pl: C's aligned attribute (the user's choice, 2026-10-22): the word
# align with n under it, written first,
#
#   __f:                  pthread:            buf:
#     align                 struct              align
#       16                  align                 16
#     array                   32                array
#       u64                 header:               char
#       64                    ...                 1024
#
# under a field before its type (the field at a multiple of n, its record
# as aligned as n at least), right after struct or union for the record's
# own alignment (its size a multiple of it), and under a global before its
# type (placed at a multiple of n). It only raises an alignment, as C's
# does. typerun and tlskip pass over it (alskip), fields lays the record
# out with it (fldalign, and a record's own align is no field: alval),
# places counts no place for it, and the placement of a global aligns to it
# (gdalign). riscv's mcontext_t is 16-aligned by its fpregs' __f, so
# ucontext_t's uc_mcontext is at 176, where glibc's swapcontext has it
# (tst-xmemset-opt). align is matched by its text: glibc names variables
# align too. Test: calignattr.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

once(\$t, "\n  gen_words:\n", "\n  al_word:\n    ascii\n      align\n  gen_words:\n", 'gen_words');

# typerun and tlskip: past an align first
my $moves = "        mv\n          a0\n          s4\n        mv\n          a1\n          s5\n";
edit(\$t, 'cc/typerun', "        enter5\n$moves", "        enter5\n$moves" . asm(8, "
    call alskip
    mv a0 s4
"));
edit(\$t, 'cc/tlskip', "        enter2\n$moves", "        enter2\n$moves" . asm(8, "
    call alskip
    mv a0 s4
"));

# fields: a record's own align raises its alignment (s10), and is no field;
# a field's align raises the field's
edit(\$t, 'cc/fields',
    "        L1:\n          beqz\n            L8\n            s7\n", asm(8, "
L1:
    beqz L8 s7
    mv s8 a0
    addi 8 s8 a1
    call alval
    beqz LA1 a0
    bgeu rel:LA0 a0 s10
    mv a0 s10
LA0:
    addi 8 s8 s8
    addi -1 s7 s7
    j L1
LA1:
"),
    "        U1:\n          beqz\n            U8\n            s7\n", asm(8, "
U1:
    beqz U8 s7
    mv s8 a0
    addi 8 s8 a1
    call alval
    beqz UA1 a0
    bgeu rel:UA0 a0 s10
    mv a0 s10
UA0:
    addi 8 s8 s8
    addi -1 s7 s7
    j U1
UA1:
"),
    "        L11:\n          ld\n            72\n            sp\n            a0\n          call\n            talign\n",
    "        L11:\n          ld\n            72\n            sp\n            a0\n" . asm(10, "
    ld 0 s8 a1
    call fldalign
"),
    "          bnez\n            L12\n            a0\n          ld\n            72\n            sp\n            a0\n          call\n            talign\n",
    "          bnez\n            L12\n            a0\n          ld\n            72\n            sp\n            a0\n" . asm(10, "
    ld 0 s8 a1
    call fldalign
"),
    "          sd\n            72\n            a0\n            sp\n          call\n            talign\n          ble\n            U2\n",
    "          sd\n            72\n            a0\n            sp\n" . asm(10, "
    ld 0 s8 a1
    call fldalign
") . "          ble\n            U2\n");

# places: a record's own align is no place
edit(\$t, 'cc/places', "        R1:\n          bgeu\n            rel\n              R9\n            s4\n            s6\n",
    "        R1:\n          bgeu\n            rel\n              R9\n            s4\n            s6\n" . asm(10, "
    mv s6 a0
    addi 8 s6 a1
    call alval
    bnez R3 a0
"));

# a global's placement: aligned to its align too
once(\$t, "      call\n        dtype\n      call\n        talign\n      la\n        cur_pc\n",
    "      call\n        gdalign\n      la\n        cur_pc\n", 'global placement');

my $fns = cfn('alval', "the n of an align node at a0 (a1 the end of its run): align with one child, a number; else 0", "
    enter2
    mv a0 s4
    li 0 s5
    bgeu rel:V9 a1 s4
    ld 0 s4 s4
    lbu NODE_children_len s4 t0
    li 1 t1
    bne rel:V9 t1 t0
    lbu NODE_content_len s4 a1
    li 5 t1
    bne rel:V9 t1 a1
    ld NODE_content s4 a0
    la al_word a2
    li 5 a3
    call streq
    beqz V9 a0
    ld NODE_children s4 t0
    ld 0 t0 t0
    lbu NODE_children_len t0 t1
    bnez V9 t1
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call parse_num
    beqz V9 a1
    mv a0 s5
V9:
    mv s5 a0
    leave2
", 6)
. cfn('alskip', "the run at a0 (a1 its end) past an align first: a0", "
    enter1
    mv a0 s4
    call alval
    beqz K9 a0
    addi 8 s4 s4
K9:
    mv s4 a0
    leave1
", 6)
. cfn('fldalign', "the alignment of type a0 as field a1 has it: raised to its align", "
    enter2
    mv a1 s4
    call talign
    mv a0 s5
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call alval
    bgeu rel:F1 a0 s5
    mv a0 s5
F1:
    mv s5 a0
    leave2
", 6)
. cfn('gdalign', "the alignment of global a0: its type's, raised to its align", "
    enter1
    mv a0 s4
    call dtype
    mv s4 a1
    call fldalign
    leave1
", 6);
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $fns;
save();
