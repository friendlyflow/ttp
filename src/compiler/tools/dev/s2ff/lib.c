/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* lib.c: what the Perl of gen/s2ff*.pl takes from Perl itself, for s2ff.c:
   strings, Perl's regular expressions (a backtracking matcher of the
   subset the Perl uses: classes, \s \w \d \b, greedy and lazy
   quantifiers, groups, (?:) (?|) (?=) (?!) (?<=) (?<!), the flags i m s x),
   hashes, the ff tree and FF.pm's write_txt, files, and Perl's die. */

/* ---- the runtime: tools/rt.ff's alloc, tools/c.ff's cp_*, the page's own s2_* (s2ff/shim.ff.txt) */
void *alloc (long n);
long cp_write (int fd, unsigned char *p, long n);
long cp_create (char *path);
long cp_readlink (char *path, unsigned char *buf, long room);
void cp_exit (int status);
long s2_open (char *path);
long s2_exists (char *path);
long s2_read (long fd, unsigned char *buf, long n);
long s2_close (long fd);

/* Every long after this is 64 bits, on every target: the Perl's numbers
   are (an address, a word of asm data, a hash), and c2ff writes long as the
   target's long, 32 bits on arm (unsigned long as u64 always): a hash of
   u64 cast to long went negative there and indexed outside its table. The
   runtime above keeps its long. */
