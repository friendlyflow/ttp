/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A function defined under an asm label (gnulib's printf __asm__
   ("rpl_printf"), found by progs3): its header gives the label, the
   definition here has none of its own, and asmlabel-b.c calls it by its C
   name, so by the label. csema followed only the C name: the other unit's
   call of rpl_show reached nothing ("unknown function: rpl_show"). */
#include <stdarg.h>
#include <stdio.h>
extern int show (const char *, ...) __asm__ ("rpl_show");
extern int twice (int) __asm__ ("rpl_twice");
int show (const char *f, ...)
{
  va_list ap;
  int r;
  va_start (ap, f);
  r = printf ("[rpl] ");
  r += vprintf (f, ap);
  va_end (ap);
  return r;
}
int twice (int x) { return 2 * x; }
