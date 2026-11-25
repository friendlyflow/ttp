# flindex.pl: find_label looks a name up in the program page through an
# index (the master's index, the user's choice, 2026-11-24). find_label
# walked: lfind over each scope's children (the program page's top level
# the outermost, through its layers), then pgroups over every group of the
# program page and their layers; on a page of 34 MB (coreutils) each lookup
# that reached the page cost its size, about 98% of the time (is_layer,
# is_fn, lfind, is_group): gawk 61 minutes, coreutils over 8 hours. The tree
# of the program page does not change while ttpc compiles it, so clfind
# builds, the first time a node (32 children or more, or a last child
# that is a layer: a long function's body) or the page's groups are asked, an index of every name in it in lfind's or pgroups' own order
# (idx_wl, idx_wg: the first of a name wins, as the walk finds it first;
# a node is classed once, idx_count: under 32 names it is walked as before;
# an indexed node whose children (their address or count) are not those it
# was indexed with, as while ttpc works on a node, is walked as before),
# in idxtab (2^20 slots of 32 bytes, open addressing: the owner and kind,
# the name's address, its length and 32-bit FNV-1a hash, the node), and then
# answers from it (idx_find compares the owner, length, hash and bytes); a
# node of fewer children (a function's own scope) is walked as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  lookcache:\n    reserve\n", "  idxtab:\n    reserve\n      33554432\n  idxown:\n    reserve\n      2097152\n  lookcache:\n    reserve\n", 'lookcache');

edit(\$t, 'find_label',
    "      li\n        0\n        a1\n      call\n        lfind\n      beqz\n        L1\n" =>
    "      li\n        0\n        a1\n      li\n        0\n        a2\n      call\n        clfind\n      beqz\n        L1\n",
    "      li\n        0\n        a1\n      call\n        pgroups\n" =>
    "      li\n        0\n        a1\n      li\n        1\n        a2\n      call\n        clfind\n");

