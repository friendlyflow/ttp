# arraylit.pl: an array compound literal, C's (char *const[]){ "sh", "-c",
# NULL } (libio's popen) or (size_t[7]){ ... }: the user's form follows a
# typed literal's, the type's first word on top, the rest of the type and
# then the items as its children: array / address / char / 3 / items. Its
# value is a temporary of that array type, as a struct's compound literal
# is (complit), its address as an array's is where it stands: primary takes array with children to complita, which makes
# the type from the children (the element's type run, then the count) and
# fills the temporary from the items after them; tscan reserves the
# temporary's room in the frame, as for a struct's. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/primary',
    "          li\n            KW_cast\n            t0\n          beq\n            rel\n              L60\n            t0\n            a0\n",
    "          li\n            KW_cast\n            t0\n          beq\n            rel\n              L60\n            t0\n            a0\n" . asm(10, "
    li KW_array t0
    beq rel:L57 t0 a0
"),
    "        L61:\n          mv\n            s4\n            a0\n          call\n            bad\n",
    "        L61:\n          mv\n            s4\n            a0\n          call\n            bad\n" . asm(8, "
    L57:
    mv s4 a0
    call complita
    call rvalue
    j L9
"));

my ($from) = find(\$t, 'cc/declare');
substr($t, $from, 0) = fn('complita', "
    enter8
    mv a0 s4
    # the element's type, the count after it
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call typerun
    bltz AB a0
    mv a0 s5
    mv a1 s7
    ld 0 s7 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call parse_num
    beqz AB a1
    mv a0 a2
    li TY_ARRAY a0
    mv s5 a1
    call newtype
    mv a0 s5
    # the children before the items: the type and the count
    ld NODE_children s4 t0
    sub t0 s7 t1
    srli 3 t1 t1
    addi 1 t1 s9
    # a temporary of that type, zero, then the items, as complit
    mv s5 a0
    call tsize
    mv a0 s6
    call slot
    add a0 s6 s6
    addi -1 s6 s6
    neg a0 a0
    and a0 s6 s6
    la ccs t0
    ld CC_tnext t0 t1
    add s6 t1 t1
    sd CC_tnext t1 t0
    mv t1 s6
    neg s6 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s5 a0
    call tsize
    li R_t1 a1
    call li
    la cc_zero a0
    call seq
    mv s4 a0
    call open
    mv a0 s7
    mv a1 s8
    AS:
    beqz AE s9
    call next
    addi -1 s9 s9
    j AS
    AE:
    mv s5 a0
    mv s6 a1
    call linit
    mv s7 a0
    mv s8 a1
    call close
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s5 a0
    call setty
    leave8
    AB:
    mv s4 a0
    call bad
", 6);
# tscan: an array with children (a literal; in a declaration array is a
# leaf) needs its size in the frame
edit(\$t, 'cc/tscan',
    "        call\n          wcount\n        mv\n          a0\n          s5\n",
    "        call\n          wcount\n        mv\n          a0\n          s5\n" . asm(8, "
    mv s4 a0
    call kwof
    li KW_array t0
    bne rel:L20 t0 a0
    lbu NODE_children_len s4 t0
    beqz L20 t0
    ld NODE_children s4 a0
    slli 3 t0 t0
    add t0 a0 a1
    call typerun
    bltz L20 a0
    mv a0 s6
    ld 0 a1 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call parse_num
    beqz L20 a1
    mv a0 s7
    mv s6 a0
    call tsize
    mul s7 a0 s6
    call slot
    add a0 s6 s6
    addi -1 s6 s6
    neg a0 a0
    and a0 s6 s6
    add s6 s5 s5
    j L2
    L20:
"));
save();
