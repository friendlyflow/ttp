/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Two units with a named enum of one tag and other constants, as
   coreutils' one program has copy.h's enum Dereference_symlink
   (DEREF_UNDEFINED = 1, ...) and ls.c's (DEREF_UNDEFINED = 0, ... and
   DEREF_COMMAND_LINE_SYMLINK_TO_DIR): csema kept one, the first, and ls's
   constant of its own was in no tree (ttpc: unknown name). */
#include <stdio.h>

enum deref { DEREF_UNDEFINED = 1, DEREF_NEVER, DEREF_ALWAYS };

int b_value (int);

static int
a_value (enum deref d)
{
  return d == DEREF_ALWAYS ? 30 : d;
}

int
main (void)
{
  printf ("%d %d %d %d\n", a_value (DEREF_NEVER), a_value (DEREF_ALWAYS), b_value (0), b_value (1));
  return 0;
}
