/* A static const struct declared before its definition (tar's sparse.c
   oldgnu_optab, the optab of zeros: an empty archive): its value is the
   definition's.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
struct optab { int (*init) (int); int k; };
static struct optab const opt;
static const struct optab *pick (void) { return &opt; }
static int twice (int x) { return 2 * x; }
static struct optab const opt = { twice, 4 };
int main (void) { const struct optab *o = pick (); printf ("%d %d\n", o->init ? o->init (1) + 1 : -1, o->k); return 0; }
