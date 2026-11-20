/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A local variable named as a type of glibc's (hash_entry, glibc's hash
   table's) and as a struct's tag of another unit, as coreutils' one program
   has gnulib hash.c's struct hash_entry and df.c's local hash_entry (a
   struct devlist *): ttpc took glibc's type for the local in hash_entry /
   seen_last, in an inner block of a function of a group (unknown name:
   seen_last; ttpc's localpath.pl). Here, in no group, ttpc took the local
   before too. And a string that is a type's name, of another unit's
   (coreutils env.c's "BLOCK", ptx.c's typedef of a struct) or of glibc's
   ("timespec"): ttpc took it for a compound literal of that type with no
   items (cannot compile: with no name); csema writes it as its bytes. */
#include <stdio.h>

struct hash_entry { int data; struct hash_entry *next; };

int last_of (int);
int block_len (char const *);

static int
sum (struct hash_entry const *e)
{
  int s = 0;
  for (; e; e = e->next)
    s += e->data;
  return s;
}

int
main (void)
{
  struct hash_entry b = { 2, 0 }, a = { 1, &b };
  printf ("%d %d\n", sum (&a), last_of (40));
  printf ("%s %s %d\n", "BLOCK", "timespec", block_len ("BLOCK"));
  return 0;
}
