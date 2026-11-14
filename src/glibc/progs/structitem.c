/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A local struct whose field is set from a struct variable, as coreutils'
   timeout.c has it (struct itimerspec its = { {0}, ts }): ttpc takes a
   struct field's item as a : of its items alone (cannot compile: ts);
   csema writes the variable's fields there. */
#include <stdio.h>
#include <time.h>

struct box { struct timespec a; struct { long x, y; } inner; };

static long
use (struct timespec ts, struct box const *bp)
{
  struct itimerspec its = { {0}, ts };
  struct box b2 = { bp->a, bp->inner };
  return its.it_value.tv_sec * 1000 + its.it_value.tv_nsec + its.it_interval.tv_sec
         + b2.a.tv_sec * 100000 + b2.inner.x * 10 + b2.inner.y;
}

int
main (void)
{
  struct timespec ts = { 5, 7 };
  struct box b = { { 3, 0 }, { 4, 2 } };
  printf ("%ld\n", use (ts, &b));
  return 0;
}
