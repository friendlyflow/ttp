# patch_hostlambda.pl: in host code a compile time lambda puts nothing. The
# jit compiles the page for the host only so that compile time can call its
# functions; what a lambda emits is the target's (its asm, its C), so stmt
# skips the lambda there (CC_jit != 0) and never runs it for the host.
our $t; do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'stmt',
    "    L18:\n      mv\n        s4\n        a0\n      la\n        function\n        a1\n      call\n        ctrun\n",
    "    L18:\n" . asm(6, "
        la ccs t0
        ld CC_jit t0 t0
        bnez L9 t0") . "      mv\n        s4\n        a0\n      la\n        function\n        a1\n      call\n        ctrun\n");
save();
