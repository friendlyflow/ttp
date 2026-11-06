/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cs_e.c (in cs.c): expressions as clang's Sema builds them for C */
static struct cs_ex *cs_mk (int k, struct cs_ty *t, int lv)
{
  struct cs_ex *e = alloc (sizeof (struct cs_ex));
  e->k = k; e->t = t; e->lv = lv;
  return e;
}
static void cs_add (struct cs_ex *e, struct cs_ex *k)
{
  if (e->nk == e->room) {
    long m = e->room * 2 + 2, i = 0;
    struct cs_ex **ks = alloc (m * sizeof (struct cs_ex *));
    while (i < e->nk) { ks[i] = e->kid[i]; i++; }
    e->kid = ks;
    e->room = m;
  }
  e->kid[e->nk++] = k;
}
static struct cs_ex *cs_mk1 (int k, struct cs_ty *t, int lv, struct cs_ex *a) { struct cs_ex *e = cs_mk (k, t, lv); cs_add (e, a); return e; }
static struct cs_ex *cs_cast_force (struct cs_ex *e, struct cs_ty *t, int ck) { struct cs_ex *r = cs_mk1 (E_ICE, t, 0, e); r->op = ck; return r; }
/* clang's ImpCastExprToType: none if the same type, a cast of that kind under it retyped */
static struct cs_ex *cs_ice (struct cs_ex *e, struct cs_ty *t, int ck)
{
  if (cs_same_ty (e->t, t)) return e;
  if (e->k == E_ICE && e->op == ck) { e->t = t; e->lv = 0; return e; }
  return cs_cast_force (e, t, ck);
}
static struct cs_ex *cs_named (struct cs_ex *e, char *s) { e->name = (unsigned char *) s; e->nlen = cstrlen (s); return e; }

