/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */


static struct cs_ex *cl_p (struct cs_ex *e)
{
  while (e->paren > 0) {
    struct cs_ex *w = cs_mk (E_PAREN, e->t, e->lv);
    e->paren = e->paren - 1;
    w->paren = e->paren;
    e->paren = 0;
    cs_add (w, e);
    e = w;
  }
  return e;
}

static struct cs_ex *cl_k (struct cs_ex *e, long i) { e->kid[i] = cl_p (e->kid[i]); return e->kid[i]; }
static struct cs_ex *cl_strip (struct cs_ex *n) { while (n->k == E_ICE || n->k == E_CONST) n = cl_k (n, 0); return n; }
static int cl_name_is (struct cs_ex *e, char *s) { return e->name && same (e->name, e->nlen, s); }
static char *cl_name_of (struct cs_ex *e) { return cl_copy (e->name, e->nlen); }
static void cl_expr (struct cs_ex *n, struct cl_list *o);
static void cl_body (struct cs_st *cs, struct cl_list *o);
static void cl_stmt (struct cs_st *n, struct cl_list *o);
static struct node *cl_decl (struct cs_decl *v, int global, char *name);
static struct cl_list *cl_ex (struct cs_ex *e) { struct cl_list *l = cl_l (); cl_expr (e, l); return l; }
static int cl_isop (char *s)
{
  static char *ops[] = { "=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>=", "||", "&&", "|", "^", "&", "==", "!=", "<", ">", "<=", ">=", "<<", ">>", "+", "-", "*", "/", "%", "!", "~", "++", "--", 0 };
  long i = 0;
  while (ops[i]) { if (cl_eq (s, ops[i])) return 1; i++; }
  return 0;
}

static int cl_prec (char *s)
{
  if (s[0] && cl_ends (s, "=") && !cl_eq (s, "==") && !cl_eq (s, "!=") && !cl_eq (s, "<=") && !cl_eq (s, ">=")) return 2;
  if (cl_eq (s, "||")) return 4;
  if (cl_eq (s, "&&")) return 6;
  if (cl_eq (s, "|")) return 8;
  if (cl_eq (s, "^")) return 10;
  if (cl_eq (s, "&")) return 12;
  if (cl_eq (s, "==") || cl_eq (s, "!=")) return 14;
  if (cl_eq (s, "<") || cl_eq (s, ">") || cl_eq (s, "<=") || cl_eq (s, ">=")) return 16;
  if (cl_eq (s, "<<") || cl_eq (s, ">>")) return 18;
  if (cl_eq (s, "+") || cl_eq (s, "-")) return 20;
  if (cl_eq (s, "*") || cl_eq (s, "/") || cl_eq (s, "%")) return 22;
  return 0;
}
static int cl_scalar_word (char *s)
{
  static char *w[] = { "char", "i8", "u8", "short", "u16", "int", "u32", "long", "u64", "float", "double", "long double", "i64", "i128", "u128", "float16", "bfloat16", "complex float16", "void", "va_list", "complex float", "complex double", "complex long double", "address", "array", 0 };
  long i = 0;
  while (w[i]) { if (cl_eq (s, w[i])) return 1; i++; }
  return C->target == 1 && cl_eq (s, "float128");
}

static void cl_item (struct cl_list *l, struct cl_list *o)
{
  if (l->n && cl_isop ((char *) l->v[0]->text) && !l->v[0]->count) { cl_push (o, cl_nl (":", l)); return; }
  cl_append (o, l);
}
static void cl_itemx (struct cs_ex *e, struct cl_list *o) { cl_item (cl_ex (e), o); }
static struct node *cl_one (struct cl_list *l) { if (l->n == 1) return l->v[0]; return cl_nl (":", l); }
static struct node *cl_atom (struct cs_ex *e) { return cl_one (cl_ex (e)); }

static char *cl_tword (struct cs_ex *e) { return cl_tword_t (e->t); }
static int cl_isq (struct cs_ex *e) { return cl_eq (cl_tword (e), cl_q128 ()); }
static int cl_isld (struct cs_ex *e) { return cl_eq (cl_tword (e), "long double"); }
static void cl_fty (char *t, long *p, long long *emin, long long *emax, char **suf, char **sp)
{
  if (cl_eq (t, "float")) { *p = 24; *emin = -149; *emax = 127; *suf = "f"; *sp = "128f"; }
  else if (cl_eq (t, "double")) { *p = 53; *emin = -1074; *emax = 1023; *suf = ""; *sp = "1024"; }
  else if (cl_eq (t, "long double")) {
    if (C->target == 1) { *p = 64; *emin = -16445; } else { *p = 113; *emin = -16494; }
    *emax = 16383; *suf = "L"; *sp = "16384L";
  }
  else { *p = 113; *emin = -16494; *emax = 16383; *suf = "Q"; *sp = "16384Q"; }
}
static int cl_ftyp (char *t) { return t[0] != 0; }

static char *cl_lit_text (struct cs_ex *e)
{
  struct cs_buf b;
  cs_b_init (&b);
  cs_tok_bytes (e->src, &b);
  return cl_copy (b.p, b.n);
}
static char *cl_with_suffix (char *lit, char *suf)
{

  long n = cstrlen (lit);
  char *r = cl_copy ((unsigned char *) lit, n - 1);
  return cl_cat (r, suf);
}
static char *cl_hexfloat_of (struct cl_big *n, struct cl_big *d, char *tw)
{
  int isf = cl_eq (tw, "float");
  long p = isf ? 24 : 53, m = p - 1, digits = (m + 3) / 4;
  long long emin = isf ? 0 - 149 : 0 - 1074, ex, e2;
  struct cl_big *q;
  struct cs_buf b;
  char *hex;
  int lead;
  char *suf = cs_pick (isf, "f", "");
  if (cl_big_zero (n)) return cl_cat ("0x0p+0", suf);
  q = cl_ratq (n, d, p, emin, &e2);
  if (cl_big_bits (q) == p) {
    lead = 1;
    ex = e2 + m;
    q = cl_big_sub (q, cl_big_shl (cl_big_small (1), m));
    if (ex > (isf ? 127 : 1023)) cl_fail ("a constant with no hex form", 0);
  } else {
    lead = 0;
    ex = isf ? 0 - 126 : 0 - 1022;
  }
  hex = cl_hexdigits (cl_big_shl (q, 4 * digits - m), digits);
  cs_b_init (&b);
  cs_b_str (&b, "0x");
  cs_b_ll (&b, lead);
  if (hex[0]) { cs_b_byte (&b, '.'); cs_b_str (&b, hex); }
  cs_b_byte (&b, 'p');
  if (ex >= 0) cs_b_byte (&b, '+');
  cs_b_ll (&b, ex);
  cs_b_str (&b, suf);
  return cl_copy (b.p, b.n);
}
static char *cl_hexfloat (struct cs_ex *e)
{
  struct cl_big *n, *d;
  char *tw = cl_tword (e);
  if (!cl_eq (tw, "float") && !cl_eq (tw, "double")) cl_fail ("a constant of that type", 0);
  cl_lit_ratio (cl_lit_text (e), &n, &d);
  return cl_hexfloat_of (n, d, tw);
}
static char *cl_ldhexfloat (char *s)
{
  char *r;
  if (C->target == 3) r = cl_ldround (s, 53, -1074, 1023);
  else if (C->target == 1) r = cl_ldround (s, 64, -16445, 16383);
  else r = cl_ldround (s, 113, -16494, 16383);
  if (!r) cl_fail ("a long double literal past the largest", 0);
  return r;
}

static int cl_ldinside (struct cs_ex *n)
{
  long i = 0;
  char *t = cl_tword (n);
  if (cl_eq (t, "long double") || cl_eq (t, "float128")) return 1;
  while (i < n->nk) { if (cl_ldinside (n->kid[i])) return 1; i++; }
  return 0;
}
static struct cl_fv *cl_fv_new (int kind, int neg) { struct cl_fv *v = alloc (sizeof (struct cl_fv)); v->kind = kind; v->neg = neg; v->q = cl_big_small (0); return v; }
static struct cl_fv *cl_fround (struct cl_fv *v, char *t)
{
  long p;
  long long emin, emax, e;
  char *suf, *sp;
  struct cl_big *n, *d, *q;
  struct cl_fv *r;
  if (!v || !cl_ftyp (t)) return 0;
  if (v->kind != 0 || cl_big_zero (v->q)) return v;
  cl_fty (t, &p, &emin, &emax, &suf, &sp);
  if (v->e >= 0) { n = cl_big_shl (v->q, v->e); d = cl_big_small (1); } else { n = v->q; d = cl_big_shl (cl_big_small (1), 0 - v->e); }
  q = cl_ratq (n, d, p, emin, &e);
  if (!cl_big_zero (q) && e + cl_big_bits (q) - 1 > emax) return cl_fv_new (1, v->neg);
  r = cl_fv_new (0, v->neg);
  r->q = q;
  r->e = e;
  return r;
}
static struct cs_ex *cl_unwrap_ice (struct cs_ex *s) { while (s->k == E_ICE || s->k == E_PAREN) s = cl_k (s, 0); return s; }
static int cl_str_empty (struct cs_ex *s);
static struct cl_fv *cl_fold (struct cs_ex *n)
{
  int k = n->k;
  if ((k == E_PAREN || k == E_CONST) && n->nk == 1) return cl_fold (cl_k (n, 0));
  if (k == E_FLT) {
    struct cl_big *nn, *dd, *q;
    long p;
    long long emin, emax, e;
    char *suf, *sp, *t = cl_tword (n);
    struct cl_fv *r;
    cl_lit_ratio (cl_lit_text (n), &nn, &dd);
    if (cl_big_zero (nn)) return cl_fv_new (0, 0);
    if (!cl_ftyp (t)) return 0;
    cl_fty (t, &p, &emin, &emax, &suf, &sp);
    q = cl_ratq (nn, dd, p, emin, &e);
    if (!cl_big_zero (q) && e + cl_big_bits (q) - 1 > emax) return cl_fv_new (1, 0);
    r = cl_fv_new (0, 0);
    r->q = q;
    r->e = e;
    return r;
  }
  if (k == E_INT) { struct cl_fv *r = cl_fv_new (0, 0); r->q = cl_big_small ((unsigned long long) n->val); return r; }
  if (k == E_CALL) {
    struct cs_ex *f = cl_unwrap_ice (cl_k (n, 0));
    char *name = "";
    if (f->k == E_REF && f->d) name = cl_dn (f->d);
    if (n->nk == 1 && (cl_eq (name, "__builtin_huge_val") || cl_eq (name, "__builtin_huge_valf") || cl_eq (name, "__builtin_huge_vall") || cl_eq (name, "__builtin_inf") || cl_eq (name, "__builtin_inff") || cl_eq (name, "__builtin_infl"))) return cl_fv_new (1, 0);
    if (n->nk == 2 && (cl_eq (name, "__builtin_nan") || cl_eq (name, "__builtin_nanf") || cl_eq (name, "__builtin_nanl"))) {
      struct cs_ex *s = cl_unwrap_ice (cl_k (n, 1));
      if (s->k == E_STR && cl_str_empty (s)) return cl_fv_new (2, 0);
    }
    return 0;
  }
  if (k == E_ICE || k == E_CAST) {
    struct cl_fv *v;
    if (!(n->op == CK_FLOATINGCAST || n->op == CK_INTEGRALTOFLOATING || n->op == CK_NOOP) || n->nk != 1) return 0;
    v = cl_fold (cl_k (n, 0));
    if (n->op == CK_NOOP) return v;
    return cl_fround (v, cl_tword (n));
  }
  if (k == E_UN && n->nk == 1 && (cl_name_is (n, "-") || cl_name_is (n, "+"))) {
    struct cl_fv *v = cl_fold (cl_k (n, 0)), *f;
    if (!v) return 0;
    if (cl_name_is (n, "+")) return v;
    f = alloc (sizeof (struct cl_fv));
    *f = *v;
    f->neg = !v->neg;
    return f;
  }
  if (k == E_BIN && n->nk == 2 && (cl_name_is (n, "-") || cl_name_is (n, "+"))) {
    struct cl_fv *a = cl_fold (cl_k (n, 0)), *b = cl_fold (cl_k (n, 1));
    long long e;
    struct cl_big *x, *y, *z;
    int zneg;
    if (!a || !b || !cl_ftyp (cl_tword (n))) return 0;
    if (cl_name_is (n, "-")) { struct cl_fv *f = alloc (sizeof (struct cl_fv)); *f = *b; f->neg = !b->neg; b = f; }
    if (a->kind == 2) return a;
    if (b->kind == 2) return b;
    if (a->kind == 1 || b->kind == 1) {
      if (a->kind == 1 && b->kind == 1 && a->neg != b->neg) return cl_fv_new (2, 0);
      if (a->kind == 1) return a;
      return b;
    }
    e = a->e < b->e ? a->e : b->e;
    x = cl_big_shl (a->q, a->e - e);
    y = cl_big_shl (b->q, b->e - e);
    if (a->neg == b->neg) { z = cl_big_add (x, y); zneg = a->neg; }
    else if (cl_big_cmp (x, y) >= 0) { z = cl_big_sub (x, y); zneg = a->neg; }
    else { z = cl_big_sub (y, x); zneg = b->neg; }
    if (cl_big_zero (z)) return cl_fv_new (0, a->neg && b->neg);
    {
      struct cl_fv *r = cl_fv_new (0, zneg);
      r->q = z;
      r->e = e;
      return cl_fround (r, cl_tword (n));
    }
  }
  return 0;
}

static struct node *cl_femit (struct cl_fv *v, char *t)
{
  long p;
  long long emin, emax;
  char *suf, *sp, *l;
  cl_fty (t, &p, &emin, &emax, &suf, &sp);
  if (v->kind == 2) l = cl_cat ("0x1.8p+", sp);
  else if (v->kind == 1) l = cl_cat ("0x1p+", sp);
  else if (cl_big_zero (v->q)) l = cl_cat ("0x0p+0", suf);
  else {
    l = cl_qlit (v->q, v->e, emax);
    if (!l) return 0;
    l = cl_with_suffix (l, suf);
  }
  if (v->neg) { struct cl_list *x = cl_l (); cl_push (x, cl_n ("-")); cl_push (x, cl_n (l)); return cl_nl (":", x); }
  return cl_n (l);
}

static char *cl_special_float (struct cs_ex *n, struct cs_ex *t)
{
  struct cs_ex *s = n, *c;
  char *name = "", *w, *ex;
  int nan = 0;
  while (s->k == E_ICE || s->k == E_CONST || s->k == E_PAREN) s = cl_k (s, 0);
  if (s->k != E_CALL) return 0;
  c = cl_strip (cl_k (s, 0));
  if (c->k == E_REF && c->d) name = cl_dn (c->d);
  if (cl_eq (name, "__builtin_nan") || cl_eq (name, "__builtin_nanf") || cl_eq (name, "__builtin_nanl") || cl_eq (name, "__builtin_nanf128")) nan = 1;
  else if (!(cl_eq (name, "__builtin_huge_val") || cl_eq (name, "__builtin_huge_valf") || cl_eq (name, "__builtin_huge_vall") || cl_eq (name, "__builtin_huge_valf128")
             || cl_eq (name, "__builtin_inf") || cl_eq (name, "__builtin_inff") || cl_eq (name, "__builtin_infl") || cl_eq (name, "__builtin_inff128"))) return 0;
  if (nan) {
    struct cs_ex *x;
    if (s->nk != 2) return 0;
    x = cl_k (s, 1);
    while (x->k == E_ICE || x->k == E_PAREN) x = cl_k (x, 0);
    if (x->k != E_STR || !cl_str_empty (x)) return 0;
  } else if (s->nk != 1) return 0;
  w = cl_tword (t);
  if (cl_eq (w, "float")) ex = "128f";
  else if (cl_eq (w, "double")) ex = "1024";
  else if (cl_eq (w, "long double")) ex = "16384L";
  else if (cl_eq (w, "float128")) ex = "16384Q";
  else return 0;
  if (nan) return cl_cat ("0x1.8p+", ex);
  return cl_cat ("0x1p+", ex);
}
static char *cl_narrowlit (struct cs_ex *n, struct cs_ex *e)
{
  char *to, *l;
  if (e->k != E_FLT || !(cl_isld (e) || cl_eq (cl_tword (e), "float128")) || C->target == 3) return 0;
  to = cl_tword (n);
  if (cl_eq (to, "double")) l = cl_ldround (cl_lit_text (e), 53, -1074, 1023);
  else if (cl_eq (to, "float")) l = cl_ldround (cl_lit_text (e), 24, -149, 127);
  else return 0;
  if (!l) return 0;
  if (cl_eq (to, "float")) return cl_with_suffix (l, "f");
  return cl_with_suffix (l, "");
}

struct cl_bytes { unsigned char *p; long n; int pre; };
static void cl_utf8 (struct cs_buf *b, long long c)
{
  if (c < 0x80) cs_b_byte (b, c);
  else if (c < 0x800) { cs_b_byte (b, 0xc0 | (c >> 6)); cs_b_byte (b, 0x80 | (c & 63)); }
  else if (c < 0x10000) { cs_b_byte (b, 0xe0 | (c >> 12)); cs_b_byte (b, 0x80 | ((c >> 6) & 63)); cs_b_byte (b, 0x80 | (c & 63)); }
  else { cs_b_byte (b, 0xf0 | (c >> 18)); cs_b_byte (b, 0x80 | ((c >> 12) & 63)); cs_b_byte (b, 0x80 | ((c >> 6) & 63)); cs_b_byte (b, 0x80 | (c & 63)); }
}

static void cl_str_walk (struct cs_ex *e, struct cl_bytes *r, long long **el, long *nel)
{
  struct node *n = e->src;
  int isstr = n->count && cs_is (n, "str");
  long pi = 0, np = isstr ? n->count : 1, room = 0, ne = 0;
  long long *a = 0;
  struct cs_buf out;
  int pre = 0;
  cs_b_init (&out);
  while (pi < np) {
    struct node *k = isstr ? n->kids[pi] : n;
    struct cs_buf b;
    long at;
    int pp;
    cs_b_init (&b);
    cs_tok_bytes (k, &b);
    pp = cs_lit_prefix (b.p, &at);
    if (pp > 1) pre = pp;
    pi++;
  }
  pi = 0;
  while (pi < np) {
    struct node *k = isstr ? n->kids[pi] : n;
    struct cs_buf b;
    long at, i, end;
    cs_b_init (&b);
    cs_tok_bytes (k, &b);
    cs_lit_prefix (b.p, &at);
    i = at + 1;
    end = b.n - 1;
    while (i < end) {
      long m;
      int esc;
      long long c = cs_lit_char (b.p + i, end - i, &m, &esc);
      if (pre > 1) {
        if (ne == room) {
          long nr = room * 2 + 16, q = 0;
          long long *x = alloc (nr * sizeof (long long));
          while (q < ne) { x[q] = a[q]; q++; }
          a = x;
          room = nr;
        }
        a[ne] = c;
        ne++;
      }
      else if (esc == 0) cs_b_bytes (&out, b.p + i, m);
      else if (esc == 1) cs_b_byte (&out, c & 0xff);
      else cl_utf8 (&out, c);
      i += m;
    }
    pi++;
  }
  r->p = out.p;
  r->n = out.n;
  r->pre = pre;
  *el = a;
  *nel = ne;
}
static int cl_str_empty (struct cs_ex *s)
{
  struct cl_bytes b;
  long long *el;
  long ne;
  cl_str_walk (s, &b, &el, &ne);
  return b.n == 0 && ne == 0;
}
static int cl_utf8_ok (unsigned char *p, long n)
{
  long i = 0;
  while (i < n) {
    unsigned char c = p[i];
    long more, j = 1;
    if (c < 0x80) { i++; continue; }
    if (c < 0xc2) return 0;
    if (c < 0xe0) more = 1; else if (c < 0xf0) more = 2; else if (c < 0xf8) more = 3; else if (c < 0xfc) more = 4; else if (c < 0xfe) more = 5; else return 0;
    if (i + more >= n + 0 && i + more > n - 1) return 0;
    while (j <= more) { if ((p[i + j] & 0xc0) != 0x80) return 0; j++; }
    i += more + 1;
  }
  return 1;
}

