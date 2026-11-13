/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* x86.c: gen/s2ffx86.pm in ff, the x86_64 arm of s2ff (a dump of an
   elf64-x86-64 object): of the forms whose GNU line is the source's
   instruction, the one whose bytes are GNU's, the bytes worked out from the
   form's definition (ttpc's x86_64 section, --shared, and x86_64gnu.ff,
   --gnu) as ttpc emits them; the forms' GNU lines and operand kinds from
   isa/x86_64.dec.ff (--tables). */

/* ---- values: Perl's numbers as these use them: an IV, or a UV past it (big); undef */
struct xval { long v; int def, big; };
static int xv_lt (struct xval *a, long b) { if (a->big) return 0; return a->v < b; }   /* a < b (b an IV) */
static int xv_ge (struct xval *a, long b) { if (a->big) return 1; return a->v >= b; }
static void xv_set (struct xval *x, long v) { x->v = v; x->def = 1; x->big = 0; }
static void xv_uv (struct xval *x, unsigned long u) { x->v = (long) u; x->def = 1; x->big = (u >> 63) ? 1 : 0; }
static void xv_undef (struct xval *x) { x->v = 0; x->def = 0; x->big = 0; }
/* Perl's shifts: without use integer of the UV, a count past 63 0 */
static unsigned long ushl (unsigned long x, long n) { if (n >= 64 || n <= -64) return 0; if (n < 0) return x >> -n; return x << n; }
static unsigned long ushr (unsigned long x, long n) { if (n >= 64 || n <= -64) return 0; if (n < 0) return x << -n; return x >> n; }

/* ---- the registers */
static struct hash *xreg_n, *xreg_c;   /* name -> number, class */
static void xreg (char *name, long n, char *cls) { h_set (xreg_n, s_of (name), n); h_setp (xreg_c, s_of (name), cls); }
static void xregs_init (void)
{
  char *q[16], *l[16], *w[16], *b[16];
  char *qs = "rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15";
  char *ls = "eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d";
  char *ws = "ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w";
  char *bs = "al cl dl bl spl bpl sil dil r8b r9b r10b r11b r12b r13b r14b r15b";
  char **tabs[4]; char *srcs[4]; long t, k;
  xreg_n = h_new (); xreg_c = h_new ();
  tabs[0] = q; tabs[1] = l; tabs[2] = w; tabs[3] = b; srcs[0] = qs; srcs[1] = ls; srcs[2] = ws; srcs[3] = bs;
  for (t = 0; t < 4; t++) {
    long i = 0, kk = 0;
    char *s = srcs[t];
    while (kk < 16) { long a = i; char *x; while (s[i] && s[i] != ' ') i++; x = alloc (i - a + 1); mcopy ((unsigned char *) x, (unsigned char *) s + a, i - a); tabs[t][kk++] = x; if (s[i]) i++; }
  }
  for (k = 0; k < 16; k++) { xreg (q[k], k, "q"); xreg (l[k], k, "l"); xreg (w[k], k, "w"); xreg (b[k], k, "b"); }
  xreg ("ah", 4, "b"); xreg ("ch", 5, "b"); xreg ("dh", 6, "b"); xreg ("bh", 7, "b");
  for (k = 0; k < 32; k++) {
    struct str *x = s_of ("xmm"), *y = s_of ("ymm"), *z = s_of ("zmm");
    s_app (x, s_num (k)); s_app (y, s_num (k)); s_app (z, s_num (k));
    h_set (xreg_n, x, k); h_setp (xreg_c, x, "x"); h_set (xreg_n, y, k); h_setp (xreg_c, y, "y"); h_set (xreg_n, z, k); h_setp (xreg_c, z, "z");
  }
  for (k = 0; k < 8; k++) { struct str *x = s_of ("k"); s_app (x, s_num (k)); h_set (xreg_n, x, k); h_setp (xreg_c, x, "k"); }
  { long cr[5]; cr[0] = 0; cr[1] = 2; cr[2] = 3; cr[3] = 4; cr[4] = 8; for (k = 0; k < 5; k++) { struct str *x = s_of ("cr"); s_app (x, s_num (cr[k])); h_set (xreg_n, x, cr[k]); h_setp (xreg_c, x, "c"); } }
  { long dr[6]; dr[0] = 0; dr[1] = 1; dr[2] = 2; dr[3] = 3; dr[4] = 6; dr[5] = 7; for (k = 0; k < 6; k++) { struct str *x = s_of ("dr"); s_app (x, s_num (dr[k])); h_set (xreg_n, x, dr[k]); h_setp (xreg_c, x, "d"); } }
}
static int isreg (struct str *s) { return h_has (xreg_n, s); }
static char *regclass (struct str *s) { return h_pv (xreg_c, s); }

/* the place of the byte c in s from i, or -1 */
static long s_find_c (struct str *s, long i, int c) { while (i < s->n) { if (s->p[i] == c) return i; i++; } return -1; }

/* ---- the forms */
struct xform { struct str *name; struct vec *kp, *kk; struct vec *opat; struct vec *onames; struct rx **orx; long order; };
static struct hash *xdef;     /* name -> def node */
static struct hash *bymn;     /* lc mnemonic -> vec of forms */
static struct str *gnu_f;
static struct vec *x_split_ops (struct str *s)
{
  struct vec *ops = v_new ();
  struct str *cur = s_of ("");
  long depth = 0, i;
  for (i = 0; i < s->n; i++) {
    int c = s->p[i];
    if (c == '(' || c == '{') depth++;
    if (c == ')' || c == '}') depth--;
    if (c == ',' && !depth) { v_push (ops, cur); cur = s_of (""); continue; }
    s_chr (cur, c);
  }
  if (m (cur, "\\S")) v_push (ops, cur);
  for (i = 0; i < ops->n; i++) ops->v[i] = s_trim (ops->v[i]);
  return ops;
}
static struct str *nows (struct str *s) { struct str *o = s_of (""); long i; for (i = 0; i < s->n; i++) if (!is_space (s->p[i])) s_chr (o, s->p[i]); return o; }
static void xdef_add (struct nd *x)
{
  long i;
  for (i = 0; i < ndn (x); i++) {
    struct nd *y = ndk (x, i);
    if (m (y->c, "^[0-9]+:$")) xdef_add (y);
    else if (m (y->c, "^(\\S+):$")) { struct str *n = g (1); if (!h_has (xdef, n)) h_setp (xdef, n, y); }
  }
}
static void x86_load (void)
{
  struct nd *sec = section_of ("x86_64"), *top, *gr;
  struct vec *itemv = v_new ();
  long i, j;
  xdef = h_new (); bymn = h_new ();
  for (i = 0; i < ndn (sec); i++) xdef_add (ndk (sec, i));
  /* x86_64gnu.ff: its x86_64 gnu: group's defs */
  {
    struct str *t;
    struct nd *root;
    if (!gnu_f) die_c ("s2ff: no --gnu FILE (x86_64gnu.ff)\n");
    t = read_all ((char *) gnu_f->p);
    if (!t) { struct str *x = s_of ("s2ff: cannot open "); s_app (x, gnu_f); s_cat (x, "\n"); die_s (x); }
    ffp = t->p; ffn = t->n; ffi = 0;
    root = ff_node ();
    if (!root) die_c ("s2ff: x86_64gnu.ff is not an ff tree\n");
    gr = child_named (root, "x86_64 gnu:");
    if (gr) xdef_add (gr);
  }
  top = tables_of ("x86_64 forms:");
  items_of (top, itemv);
  for (i = 0; i < itemv->n; i++) {
    struct nd *e = itemv->v[i], *pn = child_named (e, "params");
    struct xform *f = alloc (sizeof (struct xform));
    struct str *gl = ssub (ndk (e, 0)->c, "^\\s*(\\{[a-z0-9]+\\}\\s*)+", "", ""), *mn, *ops, *key;
    struct vec *ol, *lst;
    f->name = e->c; f->order = i;
    f->kp = v_new (); f->kk = v_new ();
    for (j = 0; j < ndn (pn); j++) {
      struct str *pk = ndk (pn, j)->c;
      long c = 0;
      while (c < pk->n && pk->p[c] != ':') c++;
      v_push (f->kp, s_sub (pk, 0, c));
      v_push (f->kk, c < pk->n ? s_sub (pk, c + 1, pk->n) : 0);
    }
    if (!m (gl, "^(\\S+)\\s*(.*)$")) { struct str *x = s_of ("s2ff: "); s_app (x, f->name); s_cat (x, ": "); s_app (x, ndk (e, 0)->c); s_cat (x, "\n"); die_s (x); }
    mn = g (1); ops = g (2);
    ol = x_split_ops (ops);
    f->opat = v_new (); f->onames = v_new ();
    for (j = 0; j < ol->n; j++) {
      struct str *o = nows (ol->v[j]), *re = s_of ("^");
      struct vec *names = v_new ();
      long a = 0;
      /* split /(<[^>]+>)/: the text between, quoted, a <name> a group */
      while (a < o->n) {
        long b = a;
        while (b < o->n && !(o->p[b] == '<' && b + 1 < o->n && o->p[b + 1] != '>' && s_find_c (o, b + 1, '>') > b + 1)) b++;
        if (b > a) s_app (re, rx_quote (s_sub (o, a, b)));
        if (b >= o->n) break;
        {
          long e2 = s_find_c (o, b + 1, '>');
          v_push (names, s_sub (o, b + 1, e2));
          s_cat (re, e2 + 1 < o->n && o->p[e2 + 1] == '(' ? "(.*)" : "(.*?)");
          a = e2 + 1;
        }
      }
      s_cat (re, "$");
      v_push (f->opat, re); v_push (f->onames, names);
    }
    f->orx = alloc ((ol->n + 1) * sizeof (struct rx *));
    key = s_lc (mn);
    lst = h_pv (bymn, key);
    if (!lst) { lst = v_new (); h_setp (bymn, key, lst); }
    v_push (lst, f);
  }
}