/* ---- constants ---- */
static long long cs_wrap (long long v, struct cs_ty *t)
{
  long long nbits;
  if (!cs_is_int (t)) return v;
  if (cs_kind (t) == TY_BOOL) return v != 0;
  nbits = cs_int_bits (t);
  if (nbits >= 64) return v;
  if (cs_is_signed (t)) {
    unsigned long long m = (unsigned long long) 1 << (nbits - 1);
    unsigned long long u = (unsigned long long) v & (((unsigned long long) 1 << nbits) - 1);
    return (long long) ((u ^ m) - m);
  }
  return (long long) ((unsigned long long) v & (((unsigned long long) 1 << nbits) - 1));
}
static int cs_eval (struct cs_ex *e, long long *v);
static int cs_builtin_is (struct cs_ex *e, char *name);
/* strlen of a literal or a const array a literal sets, in an array's count: clang folds that, so the array is no variable-length one (tst-unlockedio's char buf[strlen (blah) + 1]) */
static int cs_count_strlen (struct cs_ex *e, long long *v)
{
  struct cs_ex *f = e->kid[0], *a;
  while (f->k == E_ICE || f->k == E_CONST) f = f->kid[0];
  if (f->k != E_REF || e->nk != 2) return 0;
  if (!cs_eqb (f->name, f->nlen, (unsigned char *) "strlen", 6) && !cs_eqb (f->name, f->nlen, (unsigned char *) "__builtin_strlen", 16)) return 0;
  a = e->kid[1];
  while (a->k == E_ICE || a->k == E_CONST) a = a->kid[0];
  if (a->k == E_REF && a->d && a->d->k == DK_VAR && a->d->init && cs_canon (a->d->t)->k == TY_ARRAY && (cs_canon (cs_canon (a->d->t)->to)->q & Q_CONST)) {
    a = a->d->init;
    while (a->k == E_ICE || a->k == E_CONST) a = a->kid[0];
  }
  if (a->k != E_STR) return 0;
  *v = cs_canon (a->t)->n - 1;
  return 1;
}
static int cs_eval_call (struct cs_ex *e, long long *v)
{
  if (T->incount && cs_count_strlen (e, v)) return 1;
  struct cs_ex *f = e->kid[0];
  long long a;
  while (f->k == E_ICE) f = f->kid[0];
  if (f->k != E_REF) return 0;
  if (cs_eqb (f->name, f->nlen, (unsigned char *) "__builtin_constant_p", 20)) {
    *v = e->nk > 1 && cs_eval (e->kid[1], &a);
    if (e->nk > 1 && !*v) { struct cs_ex *x = e->kid[1]; while (x->k == E_ICE) x = x->kid[0]; if (x->k == E_STR) *v = 1; }
    return 1;
  }
  if (cs_eqb (f->name, f->nlen, (unsigned char *) "__builtin_expect", 16) && e->nk > 2) return cs_eval (e->kid[1], v);
  return 0;
}
static int cs_eval (struct cs_ex *e, long long *v)
{
  long long a, b;
  struct cs_ty *t = e->t;
  if (e->isval) { *v = e->val; return 1; }
  if (e->k == E_ICE || e->k == E_CAST) {
    if (e->op == CK_TOVOID) return 0;
    if (!cs_eval (e->kid[0], &a)) return 0;
    if (e->op == CK_INTEGRALTOBOOLEAN || e->op == CK_POINTERTOBOOLEAN) { *v = a != 0; return 1; }
    if (cs_is_int (t) || e->op == CK_NOOP || e->op == CK_LVALUETORVALUE) { *v = cs_wrap (a, t); return 1; }
    if (cs_is_ptr (t) && (e->op == CK_NULLTOPOINTER || e->op == CK_INTEGRALTOPOINTER || e->op == CK_BITCAST || e->op == CK_NOOP)) { *v = a; return 1; }
    return 0;
  }
  if (e->k == E_CONST) return cs_eval (e->kid[0], v);
  if (e->k == E_UN) {
    if (same (e->name, e->nlen, "__extension__")) return cs_eval (e->kid[0], v);
    if (!cs_eval (e->kid[0], &a)) return 0;
    if (same (e->name, e->nlen, "-")) { *v = cs_wrap ((long long) ((unsigned long long) 0 - (unsigned long long) a), t); return 1; }
    if (same (e->name, e->nlen, "+")) { *v = a; return 1; }
    if (same (e->name, e->nlen, "~")) { *v = cs_wrap (~a, t); return 1; }
    if (same (e->name, e->nlen, "!")) { *v = a == 0; return 1; }
    return 0;
  }
  if (e->k == E_BIN) {
    unsigned char *o = e->name;
    long n = e->nlen;
    int uns;
    if (same (o, n, "&&")) { if (!cs_eval (e->kid[0], &a)) return 0; if (!a) { *v = 0; return 1; } if (!cs_eval (e->kid[1], &b)) return 0; *v = b != 0; return 1; }
    if (same (o, n, "||")) { if (!cs_eval (e->kid[0], &a)) return 0; if (a) { *v = 1; return 1; } if (!cs_eval (e->kid[1], &b)) return 0; *v = b != 0; return 1; }
    if (same (o, n, ",")) return cs_eval (e->kid[1], v);
    if (!cs_eval (e->kid[0], &a) || !cs_eval (e->kid[1], &b)) return 0;
    uns = !cs_is_signed (e->kid[0]->t) || cs_is_ptr (e->kid[0]->t);
    if (same (o, n, "+")) { if (cs_is_ptr (t)) return 0; *v = cs_wrap ((long long) ((unsigned long long) a + (unsigned long long) b), t); return 1; }
    if (same (o, n, "-")) { if (cs_is_ptr (t)) return 0; *v = cs_wrap ((long long) ((unsigned long long) a - (unsigned long long) b), t); return 1; }
    if (same (o, n, "*")) { *v = cs_wrap ((long long) ((unsigned long long) a * (unsigned long long) b), t); return 1; }
    if (same (o, n, "/") || same (o, n, "%")) {
      int div = o[0] == '/';
      if (b == 0) return 0;
      if (uns) *v = (long long) (div ? (unsigned long long) a / (unsigned long long) b : (unsigned long long) a % (unsigned long long) b);
      else if (b == -1) *v = div ? (long long) ((unsigned long long) 0 - (unsigned long long) a) : 0;
      else *v = div ? a / b : a % b;
      *v = cs_wrap (*v, t);
      return 1;
    }
    if (same (o, n, "<<")) { if (b < 0 || b >= 64) return 0; *v = cs_wrap ((long long) ((unsigned long long) a << b), t); return 1; }
    if (same (o, n, ">>")) {
      if (b < 0 || b >= 64) return 0;
      if (uns) *v = (long long) ((unsigned long long) a >> b);
      else if (a < 0) *v = ~((~a) >> b);
      else *v = a >> b;
      *v = cs_wrap (*v, t);
      return 1;
    }
    if (same (o, n, "&")) { *v = a & b; return 1; }
    if (same (o, n, "|")) { *v = a | b; return 1; }
    if (same (o, n, "^")) { *v = a ^ b; return 1; }
    if (same (o, n, "==")) { *v = a == b; return 1; }
    if (same (o, n, "!=")) { *v = a != b; return 1; }
    if (uns) {
      unsigned long long x = a, y = b;
      if (same (o, n, "<")) *v = x < y; else if (same (o, n, ">")) *v = x > y; else if (same (o, n, "<=")) *v = x <= y; else if (same (o, n, ">=")) *v = x >= y; else return 0;
      return 1;
    }
    if (same (o, n, "<")) *v = a < b; else if (same (o, n, ">")) *v = a > b; else if (same (o, n, "<=")) *v = a <= b; else if (same (o, n, ">=")) *v = a >= b; else return 0;
    return 1;
  }
  if (e->k == E_GENERIC) return cs_eval (e->kid[e->val + 1], v);
  if (e->k == E_COND) { if (!cs_eval (e->kid[0], &a)) return 0; return cs_eval (e->kid[a ? 1 : 2], v); }
  if (e->k == E_BCOND) { if (!cs_eval (e->kid[0], &a)) return 0; if (a) { *v = a; return 1; } return cs_eval (e->kid[3], v); }
  if (e->k == E_CALL) return cs_eval_call (e, v);
  return 0;
}
static int cs_is_npc (struct cs_ex *e)
{
  long long v;
  for (;;) {
    struct cs_ty *t = cs_canon (e->t);
    if ((e->k == E_CAST || e->k == E_ICE) && t->k == TY_PTR && cs_canon (t->to)->k == TY_VOID && !cs_canon (t->to)->q) { e = e->kid[0]; continue; }
    if (e->k == E_UN && same (e->name, e->nlen, "__extension__")) { e = e->kid[0]; continue; }
    break;
  }
  return cs_is_int (e->t) && cs_eval (e, &v) && v == 0;
}

