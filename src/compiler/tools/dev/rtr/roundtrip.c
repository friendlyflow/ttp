/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* roundtrip.c: dev source of tools/roundtrip.ff, src/glibc/roundtrip.pl in
   ff: glibc in ff against the C it was made of, clang's AST of what ff2c
   writes back against clang's AST of glibc's .i, both normalized alike.
   The same output and status as the Perl, which stays as a cross-check
   (make roundtrip-crosscheck). Made a part at a time, each held against
   the Perl's (roundtrip.pl --parts):

     roundtrip --target t --parts unit.rtn

   prints each type's class (tstr), each floating constant as FFold.pm
   folds it and each literal's normal form of a number (flt, ldround), as
   the Perl does. On s2ff's lib.c, copied from tools/dev/s2ff. */

#include "lib.c"

static struct str *target;
static struct str *cat2 (char *a, struct str *b, char *c3) { struct str *s = s_of (a); s_app (s, b); s_cat (s, c3); return s; }
static int t_is (char *t) { return s_is (target, t); }

/* ---- JSON (clang's, and the units' caches): a value is an object (its keys
   and values in order), an array, a string, a number (its text), true,
   false or null */
struct jv { int t; struct str *s; struct vec *k, *v; };
static unsigned char *jp, *je;
static struct jv *jnull;
static void j_fail (char *m) { struct str *x = s_of ("roundtrip: bad JSON: "); s_cat (x, m); s_cat (x, "\n"); die_s (x); }
static void j_ws (void) { while (jp < je && (*jp == ' ' || *jp == '\n' || *jp == '\t' || *jp == '\r')) jp++; }
static struct jv *jv_new (int t) { struct jv *v = alloc (sizeof (struct jv)); v->t = t; return v; }
static void utf8_add (struct str *s, long c)
{
  if (c < 0x80) s_chr (s, (int) c);
  else if (c < 0x800) { s_chr (s, 0xc0 | (int) (c >> 6)); s_chr (s, 0x80 | (int) (c & 63)); }
  else if (c < 0x10000) { s_chr (s, 0xe0 | (int) (c >> 12)); s_chr (s, 0x80 | (int) ((c >> 6) & 63)); s_chr (s, 0x80 | (int) (c & 63)); }
  else { s_chr (s, 0xf0 | (int) (c >> 18)); s_chr (s, 0x80 | (int) ((c >> 12) & 63)); s_chr (s, 0x80 | (int) ((c >> 6) & 63)); s_chr (s, 0x80 | (int) (c & 63)); }
}
static struct str *j_str (void)
{
  struct str *s = s_of ("");
  unsigned char *a;
  jp++;
  for (;;) {
    a = jp;
    while (jp < je && *jp != '"' && *jp != '\\') jp++;
    if (jp > a) s_add (s, a, jp - a);
    if (jp >= je) j_fail ("a string that does not end");
    if (*jp == '"') { jp++; return s; }
    jp++;
    if (jp >= je) j_fail ("an escape that does not end");
    switch (*jp) {
    case 'n': s_chr (s, '\n'); break;
    case 't': s_chr (s, '\t'); break;
    case 'r': s_chr (s, '\r'); break;
    case 'b': s_chr (s, 8); break;
    case 'f': s_chr (s, 12); break;
    case 'u': {
      long c = 0, i;
      for (i = 1; i <= 4; i++) { int d = jp + i < je ? hexv (jp[i]) : -1; if (d < 0) j_fail ("a bad \\u"); c = c * 16 + d; }
      jp += 4;
      /* (a byte of Perl's string: below 256 the byte itself, as JSON::XS has it in a string of bytes) */
      if (c < 256) s_chr (s, (int) c); else utf8_add (s, c);
      break;
    }
    default: s_chr (s, *jp); break;
    }
    jp++;
  }
}
static struct jv *j_val (void)
{
  struct jv *v;
  j_ws ();
  if (jp >= je) j_fail ("no value");
  if (*jp == '{') {
    v = jv_new ('o'); v->k = v_new (); v->v = v_new ();
    jp++; j_ws ();
    if (jp < je && *jp == '}') { jp++; return v; }
    for (;;) {
      j_ws ();
      if (jp >= je || *jp != '"') j_fail ("a key that is no string");
      v_push (v->k, j_str ());
      j_ws ();
      if (jp >= je || *jp != ':') j_fail ("no colon");
      jp++;
      v_push (v->v, j_val ());
      j_ws ();
      if (jp < je && *jp == ',') { jp++; continue; }
      if (jp < je && *jp == '}') { jp++; return v; }
      j_fail ("an object that does not end");
    }
  }
  if (*jp == '[') {
    v = jv_new ('a'); v->v = v_new ();
    jp++; j_ws ();
    if (jp < je && *jp == ']') { jp++; return v; }
    for (;;) {
      v_push (v->v, j_val ());
      j_ws ();
      if (jp < je && *jp == ',') { jp++; continue; }
      if (jp < je && *jp == ']') { jp++; return v; }
      j_fail ("an array that does not end");
    }
  }
  if (*jp == '"') { v = jv_new ('s'); v->s = j_str (); return v; }
  if (je - jp >= 4 && msame (jp, (unsigned char *) "true", 4)) { jp += 4; v = jv_new ('t'); v->s = s_of ("1"); return v; }
  if (je - jp >= 5 && msame (jp, (unsigned char *) "false", 5)) { jp += 5; v = jv_new ('f'); v->s = s_of (""); return v; }
  if (je - jp >= 4 && msame (jp, (unsigned char *) "null", 4)) { jp += 4; return jnull; }
  {
    unsigned char *a = jp;
    while (jp < je && (is_digit (*jp) || *jp == '-' || *jp == '+' || *jp == '.' || *jp == 'e' || *jp == 'E')) jp++;
    if (jp == a) j_fail ("a value that is none");
    v = jv_new ('n'); v->s = s_new (a, jp - a);
    return v;
  }
}
static struct jv *j_parse (struct str *t)
{
  struct jv *v;
  jp = t->p; je = t->p + t->n;
  v = j_val ();
  j_ws ();
  if (jp < je) j_fail ("more after the value");
  return v;
}
/* a key's value of an object, else 0 (Perl's undef: also a null) */
static struct jv *jget (struct jv *o, char *k)
{
  long i, n = slen (k);
  if (!o || o->t != 'o') return 0;
  for (i = 0; i < o->k->n; i++) {
    struct str *x = o->k->v[i];
    if (x->n == n && msame (x->p, (unsigned char *) k, n)) { struct jv *v = o->v->v[i]; return v == jnull ? 0 : v; }
  }
  return 0;
}
/* a value as a string (Perl's), else 0 */
static struct str *jstr (struct jv *o, char *k) { struct jv *v = jget (o, k); return v && v->s ? v->s : 0; }
static int jis (struct jv *o, char *k, char *w) { struct str *s = jstr (o, k); return s && s_is (s, w); }
/* inner, a node's children (Perl's kids) */
static struct vec *empty_vec;
static struct vec *jkids (struct jv *n) { struct jv *v = jget (n, "inner"); return v && v->t == 'a' ? v->v : empty_vec; }
static struct jv *jkid (struct jv *n, long i) { struct vec *k = jkids (n); return i < k->n ? k->v[i] : 0; }
static struct str *jkind (struct jv *n) { struct str *s = n ? jstr (n, "kind") : 0; return s ? s : s_of (""); }
static int kind_is (struct jv *n, char *k) { struct str *s = n ? jstr (n, "kind") : 0; return s && s_is (s, k); }

