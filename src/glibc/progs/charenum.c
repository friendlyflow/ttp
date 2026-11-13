/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A local char set from an enum constant, as gnulib's modechange.c has it
   (char flag = MODE_COPY_EXISTING): csema writes the constant's number
   there, where ttpc took the leaf for a text in a group's function of a
   program (text needs char * pointer). */
#include <stdio.h>

enum { MODE_DONE, MODE_ORDINARY_CHANGE, MODE_X_IF_ANY_X, MODE_COPY_EXISTING = 'c' };

static int
kind (int i)
{
  char flag = MODE_COPY_EXISTING;
  unsigned char u = MODE_X_IF_ANY_X;
  if (i)
    flag = MODE_ORDINARY_CHANGE;
  return flag * 10 + u;
}

int
main (void)
{
  printf ("kind %d %d\n", kind (0), kind (1));
  return 0;
}