static int cl_reads_number (char *s)
{
  long i = 0;
  /* (Perl's $ takes a last newline too) */
  if (cstrlen (s) && s[cstrlen (s) - 1] == '\n') s = cl_copy ((unsigned char *) s, cstrlen (s) - 1);
  if (s[i] == '-') i++;
  if (s[i] == '0' && (s[i + 1] == 'x' || s[i + 1] == 'X')) {
    i += 2;
    if (!s[i]) return 0;
    while (s[i]) { if (!(cl_digit (s[i]) || (s[i] >= 'a' && s[i] <= 'f') || (s[i] >= 'A' && s[i] <= 'F'))) return 0; i++; }
    return 1;
  }
  if (!s[i]) return 0;
  while (s[i]) { if (!cl_digit (s[i])) return 0; i++; }
  return 1;
}

static struct cl_list *cl_pieces (unsigned char *p, long n, int array)
{
  struct cl_list *l = cl_l ();
  long i = 0;
  while (i < n) { if (p[i] == 0) return 0; i++; }
  i = 0;
  while (i < n) {
    long m = n - i;
    char *s;
    if (m > 255) m = 255;
    if (!cl_utf8_ok (p + i, m)) return 0;
    s = cl_copy (p + i, m);
    if (array && cl_reads_number (s)) return 0;
    cl_push (l, cl_n (s));
    i += m;
  }
  return l;
}
static struct node *cl_num_node (long long v) { return cl_n (cl_num (v)); }

static void cl_grouped (long room, struct cl_list *items, struct cl_list *o)
{
  long i = 0;
  if (items->n <= room) { cl_append (o, items); return; }
  while (i < items->n) {
    struct node *g = cl_n ("items");
    long j = 0;
    while (j < 255 && i < items->n) { nd_add (g, items->v[i]); i++; j++; }
    cl_push (o, g);
  }
}
/* into the output, of a unit (0: the weak page) */
static void cl_out_of (struct node *n, struct cl_unit *u)
{
  if (C->out.n >= C->roomoutu) {
    long m = C->roomoutu * 2 + 256, i = 0;
    struct cl_unit **a = alloc (m * sizeof (struct cl_unit *));
    while (i < C->out.n) { a[i] = C->outu[i]; i++; }
    C->outu = a;
    C->roomoutu = m;
  }
  C->outu[C->out.n] = u;
  cl_push (&C->out, n);
}
static void cl_out (struct node *n) { cl_out_of (n, C->cu); }
static char *cl_hex_key (unsigned char *p, long n)
{
  char *h = alloc (2 * n + 1);
  long i = 0;
  while (i < n) { h[2 * i] = "0123456789abcdef"[p[i] >> 4]; h[2 * i + 1] = "0123456789abcdef"[p[i] & 15]; i++; }
  return h;
}
static struct node *cl_wide_text (struct cs_ex *n, long long *el, long ne)
{
  char *name;
  struct cl_list *t, *items = cl_l (), *o = cl_l ();
  long i = 0;
  C->nwide = C->nwide + 1;
  name = cl_cat ("wide text ", cl_num (C->nwide));
  t = cl_ct (n->t);
  while (ne > 0 && el[ne - 1] == 0) ne--;
  while (i < ne) { cl_push (items, cl_num_node (el[i])); i++; }
  cl_append (o, t);
  cl_grouped (255 - t->n, items, o);
  cl_out (cl_nl (cl_cat (name, ":"), o));
  return cl_n1 ("address", cl_n1 (name, cl_n ("0")));
}

static void cl_string_bytes (unsigned char *p, long n, struct cl_list *o)
{
  struct cl_list *pc = 0;
  char *s = cl_copy (p, n);
  int hasnul = 0;
  long i = 0;
  while (i < n) { if (p[i] == 0) hasnul = 1; i++; }
  if (!hasnul && n <= 255) pc = cl_pieces (p, n, 0);
  if (!hasnul && n <= 255 && !cl_isop (s) && !cl_eq (s, "?") && !cl_eq (s, ":") && !cl_eq (s, ".") && !cl_eq (s, "...") && !cl_eq (s, "?\n") && !cl_eq (s, ":\n") && !cl_eq (s, ".\n") && !cl_eq (s, "...\n") && !cl_val (&C->reserved, s) && (n == 0 || pc)) {
    struct node *a = cl_n ("address");
    nd_add (a, cl_n ("char"));
    if (n == 0) nd_add (a, cl_n (""));
    else cl_add_all (a, pc);
    cl_push (o, a);
    return;
  }
  {
    char *key = cl_hex_key (p, n), *nm = cl_get (&C->text_item, key);
    if (!nm) {
      struct cl_list *c = cl_l (), *x = cl_l ();
      C->ntext = C->ntext + 1;
      nm = cl_cat ("text ", cl_num (C->ntext));
      cl_put (&C->text_item, key, nm);
      i = 0;
      while (i < n) { cl_push (c, cl_num_node (p[i])); i++; }
      cl_push (c, cl_n ("0"));
      cl_push (x, cl_n ("array"));
      cl_push (x, cl_n ("char"));
      cl_push (x, cl_num_node (n + 1));
      cl_grouped (252, c, x);
      cl_out (cl_nl (cl_cat (nm, ":"), x));
    }
    cl_push (o, cl_n1 ("address", cl_n1 (nm, cl_n ("0"))));
  }
}
static void cl_string_value (struct cs_ex *e, struct cl_list *o)
{
  struct cl_bytes b;
  long long *el;
  long ne;
  cl_str_walk (e, &b, &el, &ne);
  if (b.pre > 1) { cl_push (o, cl_wide_text (e, el, ne)); return; }
  cl_string_bytes (b.p, b.n, o);
}

static void cl_array_text (struct cs_ex *e, struct cl_list *o)
{
  struct cl_bytes b;
  long long *el;
  long ne, i = 0;
  struct cl_list *pc = 0;
  cl_str_walk (e, &b, &el, &ne);
  if (b.pre > 1) {
    while (ne > 0 && el[ne - 1] == 0) ne--;
    while (i < ne) { cl_push (o, cl_num_node (el[i])); i++; }
    return;
  }
  while (b.n > 0 && b.p[b.n - 1] == 0) b.n = b.n - 1;
  if (b.n == 0) return;
  if (C->in_global) pc = cl_pieces (b.p, b.n, 1);
  if (pc && pc->n) { cl_append (o, pc); return; }
  while (i < b.n) { cl_push (o, cl_num_node (b.p[i])); i++; }
}
static struct cs_ex *cl_bare_string (struct cs_ex *n)
{
  while (n->k == E_PAREN || (n->k == E_ICE && n->op != CK_ARRAYTOPOINTERDECAY)) n = cl_k (n, 0);
  if (n->k == E_STR && n->src) return n;
  return 0;
}

static struct node *cl_cast_node (struct cl_list *t, struct cl_list *v)
{
  struct cl_list *x = cl_l ();
  char *j = cl_join (t);
  if ((cl_eq (j, "address char") || cl_eq (j, "address u8")) && v->n == 1 && (!v->v[0]->count || cl_is (v->v[0], "content") || cl_is (v->v[0], "address"))) {
    struct node *h = cl_nl (":", v);
    v = cl_l ();
    cl_push (v, h);
  }
  cl_append (x, t);
  cl_append (x, v);
  return cl_nl ("cast:", x);
}
static struct node *cl_cast_w (char *w, struct cl_list *v) { struct cl_list *t = cl_l (); cl_w (t, w); return cl_cast_node (t, v); }
static void cl_operand (struct cs_ex *n, int p, int right, struct cl_list *o)
{
  struct cs_ex *s = cl_strip (n);
  struct cl_list *e = cl_ex (n);
  if ((s->k == E_BIN || s->k == E_CASS) && !cl_name_is (s, ",")) {
    int q = cl_prec (cl_name_of (s));
    if (q < p || (right && q == p && p != 2)) { cl_push (o, cl_nl (":", e)); return; }
  }
  if ((s->k == E_COND || s->k == E_BCOND) && (3 < p || (!right && 3 == p))) { cl_push (o, cl_nl (":", e)); return; }
  if (s->k == E_CLIT && e->n == 1 && e->v[0]->count && (cl_is (e->v[0], "array") || cl_is (e->v[0], "vector") || !cl_scalar_word ((char *) e->v[0]->text))) { cl_push (o, cl_nl (":", e)); return; }
  cl_append (o, e);
}

static int cl_const_val (struct cs_ex *e, long long *v)
{
  if (!e->isnull && cs_eval (e->kid[0], v)) { *v = cs_wrap (*v, e->t); return 1; }
  return 0;
}
static int cl_int_const (struct cs_ex *n, long long *v)
{
  int k = n->k;
  if (k == E_INT) { *v = n->val; return 1; }
  if (k == E_CONST && cl_const_val (n, v)) return 1;
  if (k == E_PAREN || k == E_ICE || k == E_CAST || k == E_CONST) return cl_int_const (cl_k (n, 0), v);
  if (k == E_UN) {
    long long a;
    if (cl_name_is (n, "post++") || cl_name_is (n, "post--") || !cl_int_const (cl_k (n, 0), &a)) return 0;
    if (cl_name_is (n, "-")) { *v = 0 - a; return 1; }
    if (cl_name_is (n, "~")) { *v = ~a; return 1; }
    if (cl_name_is (n, "+")) { *v = a; return 1; }
    return 0;
  }
  if (k == E_SIZEOF && cl_name_is (n, "sizeof")) {
    struct cs_ty *t = n->lhsty, *c;
    long long count = 1, z;
    if (!t) { if (!n->nk) return 0; t = n->kid[0]->t; }
    c = cs_canon (t);
    if (c->k == TY_ARRAY && c->n >= 0) { count = c->n; t = c->to; }
    z = cl_csize (t);
    if (!z) return 0;
    *v = count * z;
    return 1;
  }
  if (k == E_BIN) {
    long long a, b;
    int ha = cl_int_const (cl_k (n, 0), &a), hb = cl_int_const (cl_k (n, 1), &b);
    if (!ha || !hb) return 0;
    if (cl_name_is (n, "|")) { *v = a | b; return 1; }
    if (cl_name_is (n, "&")) { *v = a & b; return 1; }
    if (cl_name_is (n, "^")) { *v = a ^ b; return 1; }
    if (cl_name_is (n, "+")) { *v = a + b; return 1; }
    if (cl_name_is (n, "-")) { *v = a - b; return 1; }
    if (cl_name_is (n, "*")) { *v = a * b; return 1; }
    if (cl_name_is (n, "<<")) { *v = a << b; return 1; }
    if (cl_name_is (n, ">>")) { *v = a >> b; return 1; }
    if (cl_name_is (n, "/") && b) { *v = a / b; return 1; }
    return 0;
  }
  return 0;
}
static char *cl_tword_int (struct cs_ex *n) { return cl_join (cl_ct (n->t)); }
static int cl_unsigned_t (struct cs_ex *n)
{
  struct cl_list *l = cl_ct (n->t);
  char *t = (char *) l->v[0]->text;
  return (t[0] == 'u' && cl_digit (t[1])) || cl_eq (t, "char");
}
static void cl_softfp (struct cs_ex *n)
{
  int k = n->k;
  if (k == E_BIN || k == E_CASS) {
    char *op = cl_name_of (n), *base = op;
    int ld;
    if (n->nk != 2) return;
    ld = cl_isq (n->kid[0]) || cl_isq (n->kid[1]);
    if (k == E_CASS) {
      base = cl_copy ((unsigned char *) op, cstrlen (op) - 1);
      if (n->resty && cl_eq (cl_tword_t (n->resty), cl_q128 ())) ld = 1;
    }
    if (!ld) return;
    if (cl_eq (base, "+")) cl_want ("__addtf3");
    else if (cl_eq (base, "-")) cl_want ("__subtf3");
    else if (cl_eq (base, "*")) cl_want ("__multf3");
    else if (cl_eq (base, "/")) cl_want ("__divtf3");
    else if (cl_eq (base, "==")) cl_want ("__eqtf2");
    else if (cl_eq (base, "!=")) cl_want ("__netf2");
    else if (cl_eq (base, "<")) cl_want ("__lttf2");
    else if (cl_eq (base, ">")) cl_want ("__gttf2");
    else if (cl_eq (base, "<=")) cl_want ("__letf2");
    else if (cl_eq (base, ">=")) cl_want ("__getf2");
    return;
  }
  if (k == E_UN && cl_name_is (n, "-") && cl_isq (n)) { cl_want ("__negtf2"); return; }
  if (k == E_CAST || (k == E_ICE && (n->op == CK_INTEGRALTOFLOATING || n->op == CK_FLOATINGTOINTEGRAL || n->op == CK_FLOATINGCAST))) {
    char *to = cl_tword (n), *from, *q = cl_q128 ();
    if (!n->nk) return;
    from = cl_tword (n->kid[0]);
    if (cl_eq (to, from) || (!cl_eq (to, q) && !cl_eq (from, q))) return;
    if (cl_eq (to, q) && cl_eq (from, "long double")) return;
    if (cl_eq (to, "long double") && !cl_eq (q, "long double")) { cl_want ("__trunctfxf2"); return; }
    if (cl_eq (to, q)) {
      if (cl_eq (from, "float")) cl_want ("__extendsftf2");
      else if (cl_eq (from, "double")) cl_want ("__extenddftf2");
      else if (cl_unsigned_t (n->kid[0])) cl_want ("__floatunditf");
      else cl_want ("__floatditf");
    } else {
      if (cl_eq (to, "float")) cl_want ("__trunctfsf2");
      else if (cl_eq (to, "double")) cl_want ("__trunctfdf2");
      else if (cl_unsigned_t (n)) cl_want ("__fixunstfdi");
      else cl_want ("__fixtfdi");
    }
    return;
  }
  if (k == E_ICE && n->op == CK_FLOATINGTOBOOLEAN && n->nk && cl_isq (n->kid[0])) cl_want ("__netf2");
}
static int cl_label_taken (char *nm)
{
  return cl_has (&C->rec, cl_cat ("struct ", nm)) || cl_has (&C->rec, cl_cat ("union ", nm)) || cl_has (&C->enumd, cl_cat ("enum ", nm)) || cl_val (&C->typedefs, nm) || cl_has (&C->var, nm) || cl_has (&C->fn, nm);
}
static char *cl_label_name (unsigned char *p, long n)
{
  char *nm = cl_copy (p, n), *f = cl_ffname (nm);
  if (cl_ends (f, "'")) return f;
  if (cl_label_taken (nm)) return cl_cat (f, "'");
  return f;
}

