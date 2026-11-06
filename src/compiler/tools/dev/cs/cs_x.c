/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cs_x.c (in cs.c): building expressions from cparse's tree */
static struct cs_ex *cs_constant (struct cs_ex *x);
static struct cs_ex *cs_ex_of (struct node *n);
static struct cs_ty *cs_type_of_name (struct node *n);
static struct cs_ty *cs_type_in_ex (struct node *n) { struct cs_ty *t; T->exdepth++; t = cs_type_of_name (n); T->exdepth--; return t; }
static struct cs_ex *cs_stmt_expr (struct node *blk);
struct cs_st;
static struct cs_ex *cs_init_braced (struct cs_ty *t, struct node *list);

static int cs_is_ident (struct node *n)
{
  unsigned char c;
  if (n->count || n->len == 0) return 0;
  c = n->text[0];
  return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '$' || c >= 128;
}
/* a literal's bytes: a leaf's, or a long token's pieces */
static void cs_tok_bytes (struct node *n, struct cs_buf *b)
{
  long i = 0;
  if (n->count == 0) { cs_b_bytes (b, n->text, n->len); return; }
  while (i < n->count) { cs_b_bytes (b, n->kids[i]->text, n->kids[i]->len); i++; }
}
static int cs_digitv (unsigned char c)
{
  if (c >= '0' && c <= '9') return c - '0';
  if (c >= 'a' && c <= 'f') return c - 'a' + 10;
  if (c >= 'A' && c <= 'F') return c - 'A' + 10;
  return 99;
}
static int cs_fits (unsigned long long v, int k)
{
  long long nbits = cs_basic_size (k) * 8;
  int sg = k == TY_INT || k == TY_LONG || k == TY_LLONG;
  if (nbits >= 64) return sg ? v <= (unsigned long long) 0x7fffffffffffffffLL : 1;
  if (sg) return v < ((unsigned long long) 1 << (nbits - 1));
  return v < ((unsigned long long) 1 << nbits);
}
/* a fixed point literal's bits (clang's GetFixedPointValue): its decimal value times
   2^scale, truncated; a fract's 1 its largest value */
static unsigned long long cs_fix_bits (unsigned char *p, long len, struct cs_ty *t)
{
  unsigned char *dg = alloc (len + 8), *f;
  long nd = 0, i = 0, nint, m = 0, j;
  long long e = 0;
  int pt = 0, scale = cs_fix_scale (t), b = 0;
  unsigned long long ipart = 0, bits = 0, width = cs_ty_size (t) * 8, max;
  while (i < len) {
    unsigned char c = p[i];
    if (c >= '0' && c <= '9') { dg[nd++] = c - '0'; if (pt) e--; i++; continue; }
    if (c == '.') { pt = 1; i++; continue; }
    if (c == '\'') { i++; continue; }
    break;
  }
  if (i < len && (p[i] == 'e' || p[i] == 'E')) {
    long long x = 0;
    int neg = 0;
    i++;
    if (i < len && (p[i] == '+' || p[i] == '-')) { neg = p[i] == '-'; i++; }
    while (i < len && p[i] >= '0' && p[i] <= '9') { x = x * 10 + (p[i] - '0'); i++; }
    if (neg) x = 0 - x;
    e = e + x;
  }
  /* (the value: digits dg times 10^e; its integer digits, then its fraction's) */
  nint = nd + e;
  f = alloc (nd + (nint < 0 ? 0 - nint : 0) + 8);
  j = 0;
  while (j < nint) { ipart = ipart * 10; if (j < nd) ipart = ipart + dg[j]; j++; }
  j = nint;
  while (j < 0) { f[m++] = 0; j++; }
  while (j < nd) { f[m++] = dg[j]; j++; }
  while (b < scale) {
    int carry = 0;
    j = m - 1;
    while (j >= 0) { int x = f[j] * 2 + carry; f[j] = x % 10; carry = x / 10; j--; }
    bits = bits * 2 + carry;
    b++;
  }
  bits = (ipart << scale) | bits;
  max = cs_fix_uns (t) ? ~(unsigned long long) 0 >> (64 - width) : ~(unsigned long long) 0 >> (65 - width);
  if (cs_fix_code (t) % 6 < 3 && bits == max + 1) bits = max;
  return bits;
}
/* its value as clang writes it (APFixedPoint::toString, of a value not negative): the
   integer part, a point, the fraction's digits to its last (one at least) */
