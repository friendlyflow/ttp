/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* header.c: gen/Header.pm's license header of a source file, as s2ff
   uses it (license_nodes, unit_label): the leading comment of the file a
   .s is made of, its SPDX expression from its words. */

/* Perl's errno, which its die exits with (255 when it is 0): an open sets
   25 (the tty test of PerlIO), a read to the end 0, a failed open or -e
   its errno; s2ff's own steps keep it as the Perl's do */
static long perrno;
static void pdie (struct str *m) { die_status = perrno ? (int) perrno : 255; die_s (m); }
static void pdie_c (char *m) { pdie (s_of (m)); }
static struct str *p_slurp (char *f, char *who)   /* open or die, read to the end */
{
  struct str *t = read_all (f);
  if (!t) {
    long fd = s2_open (f);
    struct str *m = s_of (who);
    perrno = fd < 0 ? -fd : 2;
    s_cat (m, ": cannot open "); s_cat (m, f); s_cat (m, ": "); s_app (m, s_of (strerror_of (perrno))); s_cat (m, "\n");
    pdie (m);
  }
  perrno = 0;
  return t;
}

static char **envp_of;
static struct str *env_of (char *name)   /* $ENV{name}, or 0 */
{
  long i = 0, n = slen (name);
  while (envp_of && envp_of[i]) {
    char *e = envp_of[i];
    if (msame ((unsigned char *) e, (unsigned char *) name, n) && e[n] == '=') return s_of (e + n + 1);
    i++;
  }
  return 0;
}

/* File::Spec->rel2abs of a relative path: the current folder's, canonpath'd */
static struct str *rel2abs (struct str *p)
{
  struct str *x = getcwd_s ();
  s_cat (x, "/"); s_app (x, p);
  x = ssub (x, "/{2,}", "g", "/");
  x = ssub (x, "(?:/\\.)+(?:/|\\z)", "g", "/");
  x = ssub (x, "^/(?:\\.\\./)+", "", "/");
  if (s_is (x, "/..")) x = s_of ("/");
  if (x->n > 1 && x->p[x->n - 1] == '/' && x->p[x->n - 2] != '/') x = s_sub (x, 0, x->n - 1);
  return x;
}

/* A path resolved against a folder (0: the current one), without its .. parts. */
static struct str *libgcc_src;
static struct str *resolve (struct str *cwd, struct str *p)
{
  if (!(p->n && p->p[0] == '/')) p = cwd ? s_join (cwd, "/", p) : rel2abs (p);
  for (;;) {
    struct str *q = ssub (p, "/(?!\\.\\./)[^/]+/\\.\\./", "", "/");
    if (!subst_count) break;
    p = q;
  }
  p = ssub (p, "//+", "g", "/");
  if (libgcc_src && f_islink ((char *) p->p)) {
    struct str *a = abs_path ((char *) p->p);
    perrno = 2;
    if (a) p = a;
  }
  return p;
}

/* The source file of a .i or .s (its first two line markers), or 0 for a generated one (<stdin>) */
static struct str *source_of (struct str *file)
{
  struct str *t = read_all ((char *) file->p), *l1, *l2, *src, *cwd = 0;
  struct lines *ls;
  if (!t) { struct str *m = s_of ("header: cannot open "); long fd = s2_open ((char *) file->p); perrno = fd < 0 ? -fd : 2; s_app (m, file); s_cat (m, ": "); s_cat (m, strerror_of (perrno)); s_cat (m, "\n"); pdie (m); }
  ls = split_lines (t);
  perrno = 25;
  l1 = ls->n > 0 ? ls->l[0] : s_of ("");
  l2 = ls->n > 1 ? ls->l[1] : s_of ("");
  /* (a file of fewer than two lines: the second read is the end) */
  if (ls->n < 2) perrno = 0;
  if (!m (l1, "^# 0 \"(.*)\"$")) return 0;
  src = g (1);
  if (src->n && src->p[0] == '<') return 0;
  if (m (l2, "^# 1 \"(.*?)/*\"$")) cwd = g (1);
  return resolve (cwd, src);
}

