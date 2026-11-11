/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* enums-a.c's second unit: the same enum constant's name, another value. */
#include <stdio.h>

int
wide (int fill)
{
  enum { buf_length = 256 / sizeof (int) };
  int buf[buf_length];
  int i, sum = 0;
  for (i = 0; i < buf_length; i++)
    buf[i] = fill + i;
  for (i = 0; i < buf_length; i++)
    sum += buf[i];
  printf ("wide: buf_length %d, sizeof buf %d, sum %d\n", (int) buf_length, (int) sizeof buf, sum);
  return buf_length;
}
