/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* headers.c: dev source of tools/headers.ff, gen/headers.pl in ff: the
   round trip of the files' headers. Each file's header as ff2c writes it
   back from a tree (its comment "ff2c: the header of <file>" and the
   header after it) is the header of that file in glibc's source
   (GLIBC_SRC), byte for byte; and every unit a written function comes
   from (names.txt) has the header of its file there. The same output,
   messages and status as the Perl, which stays as a cross-check (make
   headers-crosscheck).

     headers out.c names.txt

   On s2ff's lib.c (strings, Perl's regular expressions, hashes, files,
   Perl's die) and header.c (gen/Header.pm), copied from tools/dev/s2ff. */

#include "lib.c"
#include "header.c"

/* headers.pl's own slurp: the whole file, else its message and Perl's die */
static struct str *h_slurp (char *f)
{
  return p_slurp (f, "headers");
}

/* Header.pm's real_path: a file as a page names it, back to its source:
   glibc's, else gcc's where it has that file */
static struct str *real_path (struct str *p)
{
  struct str *g, *s = env_of ("GLIBC_SRC"), *l;
  if (p->n && p->p[0] == '/') return p;
  if (!s) { perrno = 0; pdie_c ("header: GLIBC_SRC is not set: run this in `nix develop`\n"); }
  g = s_join (s, "/", p);
  l = env_of ("LIBGCC_SRC");
  if (!f_exists ((char *) g->p)) {
    perrno = 2;
    if (l) {
      struct str *x = s_join (l, "/", p);
      if (f_exists ((char *) x->p)) return x;
    }
  }
  return g;
}

/* split /\n/ or /\t/ of s, as ssplit's, a byte at a time (ssplit tries the
   pattern at every byte of the 2 MB of out.c) */
static struct vec *split_c (struct str *s, int c, int keep)
{
  struct vec *v = v_new ();
  long i, last = 0;
  if (s->n == 0) return v;
  for (i = 0; i < s->n; i++) if (s->p[i] == c) { v_push (v, s_sub (s, last, i)); last = i + 1; }
  v_push (v, s_sub (s, last, s->n));
  if (!keep) while (v->n && ((struct str *) v->v[v->n - 1])->n == 0) v->n--;
  return v;
}

static struct str *text1 (char *c) { return header_text (vec1 (c)); }

/* A unit's .i read once into a buffer of its own, used again for the next
   (header.c's source_of and files_of each read it whole and copy every
   line: some 70 MB of .i for a milestone, which a heap that never frees
   would keep), its lines looked at where they are */
static unsigned char *ibuf;
static long iroom, ilen;
static void i_read (struct str *file)
{
  long fd = s2_open ((char *) file->p);
  if (fd < 0) {
    struct str *m = s_of ("header: cannot open ");
    perrno = -fd;
    s_app (m, file); s_cat (m, ": "); s_cat (m, strerror_of (perrno)); s_cat (m, "\n");
    pdie (m);
  }
  ilen = 0;
  for (;;) {
    long r;
    if (ilen + 65536 + 1 > iroom) {
      long nr = iroom ? iroom * 2 : 1 << 22;
      unsigned char *x = alloc (nr);
      mcopy (x, ibuf, ilen);
      ibuf = x; iroom = nr;
    }
    r = s2_read (fd, ibuf + ilen, 65536);
    if (r <= 0) break;
    ilen += r;
  }
  s2_close (fd);
  ibuf[ilen] = 0;
}
/* the line of the buffer at a, with its \n, as a string that is no copy */
static long i_line (long a, struct str *l)
{
  unsigned char *p = ibuf;
  long e = a, n = ilen;
  while (e < n && p[e] != '\n') e++;
  if (e < n) e++;
  l->p = p + a; l->n = e - a; l->room = 0;
  return e;
}
/* whether a line can be a marker of a .c or .S file, # N "x.c": what
   files_of's pattern needs, the name up to the next quote (its [^"]* goes
   no further) at least 3 bytes, not <..., ending in .c or .S */
