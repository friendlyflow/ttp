# fixed.pl: fixed point (the user's words, 2026-11-02): ISO/IEC TR 18037's
# _Fract and _Accum, 24 spaced type words spelled as in C: short fract, fract,
# long fract, short accum, accum, long accum, each also with unsigned, sat and
# sat unsigned in front. One word is the base of a type run. Literals have C's
# suffixes after the number, as float128's Q: 0.5r, 0.5hk, -0.25ulk.
#
# A type code is an integer's of its size (1 2 4 8; bit 16 unsigned; arm's 8
# bytes a pair, 0x48 0x58) with bit 0x100 (fixed), 0x200 (accum), 0x400 (sat):
# V holds its bits as it holds such an integer's, and loads, stores, the stack
# and each ABI take it as that integer (gcc passes them so).
#
# Arithmetic, comparisons, shifts, negation and conversions call libgcc's
# fixed-bit.c, the functions gcc calls, by their names: __gnu_addqq3,
# __gnu_ssaddsa3, __gnu_cmpha2, __gnu_ssashlsq3, __gnu_negqq2,
# __gnu_fractqqhq2, __gnu_satfractsfha ... (fxbuild makes the name, fxcall the
# call with the types it is given). So saturation and rounding are gcc's. gcc
# builds those functions for arm alone here: elsewhere the types, their
# storage and ABI work, and their operations stop with ttpc's message unless
# the program defines the functions.
#
# The usual conversions are gcc's c_common_type's: sat if either is; unsigned
# if both are, or the one beside an integer is; the smallest mode of that class
# with the fractional and integer bits of both (fxcommon). A float beside one
# is the float's type. The value of a literal (fxlit) is its decimal digits'
# exact bits, cut (c2ff writes clang's exact value). ++ and -- are not there.
# At compile time: their size alone. Run on ttpc.ff after float16.pl.
# Test: progs/fixed (arm, against gcc), gccrt on arm.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }

