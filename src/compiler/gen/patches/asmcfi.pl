# asmcfi.pl: the frames of asm functions (lane EH, the user's words of
# 2026-11-20): GNU's .cfi_* directives as words of the ff asm pages, cfi
# and the directive's name spaced, between the instructions where gcc has
# them, emitting no bytes:
#
#   cfi def cfa / r / n        cfi def cfa offset / n    cfi def cfa register / r
#   cfi offset / r / n         cfi rel offset / r / n    cfi adjust cfa offset / n
#   cfi restore / r            cfi remember state        cfi restore state
#   cfi register / r / r       cfi undefined / r         cfi same value / r
#   cfi escape / byte ...      cfi signal frame
#
# A register is its name as the target's asm writes it (ra, s9, fs0; rbp,
# rip; x29, sp, d8) or its DWARF number. There is no startproc or endproc:
# the asm function is the procedure. code_call takes a cfi word before any
# other (ehcfi): it records a row, the bytes of its DWARF instruction after
# an advance from the row before (DW_CFA_advance_loc*, by the distance in
# code, the same in both passes), under the asm function it is in (the
# latest placed label whose first child is asm, an index of the label
# table). Where the program has its frames (ehtable.pl: -g or the unwinder),
# dbgeh writes an FDE per such function after the C layer's (the CIE of the
# target, whose first rules are GNU's: riscv64 and aarch64 CFA = sp,
# x86_64 CFA = rsp + 8 and the return address at CFA - 8), its range the
# label's, and its entry in .eh_frame_hdr, whose table is sorted then. The
# room (dbgarea) is sized from the counts at the library's end: rows, FDEs
# (24 bytes each at most past their rows) and bytes; -j's samples keep them.
# The CFA's offset is followed while recording (rel offset and adjust cfa
# offset need it, remember and restore state keep it). cfi signal frame
# records nothing (none of glibc's on these targets). On arm the cfi words
# record nothing: gcc puts them in .debug_frame there, its unwinder reads
# EHABI's tables.
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

# ---- the variables (bss), after ehtable.pl's
once(\$t, "  eh_stk:\n    reserve\n      512\n",
    "  eh_stk:\n    reserve\n      512\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
        [eh_cfn => 8], [eh_cka => 8], [eh_cby => 8], [eh_cfun => 8], [eh_cfa => 8], [eh_cpc => 8], [eh_cdep => 8],
        [eh_crs => 64], [eh_csnap => 24], [eh_crow => 64 * 65536]), 'eh_stk');

