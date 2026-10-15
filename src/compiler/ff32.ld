/* ff32.ld — the layout ttpc gives a 32-bit arm program, for the GNU twins
   of progs/arm/*.ff: one segment at 0x10000, the 84-byte ELF32 header
   first (52 + one 32-byte program header), then the sections in this
   order. objcopy -O binary of the result must equal what ttpc writes after
   its header. */
ENTRY(_start)
SECTIONS
{
    . = 0x10000 + 84;
    .text : { *(.text) }
    . = ALIGN(8);
    .rodata : { *(.rodata) }
    . = ALIGN(8);
    .data : { *(.data) }
    . = ALIGN(8);
    .bss : { *(.bss) }
    /DISCARD/ : { *(.ARM.attributes) *(.ARM.exidx*) *(.ARM.extab*) *(.comment) *(.note*) }
}