/* (a local one, GNU's __label__: x 1, x 2, in the order they are declared, c2ff's) */
static char *cl_label_of (unsigned char *p, long n, long k)
{
  char *nm;
  if (!k) return cl_label_name (p, n);
  nm = cl_cat3 (cl_copy (p, n), " ", cl_num (k));
  return cl_label_name ((unsigned char *) nm, cstrlen (nm));
}
static void cl_arg (struct cs_ex *a, struct cl_list *o)
{
  if (a->k == E_ICE && a->op == CK_INTEGRALCAST) {
    struct cs_ex *v = cl_k (a, 0);
    struct cl_list *to = cl_ct (a->t), *from = cl_ct (v->t);
    char *tj = cl_join (to), *fj = cl_join (from);
    if (cl_eq (fj, "u32") && (cl_eq (tj, "u64") || cl_eq (tj, "long") || cl_eq (tj, "i64"))) {
      struct cl_list *x = cl_l ();
      cl_itemx (v, x);
      cl_push (o, cl_cast_node (to, x));
      return;
    }
  }
  cl_itemx (a, o);
}
static struct cl_list *cl_args (struct cs_ex *n, long from)
{
  struct cl_list *l = cl_l ();
  long i = from;
  while (i < n->nk) { cl_arg (cl_k (n, i), l); i++; }
  return l;
}
static struct node *cl_call_node (char *name, struct cs_ex *n)
{
  return cl_nl (name, cl_args (n, 1));
}
static int cl_builtin_listed (char *name)
{
  static char *w[] = { "unreachable", "trap", "return_address", "frame_address", "extract_return_addr", "clz", "clzl", "clzll", "ctz", "ctzl", "ctzll", "popcount", "popcountl", "popcountll", "bswap16", "bswap32", "bswap64", "add_overflow", "mul_overflow", "add_overflow_p", "mul_overflow_p", "thread_pointer", "fabs", "fabsf", "fabsl", "copysign", "copysignf", "copysignl", "signbitf", "signbitl", "inff", "huge_val", "huge_valf", "huge_vall", "nan", "nanf", "nanl", "fma", "fmaf", "sqrt", "sqrtf", "ffs", "ffsl", "ffsll", 0 };
  long i = 0;
  if (!cl_starts (name, "__builtin_")) return 0;
  while (w[i]) { if (cl_eq (name + 10, w[i])) return 1; i++; }
  return 0;
}
static int cl_ovf_ok (char *name, char *sig)
{
  static char *addv[] = { "u64 u64 u64", "i128 i128 i128", "u32 u32 u32", "u32 u32 u64", "u32 u64 u64", "u64 int u32", "u64 u64 int", "int int int", "long int long", "long long long", "u64 u32 u64", "u64 int u64", 0 };
  static char *mulv[] = { "u64 u64 u64", "u32 u64 u64", "u64 int u32", "int int int", "long long long", 0 };
  static char *subv[] = { "long long long", "int long int", "long int long", "i128 i128 i128", "int i128 i128", "int int int", "int long long", "u64 u64 u64", 0 };
  long i = 0;
  char **a = addv;
  if (cl_eq (name, "__builtin_mul_overflow")) a = mulv;
  else if (cl_eq (name, "__builtin_sub_overflow")) a = subv;
  while (a[i]) { if (cl_eq (sig, a[i])) return 1; i++; }
  if (C->target == 3) {
    if (cl_eq (name, "__builtin_mul_overflow") && (cl_eq (sig, "u32 u32 u32") || cl_eq (sig, "u32 int u32"))) return 1;
    if (cl_eq (name, "__builtin_add_overflow") && (cl_eq (sig, "u32 int u32") || cl_eq (sig, "u64 u32 int") || cl_eq (sig, "i64 i64 i64") || cl_eq (sig, "i64 int i64"))) return 1;
    if (cl_eq (name, "__builtin_sub_overflow") && (cl_eq (sig, "i64 i64 i64") || cl_eq (sig, "int i64 i64") || cl_eq (sig, "u32 u32 u32") || cl_eq (sig, "i64 i64 long"))) return 1;
  }
  return 0;
}
static int cl_pure (struct cs_ex *n)
{
  long i = 0;
  if (n->k == E_CALL || n->k == E_CASS || n->k == E_STMTX) return 0;
  if (n->k == E_BIN && cl_name_is (n, "=")) return 0;
  if (n->k == E_UN && (cl_name_is (n, "++") || cl_name_is (n, "--") || cl_name_is (n, "post++") || cl_name_is (n, "post--"))) return 0;
  while (i < n->nk) { if (!cl_pure (n->kid[i])) return 0; i++; }
  return 1;
}
static void cl_init (struct cs_ex *n, struct cl_list *o);
static int cl_anon_union_init (struct cs_ex *n)
{
  long i = 0;
  struct cs_ty *c;
  if (n->k != E_INIT) return 0;
  c = cs_canon (n->t);
  if (c->k == TY_UNION && !c->rec->tag && !c->rec->td) return 1;
  while (i < n->nk) { if (cl_anon_union_init (n->kid[i])) return 1; i++; }
  return 0;
}
static int cl_const_init (struct cs_ex *n)
{
  long long v;
  struct cs_ex *s;
  if (n->k == E_INIT) {
    long i = 0;
    while (i < n->nk) { if (!cl_const_init (cl_k (n, i))) return 0; i++; }
    return 1;
  }
  if (n->k == E_IVI || cl_int_const (n, &v)) return 1;
  s = cl_strip (n);
  return s->k == E_REF && s->d && s->d->k == DK_ENUMC;
}
static void cl_atomic (struct cs_ex *n, struct cl_list *o)
{
  char *a = cl_name_of (n);
  struct cs_ex *p = cl_k (n, 0), *ord = cl_k (n, 1);
  struct cl_list *x = cl_l ();
  char *name = 0;
  if (cl_eq (a, "__atomic_exchange_n")) {
    name = cl_cat ("__atomic_exchange_", cl_num (cl_csize (n->t)));
    cl_itemx (p, x); cl_itemx (cl_k (n, 2), x); cl_itemx (ord, x);
  } else if (cl_eq (a, "__atomic_load_n")) {
    name = cl_cat ("__atomic_load_", cl_num (cl_csize (n->t)));
    cl_itemx (p, x); cl_itemx (ord, x);
  } else if (cl_eq (a, "__atomic_store_n")) {
    name = cl_cat ("__atomic_store_", cl_num (cl_csize (cl_k (n, 2)->t)));
    cl_itemx (p, x); cl_itemx (cl_k (n, 2), x); cl_itemx (ord, x);
  } else if (cl_eq (a, "__atomic_load") || cl_eq (a, "__atomic_store")) {
    struct cs_ty *pc = cs_canon (p->t);
    struct node *sz = cl_n ("sizeof");
    if (pc->k != TY_PTR) cl_fail ("an atomic of no pointer", a);
    cl_add_all (sz, cl_ct (pc->to));
    name = a;
    cl_push (x, sz);
    cl_itemx (p, x); cl_itemx (cl_k (n, 2), x); cl_itemx (ord, x);
  } else if (cl_eq (a, "__atomic_compare_exchange_n")) {

    name = cl_cat ("__atomic_compare_exchange_", cl_num (cl_csize (cl_k (n, 4)->t)));
    cl_itemx (p, x); cl_itemx (cl_k (n, 2), x); cl_itemx (cl_k (n, 4), x); cl_itemx (ord, x); cl_itemx (cl_k (n, 3), x);
  } else if (cl_starts (a, "__atomic_fetch_") || (cl_starts (a, "__atomic_") && cl_ends (a, "_fetch"))) {
    name = cl_cat3 (a, "_", cl_num (cl_csize (n->t)));
    cl_itemx (p, x); cl_itemx (cl_k (n, 2), x); cl_itemx (ord, x);
  } else cl_fail ("the atomic", a);
  cl_push (o, cl_nl (name, x));
}
static void cl_syscall (struct cs_st *cs, struct cl_list *o, int *found);
static char *cl_unit_label (void);

static int cl_spelled_rec (struct cs_ty *t)
{
  struct cs_buf b, in;
  char *s;
  struct cs_ty *c = cs_canon (t);

  if ((c->k == TY_STRUCT || c->k == TY_UNION) && !c->rec->tag && c->rec->td) return 0;
  cs_b_init (&b);
  cs_b_init (&in);
  cs_p_type (&b, c, &in, 1);
  s = cl_copy (b.p, b.n);
  while (cl_starts (s, "const ") || cl_starts (s, "volatile ")) { if (s[0] == 'c') s = s + 6; else s = s + 9; }
  return cl_starts (s, "struct ") || cl_starts (s, "union ");
}

/* a type's spelling less its const and volatile (c2ff.pl's $bare) */
static char *cl_bare (struct cs_ty *t)
{
  char *s = cl_td_key (t);
  struct cs_buf b;
  long i = 0;
  cs_b_init (&b);
  while (s[i]) {
    int st = i == 0 || !(cl_alpha (s[i - 1]) || cl_digit (s[i - 1]));
    if (st && cl_starts (s + i, "const ")) { i = i + 6; while (s[i] == ' ') i++; continue; }
    if (st && cl_starts (s + i, "volatile ")) { i = i + 9; while (s[i] == ' ') i++; continue; }
    cs_b_byte (&b, s[i]);
    i++;
  }
  return cl_copy (b.p, b.n);
}
static int cl_isf_word (char *s) { return cl_eq (s, "float") || cl_eq (s, "double") || cl_eq (s, "long double"); }
/* gcc's __builtin_tgmath (tgmath.h's): its functions, then the arguments; the
   call is the one of the function of the type of the arguments that differ in
   type between the functions (float, double, else long double; an integer is
   a double). clang-prelude.h declares it without parameters, so a float
   argument was made a double: the call made again, of the chosen function,
   with the arguments' own values converted to its parameters. */
static struct cs_ex *cl_tgmath (struct cs_ex *n)
{
  struct cs_ex *f[3], *e, *arg1;
  struct cs_ty *ft[3], *fc;
  long na = n->nk - 1, i = 1, nf = 0, nv, r = 0;
  while (i <= na) {
    struct cs_ex *s = cl_strip (cl_k (n, i));
    char *spelt;
    struct cs_buf b;
    if (s->k != E_REF) break;
    cs_b_init (&b);
    cs_p_ty (&b, s->t, 1);
    spelt = cl_copy (b.p, b.n);
    {
      long q = 0;
      int paren = 0;
      while (spelt[q]) { if (spelt[q] == '(') paren = 1; q++; }
      if (!paren) break;
    }
    if (nf < 3) { f[nf] = cl_k (n, i); ft[nf] = cs_canon (s->t); }
    nf++;
    i++;
  }
  nv = na - nf;
  if (nf < 3 || nv <= 0) cl_fail ("__builtin_tgmath without functions and arguments", 0);
  if (ft[0]->k != TY_FUNC || ft[1]->k != TY_FUNC || ft[2]->k != TY_FUNC || cs_kind (ft[0]->to) != TY_FLOAT || cs_kind (ft[1]->to) != TY_DOUBLE || cs_kind (ft[2]->to) != TY_LDOUBLE || ft[0]->np != nv || ft[1]->np != nv)
    cl_fail ("__builtin_tgmath of other functions than of float, double, long double", 0);
  {
    struct cs_ex **v = alloc ((nv + 1) * sizeof (struct cs_ex *));
    long q = 0;
    while (q < nv) {
      struct cs_ex *a = cl_k (n, nf + 1 + q);
      while (a->k == E_ICE && a->op == CK_FLOATINGCAST && cl_eq (cl_bare (cl_k (a, 0)->t), "float")) a = cl_k (a, 0);
      v[q] = a;
      q++;
    }
    q = 0;
    while (q < nv) {
      if (!cl_eq (cl_td_key (ft[0]->ps[q]), cl_td_key (ft[1]->ps[q]))) {
        char *t = cl_bare (v[q]->t);
        long rk = 1;
        if (cs_kind (v[q]->t) == TY_COMPLEX) cl_fail ("__builtin_tgmath of a complex argument", 0);
        if (cl_eq (t, "float")) rk = 0;
        else if (cl_eq (t, "long double")) rk = 2;
        if (rk > r) r = rk;
      }
      q++;
    }
    fc = ft[r];
    e = cs_mk (E_CALL, fc->to, 0);
    cs_add (e, f[r]);
    q = 0;
    while (q < nv) {
      char *from = cl_bare (v[q]->t), *to = cl_td_key (fc->ps[q]);
      if (cl_eq (from, to)) arg1 = v[q];
      else if (cl_isf_word (to)) arg1 = cs_ice (v[q], fc->ps[q], cl_isf_word (from) ? CK_FLOATINGCAST : CK_INTEGRALTOFLOATING);
      else arg1 = cs_ice (v[q], fc->ps[q], CK_INTEGRALCAST);
      cs_add (e, arg1);
      q++;
    }
  }
  return e;
}
static void cl_expr (struct cs_ex *n, struct cl_list *o);
static void cl_call (struct cs_ex *n, struct cl_list *o)
{
  struct cs_ex *callee = cl_k (n, 0), *c = cl_strip (callee);
  long na = n->nk - 1;
  char *name;
  /* ((*f) (...) calls what f points at; a _Generic's call is of the association it selected) */
  for (;;) {
    while (c->k == E_PAREN || (c->k == E_UN && cl_name_is (c, "*"))) c = cl_strip (cl_k (c, 0));
    if (c->k != E_GENERIC) break;
    c = cl_strip (cl_k (c, c->val + 1));
  }
  if (c->k == E_MEM || c->k == E_IDX) {
    struct cl_list *p = cl_ex (c);
    if (p->n != 1 || !p->v[0]->count) cl_fail ("a call through a path that is not one node", 0);
    if (na) cl_add_all (p->v[0], cl_args (n, 1)); else nd_add (p->v[0], cl_n ("."));
    cl_append (o, p);
    return;
  }
  if (c->k == E_CAST || c->k == E_COND || c->k == E_CALL || c->k == E_BIN) {
    struct cl_list *p = cl_ex (c);
    struct node *h = cl_one (p);
    nd_add (h, cl_n ("."));
    cl_add_all (h, cl_args (n, 1));
    cl_push (o, h);
    return;
  }
  if (c->k != E_REF) cl_fail ("a call through what is no name", 0);
  if (c->d && c->d->errfn) { struct cl_list *v = cl_l (); cl_push (v, cl_n ("0")); cl_push (o, cl_cast_w ("void", v)); return; }
  name = cl_dn (c->d);
  if (cl_eq (name, "__builtin_expect")) {
    struct cl_list *v = cl_l ();
    cl_itemx (cl_k (n, 1), v);
    cl_push (o, cl_cast_node (cl_ct (n->t), v));
    return;
  }
  if (cl_eq (name, "__builtin_tgmath")) { cl_expr (cl_tgmath (n), o); return; }
  if (C->in_global) { char *lit = cl_special_float (n, n); if (lit) { cl_push (o, cl_n (lit)); return; } }
  if (cl_eq (name, "__builtin_constant_p")) {
    struct cs_ex *a = cl_strip (cl_k (n, 1));
    cl_push (o, cl_n (cs_pick (a->k == E_INT || a->k == E_CHR, "1", "0")));
    return;
  }
  if (cl_eq (name, "__builtin_mempcpy")) {
    char *mc = cl_own ("memcpy");
    struct cl_list *t = cl_l (), *v = cl_l (), *w = cl_l ();
    if (na != 3) cl_fail ("__builtin_mempcpy without 3 arguments", 0);
    if (!cl_pure (cl_k (n, 3))) cl_fail ("__builtin_mempcpy of a count with effects", 0);
    cl_want (mc);
    cl_w (t, "address"); cl_w (t, "u8");
    cl_push (v, cl_nl (cl_ffname (mc), cl_args (n, 1)));
    cl_push (w, cl_cast_node (t, v));
    cl_push (w, cl_n ("+"));
    cl_push (w, cl_atom (cl_k (n, 3)));
    t = cl_l ();
    cl_w (t, "address"); cl_w (t, "void");
    v = cl_l ();
    cl_push (v, cl_nl (":", w));
    cl_push (o, cl_cast_node (t, v));
    return;
  }

  if (cl_starts (name, "__builtin_")) {
    char *b = name + 10;
    if (cl_starts (b, "mem") || cl_starts (b, "str") || cl_starts (b, "stp") || cl_eq (b, "free") || cl_eq (b, "malloc")) name = b;
  }

  if (cl_eq (name, "copysign") || cl_eq (name, "copysignf") || cl_eq (name, "copysignl") || cl_eq (name, "fabs") || cl_eq (name, "fabsf") || cl_eq (name, "fabsl")) name = cl_cat ("__builtin_", name);
  if (cl_eq (name, "copysignf128") || cl_eq (name, "fabsf128")) name = cl_cat ("__builtin_", name);
  if (C->target != 1 && cl_ends (name, "f128") && (cl_eq (name, "__builtin_copysignf128") || cl_eq (name, "__builtin_fabsf128") || cl_eq (name, "__builtin_huge_valf128") || cl_eq (name, "__builtin_inff128") || cl_eq (name, "__builtin_nanf128") || cl_eq (name, "__builtin_nansf128") || cl_eq (name, "__builtin_signbitf128")))
    name = cl_cat (cl_copy ((unsigned char *) name, cstrlen (name) - 4), "l");
  if (cl_eq (name, "__builtin_alloca")) { cl_push (o, cl_call_node ("alloca", n)); return; }
  if (cl_eq (name, "__builtin_add_overflow") || cl_eq (name, "__builtin_sub_overflow") || cl_eq (name, "__builtin_mul_overflow")) {

    struct cl_list *a0 = cl_ct (cl_k (n, 1)->t), *a1 = cl_ct (cl_k (n, 2)->t), *a2 = cl_ct (cl_k (n, 3)->t);
    char *sig = "";
    if (a0->n == 1 && a1->n == 1 && a2->n == 2 && cl_is (a2->v[0], "address"))
      sig = cl_cat3 (cl_cat3 ((char *) a0->v[0]->text, " ", (char *) a1->v[0]->text), " ", (char *) a2->v[1]->text);
    if (!cl_ovf_ok (name, sig)) cl_fail (name, sig);
    cl_push (o, cl_call_node (cl_cat3 (name, " ", sig), n));
    return;
  }
  if (cl_eq (name, "__builtin_isnan") || cl_eq (name, "__builtin_isinf_sign") || cl_eq (name, "__builtin_isinf") || cl_eq (name, "__builtin_signbit") || cl_eq (name, "__builtin_isfinite") || cl_eq (name, "__builtin_isunordered") || cl_eq (name, "__builtin_isless") || cl_eq (name, "__builtin_islessequal") || cl_eq (name, "__builtin_isgreater") || cl_eq (name, "__builtin_isgreaterequal") || cl_eq (name, "__builtin_fpclassify")) {
    char *t;
    if (cl_eq (name, "__builtin_fpclassify")) t = cl_tword_int (cl_k (n, n->nk - 1)); else t = cl_tword_int (cl_k (n, 1));
    if (!(cl_eq (t, "float") || cl_eq (t, "double") || cl_eq (t, "long double") || cl_eq (t, "float128") || cl_eq (t, "float16"))) cl_fail (name, t);
    cl_push (o, cl_call_node (cl_cat3 (name, " ", t), n));
    return;
  }
  if (cl_eq (name, "__builtin_va_start") || cl_eq (name, "__builtin_c23_va_start")) { struct cl_list *x = cl_l (); cl_itemx (cl_k (n, 1), x); cl_push (o, cl_nl ("va_start", x)); return; }
  if (cl_eq (name, "__builtin_va_end")) { struct cl_list *x = cl_l (); cl_itemx (cl_k (n, 1), x); cl_push (o, cl_nl ("va_end", x)); return; }
  if (cl_eq (name, "__builtin_va_copy")) { struct cl_list *x = cl_l (); cl_itemx (cl_k (n, 1), x); cl_itemx (cl_k (n, 2), x); cl_push (o, cl_nl ("va_copy", x)); return; }
  if (cl_eq (name, "__builtin_va_arg_pack")) { cl_push (o, cl_n ("va_arg_pack")); return; }
  if (cl_eq (name, "__builtin_va_arg_pack_len")) { cl_push (o, cl_n ("va_arg_pack_len")); return; }
  if (cl_starts (name, "__builtin_stdc_")) {
    struct cs_ex *a = cl_k (n, 1);
    char *w;
    while (a->k == E_ICE && a->op == CK_INTEGRALCAST) a = cl_k (a, 0);
    w = cl_tword_int (a);
    if (!(cl_eq (w, "u8") || cl_eq (w, "u16") || cl_eq (w, "u32") || cl_eq (w, "u64"))) cl_fail (name, w);
    cl_push (o, cl_call_node (cl_cat3 (name, " ", w), n));
    return;
  }
  if (cl_eq (name, "__builtin_add_overflow_p") && C->target == 3) { cl_push (o, cl_call_node (cl_cat (name, " u32"), n)); return; }
  if (cl_eq (name, "__builtin_arm_get_fpscr")) { cl_push (o, cl_n (name)); return; }
  if (cl_eq (name, "__builtin_copysignf16") || cl_eq (name, "__builtin_huge_valf16")) { cl_push (o, cl_call_node (name, n)); return; }
  if (cl_builtin_listed (name) || cl_eq (name, "__atomic_always_lock_free")) { cl_push (o, cl_call_node (name, n)); return; }
  if (C->target != 3 && (cl_eq (name, "__builtin_unwind_init") || cl_eq (name, "__builtin_dwarf_cfa") || cl_eq (name, "__builtin_dwarf_sp_column") || cl_eq (name, "__builtin_eh_return") || cl_eq (name, "__builtin_eh_return_data_regno") || cl_eq (name, "__builtin_frob_return_addr") || cl_eq (name, "__builtin_init_dwarf_reg_size_table"))) { cl_push (o, cl_call_node (name, n)); return; }
  if (C->target == 3 && cl_eq (name, "__builtin_frob_return_addr")) { cl_push (o, cl_call_node (name, n)); return; }
  if (C->target == 2 && (cl_eq (name, "__builtin_aarch64_autia1716") || cl_eq (name, "__builtin_aarch64_autib1716") || cl_eq (name, "__builtin_aarch64_chkfeat") || cl_eq (name, "__builtin_aarch64_gcspr") || cl_eq (name, "__builtin_aarch64_gcspopm") || cl_eq (name, "__builtin___clear_cache"))) { cl_push (o, cl_call_node (name, n)); return; }
  if (C->target == 2 && (cl_eq (name, "__builtin_aarch64_get_fpcr") || cl_eq (name, "__builtin_aarch64_get_fpsr")) && !na) { cl_push (o, cl_n (name)); return; }
  if (C->target == 2 && (cl_eq (name, "__builtin_aarch64_set_fpcr") || cl_eq (name, "__builtin_aarch64_set_fpsr"))) { cl_push (o, cl_call_node (name, n)); return; }
  if (C->target == 2) {
    /* libm's of aarch64 (builtins-aarch64.ff.txt) */
    static char *w[] = { "floor", "ceil", "trunc", "round", "roundeven", "rint", "nearbyint", "fmax", "fmin", "lrint", "llrint", "lround", "llround", 0 };
    long i = 0;
    while (w[i]) {
      char *b = cl_cat ("__builtin_", w[i]);
      if (cl_eq (name, b) || cl_eq (name, cl_cat (b, "f"))) { cl_push (o, cl_call_node (name, n)); return; }
      i++;
    }
  }

  if (C->target == 1 && !na && cl_eq (name, "__builtin_ia32_rdsspq")) { cl_push (o, cl_n1 (name, cl_n ("0"))); return; }
  if (C->target == 1 && (cl_eq (name, "__builtin_ia32_rdsspq") || cl_eq (name, "__builtin_ia32_incsspq") || cl_eq (name, "__builtin___clear_cache") || cl_eq (name, "__builtin_fabsf128") || cl_eq (name, "__builtin_copysignf128") || cl_eq (name, "__builtin_signbitf128") || cl_eq (name, "__builtin_huge_valf128") || cl_eq (name, "__builtin_nanf128") || cl_eq (name, "__builtin_ia32_pmovmskb128") || cl_eq (name, "__builtin_ia32_pshufb128"))) { cl_push (o, cl_call_node (name, n)); return; }
  if (C->target == 1 && !na && (cl_eq (name, "__builtin_ia32_rdtsc") || cl_eq (name, "__builtin_ia32_pause") || cl_eq (name, "__builtin_ia32_xbegin") || cl_eq (name, "__builtin_ia32_xend") || cl_eq (name, "__builtin_ia32_xtest"))) { cl_push (o, cl_n (name)); return; }
  if (C->target == 1 && na == 3 && (cl_eq (name, "_mm_cmpistri") || cl_eq (name, "_mm_cmpistrc") || cl_eq (name, "_mm_cmpistrz"))) {

    long long imm;
    char *which = cs_pick (cl_eq (name, "_mm_cmpistri"), "i", cs_pick (cl_eq (name, "_mm_cmpistrc"), "ic", "iz"));
    struct cs_buf b;
    struct cl_list *x = cl_l ();
    long d = 28;
    int any = 0;
    if (!cl_int_const (cl_k (n, 3), &imm)) cl_fail ("an immediate that is no constant of", name);
    cs_b_init (&b);
    cs_b_str (&b, "__builtin_ia32_pcmpistr");
    cs_b_str (&b, which);
    cs_b_str (&b, "128 0x");
    while (d >= 0) {
      int v = (imm >> d) & 15;
      if (v || any || d == 0) { cs_b_byte (&b, "0123456789abcdef"[v]); any = 1; }
      d = d - 4;
    }
    cl_arg (cl_k (n, 1), x);
    cl_arg (cl_k (n, 2), x);
    cl_push (o, cl_nl (cl_copy (b.p, b.n), x));
    return;
  }
  if (cl_starts (name, "__builtin_")) cl_fail ("the builtin", name);
  if (c->d->k == DK_FUNC) { name = cl_own (name); cl_want (name); }
  else if (!na) {
    struct cl_list *v = cl_ex (c);
    nd_add (v->v[0], cl_n ("."));
    cl_append (o, v);
    return;
  }
  {
    char *sn = 0;
    if (c->d->k == DK_VAR && c->d->global) sn = c->d->global;
    if (!sn) sn = cl_ffname (name);
    cl_push (o, cl_call_node (sn, n));
  }
}

