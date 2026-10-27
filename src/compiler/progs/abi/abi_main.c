/* abi_main.c — the ttpc side of the ABI test: calls gcc's functions
   (abi_gcc.c) with every shape abi.h has, defines the callbacks gcc's code
   calls, and checks each result. Exits with the count of failures. */
#include "abi.h"
#include <stdarg.h>
static int fails;
static int len (const char *s) { int n = 0; while (s[n]) n++; return n; }
static void check (int ok, const char *name)
{ if (ok) g_write ("ok ", 3); else { g_write ("FAIL ", 5); fails++; }
  g_write (name, len (name)); g_write ("\n", 1); }
int cb_i6 (int a, int b, int c, int d, int e, int f) { return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f; }
long long cb_ll (int a, long long b, int c, long long d, long long e) { return a + 2 * b + 3 * c + 4 * d + 5 * e; }
double cb_d (double a, int b, float c, double d, float e, double f, double g, double h, double i, double j, float k)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * i + 10 * j + 11 * k; }
int cb_s (s4 a, s8 b, s12 c, s20 d, int e)
{ return a.a + 2 * a.b + 3 * b.a + 4 * b.b + 5 * c.a + 6 * c.b + 7 * c.c + 8 * d.a + 9 * d.b + 10 * d.c + 11 * d.d + 12 * d.e + 13 * e; }
s20 cb_r_s20 (int a) { s20 r = { a, a + 1, a + 2, a + 3, a + 4 }; return r; }
hd2 cb_r_hd2 (double a) { hd2 r = { a, a + 1 }; return r; }
long long cb_var (int n, ...)
{ va_list ap; long long s = 0; va_start (ap, n);
  for (int i = 0; i < n; i++) { s += va_arg (ap, int); s += 2 * va_arg (ap, long long); }
  va_end (ap); return s; }
#if defined __aarch64__ || defined __x86_64__ || defined __riscv
long cb_i10 (int a, int b, int c, int d, int e, int f, int g, int h, int i, int j)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * i + 10 * j; }
double cb_mixn (int a, double b, int c, double d, int e, double f, int g, double h, int i, double j, int k, double l,
                int m, double n, int o, double p, int q, double r, int s, float t)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * i + 10 * j + 11 * k + 12 * l
    + 13 * m + 14 * n + 15 * o + 16 * p + 17 * q + 18 * r + 19 * s + 20 * t; }
long cb_s16 (int a, int b, int c, int d, int e, int f, int g, s16 x, int h)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * x.a + 9 * x.b + 10 * h; }
long cb_s24mod (s24 x) { x.a = 99; return x.a + x.b + x.c; }
double cb_hd4 (hd4 a, hd4 b, hd4 c)
{ return a.a + 2 * a.b + 3 * a.c + 4 * a.d + 5 * b.a + 6 * b.b + 7 * b.c + 8 * b.d + 9 * c.a + 10 * c.b + 11 * c.c + 12 * c.d; }
float cb_f (float a, float b, int c, float d) { return a + 2 * b + 3 * c + 4 * d; }
hd4 cb_r_hd4 (double a) { hd4 r = { a, a + 1, a + 2, a + 3 }; return r; }
s16 cb_r_s16 (long a) { s16 r = { a, a + 1 }; return r; }
long double cb_ld (int a, long double b, double c, long double d) { return a == 1 && c == 2.5 ? d : b; }
long double cb_varld (int n, ...)
{ va_list ap; long double r = 0.0L; va_start (ap, n);
  for (int i = 0; i < n; i++) { (void) va_arg (ap, double); r = va_arg (ap, long double); }
  va_end (ap); return r; }
long long cb_vsum (int n, va_list ap)
{ va_list aq; double s = 0; va_copy (aq, ap);
  for (int i = 0; i < n; i++) { s += va_arg (ap, int); s += 3 * va_arg (ap, double); }
  for (int i = 0; i < n; i++) { s += va_arg (aq, int); s += 3 * va_arg (aq, double); }
  va_end (aq); return s; }