/* ---- the bytes of a form, from its definition */
struct pbody { struct vec *params, *body; int kind; };   /* kind 1 bits, 2 ops, 3 emit */
static struct hash *pbs;
static int is_field (struct nd *c) { return (m (c->c, ":$") && ndn (c) == 1) || m (c->c, "\\[[\\d:|]+\\]$"); }
static struct pbody *params_body (struct str *name, struct nd *d)
{
  struct pbody *p = h_pv (pbs, name);
  long n = 0, i;
  if (p) return p;
  p = alloc (sizeof (struct pbody));
  p->params = v_new (); p->body = v_new ();
  while (n < ndn (d) && !ndn (ndk (d, n))) n++;
  for (i = 0; i < n; i++) v_push (p->params, ndk (d, i)->c);
  for (i = n; i < ndn (d); i++) v_push (p->body, ndk (d, i));
  h_setp (pbs, name, p);
  return p;
}
static int xsoft;            /* failing inside an eval { }: the message kept, not died */
static struct str *xerr;
static void xfail (struct str *msg)
{
  if (xsoft) { if (!xerr) xerr = msg; return; }
  fail_s (msg);
}
static struct hash *xops;
static int kind_of (struct str *name)
{
  struct nd *d = h_pv (xdef, name);
  struct pbody *p;
  long i;
  int bits = 0, ops = 0;
  if (!d) { struct str *x = s_of ("ttpc's x86_64 section has no "); s_app (x, name); xfail (x); return 0; }
  p = params_body (name, d);
  if (p->kind) return p->kind;
  for (i = 0; i < p->body->n; i++) { struct nd *c = p->body->v[i]; if (is_field (c)) bits = 1; if (h_has (xops, c->c)) ops = 1; }
  p->kind = bits ? 1 : ops ? 2 : 3;
  return p->kind;
}
static int numlit (struct str *s, struct xval *out)
{
  if (mf (s, "^0x[0-9a-f]+$", "i")) { unsigned long u = 0; long i; for (i = 2; i < s->n; i++) u = u * 16 + (unsigned long) hexv (s->p[i]); xv_uv (out, u); return 1; }
  if (mf (s, "^-0x([0-9a-f]+)$", "i")) { unsigned long u = 0; long i; for (i = 3; i < s->n; i++) u = u * 16 + (unsigned long) hexv (s->p[i]); xv_set (out, -(long) u); return 1; }
  if (m (s, "^-?\\d+$")) { long v = 0, i = s->p[0] == '-'; for (; i < s->n; i++) v = v * 10 + s->p[i] - '0'; xv_set (out, s->p[0] == '-' ? -v : v); return 1; }
  return 0;
}
/* an environment: names and their values */
struct xenv { struct str **nm; struct xval *va; long n, room; };
static struct xenv *env_new (long room) { struct xenv *e = alloc (sizeof (struct xenv)); e->room = room > 4 ? room : 4; e->nm = alloc (e->room * sizeof (struct str *)); e->va = alloc (e->room * sizeof (struct xval)); return e; }
static struct xval *env_get (struct xenv *e, struct str *k) { long i; for (i = e->n - 1; i >= 0; i--) if (s_eq (e->nm[i], k)) return &e->va[i]; return 0; }
static void env_set (struct xenv *e, struct str *k, struct xval *v)
{
  struct xval *x = env_get (e, k);
  if (x) { *x = *v; return; }
  if (e->n == e->room) {
    long r = e->room * 2, i;
    struct str **nm = alloc (r * sizeof (struct str *));
    struct xval *va = alloc (r * sizeof (struct xval));
    for (i = 0; i < e->n; i++) { nm[i] = e->nm[i]; va[i] = e->va[i]; }
    e->nm = nm; e->va = va; e->room = r;
  }
  e->nm[e->n] = k; e->va[e->n] = *v; e->n++;
}
static void leafval (struct str *s, struct xenv *env, struct xval *out)
{
  struct xval *x = env ? env_get (env, s) : 0;
  if (x) { *out = *x; return; }
  if (numlit (s, out)) return;
  if (isreg (s)) { xv_set (out, h_iv (xreg_n, s)); return; }
  xv_undef (out);
  if (s_is (s, "pc")) return;
  { struct str *m_ = s_of ("a value of no meaning here: "); s_app (m_, s); xfail (m_); }
}
static void callval (struct str *name, struct xval *args, long nargs, struct xval *out);
static void argval (struct nd *a, struct xenv *env, struct xval *out)
{
  struct xval *args;
  long i;
  if (!ndn (a)) { leafval (a->c, env, out); return; }
  args = alloc (ndn (a) * sizeof (struct xval));
  for (i = 0; i < ndn (a); i++) argval (ndk (a, i), env, &args[i]);
  callval (a->c, args, ndn (a), out);
}
static void cv_val (struct str *name, struct xenv *r, struct str *s, struct xval *out)
{
  struct xval *x = env_get (r, s);
  if (x) { *out = *x; return; }
  if (s_is (s, "zero")) { xv_set (out, 0); return; }
  if (numlit (s, out)) return;
  xv_undef (out);
  if (s_is (s, "pc")) return;
  { struct str *m_ = s_dup (name); s_cat (m_, ": a value of no meaning here: "); s_app (m_, s); xfail (m_); }
}
static long ishl (long x, long n) { if (n >= 64 || n <= -64) return 0; if (n < 0) return x >> -n; return (long) ((unsigned long) x << n); }
static long ishr (long x, long n) { if (n >= 64) return x < 0 ? -1 : 0; if (n <= -64) return 0; if (n < 0) return (long) ((unsigned long) x << -n); return x >> n; }
static void callval (struct str *name, struct xval *args, long nargs, struct xval *out)
{
  struct nd *d = h_pv (xdef, name);
  struct pbody *p;
  struct xenv *r;
  long i, k;
  xv_undef (out);
  if (!d) { struct str *x = s_of ("ttpc's x86_64 section has no "); s_app (x, name); xfail (x); return; }
  p = params_body (name, d);
  r = env_new (p->params->n + 4);
  for (i = 0; i < p->params->n; i++) { struct xval u; if (i < nargs) u = args[i]; else xv_undef (&u); env_set (r, p->params->v[i], &u); }
  for (i = 0; i < p->body->n; i++) {
    struct nd *op = p->body->v[i];
    struct str *o = op->c, *a[4];
    struct xval vx, vy, res;
    for (k = 0; k < 4; k++) a[k] = k < ndn (op) ? ndk (op, k)->c : s_of ("");
    if (s_is (o, "bits")) {
      struct xval x, shlc, sr, sc;
      cv_val (name, r, a[0], &x); cv_val (name, r, a[1], &shlc); cv_val (name, r, a[2], &sr); cv_val (name, r, a[3], &sc);
      if (xerr) return;
      if (x.def) xv_uv (&res, ushl (ushr (ushl ((unsigned long) x.v, shlc.v), sr.v), sc.v)); else xv_undef (&res);
      env_set (r, s_of ("a0"), &res);
      continue;
    }
    if (!h_has (xops, o)) { struct str *x = s_dup (name); s_cat (x, ": an op of no meaning here: "); s_app (x, o); xfail (x); return; }
    cv_val (name, r, a[0], &vx); cv_val (name, r, a[1], &vy);
    if (xerr) return;
    if (!vx.def || !vy.def) { xv_undef (&res); env_set (r, a[2], &res); continue; }
    if (s_is (o, "srli") || s_is (o, "srl")) xv_uv (&res, ushr ((unsigned long) vy.v, vx.v));
    else if (s_is (o, "sub")) xv_set (&res, vy.v - vx.v);
    else if (s_is (o, "add")) xv_set (&res, vx.v + vy.v);
    else if (s_is (o, "addi")) xv_set (&res, vy.v + vx.v);
    else if (s_is (o, "slli") || s_is (o, "sll")) xv_set (&res, ishl (vy.v, vx.v));
    else if (s_is (o, "srai") || s_is (o, "sra")) xv_set (&res, ishr (vy.v, vx.v));
    else if (s_is (o, "andi") || s_is (o, "and")) xv_set (&res, vx.v & vy.v);
    else if (s_is (o, "ori") || s_is (o, "or")) xv_set (&res, vx.v | vy.v);
    else xv_set (&res, vx.v ^ vy.v);
    env_set (r, a[2], &res);
  }
  { struct xval *av0 = env_get (r, s_of ("a0")); if (av0) *out = *av0; }
}
static long slice_width (struct str *s)
{
  long w = 0, i = 0;
  while (i < s->n) {
    long h = 0, l;
    while (i < s->n && is_digit (s->p[i])) { h = h * 10 + s->p[i] - '0'; i++; }
    l = h;
    if (i < s->n && s->p[i] == ':') { i++; l = 0; while (i < s->n && is_digit (s->p[i])) { l = l * 10 + s->p[i] - '0'; i++; } }
    w += h - l + 1;
    if (i < s->n && s->p[i] == '|') i++;
  }
  return w;
}
/* the bytes: -1 where a label gives one */
struct xbytes { long *b; long n, room; };
static void xb_push (struct xbytes *o, long v) { if (o->n == o->room) { long r = o->room ? o->room * 2 : 16, i; long *x = alloc (r * sizeof (long)); for (i = 0; i < o->n; i++) x[i] = o->b[i]; o->b = x; o->room = r; } o->b[o->n++] = v; }
static int xemit (struct nd *c, struct xenv *env, struct xbytes *out)
{
  struct str *name = c->c;
  long sz = s_is (name, "byte") ? 1 : s_is (name, "half") ? 2 : s_is (name, "word") ? 4 : s_is (name, "dword") ? 8 : 0;
  long i;
  int k;
  struct pbody *p;
  struct xenv *e;
  if (sz) {
    struct xval v;
    long b = 8 * sz;
    if (ndn (c)) argval (ndk (c, 0), env, &v); else xv_undef (&v);
    if (xerr) return 0;
    if (v.def && b < 64 && (xv_lt (&v, -((long) 1 << (b - 1))) || xv_ge (&v, (long) 1 << b))) return 0;
    for (i = 0; i < sz; i++) xb_push (out, v.def ? (long) (ushr ((unsigned long) v.v, 8 * i) & 0xff) : -1);
    return 1;
  }
  k = kind_of (name);
  if (xerr) return 0;
  p = params_body (name, h_pv (xdef, name));
  e = env_new (p->params->n);
  for (i = 0; i < p->params->n; i++) { struct xval u; if (i < ndn (c)) argval (ndk (c, i), env, &u); else xv_undef (&u); if (xerr) return 0; env_set (e, p->params->v[i], &u); }
  if (k == 1) {
    unsigned long v = 0;
    int vdef = 1;
    long w = 0;
    for (i = 0; i < p->body->n; i++) {
      struct nd *f = p->body->v[i];
      struct str *base, *spec;
      long fw;
      struct xval x, fv;
      if (m (f->c, "^(.*):$")) {
        struct str *bits = ndk (f, 0)->c;
        if (vdef) v = ushl (v, bits->n) | bin_of (bits);
        w += bits->n;
        continue;
      }
      if (!m (f->c, "^(.+)\\[([\\d:|]+)\\]$")) { struct str *x = s_dup (name); s_cat (x, ": field "); s_app (x, f->c); xfail (x); return 0; }
      base = g (1); spec = g (2);
      fw = slice_width (spec);
      argval (ndk (f, 0), e, &x);
      if (xerr) return 0;
      xv_undef (&fv);
      if (x.def) {
        if (!m (base, "'$") && m (spec, "^(\\d+)(:0)?$") && (gdef (2) || dec (g (1)) == 0)) {
          long hi = dec (g (1));
          if (xv_lt (&x, -((long) 1 << hi)) || xv_ge (&x, s_is (base, "imm") ? (long) 1 << hi : (long) 1 << (hi + 1))) return 0;
        }
        if (h_has (xdef, f->c)) { callval (f->c, &x, 1, &fv); if (xerr) return 0; }
        else {
          long h, l;
          if (!m (spec, "^(\\d+)(?::(\\d+))?$")) { struct str *y = s_dup (name); s_cat (y, ": no slice "); s_app (y, f->c); xfail (y); return 0; }
          h = dec (g (1)); l = gdef (2) ? dec (g (2)) : h;
          xv_uv (&fv, ushr ((unsigned long) x.v, l));
        }
        if (fv.def) xv_uv (&fv, (unsigned long) fv.v & (fw >= 64 ? ~(unsigned long) 0 : ((unsigned long) 1 << fw) - 1));
      }
      if (vdef && fv.def) v = ushl (v, fw) | (unsigned long) fv.v; else vdef = 0;
      w += fw;
    }
    if (w % 8) { struct str *x = s_dup (name); s_cat (x, ": "); s_app (x, s_num (w)); s_cat (x, " bits"); xfail (x); return 0; }
    for (i = 0; i < w / 8; i++) xb_push (out, vdef ? (long) (ushr (v, 8 * i) & 0xff) : -1);
    return 1;
  }
  if (k == 2) { struct str *x = s_dup (name); s_cat (x, ": a value, not bytes"); xfail (x); return 0; }
  for (i = 0; i < p->body->n; i++) if (!xemit (p->body->v[i], e, out) || xerr) return 0;
  return 1;
}

