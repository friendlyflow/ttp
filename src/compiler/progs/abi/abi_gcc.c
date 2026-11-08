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
#if defined __x86_64__
int g_write (const char *s, int n)
{ long r; __asm__ volatile ("syscall" : "=a" (r) : "0" (1L), "D" (1L), "S" (s), "d" ((long) n) : "rcx", "r11", "memory"); return r; }
#elif defined __aarch64__
int g_write (const char *s, int n)
{ register long x0 __asm__ ("x0") = 1; register const char *x1 __asm__ ("x1") = s;
  register long x2 __asm__ ("x2") = n; register long x8 __asm__ ("x8") = 64;
  __asm__ volatile ("svc 0" : "+r" (x0) : "r" (x1), "r" (x2), "r" (x8) : "memory"); return x0; }
#elif defined __riscv
int g_write (const char *s, int n)
{ register long a0 __asm__ ("a0") = 1; register const char *a1 __asm__ ("a1") = s;
  register long a2 __asm__ ("a2") = n; register long a7 __asm__ ("a7") = 64;
  __asm__ volatile ("ecall" : "+r" (a0) : "r" (a1), "r" (a2), "r" (a7) : "memory"); return a0; }
#else
int g_write (const char *s, int n)
{ register int r0 __asm__ ("r0") = 1; register const char *r1 __asm__ ("r1") = s;
  register int r2 __asm__ ("r2") = n; register int r7 __asm__ ("r7") = 4;
  __asm__ volatile ("svc 0" : "+r" (r0) : "r" (r1), "r" (r2), "r" (r7) : "memory"); return r0; }
#endif
#if defined __aarch64__ || defined __x86_64__ || defined __riscv
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
#ifdef __arm__
double f_pcs (float a, double b, int c, double d, float e) { return a + 2 * b + 3 * c + 4 * d + 5 * e; }
float f_pcsf (int a, float b) { return a + 2 * b; }
double g_pcs (void) { return cb_pcs (1.5f, 2.25, 3, 4.5, 5.5f); }
float g_pcsf (void) { return cb_pcsf (7, 1.25f); }
static volatile int ki[16] = { 0x4004, 0x5005, 0x6006, 0x7007, 0x8008, 0x9009, 0xa00a, 0xb00b,
  -8, 9, -10, 11, -12, 13, -14, 15 };
#define kd (ki + 8)
int g_keep (void)
{ register int r4 asm ("r4") = ki[0], r5 asm ("r5") = ki[1], r6 asm ("r6") = ki[2], r7 asm ("r7") = ki[3];
  register int r8 asm ("r8") = ki[4], r9 asm ("r9") = ki[5], r10 asm ("r10") = ki[6], r11 asm ("r11") = ki[7];
  register double d8 asm ("d8") = kd[0], d9 asm ("d9") = kd[1], d10 asm ("d10") = kd[2], d11 asm ("d11") = kd[3];
  register double d12 asm ("d12") = kd[4], d13 asm ("d13") = kd[5], d14 asm ("d14") = kd[6], d15 asm ("d15") = kd[7];
  long long v;
  int bad;
  asm volatile ("" : "+r" (r4), "+r" (r5), "+r" (r6), "+r" (r7), "+r" (r8), "+r" (r9), "+r" (r10), "+r" (r11));
  asm volatile ("" : "+w" (d8), "+w" (d9), "+w" (d10), "+w" (d11), "+w" (d12), "+w" (d13), "+w" (d14), "+w" (d15));
  v = cb_keep (5, 0x123456789LL, 2.5);
  asm volatile ("" : "+r" (r4), "+r" (r5), "+r" (r6), "+r" (r7), "+r" (r8), "+r" (r9), "+r" (r10), "+r" (r11));
  asm volatile ("" : "+w" (d8), "+w" (d9), "+w" (d10), "+w" (d11), "+w" (d12), "+w" (d13), "+w" (d14), "+w" (d15));
  bad = (r4 != ki[0]) | (r5 != ki[1]) << 1 | (r6 != ki[2]) << 2 | (r7 != ki[3]) << 3
      | (r8 != ki[4]) << 4 | (r9 != ki[5]) << 5 | (r10 != ki[6]) << 6 | (r11 != ki[7]) << 7
      | (d8 != kd[0]) << 8 | (d9 != kd[1]) << 9 | (d10 != kd[2]) << 10 | (d11 != kd[3]) << 11
      | (d12 != kd[4]) << 12 | (d13 != kd[5]) << 13 | (d14 != kd[6]) << 14 | (d15 != kd[7]) << 15;
  return bad | (v != 39738643342LL) << 16; }
