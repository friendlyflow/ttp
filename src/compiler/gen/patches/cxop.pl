# cxop.pl: an operator of two operands with a complex one stops, with a
# message: ttpc has no complex + - * / == != (the master's plan,
# 2026-11-18), and took the records' words as numbers: riscv64's l + m was
# silently wrong, arm's crashed. C's complex operators are csema's, written
# of the parts (real, imag, libgcc's __mulXc3 and __divXc3, as gcc calls
# them). cxty: a type that is a complex type's record (complexty.pl's
# cx_nodes, complexq.pl's cxn_q: its definition). Test: ccxopfail
# (ctime, every target). After complexty.pl and complexq.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
my $msg = "ttpc: a complex value as an operand: C's complex + - * / == != are csema's, written of the parts (real, imag, libgcc's __mulXc3 and __divXc3)";

{
    my ($from) = find(\$t, 'binop');
    substr($t, $from, 0) = fn('cxty', "
    # a0 a type: 1 a complex type's record, else 0
    lui TY_REC t0
    bltu rel:L1 t0 a0
    ld TY_base a0 t1
    la cx_nodes t0
    ld 0 t0 t2
    beq rel:L2 t2 t1
    ld 8 t0 t2
    beq rel:L2 t2 t1
    ld 16 t0 t2
    beq rel:L2 t2 t1
    la cxn_q t2
    beq rel:L2 t2 t1
L1:
    li 0 a0
    ret
L2:
    li 1 a0
    ret
", 6);
}

edit(\$t, 'binop', asm(8, "
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call fxbin
") => asm(8, "
    mv s5 a0
    call cxty
    bnez LCXO a0
    mv s6 a0
    call cxty
    bnez LCXO a0
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call fxbin
"));
{
    my ($from, $to) = find(\$t, 'binop');
    substr($t, $to, 0) = asm(8, "
LCXO:
    la msg_cxop a1
    li " . length($msg) . " a2
    li 0 a4
    j die_name
");
}
once(\$t, "      msg_type:\n", "      msg_cxop:\n        ascii\n          " . esc($msg) . "\n      msg_type:\n", 'msg_type');
save();