/* The files of C or asm a .i or .s is made of, first its source, each once */
static struct vec *files_of (struct str *file)
{
  struct str *t = p_slurp ((char *) file->p, "header"), *cwd = 0;
  struct lines *ls = split_lines (t);
  struct vec *f = v_new ();
  struct hash *seen = h_new ();
  long i;
  if (ls->n > 1 && m (ls->l[1], "^# 1 \"(.*?)/*\"$")) cwd = g (1);
  for (i = 0; i < ls->n; i++) {
    struct str *p;
    if (i == 1) continue;
    if (!m (ls->l[i], "^# \\d+ \"([^\"<][^\"]*\\.[cS])\"")) continue;
    p = resolve (cwd, g (1));
    if (!h_has (seen, p)) { h_set (seen, p, 1); v_push (f, p); }
  }
  return f;
}

static int licensed (struct str *t) { return mf (t, "licen[cs]e|copyright|permission|redistribut", "i"); }

/* the header of source text: its leading comments up to the license, or 0 */
static struct str *leading_header (struct str *text)
{
  long first, at, end = -1, head = -1, lic = -1;
  if (!mf (text, "\\A(\\s*)/\\*", "s")) return 0;
  first = rc[3] - rc[2];
  at = first;
  for (;;) {
    struct str *rest = s_sub (text, at, text->n), *blk;
    long ws;
    if (!mf (rest, "\\A(/\\*.*?\\*/)", "s")) break;
    blk = g (1);
    end = at + blk->n;
    if (head < 0) head = end;
    if (licensed (blk)) lic = end; else if (lic >= 0) break;
    ws = 0;
    while (end + ws < text->n && is_space (text->p[end + ws])) ws++;
    if (!(end + ws + 2 <= text->n && text->p[end + ws] == '/' && text->p[end + ws + 1] == '*')) break;
    at = end + ws;
  }
  {
    long e = lic >= 0 ? lic : head;
    if (e < 0) e = 0;
    return s_sub (text, first, e > first ? e : first);
  }
}

/* The license one comment names, or 0 */
static struct str *spdx_one (struct str *h)
{
  struct str *t, *lic = 0;
  int later;
  t = ssub (h, "/\\*|\\*/", "g", " ");
  t = ssub (t, "^[ \\t]*\\*+", "mg", "");
  t = ssub (t, "\\s+", "g", " ");
  later = mf (t, "(?:any later version|or later version|either version \\S+ of the License, or)", "i");
  if (mf (t, "The Inner Net License, Version 2\\.00", "i")) lic = s_of ("Inner-Net-2.0");
  else if (mf (t, "GNU (?:Lesser|Library) General Public License", "i")) {
    struct str *v = 0;
    if (mf (t, "(?:Lesser|Library) General Public License.{0,80}?version (\\d(?:\\.\\d)?)", "i")) v = g (1);
    if (!v) v = mf (t, "Lesser", "i") ? s_of ("2.1") : s_of ("2");
    { long i; int dot = 0; for (i = 0; i < v->n; i++) if (v->p[i] == '.') dot = 1; if (!dot) s_cat (v, ".0"); }
    lic = s_of ("LGPL-"); s_app (lic, v); s_cat (lic, later ? "-or-later" : "-only");
  } else if (mf (t, "GNU General Public License", "i")) {
    struct str *v = 0;
    if (mf (t, "General Public License.{0,80}?version (\\d)", "i")) v = g (1);
    if (!v) v = s_of ("2");
    lic = s_of ("GPL-"); s_app (lic, v); s_cat (lic, ".0-"); s_cat (lic, later ? "or-later" : "only");
  } else if (mf (t, "Developed at SunPro", "i") && mf (t, "freely granted, provided that this notice is preserved", "i")) lic = s_of ("SunPro");
  else if (mf (t, "Permission to use, copy, modify, and(?:/or)? distribute this software for any purpose with or without fee is hereby granted", "i")) lic = s_of ("ISC");
  else if (mf (t, "Permission is hereby granted, free of charge, to any person obtaining a copy", "i")) lic = s_of ("MIT");
  else if (mf (t, "Redistribution and use in source and binary forms", "i")) {
    long n = 0, at = 0;
    struct rx *r = rx_get ("(?:^| )\\d\\. ", "");
    while (at <= t->n && rx_exec (r, t->p, t->n, at)) { n++; at = rc[1] > rc[0] ? rc[1] : rc[0] + 1; }
    if (mf (t, "advertising materials", "i")) lic = s_of ("BSD-4-Clause");
    else if (n >= 3 || mf (t, "endorse or promote", "i")) lic = s_of ("BSD-3-Clause");
    else lic = s_of ("BSD-2-Clause");
  }
  if (!lic) return 0;
  if (mf (t, "unlimited permission to link the compiled version of this file", "i")) { s_cat (lic, " WITH GCC-exception-2.0"); return lic; }
  if (mf (t, "GCC Runtime Library Exception, version 3\\.1", "i")) { s_cat (lic, " WITH GCC-exception-3.1"); return lic; }
  return lic;
}