/* ---- big integers (Math::BigInt's, as FFold uses them): magnitude in
   32-bit limbs, least first */
struct big { unsigned int *d; long n, room; };
static struct big *b_new (long room) { struct big *b = alloc (sizeof (struct big)); b->room = room > 4 ? room : 4; b->d = alloc (b->room * sizeof (unsigned int)); return b; }
static void b_room (struct big *b, long n)
{
  if (n > b->room) { long r = n * 2, i; unsigned int *x = alloc (r * sizeof (unsigned int)); for (i = 0; i < b->n; i++) x[i] = b->d[i]; b->d = x; b->room = r; }
}
static void b_trim (struct big *b) { while (b->n && !b->d[b->n - 1]) b->n--; }
static struct big *b_of (unsigned long v) { struct big *b = b_new (4); while (v) { b->d[b->n++] = (unsigned int) (v & 0xffffffff); v >>= 32; } return b; }
static struct big *b_copy (struct big *a) { struct big *b = b_new (a->n + 1); long i; for (i = 0; i < a->n; i++) b->d[i] = a->d[i]; b->n = a->n; return b; }
static int b_zero (struct big *a) { return a->n == 0; }
static int b_odd (struct big *a) { return a->n && (a->d[0] & 1); }
static long b_bits (struct big *a)   /* length of as_bin without 0b (0: 1) */
{
  long n;
  unsigned int t;
  if (!a->n) return 1;
  n = (a->n - 1) * 32; t = a->d[a->n - 1];
  while (t) { n++; t >>= 1; }
  return n;
}
static int b_cmp (struct big *a, struct big *b)
{
  long i;
  if (a->n != b->n) return a->n < b->n ? -1 : 1;
  for (i = a->n - 1; i >= 0; i--) if (a->d[i] != b->d[i]) return a->d[i] < b->d[i] ? -1 : 1;
  return 0;
}
static void b_muladd (struct big *a, unsigned int m, unsigned int c)   /* a = a * m + c */
{
  long i;
  unsigned long carry = c;
  for (i = 0; i < a->n; i++) { unsigned long x = (unsigned long) a->d[i] * m + carry; a->d[i] = (unsigned int) (x & 0xffffffff); carry = x >> 32; }
  if (carry) { b_room (a, a->n + 1); a->d[a->n++] = (unsigned int) carry; }
}
static struct big *b_shl (struct big *a, long k)   /* a << k, new */
{
  struct big *b;
  long w = k / 32, s = k % 32, i;
  if (k <= 0 || !a->n) { b = b_copy (a); if (k < 0) { /* (blsft of a negative count: a right shift) */ long wq = -k / 32, sq = -k % 32; struct big *r = b_new (a->n); for (i = wq; i < a->n; i++) { unsigned long x = a->d[i] >> sq; if (sq && i + 1 < a->n) x |= (unsigned long) a->d[i + 1] << (32 - sq); r->d[r->n++] = (unsigned int) (x & 0xffffffff); } b_trim (r); return r; } return b; }
  b = b_new (a->n + w + 2);
  for (i = 0; i < w; i++) b->d[i] = 0;
  b->n = w;
  {
    unsigned int carry = 0;
    for (i = 0; i < a->n; i++) {
      unsigned long x = ((unsigned long) a->d[i] << s) | carry;
      b->d[b->n++] = (unsigned int) (x & 0xffffffff);
      carry = s ? (unsigned int) (x >> 32) : 0;
    }
    if (carry) b->d[b->n++] = carry;
  }
  b_trim (b);
  return b;
}
static struct big *b_add (struct big *a, struct big *b)
{
  struct big *r = b_new ((a->n > b->n ? a->n : b->n) + 1);
  long i, n = a->n > b->n ? a->n : b->n;
  unsigned long carry = 0;
  for (i = 0; i < n; i++) {
    unsigned long x = carry + (i < a->n ? a->d[i] : 0) + (i < b->n ? b->d[i] : 0);
    r->d[i] = (unsigned int) (x & 0xffffffff); carry = x >> 32;
  }
  r->n = n;
  if (carry) r->d[r->n++] = (unsigned int) carry;
  return r;
}
static struct big *b_sub (struct big *a, struct big *b)   /* a - b, a >= b */
{
  struct big *r = b_new (a->n);
  long i;
  long borrow = 0;
  for (i = 0; i < a->n; i++) {
    long x = (long) a->d[i] - (i < b->n ? (long) b->d[i] : 0) - borrow;
    borrow = x < 0;
    if (x < 0) x += 4294967296LL;
    r->d[i] = (unsigned int) x;
  }
  r->n = a->n;
  b_trim (r);
  return r;
}
static struct big *b_pow (unsigned int base, long e)
{
  struct big *r = b_of (1);
  long i;
  for (i = 0; i < e; i++) b_muladd (r, base, 0);
  return r;
}
static struct big *b_pow2 (long e) { return b_shl (b_of (1), e); }
/* n / d and its remainder (rem), d > 0: the quotient's bits from the top, as
   many as it has (n and d of any size, the quotient small or not) */
static struct big *b_divmod (struct big *n, struct big *d, struct big **rem)
{
  long nb = b_bits (n), db = b_bits (d), k;
  struct big *q = b_new (2), *r = b_copy (n);
  if (b_zero (n) || b_cmp (n, d) < 0) { *rem = r; return q; }
  for (k = nb - db; k >= 0; k--) {
    struct big *t = b_shl (d, k);
    if (b_cmp (r, t) >= 0) {
      r = b_sub (r, t);
      b_room (q, k / 32 + 1);
      while (q->n <= k / 32) q->d[q->n++] = 0;
      q->d[k / 32] |= 1u << (k % 32);
    }
  }
  b_trim (q);
  *rem = r;
  return q;
}
static unsigned int b_divsmall (struct big *a, unsigned int m)   /* a /= m in place, the remainder */
{
  long i;
  unsigned long r = 0;
  for (i = a->n - 1; i >= 0; i--) { unsigned long x = (r << 32) | a->d[i]; a->d[i] = (unsigned int) (x / m); r = x % m; }
  b_trim (a);
  return (unsigned int) r;
}
static struct str *b_dec (struct big *a)   /* the decimal digits */
{
  struct big *x = b_copy (a);
  struct str *s = s_of (""), *o;
  long i;
  if (b_zero (x)) return s_of ("0");
  while (!b_zero (x)) { unsigned int r = b_divsmall (x, 1000000000); for (i = 0; i < 9; i++) { s_chr (s, '0' + r % 10); r /= 10; } }
  while (s->n > 1 && s->p[s->n - 1] == '0') s->n--;
  o = s_of ("");
  for (i = s->n - 1; i >= 0; i--) s_chr (o, s->p[i]);
  return o;
}
static struct str *b_hex (struct big *a)   /* as_hex without 0x */
{
  struct str *s = s_of ("");
  long i;
  int started = 0;
  static char *dg = "0123456789abcdef";
  if (b_zero (a)) return s_of ("0");
  for (i = a->n - 1; i >= 0; i--) {
    long j;
    for (j = 28; j >= 0; j -= 4) {
      int x = (a->d[i] >> j) & 15;
      if (!x && !started) continue;
      started = 1; s_chr (s, dg[x]);
    }
  }
  return s;
}
static struct big *b_from_dec (struct str *s)
{
  struct big *b = b_new (4);
  long i;
  for (i = 0; i < s->n; i++) if (is_digit (s->p[i])) b_muladd (b, 10, s->p[i] - '0');
  return b;
}

