# declcolon.pl: a local struct set from a value that begins with a : group
# (C's struct t a = *(struct t *) p: : / cast t * pointer / p, then * pointer),
# a copy: decl took any item that began with : for the struct's items, wrote
# the pointer to the first field and left the rest, on every target
# (tst-fwrite-pos's thread got its arguments so, and crashed). A : alone is
# still the items. Test: cdeclcolon.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/decl', asm(10, "
    call peek
    call iscolon
    bnez L14 a0
    li 1 a0
") => asm(10, "
    call peek
    call colonalone
    bnez L14 a0
    li 1 a0
"));
my ($cf, $ct) = find(\$t, 'cc/decl');
substr($t, $ct, 0) = fn('colonalone', "
    enter1
    call iscolon
    beqz L9 a0
    la ccs t0
    ld CC_cur t0 t1
    addi 8 t1 t1
    ld CC_end t0 t0
    bge rel:L9 t0 t1
    li 0 a0
    L9:
    leave1
", 6);
save();