/* The SPDX expression of a header, from its words, or 0 */
static struct str *spdx (struct str *h)
{
  struct vec *ids = v_new ();
  struct rx *r = rx_get ("/\\*.*?\\*/", "s");
  struct vec *blocks = v_new ();
  long at = 0, i, j;
  struct str *o;
  while (at <= h->n && rx_exec (r, h->p, h->n, at)) { v_push (blocks, s_sub (h, rc[0], rc[1])); at = rc[1] > rc[0] ? rc[1] : rc[0] + 1; }
  for (i = 0; i < blocks->n; i++) {
    struct str *b = blocks->v[i], *id;
    int dup = 0;
    if (!(licensed (b) && mf (b, "licen[cs]e|permission|permitted|redistribut|granted", "i"))) continue;
    if (mf (b, "special exception", "i") && mf (b, "Bison parser skeleton", "i") && ids->n) { s_cat (ids->v[ids->n - 1], " WITH Bison-exception-2.2"); continue; }
    id = spdx_one (b);
    if (!id) return 0;
    for (j = 0; j < ids->n; j++) if (s_eq (ids->v[j], id)) dup = 1;
    if (!dup) v_push (ids, id);
  }
  if (!ids->n) return 0;
  o = s_dup (ids->v[0]);
  for (i = 1; i < ids->n; i++) { s_cat (o, " AND "); s_app (o, ids->v[i]); }
  return o;
}

/* The header's text again, from its lines in ff. */
static struct str *header_text (struct vec *l)
{
  struct str *o;
  long i;
  if (m (l->v[0], "^/\\*")) {
    o = s_dup (l->v[0]);
    for (i = 1; i < l->n; i++) { s_cat (o, "\n"); s_app (o, l->v[i]); }
    return o;
  }
  o = s_of ("/* "); s_app (o, l->v[0]);
  for (i = 1; i < l->n; i++) { struct str *c = l->v[i]; s_cat (o, "\n"); if (c->n) { s_cat (o, "   "); s_app (o, c); } }
  s_cat (o, "  */");
  return o;
}

