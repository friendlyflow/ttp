# irelglob32.pl: on arm an ifunc's address in a global item gets its
# IRELATIVE relocation (the master's fault 35, tests4's arm test-memchr,
# test-memcpy and test-memcpy-large: "not on this target: memchr"). glibc's
# ifunc slots (irelbody's first loop) had their Elf32_Rel on 32-bit targets
# already: the slot's address and R_ARM_IRELATIVE, the resolver in the slot
# itself, as REL has its addend in the word; a global's word that holds an
# ifunc's address (irw_vars, gstore) stopped with that message. Now gstore
# writes the resolver's address in that word where words are 32 bits, and
# irelbody gives the word an Elf32_Rel the same way (no third word; on the
# 64-bit targets an Elf64_Rela with the resolver as its addend, as
# before). Test: src/glibc/progs/ifuncglob.c (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/gstore', "        sd\n          8\n          t0\n          s8\n        j\n          IW9\n" =>
    "        sd\n          8\n          t0\n          s8\n" . asm(8, "
    call wordbits
    li 32 t0
    bne rel:IW9 t0 a0
    ld 16 s8 t1
    ld NODE_children t1 t0
    ld 8 t0 a2
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    call cfind
    beqz IW9 a0
    call label_addr
    mv a0 s6
    j IW9
"));
edit(\$t, 'irelbody',
    "          call\n            wordbits\n          li\n            32\n            t0\n          bne\n            rel\n              E3\n            t0\n            a0\n          ld\n            0\n            s4\n            t0\n          beqz\n            E3\n            t0\n          ld\n            16\n            s4\n            a0\n          la\n            msg_word\n            a1\n          li\n            msg_word_len\n            a2\n          j\n            diename\n" => "",
    "        E4:\n          mv\n            a0\n            a2\n          call\n            irelword\n          li\n            1\n            a1\n          li\n            0\n            a5\n          call\n            prim\n          addi\n            1\n            s5\n            s5\n          j\n            E3\n" =>
    "        E4:\n" . asm(10, "
    mv a0 s7
    call wordbits
    li 32 t0
    beq rel:E4W t0 a0
    mv s7 a2
    call irelword
    li 1 a1
    li 0 a5
    call prim
") . asm(8, "
E4W:
    addi 1 s5 s5
    j E3
"));
save();
