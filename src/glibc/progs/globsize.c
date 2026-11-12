/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A global whose value is sizeof or alignof of a type, alone or as a
   field's (glibc's nptl _thread_db_sizeof_pthread ...): csema writes it in
   a :, else ttpc took the global for a function (found by datacheck). Each
   checked against the code's own (the exit status is the number that
   fail), with no part of glibc but the builtins, built with gcc + libc.a
   and through csema --start with ttpc on every target. */

struct pair { long a; char *p; };
struct two { unsigned long x, y; };

const unsigned int size_pair = sizeof (struct pair);
unsigned long size_long = sizeof (long);
unsigned long align_long = _Alignof (long);
struct two both = { sizeof (int), _Alignof (struct pair) };
unsigned long sizes[2] = { sizeof (short), sizeof (char *) };

static volatile unsigned long one = 1;

int
main (void)
{
  int f = 0;
  f += size_pair != one * sizeof (struct pair);
  f += size_long != one * sizeof (long);
  f += align_long != one * _Alignof (long);
  f += both.x != one * sizeof (int);
  f += both.y != one * _Alignof (struct pair);
  f += sizes[0] != one * sizeof (short);
  f += sizes[1] != one * sizeof (char *);
  return f;
}
