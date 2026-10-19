/* For clang reading glibc .i made by gcc: the _FloatN types gcc has built in. */
typedef float _Float32;
typedef double _Float64;
typedef long double _Float128;
typedef double _Float32x;
typedef long double _Float64x;
/* gcc builtins clang does not have, used by inline helpers in glibc's headers. */
extern int __builtin_va_arg_pack_len (void);
extern int __builtin_va_arg_pack (void);
/* gcc 15's C23 rotates, which clang 21 does not have (glibc's PTR_MANGLE, PTR_DEMANGLE);
   glibc in ff has them in builtins.ff.txt. */
extern unsigned long __builtin_stdc_rotate_right (unsigned long, unsigned int);
extern unsigned long __builtin_stdc_rotate_left (unsigned long, unsigned int);
/* gcc's C23 bit builtins and __builtin_add_overflow_p, which clang 21 does
   not have (malloc: tcache's key, its bins, an alignment), on a word as
   glibc uses them; glibc in ff has them in builtins.ff.txt. */
extern unsigned int __builtin_stdc_count_ones (unsigned long);
extern unsigned int __builtin_stdc_bit_width (unsigned long);
extern unsigned int __builtin_stdc_leading_zeros (unsigned long);
extern unsigned int __builtin_stdc_trailing_zeros (unsigned long);
extern _Bool __builtin_stdc_has_single_bit (unsigned long);
extern unsigned long __builtin_stdc_bit_ceil (unsigned long);
extern _Bool __builtin_add_overflow_p (unsigned long, unsigned long, unsigned long);
/* and __builtin_mul_overflow_p, as gnulib's hash.c uses it: whether a
   product of two sizes fits a ptrdiff_t. */
extern _Bool __builtin_mul_overflow_p (unsigned long, unsigned long, long);
#ifdef __aarch64__
/* gcc's FPCR read, which soft-fp's sfp-machine.h uses for the rounding mode;
   glibc in ff has it in builtins-aarch64.ff.txt. */
extern unsigned int __builtin_aarch64_get_fpcr (void);
#endif
