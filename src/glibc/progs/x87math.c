/* x86_64's libm where glibc's C has the x87's asm and gcc's x87 builtins,
   built against all of glibc in ff (make x87math-check, GTARGET=x86_64):
   exp, exp2, exp10 and pow at their special cases (specialcase,
   special_case: math_force_eval's x87 branch, an "f" input), the masks of
   the x87's exceptions (feenableexcept, fedisableexcept, fegetexcept: fstcw),
   floorl, ceill and truncl (libc_fetestexcept_387: fnstsw to an "=a" of 16
   bits), the narrowing functions of long double (libc_feupdateenv_test_387),
   sqrtl (__builtin_sqrtl), powl (__powl_helper: x87 inputs that are values,
   fyl2xp1 of w_lo / (1.0L + w_hi)); and the same asm forms in its own C,
   with __builtin_ia32_cvtpd2ps (sincosf_poly.h's v2df_to_sf). Each result
   with the exceptions it raised: gcc + libc.a + libm.a and ttpc + glibc in
   ff must print the same. */
#define _GNU_SOURCE
#include <fenv.h>
#include <math.h>
#include <stdio.h>

static volatile double dv[] = { -745.1, -744.4, -708.5, 709.7, 709.78, 1e-320, -1075.5, -1022.5, 1023.9, 1024.5, -323.7, 308.2 };
static volatile long double lv[] = { 2.5L, -0.5L, 0x1.fffffffffffffffep62L, -7.75L, 1e-4000L, 3.0L, 0x1p-16445L };

static void flags (const char *what)
{
  int f = fetestexcept (FE_ALL_EXCEPT);
  printf ("  %s%s%s%s%s%s\n", what, f & FE_INVALID ? " invalid" : "", f & FE_DIVBYZERO ? " divbyzero" : "",
          f & FE_OVERFLOW ? " overflow" : "", f & FE_UNDERFLOW ? " underflow" : "", f & FE_INEXACT ? " inexact" : "");
  feclearexcept (FE_ALL_EXCEPT);
}

#define D(e) do { feclearexcept (FE_ALL_EXCEPT); double r_ = (e); printf ("%s = %a", #e, r_); flags (""); } while (0)
#define L(e) do { feclearexcept (FE_ALL_EXCEPT); long double r_ = (e); printf ("%s = %La", #e, r_); flags (""); } while (0)
#define F(e) do { feclearexcept (FE_ALL_EXCEPT); float r_ = (e); printf ("%s = %a", #e, (double) r_); flags (""); } while (0)

#ifdef __x86_64__
/* glibc's forms in a program's own C */
typedef unsigned short fexcept16;
typedef double v2df_t __attribute__ ((vector_size (2 * sizeof (double))));
typedef float v4sf_t __attribute__ ((vector_size (4 * sizeof (float))));
#define force_eval(x) \
  do { if (sizeof (x) <= sizeof (double)) __asm __volatile ("" : : "x" (x)); else __asm __volatile ("" : : "f" (x)); } while (0)
static int status (void) { fexcept16 t; asm volatile ("fnstsw %0" : "=a" (t)); return t & 0x3f; }
static int control (void) { unsigned short cw; __asm__ ("fstcw %0" : "=m" (cw)); return cw; }
static void own (void)
{
  /* (each operand read from a volatile after the asm before it: gcc keeps
     volatile reads and asm volatile in order, so what it computes from them
     raises its exceptions after that asm, as ttpc's) */
  long double y, a, b, r;
  double d;
  v2df_t v;
  v4sf_t s;
  asm volatile ("fnclex");
  printf ("control word %#x, status %#x\n", control (), status ());
  y = lv[4];
  force_eval (y * y);
  printf ("long double underflow in an \"f\" input: status %#x\n", status ());
  asm volatile ("fnclex");
  d = dv[5];
  force_eval (d * d);
  printf ("double: x87 status %#x", status ());
  flags ("");
  a = lv[3];
  b = lv[5];
  asm ("fyl2xp1" : "=t" (r) : "0" (a / (1.0L + b) + 1.75L), "u" (1.0L) : "st(1)");
  printf ("fyl2xp1 of values: %La\n", r);
  v = (v2df_t) { dv[3], -dv[11] * 1e300 };
  s = __builtin_ia32_cvtpd2ps (v);
  printf ("cvtpd2ps: %a %a %a %a", (double) s[0], (double) s[1], (double) s[2], (double) s[3]);
  flags ("");
  printf ("__builtin_sqrtl: %La %La\n", __builtin_sqrtl (lv[5]), __builtin_sqrtl (lv[2]));
}
#endif

int main (void)
{
  for (int i = 0; i < 12; i++)
    {
      D (exp (dv[i]));
      D (exp2 (dv[i] * 1.4426950408889634));
      D (exp10 (dv[i] * 0.4342944819032518));
      D (pow (0.5, -dv[i] * 1.4426950408889634));
      D (pow (-2.0, dv[i] < 0 ? -1074.0 + i : 1023.0 + i));
    }
  printf ("fegetexcept %#x\n", fegetexcept ());
  printf ("feenableexcept %#x\n", feenableexcept (FE_DIVBYZERO | FE_INVALID));
  printf ("fegetexcept %#x\n", fegetexcept ());
  printf ("fedisableexcept %#x\n", fedisableexcept (FE_ALL_EXCEPT));
  printf ("fegetexcept %#x\n", fegetexcept ());
  for (int i = 0; i < 7; i++)
    {
      L (floorl (lv[i]));
      L (ceill (lv[i]));
      L (truncl (lv[i]));
      L (sqrtl (lv[i]));
      L (powl (lv[i], 1.0L / 3));
      L (powl (lv[5], lv[i] * 1000));
      D (daddl (lv[i], 1e-30L));
      D (dsubl (lv[i], 0x1p-70L));
      D (dmull (lv[i], 1.1L));
      D (ddivl (lv[i], 3.0L));
      D (dfmal (lv[i], 3.0L, 1e-25L));
      D (dsqrtl (lv[i]));
      F (faddl (lv[i], 1e-20L));
      F (fsubl (lv[i], 0x1p-40L));
      F (fmull (lv[i], 1.1L));
      F (fdivl (lv[i], 3.0L));
      F (ffmal (lv[i], 3.0L, 1e-15L));
      F (fsqrtl (lv[i]));
    }
#ifdef __x86_64__
  own ();
#endif
  return 0;
}
