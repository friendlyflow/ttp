# debug.pl: -g, debug information in ttpc's ELF files, first step (D1):
# section headers and symbols. With -g (first, or after --target X, on the
# command line; a build file run with -g compiles its workspaces with it)
# write_output adds to an ELF file, past its bytes (nothing of them moves):
#
#   .symtab and .strtab: a symbol per top-level name the program placed
#   (its parent the page, a layer or a group; and an asm entry, a block
#   label whose first child is asm, at any depth), its address and size
#   (LABEL_addr, LABEL_end); FUNC for a C function (one dbg_fns has: the C
#   layer's frame records each one, where its prologue starts and its
#   epilogue ends) and an asm one, OBJECT for a global (in a C program,
#   whatever else has bytes; in an asm program a label of data: dword,
#   word, half, byte, ascii, reserve, align), NOTYPE for one of no bytes;
#   local where the name has a space (c2ff's statics, "name unit"),
#   else global;
#   the section headers: .text for the code from past the ELF header to the
#   program headers (or the end of the file), split by the program's other
#   parts: each round of writable globals (.data, datasep's dataplace
#   records where each starts and ends, dbg_regs), each named section (its
#   __start_ to its __stop_, sec_vars), the TLS image (.tdata, .tbss for
#   what PT_TLS has past its file); .bss for PT_LOAD past its file; then
#   .symtab, .strtab, .shstrtab.
#
# The ELF header's e_shoff, e_shentsize, e_shnum and e_shstrndx say where
# they are. Without -g nothing is recorded and no byte changes. The writer
# reads what it needs from the ELF header and program headers in outbuf
# (ELF32 or ELF64), so every target's frame (and a program that lays itself
# out, ttpc's own) gets them. ehframe.pl adds .eh_frame (D2).
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

# a label of bytes (\xHH each), aligned after it
sub bytes {
    my ($name, $text, @b) = @_;
    push @b, 0 while @b % 8;
    my $s = '';
    while (@b) { my @d = splice @b, 0, 8; $s .= "    dword\n      " . sprintf("0x%016x", unpack 'Q<', pack 'C8', @d) . "\n" }
    "  align\n    8\n  $name:\n    comment\n      $text\n$s";
}

# The names of .shstrtab: the fixed ones, their offsets
my @names = qw(.text .data .bss .tdata .tbss .symtab .strtab .shstrtab .eh_frame_hdr .eh_frame .ARM.exidx);
my (%N, $names) = ();
$names = "\0";
for (@names) { $N{$_} = length $names; $names .= "$_\0" }
our %DBG_N = %N;
my $nlen = length $names;

# ---- the variables (bss): after datasep's
once(\$t, "  data_at:\n    reserve\n      2048\n",
    "  data_at:\n    reserve\n      2048\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
        [dbg_on => 8], [dbg_fns => 8 + 65536 * 24], [dbg_regs => 8 + 256 * 16], [dbg_area => 32],
        [dbg_st => 512], [dbg_secs => 1001 * 80], [dbg_spec => 8 + 300 * 40], [dbg_syms => 8 + 262144 * 16],
        [dbg_stk => 512], [dbg_shs => 8192]), 'data_at');

# ---- the switch: -g first, and after --target X
my $fsrc = "
    mv s10 a0
    mv s11 a1
    call dbgflag
    mv a0 s10
    mv a1 s11
";
edit(\$t, '_start',
    "    addi\n      8\n      sp\n      s11\n", "    addi\n      8\n      sp\n      s11\n" . asm(4, $fsrc),
    "    L2:\n", "    L2:\n" . asm(6, $fsrc));