/* The lines a header is written as in ff */
static struct vec *notice_lines (struct str *h)
{
  struct vec *l = ssplit ("\\n", h, 1);
  if (l->n && m (l->v[0], "^/\\* (\\S.*)$") && m (l->v[l->n - 1], "\\S  \\*/$")) {
    struct vec *c = v_new ();
    long i;
    int ok = 1;
    for (i = 0; i < l->n; i++) v_push (c, l->v[i]);
    c->v[0] = ssub (c->v[0], "^/\\* ", "", "");
    c->v[c->n - 1] = ssub (c->v[c->n - 1], "  \\*/$", "", "");
    for (i = 1; i < c->n; i++) {
      struct str *x = c->v[i];
      if (x->n == 0) continue;
      if (m (x, "^   (\\S.*)$")) c->v[i] = g (1); else ok = 0;
    }
    for (i = 0; ok && i < c->n; i++) if (m (c->v[i], "\\*/") || m (c->v[i], "\\s$")) ok = 0;
    if (ok && s_eq (header_text (c), h)) return c;
  }
  return l;
}

#define GENERATED "generated from syscalls.list; glibc-2.44 COPYING.LIB"
#define NOHEADER "no header of its own; glibc-2.44 COPYING.LIB"
#define NOHEADER_GCC "no header of its own; gcc-16.2.0 COPYING3 and COPYING.RUNTIME"
#define NOLICENSE_GCC "the file names no license of its own: the tree's, gcc-16.2.0 COPYING3 and COPYING.RUNTIME"
static struct vec *nolicense_lines (struct str *h)
{
  struct vec *l = notice_lines (h);
  if (l->n == 1 && m (l->v[0], "^/\\*\\s*(.*?)\\s*\\*/$")) { l = v_new (); v_push (l, g (1)); }
  v_push (l, s_of (NOLICENSE_GCC));
  return l;
}

/* the source trees: glibc's (GLIBC_SRC) and gcc's (LIBGCC_SRC) */
struct root { char *var, *name, *spdx, *none; };
static struct root roots[2];
static struct root *root_of (struct str *p, struct str **path)   /* a file's tree and its path in it */
{
  long i;
  for (i = 0; i < 2; i++) {
    struct str *s = env_of (roots[i].var), *pat;
    if (!s) continue;
    s = ssub (s, "/+$", "", "");
    pat = s_of ("^"); s_app (pat, rx_quote (s)); s_cat (pat, "/(.*)$");
    if (mdyn (p, pat, "")) { *path = g (1); return &roots[i]; }
  }
  *path = p;
  return &roots[0];
}
static struct str *shown_path (struct str *p) { struct str *x; root_of (p, &x); return x; }

static struct hash *labels;
static struct str *unit_label (struct str *i)   /* the name of the tree a .i or .s is made of */
{
  struct str *s = 0, *x;
  if (h_has (labels, i)) return h_pv (labels, i);
  if (f_exists ((char *) i->p)) s = source_of (i); else perrno = 2;
  x = s_of (s ? root_of (s, &s)->name : roots[0].name);
  h_setp (labels, i, x);
  return x;
}

/* Perl's utf8::decode: whether the bytes are UTF-8 */
static int utf8_ok (struct str *s)
{
  long i = 0;
  while (i < s->n) {
    int c = s->p[i], k, j;
    long v;
    if (c < 0x80) { i++; continue; }
    if (c >= 0xc2 && c < 0xe0) { k = 1; v = c & 0x1f; }
    else if (c >= 0xe0 && c < 0xf0) { k = 2; v = c & 0x0f; }
    else if (c >= 0xf0 && c < 0xf8) { k = 3; v = c & 0x07; }
    else return 0;
    for (j = 1; j <= k; j++) { if (i + j >= s->n || (s->p[i + j] & 0xc0) != 0x80) return 0; v = v << 6 | (s->p[i + j] & 0x3f); }
    if ((k == 2 && v < 0x800) || (k == 3 && v < 0x10000)) return 0;
    i += k + 1;
  }
  return 1;
}
static struct vec *lines_ok (struct str *f, struct vec *l)
{
  long i;
  for (i = 0; i < l->n; i++) {
    struct str *x = l->v[i], *msg;
    if (x->n > 255) { msg = s_of ("header: "); s_app (msg, f); s_cat (msg, ": a line of "); s_app (msg, s_num (x->n)); s_cat (msg, " bytes, more than a node holds (255)\n"); pdie (msg); }
    if (!utf8_ok (x)) { msg = s_of ("header: "); s_app (msg, f); s_cat (msg, ": a line that is not UTF-8\n"); pdie (msg); }
  }
  return l;
}

