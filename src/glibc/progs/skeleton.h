/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* progs/roundnames.c's skeleton, included once per element type, as
   malloc/dynarray-skeleton.c: its anonymous records have one place.  */
struct LIST
{
  union
  {
    struct { unsigned long used; void *array; } abstract;
    struct { unsigned long used; ELEM *array; } header;
  } u;
  int tag;
};

static ELEM *
AT (struct LIST *l, unsigned long i)
{
  return l->u.header.array + i;
}

static void
PUT (struct LIST *l, ELEM e)
{
  l->u.header.array[l->u.header.used++] = e;
}
#undef LIST
#undef ELEM
#undef AT
#undef PUT
