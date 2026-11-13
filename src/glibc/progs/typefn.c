/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A program's function named as a type of glibc's (flex's yyalloc in bc's
   scan.c; glibc has a union yyalloc, bison's): csema names it with its
   unit, as a static of glibc's; with the type's name ttpc called the type
   (wrong number of arguments: yyalloc). */
#include <stdio.h>
#include <stdlib.h>

void *
yyalloc (size_t n)
{
  return calloc (1, n);
}

int
main (void)
{
  int *p = yyalloc (4 * sizeof (int));
  p[2] = 42;
  printf ("yyalloc %d %d\n", p[0], p[2]);
  free (p);
  return 0;
}
