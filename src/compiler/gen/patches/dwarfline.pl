# dwarfline.pl: -g, D3 (a): a line table of the ff tree. Each tree ttpc
# reads (tree) is recorded with its path and the range of its nodes
# (parse_node lays them out in their order, NODE_size apart, the root
# first), so a node's line in the tree's text (fftext.pl txt, one node per
# line, the root's first child on line 1) is (node - root) / NODE_size.
# Each pass records rows (dbg_lines: the address, the node) where code
# starts: an instruction or macro call of the program itself (code_call
# with no frame: not one in a function's body), a C statement (cc/stmt)
# and a C function's prologue (cc/frame); one of a node of no tree (made by
# the compiler, by emit) is left out, and a row at the address of the one
# before it takes its place (a declaration, a comment make no code).
# dtail writes past .strtab, as DWARF 5: .debug_abbrev, .debug_info (one
# compile unit, from the lowest row of the code to its end; its name the
# file of the lowest row) and .debug_line (the files: each tree's path with
# .txt, the rows by address). Without -g nothing is recorded.
#
# D3 (b), the C view: a statement line / file / number or line / number
# (C's #line N "file", #line N: c2ff writes them from clang's places)
# makes no code, as a comment (cc/stmt takes a line with 1 or 2 children
# so; a line of none stays a name); with -g it sets the C place (dbg_cst:
# the file, an index of dbg_cfiles + 1, and the line) of the rows that
# follow in its function: a row then has the C file and line, and
# .debug_line names the C files after the trees. A C function starts with
# none (cc/frame), or with the place of the first line of its body that
# names a file, which its prologue's row takes too; it ends with none.
# Run on ttpc.ff after debug.pl, ehframe.pl and setdebug.pl.
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
    my @l;
    while (length $text > 240) { $text =~ s/^(.{1,240}) //s or die "bytes: $name\n"; push @l, $1 }
    push @l, $text;
    "  align\n    8\n  $name:\n    comment\n" . join('', map { "      $_\n" } @l) . $s;
}
sub str { map { ord } split //, $_[0] }

my $MAXROWS = 262144;

# ---- the variables
once(\$t, "  dbg_shs:\n    reserve\n      8192\n",
    "  dbg_shs:\n    reserve\n      8192\n  dbg_lines:\n    reserve\n      " . (8 + $MAXROWS * 32) . "\n  dbg_trees:\n    reserve\n      " . (8 + 256 * 24) . "\n  dbg_cfiles:\n    reserve\n      " . (8 + 1024 * 16) . "\n  dbg_cst:\n    reserve\n      16\n", 'dbg_shs');

# ---- each pass starts with no rows
edit(\$t, 'compile_page', "      la\n        ct_placed\n        t0\n", asm(6, "
    la dbg_lines t0
    sd 0 zero t0
") . "      la\n        ct_placed\n        t0\n");

# ---- each tree read: its path and nodes
edit(\$t, 'tree', "      sd\n        8\n        a0\n        s5\n      leave3\n", "      sd\n        8\n        a0\n        s5\n" . asm(6, "
    mv s4 a1
    call dbgtree
") . "      leave3\n");

# ---- the rows
edit(\$t, 'code_call', "    mv\n      a1\n      s5\n    call\n      is_comment\n", "    mv\n      a1\n      s5\n" . asm(4, "call dbgrowc") . "    call\n      is_comment\n");
edit(\$t, 'cc/stmt', "        call\n          peek\n        mv\n          a0\n          s4\n",
    "        call\n          peek\n        mv\n          a0\n          s4\n" . asm(8, "
    call dbgstmt
    li 1 t0
    beq rel:L15 t0 a1
"));
edit(\$t, 'cc/frame', "        call\n          dbgfn0\n", asm(8, "call dbgrowf") . "        call\n          dbgfn0\n",
    "        call\n          dbgfn1\n", "        call\n          dbgfn1\n" . asm(8, "call dbgcend"));

# ---- dtail: the debug sections after .strtab, before .shstrtab
edit(\$t, 'dtail', "      ld\n        152\n        s4\n        t0\n      sd\n        80\n        t0\n        s4\n",
    "      ld\n        152\n        s4\n        t0\n      sd\n        80\n        t0\n        s4\n" . asm(6, "call dlines"));

my $code = '';

$code .= cfn('dbgtree', "a tree read: its root a0 (kept), its path a1, its nodes up to BS_nodes, an entry of dbg_trees (24 bytes: path, root, end); the entries of nodes it reuses (a workspace's) go", "
    la bstate t0
    ld BS_nodes t0 a2
    la dbg_trees t0
    ld 0 t0 t1
    T1:
    beqz T2 t1
    addi -1 t1 t3
    li 24 t4
    mul t4 t3 t4
    add t4 t0 t4
    ld 16 t4 a3
    bltu rel:T2 a0 a3
    mv t3 t1
    j T1
    T2:
    beqz T3 t1
    addi -1 t1 t3
    li 24 t4
    mul t4 t3 t4
    add t4 t0 t4
    ld 24 t4 a3
    bgeu rel:T3 a3 a0
    sd 24 a0 t4
    T3:
    li 255 t3
    bgeu rel:T9 t3 t1
    li 24 t4
    mul t4 t1 t4
    add t4 t0 t4
    sd 8 a1 t4
    sd 16 a0 t4
    sd 24 a2 t4
    addi 1 t1 t1
    sd 0 t1 t0
    T9:
    ret
", 2);

$code .= cfn('dbgrowc', "code_call's node a0 with its frame a1: a row if a1 is none (the program's own call, not one in a function's body)", "
    bnez R9 a1
    j dbgrow
    R9:
    ret
", 2);

$code .= cfn('dbgrow', "with -g, outside the JIT: code at cur_pc comes from the node a0 (kept, a1 too), a row of dbg_lines (32 bytes: address, node, its bit 0 set by dbgrowf, the C file and line of dbg_cst) if a0 is in a tree; the row before it if that is at cur_pc too", "
    li 0 t5
    j dbgrowx
", 2);

$code .= cfn('dbgrowx', "dbgrow's work, t5 the bit 0 of its row", "
    la dbg_on t0
    ld 0 t0 t0
    beqz R9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez R9 t0
    la dbg_trees t0
    ld 0 t0 t1
    R1:
    beqz R9 t1
    addi -1 t1 t1
    li 24 t2
    mul t2 t1 t2
    add t2 t0 t2
    ld 16 t2 t3
    bltu rel:R1 t3 a0
    ld 24 t2 t4
    bgeu rel:R1 t4 a0
    or t5 a0 t5
    la cur_pc t3
    ld 0 t3 t3
    la dbg_lines t0
    ld 0 t0 t1
    beqz R3 t1
    addi -1 t1 t2
    slli 5 t2 t2
    add t2 t0 t2
    ld 8 t2 t4
    bne rel:R3 t4 t3
    j R4
    R3:
    li32 $MAXROWS t2
    bgeu rel:R9 t2 t1
    slli 5 t1 t2
    add t2 t0 t2
    sd 8 t3 t2
    addi 1 t1 t1
    sd 0 t1 t0
    R4:
    sd 16 t5 t2
    la dbg_cst t4
    ld 0 t4 t6
    sd 24 t6 t2
    ld 8 t4 t6
    sd 32 t6 t2
    R9:
    ret
", 2);

$code .= cfn('dbgrowf', "dbgrow for the C function a0 (kept, a1 to a7 too), its prologue at cur_pc: its row's bit 0 says so (the next row is where the prologue ends); the C place none, or the first line of the function's children if it names a file", "
    enter3
    addi -64 sp sp
    sd 0 a1 sp
    sd 8 a2 sp
    sd 16 a3 sp
    sd 24 a4 sp
    sd 32 a5 sp
    sd 40 a6 sp
    sd 48 a7 sp
    mv a0 s4
    la dbg_cst t0
    sd 0 zero t0
    sd 8 zero t0
    lbu NODE_children_len a0 s5
    ld NODE_children a0 s6
    F1:
    beqz F3 s5
    ld 0 s6 a0
    addi 8 s6 s6
    addi -1 s5 s5
    lbu NODE_content_len a0 t0
    li 4 t1
    bne rel:F1 t1 t0
    lbu NODE_children_len a0 t0
    beqz F1 t0
    li 3 t1
    bgeu rel:F1 t1 t0
    ld NODE_content a0 t0
    lbu 0 t0 t1
    li 108 t2
    bne rel:F1 t2 t1
    lbu 1 t0 t1
    li 105 t2
    bne rel:F1 t2 t1
    lbu 2 t0 t1
    li 110 t2
    bne rel:F1 t2 t1
    lbu 3 t0 t1
    li 101 t2
    bne rel:F1 t2 t1
    lbu NODE_children_len a0 t0
    li 2 t1
    bne rel:F3 t1 t0
    call dbgcline
    F3:
    mv s4 a0
    li 1 t5
    call dbgrowx
    ld 0 sp a1
    ld 8 sp a2
    ld 16 sp a3
    ld 24 sp a4
    ld 32 sp a5
    ld 40 sp a6
    ld 48 sp a7
    addi 64 sp sp
    leave3
", 2);

$code .= cfn('dbgstmt', "cc/stmt's node a0 (kept): a1 1 if it is a line of 1 or 2 children (with -g its place is the C place, dbgcline), which makes no code; else a1 0 and a row (dbgrow)", "
    li 0 a1
    beqz S9 a0
    lbu NODE_content_len a0 t0
    li 4 t1
    bne rel:S8 t1 t0
    lbu NODE_children_len a0 t0
    beqz S8 t0
    li 3 t1
    bgeu rel:S8 t1 t0
    ld NODE_content a0 t0
    lbu 0 t0 t1
    li 108 t2
    bne rel:S8 t2 t1
    lbu 1 t0 t1
    li 105 t2
    bne rel:S8 t2 t1
    lbu 2 t0 t1
    li 110 t2
    bne rel:S8 t2 t1
    lbu 3 t0 t1
    li 101 t2
    bne rel:S8 t2 t1
    li 1 a1
    j dbgcline
    S8:
    j dbgrow
    S9:
    ret
", 2);

$code .= cfn('dbgcline', "with -g, outside the JIT: the line a0 (kept, a1 too) gives the C place (dbg_cst): its file (one of dbg_cfiles, added if new) if it has 2 children, its number; one without a file where there is none is left out", "
    la dbg_on t0
    ld 0 t0 t0
    beqz C9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez C9 t0
    ld NODE_children a0 t0
    lbu NODE_children_len a0 t1
    li 2 t2
    bne rel:C1 t2 t1
    ld 0 t0 a2
    ld 8 t0 a3
    ld NODE_content a2 a4
    lbu NODE_content_len a2 a5
    la dbg_cfiles t3
    ld 0 t3 t4
    li 0 t5
    C2:
    beq rel:C5 t5 t4
    slli 4 t5 t6
    add t6 t3 t6
    ld 16 t6 t2
    bne rel:C4 t2 a5
    ld 8 t6 t2
    li 0 a6
    C3:
    beq rel:C6 a6 a5
    add a6 t2 a7
    lbu 0 a7 a7
    add a6 a4 t1
    lbu 0 t1 t1
    bne rel:C4 t1 a7
    addi 1 a6 a6
    j C3
    C4:
    addi 1 t5 t5
    j C2
    C5:
    li 1023 t2
    bgeu rel:C9 t2 t4
    slli 4 t4 t6
    add t6 t3 t6
    sd 8 a4 t6
    sd 16 a5 t6
    addi 1 t4 t4
    sd 0 t4 t3
    C6:
    addi 1 t5 t5
    la dbg_cst t6
    sd 0 t5 t6
    j C7
    C1:
    la dbg_cst t6
    ld 0 t6 t2
    beqz C9 t2
    ld 0 t0 a3
    C7:
    ld NODE_content a3 a4
    lbu NODE_content_len a3 a5
    li 0 t1
    li 0 t2
    C8:
    beq rel:C10 t2 a5
    add t2 a4 t3
    lbu 0 t3 t3
    addi -48 t3 t3
    li 10 t4
    bgeu rel:C10 t4 t3
    mul t4 t1 t1
    add t3 t1 t1
    addi 1 t2 t2
    j C8
    C10:
    la dbg_cst t6
    sd 8 t1 t6
    C9:
    ret
", 2);

$code .= cfn('dbgcend', "a C function ends: the C place none", "
    la dbg_cst t0
    sd 0 zero t0
    sd 8 zero t0
    ret
", 2);

$code .= cfn('dnline', "the tree of the node a0 (bit 0 left out) (its index in dbg_trees, a0; -1 if none) and its line in the tree's text (a1)", "
    andi -2 a0 a0
    la dbg_trees t0
    ld 0 t0 t1
    L1:
    beqz L8 t1
    addi -1 t1 t1
    li 24 t2
    mul t2 t1 t2
    add t2 t0 t2
    ld 16 t2 t3
    bltu rel:L1 t3 a0
    ld 24 t2 t4
    bgeu rel:L1 t4 a0
    sub t3 a0 a1
    srli 6 a1 a1
    mv t1 a0
    ret
    L8:
    li -1 a0
    ret
", 2);

$code .= cfn('dlsort', "dbg_lines' rows by address (an insertion sort: they come nearly in order)", "
    la dbg_lines t0
    ld 0 t0 t1
    addi 8 t0 t0
    li 1 t2
    O1:
    bgeu rel:O9 t1 t2
    slli 5 t2 t3
    add t3 t0 t3
    ld 0 t3 a2
    ld 8 t3 a3
    ld 16 t3 a6
    ld 24 t3 a7
    O2:
    beq rel:O3 t0 t3
    ld -32 t3 a4
    bgeu rel:O3 a4 a2
    sd 0 a4 t3
    ld -24 t3 a5
    sd 8 a5 t3
    ld -16 t3 a5
    sd 16 a5 t3
    ld -8 t3 a5
    sd 24 a5 t3
    addi -32 t3 t3
    j O2
    O3:
    sd 0 a2 t3
    sd 8 a3 t3
    sd 16 a6 t3
    sd 24 a7 t3
    addi 1 t2 t2
    j O1
    O9:
    ret
", 2);

$code .= cfn('dlkeep', "of dbg_lines' rows (by address) only those of the code stay (dbg_st 40 to 48): not the frame's headers and data", "
    la dbg_st t0
    ld 40 t0 a2
    ld 48 t0 a3
    la dbg_lines t0
    ld 0 t0 t1
    addi 8 t0 t2
    mv t2 t3
    K1:
    beqz K3 t1
    addi -1 t1 t1
    ld 0 t2 a4
    ld 8 t2 a5
    ld 16 t2 a6
    ld 24 t2 a7
    addi 32 t2 t2
    bltu rel:K1 a2 a4
    bgeu rel:K1 a3 a4
    sd 0 a4 t3
    sd 8 a5 t3
    sd 16 a6 t3
    sd 24 a7 t3
    addi 32 t3 t3
    j K1
    K3:
    addi 8 t0 t2
    sub t2 t3 t3
    srli 5 t3 t3
    sd 0 t3 t0
    ret
", 2);

$code .= cfn('dputu', "a0 as an unsigned LEB128 at the cursor", "
    enter1
    mv a0 s4
    U1:
    andi 127 s4 a0
    srli 7 s4 s4
    beqz U2 s4
    li 128 t0
    or t0 a0 a0
    U2:
    call dput1
    bnez U1 s4
    leave1
", 2);

$code .= cfn('dputs', "a0 as a signed LEB128 at the cursor", "
    enter1
    mv a0 s4
    S1:
    andi 127 s4 a0
    srai 7 s4 s4
    andi 64 a0 t1
    bnez S3 t1
    beqz S5 s4
    j S4
    S3:
    li -1 t2
    beq rel:S5 t2 s4
    S4:
    li 128 t0
    or t0 a0 a0
    call dput1
    j S1
    S5:
    call dput1
    leave1
", 2);

$code .= cfn('dfname', "the file of the tree a0 (dbg_trees) at the cursor: its path, .txt and a NUL", "
    enter1
    la dbg_trees t0
    li 24 t1
    mul t1 a0 t1
    add t1 t0 t1
    ld 8 t1 s4
    mv s4 t0
    F1:
    lbu 0 t0 t1
    beqz F2 t1
    addi 1 t0 t0
    j F1
    F2:
    sub s4 t0 a1
    mv s4 a0
    call dcopy
    la dbg_txt a0
    li 5 a1
    call dcopy
    leave1
", 2);

$code .= cfn('dfileof', "the name of file a0 of the line table (1 up: the trees, then the C files) at the cursor, and a NUL", "
    enter1
    la dbg_trees t0
    ld 0 t0 t0
    bltu rel:E1 a0 t0
    addi -1 a0 a0
    call dfname
    leave1
    E1:
    sub t0 a0 a0
    addi -1 a0 a0
    slli 4 a0 a0
    la dbg_cfiles t0
    add a0 t0 t0
    ld 16 t0 a1
    ld 8 t0 a0
    call dcopy
    li 0 a0
    call dput1
    leave1
", 2);

$code .= cfn('dnsec', "a section of no memory from a2 (in outbuf) to the cursor, named a0 a1 (its bytes, its length)", "
    enter1
    mv a2 s4
    call dshsadd
    la dbg_st t0
    ld 80 t0 a4
    sub s4 a4 a4
    li 1 a1
    li 0 a2
    li 0 a3
    li 1 a5
    call dsec
    la outbuf t0
    sub t0 s4 t0
    sd 32 t0 a1
    leave1
", 2);

$code .= cfn('dlines', "with rows (dbg_lines), at the cursor: .debug_abbrev, .debug_info and .debug_line (DWARF 5); dbg_st 256 the file of the compile unit, 288 296 304 the address, file and line of the line program, 312 the end of the code, 320 1 once a row is written, 328 a row's line, 336 1 if the row before starts a prologue (this one gets prologue_end), 344 this row's bit 0, 352 360 its C file and line", "
    enter8
    la dbg_lines s4
    ld 0 s4 t0
    beqz X9 t0
    call dlsort
    call dlkeep
    ld 0 s4 t0
    beqz X9 t0
    la dbg_st s5
    ld 24 s4 t2
    beqz X2 t2
    la dbg_trees t0
    ld 0 t0 t0
    add t0 t2 a0
    j X3
    X2:
    ld 16 s4 a0
    call dnline
    addi 1 a0 a0
    X3:
    sd 256 a0 s5
    ld 48 s5 t2
    sd 312 t2 s5
    sd 320 zero s5
    sd 336 zero s5

    ld 80 s5 s6
    la dbg_abbrev a0
    li 20 a1
    call dcopy
    la dbg_nabbrev a0
    li 13 a1
    mv s6 a2
    call dnsec

    ld 80 s5 s6
    li 0 a0
    call dput4
    li 5 a0
    call dput2
    li 1 a0
    call dput1
    ld 8 s5 a0
    call dput1
    li 0 a0
    call dput4
    li 1 a0
    call dput1
    la dbg_prod a0
    li 5 a1
    call dcopy
    li 29 a0
    call dput2
    ld 256 s5 a0
    call dfileof
    la dbg_dot a0
    li 2 a1
    call dcopy
    ld 8 s4 a0
    call dputa
    ld 312 s5 a0
    ld 8 s4 t0
    sub t0 a0 a0
    call dput4
    li 0 a0
    call dput4
    ld 80 s5 t0
    sub s6 t0 a2
    addi -4 a2 a2
    mv s6 a0
    li 4 a1
    call dwrn
    la dbg_ninfo a0
    li 11 a1
    mv s6 a2
    call dnsec

    ld 80 s5 s6
    li 0 a0
    call dput4
    li 5 a0
    call dput2
    ld 8 s5 a0
    call dput1
    li 0 a0
    call dput1
    li 0 a0
    call dput4
    ld 80 s5 s7
    la dbg_lhead a0
    li 29 a1
    call dcopy
    la dbg_trees t0
    ld 0 t0 a0
    la dbg_cfiles t0
    ld 0 t0 t0
    add t0 a0 a0
    addi 1 a0 a0
    call dputu
    ld 256 s5 a0
    call dfileof
    li 0 a0
    call dputu
    li 1 s8
    F1:
    la dbg_trees t0
    ld 0 t0 t0
    la dbg_cfiles t1
    ld 0 t1 t1
    add t1 t0 t0
    bltu rel:F2 s8 t0
    mv s8 a0
    call dfileof
    li 0 a0
    call dputu
    addi 1 s8 s8
    j F1
    F2:
    ld 80 s5 t0
    sub s7 t0 a2
    addi 8 s6 a0
    li 4 a1
    call dwrn
    li 0 a0
    call dput1
    ld 8 s5 a0
    addi 1 a0 a0
    call dput1
    li 2 a0
    call dput1
    ld 8 s4 a0
    call dputa
    ld 8 s4 t0
    sd 288 t0 s5
    li 1 t0
    sd 296 t0 s5
    sd 304 t0 s5
    li 0 s8
    G1:
    ld 0 s4 t0
    bgeu rel:G5 t0 s8
    slli 5 s8 t0
    add t0 s4 t0
    ld 8 t0 s7
    ld 16 t0 a0
    ld 24 t0 t2
    sd 352 t2 s5
    ld 32 t0 t2
    sd 360 t2 s5
    andi 1 a0 t1
    sd 344 t1 s5
    addi 1 s8 s8
    ld 320 s5 t1
    beqz G2 t1
    ld 288 s5 t1
    beq rel:G1 t1 s7
    G2:
    ld 352 s5 t2
    beqz GF t2
    la dbg_trees t0
    ld 0 t0 t0
    add t0 t2 s9
    ld 360 s5 a1
    j GL
    GF:
    call dnline
    blt rel:G1 zero a0
    addi 1 a0 s9
    GL:
    sd 328 a1 s5
    ld 296 s5 t0
    beq rel:G3 t0 s9
    li 4 a0
    call dput1
    mv s9 a0
    call dputu
    sd 296 s9 s5
    G3:
    ld 328 s5 t0
    ld 304 s5 t1
    beq rel:G4 t1 t0
    li 3 a0
    call dput1
    ld 328 s5 t0
    ld 304 s5 t1
    sub t1 t0 a0
    call dputs
    ld 328 s5 t0
    sd 304 t0 s5
    G4:
    ld 288 s5 t0
    beq rel:G6 t0 s7
    li 2 a0
    call dput1
    ld 288 s5 t0
    sub t0 s7 a0
    call dputu
    sd 288 s7 s5
    G6:
    ld 336 s5 t0
    beqz G7 t0
    li 10 a0
    call dput1
    G7:
    ld 344 s5 t0
    sd 336 t0 s5
    li 1 a0
    call dput1
    li 1 t0
    sd 320 t0 s5
    j G1
    G5:
    li 2 a0
    call dput1
    ld 312 s5 t0
    ld 288 s5 t1
    sub t1 t0 a0
    call dputu
    li 0 a0
    call dput1
    li 1 a0
    call dput1
    li 1 a0
    call dput1
    ld 80 s5 t0
    sub s6 t0 a2
    addi -4 a2 a2
    mv s6 a0
    li 4 a1
    call dwrn
    la dbg_nline a0
    li 11 a1
    mv s6 a2
    call dnsec
    X9:
    leave8
", 2);

# ---- the constant data
$code .= bytes('dbg_abbrev', '.debug_abbrev: 1, a compile unit of no children: producer string, language data2, name string, comp_dir string, low_pc addr, high_pc data4, stmt_list sec_offset',
    1, 0x11, 0, 0x25, 0x08, 0x13, 0x05, 0x03, 0x08, 0x1b, 0x08, 0x11, 0x01, 0x12, 0x06, 0x10, 0x17, 0, 0, 0);
$code .= bytes('dbg_lhead', ".debug_line's header past header_length up to its files: instructions of 1 byte, 1 op, is_stmt, line_base -5, line_range 14, opcode_base 13 and the standard opcodes' lengths, the directories (path string): ., the files' format (path string, directory udata)",
    1, 1, 1, 0xfb, 14, 13, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0x08, 1, str('.'), 0, 2, 1, 0x08, 2, 0x0f);
$code .= bytes('dbg_nabbrev', 'the names of the sections and the strings of the compile unit', str('.debug_abbrev'));
$code .= bytes('dbg_ninfo', '.debug_info', str('.debug_info'));
$code .= bytes('dbg_nline', '.debug_line', str('.debug_line'));
$code .= bytes('dbg_prod', 'ttpc', str("ttpc\0"));
$code .= bytes('dbg_dot', '.', str(".\0"));
$code .= bytes('dbg_txt', '.txt', str(".txt\0"));

once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');
save();
