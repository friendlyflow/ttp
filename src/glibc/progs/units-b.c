/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* The other unit of units-a.c.  */

struct item { long pad; struct item *next; int *result; int x; };
struct holder { int n; struct item list[2]; };

#define ANON canon
#define FIELD two
#define ANONAT canon_at
#define LIST clist
#define ELEM char
#define AT clist_at
#define PUT clist_put
#include "skeleton.h"

int
both (int a, int b)
{
  return a + b;
}

static long store[4];
extern __typeof (store) b_store __attribute__ ((weak, alias ("store")));

static int
twice (struct item *p)
{
  return p->x * 2;
}

char *
ub (struct clist *l, struct holder *h, int *result)
{
  clist_put (l, *clist_at (l, 0));
  h->list[1].result = result;
  h->n = both (1, 2);
  h->list[1].x = twice (&h->list[0]) + (int) b_store[1];
  h->n = (int) canon_at;
  return clist_at (l, 1);
}
