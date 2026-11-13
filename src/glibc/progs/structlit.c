/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A struct set from a compound literal of its type, as gnulib's
   parse-datetime.y has it (relative_time rel_time_0 = RELATIVE_TIME_0, a
   (relative_time) { 0, ... }): csema wrote one item, the literal in a :,
   and ttpc set the first field to the temporary's address (findutils'
   find -newermt: no date parsed, ckd_add saw an overflow). */
#include <stdio.h>

typedef struct { long year, month, day; int ns; } relative_time;
#define RELATIVE_TIME_0 ((relative_time) { 0, 0, 0, 0 })
static relative_time const zero_g = RELATIVE_TIME_0;

static long
sum (int k)
{
  const relative_time rel = RELATIVE_TIME_0;
  relative_time r2 = (relative_time) { k, 2 * k, 3 * k, 4 };
  return rel.year + rel.month + r2.year * 100 + r2.month * 10 + r2.day + r2.ns + zero_g.day;
}

int
main (void)
{
  printf ("%ld %ld\n", sum (1), sum (2));
  return 0;
}
