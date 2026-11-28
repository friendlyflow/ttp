/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* An ifunc's address in a global item, a pointer and a table of them as
   glibc's string tests have (test-memchr's impls): on arm it needs a
   32-bit IRELATIVE relocation, which ttpc stopped at ("not on this target",
   tests4's arm test-memchr, test-memcpy). gcc's prints 42 3 3. */
#include <stdio.h>
static int add1 (int x) { return x + 1; }
static int add2 (int x) { return x + 2; }
static void *pick (void) { return add2; }
int addf (int) __attribute__ ((ifunc ("pick")));
int (*addp) (int) = addf;
struct impl { const char *name; int (*fn) (int); };
static const struct impl impls[] = { { "addf", addf }, { "add1", add1 } };
int main (void)
{
  int (*p) (int) = addp;
  printf ("%d %d %d\n", p (40), impls[0].fn (1), impls[1].fn (2));
  return 0;
}
