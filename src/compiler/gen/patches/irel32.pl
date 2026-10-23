# irel32.pl: glibc's IRELATIVE table on a target of 4-byte words (arm),
# whose apply_irel reads Elf32_Rel entries (ELF_MACHINE_IREL): from
# __rel_iplt_start to __rel_iplt_end, each the address of a word and
# R_ARM_IRELATIVE (two words, no addend), the resolver's address in the
# word itself, which apply_irel replaces by the resolver's choice.
#
# ifslot: on such a target an ifunc's slot is a word holding its resolver's
# address (before, zeros: an Elf64_Rela's addend names the resolver).
# irelplace: the table's names __rel_iplt_start and __rel_iplt_end there
# (irelname). irelbody: its entries words, not dwords (irelword), without
# the resolver's. The address of an ifunc in a global's value (an entry of
# its own, ifnaddr.pl) would need the resolver's address in that word: not
# on such a target yet, it stops (ttpc: not on this target: the ifunc).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# ifslot: the resolver's address, as a word, or the slot's zeros
edit(\$t, 'ifslot',
    "        call\n          cfind\n        call\n          wordbits\n        srli\n          3\n          a0\n          a0\n        call\n          skip\n        leave1\n",
    asm(8, "
    call cfind
    beqz IS1 a0
    call label_addr
    IS1:
    mv a0 s4
    call wordbits
    li 32 t0
    bne rel:IS2 t0 a0
    mv s4 a2
    la irel_words a0
    addi 1 a0 a0
    li 1 a1
    li 0 a5
    call prim
    j IS3
    IS2:
    srli 3 a0 a0
    call skip
    IS3:
    leave1
"));

# irelname: a0 0 or 1, the table's start or end: a0 a1 its name (bytes,
# length), __rela_iplt_* or, on a target of 4-byte words, __rel_iplt_*
# irelword: a0 the name of the table's word, dword or word (a2 kept)
once(\$t, "      irelplace:\n", fn('irelname', "
    enter1
    mv a0 s4
    call wordbits
    li 32 t0
    beq rel:IN3 t0 a0
    la irel_names a0
    li 17 a1
    beqz IN9 s4
    addi 17 a0 a0
    li 15 a1
    j IN9
    IN3:
    la irel_names32 a0
    li 16 a1
    beqz IN9 s4
    addi 16 a0 a0
    li 14 a1
    IN9:
    leave1
", 6) . fn('irelword', "
    enter1
    mv a2 s4
    call wordbits
    la irel_words t0
    li 32 t1
    bne rel:IR1 t1 a0
    addi 1 t0 t0
    IR1:
    mv t0 a0
    mv s4 a2
    leave1
", 6) . "      irelplace:\n", 'irelplace');

edit(\$t, 'cc/irelplace',
    "        la\n          irel_names\n          s4\n        mv\n          s4\n          a0\n        li\n          17\n          a1\n        call\n          irelfind\n",
    asm(8, "
    li 0 a0
    call irelname
    call irelfind
"));
edit(\$t, 'cc/irelplace',
    "        addi\n          17\n          s4\n          a0\n        li\n          15\n          a1\n        call\n          irelfind\n",
    asm(8, "
    li 1 a0
    call irelname
    call irelfind
"));

# irelbody: the slots' entries in words there, without the resolver's
my ($from, $to) = find(\$t, 'cc/irelbody');
my $b = substr($t, $from, $to - $from);
my $e2 = "        E2:\n          mv\n            a0\n            a2\n          la\n            irel_words\n            a0\n          li\n            1\n            a1\n          li\n            0\n            a5\n          call\n            prim\n          addi\n            1\n            s5\n            s5\n          j\n            E1\n";
once(\$b, $e2, asm(8, "
    E2:
    mv a0 s7
    call wordbits
    li 32 t0
    beq rel:E5 t0 a0
    mv s7 a2
    la irel_words a0
    li 1 a1
    li 0 a5
    call prim
    E5:
    addi 1 s5 s5
    j E1
"), 'irelbody E2');
my $la = "          la\n            irel_words\n            a0\n";
my $n = ($b =~ s/\Q$la\E/          call\n            irelword\n/g);
$n == 6 or die "irel32: irelbody: $n la irel_words, not 6\n";
# (the words of ifunc addresses in globals' values: not on such a target)
once(\$b, "        E9:\n          la\n            irw_vars\n            s4\n          li\n            0\n            s5\n",
    asm(8, "
    E9:
    la irw_vars s4
    li 0 s5
    call wordbits
    li 32 t0
    bne rel:E3 t0 a0
    ld 0 s4 t0
    beqz E3 t0
    ld 16 s4 a0
    la msg_word a1
    li msg_word_len a2
    j diename
"), 'irelbody E9');
substr($t, $from, $to - $from) = $b;

once(\$t, "  irel_words:\n", "  irel_names32:\n    ascii\n      __rel_iplt_start__rel_iplt_end\n  irel_words:\n", 'irel_words');
save();
