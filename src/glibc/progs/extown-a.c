/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A program's external global and function whose names are a static of
   glibc's too (state, pop): csema names them with the unit that defines
   them (state progs/extown-a.i), and must in every unit that uses them
   (extown-b.c), not only in this one: findutils' struct state state of
   finddata.c, used in ftsfind.c (ttpc: cannot compile: state); bc's pop of
   storage.c, called in execute.c (ttpc took x86_64's pop instruction). */
struct state { int depth; int seen; };
struct state state = { 3, 4 };
int
pop (void)
{
  state.depth--;
  return state.depth;
}
