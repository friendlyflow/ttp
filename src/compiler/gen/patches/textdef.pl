# textdef.pl: a text is never read as a type. istext (may a leaf be the
# text of a pointer to char: a global's or a field's item, the leaf alone)
# said no for a leaf naming any definition, a struct type too: a global
# g: / char / * pointer / BLOCK, where BLOCK is a struct of the program
# (coreutils' ptx.c, while env.c has the string "BLOCK"), was the type's
# "address", 0, with no message, and an array char n took no such text
# ("cannot compile"). Now a leaf that find_label or libfind finds as a type
# (isdef: a struct, a union, an enum, a function type) is text; one naming
# a function or a global stays its address.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'istext', asm(8, "
    call find_label
    bnez L1 a0
") => asm(8, "
    call find_label
    bnez LD a0
"), asm(8, "
    call libfind
L1:
") => asm(8, "
    call libfind
    beqz L1 a0
LD:
    call isdef
    seqz a0 a0
L1:
"));
save();
