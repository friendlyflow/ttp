# asmlayers.pl: an asm function past the 255 children of a node has its
# children in layers 0: 1: ... (the overflow of a node, transparent: the
# user's rule, 2026-10-18), so its asm, its align and its entry blocks
# stand in a layer. ttpc looked at the function's own children only: its
# first child 0: was no asm, so the function was taken for C ("wrong
# number of arguments"), and its entries, labels in a layer, were unknown
# names (s2ff stopped on an asm function of more than 255 parts). Now:
#   lhead   the node whose children are a0's first ones, through the
#           layers that begin it (a0 itself when it begins with none)
#   defkw   reads the first children (asm, basepcs) through lhead
#   lazyfill  an asm function's first child through lhead, its entries
#           in its layers too (lazylay)
#   asmidx, asmreach's LB  the entries of an asm function through its
#           layers (asmidxl, entin); a layer is never an entry
#   asmalign, dfirst  the first children through lhead
#   is_group  a layer is a group's only when its children are (an asm
#           function in layers was a group: no symbol with -g)
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/defkw', asm(8, "
    enter2
    mv a0 s4
") => asm(8, "
    enter2
    call lhead
    mv a0 s4
"));
{
    my ($from, $to) = find(\$t, 'is_layer');
    my $f = fn('lhead', "
    addi -16 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    mv a0 s4
H1:
    lbu NODE_children_len s4 t0
    beqz H9 t0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call is_layer
    beqz H9 a0
    ld NODE_children s4 t0
    ld 0 t0 s4
    j H1
H9:
    mv s4 a0
    ld 0 sp ra
    ld 8 sp s4
    addi 16 sp sp
    ret
");
    $f =~ s/^(.*\n)/$1    comment\n      the node whose children are the first ones of the node a0, through the layers that begin it (a0 when it begins with none)\n/;
    substr($t, $to, 0) = $f;
}

# lazyfill: an asm function's first child through lhead, its entries in its
# layers too (lazylay)
edit(\$t, 'lazyfill', asm(6, "
    call lazydef
    lbu NODE_children_len s4 t0
    beqz G8 t0
    ld NODE_children s4 t0
    ld 0 t0 t0
") => asm(6, "
    call lazydef
    mv s4 a0
    call lhead
    mv a0 s8
    lbu NODE_children_len s8 t0
    beqz G8 t0
    ld NODE_children s8 t0
    ld 0 t0 t0
"), asm(6, "
    bnez G21 a0
    ld NODE_children s4 t0
") => asm(6, "
    bnez G21 a0
    ld NODE_children s8 t0
"), asm(4, "
G5:
    ld 0 s9 a0
    call is_fn
") => asm(4, "
G5:
    ld 0 s9 a0
    call is_layer
    beqz G51 a0
    ld 0 s9 a0
    mv s5 a1
    mv s4 a2
    call lazylay
    j G7
G51:
    ld 0 s9 a0
    call is_fn
"));
{
    my ($from, $to) = find(\$t, 'lazyfill');
    my $f = fn('lazylay', "
    addi -48 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    mv a1 s5
    mv a2 s4
    lbu NODE_children_len a0 s6
    ld NODE_children a0 s7
Y1:
    beqz Y9 s6
    ld 0 s7 a0
    call is_layer
    beqz Y2 a0
    ld 0 s7 a0
    mv s5 a1
    mv s4 a2
    call lazylay
    j Y8
Y2:
    ld 0 s7 a0
    call is_fn
    beqz Y8 a0
    mv s4 a0
    mv s5 a1
    ld 0 s7 a2
    call lazydef
Y8:
    addi 8 s7 s7
    addi -1 s6 s6
    j Y1
Y9:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    addi 48 sp sp
    ret
");
    $f =~ s/^(.*\n)/$1    comment\n      lazyfill's entries of the asm function a2 (of file a1) in its layer a0, through the layers in it\n/;
    substr($t, $to, 0) = $f;
}

# asmidx (the hash of the entries of the asm functions on syms) and
# asmreach's LB (the asm function holding the entry named s4): the entries
# through the function's layers (asmidxl, entin), a layer itself never one
my $x5 = asm(8, "
X5:
    beqz X7 s8
    ld 0 s9 s10
    lbu NODE_children_len s10 t0
    beqz X6 t0
    mv s10 a0
    call defkw
    li KW_asm t0
    bne rel:X6 t0 a0
    ld NODE_content s10 t0
    lbu NODE_content_len s10 t1
    add t1 t0 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:X6 t1 t0
    ld NODE_content s10 a0
    lbu NODE_content_len s10 a1
    addi -1 a1 a1
    mv s10 a2
    mv s7 a3
    call asmins
X6:
    addi 8 s9 s9
    addi -1 s8 s8
    j X5
");
my $b2 = asm(8, "
B2:
    beqz B8 s8
    ld 0 s9 s10
    lbu NODE_children_len s10 t0
    beqz B3 t0
    mv s10 a0
    call defkw
    li KW_asm t0
    bne rel:B3 t0 a0
    ld NODE_content s10 t0
    lbu NODE_content_len s10 t1
    add t1 t0 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:B3 t1 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    ld NODE_content s10 a2
    lbu NODE_content_len s10 a3
    addi -1 a3 a3
    call streq
    bnez B7 a0
B3:
    addi 8 s9 s9
    addi -1 s8 s8
    j B2
");
my $kids = asm(10, "
    lbu NODE_children_len s7 s8
    ld NODE_children s7 s9
");
edit(\$t, 'libsym', "$kids$x5" => asm(10, "
    mv s7 a0
    mv s7 a1
    call asmidxl
"), "$kids$b2" => asm(10, "
    mv s7 a0
    ld NODE_content s4 a1
    lbu NODE_content_len s4 a2
    call entin
    mv a0 s10
    bnez B7 a0
"));
{
    my ($from, $to) = find(\$t, 'libsym');
    my $f = fn('asmidxl', "
    addi -48 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    mv a1 s5
    lbu NODE_children_len a0 s6
    ld NODE_children a0 s7
I1:
    beqz I9 s6
    ld 0 s7 s4
    mv s4 a0
    call is_layer
    beqz I2 a0
    mv s4 a0
    mv s5 a1
    call asmidxl
    j I8
I2:
    lbu NODE_children_len s4 t0
    beqz I8 t0
    mv s4 a0
    call defkw
    li KW_asm t0
    bne rel:I8 t0 a0
    ld NODE_content s4 t0
    lbu NODE_content_len s4 t1
    add t1 t0 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:I8 t1 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    addi -1 a1 a1
    mv s4 a2
    mv s5 a3
    call asmins
I8:
    addi 8 s7 s7
    addi -1 s6 s6
    j I1
I9:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    addi 48 sp sp
    ret
", 8);
    $f =~ s/^(.*\n)/$1          comment\n            asmidx's entries of the asm function a1 among the children of a0 (the function or a layer of it), through its layers\n/;
    my $g = fn('entin', "
    addi -64 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    sd 40 s8 sp
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len a0 s7
    ld NODE_children a0 s8
N1:
    li 0 a0
    beqz N9 s7
    ld 0 s8 s4
    mv s4 a0
    call is_layer
    beqz N2 a0
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call entin
    bnez N9 a0
    j N8
N2:
    lbu NODE_children_len s4 t0
    beqz N8 t0
    mv s4 a0
    call defkw
    li KW_asm t0
    bne rel:N8 t0 a0
    lbu NODE_content_len s4 a3
    beqz N8 a3
    ld NODE_content s4 a2
    add a3 a2 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:N8 t1 t0
    addi -1 a3 a3
    mv s5 a0
    mv s6 a1
    call streq
    beqz N8 a0
    mv s4 a0
    j N9
N8:
    addi 8 s8 s8
    addi -1 s7 s7
    j N1
N9:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    ld 40 sp s8
    addi 64 sp sp
    ret
", 8);
    $g =~ s/^(.*\n)/$1          comment\n            the entry named a1 a2 (a block label whose first child is asm) among the children of a0 (an asm function or a layer of it), through its layers; 0 if none\n/;
    substr($t, $to, 0) = $f . $g;
}

# asmalign (align / n first after asm) and dfirst (the kind of a label for
# -g) read the first children through lhead
edit(\$t, 'asmalign', asm(8, "
    lbu NODE_children_len s4 t0
    li 2 t1
") => asm(8, "
    mv s4 a0
    call lhead
    mv a0 s5
    lbu NODE_children_len s5 t0
    li 2 t1
"), asm(8, "
    ld NODE_children s4 t0
    ld 0 t0 a0
    call kwof
") => asm(8, "
    ld NODE_children s5 t0
    ld 0 t0 a0
    call kwof
"), asm(8, "
    ld NODE_children s4 t0
    ld 8 t0 s5
") => asm(8, "
    ld NODE_children s5 t0
    ld 8 t0 s5
"));
edit(\$t, 'dfirst', asm(4, "
    enter3
    mv a0 s4
") => asm(4, "
    enter3
    call lhead
    mv a0 s4
"));

# is_group: a layer among the children is a group's when its own children
# are (definitions or comments, through its layers): an asm function in
# layers (0: 1: are definitions by their names) was a group, so -g left
# it out of the symbols and the program page's groups (pgroups) were
# looked into it
edit(\$t, 'is_group', asm(4, "
L1:
    li 1 a0
    beqz L9 s5
    ld 0 s4 a0
    call is_fn
") => asm(4, "
L1:
    li 1 a0
    beqz L9 s5
    ld 0 s4 a0
    call is_layer
    beqz L11 a0
    ld 0 s4 a0
    call is_group
    beqz L9 a0
    j L2
L11:
    ld 0 s4 a0
    call is_fn
"));
save();
