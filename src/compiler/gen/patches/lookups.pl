# lookups.pl — ttpc's costly lookups through hash indexes, with the same
# answers as the walks they replace (lane lookups, 2026-10-21). Measured on
# the glibc milestone programs (x86_64 stage2, a ptrace sampler over its
# call stack): a fifth to a quarter of the time went into struct, which
# walked all of cc_types for the struct type of a node; then enumlib's
# walk over every enum of the library for a name that is no enum constant,
# and label_entry's walk over the labels for a node.
#
# The tables live behind lookcache's earlier tables (its reserve grows),
# at LX = lookcache + 7930072:
#   LX+0   the labels the label index holds: labels_base, labels_end
#   LX+16  the label index's generation (its entries carry it)
#   LX+24  the enum index's generation: lookcache's 112 when it holds the
#          enums of enumlib's list, else 0
#   LX+32  the enum index's count of names
#   LX+64  struct's index: 65536 of (node, type), 16 bytes each
#   SI_END the enum index: 16384 of (node of the constant, generation,
#          the enum's place in enumlib's list), 32 bytes each
#   then   the label index: 262144 of (node, generation, entry), 32 each
#   then   find_fn's front cache: 65536 of (the name's address, its
#          length and range, the range's end, the generation, the
#          answer), 64 bytes each
#
# struct: an entry is believed only when its type is still a struct type of
# that node below CC_types: only struct makes struct types, after a walk
# that found none, so there is at most one, and a hit is what the walk
# finds. A miss walks as before and fills the entry.
our $t; do "$ENV{PATCHLIB}" or die $@;

my $LX = 7930072;
my $SI = $LX + 64;                 # struct index, 1 MiB
my $EI = $SI + 65536 * 16;         # enum index, 512 KiB
my $LI = $EI + 16384 * 32;         # label index, 8 MiB
my $FF = $LI + 262144 * 32;       # find_fn's front cache, 4 MiB
my $END = $FF + 65536 * 64;

# lookcache grows by the new tables
once(\$t, "  lookcache:\n    reserve\n      7930072\n", "  lookcache:\n    reserve\n      $END\n", 'lookcache reserve');

# ---- struct ---------------------------------------------------------------
{
    my ($from, $to) = find(\$t, 'struct');
    substr($t, $from, $to - $from) = fn('struct', <<"END", 6);
        enter1
        mv a0 s4
        call SX
        ld 0 a0 t0
        bne rel:S1 s4 t0
        ld 8 a0 t0
        la cc_types t1
        bltu rel:S1 t1 t0
        la ccs t1
        ld CC_types t1 t1
        bgeu rel:S1 t1 t0
        ld TY_kind t0 t2
        li TY_STRUCT t3
        bne rel:S1 t3 t2
        ld TY_base t0 t2
        bne rel:S1 s4 t2
        mv t0 a0
        j L9
        S1:
        la cc_types t0
        la ccs t1
        ld CC_types t1 t1
        L1:
        bgeu rel:L2 t1 t0
        ld TY_kind t0 t2
        li TY_STRUCT t3
        bne rel:L3 t3 t2
        ld TY_base t0 t2
        bne rel:L3 s4 t2
        mv t0 t3
        mv s4 a0
        call SX
        sd 0 s4 a0
        sd 8 t3 a0
        mv t3 a0
        j L9
        L3:
        addi TY_sz t0 t0
        j L1
        L2:
        mv s4 a1
        li TY_STRUCT a0
        li 0 a2
        call newtype
        mv a0 s4
        ld TY_base s4 a0
        call SX
        ld TY_base s4 t0
        sd 0 t0 a0
        sd 8 s4 a0
        ld TY_base s4 a0
        li 0 a1
        li -1 a2
        call fields
        sd TY_size a0 s4
        sd TY_align a1 s4
        mv s4 a0
        L9:
        leave1
        SX:
        srli 3 a0 t0
        li32 73244475 t1
        mul t1 t0 t0
        srli 17 t0 t1
        xor t1 t0 t0
        li32 65535 t1
        and t1 t0 t0
        slli 4 t0 t0
        la lookcache t1
        li32 $SI t2
        add t2 t1 t1
        add t1 t0 a0
        ret
END
}


