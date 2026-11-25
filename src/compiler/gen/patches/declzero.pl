# declzero.pl: a local declared with no value is 0 of its type with no
# conversion (cmpdcvt.pl's follow-up, found by ports-check14's gccrt-check):
# decl's L5 gave such a local an int 0, and cmpdcvt's conversion at L8 then
# made it the local's floating type at run time, through the runtime's
# function where the target has no instruction for it: riscv64's
# __truncdfhf2 declares r: float16, so it called itself until the stack
# ran out (gccrt-prog: SIGSEGV), and a program without libgcc stopped "no
# definition of the runtime function __truncdfhf2". Zero bits are 0 of every
# scalar type, as before cmpdcvt: L5 goes past the conversion (LQ9). Test:
# progs/cdeclzero.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc/decl',
    "        L5:\n          li\n            0\n            a0\n          li\n            R_a0\n            a1\n          call\n            li\n          li\n            TY_INT\n            a0\n          call\n            setty\n        L8:\n" =>
    "        L5:\n          li\n            0\n            a0\n          li\n            R_a0\n            a1\n          call\n            li\n          li\n            TY_INT\n            a0\n          call\n            setty\n          j\n            LQ9\n        L8:\n");
save();
