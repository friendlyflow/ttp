/* progs/cf16.ff is c2ff's translation of this file (with write a system call), each
   line of its output checked equal to gcc's: float16 and bfloat16's storage, ABI and
   sign; conversions call libgcc's functions, which gccrt checks. */
typedef _Float16 hf; typedef __bf16 bf;
extern long write(int, const void *, unsigned long);
static char buf[64];
static void px(unsigned long v) { static const char h[] = "0123456789abcdef"; int i; for (i = 0; i < 16; i++) buf[i] = h[(v >> (60 - 4 * i)) & 15]; buf[16] = '\n'; write(1, buf, 17); }
static unsigned short hb(hf x) { union { hf f; unsigned short u; } v; v.f = x; return v.u; }
static unsigned short bb(bf x) { union { bf f; unsigned short u; } v; v.f = x; return v.u; }
static hf hm(unsigned short u) { union { hf f; unsigned short u; } v; v.u = u; return v.f; }
static bf bm(unsigned short u) { union { bf f; unsigned short u; } v; v.u = u; return v.f; }
hf g1 = 1.5f; hf g2 = -2.25f; hf g3[2] = { 1000.0f, 0.0f }; bf g4 = 1.5f; bf g5 = -1000.0f; hf g6 = 65504.0f; hf g7 = 1e-7f;
struct S { char c; hf x; bf y; short z; } gs = { 1, 3.0f, 4.0f, 5 };
hf id2(hf a, hf b) { return b; }
bf idb(int n, bf a, float f, bf b) { return n ? a : b; }
hf many(hf a, hf b, hf c, hf d, hf e, hf f, hf g, hf h, hf i, hf j) { return j; }
struct S2 { hf x; hf y; }; struct S3 { hf x; int i; };
struct S2 sw(struct S2 s) { struct S2 r; r.x = s.y; r.y = s.x; return r; }
struct S3 sh(struct S3 s) { s.i++; return s; }
int main(void) {
  hf a = hm(0x3e00), b = hm(0xc110); bf p = bm(0x3fc0); struct S s; hf *q = &a; hf arr[3];
  px(hb(a)); px(hb(b)); px(bb(p)); px(hb(g1)); px(hb(g2)); px(hb(g3[0])); px(hb(g3[1])); px(bb(g4)); px(bb(g5)); px(hb(g6)); px(hb(g7)); px(hb(gs.x)); px(bb(gs.y)); px(gs.z);
  px(hb(-a)); px(hb(-b));
  s.c = 1; s.x = a; s.y = p; s.z = 5; px(hb(s.x)); px(bb(s.y)); px(s.z); px(sizeof(s)); px(_Alignof(hf)); px(sizeof(bf)); px(__builtin_offsetof(struct S, y));
  arr[0] = a; arr[1] = b; arr[2] = arr[0]; px(hb(arr[2])); px(hb(arr[1])); px(hb(*q)); *q = b; px(hb(a)); a = hm(0x3e00);
  px(hb(id2(a, b))); px(bb(idb(1, p, 2.0f, bm(1)))); px(bb(idb(0, p, 2.0f, bm(1)))); px(hb(many(a,b,a,b,a,b,a,b,a,hm(7))));
  { hf (*f)(hf, hf) = id2; px(hb(f(b, a))); }
  { struct S2 t, u; t.x = a; t.y = b; u = sw(t); px(hb(u.x)); px(hb(u.y)); }
  { struct S3 t, u; t.x = b; t.i = 41; u = sh(t); px(hb(u.x)); px(u.i); }
  return 0;
}
