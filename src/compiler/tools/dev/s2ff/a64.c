/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* a64.c: gen/s2ff-aarch64.pl in ff (s2ff --target aarch64): the
   instructions read from the object GNU as made (its dump), each word
   decoded by the forms of ttpc's aarch64 section (the section of the
   shared page, --shared: the tree isa/aarch64.pl makes), its labels from
   the symbol table, the .s for its lines, aliases and other sections. */

/* ---- an ff file: the tree (hash, children, content) */
static unsigned char *ffp; static long ffn, ffi;
static struct nd *ff_node (void)
{
  struct nd *x;
  long k, i, len;
  struct vec *kids = v_new ();
  if (ffi + 33 > ffn) return 0;
  ffi += 32;
  k = ffp[ffi++];
  for (i = 0; i < k; i++) { struct nd *c = ff_node (); if (!c) return 0; v_push (kids, c); }
  if (ffi >= ffn) return 0;
  len = ffp[ffi++];
  if (ffi + len > ffn) return 0;
  x = nd_new (s_new (ffp + ffi, len));
  ffi += len;
  x->k = kids;
  return x;
}
static struct str *shared_f;
/* the section of a target (aarch64:) of the shared page */
static struct nd *section_of (char *tgtset)
{
  struct str *t, *want = s_of (tgtset);
  struct nd *root;
  long i, j;
  if (!shared_f) die_c ("s2ff: no --shared FILE (the shared page, src/compiler/shared.ff)\n");
  t = read_all ((char *) shared_f->p);
  if (!t) { struct str *x = s_of ("s2ff: cannot open "); s_app (x, shared_f); s_cat (x, "\n"); die_s (x); }
  ffp = t->p; ffn = t->n; ffi = 0;
  root = ff_node ();
  if (!root) { struct str *x = s_of ("s2ff: "); s_app (x, shared_f); s_cat (x, " is not an ff tree\n"); die_s (x); }
  s_cat (want, ":");
  for (i = 0; i < ndn (root); i++) {
    struct nd *sh = ndk (root, i);
    if (!s_is (sh->c, "shared:")) continue;
    for (j = 0; j < ndn (sh); j++) if (s_eq (ndk (sh, j)->c, want)) return ndk (sh, j);
  }
  { struct str *x = s_of ("s2ff: no section "); s_app (x, want); s_cat (x, " in "); s_app (x, shared_f); s_cat (x, "\n"); die_s (x); }
  return 0;
}

/* ---- ttpc's aarch64 instructions: fixed fields and operand slices */
struct slice { long pos, hi, lo; };
struct param { struct str *name; struct slice *sl; long nsl; long top; };
/* a def's operand of a computed field, by the def's name and the operand's: 16 or 128 less the field (shr16, shr128) */
static struct hash *inverses;
struct def { struct str *name; struct param *pa; long npa; unsigned long mask, value; long bits; long order; };
static struct def **defs;
static long ndefs;
static long bit_count (unsigned long x) { long n = 0; while (x) { n += (long) (x & 1); x = x >> 1; } return n; }
static unsigned long bin_of (struct str *s) { unsigned long v = 0; long i; for (i = 0; i < s->n; i++) v = v * 2 + (unsigned long) (s->p[i] - '0'); return v; }
static struct param *param_of (struct def *d, struct str *p)
{
  long i;
  for (i = 0; i < d->npa; i++) if (s_eq (d->pa[i].name, p)) return &d->pa[i];
  return 0;
}
static void slice_add (struct param *p, long pos, long hi, long lo)
{
  struct slice *x = alloc ((p->nsl + 1) * sizeof (struct slice));
  long i;
  for (i = 0; i < p->nsl; i++) x[i] = p->sl[i];
  x[p->nsl].pos = pos; x[p->nsl].hi = hi; x[p->nsl].lo = lo;
  p->sl = x; p->nsl++;
  if (p->nsl == 1 || hi > p->top) p->top = hi;
}
static void defs_load (char *tgtset, char *skip)
{
  struct nd *sec = section_of (tgtset);
  struct vec *dv = v_new ();
  long gi, didx, ki;
  for (gi = 0; gi < ndn (sec); gi++) {
    struct nd *gr = ndk (sec, gi);
    if (mdyn (gr->c, s_of (skip), "")) continue;
    for (didx = 0; didx < ndn (gr); didx++) {
      struct nd *dd = ndk (gr, didx);
      struct def *d;
      struct vec *params = v_new ();
      long pos = 32, npa = 0;
      struct str *name;
      if (!m (dd->c, "^(.+):$")) continue;
      name = g (1);
      if (m (name, "\\[")) continue;
      d = alloc (sizeof (struct def));
      d->name = name;
      for (ki = 0; ki < ndn (dd); ki++) if (!ndn (ndk (dd, ki))) v_push (params, ndk (dd, ki)->c);
      d->pa = alloc ((params->n + 1) * sizeof (struct param));
      for (ki = 0; ki < params->n; ki++) d->pa[npa++].name = params->v[ki];
      d->npa = npa;
      for (ki = 0; ki < ndn (dd); ki++) {
        struct nd *k = ndk (dd, ki);
        struct str *fname, *p;
        long hi, lo;
        struct param *pp;
        if (!ndn (k)) continue;
        if (m (k->c, "^(\\w+):$")) {
          struct str *bits = ndk (k, 0)->c;
          long w = bits->n;
          pos -= w;
          d->mask |= (((unsigned long) 1 << w) - 1) << pos;
          d->value |= bin_of (bits) << pos;
          continue;
        }
        if (!m (k->c, "^(\\w+)\\[(\\d+)(?::(\\d+))?\\]$")) { struct str *x = s_of ("s2ff: isa: "); s_app (x, name); s_cat (x, ": field "); s_app (x, k->c); s_cat (x, "\n"); die_s (x); }
        fname = g (1); hi = dec (g (2)); lo = gdef (3) ? dec (g (3)) : hi;
        p = ndk (k, 0)->c;
        pp = param_of (d, p);
        if (!s_eq (fname, p)) {
          int inv = s_is (fname, "shr16") ? 16 : s_is (fname, "shr128") ? 128 : 0;
          struct str *key = s_dup (name);
          if (!inv) { struct str *x = s_of ("s2ff: isa: "); s_app (x, name); s_cat (x, ": no inverse of "); s_app (x, fname); s_cat (x, "\n"); die_s (x); }
          s_cat (key, " "); s_app (key, p);
          h_set (inverses, key, inv);
        }
        pos -= hi - lo + 1;
        if (pp) slice_add (pp, pos, hi, lo);
      }
      if (pos) { struct str *x = s_of ("s2ff: isa: "); s_app (x, name); s_cat (x, " has "); s_app (x, s_num (pos)); s_cat (x, " bits left\n"); die_s (x); }
      d->bits = bit_count (d->mask);
      d->order = dv->n;
      v_push (dv, d);
    }
  }
  defs = (struct def **) dv->v; ndefs = dv->n;
}

