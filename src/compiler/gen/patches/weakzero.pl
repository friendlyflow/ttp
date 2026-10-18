# weakzero.pl: a weak global that nothing defines is at address 0, as an
# undefined weak symbol is for the linker, wherever C reads it, not only
# under address: gaddr gave "used before it is declared" for it (dl-support's
# __ehdr_start, a weak Elf64_Ehdr whose fields glibc reads when the kernel
# gives no AT_PHDR). So gaddr, with no label in the second pass, takes a
# weak declaration's address as 0.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc/gaddr',
    "        mv\n          s4\n          a0\n        la\n          msg_below\n          a1\n        li\n          msg_below_len\n          a2\n        j\n          diename\n",
    asm(8, "
    mv s4 a0
    call defkw
    li KW_weak t0
    bne rel:L2 t0 a0
    li 0 a0
    j L1
    L2:
    mv s4 a0
    la msg_below a1
    li msg_below_len a2
    j diename
"));
save();
