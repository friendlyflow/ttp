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
# rip; x29, sp, d8, vg) or its DWARF number. There is no startproc or
# endproc: a procedure is an asm function, or an entry block in it that
# starts with a cfi word (after asm, its comment and align). code_call
# takes a cfi word before any other (ehcfi): it records a row, the bytes of
# its DWARF instruction after an advance from the row before
# (DW_CFA_advance_loc*, by the distance in code, the same in both passes),
# under the procedure it is in (ehcfn: the latest placed label that is the
# function, the outermost open asm one of scopes, or such an entry; an
# index of the label table), with its function (ehfun). Where the program
# has its frames (ehtable.pl: -g or the unwinder), dbgeh writes an FDE per
# procedure after the C layer's (the CIE of the target, whose first rules
# are GNU's: riscv64 and aarch64 CFA = sp, x86_64 CFA = rsp + 8 and the
# return address at CFA - 8), from its label to the next procedure or its
# function's end (ehpend), and its entry in .eh_frame_hdr, whose table is
# sorted then. The room (dbgarea) is sized from the counts at the library's
# end: rows, FDEs (24 bytes each at most past their rows) and bytes; -j's
# samples keep them. The CFA's offset is followed while recording (rel
# offset and adjust cfa offset need it, remember and restore state keep
# it); one below 0 is DW_CFA_def_cfa_offset_sf. cfi signal frame records
# nothing (none of glibc's on these targets).
#
# arm (EHABI, which its unwinder reads; gcc puts the CFI in .debug_frame
# there, so the cfi words record nothing): the ehabi words, GNU's
# directives without fnstart and fnend,
#
#   ehabi save / r4 / lr       ehabi pad / 8             ehabi cantunwind
#
# record rows of their own (the word and its registers' mask or offset),
# and ehexidx writes each procedure's .ARM.exidx entry from them as GNU as
# does (ehabops: a pad pending until the next save or the end, each save's
# pops, all of them last first): its unwinding instructions inline (3 at
# most), or a personality-1 .ARM.extab entry after .ARM.exidx's room
# (ehxtab), or EXIDX_CANTUNWIND; an EXIDX_CANTUNWIND entry where it ends
# unless another procedure starts there; then the table with the C layer's
# entries sorted, of two at one place the EXIDX_CANTUNWIND left out (ehxsort).
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
        [eh_cfn => 8], [eh_cka => 8], [eh_cby => 8], [eh_cfun => 8], [eh_cfa => 8], [eh_cpc => 8], [eh_cfp => 8], [eh_cdep => 8],
        [eh_crs => 64], [eh_csnap => 24], [eh_abk => 8], [eh_abn => 8], [eh_abtmp => 8], [eh_abuf => 64], [eh_abadd => 256],
        [eh_crow => 64 * 65536]), 'eh_stk');

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
    dword 56
"));
# (eh_cfn eh_cka eh_cby eh_cfun eh_cfa eh_cpc eh_cfp: 56 bytes in a row)

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
    beqz R7 t1
    addi 32 a0 a0
R7:
    li 0 t5
    j R8
R9:
    li 1 t5
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
    beqz R6 t5
    add t1 a0 a0
    slli 4 t3 t3
    add t3 a0 a0
R6:
    ret
