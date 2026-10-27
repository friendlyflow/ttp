# abirv.pl: calls by the lp64d ABI of riscv64 as Linux has it, riscv64's
# cc_abi 4 (the user's choice, 2026-10-19: ttpc follows each platform's C
# ABI for every call), on the mechanism of abi.pl, abi3.pl, abia64.pl and
# abix64.pl. Each of their hooks goes to a function of its own here where
# the target's ABI is 4 (and not at compile time): abicall rvcall, abipplan
# rvpplan, abipparam rvpparam, abiretf rvretf, abiresclass rvresclass,
# abivaarg rvvaarg, abivapush (nothing), abivapackm rvvapackm, abivastart
# rvvastart, wcall (the C layer's soft-fp calls) rvwcall. abiseq stays
# abi.pl's: a variadic function's prologue is cc_enter_va, which keeps
# a0..a7 right below the stack's arguments, so that va_list (a pointer, as
# before) walks the registers and the stack as one array.
#
# The classification (rvclass, for a call's arguments and a function's
# parameters alike): by the state (the general registers a0..a7 used, the
# fa registers fa0..fa7 used, the stack's bytes, the copies' bytes) and
# whether the argument is unnamed (past a variadic function's named ones),
# its kind: 1 a word in a general register (an integer narrower than a word
# extended to 32 bits by its sign, then sign-extended; a float or double
# there as its bits: unnamed, or past fa7), 2 a struct of 16 bytes or less
# or a long double in its words' general registers (an unnamed one aligned
# to 16 from an even register), 3 4 a float, a double in an fa register, 7
# a word on the stack, 8 a struct or long double on the stack (its words,
# 16-aligned where it is), 9 10 a struct of more than 16 bytes copied by
# the caller, its address in a general register or on the stack, 12 a
# struct or long double of two words split: a7 and the stack, 13 a named
# struct of one or two floating fields, or one floating and one integer
# field (rvflat: nested structs and arrays flattened; no union, no long
# double, no bit field), each field in an fa or a general register, where
# there are enough of both (else it goes as kind 2). An empty struct is
# kind 0, nothing.
#
# A result (rvresclass): 0 a0, 1 fa0 (a float), 2 fa0 (a double), 8 a0:a1
# (a long double), 3 a struct of 16 bytes or less in a0 (a1), 13 a struct
# of floating fields in fa0 (fa1) and a0, 6 in memory, through the address
# in a0 (the hidden first argument). A call (rvcall) evaluates and pushes
# its arguments as before, classifies them (a variadic function's named
# ones counted by rvnamed from its node, which isvafn keeps), makes room
# below them for the stack's arguments and the large structs' copies (sp
# 16-aligned at the call), copies those (the first pass: t1 and t2 only),
# loads the registers (the second pass), a0 for a result in memory, t0 (L)
# with the count of the arguments for a variadic function (va_arg_pack_len)
# and calls; the result where C has it (rvres). The callee (rvpplan) keeps
# a0 for a result in memory (abi_sret), t0 for a variadic function
# (abi_vacnt), and a0..a7 in its frame (abi_csave) where a parameter is a
# struct or long double in registers or V (a0) is needed before a0's
# parameter is read (a variadic function's are above FP, cc_enter_va's);
# rvpparam finds each parameter in its register, that save, or the stack
# above FP. A result is extended or narrowed to its type where it is
# returned (rvretf), as the ABI has a caller rely on. va_arg_pack passes on
# the registers the function was given past its named ones. Run on ttpc.ff
# after abix64.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

# ---- the hooks: where the ABI is 4 and not at compile time, function f
# goes on in function g, with its arguments as they are
my $isrv = "
    la targ_abi t0
    ld 0 t0 t0
    addi -4 t0 t0
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
    $blk =~ /^( *)\Q$f\E:\n/ or die "abirv: no $f\n";
    my $i = length($1) + 2;
    $blk =~ s/^( *\Q$f\E:\n)/$1 . asm($i, "$isrv\n bnez LRV t0")/e;
    $blk .= asm($i, "LRV:\n j $g");
    substr($t, $from, $to - $from) = $blk;
}
hook('abicall', 'rvcall');
hook('abipplan', 'rvpplan');
hook('abipparam', 'rvpparam');
hook('abiretf', 'rvretf');
hook('abiresclass', 'rvresclass');
hook('abivaarg', 'rvvaarg');
hook('abivapush', 'a64nop');
hook('abivapackm', 'rvvapackm');
hook('abivastart', 'rvvastart');
hook('wcall', 'rvwcall');