# ---- enumlib --------------------------------------------------------------
# EL's list of the library's enums gets an index of their constants' names
# when it is made (EB): each name with the place of the first enum in the
# list that has it, as enumfind goes through an enum (its children after
# the first, those of an items group in their place). A name looks up its
# enum (EP) and enumfind runs on that one alone; a name no enum has is 0 at
# once. Without the index (the list was full, an items group in an items
# group, more than 12288 names) EL walks the list as before, and so too
# when enumfind would not find the name in the enum the index gave.
my $EIO = $EI;
edit(\$t, 'enumlib',
    "          sd\n            112\n            t0\n            s9\n        E1:\n" =>
    "          sd\n            112\n            t0\n            s9\n          call\n            EB\n        E1:\n",
    "        E0:\n          li\n            0\n            s11\n        E2:\n" =>
    asm(8, <<'END'));
        E0:
        call EP
        li -2 t0
        beq rel:E5 t0 a0
        bltz E8 a0
        slli 3 a0 t0
        add t0 s9 t0
        li32 7340224 t1
        add t1 t0 t0
        ld 0 t0 a0
        mv s4 a1
        mv s5 a2
        call enumfind
        bnez E9 a0
        E5:
        li 0 s11
        E2:
END
{
    my ($from, $to) = find(\$t, 'enumlib');
    substr($t, $to, 0) = asm(8, <<"END");
        EB:
        enter8
        la lookcache s9
        li32 $LX t0
        add t0 s9 s8
        sd 24 zero s8
        sd 32 zero s8
        ld 120 s9 s10
        bltz EX s10
        li 0 s11
        EB1:
        beq rel:EB8 s11 s10
        slli 3 s11 t0
        add t0 s9 t0
        li32 7340224 t1
        add t1 t0 t0
        ld 0 t0 a0
        lbu NODE_children_len a0 s6
        ld NODE_children a0 s7
        beqz EB7 s6
        addi -1 s6 s6
        addi 8 s7 s7
        EB2:
        beqz EB7 s6
        ld 0 s7 a0
        call kwof
        li KW_items t0
        bne rel:EB5 t0 a0
        ld 0 s7 t0
        lbu NODE_children_len t0 s4
        ld NODE_children t0 s5
        EB3:
        beqz EB6 s4
        ld 0 s5 a0
        call kwof
        li KW_items t0
        beq rel:EX t0 a0
        ld 0 s5 a0
        call EI
        beqz EX a0
        addi 8 s5 s5
        addi -1 s4 s4
        j EB3
        EB5:
        ld 0 s7 a0
        call EI
        beqz EX a0
        EB6:
        addi 8 s7 s7
        addi -1 s6 s6
        j EB2
        EB7:
        addi 1 s11 s11
        j EB1
        EB8:
        ld 112 s9 t0
        sd 24 t0 s8
        EX:
        leave8
        EI:
        enter3
        mv a0 s4
        lbu NODE_content_len s4 t0
        li 1 a0
        beqz EI9 t0
        ld NODE_content s4 a0
        addi -1 t0 a1
        call HN
        li32 16383 t0
        and t0 a0 s5
        EI1:
        slli 5 s5 t0
        li32 $EIO t1
        add t1 t0 t0
        add s9 t0 s6
        ld 8 s6 t0
        ld 112 s9 t1
        bne rel:EI5 t1 t0
        ld 0 s6 t0
        ld NODE_content t0 a2
        lbu NODE_content_len t0 a3
        addi -1 a3 a3
        ld NODE_content s4 a0
        lbu NODE_content_len s4 a1
        addi -1 a1 a1
        call streq
        bnez EI8 a0
        addi 1 s5 s5
        li32 16383 t0
        and t0 s5 s5
        j EI1
        EI5:
        ld 32 s8 t0
        li 0 a0
        li32 12288 t1
        bgeu rel:EI9 t1 t0
        addi 1 t0 t0
        sd 32 t0 s8
        sd 0 s4 s6
        ld 112 s9 t0
        sd 8 t0 s6
        sd 16 s11 s6
        EI8:
        li 1 a0
        EI9:
        leave3
        EP:
        enter5
        la lookcache s8
        li32 $LX t1
        add t1 s8 t1
        ld 24 t1 t2
        ld 112 s8 t3
        li -2 a0
        bne rel:EP9 t3 t2
        mv s4 a0
        mv s5 a1
        call HN
        li32 16383 t0
        and t0 a0 s6
        EP1:
        slli 5 s6 t0
        li32 $EIO t1
        add t1 t0 t0
        add s8 t0 s7
        ld 8 s7 t0
        ld 112 s8 t1
        li -1 a0
        bne rel:EP9 t1 t0
        ld 0 s7 t0
        ld NODE_content t0 a2
        lbu NODE_content_len t0 a3
        addi -1 a3 a3
        mv s4 a0
        mv s5 a1
        call streq
        bnez EP8 a0
        addi 1 s6 s6
        li32 16383 t0
        and t0 s6 s6
        j EP1
        EP8:
        ld 16 s7 a0
        EP9:
        leave5
        HN:
        mv a1 t0
        HN1:
        beqz HN2 a1
        lbu 0 a0 t1
        xor t1 t0 t0
        li32 16777619 t1
        mul t1 t0 t0
        addi 1 a0 a0
        addi -1 a1 a1
        j HN1
        HN2:
        srli 15 t0 t1
        xor t1 t0 a0
        ret
END
}

