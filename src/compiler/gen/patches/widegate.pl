# widegate.pl: on arm, where a double is a value in memory, wgate gives
# temporaries to a function that names no double but has such a value: a
# hex float literal without a suffix (strtof's (float) (negative ? -0x0p+0 :
# 0x0p+0)), and the call of a function that returns one with arguments (a
# call without arguments is a leaf, which wgate looks up already). Test:
# cwgate.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'wgate', asm(10, "
    lbu NODE_children_len s4 t1
    bnez LY t1
    lbu NODE_content_len s4 t1
    li 12 t0
") => asm(10, "
    lbu NODE_children_len s4 t1
    bnez LN t1
    lbu NODE_content_len s4 t1
    li 12 t0
"), asm(10, "
    li 76 t0
    bne rel:LY t0 t4
    lbu 0 t2 t4
    li 48 t0
    beq rel:L8 t0 t4
    j LY
") => asm(10, "
    li 76 t0
    bne rel:LD t0 t4
    lbu 0 t2 t4
    li 48 t0
    beq rel:L8 t0 t4
    j LY
") . asm(8, "
LD:
    call slot
    li 4 t0
    bne rel:LY t0 a0
    lbu NODE_content_len s4 t1
    ld NODE_content s4 t2
    add t1 t2 t3
    lbu -1 t3 t4
    li 102 t0
    beq rel:LY t0 t4
    lbu 0 t2 t4
    li 48 t0
    bne rel:LY t0 t4
    lbu 1 t2 t4
    li 120 t0
    bne rel:LY t0 t4
LP:
    bgeu rel:LY t3 t2
    lbu 0 t2 t4
    li 112 t0
    beq rel:L8 t0 t4
    addi 1 t2 t2
    j LP
LN:
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call find_label
    beqz LY a0
    lbu NODE_children_len a0 t0
    beqz LY t0
    ld NODE_children a0 t1
    slli 3 t0 t0
    add t0 t1 a1
    mv t1 a0
    call typerun
    bltz LY a0
    call fwidev
    bnez L8 a0
    j LY
"));
save();
