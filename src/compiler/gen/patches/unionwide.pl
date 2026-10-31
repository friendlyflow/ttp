# unionwide.pl: a local union set from one item that is not a union, its
# first member's (union { long double d; u64 u[2]; } v = { x }): decl stored
# it with the member's type, which for a wide one (fwide: a long double,
# its value the address of its bytes) wrote the one word store writes; now
# a wide member is copied whole (copytype), as linit does for one in a
# struct. Test: cunionld. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/decl', asm(10, "
L15:
    mv s7 a0
    li 0 a1
    call member
    mv a1 s10
    ld VAR_off s9 t0
    sub t0 a0 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s10 a0
    call store
    j L9
"), asm(10, "
L15:
    mv s7 a0
    li 0 a1
    call member
    mv a1 s10
    ld VAR_off s9 t0
    sub t0 a0 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s10 a0
    call fwide
    bnez L15W a0
    mv s10 a0
    call store
    j L9
L15W:
    mv s10 a0
    call copytype
    j L9
"));
save();
