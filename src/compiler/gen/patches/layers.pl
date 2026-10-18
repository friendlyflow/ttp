# layers.pl: a function whose name is only digits (0: 1: 2: ...) is a
# layer, the overflow of its parent past the 255 children a node holds: its
# children count as the parent's, in every scope, layers inside layers too
# (the user's rule, 2026-10-18). find_label scans a scope's children with
# lfind, which looks through each layer it meets (depth checked against
# MAX_DEPTH); a layer itself is never a name. A layer is still placed as a
# label, its children where they stand, so the code is the same.
our $t; do "$ENV{PATCHLIB}" or die $@;
my ($from, $to) = find(\$t, 'find_label');
substr($t, $from, $to - $from) = fn('find_label', "
    addi -48 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    sd 40 s8 sp
    mv a0 s4
    mv a1 s5
    la scope_depth t0
    ld 0 t0 t0
    slli 3 t0 t0
    la scopes s6
    add t0 s6 s6
    L1:
    la scopes t0
    beq rel:L4 t0 s6
    addi -8 s6 s6
    ld 0 s6 a0
    li 0 a1
    call lfind
    beqz L1 a0
    j L5
    L4:
    li 0 a0
    L5:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    ld 40 sp s8
    addi 48 sp sp
    ret
", 0) . fn('lfind', "
    addi -32 sp sp
    sd 0 ra sp
    sd 8 s6 sp
    sd 16 s7 sp
    sd 24 s8 sp
    mv a1 s6
    lbu NODE_children_len a0 s7
    ld NODE_children a0 s8
    F1:
    beqz F4 s7
    ld 0 s8 a0
    call is_fn
    beqz F3 a0
    ld 0 s8 t0
    ld NODE_content t0 t1
    lbu NODE_content_len t0 t2
    addi -1 t2 t2
    beqz F2 t2
    li 10 t4
    G1:
    lbu 0 t1 t3
    addi -48 t3 t3
    bgeu rel:F2 t4 t3
    addi 1 t1 t1
    addi -1 t2 t2
    bnez G1 t2
    li MAX_DEPTH t4
    bgeu rel:F6 t4 s6
    mv t0 a0
    addi 1 s6 a1
    call lfind
    beqz F3 a0
    j F5
    F2:
    ld 0 s8 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    addi -1 a3 a3
    mv s4 a0
    mv s5 a1
    call streq
    beqz F3 a0
    ld 0 s8 a0
    j F5
    F3:
    addi 8 s8 s8
    addi -1 s7 s7
    j F1
    F4:
    li 0 a0
    F5:
    ld 0 sp ra
    ld 8 sp s6
    ld 16 sp s7
    ld 24 sp s8
    addi 32 sp sp
    ret
    F6:
    la msg_depth a1
    li msg_depth_len a2
    ld 0 s8 t0
    ld NODE_content t0 a3
    lbu NODE_content_len t0 a4
    j die_name
", 2);
once(\$t, "  lfind:\n", "  lfind:\n    comment\n      the child of a0 named as find_label's s4 s5, looking through the layers in it, a1 layers deep; 0 if there is none\n", "lfind");
save();
