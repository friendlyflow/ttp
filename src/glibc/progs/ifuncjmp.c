/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* glibc's asm that branches to an ifunc: aarch64's rawmemchr.S, bl __strlen
   for a NUL (grep -z), and x86_64's __memcpy_chk and its kin, jmp memcpy.
   An ifunc's label is its slot: the branch goes through a stub
   (s2ff --plt, builtins-<target>.ff.txt's __ff_plt_<name>). */
#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <wchar.h>

extern void *__memcpy_chk (void *, const void *, size_t, size_t);
extern void *__memmove_chk (void *, const void *, size_t, size_t);
extern void *__mempcpy_chk (void *, const void *, size_t, size_t);
extern void *__memset_chk (void *, int, size_t, size_t);
extern wchar_t *__wmemset_chk (wchar_t *, wchar_t, size_t, size_t);

int
main (void)
{
  char s[32] = "abc\0def", d[32];
  wchar_t w[8];
  char *p = rawmemchr (s, 0);
  printf ("rawmemchr %d %d\n", (int) (p - s), (int) ((char *) rawmemchr (s, 'c') - s));
  __memcpy_chk (d, "hello", 6, sizeof d);
  __memmove_chk (d + 1, d, 6, sizeof d - 1);
  printf ("%s\n", d);
  printf ("%d\n", (int) ((char *) __mempcpy_chk (d, "xyz", 3, sizeof d) - d));
  __memset_chk (d, 'q', 4, sizeof d);
  printf ("%.6s\n", d);
  __wmemset_chk (w, L'z', 7, 8);
  w[7] = 0;
  printf ("%ls\n", w);
  return 0;
}
