# scopeexit.pl: a scope's exit actions, and C's cleanup attribute on them
# (the user's choice, 2026-10-23: option A), the word cleanup with the
# function's name under it, first under a local (after an align):
#
#   _IO_acquire_lock_file:
#     cleanup
#       _IO_acquire_lock_fct
#     _IO_FILE
#     * pointer
#     :
#       fp'
#
# At every exit of the local's block the function is called with the
# local's address, newest first: the block's end, a return (after its
# value), a break or continue out of it, a goto to a label outside it.
#
# The machinery is general (the ownership lane, B-own, will use it to free a
# pointer at its last use): a stack of exit actions, each a node that is
# compiled as a statement at each exit of the scope it was pushed in, with
# the range of nodes (pointers to them) that is still in its scope, which
# goto searches for its label.
#
#   sepush   a0 the action's node, a1 a2 the range of its scope: pushed
#   seemit   a0 a height: the actions above it compiled, newest first
#   seclose  a0 a height: seemit, then the stack is cut to it
#
# A scope (scoped, for) closes at its end what it pushed; a function (frame)
# starts with an empty stack and closes it after its body. return keeps its
# value on the stack while the actions run (seret), break and continue go
# down to the height their label was made at (newlabel keeps it, se_lh),
# goto down to the first action whose range holds the label (segoto,
# sefind). Not covered: a computed goto (goto / p / * pointer); an action
# that changes an in-memory return value (a struct's, a long double's) after
# return computed it, which C forbids no less.
#
# cleanup: typerun passes over it (clskip), decl's caller (stmt) pushes the
# call (secl): a call node of the function with the local's address, the
# local named by a name of its own (an alias of it in cc_vars, \x01 and its
# slot), so that an inner local of the same name does not hide it.
# Test: ccleanup.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

once(\$t, "\n  al_word:\n    ascii\n      align\n",
    "\n  al_word:\n    ascii\n      align\n  cl_word:\n    ascii\n      cleanup\n  ad_word:\n    ascii\n      & address\n", 'al_word');

# the stack (32 bytes an action: node, range), the heights of the labels,
# the cleanup calls' nodes (4 of 64 bytes a slot) and alias names
once(\$t, "\n  irw_pend:\n    reserve\n      8\n",
    "\n  irw_pend:\n    reserve\n      8\n  se_top:\n    reserve\n      8\n  se_tab:\n    reserve\n      8192\n"
    . "  se_lh:\n    reserve\n      524288\n  se_nodes:\n    reserve\n      65536\n  se_names:\n    reserve\n      512\n", 'irw_pend');

