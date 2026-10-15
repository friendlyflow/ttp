// exit42.s — progs/aarch64/exit42.ff for GNU as, linked with ff.ld: the
// bytes after ttpc's 120-byte ELF header must be the same. exit(42) comes
// first, the lines after it only check encodings.
    .globl  _start
_start:
    movz    x0, #42
    movz    x8, #93
    svc     #0
    str     x0, [sp, #-16]!
    ldr     x1, [sp, #8]
    add     x2, x3, #0x123, lsl #12
    b.ne    .+16
    bl      .-12
    lsl     x0, x0, #3
    sub     x0, x0, x1
    stp     x29, x30, [sp, #16]
    cbz     w5, .-24
