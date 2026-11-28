/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* nf.c: roundtrip.pl's normal forms, for roundtrip.c: E (an expression),
   S (statements), fnorm (a function), gnorm (a global), each as the Perl
   sub of its name; glibc's side first (side_ff 0), each normal form held
   against the one a unit's cache keeps (--check-cache). */

/* ---- the state of a normal form (the Perl's locals) */
static int in_global;
static struct hash *staticid, *constid, *labels, *locals_, *regvar, *asmalias, *enumval, *errordecl;
static struct hash *asmfn, *noproto, *asked, *x87in_;
static struct str *unit_i, *itext, *itext_of;

/* ---- the AST */
static struct jv *jstrv (char *c) { struct jv *v = jv_new ('s'); v->s = s_of (c); return v; }
static struct hash *atomicop;   /* (in roundtrip_main: h_words) */
static void v_cat (struct vec *a, struct vec *b) { long i, n = b->n; for (i = 0; i < n; i++) v_push (a, b->v[i]); }
static struct jv *kid0 (struct jv *n) { return n ? jkid (n, 0) : 0; }
static struct jv *strip (struct jv *n)
{
  while (n && mf (jkind (n), "^(ImplicitCastExpr|CStyleCastExpr|ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$", "")) n = kid0 (n);
  return n;
}
static struct jv *unparen (struct jv *n)
{
  while (n && mf (jkind (n), "^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$", "")) n = kid0 (n);
  return n;
}
static struct jv *unimplicit (struct jv *n)
{
  while (n && mf (jkind (n), "^(ImplicitCastExpr|ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$", "")) n = kid0 (n);
  return n;
}
static struct jv *unpromote (struct jv *n)
{
  while (n && (mf (jkind (n), "^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$", "")
               || (kind_is (n, "ImplicitCastExpr") && !mf (jstr (n, "castKind") ? jstr (n, "castKind") : s_of (""), "ToBoolean$", "")))) n = kid0 (n);
  return n;
}
static struct str *sor (struct str *s) { return s ? s : s_of (""); }
static struct str *jsor (struct jv *n, char *k) { return n ? sor (jstr (n, k)) : s_of (""); }
/* a referencedDecl's field: (x // {})->{referencedDecl}{f} // '' */
static struct jv *rdecl (struct jv *n) { return n ? jget (n, "referencedDecl") : 0; }
static struct str *rd_name (struct jv *n) { return jsor (rdecl (n), "name"); }
static struct str *rd_kind (struct jv *n) { return jsor (rdecl (n), "kind"); }
/* the first child that is no attribute */
static struct jv *first_nonattr (struct jv *n)
{
  struct vec *k = jkids (n);
  long i;
  for (i = 0; i < k->n; i++) if (!mf (jkind (k->v[i]), "Attr$", "")) return k->v[i];
  return 0;
}
/* the type's qualType (desugared first, else the qualType) */
static struct str *qtype (struct jv *n)
{
  struct jv *t = n ? jget (n, "type") : 0;
  struct str *q;
  if (!t) return 0;
  q = jstr (t, "desugaredQualType");
  return q ? q : jstr (t, "qualType");
}
static struct str *tcls (struct jv *n)
{
  struct jv *t = n ? jget (n, "type") : 0;
  if (!t) return s_of ("-");
  return tstr (sor (qtype (n)));
}
static struct str *retcls (struct jv *fn)
{
  struct str *s = noattr (sor (qtype (fn)));
  long d = 0, i;
  s = ssub (s, "\\s+$", "", "");
  for (i = s->n - 1; i >= 0; i--) { if (s->p[i] == ')') d++; if (s->p[i] == '(') d--; if (!d) break; }
  return tstr (s_sub (s, 0, i < 0 ? 0 : i));
}
/* a string of a number as Perl's number: == 0 */
static int num_zero (struct str *v)
{
  long i = 0;
  if (!v || !v->n) return 1;
  if (v->p[0] == '-' || v->p[0] == '+') i++;
  if (i + 1 < v->n && v->p[i] == '0' && (v->p[i + 1] == 'x' || v->p[i + 1] == 'X')) return 1;
  for (; i < v->n; i++) { int c = v->p[i]; if (c == 'e' || c == 'E') break; if (is_digit (c) && c != '0') return 0; if (!is_digit (c) && c != '.') break; }
  return 1;
}
/* a decimal value v: 0 <= v < 2^31, as Perl compares */
static int small_val (struct str *v)
{
  struct big *b;
  if (!v || !v->n || v->p[0] == '-') return v && v->n && v->p[0] == '-' ? 0 : 1;
  b = b_from_dec (v);
  return b_cmp (b, b_pow2 (31)) < 0;
}
static int ge_2p31 (struct str *v) { return v && v->n && v->p[0] != '-' && b_cmp (b_from_dec (v), b_pow2 (31)) >= 0; }

/* names.txt's answers, each kept (%asked) */
static int asmfn_of (struct str *x) { int v = h_has (asmfn, x); struct str *k = s_of ("a "); s_app (k, x); h_set (asked, k, v); return v; }
static int noproto_of (struct str *x) { int v = h_has (noproto, x); struct str *k = s_of ("n "); s_app (k, x); h_set (asked, k, v); return v; }

static struct str *name_of (struct jv *d)
{
  struct str *n = jsor (d, "name"), *x, *id = jstr (d, "id");
  if (side_ff) { x = h_pv (orig, n); return x ? x : n; }
  if (kind_is (d, "VarDecl") && (x = h_pv (regvar, n)) && x->n && !(id && h_has (locals_, id))) return x;
  if (id && (x = h_pv (staticid, id)) && x->n) return x;
  n = ssub (n, "^__builtin_((?:mem|str|stp)\\w+|free|malloc)$", "", "$1");
  if (mf (n, "^(?:copysign|fabs)(?:[fl]|f128)?$", "") && kind_is (d, "FunctionDecl")) n = cat2 ("__builtin_", n, "");
  if (s_is (n, "__builtin_c23_va_start")) n = s_of ("__builtin_va_start");
  if (kind_is (d, "FunctionDecl") && h_has (asmalias, n)) n = h_pv (asmalias, n);
  return n;
}
static struct jv *fnaddr (struct jv *c)
{
  struct jv *r;
  if (!(kind_is (c, "UnaryOperator") && jis (c, "opcode", "&"))) return 0;
  r = strip (kid0 (c));
  return kind_is (r, "DeclRefExpr") && s_is (rd_kind (r), "FunctionDecl") ? r : 0;
}
static int is_asmfncall (struct jv *n)
{
  struct jv *s = unparen (n), *f, *a, *d;
  if (!kind_is (s, "CallExpr")) return 0;
  f = strip (kid0 (s));
  a = f ? fnaddr (f) : 0;
  if (a) f = a;
  d = rdecl (f);
  if (!d) return 0;
  return asmfn_of (name_of (d));
}
static int is_atomiccall (struct jv *n) { struct jv *s = unparen (n); return kind_is (s, "CallExpr") && mf (rd_name (strip (kid0 (s))), "^__atomic_\\w+_\\d+$", ""); }
static int is_mempcpy (struct jv *n) { struct jv *s = unparen (n); return kind_is (s, "CallExpr") && s_is (rd_name (strip (kid0 (s))), "__builtin_mempcpy"); }
static int is_asmcall (struct jv *n) { struct jv *s = strip (n); return s && kind_is (s, "CallExpr") && mf (rd_name (strip (kid0 (s))), "^_+asm_", ""); }
static struct str *syscall_idiom (struct jv *cs);
static int is_syscallv (struct jv *n)
{
  struct jv *s;
  struct str *k;
  if (!t_is ("arm")) return 0;
  s = unparen (n);
  while (kind_is (s, "ImplicitCastExpr") && jis (s, "castKind", "IntegralCast")) s = unparen (kid0 (s));
  k = jkind (s);
  if (s_is (k, "StmtExpr")) return !side_ff && syscall_idiom (kid0 (s)) != 0;
  if (!s_is (k, "CallExpr")) return 0;
  if (!rdecl (strip (kid0 (s)))) return 0;
  return s_is (rd_name (strip (kid0 (s))), "__ff_syscall");
}
static int asm_valued (struct jv *n)
{
  struct jv *s = unparen (n);
  while (kind_is (s, "ImplicitCastExpr")) s = unparen (kid0 (s));
  if (is_asmfncall (s)) return 1;
  if (kind_is (s, "BinaryOperator") && mf (jsor (s, "opcode"), "^[-+]$", "") && (asm_valued (jkid (s, 0)) || asm_valued (jkid (s, 1)))) return 1;
  if (kind_is (s, "ConditionalOperator") && (asm_valued (jkid (s, 1)) || asm_valued (jkid (s, 2)))) return 1;
  return 0;
}
static int small_literal (struct jv *n)
{
  struct jv *s = unparen (n);
  return mf (jkind (s), "^(IntegerLiteral|CharacterLiteral)$", "") && mf (tcls (s), "^[iu]32$", "") && small_val (jstr (s, "value"));
}
static int is_zero (struct jv *n) { struct jv *s = strip (n); return mf (jkind (s), "^(IntegerLiteral|FloatingLiteral)$", "") && num_zero (jstr (s, "value")); }
static int is_null (struct jv *n)
{
  int null = 0;
  while (n && mf (jkind (n), "^(ImplicitCastExpr|CStyleCastExpr|ParenExpr)$", "")) { if (jis (n, "castKind", "NullToPointer")) null = 1; n = kid0 (n); }
  return null && kind_is (n, "IntegerLiteral") && num_zero (jstr (n, "value"));
}
static int is_offsetof (struct jv *n)
{
  struct jv *s = unparen (n);
  if (!(kind_is (s, "UnaryOperator") && jis (s, "opcode", "&"))) return 0;
  s = unparen (kid0 (s));
  while (s && (mf (jkind (s), "^(MemberExpr|ArraySubscriptExpr)$", "") || (kind_is (s, "ImplicitCastExpr") && jis (s, "castKind", "ArrayToPointerDecay")))) s = unparen (kid0 (s));
  return s && mf (jkind (s), "CastExpr$", "") && kind_is (strip (s), "IntegerLiteral") && num_zero (jstr (strip (s), "value"));
}
/* inf or nan where n is a call of gcc's __builtin_huge_val, inf or nan, under floating conversions; else 0 */
static char *special_float (struct jv *n)
{
  struct str *name;
  struct jv *d;
  while (n && (mf (jkind (n), "^(ParenExpr|ConstantExpr)$", "") || (mf (jkind (n), "^(ImplicitCastExpr|CStyleCastExpr)$", "") && mf (jsor (n, "castKind"), "^(FloatingCast|NoOp)$", "")))) n = kid0 (n);
  if (!(n && kind_is (n, "CallExpr"))) return 0;
  d = rdecl (strip (kid0 (n)));
  if (!d) return 0;
  name = jsor (d, "name");
  if (mf (name, "^__builtin_(?:huge_val|inf)(?:[fl]|f128)?$", "")) return "inf";
  if (mf (name, "^__builtin_nan(?:[fl]|f128)?$", "")) return "nan";
  return 0;
}
/* balanced parentheses: never below 0, 0 at the end */
static int balanced (struct str *s)
{
  long d = 0, i;
  for (i = 0; i < s->n; i++) { if (s->p[i] == '(') d++; if (s->p[i] == ')') { d--; if (d < 0) return 0; } }
  return d == 0;
}
static int holds (struct jv *n, char *k)
{
  struct vec *c;
  long i;
  if (kind_is (n, k)) return 1;
  c = jkids (n);
  for (i = 0; i < c->n; i++) if (holds (c->v[i], k)) return 1;
  return 0;
}
/* Perl's str: a string literal's codes */
static struct str *strlit (struct str *v)
{
  struct str *p = s_of (""), *o = s_of ("");
  long i = 0, first = 1;
  if (mf (v, "^(L|u8|u|U)?\"", "")) { p = g0 (1); i = rc[1]; }
  {
    long e = v->n;
    if (e > i && v->p[e - 1] == '"') e--;
    v = s_sub (v, i, e); i = 0;
  }
  while (i < v->n) {
    long c = -1, j;
    if (v->p[i] == '\\' && i + 1 < v->n && v->p[i + 1] == 'x' && i + 2 < v->n && is_xdigit (v->p[i + 2])) {
      j = i + 2; c = 0;
      while (j < v->n && is_xdigit (v->p[j])) { c = c * 16 + hexv (v->p[j]); j++; }
      i = j;
    } else if (v->p[i] == '\\' && i + 1 < v->n && v->p[i + 1] >= '0' && v->p[i + 1] <= '7') {
      j = i + 1; c = 0;
      while (j < v->n && j < i + 4 && v->p[j] >= '0' && v->p[j] <= '7') { c = c * 8 + (v->p[j] - '0'); j++; }
      i = j;
    } else if (v->p[i] == '\\' && i + 5 < v->n + 0 && v->p[i + 1] == 'u' && is_xdigit (v->p[i + 2]) && is_xdigit (v->p[i + 3]) && is_xdigit (v->p[i + 4]) && is_xdigit (v->p[i + 5])) {
      c = 0; for (j = i + 2; j < i + 6; j++) c = c * 16 + hexv (v->p[j]);
      i += 6;
    } else if (v->p[i] == '\\' && i + 9 < v->n + 0 && v->p[i + 1] == 'U') {
      int ok = 1; c = 0; for (j = i + 2; j < i + 10; j++) { if (!is_xdigit (v->p[j])) ok = 0; else c = c * 16 + hexv (v->p[j]); }
      if (ok) i += 10; else c = -1;
    }
    if (c < 0 && v->p[i] == '\\' && i + 1 < v->n) {
      int x = v->p[i + 1];
      static char *ek = "ntrabfve\"'\\?";
      static int ev[] = { 10, 9, 13, 7, 8, 12, 11, 27, 34, 39, 92, 63 };
      long q;
      c = x;
      for (q = 0; ek[q]; q++) if (ek[q] == x) c = ev[q];
      i += 2;
    } else if (c < 0) {
      /* a byte (in a wide text too: utf8::decode of one byte changes none) */
      c = v->p[i];
      i++;
    }
    if (!first) s_chr (o, ',');
    s_app (o, s_num (c)); first = 0;
  }
  return cat2 (p->n && !s_is (p, "u8") ? "w" : "", o, "");
}