static struct hash *regparam;
/* Perl's "%.15g" of the NV 2**64 - v (v > 0): the double nearest, then 15 digits */
static struct str *nv_g15 (unsigned long v)
{
  unsigned long u = (unsigned long) 0 - v, d, q, r;   /* 2**64 - v, below 2**64 */
  long top = 63, e = 0, nd = 0, i, exp10;
  char dg[24];
  struct str *o;
  while (top > 0 && !((u >> top) & 1)) top--;
  if (top > 52) {   /* to 53 bits, the half to even */
    long sh = top - 52;
    unsigned long hhalf = (unsigned long) 1 << (sh - 1), rem = u & (((unsigned long) 1 << sh) - 1);
    d = u >> sh;
    if (rem > hhalf || (rem == hhalf && (d & 1))) d++;
    if (d >> 53) { d = d >> 1; sh++; }
    e = sh;
  } else d = u;
  /* the value d * 2**e as decimal digits; 2**64 itself when it rounds up to it */
  if (e && (d >> (64 - e))) return s_of ("1.84467440737096e+19");
  q = d << e;
  r = q;
  while (r) { dg[nd++] = (char) ('0' + r % 10); r = r / 10; }
  exp10 = nd - 1;
  if (nd <= 15) return s_unum (q);
  /* round to 15 digits, the half to even on the exact value */
  {
    long cut = nd - 15, k;
    int up = 0, more = 0;
    for (k = 0; k < cut - 1; k++) if (dg[k] != '0') more = 1;
    if (dg[cut - 1] > '5' || (dg[cut - 1] == '5' && (more || ((dg[cut] - '0') & 1)))) up = 1;
    for (k = cut; up && k < nd; k++) { if (dg[k] == '9') dg[k] = '0'; else { dg[k]++; up = 0; } }
    if (up) { dg[nd++] = '1'; exp10++; cut++; }
    o = s_of ("");
    i = nd - 1;
    s_chr (o, dg[i]);
    {
      long last = cut;
      while (last < i && dg[last] == '0') last++;
      if (last < i) { s_chr (o, '.'); for (k = i - 1; k >= last; k--) s_chr (o, dg[k]); }
    }
  }
  if (exp10 < 15) return s_unum (q);
  s_cat (o, "e+"); if (exp10 < 10) s_chr (o, '0'); s_app (o, s_num (exp10));
  return o;
}
static char *conds[16];
struct a64m { struct str *sec, *op, *args; long addr; unsigned long wordv; struct str *rt; struct str *rs; long rsec_off; struct str *rsec; int has_reloc, rs_local; };

static struct def *decode (struct a64m *mm, long *vals)
{
  long i, best = -1, j;
  struct def *d = 0;
  int ok;
  for (i = 0; i < ndefs; i++) if ((mm->wordv & defs[i]->mask) == defs[i]->value && defs[i]->bits > best) best = defs[i]->bits;
  if (best < 0) {
    struct str *x = s_of ("no ff form for "); s_app (x, mm->op); s_cat (x, " "); s_app (x, mm->args); s_cat (x, " ("); s_app (x, s_hex (mm->wordv, 8, 0)); s_cat (x, ")");
    fail_s (x);
  }
  for (i = 0; i < ndefs && !d; i++) if ((mm->wordv & defs[i]->mask) == defs[i]->value && defs[i]->bits == best && s_eq (defs[i]->name, mm->op)) d = defs[i];
  for (i = 0; i < ndefs && !d; i++) if ((mm->wordv & defs[i]->mask) == defs[i]->value && defs[i]->bits == best) d = defs[i];
  ok = d->name->n >= mm->op->n && msame (d->name->p, mm->op->p, mm->op->n);
  if (!ok) {
    if (s_is (mm->op, "hint")) ok = m (d->name, "^(nop|bti(\\.\\w+)?|paciasp|autiasp|chkfeat)$");
    else if (s_is (mm->op, "sys")) ok = m (d->name, "^(dc\\.\\w+|gcsss1)$");
    else if (s_is (mm->op, "sysl")) ok = m (d->name, "^(gcsss2|gcspopm)$");
  }
  if (!ok) { struct str *x = s_of ("ttpc's "); s_app (x, d->name); s_cat (x, " for "); s_app (x, mm->op); s_cat (x, " "); s_app (x, mm->args); fail_s (x); }
  for (i = 0; i < d->npa; i++) {
    struct param *p = &d->pa[i];
    long v = 0;
    for (j = 0; j < p->nsl; j++) {
      struct slice *s = &p->sl[j];
      v |= (long) (((mm->wordv >> s->pos) & (((unsigned long) 1 << (s->hi - s->lo + 1)) - 1)) << s->lo);
    }
    if (s_is (p->name, "imm") && p->nsl && ((v >> p->top) & 1)) v -= (long) 1 << (p->top + 1);
    { struct str *key = s_dup (d->name); long inv; s_cat (key, " "); s_app (key, p->name); inv = h_iv (inverses, key); if (inv) v = inv - v; }
    vals[i] = v;
  }
  return d;
}

