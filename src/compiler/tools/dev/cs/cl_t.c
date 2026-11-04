/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cl_t.c (in cs.c): names and types, as gen/c2ff.pl's ctype and its pass over a unit's declarations */
static char *cl_reserved_words[] = {
  "if", "else", "while", "for", "return", "break", "continue", "comment", "address", "content", "syscall", "U", "L", "UL", "LL", "ULL",
  "array", "struct", "union", "enum", "function", "sizeof", "alignof", "compile", "emit", "fail", "number",
  "target", "include", "workspace", "switch", "case", "default", "goto", "char", "short", "int", "long", "void",
  "type", "i8", "i16", "i32", "i64", "i128", "u8", "u16", "u32", "u64", "u128", "float16", "bfloat16", "fract", "accum", "va_list", "va_start", "va_arg", "va_end", "va_copy",
  "alias", "ifunc", "asm", "items", "cast", "weak", "va_arg_pack", "va_arg_pack_len", "real", "imag", "generic", "section", "constructor", "destructor", "fs", "vector", "line", 0
};
static char *cl_reg_words[] = { "zero", "ra", "sp", "gp", "tp", "fp", "pc", 0 };
static char *cl_reg_pre[] = { "x", "a", "s", "t", "f", "fa", "fs", "ft", "v", 0 };
static void cl_reserve (void)
{
  long i = 0;
  while (cl_reserved_words[i]) { cl_set (&C->reserved, cl_reserved_words[i]); i++; }
  /* (riscv64's registers; another target's its own, cl_reserve_target) */
  if (C->target) return;
  i = 0;
  while (cl_reg_words[i]) { cl_set (&C->reserved, cl_reg_words[i]); i++; }
  i = 0;
  while (cl_reg_pre[i]) {
    long j = 0;
    while (j < 32) { cl_set (&C->reserved, cl_cat (cl_reg_pre[i], cl_num (j))); j++; }
    i++;
  }
}
static char *cl_ffname (char *n)
{
  if (!cl_val (&C->reserved, n)) return n;
  return cl_cat (n, "'");
}
static char *cl_dn (struct cs_decl *d) { return cl_copy (d->name, d->nlen); }
static char *cl_own (char *n) { char *o = cl_get (&C->own, n); if (o) return o; return n; }
static void cl_want (char *n)
{
  if (cl_val (&C->done, n)) return;
  cl_set (&C->done, n);
  if (C->ntodo == C->roomtodo) {
    long m = C->roomtodo * 2 + 64, i = 0;
    struct node **a = alloc (m * sizeof (struct node *));
    while (i < C->ntodo) { a[i] = C->todo[i]; i++; }
    C->todo = a;
    C->roomtodo = m;
  }
  C->todo[C->ntodo] = (struct node *) n;
  C->ntodo = C->ntodo + 1;
}
static void cl_local_name (unsigned char *p, long n) { if (p && n) cl_set (&C->localname, cl_copy (p, n)); }
/* ---- records and enums ---- */
static char *cl_rec_kind (struct cs_rec *r)
{
  if (r->k == TY_ENUM) return "enum";
  if (r->k == TY_UNION) return "union";
  return "struct";
}
/* what clang's anon_key finds: base:line:col of the record's place */
static char *cl_anon_key (struct cs_rec *r)
{
  char *s = cl_copy (r->loc, r->llen);
  long i = 9, base = 9, n = cstrlen (s);
  while (s[i]) { if (s[i] == '/') base = i + 1; i++; }
  s[n - 1] = 0;
  return s + base;
}
/* the anonymous record a type's spelling shows, under its pointers and arrays */
static struct cs_rec *cl_anon_in (struct cs_ty *t)
{
  while (t) {
    if (t->k == TY_PTR || t->k == TY_ARRAY) { t = t->to; continue; }
    if (t->k == TY_STRUCT || t->k == TY_UNION || t->k == TY_ENUM) { if (!t->rec->tag && !t->rec->td) return t->rec; return 0; }
    return 0;
  }
  return 0;
}
static void cl_anon_fields (struct cs_rec *r, char *rname);
static int cl_same_def (struct cs_rec *a, struct cs_rec *b);
static int cl_enum_more (struct cs_rec *o, struct cs_rec *d);
static void cl_set_enumd (char *tag, struct cs_rec *d)
{
  struct cs_rec *o = cl_get (&C->enumd, tag);
  if (!o || (!o->nenums && d->nenums) || cl_enum_more (o, d)) cl_put (&C->enumd, tag, d);
}
/* (another unit's with every constant of the first, of the same value, and more: gcc's dwarf2.h's over glibc's) */
static int cl_enum_more (struct cs_rec *o, struct cs_rec *d)
{
  long i = 0, j;
  long long v = 0 - 1;
  if (d->nenums <= o->nenums) return 0;
  while (i < o->nenums) {
    int found = 0;
    long long ov = o->enums[i]->val;
    j = 0;
    while (j < d->nenums) {
      if (same (d->enums[j]->name, d->enums[j]->nlen, cl_copy (o->enums[i]->name, o->enums[i]->nlen))) { if (d->enums[j]->val == ov) found = 1; break; }
      j++;
    }
    if (!found) return 0;
    i++;
  }
  (void) v;
  return 1;
}
static char *cl_rname (struct cs_rec *r) { if (r->tag) return cl_copy (r->tag, r->tlen); if (r->td) return cl_copy (r->td, r->tdlen); return 0; }
static void cl_anon_fields (struct cs_rec *r, char *rname)
{
  struct cs_inner *i = r->in_first;
  struct cs_rec *last = 0;
  while (i) {
    if (i->r) {
      struct cs_rec *k = i->r;
      last = k;
      if (k->tag) {
        char *nm = cl_copy (k->tag, k->tlen);
        if (k->k == TY_ENUM) cl_set_enumd (cl_cat ("enum ", nm), k);
        else { cl_put_new (&C->rec, cl_cat3 (cl_rec_kind (k), " ", nm), k); cl_anon_fields (k, nm); }
      }
    } else if (i->f->name && i->f->nlen && last && !last->tag) {
      struct cs_rec *in = cl_anon_in (i->f->t);
      if (in) {
        char *key = cl_anon_key (in), *kind = cl_rec_kind (last);
        char *name = cl_cat3 (rname, " ", cl_copy (i->f->name, i->f->nlen));
        /* (the same place defined otherwise, a skeleton included for another type: by the record it is in) */
        char *atag = cl_get (&C->anon_tag, key);
        struct cs_rec *first = atag ? cl_get (&C->rec, atag) : 0;
        if (last->k != TY_ENUM && first && first != last && !cl_same_def (last, first))
          cl_put (&C->anonin, cl_cat3 (cl_cat3 (cl_rec_kind (r), " ", rname), "|", key), cl_cat3 (kind, " ", name));
        else {
          cl_put (&C->anon_tag, key, cl_cat3 (kind, " ", name));
          cl_put (&C->anon_name, key, name);
        }
        if (last->k != TY_ENUM && C->cu) cl_put_new (&C->recunit, cl_cat3 (kind, " ", name), C->cu);
        if (last->k == TY_ENUM) cl_put_new (&C->enumd, cl_cat ("enum ", name), last);
        else { cl_put_new (&C->rec, cl_cat3 (kind, " ", name), last); cl_anon_fields (last, name); }
        last = 0;
      }
    }
    i = i->nxt;
  }
}
static void cl_index_enum (struct cs_rec *d)
{
  char *tag = 0;
  long i = 0;
  long long v = -1;
  if (d->tag) tag = cl_cat ("enum ", cl_copy (d->tag, d->tlen));
  else if (d->nenums) tag = cl_cat3 ("enum ", cl_dn (d->enums[0]), " enum");
  if (!tag) return;
  cl_set_enumd (tag, d);
  if (!d->tag && d->nenums) cl_put_new (&C->tagname, tag, cl_cat (cl_dn (d->enums[0]), " enum"));
  while (i < d->nenums) {
    char *c = cl_dn (d->enums[i]);
    cl_put_new (&C->enumof, c, tag);
    v = d->enums[i]->val;
    if (!cl_has (&C->enumval, c)) cl_make (&C->enumval, c)->num = v;
    i++;
  }
}
static char *cl_unit_name (void);
static char *cl_unit_name_of (struct cl_unit *u);
static int cl_is_fieldname (char *n)
{
  if (C->nfieldrec != C->rec.count) {
    long i = 0;
    C->fieldname.tab = 0;
    C->fieldname.count = 0;
    if (C->rec.tab) while (i < CL_BUCKETS) {
      struct cl_ent *e = C->rec.tab[i];
      while (e) {
        struct cs_field *f = ((struct cs_rec *) e->val)->first;
        while (f) { if (f->name && f->nlen) cl_set (&C->fieldname, cl_ffname (cl_copy (f->name, f->nlen))); f = f->nxt; }
        e = e->nxt;
      }
      i++;
    }
    C->nfieldrec = C->rec.count;
  }
  return cl_val (&C->fieldname, n);
}
/* a record's or an enum's ff name; it comes with the output */
static char *cl_tag (struct cs_rec *r)
{
  char *nm = cl_rname (r);
  if (nm) {
    char *kind = cl_rec_kind (r), *key = cl_cat3 (kind, " ", nm), *f;
    /* (a function's own definition of the tag) */
    if (C->cur_fn) {
      char *ownk = cl_get (&C->ownfn, cl_cat3 (C->cur_fn, "\t", key));
      if (ownk) {
        cl_set (&C->wanttag, ownk);
        f = cl_get (&C->tagname, ownk);
        if (f) return f;
        f = cl_cat3 (cl_ffname (nm), " ", cl_ffname (C->cur_fn));
        cl_put (&C->tagname, ownk, f);
        return f;
      }
    }
    /* (a unit's own definition of the tag, reg_rec) */
    if (C->cu) {
      char *ownk = cl_get (&C->ownrec, key);
      if (ownk) {
        cl_set (&C->wanttag, ownk);
        f = cl_get (&C->tagname, ownk);
        if (f) return f;
        f = cl_cat3 (cl_ffname (nm), " ", cl_unit_name ());
        cl_put (&C->tagname, ownk, f);
        return f;
      }
    }
    cl_set (&C->wanttag, key);
    f = cl_get (&C->tagname, key);
    if (f) return f;
    if (cl_has (&C->var, nm) || cl_has (&C->fn, nm) || cl_has (&C->alias, nm) || cl_val (&C->localname, nm) || cl_is_fieldname (cl_ffname (nm)) || cl_val (&C->treedefs, cl_ffname (nm))) {
      f = cl_cat3 (nm, " ", kind);
      if (C->treedefs.count) f = cl_cat (f, " prog");
    }
    else f = cl_ffname (nm);
    cl_put (&C->tagname, key, f);
    return f;
  }
  {
    char *key = cl_anon_key (r), *tag = cl_get (&C->anon_tag, key), *ownk = 0;
    /* (a unit's own anonymous record, where another unit's at the same place differs) */
    if (C->cu) { ownk = cl_get (&C->ownanon, key); if (ownk) tag = ownk; }
    /* (a record's own, first) */
    if (C->cur_tag) { char *in = cl_get (&C->anonin, cl_cat3 (C->cur_tag, "|", key)); if (in) { ownk = in; tag = in; } }
    if (tag) {
      char *f = cl_get (&C->tagname, tag);
      cl_set (&C->wanttag, tag);
      if (f) return f;
      /* (the tag less its kind) */
      if (ownk) { long b = 0; while (ownk[b] != ' ') b++; f = ownk + b + 1; }
      else f = cl_get (&C->anon_name, key);
      cl_put (&C->tagname, tag, f);
      return f;
    }
    if (r->k == TY_ENUM) return "int";
    cl_fail ("no ff type for an anonymous record at", key);
  }
  return 0;
}
/* ---- types ---- */
static void cl_w (struct cl_list *o, char *s) { cl_push (o, cl_n (s)); }
static void cl_ctype (struct cs_ty *t, struct cl_list *o);
/* a spelling without its qualifiers and attributes, its spaces single: what ctype makes of one before it looks at it */
static char *cl_key_norm (char *s, int raw)
{
  struct cs_buf b;
  long i = 0;
  cs_b_init (&b);
  while (s[i]) {
    int word_start = i == 0 || !(cl_alpha (s[i - 1]) || cl_digit (s[i - 1]));
    if (word_start && (cl_starts (s + i, "const") || cl_starts (s + i, "volatile") || cl_starts (s + i, "restrict") || cl_starts (s + i, "__restrict"))) {
      long e = i;
      while (cl_alpha (s[e]) || cl_digit (s[e])) e++;
      if (e - i == 5 || e - i == 8 || e - i == 10) {
        char *w = cl_copy ((unsigned char *) s + i, e - i);
        if (cl_eq (w, "const") || cl_eq (w, "volatile") || cl_eq (w, "restrict") || cl_eq (w, "__restrict")) { i = e; continue; }
      }
    }
    if (word_start && cl_starts (s + i, "__attribute__") && !cl_starts (s + i, "__attribute__((__vector_size__") && !cl_starts (s + i, "__attribute__((address_space")) {
      long e = i + 13, d = 0;
      while (s[e]) { if (s[e] == '(') d++; if (s[e] == ')') { d--; if (d == 0) { e++; break; } } e++; }
      i = e;
      continue;
    }
    cs_b_byte (&b, s[i]);
    i++;
  }
  s = cl_copy (b.p, b.n);
  cs_b_init (&b);
  i = 0;
  while (s[i]) {
    /* (raw: a function type through a typedef's name, by expand, which leaves the spaces of a const it takes out: __ssize_t (void *,  char *, size_t) is not __ssize_t (void *, char *, size_t), cookie_write_function_t and cookie_read_function_t) */
    if (s[i] == ' ' && raw) {
      long e = i;
      while (s[e] == ' ') e++;
      if (!b.n || !s[e]) { i = e; continue; }
    }
    else if (s[i] == ' ') { while (s[i] == ' ') i++; if (b.n && s[i]) cs_b_byte (&b, ' '); continue; }
    cs_b_byte (&b, s[i]);
    i++;
  }
  /* (its parameters trimmed: the last balanced ( ) at the end) */
  s = cl_copy (b.p, b.n);
  i = b.n - 1;
  if (i > 0 && s[i] == ')') {
    long d = 0;
    while (i >= 0) {
      if (s[i] == ')') d++;
      if (s[i] == '(') { d--; if (!d) break; }
      i--;
    }
    if (i >= 0 && s[i + 1] == ' ') {
      long j = i + 1;
      while (s[j + 1]) { s[j] = s[j + 1]; j++; }
      s[j] = 0;
    }
  }
  return s;
}
/* a pointer to a function: its type's name, made once per spelling */
static char *cl_fntype (struct cs_ty *f, int raw)
{
  struct cs_buf b, in;
  char *key, *name;
  cs_b_init (&b);
  cs_b_init (&in);
  cs_p_type (&b, f, &in, 1);
  key = cl_key_norm (cl_copy (b.p, b.n), raw);
  /* (arm's pcs ("aapcs") of the function type: a type of its own, base pcs first) */
  if (f->pcs) key = cl_cat (key, " pcs");
  name = cl_get (&C->fntype, key);
  if (name) return name;
  C->fnlast = C->fnlast + 1;
  /* (with --index, not a name of the tree's own) */
  while (cl_val (&C->treedefs, cl_cat ("fn", cl_num (C->fnlast)))) C->fnlast = C->fnlast + 1;
  name = cl_cat ("fn", cl_num (C->fnlast));
  cl_put (&C->fntype, key, name);
  if (C->nfnt == C->roomfnt) {
    long m = C->roomfnt * 2 + 32, i = 0;
    char **a = alloc (m * sizeof (char *));
    struct cs_ty **x = alloc (m * sizeof (struct cs_ty *));
    while (i < C->nfnt) { a[i] = C->fnt_name[i]; x[i] = C->fnt_ty[i]; i++; }
    C->fnt_name = a;
    C->fnt_ty = x;
    C->roomfnt = m;
  }
  C->fnt_name[C->nfnt] = name;
  C->fnt_ty[C->nfnt] = f;
  C->nfnt = C->nfnt + 1;
  return name;
}
/* an array's count that is a const integer global of the unit: its number (c2ff's constcounts) */
static int cl_vla_const (struct cs_ty *c, long long *v)
{
  struct node *k = c->count;
  struct cl_ent *e;
  if (!k || k->count || !cl_alpha (k->text[0])) return 0;
  e = cl_find (&C->constint, nd_cstr (k));
  if (!e) return 0;
  *v = e->num;
  return 1;
}
static int cl_is_va_rec (struct cs_ty *c, char *tag) { return (c->k == TY_STRUCT) && c->rec->tag && same (c->rec->tag, c->rec->tlen, tag); }
/* a type under its typedef names as c2ff.pl's ctype reads them: the unit's own
   typedef of the name, else the one all units share (the first that is not
   void: _IO_lock_t outside and inside libio's lock) */
