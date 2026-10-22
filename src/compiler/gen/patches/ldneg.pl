# ldneg.pl: two long double items of a global that gval now works out
# itself (libm's tables: e_expl's C, __expl_table), which went to the
# compile time JIT, which has no temporaries for long double ("a value of a
# type in memory"):
#   : / - / x             x negated, a literal 0x...L or the cast below:
#                          its sign bit flipped (in cc_ldhi's high word;
#                          the double where long double is double, arm)
#   cast / long double, N  an int as long double, exact: binary128's high
#                          and low word (cc_ldhi as hexf leaves it), or the
#                          double where it is exact (else as before)
# The same for a double's item (arm's long double).
# Test: cldneg. Run on ttpc.ff after ldarray.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# long double (binary128, cc_ldhi) or double: long double is double where
# the word is 4 bytes (arm, pairs3.pl), as typerun has it
my $type = "
    li TY_LDOUBLE t0
    beq rel:%s t0 %s
    li TY_DOUBLE t0
    bne rel:%s t0 %s
";
my $wide = "
    li TY_LDOUBLE t3
    beq rel:%s t3 %s
";

# a group `:` / - / x, x a long double literal or a cast: x's value
# (gval on the group's items after -), its sign flipped
my $group = "          li\n            KW_group\n            t0\n          bne\n            rel\n              L28\n            t0\n            a0\n";
edit(\$t, 'gval', $group, $group . asm(10, "
" . sprintf($type, 'LGT', 's7', 'LGN', 's7') . "
LGT:
    lbu NODE_children_len s5 t0
    li 2 t1
    bltu rel:LGN t1 t0
    ld NODE_children s5 t2
    ld 0 t2 a0
    lbu NODE_children_len a0 t0
    bnez LGN t0
    call opof
    li OP_sub t0
    bne rel:LGN t0 a0
    ld NODE_children s5 t2
    ld 8 t2 a0
    call kwof
    li KW_cast t0
    beq rel:LGV t0 a0
    ld NODE_children s5 t2
    ld 8 t2 t3
    lbu NODE_children_len t3 t0
    bnez LGN t0
    ld NODE_content t3 a0
    lbu NODE_content_len t3 a1
    add a1 a0 t0
    lbu -1 t0 t0
    li 76 t1
    bne rel:LGN t1 t0
LGV:
    la gv_end t0
    ld 0 t0 t1
    addi -16 sp sp
    sd 0 t1 sp
    ld NODE_children s5 a0
    lbu NODE_children_len s5 t1
    slli 3 t1 t1
    add a0 t1 t1
    sd 0 t1 t0
    addi 8 a0 a0
    mv s7 a1
    call gval
    la gv_end t0
    ld 0 sp t1
    sd 0 t1 t0
    addi 16 sp sp
    li 1 t1
    slli 63 t1 t1
" . sprintf($wide, 'LGQ', 's7') . "
    xor t1 a0 a0
    j LGE
LGQ:
    la cc_ldhi t3
    ld 0 t3 t2
    xor t1 t2 t2
    sd 0 t2 t3
LGE:
    addi 8 s4 a1
    j L9
LGN:
    mv s5 a0
"));

edit(\$t, 'gval', "          mv\n            a0\n            s8\n", "          mv\n            a0\n            s8\n" . asm(10, "
    # cast / long double, then an int: |N| normalized (t0, its top bit
    # set, then shifted out: the fraction), t2 its top bit's place, t1 the
    # sign, t5 0 for zero
" . sprintf($type, 'LDT', 's8', 'LDC9', 's8') . "
LDT:
    addi 8 s4 t1
    la gv_end t0
    ld 0 t0 t0
    bgeu rel:LDC9 t0 t1
    ld 0 t1 t2
    lbu NODE_children_len t2 t3
    bnez LDC9 t3
    ld NODE_content t2 a0
    lbu NODE_content_len t2 a1
    call parse_num
    beqz LDC9 a1
    mv a0 t0
    srai 63 t0 t1
    xor t1 t0 t0
    sub t1 t0 t0
    mv t0 t5
    li 63 t2
    beqz LDK t0
LDN1:
    bltz LDK t0
    slli 1 t0 t0
    addi -1 t2 t2
    j LDN1
LDK:
    slli 1 t0 t0
    slli 63 t1 t1
" . sprintf($wide, 'LDQ', 's8') . "
    slli 52 t0 t4
    bnez LDC9 t4
    mv t1 a0
    beqz LDG t5
    li32 1023 t3
    add t3 t2 t2
    slli 52 t2 t2
    srli 12 t0 t0
    or t2 t0 t0
    or t0 a0 a0
    j LDG
LDQ:
    mv t1 a2
    li 0 a0
    beqz LDH t5
    li32 16383 t3
    add t3 t2 t2
    slli 48 t2 t2
    or t2 a2 a2
    srli 16 t0 t3
    or t3 a2 a2
    slli 48 t0 a0
LDH:
    la cc_ldhi t3
    sd 0 a2 t3
    li 1 t4
    sd 8 t4 t3
LDG:
    addi 16 s4 a1
    j L9
LDC9:
    mv s8 a0
"));
save();