static void cl_offsetof (struct cs_ex *e, struct cl_list *o)
{
  struct node *n = e->src;
  struct node *a = cl_n ("address"), *b = cl_n ("address");
  struct cl_list *t = cl_ct (e->lhsty);
  long i = 1;
  cl_add_all (b, t);
  nd_add (b, cl_n ("0"));
  nd_add (b, cl_n ("."));
  while (i < n->count) {
    struct node *k = n->kids[i];
    if (cs_is (k, "[]")) {
      struct node *x = k->kids[0];
      if (x->count || !cl_digit (x->text[0])) cl_fail ("an offsetof of an index that is no number", 0);
      nd_add (b, cl_n (nd_cstr (x)));
    } else {
      struct node *nm = cs_is (k, ".") ? k->kids[0] : k;
      nd_add (b, cl_n (cl_ffname (nd_cstr (nm))));
    }
    i++;
  }
  nd_add (a, b);
  {
    struct cl_list *c = cl_l ();
    cl_w (c, cs_pick (C->target == 3, "u32", "u64"));
    cl_push (c, a);
    cl_push (o, cl_nl ("cast:", c));
  }
}
/* foldf and f16bits: a floating constant as a double (literals, parentheses, casts, + and -), then its bits as binary16 or bfloat16, rounded to nearest, ties to even */
static int cl_foldf (struct cs_ex *n, struct cl_big **nn, struct cl_big **dd, int *neg)
{
  int k = n->k;
  if (k == E_FLT) { cl_lit_ratio (cl_lit_text (n), nn, dd); return 1; }
  if (k == E_INT) { *nn = cl_big_small ((unsigned long long) n->val); *dd = cl_big_small (1); return 1; }
  if (k == E_PAREN || k == E_ICE || k == E_CAST || k == E_CONST) return cl_foldf (cl_k (n, 0), nn, dd, neg);
  if (k == E_UN && (cl_name_is (n, "-") || cl_name_is (n, "+"))) {
    if (!cl_foldf (cl_k (n, 0), nn, dd, neg)) return 0;
    if (cl_name_is (n, "-")) *neg = !*neg;
    return 1;
  }
  return 0;
}
static char *cl_f16_bits (struct cs_ex *n)
{
  struct cl_big *nn, *dd, *q;
  int neg = 0, isf16 = cs_kind (n->t) != TY_BF16;
  long long e2, e, be, shift, bias, eb, fb;
  unsigned long long m = 0, r = 0, qq, rest, half;
  long i;
  if (!cl_foldf (n, &nn, &dd, &neg)) cl_fail ("a float16's initializer that is no constant here", 0);
  eb = 8; fb = 7; bias = 127;
  if (isf16) { eb = 5; fb = 10; bias = 15; }
  if (!cl_big_zero (nn)) {
    q = cl_ratq (nn, dd, 53, 0 - 1074, &e2);
    i = q->n - 1;
    while (i >= 0) { m = (m << 32) | q->w[i]; i--; }
    /* (a double's value m * 2^e2; subnormal doubles are far below binary16's and bfloat16's) */
    e = e2 + cl_big_bits (q) - 1;
    while (m < (1ULL << 52)) { m = m << 1; e2 = e2 - 1; }
    e = e2 + 52;
    shift = 52 - fb;
    be = e + bias;
    if (be <= 0) { shift = shift + 1 - be; be = 0; }
    if (shift > 62) shift = 62;
    qq = m >> shift;
    rest = m & ((1ULL << shift) - 1);
    half = 1ULL << (shift - 1);
    if (rest > half || (rest == half && (qq & 1))) qq++;
    if (be) r = ((unsigned long long) (be - 1) << fb) + qq; else r = qq;
    if (r >= (((1ULL << eb) - 1) << fb)) r = ((1ULL << eb) - 1) << fb;
  }
  if (neg) r = r | (1ULL << (eb + fb));
  {
    static char *dg = "0123456789abcdef";
    char buf[24];
    long p = 22;
    buf[23] = 0;
    if (r == 0) { buf[p] = '0'; p--; }
    while (r) { buf[p] = dg[r & 15]; r = r >> 4; p--; }
    buf[p] = 'x'; p--;
    buf[p] = '0';
    return cl_copy ((unsigned char *) buf + p, 23 - p);
  }
}
/* fold128: a constant of 128-bit integers, its value modulo 2^128 in 32-bit
   words, neg if it is negative (wrapped by its type where a cast or an operator
   has one) */
