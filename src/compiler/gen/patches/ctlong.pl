# ctlong.pl: a global's items worked out while compiling (ctrun, under
# ct_targ: cttarget.pl) on a target of 4-byte words take long as the
# target's, int's type code: sizeof (long long) was 4 on arm. While compiling,
# i64 and u64 keep the host's code, 0x08, long's too (pairs.pl gives them
# their pair codes outside compile time alone), and cttarget.pl's word8 took
# every 8-byte size for the target's word: glibc's mktime_max, TYPE_MAXIMUM
# (long long), was 0x7fffffff, and timegm of 2038 failed (time's
# tst-timegm-time64, tst-mktime4-time64, tst-strftime4-time64). Now tyname
# gives long and va_list int's code then (ctlong), so a long there is the
# target's in size and arithmetic, and word8 maps no size while compiling.
# Test cctlong (4 targets). After pairs.pl and cttarget.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# (ctlong, tyname's lookup of a code: a0 the name's index in cc_tynames, its
# code in a0, int's for long (3) and va_list (14) while ct_targ is set on a
# 4-byte target; t0 alone, as the lookup it takes the place of)
# (before tyname, which nothing falls into: tsize falls into word8)
{
    my ($from) = find(\$t, 'tyname');
    substr($t, $from, 0) = fn('ctlong', "
    li 3 t0
    beq rel:L1 t0 a0
    li 14 t0
    beq rel:L1 t0 a0
L9:
    la cc_tycodes t0
    add a0 t0 t0
    lbu 0 t0 a0
    ret
L1:
    la ccs t0
    ld CC_jit t0 t0
    beqz L9 t0
    la ct_targ t0
    ld 0 t0 t0
    beqz L9 t0
    la targ_word t0
    ld 0 t0 t0
    addi -8 t0 t0
    beqz L9 t0
    li 4 a0
    ret
", 6);
}

edit(\$t, 'tyname', asm(8, "
L5:
    la cc_tycodes t0
    add a0 t0 t0
    lbu 0 t0 a0
") => asm(8, "
L5:
    call ctlong
"));

edit(\$t, 'word8', asm(8, "
    la ccs t0
    ld CC_jit t0 t0
    beqz L4 t0
    la ct_targ t0
    ld 0 t0 t0
    beqz L1 t0
L4:
    la targ_word t0
    ld 0 t0 a0
") => asm(8, "
    la ccs t0
    ld CC_jit t0 t0
    bnez L1 t0
    la targ_word t0
    ld 0 t0 a0
"));
save();
