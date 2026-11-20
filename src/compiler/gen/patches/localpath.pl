# localpath.pl: a local hides a struct type of the same name on the left of
# an assignment too, in an inner block (the user's rule: a local hides a
# same-named struct type). addr (the address of an item: the left of =,
# +=, ++, & address) took a node with children whose name cfind finds as a
# struct for a compound literal of it (AC, the address of one) before
# looking at the locals, and cfind sees a function's own declarations only,
# not those of a block in it: coreutils df.c's local hash_entry (a struct
# devlist *, in an if's body) and glibc's type hash_entry gave, for
# hash_entry / seen_last = devlist, "unknown name: seen_last" (the literal's
# item). Now a name vfind finds is a variable there, before AC. (A local
# of the function's own body hid the type already: cfind found its
# declaration, no struct.)
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'addr', asm(8, "
AC:
    enter1
    mv a0 s4
    lbu NODE_children_len s4 t0
    beqz AC9 t0
") => asm(8, "
AC:
    enter1
    mv a0 s4
    lbu NODE_children_len s4 t0
    beqz AC9 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call vfind
    bnez AC9 a0
"));
save();
