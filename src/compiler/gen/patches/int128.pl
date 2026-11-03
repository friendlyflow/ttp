# int128.pl: i128 and u128 (the user's words, 2026-11-02): C's __int128 and
# unsigned __int128, on the targets whose word is 8 bytes (riscv64, x86_64,
# aarch64), refused on arm; at compile time for its size alone. They are arm's i64 and u64
# (pairs.pl, pairs2.pl, pairs3.pl) one size up: a pair of registers, V and L
# (macros/<target>.ff.txt, the group pair128), type codes 0x40 and 0x50 (the
# size nibble 0 is 16, as (code | 16) == 80), 16 bytes aligned to 16. ispair
# takes them, so everything arm's pairs go through takes them too: the usual
# conversions, the operators by cc_opseqp, -, ~, !, ++, --, loads, stores,
# the stack between operands, conditions, switch.
#
# Division and % call libgcc's __divti3 __udivti3 __modti3 __umodti3 (cc_args2_p
# puts L and V in the argument registers); float, double, long double and
# float128 to and from a pair call __floattisf ... __fixunsxfti, as gcc does
# (cc_sfnames from 27 on, wcall; a64sfargs' kinds 6 and 7 are a pair's high
# and low slot, __fixxfti takes the x87's long double on the stack). A pair
# to a narrower integer is that integer's narrow (arm's low word needs none).
#
# The ABIs: a result is in V, which is rax:rdx, x0:x1, a0:a1. An argument is
# a struct of two words, aligned to 16 (x64class, a64class, rvclass: kinds 2,
# 8 and rv's 12, by the rules each has for such a struct; riscv64 as a long
# double, a named one from any register, an unnamed one from an even one);
# a call's pair stays on two slots, so that pslot finds each argument's slot
# and x64put*, a64put*, rvput* load from them; a parameter is what the ABI's
# struct path leaves (V its address) loaded (ppload). va_arg: as the struct's;
# x86_64's overflow area aligned (cc_x64_vax16). Test: progs/abi, ci128.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
sub unesc { my $s = shift; $s =~ s/\\x([0-9a-f]{2})/chr hex $1/ge; $s }

