/* ffwords, unit a: C functions named as the words ttpc takes by their name
   alone (license, a comment to ttpc as comment is: gzip's license (), whose
   call ttpc dropped; frame, program, origin and elf_header of the layout;
   ascii, align, reserve, bss, bits, rel of the data; with, packed, cleanup,
   alloca): csema writes each name', at its definition and every use, here
   and in the other units. Each returns its number; words_a calls them all.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
int __attribute__ ((noinline)) license (void) { return 1; }
int __attribute__ ((noinline)) frame (void) { return 2; }
int __attribute__ ((noinline)) program (void) { return 3; }
int __attribute__ ((noinline)) origin (void) { return 4; }
int __attribute__ ((noinline)) elf_header (void) { return 5; }
int __attribute__ ((noinline)) ascii (void) { return 6; }
int __attribute__ ((noinline)) align (void) { return 7; }
int __attribute__ ((noinline)) reserve (void) { return 8; }
int __attribute__ ((noinline)) bss (void) { return 9; }
int __attribute__ ((noinline)) bits (void) { return 10; }
int __attribute__ ((noinline)) rel (void) { return 11; }
int __attribute__ ((noinline)) with (void) { return 12; }
int __attribute__ ((noinline)) packed (void) { return 13; }
int __attribute__ ((noinline)) cleanup (void) { return 14; }
int __attribute__ ((noinline)) alloca (void) { return 15; }

int words_a (void)
{
  return license () + frame () + program () + origin () + elf_header () + ascii () + align () + reserve () + bss () + bits () + rel () + with () + packed () + cleanup () + alloca ();
}