/* ---- the source's operands */
/* a number, or a constant expression, as GNU as takes it (0 if it is not one) */
static int xnum (struct str *v, long *out)
{
  struct str *e;
  if (!v || !m (v, "\\d") || !mf (v, "^[\\s\\da-fx()+\\-*/%<>&|~^]+$", "i")) return 0;
  e = s_of ("");
  {
    long at = 0, last = 0;
    struct rx *rr = rx_get ("\\b0x([0-9a-f]+)\\b", "i");
    while (at <= v->n && rx_exec (rr, v->p, v->n, at)) {
      unsigned long h = 0;
      long k;
      s_add (e, v->p + last, rc[0] - last);
      for (k = rc[2]; k < rc[3]; k++) h = h * 16 + (unsigned long) hexv (v->p[k]);
      s_app (e, s_num ((long) h));
      last = rc[1];
      at = rc[1] > rc[0] ? rc[1] : rc[0] + 1;
    }
    s_add (e, v->p + last, v->n - last);
  }
  if (!m (e, "^[\\s\\d()+\\-*/%<>&|~^]+$")) return 0;
  ep = e->p; en = e->n; ei = 0; ebad = 0;
  *out = e_or ();
  e_ws ();
  if (ebad || ei != en) return 0;
  return 1;
}
static struct hash *xnumeric;
static struct str *xlabel (struct str *o)
{
  long i;
  o = ssub (o, "@(PLT|plt)$", "", "");
  o = s_dup (o);
  for (i = 0; i < o->n; i++) if (o->p[i] == 1) o->p[i] = ' ';
  if (m (o, "^(\\d+)([fb])$")) {
    struct str *d = g (1), *x = s_of (".L");
    int f = g (2)->p[0] == 'f';
    s_app (x, d); s_cat (x, " "); s_app (x, s_num (h_iv (xnumeric, d) + (f ? 1 : 0)));
    return x;
  }
  return o;
}
/* an operand bound to a parameter of kind k: its alternatives, each a value and a leaf */
struct xalt { struct xval val; struct nd *leaf; };
static struct vec *bindop (struct str *k, struct str *s)
{
  struct vec *r = v_new ();
  struct xalt *a;
  long v;
  if (m (k, "^([qlwbxyzkcd])(?:\\.(lo|hi|any|ev|acc))?$") || m (k, "^(bm0|bm|bs|bx0|base|index)(?:\\.(lo|hi))?$")) {
    struct str *cls = g (1), *sub = g0 (2), *rn;
    if (cls->n > 1) cls = s_of ("q");
    if (!m (s, "^%(\\w+)$")) return r;
    rn = g (1);
    if (!isreg (rn)) return r;
    if (!s_is (cls, regclass (rn))) return r;
    if (s_is (sub, "acc") && h_iv (xreg_n, rn) != 0) return r;
    a = alloc (sizeof (struct xalt)); xv_set (&a->val, h_iv (xreg_n, rn)); a->leaf = nd_new (rn); v_push (r, a);
    return r;
  }
  if (s_is (k, "st.any")) {
    a = alloc (sizeof (struct xalt));
    if (s_is (s, "%st")) { xv_set (&a->val, 0); a->leaf = ndc ("st0"); v_push (r, a); return r; }
    if (m (s, "^%st\\((\\d)\\)$")) { struct str *d = g (1), *x = s_of ("st"); s_app (x, d); xv_set (&a->val, d->p[0] - '0'); a->leaf = nd_new (x); v_push (r, a); }
    return r;
  }
  if (s_is (k, "scale")) {
    if (!m (s, "^[1248]$")) return r;
    a = alloc (sizeof (struct xalt)); xv_set (&a->val, s->p[0] - '0'); a->leaf = nd_new (s); v_push (r, a);
    return r;
  }
  if (m (k, "^label8?$")) {
    if (s->n == 0 || m (s, "^[%$(*]") || m (s, "[(),{}]")) return r;
    if (m (s, "^([.\\w\\x01]+)([-+][\\d*+\\-]+)$")) {
      struct str *sy = g (1), *off = s_of ("0");
      long ov;
      s_app (off, g (2));
      if (xnum (off, &ov)) {
        a = alloc (sizeof (struct xalt)); xv_undef (&a->val);
        a->leaf = nd_add (nd2 (s_of ("addi"), LN (ov), nd_new (xlabel (sy))), ndc ("a0"));
        v_push (r, a);
        return r;
      }
    }
    a = alloc (sizeof (struct xalt)); xv_undef (&a->val); a->leaf = nd_new (xlabel (s)); v_push (r, a);
    return r;
  }
  if (m (s, "^%")) return r;
  if (s->n == 0 && m (k, "^d")) s = s_of ("0");
  if (s->n == 0) return r;
  if (xnum (s, &v)) {
    a = alloc (sizeof (struct xalt)); xv_set (&a->val, v); a->leaf = LN (v); v_push (r, a);
    if (m (k, "^[iu]")) {
      long lim[3], q;
      lim[0] = 4294967296L; lim[1] = 65536; lim[2] = 256;
      for (q = 0; q < 3; q++) if (v >= lim[q] / 2 && v < lim[q]) { a = alloc (sizeof (struct xalt)); xv_set (&a->val, v - lim[q]); a->leaf = LN (v - lim[q]); v_push (r, a); }
    }
    return r;
  }
  if (m (s, "[(),{}]") || !m (s, "^[.\\w\\x01]+$")) return r;
  a = alloc (sizeof (struct xalt)); xv_undef (&a->val); a->leaf = nd_new (xlabel (s)); v_push (r, a);
  return r;
}

/* the forms whose GNU line is the instruction: each form, its environment, its leaves */
struct xhit { struct xform *f; struct xenv *env; struct vec *leaves; };
static struct vec *xmatches (struct str *mn, struct vec *o)
{
  struct vec *forms = h_pv (bymn, mn), *res = v_new ();
  long fi, i, j, q;
  if (!forms) return res;
  for (fi = 0; fi < forms->n; fi++) {
    struct xform *f = forms->v[fi];
    struct xenv *cap;
    struct vec *alts;
    int ok = 1;
    if (f->opat->n != o->n) continue;
    cap = env_new (8);
    for (i = 0; i < o->n && ok; i++) {
      struct vec *names = f->onames->v[i];
      struct str *os = o->v[i];
      if (!f->orx[i]) { struct str *pt = f->opat->v[i]; f->orx[i] = rx_comp ((char *) pt->p, pt->n, ""); }
      g_s = os->p;
      if (!rx_exec (f->orx[i], os->p, os->n, 0)) { ok = 0; break; }
      {
        struct caps *cs = caps_save ();
        for (j = 0; j < names->n; j++) {
          struct xval sv;
          caps_load (cs);
          xv_undef (&sv);
          sv.v = (long) g0 (j + 1);   /* (the captured text, kept as a pointer) */
          sv.def = 2;
          env_set (cap, names->v[j], &sv);
        }
      }
    }
    if (!ok) continue;
    /* each parameter's value and leaf; an immediate: some, one taken */
    alts = v_new ();
    { struct xhit *h = alloc (sizeof (struct xhit)); h->f = f; h->env = env_new (f->kp->n); h->leaves = v_new (); v_push (alts, h); }
    for (i = 0; i < f->kp->n && ok; i++) {
      struct str *p = f->kp->v[i], *k = f->kk->v[i];
      struct xval *cv = env_get (cap, p);
      struct vec *b, *nalts;
      if (!cv) { ok = 0; break; }
      b = bindop (k ? k : s_of (""), (struct str *) cv->v);
      if (!b->n) { ok = 0; break; }
      nalts = v_new ();
      for (j = 0; j < alts->n; j++) {
        struct xhit *h = alts->v[j];
        for (q = 0; q < b->n; q++) {
          struct xalt *a = b->v[q];
          struct xhit *hit2 = alloc (sizeof (struct xhit));
          long z;
          hit2->f = f; hit2->env = env_new (h->env->n + 1); hit2->leaves = v_new ();
          for (z = 0; z < h->env->n; z++) env_set (hit2->env, h->env->nm[z], &h->env->va[z]);
          env_set (hit2->env, p, &a->val);
          for (z = 0; z < h->leaves->n; z++) v_push (hit2->leaves, h->leaves->v[z]);
          v_push (hit2->leaves, a->leaf);
          v_push (nalts, hit2);
        }
      }
      alts = nalts;
    }
    if (!ok) continue;
    for (j = 0; j < alts->n; j++) v_push (res, alts->v[j]);
  }
  return res;
}
static int bytes_of (struct xhit *h, struct xbytes *out)
{
  struct nd *d = h_pv (xdef, h->f->name);
  struct pbody *p;
  long i;
  if (!d) { struct str *x = s_of ("no definition of the form "); s_app (x, h->f->name); xfail (x); return 0; }
  p = params_body (h->f->name, d);
  for (i = 0; i < p->body->n; i++) if (!xemit (p->body->v[i], h->env, out) || xerr) return 0;
  return 1;
}
static int same_bytes (long *want, long nw, struct xbytes *got)
{
  long i;
  if (nw != got->n) return 0;
  for (i = 0; i < nw; i++) if (got->b[i] >= 0 && got->b[i] != want[i]) return 0;
  return 1;
}
static struct str *hexes (long *b, long n) { struct str *o = s_of (""); long i; for (i = 0; i < n; i++) { if (i) s_cat (o, " "); s_app (o, s_hex ((unsigned long) b[i], 2, 0)); } return o; }