# ---- label_entry ----------------------------------------------------------
# The labels of the main list (labels_base = labels) get an index of their
# nodes as place adds them in pass 1 (LJ), the first entry of a node; it is
# started again when the list is empty again. label_entry believes it while
# it holds exactly the labels from labels_base to labels_end; else (a jit's
# list of its own, the index full) it walks as before.
my $LIO = $LI - $LX;
edit(\$t, 'place',
    "    sd\n      LABEL_addr\n      t4\n      s5\n    j\n      L2\n" =>
    "    sd\n      LABEL_addr\n      t4\n      s5\n    call\n      LJ\n    j\n      L2\n");
{
    my ($from, $to) = find(\$t, 'place');
    substr($t, $to, 0) = asm(4, <<"END");
    LJ:
    la lookcache t0
    li32 $LX t1
    add t1 t0 t0
    la labels_base t1
    ld 0 t1 t1
    ld 0 t0 t2
    bne rel:J5 t2 t1
    ld 8 t0 t2
    bne rel:J5 t2 s5
    J1:
    ld 40 t0 t2
    li32 196608 t3
    bgeu rel:J9 t3 t2
    ld 16 t0 t3
    srli 3 s4 t1
    li32 73244475 t2
    mul t2 t1 t1
    srli 17 t1 t2
    xor t2 t1 t1
    li32 262143 t2
    and t2 t1 t1
    J2:
    slli 5 t1 t2
    li32 $LIO t4
    add t4 t2 t2
    add t0 t2 t2
    ld 8 t2 t4
    bne rel:J3 t3 t4
    ld 0 t2 t4
    beq rel:J8 s4 t4
    addi 1 t1 t1
    li32 262143 t4
    and t4 t1 t1
    j J2
    J3:
    sd 0 s4 t2
    sd 8 t3 t2
    sd 16 s5 t2
    ld 40 t0 t2
    addi 1 t2 t2
    sd 40 t2 t0
    J8:
    addi LABEL_size s5 t1
    sd 8 t1 t0
    ret
    J5:
    la labels t2
    bne rel:J6 t2 t1
    bne rel:J6 t1 s5
    ld 16 t0 t2
    addi 1 t2 t2
    sd 16 t2 t0
    sd 0 t1 t0
    sd 8 s5 t0
    sd 40 zero t0
    j J1
    J6:
    ret
    J9:
    sd 8 zero t0
    ret
END
}
{
    my ($from, $to) = find(\$t, 'label_entry');
    substr($t, $from, $to - $from) = fn('label_entry', <<"END", 2);
    la lookcache t0
    li32 $LX t1
    add t1 t0 t0
    la labels_base t1
    ld 0 t1 t1
    ld 0 t0 t2
    bne rel:W1 t2 t1
    la labels_end t1
    ld 0 t1 t1
    ld 8 t0 t2
    bne rel:W1 t2 t1
    ld 16 t0 t3
    beqz W1 t3
    srli 3 a0 t1
    li32 73244475 t2
    mul t2 t1 t1
    srli 17 t1 t2
    xor t2 t1 t1
    li32 262143 t2
    and t2 t1 t1
    H1:
    slli 5 t1 t2
    li32 $LIO t4
    add t4 t2 t2
    add t0 t2 t2
    ld 8 t2 t4
    bne rel:H0 t3 t4
    ld 0 t2 t4
    beq rel:H2 a0 t4
    addi 1 t1 t1
    li32 262143 t4
    and t4 t1 t1
    j H1
    H2:
    ld 16 t2 a0
    ret
    H0:
    li 0 a0
    ret
    W1:
    la labels_base t0
    ld 0 t0 t0
    la labels_end t1
    ld 0 t1 t1
    L1:
    beq rel:L2 t1 t0
    ld LABEL_node t0 t2
    beq rel:L3 a0 t2
    addi LABEL_size t0 t0
    j L1
    L2:
    li 0 a0
    ret
    L3:
    mv t0 a0
    ret
END
}