struct cl_v128 { unsigned int w[4]; int neg; };
static struct cl_v128 *cl_128_new (void) { struct cl_v128 *r = alloc (sizeof (struct cl_v128)); r->w[0] = 0; r->w[1] = 0; r->w[2] = 0; r->w[3] = 0; r->neg = 0; return r; }
/* wrapped by the type: its width and sign, as tword says; 0 for no integer type */
static struct cl_v128 *cl_128_wrap (struct cl_v128 *v, struct cs_ty *ty)
{
  char *t = cl_join (cl_ct (ty));
  long bits = 0, i = 0;
  int sg = 0;
  struct cl_v128 *r = cl_128_new ();
  if (cl_eq (t, "i128")) { bits = 128; sg = 1; }
  else if (cl_eq (t, "u128")) bits = 128;
  else if (cl_eq (t, "long") || cl_eq (t, "i64")) { bits = 64; sg = 1; }
  else if (cl_eq (t, "u64")) bits = 64;
  else if (cl_eq (t, "int") || cl_eq (t, "i32")) { bits = 32; sg = 1; }
  else if (cl_eq (t, "u32")) bits = 32;
  else if (cl_eq (t, "short") || cl_eq (t, "i16")) { bits = 16; sg = 1; }
  else if (cl_eq (t, "u16")) bits = 16;
  else if (cl_eq (t, "char")) { bits = 8; if (C->target == 1) sg = 1; }
  else if (cl_eq (t, "i8")) { bits = 8; sg = 1; }
  else if (cl_eq (t, "u8")) bits = 8;
  else return 0;
  while (i < 4) {
    long lo = i * 32;
    if (bits >= lo + 32) r->w[i] = v->w[i];
    else if (bits > lo) r->w[i] = v->w[i] & ((1U << (bits - lo)) - 1U);
    i++;
  }
  i = (bits - 1) / 32;
  if (sg && ((r->w[i] >> ((bits - 1) % 32)) & 1U)) {
    long j = i;
    r->neg = 1;
    if (bits % 32) r->w[i] = r->w[i] | ~((1U << (bits % 32)) - 1U);
    j = i + 1;
    while (j < 4) { r->w[j] = 0xffffffffU; j++; }
  }
  return r;
}
static struct cl_v128 *cl_128_add (struct cl_v128 *a, struct cl_v128 *b, int minus)
{
  struct cl_v128 *r = cl_128_new ();
  unsigned long long c = minus;
  long i = 0;
  while (i < 4) {
    unsigned int y = b->w[i];
    if (minus) y = ~y;
    c = c + a->w[i] + y;
    r->w[i] = (unsigned int) c;
    c = c >> 32;
    i++;
  }
  return r;
}
static struct cl_v128 *cl_128_mul (struct cl_v128 *a, struct cl_v128 *b)
{
  struct cl_v128 *r = cl_128_new ();
  long i = 0;
  while (i < 4) {
    unsigned long long c = 0;
    long j = 0;
    while (i + j < 4) {
      c = c + (unsigned long long) a->w[i] * b->w[j] + r->w[i + j];
      r->w[i + j] = (unsigned int) c;
      c = c >> 32;
      j++;
    }
    i++;
  }
  return r;
}
/* << (right 0) or >> (right 1) of a's value, by s bits */
static struct cl_v128 *cl_128_shift (struct cl_v128 *a, long long s, int right)
{
  struct cl_v128 *r = cl_128_new ();
  unsigned int fill = 0;
  long i = 0;
  if (right && a->neg) fill = 0xffffffffU;
  if (s < 0) s = 0;
  if (s >= 128) { if (right) { i = 0; while (i < 4) { r->w[i] = fill; i++; } } return r; }
  while (i < 4) {
    long from = i * 32;
    long ws, bs;
    unsigned int low, high;
    if (right) from = from + s; else from = from - s;
    if (from >= 0) ws = from / 32; else ws = 0 - ((31 - from) / 32);
    bs = from - ws * 32;
    if (ws < 0) low = 0; else if (ws > 3) low = fill; else low = a->w[ws];
    if (ws + 1 < 0) high = 0; else if (ws + 1 > 3) high = fill; else high = a->w[ws + 1];
    if (bs) r->w[i] = (low >> bs) | (high << (32 - bs)); else r->w[i] = low;
    i++;
  }
  return r;
}
static struct cl_v128 *cl_fold128 (struct cs_ex *n)
{
  int k = n->k;
  long i = 0;
  if (k == E_INT) {
    struct cl_v128 *r = cl_128_new ();
    unsigned long long u = (unsigned long long) n->val;
    r->w[0] = (unsigned int) u;
    r->w[1] = (unsigned int) (u >> 32);
    return r;
  }
  if (k == E_CONST) {
    long long cv;
    if (cl_const_val (n, &cv)) {
      struct cl_v128 *r = cl_128_new ();
      unsigned long long u = (unsigned long long) cv;
      r->w[0] = (unsigned int) u;
      r->w[1] = (unsigned int) (u >> 32);
      if (cv < 0) { r->w[2] = 0xffffffffU; r->w[3] = 0xffffffffU; r->neg = 1; }
      return r;
    }
  }
  if (k == E_PAREN || k == E_CONST) return cl_fold128 (cl_k (n, 0));
  if (k == E_ICE || k == E_CAST) {
    struct cl_v128 *v = cl_fold128 (cl_k (n, 0));
    if (!v) return 0;
    return cl_128_wrap (v, n->t);
  }
  if (k == E_UN) {
    struct cl_v128 *v, *z = cl_128_new ();
    if (cl_name_is (n, "post++") || cl_name_is (n, "post--")) return 0;
    v = cl_fold128 (cl_k (n, 0));
    if (!v) return 0;
    if (cl_name_is (n, "-")) return cl_128_wrap (cl_128_add (z, v, 1), n->t);
    if (cl_name_is (n, "~")) { while (i < 4) { z->w[i] = ~v->w[i]; i++; } return cl_128_wrap (z, n->t); }
    if (cl_name_is (n, "+")) return cl_128_wrap (v, n->t);
    return 0;
  }
  if (k == E_BIN) {
    struct cl_v128 *a = cl_fold128 (cl_k (n, 0)), *b = cl_fold128 (cl_k (n, 1)), *r = cl_128_new ();
    if (!a || !b) return 0;
    if (cl_name_is (n, "|")) { while (i < 4) { r->w[i] = a->w[i] | b->w[i]; i++; } }
    else if (cl_name_is (n, "&")) { while (i < 4) { r->w[i] = a->w[i] & b->w[i]; i++; } }
    else if (cl_name_is (n, "^")) { while (i < 4) { r->w[i] = a->w[i] ^ b->w[i]; i++; } }
    else if (cl_name_is (n, "+")) r = cl_128_add (a, b, 0);
    else if (cl_name_is (n, "-")) r = cl_128_add (a, b, 1);
    else if (cl_name_is (n, "*")) r = cl_128_mul (a, b);
    else if (cl_name_is (n, "<<") || cl_name_is (n, ">>")) {
      long long s = b->w[0];
      if (b->w[1] || b->w[2] || b->w[3]) s = 128;
      r = cl_128_shift (a, s, cl_name_is (n, ">>"));
    }
    else return 0;
    return cl_128_wrap (r, n->t);
  }
  return 0;
}
/* as a number node: the value below 2^64 in hex, else -N (N at most 2^63) */
static struct node *cl_128_node (struct cl_v128 *v)
{
  static char *dg = "0123456789abcdef";
  char buf[24];
  long p = 22;
  unsigned long long u;
  buf[23] = 0;
  if (v->w[2] == 0 && v->w[3] == 0) {
    u = ((unsigned long long) v->w[1] << 32) | v->w[0];
    if (u == 0) { buf[p] = '0'; p--; }
    while (u) { buf[p] = dg[u & 15]; u = u >> 4; p--; }
    buf[p] = 'x'; p--;
    buf[p] = '0';
    return cl_n (cl_copy ((unsigned char *) buf + p, 23 - p));
  }
  {
    struct cl_v128 *z = cl_128_new (), *m = cl_128_add (z, v, 1);
    if (m->w[2] || m->w[3] || m->w[1] > 0x80000000U || (m->w[1] == 0x80000000U && m->w[0])) cl_fail ("a 128-bit constant wider than 64 bits in a global, which ttpc has no form of", 0);
    u = ((unsigned long long) m->w[1] << 32) | m->w[0];
    while (u) { buf[p] = '0' + (char) (u % 10); u = u / 10; p--; }
    buf[p] = '-';
    return cl_n (cl_copy ((unsigned char *) buf + p, 23 - p));
  }
}
static void cl_expr (struct cs_ex *n, struct cl_list *o)
{
  int k = n->k;

  if ((k == E_UN && cl_name_is (n, "&")) || k == E_SIZEOF) {
    if (k == E_SIZEOF) {

      struct cs_ty *t = n->lhsty;
      char *w = cl_name_of (n);
      if (!t) t = cl_k (n, 0)->t;
      if (cl_eq (w, "__alignof")) w = "alignof";
      if (!n->lhsty && cl_eq (w, "sizeof") && cs_kind (t) == TY_ARRAY && cs_canon (t)->n == -2) {
        struct cs_ex *v = cl_strip (cl_k (n, 0));
        while (v->k == E_PAREN) v = cl_strip (cl_k (v, 0));
        if (v->k == E_REF) { struct cl_list *x = cl_ex (v); cl_push (o, cl_nl ("sizeof", x)); return; }
      }
      cl_push (o, cl_nl (w, cl_ct (t)));
      return;
    }
    {
      struct cs_ex *e = cl_k (n, 0), *s = cl_strip (e);
      cl_softfp (n);
      while (s->k == E_PAREN) s = cl_strip (cl_k (s, 0));
      if (C->in_global && s->k == E_IDX) {
        struct cs_ex *b = cl_k (s, 0), *i = cl_k (s, 1), *x = cl_strip (i);
        long long cv;
        if (cl_strip (b)->k == E_REF) {
          struct cl_list *l = cl_l (), *e0 = cl_ex (b);
          cl_append (l, e0);
          cl_push (l, cl_n ("+"));
          if (x->k == E_REF && x->d && x->d->k == DK_ENUMC && cl_has (&C->enumval, cl_dn (x->d))) cl_push (l, cl_num_node (cl_find (&C->enumval, cl_dn (x->d))->num));
          else if (cl_int_const (i, &cv)) cl_push (l, cl_num_node (cv));
          else cl_itemx (i, l);
          cl_push (o, cl_nl (":", l));
              return;
        }
      }
      cl_push (o, cl_nl ("address", cl_ex (e)));
      return;
    }
  }
  cl_softfp (n);
  /* (a 128-bit integer's initializer: ttpc reads a number there, -N all ones above it) */
  if (C->in_global && (k == E_BIN || k == E_UN || k == E_CAST || k == E_ICE || k == E_PAREN || k == E_INT) && (cs_kind (n->t) == TY_INT128 || cs_kind (n->t) == TY_UINT128) && !cs_quals (n->t)) {
    struct cl_v128 *v = cl_fold128 (n);
    if (!v) cl_fail ("a 128-bit integer's initializer that is no constant here", 0);
    cl_push (o, cl_128_node (v));
    return;
  }
  /* (a float16's or bfloat16's initializer: its bits, a number, what ttpc stores of a global; ttpc does no conversion at compile time) */
  if (C->in_global && (k == E_UN || k == E_CAST || k == E_ICE || k == E_PAREN || k == E_FLT || k == E_INT) && (cs_kind (n->t) == TY_FLOAT16 || cs_kind (n->t) == TY_BF16 || cs_kind (n->t) == TY_HALF) && !cs_quals (n->t)) {
    cl_push (o, cl_n (cl_f16_bits (n)));
    return;
  }
  if (C->in_global && C->target != 3 && (k == E_BIN || k == E_UN || k == E_CAST || k == E_ICE) && cl_ftyp (cl_tword (n)) && cl_ldinside (n)) {
    struct cl_fv *v = cl_fold (n);
    if (v) {
      struct node *f = cl_femit (v, cl_tword (n));
      if (f) { cl_push (o, f); return; }
    }
  }
  if (k == E_ADDRLABEL) { cl_push (o, cl_n1 ("address", cl_n (cl_label_of (n->name, n->nlen, n->lk)))); return; }
  if (C->in_global && k == E_ICE && n->op == CK_ARRAYTOPOINTERDECAY) {
    struct cs_ex *s = cl_strip (cl_k (n, 0));
    if (s->k == E_MEM || s->k == E_IDX) { cl_push (o, cl_nl ("address", cl_ex (cl_k (n, 0)))); return; }
  }
  if (k == E_ICE && n->op == CK_FUNCTIONTOPOINTERDECAY) { cl_push (o, cl_nl ("address", cl_ex (cl_k (n, 0)))); return; }
  /* (an extern array that no C defines, cast to an integer: its address; it may be a label of asm, and a name of asm alone is a call in ff) */
  if (k == E_CAST && n->op == CK_POINTERTOINTEGRAL) {
    struct cs_ex *i = cl_k (n, 0);
    while (i->k == E_PAREN) i = cl_k (i, 0);
    if (i->k == E_ICE && i->op == CK_ARRAYTOPOINTERDECAY) {
      struct cs_ex *r = cl_strip (cl_k (i, 0));
      if (r->k == E_REF && r->d && r->d->k == DK_VAR && (!r->d->local || (r->d->sp && r->d->sp->sc == SC_EXTERN)) && !r->d->global && !cl_has (&C->var, cl_own (cl_dn (r->d)))) {
        struct cl_list *v = cl_l ();
        cl_push (v, cl_nl ("address", cl_ex (r)));
        cl_push (o, cl_cast_node (cl_ct (n->t), v));
        return;
      }
    }
  }
  /* (to and from a 128-bit integer, written: a word is no pair) */
  if (k == E_ICE && n->op == CK_INTEGRALCAST && (cs_kind (n->t) == TY_INT128 || cs_kind (n->t) == TY_UINT128 || cs_kind (cl_k (n, 0)->t) == TY_INT128 || cs_kind (cl_k (n, 0)->t) == TY_UINT128)) {
    struct cl_list *to = cl_ct (n->t), *from = cl_ct (cl_k (n, 0)->t);
    char *tj = cl_join (to), *fj = cl_join (from);
    if (!cl_eq (tj, fj)) {
      struct cl_list *x = cl_l ();
      cl_itemx (cl_k (n, 0), x);
      cl_push (o, cl_cast_node (to, x));
      return;
    }
  }
  if (C->target == 3 && k == E_ICE && n->op == CK_INTEGRALCAST) {
    struct cl_list *to = cl_ct (n->t), *from = cl_ct (cl_k (n, 0)->t);
    char *tj = cl_join (to), *fj = cl_join (from);
    if ((cl_eq (tj, "i64") || cl_eq (tj, "u64")) && !cl_eq (fj, "i64") && !cl_eq (fj, "u64")) {
      struct cl_list *x = cl_l ();
      cl_itemx (cl_k (n, 0), x);
      cl_push (o, cl_cast_node (to, x));
      return;
    }
  }
  /* (arm: a float from a double's literal, that literal as a float's: a double is a type in memory there, which a function that does not name it has no room for) */
  if (C->target == 3 && k == E_ICE && n->op == CK_FLOATINGCAST && cs_kind (n->t) == TY_FLOAT && !cs_quals (n->t) && cl_k (n, 0)->k == E_FLT) {
    struct cl_big *nn, *dd;
    cl_lit_ratio (cl_lit_text (cl_k (n, 0)), &nn, &dd);
    cl_push (o, cl_n (cl_hexfloat_of (nn, dd, "float")));
    return;
  }
  if (k == E_ICE && (n->op == CK_INTEGRALTOFLOATING || n->op == CK_FLOATINGTOINTEGRAL || n->op == CK_FLOATINGCAST)) {
    struct cs_ex *e = cl_strip (cl_k (n, 0));
    struct cl_list *x;
    if (C->in_global) {
      char *lit = cl_special_float (cl_k (n, 0), n);
      if (lit) { cl_push (o, cl_n (lit)); return; }
      if ((cl_isld (n) || cl_eq (cl_tword (n), "float128")) && e->k == E_FLT && (cl_eq (cl_tword (e), "float") || cl_eq (cl_tword (e), "double"))) {
        char *l;
        if (C->target == 3 || cl_eq (cl_tword (e), "double")) l = cl_ldround (cl_lit_text (e), 53, -1074, 1023);
        else l = cl_ldround (cl_lit_text (e), 24, -149, 127);
        if (cl_eq (cl_tword (n), "float128")) l = cl_with_suffix (l, "Q");
        cl_push (o, cl_n (l));
        return;
      }
      lit = cl_narrowlit (n, e);
      if (lit) { cl_push (o, cl_n (lit)); return; }
    }
    {
      struct cl_list *t = cl_ct (n->t);
      x = cl_l ();
      cl_itemx (cl_k (n, 0), x);
      cl_push (o, cl_cast_node (t, x));
    }
    return;
  }
  if ((k == E_ICE || k == E_CAST) && (n->op == CK_INTEGRALTOBOOLEAN || n->op == CK_POINTERTOBOOLEAN || n->op == CK_FLOATINGTOBOOLEAN)) {
    struct cs_ex *e = cl_k (n, 0);
    struct cl_list *x = cl_l ();
    char *zero = "0";
    if (n->op == CK_FLOATINGTOBOOLEAN) {
      if (cl_isld (e)) zero = cl_ldhexfloat ("0");
      else if (cl_eq (cl_tword (e), "float128")) zero = "0x0p+0Q";
      else zero = cl_cat ("0x0p+0", cs_pick (cl_eq (cl_tword (e), "float"), "f", ""));
    }
    cl_operand (e, cl_prec ("!="), 0, x);
    cl_push (x, cl_n ("!="));
    cl_push (x, cl_n (zero));
    cl_push (o, cl_nl (":", x));
    return;
  }
  if (k == E_ICE || k == E_CONST) { cl_expr (cl_k (n, 0), o); return; }
  if (k == E_PAREN) { cl_push (o, cl_nl (":", cl_ex (cl_k (n, 0)))); return; }
  if (k == E_INT) {
    int c = cs_kind (n->t);
    char *v = cs_is_signed (n->t) ? cl_num (n->val) : cl_unum ((unsigned long long) n->val);
    if (c == TY_UINT) { cl_push (o, cl_n1 ("U", cl_n (v))); return; }
    if (c == TY_LONG) { cl_push (o, cl_n1 ("L", cl_n (v))); return; }
    if (c == TY_ULONG) { cl_push (o, cl_n1 ("UL", cl_n (v))); return; }
    if (c == TY_LLONG) { cl_push (o, cl_n1 ("LL", cl_n (v))); return; }
    if (c == TY_ULLONG) { cl_push (o, cl_n1 ("ULL", cl_n (v))); return; }
    {
      struct cl_list *t = cl_ct (n->t);
      if (t->n == 1 && !cl_is (t->v[0], "int")) cl_push (o, cl_n1 ((char *) t->v[0]->text, cl_n (v)));
      else cl_push (o, cl_n (v));
    }
    return;
  }
  if (k == E_CHR) {
    long long v = n->val;
    if (v >= 2147483648LL && cs_kind (n->t) == TY_INT) v = v - 4294967296LL;
    cl_push (o, cl_num_node (v));
    return;
  }
  if (k == E_TRAIT) { cl_push (o, cl_num_node (n->val ? 1 : 0)); return; }
  if (k == E_FLT) {
    if (cl_isld (n)) { cl_push (o, cl_n (cl_ldhexfloat (cl_lit_text (n)))); return; }
    if (cl_eq (cl_tword (n), "float128")) { cl_push (o, cl_n (cl_with_suffix (cl_ldround (cl_lit_text (n), 113, -16494, 16383), "Q"))); return; }
    /* (float16's: a double's, cast; ff has no other literal of it) */
    if (cs_kind (n->t) == TY_FLOAT16 || cs_kind (n->t) == TY_BF16) {
      struct cl_big *nn, *dd;
      struct cl_list *v = cl_l ();
      cl_lit_ratio (cl_lit_text (n), &nn, &dd);
      cl_push (v, cl_n (cl_hexfloat_of (nn, dd, "double")));
      cl_push (o, cl_cast_node (cl_ct (n->t), v));
      return;
    }
    cl_push (o, cl_n (cl_hexfloat (n)));
    return;
  }
  if (k == E_STR) { cl_string_value (n, o); return; }
  if (k == E_PREDEF) { cl_string_bytes (n->text, n->tlen, o); return; }
  if (k == E_REF) {
    struct cs_decl *d = n->d;
    char *nm = cl_dn (d);
    if (d->k == DK_ENUMC) { char *tag = cl_get (&C->enumof, nm); if (tag) cl_set (&C->wanttag, tag); }
    if (d->k == DK_VAR && d->global) { cl_push (o, cl_n (d->global)); return; }
    if (d->k == DK_VAR && !d->local && cl_has (&C->regvar, nm)) { cl_push (o, cl_n (cl_get (&C->regvar, nm))); return; }
    if (d->k == DK_FUNC || (d->k == DK_VAR && !d->local)) {
      char *g = cl_own (nm);
      cl_want (g);
      cl_push (o, cl_n (cl_ffname (g)));
      return;
    }
    if (d->k == DK_ENUMC) {
      struct node *r = cl_n (cl_ffname (nm));
      struct cl_list *l = cl_get (&C->enumref, nm);
      if (!l) { l = cl_l (); cl_put (&C->enumref, nm, l); }
      if (C->cu) cl_put_new (&C->enumunit, nm, C->cu);
      cl_push (l, r);
      cl_push (o, r);
      return;
    }
    cl_push (o, cl_n (cl_ffname (nm)));
    return;
  }
  if (k == E_OFFSETOF) { cl_offsetof (n, o); return; }
  if (k == E_BIN || k == E_CASS) {
    char *op = cl_name_of (n);
    struct cs_ex *l = cl_k (n, 0), *r = cl_k (n, 1);
    if (cl_eq (op, ",")) {
      struct cl_list *x = cl_l ();
      cl_itemx (l, x);
      cl_itemx (r, x);
      cl_push (o, cl_nl (":", x));
      return;
    }
    if (!cl_prec (op)) cl_fail ("the operator", op);
    cl_operand (l, cl_prec (op), 0, o);
    cl_push (o, cl_n (op));
    cl_operand (r, cl_prec (op), 1, o);
    return;
  }
  if (k == E_UN) {
    char *op = cl_name_of (n);
    struct cs_ex *e = cl_k (n, 0);
    /* (the result of a function of no C, an asm function's on aarch64, has no type for ttpc: cast) */
    if (cl_eq (op, "*") && C->target == 2) {
      struct cs_ex *c = e;
      while (c->k == E_ICE || c->k == E_PAREN) c = cl_k (c, 0);
      if (c->k == E_CALL) {
        struct cs_ex *f = cl_k (c, 0);
        while (f->k == E_ICE || f->k == E_PAREN) f = cl_k (f, 0);
        if (f->k == E_REF && f->d && !cl_has (&C->fn, cl_dn (f->d))) {
          struct cl_list *v = cl_l ();
          cl_itemx (e, v);
          cl_push (o, cl_n1 ("content", cl_cast_node (cl_ct (e->t), v)));
          return;
        }
      }
    }
    if (cl_eq (op, "*")) { cl_push (o, cl_nl ("content", cl_ex (e))); return; }
    if (cl_eq (op, "-") || cl_eq (op, "!") || cl_eq (op, "~")) { cl_push (o, cl_n (op)); cl_push (o, cl_atom (e)); return; }
    if (cl_eq (op, "++") || cl_eq (op, "--")) { cl_push (o, cl_n (op)); cl_push (o, cl_atom (e)); return; }
    if (cl_eq (op, "post++")) { cl_push (o, cl_atom (e)); cl_push (o, cl_n ("++")); return; }
    if (cl_eq (op, "post--")) { cl_push (o, cl_atom (e)); cl_push (o, cl_n ("--")); return; }
    if (cl_eq (op, "+") || cl_eq (op, "__extension__")) { cl_expr (e, o); return; }
    if (cl_eq (op, "__real")) { struct cl_list *x = cl_l (); cl_itemx (e, x); cl_push (o, cl_nl ("real", x)); return; }
    if (cl_eq (op, "__imag")) { struct cl_list *x = cl_l (); cl_itemx (e, x); cl_push (o, cl_nl ("imag", x)); return; }
    cl_fail ("the operator", op);
  }
  if (k == E_CAST) {
    if (C->in_global) { char *lit = cl_narrowlit (n, cl_strip (cl_k (n, 0))); if (lit) { cl_push (o, cl_n (lit)); return; } }
    {
      struct cl_list *t = cl_ct (n->t), *x = cl_l ();
      cl_itemx (cl_k (n, 0), x);
      cl_push (o, cl_cast_node (t, x));
    }
    return;
  }
  if (k == E_IDX || k == E_MEM) {
    struct cl_list *path = cl_l ();
    struct cs_ex *base = n;
    for (;;) {
      if (base->k == E_MEM) {
        if (base->nlen) { struct cl_list *one = cl_l (); cl_push (one, cl_n (cl_ffname (cl_name_of (base)))); cl_unshift (path, one); }
        base = cl_strip (cl_k (base, 0));
        continue;
      }
      if (base->k == E_IDX) {
        struct cs_ex *s0 = cl_strip (cl_k (base, 0));
        if (s0->k == E_REF || s0->k == E_MEM || s0->k == E_IDX) {
          struct cl_list *ix = cl_l ();
          int isrec = cl_spelled_rec (base->t);
          cl_itemx (cl_k (base, 1), ix);
          if ((ix->n > 1 || !cl_digit (ix->v[0]->text[0])) && !cl_is (ix->v[0], ":") && isrec) {
            struct node *h = cl_nl (":", ix);
            ix = cl_l ();
            cl_push (ix, h);
          }
          cl_unshift (path, ix);
          base = s0;
          continue;
        }
      }
      break;
    }
    while (base->k == E_PAREN) base = cl_strip (cl_k (base, 0));
    if (base->k == E_REF && path->n) {
      struct cl_list *b = cl_ex (base);
      cl_add_all (b->v[0], path);
      cl_append (o, b);
      return;
    }
    if (path->n && base != n) {
      struct cl_list *b = cl_ex (base);
      struct node *h;
      if (b->n > 1) { struct node *w = cl_nl (":", b); b = cl_l (); cl_push (b, w); }
      h = b->v[0];
      nd_add (h, cl_n ("."));
      cl_add_all (h, path);
      cl_append (o, b);
      return;
    }
    if (k == E_IDX && base == n) {
      struct cl_list *x = cl_ex (cl_k (n, 0));
      cl_push (x, cl_n ("+"));
      cl_push (x, cl_atom (cl_k (n, 1)));
      cl_push (o, cl_n1 ("content", cl_nl (":", x)));
      return;
    }
    cl_fail ("a path from that", 0);
  }
  if (k == E_CALL) { cl_call (n, o); return; }
  if (k == E_ATOMIC) {
    struct cl_list *t = cl_ct (n->t);
    char *j = cl_join (t);
    if (cl_eq (j, "void") || cl_eq (j, "u8") || cl_eq (j, "u16") || cl_eq (j, "u32") || cl_eq (j, "u64")) { cl_atomic (n, o); return; }
    {
      struct cl_list *v = cl_l ();
      cl_atomic (n, v);
      cl_push (o, cl_cast_node (t, v));
    }
    return;
  }
  if (k == E_VAARG) {
    struct cl_list *x = cl_l ();
    cl_itemx (cl_k (n, 0), x);
    cl_append (x, cl_ct (n->t));
    cl_push (o, cl_nl ("va_arg", x));
    return;
  }
  if (k == E_BCOND) {
    cl_operand (cl_k (n, 0), 4, 0, o);
    cl_push (o, cl_n ("?"));
    cl_push (o, cl_n (":"));
    cl_operand (cl_k (n, 3), 3, 1, o);
    return;
  }
  if (k == E_COND) {
    cl_operand (cl_k (n, 0), 4, 0, o);
    cl_push (o, cl_n ("?"));
    cl_operand (cl_k (n, 1), 4, 0, o);
    cl_push (o, cl_n (":"));
    cl_operand (cl_k (n, 2), 3, 1, o);
    return;
  }
  if (k == E_STMTX) {
    int found = 0;
    cl_syscall (n->st, o, &found);
    if (found) return;
    {
      struct cl_list *x = cl_l ();
      cl_body (n->st, x);
      cl_push (o, cl_nl (":", x));
    }
    return;
  }
  if (k == E_CLIT) {
    struct cs_ex *il = cl_k (n, 0);
    if (C->has_cur_global) {
      char *g;
      struct cs_ex *lit = il;
      struct cs_decl *d = alloc (sizeof (struct cs_decl));
      struct cl_ent *ent = cl_make (&C->literals, C->cur_global);
      ent->num = ent->num + 1;
      g = cl_cat3 (cl_ffname (C->cur_global), " literal ", cl_num (ent->num));
      d->k = DK_VAR;
      d->t = n->t;
      d->init = lit;
      cl_out (cl_decl (d, 1, g));
      cl_push (o, cl_n (g));
      return;
    }

    if (C->cur_fn && cl_anon_union_init (il) && cl_const_init (il)) {
      char *g;
      struct cs_decl *d = alloc (sizeof (struct cs_decl));
      struct cl_ent *ent = cl_make (&C->literals, C->cur_fn);
      ent->num = ent->num + 1;
      g = cl_cat3 (cl_ffname (C->cur_fn), " literal ", cl_num (ent->num));
      d->k = DK_VAR;
      d->t = n->t;
      d->init = il;
      cl_out (cl_decl (d, 1, g));
      cl_push (o, cl_n (g));
      return;
    }
    {
      struct cl_list *t = cl_ct (n->t), *i = cl_l ();
      char *h = (char *) t->v[0]->text;
      if (cl_eq (h, "array") || cl_eq (h, "vector")) {
        struct node *a = cl_n (h);
        long j = 1;
        while (j < t->n) { nd_add (a, t->v[j]); j++; }
        cl_init (il, i);
        cl_add_all (a, i);
        cl_push (o, a);
        return;
      }
      if (t->n != 1 || !(!cl_scalar_word (h) || (!cl_eq (h, "address") && !cl_eq (h, "array")))) cl_fail ("a compound literal of that type", 0);
      cl_init (il, i);
      if (!i->n) cl_push (i, cl_n ("0"));
      cl_push (o, cl_nl (h, i));
    }
    return;
  }
  /* C11's _Generic: generic / x / an association per type (its type words and a colon, holding its value) / default: */
  if (k == E_GENERIC) {
    struct cl_list *g = cl_l ();
    long q = 0;
    cl_push (g, cl_atom (cl_k (n, 0)));
    while (q < n->nk - 1) {
      char *w = "default:";
      if (n->tys[q]) w = cl_cat (cl_join (cl_ct (n->tys[q])), ":");
      cl_push (g, cl_nl (w, cl_ex (cl_k (n, q + 1))));
      q++;
    }
    cl_push (o, cl_nl ("generic", g));
    return;
  }
  cl_fail ("the expression of kind", cl_num (k));
}

