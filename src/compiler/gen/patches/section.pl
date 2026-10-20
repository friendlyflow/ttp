# section.pl: named sections (the user's choice, 2026-10-20): a global
# whose first words are section and a name,
#
#   one_impl:
#     section
#     impls
#     impl_t
#     ...
#
# is placed with every other global of that section, together, and
# __start_impls and __stop_impls are where they start and end, as ld
# defines them for a section whose name is a C name (test-string.h's IMPL
# entries, walked from __start_impls to __stop_impls). A global of a
# section is put off where it is reached (secdefer); a section is made the
# first time one of its globals or bounds is (secentry: its name, its first
# global, two nodes of its own for the bounds, each a global of no bytes,
# an array of the first global's type with 0 elements); at the end of the
# library (secplace, before the TLS image) each section is placed once: its
# __start_, each global of the program's page and then of the library's pages
# (syms) that is of it, in their order, its __stop_. The bounds are names nothing defines: cfind takes
# them for the section's (secfind) where it finds no other definition. The
# texts of a section's globals come after its __stop_ (ld puts them in
# .rodata), so that its globals are as far apart as their size. The
# sections are made anew each pass (compile_page), in the same order, so
# that their nodes, and so their labels, are the same. With sectiondefs in
# ttpc.defs.ff (KW_section 53): run on ttpc.ff after ifnaddr.pl and
# generic.pl, then with T=ttpc.defs.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_generic:\n    addi\n      52\n      zero\n      a0\n",
        "  KW_generic:\n    addi\n      52\n      zero\n      a0\n  KW_section:\n    addi\n      53\n      zero\n      a0\n", 'KW_generic');
    save();
    exit;
}

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# the word, after generic; the words of the bounds and their nodes
once(\$t, "imag\\x00generic\\x00\\x00\n", "imag\\x00generic\\x00section\\x00\\x00\n", 'cc_kw');
once(\$t, "\n  gen_words:\n", "\n  sec_words:\n    ascii\n      array0__start___stop_\n  gen_words:\n", 'gen_words');
once(\$t, "  irw_vars:\n    reserve\n      65544\n",
    "  irw_vars:\n    reserve\n      65544\n  sec_vars:\n    reserve\n      4104\n  sec_placing:\n    reserve\n      8\n  sec_nodes:\n    reserve\n      128\n  sec_prog:\n    reserve\n      8\n  sec_tbase:\n    reserve\n      8\n  sec_texts:\n    reserve\n      32776\n", 'irw_vars');

