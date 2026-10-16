/* For clang reading glibc .i made by gcc: the _FloatN types gcc has built in. */
typedef float _Float32;
typedef double _Float64;
typedef long double _Float128;
typedef double _Float32x;
typedef long double _Float64x;
/* gcc builtins clang does not have, used by inline helpers in glibc's headers. */
extern int __builtin_va_arg_pack_len (void);
extern int __builtin_va_arg_pack (void);
