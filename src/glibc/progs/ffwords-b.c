/* ffwords, unit b: unit a's functions called from another unit, by name and
   through their addresses; main.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
extern int license (void);
extern int frame (void);
extern int program (void);
extern int origin (void);
extern int elf_header (void);
extern int ascii (void);
extern int align (void);
extern int reserve (void);
extern int bss (void);
extern int bits (void);
extern int rel (void);
extern int with (void);
extern int packed (void);
extern int cleanup (void);
extern int alloca (void);
extern int words_a (void);
extern int words_c (void);
extern long words_c_addresses (void);

int main (void)
{
  int (*volatile fs[]) (void) = { license, frame, program, origin, elf_header, ascii, align, reserve, bss, bits, rel, with, packed, cleanup, alloca };
  int calls = 0, viaaddr = 0;
  calls = license () + frame () + program () + origin () + elf_header () + ascii () + align () + reserve () + bss () + bits () + rel () + with () + packed () + cleanup () + alloca ();
  for (unsigned i = 0; i < sizeof fs / sizeof fs[0]; i++)
    viaaddr += fs[i] ();
  printf ("functions: %d %d %d\n", words_a (), calls, viaaddr);
  printf ("license: %d, alloca: %d\n", license (), alloca ());
  printf ("globals: %d, addresses: %ld\n", words_c (), words_c_addresses ());
  return 0;
}
