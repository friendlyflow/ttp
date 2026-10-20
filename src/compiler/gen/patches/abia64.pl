# abia64.pl: calls by AAPCS64 as Linux has it, aarch64's cc_abi 2 (the
# user's choice, 2026-10-19: ttpc follows each platform's C ABI for every
# call), on the mechanism of abi.pl and abi3.pl. Each of their hooks goes
# to a function of its own here where the target's ABI is 2 (and not at
# compile time): abicall a64call, abipplan a64pplan, abipparam a64pparam,
# abiretf a64retf, abiresclass a64resclass, abivaarg a64vaarg, abivapush
# (nothing), abivapackm a64vapackm, abiseq (the plain prologue), vacopy
# a64vacopy; vastart a64vastart, tyname's va_list a64valist, hfa's long
# double.
#
# The classification (a64class, for a call's arguments and a function's
# parameters alike): by the state NGRN, NSRN, NSAA (and the bytes of large
# structs' copies), an argument's kind: 1 an x register, 2 a struct of one
# or two words in x registers (a struct aligned to 16 from an even one), 3
# 4 5 a float, double, long double in an s, d, q register, 6 an hfa (one
# to four floats, doubles or long doubles: abi3.pl's hfa) in consecutive
# ones, 7 a scalar on the stack (8 bytes; a long double 16, aligned), 8 a
# struct on the stack (its words), 9 10 a struct of more than 16 bytes
# copied by the caller, its address in an x register or on the stack. Past
# the registers of its class an argument goes on the stack, and so do all
# later ones of that class (NGRN or NSRN 8). A variadic function's
# arguments go the same way (Linux's AAPCS64).
#
# A result (a64resclass): 0 x0, 1 s0, 2 d0, 8 q0, 3 a struct of 16 bytes or
# less in x0 (x1), 4 5 9 an hfa in s0.. d0.. q0.., 6 in memory at x8 (the
# room the caller gives). A call (a64call) evaluates and pushes its
# arguments as before, classifies them, makes room below them for the
# stack's arguments and large structs' copies (sp 16-aligned), copies those
# (the first pass: x16 and x17 only), loads the registers (the second
# pass), x8, x9 (a variadic callee's count of arguments, for
# va_arg_pack_len) and calls; the result where C has it (a64res: a float's
# bits in V, a struct's or long double's address in V, its room). The
# callee (a64pplan) keeps x8 and x9 where it needs them, and x0..x7 and
# q0..q7 in its frame where a parameter is a struct, a long double or an
# hfa, or the function is variadic (its va_list's register save areas);
# a64pparam finds each parameter in its register, that save, or the stack
# above FP. va_list is AAPCS64's struct (32 bytes, a64valist), va_start
# and va_arg as AAPCS64 has them (cc_a64_vas1, cc_a64_vax ...).
# va_arg_pack passes on the registers the function was given beyond its
# named ones (a call with as many named ones of each class, none on the
# stack). Run on ttpc.ff after abi3.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# ---- the hooks: where the ABI is 2 and not at compile time, function f
# goes on in function g, with its arguments as they are
my $is64 = "
    la targ_abi t0
    ld 0 t0 t0
    addi -2 t0 t0
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
    $blk =~ /^( *)\Q$f\E:\n/ or die "abia64: no $f\n";
    my $i = length($1) + 2;
    $blk =~ s/^( *\Q$f\E:\n)/$1 . asm($i, "$is64\n bnez LA64 t0")/e;
    $blk .= asm($i, "LA64:\n j $g");
    substr($t, $from, $to - $from) = $blk;
}
hook('abicall', 'a64call');
hook('abipplan', 'a64pplan');
hook('abipparam', 'a64pparam');
hook('abiretf', 'a64retf');
hook('abiresclass', 'a64resclass');
hook('abivaarg', 'a64vaarg');
hook('abivapush', 'a64nop');
hook('abivapackm', 'a64vapackm');
hook('abiseq', 'a64seq');
hook('vacopy', 'a64vacopy');

