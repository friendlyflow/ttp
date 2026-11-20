# fltinc.pl: ++ and -- on a floating variable (float, double, long double,
# float16, bfloat16) add 1 or -1 in its type. unary's L13A added the
# integer 1 to the value's bits (addxv): x ++ was x plus one ulp (coreutils'
# seq, for (long double i = 1; ; i++), kept i at 1 and printed one number
# without end on x86_64), and x -- one ulp less (right by chance after a
# truncation to an integer, for float and double in registers; not for the
# values in memory, x86_64's long double and arm's double). Now a floating
# lvalue (fltty) takes LFI: new = (+-1) + old by binop, the int in X as a
# popped left operand is, then the assignment's tail (wassign, pwassign, the
# address popped, copytype for a value in memory, else store). Postfix keeps
# a copy of old (old - 0, exact, -0 too; a value in memory gets a temporary
# of its own) under the address (the address moved to V by A + 0), and its
# value is that copy - 0. wcount and wscan count 128 bytes of temporaries for ++ and
# -- (three binops of a value in memory and their conversions of the int), not 16.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'unary', asm(8, "
L13A:
    call getty
    mv a0 s6
    call push
") => asm(8, "
L13A:
    call getty
    mv a0 s6
    call push
    mv s6 a0
    call fltty
    bnez LFI a0
"), asm(8, "
L9:
    leave5
") => asm(8, "
L9:
    leave5
LFI:
    mv s6 a0
    call load
    beqz LF2 s7
    mv s6 a0
    call pushv
    li 0 a0
    li R_a0 a1
    call li
    mv s6 a0
    call popv
    li OP_sub a0
    mv s6 a1
    li TY_INT a2
    call binop
    call popt0
    mv s6 a0
    call pushv
    li 0 a0
    li R_a0 a1
    call li
    li OP_add a0
    li TY_LONG a1
    li TY_LONG a2
    call binop
    call push
    mv s6 a0
    call load
LF2:
    li 1 a0
    li OP_dec t0
    bne rel:LF3 t0 s5
    li -1 a0
LF3:
    li R_t0 a1
    call li
    li OP_add a0
    li TY_INT a1
    mv s6 a2
    call binop
    mv s6 a0
    call wassign
    mv s6 a0
    call pwassign
    call popt0
    mv s6 a0
    call inmem
    bnez LF4 a0
    mv s6 a0
    call store
    j LF5
LF4:
    mv s6 a0
    call copytype
LF5:
    beqz L14 s7
    mv s6 a0
    call popv
    li 0 a0
    li R_a0 a1
    call li
    li OP_sub a0
    mv s6 a1
    li TY_INT a2
    call binop
    j L14
"));
edit(\$t, 'wcount', asm(8, "
    call opof
    bgez L8 a0
") => asm(8, "
    call opof
    bltz LW0 a0
    li OP_inc t0
    beq rel:LW4 t0 a0
    li OP_dec t0
    beq rel:LW4 t0 a0
    j L8
LW4:
    li 128 a0
    leave1
LW0:
"));
edit(\$t, 'wscan', asm(8, "
    call opof
    bgez W9 a0
    li 16 s6
") => asm(8, "
    call opof
    bltz WQ0 a0
    li OP_inc t0
    beq rel:WQ t0 a0
    li OP_dec t0
    bne rel:W9 t0 a0
WQ:
    li 128 s6
    j W9
WQ0:
    li 16 s6
"));
{
    my ($from, $to) = find(\$t, 'is_layer');
    my $f = fn('fltty', "
    lui TY_REC t0
    bgeu rel:Y9 t0 a0
    andi 256 a0 t0
    bnez Y9 t0
    andi 32 a0 a0
    sltu a0 zero a0
    ret
Y9:
    li 0 a0
    ret
");
    $f =~ s/^(.*\n)/$1    comment\n      1 if the type a0 is a floating one (float, double, long double, float16, bfloat16: a scalar with 32 set, no fixed point), else 0\n/;
    substr($t, $to, 0) = $f;
}
save();
