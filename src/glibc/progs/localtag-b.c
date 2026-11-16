/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* localtag-a.c's other unit: a local named as its struct's tag, and a
   typedef's name that is a string of the other unit's. */
struct devlist { int dev_num; struct devlist *seen_last; };

int
last_of (int k)
{
  struct devlist one = { k + 2, 0 }, two = { k, &one };
  struct devlist *hash_entry = &two;
  hash_entry->seen_last->dev_num += 1;
  return hash_entry->seen_last->dev_num;
}

typedef struct { char const *start; char const *end; } BLOCK;

int
block_len (char const *s)
{
  BLOCK b = { s, s };
  while (*b.end)
    b.end++;
  return b.end - b.start;
}
