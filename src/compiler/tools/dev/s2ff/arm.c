/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* arm.c: gen/s2ff-arm.pl and gen/armdec.pm in ff (s2ff --target arm):
   what GNU as made of a .s (its dump), each section of code an asm
   function, each instruction decoded by the encodings of isa/arm.pl
   (isa/arm.dec.ff, --tables: gen/mkdectab.pl's) and checked by encoding
   it again. */

/* ---- armdec: the encodings */
struct afield { int kind; struct str *p; struct str *custom; struct str *spec; struct str *arg0; long w, pos; unsigned long fixed; };   /* kind 0 fixed, 1 a parameter's slice, 2 custom */
struct adef { struct str *name, *mode, *gnu; struct vec *params; struct hash *signed_; struct afield *f; long nf; unsigned long mask, val; long w; int branch; };
static struct vec *adefs_a, *adefs_t, *adefs_t2;
static struct str *tables_f;
static long specw (struct str *s)
{
  struct vec *sg = ssplit ("\\|", s, 0);
  long w = 0, i;
  for (i = 0; i < sg->n; i++) {
    struct str *x = sg->v[i];
    long h, l;
    if (!m (x, "^(\\d+)(?::(\\d+))?$")) { struct str *y = s_of ("armdec: bad spec "); s_app (y, s); s_cat (y, "\n"); die_s (y); }
    h = dec (g (1)); l = gdef (2) ? dec (g (2)) : h;
    w += h - l + 1;
  }
  return w;
}
/* the segments of a spec, each hi and lo */
static long seg_n;
static long seg_h[16], seg_l[16];
static void segs (struct str *s)
{
  struct vec *sg = ssplit ("\\|", s, 0);
  long i;
  seg_n = 0;
  for (i = 0; i < sg->n && seg_n < 16; i++) {
    struct str *x = sg->v[i];
    m (x, "^(\\d+)(?::(\\d+))?$");
    seg_h[seg_n] = dec (g (1)); seg_l[seg_n] = gdef (2) ? dec (g (2)) : seg_h[seg_n];
    seg_n++;
  }
}
/* the items of a table, through its layers */
static void items_of (struct nd *x, struct vec *out)
{
  long i;
  for (i = 0; i < ndn (x); i++) {
    struct nd *y = ndk (x, i);
    if (m (y->c, "^[0-9]+:$")) items_of (y, out);
    else if (!s_is (y->c, "comment")) v_push (out, y);
  }
}
static struct nd *tables_of (char *top)
{
  struct str *t;
  struct nd *root;
  long i;
  if (!tables_f) die_c ("s2ff: no --tables FILE (isa/<target>.dec.ff)\n");
  t = read_all ((char *) tables_f->p);
  if (!t) { struct str *x = s_of ("s2ff: cannot open "); s_app (x, tables_f); s_cat (x, "\n"); die_s (x); }
  ffp = t->p; ffn = t->n; ffi = 0;
  root = ff_node ();
  if (!root) { struct str *x = s_of ("s2ff: "); s_app (x, tables_f); s_cat (x, " is not an ff tree\n"); die_s (x); }
  for (i = 0; i < ndn (root); i++) if (s_is (ndk (root, i)->c, top)) return ndk (root, i);
  { struct str *x = s_of ("s2ff: no "); s_cat (x, top); s_cat (x, " in "); s_app (x, tables_f); s_cat (x, "\n"); die_s (x); }
  return 0;
}
static struct nd *child_named (struct nd *x, char *c) { long i; for (i = 0; i < ndn (x); i++) if (s_is (ndk (x, i)->c, c)) return ndk (x, i); return 0; }
static void armdec_load (void)
{
  struct nd *top = tables_of ("arm decode:");
  struct vec *itemv = v_new ();
  long i, j;
  items_of (top, itemv);
  adefs_a = v_new (); adefs_t = v_new (); adefs_t2 = v_new ();
  for (i = 0; i < itemv->n; i++) {
    struct nd *e = itemv->v[i], *pn = child_named (e, "params"), *sn = child_named (e, "signed"), *fn_ = child_named (e, "fields");
    struct adef *d = alloc (sizeof (struct adef));
    long pos;
    d->name = e->c; d->mode = ndk (e, 0)->c; d->gnu = ndk (e, 1)->c;
    d->params = v_new (); d->signed_ = h_new ();
    for (j = 0; j < ndn (pn); j++) v_push (d->params, ndk (pn, j)->c);
    for (j = 0; j < ndn (sn); j++) h_set (d->signed_, ndk (sn, j)->c, 1);
    d->nf = ndn (fn_);
    d->f = alloc ((d->nf + 1) * sizeof (struct afield));
    for (j = 0; j < d->nf; j++) {
      struct str *f = ndk (fn_, j)->c;
      struct afield *a = &d->f[j];
      if (m (f, "^(\\w+)=([01]+)$")) { struct str *b = g (2); a->kind = 0; a->w = b->n; a->fixed = bin_of (b); }
      else if (m (f, "^(\\w+)\\[([\\d:|]+)\\]\\(([\\w,]+)\\)$")) { struct str *c = g (1), *spc = g (2), *args = g (3); a->kind = 2; a->custom = c; a->spec = spc; a->arg0 = ssplit (",", args, 0)->v[0]; a->w = specw (spc); }
      else if (m (f, "^([\\w]+)\\[([\\d:|]+)\\]$")) { struct str *p = g (1), *spc = g (2); a->kind = 1; a->p = p; a->spec = spc; a->w = specw (spc); }
      else if (m (f, "^(\\w+)$")) { a->kind = 1; a->p = g (1); a->spec = s_of ("3:0"); a->w = 4; }
      else { struct str *x = s_of ("armdec: "); s_app (x, d->name); s_cat (x, ": field "); s_app (x, f); s_cat (x, "\n"); die_s (x); }
      d->w += a->w;
    }
    pos = d->w;
    for (j = 0; j < d->nf; j++) {
      struct afield *a = &d->f[j];
      pos -= a->w;
      a->pos = pos;
      if (a->kind) continue;
      d->mask |= (((unsigned long) 1 << a->w) - 1) << pos;
      d->val |= a->fixed << pos;
    }
    if (m (d->gnu, "\\{u?imm\\^(\\d)\\}")) d->branch = g (1)->p[0] != '0';
    if (s_is (d->mode, "a")) v_push (adefs_a, d); else if (s_is (d->mode, "t")) v_push (adefs_t, d); else v_push (adefs_t2, d);
  }
}
static struct str *rname (long n) { struct str *x; if (n == 13) return s_of ("sp"); if (n == 14) return s_of ("lr"); if (n == 15) return s_of ("pc"); x = s_of ("r"); s_app (x, s_num (n)); return x; }
static unsigned long lmask (long n) { return n >= 64 ? ~(unsigned long) 0 : ((unsigned long) 1 << n) - 1; }

/* the parameters of d for the bits v: values in pv (by d's params), defined in pd */
static struct hash *fp_p, *fp_up, *fp_mag, *fp_top, *fp_has;
static void hp_or (struct hash *h, struct str *k, long v) { struct hent *e = h_put (h, k); e->iv |= v; e->pv = (void *) 1; }
static int hdef (struct hash *h, struct str *k) { struct hent *e = h_find (h, k); return e && e->pv; }
static void hset_d (struct hash *h, struct str *k, long v) { struct hent *e = h_put (h, k); e->iv = v; e->pv = (void *) 1; }
static void fields_of (struct adef *d, unsigned long v)
{
  long i, j;
  long j1 = -1, j2 = -1, msb = 0;
  int has_msb = 0, has_j = 0;
  fp_p = h_new (); fp_up = h_new (); fp_mag = h_new (); fp_top = h_new ();
  for (i = 0; i < d->nf; i++) {
    struct afield *f = &d->f[i];
    long bits;
    if (f->kind == 0) continue;
    bits = (long) ((v >> f->pos) & lmask (f->w));
    if (f->kind == 1 || s_is (f->custom, "mag")) {
      struct hash *into = f->kind == 1 ? fp_p : fp_mag;
      struct str *name = f->kind == 1 ? f->p : f->arg0;
      long at = f->w;
      segs (f->spec);
      for (j = 0; j < seg_n; j++) {
        long n = seg_h[j] - seg_l[j] + 1;
        at -= n;
        if (!hdef (into, name)) hset_d (into, name, 0);
        hp_or (into, name, (long) ((((unsigned long) bits >> at) & lmask (n)) << seg_l[j]));
        if (!hdef (fp_top, name) || seg_h[j] > h_iv (fp_top, name)) hset_d (fp_top, name, seg_h[j]);
      }
    } else if (s_is (f->custom, "up")) hset_d (fp_up, f->arg0, bits);
    else if (s_is (f->custom, "j1")) { j1 = bits; has_j = 1; }
    else if (s_is (f->custom, "j2")) { j2 = bits; has_j = 1; }
    else if (s_is (f->custom, "msb")) { msb = bits; has_msb = 1; }
    else if (s_is (f->custom, "wm1")) hset_d (fp_p, s_of ("width"), bits + 1);
    else { struct str *x = s_of ("armdec: custom "); s_app (x, f->custom); s_cat (x, "\n"); die_s (x); }
  }
  for (i = 0; i < fp_up->keys->n; i++) {
    struct hent *e = fp_up->keys->v[i];
    long mg = h_iv (fp_mag, e->k);
    hset_d (fp_p, e->k, e->iv ? mg : -mg);
  }
  if (has_j) {
    struct str *imm = s_of ("imm");
    long iv = h_iv (fp_p, imm), s = (iv >> 24) & 1;
    iv |= ((1 ^ (j1 ^ s)) << 23) | ((1 ^ (j2 ^ s)) << 22);
    hset_d (fp_p, imm, iv);
    hset_d (fp_top, imm, 24);
  }
  if (has_msb) hset_d (fp_p, s_of ("width"), msb - h_iv (fp_p, s_of ("lsb")) + 1);
  for (i = 0; i < fp_p->keys->n; i++) {
    struct hent *e = fp_p->keys->v[i];
    long b;
    if (!e->pv) continue;
    if (!(h_has (d->signed_, e->k) && !h_has (fp_up, e->k) && hdef (fp_top, e->k))) continue;
    b = h_iv (fp_top, e->k);
    if ((e->iv >> b) & 1) e->iv -= (long) 1 << (b + 1);
  }
}
/* the bits d gives the parameters (fp_p); -1 where one is missing */
static long encode_ (struct adef *d, int *ok)
{
  unsigned long v = 0;
  long i, j;
  *ok = 1;
  for (i = 0; i < d->nf; i++) {
    struct afield *f = &d->f[i];
    unsigned long bits = 0;
    if (f->kind == 0) bits = f->fixed;
    else if (f->kind == 1 || s_is (f->custom, "mag") || s_is (f->custom, "msb") || s_is (f->custom, "wm1")) {
      long x, at = f->w;
      if (f->kind == 1) { if (!hdef (fp_p, f->p)) { *ok = 0; return 0; } x = h_iv (fp_p, f->p); }
      else if (s_is (f->custom, "mag")) { x = h_iv (fp_p, f->arg0); if (x < 0) x = -x; }
      else if (s_is (f->custom, "msb")) x = h_iv (fp_p, s_of ("lsb")) + h_iv (fp_p, s_of ("width")) - 1;
      else x = h_iv (fp_p, s_of ("width")) - 1;
      segs (f->spec);
      for (j = 0; j < seg_n; j++) {
        long n = seg_h[j] - seg_l[j] + 1;
        at -= n;
        bits |= (((unsigned long) x >> seg_l[j]) & lmask (n)) << at;
      }
    } else if (s_is (f->custom, "up")) bits = h_iv (fp_p, f->arg0) >= 0 ? 1 : 0;
    else if (s_is (f->custom, "j1") || s_is (f->custom, "j2")) {
      unsigned long imm = (unsigned long) h_iv (fp_p, s_of ("imm"));
      unsigned long ii = (imm >> (s_is (f->custom, "j1") ? 23 : 22)) & 1, s = (imm >> 24) & 1;
      bits = 1 ^ (ii ^ s);
    }
    v |= (bits & lmask (f->w)) << f->pos;
  }
  return (long) v;
}
struct afound { struct str *name; struct vec *ops; struct adef *d; };
static char *armcc[16];
static struct vec *armdec_decode (char *mode, unsigned long v)
{
  struct vec *defs_ = s_is (s_of (mode), "a") ? adefs_a : s_is (s_of (mode), "t") ? adefs_t : adefs_t2, *found = v_new (), *o;
  long i, j;
  for (i = 0; i < defs_->n; i++) {
    struct adef *d = defs_->v[i];
    struct vec *ops;
    int ok, bad = 0;
    long e;
    if ((v & d->mask) != d->val) continue;
    fields_of (d, v);
    if (hdef (fp_p, s_of ("cond")) && h_iv (fp_p, s_of ("cond")) == 15) continue;
    e = encode_ (d, &ok);
    if (!ok || (unsigned long) e != v) continue;
    ops = v_new ();
    for (j = 0; j < d->params->n && !bad; j++) {
      struct str *n = d->params->v[j], *x;
      long xv;
      if (!hdef (fp_p, n)) { bad = 1; break; }
      xv = h_iv (fp_p, n);
      if (m (n, "^(rd|rn|rm|rs|rt|rt2|ra|rdlo|rdhi|rdn|rdm)$")) x = rname (xv);
      else if (m (n, "^s[dnm]$")) { x = s_of ("s"); s_app (x, s_num (xv)); }
      else if (m (n, "^d[dnm]$")) { x = s_of ("d"); s_app (x, s_num (xv)); }
      else if (m (n, "^q[dnm]$")) { x = s_of ("q"); s_app (x, s_num (xv >> 1)); }
      else if (s_is (n, "cond") || s_is (n, "firstcond")) { x = s_of ("cond."); if (xv >= 0 && xv < 15) s_cat (x, armcc[xv]); }
      else if (s_is (n, "regs")) { x = s_of ("0x"); s_app (x, s_hex ((unsigned long) xv, 0, 0)); }
      else x = s_num (xv);
      v_push (ops, x);
    }
    if (bad) continue;
    {
      struct afound *f = alloc (sizeof (struct afound));
      f->name = d->name; f->ops = ops; f->d = d;
      v_push (found, f);
    }
  }
  o = v_new ();
  for (i = 0; i < found->n; i++) if (!m (((struct afound *) found->v[i])->name, "\\.if$")) v_push (o, found->v[i]);
  for (i = 0; i < found->n; i++) if (m (((struct afound *) found->v[i])->name, "\\.if$")) v_push (o, found->v[i]);
  return o;
}

/* ---- the dump */
struct aline { long addr; struct str *hex, *op, *args; struct vec *relocs; };
struct areloc { long addr; struct str *rkind, *tgtset; };
struct asec { struct str *name; struct vec *lines; };
static struct hash *asym, *asymsec, *secsyms, *secend, *asecs, *aundef;
static struct vec *secs_order;
struct sympos { long addr; struct str *name; };
static void arm_fail (struct str *msg) { struct str *x = s_of ("s2ff-arm: "); s_app (x, where); s_cat (x, ": "); s_app (x, msg); s_cat (x, "\n"); pdie (x); }
static long hexl (struct str *s) { long v = 0, i; for (i = 0; i < s->n; i++) v = v * 16 + hexv (s->p[i]); return v; }
static void arm_readdump (struct str *dump, int then)
{
  struct hash *base = h_new ();
  struct str *t, *cur = 0;
  struct aline *last = 0;
  struct lines *ls;
  long i, j;
  int insyms = 0;
  if (then) {
    for (i = 0; i < secs_order->n; i++) {
      struct str *s = secs_order->v[i];
      struct asec *sc = h_pv (asecs, s);
      long e = hdef (secend, s) ? h_iv (secend, s) : 0;
      for (j = 0; j < sc->lines->n; j++) {
        struct aline *l = sc->lines->v[j];
        long n = l->addr + (m (l->hex, " ") ? 4 : l->hex->n / 2);
        if (n > e) e = n;
      }
      h_set (base, s, e);
    }
  }
  t = read_all ((char *) dump->p);
  if (!t) { long fd = s2_open ((char *) dump->p); struct str *x = s_of ("s2ff-arm: cannot open "); perrno = fd < 0 ? -fd : 2; s_app (x, dump); s_cat (x, ": "); s_cat (x, strerror_of (perrno)); s_cat (x, "\n"); pdie (x); }
  perrno = 25;
  ls = split_lines (t);
  for (i = 0; i < ls->n; i++) {
    struct str *l = chomp (ls->l[i]);
    if (m (l, "^SYMBOL TABLE:")) { insyms = 1; continue; }
    if (insyms) {
      if (m (l, "^([0-9a-f]{8}) (.{7}) (\\S+)\\t([0-9a-f]+) (.*)$")) {
        struct str *flags = g (2), *s = g (3), *name = g (5);
        long addr = hexl (g (1)), size = hexl (g (4));
        struct vec *lst;
        struct sympos *sp_;
        if (then) continue;
        name = ssub (name, "^\\.(hidden|protected|internal) ", "", "");
        if (s_is (s, "*UND*")) h_set (aundef, name, 1);
        if (!hdef (secend, s) || addr + size > h_iv (secend, s)) hset_d (secend, s, addr + size);
        if (m (name, "^\\$[atd](\\.\\d+)?$") || m (flags, "d") || m (s, "^\\*(ABS|UND)\\*$")) continue;
        hset_d (asym, name, addr);
        h_setp (asymsec, name, s);
        if (!m (name, "^\\.L")) {
          lst = h_pv (secsyms, s);
          if (!lst) { lst = v_new (); h_setp (secsyms, s, lst); }
          sp_ = alloc (sizeof (struct sympos)); sp_->addr = addr; sp_->name = name;
          v_push (lst, sp_);
        }
        continue;
      }
      if (l->n == 0) insyms = 0;
      continue;
    }
    if (m (l, "^Disassembly of section (\\S+):$")) {
      cur = g (1);
      if (then && !h_pv (asecs, cur)) { struct str *x = s_dup (dump); s_cat (x, ": "); s_app (x, cur); s_cat (x, ", which the file before it has not"); arm_fail (x); }
      if (!h_pv (asecs, cur)) {
        struct asec *sc = alloc (sizeof (struct asec));
        sc->name = cur; sc->lines = v_new ();
        v_push (secs_order, cur);
        h_setp (asecs, cur, sc);
      }
      continue;
    }
    if (!cur) continue;
    if (m (l, "^\\s*([0-9a-f]+):\\t([0-9a-f]{2,8}(?: [0-9a-f]{4})?)\\s*\\t(\\S+)\\s*(.*)$")) {
      struct aline *x = alloc (sizeof (struct aline));
      x->addr = hexl (g (1)) + h_iv (base, cur);
      x->hex = g (2); x->op = g (3); x->args = g (4); x->relocs = v_new ();
      last = x;
      v_push (((struct asec *) h_pv (asecs, cur))->lines, x);
      continue;
    }
    if (m (l, "^\\s+([0-9a-f]+): (R_ARM_\\w+)\\t(.+)$")) {
      struct str *as = g (1);
      struct areloc *r = alloc (sizeof (struct areloc));
      r->addr = hexl (as) + h_iv (base, cur); r->rkind = g (2); r->tgtset = g (3);
      if (!(last && last->addr <= r->addr)) { struct str *x = s_of ("a relocation "); s_app (x, r->rkind); s_cat (x, " at "); s_app (x, as); s_cat (x, " after no instruction"); arm_fail (x); }
      v_push (last->relocs, r);
      continue;
    }
  }
  perrno = 0;
}

/* ---- the source */
struct ablk { struct str *name; long off; struct vec *nodes, *labels; struct str *file; int has_name; };
struct alab { struct str *l; long o; };
static struct vec *aaliases, *adata;
static struct hash *dlab_b, *dlab_o, *agot, *aweakref, *srcalias, *aplt;
static struct str *abase, *afile;
static struct ablk *blk;
static struct str *aother;
static struct nd *gotoff (struct str *t)
{
  struct str *x = s_dup (abase), *y = s_dup (abase);
  h_setp (agot, t, nd1 (s_of ("word"), nd_new (t)));
  s_cat (x, " got"); s_cat (y, " got "); s_app (y, t);
  return nd_add (nd2 (s_of ("sub"), nd_new (x), nd_new (y)), ndc ("a0"));
}
static struct nd *aleaf (struct str *v)
{
  if (mf (v, "^(0x[0-9a-f]+|-?\\d+)$", "i")) {
    if (mf (v, "^0x", "i")) return nd_new (s_unum ((unsigned long) hexl (s_sub (v, 2, v->n))));
    return nd_new (v);
  }
  return nd_new (v);
}
static void ablk_close (void)
{
  long i;
  if (!blk) return;
  if (blk->nodes->n) {
    struct str *nm = s_dup (blk->has_name ? blk->name : s_of ("")), *cm = s_of ("glibc-2.44 ");
    struct nd *x;
    s_cat (nm, ":");
    s_app (cm, blk->file ? blk->file : src_s);
    x = nd2 (nm, ndc ("asm"), nd1 (s_of ("comment"), nd_new (cm)));
    for (i = 0; i < blk->nodes->n; i++) nd_add (x, blk->nodes->v[i]);
    v_push (adata, x);
    for (i = 0; i < blk->labels->n; i++) {
      struct alab *a = blk->labels->v[i];
      if (blk->has_name && s_eq (a->l, blk->name)) continue;
      if (m (a->l, "^\\.L")) { h_setp (dlab_b, a->l, blk->name); hset_d (dlab_o, a->l, a->o); }
      else if (a->o == 0) v_push (aaliases, alias_of (a->l, blk->name));
      else { struct str *x = s_of ("the label "); s_app (x, a->l); s_cat (x, " at "); s_app (x, s_num (a->o)); s_cat (x, " in a block of data"); arm_fail (x); }
    }
  } else if (blk->labels->n) {
    struct str *first = 0;
    for (i = 0; i < blk->labels->n && !first; i++) { struct alab *a = blk->labels->v[i]; if (!m (a->l, "^\\.L")) first = a->l; }
    if (first) for (i = 0; i < blk->labels->n; i++) { struct alab *a = blk->labels->v[i]; if (!m (a->l, "^\\.L") && !s_eq (a->l, first)) v_push (aaliases, alias_of (a->l, first)); }
  }
  blk = 0;
}
static struct ablk *ablk_new (void) { struct ablk *b = alloc (sizeof (struct ablk)); b->nodes = v_new (); b->labels = v_new (); b->file = afile; return b; }
static void alabel (struct str *l, long o, int has_o)
{
  struct alab *a = alloc (sizeof (struct alab));
  if (!blk) blk = ablk_new ();
  if (!has_o) o = blk->off;
  if (!blk->has_name && o == 0) {
    blk->has_name = 1;
    if (m (l, "^\\.L")) { blk->name = s_dup (abase); s_cat (blk->name, " "); s_app (blk->name, l); } else blk->name = l;
  }
  a->l = l; a->o = o;
  v_push (blk->labels, a);
}
static void aput (struct nd *n, long size)
{
  if (!(blk && blk->has_name)) { struct str *x = s_of ("data with no label in "); s_app (x, aother ? aother : s_of ("")); arm_fail (x); }
  v_push (blk->nodes, n);
  blk->off += size;
}
static struct str *unquote (struct str *t)
{
  struct str *o = s_of ("");
  long i = 0;
  while (i < t->n) {
    if (t->p[i] == '\\' && i + 1 < t->n) {
      int c = t->p[i + 1];
      if (c == 'n') { s_chr (o, '\n'); i += 2; continue; }
      if (c == 't') { s_chr (o, '\t'); i += 2; continue; }
      if (c == '\\' || c == '"') { s_chr (o, c); i += 2; continue; }
      if (c >= '0' && c <= '7') { long v = 0, k = 0; i++; while (k < 3 && i < t->n && t->p[i] >= '0' && t->p[i] <= '7') { v = v * 8 + t->p[i] - '0'; i++; k++; } s_chr (o, (int) (v & 255)); continue; }
    }
    s_chr (o, t->p[i]); i++;
  }
  return o;
}
static int all_align (struct ablk *b) { long i; for (i = 0; i < b->nodes->n; i++) if (!s_is (((struct nd *) b->nodes->v[i])->c, "align")) return 0; return 1; }
static void arm_source (void)
{
  struct str *t = p_slurp ((char *) src_s->p, "s2ff-arm");
  struct lines *ls = split_lines (t);
  struct hash *numeric_ = h_new ();
  struct vec *stack = v_new ();
  long li, ln = 0;
  perrno = 25;
  for (li = 0; li < ls->n; li++) {
    struct str *l = chomp (ls->l[li]);
    struct vec *sts;
    long sx;
    if (m (l, "^# (\\d+) \"([^\"]+)\"")) { ln = dec (g (1)) - 1; afile = ssub (g (2), "^(\\.\\./)+", "", ""); if (m (afile, "^<")) afile = 0; continue; }
    ln++;
    if (!m (l, "\"")) l = ssub (l, "\\s*@.*$", "", "");
    sts = ssplit (";", l, 0);
    for (sx = 0; sx < sts->n; sx++) {
      struct str *st = sts->v[sx];
      long i;
     again:
      st = s_trim (st);
      if (st->n == 0) continue;
      if (aother && m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*\\.\\s*\\+\\s*(\\d+)$")) { struct str *a = g (1); long k = dec (g (2)); alabel (a, (blk ? blk->off : 0) + k, 1); continue; }
      if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$") || m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*([.\\w]+)$")) {
        struct str *x = g (1), *y = g (2);
        if (m (y, "^-?\\d+$")) { struct str *w = s_of ("s2ff-arm: "); s_app (w, where); s_cat (w, ": "); s_app (w, x); s_cat (w, " = "); s_app (w, y); s_cat (w, ", a constant, left out\n"); e_s (w); continue; }
        v_push (aaliases, alias_of (x, y));
        h_set (srcalias, x, 1);
        continue;
      }
      if (m (st, "^(\\d+):\\s*")) {
        struct str *d = g (1), *n = s_of (".L");
        long c = h_iv (numeric_, d) + 1;
        st = s_sub (st, rc[1], st->n);
        h_set (numeric_, d, c);
        s_app (n, d); s_chr (n, 2); s_app (n, s_num (c));
        if (aother && !m (aother, "^\\.debug_")) alabel (n, 0, 0);
        if (st->n) goto again;
        continue;
      }
      if (m (st, "^\\.(ident|file)\\b")) continue;
      if (m (st, "^\\.pushsection\\s+([^,\\s]+)")) { struct str *sn = g (1); ablk_close (); v_push (stack, aother); aother = m (sn, "^\\.(text|init|fini)$") ? 0 : sn; continue; }
      if (m (st, "^\\.popsection$")) { ablk_close (); aother = v_pop (stack); continue; }
      if (m (st, "^\\.(data|bss|text|section\\s+([^,\\s]+)(,.*)?)$")) {
        struct str *sn;
        ablk_close ();
        if (gdef (2)) sn = g (2); else { sn = s_of ("."); s_app (sn, g (1)); }
        aother = m (sn, "^\\.(text|init|fini)$") || m (sn, "^\\.note") ? 0 : sn;
        continue;
      }
      if (m (st, "^\\.weak\\s+([.\\w]+)$")) h_set (aweakref, g (1), 1);
      if (!aother) continue;
      if (m (aother, "^\\.debug_")) continue;
      if (m (st, "^\\.(globl|global|weak|type|size|hidden)\\b")) continue;
      if (m (st, "^\\.(p2align|align|balign)\\s+(\\d+)")) {
        struct str *k = g (1);
        long e = dec (g (2)), a = 1;
        if (s_is (k, "balign")) a = e; else while (e-- > 0) a *= 2;
        if (!blk || !blk->nodes->n) {
          if (!blk) blk = ablk_new ();
          if (a > 4) v_push (blk->nodes, nd1 (s_of ("align"), LN (a)));
          continue;
        }
        while (blk->off % a) aput (nd1 (s_of ("byte"), ndc ("0")), 1);
        continue;
      }
      if (m (st, "^([.\\w]+):$")) { alabel (g (1), 0, 0); continue; }
      if (m (st, "^\\.(zero|space)\\s+(\\d+)$") && blk && all_align (blk)) {
        struct vec *lsx = v_new ();
        for (i = 0; i < blk->labels->n; i++) { struct alab *a = blk->labels->v[i]; if (!m (a->l, "^\\.L")) v_push (lsx, a->l); }
        if (lsx->n) {
          struct str *first = lsx->v[0], *w;
          if (!zeroed->n || h_has (zeroed, first)) for (i = 1; i < lsx->n; i++) v_push (aaliases, alias_of (lsx->v[i], first));
          w = s_of ("s2ff-arm: "); s_app (w, where); s_cat (w, ": "); s_app (w, first); s_cat (w, " is zero, c2ff --zero "); s_app (w, first); s_cat (w, " makes it\n");
          e_s (w);
          blk = 0;
          continue;
        }
      }
      if (m (st, "^\\.(zero|space)\\s+(\\d+)$")) { long k = dec (g (2)); for (i = 0; i < k; i++) aput (nd1 (s_of ("byte"), ndc ("0")), 1); continue; }
      if (m (st, "^\\.(long|word|4byte)\\s+(.+)$")) {
        struct vec *it = ssplit ("\\s*,\\s*", g (2), 0);
        for (i = 0; i < it->n; i++) { struct str *x = it->v[i]; if (m (x, "^([.\\w]+)\\(GOT\\)$")) aput (nd1 (s_of ("word"), gotoff (g (1))), 4); else aput (nd1 (s_of ("word"), aleaf (x)), 4); }
        continue;
      }
      if (m (st, "^\\.(short|hword|2byte)\\s+(.+)$")) { struct vec *it = ssplit ("\\s*,\\s*", g (2), 0); for (i = 0; i < it->n; i++) aput (nd1 (s_of ("half"), aleaf (it->v[i])), 2); continue; }
      if (m (st, "^\\.byte\\s+(.+)$")) { struct vec *it = ssplit ("\\s*,\\s*", g (1), 0); for (i = 0; i < it->n; i++) aput (nd1 (s_of ("byte"), aleaf (it->v[i])), 1); continue; }
      if (m (st, "^\\.(string|asciz)\\s+\"(.*)\"$")) { struct str *x = unquote (g (2)); s_chr (x, 0); aput (nd1 (s_of ("ascii"), nd_new (x)), x->n); continue; }
      if (m (st, "^\\.ascii\\s+\"(.*)\"$")) { struct str *x = unquote (g (1)); aput (nd1 (s_of ("ascii"), nd_new (x)), x->n); continue; }
      { struct str *x = s_of ("bytes in "); s_app (x, aother); s_cat (x, ": "); s_app (x, st); arm_fail (x); }
    }
  }
  ablk_close ();
  perrno = 0;
}

