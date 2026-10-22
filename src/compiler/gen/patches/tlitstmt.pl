# tlitstmt.pl: a compound literal among a function's own statements has
# its temporary reserved, as one inside a statement has: treserve, which
# reserves the frame's temporaries before the body, called tscan on each
# statement node alone, and a literal at that level is a struct name and
# its items as siblings (y = point 0 0, *blob = (struct x) { 0 }), which only
# the sibling loop of tscan (litk, tlit) sees. The temporary was written
# below sp, where the next push overwrote it: libsupport's
# support_blob_repeat_free crashed (tst-memmove-overflow). Test: ctlitstmt.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'treserve', "        L1:\n          beqz\n            L2\n            s5\n          ld\n            0\n            s4\n            a0\n          call\n            tscan\n          add\n            a0\n            s6\n            s6\n          addi\n            8\n            s4\n            s4\n          addi\n            -1\n            s5\n            s5\n          j\n            L1\n", asm(8, "
    slli 3 s5 t0
    add t0 s4 s5
L1:
    bgeu rel:L2 s5 s4
    ld 0 s4 a0
    call litk
    li -1 t0
    beq rel:LT t0 a0
    mv s4 a0
    mv s5 a1
    li 1 a2
    call tlit
    add a0 s6 s6
    mv a1 s4
    j L1
LT:
    ld 0 s4 a0
    call tscan
    add a0 s6 s6
    addi 8 s4 s4
    j L1
"));
save();
