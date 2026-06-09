ENTRY(kernel_entry)

/* kernel.bin is a flat binary loaded at physical 0x11000 (disk sector 9,
 * relative to the stage-2 load base 0x10000). 0x11000 is 4K-aligned, so the
 * kernel and each of its sections fall on page boundaries — matching the
 * hardware page size and allowing per-section page permissions later. Link at
 * the load address so absolute references resolve, and keep .text first so
 * kernel_entry lands at byte 0. */
SECTIONS {
    . = 0x11000;

    .text ALIGN(4K) : {
        *(.text)
    }

    .rodata ALIGN(4K) : {
        *(.rodata)
    }

    .data ALIGN(4K) : {
        *(.data)
    }

    .bss ALIGN(4K) : {
        *(COMMON)
        *(.bss)
    }
}
