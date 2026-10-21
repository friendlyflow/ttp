# abix64.pl: calls by the SysV ABI of x86_64 as Linux has it, x86_64's
# cc_abi 3 (the user's choice, 2026-10-19: ttpc follows each platform's C
# ABI for every call), on the mechanism of abi.pl, abi3.pl and abia64.pl.
# Each of their hooks goes to a function of its own here where the
# target's ABI is 3 (and not at compile time): abicall x64call, abipplan
# x64pplan, abipparam x64pparam, abiretf x64retf, abiresclass x64resclass,
# abivaarg x64vaarg, abivapush (nothing), abivapackm x64vapackm, abiseq
# x64seq, vacopy x64vacopy, wcall (the C layer's soft-fp calls) x64wcall;
# vastart x64vastart, tyname's va_list x64valist.
#
# The classification (x64class, for a call's arguments and a function's
# parameters alike): by the state (the general registers rdi rsi rdx rcx
# r8 r9 used, the xmm registers xmm0..xmm7 used, the stack's bytes) an
# argument's kind: 1 a general register, 2 a struct of 16 bytes or less in
# its eightbytes' registers (x64sclass: an eightbyte of floats and doubles
# only in an xmm register, any other in a general one; all of them, or the
# struct goes on the stack), 3 4 5 a float, double, long double (binary128,
# ttpc's long double: gcc's -mlong-double-128) in an xmm register, 7 a
# scalar on the stack (8 bytes; a long double 16, aligned), 8 a struct on
# the stack (its bytes, 8-aligned; 16 where the struct is): one larger than
# 16 bytes, one with a long double past its start, one the registers have
# no room for. A va_list (the ABI's array of one struct) goes as its
# address. A variadic function's arguments go the same way; its caller
# gives al the count of the xmm registers used.
#
# A result (x64resclass): 0 rax, 1 xmm0 (a float), 2 xmm0 (a double), 8
# xmm0 (a long double), 3 a struct of 16 bytes or less in rax rdx xmm0
# xmm1 (its eightbytes' classes), 6 in memory, at rdi (the room the caller
# gives, its first argument; rax has it again on return). A call (x64call)
# evaluates and pushes its arguments as before, classifies them, makes
# room below them for the stack's arguments (rsp 16-aligned at the call,
# FP is: _start's first push, x64seq), copies those (the first pass), loads
# the registers (the second), rdi, al, and calls; the result where C has
# it (x64res: a float's or double's bits in V, a struct's or long double's
# address in V, its room). The callee (x64pplan) keeps rdi for a result in
# memory, and all the registers of the arguments in its frame (cc_x64_save,
# laid out as the ABI's register save area) where a parameter is a struct
# in registers or a long double, or the function is variadic; x64pparam
# finds each parameter in its register, that save, or the stack above FP.
# va_list is the ABI's struct (24 bytes, x64valist); va_start and va_arg as
# the ABI has them (cc_x64_vas1, cc_x64_vax ...). va_arg_pack passes on the
# registers the function was given beyond its named ones (a call with as
# many named ones of each class, none on the stack); va_arg_pack_len is
# the count a ttpc caller gives a variadic function in r11 (no register of
# the ABI's: a gcc caller's r11 is no count). Run on ttpc.ff after abia64.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# ---- the hooks: where the ABI is 3 and not at compile time, function f
# goes on in function g, with its arguments as they are
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
sub hook {
    my ($f, $g) = @_;
    my ($from, $to) = find(\$t, "cc/$f");
    my $blk = substr($t, $from, $to - $from);
    $blk =~ /^( *)\Q$f\E:\n/ or die "abix64: no $f\n";
    my $i = length($1) + 2;
    $blk =~ s/^( *\Q$f\E:\n)/$1 . asm($i, "$isx64\n bnez LX64 t0")/e;
    $blk .= asm($i, "LX64:\n j $g");
    substr($t, $from, $to - $from) = $blk;
}
hook('abicall', 'x64call');
hook('abipplan', 'x64pplan');
hook('abipparam', 'x64pparam');
hook('abiretf', 'x64retf');
hook('abiresclass', 'x64resclass');
hook('abivaarg', 'x64vaarg');
hook('abivapush', 'a64nop');
hook('abivapackm', 'x64vapackm');
hook('abiseq', 'x64seq');
hook('vacopy', 'x64vacopy');
hook('wcall', 'x64wcall');