static void cl_init_item (struct cs_ex *n, struct cl_list *o);
static void cl_init_items (struct cs_ex *l, struct cl_list *o)
{
  long nk = l->nk, i = 0;

  while (nk > 0 && l->kid[nk - 1]->k == E_IVI) nk--;

  if (l->fd && cs_kind (l->t) == TY_UNION) {
    struct cs_field *f = cs_canon (l->t)->rec->first;
    while (f && f != l->fd) {
      struct cl_list *t = cl_ct (f->t);
      if ((t->n == 1 && cl_scalar_word ((char *) t->v[0]->text)) || cl_is (t->v[0], "address")) cl_push (o, cl_n ("0"));
      else cl_push (o, cl_n (":"));
      f = f->nxt;
    }
  }
  while (i < nk) { cl_init_item (cl_k (l, i), o); i++; }
}
static void cl_init_item (struct cs_ex *n, struct cl_list *o)
{
  struct cs_ex *s = cl_strip (n), *str;
  if (s->k == E_INIT) {
    struct cl_list *x = cl_l (), *g = cl_l ();
    cl_init_items (s, x);
    cl_grouped (255, x, g);
    cl_push (o, cl_nl (":", g));
    return;
  }
  str = cl_bare_string (n);
  if (str) {
    struct cl_list *x = cl_l (), *g = cl_l ();
    cl_array_text (str, x);
    cl_grouped (255, x, g);
    cl_push (o, cl_nl (":", g));
    return;
  }
  if (s->k == E_IVI) {
    struct cl_list *t = cl_ct (s->t);
    if ((t->n == 1 && cl_scalar_word ((char *) t->v[0]->text)) || cl_is (t->v[0], "address") || cs_kind (s->t) == TY_ENUM) cl_push (o, cl_n ("0"));
    else cl_push (o, cl_n (":"));
    return;
  }
  {
    struct cl_list *e = cl_l ();
    cl_itemx (n, e);
    cl_push (o, cl_one (e));
  }
}
static void cl_init (struct cs_ex *n, struct cl_list *o)
{
  struct cs_ex *s = cl_strip (n), *str;
  if (s->k == E_INIT && s->nk == 1) {
    str = cl_bare_string (cl_k (s, 0));
    if (str) { cl_array_text (str, o); return; }
  }
  if (s->k == E_INIT) { cl_init_items (s, o); return; }
  str = cl_bare_string (n);
  if (str) { cl_array_text (str, o); return; }
  cl_itemx (n, o);
}
static struct node *cl_align_node (int has, long long v)
{
  if (!has) return 0;
  return cl_n1 ("align", cl_num_node (v));
}

/* the reference to a name in a count's expression (cs_ty's countx): the one declaration of that name there */
static struct cs_ex *cl_count_ref (struct cs_ex *e, char *nm)
{
  long i = 0;
  if (!e) return 0;
  if (e->k == E_REF && e->d && cl_eq (cl_dn (e->d), nm)) return e;
  while (i < e->nk) {
    struct cs_ex *f = cl_count_ref (e->kid[i], nm);
    if (f) return f;
    i++;
  }
  return 0;
}
/* a number's text as clang's type prints it, in decimal; c2ff.pl stops on a suffix */
static char *cl_count_num (char *s)
{
  long long v = 0;
  long i = 0;
  int base = 10;
  if (cl_all_digits (s) && (s[0] != '0' || !s[1])) return s;
  if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) { base = 16; i = 2; }
  else if (s[0] == '0') base = 8;
  while (s[i]) {
    int dg = -1;
    if (s[i] >= '0' && s[i] <= '9') dg = s[i] - '0';
    else if (s[i] >= 'a' && s[i] <= 'f') dg = s[i] - 'a' + 10;
    else if (s[i] >= 'A' && s[i] <= 'F') dg = s[i] - 'A' + 10;
    if (dg < 0 || dg >= base) cl_fail ("the count of a variable-length array of a number", s);
    v = v * base + dg;
    i++;
  }
  return cl_num (v);
}
/* as c2ff.pl's vla_count: names, numbers, calls, parentheses and + - * / % < > <= >= == != ?:, as ff infix, which reads them as C does; anything else stops */
static void cl_vla_count (struct node *p, struct cs_ex *ce, struct cl_list *o)
{
  long par = c_parens_of (p);
  struct cl_list *x = cl_l ();
  if (p->count == 0) {
    char *s = nd_cstr (p);
    if (s[0] == '"' || s[0] == '\'') cl_fail ("the count of a variable-length array", s);
    if (cl_alpha (s[0])) {
      struct cs_ex *r = cl_count_ref (ce, s);
      if (!r) cl_fail ("the count of a variable-length array: no such name", s);
      cl_expr (r, x);
    }
    else cl_push (x, cl_n (cl_count_num (s)));
  } else if (cs_is (p, "sizeof") && p->count == 1 && (cs_is (p->kids[0], "str") || (!p->kids[0]->count && p->kids[0]->text[0] == '"'))) {
    struct cs_ex *e = cs_ex_of (p->kids[0]);
    cl_push (x, cl_num_node (cs_canon (e->t)->n));
  } else if (p->count == 2 && (cs_is (p, "+") || cs_is (p, "-") || cs_is (p, "*") || cs_is (p, "/") || cs_is (p, "%") || cs_is (p, "<") || cs_is (p, ">") || cs_is (p, "<=") || cs_is (p, ">=") || cs_is (p, "==") || cs_is (p, "!="))) {
    cl_vla_count (p->kids[0], ce, x);
    cl_push (x, cl_n (nd_cstr (p)));
    cl_vla_count (p->kids[1], ce, x);
  } else if (cs_is (p, "?") && p->count == 3) {
    /* (a ?: in the middle of another, without parentheses, c2ff.pl stops on) */
    if (cs_is (p->kids[1], "?") && !c_parens_of (p->kids[1])) cl_fail ("the count of a variable-length array: ?: in ?:", 0);
    cl_vla_count (p->kids[0], ce, x);
    cl_push (x, cl_n ("?"));
    cl_vla_count (p->kids[1], ce, x);
    cl_push (x, cl_n (":"));
    cl_vla_count (p->kids[2], ce, x);
  } else if (cs_is (p, "()") && p->count >= 1 && p->kids[0]->count == 0 && cl_alpha (p->kids[0]->text[0]) && !c_parens_of (p->kids[0])) {
    /* a call, as cl_call's of a function by its name */
    struct cl_list *args = cl_l ();
    char *nm = nd_cstr (p->kids[0]);
    struct cs_ex *f = cl_count_ref (ce, nm);
    long i = 1;
    if (!f || !f->d || f->d->k != DK_FUNC) cl_fail ("the count of a variable-length array: a call of what is no function", nm);
    while (i < p->count) {
      struct cl_list *y = cl_l ();
      cl_vla_count (p->kids[i], ce, y);
      if (y->n == 1) cl_append (args, y); else cl_push (args, cl_nl (":", y));
      i++;
    }
    if (cl_starts (nm, "__builtin_mem") || cl_starts (nm, "__builtin_str") || cl_starts (nm, "__builtin_stp")) nm = nm + 10;
    if (cl_starts (nm, "__builtin_")) cl_fail ("the count of a variable-length array: the builtin", nm);
    nm = cl_own (nm);
    cl_want (nm);
    cl_push (x, cl_nl (cl_ffname (nm), args));
  } else cl_fail ("the count of a variable-length array of that form", nd_cstr (p));
  while (par > 0) { struct node *h = cl_nl (":", x); x = cl_l (); cl_push (x, h); par--; }
  cl_append (o, x);
}
static int cl_holds_addrlabel (struct cs_ex *e)
{
  long i = 0;
  if (!e) return 0;
  if (e->k == E_ADDRLABEL) return 1;
  while (i < e->nk) { if (cl_holds_addrlabel (e->kid[i])) return 1; i++; }
  return 0;
}
static struct node *cl_decl (struct cs_decl *v, int global, char *name)
{
  struct cl_list *t, *i = cl_l (), *tls = cl_l (), *all = cl_l ();
  int saved = C->in_global;
  struct cs_ex *init = 0;
  char *j, *nm;
  struct cs_ty *vc = cs_canon (v->t);
  if (name) nm = name; else nm = cl_ffname (cl_dn (v));
  long long vcv;
  if (!global && vc->k == TY_ARRAY && vc->n == -2 && vc->count && !cl_vla_const (vc, &vcv)) {
    struct cl_list *c = cl_l (), *x = cl_l ();
    cl_vla_count (vc->count, vc->countx, c);
    cl_w (x, "array");
    cl_ctype (vc->to, x);
    if (c->n > 1 || !cl_all_digits ((char *) c->v[0]->text)) cl_push (x, cl_nl (":", c));
    else cl_append (x, c);
    return cl_nl (cl_cat (nm, ":"), x);
  }
  t = cl_ct (v->t);
  j = cl_join (t);
  if (v->init) { v->init = cl_p (v->init); init = v->init; }
  C->in_global = global;
  if (init) cl_init (init, i);
  if (!global && !i->n && init && cl_strip (init)->k == E_INIT) cl_push (i, cl_n (":"));
  if (global && i->n > 1 && cl_strip (init)->k != E_INIT && !cl_bare_string (init)) {
    struct node *h = cl_nl (":", i);
    i = cl_l ();
    cl_push (i, h);
  }
  if ((cl_eq (j, "address char") || cl_eq (j, "address u8")) && i->n && (!i->v[0]->count || cl_is (i->v[0], "content") || cl_is (i->v[0], "address")) && !cl_bare_string (init)) {
    struct node *h = cl_nl (":", i);
    i = cl_l ();
    cl_push (i, h);
  }
  C->in_global = saved;
  if (v->sp) {
    struct node *alnv = cl_align_node (v->sp->hasaln, v->sp->alnmax);
    if (alnv) cl_push (tls, alnv);
    if (!global && v->sp->cleanup) {
      char *g = cl_own (v->sp->cleanup);
      cl_want (g);
      cl_push (tls, cl_n1 ("cleanup", cl_n (cl_ffname (g))));
    }
    if (global && v->sp->section && cl_section_name_ok (v->sp->section)) { cl_push (tls, cl_n ("section")); cl_push (tls, cl_n (v->sp->section)); }
  }
  if (global && v->tls) cl_push (tls, cl_n ("thread local"));
  cl_append (all, tls);
  cl_append (all, t);
  cl_grouped (255 - t->n - tls->n, i, all);
  return cl_nl (cl_cat (nm, ":"), all);
}

static void cl_place (long off, char **file, long *line, int *found)
{
  long lo = 0, hi = T->nmk - 1, m = -1, i, nline;
  *found = 0;
  if (off <= 0) return;
  off = off - 1;
  while (lo <= hi) { long mid = (lo + hi) / 2; if (T->mk[mid].off <= off) { m = mid; lo = mid + 1; } else hi = mid - 1; }
  if (m < 0) return;
  nline = T->mk[m].line;
  i = T->mk[m].off;
  while (i < off) { if (T->src[i] == '\n') nline++; i++; }
  {

    struct cs_buf b;
    long k = 0;
    cs_b_init (&b);
    while (k < T->mk[m].fl) {
      if (T->mk[m].f[k] == '\\' && k + 1 < T->mk[m].fl) k++;
      cs_b_byte (&b, T->mk[m].f[k]);
      k++;
    }
    *file = cl_copy (b.p, b.n);
  }
  *line = nline;
  *found = 1;
}
static void cl_line_at (long off, struct cl_list *o)
{
  char *f;
  long ln;
  int found;
  cl_place (off, &f, &ln, &found);
  if (!found || cstrlen (f) > 255) return;
  if (C->lfile && cl_eq (f, C->lfile) && ln == C->lline) return;
  {
    struct node *l = cl_n ("line");
    if (!C->lfile || !cl_eq (f, C->lfile)) nd_add (l, cl_n (f));
    nd_add (l, cl_num_node (ln));
    cl_push (o, l);
  }
  C->lfile = f;
  C->lline = ln;
}
static void cl_lstmt (struct cs_st *n, struct cl_list *o)
{
  cl_line_at (n->off, o);
  cl_stmt (n, o);
}
static void cl_body (struct cs_st *cs, struct cl_list *o)
{
  long i = 0;
  while (i < cs->nk) { cl_lstmt (cs->kid[i], o); i++; }
}
static void cl_sub_body (struct cs_st *s, struct cl_list *o) { if (s->k == S_BLOCK) cl_body (s, o); else cl_lstmt (s, o); }
static int cl_returns_twice (struct cs_ex *e)
{
  struct cs_ex *c, *f;
  char *nm;
  if (!e) return 0;
  c = cl_strip (e);
  if (c->k != E_CALL) return 0;
  f = cl_strip (cl_k (c, 0));
  if (f->k != E_REF) return 0;
  nm = cl_dn (f->d);
  return cl_eq (nm, "setjmp") || cl_eq (nm, "_setjmp") || cl_eq (nm, "__sigsetjmp") || cl_eq (nm, "sigsetjmp") || cl_eq (nm, "__builtin_setjmp") || cl_eq (nm, "getcontext") || cl_eq (nm, "_getcontext") || cl_eq (nm, "__getcontext") || cl_eq (nm, "vfork") || cl_eq (nm, "__vfork");
}
static void cl_effect (struct cs_ex *n, struct cl_list *o)
{
  struct cs_ex *s = cl_strip (n);
  if (s->k == E_UN && (cl_name_is (s, "++") || cl_name_is (s, "--") || cl_name_is (s, "post++") || cl_name_is (s, "post--"))) {
    cl_push (o, cl_atom (cl_k (s, 0)));
    cl_push (o, cl_n (cs_pick (cl_name_is (s, "++") || cl_name_is (s, "post++"), "++", "--")));
    return;
  }
  if (s->k == E_BIN && cl_name_is (s, "=") && cl_returns_twice (cl_k (s, 1))) {
    struct cs_ex *l = cl_k (s, 0), *r = cl_k (s, 1);
    struct cl_list *d = cl_ct (r->t), *x = cl_l ();
    cl_itemx (r, d);
    cl_push (x, cl_nl ("returns twice:", d));
    cl_expr (l, x);
    cl_push (x, cl_n ("="));
    cl_push (x, cl_n ("returns twice"));
    cl_push (o, cl_nl (":", x));
    return;
  }
  if (s->k == E_BIN && cl_name_is (s, ",")) {
    struct cl_list *x = cl_l ();
    cl_effect (cl_k (s, 0), x);
    cl_effect (cl_k (s, 1), x);
    cl_push (o, cl_nl (":", x));
    return;
  }
  cl_itemx (n, o);
}
static void cl_labelled (struct cs_st *n, struct cl_list *o);
static void cl_cases (struct cs_st *b, struct cl_list *o)
{
  struct cl_list *ou = cl_l ();
  long i = 0, count = 1;
  struct cs_st **v = &b;
  if (b->k == S_BLOCK) { v = b->kid; count = b->nk; }
  while (i < count) {
    struct cs_st *s = v[i];
    if (s->k == S_CASE || s->k == S_DEFAULT) cl_labelled (s, ou);
    else if (!ou->n) {
      struct cs_dl *d = s->dl;
      if (s->k != S_DECL) cl_fail ("a statement before the first case", 0);
      while (d) { if (d->d && d->d->init) cl_fail ("a statement before the first case", 0); d = d->nxt; }
      cl_stmt (s, o);
    } else {
      struct cl_list *x = cl_l ();
      cl_lstmt (s, x);
      cl_add_all (ou->v[ou->n - 1], x);
    }
    i++;
  }
  cl_append (o, ou);
}
static void cl_labelled (struct cs_st *n, struct cl_list *o)
{
  struct node *h;
  if (n->k != S_CASE) h = cl_n ("default");
  else {
    struct cl_list *x = cl_l ();
    cl_itemx (cl_p (n->e), x);
    if (n->e2) { cl_push (x, cl_n ("...")); cl_itemx (cl_p (n->e2), x); }
    h = cl_nl ("case", x);
  }
  cl_push (o, h);
  if (n->a && (n->a->k == S_CASE || n->a->k == S_DEFAULT)) { cl_labelled (n->a, o); return; }
  if (n->a) { struct cl_list *x = cl_l (); cl_lstmt (n->a, x); cl_add_all (h, x); }
}
static void cl_ifs (char *word, struct cs_st *n, struct cl_list *o)
{
  struct cl_list *x = cl_l ();
  cl_itemx (cl_p (n->e), x);
  cl_sub_body (n->a, x);
  cl_push (o, cl_nl (word, x));
  if (n->b) {
    if (n->b->k == S_IF) cl_ifs ("else if", n->b, o);
    else { struct cl_list *y = cl_l (); cl_sub_body (n->b, y); cl_push (o, cl_nl ("else", y)); }
  }
}
static void cl_static_assert (struct cs_dl *d, struct cl_list *o)
{
  char *text = "";
  if (d->msg) {
    struct cl_bytes b;
    long long *el;
    long ne;
    cl_str_walk (d->msg, &b, &el, &ne);
    if (b.n == 0) text = "";
    else {
      if (!cl_pieces (b.p, b.n, 0)) cl_fail ("a text that is not UTF-8 text", 0);
      text = cl_copy (b.p, b.n);
    }
  }
  cl_push (o, cl_n1 ("comment", cl_n (cl_cat ("_Static_assert, checked by clang: ", text))));
}
static void cl_asm_stmt (struct cs_st *n, struct cl_list *o);
static void cl_decl_stmt (struct cs_st *n, struct cl_list *o)
{
  struct cs_dl *x = n->dl;
  while (x) {
    struct cs_decl *d = x->d;
    if (x->kind == 1) cl_static_assert (x, o);
    else if (x->kind == 2) cl_set (&C->typedefs, cl_dn (d));
    else if (d->sc == SC_EXTERN) {
      if (d->sp && d->sp->err) d->errfn = 1;
      else {
        if (d->sp && d->sp->weak) cl_put_new (&C->weak, cl_dn (d), d);
        cl_want (cl_dn (d));
      }
    } else if (d->k == DK_FUNC) cl_fail ("a declaration of a function in a block, not extern", cl_dn (d));
    else if (d->sc == SC_STATIC && !cl_holds_addrlabel (d->init)) {
      /* (a later one of its name is that name and its number: e_acosh's cl) */
      char *g = cl_cat3 (cl_ffname (C->cur_fn), " ", cl_ffname (cl_dn (d)));
      long k = (long) cl_get (&C->staticcount, cl_dn (d)) + 1;
      cl_put (&C->staticcount, cl_dn (d), (char *) k);
      if (k > 1) g = cl_cat3 (g, " ", cl_num (k));
      d->global = g;
      cl_out (cl_decl (d, 1, g));
    } else cl_push (o, cl_decl (d, 0, 0));
    x = x->nxt;
  }
}
static void cl_clause_expr (struct cs_ex *e, int eff, struct cl_list *o)
{
  if (!e) { cl_push (o, cl_n (":")); return; }
  e = cl_p (e);
  if (eff) cl_effect (e, o); else cl_itemx (e, o);
}
static void cl_stmt (struct cs_st *n, struct cl_list *o)
{
  switch (n->k) {
  case S_BLOCK: {
    struct cl_list *b = cl_l ();
    cl_body (n, b);
    if (b->n > 255) {
      struct cl_list *c = cl_l ();
      long i = 0;
      while (i < b->n) { if (!(cl_is (b->v[i], "line") && b->v[i]->count)) cl_push (c, b->v[i]); i++; }
      b = c;
      C->lfile = 0;
    }
    cl_push (o, cl_nl (":", b));
    return;
  }
  case S_DECL: cl_decl_stmt (n, o); return;
  case S_RETURN: {
    struct cl_list *x = cl_l ();
    if (n->e) cl_itemx (cl_p (n->e), x);
    cl_push (o, cl_nl ("return", x));
    return;
  }
  case S_ASM: cl_asm_stmt (n, o); return;
  case S_IF: cl_ifs ("if", n, o); return;
  case S_WHILE: {
    struct cl_list *x = cl_l ();
    cl_itemx (cl_p (n->e), x);
    cl_sub_body (n->a, x);
    cl_push (o, cl_nl ("while", x));
    return;
  }
  case S_DO: {
    struct cl_list *x = cl_l ();
    cl_itemx (cl_p (n->e), x);
    cl_sub_body (n->a, x);
    cl_push (o, cl_nl ("do while", x));
    return;
  }
  case S_FOR: {
    struct cl_list *i = cl_l (), *x = cl_l ();
    int isdecl = n->a != 0;
    if (n->a) cl_stmt (n->a, i);
    else cl_clause_expr (n->e, 1, i);
    if (isdecl && i->n > 1) {
      cl_push (x, cl_n (":"));
      cl_clause_expr (n->e2, 0, x);
      cl_clause_expr (n->e3, 1, x);
      cl_sub_body (n->b, x);
      cl_push (i, cl_nl ("for", x));
      cl_push (o, cl_nl (":", i));
      return;
    }
    cl_append (x, i);
    cl_clause_expr (n->e2, 0, x);
    cl_clause_expr (n->e3, 1, x);
    cl_sub_body (n->b, x);
    cl_push (o, cl_nl ("for", x));
    return;
  }
  case S_SWITCH: {
    struct cl_list *x = cl_l ();
    cl_itemx (cl_p (n->e), x);
    cl_cases (n->a, x);
    cl_push (o, cl_nl ("switch", x));
    return;
  }
  case S_CASE: case S_DEFAULT: cl_labelled (n, o); return;
  case S_LABEL: {
    char *l = cl_cat (cl_label_of (n->name, n->nlen, n->lk), ":");
    if (n->a && n->a->k == S_DECL) { cl_push (o, cl_n (l)); cl_stmt (n->a, o); return; }
    {
      struct cl_list *x = cl_l ();
      if (n->a) cl_stmt (n->a, x);
      cl_push (o, cl_nl (l, x));
    }
    return;
  }
  case S_GOTO: cl_push (o, cl_n1 ("goto", cl_n (cl_label_of (n->name, n->nlen, n->lk)))); return;
  case S_IGOTO: cl_push (o, cl_n1 ("goto", cl_nl ("content", cl_ex (cl_p (n->e))))); return;
  case S_BREAK: cl_push (o, cl_n ("break")); return;
  case S_CONTINUE: cl_push (o, cl_n ("continue")); return;
  case S_NULL: return;
  case S_EXPR: cl_effect (cl_p (n->e), o); return;
  }
  cl_fail ("the statement of kind", cl_num (n->k));
}

