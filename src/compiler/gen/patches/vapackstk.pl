# vapackstk.pl: va_arg_pack passes on the arguments its function got on the
# stack too (the master's fault 29: on x86_64 glibc's assert message came
# out garbled). On the ABI targets (x86_64, aarch64, riscv64) a call that
# ends in va_arg_pack reloaded the argument registers the function kept
# (x64fwd, a64fwd, rvfwd) and gave the count, but nothing of the stack: the
# callee read its stack arguments from whatever lay at its caller's SP
# (__libc_message_wrapper's 9 arguments on x86_64: function, ": " and the
# assertion took the format's and the vmaname's places). The fixed
# arguments of such a call are those of the function (x64call's check), so
# the arguments its caller put on the stack go out as they came in: the
# call has FWSTK words (32, 256 bytes) of stack for them, and the fwd
# copies them from the function's incoming stack (FP + argoff, on riscv64
# past its 64 bytes of kept registers: rvstk) to SP + 0 ... (more of them
# are not passed on). Test: progs/cvapackstk (2 named, up to 30 more:
# longs, doubles, a struct), the program's own pass against a direct call.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $FW = 32;
my $L4 = "        L4:\n          ld\n            16\n            sp\n            t0\n";
for my $f (qw(x64call a64call rvcall)) {
    edit(\$t, $f, $L4 => "        L4:\n" . asm(10, "
    ld 40 sp t0
    seqz t0 t0
    seqz t0 t0
    li " . ($FW * 8) . " t1
    mul t1 t0 t0
    ld 16 sp t1
    add t1 t0 t1
    sd 16 t1 sp
    ld 16 sp t0
"));
}
my $L3 = "        L3:\n          la\n            abi_vacnt\n            t0\n";
my %copy = (
    x64fwd => ["call argoff", "la x64n_stk a0\n li 2 a1\n add s6 s5 a2\n mv s6 a3\n call a64p"],
    a64fwd => ["call argoff", "la a64n_stk a0\n li 2 a1\n add s6 s5 a2\n mv s6 a3\n call a64p"],
    rvfwd  => ["call rvstk", "la rvn_ld8 a0\n li 2 a1\n li 6 a2\n add s6 s5 a3\n call a64p\n la rvn_st a0\n li 1 a1\n mv s6 a2\n call a64p"],
);
for my $f (sort keys %copy) {
    my ($base, $cp) = @{$copy{$f}};
    my $chk = $f eq 'rvfwd' ? "
    li " . (2000 - $FW * 8) . " t0
    blt rel:LW1 t0 s5
    li 0 a0
    call bad
" : "";
    # rvfwd's enter3 keeps s4 s5 s6 (s4 is its count): s5 and s6 are free here
    edit(\$t, $f, $L3 => asm(8, "
L3:
    $base
    la ccs t0
    ld CC_depth t0 t1
    add t1 a0 s5
    li 0 s6
$chk
LW1:
    li " . ($FW * 8) . " t0
    bge rel:LW2 t0 s6
    $cp
    addi 8 s6 s6
    j LW1
LW2:
") . "          la\n            abi_vacnt\n            t0\n");
}
save();