/* ---- FFold.pm: floating constants as gcc folds them */
struct fty_ { long p, emin, emax; char *sfx, *inf; };
static struct fty_ fty_float = { 24, -149, 127, "f", "128f" }, fty_double = { 53, -1074, 1023, "", "1024" },
  fty_ld = { 113, -16494, 16383, "L", "16384L" }, fty_f128 = { 113, -16494, 16383, "Q", "16384Q" };
static void ffold_x87 (void) { fty_ld.p = 64; fty_ld.emin = -16445; }
static struct fty_ *fty (struct str *t)
{
  if (!t) return 0;
  if (s_is (t, "float")) return &fty_float;
  if (s_is (t, "double")) return &fty_double;
  if (s_is (t, "long double")) return &fty_ld;
  if (s_is (t, "float128")) return &fty_f128;
  return 0;
}
/* the node's floating type, or '' (clang's __float128 is float128) */
static struct str *ftype (struct jv *n)
{
  struct jv *t = n ? jget (n, "type") : 0;
  struct str *q;
  if (!t) return s_of ("");
  q = jstr (t, "desugaredQualType");
  if (!q) q = jstr (t, "qualType");
  if (!q) q = s_of ("");
  q = ssub (q, "\\b(const|volatile)\\s+", "g", "");
  if (s_is (q, "float") || s_is (q, "double") || s_is (q, "long double")) return q;
  if (s_is (q, "__float128")) return s_of ("float128");
  return s_of ("");
}
static int ldinside (struct jv *n)
{
  struct str *t = ftype (n);
  struct vec *k;
  long i;
  if (s_is (t, "long double") || s_is (t, "float128")) return 1;
  k = jkids (n);
  for (i = 0; i < k->n; i++) if (ldinside (k->v[i])) return 1;
  return 0;
}
/* clang's decimal: n / d, or 0 */
static int dec (struct str *s, struct big **n, struct big **d)
{
  struct str *i, *f, *m;
  long e = 0, e10, k;
  if (!mf (s, "^([0-9]*)(?:\\.([0-9]*))?(?:[eE]([-+]?[0-9]+))?$", "")) return 0;
  i = g0 (1); f = g0 (2);
  if (gdef (3)) { struct str *x = g (3); long j = 0, neg = 0; if (x->p[0] == '-' || x->p[0] == '+') { neg = x->p[0] == '-'; j = 1; } for (; j < x->n; j++) e = e * 10 + (x->p[j] - '0'); if (neg) e = -e; }
  m = s_dup (i); s_app (m, f);
  *n = b_from_dec (m);
  e10 = e - f->n;
  if (e10 >= 0) { struct big *t = b_pow (10, e10); struct big *r = b_of (0); long q; (void) q; r = b_new (2);
    /* m * 10^e10 */
    { struct big *x = b_copy (*n); for (k = 0; k < e10; k++) b_muladd (x, 10, 0); *n = x; }
    (void) t; *d = b_of (1); }
  else *d = b_pow (10, -e10);
  return 1;
}
/* n / d (n > 0) to the nearest q * 2^e2, q of p bits (ties to even), e2 no lower than emin */
static struct big *rq_n, *rq_d;
static struct big *rq_div (long e2)
{
  struct big *nn, *dd, *q, *r, *rr;
  int c;
  if (e2 >= 0) { nn = rq_n; dd = b_shl (rq_d, e2); } else { nn = b_shl (rq_n, -e2); dd = rq_d; }
  q = b_divmod (nn, dd, &r);
  rr = b_shl (r, 1);
  c = b_cmp (rr, dd);
  if (c > 0 || (c == 0 && b_odd (q))) q = b_add (q, b_of (1));
  return q;
}
static struct big *ratq (struct big *n, struct big *d, long p, long emin, long *e2out)
{
  long e2 = b_bits (n) - b_bits (d) - p;
  struct big *top = b_pow2 (p - 1), *over = b_pow2 (p), *q;
  rq_n = n; rq_d = d;
  while (b_cmp (rq_div (e2), over) >= 0) e2++;
  while (b_cmp (rq_div (e2), top) < 0 && e2 > emin) e2--;
  if (e2 < emin) e2 = emin;
  q = rq_div (e2);
  if (b_cmp (q, over) >= 0) { e2++; q = rq_div (e2); }
  *e2out = e2;
  return q;
}
/* q * 2^e2 as binary128's exact hex float with L; 0 where its top bit is past emax */
static struct str *qlit (struct big *q, long e2, long emax)
{
  long lead, ex;
  struct big *gg;
  struct str *hex, *o;
  if (b_zero (q)) return s_of ("0x0p+0L");
  lead = b_bits (q) - 1;
  ex = e2 + lead;
  if (ex > emax) return 0;
  if (ex >= -16382) {
    gg = b_sub (q, b_pow2 (lead));
    gg = b_shl (gg, 112 - lead);
    hex = b_hex (gg);
    while (hex->n < 28) { struct str *x = s_of ("0"); s_app (x, hex); hex = x; }
    while (hex->n && hex->p[hex->n - 1] == '0') hex->n--;
    hex->p[hex->n] = 0;
    o = s_of ("0x1");
    if (hex->n && !s_is (hex, "0")) { s_chr (o, '.'); s_app (o, hex); }
    s_chr (o, 'p'); if (ex >= 0) s_chr (o, '+'); s_app (o, s_num (ex)); s_chr (o, 'L');
    return o;
  }
  gg = b_shl (q, e2 + 16494);
  hex = b_hex (gg);
  while (hex->n < 28) { struct str *x = s_of ("0"); s_app (x, hex); hex = x; }
  while (hex->n && hex->p[hex->n - 1] == '0') hex->n--;
  hex->p[hex->n] = 0;
  o = s_of ("0x0."); s_app (o, hex); s_cat (o, "p-16382L");
  return o;
}
static struct str *ldround (struct str *s, long p, long emin, long emax)
{
  struct big *n, *d, *q;
  long e2;
  if (!dec (s, &n, &d)) { struct str *m = s_of ("c2ff: a long double literal that is no decimal: "); s_app (m, s); s_cat (m, "\n"); die_s (m); }
  if (b_zero (n)) return s_of ("0x0p+0L");
  q = ratq (n, d, p, emin, &e2);
  return qlit (q, e2, emax);
}

