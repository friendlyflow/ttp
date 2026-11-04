/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A program with an external definition of a name that is a static in its tree
   (units-a.c's twice): a name of its own in ff (units-check).  */

int
twice (int x)
{
  return x * 2;
}

int
main (void)
{
  return twice (0);
}
