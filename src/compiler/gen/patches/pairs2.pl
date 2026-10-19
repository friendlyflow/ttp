# pairs2.pl: calls with pairs (i64 and u64 on arm, see pairs.pl). An
# argument is converted to its parameter's type where the callee is known
# (argpush, ptype), and a pair is pushed as two slots, its low word first;
# args keeps a mask of the pairs and leaves it, the count and the slots in
# pair_args for the call being made (psetargs; no call is made between args
# and the call's own pops, so one place is enough). The registers r0..r7
# take the arguments in order, a pair the next even pair (r0:r1, r2:r3,
# r4:r5, r6:r7) as the AAPCS has it, an odd register it skips staying empty;
# from the first argument that does not fit, it and all after it are on the
# stack (nfits, popargs2, popregs2), where every argument stays pushed, as
# past 8 arguments before. A variadic call pushes the count of its slots, not
# of its arguments. The callee lays its parameters out the same way (pplan,
# pparam); va_start begins after the fixed parameters' slots and va_arg of a
# pair takes two (vaargp). The result is V, r0:r1. Where no argument is a
# pair (every target but arm), every step does what it did before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# pwassign gives V the type it converted to
E('cc/pwassign', 10, "
    mv s5 a0
    mv s4 a1
    call fcvt
", "
    mv s5 a0
    mv s4 a1
    call fcvt
    mv s4 a0
    call setty
");

# args: a1 the callee (or 0), each argument through argpush, the mask left
# for the call
E('cc/args', 8, "
    enter8
    call open
", "
    enter8
    addi -16 sp sp
    sd 0 a1 sp
    sd 8 zero sp
    call open
");
E('cc/args', 10, "
    li 1 a0
    call expr
    call push
    addi 1 s6 s6
", "
    li 1 a0
    call expr
    mv s6 a0
    mv sp a1
    call argpush
    addi 1 s6 s6
");
E('cc/args', 8, "
    L2:
    mv s4 a0
    mv s5 a1
    call close
    mv s6 a0
    mv s9 a1
    leave8
", "
    L2:
    mv s4 a0
    mv s5 a1
    call close
    mv s6 a0
    ld 8 sp a1
    call psetargs
    mv s6 a0
    mv s9 a1
    addi 16 sp sp
    leave8
");

# call: the callee for the conversions, the registers and slots by the mask
E('cc/call', 10, "
    mv s4 a0
    call args
    mv a0 s9
    mv a1 s11
    mv s5 a0
    call isvafn
    bnez L8 a0
    bnez L45 s11
    li 8 t0
    blt rel:L3 s9 t0
    bnez L3 s7
    mv s9 a0
    li 0 a1
    call popargs
", "
    mv s4 a0
    mv s5 a1
    call args
    mv a0 s9
    mv a1 s11
    mv s5 a0
    call isvafn
    bnez L8 a0
    bnez L45 s11
    call nfits
    bnez L3 a0
    bnez L3 s7
    mv s9 a0
    li 0 a1
    call popargs2
");
E('cc/call', 8, "
    L4:
    mv s9 a0
    mv s7 a1
    call popregs
", "
    L4:
    mv s9 a0
    mv s7 a1
    call popregs2
");
E('cc/call', 10, "
    la cc_auipc_ra a0
    call seq
    li 8 t0
    blt rel:L6 s9 t0
", "
    la cc_auipc_ra a0
    call seq
    call nfits
    bnez L6 a0
");
E('cc/call', 8, "
    L6:
    add s7 s9 s10
", "
    L6:
    call nslots
    add s7 a0 s10
");
E('cc/call', 8, "
    L47:
    call push
    mv s4 a0
    call args
    li 0 a1
    call popargs
", "
    L47:
    call push
    mv s4 a0
    li 0 a1
    call args
    li 0 a1
    call popargs2
");
E('cc/call', 8, "
    L8:
    bnez L42 s11
    mv s9 a0
    li R_a0 a1
", "
    L8:
    bnez L42 s11
    call nslots
    li R_a0 a1
");
E('cc/call', 10, "
    addi 1 s9 s10
    add s7 s10 s10
", "
    call nslots
    addi 1 a0 s10
    add s7 s10 s10
");
E('cc/call', 8, "
    L42:
    call vapackm
    mv s9 a0
    li R_t1 a1
", "
    L42:
    call vapackm
    call nslots
    li R_t1 a1
");
# a call through an address, a system call, compile time's workspace calls
E('cc/index', 10, "
    mv s4 a0
    call args
    li 0 a1
    call popargs
", "
    mv s4 a0
    li 0 a1
    call args
    li 0 a1
    call popargs2
");
E('cc/syscall', 8, "
    mv a0 s4
    call args
    beqz L1 a0
", "
    mv a0 s4
    li 0 a1
    call args
    call nomask
    beqz L1 a0
");
E('cc/wsop', 8, "
    mv s4 a0
    call args
", "
    mv s4 a0
    li 0 a1
    call args
");

# the callee: its parameters' slots (pplan), each one's register or slot
E('cc/fnbody', 10, "
    call isva
", "
    call isva
    mv s6 a0
    mv s11 a1
    call pplan
");
edit(\$t, 'cc/fnbody', asm(10, "
    la ccs t0
    ld CC_va t0 t0
    beqz L10 t0
    mv s7 a0
    call argaddr
    li TY_LONG a0
    call load
    j L6
") . asm(8, "
    L10:
    li 8 t0
    blt rel:L5 t0 s7
    mv s7 a0
    mv s11 a1
    call stackparam
    j L6
    L5:
    la cc_param a0
    mv s7 a1
    call seq
") => asm(10, "
    mv s7 a0
    mv s9 a1
    mv s11 a2
    call pparam
"));

# va_arg of a pair
E('cc/vaarg', 10, "
    mv a0 s6
    ld 0 s5 s5
", "
    mv a0 s6
    ld 0 s5 s5
    mv s5 a0
    mv s6 a1
    call vaargp
    bnez VAP a0
");
{
    my ($from, $to) = find(\$t, 'cc/vaarg');
    substr($t, $to, 0) = asm(8, "
        VAP:
        leave5
    ");
}

# the variables: the call being made, the parameters being laid out
once(\$t, "  targ_word:\n    dword\n      8\n", "  targ_word:\n    dword\n      8\n"
    . join('', map { "  $_:\n    dword\n      0\n" } qw(pair_args pair_args_mask pair_args_slots
      pair_params pair_params_q pair_params_p pair_params_spill)), 'pairs2: the variables');

my $h = '';
$h .= fn('psetargs', "
    la pair_args t0
    sd 0 a0 t0
    sd 8 a1 t0
    mv a0 t1
    L1:
    beqz L9 a1
    andi 1 a1 t2
    add t2 t1 t1
    srli 1 a1 a1
    j L1
    L9:
    sd 16 t1 t0
    ret
", 6);
$h .= fn('nslots', "
    la pair_args t0
    ld 16 t0 a0
    ret
", 6);
$h .= fn('nfits', "
    la pair_args t0
    ld 0 t0 a1
    ld 8 t0 a2
    li 0 a3
    L1:
    beqz L8 a1
    andi 1 a2 a4
    beqz L2 a4
    addi 1 a3 a3
    andi -2 a3 a3
    L2:
    add a4 a3 a3
    addi 1 a3 a3
    li 8 a5
    blt rel:L7 a3 a5
    srli 1 a2 a2
    addi -1 a1 a1
    j L1
    L7:
    li 1 a0
    ret
    L8:
    li 0 a0
    ret
", 6);
$h .= fn('nomask', "
    la pair_args t0
    ld 8 t0 t0
    bnez L8 t0
    ret
    L8:
    li 0 a0
    call bad
", 6);
# popargs2 a0 a1: popargs, the pairs of the call's mask in register pairs.
# popregs2 a0 a1: popregs (a1: the slot of a result's address below them),
# the same, the arguments left on the stack. Both by argregs.
$h .= fn('popargs2', "
    enter2
    la pair_args t0
    ld 8 t0 t0
    bnez L1 t0
    call popargs
    leave2
    L1:
    li 0 a2
    li 1 a3
    call argregs
    mv a0 s4
    call popped
    call slot
    mul a0 s4 a1
    la cc_addsp a0
    call seq
    leave2
", 6);
$h .= fn('popregs2', "
    enter2
    la pair_args t0
    ld 8 t0 t0
    bnez L1 t0
    call popregs
    leave2
    L1:
    mv a1 a2
    li 0 a1
    li 0 a3
    call argregs
    leave2
", 6);
# argregs a1 (1: a system call's), a2 (the slots below the arguments), a3
# (1: all fit, popargs2): the argument registers from the pushed slots, by
# the mask; a0 = the slots of the arguments
$h .= fn('argregs', "
    enter8
    mv a2 s10
    la cc_names s5
    addi 30 s5 s5
    beqz L3 a1
    addi 7 s5 s5
    L3:
    la pair_args t0
    ld 0 t0 s4
    ld 8 t0 s9
    ld 16 t0 s8
    call slot
    mv a0 s7
    li 0 s6
    li 0 s11
    L1:
    beqz L9 s4
    andi 1 s9 t0
    bnez L4 t0
    li 8 t1
    bge rel:L9 t1 s11
    sub s6 s8 t0
    addi -1 t0 t0
    add s10 t0 t0
    mul s7 t0 a3
    mv s11 a2
    li 2 a1
    mv s5 a0
    li 0 a5
    call prim
    addi 1 s11 s11
    addi 1 s6 s6
    j L5
    L4:
    addi 1 s11 s11
    andi -2 s11 s11
    addi 1 s11 t0
    li 8 t1
    bge rel:L9 t1 t0
    sub s6 s8 t0
    addi -2 t0 t0
    add s10 t0 t0
    mul s7 t0 a3
    mv s11 a2
    li 2 a1
    mv s5 a0
    li 0 a5
    call prim
    sub s6 s8 t0
    addi -1 t0 t0
    add s10 t0 t0
    mul s7 t0 a3
    addi 1 s11 a2
    li 2 a1
    mv s5 a0
    li 0 a5
    call prim
    addi 2 s11 s11
    addi 2 s6 s6
    L5:
    srli 1 s9 s9
    addi -1 s4 s4
    j L1
    L9:
    mv s8 a0
    leave8
", 6);
# argpush a0 a1: argument a0 of the call, the frame of args at a1 (the
# callee at 0, the mask at 8): converted to its parameter's type, pushed
$h .= fn('argpush', "
    enter3
    mv a0 s4
    mv a1 s5
    ld 0 s5 a0
    mv s4 a1
    call ptype
    bltz L1 a0
    call pwassign
    L1:
    call getty
    mv a0 s6
    call pushv
    mv s6 a0
    call ispair
    beqz L9 a0
    li 64 t0
    bge rel:L8 t0 s4
    li 1 t0
    sll s4 t0 t0
    ld 8 s5 t1
    or t0 t1 t1
    sd 8 t1 s5
    L9:
    leave3
    L8:
    li 0 a0
    call bad
", 6);
# ptype a0 a1: the type of parameter a1 of the function a0, or -1
$h .= fn('ptype', "
    enter5
    mv a0 s4
    mv a1 s5
    beqz L8 s4
    mv s4 a0
    call kind
    li 1 t0
    bne rel:L8 t0 a0
    ld NODE_children s4 s6
    lbu NODE_children_len s4 s7
    slli 3 s7 s7
    add s6 s7 s7
    beq rel:L8 s7 s6
    ld 0 s6 a0
    call ismark
    bnez L2 a0
    mv s6 a0
    mv s7 a1
    call typerun
    mv a1 s6
    j L3
    L2:
    addi 8 s6 s6
    L3:
    bgeu rel:L8 s7 s6
    ld 0 s6 a0
    call isparam
    bltz L8 a0
    beqz L4 s5
    addi -1 s5 s5
    addi 8 s6 s6
    j L3
    L4:
    ld 0 s6 a0
    lbu NODE_children_len a0 t0
    ld NODE_children a0 a0
    slli 3 t0 t0
    add a0 t0 a1
    call typerun
    leave5
    L8:
    li -1 a0
    leave5
", 6);
# pplan a0 a1: the parameters (a1 of them, from a0) of the function being
# compiled: their slots; a variadic one's fixed parameters as slots
$h .= fn('pplan', "
    enter3
    mv a0 s4
    mv a1 s5
    li 0 s6
    L1:
    beqz L2 s5
    ld 0 s4 a0
    lbu NODE_children_len a0 t0
    ld NODE_children a0 a0
    slli 3 t0 t0
    add a0 t0 a1
    call typerun
    call ispair
    addi 1 a0 a0
    add a0 s6 s6
    addi 8 s4 s4
    addi -1 s5 s5
    j L1
    L2:
    la pair_params t0
    sd 0 s6 t0
    sd 8 zero t0
    sd 16 zero t0
    sd 24 zero t0
    la ccs t1
    ld CC_va t1 t2
    beqz L9 t2
    sd CC_nfix s6 t1
    L9:
    leave3
", 6);
# pparam a0 a1 a2: V = parameter a0 (the variable a1) of a2: from its
# register or pair, its slot on the stack, or a variadic function's slot
$h .= fn('pparam', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    ld VAR_type s5 s7
    mv s7 a0
    call ispair
    addi 1 a0 s8
    la pair_params s9
    ld 8 s9 s10
    la ccs t0
    ld CC_va t0 t0
    beqz L10 t0
    add s8 s10 a0
    addi -1 a0 a0
    call argaddr
    li TY_LONG a0
    li 1 t0
    beq rel:L1 t0 s8
    mv s7 a0
    L1:
    call load
    j L9
    L10:
    ld 24 s9 t0
    bnez L20 t0
    ld 16 s9 s11
    li 1 t0
    beq rel:L11 t0 s8
    addi 1 s11 s11
    andi -2 s11 s11
    L11:
    add s8 s11 t0
    li 8 t1
    blt rel:L19 t0 t1
    sd 16 t0 s9
    li 1 t0
    bne rel:L12 t0 s8
    la cc_param a0
    mv s11 a1
    call seq
    j L9
    L12:
    la cc_paramp a0
    li 1 a1
    mv s11 a2
    li 0 a5
    call prim
    j L9
    L19:
    li 1 t0
    sd 24 t0 s9
    L20:
    ld 0 s9 t0
    li 1 t1
    bne rel:L21 t1 s8
    add s8 s10 a0
    addi -1 a0 a0
    mv t0 a1
    call stackparam
    j L9
    L21:
    sub s10 t0 s4
    addi -2 s4 s4
    la ccs t0
    ld CC_rty t0 a0
    call inmem
    add a0 s4 s4
    call slot
    mul a0 s4 s4
    call argoff
    add a0 s4 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s7 a0
    call load
    L9:
    ld 8 s9 t0
    add s8 t0 t0
    sd 8 t0 s9
    leave8
", 6);
# vaargp a0 a1: va_arg (the va_list a0) of a pair (type a1), else a0 = 0: the
# va_list goes down two slots, the pair is in the two below where it was
$h .= fn('vaargp', "
    enter3
    mv a0 s4
    mv a1 s5
    mv s5 a0
    call ispair
    beqz L9 a0
    mv s4 a0
    call leafval
    call push
    la ccs t0
    ld CC_depth t0 s6
    call slot
    slli 1 a0 a0
    la cc_opseq a1
    addi 850 a1 a1
    call opk
    mv s4 a0
    call setlv
    mv s6 a0
    call fpword
    call slot
    la cc_opseq a1
    addi 850 a1 a1
    call opk
    mv s5 a0
    call load
    call popt0
    mv s5 a0
    call setty
    li 1 a0
    L9:
    leave3
", 6);
$h .= "      cc_paramp:\n        ascii\n          cc_param_p\\x00\\x00\\x00\\x00\\x00\\x00\n";
{   # after the helpers of pairs.pl, in their layer
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $h;
}
save();
