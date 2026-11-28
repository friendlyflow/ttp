/* A call through a pointer to a function's pointer, (*pp) (...) (gnulib's
   exclude.c call_addfn, which du --exclude-from calls: csema called pp
   itself, SIGSEGV), and through a function's pointer with stars.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
static int add1 (int x) { return x + 1; }
static int add2 (int x) { return x + 2; }
static int call_via (void *data, int x) { int (**pp) (int) = data; return (*pp) (x); }
int main (void)
{
  int (*f) (int) = add1, (*g) (int) = add2;
  printf ("%d %d %d %d\n", call_via (&f, 6), call_via (&g, 6), (*f) (7), (**g) (8));
  return 0;
}
