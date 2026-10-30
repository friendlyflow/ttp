/* gcc's builtins and GNU C forms that glibc's C uses beyond what the other
   milestones reach (libm, strfrom, wordexp, dl-cache, pidfd_getpid): the
   type-generic classification and quiet comparisons of float, double and
   long double, fabs, copysign, inf, huge_val, nan, signbit, fma and sqrt,
   the overflow builtins, __builtin_types_compatible_p, a pointer to an
   array (const double c[][2]) and, on riscv64, asm statements with float
   register operands ("f"), an immediate ("i") and the float CSR (frsr,
   fssr), as libm has them. The exit status is a hash of every result's
   bits, so gcc + libc.a and ttpc + glibc in ff agree only when every bit
   does. gcc builds it with -fno-math-errno (CFLAGS_gnuc): sqrt is then
   fsqrt, as glibc's own libm is built. */

static unsigned long h = 1469598103934665603UL;

static void mix (unsigned long x) { h = (h ^ x) * 1099511628211UL; }

static void fbits (float x) { union { float f; unsigned int w; } u; u.f = x; mix (u.w); }
static void dbits (double x) { union { double d; unsigned long w; } u; u.d = x; mix (u.w); }
#ifdef __x86_64__
/* (the x87's 80 bits: after the sign and exponent 6 bytes of padding no store writes) */
static void lbits (long double x) { union { long double d; unsigned long w[2]; } u; u.d = x; mix (u.w[0]); mix (u.w[1] & 0xffff); }
#else
static void lbits (long double x) { union { long double d; unsigned long w[2]; } u; u.d = x; mix (u.w[0]); mix (u.w[1]); }
#endif

static volatile float fv[8];
static volatile double dv[8];
static volatile long double lv[8];

/* a value of each class, and one of each sign */
static void values (void)
{
  fv[0] = 1.5f; fv[1] = -0.0f; fv[2] = 1e-40f; fv[3] = -3.25f; fv[4] = 0.0f;
  dv[0] = -2.5; dv[1] = 0.0; dv[2] = 1e-310; dv[3] = 7.0; dv[4] = -0.0;
  lv[0] = 3.25L; lv[1] = -0.0L; lv[3] = -6.5L; lv[4] = 0.0L;
  lv[2] = 1.0L;
  for (int i = 0; i < 16; i++)
    lv[2] = lv[2] * 0x1p-1000;
  lv[2] = lv[2] * 0x1p-400;      /* subnormal */
  fv[5] = __builtin_inff (); fv[6] = -__builtin_huge_valf (); fv[7] = __builtin_nanf ("");
  dv[5] = __builtin_huge_val (); dv[6] = -__builtin_huge_val (); dv[7] = __builtin_nan ("");
  lv[5] = __builtin_huge_vall (); lv[6] = -__builtin_huge_vall (); lv[7] = __builtin_nanl ("");
}

static void classify (void)
{
  for (int i = 0; i < 8; i++)
    {
      float f = fv[i];
      double d = dv[i];
      long double l = lv[i];
      mix (__builtin_fpclassify (0, 1, 4, 3, 2, f));
      mix (__builtin_fpclassify (0, 1, 4, 3, 2, d));
      mix (__builtin_fpclassify (0, 1, 4, 3, 2, l));
      mix (__builtin_isfinite (f) * 4 + __builtin_isfinite (d) * 2 + __builtin_isfinite (l));
      mix (__builtin_isnan (f) * 4 + __builtin_isnan (d) * 2 + __builtin_isnan (l));
      mix (__builtin_isinf_sign (f) * 9 + __builtin_isinf_sign (d) * 3 + __builtin_isinf_sign (l));
      mix ((__builtin_signbit (f) != 0) * 4 + (__builtin_signbit (d) != 0) * 2 + (__builtin_signbit (l) != 0));
      mix ((__builtin_signbitf (f) != 0) * 2 + (__builtin_signbitl (l) != 0));
      fbits (__builtin_fabsf (f));
      dbits (__builtin_fabs (d));
      lbits (__builtin_fabsl (l));
      for (int j = 0; j < 8; j++)
        {
          float g = fv[j];
          double e = dv[j];
          long double m = lv[j];
          fbits (__builtin_copysignf (f, g));
          dbits (__builtin_copysign (d, e));
          lbits (__builtin_copysignl (l, m));
          mix (__builtin_isunordered (f, g) + 2 * __builtin_isless (f, g) + 4 * __builtin_islessequal (f, g)
               + 8 * __builtin_isgreater (f, g) + 16 * __builtin_isgreaterequal (f, g));
          mix (__builtin_isunordered (d, e) + 2 * __builtin_isless (d, e) + 4 * __builtin_islessequal (d, e)
               + 8 * __builtin_isgreater (d, e) + 16 * __builtin_isgreaterequal (d, e));
          mix (__builtin_isunordered (l, m) + 2 * __builtin_isless (l, m) + 4 * __builtin_islessequal (l, m)
               + 8 * __builtin_isgreater (l, m) + 16 * __builtin_isgreaterequal (l, m));
        }
    }
}

