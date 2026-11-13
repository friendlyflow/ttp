/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* statkind-a.c's other unit: its static global of the same name. */
static char const *output_file = "dd";

int
fb (void)
{
  return output_file[0] + output_file[1];
}
