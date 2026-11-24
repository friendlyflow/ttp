# ctldlit.pl (fault 25): a long double literal in a global's item worked
# out while compiling is the target's long double, as outside compile time:
# on arm (EABI: long double is double) the nearest double. hexf (ldlit.pl)
# left the literal binary128 under the JIT, whatever the target, so arm's
# fma_test_data (glibc's test-double-ldouble-fma: 0x1.ff...p+16383L /
# 0x1p+1L) called __divtf3, and cast / long double of a literal
# __trunctfdf2, which arm's libgcc has not ("no definition of the runtime
# function"). Now with ct_targ set (cttarget.pl, ctldouble.pl's rule: the
# compile-time types are the target's) hexf rounds it as outside the JIT.
# And gval takes cast / long double of such a literal (not of a double)
# as the literal itself, as it does the literal alone: it went to the
# compile-time run, whose value came back as one word (riscv64's
# cast / long double / 0x1p+1L was 0xb0 and zeros: a global's bytes
# against the literal's; x86_64's called __trunctfxf2 there).
# Test: cctldlit (4 targets), cctldarm (arm: a / and a * of literals).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'hexf', asm(10, "
    la ccs t0
    ld CC_jit t0 t0
    bnez LX t0
    la targ_word t0
") => asm(10, "
    la ccs t0
    ld CC_jit t0 t0
    beqz LWT t0
    la ct_targ t0
    ld 0 t0 t0
    beqz LX t0
") . asm(10, "
LWT:
    la targ_word t0
"));
edit(\$t, 'cc/gval', asm(12, "
bnez LDC9 t3
ld NODE_content t2 a0
lbu NODE_content_len t2 a1
call parse_num
") => asm(12, "
bnez LDC9 t3
li TY_DOUBLE t4
beq rel:LDN t4 s8
ld NODE_content t2 t4
lbu NODE_content_len t2 t5
add t5 t4 t4
lbu -1 t4 t4
li 76 t5
bne rel:LDN t5 t4
addi 8 s4 a0
mv s7 a1
call gval
j L9
") . asm(12, "
LDN:
ld NODE_content t2 a0
") . asm(12, "
lbu NODE_content_len t2 a1
call parse_num
"));
save();