# ---- the words: 24, six kinds, four forms
my @kinds = ('short fract', 'fract', 'long fract', 'short accum', 'accum', 'long accum');
my @words = map { my $f = $_; map { "$f$_" } @kinds } '', 'unsigned ', 'sat ', 'sat unsigned ';
my $tyi;
{
    $t =~ /^( *)cc_tynames:\n\s*ascii\n\s*(.*?)\\x00\\x00\n/m or die 'cc_tynames';
    my $list = $2;
    $tyi = 1 + (() = $list =~ /\\x00/g);
    my $r = "$list\\x00\\x00\n";
    my $w = join '\\x00', @words;
    # (a node holds 255 bytes: the words in a second ascii)
    once(\$t, $r, "$list\\x00\n    ascii\n      " . join('\\x00', @words[0 .. 11]) . "\\x00\n    ascii\n      " . join('\\x00', @words[12 .. 23]) . "\\x00\\x00\n", 'cc_tynames');
}
E('tyname', 8, "
    call lookup
    bltz L1 a0
", "
    call lookup
    bltz L1 a0
    li $tyi t0
    bge rel:LFX t0 a0
");
{
    my ($from, $to) = find(\$t, 'tyname');
    substr($t, $to, 0) = asm(8, "
LFX:
    addi -$tyi a0 a0
    li 6 t1
    li 0 t3
    mv a0 t2
    j LFXA
LFXA:
    blt rel:LFXB t1 t2
    sub t1 t2 t2
    addi 1 t3 t3
    j LFXA
LFXB:
    la fx_sizes t0
    add t2 t0 t0
    lbu 0 t0 a0
    li 256 t0
    or t0 a0 a0
    li 3 t1
    blt rel:LFX1 t1 t2
    li 512 t0
    or t0 a0 a0
    j LFX1
LFX1:
    andi 1 t3 t0
    slli 4 t0 t0
    or t0 a0 a0
    andi 2 t3 t0
    slli 9 t0 t0
    or t0 a0 a0
    li 5 t1
    bne rel:LFX2 t1 t2
    la ccs t0
    ld CC_jit t0 t0
    bnez LFX2 t0
    la targ_word t0
    ld 0 t0 t0
    li 4 t1
    bne rel:LFX2 t1 t0
    li 64 t0
    or t0 a0 a0
    j LFX2
LFX2:
    leave1
");
}

# ---- a pair by its low byte; tsize, talign; promote leaves them
E('ispair', 8, "
    li 16 t0
    or t0 a0 a0
", "
    andi 255 a0 a0
    li 16 t0
    or t0 a0 a0
");
for my $f ('tsize', 'talign') {
    E($f, 10, "
    li 16 t0
    or t0 a0 t0
    li 88 t1
", "
    andi 255 a0 t0
    li 16 t1
    or t1 t0 t0
    li 88 t1
");
}
E('promote', 8, "
    li 16 t0
    or t0 a0 t0
    li 80 t1
", "
    andi 256 a0 t0
    bnez L1 t0
    li 16 t0
    or t0 a0 t0
    li 80 t1
");

# ---- conversions: first in fcvt
E('fcvt', 8, "
    call pconvf
    bnez L9 a0
", "
    call fxcvt
    bnez L9 a0
    mv s4 a0
    mv s5 a1
    call pconvf
    bnez L9 a0
");
# ---- arithmetic: first in binop
E('binop', 8, "
    mv a2 s6
    mv s5 a0
    call isvector
", "
    mv a2 s6
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call fxbin
    bnez LFXB a0
    mv s5 a0
    call isvector
");
{
    my ($from, $to) = find(\$t, 'binop');
    substr($t, $to, 0) = asm(8, "
LFXB:
    leave5
");
}
# ---- - of one
E('unary', 10, "
    mv a0 s6
    call tscalar
    andi 32 a0 t0
    beqz L15 t0
", "
    mv a0 s6
    call fxneg
    bnez L9 a0
    mv s6 a0
    call tscalar
    andi 32 a0 t0
    beqz L15 t0
");
# ---- a literal
E('leafval', 10, "
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call hexf
", "
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call fxlit
    bnez LFXL a1
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call hexf
");
{
    my ($from, $to) = find(\$t, 'leafval');
    substr($t, $to, 0) = asm(8, "
LFXL:
    call fxli
    j L9
");
}
E('gval', 10, "
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    call hexf
", "
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    call fxlit
    bnez LFXG a1
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    call hexf
");
{
    my ($from, $to) = find(\$t, 'gval');
    substr($t, $to, 0) = asm(8, "
LFXG:
    addi 8 s4 a1
    j L9
");
}

# ---- common (an if as a value's two types): either fixed
E('common', 8, "
    mv a1 s5
    call ispair
", "
    mv a1 s5
    call fxc2
    bnez LFXC a0
    mv s4 a0
    call ispair
");
{
    my ($from, $to) = find(\$t, 'common');
    substr($t, $to, 0) = asm(8, "
LFXC:
    leave3
");
    ($from) = find(\$t, 'fcvt');
    substr($t, $from, 0) = fn('fxc2', "
    enter2
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call isfx
    mv a0 t2
    mv s5 a0
    call isfx
    or a0 t2 t2
    li 0 a0
    beqz L9 t2
    mv s4 a0
    beq rel:L9 s5 s4
    mv s5 a1
    call fxcommon
    j L9
L9:
    leave2
", 6);
}

# ---- pwassign: a pair's conversion where C makes one; fixed point's are
# written (c2ff's casts), and a declaration without a value has V's last type
E('pwassign', 8, "
    call getty
    mv a0 s5
    call ispair
", "
    call getty
    mv a0 s5
    mv s4 a1
    call fxsame
    bnez L9 a0
    mv s5 a0
    call ispair
");
{
    my ($from) = find(\$t, 'fcvt');
    substr($t, $from, 0) = fn('fxsame', "
    enter2
    mv a0 s4
    mv a1 s5
    call isfx
    mv a0 t2
    mv s5 a0
    call isfx
    or a0 t2 a0
    leave2
", 6);
}

# ---- the functions
my $msg = "ttpc: fixed point: no function of libgcc's in the program (arm has them, libgcc.ff), or no value of it at compile time:\x20";
once(\$t, "      msg_type:\n", "      msg_fx:\n        ascii\n          " . esc($msg) . "\n      msg_type:\n", 'msg_type');
my $swap = "
    la cc_exts a0
    addi 633 a0 a0
    call seq
";
{
    my ($from) = find(\$t, 'fcvt');
    substr($t, $from, 0) = fn('isfx', "
    lui TY_REC t0
    bgeu rel:L1 t0 a0
    srli 8 a0 a0
    andi 1 a0 a0
    ret
L1:
    li 0 a0
    ret
", 6) . fn('fxswap', "
    enter1
    la targ_word t0
    ld 0 t0 t0
    li 4 t1
    bne rel:L1 t1 t0
    la fxn_swapp a0
    call seq
    leave1
L1:
    la cc_exts a0
    addi 633 a0 a0
    call seq
    leave1
", 6) . fn('fxs', "
L1:
    lbu 0 a1 t0
    beqz L9 t0
    sb 0 t0 a0
    addi 1 a0 a0
    addi 1 a1 a1
    j L1
L9:
    ret
", 6) . fn('fxmode', "
    # a0 the place, a1 the type: its mode's letters; a0 past them
    andi 32 a1 t0
    bnez LF t0
    andi 15 a1 t1
    andi 256 a1 t2
    beqz L1 t2
    andi 16 a1 t2
    beqz L1 t2
    li 117 t2
    sb 0 t2 a0
    addi 1 a0 a0
    j L1
L1:
    li 113 t2
    li 1 t3
    beq rel:L2 t3 t1
    li 104 t2
    li 2 t3
    beq rel:L2 t3 t1
    li 115 t2
    li 4 t3
    beq rel:L2 t3 t1
    li 100 t2
    j L2
L2:
    sb 0 t2 a0
    li 105 t2
    andi 256 a1 t3
    beqz L3 t3
    li 113 t2
    andi 512 a1 t3
    beqz L3 t3
    li 97 t2
    j L3
L3:
    sb 1 t2 a0
    addi 2 a0 a0
    ret
LF:
    li 115 t2
    li 36 t3
    beq rel:LF1 t3 a1
    li 100 t2
    j LF1
LF1:
    sb 0 t2 a0
    li 102 t2
    sb 1 t2 a0
    addi 2 a0 a0
    ret
", 6) . fn('fxbuild', "
    # a0 the name's part, a1 and a2 types (a2 0: one), a3 a digit or 0: the
    # function __gnu_ part modes digit, its node
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    la cc_fxnm a0
    la fxs_gnu a1
    call fxs
    mv s4 a1
    call fxs
    mv s5 a1
    call fxmode
    beqz L1 s6
    mv s6 a1
    call fxmode
    j L1
L1:
    beqz L2 s7
    sb 0 s7 a0
    addi 1 a0 a0
    j L2
L2:
    sb 0 zero a0
    la cc_fxnm s8
    sub s8 a0 s4
    addi -64 sp sp
    sb NODE_children_len zero sp
    sd NODE_content s8 sp
    sb NODE_content_len s4 sp
    mv s8 a0
    mv s4 a1
    mv sp a2
    call cfind
    addi 64 sp sp
    beqz LB a0
    leave5
LB:
    la msg_fx a1
    li " . length($msg) . " a2
    mv s8 a3
    mv s4 a4
    j die_name
", 6) . fn('fxcall', "
    # the arguments on the stack: a0 the function's node, a1 its value's type,
    # a2 how many, a3 and a4 their types
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    addi -32 sp sp
    sd 0 a3 sp
    sd 8 a4 sp
    li 0 s7
    mv a3 a0
    call ispair
    or a0 s7 s7
    li 2 t0
    bne rel:L1 t0 s6
    ld 8 sp a0
    call ispair
    slli 1 a0 a0
    or a0 s7 s7
    j L1
L1:
    mv s6 a0
    mv s7 a1
    mv sp a2
    call psetargs
    addi 32 sp sp
    li 0 a0
    mv s4 a1
    li 0 a2
    li 0 a3
    li 0 a4
    mv s5 a5
    call abicall
    mv s5 a0
    andi 32 a0 t0
    bnez L9 t0
    li 4 t0
    andi 15 a0 t1
    bge rel:L8 t0 t1
    call narrow
    j L8
L8:
    j L9
L9:
    mv s5 a0
    call setty
    leave5
", 6) . fn('fxcvt', "
    # a0 from, a1 to, either fixed: V made so; 1 if it was
    enter5
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call isfx
    mv a0 s6
    mv s5 a0
    call isfx
    mv a0 s7
    or s7 s6 t0
    beqz L0 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez LB t0
    # the same bits but for sat
    li 1024 t0
    or t0 s4 t1
    or t0 s5 t2
    beq rel:L1 t2 t1
    # the name's part
    la fxs_fract s8
    beqz LFROM s7
    # to fixed
    li 1024 t0
    and t0 s5 t0
    la fxs_satfract s8
    bnez LI1 t0
    la fxs_fract s8
    j LI1
LI1:
    bnez LOK s6
    andi 32 s4 t0
    bnez LOK t0
    andi 16 s4 t0
    beqz LOK t0
    la fxs_fractuns s8
    li 1024 t0
    and t0 s5 t0
    beqz LOK t0
    la fxs_satfractuns s8
    j LOK
LFROM:
    andi 32 s5 t0
    bnez LOK t0
    andi 16 s5 t0
    beqz LOK t0
    la fxs_fractuns s8
    j LOK
LOK:
    mv s4 a0
    call pushv
    mv s8 a0
    mv s4 a1
    mv s5 a2
    li 0 a3
    and s7 s6 t0
    beqz LD t0
    xor s5 s4 t0
    andi 528 t0 t0
    bnez LD t0
    li 50 a3
    j LD
LD:
    call fxbuild
    mv s5 a1
    li 1 a2
    mv s4 a3
    li 0 a4
    call fxcall
    j L1
L1:
    li 1 a0
    leave5
L0:
    li 0 a0
    leave5
LB:
    la msg_fx a1
    li " . length($msg) . " a2
    li 0 a4
    j die_name
", 6) . fn('fxfi', "
    # a0 a type, a1 1 for its signed mode: a0 its fractional bits, a1 its
    # integer bits
    andi 15 a0 t0
    slli 3 t0 t1
    andi 16 a0 t2
    beqz L1 t2
    bnez L1 a1
    j L2
L1:
    addi -1 t1 t1
    j L2
L2:
    andi 512 a0 t2
    bnez LA t2
    mv t1 a0
    li 0 a1
    ret
LA:
    # short accum (16): 7 or 8 and 8; accum (32): 15 or 16 and 16; long accum (64): 31 or 32 and 32
    slli 2 t0 a1
    sub a1 t1 a0
    ret
", 6) . fn('fxcommon', "
    # a0 and a1 the operands' types, at least one fixed: the type gcc's
    # c_common_type gives
    enter8
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call isfx
    mv a0 s6
    mv s5 a0
    call isfx
    mv a0 s7
    # sat
    li 0 s8
    beqz LS1 s6
    li 1024 t0
    and t0 s4 t0
    or t0 s8 s8
    j LS1
LS1:
    beqz LS2 s7
    li 1024 t0
    and t0 s5 t0
    or t0 s8 s8
    j LS2
LS2:
    # unsigned
    li 0 s9
    and s7 s6 t0
    bnez LU1 t0
    # beside an integer: the fixed one's
    andi 16 s4 s9
    bnez LU0 s6
    andi 16 s5 s9
    j LU0
LU0:
    j LU2
LU1:
    andi 16 s4 t0
    andi 16 s5 t1
    and t1 t0 s9
    j LU2
LU2:
    # the bits of both
    li 0 s10
    li 0 s11
    beqz LB1 s6
    mv s4 a0
    seqz s9 a1
    call fxfi
    mv a0 s10
    mv a1 s11
    j LB1
LB1:
    beqz LB2 s7
    mv s5 a0
    seqz s9 a1
    call fxfi
    bge rel:LB11 a0 s10
    mv a0 s10
    j LB11
LB11:
    bge rel:LB2 a1 s11
    mv a1 s11
    j LB2
LB2:
    # the smallest of its class
    li 256 s4
    or s8 s4 s4
    or s9 s4 s4
    bnez LACC s11
    # fract: 1 2 4 bytes
    li 1 t2
LF1:
    li 8 t0
    mul t0 t2 t3
    bnez LF2 s9
    addi -1 t3 t3
    j LF2
LF2:
    bge rel:LF3 s10 t3
    li 4 t0
    bge rel:LF3 t0 t2
    slli 1 t2 t2
    j LF1
LF3:
    or t2 s4 a0
    leave8
LACC:
    # accum: 2 4 8 bytes
    li 512 t0
    or t0 s4 s4
    li 2 t2
LA1:
    li 4 t0
    mul t0 t2 t3
    mv t3 t4
    bnez LA11 s9
    addi -1 t4 t4
    j LA11
LA11:
    blt rel:LA12 s11 t3
    bge rel:LA2 s10 t4
    j LA12
LA12:
    li 8 t0
    bge rel:LA2 t0 t2
    slli 1 t2 t2
    j LA1
LA2:
    li 8 t0
    bne rel:LA3 t0 t2
    la targ_word t0
    ld 0 t0 t0
    li 4 t1
    bne rel:LA3 t1 t0
    li 64 t0
    or t0 t2 t2
    j LA3
LA3:
    or t2 s4 a0
    leave8
", 6) . fn('fxbin', "
    # a0 the operator, L and V of the types a1, a2: 1 if one is fixed, done
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s5 a0
    call isfx
    mv a0 s7
    mv s6 a0
    call isfx
    or a0 s7 s7
    beqz L0 s7
    la ccs t0
    ld CC_jit t0 t0
    bnez LB t0
    # the type of both
    li OP_shl t0
    mv s5 s8
    beq rel:LT t0 s4
    li OP_shr t0
    beq rel:LT t0 s4
    li 40 s8
    beq rel:LT s8 s5
    beq rel:LT s8 s6
    li 36 s8
    beq rel:LT s8 s5
    beq rel:LT s8 s6
    mv s5 a0
    mv s6 a1
    call fxcommon
    mv a0 s8
    j LT
LT:
    li OP_shl t0
    beq rel:LSH t0 s4
    li OP_shr t0
    beq rel:LSH t0 s4
    # both to it: L first, with V on the stack
    beq rel:L2 s8 s5
    mv s6 a0
    call pushv
    call fxswap
    mv s5 a0
    mv s8 a1
    call fcvt
    mv s6 a0
    call popv
    call fxswap
    j L2
L2:
    beq rel:L3 s8 s6
    call fxswap
    mv s8 a0
    call pushv
    call fxswap
    mv s6 a0
    mv s8 a1
    call fcvt
    mv s8 a0
    call popv
    j L3
L3:
    mv s8 a0
    call isfx
    bnez L4 a0
    # a float's
    mv s4 a0
    mv s8 a1
    mv s8 a2
    call binop
    li 1 a0
    leave8
L4:
    call fxswap
    mv s8 a0
    call pushv
    call fxswap
    mv s8 a0
    call pushv
    # the name's part
    li 1024 t0
    and t0 s8 s9
    andi 16 s8 s11
    li OP_add t0
    la fxs_add a0
    beq rel:LNA t0 s4
    li OP_sub t0
    la fxs_sub a0
    beq rel:LNA t0 s4
    li 18 t0
    la fxs_mul a0
    beq rel:LNA t0 s4
    li 19 t0
    la fxs_div a0
    beq rel:LND t0 s4
    li OP_eq t0
    blt rel:LBAD t0 s4
    li OP_ge t0
    bgt LBAD t0 s4
    # compare: 0 1 2
    la fxs_cmp a0
    mv s8 a1
    li 0 a2
    li 50 a3
    call fxbuild
    li TY_INT a1
    li 2 a2
    mv s8 a3
    mv s8 a4
    call fxcall
    li OP_eq t0
    sub t0 s4 t0
    slli 3 t0 t0
    la fx_cmps a0
    add t0 a0 t1
    lbu 0 t1 a0
    lbu 1 t1 t2
    li 50 t0
    mul t0 t2 t2
    la cc_opseq a1
    add t2 a1 a1
    call opk
    li TY_INT a0
    call setty
    li 1 a0
    leave8
LND:
    bnez LNA s9
    beqz LNA s11
    la fxs_udiv a0
    j LNA
LNA:
    # (with sat, ss or us in front)
    beqz LN s9
    mv a0 a1
    la cc_fxpt a0
    li 115 t0
    bnez LNA1 s11
    sb 0 t0 a0
    j LNA2
LNA1:
    li 117 t2
    sb 0 t2 a0
    j LNA2
LNA2:
    sb 1 t0 a0
    addi 2 a0 a0
    # (the op's own, without an u)
    call fxs
    sb 0 zero a0
    la cc_fxpt a0
    j LN
LN:
    li 51 a3
    mv s8 a1
    li 0 a2
    call fxbuild
    mv s8 a1
    li 2 a2
    mv s8 a3
    mv s8 a4
    call fxcall
    li 1 a0
    leave8
LSH:
    mv s5 s8
    call fxswap
    mv s8 a0
    call pushv
    call fxswap
    mv s6 a0
    li TY_INT a1
    call fcvt
    li TY_INT a0
    call pushv
    li 1024 t0
    and t0 s8 s9
    andi 16 s8 s11
    li OP_shl t0
    la fxs_ashl a0
    bne rel:LSH1 t0 s4
    # << with sat
    beqz LSHN s9
    la fxs_ssashl a0
    beqz LSHN s11
    la fxs_usashl a0
    j LSHN
LSH1:
    la fxs_ashr a0
    beqz LSHN s11
    la fxs_lshr a0
    j LSHN
LSHN:
    mv s8 a1
    li 0 a2
    li 51 a3
    call fxbuild
    mv s8 a1
    li 2 a2
    mv s8 a3
    li TY_INT a4
    call fxcall
    li 1 a0
    leave8
L0:
    li 0 a0
    leave8
LBAD:
    li 0 a0
    call bad
LB:
    la msg_fx a1
    li " . length($msg) . " a2
    li 0 a4
    j die_name
", 6) . fn('fxneg', "
    # - of the type a0 in V: 1 if it is fixed, done
    enter3
    mv a0 s4
    call isfx
    beqz L0 a0
    mv s4 a0
    call pushv
    li 1024 t0
    and t0 s4 s5
    andi 16 s4 s6
    la fxs_neg a0
    beqz L1 s5
    la fxs_ssneg a0
    beqz L1 s6
    la fxs_usneg a0
    j L1
L1:
    mv s4 a1
    li 0 a2
    li 50 a3
    call fxbuild
    mv s4 a1
    li 1 a2
    mv s4 a3
    li 0 a4
    call fxcall
    li 1 a0
    leave3
L0:
    li 0 a0
    leave3
", 6) . fn('fxlit', "
    # a0 a node's text, a1 its length: a1 1 and a0 its bits if it is a fixed
    # point literal (fx_ty its type)
    enter8
    mv a0 s4
    add a0 a1 s5
    li 2 t0
    blt rel:LN t0 a1
    # the first character a digit, or - and a digit
    lbu 0 s4 t0
    li 0 s9
    li 45 t1
    bne rel:L1 t1 t0
    li 1 s9
    addi 1 s4 s4
    lbu 0 s4 t0
    j L1
L1:
    addi -48 t0 t0
    li 10 t1
    bgeu rel:LN t1 t0
    # the suffix: [u] [h|l] (r|k), either case
    lbu -1 s5 t0
    li 32 t1
    or t1 t0 t0
    li 0 s6
    li 114 t1
    beq rel:L2 t1 t0
    li 512 s6
    li 107 t1
    bne rel:LN t1 t0
    j L2
L2:
    addi -1 s5 s5
    li 2 s7
    lbu -1 s5 t0
    li 32 t1
    or t1 t0 t0
    li 104 t1
    bne rel:L21 t1 t0
    li 1 s7
    addi -1 s5 s5
    j L3
L21:
    li 108 t1
    bne rel:L3 t1 t0
    li 4 s7
    addi -1 s5 s5
    j L3
L3:
    li 0 s8
    lbu -1 s5 t0
    li 32 t1
    or t1 t0 t0
    li 117 t1
    bne rel:L4 t1 t0
    li 16 s8
    addi -1 s5 s5
    j L4
L4:
    # an accum's size is twice a fract's of its suffix
    beqz L41 s6
    slli 1 s7 s7
    j L41
L41:
    # the digits: the whole part
    li 0 s10
L5:
    bgeu rel:L6 s5 s4
    lbu 0 s4 t0
    li 46 t1
    beq rel:L6 t1 t0
    addi -48 t0 t0
    li 10 t1
    bgeu rel:LN t1 t0
    mul t1 s10 s10
    add t0 s10 s10
    addi 1 s4 s4
    j L5
L6:
    # its fractional bits
    li 256 a0
    or s6 a0 a0
    or s8 a0 a0
    or s7 a0 a0
    la fx_ty t0
    sd 0 a0 t0
    li 0 a1
    call fxfi
    mv a0 s11
    # the digits after the point, doubled for each bit
    la cc_fxnm t3
    li 0 t4
    bgeu rel:L7 s5 s4
    addi 1 s4 s4
    j L61
L61:
    bgeu rel:L7 s5 s4
    lbu 0 s4 t0
    addi -48 t0 t0
    li 10 t1
    bgeu rel:LN t1 t0
    add t4 t3 t1
    sb 0 t0 t1
    addi 1 t4 t4
    addi 1 s4 s4
    li 62 t1
    blt rel:L61 t1 t4
    j L7
L7:
    # s10 the value so far; t4 digits at t3
    li 0 t5
L8:
    bge rel:L9 s11 t5
    slli 1 s10 s10
    li 0 t0
    addi 0 t4 t1
L81:
    beqz L82 t1
    addi -1 t1 t1
    add t1 t3 t2
    lbu 0 t2 a0
    slli 1 a0 a0
    add t0 a0 a0
    li 0 t0
    li 10 a1
    blt rel:L83 a1 a0
    addi -10 a0 a0
    li 1 t0
    j L83
L83:
    sb 0 a0 t2
    j L81
L82:
    add t0 s10 s10
    addi 1 t5 t5
    j L8
L9:
    mv s10 a0
    beqz L91 s9
    neg a0 a0
    j L91
L91:
    # arm's 8 bytes: a pair
    la fx_ty t0
    ld 0 t0 t1
    li 8 t2
    bne rel:L92 t2 s7
    la targ_word t2
    ld 0 t2 t2
    li 4 t3
    bne rel:L92 t3 t2
    li 64 t2
    or t2 t1 t1
    sd 0 t1 t0
    j L92
L92:
    li 1 a1
    leave8
LN:
    li 0 a1
    leave8
", 6) . fn('fxli', "
    # V the bits a0 of the literal fx_ty, its type V's
    enter1
    mv a0 s4
    la fx_ty t0
    ld 0 t0 a0
    call ispair
    beqz L1 a0
    la cc_lip a0
    li 2 a1
    slli 32 s4 a2
    srli 32 a2 a2
    srli 32 s4 a3
    li 0 a5
    call prim
    j L2
L1:
    mv s4 a0
    li R_a0 a1
    call li
    j L2
L2:
    la fx_ty t0
    ld 0 t0 a0
    call setty
    leave1
", 6);
}

# ---- the data: the name's room, the parts of names, the compares (the
# value that __gnu_cmp* gives is compared with: value, operator)
{
    my $h = '';
    my %s = (fxs_gnu => '__gnu_', fxs_fract => 'fract', fxs_satfract => 'satfract', fxs_fractuns => 'fractuns', fxs_satfractuns => 'satfractuns',
        fxs_add => 'add', fxs_sub => 'sub', fxs_mul => 'mul', fxs_div => 'div', fxs_udiv => 'udiv', fxs_cmp => 'cmp', fxs_ashl => 'ashl', fxs_ashr => 'ashr',
        fxs_lshr => 'lshr', fxs_ssashl => 'ssashl', fxs_usashl => 'usashl', fxs_neg => 'neg', fxs_ssneg => 'ssneg', fxs_usneg => 'usneg');
    for my $l (sort keys %s) {
        my $b = "$s{$l}\0";
        $b .= "\0" x (-length($b) % 8);
        $h .= "      $l:\n        ascii\n          " . esc($b) . "\n";
    }
    $h .= "      fx_sizes:\n        ascii\n          " . esc("\x01\x02\x04\x02\x04\x08\0\0") . "\n";
    # (==, !=, <, >, <=, >= of 0 less, 1 equal, 2 greater)
    $h .= "      fx_cmps:\n        ascii\n          " . esc(join '', map { chr($_->[0]) . chr($_->[1]) . "\0" x 6 } [1, 8], [1, 9], [1, 10], [1, 11], [2, 10], [0, 11]) . "\n";
    my $b = "\0cc_swap_p\0"; $b .= "\0" x (-length($b) % 8);
    $h .= "      fxn_swapp:\n        ascii\n          " . esc($b) . "\n";
    $h .= "      fx_ty:\n        dword\n          0\n";
    $h .= "      cc_fxpt:\n        reserve\n          32\n      cc_fxnm:\n        reserve\n          64\n";
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}

save();