static void cs_fix_text (struct cs_buf *b, unsigned long long bits, int scale)
{
  unsigned long long mask = ~(unsigned long long) 0 >> (64 - scale), fr = bits & mask;
  cs_b_ull (b, bits >> scale);
  cs_b_byte (b, '.');
  do {
    fr = fr * 10;
    cs_b_byte (b, '0' + (int) (fr >> scale));
    fr = fr & mask;
  } while (fr != 0);
}
static struct cs_ex *cs_num_lit (struct node *n)
{
  unsigned char *p = n->text;
  long len = n->len, i = 0, e = len;
  int base = 10, isf = 0, u = 0, l = 0, k;
  /* (one past a node's 255 bytes, in pieces: tst-strtod's) */
  if (n->count) { struct cs_buf jb; cs_b_init (&jb); cs_tok_bytes (n, &jb); p = jb.p; len = jb.n; e = len; }
  unsigned long long v = 0;
  struct cs_ex *x;
  if (len > 1 && p[0] == '0' && (p[1] == 'x' || p[1] == 'X')) {
    base = 16;
    i = 2;
    while (i < len) { if (p[i] == '.' || p[i] == 'p' || p[i] == 'P') isf = 1; i++; }
  } else {
    while (i < len) { if (p[i] == '.' || p[i] == 'e' || p[i] == 'E') isf = 1; i++; }
    if (len > 1 && p[0] == '0' && (p[1] == 'b' || p[1] == 'B')) base = 2;
    else if (p[0] == '0') base = 8;
  }
  /* (a fixed point literal: a decimal one with r or k, C's suffix of fixed point, after
     [u][h|l]: never _Sat, its value's bits in val (no integer constant)) */
  if (base != 16 && (p[len - 1] == 'r' || p[len - 1] == 'R' || p[len - 1] == 'k' || p[len - 1] == 'K')) {
    long s = len - 1;
    int acc = p[len - 1] == 'k' || p[len - 1] == 'K', sz = 1, us = 0;
    if (s > 0 && (p[s - 1] == 'h' || p[s - 1] == 'H')) { sz = 0; s--; }
    else if (s > 0 && (p[s - 1] == 'l' || p[s - 1] == 'L')) { sz = 2; s--; }
    if (s > 0 && (p[s - 1] == 'u' || p[s - 1] == 'U')) { us = 1; s--; }
    x = cs_mk (E_FIX, cs_fix_ty (sz + 3 * acc + 6 * us), 0);
    x->val = (long long) cs_fix_bits (p, s, x->t);
    x->src = n;
    return x;
  }
  if (isf) {
    int fk = TY_DOUBLE;
    unsigned char c = p[len - 1];
    if (len > 3 && (same (p + len - 3, 3, "f16") || same (p + len - 3, 3, "F16"))) fk = TY_FLOAT16;
    else if (len > 3 && (same (p + len - 3, 3, "f32") || same (p + len - 3, 3, "F32"))) fk = TY_FLOAT;
    else if (len > 3 && (same (p + len - 3, 3, "f64") || same (p + len - 3, 3, "F64"))) fk = TY_DOUBLE;
    else if (len > 4 && (same (p + len - 4, 4, "f128") || same (p + len - 4, 4, "F128"))) fk = T->target == 1 ? TY_FLOAT128 : TY_LDOUBLE;
    else if (len > 4 && (same (p + len - 4, 4, "f32x") || same (p + len - 4, 4, "F32x"))) fk = TY_DOUBLE;
    else if (len > 4 && (same (p + len - 4, 4, "f64x") || same (p + len - 4, 4, "F64x"))) fk = TY_LDOUBLE;
    else if (c == 'f' || c == 'F') fk = TY_FLOAT;
    else if (c == 'l' || c == 'L') fk = TY_LDOUBLE;
    else if (c == 'q' || c == 'Q') fk = T->target == 1 ? TY_FLOAT128 : TY_LDOUBLE;
    x = cs_mk (E_FLT, cs_basic (fk), 0);
    x->src = n;
    return x;
  }
  i = base == 16 || base == 2 ? 2 : 0;
  while (i < len) {
    int d;
    if (p[i] == '\'') { i++; continue; }
    d = cs_digitv (p[i]);
    if (d >= base) break;
    v = v * base + d;
    i++;
  }
  e = i;
  while (e < len) {
    unsigned char c = p[e];
    if (c == 'u' || c == 'U') u = 1;
    else if (c == 'l' || c == 'L') l++;
    e++;
  }
  if (l == 0 && !u && cs_fits (v, TY_INT)) k = TY_INT;
  else if (l == 0 && (u || base != 10) && cs_fits (v, TY_UINT)) k = TY_UINT;
  else if (l <= 1 && !u && cs_fits (v, TY_LONG)) k = TY_LONG;
  else if (l <= 1 && (u || base != 10) && cs_fits (v, TY_ULONG)) k = TY_ULONG;
  else if (!u && cs_fits (v, TY_LLONG)) k = TY_LLONG;
  else k = TY_ULLONG;
  x = cs_mk (E_INT, cs_basic (k), 0);
  x->val = (long long) v;
  x->isval = 1;
  return x;
}
/* one character of a literal at p (escapes read): its value; *m its length */
static long long cs_lit_char (unsigned char *p, long n, long *m, int *esc)
{
  long i = 1;
  long long v = 0;
  *esc = 1;
  if (p[0] != '\\') {
    /* a UTF-8 sequence */
    unsigned char c = p[0];
    long k = c < 0x80 ? 1 : c < 0xe0 ? 2 : c < 0xf0 ? 3 : 4, j = 1;
    *esc = 0;
    if (k > n) k = 1;
    v = k == 1 ? c : k == 2 ? (c & 0x1f) : k == 3 ? (c & 0x0f) : (c & 0x07);
    while (j < k) { v = (v << 6) | (p[j] & 0x3f); j++; }
    *m = k;
    return v;
  }
  if (n < 2) { *m = 1; return '\\'; }
  if (p[1] >= '0' && p[1] <= '7') {
    while (i < n && i < 4 && p[i] >= '0' && p[i] <= '7') { v = v * 8 + (p[i] - '0'); i++; }
    *m = i;
    return v;
  }
  if (p[1] == 'x') {
    i = 2;
    while (i < n && cs_digitv (p[i]) < 16) { v = v * 16 + cs_digitv (p[i]); i++; }
    *m = i;
    return v;
  }
  if (p[1] == 'u' || p[1] == 'U') {
    long d = p[1] == 'u' ? 4 : 8;
    i = 2;
    while (i < n && i < 2 + d) { v = v * 16 + cs_digitv (p[i]); i++; }
    *m = i;
    *esc = 2;
    return v;
  }
  *m = 2;
  if (p[1] == 'n') return 10;
  if (p[1] == 't') return 9;
  if (p[1] == 'r') return 13;
  if (p[1] == 'a') return 7;
  if (p[1] == 'b') return 8;
  if (p[1] == 'f') return 12;
  if (p[1] == 'v') return 11;
  if (p[1] == 'e' || p[1] == 'E') return 27;
  return p[1];
}
static long cs_utf8_len (long long v) { return v < 0x80 ? 1 : v < 0x800 ? 2 : v < 0x10000 ? 3 : 4; }
/* a literal's prefix: 0 none, 1 u8, 2 L, 3 u, 4 U; *at where its quote is */
static int cs_lit_prefix (unsigned char *p, long *at)
{
  if (p[0] == 'u' && p[1] == '8') { *at = 2; return 1; }
  if (p[0] == 'L') { *at = 1; return 2; }
  if (p[0] == 'u') { *at = 1; return 3; }
  if (p[0] == 'U') { *at = 1; return 4; }
  *at = 0;
  return 0;
}
static struct cs_ty *cs_char_kind_type (int pre)
{
  if (pre == 2) return cs_basic (T->wchar_k);
  if (pre == 3) return cs_basic (TY_USHORT);
  if (pre == 4) return cs_basic (TY_UINT);
  if (pre == 1) return cs_basic (TY_CHAR);
  return cs_basic (TY_CHAR);
}
static struct cs_ex *cs_char_lit (struct node *n)
{
  unsigned char *p = n->text;
  long at, i, end = n->len - 1, count = 0;
  int pre = cs_lit_prefix (p, &at), esc;
  long long v = 0, c;
  struct cs_ex *x;
  i = at + 1;
  while (i < end) {
    long m;
    c = cs_lit_char (p + i, end - i, &m, &esc);
    if (pre == 0 && !esc && m > 1) { long j = 0; while (j < m) { v = (v << 8) | p[i + j]; count++; j++; } i += m; continue; }
    v = pre == 0 ? ((v << 8) | (c & 0xff)) : c;
    count++;
    i += m;
  }
  if (pre == 0) {
    if (count == 1) { v &= 0xff; if (T->char_signed && v >= 128) v -= 256; }
    v = (long long) ((unsigned long long) v & 0xffffffff);
    x = cs_mk (E_CHR, cs_basic (TY_INT), 0);
  } else if (pre == 1) {
    x = cs_mk (E_CHR, cs_basic (TY_UCHAR), 0);
  } else x = cs_mk (E_CHR, cs_char_kind_type (pre), 0);
  x->val = v;
  x->isval = 1;
  return x;
}
/* a string literal (adjacent ones joined): its type, char[N] or the wide one's */
static struct cs_ex *cs_str_lit (struct node *n)
{
  int isstr = n->count && cs_is (n, "str");
  long pi = 0, np = isstr ? n->count : 1;
  long long count = 0;
  int pre = 0;
  struct cs_ex *x;
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
      if (pre <= 1) count += esc == 2 ? cs_utf8_len (c) : esc ? 1 : m;
      else if (pre == 3) count += c >= 0x10000 ? 2 : 1;
      else count += 1;
      i += m;
    }
    pi++;
  }
  x = cs_mk (E_STR, cs_array_of (cs_char_kind_type (pre), count + 1), 1);
  x->src = n;
  return x;
}
static struct cs_ex *cs_ref (struct cs_decl *d)
{
  struct cs_ex *e;
  if (d->k == DK_FUNC) e = cs_mk (E_REF, d->builtin ? cs_basic (TY_BUILTINFN) : d->t, 0);
  else if (d->k == DK_ENUMC) { e = cs_mk (E_REF, d->t, 0); e->val = d->val; e->isval = 1; }
  else e = cs_mk (E_REF, d->t, 1);
  e->name = d->name;
  e->nlen = d->nlen;
  e->d = d;
  return e;
}
static void cs_p_pretty (struct cs_buf *b)
{
  struct cs_decl *f = T->fn;
  struct cs_ty *t = f->t;
  struct cs_buf in;
  cs_b_init (&in);
  cs_b_bytes (&in, f->name, f->nlen);
  if (t->k == TY_FUNC) {
    long i = 0;
    cs_b_byte (&in, '(');
    if (t->proto) {
      while (i < t->np) { if (i) cs_b_str (&in, ", "); cs_p_ty (&in, t->ps[i], 1); i++; }
      if (t->var) cs_b_str (&in, cs_pick (i, ", ...", "..."));
      else if (i == 0) cs_b_str (&in, "void");
    }
    cs_b_byte (&in, ')');
    cs_p_type (b, t->to, &in, 1);
  } else cs_b_buf (b, &in);
}
static struct cs_ex *cs_predef (struct node *n)
{
  struct cs_buf b;
  struct cs_ty *t;
  struct cs_ex *e;
  cs_b_init (&b);
  if (T->fn) {
    if (same (n->text, n->len, "__PRETTY_FUNCTION__")) cs_p_pretty (&b);
    else cs_b_bytes (&b, T->fn->name, T->fn->nlen);
  }
  t = cs_array_of (cs_qual (cs_basic (TY_CHAR), Q_CONST), b.n + 1);
  e = cs_mk (E_PREDEF, t, 1);
  e->name = n->text;
  e->nlen = n->len;
  cs_add (e, cs_mk (E_STR, t, 1));
  e->text = b.p;
  e->tlen = b.n;
  return e;
}
static struct cs_ex *cs_ident (struct node *n)
{
  struct cs_decl *d = cs_lookup (n->text, n->len, 0);
  if (!d || d->k == DK_TYPEDEF) {
    if (same (n->text, n->len, "__func__") || same (n->text, n->len, "__FUNCTION__") || same (n->text, n->len, "__PRETTY_FUNCTION__")) return cs_predef (n);
    /* (C23's, gnu23's libgcc: a literal; nullptr in a typeof) */
    if (same (n->text, n->len, "true") || same (n->text, n->len, "false") || same (n->text, n->len, "nullptr")) {
      struct cs_ex *x = cs_mk (E_TRAIT, n->text[0] == 'n' ? T->vptr : cs_basic (TY_BOOL), 0);
      x->val = n->text[0] == 't';
      x->isval = 1;
      return x;
    }
    cs_fail ("an unknown name", n);
  }
  return cs_ref (d);
}
static struct cs_ex *cs_leaf (struct node *n)
{
  unsigned char c = n->len ? n->text[0] : 0;
  long at;
  if (n->count && cs_is (n, "token") && n->kids[0]->len && ((n->kids[0]->text[0] >= '0' && n->kids[0]->text[0] <= '9') || n->kids[0]->text[0] == '.')) return cs_num_lit (n);
  if (n->count && (cs_is (n, "token") || cs_is (n, "str"))) return cs_str_lit (n);
  if ((c >= '0' && c <= '9') || c == '.') return cs_num_lit (n);
  cs_lit_prefix (n->text, &at);
  if (n->len > at && n->text[at] == '\'') return cs_char_lit (n);
  if (n->len > at && n->text[at] == '"') return cs_str_lit (n);
  return cs_ident (n);
}

