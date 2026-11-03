/* progs/ci128.ff is c2ff's translation of this file (with write as a system
   call), each line of its output checked equal to gcc's. Division is long
   division of its own here: the program is ttpc's alone. */
typedef __int128 i128;
typedef unsigned __int128 u128;
extern long write(int, const void *, unsigned long);
static char buf[64];
static void puts_(const char *s) { long n = 0; while (s[n]) n++; write(1, s, n); }
static void px(u128 v) { static const char h[] = "0123456789abcdef"; int i; for (i = 0; i < 32; i++) buf[i] = h[(unsigned long)(v >> (124 - 4 * i)) & 15]; buf[32] = '\n'; buf[33] = 0; puts_(buf); }
static void pi(long v) { px((u128)v); }
static u128 udm(u128 n, u128 d, u128 *rem) { u128 q = 0, r = 0; int i; for (i = 127; i >= 0; i--) { r = (r << 1) | ((n >> i) & 1); if (r >= d) { r -= d; q |= (u128)1 << i; } } *rem = r; return q; }
u128 __udivti3(u128 n, u128 d) { u128 r; return udm(n, d, &r); }
u128 __umodti3(u128 n, u128 d) { u128 r; udm(n, d, &r); return r; }
i128 __divti3(i128 n, i128 d) { u128 r; u128 q = udm(n < 0 ? -(u128)n : n, d < 0 ? -(u128)d : d, &r); return (n < 0) != (d < 0) ? -q : q; }
i128 __modti3(i128 n, i128 d) { u128 r; udm(n < 0 ? -(u128)n : n, d < 0 ? -(u128)d : d, &r); return n < 0 ? -r : r; }
struct s { char c; i128 x; short d; u128 y; };
i128 g0; u128 garr[3]; struct s gs;
i128 g1 = 5; i128 g2 = -5; u128 g3 = 0xffffffffffffffffULL; u128 g6[2] = { 1, -1 }; struct { long a; i128 x; } g7 = { 1, -2 };
static i128 volatile vi;
i128 add(i128 a, i128 b) { return a + b; }
u128 mul(u128 a, u128 b) { return a * b; }
i128 mixed(int a, i128 b, long c, u128 d, int e, i128 f) { return a + b + c + (i128)d + e + f; }
i128 many(long a, long b, long c, long d, long e, i128 f, long g, i128 h) { return a + b + c + d + e + f + g + h; }
struct s setit(struct s *p) { p->c = 3; p->x = -5; p->d = 7; p->y = ~(u128)0 - 1; return *p; }
int main(void) {
  i128 a = 0x123456789abcdefLL; u128 b = 0xfedcba9876543210ULL; int i;
  i128 *pa = &a; u128 arr[4];
  puts_("start\n");
  px(a); px(b);
  a = (a << 64) | 0x1122334455667788LL; b = (b << 60) + 7;
  px(a); px(b);
  px(a + b); px(a - b); px(b - a); px(a * b); px(a & b); px(a | b); px(a ^ b); px(~a); px(-a); px(!a); px(!!a);
  for (i = 0; i < 128; i += 13) { px(a << i); px(a >> i); px(b >> i); px(-a >> i); }
  px(a << 64); px(a >> 64); px(b >> 64); px(-a >> 64); px(a << 63); px(a >> 63); px(b >> 65); px(-a >> 127);
  px(a < b); px(a > b); px(a <= b); px(a >= b); px(a == b); px(a != b);
  px((i128)-1 < (i128)0); px((u128)-1 < (u128)0); px(-a < a); px(a < -a); px((u128)(-a) < (u128)a); px((u128)(-a) > (u128)a);
  px(a < a); px(a <= a); px(a >= a); px(a > a); px((a ^ 1) == a); px((a + ((i128)1 << 64)) == a); px((a + ((i128)1 << 64)) > a);
  px(b / 77); px(b % 77); px(b / (u128)a); px(b % (u128)a); px(-a / 12345); px(-a % 12345); px(a / -3); px(a % -3);
  px((i128)(int)-3); px((u128)(unsigned)-3); px((i128)(long)-3); px((u128)(unsigned long)-3); px((u128)(short)-3); px((i128)(char)65); px((i128)(signed char)-65);
  pi((int)(a >> 3)); pi((short)(a >> 3)); pi((signed char)(a>>3)); pi((long)(a>>3)); pi((unsigned)(a>>3)); pi((unsigned char)(a >> 3));
  a += 5; px(a); a -= 7; px(a); a *= 3; px(a); a <<= 3; px(a); a >>= 1; px(a); a |= 1; a &= ~(i128)2; a ^= 9; px(a); a /= 3; px(a); a %= 100000; px(a);
  a++; px(a); ++a; px(a); a--; px(a); --a; px(a); px(a++); px(a--); px(*pa);
  b = ~(u128)0; b++; px(b); b--; px(b);
  arr[0] = 1; arr[1] = arr[0] << 70; arr[2] = arr[1] + arr[0]; arr[3] = arr[2] * arr[2];
  for (i = 0; i < 4; i++) px(arr[i]);
  px(sizeof(i128)); px(_Alignof(i128)); px(sizeof(struct s)); px(_Alignof(struct s)); px(__builtin_offsetof(struct s, x)); px(__builtin_offsetof(struct s, y)); px(sizeof arr);
  { char c; i128 x; char *p = &c; c = 1; x = 2; px(((unsigned long)&x & 15)); (void)p; }
  g0 = a; garr[1] = b; px(g0); px(garr[1]); px(g1); px(g2); px(g3); px(g6[0]); px(g6[1]); px(g7.x);
  gs.x = a; gs.y = b; px(gs.x + gs.y);
  { struct s t, u; u = setit(&t); px(u.x); px(u.y); px(u.c); px(u.d); }
  px(add(a, 1)); px(mul(b, 3)); px(mixed(1, 2, 3, 4, 5, 6)); px(many(1,2,3,4,5,6,7,8));
  { i128 (*f)(i128, i128) = add; px(f(10, -20)); }
  px(a ? a : b); px(0 ? a : b); if (a) puts_("t\n"); else puts_("f\n"); while (a) { a = 0; puts_("w\n"); } if (!a) puts_("z\n");
  px(a && b); px(a || b);
  vi = 33; px(vi + vi);
  switch ((i128)5) { case 4: puts_("4\n"); break; case 5: puts_("5\n"); break; default: puts_("d\n"); }
  { u128 s = 3; px((long)s + s); px(s + (unsigned long)-1); px(s + (int)-1); px((i128)-1 + (unsigned long)2); px((i128)-1 * (unsigned)2); }
  return 0;
}
