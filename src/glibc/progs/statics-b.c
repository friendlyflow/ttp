/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* statics-a.c's other unit: a static counter and a table of the same text. */

static int counter;
static const int table[3] = { 10, 20, 30 };

int
bump_b (void)
{
  return ++counter;
}

int
table_b (int i)
{
  return table[i];
}
