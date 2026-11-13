/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Two units with a static of one name, a function in this one, a global in
   statkind-b.c, as coreutils' one program has them (cksum.c's static
   function output_file, dd.c's static output_file): csema gave both the
   name, made only the function, and dd's uses called it (ttpc: wrong
   number of arguments: output_file). */
#include <stdio.h>

int fb (void);

static int
output_file (int x)
{
  return x + 1;
}

int
main (void)
{
  printf ("%d %d\n", output_file (1), fb ());
  return 0;
}
