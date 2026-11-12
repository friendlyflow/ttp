# ctldouble.pl: a global's items worked out while compiling take the
# target's long double too (after cttarget.pl's long and pointers): tyname
# named the host's long double under the JIT, 16 bytes aligned to 16 on an
# x86_64 or riscv64 machine, where arm's is a double, 8 and 8 (glibc's
# malloc mp_.tcache_bins (MALLOC_ALIGNMENT, alignof (long double)) was 1025
# for gcc's 521 on arm: found by src/glibc's datacheck). Now with ct_targ
# set tyname gives the target's, as it does outside the JIT. Test ctsize.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'tyname', asm(8, "
LD:
    la ccs t0
    ld CC_jit t0 t0
    bnez L3 t0
    la targ_abi t0
") => asm(8, "
LD:
    la ccs t0
    ld CC_jit t0 t0
    beqz LDT t0
    la ct_targ t0
    ld 0 t0 t0
    beqz L3 t0
LDT:
    la targ_abi t0
"));
save();