long long cb_vard (int n, ...) { va_list ap; va_start (ap, n); long long r = f_vsum (n, ap); va_end (ap); return r; }
/* a long double by its bytes: ttpc's program has no soft-fp to compare */
static int ldeq (long double a, long double b)
{ unsigned char *p = (unsigned char *) &a, *q = (unsigned char *) &b;
  for (int i = 0; i < 16; i++) if (p[i] != q[i]) return 0;
  return 1; }
static void a64 (void)
{
  long (*p_f_i10) (int, int, int, int, int, int, int, int, int, int) = f_i10;
  double (*p_f_mixn) (int, double, int, double, int, double, int, double, int, double, int, double,
                      int, double, int, double, int, double, int, float) = f_mixn;
  long (*p_f_s16) (int, int, int, int, int, int, int, s16, int) = f_s16;
  long (*p_f_s16r) (int, s16, s16) = f_s16r;
  long (*p_f_s24) (s24, int) = f_s24;
  long (*p_f_s24mod) (s24) = f_s24mod;
  long (*p_f_s24stk) (int, int, int, int, int, int, int, int, s24, int) = f_s24stk;
  double (*p_f_hd4) (hd4, hd4, hd4) = f_hd4;
  float (*p_f_hf4) (float, hf4) = f_hf4;
  hd4 (*p_r_hd4) (double) = r_hd4;
  hf4 (*p_r_hf4) (float) = r_hf4;
  s16 (*p_r_s16) (long) = r_s16;
  long double (*p_f_ld) (int, long double, double, long double) = f_ld;
  long double (*p_r_ld2) (hq2) = r_ld2;
  hq2 (*p_r_hq2) (long double, long double) = r_hq2;
  long double (*p_f_varld) (int, ...) = f_varld;
  long long (*p_f_vwrap) (int, ...) = f_vwrap;
  long (*p_g_i10) (void) = g_i10;
  double (*p_g_mixn) (void) = g_mixn;
  long (*p_g_s16) (void) = g_s16;
  long (*p_g_s24mod) (void) = g_s24mod;
  double (*p_g_hd4) (void) = g_hd4;
  float (*p_g_f) (void) = g_f;
  double (*p_g_r_hd4) (void) = g_r_hd4;
  long (*p_g_r_s16) (void) = g_r_s16;
  long double (*p_g_ld) (void) = g_ld;
  long double (*p_g_varld) (void) = g_varld;
  long long (*p_g_vard) (void) = g_vard;
  check (p_f_i10 (1, 2, 3, 4, 5, 6, 7, 8, 9, 10) == 385, "a64: ints on the stack's 8-byte slots");
  check (p_f_mixn (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20) == 2870, "a64: ints and doubles past x7 and v7");
  s16 x = { 8, 9 }, y = { 4, 5 };
  check (p_f_s16 (1, 2, 3, 4, 5, 6, 7, x, 10) == 385, "a64: a 16-byte struct past x7 on the stack");
  check (p_f_s16r (1, x, y) == 1 + 16 + 27 + 16 + 25, "a64: 16-byte structs in x registers");
  s24 z = { 1, 2, 3 };
  check (p_f_s24 (z, 4) == 1 + 4 + 9 + 16, "a64: a 24-byte struct by its copy's address");
  check (p_f_s24mod (z) == 99 + 2 + 3 && z.a == 1, "a64: the callee's copy is its own");
  check (p_f_s24stk (1, 1, 1, 1, 1, 1, 1, 1, z, 2) == 8 + 2 + 6 + 12 + 10, "a64: a copy's address on the stack");
  hd4 a = { 1, 2, 3, 4 }, b = { 5, 6, 7, 8 }, c = { 9, 10, 11, 12 };
  check (p_f_hd4 (a, b, c) == 650, "a64: hfas of four doubles, the third on the stack");
  hf4 f4 = { 1, 2, 3, 4 };
  check (p_f_hf4 (0.5f, f4) == 0.5f + 2 + 6 + 12 + 20, "a64: an hfa of four floats");
  hd4 rd = p_r_hd4 (1.5);
  check (rd.a == 1.5 && rd.d == 4.5, "a64: an hfa of four doubles as a result");
  hf4 rf = p_r_hf4 (1.5f);
  check (rf.a == 1.5f && rf.d == 4.5f, "a64: an hfa of four floats as a result");
  s16 rs = p_r_s16 (7);
  check (rs.a == 7 && rs.b == 8, "a64: a 16-byte struct result in x0 and x1");
  check (ldeq (p_f_ld (1, 3.0L, 2.5, 7.0L), 7.0L), "a64: long doubles in q registers");
  hq2 q2 = { 1.0L, 2.0L };
  check (ldeq (p_r_ld2 (q2), 2.0L), "a64: an hfa of long doubles");
  hq2 rq = p_r_hq2 (1.0L, 2.0L);
  check (ldeq (rq.a, 2.0L) && ldeq (rq.b, 1.0L), "a64: an hfa of long doubles as a result");
  check (ldeq (p_f_varld (2, 1.0, 1.0L, 2.0, 2.0L), 2.0L), "a64: variadic long doubles");
  check (p_f_vwrap (10, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10, 10.5) == 2 * (55 + 180), "a64: gcc's va_list to ttpc's va_arg and va_copy");
  check (p_g_i10 () == 385, "a64: gcc calls ttpc: ints on the stack");
  check (p_g_mixn () == 2870, "a64: gcc calls ttpc: ints and doubles past x7 and v7");
  check (p_g_s16 () == 385, "a64: gcc calls ttpc: a 16-byte struct on the stack");
  check (p_g_s24mod () == 104, "a64: gcc calls ttpc: the callee's copy is its own");
  check (p_g_hd4 () == 650, "a64: gcc calls ttpc: hfas of four doubles");
  check (p_g_f () == 32.5f, "a64: gcc calls ttpc: floats");
  check (p_g_r_hd4 () == 1.5 + 5 + 10.5 + 18, "a64: gcc calls ttpc: an hfa result");
  check (p_g_r_s16 () == 302, "a64: gcc calls ttpc: a 16-byte struct result");
  check (ldeq (p_g_ld (), 7.0L), "a64: gcc calls ttpc: long doubles");
  check (ldeq (p_g_varld (), 3.0L), "a64: gcc calls ttpc: variadic long doubles");
  check (p_g_vard () == 55 + 180, "a64: gcc calls ttpc: variadic doubles past v7, ttpc's va_list to gcc");
}
#endif
#if defined __x86_64__ || defined __riscv
long cb_dl (dl a, dl b, dl c, dl d, dl e, dl f, dl g)
{ return a.l + 2 * b.l + 3 * c.l + 4 * d.l + 5 * e.l + 6 * f.l + 7 * g.l + (long) (2 * (a.d + b.d + c.d + d.d + e.d + f.d + g.d)); }
dl cb_r_dl (double d, long l) { dl r = { d, l }; return r; }
fid cb_r_fid (float f, int i, double d) { fid r = { f, i, d }; return r; }
long cb_vs (int n, ...)
{ va_list ap; long s = 0; va_start (ap, n);
  for (int i = 0; i < n; i++) { s16 x = va_arg (ap, s16); s24 y = va_arg (ap, s24); s += x.a + 2 * x.b + 3 * y.a + 4 * y.b + 5 * y.c; }
  va_end (ap); return s; }
