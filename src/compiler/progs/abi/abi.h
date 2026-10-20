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