/* ---- the sections of code */
static struct hash *anames;   /* address -> vec of names, of the section at hand */
static struct str *alname (long a)
{
  struct vec *n = h_pv (anames, s_num (a));
  struct str *x;
  if (n) return n->v[0];
  x = s_of (".L "); s_app (x, s_hex ((unsigned long) a, 0, 0));
  return x;
}
static struct str *ctl_names (struct str *t)   /* s/\^([A-Z@\[\\\]^_])/chr(ord($1) - 64)/ge */
{
  struct str *o = s_of ("");
  long i;
  for (i = 0; i < t->n; i++) {
    int c = i + 1 < t->n ? t->p[i + 1] : 0;
    if (t->p[i] == '^' && ((c >= 'A' && c <= 'Z') || c == '@' || c == '[' || c == '\\' || c == ']' || c == '^' || c == '_')) { s_chr (o, c - 64); i++; continue; }
    s_chr (o, t->p[i]);
  }
  return o;
}
static struct nd *asymbol (struct str *t)
{
  if (s_is (t, "_GLOBAL_OFFSET_TABLE_")) { struct str *x = s_dup (abase); s_cat (x, " got"); return nd_new (x); }
  t = ctl_names (t);
  if (h_pv (dlab_b, t)) {
    struct str *b = h_pv (dlab_b, t);
    long o = h_iv (dlab_o, t);
    return o ? nd_add (nd2 (s_of ("addi"), LN (o), nd_new (b)), ndc ("a0")) : nd_new (b);
  }
  if (m (t, "^\\.L")) {
    struct str *n = ctl_names (t), *sc;
    if (!hdef (asym, n)) { struct str *x = s_of ("no address for the local symbol "); s_app (x, t); arm_fail (x); }
    sc = h_pv (asymsec, n);
    if (!h_pv (asecs, sc)) { struct str *x = s_of ("the local symbol "); s_app (x, t); s_cat (x, " is in "); s_app (x, sc); s_cat (x, ", not yet"); arm_fail (x); }
    return nd_new (alname (h_iv (asym, n)));
  }
  return nd_new (t);
}
static struct nd *aplus (long a, struct nd *n) { return a ? nd_add (nd2 (s_of ("addi"), LN (a), n), ndc ("a0")) : n; }
static struct nd *pcsub (struct nd *n) { return nd_add (nd2 (s_of ("sub"), ndc ("pc"), n), ndc ("a0")); }
static struct nd *data_reloc (struct areloc *r, long v)
{
  struct str *ty = r->rkind, *t = r->tgtset;
  long a = v >= 2147483648LL ? v - 4294967296LL : v;
  struct str *gb = s_dup (abase);
  s_cat (gb, " got");
  if (s_is (ty, "R_ARM_ABS32")) return nd1 (s_of ("word"), aplus (a, asymbol (t)));
  if (s_is (ty, "R_ARM_REL32")) return nd1 (s_of ("word"), aplus (a, pcsub (asymbol (t))));
  if (s_is (ty, "R_ARM_GOTPC")) return nd1 (s_of ("word"), aplus (a, pcsub (nd_new (gb))));
  if (s_is (ty, "R_ARM_GOT32")) return nd1 (s_of ("word"), aplus (a, gotoff (t)));
  if (s_is (ty, "R_ARM_GOTOFF32")) return nd1 (s_of ("word"), aplus (a, nd_add (nd2 (s_of ("sub"), nd_new (gb), asymbol (t)), ndc ("a0"))));
  if (s_is (ty, "R_ARM_TLS_IE32")) {
    struct str *k = s_dup (t), *w = s_dup (gb);
    s_cat (k, " tp");
    h_setp (agot, k, nd1 (s_of ("word"), nd1 (s_of ("tprel"), nd_new (t))));
    s_cat (w, " "); s_app (w, t); s_cat (w, " tp");
    return nd1 (s_of ("word"), aplus (a, pcsub (nd_new (w))));
  }
  { struct str *x = s_of ("a word with "); s_app (x, ty); arm_fail (x); }
  return 0;
}
static int arm_score (struct afound *f, struct str *mn)
{
  struct str *gg;
  m (f->d->gnu, "^(\\S+)");
  gg = ssub (g (1), "\\{cond\\}", "", "");
  if (s_eq (gg, mn)) return 0;
  {
    struct str *pat = s_of ("^"); s_app (pat, rx_quote (gg)); s_cat (pat, "(eq|ne|cs|cc|hs|lo|mi|pl|vs|vc|hi|ls|ge|lt|gt|le)(\\.[nw])?$");
    if (mdyn (mn, pat, "")) return 1;
  }
  return 2;
}
static long abytes;
static int has_bytes;
static void ainsert_sorted (struct vec *v, struct sympos *x)
{
  /* sort by address, then whether the source makes it an alias, then name */
  long i = v->n;
  v_push (v, x);
  while (i > 0) {
    struct sympos *y = v->v[i - 1];
    long c = y->addr != x->addr ? (y->addr < x->addr ? -1 : 1) : h_iv (srcalias, y->name) != h_iv (srcalias, x->name) ? (h_iv (srcalias, y->name) < h_iv (srcalias, x->name) ? -1 : 1) : s_cmp (y->name, x->name);
    if (c <= 0) break;
    v->v[i] = y; v->v[i - 1] = x; i--;
  }
}
static void label_walk (struct nd *f, struct hash *entry)
{
  long i;
  for (i = 0; i < ndn (f); i++) { struct nd *x = ndk (f, i); if (m (x->c, ":$")) h_set (entry, unlabel (x->c), 1); label_walk (x, entry); }
}
static void arm_main (struct vec *files)
{
  long sidx, i;
  struct hash *weakb_ = h_new ();
  if (files->n != 2) { e_str ("usage: s2ff-arm.pl [--page name | --items | --size] [--zero name] file.s file.dump [--then crtn.s crtn.dump]\n"); o_flush (); cp_exit (255); }
  src_s = files->v[0]; dump_s = files->v[1];
  where = dump_s;
  armdec_load ();
  {
    char *c = "eq ne cs cc mi pl vs vc hi ls ge lt gt le al";
    long k = 0, q = 0;
    while (k < 15) { long a = q; char *w; while (c[q] && c[q] != ' ') q++; w = alloc (q - a + 1); mcopy ((unsigned char *) w, (unsigned char *) c + a, q - a); armcc[k++] = w; if (c[q]) q++; }
  }
  asym = h_new (); asymsec = h_new (); secsyms = h_new (); secend = h_new (); asecs = h_new (); aundef = h_new (); secs_order = v_new ();
  aaliases = v_new (); adata = v_new (); dlab_b = h_new (); dlab_o = h_new (); agot = h_new (); aweakref = h_new (); srcalias = h_new ();
  arm_readdump (dump_s, 0);
  if (then_v->n) {
    arm_readdump (then_v->n > 1 ? then_v->v[1] : s_of (""), 1);
    for (i = 0; i < secs_order->n; i++) { struct hent *e = h_find (secend, secs_order->v[i]); if (e) e->pv = 0; }
  }
  abase = ssub (ssub (src_s, ".*/", "", ""), "\\.s$", "", "");
  arm_source ();
  fns = v_new ();
  for (sidx = 0; sidx < secs_order->n; sidx++) {
    struct str *s = secs_order->v[sidx], *first, *cm;
    struct vec *lines = ((struct asec *) h_pv (asecs, s))->lines, *syms, *outa, *outn;
    struct hash *tgtset = h_new ();
    long next, l0;
    struct nd *fnx, *into;
    if (!lines->n) continue;
    anames = h_new ();
    syms = h_pv (secsyms, s);
    {
      struct vec *srt = v_new ();
      if (syms) for (i = 0; i < syms->n; i++) ainsert_sorted (srt, syms->v[i]);
      for (i = 0; i < srt->n; i++) {
        struct sympos *x = srt->v[i];
        struct vec *nv = h_pv (anames, s_num (x->addr));
        if (!nv) { nv = v_new (); h_setp (anames, s_num (x->addr), nv); }
        v_push (nv, x->name);
      }
    }
    l0 = ((struct aline *) lines->v[0])->addr;
    if (!h_pv (anames, s_num (l0))) { struct vec *nv = v_new (); struct str *x = s_dup (abase); s_cat (x, " "); s_app (x, s); v_push (nv, x); h_setp (anames, s_num (l0), nv); }
    outa = v_new (); outn = v_new ();
    next = l0;
    for (i = 0; i <= lines->n; i++) {
      struct aline *li = i < lines->n ? lines->v[i] : 0;
      long to = li ? li->addr : (hdef (secend, s) ? h_iv (secend, s) : next);
      struct areloc *rel;
      struct str *mode, *mn;
      unsigned long v;
      struct vec *found;
      struct afound *f;
      struct nd *ins;
      long k;
      while (next < to) {
        long w = next % 4 == 0 && to - next >= 4 ? 4 : 1;
        long *ap = alloc (sizeof (long));
        *ap = next;
        v_push (outa, ap); v_push (outn, nd1 (s_of (w == 4 ? "word" : "byte"), ndc ("0")));
        abytes += w; has_bytes = 1;
        next += w;
      }
      if (!li) break;
      next = li->addr + (m (li->hex, "^(\\w{4}) (\\w{4})$") ? 4 : li->hex->n / 2);
      rel = li->relocs->n ? li->relocs->v[0] : 0;
      if (m (li->op, "^\\.(word|short|byte)$")) {
        struct str *w = g (1);
        long hv = hexl (li->hex), *ap = alloc (sizeof (long));
        abytes += s_is (w, "word") ? 4 : s_is (w, "short") ? 2 : 1; has_bytes = 1;
        *ap = li->addr;
        v_push (outa, ap);
        v_push (outn, rel ? data_reloc (rel, hv) : nd1 (s_of (s_is (w, "word") ? "word" : s_is (w, "short") ? "half" : "byte"), LN (hv)));
        continue;
      }
      if (m (li->hex, "^(\\w{4}) (\\w{4})$")) { struct str *a = g (1), *b = g (2); mode = s_of ("t2"); v = (unsigned long) hexl (b) << 16 | (unsigned long) hexl (a); }
      else if (li->hex->n == 4) { mode = s_of ("t"); v = (unsigned long) hexl (li->hex); }
      else { mode = s_of ("a"); v = (unsigned long) hexl (li->hex); }
      abytes += s_is (mode, "t") ? 2 : 4; has_bytes = 1;
      mn = m (li->args, "@ \\((\\S+)") ? g (1) : li->op;
      found = armdec_decode ((char *) mode->p, v);
      f = 0;
      {
        long best = 3;
        for (k = 0; k < found->n; k++) { long sc = arm_score (found->v[k], mn); if (sc < best) { best = sc; f = found->v[k]; } }
      }
      if (!f) { struct str *x = s_of ("no ff form for "); s_app (x, li->op); s_cat (x, " "); s_app (x, li->args); s_cat (x, " ("); s_app (x, li->hex); s_cat (x, ")"); arm_fail (x); }
      {
        struct vec *ops = v_new ();
        for (k = 0; k < f->ops->n; k++) v_push (ops, nd_new (f->ops->v[k]));
        if (f->d->branch) {
          long kk = -1, to2, off;
          struct str *lb;
          for (k = 0; k < f->d->params->n && kk < 0; k++) if (m (f->d->params->v[k], "^u?imm$")) kk = k;
          off = dec (f->ops->v[kk]);
          if (((struct str *) f->ops->v[kk])->p[0] == '-') off = -dec (s_sub (f->ops->v[kk], 1, ((struct str *) f->ops->v[kk])->n));
          to2 = li->addr + (s_is (mode, "a") ? 8 : 4) + off;
          if (rel && m (rel->rkind, "^(R_ARM_CALL|R_ARM_JUMP24|R_ARM_THM_CALL|R_ARM_THM_JUMP24|R_ARM_PLT32)$") && h_iv (aweakref, rel->tgtset) && h_iv (aundef, rel->tgtset)) {
            lb = s_of (".Lweak "); s_app (lb, rel->tgtset); h_set (weakb_, rel->tgtset, 1);
          } else if (rel && m (rel->rkind, "^(R_ARM_CALL|R_ARM_JUMP24|R_ARM_THM_CALL|R_ARM_THM_JUMP24|R_ARM_PLT32)$")) {
            if (h_iv (aplt, rel->tgtset)) { lb = s_of ("__ff_plt_"); s_app (lb, rel->tgtset); } else lb = rel->tgtset;
          } else if (rel) { struct str *x = s_of ("a branch with "); s_app (x, rel->rkind); arm_fail (x); lb = 0; }
          else { lb = alname (to2); h_set (tgtset, s_num (to2), 1); }
          ops->v[kk] = nd1 (s_of (s_is (mode, "a") ? "arel" : "trel"), nd_new (lb));
        } else if (rel) {
          long kk = -1, a;
          struct str *hhalf;
          int pcrel;
          struct nd *sy, *val;
          for (k = 0; k < f->d->params->n && kk < 0; k++) if (s_is (f->d->params->v[k], "imm16")) kk = k;
          if (!(kk >= 0 && m (rel->rkind, "^R_ARM_MOV([WT])_(ABS_NC|ABS|PREL_NC|PREL)$"))) { struct str *x = s_dup (rel->rkind); s_cat (x, " at "); s_app (x, f->name); arm_fail (x); }
          hhalf = s_of (g (1)->p[0] == 'W' ? "lo16" : "hi16");
          pcrel = m (g (2), "PREL");
          a = dec (f->ops->v[kk]);
          if (a >= 32768) a -= 65536;
          sy = asymbol (rel->tgtset);
          val = pcrel ? pcsub (sy) : sy;
          if (a) val = aplus (a, val);
          ops->v[kk] = nd1 (hhalf, val);
        }
        ins = nd_new (f->name);
        for (k = 0; k < ops->n; k++) nd_add (ins, ops->v[k]);
        {
          long *ap = alloc (sizeof (long));
          *ap = li->addr;
          v_push (outa, ap); v_push (outn, ins);
        }
      }
    }
    first = ((struct vec *) h_pv (anames, s_num (l0)))->v[0];
    cm = s_of ("glibc-2.44 "); s_app (cm, afile ? afile : src_s); s_cat (cm, " ("); s_app (cm, s); s_cat (cm, ")");
    {
      struct str *x = s_dup (first);
      s_cat (x, ":");
      fnx = nd2 (x, ndc ("asm"), nd1 (s_of ("comment"), nd_new (cm)));
    }
    into = fnx;
    for (i = 0; i < outa->n; i++) {
      long at = *(long *) outa->v[i];
      struct vec *nv = h_pv (anames, s_num (at));
      if (at != l0 && (nv || h_has (tgtset, s_num (at)))) {
        struct str *lb = s_dup (alname (at));
        long k;
        if (nv) for (k = 1; k < nv->n; k++) { struct str *x = s_dup (nv->v[k]); s_cat (x, ":"); nd_add (fnx, nd1 (x, ndc ("asm"))); }
        s_cat (lb, ":");
        into = nd_new (lb);
        if (nv) nd_add (into, ndc ("asm"));
        nd_add (fnx, into);
      }
      nd_add (into, outn->v[i]);
    }
    {
      struct vec *nv = h_pv (anames, s_num (l0));
      for (i = 1; i < nv->n; i++) v_push (aaliases, alias_of (nv->v[i], first));
    }
    {
      struct vec *k = h_sorted (weakb_);
      for (i = 0; i < k->n; i++) { struct str *x = s_of (".Lweak "); s_app (x, k->v[i]); s_cat (x, ":"); nd_add (fnx, nd1 (x, nd1 (s_of ("udf"), ndc ("0")))); }
      h_clear (weakb_);
    }
    v_push (fns, fnx);
  }
  if (o_size) { o_s (s_num (abytes)); o_str ("\n"); o_flush (); cp_exit (0); }
  { struct str *x = s_of ("size "); s_app (x, s_num (abytes)); s_cat (x, "\n"); facts_write (x); }
  if (agot->n) {
    struct vec *k = h_sorted (agot);
    struct str *x = s_dup (abase);
    s_cat (x, " got:");
    v_push (adata, nd2 (x, ndc ("asm"), nd1 (s_of ("align"), ndc ("4"))));
    for (i = 0; i < k->n; i++) {
      struct str *n = k->v[i], *y = s_dup (abase);
      s_cat (y, " got "); s_app (y, n); s_cat (y, ":");
      if (h_iv (aweakref, n) && h_iv (aundef, n)) v_push (adata, nd_add (nd_add (nd_add (nd1 (y, ndc ("void")), nd_new (w_ptr ())), nd_new (n)), nd_new (w_addr ())));
      else v_push (adata, nd2 (y, ndc ("asm"), h_pv (agot, n)));
    }
  }
  {
    struct vec *k = h_sorted (aweakref);
    for (i = 0; i < k->n; i++) if (h_iv (aundef, k->v[i])) { struct str *x = s_dup (k->v[i]); s_cat (x, ":"); v_push (fns, nd_add (nd2 (x, ndc ("weak"), ndc ("function")), ndc ("void"))); }
  }
  {
    struct hash *seen = h_new (), *entry = h_new ();
    struct vec *all = v_new ();
    for (i = 0; i < fns->n; i++) h_set (entry, unlabel (((struct nd *) fns->v[i])->c), 1);
    for (i = 0; i < fns->n; i++) label_walk (fns->v[i], entry);
    for (i = 0; i < fns->n; i++) v_push (all, fns->v[i]);
    for (i = 0; i < adata->n; i++) v_push (all, adata->v[i]);
    for (i = 0; i < aaliases->n; i++) {
      struct nd *a = aaliases->v[i];
      struct str *n = unlabel (a->c);
      int dup = h_has (seen, n);
      h_set (seen, n, 1);
      if (!dup && !h_has (entry, n)) v_push (all, a);
    }
    if (o_items) o_s (write_txt (all));
    else {
      struct str *pg = s_dup (page);
      struct nd *top;
      struct vec *one = v_new ();
      s_cat (pg, ":");
      top = nd_new (pg);
      for (i = 0; i < all->n; i++) nd_add (top, all->v[i]);
      v_push (one, top);
      o_s (write_txt (one));
    }
  }
  o_flush ();
}
