/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A weak reference pulls nothing in, as ld does with an archive member:
   _nl_current_LC_TIME_used, of lc-time.o, which nothing else of this
   program reaches, is 0; _nl_current_LC_CTYPE_used, of lc-ctype.o, which
   printf reaches (_nl_current_LC_CTYPE), is not (ttpc: weak / name, and
   with / names under every definition of lc-ctype.c's unit; tests2's repro,
   setlocale's weak_extern of them).  */
extern char _nl_current_LC_TIME_used __attribute__ ((weak));
extern char _nl_current_LC_CTYPE_used __attribute__ ((weak));
extern int printf (const char *, ...);

int
main (void)
{
  printf ("LC_TIME %d, LC_CTYPE %d\n", &_nl_current_LC_TIME_used != 0, &_nl_current_LC_CTYPE_used != 0);
  return 0;
}
