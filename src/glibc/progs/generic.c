/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* The C constructs of glibc that c2ff and ttpc took in for all of it,
   each checked (the exit status is the number that fail), with no part
   of glibc but the builtins: built with gcc + libc.a, and through c2ff
   --program --start with ttpc, on every target that has u64 (64-bit
   longs); also round-tripped (generic-roundtrip). */

struct item { int v; struct item *next; };

/* argp's (child++)->argp: a path from an expression of several nodes */
static int
levels (const struct item *p)
{
  int n = 0;
  while (p->v)
    n += (p++)->v;
  return n;
}

/* regex's (dfa->edests + i)->elems: a path from a binary operator */
static int
second (struct item *a, long i)
{
  return (a + i)->v;
}

static int
add2 (int a, int b)
{
  return a + b;
}

/* backtrace's ((void) x, &_Unwind_Backtrace) (...): a call through a
   comma's value, the address of a function */
static int
via_comma (int x)
{
  return ((void) x, &add2) (x, 2);
}

/* gmon's char buf[len + 20], then sizeof (buf): the size of a VLA */
static unsigned long
vla_size (unsigned long len)
{
  char buf[len + 20];
  buf[0] = 0;
  return sizeof (buf) + buf[0];
}

/* str-two-way's ret0: __attribute__ ((unused)): a label's attribute */
static int
label_attr (int x)
{
  if (x)
    goto out;
  x = 5;
 out: __attribute__ ((unused))
  return x;
}

static long
count (char *const *v)
{
  long n = 0;
  while (v[n])
    n++;
  return n;
}

/* popen's (char *const[]){ "sh", "-c", ..., NULL } and broken_cur_max's
   (size_t[7]){ ... }: array compound literals */
static long
arrlit (void)
{
  return count ((char *const[]) { (char *) "sh", (char *) "-c", (char *) 0 })
         + ((unsigned long[3]) { 4, 5, 6 })[2];
}

/* tst-random's const int nseq = 3 and long rnd[nseq][nrnd]: a const
   global's number as an array's count (in C a VLA) */
static const int rows = 3;
const int cols = 4;
static long
const_counts (void)
{
  long m[rows][cols];
  long s = 0;
  for (int i = 0; i < rows; i++)
    for (int j = 0; j < cols; j++)
      m[i][j] = i * 10 + j;
  for (int i = 0; i < rows; i++)
    for (int j = 0; j < cols; j++)
      s += m[i][j];
  return s + sizeof m / sizeof m[0];
}

/* wordexp's enum action action and fts's enum leaf_optimization
   leaf_optimization (...): a tag that is also a local's or a function's
   name */
enum leaf { LEAF_NO, LEAF_YES = 7 };
static enum leaf
leaf (int x)
{
  return x ? LEAF_YES : LEAF_NO;
}
static int
tag_names (int x)
{
  enum action { ACT_NONE, ACT_A = 35, ACT_B } action = ACT_NONE;
  if (x)
    action = ACT_B;
  return action + leaf (x);
}

/* nss.h's enum nss_status, first only declared (a GNU C incomplete enum):
   its constants are those of its definition */
enum later;
enum later *later_p;
enum later { LATER_A = -2, LATER_B, LATER_C };

/* nss_files_functions' 64 *fptr++ = f: a function past 255 nodes */
static void
many (long *p)
{
#define P8 *p++ = 1; *p++ = 2; *p++ = 3; *p++ = 4; *p++ = 5; *p++ = 6; *p++ = 7; *p++ = 8;
  P8 P8 P8 P8 P8 P8 P8 P8
}
static long
many_sum (void)
{
  long a[64], s = 0;
  many (a);
  for (int i = 0; i < 64; i++)
    s += a[i];
  return s;
}

#define LMAX 9223372036854775807L
#define LMIN (-LMAX - 1)

int
main (void)
{
  int f = 0;
  struct item it[3] = { { 1, 0 }, { 2, 0 }, { 0, 0 } };
  long r;
  int ri;

  f += levels (it) != 3;
  f += second (it, 1) != 2;
  f += via_comma (40) != 42;
  f += vla_size (7) != 27;
  f += label_attr (3) != 3 || label_attr (0) != 5;
  f += arrlit () != 8;
  f += const_counts () != 3 + 4 * (0 + 10 + 20) + 3 * (0 + 1 + 2 + 3);
  f += tag_names (0) != 0 || tag_names (1) != 36 + 7;
  f += LATER_A != -2 || LATER_C != 0 || later_p != 0;
  f += many_sum () != 8 * 36;
  /* string/ffs.c on x86_64 */
  f += __builtin_ffs (8) != 4 || __builtin_ffs (0) != 0;
  f += __builtin_ffsl (1L << 40) != 41 || __builtin_ffsll (LMIN) != 64;
  /* mktime's overflow checks on longs and ints */
  f += __builtin_sub_overflow (5L, 7L, &r) || r != -2;
  f += !__builtin_sub_overflow (LMIN, 1L, &r) || r != LMAX;
  f += __builtin_sub_overflow (0, 5L, &ri) || ri != -5;
  f += !__builtin_sub_overflow (0, 3000000000L, &ri);
  f += __builtin_sub_overflow (10L, 3, &r) || r != 7;
  f += __builtin_add_overflow (5L, 7, &r) || r != 12;
  f += !__builtin_add_overflow (LMAX, 1L, &r) || r != LMIN;
  f += __builtin_add_overflow (LMAX, -1L, &r) || r != LMAX - 1;
  return f;
}
