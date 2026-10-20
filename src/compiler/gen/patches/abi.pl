# abi.pl: calls by the platform's C ABI (the user's choice, 2026-10-19: ttpc
# follows each platform's C ABI for every call), first step: the mechanism
# and arm's AAPCS for words, pairs and addresses. A target says which ABI
# it calls by in its c: group's cc_abi (0, or none: ttpc's own convention,
# as before; 1: arm's AAPCS), read into targ_abi; compile time keeps ttpc's
# own (abion is 0 there).
#
# The caller (abicall): the arguments are evaluated and pushed as before
# (args records each one's type, abi_types); then each is placed by the
# ABI's classification (abiclass: the AAPCS's core registers r0..r3, a
# pair in an even pair, then the stack, a pair 8-aligned there), the
# stack's arguments copied from their pushed slots into an area below them
# in the ABI's order, sp 8-aligned at the call, the registers loaded, a
# result in memory's address in r0 (the hidden first argument), the call
# made, everything dropped. The callee (abipplan, abipparam) finds its
# parameters where the same classification put them, a variadic one in
# memory: its prologue pushes r0..r3 (cc_enter_va), so that they and the
# stack's arguments are one array, which va_start and va_arg walk upward
# (abivastart, abivaarg). The hidden address of a result in memory is
# pushed first in the frame (abi_sret), where return copies to.
#
# Floating point values, structs by value and calls through pointers' room
# for a result come in the next steps (abi2.pl ...): here a double or a
# struct still goes as its address. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# ---- the target's ABI: cc_abi after cc_char in cc_names, read into targ_abi
my $names = 'cc_li_pos\x00cc_li_neg\x00cc_li_big\x00cc_arg\x00cc_sysarg\x00cc_v\x00cc_l\x00cc_x\x00cc_slot\x00cc_fixed\x00cc_word\x00cc_argoff\x00cc_entryoff\x00cc_tls\x00cc_char\x00';
(my $plain = $names) =~ s/\\x00/\0/g;
my $off = length $plain;
once(\$t, "      $names\n", "      ${names}cc_abi\\x00\n", 'cc_names');
once(\$t, "          L20:\n            la\n              targ_char\n              t1\n            sd\n              0\n              t0\n              t1\n",
    "          L20:\n            la\n              targ_char\n              t1\n            sd\n              0\n              t0\n              t1\n" . asm(12, "
    la cc_names a0
    addi $off a0 a0
    li 6 a1
    call find_fn
    li 0 t0
    beqz L21 a0
    la cc_names a0
    addi $off a0 a0
    call tconst
    mv a0 t0
    L21:
    la targ_abi t1
    sd 0 t0 t1
"), 'reading cc_char');
$t =~ /^( *)targ_char:\n\1  dword\n\1    17\n/m or die "abi: no targ_char\n";
my $i = $1;
once(\$t, "${i}targ_char:\n$i  dword\n$i    17\n", "${i}targ_char:\n$i  dword\n$i    17\n"
    . join('', map { "$i$_:\n$i  dword\n$i    0\n" } qw(targ_abi abi_sret abi_vanext abi_vacnt abi_vadepth abi_csave)), 'targ_char');
# the types of the arguments of the call being made, and the parameters'
# places (64 of each), before lookcache in bss
$t =~ /^( *)lookcache:\n\1  reserve\n/m or die "abi: no lookcache\n";
$i = $1;
once(\$t, "${i}lookcache:\n", "${i}abi_types:\n$i  reserve\n$i    512\n${i}abi_pplan:\n$i  reserve\n$i    2080\n${i}lookcache:\n", 'lookcache');

# ---- args: each argument's type, in its frame after the mask (64 of them)
E('cc/args', 8, "
    enter8
    addi -16 sp sp
    sd 0 a1 sp
    sd 8 zero sp
", "
    enter8
    addi -528 sp sp
    sd 0 a1 sp
    sd 8 zero sp
");
E('cc/args', 10, "
    ld 8 sp a1
    call psetargs
    mv s6 a0
    mv s9 a1
    addi 16 sp sp
", "
    ld 8 sp a1
    addi 16 sp a2
    call psetargs
    mv s6 a0
    mv s9 a1
    addi 528 sp sp
");
E('cc/argpush', 8, "
    L1:
    call getty
    mv a0 s6
", "
    L1:
    call getty
    mv a0 s6
    li 64 t0
    bge rel:L2 t0 s4
    slli 3 s4 t0
    add t0 s5 t0
    sd 16 a0 t0
    L2:
");
E('cc/psetargs', 8, "
    la pair_args t0
    sd 0 a0 t0
    sd 8 a1 t0
", "
    la abi_types t1
    li 0 t2
    LT:
    bge rel:LU a0 t2
    li 64 t3
    bge rel:LU t3 t2
    slli 3 t2 t3
    add t3 a2 t4
    ld 0 t4 t4
    add t3 t1 t3
    sd 0 t4 t3
    addi 1 t2 t2
    j LT
    LU:
    la pair_args t0
    sd 0 a0 t0
    sd 8 a1 t0
");

# va_arg_pack under the ABI: the words pushed in order at run time (abivapush)
E('cc/args', 8, "
    L10:
    call next
    li 1 s9
", "
    L10:
    call next
    li 1 s9
    call abion
    bnez LV t0
");
{
    my ($from, $to) = find(\$t, 'cc/args');
    substr($t, $to, 0) = asm(8, "
        LV:
        call abivapush
        j L1
    ");
}
E('cc/vapackm', 8, "
    enter2
", "
    enter2
    call abion
    bnez LA t0
");
{
    my ($from, $to) = find(\$t, 'cc/vapackm');
    substr($t, $to, 0) = asm(8, "
        LA:
        call abivapackm
        leave2
    ");
}

# ---- call: by the ABI where the target has one
E('cc/call', 10, "
    call args
    mv a0 s9
    mv a1 s11
", "
    call args
    mv a0 s9
    mv a1 s11
    call abion
    bnez LA t0
");
E('cc/call', 10, "
    li 0 a1
    call args
    li 0 a1
    call popargs2
", "
    li 0 a1
    call args
    call abion
    bnez LB t0
    li 0 a1
    call popargs2
");
{
    my ($from, $to) = find(\$t, 'cc/call');
    substr($t, $to, 0) = asm(8, "
        LA:
        mv s5 a0
        call isvafn
        mv a0 a3
        mv s11 a4
        li 0 a0
        mv s5 a1
        li 0 a2
        beqz LC s7
        mv s8 a2
        LC:
        mv s6 a5
        call abicall
        j L7
        LB:
        li 1 a0
        li 0 a1
        li 0 a2
        li 0 a3
        li 0 a4
        mv s6 a5
        call abicall
        j L7
    ");
}
# index: a call through a variable, through a value
E('cc/index', 10, "
    li 0 a1
    call args
    li 0 a1
    call popargs2
", "
    li 0 a1
    call args
    call abion
    bnez LB t0
    li 0 a1
    call popargs2
");
E('cc/index', 8, "
    W1:
    call getty
    mv a0 s7
    call push
    li 0 s8
", "
    W1:
    call getty
    mv a0 s7
    call push
    li 0 s8
    addi -528 sp sp
    sd 0 zero sp
    sd 8 zero sp
");
E('cc/index', 10, "
    li 1 a0
    call expr
    call push
    addi 1 s8 s8
", "
    li 1 a0
    call expr
    mv s8 a0
    mv sp a1
    call argpush
    addi 1 s8 s8
");
E('cc/index', 8, "
    W3:
    mv s8 a0
    li 0 a1
    call popargs
", "
    W3:
    mv s8 a0
    ld 8 sp a1
    addi 16 sp a2
    call psetargs
    addi 528 sp sp
    call abion
    bnez LW t0
    mv s8 a0
    li 0 a1
    call popargs2
");
{
    my ($from, $to) = find(\$t, 'cc/index');
    substr($t, $to, 0) = asm(8, "
        LB:
        mv s7 a0
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
        bne rel:FN5 t0 t2
        addi 8 a0 a0
        FN5:
        call typerun
        bgez LD5 a0
        li TY_LONG a0
        LD5:
        mv a0 s8
        mv s7 a0
        call tbase
        ld TY_base a0 a0
        call isvafn
        mv a0 a3
        li 1 a0
        li 0 a1
        li 0 a2
        li 0 a4
        mv s8 a5
        call abicall
        mv s8 a0
        call setty
        li 1 a1
        leave5
        LW:
        mv s7 a0
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
        bne rel:FN6 t0 t2
        addi 8 a0 a0
        FN6:
        call typerun
        bgez LD6 a0
        li TY_LONG a0
        LD6:
        mv a0 s8
        mv s7 a0
        call tbase
        ld TY_base a0 a0
        call isvafn
        mv a0 a3
        li 1 a0
        li 0 a1
        li 0 a2
        li 0 a4
        mv s8 a5
        call abicall
        mv s8 a0
        call setty
        mv s5 a0
        mv s6 a1
        call close
        li 1 a1
        leave5
    ");
}

# ---- the callee
E('cc/pplan', 8, "
    enter3
    mv a0 s4
    mv a1 s5
", "
    enter3
    mv a0 s4
    mv a1 s5
    call abion
    bnez LA t0
");
{
    my ($from, $to) = find(\$t, 'cc/pplan');
    substr($t, $to, 0) = asm(8, "
        LA:
        mv s4 a0
        mv s5 a1
        call abipplan
        leave3
    ");
}
E('cc/pparam', 8, "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
", "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    call abion
    bnez LA t0
");
{
    my ($from, $to) = find(\$t, 'cc/pparam');
    substr($t, $to, 0) = asm(8, "
        LA:
        mv s4 a0
        mv s5 a1
        call abipparam
        leave8
    ");
}
E('cc/retval', 8, "
    call argoff
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li TY_LONG a0
    call load
", "
    call abisret
");
E('cc/retval', 8, "
    call pwassign
    mv s4 a0
    call inmem
", "
    call pwassign
    mv s4 a0
    call abiretf
    bnez L9 a0
    mv s4 a0
    call inmem
");
E('cc/vastart', 8, "
    ld CC_nfix t0 a0
    call argaddr
", "
    ld CC_nfix t0 a0
    call abivastart
");
E('cc/vaarg', 10, "
    mv a0 s6
    ld 0 s5 s5
    mv s5 a0
    mv s6 a1
    call vaargp
", "
    mv a0 s6
    ld 0 s5 s5
    mv s5 a0
    mv s6 a1
    call abivaarg
    bnez VAP a0
    mv s5 a0
    mv s6 a1
    call vaargp
");
E('cc/frame', 8, "
    la cc_prologue a0
    call seq
", "
    mv s4 a0
    la cc_prologue a1
    la cc_enterva a2
    call abiseq
");
E('cc/frame', 8, "
    la cc_epilogue a0
    call seq
", "
    mv s4 a0
    la cc_epilogue a1
    la cc_leaveva a2
    call abiseq
");

# ---- the helpers, in cc's layer 3
my $h = '';
# abion: t0 = 1 where calls go by the target's ABI (a0 kept)
$h .= fn('abion', "
    la targ_abi t0
    ld 0 t0 t0
    beqz L1 t0
    la ccs t0
    ld CC_jit t0 t0
    seqz t0 t0
    L1:
    ret
", 6);
# abiclass a0 a1 a2: the place of an argument of type a1 by the state a0
# (its next core register, the stack's bytes so far, the VFP singles in use,
# whether a VFP argument went to the stack), a2 1 for a variadic function
# (the base standard: no VFP): a0 = the core register (0..3), 256 + its
# offset on the stack, 32 + its single (s0..s15), 64 + its double (d0..d7),
# a1 = its words. A float takes the lowest free single (back-filling), a
# double the lowest free double, a pair and a variadic double an even pair.
$h .= fn('abiclass', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s7
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
    call ispair
    addi 1 a0 s6
    li 40 t0
    bne rel:L0 t0 s8
    li 2 s6
    L0:
    ld 0 s4 t0
    li 2 t1
    bne rel:L1 t1 s6
    addi 1 t0 t0
    andi -2 t0 t0
    L1:
    add s6 t0 t1
    li 4 t2
    blt rel:L2 t1 t2
    sd 0 t1 s4
    mv t0 a0
    mv s6 a1
    leave5
    L2:
    li 4 t1
    sd 0 t1 s4
    ld 8 s4 t0
    li 2 t1
    bne rel:L3 t1 s6
    addi 7 t0 t0
    andi -8 t0 t0
    L3:
    slli 2 s6 t1
    add t1 t0 t1
    sd 8 t1 s4
    addi 256 t0 a0
    mv s6 a1
    leave5
    LF:
    ld 24 s4 t0
    bnez LS t0
    ld 16 s4 t1
    li 0 t2
    LF1:
    li 16 t3
    bge rel:LS1 t3 t2
    srl t2 t1 t4
    andi 1 t4 t4
    beqz LF2 t4
    addi 1 t2 t2
    j LF1
    LF2:
    li 1 t4
    sll t2 t4 t4
    or t4 t1 t1
    sd 16 t1 s4
    addi 32 t2 a0
    li 1 a1
    leave5
    LS1:
    li 1 t0
    sd 24 t0 s4
    LS:
    ld 8 s4 t0
    addi 4 t0 t1
    sd 8 t1 s4
    addi 256 t0 a0
    li 1 a1
    leave5
    LD:
    ld 24 s4 t0
    bnez LT t0
    ld 16 s4 t1
    li 0 t2
    LD1:
    li 8 t3
    bge rel:LT1 t3 t2
    slli 1 t2 t5
    srl t5 t1 t4
    andi 3 t4 t4
    beqz LD2 t4
    addi 1 t2 t2
    j LD1
    LD2:
    li 3 t4
    slli 1 t2 t5
    sll t5 t4 t4
    or t4 t1 t1
    sd 16 t1 s4
    addi 64 t2 a0
    li 2 a1
    leave5
    LT1:
    li 1 t0
    sd 24 t0 s4
    LT:
    ld 8 s4 t0
    addi 7 t0 t0
    andi -8 t0 t0
    addi 8 t0 t1
    sd 8 t1 s4
    addi 256 t0 a0
    li 2 a1
    leave5
", 6);
# abiarg a0 a1: cc_arg a0 a1, register a0 = the word at SP + a1
$h .= fn('abiarg', "
    enter1
    mv a0 a2
    mv a1 a3
    la cc_names a0
    addi 30 a0 a0
    li 2 a1
    li 0 a5
    call prim
    leave1
", 6);
# abicall a0 (0: the function a1; 1: through the address pushed before the
# arguments), a2 (the place below FP of the result's room: a struct's,
# whose address goes in r0, or a double's, which comes in d0; or 0), a3 (1:
# a variadic function), a4 (1: va_arg_pack passes this function's own extra
# words on, which args has pushed in order at run time), a5 (the result's
# type): the call of the arguments args has pushed, by the ABI. Its frame:
# the classification's state at sp (32 bytes), a place per argument from sp
# + 32 (its place, words, type and slots pushed), then a3, a4, the count of
# the argument words, a5 and whether the result comes in d0 (48 arguments
# at most).
$h .= fn('abicall', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    addi -1616 sp sp
    sd 1568 a3 sp
    sd 1576 a4 sp
    sd 1592 a5 sp
    sd 0 zero sp
    sd 8 zero sp
    sd 16 zero sp
    sd 24 zero sp
    sd 1600 zero sp
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
    la pair_args t0
    ld 0 t0 s8
    li 0 s9
    li 48 t0
    blt rel:L2 t0 s8
    li 0 a0
    call bad
    L2:
    bge rel:L3 s8 s9
    la abi_types t0
    slli 3 s9 t1
    add t1 t0 t0
    ld 0 t0 s10
    mv sp a0
    mv s10 a1
    ld 1568 sp a2
    call abiclass
    slli 5 s9 t1
    add t1 sp t1
    sd 32 a0 t1
    sd 40 a1 t1
    sd 48 s10 t1
    mv s10 a0
    call ispair
    addi 1 a0 a0
    slli 5 s9 t1
    add t1 sp t1
    sd 56 a0 t1
    addi 1 s9 s9
    j L2
    L3:
    ld 0 sp t0
    ld 8 sp t1
    beqz LE t1
    srli 2 t1 t0
    addi 4 t0 t0
    LE:
    sd 1584 t0 sp
    li 0 s10
    ld 1576 sp t0
    beqz LF t0
    ld 8 sp t1
    beqz L4 t1
    li 0 a0
    call bad
    LF:
    la ccs t0
    ld CC_depth t0 t1
    ld 8 sp t2
    add t2 t1 t3
    neg t3 t3
    andi 7 t3 t3
    add t2 t3 s10
    beqz L4 s10
    add s10 t1 t1
    sd CC_depth t1 t0
    call syncsp
    L4:
    la pair_args t0
    ld 16 t0 s11
    li 0 s7
    LP:
    li 0 s9
    sd 0 zero sp
    L5:
    bge rel:LQ s8 s9
    slli 5 s9 t1
    add t1 sp t1
    ld 32 t1 a1
    ld 40 t1 a2
    ld 48 t1 a3
    ld 56 t1 t6
    ld 0 sp t5
    add t6 t5 t5
    sd 0 t5 sp
    sub t5 s11 t5
    slli 2 t5 t5
    add s10 t5 a4
    mv s7 a0
    ld 1576 sp a5
    call abiput
    addi 1 s9 s9
    j L5
    LQ:
    addi 1 s7 s7
    li 2 t0
    blt rel:LP t0 s7
    ld 1576 sp t0
    beqz L8 t0
    ld 1584 sp s9
    LG:
    li 4 t0
    bge rel:LH t0 s9
    ld 1584 sp t1
    sub t1 s9 a1
    slli 2 a1 a1
    mv s9 a0
    call abiarg
    addi 1 s9 s9
    j LG
    LH:
    ld 1584 sp t1
    li 4 t0
    sub t1 t0 a1
    beqz L8 a1
    slli 2 a1 a1
    la cc_addsp a0
    call seq
    L8:
    beqz L10 s6
    ld 1600 sp t0
    bnez L10 t0
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    L10:
    ld 1576 sp t0
    beqz LJ t0
    la cc_vacnt a0
    li 3 a1
    la abi_vacnt t0
    ld 0 t0 a2
    la abi_vanext t0
    ld 0 t0 a3
    ld 1584 sp a4
    li 0 a5
    call prim
    j LK
    LJ:
    ld 1568 sp t0
    beqz LK t0
    ld 1584 sp a0
    li R_t0 a1
    call li
    LK:
    bnez L11 s4
    mv s5 a0
    call isthumb
    mv a0 s9
    mv s5 a0
    call label_addr
    mv a0 a1
    la cc_auipc_ra a0
    beqz L12 s9
    la cc_callt a0
    L12:
    call seq
    j L13
    L11:
    slli 2 s11 a1
    add s10 a1 a1
    la cc_callp a0
    ld 1576 sp t0
    beqz LL t0
    la abi_vadepth t0
    ld 0 t0 a1
    slli 2 s11 t1
    sub t1 a1 a1
    neg a1 a1
    la cc_callpfp a0
    LL:
    call seq
    L13:
    ld 1576 sp t0
    beqz LM t0
    la abi_vadepth t0
    ld 0 t0 t1
    slli 2 s11 t2
    sub t2 t1 t1
    slli 2 s4 t2
    sub t2 t1 t1
    la ccs t0
    sd CC_depth t1 t0
    call syncsp
    j LN
    LM:
    slli 2 s11 a0
    add s10 a0 s9
    slli 2 s4 t0
    add t0 s9 s9
    srli 2 s9 a0
    call popped
    mv s9 a1
    la cc_addsp a0
    call seq
    LN:
    ld 1592 sp a0
    mv s6 a1
    ld 1568 sp a2
    call abires
    addi 1616 sp sp
    leave8
", 6);
# abiput a0 a1 a2 a3 a4 a5: argument's words in its place, in pass a0 (0:
# the stack's, which take r0 and r12 to copy; 1: the registers'): its place
# a1, words a2, type a3, its pushed value at SP + a4 (a double's address),
# a5 1 under va_arg_pack (the pushed values then at FP - abi_vadepth + a4)
$h .= fn('abiput', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
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
    L9:
    leave8
    LX:
    li 0 a0
    call bad
", 6);
# abires a0 a1 a2: the result of type a0 where C has it: a float from s0, a
# double from d0 into its room (a1 below FP, or a temporary); a variadic
# function's (a2 1) by the base standard: a float in r0, a double in r0:r1
$h .= fn('abires', "
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    call tscalar
    li 36 t0
    bne rel:L1 t0 a0
    bnez L9 s6
    la cc_resf a0
    call seq
    leave3
    L1:
    mv s4 a0
    call fwide
    beqz L9 a0
    bnez L2 s5
    call wtemp
    mv a0 s5
    L2:
    la cc_resd a0
    beqz L3 s6
    la cc_resdr a0
    L3:
    mv s5 a1
    call seq
    L9:
    leave3
", 6);
# abiprim a0 a1 a2: the primitive at a2 (a register, an offset)
$h .= fn('abiprim', "
    enter1
    mv a0 t0
    mv a1 t1
    mv a2 a0
    mv t0 a2
    mv t1 a3
    li 2 a1
    li 0 a5
    call prim
    leave1
", 6);
# isthumb a0: 1 for an asm function (or entry) whose first instruction is
# Thumb (t. or t2.): a call goes to it by blx
$h .= fn('isthumb', "
    enter1
    mv a0 s4
    L1:
    lbu NODE_children_len s4 t0
    ld NODE_children s4 t1
    L2:
    beqz L8 t0
    ld 0 t1 a0
    ld NODE_content a0 t2
    lbu NODE_content_len a0 t3
    beqz L3 t3
    add t3 t2 t4
    lbu -1 t4 t4
    li 58 t5
    bne rel:L4 t5 t4
    mv a0 s4
    j L1
    L4:
    lbu 0 t2 t4
    li 97 t5
    bne rel:L5 t5 t4
    lbu 1 t2 t4
    li 115 t5
    bne rel:L5 t5 t4
    li 3 t5
    beq rel:L3 t5 t3
    L5:
    lbu 0 t2 t4
    li 99 t5
    bne rel:L6 t5 t4
    lbu 1 t2 t4
    li 111 t5
    bne rel:L6 t5 t4
    lbu 2 t2 t4
    li 109 t5
    beq rel:L3 t5 t4
    L6:
    lbu 0 t2 t4
    li 116 t5
    bne rel:L8 t5 t4
    lbu 1 t2 t4
    li 46 t5
    beq rel:L9 t5 t4
    li 50 t5
    bne rel:L8 t5 t4
    lbu 2 t2 t4
    li 46 t5
    beq rel:L9 t5 t4
    j L8
    L3:
    addi 8 t1 t1
    addi -1 t0 t0
    j L2
    L8:
    li 0 a0
    leave1
    L9:
    li 1 a0
    leave1
", 6);
# abipplan a0 a1: the places of the parameters (a1 of them, from a0) of
# the function being compiled: its state (32 bytes) and 64 places of 32
# bytes (place, words, type) in abi_pplan; a struct result's address (r0)
# pushed first
$h .= fn('abipplan', "
    enter5
    mv a0 s4
    mv a1 s5
    la abi_pplan s6
    sd 0 zero s6
    sd 8 zero s6
    sd 16 zero s6
    sd 24 zero s6
    la ccs t0
    ld CC_rty t0 a0
    call inmem
    beqz L1 a0
    la ccs t0
    ld CC_rty t0 a0
    call fwide
    bnez L1 a0
    call push
    la ccs t0
    ld CC_depth t0 t1
    la abi_sret t0
    sd 0 t1 t0
    li 1 t0
    sd 0 t0 s6
    L1:
    la ccs t0
    ld CC_va t0 t0
    beqz LZ t0
    la cc_pushl a0
    li 1 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_vacnt t0
    sd 0 t1 t0
    LZ:
    li 0 s7
    L2:
    beqz L3 s5
    ld 0 s4 a0
    lbu NODE_children_len a0 t0
    ld NODE_children a0 a0
    slli 3 t0 t0
    add a0 t0 a1
    call typerun
    mv a0 s8
    mv a0 a1
    mv s6 a0
    la ccs t0
    ld CC_va t0 a2
    call abiclass
    li 64 t0
    bge rel:L4 t0 s7
    slli 5 s7 t1
    add t1 s6 t1
    sd 32 a0 t1
    sd 40 a1 t1
    sd 48 s8 t1
    L4:
    addi 1 s7 s7
    addi 8 s4 s4
    addi -1 s5 s5
    j L2
    L3:
    la abi_csave t0
    sd 0 zero t0
    ld 0 s6 t0
    beqz L6 t0
    ld 16 s6 t0
    beqz L6 t0
    la cc_pushr a0
    li 4 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_csave t0
    sd 0 t1 t0
    L6:
    ld 0 s6 t0
    li 4 t1
    blt rel:L5 t1 t0
    ld 8 s6 t0
    srli 2 t0 t0
    addi 4 t0 t0
    L5:
    la abi_vanext t1
    sd 0 t0 t1
    leave5
", 6);
# abipparam a0 a1: V = parameter a0 (the variable a1): from its register,
# pair, single (a float's bits) or double (stored in the variable, V its
# address), from the stack above FP, a variadic function's from its array
# (a double's V the address of its words there; a struct's, the address
# that is its word)
$h .= fn('abipparam', "
    enter5
    mv a0 s4
    mv a1 s5
    la abi_pplan t0
    slli 5 s4 t1
    add t1 t0 t0
    ld 32 t0 s6
    ld 40 t0 s7
    ld VAR_type s5 s8
    mv s8 a0
    call fwide
    bnez LW a0
    mv s8 a0
    call inmem
    beqz L1 a0
    li TY_LONG s8
    j L1
    LW:
    li 0 s8
    L1:
    la ccs t0
    ld CC_va t0 t0
    bnez L2 t0
    li 16 t0
    blt rel:LC t0 s6
    li 256 t0
    bge rel:L3 t0 s6
    li 64 t0
    blt rel:LF t0 s6
    ld VAR_off s5 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    la cc_paramd a0
    addi -64 s6 a1
    call seq
    leave5
    LF:
    la cc_paramf a0
    addi -32 s6 a1
    call seq
    leave5
    LC:
    la abi_csave t0
    ld 0 t0 t0
    beqz LK t0
    slli 2 s6 t1
    sub t0 t1 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    ld VAR_type s5 a0
    call load
    leave5
    LK:
    li 2 t0
    beq rel:L4 t0 s7
    la cc_param a0
    mv s6 a1
    call seq
    leave5
    L4:
    la cc_paramp a0
    li 1 a1
    mv s6 a2
    li 0 a5
    call prim
    leave5
    L3:
    addi -256 s6 s4
    j L5
    L2:
    slli 2 s6 s4
    li 16 t0
    blt rel:L5 t0 s6
    addi -240 s6 s4
    L5:
    call argoff
    add a0 s4 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    beqz L9 s8
    mv s8 a0
    call load
    L9:
    leave5
", 6);
# abisret: V = the address a result in memory goes to
$h .= fn('abisret', "
    enter1
    call abion
    bnez L1 t0
    call argoff
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li TY_LONG a0
    call load
    leave1
    L1:
    la abi_sret t0
    ld 0 t0 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li TY_LONG a0
    call load
    leave1
", 6);
# abiretf a0: a float or double result where the ABI has it (s0, d0; a
# variadic function's r0, r0:r1): a0 = 1
# for a double, which then needs no copy into a struct's room
$h .= fn('abiretf', "
    enter1
    mv a0 s4
    call abion
    beqz L8 t0
    call tscalar
    li 36 t0
    bne rel:L1 t0 a0
    la ccs t0
    ld CC_va t0 t0
    bnez L8 t0
    la cc_retf a0
    call seq
    j L8
    L1:
    mv s4 a0
    call fwide
    beqz L9 a0
    la cc_retd a0
    la ccs t0
    ld CC_va t0 t0
    beqz L2 t0
    la cc_retdr a0
    L2:
    call seq
    li 1 a0
    leave1
    L8:
    li 0 a0
    L9:
    leave1
", 6);
# abivastart a0: V = where va_start begins (argaddr's, or the ABI's)
$h .= fn('abivastart', "
    enter1
    mv a0 s4
    call abion
    bnez L1 t0
    mv s4 a0
    call argaddr
    leave1
    L1:
    la abi_vanext t0
    ld 0 t0 a0
    slli 2 a0 s4
    call argoff
    add a0 s4 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    leave1
", 6);
# abivaarg a0 a1: va_arg of the va_list a0, type a1, by the ABI (a0 = 1),
# or not (a0 = 0): a pair or a double 8-aligned (a double's value the
# address of its words in the array, a struct's the address its word
# holds); the list goes up past it
$h .= fn('abivaarg', "
    enter5
    mv a0 s4
    mv a1 s5
    call abion
    beqz L9 t0
    mv s4 a0
    call leafval
    li 4 s6
    li 0 s8
    mv s5 a0
    call fwide
    beqz LA a0
    li 8 s6
    li 1 s8
    j L0
    LA:
    mv s5 a0
    call inmem
    beqz LB a0
    li 2 s8
    j L1
    LB:
    mv s5 a0
    call ispair
    beqz L1 a0
    li 8 s6
    L0:
    li 7 a0
    la cc_opseq a1
    addi 800 a1 a1
    call opk
    li -8 a0
    la cc_opseq a1
    addi 350 a1 a1
    call opk
    L1:
    call push
    la ccs t0
    ld CC_depth t0 s7
    mv s6 a0
    la cc_opseq a1
    addi 800 a1 a1
    call opk
    mv s4 a0
    call setlv
    mv s7 a0
    call fpword
    li 1 t0
    beq rel:L2 t0 s8
    mv s5 a0
    li 2 t0
    bne rel:LC t0 s8
    li TY_LONG a0
    LC:
    call load
    L2:
    call popt0
    mv s5 a0
    call setty
    li 1 a0
    leave5
    L9:
    li 0 a0
    leave5
", 6);
# abivapush: va_arg_pack's words pushed, the last first (cc_vapush), so that
# they lie in order; the depth before them kept for abicall
$h .= fn('abivapush', "
    enter1
    la ccs t0
    ld CC_depth t0 t1
    la abi_vadepth t0
    sd 0 t1 t0
    la cc_vapushn a0
    li 3 a1
    la abi_vacnt t0
    ld 0 t0 a2
    la abi_vanext t0
    ld 0 t0 a4
    slli 2 a4 a3
    addi 8 a3 a3
    li 0 a5
    call prim
    leave1
", 6);
# abivapackm: V = the count of the extra words of the function being compiled
$h .= fn('abivapackm', "
    enter1
    la abi_vacnt t0
    ld 0 t0 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li TY_LONG a0
    call load
    la abi_vanext t0
    ld 0 t0 a0
    neg a0 a0
    li R_t1 a1
    call li
    la cc_add_t1 a0
    call seq
    leave1
", 6);
# abiseq a0 a1 a2: seq a1, or a2 for a variadic function by the ABI
$h .= fn('abiseq', "
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    call abion
    beqz L1 t0
    mv s4 a0
    call isvafn
    beqz L1 a0
    mv s6 s5
    L1:
    mv s5 a0
    call seq
    leave3
", 6);
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
for my $x (['cc_stsp', "\x01cc_stsp\0"], ['cc_callp', "\x01cc_callp\0"], ['cc_callt', "\x01cc_callt\0"],
           ['cc_enterva', "\0cc_enter_va\0"], ['cc_leaveva', "\0cc_leave_va\0"], ['cc_pushl', "\0cc_pushl\0"],
           ['cc_callpfp', "\x01cc_callp_fp\0"], ['cc_argfp', "cc_arg_fp\0"], ['cc_vacnt', "cc_vacount\0"], ['cc_vapushn', "cc_vapush\0"],
           ['cc_argd', "cc_arg_d\0"], ['cc_argf', "cc_arg_f\0"], ['cc_stkd', "cc_stk_d\0"], ['cc_argdr', "cc_arg_dr\0"],
           ['cc_resf', "\0cc_res_f\0"], ['cc_resd', "\x01cc_res_d\0"], ['cc_paramf', "\x01cc_param_f\0"], ['cc_paramd', "\x01cc_param_d\0"],
           ['cc_retf', "\0cc_ret_f\0"], ['cc_retd', "\0cc_ret_d\0"], ['cc_pushr', "\0cc_push_r\0"], ['cc_resdr', "\x01cc_res_dr\0"], ['cc_retdr', "\0cc_ret_dr\0"]) {
    my ($l, $b) = @$x;
    $b .= "\0" x (-length($b) % 8);
    $h .= "      $l:\n        ascii\n          " . esc($b) . "\n";
}
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $h;
}
save();