# isvafn: the node of a variadic function and its dots kept, for rvnamed
E('cc/isvafn', 8, "
    L3:
    li 1 a0
", "
    L3:
    li 1 a0
    la rv_vafn t0
    sd 0 s4 t0
    sd 8 s6 t0
");

# ---- the state: data after x64_flags
$t =~ /^( *)x64_flags:\n\1  dword\n\1    0\n/m or die "abirv: no x64_flags\n";
my $vi = $1;
once(\$t, "${vi}x64_flags:\n$vi  dword\n$vi    0\n", "${vi}x64_flags:\n$vi  dword\n$vi    0\n"
    . join('', map { "$vi$_:\n$vi  dword\n$vi    0\n" } qw(rv_st rv_named rv_fn rv_fd rv_fbad rv_vafn rv_vadots)), 'x64_flags');

# ---- the functions, in cc's layer 3
my $h = '';
# rvnamed: a0 = the count of the named parameters of the variadic function
# isvafn found last (its parameters before its dots)
$h .= fn('rvnamed', "
    enter3
    la rv_vafn t0
    ld 0 t0 s4
    ld 8 t0 s5
    ld NODE_children s4 s4
    li 0 s6
    L1:
    bgeu rel:L9 s5 s4
    ld 0 s4 a0
    call isparam
    bltz L2 a0
    addi 1 s6 s6
    L2:
    addi 8 s4 s4
    j L1
    L9:
    mv s6 a0
    leave3
", 6);
# rvpick a0 a1: a0 = the entry of table a1 (8 words) for a value of type a0:
# 0 a word, 1 four bytes, 2 3 two (signed, unsigned), 4 5 one, 6 a float,
# 7 a double
$h .= fn('rvpick', "
    li 0 t3
    lui TY_REC t0
    bgeu rel:L9 t0 a0
    li 6 t3
    li 36 t0
    beq rel:L9 t0 a0
    li 7 t3
    li 40 t0
    beq rel:L9 t0 a0
    li 0 t3
    andi 32 a0 t0
    bnez L9 t0
    andi 15 a0 t1
    andi 16 a0 t2
    li 1 t3
    li 4 t0
    beq rel:L9 t0 t1
    li 2 t3
    li 2 t0
    beq rel:LU t0 t1
    li 4 t3
    li 1 t0
    beq rel:LU t0 t1
    li 0 t3
    j L9
    LU:
    beqz L9 t2
    addi 1 t3 t3
    L9:
    slli 3 t3 t3
    add t3 a1 t3
    ld 0 t3 a0
    ret
", 6);
# rvfl a0 a1: the scalars of a value of type a0 at offset a1 of a struct,
# for rvflat: each a field of rv_fd (16 bits: its offset, its type << 8),
# rv_fn of them; rv_fbad set for what the ABI's floating convention takes
# no struct with (a third field, a long double, a union, a bit field)
$h .= fn('rvfl', "
    enter8
    mv a0 s4
    mv a1 s5
    lui TY_REC t0
    bgeu rel:LR t0 s4
    li 48 t0
    beq rel:LX t0 s4
    mv s4 t1
    j LA
    LR:
    ld TY_kind s4 t1
    li TY_STRUCT t0
    beq rel:LS t0 t1
    li TY_ARRAY t0
    beq rel:LAR t0 t1
    li TY_ADDRESS t0
    bne rel:LX t0 t1
    li 8 t1
    LA:
    la rv_fn t0
    ld 0 t0 t2
    li 2 t3
    bge rel:LX t3 t2
    slli 4 t2 t3
    slli 8 t1 t4
    or t4 s5 t4
    sll t3 t4 t4
    la rv_fd a2
    ld 0 a2 a3
    or t4 a3 a3
    sd 0 a3 a2
    addi 1 t2 t2
    sd 0 t2 t0
    leave8
    LX:
    la rv_fbad t0
    li 1 t1
    sd 0 t1 t0
    leave8
    LS:
    ld TY_base s4 s6
    ld NODE_children s6 s7
    lbu NODE_children_len s6 s8
    beqz L9 s8
    ld 0 s7 a0
    call kwof
    li KW_union t0
    beq rel:LX t0 a0
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
    bltz LX a0
    bne rel:LX s10 a1
    mv a0 s6
    call talign
    addi -1 a0 t0
    add t0 s9 s9
    neg a0 t0
    and t0 s9 s9
    add s9 s5 a1
    mv s6 a0
    call rvfl
    mv s6 a0
    call tsize
    add a0 s9 s9
    LN:
    addi 8 s7 s7
    addi -1 s8 s8
    j LF
    LAR:
    ld TY_count s4 s8
    ld TY_base s4 s6
    mv s6 a0
    call tsize
    mv a0 s9
    beqz L9 s9
    LA1:
    beqz L9 s8
    la rv_fbad t0
    ld 0 t0 t0
    bnez L9 t0
    mv s6 a0
    mv s5 a1
    call rvfl
    add s9 s5 s5
    addi -1 s8 s8
    j LA1
    L9:
    leave8
", 6);
# rvflat a0: how a struct of type a0 (16 bytes or less) goes by the ABI's
# floating convention: a0 = 0 not, or its floating fields' count + 256 *
# its integer fields' count; a1 its fields (rvfl's, 16 bits each) + its
# count of fields << 32
$h .= fn('rvflat', "
    enter2
    mv a0 s4
    la rv_fn t0
    sd 0 zero t0
    la rv_fd t0
    sd 0 zero t0
    la rv_fbad t0
    sd 0 zero t0
    mv s4 a0
    li 0 a1
    call rvfl
    la rv_fbad t0
    ld 0 t0 t0
    bnez L0 t0
    la rv_fn t0
    ld 0 t0 s5
    beqz L0 s5
    la rv_fd t0
    ld 0 t0 a1
    li 0 t1
    li 0 t2
    srli 8 a1 t3
    andi 32 t3 t3
    beqz LA1 t3
    addi 1 t1 t1
    j LA2
    LA1:
    addi 1 t2 t2
    LA2:
    li 2 t0
    bne rel:LA4 t0 s5
    srli 24 a1 t3
    andi 32 t3 t3
    beqz LA3 t3
    addi 1 t1 t1
    j LA4
    LA3:
    addi 1 t2 t2
    LA4:
    beqz L0 t1
    slli 32 s5 t3
    or t3 a1 a1
    slli 8 t2 t2
    or t2 t1 a0
    leave2
    L0:
    li 0 a0
    li 0 a1
    leave2
", 6);
# rvresclass a0: how a result of type a0 comes back: a0 = its class, a1 its
# words (3), its fields (13, as rvflat's a1)
$h .= fn('rvresclass', "
    enter2
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
    leave2
    LR:
    ld TY_kind s4 t1
    li TY_STRUCT t0
    li 0 a0
    li 0 a1
    bne rel:L9 t0 t1
    mv s4 a0
    call tsize
    mv a0 s5
    li 0 a0
    li 0 a1
    beqz L9 s5
    li 6 a0
    li 16 t0
    blt rel:L9 s5 t0
    mv s4 a0
    call rvflat
    beqz LW a0
    li 13 a0
    leave2
    LW:
    addi 7 s5 a1
    srli 3 a1 a1
    li 3 a0
    L9:
    leave2
", 6);
# rvclass a0 a1 a2: the place of an argument of type a1 by the state a0 (the
# general registers used, the fa ones, the stack's bytes, the copies'), a2
# 1 for an unnamed one: a0 = its kind, a1 its register (13: the first
# general one + 256 * the first fa one), its offset on the stack (7, 8, 10,
# 12: of the second word); a2 its words (2), its bytes on the stack (7, 8),
# its copy's offset (9, 10), its fields (13)
$h .= fn('rvclass', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lui TY_REC t0
    bgeu rel:LR t0 s5
    li 36 t0
    beq rel:LF t0 s5
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
    call tsize
    mv a0 s7
    beqz LZ s7
    li 16 t0
    blt rel:LB s7 t0
    bnez LW s6
    mv s5 a0
    call rvflat
    beqz LW a0
    mv a1 s8
    andi 255 a0 s9
    srli 8 a0 s10
    ld 0 s4 t3
    ld 8 s4 t4
    add s9 t4 t5
    li 8 a3
    blt rel:LW t5 a3
    add s10 t3 a4
    blt rel:LW a4 a3
    sd 0 a4 s4
    sd 8 t5 s4
    slli 8 t4 t4
    or t4 t3 a1
    mv s8 a2
    li 13 a0
    leave8
    LQ:
    li 16 s7
    LW:
    addi 7 s7 s8
    srli 3 s8 s8
    mv s5 a0
    call talign
    mv a0 s9
    ld 0 s4 t0
    beqz LW2 s6
    li 16 t1
    bne rel:LW2 t1 s9
    addi 1 t0 t0
    andi -2 t0 t0
    LW2:
    add s8 t0 t1
    li 8 t2
    blt rel:LW3 t1 t2
    sd 0 t1 s4
    li 2 a0
    mv t0 a1
    mv s8 a2
    leave8
    LW3:
    li 7 t2
    bne rel:LWS t2 t0
    li 8 t2
    sd 0 t2 s4
    ld 16 s4 t0
    addi 8 t0 t1
    sd 16 t1 s4
    li 12 a0
    mv t0 a1
    li 8 a2
    leave8
    LWS:
    li 8 t1
    sd 0 t1 s4
    ld 16 s4 t0
    li 16 t1
    bne rel:LWS1 t1 s9
    addi 15 t0 t0
    andi -16 t0 t0
    LWS1:
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
    addi 8 t0 t1
    sd 16 t1 s4
    li 10 a0
    mv t0 a1
    mv s9 a2
    leave8
    LF:
    bnez LI s6
    ld 8 s4 t0
    li 8 t1
    bge rel:LI t1 t0
    addi 1 t0 t1
    sd 8 t1 s4
    li 3 a0
    li 36 t1
    beq rel:LF1 t1 s5
    li 4 a0
    LF1:
    mv t0 a1
    li 0 a2
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
    addi 8 t0 t1
    sd 16 t1 s4
    li 7 a0
    mv t0 a1
    li 8 a2
    leave8
    LZ:
    li 0 a0
    li 0 a1
    li 0 a2
    leave8
", 6);
# rvcpw a0 a1 a2: a2 bytes (words) of the struct whose address is at SP + a0
# to SP + a1
$h .= fn('rvcpw', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    li 0 s7
    L1:
    bge rel:L9 s6 s7
    la rvn_stkw a0
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
# rvstk: a0 = the bytes from FP to the stack's arguments (a variadic
# function's a0..a7 lie between)
$h .= fn('rvstk', "
    enter1
    call argoff
    la ccs t0
    ld CC_va t0 t0
    beqz L1 t0
    addi 64 a0 a0
    L1:
    leave1
", 6);
# rvput0 a0 .. a5: the memory pass of an argument: its kind a0, place a1,
# type a2, a3 (rvclass's a2), its pushed value at SP + a4, the copies at SP
# + a5: the stack's arguments and the large structs' copies
$h .= fn('rvput0', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
    li 7 t0
    bne rel:L1 t0 s4
    mv s6 a0
    la rv_tld a1
    call rvpick
    li 2 a1
    li 6 a2
    mv s8 a3
    call a64p
    la rvn_st a0
    li 1 a1
    mv s5 a2
    call a64p
    leave8
    L1:
    li 8 t0
    bne rel:L2 t0 s4
    mv s8 a0
    mv s5 a1
    mv s7 a2
    call rvcpw
    leave8
    L2:
    li 12 t0
    bne rel:L3 t0 s4
    la rvn_stkw a0
    li 3 a1
    mv s8 a2
    mv s5 a3
    li 8 a4
    call a64p
    leave8
    L3:
    li 9 t0
    beq rel:L31 t0 s4
    li 10 t0
    bne rel:L9 t0 s4
    L31:
    mv s6 a0
    call tsize
    addi 7 a0 a2
    andi -8 a2 a2
    add s9 s7 a1
    mv s8 a0
    call rvcpw
    li 10 t0
    bne rel:L9 t0 s4
    la rvn_stadr a0
    li 2 a1
    add s9 s7 a2
    mv s5 a3
    call a64p
    L9:
    leave8
", 6);
# rvput1 a0 .. a5: the register pass of an argument (as rvput0)
$h .= fn('rvput1', "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
    li 1 t0
    bne rel:L2 t0 s4
    mv s6 a0
    la rv_tld a1
    call rvpick
    li 2 a1
    addi 10 s5 a2
    mv s8 a3
    call a64p
    leave8
    L2:
    li 2 t0
    bne rel:L3 t0 s4
    mv s6 a0
    call tsize
    mv a0 s10
    li 0 s11
    L21:
    bge rel:L9 s7 s11
    mv s10 a0
    mv s11 a1
    call x64last
    mv a0 t2
    la rvn_ldw a0
    beqz L22 t2
    la rvn_ldl a0
    L22:
    li 3 a1
    add s11 s5 a2
    addi 10 a2 a2
    mv s8 a3
    slli 3 s11 a4
    call a64p
    addi 1 s11 s11
    j L21
    L3:
    li 3 t0
    la rvn_lds a0
    beq rel:L31 t0 s4
    li 4 t0
    la rvn_ldd a0
    bne rel:L4 t0 s4
    L31:
    li 2 a1
    addi 10 s5 a2
    mv s8 a3
    call a64p
    leave8
    L4:
    li 9 t0
    bne rel:L5 t0 s4
    la rvn_adr a0
    li 2 a1
    addi 10 s5 a2
    add s9 s7 a3
    call a64p
    leave8
    L5:
    li 12 t0
    bne rel:L6 t0 s4
    la rvn_ldw a0
    li 3 a1
    li 17 a2
    mv s8 a3
    li 0 a4
    call a64p
    leave8
    L6:
    li 13 t0
    bne rel:L9 t0 s4
    andi 255 s5 s9
    srli 8 s5 s10
    srli 32 s7 s11
    L61:
    beqz L9 s11
    srli 8 s7 a0
    andi 255 a0 a0
    la rv_tfld a1
    call rvpick
    srli 8 s7 t1
    andi 32 t1 t1
    beqz L62 t1
    addi 10 s10 a2
    addi 1 s10 s10
    j L63
    L62:
    addi 10 s9 a2
    addi 1 s9 s9
    L63:
    li 3 a1
    mv s8 a3
    andi 255 s7 a4
    call a64p
    srli 16 s7 s7
    addi -1 s11 s11
    j L61
    L9:
    leave8
", 6);
# rvres a0 a1 a2 a3: the result of class a0, a1 (rvresclass's), room a2
# below FP (a temporary where there is none), type a3, where C has it: V the
# bits of a float or double, the address of its room for one that comes in
# registers as a struct or a long double, the room of one in memory; an
# integer narrower than a word narrowed (to ttpc's own form of it)
$h .= fn('rvres', "
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
    la rvn_resf a0
    call seq
    leave8
    L2:
    li 2 t0
    bne rel:L3 t0 s4
    la rvn_resd a0
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
    la rvn_room a0
    call seq
    li 8 t0
    bne rel:L5 t0 s4
    la rvn_rst8 a0
    li 2 a1
    li 10 a2
    li 0 a3
    call a64p
    la rvn_rst8 a0
    li 2 a1
    li 11 a2
    li 8 a3
    call a64p
    j L8
    L5:
    li 3 t0
    bne rel:L6 t0 s4
    mv s7 a0
    call tsize
    mv a0 s10
    li 0 s8
    L51:
    bge rel:L8 s5 s8
    mv s10 a0
    mv s8 a1
    call x64last
    mv a0 t2
    la rvn_rst8 a0
    beqz L52 t2
    la rvn_rst4 a0
    L52:
    li 2 a1
    addi 10 s8 a2
    slli 3 s8 a3
    call a64p
    addi 1 s8 s8
    j L51
    L6:
    srli 32 s5 s9
    mv s5 s10
    li 0 s11
    L61:
    beqz L8 s9
    srli 8 s10 a0
    andi 255 a0 a0
    mv a0 s8
    la rv_trst a1
    call rvpick
    li 2 a1
    andi 255 s10 a3
    andi 32 s8 t0
    beqz L62 t0
    addi 10 s11 a2
    addi 1 s11 s11
    j L63
    L62:
    li 10 a2
    L63:
    call a64p
    srli 16 s10 s10
    addi -1 s9 s9
    j L61
    L8:
    la rvn_resv a0
    call seq
    L9:
    leave8
", 6);
# rvfwd a0: under va_arg_pack, the registers this function was given past
# its named ones (kept above FP by cc_enter_va) loaded again for a call of
# as many named arguments (a0 its count of arguments), L the call's count
$h .= fn('rvfwd', "
    enter3
    mv a0 s4
    la rv_st t0
    ld 0 t0 t0
    andi 255 t0 s5
    L1:
    li 8 t0
    bge rel:L3 t0 s5
    slli 3 s5 a0
    addi 16 a0 a0
    li R_t0 a1
    call li
    la rvn_fwx a0
    li 1 a1
    addi 10 s5 a2
    call a64p
    addi 1 s5 s5
    j L1
    L3:
    la abi_vacnt t0
    ld 0 t0 a0
    neg a0 a0
    li R_t0 a1
    call li
    la rv_named t0
    ld 0 t0 t0
    sub t0 s4 a0
    li R_t1 a1
    call li
    la rvn_fwn a0
    call seq
    leave3
", 6);
# rvcall a0 .. a5: abicall's (a0 0: the function a1, 1: through the address
# pushed before the arguments; a2 the room of a struct or long double result
# below FP, or 0; a3 1 for a variadic function; a4 1 under va_arg_pack; a5
# the result's type) by the lp64d ABI. Its frame: the state at sp (32
# bytes), a place per argument from sp + 32 (kind, place, type, rvclass's
# a2), then a3, a4, the room below the pushed values, a5, the result's
# class and a1, the copies' offset, the pushed slots, the named arguments'
# count
$h .= fn('rvcall', "
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
    li 64 t0
    sd 1632 t0 sp
    beqz LN a3
    call rvnamed
    sd 1632 a0 sp
    LN:
    ld 1592 sp a0
    call rvresclass
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
    li 0 a2
    ld 1632 sp t0
    blt rel:L21 t0 s9
    li 1 a2
    L21:
    call rvclass
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
    la rv_st t0
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
    ld 1624 sp t0
    slli 3 t0 t0
    add s10 t0 t0
    li 2000 t1
    blt rel:L41 t1 t0
    li 0 a0
    call bad
    L41:
    beqz L5 s10
    la ccs t2
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
    ld 1616 sp a5
    call rvput0
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
    ld 1616 sp a5
    call rvput1
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
    la rvn_sret a0
    call seq
    L11:
    ld 1576 sp t0
    beqz L12 t0
    mv s8 a0
    call rvfwd
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
    slli 3 t0 t0
    add s10 t0 a1
    la rvn_callp a0
    call seq
    LD:
    ld 1624 sp t0
    add s4 t0 t0
    srli 3 s10 t1
    add t1 t0 s11
    mv s11 a0
    call popped
    slli 3 s11 a1
    srli 11 a1 t0
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
    call rvres
    addi 1648 sp sp
    leave8
", 6);
# rvwcall a0 a1 a2: wcall's (the soft-fp function a0 of cc_sfnames, its a1
# arguments pushed, its result's type a2) by the lp64d ABI: each argument in
# its registers by the function's kinds (a64sfargs: 1 a general register, 3
# 4 an fa one, 5 a long double in two general ones), sp 16-aligned at the
# call, the result where C has it (rvres; a long double's in a temporary,
# whose place a0 is, as wcall's)
$h .= fn('rvwcall', "
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
    la rvn_ld8 a0
    addi 10 s9 a2
    addi 1 s9 s9
    j L13
    L11:
    li 5 t0
    bne rel:L111 t0 t2
    mv a3 s11
    la rvn_ldw a0
    li 3 a1
    addi 10 s9 a2
    mv s11 a3
    li 0 a4
    call a64p
    la rvn_ldw a0
    li 3 a1
    addi 11 s9 a2
    mv s11 a3
    li 8 a4
    call a64p
    addi 2 s9 s9
    j L14
    L111:
    la rvn_lds a0
    li 3 t0
    beq rel:L12 t0 t2
    la rvn_ldd a0
    L12:
    addi 10 s10 a2
    addi 1 s10 s10
    L13:
    li 2 a1
    call a64p
    L14:
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
    call rvresclass
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
    call rvres
    mv s6 a0
    call setty
    mv s10 a0
    leave8
", 6);
# rvpplan a0 a1: the places of the parameters (a1 of them, from a0) of the
# function being compiled, in abi_pplan (the state, then kind, place, type,
# rvclass's a2 of each); a0 kept for a result in memory (abi_sret), t0 for a
# variadic function (abi_vacnt), a0..a7 (abi_csave) where a parameter is a
# struct or long double in registers, or V (a0) is needed before a0's
# parameter is read (a variadic function's above FP: abi_csave -16); the
# state after the named ones in rv_st (the general registers, the fa ones
# << 8, the stack's bytes << 16), their count in rv_named
$h .= fn('rvpplan', "
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
    li 0 s10
    la ccs t0
    ld CC_rty t0 a0
    call rvresclass
    li 6 t0
    bne rel:L1 t0 a0
    la rvn_pusha0 a0
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
    la rvn_pushl a0
    li 1 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_vacnt t0
    sd 0 t1 t0
    L2:
    la rv_named t0
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
    li 0 a2
    call rvclass
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
    li 12 t0
    beq rel:L41 t0 a0
    li 13 t0
    beq rel:L41 t0 a0
    li 1 t0
    bne rel:L42 t0 a0
    bnez L42 a1
    beqz L42 s7
    L41:
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
    la rv_st t1
    sd 0 t0 t1
    bnez L6 s9
    beqz L9 s10
    la rvn_savex a0
    li 8 t1
    call pushpop
    la ccs t0
    ld CC_depth t0 t1
    la abi_csave t0
    sd 0 t1 t0
    j L9
    L6:
    li -16 t1
    la abi_csave t0
    sd 0 t1 t0
    L9:
    leave8
", 6);
# rvpparam a0 a1: V = parameter a0 (the variable a1): from its register (or
# its save), the stack above FP; a struct's or long double's in registers:
# its words or fields stored in its variable (V its address); one on the
# stack: the address of its bytes; a large struct's: the address of the
# caller's copy
$h .= fn('rvpparam', "
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
    la rvn_pf a0
    beq rel:L21 t0 s6
    li 4 t0
    la rvn_pd a0
    bne rel:L3 t0 s6
    L21:
    addi 10 s7 a1
    call seq
    leave8
    L3:
    li 2 t0
    beq rel:L31 t0 s6
    li 12 t0
    beq rel:L31 t0 s6
    li 13 t0
    beq rel:L31 t0 s6
    bnez L4 s6
    L31:
    ld VAR_off s5 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    beqz L39 s6
    li 13 t0
    beq rel:LK t0 s6
    li 12 t0
    beq rel:LS t0 s6
    mv s8 a0
    call tsize
    mv a0 s11
    li 0 s4
    L32:
    bge rel:L39 s10 s4
    add s4 s7 t0
    slli 3 t0 t0
    sub s9 t0 a0
    li R_t0 a1
    call li
    mv s11 a0
    mv s4 a1
    call x64last
    mv a0 t2
    la rvn_vh8 a0
    beqz L33 t2
    la rvn_vh4 a0
    L33:
    li 1 a1
    slli 3 s4 a2
    call a64p
    addi 1 s4 s4
    j L32
    LS:
    li 56 a0
    sub s9 a0 a0
    li R_t0 a1
    call li
    la rvn_vh8 a0
    li 1 a1
    li 0 a2
    call a64p
    call rvstk
    add a0 s7 a0
    li R_t0 a1
    call li
    mv s8 a0
    call tsize
    li 1 a1
    call x64last
    mv a0 t2
    la rvn_vh8 a0
    beqz L34 t2
    la rvn_vh4 a0
    L34:
    li 1 a1
    li 8 a2
    call a64p
    j L39
    LK:
    andi 255 s7 s4
    srli 8 s7 s7
    srli 32 s10 s11
    LK1:
    beqz L39 s11
    srli 8 s10 t1
    andi 255 t1 s6
    andi 32 s6 t0
    beqz LK2 t0
    la rvn_vfs a0
    li 36 t0
    beq rel:LK11 t0 s6
    la rvn_vfd a0
    LK11:
    li 2 a1
    addi 10 s7 a2
    addi 1 s7 s7
    andi 255 s10 a3
    call a64p
    j LK3
    LK2:
    slli 3 s4 t0
    sub s9 t0 a0
    li R_t0 a1
    call li
    mv s6 a0
    la rv_tvh a1
    call rvpick
    li 1 a1
    andi 255 s10 a2
    call a64p
    addi 1 s4 s4
    LK3:
    srli 16 s10 s10
    addi -1 s11 s11
    j LK1
    L39:
    leave8
    L4:
    li 9 t0
    bne rel:L5 t0 s6
    slli 3 s7 t0
    sub t0 s9 a0
    li TY_LONG s8
    j LL
    L5:
    call rvstk
    add a0 s7 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    li 8 t0
    beq rel:L39 t0 s6
    li 10 t0
    bne rel:L51 t0 s6
    li TY_LONG s8
    L51:
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
", 6);
# rvretf a0: the result V of type a0 where the ABI has it (a0 = 1: fa0, a0:a1
# for a long double or a struct of words, fa0 fa1 a0 for one of floating
# fields), or where the caller's room is (a0 = 0: a struct through the
# address a0 gave); an integer narrower than a word as the ABI has it
# (extended to 32 bits by its sign, then sign-extended)
$h .= fn('rvretf', "
    enter8
    mv a0 s4
    call rvresclass
    mv a0 s5
    mv a1 s6
    bnez LC s5
    lui TY_REC t0
    bgeu rel:L8 t0 s4
    andi 32 s4 t0
    bnez L8 t0
    andi 15 s4 t0
    beqz L8 t0
    li 4 t1
    bne rel:LN t1 t0
    la rvn_sext a0
    call seq
    j L8
    LN:
    li 3 t1
    blt rel:L8 t0 t1
    mv s4 a0
    call narrow
    j L8
    LC:
    li 1 t0
    la rvn_retf a0
    beq rel:L7 t0 s5
    li 2 t0
    la rvn_retd a0
    beq rel:L7 t0 s5
    li 8 t0
    la rvn_retw2 a0
    beq rel:L7 t0 s5
    li 3 t0
    bne rel:LF t0 s5
    la rvn_retw1 a0
    li 1 t0
    beq rel:L7 t0 s6
    la rvn_retw2 a0
    j L7
    LF:
    li 13 t0
    bne rel:L8 t0 s5
    srli 32 s6 s7
    mv s6 s8
    li 0 s9
    LF1:
    beqz LF3 s7
    srli 8 s8 t1
    andi 255 t1 t1
    andi 32 t1 t2
    beqz LF2 t2
    la rvn_rtfs a0
    li 36 t0
    beq rel:LF15 t0 t1
    la rvn_rtfd a0
    LF15:
    li 2 a1
    addi 10 s9 a2
    addi 1 s9 s9
    andi 255 s8 a3
    call a64p
    LF2:
    srli 16 s8 s8
    addi -1 s7 s7
    j LF1
    LF3:
    srli 32 s6 s7
    mv s6 s8
    LF4:
    beqz L9 s7
    srli 8 s8 t1
    andi 255 t1 a0
    andi 32 a0 t2
    bnez LF5 t2
    la rv_trtx a1
    call rvpick
    li 1 a1
    andi 255 s8 a2
    call a64p
    LF5:
    srli 16 s8 s8
    addi -1 s7 s7
    j LF4
    L7:
    call seq
    L9:
    li 1 a0
    leave8
    L8:
    li 0 a0
    leave8
", 6);
# rvvastart a0: V = where va_start begins: past the named arguments in the
# array of a0..a7 (kept above FP) and the stack's arguments
$h .= fn('rvvastart', "
    enter1
    la rv_st t0
    ld 0 t0 t1
    andi 255 t1 t2
    slli 3 t2 t2
    srli 16 t1 t3
    add t3 t2 t2
    addi 16 t2 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    leave1
", 6);
# rvvaarg a0 a1: va_arg of the va_list a0, type a1, by the ABI (a0 = 1): an
# unnamed argument's place (rvclass): a word, a long double or struct of 16
# bytes or less in the array (16-aligned where it is: V its address), a
# larger struct's address; the list goes up past it
$h .= fn('rvvaarg', "
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
    li 1 a2
    call rvclass
    addi 32 sp sp
    mv a0 s6
    mv a2 s7
    mv s4 a0
    call addr
    li 2 t0
    beq rel:LW t0 s6
    beqz LZ s6
    la rvn_va8 a0
    li 1 a1
    li 8 a2
    call a64p
    li 9 t0
    bne rel:LP t0 s6
    li TY_LONG a0
    call load
    j LY
    LP:
    mv s5 a0
    call inmem
    bnez LY a0
    mv s5 a0
    call load
    j LY
    LW:
    mv s5 a0
    call talign
    mv a0 t1
    la rvn_va8 a0
    li 16 t0
    bne rel:LW1 t0 t1
    la rvn_va16 a0
    LW1:
    li 1 a1
    slli 3 s7 a2
    call a64p
    j LY
    LZ:
    la rvn_va8 a0
    li 1 a1
    li 0 a2
    call a64p
    LY:
    mv s5 a0
    call setty
    li 1 a0
    leave5
", 6);
# rvvapackm: V = va_arg_pack_len, the count of the arguments past the named
# ones (t0, kept by rvpplan: a ttpc caller's)
$h .= fn('rvvapackm', "
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
    la rv_named t0
    ld 0 t0 a0
    neg a0 a0
    li R_t1 a1
    call li
    la cc_add_t1 a0
    call seq
    leave1
", 6);
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }
# the primitives' names: a seq's with its count of numbers first
my @seqn = qw(sext resf resd room resv pusha0 pushl savex retf retd retw1 retw2 sret fwn);
my @seq1 = qw(callp pf pd);
my @prim = qw(ld8 ld4 ld2 ld2u ld1 ld1u lds ldd ldw ldl ldh ldhu ldb ldbu ldfs ldfd st stkw adr stadr fwx
    rst8 rst4 rst2 rst1 rsts rstd vh8 vh4 vh2 vh1 vfs vfd rtfs rtfd rtx8 rtx4 rtx2 rtx2u rtx1 rtx1u va8 va16);
for my $x ((map { [$_, "\0cc_rv_$_\0"] } @seqn), (map { [$_, "\x01cc_rv_$_\0"] } @seq1), (map { [$_, "cc_rv_$_\0"] } @prim)) {
    my ($l, $b) = @$x;
    $b .= "\0" x (-length($b) % 8);
    $h .= "      rvn_$l:\n        ascii\n          " . esc($b) . "\n";
}
# rvpick's tables: a value from a pushed slot, a struct's field, a struct
# parameter's field stored, a result's field stored, a result's field loaded
my %tab = (rv_tld => [qw(ld8 ld4 ld2 ld2u ld1 ld1u ld8 ld8)], rv_tfld => [qw(ldw ldl ldh ldhu ldb ldbu ldfs ldfd)],
    rv_tvh => [qw(vh8 vh4 vh2 vh2 vh1 vh1 vfs vfd)], rv_trst => [qw(rst8 rst4 rst2 rst2 rst1 rst1 rsts rstd)],
    rv_trtx => [qw(rtx8 rtx4 rtx2 rtx2u rtx1 rtx1u rtfs rtfd)]);
for my $n (sort keys %tab) {
    $h .= "      $n:\n" . join('', map { "        dword\n          rvn_$_\n" } @{ $tab{$n} });
}
# (in a layer of their own, 4: cc's layer 3 is full)
{
    my ($from, $to) = find(\$t, 'cc/3');
    substr($t, $to, 0) = "    4:\n$h";
}
save();
