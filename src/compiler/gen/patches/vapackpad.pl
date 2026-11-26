# vapackpad.pl: on arm a forwarded va_arg_pack leaves SP 8-aligned at the
# call (the master's faults 32 and 33). abivapush pushes the function's
# extra words (cc_vapush, their count known only at run time), abicall then
# loads the first of them into the free argument registers and drops them;
# the stack the callee got was 8-aligned or not by the parity of that
# count, and the AAPCS's va_arg (a double at an 8-aligned word of the kept
# registers and the stack after them) read a double of the pack a word off:
# a double after a long (32), a pack after an i64 named parameter (33).
# Now cc_vapush takes par, the parity of the depth below FP before it plus
# the words abicall drops (4 less the function's named words, if fewer),
# and pushes a word of padding first where the count and par make the
# stack odd (macros/arm.ff.txt; prim takes a fourth argument as text: vapar
# gives "0" or "1"; its buffers hold four now, prim_ptrs and prim_argn had
# room for three). Test: progs/cvapackarm.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'abivapush',
    "        la\n          abi_vadepth\n          t0\n        sd\n          0\n          t1\n          t0\n        la\n          cc_vapushn\n          a0\n        li\n          3\n          a1\n" =>
    "        la\n          abi_vadepth\n          t0\n        sd\n          0\n          t1\n          t0\n" . asm(8, "
    call vapar
    mv a0 s4
    la cc_vapushn a0
    li 4 a1
"),
    "        addi\n          8\n          a3\n          a3\n        li\n          0\n          a5\n" =>
    "        addi\n          8\n          a3\n          a3\n        mv\n          s4\n          a5\n");
{
    my ($from, $to) = find(\$t, 'cc/stmts');
    substr($t, $to, 0) = fn('vapar', "
    la abi_vanext t0
    ld 0 t0 t1
    la ccs t0
    ld CC_depth t0 t2
    srli 2 t2 t2
    li 4 t3
    bge rel:VP1 t3 t1
    add t1 t2 t2
VP1:
    andi 1 t2 a0
    slli 1 a0 a0
    la VPS t1
    add t1 a0 a0
    ret
", 6) . "        VPS:\n          ascii\n            0\\x001\\x00\n          align\n            4\n";
}
once(\$t, "  prim_args:\n    reserve\n      24\n  prim_ptrs:\n    reserve\n      24\n",
    "  prim_args:\n    reserve\n      32\n  prim_ptrs:\n    reserve\n      32\n", 'prim_args');
once(\$t, "  prim_argn:\n    reserve\n      192\n  prim_text:\n    reserve\n      72\n",
    "  prim_argn:\n    reserve\n      256\n  prim_text:\n    reserve\n      96\n", 'prim_argn');
save();
