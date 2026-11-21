# weakref.pl: a weak reference and a definition's with (the user's rule,
# 2026-11-18): a weak reference never pulls a definition in, as ld does
# with archive members; its address is the definition's if something else
# in the program reaches it, else 0.
#   weak / name, then & address (or as a value): the reference. addr finds
#     the name with tscan_quiet set (libsym adds nothing to the library's
#     run) and weakref set (gaddr: no label in the second pass is 0, as for
#     a weak declaration); primary's LWK gives its value.
#   weak / (f / args), and weak / f of a function (C's f ()): a call through
#     that address (0 when f is placed by nothing else); call's LWR, as a weak declaration's call (L47), its
#     result the function's type.
#   weak / name, & address in a global's items (gval's LWG), and weak / name
#     as an item's value (LWV: an array's or a function's address): its
#     label's address, 0 where nothing else places it.
#   with / names..., first under a definition's name: placing the
#     definition (libadd) places the names too (withadd), as ld's object
#     member brings all its symbols (glibc's _NL_CURRENT_DEFINE flags with
#     the _nl_current_ variable of their unit). ctone (ctscan, every
#     definition before the compiles) and lazyfill (a file read lazily)
#     take it off and note it (withstrip,
#     with_tab), as it takes off a constructor; before that alskip skips it
#     (withskip),
#     so every type run past align skips it, and defkw reads the keyword
#     after it (thread local after it istls finds already).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "\n  ccs:\n", "\n  weakref:\n    reserve\n      8\n  with_n:\n    reserve\n      8\n  with_tab:\n    reserve\n      65536\n  ccs:\n", 'ccs');
once(\$t, "  str_asm:\n    ascii\n      asm\n", "  str_asm:\n    ascii\n      asm\n  str_with:\n    ascii\n      with\n", 'str_asm');

