/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A table whose items are each a chain of 64 conditionals, as gnulib's
   base64.c builds its decoding table (B64 (x)): one item of more than a
   node holds (csema: words: an item of more than 255 nodes, coreutils). */
#include <stdio.h>

#define B64(x) ((x) == 'A' ? 0 : (x) == 'B' ? 1 : (x) == 'C' ? 2 : (x) == 'D' ? 3 : (x) == 'E' ? 4 : (x) == 'F' ? 5 : (x) == 'G' ? 6 : (x) == 'H' ? 7 : (x) == 'I' ? 8 : (x) == 'J' ? 9 : (x) == 'K' ? 10 : (x) == 'L' ? 11 : (x) == 'M' ? 12 : (x) == 'N' ? 13 : (x) == 'O' ? 14 : (x) == 'P' ? 15 : (x) == 'Q' ? 16 : (x) == 'R' ? 17 : (x) == 'S' ? 18 : (x) == 'T' ? 19 : (x) == 'U' ? 20 : (x) == 'V' ? 21 : (x) == 'W' ? 22 : (x) == 'X' ? 23 : (x) == 'Y' ? 24 : (x) == 'Z' ? 25 : (x) == 'a' ? 26 : (x) == 'b' ? 27 : (x) == 'c' ? 28 : (x) == 'd' ? 29 : (x) == 'e' ? 30 : (x) == 'f' ? 31 : (x) == 'g' ? 32 : (x) == 'h' ? 33 : (x) == 'i' ? 34 : (x) == 'j' ? 35 : (x) == 'k' ? 36 : (x) == 'l' ? 37 : (x) == 'm' ? 38 : (x) == 'n' ? 39 : (x) == 'o' ? 40 : (x) == 'p' ? 41 : (x) == 'q' ? 42 : (x) == 'r' ? 43 : (x) == 's' ? 44 : (x) == 't' ? 45 : (x) == 'u' ? 46 : (x) == 'v' ? 47 : (x) == 'w' ? 48 : (x) == 'x' ? 49 : (x) == 'y' ? 50 : (x) == 'z' ? 51 : (x) == '0' ? 52 : (x) == '1' ? 53 : (x) == '2' ? 54 : (x) == '3' ? 55 : (x) == '4' ? 56 : (x) == '5' ? 57 : (x) == '6' ? 58 : (x) == '7' ? 59 : (x) == '8' ? 60 : (x) == '9' ? 61 : (x) == '+' ? 62 : (x) == '/' ? 63 : -1)

static signed char const b64[] = { B64 ('A'), B64 ('Z'), B64 ('a'), B64 ('z'), B64 ('0'), B64 ('+'), B64 ('/'), B64 ('*') };

int
main (void)
{
  int i, c = 'q';
  for (i = 0; i < (int) sizeof b64; i++)
    printf ("%d ", b64[i]);
  printf ("%d\n", B64 (c));
  return 0;
}
