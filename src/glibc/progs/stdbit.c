/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* C23's bit functions as gcc has them built in (__builtin_stdc_*, which
   glibc's stdbit.h and its own code use), type-generic: each on each of the
   five unsigned types, against a plain count of the bits of the same value
   at the type's width (exit: how many differ, at most 255). Their result
   types are checked too: bit_floor, bit_ceil and the rotations give the
   argument's type. It needs no part of glibc but the builtins (as
   generic.c), so it runs on every target: arm's unsigned long is 32 bits. */

typedef unsigned long long u64;

static u64 mask (int n) { return n == 64 ? ~0ULL : (1ULL << n) - 1; }
static unsigned lz (u64 v, int n) { unsigned c = 0; for (int b = n - 1; b >= 0 && !(v >> b & 1); b--) c++; return c; }
static unsigned tz (u64 v, int n) { unsigned c = 0; for (int b = 0; b < n && !(v >> b & 1); b++) c++; return c; }
static unsigned pop (u64 v) { unsigned c = 0; for (; v; v >>= 1) c += v & 1; return c; }
static unsigned width (u64 v, int n) { return n - lz (v, n); }
static u64 ceil2 (u64 v, int n) { return v <= 1 ? 1 : width (v - 1, n) == (unsigned) n ? 0 : 1ULL << width (v - 1, n); }
static u64 rotl (u64 v, unsigned k, int n) { k %= n; return k ? ((v << k) | (v >> (n - k))) & mask (n) : v; }
static u64 rotr (u64 v, unsigned k, int n) { k %= n; return k ? ((v >> k) | (v << (n - k))) & mask (n) : v; }

static const u64 vals[] = {
  0, 1, 2, 3, 4, 5, 7, 8, 0x55, 0x80, 0x81, 0xfe, 0xff, 0x100, 0x7fff, 0x8000, 0xa5a5, 0xffff,
  0x10000, 0x12345678, 0x7fffffff, 0x80000000, 0x80000001, 0xfffffffe, 0xffffffff,
  0x100000000ULL, 0x123456789abcdef0ULL, 0x7fffffffffffffffULL, 0x8000000000000000ULL,
  0x8000000000000001ULL, 0xfffffffffffffffeULL, 0xffffffffffffffffULL,
};
static const unsigned counts[] = { 0, 1, 3, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65, 0xffffffffu };

/* each function on T, each value cut to T, against the counts at T's width */
#define CHECK(T)                                                              \
  static int                                                                  \
  check_##T (void)                                                            \
  {                                                                           \
    int f = 0, n = sizeof (T) * 8;                                            \
    f += sizeof (__builtin_stdc_bit_floor ((T) 0)) != sizeof (T);             \
    f += sizeof (__builtin_stdc_bit_ceil ((T) 0)) != sizeof (T);              \
    f += sizeof (__builtin_stdc_rotate_left ((T) 0, 1)) != sizeof (T);        \
    f += sizeof (__builtin_stdc_leading_zeros ((T) 0)) != sizeof (unsigned);  \
    for (unsigned i = 0; i < sizeof vals / sizeof vals[0]; i++)               \
      {                                                                       \
        T x = (T) vals[i];                                                    \
        u64 v = x, nv = ~v & mask (n);                                        \
        f += __builtin_stdc_leading_zeros (x) != lz (v, n);                   \
        f += __builtin_stdc_leading_ones (x) != lz (nv, n);                   \
        f += __builtin_stdc_trailing_zeros (x) != tz (v, n);                  \
        f += __builtin_stdc_trailing_ones (x) != tz (nv, n);                  \
        f += __builtin_stdc_first_leading_one (x) != (v ? lz (v, n) + 1 : 0); \
        f += __builtin_stdc_first_leading_zero (x) != (nv ? lz (nv, n) + 1 : 0); \
        f += __builtin_stdc_first_trailing_one (x) != (v ? tz (v, n) + 1 : 0); \
        f += __builtin_stdc_first_trailing_zero (x) != (nv ? tz (nv, n) + 1 : 0); \
        f += __builtin_stdc_count_ones (x) != pop (v);                        \
        f += __builtin_stdc_count_zeros (x) != n - pop (v);                   \
        f += __builtin_stdc_has_single_bit (x) != (pop (v) == 1);             \
        f += __builtin_stdc_bit_width (x) != width (v, n);                    \
        f += __builtin_stdc_bit_floor (x) != (v ? 1ULL << (width (v, n) - 1) : 0); \
        f += __builtin_stdc_bit_ceil (x) != ceil2 (v, n);                     \
        f += __builtin_stdc_leading_zeros ((T) (vals[i] >> 1)) != lz ((T) (vals[i] >> 1), n); \
        for (unsigned j = 0; j < sizeof counts / sizeof counts[0]; j++)      \
          {                                                                   \
            f += __builtin_stdc_rotate_left (x, counts[j]) != rotl (v, counts[j], n); \
            f += __builtin_stdc_rotate_right (x, counts[j]) != rotr (v, counts[j], n); \
          }                                                                   \
      }                                                                       \
    return f;                                                                 \
  }
typedef unsigned char uc;
typedef unsigned short us;
typedef unsigned int ui;
typedef unsigned long ul;
typedef unsigned long long ull;
CHECK (uc)
CHECK (us)
CHECK (ui)
CHECK (ul)
CHECK (ull)

int
main (void)
{
  int f = check_uc () + check_us () + check_ui () + check_ul () + check_ull ();
  return f > 255 ? 255 : f;
}
