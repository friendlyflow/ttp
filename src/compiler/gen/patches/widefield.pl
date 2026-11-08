# widefield.pl: wgate also sees a value of a type in memory (double on arm,
# long double) that a function reaches through a field or an element: a
# name whose type is a struct or union with such a field (at any depth of
# fields and arrays), an array of them, or an address of one of those (the
# addresses followed from the name's type only, never from a field's, so a
# list that points to itself ends). And a name with children (a global's
# field, gp / d; an element, ga / 2) is looked at too, as a leaf was. On arm
# a function that reached a double only through p->d and named no double
# stopped ttpc with widename's message. Such a function now has its
# temporaries; one that only names such a type has them too (16 bytes of
# its frame). Test: cwgate.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub C { my ($ind, @l) = @_; ' ' x $ind . "comment\n" . join '', map { ' ' x ($ind + 2) . "$_\n" } @l }

my $wrec = "      wrec:\n" . C(8,
    "1 where a value of the type a0, or of a field or element of it, is in a temporary (fwidev), fields of fields and arrays at any depth.",
    "a1 = 1: an address is followed to what it points to (the type of a name), 0: not (a field's type).") . asm(8, "
    enter5
    mv a0 s4
    mv a1 s7
LP:
    lui TY_REC t0
    bltu rel:LS t0 s4
    ld TY_kind s4 t1
    li TY_ADDRESS t0
    beq rel:LD t0 t1
    li TY_ARRAY t0
    beq rel:LA t0 t1
    li TY_STRUCT t0
    beq rel:LR t0 t1
LS:
    mv s4 a0
    call fwidev
    leave5
LD:
    beqz L0 s7
LA:
    ld TY_base s4 s4
    j LP
LR:
    ld TY_base s4 t0
    ld NODE_children t0 s5
    lbu NODE_children_len t0 s6
LF:
    beqz L0 s6
    ld 0 s5 t2
    ld NODE_content t2 t0
    lbu NODE_content_len t2 t1
    beqz LN t1
    add t1 t0 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:LN t1 t0
    lbu NODE_children_len t2 t0
    beqz LN t0
    ld NODE_children t2 a0
    slli 3 t0 t0
    add a0 t0 a1
    call typerun
    bltz LN a0
    li 0 a1
    call wrec
    bnez L1 a0
LN:
    addi 8 s5 s5
    addi -1 s6 s6
    j LF
L0:
    li 0 a0
    leave5
L1:
    li 1 a0
    leave5
");
my $wname = "      wname:\n" . C(8,
    "1 where the name of the node a0 is a label (find_label) whose type, the run of its children, has a value in a temporary (wrec, its addresses followed).") . asm(8, "
    enter1
    ld NODE_content a0 t0
    lbu NODE_content_len a0 a1
    mv t0 a0
    call find_label
    beqz L9 a0
    lbu NODE_children_len a0 t0
    beqz L9 t0
    ld NODE_children a0 t1
    slli 3 t0 t0
    add t0 t1 a1
    mv t1 a0
    call typerun
    bltz L9 a0
    li 1 a1
    call wrec
    leave1
L9:
    li 0 a0
    leave1
");
once(\$t, "\n      wgate:\n", "\n$wrec$wname      wgate:\n", 'wrec and wname');

edit(\$t, 'wgate', asm(8, "
    ld NODE_children s4 s6
    bnez L2 s5
    ld NODE_content s4 a0
") => asm(8, "
    ld NODE_children s4 s6
    bnez LC s5
    ld NODE_content s4 a0
"), asm(8, "
L3:
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call find_label
    beqz L9 a0
    lbu NODE_children_len a0 t0
    beqz L9 t0
    ld NODE_children a0 t1
    slli 3 t0 t0
    add t0 t1 a1
    mv t1 a0
    call typerun
    bltz L9 a0
    call fwidev
    bnez L8 a0
    j L9
") => asm(8, "
L3:
    mv s4 a0
    call wname
    bnez L8 a0
    j L9
LC:
    mv s4 a0
    call wname
    bnez L8 a0
    j L2
"));
save();