/* ---- the builtins' rules ---- */
static int cs_builtin_rule (struct cs_decl *d)
{
  unsigned char *p = d->name;
  long n = d->nlen;
  if (same (p, n, "__builtin_va_start") || same (p, n, "__builtin_va_end") || same (p, n, "__builtin_va_copy")) return BA_NONE;
  if (same (p, n, "__builtin_add_overflow") || same (p, n, "__builtin_sub_overflow") || same (p, n, "__builtin_mul_overflow")) return BA_RVALUE;
  if (same (p, n, "__builtin_constant_p")) return BA_RVALUE;
  if (same (p, n, "__builtin_isless") || same (p, n, "__builtin_islessequal") || same (p, n, "__builtin_isgreater")
      || same (p, n, "__builtin_isgreaterequal") || same (p, n, "__builtin_isunordered") || same (p, n, "__builtin_islessgreater")) return BA_UAC;
  if (same (p, n, "__builtin_isnan") || same (p, n, "__builtin_isinf") || same (p, n, "__builtin_isinf_sign") || same (p, n, "__builtin_isfinite")
      || same (p, n, "__builtin_signbit") || same (p, n, "__builtin_isnormal") || same (p, n, "__builtin_fpclassify") || same (p, n, "__builtin_issignaling")) return BA_FPCLASS;
  return BA_NORMAL;
}
static int cs_builtin_is (struct cs_ex *e, char *name) { return e->k == E_REF && same (e->name, e->nlen, name); }

/* ---- calls ---- */
static int cs_atomic_form (unsigned char *p, long n)
{
  /* 1 Load, 2 LoadCopy, 3 Copy, 4 Arithmetic, 5 Xchg, 6 GNUXchg, 7 GNUCmpXchg; +10 not _n (by address) */
  if (same (p, n, "__atomic_load_n")) return 1;
  if (same (p, n, "__atomic_load")) return 12;
  if (same (p, n, "__atomic_store_n")) return 3;
  if (same (p, n, "__atomic_store")) return 13;
  if (same (p, n, "__atomic_exchange_n")) return 5;
  if (same (p, n, "__atomic_exchange")) return 16;
  if (same (p, n, "__atomic_compare_exchange_n")) return 7;
  if (same (p, n, "__atomic_compare_exchange")) return 17;
  if (n > 13 && same (p, 13, "__atomic_fetc")) return 4;
  if (same (p, n, "__atomic_add_fetch") || same (p, n, "__atomic_sub_fetch") || same (p, n, "__atomic_and_fetch") || same (p, n, "__atomic_or_fetch")
      || same (p, n, "__atomic_xor_fetch") || same (p, n, "__atomic_nand_fetch") || same (p, n, "__atomic_max_fetch") || same (p, n, "__atomic_min_fetch")) return 4;
  return 0;
}
static struct cs_ex *cs_atomic_call (struct node *n, int form)
{
  int byaddr = form > 10, f = form % 10;
  long na = n->count - 1, i, nvals = 1;
  struct cs_ex *a[8], *e;
  struct cs_ty *vt, *byval, *res;
  if (na > 8) na = 8;
  if (f == 1) nvals = 0;
  if (f == 6) nvals = 2;
  if (f == 7) nvals = 3;
  i = 0;
  while (i < na) { a[i] = cs_ex_of (n->kids[i + 1]); i++; }
  a[0] = cs_rv (a[0]);
  vt = cs_unqual (cs_canon (a[0]->t)->to);
  if (cs_kind (vt) == TY_ATOMIC) vt = cs_canon (vt)->to;
  byval = vt;
  if (byaddr) byval = cs_ptr_to (vt);
  res = vt;
  if (f == 2 || f == 3 || f == 6) res = cs_basic (TY_VOID);
  if (f == 7) res = cs_basic (TY_BOOL);
  i = 1;
  while (i < na) {
    struct cs_ty *t;
    if (i <= nvals) {
      if (i == 1) {
        if (f == 4) { t = vt; if (cs_is_ptr (vt)) t = T->ptrdifft; }
        else if (f == 3 || f == 5) t = byval;
        else t = cs_ptr_to (vt);
        if (f == 6) t = byval;
      } else if (i == 2) t = byval;
      else t = cs_basic (TY_BOOL);
    } else t = cs_basic (TY_INT);
    a[i] = cs_assign_conv (t, a[i]);
    i++;
  }
  e = cs_mk (E_ATOMIC, res, 0);
  e->name = n->kids[0]->text;
  e->nlen = n->kids[0]->len;
  cs_add (e, a[0]);
  if (f == 1) { if (na > 1) cs_add (e, a[1]); }
  else if (f == 2 || f == 3 || f == 4 || f == 5) { if (na > 2) cs_add (e, a[2]); cs_add (e, a[1]); }
  else if (f == 6) { if (na > 3) cs_add (e, a[3]); cs_add (e, a[1]); cs_add (e, a[2]); }
  else if (f == 7) { if (na > 5) { cs_add (e, a[4]); cs_add (e, a[1]); cs_add (e, a[5]); cs_add (e, a[2]); cs_add (e, a[3]); } }
  /* (of a volatile of a typedef's, which clang does not take off: pthread_spin_lock's; a no-op cast does) */
  if ((f == 1 || f == 5) && !(cs_canon (a[0]->t)->to->q & Q_VOLATILE) && (cs_canon (cs_canon (a[0]->t)->to)->q & Q_VOLATILE)) { e->t = cs_qual (res, Q_VOLATILE); return cs_ice (e, res, CK_NOOP); }
  return e;
}
/* a transparent union parameter: the argument as the member it fits, in a compound literal */
static struct cs_ex *cs_param_conv (struct cs_ty *pt, struct cs_ex *a)
{
  struct cs_ty *c = cs_canon (pt);
  if (c->k == TY_UNION && c->rec->transparent && !cs_same_ty (cs_unqual (pt), cs_unqual (a->t))) {
    struct cs_field *f = c->rec->first;
    struct cs_ex *r = cs_rv (a);
    while (f) {
      struct cs_ty *ft = cs_canon (f->t);
      if ((ft->k == TY_PTR && (cs_is_npc (a) || (cs_is_ptr (r->t) && (cs_compatible (cs_unqual (cs_canon (ft->to)), cs_unqual (cs_canon (cs_canon (r->t)->to))) || cs_is_void (ft->to) || cs_is_void (cs_canon (r->t)->to)))))
          || cs_same_ty (cs_unqual (ft), cs_unqual (r->t))) {
        struct cs_ex *il, *clit;
        struct cs_ex *x = cs_ice (r, f->t, cs_is_ptr (r->t) ? (cs_cvr_similar (r->t, f->t) ? CK_NOOP : CK_BITCAST) : cs_is_npc (a) ? CK_NULLTOPOINTER : CK_INTEGRALTOPOINTER);
        il = cs_mk1 (E_INIT, pt, 0, x);
        il->fd = f;
        clit = cs_mk1 (E_CLIT, pt, 0, il);
        return clit;
      }
      f = f->nxt;
    }
  }
  return cs_assign_conv (cs_unqual (pt), a);
}
static struct cs_decl *cs_overload (struct cs_decl *d, struct cs_ex *a)
{
  /* clang-prelude.h's __builtin_stdc_* overloads: the one of the argument's type */
  struct cs_decl *x = d;
  struct cs_ty *at = cs_unqual (cs_canon (cs_rv (a)->t));
  while (x) {
    if (x->t->np > 0 && cs_same_ty (cs_unqual (x->t->ps[0]), at)) return x;
    x = x->prev;
  }
  return d;
}
static struct cs_ex *cs_call (struct node *n)
{
  struct node *c = n->kids[0];
  struct cs_ex *f, *e, *args[64];
  struct cs_ty *ft;
  struct cs_decl *d = 0;
  long i, na = n->count - 1;
  int rule = BA_NORMAL;
  if (na > 64) cs_fail ("a call of more than 64 arguments", c);
  if (cs_is_ident (c)) {
    int form = cs_atomic_form (c->text, c->len);
    if (form) return cs_atomic_call (n, form);
  }
  if (cs_is_ident (c) && !cs_lookup (c->text, c->len, 0) && !same (c->text, c->len, "__func__")) {
    /* C89's implicit declaration, int f (), which clang makes too (a builtin of gcc's it has not) */
    struct cs_decl *idecl = alloc (sizeof (struct cs_decl));
    struct cs_ty *ityp = cs_ty_new (TY_FUNC);
    ityp->to = T->intt;
    idecl->k = DK_FUNC; idecl->name = c->text; idecl->nlen = c->len; idecl->t = ityp;
    cs_bind (idecl->name, idecl->nlen, 0, idecl);
  }
  i = 0;
  while (i < na) { args[i] = cs_ex_of (n->kids[i + 1]); i++; }
  f = cs_ex_of (c);
  if (f->k == E_REF && f->d && f->d->k == DK_FUNC && f->d->prev && na > 0 && f->nlen > 15 && same (f->name, 15, "__builtin_stdc_")) {
    f->d = cs_overload (f->d, args[0]);
    f->t = f->d->t;
  }
  if (f->k == E_REF && f->d && f->d->builtin) {
    d = f->d;
    f = cs_cast_force (f, cs_ptr_to (d->t), CK_BUILTINFNTOFNPTR);
    ft = cs_canon (d->t);
    rule = cs_builtin_rule (d);
  } else {
    f = cs_rv (f);
    ft = cs_canon (f->t);
    if (ft->k == TY_PTR) ft = cs_canon (ft->to);
  }
  if (ft->k != TY_FUNC) cs_fail ("a call of what is not a function", c);
  e = cs_mk (E_CALL, cs_unqual (ft->to), 0);
  cs_add (e, f);
  if (rule == BA_UAC && na == 2) cs_uac (&args[0], &args[1], 0);
  i = 0;
  while (i < na) {
    struct cs_ex *a = args[i];
    if (rule == BA_NONE && i < ft->np && T->target == 1) a = cs_rv (a);
    else if (rule == BA_NONE || rule == BA_UAC) ;
    else if (rule == BA_RVALUE) a = cs_rv (a);
    else if (rule == BA_FPCLASS && (i == na - 1)) a = cs_uuc (a);
    else if (ft->proto && i < ft->np) a = cs_param_conv (ft->ps[i], a);
    else a = cs_arg_promo (a);
    cs_add (e, a);
    i++;
  }
  return e;
}