/* ---- what GNU as made */
static struct hash *sym;      /* "sec value" -> vec of names */
static struct hash *sect;     /* name -> its section */
static struct hash *codes;
static struct vec *a64_readdump (struct str *file, int symbols)
{
  struct str *t = p_slurp ((char *) file->p, "s2ff"), *insec = s_of ("");
  struct lines *ls = split_lines (t);
  struct vec *mv = v_new ();
  long i;
  for (i = 0; i < ls->n; i++) {
    struct str *l = chomp (ls->l[i]);
    if (symbols && m (l, "^([0-9a-f]{16}) (.{7}) (\\S+)\\t[0-9a-f]+ (.+)$")) {
      struct str *vs = g (1), *flags = g (2), *sec = g (3), *name = g (4), *key;
      unsigned long v = 0;
      long k;
      struct vec *lst;
      for (k = 0; k < vs->n; k++) v = v * 16 + (unsigned long) hexv (vs->p[k]);
      name = ssub (name, "^(?:\\.(?:hidden|protected|internal)|0x[0-9a-f]+) ", "", "");
      if (m (name, "^\\$[xd]") || m (flags, "d") || s_is (sec, "*ABS*")) continue;
      h_setp (sect, name, sec);
      if (s_is (sec, "*UND*")) continue;
      key = s_dup (sec); s_cat (key, " "); s_app (key, s_unum (v));
      lst = h_pv (sym, key);
      if (!lst) { lst = v_new (); h_setp (sym, key, lst); }
      v_push (lst, name);
      continue;
    }
    if (m (l, "^Disassembly of section (\\S+):")) insec = g (1);
    if (!h_has (codes, insec)) continue;
    if (m (l, "^\\s*([0-9a-f]+):\\t([0-9a-f]{8}) \\t(\\S+)\\s*(.*?)\\s*$")) {
      struct a64m *mm = alloc (sizeof (struct a64m));
      struct str *a = g (1), *w = g (2), *op = g (3), *args = g (4);
      long k;
      for (k = 0; k < a->n; k++) mm->addr = mm->addr * 16 + hexv (a->p[k]);
      for (k = 0; k < w->n; k++) mm->wordv = mm->wordv * 16 + (unsigned long) hexv (w->p[k]);
      args = ssub (args, "\\s*//.*$", "", "");
      args = ssub (args, "\\s*<[^>]*>$", "", "");
      mm->sec = insec; mm->op = op; mm->args = args;
      v_push (mv, mm);
      continue;
    }
    if (m (l, "^\\s*([0-9a-f]+): (R_AARCH64_\\w+)\\s+(\\S+)$")) {
      struct str *as = g (1), *rt = g (2), *s = g (3);
      long a = 0, k;
      struct a64m *last = mv->n ? mv->v[mv->n - 1] : 0;
      for (k = 0; k < as->n; k++) a = a * 16 + hexv (as->p[k]);
      if (!(last && last->addr == a)) { struct str *x = s_of ("a relocation of "); s_app (x, s); s_cat (x, " at "); s_app (x, s_num (a)); s_cat (x, " outside an instruction"); fail_s (x); }
      if (m (s, "^(\\.[\\w.]+)(?:\\+0x([0-9a-f]+))?$") && !h_has (sect, s)) {
        struct str *sc = g (1), *off = g (2);
        long o = 0;
        if (off) for (k = 0; k < off->n; k++) o = o * 16 + hexv (off->p[k]);
        last->rs_local = 1; last->rsec = sc; last->rsec_off = o; last->rs = 0;
      } else if (m (s, "[+-]0x")) { struct str *x = s_of ("a relocation "); s_app (x, rt); s_cat (x, " of "); s_app (x, s); s_cat (x, " with an addend"); fail_s (x); }
      else { last->rs = s; last->rs_local = 0; }
      last->rt = rt; last->has_reloc = 1;
    }
  }
  perrno = 0;   /* (close $d) */
  return mv;
}

/* ---- the source */
static struct hash *a_line, *a_alias, *rodata, *weakref, *zeroed;
static struct vec *a_data;
static struct str *ffname (struct str *n)
{
  if (m (n, "^\\.L(\\d+)__(\\d+)$")) { struct str *x = s_of (".L"); s_app (x, g (1)); s_cat (x, " "); s_app (x, g (2)); return x; }
  return n;
}
static int isL (struct str *s) { return s->n >= 2 && s->p[0] == '.' && s->p[1] == 'L'; }
/* names sorted with the .L ones last (Perl's stable sort on that alone) */
static struct vec *sort_L_last (struct vec *in)
{
  struct vec *o = v_new ();
  long i;
  for (i = 0; i < in->n; i++) if (!isL (in->v[i])) v_push (o, in->v[i]);
  for (i = 0; i < in->n; i++) if (isL (in->v[i])) v_push (o, in->v[i]);
  return o;
}
static struct vec *not_aliased (struct vec *in)
{
  struct vec *o = v_new ();
  long i;
  if (in) for (i = 0; i < in->n; i++) if (!h_has (a_alias, in->v[i])) v_push (o, in->v[i]);
  return o;
}
static struct str *key_of (struct str *sec, long a) { struct str *k = s_dup (sec); s_cat (k, " "); s_app (k, s_num (a)); return k; }

