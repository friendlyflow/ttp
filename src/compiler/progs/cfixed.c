/* progs/cfixed.ff is c2ff's translation of this file for arm (with write a system
   call), each line of its output checked equal to gcc's on arm: fixed point's
   sizes, literals, storage and ABI within ttpc, on every target. Its operations
   call libgcc's fixed-bit.c, which gccrt checks on arm. */
extern long write(int, const void *, unsigned long);
static char buf[64];
static void px(unsigned long long v) { static const char h[] = "0123456789abcdef"; int i; for (i = 0; i < 16; i++) buf[i] = h[(v >> (60 - 4 * i)) & 15]; buf[16] = '\n'; write(1, buf, 17); }
#define BITS(N, T) union u##N { T f; unsigned long long u; }; static unsigned long long fb##N (T x) { union u##N v; v.u = 0; v.f = x; return v.u; }
BITS(1, short _Fract)
BITS(2, _Fract)
BITS(3, long _Fract)
BITS(4, short _Accum)
BITS(5, _Accum)
BITS(6, long _Accum)
BITS(7, unsigned short _Fract)
BITS(8, unsigned _Fract)
BITS(9, unsigned long _Fract)
BITS(10, unsigned short _Accum)
BITS(11, unsigned _Accum)
BITS(12, unsigned long _Accum)
BITS(13, _Sat short _Fract)
BITS(14, _Sat unsigned long _Accum)
short _Fract g1 = 0.5hr; _Fract g2 = -0.25r; long _Fract g3 = 0.125lr; short _Accum g4 = 3.5hk; _Accum g5 = -100.125k; long _Accum g6 = 123456.75lk;
unsigned short _Fract g7 = 0.75uhr; unsigned _Fract g8 = 0.5ur; unsigned long _Fract g9 = 0.0625ulr; unsigned short _Accum g10 = 200.5uhk; unsigned _Accum g11 = 60000.25uk; unsigned long _Accum g12 = 3000000000.5ulk;
_Sat short _Fract g13 = 0.5hr; _Sat unsigned long _Accum g14 = 42.0ulk;
struct S { char c; short _Fract a; _Accum b; long _Accum d; } gs = { 1, 0.25hr, 2.5k, -1.5lk };
_Accum id(_Accum a, _Accum b) { return b; }
long _Accum idl(int n, long _Accum a, _Fract c, long _Accum b) { return n ? a : b; }
short _Fract ids(short _Fract a, short _Fract b, short _Fract c, short _Fract d, short _Fract e) { return e; }
struct S2 { _Fract x; _Accum y; };
struct S2 sw(struct S2 s) { s.x = -0.5r; return s; }
int main(void) {
  short _Fract va1 = -0.75hr; _Fract va2 = 0.5r; long _Fract va3 = 0.5lr; short _Accum va4 = -1.5hk; _Accum va5 = 1.5k; long _Accum va6 = -2.25lk; unsigned long _Accum va12 = 1.5ulk;
  px(fb1(g1)); px(fb2(g2)); px(fb3(g3)); px(fb4(g4)); px(fb5(g5)); px(fb6(g6)); px(fb7(g7)); px(fb8(g8)); px(fb9(g9)); px(fb10(g10)); px(fb11(g11)); px(fb12(g12)); px(fb13(g13)); px(fb14(g14));
  px(gs.c); px(fb1(gs.a)); px(fb5(gs.b)); px(fb6(gs.d));
  px(fb1(va1)); px(fb2(va2)); px(fb3(va3)); px(fb4(va4)); px(fb5(va5)); px(fb6(va6)); px(fb12(va12));
  px(sizeof(short _Fract)); px(sizeof(_Fract)); px(sizeof(long _Fract)); px(sizeof(short _Accum)); px(sizeof(_Accum)); px(sizeof(long _Accum)); px(sizeof(_Sat unsigned long _Accum)); px(sizeof(struct S));
  px(fb5(id(1.5k, 2.25k))); px(fb6(idl(1, 2.5lk, 0.5r, 3.5lk))); px(fb6(idl(0, 2.5lk, 0.5r, 3.5lk))); px(fb1(ids(0.5hr, 0.25hr, 0.125hr, -0.5hr, -0.25hr)));
  { struct S2 s, t; s.x = 0.5r; s.y = 3.5k; t = sw(s); px(fb2(t.x)); px(fb5(t.y)); }
  { _Accum (*p)(_Accum, _Accum) = id; px(fb5(p(4.5k, -1.25k))); _Accum x = 2.5k; _Accum *q = &x; px(fb5(*q)); _Accum arr[2]; arr[1] = x; px(fb5(arr[1])); if (va5) px(1); if (!va5) px(2); }
  return 0;
}
