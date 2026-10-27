# tscanglob.pl: treserve's scan (tscan) keeps room for the result of a call
# of a function whose type is in memory (a struct), as it reserves a
# function's temporaries before its body; a name of a global of such a type
# is no call: its room was reserved too, each time it was named, and never
# used (glibc's ucontext_t globals, 960 bytes for each mention: do_test of
# tst-swapcontext1 had 15 KB of them, __vfprintf_internal 17 KB, past the
# 16 KB stacks its makecontext gives). A global (kind 2) of a type larger
# than 32 bytes gets none now; a smaller one keeps it, which a long double
# or complex value's operations take their temporaries from in a function
# that does not name the type (wgate counts none there: ccomplex).
# Test: cglobroom.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/tscan', "        L11:\n          mv\n            s6\n            a0\n", asm(8, "
L11:
    mv s6 a0
    call kind
    li 2 t0
    bne rel:LG t0 a0
    mv s6 a0
    lbu NODE_children_len a0 t0
    beqz L2 t0
    ld NODE_children a0 t1
    slli 3 t0 t0
    add t0 t1 a1
    mv t1 a0
    call typerun
    bltz L2 a0
    call tsize
    li 32 t0
    blt rel:L2 a0 t0
LG:
    mv s6 a0
"));
save();