static void a64_source (void)
{
  struct str *t = p_slurp ((char *) src_s->p, "s2ff"), *file = s_of (""), *other = 0;
  struct lines *ls = split_lines (t);
  struct vec *pending = v_new (), *blob = v_new ();
  struct hash *datadef = h_new ();
  long ln = 0, li;
  int inmacro = 0;
  perrno = 25;
  for (li = 0; li < ls->n; li++) {
    struct str *l = chomp (ls->l[li]);
    struct vec *sts;
    long sx;
    if (m (l, "^# (\\d+) \"([^\"]+)\"")) { ln = dec (g (1)) - 1; file = ssub (g (2), "^(\\.\\./)+", "", ""); continue; }
    ln++;
    if (!m (l, "\"")) l = ssub (l, "\\s*//.*$", "", "");
    where = s_dup (src_s); s_cat (where, " ("); s_app (where, file); s_cat (where, ":"); s_app (where, s_num (ln)); s_cat (where, ")");
    sts = ssplit (";", l, 0);
    for (sx = 0; sx < sts->n; sx++) {
      struct str *st = s_trim (sts->v[sx]);
      long i;
      if (st->n == 0) continue;
      if (m (st, "^\\.(?:aeabi_subsection|aeabi_attribute|ident)\\b")) continue;
      if (m (st, "^\\.macro\\b")) inmacro = 1;
      if (inmacro) { if (m (st, "^\\.endm\\b")) inmacro = 0; continue; }
      if (m (st, "^\\.(data|bss|section\\s+([^,\\s]+)(,.*)?)$") || m (st, "^\\.(previous)$")) {
        struct str *sec;
        if (gdef (2)) sec = g (2); else { sec = s_of ("."); s_app (sec, g (1)); }
        if (s_is (sec, ".previous")) sec = s_of (".text");
        if (h_has (codes, sec)) { other = 0; continue; }
        other = sec;
        pending = v_new (); blob = v_new ();
        if (m (sec, "^\\.(pre)?init_array$|^\\.fini_array$")) { struct str *x = s_of ("s2ff: "); s_app (x, where); s_cat (x, ": "); s_app (x, sec); s_cat (x, " left out\n"); e_s (x); }
        continue;
      }
      if (s_is (st, ".text")) { other = 0; continue; }
      if (other) {
        if (m (st, "^\\.(globl|global|weak|type|size|hidden|align|p2align|balign)\\b")) continue;
        if (m (st, "^([.\\w]+):$")) { v_push (pending, g (1)); blob = v_new (); continue; }
        if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$")) { struct str *a = g (1), *b = g (2); if (h_iv (datadef, b)) v_push (a_data, alias_of (a, b)); continue; }
        if (m (other, "^\\.(pre)?init_array$|^\\.fini_array$") && m (st, "^\\.(dc\\.a|xword|quad)\\s+[.\\w]+$")) continue;
        if (m (other, "^\\.rodata") && m (st, "^\\.(string|asciz|ascii)\\s+\"((?:[^\"\\\\]|\\\\.)*)\"$") && pending->n) {
          struct str *k = g (1), *tx = g (2), *o = s_of ("");
          struct vec *lst;
          i = 0;
          while (i < tx->n) {
            if (tx->p[i] != '\\' || i + 1 >= tx->n) { s_chr (o, tx->p[i]); i++; continue; }
            i++;
            if (tx->p[i] >= '0' && tx->p[i] <= '7') { long v = 0, c = 0; while (c < 3 && i < tx->n && tx->p[i] >= '0' && tx->p[i] <= '7') { v = v * 8 + tx->p[i] - '0'; i++; c++; } s_chr (o, (int) (v & 255)); continue; }
            if (tx->p[i] == 'x' && i + 1 < tx->n && is_xdigit (tx->p[i + 1])) { long v = 0, c = 0; i++; while (c < 2 && i < tx->n && is_xdigit (tx->p[i])) { v = v * 16 + hexv (tx->p[i]); i++; c++; } s_chr (o, (int) v); continue; }
            {
              int e = tx->p[i];
              int r = e == 'n' ? '\n' : e == 't' ? '\t' : e == 'r' ? '\r' : e == '"' ? '"' : e == '\\' ? '\\' : -1;
              if (r < 0) { struct str *x = s_of ("an escape \\"); s_chr (x, e); fail_s (x); }
              s_chr (o, r); i++;
            }
          }
          if (!s_is (k, "ascii")) s_chr (o, 0);
          for (i = 0; i < pending->n; i++) { lst = v_new (); v_push (lst, nd1 (s_of ("ascii"), nd_new (o))); h_setp (rodata, pending->v[i], lst); }
          pending = v_new ();
          continue;
        }
        if (m (other, "^\\.rodata") && m (st, "^\\.(byte|hword|short|word|long|xword|quad|dword|zero)\\s+(-?(?:0x[0-9a-fA-F]+|\\d+))$") && (blob->n || pending->n)) {
          struct str *k = g (1), *vs = g (2), *dir;
          long bits;
          if (mf (vs, "^(-?)0x(.*)$", "i")) {
            struct str *neg = g (1), *hx = g (2);
            unsigned long h = 0;
            long q;
            for (q = 0; q < hx->n; q++) h = h * 16 + (unsigned long) hexv (hx->p[q]);
            vs = neg->n ? s_num (-(long) h) : s_unum (h);
          }
          if (pending->n) {
            struct vec *lst = v_new ();
            blob = pending; pending = v_new ();
            for (i = 0; i < blob->n; i++) h_setp (rodata, blob->v[i], lst);
          }
          if (s_is (k, "zero")) { v_push (h_pv (rodata, blob->v[0]), nd1 (s_of ("reserve"), nd_new (vs))); continue; }
          if (s_is (k, "byte")) { dir = s_of ("byte"); bits = 8; }
          else if (s_is (k, "hword") || s_is (k, "short")) { dir = s_of ("half"); bits = 16; }
          else if (s_is (k, "word") || s_is (k, "long")) { dir = s_of ("word"); bits = 32; }
          else { dir = s_of ("dword"); bits = 64; }
          if (vs->n && vs->p[0] == '-') {   /* $v += 2 ** $bits if $v < 0 */
            unsigned long v = 0;
            long q;
            for (q = 1; q < vs->n; q++) v = v * 10 + (unsigned long) (vs->p[q] - '0');
            if (v) vs = bits == 64 ? nv_g15 (v) : s_num (((long) 1 << bits) - (long) v);
          }
          v_push (h_pv (rodata, blob->v[0]), nd1 (dir, nd_new (vs)));
          continue;
        }
        if (m (st, "^\\.(long|word|quad|xword|byte|hword)\\s+0$")) {
          struct str *k = g (1);
          st = s_of (".zero ");
          s_cat (st, s_is (k, "long") || s_is (k, "word") ? "4" : s_is (k, "quad") || s_is (k, "xword") ? "8" : s_is (k, "byte") ? "1" : "2");
        }
        if (m (st, "^\\.(zero|space)\\s+(\\d+)$") && pending->n) {
          struct str *first = pending->v[0], *x;
          if (!zeroed->n || h_has (zeroed, first)) {
            for (i = 0; i < pending->n; i++) h_set (datadef, pending->v[i], 1);
            for (i = 1; i < pending->n; i++) v_push (a_data, alias_of (pending->v[i], first));
          }
          x = s_of ("s2ff: "); s_app (x, where); s_cat (x, ": "); s_app (x, first); s_cat (x, " is zero, c2ff --zero "); s_app (x, first); s_cat (x, " makes it\n");
          e_s (x);
          pending = v_new ();
          continue;
        }
        { struct str *x = s_of ("bytes in "); s_app (x, other); s_cat (x, ": "); s_app (x, st); fail_s (x); }
      }
      while (m (st, "^([.\\w]+):\\s*")) {
        struct str *name = g (1);
        st = s_sub (st, rc[1], st->n);
        if (!h_has (a_line, name)) { struct str *x = s_dup (file); s_cat (x, ":"); s_app (x, s_num (ln)); h_setp (a_line, name, x); }
      }
      if (st->n == 0) continue;
      if (m (st, "^([.\\w]+)\\s*=\\s*([.\\w]+)$") || m (st, "^\\.set\\s+([.\\w]+)\\s*,\\s*([.\\w]+)$")) { struct str *a = g (1), *b = g (2); h_setp (a_alias, a, b); continue; }
      if (m (st, "^\\.weak\\s+([.\\w]+)$")) h_set (weakref, g (1), 1);
    }
  }
  perrno = 0;
  where = src_s;
}

