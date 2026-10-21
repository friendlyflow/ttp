# ldarray.pl: a long double item of an array or a struct in a global's
# initializer (libm's tables of binary128 constants, e_expl's C), as
# ldlit.pl made a long double global itself: isagg takes the 16 bytes of a
# long double for an aggregate, so ginit's item went to the aggregate path
# and stopped there ("cannot compile" its literal). Like ginit's own type
# (ldlit.pl), a long double item is no aggregate here, nor a double where it
# is kept in memory (arm): it goes through gstore, which writes the high
# word after the low one.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'ginit',
    "          mv\n            s9\n            a0\n          call\n            isagg\n          beqz\n            L4\n            a0\n",
    "          mv\n            s9\n            a0\n          call\n            isagg\n" . asm(10, "
    li TY_LDOUBLE t0
    xor s9 t0 t1
    sltu t1 zero t1
    and t1 a0 a0
    li TY_DOUBLE t0
    xor s9 t0 t1
    sltu t1 zero t1
    and t1 a0 a0
") . "          beqz\n            L4\n            a0\n");
save();