struct hdr { struct str *file, *name, *spdx; struct vec *lines; };
static struct hdr *hdr_new (struct str *file, char *name, struct str *x, struct vec *lines) { struct hdr *h = alloc (sizeof (struct hdr)); h->file = file; h->name = s_of (name); h->spdx = x; h->lines = lines; return h; }
static struct vec *vec1 (char *c) { struct vec *v = v_new (); v_push (v, s_of (c)); return v; }
static struct hdr *header_of (struct str *ifile)
{
  struct str *src = source_of (ifile), *ff = 0, *fh = 0;
  struct vec *files = files_of (ifile);
  struct root *r;
  long i;
  for (i = 0; i < files->n; i++) {
    struct str *f = files->v[i], *h, *x, *path;
    h = leading_header (p_slurp ((char *) f->p, "header"));
    if (!h) continue;
    x = spdx (h);
    if (!x) {
      r = root_of (f, &path);
      if (r == &roots[1] && !mf (h, "licen[cs]e|permission|redistribut", "i") && mf (h, "copyright", "i"))
        return hdr_new (shown_path (f), r->name, s_of (r->spdx), lines_ok (f, nolicense_lines (h)));
      if (licensed (h)) { struct str *msg = s_of ("header: "); s_app (msg, f); s_cat (msg, ": its header names a license this cannot name (add it to spdx in gen/Header.pm)\n"); pdie (msg); }
      if (!ff && src && s_eq (f, src)) { ff = f; fh = h; }
      continue;
    }
    r = root_of (f, &path);
    return hdr_new (shown_path (f), r->name, x, lines_ok (f, notice_lines (h)));
  }
  if (!src) return hdr_new (s_of ("<stdin>"), roots[0].name, s_of ("LGPL-2.1-or-later"), vec1 (GENERATED));
  {
    struct str *path;
    r = root_of (src, &path);
    if (ff) return hdr_new (shown_path (ff), r->name, s_of (r->spdx), lines_ok (ff, notice_lines (fh)));
    return hdr_new (shown_path (src), r->name, s_of (r->spdx), vec1 (r->none));
  }
}

/* The licenses of the files a page is made of, as ff nodes */
static struct vec *license_nodes (struct vec *ifiles)
{
  struct hash *h = h_new ();
  struct vec *o = v_new (), *keys;
  long i, j;
  for (i = 0; i < ifiles->n; i++) {
    struct hdr *x = header_of (ifiles->v[i]);
    if (!h_has (h, x->file)) h_setp (h, x->file, x);
  }
  keys = h_sorted (h);
  for (i = 0; i < keys->n; i++) {
    struct hdr *x = h_pv (h, keys->v[i]);
    struct nd *lic = ndc ("license");
    v_push (o, nd1 (s_of ("comment"), nd_new (s_join (x->name, " ", x->file))));
    nd_add (lic, nd_new (x->spdx));
    for (j = 0; j < x->lines->n; j++) nd_add (lic, nd_new (x->lines->v[j]));
    v_push (o, lic);
  }
  return o;
}

static void header_init (void)
{
  roots[0].var = "GLIBC_SRC"; roots[0].name = "glibc-2.44"; roots[0].spdx = "LGPL-2.1-or-later"; roots[0].none = NOHEADER;
  roots[1].var = "LIBGCC_SRC"; roots[1].name = "gcc-16.2.0"; roots[1].spdx = "GPL-3.0-or-later WITH GCC-exception-3.1"; roots[1].none = NOHEADER_GCC;
  labels = h_new ();
  libgcc_src = env_of ("LIBGCC_SRC");
}
