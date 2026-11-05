/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A third unit of units-a.c: its static of one text with units-a.c's, shared, and
   units-b.c's external of that name (libgcc's static __udivmodti4 in _moddi3
   and _divdi3, its external in _udivmodti4).  */

struct item { int x; struct item *next; };

static int
both (struct item *p)
{
  return p->x;
}

int
uc (struct item *p)
{
  return both (p);
}