# ---- each pass starts with none
edit(\$t, 'compile_page', asm(6, "
    la eh_sp t0
    sd 0 zero t0
"), asm(6, "
    la eh_sp t0
    sd 0 zero t0
    la eh_cfn t0
    sd 0 zero t0
    la eh_cka t0
    sd 0 zero t0
    la eh_cby t0
    sd 0 zero t0
    la eh_cfun t0
    li -1 t1
    sd 0 t1 t0
"));

# ---- -j: a sample keeps them
edit(\$t, 'par_vars', asm(4, "
    dword 1
    dword eh_kf
    dword 0
    dword 8
"), asm(4, "
    dword 1
    dword eh_kf
    dword 0
    dword 8
    dword 1
    dword eh_cfn
    dword 0
    dword 48
"));
# (eh_cfn eh_cka eh_cby eh_cfun eh_cfa eh_cpc: 48 bytes in a row)

# ---- code_call: a cfi word first
edit(\$t, 'code_call', asm(4, "
    call dbgrowc
    call is_comment
"), asm(4, "
    call dbgrowc
    mv s4 a0
    mv s5 a1
    call ehcfi
    bnez L2 a0
    mv s4 a0
    mv s5 a1
    call is_comment
"));

# ---- place, first pass: a label's end 0 until its children are placed (it
# held what the memory had), which ehcfn reads as not ended
edit(\$t, 'place', asm(4, "
    sd LABEL_node s4 s5
    sd LABEL_addr t4 s5
    call LJ
"), asm(4, "
    sd LABEL_node s4 s5
    sd LABEL_addr t4 s5
    sd LABEL_end zero s5
    call LJ
"));

# ---- the room and dbgeh: the asm functions' FDEs
edit(\$t, 'cc/ehroom', asm(8, "
    beqz R9 t1
    addi 32 a0 a0
R9:
    ret
"), asm(8, "
    beqz R8 t1
    addi 32 a0 a0
R8:
    la eh_cka t0
    ld 0 t0 t1
    la eh_cby t0
    ld 0 t0 t2
    la eh_cfn t0
    ld 0 t0 t3
    la eh_csnap t0
    sd 0 t1 t0
    sd 8 t2 t0
    sd 16 t3 t0
    slli 3 t1 t1
    add t1 a0 a0
    add t2 a0 a0
R9:
    ret
"));
# (ehx: .eh_frame's bytes more; ehhx: .eh_frame_hdr's, ahead of it)
edit(\$t, 'ehx', asm(4, "
    beqz X9 t1
    addi 32 a0 a0
X9:
    ret
"), asm(4, "
    beqz X8 t1
    addi 32 a0 a0
X8:
    la eh_csnap t0
    ld 8 t0 t1
    add t1 a0 a0
X9:
    ret
"));
edit(\$t, 'dbgeh', asm(6, "
    addi 16 t2 t2
    sd 184 t2 s4
"), asm(6, "
    addi 16 t2 t2
    mv t2 s5
    call ehhx
    add a0 s5 t2
    sd 184 t2 s4
"), "    E7:\n", "    E7:\n" . asm(6, "
    mv s8 a0
    call ehasm
    mv a0 s8
"), asm(6, "
    ld 168 s4 a0
    call dptr
    sd 80 a0 s4
    li 1 a0
    call dput1
"), asm(6, "
    mv s8 a0
    call ehsort
    ld 168 s4 a0
    call dptr
    sd 80 a0 s4
    li 1 a0
    call dput1
"));

# ---- compile time's part (code_call's), at the end of layer 0
my $code = cfn('ehcfi', "a cfi word (node a0, frame a1), else 0: its row recorded (eh_crow, 64 bytes: pc, the function's label (an offset in the label table), the bytes' count, the bytes: an advance, the DWARF instruction), a0 1", "
    enter8
    mv a0 s4
    mv a1 s5
    li 0 s6
    lbu NODE_content_len s4 t0
    li 4 t1
    bltu rel:C9 t1 t0
    ld NODE_content s4 t2
    lbu 0 t2 t3
    li 99 t4
    bne rel:C9 t4 t3
    lbu 1 t2 t3
    li 102 t4
    bne rel:C9 t4 t3
    lbu 2 t2 t3
    li 105 t4
    bne rel:C9 t4 t3
    lbu 3 t2 t3
    li 32 t4
    bne rel:C9 t4 t3
    li 1 s6
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    beq rel:C9 t1 t0
    la eh_cfn t0
    ld 0 t0 t1
    li32 65536 t2
    bgeu rel:C9 t2 t1
    mv s4 a0
    call ehcop
    mv a0 s7
    beqz C8 s7
    call ehcfn
    mv a0 s8
    bltz C9 s8
    la eh_cfun t0
    ld 0 t0 t1
    beq rel:C2 t1 s8
    sd 0 s8 t0
    la eh_cka t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
    la eh_cby t0
    ld 0 t0 t1
    addi 24 t1 t1
    sd 0 t1 t0
    la labels_base t0
    ld 0 t0 t0
    add s8 t0 t0
    ld LABEL_addr t0 t1
    la eh_cpc t0
    sd 0 t1 t0
    li 0 t1
    la targ_abi t0
    ld 0 t0 t0
    li 3 t2
    bne rel:C1 t2 t0
    li 8 t1
C1:
    la eh_cfa t0
    sd 0 t1 t0
    la eh_cdep t0
    sd 0 zero t0
C2:
    la eh_cfn t0
    ld 0 t0 t1
    slli 6 t1 s9
    la eh_crow t2
    add t2 s9 s9
    addi 1 t1 t1
    sd 0 t1 t0
    la cur_pc t0
    ld 0 t0 t0
    sd 0 t0 s9
    sd 8 s8 s9
    addi 24 s9 s10
    la eh_cpc t1
    ld 0 t1 t2
    sd 0 t0 t1
    sub t2 t0 a0
    mv s10 a1
    call ehadv
    mv a1 s10
    mv s4 a0
    mv s7 a1
    mv s10 a2
    call ehops
    sub s10 a0 t0
    addi 24 s9 t1
    sub t1 a0 t1
    sd 16 t1 s9
    la eh_cby t0
    ld 0 t0 t2
    add t1 t2 t2
    sd 0 t2 t0
    j C9
C8:
    la msg_cfi a1
    li 22 a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
C9:
    mv s6 a0
    leave8
", 2)
. cfn('ehcop', "the cfi word a0's instruction: 1 def cfa, 2 def cfa offset, 3 def cfa register, 4 offset, 5 rel offset, 6 adjust cfa offset, 7 restore, 8 remember state, 9 restore state, 10 register, 11 undefined, 12 same value, 13 escape, 14 signal frame; else 0", "
    enter3
    ld NODE_content a0 s4
    lbu NODE_content_len a0 s5
    la eh_cfiw s6
O1:
    lbu 0 s6 t0
    beqz O8 t0
    mv s4 a0
    mv s5 a1
    addi 2 s6 a2
    mv t0 a3
    call streq
    bnez O9 a0
    lbu 0 s6 t0
    add t0 s6 s6
    addi 2 s6 s6
    j O1
O8:
    li 0 a0
    leave3
O9:
    lbu 1 s6 a0
    leave3
", 2)
. cfn('ehcfn', "the asm function the code at cur_pc is in: the latest placed label (labels_end in the first pass, label_next in the second) whose first child is asm and whose end is not before cur_pc (an entry block that ended is not), its offset in the label table (-1 none)", "
    la labels_base t0
    ld 0 t0 t0
    la label_next t1
    la pass t2
    ld 0 t2 t2
    li 1 t3
    bne rel:F0 t3 t2
    la labels_end t1
F0:
    ld 0 t1 t1
F1:
    bgeu rel:F8 t1 t0
    li LABEL_size t2
    sub t2 t1 t1
    ld LABEL_node t1 t2
    lbu NODE_children_len t2 t3
    beqz F1 t3
    ld NODE_children t2 t3
    ld 0 t3 t3
    lbu NODE_content_len t3 t4
    li 3 t5
    bne rel:F1 t5 t4
    ld NODE_content t3 t3
    lbu 0 t3 t4
    li 97 t5
    bne rel:F1 t5 t4
    lbu 1 t3 t4
    li 115 t5
    bne rel:F1 t5 t4
    lbu 2 t3 t4
    li 109 t5
    bne rel:F1 t5 t4
    ld LABEL_end t1 t4
    beqz F2 t4
    la cur_pc t5
    ld 0 t5 t5
    bgeu rel:F1 t4 t5
F2:
    sub t0 t1 a0
    ret
F8:
    li -1 a0
    ret
", 2)
. cfn('ehadv', "DW_CFA_advance_loc of a0 bytes (none for 0) at a1: a1 past it", "
    beqz A9 a0
    li 64 t0
    bgeu rel:A2 t0 a0
    addi 64 a0 t1
    sb 0 t1 a1
    addi 1 a1 a1
    ret
A2:
    li 256 t0
    bgeu rel:A3 t0 a0
    li 2 t1
    sb 0 t1 a1
    sb 1 a0 a1
    addi 2 a1 a1
    ret
A3:
    lui 16 t0
    bgeu rel:A4 t0 a0
    li 3 t1
    sb 0 t1 a1
    sb 1 a0 a1
    srli 8 a0 t1
    sb 2 t1 a1
    addi 3 a1 a1
    ret
A4:
    li 4 t1
    sb 0 t1 a1
    sb 1 a0 a1
    srli 8 a0 t1
    sb 2 t1 a1
    srli 16 a0 t1
    sb 3 t1 a1
    srli 24 a0 t1
    sb 4 t1 a1
    addi 5 a1 a1
A9:
    ret
", 2)
. cfn('ehuleb', "a0 as uleb128 at a1: a1 past it", "
U1:
    andi 127 a0 t0
    srli 7 a0 a0
    beqz U2 a0
    addi 128 t0 t0
    sb 0 t0 a1
    addi 1 a1 a1
    j U1
U2:
    sb 0 t0 a1
    addi 1 a1 a1
    ret
", 2)
. cfn('ehsleb', "a0 as sleb128 at a1: a1 past it", "
S1:
    andi 127 a0 t0
    srai 7 a0 a0
    beqz S2 a0
    li -1 t1
    beq rel:S3 t1 a0
    j S4
S2:
    andi 64 t0 t1
    beqz S5 t1
    j S4
S3:
    andi 64 t0 t1
    bnez S5 t1
S4:
    addi 128 t0 t0
    sb 0 t0 a1
    addi 1 a1 a1
    j S1
S5:
    sb 0 t0 a1
    addi 1 a1 a1
    ret
", 2)
. cfn('ehnum', "the number of node a0 (a leaf), else it dies", "
    enter1
    mv a0 s4
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call parse_num
    beqz N8 a1
    leave1
N8:
    la msg_cfin a1
    li 41 a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
", 2)
. cfn('ehreg', "the DWARF number of register node a0: a number, or a name of the target's (eh_regs), else it dies", "
    enter3
    mv a0 s4
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call parse_num
    beqz R1 a1
    leave3
R1:
    la targ_abi t0
    ld 0 t0 t0
    la eh_regs s5
    li 4 t1
    beq rel:R2 t1 t0
    la eh_regsx s5
    li 3 t1
    beq rel:R2 t1 t0
    la eh_regsa s5
R2:
    lbu 0 s5 t0
    beqz R8 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    addi 2 s5 a2
    mv t0 a3
    call streq
    bnez R3 a0
    lbu 0 s5 t0
    add t0 s5 s5
    addi 2 s5 s5
    j R2
R3:
    lbu 1 s5 a0
    leave3
R8:
    la msg_cfir a1
    li 53 a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
", 2)
. cfn('ehops', "cfi word a0 (instruction a1) at a2: its DWARF instruction, the CFA's offset followed (eh_cfa, eh_crs); a0 past it", "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    li 0 s9
    li 0 s10
    lbu NODE_children_len s4 s11
    ld NODE_children s4 s7
    li 13 t0
    beq rel:P13 t0 s5
    li 1 t0
    beq rel:P1 t0 s5
    li 2 t0
    beq rel:P2 t0 s5
    li 3 t0
    beq rel:P3 t0 s5
    li 4 t0
    beq rel:P4 t0 s5
    li 5 t0
    beq rel:P5 t0 s5
    li 6 t0
    beq rel:P6 t0 s5
    li 7 t0
    beq rel:P7 t0 s5
    li 8 t0
    beq rel:P8 t0 s5
    li 9 t0
    beq rel:P9 t0 s5
    li 10 t0
    beq rel:P10 t0 s5
    li 11 t0
    beq rel:P11 t0 s5
    li 12 t0
    beq rel:P12 t0 s5
    j PZ
P1:
    li 2 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehreg
    mv a0 s9
    ld 8 s7 a0
    call ehnum
    mv a0 s10
    la eh_cfa t0
    sd 0 s10 t0
    li 12 t0
    sb 0 t0 s6
    addi 1 s6 s6
    mv s9 a0
    mv s6 a1
    call ehuleb
    mv s10 a0
    call ehuleb
    mv a1 s6
    j PZ
P2:
    li 1 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehnum
    mv a0 s10
P2b:
    la eh_cfa t0
    sd 0 s10 t0
    li 14 t0
    sb 0 t0 s6
    addi 1 s6 a1
    mv s10 a0
    call ehuleb
    mv a1 s6
    j PZ
P3:
    li 1 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehreg
    mv a0 s9
    li 13 t0
    sb 0 t0 s6
    addi 1 s6 a1
    mv s9 a0
    call ehuleb
    mv a1 s6
    j PZ
P5:
    li 2 t0
    bne rel:PW t0 s11
    ld 8 s7 a0
    call ehnum
    la eh_cfa t0
    ld 0 t0 t0
    sub t0 a0 s10
    j P4b
P4:
    li 2 t0
    bne rel:PW t0 s11
    ld 8 s7 a0
    call ehnum
    mv a0 s10
P4b:
    ld 0 s7 a0
    call ehreg
    mv a0 s9
    li 17 t0
    sb 0 t0 s6
    addi 1 s6 a1
    mv s9 a0
    call ehuleb
    mv a1 s6
    li 0 t0
    bgez P4c s10
    neg s10 a0
    srli 3 a0 a0
    j P4d
P4c:
    srli 3 s10 a0
    neg a0 a0
P4d:
    mv s6 a1
    call ehsleb
    mv a1 s6
    j PZ
P6:
    li 1 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehnum
    la eh_cfa t0
    ld 0 t0 t0
    add t0 a0 s10
    j P2b
P7:
    li 1 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehreg
    li 64 t0
    bgeu rel:P7b t0 a0
    addi 192 a0 t1
    sb 0 t1 s6
    addi 1 s6 s6
    j PZ
P7b:
    mv a0 s9
    li 6 t0
    sb 0 t0 s6
    addi 1 s6 a1
    mv s9 a0
    call ehuleb
    mv a1 s6
    j PZ
P8:
    la eh_cdep t0
    ld 0 t0 t1
    li 8 t2
    bgeu rel:P8b t2 t1
    slli 3 t1 t2
    la eh_crs t3
    add t2 t3 t3
    la eh_cfa t4
    ld 0 t4 t4
    sd 0 t4 t3
P8b:
    addi 1 t1 t1
    sd 0 t1 t0
    li 10 t0
    sb 0 t0 s6
    addi 1 s6 s6
    j PZ
P9:
    la eh_cdep t0
    ld 0 t0 t1
    beqz P9b t1
    addi -1 t1 t1
    sd 0 t1 t0
    li 8 t2
    bgeu rel:P9b t2 t1
    slli 3 t1 t2
    la eh_crs t3
    add t2 t3 t3
    ld 0 t3 t4
    la eh_cfa t0
    sd 0 t4 t0
P9b:
    li 11 t0
    sb 0 t0 s6
    addi 1 s6 s6
    j PZ
P10:
    li 2 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehreg
    mv a0 s9
    ld 8 s7 a0
    call ehreg
    mv a0 s10
    li 9 t0
    sb 0 t0 s6
    addi 1 s6 a1
    mv s9 a0
    call ehuleb
    mv s10 a0
    call ehuleb
    mv a1 s6
    j PZ
P11:
    li 7 s8
    j P11b
P12:
    li 8 s8
P11b:
    li 1 t0
    bne rel:PW t0 s11
    ld 0 s7 a0
    call ehreg
    mv a0 s9
    sb 0 s8 s6
    addi 1 s6 a1
    mv s9 a0
    call ehuleb
    mv a1 s6
    j PZ
P13:
    beqz PZ s11
    li 32 t0
    bltu rel:PW s11 t0
P13b:
    beqz PZ s11
    ld 0 s7 a0
    call ehnum
    sb 0 a0 s6
    addi 1 s6 s6
    addi 8 s7 s7
    addi -1 s11 s11
    j P13b
PW:
    j wrong_args
PZ:
    mv s6 a0
    leave8
", 2)
. cfn('ehhx', "the bytes .eh_frame_hdr has more for the asm functions' FDEs (0 on arm)", "
    la dbg_st t0
    ld 216 t0 t1
    li 3 t2
    li 0 a0
    beq rel:H9 t2 t1
    la eh_csnap t0
    ld 0 t0 a0
    slli 3 a0 a0
H9:
    ret
", 2)
. cfn('ehasm', "dbgeh's FDEs of the asm functions (the rows recorded up to the room's count), at dbg_st 256 on, each in .eh_frame_hdr's table after the a0 entries there; a0 the entries then", "
    enter8
    mv a0 s5
    la dbg_st s4
    ld 216 s4 t0
    li 3 t1
    beq rel:M9 t1 t0
    la eh_csnap t0
    ld 16 t0 s6
    la eh_crow s7
    li -1 s8
    li 0 s9
    li 0 s11
M1:
    beqz M8 s6
    ld 8 s7 t0
    beq rel:M3 t0 s8
    call ehfend
    ld 8 s7 s8
    la labels_base t1
    ld 0 t1 t1
    add s8 t1 t1
    ld LABEL_addr t1 s10
    ld LABEL_end t1 t2
    sub s10 t2 t2
    mv t2 s11
    ld 256 s4 s9
    mv s9 a0
    call dptr
    sd 80 a0 s4
    li 0 a0
    call dput4
    ld 184 s4 t0
    addi 4 s9 a0
    sub t0 a0 a0
    call dput4
    addi 8 s9 t0
    sub t0 s10 a0
    call dput4
    mv s11 a0
    call dput4
    li 0 a0
    call dput1
    ld 168 s4 t0
    slli 3 s5 t1
    add t1 t0 a0
    addi 12 a0 a0
    call dptr
    sd 80 a0 s4
    ld 168 s4 t0
    sub t0 s10 a0
    call dput4
    ld 168 s4 t0
    sub t0 s9 a0
    call dput4
    addi 1 s5 s5
    addi 17 s9 a0
    call dptr
    sd 80 a0 s4
M3:
    ld 16 s7 t5
    addi 24 s7 a0
    mv t5 a1
    call dcopy
    addi 64 s7 s7
    addi -1 s6 s6
    j M1
M8:
    call ehfend
M9:
    mv s5 a0
    leave8
", 2)
. cfn('ehfend', "the asm function's FDE at dbg_st 256 (s9's, if s8 is one) ended at the cursor: its length, 8-aligned with nops (DW_CFA_nop), dbg_st 256 past it", "
    enter2
    li -1 t0
    beq rel:E9 t0 s8
    call ehcur
    mv a0 s4
    addi 7 s4 s5
    andi -8 s5 s5
    sub s4 s5 t0
E1:
    beqz E2 t0
    li 0 a0
    addi -1 t0 t0
    mv t0 s4
    call dput1
    mv s4 t0
    j E1
E2:
    la dbg_st t0
    sd 256 s5 t0
    ld 256 t0 t1
    sub s9 s5 a0
    addi -4 a0 a0
    mv a0 s4
    mv s9 a0
    call dptr
    mv s4 t1
    sb 0 t1 a0
    srli 8 t1 t2
    sb 1 t2 a0
    srli 16 t1 t2
    sb 2 t2 a0
    srli 24 t1 t2
    sb 3 t2 a0
E9:
    leave2
", 2)
. cfn('ehsort', "the a0 entries of .eh_frame_hdr's table sorted by their first word (signed, datarel): insertion", "
    enter5
    mv a0 s4
    la dbg_st t0
    ld 168 t0 a0
    addi 12 a0 a0
    call dptr
    mv a0 s5
    li 1 s6
S1:
    bgeu rel:S9 s4 s6
    slli 3 s6 t0
    add t0 s5 t0
    ld 0 t0 t2
    slli 32 t2 t1
    srai 32 t1 t1
    mv s6 t3
S2:
    beqz S3 t3
    addi -1 t3 t4
    slli 3 t4 t4
    add t4 s5 t4
    ld 0 t4 t6
    slli 32 t6 t5
    srai 32 t5 t5
    bge rel:S3 t5 t1
    sd 8 t6 t4
    addi -1 t3 t3
    j S2
S3:
    slli 3 t3 t4
    add t4 s5 t4
    sd 0 t2 t4
    addi 1 s6 s6
    j S1
S9:
    leave5
", 2);

# the cfi words (count, instruction, text); the registers' DWARF numbers
# of riscv64 (x0 ... x31, f0 ... f31), x86_64 and aarch64 (count, number, name)
my @w = ('def cfa', 'def cfa offset', 'def cfa register', 'offset', 'rel offset', 'adjust cfa offset', 'restore',
    'remember state', 'restore state', 'register', 'undefined', 'same value', 'escape', 'signal frame');
my @wb;
for my $i (0 .. $#w) { my $s = "cfi $w[$i]"; push @wb, length $s, $i + 1, map { ord } split //, $s }
push @wb, 0;
sub regtab {
    my @b;
    for (@_) { my ($n, $r) = @$_; push @b, length $n, $r, map { ord } split //, $n }
    (@b, 0);
}
my @rv = qw(zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6);
my @rf = qw(ft0 ft1 ft2 ft3 ft4 ft5 ft6 ft7 fs0 fs1 fa0 fa1 fa2 fa3 fa4 fa5 fa6 fa7 fs2 fs3 fs4 fs5 fs6 fs7 fs8 fs9 fs10 fs11 ft8 ft9 ft10 ft11);
my @rvt = ((map { [$rv[$_], $_] } 0 .. 31), ['fp', 8], (map { ["x$_", $_] } 0 .. 31), (map { [$rf[$_], 32 + $_] } 0 .. 31), (map { ["f$_", 32 + $_] } 0 .. 31));
my @x = qw(rax rdx rcx rbx rsi rdi rbp rsp);
my @xt = ((map { [$x[$_], $_] } 0 .. 7), (map { ["r$_", $_] } 8 .. 15), ['rip', 16], (map { ["xmm$_", 17 + $_] } 0 .. 15));
my @at = ((map { ["x$_", $_] } 0 .. 30), ['fp', 29], ['lr', 30], ['sp', 31], (map { ["d$_", 64 + $_], ["v$_", 64 + $_], ["q$_", 64 + $_] } 0 .. 31));
my $data = '';
$data .= bytes('eh_cfiw', 'the cfi words: their length, their instruction, their text', @wb);
$data .= bytes('eh_regs', 'riscv64: a register name, its DWARF number', regtab(@rvt));
$data .= bytes('eh_regsx', 'x86_64: a register name, its DWARF number', regtab(@xt));
$data .= bytes('eh_regsa', 'aarch64: a register name, its DWARF number', regtab(@at));
$data .= "  msg_cfi:\n    ascii\n      ttpc: not a cfi word:\\x20\n"
    . "  msg_cfin:\n    ascii\n      ttpc: a cfi word's operand is no number:\\x20\n"
    . "  msg_cfir:\n    ascii\n      ttpc: a cfi word's register is none of the target's:\\x20\n";
once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');
# (the data at the start of layer 2, before its variables and bss: layer 0
# has room for the functions only)
once(\$t, "\n2:\n  comment\n    the variables, then the memory (bss): the trees, the labels, the buffers, the C layer's tables\n",
    "\n2:\n  comment\n    the variables, then the memory (bss): the trees, the labels, the buffers, the C layer's tables\n$data", 'the start of layer 2');
save();
