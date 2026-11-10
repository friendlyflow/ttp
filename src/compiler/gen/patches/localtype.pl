# localtype.pl: a local (or a parameter) hides a struct or union type of
# the same name, in an inner block too. litk took a leaf whose name is a
# struct type for a compound literal of it before looking at the locals:
# find_label sees a function's own declarations, not those of a block in
# it, so `node`, a local in a loop body, was fftree.ff's struct node there,
# its value a compound literal made of the items after it (stage2 crashed
# on cpp's get_tok: no item was left; a program took the next statement's
# items and crashed when it ran). Now a leaf that vfind finds is a value,
# before litk's cache (tscan runs before the body declares its locals).
# And a compound literal with no items after its type stops with the
# type's name ("cannot compile: node"); litone stops with a message where
# an aggregate's item is missing, instead of reading a node at 0.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'litk', asm(8, "
K5:
    ld 0 s4 t0
    la litk t1
") => asm(8, "
K5:
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call vfind
    bnez K9 a0
    ld 0 s4 t0
    la litk t1
"));
edit(\$t, 'litone', asm(8, "
    call isagg
    beqz O3 a0
    call peek
    lbu NODE_children_len a0 t0
") => asm(8, "
    call isagg
    beqz O3 a0
    call peek
    beqz O4 a0
    lbu NODE_children_len a0 t0
"));
edit(\$t, 'litone', "        O2:\n" => asm(8, "
O4:
    call bad
") . "        O2:\n");
edit(\$t, 'complits', asm(8, "
    enter5
    mv a0 s4
") => asm(8, "
    enter5
    mv a0 s4
    call more
    bnez C1 a0
    mv s4 a0
    call bad
C1:
"));
save();
