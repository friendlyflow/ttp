/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cpr.c: the printer (in c.c's unit): a parse tree back as C, every
   operator's operation in parentheses, so that a wrong tree is other C */
static void p_expr (struct node *e);
static void p_item (struct node *n);
static void p_type (struct node *t);
static void p_init (struct node *i);
static void p_decl (struct node *d);

static void p_leaf (struct node *n)
{
  if (nd_is (n, "token") && n->count) { long i = 0; while (i < n->count) { out_bytes (n->kids[i]->text, n->kids[i]->len); i++; } return; }
  out_bytes (n->text, n->len);
}
static void p_attr (struct node *a)
{
  long i = 0;
  if (nd_is (a, "[[]]")) {
    out_str (" [[");
    while (i < a->count) {
      if (i && !nd_is (a->kids[i], ":") && !nd_is (a->kids[i - 1], ":")) out_str (" ");
      p_leaf (a->kids[i]);
      i++;
    }
    out_str ("]] ");
    return;
  }
  out_str (" __attribute__ ((");
  while (i < a->count) { if (i) out_str (" "); p_leaf (a->kids[i]); i++; }
  out_str (")) ");
}
static void p_str (struct node *s)
{
  if (nd_is (s, "str") && s->count) { long i = 0; while (i < s->count) { if (i) out_str (" "); p_leaf (s->kids[i]); i++; } return; }
  p_leaf (s);
}
static int is_kw (struct node *n, char *a, char *b, char *c, char *d, char *e)
{
  return nd_is (n, a) || (b && nd_is (n, b)) || (c && nd_is (n, c)) || (d && nd_is (n, d)) || (e && nd_is (n, e));
}
static void p_specs (struct node *s)
{
  long i = 0;
  while (i < s->count) {
    struct node *k = s->kids[i];
    if (nd_is (k, "__attribute__") || nd_is (k, "[[]]")) p_attr (k);
    else if (nd_leaf (k)) { p_leaf (k); out_str (" "); }
    else if (is_kw (k, "struct", "union", "enum", 0, 0)) {
      long j = 0;
      int en = nd_is (k, "enum");
      p_leaf (k);
      out_str (" ");
      while (j < k->count) {
        struct node *x = k->kids[j];
        if ((nd_is (x, "__attribute__") || nd_is (x, "[[]]"))) p_attr (x);
        else if (nd_is (x, ":") && x->count) { out_str (" : "); p_specs (x->kids[0]); }
        else if (nd_is (x, "{")) {
          long m = 0;
          out_str ("{\n");
          while (m < x->count) {
            struct node *y = x->kids[m];
            if (en) {
              long q = 1;
              p_leaf (y->kids[0]);
              while (q < y->count) {
                if (nd_is (y->kids[q], "=")) { out_str (" = "); p_expr (y->kids[q]->kids[0]); }
                else p_attr (y->kids[q]);
                q++;
              }
              out_str (",\n");
            } else p_item (y);
            m++;
          }
          out_str ("} ");
        } else { p_leaf (x); out_str (" "); }
        j++;
      }
    } else {
      /* typeof, _Alignas, _BitInt, _Atomic (T) */
      p_leaf (k);
      out_str (" (");
      if (nd_is (k->kids[0], "type") && k->kids[0]->count) p_type (k->kids[0]); else p_expr (k->kids[0]);
      out_str (") ");
    }
    i++;
  }
}
static int is_ptr (struct node *d) { return !nd_leaf (d) && nd_is (d, "*"); }
static void p_inner (struct node *d)
{
  if (is_ptr (d)) { out_str ("("); p_decl (d); out_str (")"); } else p_decl (d);
}
static void p_decl (struct node *d)
{
  long i = 1;
  if (nd_leaf (d)) { if (!nd_is (d, "?")) p_leaf (d); return; }
  if (nd_is (d, "*")) {
    out_str ("*");
    while (i < d->count) {
      if ((nd_is (d->kids[i], "__attribute__") || nd_is (d->kids[i], "[[]]"))) p_attr (d->kids[i]);
      else { out_str (" "); p_leaf (d->kids[i]); out_str (" "); }
      i++;
    }
    p_decl (d->kids[0]);
    return;
  }
  if (nd_is (d, "( )")) {
    out_str ("(");
    i = 0;
    while (i < d->count - 1) { p_attr (d->kids[i]); i++; }
    p_decl (d->kids[d->count - 1]);
    out_str (")");
    return;
  }
  if (nd_is (d, "[]")) {
    p_inner (d->kids[0]);
    out_str ("[");
    while (i < d->count) {
      if (i > 1) out_str (" ");
      if ((nd_is (d->kids[i], "__attribute__") || nd_is (d->kids[i], "[[]]"))) p_attr (d->kids[i]); else p_expr (d->kids[i]);
      i++;
    }
    out_str ("]");
    return;
  }
  if (nd_is (d, "()")) {
    p_inner (d->kids[0]);
    out_str (" (");
    while (i < d->count) {
      struct node *p = d->kids[i];
      if (i > 1) out_str (", ");
      if (nd_leaf (p)) p_leaf (p);
      else {
        long j = 1;
        p_specs (p->kids[0]);
        while (j < p->count) {
          if ((nd_is (p->kids[j], "__attribute__") || nd_is (p->kids[j], "[[]]"))) p_attr (p->kids[j]); else p_decl (p->kids[j]);
          j++;
        }
      }
      i++;
    }
    out_str (")");
    return;
  }
  c_fail ("cprint: not a declarator");
}
static void p_type (struct node *t)
{
  p_specs (t->kids[0]);
  if (t->count > 1) p_decl (t->kids[1]);
}
static int is_binop (struct node *e)
{
  char *ops[] = { "||", "&&", "|", "^", "&", "==", "!=", "<", ">", "<=", ">=", "<<", ">>", "+", "-", "*", "/", "%",
                  "=", "*=", "/=", "%=", "+=", "-=", "<<=", ">>=", "&=", "^=", "|=", ",", 0 };
  long i = 0;
  while (ops[i]) { if (nd_is (e, ops[i])) return 1; i++; }
  return 0;
}
static void p_args (struct node *e, long from)
{
  long i = from;
  while (i < e->count) { if (i > from) out_str (", "); p_expr (e->kids[i]); i++; }
}
static void p_expr (struct node *e)
{
  long n = e->count;
  if (n == 0 || nd_is (e, "token")) { p_leaf (e); return; }
  if (nd_is (e, "str")) { p_str (e); return; }
  if (n == 2 && is_binop (e)) {
    out_str ("(");
    p_expr (e->kids[0]);
    out_str (" ");
    p_leaf (e);
    out_str (" ");
    p_expr (e->kids[1]);
    out_str (")");
    return;
  }
  if (n == 1 && is_kw (e, "&", "*", "+", "-", "~") ) { out_str ("("); p_leaf (e); p_expr (e->kids[0]); out_str (")"); return; }
  if (n == 1 && is_kw (e, "!", "++", "--", "&&", 0)) { out_str ("("); p_leaf (e); p_expr (e->kids[0]); out_str (")"); return; }
  if (nd_is (e, "post ++") || nd_is (e, "post --")) { out_str ("("); p_expr (e->kids[0]); out_str (nd_is (e, "post ++") ? "++)" : "--)"); return; }
  if (nd_is (e, "()")) { p_expr (e->kids[0]); out_str (" ("); p_args (e, 1); out_str (")"); return; }
  if (nd_is (e, "[]")) { p_expr (e->kids[0]); out_str ("["); p_expr (e->kids[1]); out_str ("]"); return; }
  if (nd_is (e, ".") || nd_is (e, "->")) { p_expr (e->kids[0]); p_leaf (e); p_leaf (e->kids[1]); return; }
  if (nd_is (e, "cast")) { out_str ("(("); p_type (e->kids[0]); out_str (") "); p_expr (e->kids[1]); out_str (")"); return; }
  if (is_kw (e, "sizeof", "_Alignof", "alignof", "__alignof", "__alignof__")) {
    out_str ("(");
    p_leaf (e);
    if (nd_is (e->kids[0], "type") && e->kids[0]->count) { out_str (" ("); p_type (e->kids[0]); out_str ("))"); return; }
    out_str (" ");
    p_expr (e->kids[0]);
    out_str (")");
    return;
  }
  if (is_kw (e, "__real__", "__real", "__imag__", "__imag", "__extension__")) { out_str ("("); p_leaf (e); out_str (" "); p_expr (e->kids[0]); out_str (")"); return; }
  if (nd_is (e, "?")) { out_str ("("); p_expr (e->kids[0]); out_str (" ? "); p_expr (e->kids[1]); out_str (" : "); p_expr (e->kids[2]); out_str (")"); return; }
  if (nd_is (e, "?:")) { out_str ("("); p_expr (e->kids[0]); out_str (" ?: "); p_expr (e->kids[1]); out_str (")"); return; }
  if (nd_is (e, "compound literal")) { out_str ("(("); p_type (e->kids[0]); out_str (") "); p_init (e->kids[1]); out_str (")"); return; }
  if (nd_is (e, "stmt expr")) { out_str ("("); p_item (e->kids[0]); out_str (")"); return; }
  if (nd_is (e, "_Generic")) {
    long i = 1;
    out_str ("_Generic (");
    p_expr (e->kids[0]);
    while (i < n) {
      struct node *a = e->kids[i];
      out_str (", ");
      if (nd_is (a->kids[0], "type") && a->kids[0]->count) p_type (a->kids[0]); else p_leaf (a->kids[0]);
      out_str (": ");
      p_expr (a->kids[1]);
      i++;
    }
    out_str (")");
    return;
  }
  if (nd_is (e, "__builtin_offsetof")) {
    long i = 2;
    out_str ("__builtin_offsetof (");
    p_type (e->kids[0]);
    out_str (", ");
    p_leaf (e->kids[1]);
    while (i < n) {
      struct node *d = e->kids[i];
      if (nd_is (d, ".")) { out_str ("."); p_leaf (d->kids[0]); } else { out_str ("["); p_expr (d->kids[0]); out_str ("]"); }
      i++;
    }
    out_str (")");
    return;
  }
  if (nd_is (e, "__builtin_va_arg") || nd_is (e, "__builtin_convertvector")) {
    p_leaf (e); out_str (" ("); p_expr (e->kids[0]); out_str (", "); p_type (e->kids[1]); out_str (")"); return;
  }
  if (nd_is (e, "__builtin_types_compatible_p")) {
    p_leaf (e); out_str (" ("); p_type (e->kids[0]); out_str (", "); p_type (e->kids[1]); out_str (")"); return;
  }
  c_fail ("cprint: not an expression");
}
static void p_init (struct node *i)
{
  long k = 0;
  if (!nd_is (i, "{}")) { p_expr (i); return; }
  out_str ("{");
  while (k < i->count) {
    struct node *x = i->kids[k];
    if (k) out_str (", ");
    if (nd_is (x, "designated") && x->count) {
      long j = 0;
      while (j < x->count - 1) {
        struct node *d = x->kids[j];
        if (nd_is (d, ".")) { out_str ("."); p_leaf (d->kids[0]); }
        else if (nd_is (d, "[]")) { out_str ("["); p_expr (d->kids[0]); out_str ("]"); }
        else { out_str ("["); p_expr (d->kids[0]); out_str (" ... "); p_expr (d->kids[1]); out_str ("]"); }
        j++;
      }
      out_str (" = ");
      p_init (x->kids[x->count - 1]);
    } else p_init (x);
    k++;
  }
  out_str ("}");
}
static void p_idecl (struct node *id)
{
  long i = 1;
  p_decl (id->kids[0]);
  while (i < id->count) {
    struct node *k = id->kids[i];
    if (nd_is (k, ":")) { out_str (" : "); p_expr (k->kids[0]); }
    else if (nd_is (k, "asm")) { out_str (" __asm__ ("); p_str (k->kids[0]); out_str (")"); }
    else if (nd_is (k, "=")) { out_str (" = "); p_init (k->kids[0]); }
    else p_attr (k);
    i++;
  }
}
static void p_asm (struct node *a)
{
  long i = 0;
  out_str ("__asm__ ");
  while (i < a->count && nd_leaf (a->kids[i]) && a->kids[i]->text[0] != '"') { p_leaf (a->kids[i]); out_str (" "); i++; }
  out_str ("(");
  p_str (a->kids[i]);
  i++;
  while (i < a->count) {
    struct node *c = a->kids[i];
    long j = 0;
    out_str (" : ");
    while (j < c->count) {
      struct node *o = c->kids[j];
      if (j) out_str (", ");
      if (nd_is (o, "operand") && o->count >= 2) {
        long q = 0;
        if (nd_is (o->kids[0], "[]") && o->kids[0]->count) { out_str ("["); p_leaf (o->kids[0]->kids[0]); out_str ("] "); q = 1; }
        p_str (o->kids[q]);
        out_str (" (");
        p_expr (o->kids[q + 1]);
        out_str (")");
      } else p_str (o);
      j++;
    }
    i++;
  }
  out_str (")");
}
static void p_body (struct node *s) { p_item (s); }
static void p_item (struct node *n)
{
  long c = n->count;
  if (nd_is (n, "block") && c == 0) { out_str ("{\n}\n"); return; }
  if (nd_leaf (n)) {
    if (nd_is (n, ";")) out_str (";\n");
    else if (nd_is (n, "return")) out_str ("return;\n");
    else { p_leaf (n); out_str (";\n"); }
    return;
  }
  if (nd_is (n, "decl")) {
    long i = 1;
    p_specs (n->kids[0]);
    while (i < c) { if (i > 1) out_str (", "); p_idecl (n->kids[i]); i++; }
    out_str (";\n");
    return;
  }
  if (nd_is (n, "fun def")) {
    long i = 2;
    p_specs (n->kids[0]);
    p_decl (n->kids[1]);
    out_str ("\n");
    while (i < c) {
      struct node *k = n->kids[i];
      if (nd_is (k, "asm")) { out_str (" __asm__ ("); p_str (k->kids[0]); out_str (")"); }
      else if (nd_is (k, "__attribute__") || nd_is (k, "[[]]")) p_attr (k);
      else p_item (k);
      i++;
    }
    return;
  }
  if (nd_is (n, "directive")) { out_str ("\n"); p_leaf (n->kids[0]); out_str ("\n"); return; }
  if (nd_is (n, ";")) { long i = 0; while (i < c) { p_attr (n->kids[i]); i++; } out_str (";\n"); return; }
  if (nd_is (n, "_Static_assert")) {
    out_str ("_Static_assert (");
    p_expr (n->kids[0]);
    if (c > 1) { out_str (", "); p_str (n->kids[1]); }
    out_str (");\n");
    return;
  }
  if (nd_is (n, "__extension__")) { out_str ("__extension__ "); p_item (n->kids[0]); return; }
  if (nd_is (n, "asm")) { p_asm (n); out_str (";\n"); return; }
  if (nd_is (n, "block")) { long i = 0; out_str ("{\n"); while (i < c) { p_item (n->kids[i]); i++; } out_str ("}\n"); return; }
  if (nd_is (n, "expr")) { p_expr (n->kids[0]); out_str (";\n"); return; }
  if (nd_is (n, "if")) {
    out_str ("if (");
    p_expr (n->kids[0]);
    out_str (") ");
    if (c > 2 && !nd_is (n->kids[1], "block")) { out_str ("{\n"); p_body (n->kids[1]); out_str ("}\n"); } else p_body (n->kids[1]);
    if (c > 2) { out_str ("else "); p_body (n->kids[2]); }
    return;
  }
  if (nd_is (n, "while") || nd_is (n, "switch")) { p_leaf (n); out_str (" ("); p_expr (n->kids[0]); out_str (") "); p_body (n->kids[1]); return; }
  if (nd_is (n, "do")) { out_str ("do "); p_body (n->kids[0]); out_str ("while ("); p_expr (n->kids[1]); out_str (");\n"); return; }
  if (nd_is (n, "for")) {
    struct node *a = n->kids[0], *b = n->kids[1], *s = n->kids[2];
    out_str ("for (");
    if (nd_is (a, "expr")) { p_expr (a->kids[0]); out_str (";"); } else if (nd_leaf (a)) out_str (";"); else p_item (a);
    out_str (" ");
    if (nd_is (b, "expr")) p_expr (b->kids[0]);
    out_str ("; ");
    if (nd_is (s, "expr")) p_expr (s->kids[0]);
    out_str (") ");
    p_body (n->kids[3]);
    return;
  }
  if (nd_is (n, "case")) {
    out_str ("case ");
    p_expr (n->kids[0]);
    if (c > 2) { out_str (" ... "); p_expr (n->kids[1]); }
    out_str (":\n");
    p_item (n->kids[c - 1]);
    return;
  }
  if (nd_is (n, "default")) { out_str ("default:\n"); p_item (n->kids[0]); return; }
  if (nd_is (n, "label")) {
    long i = 1;
    p_leaf (n->kids[0]);
    out_str (":");
    while (i < c - 1) { p_attr (n->kids[i]); i++; }
    out_str ("\n");
    p_item (n->kids[c - 1]);
    return;
  }
  if (nd_is (n, "goto")) { out_str ("goto "); p_leaf (n->kids[0]); out_str (";\n"); return; }
  if (nd_is (n, "goto *")) { out_str ("goto *"); p_expr (n->kids[0]); out_str (";\n"); return; }
  if (nd_is (n, "return")) { out_str ("return "); p_expr (n->kids[0]); out_str (";\n"); return; }
  if (nd_is (n, "__label__")) { out_str ("__label__ "); p_args (n, 0); out_str (";\n"); return; }
  c_fail ("cprint: not a declaration or a statement");
}
void c_print (struct node *root)
{
  long i = 0;
  while (i < root->count) { p_item (root->kids[i]); i++; }
}
