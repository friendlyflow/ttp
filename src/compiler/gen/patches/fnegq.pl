# fnegq.pl: - of a long double (binary128 in memory: riscv64, x86_64,
# aarch64) flips its sign bit, as gcc does, into a temporary of the
# function (cc_fneg_q, as double's in memory on arm, cc_fneg_dm), where it
# called soft-fp's __negtf2: at compile time (a global's item - 0x0p+0L,
# tst-strtod5's tables) that has no code yet, and the call went to address
# 0. And a soft-fp call at compile time that has no code (wcall) stops
# with its name (jitaddr, as jitcall.pl's calls). The sequences are
# shared.ff's (fnegqseq.pl). Test: cldneg's - of long doubles, chexinf.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'unary',
    asm(8, "W2:\ncall push\nli 10 a0\nli 1 a1\nmv s6 a2\ncall wcall\nj L9\n") => asm(8, "
W2:
    call wtemp
    neg a0 a0
    li R_t1 a1
    call li
    la cc_fneg_q a0
    call seq
    mv s6 a0
    call setty
    j L9
"));
once(\$t, "\n  cc_add_s0:\n    ascii\n      \\x00cc_addfp\\x00\n",
    "\n  cc_add_s0:\n    ascii\n      \\x00cc_addfp\\x00\n  cc_fneg_q:\n    ascii\n      \\x00cc_fneg_q\\x00\n", 'cc_add_s0');
edit(\$t, 'wcall', asm(10, "mv s7 a0\ncall label_addr\nmv a0 a1\n") => asm(10, "mv s7 a0\ncall label_addr\nmv s7 a1\ncall jitaddr\nmv a0 a1\n"));
save();
