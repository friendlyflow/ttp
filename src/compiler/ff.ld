/* ff.ld — the layout ttpc gives a program, for the GNU twins of the ff
   programs (progs/*.s, ttpc.s): one segment at 0x10000, the 120-byte ELF
   header first, then the sections in this order. objcopy -O binary of the
   result must equal what ttpc writes after its header. */
ENTRY(_start)
SECTIONS
{
    . = 0x10000 + 120;
    .text : { *(.text) }
    . = ALIGN(8);
    .rodata : { *(.rodata) }
    . = ALIGN(8);
    .data : { *(.data) }
    . = ALIGN(8);
    .bss : { *(.bss) }
    /DISCARD/ : { *(.riscv.attributes) *(.comment) }
}
