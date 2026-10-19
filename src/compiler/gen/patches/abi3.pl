# abi3.pl: structs by value by arm's AAPCS (abi.pl's third step). A struct
# argument is its words: in core registers as far as they go, split with
# the stack where none went there before (as the AAPCS has it), a struct
# aligned to 8 from an even register, the rest on the stack; a homogeneous
# floating aggregate (hfa: one to four floats or doubles, nested structs and
# arrays of them) of a function that is not variadic in consecutive VFP
# singles or doubles. A result (abiresclass): a float in s0, a double in d0
# (a variadic function's in r0:r1), a struct of four bytes or less in r0,
# an hfa in s0.. or d0.., any other struct through the address in r0. The
# callee keeps r0..r3 in its frame where a struct's words or a VFP
# parameter need them; a struct parameter's bytes are in that save, on the
# stack, or copied together where it was split. va_arg of a struct takes
# its words from the array. Run on ttpc.ff after abi.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }
# a helper of cc's layer 3 made again
sub R {
    my ($name, $text) = @_;
    my ($from, $to) = find(\$t, "cc/$name");
    substr($t, $from, $to - $from) = $text;
}

# ---- abicall: the result's class, each argument's kind
E('cc/abicall', 8, "
    mv a5 a0
    call fwide
    beqz L0 a0
    li 1 t0
    sd 1600 t0 sp
    j L1
    L0:
    beqz L1 s6
    li 1 t0
    sd 0 t0 sp
    L1:
", "
    mv a5 a0
    mv a3 a1
    call abiresclass
    sd 1600 a0 sp
    sd 1608 a1 sp
    li 6 t0
    bne rel:L1 t0 a0
    li 1 t0
    sd 0 t0 sp
    L1:
");
E('cc/abicall', 10, "
    sd 48 s10 t1
    mv s10 a0
    call ispair
    addi 1 a0 a0
    slli 5 s9 t1
    add t1 sp t1
    sd 56 a0 t1
", "
    sd 48 s10 t1
    sd 56 a2 t1
");
E('cc/abicall', 10, "
    bge rel:LQ s8 s9
    slli 5 s9 t1
    add t1 sp t1
    ld 32 t1 a1
    ld 40 t1 a2
    ld 48 t1 a3
    ld 56 t1 t6
", "
    bge rel:LQ s8 s9
    slli 5 s9 t1
    add t1 sp t1
    ld 48 t1 a0
    call ispair
    addi 1 a0 t6
    slli 5 s9 t1
    add t1 sp t1
    ld 32 t1 a1
    ld 40 t1 a2
    ld 48 t1 a3
    ld 56 t1 t2
");
E('cc/abicall', 10, "
    mv s7 a0
    ld 1576 sp a5
    call abiput
", "
    mv s7 a0
    ld 1576 sp a5
    slli 1 t2 t2
    or t2 a5 a5
    call abiput
");
E('cc/abicall', 8, "
    L8:
    beqz L10 s6
    ld 1600 sp t0
    bnez L10 t0
", "
    L8:
    beqz L10 s6
    ld 1600 sp t0
    li 6 t1
    bne rel:L10 t1 t0
");
E('cc/abicall', 8, "
    LN:
    ld 1592 sp a0
    mv s6 a1
    ld 1568 sp a2
    call abires
", "
    LN:
    ld 1600 sp a0
    ld 1608 sp a1
    mv s6 a2
    call abires
");

$t =~ /^( *)abi_csave:\n\1  dword\n\1    0\n/m or die "abi3: no abi_csave\n";
my $vi = $1;
once(\$t, "${vi}abi_csave:\n$vi  dword\n$vi    0\n", "${vi}abi_csave:\n$vi  dword\n$vi    0\n${vi}abi_cword:\n$vi  dword\n$vi    0\n", 'abi_csave');

# ---- the callee: a struct result's address only for a struct in memory
E('cc/abipplan', 8, "
    la abi_pplan s6
", "
    la abi_pplan s6
    la abi_cword t0
    sd 0 zero t0
");
E('cc/abipplan', 8, "
    la ccs t0
    ld CC_rty t0 a0
    call inmem
    beqz L1 a0
    la ccs t0
    ld CC_rty t0 a0
    call fwide
    bnez L1 a0
", "
    la ccs t0
    ld CC_rty t0 a0
    ld CC_va t0 a1
    call abiresclass
    li 6 t0
    bne rel:L1 t0 a0
");
E('cc/abipplan', 10, "
    sd 48 s8 t1
", "
    sd 48 s8 t1
    sd 56 a2 t1
    li 1 t0
    bne rel:L4 t0 a2
    li 16 t0
    bge rel:L4 t0 a0
    la abi_cword t1
    sd 0 t0 t1
");
E('cc/abipplan', 10, "
    ld 0 s6 t0
    beqz L6 t0
    ld 16 s6 t0
    beqz L6 t0
", "
    ld 0 s6 t0
    beqz L6 t0
    ld 16 s6 t0
    la abi_cword t1
    ld 0 t1 t1
    or t1 t0 t0
    beqz L6 t0
");
# abipparam: a struct's words, an hfa's registers
E('cc/abipparam', 8, "
    ld 32 t0 s6
    ld 40 t0 s7
", "
    ld 32 t0 s6
    ld 40 t0 s7
    ld 56 t0 t1
    beqz LQ t1
    mv s4 a0
    mv s5 a1
    call abipstruct
    leave5
    LQ:
");

my $h = '';
# hfa a0: a homogeneous floating aggregate's element (36 float, 40 double)
# and count (a1), or a0 = 0
$h .= fn('hfa', "
    enter8
    mv a0 s4
    lui TY_REC t0
    bltu rel:LB t0 s4
    ld TY_kind s4 t1
    li TY_ARRAY t0
    beq rel:LA t0 t1
    li TY_STRUCT t0
    bne rel:L0 t0 t1
    ld TY_base s4 s5
    ld NODE_children s5 s6
    lbu NODE_children_len s5 s7
    li 0 s8
    li 0 s9
    beqz L0 s7
    ld 0 s6 a0
    call kwof
    li KW_struct t0
    bne rel:L0 t0 a0
    addi 8 s6 s6
    addi -1 s7 s7
    LF:
    beqz LE s7
    ld 0 s6 s10
    ld NODE_content s10 t0
    lbu NODE_content_len s10 t1
    beqz LN t1
    add t1 t0 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:LN t1 t0
    lbu NODE_children_len s10 t0
    beqz L0 t0
    ld NODE_children s10 a0
    slli 3 t0 t0
    add a0 t0 s11
    mv s11 a1
    call typerun
    bltz L0 a0
    bne rel:L0 s11 a1
    call hfa
    beqz L0 a0
    beqz LG s8
    bne rel:L0 s8 a0
    LG:
    mv a0 s8
    add a1 s9 s9
    LN:
    addi 8 s6 s6
    addi -1 s7 s7
    j LF
    LE:
    beqz L0 s9
    li 4 t0
    blt rel:L0 s9 t0
    mv s8 a0
    mv s9 a1
    leave8
    LA:
    ld TY_count s4 s5
    ld TY_base s4 a0
    call hfa
    beqz L0 a0
    mul s5 a1 a1
    leave8
    LB:
    li 1 a1
    li 36 t0
    beq rel:L9 t0 s4
    li 40 t0
    beq rel:L9 t0 s4
    L0:
    li 0 a0
    leave8
    L9:
    mv s4 a0
    leave8
", 6);
# abiresclass a0 a1: how a result of type a0 comes back (a1 1: a variadic
# function's, by the base standard): a0 = 0 in r0 (r0:r1), 1 a float in
# s0, 2 a double in d0, 7 a double in r0:r1, 3 a struct of four bytes or
# less in r0, 4 and 5 an hfa of a1 floats or doubles in s0.. or d0.., 6 a
# struct through the address in r0
$h .= fn('abiresclass', "
    enter3
    mv a0 s4
    mv a1 s5
    call tscalar
    li 36 t0
    bne rel:L1 t0 a0
    bnez L9 s5
    li 1 a0
    leave3
    L1:
    li 40 t0
    bne rel:L2 t0 a0
    li 2 a0
    beqz LV s5
    li 7 a0
    LV:
    leave3
    L2:
    mv s4 a0
    call inmem
    beqz L9 a0
    bnez L3 s5
    mv s4 a0
    call hfa
    beqz L3 a0
    li 36 t0
    li 4 t1
    beq rel:LH t0 a0
    li 5 t1
    LH:
    mv t1 a0
    leave3
    L3:
    mv s4 a0
    call tsize
    li 4 t0
    blt rel:L4 a0 t0
    li 3 a0
    leave3
    L4:
    li 6 a0
    leave3
    L9:
    li 0 a0
    leave3
", 6);
# abivfp a0 a1 a2: a1 consecutive VFP registers of a2 singles each (1 a
# float, 2 a double) by the state a0, the lowest free: a0 = 32 + the
# single or 64 + the double, or -1 when there are none (the state then has
# no VFP registers for later arguments)
$h .= fn('abivfp', "
    mul a2 a1 t0
    li 1 t1
    sll t0 t1 t1
    addi -1 t1 t1
    ld 16 a0 t2
    li 0 t3
    ld 24 a0 t4
    bnez L8 t4
    L1:
    add t0 t3 t4
    li 16 t5
    blt rel:L8 t4 t5
    srl t3 t2 t4
    and t1 t4 t4
    beqz L2 t4
    add a2 t3 t3
    j L1
    L2:
    sll t3 t1 t1
    or t1 t2 t2
    sd 16 t2 a0
    li 2 t0
    beq rel:L3 t0 a2
    addi 32 t3 a0
    ret
    L3:
    srli 1 t3 t3
    addi 64 t3 a0
    ret
    L8:
    li 1 t4
    sd 24 t4 a0
    li -1 a0
    ret
", 6);
# abiclass a0 a1 a2: the place of an argument of type a1 by the state a0
# (its next core register, its stack's bytes, the VFP singles in use,
# whether the VFP registers are done), a2 1 for a variadic function (the
# base standard: no VFP): a0 = the core register (0..3; a struct's first),
# 256 + its offset on the stack, 32 + its single, 64 + its double; a1 =
# its words (an hfa's registers); a2 = its kind (0 a scalar, 1 a struct's
# words, 2 an hfa in VFP registers)
$h .= fn('abiclass', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s7
    li 0 s11
    mv s5 a0
    call tscalar
    mv a0 s8
    bnez LB s7
    li 36 t0
    beq rel:LF t0 s8
    li 40 t0
    beq rel:LD t0 s8
    LB:
    mv s5 a0
    call inmem
    beqz LC a0
    mv s5 a0
    call fwide
    beqz LS a0
    LC:
    mv s5 a0
    call ispair
    addi 1 a0 s6
    li 40 t0
    bne rel:L0 t0 s8
    li 2 s6
    L0:
    li 0 s9
    li 2 t0
    bne rel:LW t0 s6
    li 1 s9
    j LW
    LS:
    li 1 s11
    bnez LT s7
    mv s5 a0
    call hfa
    beqz LT a0
    mv a1 s10
    li 1 s9
    li 36 t0
    beq rel:LU t0 a0
    li 2 s9
    LU:
    mv s4 a0
    mv s10 a1
    mv s9 a2
    call abivfp
    bltz LV a0
    mv s10 a1
    li 2 a2
    leave8
    LV:
    mul s10 s9 s6
    li 1 t0
    sub t0 s9 s9
    j L4
    LT:
    mv s5 a0
    call tsize
    addi 3 a0 a0
    srli 2 a0 s6
    mv s5 a0
    call talign
    li 0 s9
    li 8 t0
    blt rel:LW t0 a0
    li 1 s9
    LW:
    ld 0 s4 t0
    beqz L1 s9
    addi 1 t0 t0
    andi -2 t0 t0
    L1:
    add s6 t0 t1
    li 4 t2
    blt rel:L2 t1 t2
    sd 0 t1 s4
    mv t0 a0
    mv s6 a1
    mv s11 a2
    leave8
    L2:
    beqz L4 s11
    li 4 t2
    bge rel:L4 t2 t0
    ld 8 s4 t3
    bnez L4 t3
    li 4 t2
    sub t0 t2 t2
    sub t2 s6 t2
    slli 2 t2 t2
    sd 8 t2 s4
    li 4 t2
    sd 0 t2 s4
    mv t0 a0
    mv s6 a1
    li 1 a2
    leave8
    L4:
    li 4 t1
    sd 0 t1 s4
    ld 8 s4 t0
    beqz L3 s9
    addi 7 t0 t0
    andi -8 t0 t0
    L3:
    slli 2 s6 t1
    add t1 t0 t1
    sd 8 t1 s4
    addi 256 t0 a0
    mv s6 a1
    mv s11 a2
    leave8
    LF:
    mv s4 a0
    li 1 a1
    li 1 a2
    call abivfp
    bltz LF2 a0
    li 1 a1
    li 0 a2
    leave8
    LF2:
    li 1 s6
    li 0 s9
    j L4
    LD:
    mv s4 a0
    li 1 a1
    li 2 a2
    call abivfp
    bltz LD2 a0
    li 2 a1
    li 0 a2
    leave8
    LD2:
    li 2 s6
    li 1 s9
    j L4
", 6);
R('abiclass', $h);

# abiput a0 .. a5: an argument's words in its place, in pass a0 (0: the
# stack's, which take r0 and r12 to copy; 1: the registers'): its place
# a1, words a2, type a3, its pushed value at SP + a4 (a double's or a
# struct's address), a5 1 under va_arg_pack (the pushed values then at FP -
# abi_vadepth + a4) plus twice its kind (abiclass's)
R('abiput', fn('abiput', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    srli 1 a5 s11
    andi 1 a5 s9
    bnez LK s11
    mv s7 a0
    call fwide
    mv a0 s10
    li 16 t0
    blt rel:LR t0 s5
    li 256 t0
    bge rel:LS t0 s5
    li 64 t0
    blt rel:LF t0 s5
    beqz L9 s4
    bnez LX s9
    addi -64 s5 a0
    mv s8 a1
    la cc_argd a2
    call abiprim
    leave8
    LF:
    beqz L9 s4
    bnez LX s9
    addi -32 s5 a0
    mv s8 a1
    la cc_argf a2
    call abiprim
    leave8
    LS:
    bnez L9 s4
    addi -256 s5 s5
    bnez LSD s10
    li 0 s11
    LS1:
    bge rel:L9 s6 s11
    slli 2 s11 a1
    add s8 a1 a1
    li 0 a0
    call abiarg
    slli 2 s11 a1
    add s5 a1 a1
    la cc_stsp a0
    call seq
    addi 1 s11 s11
    j LS1
    LSD:
    mv s8 a0
    mv s5 a1
    la cc_stkd a2
    call abiprim
    leave8
    LR:
    beqz L9 s4
    bnez LRD s10
    li 0 s11
    LR1:
    bge rel:L9 s6 s11
    add s11 s5 a0
    slli 2 s11 a1
    add s8 a1 a1
    beqz LR2 s9
    la abi_vadepth t0
    ld 0 t0 t0
    sub t0 a1 a1
    la cc_argfp a2
    call abiprim
    j LR3
    LR2:
    call abiarg
    LR3:
    addi 1 s11 s11
    j LR1
    LRD:
    bnez LX s9
    mv s5 a0
    mv s8 a1
    la cc_argdr a2
    call abiprim
    leave8
    LK:
    bnez LX s9
    li 2 t0
    beq rel:LH t0 s11
    li 0 s10
    LK1:
    bge rel:L9 s6 s10
    li 256 t0
    bge rel:LK3 t0 s5
    add s10 s5 t0
    li 4 t1
    bge rel:LK2 t1 t0
    beqz LK4 s4
    add s10 s5 a2
    mv s8 a3
    slli 2 s10 a4
    la cc_argw a0
    j LK5
    LK2:
    bnez LK4 s4
    li 4 t1
    sub s5 t1 t1
    sub t1 s10 t1
    slli 2 t1 a3
    j LK6
    LK3:
    bnez LK4 s4
    addi -256 s5 a3
    slli 2 s10 t1
    add t1 a3 a3
    LK6:
    mv s8 a2
    slli 2 s10 a4
    la cc_stkw a0
    LK5:
    li 3 a1
    li 0 a5
    call prim
    LK4:
    addi 1 s10 s10
    j LK1
    LH:
    beqz L9 s4
    li 0 s10
    LH1:
    bge rel:L9 s6 s10
    li 64 t0
    bge rel:LH2 t0 s5
    addi -32 s5 a2
    add s10 a2 a2
    slli 2 s10 a4
    la cc_argfw a0
    j LH3
    LH2:
    addi -64 s5 a2
    add s10 a2 a2
    slli 3 s10 a4
    la cc_argdw a0
    LH3:
    mv s8 a3
    li 3 a1
    li 0 a5
    call prim
    addi 1 s10 s10
    j LH1
    L9:
    leave8
    LX:
    li 0 a0
    call bad
", 6));
# abipstruct a0 a1: V = parameter a0 (the variable a1), a struct: the
# address of its words (in the core registers' save, on the stack, in a
# variadic function's array), or its variable, where its words were split
# or it came in VFP registers (an hfa), copied there
$h = fn('abipstruct', "
    enter8
    mv a0 s4
    mv a1 s5
    la abi_pplan t0
    slli 5 s4 t1
    add t1 t0 t0
    ld 32 t0 s6
    ld 40 t0 s7
    ld 56 t0 s8
    ld VAR_off s5 s9
    neg s9 s9
    li 2 t0
    beq rel:LH t0 s8
    la ccs t0
    ld CC_va t0 t0
    bnez LV t0
    li 256 t0
    bge rel:LS t0 s6
    add s7 s6 t0
    li 4 t1
    blt rel:LP t0 t1
    la abi_csave t0
    ld 0 t0 t0
    slli 2 s6 t1
    sub t0 t1 a0
    j LA
    LP:
    li 0 s10
    LP1:
    add s10 s6 t0
    li 4 t1
    bge rel:LP2 t1 t0
    la abi_csave t1
    ld 0 t1 t1
    slli 2 t0 t0
    sub t1 t0 a0
    slli 2 s10 a1
    add s9 a1 a1
    la cc_cpfp a2
    call abiprim
    addi 1 s10 s10
    j LP1
    LP2:
    bge rel:LP3 s7 s10
    li 4 t1
    sub s6 t1 t1
    sub t1 s10 t1
    slli 2 t1 s11
    call argoff
    add s11 a0 a0
    slli 2 s10 a1
    add s9 a1 a1
    la cc_cpfp a2
    call abiprim
    addi 1 s10 s10
    j LP2
    LP3:
    mv s9 a0
    j LA
    LS:
    addi -256 s6 s11
    call argoff
    add s11 a0 a0
    j LA
    LV:
    slli 2 s6 s11
    li 16 t0
    blt rel:LV1 t0 s6
    addi -240 s6 s11
    LV1:
    call argoff
    add s11 a0 a0
    LA:
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    leave8
    LH:
    mv s9 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li 0 s10
    LH1:
    bge rel:L9 s7 s10
    li 64 t0
    bge rel:LH2 t0 s6
    addi -32 s6 a2
    add s10 a2 a2
    slli 2 s10 a3
    la cc_paramfw a0
    j LH3
    LH2:
    addi -64 s6 a2
    add s10 a2 a2
    slli 3 s10 a3
    la cc_paramdw a0
    LH3:
    li 2 a1
    li 0 a5
    call prim
    addi 1 s10 s10
    j LH1
    L9:
    leave8
", 6);
# abires a0 a1 a2: the result where C has it, by its class a0 (abiresclass),
# its count a1, its room a2 below FP (a temporary where there is none): V
# the bits of a float, else the address of the result in its room
$h .= fn('abires', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    li 1 t0
    bne rel:L1 t0 s4
    la cc_resf a0
    call seq
    leave5
    L1:
    beqz L9 s4
    bnez L2 s6
    call wtemp
    mv a0 s6
    L2:
    li 2 t0
    bne rel:L3 t0 s4
    la cc_resd a0
    mv s6 a1
    call seq
    leave5
    L3:
    li 7 t0
    bne rel:L4 t0 s4
    la cc_resdr a0
    mv s6 a1
    call seq
    leave5
    L4:
    li 3 t0
    bne rel:L5 t0 s4
    la cc_resw a0
    mv s6 a1
    call seq
    leave5
    L5:
    li 6 t0
    bne rel:L6 t0 s4
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    leave5
    L6:
    la cc_resroom a0
    mv s6 a1
    call seq
    li 0 s7
    L7:
    bge rel:L8 s5 s7
    mv s7 a2
    li 4 t0
    bne rel:L71 t0 s4
    slli 2 s7 a3
    la cc_resfw a0
    j L72
    L71:
    slli 3 s7 a3
    la cc_resdw a0
    L72:
    li 2 a1
    li 0 a5
    call prim
    addi 1 s7 s7
    j L7
    L8:
    la cc_resv a0
    call seq
    L9:
    leave5
", 6);
R('abires', $h);
# abiretf a0: the result of type a0 where the ABI has it, by its class: a0 =
# 1 where it needs no copy into a struct's room
R('abiretf', fn('abiretf', "
    enter3
    mv a0 s4
    call abion
    beqz L8 t0
    la ccs t0
    ld CC_va t0 a1
    call abiresclass
    mv a0 s5
    mv a1 s6
    li 1 t0
    bne rel:L1 t0 s5
    la cc_retf a0
    call seq
    j L8
    L1:
    li 2 t0
    bne rel:L2 t0 s5
    la cc_retd a0
    j L7
    L2:
    li 7 t0
    bne rel:L3 t0 s5
    la cc_retdr a0
    j L7
    L3:
    li 3 t0
    bne rel:L4 t0 s5
    la cc_retw a0
    j L7
    L4:
    li 4 t0
    blt rel:L8 t0 s5
    li 5 t0
    blt rel:L8 s5 t0
    li 0 s4
    L5:
    bge rel:L9 s6 s4
    mv s4 a2
    li 4 t0
    bne rel:L51 t0 s5
    slli 2 s4 a3
    la cc_retfw a0
    j L52
    L51:
    slli 3 s4 a3
    la cc_retdw a0
    L52:
    li 2 a1
    li 0 a5
    call prim
    addi 1 s4 s4
    j L5
    L7:
    call seq
    L9:
    li 1 a0
    leave3
    L8:
    li 0 a0
    leave3
", 6));
# va_arg of a struct: its words in the array, 8-aligned where it is
E('cc/abivaarg', 8, "
    LA:
    mv s5 a0
    call inmem
    beqz LB a0
    li 2 s8
    j L1
", "
    LA:
    mv s5 a0
    call inmem
    beqz LB a0
    li 1 s8
    mv s5 a0
    call tsize
    addi 3 a0 a0
    andi -4 a0 s6
    mv s5 a0
    call talign
    li 8 t0
    blt rel:L1 t0 a0
    j L0
");

# ---- calls through an address: room for a result in memory (A4)
# The room is made before the address and the arguments are pushed, a
# slot of the frame from then on (abiroom), its place passed to abicall.
E('cc/index', 8, "
    L20:
    call getty
    mv a0 s7
    call push
", "
    L20:
    call getty
    mv a0 s7
    mv s7 a0
    call abiroomp
    mv a0 s8
    call push
");
E('cc/index', 8, "
    W1:
    call getty
    mv a0 s7
    call push
    li 0 s8
    addi -528 sp sp
    sd 0 zero sp
    sd 8 zero sp
", "
    W1:
    call getty
    mv a0 s7
    mv s7 a0
    call abiroomp
    mv a0 s8
    call push
    addi -544 sp sp
    sd 0 zero sp
    sd 8 zero sp
    sd 528 s8 sp
    li 0 s8
");
E('cc/index', 10, "
    call psetargs
    addi 528 sp sp
    call abion
    bnez LW t0
", "
    call psetargs
    ld 528 sp t3
    addi 544 sp sp
    call abion
    bnez LW t0
");
E('cc/index', 8, "
    LB:
", "
    LB:
    addi -16 sp sp
    sd 0 s8 sp
");
E('cc/index', 8, "
    LW:
", "
    LW:
    mv t3 s8
    addi -16 sp sp
    sd 0 s8 sp
");
{
    my ($from, $to) = find(\$t, 'cc/index');
    my $e = substr($t, $from, $to - $from);
    my $n = $e =~ s/(        LD[56]:\n          mv\n            a0\n            s8\n(?:.*\n)*?          li\n            0\n            a1\n)          li\n            0\n            a2\n/$1          ld\n            0\n            sp\n            a2\n          addi\n            16\n            sp\n            sp\n/g;
    die "abi3: index's two calls, $n\n" unless $n == 2;
    substr($t, $from, $to - $from) = $e;
}

# abiroomp a0: the room for the result of a call through an address of type
# a0 where the result comes in memory: a0 = its place below FP (a temporary
# of the frame), or 0. The frame's temporaries are laid out when a function
# starts (treserve), before its calls through addresses are seen: each
# function's room for them is kept by its node (abi_xtab, the largest the
# first pass needed), which treserve adds in the second pass.
$h = fn('abiroomp', "
    enter2
    call abion
    beqz L9 t0
    mv a0 s4
    call tbase
    ld TY_base a0 a0
    call isvafn
    mv a0 s5
    mv s4 a0
    call tbase
    ld TY_base a0 t0
    ld NODE_children t0 a0
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 a0 a1
    addi -16 sp sp
    sd 0 a0 sp
    sd 8 a1 sp
    ld 0 a0 a0
    call kwof
    mv a0 t2
    ld 0 sp a0
    ld 8 sp a1
    addi 16 sp sp
    li KW_function t0
    bne rel:L1 t0 t2
    addi 8 a0 a0
    L1:
    call typerun
    bltz L9 a0
    mv a0 s4
    mv s5 a1
    call abiresclass
    li 2 t0
    blt rel:L9 t0 a0
    mv s4 a0
    call tsize
    addi 7 a0 a0
    andi -8 a0 a0
    la abi_curx t0
    ld 0 t0 t1
    add a0 t1 t1
    sd 0 t1 t0
    la ccs t0
    ld CC_tnext t0 t1
    add a0 t1 t1
    sd CC_tnext t1 t0
    mv t1 s5
    la abi_curx t0
    ld 0 t0 a0
    call abixput
    mv s5 a0
    leave2
    L9:
    li 0 a0
    leave2
", 6);
# abixget: a0 = the room the function being compiled (abi_curfn) needs
# for its calls through addresses (abi_xtab); abixput a0: it needs a0 at
# least
$h .= fn('abixget', "
    la abi_curfn t0
    ld 0 t0 t0
    la abi_xn t1
    ld 0 t1 t1
    la abi_xtab t2
    L1:
    beqz L9 t1
    ld 0 t2 t3
    beq rel:L2 t0 t3
    addi 16 t2 t2
    addi -1 t1 t1
    j L1
    L2:
    ld 8 t2 a0
    ret
    L9:
    li 0 a0
    ret
", 6);
$h .= fn('abixput', "
    la abi_curfn t0
    ld 0 t0 t0
    la abi_xn t1
    ld 0 t1 t4
    la abi_xtab t2
    L1:
    beqz L8 t4
    ld 0 t2 t3
    beq rel:L2 t0 t3
    addi 16 t2 t2
    addi -1 t4 t4
    j L1
    L8:
    ld 0 t1 t4
    li32 4096 t3
    bge rel:L9 t3 t4
    addi 1 t4 t4
    sd 0 t4 t1
    sd 0 t0 t2
    sd 8 zero t2
    L2:
    ld 8 t2 t3
    bge rel:L9 t3 a0
    sd 8 a0 t2
    L9:
    ret
", 6);
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $h;
}

# treserve: the function's node kept, its room for calls through addresses added
E('cc/fnbody', 10, "
    mv s6 a0
    mv s5 a1
    call treserve
", "
    mv s6 a0
    mv s5 a1
    mv s4 a2
    call treserve
");
E('cc/treserve', 8, "
    enter3
    mv a0 s4
", "
    enter3
    la abi_curfn t0
    sd 0 a2 t0
    la abi_curx t0
    sd 0 zero t0
    mv a0 s4
");
E('cc/treserve', 8, "
    L2:
    la ccs t0
    ld CC_depth t0 t1
", "
    L2:
    call abixget
    add a0 s6 s6
    la ccs t0
    ld CC_depth t0 t1
");
$t =~ /^( *)abi_cword:\n\1  dword\n\1    0\n/m or die "abi3: no abi_cword\n";
my $wi = $1;
once(\$t, "${wi}abi_cword:\n$wi  dword\n$wi    0\n", "${wi}abi_cword:\n$wi  dword\n$wi    0\n" . join('', map { "$wi$_:\n$wi  dword\n$wi    0\n" } qw(abi_curfn abi_curx abi_xn)), 'abi_cword');
$t =~ /^( *)lookcache:\n\1  reserve\n/m or die "abi3: no lookcache\n";
my $li = $1;
once(\$t, "${li}lookcache:\n", "${li}abi_xtab:\n$li  reserve\n$li    65536\n${li}lookcache:\n", 'lookcache');

sub esc { my $x = shift; $x =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $x }
my $d = '';
for my $x (['cc_argw', "cc_arg_w\0"], ['cc_stkw', "cc_stk_w\0"], ['cc_argfw', "cc_arg_fw\0"], ['cc_argdw', "cc_arg_dw\0"],
           ['cc_cpfp', "cc_cp_fp\0"], ['cc_paramfw', "cc_param_fw\0"], ['cc_paramdw', "cc_param_dw\0"], ['cc_resw', "\x01cc_res_w\0"],
           ['cc_resroom', "\x01cc_res_room\0"], ['cc_resfw', "cc_res_fw\0"], ['cc_resdw', "cc_res_dw\0"], ['cc_resv', "\0cc_res_v\0"],
           ['cc_retw', "\0cc_ret_w\0"], ['cc_retfw', "cc_ret_fw\0"], ['cc_retdw', "cc_ret_dw\0"]) {
    my ($l, $b) = @$x;
    $b .= "\0" x (-length($b) % 8);
    $d .= "      $l:\n        ascii\n          " . esc($b) . "\n";
}
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $d;
}
save();