/* ---- the functions */
static struct hash *at_, *labelat, *a_got, *ro, *weakb, *fnof;
static struct vec *weakgot;
static int a_ends;
static int und (struct str *n) { struct str *s = h_pv (sect, n); return s && s_is (s, "*UND*"); }
static void a64_finish (void)
{
  long i;
  if (fn) {
    struct vec *k = h_sorted (weakb);
    for (i = 0; i < k->n; i++) { struct str *x = s_of (".Lweak "); s_app (x, k->v[i]); s_cat (x, ":"); nd_add (fn, nd1 (x, nd1 (s_of ("brk"), ndc ("0")))); }
  }
  h_clear (weakb);
  if (!(fn && (a_got->n || ro->n))) return;
  {
    struct vec *k = h_sorted (a_got), *keep = v_new ();
    for (i = 0; i < k->n; i++) {
      struct str *n = k->v[i];
      if (h_iv (weakref, n) && und (n)) {
        struct str *x = s_of (".Lgot "); s_app (x, n); s_cat (x, ":");
        v_push (weakgot, nd_add (nd_add (nd_add (nd1 (x, ndc ("void")), nd_new (w_ptr ())), nd_new (n)), nd_new (w_addr ())));
      } else v_push (keep, n);
    }
    if (keep->n) {
      nd_add (fn, nd1 (s_of ("align"), ndc ("8")));
      for (i = 0; i < keep->n; i++) { struct str *x = s_of (".Lgot "); s_app (x, keep->v[i]); s_cat (x, ":"); nd_add (fn, nd1 (x, nd1 (s_of ("dword"), nd_new (keep->v[i])))); }
    }
  }
  if (ro->n) {
    struct vec *k = h_sorted (ro);
    for (i = 0; i < k->n; i++) {
      struct str *x = s_dup (ffname (k->v[i]));
      struct nd *y;
      struct vec *lst = h_pv (rodata, k->v[i]);
      long j;
      s_cat (x, ":");
      y = nd_new (x);
      for (j = 0; j < lst->n; j++) nd_add (y, lst->v[j]);
      nd_add (fn, y);
    }
    nd_add (fn, nd1 (s_of ("align"), ndc ("8")));
  }
  h_clear (a_got); h_clear (ro);
}
static struct str *symof (struct a64m *mm)
{
  struct vec *l;
  struct str *x;
  if (!mm->rs_local) return mm->rs;
  l = sort_L_last (not_aliased (h_pv (sym, key_of (mm->rsec, mm->rsec_off))));
  if (!l->n) { x = s_of ("no label at "); s_app (x, mm->rsec); s_cat (x, "+"); s_app (x, s_num (mm->rsec_off)); fail_s (x); }
  x = l->v[0];
  if (!s_is (mm->rsec, ".text")) {
    if (!h_pv (rodata, x)) { struct str *y = s_dup (x); s_cat (y, " in "); s_app (y, mm->rsec); s_cat (y, ": no bytes for it"); fail_s (y); }
    h_set (ro, x, 1);
  }
  return ffname (x);
}
static int is_rel26 (struct str *rt) { return rt && m (rt, "^R_AARCH64_(CALL26|JUMP26|CONDBR19|TSTBR14)$"); }
static void a64_emit (struct a64m *mm)
{
  long vals[64], i, ntok = 0;
  struct def *d = decode (mm, vals);
  struct str *tokn[64]; long tokv[64]; int tokl[64];
  struct str *rt = mm->has_reloc ? mm->rt : 0, *rs = 0;
  struct nd *ins = nd_new (d->name);
  struct rx *rr = rx_get ("(?<![\\w.])([xwvqdshbzp])(\\d+)\\b|\\b(sp|wsp|xzr|wzr)\\b", "");
  long at = 0;
  int any = 0;
  while (at <= mm->args->n && rx_exec (rr, mm->args->p, mm->args->n, at) && ntok < 64) {
    g_s = mm->args->p;
    if (gdef (3)) { tokn[ntok] = g (3); tokv[ntok] = 31; }
    else { struct str *x = g (1); s_app (x, g (2)); tokn[ntok] = x; tokv[ntok] = dec (g (2)); }
    tokl[ntok] = 1;
    ntok++;
    at = rc[1] > rc[0] ? rc[1] : rc[0] + 1;
  }
  if (mm->has_reloc) rs = symof (mm);
  for (i = 0; i < d->npa; i++) {
    struct str *p = d->pa[i].name;
    long val = vals[i];
    if (h_has (regparam, p)) {
      long k, f = -1;
      for (k = 0; k < ntok && f < 0; k++) if (tokl[k] && tokv[k] == val) f = k;
      if (f < 0 && val == 31) { nd_add (ins, ndc ("xzr")); continue; }
      if (f < 0) { struct str *x = s_of ("no register "); s_app (x, s_num (val)); s_cat (x, " in "); s_app (x, mm->op); s_cat (x, " "); s_app (x, mm->args); fail_s (x); }
      nd_add (ins, nd_new (tokn[f]));
      tokl[f] = 0;
      continue;
    }
    if (s_is (p, "imm") && m (d->name, "^(b|bl|b\\.\\w+|cbn?zw?|tbn?z|adrp?|\\S+\\.lit)$")) {
      long to;
      struct str *l;
      if (is_rel26 (rt) && h_iv (weakref, rs) && und (rs)) { struct str *x = s_of (".Lweak "); s_app (x, rs); h_set (weakb, rs, 1); nd_add (ins, nd1 (s_of ("rel"), nd_new (x))); continue; }
      if (is_rel26 (rt)) { nd_add (ins, nd1 (s_of ("rel"), nd_new (rs))); continue; }
      if (rt && s_is (rt, "R_AARCH64_ADR_PREL_PG_HI21")) { nd_add (ins, nd1 (s_of ("pagerel"), nd_new (rs))); continue; }
      if (rt && s_is (rt, "R_AARCH64_ADR_GOT_PAGE")) { struct str *x = s_of (".Lgot "); s_app (x, rs); h_set (a_got, rs, 1); nd_add (ins, nd1 (s_of ("pagerel"), nd_new (x))); continue; }
      if (rt) { struct str *x = s_of ("a relocation "); s_app (x, rt); s_cat (x, " in "); s_app (x, mm->op); fail_s (x); }
      to = s_is (d->name, "adrp") ? (mm->addr & ~4095L) + val : mm->addr + val;
      l = h_pv (labelat, key_of (mm->sec, to));
      if (!l) { struct str *x = s_dup (mm->op); s_cat (x, " "); s_app (x, mm->args); s_cat (x, ": no label at "); s_app (x, s_num (to)); fail_s (x); }
      nd_add (ins, nd1 (s_of (s_is (d->name, "adrp") ? "pagerel" : "rel"), nd_new (ffname (l))));
      continue;
    }
    if (s_is (p, "uimm") && rt && m (rt, "^R_AARCH64_(ADD_ABS_LO12_NC|LDST(8|16|32|64|128)_ABS_LO12_NC)$")) { nd_add (ins, nd1 (s_of ("lo12"), nd_new (rs))); continue; }
    if (s_is (p, "uimm") && rt && s_is (rt, "R_AARCH64_LD64_GOT_LO12_NC")) { struct str *x = s_of (".Lgot "); s_app (x, rs); h_set (a_got, rs, 1); nd_add (ins, nd1 (s_of ("lo12"), nd_new (x))); continue; }
    if (s_is (p, "cond")) { nd_add (ins, nd_new (s_of (conds[val & 15]))); continue; }
    nd_add (ins, LN (val));
  }
  for (i = 0; i < ndn (ins); i++) if (ndn (ndk (ins, i))) any = 1;
  if (rt && !any) { struct str *x = s_of ("a relocation "); s_app (x, rt); s_cat (x, " in "); s_app (x, mm->op); s_cat (x, " "); s_app (x, mm->args); s_cat (x, ", no operand of it"); fail_s (x); }
  nd_add (block ? block : fn, ins);
  a_ends = m (d->name, "^(b|br|ret|retr)$") ? 1 : 0;
}

