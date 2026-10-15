# wide.s — progs/wide.ff for GNU as: one instruction of most formats,
# with offsets at the edges of their range. `make check` compares the bytes.
    .option rvc
    .globl _start
_start:
    jalr ra, -4(a1)
    bltu t1, t2, .-2048
    bge a2, a3, .+4094
    jal zero, .+1048574
    auipc gp, 0xfffff
    srai a4, a5, 63
    sraiw a4, a5, 31
    csrrw zero, mtvec, t0
    csrrsi a0, mstatus, 8
    amoadd.w.aq a0, a2, (a1)
    lr.d.aqrl a0, (a1)
    fmadd.d fa0, fa1, fa2, fa3, dyn
    fsd fs0, -16(sp)
    fence rw, rw
    mulhsu s1, s2, s3
    c.j .-2048
    c.beqz a5, .-256
    c.bnez s1, .+254
    c.lui t1, 0xfffff
    c.addi16sp sp, -512
    c.addi4spn a2, sp, 1020
    c.swsp ra, 252(sp)
    c.ldsp s0, 504(sp)
    c.sw a5, 124(a4)
    c.srai a3, 63
    c.andi s1, -32
    c.subw a0, a1
    c.jalr t0
    c.ebreak
    c.slli t6, 1