static int c_marker (struct str *l)
{
  long i = 2, q;
  if (l->n < 4 || l->p[0] != '#' || l->p[1] != ' ' || !is_digit (l->p[2])) return 0;
  while (i < l->n && is_digit (l->p[i])) i++;
  if (i + 1 >= l->n || l->p[i] != ' ' || l->p[i + 1] != '"') return 0;
  i += 2;
  q = i;
  while (q < l->n && l->p[q] != '"') q++;
  if (q >= l->n || q - i < 3 || l->p[i] == '<') return 0;
  return l->p[q - 2] == '.' && (l->p[q - 1] == 'c' || l->p[q - 1] == 'S');
}
static struct hash *resolved;   /* a .i's names of files, each resolved */
/* Header.pm's header_of (header.c's), on the buffer: source_of, then files_of */
static struct hdr *hd_header_of (struct str *ifile)
{
  struct str l1, l2, l, *src = 0, *cwd = 0, *ff = 0, *fh = 0;
  struct vec *files = v_new ();
  struct hash *seen = h_new ();
  struct root *r;
  long i, a, nl = 0;
  i_read (ifile);
  for (i = 0; i < ilen; i++) if (ibuf[i] == '\n') { nl++; if (nl == 2) break; }
  a = i_line (0, &l1);
  a = i_line (a, &l2);
  /* (source_of: a file of fewer than two lines read to its end) */
  perrno = 25;
  if (!(ilen > 0 && nl + (ilen && ibuf[ilen - 1] != '\n') >= 2)) perrno = 0;
  if (l2.n && m (&l2, "^# 1 \"(.*?)/*\"$")) cwd = g (1);
  if (m (&l1, "^# 0 \"(.*)\"$")) {
    src = g (1);
    if (src->n && src->p[0] == '<') src = 0; else src = resolve (cwd, src);
  }
  /* (files_of: the .i read again to its end; a line marker that names no
     .c or .S file, a header's, is passed over before the pattern is tried,
     and each name is resolved once) */
  perrno = 0;
  h_clear (resolved);
  for (a = 0, i = 0; a < ilen; i++) {
    long b = i_line (a, &l);
    struct str *p, *k;
    if (i != 1 && c_marker (&l) && m (&l, "^# \\d+ \"([^\"<][^\"]*\\.[cS])\"")) {
      k = g (1);
      p = h_pv (resolved, k);
      if (!p) { p = resolve (cwd, k); h_setp (resolved, k, p); }
      if (!h_has (seen, p)) { h_set (seen, p, 1); v_push (files, p); }
    }
    a = b;
  }
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

int headers_main (int argc, char **argv)
{
  struct str *cfile, *names, *t, *cur = 0;
  struct hash *got;
  struct vec *ls, *keys;
  long i, bad = 0, n = 0, nfiles;
  struct hash *unit;
  envp_of = argv + argc + 1;
  header_init ();
  resolved = h_new ();
  if (argc != 3) { e_str ("usage: headers.pl out.c names.txt\n"); o_flush (); cp_exit (255); }
  cfile = s_of (argv[1]);
  names = s_of (argv[2]);

  /* the headers ff2c wrote, in its order (a header with no line: undef, '') */
  got = h_new ();
  t = h_slurp ((char *) cfile->p);
  ls = split_c (t, 10, 1);
  for (i = 0; i < ls->n; i++) {
    struct str *l = ls->v[i];
    if (m (l, "^/\\* ff2c: the header of (.+) \\*/$")) { cur = g (1); h_setp (got, cur, 0); continue; }
    if (s_is (l, "/* ff2c: the end of the headers */")) break;
    if (!cur) continue;
    {
      struct str *was = h_pv (got, cur);
      h_setp (got, cur, was ? s_join (was, "\n", l) : s_dup (l));
    }
  }

  keys = h_sorted (got);
  nfiles = keys->n;
  for (i = 0; i < keys->n; i++) {
    struct str *f = keys->v[i], *text = h_pv (got, f), *why = 0;
    if (!text) text = s_of ("");
    if (s_eq (text, text1 (GENERATED))) {
      if (!s_is (f, "<stdin>")) why = s_of ("the line of a generated stub for a file");
    } else if (s_eq (text, text1 (NOHEADER)) || s_eq (text, text1 (NOHEADER_GCC))) {
      if (leading_header (h_slurp ((char *) real_path (f)->p))) why = s_of ("it has a header, ff says none");
    } else {
      struct str *want = leading_header (h_slurp ((char *) real_path (f)->p));
      /* (a file of gcc's whose header names no license: its copyright, then the line saying so) */
      if (!want) why = s_of ("it has no header");
      else if (!s_eq (want, text) && !s_eq (text, header_text (nolicense_lines (want)))) why = s_of ("its header is not what ff2c wrote");
    }
    if (!why) continue;
    o_str ("headers: "); o_s (f); o_str (": "); o_s (why); o_str ("\n");
    bad = 1;
  }

  /* every unit of a function or global written has its file's header */
  unit = h_new ();
  t = h_slurp ((char *) names->p);
  ls = split_c (t, 10, 0);
  for (i = 0; i < ls->n; i++) {
    struct vec *f = split_c (ls->v[i], 9, 0);
    if (f->n >= 4 && s_is (f->v[0], "body") && m (f->v[3], "\\.i$")) h_set (unit, f->v[3], 1);
  }
  keys = h_sorted (unit);
  for (i = 0; i < keys->n; i++) {
    struct str *u = keys->v[i];
    struct hdr *x;
    n++;
    x = hd_header_of (u);
    if (h_has (got, x->file)) continue;
    o_str ("headers: "); o_s (u); o_str (": no header of "); o_s (x->file); o_str (" in "); o_s (cfile); o_str ("\n");
    bad = 1;
  }
  if (bad) { o_flush (); cp_exit (1); }
  o_str ("headers: "); o_s (s_num (nfiles)); o_str (" files' headers as glibc has them, for the ");
  o_s (s_num (n)); o_str (" units of the functions\n");
  o_flush ();
  return 0;
}
