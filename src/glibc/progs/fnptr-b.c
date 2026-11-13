/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* fnptr-a.c's other unit: calls through its global op, and nothing else of it. */
#include <stdio.h>

extern int (*op) (int);

int
main (void)
{
  printf ("op %d %d\n", op (3), op (-21));
  return 0;
}
