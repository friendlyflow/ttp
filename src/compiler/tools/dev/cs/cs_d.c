/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cs_d.c (in cs.c): declarations, statements, the dump, the unit */

/* ---- the dump ---- */
/* a line: its kind, then its fields (a space between them; for the tree a tab, each line indented by its depth) */
static void cl_local_name (unsigned char *p, long n);
static void cl_begin (void);
static void cl_run (void);
static void cs_o_str (char *s) { cs_b_str (&T->out, s); }
static void cs_o_sep (void) { cs_b_byte (&T->out, T->tree ? '\t' : ' '); }
static void cs_o_kind (char *s) { long i = 0; if (T->tree) while (i < T->depth) { cs_b_str (&T->out, "  "); i++; } cs_b_str (&T->out, s); }
static void cs_o_f (char *s) { cs_o_sep (); cs_b_str (&T->out, s); }
static void cs_o_ty (struct cs_ty *t) { cs_o_sep (); cs_p_ty (&T->out, t, 0); }
static void cs_o_name (unsigned char *p, long n) { cs_o_sep (); if (p && n) cs_b_bytes (&T->out, p, n); else cs_b_byte (&T->out, '-'); }
static void cs_o_vc (struct cs_ex *e) { cs_o_f (cs_pick (e->lv, "lvalue", "prvalue")); cs_o_str ("\n"); }
static void cs_o_val (long long v, struct cs_ty *t)
{
  cs_o_sep ();
  if (cs_is_int (t) && !cs_is_signed (t)) cs_b_ull (&T->out, (unsigned long long) v); else cs_b_ll (&T->out, v);
}
/* lines made at depth 0, at depth d (a statement expression's) */
static void cs_o_lines (unsigned char *p, long n, long d)
{
  long i = 0;
  while (i < n) {
    long k = 0;
    if (T->tree) while (k < d) { cs_b_str (&T->out, "  "); k++; }
    while (i < n && p[i] != '\n') { cs_b_byte (&T->out, p[i]); i++; }
    cs_b_byte (&T->out, '\n');
    i++;
  }
}
static void cs_dump_ex (struct cs_ex *e)
{
  long i = 0;
  int k = e->k;
  if (!T->dump) return;
  if (k == E_ICE || k == E_CAST) { cs_o_kind (cs_pick (k == E_ICE, "ICE", "CAST")); cs_o_f (ckname[e->op]); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_REF) { cs_o_kind ("REF"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_INT) { cs_o_kind ("INT"); cs_o_val (e->val, e->t); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_CHR) { cs_o_kind ("CHR"); cs_o_sep (); cs_b_ull (&T->out, (unsigned long long) e->val); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_FLT) { cs_o_kind ("FLT"); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_FIX) { cs_o_kind ("FIX"); cs_o_sep (); cs_fix_text (&T->out, (unsigned long long) e->val, cs_fix_scale (e->t)); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_STR) { cs_o_kind ("STR"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_UN) { cs_o_kind ("UN"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_BIN) { cs_o_kind ("BIN"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_CASS) { cs_o_kind ("CASS"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); cs_o_f (cs_pick (e->lv, "lvalue", "prvalue")); cs_o_ty (e->lhsty); cs_o_ty (e->resty); cs_o_str ("\n"); }
  else if (k == E_GENERIC) { cs_o_kind ("GENERIC"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_COND) { cs_o_kind ("COND"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_BCOND) {
    cs_o_kind ("BCOND"); cs_o_ty (e->t); cs_o_vc (e);
    cs_dump_ex (e->kid[0]);
    cs_dump_ex (e->kid[1]);
    cs_dump_ex (e->kid[2]);
    cs_dump_ex (e->kid[3]);
    return;
  }
  else if (k == E_OVE) { cs_o_kind ("OVE"); cs_o_ty (e->t); cs_o_vc (e); return; }
  else if (k == E_CALL) { cs_o_kind ("CALL"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_MEM) { cs_o_kind ("MEM"); cs_o_name (e->name, e->nlen); cs_o_f (cs_pick (e->arrow, "->", ".")); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_IDX) { cs_o_kind ("IDX"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_SIZEOF) { cs_o_kind ("SIZEOF"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); if (e->lhsty) cs_o_ty (e->lhsty); cs_o_str ("\n"); }
  else if (k == E_CONST) {
    long long v = 0;
    cs_o_kind ("CONST");
    if (!e->isnull && cs_eval (e->kid[0], &v)) cs_o_val (cs_wrap (v, e->t), e->t); else cs_o_f ("-");
    cs_o_ty (e->t); cs_o_vc (e);
  }
  else if (k == E_INIT) { cs_o_kind ("INIT"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_IVI) { cs_o_kind ("IVI"); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_CLIT) { cs_o_kind ("CLIT"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_STMTX) { cs_o_kind ("STMTX"); cs_o_ty (e->t); cs_o_vc (e); cs_o_lines (e->text, e->tlen, T->depth + 1); return; }
  else if (k == E_OFFSETOF) { cs_o_kind ("OFFSETOF"); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_VAARG) { cs_o_kind ("VAARG"); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_PREDEF) { cs_o_kind ("PREDEF"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_ADDRLABEL) { cs_o_kind ("ADDRLABEL"); cs_o_ty (e->t); cs_o_str ("\n"); }
  else if (k == E_ATOMIC) { cs_o_kind ("ATOMIC"); cs_o_name (e->name, e->nlen); cs_o_ty (e->t); cs_o_vc (e); }
  else if (k == E_TRAIT) { cs_o_kind ("TRAIT"); cs_o_ty (e->t); cs_o_str ("\n"); }
  T->depth++;
  while (i < e->nk) { cs_dump_ex (e->kid[i]); i++; }
  T->depth--;
}
static void cs_dump_in (struct cs_ex *e) { T->depth++; cs_dump_ex (e); T->depth--; }
static void cs_o_decl (char *k, unsigned char *p, long n, struct cs_ty *t, int sc)
{
  if (!T->dump) return;
  cs_o_kind (k);
  cs_o_name (p, n);
  if (t) cs_o_ty (t);
  if (sc == SC_EXTERN) cs_o_f ("extern");
  else if (sc == SC_STATIC) cs_o_f ("static");
  else if (sc == SC_REGISTER) cs_o_f ("register");
  else if (sc == SC_AUTO) cs_o_f ("auto");
  cs_o_str ("\n");
}
static struct cs_ex *cs_constant (struct cs_ex *x)
{
  struct cs_ex *c = cs_mk1 (E_CONST, x->t, x->lv, x);
  return c;
}

/* ---- attributes ---- */
static int cs_attr_is (struct node *t, char *name)
{
  /* the name with or without its __ on both sides */
  long n = cstrlen (name);
  if (same (t->text, t->len, name)) return 1;
  return t->len == n + 4 && t->text[0] == '_' && t->text[1] == '_' && t->text[t->len - 1] == '_' && t->text[t->len - 2] == '_' && same (t->text + 2, n, name);
}
static struct cs_ty *cs_attr_type (struct node *a, long *i, long end);
static long long cs_attr_expr (struct node *a, long *i, long end);
static long long cs_attr_term (struct node *a, long *i, long end)
{
  struct node *t;
  long long v = 0;
  if (*i >= end) return 0;
  t = a->kids[*i];
  if (cs_is (t, "(")) { (*i)++; v = cs_attr_expr (a, i, end); if (*i < end && cs_is (a->kids[*i], ")")) (*i)++; return v; }
  if (cs_is (t, "sizeof") || cs_is (t, "__alignof__") || cs_is (t, "__alignof") || cs_is (t, "_Alignof") || cs_is (t, "alignof")) {
    int isal = !cs_is (t, "sizeof");
    struct cs_ty *ty;
    (*i)++;
    if (*i < end && cs_is (a->kids[*i], "(")) {
      long depth = 0, j = *i;
      (*i)++;
      ty = cs_attr_type (a, i, end);
      while (j < end) { if (cs_is (a->kids[j], "(")) depth++; if (cs_is (a->kids[j], ")")) { depth--; if (depth == 0) break; } j++; }
      *i = j + 1;
      return isal ? cs_ty_align (ty) : cs_ty_size (ty);
    }
    return 0;
  }
  if (cs_is (t, "-")) { (*i)++; return -cs_attr_term (a, i, end); }
  if (t->len && t->text[0] >= '0' && t->text[0] <= '9') { struct cs_ex *x = cs_num_lit (t); (*i)++; return x->val; }
  if (cs_is_ident (t)) {
    struct cs_decl *d = cs_lookup (t->text, t->len, 0);
    (*i)++;
    if (d && d->k == DK_ENUMC) return d->val;
    return 0;
  }
  (*i)++;
  return 0;
}
static long long cs_attr_expr (struct node *a, long *i, long end)
{
  long long v = cs_attr_term (a, i, end);
  while (*i < end) {
    struct node *o = a->kids[*i];
    if (cs_is (o, "*")) { (*i)++; v = v * cs_attr_term (a, i, end); }
    else if (cs_is (o, "/")) { long long d; (*i)++; d = cs_attr_term (a, i, end); v = d ? v / d : 0; }
    else if (cs_is (o, "+")) { (*i)++; v = v + cs_attr_term (a, i, end); }
    else if (cs_is (o, "-")) { (*i)++; v = v - cs_attr_term (a, i, end); }
    else if (cs_is (o, "<<")) { (*i)++; v = v << cs_attr_term (a, i, end); }
    else break;
  }
  return v;
}
static struct cs_ty *cs_basic_of (int *cnt, int sg, int uns, int lng);
static struct cs_ty *cs_attr_type (struct node *a, long *i, long end)
{
  int cnt[16];
  int sg = 0, uns = 0, lng = 0, k = 0;
  struct cs_ty *t = 0;
  while (k < 16) cnt[k++] = 0;
  while (*i < end && !cs_is (a->kids[*i], ")") && !cs_is (a->kids[*i], "*")) {
    struct node *w = a->kids[*i];
    if (cs_is (w, "struct") || cs_is (w, "union")) {
      struct cs_rec *r;
      (*i)++;
      r = cs_lookup (a->kids[*i]->text, a->kids[*i]->len, 1);
      if (r) { t = cs_ty_new (r->k); t->rec = r; }
    }
    else if (cs_is (w, "unsigned")) uns = 1;
    else if (cs_is (w, "signed") || cs_is (w, "__signed__")) sg = 1;
    else if (cs_is (w, "long")) lng++;
    else if (cs_is (w, "char")) cnt[1] = 1;
    else if (cs_is (w, "short")) cnt[2] = 1;
    else if (cs_is (w, "int")) cnt[3] = 1;
    else if (cs_is (w, "float")) cnt[4] = 1;
    else if (cs_is (w, "double")) cnt[5] = 1;
    else if (cs_is (w, "void")) cnt[6] = 1;
    else if (cs_is (w, "_Bool")) cnt[7] = 1;
    else if (cs_is (w, "__int128")) cnt[8] = 1;
    else if (cs_is (w, "const") || cs_is (w, "volatile")) ;
    else {
      struct cs_decl *d = cs_lookup (w->text, w->len, 0);
      if (d && d->k == DK_TYPEDEF) t = d->t;
    }
    (*i)++;
  }
  if (!t) t = cs_basic_of (cnt, sg, uns, lng);
  while (*i < end && cs_is (a->kids[*i], "*")) { t = cs_ptr_to (t); (*i)++; }
  return t;
}
static int cs_mode_of (struct node *w)
{
  unsigned char *p = w->text;
  long n = w->len;
  if (n >= 4 && p[0] == '_' && p[1] == '_' && p[n - 1] == '_' && p[n - 2] == '_') { p += 2; n -= 4; }
  if (same (p, n, "QI")) return 8;
  if (same (p, n, "HI")) return 16;
  if (same (p, n, "SI")) return 32;
  if (same (p, n, "DI")) return 64;
  if (same (p, n, "TI")) return 128;
  if (same (p, n, "word") || same (p, n, "pointer") || same (p, n, "libgcc_cmp_return") || same (p, n, "libgcc_shift_count") || same (p, n, "unwind_word")) return T->lbytes * 8;
  if (same (p, n, "byte")) return 8;
  if (same (p, n, "BF")) return -17;
  if (same (p, n, "SF")) return -32;
  if (same (p, n, "DF")) return -64;
  if (same (p, n, "TF") || same (p, n, "KF")) return -128;
  if (same (p, n, "XF")) return -80;
  if (same (p, n, "HF")) return -16;
  if (same (p, n, "HC")) return -1016;
  if (same (p, n, "SC")) return -1032;
  if (same (p, n, "DC")) return -1064;
  if (same (p, n, "TC") || same (p, n, "KC")) return -1128;
  if (same (p, n, "XC")) return -1080;
  /* (fixed point's, arm's fixed-bit.c: 1000 + its code; DQ and UDQ, which clang has no type of, long long as clangfix.pl gives c2ff) */
  if (same (p, n, "QQ")) return 1000;
  if (same (p, n, "HQ")) return 1001;
  if (same (p, n, "SQ")) return 1002;
  if (same (p, n, "HA")) return 1003;
  if (same (p, n, "SA")) return 1004;
  if (same (p, n, "DA")) return 1005;
  if (same (p, n, "UQQ")) return 1006;
  if (same (p, n, "UHQ")) return 1007;
  if (same (p, n, "USQ")) return 1008;
  if (same (p, n, "UHA")) return 1009;
  if (same (p, n, "USA")) return 1010;
  if (same (p, n, "UDA")) return 1011;
  if (same (p, n, "DQ")) return 1100;
  if (same (p, n, "UDQ")) return 1101;
  return 0;
}
/* an attribute's argument as text: a name, or its strings without their quotes, joined */
static char *cs_attr_text (struct node *a, long s, long e)
{
  struct cs_buf b;
  cs_b_init (&b);
  while (s < e) {
    struct cs_buf t;
    long i = 0, n;
    /* (a text of several tokens: asm ("" "fopen64"), __REDIRECT's) */
    if (cs_is (a->kids[s], "str")) {
      long m = 0;
      while (m < a->kids[s]->count) {
        i = 0;
        cs_b_init (&t);
        cs_tok_bytes (a->kids[s]->kids[m], &t);
        n = t.n;
        if (n >= 2 && t.p[0] == '"') { i = 1; n = n - 1; }
        while (i < n) { cs_b_byte (&b, t.p[i]); i++; }
        m++;
      }
      s++;
      continue;
    }
    cs_b_init (&t);
    cs_tok_bytes (a->kids[s], &t);
    n = t.n;
    if (n >= 2 && t.p[0] == '"') { i = 1; n = n - 1; }
    while (i < n) { cs_b_byte (&b, t.p[i]); i++; }
    s++;
  }
  cs_b_byte (&b, 0);
  return (char *) b.p;
}
/* an __attribute__ ((...))'s attributes into sp */
static void cs_attrs (struct node *a, struct cs_spec *spc)
{
  long i = 0, n = a->count;
  if (!cs_is (a, "__attribute__")) return;
  while (i < n) {
    struct node *w = a->kids[i];
    long s = i + 1, e = s, depth = 0;
    if (s < n && cs_is (a->kids[s], "(")) {
      e = s;
      while (e < n) { if (cs_is (a->kids[e], "(")) depth++; if (cs_is (a->kids[e], ")")) { depth--; if (depth == 0) break; } e++; }
    } else e = s - 1;
    if (cs_attr_is (w, "aligned")) {
      if (e > s) { long j = s + 1; spc->algn = cs_attr_expr (a, &j, e); } else spc->algn = T->maxalign;
      if (!spc->hasaln || spc->algn > spc->alnmax) spc->alnmax = spc->algn;
      spc->hasaln = 1;
    }
    else if (cs_attr_is (w, "weak")) spc->weak = 1;
    else if (cs_attr_is (w, "pcs")) spc->pcs = 1;
    else if (cs_attr_is (w, "error")) spc->err = 1;
    else if (cs_attr_is (w, "alias") && e > s) spc->aliasee = cs_attr_text (a, s + 1, e);
    else if (cs_attr_is (w, "ifunc") && e > s) spc->ifunc = cs_attr_text (a, s + 1, e);
    else if (cs_attr_is (w, "section") && e > s) spc->section = cs_attr_text (a, s + 1, e);
    else if (cs_attr_is (w, "cleanup") && e > s) spc->cleanup = cs_attr_text (a, s + 1, e);
    else if (cs_attr_is (w, "constructor") || cs_attr_is (w, "destructor")) {
      spc->ctor = cs_attr_is (w, "constructor") ? 1 : 2;
      spc->ctorprio = -1;
      if (e > s) { long j = s + 1; spc->ctorprio = cs_attr_expr (a, &j, e); }
    }
    else if (cs_attr_is (w, "packed")) spc->packed = 1;
    else if (cs_attr_is (w, "noreturn")) spc->noret = 1;
    else if (cs_attr_is (w, "transparent_union")) spc->transparent = 1;
    else if (cs_attr_is (w, "mode") && e > s) spc->mode = cs_mode_of (a->kids[s + 1]);
    else if (cs_attr_is (w, "vector_size") && e > s) { long j = s + 1; spc->vec = cs_attr_expr (a, &j, e); }
    else if (cs_attr_is (w, "overloadable")) spc->thr |= 2;
    i = e + 1;
    while (i < n && cs_is (a->kids[i], ",")) i++;
  }
}

/* ---- specifiers ---- */
static struct cs_ty *cs_type_of_specs (struct node *s, struct cs_spec *spc);
static struct cs_ty *cs_declarator (struct node *d, struct cs_ty *t, struct cs_dinfo *dinf, struct cs_spec *spc);
static void cs_declare (struct cs_spec *spc, struct node *id, int where);
static void cs_layout_and_dump (struct cs_rec *r);
static struct cs_ty *cs_basic_of (int *cnt, int sg, int uns, int lng)
{
  /* cnt: 1 char 2 short 3 int 4 float 5 double 6 void 7 bool 8 int128 9 complex 10 _Fract 11 _Accum 12 _Sat */
  struct cs_ty *t;
  int k;
  if (cnt[6]) return cs_basic (TY_VOID);
  if (cnt[10] || cnt[11]) {
    int s = 1;
    if (cnt[2]) s = 0;
    if (lng) s = 2;
    return cs_fix_ty (s + 3 * cnt[11] + 6 * uns + 12 * cnt[12]);
  }
  if (cnt[7]) return cs_basic (TY_BOOL);
  if (cnt[1]) k = uns ? TY_UCHAR : sg ? TY_SCHAR : TY_CHAR;
  else if (cnt[2]) k = uns ? TY_USHORT : TY_SHORT;
  else if (cnt[8]) k = uns ? TY_UINT128 : TY_INT128;
  else if (cnt[4]) k = TY_FLOAT;
  else if (cnt[5]) k = lng ? TY_LDOUBLE : TY_DOUBLE;
  else if (lng >= 2) k = uns ? TY_ULLONG : TY_LLONG;
  else if (lng == 1) k = uns ? TY_ULONG : TY_LONG;
  else k = uns ? TY_UINT : TY_INT;
  t = cs_basic (k);
  if (cnt[9]) { struct cs_ty *c = cs_ty_new (TY_COMPLEX); c->to = (cnt[4] || cnt[5]) ? t : (cnt[1] || cnt[2] || cnt[3] || lng || uns || sg || cnt[8]) ? t : cs_basic (TY_DOUBLE); t = c; }
  return t;
}
static struct cs_ty *cs_mode_type (struct cs_ty *t, int m)
{
  int uns = cs_is_int (t) && !cs_is_signed (t);
  if (m == 1100) return cs_basic (TY_LLONG);
  if (m == 1101) return cs_basic (TY_ULLONG);
  if (m >= 1000) return cs_fix_ty (m - 1000);
  if (m > 0) {
    if (m == 8) return cs_basic (uns ? TY_UCHAR : TY_SCHAR);
    if (m == 16) return cs_basic (uns ? TY_USHORT : TY_SHORT);
    if (m == 32) return cs_basic (uns ? TY_UINT : TY_INT);
    if (m == 64) return cs_basic (T->lbytes == 8 ? (uns ? TY_ULONG : TY_LONG) : (uns ? TY_ULLONG : TY_LLONG));
    if (m == 128) return cs_basic (uns ? TY_UINT128 : TY_INT128);
  } else {
    int c = m < 0 - 1000, b = 0 - m;
    if (c) b = 0 - m - 1000;
    struct cs_ty *r = b == 32 ? cs_basic (TY_FLOAT) : b == 64 ? cs_basic (TY_DOUBLE) : b == 16 ? cs_basic (TY_FLOAT16) : b == 17 ? cs_basic (TY_BF16)
      : b == 80 ? cs_basic (TY_LDOUBLE) : T->target == 1 ? cs_basic (TY_FLOAT128) : cs_basic (TY_LDOUBLE);
    if (c) { struct cs_ty *x = cs_ty_new (TY_COMPLEX); x->to = r; return x; }
    return r;
  }
  return t;
}
static struct cs_ty *cs_rec_spec (struct node *n, struct cs_spec *spc, int alone);
static struct cs_ty *cs_enum_spec (struct node *n, struct cs_spec *spc, int alone);
static struct cs_ty *cs_type_of_specs (struct node *s, struct cs_spec *spc)
{
  int cnt[16], sg = 0, uns = 0, lng = 0, q = 0, isatomic = 0, k = 0, alone = 0;
  long i = 0;
  struct cs_ty *t = 0;
  while (k < 16) cnt[k++] = 0;
  spc->t = 0; spc->sc = SC_NONE; spc->istypedef = 0; spc->inl = 0; spc->noret = 0; spc->algn = 0; spc->mode = 0;
  spc->vec = 0; spc->packed = 0; spc->transparent = 0; spc->thr = 0; spc->defined_rec = 0; spc->autotype = 0;
  spc->alnmax = 0; spc->hasaln = 0; spc->weak = 0; spc->ctor = 0; spc->err = 0; spc->ctorprio = -1; spc->pcs = 0;
  spc->aliasee = 0; spc->ifunc = 0; spc->section = 0; spc->cleanup = 0; spc->asmlabel = 0;
  alone = T->alone;
  T->alone = 0;
  while (i < s->count) {
    struct node *w = s->kids[i];
    if (w->count == 0) {
      unsigned char *p = w->text;
      long n = w->len;
      if (same (p, n, "typedef")) spc->istypedef = 1;
      else if (same (p, n, "extern")) spc->sc = SC_EXTERN;
      else if (same (p, n, "static")) spc->sc = SC_STATIC;
      else if (same (p, n, "auto")) spc->sc = SC_AUTO;
      else if (same (p, n, "register")) spc->sc = SC_REGISTER;
      else if (same (p, n, "__thread") || same (p, n, "_Thread_local") || same (p, n, "thread_local")) spc->thr |= 1;
      else if (same (p, n, "inline") || same (p, n, "__inline") || same (p, n, "__inline__")) spc->inl = 1;
      else if (same (p, n, "_Noreturn")) ;
      else if (same (p, n, "const") || same (p, n, "__const") || same (p, n, "__const__")) q |= Q_CONST;
      else if (same (p, n, "volatile") || same (p, n, "__volatile") || same (p, n, "__volatile__")) q |= Q_VOLATILE;
      else if (same (p, n, "restrict") || same (p, n, "__restrict") || same (p, n, "__restrict__")) q |= Q_RESTRICT;
      else if (same (p, n, "_Atomic")) isatomic = 1;
      else if (same (p, n, "__seg_fs")) q |= Q_FS;
      else if (same (p, n, "__seg_gs")) q |= Q_GS;
      else if (same (p, n, "__extension__") || same (p, n, "constexpr")) ;
      else if (same (p, n, "void")) cnt[6] = 1;
      else if (same (p, n, "char")) cnt[1] = 1;
      else if (same (p, n, "short")) cnt[2] = 1;
      else if (same (p, n, "int")) cnt[3] = 1;
      else if (same (p, n, "long")) lng++;
      else if (same (p, n, "float")) cnt[4] = 1;
      else if (same (p, n, "double")) cnt[5] = 1;
      else if (same (p, n, "signed") || same (p, n, "__signed") || same (p, n, "__signed__")) sg = 1;
      else if (same (p, n, "unsigned")) uns = 1;
      else if (same (p, n, "_Bool") || same (p, n, "bool")) cnt[7] = 1;
      else if (same (p, n, "__int128")) cnt[8] = 1;
      else if (same (p, n, "_Complex") || same (p, n, "__complex") || same (p, n, "__complex__")) cnt[9] = 1;
      else if (same (p, n, "_Float16")) t = cs_basic (TY_FLOAT16);
      else if (same (p, n, "_Float32")) t = cs_basic (TY_FLOAT);
      else if (same (p, n, "_Float64") || same (p, n, "_Float32x")) t = cs_basic (TY_DOUBLE);
      else if (same (p, n, "_Float64x")) t = cs_basic (TY_LDOUBLE);
      else if (same (p, n, "_Float128")) t = cs_basic (T->target == 1 ? TY_FLOAT128 : TY_LDOUBLE);
      else if (same (p, n, "__float128")) t = cs_basic (TY_FLOAT128);
      else if (same (p, n, "__float80")) t = cs_basic (TY_LDOUBLE);
      else if (same (p, n, "__ibm128")) t = cs_basic (TY_IBM128);
      else if (same (p, n, "__fp16")) t = cs_basic (TY_HALF);
      else if (same (p, n, "__bf16")) t = cs_basic (TY_BF16);
      else if (same (p, n, "_Fract")) cnt[10] = 1;
      else if (same (p, n, "_Accum")) cnt[11] = 1;
      else if (same (p, n, "_Sat")) cnt[12] = 1;
      else if (same (p, n, "__auto_type")) spc->autotype = 1;
      else {
        struct cs_decl *d = cs_lookup (p, n, 0);
        struct cs_ty *sugt;
        if (!d || d->k != DK_TYPEDEF) cs_fail ("an unknown type name", w);
        sugt = cs_ty_new (TY_TYPEDEF);
        sugt->name = d->name;
        sugt->nlen = d->nlen;
        sugt->to = d->t;
        sugt->algn = d->algn;
        t = sugt;
      }
    } else if (cs_is (w, "struct") || cs_is (w, "union")) { t = cs_rec_spec (w, spc, alone); }
    else if (cs_is (w, "enum")) t = cs_enum_spec (w, spc, alone);
    else if (cs_is (w, "__attribute__")) cs_attrs (w, spc);
    else if (cs_is (w, "[[]]")) ;
    else if (cs_is (w, "typeof") || cs_is (w, "__typeof") || cs_is (w, "__typeof__") || cs_is (w, "typeof_unqual") || cs_is (w, "__typeof_unqual__")) {
      struct node *kid = w->kids[0];
      struct cs_ty *x, *sugt;
      if (cs_is (kid, "type")) x = cs_type_of_name (kid);
      else { struct cs_ex *e = cs_ex_of (kid); x = e->t; if (e->k == E_REF && e->d && e->d->k == DK_FUNC && e->d->builtin) x = e->d->t; }
      if (w->text[w->len - 1] == 'l' || w->text[w->len - 3] == 'q') x = cs_unqual (x);
      sugt = cs_ty_new (TY_TYPEOF);
      sugt->to = x;
      t = sugt;
    }
    else if (cs_is (w, "_Alignas") || cs_is (w, "alignas")) {
      struct node *kid = w->kids[0];
      if (cs_is (kid, "type")) spc->algn = cs_ty_align (cs_type_of_name (kid));
      else { long long v = 0; cs_eval (cs_ex_of (kid), &v); spc->algn = v; }
      {
        /* (T3c: as c2ff.pl reads a type's from the text: nothing but spaces before its parenthesis, none in it; else the largest) */
        long long v = spc->algn;
        if (cs_is (kid, "type")) {
          unsigned char *p = w->text + w->len;
          while (*p == ' ' || *p == '\t' || *p == '\n') p++;
          if (*p != '(') v = T->maxalign;
          else { p++; while (*p && *p != '(' && *p != ')') p++; if (*p != ')') v = T->maxalign; }
        }
        if (!spc->hasaln || v > spc->alnmax) spc->alnmax = v;
      }
      spc->hasaln = 1;
    }
    else if (cs_is (w, "_BitInt")) { long long v = 0; cs_eval (cs_ex_of (w->kids[0]), &v); t = cs_ty_new (uns ? TY_UBITINT : TY_BITINT); t->n = v; }
    else if (cs_is (w, "_Atomic")) { struct cs_ty *x = cs_ty_new (TY_ATOMIC); x->to = cs_type_of_name (w->kids[0]); t = x; }
    i++;
  }
  (void) alone;
  if (!t) t = cs_basic_of (cnt, sg, uns, lng);
  else if (cnt[9] && cs_is_flt (t)) { struct cs_ty *c = cs_ty_new (TY_COMPLEX); c->to = t; t = c; }
  if (isatomic) { struct cs_ty *x = cs_ty_new (TY_ATOMIC); x->to = t; t = x; }
  t = cs_qual (t, q);
  spc->t = t;
  return t;
}
static struct cs_rec *cs_new_rec (int k, struct node *tag, struct node *where)
{
  struct cs_rec *r = alloc (sizeof (struct cs_rec));
  struct cs_buf b;
  r->k = k;
  if (tag) { r->tag = tag->text; r->tlen = tag->len; }
  else {
    cs_b_init (&b);
    cs_b_str (&b, "(anon at ");
    cs_place (&b, where->text);
    cs_b_byte (&b, ')');
    r->loc = b.p;
    r->llen = b.n;
  }
  return r;
}
static struct cs_ty *cs_rec_ty (struct cs_rec *r) { struct cs_ty *t = cs_ty_new (r->k); t->rec = r; return t; }
static void cs_member_decl (struct node *m, struct cs_rec *r);
/* (T3c) a record's or enum's definition: in the unit's list, its record's or function's, or the unit's declarations */
static void cs_top_add (int k, struct cs_decl *d, struct cs_rec *r, struct node *src, int ext)
{
  struct cs_top *t = alloc (sizeof (struct cs_top));
  t->k = k;
  t->d = d;
  t->r = r;
  t->src = src;
  t->specs = T->cur_specs;
  if (ext) { if (T->extlast) T->extlast->nxt = t; else T->ext1 = t; T->extlast = t; }
  else { if (T->toplast) T->toplast->nxt = t; else T->top1 = t; T->toplast = t; }
}
static void cs_inner_add (struct cs_rec *r, struct cs_rec *in, struct cs_field *f)
{
  struct cs_inner *i = alloc (sizeof (struct cs_inner));
  i->r = in;
  i->f = f;
  if (r->in_last) r->in_last->nxt = i; else r->in_first = i;
  r->in_last = i;
}
static void cs_note_rec (struct cs_rec *r)
{
  if (T->allreclast) T->allreclast->allnext = r; else T->allrec1 = r;
  T->allreclast = r;
  if (T->currec) cs_inner_add (T->currec, r, 0);
  if (T->fn) {
    struct cs_decl *f = T->fn;
    r->infn = f;
    if (f->ntags == f->roomtags) {
      long m = f->roomtags * 2 + 8, i = 0;
      struct cs_rec **a = alloc (m * sizeof (struct cs_rec *));
      while (i < f->ntags) { a[i] = f->tags[i]; i++; }
      f->tags = a;
      f->roomtags = m;
    }
    f->tags[f->ntags] = r;
    f->ntags = f->ntags + 1;
  } else if (!T->currec && !T->exdepth && !T->builtins && T->keep) cs_top_add (r->k == TY_ENUM ? TOP_ENUM : TOP_REC, 0, r, 0, 0);
}
static struct cs_ty *cs_rec_spec (struct node *n, struct cs_spec *spc, int alone)
{
  int k = cs_is (n, "struct") ? TY_STRUCT : TY_UNION;
  struct node *tag = 0, *body = 0;
  struct cs_rec *r = 0;
  struct cs_spec ratt;
  long i = 0;
  ratt.algn = 0; ratt.packed = 0; ratt.transparent = 0; ratt.noret = 0; ratt.mode = 0; ratt.vec = 0; ratt.thr = 0;
  ratt.alnmax = 0; ratt.hasaln = 0; ratt.weak = 0; ratt.ctor = 0; ratt.err = 0; ratt.aliasee = 0; ratt.ifunc = 0; ratt.section = 0; ratt.cleanup = 0; ratt.asmlabel = 0;
  while (i < n->count) {
    struct node *w = n->kids[i];
    if (cs_is (w, "{")) body = w;
    else if (cs_is (w, "__attribute__")) cs_attrs (w, &ratt);
    else if (w->count == 0 && !cs_is (w, "[[]]")) tag = w;
    i++;
  }
  if (tag) {
    struct cs_bind *b = cs_lookup_b (tag->text, tag->len, 1);
    if (body || alone) { if (b && b->level == T->level) r = b->v; }
    else if (b) r = b->v;
    if (!r) { r = cs_new_rec (k, tag, n); cs_bind (tag->text, tag->len, 1, r); }
  } else r = cs_new_rec (k, 0, n);
  if (body) {
    if (T->dump && !(T->exdepth && T->fn && !T->inenum)) { cs_o_kind ("record"); cs_o_f (cs_pick (k == TY_STRUCT, "struct", "union")); cs_o_name (r->tag, r->tlen); cs_o_str ("\n"); }
    cs_note_rec (r);
    r->dtext = n->text;
    r->dlen = T->src + c_off_of (n) - 1 - n->text;
    {
      struct cs_rec *outer = T->currec;
      T->currec = r;
      i = 0;
      while (i < body->count) { cs_member_decl (body->kids[i], r); i++; }
      T->currec = outer;
    }
    r->complete = 1;
    r->alnmax = ratt.alnmax;
    r->hasaln = ratt.hasaln;
    if (ratt.algn) r->algn = ratt.algn;
    if (ratt.packed) r->packed = 1;
    if (ratt.transparent) r->transparent = 1;
    if (!tag) spc->defined_rec = 1;
    cs_layout_and_dump (r);
  } else {
    if (ratt.algn && !r->complete) r->algn = ratt.algn;
    /* (an attribute after a tag without a body is the declaration's) */
    if (ratt.weak) spc->weak = 1;
  }
  return cs_rec_ty (r);
}
static void cs_layout_and_dump (struct cs_rec *r)
{
  /* laid out at the end, when a typedef may have named it */
  if (T->nrecs == T->roomrecs) {
    long m = T->roomrecs * 2 + 64, i = 0;
    struct cs_rec **a = alloc (m * sizeof (struct cs_rec *));
    while (i < T->nrecs) { a[i] = T->recs[i]; i++; }
    T->recs = a;
    T->roomrecs = m;
  }
  if (T->dump) T->recs[T->nrecs++] = r;
}
static void cs_member_decl (struct node *m, struct cs_rec *r)
{
  struct cs_spec spc;
  long i = 1;
  if (cs_is (m, "__extension__")) { cs_member_decl (m->kids[0], r); return; }
  if (cs_is (m, "_Static_assert") || cs_is (m, "directive") || cs_is (m, ";")) {
    if (cs_is (m, "_Static_assert")) { struct cs_ex *c = cs_rv (cs_ex_of (m->kids[0])); int k = cs_scalar_kind (&c, cs_basic (TY_BOOL)); c = cs_ice (c, cs_basic (TY_BOOL), k); if (T->dump && !(T->exdepth && T->fn && !T->inenum)) { cs_o_kind ("static_assert"); cs_o_str ("\n"); cs_dump_in (c); } }
    return;
  }
  if (!cs_is (m, "decl")) cs_fail ("a member csema does not know", m);
  cs_type_of_specs (m->kids[0], &spc);
  if (m->count == 1) {
    /* an anonymous struct or union member */
    struct cs_field *f = alloc (sizeof (struct cs_field));
    f->t = spc.t;
    f->width = -1;
    f->anon = 1;
    if (r->last) r->last->nxt = f; else r->first = f;
    r->last = f;
    cs_inner_add (r, 0, f);
    return;
  }
  while (i < m->count) {
    struct node *id = m->kids[i];
    struct cs_dinfo dinf;
    struct cs_spec fa;
    struct cs_field *f = alloc (sizeof (struct cs_field));
    struct cs_ex *w = 0;
    long j = 1;
    dinf.name = 0; dinf.nlen = 0; dinf.ps = 0; dinf.np = 0; dinf.fn = 0; dinf.kr = 0;
    fa = spc;
    fa.algn = 0; fa.packed = 0;
    while (j < id->count) { if (cs_is (id->kids[j], "__attribute__")) cs_attrs (id->kids[j], &fa); j++; }
    if (spc.algn) fa.algn = spc.algn;
    if (spc.packed) fa.packed = 1;
    f->t = cs_declarator (id->kids[0], spc.t, &dinf, &fa);
    if (fa.mode) f->t = cs_mode_type (f->t, fa.mode);
    if (fa.vec) { struct cs_ty *v = cs_ty_new (TY_VECTOR); v->to = f->t; v->n = fa.vec; f->t = v; }
    f->name = dinf.name;
    f->nlen = dinf.nlen;
    f->width = -1;
    f->algn = fa.algn;
    f->packed = fa.packed;
    f->alnmax = fa.alnmax;
    f->hasaln = fa.hasaln;
    j = 1;
    while (j < id->count) {
      if (cs_is (id->kids[j], ":")) { long long v = 0; w = cs_constant (cs_lval_conv (cs_ex_of (id->kids[j]->kids[0]))); cs_eval (w, &v); f->width = v; }
      j++;
    }
    if (r->last) r->last->nxt = f; else r->first = f;
    r->last = f;
    cs_inner_add (r, 0, f);
    if (T->dump && !(T->exdepth && T->fn && !T->inenum)) { cs_o_kind ("field"); cs_o_name (f->name, f->nlen); cs_o_ty (f->t); if (f->width >= 0) cs_o_f ("bits"); cs_o_str ("\n"); if (w) cs_dump_in (w); }
    i++;
  }
}
static struct cs_ty *cs_enum_spec (struct node *n, struct cs_spec *spc, int alone)
{
  struct node *tag = 0, *body = 0;
  struct cs_rec *r = 0;
  long i = 0;
  while (i < n->count) {
    struct node *w = n->kids[i];
    if (cs_is (w, "{")) body = w;
    else if (w->count == 0) tag = w;
    i++;
  }
  /* (an attribute after a tag without a body is the declaration's) */
  if (!body) {
    i = 0;
    while (i < n->count) { if (cs_is (n->kids[i], "__attribute__")) cs_attrs (n->kids[i], spc); i++; }
  }
  if (tag) {
    struct cs_bind *b = cs_lookup_b (tag->text, tag->len, 1);
    if (body || alone) { if (b && b->level == T->level) r = b->v; }
    else if (b) r = b->v;
    if (!r) { r = cs_new_rec (TY_ENUM, tag, n); cs_bind (tag->text, tag->len, 1, r); }
  } else r = cs_new_rec (TY_ENUM, 0, n);
  if (body) {
    long ne = body->count, j = 0;
    struct cs_decl **enums = alloc ((ne + 1) * sizeof (struct cs_decl *));
    struct cs_ex **inits = alloc ((ne + 1) * sizeof (struct cs_ex *));
    struct cs_decl *last = 0;
    long long negbits = 0, posbits = 0;
    int allint;
    struct cs_ty *best, *promo;
    if (T->dump && !(T->exdepth && T->fn && !T->inenum)) { cs_o_kind ("enum"); cs_o_name (r->tag, r->tlen); cs_o_str ("\n"); }
    cs_note_rec (r);
    r->enums = enums;
    r->nenums = ne;
    while (j < ne) {
      struct node *en = body->kids[j];
      struct node *nm = en->kids[0];
      struct cs_decl *d = alloc (sizeof (struct cs_decl));
      long a = 1;
      d->k = DK_ENUMC;
      d->name = nm->text;
      d->nlen = nm->len;
      inits[j] = 0;
      while (a < en->count) {
        if (cs_is (en->kids[a], "=")) {
          struct cs_ex *x;
          /* (a record an enumerator's value defines is the enum's, dumped there) */
          T->inenum++;
          x = cs_constant (cs_lval_conv (cs_ex_of (en->kids[a]->kids[0])));
          T->inenum--;
          long long v = 0;
          cs_eval (x->kid[0], &v);
          v = cs_wrap (v, x->t);
          if (v >= -2147483647LL - 1 && v <= 2147483647LL) {
            if (cs_kind (x->t) != TY_INT) x = cs_ice (x, T->intt, CK_INTEGRALCAST);
            d->t = T->intt;
          } else d->t = cs_unqual (x->t);
          d->val = v;
          d->hasinit = 1;
          d->uns = cs_is_int (x->t) && !cs_is_signed (x->t);
          inits[j] = x;
        }
        a++;
      }
      if (!inits[j]) {
        if (!last) { d->t = T->intt; d->val = 0; }
        else {
          d->t = last->t;
          d->val = last->val + 1;
          if (cs_kind (d->t) == TY_INT && d->val > 2147483647LL) d->t = cs_basic (TY_UINT);
          else if (cs_kind (d->t) == TY_UINT && d->val > 4294967295LL) d->t = cs_basic (TY_LONG);
        }
      }
      cs_bind (d->name, d->nlen, 0, d);
      enums[j] = d;
      last = d;
      j++;
    }
    j = 0;
    while (j < ne) {
      long long v = enums[j]->val;
      int signedv = cs_is_signed (enums[j]->t);
      if (signedv && v < 0) { long long b = 1; while (b < 64 && !(v >= -((long long) 1 << (b - 1)))) b++; if (b > negbits) negbits = b; }
      else { long long b = 0; unsigned long long u = (unsigned long long) v; while (u) { b++; u >>= 1; } if (b > posbits) posbits = b; }
      j++;
    }
    if (negbits) {
      if (negbits <= 32 && posbits < 32) { best = cs_basic (TY_INT); promo = best; }
      else if (negbits <= T->lbytes * 8 && posbits < T->lbytes * 8) { best = cs_basic (TY_LONG); promo = best; }
      else { best = cs_basic (TY_LLONG); promo = best; }
    } else {
      if (posbits <= 32) { best = cs_basic (TY_UINT); promo = best; }
      else if (posbits <= T->lbytes * 8) { best = cs_basic (TY_ULONG); promo = best; }
      else { best = cs_basic (TY_ULLONG); promo = best; }
    }
    r->intty = best;
    r->promo = promo;
    r->complete = 1;
    /* (each an int if all fit one; else each the enum's type, as clang and C23: RT_TABLE_UNSPEC of an enum with RT_TABLE_MAX 0xFFFFFFFF) */
    {
      long q = 0;
      allint = 1;
      while (q < ne) { long long w = enums[q]->val; if (w < -2147483647LL - 1 || w > 2147483647LL) allint = 0; q++; }
    }
    j = 0;
    while (j < ne) {
      struct cs_decl *d = enums[j];
      long long v = d->val;
      struct cs_ty *nt;
      if (allint) nt = T->intt;
      else if (cs_same_ty (d->t, best)) nt = d->t;
      else nt = best;
      if (inits[j] && !cs_same_ty (nt, inits[j]->t)) inits[j] = cs_cast_force (inits[j], nt, CK_INTEGRALCAST);
      d->t = nt;
      d->val = cs_wrap (v, nt);
      if (T->dump && !(T->exdepth && T->fn && !T->inenum)) { cs_o_kind ("enumerator"); cs_o_name (d->name, d->nlen); cs_o_ty (d->t); cs_o_str ("\n"); if (inits[j]) cs_dump_in (inits[j]); }
      j++;
    }
    if (!tag) spc->defined_rec = 1;
  }
  return cs_rec_ty (r);
}

/* ---- declarators ---- */
static struct cs_ty *cs_param_type (struct node *p, struct cs_pdecl *pd)
{
  struct cs_spec spc;
  struct cs_dinfo dinf;
  struct cs_ty *t;
  long i = 1;
  cs_type_of_specs (p->kids[0], &spc);
  dinf.name = 0; dinf.nlen = 0; dinf.ps = 0; dinf.np = 0; dinf.fn = 0; dinf.kr = 0;
  t = spc.t;
  while (i < p->count) {
    struct node *k = p->kids[i];
    if (cs_is (k, "__attribute__")) cs_attrs (k, &spc);
    else t = cs_declarator (k, spc.t, &dinf, &spc);
    i++;
  }
  if (spc.mode) t = cs_mode_type (t, spc.mode);
  {
    struct cs_ty *c = cs_canon (t);
    if (c->k == TY_ARRAY) { struct cs_ty *q = cs_ptr_to (c->to); q->q = c->pq; t = q; }
    else if (c->k == TY_FUNC) t = cs_ptr_to (t);
  }
  pd->name = dinf.name;
  pd->nlen = dinf.nlen;
  pd->t = t;
  return t;
}
static struct cs_ty *cs_declarator (struct node *d, struct cs_ty *t, struct cs_dinfo *dinf, struct cs_spec *spc)
{
  for (;;) {
    if (d->count == 0) {
      if (!cs_is (d, "?")) { dinf->name = d->text; dinf->nlen = d->len; dinf->where = d; }
      return t;
    }
    if (cs_is (d, "*")) {
      struct cs_ty *p = cs_ptr_to (t);
      long i = 1;
      int at = 0;
      while (i < d->count) {
        struct node *k = d->kids[i];
        if (cs_is (k, "const") || cs_is (k, "__const") || cs_is (k, "__const__")) p->q |= Q_CONST;
        else if (cs_is (k, "volatile") || cs_is (k, "__volatile") || cs_is (k, "__volatile__")) p->q |= Q_VOLATILE;
        else if (cs_is (k, "restrict") || cs_is (k, "__restrict") || cs_is (k, "__restrict__")) p->q |= Q_RESTRICT;
        else if (cs_is (k, "__seg_fs")) p->q |= Q_FS;
        else if (cs_is (k, "__seg_gs")) p->q |= Q_GS;
        else if (cs_is (k, "_Atomic")) at = 1;
        i++;
      }
      t = p;
      if (at) { struct cs_ty *x = cs_ty_new (TY_ATOMIC); x->to = t; t = x; }
      d = d->kids[0];
      continue;
    }
    if (cs_is (d, "[]")) {
      long i = 1;
      struct node *bytes = 0;
      struct cs_ex *countx = 0;
      long long n = -1;
      int pq = 0;
      while (i < d->count) {
        struct node *k = d->kids[i];
        if (k->count == 0 && (cs_is (k, "const") || cs_is (k, "__const") || cs_is (k, "__const__"))) pq |= Q_CONST;
        else if (k->count == 0 && (cs_is (k, "volatile") || cs_is (k, "__volatile") || cs_is (k, "__volatile__"))) pq |= Q_VOLATILE;
        else if (k->count == 0 && (cs_is (k, "restrict") || cs_is (k, "__restrict") || cs_is (k, "__restrict__"))) pq |= Q_RESTRICT;
        else if (k->count == 0 && cs_is (k, "static")) ;
        else if (cs_is (k, "__attribute__")) ;
        else bytes = k;
        i++;
      }
      if (bytes) {
        if (cs_is (bytes, "*") && bytes->count == 0) n = -2;
        else {
          long long v = 0;
          T->exdepth++;
          countx = cs_ex_of (bytes);
          T->incount = 1;
          if (cs_eval (countx, &v)) n = v; else n = -2;
          T->incount = 0;
          T->exdepth--;
        }
      }
      t = cs_array_of (t, n);
      t->pq = pq;
      if (n == -2) { t->count = bytes; t->countx = countx; }
      d = d->kids[0];
      continue;
    }
    if (cs_is (d, "()")) {
      struct cs_ty *f = cs_ty_new (TY_FUNC);
      struct node *in = d->kids[0];
      long i = 1, np = 0;
      struct cs_pdecl *ps = alloc ((d->count + 1) * sizeof (struct cs_pdecl));
      long mark;
      int kr = 0;
      f->to = t;
      f->proto = 1;
      mark = cs_scope_in ();
      while (i < d->count) {
        struct node *k = d->kids[i];
        if (cs_is (k, "...") && k->count == 0) f->var = 1;
        else if (cs_is (k, "param")) {
          cs_param_type (k, &ps[np]);
          if (ps[np].name) {
            /* in the prototype's scope for the parameters after it (char a[n], __typeof (main)) */
            struct cs_decl *pd = alloc (sizeof (struct cs_decl));
            pd->k = DK_PARAM; pd->name = ps[np].name; pd->nlen = ps[np].nlen; pd->t = ps[np].t;
            cs_bind (pd->name, pd->nlen, 0, pd);
          }
          np++;
        }
        else if (k->count == 0) { ps[np].name = k->text; ps[np].nlen = k->len; ps[np].t = T->intt; np++; kr = 1; }
        i++;
      }
      cs_scope_out (mark);
      if (np == 1 && !kr && !ps[0].name && cs_is_void (ps[0].t) && !cs_quals (ps[0].t) && cs_canon (ps[0].t)->k == TY_VOID) np = 0;
      if (kr || (d->count == 1)) f->proto = 0;
      if (!kr) {
        f->ps = alloc ((np + 1) * sizeof (struct cs_ty *));
        f->np = np;
        i = 0;
        while (i < np) { f->ps[i] = ps[i].t; i++; }
      }
      while (cs_is (in, "( )") && in->count && in->kids[in->count - 1]->count) in = in->kids[in->count - 1];
      if (in->count == 0 && !dinf->fn) { dinf->fn = 1; dinf->ps = ps; dinf->np = np; dinf->kr = kr; }
      t = f;
      d = d->kids[0];
      continue;
    }
    if (cs_is (d, "( )")) {
      long i = 0;
      while (i < d->count - 1) { if (cs_is (d->kids[i], "__attribute__")) { struct cs_spec a; a.noret = 0; a.mode = 0; a.vec = 0; a.algn = 0; a.packed = 0; a.transparent = 0; a.thr = 0; cs_attrs (d->kids[i], &a); if (a.noret && spc) spc->noret = 1; } i++; }
      d = d->kids[d->count - 1];
      continue;
    }
    cs_fail ("a declarator csema does not know", d);
  }
}
static struct cs_ty *cs_type_of_name (struct node *n)
{
  struct cs_spec spc;
  struct cs_dinfo dinf;
  struct cs_ty *t = cs_type_of_specs (n->kids[0], &spc);
  dinf.name = 0; dinf.nlen = 0; dinf.ps = 0; dinf.np = 0; dinf.fn = 0; dinf.kr = 0;
  if (n->count > 1) t = cs_declarator (n->kids[1], t, &dinf, &spc);
  if (spc.mode) t = cs_mode_type (t, spc.mode);
  if (spc.vec) { struct cs_ty *v = cs_ty_new (TY_VECTOR); v->to = t; v->n = spc.vec; t = v; }
  return t;
}

/* ---- declarations ---- */
static void cs_dump_params (struct cs_dinfo *dinf)
{
  long i = 0;
  if (!T->dump || !dinf->fn) return;
  T->depth++;
  while (i < dinf->np) { cs_o_kind ("param"); cs_o_name (dinf->ps[i].name, dinf->ps[i].nlen); cs_o_ty (dinf->ps[i].t); cs_o_str ("\n"); i++; }
  T->depth--;
}
static struct cs_ty *cs_noreturn_of (struct cs_ty *t)
{
  struct cs_ty *c = cs_canon (t), *r;
  if (c->k != TY_FUNC || c->noret) return t;
  r = cs_ty_copy (c);
  r->noret = 1;
  return r;
}
/* (T3c) what a redeclaration inherits of the attributes before it, as clang's InheritableAttr */
static void cs_sp_inherit (struct cs_spec *sp, struct cs_decl *old)
{
  struct cs_spec *o;
  if (!old || !old->sp) return;
  o = old->sp;
  if (!sp->ctor) { sp->ctor = o->ctor; sp->ctorprio = o->ctorprio; }
  if (!sp->weak) sp->weak = o->weak;
  if (!sp->pcs) sp->pcs = o->pcs;
  if (!sp->err) sp->err = o->err;
  if (!sp->section) sp->section = o->section;
  if (!sp->hasaln && o->hasaln) { sp->hasaln = 1; sp->alnmax = o->alnmax; }
}
static struct cs_decl *cs_declare_fn (unsigned char *name, long nlen, struct cs_ty *t, int sc, struct cs_spec *spc)
{
  struct cs_decl *old = cs_lookup (name, nlen, 0), *d = alloc (sizeof (struct cs_decl));
  d->k = DK_FUNC;
  d->name = name;
  d->nlen = nlen;
  d->sc = sc;
  if (spc->noret) t = cs_noreturn_of (t);
  if (old && old->k == DK_FUNC) {
    struct cs_ty *oc = cs_canon (old->t), *nc = cs_canon (t);
    if ((spc->thr & 2) && oc->proto && nc->proto && !cs_compatible (oc, nc)) { d->t = t; d->prev = old; d->builtin = old->builtin; }
    else {
      if (oc->noret && !nc->noret) { t = cs_noreturn_of (t); nc = cs_canon (t); }
      if (!nc->proto && oc->proto) { struct cs_ty *m = cs_ty_copy (oc); m->to = nc->to; m->noret = nc->noret || oc->noret; t = m; }
      d->t = t;
      d->builtin = old->builtin;
      d->prev = old->prev;
      d->hasbody = old->hasbody;
    }
  } else { d->t = t; d->builtin = T->builtins; }
  cs_bind (name, nlen, 0, d);
  return d;
}
static struct cs_ex *cs_full (struct cs_ex *e) { return e; }
/* (T3c) a block's declaration, for its statement; a function's locals by name */
static void cs_dl_add (struct cs_decl *d, int kind)
{
  struct cs_dl *x = alloc (sizeof (struct cs_dl));
  x->d = d;
  x->kind = kind;
  if (T->dllast) T->dllast->nxt = x; else T->dl1 = x;
  T->dllast = x;
}
static void cs_fn_local (struct cs_decl *d);
static void cs_declare (struct cs_spec *spc, struct node *id, int where)
{
  struct cs_dinfo dinf;
  struct cs_spec da;
  struct cs_ty *t;
  struct node *init = 0;
  long j = 1;
  dinf.name = 0; dinf.nlen = 0; dinf.ps = 0; dinf.np = 0; dinf.fn = 0; dinf.kr = 0;
  da = *spc;
  while (j < id->count) {
    struct node *k = id->kids[j];
    if (cs_is (k, "__attribute__")) cs_attrs (k, &da);
    else if (cs_is (k, "asm")) da.asmlabel = cs_attr_text (k, 0, k->count);
    else if (cs_is (k, "=")) init = k->kids[0];
    j++;
  }
  t = cs_declarator (id->kids[0], spc->t, &dinf, &da);
  if (da.mode) t = cs_mode_type (t, da.mode);
  /* (arm's pcs ("aapcs") of a pointer to a function: the function type's) */
  if (da.pcs && cs_canon (t)->k == TY_PTR && cs_canon (cs_canon (t)->to)->k == TY_FUNC) {
    struct cs_ty *f = cs_ty_copy (cs_canon (cs_canon (t)->to));
    f->pcs = 1;
    t = cs_ptr_to (f);
  }
  if (da.vec) { struct cs_ty *v = cs_ty_new (TY_VECTOR); v->to = t; v->n = da.vec; t = v; }
  if (!dinf.name) return;
  if (spc->istypedef) {
    struct cs_decl *d = alloc (sizeof (struct cs_decl));
    struct cs_ty *c = cs_canon (t);
    d->k = DK_TYPEDEF;
    d->name = dinf.name;
    d->nlen = dinf.nlen;
    d->t = t;
    d->algn = da.algn;
    if (T->builtins && dinf.nlen > 4 && same (dinf.name, 4, "__SV")) {
      /* aarch64's sizeless SVE types, builtin names of their own */
      d->t = cs_ty_new (TY_SVE);
      d->t->name = dinf.name;
      d->t->nlen = dinf.nlen;
    }
    if ((da.transparent || spc->transparent) && c->k == TY_UNION) c->rec->transparent = 1;
    if (spc->defined_rec && da.hasaln && (c->k == TY_STRUCT || c->k == TY_UNION) && da.alnmax > c->rec->tdalign) c->rec->tdalign = da.alnmax;
    d->sp = alloc (sizeof (struct cs_spec));
    *d->sp = da;
    if (where == 0) cs_top_add (TOP_TYPEDEF, d, 0, id, 0);
    else cs_dl_add (d, 2);
    if (spc->defined_rec && (c->k == TY_STRUCT || c->k == TY_UNION || c->k == TY_ENUM) && !c->rec->tag && !c->rec->td && t == spc->t && !t->q) {
      c->rec->td = dinf.name;
      c->rec->tdlen = dinf.nlen;
    }
    cs_bind (dinf.name, dinf.nlen, 0, d);
    cs_o_decl ("typedef", dinf.name, dinf.nlen, t, 0);
    return;
  }
  if (cs_canon (t)->k == TY_FUNC) {
    struct cs_decl *was = cs_lookup (dinf.name, dinf.nlen, 0);
    struct cs_decl *d = cs_declare_fn (dinf.name, dinf.nlen, t, spc->sc, &da);
    d->sp = alloc (sizeof (struct cs_spec));
    *d->sp = da;
    if (was && was->k == DK_FUNC) cs_sp_inherit (d->sp, was);
    d->ps = dinf.ps;
    d->np = dinf.np;
    d->off = c_off_of (dinf.where);
    if (where == 0) cs_top_add (TOP_FN, d, 0, id, 0);
    else { d->local = 1; cs_dl_add (d, 0); if (spc->sc == SC_EXTERN) cs_top_add (TOP_FN, d, 0, id, 1); cs_fn_local (d); }
    cs_o_decl ("function", dinf.name, dinf.nlen, d->t, spc->sc);
    cs_dump_params (&dinf);
    return;
  }
  {
    struct cs_decl *old = cs_lookup (dinf.name, dinf.nlen, 0), *d = alloc (sizeof (struct cs_decl));
    struct cs_ex *e = 0;
    d->k = DK_VAR;
    d->name = dinf.name;
    d->nlen = dinf.nlen;
    d->sc = spc->sc;
    d->algn = da.algn;
    if (old && old->k == DK_VAR && (where == 0 || spc->sc == SC_EXTERN) && cs_compatible (old->t, t)) t = cs_composite (t, old->t);
    d->t = t;
    d->sp = alloc (sizeof (struct cs_spec));
    *d->sp = da;
    if (old && old->k == DK_VAR && (where == 0 || spc->sc == SC_EXTERN)) cs_sp_inherit (d->sp, old);
    d->off = c_off_of (dinf.where);
    d->tls = spc->thr & 1;
    if (where == 0) cs_top_add (TOP_VAR, d, 0, id, 0);
    else { d->local = 1; cs_dl_add (d, 0); if (spc->sc == SC_EXTERN) cs_top_add (TOP_VAR, d, 0, id, 1); cs_fn_local (d); }
    cs_bind (dinf.name, dinf.nlen, 0, d);
    {
      long mark = T->out.n, k = 0, nl;
      unsigned char *later = 0;
      if (init) {
        struct cs_ty *done;
        if (spc->autotype) { e = cs_rv (cs_ex_of (init)); d->t = cs_unqual (e->t); }
        else { e = cs_init_of (t, init, &done); d->t = done; }
      }
      /* (records and enums an initializer defines come after the declaration, as clang adds them) */
      nl = T->out.n - mark;
      if (nl) { later = alloc (nl); while (k < nl) { later[k] = T->out.p[mark + k]; k++; } T->out.n = mark; }
      d->init = e;
      cs_o_decl ("var", dinf.name, dinf.nlen, d->t, spc->sc);
      if (e) cs_dump_in (cs_full (e));
      if (nl && T->dump) cs_b_bytes (&T->out, later, nl);
    }
  }
}
static void cs_fn_local (struct cs_decl *d) { if (T->cl) cl_local_name (d->name, d->nlen); }
static void cs_decl_item (struct node *n, int where)
{
  struct cs_spec spc;
  long i = 1;
  T->alone = n->count == 1;
  cs_type_of_specs (n->kids[0], &spc);
  T->alone = 0;
  T->cur_specs = n->kids[0];
  while (i < n->count) { cs_declare (&spc, n->kids[i], where); i++; }
}

/* ---- statements ---- */
/* a node's text as a C string */
static char *nd_cstr (struct node *n)
{
  char *c = alloc (n->len + 1);
  long i = 0;
  while (i < n->len) { c[i] = n->text[i]; i++; }
  return c;
}
static struct cs_st *cs_st_new (int k, struct node *n)
{
  struct cs_st *s = alloc (sizeof (struct cs_st));
  s->k = k;
  s->src = n;
  s->off = c_off_of (n);
  return s;
}
static void cs_st_add (struct cs_st *b, struct cs_st *k)
{
  if (b->nk == b->room) {
    long m = b->room * 2 + 8, i = 0;
    struct cs_st **a = alloc (m * sizeof (struct cs_st *));
    while (i < b->nk) { a[i] = b->kid[i]; i++; }
    b->kid = a;
    b->room = m;
  }
  b->kid[b->nk] = k;
  b->nk = b->nk + 1;
}
static struct cs_st *cs_stmt (struct node *n);
/* a block's item: a statement, or none (a directive) */
static struct cs_st *cs_item (struct node *n)
{
  if (cs_is (n, "decl")) {
    struct cs_st *s = cs_st_new (S_DECL, n);
    struct cs_dl *saved = T->dl1, *savedl = T->dllast;
    T->dl1 = 0;
    T->dllast = 0;
    cs_decl_item (n, 1);
    s->dl = T->dl1;
    T->dl1 = saved;
    T->dllast = savedl;
    return s;
  }
  if (cs_is (n, "__extension__")) { struct cs_st *s = cs_item (n->kids[0]); if (s) s->off = c_off_of (n); return s; }
  if (cs_is (n, "_Static_assert")) {
    struct cs_ex *c = cs_rv (cs_ex_of (n->kids[0]));
    int k = cs_scalar_kind (&c, cs_basic (TY_BOOL));
    struct cs_st *s = cs_st_new (S_DECL, n);
    c = cs_ice (c, cs_basic (TY_BOOL), k);
    if (T->dump) { cs_o_kind ("static_assert"); cs_o_str ("\n"); cs_dump_in (c); }
    {
      struct cs_dl *d = alloc (sizeof (struct cs_dl));
      d->kind = 1;
      if (n->count > 1) d->msg = cs_ex_of (n->kids[1]);
      s->dl = d;
    }
    return s;
  }
  if (cs_is (n, "__label__")) {
    long i = 0;
    while (i < n->count) { cs_label_decl (n->kids[i]->text, n->kids[i]->len); i++; }
    return cs_st_new (S_DECL, n);
  }
  if (cs_is (n, "directive")) { cs_top_add (TOP_WEAK, 0, 0, n->kids[0], 1); return 0; }
  return cs_stmt (n);
}
static struct cs_ex *cs_cond_of (struct node *n) { return cs_rv (cs_ex_of (n)); }
static int cs_asm_letter (unsigned char c)
{
  /* 1 memory, 2 immediate, 3 a modifier, 0 a register */
  if (c == 'm' || c == 'o' || c == 'V' || c == '<' || c == '>' || c == 'A' || c == 'Q') return 1;
  if (c == 'i' || c == 'n' || c == 'I' || c == 'J' || c == 'K' || c == 'L' || c == 'M' || c == 'N' || c == 'O' || c == 'P' || c == 's' || c == 'E' || c == 'F') return 2;
  if (c == '=' || c == '+' || c == '&' || c == '%' || c == '*' || c == '#' || c == '!' || c == '?' || c == ',' || c == ' ') return 3;
  if (c >= '0' && c <= '9') return 4;
  return 0;
}
static int cs_asm_rv (struct node *s, struct node *outs)
{
  struct cs_buf b;
  long i;
  int reg = 0, mem = 0, imm = 0;
  cs_b_init (&b);
  if (cs_is (s, "str")) { i = 0; while (i < s->count) { cs_tok_bytes (s->kids[i], &b); i++; } } else cs_tok_bytes (s, &b);
  i = 0;
  while (i < b.n) {
    int k = cs_asm_letter (b.p[i]);
    if (b.p[i] == '"') { i++; continue; }
    if (k == 1) mem = 1;
    else if (k == 2) imm = 1;
    else if (k == 4) {
      long m = b.p[i] - '0';
      if (outs && m < outs->count) { struct node *o = outs->kids[m]; return cs_asm_rv (o->kids[o->count - 2], 0); }
      reg = 1;
    }
    else if (k == 0) reg = 1;
    i++;
  }
  if (reg) return 1;
  (void) mem; (void) imm;
  return 0;
}
static struct cs_st *cs_asm_stmt (struct node *n)
{
  long i = 0, sec = 0, nops = 0;
  struct node *outs = 0;
  struct cs_st *s = cs_st_new (S_ASM, n);
  while (i < n->count) { if (cs_is (n->kids[i], ":")) nops = nops + n->kids[i]->count; i++; }
  s->ops = alloc ((nops + 1) * sizeof (struct cs_ex *));
  i = 0;
  while (i < n->count) {
    struct node *k = n->kids[i];
    if (cs_is (k, ":") && k->count >= 0) {
      if (sec < 2) {
        long j = 0;
        if (sec == 0) outs = k;
        while (j < k->count) {
          struct node *o = k->kids[j];
          if (cs_is (o, "operand")) {
            struct cs_ex *e = cs_ex_of (o->kids[o->count - 1]);
            if (sec == 1 && cs_asm_rv (o->kids[o->count - 2], outs)) e = cs_rv (e);
            cs_dump_ex (e);
            s->ops[s->nops] = e;
            s->nops = s->nops + 1;
          }
          j++;
        }
      }
      sec++;
    }
    i++;
  }
  return s;
}
static struct cs_st *cs_stmt1 (struct node *n)
{
  struct cs_st *s;
  if (cs_is (n, "block")) {
    long m = cs_scope_in (), i = 0;
    struct cs_lab *labs = T->labels;
    s = cs_st_new (S_BLOCK, n);
    while (i < n->count) { struct cs_st *k = cs_item (n->kids[i]); if (k) cs_st_add (s, k); i++; }
    T->labels = labs;
    cs_scope_out (m);
    return s;
  }
  if (cs_is (n, "return")) {
    s = cs_st_new (S_RETURN, n);
    if (n->count) {
      struct cs_ex *e = cs_ex_of (n->kids[0]);
      if (T->fnret && cs_is_void (T->fnret)) { if (!cs_is_void (e->t)) e = cs_ice (cs_rv (e), cs_basic (TY_VOID), CK_TOVOID); }
      else if (T->fnret) e = cs_assign_conv (T->fnret, e);
      cs_dump_ex (e);
      s->e = e;
    }
    return s;
  }
  if (cs_is (n, "break")) return cs_st_new (S_BREAK, n);
  if (cs_is (n, "continue")) return cs_st_new (S_CONTINUE, n);
  if (n->count == 0 || cs_is (n, ";") || cs_is (n, "q")) return cs_st_new (S_NULL, n);
  if (cs_is (n, "expr")) {
    s = cs_st_new (S_EXPR, n);
    s->e = cs_ignored (cs_ex_of (n->kids[0]));
    cs_dump_ex (s->e);
    return s;
  }
  if (cs_is (n, "if")) {
    s = cs_st_new (S_IF, n);
    s->e = cs_cond_of (n->kids[0]);
    cs_dump_ex (s->e);
    s->a = cs_stmt (n->kids[1]);
    if (n->count > 2) s->b = cs_stmt (n->kids[2]);
    return s;
  }
  if (cs_is (n, "while")) {
    s = cs_st_new (S_WHILE, n);
    s->e = cs_cond_of (n->kids[0]);
    cs_dump_ex (s->e);
    s->a = cs_stmt (n->kids[1]);
    return s;
  }
  if (cs_is (n, "do")) {
    s = cs_st_new (S_DO, n);
    s->a = cs_stmt (n->kids[0]);
    s->e = cs_cond_of (n->kids[1]);
    cs_dump_ex (s->e);
    return s;
  }
  if (cs_is (n, "for")) {
    long m = cs_scope_in ();
    struct node *a = n->kids[0], *b = n->kids[1], *c = n->kids[2];
    s = cs_st_new (S_FOR, n);
    if (cs_is (a, "expr")) { s->e = cs_ignored (cs_ex_of (a->kids[0])); cs_dump_ex (s->e); }
    else if (!cs_is (a, ";")) s->a = cs_item (a);
    if (cs_is (b, "expr")) { s->e2 = cs_cond_of (b->kids[0]); cs_dump_ex (s->e2); }
    if (cs_is (c, "expr")) { s->e3 = cs_ignored (cs_ex_of (c->kids[0])); cs_dump_ex (s->e3); }
    s->b = cs_stmt (n->kids[3]);
    cs_scope_out (m);
    return s;
  }
  if (cs_is (n, "switch")) {
    struct cs_ex *c = cs_uuc (cs_ex_of (n->kids[0]));
    s = cs_st_new (S_SWITCH, n);
    s->e = c;
    cs_dump_ex (c);
    if (T->nsw < 64) T->swcond[T->nsw] = c->t;
    T->nsw++;
    s->a = cs_stmt (n->kids[1]);
    T->nsw--;
    return s;
  }
  if (cs_is (n, "case")) {
    long i = 0;
    struct cs_ty *ct = T->nsw > 0 && T->nsw <= 64 ? T->swcond[T->nsw - 1] : T->intt;
    s = cs_st_new (S_CASE, n);
    while (i < n->count - 1) {
      struct cs_ex *x = cs_constant (cs_ex_of (n->kids[i]));
      x->isnull = 1;
      x = cs_ice (x, ct, CK_INTEGRALCAST);
      cs_dump_ex (x);
      if (i == 0) s->e = x; else s->e2 = x;
      i++;
    }
    s->a = cs_item (n->kids[n->count - 1]);
    return s;
  }
  if (cs_is (n, "default")) { s = cs_st_new (S_DEFAULT, n); s->a = cs_item (n->kids[0]); return s; }
  if (cs_is (n, "label")) {
    s = cs_st_new (S_LABEL, n);
    s->name = n->kids[0]->text;
    s->nlen = n->kids[0]->len;
    s->lk = cs_label_k (s->name, s->nlen);
    s->a = cs_item (n->kids[n->count - 1]);
    return s;
  }
  if (cs_is (n, "goto *")) {
    s = cs_st_new (S_IGOTO, n);
    s->e = cs_assign_conv (T->cvptr, cs_ex_of (n->kids[0]));
    cs_dump_ex (s->e);
    return s;
  }
  if (cs_is (n, "asm")) return cs_asm_stmt (n);
  if (cs_is (n, "goto")) { s = cs_st_new (S_GOTO, n); s->name = n->kids[0]->text; s->nlen = n->kids[0]->len; s->lk = cs_label_k (s->name, s->nlen); return s; }
  s = cs_item (n);
  return s;
}
/* a statement, in the annotated tree (not -d's lines) a node of its kind over what it holds */
static struct cs_st *cs_stmt (struct node *n)
{
  struct cs_st *s;
  int tr = T->tree && T->dump;
  if (tr) {
    cs_o_kind ((char *) nd_cstr (n));
    if (cs_is (n, "label") || cs_is (n, "goto")) cs_o_name (n->kids[0]->text, n->kids[0]->len);
    cs_o_str ("\n");
    T->depth++;
  }
  s = cs_stmt1 (n);
  if (tr) T->depth--;
  return s;
}
/* (the last of a statement expression, its value: under its labels too, INLINE_VSYSCALL's out: sc_ret) */
static struct cs_st *cs_stmtx_last (struct node *it, struct cs_ex **last)
{
  if (cs_is (it, "expr")) {
    struct cs_st *x = cs_st_new (S_EXPR, it);
    *last = cs_ex_of (it->kids[0]);
    *last = cs_lval_conv (cs_fa_conv (*last));
    cs_dump_ex (*last);
    x->e = *last;
    return x;
  }
  if (cs_is (it, "label")) {
    struct cs_st *s = cs_st_new (S_LABEL, it);
    s->name = it->kids[0]->text;
    s->nlen = it->kids[0]->len;
    s->lk = cs_label_k (s->name, s->nlen);
    s->a = cs_stmtx_last (it->kids[it->count - 1], last);
    return s;
  }
  return cs_item (it);
}
static struct cs_ex *cs_stmt_expr (struct node *blk)
{
  long mark = T->out.n, sm = cs_scope_in (), i = 0;
  struct cs_ex *e = cs_mk (E_STMTX, cs_basic (TY_VOID), 0), *last = 0;
  struct cs_lab *labs = T->labels;
  int ed = T->exdepth, dd = T->depth;
  struct cs_st *b = cs_st_new (S_BLOCK, blk);
  T->exdepth = 0;
  T->depth = 0;
  while (i < blk->count) {
    struct node *it = blk->kids[i];
    if (i == blk->count - 1) { struct cs_st *k = cs_stmtx_last (it, &last); if (k) cs_st_add (b, k); }
    else { struct cs_st *k = cs_item (it); if (k) cs_st_add (b, k); }
    i++;
  }
  T->labels = labs;
  cs_scope_out (sm);
  T->exdepth = ed;
  T->depth = dd;
  if (last) e->t = cs_unqual (last->t);
  e->tlen = T->out.n - mark;
  e->text = alloc (e->tlen + 1);
  i = 0;
  while (i < e->tlen) { e->text[i] = T->out.p[mark + i]; i++; }
  T->out.n = mark;
  e->st = b;
  return e;
}
static void cs_fundef (struct node *n)
{
  struct cs_spec spc, da;
  struct cs_dinfo dinf;
  struct cs_ty *t, *f;
  struct cs_decl *d;
  struct node *body = n->kids[n->count - 1];
  long i = 2, m;
  cs_type_of_specs (n->kids[0], &spc);
  dinf.name = 0; dinf.nlen = 0; dinf.ps = 0; dinf.np = 0; dinf.fn = 0; dinf.kr = 0;
  da = spc;
  while (i < n->count - 1) {
    if (cs_is (n->kids[i], "__attribute__")) cs_attrs (n->kids[i], &da);
    else if (cs_is (n->kids[i], "asm")) da.asmlabel = cs_attr_text (n->kids[i], 0, n->kids[i]->count);
    i++;
  }
  t = cs_declarator (n->kids[1], spc.t, &dinf, &da);
  if (dinf.kr) {
    /* K&R: the declarations' types for the names */
    long k = 2;
    while (k < n->count - 1) {
      struct node *dn = n->kids[k];
      if (cs_is (dn, "decl")) {
        struct cs_spec ks;
        long a = 1;
        cs_type_of_specs (dn->kids[0], &ks);
        while (a < dn->count) {
          struct cs_dinfo pi;
          struct cs_ty *pt;
          long q = 0;
          pi.name = 0; pi.nlen = 0; pi.ps = 0; pi.np = 0; pi.fn = 0; pi.kr = 0;
          pt = cs_declarator (dn->kids[a]->kids[0], ks.t, &pi, &ks);
          if (cs_canon (pt)->k == TY_ARRAY) pt = cs_ptr_to (cs_canon (pt)->to);
          else if (cs_canon (pt)->k == TY_FUNC) pt = cs_ptr_to (pt);
          while (q < dinf.np) { if (cs_eqb (dinf.ps[q].name, dinf.ps[q].nlen, pi.name, pi.nlen)) dinf.ps[q].t = pt; q++; }
          a++;
        }
      }
      k++;
    }
  }
  {
    struct cs_decl *was = cs_lookup (dinf.name, dinf.nlen, 0);
    d = cs_declare_fn (dinf.name, dinf.nlen, t, spc.sc, &da);
    d->hasbody = 1;
    d->sp = alloc (sizeof (struct cs_spec));
    *d->sp = da;
    if (was && was->k == DK_FUNC) cs_sp_inherit (d->sp, was);
  }
  d->inl = spc.inl;
  d->ps = dinf.ps;
  d->np = dinf.np;
  d->off = c_off_of (dinf.where);
  T->cur_specs = n->kids[0];
  cs_top_add (TOP_FN, d, 0, n, 0);
  cs_o_decl ("function", dinf.name, dinf.nlen, d->t, spc.sc);
  cs_dump_params (&dinf);
  f = cs_canon (d->t);
  m = cs_scope_in ();
  i = 0;
  while (i < dinf.np) {
    struct cs_decl *p = alloc (sizeof (struct cs_decl));
    p->k = DK_PARAM;
    p->name = dinf.ps[i].name;
    p->nlen = dinf.ps[i].nlen;
    p->t = dinf.ps[i].t;
    if (p->name) cs_bind (p->name, p->nlen, 0, p);
    i++;
  }
  T->fn = d;
  T->fnret = cs_unqual (f->to);
  T->depth++;
  T->labels = 0;
  T->labcount = 0;
  d->body = cs_stmt (body);
  T->depth--;
  T->fn = 0;
  T->fnret = 0;
  cs_scope_out (m);
}
static void cs_external (struct node *n)
{
  if (cs_is (n, "decl")) {
    cs_decl_item (n, 0);
    if (!T->dump && !T->nodump && n->count > 1 && n->kids[1]->count && n->kids[1]->kids[0]->count == 0 && same (n->kids[1]->kids[0]->text, n->kids[1]->kids[0]->len, "__csema_end")) T->dump = 1;
    if (n->count > 1 && n->kids[1]->count && n->kids[1]->kids[0]->count == 0 && same (n->kids[1]->kids[0]->text, n->kids[1]->kids[0]->len, "__csema_mid")) T->builtins = 0;
    return;
  }
  if (cs_is (n, "fun def")) { cs_fundef (n); return; }
  if (cs_is (n, "__extension__")) { cs_external (n->kids[0]); return; }
  if (cs_is (n, "_Static_assert")) { cs_item (n); return; }
  if (cs_is (n, "asm")) { cs_top_add (TOP_ASM, 0, 0, n, 0); return; }
  if (cs_is (n, "directive")) { cs_top_add (TOP_WEAK, 0, 0, n->kids[0], 0); return; }
}

/* ---- the unit ---- */
/* a leaf of bytes, or past 255 a node "token" of pieces (cparse's) */
static struct node *cs_leaf_of (unsigned char *p, long n)
{
  struct node *r;
  long i = 0;
  if (n <= 255) return nd_text (p, n);
  r = nd ("token");
  while (i < n) { long e = i + 255; if (e > n) e = n; else while (e > i && (p[e] & 0xc0) == 0x80) e--; nd_add (r, nd_text (p + i, e - i)); i = e; }
  return r;
}
void cs_run (struct node *root, unsigned char *src, long n, long skip, int target, int mode, char *name)
{
  long i = 0;
  struct cs_decl *d;
  T = alloc (sizeof (struct cs_cst));
  T->tab = alloc (65536 * sizeof (struct cs_bind *));
  cs_target_init (target);
  T->src = src;
  T->srcn = n;
  T->skip = skip;
  T->fname = name;
  T->builtins = 1;
  T->tree = mode == 0;
  T->keep = 1;
  if (mode == 2) cl_begin ();
  cs_markers ();
  d = alloc (sizeof (struct cs_decl));
  d->k = DK_TYPEDEF;
  d->name = (unsigned char *) "__builtin_va_list";
  d->nlen = 17;
  d->t = T->vptr;
  cs_bind (d->name, d->nlen, 0, d);
  d = alloc (sizeof (struct cs_decl));
  d->k = DK_TYPEDEF; d->name = (unsigned char *) "__int128_t"; d->nlen = 10; d->t = cs_basic (TY_INT128);
  cs_bind (d->name, d->nlen, 0, d);
  d = alloc (sizeof (struct cs_decl));
  d->k = DK_TYPEDEF; d->name = (unsigned char *) "__uint128_t"; d->nlen = 11; d->t = cs_basic (TY_UINT128);
  cs_bind (d->name, d->nlen, 0, d);
  (void) mode;
  while (i < root->count) { cs_external (root->kids[i]); i++; }
  i = 0;
  while (i < T->nrecs) { cs_lay_dump (T->recs[i]); i++; }
  if (mode == 2) { cl_run (); return; }
  if (!T->tree) { out_bytes (T->out.p, T->out.n); return; }
  {
    /* the lines as a tree: each line a node of its kind, its fields leaves, the lines one deeper its kids */
    struct node *top = nd (""), *stack[256];
    unsigned char *p = T->out.p;
    long at = 0, nn = T->out.n;
    stack[0] = top;
    while (at < nn) {
      long d = 0, e = at, f;
      struct node *k;
      while (at + 1 < nn && p[at] == ' ' && p[at + 1] == ' ') { d++; at += 2; }
      while (e < nn && p[e] != '\n') e++;
      f = at;
      while (f < e && p[f] != '\t') f++;
      k = nd_text (p + at, f - at);
      while (f < e) {
        long g = f + 1;
        while (g < e && p[g] != '\t') g++;
        nd_add (k, cs_leaf_of (p + f + 1, g - f - 1));
        f = g;
      }
      if (d > 254) d = 254;
      if (d > T->tdepth) d = T->tdepth;
      nd_add (stack[d], k);
      stack[d + 1] = k;
      T->tdepth = d + 1;
      at = e + 1;
    }
    nd_layer (top);
    cp_write_ff (top);
  }
}
