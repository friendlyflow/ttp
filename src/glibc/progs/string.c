/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* M1: glibc's strlen, memcpy, memset, strcmp and strchr, over lengths and
   alignments that take each of their paths. Built with gcc against libc.a
   and, through c2ff, with ttpc against glibc in ff: both must exit with the
   status in string.expect, a hash of every result. No headers, so that the
   two builds see the same declarations. */

typedef unsigned long size_t;
size_t strlen (const char *);
void *memcpy (void *, const void *, size_t);
void *memset (void *, int, size_t);
int strcmp (const char *, const char *);
char *strchr (const char *, int);
/* memcpy's generic C, which its resolver leaves out where misaligned
   access is fast (qemu without V): called by its own name (x86_64 has
   none: its SSE2 asm, the one every x86_64 runs; arm neither: its plain
   ARM asm, the one its resolver takes without NEON or VFP) */
#ifdef __x86_64__
#define __memcpy_generic __memcpy_sse2_unaligned
#endif
#ifdef __arm__
#define __memcpy_generic __memcpy_arm
#endif
void *__memcpy_generic (void *, const void *, size_t);

static char src[300];
static char dst[300];

int
main (void)
{
  unsigned long h = 0;
  for (int i = 0; i < 256; i++)
    src[i] = (char) (i % 255 + 1);
  src[256] = 0;

  /* memcpy: every length step and destination offset, sources unaligned */
  for (int n = 0; n < 200; n += 13)
    for (int o = 0; o < 9; o++)
      {
        memset (dst, 'x', sizeof dst);
        memcpy (dst + o, src + (n & 7), n);
        for (int k = 0; k < 300; k++)
          h = h * 31 + (unsigned char) dst[k];
      }

  for (int n = 0; n < 200; n += 7)
    for (int o = 0; o < 9; o++)
      {
        memset (dst, 'y', sizeof dst);
        __memcpy_generic (dst + o, src + (n % 9), n);
        for (int k = 0; k < 300; k++)
          h = h * 31 + (unsigned char) dst[k];
      }

  /* memset and strlen */
  memset (dst, 0, sizeof dst);
  memset (dst + 3, 'a', 77);
  h = h * 31 + strlen (dst + 3);
  h = h * 31 + strlen (src);
  h = h * 31 + strlen ("hello, glibc");
  for (int o = 0; o < 20; o++)
    h = h * 31 + strlen (src + o * 11);

  /* strcmp: less, greater, equal, and a difference late in a long string */
  h = h * 31 + (strcmp ("abc", "abd") < 0);
  h = h * 31 + (strcmp ("abd", "abc") > 0);
  h = h * 31 + (strcmp (dst + 3, dst + 3) == 0);
  memcpy (dst, src, 257);
  dst[200] = 1;
  h = h * 31 + (strcmp (src, dst) > 0);
  h = h * 31 + (strcmp (dst + 1, src + 1) < 0);

  /* strchr: found, the terminator, a value that is cut to a char */
  h = h * 31 + (strchr (src, src[100]) - src);
  h = h * 31 + (strchr (src, 0) - src);
  h = h * 31 + (strchr (src, 322) - src);
  h = h * 31 + (strchr (src + 70, 5) == 0);

  return (int) ((h ^ (h >> 8) ^ (h >> 16) ^ (h >> 24)) & 255);
}