/* ---- an asm statement's text, from the unit's .i */
static int itext_load (void)
{
  if (!unit_i || !unit_i->n || !f_exists ((char *) unit_i->p)) return 0;
  if (!itext_of || !s_eq (itext_of, unit_i)) {
    struct str *t;
    a_push (u_arena); t = read_all ((char *) unit_i->p); a_pop ();
    if (!t) return 0;
    itext = t; itext_of = s_dup (unit_i);
  }
  return 1;
}
static long range_begin (struct jv *n)
{
  struct jv *r = n ? jget (n, "range") : 0, *b = r ? jget (r, "begin") : 0, *x;
  struct str *o = b ? jstr (b, "offset") : 0;
  if (!o) { x = b ? jget (b, "expansionLoc") : 0; o = x ? jstr (x, "offset") : 0; }
  if (!o) return -1;
  { long v = 0, i; for (i = 0; i < o->n; i++) v = v * 10 + (o->p[i] - '0'); return v; }
}
static struct str *asm_label (struct jv *a)
{
  long b;
  struct str *l = jstr (a, "label");
  if (l) return l;
  b = range_begin (a);
  if (b < 0 || !itext_load ()) return 0;
  {
    struct str *x = s_sub (itext, b, b + 80);
    if (mf (x, "^(?:(?:__asm__|__asm|asm)\\s*\\(\\s*)?\"(\\w+)\"", "")) return g (1);
  }
  return 0;
}
/* the template and the output and input constraints, else 0 */
struct asmt { struct str *t; struct vec *o, *i; };
static struct vec *quoted (struct str *s, int esc)   /* each "..." of s */
{
  struct vec *v = v_new ();
  long i = 0;
  while (i < s->n) {
    if (s->p[i] != '"') { i++; continue; }
    {
      long j = i + 1;
      while (j < s->n && s->p[j] != '"') { if (esc && s->p[j] == '\\' && j + 1 < s->n) j++; j++; }
      if (j >= s->n) break;
      v_push (v, s_sub (s, i + 1, j));
      i = j + 1;
    }
  }
  return v;
}
static struct asmt *asm_text (struct jv *n)
{
  long b = range_begin (n), depth = 0, i;
  int instr = 0, esc = 0;
  struct str *s;
  struct vec *parts;
  struct asmt *a;
  if (b < 0 || !itext_load ()) return 0;
  s = s_sub (itext, b, b + 4000);
  s = ssub (s, "^#.*\\n", "mg", "");
  if (!mf (s, "^\\s*(?:__asm__|__asm|asm)\\s*(?:(?:__volatile__|__volatile|volatile)\\s*)?\\(", "")) return 0;
  s = s_sub (s, rc[1], s->n);
  parts = v_new (); v_push (parts, s_of (""));
  for (i = 0; i < s->n; i++) {
    int c = s->p[i];
    struct str *last = parts->v[parts->n - 1];
    if (instr) { s_chr (last, c); if (esc) esc = 0; else if (c == '\\') esc = 1; else if (c == '"') instr = 0; continue; }
    if (c == '"') instr = 1; else if (c == '(') depth++; else if (c == ')') { if (depth == 0) break; depth--; }
    if (c == ':' && depth == 0) { v_push (parts, s_of ("")); continue; }
    s_chr (last, c);
  }
  a = alloc (sizeof (struct asmt));
  {
    struct vec *q = quoted (parts->v[0], 1);
    a->t = s_of ("");
    for (i = 0; i < q->n; i++) s_app (a->t, q->v[i]);
    a->t = ssub (a->t, "\\\\t", "g", " ");
    a->t = ssub (a->t, "\\\\n", "g", ";");
  }
  a->o = parts->n > 1 ? quoted (parts->v[1], 0) : v_new ();
  a->i = parts->n > 2 ? quoted (parts->v[2], 0) : v_new ();
  return a;
}
static int fp_computes (struct jv *n)
{
  struct str *k = jkind (n), *q = sor (qtype (n));
  struct vec *c;
  long i;
  if (mf (k, "^(?:BinaryOperator|UnaryOperator)$", "") && mf (q, "^(?:float|double|long double|_Float\\d+x?|__float128)$", "")) return 1;
  if (mf (k, "CastExpr$", "") && mf (jsor (n, "castKind"), "Floating", "")) return 1;
  c = jkids (n);
  for (i = 0; i < c->n; i++) if (fp_computes (c->v[i])) return 1;
  return 0;
}
static int asm_barrier (struct jv *n)
{
  struct asmt *a = asm_text (n);
  long i;
  if (!a || mf (a->t, "\\S", "")) return 0;
  if (a->o->n) {
    int ok = 1;
    for (i = 0; i < a->o->n; i++) {
      struct str *c = a->o->v[i];
      if (!mf (c, "\\+", "") || (t_is ("aarch64") ? !mf (c, "^[=+&]*[rxw]+$", "") : !mf (c, "^[=+&]*[rx]+$", ""))) ok = 0;
    }
    if (ok) return 1;
  }
  if (t_is ("x86_64") && !a->o->n) return 1;
  if (t_is ("aarch64") && !a->o->n) {
    struct vec *k = jkids (n);
    long m = 0;
    for (i = 0; i < k->n; i++) if (!mf (jkind (k->v[i]), "Attr$", "")) { m++; if (!s_is (tcls (k->v[i]), "ldouble")) return 0; }
    return m > 0;
  }
  return 0;
}

/* ---- expressions */
static struct str *E (struct jv *n);
static struct vec *S (struct vec *all);
static struct str *call (struct jv *n);
static struct str *atomic (struct jv *n);
static struct str *init (struct jv *n);
static struct str *text_codes (struct jv *n, struct str *s);
static struct str *ET (struct jv *c);
static struct str *S3 (char *a, struct str *b, char *c3, struct str *d, char *e) { struct str *s = cat2 (a, b, c3); s_app (s, d); s_cat (s, e); return s; }
static struct str *seqform (struct vec *i)
{
  struct str *o;
  long k;
  if (i->n == 1) return i->v[0];
  o = s_of ("(seq");
  for (k = 0; k < i->n; k++) { s_chr (o, ' '); s_app (o, i->v[k]); }
  s_chr (o, ')');
  return o;
}
static void seq (struct jv *n, struct vec *o)
{
  struct jv *s = unparen (n);
  if (kind_is (s, "BinaryOperator") && jis (s, "opcode", ",")) { struct vec *k = jkids (s); long i; for (i = 0; i < k->n; i++) seq (k->v[i], o); return; }
  v_push (o, E (n));
}
static struct str *tcls_nofp16 (struct jv *n) { return ssub (tcls (n), "__fp16", "", "_Float16"); }
/* csema's complex arithmetic written back (roundtrip.pl's cxlow): a
   statement expression of locals __cx_N, then C's operator of them.
   Its list (form, op, a, b): n 0 where it is none. */
