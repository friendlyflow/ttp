/* SPDX-License-Identifier: GPL-3.0-only
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software: you can redistribute it and/or modify it under the terms of the
   GNU General Public License as published by the Free Software Foundation,
   version 3 of the License. It comes with no warranty. See the file LICENSE
   for the full text.

   ttpc.ld — the layout of arm's seed for SEED=gnu (ld -T): the one both
   the bare-metal cross ld (arm-none-eabi, whose own script adds the empty
   sections .persistent and .noinit and puts .text a page after the
   headers) and a native Linux ld (armelf_linux_eabi, which may save a
   page by DATA_SEGMENT_ALIGN) follow, so both make the same file. The
   code segment: the headers, .text, .rodata, from 0x10000 (the Linux
   script's start); the data segment: .data and .bss, on the next page at
   the same offset in it (its address minus its file offset a multiple of
   4096). .ARM.attributes follows as gas writes it. */
SECTIONS
{
    . = 0x10000 + SIZEOF_HEADERS;
    .text : { *(.text) }
    .rodata : { *(.rodata) }
    . = ALIGN(0x1000) + (. & 0xfff);
    .data : { *(.data) }
    .bss : { *(.bss) }
}