/* ---- members ---- */
static struct cs_field *cs_find_field (struct cs_rec *r, unsigned char *p, long n, struct cs_field **path, long *np)
{
  struct cs_field *f = r->first;
  while (f) {
    if (f->name) { if (cs_eqb (f->name, f->nlen, p, n)) return f; }
    else if (f->width < 0 && cs_is_rec (f->t) && *np < 16) {
      long save = *np;
      struct cs_field *x;
      path[(*np)++] = f;
      x = cs_find_field (cs_canon (f->t)->rec, p, n, path, np);
      if (x) return x;
      *np = save;
    }
    f = f->nxt;
  }
  return 0;
}
static struct cs_ex *cs_member (struct node *n, int arrow)
{
  struct cs_ex *b = cs_ex_of (n->kids[0]);
  struct node *nm = n->kids[1];
  struct cs_ty *rty;
  struct cs_field *path[17], *f;
  long np = 0, i = 0;
  int q, lv;
  if (arrow) { b = cs_rv (b); rty = cs_canon (cs_canon (b->t)->to); lv = 1; }
  else { rty = cs_canon (b->t); lv = b->lv; }
  if (rty->k != TY_STRUCT && rty->k != TY_UNION) cs_fail ("a member of what is not a struct", nm);
  q = cs_quals (rty);
  f = cs_find_field (rty->rec, nm->text, nm->len, path, &np);
  if (!f) cs_fail ("no such member", nm);
  path[np] = f;
  while (i <= np) {
    struct cs_field *g = path[i];
    struct cs_ty *t = cs_qual (g->t, q);
    struct cs_ex *m = cs_mk1 (E_MEM, t, lv, b);
    m->name = g->name;
    m->nlen = g->nlen;
    m->fd = g;
    m->arrow = i == 0 && arrow;
    q = cs_quals (t);
    b = m;
    i++;
  }
  return b;
}