static void x64 (void)
{
  long (*p_f_dl) (dl, dl, dl, dl, dl, dl, dl) = f_dl;
  double (*p_f_ifl) (ifl, fid) = f_ifl;
  dl (*p_r_dl) (double, long) = r_dl;
  fid (*p_r_fid) (float, int, double) = r_fid;
  long (*p_f_vs) (int, ...) = f_vs;
  long (*p_g_dl) (void) = g_dl;
  double (*p_g_r_dl) (void) = g_r_dl;
  double (*p_g_r_fid) (void) = g_r_fid;
  long (*p_g_vs) (void) = g_vs;
  dl a = { 1.5, 1 }, b = { 2.5, 2 }, c = { 3.5, 3 }, d = { 4.5, 4 }, e = { 5.5, 5 }, f = { 6.5, 6 }, g = { 7.5, 7 };
  check (p_f_dl (a, b, c, d, e, f, g) == 203, "x64: a double and a long in an xmm and a general register, the last struct on the stack");
  ifl i = { 3, 1.5f }; fid j = { 2.5f, 4, 0.25 };
  check (p_f_ifl (i, j) == 31.5, "x64: an int and a float in one general register");
  dl rd = p_r_dl (2.5, 7);
  check (rd.d == 2.5 && rd.l == 7, "x64: a struct result in xmm0 and rax");
  fid rf = p_r_fid (1.5f, 3, 4.25);
  check (rf.f == 1.5f && rf.i == 3 && rf.d == 4.25, "x64: a struct result in rax and xmm0");
  s16 x1 = { 1, 2 }, x2 = { 6, 7 }, x3 = { 11, 12 }; s24 y1 = { 3, 4, 5 }, y2 = { 8, 9, 10 }, y3 = { 13, 14, 15 };
  check (p_f_vs (3, x1, y1, x2, y2, x3, y3) == 390, "x64: variadic structs in registers, in memory, past r9");
  check (p_g_dl () == 203, "x64: gcc calls ttpc: a double and a long, past r9");
  check (p_g_r_dl () == 9.5, "x64: gcc calls ttpc: a struct result in xmm0 and rax");
  check (p_g_r_fid () == 8.75, "x64: gcc calls ttpc: a struct result in rax and xmm0");
  check (p_g_vs () == 390, "x64: gcc calls ttpc: variadic structs");
}
#endif
#ifdef __riscv
long cb_ff2 (ff2 a, fi b, d1 c, cd d) { return a.a + 2 * a.b + 3 * b.f + 4 * b.i + 5 * c.d + 6 * d.c + 7 * d.d; }
double cb_fpout (double a, double b, double c, double d, double e, double f, double g, hd2 x, ff2 y)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * x.x + 9 * x.y + 10 * y.a + 11 * y.b; }
double cb_gpout (int a, int b, int c, int d, int e, int f, int g, int h, mix x, double y)
{ return a + 2 * b + 3 * c + 4 * d + 5 * e + 6 * f + 7 * g + 8 * h + 9 * x.a + 10 * x.b + 11 * y; }
long double cb_ldsplit (int a, int b, int c, int d, int e, int f, int g, long double x, int h)
{ return a + b + c + d + e + f + g == 28 && h == 8 ? x : 0.0L; }
int cb_narrow (unsigned a, unsigned short b, signed char c, int d)
{ return (a == 0xffffffffu) + 2 * (b == 0xffff) + 4 * (c == -1) + 8 * (d == -1) + 16 * ((unsigned long) a == 0xffffffffUL); }
unsigned cb_u32 (int a) { return a; }
unsigned short cb_u16 (int a) { return a; }
fi cb_r_fi (float f, int i) { fi r = { f, i }; return r; }
cd cb_r_cd (char c, double d) { cd r = { c, d }; return r; }
static void rv (void)
{
  long (*p_f_ff2) (ff2, fi, d1, cd) = f_ff2;
  double (*p_f_fpout) (double, double, double, double, double, double, double, hd2, ff2) = f_fpout;
  double (*p_f_gpout) (int, int, int, int, int, int, int, int, mix, double) = f_gpout;
  long double (*p_f_ldsplit) (int, int, int, int, int, int, int, long double, int) = f_ldsplit;
  long (*p_f_raw4) (unsigned) = f_raw4;
  long (*p_f_raw2) (unsigned short) = f_raw2;
  long (*p_f_raw1) (signed char) = f_raw1;
  ff2 (*p_r_ff2) (float) = r_ff2;
  fi (*p_r_fi) (float, int) = r_fi;
  cd (*p_r_cd) (char, double) = r_cd;
  long (*p_g_ff2) (void) = g_ff2;
  double (*p_g_fpout) (void) = g_fpout;
  double (*p_g_gpout) (void) = g_gpout;
  long double (*p_g_ldsplit) (void) = g_ldsplit;
  double (*p_g_r_fi) (void) = g_r_fi;
  double (*p_g_r_cd) (void) = g_r_cd;
  ff2 a = { 1, 2 }; fi b = { 3, 4 }; d1 c = { 5 }; cd d = { 6, 7 };
  check (p_f_ff2 (a, b, c, d) == 1 + 4 + 9 + 16 + 25 + 36 + 49, "rv: two floats, a float and an int, a double, a char and a double");
  hd2 x = { 8, 9 }; ff2 y = { 10, 11 };
  check (p_f_fpout (1, 2, 3, 4, 5, 6, 7, x, y) == 140 + 64 + 81 + 100 + 121, "rv: structs of floats as words past fa7");
  mix m = { 9, 10 };
  check (p_f_gpout (1, 2, 3, 4, 5, 6, 7, 8, m, 11) == 204 + 81 + 100 + 121, "rv: a struct of an int and a double on the stack past a7");
  check (ldeq (p_f_ldsplit (1, 2, 3, 4, 5, 6, 7, 9.0L, 8), 9.0L), "rv: a long double in a7 and on the stack");
  unsigned short us = (unsigned short) -1; signed char sc = (signed char) 255;
  check (p_f_raw4 (0xffffffffu) == -1 && p_f_raw2 (us) == 0xffff && p_f_raw1 (sc) == -1, "rv: narrow integers sign-extended from 32 bits");
  ff2 rf = p_r_ff2 (1.5f);
  check (rf.a == 1.5f && rf.b == 2.5f, "rv: a struct of two floats as a result");
  fi ri = p_r_fi (2.5f, 7);
  check (ri.f == 2.5f && ri.i == 7, "rv: a struct of a float and an int as a result");
  cd rc = p_r_cd (9, 1.25);
  check (rc.c == 9 && rc.d == 1.25, "rv: a struct of a char and a double as a result");
  check (p_g_ff2 () == 140, "rv: gcc calls ttpc: structs of floating fields");
  check (p_g_fpout () == 506, "rv: gcc calls ttpc: structs of floats past fa7");
  check (p_g_gpout () == 506, "rv: gcc calls ttpc: a struct of an int and a double past a7");
  check (ldeq (p_g_ldsplit (), 9.0L), "rv: gcc calls ttpc: a long double in a7 and on the stack");
  check (g_narrow () == 31, "rv: gcc calls ttpc: narrow integers");
  check (g_u32 () == 1 && g_u16 () == 1, "rv: gcc calls ttpc: narrow integer results");
  check (p_g_r_fi () == 4.5, "rv: gcc calls ttpc: a struct of a float and an int as a result");
  check (p_g_r_cd () == 7.25, "rv: gcc calls ttpc: a struct of a char and a double as a result");
}
#endif
int main (void)
{
  /* the functions of gcc whose result is not an int: through pointers of
     their type (ff knows an asm function's result as a word) */
  long long (*p_f_ll) (int a, long long b, int c, long long d, long long e) = f_ll;
  long long (*p_r_ll) (long long a) = r_ll;
  long long (*p_f_var) (int n, ...) = f_var;
  long long (*p_g_ll) (void) = g_ll;
  long long (*p_g_var) (void) = g_var;
  long long (*p_g_ptr) (long long (*f) (int, long long, int, long long, long long)) = g_ptr;
  double (*p_f_d) (double a, int b, float c, double d, float e, double f, double g, double h, double i, double j, float k) = f_d;
  float (*p_f_f) (float a, float b, int c, float d) = f_f;
  double (*p_r_d) (double a) = r_d;
  double (*p_f_vard) (int n, ...) = f_vard;
  double (*p_g_d) (void) = g_d;
  float (*p_f_hf3) (hf3 a, float b, hf3 c) = f_hf3;
  double (*p_f_hd2) (int a, hd2 b, double c) = f_hd2;
  double (*p_f_mix) (mix a, int b, mix c) = f_mix;
  s4 (*p_r_s4) (int a) = r_s4;
  s8 (*p_r_s8) (int a) = r_s8;
  s20 (*p_r_s20) (int a) = r_s20;
  hf3 (*p_r_hf3) (float a) = r_hf3;
  hd2 (*p_r_hd2) (double a) = r_hd2;
  double (*p_g_r_hd2) (void) = g_r_hd2;
  check (f_i6 (1, 2, 3, 4, 5, 6) == 91, "ints past the registers");
  check (p_f_ll (1, 0x100000002LL, 3, 0x400000005LL, 0x600000007LL) == 0x3000000045LL, "long longs in pairs and on the stack");
  check (p_r_ll (0x100000001LL) == 0x300000003LL, "a long long result");
  check (p_f_var (2, 5, 0x100000000LL, 7, 3LL) == 0x200000012LL, "variadic ints and long longs");
  long long (*p) (int, long long, int, long long, long long) = f_ll;
  check (p (1, 2, 3, 4, 5) == 1 + 4 + 9 + 16 + 25, "a call through a pointer");
  check (g_i6 () == 91, "gcc calls ttpc: ints");
  check (p_g_ll () == 0x3000000045LL, "gcc calls ttpc: long longs");
  check (p_g_var () == 0x60000000cLL, "gcc calls ttpc: variadic");
  check (p_g_ptr (cb_ll) == 55, "gcc calls ttpc through a pointer");
  check (p_f_d (1.5, 2, 3.5f, 4.25, 5.5f, 6.0, 7.0, 8.0, 9.0, 10.0, 11.5f) == 517.0, "doubles and floats");
  check (p_f_f (1.5f, 2.5f, 3, 4.25f) == 32.5f, "floats");
  check (p_r_d (1.25) == 3.75, "a double result");
  check (p_f_vard (2, 1, 1.5, 2, 2.25) == 10.5, "variadic doubles");
  check (p_g_d () == 517.0, "gcc calls ttpc: doubles and floats");
  s4 a = { 1, 2 }; s8 b = { 3, 4 }; s12 c = { 5, 6, 7 }; s20 d = { 8, 9, 10, 11, 12 };
  check (f_s (a, b, c, d, 13) == 819, "structs by value");
  hf3 h = { 1, 2, 3 }, h2 = { 4, 5, 6 };
  check (p_f_hf3 (h, 0.5f, h2) == 108, "a homogeneous float aggregate");
  hd2 e = { 1.5, 2.5 };
  check (p_f_hd2 (1, e, 3) == 23.5, "a homogeneous double aggregate");
  mix m = { 1, 2.5 }, m2 = { 3, 4.5 };
  check (p_f_mix (m, 2, m2) == 46.5, "a struct of an int and a double");
  s4 r4 = p_r_s4 (7);
  check (r4.a == 7 && r4.b == 8, "a 4-byte struct result");
  s8 r8 = p_r_s8 (7);
  check (r8.a == 7 && r8.b == 8, "an 8-byte struct result");
  s20 r20 = p_r_s20 (7);
  check (r20.a == 7 && r20.e == 11, "a 20-byte struct result");
  hf3 rh = p_r_hf3 (1.5f);
  check (rh.x == 1.5f && rh.z == 3.5f, "a float aggregate result");
  hd2 rd = p_r_hd2 (1.5);
  check (rd.x == 1.5 && rd.y == 2.5, "a double aggregate result");
  s20 (*q) (int) = r_s20;
  s20 rq = q (7);
  check (rq.a == 7 && rq.d == 10, "a struct result through a pointer");
  struct { s20 (*mk) (int); hd2 (*mkd) (double); } o = { r_s20, r_hd2 };
  s20 rf = o.mk (8);
  check (rf.a == 8 && rf.e == 12, "a struct result through a field");
  hd2 rfd = o.mkd (0.5);
  check (rfd.x == 0.5 && rfd.y == 1.5, "a double aggregate result through a field");
  /* (through the address of a function of its own: an asm function's result is a word in ff) */
  s20 ra;
  ra = ((void) 0, &cb_r_s20) (9);
  check (ra.a == 9 && ra.e == 13, "a struct result through a function's address");
  check (g_s () == 819, "gcc calls ttpc: structs");
  check (g_r_s20 () == 60, "gcc calls ttpc: a struct result");
  check (p_g_r_hd2 () == 9.5, "gcc calls ttpc: a double aggregate result");
#if defined __aarch64__ || defined __x86_64__ || defined __riscv
  a64 ();
#endif
#if defined __x86_64__ || defined __riscv
  x64 ();
#endif
#ifdef __riscv
  rv ();
#endif
  return fails;
}
