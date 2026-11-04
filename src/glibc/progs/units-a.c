/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Two units at once (units-b.c), through c2ff and csema -l as all of glibc is,
   and round-tripped (units-check), where they define one name otherwise: what
   the round trip of all of glibc found. An anonymous record of one place for
   two types (dynarray-skeleton.c); a record of one text that names a record
   each has otherwise (async_waitlist's struct waitlist, rt/ and resolv/); a
   static function of one text likewise; an alias of a static of the unit's
   own (__libc_fgetgrent_freemem_ptr of nss/fgetgrent's buffer).  */

struct big { long a, b, c; };
struct item { int x; struct item *next; };
struct holder { int n; struct item list[2]; };

#define LIST blist
#define ELEM struct big
#define AT blist_at
#define PUT blist_put
#include "skeleton.h"

static char store[8];
extern __typeof (store) a_store __attribute__ ((weak, alias ("store")));

static int
twice (struct item *p)
{
  return p->x * 2;
}

struct big *
ua (struct blist *l, struct holder *h)
{
  blist_put (l, *blist_at (l, 0));
  h->list[1].x = twice (&h->list[0]) + a_store[0];
  return blist_at (l, 1);
}
