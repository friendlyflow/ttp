/* A function's address in parentheses in a global's item (make's FT_ENTRY's
   { (_func) } in a union: ttpc "cannot compile: :"): csema writes the
   function's address, not its parentheses'.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
static int f (int x) { return x + 2; }
static int g (int x) { return x + 4; }
struct ent { union { int (*fp) (int); void *p; } u; const char *name; };
static struct ent tab[] = { { { (f) }, "f" }, { { ((g)) }, "g" } };
int main (void) { printf ("%d %d\n", tab[0].u.fp (3), tab[1].u.fp (3)); return 0; }
