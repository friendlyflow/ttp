/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A global pointer to a function, used only by calls through it in another
   unit (fnptr-b.c), as gawk's NODE *(*make_number)(double) = r_make_number
   of node.c: csema wanted no global for such a call, so the program had
   none (ttpc: unknown function: make_number). */
static int
twice (int x)
{
  return 2 * x;
}
int (*op) (int) = twice;