/* ---- operators ---- */
static struct cs_ex *cs_bin (char *op, struct cs_ty *t, struct cs_ex *l, struct cs_ex *r)
{
  struct cs_ex *e = cs_mk (E_BIN, t, 0);
  cs_named (e, op);
  cs_add (e, l);
  cs_add (e, r);
  return e;
}
static struct cs_ex *cs_compare (char *op, struct cs_ex *l, struct cs_ex *r)
{
  if (cs_is_arith (l->t) && cs_is_arith (r->t)) { cs_uac (&l, &r, 0); return cs_bin (op, T->intt, l, r); }
  l = cs_rv (l);
  r = cs_rv (r);
  /* (two vectors: a vector of the signed integers of the elements' size, clang's GetSignedVectorType) */
  if (cs_kind (l->t) == TY_VECTOR) {
    struct cs_ty *v = cs_ty_new (TY_VECTOR);
    long es = cs_ty_size (cs_canon (l->t)->to);
    v->n = cs_canon (l->t)->n;
    v->to = cs_basic (es == 8 ? TY_LLONG : es == 4 ? TY_INT : es == 2 ? TY_SHORT : TY_CHAR);
    return cs_bin (op, v, l, r);
  }
  {
    int ln = cs_is_npc (l), rn = cs_is_npc (r);
    if (cs_is_ptr (l->t) && cs_is_ptr (r->t)) {
      if (!cs_same_ty (cs_canon (cs_canon (l->t)->to), cs_canon (cs_canon (r->t)->to))) {
        int kk = CK_BITCAST;
        if (cs_ptr_as (l->t) != cs_ptr_as (r->t)) kk = CK_ADDRESSSPACECONVERSION;
        if (ln && !rn) l = cs_ice (l, r->t, kk); else r = cs_ice (r, l->t, kk);
      }
    } else if (cs_is_ptr (l->t) && cs_is_int (r->t)) r = cs_ice (r, l->t, rn ? CK_NULLTOPOINTER : CK_INTEGRALTOPOINTER);
    else if (cs_is_int (l->t) && cs_is_ptr (r->t)) l = cs_ice (l, r->t, ln ? CK_NULLTOPOINTER : CK_INTEGRALTOPOINTER);
  }
  return cs_bin (op, T->intt, l, r);
}
static struct cs_ex *cs_binary (char *op, struct cs_ex *l, struct cs_ex *r)
{
  struct cs_ty *t;
  if (same ((unsigned char *) op, cstrlen (op), "<") || same ((unsigned char *) op, cstrlen (op), ">") || same ((unsigned char *) op, cstrlen (op), "<=")
      || same ((unsigned char *) op, cstrlen (op), ">=") || same ((unsigned char *) op, cstrlen (op), "==") || same ((unsigned char *) op, cstrlen (op), "!="))
    return cs_compare (op, l, r);
  if (op[0] == '&' && op[1] == '&') { l = cs_uuc (l); r = cs_uuc (r); return cs_bin (op, T->intt, l, r); }
  if (op[0] == '|' && op[1] == '|') { l = cs_uuc (l); r = cs_uuc (r); return cs_bin (op, T->intt, l, r); }
  if (op[0] == ',') { l = cs_ignored (l); r = cs_rv (r); return cs_bin (op, r->t, l, r); }
  if ((op[0] == '<' || op[0] == '>') && op[1]) { l = cs_uuc (l); r = cs_uuc (r); return cs_bin (op, l->t, l, r); }
  t = cs_uac (&l, &r, 0);
  if (t && cs_is_arith (t)) return cs_bin (op, t, l, r);
  if (op[0] == '+') { if (cs_is_ptr (l->t)) return cs_bin (op, l->t, l, r); return cs_bin (op, r->t, l, r); }
  if (op[0] == '-') {
    if (cs_is_ptr (l->t) && cs_is_ptr (r->t)) return cs_bin (op, T->ptrdifft, l, r);
    return cs_bin (op, l->t, l, r);
  }
  return cs_bin (op, t ? t : l->t, l, r);
}
static struct cs_ex *cs_cassign (struct node *n, struct cs_ex *l, struct cs_ex *r)
{
  unsigned char *o = n->text;
  struct cs_ty *ct = 0, *clhs = 0;
  struct cs_ex *e;
  if (o[0] == '<' || o[0] == '>') {
    struct cs_ex *x = cs_uuc (l);
    ct = x->t;
    clhs = ct;
    r = cs_uuc (r);
  } else if (o[0] == '+' || o[0] == '-') {
    ct = cs_uac (&l, &r, 1);
    if (ct && cs_is_arith (ct)) clhs = ct;
    else {
      struct cs_ty *bfp = cs_bitfield_promo (l);
      clhs = l->t;
      if (bfp) clhs = bfp;
      else if (cs_is_int (l->t) && cs_promotable (l->t)) clhs = cs_promoted (l->t);
      ct = l->t;
    }
  } else { ct = cs_uac (&l, &r, 1); clhs = ct; }
  e = cs_mk (E_CASS, cs_unqual (l->t), 0);
  e->name = n->text;
  e->nlen = n->len;
  e->lhsty = l->t;
  if (clhs) e->lhsty = clhs;
  e->resty = l->t;
  if (ct) e->resty = ct;
  cs_add (e, l);
  cs_add (e, r);
  return e;
}
static struct cs_ty *cs_ptr_arms (struct cs_ex **l, struct cs_ex **r)
{
  struct cs_ty *lp = cs_canon (cs_canon ((*l)->t)->to), *rp = cs_canon (cs_canon ((*r)->t)->to), *res;
  int ql = cs_quals (lp), qr = cs_quals (rp);
  if (cs_is_void (lp) && cs_kind (rp) != TY_FUNC) {
    res = cs_ptr_to (cs_qual (lp, qr));
    *l = cs_ice (*l, res, CK_NOOP);
    *r = cs_ice (*r, res, CK_BITCAST);
    return res;
  }
  if (cs_is_void (rp) && cs_kind (lp) != TY_FUNC) {
    res = cs_ptr_to (cs_qual (rp, ql));
    *r = cs_ice (*r, res, CK_NOOP);
    *l = cs_ice (*l, res, CK_BITCAST);
    return res;
  }
  if (cs_compatible (cs_unqual (lp), cs_unqual (rp))) {
    res = cs_ptr_to (cs_qual (cs_composite (cs_unqual (cs_canon ((*l)->t)->to), cs_unqual (cs_canon ((*r)->t)->to)), ql | qr));
    *l = cs_ice (*l, res, CK_BITCAST);
    *r = cs_ice (*r, res, CK_BITCAST);
    return res;
  }
  res = T->vptr;
  *l = cs_ice (*l, res, CK_BITCAST);
  *r = cs_ice (*r, res, CK_BITCAST);
  return res;
}
static struct cs_ty *cs_arms (struct cs_ex **l, struct cs_ex **r)
{
  struct cs_ty *lt, *rty;
  *l = cs_uuc (*l);
  *r = cs_uuc (*r);
  lt = (*l)->t;
  rty = (*r)->t;
  if (cs_is_arith (lt) && cs_is_arith (rty)) {
    struct cs_ty *t = cs_uac (l, r, 0);
    int k;
    k = cs_scalar_kind (l, t);
    *l = cs_ice (*l, t, k);
    k = cs_scalar_kind (r, t);
    *r = cs_ice (*r, t, k);
    return t;
  }
  if (cs_is_rec (lt) && cs_is_rec (rty) && cs_canon (lt)->rec == cs_canon (rty)->rec) return cs_unqual (lt);
  if (cs_is_void (lt) || cs_is_void (rty)) {
    struct cs_ty *t = cs_is_void (rty) ? rty : lt;
    if (cs_is_void (lt) && cs_is_void (rty)) t = lt;
    *l = cs_ice (*l, t, CK_TOVOID);
    *r = cs_ice (*r, t, CK_TOVOID);
    return t;
  }
  if (cs_is_ptr (lt) && cs_is_npc (*r)) { *r = cs_ice (*r, lt, CK_NULLTOPOINTER); return lt; }
  if (cs_is_ptr (rty) && cs_is_npc (*l)) { *l = cs_ice (*l, rty, CK_NULLTOPOINTER); return rty; }
  if (cs_is_ptr (lt) && cs_is_ptr (rty)) return cs_ptr_arms (l, r);
  if (cs_is_ptr (lt) && cs_is_int (rty)) { *r = cs_ice (*r, lt, CK_INTEGRALTOPOINTER); return lt; }
  if (cs_is_ptr (rty) && cs_is_int (lt)) { *l = cs_ice (*l, rty, CK_INTEGRALTOPOINTER); return rty; }
  return lt;
}
static struct cs_ex *cs_unary (struct node *n)
{
  struct cs_ex *o, *e;
  unsigned char *t = n->text;
  long len = n->len;
  if (same (t, len, "&&")) { e = cs_mk (E_ADDRLABEL, T->vptr, 0); e->name = n->kids[0]->text; e->nlen = n->kids[0]->len; e->lk = cs_label_k (e->name, e->nlen); return e; }
  o = cs_ex_of (n->kids[0]);
  if (same (t, len, "&")) { e = cs_mk1 (E_UN, cs_ptr_to (o->t), 0, o); return cs_named (e, "&"); }
  if (same (t, len, "*")) {
    struct cs_ty *p;
    o = cs_uuc (o);
    p = cs_canon (o->t);
    if (p->k != TY_PTR) cs_fail ("* of what is not a pointer", n);
    e = cs_mk1 (E_UN, p->to, !(cs_kind (p->to) == TY_FUNC || (cs_is_void (p->to) && !cs_quals (p->to))), o);
    return cs_named (e, "*");
  }
  if (same (t, len, "+") || same (t, len, "-") || same (t, len, "~")) { o = cs_uuc (o); e = cs_mk1 (E_UN, o->t, 0, o); e->name = t; e->nlen = len; return e; }
  if (same (t, len, "!")) { o = cs_rv (o); e = cs_mk1 (E_UN, T->intt, 0, o); return cs_named (e, "!"); }
  if (same (t, len, "++") || same (t, len, "--")) { e = cs_mk1 (E_UN, cs_unqual (o->t), 0, o); e->name = t; e->nlen = len; return e; }
  if (same (t, len, "post ++")) { e = cs_mk1 (E_UN, cs_unqual (o->t), 0, o); return cs_named (e, "post++"); }
  if (same (t, len, "post --")) { e = cs_mk1 (E_UN, cs_unqual (o->t), 0, o); return cs_named (e, "post--"); }
  if (same (t, len, "__extension__")) { e = cs_mk1 (E_UN, o->t, o->lv, o); return cs_named (e, "__extension__"); }
  if (t[0] == '_' && t[2] == 'r') {
    struct cs_ty *ty = cs_is_complex (o->t) ? cs_canon (o->t)->to : o->t;
    e = cs_mk1 (E_UN, ty, o->lv, o);
    return cs_named (e, "__real");
  }
  if (t[0] == '_' && t[2] == 'i') {
    struct cs_ty *ty = cs_is_complex (o->t) ? cs_canon (o->t)->to : o->t;
    e = cs_mk1 (E_UN, ty, o->lv && cs_is_complex (o->t), o);
    return cs_named (e, "__imag");
  }
  cs_fail ("an operator csema does not know", n);
  return 0;
}
static struct cs_ex *cs_size_of (struct node *n)
{
  struct node *k = n->kids[0];
  struct cs_ex *e = cs_mk (E_SIZEOF, T->sizet, 0);
  struct cs_ty *t;
  int isal = n->text[0] == '_' || n->text[0] == 'a';
  if (same (n->text, n->len, "sizeof")) { cs_named (e, "sizeof"); isal = 0; }
  else if (same (n->text, n->len, "_Alignof") || same (n->text, n->len, "alignof")) cs_named (e, "alignof");
  else cs_named (e, "__alignof");
  if (cs_is (k, "type")) { t = cs_type_in_ex (k); e->lhsty = t; }
  else {
    struct cs_ex *a = cs_ex_of (k);
    cs_add (e, a);
    t = a->t;
    if (isal && a->k == E_REF && a->d && a->d->algn) { e->val = a->d->algn > cs_ty_align (t) ? a->d->algn : cs_ty_align (t); e->isval = 1; return e; }
    if (isal && a->k == E_MEM && a->fd && a->fd->algn) { e->val = a->fd->algn > cs_ty_align (t) ? a->fd->algn : cs_ty_align (t); e->isval = 1; return e; }
  }
  e->val = isal ? cs_ty_align (t) : cs_ty_size (t);
  e->isval = !(cs_canon (t)->k == TY_ARRAY && cs_canon (t)->n == -2);
  return e;
}
static struct cs_ex *cs_cast (struct node *n)
{
  struct cs_ty *t = cs_type_in_ex (n->kids[0]);
  struct cs_ex *v = cs_ex_of (n->kids[1]), *e;
  int k;
  if (cs_is_void (t)) { v = cs_ignored (v); k = CK_TOVOID; }
  else {
    v = cs_rv (v);
    if (cs_kind (t) == TY_VECTOR || cs_kind (v->t) == TY_VECTOR) k = cs_is_scalar (v->t) && cs_kind (t) == TY_VECTOR && cs_ty_size (v->t) != cs_ty_size (t) ? CK_VECTORSPLAT : CK_BITCAST;
    else if (!cs_is_scalar (t)) k = cs_is_rec (t) && cs_same_ty (cs_unqual (t), cs_unqual (v->t)) ? CK_NOOP : cs_kind (t) == TY_UNION ? CK_TOUNION : CK_NOOP;
    else k = cs_scalar_kind (&v, t);
  }
  e = cs_mk1 (E_CAST, cs_unqual (t), 0, v);
  e->op = k;
  return e;
}
static struct cs_ex *cs_offset_of (struct node *n)
{
  struct cs_ty *t = cs_type_in_ex (n->kids[0]);
  struct cs_ex *e = cs_mk (E_OFFSETOF, T->sizet, 0);
  e->lhsty = t;
  long long off = 0;
  long i = 1;
  while (i < n->count) {
    struct node *k = n->kids[i];
    struct cs_ty *c = cs_canon (t);
    if (cs_is (k, "[]")) {
      long long v = 0;
      struct cs_ex *x = cs_lval_conv (cs_ex_of (k->kids[0]));
      cs_add (e, x);
      cs_eval (x, &v);
      if (c->k == TY_ARRAY) { t = c->to; off += v * cs_ty_size (t) * 8; }
    } else {
      struct node *nm = cs_is (k, ".") ? k->kids[0] : k;
      struct cs_field *path[17], *f;
      long np = 0, j = 0;
      if (c->k != TY_STRUCT && c->k != TY_UNION) cs_fail ("offsetof in what is not a struct", nm);
      cs_layout (c->rec);
      f = cs_find_field (c->rec, nm->text, nm->len, path, &np);
      if (!f) cs_fail ("offsetof: no such member", nm);
      while (j < np) { cs_layout (cs_canon (path[j]->t)->rec); off += path[j]->off; j++; }
      off += f->off;
      t = f->t;
    }
    i++;
  }
  e->val = off / 8;
  e->isval = 1;
  e->src = n;
  return e;
}
static struct cs_ex *cs_ex_of1 (struct node *n);
static struct cs_ex *cs_ex_of (struct node *n)
{
  struct cs_ex *e = cs_ex_of1 (n);
  e->paren = c_parens_of (n);
  return e;
}
/* C11's _Generic: the association of x's type (x as its value is, lvalue, array and function conversions made), else its default */
static struct cs_ex *cs_generic (struct node *n)
{
  struct cs_ex *r = cs_rv (cs_ex_of (n->kids[0])), *e;
  struct cs_ty *ct = cs_unqual (cs_canon (r->t));
  long na = n->count - 1, i = 0, sel = 0 - 1, def = 0 - 1;
  struct cs_ty **tys = alloc ((na + 1) * sizeof (struct cs_ty *));
  struct cs_ex **vals = alloc ((na + 1) * sizeof (struct cs_ex *));
  while (i < na) {
    struct node *a = n->kids[i + 1];
    if (cs_is (a->kids[0], "default")) def = i;
    else {
      tys[i] = cs_type_in_ex (a->kids[0]);
      if (sel < 0 && cs_compatible (cs_unqual (cs_canon (tys[i])), ct)) sel = i;
    }
    vals[i] = cs_ex_of (a->kids[1]);
    i++;
  }
  if (sel < 0) sel = def;
  if (sel < 0) c_fail ("a _Generic with no association of its type");
  e = cs_mk (E_GENERIC, vals[sel]->t, vals[sel]->lv);
  cs_add (e, r);
  i = 0;
  while (i < na) { cs_add (e, vals[i]); i++; }
  e->val = sel;
  e->tys = tys;
  return e;
}
static struct cs_ex *cs_ex_of1 (struct node *n)
{
  unsigned char *t = n->text;
  long len = n->len, c = n->count;
  if (cs_is (n, "_Generic")) return cs_generic (n);
  if (c == 0 || cs_is (n, "token") || cs_is (n, "str")) return cs_leaf (n);
  if (same (t, len, "()")) return cs_call (n);
  if (same (t, len, ".") && c == 2) return cs_member (n, 0);
  if (same (t, len, "->") && c == 2) return cs_member (n, 1);
  if (same (t, len, "[]") && c == 2) {
    struct cs_ex *l = cs_rv (cs_ex_of (n->kids[0])), *r = cs_rv (cs_ex_of (n->kids[1])), *e;
    struct cs_ty *et = cs_is_ptr (l->t) ? cs_canon (l->t)->to : cs_is_ptr (r->t) ? cs_canon (r->t)->to : 0;
    if (!et) cs_fail ("[] of what is not a pointer", n);
    e = cs_mk (E_IDX, et, !(cs_kind (et) == TY_FUNC || (cs_is_void (et) && !cs_quals (et))));
    cs_add (e, l);
    cs_add (e, r);
    return e;
  }
  if (same (t, len, "cast")) return cs_cast (n);
  if (same (t, len, "sizeof") || same (t, len, "_Alignof") || same (t, len, "alignof") || same (t, len, "__alignof__") || same (t, len, "__alignof")) return cs_size_of (n);
  if (same (t, len, "compound literal")) {
    struct cs_ty *ty = cs_type_in_ex (n->kids[0]);
    struct cs_ex *il = cs_init_braced (ty, n->kids[1]);
    if (!T->fn && il->k == E_INIT) {
      /* a compound literal of static storage: each initializer a constant expression */
      long j = 0;
      while (j < il->nk) { il->kid[j] = cs_constant (il->kid[j]); il->kid[j]->isnull = 1; j++; }
    }
    return cs_mk1 (E_CLIT, cs_canon (ty)->k == TY_ARRAY && cs_canon (ty)->n < 0 ? il->t : ty, 1, il);
  }
  if (same (t, len, "stmt expr")) return cs_stmt_expr (n->kids[0]);
  if (same (t, len, "?") && c == 3) {
    struct cs_ex *cd = cs_uuc (cs_ex_of (n->kids[0])), *l = cs_ex_of (n->kids[1]), *r = cs_ex_of (n->kids[2]), *e;
    struct cs_ty *ty = cs_arms (&l, &r);
    e = cs_mk (E_COND, ty, 0);
    cs_add (e, cd);
    cs_add (e, l);
    cs_add (e, r);
    return e;
  }
  if (same (t, len, "?:") && c == 2) {
    struct cs_ex *cm = cs_uuc (cs_ex_of (n->kids[0])), *ov = cs_mk (E_OVE, cm->t, cm->lv), *l = ov, *r = cs_ex_of (n->kids[1]), *e;
    struct cs_ty *ty = cs_arms (&l, &r);
    e = cs_mk (E_BCOND, ty, 0);
    cs_add (e, cm);
    cs_add (e, ov);
    cs_add (e, l);
    cs_add (e, r);
    return e;
  }
  if (same (t, len, "__builtin_offsetof")) return cs_offset_of (n);
  if (same (t, len, "__builtin_va_arg")) {
    struct cs_ex *a = cs_ex_of (n->kids[0]);
    struct cs_ty *ty = cs_type_in_ex (n->kids[1]);
    if (cs_kind (a->t) == TY_ARRAY || T->target == 1) a = cs_rv (a);
    return cs_mk1 (E_VAARG, cs_unqual (ty), 0, a);
  }
  if (same (t, len, "__builtin_types_compatible_p")) {
    struct cs_ty *a = cs_type_in_ex (n->kids[0]), *b = cs_type_in_ex (n->kids[1]);
    struct cs_ex *e = cs_mk (E_TRAIT, T->intt, 0);
    e->val = cs_compatible (cs_unqual (cs_canon (a)), cs_unqual (cs_canon (b)));
    e->isval = 1;
    return e;
  }
  if (c == 2 && !(same (t, len, "&&") && cs_is (n, "&&") && 0)) {
    struct cs_ex *l, *r;
    if (same (t, len, "=")) {
      l = cs_ex_of (n->kids[0]);
      r = cs_assign_conv (l->t, cs_ex_of (n->kids[1]));
      return cs_bin ("=", cs_unqual (l->t), l, r);
    }
    if (len >= 2 && t[len - 1] == '=' && !same (t, len, "==") && !same (t, len, "!=") && !same (t, len, "<=") && !same (t, len, ">=")) {
      l = cs_ex_of (n->kids[0]);
      r = cs_ex_of (n->kids[1]);
      return cs_cassign (n, l, r);
    }
    l = cs_ex_of (n->kids[0]);
    r = cs_ex_of (n->kids[1]);
    {
      static char *ops[] = { "*", "/", "%", "+", "-", "<<", ">>", "<", ">", "<=", ">=", "==", "!=", "&", "^", "|", "&&", "||", ",", 0 };
      char *op = 0;
      long q = 0;
      while (ops[q]) { if (same (t, len, ops[q])) { op = ops[q]; break; } q++; }
      if (!op) cs_fail ("an operator csema does not know", n);
      return cs_binary (op, l, r);
    }
  }
  if (c == 1) return cs_unary (n);
  cs_fail ("an expression csema does not know", n);
  return 0;
}

