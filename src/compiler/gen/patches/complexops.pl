# complexops.pl: ~ of a complex value, its conjugate (GNU C's, glibc's
# conj): a copy in a temporary of the function's (two for complex long
# double's 32 bytes) whose imaginary part has its sign flipped, as gcc's
# negation does (the top bit of the part's last four bytes; little endian on
# every target). wgate gives a function that names a complex type its
# temporaries. After complex.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'unary',
    "        L1:\n          call\n            next\n          call\n            unary\n",
    "        L1:\n          call\n            next\n          call\n            unary\n" . asm(10, "
    li OP_inv t0
    beq rel:LCJ t0 s5
"),
    "        W2:\n          call\n            push\n          li\n            10\n            a0\n          li\n            1\n            a1\n          mv\n            s6\n            a2\n          call\n            wcall\n          j\n            L9\n",
    "        W2:\n          call\n            push\n          li\n            10\n            a0\n          li\n            1\n            a1\n          mv\n            s6\n            a2\n          call\n            wcall\n          j\n            L9\n" . asm(8, "
LCJ:
    call getty
    mv a0 s6
    call isstruct
    beqz L15 a0
    mv s6 a0
    call tsize
    mv a0 s7
    call wtemp
    mv a0 s8
    li 32 t0
    bne rel:LC1 t0 s7
    call wtemp
    mv a0 s8
    j LC1
LC1:
    neg s8 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s6 a0
    call copytype
    neg s8 a0
    add s7 a0 a0
    addi -4 a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    call push
    li TY_U32 a0
    call load
    li 1 a0
    slli 31 a0 a0
    li R_t0 a1
    call li
    la cc_cxor a0
    call seq
    call popt0
    li TY_U32 a0
    call store
    neg s8 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s6 a0
    call setty
    j L9
"));

# wgate: a leaf complex ... (a complex type) wants the temporaries, as
# long double does
my $l9 = "        L9:\n          lbu\n            NODE_children_len\n            s4\n            t1\n          bnez\n            LY\n            t1\n";
edit(\$t, 'wgate', $l9, $l9 . asm(10, "
    lbu NODE_content_len s4 t1
    li 12 t0
    bltu rel:LYL t0 t1
    ld NODE_content s4 t2
    lbu 0 t2 t4
    li 99 t0
    bne rel:LYL t0 t4
    lbu 1 t2 t4
    li 111 t0
    bne rel:LYL t0 t4
    lbu 6 t2 t4
    li 120 t0
    bne rel:LYL t0 t4
    lbu 7 t2 t4
    li 32 t0
    beq rel:L8 t0 t4
    j LYL
") . "        LYL:\n");

# the xor of a V and t0, cc_xor (V ^= t0)
once(\$t, "\n  cc_inv:\n", "\n  cc_cxor:\n    ascii\n      \\x00cc_xor\\x00\n  cc_inv:\n", 'cc_inv');
save();
