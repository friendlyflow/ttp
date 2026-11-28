/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Globals named as registers of some target (riscv64's gp, sp, tp, ra,
   fp; arm's lr, sp, pc; aarch64's sp): function pointers called by their
   names and plain globals, as C has them. A global function pointer called
   by its name was never reached by csema, so ttpc stopped "unknown
   function: gp" (fault 37). gcc's prints 42 43 44 45 46 47 48 7 8 9. */
#include <stdio.h>
static int add (int x) { return x + 2; }
int (*gp) (int) = add, (*sp) (int) = add, (*tp) (int) = add, (*ra) (int) = add;
int (*fp) (int) = add, (*lr) (int) = add, (*pc) (int) = add;
int zero = 7, x5 = 8, r12 = 9;
int main (void)
{
  printf ("%d %d %d %d %d %d %d %d %d %d\n", gp (40), sp (41), tp (42), ra (43), fp (44), lr (45), pc (46), zero, x5, r12);
  return 0;
}
