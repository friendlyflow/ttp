/* Duff's device: a switch whose cases stand inside its other statements
   (liblzma's lzma_decode: switch (state) while (1) { ... case 1: ... }), the
   classic copy (cases inside a do while) and a block with a declaration
   before the first case and a break of the switch: csema writes a switch of
   gotos to labels where the cases stand.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
static int run (int state, int n)
{
  int out = 0;
  switch (state)
  while (1) {
    out += 100;
  case 1:
    out += 10;
    if (--n <= 0) break;
  case 2:
    out += 1;
    if (--n <= 0) break;
  }
  return out;
}
static int copy (char *to, const char *from, int count)
{
  int n = (count + 3) / 4, k = 0;
  switch (count % 4) {
  case 0: do { *to++ = *from++; k++;
  case 3:      *to++ = *from++; k++;
  case 2:      *to++ = *from++; k++;
  case 1:      *to++ = *from++; k++;
          } while (--n > 0);
  }
  return k;
}
static int blk (int x)
{
  int r = 0;
  switch (x) {
    { int t = 5;
  case 1: r = 1;
      if (x == 1) break;
  case 2: r += 2; t = 0; r += t; }
  default: r += 4;
  }
  return r;
}
int main (void)
{
  char buf[16] = { 0 };
  printf ("%d %d %d %d\n", run (0, 3), run (1, 3), run (2, 4), run (7, 2));
  printf ("%d %s\n", copy (buf, "abcdefghij", 10), buf);
  printf ("%d %d %d\n", blk (1), blk (2), blk (3));
  return 0;
}