#endif
#ifdef __x86_64__
ld1 r_ld1 (long double a) { ld1 r = { a * 2 }; return r; }
cld r_cld (long double re, long double im) { cld z; __real__ z = re; __imag__ z = im; return z; }
long double g_ld1 (void) { return cb_ld1 (5.0L).x; }
long double g_cld (void) { cld z = cb_cld (2.0L, 3.0L); return __real__ z * 10 + __imag__ z; }
cq r_cq (__float128 re, __float128 im) { cq z; __real__ z = re; __imag__ z = im; return z; }
static int same_q (__float128 a, __float128 b) { unsigned long *x = (void *) &a, *y = (void *) &b; return x[0] == y[0] && x[1] == y[1]; }
int eq_cq (cq z, __float128 re, __float128 im) { return same_q (__real__ z, re) && same_q (__imag__ z, im); }
int g_cq (void) { cq a = r_cq (2.0Q, 3.0Q); cq z = cb_cq (a); return same_q (__real__ z, 3.0Q) && same_q (__imag__ z, 2.0Q); }
#endif
#if defined __x86_64__ || defined __riscv
long f_dl (dl a, dl b, dl c, dl d, dl e, dl f, dl g)
{ return a.l + 2 * b.l + 3 * c.l + 4 * d.l + 5 * e.l + 6 * f.l + 7 * g.l + (long) (2 * (a.d + b.d + c.d + d.d + e.d + f.d + g.d)); }
double f_ifl (ifl a, fid b) { return a.i + 2 * a.f + 3 * b.f + 4 * b.i + 8 * b.d; }
dl r_dl (double d, long l) { dl r = { d, l }; return r; }
fid r_fid (float f, int i, double d) { fid r = { f, i, d }; return r; }
/* n pairs of (s16, s24) */
long f_vs (int n, ...)
{ va_list ap; long s = 0; va_start (ap, n);
  for (int i = 0; i < n; i++) { s16 x = va_arg (ap, s16); s24 y = va_arg (ap, s24); s += x.a + 2 * x.b + 3 * y.a + 4 * y.b + 5 * y.c; }
  va_end (ap); return s; }
long g_dl (void)
{ dl a = { 1.5, 1 }, b = { 2.5, 2 }, c = { 3.5, 3 }, d = { 4.5, 4 }, e = { 5.5, 5 }, f = { 6.5, 6 }, g = { 7.5, 7 };
  return cb_dl (a, b, c, d, e, f, g); }
double g_r_dl (void) { dl r = cb_r_dl (2.5, 7); return r.d + r.l; }
double g_r_fid (void) { fid r = cb_r_fid (1.5f, 3, 4.25); return r.f + r.i + r.d; }
long g_vs (void)
{ s16 x1 = { 1, 2 }, x2 = { 6, 7 }, x3 = { 11, 12 }; s24 y1 = { 3, 4, 5 }, y2 = { 8, 9, 10 }, y3 = { 13, 14, 15 };
  return cb_vs (3, x1, y1, x2, y2, x3, y3); }
