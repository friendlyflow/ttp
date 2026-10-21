# wordsdefs.pl: the constant of the C words of gen/patches/words.pl, the
# first suffix of a typed literal (U, then L UL LL ULL) among ttpc's words
# (cc_kw), after section. Run on ttpc.defs.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
once(\$t, "  KW_section:\n    addi\n      53\n      zero\n      a0\n",
    "  KW_section:\n    addi\n      53\n      zero\n      a0\n  KW_U:\n    addi\n      54\n      zero\n      a0\n", 'KW_section');
save();
