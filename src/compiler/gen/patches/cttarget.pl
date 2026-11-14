# cttarget.pl: a global's items worked out while compiling take the
# target's sizes. gval (a global's : of one expression) and pairv (a
# two-word global's) run the item's code at compile time (ctrun, jit),
# compiled for the host, where word8 keeps 8 for a long and a pointer
# (CC_jit): compile time is the host's, but a global's value is the
# program's, so sizeof and alignof of long or of a pointer were 8 on arm
# (glibc's malloc mp_.arena_test, sizeof (long) == 4 ? 2 : 8, was 8; found
# by src/glibc's datacheck). Now ct_targ is 1 while ctrun works out such an
# item, and word8 (a long's size) and newtype (a pointer's) give the
# target's word then too. (Its arithmetic is
# still the host's, a long 64 bits.) Test ctsize (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  targ_word:\n", "  ct_targ:\n    dword\n      0\n  targ_word:\n", 'ct_targ');

edit(\$t, 'word8', asm(8, "
    la ccs t0
    ld CC_jit t0 t0
    bnez L1 t0
    la targ_word t0
    ld 0 t0 a0
") => asm(8, "
    la ccs t0
    ld CC_jit t0 t0
    beqz L4 t0
    la ct_targ t0
    ld 0 t0 t0
    beqz L1 t0
L4:
    la targ_word t0
    ld 0 t0 a0
"));

# (newtype: a pointer's size and alignment, the same way)
edit(\$t, 'newtype', asm(8, "
    la ccs t1
    ld CC_jit t1 t1
    bnez L2 t1
    la targ_word t1
    ld 0 t1 t0
") => asm(8, "
    la ccs t1
    ld CC_jit t1 t1
    beqz L3 t1
    la ct_targ t1
    ld 0 t1 t1
    beqz L2 t1
L3:
    la targ_word t1
    ld 0 t1 t0
"));

edit(\$t, 'gval', asm(10, "
    la ctconst a1
    call ctrun
") => asm(10, "
    li 1 t1
    la ct_targ t0
    sd 0 t1 t0
    la ctconst a1
    call ctrun
    la ct_targ t0
    sd 0 zero t0
"));
edit(\$t, 'pairv', asm(8, "
    la pairconst a1
    call ctrun
") => asm(8, "
    li 1 t1
    la ct_targ t0
    sd 0 t1 t0
    la pairconst a1
    call ctrun
    la ct_targ t0
    sd 0 zero t0
"));
save();
