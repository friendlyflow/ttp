/* abi_gcc.c — the functions gcc compiles for the ABI test (abi.h) */
#include "abi.h"
#include <stdarg.h>
int f_i6 (int a, int b, int c, int d, int e, int f) { return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f; }
long long f_ll (int a, long long b, int c, long long d, long long e) { return a + 2 * b + 3 * c + 4 * d + 5 * e; }
double f_d (double a, int b, float c, double d, float e, double f, double g, double h, double i, double j, float k)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * i + 10 * j + 11 * k; }
float f_f (float a, float b, int c, float d) { return a + 2 * b + 3 * c + 4 * d; }
int f_s (s4 a, s8 b, s12 c, s20 d, int e)
{ return a.a + 2 * a.b + 3 * b.a + 4 * b.b + 5 * c.a + 6 * c.b + 7 * c.c + 8 * d.a + 9 * d.b + 10 * d.c + 11 * d.d + 12 * d.e + 13 * e; }
float f_hf3 (hf3 a, float b, hf3 c) { return a.x + 2 * a.y + 3 * a.z + 4 * b + 5 * c.x + 6 * c.y + 7 * c.z; }
double f_hd2 (int a, hd2 b, double c) { return a + 2 * b.x + 3 * b.y + 4 * c; }
double f_mix (mix a, int b, mix c) { return a.a + 2 * a.b + 3 * b + 4 * c.a + 5 * c.b; }
s4 r_s4 (int a) { s4 r = { a, a + 1 }; return r; }
s8 r_s8 (int a) { s8 r = { a, a + 1 }; return r; }
s20 r_s20 (int a) { s20 r = { a, a + 1, a + 2, a + 3, a + 4 }; return r; }
hf3 r_hf3 (float a) { hf3 r = { a, a + 1, a + 2 }; return r; }
hd2 r_hd2 (double a) { hd2 r = { a, a + 1 }; return r; }
long long r_ll (long long a) { return a * 3; }
double r_d (double a) { return a * 3; }
/* n pairs of (int, long long) */
long long f_var (int n, ...)
{ va_list ap; long long s = 0; va_start (ap, n);
  for (int i = 0; i < n; i++) { s += va_arg (ap, int); s += 2 * va_arg (ap, long long); }
  va_end (ap); return s; }
/* n pairs of (int, double) */
double f_vard (int n, ...)
{ va_list ap; double s = 0; va_start (ap, n);
  for (int i = 0; i < n; i++) { s += va_arg (ap, int); s += 2 * va_arg (ap, double); }
  va_end (ap); return s; }
int g_i6 (void) { return cb_i6 (1, 2, 3, 4, 5, 6); }
long long g_ll (void) { return cb_ll (1, 0x100000002LL, 3, 0x400000005LL, 0x600000007LL); }
double g_d (void) { return cb_d (1.5, 2, 3.5f, 4.25, 5.5f, 6.0, 7.0, 8.0, 9.0, 10.0, 11.5f); }
int g_s (void)
{ s4 a = { 1, 2 }; s8 b = { 3, 4 }; s12 c = { 5, 6, 7 }; s20 d = { 8, 9, 10, 11, 12 };
  return cb_s (a, b, c, d, 13); }
int g_r_s20 (void) { s20 r = cb_r_s20 (10); return r.a + r.b + r.c + r.d + r.e; }
double g_r_hd2 (void) { hd2 r = cb_r_hd2 (2.5); return r.x + 2 * r.y; }
long long g_var (void) { return cb_var (3, 1, 0x100000000LL, 2, 0x200000000LL, 3, 3LL); }
long long g_ptr (long long (*f) (int, long long, int, long long, long long)) { return f (1, 2, 3, 4, 5); }
#ifdef __aarch64__
int g_write (const char *s, int n)
{ register long x0 __asm__ ("x0") = 1; register const char *x1 __asm__ ("x1") = s;
  register long x2 __asm__ ("x2") = n; register long x8 __asm__ ("x8") = 64;
  __asm__ volatile ("svc 0" : "+r" (x0) : "r" (x1), "r" (x2), "r" (x8) : "memory"); return x0; }
#else
int g_write (const char *s, int n)
{ register int r0 __asm__ ("r0") = 1; register const char *r1 __asm__ ("r1") = s;
  register int r2 __asm__ ("r2") = n; register int r7 __asm__ ("r7") = 4;
  __asm__ volatile ("svc 0" : "+r" (r0) : "r" (r1), "r" (r2), "r" (r7) : "memory"); return r0; }
