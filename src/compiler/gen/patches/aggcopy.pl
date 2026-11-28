# aggcopy.pl: a local struct (union, array) whose one item is a struct of
# another type, or whose item of a scalar type is a struct value, is an
# error (the master's fault 38): d: / pb / mkdiv / 10 / 3, mkdiv returning
# pa (the same layout as pb), took the call's value, the address of pa's
# temporary, as d's first field. By the language a declaration with a
# struct of its own type is a copy and the items otherwise go one to each
# place; a place of a scalar type takes no struct value, and a struct of
# another type is no copy. decl's one-item case (L15: the value as the
# first place) and linit's item of a scalar type (L4; several items, a :
# of items, a compound literal) now stop with
#   ttpc: a struct of another type is no copy, nor an item of a scalar type: d: pb, the value pa
# (the local and its type by ldecl, which decl sets around linit and its
# check; a compound literal outside a declaration has no local to name). Test: progs/caggcopy
# (4 targets) and the ctime errors caggcopyfail1 .. caggcopyfail3.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
edit(\$t, 'cc/decl',
    "          L15:\n            mv\n              s7\n              a0\n            li\n              0\n              a1\n            call\n              member\n" =>
    "          L15:\n" . asm(12, "
    mv s7 a0
    li 0 a1
    call member
    la ldecl t0
    sd 0 s4 t0
    sd 8 s7 t0
    mv a1 a0
    mv s7 a1
    call aggchk
    la ldecl t0
    sd 0 zero t0
    mv s7 a0
    li 0 a1
    call member
"),
    "          L14:\n            mv\n              s7\n              a0\n            ld\n              VAR_off\n              s9\n              a1\n            call\n              linit\n" =>
    "          L14:\n" . asm(12, "
    la ldecl t0
    sd 0 s4 t0
    sd 8 s7 t0
    mv s7 a0
    ld VAR_off s9 a1
    call linit
    la ldecl t0
    sd 0 zero t0
"));
edit(\$t, 'cc/linit',
    "        L4:\n          li\n            1\n            a0\n          call\n            expr\n          call\n            getty\n" =>
    "        L4:\n" . asm(10, "
    li 1 a0
    call expr
    li 0 a0
    mv s4 a1
    call aggchk
    call getty
"));
{
    my ($from, $to) = find(\$t, 'cc/stmts');
    substr($t, $to, 0) = fn('aggchk', "
    # a0 the place's type (0: a scalar's), a1 the struct's (union's, array's) type: the value's type a
    # struct (a union) that is not the place's stops, naming the local decl set in ldecl (its node, its type)
    enter5
    mv a0 s4
    mv a1 s5
    la ldecl t0
    ld 0 t0 s6
    beqz A0 s6
    ld 8 t0 s5
A0:
    # (an array's place is its element: member gives the array itself)
    mv s4 a0
    call isarray
    beqz A2 a0
    ld TY_base s4 s4
A2:
    call getty
    mv a0 s7
    call isstruct
    beqz A9 a0
    beq rel:A9 s4 s7
    la msg_aggcopy a1
    li 73 a2
    call wrerr
    beqz A1 s6
    ld NODE_content s6 a1
    lbu NODE_content_len s6 a2
    add a2 a1 t0
    lbu -1 t0 t0
    addi -58 t0 t0
    seqz t0 t0
    sub t0 a2 a2
    call wrerr
    la msg_aggis a1
    li 2 a2
    call wrerr
A1:
    mv s5 a0
    call wtyname
    la msg_aggval a1
    li 12 a2
    call wrerr
    mv s7 a0
    call wtyname
    la newline a1
    li 1 a2
    j die
A9:
    leave5
", 6) . fn('wtyname', "
    # a0 a type: a struct's (a union's) name, else array, to stderr
    enter1
    mv a0 s4
    call isstruct
    beqz W1 a0
    ld TY_base s4 t1
    ld NODE_content t1 a1
    lbu NODE_content_len t1 a2
    add a2 a1 t0
    lbu -1 t0 t0
    addi -58 t0 t0
    seqz t0 t0
    sub t0 a2 a2
    call wrerr
    j W9
W1:
    la msg_aggarr a1
    li 5 a2
    call wrerr
W9:
    leave1
", 6) . fn('wrerr', "
    li STDERR a0
    li SYS_write a7
    ecall
    ret
", 6);
}
once(\$t, "      msg_type:\n", "      msg_aggcopy:\n        ascii\n          " . esc("ttpc: a struct of another type is no copy, nor an item of a scalar type:") . "\\x20\n"
    . "      msg_aggis:\n        ascii\n          :\\x20\n"
    . "      msg_aggval:\n        ascii\n          , the value\\x20\n"
    . "      msg_aggarr:\n        ascii\n          array\n      msg_type:\n", 'msg_type');
once(\$t, "  tdefonly:\n    reserve\n      8\n", "  tdefonly:\n    reserve\n      8\n  ldecl:\n    reserve\n      16\n", 'tdefonly');
save();