# typerun: past a cleanup (after an align)
edit(\$t, 'cc/typerun', asm(8, "
    call alskip
    mv a0 s4
"), asm(8, "
    call alskip
    mv a0 s4
    mv s5 a1
    call clskip
    mv a0 s4
"));

# stmt: a declaration's cleanup; return, break, continue
edit(\$t, 'cc/stmt', asm(8, "
L2:
    call next
    call decl
    j L9
"), asm(8, "
L2:
    call next
    call decl
    mv s4 a0
    call secl
    j L9
"), asm(8, "
L12:
    call next
    lbu NODE_children_len s4 t0
    beqz L16 t0
    call exprof
    call retval
L16:
"), asm(8, "
L12:
    call next
    lbu NODE_children_len s4 t0
    beqz LS16 t0
    call exprof
    call seret
    call retval
    j L16
LS16:
    li 0 a0
    call seemit
L16:
"), asm(8, "
L13:
    call next
    la ccs t0
    ld CC_brk t0 a0
    bltz L17 a0
    call jump
"), asm(8, "
L13:
    call next
    la ccs t0
    ld CC_brk t0 a0
    bltz L17 a0
    call sejump
"), asm(8, "
L14:
    call next
    la ccs t0
    ld CC_cont t0 a0
    bltz L17 a0
    call jump
"), asm(8, "
L14:
    call next
    la ccs t0
    ld CC_cont t0 a0
    bltz L17 a0
    call sejump
"));

# return as a value (primary) and a bare one (leafval)
edit(\$t, 'cc/primary', asm(8, "
L45:
    mv s4 a0
    call exprof
    call retval
"), asm(8, "
L45:
    mv s4 a0
    call exprof
    call seret
    call retval
"));
edit(\$t, 'cc/leafval', asm(8, "
L42:
    la ccs t0
    ld CC_epi t0 a0
    call jump
"), asm(8, "
L42:
    li 0 a0
    call seemit
    la ccs t0
    ld CC_epi t0 a0
    call jump
"));

# goto: down to the action whose range holds the label
edit(\$t, 'cc/goto', asm(8, "
    call golabel
    call jump
    j L9
"), asm(8, "
    call golabel
    ld NODE_children s4 t0
    ld 0 t0 t0
    ld NODE_content t0 a1
    lbu NODE_content_len t0 a2
    call segoto
    j L9
"));

# a block (scoped) and a for close what they pushed
for my $s (['cc/scoped', 'stmts'], ['cc/for', 'forloop']) {
    my ($name, $body) = @$s;
    edit(\$t, $name, asm(8, "
    enter2
    la ccs t0
    ld CC_nvars t0 s4
    ld CC_depth t0 s5
    call $body
"), asm(8, "
    enter3
    la se_top t0
    ld 0 t0 s6
    la ccs t0
    ld CC_nvars t0 s4
    ld CC_depth t0 s5
    call $body
    mv s6 a0
    call seclose
"), asm(8, "
    call syncsp
    leave2
"), asm(8, "
    call syncsp
    leave3
"));
}

# a function: an empty stack, closed after the body (its end, before the
# label return jumps to); the stack of an enclosing one kept
edit(\$t, 'cc/frame', asm(8, "
    enter2
    mv a0 s4
    mv a1 s5
"), asm(8, "
    enter3
    mv a0 s4
    mv a1 s5
    la se_top t0
    ld 0 t0 s6
    sd 0 zero t0
"), asm(8, "
    jalr 0 s5 ra
"), asm(8, "
    jalr 0 s5 ra
    li 0 a0
    call seclose
"), asm(8, "
    ld CC_vbase t0 t1
    sd CC_nvars t1 t0
    leave2
"), asm(8, "
    ld CC_vbase t0 t1
    sd CC_nvars t1 t0
    la se_top t0
    sd 0 s6 t0
    leave3
"));

# a label keeps the height it was made at: a break's or continue's
edit(\$t, 'cc/newlabel', asm(8, "
    sd CC_glab t1 t0
    ret
"), asm(8, "
    sd CC_glab t1 t0
    la se_top t1
    ld 0 t1 t1
    la se_lh t2
    add a0 t2 t2
    sb 0 t1 t2
    ret
"));

my $fns = cfn('sepush', "push an exit action: a0 its node, a1 a2 the range of its scope (at most 255)", "
    la se_top t0
    ld 0 t0 t1
    li 255 t2
    bltu rel:P1 t2 t1
    j bad
P1:
    slli 5 t1 t2
    la se_tab t3
    add t2 t3 t3
    sd 0 a0 t3
    sd 8 a1 t3
    sd 16 a2 t3
    addi 1 t1 t1
    sd 0 t1 t0
    ret
", 6)
. cfn('seemit', "compile the exit actions above height a0, newest first (the stack stays)", "
    enter2
    mv a0 s4
    la se_top t0
    ld 0 t0 s5
E1:
    bgeu rel:E9 s5 s4
    addi -1 s5 s5
    slli 5 s5 t0
    la se_tab a0
    add t0 a0 a0
    addi 8 a0 a1
    call stmts
    j E1
E9:
    leave2
", 6)
. cfn('seclose', "the end of a scope: the exit actions above height a0 compiled, the stack cut to it", "
    enter1
    mv a0 s4
    call seemit
    la se_top t0
    ld 0 t0 t1
    bgeu rel:K9 t1 s4
    sd 0 s4 t0
K9:
    leave1
", 6)
. cfn('sejump', "break or continue to label a0: the actions above the height it was made at, then the jump", "
    enter1
    mv a0 s4
    la se_lh t0
    add s4 t0 t0
    lbu 0 t0 a0
    call seemit
    mv s4 a0
    call jump
    leave1
", 6)
. cfn('segoto', "goto label a0 (named a1, length a2): the actions whose range does not hold the label, then the jump", "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    beqz G0 s6
    add s6 s5 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:G0 t1 t0
    addi -1 s6 s6
G0:
    la se_top t0
    ld 0 t0 s7
G1:
    beqz G9 s7
    addi -1 s7 s7
    slli 5 s7 t0
    la se_tab s8
    add t0 s8 s8
    ld 8 s8 a0
    ld 16 s8 a1
    mv s5 a2
    mv s6 a3
    call sefind
    bnez G9 a0
    mv s8 a0
    addi 8 s8 a1
    call stmts
    j G1
G9:
    mv s4 a0
    call jump
    leave5
", 6)
. cfn('sefind', "1 where the nodes a0..a1 (pointers to them) or theirs hold the label named a2 (length a3): a name: without a type, else 0", "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
F1:
    li 0 a0
    bgeu rel:F9 s5 s4
    ld 0 s4 s8
    addi 8 s4 s4
    lbu NODE_content_len s8 t0
    addi 1 s7 t1
    bne rel:F2 t1 t0
    ld NODE_content s8 t2
    add s7 t2 t3
    lbu 0 t3 t3
    li 58 t4
    bne rel:F2 t4 t3
    mv t2 a0
    mv s7 a1
    mv s6 a2
    mv s7 a3
    call streq
    beqz F2 a0
    lbu NODE_children_len s8 t0
    beqz F8 t0
    ld NODE_children s8 a0
    slli 3 t0 t0
    add t0 a0 a1
    call typerun
    bltz F8 a0
F2:
    ld NODE_children s8 a0
    lbu NODE_children_len s8 t0
    slli 3 t0 t0
    add t0 a0 a1
    mv s6 a2
    mv s7 a3
    call sefind
    bnez F9 a0
    j F1
F8:
    li 1 a0
F9:
    leave5
", 6)
. cfn('seret', "a return's value (V, of the type CC_ty) kept on the stack while all the exit actions are compiled", "
    la se_top t0
    ld 0 t0 t0
    bnez R1 t0
    ret
R1:
    enter2
    call getty
    mv a0 s4
    call pushv
    la ccs t0
    ld CC_depth t0 s5
    li 0 a0
    call seemit
    neg s5 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s4 a0
    call inmem
    mv a0 t0
    mv s4 a0
    beqz R2 t0
    li TY_LONG a0
R2:
    call load
    mv s4 a0
    call setty
    mv s4 a0
    call popv
    leave2
", 6)
. cfn('clval', "the function node of a cleanup node at a0 (a1 the end of its run): cleanup with one child; else 0", "
    enter2
    mv a0 s4
    li 0 s5
    bgeu rel:V9 a1 s4
    ld 0 s4 s4
    lbu NODE_children_len s4 t0
    li 1 t1
    bne rel:V9 t1 t0
    lbu NODE_content_len s4 a1
    li 7 t1
    bne rel:V9 t1 a1
    ld NODE_content s4 a0
    la cl_word a2
    li 7 a3
    call streq
    beqz V9 a0
    ld NODE_children s4 t0
    ld 0 t0 s5
V9:
    mv s5 a0
    leave2
", 6)
. cfn('clskip', "the run at a0 (a1 its end) past a cleanup first: a0", "
    enter1
    mv a0 s4
    call clval
    beqz K9 a0
    addi 8 s4 s4
K9:
    mv s4 a0
    leave1
", 6)
. cfn('secl', "after declaration a0: its cleanup, if it has one, pushed: a call of the function with the local's address (by an alias of its own)", "
    enter5
    mv a0 s4
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 s5
    mv s5 a1
    call alskip
    mv s5 a1
    call clval
    beqz C9 a0
    mv a0 s6
    la ccs t0
    ld CC_nvars t0 t1
    ld CC_vbase t0 t2
    beq rel:C9 t2 t1
    addi -1 t1 t1
    li VAR_sz t2
    mul t2 t1 t1
    la cc_vars t2
    add t1 t2 s7
    ld VAR_name s7 t0
    ld NODE_content s4 t1
    bne rel:C9 t1 t0
    la se_top t0
    ld 0 t0 s5
    li 255 t1
    bltu rel:C1 t1 s5
    mv s4 a0
    j bad
C1:
    la se_names t0
    slli 1 s5 t1
    add t1 t0 s8
    li 1 t1
    sb 0 t1 s8
    addi 1 s5 t1
    sb 1 t1 s8
    la ccs t0
    ld CC_nvars t0 t1
    addi 1 t1 t2
    sd CC_nvars t2 t0
    li VAR_sz t2
    mul t2 t1 t1
    la cc_vars t2
    add t1 t2 t2
    sd VAR_name s8 t2
    li 2 t1
    sd VAR_len t1 t2
    ld VAR_off s7 t1
    sd VAR_off t1 t2
    ld VAR_type s7 t1
    sd VAR_type t1 t2
    slli 8 s5 t0
    la se_nodes t1
    add t0 t1 t0
    addi NODE_size t0 t1
    addi NODE_size t1 t2
    addi NODE_size t2 t3
    ld NODE_content s6 t4
    sd NODE_content t4 t0
    lbu NODE_content_len s6 t4
    sb NODE_content_len t4 t0
    li 2 t4
    sb NODE_children_len t4 t0
    sd NODE_children t3 t0
    sd NODE_content s8 t1
    li 2 t4
    sb NODE_content_len t4 t1
    sb NODE_children_len zero t1
    la ad_word t4
    sd NODE_content t4 t2
    li 9 t4
    sb NODE_content_len t4 t2
    sb NODE_children_len zero t2
    sd 0 t1 t3
    sd 8 t2 t3
    mv t0 a0
    la ccs t4
    ld CC_cur t4 a1
    ld CC_end t4 a2
    call sepush
C9:
    leave5
", 6);
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $fns;
save();