/* a value: num (q * 2^e), inf or nan, and its sign */
struct fv { int k; int neg; struct big *q; long e; };   /* k: 'n' num, 'i' inf, 'a' nan */
static struct fv *fv_new (int k, int neg, struct big *q, long e) { struct fv *v = alloc (sizeof (struct fv)); v->k = k; v->neg = neg; v->q = q; v->e = e; return v; }
static struct fv *fzero (int neg) { return fv_new ('n', neg, b_of (0), 0); }
static struct fv *flip (struct fv *v) { return fv_new (v->k, v->neg ? 0 : 1, v->q, v->e); }
static struct fv *fround (struct fv *v, struct str *t)
{
  struct fty_ *ft = fty (t);
  struct big *n, *d, *q;
  long e;
  if (!v || !ft) return 0;
  if (!(v->k == 'n' && !b_zero (v->q))) return v;
  if (v->e >= 0) { n = b_shl (v->q, v->e); d = b_of (1); } else { n = b_copy (v->q); d = b_pow2 (-v->e); }
  q = ratq (n, d, ft->p, ft->emin, &e);
  if (!b_zero (q) && e + b_bits (q) - 1 > ft->emax) return fv_new ('i', v->neg, 0, 0);
  return fv_new ('n', v->neg, q, e);
}
static struct jv *jstrip_cast (struct jv *f)   /* through ImplicitCastExpr and ParenExpr */
{
  while (f && (kind_is (f, "ImplicitCastExpr") || kind_is (f, "ParenExpr"))) f = jkid (f, 0);
  return f;
}
static struct fv *fold (struct jv *n)
{
  struct str *k = jkind (n);
  struct vec *c = jkids (n);
  if ((s_is (k, "ParenExpr") || s_is (k, "ConstantExpr")) && c->n == 1) return fold (c->v[0]);
  if (s_is (k, "FloatingLiteral")) {
    struct big *nn, *dd, *q;
    struct fty_ *t;
    long e;
    struct str *v = jstr (n, "value");
    if (!dec (v ? v : s_of (""), &nn, &dd)) return 0;
    if (b_zero (nn)) return fzero (0);
    t = fty (ftype (n));
    if (!t) return 0;
    q = ratq (nn, dd, t->p, t->emin, &e);
    if (!b_zero (q) && e + b_bits (q) - 1 > t->emax) return fv_new ('i', 0, 0, 0);
    return fv_new ('n', 0, q, e);
  }
  if (s_is (k, "IntegerLiteral")) {
    struct str *v = jstr (n, "value");
    int neg;
    if (!v) return 0;
    neg = v->n && v->p[0] == '-';
    return fv_new ('n', neg && !b_zero (b_from_dec (v)), b_from_dec (v), 0);
  }
  if (s_is (k, "CallExpr")) {
    /* gcc's __builtin_huge_val, inf, nan ("") */
    struct jv *f = c->n ? c->v[0] : 0, *rd;
    struct str *name;
    f = jstrip_cast (f);
    rd = f ? jget (f, "referencedDecl") : 0;
    name = rd ? jstr (rd, "name") : 0;
    if (!name) name = s_of ("");
    if (mf (name, "^__builtin_(?:huge_val|inf)[fl]?$", "") && c->n == 1) return fv_new ('i', 0, 0, 0);
    if (mf (name, "^__builtin_nan[fl]?$", "") && c->n == 2) {
      struct jv *s = jstrip_cast (c->v[1]);
      if (kind_is (s, "StringLiteral") && jis (s, "value", "\"\"")) return fv_new ('a', 0, 0, 0);
    }
    return 0;
  }
  if (s_is (k, "ImplicitCastExpr") || s_is (k, "CStyleCastExpr")) {
    struct str *ck = jstr (n, "castKind");
    struct fv *v;
    if (!ck) ck = s_of ("");
    if (!(mf (ck, "^(FloatingCast|IntegralToFloating|NoOp)$", "") && c->n == 1)) return 0;
    v = fold (c->v[0]);
    return s_is (ck, "NoOp") ? v : fround (v, ftype (n));
  }
  if (s_is (k, "UnaryOperator") && jstr (n, "opcode") && mf (jstr (n, "opcode"), "^[-+]$", "") && c->n == 1) {
    struct fv *v = fold (c->v[0]);
    if (!v) return 0;
    return jis (n, "opcode", "+") ? v : flip (v);
  }
  if (s_is (k, "BinaryOperator") && jstr (n, "opcode") && mf (jstr (n, "opcode"), "^[-+]$", "") && c->n == 2) {
    struct fv *a = fold (c->v[0]), *b = fold (c->v[1]);
    long e;
    struct big *x, *y, *z;
    int xn, yn, zn;
    if (!(a && b && fty (ftype (n)))) return 0;
    if (jis (n, "opcode", "-")) b = flip (b);
    if (a->k == 'a') return a;
    if (b->k == 'a') return b;
    if (a->k == 'i' || b->k == 'i') {
      if (a->k == 'i' && b->k == 'i' && a->neg != b->neg) return fv_new ('a', 0, 0, 0);
      return a->k == 'i' ? a : b;
    }
    e = a->e < b->e ? a->e : b->e;
    x = b_shl (a->q, a->e - e); xn = a->neg && !b_zero (x);
    y = b_shl (b->q, b->e - e); yn = b->neg && !b_zero (y);
    /* z = x + y, signed */
    if (xn == yn) { z = b_add (x, y); zn = xn; }
    else if (b_cmp (x, y) >= 0) { z = b_sub (x, y); zn = xn; }
    else { z = b_sub (y, x); zn = yn; }
    /* (an exact zero: -0 only of -0 and -0, as round to nearest has it) */
    if (b_zero (z)) return fzero (a->neg && b->neg ? 1 : 0);
    return fround (fv_new ('n', zn, z, e), ftype (n));
  }
  return 0;
}

