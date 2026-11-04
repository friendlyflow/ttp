/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cl_w.c (in cs.c): the words of now, as gen/Words.pm's newwords: what was made in the words of before, written in them */
struct cl_wf { char *name; struct cl_list *run; int pad, anon; };
struct cl_wrec { char *kind; struct cl_wf **f; long nf; };
static int cl_w_scalar (char *s)
{
  static char *w[] = { "char", "short", "int", "long", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64", "i128", "u128", "float16", "bfloat16", "short fract", "fract", "long fract", "short accum", "accum", "long accum", "unsigned short fract", "unsigned fract", "unsigned long fract", "unsigned short accum", "unsigned accum", "unsigned long accum", "sat short fract", "sat fract", "sat long fract", "sat short accum", "sat accum", "sat long accum", "sat unsigned short fract", "sat unsigned fract", "sat unsigned long fract", "sat unsigned short accum", "sat unsigned accum", "sat unsigned long accum", "void", "type", "va_list", "float", "double", "long double", "float128", 0 };
  long i = 0;
  while (w[i]) { if (cl_eq (s, w[i])) return 1; i++; }
  return 0;
}
static long cl_opix (char *s)
{
  static char *w[] = { "=", "+=", "-=", "||", "&&", "|", "^", "&", "==", "!=", "<", ">", "<=", ">=", "<<", ">>", "+", "-", "*", "/", "%", "++", "--", "!", "~", "*=", "/=", "%=", "&=", "|=", "^=", "<<=", ">>=", "?", 0 };
  long i = 0;
  while (w[i]) { if (cl_eq (s, w[i])) return i; i++; }
  return 0 - 1;
}
static char *cl_suffix_type (char *s)
{
  if (cl_eq (s, "U")) return "u32";
  if (cl_eq (s, "L")) return "long";
  if (cl_eq (s, "UL")) return "u64";
  if (cl_eq (s, "LL")) return "i64";
  if (cl_eq (s, "ULL")) return "u64";
  return 0;
}
static char *cl_tosuffix (char *s)
{
  if (cl_eq (s, "u32")) return "U";
  if (cl_eq (s, "long")) return "L";
  if (cl_eq (s, "u64")) return "ULL";
  if (cl_eq (s, "i64")) return "LL";
  return 0;
}
/* /^-?(?:\d+|0x[0-9a-fA-F]+)$/ */
static int cl_is_num (char *s) { return cl_reads_number (s); }
static long long cl_oct_or_dec (char *s)
{
  long long v = 0;
  long i = 0;
  if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) { i = 2; while (s[i]) { v = v * 16 + cs_digitv (s[i]); i++; } return v; }
  while (s[i]) { v = v * 10 + (s[i] - '0'); i++; }
  return v;
}
static char *cl_txt (struct node *n) { return (char *) n->text; }
static int cl_ends_colon (char *s) { long n = cstrlen (s); return n > 0 && s[n - 1] == ':'; }
/* /.:$/ */
static int cl_named_colon (char *s) { long n = cstrlen (s); return n > 1 && s[n - 1] == ':'; }
static char *cl_no_colon (char *s) { long n = cstrlen (s); return cl_copy ((unsigned char *) s, n - 1); }
/* /^\d+:$/ */
static int cl_is_layer (char *s) { long n = cstrlen (s), i = 0; if (n < 2 || s[n - 1] != ':') return 0; while (i < n - 1) { if (!cl_digit (s[i])) return 0; i++; } return 1; }
static int cl_is_record_word (char *s) { return cl_eq (s, "struct") || cl_eq (s, "union") || cl_eq (s, "enum") || cl_eq (s, "function"); }
static int cl_is_align (struct node *n) { return n && cl_is (n, "align") && n->count == 1 && cl_leaf (n->kids[0]); }
static int cl_is_cleanup (struct node *n) { return n && cl_is (n, "cleanup") && n->count == 1 && cl_leaf (n->kids[0]); }
static struct cl_wf *cl_field (struct node *f)
{
  struct cl_wf *w = alloc (sizeof (struct cl_wf));
  char *name = cl_no_colon (cl_txt (f));
  struct cl_list *run = cl_l ();
  long i = 0;
  int pad;
  if (f->count && cl_is_align (f->kids[0])) i = 1;
  while (i < f->count) { cl_push (run, f->kids[i]); i++; }
  /* /^padding \d+$/ */
  pad = cl_starts (name, "padding ") && cl_all_digits (name + 8);
  if (!pad && !name[0] && run->n && cl_leaf (run->v[0]) && cl_w_scalar (cl_txt (run->v[0]))) pad = 1;
  w->name = name;
  w->run = run;
  w->pad = pad;
  w->anon = !name[0] && !pad;
  return w;
}
static void cl_typenames (struct node *n)
{
  long i = 0;
  char *s = cl_txt (n);
  /* (base pcs before a function type's function: arm's pcs ("aapcs")) */
  if (cl_ends_colon (s) && cstrlen (s) > 1 && n->count > 1 && cl_isleaf (n->kids[0], "base pcs") && cl_isleaf (n->kids[1], "function")) cl_make (&C->word, cl_no_colon (s))->num = 1;
  else if (cl_ends_colon (s) && cstrlen (s) > 1 && n->count && cl_leaf (n->kids[0]) && cl_is_record_word (cl_txt (n->kids[0]))) {
    char *name = cl_no_colon (s), *kind = cl_txt (n->kids[0]);
    cl_make (&C->word, name)->num = 1;
    if (cl_eq (kind, "struct") || cl_eq (kind, "union")) {
      struct cl_wrec *r = alloc (sizeof (struct cl_wrec));
      long k = 1;
      r->kind = kind;
      r->f = alloc ((n->count + 1) * sizeof (struct cl_wf *));
      while (k < n->count) { if (cl_ends_colon (cl_txt (n->kids[k]))) { r->f[r->nf] = cl_field (n->kids[k]); r->nf = r->nf + 1; } k++; }
      cl_put (&C->recw, name, r);
    }
  }
  while (i < n->count) { cl_typenames (n->kids[i]); i++; }
}
static int cl_word (char *s) { return cl_val (&C->word, s) != 0; }
static struct cl_list *cl_newnode (struct node *n, int ctx);
static void cl_newlist (struct cl_list *l, int ctx, struct cl_list *o);
enum { CX_NONE, CX_PAGE, CX_FN, CX_REC };
static int cl_is_prefix (struct node *n) { return (cl_leaf (n) && cl_suffix_type (cl_txt (n))) || (cl_is (n, "cast") && !cl_leaf (n)); }
static int cl_is_post (struct node *n) { return n && cl_leaf (n) && (cl_is (n, C->w_ptr) || cl_is (n, C->w_addr)); }
static long cl_lit_end (struct cl_list *l, long i);
static long cl_item_end (struct cl_list *l, long i, int lit)
{
  int want = 1;
  long q = 0;
  while (i < l->n) {
    struct node *n = l->v[i];
    long op = cl_leaf (n) ? cl_opix (cl_txt (n)) : 0 - 1;
    if (op >= 0) {
      if (op == 33) { q++; want = 1; }
      else if (op == 21 || op == 22) { }
      else if (op >= 25 || op <= 20) want = 1;
      else { if (!want) return i; want = 1; }
      i++;
      continue;
    }
    if (q && cl_isleaf (n, ":")) { q--; want = 1; i++; continue; }
    if (cl_is (n, "else") || cl_is (n, "else if") || (lit && cl_is_post (n))) { i++; continue; }
    if (lit && cl_is_prefix (n)) { if (!want) return i; want = 1; i++; continue; }
    if (!want) return i;
    want = 0;
    i++;
    if (lit) i = cl_lit_end (l, i - 1);
  }
  return i;
}
static long cl_places_count (char *name, int depth);
/* how many items follow a literal's head; 1 with it */
static int cl_lit_count (struct node *n, long *count)
{
  if ((cl_is (n, "array") || cl_is (n, "vector")) && !cl_leaf (n)) {
    struct node *c = n->kids[n->count - 1];
    if (cl_leaf (c) && cl_reads_number (cl_txt (c)) && cl_txt (c)[0] != '-') { *count = cl_oct_or_dec (cl_txt (c)); return 1; }
    return 0;
  }
  if (cl_leaf (n)) {
    struct cl_wrec *r = cl_get (&C->recw, cl_txt (n));
    if (!r) return 0;
    if (cl_eq (r->kind, "union")) { *count = 0 - 1; return 1; }
    *count = cl_places_count (cl_txt (n), 0);
    return 1;
  }
  return 0;
}
static long cl_lit_end (struct cl_list *l, long i)
{
  struct node *n = l->v[i];
  long k, j, m = 0, ab;
  if (!cl_lit_count (n, &k)) return i + 1;
  j = i + 1;
  if (k < 0) j++;
  ab = k < 0 ? 0 - k : k;
  while (m < ab) { j = cl_item_end (l, j, 1); m++; }
  return j;
}
static struct cl_wrec *cl_wrec_of (char *name)
{
  struct cl_wrec *r = cl_get (&C->recw, name);
  if (!r) cl_fail ("words: not a struct or a union:", name);
  return r;
}
static long cl_places_count (char *name, int depth)
{
  struct cl_wrec *r = cl_wrec_of (name);
  long i = 0, count = 0;
  if (depth > 32) cl_fail ("words: anonymous members nested too deep", 0);
  while (i < r->nf) {
    struct cl_wf *f = r->f[i];
    if (!f->pad) {
      if (f->anon) {
        struct cl_wrec *in = cl_get (&C->recw, cl_txt (f->run->v[0]));
        if (!in) cl_fail ("words: an anonymous member that is not a struct", 0);
        if (cl_eq (in->kind, "union")) cl_fail ("words: an anonymous union in a literal", 0);
        count = count + cl_places_count (cl_txt (f->run->v[0]), depth + 1);
      } else count++;
    }
    i++;
  }
  return count;
}
/* the old type run at i of l: its nodes now, *j the index after it; 0 if none */
static struct node *cl_newone (struct node *n, int ctx)
{
  struct cl_list *r = cl_newnode (n, ctx);
  if (r->n == 1) return r->v[0];
  return cl_nl (":", r);
}
static struct cl_list *cl_newrun (struct cl_list *l, long i, long *j)
{
  char *w;
  if (i >= l->n || !cl_leaf (l->v[i])) return 0;
  w = cl_txt (l->v[i]);
  if (cl_eq (w, "address")) {
    struct cl_list *in = cl_newrun (l, i + 1, j);
    if (in) { cl_push (in, cl_n (C->w_ptr)); return in; }
    in = cl_l ();
    cl_push (in, cl_n ("void"));
    cl_push (in, cl_n (C->w_ptr));
    *j = i + 1;
    return in;
  }
  if (cl_eq (w, "fs")) {
    struct cl_list *in = cl_newrun (l, i + 1, j);
    if (!in) return 0;
    cl_push (in, cl_n ("fs"));
    return in;
  }
  if (cl_eq (w, "array") || cl_eq (w, "vector")) {
    struct cl_list *in = cl_newrun (l, i + 1, j), *r;
    struct node *a;
    if (!in || *j >= l->n) return 0;
    a = cl_n (w);
    cl_add_all (a, in);
    if (!cl_isleaf (l->v[*j], "[]")) nd_add (a, cl_newone (l->v[*j], CX_FN));
    *j = *j + 1;
    r = cl_l ();
    cl_push (r, a);
    return r;
  }
  if (cl_word (w)) {
    struct cl_list *r = cl_l ();
    cl_push (r, cl_n (w));
    *j = i + 1;
    return r;
  }
  return 0;
}
static struct cl_list *cl_sub (struct node *n, long from)
{
  struct cl_list *l = cl_l ();
  long i = from;
  while (i < n->count) { cl_push (l, n->kids[i]); i++; }
  return l;
}
static struct cl_list *cl_slice (struct cl_list *x, long from, long to)
{
  struct cl_list *l = cl_l ();
  long i = from;
  while (i < to) { cl_push (l, x->v[i]); i++; }
  return l;
}
/* one operand of a prefix (pre) or a postfix */
static void cl_w_operand (int pre, struct cl_list *k, struct cl_list *o)
{
  struct cl_list *r;
  long i = 0, m;
  long cnt;
  if (k->n != 1) {
    struct cl_list *x = cl_l ();
    cl_newlist (k, CX_FN, x);
    cl_push (o, cl_nl (":", x));
    return;
  }
  r = cl_newnode (k->v[0], CX_FN);
  while (pre && i < r->n && cl_is_prefix (r->v[i])) i++;
  if (i < r->n && !cl_is_prefix (r->v[i]) && !cl_lit_count (r->v[i], &cnt)) {
    int ok = 1;
    m = i + 1;
    while (m < r->n) { if (!cl_is_post (r->v[m]) && !cl_isleaf (r->v[m], "++") && !cl_isleaf (r->v[m], "--")) ok = 0; m++; }
    if (ok) { cl_append (o, r); return; }
  }
  cl_push (o, cl_nl (":", r));
}
static int cl_textish (struct cl_list *r)
{
  if (r->n != 2 || !cl_leaf (r->v[0])) return 0;
  if (!(cl_is (r->v[0], "char") || cl_is (r->v[0], "u8") || cl_is (r->v[0], "i8"))) return 0;
  return cl_isleaf (r->v[1], C->w_ptr);
}
static long cl_dot_at (struct cl_list *k)
{
  long i = 0;
  while (i < k->n) { if (cl_isleaf (k->v[i], ".")) return i; i++; }
  return 0 - 1;
}
/* the shapes with_path takes */
enum { WP_CONTENT, WP_ADDRESS, WP_CASTA, WP_CAST, WP_WORD, WP_REC, WP_ARR };
static void cl_new_lit (struct cl_list *ty, struct cl_list *old, int depth, struct cl_list *o);
static void cl_wp_body (int how, struct cl_list *v, struct cl_list *ty, struct cl_list *o)
{
  if (how == WP_CONTENT) { cl_w_operand (0, v, o); cl_push (o, cl_n (C->w_ptr)); return; }
  if (how == WP_ADDRESS) { cl_w_operand (0, v, o); cl_push (o, cl_n (C->w_addr)); return; }
  if (how == WP_CASTA) {
    if (!v->n) cl_fail ("words: address of a type without a value", 0);
    cl_push (o, cl_nl ("cast", ty));
    if (v->n == 1 && cl_leaf (v->v[0]) && cl_textish (ty)) cl_push (o, v->v[0]);
    else cl_w_operand (1, v, o);
    return;
  }
  if (how == WP_CAST) {
    cl_push (o, cl_nl ("cast", ty));
    if (v->n == 1 && cl_leaf (v->v[0]) && cl_textish (ty)) cl_push (o, cl_n1 (":", v->v[0]));
    else cl_w_operand (1, v, o);
    return;
  }
  if (how == WP_WORD) {
    cl_push (o, cl_nl ("cast", ty));
    cl_w_operand (1, v, o);
    return;
  }
  cl_new_lit (ty, v, 0, o);
}
static void cl_with_path (int how, struct cl_list *k, struct cl_list *ty, struct cl_list *o)
{
  long dot = cl_dot_at (k);
  if (dot < 0) { cl_wp_body (how, k, ty, o); return; }
  {
    struct cl_list *x = cl_l (), *y = cl_slice (k, dot, k->n);
    cl_wp_body (how, cl_slice (k, 0, dot), ty, x);
    cl_newlist (y, CX_FN, x);
    cl_push (o, cl_nl (":", x));
  }
}
/* the names that nodes under these declare (name: and a type) and that are type words */
static void cl_declared (struct cl_list *l, struct cl_list *o)
{
  long i = 0;
  while (i < l->n) {
    struct node *n = l->v[i];
    char *s = cl_txt (n);
    long m = cstrlen (s);
    if (m > 1 && s[m - 1] == ':' && cl_alpha (s[0])) {
      long c = 0;
      int ok = 1;
      while (c < m - 1) { if (!cl_alpha (s[c]) && !cl_digit (s[c])) ok = 0; c++; }
      if (ok) {
        char *nm = cl_no_colon (s);
        if (cl_word (nm) && !cl_w_scalar (nm) && n->count && !(cl_leaf (n->kids[0]) && cl_is_record_word (cl_txt (n->kids[0])))) cl_push (o, cl_n (nm));
      }
    }
    if (n->count) cl_declared (cl_sub (n, 0), o);
    i++;
  }
}
static char *cl_gen_new (char *w)
{
  /* address char: -> char * pointer: */
  long n = 0;
  struct cs_buf b;
  if (cl_eq (w, "address:")) w = "address void:";
  while (cl_starts (w, "address ") && w[8]) { w = w + 8; n++; }
  w = cl_no_colon (w);
  cs_b_init (&b);
  cs_b_str (&b, w);
  while (n > 0) { cs_b_str (&b, " * pointer"); n--; }
  cs_b_byte (&b, ':');
  return cl_copy (b.p, b.n);
}
static struct node *cl_newdef (struct node *n, int ctx);
static struct cl_list *cl_newnode1 (struct node *n, int ctx)
{
  char *w = cl_txt (n);
  struct cl_list *o = cl_l ();
  long j;
  if (cl_eq (w, "address:") || cl_eq (w, "content:") || cl_eq (w, "cast::")) cl_fail ("words: the shared page's declarations", w);
  if (!n->count) { cl_push (o, n); return o; }
  if (cl_eq (w, "generic")) {
    struct cl_list *x = cl_l ();
    long i = 1;
    cl_push (x, cl_newone (n->kids[0], CX_FN));
    while (i < n->count) {
      struct cl_list *y = cl_l ();
      cl_newlist (cl_sub (n->kids[i], 0), CX_FN, y);
      cl_push (x, cl_nl (cl_gen_new (cl_txt (n->kids[i])), y));
      i++;
    }
    cl_push (o, cl_nl (w, x));
    return o;
  }
  if (cl_eq (w, "content")) { cl_with_path (WP_CONTENT, cl_sub (n, 0), 0, o); return o; }
  if (cl_eq (w, "address")) {
    struct cl_list *k = cl_sub (n, 0), *r = cl_newrun (k, 0, &j);
    if (r && r->n == 1 && cl_leaf (k->v[0]) && (j == k->n || cl_isleaf (k->v[j], "."))) r = 0;
    if (!r) { cl_with_path (WP_ADDRESS, k, 0, o); return o; }
    if (cl_is (r->v[0], "array")) cl_fail ("words: a conversion to the address of an array", 0);
    cl_push (r, cl_n (C->w_ptr));
    cl_with_path (WP_CASTA, cl_slice (k, j, k->n), r, o);
    return o;
  }
  if (cl_eq (w, "cast:")) {
    struct cl_list *k = cl_sub (n, 0), *r = cl_newrun (k, 0, &j);
    if (!r) cl_fail ("words: cast: without a type", 0);
    cl_with_path (WP_CAST, cl_slice (k, j, k->n), r, o);
    return o;
  }
  if (cl_suffix_type (w) && n->count == 1 && cl_leaf (n->kids[0]) && cl_is_num (cl_txt (n->kids[0]))) {
    cl_push (o, cl_n (w));
    cl_push (o, n->kids[0]);
    return o;
  }
  if (cl_word (w) && !cl_has (&C->recw, w) && !cl_ends_colon (w)) {
    struct cl_list *ty;
    if (n->count == 1 && cl_leaf (n->kids[0]) && cl_is_num (cl_txt (n->kids[0]))) {
      char *ks = cl_txt (n->kids[0]), *suf = cl_tosuffix (w);
      if (suf) { cl_push (o, cl_n (suf)); cl_push (o, n->kids[0]); return o; }
      if (cl_eq (w, "int")) {
        long long v = ks[0] == '-' ? 0 - cl_oct_or_dec (ks + 1) : cl_oct_or_dec (ks);
        if (v >= 0 - 2147483648LL && v < 2147483648LL) { cl_push (o, n->kids[0]); return o; }
      }
    }
    ty = cl_l ();
    cl_push (ty, cl_n (w));
    cl_with_path (WP_WORD, cl_sub (n, 0), ty, o);
    return o;
  }
  if (cl_has (&C->recw, w)) {
    struct cl_list *ty = cl_l ();
    cl_push (ty, cl_n (w));
    cl_with_path (WP_REC, cl_sub (n, 0), ty, o);
    return o;
  }
  if (cl_eq (w, "array") || cl_eq (w, "vector")) {
    struct cl_list *x = cl_l (), *r;
    cl_push (x, cl_n (w));
    cl_append (x, cl_sub (n, 0));
    r = cl_newrun (x, 0, &j);
    if (!r) cl_fail ("words: an array literal without its type", 0);
    cl_with_path (WP_ARR, cl_slice (x, j, x->n), r, o);
    return o;
  }
  if (cl_named_colon (w)) { cl_push (o, cl_newdef (n, ctx)); return o; }
  {
    struct cl_list *x = cl_l ();
    cl_newlist (cl_sub (n, 0), ctx == CX_REC ? CX_FN : ctx, x);
    cl_push (o, cl_nl (w, x));
  }
  return o;
}
/* a function's parameters and locals are no types in it, though a tag has their name */
static struct cl_list *cl_newnode (struct node *n, int ctx)
{
  char *w = cl_txt (n);
  struct cl_list *shadow = 0, *r;
  long i = 0;
  if (!C->scoped && cl_named_colon (w) && n->count && cl_leaf (n->kids[0]) && !cl_is_record_word (cl_txt (n->kids[0]))) {
    shadow = cl_l ();
    cl_declared (cl_sub (n, 0), shadow);
    if (shadow->n) {
      C->scoped = 1;
      while (i < shadow->n) { cl_make (&C->word, cl_txt (shadow->v[i]))->num = 0; i++; }
    } else shadow = 0;
  }
  r = cl_newnode1 (n, ctx);
  if (shadow) {
    i = 0;
    while (i < shadow->n) { cl_make (&C->word, cl_txt (shadow->v[i]))->num = 1; i++; }
    C->scoped = 0;
  }
  return r;
}
static int cl_w_isop (struct node *x) { return x && cl_leaf (x) && cl_opix (cl_txt (x)) >= 0; }
static void cl_newlist (struct cl_list *l, int ctx, struct cl_list *o)
{
  long i = 0;
  while (i < l->n) {
    struct node *n = l->v[i];
    struct cl_list *r;
    if (cl_leaf (n) && (cl_is (n, "address") || cl_is (n, "array") || cl_is (n, "vector"))) {
      long j;
      struct cl_list *run = cl_newrun (l, i, &j);
      if (run) { cl_append (o, run); i = j; continue; }
    }
    r = cl_newnode (n, ctx);
    if (r->n > 1 && !cl_leaf (n) && (cl_is (n, "array") || cl_is (n, "vector") || cl_has (&C->recw, cl_txt (n)))
        && ((i > 0 && cl_w_isop (l->v[i - 1])) || (i + 1 < l->n && cl_w_isop (l->v[i + 1])))) {
      struct node *h = cl_nl (":", r);
      r = cl_l ();
      cl_push (r, h);
    }
    cl_append (o, r);
    i++;
  }
}
static int cl_is_mark (char *s)
{
  return cl_eq (s, "thread local") || cl_eq (s, "weak") || cl_eq (s, "base pcs") || cl_eq (s, "function") || cl_eq (s, "ifunc") || cl_eq (s, "section") || cl_eq (s, "alias") || cl_eq (s, "asm") || cl_eq (s, "struct") || cl_eq (s, "union") || cl_eq (s, "enum");
}
static long cl_marks (struct cl_list *k)
{
  long i = 0;
  if (k->n && cl_is_align (k->v[0])) i++;
  if (i < k->n && cl_is_cleanup (k->v[i])) i++;
  while (i < k->n && cl_leaf (k->v[i]) && cl_is_mark (cl_txt (k->v[i]))) {
    if (cl_is (k->v[i], "ifunc") || cl_is (k->v[i], "section")) i += 2; else i += 1;
  }
  if (i > k->n) return k->n;
  return i;
}
static struct node *cl_newdef (struct node *n, int ctx)
{
  char *w = cl_txt (n);
  struct cl_list *k = cl_sub (n, 0), *x = cl_l (), *run;
  long i = cl_marks (k), j = 0, m = 0;
  if (k->n && cl_leaf (k->v[0]) && (cl_is (k->v[0], "struct") || cl_is (k->v[0], "union"))) {
    struct cl_list *first = cl_slice (k, 0, 1);
    cl_newlist (first, CX_REC, x);
    m = 1;
    while (m < k->n) {
      struct cl_list *f = cl_newnode (k->v[m], CX_REC);
      struct node *fn = f->v[0];
      char *t = cl_txt (fn);
      if (cl_starts (t, "padding ") && cl_is_layer (t + 8)) fn = cl_nl (":", cl_sub (fn, 0));
      cl_push (x, fn);
      m++;
    }
    return cl_nl (w, x);
  }
  run = cl_newrun (k, i, &j);
  if (!run) {
    int sub = CX_FN;
    if (ctx == CX_PAGE && !(k->n && cl_isleaf (k->v[0], "compile time"))) sub = CX_PAGE;
    cl_newlist (k, sub, x);
    return cl_nl (w, x);
  }
  while (m < i) {
    if (cl_is_cleanup (k->v[m])) cl_push (x, k->v[m]);
    else { struct cl_list *one = cl_slice (k, m, m + 1); cl_newlist (one, CX_FN, x); }
    m++;
  }
  cl_append (x, run);
  cl_newlist (cl_slice (k, j, k->n), CX_FN, x);
  return cl_nl (w, x);
}
/* the items of a run, as lists of nodes */
struct cl_items { struct cl_list **v; long n; };
static struct cl_items *cl_items_of (struct cl_list *l, int lit)
{
  struct cl_items *r = alloc (sizeof (struct cl_items));
  long i = 0;
  r->v = alloc ((l->n + 1) * sizeof (struct cl_list *));
  while (i < l->n) {
    long e = cl_item_end (l, i, lit);
    if (e == i) e = i + 1;
    r->v[r->n] = cl_slice (l, i, e);
    r->n = r->n + 1;
    i = e;
  }
  return r;
}
static void cl_new_place (struct cl_list *run, struct cl_list *it, int depth, struct cl_list *o);
static void cl_new_fields (char *name, struct cl_items *items, int depth, struct cl_list *o)
{
  struct cl_wrec *r = cl_wrec_of (name);
  long i = 0;
  if (items->n > r->nf) cl_fail ("words: more items than the record has fields:", name);
  while (i < r->nf) {
    struct cl_wf *f = r->f[i];
    struct cl_list *it = i < items->n ? items->v[i] : 0;
    if (!f->pad) {
      if (f->anon) {
        struct cl_items *sub = alloc (sizeof (struct cl_items));
        if (it) {
          if (!(cl_is (it->v[0], ":") && it->n == 1)) cl_fail ("words: an anonymous member's item that is not a :", 0);
          sub = cl_items_of (cl_sub (it->v[0], 0), 0);
        }
        cl_new_fields (cl_txt (f->run->v[0]), sub, depth + 1, o);
      } else {
        long j;
        struct cl_list *run = cl_newrun (f->run, 0, &j);
        cl_new_place (run, it, depth, o);
      }
    }
    i++;
  }
}
static void cl_new_lit (struct cl_list *ty, struct cl_list *old, int depth, struct cl_list *o)
{
  struct cl_items *items;
  struct node *h = ty->v[0];
  if (depth > 32) cl_fail ("words: compound literals nested too deep", 0);
  items = cl_items_of (old, 0);
  if ((cl_is (h, "array") || cl_is (h, "vector")) && !cl_leaf (h)) {
    long count = cl_oct_or_dec (cl_txt (h->kids[h->count - 1])), m = 0;
    struct cl_list *el = cl_slice (cl_sub (h, 0), 0, h->count - 1);
    if (items->n > count) cl_fail ("words: more items than the array has elements", 0);
    cl_append (o, ty);
    while (m < count) { cl_new_place (el, m < items->n ? items->v[m] : 0, depth, o); m++; }
    return;
  }
  {
    struct cl_wrec *r = cl_get (&C->recw, cl_txt (h));
    if (!r) cl_fail ("words: not a literal's type:", cl_txt (h));
    if (cl_eq (r->kind, "union")) {
      long at = items->n ? items->n - 1 : 0, j;
      struct cl_wf *f;
      struct cl_list *run;
      if (at >= r->nf) cl_fail ("words: a union literal of a member it has not", 0);
      f = r->f[at];
      if (!f->name[0]) cl_fail ("words: a union literal of a member with no name", 0);
      run = cl_newrun (f->run, 0, &j);
      cl_append (o, ty);
      cl_push (o, cl_n (f->name));
      cl_new_place (run, items->n ? items->v[items->n - 1] : 0, depth, o);
      return;
    }
    cl_append (o, ty);
    cl_new_fields (cl_txt (h), items, depth, o);
  }
}
static void cl_new_place (struct cl_list *run, struct cl_list *it, int depth, struct cl_list *o)
{
  int agg = run->n == 1 && (((cl_is (run->v[0], "array") || cl_is (run->v[0], "vector")) && !cl_leaf (run->v[0])) || (cl_leaf (run->v[0]) && cl_has (&C->recw, cl_txt (run->v[0]))));
  if (agg) {
    if (it && it->n == 1 && cl_is (it->v[0], ":") && !cl_leaf (it->v[0])) { cl_new_lit (run, cl_sub (it->v[0], 0), depth + 1, o); return; }
    if (!it) { cl_new_lit (run, cl_l (), depth + 1, o); return; }
  }
  if (!it) { cl_push (o, cl_n ("0")); return; }
  cl_newlist (it, CX_FN, o);
}
/* ---- nodes past 255 children ---- */
static struct node *cl_layer_node (long k, struct cl_list *x) { return cl_nl (cl_cat (cl_num (k), ":"), x); }
/* FF.pm's layers */
static void cl_layers (struct cl_list *n, struct cl_list *o)
{
  long per = 255, i = 0, k = 0;
  if (n->n <= 255) { cl_append (o, n); return; }
  while (n->n > per * 255) per = per * 255;
  while (i < n->n) {
    long e = i + per;
    struct cl_list *y = cl_l ();
    if (e > n->n) e = n->n;
    cl_layers (cl_slice (n, i, e), y);
    cl_push (o, cl_layer_node (k, y));
    k++;
    i = e;
  }
}
static int cl_stmt_starts (struct node *x)
{
  char *s = cl_txt (x);
  if (cl_leaf (x)) return cl_eq (s, "comment") || cl_eq (s, "return") || cl_eq (s, "break") || cl_eq (s, "continue");
  return cl_named_colon (s) || cl_eq (s, "line") || cl_eq (s, "comment") || cl_eq (s, "return") || cl_eq (s, "if") || cl_eq (s, "while") || cl_eq (s, "for") || cl_eq (s, "do while") || cl_eq (s, "switch") || cl_eq (s, "goto");
}
static void cl_w_stmt_layers (struct cl_list *k, struct cl_list *o)
{
  struct cl_list **l, *cur = cl_l ();
  long nl = 0, i = 0, cut = 0 - 1;
  if (k->n <= 255) { cl_append (o, k); return; }
  l = alloc ((k->n + 1) * sizeof (struct cl_list *));
  while (i < k->n) {
    struct node *x = k->v[i];
    if (cur->n >= 255) {
      long q;
      if (cut < 0) { cl_layers (k, o); return; }
      l[nl] = cl_slice (cur, 0, cut);
      nl++;
      cur = cl_slice (cur, cut, cur->n);
      cut = 0 - 1;
      q = cur->n - 1;
      while (q >= 1) { if (cl_stmt_starts (cur->v[q])) { cut = q; break; } q--; }
    }
    if (cur->n && cl_stmt_starts (x)) cut = cur->n;
    cl_push (cur, x);
    i++;
  }
  if (cur->n) { l[nl] = cur; nl++; }
  if (nl > 255) { cl_layers (k, o); return; }
  i = 0;
  while (i < nl) { cl_push (o, cl_layer_node (i, l[i])); i++; }
}
static void cl_flat (struct node *x, struct cl_list *o)
{
  if (cl_is_layer (cl_txt (x))) { long i = 0; while (i < x->count) { cl_flat (x->kids[i], o); i++; } return; }
  cl_push (o, x);
}
enum { RG_NONE, RG_ITEMS, RG_BODY };
static int cl_is_typeword (struct node *n) { return (cl_leaf (n) && cl_word (cl_txt (n))) || ((cl_is (n, "array") || cl_is (n, "vector")) && !cl_leaf (n)); }
static void cl_regroup (struct node *n, int ctx)
{
  struct cl_list *k = cl_sub (n, 0);
  long head = 0, fnhead = 0 - 1, i = 0;
  int items = ctx == RG_ITEMS;
  char *w = cl_txt (n);
  if (cl_named_colon (w)) {
    long m = cl_marks (k);
    if (m < k->n && cl_is_typeword (k->v[m]) && !(cl_leaf (k->v[0]) && (cl_is (k->v[0], "struct") || cl_is (k->v[0], "union") || cl_is (k->v[0], "enum")))) {
      long j = m + 1;
      while (j < k->n && (cl_isleaf (k->v[j], C->w_ptr) || cl_isleaf (k->v[j], "fs"))) j++;
      if (j < k->n && (cl_named_colon (cl_txt (k->v[j])) || cl_is (k->v[j], "...") || cl_is (k->v[j], "comment") || cl_is (k->v[j], "return") || cl_is (k->v[j], "if") || cl_is (k->v[j], "while") || cl_is (k->v[j], "for") || cl_is (k->v[j], "do while") || cl_is (k->v[j], "switch") || cl_is (k->v[j], "goto"))) {
        while (j < k->n && (cl_named_colon (cl_txt (k->v[j])) || cl_is (k->v[j], "...") || cl_is (k->v[j], "comment")) && !cl_is_layer (cl_txt (k->v[j]))) j++;
        fnhead = j;
      } else { head = j; items = 1; }
    }
  }
  while (i < k->n) {
    struct node *x = k->v[i];
    int c = RG_NONE;
    if (items && (cl_is (x, ":") || cl_is (x, "items"))) c = RG_ITEMS;
    else if (fnhead >= 0 && cl_is_layer (cl_txt (x))) c = RG_BODY;
    cl_regroup (x, c);
    i++;
  }
  if (fnhead >= 0) {
    int past = 0;
    i = fnhead;
    while (i < k->n) { if (cl_is_layer (cl_txt (k->v[i])) && k->v[i]->count > 255) past = 1; i++; }
    if (past) {
      struct cl_list *f = cl_l (), *y = cl_slice (k, 0, fnhead);
      i = fnhead;
      while (i < k->n) { cl_flat (k->v[i], f); i++; }
      cl_w_stmt_layers (f, y);
      n->count = 0;
      n->room = 0;
      n->kids = 0;
      cl_add_all (n, y);
      return;
    }
  }
  if (k->n <= 255) return;
  if (fnhead >= 0) {
    struct cl_list *y = cl_slice (k, 0, fnhead);
    cl_w_stmt_layers (cl_slice (k, fnhead, k->n), y);
    n->count = 0; n->room = 0; n->kids = 0;
    cl_add_all (n, y);
    return;
  }
  if (!items && cl_is_layer (w) && ctx == RG_BODY) return;
  if (!items) {
    struct cl_list *y = cl_l ();
    cl_layers (k, y);
    n->count = 0; n->room = 0; n->kids = 0;
    cl_add_all (n, y);
    return;
  }
  {
    struct cl_list *v = cl_l (), *y = cl_slice (k, 0, head), *cur = cl_l ();
    i = head;
    while (i < k->n) {
      if (cl_is (k->v[i], "items") && !cl_leaf (k->v[i])) cl_append (v, cl_sub (k->v[i], 0));
      else cl_push (v, k->v[i]);
      i++;
    }
    i = 0;
    while (i < v->n) {
      long e = cl_item_end (v, i, 1);
      if (e <= i) e = i + 1;
      if (e - i > 255) cl_fail ("words: an item of more than 255 nodes", 0);
      if (cur->n + e - i > 255) { cl_push (y, cl_nl ("items", cur)); cur = cl_l (); }
      cl_append (cur, cl_slice (v, i, e));
      i = e;
    }
    if (cur->n) cl_push (y, cl_nl ("items", cur));
    n->count = 0; n->room = 0; n->kids = 0;
    cl_add_all (n, y);
  }
}
/* before -> now, each of the list */
static void cl_newwords (struct cl_list *l)
{
  long i = 0;
  while (i < l->n) { cl_typenames (l->v[i]); i++; }
  i = 0;
  while (i < l->n) {
    struct cl_list *r = cl_newnode (l->v[i], CX_PAGE);
    struct node *n;
    if (r->n != 1) cl_fail ("words: a definition that became several nodes", 0);
    n = r->v[0];
    cl_regroup (n, RG_NONE);
    l->v[i] = n;
    i++;
  }
}
