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
#   emits the push and the held ones as they were, then itself.
#
# The decisions depend only on the primitives' names and arguments, so
# pass 1 and pass 2 make the same. What is held is emitted (flushed) before
# anything else is: optflush, called by emit_raw, skip and code_call (every
# byte and every macro), by label (it reads cur_pc), jit and generic (they
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

# ---- the variables (bss): after data_at
once(\$t, "  data_at:\n    reserve\n      2048\n",
    "  data_at:\n    reserve\n      2048\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
        [opt_on => 8], [opt_held => 8], [opt_n => 8], [opt_fn => 8], [opt_buf => 8 * 48]), 'data_at');

# ---- the names it knows, after cc_names
my @safe = qw(cc_global cc_addfp cc_load_i8 cc_load_i16 cc_load_i32 cc_load_i64 cc_load_u8 cc_load_u16 cc_load_u32 cc_load_u64
    cc_ext_i8 cc_ext_i16 cc_ext_i32 cc_ext_u8 cc_ext_u16 cc_ext_u32 cc_bool cc_neg cc_not cc_inv);
my $names = join '', map { "  $_->[0]:\n    ascii\n      $_->[1]\n" }
    [opt_push => 'cc_push\x00'], [opt_pop => 'cc_pop\x00'], [opt_setreg => 'cc_setreg\x00'], [opt_l => 'cc_l\x00'],
    [opt_safe => 'cc_li_pos\x00cc_li_neg\x00cc_li_big\x00'], [opt_safe1 => join('', map { "$_\\x00" } @safe) . '\x00'];
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
edit(\$t, 'cc/generic', "        enter8\n", "        enter8\n" . asm(8, "call optflush"),
    "        ld\n          192\n          sp\n          t1\n        la\n          cur_pc\n",
    asm(8, "
    la opt_held t0
    sd 0 zero t0
    la opt_n t0
    sd 0 zero t0
") . "        ld\n          192\n          sp\n          t1\n        la\n          cur_pc\n");
# each pass starts with none held
edit(\$t, 'compile_page', "      la\n        ct_placed\n        t0\n", asm(6, "
    la opt_held t0
    sd 0 zero t0
    la opt_n t0
    sd 0 zero t0
") . "      la\n        ct_placed\n        t0\n");

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
    la opt_fn t0
    ld 0 t0 t0
    jalr 0 t0 zero
", 2);
once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');

# ---- the group opt: of cc, at the end of its layer 1
my $opt = cfn('opt', "the peephole of -O (gen/patches/opt.pl): prim's a0..a5, a primitive, held (cc_push, then what touches only V or X), rewritten (cc_pop after them: cc_setreg cc_l, then them) or emitted (prim0) after what it holds; F0 emits what it holds, R0 the primitives held after the push", "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv a3 s7
    mv a4 s8
    mv a5 s9
    la ccs t0
    ld CC_jit t0 t0
    bnez J0 t0
    la opt_held t0
    ld 0 t0 t0
    bnez H1 t0
    N0:
    mv s4 a0
    bnez X1 s5
    la opt_push a2
    call cstreq
    beqz X1 a0
    la opt_held t0
    li 1 t1
    sd 0 t1 t0
    la opt_n t0
    sd 0 zero t0
    la F0 t1
    la opt_fn t0
    sd 0 t1 t0
    leave8
    H1:
    bnez H2 s5
    la opt_pop a2
    call cstreq
    beqz H2 a0
    la opt_held t0
    sd 0 zero t0
    la opt_setreg a0
    li 1 a1
    la opt_l a5
    call prim0
    call R0
    leave8
    H2:
    la opt_n t0
    ld 0 t0 t0
    li 8 t1
    bge rel:X0 t1 t0
    la opt_safe s10
    S1:
    lbu 0 s10 t0
    beqz X0 t0
    mv s4 a0
    mv s10 a2
    call cstreq
    bnez S2 a0
    S4:
    lbu 0 s10 t0
    addi 1 s10 s10
    bnez S4 t0
    j S1
    S2:
    la opt_safe1 t0
    bgeu rel:S3 t0 s10
    beqz X0 s9
    mv s9 a0
    la opt_l a2
    call cstreq
    bnez X0 a0
    S3:
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
    J0:
    call F0
    j X1
    X0:
    call F0
    j N0
    X1:
    mv s4 a0
    mv s5 a1
    mv s6 a2
    mv s7 a3
    mv s8 a4
    mv s9 a5
    call prim0
    leave8
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
    la opt_held t0
    ld 0 t0 t1
    beqz F9 t1
    sd 0 zero t0
    la opt_push a0
    li 0 a1
    li 0 a5
    call prim0
    call R0
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
    call prim0
    addi 1 s4 s4
    j R1
    R9:
    la opt_n t0
    sd 0 zero t0
    leave1
", 6);
once(\$t, "\n    2:\n      comment\n        the C layer, definitions", "\n${opt}    2:\n      comment\n        the C layer, definitions", 'cc layer 2');
save();
