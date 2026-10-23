# ehframe.pl: -g, second step (D2): the frames of the C layer's functions
# for an unwinder, in the program's memory. With -g, at the end of the
# library of a program the frame lays out (cc_library, after the IRELATIVE
# table), dbgarea leaves room in each pass for the functions dbg_fns has
# then (the same count in both): 8 program headers, .eh_frame_hdr
# (8n + 16), .eh_frame (48n + 32) and on arm .ARM.exidx (16n). dbgwrite
# fills it (dbgeh) before debug.pl's sections:
#
#   .eh_frame: a CIE per target ("zR", FDE pointers pcrel sdata4; the CFA
#   at the stack pointer, the return address in its register, x86_64's at
#   CFA - 8), and an FDE of 48 bytes per function whose frame is the C
#   layer's (its first and last word are cc_enter's and cc_leave's, arm's
#   variadic cc_enter_va and cc_leave_va): from cc_enter's instructions on
#   the CFA is the frame pointer + 16 (arm: + 8, + 24 variadic), the return
#   address and the old frame pointer below it, as cc_enter saved them;
#   from cc_leave's restoring of sp on the CFA is sp-based again, the
#   registers restored. _start's has its return address undefined, where a
#   walk ends (on arm its .ARM.exidx entry is EXIDX_CANTUNWIND). Its
#   terminator follows. A frame that is not the C layer's (an asm
#   function, a _start that does more first) has none: a walk stops there.
#   .eh_frame_hdr: the sorted table (initial location, FDE), datarel, for
#   a binary search (libgcc's unwinder, gdb).
#   .ARM.exidx on arm (EHABI, what libgcc's unwinder reads there; gdb reads
#   .eh_frame): per function the compact model (personality 0): vsp = r11,
#   pop {r11, r14}; EXIDX_CANTUNWIND where the next function does not start
#   at its end. A variadic one's vsp misses the 16 bytes of r0..r3, which
#   its caller's frame, read from r11, does not need.
#
# The program headers move there: the program's own, then PT_GNU_EH_FRAME
# (.eh_frame_hdr), on arm PT_ARM_EXIDX; e_phoff and e_phnum say so (the
# room is inside PT_LOAD, so AT_PHDR is right). debug.pl's sections name
# the three parts. Run on ttpc.ff after debug.pl.
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

sub bytes {
    my ($name, $text, @b) = @_;
    push @b, 0 while @b % 8;
    my $s = '';
    while (@b) { my @d = splice @b, 0, 8; $s .= "    dword\n      " . sprintf("0x%016x", unpack 'Q<', pack 'C8', @d) . "\n" }
    "  align\n    8\n  $name:\n    comment\n      $text\n$s";
}

my $names = "\0";
my %N;
for (qw(.text .data .bss .tdata .tbss .symtab .strtab .shstrtab .eh_frame_hdr .eh_frame .ARM.exidx)) { $N{$_} = length $names; $names .= "$_\0" }

# ---- the room, at the end of cc_library
edit(\$t, 'cc/cc_library',
    "          call\n            irelplace\n          leave3\n",
    "          call\n            irelplace\n" . asm(10, "call dbgarea") . "          leave3\n");
