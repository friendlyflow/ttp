# opt.pl: -O, phase 1 (lane S3): a peephole on the C layer's primitive
# stream. Every primitive the C layer emits passes through cc's prim, by
# name; with -O (first, or after --target X, on the command line, as -g; a
# build file run with -O compiles its workspaces with it) prim hands it to
# the group opt: of cc, which rewrites the stream, the same for all four
# targets (each primitive is the target's own macro):
#
#   push ... pop -> L = V: cc_push is held, and after it the primitives
#   that touch only V or X (cc_li_* into V or X, cc_global, cc_addfp,
#   cc_load_*, cc_ext_*, cc_bool, cc_neg, cc_not, cc_inv, at most 8); a
#   cc_pop then becomes cc_setreg cc_l and the held ones, anything else
#   emits the push and the held ones as they were, then itself;
#   locals by one fp-relative load or store (stage B, after A): cc_li off V,
#   cc_addfp, cc_load_X is cc_ldfp_X off; cc_li off L, cc_addfp_l,
#   cc_store_N, then what neither reads nor sets L (as above, and cc_push),
#   then what sets L (cc_pop, cc_li_* or cc_setreg into cc_l) is cc_stfp_N
#   off, then the rest; off in -255..255 and not 0 (every target encodes it
#   in one instruction; the macros are in each target's c: group). Where a
#   pattern breaks, its first primitive is emitted as it was and the rest
#   go through stage B again;
#   call arguments (stage A): cc_push, then cc_arg i off for each register
#   argument, one of them off 0 (the slot pushed), then cc_drop n is cc_toarg
#   i (argument register i = V, the reverse of cc_param) first, then the
#   others one slot less, then cc_drop n less a slot (none where that is 0).
#
# The decisions depend only on the primitives' names and arguments, so
# pass 1 and pass 2 make the same. What is held is emitted (flushed) before
# anything else is: optflush, called by emit_raw, skip and code_call (every
# byte and every macro), by label (it reads cur_pc), ctrun, jit and generic (they
# set cur_pc aside; generic drops what its compile held). Inside compile
# time (CC_jit) opt holds nothing. Without -O prim goes on to prim0 (prim
# as it was) and no byte changes.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my @l;
    while (length $text > 240) { $text =~ s/^(.{1,240}) //s or die "cfn: $name\n"; push @l, $1 }
    push @l, $text;
    my $c = ' ' x ($ind + 2) . "comment\n" . join('', map { ' ' x ($ind + 4) . "$_\n" } @l);
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# what generic's compile held is dropped, and each pass starts with none
my $reset = "
    la opt_held t0
    sd 0 zero t0
    la opt_a t0
    sd 0 zero t0
    la opt_c t0
    sd 0 zero t0
    la opt_n t0
    sd 0 zero t0
    la optb_n t0
    sd 0 zero t0
";

# ---- the variables (bss): after data_at
once(\$t, "  data_at:\n    reserve\n      2048\n",
    "  data_at:\n    reserve\n      2048\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
        [opt_on => 8], [opt_held => 8], [opt_in => 8], [opt_a => 8], [opt_c => 8], [opt_n => 8], [opt_fn => 8], [opt_buf => 8 * 48],
        [optb_n => 8], [optb_buf => 10 * 48]), 'data_at');

# ---- the names it knows, after cc_names
my @safe = qw(cc_global cc_addfp cc_load_i8 cc_load_i16 cc_load_i32 cc_load_i64 cc_load_u8 cc_load_u16 cc_load_u32 cc_load_u64
    cc_ext_i8 cc_ext_i16 cc_ext_i32 cc_ext_u8 cc_ext_u16 cc_ext_u32 cc_bool cc_neg cc_not cc_inv);
