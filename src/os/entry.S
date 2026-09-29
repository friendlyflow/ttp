# entry.S — first instructions after reset.
#
# QEMU's `virt` machine with `-bios none` loads the ELF at 0x80000000 and
# jumps here in M-mode on every hart. Hart 0 sets up a C environment (gp, sp,
# trap vector, zeroed .bss) and calls kmain; all other harts park.

    .section .text.entry
    .globl _start
_start:
    csrr    t0, mhartid
    bnez    t0, park

    # gp must be loaded without relaxation, or the linker would rewrite this
    # into a gp-relative access to gp itself.
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop

    la      sp, __stack_top

    la      t0, trap_vector
    csrw    mtvec, t0

    # Zero .bss so C globals start out as 0.
    la      t0, __bss_start
    la      t1, __bss_end
1:  bgeu    t0, t1, 2f
    sd      zero, 0(t0)
    addi    t0, t0, 8
    j       1b
2:
    call    kmain

park:
    wfi
    j       park
