/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* One macro that makes anonymous records of other fields on one line, as
   glibc's tst-strtod4.c's TEST_STRTOD (float, double, long double and
   _Float128 tables): csema named an anonymous record for its file and line
   alone, so all of them were the first's, float, and the tables of the
   others read 0. Each must be its own; two of the same fields on one line
   (TABLE (int, i2)) may be one. */
#include <stdio.h>

#define TABLE(T, N) static const struct { const char *in; T expected; char tag; } tab_##N[] = { { "a", (T) 1000000.5, 1 }, { "b", (T) 10.25, 2 } }; static double sum_##N (void) { double s = 0; for (unsigned i = 0; i < sizeof tab_##N / sizeof tab_##N[0]; i++) s += (double) tab_##N[i].expected; return s; }
#define UNION(T, N) static union { T v; unsigned char b[sizeof (T)]; } un_##N = { (T) 3 };

TABLE (float, f) TABLE (double, d) TABLE (long double, ld) TABLE (int, i) TABLE (int, i2)
UNION (char, c) UNION (double, ud)

int
main (void)
{
  int bad = 0;
  printf ("float %.2f double %.2f long double %.2f int %.2f int %.2f\n", sum_f (), sum_d (), sum_ld (), sum_i (), sum_i2 ());
  struct sf { const char *in; float expected; char tag; };
  struct sd { const char *in; double expected; char tag; };
  struct sl { const char *in; long double expected; char tag; };
  printf ("sizes as named records: %d %d %d\n", sizeof tab_f[0] == sizeof (struct sf), sizeof tab_d[0] == sizeof (struct sd), sizeof tab_ld[0] == sizeof (struct sl));
  printf ("tags %d %d %d\n", tab_f[1].tag, tab_d[1].tag, tab_ld[1].tag);
  printf ("unions %d %.2f %d\n", (int) un_c.v, un_ud.v, (int) sizeof un_c);
  bad |= sum_d () != 1000010.75 || sum_ld () != 1000010.75 || sum_i () != 1000010;
  bad |= sizeof un_c != 1 || un_ud.v != 3 || sizeof tab_d[0] != sizeof (struct sd) || sizeof tab_ld[0] != sizeof (struct sl);
  return bad;
}
