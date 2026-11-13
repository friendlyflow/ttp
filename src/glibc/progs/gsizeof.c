/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A global whose first item is a sizeof, as gnulib's quotearg.c has it
   (static struct slotvec slotvec0 = { sizeof slot0, slot0 }): csema wrote
   the sizeof as it is, and ttpc took the global for a function, its words
   code, so the program wrote its quoted names into its code (findutils'
   find, xargs and locate crashed). */
#include <stdio.h>
#include <string.h>

struct slotvec { size_t size; char *val; };
static char slot0[16];
static struct slotvec slotvec0 = { sizeof slot0, slot0 };
static struct slotvec *slotvec = &slotvec0;
static unsigned int const counted = sizeof (struct slotvec);

int
main (void)
{
  strcpy (slotvec->val, "quoted");
  printf ("%d %s %s %d\n", (int) slotvec->size, slot0, slotvec0.val, (int) counted);
  return 0;
}
