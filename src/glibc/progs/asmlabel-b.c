/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* asmlabel-a.c's functions, called by their C names under its labels */
#include <stdio.h>
extern int show (const char *, ...) __asm__ ("rpl_show");
extern int twice (int) __asm__ ("rpl_twice");
int main (void)
{
  int (*p) (int) = twice;
  show ("%d %d\n", twice (21), p (3));
  return 0;
}
