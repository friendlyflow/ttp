/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* What the round trip of all of glibc found where one name or one place
   stands for two things, each checked (the exit status is the number that
   fail, at most 255), with no part of glibc but the builtins, built with
   gcc + libc.a and through c2ff --program --start with ttpc on every target,
   and round-tripped: an anonymous record of one place included for two types
   (dynarray-skeleton.c, fork_handler_list_at's stride was that of the first
   list in glibc), a local label of one name in two statement expressions
   (strptime_l's do_normal), a field with the name of a local after an index
   (lio_listio's waitlist->list[cnt].result).  */

struct big { long a, b, c; };

#define ANON banon
#define FIELD one
#define ANONAT banon_at
#define LIST blist
#define ELEM struct big
#define AT blist_at
#define PUT blist_put
#include "skeleton.h"

#define ANON canon
#define FIELD two
#define ANONAT canon_at
#define LIST clist
#define ELEM char
#define AT clist_at
#define PUT clist_put
#include "skeleton.h"

static int
places (void)
{
  int fails = 0;
  struct big bs[3];
  char cs[3];
  struct blist b;
  struct clist c;
  struct big one = { 1, 2, 3 };
  struct big two = { 4, 5, 6 };
  b.u.header.used = 0;
  b.u.header.array = bs;
  c.u.header.used = 0;
  c.u.header.array = cs;
  blist_put (&b, one);
  blist_put (&b, two);
  clist_put (&c, 'x');
  clist_put (&c, 'y');
  fails += blist_at (&b, 1) != &bs[1];
  fails += clist_at (&c, 1) != &cs[1];
  fails += bs[1].b != 5 || bs[0].c != 3;
  fails += cs[1] != 'y';
  fails += banon_at != 0 || canon_at != 0;
  return fails;
}

static int
labels (int x)
{
  int r = 0;
  r += ({ __label__ l; int v = 2; if (x) { v = 1; goto l; } if (0) { l: v += 10; } v; });
  r += ({ __label__ l; int v = 200; if (x) { v = 100; goto l; } if (0) { l: v += 1000; } v; });
  return r;
}

/* (e_acosh's cl, a table of its own in each branch) */
static int
tables (int i)
{
  if (i)
    {
      static const int t[] = { 1, 2, 3 };
      return t[2];
    }
  else
    {
      static const int t[] = { 4, 5 };
      return t[1];
    }
}

struct wait { int result; struct wait *next; };
struct waits { int n; struct wait list[3]; };

static int
paths (struct waits *w)
{
  int cnt = 1;
  int result = 2;
  int next = 0;
  w->list[cnt].result = 7;
  w->list[result].result = 8;
  w->list[next].next = &w->list[cnt];
  w->list[cnt].next = 0;
  return (w->list[1].result != 7) + (w->list[2].result != 8) + (w->list[0].next != &w->list[1]) + (w->list[1].next != 0);
}

int
main (void)
{
  int fails = 0;
  static struct waits w;
  fails += places ();
  fails += labels (1) != 1011 + 100;
  fails += labels (0) != 202;
  fails += paths (&w);
  fails += tables (1) != 3;
  fails += tables (0) != 5;
  return fails;
}
