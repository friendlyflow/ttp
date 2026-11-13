/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cl_h.c (in cs.c): what the head of a unit's source says of its terms, as gen/Header.pm */
struct cl_header { char *file, *name, *spdx; char **lines; long nlines; };
static int cl_lower (int c) { if (c >= 'A' && c <= 'Z') return c + 32; return c; }
static long cl_ifind (char *h, char *needle, long from)
{
  long i = from;
  while (h[i]) {
    long j = 0;
    while (needle[j] && h[i + j] && cl_lower (h[i + j]) == cl_lower (needle[j])) j++;
    if (!needle[j]) return i;
    i++;
  }
  return 0 - 1;
}
static int cl_ihas (char *h, char *needle) { return cl_ifind (h, needle, 0) >= 0; }
static int cl_licensed (char *b) { return cl_ihas (b, "license") || cl_ihas (b, "licence") || cl_ihas (b, "copyright") || cl_ihas (b, "permission") || cl_ihas (b, "redistribut"); }
/* a version after a phrase: /PHRASE.{0,80}?version (\d(?:\.\d)?)/i, digits how many */
static char *cl_version_after (char *t, char *phrase, int dotted)
{
  long at = 0;
  for (;;) {
    long off = 0, m;
    at = cl_ifind (t, phrase, at);
    if (at < 0) return 0;
    m = at + cstrlen (phrase);
    while (off <= 80 && t[m + off]) {
      char *p = t + m + off;
      long j = 0;
      static char *vw = "version ";
      while (vw[j] && cl_lower (p[j]) == vw[j]) j++;
      if (!vw[j] && cl_digit (p[8])) {
        if (dotted && p[9] == '.' && cl_digit (p[10])) return cl_copy ((unsigned char *) p + 8, 3);
        return cl_copy ((unsigned char *) p + 8, 1);
      }
      off++;
    }
    at = at + 1;
  }
}
static char *cl_spdx_one (char *h)
{
  struct cs_buf b;
  long i = 0;
  char *t, *lic = 0;
  int later;
  /* without the comment marks: the /star and star/, the stars that start a line; spaces as one */
  cs_b_init (&b);
  while (h[i]) {
    if ((h[i] == '/' && h[i + 1] == '*') || (h[i] == '*' && h[i + 1] == '/')) { cs_b_byte (&b, ' '); i += 2; continue; }
    if (h[i] == '\n' || i == 0) {
      long j = h[i] == '\n' ? i + 1 : i;
      long s = j;
      while (h[s] == ' ' || h[s] == '\t') s++;
      if (h[s] == '*' && h[s + 1] != '/') {
        if (h[i] == '\n') cs_b_byte (&b, ' ');
        while (h[s] == '*') s++;
        i = s;
        continue;
      }
    }
    cs_b_byte (&b, h[i]);
    i++;
  }
  t = cl_copy (b.p, b.n);
  cs_b_init (&b);
  i = 0;
  while (t[i]) {
    if (t[i] == ' ' || t[i] == '\t' || t[i] == '\n' || t[i] == '\r' || t[i] == '\f') {
      while (t[i] == ' ' || t[i] == '\t' || t[i] == '\n' || t[i] == '\r' || t[i] == '\f') i++;
      cs_b_byte (&b, ' ');
      continue;
    }
    cs_b_byte (&b, t[i]);
    i++;
  }
  t = cl_copy (b.p, b.n);
  later = cl_ihas (t, "any later version") || cl_ihas (t, "or later version");
  if (!later) {
    long a = cl_ifind (t, "either version ", 0);
    if (a >= 0) {
      long e = a + 15;
      while (t[e] && t[e] != ' ') e++;
      if (cl_starts (t + e, " of the License, or")) later = 1;
    }
  }
  if (cl_ihas (t, "The Inner Net License, Version 2.00")) lic = "Inner-Net-2.0";
  /* (BLAKE2's reference code, coreutils' src/blake2: any of three, at the user's option) */
  else if (cl_ihas (t, "under the terms of the CC0, the OpenSSL Licence, or the Apache Public License 2.0, at your option")) lic = "(CC0-1.0 OR OpenSSL OR Apache-2.0)";
  else if (cl_ihas (t, "GNU Lesser General Public License") || cl_ihas (t, "GNU Library General Public License")) {
    char *v = cl_version_after (t, "Lesser General Public License", 1);
    char *w = cl_version_after (t, "Library General Public License", 1);
    long a = cl_ifind (t, "Lesser General Public License", 0), c = cl_ifind (t, "Library General Public License", 0);
    if (w && (!v || (c >= 0 && (a < 0 || c < a)))) v = w;
    if (!v) { if (cl_ihas (t, "Lesser")) v = "2.1"; else v = "2"; }
    if (!v[1]) v = cl_cat (v, ".0");
    lic = cl_cat3 ("LGPL-", v, cs_pick (later, "-or-later", "-only"));
  } else if (cl_ihas (t, "GNU General Public License")) {
    char *v = cl_version_after (t, "General Public License", 0);
    if (!v) v = "2";
    lic = cl_cat3 ("GPL-", v, cs_pick (later, ".0-or-later", ".0-only"));
  } else if (cl_ihas (t, "Developed at SunPro") && cl_ihas (t, "freely granted, provided that this notice is preserved")) lic = "SunPro";
  else if (cl_ihas (t, "Permission to use, copy, modify, and distribute this software for any purpose with or without fee is hereby granted") || cl_ihas (t, "Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted")) lic = "ISC";
  else if (cl_ihas (t, "Permission is hereby granted, free of charge, to any person obtaining a copy")) lic = "MIT";
  else if (cl_ihas (t, "Redistribution and use in source and binary forms")) {
    long count = 0;
    i = 0;
    while (t[i]) { if ((i == 0 || t[i - 1] == ' ') && cl_digit (t[i]) && t[i + 1] == '.' && t[i + 2] == ' ') count++; i++; }
    if (cl_ihas (t, "advertising materials")) lic = "BSD-4-Clause";
    else if (count >= 3 || cl_ihas (t, "endorse or promote")) lic = "BSD-3-Clause";
    else lic = "BSD-2-Clause";
  }
  if (!lic) return 0;
  if (cl_ihas (t, "unlimited permission to link the compiled version of this file")) return cl_cat (lic, " WITH GCC-exception-2.0");
  if (cl_ihas (t, "GCC Runtime Library Exception, version 3.1")) return cl_cat (lic, " WITH GCC-exception-3.1");
  return lic;
}
static char *cl_spdx (char *h)
{
  long at = 0;
  struct cs_buf b;
  int any = 0;
  char *ids[16];
  long nids = 0, i = 0;
  for (;;) {
    long s = at, e;
    char *blk;
    while (h[s] && !(h[s] == '/' && h[s + 1] == '*')) s++;
    if (!h[s]) break;
    e = s + 2;
    while (h[e] && !(h[e] == '*' && h[e + 1] == '/')) e++;
    if (!h[e]) break;
    blk = cl_copy ((unsigned char *) h + s, e + 2 - s);
    at = e + 2;
    if (cl_licensed (blk) && (cl_ihas (blk, "license") || cl_ihas (blk, "licence") || cl_ihas (blk, "permission") || cl_ihas (blk, "permitted") || cl_ihas (blk, "redistribut") || cl_ihas (blk, "granted"))) {
      char *id;
      long k = 0;
      int dup = 0;
      if (cl_ihas (blk, "special exception") && cl_ihas (blk, "Bison parser skeleton") && nids) { ids[nids - 1] = cl_cat (ids[nids - 1], " WITH Bison-exception-2.2"); continue; }
      id = cl_spdx_one (blk);
      /* (a note on a license named before it: gawk's random.c, on BSD's advertising clause, rescinded) */
      if (!id && nids && cl_ihas (blk, "advertising clause")) continue;
      if (!id) return 0;
      while (k < nids) { if (cl_eq (ids[k], id)) dup = 1; k++; }
      if (!dup && nids < 16) { ids[nids] = id; nids++; }
    }
  }
  if (!nids) return 0;
  cs_b_init (&b);
  while (i < nids) { if (any) cs_b_str (&b, " AND "); cs_b_str (&b, ids[i]); any = 1; i++; }
  return cl_copy (b.p, b.n);
}
static int cl_space (int c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f'; }
static char *cl_leading_header (char *t)
{
  long first = 0, at, end = 0, head = 0 - 1, lic = 0 - 1;
  while (cl_space (t[first])) first++;
  if (!(t[first] == '/' && t[first + 1] == '*')) return 0;
  at = first;
  while (t[at] == '/' && t[at + 1] == '*') {
    long e = at + 2, ws;
    char *blk;
    while (t[e] && !(t[e] == '*' && t[e + 1] == '/')) e++;
    if (!t[e]) break;
    end = e + 2;
    blk = cl_copy ((unsigned char *) t + at, end - at);
    if (head < 0) head = end;
    if (cl_licensed (blk)) lic = end;
    else if (lic >= 0) break;
    ws = end;
    while (cl_space (t[ws])) ws++;
    if (!(t[ws] == '/' && t[ws + 1] == '*')) break;
    at = ws;
  }
  {
    long stop = lic >= 0 ? lic : head;
    if (stop < 0) return "";
    return cl_copy ((unsigned char *) t + first, stop - first);
  }
}
static char **cl_split_nl (char *h, long *count)
{
  long n = 1, i = 0, k = 0, b = 0;
  char **v;
  while (h[i]) { if (h[i] == '\n') n++; i++; }
  v = alloc ((n + 1) * sizeof (char *));
  i = 0;
  for (;;) {
    if (h[i] == '\n' || !h[i]) {
      v[k] = cl_copy ((unsigned char *) h + b, i - b);
      k++;
      if (!h[i]) break;
      b = i + 1;
    }
    i++;
  }
  *count = k;
  return v;
}
static char **cl_notice_lines (char *h, long *count)
{
  long n, i = 1;
  char **l = cl_split_nl (h, &n), **c;
  int ok = 1;
  long ln0 = cstrlen (l[0]), lnl = cstrlen (l[n - 1]);
  *count = n;
  if (!(ln0 > 3 && l[0][0] == '/' && l[0][1] == '*' && l[0][2] == ' ' && !cl_space (l[0][3]))) return l;
  if (!(lnl >= 5 && cl_ends (l[n - 1], "  */") && !cl_space (l[n - 1][lnl - 5]))) return l;
  c = alloc ((n + 1) * sizeof (char *));
  while (i < n) { c[i] = l[i]; i++; }
  c[0] = l[0] + 3;
  c[n - 1] = cl_copy ((unsigned char *) c[n - 1], cstrlen (c[n - 1]) - 4);
  if (n == 1) c[0] = cl_copy ((unsigned char *) l[0] + 3, ln0 - 3 - 4);
  i = 1;
  while (i < n) {
    if (c[i][0]) {
      if (c[i][0] == ' ' && c[i][1] == ' ' && c[i][2] == ' ' && c[i][3] && !cl_space (c[i][3])) c[i] = c[i] + 3;
      else ok = 0;
    }
    i++;
  }
  i = 0;
  while (i < n && ok) {
    long m = cstrlen (c[i]);
    long q = 0;
    while (q + 1 < m) { if (c[i][q] == '*' && c[i][q + 1] == '/') ok = 0; q++; }
    if (m && cl_space (c[i][m - 1])) ok = 0;
    i++;
  }
  if (ok && c[0][0] == '/' && c[0][1] == '*') ok = 0;
  if (ok) return c;
  return l;
}
/* a path against a folder, without its .. parts */
static char *cl_resolve (char *cdir, char *p)
{
  char *r = p;
  struct cs_buf b;
  long i;
  /* (without a folder of its own, gcc -E of a program: where the tool runs, as
     c2ff.pl's File::Spec->rel2abs; a round trip's unit of a program, progrt) */
  if (p[0] != '/' && cdir) r = cl_cat3 (cdir, "/", p);
  else if (p[0] != '/') {
    unsigned char *wd = alloc (4097);
    long m = cp_readlink ("/proc/self/cwd", wd, 4096);
    if (m > 0) r = cl_cat3 (cl_copy (wd, m), "/", p);
  }
  for (;;) {
    /* /x/../ -> /, x not .. */
    long at = 0, done = 1;
    while (r[at]) {
      if (r[at] == '/') {
        long e = at + 1;
        while (r[e] && r[e] != '/') e++;
        if (e > at + 1 && r[e] == '/' && r[e + 1] == '.' && r[e + 2] == '.' && r[e + 3] == '/' && !(r[at + 1] == '.' && r[at + 2] == '.' && r[at + 3] == '/')) {
          r = cl_cat (cl_copy ((unsigned char *) r, at + 1), r + e + 4);
          done = 0;
          break;
        }
      }
      at++;
    }
    if (done) break;
  }
  cs_b_init (&b);
  i = 0;
  while (r[i]) {
    if (r[i] == '/' && i && r[i - 1] == '/') { i++; continue; }
    cs_b_byte (&b, r[i]);
    i++;
  }
  r = cl_copy (b.p, b.n);
  /* (a link in libgcc's build to its source: enable-execute-stack.c) */
  if (C->libgcc_src) {
    unsigned char *lk = alloc (4097);
    long m = cp_readlink (r, lk, 4096);
    if (m > 0) {
      long d = cstrlen (r);
      if (lk[0] == '/') return cl_resolve (cdir, cl_copy (lk, m));
      while (d > 0 && r[d - 1] != '/') d--;
      return cl_resolve (cdir, cl_cat (cl_copy ((unsigned char *) r, d), cl_copy (lk, m)));
    }
  }
  return r;
}
/* the first line's and second line's markers */
static char *cl_marker_name (unsigned char *s, long n, long *next_at, char *num)
{
  /* a line # num "name": its name; *next_at the next line */
  long e = 0, b;
  long m = cstrlen (num);
  char *r = 0;
  while (e < n && s[e] != '\n') e++;
  *next_at = e + 1;
  if (e >= 4 + m && s[0] == '#' && s[1] == ' ' && same (s + 2, m, num) && s[2 + m] == ' ' && s[3 + m] == '"' && s[e - 1] == '"') {
    b = 4 + m;
    r = cl_copy (s + b, e - 1 - b);
  }
  return r;
}
static int cl_has_slash (char *p) { while (*p) { if (*p == '/') return 1; p++; } return 0; }
static char *cl_base (char *p) { char *b = p; while (*p) { if (*p == '/') b = p + 1; p++; } return b; }
static char *cl_source_of (char **cdirp)
{
  unsigned char *s = T->src + T->skip;
  long n = T->srcn - T->skip, nx, nx2;
  char *src = cl_marker_name (s, n, &nx, "0"), *cdir;
  *cdirp = 0;
  if (nx < n) {
    cdir = cl_marker_name (s + nx, n - nx, &nx2, "1");
    if (cdir) {
      long m = cstrlen (cdir);
      while (m > 0 && cdir[m - 1] == '/') m--;
      cdir[m] = 0;
      *cdirp = cdir;
    }
  }
  if (!src || src[0] == '<') return 0;
  return cl_resolve (*cdirp, src);
}
/* the root of a path: its tree's name */
static int cl_is_gcc_file (char *p)
{
  if (!C->libgcc_src || (C->glibc_src && cl_starts (p, cl_cat (C->glibc_src, "/")))) return 0;
  return cl_starts (p, cl_cat (C->libgcc_src, "/"));
}
static char *cl_shown (char *p)
{
  if (C->glibc_src && cl_starts (p, cl_cat (C->glibc_src, "/"))) return p + cstrlen (C->glibc_src) + 1;
  if (C->libgcc_src && cl_starts (p, cl_cat (C->libgcc_src, "/"))) return p + cstrlen (C->libgcc_src) + 1;
  if (C->tree_build && cl_starts (p, cl_cat (C->tree_build, "/"))) return cl_cat ("build/", p + cstrlen (C->tree_build) + 1);
  return p;
}
static char *cl_glibc_tree (void) { return cs_pick (C->tree != 0, C->tree, "glibc-2.44"); }
static char *cl_tree_name (char *p) { return cs_pick (cl_is_gcc_file (p), "gcc-16.2.0", cl_glibc_tree ()); }
static char *cl_unit_label (void)
{
  char *cdir, *s = cl_source_of (&cdir);
  if (s) return cl_tree_name (s);
  return cl_glibc_tree ();
}
static char *cl_file_text (char *f)
{
  long n;
  unsigned char *p = cp_file (f, &n);
  return cl_copy (p, n);
}
static void cl_lines_ok (char *f, char **l, long n)
{
  long i = 0;
  while (i < n) {
    if (cstrlen (l[i]) > 255) cl_fail ("a header's line of more than a node holds in", f);
    if (!cl_utf8_ok ((unsigned char *) l[i], cstrlen (l[i]))) cl_fail ("a header's line that is not UTF-8 in", f);
    i++;
  }
}
static struct cl_header *cl_header_of (void)
{
  struct cl_header *x = alloc (sizeof (struct cl_header));
  char *cdir, *src = cl_source_of (&cdir), *firstf = 0, *firsth = 0;
  struct cl_map seen;
  unsigned char *s = T->src + T->skip;
  long n = T->srcn - T->skip, at = 0, lineno = 0;
  seen.tab = 0;
  seen.count = 0;
  while (at < n) {
    long e = at;
    while (e < n && s[e] != '\n') e++;
    /* /^# \d+ "([^"<][^"]*\.[cS])"/, not the second line */
    if (lineno != 1 && s[at] == '#' && at + 2 < n && s[at + 1] == ' ' && cl_digit (s[at + 2])) {
      long q = at + 2;
      while (q < e && cl_digit (s[q])) q++;
      if (q + 2 < e && s[q] == ' ' && s[q + 1] == '"' && s[q + 2] != '"' && s[q + 2] != '<') {
        long b = q + 2, c = b;
        while (c < e && s[c] != '"') c++;
        if (c < e && c - 2 >= b && s[c - 2] == '.' && (s[c - 1] == 'c' || s[c - 1] == 'S')) {
          char *f = cl_copy (s + b, c - b);
          /* (a #line of the source's own, a generated file's: flex's scan.c, bison's bc.c, a bare name, is the source) */
          if (src && !cl_has_slash (f) && cl_eq (f, cl_base (src))) f = src;
          else f = cl_resolve (cdir, f);
          if (!cl_val (&seen, f)) {
            char *h;
            cl_set (&seen, f);
            h = cl_leading_header (cl_file_text (f));
            if (h) {
              char *id = cl_spdx (h);
              if (id) {
                x->file = cl_shown (f);
                x->name = cl_tree_name (f);
                x->spdx = id;
                x->lines = cl_notice_lines (h, &x->nlines);
                cl_lines_ok (f, x->lines, x->nlines);
                return x;
              }
              if (cl_is_gcc_file (f) && !(cl_ihas (h, "license") || cl_ihas (h, "licence") || cl_ihas (h, "permission") || cl_ihas (h, "redistribut")) && cl_ihas (h, "copyright")) {
                /* (a file of gcc's whose header is its copyright alone: the tree's terms, its copyright kept) */
                long nl, q = 0;
                char **l = cl_notice_lines (h, &nl);
                char **w = alloc ((nl + 2) * sizeof (char *));
                while (q < nl) { w[q] = l[q]; q++; }
                if (nl == 1 && cl_starts (l[0], "/*") && cl_ends (l[0], "*/")) {
                  char *in = cl_copy ((unsigned char *) l[0] + 2, cstrlen (l[0]) - 4);
                  long b = 0, e = cstrlen (in);
                  while (cl_space (in[b])) b++;
                  while (e > b && cl_space (in[e - 1])) e--;
                  w[0] = cl_copy ((unsigned char *) in + b, e - b);
                }
                w[nl] = cl_cat ("the file names no ", "license of its own: the tree's, gcc-16.2.0 COPYING3 and COPYING.RUNTIME");
                x->file = cl_shown (f);
                x->name = "gcc-16.2.0";
                x->spdx = "GPL-3.0-or-later WITH GCC-exception-3.1";
                x->lines = w;
                x->nlines = nl + 1;
                cl_lines_ok (f, w, nl + 1);
                return x;
              }
              if (cl_licensed (h)) cl_fail ("a header that names a license this cannot name", f);
              if (src && cl_eq (f, src) && !firstf) { firstf = f; firsth = h; }
            }
          }
        }
      }
    }
    at = e + 1;
    lineno++;
  }
  x->name = cl_glibc_tree ();
  x->spdx = cs_pick (C->tree != 0, C->tree_spdx, "LGPL-2.1-or-later");
  if (!src) {
    x->file = "<stdin>";
    x->lines = alloc (2 * sizeof (char *));
    x->lines[0] = "generated from syscalls.list; glibc-2.44 COPYING.LIB";
    x->nlines = 1;
    return x;
  }
  x->name = cl_tree_name (src);
  if (cl_is_gcc_file (src)) x->spdx = "GPL-3.0-or-later WITH GCC-exception-3.1";
  if (firstf) {
    x->file = cl_shown (firstf);
    x->lines = cl_notice_lines (firsth, &x->nlines);
    cl_lines_ok (firstf, x->lines, x->nlines);
    return x;
  }
  x->file = cl_shown (src);
  x->lines = alloc (2 * sizeof (char *));
  x->lines[0] = cs_pick (cl_is_gcc_file (src), "no header of its own; gcc-16.2.0 COPYING3 and COPYING.RUNTIME", "no header of its own; glibc-2.44 COPYING.LIB");
  if (C->tree && !cl_is_gcc_file (src)) x->lines[0] = cl_cat3 ("no header of its own; ", C->tree, cl_cat (" ", C->tree_copying));
  x->nlines = 1;
  return x;
}
static struct node *cl_license_node (struct cl_header *x)
{
  struct node *lic = cl_n ("license");
  long i = 0;
  nd_add (lic, cl_n (x->spdx));
  while (i < x->nlines) { nd_add (lic, cl_n (x->lines[i])); i++; }
  return lic;
}