#define long long long

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
    if (s->n) mcopy (x, s->p, s->n);
    s->p = x; s->room = r;
  }
  mcopy (s->p + s->n, p, n);
  s->n += n;
  s->p[s->n] = 0;
}
static void s_cat (struct str *s, char *c) { s_add (s, (unsigned char *) c, slen (c)); }
static void s_app (struct str *s, struct str *t) { s_add (s, t->p, t->n); }
static void s_chr (struct str *s, int c) { unsigned char b[1]; b[0] = (unsigned char) c; s_add (s, b, 1); }
static struct str *s_new (unsigned char *p, long n) { struct str *s = alloc (sizeof (struct str)); s_add (s, p, n); return s; }
static struct str *s_of (char *c) { return s_new ((unsigned char *) c, slen (c)); }
static struct str *s_dup (struct str *t) { return s_new (t->p, t->n); }
static struct str *s_sub (struct str *t, long a, long b) { if (a < 0) a = 0; if (b > t->n) b = t->n; if (b < a) b = a; return s_new (t->p + a, b - a); }
static struct str *s_join (struct str *a, char *mid, struct str *b) { struct str *s = s_dup (a); s_cat (s, mid); s_app (s, b); return s; }
static int s_eq (struct str *a, struct str *b) { return a->n == b->n && msame (a->p, b->p, a->n); }
static int s_is (struct str *a, char *c) { long n = slen (c); return a->n == n && msame (a->p, (unsigned char *) c, n); }
static int s_cmp (struct str *a, struct str *b)
{
  long m = a->n < b->n ? a->n : b->n, i = 0;
  while (i < m && a->p[i] == b->p[i]) i++;
  if (i < m) return (int) a->p[i] - (int) b->p[i];
  return a->n < b->n ? -1 : a->n > b->n ? 1 : 0;
}
static struct str *s_num (long v)   /* Perl's "$v" of an integer */
{
  char t[24]; long m = 0; struct str *s = s_of ("");
  unsigned long u = v < 0 ? (unsigned long) 0 - (unsigned long) v : (unsigned long) v;
  if (v < 0) s_chr (s, '-');
  if (u == 0) t[m++] = '0';
  while (u > 0) { t[m++] = (char) ('0' + u % 10); u = u / 10; }
  while (m > 0) s_chr (s, t[--m]);
  return s;
}
static struct str *s_unum (unsigned long u)
{
  char t[24]; long m = 0; struct str *s = s_of ("");
  if (u == 0) t[m++] = '0';
  while (u > 0) { t[m++] = (char) ('0' + u % 10); u = u / 10; }
  while (m > 0) s_chr (s, t[--m]);
  return s;
}
static struct str *s_hex (unsigned long u, int width, int upper)   /* sprintf "%0*x" */
{
  char t[24]; long m = 0; struct str *s = s_of ("");
  char *dg = upper ? "0123456789ABCDEF" : "0123456789abcdef";
  while (u > 0) { t[m++] = dg[u & 15]; u = u >> 4; }
  while (m < width) t[m++] = '0';
  if (m == 0) t[m++] = '0';
  while (m > 0) s_chr (s, t[--m]);
  return s;
}
static int is_space (int c) { return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == 11; }
static int is_digit (int c) { return c >= '0' && c <= '9'; }
static int is_word (int c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'; }
static int is_xdigit (int c) { return is_digit (c) || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'); }
static int lower_of (int c) { return c >= 'A' && c <= 'Z' ? c + 32 : c; }
static int upper_of (int c) { return c >= 'a' && c <= 'z' ? c - 32 : c; }
static struct str *s_lc (struct str *t) { struct str *s = s_dup (t); long i; for (i = 0; i < s->n; i++) s->p[i] = (unsigned char) lower_of (s->p[i]); return s; }
static struct str *s_uc (struct str *t) { struct str *s = s_dup (t); long i; for (i = 0; i < s->n; i++) s->p[i] = (unsigned char) upper_of (s->p[i]); return s; }
static struct str *s_trim (struct str *t)   /* s/^\s+|\s+$//g */
{
  long a = 0, b = t->n;
  while (a < b && is_space (t->p[a])) a++;
  while (b > a && is_space (t->p[b - 1])) b--;
  return s_sub (t, a, b);
}

/* ---- output: stdout through a buffer, stderr at once; Perl's die (its status 255) */
static unsigned char obuf[65536];
static long on;
static void o_flush (void) { long i = 0; while (i < on) { long w = cp_write (1, obuf + i, on - i); if (w <= 0) break; i += w; } on = 0; }
static void o_bytes (unsigned char *p, long n) { while (n > 0) { if (on == 65536) o_flush (); obuf[on++] = *p++; n--; } }
static void o_str (char *s) { o_bytes ((unsigned char *) s, slen (s)); }
static void o_s (struct str *s) { o_bytes (s->p, s->n); }
static void e_bytes (unsigned char *p, long n) { cp_write (2, p, n); }
static void e_str (char *s) { e_bytes ((unsigned char *) s, slen (s)); }
static void e_s (struct str *s) { e_bytes (s->p, s->n); }
static int die_status = 255;
static void die_s (struct str *m) { o_flush (); e_s (m); cp_exit (die_status); }
static void die_c (char *m) { die_s (s_of (m)); }

/* ---- files */
static char *strerror_of (long e)   /* Perl's $! of the errors an open of a file meets */
{
  if (e == 2) return "No such file or directory";
  if (e == 13) return "Permission denied";
  if (e == 20) return "Not a directory";
  if (e == 21) return "Is a directory";
  if (e == 36) return "File name too long";
  if (e == 40) return "Too many levels of symbolic links";
  return "Unknown error";
}
static struct str *read_all (char *path)   /* 0 if it cannot be read */
{
  long fd = s2_open (path);
  struct str *s;
  if (fd < 0) return 0;
  s = alloc (sizeof (struct str));
  s->room = 1 << 16; s->p = alloc (s->room);
  for (;;) {
    long r;
    if (s->n + 65536 + 1 > s->room) { unsigned char *x = alloc (s->room * 2); mcopy (x, s->p, s->n); s->p = x; s->room *= 2; }
    r = s2_read (fd, s->p + s->n, 65536);
    if (r < 0) { s2_close (fd); return 0; }
    if (r == 0) break;
    s->n += r;
  }
  s2_close (fd);
  s->p[s->n] = 0;
  return s;
}
static int f_exists (char *path) { long fd = s2_exists (path); if (fd < 0) return 0; s2_close (fd); return 1; }
static int f_islink (char *path) { unsigned char b[8]; return cp_readlink (path, b, 8) >= 0; }
static struct str *abs_path (char *path)   /* Cwd::abs_path: the path the kernel gives the open file */
{
  long fd = s2_exists (path), n;
  unsigned char b[4096];
  struct str *l;
  if (fd < 0) return 0;
  l = s_of ("/proc/self/fd/"); s_app (l, s_num (fd));
  n = cp_readlink ((char *) l->p, b, 4095);
  s2_close (fd);
  if (n <= 0) return 0;
  return s_new (b, n);
}
static struct str *getcwd_s (void)
{
  unsigned char b[4096];
  long n = cp_readlink ("/proc/self/cwd", b, 4095);
  if (n <= 0) return s_of ("/");
  return s_new (b, n);
}
/* the lines of a text, each with its \n (Perl's <$h>) */
struct lines { struct str **l; long n; };
static struct lines *split_lines (struct str *t)
{
  struct lines *ls = alloc (sizeof (struct lines));
  long i = 0, a = 0, k = 0;
  for (i = 0; i < t->n; i++) if (t->p[i] == '\n') k++;
  ls->l = alloc ((k + 2) * sizeof (struct str *));
  for (i = 0; i < t->n; i++) if (t->p[i] == '\n') { ls->l[ls->n++] = s_sub (t, a, i + 1); a = i + 1; }
  if (a < t->n) ls->l[ls->n++] = s_sub (t, a, t->n);
  return ls;
}
static struct str *chomp (struct str *s) { if (s->n && s->p[s->n - 1] == '\n') return s_sub (s, 0, s->n - 1); return s; }

/* ---- lists of pointers */
struct vec { void **v; long n, room; };
static struct vec *v_new (void) { return alloc (sizeof (struct vec)); }
static void v_push (struct vec *a, void *x)
{
  if (a->n == a->room) { long r = a->room ? a->room * 2 : 8; void **y = alloc (r * sizeof (void *)); long i; for (i = 0; i < a->n; i++) y[i] = a->v[i]; a->v = y; a->room = r; }
  a->v[a->n++] = x;
}
static void *v_pop (struct vec *a) { return a->n ? a->v[--a->n] : 0; }
static void *v_shift (struct vec *a) { void *x; long i; if (!a->n) return 0; x = a->v[0]; for (i = 1; i < a->n; i++) a->v[i - 1] = a->v[i]; a->n--; return x; }
static void v_sort_str (struct vec *a)   /* sort of strings, Perl's cmp */
{
  long x, y;
  for (x = 1; x < a->n; x++) for (y = x; y > 0; y--) {
    struct str *u = a->v[y - 1], *w = a->v[y];
    if (s_cmp (u, w) <= 0) break;
    a->v[y - 1] = w; a->v[y] = u;
  }
}

/* ---- hashes of strings */
struct hent { struct str *k; long iv; void *pv; struct hent *next; };
struct hash { struct hent **b; long nb, n; struct vec *keys; };
static long h_of (unsigned char *p, long n) { unsigned long h = 5381; long i = 0; while (i < n) { h = h * 33 + p[i]; i++; } return (long) (h >> 1); }
static struct hash *h_new (void) { struct hash *h = alloc (sizeof (struct hash)); h->nb = 256; h->b = alloc (h->nb * sizeof (struct hent *)); h->keys = v_new (); return h; }
static struct hent *h_find (struct hash *h, struct str *k)
{
  struct hent *e = h->b[h_of (k->p, k->n) % h->nb];
  while (e) { if (s_eq (e->k, k)) return e; e = e->next; }
  return 0;
}
static struct hent *h_put (struct hash *h, struct str *k)   /* the entry of k, made if it is not there */
{
  struct hent *e = h_find (h, k);
  long i;
  if (e) return e;
  if (h->n > h->nb * 2) {
    long nb = h->nb * 4;
    struct hent **b = alloc (nb * sizeof (struct hent *));
    for (i = 0; i < h->nb; i++) { struct hent *x = h->b[i]; while (x) { struct hent *nx = x->next; long j = h_of (x->k->p, x->k->n) % nb; x->next = b[j]; b[j] = x; x = nx; } }
    h->b = b; h->nb = nb;
  }
  e = alloc (sizeof (struct hent));
  e->k = s_dup (k);
  i = h_of (k->p, k->n) % h->nb;
  e->next = h->b[i]; h->b[i] = e;
  h->n++;
  v_push (h->keys, e);
  return e;
}
static int h_has (struct hash *h, struct str *k) { return h_find (h, k) != 0; }
static int h_hasc (struct hash *h, char *k) { return h_find (h, s_of (k)) != 0; }
static long h_iv (struct hash *h, struct str *k) { struct hent *e = h_find (h, k); return e ? e->iv : 0; }
static void *h_pv (struct hash *h, struct str *k) { struct hent *e = h_find (h, k); return e ? e->pv : 0; }
static void h_set (struct hash *h, struct str *k, long v) { h_put (h, k)->iv = v; }
static void h_setp (struct hash *h, struct str *k, void *v) { h_put (h, k)->pv = v; }
static void h_clear (struct hash *h) { long i; for (i = 0; i < h->nb; i++) h->b[i] = 0; h->n = 0; h->keys = v_new (); }
static struct vec *h_sorted (struct hash *h)   /* sort keys */
{
  struct vec *a = v_new ();
  long i;
  for (i = 0; i < h->keys->n; i++) v_push (a, ((struct hent *) h->keys->v[i])->k);
  v_sort_str (a);
  return a;
}
/* a set of words from a string of them, space-separated (Perl's map { $_ => 1 } qw(...)) */
static struct hash *h_words (char *w)
{
  struct hash *h = h_new ();
  long i = 0, n = slen (w);
  while (i < n) {
    long a;
    while (i < n && w[i] == ' ') i++;
    a = i;
    while (i < n && w[i] != ' ') i++;
    if (i > a) h_set (h, s_new ((unsigned char *) w + a, i - a), 1);
  }
  return h;
}

/* ---- the ff tree (FF.pm's node) and its text (write_txt) */
struct nd { struct str *c; struct vec *k; };
static struct nd *nd_new (struct str *c) { struct nd *x = alloc (sizeof (struct nd)); x->c = c; x->k = v_new (); return x; }
static struct nd *ndc (char *c) { return nd_new (s_of (c)); }
static struct nd *nd_add (struct nd *x, struct nd *y) { v_push (x->k, y); return x; }
static struct nd *nd1 (struct str *c, struct nd *a) { return nd_add (nd_new (c), a); }
static struct nd *nd2 (struct str *c, struct nd *a, struct nd *b) { return nd_add (nd_add (nd_new (c), a), b); }
/* the C layer's words "* pointer" and "& address", made at run time: as
   text in the C they would be words of now in its page, and c2ff then takes
   the whole page for one in the words of now (Words.pm's has_newwords) */
static struct str *w_ptr (void) { struct str *x = s_of ("*"); s_cat (x, " pointer"); return x; }
static struct str *w_addr (void) { struct str *x = s_of ("&"); s_cat (x, " address"); return x; }
static struct nd *ndk (struct nd *x, long i) { return x->k->v[i]; }
static long ndn (struct nd *x) { return x->k->n; }
static void esc_out (struct str *s, struct str *o)
{
  long i;
  if (s->n == 0) { s_cat (o, "\\e"); return; }
  for (i = 0; i < s->n; i++) {
    int c = s->p[i];
    if (c == '\\') s_cat (o, "\\\\");
    else if (c == '\n') s_cat (o, "\\n");
    else if (c < 0x20 || c == 0x7f) { s_cat (o, "\\x"); s_app (o, s_hex (c, 2, 0)); }
    else if (c == ' ' && (i == 0 || i == s->n - 1)) s_cat (o, "\\x20");
    else s_chr (o, c);
  }
}
static void txt_walk (struct nd *x, long depth, struct str *o)
{
  long i;
  for (i = 0; i < depth; i++) s_cat (o, "  ");
  esc_out (x->c, o);
  s_chr (o, '\n');
  for (i = 0; i < ndn (x); i++) txt_walk (ndk (x, i), depth + 1, o);
}
static struct str *write_txt (struct vec *ns)
{
  struct str *o = s_of ("");
  long i;
  for (i = 0; i < ns->n; i++) txt_walk (ns->v[i], 0, o);
  return o;
}

/* ---- regular expressions ---------------------------------------------- */
/* the program: each instruction op, x, y */
#define R_CHAR 1
#define R_ANY 2
#define R_ANYNL 3
#define R_CLASS 4
#define R_BOL 5
#define R_MBOL 6
#define R_EOL 7
#define R_MEOL 8
#define R_ABEG 9
#define R_AEND 10
#define R_WB 11
#define R_NWB 12
#define R_SPLIT 13
#define R_JMP 14
#define R_SAVE 15
#define R_MATCH 16
#define R_LOOK 17
#define R_BREF 18
#define R_PROG 19
#define R_ZEND 20
struct rx { long *op, *x, *y, *z; long n, room; unsigned char *cls; long ncls; long ngroups; long nslots; int ficase, fmulti, fdot, fext; char *src; long srcn; };
/* the parse tree: kinds */
#define A_CHAR 1
#define A_CLASS 2
#define A_ANY 3
#define A_ASSERT 4
#define A_CAT 5
#define A_ALT 6
#define A_GROUP 7
#define A_REP 8
#define A_LOOK 9
#define A_BREF 10
struct ast { int kind; long v, lo, hi; int lazy; struct vec *k; struct ast *sub; long cap; };
static struct rx *R;
static char *P; static long PN, PI;
static long rx_ng;
static struct ast *a_new (int kind) { struct ast *a = alloc (sizeof (struct ast)); a->kind = kind; a->k = v_new (); a->cap = -1; return a; }
static void rx_fail (char *m) { struct str *s = s_of ("s2ff: bad pattern ("); s_cat (s, m); s_cat (s, "): "); s_add (s, (unsigned char *) P, PN); s_cat (s, "\n"); die_s (s); }
static long cls_new (void)
{
  if (R->ncls % 16 == 0) { unsigned char *c = alloc ((R->ncls + 16) * 256); if (R->ncls) mcopy (c, R->cls, R->ncls * 256); R->cls = c; }
  return R->ncls++;
}
static void cls_set (long k, int c) { R->cls[k * 256 + c] = 1; }
static void cls_esc (long k, int e)   /* \s \S \d \D \w \W into a class */
{
  int c;
  for (c = 0; c < 256; c++) {
    int in = e == 's' || e == 'S' ? is_space (c) : e == 'd' || e == 'D' ? is_digit (c) : is_word (c);
    if (e == 'S' || e == 'D' || e == 'W') in = !in;
    if (in) cls_set (k, c);
  }
}
static int hexv (int c) { return c <= '9' ? c - '0' : lower_of (c) - 'a' + 10; }
static int esc_char (int e)   /* the byte of \n \t ... or -1 */
{
  if (e == 'n') return '\n';
  if (e == 't') return '\t';
  if (e == 'r') return '\r';
  if (e == 'f') return '\f';
  if (e == 'e') return 27;
  if (e == 'a') return 7;
  if (e == '0') return 0;
  return -1;
}
static int p_xbyte (void)   /* after \x */
{
  int v = 0, k = 0;
  if (PI < PN && P[PI] == '{') { PI++; while (PI < PN && P[PI] != '}') { v = v * 16 + hexv (P[PI]); PI++; } PI++; return v; }
  while (k < 2 && PI < PN && is_xdigit (P[PI])) { v = v * 16 + hexv (P[PI]); PI++; k++; }
  return v;
}
static void p_skipx (void)   /* /x: blanks and # comments are not the pattern's */
{
  if (!R->fext) return;
  for (;;) {
    while (PI < PN && is_space (P[PI])) PI++;
    if (PI < PN && P[PI] == '#') { while (PI < PN && P[PI] != '\n') PI++; continue; }
    return;
  }
}
static struct ast *p_class (void)
{
  struct ast *a = a_new (A_CLASS);
  long k = cls_new ();
  int neg = 0, first = 1, c, i;
  unsigned char tmp[256];
  if (PI < PN && P[PI] == '^') { neg = 1; PI++; }
  for (i = 0; i < 256; i++) tmp[i] = 0;
  for (;;) {
    int lo;
    if (PI >= PN) rx_fail ("no ]");
    c = (unsigned char) P[PI];
    if (c == ']' && !first) { PI++; break; }
    first = 0;
    PI++;
    if (c == '\\') {
      int e = (unsigned char) P[PI++];
      if (e == 's' || e == 'S' || e == 'd' || e == 'D' || e == 'w' || e == 'W') {
        long t = cls_new (), j;
        cls_esc (t, e);
        for (j = 0; j < 256; j++) if (R->cls[t * 256 + j]) tmp[j] = 1;
        continue;
      }
      if (e == 'x') lo = p_xbyte ();
      else { lo = esc_char (e); if (lo < 0) lo = e; }
    } else lo = c;
    /* a range lo-hi */
    if (PI + 1 < PN && P[PI] == '-' && P[PI + 1] != ']') {
      int hi;
      PI++;
      c = (unsigned char) P[PI++];
      if (c == '\\') { int e = (unsigned char) P[PI++]; if (e == 'x') hi = p_xbyte (); else { hi = esc_char (e); if (hi < 0) hi = e; } }
      else hi = c;
      for (i = lo; i <= hi; i++) tmp[i] = 1;
      continue;
    }
    tmp[lo] = 1;
  }
  if (R->ficase) for (i = 0; i < 256; i++) if (tmp[i]) { tmp[lower_of (i)] = 1; tmp[upper_of (i)] = 1; }
  for (i = 0; i < 256; i++) if (tmp[i] != neg) cls_set (k, i);
  a->v = k;
  return a;
}
static struct ast *p_alt (void);
static struct ast *p_atom (void)
{
  struct ast *a;
  int c;
  p_skipx ();
  c = (unsigned char) P[PI];
  if (c == '(') {
    PI++;
    if (PI < PN && P[PI] == '?') {
      PI++;
      if (P[PI] == ':') { PI++; a = p_alt (); if (P[PI] != ')') rx_fail ("no )"); PI++; return a; }
      if (P[PI] == '|') {   /* branch reset: each alternative's groups from the same number */
        long base = rx_ng, most = rx_ng;
        struct ast *alt = a_new (A_ALT);
        PI++;
        for (;;) {
          struct ast *cat;
          rx_ng = base;
          cat = a_new (A_CAT);
          for (;;) {
            struct ast *q;
            p_skipx ();
            if (PI >= PN || P[PI] == '|' || P[PI] == ')') break;
            q = p_atom ();
            v_push (cat->k, q);
          }
          v_push (alt->k, cat);
          if (rx_ng > most) most = rx_ng;
          if (PI < PN && P[PI] == '|') { PI++; continue; }
          break;
        }
        rx_ng = most;
        if (P[PI] != ')') rx_fail ("no )");
        PI++;
        return alt;
      }
      if (P[PI] == '=' || P[PI] == '!') {
        a = a_new (A_LOOK); a->lo = 0; a->hi = P[PI] == '!'; PI++;
        a->sub = p_alt (); if (P[PI] != ')') rx_fail ("no )"); PI++; return a;
      }
      if (P[PI] == '<' && (P[PI + 1] == '=' || P[PI + 1] == '!')) {
        a = a_new (A_LOOK); a->lo = 1; a->hi = P[PI + 1] == '!'; PI += 2;
        a->sub = p_alt (); if (P[PI] != ')') rx_fail ("no )"); PI++; return a;
      }
      rx_fail ("(? form");
    }
    a = a_new (A_GROUP);
    a->cap = ++rx_ng;
    a->sub = p_alt ();
    if (PI >= PN || P[PI] != ')') rx_fail ("no )");
    PI++;
    return a;
  }
  if (c == '[') { PI++; return p_class (); }
  if (c == '.') { PI++; return a_new (A_ANY); }
  if (c == '^') { PI++; a = a_new (A_ASSERT); a->v = R->fmulti ? R_MBOL : R_BOL; return a; }
  if (c == '$') { PI++; a = a_new (A_ASSERT); a->v = R->fmulti ? R_MEOL : R_EOL; return a; }
  if (c == '\\') {
    int e = (unsigned char) P[PI + 1];
    PI += 2;
    if (e == 's' || e == 'S' || e == 'd' || e == 'D' || e == 'w' || e == 'W') { a = a_new (A_CLASS); a->v = cls_new (); cls_esc (a->v, e); return a; }
    if (e == 'b' || e == 'B' || e == 'A' || e == 'z' || e == 'Z') { a = a_new (A_ASSERT); a->v = e == 'b' ? R_WB : e == 'B' ? R_NWB : e == 'A' ? R_ABEG : e == 'z' ? R_AEND : R_ZEND; return a; }
    if (e >= '1' && e <= '9') { a = a_new (A_BREF); a->v = e - '0'; return a; }
    a = a_new (A_CHAR);
    if (e == 'x') a->v = p_xbyte ();
    else { a->v = esc_char (e); if (a->v < 0) a->v = e; }
    return a;
  }
  PI++;
  a = a_new (A_CHAR); a->v = c;
  return a;
}
static int p_num (long *v) { int any = 0; *v = 0; while (PI < PN && is_digit (P[PI])) { *v = *v * 10 + P[PI] - '0'; PI++; any = 1; } return any; }
static struct ast *p_rep (void)
{
  struct ast *a = p_atom ();
  for (;;) {
    long lo, hi;
    int c;
    p_skipx ();
    if (PI >= PN) break;
    c = P[PI];
    if (c == '*') { lo = 0; hi = -1; PI++; }
    else if (c == '+') { lo = 1; hi = -1; PI++; }
    else if (c == '?') { lo = 0; hi = 1; PI++; }
    else if (c == '{') {
      long save = PI;
      PI++;
      if (!p_num (&lo)) { PI = save; break; }
      hi = lo;
      if (P[PI] == ',') { PI++; if (!p_num (&hi)) hi = -1; }
      if (P[PI] != '}') { PI = save; break; }
      PI++;
    } else break;
    {
      struct ast *r = a_new (A_REP);
      r->sub = a; r->lo = lo; r->hi = hi;
      if (PI < PN && P[PI] == '?') { r->lazy = 1; PI++; }
      else if (PI < PN && P[PI] == '+') PI++;
      a = r;
    }
  }
  return a;
}
static struct ast *p_alt (void)
{
  struct ast *alt = a_new (A_ALT);
  for (;;) {
    struct ast *cat = a_new (A_CAT);
    for (;;) {
      p_skipx ();
      if (PI >= PN || P[PI] == '|' || P[PI] == ')') break;
      v_push (cat->k, p_rep ());
    }
    v_push (alt->k, cat);
    if (PI < PN && P[PI] == '|') { PI++; continue; }
    break;
  }
  return alt;
}
static long r_emit (long op, long x, long y)
{
  if (R->n == R->room) {
    long r = R->room ? R->room * 2 : 64, i;
    long *a = alloc (r * sizeof (long)), *b = alloc (r * sizeof (long)), *c = alloc (r * sizeof (long)), *d = alloc (r * sizeof (long));
    for (i = 0; i < R->n; i++) { a[i] = R->op[i]; b[i] = R->x[i]; c[i] = R->y[i]; d[i] = R->z[i]; }
    R->op = a; R->x = b; R->y = c; R->z = d; R->room = r;
  }
  R->op[R->n] = op; R->x[R->n] = x; R->y[R->n] = y; R->z[R->n] = 0;
  return R->n++;
}
static long a_len (struct ast *a)   /* the fixed length of a lookbehind's pattern, or -1 */
{
  long i, n = 0, m;
  if (a->kind == A_CHAR || a->kind == A_CLASS || a->kind == A_ANY) return 1;
  if (a->kind == A_ASSERT || a->kind == A_LOOK) return 0;
  if (a->kind == A_GROUP) return a_len (a->sub);
  if (a->kind == A_CAT) { for (i = 0; i < a->k->n; i++) { m = a_len (a->k->v[i]); if (m < 0) return -1; n += m; } return n; }
  if (a->kind == A_ALT) { for (i = 0; i < a->k->n; i++) { m = a_len (a->k->v[i]); if (m < 0 || (i && m != n)) return -1; n = m; } return n; }
  if (a->kind == A_REP && a->lo == a->hi) { m = a_len (a->sub); return m < 0 ? -1 : m * a->lo; }
  return -1;
}
static void a_emit (struct ast *a)
{
  long i;
  if (a->kind == A_CHAR) {
    if (R->ficase && lower_of ((int) a->v) != upper_of ((int) a->v)) { long k = cls_new (); cls_set (k, lower_of ((int) a->v)); cls_set (k, upper_of ((int) a->v)); r_emit (R_CLASS, k, 0); }
    else r_emit (R_CHAR, a->v, 0);
  }
  else if (a->kind == A_CLASS) r_emit (R_CLASS, a->v, 0);
  else if (a->kind == A_ANY) r_emit (R->fdot ? R_ANYNL : R_ANY, 0, 0);
  else if (a->kind == A_ASSERT) r_emit (a->v, 0, 0);
  else if (a->kind == A_BREF) r_emit (R_BREF, a->v, 0);
  else if (a->kind == A_CAT) { for (i = 0; i < a->k->n; i++) a_emit (a->k->v[i]); }
  else if (a->kind == A_ALT) {
    long nk = a->k->n, *jumps = alloc ((nk + 1) * sizeof (long));
    for (i = 0; i < nk; i++) {
      if (i < nk - 1) {
        long spos = r_emit (R_SPLIT, 0, 0);
        R->x[spos] = spos + 1;
        a_emit (a->k->v[i]);
        jumps[i] = r_emit (R_JMP, 0, 0);
        R->y[spos] = R->n;
      } else a_emit (a->k->v[i]);
    }
    for (i = 0; i < nk - 1; i++) R->x[jumps[i]] = R->n;
  }
  else if (a->kind == A_GROUP) { r_emit (R_SAVE, 2 * a->cap, 0); a_emit (a->sub); r_emit (R_SAVE, 2 * a->cap + 1, 0); }
  else if (a->kind == A_LOOK) {
    long at = r_emit (R_LOOK, 0, 0), len = 0;
    if (a->lo) { len = a_len (a->sub); if (len < 0) rx_fail ("lookbehind of no fixed length"); }
    a_emit (a->sub);
    r_emit (R_MATCH, 0, 0);
    R->x[at] = a->hi;   /* negative */
    R->y[at] = R->n;    /* after it */
    R->z[at] = a->lo ? len : -1;
  }
  else if (a->kind == A_REP) {
    long k;
    for (k = 0; k < a->lo; k++) a_emit (a->sub);
    if (a->hi < 0) {
      long slot = R->nslots++;
      long spos = r_emit (R_SPLIT, 0, 0), mark;
      mark = r_emit (R_SAVE, slot, 1);
      a_emit (a->sub);
      r_emit (R_PROG, slot, 0);
      r_emit (R_JMP, spos, 0);
      if (a->lazy) { R->x[spos] = R->n; R->y[spos] = mark; } else { R->x[spos] = mark; R->y[spos] = R->n; }
    } else {
      long nopt = a->hi - a->lo, *sps = alloc ((nopt + 1) * sizeof (long));
      for (k = 0; k < nopt; k++) {
        sps[k] = r_emit (R_SPLIT, 0, 0);
        a_emit (a->sub);
      }
      for (k = 0; k < nopt; k++) { if (a->lazy) { R->x[sps[k]] = R->n; R->y[sps[k]] = sps[k] + 1; } else { R->x[sps[k]] = sps[k] + 1; R->y[sps[k]] = R->n; } }
    }
  }
}
/* a pattern and its flags (i m s x) compiled */
static struct rx *rx_comp (char *pat, long n, char *flags)
{
  struct ast *a;
  long i;
  R = alloc (sizeof (struct rx));
  for (i = 0; flags[i]; i++) { if (flags[i] == 'i') R->ficase = 1; if (flags[i] == 'm') R->fmulti = 1; if (flags[i] == 's') R->fdot = 1; if (flags[i] == 'x') R->fext = 1; }
  P = pat; PN = n; PI = 0; rx_ng = 0;
  R->src = pat; R->srcn = n;
  a = p_alt ();
  if (PI != PN) rx_fail ("unmatched )");
  R->ngroups = rx_ng;
  R->nslots = 2 * (rx_ng + 1);
  r_emit (R_SAVE, 0, 0);
  a_emit (a);
  r_emit (R_SAVE, 1, 0);
  r_emit (R_MATCH, 0, 0);
  return R;
}
/* the patterns of the program's text, compiled once each (by the address of their text) */
#define RXC 4096
static char *rxc_pat[RXC];
static char *rxc_fl[RXC];
static struct rx *rxc_rx[RXC];
static struct rx *rx_get (char *pat, char *flags)
{
  long h = (long) (((unsigned long) pat >> 3) % RXC), i;
  for (i = 0; i < RXC; i++) {
    long j = (h + i) % RXC;
    if (!rxc_pat[j]) { rxc_pat[j] = pat; rxc_fl[j] = flags; rxc_rx[j] = rx_comp (pat, slen (pat), flags); return rxc_rx[j]; }
    if (rxc_pat[j] == pat && rxc_fl[j] == flags) return rxc_rx[j];
  }
  return rx_comp (pat, slen (pat), flags);
}
/* the match: captures in rc[] (-1 where a group took no part) */
#define RCMAX 64
static long rc[RCMAX];
static unsigned char *rs; static long rsn;
static long *bst_a, *bst_b, *bst_c; static long bst_n, bst_room;
static void bpush (long a, long b, long c)
{
  if (bst_n == bst_room) {
    long r = bst_room ? bst_room * 2 : 4096, i;
    long *x = alloc (r * sizeof (long)), *y = alloc (r * sizeof (long)), *z = alloc (r * sizeof (long));
    for (i = 0; i < bst_n; i++) { x[i] = bst_a[i]; y[i] = bst_b[i]; z[i] = bst_c[i]; }
    bst_a = x; bst_b = y; bst_c = z; bst_room = r;
  }
  bst_a[bst_n] = a; bst_b[bst_n] = b; bst_c[bst_n] = c; bst_n++;
}
static long *slots;
static long nslots_room;
static int wordat (long i) { return i >= 0 && i < rsn && is_word (rs[i]); }
/* run r from pc at sp: the end of the match, or -1 (slots[] set) */
static long rx_run (struct rx *r, long pcx, long spos)
{
  long base = bst_n;
  for (;;) {
    long op = r->op[pcx];
    int ok = 1;
    if (op == R_CHAR) { if (spos < rsn && rs[spos] == r->x[pcx]) { spos++; pcx++; } else ok = 0; }
    else if (op == R_CLASS) { if (spos < rsn && r->cls[r->x[pcx] * 256 + rs[spos]]) { spos++; pcx++; } else ok = 0; }
    else if (op == R_ANY) { if (spos < rsn && rs[spos] != '\n') { spos++; pcx++; } else ok = 0; }
    else if (op == R_ANYNL) { if (spos < rsn) { spos++; pcx++; } else ok = 0; }
    else if (op == R_BOL || op == R_ABEG) { if (spos == 0) pcx++; else ok = 0; }
    else if (op == R_MBOL) { if (spos == 0 || (rs[spos - 1] == '\n' && spos < rsn)) pcx++; else ok = 0; }
    else if (op == R_EOL || op == R_ZEND) { if (spos == rsn || (spos == rsn - 1 && rs[spos] == '\n')) pcx++; else ok = 0; }
    else if (op == R_MEOL) { if (spos == rsn || rs[spos] == '\n') pcx++; else ok = 0; }
    else if (op == R_AEND) { if (spos == rsn) pcx++; else ok = 0; }
    else if (op == R_WB || op == R_NWB) { int b = wordat (spos - 1) != wordat (spos); if (b == (op == R_WB)) pcx++; else ok = 0; }
    else if (op == R_JMP) pcx = r->x[pcx];
    else if (op == R_SPLIT) { bpush (0, r->y[pcx], spos); pcx = r->x[pcx]; }
    else if (op == R_SAVE) { bpush (1, r->x[pcx], slots[r->x[pcx]]); slots[r->x[pcx]] = spos; pcx++; }
    else if (op == R_PROG) { if (slots[r->x[pcx]] == spos) ok = 0; else pcx++; }
    else if (op == R_BREF) {
      long a = slots[2 * r->x[pcx]], b = slots[2 * r->x[pcx] + 1];
      if (a < 0 || b < 0) ok = 0;
      else if (spos + (b - a) <= rsn && msame (rs + a, rs + spos, b - a)) { spos += b - a; pcx++; }
      else ok = 0;
    }
    else if (op == R_LOOK) {
      long at = r->z[pcx] < 0 ? spos : spos - r->z[pcx], e = -1, save = bst_n;
      if (at >= 0) e = rx_run (r, pcx + 1, at);
      /* (the stack above it is the look's own: what it saved undone) */
      while (bst_n > save) { bst_n--; if (bst_a[bst_n] == 1) slots[bst_b[bst_n]] = bst_c[bst_n]; }
      if ((e >= 0) != (r->x[pcx] != 0)) pcx = r->y[pcx]; else ok = 0;
    }
    else if (op == R_MATCH) { return spos; }
    if (!ok) {
      for (;;) {
        if (bst_n == base) return -1;
        bst_n--;
        if (bst_a[bst_n] == 1) { slots[bst_b[bst_n]] = bst_c[bst_n]; continue; }
        pcx = bst_b[bst_n]; spos = bst_c[bst_n];
        break;
      }
    }
  }
}
static long rx_ngroups;
/* r on s from start: whether it matches; rc[] its groups */
static int rx_exec (struct rx *r, unsigned char *s, long n, long start)
{
  long i, at;
  if (r->nslots > nslots_room) { nslots_room = r->nslots * 2; slots = alloc (nslots_room * sizeof (long)); }
  rs = s; rsn = n;
  for (at = start; at <= n; at++) {
    long e;
    for (i = 0; i < r->nslots; i++) slots[i] = -1;
    bst_n = 0;
    e = rx_run (r, 0, at);
    if (e >= 0) {
      for (i = 0; i < 2 * (r->ngroups + 1) && i < RCMAX; i++) rc[i] = slots[i];
      for (; i < RCMAX; i++) rc[i] = -1;
      rx_ngroups = r->ngroups;
      return 1;
    }
    if (r->op[1] == R_ABEG || r->op[1] == R_BOL) break;
  }
  return 0;
}
static unsigned char *g_s;   /* the subject of the last match */
/* s =~ /pat/flags */
static int mf (struct str *s, char *pat, char *flags) { g_s = s->p; return rx_exec (rx_get (pat, flags), s->p, s->n, 0); }
static int m (struct str *s, char *pat) { return mf (s, pat, ""); }
static int mc (char *s, char *pat) { return m (s_of (s), pat); }
/* group i of the last match, or 0 where it took no part */
static struct str *g (long i) { if (rc[2 * i] < 0 || rc[2 * i + 1] < 0) return 0; return s_new (g_s + rc[2 * i], rc[2 * i + 1] - rc[2 * i]); }
static int gdef (long i) { return rc[2 * i] >= 0 && rc[2 * i + 1] >= 0; }
static struct str *g0 (long i) { struct str *x = g (i); return x ? x : s_of (""); }
/* the groups of the last match, saved */
struct caps { long c[RCMAX]; unsigned char *s; };
static struct caps *caps_save (void) { struct caps *c = alloc (sizeof (struct caps)); long i; for (i = 0; i < RCMAX; i++) c->c[i] = rc[i]; c->s = g_s; return c; }
static void caps_load (struct caps *c) { long i; for (i = 0; i < RCMAX; i++) rc[i] = c->c[i]; g_s = c->s; }
/* the text of a replacement: $1..$9 and ${N} of the match, \\ \$ \n \t */
static void repl_add (struct str *o, char *t)
{
  long i = 0;
  while (t[i]) {
    if (t[i] == '$' && is_digit (t[i + 1])) { struct str *x = g (t[i + 1] - '0'); if (x) s_app (o, x); i += 2; continue; }
    if (t[i] == '\\' && t[i + 1]) { int e = esc_char (t[i + 1]); s_chr (o, e >= 0 ? e : t[i + 1]); i += 2; continue; }
    s_chr (o, t[i]); i++;
  }
}
/* s/pat/repl/flags (g: every match), a new string; *count how many */
static long subst_count;
static struct str *ssub (struct str *s, char *pat, char *flags, char *repl)
{
  int gl = 0, i;
  struct rx *r;
  struct str *o = s_of ("");
  long at = 0, last = 0;
  for (i = 0; flags[i]; i++) if (flags[i] == 'g') gl = 1;
  r = rx_get (pat, flags);   /* (g is not a pattern flag: rx_comp ignores it) */
  subst_count = 0;
  g_s = s->p;
  while (at <= s->n && rx_exec (r, s->p, s->n, at)) {
    long a = rc[0], b = rc[1];
    s_add (o, s->p + last, a - last);
    repl_add (o, repl);
    subst_count++;
    last = b;
    if (b == a) { if (a < s->n) s_chr (o, s->p[a]); last = a + 1; at = a + 1; } else at = b;
    if (!gl) break;
  }
  if (last < s->n) s_add (o, s->p + last, s->n - last);
  return o;
}
/* split /pat/, s (Perl's: trailing empty fields gone; limit -1 keeps them) */
static struct vec *ssplit (char *pat, struct str *s, int keep)
{
  struct vec *v = v_new ();
  struct rx *r = rx_get (pat, "");
  long at = 0, last = 0;
  if (s->n == 0) return v;
  while (at < s->n && rx_exec (r, s->p, s->n, at)) {
    long a = rc[0], b = rc[1];
    if (b == a) { if (a >= s->n) break; if (a == 0) { at = 1; continue; } }
    if (a == 0 && b > 0 && last == 0 && v->n == 0) { v_push (v, s_of ("")); last = b; at = b; continue; }
    v_push (v, s_sub (s, last, a));
    last = b;
    at = b > a ? b : a + 1;
  }
  v_push (v, s_sub (s, last, s->n));
  if (!keep) while (v->n && ((struct str *) v->v[v->n - 1])->n == 0) v->n--;
  return v;
}
/* \Q...\E: the bytes of t as a pattern of themselves */
static struct str *rx_quote (struct str *t)
{
  struct str *o = s_of ("");
  long i;
  for (i = 0; i < t->n; i++) { if (!is_word (t->p[i])) s_chr (o, '\\'); s_chr (o, t->p[i]); }
  return o;
}
/* a pattern made at run time (not cached) */
static int mdyn (struct str *s, struct str *pat, char *flags) { g_s = s->p; return rx_exec (rx_comp ((char *) pat->p, pat->n, flags), s->p, s->n, 0); }
