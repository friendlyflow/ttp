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
#if defined __aarch64__ || defined __x86_64__ || defined __riscv
/* the shapes of the 64-bit ABIs (AAPCS64, SysV x86_64, lp64d): the stack's
   8-byte slots past the registers, structs of 16 bytes in two registers or
   (past them) on the stack, larger ones (by the address of a copy on aarch64
   and riscv64, by their bytes on the stack on x86_64), hfas of four, long
   doubles in q or xmm registers or a pair of general ones (binary128),
   va_list passed on between gcc's code and ttpc's */
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
#ifdef __arm__
/* base pcs: arm's base standard, C's pcs ("aapcs") (libgcc's __aeabi_d2lz
   ...): floats and doubles in core registers and on the stack, both ways,
   through a pointer of the function's type too */
double f_pcs (float a, double b, int c, double d, float e) __attribute__ ((pcs ("aapcs")));
float f_pcsf (int a, float b) __attribute__ ((pcs ("aapcs")));
double cb_pcs (float a, double b, int c, double d, float e) __attribute__ ((pcs ("aapcs")));
float cb_pcsf (int a, float b) __attribute__ ((pcs ("aapcs")));
double g_pcs (void);
float g_pcsf (void);
#endif
#ifdef __x86_64__
/* the SysV ABI's x87 classes of a result (gcc's default long double, the
   x87's): a struct of one long double in st0, as a long double; a complex
   long double in st0 and st1 */
typedef struct { long double x; } ld1;
typedef _Complex long double cld;
ld1 r_ld1 (long double a);
cld r_cld (long double re, long double im);
ld1 cb_ld1 (long double a);
cld cb_cld (long double re, long double im);
long double g_ld1 (void);
long double g_cld (void);
/* _Complex __float128: in memory, as an argument and as a result */
#ifdef __clang__
typedef _Complex __float128 cq;
#else
typedef _Complex _Float128 cq;
#endif
cq r_cq (__float128 re, __float128 im);
int eq_cq (cq z, __float128 re, __float128 im);
cq cb_cq (cq z);
int g_cq (void);
#endif
#if defined __x86_64__ || defined __riscv
/* the SysV ABI's own shapes (on riscv64: a double and a long, an int and a
   float in an fa and a general register, three fields as two words): a struct's eightbytes in a general and an xmm
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
#ifdef __riscv
/* the lp64d ABI's own shapes: structs of two floats, of a float and an int,
   of one double, of a char and a double in fa (and a) registers; as words
   where the fa or the general registers run out; a long double split
   between a7 and the stack; integers narrower than a word as their
   registers hold them (extended by their sign to 32 bits, then
   sign-extended), both ways */
typedef struct { float a, b; } ff2;
typedef struct { float f; int i; } fi;
typedef struct { double d; } d1;
typedef struct { char c; double d; } cd;
long f_ff2 (ff2 a, fi b, d1 c, cd d);
double f_fpout (double a, double b, double c, double d, double e, double f, double g, hd2 x, ff2 y);
double f_gpout (int a, int b, int c, int d, int e, int f, int g, int h, mix x, double y);
long double f_ldsplit (int a, int b, int c, int d, int e, int f, int g, long double x, int h);
long f_raw4 (unsigned a);
long f_raw2 (unsigned short a);
long f_raw1 (signed char a);
ff2 r_ff2 (float a);
fi r_fi (float f, int i);
cd r_cd (char c, double d);
long cb_ff2 (ff2 a, fi b, d1 c, cd d);
double cb_fpout (double a, double b, double c, double d, double e, double f, double g, hd2 x, ff2 y);
double cb_gpout (int a, int b, int c, int d, int e, int f, int g, int h, mix x, double y);
long double cb_ldsplit (int a, int b, int c, int d, int e, int f, int g, long double x, int h);
int cb_narrow (unsigned a, unsigned short b, signed char c, int d);
unsigned cb_u32 (int a);
unsigned short cb_u16 (int a);
fi cb_r_fi (float f, int i);
cd cb_r_cd (char c, double d);
long g_ff2 (void);
double g_fpout (void);
double g_gpout (void);
long double g_ldsplit (void);
int g_narrow (void);
int g_u32 (void);
int g_u16 (void);
double g_r_fi (void);
double g_r_cd (void);
#endif
#ifdef __SIZEOF_INT128__
/* i128 and u128: registers (x86_64 any two, aarch64 an even pair, riscv64
   any two, an unnamed one an even pair), split (riscv64), on the stack
   (16-aligned), in structs, by value and as results, va_arg */
