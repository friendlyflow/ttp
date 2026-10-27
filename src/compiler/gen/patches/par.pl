# par.pl: ttpc -j N, the second pass on N processes. The first pass runs
# as before and takes samples of the state the second pass will meet:
# where in the library's list (cc_library) a function is about to be
# compiled, after a share of the work (the listing's bytes, which the
# first pass counts as the second will write them), at most 128 of them
# (past that every other one goes and the share doubles), and one at the
# end of the list. A sample is the place in the list and the loop (1 the
# first, 2 the second, 3 the end), the labels placed so far, the listing's
# bytes so far, then what par_vars names: the words, tables and counts the
# second pass builds again (each pass clears them), as they are there. At
# the first sample of the second pass the samples are cut into N shares of
# the work; a process (clone, as fork) is started for each share but the
# first, which takes up the state of its sample and goes on from there,
# writes its code into its own copy of the output (outbuf) and its listing
# into a shared one where the first pass's count puts it, checks that it
# meets its end in the state the first pass recorded there (else it stops
# with the place), copies its code into the shared output and exits. The
# first process compiles the first share, checks the same, waits for the
# others (wait4; one that fails stops all, with its status), writes their
# listing, takes their code and the state of the end, and goes on. Output
# and listing are byte for byte those of the one pass. -j1 and no -j are
# as before; -j0 checks: one process, whose second pass compares its state
# with each sample. Compile time's JIT never samples or forks. Run on
# ttpc.ff, then with T=ttpc.defs.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_moved_len:\n    size\n      msg_moved\n",
        "  msg_moved_len:\n    size\n      msg_moved\n  msg_jstate_len:\n    size\n      msg_jstate\n  msg_jsys_len:\n    size\n      msg_jsys\n", 'msg_moved_len');
    save();
    exit;
}

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my @l = ($text =~ m{(.{1,250})(?: |$)}g);
    my $c = " " x ($ind + 2) . "comment\n" . join("", map { " " x ($ind + 4) . "$_\n" } @l);
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# ---- the switch: -j N or -jN, before or after -O, -g and --target X
$t =~ s/^( +)call\n\1  optflag\n\1call\n\1  dbgflag\n\1call\n\1  optflag\n/$1call\n$1  allflags\n/mg == 2 or die "par: flag calls\n";

# ---- the listing: place's lines through write_out too, which in a
# process of a share appends to its part of the shared listing
my $w = "      li\n        SYS_write\n        a7\n      ecall\n";
edit(\$t, 'place',
    "      li\n        1\n        a0\n      la\n        linebuf\n        a1\n", "      la\n        linebuf\n        a1\n",
    "        a2\n$w      li\n        1\n        a0\n      ld\n", "        a2\n      call\n        write_out\n      ld\n",
    "        a2\n$w      li\n        1\n        a0\n      la\n        str_place\n", "        a2\n      call\n        write_out\n      la\n        str_place\n",
    "        a2\n$w    L6:\n", "        a2\n      call\n        write_out\n    L6:\n",
    "    L2:\n", "    L2:\n      call\n        parlst2\n");
