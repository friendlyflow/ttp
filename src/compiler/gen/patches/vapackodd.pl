# vapackodd.pl: on arm a va_arg_pack call whose arguments before it take
# a number of core registers of other parity than its function's own named
# ones stops naming the callee (the master's arm parity gap, after faults
# 32 and 33). vapackpad.pl's padding counts the words abicall drops as 4
# less the function's named words; the call's own (48(sp)) of other parity
# would leave SP 4 off 8-aligned, and the callee's va_arg would read a
# double a word off. The other ABI targets take no other fixed arguments at
# all (vapackfix.pl). Test: progs/cvapackfixfail2 (ctime, every target).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'abicall', "          ld\n            8\n            sp\n            t1\n          beqz\n            L4\n            t1\n          mv\n            s5\n            a0\n          call\n            vafixbad\n" =>
    "          ld\n            8\n            sp\n            t1\n" . asm(10, "
    ld 48 sp t2
    la abi_vanext t3
    ld 0 t3 t3
    xor t3 t2 t2
    andi 1 t2 t2
    or t2 t1 t1
") . "          beqz\n            L4\n            t1\n          mv\n            s5\n            a0\n          call\n            vafixbad\n");
save();