# vastart: the ABI's va_list filled in (V the address of ap)
E('cc/vastart', 8, "
    ld CC_va t0 t1
    beqz L8 t1
", "
    ld CC_va t0 t1
    beqz L8 t1
    la targ_abi t1
    ld 0 t1 t1
    addi -3 t1 t1
    seqz t1 t1
    la ccs t2
    ld CC_jit t2 t2
    seqz t2 t2
    and t2 t1 t1
    bnez LVX t1
");
{
    my ($from, $to) = find(\$t, 'cc/vastart');
    substr($t, $to, 0) = asm(8, "
        LVX:
        mv s4 a0
        call x64vastart
        leave1
    ");
}
# tyname: va_list is the ABI's struct
E('cc/tyname', 8, "
    LVA:
    la targ_abi t0
    ld 0 t0 t0
    li 2 t1
    bne rel:L5 t1 t0
", "
    LVA:
    la targ_abi t0
    ld 0 t0 t0
    li 3 t1
    beq rel:LVX t1 t0
    li 2 t1
    bne rel:L5 t1 t0
");
{
    my ($from, $to) = find(\$t, 'cc/tyname');
    substr($t, $to, 0) = asm(8, "
        LVX:
        la ccs t0
        ld CC_jit t0 t0
        bnez L5 t0
        call x64valist
        leave1
    ");
}

# ---- the state: data after a64_vsave; va_list's struct, x64_vanode:
# nodes (hash, children_len, children, content_len, content) as its
# definition would be: struct, gp_offset fp_offset (u32),
# overflow_arg_area reg_save_area (long)
$t =~ /^( *)a64_vsave:\n\1  dword\n\1    0\n/m or die "abix64: no a64_vsave\n";
my $vi = $1;
sub dwords { my ($l, @v) = @_; "$vi$l:\n" . join('', map { "$vi  " . ($_ =~ /^r(\d+)$/ ? "reserve\n$vi    $1\n" : "dword\n$vi    $_\n") } @v) }
sub text { my ($l, $s) = @_; my $b = $s . "\0" x (-length($s) % 8 || 8); $b =~ s/\0/\\x00/g; "$vi$l:\n$vi  ascii\n$vi    $b\n" }
my @f = (['gp_offset:', 'u32'], ['fp_offset:', 'u32'], ['overflow_arg_area:', 'long'], ['reg_save_area:', 'long']);
my $nodes = dwords('x64_vanode', 'r32', 1 + @f, 'x64_vakids', 0, 0)
    . dwords('x64_vakids', 'x64_vakw', map { "x64_vaf$_" } 1 .. @f)
    . dwords('x64_vakw', 'r32', 0, 0, 6, 'x64_vas0')
    . join('', map { my $k = $_ + 1; dwords("x64_vaf$k", 'r32', 1, "x64_vafk$k", length $f[$_][0], "x64_vas$k") . dwords("x64_vafk$k", "x64_vat_$f[$_][1]") } 0 .. $#f)
    . dwords('x64_vat_long', 'r32', 0, 0, 4, 'x64_vasl') . dwords('x64_vat_u32', 'r32', 0, 0, 3, 'x64_vasu')
    . text('x64_vas0', 'struct') . join('', map { text("x64_vas" . ($_ + 1), $f[$_][0]) } 0 .. $#f)
    . text('x64_vasl', 'long') . text('x64_vasu', 'u32');
once(\$t, "${vi}a64_vsave:\n$vi  dword\n$vi    0\n", "${vi}a64_vsave:\n$vi  dword\n$vi    0\n"
    . join('', map { "$vi$_:\n$vi  dword\n$vi    0\n" } qw(x64_st x64_named x64_cls x64_flags)) . $nodes, 'a64_vsave');

# ---- the functions, in cc's layer 3
my $h = '';
# x64seq a0 a1 a2: seq a1 (a variadic function's prologue is the plain
# one); _start's prologue after cc_x64_entry, as startinit finds _start
$h .= fn('x64seq', "
    enter2
    mv a0 s4
    mv a1 s5
    la cc_prologue t0
    bne rel:L1 t0 s5
    mv s4 a0
    call libbase
    ld 8 a0 t0
    beqz L1 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    la ifnames a2
    addi 26 a2 a2
    li 7 a3
    call streq
    beqz L1 a0
    la x64n_entry a0
    call seq
    L1:
    mv s5 a0
    call seq
    leave2
", 6);
# x64eb a0 a1: the eightbytes of a value of type a0 at offset a1 of a struct
# of 16 bytes or less, in x64_cls (bit k for an eightbyte with a part that
# is no float or double) and x64_flags (1: the struct is in memory, a long
# double past its start; 2: a long double at its start)
$h .= fn('x64eb', "
    enter8
    mv a0 s4
    mv a1 s5
    li 16 t0
    bge rel:L9 t0 s5
    lui TY_REC t0
    bgeu rel:LR t0 s4
    li 36 t0
    beq rel:L9 t0 s4
    li 40 t0
    beq rel:L9 t0 s4
    li 48 t0
    bne rel:LI t0 s4
    bnez LM s5
    la x64_flags t0
    ld 0 t0 t1
    li 2 t2
    or t2 t1 t1
    sd 0 t1 t0
    j L9
    LM:
    la x64_flags t0
    ld 0 t0 t1
    li 1 t2
    or t2 t1 t1
    sd 0 t1 t0
    j L9
    LI:
    srli 3 s5 t1
    li 1 t2
    sll t1 t2 t2
    la x64_cls t0
    ld 0 t0 t1
    or t2 t1 t1
    sd 0 t1 t0
    j L9
    LB:
    la x64_cls t0
    li 3 t1
    sd 0 t1 t0
    j LN
    LR:
    ld TY_kind s4 t1
    li TY_ARRAY t0
    beq rel:LA t0 t1
    li TY_STRUCT t0
    bne rel:LI t0 t1
    ld TY_base s4 s6
    ld NODE_children s6 s7
    lbu NODE_children_len s6 s8
    beqz L9 s8
    ld 0 s7 a0
    call kwof
    li 0 s11
    li KW_union t0
    bne rel:LS t0 a0
    li 1 s11
    LS:
    addi 8 s7 s7
    addi -1 s8 s8
    li 0 s9
    LF:
    beqz L9 s8
    ld 0 s7 s10
    ld NODE_content s10 t0
    lbu NODE_content_len s10 t1
    beqz LN t1
    add t1 t0 t0
    lbu -1 t0 t0
    li 58 t1
    bne rel:LN t1 t0
    lbu NODE_children_len s10 t0
    beqz LN t0
    ld NODE_children s10 a0
    slli 3 t0 t0
    add a0 t0 s10
    mv s10 a1
    call typerun
    bltz LM a0
    bne rel:LB s10 a1
    mv a0 s6
    bnez LU s11
    call talign
    addi -1 a0 t0
    add t0 s9 s9
    neg a0 t0
    and t0 s9 s9
    add s9 s5 a1
    mv s6 a0
    call x64eb
    mv s6 a0
    call tsize
    add a0 s9 s9
    j LN
    LU:
    mv s5 a1
    call x64eb
    LN:
    addi 8 s7 s7
    addi -1 s8 s8
    j LF
    LA:
    ld TY_count s4 s8
    ld TY_base s4 s6
    mv s6 a0
    call tsize
    mv a0 s9
    beqz L9 s9
    LA1:
    beqz L9 s8
    li 16 t0
    bge rel:L9 t0 s5
    mv s6 a0
    mv s5 a1
    call x64eb
    add s9 s5 s5
    addi -1 s8 s8
    j LA1
    L9:
    leave8
", 6);
# x64sclass a0: how a struct of type a0 goes: a0 = 2 in its eightbytes'
# registers (a1 = their count + 256 * the mask of those in xmm
# registers), 5 as a long double (a struct of one), 6 in memory
$h .= fn('x64sclass', "
    enter3
    mv a0 s4
    call tsize
    mv a0 s5
    li 16 t0
    blt rel:LM s5 t0
    la x64_cls t0
    sd 0 zero t0
    la x64_flags t0
    sd 0 zero t0
    mv s4 a0
    li 0 a1
    call x64eb
    la x64_cls t0
    ld 0 t0 t1
    la x64_flags t0
    ld 0 t0 t2
    andi 1 t2 t3
    bnez LM t3
    andi 2 t2 t3
    beqz LW t3
    bnez LM t1
    li 16 t0
    bne rel:LM t0 s5
    li 5 a0
    li 1 a1
    leave3
    LW:
    addi 7 s5 t3
    srli 3 t3 t3
    li 1 t4
    sll t3 t4 t4
    addi -1 t4 t4
    and t1 t4 t5
    sub t5 t4 t5
    slli 8 t5 t5
    or t5 t3 a1
    li 2 a0
    leave3
    LM:
    li 6 a0
    li 0 a1
    leave3
", 6);
# x64resclass a0: how a result of type a0 comes back: a0 = its class, a1
# its eightbytes (as x64sclass's) for class 3
$h .= fn('x64resclass', "
    enter1
    mv a0 s4
    lui TY_REC t0
    bgeu rel:LR t0 s4
    li 0 a1
    li 36 t0
    li 1 a0
    beq rel:L9 t0 s4
    li 40 t0
    li 2 a0
    beq rel:L9 t0 s4
    li 48 t0
    li 8 a0
    beq rel:L9 t0 s4
    li 0 a0
    leave1
    LR:
    ld TY_kind s4 t1
    li TY_STRUCT t0
    li 0 a0
    li 0 a1
    bne rel:L9 t0 t1
    mv s4 a0
    call x64sclass
    li 6 t0
    beq rel:L9 t0 a0
    li 5 t0
    bne rel:L1 t0 a0
    li 8 a0
    li 0 a1
    leave1
    L1:
    li 3 a0
    L9:
    leave1
", 6);
# x64isva a0: a0 = 1 for the type va_list (the struct of x64_vanode)
$h .= fn('x64isva', "
    lui TY_REC t0
    bltu rel:L0 t0 a0
    ld TY_kind a0 t1
    li TY_STRUCT t0
    bne rel:L0 t0 t1
    ld TY_base a0 t1
    la x64_vanode t0
    bne rel:L0 t0 t1
    li 1 a0
    ret
    L0:
    li 0 a0
    ret
", 6);
# x64class a0 a1: the place of an argument of type a1 by the state a0 (the
# general registers used, the xmm ones, the stack's bytes): a0 = its kind,
# a1 its register (2: the first general one + 256 * the first xmm one) or
# its offset on the stack, a2 its eightbytes (2, as x64sclass's a1), its
# bytes on the stack (7, 8)
$h .= fn('x64class', "
    enter8
    mv a0 s4
    mv a1 s5
    mv s5 a0
    call x64isva
    bnez LI a0
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 3 s6
    li 36 t0
    beq rel:LF t0 s5
    li 4 s6
    li 40 t0
    beq rel:LF t0 s5
    li 48 t0
    beq rel:LQ t0 s5
    j LI
    LR:
    ld TY_kind s5 t1
    li TY_STRUCT t0
    bne rel:LI t0 t1
    mv s5 a0
    call x64sclass
    li 5 t0
    beq rel:LQ t0 a0
    li 6 t0
    beq rel:LS t0 a0
    mv a1 s7
    andi 255 s7 s8
    srli 8 s7 s9
    andi 1 s9 s10
    srli 1 s9 t0
    andi 1 t0 t0
    add t0 s10 s10
    sub s10 s8 s11
    ld 0 s4 t0
    add s11 t0 t1
    li 6 t2
    blt rel:LS t1 t2
    ld 8 s4 t3
    add s10 t3 t4
    li 8 t2
    blt rel:LS t4 t2
    sd 0 t1 s4
    sd 8 t4 s4
    slli 8 t3 t3
    or t3 t0 a1
    mv s7 a2
    li 2 a0
    leave8
    LS:
    mv s5 a0
    call tsize
    addi 7 a0 s7
    andi -8 s7 s7
    mv s5 a0
    call talign
    ld 16 s4 t0
    li 16 t1
    blt rel:LS1 t1 a0
    addi 15 t0 t0
    andi -16 t0 t0
    LS1:
    add s7 t0 t1
    sd 16 t1 s4
    li 8 a0
    mv t0 a1
    mv s7 a2
    leave8
    LI:
    ld 0 s4 t0
    li 6 t1
    bge rel:LIS t1 t0
    addi 1 t0 t1
    sd 0 t1 s4
    li 1 a0
    mv t0 a1
    li 0 a2
    leave8
    LF:
    ld 8 s4 t0
    li 8 t1
    bge rel:LIS t1 t0
    addi 1 t0 t1
    sd 8 t1 s4
    mv s6 a0
    mv t0 a1
    li 0 a2
    leave8
    LIS:
    ld 16 s4 t0
    addi 8 t0 t1
    sd 16 t1 s4
    li 7 a0
    mv t0 a1
    li 8 a2
    leave8
    LQ:
    ld 8 s4 t0
    li 8 t1
    bge rel:LQS t1 t0
    addi 1 t0 t1
    sd 8 t1 s4
    li 5 a0
    mv t0 a1
    li 0 a2
    leave8
    LQS:
    ld 16 s4 t0
    addi 15 t0 t0
    andi -16 t0 t0
    addi 16 t0 t1
    sd 16 t1 s4
    li 7 a0
    mv t0 a1
    li 16 a2
    leave8
", 6);
# x64last a0 a1: a0 = 1 where eightbyte a1 of a struct of a0 bytes is its
# last and has 4 bytes or less (a 4-byte load or store)
$h .= fn('x64last', "
    slli 3 a1 t0
    sub t0 a0 t0
    li 4 t1
    blt rel:L0 t0 t1
    li 1 a0
    ret
    L0:
    li 0 a0
    ret
", 6);
# x64cpw a0 a1 a2: a2 bytes (words) of the struct whose address is at SP + a0
# to SP + a1
$h .= fn('x64cpw', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    li 0 s7
    L1:
    bge rel:L9 s6 s7
    la x64n_stkw a0
    li 3 a1
    mv s4 a2
    add s7 s5 a3
    mv s7 a4
    call a64p
    addi 8 s7 s7
    j L1
    L9:
    leave5
", 6);
# x64put0 a0 .. a4: the memory pass of an argument: its kind a0, place a1,
# type a2, a3 (x64class's a2), its pushed value at SP + a4: the stack's
# arguments
$h .= fn('x64put0', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    li 7 t0
    bne rel:L1 t0 s4
    li 8 t0
    bne rel:L0 t0 s7
    la x64n_stk a0
    li 2 a1
    mv s8 a2
    mv s5 a3
    call a64p
    leave5
    L0:
    mv s8 a0
    mv s5 a1
    li 16 a2
    call x64cpw
    leave5
    L1:
    li 8 t0
    bne rel:L9 t0 s4
    mv s8 a0
    mv s5 a1
    mv s7 a2
    call x64cpw
    L9:
    leave5
", 6);
# x64put1 a0 .. a4: the register pass of an argument (as x64put0)
$h .= fn('x64put1', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    li 1 t0
    bne rel:L2 t0 s4
    la cc_names a0
    addi 30 a0 a0
    li 2 a1
    mv s5 a2
    mv s8 a3
    call a64p
    leave8
    L2:
    li 3 t0
    la x64n_lds a0
    beq rel:L21 t0 s4
    li 4 t0
    la x64n_ldd a0
    beq rel:L21 t0 s4
    li 5 t0
    la x64n_ldq a0
    bne rel:L3 t0 s4
    L21:
    li 2 a1
    mv s5 a2
    mv s8 a3
    call a64p
    leave8
    L3:
    li 2 t0
    bne rel:L9 t0 s4
    mv s6 a0
    call tsize
    mv a0 s6
    andi 255 s5 s9
    srli 8 s5 s10
    li 0 s11
    L31:
    andi 255 s7 t0
    bge rel:L9 t0 s11
    mv s6 a0
    mv s11 a1
    call x64last
    mv a0 t2
    srli 8 s7 t0
    srl s11 t0 t0
    andi 1 t0 t0
    beqz L32 t0
    la x64n_ldsw a0
    beqz L33 t2
    la x64n_ldsl a0
    L33:
    mv s10 a2
    addi 1 s10 s10
    j L34
    L32:
    la x64n_ldxw a0
    beqz L35 t2
    la x64n_ldxl a0
    L35:
    mv s9 a2
    addi 1 s9 s9
    L34:
    li 3 a1
    mv s8 a3
    slli 3 s11 a4
    call a64p
    addi 1 s11 s11
    j L31
    L9:
    leave8
", 6);
# x64res a0 a1 a2 a3: the result of class a0, eightbytes a1, room a2 below
# FP (a temporary where there is none), type a3, where C has it: V the bits
# of a float or double, the address of its room for one that comes in
# registers as a struct or a long double, the room of one in memory; an
# integer narrower than a word extended (its upper bits are not the
# callee's to set)
$h .= fn('x64res', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    bnez L1 s4
    lui TY_REC t0
    bgeu rel:L9 t0 s7
    andi 32 s7 t0
    bnez L9 t0
    andi 15 s7 t0
    beqz L9 t0
    li 8 t1
    bge rel:L9 t1 t0
    mv s7 a0
    call narrow
    leave8
    L1:
    li 1 t0
    bne rel:L2 t0 s4
    la x64n_resf a0
    call seq
    leave8
    L2:
    li 2 t0
    bne rel:L3 t0 s4
    la x64n_resd a0
    call seq
    leave8
    L3:
    li 6 t0
    bne rel:L4 t0 s4
    bnez L31 s6
    li 0 a0
    call bad
    L31:
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    leave8
    L4:
    bnez L41 s6
    mv s7 a0
    call tsize
    li 16 t0
    bge rel:L40 a0 t0
    li 0 a0
    call bad
    L40:
    call wtemp
    mv a0 s6
    L41:
    neg s6 a0
    li R_t1 a1
    call li
    la x64n_room a0
    call seq
    li 8 t0
    bne rel:L5 t0 s4
    la x64n_rstq a0
    call seq
    j L8
    L5:
    mv s7 a0
    call tsize
    mv a0 s10
    li 0 s8
    li 0 s9
    li 0 s11
    L51:
    andi 255 s5 t0
    bge rel:L8 t0 s11
    mv s10 a0
    mv s11 a1
    call x64last
    mv a0 t2
    srli 8 s5 t0
    srl s11 t0 t0
    andi 1 t0 t0
    beqz L52 t0
    la x64n_rsts a0
    beqz L53 t2
    la x64n_rstsl a0
    L53:
    mv s9 a2
    addi 1 s9 s9
    j L54
    L52:
    la x64n_rstx a0
    beqz L55 t2
    la x64n_rstxl a0
    L55:
    slli 1 s8 a2
    addi 1 s8 s8
    L54:
    li 2 a1
    slli 3 s11 a3
    call a64p
    addi 1 s11 s11
    j L51
    L8:
    la x64n_resv a0
    call seq
    L9:
    leave8
", 6);
# x64fwd a0: under va_arg_pack, the registers this function was given past
# its named ones (kept by x64pplan) loaded again for a call of as many
# named arguments (a0 its count of arguments), al 8, r11 the call's count
$h .= fn('x64fwd', "
    enter5
    mv a0 s4
    la x64_st t0
    ld 0 t0 t0
    andi 255 t0 s5
    srli 8 t0 s6
    andi 255 s6 s6
    la abi_csave t0
    ld 0 t0 s7
    L1:
    li 6 t0
    bge rel:L2 t0 s5
    slli 3 s5 t1
    sub s7 t1 a0
    li R_t0 a1
    call li
    la x64n_fwx a0
    li 1 a1
    mv s5 a2
    call a64p
    addi 1 s5 s5
    j L1
    L2:
    li 8 t0
    bge rel:L3 t0 s6
    slli 4 s6 t1
    addi 48 t1 t1
    sub s7 t1 a0
    li R_t0 a1
    call li
    la x64n_fwq a0
    li 1 a1
    mv s6 a2
    call a64p
    addi 1 s6 s6
    j L2
    L3:
    la abi_vacnt t0
    ld 0 t0 a0
    neg a0 a0
    li R_t0 a1
    call li
    la x64_named t0
    ld 0 t0 t0
    sub t0 s4 a1
    la x64n_fwn a0
    call seq
    la x64n_al a0
    li 8 a1
    call seq
    leave5
", 6);
# x64call a0 .. a5: abicall's (a0 0: the function a1, 1: through the address
# pushed before the arguments; a2 the room of a struct or long double
# result below FP, or 0; a3 1 for a variadic function; a4 1 under
# va_arg_pack; a5 the result's type) by the SysV ABI. Its frame: the state
# at sp (32 bytes), a place per argument from sp + 32 (kind, place, type,
# x64class's a2), then a3, a4, the room below the pushed values, a5, the
# result's class and eightbytes, the stack's arguments' bytes, the pushed
# slots
$h .= fn('x64call', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    addi -1648 sp sp
    sd 1568 a3 sp
    sd 1576 a4 sp
    sd 1592 a5 sp
    sd 0 zero sp
    sd 8 zero sp
    sd 16 zero sp
    sd 24 zero sp
    mv a5 a0
    call x64resclass
    sd 1600 a0 sp
    sd 1608 a1 sp
    li 6 t0
    bne rel:L0 t0 a0
    li 1 t0
    sd 0 t0 sp
    L0:
    la pair_args t0
    ld 0 t0 s8
    ld 16 t0 t1
    sd 1624 t1 sp
    li 48 t0
    blt rel:L1 t0 s8
    li 0 a0
    call bad
    L1:
    li 0 s9
    L2:
    bge rel:L3 s8 s9
    la abi_types t0
    slli 3 s9 t1
    add t1 t0 t0
    ld 0 t0 s10
    mv sp a0
    mv s10 a1
    call x64class
    slli 5 s9 t1
    add t1 sp t1
    sd 32 a0 t1
    sd 40 a1 t1
    sd 48 s10 t1
    sd 56 a2 t1
    addi 1 s9 s9
    j L2
    L3:
    ld 1576 sp t0
    beqz L4 t0
    ld 0 sp t1
    ld 8 sp t2
    slli 8 t2 t2
    or t2 t1 t1
    ld 16 sp t2
    slli 16 t2 t2
    or t2 t1 t1
    la x64_st t0
    ld 0 t0 t0
    bne rel:LX t0 t1
    srli 16 t1 t1
    beqz L4 t1
    LX:
    li 0 a0
    call bad
    L4:
    ld 16 sp t0
    addi 15 t0 t0
    andi -16 t0 t0
    sd 1616 t0 sp
    la ccs t2
    ld CC_depth t2 t1
    add t1 t0 t3
    addi 15 t3 t3
    andi -16 t3 t3
    sub t1 t3 s10
    sd 1584 s10 sp
    beqz L5 s10
    sd CC_depth t3 t2
    call syncsp
    L5:
    li 0 s9
    L6:
    bge rel:L7 s8 s9
    slli 5 s9 t1
    add t1 sp t1
    ld 32 t1 a0
    ld 40 t1 a1
    ld 48 t1 a2
    ld 56 t1 a3
    ld 1624 sp t2
    sub s9 t2 t2
    addi -1 t2 t2
    slli 3 t2 t2
    add s10 t2 a4
    call x64put0
    addi 1 s9 s9
    j L6
    L7:
    li 0 s9
    L8:
    bge rel:L10 s8 s9
    slli 5 s9 t1
    add t1 sp t1
    ld 32 t1 a0
    ld 40 t1 a1
    ld 48 t1 a2
    ld 56 t1 a3
    ld 1624 sp t2
    sub s9 t2 t2
    addi -1 t2 t2
    slli 3 t2 t2
    add s10 t2 a4
    call x64put1
    addi 1 s9 s9
    j L8
    L10:
    ld 1600 sp t0
    li 6 t1
    bne rel:L11 t1 t0
    bnez L101 s6
    li 0 a0
    call bad
    L101:
    neg s6 a0
    li R_t0 a1
    call li
    la x64n_rdi a0
    call seq
    L11:
    ld 1576 sp t0
    beqz L12 t0
    mv s8 a0
    call x64fwd
    j L13
    L12:
    ld 1568 sp t0
    beqz L13 t0
    mv s8 a0
    li R_t1 a1
    call li
    la x64n_al a0
    ld 8 sp a1
    call seq
    L13:
    bnez LC s4
    mv s5 a0
    call label_addr
    mv a0 a1
    la cc_auipc_ra a0
    call seq
    j LD
    LC:
    ld 1624 sp t0
    slli 3 t0 t0
    add s10 t0 a1
    la x64n_callp a0
    call seq
    LD:
    ld 1624 sp t0
    add s4 t0 t0
    srli 3 s10 t1
    add t1 t0 s11
    mv s11 a0
    call popped
    slli 3 s11 a1
    srli 12 a1 t0
    bnez LE t0
    la cc_addsp a0
    call seq
    j LF
    LE:
    call syncsp
    LF:
    ld 1600 sp a0
    ld 1608 sp a1
    mv s6 a2
    ld 1592 sp a3
    call x64res
    addi 1648 sp sp
    leave8
", 6);
# x64wcall a0 a1 a2: wcall's (the soft-fp function a0 of cc_sfnames, its a1
# arguments pushed, its result's type a2) by the SysV ABI: each argument in
# its register by the function's kinds (a64sfargs: 1 a general register,
# 3 4 5 an xmm one), rsp 16-aligned at the call, the result where C has it
# (x64res; a long double's in a temporary, whose place a0 is, as wcall's)
$h .= fn('x64wcall', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    la cc_sfnames t0
    slli 4 s4 t1
    add t1 t0 s11
    mv s11 a0
    call strlen
    addi -64 sp sp
    sb NODE_children_len zero sp
    sd NODE_content s11 sp
    sb NODE_content_len a0 sp
    mv a0 a1
    mv s11 a0
    mv sp a2
    call cfind
    addi 64 sp sp
    bnez L0 a0
    li 0 a0
    call bad
    L0:
    mv a0 s7
    li 0 s8
    li 0 s9
    li 0 s10
    L1:
    bge rel:L2 s5 s8
    la a64sfargs t0
    slli 1 s4 t1
    add t1 t0 t0
    add s8 t0 t0
    lbu 0 t0 t2
    sub s8 s5 t1
    addi -1 t1 t1
    slli 3 t1 a3
    li 1 t0
    bne rel:L11 t0 t2
    la cc_names a0
    addi 30 a0 a0
    mv s9 a2
    addi 1 s9 s9
    j L13
    L11:
    la x64n_lds a0
    li 3 t0
    beq rel:L12 t0 t2
    la x64n_ldd a0
    li 4 t0
    beq rel:L12 t0 t2
    la x64n_ldq a0
    L12:
    mv s10 a2
    addi 1 s10 s10
    L13:
    li 2 a1
    call a64p
    addi 1 s8 s8
    j L1
    L2:
    li 0 s8
    la ccs t0
    ld CC_depth t0 t0
    andi 15 t0 t0
    beqz L21 t0
    li 8 s8
    la cc_addsp a0
    li -8 a1
    call seq
    L21:
    mv s7 a0
    call label_addr
    mv a0 a1
    la cc_auipc_ra a0
    call seq
    mv s5 a0
    call popped
    slli 3 s5 a1
    add s8 a1 a1
    la cc_addsp a0
    call seq
    mv s6 a0
    call x64resclass
    mv a0 s8
    mv a1 s9
    li 0 s10
    li 8 t0
    bne rel:L3 t0 s8
    call wtemp
    mv a0 s10
    L3:
    mv s8 a0
    mv s9 a1
    mv s10 a2
    mv s6 a3
    call x64res
    mv s6 a0
    call setty
    mv s10 a0
    leave8
", 6);
# x64pplan a0 a1: the places of the parameters (a1 of them, from a0) of the
# function being compiled, in abi_pplan (the state, then kind, place, type,
# x64class's a2 of each); rdi kept for a result in memory (abi_sret), the
# registers of the arguments (cc_x64_save, abi_csave) where a parameter is
# a struct in registers or a long double, or the function is variadic; the
# state after the named ones in x64_st (the general registers, the xmm ones
# << 8, the stack's bytes << 16), their count in x64_named
$h .= fn('x64pplan', "
    enter8
    mv a0 s4
    mv a1 s5
    la abi_pplan s6
    sd 0 zero s6
    sd 8 zero s6
    sd 16 zero s6
    sd 24 zero s6
    la abi_csave t0
    sd 0 zero t0
    la ccs t0
    ld CC_rty t0 a0
    call x64resclass
    li 6 t0
    bne rel:L1 t0 a0
    la x64n_pushrdi a0
    li 1 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_sret t0
    sd 0 t1 t0
    li 1 t0
    sd 0 t0 s6
    L1:
    la ccs t0
    ld CC_va t0 s9
    beqz L2 s9
    la x64n_pushr11 a0
    li 1 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_vacnt t0
    sd 0 t1 t0
    L2:
    la x64_named t0
    sd 0 s5 t0
    li 0 s7
    L3:
    beqz L5 s5
    ld 0 s4 a0
    lbu NODE_children_len a0 t0
    ld NODE_children a0 a0
    slli 3 t0 t0
    add a0 t0 a1
    call typerun
    mv a0 s8
    mv a0 a1
    mv s6 a0
    call x64class
    li 64 t0
    bge rel:L4 t0 s7
    slli 5 s7 t1
    add t1 s6 t1
    sd 32 a0 t1
    sd 40 a1 t1
    sd 48 s8 t1
    sd 56 a2 t1
    L4:
    li 2 t0
    beq rel:L41 t0 a0
    li 5 t0
    bne rel:L42 t0 a0
    L41:
    li 1 s9
    L42:
    addi 1 s7 s7
    addi 8 s4 s4
    addi -1 s5 s5
    j L3
    L5:
    ld 0 s6 t0
    ld 8 s6 t1
    slli 8 t1 t1
    or t1 t0 t0
    ld 16 s6 t1
    slli 16 t1 t1
    or t1 t0 t0
    la x64_st t1
    sd 0 t0 t1
    beqz L9 s9
    la x64n_save a0
    li 22 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_csave t0
    sd 0 t1 t0
    L9:
    leave8
", 6);
# x64pparam a0 a1: V = parameter a0 (the variable a1): from its register (or
# its save), the stack above FP; a long double's, a struct's on the stack:
# the address of its bytes; a struct's in registers: its eightbytes stored
# in its variable (V its address); a va_list's: the address its register
# holds (the caller's va_list, which the variable copies)
$h .= fn('x64pparam', "
    enter8
    mv a0 s4
    mv a1 s5
    la abi_pplan t0
    slli 5 s4 t1
    add t1 t0 t0
    ld 32 t0 s6
    ld 40 t0 s7
    ld 56 t0 s10
    ld VAR_type s5 s8
    la abi_csave t0
    ld 0 t0 s9
    li 1 t0
    bne rel:L2 t0 s6
    bnez L11 s9
    la cc_param a0
    mv s7 a1
    call seq
    leave8
    L11:
    slli 3 s7 t0
    sub t0 s9 a0
    j LL
    L2:
    li 3 t0
    beq rel:L3 t0 s6
    li 4 t0
    bne rel:L5 t0 s6
    L3:
    bnez L31 s9
    la x64n_pf a0
    li 3 t0
    beq rel:L32 t0 s6
    la x64n_pd a0
    L32:
    mv s7 a1
    call seq
    leave8
    L31:
    slli 4 s7 t0
    addi 48 t0 t0
    sub t0 s9 a0
    j LL
    L5:
    li 5 t0
    bne rel:L6 t0 s6
    slli 4 s7 t0
    addi 48 t0 t0
    sub t0 s9 a0
    j LA
    L6:
    li 2 t0
    bne rel:L80 t0 s6
    ld VAR_off s5 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s8 a0
    call tsize
    mv a0 s8
    andi 255 s7 s4
    srli 8 s7 s7
    li 0 s6
    L61:
    andi 255 s10 t0
    bge rel:L69 t0 s6
    srli 8 s10 t0
    srl s6 t0 t0
    andi 1 t0 t0
    beqz L62 t0
    slli 4 s7 t0
    addi 48 t0 t0
    addi 1 s7 s7
    j L63
    L62:
    slli 3 s4 t0
    addi 1 s4 s4
    L63:
    sub s9 t0 a0
    li R_t0 a1
    call li
    mv s8 a0
    mv s6 a1
    call x64last
    mv a0 t2
    la x64n_vh a0
    beqz L64 t2
    la x64n_vhl a0
    L64:
    li 1 a1
    slli 3 s6 a2
    call a64p
    addi 1 s6 s6
    j L61
    L69:
    leave8
    L80:
    call argoff
    add a0 s7 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li 7 t0
    bne rel:L69 t0 s6
    mv s8 a0
    call inmem
    beqz L81 a0
    li 16 t0
    beq rel:L69 t0 s10
    li TY_LONG s8
    L81:
    mv s8 a0
    call load
    leave8
    LL:
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s8 a0
    call inmem
    beqz LL1 a0
    li TY_LONG s8
    LL1:
    mv s8 a0
    call load
    leave8
    LA:
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    leave8
", 6);
# x64retf a0: the result V of type a0 where the ABI has it (a0 = 1: xmm0,
# rax rdx xmm0 xmm1, a struct in memory copied through the address rdi
# gave, rax that address), or where C had it (a0 = 0: rax)
$h .= fn('x64retf', "
    enter8
    mv a0 s4
    call x64resclass
    mv a0 s5
    mv a1 s6
    li 1 t0
    la x64n_retf a0
    beq rel:L7 t0 s5
    li 2 t0
    la x64n_retd a0
    beq rel:L7 t0 s5
    li 8 t0
    la x64n_retq a0
    beq rel:L7 t0 s5
    li 6 t0
    beq rel:LM t0 s5
    li 3 t0
    bne rel:L8 t0 s5
    la x64n_retb a0
    call seq
    mv s4 a0
    call tsize
    mv a0 s10
    li 0 s7
    li 0 s8
    li 0 s9
    L51:
    andi 255 s6 t0
    bge rel:L9 t0 s9
    mv s10 a0
    mv s9 a1
    call x64last
    mv a0 t2
    srli 8 s6 t0
    srl s9 t0 t0
    andi 1 t0 t0
    beqz L52 t0
    la x64n_rets a0
    beqz L53 t2
    la x64n_retsl a0
    L53:
    mv s8 a2
    addi 1 s8 s8
    j L54
    L52:
    la x64n_retx a0
    beqz L55 t2
    la x64n_retxl a0
    L55:
    slli 1 s7 a2
    addi 1 s7 s7
    L54:
    li 2 a1
    slli 3 s9 a3
    call a64p
    addi 1 s9 s9
    j L51
    LM:
    call push
    la ccs t0
    ld CC_depth t0 s5
    call abisret
    call push
    call popt0
    mv s5 a0
    call fpword
    mv s4 a0
    call copytype
    call popt0
    call abisret
    j L9
    L7:
    call seq
    L9:
    li 1 a0
    leave8
    L8:
    li 0 a0
    leave8
", 6);
# x64vastart a0: va_start of the va_list a0 (its address in V): the
# registers' offsets past the named arguments, the stack past them, the
# save
$h .= fn('x64vastart', "
    enter3
    call addr
    la x64_st t0
    ld 0 t0 s4
    andi 255 s4 t0
    slli 3 t0 a2
    srli 8 s4 t0
    andi 255 t0 t0
    slli 4 t0 t0
    addi 48 t0 a3
    la x64n_vas1 a0
    li 2 a1
    call a64p
    call argoff
    srli 16 s4 t0
    add t0 a0 a2
    la abi_csave t0
    ld 0 t0 a3
    neg a3 a3
    la x64n_vas2 a0
    li 2 a1
    call a64p
    li TY_LONG a0
    call setty
    leave3
", 6);
# x64vaarg a0 a1: va_arg of the va_list a0, type a1, by the ABI (a0 = 1): the
# argument's address from the registers' save or the stack (cc_x64_vax
# ...), then its value; a struct's, a long double's V its address (a
# struct of a general and an xmm register, or of two xmm ones, is not
# there yet)
$h .= fn('x64vaarg', "
    enter5
    mv a0 s4
    mv a1 s5
    addi -32 sp sp
    sd 0 zero sp
    sd 8 zero sp
    sd 16 zero sp
    sd 24 zero sp
    mv sp a0
    mv s5 a1
    call x64class
    addi 32 sp sp
    mv a0 s6
    mv a2 s7
    mv s4 a0
    call addr
    li 1 t0
    beq rel:LX t0 s6
    li 3 t0
    beq rel:LV t0 s6
    li 4 t0
    beq rel:LV t0 s6
    li 5 t0
    beq rel:LQ t0 s6
    li 2 t0
    beq rel:LW t0 s6
    li 8 t0
    beq rel:LM t0 s6
    mv s4 a0
    call bad
    LX:
    la x64n_vax a0
    li 41 a2
    li 8 a3
    li 8 a4
    j LP
    LV:
    la x64n_vav a0
    li 161 a2
    li 16 a3
    li 8 a4
    j LP
    LQ:
    la x64n_vav16 a0
    li 1 a1
    li 161 a2
    call a64p
    j LY
    LW:
    srli 8 s7 t0
    bnez LW1 t0
    andi 255 s7 t0
    slli 3 t0 a3
    li 49 a2
    sub a3 a2 a2
    mv a3 a4
    la x64n_vax a0
    j LP
    LW1:
    li 1 t1
    bne rel:LW2 t1 t0
    andi 255 s7 t0
    beq rel:LV t1 t0
    LW2:
    mv s4 a0
    call bad
    LM:
    mv s5 a0
    call talign
    mv a0 t1
    li 16 t0
    la x64n_vam a0
    blt rel:LM1 t0 t1
    la x64n_vam16 a0
    LM1:
    li 1 a1
    mv s7 a2
    call a64p
    j LY
    LP:
    li 3 a1
    call a64p
    LY:
    mv s5 a0
    call inmem
    bnez LZ a0
    mv s5 a0
    call load
    LZ:
    mv s5 a0
    call setty
    li 1 a0
    leave5
", 6);
# x64vacopy a0: va_copy, the 24 bytes of the ABI's va_list
$h .= fn('x64vacopy', "
    enter2
    mv a0 s4
    lbu NODE_children_len s4 t0
    li 2 t1
    bne rel:L8 t1 t0
    ld NODE_children s4 s5
    ld 0 s5 a0
    call addr
    call push
    ld 8 s5 a0
    call addr
    call popt0
    call x64valist
    call copytype
    li TY_LONG a0
    call setty
    leave2
    L8:
    mv s4 a0
    call bad
", 6);
# x64vapackm: V = va_arg_pack_len, the count of the arguments past the named
# ones (r11, kept by x64pplan: a ttpc caller's)
$h .= fn('x64vapackm', "
    enter1
    la abi_vacnt t0
    ld 0 t0 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li TY_LONG a0
    call load
    la x64_named t0
    ld 0 t0 a0
    neg a0 a0
    li R_t1 a1
    call li
    la cc_add_t1 a0
    call seq
    leave1
", 6);
# x64valist: a0 = the type of va_list, the ABI's struct of 24 bytes (the
# struct of the node x64_vanode, made once in each compilation)
$h .= fn('x64valist', "
    la x64_vanode a0
    j struct
", 6);
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
# the primitives' names: a seq's with its count of numbers first
my @seqn = qw(resf resd room rstq resv entry pushrdi pushr11 save retf retd retq retb rdi);
my @seq1 = qw(callp pf pd al fwn);
my @prim = qw(lds ldd ldq ldxw ldxl ldsw ldsl stk stkw fwx fwq rstx rstxl rsts rstsl vh vhl retx retxl rets retsl vas1 vas2 vax vav vav16 vam vam16);
for my $x ((map { [$_, "\0cc_x64_$_\0"] } @seqn), (map { [$_, "\x01cc_x64_$_\0"] } @seq1), (map { [$_, "cc_x64_$_\0"] } @prim)) {
    my ($l, $b) = @$x;
    $b .= "\0" x (-length($b) % 8);
    $h .= "      x64n_$l:\n        ascii\n          " . esc($b) . "\n";
}
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $h;
}
save();
