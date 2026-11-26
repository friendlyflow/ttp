# gcvt.pl: a global's value converts to its type as a cast does (the
# user's choice A, 2026-11-24): gi: i64 / 0x1.8p+1 is 3 (toward zero), gd:
# double / 7 is 7.0; gval kept the literal's bits (a double's in an i64, an
# integer's in a double). Now where gval takes a floating literal (hexf: its
# kind, 36 float or 40 double) for a scalar integer type, f2int truncates
# it; where it takes an integer constant (constval) for float or double,
# int2f makes its bits, rounded to nearest, ties to even, as C's
# conversion. Test: progs/ccmpdcvt.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/gval',
    "          call\n            hexf\n          beqz\n            L50\n            a1\n" =>
    "          call\n            hexf\n          beqz\n            L50\n            a1\n" . asm(10, "
    li 36 t0
    beq rel:LQI t0 a1
    li 40 t0
    bne rel:LQJ t0 a1
") . asm(8, "
LQI:
    addi -16 sp sp
    sd 0 a0 sp
    sd 8 a1 sp
    mv s7 a0
    call gcvtint
    mv a0 t0
    ld 0 sp a0
    ld 8 sp a1
    addi 16 sp sp
    beqz LQJ t0
    call f2int
    li 1 a1
LQJ:
    mv a1 a1
"),
    "        L30:\n          mv\n            s5\n            a0\n          call\n            constval\n" =>
    "        L30:\n          mv\n            s5\n            a0\n          call\n            constval\n" . asm(10, "
    li 36 t0
    beq rel:LQF s7 t0
    li 40 t0
    bne rel:LQG s7 t0
") . asm(8, "
LQF:
    mv s7 a1
    call int2f
LQG:
    mv a0 a0
"));

my ($from, $to) = find(\$t, 'cc/gval');
substr($t, $to, 0) = join '',
  "      comment\n        gcvtint: 1 if the type a0 is a scalar integer one (no address, no floating type), else 0\n",
  fn('gcvtint', "
    enter1
    mv a0 s4
    lui TY_REC t0
    bgeu rel:L8 t0 s4
    call fltty
    bnez L8 a0
    mv s4 a0
    call isaddr
    bnez L8 a0
    li 1 a0
    leave1
L8:
    li 0 a0
    leave1
", 6),
  "      comment\n        f2int: the integer of the float (a1 36) or double (a1 40) bits a0, toward zero\n",
  fn('f2int', "
    li 52 t3
    li32 1023 t4
    li32 2047 t5
    li 63 t6
    li 40 t1
    beq rel:F1 t1 a1
    li 23 t3
    li 127 t4
    li 255 t5
    li 31 t6
F1:
    srl t6 a0 a2
    andi 1 a2 a2
    srl t3 a0 t0
    and t5 t0 t0
    bltu rel:FZ t4 t0
    sub t4 t0 t0
    li 1 t1
    sll t3 t1 t1
    addi -1 t1 t2
    and t2 a0 t2
    or t1 t2 t2
    bltu rel:F3 t0 t3
    sub t0 t3 t1
    srl t1 t2 a0
    j F4
F3:
    sub t3 t0 t1
    sll t1 t2 a0
F4:
    beqz F9 a2
    neg a0 a0
F9:
    ret
FZ:
    li 0 a0
    ret
", 6),
  "      comment\n        int2f: the float (a1 36) or double (a1 40) bits of the integer a0, rounded to nearest, ties to even\n",
  fn('int2f', "
    beqz Z9 a0
    li 0 t6
    bgez P1 a0
    li 1 t6
    neg a0 a0
P1:
    mv a0 t0
    li 63 t2
P2:
    bltz P3 t0
    slli 1 t0 t0
    addi -1 t2 t2
    j P2
P3:
    li 52 t3
    li32 1023 t4
    li 40 t5
    beq rel:P4 t5 a1
    li 23 t3
    li 127 t4
P4:
    bltu rel:P6 t2 t3
    sub t2 t3 t5
    sll t5 a0 t0
    j P8
P6:
    sub t3 t2 t5
    srl t5 a0 t0
    li 1 t1
    sll t5 t1 t1
    addi -1 t1 t1
    and t1 a0 t1
    addi -1 t5 a2
    li 1 a3
    sll a2 a3 a3
    bltu rel:P8 a3 t1
    bne rel:P7 t1 a3
    andi 1 t0 a2
    beqz P8 a2
P7:
    addi 1 t0 t0
    addi 1 t3 a2
    srl a2 t0 a3
    beqz P8 a3
    srli 1 t0 t0
    addi 1 t2 t2
P8:
    li 1 a2
    sll t3 a2 a2
    addi -1 a2 a2
    and a2 t0 t0
    add t4 t2 t2
    sll t3 t2 t2
    or t2 t0 a0
    beqz Z9 t6
    li 63 t1
    li 40 t5
    beq rel:P9 t5 a1
    li 31 t1
P9:
    li 1 a2
    sll t1 a2 a2
    or a2 a0 a0
Z9:
    ret
", 6);
save();
