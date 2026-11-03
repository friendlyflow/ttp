/* fixed point, on arm: ttpc's operators, each saturating and rounding as gcc's own calls of libgcc do; its literals, conversions and the usual conversions */
union UF { float f; unsigned u; }; union UD { double f; unsigned long long u; };
#define BITS(T) union u_##T { T f; unsigned long long u; }; static unsigned long long b_##T (T x) { union u_##T v; v.u = 0; v.f = x; return v.u; }
typedef short _Fract fq1; typedef _Fract fq2; typedef long _Fract fq3; typedef short _Accum fq4; typedef _Accum fq5; typedef long _Accum fq6;
typedef unsigned short _Fract fq7; typedef unsigned _Fract fq8; typedef unsigned long _Fract fq9; typedef unsigned short _Accum fq10; typedef unsigned _Accum fq11; typedef unsigned long _Accum fq12;
typedef _Sat short _Fract fq13; typedef _Sat _Fract fq14; typedef _Sat long _Fract fq15; typedef _Sat short _Accum fq16; typedef _Sat _Accum fq17; typedef _Sat long _Accum fq18;
typedef _Sat unsigned short _Fract fq19; typedef _Sat unsigned _Fract fq20; typedef _Sat unsigned long _Fract fq21; typedef _Sat unsigned short _Accum fq22; typedef _Sat unsigned _Accum fq23; typedef _Sat unsigned long _Accum fq24;
#define ALL(M) M(fq1) M(fq2) M(fq3) M(fq4) M(fq5) M(fq6) M(fq7) M(fq8) M(fq9) M(fq10) M(fq11) M(fq12) M(fq13) M(fq14) M(fq15) M(fq16) M(fq17) M(fq18) M(fq19) M(fq20) M(fq21) M(fq22) M(fq23) M(fq24)
ALL(BITS)
#define SIGNED(M) M(fq1) M(fq2) M(fq3) M(fq4) M(fq5) M(fq6) M(fq13) M(fq14) M(fq15) M(fq16) M(fq17) M(fq18)
#define OPS(T) static void op_##T (T a, T b, int n) { w (b_##T (a + b)); w (b_##T (a - b)); w (b_##T (a * b)); if (b != 0) w (b_##T (a / b)); w (a < b); w (a > b); w (a <= b); w (a >= b); w (a == b); w (a != b); w (b_##T (a << n)); w (b_##T (a >> n)); w (b_##T (a ? a : b)); w (!a); if (a) w (1); \
   w ((int)a); w ((long long)a); w ((unsigned)a); w ((signed char)a); { union UF v; v.f = a; w (v.u); } { union UD v; v.f = a; w (v.u); } }
