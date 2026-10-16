# exit42.s — progs/riscv64/exit42.ff for GNU as, linked with ff64.ld:
# `make check` compares the bytes. The c.* lines only check encodings:
# exit(42) comes first.
#
# ff is explicit about compressed code, GNU as is not: norvc keeps it from
# compressing the 32-bit instructions, rvc allows the c.* ones.

    .option norvc
    .globl  _start
_start:
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