# ---- the words: cc_tynames, after what is there
my $tyi;
{
    $t =~ /^( *)cc_tynames:\n\s*ascii\n\s*(.*?)\\x00\\x00\n/m or die 'cc_tynames';
    my $list = $2;
    $tyi = 1 + (() = $list =~ /\\x00/g);
    once(\$t, "$list\\x00\\x00\n", "$list\\x00i128\\x00u128\\x00\\x00\n", 'cc_tynames');
}
my $msg = "ttpc: i128 and u128 are on a target of 8-byte words, no value of them at compile time:\x20";
E('tyname', 8, "
    call lookup
    bltz L1 a0
", "
    call lookup
    bltz L1 a0
    li $tyi t0
    beq rel:LI128 t0 a0
    addi 1 t0 t0
    beq rel:LU128 t0 a0
");
{
    my ($from, $to) = find(\$t, 'tyname');
    substr($t, $to, 0) = asm(8, "
LI128:
    li 64 t1
    j LP128
LU128:
    li 80 t1
    j LP128
LP128:
    la targ_word t0
    ld 0 t0 t0
    li 8 t2
    bne rel:LP129 t2 t0
    mv t1 a0
    leave1
LP129:
    mv s4 a0
    la msg_i128 a1
    li " . length($msg) . " a2
    j diename
");
}
once(\$t, "      msg_type:\n", "      msg_i128:\n        ascii\n          " . esc($msg) . "\n      msg_type:\n", 'msg_type');

# ---- the pair
E('ispair', 8, "
    li 16 t0
    or t0 a0 a0
    addi -88 a0 a0
    seqz a0 a0
    ret
", "
    li 16 t0
    or t0 a0 a0
    addi -80 a0 t0
    seqz t0 t0
    addi -88 a0 a0
    seqz a0 a0
    or t0 a0 a0
    ret
");
for my $f ('tsize', 'talign') {
    E($f, 10, "
    li 88 t1
    beq rel:L2 t1 t0
", "
    li 88 t1
    beq rel:L2 t1 t0
    li 80 t1
    beq rel:L2 t1 t0
");
}
E('opseq', 8, "
    li 88 t3
    bne rel:L1 t3 t2
    la cc_opseqp t1
", "
    addi -80 t2 t2
    andi -9 t2 t2
    bnez L1 t2
    la cc_opseqp t1
");
E('promote', 8, "
    andi 12 a0 t0
    bnez L1 t0
", "
    li 16 t0
    or t0 a0 t0
    li 80 t1
    beq rel:L1 t1 t0
    andi 12 a0 t0
    bnez L1 t0
");
# the usual conversions: i128 only where one of them is i128 ... a u64 beside
# an i128 is an i128
E('common', 10, "
    li 72 a0
    or t1 a0 a0
    leave3
", "
    la targ_word t0
    ld 0 t0 t0
    li 8 t2
    beq rel:L21 t2 t0
    li 72 a0
    or t1 a0 a0
    leave3
");
{
    my ($from, $to) = find(\$t, 'common');
    substr($t, $to, 0) = asm(8, "
L21:
    li 80 t2
    li 0 t1
    bne rel:L22 t2 s4
    li 16 t1
    j L22
L22:
    bne rel:L23 t2 s5
    li 16 t1
    j L23
L23:
    li 64 a0
    or t1 a0 a0
    leave3
");
}

# ---- cc_sfnames: their functions; a64sfargs: their kinds
my @fl = qw(__floattisf __floatuntisf __floattidf __floatuntidf __floattitf __floatuntitf __floattixf __floatuntixf);
my @fx = qw(__fixsfti __fixunssfti __fixdfti __fixunsdfti __fixtfti __fixunstfti __fixxfti __fixunsxfti);
my @dv = qw(__divti3 __udivti3 __modti3 __umodti3);
my ($sfi, $fxi, $dvi);
{
    my ($from, $to) = find(\$t, 'cc_sfnames');
    my $len = 0;
    $len += length unesc($_) for substr($t, $from, $to - $from) =~ /^ {6}(.*)\n/mg;
    die "cc_sfnames: $len\n" if $len % 16;
    $sfi = $len / 16; $fxi = $sfi + @fl; $dvi = $fxi + @fx;
    my $b = join '', map { $_ . "\0" x (16 - length) } @fl, @fx, @dv;
    substr($t, $to, 0) = join '', map { "    ascii\n      " . esc($_) . "\n" } $b =~ /(.{1,160})/gs;
}
{
    my ($from, $to) = find(\$t, 'a64sfargs');
    my $s = substr($t, $from, $to - $from);
    $s =~ /^( *)a64sfargs:\n *ascii\n *(.*)\n/ or die 'a64sfargs';
    my $b = substr(unesc($2), 0, 2 * $sfi);
    die "a64sfargs\n" if length($b) != 2 * $sfi;
    $b .= "\x06\x07" x @fl;
    $b .= "\x03\x00" x 2 . "\x04\x00" x 2 . "\x05\x00" x 2 . "\x00\x00" x 2;
    $b .= "\x00\x00" x @dv;
    $b .= "\0" x (-length($b) % 4);
    my $i = $1;
    substr($t, $from, $to - $from) = "$i" . "a64sfargs:\n$i  ascii\n$i    " . join('', map { sprintf "\\x%02x", ord } split //, $b) . "\n";
}
# a call: the kinds 6 and 7 of a pair's slots, in two argument registers
for my $x (['x64wcall', "la cc_names a0\n addi 30 a0 a0\n", 0, ''], ['a64wcall', "la cc_names a0\n addi 30 a0 a0\n", 0, "li 1 t1\n sub t0 t1 t1\n slli 3 t1 t1\n sub t1 a3 a3\n"], ['rvwcall', "la rvn_ld8 a0\n", 10, '']) {
    my ($f, $name, $base, $hi) = @$x;
    E($f, 10, "
    li 1 t0
    bne rel:L11 t0 t2
", "
    addi -6 t2 t0
    li 2 t1
    bltu rel:LP2 t1 t0
    li 1 t0
    bne rel:L11 t0 t2
");
    my ($from, $to) = find(\$t, $f);
    substr($t, $to, 0) = asm(8, "
LP2:
    $name
    $hi
    li 1 t1
    sub t0 t1 t1
    add t1 s9 a2
    addi $base a2 a2
    slli 1 t0 t0
    add t0 s9 s9
    j L13
");
}

# ---- compile time: the type is there, for its size (sizeof, a struct with
# one); no value of it, which a global's : could not give whole
{
    my ($from) = find(\$t, 'ispair');
    substr($t, $from, 0) = fn('pjit', "
    la ccs t0
    ld CC_jit t0 t0
    beqz L9 t0
    li 16 t0
    or t0 a0 t0
    li 80 t1
    bne rel:L9 t1 t0
    la msg_i128 a1
    li " . length($msg) . " a2
    li 0 a4
    j die_name
L9:
    ret
", 6);
}
E('paccess', 8, "
    mv a1 s5
    call ispair
", "
    mv a1 s5
    call pjit
    call ispair
");
E('pconvf', 8, "
    mv a0 s4
    mv a1 s5
    call ispair
    mv a0 s6
", "
    mv a0 s4
    mv a1 s5
    call pjit
    mv s5 a0
    call pjit
    mv s4 a0
    call ispair
    mv a0 s6
");
E('unseq', 8, "
    call getty
    call ispair
", "
    call getty
    call pjit
    call ispair
");

# ---- division and %
E('binop', 10, "
    andi 16 s8 s7
    li 50 t0
    mul t0 s4 t0
", "
    mv s4 a0
    mv s8 a1
    call pdiv
    bnez LPD a0
    andi 16 s8 s7
    li 50 t0
    mul t0 s4 t0
");
{
    my ($from, $to) = find(\$t, 'binop');
    substr($t, $to, 0) = asm(8, "
LPD:
    mv s8 s5
    j L8
");
    ($from) = find(\$t, 'binop');
    substr($t, $from, 0) = fn('pdiv', "
    enter3
    mv a0 s4
    mv a1 s5
    mv s5 a0
    call pjit
    li 19 t0
    beq rel:L1 t0 s4
    li 20 t0
    bne rel:L8 t0 s4
    j L1
L1:
    la targ_word t0
    ld 0 t0 t0
    li 8 t1
    bne rel:L8 t1 t0
    mv s5 a0
    call ispair
    beqz L8 a0
    la cc_args2p a0
    call seq
    addi -19 s4 t0
    slli 1 t0 t0
    andi 16 s5 t1
    srli 4 t1 t1
    add t1 t0 t0
    addi $dvi t0 a0
    li 0 a1
    mv s5 a2
    call wcall
    li 1 a0
    leave3
L8:
    li 0 a0
    leave3
", 6);
}

# ---- conversions
E('pconvf', 8, "
    andi 32 a0 t0
    bnez L8 t0
    li 1 a0
    j L9
", "
    andi 32 a0 t0
    bnez L8 t0
    call pnarrow
    li 1 a0
    j L9
");
E('ptof', 8, "
    andi 16 s4 s4
", "
    andi 16 s4 s4
    la targ_word t0
    ld 0 t0 t0
    li 8 t1
    beq rel:LW8 t1 t0
");
E('ftop', 8, "
    andi 16 s5 s5
", "
    andi 16 s5 s5
    la targ_word t0
    ld 0 t0 t0
    li 8 t1
    beq rel:LW8 t1 t0
");
{
    my ($from, $to) = find(\$t, 'ptof');
    substr($t, $to, 0) = asm(8, "
LW8:
    li 0 t0
    li 36 t1
    beq rel:LW9 t1 s5
    li 2 t0
    li 40 t1
    beq rel:LW9 t1 s5
    li 6 t0
    li 112 t1
    beq rel:LW9 t1 s5
    li 4 t0
    j LW9
LW9:
    srli 4 s4 t1
    add t1 t0 t0
    addi $sfi t0 s4
    la cc_pushp a0
    li 2 t1
    call pushpop
    mv s4 a0
    li 2 a1
    mv s5 a2
    call wcall
    leave2
");
    ($from, $to) = find(\$t, 'ftop');
    substr($t, $to, 0) = asm(8, "
LW8:
    li 0 t0
    li 36 t1
    beq rel:LW9 t1 s4
    li 2 t0
    li 40 t1
    beq rel:LW9 t1 s4
    li 6 t0
    li 112 t1
    beq rel:LWX t1 s4
    li 4 t0
    j LW9
LW9:
    srli 4 s5 t1
    add t1 t0 t0
    addi $fxi t0 s4
    call push
    mv s4 a0
    li 1 a1
    li 64 a2
    or s5 a2 a2
    call wcall
    leave2
LWX:
    srli 4 s5 t1
    add t1 t0 t0
    addi $fxi t0 a0
    li 64 a1
    or s5 a1 a1
    call ptx87
    leave2
");
    ($from) = find(\$t, 'ptof');
    substr($t, $from, 0) = fn('pnarrow', "
    enter1
    la targ_word t0
    ld 0 t0 t0
    li 8 t1
    bne rel:L9 t1 t0
    andi 15 a0 t0
    beqz L9 t0
    bge rel:L9 t1 t0
    call narrow
    j L9
L9:
    leave1
", 6) . fn('ptx87', "
    enter3
    mv a0 s4
    mv a1 s5
    li 2 s6
    la cc_loadp a0
    call seq
    la ccs t0
    ld CC_depth t0 t0
    andi 15 t0 t0
    beqz L1 t0
    call push
    li 3 s6
    j L1
L1:
    la cc_pushp a0
    li 2 t1
    call pushpop
    mv s4 a0
    li 0 a1
    mv s5 a2
    call wcall
    mv s6 a0
    call popped
    slli 3 s6 a1
    la cc_addsp a0
    call seq
    leave3
", 6);
}

# ---- a parameter: what the ABI's struct path gives, its address in V, loaded
E('pparam', 10, "
    mv s4 a0
    mv s5 a1
    call abipparam
", "
    mv s4 a0
    mv s5 a1
    call abipparam
    ld VAR_type s5 a0
    call ppload
");
{
    my ($from) = find(\$t, 'pparam');
    substr($t, $from, 0) = fn('ppload', "
    enter1
    mv a0 s4
    call ispair
    beqz L9 a0
    la targ_word t0
    ld 0 t0 t0
    li 8 t1
    bne rel:L9 t1 t0
    mv s4 a0
    call load
    j L9
L9:
    leave1
", 6) . fn('pslot', "
    la pair_args t3
    ld 8 t3 t3
    li 1 t4
    addi 1 s9 t5
    sll t5 t4 t4
    addi -1 t4 t4
    and t4 t3 t3
    sub t5 t2 t2
L1:
    beqz L9 t3
    andi 1 t3 t4
    sub t4 t2 t2
    srli 1 t3 t3
    j L1
L9:
    ret
", 6);
}

# ---- a global's initializer: the number's 64 bits; -N all ones above it
# (gval's value, then cc_ldhi's high word, as a long double's; gput writes the
# value's 16 bytes, its high ones 0 first)
E('gstore', 8, "
    mv s4 a1
    call gval
", "
    mv s4 a1
    call pgsign
    call gval
");
E('gstore', 8, "
    li 112 t0
    beq rel:LH t0 s4
", "
    li 16 t0
    or t0 s4 t0
    li 80 t1
    beq rel:LH t1 t0
    li 112 t0
    beq rel:LH t0 s4
");
{
    my ($from) = find(\$t, 'gstore');
    substr($t, $from, 0) = fn('pgsign', "
    li 16 t0
    or t0 a1 t0
    li 80 t1
    bne rel:L9 t1 t0
    ld 0 a0 t0
    lbu NODE_children_len t0 t1
    bnez L9 t1
    lbu NODE_content_len t0 t1
    beqz L9 t1
    ld NODE_content t0 t2
    lbu 0 t2 t2
    li 45 t3
    bne rel:L9 t3 t2
    la cc_ldhi t0
    li -1 t1
    sd 0 t1 t0
    li 1 t1
    sd 8 t1 t0
    j L9
L9:
    ret
", 6);
}

# ---- the three ABIs: a call's slots
for my $x (['x64call', 'x64put', 3, ''], ['a64call', 'a64put', 4, "ld 1616 sp a5\n"], ['rvcall', 'rvput', 3, "ld 1616 sp a5\n"]) {
    my ($f, $p, $sh, $a5) = @$x;
    for my $n (0, 1) {
        E($f, 10, "
    ld 1624 sp t2
    sub s9 t2 t2
    addi -1 t2 t2
    slli $sh t2 t2
    add s10 t2 a4
    $a5
    call $p$n
", "
    ld 1624 sp t2
    call pslot
    slli $sh t2 t2
    add s10 t2 a4
    $a5
    call $p$n
");
    }
}

# ---- x86_64
E('x64class', 8, "
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 3 s6
", "
    mv s5 a0
    call ispair
    bnez LP a0
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 3 s6
");
{
    my ($from, $to) = find(\$t, 'x64class');
    substr($t, $to, 0) = asm(8, "
LP:
    ld 0 s4 t0
    addi 2 t0 t1
    li 6 t2
    blt rel:LS t1 t2
    sd 0 t1 s4
    ld 8 s4 t3
    slli 8 t3 t3
    or t3 t0 a1
    li 2 a2
    li 2 a0
    leave8
");
}
# (a pair in a struct: both its eightbytes in general registers)
E('x64eb', 10, "
    srli 3 s5 t1
    li 1 t2
    sll t1 t2 t2
", "
    mv s4 a0
    call ispair
    slli 1 a0 t2
    addi 1 t2 t2
    srli 3 s5 t1
    sll t1 t2 t2
");
E('x64put0', 10, "
    li 8 t0
    bne rel:L9 t0 s4
", "
    li 8 t0
    bne rel:L9 t0 s4
    mv s6 a0
    call ispair
    bnez LP a0
");
E('x64put1', 10, "
    li 2 t0
    bne rel:L9 t0 s4
", "
    li 2 t0
    bne rel:L9 t0 s4
    mv s6 a0
    call ispair
    bnez LP a0
");
{
    my ($from, $to) = find(\$t, 'x64put0');
    substr($t, $to, 0) = asm(8, "
LP:
    la x64n_stk a0
    li 2 a1
    mv s8 a2
    mv s5 a3
    call a64p
    la x64n_stk a0
    li 2 a1
    addi 8 s8 a2
    addi 8 s5 a3
    call a64p
    leave5
");
    ($from, $to) = find(\$t, 'x64put1');
    substr($t, $to, 0) = asm(8, "
LP:
    andi 255 s5 s9
    la cc_names a0
    addi 30 a0 a0
    li 2 a1
    mv s9 a2
    mv s8 a3
    call a64p
    la cc_names a0
    addi 30 a0 a0
    li 2 a1
    addi 1 s9 a2
    addi 8 s8 a3
    call a64p
    leave8
");
}
E('x64vaarg', 10, "
    mv a3 a4
    la x64n_vax a0
    j LP
", "
    mv a3 a4
    mv s5 a0
    call ispair
    mv a0 t1
    la x64n_vax a0
    beqz LP t1
    la x64n_vax16 a0
    j LP
");

# ---- aarch64
E('a64class', 8, "
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 3 s6
", "
    mv s5 a0
    call ispair
    bnez LP a0
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 3 s6
");
{
    my ($from, $to) = find(\$t, 'a64class');
    substr($t, $to, 0) = asm(8, "
LP:
    li 2 s8
    li 16 s9
    ld 0 s4 t0
    addi 1 t0 t0
    andi -2 t0 t0
    j LX1
");
}
E('a64put0', 10, "
    li 8 t0
    bne rel:L2 t0 s4
", "
    li 8 t0
    bne rel:L2 t0 s4
    mv s6 a0
    call ispair
    bnez LP a0
");
E('a64put1', 10, "
    li 2 t0
    bne rel:L3 t0 s4
", "
    li 2 t0
    bne rel:L3 t0 s4
    mv s6 a0
    call ispair
    bnez LP a0
");
{
    my ($from, $to) = find(\$t, 'a64put0');
    substr($t, $to, 0) = asm(8, "
LP:
    la a64n_stk a0
    li 2 a1
    mv s8 a2
    mv s5 a3
    call a64p
    la a64n_stk a0
    li 2 a1
    addi 8 s8 a2
    addi 8 s5 a3
    call a64p
    leave8
");
    ($from, $to) = find(\$t, 'a64put1');
    substr($t, $to, 0) = asm(8, "
LP:
    la cc_names a0
    addi 30 a0 a0
    li 2 a1
    mv s5 a2
    mv s8 a3
    call a64p
    la cc_names a0
    addi 30 a0 a0
    li 2 a1
    addi 1 s5 a2
    addi 8 s8 a3
    call a64p
    leave8
");
}

# ---- riscv64
E('rvclass', 8, "
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 36 t0
", "
    mv s5 a0
    call ispair
    bnez LQ a0
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 36 t0
");
E('rvput0', 10, "
    li 8 t0
    bne rel:L2 t0 s4
", "
    li 8 t0
    bne rel:L2 t0 s4
    mv s6 a0
    call ispair
    bnez LP a0
");
E('rvput0', 10, "
    li 12 t0
    bne rel:L3 t0 s4
", "
    li 12 t0
    bne rel:L3 t0 s4
    mv s6 a0
    call ispair
    bnez LP1 a0
");
E('rvput1', 10, "
    li 2 t0
    bne rel:L3 t0 s4
", "
    li 2 t0
    bne rel:L3 t0 s4
    mv s6 a0
    call ispair
    bnez LP a0
");
E('rvput1', 10, "
    li 12 t0
    bne rel:L6 t0 s4
", "
    li 12 t0
    bne rel:L6 t0 s4
    mv s6 a0
    call ispair
    bnez LP1 a0
");
{
    my $st = sub { my ($s, $d) = @_; "
    la rvn_ld8 a0
    li 2 a1
    li 6 a2
    $s a3
    call a64p
    la rvn_st a0
    li 1 a1
    $d a2
    call a64p
" };
    my ($from, $to) = find(\$t, 'rvput0');
    substr($t, $to, 0) = asm(8, "
LP:" . $st->('mv s8', 'mv s5') . $st->('addi 8 s8', 'addi 8 s5') . "
    leave8
LP1:" . $st->('addi 8 s8', 'mv s5') . "
    leave8
");
    ($from, $to) = find(\$t, 'rvput1');
    substr($t, $to, 0) = asm(8, "
LP:
    la rvn_ld8 a0
    li 2 a1
    addi 10 s5 a2
    mv s8 a3
    call a64p
    la rvn_ld8 a0
    li 2 a1
    addi 11 s5 a2
    addi 8 s8 a3
    call a64p
    leave8
LP1:
    la rvn_ld8 a0
    li 2 a1
    li 17 a2
    mv s8 a3
    call a64p
    leave8
");
}
E('rvvaarg', 10, "
    li 1 a1
    slli 3 s7 a2
    call a64p
    j LY
", "
    li 1 a1
    slli 3 s7 a2
    call a64p
    mv s5 a0
    call ppload
    j LY
");

# ---- the primitives' names (a seq's; a64p's)
{
    my $b = "\0cc_args2_p\0";
    $b .= "\0" x (-length($b) % 8);
    my $h = "      cc_args2p:\n        ascii\n          " . esc($b) . "\n";
    $h .= "      x64n_vax16:\n        ascii\n          " . esc("cc_x64_vax16\0\0\0\0") . "\n";
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}

save();