typedef __int128 i128_t;
typedef unsigned __int128 u128_t;
typedef struct { i128_t x; } si;
typedef struct { long a; i128_t x; } sli;
typedef struct { double d; i128_t x; } sdi;
#define BIG(n) ((((i128_t) (n)) << 64) + (n) * 3 + 1)
#define W2(a, b) ((a) + 3 * (b))
#define W4(a, b, c, d) ((a) + 3 * (b) + 5 * (c) + 7 * (d))
#define W6(a, b, c, d, e, f) ((a) + 3 * (b) + 5 * (c) + 7 * (d) + 9 * (e) + 11 * (f))
static inline long qbits (double d) { union { double d; long l; } u; u.d = d; return u.l; }
i128_t f_q2 (i128_t a, i128_t b);
i128_t f_q4 (int a, i128_t b, int c, i128_t d);
i128_t f_q9 (long a, long b, long c, long d, long e, i128_t f, long g, i128_t h, long i);
u128_t f_q8 (long a, long b, long c, long d, long e, long f, long g, u128_t h, long i);
i128_t f_q6 (i128_t a, i128_t b, i128_t c, i128_t d, i128_t e, long f);
i128_t f_qs (si a, sli b, sdi c, si d);
si r_qs (i128_t a);
sli r_qsl (long a, i128_t b);
i128_t f_qv (int n, ...);
i128_t cb_q2 (i128_t a, i128_t b);
i128_t cb_q4 (int a, i128_t b, int c, i128_t d);
i128_t cb_q9 (long a, long b, long c, long d, long e, i128_t f, long g, i128_t h, long i);
u128_t cb_q8 (long a, long b, long c, long d, long e, long f, long g, u128_t h, long i);
i128_t cb_q6 (i128_t a, i128_t b, i128_t c, i128_t d, i128_t e, long f);
i128_t cb_qs (si a, sli b, sdi c, si d);
si cb_r_qs (i128_t a);
sli cb_r_qsl (long a, i128_t b);
i128_t cb_qv (int n, ...);
i128_t g_q2 (void);
i128_t g_q4 (void);
i128_t g_q9 (void);
u128_t g_q8 (void);
i128_t g_q6 (void);
i128_t g_qs (void);
i128_t g_r_qs (void);
i128_t g_r_qsl (void);
i128_t g_qv (void);
#endif
#if defined __x86_64__ || defined __aarch64__ || defined __riscv
/* float16 and bfloat16: a float's registers, low half (riscv64 boxed); in structs */
typedef _Float16 h_t;
typedef __bf16 b_t;
typedef struct { h_t x; h_t y; } h2;
typedef struct { h_t x; int i; } hin;
typedef struct { h_t a, b, c, d, e; } h5;
/* (by way of memory: gcc's bits of a register have forms ttpc has not) */
static inline h_t H (unsigned short u) { volatile unsigned short v = u; return *(volatile h_t *) &v; }
static inline unsigned short HB (h_t f) { volatile h_t v = f; return *(volatile unsigned short *) &v; }
static inline b_t B (unsigned short u) { volatile unsigned short v = u; return *(volatile b_t *) &v; }
static inline unsigned short BB (b_t f) { volatile b_t v = f; return *(volatile unsigned short *) &v; }
h_t f_h2 (h_t a, h_t b);
b_t f_b2 (int a, b_t b, float c);
h_t f_h10 (h_t a, h_t b, h_t c, h_t d, h_t e, h_t f, h_t g, h_t h, h_t i, h_t j);
int f_hsum (h_t a, double b, h_t c, long d, b_t e);
int f_h2s (h2 a, hin b, h5 c);
h2 r_h2 (unsigned short a, unsigned short b);
hin r_hin (unsigned short a, int i);
h_t cb_h2 (h_t a, h_t b);
b_t cb_b2 (int a, b_t b, float c);
h_t cb_h10 (h_t a, h_t b, h_t c, h_t d, h_t e, h_t f, h_t g, h_t h, h_t i, h_t j);
int cb_hsum (h_t a, double b, h_t c, long d, b_t e);
int cb_h2s (h2 a, hin b, h5 c);
h2 cb_r_h2 (unsigned short a, unsigned short b);
hin cb_r_hin (unsigned short a, int i);
int g_h2 (void);
int g_b2 (void);
int g_h10 (void);
int g_hsum (void);
int g_h2s (void);
int g_r_h2 (void);
int g_r_hin (void);
/* complex float16: two float16 by each struct path */
typedef _Complex _Float16 hc_t;
h_t f_hci (int n, hc_t z, h_t a);
hc_t r_hc (h_t a, h_t b);
h_t cb_hci (int n, hc_t z, h_t a);
hc_t cb_r_hc (h_t a, h_t b);
int g_hci (void);
int g_r_hc (void);
#endif
#ifdef __arm__
/* float16 on arm (gcc's -mfp16-format=ieee): an s register's low half */
typedef _Float16 ah_t;
static inline ah_t AH (unsigned short u) { volatile unsigned short v = u; return *(volatile ah_t *) &v; }
static inline unsigned short AB (ah_t f) { volatile ah_t v = f; return *(volatile unsigned short *) &v; }
ah_t f_ah2 (ah_t a, ah_t b);
ah_t f_ah3 (ah_t a, double b, float c, int d, ah_t e);
ah_t cb_ah2 (ah_t a, ah_t b);
ah_t cb_ah3 (ah_t a, double b, float c, int d, ah_t e);
int g_ah2 (void);
int g_ah3 (void);
#endif
#ifdef __arm__
/* fixed point on arm: as the integers of their sizes, core registers, a pair for long accum */
typedef struct { _Fract x; _Accum y; } fxs;
typedef long _Accum lk_t;
long _Accum f_fx (short _Fract a, long _Accum b, _Accum c, long _Accum d, _Sat _Fract e, unsigned _Accum f);
int f_fxc (short _Fract a, long _Accum b, _Accum c, long _Accum d, _Sat _Fract e, unsigned _Accum f);
fxs f_fxs (fxs a, long _Accum b);
lk_t cb_fx (short _Fract a, long _Accum b, _Accum c, long _Accum d, _Sat _Fract e, unsigned _Accum f);
int cb_fxc (short _Fract a, long _Accum b, _Accum c, long _Accum d, _Sat _Fract e, unsigned _Accum f);
int g_fxc (void);
fxs cb_fxs (fxs a, long _Accum b);
int g_fx (void);
int g_fxs (void);
#endif