struct cxr { long n; struct str *form, *op, *a, *b; };
struct cxt { struct jv *init; int real; };
struct cxp { int k, sub; struct str *nm, *op; struct jv *a, *b; };   /* k: z zero, r re, i im, v val, n neg (of sub), b bin */
static struct cxr *cx_none (void) { struct cxr *r = alloc (sizeof (struct cxr)); return r; }
static struct cxr *cx_res (struct str *op, struct str *a, struct str *b)
{
  struct cxr *r = alloc (sizeof (struct cxr));
  r->form = s_of ("("); s_app (r->form, op); s_chr (r->form, ' '); s_app (r->form, a);
  if (b) { s_chr (r->form, ' '); s_app (r->form, b); }
  s_chr (r->form, ')');
  r->op = op; r->a = a; r->b = b; r->n = b ? 4 : 3;
  return r;
}
static struct cxp *cx_new (int k, struct str *nm) { struct cxp *p = alloc (sizeof (struct cxp)); p->k = k; p->nm = nm ? nm : s_of (""); return p; }
static struct cxp *cx_part (struct jv *x, struct hash *t)
{
  struct jv *u = strip (x);
  struct cxt *e;
  if (is_zero (u)) return cx_new ('z', 0);
  if (kind_is (u, "UnaryOperator") && mf (jsor (u, "opcode"), "^__(real|imag)$", "")) {
    int re = s_is (g (1), "real");
    struct jv *r = strip (kid0 (u));
    struct str *nm = kind_is (r, "DeclRefExpr") ? rd_name (r) : s_of ("");
    if ((e = h_pv (t, nm)) && !e->real) return cx_new (re ? 'r' : 'i', nm);
  }
  if (kind_is (u, "DeclRefExpr") && (e = h_pv (t, rd_name (u))) && e->real) return cx_new ('v', rd_name (u));
  if (kind_is (u, "UnaryOperator") && jis (u, "opcode", "-")) {
    struct cxp *q = cx_part (kid0 (u), t);
    if (q && (q->k == 'r' || q->k == 'i')) { struct cxp *p = cx_new ('n', q->nm); p->sub = q->k; return p; }
  }
  if (kind_is (u, "BinaryOperator")) { struct cxp *p = cx_new ('b', 0); p->op = jsor (u, "opcode"); p->a = jkid (u, 0); p->b = jkid (u, 1); return p; }
  return 0;
}
static int cx_is (struct cxp *p, int k, struct str *nm) { return p && p->k == k && (!nm || s_eq (p->nm, nm)); }
static struct str *cx_opnd (struct hash *t, struct str *nm) { struct cxt *e = h_pv (t, nm); return E (e ? e->init : 0); }
static struct cxr *cxlow (struct jv *n)
{
  struct vec *s;
  struct hash *t;
  struct jv *R;
  struct str *ct;
  long i = 0;
  if (!(side_ff && kind_is (n, "StmtExpr"))) return cx_none ();
  s = jkids (kid0 (n));
  if (s->n < 2) return cx_none ();
  t = h_new ();
  while (i < s->n - 1) {
    struct jv *st = s->v[i], *v, *init;
    struct vec *vs;
    struct cxt *e;
    if (!kind_is (st, "DeclStmt")) return cx_none ();
    vs = jkids (st);
    if (!(vs->n == 1 && kind_is (vs->v[0], "VarDecl") && mf (jsor (vs->v[0], "name"), "^__cx_\\d+$", ""))) return cx_none ();
    v = vs->v[0];
    init = first_nonattr (v);
    if (!init) {
      struct jv *as, *l;
      if (!(i + 1 < s->n - 1)) return cx_none ();
      as = unparen (s->v[i + 1]);
      if (!(kind_is (as, "BinaryOperator") && jis (as, "opcode", "="))) return cx_none ();
      l = strip (jkid (as, 0));
      if (!(kind_is (l, "DeclRefExpr") && s_eq (rd_name (l), jsor (v, "name")))) return cx_none ();
      init = jkid (as, 1);
      i++;
    }
    e = alloc (sizeof (struct cxt)); e->init = init; e->real = !mf (tcls (v), "_Complex", "");
    h_setp (t, jsor (v, "name"), e);
    i++;
  }
  ct = tcls (n);
  R = strip (s->v[s->n - 1]);
  if (kind_is (R, "CallExpr")) {
    struct vec *rk = jkids (R), *a = v_new ();
    struct str *fn;
    for (i = 1; i < rk->n; i++) v_push (a, rk->v[i]);
    fn = rd_name (strip (kid0 (R)));
    if (mf (fn, "^__(mul|div)[sdxt]c3$", "") && a->n == 4) {
      struct str *op = s_of (s_is (g (1), "mul") ? "*" : "/"), *o[2];
      struct cxp *p[4];
      long j;
      for (j = 0; j < 4; j++) p[j] = cx_part (a->v[j], t);
      for (j = 0; j < 4; j += 2) {
        if (cx_is (p[j], 'r', 0) && cx_is (p[j + 1], 'i', p[j]->nm)) o[j / 2] = cx_opnd (t, p[j]->nm);
        else if (cx_is (p[j], 'v', 0) && cx_is (p[j + 1], 'z', 0)) o[j / 2] = cx_opnd (t, p[j]->nm);
        else return cx_none ();
      }
      return cx_res (op, o[0], o[1]);
    }
    if (s_is (fn, "__builtin_complex") && a->n == 2) {
      struct cxp *x = cx_part (a->v[0], t), *y = cx_part (a->v[1], t), *l, *r, *yb0 = 0, *yb1 = 0;
      struct str *op;
      int yb;
      if (!(x && y)) return cx_none ();
      if (x->k == 'n' && y->k == 'n' && x->sub == 'r' && y->sub == 'i' && s_eq (x->nm, y->nm)) return cx_res (s_of ("u-"), cx_opnd (t, x->nm), 0);
      if (x->k == 'r' && y->k == 'i' && s_eq (x->nm, y->nm)) {
        struct cxr *c = cx_none ();
        c->n = 1; c->form = s_of ("(cast FloatingComplexCast "); s_app (c->form, ct); s_chr (c->form, ' '); s_app (c->form, cx_opnd (t, x->nm)); s_chr (c->form, ')');
        return c;
      }
      if (!(x->k == 'b' && mf (x->op, "^[-+*/]$", ""))) return cx_none ();
      op = x->op;
      l = cx_part (x->a, t); r = cx_part (x->b, t);
      if (!(l && r)) return cx_none ();
      yb = y->k == 'b' && s_eq (y->op, op);
      if (yb) { yb0 = cx_part (y->a, t); yb1 = cx_part (y->b, t); }
      if (cx_is (l, 'r', 0) && cx_is (r, 'r', 0)) {
        if (mf (op, "^[-+]$", "") && yb && cx_is (yb0, 'i', l->nm) && cx_is (yb1, 'i', r->nm)) return cx_res (op, cx_opnd (t, l->nm), cx_opnd (t, r->nm));
        return cx_none ();
      }
      if (cx_is (l, 'r', 0) && cx_is (r, 'v', 0)) {
        if ((mf (op, "^[-+]$", "") && cx_is (y, 'i', l->nm)) || (mf (op, "^[*/]$", "") && yb && cx_is (yb0, 'i', l->nm) && cx_is (yb1, 'v', r->nm))) return cx_res (op, cx_opnd (t, l->nm), cx_opnd (t, r->nm));
        return cx_none ();
      }
      if (cx_is (l, 'v', 0) && cx_is (r, 'r', 0)) {
        if ((s_is (op, "+") && cx_is (y, 'i', r->nm)) || (s_is (op, "-") && y->k == 'n' && y->sub == 'i' && s_eq (y->nm, r->nm))
            || (s_is (op, "*") && yb && cx_is (yb0, 'v', l->nm) && cx_is (yb1, 'i', r->nm))) return cx_res (op, cx_opnd (t, l->nm), cx_opnd (t, r->nm));
        return cx_none ();
      }
      return cx_none ();
    }
    return cx_none ();
  }
  if (kind_is (R, "BinaryOperator") && mf (jsor (R, "opcode"), "^(&&|\\|\\|)$", "")) {
    struct cxp *x = cx_part (jkid (R, 0), t), *y = cx_part (jkid (R, 1), t), *pa1, *pb1, *pa2, *pb2;
    struct str *op, *an = 0, *bn = 0;
    if (!(x && y && x->k == 'b' && y->k == 'b' && s_eq (x->op, y->op))) return cx_none ();
    op = x->op;
    if (!((s_is (op, "==") && jis (R, "opcode", "&&")) || (s_is (op, "!=") && jis (R, "opcode", "||")))) return cx_none ();
    pa1 = cx_part (x->a, t); pb1 = cx_part (x->b, t); pa2 = cx_part (y->a, t); pb2 = cx_part (y->b, t);
    if (!(pa1 && pb1 && pa2 && pb2)) return cx_none ();
    if (s_is (op, "!=") && cx_is (pa1, 'r', 0) && cx_is (pb1, 'z', 0) && cx_is (pa2, 'i', pa1->nm) && cx_is (pb2, 'z', 0)) {
      struct cxt *e = h_pv (t, pa1->nm);
      struct str *v = E (unimplicit (e->init));
      struct cxr *c = cx_none ();
      c->n = 3; c->form = cat2 ("(tobool ", v, ")"); c->op = s_of ("tobool"); c->a = v;
      return c;
    }
    if (cx_is (pa1, 'r', 0) && cx_is (pa2, 'i', pa1->nm)) an = pa1->nm; else if (cx_is (pa1, 'v', 0) && cx_is (pa2, 'z', 0)) an = pa1->nm;
    if (cx_is (pb1, 'r', 0) && cx_is (pb2, 'i', pb1->nm)) bn = pb1->nm; else if (cx_is (pb1, 'v', 0) && cx_is (pb2, 'z', 0)) bn = pb1->nm;
    if (!(an && bn)) return cx_none ();
    return cx_res (op, cx_opnd (t, an), cx_opnd (t, bn));
  }
  return cx_none ();
}
/* a value tested for truth: csema's test of a complex one by its parts (cxlow's tobool) */
static struct str *ET (struct jv *c)
{
  if (c) { struct cxr *x = cxlow (unparen (strip (c))); if (x->n >= 2 && s_is (x->op, "tobool")) return x->a; }
  return E (c);
}
static struct str *E (struct jv *n)
{
  struct str *k;
  char *sp;
  if (!n || !jstr (n, "kind")) return s_of ("-");
  k = jkind (n);
  if (mf (k, "^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$", "")) return E (kid0 (n));
  /* (in a global's value gcc's infinity or NaN, converted or not, is the literal of its type there) */
  if (in_global && (sp = special_float (n))) { struct str *o = s_of ("(fspecial "); s_cat (o, sp); s_chr (o, ' '); s_app (o, tcls (n)); s_chr (o, ')'); return o; }
  /* (a global's floating constant of long double, as c2ff works it out: FFold's) */
  if (in_global && !t_is ("arm") && mf (k, "^(BinaryOperator|UnaryOperator|CStyleCastExpr|ImplicitCastExpr)$", "") && fty (ftype (n)) && ldinside (n)) {
    struct fv *v = fold (n);
    if (v) return fconst (v, ftype (n));
  }
  if (s_is (k, "ImplicitCastExpr") || s_is (k, "CStyleCastExpr")) {
    struct jv *c = kid0 (n), *rd;
    struct str *ck = jsor (n, "castKind");
    /* (a const integer of a number read in a global's items: the number, as c2ff) */
    if (in_global && s_is (ck, "LValueToRValue") && (rd = rdecl (strip (n)))) {
      struct str *v = h_pv (constid, jsor (rd, "id"));
      if (!v && kind_is (rd, "VarDecl")) {
        struct jv *ty = jget (rd, "type");
        if (ty && mf (sor (jstr (ty, "qualType")), "\\bconst\\b", "")) v = h_pv (constint, jsor (rd, "name"));
      }
      if (v) return cat2 ("(int ", v, " i32)");
    }
    if (mf (ck, "ToBoolean$", "")) return cat2 ("(tobool ", E (unimplicit (c)), ")");
    if (s_is (ck, "FloatingComplexToReal")) return cat2 ("(u__real ", E (c), ")");
    if (s_is (ck, "IntegralCast") && s_is (tcls (n), "u8") && !in_global && kind_is (unparen (c), "IntegerLiteral") && mf (jsor (unparen (c), "value"), "^[01]$", "")) return E (unparen (c));
    if (s_is (ck, "IntegralCast") && s_is (tcls (n), "u8") && (side_ff || s_is (k, "ImplicitCastExpr"))) {
      struct jv *b = unparen (c);
      if (kind_is (b, "BinaryOperator") && jis (b, "opcode", "!=") && is_zero (jkid (b, 1))) return cat2 ("(tobool ", E (unimplicit (jkid (b, 0))), ")");
    }
    /* a null pointer, however its casts go */
    if ((s_is (ck, "BitCast") || s_is (ck, "NullToPointer")) && is_null (n)) return cat2 ("(null ", tcls (n), ")");
    if (mf (ck, "^(LValueToRValue|NoOp|ArrayToPointerDecay|FunctionToPointerDecay|BuiltinFnToFnPtr)$", "")) return E (c);
    if (in_global && s_is (ck, "BitCast") && s_is (k, "ImplicitCastExpr")) {
      struct jv *u = unparen (c);
      if (kind_is (u, "UnaryOperator") && jis (u, "opcode", "&") && mf (tcls (unparen (kid0 (u))), "^arr\\(", "")) return E (c);
    }
    if ((s_is (k, "ImplicitCastExpr") || side_ff) && is_asmfncall (c)) return E (c);
    if (mf (ck, "^(BitCast|IntegralToPointer|PointerToIntegral|IntegralCast|NoOp)$", "") && asm_valued (c)) return E (c);
    if (s_is (ck, "IntegralCast") && is_syscallv (c)) return E (c);
    if (s_is (ck, "IntegralCast") && s_is (tcls (c), "u32") && mf (tcls (n), "^[iu]64$", "")) return E (c);
    if (s_is (ck, "IntegralCast") && mf (tcls (n), "^[iu]32$", "") && small_literal (c)) return E (c);
    if (s_is (ck, "IntegralCast") && mf (tcls (n), "^[iu]32$", "") && kind_is (unparen (c), "TypeTraitExpr")) return E (c);
    if (s_is (ck, "IntegralCast") && small_literal (c) && num_zero (jstr (unparen (c), "value"))) return s_of ("(int 0 i32)");
    if (s_is (ck, "ToVoid") && is_asmfncall (c)) return E (c);
    if (side_ff && is_atomiccall (c)) return E (c);
    if (s_eq (tcls (n), tcls (c)) && !s_is (ck, "ToVoid")) return E (c);
    if (!side_ff && s_is (ck, "IntegralCast") && s_is (tcls (n), "enum") && !mf (tcls (c), "^(enum|i32)$", "")
        && mf (sor (qtype (n)), "^enum \\((?:unnamed|anonymous)\\b", "")) return cat2 ("(cast IntegralCast i32 ", E (c), ")");
    if (s_is (ck, "IntegralCast") && (s_is (tcls (n), "enum") || s_is (tcls (c), "enum"))) return E (c);
    if (s_is (ck, "IntegralCast") && kind_is (unparen (c), "DeclRefExpr") && s_is (rd_kind (unparen (c)), "EnumConstantDecl")) return E (c);
    if (s_is (ck, "PointerToIntegral") && is_offsetof (c)) return s_of ("(offsetof)");
    if (s_is (ck, "FloatingCast") && kind_is (strip (c), "FloatingLiteral")) return cat2 ("(flt ", flt (jsor (strip (c), "value")), ")");
    if (s_is (ck, "FloatingCast") && mf (tcls (n), "__fp16", "")) return E (c);
    { struct str *o = s_of ("(cast "); s_app (o, ck); s_chr (o, ' '); s_app (o, tcls_nofp16 (n)); s_chr (o, ' '); s_app (o, E (c)); s_chr (o, ')'); return o; }
  }
  if (s_is (k, "IntegerLiteral")) {
    struct str *o = s_of ("(int "), *v = jstr (n, "value");
    s_app (o, v ? v : s_of ("0")); s_chr (o, ' '); s_app (o, small_literal (n) ? s_of ("i32") : tcls (n)); s_chr (o, ')');
    return o;
  }
  if (s_is (k, "CXXBoolLiteralExpr")) { struct jv *v = jget (n, "value"); return s_of (v && v->s && v->s->n && !s_is (v->s, "0") ? "(int 1 i32)" : "(int 0 i32)"); }
  if (s_is (k, "TypeTraitExpr")) {
    struct vec *c = jkids (n), *t = v_new ();
    long i;
    for (i = 0; i < c->n; i++) {
      struct str *q = sor (qtype (c->v[i]));
      q = ssub (q, "\\b(const|volatile|restrict)\\b", "g", "");
      q = ssub (q, "\\s+", "g", " ");
      q = ssub (q, "^ | $", "g", "");
      v_push (t, q);
    }
    return S3 ("(int ", s_of (t->n == 2 && ((struct str *) t->v[0])->n && s_eq (t->v[0], t->v[1]) ? "1" : "0"), " ", tcls (n), ")");
  }
  if (s_is (k, "CharacterLiteral")) {
    struct str *v = jsor (n, "value");
    struct jv *ty = jget (n, "type");
    if (ge_2p31 (v) && ty && s_is (sor (jstr (ty, "qualType")), "int")) {
      long x = 0, i;
      for (i = 0; i < v->n; i++) x = x * 10 + (v->p[i] - '0');
      return S3 ("(u- (int ", s_num (4294967296LL - x), " i32))", s_of (""), "");
    }
    return cat2 ("(int ", v, " i32)");
  }
  if (s_is (k, "FloatingLiteral")) {
    struct str *v = jsor (n, "value");
    if (s_is (tcls (n), "ldouble") && t_is ("x86_64") && s_is (ftype (n), "long double")) return cat2 ("(fltl ", ldround (v, 64, -16445, 16383), ")");
    if (s_is (tcls (n), "ldouble") && !t_is ("arm")) return cat2 ("(fltl ", ldround (v, 113, -16494, 16383), ")");
    if (s_is (tcls (n), "ldouble")) return cat2 ("(fltl ", v, ")");
    if (s_is (ftype (n), "float")) { struct fv *f = fold (n); if (f) return fconst (f, s_of ("float")); }
    return cat2 ("(flt ", flt (v), ")");
  }
  if (s_is (k, "StringLiteral")) return cat2 ("(str ", strlit (jsor (n, "value")), ")");
  if (s_is (k, "PredefinedExpr")) return E (kid0 (n));
  if (s_is (k, "DeclRefExpr")) {
    struct jv *rd = rdecl (n);
    if (in_global && s_is (rd_kind (n), "EnumConstantDecl")) { struct str *v = h_pv (enumval, rd_name (n)); if (v) return cat2 ("(int ", v, " i32)"); }
    return cat2 ("(ref ", name_of (rd ? rd : jnull), ")");
  }
  if (s_is (k, "UnaryOperator")) {
    struct jv *c = kid0 (n);
    struct str *op = jsor (n, "opcode");
    if (s_is (op, "+") || s_is (op, "__extension__")) return E (s_is (op, "+") ? unimplicit (c) : c);
    if (s_is (op, "&")) {
      struct str *e = E (c);
      if (mf (e, "^\\(u\\* (.*)\\)$", "s")) { struct str *x = g (1); if (balanced (x)) return x; }
    }
    if (s_is (op, "&") && in_global && mf (tcls (unparen (c)), "^arr\\(", "")) return E (c);
    if (s_is (op, "&") && kind_is (strip (c), "DeclRefExpr") && s_is (rd_kind (strip (c)), "FunctionDecl")) return E (c);
    if (s_is (op, "!")) return cat2 ("(u! ", ET (c), ")");
    { struct str *o = s_of ("(u"); s_app (o, op); { struct jv *pf = jget (n, "isPostfix"); if (pf && pf->t == 't') s_cat (o, "post"); } s_chr (o, ' '); s_app (o, E (c)); s_chr (o, ')'); return o; }
  }
  if (s_is (k, "BinaryOperator") && jis (n, "opcode", ",")) { struct vec *o = v_new (); seq (n, o); return seqform (o); }
  if (s_is (k, "BinaryOperator") || s_is (k, "CompoundAssignOperator")) {
    struct jv *l = jkid (n, 0), *r = jkid (n, 1);
    struct str *op = jsor (n, "opcode"), *o;
    if (side_ff && s_is (op, "=") && is_asmcall (r)) return s_of ("(asm)");
    if (is_asmfncall (unimplicit (l))) r = unimplicit (r);
    if (is_asmfncall (unimplicit (r))) l = unimplicit (l);
    if (s_is (tcls (unimplicit (l)), "enum") || s_is (tcls (unimplicit (r)), "enum")) { l = unimplicit (l); r = unimplicit (r); }
    if (side_ff && s_is (op, "=")) {
      struct cxr *x = cxlow (unparen (r));
      if (x->n > 2) {
        struct str *el = E (l);
        if (mf (x->op, "^[-+*/]$", "") && s_eq (x->a, el)) { struct str *o2 = s_of ("("); s_app (o2, x->op); s_cat (o2, "= "); s_app (o2, el); s_chr (o2, ' '); s_app (o2, x->b ? x->b : s_of ("")); s_chr (o2, ')'); return o2; }
      }
    }
    o = s_of ("("); s_app (o, op); s_chr (o, ' ');
    if (mf (op, "^(&&|\\|\\|)$", "")) { s_app (o, ET (l)); s_chr (o, ' '); s_app (o, ET (r)); }
    else { s_app (o, E (l)); s_chr (o, ' '); s_app (o, E (r)); }
    s_chr (o, ')');
    return o;
  }
  if (s_is (k, "ConditionalOperator")) { struct str *o = s_of ("(?: "); s_app (o, ET (jkid (n, 0))); s_chr (o, ' '); s_app (o, E (jkid (n, 1))); s_chr (o, ' '); s_app (o, E (jkid (n, 2))); s_chr (o, ')'); return o; }
  if (s_is (k, "BinaryConditionalOperator")) { struct str *o = s_of ("(?2 "); s_app (o, E (jkid (n, 0))); s_chr (o, ' '); s_app (o, E (jkid (n, 3))); s_chr (o, ')'); return o; }
  if (s_is (k, "ArraySubscriptExpr")) { struct str *o = s_of ("(u* (+ "); s_app (o, E (jkid (n, 0))); s_chr (o, ' '); s_app (o, E (jkid (n, 1))); s_cat (o, "))"); return o; }
  if (s_is (k, "MemberExpr")) {
    struct str *nm = jsor (n, "name"), *o;
    struct jv *ar = jget (n, "isArrow");
    if (!nm->n) return E (kid0 (n));
    o = s_of ("(mem "); s_cat (o, ar && ar->t == 't' ? "->" : "."); s_app (o, ssub (nm, "'$", "", "")); s_chr (o, ' '); s_app (o, E (kid0 (n))); s_chr (o, ')');
    return o;
  }
  if (s_is (k, "CallExpr") && s_is (rd_name (strip (kid0 (n))), "__builtin_complex") && jkids (n)->n == 3 && is_zero (jkid (n, 2)))
    return S3 ("(cast FloatingRealToComplex ", tcls (n), " ", E (jkid (n, 1)), ")");
  if (s_is (k, "CallExpr")) return call (n);
  if (s_is (k, "AtomicExpr")) return atomic (n);
  if (s_is (k, "OffsetOfExpr")) return s_of ("(offsetof)");
  if (s_is (k, "UnaryExprOrTypeTraitExpr")) {
    struct str *nm = jsor (n, "name"), *w = mf (nm, "align", "i") ? s_of ("alignof") : nm, *t;
    struct jv *at = jget (n, "argType");
    if (at) { struct str *q = jstr (at, "desugaredQualType"); t = tstr (sor (q ? q : jstr (at, "qualType"))); }
    else t = tcls (kid0 (n));
    return S3 ("(", w, " ", t, ")");
  }
  if (s_is (k, "StmtExpr")) {
    struct jv *cs = kid0 (n);
    { struct cxr *x = cxlow (n); if (x->n) return x->form; }
    if (!side_ff) { struct str *s = syscall_idiom (cs); if (s) return s; }
    return seqform (S (jkids (cs)));
  }
  if (s_is (k, "CompoundLiteralExpr")) return S3 ("(clit ", tcls (n), " ", E (kid0 (n)), ")");
  if (s_is (k, "InitListExpr")) return init (n);
  if (s_is (k, "ImplicitValueInitExpr")) return s_of ("(zero)");
  if (s_is (k, "VAArgExpr")) return S3 ("(va_arg ", tcls (n), " ", E (kid0 (n)), ")");
  if (s_is (k, "AddrLabelExpr")) { struct str *l = h_pv (labels, jsor (n, "labelDeclId")); return cat2 ("(addrlabel ", l ? l : s_of ("?"), ")"); }
  if (s_is (k, "GCCAsmStmt")) return s_of ("(asm)");
  return cat2 ("(?", k, ")");
}

