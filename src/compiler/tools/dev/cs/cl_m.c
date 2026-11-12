/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cl_m.c (in cs.c): what a unit's roots reach, its types, the page: gen/c2ff.pl's main */
static void cl_read_index (void);
/* into a unit: what is its own, and T and the parser's marks; 0: none (T stays) */
static void cl_enter (struct cl_unit *u)
{
  struct cl_unit *o = C->cu;
  if (o == u) return;
  if (o) {
    o->own = C->own; o->constint = C->constint; o->ownfn = C->ownfn; o->text_item = C->text_item;
    o->owntd = C->owntd; o->ownrec = C->ownrec; o->ownanon = C->ownanon;
  }
  if (u) {
    C->own = u->own; C->constint = u->constint; C->ownfn = u->ownfn; C->text_item = u->text_item;
    C->owntd = u->owntd; C->ownrec = u->ownrec; C->ownanon = u->ownanon;
    C->ifile = u->i;
    T = u->t;
    c_state_set (u->s);
  } else {
    C->own = C->empty; C->constint = C->empty; C->ownfn = C->empty; C->text_item = C->empty;
    C->owntd = C->empty; C->ownrec = C->empty; C->ownanon = C->empty;
  }
  C->cu = u;
}
static void cl_ifunc_node (char *name, struct cs_decl *d)
{
  struct cs_ty *f = cs_canon (d->t);
  struct cl_list *x = cl_l ();
  long i = 0;
  cl_enter (0);
  cl_w (x, "ifunc");
  cl_w (x, cl_ffname (d->sp->ifunc));
  cl_ctype (f->to, x);
  while (i < f->np) {
    cl_push (x, cl_nl (cl_cat3 ("p", cl_num (i + 1), ":"), cl_ct (f->ps[i])));
    i++;
  }
  cl_out_of (cl_nl (cl_cat (cl_ffname (name), ":"), x), d->unit);
  cl_want (d->sp->ifunc);
}
static void cl_want_ctors (void)
{
  long i = 0;
  struct cl_list *l = &C->cu->ctors;
  while (i < l->n) { cl_want ((char *) l->v[i]->text); i++; }
}
static char *cl_next_name (void)
{
  if (C->attodo < C->ntodo) {
    char *s = (char *) C->todo[C->attodo];
    C->attodo = C->attodo + 1;
    return s;
  }
  while (C->atroots < C->nroots) {
    char *r = C->roots[C->atroots];
    C->atroots = C->atroots + 1;
    if (!cl_val (&C->done, r)) { cl_set (&C->done, r); return r; }
  }
  return 0;
}
/* (a definition left out: what it had made stays; the state of the one being translated goes) */
static void cl_leave_out (char *name)
{
  C->jb = 0;
  C->cur_fn = 0;
  C->cur_global = 0;
  C->has_cur_global = 0;
  C->in_global = 0;
  C->lfile = 0;
  C->lline = 0;
  cl_set (&C->left_out, cl_ffname (name));
  err_str ("csema: left out: ");
  err_str (name);
  err_str ("\n");
}
static void cl_reach (void)
{
  char *name;
  long buf[64];
  while ((name = cl_next_name ())) {
    char *a = cl_get (&C->alias, name);
    struct cs_decl *d;
    if (a) {
      struct cl_list *x = cl_l ();
      /* (of what its unit names: a static of its own) */
      cl_enter (cl_get (&C->aliasunit, name));
      a = cl_own (a);
      cl_w (x, "alias");
      cl_w (x, cl_ffname (a));
      cl_out_of (cl_nl (cl_cat (cl_ffname (name), ":"), x), cl_get (&C->aliasunit, name));
      cl_want (a);
      continue;
    }
    d = cl_get (&C->ifunc, name);
    if (d) { cl_ifunc_node (name, d); continue; }
    d = cl_get (&C->fn, name);
    if (d) {
      struct node *f;
      cl_enter (d->unit);
      cl_want_ctors ();
      if (C->keep_going) {
        if (((long (*)(long *)) cp_jump[0]) (buf)) { cl_leave_out (name); continue; }
        C->jb = buf;
      }
      f = cl_function (name, d);
      C->jb = 0;
      cl_out (f);
      continue;
    }
    d = cl_get (&C->var, name);
    if (d) {
      struct node *v;
      char *nn = 0;
      cl_enter (d->unit);
      cl_want_ctors ();
      if (C->keep_going) {
        if (((long (*)(long *)) cp_jump[0]) (buf)) { cl_leave_out (name); continue; }
        C->jb = buf;
      }
      C->cur_global = name;
      C->has_cur_global = 1;
      if (!cl_eq (name, cl_dn (d))) nn = cl_ffname (name);
      v = cl_decl (d, 1, nn);
      C->has_cur_global = 0;
      C->jb = 0;
      cl_out (v);
      continue;
    }
    /* an absolute symbol of a unit's top-level asm (cl_asm_absdefs): a char of its value there */
    if (cl_get (&C->absdef, name)) {
      struct cl_list *x = cl_l ();
      struct node *vn = cl_get (&C->absdef, name);
      cl_enter ((struct cl_unit *) cl_get (&C->absdef, cl_cat (name, " unit")));
      cl_w (x, "char");
      cl_push (x, cl_n ((char *) vn->text));
      cl_out (cl_nl (cl_cat (cl_ffname (name), ":"), x));
      continue;
    }
    cl_enter (0);
    d = cl_get (&C->weak, name);
    if (d && cl_val (&C->treedefs, cl_ffname (name))) continue;
    if (d) {
      struct cl_list *x = cl_l ();
      struct node *w;
      cl_w (x, "weak");
      if (d->k == DK_FUNC) { cl_w (x, "function"); cl_ctype (cs_canon (d->t)->to, x); }
      else cl_ctype (d->t, x);
      w = cl_nl (cl_cat (cl_ffname (name), ":"), x);
      cl_out_of (w, 0);
      continue;
    }
    /* a section's bounds: the section's globals come with them */
    if (cl_starts (name, "__start_") || cl_starts (name, "__stop_")) {
      char *sec = name + (cl_starts (name, "__start_") ? 8 : 7);
      struct cl_list *l = cl_get (&C->section, sec);
      if (l) { long i = 0; while (i < l->n) { cl_want ((char *) l->v[i]->text); i++; } continue; }
    }
    /* no definition: left out, as c2ff says */
  }
}
static char *cl_unit_name_of (struct cl_unit *u)
{
  /* s{^.*\/([^/]+/[^/]+)\.i$}{$1} */
  char *s;
  long n, e, slashes = 0, b;
  if (!u) return "weak";
  s = u->i;
  n = cstrlen (s);
  e = n;
  if (cl_ends (s, ".i")) e = n - 2;
  b = e;
  while (b > 0) { if (s[b - 1] == '/') { slashes++; if (slashes == 2) break; } b--; }
  /* (not of that form: as it is) */
  if (slashes < 2 || !cl_ends (s, ".i")) return s;
  return cl_copy ((unsigned char *) s + b, e - b);
}
static char *cl_unit_name (void) { return cl_unit_name_of (C->cu); }
static void cl_enum_rename (char *c, char **out)
{
  char *n = cl_ffname (c);
  struct cl_list *refs = cl_get (&C->enumref, c);
  *out = n;
  if (!cl_val (&C->enumused, n) || !refs || !cl_get (&C->enumunit, c)) return;
  {
    char *nw = cl_ffname (cl_cat3 (c, " ", cl_unit_name_of (cl_get (&C->enumunit, c))));
    long i = 0;
    while (i < refs->n) { refs->v[i]->text = (unsigned char *) nw; refs->v[i]->len = cstrlen (nw); i++; }
    *out = nw;
  }
}
static void cl_record_node (char *tag, struct cs_rec *d, char *kind)
{
  struct cl_list *x = cl_l ();
  struct cs_field *fds[4096];
  long nf = 0, i = 0, pad = 0;
  long long zalign = 0, alnv = 0;
  int hasal = 0;
  struct cs_field *f;
  char *name = cl_get (&C->tagname, tag);
  if (d) { f = d->first; while (f) { if (nf < 4096) { fds[nf] = f; nf++; } f = f->nxt; } }
  while (nf > 0 && fds[nf - 1]->width == 0 && !(fds[nf - 1]->name && fds[nf - 1]->nlen)) {
    char *t = cl_join (cl_ct (fds[nf - 1]->t));
    long sz = 0;
    if (cl_eq (t, "char") || cl_eq (t, "i8") || cl_eq (t, "u8")) sz = 1;
    else if (cl_eq (t, "short") || cl_eq (t, "i16") || cl_eq (t, "u16")) sz = 2;
    else if (cl_eq (t, "int") || cl_eq (t, "i32") || cl_eq (t, "u32")) sz = 4;
    else if (cl_eq (t, "i64") || cl_eq (t, "u64")) sz = 8;
    else if (cl_eq (t, "long")) sz = C->target == 3 ? 4 : 8;
    else cl_fail ("a bitfield of width 0 of a", t);
    if (sz > zalign) zalign = sz;
    nf--;
  }
  if (d && d->hasaln) { alnv = d->alnmax; hasal = 1; }
  if (d && d->tdalign) { if (!hasal || d->tdalign > alnv) alnv = d->tdalign; hasal = 1; }
  if (zalign) { if (!hasal || zalign > alnv) alnv = zalign; hasal = 1; }
  cl_w (x, kind);
  /* (a packed record, C's packed attribute after its braces: packed right after its kind) */
  if (d && d->packed) cl_push (x, cl_n ("packed"));
  if (hasal) cl_push (x, cl_n1 ("align", cl_num_node (alnv)));
  while (i < nf) {
    struct cl_list *y = cl_l ();
    char *fnm;
    f = fds[i];
    {
      /* (and a field whose type is a typedef aligned more than its type: arm's __jmp_buf, int [64]
         aligned (8), in struct __jmp_buf_tag, gcc's 392 bytes; ff names the typedef's type) */
      long long fal = f->hasaln ? f->alnmax : 0;
      struct cs_ty *s = f->t;
      while (s && cs_sugar (s)) {
        if (s->k == TY_TYPEDEF && s->algn) { if (s->algn > fal && s->algn > cs_ty_align (s->to)) fal = s->algn; break; }
        s = s->to;
      }
      /* (a packed field, C's packed attribute: packed first, then its align) */
      if (f->packed) cl_push (y, cl_n ("packed"));
      if (fal) cl_push (y, cl_n1 ("align", cl_num_node (fal)));
    }
    cl_ctype (f->t, y);
    if (f->width >= 0) {
      if (f->width == 0) cl_fail ("a bitfield of width 0", 0);
      cl_push (y, cl_num_node (f->width));
    }
    if (f->name && f->nlen) fnm = cl_cat (cl_ffname (cl_copy (f->name, f->nlen)), ":");
    else if (f->width >= 0) { pad++; fnm = cl_cat3 ("padding ", cl_num (pad), ":"); }
    else fnm = ":";
    cl_push (x, cl_nl (fnm, y));
    i++;
  }
  cl_unshift1 (&C->types, cl_nl (cl_cat (name, ":"), x));
}
static void cl_enum_node (char *tag, struct cs_rec *d)
{
  struct cl_list *x = cl_l (), *e = cl_l ();
  char *name = cl_get (&C->tagname, tag);
  long i = 0;
  if (!name) {
    /* its name, where no ctype gave it yet */
    char *nm = tag + 5;
    if (cl_has (&C->var, nm) || cl_has (&C->fn, nm) || cl_has (&C->alias, nm) || cl_val (&C->localname, nm) || cl_is_fieldname (cl_ffname (nm)) || cl_val (&C->treedefs, cl_ffname (nm))) {
      name = cl_cat (nm, " enum");
      if (C->treedefs.count) name = cl_cat (name, " prog");
    }
    else name = cl_ffname (nm);
    cl_put (&C->tagname, tag, name);
  }
  cl_w (x, "enum");
  while (i < d->nenums) {
    struct cs_decl *c = d->enums[i];
    char *nn;
    struct node *k;
    cl_enum_rename (cl_dn (c), &nn);
    k = cl_n (cl_cat (nn, ":"));
    if (c->hasinit) { if (c->uns) nd_add (k, cl_n (cl_unum ((unsigned long long) c->val))); else nd_add (k, cl_num_node (c->val)); }
    cl_push (e, k);
    i++;
  }
  cl_grouped (254, e, x);
  cl_unshift1 (&C->types, cl_nl (cl_cat (name, ":"), x));
}
static void cl_types_all (void)
{
  long i;
  for (;;) {
    long nt;
    char **keys;
    int fresh = 0;
    cl_enter (0);
    while (C->fndone < C->nfnt) {
      char *name = C->fnt_name[C->fndone];
      struct cs_ty *f = C->fnt_ty[C->fndone];
      struct cl_list *x = cl_l ();
      long p = 0;
      C->fndone = C->fndone + 1;
      if (f->pcs) cl_w (x, "base pcs");
      cl_w (x, "function");
      cl_ctype (f->to, x);
      while (p < f->np) {
        cl_push (x, cl_nl (cl_cat3 ("p", cl_num (p + 1), ":"), cl_ct (f->ps[p])));
        p++;
      }
      if (f->var) cl_push (x, cl_n ("..."));
      cl_push (&C->types, cl_nl (cl_cat (name, ":"), x));
    }
    for (;;) {
      struct cl_map *pending;
      int any = 0;
      keys = cl_keys (&C->wanttag, &nt);
      i = 0;
      (void) pending;
      while (i < nt) {
        char *tag = keys[i];
        if (!cl_val (&C->tdone, tag)) {
          struct cs_rec *r = cl_get (&C->rec, tag), *e = cl_get (&C->enumd, tag);
          any = 1;
          cl_set (&C->tdone, tag);
          /* (its fields' types as its unit has them) */
          cl_enter (cl_get (&C->recunit, tag));
          C->cur_tag = tag;
          /* (a record the program only declares and its tree defines: the tree's) */
          if (C->program && !r && (cl_starts (tag, "struct ") || cl_starts (tag, "union "))) {
            char *nm = cl_starts (tag, "struct ") ? tag + 7 : tag + 6;
            char *fnm = cl_get (&C->tagname, tag);
            long q = 0;
            int plain = cl_alpha (nm[0]);
            while (nm[q]) { if (!cl_alpha (nm[q]) && !cl_digit (nm[q])) plain = 0; q++; }
            if (plain && fnm && cl_val (&C->treerec, fnm)) { i++; continue; }
          }
          if (cl_starts (tag, "enum ") && !r) { if (e) cl_enum_node (tag, e); }
          else if (r) cl_record_node (tag, r, cl_starts (tag, "union ") ? "union" : "struct");
          else if (cl_starts (tag, "struct ")) cl_record_node (tag, 0, "struct");
          else if (cl_starts (tag, "union ")) cl_record_node (tag, 0, "union");
        }
        i++;
      }
      if (!any) break;
    }
    cl_enter (0);
    if (C->fndone < C->nfnt) fresh = 1;
    keys = cl_keys (&C->wanttag, &nt);
    i = 0;
    while (i < nt) { if (!cl_val (&C->tdone, keys[i])) fresh = 1; i++; }
    if (!fresh) break;
  }
}
/* ---- the text ---- */
static void cl_escape (struct cs_buf *b, char *s)
{
  long n = cstrlen (s), i = 0;
  if (!n) { cs_b_str (b, "\\e"); return; }
  while (i < n) {
    unsigned char c = s[i];
    if (c == '\\') cs_b_str (b, "\\\\");
    else if (c == '\n') cs_b_str (b, "\\n");
    else if (c < 0x20 || c == 0x7f) { cs_b_str (b, "\\x"); cs_b_byte (b, "0123456789abcdef"[c >> 4]); cs_b_byte (b, "0123456789abcdef"[c & 15]); }
    else if (c == ' ' && (i == 0 || i == n - 1)) cs_b_str (b, "\\x20");
    else cs_b_byte (b, c);
    i++;
  }
}
static void cl_write_txt (struct node *n, long depth)
{
  struct cs_buf b;
  long i = 0;
  cs_b_init (&b);
  while (i < depth) { cs_b_str (&b, "  "); i++; }
  cl_escape (&b, (char *) n->text);
  cs_b_byte (&b, '\n');
  out_bytes (b.p, b.n);
  i = 0;
  while (i < n->count) { cl_write_txt (n->kids[i], depth + 1); i++; }
}
static struct node *cl_group (char *name, struct cl_list *n)
{
  struct cl_list *y = cl_l ();
  cl_layers (n, y);
  return cl_nl (cl_cat (name, ":"), y);
}
static void cl_reserve_form (char *s)
{
  long i = 0, n = cstrlen (s);
  if (n < 2 || s[n - 1] != ':' || !cl_alpha (s[0])) return;
  while (i < n - 1) { if (!cl_alpha (s[i]) && !cl_digit (s[i])) return; i++; }
  cl_set (&C->reserved, cl_no_colon (s));
}
/* (x86_64gnu.ff's forms, a name: without a name: under it; else what is under it, in c2ff.pl's order) */
static void cl_reserve_gnu (struct node *root)
{
  long j = 0;
  while (j < root->count) {
    struct node *x = root->kids[j];
    char *s = cl_copy (x->text, x->len);
    long i = 0, n = cstrlen (s);
    int form = n >= 2 && s[n - 1] == ':' && s[0] >= 'a' && s[0] <= 'z';
    while (form && i < n - 1) { if (!cl_alpha (s[i]) && !cl_digit (s[i])) form = 0; i++; }
    i = 0;
    while (form && i < x->count) { char *k = cl_copy (x->kids[i]->text, x->kids[i]->len); long m = cstrlen (k); if (m && k[m - 1] == ':') form = 0; i++; }
    if (form) cl_reserve_form (s);
    else cl_reserve_gnu (x);
    j++;
  }
}
/* the shared page's names: its nodes copied, each text a C string */
static struct node *cl_copy_tree (struct node *n)
{
  struct node *c = cl_n (cl_copy (n->text, n->len));
  long i = 0;
  while (i < n->count) { nd_add (c, cl_copy_tree (n->kids[i])); i++; }
  return c;
}
static void cl_read_shared (void)
{
  long n;
  unsigned char *p;
  struct node *root;
  static char *w[] = { "char", "short", "int", "long", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64", "i128", "u128", "float16", "bfloat16", "short fract", "fract", "long fract", "short accum", "accum", "long accum", "unsigned short fract", "unsigned fract", "unsigned long fract", "unsigned short accum", "unsigned accum", "unsigned long accum", "sat short fract", "sat fract", "sat long fract", "sat short accum", "sat accum", "sat long accum", "sat unsigned short fract", "sat unsigned fract", "sat unsigned long fract", "sat unsigned short accum", "sat unsigned accum", "sat unsigned long accum", "void", "type", "va_list", "float", "double", "long double", "float128", 0 };
  long i = 0;
  while (w[i]) { cl_make (&C->word, w[i])->num = 1; i++; }
  p = cp_file (C->shared, &n);
  root = cp_read_ff (p, n);
  cl_typenames (cl_copy_tree (root));
}
static struct node *cl_kid_named (struct node *n, char *s)
{
  long i = 0;
  while (i < n->count) { if (same (n->kids[i]->text, n->kids[i]->len, s)) return n->kids[i]; i++; }
  return 0;
}
/* --target: the names of the registers group of its section in shared.ff; on x86_64 its instructions' names too */
static void cl_reserve_target (void)
{
  long n, i = 0;
  unsigned char *p = cp_file (C->shared, &n);
  struct node *root = cp_read_ff (p, n), *sh = cl_kid_named (root, "shared:"), *sec, *regs;
  char *t = cs_pick (C->target == 1, "x86_64:", cs_pick (C->target == 2, "aarch64:", "arm:"));
  if (!sh) cl_fail ("no shared: in", C->shared);
  sec = cl_kid_named (sh, t);
  if (!sec) cl_fail ("no section of", t);
  regs = cl_kid_named (sec, "registers:");
  if (!regs) cl_fail ("no registers in", t);
  while (i < regs->count) {
    char *c = cl_copy (regs->kids[i]->text, regs->kids[i]->len);
    long m, e = 0;
    char **v;
    if (cl_ends (c, ":")) c = cl_no_colon (c);
    v = cl_split_ws (c, &m);
    while (e < m) { cl_set (&C->reserved, v[e]); e++; }
    i++;
  }
  if (C->target == 3) {
    static char *g[] = { "data:", "data2:", "shifts:", "multiply:", "bits:", "memory:", "atomic:", "branch:", "system:", "vfp:", "a32x:", 0 };
    long q = 0;
    while (q < sec->count) {
      long w = 0;
      struct node *x = sec->kids[q];
      int yes = 0;
      while (g[w]) { if (same (x->text, x->len, g[w])) yes = 1; w++; }
      if (yes) {
        long u = 0;
        while (u < x->count) { char *s = cl_copy (x->kids[u]->text, x->kids[u]->len); cl_reserve_form (s); u++; }
      }
      q++;
    }
  }
  if (C->target == 1) {
    static char *g[] = { "alu1:", "alu2:", "move:", "unary:", "shift1:", "shift2:", "bit:", "branch:", "set:", "cmov:", "stack:", "atomic:", "system:", "sse:", 0 };
    long q = 0;
    struct cs_buf b;
    char *gnu;
    long at;
    while (q < sec->count) {
      long w = 0;
      struct node *x = sec->kids[q];
      int yes = 0;
      while (g[w]) { if (same (x->text, x->len, g[w])) yes = 1; w++; }
      if (yes) {
        long u = 0;
        while (u < x->count) { char *s = cl_copy (x->kids[u]->text, x->kids[u]->len); cl_reserve_form (s); u++; }
      }
      q++;
    }
    /* x86_64gnu.ff, next to shared.ff */
    cs_b_init (&b);
    at = cstrlen (C->shared);
    while (at > 0 && C->shared[at - 1] != '/') at--;
    cs_b_bytes (&b, (unsigned char *) C->shared, at);
    cs_b_str (&b, "x86_64gnu.ff");
    gnu = cl_copy (b.p, b.n);
    p = cp_file (gnu, &n);
    cl_reserve_gnu (cp_read_ff (p, n));
  }
}
static void cl_begin (void)
{
  T->cl = C;
  T->nodump = 1;
  if (C->began) return;
  C->began = 1;
  C->target = T->target;
  cl_reserve ();
  C->nfieldrec = 0 - 1;
  if (C->target) cl_reserve_target ();
  if (C->indexf) cl_read_index ();
  /* (-J file: the tree's statics, a line each) */
  if (C->staticsf) {
    long n = 0, i = 0;
    unsigned char *p = cp_file (C->staticsf, &n);
    if (!p) cl_fail ("cannot read", C->staticsf);
    while (i < n) {
      long b = i;
      while (i < n && p[i] != '\n') i++;
      if (i > b) cl_set (&C->treestatic, cl_copy (p + b, i - b));
      i++;
    }
  }
}
/* a unit read: its pass */
static void cl_run (void)
{
  struct cl_unit *u = C->units[C->nunits - 1];
  u->t = T;
  u->s = c_state_get ();
  cl_enter (u);
  cl_pass ();
}
/* (-T) a program's own _start: exit (main ()) */
static void cl_write_start (void)
{
  struct cl_list *sc, *sv;
  if (!C->start) return;
  sc = cl_l ();
  sv = cl_l ();
  cl_push (sc, cl_n ("SYS_exit"));
  cl_push (sc, cl_n ("main"));
  cl_push (sv, cl_n ("void"));
  cl_push (sv, cl_nl ("syscall", sc));
  cl_write_txt (cl_nl ("_start:", sv), 0);
}
/* the license of each file a page is made of, one per file, by the file's name (Header.pm's license_nodes) */
static void cl_license_nodes_of (struct cl_list *units, struct cl_list *o)
{
  struct cl_map h, byi;
  long i = 0, n;
  char **keys;
  h.tab = 0; h.count = 0;
  byi.tab = 0; byi.count = 0;
  while (i < units->n) { struct cl_unit *u = (struct cl_unit *) units->v[i]; cl_put (&byi, u->i, u); i++; }
  keys = cl_keys (&byi, &n);
  i = 0;
  while (i < n) {
    struct cl_header *x;
    cl_enter (cl_get (&byi, keys[i]));
    x = cl_header_of ();
    cl_put_new (&h, x->file, x);
    i++;
  }
  keys = cl_keys (&h, &n);
  i = 0;
  while (i < n) {
    struct cl_header *x = cl_get (&h, keys[i]);
    cl_push (o, cl_n1 ("comment", cl_n (cl_cat3 (x->name, " ", x->file))));
    cl_push (o, cl_license_node (x));
    i++;
  }
}
/* (-K file: the statics of the tree that keep their plain names, reached: a line each, for a program's -J; c2ff.pl's --statics-out) */
static void cl_write_statics (void)
{
  struct cl_map st;
  struct cl_map *maps[2];
  char **keys;
  long fd = cp_create (C->staticsout), m = 0, i = 0, count = 0;
  if (fd < 0) cl_fail ("cannot write", C->staticsout);
  st.tab = 0; st.count = 0;
  maps[0] = &C->fn; maps[1] = &C->var;
  while (m < 2) {
    keys = cl_keys (maps[m], &count);
    i = 0;
    while (i < count) {
      struct cs_decl *d = cl_get (&C->fn, keys[i]);
      long q = 0;
      if (!d) d = cl_get (&C->var, keys[i]);
      while (keys[i][q] && keys[i][q] != ' ') q++;
      if (!keys[i][q] && cl_val (&C->done, keys[i]) && d->sc == SC_STATIC) cl_set (&st, keys[i]);
      i++;
    }
    m++;
  }
  keys = cl_keys (&st, &count);
  i = 0;
  while (i < count) {
    char *n = cl_cat (cl_ffname (keys[i]), "\n");
    cp_write (fd, (unsigned char *) n, cstrlen (n));
    i++;
  }
}
/* every unit read: what the roots reach, its types, the page */
void cl_finish (void)
{
  struct cl_list *all = cl_l ();
  long i = 0, nt, nout;
  /* (an object's constructors and destructors are roots) */
  while (i < C->nunits) {
    if (C->units[i]->object) {
      struct cl_list *l = &C->units[i]->ctors;
      long j = 0;
      while (j < l->n) { cl_want ((char *) l->v[j]->text); j++; }
    }
    i++;
  }
  cl_reach ();
  if (C->staticsout) cl_write_statics ();
  /* (an alias of what was left out is left out too: libgcc's __nehf2, of __eqhf2, a function of _Float16) */
  for (;;) {
    long r = 0, w = 0;
    int any = 0;
    struct cl_list *dropped = cl_l ();
    while (r < C->out.n) {
      struct node *x = C->out.v[r];
      if (x->count == 2 && same (x->kids[0]->text, x->kids[0]->len, "alias") && cl_val (&C->left_out, cl_txt (x->kids[1]))) { cl_push (dropped, x); any = 1; }
      else { C->out.v[w] = x; C->outu[w] = C->outu[r]; w++; }
      r++;
    }
    C->out.n = w;
    r = 0;
    while (r < dropped->n) { cl_set (&C->left_out, cl_no_colon (cl_txt (dropped->v[r]))); r++; }
    if (!any) break;
  }
  /* an enum constant whose name a function or a global has too: named with the unit */
  i = 0;
  while (i < C->out.n) {
    char *s = (char *) C->out.v[i]->text;
    if (cl_named_colon (s)) cl_set (&C->enumused, cl_no_colon (s));
    i++;
  }
  cl_types_all ();
  nt = C->types.n;
  nout = C->out.n;
  cl_append (all, &C->types);
  cl_append (all, &C->out);
  cl_read_shared ();
  cl_newwords (all);
  {
    struct cl_list *ty = cl_slice (all, 0, nt);
    if (C->program && !C->groups) {
      struct cl_header *hx;
      long q = 0;
      cl_enter (C->units[0]);
      hx = cl_header_of ();
      cl_write_txt (cl_license_node (hx), 0);
      cl_write_txt (cl_n1 ("include", cl_n (C->program)), 0);
      while (q < ty->n) { cl_write_txt (ty->v[q], 0); q++; }
      q = 0;
      while (q < nout) { cl_write_txt (all->v[nt + q], 0); q++; }
      cl_write_start ();
      out_flush ();
      return;
    }
    /* (-p with -P: a program of many files, sed's: the include, then its groups as a page's) */
    if (C->program) cl_write_txt (cl_n1 ("include", cl_n (C->program)), 0);
    {
      /* (by directory, not by unit: each function's comment names its unit) */
      struct cl_map by, inunits, seen;
      char **order = alloc ((nout + 1) * sizeof (char *));
      long ng = 0, g = 0;
      by.tab = 0; by.count = 0;
      inunits.tab = 0; inunits.count = 0;
      seen.tab = 0; seen.count = 0;
      i = 0;
      while (i < nout) {
        struct cl_unit *u = C->outu[i];
        char *un = cl_unit_name_of (u), *dir;
        struct cl_list *l;
        long d = 0;
        while (un[d] && un[d] != '/') d++;
        dir = cl_copy ((unsigned char *) un, d);
        l = cl_get (&by, dir);
        if (!l) {
          l = cl_l ();
          cl_put (&by, dir, l);
          cl_put (&inunits, dir, cl_l ());
          order[ng] = dir;
          ng++;
        }
        cl_push (l, all->v[nt + i]);
        if (u && !cl_val (&seen, u->i)) {
          cl_set (&seen, u->i);
          cl_push (cl_get (&inunits, dir), (struct node *) u);
        }
        i++;
      }
      /* (a program's types at its top, as a program's of one file: ttpc sees no enum constant of a group's type on the program page) */
      if (C->program) { long q = 0; while (q < ty->n) { cl_write_txt (ty->v[q], 0); q++; } }
      else cl_write_txt (cl_group (cl_cat (C->page, " types"), ty), 0);
      while (g < ng) {
        struct cl_list *lic = cl_l ();
        cl_license_nodes_of (cl_get (&inunits, order[g]), lic);
        cl_append (lic, cl_get (&by, order[g]));
        cl_write_txt (cl_group (cl_cat3 (C->page, " ", order[g]), lic), 0);
        g++;
      }
    }
  }
  if (C->program) cl_write_start ();
  out_flush ();
}
/* --index: the names the program's tree defines, and the records its types page defines */
static void cl_flat_layers (struct node *n, struct cl_list *o)
{
  long i = 0;
  while (i < n->count) {
    if (cl_is_layer (cl_txt (n->kids[i]))) cl_flat_layers (n->kids[i], o);
    else cl_push (o, n->kids[i]);
    i++;
  }
}
static void cl_read_index (void)
{
  long n, i = 0;
  unsigned char *p = cp_file (C->indexf, &n);
  struct node *root = cl_copy_tree (cp_read_ff (p, n)), *ix = 0;
  struct cl_list *d = cl_l ();
  struct cs_buf b;
  char *tf;
  long at;
  while (i < root->count) { if (cl_is (root->kids[i], "index:")) ix = root->kids[i]; i++; }
  if (!ix) cl_fail ("no index in", C->indexf);
  cl_flat_layers (ix, d);
  i = 0;
  while (i < d->n) {
    char *s = cl_txt (d->v[i]);
    if (cl_ends_colon (s)) s = cl_no_colon (s);
    cl_set (&C->treedefs, s);
    if (d->v[i]->count) cl_put (&C->treefile, s, cl_txt (d->v[i]->kids[0]));
    i++;
  }
  cs_b_init (&b);
  at = cstrlen (C->indexf);
  while (at > 0 && C->indexf[at - 1] != '/') at--;
  cs_b_bytes (&b, (unsigned char *) C->indexf, at);
  cs_b_str (&b, "types.ff");
  tf = cl_copy (b.p, b.n);
  p = cp_file (tf, &n);
  root = cl_copy_tree (cp_read_ff (p, n));
  i = 0;
  while (i < root->count) {
    struct cl_list *y = cl_l ();
    long j = 0;
    cl_flat_layers (root->kids[i], y);
    while (j < y->n) {
      struct node *t = y->v[j];
      struct cl_list *z = cl_l ();
      cl_flat_layers (t, z);
      if (z->n > 1 && (cl_is (z->v[0], "struct") || cl_is (z->v[0], "union")) && cl_ends_colon (cl_txt (t))) cl_set (&C->treerec, cl_no_colon (cl_txt (t)));
      j++;
    }
    i++;
  }
}
void cl_statics_file (char *f) { C->staticsf = f; }
void cl_statics_out (char *f) { C->staticsout = f; }
void cl_tree (char *name, char *spdx, char *copying, char *build, int groups) { C->tree = name; C->tree_spdx = spdx; C->tree_copying = copying; C->tree_build = build; C->groups = groups; }
void cl_options2 (char *program, char *indexf, int start, char **zero, long nzero, char **weak, long nweak, int keep_going)
{
  long i = 0;
  C->keep_going = keep_going;
  C->program = program;
  C->indexf = indexf;
  C->start = start;
  if (program) { C->ntext = 100000; C->nwide = 100000; }
  while (i < nzero) { cl_set (&C->zero, zero[i]); i++; }
  i = 0;
  while (i < nweak) { cl_set (&C->forceweak, weak[i]); i++; }
}
/* the options of csema -l */
void cl_options (char *page, char *glibc_src, char *libgcc_src, char *shared, char **roots, long nroots)
{
  C = alloc (sizeof (struct cl_state));
  C->page = page;
  C->glibc_src = glibc_src;
  C->libgcc_src = libgcc_src;
  C->shared = shared;
  C->roots = roots;
  C->nroots = nroots;
  C->w_ptr = cl_cat ("* ", "pointer");
  C->w_addr = cl_cat ("& ", "address");
}
/* before a unit is read: its name (the .i, not the copy of it clang read) */
void cl_new_unit (char *name, int object)
{
  struct cl_unit *u = alloc (sizeof (struct cl_unit));
  if (cl_ends (name, ".clang.i")) name = cl_cat (cl_copy ((unsigned char *) name, cstrlen (name) - 8), ".i");
  u->i = name;
  u->object = object;
  if (C->nunits == C->roomunits) {
    long m = C->roomunits * 2 + 64, i = 0;
    struct cl_unit **a = alloc (m * sizeof (struct cl_unit *));
    while (i < C->nunits) { a[i] = C->units[i]; i++; }
    C->units = a;
    C->roomunits = m;
  }
  C->units[C->nunits] = u;
  C->nunits = C->nunits + 1;
  c_state_new ();
}
