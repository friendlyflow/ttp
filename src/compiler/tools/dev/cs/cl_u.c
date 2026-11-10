/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cl_u.c (in cs.c): T3c, the C layer written from csema's tree, equal to
   gen/c2ff.pl's: small things. Texts here are C strings (no node of the C
   layer holds a NUL), nodes struct node with their texts so. */
struct cl_list { struct node **v; long n, room; };
struct cl_ent { char *key; void *val; long num; struct cl_ent *nxt; };
struct cl_map { struct cl_ent **tab; long count; };
struct cl_big { unsigned int *w; long n; };
struct cl_fv { int kind; int neg; struct cl_big *q; long long e; };   /* kind 0 a number q * 2^e, 1 infinity, 2 NaN */
struct cl_out { struct node *n; };
/* a unit, as c2ff.pl's %own, %ownrec, %ownanon, %owntd, %constint, ...: what is its own */
struct cl_unit {
  char *i;                     /* its .i, as c2ff names it */
  int object;
  struct cs_cst *t;
  void *s;
  struct cl_map own, constint, ownfn, text_item, owntd, ownrec, ownanon;
  struct cl_list ctors;        /* its constructors and destructors */
  struct cl_shared *shared;    /* its records of the first's text */
};
struct cl_shared { char *key; struct cs_rec *d; struct cl_shared *nxt; };
struct cl_state {
  int target;                  /* 0 riscv64, 1 x86_64, 2 aarch64, 3 arm */
  char *page;
  char *ifile, *glibc_src, *libgcc_src, *shared;
  struct cl_map fn, var, alias, ifunc, weak, regvar, section;
  struct cl_map rec, enumd, anon_tag, anon_name, tagname, wanttag, tdone, enumof, enumval, enumref, enumused;
  struct cl_map treefile, treepage;
  struct cl_map lastdecl, typedefs, localname, fieldname, own, done, fntype, reserved, renamed, text_item, asmfn, asmsig, ctor, pragma_weak, left_out;
  long nfieldrec, nrec;
  struct node **todo; long ntodo, roomtodo, attodo;
  char **roots; long nroots, atroots;
  char **fnt_name; struct cs_ty **fnt_ty; long nfnt, roomfnt, fndone;
  long fnlast, ntext, nwide;
  struct cl_list out, types;
  /* the function or global being translated */
  char *cur_fn, *cur_global;
  int in_global, has_cur_global;
  char *lfile; long lline;
  struct cl_map literals;
  struct cs_rec *lastanon;
  int asm_rd_out;
  /* --program, --index, --start, --zero, --weak */
  char *program, *indexf, *staticsf, *staticsout;
  int start;
  /* -N: the tree the files under -s are of (a program's: its name, the SPDX of a file of no header, its license file); -p with -P: the program's definitions in groups, as a page's */
  char *tree, *tree_spdx, *tree_copying, *tree_build;   /* (-B: its build folder, of files the build makes: shown as build/...) */
  int groups;
  struct cl_map treedefs, treerec, zero, forceweak, constint, recfn, ownfn;
  /* the units */
  struct cl_unit *cu;          /* (c2ff.pl's $cur_unit, 0 for none) */
  struct cl_unit **units; long nunits, roomunits;
  struct cl_map recunit, typedef_t, typedef_k, enumunit, aliasunit;
  struct cl_map owntd, ownrec, ownanon;
  struct cl_map plainstatic;   /* the units sharing the first's static of a name, the same text */
  struct cl_map treestatic;    /* -J file: those of the tree's names that are a static of a unit there */
  struct cl_map staticcount;   /* how many statics of a name the function at hand has had */
  struct cl_map anonin;        /* a record's own anonymous records, where the first at the same place differs: tag|key */
  char *cur_tag;               /* the record whose fields are being written */
  struct cl_unit **outu; long roomoutu;
  struct cl_map empty;
  int began, keep_going;
  long *jb;                    /* where a failure goes back to, with -k */
  /* words */
  char *w_ptr, *w_addr;   /* (made, not written: gen/Words.pm takes a text of these for a tree in the words of now) */
  struct cl_map word, recw;
  int scoped;
};
static struct cl_state *C;
static void cl_fail (char *what, char *more)
{
  err_str ("csema: not yet: ");
  err_str (what);
  if (more) { err_str (" "); err_str (more); }
  if (C && C->cur_fn) { err_str (" (in "); err_str (C->cur_fn); err_str (")"); }
  err_str ("\n");
  /* (-k: what cannot be translated yet is left out, said; the rest goes on) */
  if (C && C->jb) ((void (*)(long *)) cp_jump[1]) (C->jb);
  cp_exit (3);
}
static int cl_eq (char *a, char *b)
{
  long i = 0;
  while (a[i] && a[i] == b[i]) i++;
  return a[i] == b[i];
}
static int cl_cmp (char *a, char *b)
{
  long i = 0;
  while (a[i] && a[i] == b[i]) i++;
  return (unsigned char) a[i] - (unsigned char) b[i];
}
static char *cl_cat (char *a, char *b)
{
  long x = cstrlen (a), y = cstrlen (b), i = 0;
  char *r = alloc (x + y + 1);
  while (i < x) { r[i] = a[i]; i++; }
  i = 0;
  while (i < y) { r[x + i] = b[i]; i++; }
  return r;
}
static char *cl_cat3 (char *a, char *b, char *c) { return cl_cat (cl_cat (a, b), c); }
static char *cl_copy (unsigned char *p, long n)
{
  char *r = alloc (n + 1);
  long i = 0;
  while (i < n) { r[i] = p[i]; i++; }
  return r;
}
static char *cl_num (long long v)
{
  struct cs_buf b;
  cs_b_init (&b);
  cs_b_ll (&b, v);
  return cl_copy (b.p, b.n);
}
static char *cl_unum (unsigned long long v)
{
  struct cs_buf b;
  cs_b_init (&b);
  cs_b_ull (&b, v);
  return cl_copy (b.p, b.n);
}
static int cl_starts (char *s, char *pre)
{
  long i = 0;
  while (pre[i]) { if (s[i] != pre[i]) return 0; i++; }
  return 1;
}
static int cl_ends (char *s, char *suf)
{
  long a = cstrlen (s), b = cstrlen (suf), i = 0;
  if (b > a) return 0;
  while (i < b) { if (s[a - b + i] != suf[i]) return 0; i++; }
  return 1;
}
static int cl_digit (int c) { return c >= '0' && c <= '9'; }
static int cl_alpha (int c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'; }
/* /^\d+$/ */
static int cl_all_digits (char *s)
{
  long i = 0;
  if (!s[0]) return 0;
  while (s[i]) { if (!cl_digit (s[i])) return 0; i++; }
  return 1;
}
/* ---- maps ---- */
#define CL_BUCKETS 16384
static long cl_hash (char *s)
{
  long h = 5381, i = 0;
  while (s[i]) { h = (h * 33 + (unsigned char) s[i]) & 0xffffff; i++; }
  return h & (CL_BUCKETS - 1);
}
static struct cl_ent *cl_find (struct cl_map *m, char *key)
{
  struct cl_ent *e;
  if (!m->tab) return 0;
  e = m->tab[cl_hash (key)];
  while (e) { if (cl_eq (e->key, key)) return e; e = e->nxt; }
  return 0;
}
static struct cl_ent *cl_make (struct cl_map *m, char *key)
{
  struct cl_ent *e = cl_find (m, key);
  long h;
  if (e) return e;
  if (!m->tab) m->tab = alloc (CL_BUCKETS * sizeof (struct cl_ent *));
  h = cl_hash (key);
  e = alloc (sizeof (struct cl_ent));
  e->key = key;
  e->nxt = m->tab[h];
  m->tab[h] = e;
  m->count = m->count + 1;
  return e;
}
static void *cl_get (struct cl_map *m, char *key) { struct cl_ent *e = cl_find (m, key); if (e) return e->val; return 0; }
static int cl_has (struct cl_map *m, char *key) { return cl_find (m, key) != 0; }
static void cl_put (struct cl_map *m, char *key, void *v) { cl_make (m, key)->val = v; }
static void cl_del (struct cl_map *m, char *key)
{
  struct cl_ent **p;
  if (!m->tab) return;
  p = &m->tab[cl_hash (key)];
  while (*p) {
    if (cl_eq ((*p)->key, key)) { *p = (*p)->nxt; m->count = m->count - 1; return; }
    p = &(*p)->nxt;
  }
}
/* //= */
static void cl_put_new (struct cl_map *m, char *key, void *v) { if (!cl_has (m, key)) cl_put (m, key, v); }
static void cl_set (struct cl_map *m, char *key) { cl_make (m, key)->num = 1; }
static long cl_val (struct cl_map *m, char *key) { struct cl_ent *e = cl_find (m, key); if (e) return e->num; return 0; }
/* the keys, sorted, as Perl's sort */
static char **cl_keys (struct cl_map *m, long *count)
{
  char **a = alloc ((m->count + 1) * sizeof (char *));
  long i = 0, n = 0;
  if (m->tab) while (i < CL_BUCKETS) { struct cl_ent *e = m->tab[i]; while (e) { a[n] = e->key; n++; e = e->nxt; } i++; }
  {
    /* (a merge sort) */
    char **t = alloc ((n + 1) * sizeof (char *)), **from = a, **into = t;
    long w = 1;
    while (w < n) {
      long lo = 0;
      while (lo < n) {
        long mid = lo + w, hi = lo + 2 * w, x, y, z;
        if (mid > n) mid = n;
        if (hi > n) hi = n;
        x = lo; y = mid; z = lo;
        while (x < mid && y < hi) { if (cl_cmp (from[x], from[y]) <= 0) { into[z] = from[x]; x++; } else { into[z] = from[y]; y++; } z++; }
        while (x < mid) { into[z] = from[x]; x++; z++; }
        while (y < hi) { into[z] = from[y]; y++; z++; }
        lo = hi;
      }
      { char **tmp = from; from = into; into = tmp; }
      w = w * 2;
    }
    *count = n;
    return from;
  }
}
/* ---- nodes and lists ---- */
static struct node *cl_n (char *s) { return nd_text ((unsigned char *) s, cstrlen (s)); }
static struct node *cl_n1 (char *s, struct node *k) { struct node *x = cl_n (s); nd_add (x, k); return x; }
static int cl_is (struct node *n, char *s) { return n && cl_eq ((char *) n->text, s); }
static int cl_leaf (struct node *n) { return n->count == 0; }
static int cl_isleaf (struct node *n, char *s) { return n && n->count == 0 && cl_eq ((char *) n->text, s); }
static struct cl_list *cl_l (void) { return alloc (sizeof (struct cl_list)); }
static void cl_push (struct cl_list *l, struct node *n)
{
  if (l->n == l->room) {
    long m = l->room * 2 + 8, i = 0;
    struct node **a = alloc (m * sizeof (struct node *));
    while (i < l->n) { a[i] = l->v[i]; i++; }
    l->v = a;
    l->room = m;
  }
  l->v[l->n] = n;
  l->n = l->n + 1;
}
static void cl_append (struct cl_list *l, struct cl_list *x) { long i = 0; while (i < x->n) { cl_push (l, x->v[i]); i++; } }
static void cl_unshift (struct cl_list *l, struct cl_list *x)
{
  struct cl_list *r = cl_l ();
  cl_append (r, x);
  cl_append (r, l);
  *l = *r;
}
static void cl_add_all (struct node *n, struct cl_list *x) { long i = 0; while (i < x->n) { nd_add (n, x->v[i]); i++; } }
static struct node *cl_nl (char *s, struct cl_list *x) { struct node *r = cl_n (s); cl_add_all (r, x); return r; }
/* the words of a list of leaves, joined by spaces */
static char *cl_join (struct cl_list *l)
{
  struct cs_buf b;
  long i = 0;
  cs_b_init (&b);
  while (i < l->n) { if (i) cs_b_byte (&b, ' '); cs_b_str (&b, (char *) l->v[i]->text); i++; }
  return cl_copy (b.p, b.n);
}
/* ---- big numbers (unsigned): what long double's literals are rounded with ---- */
static struct cl_big *cl_big_new (long room)
{
  struct cl_big *b = alloc (sizeof (struct cl_big));
  b->w = alloc ((room + 1) * sizeof (unsigned int));
  return b;
}
static void cl_big_trim (struct cl_big *b) { while (b->n > 0 && b->w[b->n - 1] == 0) b->n = b->n - 1; }
static struct cl_big *cl_big_copy (struct cl_big *a)
{
  struct cl_big *b = cl_big_new (a->n + 1);
  long i = 0;
  while (i < a->n) { b->w[i] = a->w[i]; i++; }
  b->n = a->n;
  return b;
}
static struct cl_big *cl_big_small (unsigned long long v)
{
  struct cl_big *b = cl_big_new (3);
  b->w[0] = (unsigned int) v;
  b->w[1] = (unsigned int) (v >> 32);
  b->n = 2;
  cl_big_trim (b);
  return b;
}
static int cl_big_zero (struct cl_big *a) { return a->n == 0; }
/* a * m + c */
static struct cl_big *cl_big_muladd (struct cl_big *a, unsigned int m, unsigned int c)
{
  struct cl_big *b = cl_big_new (a->n + 2);
  unsigned long long carry = c;
  long i = 0;
  while (i < a->n) {
    unsigned long long x = (unsigned long long) a->w[i] * m + carry;
    b->w[i] = (unsigned int) x;
    carry = x >> 32;
    i++;
  }
  b->w[i] = (unsigned int) carry;
  b->n = i + 1;
  cl_big_trim (b);
  return b;
}
static long cl_big_bits (struct cl_big *a)
{
  long n = a->n;
  unsigned int t;
  long r;
  if (!n) return 0;
  t = a->w[n - 1];
  r = (n - 1) * 32;
  while (t) { r++; t = t >> 1; }
  return r;
}
static struct cl_big *cl_big_shl (struct cl_big *a, long s)
{
  long ws = s / 32, bs = s % 32, i = 0;
  struct cl_big *b = cl_big_new (a->n + ws + 2);
  while (i < a->n) {
    unsigned long long x = (unsigned long long) a->w[i] << bs;
    b->w[i + ws] = b->w[i + ws] | (unsigned int) x;
    b->w[i + ws + 1] = (unsigned int) (x >> 32);
    i++;
  }
  b->n = a->n + ws + 1;
  cl_big_trim (b);
  return b;
}
static int cl_big_cmp (struct cl_big *a, struct cl_big *b)
{
  long i;
  if (a->n != b->n) { if (a->n > b->n) return 1; return 0 - 1; }
  i = a->n - 1;
  while (i >= 0) {
    if (a->w[i] != b->w[i]) { if (a->w[i] > b->w[i]) return 1; return 0 - 1; }
    i--;
  }
  return 0;
}
/* a - b, a >= b */
static struct cl_big *cl_big_sub (struct cl_big *a, struct cl_big *b)
{
  struct cl_big *r = cl_big_new (a->n + 1);
  long long borrow = 0;
  long i = 0;
  while (i < a->n) {
    long long x = (long long) a->w[i] - borrow;
    if (i < b->n) x = x - (long long) b->w[i];
    borrow = 0;
    if (x < 0) { x = x + 4294967296LL; borrow = 1; }
    r->w[i] = (unsigned int) x;
    i++;
  }
  r->n = a->n;
  cl_big_trim (r);
  return r;
}
static struct cl_big *cl_big_add (struct cl_big *a, struct cl_big *b)
{
  long n = a->n > b->n ? a->n : b->n, i = 0;
  struct cl_big *r = cl_big_new (n + 2);
  unsigned long long carry = 0;
  while (i < n) {
    unsigned long long x = carry;
    if (i < a->n) x = x + a->w[i];
    if (i < b->n) x = x + b->w[i];
    r->w[i] = (unsigned int) x;
    carry = x >> 32;
    i++;
  }
  r->w[n] = (unsigned int) carry;
  r->n = n + 1;
  cl_big_trim (r);
  return r;
}
static int cl_big_bit (struct cl_big *a, long i) { long w = i / 32; if (w >= a->n) return 0; return (a->w[w] >> (i % 32)) & 1; }
/* a / b: the quotient; *rem the rest (shift and subtract) */
static struct cl_big *cl_big_div (struct cl_big *a, struct cl_big *b, struct cl_big **rem)
{
  long i = cl_big_bits (a) - 1;
  struct cl_big *q = cl_big_new (a->n + 1);
  struct cl_big *r = cl_big_new (b->n + 2);
  q->n = a->n;
  while (i >= 0) {
    /* r = r * 2 + bit i of a, in place */
    unsigned int carry = cl_big_bit (a, i);
    long j = 0;
    while (j < r->n) { unsigned int top = r->w[j] >> 31; r->w[j] = (r->w[j] << 1) | carry; carry = top; j++; }
    if (carry) { r->w[r->n] = carry; r->n = r->n + 1; }
    if (cl_big_cmp (r, b) >= 0) {
      /* r = r - b, in place */
      long long borrow = 0;
      long m = 0;
      while (m < r->n) {
        long long x = (long long) r->w[m] - borrow;
        if (m < b->n) x = x - (long long) b->w[m];
        borrow = 0;
        if (x < 0) { x = x + 4294967296LL; borrow = 1; }
        r->w[m] = (unsigned int) x;
        m++;
      }
      cl_big_trim (r);
      q->w[i / 32] = q->w[i / 32] | ((unsigned int) 1 << (i % 32));
    }
    i--;
  }
  cl_big_trim (q);
  *rem = r;
  return q;
}
/* n / d (n > 0) to the nearest q * 2^e2, q of p bits (ties to even), e2 no lower than emin (FFold.pm's ratq) */
static struct cl_big *cl_ratq_div (struct cl_big *n, struct cl_big *d, long long e2)
{
  struct cl_big *nn = n, *dd = d, *qq, *r;
  int c;
  if (e2 >= 0) dd = cl_big_shl (d, e2); else nn = cl_big_shl (n, 0 - e2);
  qq = cl_big_div (nn, dd, &r);
  c = cl_big_cmp (cl_big_shl (r, 1), dd);
  if (c > 0 || (c == 0 && cl_big_bit (qq, 0))) qq = cl_big_add (qq, cl_big_small (1));
  return qq;
}
static struct cl_big *cl_ratq (struct cl_big *n, struct cl_big *d, long p, long long emin, long long *eout)
{
  long long e2 = cl_big_bits (n) - cl_big_bits (d) - p;
  struct cl_big *top = cl_big_shl (cl_big_small (1), p - 1), *over = cl_big_shl (cl_big_small (1), p), *q;
  while (cl_big_cmp (cl_ratq_div (n, d, e2), over) >= 0) e2++;
  while (cl_big_cmp (cl_ratq_div (n, d, e2), top) < 0 && e2 > emin) e2--;
  if (e2 < emin) e2 = emin;
  q = cl_ratq_div (n, d, e2);
  if (cl_big_cmp (q, over) >= 0) { e2++; q = cl_ratq_div (n, d, e2); }
  *eout = e2;
  return q;
}
/* q * 2^e2 as binary128's exact hex float with L (FFold.pm's qlit); 0 where its top bit is past emax */
static char *cl_hexdigits (struct cl_big *g, long digits)
{
  /* g as digits hex digits, its zeros at the end left out */
  char *h = alloc (digits + 1);
  long i = 0, last = 0;
  while (i < digits) {
    long at = (digits - 1 - i) * 4;
    int v = cl_big_bit (g, at) | (cl_big_bit (g, at + 1) << 1) | (cl_big_bit (g, at + 2) << 2) | (cl_big_bit (g, at + 3) << 3);
    h[i] = "0123456789abcdef"[v];
    if (v) last = i + 1;
    i++;
  }
  h[last] = 0;
  return h;
}
static char *cl_qlit (struct cl_big *q, long long e2, long long emax)
{
  long lead;
  long long xp;
  struct cs_buf b;
  if (cl_big_zero (q)) return "0x0p+0L";
  lead = cl_big_bits (q) - 1;
  xp = e2 + lead;
  if (xp > emax) return 0;
  cs_b_init (&b);
  if (xp >= 0 - 16382) {
    struct cl_big *g = cl_big_shl (cl_big_sub (q, cl_big_shl (cl_big_small (1), lead)), 112 - lead);
    char *h = cl_hexdigits (g, 28);
    cs_b_str (&b, "0x1");
    if (h[0]) { cs_b_byte (&b, '.'); cs_b_str (&b, h); }
    cs_b_byte (&b, 'p');
    if (xp >= 0) cs_b_byte (&b, '+');
    cs_b_ll (&b, xp);
    cs_b_byte (&b, 'L');
    return cl_copy (b.p, b.n);
  }
  {
    struct cl_big *g = cl_big_shl (q, e2 + 16494);
    cs_b_str (&b, "0x0.");
    cs_b_str (&b, cl_hexdigits (g, 28));
    cs_b_str (&b, "p-16382L");
    return cl_copy (b.p, b.n);
  }
}
/* a literal's text as n / d; 0 if it is no floating literal */
static int cl_lit_ratio (char *s, struct cl_big **np, struct cl_big **dp)
{
  struct cl_big *n = cl_big_small (0), *d = cl_big_small (1);
  long i = 0;
  long long ex = 0, fr = 0;
  int hex = s[0] == '0' && (s[1] == 'x' || s[1] == 'X'), seen = 0;
  if (hex) i = 2;
  for (;;) {
    int c = s[i], v = -1;
    if (c == '.') { seen = 1; i++; continue; }
    if (cl_digit (c)) v = c - '0';
    else if (hex && c >= 'a' && c <= 'f') v = c - 'a' + 10;
    else if (hex && c >= 'A' && c <= 'F') v = c - 'A' + 10;
    if (v < 0) break;
    n = cl_big_muladd (n, hex ? 16 : 10, v);
    if (seen) fr++;
    i++;
  }
  if ((!hex && (s[i] == 'e' || s[i] == 'E')) || (hex && (s[i] == 'p' || s[i] == 'P'))) {
    int neg = 0;
    i++;
    if (s[i] == '-') { neg = 1; i++; } else if (s[i] == '+') i++;
    while (cl_digit (s[i])) { ex = ex * 10 + (s[i] - '0'); i++; }
    if (neg) ex = 0 - ex;
  }
  if (hex) {
    long long e2 = ex - 4 * fr;
    if (e2 >= 0) n = cl_big_shl (n, e2); else d = cl_big_shl (d, 0 - e2);
  } else {
    long long e10 = ex - fr, k = 0, m = e10 >= 0 ? e10 : 0 - e10;
    while (k < m) { if (e10 >= 0) n = cl_big_muladd (n, 10, 0); else d = cl_big_muladd (d, 10, 0); k++; }
  }
  *np = n;
  *dp = d;
  return 1;
}
/* FFold.pm's ldround: a literal to the nearest of p bits, as that hex float */
static char *cl_ldround (char *s, long p, long long emin, long long emax)
{
  struct cl_big *n, *d, *q;
  long long e2;
  cl_lit_ratio (s, &n, &d);
  if (cl_big_zero (n)) return "0x0p+0L";
  q = cl_ratq (n, d, p, emin, &e2);
  return cl_qlit (q, e2, emax);
}
