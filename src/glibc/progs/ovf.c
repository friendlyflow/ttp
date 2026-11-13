/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* gcc's type-generic __builtin_add_overflow, __builtin_sub_overflow and
   __builtin_mul_overflow of the types gnulib's ckd_add, ckd_sub and
   ckd_mul give them in findutils, grep and coreutils (builtins.ff.txt,
   builtins-arm.ff.txt): each at the edges of its types, the result and
   whether it overflowed, printed; gcc's and ttpc's must print the same. */
#include <stdio.h>
#include <limits.h>

#define T(op, A, B, R, a, b) \
  do { R r_ = 0; int o_ = __builtin_##op##_overflow ((A) (a), (B) (b), &r_); \
       printf ("%s %s %s %s: %lld %d\n", #op, #A, #B, #R, (long long) r_, o_); } while (0)
#define TU(op, A, B, R, a, b) \
  do { R r_ = 0; int o_ = __builtin_##op##_overflow ((A) (a), (B) (b), &r_); \
       printf ("%s %s %s %s: %llu %d\n", #op, #A, #B, #R, (unsigned long long) r_, o_); } while (0)

typedef unsigned long u64;
typedef unsigned long long ull;

int
main (void)
{
  /* every target */
  T (add, int, int, long, INT_MAX, INT_MAX);
  T (add, int, int, long, INT_MIN, -1);
  TU (mul, ull, int, ull, 0x100000000ULL, 0x7fffffff);
  TU (mul, ull, int, ull, 0x100000000ULL, 0x100);
  TU (mul, ull, int, ull, 3, -1);
  TU (mul, ull, int, ull, 0, -5);
  TU (mul, ull, int, ull, ULLONG_MAX, 1);
  TU (mul, ull, int, ull, ULLONG_MAX, 2);
  TU (add, ull, int, unsigned char, 250, 5);
  TU (add, ull, int, unsigned char, 250, 6);
  TU (add, ull, int, unsigned char, 3, -4);
  TU (add, ull, int, unsigned char, ULLONG_MAX, 1);
  TU (add, ull, int, unsigned char, 300, -100);
#if LONG_MAX > INT_MAX
  T (add, int, long, int, 5, (long) INT_MAX);
  T (add, int, long, int, -5, (long) INT_MIN + 10);
  T (add, int, long, long, 1, LONG_MAX);
  T (add, int, long, long, -1, LONG_MAX);
  T (add, u64, int, long, (u64) LONG_MAX, 1);
  T (add, u64, int, long, (u64) LONG_MAX + 5, -5);
  T (add, u64, int, long, ULONG_MAX, -1);
  T (sub, long, int, int, (long) INT_MIN, 1);
  T (sub, long, int, int, (long) INT_MAX + 1, 1);
  T (mul, u64, u64, long, 0x80000000UL, 0xffffffffUL);
  T (mul, u64, u64, long, 0x100000000UL, 0x80000000UL);
  T (mul, u64, u64, long, ULONG_MAX, ULONG_MAX);
  TU (add, u64, long, u64, ULONG_MAX, -1);
  TU (add, u64, long, u64, ULONG_MAX, 1);
  TU (add, u64, long, u64, 5, -6);
  T (mul, int, int, long, INT_MIN, INT_MIN);
  T (mul, int, int, long, INT_MAX, -3);
  T (mul, u64, long, long, ULONG_MAX, 0);
  T (mul, u64, long, long, 1UL << 62, 2);
  T (mul, u64, long, long, 1UL << 62, -2);
  T (mul, u64, long, long, 3, -5);
  T (sub, long, long, int, LONG_MIN, LONG_MIN);
  T (sub, long, long, int, 0, LONG_MIN);
  T (sub, long, long, int, -5, (long) INT_MAX);
#else
  T (add, unsigned int, int, int, 0x7fffffffU, 0);
  T (add, unsigned int, int, int, 0x80000000U, -1);
  T (add, unsigned int, int, int, 0xffffffffU, 1);
  T (add, int, int, long long, INT_MAX, INT_MAX);
  T (sub, int, long, long long, INT_MIN, LONG_MAX);
  T (mul, unsigned int, unsigned int, int, 0xffffU, 0x8000U);
  T (mul, unsigned int, unsigned int, int, 0x10000U, 0x8000U);
  T (add, long long, int, int, (long long) INT_MAX - 1, 1);
  T (add, long long, int, int, (long long) INT_MAX, 1);
  T (add, long long, int, int, LLONG_MAX, 1);
  T (add, int, long long, long long, 1, LLONG_MAX);
  T (add, int, long long, long long, -1, LLONG_MIN + 1);
  T (add, int, long long, int, 1, (long long) INT_MAX - 1);
  T (add, int, long long, int, 1, LLONG_MAX);
  T (sub, long long, int, long long, LLONG_MIN, 1);
  T (sub, long long, int, long long, LLONG_MIN, -1);
  T (sub, long long, int, int, (long long) INT_MIN + 1, 1);
  T (sub, long long, int, int, LLONG_MIN, 1);
  T (sub, int, long long, int, 0, (long long) INT_MIN);
  T (sub, int, long long, int, -1, LLONG_MIN);
  T (mul, long long, long long, long long, 0x100000000LL, 0x7fffffffLL);
  T (mul, long long, long long, long long, 0x100000000LL, 0x80000000LL);
  T (mul, long long, long long, long long, -1, LLONG_MIN);
  T (mul, long long, long long, long long, LLONG_MIN, -1);
  T (mul, long long, long long, long long, 0, LLONG_MIN);
  T (mul, int, int, long long, INT_MIN, INT_MIN);
  TU (mul, unsigned int, unsigned int, ull, 0xffffffffU, 0xffffffffU);
  T (add, long long, unsigned int, long long, LLONG_MAX - 5, 5);
  T (add, long long, unsigned int, long long, LLONG_MAX - 5, 6);
  T (add, long long, unsigned int, long long, LLONG_MIN, 0xffffffffU);
  TU (add, ull, long long, ull, ULLONG_MAX, -1);
  TU (add, ull, long long, ull, ULLONG_MAX, 1);
  TU (add, ull, long long, ull, 5, -6);
  TU (add, ull, long long, ull, 0x8000000000000000ULL, LLONG_MIN);
  T (add, ull, int, long long, 0x7fffffffffffffffULL, 1);
  T (add, ull, int, long long, 0x8000000000000000ULL, -1);
  T (add, ull, int, long long, 0x8000000000000000ULL, 0);
  T (mul, ull, long long, long long, 1ULL << 62, 2);
  T (mul, ull, long long, long long, 1ULL << 62, -2);
  T (mul, ull, long long, long long, 1ULL << 63, -1);
  T (mul, ull, long long, long long, (1ULL << 63) + 1, -1);
  T (mul, ull, long long, long long, 3, -5);
  T (mul, ull, long long, long long, 0, LLONG_MIN);
#endif
  return 0;
}
