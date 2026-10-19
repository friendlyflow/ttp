# pairs3.pl: the rest of i64 and u64 on arm (pairs.pl, pairs2.pl): their
# conversions to and from float and double (ptof, ftop, by arm's
# cc_cvt_*_p primitives), a switch on a pair (its value two slots, each
# case's value too), and long double as double on a target whose word is 4
# bytes, as the arm EABI has it (gcc's long double there is double): the
# type word long double is the code of double there, outside compile time.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# long double is double where the word is 4 bytes
E('cc/tyname', 8, "
    call lookup
    bltz L1 a0
", "
    call lookup
    bltz L1 a0
    li 17 t0
    beq rel:LD t0 a0
");
{
    my ($from, $to) = find(\$t, 'cc/tyname');
    substr($t, $to, 0) = asm(8, "
        LD:
        la ccs t0
        ld CC_jit t0 t0
        bnez L3 t0
        la targ_word t0
        ld 0 t0 t0
        li 8 t1
        beq rel:L3 t1 t0
        li 40 a0
        leave1
    ");
}

# conversions between a pair and a floating type
E('cc/pconvf', 8, "
    L1:
    li 1 a0
    bnez L9 s6
    mv s4 a0
    li 0 a1
    call pext
    li 1 a0
", "
    L1:
    li 1 a0
    bnez L9 s6
    mv s4 a0
    call tscalar
    andi 32 a0 t0
    bnez L7 t0
    mv s4 a0
    li 0 a1
    call pext
    li 1 a0
");
E('cc/pconvf', 8, "
    L8:
    li 0 a0
    call bad
", "
    L8:
    mv s4 a0
    mv s5 a1
    call ptof
    li 1 a0
    leave3
    L7:
    mv s4 a0
    mv s5 a1
    call ftop
    li 1 a0
    leave3
");

# a switch on a pair: its value two slots, a case's value pushed as its type
E('cc/switch', 8, "
    call getty
    call promote
    mv a0 s4
    call push
", "
    call getty
    call promote
    mv a0 s4
    mv s4 a0
    call pushv
");
E('cc/switch', 10, "
    li 1 a0
    call popped
", "
    call swpop
");
E('cc/case', 8, "
    call getty
    mv a0 s8
    call push
", "
    call getty
    mv a0 s8
    mv s8 a0
    call pushv
");
E('cc/case', 8, "
    call load
    call popt0
    call dotsnext
", "
    call load
    mv s8 a0
    call popv
    call dotsnext
");
E('cc/casehi', 8, "
    call getty
    mv a0 s4
    call push
", "
    call getty
    mv a0 s4
    mv s4 a0
    call pushv
");
E('cc/casehi', 8, "
    call load
    call popt0
", "
    call load
    mv s4 a0
    call popv
");

# a system call's arguments are words: a pair converts to its low word
# (ptype's callee 1: every parameter a long)
E('cc/syscall', 8, "
    li 0 a1
    call args
", "
    li 1 a1
    call args
");
E('cc/ptype', 8, "
    beqz L8 s4
", "
    beqz L8 s4
    li 1 t0
    beq rel:LW t0 s4
");
{
    my ($from, $to) = find(\$t, 'cc/ptype');
    substr($t, $to, 0) = asm(8, "
        LW:
        li TY_LONG a0
        leave5
    ");
}

my $h = '';
# ptof a0 a1: V, a pair of type a0, converted to the floating type a1
$h .= fn('ptof', "
    enter2
    mv a0 s4
    mv a1 s5
    andi 16 s4 s4
    mv s5 a0
    call fwide
    la cc_ptofs t1
    beqz L2 a0
    call wtemp
    neg a0 a0
    li R_t1 a1
    call li
    la cc_ptofd t1
    L2:
    srli 4 s4 t0
    slli 4 t0 t0
    add t0 t1 a0
    call seq
    leave2
", 6);
# ftop a0 a1: V, of the floating type a0, converted to the pair type a1
$h .= fn('ftop', "
    enter2
    mv a0 s4
    mv a1 s5
    andi 16 s5 s5
    mv s4 a0
    call fwide
    la cc_ftops t1
    beqz L1 a0
    la cc_ftopd t1
    L1:
    srli 4 s5 t0
    slli 4 t0 t0
    add t0 t1 a0
    call seq
    leave2
", 6);
# swpop: the end of a switch, its value's slots popped
$h .= fn('swpop', "
    enter1
    la ccs t0
    ld CC_swty t0 a0
    call ispair
    addi 1 a0 a0
    call popped
    leave1
", 6);
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
for my $x (['cc_ptofs', 'cc_cvt_s_p', 'cc_cvt_s_pu'], ['cc_ptofd', 'cc_cvt_dm_p', 'cc_cvt_dm_pu'],
           ['cc_ftops', 'cc_cvt_p_s', 'cc_cvt_pu_s'], ['cc_ftopd', 'cc_cvt_p_dm', 'cc_cvt_pu_dm']) {
    my ($label, @names) = @$x;
    $h .= "      $label:\n        ascii\n          " . esc(join '', map { pack 'a16', "\0$_" } @names) . "\n";
}
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $h;
}
save();