static struct hash *xprefix, *xalias;
static int prefix_byte (struct str *p) { return (int) h_iv (xprefix, p); }
static int is_prefix (struct str *p) { return h_has (xprefix, p); }
/* one instruction: its prefixes' calls and the form whose bytes are GNU's (into out) */
static int translate (struct str *mn, struct vec *ops, long *bytes, long nb, struct str *dumpasm, struct vec *pre, struct vec *outn)
{
  struct str *dumpmn = 0, *dumpops = 0;
  struct vec *o = v_new (), *keys = v_new (), *alts, *hit = v_new ();
  struct hash *seen = h_new ();
  long *want, nw, i, j, q;
  char *sfx[4];
  sfx[0] = "b"; sfx[1] = "w"; sfx[2] = "l"; sfx[3] = "q";
  if (dumpasm && m (dumpasm, "^(?:(?:rep\\w*|lock|data16|notrack|cs|ds|fs|gs|bnd)\\s+)*(\\S+)\\s*(.*)$")) { dumpmn = g (1); dumpops = g (2); }
  { struct vec *pre2 = v_new (); for (i = 0; i < pre->n; i++) v_push (pre2, pre->v[i]); pre = pre2; }
  for (i = 0; i < ops->n; i++) v_push (o, nows (ops->v[i]));
  for (i = 0; i < o->n; i++) {
    struct str *x = o->v[i];
    if (m (x, "^%(cs|ds|fs|gs):")) { v_push (pre, g (1)); x = s_sub (x, rc[1], x->n); }
    else if (m (x, "^\\*%(cs|ds|fs|gs):")) { v_push (pre, g (1)); x = s_join (s_of ("*"), "", s_sub (x, rc[1], x->n)); }
    x = ssub (x, "\\((%\\w+),(%\\w+)\\)$", "", "($1,$2,1)");
    o->v[i] = x;
  }
  {
    int any = 0;
    for (i = 0; i < o->n; i++) if (m (o->v[i], "\\(%(e[a-z]{2}|r\\d+d)\\b")) any = 1;
    if (any) {
      for (i = 0; i < o->n; i++) {
        struct str *x = o->v[i], *y = s_of ("");
        struct rx *rr = rx_get ("(?<=[(,])%(e[a-z]{2}|r\\d+d)\\b", "");
        long at = 0, last = 0;
        while (at <= x->n && rx_exec (rr, x->p, x->n, at)) {
          struct str *r32;
          long k, num_;
          g_s = x->p;
          r32 = g (1);
          s_add (y, x->p + last, rc[0] - last);
          s_cat (y, "%");
          num_ = h_iv (xreg_n, r32);
          for (k = 0; k < xreg_n->keys->n; k++) {
            struct hent *e = xreg_n->keys->v[k];
            if (e->iv == num_ && s_is (e->k, "") == 0 && ((char *) h_pv (xreg_c, e->k))[0] == 'q') { s_app (y, e->k); break; }
          }
          last = rc[1];
          at = rc[1] > rc[0] ? rc[1] : rc[0] + 1;
        }
        s_add (y, x->p + last, x->n - last);
        o->v[i] = y;
      }
      v_push (pre, s_of ("addr32"));
    }
  }
  want = bytes; nw = nb;
  for (i = 0; i < pre->n; i++) {
    if (!(nw && want[0] == prefix_byte (pre->v[i]))) { struct str *x = s_of ("GNU as put the prefix "); s_app (x, pre->v[i]); s_cat (x, " elsewhere: "); s_app (x, hexes (bytes, nb)); xfail (x); return 0; }
    want++; nw--;
  }
  v_push (keys, mn);
  if (h_pv (xalias, mn)) v_push (keys, h_pv (xalias, mn));
  for (i = 0; i < 4; i++) { struct str *x = s_dup (mn); s_cat (x, sfx[i]); v_push (keys, x); }
  if (dumpmn && dumpmn->n) { v_push (keys, dumpmn); for (i = 0; i < 4; i++) { struct str *x = s_dup (dumpmn); s_cat (x, sfx[i]); v_push (keys, x); } }
  alts = v_new ();
  v_push (alts, o);
  if (o->n && s_is (o->v[0], "$1") && m (mn, "^(rol|ror|rcl|rcr|shl|sal|shr|sar)[bwlq]?$")) { struct vec *x = v_new (); for (i = 1; i < o->n; i++) v_push (x, o->v[i]); v_push (alts, x); }
  if (m (mn, "^xchg[bwlq]?$")) { struct vec *x = v_new (); for (i = o->n - 1; i >= 0; i--) v_push (x, o->v[i]); v_push (alts, x); }
  if (!o->n && m (mn, "^fn?stsw$")) { struct vec *x = v_new (); v_push (x, s_of ("%ax")); v_push (alts, x); }
  for (i = 0; i < keys->n; i++) {
    struct str *k = keys->v[i];
    if (h_has (seen, k)) continue;
    h_set (seen, k, 1);
    for (j = 0; j < alts->n; j++) {
      struct vec *ms = xmatches (k, alts->v[j]);
      if (xerr) return 0;
      for (q = 0; q < ms->n; q++) {
        struct xbytes b;
        b.b = 0; b.n = 0; b.room = 0;
        if (bytes_of (ms->v[q], &b) && b.n && same_bytes (want, nw, &b)) v_push (hit, ms->v[q]);
        if (xerr) return 0;
      }
    }
    if (hit->n) break;
  }
  if (!hit->n && dumpops && dumpops->n) {
    int sym = 0;
    for (i = 0; i < o->n; i++) { struct str *x = ssub (o->v[i], "%\\w+|\\b0x[0-9a-f]+\\b|\\d+", "gi", ""); if (mf (x, "[a-z_.]", "i")) sym = 1; }
    if (!sym) {
      struct vec *dlst = x_split_ops (dumpops), *d = v_new ();
      struct hash *seen2 = h_new ();
      struct vec *keys2 = v_new ();
      for (i = 0; i < dlst->n; i++) v_push (d, ssub (nows (dlst->v[i]), "^%(cs|ds|fs|gs):", "", ""));
      v_push (keys2, dumpmn);
      for (i = 0; i < 4; i++) { struct str *x = s_dup (dumpmn); s_cat (x, sfx[i]); v_push (keys2, x); }
      for (i = 0; i < keys2->n; i++) {
        struct vec *ms;
        if (h_has (seen2, keys2->v[i])) continue;
        h_set (seen2, keys2->v[i], 1);
        ms = xmatches (keys2->v[i], d);
        for (q = 0; q < ms->n; q++) {
          struct xbytes b;
          b.b = 0; b.n = 0; b.room = 0;
          if (bytes_of (ms->v[q], &b) && b.n && same_bytes (want, nw, &b)) v_push (hit, ms->v[q]);
          if (xerr) return 0;
        }
        if (hit->n) break;
      }
    }
  }
  if (!hit->n) {
    struct str *x = s_of ("no form of "), *near = s_of ("");
    struct hash *t = h_new ();
    long nn = 0;
    for (i = 0; i < seen->keys->n; i++) {
      struct str *k = ((struct hent *) seen->keys->v[i])->k;
      struct vec *ms;
      if (!h_pv (bymn, k)) continue;
      ms = xmatches (k, o);
      for (q = 0; q < ms->n; q++) {
        struct str *nm = ((struct xhit *) ms->v[q])->f->name;
        if (h_has (t, nm)) continue;
        h_set (t, nm, 1);
        if (nn < 6) { if (nn) s_cat (near, " "); s_app (near, nm); }
        nn++;
      }
    }
    s_app (x, mn); s_cat (x, " ");
    for (i = 0; i < ops->n; i++) { if (i) s_cat (x, ", "); s_app (x, ops->v[i]); }
    s_cat (x, " makes GNU's "); s_app (x, hexes (want, nw));
    if (nn) { s_cat (x, " (of "); s_app (x, near); s_cat (x, ")"); } else s_cat (x, " (ttpc has no form of it)");
    xfail (x);
    return 0;
  }
  {
    struct xhit *best = hit->v[0];
    for (i = 1; i < hit->n; i++) if (((struct xhit *) hit->v[i])->f->order < best->f->order) best = hit->v[i];
    for (i = 0; i < pre->n; i++) v_push (outn, nd_new (pre->v[i]));
    {
      struct nd *x = nd_new (best->f->name);
      for (i = 0; i < best->leaves->n; i++) nd_add (x, best->leaves->v[i]);
      v_push (outn, x);
    }
  }
  return 1;
}

/* ---- the dump */
struct xm { long addr; long *b; long nb, room; struct str *asm_; };
static void xm_push (struct xm *x, long v) { if (x->nb == x->room) { long r = x->room ? x->room * 2 : 16, i; long *y = alloc (r * sizeof (long)); for (i = 0; i < x->nb; i++) y[i] = x->b[i]; x->b = y; x->room = r; } x->b[x->nb++] = v; }
static struct hash *read_dump_x (struct str *dump)
{
  struct str *t = p_slurp ((char *) dump->p, "s2ff"), *sec = s_of ("");
  struct lines *ls = split_lines (t);
  struct hash *made_ = h_new ();
  struct vec *tsecs = v_new ();
  long i, k;
  for (i = 0; i < ls->n; i++) {
    struct str *l = ls->l[i], *hx, *as, *key;
    struct vec *mv, *hb;
    long addr;
    struct xm *x;
    if (m (l, "^Disassembly of section (\\S+):")) { sec = g (1); continue; }
    if (!m (l, "^\\s*([0-9a-f]+):\\t([0-9a-f ]+?)\\s*(?:\\t(.*))?$")) continue;
    addr = hexl (g (1)); hx = g (2); as = g0 (3);
    as = ssub (as, "\\s*#.*", "", "");
    as = ssub (as, "\\s+<[^>]*>\\s*$", "", "");
    hb = ssplit (" ", hx, 0);
    if (m (sec, "^\\.text")) { int f = 0; for (k = 0; k < tsecs->n; k++) if (s_eq (tsecs->v[k], sec)) f = 1; if (!f) v_push (tsecs, sec); }
    key = m (sec, "^\\.text") ? s_of (".text") : sec;
    mv = h_pv (made_, key);
    if (!mv) { mv = v_new (); h_setp (made_, key, mv); }
    if (as->n == 0 && mv->n) { x = mv->v[mv->n - 1]; for (k = 0; k < hb->n; k++) if (((struct str *) hb->v[k])->n) xm_push (x, hexl (hb->v[k])); continue; }
    x = alloc (sizeof (struct xm));
    x->addr = addr; x->asm_ = as;
    for (k = 0; k < hb->n; k++) if (((struct str *) hb->v[k])->n) xm_push (x, hexl (hb->v[k]));
    v_push (mv, x);
  }
  if (tsecs->n > 1) {
    struct str *x = s_of ("code in more than one section:");
    v_sort_str (tsecs);
    for (k = 0; k < tsecs->n; k++) { s_cat (x, " "); s_app (x, tsecs->v[k]); }
    fail_s (x);
  }
  return made_;
}
static int is_code (struct str *s) { return m (s, "^\\.text(\\.|$)") || m (s, "^\\.(init|fini)$"); }

