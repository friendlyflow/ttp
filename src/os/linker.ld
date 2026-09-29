/* linker.ld — OS memory layout. QEMU `virt` RAM starts at 0x80000000 and
 * `-bios none` jumps straight there, so _start (.text.entry) goes first. */
OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    . = 0x80000000;

    .text : {
        *(.text.entry)
        *(.text .text.*)
    }

    .rodata : ALIGN(8) {
        *(.srodata .srodata.*)
        *(.rodata .rodata.*)
    }

    .data : ALIGN(8) {
        *(.data .data.*)
        /* gp points 2 KiB into the small-data area so +-2 KiB offsets
         * reach both .sdata and .sbss. */
        __global_pointer$ = . + 0x800;
        *(.sdata .sdata.*)
    }

    .bss : ALIGN(8) {
        __bss_start = .;
        *(.sbss .sbss.*)
        *(.bss .bss.*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end = .;
    }

    /* 16 KiB boot stack for hart 0; grows down from __stack_top. */
    . = ALIGN(16);
    . += 0x4000;
    __stack_top = .;
}
