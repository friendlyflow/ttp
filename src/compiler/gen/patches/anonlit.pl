# anonlit.pl: an anonymous union in a compound literal takes one item, its
# first field's, in place (as a struct's anonymous member takes its fields'
# items): litinit stopped on it (NB, "cannot compile"), so c2ff made a
# constant one a global of its own (arm's mutex initializer) and a literal
# of variables failed. Now NA fills the union's first field (member 0, at
# the union's offset) by litone. Test: canonlit.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/litinit', "          li\n            KW_union\n            t0\n          beq\n            rel\n              NB\n            t0\n            a0\n          mv\n",
    "          li\n            KW_union\n            t0\n          beq\n            rel\n              NA\n            t0\n            a0\n          mv\n",
    "        N9:\n          leave8\n        NB:\n", "        N9:\n          leave8\n" . asm(8, "
NA:
    mv s10 a0
    li 0 a1
    call member
    mv a1 a0
    sub s9 s5 a1
    call litone
    j N5
") . "        NB:\n");
save();
