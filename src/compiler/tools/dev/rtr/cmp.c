/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cmp.c: roundtrip.pl's comparison, for roundtrip.c: names.txt, the normal
   forms of the C written back (ff's side), each unit's (glibc's side, from
   its cache where it has one), held against each other, and the report. */

/* ---- names.txt: each line kind, C name, glibc's name, unit */
struct nm { struct str *k, *cid, *o, *unit; };
static struct vec *bodies, *globals_, *failed_;
static struct hash *byunit, *fnunit, *gwant;
static struct hash *gfound, *gextern, *gasm, *back, *backg;
static long same_n, gsame_n;
static struct vec *diffs, *gdiffs;
static struct str *norms_txt;
static long norms_fd = -1;
static int cached;
static struct str *cachedir, *cache_stamp, *pl_path;
static char **envp_;
static struct str *env_s (char *name)   /* $ENV{name}, or 0 */
{
  long i = 0, n = slen (name);
  while (envp_ && envp_[i]) {
    char *e = envp_[i];
    if (msame ((unsigned char *) e, (unsigned char *) name, n) && e[n] == '=') return s_of (e + n + 1);
    i++;
  }
  return 0;
}
static void die_open (struct str *f, long err)
{
  struct str *m = s_of ("roundtrip: ");
  s_app (m, f); s_cat (m, ": "); s_cat (m, strerror_of (err)); s_cat (m, "\n");
  die_status = (int) err;
  die_s (m);
}
static struct str *read_or_die (struct str *f)
{
  long fd = s2_open ((char *) f->p);
  struct str *t;
  if (fd < 0) die_open (f, -fd);
  s2_close (fd);
  t = read_all ((char *) f->p);
  if (!t) die_open (f, 5);
  return t;
}
static struct str *fld (struct vec *f, long i) { return i < f->n ? f->v[i] : 0; }
static struct str *unit_json_of (struct str *u) { return ssub (u ? u : s_of (""), "\\.i$", "", ".json"); }
static void push_to (struct hash *h, struct str *k, void *x) { struct hent *e = h_put (h, k); if (!e->pv) e->pv = v_new (); v_push (e->pv, x); }
static void names_read (struct str *f)
{
  struct lines *ls = split_lines (read_or_die (f));
  long i;
  bodies = v_new (); globals_ = v_new (); failed_ = v_new ();
  byunit = h_new (); fnunit = h_new (); gwant = h_new ();
  for (i = 0; i < ls->n; i++) {
    struct vec *f = ssplit ("\t", chomp (ls->l[i]), 0);
    struct nm *b;
    if (!f->n) continue;
    b = alloc (sizeof (struct nm));
    b->k = fld (f, 0); b->cid = fld (f, 1); b->o = fld (f, 2); b->unit = fld (f, 3);
    if (!b->cid) b->cid = s_of ("");
    if (s_is (b->k, "asm")) { if (b->o) h_set (asmfn, b->o, 1); continue; }
    if (s_is (b->k, "noproto")) { if (b->o) h_set (noproto, b->o, 1); continue; }
    if (!b->o) b->o = s_of ("");
    if (s_is (b->k, "global") || s_is (b->k, "gfailed")) {
      v_push (globals_, b);
      if (s_is (b->k, "global")) push_to (gwant, ssub (b->o, "#\\d+$", "", ""), b);
      continue;
    }
    h_setp (orig, b->cid, b->o);
    if (s_is (b->k, "body") || s_is (b->k, "failed")) {
      v_push (bodies, b);
      h_setp (fnunit, b->o, unit_json_of (b->unit));
      if (s_is (b->k, "body")) push_to (byunit, unit_json_of (b->unit), b);
      else v_push (failed_, b);
    }
  }
}

/* ---- an AST's tables (roundtrip.pl's typedefs, typeofs, declty,
   enumvals, errordecls), a top declaration at a time: typeofs and enumvals
   by the first in breadth-first order, the shallowest then the first */
static struct hash *tdepth, *edepth;
static int has_text (struct str *s, char *w) { long n = slen (w), i; for (i = 0; i + n <= s->n; i++) if (msame (s->p + i, (unsigned char *) w, n)) return 1; return 0; }
static int has_body (struct jv *d)
{
  struct vec *k = jkids (d);
  long i;
  if (!kind_is (d, "FunctionDecl")) return 0;
  for (i = 0; i < k->n; i++) if (kind_is (k->v[i], "CompoundStmt")) return 1;
  return 0;
}
static struct str *num_next (struct str *x)   /* Perl's $x + 1 of an integer's text */
{
  long v = 0, i = 0, neg = 0;
  if (x && x->n && x->p[0] == '-') { neg = 1; i = 1; }
  for (; x && i < x->n && is_digit (x->p[i]); i++) v = v * 10 + (x->p[i] - '0');
  return s_num ((neg ? -v : v) + 1);
}
static void enum_decl (struct jv *n, long depth)
{
  struct vec *k = jkids (n);
  struct str *x = s_of ("-1");
  long i;
  for (i = 0; i < k->n; i++) {
    struct jv *c = k->v[i], *e;
    struct hent *h;
    struct str *nm;
    if (!kind_is (c, "EnumConstantDecl")) continue;
    e = first_nonattr (c);
    while (e && (kind_is (e, "ImplicitCastExpr") || kind_is (e, "ParenExpr"))) e = kid0 (e);
    x = e && kind_is (e, "ConstantExpr") ? jstr (e, "value") : num_next (x);
    nm = jsor (c, "name");
    h = h_find (edepth, nm);
    if (!h || h->iv > depth || !h_pv (enumval, nm)) {
      struct str *key2 = s_dup (nm);
      h_set (edepth, key2, depth);
      h_setp (enumval, key2, x ? s_dup (x) : 0);
    }
  }
}
static void walk_tables (struct jv *n, long depth, int in_enum, int errs)
{
  struct jv *ty = jget (n, "type");
  struct vec *k;
  long i;
  if (ty && ty->t == 'o') {
    struct str *q = jstr (ty, "qualType"), *dq = jstr (ty, "desugaredQualType");
    if (dq && q && has_text (q, "typeof")) {
      struct hent *h = h_find (tdepth, q);
      if (!h || h->iv > depth) { struct str *key2 = s_dup (q); h_set (tdepth, key2, depth); h_setp (typeof_, key2, s_dup (dq)); }
    }
  }
  if (errs && depth >= 2 && kind_is (n, "FunctionDecl")) {
    k = jkids (n);
    for (i = 0; i < k->n; i++) if (kind_is (k->v[i], "ErrorAttr")) { struct str *id = jstr (n, "id"); h_set (errordecl, s_dup (id ? id : s_of ("")), 1); break; }
  }
  if (!in_enum && kind_is (n, "EnumDecl")) { enum_decl (n, depth); in_enum = 1; }
  k = jkids (n);
  for (i = 0; i < k->n; i++) walk_tables (k->v[i], depth + 1, in_enum, errs);
}
static void tables_new (void)
{
  tdef = h_new (); typeof_ = h_new (); declty = h_new (); enumval = h_new (); errordecl = h_new ();
  tdepth = h_new (); edepth = h_new ();
}
static void top_tables (struct jv *d, int errs)
{
  struct jv *ty = jget (d, "type");
  struct str *q = ty ? jstr (ty, "qualType") : 0, *nm = jstr (d, "name");
  if (kind_is (d, "TypedefDecl")) h_setp (tdef, s_dup (nm ? nm : s_of ("")), q ? s_dup (q) : 0);
  if ((kind_is (d, "FunctionDecl") || kind_is (d, "VarDecl")) && nm && ty) h_setp (declty, s_dup (nm), q ? s_dup (q) : 0);
  walk_tables (d, 1, 0, errs);
}
static int back_each (struct jv *d, long at)
{
  (void) at;
  top_tables (d, 0);
  return (kind_is (d, "VarDecl") && !jis (d, "storageClass", "extern")) || has_body (d);
}
static int unit_each (struct jv *d, long at)
{
  (void) at;
  top_tables (d, 1);
  return has_body (d) || kind_is (d, "VarDecl") || kind_is (d, "FileScopeAsmDecl");
}

/* ---- ff's side: the normal form of each function and global of the C written back */
static void norm_state (void)
{
  ltype = h_new (); labels = h_new (); staticid = h_new (); constid = h_new (); locals_ = h_new ();
  regvar = h_new (); asmalias = h_new (); constint = h_new ();
  itext_of = 0;
}
static void back_norms (struct str *f)
{
  struct vec *kept;
  long i;
  side_ff = 1;
  tables_new ();
  kept = j_unit ((char *) f->p, 2, back_each, 0);
  norm_state ();
  back = h_new (); backg = h_new ();
  for (i = 0; i < kept->n; i++) {
    struct jv *d = kept->v[i];
    if (kind_is (d, "VarDecl") && !jis (d, "storageClass", "extern")) { h_setp (backg, jsor (d, "name"), gnorm (d)); continue; }
    if (!has_body (d)) continue;
    h_setp (back, jsor (d, "name"), fnorm (d));
  }
}

/* ---- glibc's side: a unit, from its cache (made of this code and after its JSON) or its JSON */
struct unit { struct str *j; struct vec *kept; struct jv *norm; struct hash *tdef, *typeof_, *declty, *enumval, *errordecl; };
static struct unit *unit_from_json (struct str *j)
{
  struct unit *u;
  a_reset (u_arena);
  a_push (u_arena);
  u = alloc (sizeof (struct unit));
  u->j = s_dup (j);
  tables_new ();
  u->kept = j_unit ((char *) j->p, 1, unit_each, 0);
  u->tdef = tdef; u->typeof_ = typeof_; u->declty = declty; u->enumval = enumval; u->errordecl = errordecl;
  a_pop ();
  return u;
}
static struct str *cache_of (struct str *j)
{
  struct str *x = cachedir ? s_join (cachedir, "", j) : s_dup (j);
  return ssub (x, "\\.json$", "", ".rtn");
}
static struct unit *load_unit (struct str *j)
{
  if (cached) {
    struct str *f = cache_of (j);
    /* (a cache older than its JSON is none to roundtrip.pl: here there is no
       stat, make's rule (the cache made of the JSON) keeps it newer) */
    if (f_exists ((char *) f->p)) {
      struct jv *c, *t;
      struct unit *u;
      a_reset (u_arena);
      a_push (u_arena);
      c = j_file ((char *) f->p, 0);
      if (s_eq (jsor (c, "stamp"), cache_stamp)) {
        u = alloc (sizeof (struct unit));
        u->j = s_dup (j);
        t = jget (c, "tables");
        u->kept = jget (c, "keep") && jget (c, "keep")->t == 'a' ? jget (c, "keep")->v : empty_vec;
        u->norm = jget (c, "norm");
        u->tdef = jhash (jget (t, "tdef")); u->typeof_ = jhash (jget (t, "typeof")); u->declty = jhash (jget (t, "declty"));
        u->enumval = jhash (jget (t, "enumval")); u->errordecl = jhash (jget (t, "errordecl"));
        a_pop ();
        return u;
      }
      a_pop ();
    }
  }
  return unit_from_json (j);
}
/* the normal form of key (f id, g id, s id) from the cache, where names.txt
   answers as it did; else none, and the unit is read from its JSON (umiss) */
static int umiss;
static int truth (struct jv *v) { return v && v != jnull && v->s && v->s->n && !s_is (v->s, "0"); }
static struct str *cnorm (struct unit *u, char *pre, struct jv *d, int fn)
{
  struct jv *e, *ask;
  long i;
  if (!u->norm) return fn ? fnorm (d) : gnorm (d);
  e = jget (u->norm, (char *) cat2 (pre, jsor (d, "id"), "")->p);
  if (e) {
    int ok = 1;
    ask = jget (e, "asked");
    for (i = 0; ask && ask->t == 'o' && i < ask->k->n; i++) {
      struct str *k = ask->k->v[i];
      int now = k->n >= 2 && k->p[0] == 'a' && k->p[1] == ' ' ? h_has (asmfn, s_sub (k, 2, k->n)) : h_has (noproto, s_sub (k, 2, k->n));
      if (now != truth (ask->v->v[i])) ok = 0;
    }
    if (ok) {
      struct jv *err = jget (e, "err");
      if (err && err->s) { die_status = 255; die_s (s_dup (err->s)); }
      return s_dup (jsor (e, "norm"));
    }
  }
  umiss = 1;
  return s_of ("");
}
struct un { struct str *j; struct hash *want, *gf, *ge, *gs; };
static int defined_true (struct hash *h, struct str *k) { struct str *v = h_pv (h, k); return v && v->n && !s_is (v, "0"); }
static struct jv *jobj (void) { struct jv *x = jv_new ('o'); x->k = v_new (); x->v = v_new (); return x; }
static void jset (struct jv *o, char *k, struct jv *v) { v_push (o->k, s_of (k)); v_push (o->v, v); }
static struct jv *jtype (char *q) { struct jv *t = jobj (); jset (t, "qualType", jstrv (q)); return t; }
static struct jv *jarr1 (struct jv *x) { struct jv *a = jv_new ('a'); a->v = v_new (); v_push (a->v, x); return a; }
static struct un *unit_norms (struct unit *u)
{
  struct un *r = alloc (sizeof (struct un));
  struct vec *kp = u->kept, *blist;
  struct hash *def = h_new ();
  struct str *j = u->j;
  long i, q;
  r->j = j; r->want = h_new (); r->gf = h_new (); r->ge = h_new (); r->gs = h_new ();
  tdef = u->tdef; typeof_ = u->typeof_; declty = u->declty; enumval = u->enumval; errordecl = u->errordecl;
  side_ff = 0;
  norm_state ();
  unit_i = ssub (j, "\\.json$", "", ".i");
  for (i = 0; i < kp->n; i++) {
    struct jv *d = kp->v[i];
    if (kind_is (d, "FileScopeAsmDecl")) {
      struct str *v = jsor (kid0 (d), "value");
      if (mf (v, "^\"\\s*([.\\w]+)\\s*=\\s*([.\\w]+)\\s*\"$", "")) h_setp (asmalias, g (1), g (2));
    }
  }
  constint_of (kp);
  for (i = 0; i < kp->n; i++) {
    struct jv *d = kp->v[i], *l;
    if (kind_is (d, "VarDecl") && jis (d, "storageClass", "register") && (l = asm_label_attr (d))) { struct str *m = jstr (d, "mangledName"); h_setp (regvar, jsor (d, "name"), m ? m : jstr (l, "label")); }
    if (has_body (d)) h_setp (def, jsor (d, "name"), d);
  }
  /* (a top-level asm's .globl N and .set N, V, .equ N, V or N = V: an absolute symbol, a char global of value V) */
  for (i = 0; i < kp->n; i++) {
    struct jv *a = kp->v[i];
    struct str *s;
    struct vec *ls;
    struct hash *gl = h_new (), *vv = h_new ();
    if (!kind_is (a, "FileScopeAsmDecl")) continue;
    s = jsor (kid0 (a), "value");
    s = ssub (s, "^\"|\"$", "g", "");
    s = ssub (s, "\\\\[nt]", "g", "\n");
    ls = ssplit ("[\\n;]", s, 0);
    for (q = 0; q < ls->n; q++) {
      struct str *l = ssub (ls->v[q], "^\\s+|\\s+$", "g", "");
      if (mf (l, "^\\.globl\\s+([.\\w]+)$", "")) h_set (gl, g (1), 1);
      else if (mf (l, "^\\.(?:set|equ)\\s+([.\\w]+)\\s*,\\s*(-?\\d+)$", "") || mf (l, "^([.\\w]+)\\s*=\\s*(-?\\d+)$", "")) h_setp (vv, g (1), g (2));
    }
    for (q = 0; q < vv->keys->n; q++) {
      struct hent *e = vv->keys->v[q];
      struct jv *d, *c, *lit;
      if (!(h_has (gl, e->k) && h_pv (gwant, e->k))) continue;
      lit = jobj (); jset (lit, "kind", jstrv ("IntegerLiteral")); jset (lit, "value", jv_new ('s')); ((struct jv *) lit->v->v[1])->s = e->pv; jset (lit, "type", jtype ("int"));
      c = jobj (); jset (c, "kind", jstrv ("ImplicitCastExpr")); jset (c, "castKind", jstrv ("IntegralCast")); jset (c, "type", jtype ("char")); jset (c, "inner", jarr1 (lit));
      d = jobj (); jset (d, "kind", jstrv ("VarDecl")); jset (d, "name", jv_new ('s')); ((struct jv *) d->v->v[1])->s = e->k; jset (d, "type", jtype ("char")); jset (d, "inner", jarr1 (c));
      h_setp (r->gs, e->k, gnorm (d));
    }
  }
  /* its globals: a definition (an extern declaration is none), the first unit's */
  for (i = 0; i < kp->n; i++) {
    struct jv *d = kp->v[i];
    struct str *nm = jstr (d, "name");
    if (!(kind_is (d, "VarDecl") && nm && (blist = h_pv (gwant, nm)))) continue;
    if (jis (d, "storageClass", "extern")) { if (!h_pv (r->ge, nm)) h_setp (r->ge, nm, cat2 ("(global ", tcls (d), " (zero))")); continue; }
    for (q = 0; q < blist->n; q++) {
      struct nm *gw = blist->v[q];
      struct str *hint = gw->unit;
      if ((hint && mf (hint, "^in ", "")) || defined_true (gfound, gw->cid) || defined_true (r->gf, gw->cid)) continue;
      if (hint && mf (hint, "^unit (.+)$", "")) { struct str *w = s_of ("/"); s_app (w, g (1)); s_cat (w, ".json"); if (!(j->n >= w->n && msame (j->p + j->n - w->n, w->p, w->n))) continue; }
      h_setp (r->gf, gw->cid, cnorm (u, "g ", d, 0));
    }
  }
  /* and its functions' statics */
  for (i = 0; i < kp->n; i++) {
    struct jv *d = kp->v[i];
    struct str *nm = jstr (d, "name"), *fu;
    struct vec *qu;
    long at = 0;
    if (!(kind_is (d, "FunctionDecl") && nm && (fu = h_pv (fnunit, nm)) && s_eq (fu, j) && has_body (d))) continue;
    { struct hash *cnt = h_new (); staticid = h_new (); static_walk (d, cnt); }
    constid = h_new (); const_walk (d);
    qu = v_new (); v_cat (qu, jkids (d));
    while (at < qu->n) {
      struct jv *n = qu->v[at++];
      if (kind_is (n, "VarDecl") && jis (n, "storageClass", "static") && (blist = h_pv (gwant, jsor (n, "name")))) {
        struct str *o = name_of (n), *in = cat2 ("in ", nm, "");
        for (q = 0; q < blist->n; q++) {
          struct nm *gw = blist->v[q];
          if (h_pv (r->gf, gw->cid)) continue;
          if (gw->unit && s_eq (gw->unit, in) && s_eq (gw->o, o) && !defined_true (gfound, gw->cid)) h_setp (r->gf, gw->cid, cnorm (u, "s ", n, 0));
        }
      }
      v_cat (qu, jkids (n));
    }
    staticid = h_new (); constid = h_new ();
  }
  blist = h_pv (byunit, j);
  for (i = 0; blist && i < blist->n; i++) {
    struct nm *b = blist->v[i];
    struct jv *d = h_pv (def, b->o);
    if (!d) continue;
    h_setp (r->want, b->cid, cnorm (u, "f ", d, 1));
  }
  return r;
}

/* ---- held against the C written back */
struct dif { struct str *cid, *msg; };
static void dif_add (struct vec *v, struct str *cid, struct str *msg) { struct dif *x = alloc (sizeof (struct dif)); x->cid = cid; x->msg = msg; v_push (v, x); }
static struct str *where (struct str *a, struct str *b)
{
  long i = 0, from;
  struct str *o = s_of ("\n    glibc: ..."), *ab;
  struct md5 *m = md5_new ();
  while (i < a->n && i < b->n && a->p[i] == b->p[i]) i++;
  from = i > 80 ? i - 80 : 0;
  s_app (o, s_sub (a, from, from + 200));
  s_cat (o, "\n    ff:    ...");
  s_app (o, s_sub (b, from, from + 200));
  s_cat (o, "\n    digest: ");
  ab = s_dup (a); s_chr (ab, 0); s_app (ab, b);
  md5_add (m, ab->p, ab->n);
  s_app (o, s_sub (md5_hex (m), 0, 12));
  return o;
}
static void norms_line (char *k, struct str *cid, struct str *n)
{
  if (!norms_txt) return;
  s_cat (norms_txt, k); s_chr (norms_txt, ' '); s_app (norms_txt, cid); s_chr (norms_txt, '\t'); s_app (norms_txt, n); s_chr (norms_txt, '\n');
}
static void copy_new (struct hash *to, struct hash *from)   /* $to{$_} //= $from{$_} */
{
  long i;
  for (i = 0; i < from->keys->n; i++) { struct hent *e = from->keys->v[i]; if (!h_pv (to, e->k)) h_setp (to, s_dup (e->k), e->pv); }
}
static void unit_compare (struct un *u)
{
  struct vec *blist = h_pv (byunit, u->j);
  long i;
  copy_new (gfound, u->gf); copy_new (gextern, u->ge); copy_new (gasm, u->gs);
  for (i = 0; blist && i < blist->n; i++) {
    struct nm *b = blist->v[i];
    struct str *want = h_pv (u->want, b->cid), *got;
    if (!want) { struct str *m = s_of ("no function "); s_app (m, b->o); s_cat (m, " in "); s_app (m, u->j); dif_add (diffs, b->cid, m); continue; }
    norms_line ("f", b->cid, want);
    got = h_pv (back, b->cid);
    if (!got) { dif_add (diffs, b->cid, s_of ("not in the C written back")); continue; }
    if (s_eq (want, got)) { same_n++; continue; }
    dif_add (diffs, b->cid, where (want, got));
  }
}
static void stamp_of (void)
{
  struct md5 *m = md5_new ();
  struct str *pl = pl_path ? pl_path : s_of ("roundtrip.pl"), *fo, *t;
  fo = ssub (pl, "[^/]*$", "", "");
  s_cat (fo, "../compiler/gen/FFold.pm");
  t = read_or_die (pl); md5_add (m, t->p, t->n);
  t = read_or_die (fo); md5_add (m, t->p, t->n);
  t = cat2 ("target ", target, "");
  md5_add (m, t->p, t->n);
  cache_stamp = md5_hex (m);
}
/* the round trip: names.txt, back.json, unit.json ... */
static int round_trip (struct vec *args)
{
  struct str *names = args->v[0], *backj = args->v[1], *show = env_s ("ROUNDTRIP_SHOW"), *nf = env_s ("ROUNDTRIP_NORMS");
  struct hash *seen = h_new ();
  struct vec *order = v_new (), *ks;
  long i;
  if (nf && nf->n) {
    norms_fd = cp_create ((char *) nf->p);
    if (norms_fd < 0) die_open (nf, -norms_fd);
    norms_txt = s_of ("");
  }
  if (cached) stamp_of ();
  names_read (names);
  gfound = h_new (); gextern = h_new (); gasm = h_new ();
  diffs = v_new (); gdiffs = v_new ();
  back_norms (backj);
  for (i = 2; i < args->n; i++) v_push (order, args->v[i]);
  ks = h_sorted (byunit);
  for (i = 0; i < ks->n; i++) v_push (order, ks->v[i]);
  for (i = 0; i < order->n; i++) {
    struct str *j = order->v[i];
    struct unit *u;
    struct un *r;
    if (h_has (seen, j)) continue;
    h_set (seen, j, 1);
    u = load_unit (j);
    umiss = 0;
    r = unit_norms (u);
    if (umiss) { u = unit_from_json (j); r = unit_norms (u); }
    unit_compare (r);
  }
  for (i = 0; i < globals_->n; i++) {
    struct nm *g = globals_->v[i];
    struct str *want, *got;
    if (s_is (g->k, "gfailed")) { dif_add (gdiffs, g->cid, s_of ("ff2c could not write it back")); continue; }
    want = h_pv (gfound, g->cid);
    if (!want) want = h_pv (gasm, g->o);
    if (!want) want = h_pv (gextern, g->o);
    if (!want) { struct str *m = s_of ("no definition of "); s_app (m, g->o); s_cat (m, " in glibc's units ("); s_app (m, g->unit ? g->unit : s_of ("")); s_chr (m, ')'); dif_add (gdiffs, g->cid, m); continue; }
    norms_line ("g", g->cid, want);
    got = h_pv (backg, g->cid);
    if (!got) { dif_add (gdiffs, g->cid, s_of ("not in the C written back")); continue; }
    if (show && s_eq (show, g->cid)) { o_str ("glibc: "); o_s (want); o_str ("\nff:    "); o_s (got); o_str ("\n"); }
    if (s_eq (want, got)) { gsame_n++; continue; }
    dif_add (gdiffs, g->cid, where (want, got));
  }
  for (i = 0; i < diffs->n + gdiffs->n; i++) {
    struct dif *d = i < diffs->n ? diffs->v[i] : gdiffs->v[i - diffs->n];
    o_str ("roundtrip: "); o_s (d->cid); o_str (": "); o_s (d->msg); o_str ("\n");
  }
  for (i = 0; i < failed_->n; i++) { struct nm *b = failed_->v[i]; o_str ("roundtrip: "); o_s (b->o); o_str (": ff2c could not write it back\n"); }
  o_str ("roundtrip: "); o_s (s_num (same_n)); o_str (" of "); o_s (s_num (bodies->n)); o_str (" functions and ");
  o_s (s_num (gsame_n)); o_str (" of "); o_s (s_num (globals_->n)); o_str (" globals as glibc's C\n");
  o_flush ();
  if (norms_txt) { long w = 0; while (w < norms_txt->n) { long x = cp_write ((int) norms_fd, norms_txt->p + w, norms_txt->n - w); if (x <= 0) break; w += x; } }
  return diffs->n || failed_->n || gdiffs->n ? 1 : 0;
}