/* ---- conversions ---- */
static struct cs_ex *cs_lval_conv (struct cs_ex *e)
{
  struct cs_ex *r;
  if (!e->lv) return e;
  if (cs_is_void (e->t)) return e;
  r = cs_cast_force (e, cs_unqual (e->t), CK_LVALUETORVALUE);
  if (cs_kind (r->t) == TY_ATOMIC) r = cs_ice (r, cs_canon (r->t)->to, CK_ATOMICTONONATOMIC);
  return r;
}
static struct cs_ex *cs_fa_conv (struct cs_ex *e)
{
  struct cs_ty *t = cs_canon (e->t);
  if (t->k == TY_FUNC) return cs_ice (e, cs_ptr_to (e->t), CK_FUNCTIONTOPOINTERDECAY);
  if (t->k == TY_ARRAY) return cs_ice (e, cs_ptr_to (t->to), CK_ARRAYTOPOINTERDECAY);
  return e;
}
static struct cs_ex *cs_rv (struct cs_ex *e) { return cs_lval_conv (cs_fa_conv (e)); }
static int cs_promotable (struct cs_ty *t)
{
  int k = cs_kind (t);
  return k == TY_BOOL || k == TY_CHAR || k == TY_SCHAR || k == TY_UCHAR || k == TY_SHORT || k == TY_USHORT || k == TY_ENUM;
}
static struct cs_ty *cs_promoted (struct cs_ty *t)
{
  struct cs_ty *c = cs_canon (t);
  if (c->k == TY_ENUM) return c->rec->promo ? c->rec->promo : cs_basic (TY_UINT);
  if (cs_is_signed (c)) return cs_basic (TY_INT);
  return cs_ty_size (c) != 4 ? cs_basic (TY_INT) : cs_basic (TY_UINT);
}
/* the bitfield an expression reads, if any (clang's getSourceBitField) */
static struct cs_field *cs_source_bitfield (struct cs_ex *e)
{
  for (;;) {
    if (e->k == E_ICE && (e->op == CK_LVALUETORVALUE || (e->op == CK_NOOP && e->lv))) { e = e->kid[0]; continue; }
    if (e->k == E_MEM) return e->fd && e->fd->width >= 0 ? e->fd : 0;
    if (e->k == E_BIN && e->nk == 2) {
      if (same (e->name, e->nlen, "=")) { e = e->kid[0]; continue; }
      if (same (e->name, e->nlen, ",")) { e = e->kid[1]; continue; }
      return 0;
    }
    if (e->k == E_CASS) { e = e->kid[0]; continue; }
    if (e->k == E_UN && (same (e->name, e->nlen, "++") || same (e->name, e->nlen, "--"))) { e = e->kid[0]; continue; }
    return 0;
  }
}
static struct cs_ty *cs_bitfield_promo (struct cs_ex *e)
{
  struct cs_field *f = cs_source_bitfield (e);
  if (!f) return 0;
  if (cs_kind (f->t) == TY_BITINT || cs_kind (f->t) == TY_UBITINT) return f->t;
  if (f->width < 32) return cs_basic (TY_INT);
  if (f->width == 32) return cs_is_signed (f->t) ? cs_basic (TY_INT) : cs_basic (TY_UINT);
  return 0;
}
static struct cs_ex *cs_uuc (struct cs_ex *e)
{
  struct cs_ty *t, *p;
  e = cs_rv (e);
  t = cs_canon (e->t);
  if (t->k == TY_HALF) return cs_ice (e, cs_basic (TY_FLOAT), CK_FLOATINGCAST);
  if (cs_k_int (t->k)) {
    p = cs_bitfield_promo (e);
    if (p) return cs_ice (e, p, CK_INTEGRALCAST);
    if (cs_promotable (t)) return cs_ice (e, cs_promoted (t), CK_INTEGRALCAST);
  }
  return e;
}
static struct cs_ex *cs_arg_promo (struct cs_ex *e)
{
  e = cs_uuc (e);
  if (cs_kind (e->t) == TY_FLOAT) return cs_ice (e, cs_basic (TY_DOUBLE), CK_FLOATINGCAST);
  return e;
}
/* IgnoredValueConversions: an expression whose value is not used */
static struct cs_ex *cs_ignored (struct cs_ex *e)
{
  if (!e->lv) { if (cs_kind (e->t) == TY_FUNC) return cs_fa_conv (e); return e; }
  return cs_rv (e);
}
static int cs_flt_rank (struct cs_ty *t)
{
  int k = cs_kind (t);
  if (k == TY_HALF || k == TY_FLOAT16 || k == TY_BF16) return 1;
  if (k == TY_FLOAT) return 2;
  if (k == TY_DOUBLE) return 3;
  if (k == TY_LDOUBLE) return 4;
  return 5;
}
static struct cs_ty *cs_int_conv (struct cs_ex **l, struct cs_ex **r, struct cs_ty *lt, struct cs_ty *rty, int comp)
{
  int ls = cs_is_signed (lt), rs = cs_is_signed (rty);
  int lrank = cs_rank (lt), rr = cs_rank (rty);
  int order = 0;
  struct cs_ty *res;
  if (lrank > rr) order = 1;
  if (lrank < rr) order = 0 - 1;
  if (ls == rs) {
    if (order >= 0) { *r = cs_ice (*r, lt, CK_INTEGRALCAST); return lt; }
    if (!comp) *l = cs_ice (*l, rty, CK_INTEGRALCAST);
    return rty;
  }
  if (order != (ls ? 1 : -1)) {
    if (rs) { *r = cs_ice (*r, lt, CK_INTEGRALCAST); return lt; }
    if (!comp) *l = cs_ice (*l, rty, CK_INTEGRALCAST);
    return rty;
  }
  if (cs_int_bits (lt) != cs_int_bits (rty)) {
    if (ls) { *r = cs_ice (*r, lt, CK_INTEGRALCAST); return lt; }
    if (!comp) *l = cs_ice (*l, rty, CK_INTEGRALCAST);
    return rty;
  }
  res = cs_to_unsigned (ls ? lt : rty);
  *r = cs_ice (*r, res, CK_INTEGRALCAST);
  if (!comp) *l = cs_ice (*l, res, CK_INTEGRALCAST);
  return res;
}
static struct cs_ty *cs_uac (struct cs_ex **l, struct cs_ex **r, int comp)
{
  struct cs_ty *lt, *rty, *lu, *bfp;
  if (!comp) *l = cs_uuc (*l);
  *r = cs_uuc (*r);
  lt = cs_unqual ((*l)->t);
  rty = cs_unqual ((*r)->t);
  if (cs_kind (lt) == TY_ATOMIC) lt = cs_canon (lt)->to;
  if (cs_same_ty (lt, rty)) return lt;
  if (!cs_is_arith (lt) || !cs_is_arith (rty)) return 0;
  lu = lt;
  if (cs_is_int (lt) && cs_promotable (lt)) lt = cs_promoted (lt);
  bfp = cs_bitfield_promo (*l);
  if (bfp) lt = bfp;
  if (!cs_same_ty (lt, lu) && !comp) *l = cs_ice (*l, lt, CK_INTEGRALCAST);
  if (cs_same_ty (lt, rty)) return lt;
  if (cs_is_complex (lt) || cs_is_complex (rty)) {
    struct cs_ty *le = cs_is_complex (lt) ? cs_canon (lt)->to : lt, *re = cs_is_complex (rty) ? cs_canon (rty)->to : rty;
    struct cs_ty *res;
    if (cs_is_flt (le) || cs_is_flt (re)) {
      struct cs_ty *e = cs_flt_rank (le) >= cs_flt_rank (re) || !cs_is_flt (re) ? (cs_is_flt (le) ? le : re) : re;
      res = cs_ty_new (TY_COMPLEX); res->to = cs_canon (e);
    } else { res = cs_is_complex (lt) ? lt : rty; }
    if (!cs_same_ty (rty, res)) *r = cs_ice (*r, res, cs_is_complex (rty) ? (cs_is_flt (cs_canon (rty)->to) ? CK_FLOATINGCOMPLEXCAST : CK_INTEGRALCOMPLEXTOFLOATINGCOMPLEX) : (cs_is_flt (rty) ? CK_FLOATINGREALTOCOMPLEX : CK_INTEGRALREALTOCOMPLEX));
    if (!comp && !cs_same_ty (lt, res)) *l = cs_ice (*l, res, cs_is_complex (lt) ? (cs_is_flt (cs_canon (lt)->to) ? CK_FLOATINGCOMPLEXCAST : CK_INTEGRALCOMPLEXTOFLOATINGCOMPLEX) : (cs_is_flt (lt) ? CK_FLOATINGREALTOCOMPLEX : CK_INTEGRALREALTOCOMPLEX));
    return res;
  }
  /* (fixed point, clang's handleFloatConversion and handleFixedPointConversion: a floating
     type's operand converted to it, else no conversion in the tree, the type of the higher
     rank, an unsigned one signed beside a signed, saturating if either is) */
  if (cs_is_fix (lt) || cs_is_fix (rty)) {
    struct cs_ty *res;
    int lr = 0, rr = 0;
    if (cs_is_flt (lt)) { *r = cs_ice (*r, lt, CK_FIXEDPOINTTOFLOATING); return lt; }
    if (cs_is_flt (rty)) { if (!comp) *l = cs_ice (*l, rty, CK_FIXEDPOINTTOFLOATING); return rty; }
    if (cs_is_fix (lt) && cs_is_fix (rty)) {
      if (!cs_fix_uns (rty) && cs_fix_uns (lt)) lt = cs_fix_ty (cs_fix_code (lt) - 6);
      else if (cs_fix_uns (rty) && !cs_fix_uns (lt)) rty = cs_fix_ty (cs_fix_code (rty) - 6);
    }
    if (cs_is_fix (lt)) lr = cs_fix_rank (lt);
    if (cs_is_fix (rty)) rr = cs_fix_rank (rty);
    res = rty;
    if (lr > rr) res = lt;
    if (((cs_is_fix (lt) && cs_fix_sat (lt)) || (cs_is_fix (rty) && cs_fix_sat (rty))) && !cs_fix_sat (res)) res = cs_fix_ty (cs_fix_code (res) + 12);
    return res;
  }
  if (cs_is_flt (lt) && cs_is_flt (rty)) {
    if (cs_flt_rank (lt) > cs_flt_rank (rty)) { *r = cs_ice (*r, lt, CK_FLOATINGCAST); return lt; }
    if (!comp) *l = cs_ice (*l, rty, CK_FLOATINGCAST);
    return rty;
  }
  if (cs_is_flt (lt)) { if (cs_kind (lt) == TY_HALF) lt = cs_basic (TY_FLOAT); *r = cs_ice (*r, lt, CK_INTEGRALTOFLOATING); return lt; }
  if (cs_is_flt (rty)) { if (!comp) *l = cs_ice (*l, rty, CK_INTEGRALTOFLOATING); return rty; }
  return cs_int_conv (l, r, lt, rty, comp);
}
/* types the same but for cvr qualifiers at every pointer level */
static int cs_cvr_similar (struct cs_ty *a, struct cs_ty *b)
{
  for (;;) {
    a = cs_unqual (cs_canon (a));
    b = cs_unqual (cs_canon (b));
    if (cs_same_ty (a, b)) return 1;
    if (a->k == TY_PTR && b->k == TY_PTR) { a = a->to; b = b->to; continue; }
    if (a->k == TY_ARRAY && b->k == TY_ARRAY && a->n == b->n) { a = a->to; b = b->to; continue; }
    return 0;
  }
}
/* PrepareScalarCast: the kind of a scalar conversion (complex element casts made first) */
/* a pointer's pointee's address space (x86_64's __seg_fs, __seg_gs) */
static int cs_ptr_as (struct cs_ty *t) { return cs_quals (cs_canon (t)->to) & (Q_FS | Q_GS); }
static int cs_scalar_kind (struct cs_ex **s, struct cs_ty *d)
{
  struct cs_ty *st = (*s)->t;
  if (cs_same_ty (cs_unqual (st), cs_unqual (d))) return CK_NOOP;
  if (cs_is_fix (st)) {
    if (cs_is_fix (d)) return CK_FIXEDPOINTCAST;
    if (cs_kind (d) == TY_BOOL) return CK_FIXEDPOINTTOBOOLEAN;
    if (cs_is_int (d)) return CK_FIXEDPOINTTOINTEGRAL;
    if (cs_is_flt (d)) return CK_FIXEDPOINTTOFLOATING;
  }
  if (cs_is_fix (d)) {
    if (cs_is_int (st)) return CK_INTEGRALTOFIXEDPOINT;
    if (cs_is_flt (st)) return CK_FLOATINGTOFIXEDPOINT;
  }
  if (cs_is_ptr (st)) {
    if (cs_is_ptr (d) && cs_ptr_as (st) != cs_ptr_as (d)) return CK_ADDRESSSPACECONVERSION;
    if (cs_is_ptr (d)) return cs_cvr_similar (st, d) ? CK_NOOP : CK_BITCAST;
    if (cs_kind (d) == TY_BOOL) return CK_POINTERTOBOOLEAN;
    if (cs_is_int (d)) return CK_POINTERTOINTEGRAL;
    return CK_BITCAST;
  }
  if (cs_is_int (st)) {
    if (cs_is_ptr (d)) return cs_is_npc (*s) ? CK_NULLTOPOINTER : CK_INTEGRALTOPOINTER;
    if (cs_kind (d) == TY_BOOL) return CK_INTEGRALTOBOOLEAN;
    if (cs_is_int (d)) return CK_INTEGRALCAST;
    if (cs_is_flt (d)) return CK_INTEGRALTOFLOATING;
    if (cs_is_complex (d)) {
      struct cs_ty *e = cs_canon (d)->to;
      if (cs_is_flt (e)) { *s = cs_ice (*s, e, CK_INTEGRALTOFLOATING); return CK_FLOATINGREALTOCOMPLEX; }
      *s = cs_ice (*s, e, CK_INTEGRALCAST);
      return CK_INTEGRALREALTOCOMPLEX;
    }
  }
  if (cs_is_flt (st)) {
    if (cs_is_flt (d)) return CK_FLOATINGCAST;
    if (cs_kind (d) == TY_BOOL) return CK_FLOATINGTOBOOLEAN;
    if (cs_is_int (d)) return CK_FLOATINGTOINTEGRAL;
    if (cs_is_complex (d)) {
      struct cs_ty *e = cs_canon (d)->to;
      if (cs_is_flt (e)) { *s = cs_ice (*s, e, CK_FLOATINGCAST); return CK_FLOATINGREALTOCOMPLEX; }
      *s = cs_ice (*s, e, CK_FLOATINGTOINTEGRAL);
      return CK_INTEGRALREALTOCOMPLEX;
    }
  }
  if (cs_is_complex (st)) {
    int sf = cs_is_flt (cs_canon (st)->to);
    if (cs_is_complex (d)) {
      int df = cs_is_flt (cs_canon (d)->to);
      if (sf && df) return CK_FLOATINGCOMPLEXCAST;
      if (!sf && !df) return CK_INTEGRALCOMPLEXCAST;
      return sf ? CK_FLOATINGCOMPLEXTOINTEGRALCOMPLEX : CK_INTEGRALCOMPLEXTOFLOATINGCOMPLEX;
    }
    if (cs_kind (d) == TY_BOOL) return sf ? CK_FLOATINGCOMPLEXTOBOOLEAN : CK_INTEGRALCOMPLEXTOBOOLEAN;
    {
      struct cs_ty *e = cs_canon (st)->to;
      *s = cs_ice (*s, e, sf ? CK_FLOATINGCOMPLEXTOREAL : CK_INTEGRALCOMPLEXTOREAL);
      if (cs_is_flt (d)) return sf ? CK_FLOATINGCAST : CK_INTEGRALTOFLOATING;
      return sf ? CK_FLOATINGTOINTEGRAL : CK_INTEGRALCAST;
    }
  }
  return CK_NOOP;
}
/* the conversion as if by assignment to type lt (CheckSingleAssignmentConstraints) */
static struct cs_ex *cs_assign_conv (struct cs_ty *lt, struct cs_ex *r)
{
  struct cs_ty *lc = cs_unqual (cs_canon (lt)), *rc;
  int k;
  if (lc->k == TY_PTR && cs_is_npc (r)) return cs_ice (r, lt, CK_NULLTOPOINTER);
  r = cs_rv (r);
  rc = cs_unqual (cs_canon (r->t));
  if (cs_same_ty (lc, rc)) return r;
  if (lc->k == TY_ATOMIC) {
    struct cs_ex *x = cs_assign_conv (lc->to, r);
    return cs_ice (x, cs_unqual (lt), CK_NONATOMICTOATOMIC);
  }
  if (lc->k == TY_VECTOR || rc->k == TY_VECTOR) return cs_ice (r, cs_unqual (lt), CK_BITCAST);
  if (cs_is_arith (lc) && cs_is_arith (rc)) { k = cs_scalar_kind (&r, lc); return cs_ice (r, cs_unqual (lt), k); }
  if (lc->k == TY_PTR) {
    if (rc->k == TY_PTR && cs_ptr_as (rc) != cs_ptr_as (lc)) return cs_ice (r, cs_unqual (lt), CK_ADDRESSSPACECONVERSION);
    if (rc->k == TY_PTR) return cs_ice (r, cs_unqual (lt), cs_cvr_similar (rc, lc) ? CK_NOOP : CK_BITCAST);
    if (cs_is_int (rc)) return cs_ice (r, cs_unqual (lt), CK_INTEGRALTOPOINTER);
    return r;
  }
  if (rc->k == TY_PTR) {
    if (lc->k == TY_BOOL) return cs_ice (r, cs_unqual (lt), CK_POINTERTOBOOLEAN);
    if (cs_is_int (lc)) return cs_ice (r, cs_unqual (lt), CK_POINTERTOINTEGRAL);
    return r;
  }
  if ((lc->k == TY_STRUCT || lc->k == TY_UNION) && cs_compatible (lc, rc)) return cs_ice (r, cs_unqual (lt), CK_NOOP);
  return r;
}
