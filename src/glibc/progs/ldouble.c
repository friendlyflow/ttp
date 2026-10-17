/* long double, through glibc's soft-fp (the same functions gcc takes from
   libgcc): + - * /, the comparisons, negation, and the conversions to and
   from the integers, float and double. The exit status is a hash of the
   bits of every result, so gcc + libc.a and ttpc + glibc in ff agree only
   when every bit does. */

static unsigned long h = 1469598103934665603UL;

static void mix (unsigned long x) { h = (h ^ x) * 1099511628211UL; }

static void bits (long double x)
{
  union { long double d; unsigned long w[2]; } u;
  u.d = x;
  mix (u.w[0]);
  mix (u.w[1]);
}

static void dbits (double x)
{
  union { double d; unsigned long w; } u;
  u.d = x;
  mix (u.w);
}

static void fbits (float x)
{
  union { float f; unsigned int w; } u;
  u.f = x;
  mix (u.w);
}

int
main (void)
{
  volatile long double a = 1.5L, b = -2.25L, c = 3.0L, z = 0.0L;
  volatile long double big = 1e300, tiny = 0x1p-1000;
  volatile long n = -7, m = 1234567890123456789L;
  volatile unsigned long u = 18446744073709551615UL;
  volatile double d = 0.1;
  volatile float f = 0.1f;

  bits (a + b);
  bits (a - b);
  bits (a * b);
  bits (a / b);
  bits (b / c);
  bits (big * big);
  bits (tiny * tiny);
  bits (a / z);
  bits (z / z * 0 + a);
  bits (-a);
  bits (-z);
  mix (a < b); mix (a <= b); mix (a > b); mix (a >= b); mix (a == b); mix (a != b);
  mix (c == c); mix (z == -z); mix (b < a);

  bits ((long double) n);
  bits ((long double) m);
  bits ((long double) u);
  bits ((long double) d);
  bits ((long double) f);
  mix ((unsigned long) (long) (b * c));
  mix ((unsigned long) (c * c * c));
  mix ((unsigned long) (long) (m * a));
  dbits ((double) (a / c));
  dbits ((double) (b / c));
  fbits ((float) (a / c));
  fbits ((float) (big));

  long double s = 0;
  for (int i = 1; i <= 50; i++)
    s += 1.0L / i;
  bits (s);
  s = 1;
  for (int i = 0; i < 30; i++)
    s = s * 3 - s / 7;
  bits (s);

  return (int) ((h ^ (h >> 8) ^ (h >> 16) ^ (h >> 24) ^ (h >> 32) ^ (h >> 40) ^ (h >> 48) ^ (h >> 56)) & 255);
}
