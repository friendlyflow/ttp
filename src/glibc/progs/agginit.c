/* A local of a struct, union or complex type initialized with a value that
   ff would write as a lone : or several items, which after such a local are
   its items: (x), c ? a : b, ({ ... }), (a, b); csema assigns those after
   the declaration, and drops redundant parentheses. glibc's
   math_check_force_underflow_complex, __typeof (x) tmp = (x), read the
   copy's first part from x (a spurious Underflow in libm's complex
   functions: math's test-double-cexp, ccosh ...).
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
#include <fenv.h>
#include <math.h>
#include <float.h>

struct pt { long x, y; };
union u { long l; double d; };

#define math_force_eval(x) ({ __typeof (x) __x = (x); __asm __volatile__ ("" : : "m" (__x)); })
#define check_underflow(x) do { __typeof (x) t_ = (x); if (fabs (t_) < DBL_MIN) { __typeof (t_) t2_ = t_ * t_; math_force_eval (t2_); } } while (0)
#define check_underflow_complex(x) do { __typeof (x) tc_ = (x); check_underflow (__real__ tc_); check_underflow (__imag__ tc_); } while (0)

int main (void)
{
  volatile int one = 1, zero = 0;
  struct pt p = { 3, 4 }, q = { 5, 6 };
  struct pt a = (p);
  struct pt b = one ? p : q;
  struct pt c = zero ? p : q;
  /* (a statement expression whose value is a struct local of its own: ttpc copies it after the group's
     scope is closed, a fault of its own; here its value is an outer one) */
  struct pt d = ({ long k = 10; p.x += k; p; });
  struct pt e = (zero, q);
  union u v = { .l = 42 };
  union u w = (v);
  double _Complex z = __builtin_complex (1.5, -2.0);
  double _Complex z1 = (z);
  __typeof (z) z2 = (z);
  double _Complex z3 = one ? z : 0;
  printf ("%ld %ld %ld %ld %ld %ld %ld %ld %ld %ld\n", a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y, e.x, e.y);
  printf ("%ld %g %g %g %g %g %g\n", w.l, __real__ z1, __imag__ z1, __real__ z2, __imag__ z2, __real__ z3, __imag__ z3);
  volatile double vz = 0.0, vo = 1.0;
  double _Complex r;
  __real__ r = vo;
  __imag__ r = vz;
  feclearexcept (FE_ALL_EXCEPT);
  check_underflow_complex (r);
  printf ("underflow %d\n", !!fetestexcept (FE_UNDERFLOW));
  return 0;
}
