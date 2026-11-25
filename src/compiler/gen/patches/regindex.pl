# regindex.pl: find_reg keeps what it found for a name over 32 bytes too
# (with flindex.pl, the master's index, 2026-11-24). find_reg kept its
# answers in lookcache by a name's first 32 bytes, so a longer name (csema's
# types, X struct prog, a static local's) scanned every symbol each time
# (reg_in: is_bits on each), a quarter of the time on xargs' page. Now a
# name over 32 bytes is kept in rgcache (32768 slots of 64 bytes): its
# length, kind and 32-bit FNV-1a hash, the scope range (scope_range), the
# generation (lookcache + 104, bumped per page), the name's address and the
# answer; a hit compares them and the bytes.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  lookcache:\n    reserve\n", "  rgcache:\n    reserve\n      2097152\n  lookcache:\n    reserve\n", 'lookcache');

edit(\$t, 'find_reg',
    "    bltu\n      rel\n        M1\n      s5\n      t0\n" => "    bltu\n      rel\n        LX\n      s5\n      t0\n",
    "    M3:\n      leave8\n" => "    M3:\n      leave8\n" . asm(4, "
LX:
    li32 2166136261 t2
    li 0 t3
LH:
    bgeu rel:LH2 s5 t3
    add s4 t3 t4
    lbu 0 t4 t4
    xor t4 t2 t2
    li32 16777619 t5
    mul t5 t2 t2
    addi 1 t3 t3
    j LH
LH2:
    slli 32 t2 t2
    srli 32 t2 t2
    slli 16 t2 s7
    or s5 s7 s7
    srli 4 s10 t0
    xor t0 t2 t0
    li32 32767 t1
    and t1 t0 t0
    slli 6 t0 t0
    la rgcache t1
    add t1 t0 s9
    ld 0 s9 t0
    bne rel:LXM t0 s7
    ld 8 s9 t0
    bne rel:LXM t0 s10
    ld 16 s9 t0
    bne rel:LXM t0 s11
    la lookcache t1
    addi 104 t1 t1
    ld 0 t1 t2
    ld 24 s9 t0
    bne rel:LXM t0 t2
    mv s4 a0
    mv s5 a1
    ld 32 s9 a2
    mv s5 a3
    call streq
    beqz LXM a0
    ld 40 s9 a0
    leave8
LXM:
    mv s4 a0
    mv s5 a1
    mv s10 a2
    mv s11 a3
    call reg_in
    bgez LXS a0
    mv s4 a0
    mv s5 a1
    la syms a2
    la common_end a3
    ld 0 a3 a3
    call reg_in
LXS:
    sd 0 s7 s9
    sd 8 s10 s9
    sd 16 s11 s9
    la lookcache t1
    addi 104 t1 t1
    ld 0 t1 t2
    sd 24 t2 s9
    sd 32 s4 s9
    sd 40 a0 s9
    leave8
"));
save();