"));
# (ehinit, arm: the LSDAs after the asm functions' entries of .ARM.exidx
# (16 bytes a function) and their .ARM.extab entries (eh_cby and 16 a row))
edit(\$t, 'ehinit', asm(6, "
    slli 4 s5 t3
    add t3 t0 t0
") . "    I2:\n", asm(6, "
    slli 4 s5 t3
    add t3 t0 t0
    la eh_csnap t3
    ld 0 t3 t4
    slli 4 t4 t4
    add t4 t0 t0
    ld 8 t3 t4
    add t4 t0 t0
    ld 16 t3 t4
    slli 4 t4 t4
    add t4 t0 t0
") . "    I2:\n");
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
    mv s6 a0
    call ehexidx
    ld 168 s4 a0
    call dptr
    sd 80 a0 s4
    li 1 a0
    call dput1
"));

# ---- compile time's part (code_call's), at the end of layer 0
my $code = cfn('ehcfi', "a cfi word (node a0, frame a1), or on arm an ehabi word, else 0: its row recorded (eh_crow, 64 bytes: pc, the procedure's label and its function's (offsets in the label table, the function's << 32), the bytes' count, the bytes: an advance and the DWARF instruction, or ehabi's (ehaops)), a0 1; a cfi word on arm and an ehabi word elsewhere record nothing", "
    enter8
    mv a0 s4
    mv a1 s5
    li 0 s6
    li 0 s11
    lbu NODE_content_len s4 t0
    li 4 t1
    bltu rel:C9 t1 t0
    ld NODE_content s4 t2
    lbu 0 t2 t3
    li 99 t4
    bne rel:C5 t4 t3
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
    mv s4 a0
    la eh_cfiw a1
    call ehcop
    mv a0 s7
    j C4
C5:
    li 101 t4
    bne rel:C9 t4 t3
    li 6 t1
    bltu rel:C9 t1 t0
    lbu 1 t2 t3
    li 104 t4
    bne rel:C9 t4 t3
    lbu 2 t2 t3
    li 97 t4
    bne rel:C9 t4 t3
    lbu 3 t2 t3
    li 98 t4
    bne rel:C9 t4 t3
    lbu 4 t2 t3
    li 105 t4
    bne rel:C9 t4 t3
    lbu 5 t2 t3
    li 32 t4
    bne rel:C9 t4 t3
    li 1 s6
    li 1 s11
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    bne rel:C9 t1 t0
    mv s4 a0
    la eh_abiw a1
    call ehcop
    mv a0 s7
C4:
    beqz C8 s7
    la eh_cfn t0
    ld 0 t0 t1
    li32 65536 t2
    bgeu rel:C9 t2 t1
    call ehcfn
    mv a0 s8
    bltz C9 s8
    la eh_cfun t0
    ld 0 t0 t1
    beq rel:C2 t1 s8
    sd 0 s8 t0
    mv s8 a0
    call ehfun
    slli 32 a0 a0
    or s8 a0 a0
    la eh_cfp t0
    sd 0 a0 t0
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
    la eh_cfp t1
    ld 0 t1 t1
    sd 8 t1 s9
    addi 24 s9 s10
    beqz C3 s11
    mv s4 a0
    mv s7 a1
    mv s10 a2
    call ehaops
    j C6
C3:
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
C6:
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
    li 31 a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
C9:
    mv s6 a0
    leave8
", 2)
. cfn('ehcop', "the word a0's instruction in table a1 (eh_cfiw: 1 def cfa, 2 def cfa offset, 3 def cfa register, 4 offset, 5 rel offset, 6 adjust cfa offset, 7 restore, 8 remember state, 9 restore state, 10 register, 11 undefined, 12 same value, 13 escape, 14 signal frame; eh_abiw: 1 save, 2 pad, 3 cantunwind); else 0", "
    enter3
    ld NODE_content a0 s4
    lbu NODE_content_len a0 s5
    mv a1 s6
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
. cfn('ehcfn', "the procedure the code at cur_pc is in: the latest placed label (labels_end in the first pass, label_next in the second) whose first child is asm and which is the function (the outermost open one, ehfnode) or an entry block that starts with a cfi or ehabi word (ehlead), its offset in the label table (-1 none)", "
    enter3
    call ehfnode
    mv a0 s6
    beqz F8 s6
    la labels_base t0
    ld 0 t0 s4
    la label_next t1
    la pass t2
    ld 0 t2 t2
    li 1 t3
    bne rel:F0 t3 t2
    la labels_end t1
F0:
    ld 0 t1 s5
F1:
    bgeu rel:F8 s5 s4
    li LABEL_size t2
    sub t2 s5 s5
    ld LABEL_node s5 a0
    beq rel:F2 a0 s6
    call ehlead
    beqz F1 a0
F2:
    sub s4 s5 a0
    leave3
F8:
    li -1 a0
    leave3
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
. cfn('ehreg', "the DWARF number of register node a0 (arm: its number): a number, or a name of the target's (eh_regs, eh_regsx, eh_regsr, eh_regsa), else it dies", "
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
    la eh_regsr s5
    li 1 t1
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
. cfn('ehops', "cfi word a0 (instruction a1) at a2: its DWARF instruction (a CFA's offset below it DW_CFA_def_cfa_offset_sf), the CFA's offset followed (eh_cfa, eh_crs); a0 past it", "
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
    bltz P2n s10
    li 14 t0
    sb 0 t0 s6
    addi 1 s6 a1
    mv s10 a0
    call ehuleb
    mv a1 s6
    j PZ
P2n:
    li 19 t0
    sb 0 t0 s6
    addi 1 s6 a1
    neg s10 a0
    srli 3 a0 a0
    call ehsleb
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
. cfn('ehasm', "dbgeh's FDEs of the asm functions' procedures (the rows recorded up to the room's count), at dbg_st 256 on, each in .eh_frame_hdr's table after the a0 entries there, its range to its end (ehpend); a0 the entries then", "
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
    mv s7 a0
    mv s6 a1
    call ehpend
    mv a0 s11
    slli 32 s8 t1
    srli 32 t1 t1
    la labels_base t0
    ld 0 t0 t0
    add t1 t0 t1
    ld LABEL_addr t1 s10
    sub s10 s11 s11
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


# ---- more of it, at the start of layer 2 (layer 0 is full): the
# procedures' ends, arm's EHABI
my $code2 = cfn('ehlead', "1 if node a0's first child is asm and its first after asm, comment and align is a cfi or ehabi word (an entry block that starts a procedure), else 0", "
    lbu NODE_children_len a0 t0
    ld NODE_children a0 t1
    beqz W8 t0
    ld 0 t1 t2
    lbu NODE_content_len t2 t3
    li 3 t4
    bne rel:W8 t4 t3
    ld NODE_content t2 t2
    lbu 0 t2 t3
    li 97 t4
    bne rel:W8 t4 t3
    lbu 1 t2 t3
    li 115 t4
    bne rel:W8 t4 t3
    lbu 2 t2 t3
    li 109 t4
    bne rel:W8 t4 t3
W1:
    addi 8 t1 t1
    addi -1 t0 t0
    beqz W8 t0
    ld 0 t1 t2
    lbu NODE_content_len t2 t3
    ld NODE_content t2 t2
    li 7 t4
    bne rel:W3 t4 t3
    lbu 0 t2 t5
    li 99 t4
    bne rel:W3 t4 t5
    lbu 1 t2 t5
    li 111 t4
    beq rel:W1 t4 t5
W3:
    li 5 t4
    bne rel:W4 t4 t3
    lbu 0 t2 t5
    li 97 t4
    bne rel:W4 t4 t5
    lbu 1 t2 t5
    li 108 t4
    beq rel:W1 t4 t5
W4:
    li 4 t4
    bltu rel:W8 t4 t3
    lbu 0 t2 t5
    li 99 t4
    bne rel:W2 t4 t5
    lbu 1 t2 t5
    li 102 t4
    bne rel:W8 t4 t5
    lbu 2 t2 t5
    li 105 t4
    bne rel:W8 t4 t5
    lbu 3 t2 t5
    li 32 t4
    bne rel:W8 t4 t5
    li 1 a0
    ret
W2:
    li 101 t4
    bne rel:W8 t4 t5
    li 6 t4
    bltu rel:W8 t4 t3
    lbu 1 t2 t5
    li 104 t4
    bne rel:W8 t4 t5
    lbu 2 t2 t5
    li 97 t4
    bne rel:W8 t4 t5
    lbu 3 t2 t5
    li 98 t4
    bne rel:W8 t4 t5
    lbu 4 t2 t5
    li 105 t4
    bne rel:W8 t4 t5
    lbu 5 t2 t5
    li 32 t4
    bne rel:W8 t4 t5
    li 1 a0
    ret
W8:
    li 0 a0
    ret
", 2)
. cfn('ehfnode', "the node of the asm function the code is in: the outermost open label whose first child is asm (scopes), else 0", "
    la scope_depth t0
    ld 0 t0 t1
    la scopes t2
    li 0 t3
U1:
    bgeu rel:U8 t1 t3
    slli 3 t3 t4
    add t2 t4 t4
    ld 0 t4 a0
    addi 1 t3 t3
    lbu NODE_children_len a0 t5
    beqz U1 t5
    ld NODE_children a0 t5
    ld 0 t5 t5
    lbu NODE_content_len t5 t6
    li 3 a1
    bne rel:U1 a1 t6
    ld NODE_content t5 t5
    lbu 0 t5 t6
    li 97 a1
    bne rel:U1 a1 t6
    lbu 1 t5 t6
    li 115 a1
    bne rel:U1 a1 t6
    lbu 2 t5 t6
    li 109 a1
    bne rel:U1 a1 t6
    ret
U8:
    li 0 a0
    ret
", 2)
. cfn('ehfun', "the function of the procedure at label a0 (an offset in the label table): ehfnode's, found back from a0; a0 if none", "
    enter1
    mv a0 s4
    call ehfnode
    beqz U8 a0
    la labels_base t0
    ld 0 t0 t0
    add s4 t0 t1
U2:
    ld LABEL_node t1 t2
    beq rel:U9 t2 a0
    beq rel:U8 t0 t1
    li LABEL_size t2
    sub t2 t1 t1
    j U2
U9:
    sub t0 t1 a0
    leave1
U8:
    mv s4 a0
    leave1
", 2)
. cfn('ehpend', "the end of the procedure of row a0 (a1 rows from it): its function's end, or where the next procedure starts if that is before it (a1 1 then, else 0)", "
    ld 8 a0 t0
    slli 32 t0 t1
    srli 32 t1 t1
    srli 32 t0 t2
    la labels_base t3
    ld 0 t3 t3
    add t3 t1 t1
    add t3 t2 t2
    ld LABEL_addr t1 t4
    ld LABEL_end t2 t5
    li 0 t6
D1:
    beqz D9 a1
    ld 8 a0 t1
    bne rel:D2 t1 t0
    addi 64 a0 a0
    addi -1 a1 a1
    j D1
D2:
    slli 32 t1 t1
    srli 32 t1 t1
    add t3 t1 t1
    ld LABEL_addr t1 t1
    bgeu rel:D9 t1 t4
    bltu rel:D9 t1 t5
    mv t1 t5
    li 1 t6
D9:
    mv t5 a0
    mv t6 a1
    ret
", 2)
. cfn('ehaops', "the row of ehabi word a0 (instruction a1: 1 save, 2 pad, 3 cantunwind) at a2: the instruction, then save's registers as a mask (2 bytes), pad's offset (4); a0 past it", "
    enter8
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len s4 s7
    ld NODE_children s4 s8
    sb 0 s5 s6
    addi 1 s6 s6
    li 1 t0
    beq rel:B1 t0 s5
    li 2 t0
    beq rel:B2 t0 s5
    bnez BW s7
    j B9
B1:
    li 0 s9
B3:
    beqz B4 s7
    ld 0 s8 a0
    call ehreg
    li 16 t0
    bgeu rel:BW t0 a0
    li 1 t1
    sll a0 t1 t1
    or t1 s9 s9
    addi 8 s8 s8
    addi -1 s7 s7
    j B3
B4:
    beqz BW s9
    sb 0 s9 s6
    srli 8 s9 t0
    sb 1 t0 s6
    addi 2 s6 s6
    j B9
B2:
    li 1 t0
    bne rel:BW t0 s7
    ld 0 s8 a0
    call ehnum
    sb 0 a0 s6
    srli 8 a0 t0
    sb 1 t0 s6
    srli 16 a0 t0
    sb 2 t0 s6
    srli 24 a0 t0
    sb 3 t0 s6
    addi 4 s6 s6
B9:
    mv s6 a0
    leave8
BW:
    j wrong_args
", 2)
. cfn('ehachunk', "an unwinding instruction a0 (its bytes' count, then its bytes from bit 8 on) added to eh_abadd (eh_abk of them, 32 at most), in GNU as's order", "
    la eh_abk t0
    ld 0 t0 t1
    li 32 t2
    bgeu rel:K9 t2 t1
    slli 3 t1 t3
    la eh_abadd t4
    add t4 t3 t3
    sd 0 a0 t3
    addi 1 t1 t1
    sd 0 t1 t0
K9:
    ret
", 2)
. cfn('ehaadj', "the instructions that add a0 to vsp (GNU as's add_unwind_adjustsp), added (ehachunk)", "
    enter3
    mv a0 s4
    li 513 t0
    bge rel:J1 t0 s4
    li 257 t0
    bge rel:J2 t0 s4
    bltz J4 s4
    beqz J0 s4
    addi -4 s4 t1
    srli 2 t1 t1
    slli 8 t1 a0
    addi 1 a0 a0
    call ehachunk
J0:
    leave3
J1:
    addi -516 s4 s5
    srli 2 s5 s5
    li 0 s6
    bnez J1b s5
    li 1 a0
    call ehachunk
J1b:
    beqz J1c s5
    andi 127 s5 t1
    srli 7 s5 s5
    beqz J1d s5
    addi 128 t1 t1
J1d:
    la eh_abtmp t0
    add s6 t0 t2
    sb 0 t1 t2
    addi 1 s6 s6
    j J1b
J1c:
    beqz J1e s6
    addi -1 s6 s6
    la eh_abtmp t0
    add s6 t0 t2
    lbu 0 t2 t1
    slli 8 t1 a0
    addi 1 a0 a0
    call ehachunk
    j J1c
J1e:
    li32 45569 a0
    call ehachunk
    leave3
J2:
    li32 16129 a0
    call ehachunk
    addi -260 s4 t1
    srli 2 t1 t1
    slli 8 t1 a0
    addi 1 a0 a0
    call ehachunk
    leave3
J4:
    neg s4 s4
J4a:
    li 257 t0
    blt rel:J4b t0 s4
    li32 32513 a0
    call ehachunk
    addi -256 s4 s4
    j J4a
J4b:
    addi -4 s4 t1
    srli 2 t1 t1
    addi 64 t1 t1
    slli 8 t1 a0
    addi 1 a0 a0
    call ehachunk
    leave3
", 2)
. cfn('ehabops', "the rows from a0 (a1 left) of its procedure, a0 their count: its EHABI unwinding instructions as GNU as makes them of .save, .pad and .cantunwind (pad's offset pending until a save or the end, each save's instructions after it, all of them last first), in eh_abuf (48 at most), their count in eh_abn (-1 cantunwind)", "
    enter8
    mv a0 s4
    mv a1 s5
    ld 8 s4 s6
    li 0 s7
    li 0 s9
    li 0 s10
    la eh_abk t0
    sd 0 zero t0
G1:
    beqz G7 s5
    ld 8 s4 t0
    bne rel:G7 t0 s6
    lbu 24 s4 t1
    li 1 t2
    beq rel:G2 t2 t1
    li 2 t2
    beq rel:G3 t2 t1
    li 1 s9
    j G6
G3:
    lbu 25 s4 t0
    lbu 26 s4 t1
    slli 8 t1 t1
    or t1 t0 t0
    lbu 27 s4 t1
    slli 16 t1 t1
    or t1 t0 t0
    lbu 28 s4 t1
    slli 24 t1 t1
    or t1 t0 t0
    slli 32 t0 t0
    srai 32 t0 t0
    add t0 s7 s7
    j G6
G2:
    mv s7 a0
    li 0 s7
    call ehaadj
    lbu 25 s4 s8
    lbu 26 s4 t0
    slli 8 t0 t0
    or t0 s8 s8
    li32 65520 t0
    and t0 s8 t1
    beqz G4 t1
    li 0 s11
G2a:
    li 8 t0
    bgeu rel:G2b t0 s11
    addi 4 s11 t1
    li 1 t2
    sll t1 t2 t2
    and t2 s8 t2
    beqz G2b t2
    addi 1 s11 s11
    j G2a
G2b:
    beqz G2c s11
    li32 65520 t0
    sll s11 t0 t0
    and s8 t0 t0
    li32 49136 t1
    and t1 t0 t0
    bnez G2c t0
    li 160 t1
    li32 16384 t2
    and s8 t2 t2
    beqz G2d t2
    li 168 t1
G2d:
    addi -1 s11 t2
    or t2 t1 t1
    slli 8 t1 a0
    addi 1 a0 a0
    call ehachunk
    j G4
G2c:
    srli 4 s8 t1
    li32 4095 t2
    and t2 t1 t1
    li32 32768 t2
    or t2 t1 t1
    srli 8 t1 t2
    andi 255 t1 t3
    slli 8 t2 a0
    slli 16 t3 t3
    or t3 a0 a0
    addi 2 a0 a0
    call ehachunk
G4:
    andi 15 s8 t1
    beqz G6 t1
    slli 16 t1 a0
    li32 45312 t2
    or t2 a0 a0
    addi 2 a0 a0
    call ehachunk
G6:
    addi 64 s4 s4
    addi -1 s5 s5
    addi 1 s10 s10
    j G1
G7:
    mv s7 a0
    call ehaadj
    la eh_abk t0
    ld 0 t0 t1
    la eh_abadd t2
    la eh_abuf t3
    li 0 t4
G8:
    beqz G9 t1
    addi -1 t1 t1
    slli 3 t1 t5
    add t2 t5 t5
    ld 0 t5 t5
    andi 255 t5 t6
    srli 8 t5 t5
G8a:
    beqz G8 t6
    li 48 a1
    bgeu rel:G8b a1 t4
    add t3 t4 a1
    sb 0 t5 a1
    addi 1 t4 t4
G8b:
    srli 8 t5 t5
    addi -1 t6 t6
    j G8a
G9:
    beqz G9a s9
    li -1 t4
G9a:
    la eh_abn t0
    sd 0 t4 t0
    mv s10 a0
    leave8
", 2)
. cfn('ehxtab', "the .ARM.extab entry of eh_abuf's eh_abn instructions at a0 (personality 1: its index, the words after the first, the instructions, finish to a word, a word 0), as GNU as's; a0 its bytes", "
    enter5
    mv a0 s4
    call dptr
    la dbg_st t0
    sd 80 a0 t0
    la eh_abn t0
    ld 0 t0 s5
    addi 1 s5 s6
    srli 2 s6 s6
    li 0 s7
    slli 2 s6 s8
    addi 4 s8 s8
T1:
    bgeu rel:T8 s8 s7
    li 0 a0
    li 4 t3
T2:
    beqz T3 t3
    slli 8 a0 a0
    li 129 t4
    beqz T2a s7
    mv s6 t4
    li 1 t5
    beq rel:T2a t5 s7
    addi -2 s7 t5
    li 176 t4
    bgeu rel:T2a s5 t5
    la eh_abuf t6
    add t5 t6 t6
    lbu 0 t6 t4
T2a:
    or t4 a0 a0
    addi 1 s7 s7
    addi -1 t3 t3
    j T2
T3:
    call dput4
    j T1
T8:
    li 0 a0
    call dput4
    addi 4 s8 a0
    leave5
", 2)
. cfn('ehexidx', "on arm, dbgeh's entries of .ARM.exidx for the asm functions' procedures (a0 the C functions', whose room is before theirs): each where it starts, its word the instructions (3 at most, personality 0) or the prel31 of its .ARM.extab entry (ehxtab, after .ARM.exidx's room) or EXIDX_CANTUNWIND, an EXIDX_CANTUNWIND entry where it ends if no other procedure starts there; the table then sorted (ehxsort)", "
    enter8
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    bne rel:X9 t1 t0
    la dbg_st s4
    ld 200 s4 t0
    slli 4 a0 t1
    add t1 t0 t0
    la eh_csnap t2
    ld 0 t2 t3
    slli 4 t3 t3
    add t3 t0 s9
    ld 16 t2 s6
    la eh_crow s7
X1:
    beqz X8 s6
    mv s7 a0
    mv s6 a1
    call ehpend
    mv a0 s10
    mv a1 s11
    ld 8 s7 t0
    slli 32 t0 t0
    srli 32 t0 t0
    la labels_base t1
    ld 0 t1 t1
    add t1 t0 t0
    ld LABEL_addr t0 s8
    mv s7 a0
    mv s6 a1
    call ehabops
    slli 6 a0 t0
    add t0 s7 s7
    sub a0 s6 s6
    la eh_abn t0
    ld 0 t0 t1
    li 1 s5
    bltz X5 t1
    li 4 t2
    bgeu rel:X3 t2 t1
    li 128 s5
    li 0 t2
X2:
    li 3 t3
    bgeu rel:X5 t3 t2
    slli 8 s5 s5
    li 176 t4
    bgeu rel:X2a t1 t2
    la eh_abuf t5
    add t2 t5 t5
    lbu 0 t5 t4
X2a:
    or t4 s5 s5
    addi 1 t2 t2
    j X2
X3:
    mv s9 a0
    call ehxtab
    mv s9 s5
    add a0 s9 s9
    ld 200 s4 t0
    ld 208 s4 t1
    add t1 t0 t0
    addi 4 t0 t0
    sub t0 s5 s5
    slli 33 s5 s5
    srli 33 s5 s5
X5:
    ld 200 s4 t0
    ld 208 s4 t1
    add t1 t0 a0
    call dptr
    sd 80 a0 s4
    mv s8 a0
    mv s5 a1
    call dexent
    bnez X1 s11
    mv s10 a0
    li 1 a1
    call dexent
    j X1
X8:
    call ehxsort
X9:
    leave8
", 2)
. cfn('ehxsort', "arm: .ARM.exidx's entries (dbg_st 200, 208 bytes) sorted by where they start, of two that start at one place an EXIDX_CANTUNWIND left out; their prel31 words made addresses for it and back", "
    enter8
    la dbg_st s4
    ld 200 s4 s5
    mv s5 a0
    call dptr
    mv a0 s6
    ld 208 s4 s7
    srli 3 s7 s7
    li 0 t0
Q1:
    bgeu rel:Q2 s7 t0
    slli 3 t0 t1
    add s6 t1 t2
    add s5 t1 t3
    ld 0 t2 t4
    slli 33 t4 t5
    srai 33 t5 t5
    add t3 t5 t5
    slli 32 t5 t5
    srli 32 t5 t5
    srli 32 t4 t6
    li 1 a0
    beq rel:Q1a a0 t6
    srli 31 t6 a0
    bnez Q1a a0
    slli 33 t6 t6
    srai 33 t6 t6
    add t3 t6 t6
    addi 4 t6 t6
    slli 32 t6 t6
    srli 32 t6 t6
Q1a:
    slli 32 t6 t6
    or t6 t5 t5
    sd 0 t5 t2
    addi 1 t0 t0
    j Q1
Q2:
    li 1 t0
Q2a:
    bgeu rel:Q3 s7 t0
    slli 3 t0 t1
    add s6 t1 t1
    ld 0 t1 t2
    slli 32 t2 t3
    srli 32 t3 t3
    mv t0 t4
Q2b:
    beqz Q2c t4
    addi -1 t4 t5
    slli 3 t5 t5
    add s6 t5 t5
    ld 0 t5 a0
    slli 32 a0 t6
    srli 32 t6 t6
    bgeu rel:Q2c t6 t3
    sd 8 a0 t5
    addi -1 t4 t4
    j Q2b
Q2c:
    slli 3 t4 t5
    add s6 t5 t5
    sd 0 t2 t5
    addi 1 t0 t0
    j Q2a
Q3:
    li 0 t0
    li 0 t1
Q3a:
    bgeu rel:Q4 s7 t0
    slli 3 t0 t2
    add s6 t2 t2
    ld 0 t2 t3
    beqz Q3c t1
    addi -1 t1 t4
    slli 3 t4 t4
    add s6 t4 t4
    ld 0 t4 t5
    slli 32 t5 t6
    slli 32 t3 a0
    bne rel:Q3c a0 t6
    srli 32 t5 t5
    li 1 a0
    bne rel:Q3b a0 t5
    sd 0 t3 t4
Q3b:
    addi 1 t0 t0
    j Q3a
Q3c:
    slli 3 t1 t4
    add s6 t4 t4
    sd 0 t3 t4
    addi 1 t1 t1
    addi 1 t0 t0
    j Q3a
Q4:
    mv t1 s7
    slli 3 s7 t0
    sd 208 t0 s4
    li 0 t0
Q4a:
    bgeu rel:Q9 s7 t0
    slli 3 t0 t1
    add s6 t1 t2
    add s5 t1 t3
    ld 0 t2 t4
    slli 32 t4 t5
    srli 32 t5 t5
    sub t3 t5 t5
    slli 33 t5 t5
    srli 33 t5 t5
    srli 32 t4 t6
    li 1 a0
    beq rel:Q4b a0 t6
    srli 31 t6 a0
    bnez Q4b a0
    addi 4 t3 a0
    sub a0 t6 t6
    slli 33 t6 t6
    srli 33 t6 t6
Q4b:
    slli 32 t6 t6
    or t6 t5 t5
    sd 0 t5 t2
    addi 1 t0 t0
    j Q4a
Q9:
    leave8
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
my @at = ((map { ["x$_", $_] } 0 .. 30), ['fp', 29], ['lr', 30], ['sp', 31], ['vg', 46], (map { ["d$_", 64 + $_], ["v$_", 64 + $_], ["q$_", 64 + $_] } 0 .. 31));
my $data = '';
$data .= bytes('eh_cfiw', 'the cfi words: their length, their instruction, their text', @wb);
$data .= bytes('eh_regs', 'riscv64: a register name, its DWARF number', regtab(@rvt));
$data .= bytes('eh_regsx', 'x86_64: a register name, its DWARF number', regtab(@xt));
$data .= bytes('eh_regsa', 'aarch64: a register name, its DWARF number', regtab(@at));
my @ab;
my @aw = ('save', 'pad', 'cantunwind');
for my $i (0 .. $#aw) { my $s = "ehabi $aw[$i]"; push @ab, length $s, $i + 1, map { ord } split //, $s }
push @ab, 0;
$data .= bytes('eh_abiw', 'the ehabi words: their length, their instruction, their text', @ab);
my @art = ((map { ["r$_", $_] } 0 .. 15), ['fp', 11], ['ip', 12], ['sp', 13], ['lr', 14], ['pc', 15]);
$data .= bytes('eh_regsr', 'arm: a register name, its number', regtab(@art));
$data .= "  msg_cfi:\n    ascii\n      ttpc: not a cfi or ehabi word:\\x20\n"
    . "  msg_cfin:\n    ascii\n      ttpc: a cfi word's operand is no number:\\x20\n"
    . "  msg_cfir:\n    ascii\n      ttpc: a cfi word's register is none of the target's:\\x20\n";
once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');
# (the data at the start of layer 2, before its variables and bss: layer 0
# has room for the functions only)
once(\$t, "\n2:\n  comment\n    the variables, then the memory (bss): the trees, the labels, the buffers, the C layer's tables\n",
    "\n2:\n  comment\n    the variables, then the memory (bss): the trees, the labels, the buffers, the C layer's tables\n$code2$data", 'the start of layer 2');
save();