my ($from, $to) = find(\$t, 'find_label');
substr($t, $to, 0) = join '',
  "    comment\n      clfind: lfind (a2 0) or pgroups (a2 1) of the node a0 (a1 0) for find_label's name s4 s5, from the index of the node (32 children or more, or a layer last) or of the page's groups\n",
  fn('clfind', "
    enter8
    mv a0 s6
    mv a2 s7
    or s7 s6 s8
    mv s8 a0
    call idx_state
    mv a1 s9
    li 2 t0
    beq rel:LP t0 a0
    beqz LN a0
    ld 16 s9 t0
    ld NODE_children s6 t1
    bne rel:LP t0 t1
    ld 24 s9 t0
    lbu NODE_children_len s6 t1
    bne rel:LP t0 t1
    j LF
LN:
    ld NODE_children s6 t0
    sd 16 t0 s9
    lbu NODE_children_len s6 t0
    sd 24 t0 s9
    bnez LG s7
    mv s6 a0
    li 0 a1
    call idx_count
    li 32 t0
    bltu rel:LS t0 a0
    li 1 t0
    sd 8 t0 s9
    mv s8 a0
    mv s6 a1
    li 0 a2
    call idx_wl
    j LF
LS:
    li 2 t0
    sd 8 t0 s9
    j LP
LG:
    li 1 t0
    sd 8 t0 s9
    mv s8 a0
    mv s6 a1
    li 0 a2
    call idx_wg
LF:
    mv s8 a0
    call idx_find
    leave8
LP:
    mv s6 a0
    li 0 a1
    call lfind
    leave8
", 4),
  "    comment\n      idx_count: how many names lfind would look at under the node a0 (its definitions, through its layers, a1 deep)\n",
  fn('idx_count', "
    enter5
    mv a0 s4
    mv a1 s5
    li 0 s6
    lbu NODE_children_len s4 s7
    ld NODE_children s4 s8
C1:
    beqz C9 s7
    ld 0 s8 a0
    call is_fn
    beqz C5 a0
    ld 0 s8 a0
    call is_layer
    beqz C3 a0
    li MAX_DEPTH t0
    bgeu rel:C5 t0 s5
    ld 0 s8 a0
    addi 1 s5 a1
    call idx_count
    add a0 s6 s6
    j C5
C3:
    addi 1 s6 s6
C5:
    addi 8 s8 s8
    addi -1 s7 s7
    j C1
C9:
    mv s6 a0
    leave5
", 4),
  "    comment\n      hashname: a0 = the 32-bit FNV-1a hash of the a1 bytes at a0\n",
  fn('hashname', "
    li32 2166136261 t2
    li 0 t3
H1:
    bgeu rel:H2 a1 t3
    add a0 t3 t4
    lbu 0 t4 t4
    xor t4 t2 t2
    li32 16777619 t5
    mul t5 t2 t2
    addi 1 t3 t3
    j H1
H2:
    slli 32 t2 a0
    srli 32 a0 a0
    ret
", 4),
  "    comment\n      idx_state: the state of the owner and kind a0, its entry in a1: 1 indexed, 2 walked (few names), 0 new (the entry is its now, state 0)\n",
  fn('idx_state', "
    srli 3 a0 t0
    li32 65535 t1
    and t1 t0 t0
B1:
    slli 5 t0 t2
    la idxown t3
    add t3 t2 t2
    ld 0 t2 t4
    beqz B8 t4
    beq rel:B9 t4 a0
    addi 1 t0 t0
    li32 65535 t1
    and t1 t0 t0
    j B1
B8:
    sd 0 a0 t2
    sd 8 zero t2
    mv t2 a1
    li 0 a0
    ret
B9:
    mv t2 a1
    ld 8 t2 a0
    ret
", 4),
  "    comment\n      idx_ins: the child a1 into the index of a0 under its name, unless the name is there (the first one wins)\n",
  fn('idx_ins', "
    enter8
    mv a0 s4
    mv a1 s5
    ld NODE_content s5 s6
    lbu NODE_content_len s5 s7
    addi -1 s7 s7
    mv s6 a0
    mv s7 a1
    call hashname
    slli 16 a0 s8
    or s7 s8 s8
    srli 3 s4 t0
    xor a0 t0 s9
    li32 1048575 t1
    and t1 s9 s9
I1:
    slli 5 s9 t1
    la idxtab t2
    add t2 t1 s10
    ld 0 s10 t2
    beqz I8 t2
    bne rel:I5 t2 s4
    ld 16 s10 t2
    bne rel:I5 t2 s8
    mv s6 a0
    mv s7 a1
    ld 8 s10 a2
    mv s7 a3
    call streq
    bnez I9 a0
I5:
    addi 1 s9 s9
    li32 1048575 t1
    and t1 s9 s9
    j I1
I8:
    sd 0 s4 s10
    sd 8 s6 s10
    sd 16 s8 s10
    sd 24 s5 s10
I9:
    leave8
", 4),
  "    comment\n      idx_find: the node named as find_label's s4 s5 in the index of a0, or 0\n",
  fn('idx_find', "
    enter8
    mv a0 s6
    mv s4 a0
    mv s5 a1
    call hashname
    slli 16 a0 s8
    or s5 s8 s8
    srli 3 s6 t0
    xor a0 t0 s9
    li32 1048575 t1
    and t1 s9 s9
Q1:
    slli 5 s9 t1
    la idxtab t2
    add t2 t1 s10
    ld 0 s10 t2
    beqz Q8 t2
    bne rel:Q5 t2 s6
    ld 16 s10 t2
    bne rel:Q5 t2 s8
    mv s4 a0
    mv s5 a1
    ld 8 s10 a2
    mv s5 a3
    call streq
    beqz Q5 a0
    ld 24 s10 a0
    leave8
Q5:
    addi 1 s9 s9
    li32 1048575 t1
    and t1 s9 s9
    j Q1
Q8:
    li 0 a0
    leave8
", 4),
  "    comment\n      idx_wl: the names of the node a1 into the index of a0, as lfind finds them (its children that are definitions, through its layers, a2 deep)\n",
  fn('idx_wl', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len s5 s7
    ld NODE_children s5 s8
W1:
    beqz W9 s7
    ld 0 s8 a0
    call is_fn
    beqz W5 a0
    ld 0 s8 a0
    call is_layer
    beqz W3 a0
    li MAX_DEPTH t0
    bgeu rel:W5 t0 s6
    mv s4 a0
    ld 0 s8 a1
    addi 1 s6 a2
    call idx_wl
    j W5
W3:
    mv s4 a0
    ld 0 s8 a1
    call idx_ins
W5:
    addi 8 s8 s8
    addi -1 s7 s7
    j W1
W9:
    leave8
", 4),
  "    comment\n      idx_wg: the names of the groups of the node a1 (through its layers, a2 deep) into the index of a0, as pgroups finds them\n",
  fn('idx_wg', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len s5 s7
    ld NODE_children s5 s8
G1:
    beqz G9 s7
    ld 0 s8 a0
    call is_layer
    beqz G3 a0
    li MAX_DEPTH t0
    bgeu rel:G5 t0 s6
    mv s4 a0
    ld 0 s8 a1
    addi 1 s6 a2
    call idx_wg
    j G5
G3:
    ld 0 s8 a0
    call is_group
    beqz G5 a0
    mv s4 a0
    ld 0 s8 a1
    li 0 a2
    call idx_wl
G5:
    addi 8 s8 s8
    addi -1 s7 s7
    j G1
G9:
    leave8
", 4);
save();
