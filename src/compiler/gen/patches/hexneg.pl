# hexneg.pl: gval's own - of a literal (ldneg.pl) takes a double's too,
# a hex float without the L (0x...): a global double of - 0x1p+1024 (-inf,
# C's -HUGE_VAL) on arm, where a double is in memory, went to the compile
# time JIT, which there gave its temporary's address as the value
# (chexinf's gdm on the arm host). Only a group of - and the literal (or -
# and a cast, ldneg's): one of more (: - 1.0 / 3.0, tst-printf-round's)
# was its first literal negated.
# Test: chexinf (bootstrap's chello-arm), cldneg.
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
edit(\$t, 'gval', asm(10, "LGT:\nlbu NODE_children_len s5 t0\nli 2 t1\nbltu rel:LGN t1 t0\n") => asm(10, "
LGT:
    lbu NODE_children_len s5 t0
    li 2 t1
    beq rel:LGK t1 t0
    li 3 t1
    bne rel:LGN t1 t0
    ld NODE_children s5 t2
    ld 8 t2 a0
    call kwof
    li KW_cast t0
    bne rel:LGN t0 a0
LGK:
"));
save();
