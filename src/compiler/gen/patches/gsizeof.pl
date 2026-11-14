# gsizeof.pl: a sizeof or an alignof is an item of a global, as in C.
# kind took a page item whose item with children is none of :, items, a
# cast's type and value, a suffix or what comes before & address for a
# function, so a global written g: / sv / sizeof / slot0 / slot0 (gnulib
# quotearg.c's slotvec0 = { sizeof slot0, slot0 }, glibc nptl's
# _thread_db_sizeof_*) was silently code: its bytes instructions, g / val
# a call ("unknown name: val"), &g the address of that code. Now kind
# keeps such an item a global where it holds a sizeof or an alignof, which
# a global's items work out while compiling as they do : / sizeof / slot0
# (the user's choice, 2026-11-14; csema still writes the : form). And gval
# takes a - before an item with children (- / sizeof / sv) as the negated
# value of that item; constval had made -1 of it. Test cgsizeof (4
# targets: both forms the same bytes, read as fields, g / val, a -).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/kind', asm(10, "
LN:
    ld -8 s5 a0
    call kwof
    li KW_address t0
    beq rel:L2 t0 a0
") => asm(10, "
LN:
    ld -8 s5 a0
    call kwof
    li KW_address t0
    beq rel:L2 t0 a0
    li KW_sizeof t0
    beq rel:L2 t0 a0
    li KW_alignof t0
    beq rel:L2 t0 a0
"));
edit(\$t, 'cc/gval', asm(8, "
L50:
    mv s5 a0
    call opof
    li OP_sub t0
    bne rel:L3 t0 a0
    ld 8 s4 a0
    call constval
    neg a0 a0
    addi 16 s4 a1
    j L9
") => asm(8, "
L50:
    mv s5 a0
    call opof
    li OP_sub t0
    bne rel:L3 t0 a0
    ld 8 s4 a0
    lbu NODE_children_len a0 t0
    bnez GN6 t0
    call constval
    neg a0 a0
    addi 16 s4 a1
    j L9
GN6:
    addi 8 s4 a0
    mv s7 a1
    call gval
    neg a0 a0
    j L9
"));
save();
