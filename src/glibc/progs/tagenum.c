/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A struct's tag that is also an enum constant's name, as gnulib's
   exclude.c has them (grep): struct exclude_pattern and enum exclude_type
   { exclude_hash, exclude_pattern }. C keeps tags apart from ordinary
   names; csema gave both one ff name, so ttpc took the constant in
   "p->type == exclude_pattern && ..." for the struct, a compound literal of
   it, and stopped: "cannot compile: &&". The tag is renamed now. */
#include <stdio.h>

enum exclude_type { exclude_hash, exclude_pattern };

struct exclude_pattern
{
  int count;
  int alloc;
};

struct segment
{
  enum exclude_type type;
  int options;
  struct exclude_pattern pat;
};

static int
same_kind (struct segment *s, int options)
{
  return s && s->type == exclude_pattern && (s->options & 4) == (options & 4);
}

int
main (void)
{
  struct segment s = { exclude_pattern, 4, { 1, 2 } };
  struct exclude_pattern *p = &s.pat;
  int a = same_kind (&s, 4), b = same_kind (&s, 0), c = same_kind (0, 4);
  printf ("same %d %d %d, pattern %d %d, sizeof %d\n", a, b, c, p->count, p->alloc, (int) sizeof (struct exclude_pattern));
  return a == 1 && b == 0 && c == 0 ? 0 : 1;
}
