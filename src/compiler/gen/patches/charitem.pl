# charitem.pl: a leaf item of a char array is its text, whatever it names
# (the master's fault 11, 2026-11-21). istext, asked for a char array's item
# (text_item: ginit and gtext), took a leaf that is a local, a definition
# or a register for that name, not text: glibc's static const char str[] =
# "str" (csema: str: / array / char / 4 / str) read as glibc's global str,
# an empty text (riscv64, x86_64). In C a char array's item is never another
# object: now with text_item set, a leaf that is no number is text at once
# (textdef.pl's rule, isdef, stays for a char * pointer's item, where a
# leaf naming a global or a function is its address). Test: progs/ccharitem.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'istext', asm(8, "
    call parse_num
    mv a1 a0
    bnez L1 a0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call vfind
") => asm(8, "
    call parse_num
    mv a1 a0
    bnez L1 a0
    la text_item t0
    ld 0 t0 t0
    bnez L1 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call vfind
"));
save();
