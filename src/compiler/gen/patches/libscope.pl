# libscope.pl: a function or global of a definition page sees the names of
# its own group before those of the other pages. Library C was compiled
# with the program page's scopes alone, so a name its body did not declare
# was looked up among all the definition pages (find_fn), and the first
# page's won: cpp's tok on tools/cpp.ff lost to tools/c.ff's tok of the same
# name (`unknown name: type'`, a field only cpp's has), and its string
# literals (text 1 ...) to c.ff's. Now each cc goes through ccg, which sets
# lib_grp to the definition's group (libgrp: the top-level node of a
# definition page that holds it, through the layers; the last one before it
# in memory, as trees are read in preorder, checked by libmem; 0 on the
# program page) while it compiles, also when dataplace or a section places a
# global later; the C layer's lookups among the definition pages (each call
# of find_fn in cc is one of libfind; enumconst's of enumlib) look in that
# group first (libl, as find_label's lfind, which is local to it; enumin),
# then among all as before. The order for a name in library C: its
# function's scopes and the program page (find_label), its own group, the
# other pages.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }

# every call of cc (compile_page, run_placed, cc_library, dataplace,
# secplace, tlsplace) goes through ccg, which sets lib_grp for it
{
    my $n = $t =~ s/(\n *call\n *)cc\n/$1ccg\n/g;
    die "libscope: $n calls of cc, not 9\n" unless $n == 9;
}
# every lookup of the C layer among the definition pages: libsym, libtype,
# istext (text N, a string literal's global: cpp's and c.ff's both have
# them), leafval, stmt, select, the thread locals', compile time's
{
    my $from = index($t, "\n  cc:\n"); my $to = index($t, "\n  cc_quiet:\n");
    die "libscope: no cc group\n" unless $from >= 0 && $to > $from && index($t, "\n  cc:\n", $from + 1) < 0;
    my $cc = substr($t, $from, $to - $from);
    my $n = $cc =~ s/(\n *call\n *)find_fn\n/$1libfind\n/g;
    die "libscope: $n calls of find_fn in cc, not 14\n" unless $n == 14;
    substr($t, $from, $to - $from) = $cc;
}
# and an enum constant (enumconst): the scopes, then lib_grp's enums, then
# the definition pages' (enumlib)
edit(\$t, 'enumconst', asm(8, "
L8:
    mv s4 a0
    mv s5 a1
    call enumlib
") => asm(8, "
L8:
    la lib_grp t0
    ld 0 t0 a0
    beqz L7 a0
    li 0 a1
    call enumin
    bnez L9 a0
L7:
    mv s4 a0
    mv s5 a1
    call enumlib
"));

after_fn('cc_library', cfn('libfind', "find_fn's a0 a1 (a name), looked up first among the definitions of lib_grp (through its layers) when it is not 0", "
    enter2
    mv a0 s4
    mv a1 s5
    la lib_grp t0
    ld 0 t0 a0
    beqz F1 a0
    li 0 a1
    call libl
    bnez F9 a0
F1:
    mv s4 a0
    mv s5 a1
    call find_fn
F9:
    leave2
", 6) . cfn('libl', "the child of a0 named as libfind's s4 s5 (a definition), looking through the layers in it, a1 layers deep (find_label's lfind); 0 if there is none", "
    enter5
    mv a0 s6
    mv a1 s7
    lbu NODE_children_len a0 s8
    ld NODE_children a0 s6
L1:
    li 0 a0
    beqz L9 s8
    ld 0 s6 a0
    call is_fn
    beqz L3 a0
    ld 0 s6 a0
    call is_layer
    beqz L2 a0
    li MAX_DEPTH t4
    bgeu rel:L3 t4 s7
    ld 0 s6 a0
    addi 1 s7 a1
    call libl
    bnez L9 a0
    j L3
L2:
    ld 0 s6 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    addi -1 a3 a3
    mv s4 a0
    mv s5 a1
    call streq
    beqz L3 a0
    ld 0 s6 a0
    j L9
L3:
    addi 8 s6 s6
    addi -1 s8 s8
    j L1
L9:
    leave5
", 6));
after_fn('cc_quiet', cfn('ccg', "cc of the definition a0 with lib_grp its group (libgrp; 0 on the program page) meanwhile: library C sees its own group's names before the other pages'", "
    enter3
    mv a0 s4
    la lib_grp t0
    ld 0 t0 s6
    call libgrp
    la lib_grp t0
    sd 0 a0 t0
    mv s4 a0
    call cc
    la lib_grp t0
    sd 0 s6 t0
    leave3
", 2) . cfn('libgrp', "the top-level node of a definition page (of combined's children) that holds a0 among its children, through its layers, or 0 (the program page's, or none): the last one before a0 in memory (a tree is read in preorder), checked by libmem", "
    enter5
    mv a0 s4
    li 0 s5
    la combined t0
    lbu NODE_children_len t0 s6
    ld NODE_children t0 s7
    addi -1 s6 t0
    slli 3 t0 t0
    add t0 s7 t0
    ld 0 t0 s8
G1:
    beqz G3 s6
    ld 0 s7 t0
    bltu rel:G2 t0 s4
    bgeu rel:G2 t0 s5
    mv t0 s5
G2:
    addi 8 s7 s7
    addi -1 s6 s6
    j G1
G3:
    li 0 a0
    beqz G9 s5
    beq rel:G9 s5 s8
    mv s5 a0
    mv s4 a1
    li 0 a2
    call libmem
    beqz G9 a0
    mv s5 a0
G9:
    leave5
", 2) . cfn('libmem', "1 if a1 is a child of a0, through its layers (a2 deep), else 0", "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len s4 s7
    ld NODE_children s4 s8
M1:
    li 0 a0
    beqz M9 s7
    ld 0 s8 a0
    beq rel:M8 a0 s5
    call is_layer
    beqz M2 a0
    li MAX_DEPTH t4
    bgeu rel:M2 t4 s6
    ld 0 s8 a0
    mv s5 a1
    addi 1 s6 a2
    call libmem
    bnez M9 a0
M2:
    addi 8 s8 s8
    addi -1 s7 s7
    j M1
M8:
    li 1 a0
M9:
    leave5
", 2));
once(\$t, "\n  scope_depth:\n", "\n  lib_grp:\n    dword\n      0\n  scope_depth:\n", 'lib_grp');
save();
