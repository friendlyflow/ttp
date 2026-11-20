/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* ++ and -- on a floating variable add 1 or -1 in its type: ttpc added 1
   or -1 to its bits (x ++ was x and one ulp), so coreutils' seq, whose
   loop is for (long double i = 1; ; i++), printed 0.000001 without end
   (seq 0 0.000001 0.000003; on x86_64, x87). Here seq's loop (to i = 3),
   and ++ / -- of float, double and long double, prefix and postfix, their
   values, a field and an element, printed by glibc's printf.  */
#include <stdio.h>

struct box { float f; double d[2]; long double l; };

static int
seq (long double first, long double step, long double upto)
{
  int n = 0;
  for (long double i = 1; n < 10; i++)
    {
      long double x = first + i * step;
      printf ("%Lf\n", x);
      n++;
      if (i >= upto)
        break;
    }
  return n;
}

int
main (void)
{
  float f = 0.25f;
  double d = 0.25;
  long double l = 0.25L;
  struct box b = { 1.5f, { 2.5, -0.5 }, 3.5L };
  float f0 = f++;
  double d0 = d--;
  long double l0 = l++;
  printf ("%g %g %g %g %Lg %Lg\n", f0, f, d0, d, l0, l);
  printf ("%g %g %Lg\n", ++f, --d, --l);
  b.f++;
  b.d[1]--;
  ++b.l;
  printf ("%g %g %g %Lg\n", b.f, b.d[0], b.d[1], b.l);
  long double big = 1e40L;
  big++;
  printf ("%Lg %d\n", big, big == 1e40L);
  printf ("%d\n", seq (0, 0.000001L, 3));
  return 0;
}
