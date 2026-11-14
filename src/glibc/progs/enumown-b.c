/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* enumown-a.c's other unit: the same tag, other constants. */
enum deref { DEREF_UNDEFINED, DEREF_NEVER, DEREF_TO_DIR, DEREF_ALWAYS };

static enum deref dereference = DEREF_TO_DIR;

int
b_value (int k)
{
  enum deref d = k ? dereference : DEREF_ALWAYS;
  return d * 10 + DEREF_NEVER;
}
