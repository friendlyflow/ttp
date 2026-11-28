/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* ff2c.c: dev source of tools/ff2c.ff, gen/ff2c.pl in ff: ff's C layer as
   C, the definitions of a tree (a milestone's .ff.txt) written back as one
   C translation unit, read the way ttpc reads them, so that clang's AST of
   it can be held against clang's AST of the C they were made of
   (src/glibc/roundtrip.pl). The same files, messages and status as the
   Perl, which stays as a cross-check (make ff2c-crosscheck).

     ff2c [--shared FILE] [--pages page,...] [--target t] tree.ff.txt out.c names.txt
     ff2c [--shared FILE] [--target t] --split DIR tree.ff.txt list.txt names.txt

   --shared is the shared page (the Perl's ../shared.ff beside it). The
   tree is read as fftree.ff reads it and put in the C words of before by
   words.ff (the page's shim, f2_read_txt and f2_oldwords), as the Perl
   does with FF.pm and Words.pm; each sub of the Perl is a function here of
   its name. A die of the Perl inside an eval is a failure here (fail): it
   is set, everything returns at once to the eval's place (catch), and its
   message is the Perl's $@. On s2ff's lib.c, copied from tools/dev/s2ff. */

/* the tree as fftree.ff has it (its node, the type the shim's functions take) */
struct node { unsigned char hash[32]; long count; long room; struct node **kids; long len; unsigned char *text; };
/* the page's own runtime (f2c/shim.ff.txt; the dev build's shim.c) */
struct node *f2_read_txt (unsigned char *p, long n, char *name);
struct node *f2_read_ff (unsigned char *p, long n);
struct node *f2_oldwords (struct node *root, struct node *shared, long l32);
long f2_mkdir (char *path);

/* Memory: the runtime's alloc never frees, and a body's work makes some
   hundred times its C in strings, lists and scopes that are dropped after
   it (all of glibc, 40000 bodies, took 23 GB). So while a body or a
   global's items are written (tmode) what is allocated is temporary, in
   chunks used again for the next (mark, release); what stays (the names'
   C identifiers, the functions' signatures, the globals' types, the
   records' fields, a name c2ff left out, a compiled pattern and the
   matcher's stacks) is made in a permanent section (perm_begin, perm_end)
   with the runtime's alloc. */
void *alloc (long n);
#define CHUNK (1 << 24)
static unsigned char **chunk_p;
static long nchunks, chunk_at, chunk_used;
static int tmode, pdepth;
static void *xalloc (long n)
{
  unsigned char *p;
  long i;
  if (!tmode || pdepth || n > CHUNK / 4) return alloc (n);
  n = (n + 15) & ~15L;
  if (chunk_used + n > CHUNK) { chunk_at++; chunk_used = 0; }
  if (chunk_at >= nchunks) {
    unsigned char **x = alloc ((nchunks + 1) * sizeof (unsigned char *));
    for (i = 0; i < nchunks; i++) x[i] = chunk_p[i];
    x[nchunks++] = alloc (CHUNK);
    chunk_p = x;
  }
  p = chunk_p[chunk_at] + chunk_used;
  chunk_used += n;
  for (i = 0; i < n; i++) p[i] = 0;
  return p;
}
static void perm_begin (void) { pdepth++; }
static void perm_end (void) { pdepth--; }
/* the temporary chunks from here (tmode on), and back to where they were (tmode off) */
static long mark_at, mark_used;
static void temp_begin (void) { mark_at = chunk_at; mark_used = chunk_used; tmode = 1; }
static void temp_end (void) { chunk_at = mark_at; chunk_used = mark_used; tmode = 0; }
#define alloc xalloc
#include "lib.c"
#include "header.c"
/* a match makes what stays (its pattern compiled, the matcher's stacks grown): permanent */
static int mf_perm (struct str *x, char *pat, char *flags) { int r; perm_begin (); r = mf (x, pat, flags); perm_end (); return r; }
#define mf(x, p, f) mf_perm (x, p, f)

/* ---- the tree */
static int leaf (struct node *n) { return n->count == 0; }
static int is (struct node *n, char *s) { long k = slen (s); return n && n->len == k && msame (n->text, (unsigned char *) s, k); }
static struct str *c (struct node *n) { return s_new (n->text, n->len); }
static struct node *new_node (unsigned char *p, long n)
{
  struct node *x = alloc (sizeof (struct node));
  x->text = p; x->len = n;
  return x;
}
static struct node *new_text (char *s) { return new_node ((unsigned char *) s, slen (s)); }
static void add_kid (struct node *n, struct node *k)
{
  if (n->count == n->room) {
    long r = n->room * 2 + 4, i;
    struct node **ks = alloc (r * sizeof (struct node *));
    for (i = 0; i < n->count; i++) ks[i] = n->kids[i];
    n->kids = ks; n->room = r;
  }
  n->kids[n->count++] = k;
}
/* the content ends in a colon: name: (Perl's /^(.+):$/), and its name */
static int is_def (struct node *n) { return n->len >= 2 && n->text[n->len - 1] == ':'; }
static struct str *def_name (struct node *n) { return s_new (n->text, n->len - 1); }
/* /:$/ alone */
static int ends_colon (struct node *n) { return n->len >= 1 && n->text[n->len - 1] == ':'; }
static struct str *uncolon (struct node *n) { return ends_colon (n) ? s_new (n->text, n->len - 1) : c (n); }
/* FF.pm's is_layer: 0: 1: ... */
static int is_layer (struct node *n)
{
  long i;
  if (n->len < 2 || n->text[n->len - 1] != ':') return 0;
  for (i = 0; i < n->len - 1; i++) if (!is_digit (n->text[i])) return 0;
  return 1;
}
/* a list of nodes (Perl's @k): a vec of node pointers */
static struct vec *kids (struct node *n) { struct vec *v = v_new (); long i; for (i = 0; i < n->count; i++) v_push (v, n->kids[i]); return v; }
static struct node *K (struct vec *a, long i) { return (struct node *) a->v[i]; }
static struct vec *slice (struct vec *v, long a, long b)   /* @v[a .. b - 1] */
{
  struct vec *o = v_new ();
  long i;
  for (i = a; i < b && i < v->n; i++) if (i >= 0) v_push (o, v->v[i]);
  return o;
}
static struct vec *vec1n (struct node *n) { struct vec *v = v_new (); v_push (v, n); return v; }
static void v_cat (struct vec *a, struct vec *b) { long i; for (i = 0; i < b->n; i++) v_push (a, b->v[i]); }
/* a node of content w and these children, made (Perl's { content => .., children => [..] }) */
static struct node *node_of (struct str *w, struct vec *k)
{
  struct node *x = new_node (w->p, w->n);
  long i;
  for (i = 0; i < k->n; i++) add_kid (x, K (k, i));
  return x;
}

/* Perl's sort of strings (cmp), a merge sort (lib.c's is by insertion) */
static void sort_strs (struct vec *a)
{
  long n = a->n, w, i;
  void **x = a->v, **y;
  if (n < 2) return;
  y = alloc (n * sizeof (void *));
  for (w = 1; w < n; w *= 2) {
    for (i = 0; i < n; i += 2 * w) {
      long l = i, m = i + w < n ? i + w : n, r = i + 2 * w < n ? i + 2 * w : n, p = l, q = m, k = l;
      while (p < m && q < r) { if (s_cmp (x[q], x[p]) < 0) y[k++] = x[q++]; else y[k++] = x[p++]; }
      while (p < m) y[k++] = x[p++];
      while (q < r) y[k++] = x[q++];
    }
    { void **t = x; x = y; y = t; }
  }
  if (x != a->v) for (i = 0; i < n; i++) a->v[i] = x[i];
}
static struct vec *sorted_keys (struct hash *h)
{
  struct vec *a = v_new ();
  long i;
  for (i = 0; i < h->keys->n; i++) v_push (a, ((struct hent *) h->keys->v[i])->k);
  sort_strs (a);
  return a;
}

/* ---- failure: the Perl's die, caught by an eval, or not */
static int F;              /* a failure is on its way up */
static int in_eval;        /* how many evals are open */
static struct str *F_msg;  /* its message, the Perl's $@ */
static struct str *cur_fn; /* (our $cur_fn) */
static void die_now (struct str *m) { o_flush (); e_s (m); cp_exit (255); }
static void fail_s (struct str *what, struct node *n)
{
  struct str *m;
  if (F) return;
  m = s_of ("ff2c: ");
  s_app (m, what);
  if (n) { s_cat (m, " (at "); s_add (m, n->text, n->len); s_cat (m, ")"); }
  if (cur_fn) { s_cat (m, " in "); s_app (m, cur_fn); }
  s_cat (m, "\n");
  if (!in_eval) die_now (m);
  F = 1; F_msg = m;
}
static void fail (char *what, struct node *n) { fail_s (s_of (what), n); }
/* an eval { } around a call: try () before, catch () after it: 1 if it failed (its message in F_msg) */
static void try_ (void) { in_eval++; }
static int catch_ (void) { int f = F; in_eval--; F = 0; return f; }
static struct str *E_ (void) { return s_of (""); }   /* what a failing call gives back */

/* ---- the tables */
static struct str *target;   /* --target */
static struct hash *only;    /* --pages */
static struct hash *ckw, *scalar, *cidh, *taken;
static struct hash *rec, *enm, *fntype, *fn, *var, *econst, *glibcpage, *firstdef, *fieldcache;
static struct vec *order;
static struct vec *headers;  /* [file, lines] of each license after a comment naming its file */
struct rec { struct str *kind; struct node *node; };
struct param { struct str *name; struct ty *t; };
struct sig { struct ty *ret; struct vec *params; int va; long body; };
struct fn { char *kind; struct node *node; long from; struct str *target, *ctor; char *attr; int entry, missing; struct sig *sig; };
struct var { struct node *node; long from; int weak, tls, glibc; struct str *section, *bound, *align; struct ty *type; };
struct hdr2 { struct str *file; struct vec *lines; };
static struct rec *REC (struct str *n) { return h_pv (rec, n); }
static struct fn *FN (struct str *n) { return h_pv (fn, n); }
static struct var *VAR (struct str *n) { return h_pv (var, n); }
static int is_kind (struct fn *f, char *k) { return f && slen (f->kind) == slen (k) && msame ((unsigned char *) f->kind, (unsigned char *) k, slen (k)); }

static void tables (void)
{
  static char *sc[] = { "char", "char", "short", "short", "int", "int", "long", "long", "i8", "signed char", "i16", "short",
    "i32", "int", "i64", "long long", "u8", "unsigned char", "u16", "unsigned short", "u32", "unsigned int",
    "u64", "unsigned long", "void", "void", "float", "float", "double", "double", "long double", "long double",
    "float128", "__float128", "complex float128", "_Complex __float128", "i128", "__int128", "u128", "unsigned __int128", "float16", "_Float16", "bfloat16", "__bf16", "complex float16", "_Complex _Float16",
    "short fract", "short _Fract", "unsigned short fract", "unsigned short _Fract", "sat short fract", "_Sat short _Fract", "sat unsigned short fract", "_Sat unsigned short _Fract",
    "fract", "_Fract", "unsigned fract", "unsigned _Fract", "sat fract", "_Sat _Fract", "sat unsigned fract", "_Sat unsigned _Fract",
    "long fract", "long _Fract", "unsigned long fract", "unsigned long _Fract", "sat long fract", "_Sat long _Fract", "sat unsigned long fract", "_Sat unsigned long _Fract",
    "short accum", "short _Accum", "unsigned short accum", "unsigned short _Accum", "sat short accum", "_Sat short _Accum", "sat unsigned short accum", "_Sat unsigned short _Accum",
    "accum", "_Accum", "unsigned accum", "unsigned _Accum", "sat accum", "_Sat _Accum", "sat unsigned accum", "_Sat unsigned _Accum",
    "long accum", "long _Accum", "unsigned long accum", "unsigned long _Accum", "sat long accum", "_Sat long _Accum", "sat unsigned long accum", "_Sat unsigned long _Accum",
    "va_list", "__builtin_va_list", "complex float", "_Complex float", "complex double", "_Complex double",
    "complex long double", "_Complex long double", "complex float128", "_Complex __float128", 0 };
  long i;
  ckw = h_words ("auto break case char const continue default do double else enum extern float for goto if inline int long register restrict return short signed sizeof static struct switch typedef union unsigned void volatile while _Bool _Complex _Imaginary _Alignas _Alignof _Atomic _Generic _Noreturn _Static_assert _Thread_local");
  scalar = h_new ();
  for (i = 0; sc[i]; i += 2) h_setp (scalar, s_of (sc[i]), s_of (sc[i + 1]));
  if (s_is (target, "arm")) h_setp (scalar, s_of ("u64"), s_of ("unsigned long long"));
  cidh = h_new (); taken = h_new ();
  rec = h_new (); enm = h_new (); fntype = h_new (); fn = h_new (); var = h_new (); econst = h_new ();
  glibcpage = h_new (); firstdef = h_new (); fieldcache = h_new ();
  order = v_new (); headers = v_new ();
}
static int is_scalar (struct str *w) { return h_has (scalar, w); }
static struct str *scalar_c (struct str *w) { return h_pv (scalar, w); }

/* ---- names */
static struct str *cid_ (struct str *n);
static struct str *cid (struct str *n) { struct str *s; perm_begin (); s = cid_ (n); perm_end (); return s; }
static struct str *cid_ (struct str *n)
{
  struct str *s, *b;
  long i, k = 1;
  if (F) return E_ ();
  if (h_has (cidh, n)) return h_pv (cidh, n);
  s = s_dup (n);
  if (s->n && s->p[s->n - 1] == '\'') s->n--, s->p[s->n] = 0;
  for (i = 0; i < s->n; i++) if (!is_word (s->p[i])) s->p[i] = '_';
  if ((s->n && is_digit (s->p[0])) || h_has (ckw, s)) { struct str *x = s_of ("_"); s_app (x, s); s = x; }
  b = s;
  while (h_has (taken, s)) { s = s_dup (b); s_chr (s, '_'); s_app (s, s_num (++k)); }
  h_set (taken, s, 1);
  h_setp (cidh, n, s);
  return s;
}
static struct str *cid_local (struct str *n)
{
  struct str *s = s_dup (n);
  long i;
  if (s->n && s->p[s->n - 1] == '\'') s->n--, s->p[s->n] = 0;
  for (i = 0; i < s->n; i++) if (!is_word (s->p[i])) s->p[i] = '_';
  if (h_has (ckw, s)) { struct str *x = s_of ("_"); s_app (x, s); s = x; }
  return s;
}
static int clang_builtin (struct str *w)
{
  return mf (w, "^__builtin_|^__atomic_(?:always_lock_free|is_lock_free|thread_fence|signal_fence|load|store)$|^__clear_cache$", "");
}

/* ---- types: [scalar => w], [ptr => T or 0 (void)], [arr => T, count node], [rec => name], [enum => name], [fn => name], [fs => T], [vec => T, count node], [fndef => name] */
enum { T_SCALAR = 1, T_PTR, T_ARR, T_REC, T_ENUM, T_FN, T_FS, T_VEC, T_FNDEF };
struct ty { int k; struct str *w; struct ty *t; struct node *cnt; };
static struct ty *ty_new (int k, struct str *w, struct ty *t, struct node *cnt) { struct ty *x = alloc (sizeof (struct ty)); x->k = k; x->w = w; x->t = t; x->cnt = cnt; return x; }
static struct ty *ty_sc (char *w) { return ty_new (T_SCALAR, s_of (w), 0, 0); }
static struct ty *ty_ptr (struct ty *t) { return ty_new (T_PTR, 0, t, 0); }

static int is_typeword (struct str *w)
{
  return is_scalar (w) || s_is (w, "address") || s_is (w, "array") || s_is (w, "vector") || s_is (w, "fs") || h_has (rec, w) || h_has (enm, w) || h_has (fntype, w);
}
/* the type run at *i of a list of nodes */
static struct ty *ptype (struct vec *l, long *i)
{
  struct node *n;
  struct str *w;
  if (F) return 0;
  if (*i >= l->n) { fail ("a type that ends early", 0); return 0; }
  n = K (l, *i);
  w = c (n);
  (*i)++;
  if (is_scalar (w)) return ty_new (T_SCALAR, w, 0, 0);
  if (h_has (rec, w)) return ty_new (T_REC, w, 0, 0);
  if (h_has (enm, w)) return ty_new (T_ENUM, w, 0, 0);
  if (h_has (fntype, w)) return ty_new (T_FN, w, 0, 0);
  if (s_is (w, "address")) {
    /* (address alone: the address of nothing, void *) */
    if (*i >= l->n || !leaf (K (l, *i)) || !is_typeword (c (K (l, *i)))) return ty_ptr (0);
    return ty_ptr (ptype (l, i));
  }
  if (s_is (w, "fs")) return ty_new (T_FS, 0, ptype (l, i), 0);
  if (s_is (w, "array") || s_is (w, "vector")) {
    struct ty *t = ptype (l, i);
    if (F) return 0;
    if (*i >= l->n) { fail (s_is (w, "array") ? "an array without its count" : "a vector without its count", 0); return 0; }
    return ty_new (s_is (w, "array") ? T_ARR : T_VEC, 0, t, K (l, (*i)++));
  }
  { struct str *m = s_of ("not a type: "); s_app (m, w); fail_s (m, n); }
  return 0;
}

static int extern_arrays;   /* (local our $extern_arrays) */
static struct str *expr_item (struct vec *nodes);
static struct str *cname (struct str *n);
static struct str *trim_end (struct str *s) { while (s->n && is_space (s->p[s->n - 1])) s->n--; s->p[s->n] = 0; return s; }
static struct str *cat3 (char *a, struct str *b, char *c3) { struct str *s = s_of (a); s_app (s, b); s_cat (s, c3); return s; }
static struct str *count_text (struct node *n);
static struct str *ctype (struct ty *t);
/* a declarator: the type as C writes it around name */
static struct str *cdecl_ (struct ty *t, struct str *name, struct str *count)
{
  struct str *s;
  if (F || !t) return E_ ();
  if (!name) name = s_of ("");
  if (t->k == T_SCALAR) { s = s_dup (scalar_c (t->w)); s_chr (s, ' '); s_app (s, name); return trim_end (s); }
  if (t->k == T_REC) { s = s_of (s_is (REC (t->w)->kind, "struct") ? "struct " : "union "); s_app (s, cid (t->w)); s_chr (s, ' '); s_app (s, name); return trim_end (s); }
  if (t->k == T_ENUM) { s = s_of ("enum "); s_app (s, cid (t->w)); s_chr (s, ' '); s_app (s, name); return trim_end (s); }
  if (t->k == T_FN) { s = s_dup (cid (t->w)); s_chr (s, ' '); s_app (s, name); return trim_end (s); }
  if (t->k == T_PTR) {
    struct ty *to = t->t ? t->t : ty_sc ("void");
    struct str *in = s_of ("*");
    s_app (in, name);
    if (to->k == T_ARR) in = cat3 ("(", in, ")");
    return cdecl_ (to, in, 0);
  }
  /* (C's qualifier after the type it qualifies) */
  if (t->k == T_FS) { s = s_of ("__seg_fs "); s_app (s, name); return cdecl_ (t->t, trim_end (s), count); }
  if (t->k == T_ARR) {
    struct str *nn = count ? count : count_text (t->cnt);
    s = s_dup (name); s_chr (s, '['); s_app (s, nn); s_chr (s, ']');
    return cdecl_ (t->t, s, 0);
  }
  if (t->k == T_VEC) {
    struct str *e = ctype (t->t);
    s = s_of ("__attribute__((__vector_size__("); s_app (s, count_text (t->cnt)); s_cat (s, " * sizeof("); s_app (s, e); s_cat (s, ")))) ");
    s_app (s, e); s_chr (s, ' '); s_app (s, name);
    return trim_end (s);
  }
  fail ("Died", 0);
  return E_ ();
}
static struct str *cdecl (struct ty *t, struct str *name) { return cdecl_ (t, name, 0); }
static struct str *ctype (struct ty *t) { return cdecl_ (t, s_of (""), 0); }
/* an array's count: a number, a constant, or (a local's) a value */
static struct str *count_text (struct node *n)
{
  if (F) return E_ ();
  if (leaf (n) && is (n, "0") && extern_arrays) return s_of ("");
  if (leaf (n) && h_has (econst, c (n))) return cname (c (n));
  if (leaf (n)) return c (n);
  return expr_item (kids (n));
}

/* the fields of a record */
struct fld { struct str *name; struct ty *type; struct str *bits, *align; int packed; };
static struct vec *fields (struct str *name)
{
  struct rec *r = REC (name);
  struct vec *f = v_new (), *ks;
  long j;
  if (!r) return f;
  ks = kids (r->node);
  for (j = 0; j < ks->n && !F; j++) {
    struct node *x = K (ks, j);
    struct vec *l;
    struct fld *d;
    long i;
    int pk;
    if (is (x, "struct") || is (x, "union") || is (x, "comment") || is (x, "align") || (is (x, "packed") && leaf (x))) continue;
    d = alloc (sizeof (struct fld));
    d->name = uncolon (x);
    l = kids (x);
    /* (packed first: C's packed attribute; then align n: C's aligned attribute) */
    pk = l->n && is (K (l, 0), "packed") && leaf (K (l, 0)) ? 1 : 0;
    i = pk;
    if (i < l->n && is (K (l, i), "align") && !leaf (K (l, i))) { d->align = c (K (l, i)->kids[0]); i++; }
    d->type = ptype (l, &i);
    d->bits = i < l->n ? c (K (l, i)) : 0;
    d->packed = pk;
    v_push (f, d);
  }
  return f;
}
static struct vec *fields_of (struct str *r)
{
  struct vec *v = h_pv (fieldcache, r);
  if (!v) { perm_begin (); v = fields (r); if (!F) h_setp (fieldcache, r, v); perm_end (); }
  return v;
}
static struct ty *field (struct str *rname, struct str *f)
{
  struct vec *fl = fields_of (rname);
  long i;
  for (i = 0; i < fl->n && !F; i++) {
    struct fld *x = fl->v[i];
    if (s_eq (x->name, f)) return x->type;
    if (x->name->n == 0 && x->type && x->type->k == T_REC) { struct ty *t = field (x->type->w, f); if (t) return t; }
  }
  return 0;
}

/* ---- what a name is */
static struct vec *scopes;   /* the locals' scopes, innermost last: hashes of name to type */
static struct vec *noscopes; /* (none: between the bodies) */
static struct str *cur_last; /* the function's last parameter */
static struct hash *labels;  /* (our $labels) */
static struct ty *local_type (struct str *n)
{
  long i;
  for (i = scopes->n - 1; i >= 0; i--) { struct hash *s = scopes->v[i]; struct hent *e = h_find (s, n); if (e) return e->pv; }
  return 0;
}
static void scope_push (void) { v_push (scopes, h_new ()); }
static void scope_pop (void) { scopes->n--; }
static struct ty *gtype_ (struct str *n);
static struct ty *gtype (struct str *n) { struct ty *t; perm_begin (); t = gtype_ (n); perm_end (); return t; }
static struct ty *gtype_ (struct str *n)
{
  struct fn *f = FN (n);
  struct var *v;
  if (F) return 0;
  /* (a global of its own first: the asm page's alias of it) */
  if (f && is_kind (f, "alias") && !FN (f->target) && !VAR (n)) return gtype_ (f->target);
  v = VAR (n);
  if (!v) return 0;
  if (v->bound) { if (!v->type) v->type = ty_new (T_ARR, 0, gtype (v->bound), new_text ("0")); return v->type; }
  if (!v->type) { struct vec *l = kids (v->node); long i = v->from; v->type = ptype (l, &i); }
  return v->type;
}
static struct sig *atomic_sig (struct str *op, long bits);
/* a function's return type, parameters and whether it is variadic */
static struct sig *sig_ (struct str *n);
static struct sig *sig (struct str *n) { struct sig *s; perm_begin (); s = sig_ (n); perm_end (); return s; }
static struct sig *sig_ (struct str *n)
{
  struct fn *f = FN (n);
  struct vec *l;
  long i;
  struct sig *s;
  if (F || !f) return 0;
  if (is_kind (f, "alias")) return sig_ (f->target);
  if (f->sig) return f->sig;
  /* (libatomic's functions, asm where the target has real ones: C's types) */
  if (is_kind (f, "asm") && mf (n, "^__atomic_(\\w+)_([1248])$", "")) {
    struct str *op = g (1), *b = g (2);
    struct sig *x = atomic_sig (op, 8 * (b->p[0] - '0'));
    if (x) return f->sig = x;
  }
  s = alloc (sizeof (struct sig));
  if (is_kind (f, "asm")) { s->ret = ty_sc ("long"); return f->sig = s; }
  l = kids (f->node);
  i = f->from;
  s->ret = ptype (l, &i);
  if (F) return 0;
  if (is_kind (f, "weak")) return f->sig = s;
  s->params = v_new ();
  while (i < l->n) {
    struct node *p = K (l, i);
    struct vec *pl;
    long j = 0;
    struct ty *t;
    struct param *pa;
    if (leaf (p) && is (p, "...")) { s->va = 1; i++; continue; }
    if (!(is_def (p) && !leaf (p))) break;
    pl = kids (p);
    if (!is_typeword (c (K (pl, 0)))) break;
    t = ptype (pl, &j);
    if (F) return 0;
    if (j < pl->n) break;   /* a value after the type: a local, not a parameter */
    pa = alloc (sizeof (struct param)); pa->name = def_name (p); pa->t = t;
    v_push (s->params, pa);
    i++;
  }
  s->body = i;
  return f->sig = s;
}
static struct param *pr (char *n, struct ty *t) { struct param *p = alloc (sizeof (struct param)); p->name = s_of (n); p->t = t; return p; }
static struct sig *atomic_sig (struct str *op, long bits)
{
  struct str *uw = s_of ("u"); struct ty *u, *in = ty_sc ("int");
  struct sig *s = alloc (sizeof (struct sig));
  s_app (uw, s_num (bits));
  u = ty_new (T_SCALAR, uw, 0, 0);
  s->params = v_new ();
  if (s_is (op, "load")) { s->ret = u; v_push (s->params, pr ("p", ty_ptr (u))); v_push (s->params, pr ("order", in)); return s; }
  if (s_is (op, "store")) { s->ret = ty_sc ("void"); v_push (s->params, pr ("p", ty_ptr (u))); v_push (s->params, pr ("v", u)); v_push (s->params, pr ("order", in)); return s; }
  if (s_is (op, "compare_exchange")) {
    s->ret = in; v_push (s->params, pr ("p", ty_ptr (u))); v_push (s->params, pr ("e", ty_ptr (u))); v_push (s->params, pr ("d", u));
    v_push (s->params, pr ("success", in)); v_push (s->params, pr ("failure", in)); return s;
  }
  if (mf (op, "^(?:exchange|fetch_\\w+|\\w+_fetch)$", "")) { s->ret = u; v_push (s->params, pr ("p", ty_ptr (u))); v_push (s->params, pr ("v", u)); v_push (s->params, pr ("order", in)); return s; }
  return 0;
}
static struct sig *fnptr_sig (struct ty *t)
{
  struct vec *l;
  long i = 1;
  struct sig *s;
  if (F) return 0;
  if (t && t->k == T_PTR && t->t) t = t->t;
  /* (a function's own address, C's &f: its definition's result) */
  if (t && t->k == T_FNDEF && sig (t->w)) { s = alloc (sizeof (struct sig)); s->ret = sig (t->w)->ret; return s; }
  if (!(t && t->k == T_FN)) return 0;
  l = kids (h_pv (fntype, t->w));
  if (is (K (l, 0), "base pcs")) l = slice (l, 1, l->n);
  s = alloc (sizeof (struct sig));
  s->ret = ptype (l, &i);
  return F ? 0 : s;
}
/* a name in C: a local's, else a global's, function's or constant's */
static struct str *cname (struct str *n) { return local_type (n) ? cid_local (n) : cid (n); }

/* ---- expressions */
/* the operators' precedence, twice the Perl's (its ? is 1.5): 0 for none */
static long prec_of (struct node *n)
{
  static char *ops[] = { "=", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>=", 0 };
  static char *lv[] = { "?", "3", "||", "4", "&&", "6", "|", "8", "^", "10", "&", "12", "==", "14", "!=", "14", "<", "16", ">", "16", "<=", "16", ">=", "16",
    "<<", "18", ">>", "18", "+", "20", "-", "20", "*", "22", "/", "22", "%", "22", 0 };
  long i;
  for (i = 0; ops[i]; i++) if (is (n, ops[i])) return 2;
  for (i = 0; lv[i]; i += 2) if (is (n, lv[i])) { char *v = lv[i + 1]; long x = 0; while (*v) x = x * 10 + (*v++ - '0'); return x; }
  return 0;
}
static int is_prefixw (struct node *n) { return is (n, "-") || is (n, "!") || is (n, "~") || is (n, "++") || is (n, "--"); }
static int isbin (struct node *n) { return leaf (n) && prec_of (n); }

/* the items of a list of nodes: each an expression the operators join, or a node alone */
static struct vec *items (struct vec *ns)
{
  struct vec *its = v_new (), *cur = 0;
  long i, q = 0;
  int want = 0;
  for (i = 0; i < ns->n; i++) {
    struct node *n = K (ns, i);
    int lf = leaf (n);
    int isop = lf && (prec_of (n) || (is (n, ":") && q));
    if (cur && want) {
      v_push (cur, n);
      if (lf && is (n, "?")) q++;
      if (lf && is (n, ":") && q) q--;
      want = lf && (is_prefixw (n) || isop) ? 1 : 0;
      continue;
    }
    if (cur && lf && (is (n, "++") || is (n, "--"))) { v_push (cur, n); continue; }
    if (cur && isop) { v_push (cur, n); if (is (n, "?")) q++; if (is (n, ":")) q--; want = 1; continue; }
    if (cur) v_push (its, cur);
    cur = vec1n (n);
    q = lf && is (n, "?") ? 1 : 0;
    want = lf && (is_prefixw (n) || prec_of (n)) ? 1 : 0;
  }
  if (cur) v_push (its, cur);
  return its;
}

static struct str *operand (struct node *n, struct ty **t);
static struct str *binary (struct vec *l, long *pos, long min, struct ty **t);
static int is_ptr (struct ty *t);
static struct ty *nofs (struct ty *t) { while (t && t->k == T_FS) t = t->t; return t; }
static int is_ptr (struct ty *t) { t = nofs (t); return t && (t->k == T_PTR || t->k == T_ARR); }
/* an expression: its C, its type (or 0) */
static struct str *expr (struct vec *nodes, struct ty **t)
{
  long pos = 0;
  struct str *s;
  struct ty *x = 0;
  if (F) { if (t) *t = 0; return E_ (); }
  s = binary (nodes, &pos, 0, &x);
  if (!F && pos < nodes->n) fail ("more after an expression", K (nodes, pos));
  if (t) *t = x;
  return F ? E_ () : s;
}
static struct str *expr_item (struct vec *nodes) { return expr (nodes, 0); }
static struct str *unary (struct vec *l, long *pos, struct ty **t);
static struct str *paren3 (struct str *a, char *op, struct str *b) { struct str *s = s_of ("("); s_app (s, a); s_chr (s, ' '); s_cat (s, op); s_chr (s, ' '); s_app (s, b); s_chr (s, ')'); return s; }
static struct str *binary (struct vec *l, long *pos, long min, struct ty **t)
{
  struct ty *st = 0;
  struct str *s = unary (l, pos, &st);
  while (!F && *pos < l->n) {
    struct node *op = K (l, *pos);
    long p, right;
    struct str *w, *r;
    struct ty *rt = 0, *nt;
    if (!isbin (op)) break;
    w = c (op);
    p = prec_of (op);
    if (p < min) break;
    (*pos)++;
    if (s_is (w, "?")) {
      struct str *a, *b, *x;
      struct ty *at = 0, *bt = 0;
      /* c ? a : b, GNU's c ?: b */
      if (*pos < l->n && leaf (K (l, *pos)) && is (K (l, *pos), ":")) {
        (*pos)++;
        b = binary (l, pos, 3, &bt);
        x = s_of ("("); s_app (x, s); s_cat (x, " ?: "); s_app (x, b); s_chr (x, ')');
        s = x;
        continue;
      }
      a = binary (l, pos, 2, &at);
      if (F) break;
      if (*pos >= l->n) { fail ("a ? without its :", 0); break; }
      if (!(leaf (K (l, *pos)) && is (K (l, *pos), ":"))) { fail ("a ? without its :", K (l, *pos)); break; }
      (*pos)++;
      b = binary (l, pos, 3, &bt);
      x = s_of ("("); s_app (x, s); s_cat (x, " ? "); s_app (x, a); s_cat (x, " : "); s_app (x, b); s_chr (x, ')');
      s = x; st = at ? at : bt;
      continue;
    }
    right = p == 2 ? p : p + 2;   /* = is right to left */
    r = binary (l, pos, right, &rt);
    if (p == 2) nt = st;
    else if (s_is (w, "+") || s_is (w, "-")) nt = is_ptr (st) && !is_ptr (rt) ? st : s_is (w, "+") && is_ptr (rt) ? rt : 0;
    else nt = 0;
    /* (an array in a sum is a pointer) */
    if (p != 2 && nt && nt->k == T_ARR) nt = ty_ptr (nt->t);
    s = paren3 (s, (char *) w->p, r);
    st = nt;
  }
  *t = st;
  return s;
}
static struct str *unary (struct vec *l, long *pos, struct ty **t)
{
  struct node *n;
  struct str *s;
  struct ty *x = 0;
  *t = 0;
  if (F) return E_ ();
  if (*pos >= l->n) { fail ("an operand missing", 0); return E_ (); }
  n = K (l, *pos);
  if (leaf (n) && is_prefixw (n)) {
    struct str *o;
    (*pos)++;
    s = unary (l, pos, &x);
    o = s_of ("("); s_add (o, n->text, n->len); s_app (o, s); s_chr (o, ')');
    *t = is (n, "++") || is (n, "--") ? x : 0;
    return o;
  }
  (*pos)++;
  s = operand (n, &x);
  /* x ++ */
  while (!F && *pos < l->n && leaf (K (l, *pos)) && (is (K (l, *pos), "++") || is (K (l, *pos), "--"))) {
    struct str *o = s_of ("(");
    s_app (o, s); s_add (o, K (l, *pos)->text, K (l, *pos)->len); s_chr (o, ')');
    s = o;
    (*pos)++;
  }
  *t = x;
  return s;
}

/* text leaves as a C string */
static struct str *cstring (struct str *b)
{
  struct str *s = s_of ("\"");
  long i;
  for (i = 0; i < b->n; i++) {
    int x = b->p[i];
    if (x == 34) s_cat (s, "\\\"");
    else if (x == 92) s_cat (s, "\\\\");
    else if (x >= 32 && x < 127) s_chr (s, x);
    else { s_chr (s, '\\'); s_chr (s, '0' + (x >> 6)); s_chr (s, '0' + ((x >> 3) & 7)); s_chr (s, '0' + (x & 7)); }
  }
  s_chr (s, '"');
  return s;
}
static struct str *text_of (struct vec *ns) { struct str *s = s_of (""); long i; for (i = 0; i < ns->n; i++) s_add (s, K (ns, i)->text, K (ns, i)->len); return s; }
/* a global's items, after its type (an items group's children in its place) */
static struct vec *items_of (struct str *n)
{
  struct var *v = VAR (n);
  struct vec *l = kids (v->node), *o = v_new ();
  long i = v->from;
  ptype (l, &i);
  for (; i < l->n; i++) { struct node *x = K (l, i); if (is (x, "items")) v_cat (o, kids (x)); else v_push (o, x); }
  return o;
}
static struct vec *global_items (struct str *n)
{
  struct var *v = VAR (n);
  if (!v) return v_new ();
  return items_of (n);
}
static struct str *init_list (struct ty *t, struct vec *l);
static struct vec *elements (struct vec *ns);
struct st { int k; struct str *s; struct ty *t; };   /* k: 'e' expr, 's' stmt, 'd' decl */
static struct st *stmt_of (struct vec *e);
static struct str *path (struct str *s, struct ty *t, struct vec *l, struct ty **rt);
static struct str *callee (struct str *w);
static struct str *orig (struct str *n);
static struct node *synth (struct str *w, struct vec *k) { return node_of (w, k); }
static struct str *paren (struct str *a) { return cat3 ("(", a, ")"); }
static struct str *cast_text (struct ty *t, struct str *v) { struct str *s = s_of ("(("); s_app (s, ctype (t)); s_cat (s, ")("); s_app (s, v); s_cat (s, "))"); return s; }
static struct str *join_items (struct vec *its)   /* join(', ', map { expr_item($_) } @its) */
{
  struct str *s = s_of ("");
  long i;
  for (i = 0; i < its->n && !F; i++) { if (i) s_cat (s, ", "); s_app (s, expr_item (its->v[i])); }
  return s;
}
static struct str *hexlower (unsigned long v) { return s_hex (v, 0, 0); }
static long num_of (struct node *n)   /* a leaf as Perl's number of it: a - and the digits it begins with */
{
  long v = 0, i = 0, neg = 0;
  if (i < n->len && n->text[i] == '-') { neg = 1; i++; }
  for (; i < n->len && is_digit (n->text[i]); i++) v = v * 10 + (n->text[i] - '0');
  return neg ? -v : v;
}

static struct str *operand (struct node *n, struct ty **t)
{
  struct str *w = c (n), *s;
  struct vec *k = kids (n);
  long i, dot = -1;
  *t = 0;
  if (F) return E_ ();
  /* (weak / name or a call: the reference C writes, weak by its declaration) */
  if (s_is (w, "weak") && k->n == 1) return operand (K (k, 0), t);
  /* a path from an expression: the node cut at the ., the rest a path */
  for (i = 0; i < k->n; i++) if (leaf (K (k, i)) && is (K (k, i), ".")) { dot = i; break; }
  if (dot >= 0) {
    struct ty *x = 0;
    struct sig *f;
    s = operand (synth (w, slice (k, 0, dot)), &x);
    if (F) return E_ ();
    /* (a function's address with nothing after the . is called without arguments) */
    if (dot == k->n - 1 && (f = fnptr_sig (x))) { *t = f->ret; return cat3 ("(", s, ")()"); }
    return path (paren (s), x, slice (k, dot + 1, k->n), t);
  }
  if (!k->n) {
    struct ty *lt;
    struct sig *sg;
    if (mf (w, "^-?(?:0x[0-9a-fA-F]+|\\d+)$", "")) { *t = ty_sc ("int"); return w; }
    /* (a hex float one exponent past its type's range: infinity, or with a fraction a NaN) */
    if (mf (w, "^0x1(\\.[0-9a-f]*)?p\\+(128f|1024|16384L|16384Q)$", "i")) {
      struct str *frac = g0 (1), *e = g (2), *o;
      char *sfx = "l", *tn = "long double";
      if (s_is (e, "128f")) { sfx = "f"; tn = "float"; }
      else if (s_is (e, "1024")) { sfx = ""; tn = "double"; }
      else if (s_is (e, "16384Q")) { sfx = "f128"; tn = "float128"; }
      *t = ty_sc (tn);
      if (mf (frac, "[1-9a-f]", "i")) { o = s_of ("__builtin_nan"); s_cat (o, sfx); s_cat (o, "(\"\")"); }
      else { o = s_of ("__builtin_inf"); s_cat (o, sfx); s_cat (o, "()"); }
      return o;
    }
    if (mf (w, "^-?0x[0-9a-f.]+p[-+]\\d+L$", "i")) { *t = ty_sc ("long double"); return w; }
    /* (float128's Q, x86_64's __float128: GNU C's Q) */
    if (mf (w, "^-?0x[0-9a-f.]+p[-+]\\d+Q$", "i")) { *t = ty_sc ("float128"); return w; }
    if (mf (w, "^-?0x[0-9a-f.]+p[-+]\\d+f?$", "i")) { *t = ty_sc (mf (w, "f$", "") ? "float" : "double"); return w; }
    if (s_is (w, "va_arg_pack")) return s_of ("__builtin_va_arg_pack()");
    if (s_is (w, "va_arg_pack_len")) return s_of ("__builtin_va_arg_pack_len()");
    if ((lt = local_type (w))) { *t = lt; return cid_local (w); }
    if (s_is (w, "tp")) { *t = ty_ptr (0); return s_of ("tp"); }
    if (clang_builtin (w)) return cat3 ("", w, "()");
    /* (a compound literal c2ff made a global of its own: the literal again) */
    if (mf (w, " literal \\d+$", "") && VAR (w)) {
      struct ty *gt = gtype (w);
      struct str *o = s_of ("((");
      s_app (o, ctype (gt)); s_chr (o, ')'); s_app (o, init_list (gt, items_of (w))); s_chr (o, ')');
      *t = gt;
      return F ? E_ () : o;
    }
    if ((lt = gtype (w))) { *t = lt; return cid (w); }
    if (F) return E_ ();
    if (h_has (econst, w)) { *t = ty_new (T_ENUM, h_pv (econst, w), 0, 0); return cid (w); }
    /* a function named alone is called; a label in an asm function is its address */
    { struct fn *f = FN (w); if (f && is_kind (f, "asm") && f->entry) { *t = ty_ptr (0); return cid (w); } }
    if ((sg = sig (w))) { *t = sg->ret; return cat3 ("", callee (w), "()"); }
    if (F) return E_ ();
    { struct str *m = s_of ("an unknown name "); s_app (m, w); fail_s (m, 0); }
    return E_ ();
  }
  if (s_is (w, ":")) {
    struct vec *e = elements (k), *lit = 0, *sts = v_new ();
    struct str *o;
    long all = 1;
    if (F) return E_ ();
    /* (a complex type and its two parts after it, real then imaginary, is that complex number) */
    if (e->n >= 3) {
      struct vec *x = e->v[e->n - 3];
      if (x->n == 1 && leaf (K (x, 0)) && mf (c (K (x, 0)), "^complex (.+)$", "") && is_scalar (c (K (x, 0))) && !local_type (c (K (x, 0)))) {
        lit = slice (e, e->n - 3, e->n); e->n -= 3;
      }
    }
    /* (its value is its last item's: a : there is one too, not a block) */
    for (i = 0; i < e->n && !F; i++) {
      struct vec *x = e->v[i];
      if (x->n == 1 && is (K (x, 0), ":") && !leaf (K (x, 0))) {
        struct st *q = alloc (sizeof (struct st));
        q->k = 'e'; q->s = operand (K (x, 0), &q->t);
        v_push (sts, q);
      } else v_push (sts, stmt_of (x));
    }
    if (F) return E_ ();
    if (lit) {
      struct str *ct = c (K ((struct vec *) lit->v[0], 0)), *ew = s_sub (ct, 8, ct->n);
      struct ty *et = ty_new (T_SCALAR, ew, 0, 0);
      struct st *q = alloc (sizeof (struct st));
      q->k = 'e';
      q->s = s_of ("__builtin_complex(");
      for (i = 1; i <= 2; i++) { if (i == 2) s_cat (q->s, ", "); s_cat (q->s, "(("); s_app (q->s, ctype (et)); s_cat (q->s, ")("); s_app (q->s, expr_item (lit->v[i])); s_cat (q->s, "))"); }
      s_chr (q->s, ')');
      q->t = ty_new (T_SCALAR, ct, 0, 0);
      v_push (sts, q);
    }
    if (F) return E_ ();
    if (sts->n == 1 && ((struct st *) sts->v[0])->k == 'e') { struct st *q = sts->v[0]; *t = q->t; return paren (q->s); }
    for (i = 0; i < sts->n; i++) if (((struct st *) sts->v[i])->k != 'e') all = 0;
    if (all) {
      o = s_of ("(");
      for (i = 0; i < sts->n; i++) { if (i) s_cat (o, ", "); s_app (o, ((struct st *) sts->v[i])->s); }
      s_chr (o, ')');
      *t = sts->n ? ((struct st *) sts->v[sts->n - 1])->t : 0;
      return o;
    }
    o = s_of ("({ ");
    for (i = 0; i < sts->n; i++) { struct st *q = sts->v[i]; if (i) s_chr (o, ' '); s_app (o, q->s); if (q->k == 'e') s_chr (o, ';'); }
    s_cat (o, " })");
    { struct st *q = sts->v[sts->n - 1]; *t = q->k == 'e' ? q->t : 0; }
    return o;
  }
  if (s_is (w, "address")) {
    struct node *f;
    struct str *fw;
    /* (a : around one item is that item: address / : / free is &(free)) */
    while (k->n == 1 && is (K (k, 0), ":") && K (k, 0)->count == 1) k = kids (K (k, 0));
    f = K (k, 0);
    fw = c (f);
    if (leaf (f) && is_typeword (fw) && !local_type (fw) && !gtype (fw)) {
      long j = 0, a;
      struct ty *pt = ptype (k, &j);
      struct vec *rest = slice (k, j, k->n);
      int allleaf = 1;
      if (F) return E_ ();
      for (a = 0; a < rest->n; a++) if (!leaf (K (rest, a))) allleaf = 0;
      if (pt->k == T_SCALAR && (s_is (pt->w, "char") || s_is (pt->w, "u8")) && rest->n && allleaf) { *t = ty_ptr (pt); return cstring (text_of (rest)); }
      if (!rest->n) { fail ("address of a type without a value", n); return E_ (); }
      s = expr (rest, 0);
      *t = ty_ptr (pt);
      return cast_text (ty_ptr (pt), s);
    }
    if (F) return E_ ();
    if (!leaf (f) && is_scalar (fw) && !local_type (fw) && k->n == 1) {
      /* (a scalar's: C's &(unsigned int){0}) */
      struct str *o = s_of ("(&("); s_app (o, ctype (ty_new (T_SCALAR, fw, 0, 0))); s_cat (o, "){"); s_app (o, expr_item (kids (f))); s_cat (o, "})");
      *t = ty_ptr (ty_new (T_SCALAR, fw, 0, 0));
      return o;
    }
    if (!leaf (f) && is_typeword (fw) && !local_type (fw) && !gtype (fw) && k->n == 1) {
      /* a typed literal's or a compound literal's address */
      struct ty *x = 0;
      s = operand (f, &x);
      *t = ty_ptr (x);
      return cat3 ("(&", s, ")");
    }
    if (F) return E_ ();
    /* a text c2ff made a global: the string again */
    if (k->n == 1 && mf (fw, "^text \\d+$", "") && f->count == 1 && is (f->kids[0], "0")) {
      struct vec *b = global_items (fw);
      struct str *by = s_of ("");
      /* (its items bytes, or text leaves over 255 bytes: csema's, stdio-common's bug28) */
      for (i = 0; i < b->n; i++) { struct str *iw = c (K (b, i)); if (mf (iw, "^\\d+$", "")) s_chr (by, (int) num_of (K (b, i))); else s_app (by, iw); }
      if (b->n && is (K (b, b->n - 1), "0")) by->n--;
      *t = ty_ptr (ty_sc ("char"));
      return cstring (by);
    }
    if (k->n == 1 && mf (fw, "^wide text \\d+$", "") && f->count == 1 && is (f->kids[0], "0")) {
      struct ty *gt = gtype (fw);
      struct vec *e = global_items (fw);
      struct str *o, *ew = gt->t->w;
      char *p = "L";
      if (s_is (ew, "u32")) p = "U"; else if (s_is (ew, "u16")) p = "u";
      o = s_of (p); s_chr (o, '"');
      for (i = 0; i < e->n; i++) { s_cat (o, "\\x"); s_app (o, hexlower ((unsigned long) num_of (K (e, i)))); }
      s_chr (o, '"');
      *t = ty_ptr (gt->t);
      return o;
    }
    /* a label's address (GNU C's &&L); a function's */
    if (k->n == 1 && leaf (f) && !local_type (fw) && labels && h_has (labels, fw)) { *t = ty_ptr (0); return cat3 ("(&&", cid_local (fw), ")"); }
    if (k->n == 1 && leaf (f) && !local_type (fw) && !gtype (fw) && sig (fw)) { *t = ty_ptr (ty_new (T_FNDEF, fw, 0, 0)); return cat3 ("(&", callee (fw), ")"); }
    if (F) return E_ ();
    /* a name c2ff left out (an asm variant no milestone has): as an asm function */
    if (k->n == 1 && leaf (f) && !local_type (fw) && !gtype (fw) && !h_has (econst, fw)) {
      struct fn *x;
      perm_begin ();
      x = alloc (sizeof (struct fn));
      x->kind = "asm"; x->missing = 1; fw = s_dup (fw);
      h_setp (fn, fw, x); v_push (order, fw);
      perm_end ();
      *t = ty_ptr (0);
      return cat3 ("(&", cid (fw), ")");
    }
    {
      struct ty *x = 0;
      s = expr (k, &x);
      *t = ty_ptr (x);
      return F ? E_ () : cat3 ("(&", s, ")");
    }
  }
  /* a complex value's parts: C's __real__ and __imag__ */
  if (s_is (w, "real") || s_is (w, "imag")) {
    struct ty *x = 0;
    struct str *o;
    s = expr (k, &x);
    o = s_of ("(__"); s_app (o, w); s_cat (o, "__ ("); s_app (o, s); s_cat (o, "))");
    if (x && x->k == T_SCALAR && mf (x->w, "^complex (.+)$", "")) *t = ty_new (T_SCALAR, g (1), 0, 0);
    return o;
  }
  if (s_is (w, "content")) {
    struct ty *x = 0;
    s = expr (k, &x);
    *t = x && (x->k == T_PTR || x->k == T_ARR) ? x->t : 0;
    return cat3 ("(*", s, ")");
  }
  /* C11's _Generic: an association's name is its type, address as often as it says and then one type name */
  if (s_is (w, "generic")) {
    struct str *xs = expr (vec1n (K (k, 0)), 0), *o;
    struct ty *rt = 0;
    o = s_of ("_Generic("); s_app (o, xs);
    for (i = 1; i < k->n && !F; i++) {
      struct node *as = K (k, i);
      struct str *name = uncolon (as), *v;
      struct ty *vt = 0;
      struct vec *wv = v_new ();
      long j = 0;
      v = expr (kids (as), &vt);
      if (!rt) rt = vt;
      s_cat (o, ", ");
      if (s_is (name, "default")) { s_cat (o, "default: "); s_app (o, v); continue; }
      while (name->n > 8 && msame (name->p, (unsigned char *) "address ", 8)) { v_push (wv, new_text ("address")); name = s_sub (name, 8, name->n); }
      v_push (wv, new_node (name->p, name->n));
      s_app (o, ctype (ptype (wv, &j))); s_cat (o, ": "); s_app (o, v);
    }
    s_chr (o, ')');
    *t = rt;
    return F ? E_ () : o;
  }
  if (s_is (w, "cast:")) {
    long j = 0;
    struct ty *ct = ptype (k, &j);
    s = expr (slice (k, j, k->n), 0);
    *t = ct;
    return F ? E_ () : cast_text (ct, s);
  }
  if (s_is (w, "sizeof") || s_is (w, "alignof")) {
    char *op = "_Alignof(";
    if (s_is (w, "sizeof")) op = "sizeof(";
    long j = 0;
    struct ty *x;
    *t = ty_sc ("u64");
    /* of a variable (a variable-length array's) */
    if (k->n == 1 && leaf (K (k, 0)) && (local_type (c (K (k, 0))) || gtype (c (K (k, 0))))) { struct ty *y = 0; return cat3 (op, operand (K (k, 0), &y), ")"); }
    x = ptype (k, &j);
    return F ? E_ () : cat3 (op, ctype (x), ")");
  }
  /* an array compound literal: array / its element's type / its count / items */
  if (s_is (w, "array") || s_is (w, "vector")) {
    struct vec *l = vec1n (new_node (w->p, w->n));
    long j = 0;
    struct ty *x;
    struct str *o;
    v_cat (l, k);
    x = ptype (l, &j);
    if (F) return E_ ();
    o = s_of ("(("); s_app (o, ctype (x)); s_chr (o, ')'); s_app (o, init_list (x, slice (l, j, l->n))); s_chr (o, ')');
    *t = x;
    return F ? E_ () : o;
  }
  if (s_is (w, "syscall")) { *t = ty_sc ("long"); return cat3 ("__ff_syscall(", join_items (items (k)), ")"); }
  if (s_is (w, "va_arg")) {
    struct vec *its = items (k), *fl = v_new ();
    struct str *ap = expr_item (its->v[0]), *o;
    long j = 0;
    struct ty *x;
    for (i = 1; i < its->n; i++) v_cat (fl, its->v[i]);
    x = ptype (fl, &j);
    if (F) return E_ ();
    o = s_of ("__builtin_va_arg("); s_app (o, ap); s_cat (o, ", "); s_app (o, ctype (x)); s_chr (o, ')');
    *t = x;
    return o;
  }
  if (s_is (w, "va_start")) { struct str *o = s_of ("__builtin_va_start("); s_app (o, expr_item (k)); s_cat (o, ", "); s_app (o, cur_last); s_chr (o, ')'); return o; }
  if (s_is (w, "va_end")) return cat3 ("__builtin_va_end(", expr_item (k), ")");
  if (s_is (w, "va_copy")) return cat3 ("__builtin_va_copy(", join_items (items (k)), ")");
  if (s_is (w, "alloca")) { *t = ty_ptr (0); return cat3 ("__builtin_alloca(", expr_item (k), ")"); }
  /* a type with a value: a typed literal, a conversion, a compound literal */
  if (is_scalar (w) && !local_type (w)) {
    struct ty *x = ty_new (T_SCALAR, w, 0, 0);
    *t = x;
    if (k->n == 1 && leaf (K (k, 0)) && mf (c (K (k, 0)), "^\\d+$|^0x[0-9a-f]+$", "i")) {
      char *sfx = 0;
      if (s_is (w, "u64")) { sfx = "UL"; if (s_is (target, "arm")) sfx = "ULL"; }
      else if (s_is (w, "long")) sfx = "L";
      else if (s_is (w, "i64")) sfx = "LL";
      else if (s_is (w, "u32")) sfx = "U";
      else if (s_is (w, "int")) sfx = "";
      if (sfx) { struct str *o = c (K (k, 0)); s_cat (o, sfx); return o; }
    }
    s = expr (k, 0);
    return F ? E_ () : cast_text (x, s);
  }
  if (h_has (rec, w) && !local_type (w) && !gtype (w)) {
    struct ty *x = ty_new (T_REC, w, 0, 0);
    struct str *o = s_of ("((");
    s_app (o, ctype (x)); s_chr (o, ')'); s_app (o, init_list (x, k)); s_chr (o, ')');
    *t = x;
    return F ? E_ () : o;
  }
  if (F) return E_ ();
  /* a call */
  /* (x86_64's pcmpistri of an immediate, c2ff's of gcc's _mm_cmpistri, _mm_cmpistrc, _mm_cmpistrz: those again, the immediate last) */
  if (mf (w, "^__builtin_ia32_pcmpistr(i|ic|iz)128 (0x[0-9a-f]+)$", "")) {
    struct str *v = g (1), *imm = g (2), *o = s_of ("_mm_cmpistr");
    struct vec *its = items (k);
    s_cat (o, s_is (v, "i") ? "i" : s_is (v, "ic") ? "c" : "z");
    s_chr (o, '(');
    s_app (o, join_items (its));
    if (its->n) s_cat (o, ", ");
    s_app (o, imm); s_chr (o, ')');
    *t = ty_sc ("int");
    return o;
  }
  /* (c2ff's call of libatomic's generic __atomic_load or __atomic_store, the size first: gcc's builtin again, without it) */
  if (mf (w, "^__atomic_(load|store)$", "") && !local_type (w)) {
    struct vec *its = items (k);
    *t = ty_sc ("void");
    s = s_dup (w); s_chr (s, '('); s_app (s, join_items (slice (its, 1, its->n))); s_chr (s, ')');
    return s;
  }
  if (!local_type (w) && !gtype (w) && (sig (w) || mf (w, "^__builtin_", ""))) {
    struct sig *sg = sig (w);
    struct str *o;
    if (F) return E_ ();
    o = s_dup (callee (w)); s_chr (o, '('); s_app (o, join_items (items (k))); s_chr (o, ')');
    *t = sg ? sg->ret : 0;
    return F ? E_ () : o;
  }
  if (F) return E_ ();
  /* a path from a variable */
  {
    struct ty *x = 0;
    s = operand (new_node (w->p, w->n), &x);
    if (F) return E_ ();
    return path (s, x, k, t);
  }
}

/* a function's name as called: a builtin's as clang has it */
static struct str *callee (struct str *w)
{
  if (mf (w, "^(__builtin_\\w+)(?: .*)?$", "")) return g (1);
  if (clang_builtin (w)) return w;
  return cid (w);
}

/* elements and fields after a value: s the C so far, t its type */
static struct str *path (struct str *s, struct ty *t, struct vec *l, struct ty **rt)
{
  long at = 0;
  *rt = 0;
  while (at < l->n && !F) {
    struct node *n = K (l, at);
    struct ty *pt, *ft;
    struct str *rn = 0;
    struct sig *f;
    t = nofs (t);
    pt = t && t->k == T_PTR ? nofs (t->t) : 0;
    if (t && t->k == T_REC) rn = t->w; else if (pt && pt->k == T_REC) rn = pt->w;
    /* (another . in a path: what came before it is the value, the rest a path from it) */
    if (leaf (n) && is (n, ".")) {
      at++;
      if (at >= l->n && (f = fnptr_sig (t))) { *rt = f->ret; return cat3 ("(", s, ")()"); }
      s = paren (s);
      continue;
    }
    if (rn && leaf (n) && (ft = field (rn, c (n)))) {
      struct str *o = s_of ("(");
      s_app (o, s); s_cat (o, t->k == T_PTR ? "->" : "."); s_app (o, cid_local (c (n))); s_chr (o, ')');
      s = o; t = ft; at++;
      continue;
    }
    if (F) break;
    if ((f = fnptr_sig (t))) {
      /* through a function's address: the rest are its arguments */
      struct str *o = s_of ("(");
      s_app (o, s); s_cat (o, ")("); s_app (o, join_items (items (slice (l, at, l->n)))); s_chr (o, ')');
      *rt = f->ret;
      return o;
    }
    {
      struct vec *first = items (slice (l, at, l->n))->v[0];
      struct str *ix, *o;
      at += first->n;
      ix = expr (first, 0);
      o = s_of ("("); s_app (o, s); s_chr (o, '['); s_app (o, ix); s_cat (o, "])");
      s = o;
      t = t && (t->k == T_PTR || t->k == T_ARR) ? t->t : 0;
    }
  }
  *rt = t;
  return F ? E_ () : s;
}

/* ---- initializers */
static void flat_items (struct vec *l, struct vec *o)
{
  long i;
  for (i = 0; i < l->n; i++) { struct node *x = K (l, i); if (is (x, "items")) flat_items (kids (x), o); else v_push (o, x); }
}
static struct str *init_item (struct ty *t, struct vec *it);
/* the items of an initializer of type t, as C's braces */
static struct str *init_list (struct ty *t, struct vec *l)
{
  struct vec *fi = v_new (), *its, *fl = v_new (), *parts = v_new ();
  struct str *o;
  long i;
  if (F || !t) return E_ ();
  /* (nothing in braces: gaih_inet's struct gaih_result res = {}) */
  if (t->k == T_REC && l->n == 1 && leaf (K (l, 0)) && is (K (l, 0), ":")) {
    struct vec *f = fields_of (t->w);
    if (f->n) { struct fld *f1 = f->v[0]; if (f1->type->k != T_REC && f1->type->k != T_ARR) return s_of ("{}"); }
  }
  /* (items in items: an array past 255 items) */
  flat_items (l, fi);
  its = items (fi);
  /* a char array set from text */
  if (t->k == T_ARR && t->t->k == T_SCALAR && (s_is (t->t->w, "char") || s_is (t->t->w, "u8") || s_is (t->t->w, "i8")) && fi->n) {
    int ok = 1;
    for (i = 0; i < fi->n; i++) if (!leaf (K (fi, i)) || mf (c (K (fi, i)), "^-?(?:0x[0-9a-f]+|\\d+)$", "i")) ok = 0;
    if (ok) return cstring (text_of (fi));
  }
  if (t->k == T_REC) {
    struct vec *a = fields_of (t->w);
    for (i = 0; i < a->n; i++) { struct fld *f = a->v[i]; if (!f->bits || !mf (f->name, "^padding \\d+$", "")) v_push (fl, f); }
  }
  for (i = 0; i < its->n && !F; i++) {
    struct ty *et;
    /* (a flexible array member, the last field, array T 0, takes the items after it) */
    if (t->k == T_REC && i == fl->n - 1 && ((struct fld *) fl->v[i])->type->k == T_ARR && is (((struct fld *) fl->v[i])->type->cnt, "0") && i < its->n - 1) {
      struct fld *f = fl->v[i];
      struct str *x = s_of ("{");
      long j;
      for (j = i; j < its->n; j++) { if (j > i) s_cat (x, ", "); s_app (x, init_item (f->type->t, its->v[j])); }
      s_chr (x, '}');
      v_push (parts, x);
      break;
    }
    et = t->k == T_ARR || t->k == T_VEC ? t->t : i < fl->n ? ((struct fld *) fl->v[i])->type : 0;
    v_push (parts, init_item (et, its->v[i]));
  }
  if (F) return E_ ();
  /* a union set through a member not its first: ttpc sets by place, zeros first */
  if (t->k == T_REC && s_is (REC (t->w)->kind, "union") && parts->n > 1) {
    o = s_of ("{ .");
    s_app (o, cid_local (((struct fld *) fl->v[parts->n - 1])->name)); s_cat (o, " = "); s_app (o, parts->v[parts->n - 1]); s_cat (o, " }");
    return o;
  }
  o = s_of ("{");
  for (i = 0; i < parts->n; i++) { if (i) s_cat (o, ", "); s_app (o, parts->v[i]); }
  s_chr (o, '}');
  return o;
}
static struct str *init_item (struct ty *t, struct vec *it)
{
  if (it->n == 1 && is (K (it, 0), ":") && t && (t->k == T_REC || t->k == T_ARR)) return init_list (t, kids (K (it, 0)));
  return expr_item (it);
}

/* ---- statements */
static int is_stmtword (struct node *n)
{
  static char *w[] = { "if", "else", "else if", "while", "do while", "for", "switch", "case", "default", "return", "goto", "break", "continue", "comment", "line", 0 };
  long i;
  for (i = 0; w[i]; i++) if (is (n, w[i])) return 1;
  return 0;
}
/* the elements of a body: statement nodes, declarations, labels, and expression items */
static struct vec *elements (struct vec *ns)
{
  struct vec *e = v_new (), *run = v_new ();
  long i;
  for (i = 0; i < ns->n; i++) {
    struct node *n = K (ns, i);
    int st = (is_stmtword (n) && !local_type (c (n))) || (is_def (n) && !is (n, "cast:"));
    if (st && (!run->n || !(isbin (K (run, run->n - 1)) || (is_prefixw (K (run, run->n - 1)) && leaf (K (run, run->n - 1)))))) {
      if (run->n) v_cat (e, items (run));
      run = v_new ();
      v_push (e, vec1n (n));
      continue;
    }
    v_push (run, n);
  }
  if (run->n) v_cat (e, items (run));
  return e;
}
static struct st *st_new (int k, struct str *s, struct ty *t) { struct st *x = alloc (sizeof (struct st)); x->k = k; x->s = s; x->t = t; return x; }
static struct str *stext (struct st *x) { return x->k == 'e' ? cat3 ("", x->s, ";") : x->s; }
static struct str *decl (struct str *name, struct node *n);
static struct str *control (struct node *n);
static struct st *stmt_of (struct vec *e)
{
  struct node *n = K (e, 0);
  long i;
  if (F) return st_new ('e', E_ (), 0);
  if (e->n == 1 && is_def (n) && !is (n, "cast:")) {
    struct str *name = def_name (n), *o;
    struct vec *k = kids (n), *ss;
    /* (a local's align n first: C's aligned attribute; then its cleanup / f: C's cleanup attribute) */
    long j = k->n > 1 && is (K (k, 0), "align") && K (k, 0)->count == 1 && leaf (K (k, 0)->kids[0]) ? 1 : 0;
    if (k->n > j + 1 && is (K (k, j), "cleanup") && K (k, j)->count == 1 && leaf (K (k, j)->kids[0])) j++;
    if (k->n > j && leaf (K (k, j)) && is_typeword (c (K (k, j))) && !local_type (c (K (k, j)))) return st_new ('d', decl (name, n), 0);
    /* a label: its statements after it */
    ss = elements (k);
    o = s_dup (cid_local (name)); s_cat (o, ": ");
    if (!ss->n) s_chr (o, ';');
    for (i = 0; i < ss->n && !F; i++) { if (i) s_chr (o, ' '); s_app (o, stext (stmt_of (ss->v[i]))); }
    return st_new ('s', o, 0);
  }
  if (e->n == 1 && is_stmtword (n)) return st_new ('s', control (n), 0);
  /* (a : with a path after it is an expression) */
  if (e->n == 1 && is (n, ":")) {
    int haspath = 0;
    for (i = 0; i < n->count; i++) if (leaf (n->kids[i]) && is (n->kids[i], ".")) haspath = 1;
    if (!haspath) {
      struct vec *ss;
      struct str *o = s_of ("{ ");
      scope_push ();
      ss = elements (kids (n));
      for (i = 0; i < ss->n && !F; i++) { if (i) s_chr (o, ' '); s_app (o, stext (stmt_of (ss->v[i]))); }
      scope_pop ();
      /* (a : as a statement is a block) */
      s_cat (o, " }");
      return st_new ('s', o, 0);
    }
  }
  {
    struct ty *t = 0;
    struct str *s = expr (e, &t);
    return st_new ('e', s, t);
  }
}
static struct str *block (struct vec *ns)
{
  struct vec *e;
  struct str *o = s_of ("{ ");
  long i;
  scope_push ();
  e = elements (ns);
  for (i = 0; i < e->n && !F; i++) { if (i) s_chr (o, ' '); s_app (o, stext (stmt_of (e->v[i]))); }
  scope_pop ();
  s_cat (o, " }");
  return o;
}
static int copy_of (struct ty *t, struct vec *init);
static struct str *decl (struct str *name, struct node *n)
{
  struct vec *k = kids (n), *init;
  long i = 0;
  struct str *aln = 0, *clu = 0, *d;
  struct ty *t;
  if (is (K (k, 0), "align") && !leaf (K (k, 0))) { aln = c (K (k, 0)->kids[0]); i = 1; }
  if (i < k->n && is (K (k, i), "cleanup") && !leaf (K (k, i))) { clu = c (K (k, i)->kids[0]); i++; }
  t = ptype (k, &i);
  if (F) return E_ ();
  init = slice (k, i, k->n);
  if (!scopes->n) scope_push ();
  h_setp (scopes->v[scopes->n - 1], name, t);
  d = cdecl (t, cid_local (name));
  if (aln) { s_cat (d, " __attribute__((aligned("); s_app (d, aln); s_cat (d, ")))"); }
  if (clu) { s_cat (d, " __attribute__((cleanup("); s_app (d, cid (clu)); s_cat (d, ")))"); }
  if (!init->n) return cat3 ("", d, ";");
  if (t->k == T_ARR || (t->k == T_REC && !copy_of (t, init))) { s_cat (d, " = "); s_app (d, init_list (t, init)); s_chr (d, ';'); return d; }
  s_cat (d, " = "); s_app (d, expr_item (init)); s_chr (d, ';');
  return d;
}
/* whether a struct's one item is a value of its type (a copy) */
static int copy_of (struct ty *t, struct vec *init)
{
  struct vec *its = items (init);
  struct ty *it = 0;
  int f;
  if (its->n != 1) return 0;
  if (((struct vec *) its->v[0])->n == 1 && is (K ((struct vec *) its->v[0], 0), ":")) return 0;
  try_ ();
  expr (its->v[0], &it);
  f = catch_ ();
  if (f) it = 0;
  return it && it->k == T_REC && s_eq (it->w, t->w);
}
/* the first item of a list, then the nodes after it */
static struct vec *items_head (struct vec *k, struct vec **rest)
{
  struct vec *its = items (k), *first = its->n ? its->v[0] : v_new ();
  *rest = slice (k, first->n, k->n);
  return first;
}
static struct str *control (struct node *n)
{
  struct vec *k = kids (n), *rest;
  struct str *o;
  long i;
  if (is (n, "break")) return s_of ("break;");
  if (is (n, "continue")) return s_of ("continue;");
  if (is (n, "comment")) return s_of ("");
  /* (line / file / n: where c2ff found the statement after it, C's #line; the round trip compares the code) */
  if (is (n, "line")) return s_of ("");
  if (is (n, "return")) return k->n ? cat3 ("return ", expr_item (k), ";") : s_of ("return;");
  if (is (n, "goto")) {
    if (is (K (k, 0), "content")) return cat3 ("goto *", expr_item (kids (K (k, 0))), ";");
    return cat3 ("goto ", cid_local (c (K (k, 0))), ";");
  }
  if (is (n, "if") || is (n, "else if")) {
    struct vec *cond = items_head (k, &rest);
    o = s_of (is (n, "else if") ? "else if (" : "if ("); s_app (o, expr_item (cond)); s_cat (o, ") "); s_app (o, block (rest));
    return o;
  }
  if (is (n, "else")) return cat3 ("else ", block (k), "");
  if (is (n, "while")) { struct vec *cond = items_head (k, &rest); o = s_of ("while ("); s_app (o, expr_item (cond)); s_cat (o, ") "); s_app (o, block (rest)); return o; }
  if (is (n, "do while")) { struct vec *cond = items_head (k, &rest); o = s_of ("do "); s_app (o, block (rest)); s_cat (o, " while ("); s_app (o, expr_item (cond)); s_cat (o, ");"); return o; }
  if (is (n, "for")) {
    struct vec *e, *body = v_new ();
    struct str *p[3];
    scope_push ();
    e = elements (k);
    for (i = 0; i < 3; i++) {
      struct vec *x = i < e->n ? e->v[i] : 0;
      /* (an empty : an empty part; one with items their value, C's comma) */
      if (!x) p[i] = s_of ("");
      else if (x->n == 1 && is (K (x, 0), ":")) { struct ty *y = 0; p[i] = leaf (K (x, 0)) ? s_of ("") : operand (K (x, 0), &y); }
      else { struct st *q = stmt_of (x); p[i] = q->s; if (q->k == 'd' && q->s->n && q->s->p[q->s->n - 1] == ';') p[i] = s_sub (q->s, 0, q->s->n - 1); }
    }
    for (i = 3; i < e->n; i++) v_cat (body, e->v[i]);
    o = s_of ("for ("); s_app (o, p[0]); s_cat (o, "; "); s_app (o, p[1]); s_cat (o, "; "); s_app (o, p[2]); s_cat (o, ") "); s_app (o, block (body));
    scope_pop ();
    return o;
  }
  if (is (n, "switch")) {
    struct vec *v = items_head (k, &rest), *e;
    o = s_of ("switch ("); s_app (o, expr_item (v)); s_cat (o, ") { ");
    scope_push ();
    e = elements (rest);
    for (i = 0; i < e->n && !F; i++) { if (i) s_chr (o, ' '); s_app (o, stext (stmt_of (e->v[i]))); }
    scope_pop ();
    s_cat (o, " }");
    return o;
  }
  if (is (n, "case")) {
    struct vec *e = elements (k);
    long at = 1;
    o = s_of ("case "); s_app (o, expr_item (e->v[0]));
    if (e->n > 1 && ((struct vec *) e->v[1])->n == 1 && is (K ((struct vec *) e->v[1], 0), "...")) { s_cat (o, " ... "); s_app (o, expr_item (e->v[2])); at = 3; }
    s_cat (o, ": ");
    if (at >= e->n) s_chr (o, ';');
    for (i = at; i < e->n && !F; i++) { if (i > at) s_chr (o, ' '); s_app (o, stext (stmt_of (e->v[i]))); }
    return o;
  }
  if (is (n, "default")) {
    struct vec *e = elements (k);
    o = s_of ("default: ");
    if (!e->n) s_chr (o, ';');
    for (i = 0; i < e->n && !F; i++) { if (i) s_chr (o, ' '); s_app (o, stext (stmt_of (e->v[i]))); }
    return o;
  }
  { struct str *m = s_of ("the statement "); s_add (m, n->text, n->len); fail_s (m, n); }
  return E_ ();
}

/* ---- the definitions */
/* a page item is a global when its items have children only as :, address, cast: or a typed literal; else a function */
static int is_function (struct node *d)
{
  long i;
  for (i = 0; i < d->count; i++) {
    struct node *k = d->kids[i];
    struct str *w;
    long j;
    int nl = 0;
    if (leaf (k)) continue;
    if (is (k, ":") || is (k, "address") || is (k, "cast:") || is (k, "items") || is (k, "align") || is (k, "sizeof") || is (k, "alignof")) continue;
    w = c (k);
    for (j = 0; j < k->count; j++) if (!leaf (k->kids[j])) nl = 1;
    if ((is_scalar (w) || h_has (rec, w)) && !nl) continue;
    return 1;
  }
  return 0;
}
static void node_text (struct node *n, struct str *o)
{
  long i;
  s_add (o, n->text, n->len); s_chr (o, '(');
  for (i = 0; i < n->count; i++) { if (i) s_chr (o, ','); node_text (n->kids[i], o); }
  s_chr (o, ')');
}
static int same_text (struct node *a, struct node *b) { struct str *x = s_of (""), *y = s_of (""); node_text (a, x); node_text (b, y); return s_eq (x, y); }
static struct fn *fn_new (char *kind, struct node *node, long from) { struct fn *f = alloc (sizeof (struct fn)); f->kind = kind; f->node = node; f->from = from; return f; }
static struct var *var_new (struct node *node, long from) { struct var *v = alloc (sizeof (struct var)); v->node = node; v->from = from; return v; }

static void definitions (struct node *page)
{
  struct str *pgc = c (page);
  int glibc;
  long i;
  struct vec *k = kids (page);
  if (is (page, "comment") || is (page, "license")) return;
  glibc = mf (pgc, "^(?:glibc|gcc) ", "") && !mf (pgc, "^(?:glibc|gcc) asm:$", "") && (!only || h_has (only, uncolon (page)));
  /* (each license after a comment naming its file: that file's header) */
  for (i = 1; i < k->n; i++) {
    struct node *l = K (k, i), *cm = K (k, i - 1);
    struct hdr2 *h;
    long j;
    if (!(is (l, "license") && is (cm, "comment") && cm->count)) continue;
    if (!mf (c (cm->kids[0]), "^(?:glibc|gcc)-\\S+ (.+)$", "")) continue;
    h = alloc (sizeof (struct hdr2));
    h->file = g (1);
    h->lines = v_new ();
    for (j = 1; j < l->count; j++) v_push (h->lines, c (l->kids[j]));
    v_push (headers, h);
  }
  /* (a page's definitions through its layers, 0: 1: ...: flat already) */
  for (i = 0; i < k->n; i++) {
    struct node *d = K (k, i);
    struct str *name, *w, *aln = 0;
    struct vec *dk;
    struct node *prev;
    if (is (d, "comment") || is (d, "license")) continue;
    if (!ends_colon (d)) fail ("not a definition", d);
    name = uncolon (d);
    /* (a definition twice over, c2ff's static of one name in a function: one; if they differ, C says so) */
    if ((prev = h_pv (firstdef, name)) && same_text (prev, d)) continue;
    h_setp (firstdef, name, d);
    /* (with / names first: what placing it places too, which C does not say) */
    if (d->count && is (d->kids[0], "with") && !leaf (d->kids[0])) { long j; for (j = 1; j < d->count; j++) d->kids[j - 1] = d->kids[j]; d->count--; }
    dk = kids (d);
    w = dk->n ? c (K (dk, 0)) : s_of ("");
    /* a global's align n first (C's aligned attribute): the words after it as before */
    if (s_is (w, "align") && !leaf (K (dk, 0))) { aln = c (K (dk, 0)->kids[0]); dk = slice (dk, 1, dk->n); w = dk->n ? c (K (dk, 0)) : s_of (""); }
    v_push (order, name);
    if (s_is (w, "struct") || s_is (w, "union")) { struct rec *r = alloc (sizeof (struct rec)); r->kind = w; r->node = d; h_setp (rec, name, r); }
    else if (s_is (w, "enum")) {
      long j;
      h_setp (enm, name, d);
      for (j = 1; j < dk->n; j++) {
        struct node *x = K (dk, j);
        struct vec *xs = is (x, "items") ? kids (x) : vec1n (x);
        long m2;
        for (m2 = 0; m2 < xs->n; m2++) { struct node *y = K (xs, m2); if (ends_colon (y) && !h_has (econst, uncolon (y))) h_setp (econst, uncolon (y), name); }
      }
    }
    /* (a function type: on c2ff's types page, or a builtins page's own) */
    else if (s_is (w, "function")) h_setp (fntype, name, d);
    else if (s_is (w, "alias")) { struct fn *f = fn_new ("alias", 0, 0); f->target = c (K (dk, 1)); h_setp (fn, name, f); }
    else if (s_is (w, "ifunc")) h_setp (fn, name, fn_new ("ifunc", d, 2));
    else if (s_is (w, "asm")) {
      long j;
      h_setp (fn, name, fn_new ("asm", 0, 0));
      /* (and each entry of it, a block whose first child is asm) */
      for (j = 0; j < dk->n; j++) {
        struct node *b = K (dk, j);
        if (!leaf (b) && is_def (b) && is (b->kids[0], "asm")) {
          struct str *e = def_name (b);
          if (!FN (e)) { struct fn *f = fn_new ("asm", 0, 0); f->entry = 1; h_setp (fn, e, f); }
          v_push (order, e);
        }
      }
    }
    else if (s_is (w, "weak")) {
      if (dk->n > 1 && is (K (dk, 1), "function")) h_setp (fn, name, fn_new ("weak", d, 2));
      else { struct var *v = var_new (d, 1); v->weak = 1; h_setp (var, name, v); }
    }
    /* a constructor or destructor (and its priority): C's attribute */
    else if (s_is (w, "constructor") || s_is (w, "destructor")) {
      struct fn *f = fn_new ("c", d, 1);
      struct node *x = K (dk, 0);
      f->ctor = s_dup (w);
      if (x->count) { s_chr (f->ctor, '('); s_add (f->ctor, x->kids[0]->text, x->kids[0]->len); s_chr (f->ctor, ')'); }
      h_setp (fn, name, f);
      if (glibc) h_set (glibcpage, name, 1);
    }
    /* base pcs: arm's base procedure call standard, C's pcs ("aapcs") */
    else if (s_is (w, "base pcs") && dk->n > 1 && is (K (dk, 1), "function")) h_setp (fntype, name, d);
    else if (s_is (w, "base pcs")) { struct fn *f = fn_new ("c", d, 1); f->attr = "pcs(\"aapcs\")"; h_setp (fn, name, f); if (glibc) h_set (glibcpage, name, 1); }
    else if (s_is (w, "thread local")) { struct var *v = var_new (d, 1); v->tls = 1; v->glibc = glibc; h_setp (var, name, v); }
    /* a global of a named section; its bounds __start_ and __stop_ of the name are arrays of its type */
    else if (s_is (w, "section")) {
      struct str *sec = c (K (dk, 1));
      struct var *v = var_new (d, 2);
      long j;
      v->glibc = glibc; v->section = sec;
      h_setp (var, name, v);
      for (j = 0; j < 2; j++) {
        struct str *b = s_of (j ? "__stop_" : "__start_");
        s_app (b, sec);
        if (VAR (b)) continue;
        { struct var *bv = alloc (sizeof (struct var)); bv->bound = name; h_setp (var, b, bv); }
        v_push (order, b);
      }
    }
    else if (is_function (d)) { h_setp (fn, name, fn_new ("c", d, 0)); if (glibc) h_set (glibcpage, name, 1); }
    else { struct var *v = var_new (d, 0); v->glibc = glibc; h_setp (var, name, v); }
    /* (past its align) */
    if (aln) { struct var *v = VAR (name); if (v && v->node == d) { v->from++; v->align = aln; } }
  }
}

/* ---- the unit */
static struct vec *C;      /* the lines of out.c (@c) */
static struct vec *Cdecl;  /* (--split) each line's C names it declares, or 0 */
static void push_c (struct str *l) { v_push (C, l); v_push (Cdecl, 0); }
static void cdeclares (struct str *line, struct vec *ids) { v_push (C, line); v_push (Cdecl, ids); }
static struct vec *ids1 (struct str *a) { struct vec *v = v_new (); v_push (v, a); return v; }
static struct hash *rdone;
static void emit_rec (struct str *r);
static void rec_deps (struct str *r)
{
  struct vec *fl = fields_of (r);
  long i;
  for (i = 0; i < fl->n; i++) {
    struct fld *f = fl->v[i];
    struct ty *t = f->type;
    while (t->k == T_ARR) t = t->t;
    if (t->k != T_REC) continue;
    /* an anonymous member is written where it stands: what it holds first */
    if (f->name->n == 0) rec_deps (t->w); else emit_rec (t->w);
  }
}
/* a record's fields in braces; an anonymous member (C11's) as its own fields in braces of their own */
static struct str *rec_body (struct str *r)
{
  struct vec *fl = fields_of (r);
  struct str *o = s_of ("{ ");
  long i;
  int save = extern_arrays;
  for (i = 0; i < fl->n; i++) {
    struct fld *f = fl->v[i];
    if (i) s_chr (o, ' ');
    /* (the last field, array T 0, is a flexible array member: T x[]) */
    extern_arrays = i == fl->n - 1;
    if (f->name->n == 0 && f->type->k == T_REC) { s_app (o, REC (f->type->w)->kind); s_chr (o, ' '); s_app (o, rec_body (f->type->w)); s_chr (o, ';'); }
    else {
      struct str *nm = f->bits && mf (f->name, "^padding \\d+$", "") ? s_of ("") : cid_local (f->name);
      s_app (o, cdecl (f->type, nm));
      if (f->bits) { s_cat (o, " : "); s_app (o, f->bits); }
      if (f->align) { s_cat (o, " __attribute__((aligned("); s_app (o, f->align); s_cat (o, ")))"); }
      if (f->packed) s_cat (o, " __attribute__((packed))");
      s_chr (o, ';');
    }
    extern_arrays = save;
  }
  s_cat (o, " }");
  return o;
}
static void emit_rec (struct str *r)
{
  struct node *rn = REC (r)->node;
  struct str *aln = 0, *o;
  long i;
  int pk = 0;
  if (h_has (rdone, r)) return;
  h_set (rdone, r, 1);
  rec_deps (r);
  /* (a record's own align, after struct: C's aligned attribute after its braces; and packed: C's packed record) */
  for (i = 0; i < rn->count; i++) {
    struct node *x = rn->kids[i];
    if (is (x, "align") && !leaf (x) && !aln) aln = c (x->kids[0]);
    if (is (x, "packed") && leaf (x)) pk = 1;
  }
  o = s_dup (REC (r)->kind); s_chr (o, ' '); s_app (o, cid (r)); s_chr (o, ' '); s_app (o, rec_body (r));
  if (pk) s_cat (o, " __attribute__((packed))");
  if (aln) { s_cat (o, " __attribute__((aligned("); s_app (o, aln); s_cat (o, ")))"); }
  s_chr (o, ';');
  cdeclares (o, ids1 (cid (r)));
}
static struct str *proto (struct str *name)
{
  struct sig *s = sig (name);
  struct str *ps, *x;
  long i;
  if (!s->params) ps = s_of ("");
  else if (s->params->n || s->va) {
    ps = s_of ("");
    for (i = 0; i < s->params->n; i++) { if (i) s_cat (ps, ", "); s_app (ps, ctype (((struct param *) s->params->v[i])->t)); }
    if (s->va) { if (s->params->n) s_cat (ps, ", "); s_cat (ps, "..."); }
  } else ps = s_of ("void");
  x = s_dup (cid (name)); s_chr (x, '('); s_app (x, ps); s_chr (x, ')');
  return cdecl (s->ret, x);
}
/* the labels of a body: name: nodes that are no declaration */
static void labels_in (struct vec *l, struct hash *o)
{
  long i;
  for (i = 0; i < l->n; i++) {
    struct node *n = K (l, i);
    if (is_def (n) && !is (n, "cast:") && !(n->count && leaf (n->kids[0]) && is_typeword (c (n->kids[0])))) h_set (o, def_name (n), 1);
    labels_in (kids (n), o);
  }
}
/* the name a function had in C: without c2ff's ' and its unit */
static struct str *unq (struct str *s) { s = s_dup (s); if (s->n && s->p[s->n - 1] == '\'') { s->n--; s->p[s->n] = 0; } return s; }
static struct str *orig (struct str *n)
{
  if (mf (n, "^(\\S+) \\S+/\\S+$", "")) return g (1);
  /* a function's static: its own name (of a unit's own function too) */
  if (mf (n, "^(\\S+ \\S+/\\S+) (\\S+)$", "")) { struct str *a = g (1), *b = g (2); if (FN (a)) return unq (b); }
  /* (a later one of its name: name#k, roundtrip.pl's) */
  if (mf (n, "^(\\S+(?: \\S+/\\S+)?) (\\S+) (\\d+)$", "")) {
    struct str *a = g (1), *b = g (2), *kno = g (3);
    if (FN (a) && !s_is (b, "literal")) { struct str *o = unq (b); s_chr (o, '#'); s_app (o, kno); return o; }
  }
  if (mf (n, "^(\\S+) (\\S+)$", "")) { struct str *a = g (1), *b = g (2); if (FN (a)) return unq (b); }
  return unq (n);
}
static struct str *join_tab (char *a, struct str *b, struct str *c3, struct str *d)
{
  struct str *s = s_of (a);
  s_chr (s, '\t'); s_app (s, b); s_chr (s, '\t'); s_app (s, c3);
  if (d) { s_chr (s, '\t'); s_app (s, d); }
  return s;
}

/* ---- reading: the tree through its layers, weak / x as x (a weak reference: C writes it so); a : field of a scalar type (C's unnamed bitfield) padding n: again */
static struct node *unweak (struct node *n) { while (is (n, "weak") && n->count == 1) n = n->kids[0]; return n; }
static void flat (struct node *n, long depth)
{
  struct node **ks = n->kids;
  long cnt = n->count, i;
  n->kids = 0; n->count = 0; n->room = 0;
  for (i = 0; i < cnt; i++) {
    struct node *k = ks[i];
    if (is_layer (k)) { long j; flat (k, depth + 1); for (j = 0; j < k->count; j++) add_kid (n, k->kids[j]); }
    else { k = unweak (k); flat (k, depth + 1); add_kid (n, k); }
  }
}
/* (the Perl's block-local %scalar there: the integer words) */
static int padword (struct node *n)
{
  static char *w[] = { "char", "short", "int", "long", "i8", "i16", "i32", "i64", "i128", "u8", "u16", "u32", "u64", "u128", 0 };
  long i;
  for (i = 0; w[i]; i++) if (is (n, w[i])) return 1;
  return 0;
}
static void pad (struct node *n)
{
  long i;
  if (n->count && leaf (n->kids[0]) && (is (n->kids[0], "struct") || is (n->kids[0], "union"))) {
    long k = 0;
    for (i = 1; i < n->count; i++) {
      struct node *f = n->kids[i];
      if (is (f, ":") && f->count && padword (f->kids[0])) {
        struct str *w = s_of ("padding ");
        s_app (w, s_num (++k)); s_chr (w, ':');
        f->text = w->p; f->len = w->n;
      }
    }
  }
  for (i = 0; i < n->count; i++) pad (n->kids[i]);
}
/* (on arm a UL is 32 bits, its unsigned long: Words.pm's long32, words.ff has none; a UL before a number is a U, which is u32 too) */
static void long32 (struct node *n)
{
  long i;
  for (i = 0; i + 1 < n->count; i++) {
    struct node *x = n->kids[i], *y = n->kids[i + 1];
    if (leaf (x) && is (x, "UL") && leaf (y) && mf (c (y), "^-?(?:\\d+|0x[0-9a-fA-F]+)$", "")) { x->text = (unsigned char *) "U"; x->len = 1; }
  }
  for (i = 0; i < n->count; i++) long32 (n->kids[i]);
}
/* a file's bytes, else the Perl's die: its message (what, then $!) and the errno as status */
static struct str *slurp_or_die (char *path, struct str *what)
{
  struct str *t = read_all (path);
  if (!t) {
    long fd = s2_open (path), e = fd < 0 ? -fd : 2;
    s_cat (what, strerror_of (e)); s_cat (what, "\n");
    o_flush (); e_s (what); cp_exit ((int) e);
  }
  return t;
}
static long fcreate (char *path)
{
  long fd = cp_create (path);
  if (fd < 0) { struct str *m = s_of ("ff2c: "); s_cat (m, path); s_cat (m, ": "); s_cat (m, strerror_of (-fd)); s_cat (m, "\n"); o_flush (); e_s (m); cp_exit ((int) -fd); }
  return fd;
}
static void fwrite_all (long fd, struct str *s) { long i = 0; while (i < s->n) { long w = cp_write ((int) fd, s->p + i, s->n - i); if (w <= 0) break; i += w; } }

static char *split_dir;
static void write_split (char *out, struct vec *gdefline, struct vec *cbody, struct vec *cbodyunit, struct hash *fnunit);
struct gdl { long line; struct str *hint, *sf; };

int ff2c_main (int argc, char **argv)
{
  long a = 1, i;
  char *in, *out, *namesout, *shared = "shared.ff";
  struct str *t, *sh;
  struct node *root, *shr;
  struct vec *top, *names, *gnames, *gdefline, *cbody, *cbodyunit;
  struct hash *fnunit;
  target = s_of ("");
  while (a + 1 < argc && (!slen (argv[a]) ? 0 : (s_is (s_of (argv[a]), "--pages") || s_is (s_of (argv[a]), "--target") || s_is (s_of (argv[a]), "--split") || s_is (s_of (argv[a]), "--shared")))) {
    struct str *o = s_of (argv[a]), *v = s_of (argv[a + 1]);
    if (s_is (o, "--pages")) { struct vec *p = ssplit (",", v, 0); if (!only) only = h_new (); for (i = 0; i < p->n; i++) h_set (only, p->v[i], 1); }
    else if (s_is (o, "--split")) split_dir = argv[a + 1];
    else if (s_is (o, "--shared")) shared = argv[a + 1];
    else target = v;
    a += 2;
  }
  if (argc - a < 3) { e_str ("usage: ff2c.pl [--pages page,...] [--target t] tree.ff.txt out.c names.txt\n"); cp_exit (255); }
  in = argv[a]; out = argv[a + 1]; namesout = argv[a + 2];
  tables ();
  noscopes = v_new ();
  scopes = noscopes;
  t = slurp_or_die (in, cat3 ("ff2c: ", s_of (in), ": "));
  root = f2_read_txt (t->p, t->n, in);
  /* The C words now (Words.pm): read in the words of before, which the rest of ff2c knows */
  sh = slurp_or_die (shared, s_of ("ff2c: shared.ff: "));
  shr = f2_read_ff (sh->p, sh->n);
  for (i = 0; i < root->count; i++) flat (root->kids[i], 0);
  if (s_is (target, "arm")) long32 (root);
  root = f2_oldwords (root, shr, s_is (target, "arm"));
  for (i = 0; i < root->count; i++) pad (root->kids[i]);
  top = kids (root);

  for (i = 0; i < top->n; i++) definitions (K (top, i));

  C = v_new (); Cdecl = v_new (); rdone = h_new ();
  {
    struct str *x = s_of ("/* made by ff2c.pl from "), *base = s_of (in);
    long j = base->n;
    while (j > 0 && base->p[j - 1] != '/') j--;
    s_app (x, s_sub (base, j, base->n)); s_cat (x, " */");
    push_c (x);
  }
  /* the header of each file, as the file has it (gen/headers.pl checks them) */
  for (i = 0; i < headers->n; i++) {
    struct hdr2 *h = headers->v[i];
    push_c (cat3 ("/* ff2c: the header of ", h->file, " */"));
    push_c (header_text (h->lines));
  }
  if (headers->n) push_c (s_of ("/* ff2c: the end of the headers */"));
  cdeclares (s_of ("long __ff_syscall(long, ...);"), ids1 (s_of ("__ff_syscall")));
  cdeclares (s_of ("extern void *tp;"), ids1 (s_of ("tp")));
  /* (gcc's SSE4.2 compares of an immediate, <smmintrin.h>'s, whose calls c2ff makes builtins) */
  {
    static char *x[] = { "i", "c", "z" };
    for (i = 0; i < 3; i++) {
      struct str *l = s_of ("int _mm_cmpistr");
      s_cat (l, x[i]); s_cat (l, "(__attribute__((__vector_size__(2 * sizeof(long long)))) long long, __attribute__((__vector_size__(2 * sizeof(long long)))) long long, const int);");
      cdeclares (l, ids1 (cat3 ("_mm_cmpistr", s_of (x[i]), "")));
    }
  }
  /* the records first as names, so that each may point at any */
  for (i = 0; i < order->n; i++) { struct str *n = order->v[i]; if (REC (n)) { struct str *l = s_dup (REC (n)->kind); s_chr (l, ' '); s_app (l, cid (n)); s_chr (l, ';'); cdeclares (l, ids1 (cid (n))); } }
  /* the enums: a constant's value where it has one (a constant two enums of the tree have is the first's) */
  for (i = 0; i < order->n; i++) {
    struct str *e = order->v[i], *l;
    struct node *en = h_pv (enm, e);
    struct vec *cs = v_new (), *ids;
    long j, m2;
    if (!en) continue;
    for (j = 1; j < en->count; j++) {
      struct node *x = en->kids[j];
      struct vec *xs = is (x, "items") ? kids (x) : vec1n (x);
      for (m2 = 0; m2 < xs->n; m2++) { struct node *y = K (xs, m2); if (ends_colon (y) && s_eq (h_pv (econst, uncolon (y)), e)) v_push (cs, y); }
    }
    l = s_of ("enum "); s_app (l, cid (e)); s_cat (l, " { ");
    ids = ids1 (cid (e));
    if (!cs->n) { s_app (l, cid (e)); s_cat (l, "__none"); }
    for (j = 0; j < cs->n; j++) {
      struct node *y = K (cs, j);
      long q;
      if (j) s_cat (l, ", ");
      s_app (l, cid (uncolon (y)));
      if (y->count) { s_cat (l, " = "); for (q = 0; q < y->count; q++) s_add (l, y->kids[q]->text, y->kids[q]->len); }
    }
    for (j = 0; j < cs->n; j++) v_push (ids, cid (uncolon (K (cs, j))));
    s_cat (l, " };");
    cdeclares (l, ids);
  }
  /* the function types */
  for (i = 0; i < order->n; i++) {
    struct str *f = order->v[i], *l, *ps;
    struct node *fd = h_pv (fntype, f);
    struct vec *fl, *p;
    long j = 1, q;
    int pcs = 0, va = 0;
    struct ty *ret;
    if (!fd) continue;
    fl = kids (fd);
    if (is (K (fl, 0), "base pcs")) { pcs = 1; fl = slice (fl, 1, fl->n); }
    ret = ptype (fl, &j);
    p = v_new ();
    for (q = j; q < fl->n; q++) {
      struct node *x = K (fl, q);
      long m2 = 0;
      if (is (x, "...")) { va = 1; continue; }
      v_push (p, ctype (ptype (kids (x), &m2)));
    }
    if (va) v_push (p, s_of ("..."));
    ps = s_of ("");
    for (q = 0; q < p->n; q++) { if (q) s_cat (ps, ", "); s_app (ps, p->v[q]); }
    if (!p->n) ps = s_of ("void");
    l = s_dup (cid (f)); s_chr (l, '('); s_app (l, ps); s_chr (l, ')');
    l = cat3 ("typedef ", cdecl (ret, l), pcs ? " __attribute__((pcs(\"aapcs\")));" : ";");
    cdeclares (l, ids1 (cid (f)));
  }
  /* the records' fields, each after those it holds by value */
  for (i = 0; i < order->n; i++) if (REC (order->v[i])) emit_rec (order->v[i]);
  /* the globals */
  extern_arrays = 1;
  for (i = 0; i < order->n; i++) {
    struct str *v = order->v[i], *l;
    struct var *x = VAR (v);
    if (!x || clang_builtin (v)) continue;
    l = s_of (x->tls ? "extern __thread " : "extern "); s_app (l, cdecl (gtype (v), cid (v)));
    if (x->weak) s_cat (l, " __attribute__((weak))");
    s_chr (l, ';');
    cdeclares (l, ids1 (cid (v)));
  }
  extern_arrays = 0;
  /* the functions */
  for (i = 0; i < order->n; i++) {
    struct str *f = order->v[i], *l;
    struct fn *x = FN (f);
    if (!x || is_kind (x, "alias") || clang_builtin (f)) continue;
    l = proto (f);
    if (is_kind (x, "weak")) s_cat (l, " __attribute__((weak))");
    if (x->ctor) { s_cat (l, " __attribute__(("); s_app (l, x->ctor); s_cat (l, "))"); }
    if (x->attr) { s_cat (l, " __attribute__(("); s_cat (l, x->attr); s_cat (l, "))"); }
    s_chr (l, ';');
    cdeclares (l, ids1 (cid (f)));
  }
  for (i = 0; i < order->n; i++) {
    struct str *f = order->v[i], *l;
    struct fn *x = FN (f);
    if (!(x && is_kind (x, "alias") && !VAR (f))) continue;
    if (VAR (x->target)) { l = cat3 ("extern __typeof__(", cid (x->target), ") "); s_app (l, cid (f)); s_chr (l, ';'); }
    else l = cat3 ("", proto (f), ";");
    cdeclares (l, ids1 (cid (f)));
  }
  /* the glibc pages' globals, with their items (but those c2ff makes of a text or a compound literal) */
  gnames = v_new (); gdefline = v_new ();
  for (i = 0; i < order->n; i++) {
    struct str *v = order->v[i], *init = 0, *sec, *sf = 0, *hint;
    struct var *x = VAR (v);
    struct ty *gt;
    struct vec *its;
    int ok = 0;
    if (!(x && x->glibc && !x->weak && !mf (v, "^(?:wide )?text \\d+$| literal \\d+$", ""))) continue;
    gt = gtype (v);
    its = items_of (v);
    cur_fn = v;
    temp_begin ();
    try_ ();
    if (!its->n) init = s_of ("");
    else if (gt->k == T_ARR || gt->k == T_REC) init = cat3 (" = ", init_list (gt, its), "");
    else { struct vec *fl = v_new (); long j; for (j = 0; j < its->n; j++) { struct node *y = K (its, j); if (is (y, "items")) v_cat (fl, kids (y)); else v_push (fl, y); } init = cat3 (" = ", expr_item (fl), ""); }
    if (catch_ ()) { init = 0; e_s (F_msg); }
    if (init) { perm_begin (); init = s_dup (init); perm_end (); }
    temp_end ();
    sec = s_of ("");
    if (x->section) { s_cat (sec, " __attribute__((section(\""); s_app (sec, x->section); s_cat (sec, "\")))"); }
    if (x->align) { s_cat (sec, " __attribute__((aligned("); s_app (sec, x->align); s_cat (sec, ")))"); }
    if (init) {
      struct str *l = s_of (x->tls ? "__thread " : "");
      s_app (l, cdecl (gt, cid (v))); s_app (l, sec); s_app (l, init); s_chr (l, ';');
      push_c (l);
      ok = 1;
    }
    /* (where glibc has it: a unit's own static in that unit, a function's static in that function) */
    if (mf (v, "^(\\S+(?: \\S+/\\S+)?) \\S+(?: \\d+)?$", "")) { struct str *a1 = g (1); if (FN (a1)) sf = a1; }
    if (sf) hint = cat3 ("in ", orig (sf), "");
    else if (mf (v, "^\\S+ (\\S+/\\S+)$", "")) hint = cat3 ("unit ", g (1), "");
    else hint = s_of ("-");
    if (ok) { struct gdl *gd = alloc (sizeof (struct gdl)); gd->line = C->n - 1; gd->hint = hint; gd->sf = sf; v_push (gdefline, gd); }
    v_push (gnames, join_tab (ok ? "global" : "gfailed", cid (v), orig (v), hint));
    cur_fn = 0;
  }
  /* the bodies */
  names = v_new (); cbody = v_new (); cbodyunit = v_new (); fnunit = h_new ();
  v_cat (names, gnames);
  for (i = 0; i < order->n; i++) {
    struct str *f = order->v[i], *unit = 0, *ps, *body, *l;
    struct fn *x;
    struct sig *s;
    struct vec *blist;
    struct hash *sc;
    long j;
    if (!h_has (glibcpage, f)) continue;
    x = FN (f);
    cur_fn = f;
    s = sig (f);
    temp_begin ();
    blist = slice (kids (x->node), s->body, x->node->count);
    for (j = 0; j < blist->n && !unit; j++) { struct node *y = K (blist, j); if (is (y, "comment") && y->count && mf (c (y->kids[0]), "^(?:glibc|gcc)-\\S+ (\\S+)$", "")) unit = g (1); }
    scopes = v_new ();
    sc = h_new ();
    for (j = 0; j < s->params->n; j++) { struct param *p = s->params->v[j]; h_setp (sc, p->name, p->t); }
    v_push (scopes, sc);
    cur_last = s->params->n ? cid_local (((struct param *) s->params->v[s->params->n - 1])->name) : s_of ("");
    labels = h_new ();
    labels_in (blist, labels);
    ps = s_of ("");
    if (s->params->n || s->va) {
      for (j = 0; j < s->params->n; j++) { struct param *p = s->params->v[j]; if (j) s_cat (ps, ", "); s_app (ps, cdecl (p->t, cid_local (p->name))); }
      if (s->va) { if (s->params->n) s_cat (ps, ", "); s_cat (ps, "..."); }
    } else ps = s_of ("void");
    try_ ();
    body = block (blist);
    if (catch_ ()) {
      e_s (F_msg);
      perm_begin (); v_push (names, join_tab ("failed", cid (f), orig (f), unit ? s_dup (unit) : s_of ("-"))); perm_end ();
      temp_end (); scopes = noscopes; labels = 0; cur_last = 0;
      continue;
    }
    l = s_dup (cid (f)); s_chr (l, '('); s_app (l, ps); s_chr (l, ')');
    l = cdecl (s->ret, l); s_chr (l, ' '); s_app (l, body);
    perm_begin ();
    unit = unit ? s_dup (unit) : s_of ("-");
    v_push (cbody, s_dup (l));
    v_push (cbodyunit, unit);
    h_setp (fnunit, f, unit);
    v_push (names, join_tab ("body", cid (f), orig (f), unit));
    perm_end ();
    temp_end (); scopes = noscopes; labels = 0; cur_last = 0;
  }
  cur_fn = 0;
  /* (the names c2ff left out, found in the bodies, before them) */
  for (i = 0; i < order->n; i++) { struct str *f = order->v[i]; struct fn *x = FN (f); if (x && x->missing) cdeclares (cat3 ("long ", cid (f), "();"), ids1 (cid (f))); }
  if (split_dir) write_split (out, gdefline, cbody, cbodyunit, fnunit);
  else {
    struct str *o = s_of ("");
    long fd;
    v_cat (C, cbody);
    for (i = 0; i < C->n; i++) { if (i) s_chr (o, '\n'); s_app (o, C->v[i]); }
    s_chr (o, '\n');
    fd = fcreate (out);
    fwrite_all (fd, o);
  }
  for (i = 0; i < order->n; i++) { struct str *f = order->v[i]; if (VAR (f) || FN (f)) v_push (names, join_tab ("name", cid (f), orig (f), 0)); }
  /* (and the enum constants c2ff named with their unit: C's name for them) */
  {
    struct vec *ks = sorted_keys (econst);
    for (i = 0; i < ks->n; i++) if (mf (ks->v[i], "^\\S+ \\S+/\\S+$", "")) v_push (names, join_tab ("name", cid (ks->v[i]), orig (ks->v[i]), 0));
  }
  for (i = 0; i < order->n; i++) { struct str *f = order->v[i]; struct fn *x = FN (f); if (x && is_kind (x, "asm")) v_push (names, join_tab ("asm", cid (f), orig (f), 0)); }
  /* (a weak function, declared without its parameters: noproto) */
  for (i = 0; i < order->n; i++) { struct str *f = order->v[i]; struct fn *x = FN (f); if (x && is_kind (x, "weak")) v_push (names, join_tab ("noproto", cid (f), orig (f), 0)); }
  /* (and the aliases of asm functions, which C calls as they are) */
  for (i = 0; i < order->n; i++) {
    struct str *f = order->v[i], *n2 = f;
    struct fn *x = FN (f);
    long d;
    int at = 0;
    if (!(x && is_kind (x, "alias"))) continue;
    for (d = 0; d <= 8; d++) { struct fn *y = FN (n2); if (!y) break; if (is_kind (y, "asm")) { at = 1; break; } if (!is_kind (y, "alias")) break; n2 = y->target; }
    if (at) v_push (names, join_tab ("asm", cid (f), orig (f), 0));
  }
  {
    struct str *o = s_of ("");
    long fd;
    for (i = 0; i < names->n; i++) { s_app (o, names->v[i]); s_chr (o, '\n'); }
    fd = fcreate (namesout);
    fwrite_all (fd, o);
  }
  o_flush ();
  return 0;
}

/* --split: a file per unit, its name from its .i's path under i/ (or ff/) */
static struct str *split_name (struct str *u)
{
  struct str *s = ssub (u, "\\.i$", "", "");
  s = ssub (s, "^.*/(?:i|ff)/", "", "");
  s = ssub (s, "^/+", "", "");
  return ssub (s, "/", "g", "_");
}
static void want_ids (struct str *s, struct vec *todo, struct hash *seen)
{
  long i = 0;
  while (i < s->n) {
    if ((s->p[i] >= 'A' && s->p[i] <= 'Z') || (s->p[i] >= 'a' && s->p[i] <= 'z') || s->p[i] == '_') {
      long j = i;
      struct str *id;
      while (j < s->n && is_word (s->p[j])) j++;
      id = s_sub (s, i, j);
      if (!h_has (seen, id)) { h_set (seen, id, 1); v_push (todo, id); }
      i = j;
    } else i++;
  }
}
struct own { struct vec *defs, *bodies; };
static void write_split (char *out, struct vec *gdefline, struct vec *cbody, struct vec *cbodyunit, struct hash *fnunit)
{
  struct hash *own = h_new (), *whose = h_new ();
  struct vec *ks;
  struct str *list = s_of ("");
  long i, k = 1, n = 0, size = 0, fd;
  for (i = 0; i < C->n; i++) {
    struct vec *ids = Cdecl->v[i];
    long j;
    if (!ids) continue;
    for (j = 0; j < ids->n; j++) { struct vec *w = h_pv (whose, ids->v[j]); if (!w) { w = v_new (); h_setp (whose, ids->v[j], w); } v_push (w, (void *) (i + 1)); }
  }
  /* the globals: in their unit's file, a function's static in its function's; the others a hundred to a file, or a megabyte */
  for (i = 0; i < gdefline->n; i++) {
    struct gdl *gd = gdefline->v[i];
    struct str *name;
    struct own *o;
    if (mf (gd->hint, "^unit (.+)$", "")) name = split_name (g (1));
    else if (gd->sf && h_pv (fnunit, gd->sf) && !s_is (h_pv (fnunit, gd->sf), "-")) name = split_name (h_pv (fnunit, gd->sf));
    else {
      if (n >= 100 || (size + ((struct str *) C->v[gd->line])->n > 1000000 && n)) { k++; n = 0; size = 0; }
      n++; size += ((struct str *) C->v[gd->line])->n;
      name = cat3 ("g-", s_num (k), "");
    }
    o = h_pv (own, name);
    if (!o) { o = alloc (sizeof (struct own)); o->defs = v_new (); o->bodies = v_new (); h_setp (own, name, o); }
    v_push (o->defs, (void *) (gd->line + 1));
  }
  for (i = 0; i < cbody->n; i++) {
    struct str *u = cbodyunit->v[i], *name = s_is (u, "-") ? s_of ("nounit") : split_name (u);
    struct own *o = h_pv (own, name);
    if (!o) { o = alloc (sizeof (struct own)); o->defs = v_new (); o->bodies = v_new (); h_setp (own, name, o); }
    v_push (o->bodies, (void *) (i + 1));
  }
  f2_mkdir (split_dir);
  ks = sorted_keys (own);
  for (i = 0; i < ks->n; i++) {
    struct own *o = h_pv (own, ks->v[i]);
    struct hash *seen = h_new ();
    struct vec *todo = v_new ();
    char *line = alloc (C->n + 1);
    struct str *path = s_of (split_dir), *txt = s_of ("");
    long j, at = 0, ffd;
    for (j = 0; j < o->defs->n; j++) want_ids (C->v[(long) o->defs->v[j] - 1], todo, seen);
    for (j = 0; j < o->bodies->n; j++) want_ids (cbody->v[(long) o->bodies->v[j] - 1], todo, seen);
    while (at < todo->n) {
      struct vec *w = h_pv (whose, todo->v[at++]);
      long q;
      if (!w) continue;
      for (q = 0; q < w->n; q++) { long x = (long) w->v[q] - 1; if (line[x]) continue; line[x] = 1; want_ids (C->v[x], todo, seen); }
    }
    for (j = 0; j < o->defs->n; j++) line[(long) o->defs->v[j] - 1] = 1;
    s_chr (path, '/'); s_app (path, ks->v[i]); s_cat (path, ".c");
    for (j = 0; j < C->n; j++) if (line[j]) { s_app (txt, C->v[j]); s_chr (txt, '\n'); }
    for (j = 0; j < o->bodies->n; j++) { s_app (txt, cbody->v[(long) o->bodies->v[j] - 1]); s_chr (txt, '\n'); }
    ffd = fcreate ((char *) path->p);
    fwrite_all (ffd, txt);
    s_app (list, path); s_chr (list, '\n');
  }
  fd = fcreate (out);
  fwrite_all (fd, list);
}
