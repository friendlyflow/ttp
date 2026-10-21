/* abi.h — the shapes of calls abi_gcc.c (compiled by gcc) and abi_main.c
   (translated by c2ff, compiled by ttpc) make of each other: ints past
   the registers, long longs in pairs, floats and doubles, structs by value
   (small, large, homogeneous floating aggregates), results of each,
   variadics, calls through pointers. */
typedef struct { short a, b; } s4;
typedef struct { int a, b; } s8;
typedef struct { int a, b, c; } s12;
typedef struct { int a, b, c, d, e; } s20;
typedef struct { float x, y, z; } hf3;
typedef struct { double x, y; } hd2;
typedef struct { int a; double b; } mix;

int f_i6 (int a, int b, int c, int d, int e, int f);
long long f_ll (int a, long long b, int c, long long d, long long e);
double f_d (double a, int b, float c, double d, float e, double f, double g, double h, double i, double j, float k);
float f_f (float a, float b, int c, float d);
int f_s (s4 a, s8 b, s12 c, s20 d, int e);
float f_hf3 (hf3 a, float b, hf3 c);
double f_hd2 (int a, hd2 b, double c);
double f_mix (mix a, int b, mix c);
s4 r_s4 (int a);
s8 r_s8 (int a);
s20 r_s20 (int a);
hf3 r_hf3 (float a);
hd2 r_hd2 (double a);
long long r_ll (long long a);
double r_d (double a);
long long f_var (int n, ...);
double f_vard (int n, ...);

/* the other way: gcc's code calls these, which abi_main.c defines */
int cb_i6 (int a, int b, int c, int d, int e, int f);
long long cb_ll (int a, long long b, int c, long long d, long long e);
double cb_d (double a, int b, float c, double d, float e, double f, double g, double h, double i, double j, float k);
int cb_s (s4 a, s8 b, s12 c, s20 d, int e);
s20 cb_r_s20 (int a);
hd2 cb_r_hd2 (double a);
long long cb_var (int n, ...);
int g_i6 (void);
long long g_ll (void);
double g_d (void);
int g_s (void);
int g_r_s20 (void);
double g_r_hd2 (void);
long long g_var (void);
long long g_ptr (long long (*f) (int, long long, int, long long, long long));
int g_write (const char *s, int n);
#if defined __aarch64__ || defined __x86_64__
/* the shapes of the 64-bit ABIs (AAPCS64, SysV x86_64): the stack's 8-byte
   slots past the registers, structs of 16 bytes in two registers or (past
   them) on the stack, larger ones (by the address of a copy on aarch64, by
   their bytes on the stack on x86_64), hfas of four, long doubles in q or
   xmm registers (binary128), va_list passed on between gcc's code and
   ttpc's */
#include <stdarg.h>
typedef struct { long a, b; } s16;
typedef struct { long a, b, c; } s24;
typedef struct { double a, b, c, d; } hd4;
typedef struct { float a, b, c, d; } hf4;
typedef struct { long double a, b; } hq2;
long f_i10 (int a, int b, int c, int d, int e, int f, int g, int h, int i, int j);
double f_mixn (int a, double b, int c, double d, int e, double f, int g, double h, int i, double j, int k, double l,
               int m, double n, int o, double p, int q, double r, int s, float t);
long f_s16 (int a, int b, int c, int d, int e, int f, int g, s16 x, int h);
long f_s16r (int a, s16 x, s16 y);
long f_s24 (s24 x, int y);
long f_s24mod (s24 x);
long f_s24stk (int a, int b, int c, int d, int e, int f, int g, int h, s24 x, int y);
double f_hd4 (hd4 a, hd4 b, hd4 c);
float f_hf4 (float a, hf4 b);
hd4 r_hd4 (double a);
hf4 r_hf4 (float a);
s16 r_s16 (long a);
long double f_ld (int a, long double b, double c, long double d);
long double r_ld2 (hq2 a);
hq2 r_hq2 (long double a, long double b);
long double f_varld (int n, ...);
long long f_vsum (int n, va_list ap);
long long f_vwrap (int n, ...);
long cb_i10 (int a, int b, int c, int d, int e, int f, int g, int h, int i, int j);
double cb_mixn (int a, double b, int c, double d, int e, double f, int g, double h, int i, double j, int k, double l,
                int m, double n, int o, double p, int q, double r, int s, float t);
long cb_s16 (int a, int b, int c, int d, int e, int f, int g, s16 x, int h);
long cb_s24mod (s24 x);
double cb_hd4 (hd4 a, hd4 b, hd4 c);
float cb_f (float a, float b, int c, float d);
hd4 cb_r_hd4 (double a);
s16 cb_r_s16 (long a);
long double cb_ld (int a, long double b, double c, long double d);
long double cb_varld (int n, ...);
long long cb_vsum (int n, va_list ap);
long long cb_vard (int n, ...);
long g_i10 (void);
double g_mixn (void);
long g_s16 (void);
long g_s24mod (void);
double g_hd4 (void);
float g_f (void);
double g_r_hd4 (void);
long g_r_s16 (void);
long double g_ld (void);
long double g_varld (void);
long long g_vard (void);
#endif
#ifdef __x86_64__
/* the SysV ABI's own shapes: a struct's eightbytes in a general and an xmm
   register, an int and a float in one eightbyte (a general one), structs
   past rdi..r9 on the stack, va_arg of structs in registers and in memory */
typedef struct { double d; long l; } dl;
typedef struct { int i; float f; } ifl;
typedef struct { float f; int i; double d; } fid;
long f_dl (dl a, dl b, dl c, dl d, dl e, dl f, dl g);
double f_ifl (ifl a, fid b);
dl r_dl (double d, long l);
fid r_fid (float f, int i, double d);
long f_vs (int n, ...);
long cb_dl (dl a, dl b, dl c, dl d, dl e, dl f, dl g);
dl cb_r_dl (double d, long l);
fid cb_r_fid (float f, int i, double d);
long cb_vs (int n, ...);
long g_dl (void);
double g_r_dl (void);
double g_r_fid (void);
long g_vs (void);
#endif