static struct vec *vmap_unimplicit (struct vec *a) { struct vec *o = v_new (); long i; for (i = 0; i < a->n; i++) v_push (o, unimplicit (a->v[i])); return o; }
static struct jv *strip_bitcast (struct jv *a)   /* through Implicit and CStyle casts of BitCast or NoOp */
{
  while (a && mf (jkind (a), "^(ImplicitCastExpr|CStyleCastExpr)$", "") && mf (jsor (a, "castKind"), "^(BitCast|NoOp)$", "")) a = kid0 (a);
  return a;
}
static struct str *call (struct jv *n)
{
  struct vec *k = jkids (n), *args = v_new ();
  struct jv *callee = k->n ? k->v[0] : 0, *c, *fa;
  struct str *name = 0, *o;
  long i;
  for (i = 1; i < k->n; i++) v_push (args, k->v[i]);
  c = strip (callee);
  while (c && kind_is (c, "UnaryOperator") && jis (c, "opcode", "*")) c = strip (kid0 (c));
  fa = c ? fnaddr (c) : 0;
  if (fa) c = fa;
  if (c && kind_is (c, "DeclRefExpr") && s_is (rd_kind (c), "FunctionDecl")) name = name_of (rdecl (c));
  if (name) {
    if (!side_ff) {
      if (s_is (name, "__builtin_expect")) return E (args->n ? args->v[0] : 0);
      if (h_has (errordecl, jsor (rdecl (c), "id"))) return s_of ("(cast ToVoid void (int 0 i32))");
      /* __builtin_mempcpy (d, s, n): memcpy (d, s, n) + n */
      if (s_is (jsor (rdecl (c), "name"), "__builtin_mempcpy") && args->n == 3) {
        struct jv *n2 = args->v[2];
        struct str *mc = h_has (asmalias, s_of ("memcpy")) ? h_pv (asmalias, s_of ("memcpy")) : s_of ("memcpy");
        if (kind_is (n2, "ImplicitCastExpr") && jis (n2, "castKind", "IntegralCast")) n2 = kid0 (n2);
        if (asmfn_of (mc)) {
          o = s_of ("(cast BitCast ptr(void) (+ (call "); s_app (o, mc);
          for (i = 0; i < args->n; i++) {
            struct jv *a = args->v[i];
            while (a && mf (jkind (a), "CastExpr$", "") && mf (jsor (a, "castKind"), "^(BitCast|NoOp)$", "")) a = kid0 (a);
            s_chr (o, ' '); s_app (o, E (a));
          }
          s_cat (o, ") "); s_app (o, E (n2)); s_cat (o, "))");
          return o;
        }
        o = s_of ("(cast BitCast ptr(void) (+ (cast BitCast ptr(u8) (call "); s_app (o, mc);
        for (i = 0; i < args->n; i++) { s_chr (o, ' '); s_app (o, E (args->v[i])); }
        s_cat (o, ")) "); s_app (o, E (n2)); s_cat (o, "))");
        return o;
      }
      if (s_is (name, "__builtin_constant_p")) return s_of (mf (jkind (strip (args->n ? args->v[0] : 0)), "^(IntegerLiteral|CharacterLiteral)$", "") ? "(int 1 i32)" : "(int 0 i32)");
    }
    if (s_is (name, "__builtin_va_start")) { struct vec *a = v_new (); if (args->n) v_push (a, args->v[0]); args = a; }
    if (asmfn_of (name)) args = vmap_unimplicit (args);
    if (noproto_of (name)) { struct vec *a = v_new (); for (i = 0; i < args->n; i++) v_push (a, unpromote (args->v[i])); args = a; }
    /* (and ff's x != 0 for it, which a parameter's bool made (tobool x)) */
    if (side_ff && noproto_of (name)) {
      struct vec *a = v_new ();
      for (i = 0; i < args->n; i++) {
        struct jv *b = unparen (args->v[i]);
        if (kind_is (b, "BinaryOperator") && jis (b, "opcode", "!=") && is_zero (jkid (b, 1))) {
          struct jv *x = jv_new ('o'), *in = jv_new ('a');
          x->k = v_new (); x->v = v_new (); in->v = v_new ();
          v_push (in->v, jkid (b, 0));
          v_push (x->k, s_of ("kind")); v_push (x->v, jstrv ("ImplicitCastExpr"));
          v_push (x->k, s_of ("castKind")); v_push (x->v, jstrv ("IntegralToBoolean"));
          v_push (x->k, s_of ("type")); v_push (x->v, jget (b, "type") ? jget (b, "type") : jnull);
          v_push (x->k, s_of ("inner")); v_push (x->v, in);
          v_push (a, x);
        } else v_push (a, args->v[i]);
      }
      args = a;
    }
    if (asmfn_of (name)) { struct vec *a = v_new (); for (i = 0; i < args->n; i++) v_push (a, strip_bitcast (args->v[i])); args = a; }
    if (mf (name, "^_+asm_", "")) return s_of ("(asm)");
    if (side_ff && mf (name, "^__atomic_(\\w+)_\\d+$", "") && h_has (atomicop, g (1))) {
      o = s_of ("(atomic "); s_app (o, g (1));
      for (i = 0; i < args->n; i++) { s_chr (o, ' '); s_app (o, E (strip (args->v[i]))); }
      s_chr (o, ')');
      return o;
    }
    if (s_is (name, "__ff_syscall")) { o = s_of ("(syscall"); for (i = 0; i < args->n; i++) { s_chr (o, ' '); s_app (o, E (strip (args->v[i]))); } s_chr (o, ')'); return o; }
    if (asmfn_of (name)) {
      o = s_of ("(call "); s_app (o, name);
      for (i = 0; i < args->n; i++) {
        struct str *e = E (args->v[i]);
        if (!side_ff && is_mempcpy (args->v[i]) && mf (e, "^\\(cast BitCast ptr\\(void\\) (.*)\\)$", "s")) e = g (1);
        s_chr (o, ' '); s_app (o, e);
      }
      s_chr (o, ')');
      return o;
    }
    o = s_of ("(call "); s_app (o, name);
    for (i = 0; i < args->n; i++) { s_chr (o, ' '); s_app (o, E (args->v[i])); }
    s_chr (o, ')');
    return o;
  }
  o = s_of ("(call* "); s_app (o, E (c));
  for (i = 0; i < args->n; i++) { s_chr (o, ' '); s_app (o, E (args->v[i])); }
  s_chr (o, ')');
  return o;
}
static struct str *atomic (struct jv *n)
{
  struct vec *k = jkids (n), *a = v_new ();
  struct jv *p = jkid (n, 0), *ord = jkid (n, 1);
  struct str *nm = ssub (ssub (jsor (n, "name"), "^__atomic_", "", ""), "_n$", "", ""), *o;
  long i;
  (void) k;
  if (s_is (nm, "load")) { v_push (a, p); v_push (a, ord); }
  else if (s_is (nm, "compare_exchange")) { v_push (a, p); v_push (a, jkid (n, 2)); v_push (a, jkid (n, 4)); v_push (a, ord); v_push (a, jkid (n, 3)); }
  else { v_push (a, p); v_push (a, jkid (n, 2)); v_push (a, ord); }
  o = s_of ("(atomic "); s_app (o, nm);
  for (i = 0; i < a->n; i++) { s_chr (o, ' '); s_app (o, E (strip (a->v[i]))); }
  s_chr (o, ')');
  return o;
}
static int is_zero_form (struct str *e) { return mf (e, "^\\((?:int 0 \\S+|null \\S+|init|zero|cast \\w+ \\S+ \\(int 0 \\S+\\))\\)$", ""); }
static struct str *init (struct jv *n)
{
  struct vec *k = jkids (n), *items = v_new ();
  struct jv *af = jget (n, "array_filler"), *fld;
  int elem;
  long i;
  struct str *o;
  if (!k->n && af && af->t == 'a') { k = v_new (); for (i = 1; i < af->v->n; i++) v_push (k, af->v->v[i]); }
  if (k->n == 1 && mf (tcls (n), "^arr\\(", "") && kind_is (unparen (k->v[0]), "StringLiteral")) return text_codes (n, E (k->v[0]));
  elem = mf (tcls (n), "^arr\\((char|u8|i8),", "");
  for (i = 0; i < k->n; i++) {
    struct jv *u = unparen (k->v[i]);
    struct str *e = kind_is (u, "StringLiteral") ? text_codes (u, E (u)) : E (k->v[i]);
    if (elem) {
      e = ssub (e, "^\\(cast IntegralCast (?:char|u8|i8) \\(int (-?\\d+) i32\\)\\)$", "", "(int $1 char)");
      e = ssub (e, "^\\(int (-?\\d+) (?:u8|i8)\\)$", "", "(int $1 char)");
    }
    v_push (items, is_zero_form (e) ? s_of ("(zero)") : e);
  }
  while (items->n && s_is (items->v[items->n - 1], "(zero)")) items->n--;
  fld = jget (n, "field");
  if (!items->n) return s_of ("(zero)");
  o = s_of ("(init");
  if (fld) { s_cat (o, " ."); s_app (o, jsor (fld, "name")); }
  for (i = 0; i < items->n; i++) { s_chr (o, ' '); s_app (o, items->v[i]); }
  s_chr (o, ')');
  return o;
}
/* a text that sets an array: its codes as the array's items, the zeros at its end the rest */
static struct str *text_codes (struct jv *n, struct str *s)
{
  struct str *w, *codes, *elem, *o;
  struct vec *c;
  long i;
  if (!mf (s, "^\\(str (w?)([-\\d,]*)\\)$", "")) return s;
  w = g0 (1); codes = g0 (2);
  elem = mf (tcls (n), "^arr\\((\\w+),", "") ? g (1) : s_of ("");
  if (!w->n || mf (elem, "^(u8|i8)$", "")) elem = s_of ("char");
  if (mf (elem, "^[iu]32$", "")) elem = s_of ("i32");
  c = ssplit (",", codes, 0);
  while (c->n && num_zero (c->v[c->n - 1])) c->n--;
  if (!c->n) return s_of ("(zero)");
  o = s_of ("(init");
  for (i = 0; i < c->n; i++) {
    struct str *x = c->v[i];
    if (num_zero (x)) s_cat (o, " (zero)");
    else if (s_is (elem, "u16")) { s_cat (o, " (cast IntegralCast u16 (int "); s_app (o, x); s_cat (o, " i32))"); }
    else { s_cat (o, " (int "); s_app (o, x); s_chr (o, ' '); s_app (o, elem); s_chr (o, ')'); }
  }
  s_chr (o, ')');
  return o;
}
static struct str *var_init (struct jv *d)
{
  struct jv *in = first_nonattr (d), *u;
  if (!in) return 0;
  u = unparen (in);
  if (kind_is (u, "StringLiteral") && mf (tcls (d), "^arr\\(", "")) return text_codes (d, E (u));
  return E (in);
}
/* (sizeof (T[n]) / sizeof (T): n) */
static struct str *sizeof_div (struct str *i)
{
  return ssub (i, "\\(/ \\(sizeof arr\\(([^()]*(?:\\([^()]*\\))?[^()]*),(\\d+)\\)\\) \\(sizeof \\1\\)\\)", "g", "(int $2 i32)");
}
static struct str *gnorm (struct jv *d)
{
  struct str *i, *o;
  int was = in_global;
  in_global = 1;
  i = var_init (d);
  if (!i || is_zero_form (i)) i = s_of ("(zero)");
  /* (a constant sum: randtbl's &randtbl[SEP_3 + 1]) */
  for (;;) {
    struct rx *r = rx_get ("\\(\\+ \\(int (\\d+) i32\\) \\(int (\\d+) i32\\)\\)", "");
    struct str *x, *a, *b;
    g_s = i->p;
    if (!rx_exec (r, i->p, i->n, 0)) break;
    a = g (1); b = g (2);
    x = s_sub (i, 0, rc[0]);
    { struct big *sum = b_add (b_from_dec (a), b_from_dec (b)); s_cat (x, "(int "); s_app (x, b_dec (sum)); s_cat (x, " i32)"); }
    s_add (x, i->p + rc[1], i->n - rc[1]);
    i = x;
  }
  i = sizeof_div (i);
  if (mf (i, "^\\(init (.*)\\)$", "s")) { struct str *in = g (1); if (balanced (in) && !mf (tcls (d), "^(?:arr|rec|vla)", "")) i = in; }
  in_global = was;
  o = s_of ("(global "); s_app (o, ssub (tcls (d), "^enum$", "", "i32")); s_chr (o, ' '); s_app (o, i); s_chr (o, ')');
  return o;
}

