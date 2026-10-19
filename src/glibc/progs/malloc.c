/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* M3: glibc's malloc, free, realloc and calloc, and qsort, which needs
   them: small blocks of many sizes (their bins, tcache), frees that leave
   holes, realloc growing and shrinking in place and by moving, a block
   over the mmap threshold, calloc's zeroes, and qsort of a thousand longs.
   What is hashed is what a program may count on: the contents kept,
   alignment, zeroes, the order; never an address, which differs between
   the two builds. No headers, as in stdlib.c. */

void *malloc (unsigned long);
void free (void *);
void *realloc (void *, unsigned long);
void *calloc (unsigned long, unsigned long);
void qsort (void *, unsigned long, unsigned long, int (*) (const void *, const void *));

static unsigned long h = 1469598103934665603UL;

static void mix (unsigned long x) { h = (h ^ x) * 1099511628211UL; }

static int
cmp (const void *a, const void *b)
{
  long x = *(const long *) a, y = *(const long *) b;
  return (x > y) - (x < y);
}

/* every byte of p[0 .. n) is c */
static int
filled (const char *p, unsigned long n, char c)
{
  for (unsigned long i = 0; i < n; i++)
    if (p[i] != c)
      return 0;
  return 1;
}

int
main (void)
{
  char *p[200];
  for (int i = 0; i < 200; i++)
    {
      unsigned long n = i * 7 + 1;
      p[i] = malloc (n);
      mix (p[i] != 0);
      mix (((unsigned long) p[i] & 15) == 0);
      for (unsigned long j = 0; j < n; j++)
        p[i][j] = (char) i;
    }
  for (int i = 0; i < 200; i += 2)
    free (p[i]);
  for (int i = 1; i < 200; i += 2)
    {
      unsigned long old = i * 7 + 1, n = i % 3 == 0 ? old / 2 + 1 : i * 13 + 5;
      p[i] = realloc (p[i], n);
      mix (filled (p[i], n < old ? n : old, (char) i));
      for (unsigned long j = 0; j < n; j++)
        p[i][j] = (char) (i + 1);
    }
  for (int i = 0; i < 200; i += 2)
    {
      p[i] = malloc (i + 3);
      mix (((unsigned long) p[i] & 15) == 0);
    }
  for (int i = 1; i < 200; i += 2)
    mix (filled (p[i], i % 3 == 0 ? (i * 7 + 1) / 2 + 1 : i * 13 + 5, (char) (i + 1)));

  /* over the mmap threshold, grown by realloc */
  unsigned long big = 1UL << 20;
  char *b = malloc (big);
  for (unsigned long j = 0; j < big; j += 4096)
    b[j] = (char) (j >> 12);
  b = realloc (b, 3 * big);
  int ok = 1;
  for (unsigned long j = 0; j < big; j += 4096)
    ok &= b[j] == (char) (j >> 12);
  mix (ok);
  free (b);

  long *z = calloc (1000, sizeof (long));
  long s = 0;
  for (int i = 0; i < 1000; i++)
    s += z[i];
  mix (s);
  for (int i = 0; i < 1000; i++)
    z[i] = (i * 7919L) % 1000 - 500;
  qsort (z, 1000, sizeof (long), cmp);
  for (int i = 0; i < 1000; i++)
    mix (z[i]);
  free (z);

  for (int i = 0; i < 200; i++)
    free (p[i]);
  mix (malloc (0) != 0);
  return (int) ((h ^ (h >> 8) ^ (h >> 16) ^ (h >> 24) ^ (h >> 32) ^ (h >> 40) ^ (h >> 48) ^ (h >> 56)) & 255);
}
