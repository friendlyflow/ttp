# ctldarm.pl (fault 25, arm): on arm (EABI: long double is double, the
# target's word 4 bytes) cast / long double is a cast to TY_DOUBLE, which
# ctldlit.pl's gval left to the compile-time run: cast / long double of an
# L literal is now the literal there too, as hexf makes it (arm's double).
# The run gave the right double on a riscv64 host, but on an arm host a
# global's double that compile time works out is wrong (another fault:
# d: double / : / 0x1.8p+0 / * / 0x1p+1 is not 3 there; reported), and
# chello-arm's cctldlit failed. A cast / double of an L literal on the
# other targets still converts (binary128 or x87 to double).
# Test: cctldlit (chello-arm: built on arm).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/gval', asm(12, "
bnez LDC9 t3
li TY_DOUBLE t4
beq rel:LDN t4 s8
ld NODE_content t2 t4
") => asm(12, "
bnez LDC9 t3
li TY_DOUBLE t4
bne rel:LDL t4 s8
la targ_word t4
ld 0 t4 t4
li 8 t5
beq rel:LDN t5 t4
") . asm(12, "
LDL:
ld NODE_content t2 t4
"));
save();