# vastart: AAPCS64's va_list filled in (V the address of ap)
E('cc/vastart', 8, "
    ld CC_va t0 t1
    beqz L8 t1
", "
    ld CC_va t0 t1
    beqz L8 t1
    la targ_abi t1
    ld 0 t1 t1
    addi -2 t1 t1
    seqz t1 t1
    la ccs t2
    ld CC_jit t2 t2
    seqz t2 t2
    and t2 t1 t1
    bnez LVA t1
");
{
    my ($from, $to) = find(\$t, 'cc/vastart');
    substr($t, $to, 0) = asm(8, "
        LVA:
        mv s4 a0
        call a64vastart
        leave1
    ");
}
# tyname: va_list is AAPCS64's struct
E('cc/tyname', 8, "
    call lookup
    bltz L1 a0
", "
    call lookup
    bltz L1 a0
    li 14 t0
    beq rel:LVA t0 a0
");
{
    my ($from, $to) = find(\$t, 'cc/tyname');
    substr($t, $to, 0) = asm(8, "
        LVA:
        la targ_abi t0
        ld 0 t0 t0
        li 2 t1
        bne rel:L5 t1 t0
        la ccs t0
        ld CC_jit t0 t0
        bnez L5 t0
        call a64valist
        leave1
    ");
}
# hfa: an aggregate of long doubles too (AAPCS64's quad precision)
E('cc/hfa', 10, "
    li 40 t0
    beq rel:L9 t0 s4
", "
    li 40 t0
    beq rel:L9 t0 s4
    la targ_abi t0
    ld 0 t0 t0
    li 2 t1
    bne rel:L0 t1 t0
    li 48 t0
    beq rel:L9 t0 s4
");

# ---- the state: data after abi_xn; va_list's struct, a64_vanode: nodes
# (hash, children_len, children, content_len, content) as its definition
# would be: struct, __stack __gr_top __vr_top (long), __gr_offs __vr_offs
# (int)
$t =~ /^( *)abi_xn:\n\1  dword\n\1    0\n/m or die "abia64: no abi_xn\n";
my $vi = $1;
sub dwords { my ($l, @v) = @_; "$vi$l:\n" . join('', map { "$vi  " . ($_ =~ /^r(\d+)$/ ? "reserve\n$vi    $1\n" : "dword\n$vi    $_\n") } @v) }
sub text { my ($l, $s) = @_; my $b = $s . "\0" x (-length($s) % 8 || 8); $b =~ s/\0/\\x00/g; "$vi$l:\n$vi  ascii\n$vi    $b\n" }
my @f = (['__stack:', 'long'], ['__gr_top:', 'long'], ['__vr_top:', 'long'], ['__gr_offs:', 'int'], ['__vr_offs:', 'int']);
my $nodes = dwords('a64_vanode', 'r32', 1 + @f, 'a64_vakids', 0, 0)
    . dwords('a64_vakids', 'a64_vakw', map { "a64_vaf$_" } 1 .. @f)
    . dwords('a64_vakw', 'r32', 0, 0, 6, 'a64_vas0')
    . join('', map { my $k = $_ + 1; dwords("a64_vaf$k", 'r32', 1, "a64_vafk$k", length $f[$_][0], "a64_vas$k") . dwords("a64_vafk$k", "a64_vat_$f[$_][1]") } 0 .. $#f)
    . dwords('a64_vat_long', 'r32', 0, 0, 4, 'a64_vasl') . dwords('a64_vat_int', 'r32', 0, 0, 3, 'a64_vasi')
    . text('a64_vas0', 'struct') . join('', map { text("a64_vas" . ($_ + 1), $f[$_][0]) } 0 .. $#f)
    . text('a64_vasl', 'long') . text('a64_vasi', 'int');
once(\$t, "${vi}abi_xn:\n$vi  dword\n$vi    0\n", "${vi}abi_xn:\n$vi  dword\n$vi    0\n"
    . join('', map { "$vi$_:\n$vi  dword\n$vi    0\n" } qw(a64_st a64_named a64_vsave)) . $nodes, 'abi_xn');

# ---- the functions, in cc's layer 3
my $h = '';
# a64p a0 a1 a2 a3 a4: the primitive a0 with a1 numbers (a2 ...)
$h .= fn('a64p', "
    li 0 a5
    j prim
", 6);
$h .= fn('a64nop', "
    ret
", 6);
# a64seq a0 a1 a2: seq a1 (a variadic function's prologue is the plain one)
$h .= fn('a64seq', "
    mv a1 a0
    j seq
", 6);
# a64resclass a0: how a result of type a0 comes back: a0 = its class, a1 its
# count (a struct's words, an hfa's elements)
$h .= fn('a64resclass', "
    enter3
    mv a0 s4
    lui TY_REC t0
    bgeu rel:LR t0 s4
    li 1 a1
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
    leave3
    LR:
    ld TY_kind s4 t1
    li TY_STRUCT t0
    li 0 a0
    li 0 a1
    bne rel:L9 t0 t1
    mv s4 a0
    call hfa
    beqz LS a0
    mv a1 s5
    li 36 t0
    li 4 s6
    beq rel:LH t0 a0
    li 40 t0
    li 5 s6
    beq rel:LH t0 a0
    li 9 s6
    LH:
    mv s6 a0
    mv s5 a1
    leave3
    LS:
    mv s4 a0
    call tsize
    li 16 t0
    blt rel:LM a0 t0
    addi 7 a0 a1
    srli 3 a1 a1
    li 3 a0
    leave3
    LM:
    li 6 a0
    li 0 a1
    L9:
    leave3
", 6);
# a64class a0 a1: the place of an argument of type a1 by the state a0 (NGRN,
# NSRN, NSAA, the bytes of the copies): a0 = its kind, a1 its register or
# its offset on the stack, a2 its words (2), its count and element's size
# (6: count + 256 * size), its bytes on the stack (7, 8), its copy's offset
# (9, 10)
$h .= fn('a64class', "
    enter8
    mv a0 s4
    mv a1 s5
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 3 s6
    li 36 t0
    beq rel:LF t0 s5
    li 4 s6
    li 40 t0
    beq rel:LF t0 s5
    li 5 s6
    li 48 t0
    beq rel:LF t0 s5
    j LI
    LR:
    ld TY_kind s5 t1
    li TY_STRUCT t0
    bne rel:LI t0 t1
    mv s5 a0
    call hfa
    bnez LH a0
    mv s5 a0
    call tsize
    mv a0 s7
    li 16 t0
    blt rel:LB a0 t0
    addi 7 s7 s8
    srli 3 s8 s8
    mv s5 a0
    call talign
    mv a0 s9
    ld 0 s4 t0
    li 16 t1
    bne rel:LX1 t1 s9
    addi 1 t0 t0
    andi -2 t0 t0
    LX1:
    add s8 t0 t1
    li 8 t2
    blt rel:LXS t1 t2
    sd 0 t1 s4
    li 2 a0
    mv t0 a1
    mv s8 a2
    leave8
    LXS:
    li 8 t1
    sd 0 t1 s4
    ld 16 s4 t0
    addi 7 t0 t0
    andi -8 t0 t0
    li 16 t1
    bne rel:LX3 t1 s9
    addi 15 t0 t0
    andi -16 t0 t0
    LX3:
    slli 3 s8 t1
    add t1 t0 t2
    sd 16 t2 s4
    li 8 a0
    mv t0 a1
    mv t1 a2
    leave8
    LB:
    ld 24 s4 t0
    addi 15 t0 t0
    andi -16 t0 t0
    mv t0 s9
    addi 7 s7 t1
    andi -8 t1 t1
    add t1 t0 t0
    sd 24 t0 s4
    ld 0 s4 t0
    li 8 t1
    bge rel:LBS t1 t0
    addi 1 t0 t1
    sd 0 t1 s4
    li 9 a0
    mv t0 a1
    mv s9 a2
    leave8
    LBS:
    ld 16 s4 t0
    addi 7 t0 t0
    andi -8 t0 t0
    addi 8 t0 t1
    sd 16 t1 s4
    li 10 a0
    mv t0 a1
    mv s9 a2
    leave8
    LI:
    ld 0 s4 t0
    li 8 t1
    bge rel:LIS t1 t0
    addi 1 t0 t1
    sd 0 t1 s4
    li 1 a0
    mv t0 a1
    li 0 a2
    leave8
    LIS:
    ld 16 s4 t0
    addi 7 t0 t0
    andi -8 t0 t0
    addi 8 t0 t1
    sd 16 t1 s4
    li 7 a0
    mv t0 a1
    li 8 a2
    leave8
    LF:
    ld 8 s4 t0
    li 8 t1
    bge rel:LFS t1 t0
    addi 1 t0 t1
    sd 8 t1 s4
    mv s6 a0
    mv t0 a1
    li 0 a2
    leave8
    LFS:
    li 8 a2
    li 5 t1
    bne rel:LF1 t1 s6
    li 16 a2
    LF1:
    ld 16 s4 t0
    addi -1 a2 t1
    add t1 t0 t0
    neg a2 t1
    and t1 t0 t0
    add a2 t0 t1
    sd 16 t1 s4
    li 7 a0
    mv t0 a1
    leave8
    LH:
    mv a1 s8
    li 4 s9
    li 36 t0
    beq rel:LH1 t0 a0
    li 8 s9
    li 40 t0
    beq rel:LH1 t0 a0
    li 16 s9
    LH1:
    ld 8 s4 t0
    add s8 t0 t1
    li 8 t2
    blt rel:LHS t1 t2
    sd 8 t1 s4
    slli 8 s9 a2
    add s8 a2 a2
    li 6 a0
    mv t0 a1
    leave8
    LHS:
    li 8 t1
    sd 8 t1 s4
    mv s5 a0
    call tsize
    addi 7 a0 s7
    andi -8 s7 s7
    mv s5 a0
    call talign
    ld 16 s4 t0
    addi 7 t0 t0
    andi -8 t0 t0
    li 16 t1
    blt rel:LH2 t1 a0
    addi 15 t0 t0
    andi -16 t0 t0
    LH2:
    add s7 t0 t1
    sd 16 t1 s4
    li 8 a0
    mv t0 a1
    mv s7 a2
    leave8
", 6);
# a64cpw a0 a1 a2: a2 bytes (words) of the struct whose address is at SP + a0
# to SP + a1
$h .= fn('a64cpw', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    li 0 s7
    L1:
    bge rel:L9 s6 s7
    la a64n_stkw a0
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
# a64put0 a0 .. a5: the memory pass of an argument: its kind a0, place a1,
# type a2, a3 (a64class's a2), its pushed value at SP + a4, the copies at SP
# + a5: the stack's arguments and the large structs' copies
$h .= fn('a64put0', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
    li 7 t0
    bne rel:L1 t0 s4
    li 8 t0
    bne rel:L0 t0 s7
    la a64n_stk a0
    li 2 a1
    mv s8 a2
    mv s5 a3
    call a64p
    leave8
    L0:
    mv s8 a0
    mv s5 a1
    li 16 a2
    call a64cpw
    leave8
    L1:
    li 8 t0
    bne rel:L2 t0 s4
    mv s8 a0
    mv s5 a1
    mv s7 a2
    call a64cpw
    leave8
    L2:
    li 9 t0
    beq rel:L3 t0 s4
    li 10 t0
    bne rel:L9 t0 s4
    L3:
    mv s6 a0
    call tsize
    addi 7 a0 a2
    andi -8 a2 a2
    add s9 s7 a1
    mv s8 a0
    call a64cpw
    li 10 t0
    bne rel:L9 t0 s4
    la a64n_stadr a0
    li 2 a1
    add s9 s7 a2
    mv s5 a3
    call a64p
    L9:
    leave8
", 6);
# a64put1 a0 .. a5: the register pass of an argument (as a64put0)
$h .= fn('a64put1', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
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
    li 2 t0
    bne rel:L3 t0 s4
    li 0 s10
    L21:
    bge rel:L9 s7 s10
    la a64n_ldxw a0
    li 3 a1
    add s10 s5 a2
    mv s8 a3
    slli 3 s10 a4
    call a64p
    addi 1 s10 s10
    j L21
    L3:
    li 3 t0
    la a64n_lds a0
    beq rel:L31 t0 s4
    li 4 t0
    la a64n_ldd a0
    beq rel:L31 t0 s4
    li 5 t0
    la a64n_ldq a0
    bne rel:L4 t0 s4
    L31:
    li 2 a1
    mv s5 a2
    mv s8 a3
    call a64p
    leave8
    L4:
    li 6 t0
    bne rel:L5 t0 s4
    andi 255 s7 s10
    srli 8 s7 s11
    li 0 s7
    L41:
    bge rel:L9 s10 s7
    la a64n_ldsw a0
    li 4 t0
    beq rel:L42 t0 s11
    la a64n_lddw a0
    li 8 t0
    beq rel:L42 t0 s11
    la a64n_ldqw a0
    L42:
    li 3 a1
    add s7 s5 a2
    mv s8 a3
    mul s11 s7 a4
    call a64p
    addi 1 s7 s7
    j L41
    L5:
    li 9 t0
    bne rel:L9 t0 s4
    la a64n_adr a0
    li 2 a1
    mv s5 a2
    add s9 s7 a3
    call a64p
    L9:
    leave8
", 6);
# a64res a0 a1 a2 a3: the result of class a0, count a1, room a2 below FP (a
# temporary where there is none), type a3, where C has it: V the bits of a
# float or double, the address of its room for one that comes in registers
# as a struct or a long double, the room of one in memory; an integer
# narrower than a word extended (its upper bits are not the callee's to set)
$h .= fn('a64res', "
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
    la a64n_resf a0
    call seq
    leave8
    L2:
    li 2 t0
    bne rel:L3 t0 s4
    la a64n_resd a0
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
    la a64n_room a0
    call seq
    li 3 t0
    bne rel:L5 t0 s4
    li 0 s8
    L42:
    bge rel:L8 s5 s8
    la a64n_rstx a0
    li 2 a1
    mv s8 a2
    slli 3 s8 a3
    call a64p
    addi 1 s8 s8
    j L42
    L5:
    li 8 t0
    bne rel:L6 t0 s4
    li 1 s5
    li 9 s4
    L6:
    la a64n_rsts s9
    li 4 s10
    li 4 t0
    beq rel:L61 t0 s4
    la a64n_rstd s9
    li 8 s10
    li 5 t0
    beq rel:L61 t0 s4
    la a64n_rstq s9
    li 16 s10
    L61:
    li 0 s8
    L62:
    bge rel:L8 s5 s8
    mv s9 a0
    li 2 a1
    mv s8 a2
    mul s10 s8 a3
    call a64p
    addi 1 s8 s8
    j L62
    L8:
    la a64n_resv a0
    call seq
    L9:
    leave8
", 6);
# a64fwd a0: under va_arg_pack, the registers this function was given past
# its named ones (kept by a64pplan) loaded again for a call of a0 named
# arguments, x9 the count of the call's
$h .= fn('a64fwd', "
    enter5
    mv a0 s4
    la a64_st t0
    ld 0 t0 t0
    andi 255 t0 s5
    srli 8 t0 s6
    andi 255 s6 s6
    L1:
    li 8 t0
    bge rel:L2 t0 s5
    la abi_csave t0
    ld 0 t0 t0
    slli 3 s5 t1
    sub t1 t0 a0
    neg a0 a0
    li R_t0 a1
    call li
    la a64n_fwx a0
    li 1 a1
    mv s5 a2
    call a64p
    addi 1 s5 s5
    j L1
    L2:
    li 8 t0
    bge rel:L3 t0 s6
    la a64_vsave t0
    ld 0 t0 t0
    slli 4 s6 t1
    sub t1 t0 a0
    neg a0 a0
    li R_t0 a1
    call li
    la a64n_fwq a0
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
    la a64_named t0
    ld 0 t0 t0
    sub t0 s4 a0
    li R_t1 a1
    call li
    la a64n_fwn a0
    call seq
    leave5
", 6);
# a64call a0 .. a5: abicall's (a0 0: the function a1, 1: through the address
# pushed before the arguments; a2 the room of a struct or long double result
# below FP, or 0; a3 1 for a variadic function; a4 1 under va_arg_pack; a5
# the result's type) by AAPCS64. Its frame: the state at sp (32 bytes), a
# place per argument from sp + 32 (kind, place, type, a64class's a2), then
# a3, a4, the room below the pushed values, a5, the result's class and
# count, the copies' offset, the pushed slots
$h .= fn('a64call', "
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
    call a64resclass
    sd 1600 a0 sp
    sd 1608 a1 sp
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
    call a64class
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
    la a64_st t0
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
    ld 24 sp t1
    add t1 t0 t0
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
    slli 4 t2 t2
    add s10 t2 a4
    ld 1616 sp a5
    call a64put0
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
    slli 4 t2 t2
    add s10 t2 a4
    ld 1616 sp a5
    call a64put1
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
    la a64n_x8 a0
    call seq
    L11:
    ld 1576 sp t0
    beqz L12 t0
    mv s8 a0
    call a64fwd
    j L13
    L12:
    ld 1568 sp t0
    beqz L13 t0
    mv s8 a0
    li R_t0 a1
    call li
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
    slli 4 t0 t0
    add s10 t0 a1
    la a64n_callp a0
    call seq
    LD:
    ld 1624 sp t0
    add s4 t0 t0
    srli 4 s10 t1
    add t1 t0 s11
    mv s11 a0
    call popped
    slli 4 s11 a1
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
    call a64res
    addi 1648 sp sp
    leave8
", 6);
# a64pplan a0 a1: the places of the parameters (a1 of them, from a0) of the
# function being compiled, in abi_pplan (the state, then kind, place, type,
# a64class's a2 of each); x8 kept for a result in memory (abi_sret), x9 for
# a variadic function (abi_vacnt), x0..x7 (abi_csave) where a parameter is
# a struct or V (x0) is needed before x0's parameter is read, q0..q7
# (a64_vsave) where one is a long double or an hfa, both where the function
# is variadic; the state after the named ones in a64_st (NGRN,
# NSRN << 8, NSAA << 16), their count in a64_named
$h .= fn('a64pplan', "
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
    la a64_vsave t0
    sd 0 zero t0
    la ccs t0
    ld CC_rty t0 a0
    call a64resclass
    li 6 t0
    bne rel:L1 t0 a0
    la a64n_pushx8 a0
    li 1 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_sret t0
    sd 0 t1 t0
    L1:
    la ccs t0
    ld CC_va t0 s9
    mv s9 s10
    beqz L2 s9
    la a64n_pushx9 a0
    li 1 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_vacnt t0
    sd 0 t1 t0
    L2:
    la a64_named t0
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
    call a64class
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
    li 9 t0
    beq rel:L41 t0 a0
    li 5 t0
    beq rel:L43 t0 a0
    li 6 t0
    beq rel:L43 t0 a0
    li 1 t0
    bne rel:L42 t0 a0
    bnez L42 a1
    beqz L42 s7
    L41:
    li 1 s9
    j L42
    L43:
    li 1 s10
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
    la a64_st t1
    sd 0 t0 t1
    beqz L8 s9
    la a64n_savex a0
    li 4 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_csave t0
    sd 0 t1 t0
    L8:
    beqz L9 s10
    la a64n_saveq a0
    li 8 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la a64_vsave t0
    sd 0 t1 t0
    L9:
    leave8
", 6);
# a64pparam a0 a1: V = parameter a0 (the variable a1): from its register (or
# its save), the stack above FP; a struct's, a long double's: the address of
# its bytes (the save, the stack, the caller's copy); an hfa's elements
# stored in its variable (V its address)
$h .= fn('a64pparam', "
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
    la a64_vsave t0
    ld 0 t0 s11
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
    bnez L31 s11
    la a64n_pf a0
    li 3 t0
    beq rel:L32 t0 s6
    la a64n_pd a0
    L32:
    mv s7 a1
    call seq
    leave8
    L31:
    slli 4 s7 t0
    sub t0 s11 a0
    j LL
    L5:
    li 5 t0
    bne rel:L6 t0 s6
    slli 4 s7 t0
    sub t0 s11 a0
    j LA
    L6:
    li 2 t0
    bne rel:L7 t0 s6
    slli 3 s7 t0
    sub t0 s9 a0
    j LA
    L7:
    li 9 t0
    bne rel:L8 t0 s6
    slli 3 s7 t0
    sub t0 s9 a0
    li TY_LONG s8
    j LL
    L8:
    li 6 t0
    bne rel:L80 t0 s6
    ld VAR_off s5 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    andi 255 s10 s4
    srli 8 s10 s10
    li 0 s6
    L81:
    bge rel:L89 s4 s6
    add s6 s7 t0
    slli 4 t0 t0
    sub t0 s11 a0
    neg a0 a0
    li R_t0 a1
    call li
    la a64n_vhs a0
    li 4 t0
    beq rel:L82 t0 s10
    la a64n_vhd a0
    li 8 t0
    beq rel:L82 t0 s10
    la a64n_vhq a0
    L82:
    li 1 a1
    mul s10 s6 a2
    call a64p
    addi 1 s6 s6
    j L81
    L89:
    leave8
    L80:
    call argoff
    add a0 s7 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li 10 t0
    bne rel:L801 t0 s6
    li TY_LONG a0
    call load
    leave8
    L801:
    li 7 t0
    bne rel:L89 t0 s6
    mv s8 a0
    call inmem
    bnez L89 a0
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
# a64retf a0: the result V of type a0 where AAPCS64 has it (a0 = 1), or
# where the caller's room is (a0 = 0: in x0, or through x8)
$h .= fn('a64retf', "
    enter5
    call a64resclass
    mv a0 s4
    mv a1 s5
    li 1 t0
    la a64n_retf a0
    beq rel:L7 t0 s4
    li 2 t0
    la a64n_retd a0
    beq rel:L7 t0 s4
    li 8 t0
    la a64n_retq a0
    beq rel:L7 t0 s4
    li 3 t0
    bne rel:L4 t0 s4
    la a64n_retw1 a0
    li 2 t0
    bne rel:L7 t0 s5
    la a64n_retw2 a0
    j L7
    L4:
    la a64n_retsm s6
    li 4 s7
    li 4 t0
    beq rel:L5 t0 s4
    la a64n_retdm s6
    li 8 s7
    li 5 t0
    beq rel:L5 t0 s4
    la a64n_retqm s6
    li 16 s7
    li 9 t0
    bne rel:L8 t0 s4
    L5:
    li 0 s8
    L51:
    bge rel:L9 s5 s8
    mv s6 a0
    li 2 a1
    mv s8 a2
    mul s7 s8 a3
    call a64p
    addi 1 s8 s8
    j L51
    L7:
    call seq
    L9:
    li 1 a0
    leave5
    L8:
    li 0 a0
    leave5
", 6);
# a64vastart a0: va_start of the va_list a0 (its address in V): the stack
# past the named arguments, the saves' tops, the registers left
$h .= fn('a64vastart', "
    enter3
    call addr
    call argoff
    mv a0 s5
    la a64_st t0
    ld 0 t0 s4
    srli 16 s4 t0
    add t0 s5 a2
    la abi_csave t0
    ld 0 t0 a3
    addi -64 a3 a3
    la a64_vsave t0
    ld 0 t0 a4
    addi -128 a4 a4
    la a64n_vas1 a0
    li 3 a1
    call a64p
    andi 255 s4 t0
    li 8 t1
    sub t0 t1 t1
    slli 3 t1 a2
    srli 8 s4 t0
    andi 255 t0 t0
    li 8 t1
    sub t0 t1 t1
    slli 4 t1 a3
    la a64n_vas2 a0
    li 2 a1
    call a64p
    li TY_LONG a0
    call setty
    leave3
", 6);
# a64vaarg a0 a1: va_arg of the va_list a0, type a1, by AAPCS64 (a0 = 1): the
# argument's address from the registers' saves or the stack (cc_a64_vax
# ...), then its value; a struct's, a long double's V its address, a large
# struct's the address its word holds
$h .= fn('a64vaarg', "
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
    call a64class
    addi 32 sp sp
    mv a0 s6
    mv a2 s7
    mv s4 a0
    call addr
    li 6 t0
    bne rel:L1 t0 s6
    andi 255 s7 t0
    li 1 t1
    beq rel:L01 t1 t0
    mv s4 a0
    call bad
    L01:
    srli 8 s7 t0
    li 3 s6
    li 4 t1
    beq rel:L1 t1 t0
    li 4 s6
    li 8 t1
    beq rel:L1 t1 t0
    li 5 s6
    L1:
    li 1 t0
    beq rel:LX t0 s6
    li 9 t0
    beq rel:LX t0 s6
    li 2 t0
    beq rel:LW t0 s6
    li 5 t0
    beq rel:LQ t0 s6
    la a64n_vav a0
    li 16 a2
    li 8 a3
    j LP
    LQ:
    la a64n_vav16 a0
    li 16 a2
    li 16 a3
    j LP
    LX:
    la a64n_vax a0
    li 8 a2
    li 8 a3
    j LP
    LW:
    mv s5 a0
    call talign
    mv a0 t1
    la a64n_vax a0
    li 16 t0
    bne rel:LW1 t0 t1
    la a64n_vax16 a0
    LW1:
    slli 3 s7 a2
    mv a2 a3
    LP:
    li 2 a1
    call a64p
    li 9 t0
    bne rel:LP1 t0 s6
    li TY_LONG a0
    call load
    j LY
    LP1:
    mv s5 a0
    call inmem
    bnez LY a0
    mv s5 a0
    call load
    LY:
    mv s5 a0
    call setty
    li 1 a0
    leave5
", 6);
# a64vacopy a0: va_copy, the 32 bytes of AAPCS64's va_list
$h .= fn('a64vacopy', "
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
    call a64valist
    call copytype
    li TY_LONG a0
    call setty
    leave2
    L8:
    mv s4 a0
    call bad
", 6);
# a64vapackm: V = va_arg_pack_len, the count of the arguments past the named ones
$h .= fn('a64vapackm', "
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
    la a64_named t0
    ld 0 t0 a0
    neg a0 a0
    li R_t1 a1
    call li
    la cc_add_t1 a0
    call seq
    leave1
", 6);
# a64valist: a0 = the type of va_list, AAPCS64's struct of 32 bytes (the
# struct of the node a64_vanode, made once in each compilation)
$h .= fn('a64valist', "
    la a64_vanode a0
    j struct
", 6);
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
# the primitives' names: a seq's with its count of numbers first
my @seqn = qw(x8 fwn resf resd room resv pushx8 pushx9 savex saveq retf retd retq retw1 retw2);
my @seq1 = qw(callp pf pd);
my @prim = qw(lds ldd ldq ldxw ldsw lddw ldqw stk stkw adr stadr fwx fwq rstx rsts rstd rstq vhs vhd vhq retsm retdm retqm vas1 vas2 vax vav vax16 vav16);
for my $x ((map { [$_, "\0cc_a64_$_\0"] } @seqn), (map { [$_, "\x01cc_a64_$_\0"] } @seq1), (map { [$_, "cc_a64_$_\0"] } @prim)) {
    my ($l, $b) = @$x;
    $b .= "\0" x (-length($b) % 8);
    $h .= "      a64n_$l:\n        ascii\n          " . esc($b) . "\n";
}
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = $h;
}
save();
