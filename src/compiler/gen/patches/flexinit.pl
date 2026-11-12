# flexinit.pl: a global whose struct ends in an array without a count (C's
# flexible array member) takes each element its items reach whole, as gcc
# lays it out. global's room is the type's size, grown by gput to the end of
# the last scalar ginit stores, so the last element ended at its last item:
# csu/libc-tls.c's static_slotinfo, .slotinfo = { [63] = { 0 } }, had 1032
# bytes for gcc's 1040, and the next global (_dl_tls_dtv_slotinfo_list) lay
# on slotinfo[63].map (found by src/glibc's datacheck). Now ginit, after
# each item, grows the room to the end of that member or element (its
# offset and its type's size), the bytes up to there zero. Inside the
# type's size it changes nothing. Test cflexinit (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'ginit', asm(8, "
L6:
    addi 1 s8 s8
    j L1
") => asm(8, "
L6:
    mv s9 a0
    call tsize
    add s10 a0 a1
    call gbase
    ld 8 a0 t0
    bgeu rel:L7 a1 t0
    li32 8448 t2
    add t2 a0 t2
L8:
    bgeu rel:L10 a1 t0
    add t0 t2 t3
    sb 0 zero t3
    addi 1 t0 t0
    j L8
L10:
    sd 8 a1 a0
L7:
    addi 1 s8 s8
    j L1
"));
save();
