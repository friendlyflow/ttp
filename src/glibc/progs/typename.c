/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A variable named type under sizeof, as coreutils' stat.c has it
   (char buf[sizeof type * CHAR_BIT / 3 + 3]): csema took the leaf type for
   a type name's node, which has its specifiers under it, and crashed. */
#include <stdio.h>
#include <limits.h>

static int
digits (unsigned long type)
{
  char buf[sizeof type * CHAR_BIT / 3 + 3];
  return sprintf (buf, "%lx", type) + (int) sizeof buf * 0 + (int) (sizeof buf > sizeof type);
}

int
main (void)
{
  int type = 7;
  printf ("sizeof type %d, digits %d %d\n", (int) sizeof type, digits (0xabc), digits ((unsigned long) type));
  return 0;
}