/* ---- glibc's INTERNAL_SYSCALL as ff's syscall */
static int is_decl_stmt (struct jv *n) { return kind_is (n, "DeclStmt"); }
static struct jv *asm_label_attr (struct jv *v) { struct vec *k = jkids (v); long i; for (i = 0; i < k->n; i++) if (kind_is (k->v[i], "AsmLabelAttr")) return k->v[i]; return 0; }
static struct str *syscall_x86 (struct jv *cs);
static struct str *syscall_arm (struct jv *cs);
/* an argument: the local's value where it is one (_aNtmp, __argN) */
static struct str *sys_arg (struct jv *e, struct hash *l)
{
  struct jv *s = strip (e), *x;
  if (kind_is (s, "DeclRefExpr") && (x = h_pv (l, rd_name (s)))) e = x;
  return E (strip (e));
}
static struct str *syscall_idiom (struct jv *cs)
{
  struct vec *st, *ik;
  struct jv *inner = 0;
  struct hash *reg, *regof, *l;
  struct str *nr, *o;
  char *ar;
  long i, j;
  int has_asm = 0;
  if (t_is ("arm")) return syscall_arm (cs);
  { struct str *x = syscall_x86 (cs); if (x) return x; }
  st = jkids (cs);
  for (i = 0; i < st->n; i++) if (kind_is (st->v[i], "CompoundStmt")) { inner = st->v[i]; break; }
  if (!inner) return 0;
  ik = jkids (inner);
  for (i = 0; i < ik->n; i++) if (kind_is (ik->v[i], "GCCAsmStmt")) has_asm = 1;
  if (!has_asm) return 0;
  reg = h_new (); regof = h_new (); l = h_new ();
  for (i = 0; i < ik->n; i++) {
    struct vec *vs;
    if (!is_decl_stmt (ik->v[i])) continue;
    vs = jkids (ik->v[i]);
    for (j = 0; j < vs->n; j++) {
      struct jv *v = vs->v[j], *lab = asm_label_attr (v), *in = first_nonattr (v);
      struct str *r;
      if (!lab) continue;
      r = jstr (lab, "label");
      if (!r && mf (jsor (v, "name"), "^(?:__(a[0-7])|_(x[0-8]))$", "")) r = gdef (1) ? g (1) : g (2);
      if (!r) continue;
      h_setp (regof, jsor (v, "id"), r);
      if (in) h_setp (reg, r, in);
    }
  }
  for (i = 0; i < ik->n; i++) {
    struct jv *s = ik->v[i], *lh, *rh;
    struct str *r;
    if (!(kind_is (s, "BinaryOperator") && jis (s, "opcode", "="))) continue;
    lh = strip (jkid (s, 0)); rh = jkid (s, 1);
    if (kind_is (lh, "DeclRefExpr") && (r = h_pv (regof, jsor (rdecl (lh), "id"))) && r->n && !h_pv (reg, r)) h_setp (reg, r, rh);
  }
  if (h_pv (reg, s_of ("a7"))) { nr = s_of ("a7"); ar = "a"; }
  else if (h_pv (reg, s_of ("x8"))) { nr = s_of ("x8"); ar = "x"; }
  else return 0;
  {
    struct vec *all = v_new ();
    v_cat (all, st); v_cat (all, ik);
    for (i = 0; i < all->n; i++) {
      struct vec *vs;
      if (!is_decl_stmt (all->v[i])) continue;
      vs = jkids (all->v[i]);
      for (j = 0; j < vs->n; j++) { struct jv *v = vs->v[j], *in = first_nonattr (v); if (in && !h_pv (regof, jsor (v, "id"))) h_setp (l, jsor (v, "name"), in); }
    }
  }
  o = s_of ("(syscall "); s_app (o, E (strip (h_pv (reg, nr))));
  for (i = 0; i <= 5; i++) {
    struct str *rn = s_of (ar);
    struct jv *e;
    s_app (rn, s_num (i));
    e = h_pv (reg, rn);
    if (!e) break;
    s_chr (o, ' '); s_app (o, sys_arg (e, l));
  }
  s_chr (o, ')');
  return o;
}
static struct str *syscall_x86 (struct jv *cs)
{
  struct vec *st = jkids (cs), *ops;
  struct jv *as = 0;
  struct asmt *a;
  struct hash *reg = h_new (), *l = h_new ();
  long i, j, nasm = 0, num = -1, nother = 0;
  static char *regs[] = { "rdi", "rsi", "rdx", "r10", "r8", "r9" };
  struct str *o;
  for (i = 0; i < st->n; i++) if (kind_is (st->v[i], "GCCAsmStmt")) { as = st->v[i]; nasm++; }
  if (nasm != 1) return 0;
  a = asm_text (as);
  if (!(a && mf (a->t, "^\\s*syscall[\\s;]*$", "") && a->o->n == 1 && s_is (a->o->v[0], "=a"))) return 0;
  ops = jkids (as);
  for (i = 0; i < a->i->n; i++) if (s_is (a->i->v[i], "0")) { num = i; break; }
  if (num < 0) return 0;
  {
    struct jv *other = 0;
    for (i = 0; i < st->n; i++) if (!kind_is (st->v[i], "DeclStmt") && !kind_is (st->v[i], "GCCAsmStmt")) { other = st->v[i]; nother++; }
    if (nother > 1) return 0;
    if (nother) {
      struct jv *last = strip (other);
      struct str *id0 = jstr (rdecl (strip (ops->n ? ops->v[0] : 0)), "id");
      if (!(other == st->v[st->n - 1] && kind_is (last, "DeclRefExpr") && s_eq (jsor (rdecl (last), "id"), id0 ? id0 : s_of ("-")))) return 0;
    }
  }
  for (i = 0; i < st->n; i++) {
    struct vec *vs;
    if (!kind_is (st->v[i], "DeclStmt")) continue;
    vs = jkids (st->v[i]);
    for (j = 0; j < vs->n; j++) {
      struct jv *v = vs->v[j], *lab = asm_label_attr (v), *in = first_nonattr (v);
      if (!in) continue;
      if (lab) {
        struct str *r = jstr (lab, "label");
        if (!r && mf (jsor (v, "name"), "^_a([1-6])$", "")) r = s_of (regs[g (1)->p[0] - '1']);
        if (r) h_setp (reg, r, in);
      } else if (jstr (v, "name")) h_setp (l, jstr (v, "name"), in);
    }
  }
  for (j = 0; j < a->i->n; j++) {
    struct str *c = a->i->v[j];
    char *r = s_is (c, "D") ? "rdi" : s_is (c, "S") ? "rsi" : s_is (c, "d") ? "rdx" : 0;
    if (r && !h_pv (reg, s_of (r)) && a->o->n + j < ops->n) h_setp (reg, s_of (r), ops->v[a->o->n + j]);
  }
  o = s_of ("(syscall "); s_app (o, E (strip (a->o->n + num < ops->n ? ops->v[a->o->n + num] : 0)));
  for (i = 0; i < 6; i++) {
    struct jv *e = h_pv (reg, s_of (regs[i]));
    if (!e) break;
    s_chr (o, ' '); s_app (o, sys_arg (e, l));
  }
  s_chr (o, ')');
  return o;
}
static struct str *syscall_arm (struct jv *cs)
{
  struct vec *st = jkids (cs);
  struct jv *as = 0;
  struct asmt *a;
  struct hash *regof = h_new (), *reg = h_new (), *l = h_new ();
  static char *an[] = { "r0", "0", "a1", "0", "r1", "1", "a2", "1", "r2", "2", "a3", "2", "r3", "3", "a4", "3", "r4", "4", "v1", "4", "r5", "5", "v2", "5", "r6", "6", "v3", "6", 0 };
  struct jv *byno[7] = { 0, 0, 0, 0, 0, 0, 0 };
  struct str *o;
  long i, j, nasm = 0;
  for (i = 0; i < st->n; i++) if (kind_is (st->v[i], "GCCAsmStmt")) { as = st->v[i]; nasm++; }
  if (nasm != 1) return 0;
  a = asm_text (as);
  if (!(a && mf (a->t, "^\\s*swi\\s+0x0\\b", "") && a->o->n == 1 && s_is (a->o->v[0], "=r"))) return 0;
  for (i = 0; i < st->n; i++) {
    struct vec *vs;
    if (!kind_is (st->v[i], "DeclStmt")) continue;
    vs = jkids (st->v[i]);
    for (j = 0; j < vs->n; j++) {
      struct jv *v = vs->v[j], *lab = asm_label_attr (v), *in = first_nonattr (v);
      if (lab) { struct str *r = asm_label (lab); if (!r) continue; h_setp (regof, jsor (v, "name"), r); if (in) h_setp (reg, r, in); }
      else if (in && jstr (v, "name")) h_setp (l, jstr (v, "name"), in);
    }
  }
  for (i = 0; i < st->n; i++) {
    struct jv *s = st->v[i], *lh;
    struct str *r;
    if (!(kind_is (s, "BinaryOperator") && jis (s, "opcode", "="))) continue;
    lh = strip (jkid (s, 0));
    if (!(kind_is (lh, "DeclRefExpr") && (r = h_pv (regof, rd_name (lh))))) continue;
    h_setp (reg, r, jkid (s, 1));
  }
  if (!h_pv (reg, s_of ("r7"))) return 0;
  /* (%byno: in the order of %reg's keys, a later register of one number over an earlier) */
  {
    struct vec *ks = reg->keys;
    for (i = 0; i < ks->n; i++) {
      struct hent *e = ks->v[i];
      long q;
      for (q = 0; an[q]; q += 2) if (s_is (e->k, an[q])) byno[an[q + 1][0] - '0'] = e->pv;
    }
  }
  o = s_of ("(syscall "); s_app (o, E (strip (h_pv (reg, s_of ("r7")))));
  for (i = 0; i <= 6; i++) { if (!byno[i]) break; s_chr (o, ' '); s_app (o, sys_arg (byno[i], l)); }
  s_chr (o, ')');
  return o;
}

