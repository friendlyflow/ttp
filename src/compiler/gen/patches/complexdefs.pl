# complexdefs.pl (on ttpc.defs.ff): the words real and imag of C's complex
# types (the user's choice, 2026-10-19), after va_arg_pack_len in cc_kw.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
once(\$t, "  KW_vapacklen:\n    addi\n      49\n      zero\n      a0\n",
    "  KW_vapacklen:\n    addi\n      49\n      zero\n      a0\n  KW_real:\n    addi\n      50\n      zero\n      a0\n  KW_imag:\n    addi\n      51\n      zero\n      a0\n", 'KW_vapacklen');
save();
