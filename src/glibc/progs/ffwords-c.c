/* ffwords, unit c: globals of this unit named as the same words (another
   unit's functions have those names), read and written, their addresses taken.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
static int license = 101;
static int frame = 102;
static int program = 103;
static int origin = 104;
static int elf_header = 105;
static int ascii = 106;
static int align = 107;
static int reserve = 108;
static int bss = 109;
static int bits = 110;
static int rel = 111;
static int with = 112;
static int packed = 113;
static int cleanup = 114;
static int alloca = 115;

int words_c (void)
{
  license += 1000;
  return license + frame + program + origin + elf_header + ascii + align + reserve + bss + bits + rel + with + packed + cleanup + alloca;
}

long words_c_addresses (void)
{
  int *volatile a[] = { &license, &frame, &program, &origin, &elf_header, &ascii, &align, &reserve, &bss, &bits, &rel, &with, &packed, &cleanup, &alloca };
  long n = 0;
  for (unsigned i = 0; i < sizeof a / sizeof a[0]; i++)
    n += a[i] != 0 && *a[i] > 100;
  return n;
}
