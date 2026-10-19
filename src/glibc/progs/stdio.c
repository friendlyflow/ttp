/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* M4: glibc's printf without floats, puts and putchar, on stdout, which
   exit flushes: the conversions d i u o x X c s % and n, the flags - + space
   # 0, width and precision, also from the arguments (*), the lengths hh h l
   ll z t j, and NULL for %s. Both builds must print the rest of
   stdio.expect and exit with its status, the sum of what printf and puts
   returned. No headers, as in stdlib.c. */

int printf (const char *, ...);
int puts (const char *);
int putchar (int);

int
main (void)
{
  int t = 0, n = 0;
  t += puts ("stdio in ff");
  t += printf ("%d %i %u %o %x %X %c %s %%\n", -42, 17, 3000000000u, 8, 255, 48879, 'z', "text");
  t += printf ("[%5d] [%-5d] [%05d] [%+d] [% d] [%+d]\n", 42, 42, 42, 42, 42, -42);
  t += printf ("[%#o] [%#x] [%#X] [%#x]\n", 8, 255, 255, 0);
  t += printf ("[%.3d] [%8.3d] [%-8.3d] [%.0d] [%.0x]\n", 7, 7, -7, 0, 0);
  t += printf ("[%s] [%.2s] [%6s] [%-6s] [%*s] [%-*s] [%.*s]\n", "abc", "abc", "abc", "abc", 4, "x", 4, "y", 1, "zz");
  t += printf ("[%*d] [%-*d] [%.*d]\n", -6, 1, 6, 2, 4, 3);
  t += printf ("%ld %lu %lx %lld %llu\n", -9223372036854775807L - 1, 18446744073709551615UL,
               0xdeadbeefcafeUL, -1LL, 12345678901234567890ULL);
  t += printf ("%hhd %hhu %hd %hu\n", 300, 300, 70000, 70000);
  t += printf ("%zu %td %jd\n", (unsigned long) 99, (long) -5, (long) 1 << 40);
  t += printf ("%c%c%c%n|\n", 'a', 'b', 'c', &n);
  t += printf ("n %d, %s\n", n, (char *) 0);
  t += printf ("%5c|%-3c|\n", 'q', 'r');
  t += printf ("no conversions\n");
  t += printf ("");
  for (int i = 0; i < 5; i++)
    t += putchar ('0' + i) == '0' + i;
  t += putchar ('\n') == '\n';
  t += puts ("");
  return t & 255;
}
