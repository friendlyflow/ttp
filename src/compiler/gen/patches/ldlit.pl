# ldlit.pl: a long double literal, C's L after an exact hex float (the
# user's choice, 2026-10-19): 0x1.921fb54442d18469898cc51701b8p+1L is M_PIl,
# binary128's 113 bits; 0x0.<digits>p-16382L a subnormal, 0x0p+0L zero.
# hexf reads it into two words: the low one is its value (a0), the high one
# (sign, exponent, the fraction's top 48 bits) goes to cc_ldhi, with
# cc_ldhi + 8 set to say a literal left it there. wlit writes all 16 bytes
# into the temporary of a long double value; gstore, for a long double
# global, the high word after the low; wgate gives a function with such a
# literal its temporaries, as it does one that names long double.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# hexf: a literal ending with L is the long double one
edit(\$t, 'hexf',
    "        add\n          a0\n          a1\n          s5\n",
    "        add\n          a0\n          a1\n          s5\n" . asm(8, "
    lbu -1 s5 t0
    li 76 t1
    beq rel:LL t1 t0
"),
    "        L8:\n          li\n            0\n            a1\n          leave8\n",
    "        L8:\n          li\n            0\n            a1\n          leave8\n" . asm(8, "
LL:
    # 0x, then the leading digit, 0 or 1 (s10), then . and at most 28 hex
    # digits: the first 12 the high word's fraction (s6), the rest the low
    # word (s7); s8 counts them
    addi -1 s5 s5
    lbu 0 s4 t0
    li 48 t1
    bne rel:L8 t1 t0
    lbu 1 s4 t0
    li 32 t1
    or t1 t0 t0
    li 120 t1
    bne rel:L8 t1 t0
    lbu 2 s4 s10
    addi -48 s10 s10
    li 1 t1
    bltu rel:L8 s10 t1
    addi 3 s4 s4
    li 0 s6
    li 0 s7
    li 0 s8
    bgeu rel:L8 s5 s4
    lbu 0 s4 t0
    li 46 t1
    bne rel:LM t1 t0
    addi 1 s4 s4
    j LM
LM:
    bgeu rel:L8 s5 s4
    lbu 0 s4 t0
    li 112 t1
    beq rel:LP t1 t0
    addi -48 t0 t3
    li 10 t1
    bltu rel:LN t1 t3
    li 32 t2
    or t0 t2 t2
    addi -97 t2 t3
    li 6 t1
    bgeu rel:L8 t1 t3
    addi 10 t3 t3
    j LN
LN:
    li 28 t1
    bgeu rel:L8 t1 s8
    li 12 t1
    bgeu rel:LO t1 s8
    slli 2 s8 t4
    li 44 t5
    sub t4 t5 t5
    sll t5 t3 t3
    or t3 s6 s6
    addi 1 s8 s8
    addi 1 s4 s4
    j LM
LO:
    addi -12 s8 t4
    slli 2 t4 t4
    li 60 t5
    sub t4 t5 t5
    sll t5 t3 t3
    or t3 s7 s7
    addi 1 s8 s8
    addi 1 s4 s4
    j LM
LP:
    # p, a sign, the exponent in decimal (s9), up to the L
    addi 1 s4 s4
    li 0 s9
    li 0 t6
    bgeu rel:L8 s5 s4
    lbu 0 s4 t0
    li 45 t1
    bne rel:LQ t1 t0
    li 1 t6
    addi 1 s4 s4
    j LR
LQ:
    li 43 t1
    bne rel:LR t1 t0
    addi 1 s4 s4
    j LR
LR:
    li 0 a2
    j LS
LS:
    bgeu rel:LT s5 s4
    lbu 0 s4 t0
    addi -48 t0 t3
    li 10 t1
    bgeu rel:L8 t1 t3
    mul t1 s9 s9
    add t3 s9 s9
    addi 1 a2 a2
    addi 1 s4 s4
    j LS
LT:
    beqz L8 a2
    beqz LU t6
    neg s9 s9
    j LU
LU:
    # 1.f: the exponent biased by 16383, 1 to 32766; 0.f: a subnormal,
    # p-16382, or zero, p+0
    li 1 t1
    bne rel:LV t1 s10
    li32 16383 t0
    add t0 s9 t0
    blez L8 t0
    li32 32767 t1
    bgeu rel:L8 t1 t0
    slli 48 t0 t0
    or t0 s6 s6
    j LW
LV:
    or s6 s7 t0
    beqz LZ t0
    li32 16382 t1
    add t1 s9 t1
    bnez L8 t1
    j LW
LZ:
    bnez L8 s9
    j LW
LW:
    la cc_ldhi t0
    sd 0 s6 t0
    li 1 t1
    sd 8 t1 t0
    mv s7 a0
    li TY_LDOUBLE s11
    j L30
"));

# wlit: a long double's temporary gets the high word too (cc_ldhi), at +8
edit(\$t, 'wlit',
    "          neg\n            s6\n            a0\n          li\n            R_a0\n            a1\n          call\n            li\n          la\n            cc_add_s0\n            a0\n          call\n            seq\n          mv\n            s5\n            a0\n          call\n            setty\n          leave3\n",
    asm(10, "
    li TY_LDOUBLE t0
    beq rel:LH t0 s5
    j LK
") . asm(8, "
LH:
    la cc_ldhi t0
    sd 8 zero t0
    ld 0 t0 a0
    slli 32 a0 a0
    srli 32 a0 a0
    li R_a0 a1
    call li
    neg s6 a0
    addi 8 a0 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    li TY_U32 a0
    call store
    la cc_ldhi t0
    ld 0 t0 a0
    srli 32 a0 a0
    li R_a0 a1
    call li
    neg s6 a0
    addi 12 a0 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    li TY_U32 a0
    call store
    j LK
LK:
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s5 a0
    call setty
    leave3
"));

# gstore: a long double global's high word, after its low one
edit(\$t, 'gstore',
    "        call\n          gput\n        mv\n          s7\n          a0\n        leave5\n        L1:\n",
    "        call\n          gput\n" . asm(8, "
    li TY_LDOUBLE t0
    beq rel:LH t0 s4
    j LK
LH:
    la cc_ldhi t0
    ld 8 t0 t1
    beqz LK t1
    sd 8 zero t0
    ld 0 t0 a1
    addi 8 s5 a0
    li 8 a2
    call gput
    j LK
LK:
    mv s7 a0
    leave5
") . "        L1:\n");

# wgate: a long double literal wants the temporaries as long double does
# (a leaf 0x...L, found where a leaf is about to give 0)
edit(\$t, 'wgate',
    "        L9:\n          li\n            0\n            a0\n          leave3\n        L8:\n          li\n            1\n            a0\n          leave3\n",
    asm(8, "
L9:
    lbu NODE_children_len s4 t1
    bnez LY t1
    lbu NODE_content_len s4 t1
    li 4 t0
    bltu rel:LY t0 t1
    ld NODE_content s4 t2
    add t1 t2 t4
    lbu -1 t4 t4
    li 76 t0
    bne rel:LY t0 t4
    lbu 0 t2 t4
    li 48 t0
    beq rel:L8 t0 t4
    j LY
") . "        L8:\n          li\n            1\n            a0\n          leave3\n" . asm(8, "
LY:
    li 0 a0
    leave3
"));

# ginit: a long double global is no aggregate here: its one item, a
# literal, goes through gstore
edit(\$t, 'ginit',
    "        call\n          isagg\n        bnez\n          L41\n          a0\n",
    "        call\n          isagg\n" . asm(8, "
    li TY_LDOUBLE t0
    xor s4 t0 t1
    sltu t1 zero t1
    and t1 a0 a0
") . "        bnez\n          L41\n          a0\n");

# cc_ldhi: the high word of the last long double literal, and its flag
once(\$t, "\n  ccs:\n", "\n  cc_ldhi:\n    reserve\n      16\n  ccs:\n", 'ccs');
save();