my $names = join '', map { "  $_->[0]:\n    ascii\n      $_->[1]\n" }
    [opt_push => 'cc_push\x00'], [opt_pop => 'cc_pop\x00'], [opt_setreg => 'cc_setreg\x00'], [opt_l => 'cc_l\x00'],
    [opt_safe => 'cc_li_pos\x00cc_li_neg\x00cc_li_big\x00'], [opt_safe1 => join('', map { "$_\\x00" } @safe) . '\x00'],
    [opt_v => 'cc_v\x00'], [opt_arg => 'cc_arg\x00'], [opt_drop => 'cc_drop\x00'], [opt_toarg => 'cc_toarg\x00'], [opt_addfp => 'cc_addfp\x00'], [opt_addfpl => 'cc_addfp_l\x00'],
    [opt_lipos => 'cc_li_pos\x00'], [opt_lineg => 'cc_li_neg\x00'], [opt_libig => 'cc_li_big\x00'],
    [opt_lds => 'cc_load_i8\x00\x00cc_load_i16\x00cc_load_i32\x00cc_load_i64\x00cc_load_u8\x00\x00cc_load_u16\x00cc_load_u32\x00cc_load_u64\x00\x00'],
    [opt_ldfps => 'cc_ldfp_i8\x00\x00cc_ldfp_i16\x00cc_ldfp_i32\x00cc_ldfp_i64\x00cc_ldfp_u8\x00\x00cc_ldfp_u16\x00cc_ldfp_u32\x00cc_ldfp_u64\x00'],
    [opt_sts => 'cc_store_8\x00\x00cc_store_16\x00cc_store_32\x00cc_store_64\x00\x00'],
    [opt_stfps => 'cc_stfp_8\x00\x00\x00cc_stfp_16\x00\x00cc_stfp_32\x00\x00cc_stfp_64\x00\x00'];
once(\$t, "  cc_loads:\n", "${names}  cc_loads:\n", 'cc_loads');

# ---- the switch: -O before and after -g, first and after --target X
$t =~ s/^( +)call\n\1  dbgflag\n/$1call\n$1  optflag\n$1call\n$1  dbgflag\n$1call\n$1  optflag\n/mg == 2 or die "opt: dbgflag calls\n";

