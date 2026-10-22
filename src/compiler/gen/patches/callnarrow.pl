# callnarrow.pl: a call's result of an integer type narrower than a word
# is narrowed to its type where the call returns (as a64res does on
# aarch64): the callee returns its value as it computed it (extractbyte's
# u8 x >> (idx * 8) kept the bytes above), and an expression that uses the
# call (final_cmp's extractbyte w1 idx - extractbyte w2 idx) takes it as
# its type, so glibc's strcmp said "__vdso_clock_gettime" differs from
# itself where the bytes after its end were not zero. Test: cnarrowret.
# Run on ttpc.ff after ctor.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/call', "        L7:\n          mv\n            s6\n            a0\n          call\n            setty\n          leave8\n", asm(8, "
L7:
    lui TY_REC t0
    bgeu rel:LN9 t0 s6
    andi 32 s6 t0
    bnez LN9 t0
    andi 15 s6 t0
    beqz LN9 t0
    li 8 t1
    bge rel:LN9 t1 t0
    mv s6 a0
    call narrow
LN9:
    mv s6 a0
    call setty
    leave8
"));
save();
