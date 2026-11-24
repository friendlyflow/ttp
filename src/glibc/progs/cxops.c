/* C's complex operators on each complex type, as gcc does them: + and -
   part by part, * and / libgcc's __mulXc3 and __divXc3 (with their NaN
   recovery: an infinity times a NaN is an infinity), a real operand kept
   real (its other part untouched: -0.0 stays), == and !=, unary -, the
   compound assignments and the conversions between them. Operands are
   volatile (no folding) and exact, so every target prints the same; a
   special result prints its class.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
#include <math.h>

static const char *cls (double x)
{
  if (isnan (x))
    return "nan";
  if (isinf (x))
    return x < 0 ? "-inf" : "inf";
  return 0;
}

static void p (const char *what, double re, double im)
{
  const char *a = cls (re), *b = cls (im);
  printf ("%s:", what);
  if (a)
    printf (" %s", a);
  else
    printf (" %a", re);
  if (b)
    printf (" %s\n", b);
  else
    printf (" %a\n", im);
}

#define OPS(T, N)							\
  static void N (void)							\
  {									\
    volatile T ar = 1.5, ai = -2.0, br = 0.5, bi = 4.0, r = 3.0;	\
    T _Complex a = __builtin_complex ((T) ar, (T) ai);			\
    T _Complex b = __builtin_complex ((T) br, (T) bi);			\
    T _Complex c;							\
    p (#N " a+b", __real__ (a + b), __imag__ (a + b));			\
    p (#N " a-b", __real__ (a - b), __imag__ (a - b));			\
    p (#N " a*b", __real__ (a * b), __imag__ (a * b));			\
    c = a / b;								\
    p (#N " a/b", __real__ c, __imag__ c);				\
    p (#N " a+r", __real__ (a + r), __imag__ (a + r));			\
    p (#N " r-a", __real__ (r - a), __imag__ (r - a));			\
    p (#N " r*a", __real__ (r * a), __imag__ (r * a));			\
    p (#N " a/r", __real__ (a / r), __imag__ (a / r));			\
    c = r / b;								\
    p (#N " r/b", __real__ c, __imag__ c);				\
    p (#N " -a", __real__ (-a), __imag__ (-a));				\
    printf (#N " ==: %d %d %d %d\n", a == a, a == b, a != b,		\
	    __builtin_complex ((T) r, (T) 0) == r);			\
    c = a;								\
    c += b;								\
    c *= b;								\
    c -= r;								\
    c /= a;								\
    p (#N " op=", __real__ c, __imag__ c);				\
    volatile T inf = INFINITY, nan = NAN, z = -0.0;			\
    T _Complex ni = __builtin_complex ((T) inf, (T) nan);		\
    T _Complex one = __builtin_complex ((T) 1, (T) 1);			\
    c = ni * one;							\
    p (#N " inf*1", __real__ c, __imag__ c);				\
    c = one / __builtin_complex ((T) 0, (T) 0);				\
    p (#N " 1/0", __real__ c, __imag__ c);				\
    c = __builtin_complex ((T) 2, (T) z) + (T) 1;			\
    printf (#N " -0: %d\n", !!signbit (__imag__ c));			\
  }

OPS (float, f)
OPS (double, d)
OPS (long double, l)

/* a complex operation as an argument and as a result (glibc's cpow:
   __cexp (c * __clog (x))) */
static double _Complex __attribute__ ((noinline)) cid (double _Complex z)
{
  return z;
}

static double _Complex __attribute__ ((noinline)) cmul (double _Complex a, double _Complex b)
{
  return a * b;
}

int main (void)
{
  float _Complex fz = __builtin_complex (1.25f, -0.5f);
  double _Complex dz = fz;
  long double _Complex lz = dz;
  double x = dz;
  f ();
  d ();
  l ();
  p ("conv", __real__ lz, __imag__ lz);
  p ("toreal", x, 0);
  printf ("tobool: %d %d\n", !!dz, !!(dz - dz));
  {
    double _Complex zero = dz - dz, im = __builtin_complex (0.0, 0.5);
    int n = 0;
    if (im)
      n = n + 1;
    if (zero)
      n = n + 10;
    printf ("cond: %d %d %d %d %d\n", n, zero ? 1 : 2, im && 1, zero || 0, !im);
  }
  dz = cid (dz + dz);
  p ("arg", __real__ dz, __imag__ dz);
  dz = cmul (dz, cid (-dz));
  p ("ret", __real__ dz, __imag__ dz);
  return 0;
}
