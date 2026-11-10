# progroups.pl: a group's definitions are seen by the whole program on
# every page, the program page's too (the user's choice, 2026-11-10: 1A).
# A definition page's groups were (collect_syms puts their definitions on
# syms), but a group on the program page kept its children to itself:
# `cpp_main`, in the group cpp: of a program page, was an unknown name to
# its _start. Now find_label, when no scope has the name, looks in the
# program page's groups (sec_prog's children that are groups, through the
# layers of the page and of each group): after every scope, so the page's
# own top-level names come first, and before the other pages (cfind,
# tyword, litk go to them after find_label). A nested function's children
# stay local: only a group (a definition whose children are all
# definitions or comments, is_group) is looked into, one level deep, as a
# definition page's are.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'find_label', asm(4, "
L4:
    li 0 a0
") => asm(4, "
L4:
    la sec_prog t0
    ld 0 t0 a0
    beqz L6 a0
    li 0 a1
    call pgroups
    j L5
L6:
    li 0 a0
"));
my ($from, $to) = find(\$t, 'find_label/lfind');
my $f = fn('pgroups', "
    enter5
    mv a0 s6
    mv a1 s7
    lbu NODE_children_len a0 s8
    ld NODE_children a0 s6
P1:
    li 0 a0
    beqz P9 s8
    ld 0 s6 a0
    call is_layer
    beqz P2 a0
    li MAX_DEPTH t4
    bgeu rel:P3 t4 s7
    ld 0 s6 a0
    addi 1 s7 a1
    call pgroups
    bnez P9 a0
    j P3
P2:
    ld 0 s6 a0
    call is_group
    beqz P3 a0
    ld 0 s6 a0
    li 0 a1
    call lfind
    bnez P9 a0
P3:
    addi 8 s6 s6
    addi -1 s8 s8
    j P1
P9:
    leave5
", 4);
$f =~ s/^(.*\n)/$1      comment\n        the definition named as find_label's s4 s5 in a group among the children of a0 (the program page), through its layers (a1 deep); 0 if none\n/;
substr($t, $to, 0) = $f;
save();
