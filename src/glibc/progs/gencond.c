/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* _Generic of a conditional, as gnulib's string.h macros keep strchr's
   constness (time_rz.c, findutils): 1 ? (s) : (void *) 99 is a void *,
   whatever s's pointer type; ttpc typed the conditional by its first value
   (char *), found no association for it (cannot compile: generic). */
#include <stdio.h>
#include <string.h>

#define strnul(s) _Generic (1 ? (s) : (void *) 99, void *: (char *) strchr ((s), 0), const void *: strchr ((s), 0))

int
main (void)
{
  char buf[] = "zone\0next";
  char *z = buf;
  char const *c = "const";
  z = strnul (z) + 1;
  printf ("%s %d\n", z, (int) (strnul (c) - c));
  return 0;
}
