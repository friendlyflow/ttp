/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* libgcc's own functions, called by name: complex multiply and divide
   (C99's Annex G, its infinities and NaNs too), the integer helpers, the
   powers to an int, soft-fp's float conversions and division, and arm's
   AEABI helpers in asm (division, shifts, soft-float) and __sync functions. Each
   result's bits are printed: gcc + libc.a + gcc's libgcc.a and ttpc + glibc
   and libgcc in ff agree only when every bit does. */

#include <stdio.h>

typedef _Complex float cf;
typedef _Complex double cd;
/* binary128, gcc's TF: long double on riscv64, __float128 on x86_64, whose
   long double is the x87's (XF, its own functions below) */
#ifdef __x86_64__
typedef __float128 tf;
typedef _Complex long double cx;
#else
typedef long double tf;
typedef _Complex long double cl;
#endif

cf __mulsc3 (float, float, float, float);
cf __divsc3 (float, float, float, float);
cd __muldc3 (double, double, double, double);
cd __divdc3 (double, double, double, double);
#ifndef __x86_64__
cl __multc3 (tf, tf, tf, tf);
cl __divtc3 (tf, tf, tf, tf);
#else
cx __mulxc3 (long double, long double, long double, long double);
cx __divxc3 (long double, long double, long double, long double);
long double __powixf2 (long double, int);
/* (libgcc2's _fixunsxfsi.o of a 64-bit word: x87 to an unsigned long) */
unsigned long __fixunsxfdi (long double);
tf __extendxftf2 (long double);
long double __trunctfxf2 (tf);
#endif
int __popcountdi2 (long long);
int __clzdi2 (unsigned long long);
int __ctzdi2 (unsigned long long);
int __ffsdi2 (long long);
int __paritydi2 (long long);
int __clrsbdi2 (long long);
unsigned int __bswapsi2 (unsigned int);
long long __bswapdi2 (long long);
int __absvsi2 (int);
long long __absvdi2 (long long);
int __addvsi3 (int, int);
long long __addvdi3 (long long, long long);
long long __subvdi3 (long long, long long);
int __mulvsi3 (int, int);
double __powidf2 (double, int);
float __powisf2 (float, int);
#ifndef __arm__
/* the TI functions: __int128 (ff's i128, u128) */
typedef __int128 ti;
typedef unsigned __int128 uti;
ti __multi3 (ti, ti);
ti __divti3 (ti, ti);
ti __modti3 (ti, ti);
uti __udivti3 (uti, uti);
uti __umodti3 (uti, uti);
uti __udivmodti4 (uti, uti, uti *);
ti __divmodti4 (ti, ti, ti *);
ti __negti2 (ti);
ti __ashlti3 (ti, int);
ti __ashrti3 (ti, int);
ti __lshrti3 (ti, int);
int __cmpti2 (ti, ti);
int __ucmpti2 (uti, uti);
ti __absvti2 (ti);
ti __addvti3 (ti, ti);
ti __subvti3 (ti, ti);
ti __mulvti3 (ti, ti);
ti __negvti2 (ti);
int __ffsti2 (ti);
int __clzti2 (uti);
int __ctzti2 (uti);
int __popcountti2 (uti);
int __parityti2 (uti);
int __clrsbti2 (ti);
float __floattisf (ti);
float __floatuntisf (uti);
double __floattidf (ti);
double __floatuntidf (uti);
tf __floattitf (ti);
tf __floatuntitf (uti);
ti __fixsfti (float);
uti __fixunssfti (float);
ti __fixdfti (double);
uti __fixunsdfti (double);
ti __fixtfti (tf);
uti __fixunstfti (tf);
#ifdef __x86_64__
long double __floattixf (ti);
long double __floatuntixf (uti);
ti __fixxfti (long double);
uti __fixunsxfti (long double);
#endif
#endif
#ifndef __arm__
tf __powitf2 (tf, int);
unsigned long long __fixunsdfdi (double);
unsigned long long __fixunssfdi (float);
tf __floatsitf (int);
tf __floatunsitf (unsigned int);
int __fixtfsi (tf);
unsigned int __fixunstfsi (tf);
int __unordtf2 (tf, tf);
#else
/* (arm: no binary128, its long double a double; its 64-bit division, C;
   the four of AEABI's base procedure call standard, their floats in core
   registers (ff's base pcs), by both their names) */
#define PCS __attribute__ ((pcs ("aapcs")))
long long __fixdfdi (double) PCS;
long long __aeabi_d2lz (double) PCS;
unsigned long long __fixunsdfdi (double) PCS;
unsigned long long __aeabi_d2ulz (double) PCS;
long long __fixsfdi (float) PCS;
long long __aeabi_f2lz (float) PCS;
unsigned long long __fixunssfdi (float) PCS;
unsigned long long __aeabi_f2ulz (float) PCS;
long long __divdi3 (long long, long long);
long long __moddi3 (long long, long long);
unsigned long long __udivdi3 (unsigned long long, unsigned long long);
unsigned long long __umoddi3 (unsigned long long, unsigned long long);
/* AEABI's helpers in asm: lib1funcs.S's division of 32 bits (divmod's
   quotient in r0, its remainder in r1: a 64-bit result here) and shifts of
   64, ieee754-df/sf.S's soft-float arithmetic, conversions and comparisons,
   whose floats come in core registers: here their bits, as integers */
typedef unsigned long long u64;
typedef unsigned int u32;
u32 __aeabi_uidiv (u32, u32);
int __aeabi_idiv (int, int);
u64 __aeabi_uidivmod (u32, u32);
u64 __aeabi_idivmod (int, int);
u32 __umodsi3 (u32, u32);
int __modsi3 (int, int);
long long __aeabi_llsr (long long, int);
long long __aeabi_lasr (long long, int);
long long __aeabi_llsl (long long, int);
u64 __aeabi_dadd (u64, u64);
u64 __aeabi_dsub (u64, u64);
u64 __aeabi_drsub (u64, u64);
u64 __aeabi_dmul (u64, u64);
u64 __aeabi_ddiv (u64, u64);
int __aeabi_dcmpeq (u64, u64);
int __aeabi_dcmplt (u64, u64);
int __aeabi_dcmpge (u64, u64);
u32 __aeabi_d2f (u64);
u64 __aeabi_f2d (u32);
u64 __aeabi_i2d (int);
u64 __aeabi_l2d (long long);
u32 __aeabi_fadd (u32, u32);
u32 __aeabi_fsub (u32, u32);
u32 __aeabi_fmul (u32, u32);
u32 __aeabi_fdiv (u32, u32);
int __aeabi_fcmple (u32, u32);
int __aeabi_fcmpgt (u32, u32);
u32 __aeabi_ui2f (u32);
u32 __aeabi_l2f (long long);
/* (an asm function's result is a long to ttpc's C, 32 bits on arm: those
   of 64 bits are called through pointers of their types) */
static struct
{
  u64 (*uidivmod) (u32, u32);
  u64 (*idivmod) (int, int);
  long long (*llsr) (long long, int), (*lasr) (long long, int), (*llsl) (long long, int);
  u64 (*dadd) (u64, u64), (*dsub) (u64, u64), (*drsub) (u64, u64), (*dmul) (u64, u64), (*ddiv) (u64, u64);
  u64 (*f2d) (u32);
  u64 (*i2d) (int);
  u64 (*l2d) (long long);
} h64 = { __aeabi_uidivmod, __aeabi_idivmod, __aeabi_llsr, __aeabi_lasr, __aeabi_llsl, __aeabi_dadd, __aeabi_dsub,
          __aeabi_drsub, __aeabi_dmul, __aeabi_ddiv, __aeabi_f2d, __aeabi_i2d, __aeabi_l2d };
/* linux-atomic.c's __sync functions (through the kernel's cmpxchg helper),
   by their asm names: gcc and clang know the names as builtins */
int sync_fetch_and_add_4 (int *, int) __asm__ ("__sync_fetch_and_add_4");
int sync_fetch_and_nand_4 (int *, int) __asm__ ("__sync_fetch_and_nand_4");
short sync_sub_and_fetch_2 (short *, short) __asm__ ("__sync_sub_and_fetch_2");
signed char sync_val_cas_1 (signed char *, signed char, signed char) __asm__ ("__sync_val_compare_and_swap_1");
int sync_lock_test_and_set_4 (int *, int) __asm__ ("__sync_lock_test_and_set_4");
long long sync_fetch_and_add_8 (long long *, long long) __asm__ ("__sync_fetch_and_add_8");
long long sync_val_cas_8 (long long *, long long, long long) __asm__ ("__sync_val_compare_and_swap_8");
void sync_synchronize (void) __asm__ ("__sync_synchronize");
#endif
#ifdef __riscv
/* (soft-fp's division of float and double: riscv64's libgcc has them, x86_64
   divides in SSE) */
double __divdf3 (double, double);
float __divsf3 (float, float);
#endif
int __gcc_bcmp (const unsigned char *, const unsigned char *, __SIZE_TYPE__);

static int n;

static void w (unsigned long long x) { printf ("%d %016llx\n", n++, x); }
/* (an unsigned int as itself: this file declares __bswapsi2 unsigned, where
   libgcc's is SItype, an int; gcc takes a call's type from the caller's
   declaration, ttpc from the function's definition) */
static void w32 (unsigned int x) { printf ("%d %08x\n", n++, x); }
/* (a NaN's sign on aarch64 and arm as 0: gcc's libgcc there computes
   a * b + c as one fmadd, fmsub ..., arm's vmla, vmls (C's FP_CONTRACT,
   gcc's -ffp-contract=fast), whose NaN takes another sign than two
   operations', ttpc's) */
#if defined __aarch64__ || defined __arm__
#define NANSIGN(x, s) ((x) != (x) ? (s) : 0)
#else
#define NANSIGN(x, s) 0
#endif
static void f (float x) { union { float f; unsigned int u; } v; v.f = x; w (v.u & ~NANSIGN (x, 0x80000000u)); }
static void d (double x) { union { double d; unsigned long long u; } v; v.d = x; w (v.u & ~NANSIGN (x, 0x8000000000000000ul)); }
#ifndef __arm__
static void l (tf x) { union { tf d; unsigned long long u[2]; } v; v.d = x; w (v.u[0]); w (v.u[1] & ~NANSIGN (x, 0x8000000000000000ul)); }
#endif
#ifdef __x86_64__
/* (the x87's 80 bits: the 6 bytes above them are padding) */
static void xl (long double x) { union { long double d; unsigned long u[2]; } v; v.d = x; w (v.u[0]); w (v.u[1] & 0xffff); }
#endif

#ifndef __arm__
/* float16 and bfloat16 (_Float16, __bf16) */
typedef _Float16 hf;
typedef __bf16 bf;
#ifndef __aarch64__
float __extendhfsf2 (hf);
double __extendhfdf2 (hf);
hf __truncsfhf2 (float);
hf __truncdfhf2 (double);
#endif
tf __extendhftf2 (hf);
hf __trunctfhf2 (tf);
float __extendbfsf2 (bf);
bf __truncsfbf2 (float);
bf __truncdfbf2 (double);
bf __trunctfbf2 (tf);
bf __trunchfbf2 (hf);
ti __fixhfti (hf);
uti __fixunshfti (hf);
hf __floattihf (ti);
hf __floatuntihf (uti);
bf __floattibf (ti);
bf __floatuntibf (uti);
#ifdef __x86_64__
long double __extendhfxf2 (hf);
hf __truncxfhf2 (long double);
bf __truncxfbf2 (long double);
int __eqhf2 (hf, hf);
int __nehf2 (hf, hf);
#endif
#ifdef __riscv
hf __truncbfhf2 (bf);
int __fixhfsi (hf);
long __fixhfdi (hf);
unsigned __fixunshfsi (hf);
unsigned long __fixunshfdi (hf);
hf __floatsihf (int);
hf __floatdihf (long);
hf __floatunsihf (unsigned);
hf __floatundihf (unsigned long);
bf __floatsibf (int);
bf __floatdibf (long);
bf __floatunsibf (unsigned);
bf __floatundibf (unsigned long);
#endif
#ifdef __aarch64__
bf __floatdibf (long);
bf __floatundibf (unsigned long);
#endif
static unsigned short hb (hf x) { union { hf f; unsigned short u; } v; v.f = x; return v.u; }
static unsigned short bb (bf x) { union { bf f; unsigned short u; } v; v.f = x; return v.u; }
/* (a NaN as one NaN: of two NaN operands, which one an operation gives is its compiler's order of them) */
static unsigned short hn (hf x) { unsigned short u = hb (x); return (u & 0x7c00) == 0x7c00 && (u & 0x3ff) ? 0x7e00 : u; }
static hf hfrom (unsigned short u) { union { hf f; unsigned short u; } v; v.u = u; return v.f; }
static bf bfrom (unsigned short u) { union { bf f; unsigned short u; } v; v.u = u; return v.f; }
_Complex _Float16 __mulhc3 (hf, hf, hf, hf);
_Complex _Float16 __divhc3 (hf, hf, hf, hf);
hf __floatbitinthf (const unsigned long *, int);
#if defined __x86_64__ || defined __aarch64__
bf __floatbitintbf (const unsigned long *, int);
#endif
#endif
#ifdef __arm__
float __floatbitinthf (const unsigned int *, int);
#endif
static double dv[] = { 0.0, -0.0, 1.0, -2.5, 3.0e300, 1.0e-310, __builtin_inf (), -__builtin_inf (), __builtin_nan ("") };
#define N (sizeof dv / sizeof dv[0])

int main (void)
{
  unsigned int i, j;
  for (i = 0; i < N; i++)
    for (j = 0; j < N; j += 2)
      {
        double a = dv[i], b = dv[(i + 3) % N], c = dv[j], e = dv[(j + 5) % N];
        cd z = __muldc3 (a, b, c, e), q = __divdc3 (a, b, c, e);
        d (__real__ z); d (__imag__ z); d (__real__ q); d (__imag__ q);
        cf zf = __mulsc3 (a, b, c, e), qf = __divsc3 (a, b, c, e);
        f (__real__ zf); f (__imag__ zf); f (__real__ qf); f (__imag__ qf);
#if !defined __x86_64__ && !defined __arm__
        cl zl = __multc3 (a, b, c, e), ql = __divtc3 (a, b, c, e);
        l (__real__ zl); l (__imag__ zl); l (__real__ ql); l (__imag__ ql);
#elif defined __x86_64__
        cx zx = __mulxc3 (a, b, c, e), qx = __divxc3 (a, b, c, e);
        xl (__real__ zx); xl (__imag__ zx); xl (__real__ qx); xl (__imag__ qx);
#endif
      }
  static long long iv[] = { 0, 1, -1, 2, 0x7f, 0x80, 0x12345678, -0x7fffffffLL, 0x0102030405060708LL, 0x7fffffffffffffffLL, (long long) 0x8000000000000000ULL };
  for (i = 0; i < sizeof iv / sizeof iv[0]; i++)
    {
      long long x = iv[i];
      w (__popcountdi2 (x)); w (__ffsdi2 (x)); w (__paritydi2 (x)); w (__clrsbdi2 (x));
      if (x)
        {
          w (__clzdi2 (x));
          w (__ctzdi2 (x));
        }
      w32 (__bswapsi2 (x)); w (__bswapdi2 (x));
#ifndef __arm__
      /* (arm's trapping arithmetic of 64 bits: its overflow builtins of
         long long, which c2ff has no form of on arm yet) */
      if (x != (long long) 0x8000000000000000ULL)
        w (__absvdi2 (x));
#endif
      if ((int) x != (int) 0x80000000)
        w (__absvsi2 ((int) x));
      w (__addvsi3 ((int) x >> 2, 12345));
#ifndef __arm__
      w (__addvdi3 (x >> 2, -77)); w (__subvdi3 (x >> 2, 99));
#endif
      w (__mulvsi3 ((int) x >> 17, 3));
      d (__powidf2 (1.0 + (double) (x & 0xff) / 64, (int) (x & 31) - 8));
      f (__powisf2 (1.0f + (float) (x & 0xff) / 32, (int) (x & 15) - 4));
#ifndef __arm__
      l (__powitf2 ((tf) 1 + (tf) (x & 0xff) / 16, (int) (x & 63) - 20));
      l (__floatsitf ((int) x)); l (__floatunsitf ((unsigned int) x));
      w (__fixtfsi ((tf) (int) x / 3)); w32 (__fixunstfsi ((tf) (unsigned int) x / 5));
      w (__fixunsdfdi ((double) (unsigned long long) x)); w (__fixunssfdi ((float) (unsigned int) x));
#else
      w (__divdi3 (x, 7)); w (__moddi3 (x, -5)); w (__udivdi3 (x, 3)); w (__umoddi3 (x, 1000003));
      if (x != (long long) 0x8000000000000000ULL)
        w (__divdi3 (x, x | 1));
      u64 hx = (u64) x >> 1;
      w (__fixdfdi ((double) x / 3)); w (__aeabi_d2lz (-(double) (x >> 1))); w (__fixunsdfdi ((double) hx));
      { unsigned int lb[2] = { (unsigned int) x, (unsigned int) (x >> 32) }; float (*p) (const unsigned int *, int) = __floatbitinthf; union { float f; unsigned int u; } v; v.f = p (lb, -64); w32 (v.u & 0xffff); }
      w (__aeabi_d2ulz ((double) (u32) x * 7)); w (__fixsfdi ((float) x / 5)); w (__aeabi_f2lz (-(float) (int) x));
      w (__fixunssfdi ((float) (u32) x)); w (__aeabi_f2ulz ((float) hx * 0.5f));
      u32 y = (u32) x, z = (u32) (x >> 32) | 3;
      w32 (__aeabi_uidiv (y, z)); w32 (__aeabi_idiv ((int) y, (int) z)); w (h64.uidivmod (y, 7));
      w (h64.idivmod ((int) y, -(int) z)); w32 (__umodsi3 (y, 10)); w32 (__modsi3 ((int) y, 3));
      w (h64.llsr (x, i * 5)); w (h64.lasr (x, i * 6)); w (h64.llsl (x, 63 - i * 4));
      u64 a = (u64) x, b = (u64) iv[(i + 4) % (sizeof iv / sizeof iv[0])] ^ 0x4000000000000000ULL;
      w (h64.dadd (a, b)); w (h64.dsub (a, b)); w (h64.drsub (a, b)); w (h64.dmul (a, b));
      w (h64.ddiv (a, b)); w (__aeabi_dcmpeq (a, b)); w (__aeabi_dcmplt (a, b)); w (__aeabi_dcmpge (a, a));
      w32 (__aeabi_d2f (b)); w (h64.f2d (y)); w (h64.i2d ((int) y)); w (h64.l2d (x));
      w32 (__aeabi_fadd (y, z)); w32 (__aeabi_fsub (y, z)); w32 (__aeabi_fmul (y, z)); w32 (__aeabi_fdiv (y, z));
      w (__aeabi_fcmple (y, z)); w (__aeabi_fcmpgt (y, y)); w32 (__aeabi_ui2f (y)); w32 (__aeabi_l2f (x));
      {
        static int m4 = 5;
        static short m2 = 300;
        static signed char m1 = -7;
        static long long m8 = 0x100000000LL;
        w32 (sync_fetch_and_add_4 (&m4, (int) y)); w32 (sync_fetch_and_nand_4 (&m4, (int) z));
        w32 ((unsigned short) sync_sub_and_fetch_2 (&m2, (short) y));
        w32 ((unsigned char) sync_val_cas_1 (&m1, m1, (signed char) y)); w32 ((unsigned char) sync_val_cas_1 (&m1, 1, 2));
        w32 (sync_lock_test_and_set_4 (&m4, (int) z)); w (sync_fetch_and_add_8 (&m8, x));
        w (sync_val_cas_8 (&m8, m8, x ^ 0x55)); w (sync_val_cas_8 (&m8, 3, 4));
        sync_synchronize ();
        w32 (m4); w32 ((unsigned short) m2); w32 ((unsigned char) m1); w (m8);
      }
#endif
#ifndef __arm__
      {
        ti a = ((ti) x << 64) | (unsigned long long) (x * 0x9e3779b97f4a7c15ULL);
        ti b = ((ti) (x >> (x & 63)) << (x & 63)) ^ (ti) (long long) (x * 0xd1342543de82ef95ULL);
        ti c = (ti) (long long) (x | 1) ;
        ti r2; uti u2;
        int n = (int) (x & 127);
        w ((unsigned long long) (__multi3 (a, b) >> 64)); w ((unsigned long long) __multi3 (a, b));
        if (b != 0)
          {
            w ((unsigned long long) (__divti3 (a, b) >> 64)); w ((unsigned long long) __divti3 (a, b));
            w ((unsigned long long) (__modti3 (a, b) >> 64)); w ((unsigned long long) __modti3 (a, b));
            w ((unsigned long long) (__udivti3 (a, b) >> 64)); w ((unsigned long long) __udivti3 (a, b));
            w ((unsigned long long) (__umodti3 (a, b) >> 64)); w ((unsigned long long) __umodti3 (a, b));
            w ((unsigned long long) (__udivmodti4 (a, b, &u2) >> 64)); w ((unsigned long long) (u2 >> 64)); w ((unsigned long long) u2);
            w ((unsigned long long) (__divmodti4 (a, b, &r2) >> 64)); w ((unsigned long long) (r2 >> 64)); w ((unsigned long long) r2);
          }
        w ((unsigned long long) (__divti3 (a, c) >> 64)); w ((unsigned long long) __modti3 (a, c));
        w ((unsigned long long) (__udivti3 (a, (unsigned long long) c) >> 64)); w ((unsigned long long) __umodti3 (a, (unsigned long long) c));
        w ((unsigned long long) (__negti2 (a) >> 64)); w ((unsigned long long) __negti2 (a));
        w ((unsigned long long) (__ashlti3 (a, n) >> 64)); w ((unsigned long long) __ashlti3 (a, n));
        w ((unsigned long long) (__ashrti3 (a, n) >> 64)); w ((unsigned long long) __ashrti3 (a, n));
        w ((unsigned long long) (__lshrti3 (a, n) >> 64)); w ((unsigned long long) __lshrti3 (a, n));
        w (__cmpti2 (a, b)); w (__ucmpti2 (a, b)); w (__cmpti2 (a, a));
        w ((unsigned long long) (__absvti2 (a >> 1) >> 64));
        w ((unsigned long long) (__addvti3 (a >> 2, b >> 2) >> 64)); w ((unsigned long long) (__subvti3 (a >> 2, b >> 2) >> 64));
        w ((unsigned long long) (__mulvti3 (a >> 90, b >> 90)));
        w ((unsigned long long) (__negvti2 (a >> 1) >> 64));
        w (__ffsti2 (a)); w (__ffsti2 ((ti) x << 64)); w (__ffsti2 (0));
        w (__clzti2 (a | 1)); w (__clzti2 ((a >> 64 & 0xffffffffffffffffULL) | 1)); w (__ctzti2 (a | ((ti) 1 << 127)));
        w (__ctzti2 ((a & ~(uti) 0 << 64) | ((ti) 1 << 127)));
        w (__popcountti2 (a)); w (__parityti2 (a)); w (__clrsbti2 (a)); w (__clrsbti2 (a >> 70));
        f (__floattisf (a)); f (__floatuntisf (a)); d (__floattidf (a)); d (__floatuntidf (a));
        l (__floattitf (a)); l (__floatuntitf (a));
        f (__floattisf (a >> 40)); d (__floattidf (a >> 40)); l (__floattitf (a >> 40));
        {
          ti t; uti tu;
          t = __fixsfti ((float) (long long) x); w ((unsigned long long) (t >> 64)); w ((unsigned long long) t);
          tu = __fixunssfti ((float) (x >> 1)); w ((unsigned long long) (tu >> 64)); w ((unsigned long long) tu);
          t = __fixdfti ((double) (long long) x * 1e10); w ((unsigned long long) (t >> 64)); w ((unsigned long long) t);
          tu = __fixunsdfti ((double) x * 1e10); w ((unsigned long long) (tu >> 64)); w ((unsigned long long) tu);
          t = __fixtfti ((tf) (long long) x * 1e15); w ((unsigned long long) (t >> 64)); w ((unsigned long long) t);
          tu = __fixunstfti ((tf) x * 1e15); w ((unsigned long long) (tu >> 64)); w ((unsigned long long) tu);
        }
#ifdef __x86_64__
        xl (__floattixf (a)); xl (__floatuntixf (a));
        {
          ti t = __fixxfti ((long double) (long long) x * 1e10L); uti tu = __fixunsxfti ((long double) x * 1e10L);
          w ((unsigned long long) (t >> 64)); w ((unsigned long long) t); w ((unsigned long long) (tu >> 64)); w ((unsigned long long) tu);
        }
#endif
        /* the operators: gcc's and ttpc's own calls of these */
        w ((unsigned long long) ((a * b) >> 64));
        if (b != 0)
          { w ((unsigned long long) ((a / b) >> 64)); w ((unsigned long long) (a % b)); w ((unsigned long long) (((uti) a / (uti) b) >> 64)); w ((unsigned long long) ((uti) a % (uti) b)); }
        f ((float) a); d ((double) a); l ((tf) a); f ((float) (uti) a); d ((double) (uti) a); l ((tf) (uti) a);
        { float ff = (float) (long long) x; double dd = (double) (long long) x * 1e10; tf tt = (tf) (long long) x * 1e15;
          ti t = ff; w ((unsigned long long) (t >> 64)); w ((unsigned long long) t); t = dd; w ((unsigned long long) (t >> 64)); w ((unsigned long long) t);
          t = tt; w ((unsigned long long) (t >> 64)); w ((unsigned long long) t); }
      }
#endif
#ifndef __arm__
      {
        /* every 16-bit pattern's neighbours: x's bits, NaNs and infinities among them */
        hf h = hfrom ((unsigned short) x), h2 = hfrom ((unsigned short) (x >> 16));
        bf b = bfrom ((unsigned short) x);
        float fv = (float) (int) x / 7.0f; double dv2 = (double) x / 11.0; tf tv = (tf) x / 13;
        ti a128 = ((ti) x << 64) | (unsigned long long) (x * 0x9e3779b97f4a7c15ULL);
#ifndef __aarch64__
        f (__extendhfsf2 (h)); d (__extendhfdf2 (h));
        w (hb (__truncsfhf2 (fv))); w (hb (__truncdfhf2 (dv2))); w (hb (__truncsfhf2 ((float) x)));
#endif
        l (__extendhftf2 (h)); w (hb (__trunctfhf2 (tv)));
        f (__extendbfsf2 (b));
        w (bb (__truncsfbf2 (fv))); w (bb (__truncdfbf2 (dv2))); w (bb (__trunctfbf2 (tv)));
        w (bb (__trunchfbf2 (h)));
        { ti t = __fixhfti (hfrom ((unsigned short) x & 0x7bff)); uti u = __fixunshfti (hfrom ((unsigned short) x & 0x7bff));
          w ((unsigned long long) (t >> 64)); w ((unsigned long long) t); w ((unsigned long long) (u >> 64)); w ((unsigned long long) u); }
        w (hb (__floattihf (a128 >> 100))); w (hb (__floatuntihf ((uti) a128 >> 100))); w (hb (__floattihf (a128)));
        w (bb (__floattibf (a128))); w (bb (__floatuntibf ((uti) a128 >> 1)));
#ifdef __x86_64__
        xl (__extendhfxf2 (h)); w (hb (__truncxfhf2 ((long double) x / 3))); w (bb (__truncxfbf2 ((long double) x / 3)));
        w (__eqhf2 (h, h2) != 0); w (__nehf2 (h, h) != 0);
#endif
#ifdef __riscv
        w (hb (__truncbfhf2 (b)));
        { hf s = hfrom ((unsigned short) x & 0x47ff); w (__fixhfsi (s)); w (__fixhfdi (s)); w (__fixunshfsi (s)); w (__fixunshfdi (s)); }
        w (hb (__floatsihf ((int) x >> 16))); w (hb (__floatdihf (x >> 48))); w (hb (__floatunsihf ((unsigned) x >> 16))); w (hb (__floatundihf ((unsigned long) x >> 48)));
        w (bb (__floatsibf ((int) x))); w (bb (__floatdibf (x))); w (bb (__floatunsibf ((unsigned) x))); w (bb (__floatundibf ((unsigned long) x)));
#endif
#ifdef __aarch64__
        w (bb (__floatdibf (x))); w (bb (__floatundibf ((unsigned long) x)));
#endif
        { unsigned long lb[2] = { (unsigned long) x, (unsigned long) (x >> 63) }; w (hb (__floatbitinthf (lb, -65))); w (hb (__floatbitinthf (lb, 64)));
#if defined __x86_64__ || defined __aarch64__
          w (bb (__floatbitintbf (lb, -65)));
#endif
        }
        { _Complex _Float16 z = __mulhc3 (h, h2, hfrom ((unsigned short) (x >> 32)), hfrom ((unsigned short) (x >> 48)));
          w (hn (__real__ z)); w (hn (__imag__ z));
          z = __divhc3 (h, h2, hfrom ((unsigned short) (x >> 32)), hfrom ((unsigned short) (x >> 48)));
          w (hn (__real__ z)); w (hn (__imag__ z)); }
        /* the operators and casts: ttpc's own calls of these, gcc's */
        { hf s = hfrom ((unsigned short) x & 0x7bff), s2 = hfrom ((unsigned short) (x >> 16) & 0x7bff);
          w (hb (s + s2)); w (hb (s - s2)); w (hb (s * s2)); if (s2 != 0) w (hb (s / s2)); w (hb (-s)); w (s < s2); w (s == s);
          f ((float) s); d ((double) s); l ((tf) s); w (hb ((hf) fv)); w (hb ((hf) dv2)); w (hb ((hf) tv)); w (hb ((hf) (int) (x & 0x3ff))); w ((long) s2);
          f ((float) bfrom ((unsigned short) x & 0x7f7f)); w (bb ((bf) fv)); w (bb ((bf) dv2)); w (bb ((bf) tv)); }
      }
#endif
#ifdef __riscv
      d (__divdf3 ((double) x, 7.0)); f (__divsf3 ((float) x, -3.0f));
#endif
#ifdef __x86_64__
      xl (__powixf2 (1.0L + (long double) (x & 0xff) / 16, (int) (x & 63) - 20));
      w (__fixunsxfdi ((long double) (unsigned long long) x / 5));
      l (__extendxftf2 ((long double) x / 3)); xl (__trunctfxf2 ((tf) x / 3));
#endif
    }
#ifndef __arm__
  for (i = 0; i < N; i++)
    w (__unordtf2 (dv[i], dv[(i + 7) % N]));
#endif
  static const unsigned char s1[] = "libgcc in ff", s2[] = "libgcc in FF";
  w (__gcc_bcmp (s1, s2, 10)); w (__gcc_bcmp (s1, s2, 12) != 0);
  return 0;
}