/* ---- statements: a list of tokens (statements, and { } around a block) */
static struct vec *xstmt (struct jv *n);
static struct jv *x87in (struct jv *a);
static struct vec *brace (struct vec *s);
static struct vec *body (struct jv *b);
static struct str *effect (struct jv *n);
static struct vec *S1 (struct jv *n) { struct vec *v = v_new (); v_push (v, n); return S (v); }
static struct str *jw (char *a, struct vec *tok, char *z)   /* a, the tokens joined by ' ', z */
{
  struct str *o = s_of (a);
  long i;
  for (i = 0; i < tok->n; i++) { if (i || a[0]) s_chr (o, ' '); s_app (o, tok->v[i]); }
  s_cat (o, z);
  return o;
}
static struct vec *S (struct vec *all)
{
  struct vec *out = v_new ();
  long ix, i;
  for (ix = 0; ix < all->n; ix++) {
    struct jv *n = all->v[ix];
    struct str *k;
    if (!n || !jstr (n, "kind")) continue;
    if (n->done) continue;
    k = jkind (n);
    /* (csema's local of a struct, union or complex type whose value would be
       written as a lone : or several items, which after it are its items:
       declared, then assigned it; its complex arithmetic, a statement
       expression, ?: or a comma) */
    if (side_ff && s_is (k, "DeclStmt") && jkids (n)->n == 1 && kind_is (jkid (n, 0), "VarDecl") && !first_nonattr (jkid (n, 0))) {
      struct jv *d = jkid (n, 0), *as = ix < all->n - 1 ? unparen (all->v[ix + 1]) : 0;
      struct str *q = sor (qtype (d)), *dn = jstr (d, "name");
      if (mf (q, "^(?:(?:const |volatile )*(?:struct|union) |.*_Complex)", "") && !mf (q, "[*\\[(]", "") && as && kind_is (as, "BinaryOperator") && jis (as, "opcode", "=")
          && s_eq (rd_name (strip (jkid (as, 0))), dn ? dn : s_of ("-"))) {
        struct jv *r = unparen (jkid (as, 1));
        struct str *rk = jkind (r);
        if (cxlow (r)->n || mf (rk, "^(StmtExpr|ConditionalOperator|BinaryConditionalOperator)$", "") || (s_is (rk, "BinaryOperator") && jis (r, "opcode", ","))) {
          struct str *o = s_of ("(var "); s_app (o, ssub (jsor (d, "name"), "'$", "", "")); s_chr (o, ' '); s_app (o, tcls (d)); s_chr (o, ' '); s_app (o, E (jkid (as, 1))); s_chr (o, ')');
          v_push (out, o);
          ((struct jv *) all->v[ix + 1])->done = 1;
          continue;
        }
      }
    }
    if (s_is (k, "CompoundStmt")) {
      /* (c2ff's x = setjmp (...) through a local of its own, returns twice, is that assignment) */
      struct vec *c = jkids (n);
      struct jv *v = c->n == 2 && kind_is (c->v[0], "DeclStmt") ? jkid (c->v[0], 0) : 0, *as = c->n == 2 ? unparen (c->v[1]) : 0;
      if (side_ff && v && mf (jsor (v, "name"), "^returns_?twice$", "") && kind_is (as, "BinaryOperator") && jis (as, "opcode", "=")) {
        struct jv *init = first_nonattr (v), *rr = strip (jkid (as, 1));
        if (init && kind_is (rr, "DeclRefExpr") && s_eq (rd_name (rr), jsor (v, "name"))) {
          struct str *o = s_of ("(= "); s_app (o, E (jkid (as, 0))); s_chr (o, ' '); s_app (o, E (init)); s_chr (o, ')');
          v_push (out, o);
          continue;
        }
      }
      v_cat (out, brace (S (c)));
      continue;
    }
    /* (csema's local of an x87 asm input that is a value, __x87_1 ..., is that asm statement's operand) */
    if (s_is (k, "DeclStmt") && side_ff && jkids (n)->n) {
      struct vec *ds = jkids (n);
      int all87 = 1;
      for (i = 0; i < ds->n; i++) if (!kind_is (ds->v[i], "VarDecl") || !mf (jsor (ds->v[i], "name"), "^__x87_\\d+$", "")) all87 = 0;
      if (all87) { for (i = 0; i < ds->n; i++) h_setp (x87in_, jsor (ds->v[i], "name"), first_nonattr (ds->v[i])); continue; }
    }
    if (s_is (k, "DeclStmt")) {
      struct vec *ds = jkids (n);
      for (i = 0; i < ds->n; i++) {
        struct jv *d = ds->v[i];
        struct str *in, *o;
        if (!kind_is (d, "VarDecl")) continue;
        if (jis (d, "storageClass", "extern")) continue;
        if (jis (d, "storageClass", "static") && !holds (d, "AddrLabelExpr")) continue;
        in = var_init (d);
        o = s_of ("(var "); s_app (o, ssub (jsor (d, "name"), "'$", "", "")); s_chr (o, ' '); s_app (o, ssub (tcls (d), "^enum$", "", "i32"));
        if (in) { s_chr (o, ' '); s_app (o, in); }
        s_chr (o, ')');
        v_push (out, o);
      }
      continue;
    }
    if (s_is (k, "IfStmt")) {
      struct jv *c = jkid (n, 0), *t = jkid (n, 1), *e = 0, *he = jget (n, "hasElse");
      if (he && he->t == 't') e = jkid (n, 2);
      v_push (out, cat2 ("(if ", ET (c), ""));
      v_cat (out, body (t));
      if (e) { v_push (out, s_of ("else")); v_cat (out, body (e)); }
      v_push (out, s_of (")"));
      continue;
    }
    if (s_is (k, "WhileStmt")) { v_push (out, cat2 ("(while ", ET (jkid (n, 0)), "")); v_cat (out, body (jkid (n, 1))); v_push (out, s_of (")")); continue; }
    if (s_is (k, "DoStmt")) { v_push (out, cat2 ("(do ", ET (jkid (n, 1)), "")); v_cat (out, body (jkid (n, 0))); v_push (out, s_of (")")); continue; }
    if (s_is (k, "ForStmt")) {
      struct jv *in = jkid (n, 0), *c = jkid (n, 2), *s = jkid (n, 3), *b = jkid (n, 4);
      struct str *h;
      if (in && jstr (in, "kind") && kind_is (in, "DeclStmt") && jkids (in)->n > 1) {
        v_push (out, s_of ("{"));
        v_cat (out, S1 (in));
        h = s_of ("(for - "); s_app (h, ET (c)); s_chr (h, ' '); s_app (h, effect (s));
        v_push (out, h); v_cat (out, body (b)); v_push (out, s_of (")")); v_push (out, s_of ("}"));
        continue;
      }
      h = s_of ("(for ");
      if (in && jstr (in, "kind")) { if (kind_is (in, "DeclStmt")) s_app (h, jw ("", S1 (in), "")); else s_app (h, effect (in)); }
      else s_chr (h, '-');
      s_chr (h, ' '); s_app (h, ET (c)); s_chr (h, ' '); s_app (h, effect (s));
      v_push (out, h); v_cat (out, body (b)); v_push (out, s_of (")"));
      continue;
    }
    if (s_is (k, "SwitchStmt")) { v_push (out, cat2 ("(switch ", E (jkid (n, 0)), "")); v_cat (out, body (jkid (n, 1))); v_push (out, s_of (")")); continue; }
    if (s_is (k, "CaseStmt")) {
      struct vec *kk = jkids (n), *es = v_new ();
      struct jv *sub = kk->n ? kk->v[kk->n - 1] : 0;
      for (i = 0; i + 1 < kk->n; i++) v_push (es, E (kk->v[i]));
      { struct str *o = s_of ("(case "); for (i = 0; i < es->n; i++) { if (i) s_chr (o, ' '); s_app (o, es->v[i]); } s_chr (o, ')'); v_push (out, o); }
      if (sub) v_cat (out, S1 (sub));
      continue;
    }
    if (s_is (k, "DefaultStmt")) { v_push (out, s_of ("(default)")); v_cat (out, S (jkids (n))); continue; }
    if (s_is (k, "LabelStmt")) {
      struct str *l = h_pv (labels, jsor (n, "declId"));
      struct vec *kk = jkids (n), *na = v_new ();
      v_push (out, cat2 ("(label ", l ? l : jsor (n, "name"), ")"));
      for (i = 0; i < kk->n; i++) if (!mf (jkind (kk->v[i]), "Attr$", "")) v_push (na, kk->v[i]);
      v_cat (out, S (na));
      continue;
    }
    if (s_is (k, "AttributedStmt")) { struct vec *kk = jkids (n), *na = v_new (); for (i = 0; i < kk->n; i++) if (!mf (jkind (kk->v[i]), "Attr$", "")) v_push (na, kk->v[i]); v_cat (out, S (na)); continue; }
    if (s_is (k, "NullStmt")) continue;
    if (s_is (k, "ReturnStmt")) { v_push (out, jget (n, "inner") ? cat2 ("(return ", E (kid0 (n)), ")") : s_of ("(return)")); continue; }
    if (s_is (k, "BreakStmt")) { v_push (out, s_of ("(break)")); continue; }
    if (s_is (k, "ContinueStmt")) { v_push (out, s_of ("(continue)")); continue; }
    if (s_is (k, "GotoStmt")) { struct str *l = h_pv (labels, jsor (n, "targetLabelDeclId")); v_push (out, cat2 ("(goto ", l ? l : s_of ("?"), ")")); continue; }
    if (s_is (k, "IndirectGotoStmt")) { v_push (out, cat2 ("(goto* ", E (kid0 (n)), ")")); continue; }
    if (s_is (k, "GCCAsmStmt")) {
      if (!side_ff && t_is ("x86_64")) {
        struct asmt *a = asm_text (n);
        if (a && !mf (a->t, "\\S", "") && a->o->n == 1 && mf (a->o->v[0], "^=&?[tx]$", "") && a->i->n == 1 && s_is (a->i->v[0], "0")) {
          struct str *o = s_of ("(= "); s_app (o, E (jkid (n, 0))); s_chr (o, ' '); s_app (o, E (jkid (n, 1))); s_chr (o, ')');
          v_push (out, o);
          continue;
        }
      }
      if (!side_ff && asm_barrier (n)) {
        if (t_is ("x86_64")) {
          struct asmt *a = asm_text (n);
          if (a && !a->o->n) { struct vec *kk = jkids (n); for (i = 0; i < kk->n; i++) if (fp_computes (kk->v[i])) v_push (out, cat2 ("(cast ToVoid void ", E (kk->v[i]), ")")); }
        }
        continue;
      }
      v_push (out, s_of ("(asm)"));
      continue;
    }
    /* (an empty asm of inputs alone, math_force_eval's: csema's call of its
       asm function, _asm___x (v) or of x87 inputs _asm___f_l (&__x87_1),
       is glibc's barrier: what an input computes in floating point) */
    if (side_ff && t_is ("x86_64") && kind_is (unimplicit (n), "CallExpr")) {
      struct jv *c = unimplicit (n), *fd = rdecl (strip (kid0 (c)));
      if (fd && mf (name_of (fd), "^_asm___", "")) {
        struct vec *kk = jkids (c);
        for (i = 1; i < kk->n; i++) {
          struct jv *a = x87in (kk->v[i]);
          if (fp_computes (a)) v_push (out, cat2 ("(cast ToVoid void ", E (a), ")"));
        }
        continue;
      }
    }
    v_cat (out, xstmt (n));
  }
  return out;
}
/* an asm function's argument: the value of csema's x87 local whose address it is */
static struct jv *x87in (struct jv *a)
{
  struct jv *u = unimplicit (a), *r;
  struct hent *e;
  if (!(kind_is (u, "UnaryOperator") && jis (u, "opcode", "&"))) return u;
  r = strip (kid0 (u));
  e = h_find (x87in_, kind_is (r, "DeclRefExpr") ? rd_name (r) : s_of (""));
  return e ? e->pv : u;
}
static struct vec *xstmt (struct jv *n)
{
  struct jv *u = unimplicit (n);
  struct vec *s = v_new ();
  while (kind_is (u, "UnaryOperator") && jis (u, "opcode", "__extension__")) u = unimplicit (kid0 (u));
  if (kind_is (u, "StmtExpr") && !(!side_ff && syscall_idiom (kid0 (u)))) s = S (jkids (kid0 (u)));
  else if (kind_is (u, "BinaryOperator") && jis (u, "opcode", ",")) { struct vec *k = jkids (u); long i; for (i = 0; i < k->n; i++) v_cat (s, xstmt (k->v[i])); }
  else { v_push (s, effect (n)); return s; }
  return brace (s);
}
static struct vec *brace (struct vec *s)
{
  struct vec *o;
  if (s->n == 1 && !mf (s->v[0], "^\\(var ", "")) return s;
  if (s->n && s_is (s->v[0], "{")) {
    long d = 0, i;
    for (i = 0; i < s->n; i++) {
      if (s_is (s->v[i], "{")) d++;
      if (s_is (s->v[i], "}")) d--;
      if (!d && i == s->n - 1) return s;
      if (!d) break;
    }
  }
  o = v_new (); v_push (o, s_of ("{")); v_cat (o, s); v_push (o, s_of ("}"));
  return o;
}
static struct vec *body (struct jv *b)
{
  if (!b || !jstr (b, "kind")) return v_new ();
  return kind_is (b, "CompoundStmt") ? S (jkids (b)) : S1 (b);
}
static struct str *effect (struct jv *n)
{
  struct jv *s;
  if (!n || !jstr (n, "kind")) return s_of ("-");
  s = unparen (n);
  if (kind_is (s, "UnaryOperator") && mf (jsor (s, "opcode"), "^(\\+\\+|--)$", "")) return S3 ("(u", jsor (s, "opcode"), " ", E (kid0 (s)), ")");
  if (kind_is (s, "BinaryOperator") && jis (s, "opcode", ",")) { struct vec *k = jkids (s), *e = v_new (); long i; for (i = 0; i < k->n; i++) v_push (e, effect (k->v[i])); return jw ("(seq", e, ")"); }
  return E (n);
}

