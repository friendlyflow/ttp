# aggitem.pl: a local's field (or element) of a struct or union type
# takes an expression of that type for its item, a copy of it, as C's
# { f (x) } does; only a : (its items, as C's inner braces) did, and any
# other item stopped ttpc ("cannot compile": glibc's statx_generic,
# struct statx obuf = { ..., statx_convert_timestamp (st->st_atim), ... },
# a call returning a struct; found by datacheck). ff has no brace elision,
# so an item that is no : was never an aggregate's items: now linit
# compiles it as an expression and copies it where its type is the
# field's; another type stops as before. Test caggitem (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/linit', asm(10, "
    call peek
    call iscolon
    beqz L3 a0
") => asm(10, "
    call peek
    call iscolon
    beqz LX a0
"));
edit(\$t, 'cc/linit', asm(10, "
    mv s7 a0
    call copytype
    j L5
") => asm(10, "
    mv s7 a0
    call copytype
    j L5
") . asm(8, "
LX:
    li 1 a0
    call expr
    mv s7 a0
    call wassign
    call getty
    bne rel:L3 s7 a0
    sub s5 s8 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s7 a0
    call copytype
    j L5
"));
save();
