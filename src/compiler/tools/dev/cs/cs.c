/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cs.c: dev source of tools/csem.ff, the types and semantics of C (T3b)
   on cparse's tree: every declaration's and expression's type, the integer
   promotions and the usual arithmetic conversions, decay, lvalues, the
   implicit casts made explicit (as clang's kinds), sizeof and alignof,
   struct and union layout as the target's ABI lays them out, integer
   constant expressions folded. Its output: the lines csema -d writes
   (gen/clangsema.pl writes clang's), or the annotated tree. */
#include "c.h"
#include "cs.h"

enum {
  TY_VOID, TY_BOOL, TY_CHAR, TY_SCHAR, TY_UCHAR, TY_SHORT, TY_USHORT, TY_INT, TY_UINT, TY_LONG, TY_ULONG,
  TY_LLONG, TY_ULLONG, TY_INT128, TY_UINT128, TY_FLOAT16, TY_BF16, TY_HALF, TY_FLOAT, TY_DOUBLE, TY_LDOUBLE,
  TY_FLOAT128, TY_IBM128, TY_COMPLEX, TY_PTR, TY_ARRAY, TY_FUNC, TY_STRUCT, TY_UNION, TY_ENUM, TY_VECTOR,
  TY_ATOMIC, TY_BITINT, TY_UBITINT, TY_BUILTINFN, TY_SVE, TY_TYPEDEF, TY_TYPEOF, TY_N
};
enum { Q_CONST = 1, Q_VOLATILE = 2, Q_RESTRICT = 4, Q_FS = 8, Q_GS = 16 };
enum { DK_VAR, DK_FUNC, DK_TYPEDEF, DK_ENUMC, DK_PARAM };
enum { SC_NONE, SC_EXTERN, SC_STATIC, SC_AUTO, SC_REGISTER };
enum {
  E_ICE, E_CAST, E_REF, E_INT, E_CHR, E_FLT, E_STR, E_UN, E_BIN, E_CASS, E_COND, E_BCOND, E_OVE, E_CALL,
  E_MEM, E_IDX, E_SIZEOF, E_CONST, E_INIT, E_IVI, E_CLIT, E_STMTX, E_OFFSETOF, E_VAARG, E_PREDEF, E_ADDRLABEL,
  E_ATOMIC, E_TRAIT, E_OTHER, E_PAREN, E_GENERIC
};
enum {
  CK_LVALUETORVALUE, CK_INTEGRALCAST, CK_FUNCTIONTOPOINTERDECAY, CK_ARRAYTOPOINTERDECAY, CK_NOOP, CK_BITCAST,
  CK_INTEGRALTOBOOLEAN, CK_NULLTOPOINTER, CK_BUILTINFNTOFNPTR, CK_POINTERTOINTEGRAL, CK_INTEGRALTOPOINTER, CK_TOVOID,
  CK_INTEGRALTOFLOATING, CK_FLOATINGTOINTEGRAL, CK_FLOATINGCAST, CK_FLOATINGTOBOOLEAN, CK_POINTERTOBOOLEAN, CK_TOUNION,
  CK_VECTORSPLAT, CK_INTEGRALREALTOCOMPLEX, CK_FLOATINGREALTOCOMPLEX, CK_FLOATINGCOMPLEXCAST, CK_INTEGRALCOMPLEXCAST,
  CK_FLOATINGCOMPLEXTOREAL, CK_INTEGRALCOMPLEXTOREAL, CK_FLOATINGCOMPLEXTOBOOLEAN, CK_INTEGRALCOMPLEXTOBOOLEAN,
  CK_FLOATINGCOMPLEXTOINTEGRALCOMPLEX, CK_INTEGRALCOMPLEXTOFLOATINGCOMPLEX, CK_NONATOMICTOATOMIC, CK_ATOMICTONONATOMIC,
  CK_LVALUEBITCAST, CK_ADDRESSSPACECONVERSION, CK_N
};
/* the builtins' argument rules */
enum { BA_NORMAL, BA_NONE, BA_RVALUE, BA_PROMOTE, BA_UAC, BA_FPCLASS };

struct cs_bind { unsigned char *p; long n; int ns; int level; void *v; struct cs_bind *nxt; };
struct cs_mark { long off; long line; unsigned char *f; long fl; };
struct cs_pdecl { unsigned char *name; long nlen; struct cs_ty *t; };
struct cs_dinfo { unsigned char *name; long nlen; struct cs_pdecl *ps; long np; int fn; int kr; struct node *where; };
struct cs_spec {
  struct cs_ty *t; int sc; int istypedef; int inl; int noret; long long algn; int mode; int modebits;
  long long vec; int packed; int transparent; int thr; int defined_rec; int autotype;
  /* (T3c) the attributes the C layer takes */
  long long alnmax; int hasaln; int weak, ctor, err, pcs; long long ctorprio;
  char *aliasee, *ifunc, *section, *cleanup, *asmlabel;
};

struct cs_lab { unsigned char *p; long n; long k; struct cs_lab *up; };   /* a __label__ in scope; or (labcount) how many of a name so far */
struct cs_cst {
  struct cs_lab *labels, *labcount;
  int target;
  int char_signed, lbytes, pbytes, ldbl, llalign, dalign, wchar_k, size_k, ptrdiff_k;
  long long maxalign;
  struct cs_ty *basic[TY_N];
  struct cs_ty *vptr, *cvptr, *va, *sizet, *ptrdifft, *intt;
  struct cs_buf out;
  struct cs_bind **tab;
  struct cs_bind **undo; long nundo, roomundo; int level;
  unsigned char *src; long srcn, skip;
  struct cs_mark *mk; long nmk;
  int dump;
  struct cs_decl *fn; struct cs_ty *fnret; struct node *fnnode;
  struct cs_ty *swcond[64]; int nsw;
  struct cs_buf tmp, lay;
  long errors;
  int exdepth, builtins, alone, inenum, tree, depth, tdepth, incount;
  struct cs_rec **recs; long nrecs, roomrecs;
  char *fname;
  /* (T3c) what the C layer reads */
  int keep, nodump;
  struct cs_top *top1, *toplast;
  struct cs_top *ext1, *extlast;      /* extern declarations in blocks: after the unit's own */
  struct cs_rec *allrec1, *allreclast;
  struct cs_rec *currec;
  struct cs_dl *dl1, *dllast;
  struct cs_bind *weakpending;
  void *cl;
  struct node *cur_specs;
};
static struct cs_cst *T;
/* one of two texts (a conditional of texts is not one ttpc takes) */
static char *cs_pick (int c, char *a, char *b) { if (c) return a; return b; }

static char *ckname[] = {
  "LValueToRValue", "IntegralCast", "FunctionToPointerDecay", "ArrayToPointerDecay", "NoOp", "BitCast",
  "IntegralToBoolean", "NullToPointer", "BuiltinFnToFnPtr", "PointerToIntegral", "IntegralToPointer", "ToVoid",
  "IntegralToFloating", "FloatingToIntegral", "FloatingCast", "FloatingToBoolean", "PointerToBoolean", "ToUnion",
  "VectorSplat", "IntegralRealToComplex", "FloatingRealToComplex", "FloatingComplexCast", "IntegralComplexCast",
  "FloatingComplexToReal", "IntegralComplexToReal", "FloatingComplexToBoolean", "IntegralComplexToBoolean",
  "FloatingComplexToIntegralComplex", "IntegralComplexToFloatingComplex", "NonAtomicToAtomic", "AtomicToNonAtomic",
  "LValueBitCast", "AddressSpaceConversion"
};
static char *tyname[] = {
  "void", "_Bool", "char", "signed char", "unsigned char", "short", "unsigned short", "int", "unsigned int", "long",
  "unsigned long", "long long", "unsigned long long", "__int128", "unsigned __int128", "_Float16", "__bf16", "__fp16",
  "float", "double", "long double", "__float128", "__ibm128"
};

/* ---- buffers ---- */
static void cs_b_room (struct cs_buf *b, long more)
{
  if (b->n + more > b->room) {
    long m = b->room * 2 + more + 256, i = 0;
    unsigned char *p = alloc (m);
    while (i < b->n) { p[i] = b->p[i]; i++; }
    b->p = p;
    b->room = m;
  }
}
static void cs_b_bytes (struct cs_buf *b, unsigned char *p, long n)
{
  long i = 0;
  cs_b_room (b, n);
  while (i < n) { b->p[b->n + i] = p[i]; i++; }
  b->n += n;
}
static void cs_b_str (struct cs_buf *b, char *s) { cs_b_bytes (b, (unsigned char *) s, cstrlen (s)); }
static void cs_b_byte (struct cs_buf *b, int c) { unsigned char x[1]; x[0] = c; cs_b_bytes (b, x, 1); }
static void cs_b_ull (struct cs_buf *b, unsigned long long v)
{
  unsigned char t[24];
  long n = 0;
  if (v == 0) t[n++] = '0';
  while (v != 0) { t[n++] = '0' + (int) (v % 10); v = v / 10; }
  while (n > 0) { n--; cs_b_byte (b, t[n]); }
}
static void cs_b_ll (struct cs_buf *b, long long v)
{
  if (v < 0) { cs_b_byte (b, '-'); cs_b_ull (b, (unsigned long long) 0 - (unsigned long long) v); }
  else cs_b_ull (b, (unsigned long long) v);
}
static void cs_b_init (struct cs_buf *b) { b->p = 0; b->n = 0; b->room = 0; }
static void cs_b_buf (struct cs_buf *b, struct cs_buf *c) { cs_b_bytes (b, c->p, c->n); }
static int cs_eqb (unsigned char *a, long an, unsigned char *b, long bn)
{
  long i = 0;
  if (an != bn) return 0;
  while (i < an) { if (a[i] != b[i]) return 0; i++; }
  return 1;
}
static int cs_is (struct node *n, char *s) { return n && same (n->text, n->len, s); }
static void cs_fail (char *what, struct node *n)
{
  err_str ("csema: ");
  err_str (what);
  if (n) { err_str (": "); err_bytes (n->text, n->len); }
  err_str ("\n");
  cp_exit (1);
}

/* ---- names in scopes ---- */
static long cs_hash (unsigned char *p, long n)
{
  long h = 5381, i = 0;
  while (i < n) { h = (h * 33 + p[i]) & 0xffff; i++; }
  return h;
}
static void cs_bind (unsigned char *p, long n, int ns, void *v)
{
  struct cs_bind *b = alloc (sizeof (struct cs_bind));
  long h = cs_hash (p, n);
  b->p = p; b->n = n; b->ns = ns; b->v = v; b->level = T->level;
  b->nxt = T->tab[h];
  T->tab[h] = b;
  if (T->nundo == T->roomundo) {
    long m = T->roomundo * 2 + 256, i = 0;
    struct cs_bind **u = alloc (m * sizeof (struct cs_bind *));
    while (i < T->nundo) { u[i] = T->undo[i]; i++; }
    T->undo = u;
    T->roomundo = m;
  }
  T->undo[T->nundo++] = b;
}
static struct cs_bind *cs_lookup_b (unsigned char *p, long n, int ns)
{
  struct cs_bind *b = T->tab[cs_hash (p, n)];
  while (b) { if (b->ns == ns && cs_eqb (b->p, b->n, p, n)) return b; b = b->nxt; }
  return 0;
}
static void *cs_lookup (unsigned char *p, long n, int ns) { struct cs_bind *b = cs_lookup_b (p, n, ns); return b ? b->v : 0; }
static long cs_scope_in (void) { T->level++; return T->nundo; }
/* GNU's __label__: a label of its block, numbered among the function's of its name (a label in ff is the function's) */
static int cs_lab_is (struct cs_lab *l, unsigned char *p, long n)
{
  long i = 0;
  if (l->n != n) return 0;
  while (i < n) { if (l->p[i] != p[i]) return 0; i++; }
  return 1;
}
static void cs_label_decl (unsigned char *p, long n)
{
  struct cs_lab *c = T->labcount, *l = alloc (sizeof (struct cs_lab));
  while (c && !cs_lab_is (c, p, n)) c = c->up;
  if (!c) { c = alloc (sizeof (struct cs_lab)); c->p = p; c->n = n; c->up = T->labcount; T->labcount = c; }
  c->k++;
  l->p = p; l->n = n; l->k = c->k; l->up = T->labels;
  T->labels = l;
}
/* its number where one is in scope, or 0 */
static long cs_label_k (unsigned char *p, long n)
{
  struct cs_lab *l = T->labels;
  while (l && !cs_lab_is (l, p, n)) l = l->up;
  return l ? l->k : 0;
}
static void cs_scope_out (long mark)
{
  while (T->nundo > mark) {
    struct cs_bind *b = T->undo[--T->nundo];
    long h = cs_hash (b->p, b->n);
    T->tab[h] = b->nxt;
  }
  T->level--;
}

/* ---- types ---- */
static struct cs_ty *cs_ty_new (int k) { struct cs_ty *t = alloc (sizeof (struct cs_ty)); t->k = k; return t; }
static struct cs_ty *cs_ty_copy (struct cs_ty *t)
{
  struct cs_ty *c = alloc (sizeof (struct cs_ty));
  c->k = t->k; c->q = t->q; c->to = t->to; c->n = t->n; c->rec = t->rec; c->ps = t->ps; c->np = t->np;
  c->var = t->var; c->proto = t->proto; c->noret = t->noret; c->name = t->name; c->nlen = t->nlen; c->algn = t->algn; c->pq = t->pq; c->count = t->count; c->countx = t->countx;
  return c;
}
static int cs_sugar (struct cs_ty *t) { return t->k == TY_TYPEDEF || t->k == TY_TYPEOF; }
static struct cs_ty *cs_qual (struct cs_ty *t, int q);
static struct cs_ty *cs_canon (struct cs_ty *t)
{
  int q = 0;
  while (cs_sugar (t)) { q |= t->q; t = t->to; }
  return q ? cs_qual (t, q) : t;
}
static struct cs_ty *cs_qual (struct cs_ty *t, int q)
{
  struct cs_ty *c;
  if (!q) return t;
  if (t->k == TY_FUNC) return t;
  if (t->k == TY_ARRAY) { c = cs_ty_copy (t); c->to = cs_qual (t->to, q); return c; }
  if (cs_sugar (t) && cs_canon (t)->k == TY_ARRAY) return cs_qual (cs_canon (t), q);
  if ((t->q | q) == t->q) return t;
  c = cs_ty_copy (t);
  c->q |= q;
  return c;
}
/* the qualifiers, through sugar; an array's are its element's */
static int cs_quals (struct cs_ty *t)
{
  int q = 0;
  for (;;) {
    q |= t->q;
    if (cs_sugar (t) || t->k == TY_ARRAY) t = t->to; else return q;
  }
}
static struct cs_ty *cs_unqual (struct cs_ty *t)
{
  struct cs_ty *c;
  if (t->k == TY_ARRAY) return t;
  if (!cs_quals (t)) return t;
  if (cs_sugar (t) && cs_quals (t->to)) t = cs_canon (t);
  if (t->k == TY_ARRAY) return t;
  c = cs_ty_copy (t);
  c->q = 0;
  return c;
}
static struct cs_ty *cs_basic (int k) { return T->basic[k]; }
static struct cs_ty *cs_ptr_to (struct cs_ty *t) { struct cs_ty *p = cs_ty_new (TY_PTR); p->to = t; return p; }
static struct cs_ty *cs_array_of (struct cs_ty *t, long long n) { struct cs_ty *a = cs_ty_new (TY_ARRAY); a->to = t; a->n = n; return a; }
static int cs_kind (struct cs_ty *t) { return cs_canon (t)->k; }
static int cs_k_int (int k) { return (k >= TY_BOOL && k <= TY_UINT128) || k == TY_ENUM || k == TY_BITINT || k == TY_UBITINT; }
static int cs_is_int (struct cs_ty *t) { return cs_k_int (cs_kind (t)); }
static int cs_is_flt (struct cs_ty *t) { int k = cs_kind (t); return k >= TY_FLOAT16 && k <= TY_IBM128; }
static int cs_is_complex (struct cs_ty *t) { return cs_kind (t) == TY_COMPLEX; }
static int cs_is_arith (struct cs_ty *t) { return cs_is_int (t) || cs_is_flt (t) || cs_is_complex (t); }
static int cs_is_ptr (struct cs_ty *t) { return cs_kind (t) == TY_PTR; }
static int cs_is_scalar (struct cs_ty *t) { return cs_is_arith (t) || cs_is_ptr (t); }
static int cs_is_rec (struct cs_ty *t) { int k = cs_kind (t); return k == TY_STRUCT || k == TY_UNION; }
static int cs_is_void (struct cs_ty *t) { return cs_kind (t) == TY_VOID; }
static struct cs_ty *cs_enum_int (struct cs_ty *t)
{
  t = cs_canon (t);
  if (t->k == TY_ENUM) return t->rec->intty ? t->rec->intty : cs_basic (TY_UINT);
  return t;
}
static int cs_is_signed (struct cs_ty *t)
{
  int k = cs_canon (cs_enum_int (t))->k;
  if (k == TY_CHAR) return T->char_signed;
  return k == TY_SCHAR || k == TY_SHORT || k == TY_INT || k == TY_LONG || k == TY_LLONG || k == TY_INT128 || k == TY_BITINT;
}
static int cs_rank (struct cs_ty *t)
{
  int k = cs_canon (cs_enum_int (t))->k;
  if (k == TY_BOOL) return 1;
  if (k <= TY_UCHAR) return 2;
  if (k <= TY_USHORT) return 3;
  if (k <= TY_UINT) return 4;
  if (k <= TY_ULONG) return 5;
  if (k <= TY_ULLONG) return 6;
  return 7;
}
static struct cs_ty *cs_to_unsigned (struct cs_ty *t)
{
  int k = cs_canon (cs_enum_int (t))->k;
  if (k == TY_CHAR || k == TY_SCHAR) return cs_basic (TY_UCHAR);
  if (k == TY_SHORT || k == TY_INT || k == TY_LONG || k == TY_LLONG || k == TY_INT128) return cs_basic (k + 1);
  return cs_canon (cs_enum_int (t));
}
static long long cs_ty_size (struct cs_ty *t);
static long long cs_ty_align (struct cs_ty *t);
static long long cs_int_bits (struct cs_ty *t) { if (cs_kind (t) == TY_BOOL) return 1; return cs_ty_size (cs_enum_int (t)) * 8; }

/* the same type, canonically (qualifiers too) */
static int cs_same_ty (struct cs_ty *a, struct cs_ty *b);
static int cs_same_params (struct cs_ty *a, struct cs_ty *b)
{
  long i = 0;
  if (a->np != b->np || a->var != b->var || a->proto != b->proto || a->noret != b->noret) return 0;
  while (i < a->np) { if (!cs_same_ty (cs_unqual (a->ps[i]), cs_unqual (b->ps[i]))) return 0; i++; }
  return 1;
}
static int cs_same_ty (struct cs_ty *a, struct cs_ty *b)
{
  a = cs_canon (a);
  b = cs_canon (b);
  if (a == b) return 1;
  if (a->k != b->k || a->q != b->q) return 0;
  if (a->k == TY_PTR || a->k == TY_COMPLEX || a->k == TY_ATOMIC) return cs_same_ty (a->to, b->to);
  if (a->k == TY_ARRAY) return a->n == b->n && cs_same_ty (a->to, b->to);
  if (a->k == TY_VECTOR) return a->n == b->n && cs_same_ty (a->to, b->to);
  if (a->k == TY_FUNC) return cs_same_ty (cs_unqual (a->to), cs_unqual (b->to)) && cs_same_params (a, b);
  if (a->k == TY_STRUCT || a->k == TY_UNION || a->k == TY_ENUM) return a->rec == b->rec;
  if (a->k == TY_BITINT || a->k == TY_UBITINT) return a->n == b->n;
  return 1;
}
/* compatible types (C's 6.2.7), for merging and pointer checks */
static int cs_compatible (struct cs_ty *a, struct cs_ty *b)
{
  a = cs_canon (a);
  b = cs_canon (b);
  if (a == b) return 1;
  if (a->q != b->q) return 0;
  if (a->k == TY_ENUM && cs_k_int (b->k) && b->k != TY_ENUM) return cs_same_ty (cs_enum_int (a), b);
  if (b->k == TY_ENUM && cs_k_int (a->k) && a->k != TY_ENUM) return cs_same_ty (cs_enum_int (b), a);
  if (a->k != b->k) return 0;
  if (a->k == TY_PTR || a->k == TY_COMPLEX || a->k == TY_ATOMIC) return cs_compatible (a->to, b->to);
  if (a->k == TY_ARRAY) return (a->n < 0 || b->n < 0 || a->n == b->n) && cs_compatible (a->to, b->to);
  if (a->k == TY_FUNC) {
    long i = 0;
    if (!cs_compatible (cs_unqual (a->to), cs_unqual (b->to))) return 0;
    if (!a->proto || !b->proto) return 1;
    if (a->np != b->np || a->var != b->var) return 0;
    while (i < a->np) { if (!cs_compatible (cs_unqual (a->ps[i]), cs_unqual (b->ps[i]))) return 0; i++; }
    return 1;
  }
  return cs_same_ty (a, b);
}
/* the composite of two compatible types (clang's mergeTypes) */
static struct cs_ty *cs_composite (struct cs_ty *a, struct cs_ty *b)
{
  struct cs_ty *ca = cs_canon (a), *cb = cs_canon (b), *r;
  if (ca->k == TY_ARRAY && cb->k == TY_ARRAY) {
    if (ca->n < 0 && cb->n >= 0) return b;
    if (cb->n < 0 && ca->n >= 0) return a;
    return a;
  }
  if (ca->k == TY_FUNC && cb->k == TY_FUNC) {
    if (!ca->proto && cb->proto) { r = cs_ty_copy (cb); r->to = ca->to; r->noret = ca->noret || cb->noret; return r; }
    if (ca->noret != cb->noret && (ca->noret || cb->noret)) { r = cs_ty_copy (a == ca ? ca : ca); r->noret = 1; return r; }
    return a;
  }
  if (ca->k == TY_PTR && cb->k == TY_PTR) {
    struct cs_ty *m = cs_composite (ca->to, cb->to);
    if (m == ca->to) return a;
    r = cs_ty_copy (ca);
    r->to = m;
    return r;
  }
  return a;
}

/* ---- the target ---- */
static void cs_target_init (int t)
{
  long i = 0;
  T->target = t;
  while (i < TY_N) { T->basic[i] = cs_ty_new (i); i++; }
  T->char_signed = t == 1;
  T->lbytes = t == 3 ? 4 : 8;
  T->pbytes = T->lbytes;
  T->ldbl = t == 1 ? 1 : t == 3 ? 2 : 0;
  T->llalign = 8;
  T->dalign = 8;
  T->wchar_k = t == 2 || t == 3 ? TY_UINT : TY_INT;
  T->size_k = t == 3 ? TY_UINT : TY_ULONG;
  T->ptrdiff_k = t == 3 ? TY_INT : TY_LONG;
  T->maxalign = t == 3 ? 8 : 16;
  T->vptr = cs_ptr_to (cs_basic (TY_VOID));
  T->cvptr = cs_ptr_to (cs_qual (cs_basic (TY_VOID), Q_CONST));
  T->sizet = cs_basic (T->size_k);
  T->ptrdifft = cs_basic (T->ptrdiff_k);
  T->intt = cs_basic (TY_INT);
}
static long long cs_basic_size (int k)
{
  if (k == TY_VOID || k == TY_BOOL || k <= TY_UCHAR) return 1;
  if (k <= TY_USHORT) return 2;
  if (k <= TY_UINT) return 4;
  if (k <= TY_ULONG) return T->lbytes;
  if (k <= TY_ULLONG) return 8;
  if (k <= TY_UINT128) return 16;
  if (k <= TY_HALF) return 2;
  if (k == TY_FLOAT) return 4;
  if (k == TY_DOUBLE) return 8;
  if (k == TY_LDOUBLE) return T->ldbl == 2 ? 8 : 16;
  return 16;
}
static long long cs_basic_align (int k)
{
  if (k == TY_LLONG || k == TY_ULLONG) return T->llalign;
  if (k == TY_DOUBLE) return T->dalign;
  return cs_basic_size (k);
}
static void cs_layout (struct cs_rec *r);
static long long cs_ty_size (struct cs_ty *t)
{
  t = cs_canon (t);
  if (t->k < TY_COMPLEX) return cs_basic_size (t->k);
  if (t->k == TY_COMPLEX) return 2 * cs_ty_size (t->to);
  if (t->k == TY_PTR) return T->pbytes;
  if (t->k == TY_ARRAY) return t->n < 0 ? 0 : t->n * cs_ty_size (t->to);
  if (t->k == TY_FUNC) return 1;
  if (t->k == TY_STRUCT || t->k == TY_UNION) { cs_layout (t->rec); return t->rec->bytes; }
  if (t->k == TY_ENUM) return cs_ty_size (cs_enum_int (t));
  if (t->k == TY_VECTOR) return t->n;
  if (t->k == TY_ATOMIC) {
    long long s = cs_ty_size (t->to), p = 1;
    while (p < s) p *= 2;
    return p <= 16 ? p : s;
  }
  if (t->k == TY_BITINT || t->k == TY_UBITINT) { long long b = (t->n + 7) / 8, p = 1; while (p < b && p < 8) p *= 2; return p >= 8 ? (b + 7) / 8 * 8 : p; }
  return 1;
}
static long long cs_ty_align (struct cs_ty *t)
{
  while (cs_sugar (t)) { if (t->k == TY_TYPEDEF && t->algn) return t->algn; t = t->to; }
  if (t->k < TY_COMPLEX) return cs_basic_align (t->k);
  if (t->k == TY_COMPLEX) return cs_ty_align (t->to);
  if (t->k == TY_PTR) return T->pbytes;
  if (t->k == TY_ARRAY) return cs_ty_align (t->to);
  if (t->k == TY_FUNC) return 1;
  if (t->k == TY_STRUCT || t->k == TY_UNION) { cs_layout (t->rec); return t->rec->isal; }
  if (t->k == TY_ENUM) return cs_ty_align (cs_enum_int (t));
  if (t->k == TY_VECTOR) { long long a = 1; while (a < t->n) a *= 2; return a > 16 ? 16 : a; }
  if (t->k == TY_ATOMIC) { long long s = cs_ty_size (t); return s <= 16 && s > cs_ty_align (t->to) ? s : cs_ty_align (t->to); }
  if (t->k == TY_BITINT || t->k == TY_UBITINT) { long long s = cs_ty_size (t); return s > 8 ? 8 : s; }
  return 1;
}

/* ---- places: an anonymous record's (FILE:LINE:COL of its keyword, as the line markers give it) ---- */
static void cs_markers (void)
{
  unsigned char *s = T->src;
  long i = T->skip, n = T->srcn, room = 1024;
  T->mk = alloc (room * sizeof (struct cs_mark));
  while (i < n) {
    if (s[i] == '#' && (i == 0 || s[i - 1] == '\n')) {
      long j = i + 1, line = 0, f, e;
      while (j < n && s[j] == ' ') j++;
      if (j < n && s[j] >= '0' && s[j] <= '9') {
        while (j < n && s[j] >= '0' && s[j] <= '9') { line = line * 10 + (s[j] - '0'); j++; }
        while (j < n && s[j] == ' ') j++;
        if (j < n && s[j] == '"') {
          f = j + 1;
          e = f;
          while (e < n && s[e] != '"') { if (s[e] == '\\') e++; e++; }
          while (j < n && s[j] != '\n') j++;
          if (T->nmk == room) {
            struct cs_mark *m = alloc (room * 2 * sizeof (struct cs_mark));
            long k = 0;
            while (k < T->nmk) { m[k] = T->mk[k]; k++; }
            T->mk = m;
            room *= 2;
          }
          T->mk[T->nmk].off = j + 1;
          T->mk[T->nmk].line = line;
          T->mk[T->nmk].f = s + f;
          T->mk[T->nmk].fl = e - f;
          T->nmk++;
          i = j;
          continue;
        }
      }
    }
    i++;
  }
}
static void cs_place (struct cs_buf *b, unsigned char *p)
{
  long off = p - T->src, lo = 0, hi = T->nmk - 1, m = -1, i, line, ls;
  while (lo <= hi) { long mid = (lo + hi) / 2; if (T->mk[mid].off <= off) { m = mid; lo = mid + 1; } else hi = mid - 1; }
  if (m < 0) { line = 1; i = T->skip; } else { line = T->mk[m].line; i = T->mk[m].off; }
  ls = i;
  while (i < off) { if (T->src[i] == '\n') { line++; ls = i + 1; } i++; }
  if (m < 0) cs_b_str (b, T->fname); else cs_b_bytes (b, T->mk[m].f, T->mk[m].fl);
  cs_b_byte (b, ':');
  cs_b_ll (b, line);
  cs_b_byte (b, ':');
  cs_b_ll (b, off - ls + 1);
}

/* ---- printing types: canonical as clang spells them (sugar 1: typedef names kept) ---- */
static void cs_p_quals (struct cs_buf *b, int q)
{
  int any = 0;
  if (q & Q_CONST) { cs_b_str (b, "const"); any = 1; }
  if (q & Q_VOLATILE) { if (any) cs_b_byte (b, ' '); cs_b_str (b, "volatile"); any = 1; }
  if (q & Q_RESTRICT) { if (any) cs_b_byte (b, ' '); cs_b_str (b, "restrict"); any = 1; }
  /* (x86_64's __seg_fs and __seg_gs, clang's address spaces) */
  if (q & Q_FS) { if (any) cs_b_byte (b, ' '); cs_b_str (b, "__attribute__((address_space(257)))"); any = 1; }
  if (q & Q_GS) { if (any) cs_b_byte (b, ' '); cs_b_str (b, "__attribute__((address_space(256)))"); }
}
static void cs_p_rec (struct cs_buf *b, struct cs_rec *r)
{
  cs_b_str (b, cs_pick (r->k == TY_STRUCT, "struct ", cs_pick (r->k == TY_UNION, "union ", "enum ")));
  if (r->tag) cs_b_bytes (b, r->tag, r->tlen);
  else if (r->td) cs_b_bytes (b, r->td, r->tdlen);
  else cs_b_bytes (b, r->loc, r->llen);
}
static void cs_p_type (struct cs_buf *o, struct cs_ty *t, struct cs_buf *in, int sug);
static void cs_p_ty (struct cs_buf *o, struct cs_ty *t, int sug) { struct cs_buf in; cs_b_init (&in); cs_p_type (o, t, &in, sug); }
static void cs_p_params (struct cs_buf *b, struct cs_ty *t, int sug)
{
  long i = 0;
  cs_b_byte (b, '(');
  if (t->proto) {
    while (i < t->np) {
      if (i) cs_b_str (b, ", ");
      cs_p_ty (b, sug ? t->ps[i] : cs_unqual (cs_canon (t->ps[i])), sug);
      i++;
    }
    if (t->var) cs_b_str (b, cs_pick (i, ", ...", ""));
    else if (t->np == 0) cs_b_str (b, "void");
  }
  cs_b_byte (b, ')');
}
static void cs_p_type (struct cs_buf *o, struct cs_ty *t, struct cs_buf *in, int sug)
{
  struct cs_buf n;
  cs_b_init (&n);
  if (!sug || t->k == TY_TYPEOF) t = cs_canon (t);
  if (t->k == TY_PTR) {
    struct cs_ty *p = sug ? t->to : cs_canon (t->to);
    int paren = p->k == TY_ARRAY || p->k == TY_FUNC;
    if (paren) cs_b_byte (&n, '(');
    cs_b_byte (&n, '*');
    if (t->q & (Q_FS | Q_GS) && !(t->q & 7)) cs_b_byte (&n, ' ');
    cs_p_quals (&n, t->q);
    if (t->q && in->n) cs_b_byte (&n, ' ');
    cs_b_buf (&n, in);
    if (paren) cs_b_byte (&n, ')');
    cs_p_type (o, t->to, &n, sug);
    return;
  }
  if (t->k == TY_ARRAY) {
    cs_b_buf (&n, in);
    cs_b_byte (&n, '[');
    if (t->n >= 0) cs_b_ll (&n, t->n); else if (t->n == -2) cs_b_byte (&n, '*');
    cs_b_byte (&n, ']');
    cs_p_type (o, t->to, &n, sug);
    return;
  }
  if (t->k == TY_FUNC) {
    cs_b_buf (&n, in);
    cs_p_params (&n, t, sug);
    if (t->noret) cs_b_str (&n, " __attribute__((noreturn))");
    cs_p_type (o, sug ? t->to : cs_unqual (cs_canon (t->to)), &n, sug);
    return;
  }
  if (t->q) { cs_p_quals (&n, t->q); cs_b_byte (&n, ' '); }
  if (t->k == TY_TYPEDEF) cs_b_bytes (&n, t->name, t->nlen);
  else if (t->k < TY_COMPLEX) cs_b_str (&n, tyname[t->k]);
  else if (t->k == TY_STRUCT || t->k == TY_UNION || t->k == TY_ENUM) cs_p_rec (&n, t->rec);
  else if (t->k == TY_COMPLEX) { cs_b_str (&n, "_Complex "); cs_p_ty (&n, t->to, sug); }
  else if (t->k == TY_ATOMIC) { cs_b_str (&n, "_Atomic("); cs_p_ty (&n, t->to, sug); cs_b_byte (&n, ')'); }
  else if (t->k == TY_VECTOR) {
    cs_b_str (&n, "__attribute__((__vector_size__(");
    cs_b_ll (&n, t->n / cs_ty_size (t->to));
    cs_b_str (&n, " * sizeof(");
    cs_p_ty (&n, t->to, sug);
    cs_b_str (&n, ")))) ");
    cs_p_ty (&n, cs_unqual (t->to), sug);
  }
  else if (t->k == TY_BITINT || t->k == TY_UBITINT) { cs_b_str (&n, cs_pick (t->k == TY_UBITINT, "unsigned _BitInt(", "_BitInt(")); cs_b_ll (&n, t->n); cs_b_byte (&n, ')'); }
  else if (t->k == TY_BUILTINFN) cs_b_str (&n, "<builtin>");
  else if (t->k == TY_SVE) cs_b_bytes (&n, t->name, t->nlen);
  else cs_b_str (&n, "?");
  cs_b_buf (o, &n);
  if (in->n) { if (in->p[0] != '[') cs_b_byte (o, ' '); cs_b_buf (o, in); }
}
#include "cs_l.c"
#include "cs_e.c"
#include "cs_x.c"
#include "cs_d.c"
#include "cl_u.c"
#include "cl_t.c"
#include "cl_x.c"
#include "cl_w.c"
#include "cl_h.c"
#include "cl_a.c"
#include "cl_m.c"
