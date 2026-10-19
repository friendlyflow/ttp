# pairs.pl: i64 and u64 on arm, in a pair of registers (the user's choice,
# 2026-10-19, over keeping them in memory as arm's double is). On a target
# whose word is 4 bytes (arm) and outside compile time, i64 and u64 get
# type codes of their own, 0x48 and 0x58 (the pair bit 0x40 with an 8-byte
# size), 8 bytes aligned to 8 as the AAPCS lays them out; long stays the
# word. V is the pair r0:r1 (low word first), L r12:r9; the primitives are
# arm's cc_*_p (macros/arm.ff.txt). Elsewhere i64 is long, and nothing here
# changes what ttpc makes for riscv64, x86_64 or aarch64.
#
# This step: the type (tyname, tsize, talign), C's usual conversions with
# pairs (common, also for an if as a value) and the widening of the other
# operand (pwiden), the pair forms of the operators that have them now (+
# - & | ^ and the compares, by the table cc_opseqp), - ~ ! ++ --, loads
# and stores (paccess), a pair on the stack between the operands of an
# operator (pushv, popv), the truth of a pair in a condition (jzv, jnzv,
# boolv), literals that do not fit 32 bits (numlit), and the conversions
# to and from a pair where C makes them: a cast and an if's value (fcvt),
# =, a declaration's value, an initializer's item and return (pwassign).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# the type: i64 and u64 where the word is 4 bytes
E('cc/tyname', 10, "
    la msg_word a1
    li msg_word_len a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
", "
    addi -7 a0 a0
    slli 2 a0 a0
    addi 72 a0 a0
    leave1
");
for my $f ('cc/tsize', 'cc/talign') {
    E($f, 10, "
        andi 32 a0 t0
        bnez L2 t0
        andi 15 a0 a0
    ", "
        andi 64 a0 t0
        bnez L2 t0
        andi 32 a0 t0
        bnez L2 t0
        andi 15 a0 a0
    ");
}

# binop: the type of both operands by common, the other operand widened to
# a pair, the pair's operator
edit(\$t, 'cc/binop', asm(10, "
    mv s6 a0
    call promote
    mv a0 s8
    li 0 t1
    andi 8 s7 t0
    beqz L12 t0
    andi 16 s7 t1
") . asm(8, "
    L12:
    andi 8 s8 t0
    beqz L13 t0
    andi 16 s8 t0
    or t0 t1 t1
    L13:
    or s8 s7 t0
    andi 8 t0 t2
    beqz L14 t2
    li TY_LONG s8
    or t1 s8 s8
    j L15
    L14:
    andi 16 t0 t0
    li TY_INT s8
    or t0 s8 s8
") => asm(10, "
    mv s6 a0
    call promote
    mv a0 s8
    mv s7 a0
    mv s8 a1
    call common
    mv a0 s8
"));
E('cc/binop', 8, "
    L15:
    li TY_U32 t0
", "
    L15:
    mv s7 a0
    mv s6 a1
    mv s8 a2
    call pwiden
    li TY_U32 t0
");
E('cc/binop', 8, "
    L16:
    la cc_opseq a0
", "
    L16:
    mv s8 a0
    call opseq
");

# an if as a value: its type by common
E('cc/if', 8, "
    CT3:
    mv s4 a0
    call promote
    mv a0 s4
    mv s5 a0
    call promote
    mv a0 s5
    li 0 t1
    andi 8 s4 t0
    beqz CT4 t0
    andi 16 s4 t1
    CT4:
    andi 8 s5 t0
    beqz CT5 t0
    andi 16 s5 t0
    or t0 t1 t1
    CT5:
    or s5 s4 t0
    andi 8 t0 t2
    beqz CT6 t2
    li TY_LONG a0
    or t1 a0 a0
    leave3
    CT6:
    andi 16 t0 t0
    li TY_INT a0
    or t0 a0 a0
    leave3
", "
    CT3:
    mv s4 a0
    call promote
    mv a0 s4
    mv s5 a0
    call promote
    mv a0 a1
    mv s4 a0
    call common
    leave3
");

# loads and stores of a pair, and narrow to one (nothing)
E('cc/access', 8, "
    mv a0 s4
    call fwide
", "
    mv a0 s4
    mv s5 a1
    call paccess
    bnez L9 a0
    mv s4 a0
    call fwide
");

# conversions to and from a pair: a cast, an if's value (fcvt), =, a
# declaration's value, an initializer's item, return (pwassign)
E('cc/fcvt', 8, "
    beq rel:L9 s5 s4
    mv s4 a0
    call fwide
", "
    beq rel:L9 s5 s4
    mv s4 a0
    mv s5 a1
    call pconvf
    bnez L9 a0
    mv s4 a0
    call fwide
");
E('cc/expr', 8, "
    L3:
    mv s7 a0
    call wassign
    call popt0
", "
    L3:
    mv s7 a0
    call wassign
    mv s7 a0
    call pwassign
    call popt0
");
E('cc/decl', 8, "
    L5:
    li 0 a0
    li R_a0 a1
    call li
    L8:
    mv s4 a0
    mv s7 a1
    call declare
", "
    L5:
    li 0 a0
    li R_a0 a1
    call li
    li TY_INT a0
    call setty
    L8:
    mv s7 a0
    call pwassign
    mv s4 a0
    mv s7 a1
    call declare
");
E('cc/linit', 8, "
    L4:
    li 1 a0
    call expr
    sub s5 s8 a0
", "
    L4:
    li 1 a0
    call expr
    mv s7 a0
    call pwassign
    sub s5 s8 a0
");
E('cc/retval', 8, "
    enter2
    la ccs t0
    ld CC_rty t0 s4
", "
    enter2
    la ccs t0
    ld CC_rty t0 s4
    mv s4 a0
    call pwassign
");

# a pair on the stack: an operator's left operand, a compound assignment's
# old value
E('cc/expr', 8, "
    L6:
    li OP_and t0
    beq rel:L7 t0 s5
    li OP_or t0
    beq rel:L7 t0 s5
    call getty
    mv a0 s7
    call push
    addi 1 s6 a0
    call expr
    call getty
    mv a0 s8
    call popt0
", "
    L6:
    li OP_and t0
    beq rel:L7 t0 s5
    li OP_or t0
    beq rel:L7 t0 s5
    call getty
    mv a0 s7
    mv s7 a0
    call pushv
    addi 1 s6 a0
    call expr
    call getty
    mv a0 s8
    mv s7 a0
    call popv
");
E('cc/expr', 8, "
    mv s7 a0
    call load
    call push
    L2:
    li 1 a0
    call expr
    beqz L3 s5
    call getty
    mv a0 s8
    call popt0
", "
    mv s7 a0
    call load
    mv s7 a0
    call pushv
    L2:
    li 1 a0
    call expr
    beqz L3 s5
    call getty
    mv a0 s8
    mv s7 a0
    call popv
");

# the truth of a pair: && || (to an int first), if, ?:, while, for, do while
E('cc/expr', 8, "
    L7:
    la cc_bool a0
    call seq
", "
    L7:
    call boolv
");
E('cc/expr', 8, "
    L10:
    addi 1 s6 a0
    call expr
    la cc_bool a0
    call seq
", "
    L10:
    addi 1 s6 a0
    call expr
    call boolv
");
E('cc/if', 8, "
    li 1 a0
    call expr
    call newlabel
    mv a0 s7
    call jz
", "
    li 1 a0
    call expr
    call newlabel
    mv a0 s7
    call jzv
");
E('cc/if', 10, "
    call newlabel
    mv a0 s7
    call jz
    li 1 a0
", "
    call newlabel
    mv a0 s7
    call jzv
    li 1 a0
");
E('cc/if', 10, "
    mv a0 s11
    la cc_beqz8 t0
    call jcond
", "
    mv a0 s11
    call jnzv
");
E('cc/while', 8, "
    call expr
    mv s8 a0
    call jz
", "
    call expr
    mv s8 a0
    call jzv
");
E('cc/forloop', 10, "
    ld CC_brk t0 a0
    call jz
", "
    ld CC_brk t0 a0
    call jzv
");
E('cc/dowhile', 8, "
    call expr
    mv s8 a0
    call jz
", "
    call expr
    mv s8 a0
    call jzv
");

# - ~ ! of a pair, ++ and -- of one
E('cc/unary', 8, "
    L3:
    call seq
    li TY_INT a0
", "
    L3:
    call unseq
    li TY_INT a0
");
E('cc/unary', 10, "
    call li
    la cc_add_t1 a0
    call seq
    call popt0
", "
    call li
    mv s6 a0
    call addxv
    call popt0
");
E('cc/unary', 10, "
    neg s4 a0
    li R_t1 a1
    call li
    la cc_add_t1 a0
    call seq
", "
    neg s4 a0
    li R_t1 a1
    call li
    mv s6 a0
    call addxv
");

# a number: numlit, a pair where it does not fit 32 bits on arm
E('cc/leafval', 8, "
    mv a0 s5
    li R_a0 a1
    call li
    li TY_INT a0
    slli 32 s5 t0
    srai 32 t0 t0
    beq rel:L8 t0 s5
    li TY_LONG a0
    lbu NODE_content_len s4 t1
    li 2 t2
    blt rel:L8 t2 t1
    ld NODE_content s4 t1
    lbu 1 t1 t1
    li 120 t2
    bne rel:L8 t2 t1
    srli 32 s5 t0
    li TY_U32 a0
    beqz L8 t0
    li TY_LONG a0
    bgez L8 s5
    li TY_U64 a0
    j L8
", "
    mv a0 s5
    mv s4 a1
    call numlit
    j L8
");

# the helpers, a layer of cc of their own
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
sub ascii {   # a data label: its bytes in ascii nodes of at most 250
    my ($name, $bytes) = @_;
    $bytes .= "\0" x (-length($bytes) % 8);   # the code after it stays aligned
    my $s = "      $name:\n";
    $s .= "        ascii\n          " . esc(substr($bytes, $_ * 250, 250)) . "\n" for 0 .. (length($bytes) - 1) / 250;
    $s;
}
my %ops = (5 => ['or'], 6 => ['xor'], 7 => ['and'], 8 => ['eq'], 9 => ['ne'], 10 => ['lt', 'ltu'],
           11 => ['gt', 'gtu'], 12 => ['le', 'leu'], 13 => ['ge', 'geu'], 14 => ['shl'], 15 => ['sar', 'shr'],
           16 => ['add'], 17 => ['sub'], 18 => ['mul'], 19 => ['div', 'divu'], 20 => ['rem', 'remu']);
my $opseqp = '';
for my $op (0 .. 20) {
    for my $u (0, 1) {
        my $n = $ops{$op} ? "cc_" . ($ops{$op}[$u] // $ops{$op}[0]) . "_p" : '';
        $opseqp .= $n eq '' ? "\0" x 25 : pack('a25', "\0$n");
    }
}
my $helpers = "    3:\n      comment\n        i64 and u64 on arm, a pair of registers (gen/patches/pairs.pl): ispair, common, pwiden, pext, pconvf, opseq, paccess, pushv, popv, jzv, jnzv, boolv, unseq, addxv, pwassign, numlit.\n";
$helpers .= fn('ispair', "
    lui TY_REC t0
    bgeu rel:L1 t0 a0
    andi 64 a0 a0
    srli 6 a0 a0
    ret
    L1:
    li 0 a0
    ret
", 6);
$helpers .= fn('common', "
    enter3
    mv a0 s4
    mv a1 s5
    call ispair
    mv a0 s6
    mv s5 a0
    call ispair
    or a0 s6 s6
    li 0 t1
    andi 8 s4 t0
    beqz L12 t0
    andi 16 s4 t1
    L12:
    andi 8 s5 t0
    beqz L13 t0
    andi 16 s5 t0
    or t0 t1 t1
    L13:
    or s5 s4 t0
    bnez L20 s6
    andi 8 t0 t2
    beqz L14 t2
    li TY_LONG a0
    or t1 a0 a0
    bnez L9 t1
    la targ_word t2
    ld 0 t2 t2
    li 4 t3
    bne rel:L9 t3 t2
    la ccs t2
    ld CC_jit t2 t2
    bnez L9 t2
    andi 16 t0 t0
    beqz L9 t0
    li TY_U32 a0
    L9:
    leave3
    L14:
    andi 16 t0 t0
    li TY_INT a0
    or t0 a0 a0
    leave3
    L20:
    li 72 a0
    or t1 a0 a0
    leave3
", 6);
$helpers .= fn('pwiden', "
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s6 a0
    call ispair
    beqz L9 a0
    mv s4 a0
    call ispair
    bnez L1 a0
    mv s4 a0
    li 1 a1
    call pext
    L1:
    mv s5 a0
    call promote
    mv a0 s4
    call ispair
    bnez L9 a0
    mv s4 a0
    li 0 a1
    call pext
    L9:
    leave3
", 6);
$helpers .= fn('pext', "
    enter1
    mv a1 s4
    call tscalar
    andi 32 a0 t0
    bnez L8 t0
    andi 16 a0 t0
    srli 4 t0 t0
    slli 1 s4 t1
    add t1 t0 t0
    slli 4 t0 t0
    la cc_pexts a0
    add t0 a0 a0
    call seq
    leave1
    L8:
    li 0 a0
    call bad
", 6);
$helpers .= fn('pconvf', "
    enter3
    mv a0 s4
    mv a1 s5
    call ispair
    mv a0 s6
    mv s5 a0
    call ispair
    bnez L1 a0
    li 0 a0
    beqz L9 s6
    mv s5 a0
    call tscalar
    andi 32 a0 t0
    bnez L8 t0
    li 1 a0
    j L9
    L1:
    li 1 a0
    bnez L9 s6
    mv s4 a0
    li 0 a1
    call pext
    li 1 a0
    L9:
    leave3
    L8:
    li 0 a0
    call bad
", 6);
$helpers .= fn('opseq', "
    la cc_opseq t1
    lui TY_REC t2
    bgeu rel:L1 t2 a0
    andi 64 a0 t2
    beqz L1 t2
    la cc_opseqp t1
    L1:
    mv t1 a0
    ret
", 6);
$helpers .= fn('paccess', "
    enter2
    mv a1 s5
    call ispair
    beqz L9 a0
    la cc_loadp a0
    la cc_loads t0
    beq rel:L1 t0 s5
    la cc_storep a0
    la cc_stores t0
    beq rel:L1 t0 s5
    li 1 a0
    j L9
    L1:
    call seq
    li 1 a0
    L9:
    leave2
", 6);
for my $x (['pushv', 'cc_pushp', 2, 'push'], ['popv', 'cc_popp', -2, 'popt0']) {
    my ($name, $entry, $n, $word) = @$x;
    $helpers .= fn($name, "
        enter1
        call ispair
        beqz L1 a0
        la $entry a0
        li $n t1
        call pushpop
        leave1
        L1:
        call $word
        leave1
    ", 6);
}
for my $x (['jzv', 'cc_bnez8', 'cc_jzp'], ['jnzv', 'cc_beqz8', 'cc_jnzp']) {
    my ($name, $word, $pair) = @$x;
    $helpers .= fn($name, "
        enter2
        mv a0 s4
        call getty
        call ispair
        mv a0 s5
        mv s4 a0
        la $word t0
        beqz L1 s5
        la $pair t0
        L1:
        call jcond
        leave2
    ", 6);
}
$helpers .= fn('boolv', "
    enter1
    call getty
    call ispair
    mv a0 s4
    la cc_bool a0
    beqz L1 s4
    la cc_boolp a0
    L1:
    call seq
    leave1
", 6);
$helpers .= fn('unseq', "
    enter2
    mv a0 s4
    call getty
    call ispair
    beqz L9 a0
    la cc_negp s5
    la cc_neg t0
    beq rel:L1 t0 s4
    la cc_notp s5
    la cc_not t0
    beq rel:L1 t0 s4
    la cc_invp s5
    L1:
    mv s5 s4
    L9:
    mv s4 a0
    call seq
    leave2
", 6);
$helpers .= fn('addxv', "
    enter1
    call ispair
    mv a0 s4
    la cc_add_t1 a0
    beqz L1 s4
    la cc_addxp a0
    L1:
    call seq
    leave1
", 6);
$helpers .= fn('pwassign', "
    enter2
    mv a0 s4
    call getty
    mv a0 s5
    call ispair
    bnez L1 a0
    mv s4 a0
    call ispair
    beqz L9 a0
    L1:
    mv s5 a0
    mv s4 a1
    call fcvt
    L9:
    leave2
", 6);
$helpers .= fn('numlit', "
    enter3
    mv a0 s5
    mv a1 s4
    li TY_INT s6
    slli 32 s5 t0
    srai 32 t0 t0
    beq rel:L8 t0 s5
    li TY_LONG s6
    lbu NODE_content_len s4 t1
    li 2 t2
    blt rel:L8 t2 t1
    ld NODE_content s4 t1
    lbu 1 t1 t1
    li 120 t2
    bne rel:L8 t2 t1
    srli 32 s5 t0
    li TY_U32 s6
    beqz L8 t0
    li TY_LONG s6
    bgez L8 s5
    li TY_U64 s6
    L8:
    andi 8 s6 t0
    beqz L1 t0
    la targ_word t0
    ld 0 t0 t0
    li 4 t1
    bne rel:L1 t1 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez L1 t0
    li 64 t0
    or t0 s6 s6
    la cc_lip a0
    li 2 a1
    slli 32 s5 a2
    srli 32 a2 a2
    srli 32 s5 a3
    li 0 a5
    call prim
    j L9
    L1:
    mv s5 a0
    li R_a0 a1
    call li
    L9:
    mv s6 a0
    leave3
", 6);
$helpers .= ascii('cc_opseqp', $opseqp);
$helpers .= ascii('cc_pexts', join '', map { pack 'a16', "\0$_" } qw(cc_ext_p cc_ext_pu cc_ext_lp cc_ext_lpu));
$helpers .= ascii($_->[0], $_->[1]) for
    ['cc_pushp', "\0cc_push_p\0"], ['cc_popp', "\0cc_pop_p\0"], ['cc_loadp', "\0cc_load_p\0"],
    ['cc_storep', "\0cc_store_p\0"], ['cc_jzp', "\x01cc_jz_p\0"], ['cc_jnzp', "\x01cc_jnz_p\0"],
    ['cc_boolp', "\0cc_bool_p\0"], ['cc_notp', "\0cc_not_p\0"], ['cc_negp', "\0cc_neg_p\0"],
    ['cc_invp', "\0cc_inv_p\0"], ['cc_addxp', "\0cc_addx_p\0"], ['cc_lip', "cc_li_p\0"];
{
    my ($from, $to) = find(\$t, 'cc');
    substr($t, $to, 0) = $helpers;
}
save();