#endif
#ifdef __aarch64__
long f_i10 (int a, int b, int c, int d, int e, int f, int g, int h, int i, int j)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * i + 10 * j; }
double f_mixn (int a, double b, int c, double d, int e, double f, int g, double h, int i, double j, int k, double l,
               int m, double n, int o, double p, int q, double r, int s, float t)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * i + 10 * j + 11 * k + 12 * l
    + 13 * m + 14 * n + 15 * o + 16 * p + 17 * q + 18 * r + 19 * s + 20 * t; }
long f_s16 (int a, int b, int c, int d, int e, int f, int g, s16 x, int h)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * x.a + 9 * x.b + 10 * h; }
long f_s16r (int a, s16 x, s16 y) { return a + 2 * x.a + 3 * x.b + 4 * y.a + 5 * y.b; }
long f_s24 (s24 x, int y) { return x.a + 2 * x.b + 3 * x.c + 4 * y; }
long f_s24mod (s24 x) { x.a = 99; return x.a + x.b + x.c; }
long f_s24stk (int a, int b, int c, int d, int e, int f, int g, int h, s24 x, int y)
{ return a + b + c + d + e + f + g + h + 2 * x.a + 3 * x.b + 4 * x.c + 5 * y; }
double f_hd4 (hd4 a, hd4 b, hd4 c)
{ return a.a + 2 * a.b + 3 * a.c + 4 * a.d + 5 * b.a + 6 * b.b + 7 * b.c + 8 * b.d + 9 * c.a + 10 * c.b + 11 * c.c + 12 * c.d; }
float f_hf4 (float a, hf4 b) { return a + 2 * b.a + 3 * b.b + 4 * b.c + 5 * b.d; }
hd4 r_hd4 (double a) { hd4 r = { a, a + 1, a + 2, a + 3 }; return r; }
hf4 r_hf4 (float a) { hf4 r = { a, a + 1, a + 2, a + 3 }; return r; }
s16 r_s16 (long a) { s16 r = { a, a + 1 }; return r; }
long double f_ld (int a, long double b, double c, long double d) { return a == 1 && c == 2.5 ? d : b; }
long double r_ld2 (hq2 a) { return a.b; }
hq2 r_hq2 (long double a, long double b) { hq2 r = { b, a }; return r; }
/* the n-th of its long doubles */
long double f_varld (int n, ...)
{ va_list ap; long double r = 0.0L; va_start (ap, n);
  for (int i = 0; i < n; i++) { (void) va_arg (ap, double); r = va_arg (ap, long double); }
  va_end (ap); return r; }
/* n pairs of (int, double) from a va_list */
long long f_vsum (int n, va_list ap)
{ double s = 0; for (int i = 0; i < n; i++) { s += va_arg (ap, int); s += 3 * va_arg (ap, double); } return s; }
long long f_vwrap (int n, ...) { va_list ap; va_start (ap, n); long long r = cb_vsum (n, ap); va_end (ap); return r; }
long g_i10 (void) { return cb_i10 (1, 2, 3, 4, 5, 6, 7, 8, 9, 10); }
double g_mixn (void) { return cb_mixn (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20); }
long g_s16 (void) { s16 x = { 8, 9 }; return cb_s16 (1, 2, 3, 4, 5, 6, 7, x, 10); }
long g_s24mod (void) { s24 x = { 1, 2, 3 }; long r = cb_s24mod (x); return x.a == 1 ? r : -1; }
double g_hd4 (void) { hd4 a = { 1, 2, 3, 4 }, b = { 5, 6, 7, 8 }, c = { 9, 10, 11, 12 }; return cb_hd4 (a, b, c); }
float g_f (void) { return cb_f (1.5f, 2.5f, 3, 4.25f); }
double g_r_hd4 (void) { hd4 r = cb_r_hd4 (1.5); return r.a + 2 * r.b + 3 * r.c + 4 * r.d; }
long g_r_s16 (void) { s16 r = cb_r_s16 (100); return r.a + 2 * r.b; }
long double g_ld (void) { return cb_ld (1, 3.0L, 2.5, 7.0L); }
long double g_varld (void) { return cb_varld (3, 1.0, 1.0L, 2.0, 2.0L, 3.0, 3.0L); }
long long g_vard (void) { return cb_vard (10, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5); }
#endif
