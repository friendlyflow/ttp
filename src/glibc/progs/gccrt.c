/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* libgcc's own functions, called by name: complex multiply and divide
   (C99's Annex G, its infinities and NaNs too), the integer helpers, the
   powers to an int, and soft-fp's float conversions and division. Each
   result's bits are printed: gcc + libc.a + gcc's libgcc.a and ttpc + glibc
   and libgcc in ff agree only when every bit does. */

#include <stdio.h>

typedef _Complex float cf;
typedef _Complex double cd;
typedef _Complex long double cl;

cf __mulsc3 (float, float, float, float);
cf __divsc3 (float, float, float, float);
cd __muldc3 (double, double, double, double);
cd __divdc3 (double, double, double, double);
cl __multc3 (long double, long double, long double, long double);
cl __divtc3 (long double, long double, long double, long double);
int __popcountdi2 (long);
int __clzdi2 (unsigned long);
int __ctzdi2 (unsigned long);
int __ffsdi2 (long);
int __paritydi2 (long);
int __clrsbdi2 (long);
unsigned int __bswapsi2 (unsigned int);
long __bswapdi2 (long);
int __absvsi2 (int);
long __absvdi2 (long);
int __addvsi3 (int, int);
long __addvdi3 (long, long);
long __subvdi3 (long, long);
int __mulvsi3 (int, int);
double __powidf2 (double, int);
float __powisf2 (float, int);
long double __powitf2 (long double, int);
unsigned long __fixunsdfdi (double);
unsigned long __fixunssfdi (float);
long double __floatsitf (int);
long double __floatunsitf (unsigned int);
int __fixtfsi (long double);
unsigned int __fixunstfsi (long double);
int __unordtf2 (long double, long double);
#ifdef __riscv
/* (soft-fp's division of float and double: riscv64's libgcc has them, x86_64
   divides in SSE) */
double __divdf3 (double, double);
float __divsf3 (float, float);
#endif
int __gcc_bcmp (const unsigned char *, const unsigned char *, unsigned long);

static int n;

static void w (unsigned long x) { printf ("%d %016lx\n", n++, x); }
/* (an unsigned int as itself: this file declares __bswapsi2 unsigned, where
   libgcc's is SItype, an int; gcc takes a call's type from the caller's
   declaration, ttpc from the function's definition) */
static void w32 (unsigned int x) { printf ("%d %08x\n", n++, x); }
static void f (float x) { union { float f; unsigned int u; } v; v.f = x; w (v.u); }
static void d (double x) { union { double d; unsigned long u; } v; v.d = x; w (v.u); }
static void l (long double x) { union { long double d; unsigned long u[2]; } v; v.d = x; w (v.u[0]); w (v.u[1]); }

static double dv[] = { 0.0, -0.0, 1.0, -2.5, 3.0e300, 1.0e-310, __builtin_inf (), -__builtin_inf (), __builtin_nan ("") };
#define N (sizeof dv / sizeof dv[0])

int main (void)
{
  unsigned int i, j;
  for (i = 0; i < N; i++)
    for (j = 0; j < N; j += 2)
      {
        double a = dv[i], b = dv[(i + 3) % N], c = dv[j], e = dv[(j + 5) % N];
        cd z = __muldc3 (a, b, c, e), q = __divdc3 (a, b, c, e);
        d (__real__ z); d (__imag__ z); d (__real__ q); d (__imag__ q);
        cf zf = __mulsc3 (a, b, c, e), qf = __divsc3 (a, b, c, e);
        f (__real__ zf); f (__imag__ zf); f (__real__ qf); f (__imag__ qf);
        cl zl = __multc3 (a, b, c, e), ql = __divtc3 (a, b, c, e);
        l (__real__ zl); l (__imag__ zl); l (__real__ ql); l (__imag__ ql);
      }
  static long iv[] = { 0, 1, -1, 2, 0x7f, 0x80, 0x12345678, -0x7fffffffL, 0x0102030405060708L, 0x7fffffffffffffffL, (long) 0x8000000000000000UL };
  for (i = 0; i < sizeof iv / sizeof iv[0]; i++)
    {
      long x = iv[i];
      w (__popcountdi2 (x)); w (__ffsdi2 (x)); w (__paritydi2 (x)); w (__clrsbdi2 (x));
      if (x)
        { w (__clzdi2 (x)); w (__ctzdi2 (x)); }
      w32 (__bswapsi2 (x)); w (__bswapdi2 (x));
      if (x != (long) 0x8000000000000000UL)
        w (__absvdi2 (x));
      if ((int) x != (int) 0x80000000)
        w (__absvsi2 ((int) x));
      w (__addvsi3 ((int) x >> 2, 12345)); w (__addvdi3 (x >> 2, -77)); w (__subvdi3 (x >> 2, 99)); w (__mulvsi3 ((int) x >> 17, 3));
      d (__powidf2 (1.0 + (double) (x & 0xff) / 64, (int) (x & 31) - 8));
      f (__powisf2 (1.0f + (float) (x & 0xff) / 32, (int) (x & 15) - 4));
      l (__powitf2 (1.0L + (long double) (x & 0xff) / 16, (int) (x & 63) - 20));
      l (__floatsitf ((int) x)); l (__floatunsitf ((unsigned int) x));
      w (__fixtfsi ((long double) (int) x / 3)); w32 (__fixunstfsi ((long double) (unsigned int) x / 5));
      w (__fixunsdfdi ((double) (unsigned long) x)); w (__fixunssfdi ((float) (unsigned int) x));
#ifdef __riscv
      d (__divdf3 ((double) x, 7.0)); f (__divsf3 ((float) x, -3.0f));
#endif
    }
  for (i = 0; i < N; i++)
    w (__unordtf2 (dv[i], dv[(i + 7) % N]));
  static const unsigned char s1[] = "libgcc in ff", s2[] = "libgcc in FF";
  w (__gcc_bcmp (s1, s2, 10)); w (__gcc_bcmp (s1, s2, 12) != 0);
  return 0;
}
