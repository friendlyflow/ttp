# x87.pl: x86_64's long double is the x87's 80-bit extended format, as
# gcc's default has it (the user's choice, 2026-10-28), and float128 is
# binary128 (the user's choice, 2026-10-30: C's _Float128 and __float128).
#
# A type of its own, 112 (48, binary128's code, with bit 64): on x86_64
# (not at compile time) tyname gives it to long double; float128 is 48,
# binary128 as long double was (and is on the other targets, where float128
# is long double). 112 is a floating type of 16 bytes, so fwide, tsize and
# talign take it as they took 48: a value of it is in memory, its address
# in V. Its arithmetic, comparisons, negation and conversions are the
# primitives arm's double in memory has (cc_fadd_dm ... cc_cvt_s_dm), which
# x86_64 has with x87 instructions (macros/x86_64.ff.txt), and three of
# x86_64's own: cc_cvt_dm_d and cc_cvt_d_dm (to and from double, a narrow
# type on x86_64), cc_cvt_q_dm (to float128, exact). float128 to long
# double calls soft-fp's __trunctfxf2 (cc_sfnames 26).
#
# Its literal: an exact hex float with L after it, read as binary128's
# (ldlit.pl's hexf), rounded to nearest even to the x87's 64 bits of
# significand: cc_ldhi's high word the sign and exponent (16 bits), the low
# word the significand with its integer bit. One with Q after it is
# binary128's on every target, type 48 (float128). gval works out a negated
# long double literal (the sign, bit 15 of the high word) and the cast of
# an int (exact) in the x87's format, as ldneg.pl does binary128's.
#
# The SysV ABI's X87 class: a long double argument goes on the stack (16
# bytes, 16-aligned), a struct with one in memory; a result comes back in
# st0 (x64resclass's class 9: cc_x64_rstt stores it, cc_x64_rett loads it);
# va_arg takes it from the stack. Run on ttpc.ff after abix64.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }
my $isx64 = "
    la targ_abi t0
    ld 0 t0 t0
    addi -3 t0 t0
    seqz t0 t0
    la ccs t1
    ld CC_jit t1 t1
    seqz t1 t1
    and t1 t0 t0
";
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }

# ---- the type: long double 112 on x86_64, float128 48 (cc_tynames 21)
once(\$t, "complex long double\\x00\\x00\n", "complex long double\\x00float128\\x00\\x00\n", 'cc_tynames');
E('tyname', 8, "
    call lookup
    bltz L1 a0
", "
    call lookup
    bltz L1 a0
    li 21 t0
    beq rel:LQ t0 a0
");
E('tyname', 8, "
LD:
    la ccs t0
    ld CC_jit t0 t0
    bnez L3 t0
", "
LD:
    la ccs t0
    ld CC_jit t0 t0
    bnez L3 t0
    la targ_abi t0
    ld 0 t0 t0
    li 3 t1
    bne rel:LD1 t1 t0
    li 112 a0
    leave1
LD1:
");
{
    my ($from, $to) = find(\$t, 'tyname');
    substr($t, $to, 0) = asm(8, "
LQ:
    li TY_LDOUBLE a0
    leave1
");
}

# ---- cc_sfnames: 25 float128 (the type's word, for wgate), 26 __trunctfxf2;
# a64sfargs: their kinds (26: a float128 in an xmm register)
once(\$t, "double\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\n  str_index:\n",
    "double\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\n    ascii\n      " . esc("float128" . "\0" x 8 . "__trunctfxf2" . "\0" x 4) . "\n  str_index:\n", 'cc_sfnames');
# (56 bytes, as 48 were: the code after it stays 4-aligned, as aarch64's must)
once(\$t, "\\x05\\x00\\x05\\x00\\x00\\x00\n      a64n_x8:\n",
    "\\x05\\x00\\x05\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x05\\x00\\x00\\x00\n      a64n_x8:\n", 'a64sfargs');

# ---- wgate: a function naming float128, or with a Q literal, gets the
# temporaries too
E('wgate', 8, "
    call streq
    bnez L8 a0
    call slot
", "
    call streq
    bnez L8 a0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    la cc_sfnames a2
    li32 400 t0
    add t0 a2 a2
    li 8 a3
    call streq
    bnez L8 a0
    call slot
");
E('wgate', 10, "
    lbu -1 t4 t4
    li 76 t0
    bne rel:LY t0 t4
", "
    lbu -1 t4 t4
    addi -81 t4 t5
    seqz t5 t5
    li 5 t0
    mul t0 t5 t5
    sub t5 t4 t4
    li 76 t0
    bne rel:LY t0 t4
");

# ---- hexf: Q after the hex float is binary128's (float128) on every
# target; L on x86_64 the x87's, binary128's bits rounded to nearest even
E('hexf', 8, "
    lbu -1 s5 t0
    li 76 t1
    beq rel:LL t1 t0
", "
    lbu -1 s5 t0
    li 76 t1
    beq rel:LL t1 t0
    li 81 t1
    beq rel:LL t1 t0
");
E('hexf', 8, "
LW:
    la ccs t0
    ld CC_jit t0 t0
    bnez LX t0
", "
LW:
    lbu 0 s5 t0
    li 81 t1
    beq rel:LX t1 t0
$isx64
    bnez LX87 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez LX t0
");
{
    # s6 the high word (the exponent, the fraction's top 48 bits), s7 the
    # low one: t0 the exponent, t1 the significand (the integer bit, then
    # the fraction's top 63 bits), t3 the next bit, t4 the bits after it
    my ($from, $to) = find(\$t, 'hexf');
    substr($t, $to, 0) = asm(8, "
LX87:
    srli 48 s6 t0
    slli 16 s6 t1
    srli 48 s7 t2
    or t2 t1 t1
    andi 1 t1 t3
    slli 16 s7 t4
    srli 1 t1 t1
    beqz LX1 t0
    li 1 t5
    slli 63 t5 t5
    or t5 t1 t1
    j LX1
LX1:
    li32 32767 t5
    beq rel:LXN t5 t0
    beqz LX9 t3
    bnez LX2 t4
    andi 1 t1 t5
    beqz LX9 t5
    j LX2
LX2:
    # rounded up: past 64 bits the next exponent; a subnormal's to the
    # smallest normal number, exponent 1
    addi 1 t1 t1
    bnez LX3 t1
    li 1 t5
    slli 63 t5 t1
    addi 1 t0 t0
    j LX9
LX3:
    bnez LX9 t0
    srli 63 t1 t5
    beqz LX9 t5
    li 1 t0
    j LX9
LXN:
    # a NaN keeps a bit of its fraction (the quiet one)
    slli 1 t1 t5
    bnez LX9 t5
    slli 16 s6 t5
    or s7 t5 t5
    beqz LX9 t5
    li 1 t5
    slli 62 t5 t5
    or t5 t1 t1
    j LX9
LX9:
    la cc_ldhi t2
    sd 0 t0 t2
    li 1 t3
    sd 8 t3 t2
    mv t1 a0
    li 112 s11
    j L30
");
}

# ---- binop: an operand of 112 makes the operation one of 112 (wbin)
E('binop', 10, "
    li 48 t0
    beq rel:W5 t0 s5
    beq rel:W5 t0 s6
", "
    li 48 t0
    beq rel:W5 t0 s5
    beq rel:W5 t0 s6
    li 112 t0
    beq rel:W7 t0 s5
    beq rel:W7 t0 s6
");
{
    my ($from, $to) = find(\$t, 'binop');
    substr($t, $to, 0) = asm(8, "
W7:
    li 112 s8
    j W6
");
}

# ---- wcvt (a0 from, a1 to): long double (112, a type in memory, as arm's
# double) to and from double (cc_cvt_dm_d, cc_cvt_d_dm), to float128
# (cc_cvt_q_dm, exact), from float128 (__trunctfxf2, cc_sfnames 26 in
# place of 18)
E('wcvt', 8, "
    li R_t1 a1
    call li
    li 48 a0
    li 36 t0
", "
    li R_t1 a1
    call li
    li 40 t0
    beq rel:LXD t0 s4
    li 48 a0
    li 36 t0
");
E('wcvt', 10, "
    call push
    li 18 a0
", "
    call push
    li 18 a0
    addi -112 s5 t0
    seqz t0 t0
    slli 3 t0 t0
    add t0 a0 a0
");
E('wcvt', 8, "
L10:
    li 15 a0
", "
L10:
    li 112 t0
    beq rel:LXQ t0 s4
    li 15 a0
");
E('wcvt', 8, "
L20:
    li 48 t0
    beq rel:L30 t0 s4
", "
L20:
    li 48 t0
    beq rel:L30 t0 s4
    li 40 t0
    beq rel:LXE t0 s5
");
{
    my ($from, $to) = find(\$t, 'wcvt');
    substr($t, $to, 0) = asm(8, "
LXQ:
    call wtemp
    mv a0 s8
    neg s8 a0
    li R_t1 a1
    call li
    la x87n_qdm a0
    call seq
    j L9
LXD:
    la x87n_dmd a0
    call seq
    j L9
LXE:
    la x87n_ddm a0
    call seq
    j L9
");
}

# ---- a long double literal's 16 bytes in a temporary (wlit) and in a
# global (gstore) as binary128's: the low word, then cc_ldhi's high one;
# long double is no aggregate (ginit)
E('wlit', 10, "
    li TY_LDOUBLE t0
    beq rel:LH t0 s5
", "
    li 112 t0
    beq rel:LH t0 s5
    li TY_LDOUBLE t0
    beq rel:LH t0 s5
");
E('gstore', 8, "
    li TY_LDOUBLE t0
    beq rel:LH t0 s4
", "
    li 112 t0
    beq rel:LH t0 s4
    li TY_LDOUBLE t0
    beq rel:LH t0 s4
");
for my $x (['s4', 8], ['s9', 10]) {
    my ($r, $i) = @$x;
    E('ginit', $i, "
    call isagg
    li TY_LDOUBLE t0
    xor $r t0 t1
    sltu t1 zero t1
    and t1 a0 a0
", "
    call isagg
    li TY_LDOUBLE t0
    xor $r t0 t1
    sltu t1 zero t1
    and t1 a0 a0
    li 112 t0
    xor $r t0 t1
    sltu t1 zero t1
    and t1 a0 a0
");
}
E('fsconv', 8, "
    li TY_LDOUBLE t0
    beq rel:F9 t0 s4
", "
    li TY_LDOUBLE t0
    beq rel:F9 t0 s4
    li 112 t0
    beq rel:F9 t0 s4
");

# ---- gval (ldneg.pl's items): a negated long double literal or cast, its
# sign (bit 15 of the high word) flipped; the cast of an int, exact
E('gval', 10, "
    li TY_LDOUBLE t0
    beq rel:LGT t0 s7
", "
    li 112 t0
    beq rel:LGT t0 s7
    li TY_LDOUBLE t0
    beq rel:LGT t0 s7
");
E('gval', 12, "
    li TY_LDOUBLE t3
    beq rel:LGQ t3 s7
", "
    li 112 t3
    beq rel:LGX t3 s7
    li TY_LDOUBLE t3
    beq rel:LGQ t3 s7
");
E('gval', 10, "
    li TY_LDOUBLE t0
    beq rel:LDT t0 s8
", "
    li 112 t0
    beq rel:LDT t0 s8
    li TY_LDOUBLE t0
    beq rel:LDT t0 s8
");
E('gval', 12, "
    li TY_LDOUBLE t3
    beq rel:LDQ t3 s8
", "
    li 112 t3
    beq rel:LDX t3 s8
    li TY_LDOUBLE t3
    beq rel:LDQ t3 s8
");
{
    my ($from, $to) = find(\$t, 'gval');
    substr($t, $to, 0) = asm(8, "
LGX:
    la cc_ldhi t3
    ld 0 t3 t2
    li 1 t1
    slli 15 t1 t1
    xor t1 t2 t2
    sd 0 t2 t3
    addi 8 s4 a1
    j L9
LDX:
    # t0 |N|'s fraction (its top bit shifted out), t2 that bit's place, t1
    # the sign (bit 63), t5 0 for zero: the significand, the exponent
    li 0 a0
    li 0 a2
    beqz LDX1 t5
    srli 1 t0 a0
    li 1 t4
    slli 63 t4 t4
    or t4 a0 a0
    li32 16383 t3
    add t3 t2 a2
    j LDX1
LDX1:
    srli 48 t1 t3
    or t3 a2 a2
    la cc_ldhi t3
    sd 0 a2 t3
    li 1 t4
    sd 8 t4 t3
    addi 16 s4 a1
    j L9
");
}

# ---- ~ of a complex long double (complexops.pl's conjugate): on x86_64
# the imaginary part's sign is bit 15 of its high word, the u32 at 24 of
# the 32 bytes
my $cx87 = "$isx64
    addi -32 s7 t2
    seqz t2 t2
    and t2 t0 t0
";
E('unary', 10, "
    add s7 a0 a0
    addi -4 a0 a0
", "
    add s7 a0 a0
    addi -4 a0 a0
$cx87
    slli 2 t0 t0
    sub t0 a0 a0
", "
    li 1 a0
    slli 31 a0 a0
", "
    li 1 a0
    slli 31 a0 a0
$cx87
    slli 4 t0 t0
    srl t0 a0 a0
");

# ---- the SysV ABI's X87 class
E('x64eb', 8, "
    li 48 t0
    bne rel:LI t0 s4
", "
    li 112 t0
    beq rel:LM t0 s4
    li 48 t0
    bne rel:LI t0 s4
");
E('x64resclass', 8, "
    li 48 t0
    li 8 a0
    beq rel:L9 t0 s4
", "
    li 48 t0
    li 8 a0
    beq rel:L9 t0 s4
    li 112 t0
    li 9 a0
    beq rel:L9 t0 s4
");
E('x64class', 8, "
    li 48 t0
    beq rel:LQ t0 s5
", "
    li 48 t0
    beq rel:LQ t0 s5
    li 112 t0
    beq rel:LQS t0 s5
");
E('x64res', 10, "
    li 8 t0
    bne rel:L5 t0 s4
", "
    li 9 t0
    beq rel:LT9 t0 s4
    li 8 t0
    bne rel:L5 t0 s4
");
{
    my ($from, $to) = find(\$t, 'x64res');
    substr($t, $to, 0) = asm(8, "
LT9:
    la x64n_rstt a0
    call seq
    j L8
");
}
E('x64retf', 8, "
    li 8 t0
    la x64n_retq a0
    beq rel:L7 t0 s5
", "
    li 8 t0
    la x64n_retq a0
    beq rel:L7 t0 s5
    li 9 t0
    la x64n_rett a0
    beq rel:L7 t0 s5
");
E('x64wcall', 10, "
    li 8 t0
    bne rel:L3 t0 s8
", "
    addi -8 s8 t0
    li 2 t1
    bgeu rel:L3 t1 t0
");
E('x64vaarg', 8, "
    li 8 t0
    beq rel:LM t0 s6
", "
    li 8 t0
    beq rel:LM t0 s6
    li 7 t0
    beq rel:LM t0 s6
");

# ---- the primitives' names (a seq's: no numbers)
{
    my $h = '';
    for my $x (['x64n_rstt', 'cc_x64_rstt'], ['x64n_rett', 'cc_x64_rett'], ['x87n_dmd', 'cc_cvt_dm_d'],
               ['x87n_ddm', 'cc_cvt_d_dm'], ['x87n_qdm', 'cc_cvt_q_dm']) {
        my ($l, $n) = @$x;
        my $b = "\0$n\0";
        $b .= "\0" x (-length($b) % 8);
        $h .= "      $l:\n        ascii\n          " . esc($b) . "\n";
    }
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}

save();