ALL(OPS)
#define NEG(T) static void neg_##T (T a) { w (b_##T (-a)); }
SIGNED(NEG)
/* (the literal's own value: non-saturating gcc types) */
fq1 gfq1 = 0.5hr; fq2 gfq2 = -0.25r; fq3 gfq3 = 0.125lr; fq4 gfq4 = 3.5hk; fq5 gfq5 = -100.125k; fq6 gfq6 = 123456.75lk; fq7 gfq7 = 0.75uhr; fq8 gfq8 = 0.5ur; fq9 gfq9 = 0.0625ulr; fq10 gfq10 = 200.5uhk; fq11 gfq11 = 60000.25uk; fq12 gfq12 = 3000000000.5ulk;
fq13 gfq13 = 0.5hr; fq18 gfq18 = -7.5lk; fq24 gfq24 = 42.0ulk;
struct S { char c; fq1 a; fq5 b; fq6 d; } gfqs = { 1, 0.25hr, 2.5k, -1.5lk };
fq5 fqaddk(fq5 a, fq5 b) { return a + b; }
fq6 fqaddlk(int n, fq6 a, fq2 c, fq6 b) { return a + b + c; }
static void fxops (void) {
  volatile int ii = 3; volatile long long ll = 5; volatile float ff = 0.375f; volatile double dd = -1.625; volatile unsigned uu = 2;
#define TEST(T, A, B, N) { T a = A, b = B; op_##T (a, b, N); }
  TEST(fq1, 0.5hr, 0.25hr, 1) TEST(fq1, -0.75hr, 0.5hr, 2) TEST(fq2, 0.5r, 0.25r, 1) TEST(fq2, -0.75r, 0.5r, 2) TEST(fq3, 0.5lr, 0.25lr, 1) TEST(fq3, -0.75lr, -0.5lr, 3)
  TEST(fq4, 1.5hk, 2.25hk, 1) TEST(fq4, -100.5hk, 3.5hk, 2) TEST(fq5, 1.5k, 2.25k, 1) TEST(fq5, -30000.5k, 3.5k, 2) TEST(fq6, 1.5lk, 2.25lk, 1) TEST(fq6, -2000000000.5lk, 3.5lk, 2)
  TEST(fq7, 0.5uhr, 0.25uhr, 1) TEST(fq8, 0.5ur, 0.25ur, 1) TEST(fq9, 0.5ulr, 0.25ulr, 1) TEST(fq10, 1.5uhk, 2.25uhk, 1) TEST(fq11, 1.5uk, 2.25uk, 1) TEST(fq12, 1.5ulk, 2.25ulk, 1)
  TEST(fq13, 0.75hr, 0.5hr, 1) TEST(fq13, -0.75hr, 0.5hr, 2) TEST(fq14, 0.75r, 0.5r, 1) TEST(fq14, -0.75r, 0.5r, 2) TEST(fq15, 0.75lr, 0.5lr, 1) TEST(fq15, -0.75lr, 0.5lr, 2)
  TEST(fq16, 100.5hk, 100.25hk, 1) TEST(fq16, -100.5hk, 100.25hk, 2) TEST(fq17, 30000.5k, 30000.25k, 1) TEST(fq17, -30000.5k, 30000.25k, 2) TEST(fq18, 2000000000.5lk, 2000000000.25lk, 1) TEST(fq18, -2000000000.5lk, 2000000000.25lk, 2)
  TEST(fq19, 0.75uhr, 0.5uhr, 1) TEST(fq20, 0.75ur, 0.5ur, 1) TEST(fq21, 0.75ulr, 0.5ulr, 1) TEST(fq22, 200.5uhk, 100.25uhk, 1) TEST(fq23, 60000.5uk, 30000.25uk, 1) TEST(fq24, 4000000000.5ulk, 2000000000.25ulk, 1)
#define N(T, A) { T a = A; neg_##T (a); }
  N(fq1, 0.5hr) N(fq2, 0.5r) N(fq3, 0.5lr) N(fq4, 1.5hk) N(fq5, 1.5k) N(fq6, 1.5lk) N(fq13, -0.5hr) N(fq14, -0.5r) N(fq15, -0.5lr) N(fq16, -1.5hk) N(fq17, -1.5k) N(fq18, -1.5lk)
  /* conversions among them, ints, floats; both forms of sat */
  { fq5 a = 2.5k; fq1 x = a; w (b_fq1(x)); fq13 y = a; w (b_fq13(y)); fq6 z = a; w (b_fq6(z)); fq3 u = a; w (b_fq3(u)); fq15 v = a; w (b_fq15(v)); fq11 wv = a; w (b_fq11(wv)); fq23 s = -a; w (b_fq23(s)); }
  { fq6 a = -2000000000.5lk; fq5 x = a; w (b_fq5(x)); fq17 y = a; w (b_fq17(y)); fq4 z = a; w (b_fq4(z)); fq16 wv = a; w (b_fq16(wv)); }
  { fq5 a = ii; w (b_fq5(a)); fq17 c = ll; w (b_fq17(c)); fq1 d = ii; w (b_fq1(d)); fq13 e = ii; w (b_fq13(e)); fq11 f = uu; w (b_fq11(f)); fq23 g = uu; w (b_fq23(g)); fq6 h = ll; w (b_fq6(h)); }
  { fq5 a = ff; w (b_fq5(a)); fq17 c = dd; w (b_fq17(c)); fq2 d = ff; w (b_fq2(d)); fq14 e = dd; w (b_fq14(e)); fq12 f = ff; w (b_fq12(f)); }
  /* the usual conversions */
  { fq1 a = 0.5hr; fq5 b = 1.5k; w (b_fq5(a + b)); fq13 c = 0.5hr; w (b_fq17(c + b)); w (b_fq5(b + ii)); w (b_fq5(ii * b)); fq7 d = 0.5uhr; w (b_fq1(a + d)); fq11 e = 1.5uk; w (b_fq11(e + uu)); w (b_fq5(b + e)); w (a < b); { union UF v; v.f = b + ff; w (v.u); } { union UD v; v.f = b * dd; w (v.u); } }
  w (b_fq1(gfq1)); w (b_fq2(gfq2)); w (b_fq3(gfq3)); w (b_fq4(gfq4)); w (b_fq5(gfq5)); w (b_fq6(gfq6)); w (b_fq7(gfq7)); w (b_fq8(gfq8)); w (b_fq9(gfq9)); w (b_fq10(gfq10)); w (b_fq11(gfq11)); w (b_fq12(gfq12)); w (b_fq13(gfq13)); w (b_fq18(gfq18)); w (b_fq24(gfq24));
  w (gfqs.c); w (b_fq1(gfqs.a)); w (b_fq5(gfqs.b)); w (b_fq6(gfqs.d)); w (sizeof(struct S)); w (_Alignof(fq6)); w (sizeof(fq1)); w (sizeof(fq2)); w (sizeof(fq3)); w (sizeof(fq4)); w (sizeof(fq5)); w (sizeof(fq6));
  w (b_fq5(fqaddk(1.5k, 2.25k))); w (b_fq6(fqaddlk(1, 2.5lk, 0.5r, 3.5lk)));
  { fq5 (*p)(fq5, fq5) = fqaddk; w (b_fq5(p(4.5k, -1.25k))); fq5 x = 2.5k; fq5 *q = &x; *q = *q * 2; w (b_fq5(x)); fq5 arr[2]; arr[1] = x; w (b_fq5(arr[1])); x += 1; w (b_fq5(x)); x -= 0.5k; x *= 2; x /= 3; x <<= 1; x >>= 2; w (b_fq5(x)); }
}
