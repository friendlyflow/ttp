/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A local array of structs set from calls that return them, as coreutils'
   cp and touch have it (struct timespec timespec[2] = { get_stat_atime
   (st), get_stat_mtime (st) }): ttpc takes a struct element's item as a :
   of its items alone (cannot compile: get_stat_atime); csema declares the
   array and sets each element after. */
#include <stdio.h>
#include <time.h>

struct st { int mode; struct timespec at, mt; };

static inline struct timespec get_at (struct st const *p) { return p->at; }
static inline struct timespec get_mt (struct st const *p) { return p->mt; }

static long
stamp (struct st const *p)
{
  struct timespec timespec[3] = { get_at (p), get_mt (p) };
  return timespec[0].tv_sec * 1000 + timespec[1].tv_nsec * 10 + timespec[2].tv_sec;
}

int
main (void)
{
  struct st s = { 0, { 3, 4 }, { 5, 6 } };
  printf ("%ld\n", stamp (&s));
  return 0;
}
