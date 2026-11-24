# complexlit.pl: a complex type as a value, its two parts after it, is a
# compound literal of it, as a struct's (the user's choice, 2026-11-18,
# option A): complex double / 3 / 4 is C's 3 + 4i, in code (an argument, a
# result, a local's value) and as a global's item in a : (selfcl.pl's), and
# csema writes C's imaginary constants and __builtin_complex (a, b) so. The
# complex types are records of ttpc's own (complexty.pl: cx_nodes, a struct
# of real part and imag part; complexq.pl's cxn_q for complex float128), so
# the leaf's type word finds that definition where a struct's name finds its
# own: litk (whether a leaf heads a literal, and its places) and complits
# (the temporary), littype (its type) and stmt (a statement's start, else
# the shared page's word of it) look a complex type word up first (cxnode). Test:
# ccomplexlit (4 targets). After complexty.pl, complexq.pl, words.pl and
# selfcl.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

{
    my ($from) = find(\$t, 'litk');
    substr($t, $from, 0) = fn('cxnode', "
    # a0 a leaf: the definition of the complex type it names (cx_nodes,
    # cxn_q), else 0
    enter1
    la cc_tynames a1
    call lookup
    li 18 t0
    beq rel:L1 t0 a0
    li 19 t0
    beq rel:L1 t0 a0
    li 20 t0
    beq rel:L1 t0 a0
    li 51 t0
    beq rel:L2 t0 a0
    li 0 a0
    leave1
L1:
    addi -18 a0 a0
    slli 3 a0 a0
    la cx_nodes t0
    add t0 a0 a0
    ld 0 a0 a0
    leave1
L2:
    la cxn_q a0
    leave1
", 6) . fn('cxlabel', "
    # find_label's (a0 a1 a name's text), a complex type word's definition
    # first (a2 its leaf)
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s6 a0
    call cxnode
    bnez L1 a0
    mv s4 a0
    mv s5 a1
    call find_label
L1:
    leave3
", 6) . fn('cxcfind', "
    # cfind's (a0 a1 a name's text, a2 its leaf), a complex type word's
    # definition first
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s6 a0
    call cxnode
    bnez L1 a0
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call cfind
L1:
    leave3
", 6);
}

edit(\$t, 'litk', asm(10, "
    call find_label
    bnez K6 a0
") => asm(10, "
    mv s4 a2
    call cxlabel
    bnez K6 a0
"));
edit(\$t, 'complits', asm(8, "
    mv s4 a2
    call cfind
    call struct
") => asm(8, "
    mv s4 a2
    call cxcfind
    call struct
"));
# (littype, a literal's type, its head a leaf: the same)
edit(\$t, 'littype', asm(10, "
    mv s4 a2
    call cfind
    call struct
") => asm(10, "
    mv s4 a2
    call cxcfind
    call struct
"));
# (stmt: a leaf a statement starts with is C code where cfind finds a C
# definition, a struct's name; a complex type word too, which the shared
# page declares as a word, called otherwise: a : holding its literal, a
# value group (C's ({ ... })), took it as that word's call)
edit(\$t, 'stmt', asm(10, "
    mv s4 a2
    call cfind
    bnez L8 a0
") => asm(10, "
    mv s4 a2
    call cxcfind
    bnez L8 a0
"));
save();