static void fused (void)
{
  volatile double a = 1.0 + 0x1p-30, b = 1.0 - 0x1p-30, c = -1.0, two = 2.0;
  volatile float fa = 1.0f + 0x1p-12f, fb = 1.0f - 0x1p-12f, fc = -1.0f, ftwo = 2.0f;
  dbits (__builtin_fma (a, b, c));
  fbits (__builtin_fmaf (fa, fb, fc));
  dbits (__builtin_sqrt (two));
  fbits (__builtin_sqrtf (ftwo));
  for (int i = 0; i < 5; i++)
    {
      dbits (__builtin_sqrt (__builtin_fabs (dv[i]) + 3.0));
      fbits (__builtin_sqrtf (__builtin_fabsf (fv[i]) + 5.0f));
      dbits (__builtin_fma (dv[i], dv[(i + 1) % 5], dv[(i + 2) % 5]));
      fbits (__builtin_fmaf (fv[i], fv[(i + 1) % 5], fv[(i + 2) % 5]));
    }
}

static volatile unsigned long A[] = { 0, 1, 5, 0x7fffffffffffffffUL, 0xfffffffffffffff0UL, 0xffffffffffffffffUL };
static volatile unsigned int B[] = { 0, 1, 16, 0xffffffffU };
static volatile int I[] = { 0, 1, -1, -6, 7, 0x7fffffff, -0x7fffffff - 1, 46341, -46341 };

static void overflow (void)
{
  unsigned long r;
  int ir;
  for (int i = 0; i < 6; i++)
    {
      for (int j = 0; j < 4; j++)
        {
          int o = __builtin_add_overflow (A[i], B[j], &r);
          mix (r);
          mix (o);
        }
      for (int j = 0; j < 9; j++)
        {
          int o = __builtin_add_overflow (A[i], I[j], &r);
          mix (r);
          mix (o);
        }
    }
  for (int i = 0; i < 9; i++)
    for (int j = 0; j < 9; j++)
      {
        int o = __builtin_mul_overflow (I[i], I[j], &ir);
        mix ((unsigned int) ir);
        mix (o);
      }
}

static const double tab[][2] = { { 1.0, 2.0 }, { 3.0, 4.0 }, { 5.0, 6.0 } };

static double rows (int n, const double c[][2])
{
  double s = 0;
  for (int i = 0; i < n; i++)
    s += c[i][0] * 10 + c[i][1];
  return s;
}

static void gnu (void)
{
  const double (*p)[2] = tab + 1;
  dbits (rows (3, tab));
  dbits (p[1][1]);
  mix (__builtin_types_compatible_p (double, float));
  mix (__builtin_types_compatible_p (const int, int));
}

#ifdef __riscv
/* libm's asm statements: fclass, the conversions with their rounding
   modes, fmin and fmax, a result in a float register, the float CSR */
static void riscv (void)
{
  long r, cls;
  int ir;
  double d, m;
  float f;
  unsigned int env, old;
  for (int i = 0; i < 8; i++)
    {
      double x = dv[i];
      float fx = fv[i];
      asm ("fclass.d %0, %1" : "=r" (cls) : "f" (x));
      mix (cls);
      asm ("fclass.s %0, %1" : "=r" (cls) : "f" (fx));
      mix (cls);
      if (i == 7 || i == 5 || i == 6)
        continue;
      asm ("fcvt.l.d %0, %1, rmm" : "=r" (r) : "f" (x));
      mix (r);
      asm ("fcvt.l.d %0, %1, rtz" : "=r" (r) : "f" (x));
      mix (r);
      asm volatile ("fcvt.w.s %0, %1, rdn" : "=r" (ir) : "f" (fx));
      mix (ir);
      asm ("fmax.d %0, %1, %2" : "=f" (m) : "f" (x), "f" (dv[(i + 3) % 5]));
      dbits (m);
      asm ("fmin.s %0, %1, %2" : "=f" (f) : "f" (fx), "f" (fv[(i + 3) % 5]));
      fbits (f);
      asm ("fcvt.d.l %0, %1" : "=f" (d) : "r" (r));
      dbits (d);
      asm volatile ("fcvt.s.w %0, %1, rup" : "=f" (f) : "r" (ir));
      fbits (f);
    }
  /* the flags: the quiet comparisons above raised no invalid */
  asm volatile ("frsr %0" : "=r" (old));
  asm volatile ("fssr %z0" : : "rJ" (0));
  for (int i = 0; i < 8; i++)
    mix (__builtin_isless (dv[i], dv[7]) + __builtin_isgreater (lv[7], lv[i]) + __builtin_islessequal (fv[7], fv[i]));
  asm volatile ("frsr %0" : "=r" (env));
  mix (env & 0x10);
  asm volatile ("fssr %z0" : : "rJ" (1));
  asm volatile ("csrrc %0, fcsr, %1" : "=r" (env) : "i" ((0x01) | (0x08) | (0x02) | (0x04) | (0x10)));
  mix (env);
  asm volatile ("frsr %0" : "=r" (env));
  mix (env);
  asm volatile ("fssr %z0" : : "rJ" (old));
}
#endif

int main (void)
{
  values ();
  classify ();
  fused ();
  overflow ();
  gnu ();
#ifdef __riscv
  riscv ();
#endif
  return h % 251;
}