/* ---- initializers (clang's InitListChecker, its semantic form) ---- */
struct cs_cur { struct node *list; long i; long dpos; struct cs_ex *pend; long pendi; };
static struct node *cs_item_of (struct cs_cur *c) { return c->i < c->list->count ? c->list->kids[c->i] : 0; }
static long cs_ndesig (struct node *it) { return cs_is (it, "designated") ? it->count - 1 : 0; }
static struct node *cs_value_of (struct node *it) { return cs_is (it, "designated") ? it->kids[it->count - 1] : it; }
static void cs_next_item (struct cs_cur *c) { c->i++; c->dpos = 0; }
static struct cs_ex *cs_item_ex (struct cs_cur *c)
{
  if (c->pend && c->pendi == c->i) return c->pend;
  c->pend = cs_ex_of (cs_value_of (cs_item_of (c)));
  c->pendi = c->i;
  return c->pend;
}
static int cs_is_char_array (struct cs_ty *t)
{
  struct cs_ty *c = cs_canon (t);
  int k;
  if (c->k != TY_ARRAY) return 0;
  k = cs_kind (c->to);
  return k == TY_CHAR || k == TY_SCHAR || k == TY_UCHAR || k == T->wchar_k || k == TY_USHORT || k == TY_UINT || k == TY_INT;
}
static int cs_str_of (struct cs_ex *e) { while (e->k == E_UN && same (e->name, e->nlen, "__extension__")) e = e->kid[0]; return e->k == E_STR || e->k == E_PREDEF; }
/* a string literal initializing an array: the array's type, a prvalue (clang's updateStringLiteralType) */
static struct cs_ex *cs_str_into (struct cs_ex *e, struct cs_ty *t)
{
  struct cs_ex *x = e;
  for (;;) { x->t = t; x->lv = 0; if (x->k == E_UN && same (x->name, x->nlen, "__extension__")) x = x->kid[0]; else break; }
  return e;
}
static void cs_fill (struct cs_ty *t, struct cs_ex *il, struct cs_ex **slots, long *nslot, struct cs_cur *c, int mode);
static struct cs_ex *cs_sub_list (struct cs_ty *t, struct cs_ex *old)
{
  if (old && old->k == E_INIT) return old;
  return cs_mk (E_INIT, cs_unqual (t), 0);
}
/* the next item(s) as the initializer of an object of type t */
static struct cs_ex *cs_elem (struct cs_ty *t, struct cs_ex *old, struct cs_cur *c)
{
  struct node *it = cs_item_of (c);
  struct node *v = cs_value_of (it);
  if (c->dpos < cs_ndesig (it)) {
    /* designators left: they go into this subobject */
    struct cs_ex *sub = cs_sub_list (t, old);
    cs_fill (t, sub, 0, 0, c, 2);
    return sub;
  }
  if (cs_is (v, "{}") && v->count >= 0 && !(c->pend && c->pendi == c->i)) {
    struct cs_ex *r = cs_init_braced (t, v);
    cs_next_item (c);
    return r;
  }
  if (cs_is_scalar (t) || cs_kind (t) == TY_VECTOR) {
    struct cs_ex *r = cs_assign_conv (t, cs_item_ex (c));
    cs_next_item (c);
    return r;
  }
  {
    struct cs_ex *e = cs_item_ex (c);
    if (cs_is_char_array (t) && cs_str_of (e)) {
      struct cs_ty *ct = cs_canon (t);
      cs_next_item (c);
      return cs_str_into (e, ct->n < 0 ? cs_array_of (ct->to, cs_canon (e->t)->n) : t);
    }
    if (cs_is_rec (t) && cs_is_rec (e->t) && cs_canon (t)->rec == cs_canon (e->t)->rec) { cs_next_item (c); return cs_assign_conv (t, e); }
    {
      struct cs_ex *sub = cs_sub_list (t, old);
      cs_fill (t, sub, 0, 0, c, 0);
      return sub;
    }
  }
}
static long cs_rec_count (struct cs_rec *r)
{
  struct cs_field *f = r->first;
  long n = 0;
  while (f) { if (f->name || f->width < 0) n++; f = f->nxt; }
  return n;
}
/* fill il, an InitListExpr of type t, from the items at c; mode 1 explicit braces, 0 brace elision (stops when full or at a
   designator), 2 one designated cs_item (its designators from c->dpos) */
