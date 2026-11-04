/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cs_l.c (in cs.c): struct and union layout, as clang's Itanium builder
   for the generic (System V) ABI lays them out, in nbits */
static long long cs_up (long long v, long long a) { return a <= 1 ? v : (v + a - 1) / a * a; }
static long long cs_maxl (long long a, long long b) { return a > b ? a : b; }
static void cs_layout (struct cs_rec *r)
{
  struct cs_field *f;
  int un = r->k == TY_UNION;
  long long dsize = 0, sz = 0, unfilled = 0, algn = 8;
  if (r->laid) return;
  r->laid = 1;
  if (!r->complete) { r->bytes = 0; r->isal = 1; return; }
  f = r->first;
  while (f) {
    struct cs_ty *ft = f->t;
    int packed = r->packed || f->packed;
    long long tsize = cs_ty_size (ft) * 8, talign = cs_ty_align (ft) * 8;
    if (f->width >= 0) {
      long long fsize = f->width, falign = talign, off = un ? 0 : dsize - unfilled;
      if (packed && fsize != 0) falign = 1;
      if (f->algn) falign = cs_maxl (falign, f->algn * 8);
      if (fsize == 0 || ((off & (falign - 1)) + fsize > tsize)) off = cs_up (off, falign);
      else if (f->algn) off = cs_up (off, f->algn * 8);
      f->off = off;
      if (un) dsize = cs_maxl (dsize, cs_up (fsize, 8));
      else { long long ns = off + fsize; dsize = cs_up (ns, 8); unfilled = dsize - ns; }
      sz = cs_maxl (sz, dsize);
      /* (an unnamed one aligns nothing, but of width 0 on AAPCS: the record as its type, unwind-arm-common.h's long long int :0) */
      algn = cs_maxl (algn, f->name || (fsize == 0 && T->target >= 2) ? falign : 8);
    } else {
      long long falign = talign, off;
      unfilled = 0;
      if (packed) falign = 8;
      if (f->algn) falign = cs_maxl (falign, f->algn * 8);
      off = un ? 0 : cs_up (dsize, falign);
      f->off = off;
      if (un) dsize = cs_maxl (dsize, tsize); else dsize = off + tsize;
      sz = cs_maxl (sz, dsize);
      algn = cs_maxl (algn, falign);
    }
    f = f->nxt;
  }
  if (r->algn) algn = cs_maxl (algn, r->algn * 8);
  r->isal = algn / 8;
  r->bytes = cs_up (sz, algn) / 8;
}
/* the layout as clang's -fdump-record-layouts, as clangsema.pl keeps it */
static void cs_lay_fields (struct cs_rec *r, long long base, int depth)
{
  struct cs_field *f = r->first;
  while (f) {
    long long off = base + f->off;
    long ind = 0;
    if (T->tree) while (ind < depth) { cs_b_str (&T->out, "  "); ind++; }
    cs_b_str (&T->out, "at");
    cs_b_byte (&T->out, T->tree ? '\t' : ' ');
    if (f->width >= 0) {
      long long by = off / 8;
      cs_b_ll (&T->out, by);
      cs_b_byte (&T->out, ':');
      if (f->width == 0) cs_b_byte (&T->out, '-');
      else { cs_b_ll (&T->out, off - by * 8); cs_b_byte (&T->out, '-'); cs_b_ll (&T->out, off - by * 8 + f->width - 1); }
    } else cs_b_ll (&T->out, off / 8);
    cs_b_byte (&T->out, T->tree ? '\t' : ' ');
    cs_b_ll (&T->out, depth);
    cs_b_byte (&T->out, T->tree ? '\t' : ' ');
    if (f->name) cs_b_bytes (&T->out, f->name, f->nlen); else cs_b_byte (&T->out, '-');
    cs_b_byte (&T->out, '\n');
    if (f->width < 0 && cs_is_rec (f->t)) cs_lay_fields (cs_canon (f->t)->rec, off / 8 * 8, depth + 1);
    f = f->nxt;
  }
}
static void cs_lay_dump (struct cs_rec *r)
{
  cs_layout (r);
  if (!T->dump) return;
  cs_b_str (&T->out, cs_pick (T->tree, "layout\t0\t", "layout 0 "));
  if (!r->tag && r->td) { cs_b_str (&T->out, "td "); cs_b_bytes (&T->out, r->td, r->tdlen); }
  else {
    cs_b_str (&T->out, cs_pick (r->k == TY_STRUCT, "struct ", "union "));
    if (r->tag) cs_b_bytes (&T->out, r->tag, r->tlen); else cs_b_bytes (&T->out, r->loc, r->llen);
  }
  cs_b_byte (&T->out, '\n');
  cs_lay_fields (r, 0, 1);
  cs_b_str (&T->out, cs_pick (T->tree, "  size\t", "size "));
  cs_b_ll (&T->out, r->bytes);
  cs_b_str (&T->out, cs_pick (T->tree, "\talign\t", " align "));
  cs_b_ll (&T->out, r->isal);
  cs_b_byte (&T->out, '\n');
}
