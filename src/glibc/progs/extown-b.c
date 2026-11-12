/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* extown-a.c's other unit: its state and pop used here. */
#include <stdio.h>

struct state { int depth; int seen; };
extern struct state state;
int pop (void);

int
main (void)
{
  int a = pop (), b = pop ();
  state.seen += a + b;
  printf ("depth %d seen %d\n", state.depth, state.seen);
  return state.depth == 1 && state.seen == 7 ? 0 : 1;
}