# tlskip: section and its name come before the type too
edit(\$t, 'cc/tlskip',
    "        call\n          kwof\n        li\n          KW_tls\n          t0\n",
    asm(8, "
    call kwof
    li KW_section t0
    beq rel:LS t0 a0
    li KW_tls t0
"),
    "          leave2\n",
    "          leave2\n" . asm(8, "
    LS:
    addi 8 s4 s4
    j L1
"));

# cfind: a name nothing defines may be a section's bound
edit(\$t, 'cc/cfind',
    "        L10:\n          leave1\n",
    asm(8, "
    L10:
    bnez SF9 a0
    mv s4 a0
    call secfind
    SF9:
    leave1
"));

# cc: a global of a section is put off
edit(\$t, 'cc',
    "    L2:\n      mv\n        s4\n        a0\n      call\n        tlsdefer\n",
    asm(4, "
    L2:
    mv s4 a0
    call secdefer
    bnez L8 a0
    mv s4 a0
    call tlsdefer
"));

# cc_library: the sections, at the end, before the TLS image
edit(\$t, 'cc/cc_library',
    "        L9:\n          call\n            tlsplace\n",
    asm(8, "
    L9:
    call secplace
    bnez L5 a0
    call tlsplace
"));

# compile_page: each pass, no sections yet
# compile_page: the program's page (its last tree), whose definitions are
# in no syms
my $last = "    ld\n      -8\n      t1\n      s7\n";
edit(\$t, 'compile_page', $last, $last . "    la\n      sec_prog\n      t0\n    sd\n      0\n      s7\n      t0\n");
my $irw = "      la\n        irw_vars\n        t0\n      sd\n        0\n        zero\n        t0\n";
edit(\$t, 'compile_page', $irw, $irw . "      la\n        sec_vars\n        t0\n      sd\n        0\n        zero\n        t0\n");

# gval: a text of a section's global goes after the section, where
# secplace puts it (sec_tbase: there, after the texts before it), so that
# its globals are as many bytes apart as their type has, as ld's are
my $tb = "          ld\n            0\n            s6\n            a0\n          ld\n            8\n            s6\n            t0\n          add\n            t0\n            a0\n            a0\n";
edit(\$t, 'cc/gval', $tb, asm(10, "
    la sec_placing t0
    ld 0 t0 t0
    beqz GT1 t0
    la sec_tbase t0
    ld 0 t0 a0
    j GT2
    GT1:
    ld 0 s6 a0
    ld 8 s6 t0
    add t0 a0 a0
    GT2:
"));
# global: and is not placed after the global, but in the section's pool
edit(\$t, 'cc/global', "          li\n            0\n            s10\n        L6:\n",
    "          li\n            0\n            s10\n" . asm(10, "
    la sec_placing t0
    ld 0 t0 t0
    beqz GS9 t0
    call secpool
    j L7
    GS9:
") . "        L6:\n");

my $fns = cfn('secnth', "the definition a0 of those a section's globals may be: the program's page's, in its groups too (what is no C definition there, kind 0), then the library's (syms); 0 past them", "
    enter5
    mv a0 s4
    la sec_prog t0
    ld 0 t0 s5
    beqz N5 s5
    lbu NODE_children_len s5 s6
    ld NODE_children s5 s7
    N1:
    beqz N5 s6
    ld 0 s7 s8
    mv s8 a0
    call kind
    bnez N2 a0
    lbu NODE_children_len s8 t0
    beqz N2 t0
    bgeu rel:N3 t0 s4
    ld NODE_children s8 t1
    slli 3 s4 t2
    add t2 t1 t2
    ld 0 t2 a0
    leave5
    N3:
    sub t0 s4 s4
    j N4
    N2:
    beqz N6 s4
    addi -1 s4 s4
    N4:
    addi 8 s7 s7
    addi -1 s6 s6
    j N1
    N6:
    mv s8 a0
    leave5
    N5:
    la syms t2
    la syms_end t0
    ld 0 t0 t0
    slli 3 s4 t3
    add t3 t2 t3
    bgeu rel:N8 t0 t3
    ld 0 t3 a0
    leave5
    N8:
    li 0 a0
    leave5
", 6)
. cfn('secis', "1 if the definition a0 is a global of the section a1 a2 (its name, its length), else 0", "
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len s4 t0
    li 3 t1
    bltu rel:S8 t1 t0
    mv s4 a0
    call defkw
    li KW_section t0
    bne rel:S8 t0 a0
    ld NODE_children s4 t0
    ld 8 t0 t1
    ld NODE_content t1 a0
    lbu NODE_content_len t1 a1
    mv s5 a2
    mv s6 a3
    call streq
    beqz S8 a0
    li 1 a0
    leave3
    S8:
    li 0 a0
    leave3
", 6)
. cfn('secentry', "the section a0 a1 (its name, its length): found, or made where a definition of the program's pages is of it, else 0", "
    enter8
    mv a0 s4
    mv a1 s5
    la sec_vars s6
    ld 0 s6 s7
    li 0 s8
    E1:
    bgeu rel:E2 s7 s8
    slli 8 s8 t0
    add t0 s6 t0
    addi 8 t0 s9
    ld 0 s9 a0
    ld 8 s9 a1
    mv s4 a2
    mv s5 a3
    call streq
    bnez E9 a0
    addi 1 s8 s8
    j E1
    E2:
    li 0 s9
    E3:
    mv s9 a0
    call secnth
    beqz E8 a0
    mv s4 a1
    mv s5 a2
    call secis
    bnez E4 a0
    addi 1 s9 s9
    j E3
    E4:
    mv s9 a0
    call secnth
    mv a0 s10
    li 16 t0
    bgeu rel:E7 t0 s7
    slli 8 s7 t0
    add t0 s6 t0
    addi 8 t0 s9
    addi 1 s7 s7
    sd 0 s7 s6
    sd 0 s4 s9
    sd 8 s5 s9
    sd 16 s10 s9
    sd 24 zero s9
    la sec_nodes t0
    sb NODE_children_len zero t0
    li 5 t1
    sb NODE_content_len t1 t0
    la sec_words t1
    sd NODE_content t1 t0
    addi 64 t0 t2
    sb NODE_children_len zero t2
    li 1 t1
    sb NODE_content_len t1 t2
    la sec_words t1
    addi 5 t1 t1
    sd NODE_content t1 t2
    addi 160 s9 s11
    sd 0 t0 s11
    ld NODE_children s10 a0
    lbu NODE_children_len s10 t1
    slli 3 t1 t1
    add t1 a0 a1
    addi 16 a0 a0
    mv a0 s8
    call typerun
    bltz E7 a0
    addi 8 s11 t3
    li 1 t4
    E5:
    bgeu rel:E6 a1 s8
    li 9 t5
    bgeu rel:E7 t5 t4
    ld 0 s8 t0
    sd 0 t0 t3
    addi 8 s8 s8
    addi 8 t3 t3
    addi 1 t4 t4
    j E5
    E6:
    la sec_nodes t0
    addi 64 t0 t0
    sd 0 t0 t3
    addi 1 t4 t4
    addi 32 s9 t0
    sb NODE_children_len t4 t0
    sd NODE_children s11 t0
    sb NODE_content_len s5 t0
    sd NODE_content s4 t0
    addi 96 s9 t0
    sb NODE_children_len t4 t0
    sd NODE_children s11 t0
    sb NODE_content_len s5 t0
    sd NODE_content s4 t0
    mv s9 a0
    leave8
    E7:
    mv s10 a0
    call bad
    E8:
    li 0 a0
    leave8
    E9:
    mv s9 a0
    leave8
", 6)
. cfn('secfind', "the node of the section bound a0 (__start_ or __stop_ and a section's name), or 0", "
    enter5
    mv a0 s4
    ld NODE_content s4 s5
    lbu NODE_content_len s4 s6
    li 9 t0
    bltu rel:F1 t0 s6
    mv s5 a0
    li 8 a1
    la sec_words a2
    addi 6 a2 a2
    li 8 a3
    call streq
    beqz F1 a0
    addi 8 s5 a0
    addi -8 s6 a1
    li 0 s7
    j F3
    F1:
    li 8 t0
    bltu rel:F8 t0 s6
    mv s5 a0
    li 7 a1
    la sec_words a2
    addi 14 a2 a2
    li 7 a3
    call streq
    beqz F8 a0
    addi 7 s5 a0
    addi -7 s6 a1
    li 1 s7
    F3:
    call secentry
    beqz F9 a0
    addi 32 a0 a0
    beqz F9 s7
    addi 64 a0 a0
    j F9
    F8:
    li 0 a0
    F9:
    leave5
", 6)
. cfn('secdefer', "1 if the global a0 is of a section, put off for secplace (while it places none); else 0", "
    enter1
    mv a0 s4
    la sec_placing t0
    ld 0 t0 t0
    bnez D8 t0
    mv s4 a0
    call defkw
    li KW_section t0
    bne rel:D8 t0 a0
    lbu NODE_children_len s4 t0
    li 3 t1
    bltu rel:D8 t1 t0
    ld NODE_children s4 t0
    ld 8 t0 t1
    ld NODE_content t1 a0
    lbu NODE_content_len t1 a1
    call secentry
    beqz D7 a0
    li 1 a0
    leave1
    D7:
    mv s4 a0
    call bad
    D8:
    li 0 a0
    leave1
", 6)
. cfn('secpool', "the texts of the global being placed (gbase's), for after its section (sec_texts), and sec_tbase after them", "
    enter3
    call gbase
    mv a0 s4
    la sec_texts s5
    li 0 s6
    Q1:
    ld 24 s4 t0
    bgeu rel:Q8 t0 s6
    ld 0 s5 t1
    li32 4096 t2
    bgeu rel:Q7 t2 t1
    slli 3 s6 t2
    add t2 s4 t2
    ld 32 t2 t2
    slli 3 t1 t3
    add t3 s5 t3
    sd 8 t2 t3
    addi 1 t1 t1
    sd 0 t1 s5
    addi 1 s6 s6
    j Q1
    Q8:
    ld 16 s4 t0
    la sec_tbase t1
    ld 0 t1 t2
    add t0 t2 t2
    sd 0 t2 t1
    leave3
    Q7:
    li 0 a0
    call bad
", 6)
. cfn('secplace', "each section not placed yet: its __start_, its globals in the order of the program's pages, its __stop_; 1 if it placed one, else 0", "
    enter8
    li 0 s7
    la sec_vars s4
    li 0 s5
    P1:
    ld 0 s4 t0
    bgeu rel:P9 t0 s5
    slli 8 s5 t0
    add t0 s4 t0
    addi 8 t0 s6
    addi 1 s5 s5
    ld 24 s6 t0
    bnez P1 t0
    li 1 t0
    sd 24 t0 s6
    li 1 s7
    la sec_placing t0
    li 1 t1
    sd 0 t1 t0
    addi 32 s6 a0
    call cc
    la sec_texts t0
    sd 0 zero t0
    addi 96 s6 a0
    call label_addr
    la sec_tbase t0
    sd 0 a0 t0
    li 0 s8
    P2:
    mv s8 a0
    call secnth
    beqz P3 a0
    ld 0 s6 a1
    ld 8 s6 a2
    call secis
    beqz P4 a0
    mv s8 a0
    call secnth
    call cc
    P4:
    addi 1 s8 s8
    j P2
    P3:
    addi 96 s6 a0
    call cc
    li 0 s9
    Z1:
    la sec_texts t0
    ld 0 t0 t1
    bgeu rel:Z2 t1 s9
    slli 3 s9 t2
    add t2 t0 t2
    ld 8 t2 t2
    ld NODE_content t2 a0
    lbu NODE_content_len t2 a1
    call emit_raw
    la zero_byte a0
    li 1 a1
    call emit_raw
    addi 1 s9 s9
    j Z1
    Z2:
    la cur_pc t0
    ld 0 t0 t0
    neg t0 a0
    andi 7 a0 a0
    call pad
    la sec_placing t0
    sd 0 zero t0
    j P1
    P9:
    mv s7 a0
    leave8
", 6);
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $fns;
save();
