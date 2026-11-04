/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* Two things c2ff reads from clang's text and once read wrong, each checked
   (the exit status is the number that fail, at most 255), with no part of
   glibc but the builtins, built with gcc + libc.a and through c2ff --program
   --start with ttpc on every target, and round-tripped: a string literal's
   prefix (c8rtomb's u8""[0] was 'u'; L"ab"[1] counted in arrays) and a
   variable-length array's count (execvpe's char *new_argv[argc > 1 ? 2 + argc
   : 3] was always 3; tst-unlockedio's char buf[strlen (blah) + 1] a call). */

typedef __CHAR16_TYPE__ c16;
typedef __CHAR32_TYPE__ c32;
typedef __WCHAR_TYPE__ wch;

static char g8[] = u8"xy";
static const char *gp8 = u8"pq";
static wch gl[] = L"xy";
static c16 gu[] = u"xy";
static c32 gU[] = U"xy";
static const wch *gpl = L"pq";
static const c16 *gpu = u"pq";
static const c32 *gpU = U"pq";

static int
literals (void)
{
  int f = 0;
  char a8[] = u8"xy";
  wch al[] = L"xy";
  c16 au[] = u"xy";
  c32 aU[] = U"xy";
  const char *p8 = u8"pq";
  const wch *pl = L"pq";
  const c16 *pu = u"pq";
  const c32 *pU = U"pq";

  /* each prefix, empty and not, indexed */
  f += u8""[0] != 0;
  f += u8"ab"[0] != 'a' || u8"ab"[1] != 'b' || u8"ab"[2] != 0;
  f += ""[0] != 0;
  f += "ab"[0] != 'a' || "ab"[1] != 'b' || "ab"[2] != 0;
  f += L""[0] != 0;
  f += L"ab"[0] != 'a' || L"ab"[1] != 'b' || L"ab"[2] != 0;
  f += u""[0] != 0;
  f += u"ab"[0] != 'a' || u"ab"[1] != 'b' || u"ab"[2] != 0;
  f += U""[0] != 0;
  f += U"ab"[0] != 'a' || U"ab"[1] != 'b' || U"ab"[2] != 0;
  /* not a prefix: a text that is these characters */
  f += "u8\""[0] != 'u' || "u8\""[1] != '8' || "u8\""[2] != '"' || "u8\""[3] != 0;
  f += "L\""[0] != 'L' || "u\""[0] != 'u' || "U\""[0] != 'U';
  /* an escape, and a text of pieces */
  f += (unsigned char) u8"\303\251"[1] != 0xa9;
  f += (u8"a" "b")[1] != 'b' || (u8"a" "b")[2] != 0;
  f += L"\x263a"[0] != 0x263a || u"\x263a"[0] != 0x263a || U"\x1f600"[0] != 0x1f600;
  /* their sizes */
  f += sizeof (u8"ab") != 3 || sizeof (u8"") != 1;
  f += sizeof (L"ab") != 3 * sizeof (wch) || sizeof (u"ab") != 3 * sizeof (c16) || sizeof (U"ab") != 3 * sizeof (c32);
  /* what sets an array, a local's and a global's */
  f += sizeof (a8) != 3 || a8[0] != 'x' || a8[1] != 'y' || a8[2] != 0;
  f += sizeof (g8) != 3 || g8[0] != 'x' || g8[1] != 'y' || g8[2] != 0;
  f += al[0] != 'x' || al[1] != 'y' || al[2] != 0 || gl[0] != 'x' || gl[1] != 'y' || gl[2] != 0;
  f += au[0] != 'x' || au[1] != 'y' || au[2] != 0 || gu[0] != 'x' || gu[1] != 'y' || gu[2] != 0;
  f += aU[0] != 'x' || aU[1] != 'y' || aU[2] != 0 || gU[0] != 'x' || gU[1] != 'y' || gU[2] != 0;
  /* as an address */
  f += p8[0] != 'p' || p8[1] != 'q' || p8[2] != 0 || gp8[0] != 'p' || gp8[2] != 0;
  f += pl[1] != 'q' || pl[2] != 0 || pu[1] != 'q' || pu[2] != 0 || pU[1] != 'q' || pU[2] != 0;
  f += gpl[1] != 'q' || gpl[2] != 0 || gpu[1] != 'q' || gpu[2] != 0 || gpU[1] != 'q' || gpU[2] != 0;
  /* an address counts in elements */
  f += *(L"ab" + 1) != 'b' || *(u"ab" + 1) != 'b' || *(U"ab" + 1) != 'b' || *(u8"ab" + 1) != 'b';
  return f;
}

static int
c8_of (int x)
{
  /* wcsmbs/c8rtomb.c: the value of u8""[0] in a variable */
  char c8;
  if (x)
    c8 = u8""[0];
  else
    c8 = u8"z"[0];
  return c8;
}

static long
length (const char *s)
{
  long n = 0;
  while (s[n])
    n++;
  return n;
}

static long
twice (long a, long b)
{
  return 2 * a + b;
}

static long limit = 4;
enum { SOME = 6 };

/* every element written and read back: an array too small would overwrite
   what lies beside it */
#define ELEMS(a) (long) (sizeof (a) / sizeof ((a)[0]))
#define FILL(a) \
  ({ long i_, r_ = 0; \
     for (i_ = 0; i_ < ELEMS (a); i_++) \
       (a)[i_] = 0; \
     for (i_ = 0; i_ < ELEMS (a); i_++) \
       r_ += (a)[i_] != 0; \
     r_; })

/* posix/execvpe.c, maybe_script_execute */
static long
execvpe_count (long argc)
{
  long before = 11;
  char *new_argv[argc > 1 ? 2 + argc : 3];
  long after = 22;
  long want = argc > 1 ? 2 + argc : 3;
  long i;
  /* (as it does: new_argv[0], [1], then argc pointers from new_argv + 2) */
  for (i = 0; i < want; i++)
    new_argv[i] = (char *) &before;
  for (i = 0; i < want; i++)
    if (new_argv[i] != (char *) &before)
      return -1;
  if (before != 11 || after != 22)
    return -2;
  return ELEMS (new_argv);
}

static int
counts (long n, const char *blah)
{
  int f = 0;
  /* the operators, each as C reads it */
  {
    char a[n > 1 ? n : 1];
    char b[n < 1 ? n : 1];
    char c[n >= 3 ? 2 : 5];
    char d[n <= 3 ? 7 : 5];
    char e[n == 3 ? 8 : 9];
    char g[n != 3 ? 8 : 9];
    char h[n % 2 + 1];
    char i[(n + 1) * 2];
    char j[n + 1 * 2];
    char k[(n > 1 ? n : 1) * 2];
    char l[n > 1 ? (n > 2 ? 10 : 11) : 12];
    char m[n < 1 ? 13 : n < 2 ? 14 : 15];
    char o[(n > 1 ? 16 : 17) > 16 ? 18 : 19];
    char p[1 + (n > 1 ? n : 2) + 1];
    char q[n * 2 > 5 ? n * 2 - 1 : n / 2 + 1];
    f += FILL (a) + FILL (b) + FILL (c) + FILL (d) + FILL (e) + FILL (g) + FILL (h) + FILL (i)
      + FILL (j) + FILL (k) + FILL (l) + FILL (m) + FILL (o) + FILL (p) + FILL (q);
    f += ELEMS (a) != (n > 1 ? n : 1) || ELEMS (b) != (n < 1 ? n : 1);
    f += ELEMS (c) != (n >= 3 ? 2 : 5) || ELEMS (d) != (n <= 3 ? 7 : 5);
    f += ELEMS (e) != (n == 3 ? 8 : 9) || ELEMS (g) != (n != 3 ? 8 : 9);
    f += ELEMS (h) != n % 2 + 1 || ELEMS (i) != (n + 1) * 2 || ELEMS (j) != n + 2;
    f += ELEMS (k) != (n > 1 ? n : 1) * 2;
    f += ELEMS (l) != (n > 1 ? (n > 2 ? 10 : 11) : 12) || ELEMS (m) != (n < 1 ? 13 : n < 2 ? 14 : 15);
    f += ELEMS (o) != ((n > 1 ? 16 : 17) > 16 ? 18 : 19);
    f += ELEMS (p) != 1 + (n > 1 ? n : 2) + 1;
    f += ELEMS (q) != (n * 2 > 5 ? n * 2 - 1 : n / 2 + 1);
  }
  /* a call, a call among operators, of several arguments, in one another,
     of a global, an enum's constant */
  {
    char a[length (blah) + 1];
    char b[length (blah)];
    char c[1 + twice (n, length (blah)) * 2];
    char d[twice (twice (n, 1), n + 1)];
    char e[n > 1 ? length (blah) : 2];
    char g[limit + n];
    char h[SOME + n];
    f += FILL (a) + FILL (b) + FILL (c) + FILL (d) + FILL (e) + FILL (g) + FILL (h);
    f += ELEMS (a) != length (blah) + 1 || ELEMS (b) != length (blah);
    f += ELEMS (c) != 1 + twice (n, length (blah)) * 2;
    f += ELEMS (d) != twice (twice (n, 1), n + 1);
    f += ELEMS (e) != (n > 1 ? length (blah) : 2);
    f += ELEMS (g) != limit + n || ELEMS (h) != SOME + n;
  }
  return f;
}

/* a local of a global's name, and a function's static */
static long
shadow (long n)
{
  long limit = n + 1;
  static long fixed = 5;
  char a[limit + 1];
  char b[fixed + n];
  return ELEMS (a) * 100 + ELEMS (b);
}

int
main (void)
{
  int f = literals ();
  f += c8_of (1) != 0 || c8_of (0) != 'z';
  f += execvpe_count (0) != 3 || execvpe_count (1) != 3 || execvpe_count (2) != 4 || execvpe_count (40) != 42;
  f += counts (1, "BLAH") + counts (2, "") + counts (3, "BLAH") + counts (9, "abcdefgh");
  f += shadow (3) != 508;
  return f > 255 ? 255 : f;
}