static void cs_fill (struct cs_ty *t, struct cs_ex *il, struct cs_ex **slots0, long *nslot0, struct cs_cur *c, int mode)
{
  struct cs_ty *ct = cs_canon (t);
  long n = 0, idx = 0, maxn = 0, i;
  struct cs_ex **slots;
  struct cs_field **flds = 0;
  int un = ct->k == TY_UNION, isrec = ct->k == TY_STRUCT || un;
  long long cap = -1;
  if (isrec) {
    struct cs_field *f = ct->rec->first;
    n = cs_rec_count (ct->rec);
    flds = alloc ((n + 1) * sizeof (struct cs_field *));
    i = 0;
    while (f) { if (f->name || f->width < 0) flds[i++] = f; f = f->nxt; }
    cap = n;
  } else if (ct->k == TY_ARRAY) cap = ct->n;
  else if (ct->k == TY_VECTOR) cap = ct->n / cs_ty_size (ct->to);
  else cap = 1;
  maxn = il->nk;
  slots = alloc ((maxn + 16) * sizeof (struct cs_ex *));
  {
    long room = maxn + 16;
    i = 0;
    while (i < il->nk) { slots[i] = il->kid[i]; i++; }
    if (isrec) idx = 0;
    while (cs_item_of (c)) {
      struct node *it = cs_item_of (c);
      long ndd = cs_ndesig (it);
      struct cs_ty *et;
      if (c->dpos < ndd) {
        struct node *d = it->kids[c->dpos];
        if (mode == 0 && c->dpos == 0) break;
        if (mode == 1 || mode == 2 || c->dpos > 0) {
          if (cs_is (d, ".")) {
            struct cs_field *path[17], *f;
            long np = 0, j;
            if (!isrec) cs_fail ("a designator . of what is not a struct", d);
            f = cs_find_field (ct->rec, d->kids[0]->text, d->kids[0]->len, path, &np);
            if (!f) cs_fail ("no such member to initialize", d->kids[0]);
            if (np > 0) {
              /* an anonymous member's: the designator again in it */
              j = 0;
              while (j < n && flds[j] != path[0]) j++;
              idx = j;
            } else {
              j = 0;
              while (j < n && flds[j] != f) j++;
              idx = j;
              c->dpos++;
            }
          } else if (cs_is (d, "[]") || cs_is (d, "[...]")) {
            long long v = 0, hi;
            struct cs_ex *x = cs_ex_of (d->kids[0]);
            cs_eval (x, &v);
            hi = v;
            if (cs_is (d, "[...]")) { struct cs_ex *y = cs_ex_of (d->kids[1]); cs_eval (y, &hi); }
            idx = v;
            c->dpos++;
            if (hi > v) {
              /* a range: every element the same initializer */
              struct cs_ex *r;
              while (idx >= room) { struct cs_ex **m = alloc (room * 2 * sizeof (struct cs_ex *)); long q = 0; while (q < room) { m[q] = slots[q]; q++; } slots = m; room *= 2; }
              et = ct->to;
              r = cs_elem (et, idx < maxn ? slots[idx] : 0, c);
              while (idx <= hi) {
                while (idx >= room) { struct cs_ex **m = alloc (room * 2 * sizeof (struct cs_ex *)); long q = 0; while (q < room) { m[q] = slots[q]; q++; } slots = m; room *= 2; }
                while (maxn < idx) slots[maxn++] = 0;
                slots[idx] = r;
                if (idx + 1 > maxn) maxn = idx + 1;
                idx++;
              }
              if (mode == 2) break;
              continue;
            }
          }
        }
      } else if (mode == 2) break;
      if (cap >= 0 && idx >= cap) { if (mode == 1) { cs_next_item (c); continue; } break; }
      et = isrec ? flds[idx]->t : ct->k == TY_ARRAY || ct->k == TY_VECTOR ? ct->to : t;
      while (idx >= room) { struct cs_ex **m = alloc (room * 2 * sizeof (struct cs_ex *)); long q = 0; while (q < room) { m[q] = slots[q]; q++; } slots = m; room *= 2; }
      while (maxn < idx) slots[maxn++] = 0;
      if (idx == maxn) slots[maxn++] = 0;
      slots[idx] = cs_elem (et, slots[idx], c);
      idx++;
      if (un) { if (mode != 1) break; idx = cap; }
      if (mode == 2) break;
    }
  }
  /* the semantic form: a struct's every field (implicit value inits), a union's one, an array's holes */
  il->nk = 0;
  if (isrec && !un) {
    i = 0;
    while (i < n) { cs_add (il, i < maxn && slots[i] ? slots[i] : cs_mk (E_IVI, flds[i]->t, 0)); i++; }
  } else if (un) {
    i = 0;
    while (i < maxn && !slots[i]) i++;
    if (i < maxn) cs_add (il, slots[i]);
    if (i < maxn && i > 0) il->fd = flds[i];
  } else {
    struct cs_ex *filler = 0;
    i = 0;
    while (i < maxn) {
      if (!slots[i]) { if (!filler) filler = cs_mk (E_IVI, ct->k == TY_ARRAY || ct->k == TY_VECTOR ? ct->to : t, 0); cs_add (il, filler); }
      else cs_add (il, slots[i]);
      i++;
    }
    if (ct->k == TY_ARRAY && ct->n < 0) il->t = cs_array_of (ct->to, maxn);
  }
}
static struct cs_ex *cs_init_braced (struct cs_ty *t, struct node *list)
{
  struct cs_ex *il = cs_mk (E_INIT, cs_unqual (t), 0);
  struct cs_cur c;
  c.list = list; c.i = 0; c.dpos = 0; c.pend = 0; c.pendi = -1;
  if (cs_is_scalar (t) && list->count > 0) {
    struct node *v = cs_value_of (list->kids[0]);
    if (cs_is (v, "{}")) cs_add (il, cs_init_braced (t, v));
    else cs_add (il, cs_assign_conv (t, cs_ex_of (v)));
    return il;
  }
  if (cs_is_char_array (t) && list->count == 1 && !cs_is (list->kids[0], "designated") && !cs_is (list->kids[0], "{}")) {
    struct cs_ex *e = cs_item_ex (&c);
    if (cs_str_of (e)) {
      struct cs_ty *ct = cs_canon (t);
      if (ct->n < 0) il->t = cs_canon (e->t)->k == TY_ARRAY ? cs_array_of (ct->to, cs_canon (e->t)->n) : t;
      cs_add (il, cs_str_into (e, il->t));
      return il;
    }
  }
  cs_fill (t, il, 0, 0, &c, 1);
  return il;
}
/* an object's initializer: the expression converted, a string into its array, or the list */
static struct cs_ex *cs_init_of (struct cs_ty *t, struct node *v, struct cs_ty **done)
{
  struct cs_ex *e;
  *done = t;
  if (cs_is (v, "{}")) { e = cs_init_braced (t, v); *done = cs_canon (t)->k == TY_ARRAY && cs_canon (t)->n < 0 ? e->t : t; return e; }
  e = cs_ex_of (v);
  if (cs_is_char_array (t) && cs_str_of (e)) {
    struct cs_ty *ct = cs_canon (t);
    if (ct->n < 0) *done = cs_array_of (ct->to, cs_canon (e->t)->n);
    return cs_str_into (e, *done);
  }
  if (cs_canon (t)->k == TY_ARRAY) return e;
  return cs_assign_conv (t, e);
}
