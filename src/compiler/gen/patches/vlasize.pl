# vlasize.pl: sizeof of a variable-length array is its size, worked out
# when it was declared, as C has it (gmon's char buf[len + 20], then
# __snprintf (buf, sizeof (buf), ...)): it was the size of the address
# ttpc keeps for it. A VLA's declaration (decl, W4) now has a local of its
# own just before the array's, with no name, that holds its size in bytes;
# the array's address type has count 1, which no other address type has;
# and sizeof of such a variable loads that local. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/decl',
    "          li\n            2\n            a2\n          call\n            ccalloca\n          li\n            TY_ADDRESS\n            a0\n          mv\n            s7\n            a1\n          li\n            0\n            a2\n          call\n            newtype\n",
    asm(10, "
    mv s4 a0
    li TY_LONG a1
    call declare
    sd VAR_len zero a0
    mv a0 s9
    call syncsp
    mv s9 a0
    call vaddrt0
    li TY_LONG a0
    call store
    li 2 a2
    call ccalloca
    li TY_ADDRESS a0
    mv s7 a1
    li 1 a2
    call newtype
"));

edit(\$t, 'cc/primary',
    "            vfind\n          beqz\n            L49\n            a0\n          ld\n            VAR_type\n            a0\n            a0\n          j\n            L48\n",
    "            vfind\n          beqz\n            L49\n            a0\n" . asm(10, "
    ld VAR_type a0 t0
    ld TY_kind t0 t1
    li TY_ADDRESS t2
    bne rel:L56 t2 t1
    ld TY_count t0 t1
    li 1 t2
    bne rel:L56 t2 t1
    li VAR_sz t1
    sub t1 a0 a0
    call vaddr
    call rvalue
    li TY_U64 a0
    call setty
    j L9
    L56:
    ld VAR_type a0 a0
    j L48
"));
save();