/* ---- numbers as Perl prints them: sprintf '%.17g' of a double, exactly */
/* a double's value: its sign, and q * 2^e (q 0 for a zero); inf and nan */
struct dbl { int neg, inf, nan; struct big *q; long e; };
static struct dbl *dbl_of_bits (unsigned long bits)
{
  struct dbl *x = alloc (sizeof (struct dbl));
  long ex = (long) ((bits >> 52) & 0x7ff);
  unsigned long m = bits & 0xfffffffffffffULL;
  x->neg = (int) (bits >> 63);
  if (ex == 0x7ff) { if (m) x->nan = 1; else x->inf = 1; return x; }
  if (ex == 0) { x->q = b_of (m); x->e = -1074; }
  else { x->q = b_of (m | (1ULL << 52)); x->e = ex - 1075; }
  return x;
}
/* the digits of q * 2^e (q > 0) to p significant ones, rounded to nearest (ties even), and where the point goes: value = 0.d1d2... * 10^pointat */
static struct str *sig_digits (struct big *q, long e, long p, long *pointat)
{
  struct big *n;
  struct str *d, *o;
  long point, i;
  if (e >= 0) { n = b_shl (q, e); d = b_dec (n); point = d->n; }
  else { n = b_copy (q); for (i = 0; i < -e; i++) b_muladd (n, 5, 0); d = b_dec (n); point = d->n + e; }
  if (d->n > p) {
    int up, rest = 0;
    long j;
    char r = d->p[p];
    for (j = p + 1; j < d->n; j++) if (d->p[j] != '0') rest = 1;
    up = r > '5' || (r == '5' && (rest || ((d->p[p - 1] - '0') & 1)));
    o = s_sub (d, 0, p);
    if (up) {
      j = p - 1;
      while (j >= 0 && o->p[j] == '9') { o->p[j] = '0'; j--; }
      if (j >= 0) o->p[j]++;
      else { struct str *x = s_of ("1"); s_app (x, o); o = s_sub (x, 0, p); point++; }
    }
    d = o;
  }
  *pointat = point;
  return d;
}
/* sprintf '%.17g' of sign, q * 2^e */
static struct str *fmt_g17 (int neg, struct big *q, long e)
{
  struct str *o = s_of (neg ? "-" : ""), *d;
  long pointat, ex, i, P = 17;
  if (b_zero (q)) { s_chr (o, '0'); return o; }
  d = sig_digits (q, e, P, &pointat);
  ex = pointat - 1;
  while (d->n > 1 && d->p[d->n - 1] == '0') d->n--;
  if (ex < -4 || ex >= P) {
    s_chr (o, d->p[0]);
    if (d->n > 1) { s_chr (o, '.'); s_add (o, d->p + 1, d->n - 1); }
    s_chr (o, 'e'); s_chr (o, ex < 0 ? '-' : '+');
    if (ex < 0) ex = -ex;
    if (ex < 10) s_chr (o, '0');
    s_app (o, s_num (ex));
    return o;
  }
  if (ex < 0) {
    s_cat (o, "0.");
    for (i = 0; i < -ex - 1; i++) s_chr (o, '0');
    s_app (o, d);
    return o;
  }
  for (i = 0; i <= ex; i++) s_chr (o, i < d->n ? d->p[i] : '0');
  if (d->n > ex + 1) { s_chr (o, '.'); s_add (o, d->p + ex + 1, d->n - ex - 1); }
  return o;
}
static struct str *fmt_dbl (struct dbl *x)
{
  if (x->nan) return s_of ("NaN");
  if (x->inf) return s_of (x->neg ? "-Inf" : "Inf");
  return fmt_g17 (x->neg, x->q, x->e);
}
/* Perl's 0 + "decimal": the nearest double (strtod's), as q * 2^e; inf past its range */
static struct dbl *dbl_of_dec (struct str *s)
{
  struct dbl *x = alloc (sizeof (struct dbl));
  struct big *n, *d, *q;
  long e2, i = 0;
  struct str *t = s;
  if (t->n && (t->p[0] == '-' || t->p[0] == '+')) { x->neg = t->p[0] == '-'; t = s_sub (t, 1, t->n); }
  (void) i;
  if (mf (t, "^(?:inf|infinity)$", "i")) { x->inf = 1; return x; }
  if (mf (t, "^nan", "i")) { x->nan = 1; return x; }
  if (!dec (t, &n, &d) || b_zero (n)) { x->q = b_of (0); return x; }
  q = ratq (n, d, 53, -1074, &e2);
  if (e2 + b_bits (q) - 1 > 1023) { x->inf = 1; return x; }
  x->q = q; x->e = e2;
  return x;
}
/* the bits of a double: through memory */
union dbits { double d; unsigned long u; };
static unsigned long bits_of (double v) { union dbits x; x.d = v; return x.u; }
static double dbl_bits (unsigned long u) { union dbits x; x.u = u; return x.d; }
/* 2 ** e as a double (pow (2, e), exact where it is one: 0 below the subnormals, inf past the range) */
static double pow2 (long e)
{
  if (e > 1023) return dbl_bits (0x7ff0000000000000ULL);
  if (e >= -1022) return dbl_bits ((unsigned long) (e + 1023) << 52);
  if (e >= -1074) return dbl_bits (1ULL << (e + 1074));
  return 0.0;
}
/* roundtrip.pl's hexf: a hex float's value, summed as the Perl sums it (doubles) */
static int hexd (int c) { return hexv (c); }
static struct str *hexf_flt (struct str *v, int *ok)
{
  struct str *sg, *ipart, *fpart, *epart;
  double m, x;
  long e = 0, i, j;
  *ok = 0;
  if (!mf (v, "^(-?)0x([0-9a-f]*)(?:\\.([0-9a-f]*))?p([-+]?\\d+)", "i")) return v;
  sg = g0 (1); ipart = g0 (2); fpart = g0 (3); epart = g (4);
  *ok = 1;
  m = 0.0;
  for (i = 0; i < ipart->n; i++) m = m * 16.0 + hexd (ipart->p[i]);
  for (i = 0; i < fpart->n; i++) {
    double p16 = 1.0;
    for (j = 0; j <= i; j++) p16 = p16 * 16.0;
    m = m + hexd (fpart->p[i]) / p16;
  }
  { long k = 0, neg = 0; if (epart->p[0] == '-' || epart->p[0] == '+') { neg = epart->p[0] == '-'; k = 1; } for (; k < epart->n; k++) e = e * 10 + (epart->p[k] - '0'); if (neg) e = -e; }
  x = (sg->n ? -1.0 : 1.0) * m * pow2 (e);
  return fmt_dbl (dbl_of_bits (bits_of (x)));
}
/* roundtrip.pl's flt: a literal's value as a double, '%.17g' */
static struct str *flt (struct str *v)
{
  int ok;
  if (v->n >= 2 && v->p[0] == '0' && (v->p[1] == 'x' || v->p[1] == 'X')) { struct str *r = hexf_flt (v, &ok); if (ok) return r; return fmt_dbl (dbl_of_dec (s_of ("0"))); }

  return fmt_dbl (dbl_of_dec (v));
}