static char *cl_reg_of_name (char *s)
{
  if (C->target == 2) { if (s[0] == '_' && s[1] == 'x' && s[2] >= '0' && s[2] <= '8' && !s[3]) return s + 1; return 0; }
  if (s[0] == '_' && s[1] == '_' && s[2] == 'a' && s[3] >= '0' && s[3] <= '7' && !s[4]) return s + 2;
  return 0;
}
static void cl_syscall_x86 (struct cs_st *cs, struct cl_list *o, int *found);
static void cl_syscall_arm (struct cs_st *cs, struct cl_list *o, int *found);
static void cl_syscall (struct cs_st *cs, struct cl_list *o, int *found)
{
  struct cs_st *inner = 0;
  struct cl_map reg, regof, locals;
  long i = 0;
  int hasasm = 0;
  char *nr, *ar;
  *found = 0;
  if (C->target == 1) { cl_syscall_x86 (cs, o, found); return; }
  if (C->target == 3) { cl_syscall_arm (cs, o, found); return; }
  nr = cs_pick (C->target == 2, "x8", "a7");
  ar = cs_pick (C->target == 2, "x", "a");
  reg.tab = 0; reg.count = 0;
  regof.tab = 0; regof.count = 0;
  locals.tab = 0; locals.count = 0;
  while (i < cs->nk) { if (cs->kid[i]->k == S_BLOCK) { inner = cs->kid[i]; break; } i++; }
  if (!inner) return;
  i = 0;
  while (i < inner->nk) { if (inner->kid[i]->k == S_ASM) hasasm = 1; i++; }
  if (!hasasm) return;
  i = 0;
  while (i < inner->nk) {
    struct cs_st *s = inner->kid[i];
    if (s->k == S_DECL) {
      struct cs_dl *x = s->dl;
      while (x) {
        struct cs_decl *v = x->d;
        if (x->kind == 0 && v && v->sp && v->sp->asmlabel) {
          char *r = cl_reg_of_name (cl_dn (v));
          if (r) {
            cl_put (&regof, cl_dn (v), r);
            if (v->init) cl_put (&reg, r, v->init);
          }
        }
        x = x->nxt;
      }
    }
    i++;
  }

  i = 0;
  while (i < inner->nk) {
    struct cs_st *s = inner->kid[i];
    if (s->k == S_EXPR && s->e->k == E_BIN && cl_name_is (s->e, "=")) {
      struct cs_ex *l = cl_strip (cl_k (s->e, 0));
      if (l->k == E_REF && cl_has (&regof, cl_dn (l->d))) cl_put_new (&reg, cl_get (&regof, cl_dn (l->d)), cl_k (s->e, 1));
    }
    i++;
  }
  if (!cl_has (&reg, nr)) return;

  {
    long pass = 0;
    while (pass < 2) {
      struct cs_st *b = cs;
      if (pass) b = inner;
      i = 0;
      while (i < b->nk) {
        struct cs_st *s = b->kid[i];
        if (s->k == S_DECL) {
          struct cs_dl *x = s->dl;
          while (x) {
            if (x->kind == 0 && x->d && x->d->init && x->d->k == DK_VAR && !cl_has (&regof, cl_dn (x->d))) cl_put (&locals, cl_dn (x->d), x->d->init);
            x = x->nxt;
          }
        }
        i++;
      }
      pass++;
    }
  }
  {
    struct cl_list *x = cl_l ();
    struct cs_ex *num = cl_p (cl_get (&reg, nr));
    long a = 0;
    cl_itemx (num, x);
    while (a <= 5) {
      struct cs_ex *e = cl_get (&reg, cl_cat (ar, cl_num (a)));
      struct cs_ex *s;
      if (!e) break;
      e = cl_p (e);
      s = cl_strip (e);
      if (s->k == E_REF && cl_has (&locals, cl_dn (s->d))) e = cl_p (cl_get (&locals, cl_dn (s->d)));
      cl_itemx (e, x);
      a++;
    }
    cl_push (o, cl_nl ("syscall", x));
    *found = 1;
  }
}

static struct node *cl_nw (char *s) { return cl_n (s); }

static char **cl_split_ws (char *s, long *count)
{
  long room = 16, n = 0, i = 0;
  char **v = alloc (room * sizeof (char *));
  while (s[i]) {
    long b;
    while (s[i] == ' ' || s[i] == '\t' || s[i] == ',' || s[i] == '\n') i++;
    if (!s[i]) break;
    b = i;
    while (s[i] && s[i] != ' ' && s[i] != '\t' && s[i] != ',' && s[i] != '\n') i++;
    if (n + 1 >= room) cl_fail ("an asm instruction of many operands", s);
    v[n] = cl_copy ((unsigned char *) s + b, i - b);
    n++;
  }
  *count = n;
  return v;
}
static char *cl_csr (char *c)
{
  if (cl_eq (c, "fflags")) return "1";
  if (cl_eq (c, "frm")) return "2";
  if (cl_eq (c, "fcsr")) return "3";
  if (cl_all_digits (c)) return c;
  cl_fail ("the CSR", c);
  return 0;
}
static char *cl_rm (char *m)
{
  if (cl_eq (m, "rne")) return "0";
  if (cl_eq (m, "rtz")) return "1";
  if (cl_eq (m, "rdn")) return "2";
  if (cl_eq (m, "rup")) return "3";
  if (cl_eq (m, "rmm")) return "4";
  if (cl_eq (m, "dyn")) return "7";
  cl_fail ("the rounding mode", m);
  return 0;
}
static struct node *cl_ins (char *op, char *a0, char *a1, char *a2)
{
  struct node *n = cl_n (op);
  nd_add (n, cl_n (a0));
  nd_add (n, cl_n (a1));
  if (a2) nd_add (n, cl_n (a2));
  return n;
}
static char *cl_mem_base (char *m)
{
  long i = 0, v = 0;
  char *b;
  if (m[i] == '-') i++;
  while (cl_digit (m[i])) { v = v * 10 + (m[i] - '0'); i++; }
  if (m[i] != '(' || v) cl_fail ("the asm memory operand", m);
  b = cl_copy ((unsigned char *) m + i + 1, cstrlen (m) - i - 1);
  if (!b[0] || !cl_ends (b, ")")) cl_fail ("the asm memory operand", m);
  b[cstrlen (b) - 1] = 0;
  return b;
}
static long long cl_parse_num (char *s)
{
  long long v = 0;
  long i = 0;
  if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
    i = 2;
    while (s[i]) { v = v * 16 + cs_digitv (s[i]); i++; }
    return v;
  }
  if (s[0] == '0' && s[1]) { i = 1; while (s[i]) { v = v * 8 + (s[i] - '0'); i++; } return v; }
  while (s[i]) { v = v * 10 + (s[i] - '0'); i++; }
  return v;
}
static char *cl_xreg[] = { "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6" };
static void cl_asm_ins (char *line, struct cl_list *o)
{
  long na;
  char **v = cl_split_ws (line, &na), *op = v[0];
  char **a = v + 1;
  na = na - 1;
  if (cl_eq (op, "frrm") && na == 1) { cl_push (o, cl_ins ("csrrs", "2", "zero", a[0])); return; }
  if (cl_eq (op, "fsrm") && na == 1) { cl_push (o, cl_ins ("csrrw", "2", a[0], "zero")); return; }
  if (cl_eq (op, "frflags") && na == 1) { cl_push (o, cl_ins ("csrrs", "1", "zero", a[0])); return; }
  if (cl_eq (op, "fsflags") && na == 1) { cl_push (o, cl_ins ("csrrw", "1", a[0], "zero")); return; }
  if (cl_eq (op, "csrr") && na == 2) { cl_push (o, cl_ins ("csrrs", cl_csr (a[1]), "zero", a[0])); return; }
  if ((cl_eq (op, "csrw") || cl_eq (op, "csrs") || cl_eq (op, "csrc")) && na == 2) { cl_push (o, cl_ins (cl_cat ("csrr", op + 3), cl_csr (a[0]), a[1], "zero")); return; }
  if (cl_eq (op, "frsr") && na == 1) { cl_push (o, cl_ins ("csrrs", "3", "zero", a[0])); return; }
  if (cl_eq (op, "fssr") && na == 1) { cl_push (o, cl_ins ("csrrw", "3", a[0], "zero")); return; }
  if ((cl_eq (op, "csrrw") || cl_eq (op, "csrrs") || cl_eq (op, "csrrc")) && na == 3) {
    if (cl_all_digits (a[2])) cl_push (o, cl_ins (cl_cat (op, "i"), cl_csr (a[1]), a[2], a[0]));
    else cl_push (o, cl_ins (op, cl_csr (a[1]), a[2], a[0]));
    return;
  }
  if ((cl_eq (op, "fclass.s") || cl_eq (op, "fclass.d")) && na == 2) { struct node *n = cl_n (op); nd_add (n, cl_n (a[1])); nd_add (n, cl_n (a[0])); cl_push (o, n); return; }
  if ((cl_eq (op, "fmin.s") || cl_eq (op, "fmin.d") || cl_eq (op, "fmax.s") || cl_eq (op, "fmax.d")) && na == 3) { cl_push (o, cl_ins (op, a[2], a[1], a[0])); return; }
  if (cl_starts (op, "fcvt.") && (na == 2 || na == 3)) {

    char *r = op + 5;
    int ok = 0;
    if ((r[0] == 'w' || r[0] == 'l') && ((r[1] == '.' && (r[2] == 's' || r[2] == 'd') && !r[3]) || (r[1] == 'u' && r[2] == '.' && (r[3] == 's' || r[3] == 'd') && !r[4]))) ok = 1;
    if ((r[0] == 's' || r[0] == 'd') && r[1] == '.' && (r[2] == 'w' || r[2] == 'l') && (!r[3] || (r[3] == 'u' && !r[4]))) ok = 1;
    if (ok) {
      char *m = "7";
      if (na == 3) m = cl_rm (a[2]);
      cl_push (o, cl_ins (op, a[1], m, a[0]));
      return;
    }
  }

  {
    long dot = 0;
    while (op[dot] && op[dot] != '.') dot++;
    if (op[dot] == '.' && (op[dot + 1] == 'w' || op[dot + 1] == 'd') && (op[dot + 2] == 0 || op[dot + 2] == '.')) {
      char *ins = cl_copy ((unsigned char *) op, dot);
      char *bits = op + dot + 2;
      if (cl_eq (ins, "lr") || cl_eq (ins, "sc") || cl_eq (ins, "amoswap") || cl_eq (ins, "amoadd") || cl_eq (ins, "amoxor") || cl_eq (ins, "amoand") || cl_eq (ins, "amoor") || cl_eq (ins, "amomin") || cl_eq (ins, "amomax") || cl_eq (ins, "amominu") || cl_eq (ins, "amomaxu")) {
        char *name = cl_copy ((unsigned char *) op, dot + 2);
        int aq = 0, rl = 0;
        long i = 0;
        while (bits[i]) { if (bits[i] == 'q') aq = 1; if (bits[i] == 'r' && bits[i + 1] == 'l') rl = 1; i++; }
        if (cl_eq (ins, "lr") && na == 2) {
          struct node *n = cl_n (name);
          nd_add (n, cl_num_node (aq)); nd_add (n, cl_num_node (rl)); nd_add (n, cl_n (cl_mem_base (a[1]))); nd_add (n, cl_n (a[0]));
          cl_push (o, n);
          return;
        }
        if (na == 3) {
          struct node *n = cl_n (name);
          nd_add (n, cl_num_node (aq)); nd_add (n, cl_num_node (rl)); nd_add (n, cl_n (a[1])); nd_add (n, cl_n (cl_mem_base (a[2]))); nd_add (n, cl_n (a[0]));
          cl_push (o, n);
          return;
        }
      }
    }
  }
  if (cl_eq (op, ".insn") && na == 6 && cl_eq (a[0], "i") && (cl_eq (a[1], "0x0f") || cl_eq (a[1], "0x0F")) && cl_eq (a[2], "0") && cl_eq (a[3], "x0") && cl_eq (a[4], "x0")) {
    long long imm = cl_parse_num (a[5]) & 0xfff;
    struct node *n = cl_n ("fence");
    nd_add (n, cl_num_node (imm >> 8));
    nd_add (n, cl_num_node ((imm >> 4) & 15));
    nd_add (n, cl_num_node (imm & 15));
    cl_push (o, n);
    return;
  }
  if (cl_eq (op, ".insn") && na == 1 && cl_starts (a[0], "0x") && cstrlen (a[0]) == 10) {
    long long w = cl_parse_num (a[0]);
    if ((w & 0x707f) == 0x2073 && ((w >> 15) & 31) == 0) {
      char *rd = cl_xreg[(w >> 7) & 31];
      cl_push (o, cl_ins ("csrrs", cl_num (w >> 20), "zero", rd));
      if (C->asm_rd_out) { struct node *n = cl_n ("mv"); nd_add (n, cl_n (rd)); nd_add (n, cl_n ("t0")); cl_push (o, n); }
      return;
    }
  }
  cl_fail ("the asm instruction", line);
}
static long cl_size_class (char *t)
{
  if (cl_eq (t, "u64") || cl_eq (t, "long") || cl_eq (t, "i64")) return 8;
  if (cl_eq (t, "u32") || cl_eq (t, "int") || cl_eq (t, "i32")) return 4;
  return 0;
}