# ---- find_fn: a front cache on the name's address ---------------
# Most names come from the text of the trees read (buf up to BS_buf), which
# nothing writes again: there the address and the length are the name, and
# a cache on them (with the range and the generation, as lookcache's key)
# answers without copying and hashing the name's bytes. FP finds the entry
# (t6, 0 if none or another name); FS keeps an answer in it. A name
# elsewhere (prim_text, a node on the stack) goes on as before, and so too
# a name of 32 bytes or more, which lookcache does not keep either.
for my $f (['find_fn', $FF]) {
    my ($name, $off) = @$f;
    edit(\$t, $name,
        "    li\n      0\n      s6\n    li\n      32\n      t0\n" =>
        "    li\n      0\n      s6\n    call\n      FP\n    bnez\n      FQ\n      t6\n    li\n      32\n      t0\n",
        "    M3:\n      leave8\n" =>
        "    M3:\n      call\n        FS\n      leave8\n");
    my ($from, $to) = find(\$t, $name);
    substr($t, $to, 0) = asm(4, <<"END");
    FQ:
    ld 32 t6 a0
    leave8
    FH:
    li 0 t6
    li 32 t0
    bgeu rel:H9 t0 s5
    la buf t0
    bltu rel:H9 t0 s4
    la bstate t1
    ld BS_buf t1 t1
    bgeu rel:H9 t1 s4
    li32 73244475 t1
    mul t1 s4 t0
    xor s7 t0 t0
    mul t1 t0 t0
    srli 29 t0 t1
    xor t1 t0 t0
    li32 65535 t1
    and t1 t0 t0
    slli 6 t0 t0
    la lookcache t1
    li32 $off t2
    add t2 t1 t1
    add t1 t0 t6
    H9:
    ret
    FP:
    addi -16 sp sp
    sd 0 ra sp
    call FH
    ld 0 sp ra
    addi 16 sp sp
    beqz P9 t6
    ld 0 t6 t0
    bne rel:P8 s4 t0
    ld 8 t6 t0
    bne rel:P8 s7 t0
    ld 16 t6 t0
    bne rel:P8 s8 t0
    la lookcache t1
    ld 104 t1 t1
    ld 24 t6 t0
    bne rel:P8 t1 t0
    ret
    P8:
    li 0 t6
    P9:
    ret
    FS:
    addi -16 sp sp
    sd 0 ra sp
    call FH
    ld 0 sp ra
    addi 16 sp sp
    beqz S9 t6
    sd 0 s4 t6
    sd 8 s7 t6
    sd 16 s8 t6
    la lookcache t1
    ld 104 t1 t1
    sd 24 t1 t6
    sd 32 a0 t6
    S9:
    ret
END
}

# ---- is_exec_op: its name as one word ------------------------------------
# exec_ops holds names of up to 8 bytes, padded with zeros to 8: a name is
# one of them when it is that word, padded with zeros the same way (what
# streq on its bytes and a zero after them found). (A table of the words
# hashed was slower: most names are found among the first.)
{
    my ($from, $to) = find(\$t, 'is_exec_op');
    substr($t, $from, $to - $from) = fn('is_exec_op', <<'END', 2);
    ld NODE_content a0 t0
    lbu NODE_content_len a0 t1
    li 0 a0
    li 8 t2
    bltu rel:L9 t1 t2
    li 0 t3
    add t1 t0 t4
    X1:
    beq rel:X2 t0 t4
    addi -1 t4 t4
    lbu 0 t4 t5
    slli 8 t3 t3
    or t5 t3 t3
    j X1
    X2:
    la exec_ops t0
    la exec_ops_end t1
    X3:
    li 0 a0
    beq rel:L9 t1 t0
    li 1 a0
    ld 0 t0 t2
    beq rel:L9 t3 t2
    addi OP_size t0 t0
    j X3
    L9:
    ret
END
}

save();
