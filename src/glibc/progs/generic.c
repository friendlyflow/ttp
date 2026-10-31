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

/* a compound literal as an operator's operand, left or right (the
   user's choice A: in a :) */
static long
arrlit_op (int *p)
{
  return *((int[2]) { 3, 4 } + 1) + ((int[1]) { 5 } != p) * 10
         + (p != (int[1]) { 5 }) * 20;
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

/* strtod's and strfrom's tests' tables: HUGE_VAL, INFINITY and NAN in a
   global's value (gcc folds the builtins; ff has their literals) */
static const struct { double d; float f; long double l; } specials[] = {
  { __builtin_huge_val (), __builtin_inff (), __builtin_huge_vall () },
  { -__builtin_huge_val (), __builtin_nanf (""), __builtin_nanl ("") },
  { __builtin_nan (""), -__builtin_inff (), -__builtin_infl () },
};
static int
specials_bad (void)
{
  return (__builtin_isinf_sign (specials[0].d) != 1) + (__builtin_isinf_sign (specials[0].f) != 1)
         + (__builtin_isinf_sign (specials[0].l) != 1) + (__builtin_isinf_sign (specials[1].d) != -1)
         + !__builtin_isnan (specials[1].f) + !__builtin_isnan (specials[1].l) + !__builtin_isnan (specials[2].d)
         + (__builtin_isinf_sign (specials[2].f) != -1) + (__builtin_isinf_sign (specials[2].l) != -1);
}

/* a long double literal made double or float in a global's value, as
   glibc's DBL_MIN ((double) 2.2250738585072014e-308L): its value rounded
   to the type (gcc folds it; ttpc has no conversion at compile time) */
static volatile double dmin = ((double) 2.22507385850720138309e-308L);
static volatile float fthird = (float) 0.333333333333333333333333L;
static volatile double dsub = 4.9406564584124654e-324L;

/* a global's long double constants worked out as gcc folds them (soft-fp
   has no code at compile time): strtod's and strfrom's tests' INFINITY +
   0.0L, -NAN + 0.0L; a sum rounded, the zero's sign */
static volatile long double ldnan = -__builtin_nanf ("") + 0.0L;
static volatile long double ldinf = __builtin_inff () + 0.0L;
static volatile long double ldsum = 1.0L + 0x1p-112L - 0x1p-114L;
static volatile long double ldmz = -0.0L + -0.0L;
static volatile long double ldpz = -0.0L + 0.0L;
static volatile double dfold = (double) (1.0L + 0x1p-60L) - 1;

/* (their bits: this program has no soft-fp; binary128's high word is the
   second where long double is 16 bytes, little-endian) */
static unsigned long long
ldhi (volatile long double *x)
{
  return ((volatile unsigned long long *) x)[1];
}
static unsigned long long
ldlo (volatile long double *x)
{
  return ((volatile unsigned long long *) x)[0];
}
static int
ldfold_bad (void)
{
  if (sizeof (long double) != 16)
    return 0;
#ifdef __x86_64__
  /* (the x87's: the significand, its integer bit set, then the sign and
     exponent; 1 + 0x1p-112 rounds to 1 there) */
  return (ldhi (&ldnan) != 0xffff || ldlo (&ldnan) != 0xc000000000000000ULL)
         + (ldhi (&ldinf) != 0x7fff || ldlo (&ldinf) != 0x8000000000000000ULL)
         + (ldhi (&ldsum) != 0x3fff) + (ldlo (&ldsum) != 0x8000000000000000ULL) + (ldhi (&ldmz) != 0x8000)
         + (ldhi (&ldpz) != 0) + (dfold != 0);
#endif
  return (ldhi (&ldnan) != 0xffff800000000000ULL) + (ldhi (&ldinf) != 0x7fff000000000000ULL)
         + (ldhi (&ldsum) != 0x3fff000000000000ULL) + (ldlo (&ldsum) != 1) + (ldhi (&ldmz) != 0x8000000000000000ULL)
         + (ldhi (&ldpz) != 0) + (dfold != 0);
}

/* gconv's const unsigned char *inptr = *inptrp: a char or u8 pointer set
   from a dereference or an address, not a text */
static int
text_ptr (unsigned char **pp)
{
  const unsigned char *p = *pp;
  char *q = (char *) *pp;
  unsigned char c = 5;
  unsigned char *r = &c;
  return p[0] + q[1] + *r;
}

/* dlopen's RETURN_ADDRESS and ____longjmp_chk's check of a frame:
   __builtin_return_address (0) is in the caller's code, after its start;
   __builtin_frame_address (0) is next to the function's locals (ttpc's
   frame pointer, through builtins-<target>.ff.txt's __ff_fp) */
static void * __attribute__ ((noinline))
back_to (void)
{
  return __builtin_return_address (0);
}

static int __attribute__ ((noinline))
ret_addr_bad (void)
{
  char *r = back_to ();
  return !(r > (char *) ret_addr_bad && r < (char *) ret_addr_bad + 4096);
}

static int __attribute__ ((noinline))
frame_bad (void)
{
  volatile int x = 1;
  char *fr = __builtin_frame_address (0);
  return !((char *) &x < fr + 64 && (char *) &x > fr - 4096) + (x != 1);
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
  f += arrlit_op (0) != 34;
  f += const_counts () != 3 + 4 * (0 + 10 + 20) + 3 * (0 + 1 + 2 + 3);
  f += tag_names (0) != 0 || tag_names (1) != 36 + 7;
  f += LATER_A != -2 || LATER_C != 0 || later_p != 0;
  f += many_sum () != 8 * 36;
  f += specials_bad ();
  f += ldfold_bad ();
  f += ret_addr_bad () + frame_bad ();
  f += dmin != 0x1p-1022 || fthird != 0x1.555556p-2f || dsub != 0x1p-1074;
  {
    unsigned char b[2] = { 30, 7 }, *bp = b;
    f += text_ptr (&bp) != 42;
  }
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
