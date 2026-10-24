# ctwide.pl: compile time's code of a global's value (ctconst: frame with
# exprbody) reserves the temporaries of its value as a function's body does
# (treserve over the value, the node its abi key, wcount on: lookcache
# 160, which frame clears and a function has from wgate), and so does a pair's
# (pairconst: pairbody over the item's nodes, riscv64's long double in a
# global's items, tst-strtod5's - 0x0p+0L): a value of a type in
# memory needs one (wtemp), double on arm, where compile time runs on an
# arm host; there exprbody had none, and a global double of a value such as
# - 0x1p+1024 stopped ttpc ("a value of a type in memory ... in a function
# that does not name the type"; chexinf's gdm on the arm host). Test:
# chexinf on the arm host (bootstrap's chello-arm).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'exprbody',
    asm(8, "enter1\nla ccs t0\nsd CC_self a0 t0\n") => asm(8, "
    enter1
    mv a0 s4
    li 1 t1
    la lookcache t0
    sd 160 t1 t0
    addi -16 sp sp
    sd 0 a0 sp
    mv sp a0
    li 1 a1
    mv s4 a2
    call treserve
    addi 16 sp sp
    mv s4 a0
    la ccs t0
    sd CC_self a0 t0
"));
edit(\$t, 'pairbody',
    asm(8, "enter3\nla pair_slot t0\nld 0 t0 s4\n") => asm(8, "
    enter3
    li 1 t1
    la lookcache t0
    sd 160 t1 t0
    la pair_slot t0
    ld 0 t0 a0
    la pair_end t1
    ld 0 t1 a1
    sub a0 a1 a1
    srli 3 a1 a1
    ld 0 a0 a2
    call treserve
    la pair_slot t0
    ld 0 t0 s4
"));
save();
