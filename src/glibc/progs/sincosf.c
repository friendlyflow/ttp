/* sinf, cosf and sincosf (sincosf_poly.h: v2df_t's arithmetic, its
   subscripts and v2df_to_sf's __builtin_ia32_cvtpd2ps on x86_64) built
   against all of glibc in ff (make sincosf-check): each argument's results
   with the exceptions they raised; gcc + libc.a + libm.a and ttpc + glibc in
   ff must print the same. The arguments reach each path: tiny, |x| < pi/4,
   the small reduction, the large one (beyond 120), inf and nan. */
#define _GNU_SOURCE
#include <fenv.h>
#include <math.h>
#include <stdio.h>

static volatile float xs[] = { 0x1p-30f, -0x1p-13f, 0.1f, -0.5f, 0.7853f, 1.0f, -2.5f, 3.14159f, 10.0f, -100.5f,
                               119.0f, 121.75f, -1000.0f, 12345.678f, 0x1p30f, -0x1.fffffep127f, 1e-40f, INFINITY, NAN };

static void flags (void)
{
  int f = fetestexcept (FE_ALL_EXCEPT);
  printf ("%s%s%s%s%s\n", f & FE_INVALID ? " invalid" : "", f & FE_DIVBYZERO ? " divbyzero" : "",
          f & FE_OVERFLOW ? " overflow" : "", f & FE_UNDERFLOW ? " underflow" : "", f & FE_INEXACT ? " inexact" : "");
  feclearexcept (FE_ALL_EXCEPT);
}

int main (void)
{
  for (unsigned i = 0; i < sizeof xs / sizeof xs[0]; i++)
    {
      float x = xs[i], s, c;
      feclearexcept (FE_ALL_EXCEPT);
      printf ("sinf (%a) = %a", (double) x, (double) sinf (x));
      flags ();
      x = xs[i];
      printf ("cosf (%a) = %a", (double) x, (double) cosf (x));
      flags ();
      x = xs[i];
      sincosf (x, &s, &c);
      printf ("sincosf (%a) = %a %a", (double) x, (double) s, (double) c);
      flags ();
    }
  return 0;
}
