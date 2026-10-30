/* For clang reading glibc .i made by gcc: the _FloatN types gcc has built in,
   as macros, so that _Complex _Float32 reads (cmathcalls.h's, in the tests
   of scanf's formats); a typedef cannot follow _Complex. */
#define _Float32 float
#define _Float64 double
#ifdef __x86_64__
/* x86_64: gcc's _Float128 is a type of its own beside long double, the
   x87's (glibc's _Generic lists both); __float128 is clang's (c2ff's
   float128); a macro, so that _Complex _Float128 reads */
#define _Float128 __float128
#else
#define _Float128 long double
#endif
#define _Float32x double
#define _Float64x long double
/* gcc builtins clang does not have, used by inline helpers in glibc's headers. */
extern int __builtin_va_arg_pack_len (void);
extern int __builtin_va_arg_pack (void);
/* gcc's tgmath.h builtin: its functions, then the arguments; c2ff calls the
   function of the arguments' type (tgmath) */
extern double __builtin_tgmath ();
/* gcc's C23 bit builtins (stdbit.h's, and glibc's own PTR_MANGLE, malloc's
   tcache, printf_fp's limbs, libm's), which clang 21 does not have: they are
   type-generic, of the width of their argument's type, and bit_floor,
   bit_ceil and the rotations give that type (the tests' _Generic checks):
   here functions overloaded on the five unsigned types (an argument of one
   of them, as gcc takes no other). glibc in ff has one of each for each
   width, stdbit.ff.txt's, which c2ff names a call of by its argument. */
#define __ff_ov __attribute__ ((__overloadable__))
#define __ff_stdc(r, f, ...) \
  extern r (unsigned char) f (unsigned char __VA_ARGS__) __ff_ov; \
  extern r (unsigned short) f (unsigned short __VA_ARGS__) __ff_ov; \
  extern r (unsigned int) f (unsigned int __VA_ARGS__) __ff_ov; \
  extern r (unsigned long) f (unsigned long __VA_ARGS__) __ff_ov; \
  extern r (unsigned long long) f (unsigned long long __VA_ARGS__) __ff_ov;
#define __ff_uint(t) unsigned int
#define __ff_bool(t) _Bool
#define __ff_same(t) t
__ff_stdc (__ff_uint, __builtin_stdc_leading_zeros)
__ff_stdc (__ff_uint, __builtin_stdc_leading_ones)
__ff_stdc (__ff_uint, __builtin_stdc_trailing_zeros)
__ff_stdc (__ff_uint, __builtin_stdc_trailing_ones)
__ff_stdc (__ff_uint, __builtin_stdc_first_leading_zero)
__ff_stdc (__ff_uint, __builtin_stdc_first_leading_one)
__ff_stdc (__ff_uint, __builtin_stdc_first_trailing_zero)
__ff_stdc (__ff_uint, __builtin_stdc_first_trailing_one)
__ff_stdc (__ff_uint, __builtin_stdc_count_zeros)
__ff_stdc (__ff_uint, __builtin_stdc_count_ones)
__ff_stdc (__ff_bool, __builtin_stdc_has_single_bit)
__ff_stdc (__ff_uint, __builtin_stdc_bit_width)
__ff_stdc (__ff_same, __builtin_stdc_bit_floor)
__ff_stdc (__ff_same, __builtin_stdc_bit_ceil)
__ff_stdc (__ff_same, __builtin_stdc_rotate_left, , unsigned int)
__ff_stdc (__ff_same, __builtin_stdc_rotate_right, , unsigned int)
#undef __ff_ov
#undef __ff_stdc
#undef __ff_uint
#undef __ff_bool
#undef __ff_same
/* and __builtin_add_overflow_p, as glibc uses it (malloc: an alignment),
   on a word; builtins.ff.txt has it. */
extern _Bool __builtin_add_overflow_p (unsigned long, unsigned long, unsigned long);
/* and __builtin_mul_overflow_p, as gnulib's hash.c uses it: whether a
   product of two sizes fits a ptrdiff_t. */
extern _Bool __builtin_mul_overflow_p (unsigned long, unsigned long, long);
#ifdef __aarch64__
/* gcc's FPCR read, which soft-fp's sfp-machine.h uses for the rounding mode;
   glibc in ff has it in builtins-aarch64.ff.txt. */
extern unsigned int __builtin_aarch64_get_fpcr (void);
#endif