/* ---- the walk */
struct xcode { struct vec *made; long n, pos; struct nd *fn, *block; int ends; };
static struct vec *xmade; static long xn, xpos; static int xends;
static struct str *xother; static struct vec *xpending; static struct hash *xdatadef, *xgot, *xtls, *xmacro, *xweak, *xweakgot, *xzeroed;
static long xalign; static int xalign_def; static long xmaxalign; static int xmaxalign_def;
static struct vec *xprefixes, *xsections, *xcarried, *xcarry, *xruns;
static struct hash *xMADE, *xCODE, *xrodata, *xro, *xroset, *xrunof, *xrunidx, *xinto;
static struct str *xcode_;
static struct vec *xroblob;
static long xroalign; static int xroalign_def;
static struct xm *xtake (void)
{
  struct xm *mm;
  if (xn >= xmade->n) fail_c ("GNU as made fewer instructions than the source has");
  mm = xmade->v[xn++];
  if (mm->addr != xpos) { struct str *x = s_of ("GNU's next instruction is at 0x"); s_app (x, s_hex ((unsigned long) mm->addr, 0, 0)); s_cat (x, ", the source's at 0x"); s_app (x, s_hex ((unsigned long) xpos, 0, 0)); fail_s (x); }
  xpos += mm->nb;
  return mm;
}
static struct nd *xinto_ (void) { return block ? block : fn; }
struct carried { struct nd *f; struct vec *nodes; };
static void xfinish (void)
{
  long i;
  if (fn && xro->n) { struct carried *c = alloc (sizeof (struct carried)); c->f = fn; c->nodes = h_sorted (xro); v_push (xcarry, c); }
  h_clear (xro);
  for (i = 0; i < xgot->keys->n; i++) { struct str *k = ((struct hent *) xgot->keys->v[i])->k; if (h_iv (xweak, k)) h_set (xweakgot, k, 1); }
  {
    struct hash *g2 = h_new ();
    for (i = 0; i < xgot->keys->n; i++) { struct str *k = ((struct hent *) xgot->keys->v[i])->k; if (!h_has (xweakgot, k)) h_set (g2, k, 1); }
    xgot = g2;
  }
  if (!(fn && (xtls->n || xgot->n))) return;
  {
    struct carried *c = alloc (sizeof (struct carried));
    struct vec *k;
    c->f = fn; c->nodes = v_new ();
    v_push (c->nodes, nd1 (s_of ("align"), ndc ("8")));
    k = h_sorted (xtls);
    for (i = 0; i < k->n; i++) { struct str *x = s_of (".Ltls "); s_app (x, k->v[i]); s_cat (x, ":"); v_push (c->nodes, nd1 (x, nd1 (s_of ("dword"), nd1 (s_of ("tprel"), nd_new (k->v[i]))))); }
    k = h_sorted (xgot);
    for (i = 0; i < k->n; i++) { struct str *x = s_of (".Lgot "); s_app (x, k->v[i]); s_cat (x, ":"); v_push (c->nodes, nd1 (x, nd1 (s_of ("dword"), nd_new (k->v[i])))); }
    v_push (xcarried, c);
  }
  h_clear (xtls); xgot = h_new ();
}
static void code_to (struct str *sec)
{
  struct xcode *c;
  int had;
  if (xcode_) {
    struct xcode *s = alloc (sizeof (struct xcode));
    long i;
    s->made = v_new (); for (i = 0; i < xmade->n; i++) v_push (s->made, xmade->v[i]);
    s->n = xn; s->pos = xpos; s->fn = fn; s->block = block; s->ends = xends;
    h_setp (xCODE, xcode_, s);
  }
  c = h_pv (xCODE, sec);
  had = c != 0;
  if (!c) { c = alloc (sizeof (struct xcode)); c->made = h_pv (xMADE, sec) ? h_pv (xMADE, sec) : v_new (); c->fn = fn; c->ends = 1; }
  xcode_ = sec;
  { struct vec *mv = v_new (); long i; for (i = 0; i < c->made->n; i++) v_push (mv, c->made->v[i]); xmade = mv; }
  xn = c->n; xpos = c->pos; fn = c->fn; block = c->block; xends = c->ends;
  if (!had) { block = 0; xends = 1; }
}
static void code_done (void)
{
  struct vec *k;
  long i;
  code_to (xcode_);
  k = h_sorted (xCODE);
  for (i = 0; i < k->n; i++) {
    struct xcode *c = h_pv (xCODE, k->v[i]);
    struct vec *mv = c->made;
    while (mv->n > c->n && m (((struct xm *) mv->v[mv->n - 1])->asm_, "^((data16|cs)\\s+)*(nop\\w*|xchg\\s+%ax,%ax)\\b")) mv->n--;
    if (c->n != mv->n) { struct str *x = s_of ("GNU as made "); s_app (x, s_num (mv->n)); s_cat (x, " instructions in "); s_app (x, k->v[i]); s_cat (x, ", the source "); s_app (x, s_num (c->n)); fail_s (x); }
  }
  k = h_sorted (xMADE);
  for (i = 0; i < k->n; i++) if (!h_pv (xCODE, k->v[i])) { struct str *x = s_of ("GNU as made code in "); s_app (x, k->v[i]); s_cat (x, ", the source has none"); fail_s (x); }
}
static struct vec *padnode (struct xm *mm);
static void xpad (long a, long max, int has_max, long fill, int has_fill)
{
  long to;
  if (a <= 1) return;
  if (!xmaxalign_def || a > xmaxalign) { xmaxalign = a; xmaxalign_def = 1; }
  to = (xpos + a - 1) & ~(a - 1);
  if (has_max && to - xpos > max) return;
  if (has_fill) {
    long part = 0;
    while (xpos < to) {
      struct xm *mm;
      long k;
      if (!fn) fail_c ("padding outside a function");
      if (xn >= xmade->n) fail_c ("GNU as made no padding here");
      mm = xmade->v[xn];
      if (!(mm->addr == xpos && mm->nb && mm->b[0] == fill)) { struct str *x = s_of ("GNU's padding is not "); s_app (x, s_num (fill)); s_cat (x, " at 0x"); s_app (x, s_hex ((unsigned long) xpos, 0, 0)); fail_s (x); }
      nd_add (xinto_ (), nd1 (s_of ("byte"), LN (fill)));
      for (k = 1; k < mm->nb; k++) mm->b[k - 1] = mm->b[k];
      mm->nb--;
      mm->addr++;
      xpos++;
      part = mm->nb;
      if (!part) xn++;
    }
    if (part && xn + 1 < xmade->n) {
      struct xm *mm = xmade->v[xn], *nx = xmade->v[xn + 1], *y = alloc (sizeof (struct xm));
      long k;
      for (k = 0; k < mm->nb; k++) xm_push (y, mm->b[k]);
      for (k = 0; k < nx->nb; k++) xm_push (y, nx->b[k]);
      y->addr = xpos; y->asm_ = nx->asm_;
      for (k = xn + 1; k + 1 < xmade->n; k++) xmade->v[k] = xmade->v[k + 1];
      xmade->n--;
      xmade->v[xn] = y;
    }
    return;
  }
  while (xpos < to) {
    struct vec *ns;
    long k;
    if (!fn) fail_c ("padding outside a function");
    ns = padnode (xtake ());
    for (k = 0; k < ns->n; k++) nd_add (xinto_ (), ns->v[k]);
  }
  if (xpos > to) fail_c ("GNU's padding runs past the alignment");
}
static struct vec *padnode (struct xm *mm)
{
  struct str *mn, *rest;
  struct vec *pre = v_new (), *ops, *out = v_new ();
  if (!m (mm->asm_, "^(\\S+)\\s*(.*)$")) fail_c ("padding with no text");
  mn = g (1); rest = g (2);
  while (is_prefix (mn)) { v_push (pre, mn); m (rest, "^(\\S+)\\s*(.*)$"); mn = g0 (1); rest = g0 (2); }
  ops = x_split_ops (rest);
  xsoft = 1; xerr = 0;
  if (translate (mn, ops, mm->b, mm->nb, 0, pre, out) && !xerr) { xsoft = 0; return out; }
  xsoft = 0; xerr = 0;
  if (s_is (mn, "nopw")) {
    struct vec *pre2 = v_new ();
    long k;
    v_push (pre2, s_of ("data16"));
    for (k = 0; k < pre->n; k++) v_push (pre2, pre->v[k]);
    out = v_new ();
    xsoft = 1;
    if (translate (s_of ("nopl"), ops, mm->b, mm->nb, 0, pre2, out) && !xerr) { xsoft = 0; xerr = 0; return out; }
    xsoft = 0; xerr = 0;
  }
  { struct str *x = s_of ("padding of no form: "); s_app (x, mm->asm_); s_cat (x, " ("); s_app (x, hexes (mm->b, mm->nb)); s_cat (x, ")"); fail_s (x); }
  return 0;
}
/* the lines of a .s, each with its file and line */
struct sline { struct str *l, *file; long lineno; };
static struct vec *read_src_x (struct str *src)
{
  struct str *t = p_slurp ((char *) src->p, "s2ff"), *file = s_of ("");
  struct lines *ls = split_lines (t);
  struct vec *o = v_new ();
  long i, lineno = 0;
  for (i = 0; i < ls->n; i++) {
    struct str *l = chomp (ls->l[i]);
    struct sline *x;
    if (m (l, "^# (\\d+) \"([^\"]+)\"")) { lineno = dec (g (1)) - 1; file = ssub (g (2), "^(\\.\\./)+", "", ""); continue; }
    if (m (l, "^\\s*#")) continue;
    lineno++;
    if (!m (l, "\"")) l = ssub (l, "\\s*#.*$", "", "");
    x = alloc (sizeof (struct sline)); x->l = l; x->file = file; x->lineno = lineno;
    v_push (o, x);
  }
  return o;
}
static void walk_stmt (struct str *st, struct str *file, long lineno);
static void xsection (struct str *sec)
{
  if (is_code (sec)) { xother = 0; code_to (m (sec, "^\\.text") ? s_of (".text") : sec); return; }
  xother = sec;
  xpending = v_new ();
  xroblob = 0;
}
struct runent { struct vec *names, *bytes; long align; int has_align; };
static void rodata_add (struct nd *d)
{
  if (xpending->n) {
    struct runent *e = alloc (sizeof (struct runent));
    struct vec *run;
    long k, i;
    xroblob = v_new ();
    for (i = 0; i < xpending->n; i++) h_setp (xrodata, xpending->v[i], xroblob);
    if (!h_has (xrunidx, xother)) { v_push (xruns, v_new ()); h_set (xrunidx, xother, xruns->n - 1); }
    k = h_iv (xrunidx, xother);
    run = xruns->v[k];
    e->names = xpending; e->bytes = xroblob; e->align = xroalign; e->has_align = xroalign_def;
    v_push (run, e);
    for (i = 0; i < xpending->n; i++) h_set (xrunof, xpending->v[i], k + 1);
    xpending = v_new ();
    xroalign_def = 0;
  }
  if (!xroblob) fail_c ("read-only bytes with no label");
  v_push (xroblob, d);
}
static void rodata_set (struct str *x)
{
  struct vec *set, *b;
  struct str *y;
  long off, i = 0, off0;
  if (h_pv (xrodata, x) || !h_pv (xroset, x)) return;
  set = h_pv (xroset, x);
  y = set->v[0]; off = *(long *) set->v[1]; off0 = off;
  rodata_set (y);
  b = h_pv (xrodata, y);
  if (!b) return;
  while (off > 0) {
    struct nd *d;
    long k;
    if (i >= b->n) { struct str *z = s_dup (x); s_cat (z, ": past the bytes of "); s_app (z, y); fail_s (z); }
    d = b->v[i++];
    k = s_is (d->c, "byte") ? 1 : s_is (d->c, "half") ? 2 : s_is (d->c, "word") ? 4 : s_is (d->c, "dword") ? 8 : 0;
    if (!k) { struct str *z = s_dup (x); s_cat (z, ": "); s_app (z, y); s_cat (z, "+"); s_app (z, s_num (off0)); s_cat (z, " inside its "); s_app (z, d->c); fail_s (z); }
    off -= k;
  }
  if (off < 0) { struct str *z = s_dup (x); s_cat (z, ": "); s_app (z, y); s_cat (z, "+"); s_app (z, s_num (off0)); s_cat (z, " inside a word of it"); fail_s (z); }
  { struct vec *nb = v_new (); for (; i < b->n; i++) v_push (nb, b->v[i]); h_setp (xrodata, x, nb); }
}
static struct hash *xkw;
static struct str *kwname (struct str *n) { if (h_has (xkw, n)) { struct str *x = s_dup (n); s_cat (x, "'"); return x; } return n; }

/* a decimal number as the double nearest it (Perl's NV of the text) */
static unsigned long dbl_bits (struct str *t);
static unsigned long flt_bits (unsigned long d);