/* --locals: the numeric labels named */
static void a64_locals (void)
{
  struct str *t = p_slurp ((char *) src_s->p, "s2ff");
  struct lines *ls = split_lines (t);
  struct hash *count = h_new ();
  long li;
  int inmacro = 0;
  for (li = 0; li < ls->n; li++) {
    struct str *l = ls->l[li];
    struct vec *sts;
    long k;
    if (l->n && l->p[0] == '#') { o_s (l); continue; }
    sts = ssplit (";", l, 1);
    for (k = 0; k < sts->n; k++) {
      struct str *st = sts->v[k], *out = s_of (""), *rest = st;
      if (m (st, "^\\s*\\.macro\\b")) inmacro = 1;
      if (m (st, "^\\s*\\.endm\\b")) inmacro = 0;
      if (inmacro) continue;
      while (m (rest, "^(\\s*)(\\d+):")) {
        struct str *sp1 = g (1), *n = g (2);
        long c = h_iv (count, n) + 1;
        rest = s_join (sp1, "", s_sub (rest, rc[1], rest->n));
        h_set (count, n, c);
        s_cat (out, ".L"); s_app (out, n); s_cat (out, "__"); s_app (out, s_num (c)); s_cat (out, ":");
      }
      if (m (rest, "^\\s*[A-Za-z_]") && !m (rest, "^\\s*\\.")) {
        struct str *o = s_of ("");
        struct rx *rr = rx_get ("(?<![.\\w])(\\d+)([fb])\\b", "");
        long at = 0, last = 0;
        while (at <= rest->n && rx_exec (rr, rest->p, rest->n, at)) {
          struct str *n, *fb;
          g_s = rest->p;
          n = g (1); fb = g (2);
          s_add (o, rest->p + last, rc[0] - last);
          s_cat (o, ".L"); s_app (o, n); s_cat (o, "__"); s_app (o, s_num (h_iv (count, n) + (fb->p[0] == 'f' ? 1 : 0)));
          last = rc[1];
          at = rc[1] > rc[0] ? rc[1] : rc[0] + 1;
        }
        s_add (o, rest->p + last, rest->n - last);
        rest = o;
      }
      sts->v[k] = s_join (out, "", rest);
    }
    for (k = 0; k < sts->n; k++) { if (k) o_str (";"); o_s (sts->v[k]); }
  }
  perrno = 0;
}

