# check.s — the program in the last page of test.ff (see mkff.pl), written
# for GNU as. `make check` assembles it and compares the bytes with the code
# ttpc wrote behind its ELF header.
#
# ff is explicit about compressed code, GNU as is not: norvc keeps it from
# compressing the 32-bit instructions, rvc allows the c.* ones. norelax
# makes it resolve the branch offsets itself instead of leaving relocations.

    .option norelax
    .option norvc
    addi    a0, zero, 42
    addi    a7, zero, 93
    ecall
    sd      a0, -8(sp)
    ld      s0, 16(sp)
    lui     t0, 0x12345
    beq     a0, a1, .+16
    jal     ra, .-12
    slli    a0, a0, 3
    sub     a0, a0, a1
    .option rvc
    c.addi  a0, -1
    c.ld    a0, 8(s0)
    c.mv    a0, a1
