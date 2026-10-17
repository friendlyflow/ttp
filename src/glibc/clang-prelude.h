/* For clang reading glibc .i made by gcc: the _FloatN types gcc has built in. */
typedef float _Float32;
typedef double _Float64;
typedef long double _Float128;
typedef double _Float32x;
typedef long double _Float64x;
/* gcc builtins clang does not have, used by inline helpers in glibc's headers. */
extern int __builtin_va_arg_pack_len (void);
extern int __builtin_va_arg_pack (void);
/* gcc 15's C23 rotate, which clang 21 does not have (glibc's PTR_DEMANGLE);
   glibc in ff has it in builtins.ff.txt. */
extern unsigned long __builtin_stdc_rotate_right (unsigned long, unsigned int);