/* ---- types */
static struct hash *tdef, *typeof_, *declty, *constint, *ltype, *cls;
static long typeof_depth;
static void cls_init (void)
{
  static char *c[] = { "char", "char", "signed char", "i8", "unsigned char", "u8", "short", "i16", "unsigned short", "u16",
    "int", "i32", "unsigned int", "u32", "long", "i64", "long long", "i64", "unsigned long", "u64",
    "unsigned long long", "u64", "_Bool", "u8", "bool", "u8", "float", "float", "double", "double",
    "long double", "ldouble", "__float128", "ldouble", "void", "void", "__builtin_va_list", "va", "va_list", "va", "__va_list_tag", "va", 0 };
  long i;
  cls = h_new ();
  for (i = 0; c[i]; i += 2) h_setp (cls, s_of (c[i]), s_of (c[i + 1]));
  if (t_is ("arm")) h_setp (cls, s_of ("unsigned long"), s_of ("u32"));
}
/* the end of the balanced parentheses that begin at i (the index after its ')'), or -1 */
static long balanced_end (struct str *s, long i)
{
  long d = 0;
  for (; i < s->n; i++) { if (s->p[i] == '(') d++; else if (s->p[i] == ')') { d--; if (!d) return i + 1; } }
  return -1;
}
/* without its __attribute__ ((...)) */
static struct str *noattr (struct str *s)
{
  long at = 0;
  s = s_dup (s);
  for (;;) {
    long b = -1, i, j, d = 0;
    for (i = at; i + 13 <= s->n; i++) if (msame (s->p + i, (unsigned char *) "__attribute__", 13)) {
      j = i + 13;
      while (j < s->n && is_space (s->p[j])) j++;
      if (j < s->n && s->p[j] == '(') { b = i; break; }
    }
    if (b < 0) return s;
    j = b + 13;
    while (s->p[j] != '(') j++;
    for (i = j; i < s->n; i++) { if (s->p[i] == '(') d++; if (s->p[i] == ')') d--; if (!d) break; }
    {
      long e = i + 1 > s->n ? s->n : i + 1;
      struct str *x = s_sub (s, 0, b);
      s_add (x, s->p + e, s->n - e);
      s = x;
    }
    at = b;
  }
}
static struct str *tstr (struct str *s);
static struct str *typeof_expr (struct str *e);
static struct str *trim (struct str *e) { return ssub (e, "^\\s+|\\s+$", "g", ""); }
/* the outermost parentheses around all of e, (...): its inside, else 0 */
static struct str *paren_inside (struct str *e)
{
  if (e->n >= 2 && e->p[0] == '(' && balanced_end (e, 0) == e->n) return s_sub (e, 1, e->n - 1);
  return 0;
}
static struct str *typeof_expr (struct str *e)
{
  struct str *in, *x;
  e = ssub (e, "__attribute__\\s*\\(\\(address_space\\(257\\)\\)\\)", "g", "");
  e = trim (e);
  while ((in = paren_inside (e))) e = trim (in);
  if ((x = h_pv (ltype, e))) return x;
  if (h_has (ltype, e)) return 0;
  if (h_has (declty, e)) return h_pv (declty, e);
  if (e->n && e->p[0] == '*') {
    struct str *t = typeof_expr (s_sub (e, 1, e->n));
    if (!t) return 0;
    t = noattr (t);
    t = ssub (t, "\\s*\\b(?:const|volatile)\\s*$", "", "");
    if (mf (t, "^(.*?)\\s*\\*$", "")) return g (1);
    return 0;
  }
  if (mf (e, "^\\(([^()]*\\*)\\s*\\)\\s*\\S", "")) return trim (g (1));
  return 0;
}

/* (a newline after i: (.*)$ of a pattern without /s stops before it) */
static int memchr_nl (struct str *s, long i) { for (; i < s->n; i++) if (s->p[i] == '\n') return 1; return 0; }
static struct str *vla_norm (struct str *c);
/* a C type's class, as roundtrip.pl's tstr */
static struct str *tstr (struct str *s)
{
  struct str *x;
  s = noattr (s);
  s = ssub (s, "\\b(const|volatile|restrict|__restrict)\\b", "g", "");
  s = ssub (s, "\\s+", "g", " ");
  s = ssub (s, "^ | $", "g", "");
  s = ssub (s, " (\\*|\\[)", "g", "$1");
  if (constint->n) {
    /* s/\[([A-Za-z_]\w*)\]/'[' . ($constint{$1} // $1) . ']'/ge */
    struct str *o = s_of ("");
    long at = 0, last = 0;
    struct rx *r = rx_get ("\\[([A-Za-z_]\\w*)\\]", "");
    g_s = s->p;
    while (at <= s->n && rx_exec (r, s->p, s->n, at)) {
      struct str *nm = g (1), *v = h_pv (constint, nm);
      s_add (o, s->p + last, rc[0] - last);
      s_chr (o, '['); s_app (o, v ? v : nm); s_chr (o, ']');
      last = rc[1]; at = rc[1];
      g_s = s->p;
    }
    s_add (o, s->p + last, s->n - last);
    s = o;
  }
  s = ssub (s, "\\b(?:long int)\\b", "g", "long");
  s = ssub (s, "\\b(?:short int)\\b", "g", "short");
  s = ssub (s, "\\bunsigned\\b(?! (?:char|short|int|long))", "g", "unsigned int");
  /* (a 128-bit integer, under its names) */
  if (mf (s, "^(?:signed )?__int128$|^__int128_t$", "")) return s_of ("__int128");
  if (mf (s, "^unsigned (?:int )?__int128$|^__uint128_t$", "")) return s_of ("unsigned __int128");
  if (h_has (tdef, s)) return tstr (h_pv (tdef, s) ? h_pv (tdef, s) : s_of (""));
  if (h_has (typeof_, s)) return tstr (h_pv (typeof_, s) ? h_pv (typeof_, s) : s_of (""));
  /* (typeof (name): the type of what the unit declares by that name) */
  if (mf (s, "^(?:typeof|__typeof__) \\(\\s*(\\w+)\\s*\\)$", "")) {
    struct str *nm = g (1);
    if (h_has (declty, nm)) { struct str *t = h_pv (declty, nm); return tstr (t ? t : s_of ("")); }
  }
  /* (typeof of an expression, as c2ff's typeof_expr) */
  if (typeof_depth < 8 && mf (s, "^(?:typeof|__typeof__|__typeof)\\s*\\(", "")) {
    long open = rc[1] - 1, end = balanced_end (s, open);
    if (end > 0 && !memchr_nl (s, end)) {
      struct str *e = s_sub (s, open + 1, end - 1), *rest = s_sub (s, end, s->n), *t = typeof_expr (e);
      if (t) {
        struct str *tr = s_dup (t);
        s_app (tr, rest);
        if (!s_eq (tr, s)) { struct str *r; typeof_depth++; r = tstr (tr); typeof_depth--; return r; }
      }
    }
  }
  if (mf (s, "^(?:typeof|__typeof__) \\(", "") && mf (s, "\\)$", "")) return s_of ("?typeof");
  /* (an anonymous record's spelling, union __mbstate_t::(unnamed at f.h:3:5), is a record) */
  if (mf (s, "^(?:struct|union)\\b[^*\\[]*\\((?:unnamed|anonymous)\\b[^()]*\\)$", "")) return s_of ("rec");
  if (mf (s, "^enum\\b[^*\\[]*\\((?:unnamed|anonymous)\\b[^()]*\\)$", "")) return s_of ("enum");
  /* (a pointer to an array, an array of function pointers, as C spells them) */
  if (mf (s, "^(.*)\\(\\*\\)((?:\\[\\d*\\])+)$", "")) {
    struct str *e = g (1), *r = g (2);
    e = ssub (e, " $", "", "");
    s_app (e, r);
    return cat2 ("ptr(", tstr (e), ")");
  }
  if (mf (s, "\\(\\*\\[(\\d*)\\]\\)\\s*\\(", "")) return cat2 ("arr(fnptr,", g (1), ")");
  if (mf (s, "\\(\\*+\\)\\s*\\(", "") || mf (s, "\\(\\*\\)$", "")) return s_of ("fnptr");
  if (mf (s, "\\)$", "") && mf (s, "^[^(]+\\(", "") && !mf (s, "^(?:struct|union|enum) \\(", "")) return s_of ("fn");
  /* (T[n][m] is n of T[m]: the first count is the array's) */
  if (mf (s, "^([^\\[\\]()]*)\\[(\\d*)\\]((?:\\[\\d*\\])*)$", "")) {
    struct str *e = g (1), *c = g (2), *r = g (3), *o;
    s_app (e, r);
    o = cat2 ("arr(", tstr (e), ","); s_app (o, c); s_chr (o, ')');
    return o;
  }
  if (mf (s, "^(.*)\\[(\\d*)\\]$", "")) { struct str *e = g (1), *c = g (2), *o = cat2 ("arr(", tstr (e), ","); s_app (o, c); s_chr (o, ')'); return o; }
  if (mf (s, "^(.*?)\\[([^\\[\\]]*[A-Za-z_(][^\\[\\]]*)\\]$", "")) { struct str *e = g (1), *c = g (2), *o = cat2 ("vla(", tstr (e), ","); s_app (o, vla_norm (c)); s_chr (o, ')'); return o; }
  if (mf (s, "^(.*)\\*$", "")) { struct str *to = tstr (g (1)); return s_is (to, "fn") ? s_of ("fnptr") : cat2 ("ptr(", to, ")"); }
  if ((x = h_pv (cls, s))) return x;
  if (mf (s, "^(?:struct|union)\\b", "")) return s_of ("rec");
  if (mf (s, "^enum\\b", "")) return s_of ("enum");
  if (s_is (s, "unsigned long int")) return s_of (t_is ("arm") ? "u32" : "u64");
  return cat2 ("?", s, "");
}

