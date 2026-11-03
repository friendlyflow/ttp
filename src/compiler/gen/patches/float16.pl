# float16.pl: float16 and bfloat16 (the user's words, 2026-11-02): C's _Float16
# and __bf16, 2 bytes, beside float128. Type codes 34 (float, size 2) and 98
# (34 with bit 64). V holds a value's bits in its low 16 (a load's sign above
# them, no matter); on riscv64 boxed where it goes to an f register: all ones
# above the 16 (hfbox).
#
# Arithmetic is float's, as gcc's without hardware for it: both to float (or
# the other operand's wider type), the operation, and the result back to
# float16 where both were float16 or an integer (hfbin); float has enough bits
# that this rounds as float16 itself would. - flips bit 15.
#
# Conversions (hfcvt, before everything else in fcvt) call libgcc's soft-fp, as
# gcc does: __extendhfsf2 ... __truncxfhf2, __extendbfsf2 ... __trunctfbf2,
# __trunchfbf2 (cc_sfnames, a64sfargs); aarch64 has no __extendhfsf2 and such:
# its fcvt (cc_cvt_h_s, cc_cvt_h_d, cc_cvt_s_h, cc_cvt_d_h). A bfloat16 to
# anything but float through float, float16 from bfloat16 too; an integer to
# either through double (exact where it matters: past 2^53 a float16 is
# infinite); either to an integer through float (exact). i128 and u128 by
# __floattihf __floatuntihf __floattibf __floatuntibf __fixhfti __fixunshfti.
#
# The ABIs: a float's class (x86_64 xmm low half, aarch64 v's low half,
# riscv64 an f register boxed); a result masked to 16 bits (hfmask). In a
# struct: x86_64's SSE class (x64eb), aarch64's hfa in h registers, riscv64's
# flattening. arm: storage and s registers only, no conversion (gcc has neither
# by default there: -mfp16-format=ieee).
#
# Run on ttpc.ff after int128.pl. Test: progs/abi, cf16, gccrt.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
sub unesc { my $s = shift; $s =~ s/\\x([0-9a-f]{2})/chr hex $1/ge; $s }

