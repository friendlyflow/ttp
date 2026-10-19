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
int g_write (const char *s, int n)
{ register int r0 __asm__ ("r0") = 1; register const char *r1 __asm__ ("r1") = s;
  register int r2 __asm__ ("r2") = n; register int r7 __asm__ ("r7") = 4;
  __asm__ volatile ("svc 0" : "+r" (r0) : "r" (r1), "r" (r2), "r" (r7) : "memory"); return r0; }
