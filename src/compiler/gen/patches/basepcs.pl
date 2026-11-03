# basepcs.pl: base pcs (the user's choice, 2026-10-31): the first node
# under a function's name, before its type, on a definition, a declaration
# or a function type,
#
#   __fixdfdi:
#     base pcs
#     i64
#     a:
#       double
#     ...
#
# C's __attribute__ ((pcs ("aapcs"))) on arm: the function takes and
# gives its floats and doubles in core registers, r0..r3 and the stack, as
# the AAPCS's base standard has them, not in VFP registers (libgcc's
# __aeabi_d2lz ..., which gcc's hard-float code calls so). It is the
# standard arm's variadic functions follow already (abi.pl, abi3.pl), so
# on arm (targ_abi 1) isvafn is 1 for such a function too: its calls,
# through a pointer of its type too, its prologue (cc_enter_va: r0..r3
# kept beside the stack's arguments, where its parameters are read) and
# its result (r0, r0:r1) are a variadic function's. The word is skipped
# where weak is (tlskip, fnbody), and defkw, a definition's keyword, is the one
# after it (base pcs / function ... is a function type or a declaration);
# on the other targets it changes nothing. With
# basepcsdefs in ttpc.defs.ff (KW_basepcs 66, after KW_setjobs): run on
# ttpc.ff after setjobs.pl, then with T=ttpc.defs.ff. Test: progs/abi
# (arm), libgcc's _fixdfdi ... (src/glibc gccrt).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_setjobs:\n    addi\n      65\n      zero\n      a0\n",
        "  KW_setjobs:\n    addi\n      65\n      zero\n      a0\n  KW_basepcs:\n    addi\n      66\n      zero\n      a0\n", 'KW_setjobs');
    save();
    exit;
}

# the word, after set jobs
once(\$t, "      set debug\\x00set optimise\\x00set jobs\\x00\\x00\n", "      set debug\\x00set optimise\\x00set jobs\\x00base pcs\\x00\\x00\n", 'cc_kw');

# tlskip: base pcs is skipped as weak is
E('tlskip', 8, "
    li KW_weak t0
    bne rel:L9 t0 a0
", "
    li KW_weak t0
    beq rel:L1 t0 a0
    li KW_basepcs t0
    bne rel:L9 t0 a0
");

# isvafn: on arm a function of base pcs calls as a variadic one
E('isvafn', 10, "
    li KW_dots t0
    li 1 t1
    beq rel:L3 t0 a0
", "
    li KW_dots t0
    li 1 t1
    beq rel:L3 t0 a0
    li KW_basepcs t0
    bne rel:L2 t0 a0
    la targ_abi t0
    ld 0 t0 t0
    bne rel:L2 t1 t0
    li 1 a0
    j L9
");
# fnbody: the definition's type run after the word; CC_va is set as a
# variadic function's (abipplan, abipparam, abiretf read it), all its
# parameters fixed
E('fnbody', 8, "
    ld 0 s6 a0
    call ismark
", "
    ld 0 s6 a0
    call bpskip
    add a0 s6 s6
    ld 0 s6 a0
    call ismark
");
E('fnbody', 10, "
    mv s6 a0
    mv s5 a1
    mv s11 a2
    call isva
", "
    mv s6 a0
    mv s5 a1
    mv s11 a2
    call isva
    mv s4 a0
    mv s11 a1
    call bpva
");
{
    my ($from) = find(\$t, 'fnbody');
    substr($t, $from, 0) = fn('bpskip', "
    lbu NODE_children_len a0 t0
    bnez L8 t0
    enter1
    call kwof
    li KW_basepcs t0
    li 0 t1
    bne rel:L1 t0 a0
    li 8 t1
L1:
    mv t1 a0
    leave1
L8:
    li 0 a0
    ret
", 6) . fn('bpva', "
    enter2
    mv a0 s4
    mv a1 s5
    lbu NODE_children_len s4 t0
    beqz L9 t0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call bpskip
    beqz L9 a0
    call abion
    beqz L9 t0
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    bne rel:L9 t1 t0
    la ccs t0
    li 1 t1
    sd CC_va t1 t0
    sd CC_nfix s5 t0
L9:
    leave2
", 6);
}
# typerun: a function type's run, of a call through a pointer of it, after
# the word and its function (their callers skip a function alone)
E('typerun', 8, "
    mv a1 s5
    call alskip
", "
    mv a1 s5
    call bprun
    call alskip
");
{
    my ($from) = find(\$t, 'typerun');
    substr($t, $from, 0) = fn('bprun', "
    bgeu rel:L8 a1 a0
    ld 0 a0 t0
    lbu NODE_content_len t0 t1
    li 8 t2
    bne rel:L8 t2 t1
    lbu NODE_children_len t0 t1
    bnez L8 t1
    enter2
    mv a0 s4
    mv a1 s5
    mv t0 a0
    call kwof
    li KW_basepcs t0
    bne rel:L9 t0 a0
    addi 8 s4 s4
    bgeu rel:L9 s5 s4
    ld 0 s4 a0
    lbu NODE_children_len a0 t1
    bnez L9 t1
    call kwof
    li KW_function t0
    bne rel:L9 t0 a0
    addi 8 s4 s4
L9:
    mv s4 a0
    mv s5 a1
    leave2
L8:
    ret
", 6);
}
# defkw: the keyword of the node after base pcs (a declaration's or a
# function type's function), else the first node's as before
{
    my ($from, $to) = find(\$t, 'defkw');
    substr($t, $from, $to - $from) = fn('defkw', "
    enter2
    mv a0 s4
    li -1 s5
    lbu NODE_children_len s4 t1
    beqz L1 t1
    ld NODE_children s4 t1
    ld 0 t1 a0
    lbu NODE_children_len a0 t2
    bnez L1 t2
    call kwof
    li KW_basepcs t0
    bne rel:L9 t0 a0
    lbu NODE_children_len s4 t1
    li 2 t0
    bltu rel:L9 t0 t1
    ld NODE_children s4 t1
    ld 8 t1 a0
    lbu NODE_children_len a0 t2
    bnez L1 t2
    call kwof
L9:
    leave2
L1:
    mv s5 a0
    leave2
", 6);
}
save();