my ($pf, $pt) = find(\$t, 'cc/tlsplace');
substr($t, $pt, 0) = cfn('dbgarea', "with -g, at the end of the library of a program the frame lays out (not the JIT's), once a pass: 8-aligned, room for dbgeh (gen/patches/ehframe.pl): 8 program headers, .eh_frame_hdr, .eh_frame, on arm .ARM.exidx, for the n functions dbg_fns has; dbg_area: 0 where, 8 its size, 16 placed, 24 n", "
    enter2
    la dbg_on t0
    ld 0 t0 t0
    beqz A9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez A9 t0
    la dbg_area t0
    ld 16 t0 t1
    bnez A9 t1
    call libbase
    ld 8 a0 t0
    beqz A9 t0
    la cur_pc t0
    ld 0 t0 t0
    neg t0 a0
    andi 7 a0 a0
    call pad
    la dbg_fns t0
    ld 0 t0 s4
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    li 448 s5
    bne rel:A1 t1 t0
    li 256 s5
    slli 4 s4 t2
    add t2 s5 s5
    A1:
    slli 3 s4 t2
    add t2 s5 s5
    addi 16 s5 s5
    li 48 t2
    mul t2 s4 t2
    add t2 s5 s5
    addi 32 s5 s5
    la dbg_area t0
    la cur_pc t1
    ld 0 t1 t1
    sd 0 t1 t0
    sd 8 s5 t0
    li 1 t2
    sd 16 t2 t0
    sd 24 s4 t0
    mv s5 a0
    call pad
    A9:
    leave2
", 6);

# ---- dbgwrite: the frames first, then the sections (which name them)
edit(\$t, 'dbgwrite', "    call\n      dspecs\n", asm(4, "call dbgeh") . "    call\n      dspecs\n");

# ---- dspecs: the room's parts
edit(\$t, 'dspecs', "      call\n        dsort\n", asm(6, "
    la dbg_area s5
    ld 16 s5 t0
    beqz K9 t0
    ld 176 s4 t0
    beqz K9 t0
    ld 0 s5 a0
    ld 168 s4 a1
    li 0 a2
    li 0 a3
    li 0 a4
    call dspec
    ld 168 s4 a0
    ld 176 s4 a1
    add a0 a1 a1
    li $N{'.eh_frame_hdr'} a2
    li 1 a3
    li 2 a4
    call dspec
    ld 168 s4 a0
    ld 176 s4 t0
    add t0 a0 a0
    ld 184 s4 a1
    li 0 a2
    li 0 a3
    li 0 a4
    call dspec
    ld 184 s4 a0
    ld 192 s4 a1
    add a0 a1 a1
    li $N{'.eh_frame'} a2
    li 1 a3
    li 2 a4
    call dspec
    ld 200 s4 a0
    ld 208 s4 a1
    add a0 a1 a1
    li $N{'.ARM.exidx'} a2
    li32 1879048193 a3
    li 2 a4
    call dspec
    ld 184 s4 a0
    ld 192 s4 t0
    add t0 a0 a0
    ld 200 s4 a1
    li 0 a2
    li 0 a3
    li 0 a4
    call dspec
    ld 200 s4 a0
    ld 208 s4 t0
    add t0 a0 a0
    ld 0 s5 a1
    ld 8 s5 t0
    add t0 a1 a1
    li 0 a2
    li 0 a3
    li 0 a4
    call dspec
    K9:
") . "      call\n        dsort\n");

my $code = '';

$code .= cfn('dbgeh', "the room dbgarea left (dbg_area), if any: the program headers again with PT_GNU_EH_FRAME (and PT_ARM_EXIDX), .eh_frame_hdr, .eh_frame (and .ARM.exidx) for the functions of dbg_fns whose frame is the C layer's; dbg_st 168 176 .eh_frame_hdr's address and size, 184 192 .eh_frame's, 200 208 .ARM.exidx's", "
    enter8
    la dbg_st s4
    la dbg_area t0
    ld 16 t0 t1
    beqz E9 t1
    ld 216 s4 t1
    bltz E9 t1
    ld 112 s4 t1
    li 6 t2
    bltu rel:E9 t1 t2
    ld 24 t0 s6
    la dbg_fns t1
    ld 0 t1 t1
    bgeu rel:E1 s6 t1
    mv t1 s6
    E1:
    ld 0 t0 t2
    ld 120 s4 t3
    slli 3 t3 t3
    add t3 t2 t2
    sd 168 t2 s4
    slli 3 s6 t3
    add t3 t2 t2
    addi 16 t2 t2
    sd 184 t2 s4
    li 48 t3
    mul t3 s6 t3
    add t3 t2 t2
    addi 32 t2 t2
    sd 200 t2 s4
    sd 208 zero s4
    ld 184 s4 a0
    call dptr
    sd 80 a0 s4
    ld 216 s4 t0
    li 24 t1
    mul t1 t0 t0
    la dbg_cie a0
    add t0 a0 a0
    li 24 a1
    call dcopy
    li 0 s7
    li 0 s8
    li 0 s9
    E2:
    bgeu rel:E7 s6 s7
    li 24 t0
    mul t0 s7 t0
    la dbg_fns s10
    add t0 s10 s10
    addi 8 s10 s10
    addi 1 s7 s7
    ld 16 s10 t0
    beqz E2 t0
    ld 216 s4 s11
    sd 248 zero s4
    ld 8 s10 a0
    call dptr
    li 4 a1
    call drd
    mv a0 s5
    li 3 t0
    bne rel:E3 t0 s11
    la dbg_tpar a0
    addi 64 a0 a0
    li 4 a1
    call drd
    bne rel:E3 a0 s5
    li 4 s11
    E3:
    slli 4 s11 a0
    la dbg_tpar t0
    add t0 a0 a0
    li 4 a1
    call drd
    bne rel:E2 a0 s5
    ld 16 s10 a0
    addi -4 a0 a0
    call dptr
    li 4 a1
    call drd
    mv a0 s5
    slli 4 s11 a0
    la dbg_tpar t0
    add t0 a0 a0
    addi 4 a0 a0
    li 4 a1
    call drd
    bne rel:E2 a0 s5
    slli 4 s11 t1
    la dbg_tpar t2
    add t2 t1 t1
    lbu 8 t1 t2
    lbu 9 t1 t3
    ld 16 s10 t5
    sub t3 t5 t5
    ld 8 s10 t6
    add t2 t6 t6
    sub t6 t5 t5
    blez E2 t5
    li 48 t0
    mul t0 s8 t0
    ld 184 s4 t1
    add t1 t0 t0
    addi 24 t0 s5
    mv s5 a0
    call dptr
    sd 80 a0 s4
    li 44 a0
    call dput4
    ld 184 s4 t0
    addi 4 s5 a0
    sub t0 a0 a0
    call dput4
    ld 8 s10 a0
    addi 8 s5 t0
    sub t0 a0 a0
    call dput4
    ld 8 s10 t0
    ld 16 s10 a0
    sub t0 a0 a0
    call dput4
    li 0 a0
    call dput1
    slli 5 s11 t0
    la dbg_fde a0
    add t0 a0 a0
    li 31 a1
    call dcopy
    ld 0 s10 a0
    la dbg_startn a1
    li 7 a2
    call is_named
    sd 248 a0 s4
    beqz E4 a0
    addi 17 s5 a0
    call dptr
    li 7 t0
    sb 0 t0 a0
    slli 4 s11 t1
    la dbg_tpar t2
    add t2 t1 t1
    lbu 11 t1 t1
    sb 1 t1 a0
    E4:
    slli 4 s11 t1
    la dbg_tpar t2
    add t2 t1 t1
    lbu 8 t1 t2
    lbu 9 t1 t3
    lbu 10 t1 t4
    ld 16 s10 t5
    sub t3 t5 t5
    ld 8 s10 t6
    add t2 t6 t6
    sub t6 t5 a2
    addi 17 s5 a0
    add t4 a0 a0
    call dptr
    li 4 a1
    call dwrn
    ld 168 s4 t0
    slli 3 s8 t1
    add t1 t0 a0
    addi 12 a0 a0
    call dptr
    sd 80 a0 s4
    ld 168 s4 t0
    ld 8 s10 a0
    sub t0 a0 a0
    call dput4
    ld 168 s4 t0
    sub t0 s5 a0
    call dput4
    addi 1 s8 s8
    li 3 t0
    bltu rel:E2 t0 s11
    ld 200 s4 t0
    ld 208 s4 t1
    add t1 t0 a0
    call dptr
    sd 80 a0 s4
    beqz E5 s9
    ld 8 s10 t0
    beq rel:E5 t0 s9
    mv s9 a0
    li 1 a1
    call dexent
    E5:
    ld 8 s10 a0
    li32 -2137291648 a1
    ld 248 s4 t0
    beqz E6 t0
    li 1 a1
    E6:
    call dexent
    ld 16 s10 s9
    j E2
    E7:
    ld 216 s4 t0
    li 3 t1
    bne rel:E8 t1 t0
    beqz E8 s9
    ld 200 s4 t0
    ld 208 s4 t1
    add t1 t0 a0
    call dptr
    sd 80 a0 s4
    mv s9 a0
    li 1 a1
    call dexent
    E8:
    li 48 t0
    mul t0 s8 t0
    ld 184 s4 t1
    add t1 t0 a0
    addi 24 a0 a0
    call dptr
    sd 80 a0 s4
    li 0 a0
    call dput4
    li 48 t0
    mul t0 s8 t0
    addi 28 t0 t0
    sd 192 t0 s4
    slli 3 s8 t0
    addi 12 t0 t0
    sd 176 t0 s4
    ld 168 s4 a0
    call dptr
    sd 80 a0 s4
    li 1 a0
    call dput1
    li 27 a0
    call dput1
    li 3 a0
    call dput1
    li 59 a0
    call dput1
    ld 168 s4 t0
    addi 4 t0 t0
    ld 184 s4 a0
    sub t0 a0 a0
    call dput4
    mv s8 a0
    call dput4
    la dbg_area t0
    ld 0 t0 a0
    call dptr
    sd 80 a0 s4
    ld 104 s4 t0
    la outbuf a0
    add t0 a0 a0
    ld 112 s4 t0
    ld 120 s4 a1
    mul t0 a1 a1
    call dcopy
    li32 1685382480 a0
    ld 168 s4 a1
    ld 176 s4 a2
    call dphdr
    ld 112 s4 s5
    addi 1 s5 s5
    ld 216 s4 t0
    li 3 t1
    bne rel:E10 t1 t0
    li32 1879048193 a0
    ld 200 s4 a1
    ld 208 s4 a2
    call dphdr
    addi 1 s5 s5
    E10:
    la dbg_area t0
    ld 0 t0 t0
    ld 16 s4 t1
    sub t1 t0 a1
    li 0 a0
    call dhfw
    li 4 a0
    mv s5 a1
    call dhfw
    E9:
    leave8
", 2);

$code .= cfn('dexent', "an entry of .ARM.exidx at the cursor: the function at a0 (prel31), its word a1; dbg_st 208 grows by 8", "
    enter1
    mv a1 s4
    la dbg_st t0
    ld 80 t0 t1
    la outbuf t2
    sub t2 t1 t1
    ld 16 t0 t2
    add t2 t1 t1
    sub t1 a0 a0
    slli 33 a0 a0
    srli 33 a0 a0
    call dput4
    mv s4 a0
    call dput4
    la dbg_st t0
    ld 208 t0 t1
    addi 8 t1 t1
    sd 208 t1 t0
    leave1
", 2);

$code .= cfn('dphdr', "a program header at the cursor, as the class has it: type a0, R, the part at a1 of a2 bytes, aligned to 4", "
    enter5
    mv a0 s4
    mv a1 s6
    mv a2 s7
    la dbg_st s8
    call dput4
    ld 0 s8 t0
    beqz F1 t0
    li 4 a0
    call dput4
    F1:
    ld 16 s8 t0
    sub t0 s6 a0
    call dputa
    mv s6 a0
    call dputa
    mv s6 a0
    call dputa
    mv s7 a0
    call dputa
    mv s7 a0
    call dputa
    ld 0 s8 t0
    bnez F2 t0
    li 4 a0
    call dput4
    F2:
    li 4 a0
    call dputa
    leave5
", 2);

# ---- the constant data: per frame (0 riscv64, 1 x86_64, 2 aarch64, 3 arm, 4 arm's variadic)
my @cie = (
    [0x78, 0x01, 0x0c, 0x02, 0x00],
    [0x78, 0x10, 0x0c, 0x07, 0x08, 0x90, 0x01],
    [0x78, 0x1e, 0x0c, 0x1f, 0x00],
    [0x7c, 0x0e, 0x0c, 0x0d, 0x00],
);
my @cb;
for (@cie) {
    my ($da, $ra, @init) = @$_;
    my @c = (0x14, 0, 0, 0, 0, 0, 0, 0, 1, ord 'z', ord 'R', 0, 1, $da, $ra, 1, 0x1b, @init);
    push @c, 0 while @c < 24;
    die "ehframe.pl: CIE of " . @c . " bytes\n" if @c != 24;
    push @cb, @c;
}
# an FDE's instructions: 2 bytes for _start (DW_CFA_undefined RA), the
# prologue's, DW_CFA_advance_loc4 to the epilogue's first change, the epilogue's
my @fde = (
    [[0x44, 0x0e, 0x10, 0x44, 0x81, 0x01, 0x44, 0x88, 0x02, 0x44, 0x0d, 0x08], [0x0c, 0x02, 0x10, 0x48, 0xc1, 0xc8, 0x44, 0x0e, 0x00]],
    [[0x42, 0x0e, 0x10, 0x86, 0x02, 0x43, 0x0d, 0x06], [0x0c, 0x07, 0x08, 0xc6]],
    [[0x44, 0x0e, 0x10, 0x9d, 0x02, 0x9e, 0x01, 0x44, 0x0d, 0x1d], [0x0c, 0x1f, 0x10, 0x44, 0x0e, 0x00, 0xdd, 0xde]],
    [[0x44, 0x0e, 0x08, 0x8b, 0x02, 0x8e, 0x01, 0x44, 0x0d, 0x0b], [0x0c, 0x0d, 0x08]],
    [[0x44, 0x0e, 0x10, 0x44, 0x0e, 0x18, 0x8b, 0x06, 0x8e, 0x05, 0x44, 0x0d, 0x0b], [0x0c, 0x0d, 0x18, 0x44, 0x0e, 0x10, 0xcb, 0xce, 0x44, 0x0e, 0x00]],
);
# per frame: cc_enter's first word, cc_leave's last, the prologue's length,
# the epilogue's first change before the end, where the distance is, RA
my @par = (
    [0xff010113, 0x00008067, 16, 16, 1],
    [0x89485540, 0xc35d40ec, 5, 1, 16],
    [0xa9bf7bfd, 0xd65f03c0, 8, 8, 30],
    [0xe92d4800, 0xe8bd8800, 8, 4, 14],
    [0xe92d000f, 0xe12fff1e, 12, 12, 14],
);
my (@fb, @pb);
for my $i (0 .. $#fde) {
    my ($pro, $epi) = @{ $fde[$i] };
    my @f = (0, 0, @$pro, 0x04, 0, 0, 0, 0, @$epi);
    die "ehframe.pl: FDE $i of " . @f . " bytes\n" if @f > 31;
    push @f, 0 while @f < 32;
    push @fb, @f;
    my ($pw, $ew, $pl, $ek, $ra) = @{ $par[$i] };
    push @pb, unpack('C4', pack 'V', $pw), unpack('C4', pack 'V', $ew), $pl, $ek, 2 + @$pro + 1, $ra, 0, 0, 0, 0;
}
$code .= bytes('dbg_cie', 'the CIE of each target (24 bytes): riscv64, x86_64, aarch64, arm', @cb);
$code .= bytes('dbg_fde', 'the instructions of an FDE (31 bytes, from 32): riscv64, x86_64, aarch64, arm, arm variadic', @fb);
$code .= bytes('dbg_tpar', 'per frame (16 bytes): the first word of cc_enter, the last of cc_leave, the prologue, the epilogue from the end, where in an FDE the distance between them is, the return address register', @pb);
$code .= bytes('dbg_startn', 'the name of the function where a walk ends', map { ord } split //, "_start:");

once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');
save();
