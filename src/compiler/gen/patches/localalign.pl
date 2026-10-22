# localalign.pl: a local's align n (C's aligned attribute or _Alignas on a
# local: qsort's _Alignas (uint64_t) char tmp[1024]) places it at a
# multiple of n: declare rounds the frame's depth after it up to n (the
# frame's base is aligned to the target's stack alignment, 16, arm 8, so n
# up to that holds). typerun already passes over the align (align.pl).
# Test: calignattr.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/declare', "        L1:\n          la\n            ccs\n            t0\n          ld\n            CC_depth\n            t0\n            t1\n          add\n            a0\n            t1\n            t1\n", asm(8, "
L1:
    mv a0 s6
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call alval
    la ccs t0
    ld CC_depth t0 t1
    add s6 t1 t1
    beqz LA a0
    addi -1 a0 t2
    add t2 t1 t1
    neg a0 t2
    and t2 t1 t1
LA:
"));
save();