static int skipnote;
static struct str *ptr_key (void *p) { return s_num ((long) p); }
static void walk_stmt (struct str *st, struct str *file, long lineno)
{
  struct str *op, *rest;
  struct vec *ops, *pre, *nodes;
  struct xm *mm;
  long i;
  if (m (st, "^\\.pushsection\\s+\"?\\.note\\.gnu\\.property\"?")) { skipnote = 1; return; }
  if (skipnote) { if (s_is (st, ".popsection")) skipnote = 0; return; }
  if (m (st, "^\\.weak\\s+([.\\w]+)$")) h_set (xweak, g (1), 1);
  if (m (st, "^\\.(text|data|bss)$")) {
    struct str *s = s_of ("."); struct vec *p = v_new ();
    s_app (s, g (1));
    v_push (p, xother); v_push (p, xcode_); v_push (xsections, p);
    xsection (s);
    return;
  }
  if (m (st, "^\\.section\\s+\"?([^\",\\s]+)\"?")) {
    struct str *s = g (1); struct vec *p = v_new ();
    v_push (p, xother); v_push (p, xcode_); v_push (xsections, p);
    xsection (s);
    return;
  }
  if (s_is (st, ".previous")) {
    struct vec *p = v_pop (xsections), *q = v_new ();
    struct str *c;
    if (!p) fail_c (".previous with no section before");
    v_push (q, xother); v_push (q, xcode_); v_push (xsections, q);
    xother = p->v[0]; c = p->v[1];
    if (!xother) code_to (c);
    return;
  }
  if (xother && m (xother, "^\\.(?:gcc_except_table|note\\.|data\\.DW\\.ref\\.|init_array\\.)")) return;
  if (xother) {
    if (m (xother, "^\\.?rodata") && m (st, "^\\.(p2align|align|balign)\\s+([^,]+)")) {
      struct str *d = g (1), *v = g (2);
      long x, a;
      if (!xnum (v, &x)) fail_s (st);
      a = s_is (d, "p2align") ? (long) ushl (1, x) : x;
      if (!xroalign_def || a > xroalign) { xroalign = a; xroalign_def = 1; }
      return;
    }
    if (m (st, "^\\.(globl|global|weak|type|size|hidden|protected|align|p2align|balign|cfi_\\w+|ident)\\b")) return;
    if (m (st, "^([.\\w]+):\\s*(\\S.*)$")) { struct str *a = g (1), *b = g (2); v_push (xpending, a); xroblob = 0; walk_stmt (b, file, lineno); return; }
    if (m (st, "^([.\\w]+):$")) { v_push (xpending, g (1)); xroblob = 0; return; }
    if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$")) { struct str *a = g (1), *b = g (2); if (h_iv (xdatadef, b)) v_push (fns, alias_of (a, b)); return; }
    if (m (xother, "^\\.?rodata")) {
      if (m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*([.\\w]+)\\s*(?:\\+\\s*(\\d+))?$")) {
        struct str *a = g (1), *b = g (2), *c = g (3);
        struct vec *p = v_new ();
        long *o = alloc (sizeof (long));
        *o = c ? dec (c) : 0;
        v_push (p, b); v_push (p, o);
        h_setp (xroset, a, p);
        return;
      }
      if (m (st, "^\\.(int|long|4byte)\\s+([.\\w]+)\\s*-\\s*([.\\w]+)$")) {
        struct str *x = g (2), *y = g (3);
        if (!m (x, "^\\.L")) h_set (xro, x, 1);
        if (!m (y, "^\\.L")) h_set (xro, y, 1);
        rodata_add (nd1 (s_of ("word"), nd_add (nd2 (s_of ("sub"), nd_new (y), nd_new (x)), ndc ("a0"))));
        return;
      }
      if (m (st, "^\\.(string|asciz|ascii)\\s+\"((?:[^\"\\\\]|\\\\.)*)\"$")) {
        struct str *k = g (1), *tx = g (2), *o = s_of ("");
        i = 0;
        while (i < tx->n) {
          if (tx->p[i] != '\\' || i + 1 >= tx->n) { s_chr (o, tx->p[i]); i++; continue; }
          i++;
          if (tx->p[i] >= '0' && tx->p[i] <= '7') { long v = 0, c = 0; while (c < 3 && i < tx->n && tx->p[i] >= '0' && tx->p[i] <= '7') { v = v * 8 + tx->p[i] - '0'; i++; c++; } s_chr (o, (int) (v & 255)); continue; }
          if (tx->p[i] == 'x' && i + 1 < tx->n && is_xdigit (tx->p[i + 1])) { long v = 0, c = 0; i++; while (c < 2 && i < tx->n && is_xdigit (tx->p[i])) { v = v * 16 + hexv (tx->p[i]); i++; c++; } s_chr (o, (int) v); continue; }
          {
            int e = tx->p[i];
            int r = e == 'n' ? '\n' : e == 't' ? '\t' : e == 'r' ? '\r' : e == 'f' ? '\f' : e == 'b' ? '\b' : e == '"' ? '"' : e == '\\' ? '\\' : -1;
            if (r < 0) { struct str *x = s_of ("an escape \\"); s_chr (x, e); fail_s (x); }
            s_chr (o, r); i++;
          }
        }
        if (!s_is (k, "ascii")) s_chr (o, 0);
        rodata_add (nd1 (s_of ("ascii"), nd_new (o)));
        return;
      }
      if (m (st, "^\\.(double|float)\\s+([-+]?(?:\\d+\\.?\\d*(?:[eE][-+]?\\d+)?|\\.\\d+(?:[eE][-+]?\\d+)?))$")) {
        struct str *k = g (1), *v = g (2);
        unsigned long d = dbl_bits (v);
        if (s_is (k, "double")) { rodata_add (nd1 (s_of ("dword"), nd_new (s_unum (d)))); return; }
        rodata_add (nd1 (s_of ("word"), nd_new (s_unum (flt_bits (d)))));
        return;
      }
      if (m (st, "^\\.(byte|value|short|2byte|word|long|int|4byte|quad|8byte)\\s+(-?(?:0x[0-9a-fA-F]+|\\d+))(?:\\s*,\\s*-?(?:0x[0-9a-fA-F]+|\\d+))+$")) {
        struct str *k = g (1), *list = ssub (st, "^\\.\\w+\\s+", "", "");
        struct vec *it = ssplit ("\\s*,\\s*", list, 0);
        for (i = 0; i < it->n; i++) { struct str *x = s_of ("."); s_app (x, k); s_cat (x, " "); s_app (x, it->v[i]); walk_stmt (x, file, lineno); }
        return;
      }
      if (m (st, "^\\.(byte|value|short|2byte|word|long|int|4byte|quad|8byte|zero|skip)\\s+(-?(?:0x[0-9a-fA-F]+|\\d+))$")) {
        struct str *k = g (1), *vs = g (2), *dir;
        long bits;
        if (mf (vs, "^(-?)0x(.*)$", "i")) {
          struct str *neg = g (1), *hx = g (2);
          unsigned long h = 0;
          long q;
          for (q = 0; q < hx->n; q++) h = h * 16 + (unsigned long) hexv (hx->p[q]);
          vs = neg->n ? s_num (-(long) h) : s_unum (h);
        }
        if (m (k, "^(zero|skip)$")) { rodata_add (nd1 (s_of ("reserve"), nd_new (vs))); return; }
        if (s_is (k, "byte")) { dir = s_of ("byte"); bits = 8; }
        else if (m (k, "^(value|short|2byte|word)$")) { dir = s_of ("half"); bits = 16; }
        else if (m (k, "^(long|int|4byte)$")) { dir = s_of ("word"); bits = 32; }
        else { dir = s_of ("dword"); bits = 64; }
        if (vs->n && vs->p[0] == '-') {
          unsigned long v = 0;
          long q;
          for (q = 1; q < vs->n; q++) v = v * 10 + (unsigned long) (vs->p[q] - '0');
          if (v) vs = bits == 64 ? nv_g15 (v) : s_num (((long) 1 << bits) - (long) v);
        }
        rodata_add (nd1 (dir, nd_new (vs)));
        return;
      }
    }
    if (m (st, "^\\.(long|int|quad|byte|value|short|word)\\s+0$")) {
      struct str *k = g (1);
      st = s_of (".zero ");
      s_cat (st, m (k, "^(long|int)$") ? "4" : s_is (k, "quad") ? "8" : s_is (k, "byte") ? "1" : "2");
    }
    if (m (st, "^\\.(zero|space)\\s+(\\d+)$") && xpending->n) {
      struct str *first = xpending->v[0], *x;
      if (!xzeroed->n || h_has (xzeroed, first)) {
        for (i = 0; i < xpending->n; i++) h_set (xdatadef, xpending->v[i], 1);
        for (i = 1; i < xpending->n; i++) v_push (fns, alias_of (xpending->v[i], first));
      }
      x = s_of ("s2ff: "); s_app (x, where); s_cat (x, ": "); s_app (x, first); s_cat (x, " is zero, c2ff --zero "); s_app (x, first); s_cat (x, " makes it\n");
      e_s (x);
      xpending = v_new ();
      return;
    }
    { struct str *x = s_of ("bytes in "); s_app (x, xother); s_cat (x, ": "); s_app (x, st); fail_s (x); }
  }
  while (m (st, "^([.\\w\\$]+):\\s*")) {
    struct str *name = kwname (g (1)), *x;
    st = s_sub (st, rc[1], st->n);
    if (m (name, "^\\d+$")) {
      long c = h_iv (xnumeric, name) + 1;
      h_set (xnumeric, name, c);
      x = s_of (".L"); s_app (x, name); s_cat (x, " "); s_app (x, s_num (c));
      name = x;
    }
    if (m (name, "^\\.L")) {
      if (!fn) { x = s_of ("a label outside a function: "); s_app (x, name); fail_s (x); }
      x = s_dup (name); s_cat (x, ":");
      block = nd_new (x);
      nd_add (fn, block);
    } else if (fn && !xends) {
      struct str *cm = s_of ("glibc-2.44 ");
      s_app (cm, file); s_cat (cm, ":"); s_app (cm, s_num (lineno));
      x = s_dup (name); s_cat (x, ":");
      block = nd2 (x, ndc ("asm"), nd1 (s_of ("comment"), nd_new (cm)));
      nd_add (fn, block);
      xalign_def = 0;
    } else {
      struct str *cm = s_of ("glibc-2.44 ");
      xfinish ();
      s_app (cm, file); s_cat (cm, ":"); s_app (cm, s_num (lineno));
      x = s_dup (name); s_cat (x, ":");
      fn = nd1 (x, ndc ("asm"));
      if (xalign_def) nd_add (fn, nd1 (s_of ("align"), LN (xalign)));
      nd_add (fn, nd1 (s_of ("comment"), nd_new (cm)));
      v_push (fns, fn);
      block = 0;
      xalign_def = 0;
      xends = 0;
    }
  }
  if (st->n == 0) return;
  if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$") || m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*([.\\w]+)$")) { struct str *a = g (1), *b = g (2); v_push (fns, alias_of (a, b)); return; }
  m (st, "^(\\S+)\\s*(.*)$");
  op = g (1); rest = g (2);
  if (op->p[0] == '.') {
    if (m (op, "^\\.(p2align|align|balign)$")) {
      struct vec *a = x_split_ops (rest);
      long x, alv, mx = 0, fl = 0;
      int hm = 0, hf = 0;
      if (!xnum (a->n ? a->v[0] : 0, &x)) { struct str *y = s_dup (op); s_cat (y, " of "); if (a->n) s_app (y, a->v[0]); fail_s (y); }
      alv = s_is (op, ".p2align") ? (long) ushl (1, x) : x;
      if (a->n > 2 && ((struct str *) a->v[2])->n) { hm = xnum (a->v[2], &mx); }
      if (a->n > 1 && ((struct str *) a->v[1])->n) { hf = xnum (a->v[1], &fl); }
      xpad (alv, mx, hm, fl, hf);
      xalign = alv; xalign_def = 1;
      return;
    }
    if (m (op, "^\\.(globl|global|weak|hidden|protected|type|size|cfi_\\w+|loc|file|ident|code64|att_syntax)$")) return;
    fail2 ("a directive with no ff form: ", st);
  }
  xalign_def = 0;
  if (!fn) fail2 ("an instruction outside a function: ", st);
  op = s_lc (op);
  while (is_prefix (op)) {
    v_push (xprefixes, op);
    if (rest->n == 0) return;
    m (rest, "^(\\S+)\\s*(.*)$");
    op = s_lc (g0 (1)); rest = g0 (2);
  }
  ops = x_split_ops (rest);
  for (i = 0; i < ops->n; i++) {
    struct str *x = ops->v[i];
    if (mf (x, "^(\\*?)([.\\w]+)@GOTPCREL\\(%rip\\)$", "i")) {
      struct str *star = g (1), *sy = g (2), *y = s_dup (star);
      h_set (xgot, sy, 1);
      s_cat (y, ".Lgot"); s_chr (y, 1); s_app (y, sy); s_cat (y, "(%rip)");
      ops->v[i] = x = y;
    } else if (mf (x, "^([.\\w]+)@GOTTPOFF\\(%rip\\)$", "i")) {
      struct str *sy = g (1), *y = s_of (".Ltls");
      h_set (xtls, sy, 1);
      s_chr (y, 1); s_app (y, sy); s_cat (y, "(%rip)");
      ops->v[i] = x = y;
    } else if (m (op, "^(?:call|jmp)q?$") && mf (x, "^([.\\w]+)@PLT$", "i")) ops->v[i] = x = g (1);
    else if (m (x, "@")) fail2 ("a relocation with no ff form: ", x);
    if (m (x, "^([.\\w]+)(?:[-+]\\d+)?\\(%rip\\)$") || m (x, "^\\$(\\.L\\w+)$")) h_set (xro, g (1), 1);
  }
  mm = xtake ();
  pre = v_new ();
  for (i = 0; i < xprefixes->n; i++) v_push (pre, xprefixes->v[i]);
  xprefixes = v_new ();
  nodes = v_new ();
  translate (op, ops, mm->b, mm->nb, mm->asm_, pre, nodes);
  for (i = 0; i < nodes->n; i++) nd_add (xinto_ (), nodes->v[i]);
  xends = m (((struct nd *) nodes->v[nodes->n - 1])->c, "^(ret|jmp|ud2|hlt)(\\.|$)") ? 1 : 0;
}