/* ---- a variable-length array's count, as prefix (vla_norm) */
static int side_ff;          /* (our $side eq 'ff') */
static struct hash *orig;    /* names.txt's C name of each name */
static struct vec *vtok;
static long vat;
static int verr;
static long vprec (struct str *t)
{
  static char *p[] = { "?", "1", "==", "2", "!=", "2", "<", "3", ">", "3", "<=", "3", ">=", "3", "+", "4", "-", "4", "*", "5", "/", "5", "%", "5", 0 };
  long i;
  if (!t) return 0;
  for (i = 0; p[i]; i += 2) if (s_is (t, p[i])) return p[i + 1][0] - '0';
  return 0;
}
static struct str *vpeek (void) { return vat < vtok->n ? vtok->v[vat] : 0; }
static struct str *vshift (void) { return vat < vtok->n ? vtok->v[vat++] : 0; }
static struct str *vla_binary (long min);
static struct str *vla_primary (void)
{
  struct str *t = vshift (), *o;
  if (!t) { verr = 1; return s_of (""); }
  if (s_is (t, "(")) { struct str *r = vla_binary (0); struct str *c = vshift (); if (!c || !s_is (c, ")")) verr = 1; return r; }
  if (is_digit (t->p[0])) return t;
  if (!(t->p[0] == '_' || (t->p[0] >= 'a' && t->p[0] <= 'z') || (t->p[0] >= 'A' && t->p[0] <= 'Z'))) { verr = 1; return s_of (""); }
  if (side_ff) { struct str *x = h_pv (orig, t); if (x) t = x; }
  else t = ssub (t, "^__builtin_((?:mem|str|stp)\\w+)$", "", "$1");
  if (!(vpeek () && s_is (vpeek (), "("))) return t;
  vshift ();
  /* ("(call $t @a)": the arguments after a space, between spaces) */
  o = s_of ("(call "); s_app (o, t); s_chr (o, ' ');
  {
    int first = 1;
    while (vpeek () && !s_is (vpeek (), ")") && !verr) {
      struct str *a = vla_binary (0);
      if (!first) s_chr (o, ' ');
      s_app (o, a); first = 0;
      if (vpeek () && s_is (vpeek (), ",")) vshift ();
    }
  }
  { struct str *c = vshift (); if (!c || !s_is (c, ")")) verr = 1; }
  s_chr (o, ')');
  return o;
}
static struct str *vla_binary (long min)
{
  struct str *l = vla_primary ();
  while (!verr && vpeek () && vprec (vpeek ()) > min) {
    struct str *op = vshift ();
    if (s_is (op, "?")) {
      struct str *a = vla_binary (0), *c = vshift (), *b, *o;
      if (!c || !s_is (c, ":")) { verr = 1; return l; }
      b = vla_binary (0);
      o = s_of ("(? "); s_app (o, l); s_chr (o, ' '); s_app (o, a); s_chr (o, ' '); s_app (o, b); s_chr (o, ')');
      l = o;
    } else {
      struct str *r = vla_binary (vprec (op)), *o = s_of ("(");
      s_app (o, op); s_chr (o, ' '); s_app (o, l); s_chr (o, ' '); s_app (o, r); s_chr (o, ')');
      l = o;
    }
  }
  return l;
}
static struct str *vla_norm (struct str *c)
{
  struct str *text = ssub (c, "\\s+", "g", ""), *t = s_of (""), *r;
  long i = 0, at = 0;
  /* sizeof ("text") as its size: its bytes (an escape one) and the NUL */
  struct rx *rx = rx_get ("\\bsizeof\\s*\\(\\s*\"((?:[^\"\\\\]|\\\\.)*)\"\\s*\\)", "");
  long last = 0;
  g_s = c->p;
  while (at <= c->n && rx_exec (rx, c->p, c->n, at)) {
    struct str *b = g (1);
    long len = 0, j;
    s_add (t, c->p + last, rc[0] - last);
    for (j = 0; j < b->n; j++) { if (b->p[j] == '\\' && j + 1 < b->n) j++; len++; }
    s_app (t, s_num (len + 1));
    last = rc[1]; at = rc[1] > rc[0] ? rc[1] : rc[0] + 1;
    g_s = c->p;
  }
  s_add (t, c->p + last, c->n - last);
  /* the tokens: \G\s*(name|number|<=|>=|==|!=|one of -+*\/%<>?:(),) */
  vtok = v_new ();
  for (;;) {
    long j;
    while (i < t->n && is_space (t->p[i])) i++;
    if (i >= t->n) break;
    j = i;
    if (t->p[i] == '_' || (t->p[i] >= 'a' && t->p[i] <= 'z') || (t->p[i] >= 'A' && t->p[i] <= 'Z')) { while (j < t->n && is_word (t->p[j])) j++; }
    else if (is_digit (t->p[i])) {
      while (j < t->n && is_digit (t->p[j])) j++;
      /* (\d+\b: a number that runs into a word's letters is none) */
      if (j < t->n && is_word (t->p[j])) break;
    }
    else if (i + 1 < t->n && (t->p[i + 1] == '=') && (t->p[i] == '<' || t->p[i] == '>' || t->p[i] == '=' || t->p[i] == '!')) j = i + 2;
    else if (slen ("-+*/%<>?:(),") && t->p[i] && (t->p[i] == '-' || t->p[i] == '+' || t->p[i] == '*' || t->p[i] == '/' || t->p[i] == '%' || t->p[i] == '<' || t->p[i] == '>' || t->p[i] == '?' || t->p[i] == ':' || t->p[i] == '(' || t->p[i] == ')' || t->p[i] == ',')) j = i + 1;
    else break;
    v_push (vtok, s_sub (t, i, j));
    i = j;
  }
  while (i < t->n && is_space (t->p[i])) i++;
  if (i < t->n) return text;
  vat = 0; verr = 0;
  r = vla_binary (0);
  return !verr && vat >= vtok->n ? r : text;
}

