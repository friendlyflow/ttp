# groupdot.pl: a : with a . among its children is a value with a path, not
# a block, where it stands as a statement too: a : of one item that holds
# it (two / 40 / : / : / p / - / 1 / . / tid, c2ff's THREAD_SELF->tid in an
# argument, a : around one item) runs that item as a statement, and stmt
# took the inner : for a block of statements (p - 1, then . and tid: "unknown
# name: tid"). stmt now gives a : that dotted finds a . in to the
# expression (L8), as it does a cast:. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc/stmt',
    "          li\n            KW_cast\n            t0\n          beq\n            rel\n              L8\n            t0\n            a0\n",
    "          li\n            KW_cast\n            t0\n          beq\n            rel\n              L8\n            t0\n            a0\n" . asm(10, "
    mv s4 a0
    call dotted
    bgez L8 a0
"));
save();