/* ---- a function, a global */
static void labels_walk (struct jv *m, long *i)
{
  struct vec *k;
  long j;
  if (kind_is (m, "LabelStmt")) {
    struct str *v = ssub (jsor (m, "name"), "_\\d+$", "", "");
    s_chr (v, '#'); s_app (v, s_num (++*i));
    h_setp (labels, jsor (m, "declId"), v);
  }
  k = jkids (m);
  for (j = 0; j < k->n; j++) labels_walk (k->v[j], i);
}
static void static_walk (struct jv *n, struct hash *cnt)
{
  struct vec *k;
  long j;
  if (kind_is (n, "VarDecl") && jis (n, "storageClass", "static") && jstr (n, "name") && !holds (n, "AddrLabelExpr")) {
    struct str *nm = jstr (n, "name");
    long c = h_iv (cnt, nm) + 1;
    h_set (cnt, nm, c);
    if (c > 1) { struct str *v = s_dup (nm); s_chr (v, '#'); s_app (v, s_num (c)); h_setp (staticid, jsor (n, "id"), v); }
  }
  k = jkids (n);
  for (j = 0; j < k->n; j++) static_walk (k->v[j], cnt);
}
static void const_walk (struct jv *n)
{
  struct vec *k;
  long j;
  if (kind_is (n, "VarDecl") && jis (n, "storageClass", "static") && jget (n, "type") && mf (sor (jstr (jget (n, "type"), "qualType")), "\\bconst\\b", "")) {
    struct jv *i = first_nonattr (n);
    while (i && mf (jkind (i), "^(ImplicitCastExpr|ParenExpr|ConstantExpr)$", "")) i = kid0 (i);
    if (i && kind_is (i, "IntegerLiteral")) h_setp (constid, jsor (n, "id"), jstr (i, "value"));
  }
  k = jkids (n);
  for (j = 0; j < k->n; j++) const_walk (k->v[j]);
}
static void locals_walk (struct jv *n, int types)
{
  struct vec *k;
  long j;
  if (mf (jkind (n), "^(ParmVarDecl|VarDecl)$", "")) {
    if (types) { if (jstr (n, "name") && jget (n, "type")) h_setp (ltype, jstr (n, "name"), jstr (jget (n, "type"), "qualType")); }
    else h_set (locals_, jsor (n, "id"), 1);
  }
  if (types == 2 && kind_is (n, "TypedefDecl")) h_setp (tdef, jsor (n, "name"), jstr (jget (n, "type"), "qualType"));
  k = jkids (n);
  for (j = 0; j < k->n; j++) locals_walk (k->v[j], types);
}
static struct hash *h_copy (struct hash *h)
{
  struct hash *c = h_new ();
  long i;
  for (i = 0; i < h->keys->n; i++) { struct hent *e = h->keys->v[i]; struct hent *x = h_put (c, e->k); x->iv = e->iv; x->pv = e->pv; }
  return c;
}
static struct str *fnorm (struct jv *fn)
{
  struct hash *s_ltype = ltype, *s_labels = labels, *s_static = staticid, *s_tdef = tdef, *s_locals = locals_;
  struct vec *k = jkids (fn), *p = v_new (), *st;
  struct jv *cs = 0;
  struct jv *va;
  struct str *f;
  long i, li = 0;
  ltype = h_new (); locals_walk (fn, 1);
  labels = h_new (); labels_walk (fn, &li);
  if (!side_ff) { struct hash *cnt = h_new (); staticid = h_new (); static_walk (fn, cnt); }
  /* (a typedef in a function) */
  tdef = h_copy (tdef);
  { struct hash *save = ltype; ltype = h_new (); locals_walk (fn, 2); ltype = save; }
  locals_ = h_new (); locals_walk (fn, 0);
  for (i = 0; i < k->n; i++) if (kind_is (k->v[i], "ParmVarDecl")) v_push (p, tcls (k->v[i]));
  for (i = 0; i < k->n; i++) if (kind_is (k->v[i], "CompoundStmt")) { cs = k->v[i]; break; }
  st = S (jkids (cs));
  f = s_of ("(fn "); s_app (f, retcls (fn)); s_cat (f, " (");
  for (i = 0; i < p->n; i++) { if (i) s_chr (f, ' '); s_app (f, p->v[i]); }
  va = jget (fn, "variadic");
  if (va && va->t == 't') s_cat (f, " ...");
  s_chr (f, ')');
  for (i = 0; i < st->n; i++) { s_chr (f, ' '); s_app (f, st->v[i]); }
  s_cat (f, " )");
  /* (a constant as a condition, ff's 1 != 0) */
  f = ssub (f, "\\(!= \\(int (-?\\d+) i32\\) \\(int 0 i32\\)\\)", "g", "(tobool (int $1 i32))");
  ltype = s_ltype; labels = s_labels; staticid = s_static; tdef = s_tdef; locals_ = s_locals;
  return f;
}