/* a value of FFold's as E has the literal of its type */
static struct str *fconst (struct fv *v, struct str *t)
{
  struct str *x;
  if (v->k != 'n') { x = s_of ("(fspecial "); s_cat (x, v->k == 'i' ? "inf" : "nan"); s_chr (x, ' '); s_app (x, tstr (t)); s_chr (x, ')'); }
  else if (s_is (t, "long double") || s_is (t, "float128")) { struct str *l = qlit (v->q, v->e, 16383); x = cat2 ("(fltl ", l ? l : s_of (""), ")"); }
  else x = cat2 ("(flt ", fmt_g17 (0, v->q, v->e), ")");
  return v->neg ? cat2 ("(u- ", x, ")") : x;
}

/* ---- the unit's tables from its cache */
static struct hash *jhash (struct jv *o)   /* an object of strings as a hash (a value 0 where it is no string) */
{
  struct hash *h = h_new ();
  long i;
  if (!o || o->t != 'o') return h;
  for (i = 0; i < o->k->n; i++) { struct jv *v = o->v->v[i]; h_setp (h, o->k->v[i], v && v != jnull ? v->s : 0); }
  return h;
}
static struct str *slurp_j (char *f)
{
  struct str *t = read_all (f);
  if (!t) { struct str *m = s_of ("roundtrip: "); s_cat (m, f); s_cat (m, ": "); s_cat (m, strerror_of (2)); s_cat (m, "\n"); die_s (m); }
  return t;
}
/* the const integer globals of a number (roundtrip.pl's %constint) */
static void constint_of (struct vec *keep)
{
  long i;
  constint = h_new ();
  for (i = 0; i < keep->n; i++) {
    struct jv *d = keep->v[i], *e = 0, *ty;
    struct str *q, *init;
    struct vec *k;
    long j;
    if (!kind_is (d, "VarDecl")) continue;
    ty = jget (d, "type");
    q = ty ? jstr (ty, "qualType") : 0;
    init = jstr (d, "init");
    if (!(q && mf (q, "^const (?:(?:unsigned |signed )?(?:char|short|int|long|long long)(?: int)?|unsigned)$", "") && init && s_is (init, "c"))) continue;
    k = jkids (d);
    for (j = 0; j < k->n; j++) if (!mf (jkind (k->v[j]), "Attr$", "")) { e = k->v[j]; break; }
    while (e && mf (jkind (e), "^(ImplicitCastExpr|ParenExpr|ConstantExpr)$", "")) e = jkid (e, 0);
    if (e && kind_is (e, "IntegerLiteral")) h_setp (constint, jstr (d, "name") ? jstr (d, "name") : s_of (""), jstr (e, "value"));
  }
}

/* --parts unit.rtn */
static void parts (char *f)
{
  struct jv *c = j_parse (slurp_j (f)), *t = jget (c, "tables"), *keep = jget (c, "keep");
  struct hash *ty = h_new ();
  struct vec *q = v_new (), *lines = v_new (), *ks;
  long i, at = 0;
  tdef = jhash (jget (t, "tdef")); typeof_ = jhash (jget (t, "typeof")); declty = jhash (jget (t, "declty"));
  ltype = h_new (); orig = h_new ();
  constint_of (keep ? keep->v : empty_vec);
  if (keep) for (i = 0; i < keep->v->n; i++) v_push (q, keep->v->v[i]);
  while (at < q->n) {
    struct jv *n = q->v[at++], *y = jget (n, "type");
    struct str *k = jkind (n);
    struct vec *kk;
    if (y) { struct str *a = jstr (y, "qualType"), *b = jstr (y, "desugaredQualType"); if (a) h_set (ty, a, 1); if (b) h_set (ty, b, 1); }
    if (s_is (k, "FloatingLiteral")) {
      struct str *v = jstr (n, "value"), *l = s_of ("flt ");
      if (!v) v = s_of ("");
      s_app (l, v); s_chr (l, '\t'); s_app (l, flt (v));
      v_push (lines, l);
      if (mf (v, "^[0-9.eE+-]+$", "")) {
        struct str *a = ldround (v, 64, -16445, 16383), *b = ldround (v, 113, -16494, 16383);
        l = s_of ("ldround "); s_app (l, v); s_chr (l, '\t'); s_app (l, a ? a : s_of ("undef")); s_chr (l, ' '); s_app (l, b ? b : s_of ("undef"));
        v_push (lines, l);
      }
    }
    if (!s_is (k, "FunctionDecl") && fty (ftype (n))) {
      struct fv *v = fold (n);
      struct str *l = s_of ("fold "), *id = jstr (n, "id");
      s_app (l, id ? id : s_of ("")); s_chr (l, '\t');
      s_app (l, v ? fconst (v, ftype (n)) : s_of ("undef"));
      v_push (lines, l);
    }
    kk = jkids (n);
    for (i = 0; i < kk->n; i++) v_push (q, kk->v[i]);
  }
  ks = h_sorted (ty);
  for (i = 0; i < ks->n; i++) { o_str ("tstr "); o_s (ks->v[i]); o_str ("\t"); o_s (tstr (ks->v[i])); o_str ("\n"); }
  for (i = 0; i < lines->n; i++) { o_s (lines->v[i]); o_str ("\n"); }
  o_flush ();
}

int roundtrip_main (int argc, char **argv)
{
  long a = 1;
  target = s_of ("");
  empty_vec = v_new ();
  jnull = jv_new ('z');
  if (a + 1 < argc && s_is (s_of (argv[a]), "--target")) { target = s_of (argv[a + 1]); a += 2; }
  if (t_is ("x86_64")) ffold_x87 ();
  cls_init ();
  if (a + 1 < argc && s_is (s_of (argv[a]), "--parts")) { parts (argv[a + 1]); return 0; }
  e_str ("usage: roundtrip [--target t] --parts unit.rtn\n");
  cp_exit (255);
  return 255;
}
