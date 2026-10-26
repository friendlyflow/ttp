# tscantype.pl: treserve's scan (tscan) takes a struct type's name followed
# by items for a compound literal, and keeps room of its size for it; the
# type of a cast, a sizeof or an alignof is no literal (THREAD_SELF's cast
# to struct pthread *, its sizeof and alignof: 2.7 KB each, 5.5 KB of
# __vfprintf_internal's lock, 17 KB in all with its others), and neither
# runs code: tscan passes over their children now (a type of a library
# tree, which litk finds by libtype: glibc's). After tscanglob.pl.
# Test: tst-swapcontext1 (a library tree's type; cglobroom has the global case).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/tscan', "        L2:\n          mv\n            s4\n            a0\n          call\n            flatkids\n", asm(8, "
L2:
    mv s4 a0
    call kwof
    li KW_cast t0
    beq rel:L9 t0 a0
    li KW_sizeof t0
    beq rel:L9 t0 a0
    li KW_alignof t0
    beq rel:L9 t0 a0
    mv s4 a0
    call flatkids
"));
save();