edit(\$t, 'emit', "    call\n      emit_raw\n", "    call\n      emit_raw\n    call\n      parlst1\n");
once(\$t, "  write_out:\n    li\n      STDOUT\n      a0\n    li\n      SYS_write\n      a7\n    ecall\n    ret\n", fn('write_out', "
    la par_lcur a7
    ld 0 a7 a7
    bnez W1 a7
    li STDOUT a0
    li SYS_write a7
    ecall
    ret
    W1:
    beqz W2 a2
    lbu 0 a1 a0
    sb 0 a0 a7
    addi 1 a1 a1
    addi 1 a7 a7
    addi -1 a2 a2
    j W1
    W2:
    la par_lcur a0
    sd 0 a7 a0
    la par_lend a0
    ld 0 a0 a0
    bltu rel:W8 a7 a0
    ret
    W8:
    li 2 a0
    j parfail
"), 'write_out');

# ---- the hooks: in cc_library before an entry is compiled, in either
# loop, and at the end of the list; PJ goes where parhook says
edit(\$t, 'cc_library',
    "          bgeu\n            rel\n              L3\n            t0\n            s4\n",
    "          bgeu\n            rel\n              L3\n            t0\n            s4\n" . asm(10, "
    mv s4 a0
    li 1 a1
    call parhook
    bne rel:PJ zero a0
"),
    "          bgeu\n            rel\n              L9\n            t0\n            s4\n",
    "          bgeu\n            rel\n              L9\n            t0\n            s4\n" . asm(10, "
    mv s4 a0
    li 2 a1
    call parhook
    bne rel:PJ zero a0
"),
    "          call\n            irelplace\n          call\n            dbgarea\n          leave3\n",
    asm(10, "
    li -1 a0
    li 3 a1
    call parhook
    bne rel:PJ zero a0
") . "        P9:\n          call\n            irelplace\n          call\n            dbgarea\n          leave3\n" . asm(8, "
    PJ:
    mv a1 s4
    li 1 t0
    beq rel:L1 t0 a0
    li 2 t0
    beq rel:L5 t0 a0
    j P9
"));

# ---- each pass starts the samples
edit(\$t, 'compile_page', "      mv\n        s7\n        a0\n      call\n        run_placed\n",
    "      call\n        parpass\n      mv\n        s7\n        a0\n      call\n        run_placed\n");

# ---- the state
my $vars = '';
my @v = ([1, 'cur_pc', 0, 8], [1, 'in_bss', 0, 8], [1, 'out_end', 0, 8], [1, 'scope_depth', 0, 8],
    [1, 'ccs', 0, 'CC_swx'], [1, 'ccs', 'CC_rty', 24], [1, 'data_state', 0, 24], [1, 'dbg_area', 0, 32], [1, 'dbg_cst', 0, 16],
    [1, 'dbg_fns', 0, 8], [1, 'dbg_regs', 0, 8], [1, 'dbg_lines', 0, 8], [1, 'ct_placed', 0, 8],
    [1, 'sec_vars', 0, 8200], [1, 'sec_placing', 0, 8], [2, 'data_vars', 0, 8], [3, 'tls_vars', 0, 8],
    [1, 'tls_vars', 32768, 16], [2, 'irw_vars', 0, 16],
    map { [1, $_->[0], 0, $_->[1]] } [opt_held => 8], [opt_in => 8], [opt_a => 8], [opt_c => 8], [opt_n => 8],
        [opt_fn => 8], [opt_buf => 384], [optb_n => 8], [optb_buf => 480], [opt_dead => 8], [opt_jheld => 8],
        [opt_jid => 8], [opt_jlab => 8], [opt_jbuf => 48], [opt_spk => 8], [opt_spv => 8], [opt_spnew => 8],
        [opt_spset => 8], [opt_spdrop => 8], [opt_insync => 8], [opt_inprim => 8]);
$vars .= "dword $_->[0]\ndword $_->[1]\ndword $_->[2]\ndword $_->[3]\n" for @v;
once(\$t, "  cc_loads:\n", cfn('par_vars', "the state a sample of -j keeps: kind (1 its bytes, 2 a count and as many entries after it, 3 the same after 16 bytes), name, offset, bytes (of an entry); cur_pc, in_bss and out_end first (a sample's 32, 40, 48)", $vars . "dword 0\n", 2) . "  cc_loads:\n", 'cc_loads');
once(\$t, "  msg_moved:\n", "  msg_jstate:\n    ascii\n      ttpc -j: the second pass does not meet the state the first recorded (the list's place, what differs):\\x20\n  msg_jsys:\n    ascii\n      ttpc -j: a system call failed (mmap, clone or wait4)\\x0a\n  msg_moved:\n", 'msg_moved');

my $res = '';
$res .= "  $_->[0]:\n    reserve\n      $_->[1]\n" for [par_n => 8], [par_chk => 8], [par_go => 8], [par_lo => 8], [par_hi => 8],
    [par_kid => 8], [par_m => 8], [par_lst => 8], [par_lastw => 8], [par_w => 8], [par_ns => 8], [par_nfree => 8],
    [par_sbuf => 8], [par_endb => 8], [par_samp => 1040], [par_free => 1040], [par_bnd => 528], [par_pids => 520],
    [par_sout => 8], [par_slst => 8], [par_lcur => 8], [par_lend => 8], [par_tmp => 16], [par_txt => 40];
once(\$t, "  opt_cli:\n    reserve\n      8\n", "  opt_cli:\n    reserve\n      8\n$res", 'opt_cli');

# ---- the functions, before write_output
my $c = '';
$c .= cfn('allflags', "a0 a1: _start's count of arguments and pointer; past the switches -j N, -O and -g, in any order", "
    addi -16 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    F1:
    mv a0 s4
    call jflag
    call optflag
    call dbgflag
    bne rel:F1 s4 a0
    ld 0 sp ra
    ld 8 sp s4
    addi 16 sp sp
    ret
", 2);
$c .= cfn('jflag', "a0 a1 as optflag; past a first -j N or -jN: par_n N (at most 64), none for 1, -j0 checks (par_chk)", "
    li 2 t1
    blt rel:J9 t1 a0
    ld 8 a1 t2
    lbu 0 t2 t3
    li 45 t4
    bne rel:J9 t4 t3
    lbu 1 t2 t3
    li 106 t4
    bne rel:J9 t4 t3
    lbu 2 t2 t3
    addi 2 t2 t2
    li 1 t5
    bnez J2 t3
    li 3 t1
    blt rel:J9 t1 a0
    ld 16 a1 t2
    li 2 t5
    J2:
    lbu 0 t2 t3
    beqz J9 t3
    li 0 t6
    J3:
    lbu 0 t2 t3
    beqz J4 t3
    addi -48 t3 t3
    li 10 t4
    bgeu rel:J9 t4 t3
    mul t4 t6 t6
    add t3 t6 t6
    addi 1 t2 t2
    j J3
    J4:
    la par_n t0
    la par_chk t1
    sd 0 zero t1
    bnez J5 t6
    li 1 t3
    sd 0 t3 t1
    li 2 t6
    J5:
    li 1 t3
    bne rel:J6 t3 t6
    li 0 t6
    J6:
    li 64 t3
    bgeu rel:J7 t6 t3
    mv t3 t6
    J7:
    sd 0 t6 t0
    slli 3 t5 t4
    add t4 a1 a1
    sub t5 a0 a0
    J9:
    ret
", 2);
$c .= cfn('parlst1', "emit's listing in the first pass with -j: the bytes its line will have (s5 bits, s6 the node), in par_lst", "
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:Q9 t1 t0
    la par_n t0
    ld 0 t0 t0
    beqz Q9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez Q9 t0
    srli 2 s5 t0
    lbu NODE_content_len s6 t1
    add t1 t0 t0
    addi 3 t0 t0
    la par_lst t1
    ld 0 t1 t2
    add t0 t2 t2
    sd 0 t2 t1
    Q9:
    ret
", 2);
$c .= cfn('parlst2', "place's line, as parlst1 (s4 the node)", "
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:Q9 t1 t0
    la par_n t0
    ld 0 t0 t0
    beqz Q9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez Q9 t0
    lbu NODE_content_len s4 t0
    addi 18 t0 t0
    la par_lst t1
    ld 0 t1 t2
    add t0 t2 t2
    sd 0 t2 t1
    Q9:
    ret
", 2);
$c .= cfn('parwalk', "the state par_vars names and the sample a0: a1 0 into the sample, 1 back from it, 2 compared (a0 0, else 1 + the place in the sample that differs)", "
    la par_vars a2
    addi 32 a0 a3
    li 0 a4
    V1:
    ld 0 a2 t0
    beqz V9 t0
    ld 8 a2 t1
    ld 16 a2 t2
    add t2 t1 t1
    ld 24 a2 t2
    li 1 t3
    beq rel:V4 t3 t0
    ld 0 t1 t4
    beqz V2 a1
    ld 0 a3 t4
    V2:
    mul t4 t2 t2
    addi 8 t2 t2
    li 3 t3
    bne rel:V4 t3 t0
    addi 8 t2 t2
    V4:
    beqz V8 t2
    li 1 t3
    beq rel:V5 t3 a1
    li 2 t3
    beq rel:V6 t3 a1
    ld 0 t1 t4
    sd 0 t4 a3
    j V7
    V5:
    ld 0 a3 t4
    sd 0 t4 t1
    j V7
    V6:
    ld 0 a3 t4
    ld 0 t1 t5
    beq rel:V7 t5 t4
    bnez V7 a4
    sub a0 a3 a4
    addi 1 a4 a4
    V7:
    addi 8 t1 t1
    addi 8 a3 a3
    addi -8 t2 t2
    j V4
    V8:
    addi 32 a2 a2
    j V1
    V9:
    mv a4 a0
    ret
", 2);
$c .= cfn('parfix', "after parwalk took up the sample s6: label_next its labels, CC_pass this pass", "
    ld 16 s6 t0
    la labels_base t1
    ld 0 t1 t1
    add t1 t0 t0
    la label_next t1
    sd 0 t0 t1
    la pass t0
    ld 0 t0 t0
    la ccs t1
    sd CC_pass t0 t1
    ret
", 2);
$c .= cfn('parcmpx', "a0 0 if the state is the sample s6's, else what differs (17 the labels)", "
    addi -16 sp sp
    sd 0 ra sp
    la ccs t1
    li 1 t0
    sd CC_pass t0 t1
    mv s6 a0
    li 2 a1
    call parwalk
    la pass t0
    ld 0 t0 t0
    la ccs t1
    sd CC_pass t0 t1
    bnez X9 a0
    la label_next t0
    ld 0 t0 t0
    la labels_base t1
    ld 0 t1 t1
    sub t1 t0 t0
    ld 16 s6 t1
    li 0 a0
    beq rel:X9 t1 t0
    li 17 a0
    X9:
    ld 0 sp ra
    addi 16 sp sp
    ret
", 2);
$c .= cfn('parfail', "stops: the state differs (a0 what, s4 the list's place)", "
    mv a0 t6
    la par_txt a3
    mv s4 a0
    call parhex
    li 32 t0
    sb 0 t0 a3
    addi 1 a3 a3
    mv t6 a0
    call parhex
    la par_txt a3
    li 33 a4
    la msg_jstate a1
    li msg_jstate_len a2
    j die_name
", 2);
$c .= cfn('parhex', "a0 in 16 hex digits at a3, past them", "
    la hexdigits t1
    li 60 t2
    H1:
    srl t2 a0 t3
    andi 15 t3 t3
    add t3 t1 t3
    lbu 0 t3 t3
    sb 0 t3 a3
    addi 1 a3 a3
    addi -4 t2 t2
    bgez H1 t2
    ret
", 2);
$c .= cfn('parsys', "a0 a system call's result: back if it is no error", "
    li -4095 t0
    bgeu rel:Y1 t0 a0
    ret
    Y1:
    la msg_jsys a1
    li msg_jsys_len a2
    j die
", 2);
$c .= cfn('parpass', "compile_page, each pass: with -j, the first starts the samples (their 130 buffers of 256 KiB, mapped once)", "
    la par_n t0
    ld 0 t0 t0
    beqz P9 t0
    la par_go t0
    sd 0 zero t0
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:P9 t1 t0
    la par_sbuf t0
    ld 0 t0 t1
    bnez P2 t1
    addi -16 sp sp
    sd 0 ra sp
    li 0 a0
    li32 34078720 a1
    li 3 a2
    li32 16418 a3
    li -1 a4
    li 0 a5
    li SYS_mmap a7
    ecall
    call parsys
    ld 0 sp ra
    addi 16 sp sp
    la par_sbuf t0
    sd 0 a0 t0
    P2:
    la par_sbuf t0
    ld 0 t0 t1
    la par_free t2
    li 0 t3
    P3:
    sd 0 t1 t2
    addi 8 t2 t2
    li32 262144 t4
    add t4 t1 t1
    addi 1 t3 t3
    li 129 t4
    bltu rel:P3 t4 t3
    la par_endb t2
    sd 0 t1 t2
    la par_nfree t2
    li 129 t3
    sd 0 t3 t2
    la par_ns t0
    sd 0 zero t0
    la par_lst t0
    sd 0 zero t0
    la par_lastw t0
    sd 0 zero t0
    la par_w t0
    li 1 t1
    sd 0 t1 t0
    la par_kid t0
    sd 0 zero t0
    P9:
    ret
", 2);
$c .= cfn('parhook', "cc_library: the entry a0 (-1 the list's end) of the loop a1 is next; a0 0 go on, else where to go on (a1 the entry): 1 the first loop, 2 the second, 3 the end", "
    la par_n t0
    ld 0 t0 t0
    bnez K0 t0
    li 0 a0
    ret
    K0:
    la ccs t0
    ld CC_jit t0 t0
    beqz K1 t0
    li 0 a0
    ret
    K1:
    addi -48 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    mv a0 s4
    mv a1 s5
    bgez K2 s4
    li 1 s4
    slli 40 s4 s4
    K2:
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:K3 t1 t0
    call parrec
    j K8
    K3:
    la par_chk t0
    ld 0 t0 t0
    beqz K4 t0
    call parcheck
    j K8
    K4:
    la par_go t0
    ld 0 t0 t0
    bnez K5 t0
    call parstart
    K5:
    la par_lo t0
    ld 0 t0 t0
    bgeu rel:K6 t0 s4
    la par_kid t0
    ld 0 t0 t0
    slli 3 t0 t0
    la par_bnd t1
    add t1 t0 t0
    ld 0 t0 s6
    mv s6 a0
    li 1 a1
    call parwalk
    call parfix
    ld 8 s6 a0
    ld 0 s6 a1
    j K9
    K6:
    la par_hi t0
    ld 0 t0 t0
    bltu rel:K8 t0 s4
    la par_kid t0
    ld 0 t0 t0
    beqz K7 t0
    call parend
    K7:
    call parjoin
    li 3 a0
    j K9
    K8:
    li 0 a0
    K9:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    addi 48 sp sp
    ret
", 2);
$c .= cfn('parrec', "the first pass at the entry s4 (1 << 40 the end) of the loop s5: a sample, at the first, the end and past each par_w bytes of the listing (128 at most: then every other one goes and par_w doubles)", "
    addi -16 sp sp
    sd 0 ra sp
    li 1 t0
    slli 40 t0 t0
    bne rel:R1 t0 s4
    la par_endb t0
    ld 0 t0 s6
    j R5
    R1:
    la par_ns t0
    ld 0 t0 t1
    beqz R3 t1
    la par_lst t2
    ld 0 t2 t2
    la par_lastw t3
    ld 0 t3 t3
    sub t3 t2 t2
    la par_w t3
    ld 0 t3 t3
    bltu rel:R9 t3 t2
    li 128 t2
    bltu rel:R3 t2 t1
    la par_samp t2
    li 1 t3
    R2:
    slli 4 t3 t4
    add t4 t2 t4
    ld 0 t4 t5
    ld -8 t4 t6
    la par_nfree a2
    ld 0 a2 a3
    slli 3 a3 a4
    la par_free a5
    add a5 a4 a4
    sd 0 t6 a4
    addi 1 a3 a3
    sd 0 a3 a2
    slli 3 t3 t4
    add t4 t2 t4
    sd 0 t5 t4
    addi 1 t3 t3
    li 64 t4
    bltu rel:R2 t4 t3
    ld 1016 t2 t6
    la par_nfree a2
    ld 0 a2 a3
    slli 3 a3 a4
    la par_free a5
    add a5 a4 a4
    sd 0 t6 a4
    addi 1 a3 a3
    sd 0 a3 a2
    li 64 t1
    la par_ns t0
    sd 0 t1 t0
    la par_w t0
    ld 0 t0 t2
    slli 1 t2 t2
    sd 0 t2 t0
    R3:
    la par_nfree a2
    ld 0 a2 a3
    addi -1 a3 a3
    sd 0 a3 a2
    slli 3 a3 a4
    la par_free a5
    add a5 a4 a4
    ld 0 a4 s6
    la par_ns t0
    ld 0 t0 t1
    slli 3 t1 t2
    la par_samp t3
    add t3 t2 t2
    sd 0 s6 t2
    addi 1 t1 t1
    sd 0 t1 t0
    la par_lst t0
    ld 0 t0 t0
    la par_lastw t1
    sd 0 t0 t1
    R5:
    sd 0 s4 s6
    sd 8 s5 s6
    la labels_end t0
    ld 0 t0 t0
    la labels_base t1
    ld 0 t1 t1
    sub t1 t0 t0
    sd 16 t0 s6
    la par_lst t0
    ld 0 t0 t0
    sd 24 t0 s6
    mv s6 a0
    li 0 a1
    call parwalk
    R9:
    ld 0 sp ra
    addi 16 sp sp
    ret
", 2);
$c .= cfn('parcheck', "-j0, the second pass at the entry s4: the state the sample there has, if there is one", "
    addi -16 sp sp
    sd 0 ra sp
    li 1 t0
    slli 40 t0 t0
    bne rel:Z1 t0 s4
    la par_endb t1
    ld 0 t1 s6
    j Z5
    Z1:
    la par_samp t1
    la par_ns t2
    ld 0 t2 t2
    li 0 t3
    Z2:
    bgeu rel:Z9 t2 t3
    slli 3 t3 t4
    add t4 t1 t4
    ld 0 t4 s6
    ld 0 s6 t5
    addi 1 t3 t3
    bne rel:Z2 t5 s4
    Z5:
    call parcmpx
    beqz Z9 a0
    j parfail
    Z9:
    ld 0 sp ra
    addi 16 sp sp
    ret
", 2);
$c .= cfn('parstart', "the second pass's first sample (the entry s4): the samples cut into par_n shares of the listing's bytes (par_bnd), the shared output and listing mapped, a process started for each share but the first (par_kid 1 ...), each with its range par_lo par_hi of entries", "
    addi -16 sp sp
    sd 0 ra sp
    la par_go t0
    li 1 t1
    sd 0 t1 t0
    la par_lo t0
    sd 0 s4 t0
    li -1 t1
    la par_hi t0
    sd 0 t1 t0
    la par_m t0
    sd 0 zero t0
    la par_ns t0
    ld 0 t0 t6
    beqz S9 t6
    la par_samp t0
    ld 0 t0 t2
    ld 0 t2 t3
    bne rel:S9 t3 s4
    la par_bnd t0
    sd 0 t2 t0
    ld 24 t2 a2
    la par_endb t3
    ld 0 t3 t3
    ld 24 t3 a3
    sub a2 a3 a3
    la par_n t3
    ld 0 t3 a4
    li 1 a5
    li 1 t5
    li 0 s7
    S1:
    bgeu rel:S5 a4 a5
    mul a5 a3 t0
    divu a4 t0 t0
    add a2 t0 t0
    S2:
    bgeu rel:S5 t6 t5
    slli 3 t5 t1
    la par_samp t2
    add t2 t1 t1
    ld 0 t1 t1
    ld 24 t1 t2
    addi 1 t5 t5
    bltu rel:S2 t0 t2
    addi 1 s7 s7
    slli 3 s7 t2
    la par_bnd t3
    add t3 t2 t2
    sd 0 t1 t2
    addi 1 a5 a5
    j S1
    S5:
    beqz S9 s7
    addi 1 s7 t1
    slli 3 t1 t1
    la par_bnd t2
    add t2 t1 t1
    la par_endb t2
    ld 0 t2 t2
    sd 0 t2 t1
    la par_m t0
    sd 0 s7 t0
    ld 48 t2 a1
    la outbuf t0
    sub t0 a1 a1
    addi 1 a1 a1
    li 0 a0
    li 3 a2
    li32 16417 a3
    li -1 a4
    li 0 a5
    li SYS_mmap a7
    ecall
    call parsys
    la par_sout t0
    sd 0 a0 t0
    la par_bnd t0
    ld 8 t0 t0
    ld 24 t0 t1
    la par_endb t2
    ld 0 t2 t2
    ld 24 t2 a1
    sub t1 a1 a1
    addi 1 a1 a1
    li 0 a0
    li 3 a2
    li32 16417 a3
    li -1 a4
    li 0 a5
    li SYS_mmap a7
    ecall
    call parsys
    la par_slst t0
    sd 0 a0 t0
    li 1 t5
    S6:
    bltu rel:S8 t5 s7
    li 17 a0
    li 0 a1
    li 0 a2
    li 0 a3
    li 0 a4
    li SYS_clone a7
    ecall
    call parsys
    beqz S7 a0
    slli 3 t5 t1
    la par_pids t2
    add t2 t1 t1
    sd 0 a0 t1
    addi 1 t5 t5
    j S6
    S7:
    la par_kid t0
    sd 0 t5 t0
    slli 3 t5 t1
    la par_bnd t2
    add t2 t1 t1
    ld 0 t1 t2
    ld 8 t1 t3
    ld 0 t2 t4
    la par_lo t0
    sd 0 t4 t0
    ld 0 t3 t4
    la par_hi t0
    sd 0 t4 t0
    la par_bnd t0
    ld 8 t0 t0
    ld 24 t0 t0
    la par_slst t1
    ld 0 t1 t1
    sub t0 t1 t1
    ld 24 t2 t4
    add t1 t4 t4
    la par_lcur t0
    sd 0 t4 t0
    ld 24 t3 t4
    add t1 t4 t4
    la par_lend t0
    sd 0 t4 t0
    j S9
    S8:
    la par_bnd t0
    ld 8 t0 t0
    ld 0 t0 t1
    la par_hi t0
    sd 0 t1 t0
    S9:
    ld 0 sp ra
    addi 16 sp sp
    ret
", 2);
$c .= cfn('parend', "a share's process at its end (the entry s4): its state checked against its end's sample, its code into the shared output, exit", "
    la par_kid t0
    ld 0 t0 t0
    addi 1 t0 t0
    slli 3 t0 t0
    la par_bnd t1
    add t1 t0 t0
    ld 0 t0 s6
    call parcmpx
    beqz E0 a0
    j parfail
    E0:
    la par_lcur t0
    ld 0 t0 t0
    la par_lend t1
    ld 0 t1 t1
    li 2 a0
    beq rel:E3 t1 t0
    j parfail
    E3:
    la par_kid t0
    ld 0 t0 t0
    slli 3 t0 t0
    la par_bnd t1
    add t1 t0 t0
    ld 0 t0 t0
    ld 48 t0 t1
    ld 48 s6 t2
    la outbuf t3
    sub t3 t1 t4
    la par_sout t5
    ld 0 t5 t5
    add t5 t4 t4
    E1:
    bgeu rel:E2 t2 t1
    lbu 0 t1 t5
    sb 0 t5 t4
    addi 1 t1 t1
    addi 1 t4 t4
    j E1
    E2:
    li 0 a0
    li SYS_exit_group a7
    ecall
", 2);
$c .= cfn('parjoin', "the first process at its share's end: its state checked, the others waited for (one that failed: the rest killed, its status the exit's), their listing written, their code taken, the end's state taken up", "
    addi -16 sp sp
    sd 0 ra sp
    la par_bnd t0
    ld 8 t0 s6
    call parcmpx
    beqz G0 a0
    j parfail
    G0:
    li 1 s7
    G1:
    la par_m t0
    ld 0 t0 t0
    bltu rel:G5 s7 t0
    slli 3 s7 t1
    la par_pids t2
    add t2 t1 t1
    ld 0 t1 a0
    la par_tmp a1
    sd 0 zero a1
    li 0 a2
    li 0 a3
    li SYS_wait4 a7
    ecall
    call parsys
    la par_tmp t0
    ld 0 t0 t0
    li32 65535 t1
    and t1 t0 t0
    addi 1 s7 s7
    beqz G1 t0
    li 1 t1
    andi 127 t0 t2
    bnez G2 t2
    srli 8 t0 t1
    G2:
    la par_tmp t0
    sd 8 t1 t0
    G3:
    la par_m t0
    ld 0 t0 t0
    bltu rel:G4 s7 t0
    slli 3 s7 t1
    la par_pids t2
    add t2 t1 t1
    ld 0 t1 a0
    li 9 a1
    li SYS_kill a7
    ecall
    slli 3 s7 t1
    la par_pids t2
    add t2 t1 t1
    ld 0 t1 a0
    la par_tmp a1
    li 0 a2
    li 0 a3
    li SYS_wait4 a7
    ecall
    addi 1 s7 s7
    j G3
    G4:
    la par_tmp t0
    ld 8 t0 a0
    j exit
    G5:
    la par_bnd t0
    ld 8 t0 t0
    ld 24 t0 t1
    la par_endb t2
    ld 0 t2 t2
    ld 24 t2 a2
    sub t1 a2 a2
    li STDOUT a0
    la par_slst a1
    ld 0 a1 a1
    call write_all
    la par_bnd t0
    ld 8 t0 t0
    ld 48 t0 t1
    la par_endb t2
    ld 0 t2 t2
    ld 48 t2 t2
    la outbuf t3
    sub t3 t1 t4
    la par_sout t5
    ld 0 t5 t5
    add t5 t4 t4
    C1:
    bgeu rel:C2 t2 t1
    lbu 0 t4 t5
    sb 0 t5 t1
    addi 1 t1 t1
    addi 1 t4 t4
    j C1
    C2:
    la par_endb t0
    ld 0 t0 s6
    mv s6 a0
    li 1 a1
    call parwalk
    call parfix
    li -1 t1
    la par_hi t0
    sd 0 t1 t0
    li 2 t1
    la par_go t0
    sd 0 t1 t0
    ld 0 sp ra
    addi 16 sp sp
    ret
", 2);
once(\$t, "  write_output:\n", "$c  write_output:\n", 'write_output');
# layer 2: is full: what follows opt_on (the reserves, mem_end) a layer 3: of its own
once(\$t, "\n  opt_on:\n", "\n3:\n  opt_on:\n", "opt_on");
save();