# gaddr: no label in the second pass is 0 for a weak reference too
edit(\$t, 'cc/gaddr', asm(8, "
L2:
    mv s4 a0
    la msg_below a1
") => asm(8, "
L2:
    li 0 a0
    la weakref t0
    ld 0 t0 t0
    bnez L1 t0
    mv s4 a0
    la msg_below a1
"));

# addr: weak / name is the name's address, found and placed weakly
edit(\$t, 'cc/addr', asm(8, "
L3:
    mv s4 a0
    call AT
") => asm(8, "
L3:
    mv s4 a0
    call kwof
    li KW_weak t0
    beq rel:AWK t0 a0
    mv s4 a0
    call AT
"), asm(8, "
AT:
    enter1
") => asm(8, "
AWK:
    lbu NODE_children_len s4 t0
    li 1 t1
    bne rel:AWB t1 t0
    ld NODE_children s4 t0
    ld 0 t0 s5
    lbu NODE_children_len s5 t0
    bnez AWB t0
    li 1 t1
    la tscan_quiet t0
    sd 0 t1 t0
    la weakref t0
    sd 0 t1 t0
    mv s5 a0
    call addr
    la tscan_quiet t0
    sd 0 zero t0
    la weakref t0
    sd 0 zero t0
    leave2
AWB:
    mv s4 a0
    call bad
AT:
    enter1
"));

# primary: weak / name as a value, weak / (f / args) a call
edit(\$t, 'cc/primary', asm(10, "
    li KW_cast t0
    beq rel:L60 t0 a0
") => asm(10, "
    li KW_cast t0
    beq rel:L60 t0 a0
    li KW_weak t0
    beq rel:LWK t0 a0
"), asm(8, "
L60:
") => asm(8, "
LWK:
    lbu NODE_children_len s4 t0
    li 1 t1
    bne rel:LWB t1 t0
    ld NODE_children s4 t0
    ld 0 t0 s5
LWC:
    li 1 t1
    la tscan_quiet t0
    sd 0 t1 t0
    la weakref t0
    sd 0 t1 t0
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    mv s5 a2
    call cfind
    la tscan_quiet t0
    sd 0 zero t0
    beqz LWB a0
    mv a0 s6
    lbu NODE_children_len s5 t0
    bnez LWC2 t0
    mv s6 a0
    call defkw
    li KW_asm t0
    beq rel:LWC2 t0 a0
    li KW_weak t0
    beq rel:LWC2 t0 a0
    mv s6 a0
    call kind
    li 1 t0
    beq rel:LWC2 t0 a0
    la weakref t0
    sd 0 zero t0
    mv s4 a0
    call addr
    call rvalue
    j L9
LWC2:
    mv s5 a0
    mv s6 a1
    call call
    la weakref t0
    sd 0 zero t0
    j L9
LWB:
    la weakref t0
    sd 0 zero t0
    la tscan_quiet t0
    sd 0 zero t0
    mv s4 a0
    call bad
L60:
"));

# call: a weak reference's call goes through its address (weakref set by
# primary's LWC for the callee only)
edit(\$t, 'cc/call', asm(8, "
    li KW_weak t0
    beq rel:L46 t0 a0
") => asm(8, "
    li KW_weak t0
    beq rel:L46 t0 a0
    la weakref t0
    ld 0 t0 t0
    bnez LWR t0
"), asm(8, "
L42:
") => asm(8, "
LWR:
    li TY_LONG s6
    mv s5 a0
    call kind
    li 1 t0
    bne rel:LWR1 t0 a0
    mv s5 a0
    call dtype
    mv a0 s6
LWR1:
    mv s5 a0
    call gaddr
    la weakref t0
    sd 0 zero t0
    j L47
L42:
"));

# alskip: past a with first (withskip)
edit(\$t, 'cc/alskip', asm(8, "
    enter1
    mv a0 s4
    call alval
") => asm(8, "
    enter1
    call withskip
    mv a0 s4
    call alval
"));
{
    my ($from, $to) = find(\$t, 'cc/alskip');
    my $f = fn('withskip', "
    bgeu rel:WS9 a1 a0
    ld 0 a0 t0
    lbu NODE_children_len t0 t1
    beqz WS9 t1
    lbu NODE_content_len t0 t1
    li 4 t2
    bne rel:WS9 t2 t1
    ld NODE_content t0 t1
    lbu 0 t1 t2
    li 119 t3
    bne rel:WS9 t3 t2
    lbu 1 t1 t2
    li 105 t3
    bne rel:WS9 t3 t2
    lbu 2 t1 t2
    li 116 t3
    bne rel:WS9 t3 t2
    lbu 3 t1 t2
    li 104 t3
    bne rel:WS9 t3 t2
    addi 8 a0 a0
WS9:
    ret
", 6);
    $f =~ s/^(.*\n)/$1        comment\n          the run at a0 (a1 its end) past a with first (with \/ names: what placing the definition places too): a0\n/;
    substr($t, $to, 0) = $f;
}

# libadd: a definition placed places its with's names too (withadd)
edit(\$t, 'cc/libadd', asm(10, "
    sd 0 t0 s5
    j L9
") => asm(10, "
    sd 0 t0 s5
    mv s4 a0
    call withadd
    j L9
"));
{
    my ($from, $to) = find(\$t, 'cc/libadd');
    my $f = fn('withadd', "
    enter3
    mv a0 s4
    la with_n t0
    ld 0 t0 t1
    la with_tab t2
WA0:
    beqz WA9 t1
    ld 0 t2 t3
    beq rel:WA01 t3 s4
    addi 16 t2 t2
    addi -1 t1 t1
    j WA0
WA01:
    ld 8 t2 s4
    lbu NODE_children_len s4 s5
    ld NODE_children s4 s6
WA1:
    beqz WA9 s5
    ld 0 s6 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call libfind
    beqz WA2 a0
    call libadd
WA2:
    addi 8 s6 s6
    addi -1 s5 s5
    j WA1
WA9:
    leave3
", 6);
    $f =~ s/^(.*\n)/$1        comment\n          the names of the with taken off the definition a0 (withstrip), each placed (libadd) where the library defines it\n/;
    my $g = fn('withstrip', "
    lbu NODE_children_len a0 t0
    beqz WS9 t0
    ld NODE_children a0 t1
    ld 0 t1 t2
    lbu NODE_children_len t2 t3
    beqz WS9 t3
    lbu NODE_content_len t2 t3
    li 4 t4
    bne rel:WS9 t4 t3
    ld NODE_content t2 t3
    lbu 0 t3 t4
    li 119 t5
    bne rel:WS9 t5 t4
    lbu 1 t3 t4
    li 105 t5
    bne rel:WS9 t5 t4
    lbu 2 t3 t4
    li 116 t5
    bne rel:WS9 t5 t4
    lbu 3 t3 t4
    li 104 t5
    bne rel:WS9 t5 t4
    la with_n t3
    ld 0 t3 t4
    li32 4096 t5
    bgeu rel:WS9 t5 t4
    slli 4 t4 t5
    la with_tab t6
    add t6 t5 t5
    sd 0 a0 t5
    sd 8 t2 t5
    addi 1 t4 t4
    sd 0 t4 t3
    addi 8 t1 t1
    sd NODE_children t1 a0
    addi -1 t0 t0
    sb NODE_children_len t0 a0
WS9:
    ret
", 2);
    $g =~ s/^(.*\n)/$1    comment\n      a with first under the definition a0 taken off it and noted (with_tab, 4096 of them: the definition, the with), as ctone takes off a constructor; withadd places its names with the definition\n/;
    substr($t, $to, 0) = $f;
    my ($lf, $lt) = find(\$t, 'is_layer');
    substr($t, $lt, 0) = $g;
}

# gval: weak / name, & address in a global's items: the definition's
# address if placed, else 0; nothing placed by it
edit(\$t, 'cc/gval', asm(8, "
L40:
    call gpath
    addi 8 s4 a1
    j L9
") => asm(8, "
L40:
    addi -16 sp sp
    sd 0 a0 sp
    call kwof
    mv a0 t0
    ld 0 sp a0
    addi 16 sp sp
    li KW_weak t1
    beq rel:LWG t1 t0
    call gpath
    addi 8 s4 a1
    j L9
LWG:
    lbu NODE_children_len a0 t0
    li 1 t1
    bne rel:LWG8 t1 t0
    ld NODE_children a0 t0
    ld 0 t0 s5
    lbu NODE_children_len s5 t0
    bnez LWG8 t0
    li 1 t1
    la tscan_quiet t0
    sd 0 t1 t0
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    mv s5 a2
    call cfind
    la tscan_quiet t0
    sd 0 zero t0
    beqz LWG9 a0
    call label_addr
LWG9:
    addi 8 s4 a1
    j L9
LWG8:
    call bad
"));

# defkw: past a with first, the keyword of the child after it (weak,
# section, constructor ... of a definition that has a with)
edit(\$t, 'cc/defkw', asm(8, "
    ld 0 t1 a0
    lbu NODE_children_len a0 t2
    bnez L1 t2
    call kwof
    li KW_basepcs t0
") => asm(8, "
    ld 0 t1 a0
    lbu NODE_children_len a0 t2
    bnez LWT t2
    call kwof
    li KW_basepcs t0
"), asm(8, "
L1:
    mv s5 a0
    leave2
") => asm(8, "
L1:
    mv s5 a0
    leave2
LWT:
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t1
    slli 3 t1 t1
    add t1 a0 a1
    mv a0 s5
    call withskip
    beq rel:LWT1 a0 s5
    bgeu rel:LWT1 a1 a0
    ld 0 a0 a0
    lbu NODE_children_len a0 t2
    bnez LWT1 t2
    call kwof
    j L9
LWT1:
    li -1 s5
    j L1
"));

# ctone (ctscan's look at every definition of the program's page and the
# library's, before any compiles): a with first is taken off (withstrip)
edit(\$t, 'cc/ctone', asm(8, "
    enter3
    mv a0 s4
    mv a1 s5
") => asm(8, "
    enter3
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call withstrip
"));

# lazyfill (each definition of a file read lazily, a library folder's):
# its with taken off too (withstrip), before it is compiled
edit(\$t, 'lazyfill', asm(4, "
G2:
    mv s4 a0
    call is_fn
    beqz G8 a0
") => asm(4, "
G2:
    mv s4 a0
    call is_fn
    beqz G8 a0
    mv s4 a0
    call withstrip
"));

# gval: weak / name as a global's item's value (an array's or a function's
# address, C's decay: glibc's _nl_global_locale's __ctype_b,
# (const uint16_t *) _nl_C_LC_CTYPE_class + 128): its label's address,
# 0 where nothing else places it (gval's LWV), as LWG for & address
edit(\$t, 'cc/gval', asm(8, "
L10:
    mv s5 a0
    call kwof
    li KW_address t0
") => asm(8, "
L10:
    mv s5 a0
    call kwof
    li KW_weak t0
    beq rel:LWV t0 a0
    mv s5 a0
    call kwof
    li KW_address t0
"), asm(8, "
LWG8:
    call bad
") => asm(8, "
LWG8:
    call bad
LWV:
    mv s5 a0
    li 1 t1
    lbu NODE_children_len a0 t0
    bne rel:LWG8 t1 t0
    ld NODE_children a0 t0
    ld 0 t0 s5
    lbu NODE_children_len s5 t0
    bnez LWG8 t0
    la tscan_quiet t0
    sd 0 t1 t0
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    mv s5 a2
    call cfind
    la tscan_quiet t0
    sd 0 zero t0
    beqz LWV9 a0
    call label_addr
LWV9:
    addi 8 s4 a1
    j L9
"));
save();