# ---- each pass starts with none recorded
edit(\$t, 'compile_page', "      la\n        ct_placed\n        t0\n", asm(6, "
    la dbg_fns t0
    sd 0 zero t0
    la dbg_regs t0
    sd 0 zero t0
    la dbg_area t0
    sd 0 zero t0
    sd 8 zero t0
    sd 16 zero t0
    sd 24 zero t0
") . "      la\n        ct_placed\n        t0\n");

# ---- the C layer's frame: where a function's prologue starts, where its epilogue ends
edit(\$t, 'cc/frame',
    "        la\n          cc_prologue\n          a1\n",
    asm(8, "call dbgfn0") . "        la\n          cc_prologue\n          a1\n",
    "          cc_leaveva\n          a2\n        call\n          abiseq\n",
    "          cc_leaveva\n          a2\n        call\n          abiseq\n" . asm(8, "
    mv s4 a0
    call dbgfn1
"));

# ---- datasep's rounds of globals: where each starts and ends
edit(\$t, 'cc/dataplace',
    "        X2:\n          call\n            pagepad\n",
    "        X2:\n          call\n            pagepad\n" . asm(10, "call dbgdata0"),
    "        X4:\n", "        X4:\n" . asm(10, "call dbgdata1"));

# ---- write_output: the debug information first
edit(\$t, 'write_output', "    sd\n      8\n      s4\n      sp\n", "    sd\n      8\n      s4\n      sp\n" . asm(4, "call dbgwrite"));

my $code = '';

$code .= cfn('dbgflag', "a0 a1: _start's count of arguments and pointer (s10 s11); past a first -g, which sets dbg_on", "
    li 2 t1
    blt rel:G9 t1 a0
    ld 8 a1 t2
    lbu 0 t2 t3
    li 45 t4
    bne rel:G9 t4 t3
    lbu 1 t2 t3
    li 103 t4
    bne rel:G9 t4 t3
    lbu 2 t2 t3
    bnez G9 t3
    la dbg_on t0
    li 1 t1
    sd 0 t1 t0
    addi 8 a1 a1
    addi -1 a0 a0
    G9:
    ret
", 2);

$code .= cfn('dbgfn0', "with -g, outside compile time's JIT: the function a0 (kept) of the C layer's frame, its prologue at cur_pc, a new entry of dbg_fns (its node, start and end, 24 bytes)", "
    la dbg_on t0
    ld 0 t0 t0
    beqz B9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez B9 t0
    la dbg_fns t0
    ld 0 t0 t1
    li32 65535 t2
    bgeu rel:B9 t2 t1
    li 24 t3
    mul t3 t1 t3
    add t3 t0 t3
    sd 8 a0 t3
    la cur_pc t4
    ld 0 t4 t4
    sd 16 t4 t3
    sd 24 zero t3
    addi 1 t1 t1
    sd 0 t1 t0
    B9:
    ret
", 2);

$code .= cfn('dbgfn1', "the frame of the function a0 ends at cur_pc (past its epilogue): the end of its entry of dbg_fns, the last one", "
    la dbg_on t0
    ld 0 t0 t0
    beqz B9 t0
    la dbg_fns t0
    ld 0 t0 t1
    beqz B9 t1
    addi -1 t1 t1
    li 24 t3
    mul t3 t1 t3
    add t3 t0 t3
    ld 8 t3 t4
    bne rel:B9 t4 a0
    ld 24 t3 t4
    bnez B9 t4
    la cur_pc t4
    ld 0 t4 t4
    sd 24 t4 t3
    B9:
    ret
", 2);

$code .= cfn('dbgdata0', "with -g, outside the JIT: a round of datasep's globals starts at cur_pc, a new entry of dbg_regs (start, end)", "
    la dbg_on t0
    ld 0 t0 t0
    beqz B9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez B9 t0
    la dbg_regs t0
    ld 0 t0 t1
    li 255 t2
    bgeu rel:B9 t2 t1
    slli 4 t1 t3
    add t3 t0 t3
    la cur_pc t4
    ld 0 t4 t4
    sd 8 t4 t3
    sd 16 t4 t3
    addi 1 t1 t1
    sd 0 t1 t0
    B9:
    ret
", 2);

$code .= cfn('dbgdata1', "the round of globals dbgdata0 started ends at cur_pc", "
    la dbg_on t0
    ld 0 t0 t0
    beqz B9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez B9 t0
    la dbg_regs t0
    ld 0 t0 t1
    beqz B9 t1
    slli 4 t1 t3
    add t3 t0 t3
    la cur_pc t4
    ld 0 t4 t4
    sd 0 t4 t3
    B9:
    ret
", 2);

$code .= cfn('dbgwrite', "with -g, an ELF file in outbuf gets its debug information past its bytes (gen/patches/debug.pl): out_end moves", "
    enter1
    la dbg_on t0
    ld 0 t0 t0
    beqz W9 t0
    la outbuf t0
    lbu 0 t0 t1
    li 127 t2
    bne rel:W9 t2 t1
    lbu 1 t0 t1
    li 69 t2
    bne rel:W9 t2 t1
    lbu 2 t0 t1
    li 76 t2
    bne rel:W9 t2 t1
    lbu 3 t0 t1
    li 70 t2
    bne rel:W9 t2 t1
    call dhead
    beqz W9 a0
    call dspecs
    call dsects
    call dsyms
    call dtail
    W9:
    leave1
", 2);

$code .= cfn('dhead', "dbg_st from the ELF header and program headers in outbuf: 0 class 64 (1/0), 8 the size of an address, 16 the base (PT_LOAD's vaddr - offset), 24 its filesz, 32 its memsz, 40 the code's start (past the header and one program header), 48 its end (the program headers, else the file's), 56 64 72 PT_TLS's vaddr filesz memsz, 96 e_machine, 104 e_phoff, 112 e_phnum, 120 e_phentsize, 128 e_ehsize, 216 the target (0 riscv64, 1 x86_64, 2 aarch64, 3 arm, -1 another), 224 the file's size; 1 if it has a PT_LOAD, else 0", "
    enter5
    la dbg_st s4
    la outbuf s5
    li 64 t0
    mv s4 t1
    Z1:
    sd 0 zero t1
    addi 8 t1 t1
    addi -1 t0 t0
    bnez Z1 t0
    lbu 4 s5 t0
    li 2 t1
    li 4 t2
    bne rel:H1 t1 t0
    li 1 t3
    sd 0 t3 s4
    li 8 t2
    H1:
    sd 8 t2 s4
    addi 18 s5 a0
    li 2 a1
    call drd
    sd 96 a0 s4
    li 0 a0
    call dhf
    sd 104 a0 s4
    li 2 a0
    call dhf
    sd 128 a0 s4
    li 3 a0
    call dhf
    sd 120 a0 s4
    li 4 a0
    call dhf
    sd 112 a0 s4
    la out_end t0
    ld 0 t0 t0
    sub s5 t0 t0
    sd 224 t0 s4
    li 0 s6
    H2:
    ld 112 s4 t0
    bgeu rel:H5 t0 s6
    ld 120 s4 t0
    mul t0 s6 t0
    ld 104 s4 t1
    add t1 t0 t0
    add s5 t0 s7
    addi 1 s6 s6
    mv s7 a0
    li 0 a1
    call dpf
    li 1 t0
    beq rel:H3 t0 a0
    li 7 t0
    beq rel:H4 t0 a0
    j H2
    H3:
    ld 32 s4 t0
    bnez H2 t0
    mv s7 a0
    li 2 a1
    call dpf
    mv a0 s8
    mv s7 a0
    li 1 a1
    call dpf
    sub a0 s8 s8
    sd 16 s8 s4
    mv s7 a0
    li 4 a1
    call dpf
    sd 24 a0 s4
    mv s7 a0
    li 5 a1
    call dpf
    sd 32 a0 s4
    j H2
    H4:
    mv s7 a0
    li 2 a1
    call dpf
    sd 56 a0 s4
    mv s7 a0
    li 4 a1
    call dpf
    sd 64 a0 s4
    mv s7 a0
    li 5 a1
    call dpf
    sd 72 a0 s4
    j H2
    H5:
    li 0 a0
    ld 32 s4 t0
    beqz H9 t0
    ld 16 s4 t0
    ld 128 s4 t1
    add t1 t0 t0
    ld 120 s4 t1
    add t1 t0 t0
    sd 40 t0 s4
    ld 16 s4 t0
    ld 104 s4 t1
    ld 128 s4 t2
    add t1 t0 t3
    bltu rel:H7 t1 t2
    ld 24 s4 t1
    add t1 t0 t3
    H7:
    sd 48 t3 s4
    ld 96 s4 t0
    li -1 t1
    li 243 t2
    bne rel:T1 t2 t0
    li 0 t1
    T1:
    li 62 t2
    bne rel:T2 t2 t0
    li 1 t1
    T2:
    li 183 t2
    bne rel:T3 t2 t0
    li 2 t1
    T3:
    li 40 t2
    bne rel:T4 t2 t0
    li 3 t1
    T4:
    sd 216 t1 s4
    li 1 a0
    H9:
    leave5
", 2);

$code .= cfn('drd', "the a1 bytes at a0, little endian: a0 (t0..t2)", "
    add a1 a0 t1
    li 0 t0
    R1:
    beq rel:R2 a0 t1
    addi -1 t1 t1
    lbu 0 t1 t2
    slli 8 t0 t0
    or t2 t0 t0
    j R1
    R2:
    mv t0 a0
    ret
", 2);

$code .= cfn('dwrn', "a2 as a1 bytes at a0, little endian; a0 past them (a regs only)", "
    D1:
    beqz D2 a1
    sb 0 a2 a0
    srli 8 a2 a2
    addi 1 a0 a0
    addi -1 a1 a1
    j D1
    D2:
    ret
", 2);

$code .= cfn('droom', "out_full unless a1 bytes from a0 fit in outbuf", "
    la outbuf t1
    lui OUT_SIZE t2
    add t2 t1 t1
    add a1 a0 t3
    bgeu rel:R1 t3 t1
    j out_full
    R1:
    ret
", 2);

$code .= cfn('dputn', "a0 as a1 bytes at dbg_st's cursor (80), which moves past them", "
    enter2
    mv a0 s5
    la dbg_st s4
    ld 80 s4 a0
    call droom
    mv s5 a2
    call dwrn
    sd 80 a0 s4
    leave2
", 2);
$code .= fn('dput1', "li 1 a1\nj dputn", 2);
$code .= fn('dput2', "li 2 a1\nj dputn", 2);
$code .= fn('dput4', "li 4 a1\nj dputn", 2);
$code .= fn('dput8', "li 8 a1\nj dputn", 2);
$code .= fn('dputa', "la dbg_st t0\nld 8 t0 a1\nj dputn", 2);

$code .= cfn('dcopy', "the a1 bytes at a0 to the cursor", "
    enter2
    mv a0 s4
    mv a1 s5
    la dbg_st t0
    ld 80 t0 a0
    call droom
    la dbg_st t0
    ld 80 t0 t1
    C1:
    beqz C2 s5
    lbu 0 s4 t2
    sb 0 t2 t1
    addi 1 s4 s4
    addi 1 t1 t1
    addi -1 s5 s5
    j C1
    C2:
    sd 80 t1 t0
    leave2
", 2);

$code .= cfn('dpad', "zeros at the cursor up to a multiple of a0 (a power of 2) in the file", "
    enter1
    mv a0 s4
    la dbg_st t0
    ld 80 t0 a0
    mv s4 a1
    call droom
    la dbg_st t0
    ld 80 t0 t1
    la outbuf t2
    addi -1 s4 a0
    P1:
    sub t2 t1 t3
    and a0 t3 t3
    beqz P2 t3
    sb 0 zero t1
    addi 1 t1 t1
    j P1
    P2:
    sd 80 t1 t0
    leave1
", 2);

$code .= cfn('dptr', "the address a0 of the program, where it is in outbuf (t0)", "
    la dbg_st t0
    ld 16 t0 t0
    sub t0 a0 a0
    la outbuf t0
    add t0 a0 a0
    ret
", 2);

$code .= cfn('dhfo', "where field a0 of the ELF header is (a0) and its size (a1): 0 e_phoff, 1 e_shoff, 2 e_ehsize, 3 e_phentsize, 4 e_phnum, 5 e_shentsize, 6 e_shnum, 7 e_shstrndx", "
    la dbg_st t0
    ld 8 t0 a1
    ld 0 t0 t1
    la dbg_h64 t2
    bnez O1 t1
    la dbg_h32 t2
    O1:
    li 2 t3
    bltu rel:O2 t3 a0
    li 2 a1
    O2:
    add a0 t2 t2
    lbu 0 t2 a0
    ret
", 2);

$code .= cfn('dhf', "field a0 of the ELF header (dhfo)", "
    enter1
    call dhfo
    la outbuf t0
    add t0 a0 a0
    call drd
    leave1
", 2);

$code .= cfn('dhfw', "field a0 of the ELF header (dhfo) becomes a1", "
    enter1
    mv a1 s4
    call dhfo
    la outbuf t0
    add t0 a0 a0
    mv s4 a2
    call dwrn
    leave1
", 2);

$code .= cfn('dpf', "field a1 of the program header at a0: 0 p_type, 1 p_offset, 2 p_vaddr, 3 p_paddr, 4 p_filesz, 5 p_memsz, 6 p_flags, 7 p_align", "
    enter1
    la dbg_st t0
    ld 0 t0 t1
    ld 8 t0 t4
    la dbg_p64 t2
    bnez Q1 t1
    la dbg_p32 t2
    Q1:
    add a1 t2 t2
    lbu 0 t2 t2
    add t2 a0 a0
    beqz Q2 a1
    li 6 t3
    beq rel:Q2 t3 a1
    mv t4 a1
    j Q3
    Q2:
    li 4 a1
    Q3:
    call drd
    leave1
", 2);

$code .= cfn('dspec', "a part of the program that is a section of its own: from a0 to a1, its name a2 (in .shstrtab), type a3 (0: none, a hole), flags a4; one of none is left out", "
    bgeu rel:S9 a1 a0
    la dbg_spec t0
    ld 0 t0 t1
    li 300 t2
    bgeu rel:S9 t2 t1
    li 40 t3
    mul t3 t1 t3
    add t3 t0 t3
    sd 8 a0 t3
    sd 16 a1 t3
    sd 24 a2 t3
    sd 32 a3 t3
    sd 40 a4 t3
    addi 1 t1 t1
    sd 0 t1 t0
    S9:
    ret
", 2);

$code .= cfn('dshsadd', "the name a0 a1 (its bytes, its length) at the end of .shstrtab (dbg_shs, its length at dbg_st 160): a0 where it is", "
    la dbg_st t0
    ld 160 t0 t1
    li32 7900 t2
    add a1 t1 t3
    bltu rel:N1 t2 t3
    li 0 a1
    N1:
    la dbg_shs t2
    add t1 t2 t2
    mv t1 t3
    N2:
    beqz N3 a1
    lbu 0 a0 t4
    sb 0 t4 t2
    addi 1 a0 a0
    addi 1 t2 t2
    addi 1 t1 t1
    addi -1 a1 a1
    j N2
    N3:
    sb 0 zero t2
    addi 1 t1 t1
    sd 160 t1 t0
    mv t3 a0
    ret
", 2);

$code .= cfn('dspecs', "the program's parts that are sections of their own (dspec), by address: the rounds of writable globals, the named sections, the TLS image", "
    enter8
    la dbg_st s4
    la dbg_spec t0
    sd 0 zero t0
    la dbg_shs a1
    la dbg_names a0
    li $nlen a2
    sd 160 a2 s4
    K1:
    lbu 0 a0 t0
    sb 0 t0 a1
    addi 1 a0 a0
    addi 1 a1 a1
    addi -1 a2 a2
    bnez K1 a2
    la dbg_regs s5
    ld 0 s5 s6
    addi 8 s5 s5
    K2:
    beqz K3 s6
    ld 0 s5 a0
    ld 8 s5 a1
    li $N{'.data'} a2
    li 1 a3
    li 3 a4
    call dspec
    addi 16 s5 s5
    addi -1 s6 s6
    j K2
    K3:
    la sec_vars s5
    ld 0 s5 s6
    li 0 s7
    V1:
    bgeu rel:V2 s6 s7
    slli 9 s7 t0
    add t0 s5 t0
    addi 8 t0 s8
    addi 1 s7 s7
    ld 24 s8 t0
    beqz V1 t0
    addi 32 s8 a0
    call label_addr
    mv a0 s9
    addi 96 s8 a0
    call label_addr
    mv a0 s10
    beqz V1 s9
    bgeu rel:V1 s10 s9
    ld 0 s8 a0
    ld 8 s8 a1
    call dshsadd
    mv a0 a2
    mv s9 a0
    mv s10 a1
    li 1 a3
    li 3 a4
    call dspec
    j V1
    V2:
    ld 56 s4 a0
    ld 64 s4 a1
    add a0 a1 a1
    li $N{'.tdata'} a2
    li 1 a3
    li 1027 a4
    call dspec
    call dsort
    leave8
", 2);

$code .= cfn('dsort', "dbg_spec's parts by their start (an insertion sort: they come nearly in order)", "
    la dbg_spec t0
    ld 0 t0 t1
    addi 8 t0 t0
    li 1 t2
    I1:
    bgeu rel:I9 t1 t2
    li 40 t3
    mul t3 t2 t3
    add t0 t3 t3
    mv t2 t4
    I2:
    beqz I3 t4
    addi -40 t3 t5
    ld 0 t3 a0
    ld 0 t5 a1
    bgeu rel:I3 a1 a0
    li 5 a2
    I4:
    ld 0 t3 a3
    ld 0 t5 a4
    sd 0 a4 t3
    sd 0 a3 t5
    addi 8 t3 t3
    addi 8 t5 t5
    addi -1 a2 a2
    bnez I4 a2
    addi -80 t3 t3
    addi -1 t4 t4
    j I2
    I3:
    addi 1 t2 t2
    j I1
    I9:
    ret
", 2);

$code .= cfn('dsec', "a new section header in dbg_secs (80 bytes: name, type, flags, addr, offset, size, link, info, addralign, entsize): name a0, type a1, flags a2, addr a3 (its offset in the file addr - the base), size a4, addralign a5; a0 its index, a1 where it is (past 1000 headers, a spare one, not counted)", "
    la dbg_st t0
    ld 88 t0 t1
    li 80 t2
    mul t2 t1 t2
    la dbg_secs t3
    add t3 t2 t2
    sd 0 a0 t2
    sd 8 a1 t2
    sd 16 a2 t2
    sd 24 a3 t2
    ld 16 t0 t4
    sub t4 a3 t4
    sd 32 t4 t2
    sd 40 a4 t2
    sd 48 zero t2
    sd 56 zero t2
    sd 64 a5 t2
    sd 72 zero t2
    mv t1 a0
    mv t2 a1
    li 1000 t3
    bgeu rel:Q9 t3 t1
    addi 1 t1 t1
    sd 88 t1 t0
    Q9:
    ret
", 2);

$code .= cfn('dsects', "the section headers of the program's memory: the null one, .text between dbg_spec's parts and up to the code's end, the parts, .tbss, .bss", "
    enter8
    la dbg_st s4
    sd 88 zero s4
    li 0 a0
    li 0 a1
    li 0 a2
    li 0 a3
    li 0 a4
    li 0 a5
    call dsec
    sd 32 zero a1
    ld 40 s4 s5
    la dbg_spec s6
    ld 0 s6 s7
    addi 8 s6 s6
    M1:
    beqz M5 s7
    ld 0 s6 s8
    bgeu rel:M2 s5 s8
    mv s5 s8
    M2:
    bgeu rel:M3 s8 s5
    li $N{'.text'} a0
    li 1 a1
    li 6 a2
    mv s5 a3
    sub s5 s8 a4
    li 1 a5
    call dsec
    M3:
    ld 8 s6 s9
    bgeu rel:M4 s9 s8
    ld 24 s6 a1
    beqz M4 a1
    ld 16 s6 a0
    ld 32 s6 a2
    mv s8 a3
    sub s8 s9 a4
    li 1 a5
    call dsec
    M4:
    bgeu rel:M45 s9 s5
    mv s9 s5
    M45:
    addi 40 s6 s6
    addi -1 s7 s7
    j M1
    M5:
    ld 48 s4 s8
    bgeu rel:M6 s8 s5
    li $N{'.text'} a0
    li 1 a1
    li 6 a2
    mv s5 a3
    sub s5 s8 a4
    li 1 a5
    call dsec
    M6:
    ld 72 s4 t0
    ld 64 s4 t1
    bgeu rel:M7 t0 t1
    li $N{'.tbss'} a0
    li 8 a1
    li 1027 a2
    ld 56 s4 a3
    add t1 a3 a3
    sub t1 t0 a4
    li 1 a5
    call dsec
    M7:
    ld 32 s4 t0
    ld 24 s4 t1
    bgeu rel:M8 t0 t1
    li $N{'.bss'} a0
    li 8 a1
    li 3 a2
    ld 16 s4 a3
    add t1 a3 a3
    sub t1 t0 a4
    li 1 a5
    call dsec
    M8:
    leave8
", 2);

$code .= cfn('dshndx', "the section a0 is in (a0, its flags a1): the allocated one it is in, else the first it ends, else SHN_ABS", "
    la dbg_st t0
    ld 88 t0 t1
    la dbg_secs t2
    li 0 t3
    li32 65521 a2
    li 0 a3
    X1:
    addi 1 t3 t3
    addi 80 t2 t2
    bgeu rel:X5 t1 t3
    ld 16 t2 t4
    andi 2 t4 t5
    beqz X1 t5
    ld 8 t2 t5
    li 8 t6
    bne rel:X2 t6 t5
    andi 1024 t4 t5
    bnez X1 t5
    X2:
    ld 24 t2 t5
    bltu rel:X1 t5 a0
    ld 40 t2 t6
    add t6 t5 t5
    bltu rel:X4 t5 a0
    bne rel:X1 t5 a0
    li32 65521 t6
    bne rel:X1 t6 a2
    mv t3 a2
    mv t4 a3
    j X1
    X4:
    mv t3 a0
    mv t4 a1
    ret
    X5:
    mv a2 a0
    mv a3 a1
    ret
", 2);

$code .= cfn('dfirst', "what the first child of the label a0 says: 1 asm (an asm function or entry), 2 data (dword, word, half, byte, ascii, reserve, align), else 0", "
    enter3
    mv a0 s4
    li 0 s5
    lbu NODE_children_len s4 t0
    beqz F9 t0
    ld NODE_children s4 t0
    ld 0 t0 s4
    mv s4 a0
    la str_asm a1
    li 3 a2
    call is_named
    li 1 s5
    bnez F9 a0
    li 0 s5
    la dbg_dirs s6
    F1:
    lbu 0 s6 a2
    beqz F9 a2
    mv s4 a0
    addi 1 s6 a1
    call is_named
    bnez F2 a0
    lbu 0 s6 t0
    add t0 s6 s6
    addi 1 s6 s6
    j F1
    F2:
    li 2 s5
    F9:
    mv s5 a0
    leave3
", 2);

$code .= cfn('dspace', "1 if the name of the node a0 has a space (c2ff's name of a static: name unit), else 0", "
    ld NODE_content a0 t0
    lbu NODE_content_len a0 t1
    li 32 t3
    S1:
    li 0 a0
    beqz S2 t1
    lbu 0 t0 t2
    li 1 a0
    beq rel:S2 t3 t2
    addi 1 t0 t0
    addi -1 t1 t1
    j S1
    S2:
    ret
", 2);

$code .= cfn('dsymkind', "the symbol of the label entry a0, a1 1 if it is a C function of dbg_fns: a0 its st_info (bind, type), a1 its section", "
    enter5
    mv a0 s4
    mv a1 s5
    ld LABEL_node s4 s6
    ld LABEL_addr s4 a0
    call dshndx
    mv a0 s7
    mv a1 s8
    ld LABEL_end s4 t0
    ld LABEL_addr s4 t1
    bne rel:K1 t0 t1
    li 0 s5
    j K8
    K1:
    bnez K7 s5
    mv s6 a0
    call dfirst
    li 2 s5
    li 1 t0
    beq rel:K8 t0 a0
    li 1 s5
    andi 4 s8 t1
    beqz K8 t1
    la dbg_fns t1
    ld 0 t1 t1
    bnez K8 t1
    li 2 t0
    beq rel:K8 t0 a0
    li 2 s5
    j K8
    K7:
    li 2 s5
    K8:
    mv s6 a0
    call dspace
    li 1 t0
    sub a0 t0 t0
    slli 4 t0 t0
    or s5 t0 a0
    mv s7 a1
    leave5
", 2);

$code .= cfn('dsyms', "the labels that are symbols, into dbg_syms (16 bytes each: the label entry, st_info | section << 8), their count at dbg_st 144: in the order placed, a name that is no layer, no group, not nested in another label's bytes (one of none ends where it starts), or an asm entry", "
    enter8
    la dbg_st s4
    la labels_base t0
    ld 0 t0 s5
    la labels_end t0
    ld 0 t0 s6
    li 0 s7
    li 0 s8
    la dbg_fns s9
    ld 0 s9 t1
    addi 8 s9 s9
    li 24 t2
    mul t2 t1 t1
    add t1 s9 s10
    Y1:
    bgeu rel:Y8 s6 s5
    ld LABEL_node s5 s11
    ld LABEL_addr s5 t0
    ld 40 s4 t1
    bltu rel:Y7 t1 t0
    ld 16 s4 t1
    ld 32 s4 t2
    add t2 t1 t1
    bltu rel:Y7 t0 t1
    lbu NODE_content_len s11 t0
    li 2 t1
    bltu rel:Y7 t1 t0
    mv s11 a0
    call is_layer
    bnez Y7 a0
    mv s11 a0
    call is_group
    bnez Y7 a0
    Y2:
    beqz Y3 s7
    addi -1 s7 t0
    slli 3 t0 t0
    la dbg_stk t1
    add t1 t0 t0
    ld 0 t0 t0
    ld LABEL_addr s5 t1
    bltu rel:Y3 t0 t1
    addi -1 s7 s7
    j Y2
    Y3:
    beqz Y4 s7
    lbu NODE_children_len s11 t0
    beqz Y6 t0
    ld NODE_children s11 t0
    ld 0 t0 a0
    la str_asm a1
    li 3 a2
    call is_named
    beqz Y6 a0
    Y4:
    ld LABEL_addr s5 t0
    Y41:
    bgeu rel:Y42 s10 s9
    ld 8 s9 t1
    bgeu rel:Y42 t0 t1
    addi 24 s9 s9
    j Y41
    Y42:
    li 0 a1
    bgeu rel:Y43 s10 s9
    ld 8 s9 t1
    ld LABEL_end s5 t2
    bgeu rel:Y43 t2 t1
    li 1 a1
    Y43:
    li32 262143 t0
    bgeu rel:Y6 t0 s8
    mv s5 a0
    call dsymkind
    slli 8 a1 a1
    or a1 a0 a0
    slli 4 s8 t0
    la dbg_syms t1
    add t1 t0 t0
    sd 8 s5 t0
    sd 16 a0 t0
    addi 1 s8 s8
    Y6:
    li 64 t0
    bgeu rel:Y7 t0 s7
    slli 3 s7 t0
    la dbg_stk t1
    add t1 t0 t0
    ld LABEL_end s5 t1
    sd 0 t1 t0
    addi 1 s7 s7
    Y7:
    addi LABEL_size s5 s5
    j Y1
    Y8:
    sd 144 s8 s4
    leave8
", 2);

$code .= cfn('dstrb', "the a1 bytes at a0 at the end of .strtab (dbg_st 152)", "
    enter2
    mv a0 s4
    mv a1 s5
    la dbg_st t0
    ld 152 t0 a0
    addi 1 s5 a1
    call droom
    la dbg_st t0
    ld 152 t0 t1
    B1:
    beqz B2 s5
    lbu 0 s4 t2
    sb 0 t2 t1
    addi 1 s4 s4
    addi 1 t1 t1
    addi -1 s5 s5
    j B1
    B2:
    sd 152 t1 t0
    leave2
", 2);

$code .= cfn('dstr', "the name of the label a0 (without its colon; a named section's bound, a node of sec_vars, __start_ or __stop_ and the section's name) and a NUL at the end of .strtab (from dbg_st 240): a0 where it starts in it", "
    enter3
    mv a0 s4
    la dbg_st s5
    ld 152 s5 s6
    la sec_vars t0
    sub t0 s4 t1
    li32 8200 t2
    bgeu rel:S5 t2 t1
    addi -8 t1 t1
    andi 511 t1 t2
    sub t2 t1 t1
    add t1 t0 t1
    addi 8 t1 s4
    la dbg_pstart a0
    li 8 a1
    li 32 t3
    beq rel:S4 t3 t2
    la dbg_pstop a0
    li 7 a1
    S4:
    call dstrb
    ld 0 s4 a0
    ld 8 s4 a1
    call dstrb
    j S6
    S5:
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    addi -1 a1 a1
    call dstrb
    S6:
    ld 152 s5 t1
    sb 0 zero t1
    addi 1 t1 t1
    sd 152 t1 s5
    la outbuf t2
    ld 240 s5 t3
    add t3 t2 t2
    sub t2 s6 a0
    leave3
", 2);

$code .= cfn('dsym', "a symbol at the cursor, as the class has it: name a0, value a1, size a2, info a3, section a4", "
    enter5
    mv a1 s4
    mv a2 s5
    mv a3 s6
    mv a4 s7
    la dbg_st s8
    call dput4
    ld 0 s8 t0
    beqz Z1 t0
    mv s6 a0
    call dput1
    li 0 a0
    call dput1
    mv s7 a0
    call dput2
    mv s4 a0
    call dput8
    mv s5 a0
    call dput8
    leave5
    Z1:
    mv s4 a0
    call dput4
    mv s5 a0
    call dput4
    mv s6 a0
    call dput1
    li 0 a0
    call dput1
    mv s7 a0
    call dput2
    leave5
", 2);

$code .= cfn('dtail', "past the file's bytes, 8-aligned: .symtab (the local symbols first), .strtab, .shstrtab, the section headers; the ELF header names them; out_end past them", "
    enter8
    la dbg_st s4
    la outbuf t0
    ld 224 s4 t1
    add t1 t0 t0
    sd 80 t0 s4
    li 8 a0
    call dpad
    ld 80 s4 t0
    la outbuf t1
    sub t1 t0 t0
    sd 232 t0 s4
    li 16 s5
    ld 0 s4 t0
    beqz T1 t0
    li 24 s5
    T1:
    ld 144 s4 t0
    addi 1 t0 t0
    mul s5 t0 t0
    ld 232 s4 t1
    add t1 t0 t0
    sd 240 t0 s4
    la outbuf t1
    add t1 t0 a0
    li 1 a1
    call droom
    sb 0 zero a0
    addi 1 a0 a0
    sd 152 a0 s4
    sd 136 zero s4
    li 0 a0
    li 0 a1
    li 0 a2
    li 0 a3
    li 0 a4
    call dsym
    li 0 s6
    T2:
    li 0 s7
    T3:
    ld 144 s4 t0
    bgeu rel:T5 t0 s7
    slli 4 s7 t0
    la dbg_syms s8
    add t0 s8 s8
    addi 8 s8 s8
    addi 1 s7 s7
    ld 8 s8 t0
    srli 4 t0 t1
    andi 15 t1 t1
    bne rel:T3 t1 s6
    bnez T4 s6
    ld 136 s4 t1
    addi 1 t1 t1
    sd 136 t1 s4
    T4:
    ld 0 s8 s9
    ld LABEL_node s9 a0
    call dstr
    ld LABEL_addr s9 a1
    ld LABEL_end s9 a2
    sub a1 a2 a2
    ld 8 s8 t0
    andi 255 t0 a3
    srli 8 t0 a4
    call dsym
    j T3
    T5:
    bnez T6 s6
    li 1 s6
    j T2
    T6:
    li $N{'.symtab'} a0
    li 2 a1
    li 0 a2
    li 0 a3
    ld 144 s4 a4
    addi 1 a4 a4
    mul s5 a4 a4
    ld 8 s4 a5
    call dsec
    ld 232 s4 t0
    sd 32 t0 a1
    addi 1 a0 t0
    sd 48 t0 a1
    ld 136 s4 t0
    addi 1 t0 t0
    sd 56 t0 a1
    sd 72 s5 a1
    ld 152 s4 t0
    la outbuf t1
    sub t1 t0 t0
    ld 240 s4 t1
    sub t1 t0 a4
    li $N{'.strtab'} a0
    li 3 a1
    li 0 a2
    li 0 a3
    li 1 a5
    call dsec
    ld 240 s4 t0
    sd 32 t0 a1
    ld 152 s4 t0
    sd 80 t0 s4
    li $N{'.shstrtab'} a0
    li 3 a1
    li 0 a2
    li 0 a3
    ld 160 s4 a4
    li 1 a5
    call dsec
    ld 80 s4 t0
    la outbuf t1
    sub t1 t0 t0
    sd 32 t0 a1
    la dbg_shs a0
    ld 160 s4 a1
    call dcopy
    li 8 a0
    call dpad
    ld 80 s4 t0
    la outbuf t1
    sub t1 t0 a1
    li 1 a0
    call dhfw
    li 40 a1
    ld 0 s4 t0
    beqz T7 t0
    li 64 a1
    T7:
    li 5 a0
    call dhfw
    li 6 a0
    ld 88 s4 a1
    call dhfw
    li 7 a0
    ld 88 s4 a1
    addi -1 a1 a1
    call dhfw
    li 0 s5
    U1:
    ld 88 s4 t0
    bgeu rel:U2 t0 s5
    li 80 t0
    mul t0 s5 t0
    la dbg_secs s6
    add t0 s6 s6
    addi 1 s5 s5
    ld 0 s6 a0
    call dput4
    ld 8 s6 a0
    call dput4
    ld 16 s6 a0
    call dputa
    ld 24 s6 a0
    call dputa
    ld 32 s6 a0
    call dputa
    ld 40 s6 a0
    call dputa
    ld 48 s6 a0
    call dput4
    ld 56 s6 a0
    call dput4
    ld 64 s6 a0
    call dputa
    ld 72 s6 a0
    call dputa
    j U1
    U2:
    ld 80 s4 t0
    la out_end t1
    sd 0 t0 t1
    leave8
", 2);

# ---- the constant data
$code .= bytes('dbg_h64', 'ELF64: where e_phoff, e_shoff, e_ehsize, e_phentsize, e_phnum, e_shentsize, e_shnum, e_shstrndx are', 0x20, 0x28, 0x34, 0x36, 0x38, 0x3a, 0x3c, 0x3e);
$code .= bytes('dbg_h32', 'ELF32: the same', 0x1c, 0x20, 0x28, 0x2a, 0x2c, 0x2e, 0x30, 0x32);
$code .= bytes('dbg_p64', 'ELF64: where p_type, p_offset, p_vaddr, p_paddr, p_filesz, p_memsz, p_flags, p_align are in a program header', 0, 8, 16, 24, 32, 40, 4, 48);
$code .= bytes('dbg_p32', 'ELF32: the same', 0, 4, 8, 12, 16, 20, 24, 28);
$code .= bytes('dbg_names', 'the names of the sections, as .shstrtab starts', map { ord } split //, $names);
$code .= "  dbg_pstart:\n    ascii\n      __start_\n  dbg_pstop:\n    ascii\n      __stop_\n";
$code .= bytes('dbg_dirs', 'the words of data that start a label of an asm program, each after its length; 0 ends them', (map { (length $_, map { ord } split //) } qw(dword word half byte ascii reserve align)), 0);

once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');
save();
