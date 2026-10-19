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
  return fails;
}