/* the lines of the source, GNU's macros expanded */
struct xmacro { struct vec *pn, *pd; struct vec *body; };
static struct vec *wl_body (struct vec *src, long *i, char *open, char *close)
{
  struct vec *b = v_new ();
  long nest = 0;
  while (*i < src->n) {
    struct sline *x = src->v[(*i)++];
    if (mdyn (x->l, s_join (s_of ("^\\s*"), "", s_of (open)), "")) nest++;
    if (mdyn (x->l, s_join (s_of ("^\\s*"), "", s_of (close)), "")) { if (!nest) return b; nest--; }
    v_push (b, x);
  }
  { struct str *x = s_of ("no "); s_cat (x, close); fail_s (x); }
  return 0;
}
static void walk_lines (struct vec *src, long depth)
{
  long i = 0;
  struct vec *cond = v_new ();   /* each .if: taking, taken, the outer one taking */
  if (depth > 50) fail_c ("macros nested past 50");
  while (i < src->n) {
    struct sline *sln = src->v[i++];
    struct str *l = sln->l, *t;
    int off;
    struct vec *sts;
    long sx;
    where = s_dup (sln->file); s_cat (where, ":"); s_app (where, s_num (sln->lineno));
    t = s_trim (l);
    off = cond->n && !((long *) cond->v[cond->n - 1])[0];
    if (mf (t, "^\\.macro\\s+([\\w.]+)\\s*,?\\s*(.*)$", "i")) {
      struct str *name = g (1), *args = g (2);
      struct vec *b = wl_body (src, &i, "\\.macro\\b", "\\.endm\\b");
      if (!off) {
        struct xmacro *mc = alloc (sizeof (struct xmacro));
        struct vec *as = ssplit ("[\\s,]+", args, 0);
        long k;
        mc->pn = v_new (); mc->pd = v_new (); mc->body = b;
        for (k = 0; k < as->n; k++) {
          struct str *a = as->v[k];
          long e = 0;
          if (!a->n) continue;
          while (e < a->n && a->p[e] != '=') e++;
          v_push (mc->pn, s_sub (a, 0, e));
          v_push (mc->pd, e < a->n ? s_sub (a, e + 1, a->n) : 0);
        }
        h_setp (xmacro, s_lc (name), mc);
      }
      continue;
    }
    if (m (t, "^\\.rept\\s+(.*)$")) {
      struct str *count = g (1);
      struct vec *b = wl_body (src, &i, "\\.(?:rept|irp|irpc)\\b", "\\.endr\\b");
      long c, k;
      if (off) continue;
      if (!xnum (count, &c)) { struct str *x = s_of (".rept of "); s_app (x, count); fail_s (x); }
      for (k = 0; k < c; k++) walk_lines (b, depth + 1);
      continue;
    }
    if (m (t, "^\\.if(eq|ne|gt|ge|lt|le)?\\s+(.*)$")) {
      struct str *k = g0 (1), *e = g (2);
      long v = 0, *c = alloc (3 * sizeof (long));
      int take;
      if (!off && !xnum (e, &v)) { struct str *x = s_of (".if of "); s_app (x, e); fail_s (x); }
      take = k->n == 0 || s_is (k, "ne") ? v != 0 : s_is (k, "eq") ? v == 0 : s_is (k, "gt") ? v > 0 : s_is (k, "ge") ? v >= 0 : s_is (k, "lt") ? v < 0 : v <= 0;
      c[0] = !off && take; c[1] = !off && take; c[2] = !off;
      v_push (cond, c);
      continue;
    }
    if (m (t, "^\\.else\\b")) { long *c; if (!cond->n) fail_c (".else with no .if"); c = cond->v[cond->n - 1]; c[0] = c[2] && !c[1]; continue; }
    if (m (t, "^\\.endif\\b")) { if (!cond->n) fail_c (".endif with no .if"); cond->n--; continue; }
    if (off) continue;
    if (m (t, "^\\.err\\b")) fail_c (".err: GNU as stops here");
    sts = ssplit (";", l, 0);
    for (sx = 0; sx < sts->n; sx++) {
      struct str *st = s_trim (sts->v[sx]);
      struct xmacro *mc = 0;
      if (st->n == 0) continue;
      if (m (st, "^([\\w.]+)\\s*(.*)$")) {
        struct str *w = g (1), *rest = g (2);
        mc = h_pv (xmacro, s_lc (w));
        if (mc) {
          struct vec *a = x_split_ops (rest), *x = v_new ();
          struct hash *vals = h_new ();
          long k, q;
          if (a->n == 1 && mc->pn->n > 1) a = ssplit ("\\s+", s_trim (rest), 0);
          for (k = 0; k < mc->pn->n; k++) {
            struct str *v = k < a->n ? a->v[k] : mc->pd->v[k] ? mc->pd->v[k] : s_of ("");
            h_setp (vals, mc->pn->v[k], v);
          }
          for (k = 0; k < mc->body->n; k++) {
            struct sline *b = mc->body->v[k], *y = alloc (sizeof (struct sline));
            struct str *bline = b->l, *o = s_of ("");
            q = 0;
            while (q < bline->n) {
              if (bline->p[q] == '\\' && q + 1 < bline->n && is_word (bline->p[q + 1])) {
                long e = q + 1;
                struct str *nm;
                while (e < bline->n && is_word (bline->p[e])) e++;
                nm = s_sub (bline, q + 1, e);
                if (h_has (vals, nm)) s_app (o, h_pv (vals, nm)); else { s_chr (o, '\\'); s_app (o, nm); }
                q = e;
                continue;
              }
              s_chr (o, bline->p[q]); q++;
            }
            o = ssub (o, "\\\\\\(\\)", "g", "");
            y->l = o; y->file = sln->file; y->lineno = sln->lineno;
            v_push (x, y);
          }
          walk_lines (x, depth + 1);
          continue;
        }
      }
      walk_stmt (st, sln->file, sln->lineno);
    }
  }
  if (cond->n) fail_c (".if with no .endif");
}

/* A function that jumps to a block of the function after it: one asm function */
static void jtargets (struct nd *f, struct vec *t)
{
  long i;
  for (i = 0; i < ndn (f); i++) { struct nd *x = ndk (f, i); if (m (x->c, "^(j[a-z]+|call)(\\.8)?$") && ndn (x)) v_push (t, ndk (x, 0)->c); jtargets (x, t); }
}
static struct hash *dotL_labels (struct nd *f)
{
  struct hash *h = h_new ();
  long i;
  for (i = 0; i < ndn (f); i++) if (m (ndk (f, i)->c, "^\\.L.*:$")) h_set (h, unlabel (ndk (f, i)->c), 1);
  return h;
}
static void merge_runons (void)
{
  long i, j, q;
  for (i = 0; i + 1 < fns->n; i++) {
    struct nd *f = fns->v[i], *gg;
    struct hash *in_g, *in_f;
    struct vec *tf, *tgt2, *rest, *own;
    int hitx = 0;
    if (!isasm (f)) continue;
    for (j = i + 1; j < fns->n && !isasm (fns->v[j]); j++) {}
    if (j >= fns->n) continue;
    gg = fns->v[j];
    in_g = dotL_labels (gg); in_f = dotL_labels (f);
    tf = v_new (); jtargets (f, tf); tgt2 = v_new (); jtargets (gg, tgt2);
    for (q = 0; q < tf->n; q++) if (h_has (in_g, tf->v[q])) hitx = 1;
    for (q = 0; q < tgt2->n; q++) if (h_has (in_f, tgt2->v[q])) hitx = 1;
    if (!hitx) continue;
    rest = v_new ();
    for (q = 0; q < ndn (gg); q++) if (!s_is (ndk (gg, q)->c, "align")) v_push (rest, ndk (gg, q));
    own = v_new ();
    {
      struct nd *x = nd1 (gg->c, ndc ("asm"));
      struct vec *later = v_new ();
      for (q = 1; q < rest->n; q++) {
        struct nd *y = rest->v[q];
        if (later->n || (m (y->c, ":$") && q != 1)) v_push (later, y); else nd_add (x, y);
      }
      nd_add (f, x);
      for (q = 0; q < later->n; q++) nd_add (f, later->v[q]);
    }
    h_setp (xinto, ptr_key (gg), f);
    for (q = j; q + 1 < fns->n; q++) fns->v[q] = fns->v[q + 1];
    fns->n--;
    i = -1;
  }
}
static void carry_rodata (void)
{
  struct hash *labels = h_new ();
  struct vec *order = v_new ();
  long i, j, k;
  for (i = 0; i < xcarry->n; i++) {
    struct carried *c = xcarry->v[i];
    struct nd *f = c->f;
    struct hash *ls;
    while (h_pv (xinto, ptr_key (f))) f = h_pv (xinto, ptr_key (f));
    ls = h_pv (labels, ptr_key (f));
    if (!ls) { ls = h_new (); h_setp (labels, ptr_key (f), ls); v_push (order, f); }
    for (j = 0; j < c->nodes->n; j++) h_set (ls, c->nodes->v[j], 1);
  }
  for (i = 0; i < order->n; i++) {
    struct nd *f = order->v[i];
    struct vec *lb = h_sorted (h_pv (labels, ptr_key (f))), *l = v_new ();
    struct hash *first = h_new ();
    struct vec *fk;
    for (j = 0; j < lb->n; j++) rodata_set (lb->v[j]);
    for (j = 0; j < lb->n; j++) if (h_pv (xrodata, lb->v[j])) v_push (l, lb->v[j]);
    if (!l->n) continue;
    for (j = 0; j < l->n; j++) {
      struct str *x = l->v[j];
      long ri = h_iv (xrunof, x), q;
      struct vec *r;
      if (!ri) continue;
      r = xruns->v[ri - 1];
      for (q = 0; q < r->n; q++) {
        struct runent *e = r->v[q];
        long z, found2 = 0;
        for (z = 0; z < e->names->n; z++) if (s_eq (e->names->v[z], x)) found2 = 1;
        if (found2) break;
      }
      { struct str *key = s_num (ri - 1); if (!h_has (first, key) || q < h_iv (first, key)) h_set (first, key, q); }
    }
    fk = v_new ();
    for (j = 0; j < first->keys->n; j++) v_push (fk, ((struct hent *) first->keys->v[j])->k);
    /* sorted as numbers */
    for (j = 1; j < fk->n; j++) for (k = j; k > 0 && dec (fk->v[k - 1]) > dec (fk->v[k]); k--) { void *t = fk->v[k]; fk->v[k] = fk->v[k - 1]; fk->v[k - 1] = t; }
    for (j = 0; j < fk->n; j++) {
      struct vec *r = xruns->v[dec (fk->v[j])];
      long st = h_iv (first, fk->v[j]), alv = 16, q;
      for (q = st; q < r->n; q++) { struct runent *e = r->v[q]; if ((e->has_align ? e->align : 0) > alv) alv = e->align; }
      nd_add (f, nd1 (s_of ("align"), LN (alv)));
      for (q = st; q < r->n; q++) {
        struct runent *e = r->v[q];
        long z;
        struct nd *last;
        struct str *x;
        if (q > st && (e->has_align ? e->align : 1) > 1) nd_add (f, nd1 (s_of ("align"), LN (e->align)));
        for (z = 0; z + 1 < e->names->n; z++) { x = s_dup (e->names->v[z]); s_cat (x, ":"); nd_add (f, nd_new (x)); }
        x = s_dup (e->names->v[e->names->n - 1]); s_cat (x, ":");
        last = nd_new (x);
        for (z = 0; z < e->bytes->n; z++) nd_add (last, e->bytes->v[z]);
        nd_add (f, last);
      }
    }
    for (j = 0; j < l->n; j++) {
      struct str *x = l->v[j], *y;
      struct vec *b;
      struct nd *n2;
      long z;
      if (h_iv (xrunof, x)) continue;
      nd_add (f, nd1 (s_of ("align"), ndc ("16")));
      y = s_dup (x); s_cat (y, ":");
      n2 = nd_new (y);
      b = h_pv (xrodata, x);
      for (z = 0; z < b->n; z++) nd_add (n2, b->v[z]);
      nd_add (f, n2);
    }
  }
}