static struct vec *blocks_of (struct nd *f, struct vec *b)
{
  long i;
  for (i = 0; i < ndn (f); i++) {
    struct nd *x = ndk (f, i);
    if (m (x->c, "^(.+):$") && ndn (x)) { v_push (b, g (1)); blocks_of (x, b); }
  }
  return b;
}

static void a64_main (struct vec *files)
{
  struct vec *all, *mv;
  long i, skip = 0;
  struct str *cursec = s_of ("");
  if (!files->n) { e_str ("usage: s2ff-aarch64.pl [--page name | --items | --size] file.s file.dump | --locals file.s\n"); o_flush (); cp_exit (255); }
  src_s = files->v[0];
  where = src_s;
  if (o_locals) { a64_locals (); o_flush (); cp_exit (0); }
  if (files->n != 2) { e_str ("usage: s2ff-aarch64.pl [--page name | --items | --size] file.s file.dump\n"); o_flush (); cp_exit (255); }
  dump_s = files->v[1];
  defs_load ("aarch64", "^(registers|slices|macros|elf|c|opt|pair128|linux|rv64):$");
  regparam = h_words ("rd rn rm ra rt rt2 rs zd zn zm zt pd pn pm pg");
  {
    char *c = "eq ne cs cc mi pl vs vc hi ls ge lt gt le al nv";
    long k = 0, q = 0;
    while (k < 16) { long a = q; char *w; while (c[q] && c[q] != ' ') q++; w = alloc (q - a + 1); mcopy ((unsigned char *) w, (unsigned char *) c + a, q - a); conds[k++] = w; if (c[q]) q++; }
  }
  sym = h_new (); sect = h_new (); codes = h_words (".text .init .fini");
  a_line = h_new (); a_alias = h_new (); rodata = h_new (); weakref = h_new (); a_data = v_new ();
  at_ = h_new (); labelat = h_new (); a_got = h_new (); ro = h_new (); weakb = h_new (); fnof = h_new (); weakgot = v_new ();
  all = a64_readdump (dump_s, 1);
  mv = v_new ();
  for (i = 0; i < all->n; i++) if (s_is (((struct a64m *) all->v[i])->sec, ".text")) v_push (mv, all->v[i]);
  while (mv->n) {
    struct a64m *x = mv->v[mv->n - 1];
    if (!(s_is (x->op, "hint") && s_is (x->args, "#0x0") && !h_has (sym, key_of (s_of (".text"), x->addr)))) break;
    mv->n--;
  }
  while (mv->n) {
    struct a64m *x = mv->v[0];
    if (!(s_is (x->op, "hint") && s_is (x->args, "#0x0") && !h_has (sym, key_of (s_of (".text"), x->addr)))) break;
    v_shift (mv); skip += 4;
  }
  if (o_size) { o_s (s_num (4 * mv->n)); o_str ("\n"); o_flush (); cp_exit (0); }
  if (o_skip) { o_s (s_num (skip)); o_str ("\n"); o_flush (); cp_exit (0); }
  { struct str *x = s_of ("size "); s_app (x, s_num (4 * mv->n)); s_cat (x, "\nskip "); s_app (x, s_num (skip)); s_cat (x, "\n"); facts_write (x); }
  for (i = 0; i < all->n; i++) if (!s_is (((struct a64m *) all->v[i])->sec, ".text")) v_push (mv, all->v[i]);
  a64_source ();
  /* where each label is, and the label a branch names at each place */
  for (i = 0; i < sym->keys->n; i++) {
    struct hent *e = sym->keys->v[i];
    struct str *sec;
    struct vec *l;
    if (!m (e->k, "^(\\S+) ")) continue;
    sec = g (1);
    if (!h_has (codes, sec)) continue;
    l = not_aliased (e->pv);
    h_setp (at_, e->k, l);
    l = sort_L_last (l);
    if (l->n) h_setp (labelat, e->k, l->v[0]);
  }
  fns = v_new ();
  for (i = 0; i < mv->n; i++) {
    struct a64m *mm = mv->v[i];
    struct vec *names = h_pv (at_, key_of (mm->sec, mm->addr)), *srt;
    long k;
    if (!s_eq (mm->sec, cursec)) { a_ends = 1; cursec = mm->sec; }
    srt = v_new ();
    if (names) {   /* the non-.L first, each kind by cmp */
      struct vec *a = v_new (), *b = v_new ();
      for (k = 0; k < names->n; k++) v_push (isL (names->v[k]) ? b : a, names->v[k]);
      v_sort_str (a); v_sort_str (b);
      for (k = 0; k < a->n; k++) v_push (srt, a->v[k]);
      for (k = 0; k < b->n; k++) v_push (srt, b->v[k]);
    }
    for (k = 0; k < srt->n; k++) {
      struct str *name = srt->v[k], *cm = s_of ("glibc-2.44 "), *ln = h_pv (a_line, name), *x;
      struct nd *c;
      s_app (cm, ln ? ln : src_s);
      c = nd1 (s_of ("comment"), nd_new (cm));
      if (isL (name)) {
        if (!fn) { x = s_of ("label "); s_app (x, name); s_cat (x, " outside a function"); fail_s (x); }
        x = s_dup (ffname (name)); s_cat (x, ":");
        block = nd_new (x);
        nd_add (fn, block);
      } else if (fn && !a_ends) {
        x = s_dup (name); s_cat (x, ":");
        block = nd2 (x, ndc ("asm"), c);
        nd_add (fn, block);
      } else {
        a64_finish ();
        x = s_dup (name); s_cat (x, ":");
        fn = nd2 (x, ndc ("asm"), c);
        h_setp (fnof, name, fn);
        v_push (fns, fn);
        block = 0;
      }
    }
    if (!fn) { struct str *x = s_of ("an instruction outside a function at "); s_app (x, s_num (mm->addr)); fail_s (x); }
    a64_emit (mm);
  }
  a64_finish ();
  if (then_v->n) {
    struct vec *tm = a64_readdump (then_v->n > 1 ? then_v->v[1] : s_of (""), 0);
    for (i = 0; i < tm->n; i++) {
      struct a64m *mm = tm->v[i];
      struct vec *names;
      if (s_is (mm->sec, ".text")) continue;
      names = h_pv (at_, key_of (mm->sec, 0));
      if (!names || !names->n) { struct str *x = s_of ("no function of "); s_app (x, mm->sec); s_cat (x, " for "); s_app (x, then_v->v[0]); fail_s (x); }
      fn = h_pv (fnof, names->v[0]); block = 0;
      a64_emit (mm);
    }
  }
  /* aliases, data, weak functions, weak words */
  {
    struct vec *k = h_sorted (a_alias);
    for (i = 0; i < k->n; i++) v_push (fns, alias_of (k->v[i], h_pv (a_alias, k->v[i])));
    for (i = 0; i < a_data->n; i++) v_push (fns, a_data->v[i]);
    k = h_sorted (weakref);
    for (i = 0; i < k->n; i++) if (und (k->v[i])) { struct str *x = s_dup (k->v[i]); s_cat (x, ":"); v_push (fns, nd_add (nd2 (x, ndc ("weak"), ndc ("function")), ndc ("void"))); }
    for (i = 0; i < weakgot->n; i++) v_push (fns, weakgot->v[i]);
  }
  /* a function that jumps to a block label of a function after it: one asm function */
  for (i = 0; i + 1 < fns->n; i++) {
    struct hash *tg;
    struct vec *tv;
    long j, last = -1, q;
    if (!isasm (fns->v[i])) continue;
    tv = v_new (); targets_of (fns->v[i], tv);
    tg = h_new ();
    for (j = 0; j < tv->n; j++) h_set (tg, tv->v[j], 1);
    for (j = i + 1; j < fns->n && isasm (fns->v[j]); j++) {
      struct vec *b = blocks_of (fns->v[j], v_new ());
      for (q = 0; q < b->n; q++) if (h_has (tg, b->v[q])) { last = j; break; }
    }
    if (last < 0) continue;
    {
      struct nd *into = fns->v[i];
      struct vec *nf = v_new ();
      for (j = i + 1; j <= last; j++) {
        struct nd *gg = fns->v[j], *own;
        struct vec *later = v_new ();
        long r;
        own = nd1 (gg->c, ndk (gg, 0));
        for (r = 1; r < ndn (gg); r++) {
          struct nd *x = ndk (gg, r);
          if (later->n || (m (x->c, ":$") && ndn (x) && !s_is (x->c, "comment"))) v_push (later, x); else nd_add (own, x);
        }
        nd_add (into, own);
        for (r = 0; r < later->n; r++) nd_add (into, later->v[r]);
      }
      for (j = 0; j <= i; j++) v_push (nf, fns->v[j]);
      for (j = last + 1; j < fns->n; j++) v_push (nf, fns->v[j]);
      fns = nf;
    }
    i--;
  }
  {
    struct vec *out = fns;
    if (!o_items) {
      struct str *pg = s_dup (page);
      struct nd *top;
      s_cat (pg, ":");
      top = nd_new (pg);
      for (i = 0; i < fns->n; i++) nd_add (top, fns->v[i]);
      out = v_new (); v_push (out, top);
    }
    o_s (write_txt (out));
  }
  o_flush ();
}
