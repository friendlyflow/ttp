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
   setlocale's weak_extern of them). A block's extern declared weak is a
   weak reference too: _nl_current_LC_MONETARY_used, as uselocale.c declares
   each category's in a block, is 0 (csema wrote it as a plain name, which
   pulled lc-monetary's in: uselocale then stored to the thread locals it
   left out, tst-ftime_l's SIGILL on aarch64). An array declared weak that
   nothing defines, at file scope and in a block, is 0 as a value (ttpc
   called through it, fault 28; csema kept a block's array a plain name for
   apply_irel's __rela_iplt_start, which ttpc places itself).  */
extern char _nl_current_LC_TIME_used __attribute__ ((weak));
extern char _nl_current_LC_CTYPE_used __attribute__ ((weak));
extern const char ttp_weakref_gone[] __attribute__ ((weak));
extern int printf (const char *, ...);

int
main (void)
{
  printf ("LC_TIME %d, LC_CTYPE %d\n", &_nl_current_LC_TIME_used != 0, &_nl_current_LC_CTYPE_used != 0);
  {
    extern char _nl_current_LC_MONETARY_used;
#pragma weak _nl_current_LC_MONETARY_used
    printf ("LC_MONETARY %d\n", &_nl_current_LC_MONETARY_used != 0);
  }
  {
    extern const char ttp_weakref_none[];
#pragma weak ttp_weakref_none
    const char *p = ttp_weakref_none;
    printf ("arrays %d %d\n", ttp_weakref_gone != 0, p != 0);
  }
  return 0;
}