#endif
#ifdef __riscv
long f_ff2 (ff2 a, fi b, d1 c, cd d) { return a.a + 2 * a.b + 3 * b.f + 4 * b.i + 5 * c.d + 6 * d.c + 7 * d.d; }
double f_fpout (double a, double b, double c, double d, double e, double f, double g, hd2 x, ff2 y)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * x.x + 9 * x.y + 10 * y.a + 11 * y.b; }
double f_gpout (int a, int b, int c, int d, int e, int f, int g, int h, mix x, double y)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * x.a + 10 * x.b + 11 * y; }
long double f_ldsplit (int a, int b, int c, int d, int e, int f, int g, long double x, int h)
{ return a + b + c + d + e + f + g == 28 && h == 8 ? x : 0.0L; }
/* the register as the caller left it */
long f_raw4 (unsigned a) { long r; __asm__ ("mv %0, %1" : "=r" (r) : "r" (a)); return r; }
long f_raw2 (unsigned short a) { long r; __asm__ ("mv %0, %1" : "=r" (r) : "r" (a)); return r; }
long f_raw1 (signed char a) { long r; __asm__ ("mv %0, %1" : "=r" (r) : "r" (a)); return r; }
ff2 r_ff2 (float a) { ff2 r = { a, a + 1 }; return r; }
fi r_fi (float f, int i) { fi r = { f, i }; return r; }
cd r_cd (char c, double d) { cd r = { c, d }; return r; }
long g_ff2 (void) { ff2 a = { 1, 2 }; fi b = { 3, 4 }; d1 c = { 5 }; cd d = { 6, 7 }; return cb_ff2 (a, b, c, d); }
double g_fpout (void) { hd2 x = { 8, 9 }; ff2 y = { 10, 11 }; return cb_fpout (1, 2, 3, 4, 5, 6, 7, x, y); }
double g_gpout (void) { mix x = { 9, 10 }; return cb_gpout (1, 2, 3, 4, 5, 6, 7, 8, x, 11); }
long double g_ldsplit (void) { return cb_ldsplit (1, 2, 3, 4, 5, 6, 7, 9.0L, 8); }
int g_narrow (void) { return cb_narrow (0xffffffffu, 0xffff, -1, -1); }
/* the result's register as the callee left it */
int g_u32 (void) { long r; unsigned v = cb_u32 (-1); __asm__ ("mv %0, %1" : "=r" (r) : "r" (v)); return r == -1; }
int g_u16 (void) { long r; unsigned short v = cb_u16 (-1); __asm__ ("mv %0, %1" : "=r" (r) : "r" (v)); return r == 0xffff; }
double g_r_fi (void) { fi r = cb_r_fi (1.5f, 3); return r.f + r.i; }
double g_r_cd (void) { cd r = cb_r_cd (5, 2.25); return r.c + r.d; }
#endif
#ifdef __SIZEOF_INT128__
i128_t f_q2 (i128_t a, i128_t b) { return W2 (a, b); }
i128_t f_q4 (int a, i128_t b, int c, i128_t d) { return W4 (a, b, c, d); }
i128_t f_q9 (long a, long b, long c, long d, long e, i128_t f, long g, i128_t h, long i) { return W6 (a + b, c + d, e, f, h, g + 2 * i); }
u128_t f_q8 (long a, long b, long c, long d, long e, long f, long g, u128_t h, long i) { return W4 (a + b + c, d + e + f, g, h) + i; }
i128_t f_q6 (i128_t a, i128_t b, i128_t c, i128_t d, i128_t e, long f) { return W6 (a, b, c, d, e, f); }
i128_t f_qs (si a, sli b, sdi c, si d) { return W6 (a.x, b.a, b.x, qbits (c.d), c.x, d.x); }
si r_qs (i128_t a) { si r = { a + 1 }; return r; }
sli r_qsl (long a, i128_t b) { sli r = { a + 1, b + 2 }; return r; }
i128_t f_qv (int n, ...)
{ va_list ap; i128_t s = 0; va_start (ap, n);
  for (int i = 0; i < n; i++) { s += va_arg (ap, int); s = 3 * s + va_arg (ap, i128_t); s = 3 * s + qbits (va_arg (ap, double)); }
  va_end (ap); return s; }
