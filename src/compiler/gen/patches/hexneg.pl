# hexneg.pl: gval's own - of a literal (ldneg.pl) takes a double's too,
# a hex float without the L (0x...): a global double of - 0x1p+1024 (-inf,
# C's -HUGE_VAL) on arm, where a double is in memory, went to the compile
# time JIT, which there gave its temporary's address as the value
# (chexinf's gdm on the arm host). Test: chexinf (bootstrap's chello-arm).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'gval', asm(12, "lbu -1 t0 t0\nli 76 t1\nbne rel:LGN t1 t0\n") => asm(12, "
    lbu -1 t0 t0
    li 76 t1
    beq rel:LGV t1 t0
    lbu 0 a0 t0
    li 48 t1
    bne rel:LGN t1 t0
    lbu 1 a0 t0
    li 120 t1
    bne rel:LGN t1 t0
"));
save();
