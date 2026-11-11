/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* setlocale with a locale of files (C.UTF-8, made by localedef into
   LOCPATH: make locale-check), against all of glibc in ff: a static
   program's setlocale installs a category only where its lc-*.c is linked,
   which says so by an absolute symbol of a top-level asm
   (_nl_current_LC_CTYPE_used, localeinfo.h's _NL_CURRENT_DEFINE_ABS);
   without it the locale's name came back but its data stayed C's (sed's
   UTF-8 tests). Then MB_CUR_MAX, mbrtowc, mbstowcs and wctomb in it, and
   back to C. */
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

int
main (void)
{
  const char *s = "a\xce\xa6\xe2\x82\xac";
  const char *p = s;
  mbstate_t st;
  wchar_t w;
  char buf[8];
  char *r = setlocale (LC_ALL, "C.UTF-8");
  int k;
  printf ("setlocale: %s\n", r ? r : "(null)");
  printf ("MB_CUR_MAX: %d\n", (int) MB_CUR_MAX);
  memset (&st, 0, sizeof st);
  while (*p)
    {
      size_t n = mbrtowc (&w, p, strlen (p), &st);
      printf ("mbrtowc: %d U+%04lx\n", (int) n, (unsigned long) w);
      if (n == 0 || n > 4)
        break;
      p += n;
    }
  printf ("mbstowcs: %d\n", (int) mbstowcs (NULL, s, 0));
  k = wctomb (buf, 0x20ac);
  printf ("wctomb: %d %02x %02x %02x\n", k, buf[0] & 255, buf[1] & 255, buf[2] & 255);
  r = setlocale (LC_CTYPE, "C");
  printf ("setlocale: %s, MB_CUR_MAX: %d\n", r ? r : "(null)", (int) MB_CUR_MAX);
  printf ("mbstowcs: %d\n", (int) mbstowcs (NULL, s, 0));
  return 0;
}
