/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Two units (statics-b.c) each with a writable static of one name and one
   text, and a read-only one: csema gave units whose static has the same
   text one definition, the first's, so the two counters were one (glibc's
   56 units' static locks were one lock: found by datacheck). Each unit's
   writable static is its own object; a const one may be shared. */
#include <stdio.h>

int bump_b (void);
int table_b (int i);

static int counter;
static const int table[3] = { 10, 20, 30 };

static int
bump_a (void)
{
  return ++counter;
}

int
main (void)
{
  int a1 = bump_a ();
  int a2 = bump_a ();
  int b1 = bump_b ();
  int a3 = bump_a ();
  printf ("a %d %d %d, b %d, tables %d %d\n", a1, a2, a3, b1, table[1], table_b (2));
  return 0;
}