# ---- the words
my $tyi;
{
    $t =~ /^( *)cc_tynames:\n\s*ascii\n\s*(.*?)\\x00\\x00\n/m or die 'cc_tynames';
    my $list = $2;
    $tyi = 1 + (() = $list =~ /\\x00/g);
    once(\$t, "$list\\x00\\x00\n", "$list\\x00float16\\x00bfloat16\\x00complex float16\\x00\\x00\n", 'cc_tynames');
}
E('tyname', 8, "
    call lookup
    bltz L1 a0
", "
    call lookup
    bltz L1 a0
    li $tyi t0
    beq rel:LF16 t0 a0
    addi 1 t0 t0
    beq rel:LB16 t0 a0
");
{
    my ($from, $to) = find(\$t, 'tyname');
    substr($t, $to, 0) = asm(8, "
LF16:
    li 34 a0
    leave1
LB16:
    li 98 a0
    leave1
");
}

# ---- cc_sfnames, a64sfargs
my @names = qw(__extendhfsf2 __extendhfdf2 __extendhftf2 __extendhfxf2 __extendbfsf2 __trunchfbf2
    __truncsfhf2 __truncdfhf2 __trunctfhf2 __truncxfhf2 __truncsfbf2 __truncdfbf2 __trunctfbf2 __truncxfbf2
    __floattihf __floatuntihf __floattibf __floatuntibf __fixhfti __fixunshfti);
my @kinds = ((3, 0) x 6, 3, 0, 4, 0, 5, 0, 0, 0, 3, 0, 4, 0, 5, 0, 0, 0, (6, 7) x 4, (3, 0) x 2);
my $hfi;
{
    my ($from, $to) = find(\$t, 'cc_sfnames');
    my $len = 0;
    $len += length unesc($_) for substr($t, $from, $to - $from) =~ /^ {6}(.*)\n/mg;
    die "cc_sfnames: $len\n" if $len % 16;
    $hfi = $len / 16;
    my $b = join '', map { $_ . "\0" x (16 - length) } @names;
    substr($t, $to, 0) = join '', map { "    ascii\n      " . esc($_) . "\n" } $b =~ /(.{1,160})/gs;
    ($from, $to) = find(\$t, 'a64sfargs');
    my $s = substr($t, $from, $to - $from);
    $s =~ /^( *)a64sfargs:\n *ascii\n *(.*)\n/ or die 'a64sfargs';
    my $i = $1;
    $b = substr(unesc($2), 0, 2 * $hfi) . join('', map { chr } @kinds);
    $b .= "\0" x (-length($b) % 4);
    substr($t, $from, $to - $from) = "$i" . "a64sfargs:\n$i  ascii\n$i    " . join('', map { sprintf "\\x%02x", ord } split //, $b) . "\n";
}

# ---- conversions
E('fcvt', 8, "
    call pconvf
    bnez L9 a0
", "
    call pconvf
    bnez L9 a0
    mv s4 a0
    mv s5 a1
    call hfcvt
    bnez L9 a0
");
my $msg = "ttpc: float16 and bfloat16 have no conversion here (arm: storage and the ABI; no value of them at compile time):\x20";
once(\$t, "      msg_type:\n", "      msg_f16:\n        ascii\n          " . esc($msg) . "\n      msg_type:\n", 'msg_type');
{
    my ($from) = find(\$t, 'fcvt');
    substr($t, $from, 0) = fn('ishf', "
    andi -65 a0 t0
    addi -34 t0 t0
    seqz t0 a0
    ret
", 6) . fn('hfmask', "
    enter1
    call ishf
    beqz L9 a0
    li 18 a0
    call narrow
    j L9
L9:
    leave1
", 6) . fn('hfbox', "
    enter1
    call ishf
    beqz L9 a0
    la targ_abi t0
    ld 0 t0 t0
    li 4 t1
    bne rel:L9 t1 t0
    la rvn_box16 a0
    call seq
    j L9
L9:
    leave1
", 6) . fn('hfcall', "
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    la targ_abi t0
    ld 0 t0 t0
    li 2 t1
    bne rel:L1 t1 t0
    addi -$hfi s4 t0
    li 2 t1
    bltu rel:LA t1 t0
    addi -6 t0 t0
    bltu rel:LB t1 t0
    j L1
L1:
    li 112 t0
    beq rel:LX t0 s6
    mv s6 a0
    call hfbox
    call push
    mv s4 a0
    li 1 a1
    mv s5 a2
    call wcall
    leave3
LX:
    mv s4 a0
    mv s5 a1
    call ptx87
    leave3
LA:
    slli 4 t0 t0
    j LC
LB:
    addi 2 t0 t0
    slli 4 t0 t0
    j LC
LC:
    la a64n_hf a0
    add t0 a0 a0
    call seq
    mv s5 a0
    call setty
    mv s5 a0
    call hfmask
    leave3
", 6) . fn('hfcvt', "
    enter5
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call ishf
    mv a0 s6
    mv s5 a0
    call ishf
    mv a0 s7
    or s7 s6 t0
    beqz L0 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez LBAD t0
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    beq rel:LBAD t1 t0
    beqz LTO s6
    # from float16 or bfloat16
    beqz LNH s7
    li 34 t0
    bne rel:LBH t0 s4
    li " . ($hfi + 5) . " a0
    mv s5 a1
    mv s4 a2
    call hfcall
    j L1
LBH:
    mv s4 a0
    li 36 a1
    call fcvt
    li 36 a0
    mv s5 a1
    call fcvt
    j L1
LNH:
    andi 32 s5 t0
    beqz LVIAF t0
    li 34 t0
    beq rel:LH t0 s4
    li 36 t0
    bne rel:LVIAF t0 s5
    li " . ($hfi + 4) . " a0
    li 36 a1
    mv s4 a2
    call hfcall
    j L1
LVIAF:
    mv s4 a0
    li 36 a1
    call fcvt
    li 36 a0
    mv s5 a1
    call fcvt
    j L1
LH:
    li 0 t0
    li 36 t1
    beq rel:LH1 t1 s5
    li 1 t0
    li 40 t1
    beq rel:LH1 t1 s5
    li 3 t0
    li 112 t1
    beq rel:LH1 t1 s5
    li 2 t0
    j LH1
LH1:
    addi $hfi t0 a0
    mv s5 a1
    mv s4 a2
    call hfcall
    j L1
LTO:
    # to float16 or bfloat16
    andi 32 s4 t0
    bnez LTF t0
    mv s4 a0
    li 40 a1
    call fcvt
    li 40 a0
    mv s5 a1
    call fcvt
    j L1
LTF:
    li 0 t0
    li 36 t1
    beq rel:LT1 t1 s4
    li 1 t0
    li 40 t1
    beq rel:LT1 t1 s4
    li 3 t0
    li 112 t1
    beq rel:LT1 t1 s4
    li 2 t0
    j LT1
LT1:
    li 34 t1
    beq rel:LT2 t1 s5
    addi 4 t0 t0
    j LT2
LT2:
    addi " . ($hfi + 6) . " t0 a0
    mv s5 a1
    mv s4 a2
    call hfcall
    j L1
L1:
    li 1 a0
    leave5
L0:
    li 0 a0
    leave5
LBAD:
    la msg_f16 a1
    li " . length($msg) . " a2
    li 0 a4
    j die_name
", 6);
}
# i128 and u128 to and from them
E('ptof', 10, "
    li 0 t0
    li 36 t1
    beq rel:LW9 t1 s5
", "
    li " . ($hfi + 14 - 27) . " t0
    li 34 t1
    beq rel:LW9 t1 s5
    li " . ($hfi + 16 - 27) . " t0
    li 98 t1
    beq rel:LW9 t1 s5
    li 0 t0
    li 36 t1
    beq rel:LW9 t1 s5
");
E('ftop', 10, "
    li 0 t0
    li 36 t1
    beq rel:LW9 t1 s4
", "
    li " . ($hfi + 18 - 35) . " t0
    li 34 t1
    beq rel:LW9 t1 s4
    li 98 t1
    bne rel:LW7 t1 s4
    mv s4 a0
    li 36 a1
    call fcvt
    li 36 s4
    j LW7
LW7:
    li 0 t0
    li 36 t1
    beq rel:LW9 t1 s4
");

# ---- arithmetic
E('binop', 10, "
    mv s5 a0
    call tscalar
    mv a0 s5
    mv s6 a0
    call tscalar
    mv a0 s6
", "
    mv s5 a0
    call tscalar
    mv a0 s5
    mv s6 a0
    call tscalar
    mv a0 s6
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call hfbin
    bnez LHF a0
");
{
    my ($from, $to) = find(\$t, 'binop');
    substr($t, $to, 0) = asm(8, "
LHF:
    leave5
");
    ($from) = find(\$t, 'fcvt');
    substr($t, $from, 0) = fn('hfbin', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s5 a0
    call ishf
    mv a0 s7
    mv s6 a0
    call ishf
    mv a0 s8
    or s8 s7 t0
    beqz L0 t0
    # T: the other's wider type, else float
    li 36 t2
    li 0 t3
    li 40 t0
    beq rel:LW1 t0 s5
    beq rel:LW1 t0 s6
    li 48 t0
    beq rel:LW1 t0 s5
    beq rel:LW1 t0 s6
    li 112 t0
    beq rel:LW1 t0 s5
    beq rel:LW1 t0 s6
    j LN
LW1:
    mv t0 t2
    li 1 t3
    j LN
LN:
    mv t2 s7
    mv t3 s8
    beq rel:L2 s7 s5
    call push
    la cc_exts a0
    addi 633 a0 a0
    call seq
    mv s5 a0
    mv s7 a1
    call fcvt
    call popt0
    la cc_exts a0
    addi 633 a0 a0
    call seq
    j L2
L2:
    beq rel:L3 s7 s6
    la cc_exts a0
    addi 633 a0 a0
    call seq
    call push
    la cc_exts a0
    addi 633 a0 a0
    call seq
    mv s6 a0
    mv s7 a1
    call fcvt
    call popt0
    j L3
L3:
    mv s4 a0
    mv s7 a1
    mv s7 a2
    call binop
    li OP_eq t0
    blt rel:L4 t0 s4
    li OP_ge t0
    bgt L4 t0 s4
    j L9
L4:
    bnez L9 s8
    li 36 a0
    li 34 a1
    call fcvt
    li 34 a0
    call setty
    j L9
L9:
    li 1 a0
    leave5
L0:
    li 0 a0
    leave5
", 6);
}
E('unary', 10, "
    mv s6 a0
    call fwide
    bnez W1 a0
    li 36 t0
    li 441 a0
", "
    mv s6 a0
    call ishf
    bnez LHN a0
    mv s6 a0
    call fwide
    bnez W1 a0
    li 36 t0
    li 441 a0
");
{
    my ($from, $to) = find(\$t, 'unary');
    substr($t, $to, 0) = asm(8, "
LHN:
    li32 32768 a0
    la cc_opseq a1
    addi 300 a1 a1
    call opk
    mv s6 a0
    call setty
    j L9
");
}

# ---- arm: a float's class (s registers, core ones in base pcs); no mask
{
    my ($from) = find(\$t, 'fcvt');
    substr($t, $from, 0) = fn('hfasf', "
    andi -65 a0 t0
    addi -34 t0 t0
    bnez L9 t0
    li 36 a0
    j L9
L9:
    ret
", 6);
}
E('abiclass', 8, "
    call tscalar
    mv a0 s8
", "
    call tscalar
    call hfasf
    mv a0 s8
");
E('abiresclass', 8, "
    call tscalar
    li 36 t0
", "
    call tscalar
    call hfasf
    li 36 t0
");

# ---- the ABIs: a float's class; a result masked; riscv64 boxed
for my $f ('x64class', 'a64class') {
    E($f, 8, "
    li 3 s6
    li 36 t0
    beq rel:LF t0 s5
", "
    li 3 s6
    mv s5 a0
    call ishf
    bnez LF a0
    li 36 t0
    beq rel:LF t0 s5
");
}
E('rvclass', 8, "
    li 36 t0
    beq rel:LF t0 s5
", "
    mv s5 a0
    call ishf
    bnez LF a0
    li 36 t0
    beq rel:LF t0 s5
");
E('rvclass', 10, "
    li 3 a0
    li 36 t1
    beq rel:LF1 t1 s5
", "
    li 3 a0
    li 36 t1
    beq rel:LF1 t1 s5
    li 34 t1
    beq rel:LF1 t1 s5
    li 98 t1
    beq rel:LF1 t1 s5
");
for my $f ('x64resclass', 'a64resclass', 'rvresclass') {
    E($f, 8, "
    li 36 t0
    li 1 a0
    beq rel:L9 t0 s4
", "
    li 34 t0
    li 1 a0
    beq rel:L9 t0 s4
    li 98 t0
    beq rel:L9 t0 s4
    li 36 t0
    beq rel:L9 t0 s4
");
}
for my $x (['x64res', 'x64n_resf'], ['a64res', 'a64n_resf'], ['rvres', 'rvn_resf']) {
    my ($f, $n) = @$x;
    E($f, 10, "
    li 1 t0
    bne rel:L2 t0 s4
    la $n a0
    call seq
", "
    li 1 t0
    bne rel:L2 t0 s4
    la $n a0
    call seq
    mv s7 a0
    call hfmask
");
}
E('rvretf', 10, "
    li 1 t0
    la rvn_retf a0
", "
    mv s4 a0
    call hfbox
    li 1 t0
    la rvn_retf a0
");
E('argpush', 10, "
    call pushv
    mv s6 a0
", "
    mv s6 a0
    call hfbox
    mv s6 a0
    call pushv
    mv s6 a0
");
E('x64eb', 8, "
    li 36 t0
    beq rel:L9 t0 s4
", "
    mv s4 a0
    call ishf
    bnez L9 a0
    li 36 t0
    beq rel:L9 t0 s4
");

# ---- structs: aarch64's hfa of them, in h registers, riscv64's flattening,
# each field boxed in an f register
E('hfa', 10, "
    li 48 t0
    beq rel:L9 t0 s4
", "
    li 48 t0
    beq rel:L9 t0 s4
    li 34 t0
    beq rel:L9 t0 s4
    li 98 t0
    beq rel:L9 t0 s4
");
E('a64class', 10, "
    mv a1 s8
    li 4 s9
", "
    mv a1 s8
    li 2 s9
    li 34 t0
    beq rel:LH1 t0 a0
    li 98 t0
    beq rel:LH1 t0 a0
    li 4 s9
");
E('a64put1', 10, "
    la a64n_ldsw a0
    li 4 t0
", "
    la a64n_ldhw a0
    li 2 t0
    beq rel:L42 t0 s11
    la a64n_ldsw a0
    li 4 t0
");
E('a64pparam', 10, "
    la a64n_vhs a0
    li 4 t0
", "
    la a64n_vhh a0
    li 2 t0
    beq rel:L82 t0 s10
    la a64n_vhs a0
    li 4 t0
");
E('a64resclass', 10, "
    mv a1 s5
    li 36 t0
    li 4 s6
", "
    mv a1 s5
    li 34 t0
    li 11 s6
    beq rel:LH t0 a0
    li 98 t0
    beq rel:LH t0 a0
    li 36 t0
    li 4 s6
");
E('a64res', 10, "
    la a64n_rsts s9
    li 4 s10
", "
    la a64n_rsth s9
    li 2 s10
    li 11 t0
    beq rel:L61 t0 s4
    la a64n_rsts s9
    li 4 s10
");
E('a64retf', 10, "
    la a64n_retsm s6
    li 4 s7
", "
    la a64n_rethm s6
    li 2 s7
    li 11 t0
    beq rel:L5 t0 s4
    la a64n_retsm s6
    li 4 s7
");
E('rvpick', 8, "
    li 6 t3
    li 36 t0
", "
    li 8 t3
    li 34 t0
    beq rel:L9 t0 a0
    li 98 t0
    beq rel:L9 t0 a0
    li 6 t3
    li 36 t0
");
for my $x (['rv_tfld', 'rvn_ldfh'], ['rv_tld', 'rvn_ld8'], ['rv_trst', 'rvn_rsth'], ['rv_tvh', 'rvn_vh8'], ['rv_trtx', 'rvn_rtx8']) {
    my ($tb, $n) = @$x;
    my ($from, $to) = find(\$t, $tb);
    substr($t, $to, 0) = "        dword\n          $n\n";
}
E('rvpparam', 10, "
    la rvn_vfs a0
    li 36 t0
", "
    la rvn_vfh a0
    li 34 t0
    beq rel:LK11 t0 s6
    li 98 t0
    beq rel:LK11 t0 s6
    la rvn_vfs a0
    li 36 t0
");
E('rvretf', 10, "
    la rvn_rtfs a0
    li 36 t0
", "
    la rvn_rtfh a0
    li 34 t0
    beq rel:LF15 t0 t1
    li 98 t0
    beq rel:LF15 t0 t1
    la rvn_rtfs a0
    li 36 t0
");

# ---- complex float16 (the user's word, 2026-11-02): C's _Complex _Float16, a
# struct type of ttpc's own as complex float128's (complexq.pl), its fields
# real part and imag part float16s: by each ABI two float16s, through the
# struct path (x86_64 one SSE eightbyte, aarch64's hfa, riscv64's two f
# registers). libgcc's __mulhc3, __divhc3.
{
    my $node = sub {
        my ($label, $text, @kids) = @_;
        my $s = "  $label:\n    reserve\n      32\n    dword\n      " . scalar(@kids) . "\n    dword\n      " . (@kids ? "${label}_k" : 0)
            . "\n    dword\n      " . length($text) . "\n    dword\n      ${label}_t\n";
        $s .= "  ${label}_k:\n" . join('', map { "    dword\n      $_\n" } @kids) if @kids;
        $s;
    };
    # the word's place in cx_nodes (tyname: its index past 18)
    my ($from, $to) = find(\$t, 'cx_nodes');
    my $block = substr($t, $from, $to - $from);
    my $have = () = $block =~ /^ *dword\n/mg;
    my $want = $tyi + 2 - 18;
    die "float16: cx_nodes has $have, wants up to $want\n" if $have > $want;
    substr($t, $to, 0) = "    dword\n      0\n" x ($want - $have) . "    dword\n      cxn_h\n";
    my %texts = (cxn_h_t => 'complex float16:', cxn_hr_t => 'real part:', cxn_hi_t => 'imag part:', cxn_hty_t => 'float16');
    my $data = $node->('cxn_h', 'complex float16:', 'cxn_struct', 'cxn_hr', 'cxn_hi')
        . $node->('cxn_hr', 'real part:', 'cxn_hty') . $node->('cxn_hi', 'imag part:', 'cxn_hty') . $node->('cxn_hty', 'float16')
        . join('', map { "  $_:\n    ascii\n      $texts{$_}\n" } sort keys %texts);
    once(\$t, "  cxn_struct:\n", "$data  align\n    8\n  cxn_struct:\n", 'cxn_struct');
}

# ---- the primitives' names
{
    my $h = "      rvn_box16:\n        ascii\n          " . esc("\0cc_rv_box16\0\0\0\0") . "\n";
    my $b = join '', map { "\0" . $_ . "\0" x (15 - length) } qw(cc_cvt_h_s cc_cvt_h_d cc_cvt_s_h cc_cvt_d_h);
    $h .= "      a64n_hf:\n        ascii\n          " . esc($b) . "\n";
    for my $x (['a64n_ldhw', 'cc_a64_ldhw'], ['a64n_vhh', 'cc_a64_vhh'], ['a64n_rsth', 'cc_a64_rsth'], ['a64n_rethm', 'cc_a64_rethm'],
               ['rvn_ldfh', 'cc_rv_ldfh'], ['rvn_vfh', 'cc_rv_vfh'], ['rvn_rsth', 'cc_rv_rsth'], ['rvn_rtfh', 'cc_rv_rtfh']) {
        my ($l, $n) = @$x;
        $h .= "      $l:\n        ascii\n          " . esc($n . "\0" x (16 - length $n)) . "\n";
    }
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}

save();