static struct cs_ty *cl_td_walk (struct cs_ty *t)
{
  while (cs_sugar (t)) {
    if (t->k == TY_TYPEDEF && t->name) {
      char *nm = cl_copy (t->name, t->nlen);
      struct cs_ty *g = 0;
      if (C->cu) g = cl_get (&C->owntd, nm);
      if (!g) g = cl_get (&C->typedef_t, nm);
      if (g) { t = g; continue; }
    }
    t = t->to;
  }
  return t;
}
static void cl_ctype (struct cs_ty *t, struct cl_list *o)
{
  int q = cs_quals (t);
  struct cs_ty *c = cs_canon (cl_td_walk (t));
  if (q & Q_FS) { if (c->k != TY_ARRAY) cl_w (o, "fs"); }
  while (c->k == TY_ATOMIC) c = cs_canon (c->to);
  switch (c->k) {
  case TY_VOID: cl_w (o, "void"); return;
  case TY_BOOL: cl_w (o, "u8"); return;
  case TY_CHAR: cl_w (o, "char"); return;
  case TY_SCHAR: cl_w (o, "i8"); return;
  case TY_UCHAR: cl_w (o, "u8"); return;
  case TY_SHORT: cl_w (o, "short"); return;
  case TY_USHORT: cl_w (o, "u16"); return;
  case TY_INT: cl_w (o, "int"); return;
  case TY_UINT: cl_w (o, "u32"); return;
  case TY_LONG: cl_w (o, "long"); return;
  case TY_ULONG: if (C->target == 3) cl_w (o, "u32"); else cl_w (o, "u64"); return;
  case TY_LLONG: cl_w (o, "i64"); return;
  case TY_ULLONG: cl_w (o, "u64"); return;
  case TY_FLOAT: cl_w (o, "float"); return;
  case TY_DOUBLE: cl_w (o, "double"); return;
  case TY_LDOUBLE: cl_w (o, "long double"); return;
  case TY_FLOAT128: if (C->target == 1) cl_w (o, "float128"); else cl_w (o, "long double"); return;
  case TY_FLOAT16: case TY_HALF: cl_w (o, "float16"); return;
  case TY_BF16: cl_w (o, "bfloat16"); return;
  case TY_INT128: cl_w (o, "i128"); return;
  case TY_UINT128: cl_w (o, "u128"); return;
  case TY_COMPLEX: {
    int k = cs_kind (c->to);
    if (k == TY_FLOAT) cl_w (o, "complex float");
    else if (k == TY_DOUBLE) cl_w (o, "complex double");
    else if (k == TY_LDOUBLE) cl_w (o, "complex long double");
    else if (k == TY_FLOAT16) cl_w (o, "complex float16");
    else cl_fail ("no ff type for a complex of that type", 0);
    return;
  }
  case TY_PTR: {
    struct cs_ty *to = cs_canon (c->to);
    if (C->target == 1 && cl_is_va_rec (to, "__va_list_tag")) { cl_w (o, "va_list"); return; }
    cl_w (o, "address");
    if (to->k == TY_FUNC) { cl_w (o, cl_fntype (to, c->to->k == TY_TYPEDEF)); return; }
    cl_ctype (c->to, o);
    return;
  }
  case TY_ARRAY:
    if (C->target == 1 && cl_is_va_rec (cs_canon (c->to), "__va_list_tag") && c->n == 1) { cl_w (o, "va_list"); return; }
    cl_w (o, "array");
    cl_ctype (c->to, o);
    if (c->n == -2) {
      long long cv;
      if (!cl_vla_const (c, &cv)) cl_fail ("no ff type for a variable-length array here", 0);
      cl_w (o, cl_num (cv));
    }
    else if (c->n < 0) cl_w (o, "[]");
    else cl_w (o, cl_num (c->n));
    return;
  case TY_VECTOR:
    cl_w (o, "vector");
    cl_ctype (c->to, o);
    cl_w (o, cl_num (c->n / cs_ty_size (c->to)));
    return;
  case TY_STRUCT: case TY_UNION: case TY_ENUM:
    if (c->k == TY_STRUCT && C->target >= 2 && cl_is_va_rec (c, "__va_list")) { cl_w (o, "va_list"); return; }
    cl_w (o, cl_tag (c->rec));
    return;
  }
  cl_fail ("no ff type for a type of kind", cl_num (c->k));
}
static struct cl_list *cl_ct (struct cs_ty *t) { struct cl_list *l = cl_l (); cl_ctype (t, l); return l; }
/* the bytes of a scalar or an address: what the atomics need (c2ff's %wsize) */
static long cl_wsize (char *w)
{
  if (cl_eq (w, "char") || cl_eq (w, "i8") || cl_eq (w, "u8")) return 1;
  if (cl_eq (w, "short") || cl_eq (w, "i16") || cl_eq (w, "u16")) return 2;
  if (cl_eq (w, "int") || cl_eq (w, "i32") || cl_eq (w, "u32")) return 4;
  if (cl_eq (w, "long") || cl_eq (w, "i64") || cl_eq (w, "u64") || cl_eq (w, "address")) return 8;
  return 0;
}
/* csize: 0 where it has none */
static long cl_csize (struct cs_ty *t)
{
  struct cl_list *l;
  if (cs_kind (t) == TY_ENUM && cs_kind (t) == TY_ENUM) { return 4; }
  l = cl_ct (t);
  return cl_wsize ((char *) l->v[0]->text);
}
/* the C name a floating type has, as c2ff's tword: "" for none */
static char *cl_tword_t (struct cs_ty *t)
{
  int k = cs_kind (t);
  if (k == TY_FLOAT) return "float";
  if (k == TY_DOUBLE) return "double";
  if (k == TY_LDOUBLE) return "long double";
  if (k == TY_FLOAT128) return "float128";
  return "";
}
static char *cl_q128 (void) { if (C->target == 1) return "float128"; return "long double"; }
/* ---- the unit's declarations ---- */
static void cl_ps_names (struct cs_decl *d)
{
  long i = 0;
  while (i < d->np) { cl_local_name (d->ps[i].name, d->ps[i].nlen); i++; }
}
static int cl_section_name_ok (char *s)
{
  long i = 0;
  if (!cl_alpha (s[0])) return 0;
  while (s[i]) { if (!cl_alpha (s[i]) && !cl_digit (s[i])) return 0; i++; }
  return 1;
}
/* asm ("memset = __memset_generic") at the top of a unit: its calls of memset are of __memset_generic */
static void cl_file_asm (struct node *n)
{
  struct cs_buf b;
  long i = 0, j;
  char *s;
  cs_b_init (&b);
  while (i < n->count && !cs_is (n->kids[i], ":")) {
    struct node *k = n->kids[i];
    if (cs_is (k, "str")) { long m = 0; while (m < k->count) { struct cs_buf t; cs_b_init (&t); cs_tok_bytes (k->kids[m], &t); cs_b_bytes (&b, t.p + 1, t.n - 2); m++; } }
    else if (k->len && k->text[0] == '"') { struct cs_buf t; cs_b_init (&t); cs_tok_bytes (k, &t); cs_b_bytes (&b, t.p + 1, t.n - 2); }
    i++;
  }
  s = cl_copy (b.p, b.n);
  i = 0;
  while (s[i] == ' ' || s[i] == '\t') i++;
  j = i;
  while (cl_alpha (s[j]) || cl_digit (s[j]) || s[j] == '.') j++;
  if (j > i) {
    long e = j, x;
    while (s[e] == ' ' || s[e] == '\t') e++;
    if (s[e] == '=') {
      e++;
      while (s[e] == ' ' || s[e] == '\t') e++;
      x = e;
      while (cl_alpha (s[x]) || cl_digit (s[x]) || s[x] == '.') x++;
      if (x > e) {
        long y = x;
        while (s[y] == ' ' || s[y] == '\t') y++;
        if (!s[y]) cl_put (&C->own, cl_copy ((unsigned char *) s + i, j - i), cl_copy ((unsigned char *) s + e, x - e));
      }
    }
  }
}
static struct cs_ex *cl_p (struct cs_ex *e);
static int cl_int_const (struct cs_ex *n, long long *v);
static int cl_same_text (unsigned char *a, long na, unsigned char *b, long nb)
{
  long i = 0;
  if (na != nb) return 0;
  while (i < na) { if (a[i] != b[i]) return 0; i++; }
  return 1;
}
static int cl_same_def (struct cs_rec *a, struct cs_rec *b)
{
  if (a == b) return 1;
  return cl_same_text (a->dtext, a->dlen, b->dtext, b->dlen);
}
/* the text of a function's or a variable's definition: from its specifiers to its last token (def_text, clang's range) */
static void cl_def_text (struct cs_top *t)
{
  struct cs_decl *d = t->d;
  long b = 0, e = 0;
  if (!d || d->dtext) return;
  if (t->specs) b = c_off_of (t->specs);
  if (t->src) e = c_off_of (t->src);
  if (b && e && e >= b) { d->dtext = T->src + b - 1; d->dlen = e - b; }
  else { d->dtext = (unsigned char *) ""; d->dlen = 0; }
}
static char *cl_td_key (struct cs_ty *t);
/* whether a definition's text names, in this unit, what it does not in unit v: a record either has of its own, or a typedef (names_otherwise) */
static int cl_names_otherwise (unsigned char *p, long n, struct cl_unit *v)
{
  long i = 0;
  if (!C->ownrec.count && !C->owntd.count && !v->ownrec.count && !v->owntd.count) return 0;
  while (i < n) {
    long b = i;
    char *w;
    if (!cl_alpha (p[i]) && !cl_digit (p[i])) { i++; continue; }
    while (i < n && (cl_alpha (p[i]) || cl_digit (p[i]))) i++;
    if (cl_digit (p[b])) continue;
    w = cl_copy (p + b, i - b);
    if (cl_eq (w, "struct") || cl_eq (w, "union")) {
      long j = i;
      while (j < n && (p[j] == ' ' || p[j] == '\n' || p[j] == '\t' || p[j] == '\r' || p[j] == '\f' || p[j] == '\v')) j++;
      if (j > i && j < n && cl_alpha (p[j])) {
        long e = j;
        char *k, *a, *c;
        while (e < n && (cl_alpha (p[e]) || cl_digit (p[e]))) e++;
        k = cl_cat3 (w, " ", cl_copy (p + j, e - j));
        a = cl_get (&C->ownrec, k);
        c = cl_get (&v->ownrec, k);
        if (!cl_eq (a ? a : "", c ? c : "")) return 1;
        i = e;
        continue;
      }
    }
    {
      struct cs_ty *a = cl_get (&C->owntd, w), *c = cl_get (&v->owntd, w);
      if ((a || c) && !(a && c && cl_eq (cl_td_key (a), cl_td_key (c)))) return 1;
    }
  }
  return 0;
}
/* the name a static takes that another unit defines otherwise: its own, named with the unit (own_name) */
static char *cl_own_name (struct cl_map *map, char *name, struct cs_decl *d)
{
  struct cs_decl *old;
  char *k;
  if (C->treedefs.count && d->sc == SC_STATIC && cl_val (&C->treedefs, cl_ffname (name))) {
    k = cl_cat3 (name, " ", cl_unit_name ());
    cl_put (&C->own, name, k);
    return k;
  }
  old = cl_get (map, name);
  if (!old) return name;
  if (old->unit == C->cu || d->sc != SC_STATIC || old->sc != SC_STATIC) return name;
  if (cl_same_text (d->dtext, d->dlen, old->dtext, old->dlen) && !cl_names_otherwise (d->dtext, d->dlen, old->unit)) return name;
  k = cl_cat3 (name, " ", cl_unit_name ());
  cl_put (&C->own, name, k);
  return k;
}
static void cl_rec_own (char *key, struct cs_rec *d)
{
  char *ownk = cl_cat3 (key, " ", cl_unit_name ());
  cl_put_new (&C->rec, ownk, d);
  cl_put_new (&C->recunit, ownk, C->cu);
  cl_put (&C->ownrec, key, ownk);
}
/* a record tag's definition: the first is everyone's; a unit that defines it otherwise has its own, named with the unit (reg_rec): 1 where it is the first */
static int cl_reg_rec (char *key, struct cs_rec *d)
{
  struct cs_rec *o = cl_get (&C->rec, key);
  struct cl_unit *ru;
  if (!o) { cl_put (&C->rec, key, d); cl_put (&C->recunit, key, C->cu); return 1; }
  ru = cl_get (&C->recunit, key);
  if (!ru || ru == C->cu) return 0;
  if (cl_same_def (d, o)) {
    struct cl_shared *s = alloc (sizeof (struct cl_shared));
    s->key = key; s->d = d; s->nxt = C->cu->shared; C->cu->shared = s;
    return 0;
  }
  cl_rec_own (key, d);
  return 0;
}
/* a unit's records of the first's text: its own too where they name otherwise, until there are no more (own_by_names) */
static void cl_own_by_names (void)
{
  int more = 1;
  while (more) {
    struct cl_shared *s = C->cu->shared;
    more = 0;
    while (s) {
      if (!cl_get (&C->ownrec, s->key) && cl_names_otherwise (s->d->dtext, s->d->dlen, cl_get (&C->recunit, s->key))) {
        cl_rec_own (s->key, s->d);
        more = 1;
      }
      s = s->nxt;
    }
  }
}
static void cl_pass_tags (struct cs_decl *d, char *fk)
{
  long i = 0;
  while (i < d->ntags) {
    struct cs_rec *t = d->tags[i];
    if (t->k == TY_ENUM) cl_index_enum (t);
    else if (t->tag) {
      char *nm = cl_copy (t->tag, t->tlen), *key = cl_cat3 (cl_rec_kind (t), " ", nm);
      struct cs_rec *o = cl_get (&C->rec, key);
      /* (a tag that another function of the unit defines otherwise is this function's own, named with it) */
      if (fk && o && cl_get (&C->recunit, key) == C->cu && !cl_same_def (t, o)) {
        char *ownk = cl_cat3 (key, " ", cl_ffname (fk));
        cl_put_new (&C->rec, ownk, t);
        cl_put_new (&C->recunit, ownk, C->cu);
        cl_put (&C->ownfn, cl_cat3 (fk, "\t", key), ownk);
      } else if (cl_reg_rec (key, t)) {
        cl_anon_fields (t, nm);
        if (fk) cl_put (&C->recfn, key, fk);
      }
    }
    i++;
  }
}
/* a type's spelling, under the typedef names at its top (c2ff.pl's qt: desugaredQualType) */
static char *cl_td_key (struct cs_ty *t)
{
  struct cs_buf b;
  while (t->k == TY_TYPEDEF) t = t->to;
  cs_b_init (&b);
  cs_p_ty (&b, t, 1);
  return cl_copy (b.p, b.n);
}
static void cl_pass_typedef (struct cs_decl *d, char *name)
{
  struct cs_ty *c = cs_canon (d->t);
  char *was = cl_get (&C->typedef_k, name), *q;
  cl_set (&C->typedefs, name);
  if ((c->k == TY_STRUCT || c->k == TY_UNION || c->k == TY_ENUM) && !c->rec->tag && c->rec->td && same (c->rec->td, c->rec->tdlen, name)) {
    if (c->k == TY_ENUM) {
      /* a typedef of an anonymous enum: the enum takes its name */
      long i = 0;
      char *tag = cl_cat ("enum ", name);
      cl_set_enumd (tag, c->rec);
      cl_put_new (&C->tagname, tag, cl_ffname (name));
      if (!was) { cl_put (&C->typedef_k, name, tag); cl_put (&C->typedef_t, name, d->t); }
      while (i < c->rec->nenums) { cl_put (&C->enumof, cl_dn (c->rec->enums[i]), tag); i++; }
      return;
    }
    /* a typedef of an anonymous struct or union: the record is its tag */
    q = cl_cat3 (cl_rec_kind (c->rec), " ", name);
    cl_put_new (&C->rec, q, c->rec);
    cl_anon_fields (c->rec, name);
    if (!was || cl_eq (was, "void")) { cl_put (&C->typedef_k, name, q); cl_put (&C->typedef_t, name, d->t); was = q; }
    if (!cl_eq (was, q)) cl_put (&C->owntd, name, d->t);
    return;
  }
  q = cl_td_key (d->t);
  if (!was || cl_eq (was, "void")) { cl_put (&C->typedef_k, name, q); cl_put (&C->typedef_t, name, d->t); was = q; }
  if (!cl_eq (was, q) && !cl_eq (q, "void")) cl_put (&C->owntd, name, d->t);
}
static void cl_pass_one (struct cs_top *t)
{
  struct cs_decl *d = t->d;
  char *name, *fkey = 0;
  if (t->k == TOP_ENUM || t->k == TOP_REC) {
    struct cs_rec *r = t->r;
    if (r->k == TY_ENUM) cl_index_enum (r);
    if (!r->tag) { C->lastanon = r; return; }
    name = cl_copy (r->tag, r->tlen);
    if (r->k == TY_ENUM) cl_set_enumd (cl_cat ("enum ", name), r);
    else {
      char *key = cl_cat3 (cl_rec_kind (r), " ", name);
      char *f = cl_get (&C->recfn, key);
      /* (a tag a function of the unit defined first, otherwise, is that function's own, the unit's the global one) */
      if (f) {
        struct cs_rec *o = cl_get (&C->rec, key);
        cl_put (&C->recfn, key, 0);
        if (cl_get (&C->recunit, key) == C->cu && !cl_same_def (r, o)) {
          char *ownk = cl_cat3 (key, " ", cl_ffname (f));
          cl_put_new (&C->rec, ownk, o);
          cl_put_new (&C->recunit, ownk, C->cu);
          cl_put (&C->ownfn, cl_cat3 (f, "\t", key), ownk);
          cl_put (&C->rec, key, r);
          cl_anon_fields (r, name);
          return;
        }
      }
      if (cl_reg_rec (key, r)) cl_anon_fields (r, name);
    }
    return;
  }
  if (t->k == TOP_ASM) { cl_file_asm (t->src); return; }
  if (t->k == TOP_WEAK) {
    /* #pragma weak name */
    char *s = nd_cstr (t->src);
    long i = 0;
    if (s[i] == '#') i++;
    while (s[i] == ' ') i++;
    if (cl_starts (s + i, "pragma")) {
      i = i + 6;
      while (s[i] == ' ') i++;
      if (cl_starts (s + i, "weak ")) {
        long j;
        i = i + 5;
        while (s[i] == ' ') i++;
        j = i;
        while (cl_alpha (s[j]) || cl_digit (s[j])) j++;
        if (j > i) {
          char *nm = cl_copy ((unsigned char *) s + i, j - i);
          struct cs_decl *now = cl_get (&C->lastdecl, nm);
          cl_set (&C->pragma_weak, nm);
          if (now) cl_put_new (&C->weak, nm, now);
        }
      }
    }
    return;
  }
  name = cl_dn (d);
  d->unit = C->cu;
  cl_def_text (t);
  if (d->k == DK_VAR || d->k == DK_FUNC) cl_put (&C->lastdecl, name, d);
  if (d->k == DK_VAR && C->lastanon) {
    struct cs_rec *an = cl_anon_in (d->t);
    if (an) {
      char *key = cl_anon_key (an), *kind = cl_rec_kind (C->lastanon), *tn = cl_cat3 (name, " ", kind);
      if (!cl_has (&C->anon_tag, key)) {
        cl_put (&C->anon_tag, key, cl_cat3 (kind, " ", tn));
        cl_put (&C->anon_name, key, tn);
      }
      if (C->lastanon->k == TY_ENUM) {
        long i = 0;
        char *atag = cl_get (&C->anon_tag, key);
        cl_put_new (&C->enumd, cl_cat ("enum ", tn), C->lastanon);
        cl_put_new (&C->tagname, atag, cl_get (&C->anon_name, key));
        while (i < C->lastanon->nenums) { cl_put (&C->enumof, cl_dn (C->lastanon->enums[i]), atag); i++; }
      } else {
        cl_put_new (&C->rec, cl_cat3 (kind, " ", tn), C->lastanon);
        cl_anon_fields (C->lastanon, tn);
      }
    }
  }
  /* a program's function C names by another asm name: the unit's calls are of that name (not glibc's __GI_ names) */
  if (t->k == TOP_FN && C->program && d->sp && d->sp->asmlabel && !cl_eq (d->sp->asmlabel, name) && !cl_starts (d->sp->asmlabel, "__GI_")) cl_put (&C->own, name, d->sp->asmlabel);
  if (d->sc == SC_REGISTER && d->sp && d->sp->asmlabel) { cl_put (&C->regvar, name, d->sp->asmlabel); return; }
  if ((d->k == DK_VAR || d->k == DK_FUNC) && ((d->sp && (d->sp->weak || d->sp->err)) || cl_val (&C->pragma_weak, name) || cl_val (&C->forceweak, name))) cl_put_new (&C->weak, name, d);
  if (t->k == TOP_TYPEDEF) { cl_pass_typedef (d, name); return; }
  if (t->k == TOP_FN) {
    if (d->sp && d->sp->aliasee) { cl_put (&C->alias, name, d->sp->aliasee); cl_put (&C->aliasunit, name, C->cu); return; }
    if (d->sp && d->sp->ifunc) { cl_put (&C->ifunc, name, d); return; }
    if (d->body && !(C->treedefs.count && (d->inl || (d->sp && d->sp->inl)) && d->sc == SC_EXTERN && cl_val (&C->treedefs, cl_ffname (name)))) {
      char *k = cl_own_name (&C->fn, name, d);
      fkey = k;
      cl_put_new (&C->fn, k, d);
      if (d->sp && d->sp->ctor) { cl_put (&C->ctor, k, d); cl_push (&C->cu->ctors, cl_n (k)); }
    }
    cl_ps_names (d);
    cl_pass_tags (d, fkey);
    return;
  }
  /* a variable */
  if (d->sp && d->sp->aliasee) { cl_put (&C->alias, name, d->sp->aliasee); cl_put (&C->aliasunit, name, C->cu); return; }
  /* (a const integer global of a number: an array of it as count is of variable length, the same as of the number) */
  if (d->init && (cs_quals (d->t) & Q_CONST)) {
    int k = cs_kind (d->t);
    long long v;
    if (k == TY_CHAR || k == TY_SCHAR || k == TY_UCHAR || k == TY_SHORT || k == TY_USHORT || k == TY_INT || k == TY_UINT || k == TY_LONG || k == TY_ULONG || k == TY_LLONG || k == TY_ULLONG) {
      if (cl_int_const (cl_p (d->init), &v)) cl_make (&C->constint, name)->num = v;
    }
  }
  if (d->sc != SC_EXTERN || cl_val (&C->zero, name)) {
    char *k = cl_own_name (&C->var, name, d);
    if (!cl_has (&C->var, k) && d->sp && d->sp->section && cl_section_name_ok (d->sp->section)) {
      /* (a global of a named section: reached with the section's bounds) */
      struct cl_list *l = cl_get (&C->section, d->sp->section);
      if (!l) { l = cl_l (); cl_put (&C->section, d->sp->section, l); }
      cl_push (l, cl_n (k));
    }
    cl_put_new (&C->var, k, d);
  }
}
static void cl_pass (void)
{
  struct cs_top *t;
  struct cs_rec *r = T->allrec1;
  /* the anonymous records, named for their places (anon_places, places) */
  while (r) {
    if (r->k != TY_ENUM && !r->tag) {
      char *key = cl_anon_key (r);
      /* (without its column: struct at file:line) */
      long n = cstrlen (key);
      char *name;
      while (n > 0 && key[n - 1] != ':') n--;
      name = cl_cat ("at ", cl_copy ((unsigned char *) key, n - 1));
      name = cl_cat3 (cl_rec_kind (r), " ", name);
      if (!cl_has (&C->anon_tag, key)) {
        char *tag = cl_cat3 (cl_rec_kind (r), " ", name);
        cl_put (&C->anon_tag, key, tag);
        cl_put (&C->anon_name, key, name);
        cl_put_new (&C->rec, tag, r);
        cl_put_new (&C->recunit, tag, C->cu);
      } else {
        /* (the same place in another unit, defined otherwise there: a skeleton included with another type: that unit's own, named with it) */
        char *atag = cl_get (&C->anon_tag, key);
        struct cs_rec *o = cl_get (&C->rec, atag);
        struct cl_unit *ru = cl_get (&C->recunit, atag);
        if (o && ru && ru != C->cu && !cl_same_def (r, o)) {
          char *ownn = cl_cat3 (name, " ", cl_unit_name ());
          char *tag = cl_cat3 (cl_rec_kind (r), " ", ownn);
          cl_put (&C->ownanon, key, tag);
          cl_put_new (&C->rec, tag, r);
          cl_put_new (&C->recunit, tag, C->cu);
        }
      }
    }
    r = r->allnext;
  }
  C->lastdecl.tab = 0;
  C->lastdecl.count = 0;
  C->pragma_weak.tab = 0;
  C->pragma_weak.count = 0;
  t = T->top1;
  while (t) { cl_pass_one (t); t = t->nxt; }
  t = T->ext1;
  while (t) { cl_pass_one (t); t = t->nxt; }
  cl_own_by_names ();
}
