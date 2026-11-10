/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Two units (enums-b.c) with a function's own enum constant of one name and
   two values, as glibc's vfprintf-internal.c and vfwprintf-internal.c have
   in outstring_converted_wide_string: enum { buf_length = 256 / sizeof
   (CHAR_T) }, 256 for char, 64 for wchar_t. csema took the first unit's
   value for both, so the wide function's loop ran to 256 over a buffer of
   64 (tst-vfprintf-mbs-prec's SIGSEGV): each unit must keep its own. */
#include <stdio.h>

int wide (int fill);

static int
narrow (int fill)
{
  enum { buf_length = 256 / sizeof (char) };
  char buf[buf_length];
  int i, sum = 0;
  for (i = 0; i < buf_length; i++)
    buf[i] = (char) (fill + i);
  for (i = 0; i < buf_length; i++)
    sum += buf[i];
  printf ("narrow: buf_length %d, sizeof buf %d, sum %d\n", (int) buf_length, (int) sizeof buf, sum);
  return buf_length;
}

int
main (void)
{
  int n = narrow (1);
  int w = wide (2);
  printf ("narrow %d wide %d\n", n, w);
  return n == 256 && w == 64 ? 0 : 1;
}