# ---- prim: with -O to opt, else prim0 (prim as it was)
once(\$t, "      prim:\n        enter8\n", "      prim:\n" . asm(8, "
    la opt_on t0
    ld 0 t0 t0
    bnez P1 t0
    j prim0
    P1:
    j opt
") . "      prim0:\n        enter8\n", 'prim');

# ---- what flushes it
my $hook = "
    addi -16 sp sp
    sd 0 ra sp
    call optflush
    ld 0 sp ra
    addi 16 sp sp
";
once(\$t, "  emit_raw:\n", "  emit_raw:\n" . asm(4, $hook), 'emit_raw');
edit(\$t, 'skip', "    sd\n      8\n      s4\n      sp\n", "    sd\n      8\n      s4\n      sp\n" . asm(4, "call optflush"));
edit(\$t, 'code_call', "    call\n      dbgrowc\n", asm(4, "call optflush") . "    call\n      dbgrowc\n");
once(\$t, "      label:\n        la\n          pass\n", "      label:\n" . asm(8, $hook) . "        la\n          pass\n", 'label');
once(\$t, "      jit:\n        enter8\n", "      jit:\n        enter8\n" . asm(8, "call optflush"), 'jit');
# (ctrun runs jit only the first time, in pass 1: it flushes in both)
once(\$t, "      ctrun:\n        enter3\n", "      ctrun:\n        enter3\n" . asm(8, "call optflush"), 'ctrun');
edit(\$t, 'cc/generic', "        enter8\n", "        enter8\n" . asm(8, "call optflush"),
    "        ld\n          192\n          sp\n          t1\n        la\n          cur_pc\n",
    asm(8, $reset) . "        ld\n          192\n          sp\n          t1\n        la\n          cur_pc\n");
# each pass starts with none held
edit(\$t, 'compile_page', "      la\n        ct_placed\n        t0\n", asm(6, $reset) . "      la\n        ct_placed\n        t0\n");

# ---- the functions of layer 0
my $code = '';
$code .= cfn('optflag', "a0 a1: _start's count of arguments and pointer (s10 s11); past a first -O, which sets opt_on", "
    li 2 t1
    blt rel:O9 t1 a0
    ld 8 a1 t2
    lbu 0 t2 t3
    li 45 t4
    bne rel:O9 t4 t3
    lbu 1 t2 t3
    li 79 t4
    bne rel:O9 t4 t3
    lbu 2 t2 t3
    bnez O9 t3
    la opt_on t0
    li 1 t1
    sd 0 t1 t0
    addi 8 a1 a1
    addi -1 a0 a0
    O9:
    ret
", 2);
$code .= cfn('optflush', "with -O, what opt holds emitted (opt_fn, its flush); every register kept but t0", "
    la opt_held t0
    ld 0 t0 t0
    bnez O1 t0
    ret
    O1:
    addi -16 sp sp
    sd 0 ra sp
    la opt_fn t0
    ld 0 t0 t0
    jalr 0 t0 ra
    ld 0 sp ra
    addi 16 sp sp
    ret
", 2);
once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');

# ---- the group opt: of cc, at the end of its layer 1
# Stage A (push ... pop) feeds stage B (the locals), stage B prim0.
my $opt = cfn('opt', "the peephole of -O (gen/patches/opt.pl), prim's a0..a5 a primitive. Stage A: cc_push held (opt_a), then what touches only V or X (opt_buf, opt_n); cc_pop after them is cc_setreg cc_l, then them; or at once after it cc_arg i off (opt_c), one of them off 0, then cc_drop n: cc_toarg of that one, the others a slot less, cc_drop n less a slot; else the push and them, then it. Stage B (optb_buf, optb_n): cc_li off V, cc_addfp, cc_load_* is cc_ldfp_* off; cc_li off L, cc_addfp_l, cc_store_*, what neither reads nor sets L, then what sets L is cc_stfp_* off, then them; else the first as it was, the rest again. F0 emits what both hold (optflush), unless opt runs (opt_in).", "
    addi -16 sp sp
    sd 0 ra sp
    la opt_in t0
    li 1 t1
    sd 0 t1 t0
    la F0 t1
    la opt_fn t0
    sd 0 t1 t0
    call M0
    la opt_in t0
    sd 0 zero t0
    ld 0 sp ra
    addi 16 sp sp
    ret
    M0:
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
    la ccs t0
    ld CC_jit t0 t0
    beqz M1 t0
    call prim0
    leave8
    M1:
    la opt_a t0
    ld 0 t0 t0
    bnez H0 t0
    N0:
    mv s4 a0
    bnez X1 s5
    la opt_push a2
    call cstreq
    beqz X1 a0
    la opt_a t0
    li 1 t1
    sd 0 t1 t0
    la opt_held t0
    sd 0 t1 t0
    la opt_n t0
    sd 0 zero t0
    leave8
    H0:
    la opt_c t0
    ld 0 t0 t0
    bnez C1 t0
    la opt_n t0
    ld 0 t0 t0
    bnez H1 t0
    call ISA
    beqz H1 a0
    la opt_c t0
    li 1 t1
    sd 0 t1 t0
    j AP
    C1:
    la opt_n t0
    ld 0 t0 t0
    li 8 t1
    bge rel:X0 t1 t0
    call ISA
    bnez AP a0
    li 1 t0
    bne rel:X0 t0 s5
    mv s4 a0
    la opt_drop a2
    call cstreq
    beqz X0 a0
    li -1 s10
    li 0 t1
    la opt_n t0
    ld 0 t0 t2
    CD1:
    bge rel:CD2 t2 t1
    li 48 t3
    mul t3 t1 t3
    la opt_buf t0
    add t3 t0 t3
    ld 24 t3 t4
    bnez CD3 t4
    bltz CD8 s10
    j X0
    CD8:
    mv t1 s10
    CD3:
    addi 1 t1 t1
    j CD1
    CD2:
    bltz X0 s10
    call slot
    mv a0 s11
    li 48 t3
    mul t3 s10 t3
    la opt_buf t0
    add t3 t0 t3
    ld 16 t3 a2
    la opt_toarg a0
    li 1 a1
    li 0 a5
    call SB
    li 0 s7
    CD4:
    la opt_n t0
    ld 0 t0 t1
    bge rel:CD6 t1 s7
    beq rel:CD5 s7 s10
    li 48 t3
    mul t3 s7 t3
    la opt_buf t0
    add t3 t0 t3
    ld 0 t3 a0
    ld 8 t3 a1
    ld 16 t3 a2
    ld 24 t3 a3
    sub s11 a3 a3
    li 0 a5
    call SB
    CD5:
    addi 1 s7 s7
    j CD4
    CD6:
    la opt_a t0
    sd 0 zero t0
    la opt_n t0
    sd 0 zero t0
    la opt_c t0
    sd 0 zero t0
    sub s11 s6 a2
    beqz CD7 a2
    mv s4 a0
    li 1 a1
    li 0 a5
    call SB
    CD7:
    leave8
    ISA:
    li 2 t0
    bne rel:IS0 t0 s5
    bnez IS0 s9
    mv s4 a0
    la opt_arg a2
    j cstreq
    IS0:
    li 0 a0
    ret
    H1:
    mv s4 a0
    bnez H2 s5
    la opt_pop a2
    call cstreq
    beqz H2 a0
    la opt_a t0
    sd 0 zero t0
    la opt_setreg a0
    li 1 a1
    la opt_l a5
    call SB
    call R0
    leave8
    H2:
    la opt_n t0
    ld 0 t0 t0
    li 8 t1
    bge rel:X0 t1 t0
    mv s4 a0
    mv s9 a1
    call SAFE
    beqz X0 a0
    AP:
    la opt_n t0
    ld 0 t0 t1
    addi 1 t1 t2
    sd 0 t2 t0
    li 48 t2
    mul t2 t1 t1
    la opt_buf t0
    add t1 t0 t0
    sd 0 s4 t0
    sd 8 s5 t0
    sd 16 s6 t0
    sd 24 s7 t0
    sd 32 s8 t0
    sd 40 s9 t0
    leave8
    X0:
    call FA
    j N0
    X1:
    mv s4 a0
    mv s5 a1
    mv s6 a2
    mv s7 a3
    mv s8 a4
    mv s9 a5
    call SB
    leave8
    FA:
    enter1
    la opt_c t0
    sd 0 zero t0
    la opt_a t0
    ld 0 t0 t1
    beqz FA9 t1
    sd 0 zero t0
    la opt_push a0
    li 0 a1
    li 0 a5
    call SB
    call R0
    FA9:
    leave1
    F0:
    addi -112 sp sp
    sd 0 ra sp
    sd 8 a0 sp
    sd 16 a1 sp
    sd 24 a2 sp
    sd 32 a3 sp
    sd 40 a4 sp
    sd 48 a5 sp
    sd 56 t1 sp
    sd 64 t2 sp
    sd 72 t3 sp
    sd 80 t4 sp
    sd 88 t5 sp
    sd 96 t6 sp
    la opt_in t0
    ld 0 t0 t1
    bnez F9 t1
    li 1 t1
    sd 0 t1 t0
    call FA
    call FB
    la opt_held t0
    sd 0 zero t0
    la opt_in t0
    sd 0 zero t0
    F9:
    ld 0 sp ra
    ld 8 sp a0
    ld 16 sp a1
    ld 24 sp a2
    ld 32 sp a3
    ld 40 sp a4
    ld 48 sp a5
    ld 56 sp t1
    ld 64 sp t2
    ld 72 sp t3
    ld 80 sp t4
    ld 88 sp t5
    ld 96 sp t6
    addi 112 sp sp
    ret
    R0:
    enter1
    li 0 s4
    R1:
    la opt_n t0
    ld 0 t0 t1
    bge rel:R9 t1 s4
    li 48 t2
    mul t2 s4 t2
    la opt_buf t0
    add t2 t0 t0
    ld 0 t0 a0
    ld 8 t0 a1
    ld 16 t0 a2
    ld 24 t0 a3
    ld 32 t0 a4
    ld 40 t0 a5
    call SB
    addi 1 s4 s4
    j R1
    R9:
    la opt_n t0
    sd 0 zero t0
    leave1
    FB:
    enter1
    li 0 s4
    FB1:
    la optb_n t0
    ld 0 t0 t1
    bge rel:FB9 t1 s4
    li 48 t2
    mul t2 s4 t2
    la optb_buf t0
    add t2 t0 t0
    ld 0 t0 a0
    ld 8 t0 a1
    ld 16 t0 a2
    ld 24 t0 a3
    ld 32 t0 a4
    ld 40 t0 a5
    call prim0
    addi 1 s4 s4
    j FB1
    FB9:
    la optb_n t0
    sd 0 zero t0
    leave1
    SAFE:
    enter3
    mv a0 s4
    mv a1 s5
    la opt_safe s6
    Q1:
    lbu 0 s6 t0
    beqz Q0 t0
    mv s4 a0
    mv s6 a2
    call cstreq
    bnez Q2 a0
    Q3:
    lbu 0 s6 t0
    addi 1 s6 s6
    bnez Q3 t0
    j Q1
    Q2:
    la opt_safe1 t0
    bgeu rel:Q4 t0 s6
    beqz Q0 s5
    mv s5 a0
    la opt_l a2
    call cstreq
    bnez Q0 a0
    Q4:
    li 1 a0
    leave3
    Q0:
    li 0 a0
    leave3
    FIND:
    enter3
    mv a0 s4
    mv a1 s5
    li 0 s6
    D1:
    lbu 0 s5 t0
    beqz D0 t0
    mv s4 a0
    mv s5 a2
    call cstreq
    bnez D2 a0
    addi 12 s5 s5
    addi 1 s6 s6
    j D1
    D2:
    mv s6 a0
    leave3
    D0:
    li -1 a0
    leave3
    SB:
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
    la optb_n t0
    ld 0 t0 s10
    bnez B1 s10
    beqz BO s9
    beqz BO s6
    addi 255 s6 t0
    li 511 t1
    bgeu rel:BO t1 t0
    la opt_lipos a2
    call cstreq
    bnez B0 a0
    mv s4 a0
    la opt_lineg a2
    call cstreq
    beqz BO a0
    B0:
    mv s9 a0
    la opt_v a2
    call cstreq
    bnez BA a0
    mv s9 a0
    la opt_l a2
    call cstreq
    bnez BA a0
    j BO
    B1:
    li 1 t0
    bne rel:B2 t0 s10
    la optb_buf t0
    ld 40 t0 a0
    la opt_v a2
    call cstreq
    la opt_addfp a2
    bnez B11 a0
    la opt_addfpl a2
    B11:
    mv s4 a0
    call cstreq
    bnez BA a0
    j BM
    B2:
    li 2 t0
    bne rel:B3 t0 s10
    la optb_buf t0
    ld 40 t0 a0
    la opt_v a2
    call cstreq
    beqz B21 a0
    mv s4 a0
    la opt_lds a1
    call FIND
    bltz BM a0
    li 12 t0
    mul t0 a0 a0
    la opt_ldfps t0
    add t0 a0 a0
    li 1 a1
    la optb_buf t0
    ld 16 t0 a2
    li 0 a5
    call prim0
    la optb_n t0
    sd 0 zero t0
    leave8
    B21:
    mv s4 a0
    la opt_sts a1
    call FIND
    bltz BM a0
    j BA
    B3:
    mv s4 a0
    la opt_pop a2
    call cstreq
    bnez BK a0
    beqz BN s9
    mv s9 a0
    la opt_l a2
    call cstreq
    beqz BN a0
    mv s4 a0
    la opt_setreg a2
    call cstreq
    bnez BK a0
    mv s4 a0
    la opt_lipos a2
    call cstreq
    bnez BK a0
    mv s4 a0
    la opt_lineg a2
    call cstreq
    bnez BK a0
    mv s4 a0
    la opt_libig a2
    call cstreq
    bnez BK a0
    BN:
    li 9 t0
    bge rel:BM t0 s10
    bnez BN1 s5
    mv s4 a0
    la opt_push a2
    call cstreq
    bnez BA a0
    BN1:
    mv s4 a0
    mv s9 a1
    call SAFE
    bnez BA a0
    j BM
    BK:
    la optb_buf t0
    ld 96 t0 a0
    la opt_sts a1
    call FIND
    li 12 t0
    mul t0 a0 a0
    la opt_stfps t0
    add t0 a0 a0
    li 1 a1
    la optb_buf t0
    ld 16 t0 a2
    li 0 a5
    call prim0
    li 3 a0
    call RF
    leave8
    BA:
    la optb_n t0
    ld 0 t0 t1
    addi 1 t1 t2
    sd 0 t2 t0
    li 48 t2
    mul t2 t1 t1
    la optb_buf t0
    add t1 t0 t0
    sd 0 s4 t0
    sd 8 s5 t0
    sd 16 s6 t0
    sd 24 s7 t0
    sd 32 s8 t0
    sd 40 s9 t0
    la opt_held t0
    li 1 t1
    sd 0 t1 t0
    leave8
    BO:
    mv s4 a0
    mv s5 a1
    mv s6 a2
    mv s7 a3
    mv s8 a4
    mv s9 a5
    call prim0
    leave8
    BM:
    la optb_buf t0
    ld 0 t0 a0
    ld 8 t0 a1
    ld 16 t0 a2
    ld 24 t0 a3
    ld 32 t0 a4
    ld 40 t0 a5
    call prim0
    li 1 a0
    call RF
    leave8
    RF:
    addi -512 sp sp
    sd 0 ra sp
    sd 8 s10 sp
    sd 16 s11 sp
    la optb_n t0
    ld 0 t0 t1
    sd 0 zero t0
    addi 32 sp t2
    li 0 s11
    RF1:
    bge rel:RF2 t1 a0
    li 48 t3
    mul t3 a0 t3
    la optb_buf t0
    add t3 t0 t0
    ld 0 t0 t3
    sd 0 t3 t2
    ld 8 t0 t3
    sd 8 t3 t2
    ld 16 t0 t3
    sd 16 t3 t2
    ld 24 t0 t3
    sd 24 t3 t2
    ld 32 t0 t3
    sd 32 t3 t2
    ld 40 t0 t3
    sd 40 t3 t2
    addi 48 t2 t2
    addi 1 s11 s11
    addi 1 a0 a0
    j RF1
    RF2:
    sd 0 s4 t2
    sd 8 s5 t2
    sd 16 s6 t2
    sd 24 s7 t2
    sd 32 s8 t2
    sd 40 s9 t2
    addi 1 s11 s11
    li 0 s10
    RF3:
    bge rel:RF9 s11 s10
    li 48 t3
    mul t3 s10 t3
    addi 32 sp t0
    add t3 t0 t0
    ld 0 t0 a0
    ld 8 t0 a1
    ld 16 t0 a2
    ld 24 t0 a3
    ld 32 t0 a4
    ld 40 t0 a5
    call SB
    addi 1 s10 s10
    j RF3
    RF9:
    ld 0 sp ra
    ld 8 sp s10
    ld 16 sp s11
    addi 512 sp sp
    ret
", 6);
once(\$t, "\n    2:\n      comment\n        the C layer, definitions", "\n${opt}    2:\n      comment\n        the C layer, definitions", 'cc layer 2');
save();
