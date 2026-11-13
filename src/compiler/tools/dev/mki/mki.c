/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* mki.c: dev source of tools/mki.ff, src/glibc/mki.pl and src/libgcc/mki.pl
   in ff: the .i (or an asm object's .s) of an object of the reference
   glibc or libgcc, its command from the build's log run again with -E (or
   the C preprocessor in ff in gcc's place, --cpp), in the folder it ran in.
   The same commands and the same files as the Perl, which stays as a
   cross-check (make mki-crosscheck); --show prints each command instead of
   running it (both tools), which is what that check compares.

     mki [--dry] [--show] [--log FILE]... [--cpp TOOL --predef FILE [--out DIR]] OBJ SRC OBJECT...
     mki --libgcc [--dry] [--show] [--cpp TOOL --predef FILE] [--out DIR] BUILD OUT OBJECT...

   Perl's patterns are matched by hand, each as the Perl's comment above it
   says. */

/* the runtime: tools/rt.ff's alloc, tools/c.ff's cp_* and the page's own mk_* (mki/shim.ff.txt;
   the dev build's shim.c): raw syscalls, each result the kernel's, a negative errno when it fails */
void *alloc (long n);
long cp_write (int fd, unsigned char *p, long n);
long cp_readlink (char *path, unsigned char *buf, long room);
void cp_exit (int status);
long mk_open (char *path);
long mk_exists (char *path);
long mk_read (long fd, unsigned char *buf, long n);
long mk_close (long fd);
long mk_mkdir (char *path);
long mk_run (char *path, char **argv, char **envp);

/* ---- strings */
struct str { unsigned char *p; long n, room; };
static long slen (char *s) { long n = 0; while (s[n]) n++; return n; }
static void mcopy (unsigned char *d, unsigned char *s, long n) { long i = 0; while (i < n) { d[i] = s[i]; i++; } }
static int msame (unsigned char *a, unsigned char *b, long n) { long i = 0; while (i < n) { if (a[i] != b[i]) return 0; i++; } return 1; }
static void s_add (struct str *s, unsigned char *p, long n)
{
  if (s->n + n + 1 > s->room) {
    long r = (s->room + n + 1) * 2;
    unsigned char *x = alloc (r);
    mcopy (x, s->p, s->n);
    s->p = x; s->room = r;
  }
  mcopy (s->p + s->n, p, n);
  s->n += n;
  s->p[s->n] = 0;
}
static void s_cat (struct str *s, char *c) { s_add (s, (unsigned char *) c, slen (c)); }
static struct str *s_new (unsigned char *p, long n) { struct str *s = alloc (sizeof (struct str)); s_add (s, p, n); return s; }
static struct str *s_of (char *c) { return s_new ((unsigned char *) c, slen (c)); }
/* s with [a, b) replaced by r */
static struct str *s_splice (struct str *s, long a, long b, unsigned char *r, long rn)
{
  struct str *t = s_new (s->p, a);
  s_add (t, r, rn);
  s_add (t, s->p + b, s->n - b);
  return t;
}
/* the first place of the bytes f in s from i, or -1 */
static long s_find (struct str *s, long i, char *f)
{
  long n = slen (f);
  while (i + n <= s->n) { if (msame (s->p + i, (unsigned char *) f, n)) return i; i++; }
  return -1;
}
static int is_space (int c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == 11; }
static int is_word (int c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'; }
/* the end of the run of non-space bytes (\S+) from i */
static long tok_end (struct str *s, long i) { while (i < s->n && !is_space (s->p[i])) i++; return i; }
static int ends (unsigned char *p, long n, char *e) { long k = slen (e); return n >= k && msame (p + n - k, (unsigned char *) e, k); }

/* ---- output */
static unsigned char obuf[65536];
static long on;
static void o_flush (void) { long i = 0; while (i < on) { long w = cp_write (1, obuf + i, on - i); if (w <= 0) break; i += w; } on = 0; }
static void o_bytes (unsigned char *p, long n) { while (n > 0) { if (on == 65536) o_flush (); obuf[on++] = *p++; n--; } }
static void o_str (char *s) { o_bytes ((unsigned char *) s, slen (s)); }
static void e_bytes (unsigned char *p, long n) { cp_write (2, p, n); }
static void e_str (char *s) { e_bytes ((unsigned char *) s, slen (s)); }
static void die (void) { o_flush (); cp_exit (255); }

/* ---- files */
static struct str *read_all (char *path)   /* 0 if it cannot be read */
{
  long fd = mk_open (path);
  struct str *s;
  if (fd < 0) return 0;
  s = alloc (sizeof (struct str));
  s->room = 1 << 20; s->p = alloc (s->room);
  for (;;) {
    long r;
    if (s->n + 65536 + 1 > s->room) { unsigned char *x = alloc (s->room * 2); mcopy (x, s->p, s->n); s->p = x; s->room *= 2; }
    r = mk_read (fd, s->p + s->n, 65536);
    if (r < 0) { mk_close (fd); return 0; }
    if (r == 0) break;
    s->n += r;
  }
  mk_close (fd);
  s->p[s->n] = 0;
  return s;
}
static void make_path (struct str *d)   /* File::Path's make_path: each folder of d made */
{
  long i = 1;
  while (i <= d->n) {
    if (i == d->n || d->p[i] == '/') {
      struct str *x = s_new (d->p, i);
      mk_mkdir ((char *) x->p);
    }
    i++;
  }
}
static struct str *dirname_of (struct str *s)   /* File::Basename's dirname (of a path with a / not at its end) */
{
  long i = s->n;
  while (i > 0 && s->p[i - 1] != '/') i--;
  while (i > 1 && s->p[i - 1] == '/') i--;
  if (i == 0) return s_of (".");
  return s_new (s->p, i);
}
static struct str *abs_path (char *path)   /* Cwd::abs_path: the path the kernel gives the open folder */
{
  long fd = mk_exists (path), n;
  unsigned char b[4096];
  struct str *l;
  char num[24]; long k = 0, v = fd; char t[24]; long m = 0;
  if (fd < 0) return s_of ("");
  if (v == 0) t[m++] = '0';
  while (v > 0) { t[m++] = '0' + (char) (v % 10); v = v / 10; }
  while (m > 0) num[k++] = t[--m];
  num[k] = 0;
  l = s_of ("/proc/self/fd/"); s_cat (l, num);
  n = cp_readlink ((char *) l->p, b, 4095);
  mk_close (fd);
  if (n <= 0) return s_of ("");
  return s_new (b, n);
}

/* ---- the commands */
struct cmd { struct str *obj; struct str *cmdline; struct cmd *next; };
#define NH 65536
static struct cmd *tab[NH];
static long hashof (unsigned char *p, long n) { unsigned long h = 5381; long i = 0; while (i < n) { h = h * 33 + p[i]; i++; } return (long) (h & (NH - 1)); }
static struct str *lookup (struct cmd **t, unsigned char *o, long n)
{
  struct cmd *c = t[hashof (o, n)];
  while (c) { if (c->obj->n == n && msame (c->obj->p, o, n)) return c->cmdline; c = c->next; }
  return 0;
}
static void keep (struct cmd **t, unsigned char *o, long n, struct str *cl1)   /* $cmd{$o} //= $line */
{
  long h = hashof (o, n);
  struct cmd *c;
  if (lookup (t, o, n)) return;
  c = alloc (sizeof (struct cmd));
  c->obj = s_new (o, n); c->cmdline = cl1; c->next = t[h]; t[h] = c;
}
static struct cmd *gen[NH];

/* / -o (\S+\.o[sS]?) /: the place of the object after the first -o that names one followed by a space, its end in *e; -1 if none */
static long dash_o_obj (struct str *l, long *e, int with_S)
{
  long i = 0;
  for (;;) {
    long a = s_find (l, i, " -o "), b;
    if (a < 0) return -1;
    a += 4;
    b = tok_end (l, a);
    if (b < l->n && l->p[b] == ' ' && b - a >= 1) {
      unsigned char *p = l->p + a; long n = b - a;
      if ((n > 2 && ends (p, n, ".o")) || (n > 3 && (ends (p, n, ".os") || ends (p, n, ".oS"))) || (with_S && n > 2 && ends (p, n, ".S"))) { *e = b; return a; }
    }
    i = a - 3;
  }
}
/* / -S(?:\s|$)/ */
static int has_S (struct str *l)
{
  long i = 0;
  for (;;) {
    long a = s_find (l, i, " -S");
    if (a < 0) return 0;
    if (a + 3 == l->n || is_space (l->p[a + 3])) return 1;
    i = a + 1;
  }
}
static struct str *obj, *real, *build, *src, *outdir, *cpp, *predef;
static int dry, show, libgcc;
/* / -o (?:\Q$obj\E|\Q$real\E)\/(\S+)-aux\.S /: $1, or 0 */
static struct str *aux_of (struct str *l)
{
  long i = 0;
  for (;;) {
    long a = s_find (l, i, " -o "), b, k;
    if (a < 0) return 0;
    a += 4;
    b = tok_end (l, a);
    for (k = 0; k < 2; k++) {
      struct str *pre = k ? real : obj;
      long s0 = a + pre->n + 1;
      if (s0 <= l->n && msame (l->p + a, pre->p, pre->n) && l->p[a + pre->n] == '/' && b < l->n && l->p[b] == ' '
          && b - s0 > 6 && ends (l->p + s0, b - s0, "-aux.S"))
        return s_new (l->p + s0, b - s0 - 6);
    }
    i = a - 3;
  }
}
static void read_log (char *name)
{
  struct str *all = read_all (name), *block = 0;
  long i = 0;
  if (!all) { e_str ("mki: cannot open "); e_str (name); e_str (": No such file or directory\n"); die (); }
  while (i < all->n) {
    long j = i, e, a;
    struct str *l, *o;
    while (j < all->n && all->p[j] != '\n') j++;
    if (j < all->n) j++;
    l = s_new (all->p + i, j - i);
    i = j;
    /* a command over several lines (each but the last ending in \): (echo ...; ...) | gcc ... - */
    if ((l->n >= 6 && msame (l->p, (unsigned char *) "(echo ", 6)) || block) {
      long k = l->n;
      if (!block) block = s_new (l->p, 0);
      s_add (block, l->p, l->n);
      while (k > 0 && is_space (l->p[k - 1])) k--;
      if (k > 0 && l->p[k - 1] == '\\') continue;
      l = block; block = 0;
    }
    /* an object whose asm is gcc's -S of a C file (errlist-data.S includes errlist-data-aux.S, from errlist-data-gen.c): that C is its source */
    if (has_S (l) && (o = aux_of (l))) { s_cat (o, ".o"); keep (gen, o->p, o->n, l); continue; }
    if (s_find (l, 0, " -c ") < 0) continue;
    a = dash_o_obj (l, &e, 0);
    if (a < 0) continue;
    if (e - a > obj->n && msame (l->p + a, obj->p, obj->n) && l->p[a + obj->n] == '/') a += obj->n + 1;
    else if (real->n && e - a > real->n && msame (l->p + a, real->p, real->n) && l->p[a + real->n] == '/') a += real->n + 1;
    else continue;
    keep (tab, l->p + a, e - a, l);
  }
}
/* libgcc's log: each command once, its continued lines joined; / -c / && / -o (\S+\.o) / */
static void read_libgcc_log (char *name)
{
  struct str *all = read_all (name), *j;
  long i = 0, k;
  if (!all) { e_str ("mki: cannot open "); e_str (name); e_str (": No such file or directory\n"); die (); }
  j = s_new (all->p, 0);
  for (k = 0; k < all->n; k++) {
    if (all->p[k] == '\\' && k + 1 < all->n && all->p[k + 1] == '\n') { s_add (j, (unsigned char *) " ", 1); k++; }
    else s_add (j, all->p + k, 1);
  }
  while (i < j->n) {
    long e = i, a, b, s0 = 0;
    struct str *l;
    while (e < j->n && j->p[e] != '\n') e++;
    l = s_new (j->p + i, e - i);
    i = e + 1;
    if (s_find (l, 0, " -c ") < 0) continue;
    for (;;) {
      a = s_find (l, s0, " -o ");
      if (a < 0) break;
      a += 4; b = tok_end (l, a);
      if (b < l->n && l->p[b] == ' ' && b - a > 2 && ends (l->p + a, b - a, ".o")) break;
      s0 = a - 3;
    }
    if (a < 0) continue;
    keep (tab, l->p + a, b - a, l);
  }
}

/* the command of libm's soft-fp code: of e_sqrtl or e_sqrtf128, the one whose source includes soft-fp (x86_64's e_sqrtl is the x87's) */
/* m{ \.\./(sysdeps/\S+/e_sqrt(?:l|f128)\.c) }: the place of sysdeps/..., its end in *e */
static long sqrt_src (struct str *c, long *e)
{
  long i = 0;
  for (;;) {
    long a = s_find (c, i, " ../sysdeps/"), b;
    if (a < 0) return -1;
    a += 4;
    b = tok_end (c, a);
    if (b < c->n && c->p[b] == ' ') {
      unsigned char *p = c->p + a; long n = b - a;
      if ((n > 18 && ends (p, n, "/e_sqrtl.c")) || (n > 21 && ends (p, n, "/e_sqrtf128.c"))) { *e = b; return a; }
    }
    i = a - 3;
  }
}
static struct str *softfp_cmd (void)
{
  char *os[2] = { "math/e_sqrtl.o", "math/e_sqrtf128.o" };
  long k;
  for (k = 0; k < 2; k++) {
    struct str *c = lookup (tab, (unsigned char *) os[k], slen (os[k])), *f, *t;
    long a, e;
    if (!c) continue;
    a = sqrt_src (c, &e);
    if (a < 0) continue;
    f = s_new (src->p, src->n); s_cat (f, "/"); s_add (f, c->p + a, e - a);
    t = read_all ((char *) f->p);
    if (!t) continue;
    if (s_find (t, 0, "soft-fp") >= 0) return c;
  }
  return 0;
}
/* s/A/B/: the first A replaced by B, 0 if there is none */
static struct str *sub1 (struct str *s, char *a, char *b)
{
  long i = s_find (s, 0, a);
  if (i < 0) return 0;
  return s_splice (s, i, i + slen (a), (unsigned char *) b, slen (b));
}
static void warn_fail (struct str *o) { e_str ("mki: "); e_bytes (o->p, o->n); e_str (": the compiler failed\n"); }

/* the store paths a command names (m{(/nix/store/[a-z0-9]{32}-[^/\s'"]+)}g) that are gone: one line each, sorted, unique; 0 if none */
static struct str **gone_paths (struct str *c, long *ng, int unique)
{
  struct str **g = alloc (256 * sizeof (struct str *));
  long i = 0, n = 0;
  for (;;) {
    long a = s_find (c, i, "/nix/store/"), b, k, ok = 1;
    if (a < 0) break;
    b = a + 11;
    for (k = 0; k < 32; k++) { int x = b + k < c->n ? c->p[b + k] : 0; if (!((x >= 'a' && x <= 'z') || (x >= '0' && x <= '9'))) { ok = 0; break; } }
    if (!ok || b + 32 >= c->n || c->p[b + 32] != '-') { i = a + 1; continue; }
    b += 33;
    while (b < c->n && c->p[b] != '/' && !is_space (c->p[b]) && c->p[b] != '\'' && c->p[b] != '"') b++;
    if (b == a + 44) { i = a + 1; continue; }
    {
      struct str *p = s_new (c->p + a, b - a);
      long fd = mk_exists ((char *) p->p), j, dup = 0;
      if (fd >= 0) mk_close (fd);
      else if (n < 256) {
        for (j = 0; j < n && unique; j++) if (g[j]->n == p->n && msame (g[j]->p, p->p, p->n)) dup = 1;
        if (!dup) g[n++] = p;
      }
    }
    i = b;
  }
  if (unique) {   /* sort keys */
    long x, y;
    for (x = 1; x < n; x++) for (y = x; y > 0; y--) {
      struct str *u = g[y - 1], *v = g[y];
      long m = u->n < v->n ? u->n : v->n, q = 0, d = 0;
      while (q < m && u->p[q] == v->p[q]) q++;
      d = q < m ? (int) u->p[q] - (int) v->p[q] : u->n - v->n;
      if (d <= 0) break;
      g[y - 1] = v; g[y] = u;
    }
  }
  *ng = n;
  return g;
}

static char *sh_path;
static char **envp_of;
static long run_sh (struct str *dir, struct str *c)   /* system ('sh', '-c', "cd '$dir' && $c"): 0 when it exits 0 */
{
  struct str *sh_line = s_of ("cd '");
  char *argv[4];
  s_add (sh_line, dir->p, dir->n); s_cat (sh_line, "' && "); s_add (sh_line, c->p, c->n);
  if (show) { o_bytes (sh_line->p, sh_line->n); o_str ("\n"); return 0; }
  argv[0] = "sh"; argv[1] = "-c"; argv[2] = (char *) sh_line->p; argv[3] = 0;
  o_flush ();
  return mk_run (sh_path, argv, envp_of);
}
static void find_sh (char **envp)   /* sh on the PATH, as Perl's system finds it */
{
  long i = 0;
  sh_path = "/bin/sh";
  while (envp && envp[i]) {
    char *e = envp[i];
    if (e[0] == 'P' && e[1] == 'A' && e[2] == 'T' && e[3] == 'H' && e[4] == '=') {
      char *p = e + 5;
      while (*p) {
        long n = 0;
        while (p[n] && p[n] != ':') n++;
        if (n > 0) {
          struct str *x = s_new ((unsigned char *) p, n);
          long fd;
          s_cat (x, "/sh");
          fd = mk_exists ((char *) x->p);
          if (fd >= 0) { mk_close (fd); sh_path = (char *) x->p; return; }
        }
        p += n;
        if (*p == ':') p++;
      }
      return;
    }
    i++;
  }
}

static int glibc_one (struct str *o, char **logs, long nlogs)
{
  struct str *c = lookup (gen, o->p, o->n), *t, *i, *dir, *x;
  int isgen = c != 0, ext_s;
  long k, e, a;
  if (!c) c = lookup (tab, o->p, o->n);
  if (!c) { x = s_new (o->p, o->n); s_cat (x, "S"); c = lookup (tab, x->p, x->n); }
  if (!c) { x = s_new (o->p, o->n); s_cat (x, "s"); c = lookup (tab, x->p, x->n); }
  /* soft-fp/X.o: libm's soft-fp command with soft-fp/X.c, in libc, without a 128-bit integer */
  if (!c && o->n > 10 && msame (o->p, (unsigned char *) "soft-fp/", 8) && ends (o->p, o->n, ".o") && (t = softfp_cmd ())) {
    struct str *f = s_new (o->p + 8, o->n - 10), *r;
    int w = f->n > 0;
    for (k = 0; k < f->n; k++) if (!is_word (f->p[k])) w = 0;
    if (w) {
      a = sqrt_src (t, &e);
      r = s_of (" ../soft-fp/"); s_add (r, f->p, f->n); s_cat (r, ".c ");
      c = s_splice (t, a - 4, e + 1, r->p, r->n);
      x = sub1 (c, " -DMODULE_NAME=libm ", " -DMODULE_NAME=libc ");
      if (!x) { e_str ("mki: no MODULE_NAME in e_sqrt's command\n"); die (); }
      c = sub1 (x, " -o ", " -U__SIZEOF_INT128__ -U__BITINT_MAXWIDTH__ -o ");
      if (s_find (t, 0, "/sysdeps/x86/fpu/e_sqrtf128.c ") >= 0) c = sub1 (c, " -o ", " -D__gcc_CMPtype=__gcc_CMPtype_GCC -o ");
      /* s{ -o \S+\.o }{ -o $obj/soft-fp/$f.o } */
      for (k = 0;;) {
        long b;
        a = s_find (c, k, " -o ");
        if (a < 0) break;
        b = tok_end (c, a + 4);
        if (b < c->n && c->p[b] == ' ' && b - (a + 4) > 2 && ends (c->p + a + 4, b - a - 4, ".o")) {
          r = s_of (" -o "); s_add (r, obj->p, obj->n); s_cat (r, "/soft-fp/"); s_add (r, f->p, f->n); s_cat (r, ".o ");
          c = s_splice (c, a, b + 1, r->p, r->n);
          break;
        }
        k = a + 1;
      }
    } else c = 0;
  }
  if (!c) {
    e_str ("mki: no command for "); e_bytes (o->p, o->n); e_str (" in ");
    for (k = 0; k < nlogs; k++) { if (k) e_str (", "); e_str (logs[k]); }
    e_str ("\n");
    return 1;
  }
  c = s_new (c->p, c->n);
  if (c->n && c->p[c->n - 1] == '\n') c->p[--c->n] = 0;   /* chomp */
  /* m{\.S\s| -x assembler-with-cpp } */
  ext_s = 0;
  if (!isgen) {
    if (s_find (c, 0, " -x assembler-with-cpp ") >= 0) ext_s = 1;
    for (k = 0; k + 2 < c->n && !ext_s; k++) if (c->p[k] == '.' && c->p[k + 1] == 'S' && is_space (c->p[k + 2])) ext_s = 1;
  }
  i = outdir ? s_new (outdir->p, outdir->n) : s_new (build->p, build->n);
  if (!outdir) s_cat (i, "/i");
  s_cat (i, "/"); s_add (i, o->p, o->n);
  /* s/\.o[sS]?$/.$ext/ */
  if (ends (i->p, i->n, ".o")) i->n -= 2;
  else if (ends (i->p, i->n, ".os") || ends (i->p, i->n, ".oS")) i->n -= 3;
  else { e_str ("mki: not an object: "); e_bytes (o->p, o->n); e_str ("\n"); return 1; }
  s_cat (i, ext_s ? ".s" : ".i");
  if (dry) { o_bytes (i->p, i->n); o_str ("\n"); return 0; }
  if (!show) make_path (dirname_of (i));
  if ((x = sub1 (c, " -c ", " -E "))) c = x;
  else {   /* s/ -S(\s|$)/ -E$1/ */
    for (k = 0;; k++) {
      a = s_find (c, k, " -S");
      if (a < 0) break;
      if (a + 3 == c->n || is_space (c->p[a + 3])) { c = s_splice (c, a, a + 3, (unsigned char *) " -E", 3); break; }
      k = a;
    }
  }
  /* s/ -o \S+\.(?:o[sS]?|S) / -o $i / */
  a = dash_o_obj (c, &e, 1);
  if (a >= 0) { x = s_new (i->p, i->n); s_cat (x, " "); c = s_splice (c, a, e + 1, x->p, x->n); }
  /* s/ -MD -MP -MF \S+ -MT \S+// */
  for (k = 0;;) {
    long b, d;
    a = s_find (c, k, " -MD -MP -MF ");
    if (a < 0) break;
    b = tok_end (c, a + 13);
    if (b > a + 13 && b + 5 <= c->n && msame (c->p + b, (unsigned char *) " -MT ", 5) && (d = tok_end (c, b + 5)) > b + 5) { c = s_splice (c, a, d, (unsigned char *) "", 0); break; }
    k = a + 1;
  }
  /* (the preprocessor in ff in the compiler's place; a syscall stub's command is (echo ...) | gcc ...: the compiler after the pipe) */
  if (cpp) {
    struct str *r = s_new (cpp->p, cpp->n);
    int done = 0;
    s_cat (r, " --predef="); s_add (r, predef->p, predef->n);
    if (c->n >= 6 && msame (c->p, (unsigned char *) "(echo ", 6)) {
      /* s{\)\s*\|\s*(\S+)}{) | $cpp --predef=$predef} */
      for (k = 0; k < c->n && !done; k++) {
        long q = k + 1, b;
        if (c->p[k] != ')') continue;
        while (q < c->n && is_space (c->p[q])) q++;
        if (q >= c->n || c->p[q] != '|') continue;
        q++;
        while (q < c->n && is_space (c->p[q])) q++;
        b = tok_end (c, q);
        if (b == q) continue;
        x = s_of (") | "); s_add (x, r->p, r->n);
        c = s_splice (c, k, b, x->p, x->n);
        done = 1;
      }
    } else {
      /* s{^\s*(\S+)}{$cpp --predef=$predef} */
      long q = 0, b;
      while (q < c->n && is_space (c->p[q])) q++;
      b = tok_end (c, q);
      if (b > q) { c = s_splice (c, 0, b, r->p, r->n); done = 1; }
    }
    if (!done) { e_str ("mki: "); e_bytes (o->p, o->n); e_str (": no compiler in its command\n"); die (); }
  }
  /* build.log names the compiler and the kernel's headers by their store paths: one that is gone cannot run */
  {
    long ng;
    struct str **g = gone_paths (c, &ng, 1);
    if (ng) {
      struct str *cc = 0;
      long fd = -1;
      /* m{(?:^|\|\s*)(/nix/store/\S+)} */
      for (k = 0; k < c->n && !cc; k++) {
        long q = k;
        if (k == 0) { if (c->n > 11 && msame (c->p, (unsigned char *) "/nix/store/", 11) && tok_end (c, 0) > 11) cc = s_new (c->p, tok_end (c, 0)); }
        if (cc || c->p[k] != '|') continue;
        q = k + 1;
        while (q < c->n && is_space (c->p[q])) q++;
        if (c->n - q > 11 && msame (c->p + q, (unsigned char *) "/nix/store/", 11) && tok_end (c, q) > q + 11) cc = s_new (c->p + q, tok_end (c, q) - q);
      }
      e_str ("mki: "); e_bytes (o->p, o->n); e_str (": build.log's command cannot run again: ");
      if (cc) fd = mk_exists ((char *) cc->p);
      if (cc && fd < 0) { e_str ("its compiler "); e_bytes (cc->p, cc->n); e_str (" is gone"); }
      else {
        if (fd >= 0) mk_close (fd);
        e_str ("it names ");
        for (k = 0; k < ng; k++) { if (k) e_str (", "); e_bytes (g[k]->p, g[k]->n); }
        e_str (ng > 1 ? ", which are gone" : ", which is gone");
      }
      e_str (" (nix gc took it after an update).\n");
      e_str ("mki: rebuild glibc-ref with the current toolchain, into a new BUILD (make -C src/glibc glibc-ref BUILD=...),\n");
      e_str ("mki: and keep the toolchain alive with `make gcroots`.\n");
      die ();
    }
  }
  /* (libg.a's dummy.o, at the top of the build, is made in misc) */
  dir = s_new (src->p, src->n); s_cat (dir, "/");
  if (o->n > 8 && msame (o->p, (unsigned char *) "soft-fp/", 8)) s_cat (dir, "math");
  else {
    long slash = 0;
    while (slash < o->n && o->p[slash] != '/') slash++;
    if (slash == o->n) s_cat (dir, "misc"); else s_add (dir, o->p, slash);
  }
  if (run_sh (dir, c) != 0) { warn_fail (o); return 1; }
  /* the .i of glibc's u128 as a 128-bit integer: again without one */
  if (!ext_s && !show && s_find (c, 0, " -U__SIZEOF_INT128__ ") < 0) {
    struct str *f = read_all ((char *) i->p);
    int u = 0;
    if (f) {
      long p = 0;
      while (p < f->n && !u) {
        long q = p;
        while (q < f->n && f->p[q] != '\n') q++;
        if ((q - p == 31 && msame (f->p + p, (unsigned char *) "typedef unsigned __int128 u128;", 31))
            || (q - p == 35 && msame (f->p + p, (unsigned char *) "typedef unsigned _BitInt(128) u128;", 35))) u = 1;
        p = q + 1;
      }
    }
    if (u) {
      c = sub1 (c, " -o ", " -U__SIZEOF_INT128__ -U__BITINT_MAXWIDTH__ -o ");
      if (run_sh (dir, c) != 0) { warn_fail (o); return 1; }
    }
  }
  o_bytes (i->p, i->n); o_str ("\n");
  return 0;
}

static int libgcc_one (struct str *o)
{
  struct str *c = lookup (tab, o->p, o->n), *i, *x;
  int ext_s = 0;
  long k, a, b;
  if (!c) { e_str ("mki: no command for "); e_bytes (o->p, o->n); e_str (" in "); e_bytes (obj->p, obj->n); e_str ("/build.log\n"); return 1; }
  /* (an asm source: -xassembler-with-cpp, or a .S that gcc knows by its name: / -c \S+\.S\b/) */
  if (s_find (c, 0, " -xassembler-with-cpp ") >= 0) ext_s = 1;
  for (k = 0; !ext_s;) {
    long q, t;
    a = s_find (c, k, " -c ");
    if (a < 0) break;
    q = a + 4; t = tok_end (c, q);
    for (b = q + 1; b + 1 < t && !ext_s; b++)
      if (c->p[b] == '.' && c->p[b + 1] == 'S' && !(b + 2 < c->n && is_word (c->p[b + 2]))) ext_s = 1;
    k = a + 1;
  }
  i = s_new (outdir->p, outdir->n); s_cat (i, "/"); s_add (i, o->p, o->n);
  if (ends (i->p, i->n, ".o")) { i->n -= 2; s_cat (i, ext_s ? ".s" : ".i"); }
  if (dry) { o_bytes (i->p, i->n); o_str ("\n"); return 0; }
  if (!show) make_path (outdir);
  x = sub1 (c, " -c ", " -E ");
  if (!x) { e_str ("mki: "); e_bytes (o->p, o->n); e_str (": no -c in its command\n"); die (); }
  c = x;
  /* s/ -o \S+\.o / -o $i / */
  for (k = 0;;) {
    a = s_find (c, k, " -o ");
    if (a < 0) break;
    b = tok_end (c, a + 4);
    if (b < c->n && c->p[b] == ' ' && b - a - 4 > 2 && ends (c->p + a + 4, b - a - 4, ".o")) {
      x = s_of (" -o "); s_add (x, i->p, i->n); s_cat (x, " ");
      c = s_splice (c, a, b + 1, x->p, x->n);
      break;
    }
    k = a + 1;
  }
  /* s/ -MT \S+ -MD -MP -MF \S+// */
  for (k = 0;;) {
    long d;
    a = s_find (c, k, " -MT ");
    if (a < 0) break;
    b = tok_end (c, a + 5);
    if (b > a + 5 && b + 13 <= c->n && msame (c->p + b, (unsigned char *) " -MD -MP -MF ", 13) && (d = tok_end (c, b + 13)) > b + 13) { c = s_splice (c, a, d, (unsigned char *) "", 0); break; }
    k = a + 1;
  }
  if (cpp) {
    long q = 0;
    struct str *r = s_new (cpp->p, cpp->n);
    s_cat (r, " --predef="); s_add (r, predef->p, predef->n);
    while (q < c->n && is_space (c->p[q])) q++;
    b = tok_end (c, q);
    if (b == q) { e_str ("mki: "); e_bytes (o->p, o->n); e_str (": no compiler in its command\n"); die (); }
    c = s_splice (c, 0, b, r->p, r->n);
  }
  {
    long ng;
    struct str **g = gone_paths (c, &ng, 0);
    if (ng) {
      e_str ("mki: "); e_bytes (o->p, o->n); e_str (": build.log's command names ");
      for (k = 0; k < ng; k++) { if (k) e_str (", "); e_bytes (g[k]->p, g[k]->n); }
      e_str (", gone (nix gc): make libgcc-ref again, into a new BUILD\n");
      die ();
    }
  }
  if (run_sh (obj, c) != 0) { warn_fail (o); return 1; }
  o_bytes (i->p, i->n); o_str ("\n");
  return 0;
}

static int is_opt (char *a, char *o) { long n = slen (o); return slen (a) == n && msame ((unsigned char *) a, (unsigned char *) o, n); }
int mki_main (int argc, char **argv)
{
  char **logs = alloc ((argc + 1) * sizeof (char *));
  long nlogs = 0, k;
  int i = 1, bad = 0;
  envp_of = argv + argc + 1;
  if (i < argc && is_opt (argv[i], "--libgcc")) { libgcc = 1; i++; }
  while (i < argc) {
    char *a = argv[i];
    if (is_opt (a, "--dry")) { dry = 1; i++; }
    else if (is_opt (a, "--show")) { show = 1; i++; }
    else if (!libgcc && is_opt (a, "--log") && i + 1 < argc) { logs[nlogs++] = argv[i + 1]; i += 2; }
    else if (is_opt (a, "--cpp") && i + 1 < argc) { cpp = s_of (argv[i + 1]); i += 2; }
    else if (is_opt (a, "--predef") && i + 1 < argc) { predef = s_of (argv[i + 1]); i += 2; }
    else if (is_opt (a, "--out") && i + 1 < argc) { outdir = s_of (argv[i + 1]); i += 2; }
    else break;
  }
  if (argc - i < 3) {
    if (libgcc) e_str ("usage: mki --libgcc [--dry] [--show] [--cpp tool --predef file [--out dir]] <libgcc build dir> <out dir> <object>...\n");
    else e_str ("usage: mki [--dry] [--show] [--log file]... [--cpp tool --predef file [--out dir]] <obj dir> <glibc source> <object>...\n");
    die ();
  }
  if (cpp && !predef) { e_str ("mki: --cpp needs --predef\n"); die (); }
  find_sh (envp_of);
  obj = s_of (argv[i]);
  if (libgcc) {
    if (!outdir) outdir = s_of (argv[i + 1]);
    { struct str *l = s_new (obj->p, obj->n); s_cat (l, "/build.log"); read_libgcc_log ((char *) l->p); }
    for (k = i + 2; k < argc; k++) bad |= libgcc_one (s_of (argv[k]));
    o_flush ();
    return bad;
  }
  src = s_of (argv[i + 1]);
  /* the folder of the build, as given, its last name taken off (the Perl's s{...}{}): its i/ is next to obj/ */
  {
    long e = obj->n, b;
    while (e > 0 && obj->p[e - 1] == '/') e--;
    b = e;
    while (b > 0 && obj->p[b - 1] != '/') b--;
    if (b > 0 && b < e) { while (b > 0 && obj->p[b - 1] == '/') b--; build = s_new (obj->p, b); }
    else build = s_new (obj->p, obj->n);
  }
  real = abs_path ((char *) obj->p);
  if (!nlogs) { struct str *l = s_new (obj->p, obj->n); s_cat (l, "/build.log"); logs[nlogs++] = (char *) l->p; }
  for (k = 0; k < nlogs; k++) read_log (logs[k]);
  for (k = i + 2; k < argc; k++) bad |= glibc_one (s_of (argv[k]), logs, nlogs);
  o_flush ();
  return bad;
}