i128_t g_q2 (void) { return cb_q2 (BIG (1), BIG (2)); }
i128_t g_q4 (void) { return cb_q4 (1, BIG (2), 3, BIG (4)); }
i128_t g_q9 (void) { return cb_q9 (1, 2, 3, 4, 5, BIG (6), 7, BIG (8), 9); }
u128_t g_q8 (void) { return cb_q8 (1, 2, 3, 4, 5, 6, 7, BIG (8), 9); }
i128_t g_q6 (void) { return cb_q6 (BIG (1), BIG (2), BIG (3), BIG (4), BIG (5), 6); }
/* (not constants: an aarch64 16-byte constant's label loses its alignment in s2ff) */
__attribute__ ((noipa)) static long q_one (void) { return 1; }
i128_t g_qs (void) { long u = q_one (); si a = { BIG (u) }; sli b = { 2, BIG (3 * u) }; sdi c = { 4.0, BIG (5 * u) }; si d = { BIG (6 * u) }; return cb_qs (a, b, c, d); }
i128_t g_r_qs (void) { si r = cb_r_qs (BIG (1)); return r.x; }
i128_t g_r_qsl (void) { sli r = cb_r_qsl (5, BIG (1)); return r.a + r.x; }
i128_t g_qv (void) { return cb_qv (3, 1, BIG (2), 3.0, 4, BIG (5), 6.0, 7, BIG (8), 9.0); }
#endif
#if defined __x86_64__ || defined __aarch64__ || defined __riscv
h_t f_h2 (h_t a, h_t b) { return b; }
b_t f_b2 (int a, b_t b, float c) { return b; }
h_t f_h10 (h_t a, h_t b, h_t c, h_t d, h_t e, h_t f, h_t g, h_t h, h_t i, h_t j) { return j; }
int f_hsum (h_t a, double b, h_t c, long d, b_t e) { return HB (a) + 2 * HB (c) + 3 * d + 4 * BB (e); }
int f_h2s (h2 a, hin b, h5 c) { return HB (a.x) + 2 * HB (a.y) + 3 * HB (b.x) + 5 * b.i + 7 * HB (c.a) + 11 * HB (c.e); }
h2 r_h2 (unsigned short a, unsigned short b) { h2 r = { H (a), H (b) }; return r; }
hin r_hin (unsigned short a, int i) { hin r = { H (a), i }; return r; }
h_t f_hci (int n, hc_t z, h_t a) { return n == 1 ? __real__ z : n == 2 ? __imag__ z : a; }
hc_t r_hc (h_t a, h_t b) { hc_t r; __real__ r = a; __imag__ r = b; return r; }
int g_hci (void) { hc_t z; __real__ z = H (1); __imag__ z = H (2); return HB (cb_hci (1, z, H (3))) == 1 && HB (cb_hci (2, z, H (3))) == 2 && HB (cb_hci (3, z, H (3))) == 3; }
int g_r_hc (void) { hc_t z = cb_r_hc (H (1), H (2)); return HB (__real__ z) == 1 && HB (__imag__ z) == 2; }
int g_h2 (void) { return HB (cb_h2 (H (0x3c00), H (0x3e00))) == 0x3e00; }
int g_b2 (void) { return BB (cb_b2 (1, B (0x3f80), 2.0f)) == 0x3f80; }
int g_h10 (void) { return HB (cb_h10 (H (1), H (2), H (3), H (4), H (5), H (6), H (7), H (8), H (9), H (10))) == 10; }
int g_hsum (void) { return cb_hsum (H (1), 2.0, H (3), 4, B (5)) == 1 + 6 + 12 + 20; }
int g_h2s (void) { h2 a = { H (1), H (2) }; hin b = { H (3), 4 }; h5 c = { H (5), H (0), H (0), H (0), H (6) }; return cb_h2s (a, b, c) == 1 + 4 + 9 + 20 + 35 + 66; }
int g_r_h2 (void) { h2 r = cb_r_h2 (1, 2); return HB (r.x) == 1 && HB (r.y) == 2; }
int g_r_hin (void) { hin r = cb_r_hin (1, 2); return HB (r.x) == 1 && r.i == 2; }
#endif
#ifdef __arm__
ah_t f_ah2 (ah_t a, ah_t b) { return b; }
ah_t f_ah3 (ah_t a, double b, float c, int d, ah_t e) { return e; }
int g_ah2 (void) { return AB (cb_ah2 (AH (0x3c00), AH (0x3e00))) == 0x3e00; }
int g_ah3 (void) { return AB (cb_ah3 (AH (1), 2.0, 3.0f, 4, AH (5))) == 5; }
#endif
#ifdef __arm__
long _Accum f_fx (short _Fract a, long _Accum b, _Accum c, long _Accum d, _Sat _Fract e, unsigned _Accum f) { return d; }
int f_fxc (short _Fract a, long _Accum b, _Accum c, long _Accum d, _Sat _Fract e, unsigned _Accum f) { return *(signed char *) &a == 0x40 && *(int *) &c == 0x12000 && *(short *) &e == 0x2000 && *(unsigned *) &f == 0x18000; }
fxs f_fxs (fxs a, long _Accum b) { a.y = (_Accum) 0; *(int *) &a.y = (int) *(long long *) &b; return a; }
int g_fx (void) { long _Accum v = cb_fx (0.5hr, 1.5lk, 2.25k, -3.5lk, 0.25r, 1.5uk); return *(long long *) &v == -7516192768LL; }
int g_fxc (void) { return cb_fxc (0.5hr, 1.5lk, 2.25k, -3.5lk, 0.25r, 1.5uk); }
int g_fxs (void) { fxs a = { 0.5r, 0.0k }; fxs r = cb_fxs (a, 1.5lk); return *(short *) &r.x == 0x4000 && *(int *) &r.y == (int) 0xc0000000; }
#endif