/* run: the ff of src and dump (mode 0), or its size (1) or first alignment (2) */
static long x86_facts_size, x86_facts_align;
static long x86_run (int mode, struct str *src, struct str *dump, struct vec *zerov, struct vec *then)
{
  long i;
  x86_load ();
  where = src;
  xMADE = read_dump_x (dump);
  xCODE = h_new ();
  xcode_ = 0;
  xn = 0; xpos = 0; xends = 1; xmaxalign_def = 0; fn = 0; block = 0; xother = 0; xalign_def = 0;
  fns = v_new (); xpending = v_new (); xdatadef = h_new (); xnumeric = h_new (); xgot = h_new (); xtls = h_new (); xmacro = h_new ();
  xsections = v_new (); xprefixes = v_new (); xrodata = h_new (); xro = h_new (); xcarry = v_new (); xroset = h_new (); xweak = h_new ();
  xcarried = v_new (); xweakgot = h_new (); xruns = v_new (); xrunof = h_new (); xrunidx = h_new (); xinto = h_new ();
  xroalign_def = 0;
  xzeroed = h_new ();
  for (i = 0; i < zerov->n; i++) h_set (xzeroed, zerov->v[i], 1);
  xroblob = 0;
  code_to (s_of (".text"));
  walk_lines (read_src_x (src), 0);
  xfinish ();
  code_done ();
  if (then->n) {
    struct hash *more = read_dump_x (then->n > 1 ? then->v[1] : s_of (""));
    struct vec *k;
    where = then->v[0];
    code_to (xcode_);
    k = v_new ();
    for (i = 0; i < xCODE->keys->n; i++) v_push (k, ((struct hent *) xCODE->keys->v[i])->k);
    for (i = 0; i < k->n; i++) {
      struct xcode *o = h_pv (xCODE, k->v[i]), *c = alloc (sizeof (struct xcode));
      c->made = h_pv (more, k->v[i]) ? h_pv (more, k->v[i]) : v_new ();
      c->fn = o->fn; c->block = o->block; c->ends = 0;
      h_setp (xCODE, k->v[i], c);
    }
    for (i = 0; i < more->keys->n; i++) {
      struct str *s = ((struct hent *) more->keys->v[i])->k;
      if (!h_pv (xCODE, s)) { struct xcode *c = alloc (sizeof (struct xcode)); c->made = h_pv (more, s); c->ends = 1; h_setp (xCODE, s, c); }
    }
    xcode_ = 0;
    xother = 0; xsections = v_new ();
    code_to (s_of (".text"));
    xMADE = more;
    walk_lines (read_src_x (then->v[0]), 0);
    xfinish ();
    code_done ();
  }
  for (i = 0; i < xcarried->n; i++) { struct carried *c = xcarried->v[i]; long j; for (j = 0; j < c->nodes->n; j++) nd_add (c->f, c->nodes->v[j]); }
  {
    struct hash *defined = h_new ();
    struct vec *k = h_sorted (xweak);
    for (i = 0; i < fns->n; i++) h_set (defined, unlabel (((struct nd *) fns->v[i])->c), 1);
    for (i = 0; i < k->n; i++) {
      struct str *w = k->v[i], *x;
      if (h_has (defined, w) || m (w, "^DW\\.ref\\.")) continue;
      x = s_dup (w); s_cat (x, ":");
      v_push (fns, nd_add (nd2 (x, ndc ("weak"), ndc ("function")), ndc ("void")));
    }
    k = h_sorted (xweakgot);
    for (i = 0; i < k->n; i++) { struct str *x = s_of (".Lgot "); s_app (x, k->v[i]); s_cat (x, ":"); v_push (fns, nd_add (nd_add (nd_add (nd1 (x, ndc ("void")), nd_new (w_ptr ())), nd_new (k->v[i])), nd_new (w_addr ()))); }
  }
  if (xprefixes->n) { struct str *x = s_of ("a prefix with no instruction after it:"); for (i = 0; i < xprefixes->n; i++) { s_cat (x, " "); s_app (x, xprefixes->v[i]); } fail_s (x); }
  {
    struct nd *first = 0;
    for (i = 0; i < fns->n && !first; i++) if (isasm (fns->v[i])) first = fns->v[i];
    if (first && xmaxalign_def && xmaxalign > 1) {
      if (ndn (first) > 1 && s_is (ndk (first, 1)->c, "align")) ndk (ndk (first, 1), 0)->c = s_num (xmaxalign);
      else {
        struct nd *a = nd1 (s_of ("align"), LN (xmaxalign));
        long j;
        v_push (first->k, 0);
        for (j = ndn (first) - 1; j > 1; j--) first->k->v[j] = first->k->v[j - 1];
        first->k->v[1] = a;
      }
    }
  }
  x86_facts_size = ((struct xcode *) h_pv (xCODE, s_of (".text")))->pos;
  x86_facts_align = xmaxalign_def ? xmaxalign : 1;
  if (mode == 1) return x86_facts_size;
  if (mode == 2) return x86_facts_align;
  merge_runons ();
  carry_rodata ();
  return 0;
}

static void x86_init (void)
{
  char *pn = "rep repe repz repne repnz lock data16 notrack addr32 cs ds fs gs";
  long pb[13], i = 0, k = 0;
  pb[0] = 0xf3; pb[1] = 0xf3; pb[2] = 0xf3; pb[3] = 0xf2; pb[4] = 0xf2; pb[5] = 0xf0; pb[6] = 0x66; pb[7] = 0x3e; pb[8] = 0x67; pb[9] = 0x2e; pb[10] = 0x3e; pb[11] = 0x64; pb[12] = 0x65;
  xprefix = h_new ();
  while (k < 13) { long a = i; while (pn[i] && pn[i] != ' ') i++; h_set (xprefix, s_new ((unsigned char *) pn + a, i - a), pb[k++]); if (pn[i]) i++; }
  xalias = h_new ();
  h_setp (xalias, s_of ("retq"), s_of ("ret")); h_setp (xalias, s_of ("jmpq"), s_of ("jmp")); h_setp (xalias, s_of ("callq"), s_of ("call"));
  h_setp (xalias, s_of ("sal"), s_of ("shl")); h_setp (xalias, s_of ("salb"), s_of ("shlb")); h_setp (xalias, s_of ("salw"), s_of ("shlw"));
  h_setp (xalias, s_of ("sall"), s_of ("shll")); h_setp (xalias, s_of ("salq"), s_of ("shlq"));
  xops = h_words ("sub add addi slli srli srai andi ori xori or and xor bits srl sra sll");
  xkw = h_words ("syscall if else while for return break continue comment switch case default goto array struct union enum function sizeof alignof alias ifunc asm items cast weak section constructor destructor");
  pbs = h_new ();
  xregs_init ();
}

/* ---- decimal to double, as Perl's atof (the nearest, ties to even) and that double to a float */
/* big numbers: little-endian 32-bit limbs */
struct bn { unsigned long d[80]; long n; };
static void bn_set (struct bn *a, unsigned long v) { a->n = 0; while (v) { a->d[a->n++] = v & 0xffffffff; v = v >> 32; } }
static void bn_mul (struct bn *a, unsigned long k) { unsigned long c = 0; long i; for (i = 0; i < a->n; i++) { unsigned long x = a->d[i] * k + c; a->d[i] = x & 0xffffffff; c = x >> 32; } while (c) { a->d[a->n++] = c & 0xffffffff; c = c >> 32; } }
static void bn_add (struct bn *a, unsigned long k) { long i = 0; unsigned long c = k; while (c) { if (i == a->n) a->d[a->n++] = 0; c += a->d[i]; a->d[i] = c & 0xffffffff; c = c >> 32; i++; } }
static int bn_cmp (struct bn *a, struct bn *b) { long i; if (a->n != b->n) return a->n < b->n ? -1 : 1; for (i = a->n - 1; i >= 0; i--) if (a->d[i] != b->d[i]) return a->d[i] < b->d[i] ? -1 : 1; return 0; }
static void bn_sub (struct bn *a, struct bn *b) { long i; unsigned long br = 0; for (i = 0; i < a->n; i++) { unsigned long y = (i < b->n ? b->d[i] : 0) + br; if (a->d[i] >= y) { a->d[i] -= y; br = 0; } else { a->d[i] = a->d[i] + 4294967296UL - y; br = 1; } } while (a->n && !a->d[a->n - 1]) a->n--; }
static void bn_shl1 (struct bn *a) { bn_mul (a, 2); }
static unsigned long dbl_bits (struct str *t)
{
  struct bn num_, den, q;
  long i = 0, exp10 = 0, e2 = 0, k;
  int neg = 0;
  unsigned long mant = 0;
  if (i < t->n && (t->p[i] == '-' || t->p[i] == '+')) { neg = t->p[i] == '-'; i++; }
  bn_set (&num_, 0);
  while (i < t->n && is_digit (t->p[i])) { bn_mul (&num_, 10); bn_add (&num_, t->p[i] - '0'); i++; }
  if (i < t->n && t->p[i] == '.') { i++; while (i < t->n && is_digit (t->p[i])) { bn_mul (&num_, 10); bn_add (&num_, t->p[i] - '0'); exp10--; i++; } }
  if (i < t->n && (t->p[i] == 'e' || t->p[i] == 'E')) {
    int en = 0; long ev = 0;
    i++;
    if (i < t->n && (t->p[i] == '-' || t->p[i] == '+')) { en = t->p[i] == '-'; i++; }
    while (i < t->n && is_digit (t->p[i])) { ev = ev * 10 + t->p[i] - '0'; i++; }
    exp10 += en ? -ev : ev;
  }
  if (!num_.n) return neg ? (unsigned long) 1 << 63 : 0;
  bn_set (&den, 1);
  if (exp10 > 0) for (k = 0; k < exp10; k++) bn_mul (&num_, 10);
  else for (k = 0; k < -exp10; k++) bn_mul (&den, 10);
  /* scale so that 2^53 <= num/den < 2^54 */
  {
    struct bn tmp1;
    for (;;) {
      tmp1 = den; for (k = 0; k < 54; k++) bn_shl1 (&tmp1);
      if (bn_cmp (&num_, &tmp1) >= 0) { bn_shl1 (&den); e2++; continue; }
      tmp1 = den; for (k = 0; k < 53; k++) bn_shl1 (&tmp1);
      if (bn_cmp (&num_, &tmp1) < 0) { bn_shl1 (&num_); e2--; continue; }
      break;
    }
  }
  /* q = num / den, by bits */
  bn_set (&q, 0);
  {
    struct bn r = num_, dsh;
    for (k = 53; k >= 0; k--) {
      long z;
      dsh = den; for (z = 0; z < k; z++) bn_shl1 (&dsh);
      if (bn_cmp (&r, &dsh) >= 0) { bn_sub (&r, &dsh); mant |= (unsigned long) 1 << k; }
    }
    /* the 54th bit is the rounding bit: mant has 54 bits; half and the rest */
    {
      int halfv = (int) (mant & 1), more = r.n != 0;
      mant = mant >> 1; e2++;
      if (halfv && (more || (mant & 1))) mant++;
      if (mant >> 53) { mant = mant >> 1; e2++; }
    }
  }
  /* the value mant * 2^e2, mant of 53 bits */
  {
    long be = e2 + 52 + 1023;
    if (be <= 0 || be >= 2047) return 0;   /* (no denormals or infinities here) */
    return (neg ? (unsigned long) 1 << 63 : 0) | (unsigned long) be << 52 | (mant & (((unsigned long) 1 << 52) - 1));
  }
}
static unsigned long flt_bits (unsigned long d)
{
  unsigned long sign = d >> 63, mant = d & (((unsigned long) 1 << 52) - 1), r;
  long be = (long) ((d >> 52) & 2047), fe;
  if (be == 0) return sign << 31;
  fe = be - 1023 + 127;
  if (fe <= 0 || fe >= 255) return sign << 31 | (fe >= 255 ? 0x7f800000UL : 0);
  r = mant >> 29;
  {
    unsigned long rest = mant & ((1UL << 29) - 1), halfv = 1UL << 28;
    if (rest > halfv || (rest == halfv && (r & 1))) r++;
    if (r >> 23) { r = 0; fe++; }
  }
  return sign << 31 | (unsigned long) fe << 23 | r;
}

/* s2ff.pl's x86_64 arm: --size, --align, else the ff */
static void x86_main (void)
{
  if (o_size || o_align) {
    long v = x86_run (o_size ? 1 : 2, src_s, dump_s, zero_v, then_v);
    o_s (s_num (v)); o_str ("\n"); o_flush (); cp_exit (0);
  }
  x86_run (0, src_s, dump_s, zero_v, then_v);
  { struct str *x = s_of ("size "); s_app (x, s_num (x86_facts_size)); s_cat (x, "\nalign "); s_app (x, s_num (x86_facts_align)); s_cat (x, "\n"); facts_write (x); }
  if (o_items) o_s (write_txt (fns));
  else {
    struct str *pg = s_dup (page);
    struct nd *top;
    struct vec *one = v_new (), *lic;
    long i;
    s_cat (pg, ":");
    top = nd_new (pg);
    v_push (one, src_s);
    lic = license_nodes (one);
    for (i = 0; i < lic->n; i++) nd_add (top, lic->v[i]);
    for (i = 0; i < fns->n; i++) nd_add (top, fns->v[i]);
    one = v_new (); v_push (one, top);
    o_s (write_txt (one));
  }
  o_flush ();
}