struct cl_asm { char *tmpl; char **oc, **ic; long noc, nic; int clob1; };
static char *cl_str_raw (struct node *s)
{

  struct cs_buf b;
  long i = 0, np = 1;
  cs_b_init (&b);
  if (cs_is (s, "str")) np = s->count;
  while (i < np) {
    struct node *k = s;
    struct cs_buf t;
    long at;
    if (cs_is (s, "str")) k = s->kids[i];
    cs_b_init (&t);
    cs_tok_bytes (k, &t);
    cs_lit_prefix (t.p, &at);
    cs_b_bytes (&b, t.p + at + 1, t.n - at - 2);
    i++;
  }
  return cl_copy (b.p, b.n);
}
static void cl_asm_parts (struct cs_st *n, struct cl_asm *r)
{
  struct node *a = n->src;
  long i = 0, sec = 0;
  r->tmpl = 0;
  r->noc = 0;
  r->nic = 0;
  r->clob1 = 0;
  r->oc = alloc (64 * sizeof (char *));
  r->ic = alloc (64 * sizeof (char *));
  while (i < a->count) {
    struct node *k = a->kids[i];
    if (!r->tmpl && (cs_is (k, "str") || (!k->count && k->len && k->text[0] == '"') || cs_is (k, "token"))) {

      char *raw = cl_str_raw (k);
      struct cs_buf b;
      long j = 0;
      cs_b_init (&b);
      while (raw[j]) {
        if (raw[j] == '\\' && raw[j + 1] == 't') { cs_b_byte (&b, ' '); j += 2; continue; }
        if (raw[j] == '\\' && raw[j + 1] == 'n') { cs_b_byte (&b, ';'); j += 2; continue; }
        if (raw[j] == '\\' && raw[j + 1]) { cs_b_byte (&b, raw[j]); cs_b_byte (&b, raw[j + 1]); j += 2; continue; }
        cs_b_byte (&b, raw[j]);
        j++;
      }
      r->tmpl = cl_copy (b.p, b.n);
    } else if (cs_is (k, ":")) {
      if (sec < 2) {
        long j = 0;
        while (j < k->count) {
          struct node *o = k->kids[j];
          if (cs_is (o, "operand")) {
            char *c = cl_str_raw (o->kids[o->count - 2]);
            if (sec == 0) { r->oc[r->noc] = c; r->noc = r->noc + 1; } else { r->ic[r->nic] = c; r->nic = r->nic + 1; }
          }
          j++;
        }
      }
      else if (sec == 2) {
        long j = 0;
        while (j < k->count) { if (cl_eq (cl_str_raw (k->kids[j]), "st(1)")) r->clob1 = 1; j++; }
      }
      sec++;
    }
    i++;
  }
  if (!r->tmpl) r->tmpl = "";
}

static void cl_asm_ops (struct cs_st *n, struct cl_asm *p)
{
  long i = 0;
  struct cs_ex **ops = n->ops;
  cl_asm_parts (n, p);
  if (n->nops != p->noc + p->nic) cl_fail ("an asm statement whose operands are not its text's", 0);
  while (i < n->nops) { ops[i] = cl_p (ops[i]); i++; }
  i = 0;
  while (i < p->noc) {
    struct cs_ex *x = ops[i];
    if (x->k == E_CAST) {
      struct cs_ex *in = cl_strip (cl_k (x, 0));
      char *to = cl_tword_int (x), *from = cl_tword_int (in);
      if (cl_eq (to, from) || (cl_size_class (to) && cl_size_class (to) == cl_size_class (from))) ops[i] = in;
    }
    i++;
  }
}
static char *cl_constraint_clean (char *c)
{

  struct cs_buf b;
  long i = 0;
  cs_b_init (&b);
  while (c[i]) { if (c[i] != '=' && c[i] != '+' && c[i] != '&') cs_b_byte (&b, c[i]); i++; }
  return cl_copy (b.p, b.n);
}
static int cl_regs_only (char *k)
{
  long i = 0;
  if (!k[0]) return 0;
  while (k[i]) { if (k[i] != 'r' && k[i] != 'J' && k[i] != 'K') return 0; i++; }
  return 1;
}
static int cl_has_plus (char *c) { long i = 0; while (c[i]) { if (c[i] == '+') return 1; i++; } return 0; }
static void cl_name_clean (struct cs_buf *b, char *s)
{

  long i = 0;
  int run = 0;
  while (s[i]) {
    if (cl_digit (s[i]) || (s[i] >= 'a' && s[i] <= 'z') || (s[i] >= 'A' && s[i] <= 'Z')) { cs_b_byte (b, s[i]); run = 0; }
    else if (!run) { cs_b_byte (b, '_'); run = 1; }
    i++;
  }
}
static void cl_alnum (struct cs_buf *b, char *s)
{
  long i = 0;
  while (s[i]) { if (cl_digit (s[i]) || (s[i] >= 'a' && s[i] <= 'z') || (s[i] >= 'A' && s[i] <= 'Z')) cs_b_byte (b, s[i]); i++; }
}
static void cl_asm_other (struct cs_st *n, struct cl_list *o);
static void cl_unshift1 (struct cl_list *l, struct node *n) { struct cl_list *one = cl_l (); cl_push (one, n); cl_unshift (l, one); }

static unsigned int cl_rol (unsigned int v, int b) { return (v << b) | (v >> (32 - b)); }
static char *cl_sha1_hex (unsigned char *m, long n)
{
  unsigned int h[5], w[80];
  long total = ((n + 8) / 64 + 1) * 64, i = 0;
  unsigned char *b = alloc (total + 1);
  char *r = alloc (41);
  h[0] = 0x67452301; h[1] = 0xEFCDAB89; h[2] = 0x98BADCFE; h[3] = 0x10325476; h[4] = 0xC3D2E1F0;
  while (i < n) { b[i] = m[i]; i++; }
  b[n] = 0x80;
  { long long bits = n * 8; long k = 0; while (k < 8) { b[total - 1 - k] = (bits >> (8 * k)) & 0xff; k++; } }
  i = 0;
  while (i < total) {
    unsigned int x0 = h[0], x1 = h[1], x2 = h[2], x3 = h[3], x4 = h[4];
    long t = 0;
    while (t < 16) { long at = i + 4 * t; w[t] = ((unsigned int) b[at] << 24) | ((unsigned int) b[at + 1] << 16) | ((unsigned int) b[at + 2] << 8) | b[at + 3]; t++; }
    while (t < 80) { w[t] = cl_rol (w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1); t++; }
    t = 0;
    while (t < 80) {
      unsigned int fv, kv, tmp;
      if (t < 20) { fv = (x1 & x2) | ((~x1) & x3); kv = 0x5A827999; }
      else if (t < 40) { fv = x1 ^ x2 ^ x3; kv = 0x6ED9EBA1; }
      else if (t < 60) { fv = (x1 & x2) | (x1 & x3) | (x2 & x3); kv = 0x8F1BBCDC; }
      else { fv = x1 ^ x2 ^ x3; kv = 0xCA62C1D6; }
      tmp = cl_rol (x0, 5) + fv + x4 + kv + w[t];
      x4 = x3; x3 = x2; x2 = cl_rol (x1, 30); x1 = x0; x0 = tmp;
      t++;
    }
    h[0] = h[0] + x0; h[1] = h[1] + x1; h[2] = h[2] + x2; h[3] = h[3] + x3; h[4] = h[4] + x4;
    i += 64;
  }
  i = 0;
  while (i < 20) {
    unsigned int v = (h[i / 4] >> (24 - 8 * (i % 4))) & 0xff;
    r[2 * i] = "0123456789abcdef"[v >> 4];
    r[2 * i + 1] = "0123456789abcdef"[v & 15];
    i++;
  }
  return r;
}
static char *cl_asm_sha_name (char *name, char *sig)
{
  char *h = cl_sha1_hex ((unsigned char *) sig, cstrlen (sig));
  char *nw = cl_cat3 (name, "_", cl_copy ((unsigned char *) h, 6));
  char *old = cl_get (&C->asmsig, nw);
  if (old && !cl_eq (old, sig)) cl_fail ("two asm statements of one name", nw);
  cl_put (&C->asmsig, nw, sig);
  return nw;
}
static void cl_asm_stmt (struct cs_st *n, struct cl_list *o)
{
  struct cl_asm p;
  long i = 0, nargs = 0, ni = 0, nf = 0, ret = -1, nops = n->nops;
  char *fret = 0;
  char **text = alloc ((nops + 1) * sizeof (char *));
  long *argop = alloc ((nops + 1) * sizeof (long));
  int *argaddr = alloc ((nops + 1) * sizeof (int)), *argplus = alloc ((nops + 1) * sizeof (int));
  char **argreg = alloc ((nops + 1) * sizeof (char *));
  struct cl_list *code = cl_l ();
  struct cs_ex **ops = n->ops;
  if (C->target != 0) { cl_asm_other (n, o); return; }
  cl_asm_ops (n, &p);
  i = 0;
  while (i < nops) {
    char *c = i < p.noc ? p.oc[i] : p.ic[i - p.noc];
    char *k = cl_constraint_clean (c);
    if (cl_eq (k, "f") && i < p.noc && !cl_has_plus (c)) {
      char *t = cl_tword (ops[i]);
      if (ret >= 0) cl_fail ("an asm statement with two register outputs", 0);
      ret = i;
      if (cl_eq (t, "float")) fret = "s"; else if (cl_eq (t, "double")) fret = "d"; else cl_fail ("an asm operand f of that type", 0);
      text[i] = "ft0";
    } else if (cl_eq (k, "f") && i >= p.noc) {
      char *t = cl_tword (ops[i]);
      if (!cl_eq (t, "float") && !cl_eq (t, "double")) cl_fail ("an asm operand f of that type", 0);
      argop[nargs] = i;
      argreg[nargs] = cl_cat ("fa", cl_num (nf));
      nf++;
      text[i] = argreg[nargs];
      nargs++;
    } else if (cl_eq (k, "i") && i >= p.noc) {
      long long v;
      if (!cl_int_const (ops[i], &v)) cl_fail ("an asm operand i that is no constant", 0);
      text[i] = cl_num (v);
    } else if (cl_regs_only (k) && i < p.noc) {
      if (ret >= 0) cl_fail ("an asm statement with two register outputs", 0);
      ret = i;
      text[i] = "t0";
      if (cl_has_plus (c)) {
        argop[nargs] = i;
        argplus[nargs] = 1;
        argreg[nargs] = cl_cat ("a", cl_num (ni));
        ni++;
        nargs++;
      }
    } else if (cl_regs_only (k)) {
      argop[nargs] = i;
      argreg[nargs] = cl_cat ("a", cl_num (ni));
      ni++;
      text[i] = argreg[nargs];
      nargs++;
    } else if (cl_digit (k[0]) && !k[1] && i >= p.noc && ret >= 0 && k[0] - '0' == ret) {
      argop[nargs] = i;
      argplus[nargs] = 1;
      argreg[nargs] = cl_cat ("a", cl_num (ni));
      ni++;
      nargs++;
      text[i] = "t0";
    } else if (cl_eq (k, "A") || cl_eq (k, "m")) {
      argop[nargs] = i;
      argaddr[nargs] = 1;
      argreg[nargs] = cl_cat ("a", cl_num (ni));
      ni++;
      if (cl_eq (k, "A")) text[i] = cl_cat3 ("(", argreg[nargs], ")"); else text[i] = cl_cat3 ("0(", argreg[nargs], ")");
      nargs++;
    } else cl_fail ("the asm constraint", c);
    i++;
  }
  {

    struct cs_buf b;
    char *t;
    long j = 0;
    cs_b_init (&b);
    while (p.tmpl[j]) {
      if (p.tmpl[j] == '%') {
        long m = j + 1, v = 0;
        if (p.tmpl[m] == 'z') m++;
        if (cl_digit (p.tmpl[m])) {
          while (cl_digit (p.tmpl[m])) { v = v * 10 + (p.tmpl[m] - '0'); m++; }
          if (v >= nops || !text[v]) cl_fail ("the asm operand", p.tmpl);
          cs_b_str (&b, text[v]);
          j = m;
          continue;
        }
      }
      cs_b_byte (&b, p.tmpl[j]);
      j++;
    }
    t = cl_copy (b.p, b.n);

    j = 0;
    while (j < nargs) {
      if (argplus[j]) { struct node *m = cl_n ("mv"); nd_add (m, cl_n (argreg[j])); nd_add (m, cl_n ("t0")); cl_push (code, m); }
      j++;
    }
    {
      int any = 0;
      long q = 0;
      while (p.tmpl[q]) { if (p.tmpl[q] == '%') any = 1; q++; }
      C->asm_rd_out = ret >= 0 && !any;
    }

    j = 0;
    while (t[j]) {
      long e = j, x;
      char *line;
      int blank = 1;
      while (t[e] && t[e] != ';') e++;
      line = cl_copy ((unsigned char *) t + j, e - j);
      x = 0;
      while (line[x]) { if (line[x] != ' ' && line[x] != '\t' && line[x] != '\n') blank = 0; x++; }
      if (!blank) cl_asm_ins (line, code);
      j = e;
      if (t[j] == ';') j++;
    }
    if (fret) { struct node *m = cl_n (cs_pick (fret[0] == 's', "fmv.x.w", "fmv.x.d")); nd_add (m, cl_n ("ft0")); nd_add (m, cl_n ("t0")); cl_push (code, m); }
    if (ret >= 0) { struct node *m = cl_n ("mv"); nd_add (m, cl_n ("t0")); nd_add (m, cl_n ("a0")); cl_push (code, m); }
  }
  {
    struct cs_buf nm, sg;
    char *name, *sig, *old;
    long j = 0;
    cs_b_init (&nm);
    cl_name_clean (&nm, cl_cat ("__asm_", p.tmpl));
    cs_b_byte (&nm, '_');
    while (j < p.noc) { cl_alnum (&nm, p.oc[j]); j++; }
    j = 0;
    while (j < p.nic) { cl_alnum (&nm, p.ic[j]); j++; }
    name = cl_copy (nm.p, nm.n);
    cs_b_init (&sg);
    cs_b_str (&sg, p.tmpl);
    cs_b_str (&sg, " : ");
    j = 0;
    while (j < p.noc) { if (j) cs_b_byte (&sg, ' '); cs_b_str (&sg, p.oc[j]); j++; }
    cs_b_str (&sg, " : ");
    j = 0;
    while (j < p.nic) { if (j) cs_b_byte (&sg, ' '); cs_b_str (&sg, p.ic[j]); j++; }
    sig = cl_copy (sg.p, sg.n);
    old = cl_get (&C->asmsig, name);
    if (old && !cl_eq (old, sig)) name = cl_asm_sha_name (name, sig);
    else cl_put (&C->asmsig, name, sig);
    if (!cl_val (&C->asmfn, name)) {
      struct cl_list *d = cl_l ();
      cl_set (&C->asmfn, name);
      cl_push (d, cl_n ("asm"));
      cl_push (d, cl_n1 ("comment", cl_n (cl_cat3 ("glibc's asm statement \"", p.tmpl, "\""))));
      cl_append (d, code);
      cl_push (d, cl_n ("ret"));
      cl_out (cl_nl (cl_cat (name, ":"), d));
    }
    {
      struct cl_list *args = cl_l ();
      struct node *cnode;
      j = 0;
      while (j < nargs) {
        if (argaddr[j]) cl_push (args, cl_n1 ("address", cl_atom (ops[argop[j]])));
        else cl_push (args, cl_atom (ops[argop[j]]));
        j++;
      }
      cnode = cl_nl (name, args);
      if (fret) {
        struct cl_list *t = cl_l (), *v = cl_l ();
        cl_w (t, "address");
        cl_w (t, cs_pick (fret[0] == 's', "u32", "u64"));
        cl_push (v, cl_n1 ("address", cl_atom (ops[ret])));
        cl_push (o, cl_n1 ("content", cl_cast_node (t, v)));
        cl_push (o, cl_n ("="));
        cl_push (o, cnode);
        return;
      }
      if (ret >= 0) {
        cl_itemx (ops[ret], o);
        cl_push (o, cl_n ("="));
        cl_push (o, cnode);
        return;
      }
      cl_push (o, cnode);
    }
  }
}

static struct node *cl_function (char *name, struct cs_decl *d)
{
  struct cl_list *head = cl_l (), *ps = cl_l (), *st = cl_l ();
  struct cs_ty *f = cs_canon (d->t);
  long i = 0;
  C->staticcount.tab = 0;
  C->staticcount.count = 0;
  char *saved_fn = C->cur_fn;
  char *file, *comment;
  long nst = 0;
  struct cl_list **sts;
  C->cur_fn = name;
  cl_ctype (f->to, head);
  while (i < d->np) {
    char *pn;
    struct cl_list *t;
    if (d->ps[i].name && d->ps[i].nlen) pn = cl_copy (d->ps[i].name, d->ps[i].nlen);
    else pn = cl_cat ("p", cl_num (i + 1));
    t = cl_ct (d->ps[i].t);
    cl_push (head, cl_nl (cl_cat (cl_ffname (pn), ":"), t));
    i++;
  }
  if (f->var) cl_push (head, cl_n ("..."));
  file = C->ifile;
  comment = cl_cat3 (cl_unit_label (), " ", file);
  cl_push (head, cl_n1 ("comment", cl_n (comment)));
  if (d->sp && d->sp->ctor) {
    struct node *c = cl_n (cs_pick (d->sp->ctor == 1, "constructor", "destructor"));
    struct cl_list *h = cl_l ();
    if (d->sp->ctorprio >= 0) nd_add (c, cl_num_node (d->sp->ctorprio));
    cl_push (h, c);
    cl_append (h, head);
    head = h;
  }

  if (d->sp && d->sp->pcs) cl_unshift1 (head, cl_n ("base pcs"));
  C->lfile = 0;
  C->lline = 0;

  sts = alloc ((d->body->nk + 2) * sizeof (struct cl_list *));
  {
    struct cl_list *at = cl_l ();
    cl_line_at (d->off, at);
    if (at->n) { sts[nst] = at; nst++; }
  }
  i = 0;
  while (i < d->body->nk) { struct cl_list *x = cl_l (); cl_lstmt (d->body->kid[i], x); sts[nst] = x; nst++; i++; }
  {
    long total = 0;
    i = 0;
    while (i < nst) { total = total + sts[i]->n; i++; }
    if (head->n + total <= 255) {
      i = 0;
      while (i < nst) { cl_append (st, sts[i]); i++; }
    } else {
      struct cl_list *cur = cl_l ();
      long layers = 0;
      i = 0;
      while (i < nst) {
        if (cur->n + sts[i]->n > 255) {
          cl_push (st, cl_nl (cl_cat (cl_num (layers), ":"), cur));
          layers++;
          cur = cl_l ();
        }
        cl_append (cur, sts[i]);
        i++;
      }
      if (cur->n) { cl_push (st, cl_nl (cl_cat (cl_num (layers), ":"), cur)); layers++; }
      if (head->n + layers > 255) cl_fail ("a function too long for layers of one level", 0);
    }
  }
  C->cur_fn = saved_fn;
  cl_append (ps, head);
  cl_append (ps, st);
  return cl_nl (cl_cat (cl_ffname (name), ":"), ps);
}