/* ---- --check-cache unit.rtn: each normal form the cache keeps made again here, and held against it */
static long ck_same, ck_differ, ck_died, ck_asked;
static void ck_one (struct jv *norms, struct str *key, struct str *got)
{
  struct jv *e = jget (norms, (char *) key->p), *want, *ask;
  long i;
  if (!e) { o_str ("NOKEY "); o_s (key); o_str ("\n"); ck_differ++; return; }
  if (jget (e, "err")) { ck_died++; return; }
  want = jget (e, "norm");
  if (!want || !s_eq (want->s, got)) {
    struct str *w = want ? want->s : s_of ("");
    long at = 0;
    while (at < w->n && at < got->n && w->p[at] == got->p[at]) at++;
    o_str ("DIFFER "); o_s (key); o_str ("\n  perl: "); o_s (s_sub (w, at > 60 ? at - 60 : 0, at + 140)); o_str ("\n  ff:   "); o_s (s_sub (got, at > 60 ? at - 60 : 0, at + 140)); o_str ("\n");
    ck_differ++;
    return;
  }
  ask = jget (e, "asked");
  {
    int ok = ask && ask->t == 'o' && ask->k->n == asked->keys->n;
    for (i = 0; ok && i < ask->k->n; i++) {
      struct hent *x = h_find (asked, ask->k->v[i]);
      struct jv *v = ask->v->v[i];
      if (!x || x->iv != (v->s && v->s->n && !s_is (v->s, "0"))) ok = 0;
    }
    if (!ok) { o_str ("ASKED "); o_s (key); o_str ("\n"); ck_asked++; return; }
  }
  ck_same++;
}
static void check_cache (char *f)
{
  struct jv *c = j_file (f, 0), *t = jget (c, "tables"), *keep = jget (c, "keep"), *norms = jget (c, "norm");
  struct vec *kp = keep ? keep->v : empty_vec;
  struct str *j = jsor (c, "j");
  long i;
  tdef = jhash (jget (t, "tdef")); typeof_ = jhash (jget (t, "typeof")); declty = jhash (jget (t, "declty"));
  enumval = jhash (jget (t, "enumval")); errordecl = jhash (jget (t, "errordecl"));
  ltype = h_new (); orig = h_new (); labels = h_new (); staticid = h_new (); constid = h_new (); locals_ = h_new ();
  asmfn = h_new (); noproto = h_new (); x87in_ = h_new ();
  constint_of (kp);
  unit_i = ssub (j, "\\.json$", "", ".i");
  /* the unit's asm aliases and register variables */
  asmalias = h_new (); regvar = h_new ();
  for (i = 0; i < kp->n; i++) {
    struct jv *d = kp->v[i];
    if (kind_is (d, "FileScopeAsmDecl")) {
      struct str *v = jsor (kid0 (d), "value");
      if (mf (v, "^\"\\s*([.\\w]+)\\s*=\\s*([.\\w]+)\\s*\"$", "")) h_setp (asmalias, g (1), g (2));
    }
    if (kind_is (d, "VarDecl") && jis (d, "storageClass", "register")) {
      struct jv *l = asm_label_attr (d);
      if (l) { struct str *m = jstr (d, "mangledName"); h_setp (regvar, jsor (d, "name"), m ? m : jsor (l, "label")); }
    }
  }
  for (i = 0; i < kp->n; i++) {
    struct jv *d = kp->v[i];
    struct vec *body_k = jkids (d);
    int has = 0;
    long q;
    for (q = 0; q < body_k->n; q++) if (kind_is (body_k->v[q], "CompoundStmt")) has = 1;
    if (kind_is (d, "FunctionDecl") && has) {
      struct vec *qu = v_new ();
      long at = 0;
      asked = h_new ();
      ck_one (norms, cat2 ("f ", jsor (d, "id"), ""), fnorm (d));
      { struct hash *cnt = h_new (); staticid = h_new (); static_walk (d, cnt); }
      constid = h_new (); const_walk (d);
      v_cat (qu, jkids (d));
      while (at < qu->n) {
        struct jv *n = qu->v[at++];
        if (kind_is (n, "VarDecl") && jis (n, "storageClass", "static")) { asked = h_new (); ck_one (norms, cat2 ("s ", jsor (n, "id"), ""), gnorm (n)); }
        v_cat (qu, jkids (n));
      }
      staticid = h_new (); constid = h_new ();
    }
    if (kind_is (d, "VarDecl") && jstr (d, "name") && !jis (d, "storageClass", "extern")) { asked = h_new (); ck_one (norms, cat2 ("g ", jsor (d, "id"), ""), gnorm (d)); }
  }
  o_str ("check-cache: "); o_s (s_num (ck_same)); o_str (" same, "); o_s (s_num (ck_differ)); o_str (" differ, ");
  o_s (s_num (ck_asked)); o_str (" asked otherwise, "); o_s (s_num (ck_died)); o_str (" the Perl's died\n");
  o_flush ();
}
