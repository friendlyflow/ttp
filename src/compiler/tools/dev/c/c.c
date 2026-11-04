/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* c.c: dev source of tools/c.ff, the C parser's library: nodes, output,
   the lexer of a gcc-preprocessed .i and a recursive-descent parser of GNU C
   as glibc writes it, its parse tree a tree of nodes (see cparse.ff's
   comment for the shapes). */
#include "c.h"

/* ---- tokens and names ---- */
enum { T_EOF, T_ID, T_NUM, T_CHR, T_STR, T_P, T_DIR };
enum {
  P_ELL, P_SHLEQ, P_SHREQ, P_ARROW, P_INC, P_DEC, P_SHL, P_SHR, P_LE, P_GE, P_EQ, P_NE, P_ANDAND, P_OROR,
  P_MULEQ, P_DIVEQ, P_MODEQ, P_ADDEQ, P_SUBEQ, P_ANDEQ, P_OREQ, P_XOREQ, P_HASHHASH,
  P_LBRACK, P_RBRACK, P_LPAR, P_RPAR, P_LBRACE, P_RBRACE, P_DOT, P_AMP, P_STAR, P_PLUS, P_MINUS,
  P_TILDE, P_NOT, P_DIV, P_MOD, P_LT, P_GT, P_XOR, P_OR, P_QUEST, P_COLON, P_SEMI, P_ASSIGN,
  P_COMMA, P_HASH, P_AT, P_N
};
static char *ptext[] = {
  "...", "<<=", ">>=", "->", "++", "--", "<<", ">>", "<=", ">=", "==", "!=", "&&", "||",
  "*=", "/=", "%=", "+=", "-=", "&=", "|=", "^=", "##",
  "[", "]", "(", ")", "{", "}", ".", "&", "*", "+", "-",
  "~", "!", "/", "%", "<", ">", "^", "|", "?", ":", ";", "=",
  ",", "#", "@"
};

/* keywords: a class each */
enum {
  K_NONE, K_STORAGE, K_QUAL, K_FUNC, K_TYPE, K_STRUCT, K_ENUM, K_TYPEOF, K_ALIGNAS, K_BITINT, K_ATOMIC,
  K_ATTR, K_EXT, K_ASM, K_SIZEOF, K_REAL, K_GENERIC, K_OFFSETOF, K_VAARG, K_TYPESCOMPAT, K_CONVERT,
  K_STATICASSERT, K_LABEL, K_IF, K_ELSE, K_WHILE, K_DO, K_FOR, K_SWITCH, K_CASE, K_DEFAULT, K_GOTO,
  K_CONTINUE, K_BREAK, K_RETURN, K_TYPEDEF
};
static char *kwords[] = {
  "typedef", "extern", "static", "auto", "register", "__thread", "_Thread_local", "thread_local",
  "const", "__const", "__const__", "volatile", "__volatile", "__volatile__", "restrict", "__restrict", "__restrict__",
  "__seg_fs", "__seg_gs",
  "inline", "__inline", "__inline__", "_Noreturn",
  "void", "char", "short", "int", "long", "float", "double", "signed", "__signed", "__signed__", "unsigned",
  "_Bool", "_Complex", "__complex", "__complex__", "_Imaginary", "__int128", "_Float16", "_Float32", "_Float64",
  "_Float128", "_Float32x", "_Float64x", "_Float128x", "__float128", "__float80", "__ibm128", "__fp16", "__bf16",
  "_Decimal32", "_Decimal64", "_Decimal128", "__auto_type", "bool", "constexpr",
  "struct", "union", "enum", "typeof", "__typeof", "__typeof__", "typeof_unqual", "__typeof_unqual__",
  "_Alignas", "alignas", "_BitInt", "_Atomic", "__attribute__", "__attribute", "__extension__",
  "asm", "__asm", "__asm__", "sizeof", "_Alignof", "alignof", "__alignof", "__alignof__",
  "__real__", "__real", "__imag__", "__imag", "_Generic", "__builtin_offsetof", "__builtin_va_arg",
  "__builtin_types_compatible_p", "__builtin_convertvector", "_Static_assert", "static_assert", "__label__",
  "if", "else", "while", "do", "for", "switch", "case", "default", "goto", "continue", "break", "return", 0
};
static int kclass[] = {
  K_TYPEDEF, K_STORAGE, K_STORAGE, K_STORAGE, K_STORAGE, K_STORAGE, K_STORAGE, K_STORAGE,
  K_QUAL, K_QUAL, K_QUAL, K_QUAL, K_QUAL, K_QUAL, K_QUAL, K_QUAL, K_QUAL,
  K_QUAL, K_QUAL,
  K_FUNC, K_FUNC, K_FUNC, K_FUNC,
  K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE,
  K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE,
  K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE,
  K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_TYPE, K_STORAGE,
  K_STRUCT, K_STRUCT, K_ENUM, K_TYPEOF, K_TYPEOF, K_TYPEOF, K_TYPEOF, K_TYPEOF,
  K_ALIGNAS, K_ALIGNAS, K_BITINT, K_ATOMIC, K_ATTR, K_ATTR, K_EXT,
  K_ASM, K_ASM, K_ASM, K_SIZEOF, K_SIZEOF, K_SIZEOF, K_SIZEOF, K_SIZEOF,
  K_REAL, K_REAL, K_REAL, K_REAL, K_GENERIC, K_OFFSETOF, K_VAARG,
  K_TYPESCOMPAT, K_CONVERT, K_STATICASSERT, K_STATICASSERT, K_LABEL,
  K_IF, K_ELSE, K_WHILE, K_DO, K_FOR, K_SWITCH, K_CASE, K_DEFAULT, K_GOTO, K_CONTINUE, K_BREAK, K_RETURN
};

struct sym { unsigned char *p; long len; int kw; int istype; int level; };
struct tok { int kind; int id; long len; unsigned char *p; long ln; struct sym *sym; };
struct binding { struct sym *s; int istype; int level; };

/* what the tree does not show, by node: where a statement or a name begins, a parenthesized expression's parentheses */
struct cmark { struct node *n; long off; long parens; };
struct cstate {
  unsigned char *obuf; long on;
  struct tok *toks; long ntok; long room; long at;
  struct sym **tab; long tabn; long nsym;
  struct binding *undo; long nundo; long roomundo; int level;
  char *name;
  struct node *none;
  unsigned char *src;
  struct cmark *marks; long nmarks; long roommarks;
};
static struct cstate *S;

/* ---- the marks ---- */
static struct cmark *mark_of (struct node *n, int make)
{
  long at, m;
  if (!S->roommarks) { S->roommarks = 4096; while (S->roommarks < S->ntok / 2) S->roommarks = S->roommarks * 2; S->marks = alloc (S->roommarks * sizeof (struct cmark)); }
  if (make && (S->nmarks + 1) * 2 > S->roommarks) {
    struct cmark *o = S->marks;
    long oldn = S->roommarks, i = 0;
    S->roommarks = oldn * 2;
    S->marks = alloc (S->roommarks * sizeof (struct cmark));
    while (i < oldn) {
      if (o[i].n) {
        at = ((long) o[i].n >> 4) & (S->roommarks - 1);
        while (S->marks[at].n) at = (at + 1) & (S->roommarks - 1);
        S->marks[at] = o[i];
      }
      i++;
    }
  }
  m = S->roommarks - 1;
  at = ((long) n >> 4) & m;
  while (S->marks[at].n && S->marks[at].n != n) at = (at + 1) & m;
  if (!S->marks[at].n) {
    if (!make) return 0;
    S->marks[at].n = n;
    S->nmarks++;
  }
  return &S->marks[at];
}
long c_off_of (struct node *n) { struct cmark *c = mark_of (n, 0); if (c) return c->off; return 0; }
long c_parens_of (struct node *n) { struct cmark *c = mark_of (n, 0); if (c) return c->parens; return 0; }
static void mark_off (struct node *n, unsigned char *p) { struct cmark *c = mark_of (n, 1); if (!c->off) c->off = p - S->src + 1; }
static void mark_paren (struct node *n) { struct cmark *c = mark_of (n, 1); c->parens = c->parens + 1; }

/* ---- small things ---- */
long cstrlen (char *s) { long n = 0; while (s[n]) n++; return n; }
int same (unsigned char *p, long n, char *s)
{
  long i = 0;
  while (i < n) { if (s[i] == 0 || p[i] != (unsigned char) s[i]) return 0; i++; }
  return s[n] == 0;
}
static void copy (unsigned char *d, unsigned char *s, long n) { long i = 0; while (i < n) { d[i] = s[i]; i++; } }

static void st_init (void)
{
  if (S) return;
  S = alloc (sizeof (struct cstate));
  S->obuf = alloc (65536);
}
/* a unit's parser state: its marks are read after its parse; the output buffer stays */
void *c_state_get (void) { return S; }
void c_state_set (void *x)
{
  struct cstate *n = x;
  if (S && n != S) { n->obuf = S->obuf; n->on = S->on; }
  S = n;
}
void c_state_new (void)
{
  struct cstate *o = S;
  S = alloc (sizeof (struct cstate));
  /* (and the tokens' array: nothing reads the tokens after a parse) */
  if (o) { S->obuf = o->obuf; S->on = o->on; S->toks = o->toks; S->room = o->room; }
  else S->obuf = alloc (65536);
}
void out_flush (void)
{
  long p = 0;
  while (p < S->on) {
    long w = cp_write (1, S->obuf + p, S->on - p);
    if (w <= 0) { err_str ("cannot write the output\n"); cp_exit (1); }
    p += w;
  }
  S->on = 0;
}
void out_bytes (unsigned char *p, long n)
{
  st_init ();
  if (S->on + n > 65536) out_flush ();
  if (n > 65536) { long w = 0; while (w < n) { long k = cp_write (1, p + w, n - w); if (k <= 0) c_fail ("cannot write the output"); w += k; } return; }
  copy (S->obuf + S->on, p, n);
  S->on += n;
}
void out_str (char *s) { out_bytes ((unsigned char *) s, cstrlen (s)); }
static long numtext (long v, unsigned char *b)
{
  unsigned char t[24];
  long n = 0, k = 0;
  int neg = v < 0;
  if (v == 0) t[n++] = '0';
  while (v != 0) { long d = v % 10; if (d < 0) d = -d; t[n++] = '0' + d; v = v / 10; }
  if (neg) b[k++] = '-';
  while (n > 0) b[k++] = t[--n];
  return k;
}
void out_num (long v) { unsigned char b[24]; out_bytes (b, numtext (v, b)); }
void err_bytes (unsigned char *p, long n) { cp_write (2, p, n); }
void err_str (char *s) { err_bytes ((unsigned char *) s, cstrlen (s)); }
void err_num (long v) { unsigned char b[24]; err_bytes (b, numtext (v, b)); }
void c_fail (char *s)
{
  err_str ("cparse: ");
  if (S && S->name) { err_str (S->name); err_str (": "); }
  err_str (s);
  err_str ("\n");
  cp_exit (1);
}

/* ---- nodes ---- */
struct node *nd_text (unsigned char *p, long n)
{
  struct node *k = alloc (sizeof (struct node));
  k->text = p;
  k->len = n;
  return k;
}
struct node *nd (char *kind) { return nd_text ((unsigned char *) kind, cstrlen (kind)); }
void nd_add (struct node *n, struct node *k)
{
  if (n->count == n->room) {
    long more = n->room * 2 + 4, i = 0;
    struct node **ks = alloc (more * sizeof (struct node *));
    while (i < n->count) { ks[i] = n->kids[i]; i++; }
    n->kids = ks;
    n->room = more;
  }
  n->kids[n->count] = k;
  n->count++;
}
struct node *nd_kid (struct node *n, long i) { return i < n->count ? n->kids[i] : 0; }
int nd_is (struct node *n, char *s) { return n && same (n->text, n->len, s); }
int nd_leaf (struct node *n) { return n->count == 0; }
static int is_layer (struct node *n)
{
  long i = 0;
  if (n->len < 2 || n->text[n->len - 1] != ':') return 0;
  while (i < n->len - 1) { if (n->text[i] < '0' || n->text[i] > '9') return 0; i++; }
  return 1;
}
/* FF.pm's layers: a node of more than 255 children holds them in layers
   0: 1: ..., 255 each (255 * 255 each a level deeper) */
static void layers_of (struct node *n, struct node **k, long c)
{
  long per = 255, i = 0, l = 0;
  if (c <= 255) { long j = 0; while (j < c) { nd_add (n, k[j]); j++; } return; }
  while (c > per * 255) per = per * 255;
  while (i < c) {
    long e = i + per < c ? i + per : c;
    unsigned char b[24];
    long m = numtext (l, b);
    unsigned char *t = alloc (m + 1);
    struct node *y;
    copy (t, b, m);
    t[m] = ':';
    y = nd_text (t, m + 1);
    layers_of (y, k + i, e - i);
    nd_add (n, y);
    l++;
    i = e;
  }
}
void nd_layer (struct node *n)
{
  long i = 0;
  while (i < n->count) { nd_layer (n->kids[i]); i++; }
  if (n->count > 255) {
    struct node **k = n->kids;
    long c = n->count;
    n->kids = 0; n->count = 0; n->room = 0;
    layers_of (n, k, c);
  }
}
static void flat_into (struct node *to, struct node *n)
{
  long i = 0;
  while (i < n->count) {
    struct node *k = n->kids[i];
    if (is_layer (k)) flat_into (to, k); else nd_add (to, k);
    i++;
  }
}
/* the children through their layers, at every level */
void nd_flat (struct node *n)
{
  long i = 0, has = 0;
  while (i < n->count) { if (is_layer (n->kids[i])) has = 1; i++; }
  if (has) {
    struct node t;
    t.count = 0; t.room = 0; t.kids = 0;
    flat_into (&t, n);
    n->kids = t.kids; n->count = t.count; n->room = t.room;
  }
  i = 0;
  while (i < n->count) { nd_flat (n->kids[i]); i++; }
}

/* ---- names ---- */
static long hashof (unsigned char *p, long n)
{
  long h = 5381, i = 0;
  while (i < n) { h = (h * 33 + p[i]) & 0xfffffff; i++; }
  return h;
}
static struct sym *intern (unsigned char *p, long n)
{
  long i;
  if (S->nsym * 2 >= S->tabn) {
    long m = S->tabn ? S->tabn * 2 : 4096, j = 0;
    struct sym **t = alloc (m * sizeof (struct sym *));
    while (j < S->tabn) {
      struct sym *s = S->tab[j];
      if (s) { long k = hashof (s->p, s->len) & (m - 1); while (t[k]) k = (k + 1) & (m - 1); t[k] = s; }
      j++;
    }
    S->tab = t;
    S->tabn = m;
  }
  i = hashof (p, n) & (S->tabn - 1);
  while (S->tab[i]) {
    struct sym *s = S->tab[i];
    if (s->len == n) { long j = 0; while (j < n && s->p[j] == p[j]) j++; if (j == n) return s; }
    i = (i + 1) & (S->tabn - 1);
  }
  {
    struct sym *s = alloc (sizeof (struct sym));
    s->p = p; s->len = n;
    S->tab[i] = s;
    S->nsym++;
    return s;
  }
}
static void bind_sym (struct sym *s, int ty)
{
  if (S->nundo == S->roomundo) {
    long m = S->roomundo * 2 + 64, i = 0;
    struct binding *u = alloc (m * sizeof (struct binding));
    while (i < S->nundo) { u[i] = S->undo[i]; i++; }
    S->undo = u;
    S->roomundo = m;
  }
  S->undo[S->nundo].s = s;
  S->undo[S->nundo].istype = s->istype;
  S->undo[S->nundo].level = s->level;
  S->nundo++;
  s->istype = ty;
  s->level = S->level;
}
static long scope_in (void) { S->level++; return S->nundo; }
static void scope_out (long mark)
{
  while (S->nundo > mark) {
    struct binding *b = &S->undo[--S->nundo];
    b->s->istype = b->istype;
    b->s->level = b->level;
  }
  S->level--;
}

/* ---- the lexer ---- */
static void push_tok (int kind, int id, unsigned char *p, long n, long ln)
{
  struct tok *t;
  if (S->ntok == S->room) {
    long m = S->room * 2 + 1024, i = 0;
    struct tok *a = alloc (m * sizeof (struct tok));
    while (i < S->ntok) { a[i] = S->toks[i]; i++; }
    S->toks = a;
    S->room = m;
  }
  t = &S->toks[S->ntok++];
  t->kind = kind; t->id = id; t->p = p; t->len = n; t->ln = ln; t->sym = 0;
  if (kind == T_ID) t->sym = intern (p, n);
}
static int idch (unsigned char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '$' || (c >= '0' && c <= '9') || c >= 128; }
static int digit (unsigned char c) { return c >= '0' && c <= '9'; }
static void lex (unsigned char *s, long n)
{
  long i = 0, ln = 1;
  int bol = 1;
  while (i < n) {
    unsigned char c = s[i];
    long j;
    if (c == '\n') { ln++; i++; bol = 1; continue; }
    if (c == ' ' || c == '\t' || c == '\r' || c == '\f' || c == '\v') { i++; continue; }
    if (c == '\\' && i + 1 < n && s[i + 1] == '\n') { i += 2; ln++; continue; }
    if (c == '#' && bol) {
      long e;
      j = i + 1;
      while (j < n && (s[j] == ' ' || s[j] == '\t')) j++;
      e = j;
      while (e < n && s[e] != '\n') e++;
      if ((j < n && digit (s[j])) || (e - j >= 4 && same (s + j, 4, "line"))) { i = e; continue; }
      j = e;
      while (j > i && (s[j - 1] == ' ' || s[j - 1] == '\t' || s[j - 1] == '\r')) j--;
      push_tok (T_DIR, 0, s + i, j - i, ln);
      i = e;
      continue;
    }
    bol = 0;
    j = i;
    if (c == 'L' || c == 'U' || c == 'u') {
      j = i + 1;
      if (c == 'u' && j < n && s[j] == '8') j++;
      if (j < n && (s[j] == '\'' || s[j] == '"')) c = s[j]; else j = i;
    }
    if (c == '\'' || c == '"') {
      unsigned char q = c;
      j++;
      while (j < n && s[j] != q) { if (s[j] == '\\') j++; if (j < n && s[j] == '\n') c_fail ("a newline in a literal"); j++; }
      if (j >= n) c_fail ("a literal without its end");
      j++;
      push_tok (q == '"' ? T_STR : T_CHR, 0, s + i, j - i, ln);
      i = j;
      continue;
    }
    if (digit (c) || (c == '.' && i + 1 < n && digit (s[i + 1]))) {
      j = i + 1;
      while (j < n) {
        unsigned char d = s[j];
        if ((d == '+' || d == '-') && (s[j - 1] == 'e' || s[j - 1] == 'E' || s[j - 1] == 'p' || s[j - 1] == 'P')) { j++; continue; }
        if (d == '\'' && j + 1 < n && idch (s[j + 1])) { j += 2; continue; }
        if (idch (d) || d == '.') { j++; continue; }
        break;
      }
      push_tok (T_NUM, 0, s + i, j - i, ln);
      i = j;
      continue;
    }
    if (idch (c)) {
      j = i + 1;
      while (j < n && idch (s[j])) j++;
      push_tok (T_ID, 0, s + i, j - i, ln);
      i = j;
      continue;
    }
    {
      int k = 0, found = -1;
      while (k < P_N) {
        char *t = ptext[k];
        long m = cstrlen (t);
        if (i + m <= n) { long q = 0; while (q < m && s[i + q] == (unsigned char) t[q]) q++; if (q == m) { found = k; break; } }
        k++;
      }
      if (found < 0) { err_str ("cparse: ln "); err_num (ln); err_str (": "); c_fail ("a byte that starts no token"); }
      push_tok (T_P, found, s + i, cstrlen (ptext[found]), ln);
      i += cstrlen (ptext[found]);
    }
  }
  push_tok (T_EOF, 0, s + n, 0, ln);
}

/* ---- the parser's tokens ---- */
static struct tok *tk (long k) { long i = S->at + k; return i < S->ntok ? &S->toks[i] : &S->toks[S->ntok - 1]; }
static int isp (long k, int id) { struct tok *t = tk (k); return t->kind == T_P && t->id == id; }
static int kw (long k) { struct tok *t = tk (k); return t->kind == T_ID ? t->sym->kw : K_NONE; }
static int iskw (long k, char *w) { struct tok *t = tk (k); return t->kind == T_ID && same (t->p, t->len, w); }
static void perr (char *what)
{
  struct tok *t = tk (0);
  err_str ("cparse: ");
  if (S->name) { err_str (S->name); err_str (":"); }
  err_num (t->ln);
  err_str (": ");
  err_str (what);
  err_str (" at '");
  err_bytes (t->p, t->len > 60 ? 60 : t->len);
  err_str ("'\n");
  cp_exit (1);
}
static void next (void) { if (S->at < S->ntok - 1) S->at++; }
static void expect (int id)
{
  if (!isp (0, id)) {
    unsigned char m[40];
    char *w = "expected ";
    long i = 0, k = 0;
    while (w[i]) { m[k++] = w[i]; i++; }
    i = 0;
    while (ptext[id][i]) { m[k++] = ptext[id][i]; i++; }
    m[k] = 0;
    perr ((char *) m);
  }
  next ();
}
static int is_typename (long k) { struct tok *t = tk (k); return t->kind == T_ID && t->sym->kw == K_NONE && t->sym->istype; }

/* UTF-8, strictly: no overlong form, no surrogate, at most 0x10ffff; the
   length of the form at p, 0 if none */
static long utf8_at (unsigned char *p, long n)
{
  unsigned char c = p[0];
  long m, i;
  if (c < 0x80) return 1;
  if (c >= 0xc2 && c <= 0xdf) m = 2;
  else if (c >= 0xe0 && c <= 0xef) m = 3;
  else if (c >= 0xf0 && c <= 0xf4) m = 4;
  else return 0;
  if (m > n) return 0;
  i = 1;
  while (i < m) { if ((p[i] & 0xc0) != 0x80) return 0; i++; }
  if (c == 0xe0 && p[1] < 0xa0) return 0;
  if (c == 0xed && p[1] >= 0xa0) return 0;
  if (c == 0xf0 && p[1] < 0x90) return 0;
  if (c == 0xf4 && p[1] >= 0x90) return 0;
  return m;
}
/* a token as a node: its bytes (a narrow literal's bytes that are not
   UTF-8 as octal escapes, the same bytes to C), in pieces of up to 255 under
   a node "token" if longer */
static struct node *tok_node (struct tok *t)
{
  unsigned char *p = t->p;
  long n = t->len, i = 0, bad = 0;
  struct node *r;
  while (i < n) { long m = utf8_at (p + i, n - i); if (m == 0) { bad++; m = 1; } i += m; }
  if (bad) {
    unsigned char *q;
    long k = 0;
    if (t->kind != T_STR && t->kind != T_CHR) perr ("a token that is not UTF-8");
    if (p[0] == 'L' || p[0] == 'U' || (p[0] == 'u' && p[1] != '8')) perr ("a wide literal that is not UTF-8");
    q = alloc (n + bad * 3);
    i = 0;
    while (i < n) {
      long m = utf8_at (p + i, n - i);
      if (m == 0) { q[k++] = '\\'; q[k++] = '0' + (p[i] >> 6); q[k++] = '0' + ((p[i] >> 3) & 7); q[k++] = '0' + (p[i] & 7); i++; }
      else { copy (q + k, p + i, m); k += m; i += m; }
    }
    p = q;
    n = k;
  }
  if (n <= 255) return nd_text (p, n);
  r = nd ("token");
  i = 0;
  while (i < n) {
    long e = i + 255;
    if (e >= n) e = n;
    else while (e > i && (p[e] & 0xc0) == 0x80) e--;
    nd_add (r, nd_text (p + i, e - i));
    i = e;
  }
  return r;
}
static struct node *take (void) { struct node *n = tok_node (tk (0)); next (); return n; }
static struct node *nd1 (char *k, struct node *a) { struct node *n = nd (k); nd_add (n, a); return n; }
static struct node *nd2 (char *k, struct node *a, struct node *b) { struct node *n = nd1 (k, a); nd_add (n, b); return n; }

/* ---- attributes, strings ---- */
static struct node *string_lit (void)
{
  struct node *a, *n;
  if (tk (0)->kind != T_STR) perr ("expected a string");
  a = take ();
  if (tk (0)->kind != T_STR) return a;
  n = nd1 ("str", a);
  while (tk (0)->kind == T_STR) nd_add (n, take ());
  return n;
}
/* __attribute__((...)): the tokens inside the double parentheses */
static struct node *attribute (void)
{
  struct node *n = nd ("__attribute__");
  long depth = 0;
  next ();
  expect (P_LPAR);
  expect (P_LPAR);
  while (!(depth == 0 && isp (0, P_RPAR))) {
    if (tk (0)->kind == T_EOF) perr ("an attribute without its end");
    if (isp (0, P_LPAR)) depth++;
    if (isp (0, P_RPAR)) depth--;
    nd_add (n, take ());
  }
  expect (P_RPAR);
  expect (P_RPAR);
  return n;
}
/* C23's [[...]]: the tokens inside */
static struct node *std_attribute (void)
{
  struct node *n = nd ("[[]]");
  long depth = 0;
  next ();
  next ();
  while (!(depth == 0 && isp (0, P_RBRACK) && isp (1, P_RBRACK))) {
    if (tk (0)->kind == T_EOF) perr ("an attribute without its end");
    if (isp (0, P_LBRACK) || isp (0, P_LPAR)) depth++;
    if (isp (0, P_RBRACK) || isp (0, P_RPAR)) depth--;
    nd_add (n, take ());
  }
  next ();
  next ();
  return n;
}
static int at_attr (long k) { return kw (k) == K_ATTR || (isp (k, P_LBRACK) && isp (k + 1, P_LBRACK)); }
static struct node *any_attribute (void) { return kw (0) == K_ATTR ? attribute () : std_attribute (); }
static void attributes (struct node *to) { while (at_attr (0)) nd_add (to, any_attribute ()); }

/* ---- expressions ---- */
static struct node *expr (void);
static struct node *assign (void);
static struct node *cast_expr (void);
static struct node *type_name (void);
static struct node *initializer (void);
static struct node *block (void);
static int starts_type (long k);

static struct node *postfix (struct node *e)
{
  for (;;) {
    if (isp (0, P_LBRACK)) { next (); e = nd2 ("[]", e, expr ()); expect (P_RBRACK); }
    else if (isp (0, P_LPAR)) {
      struct node *c = nd1 ("()", e);
      next ();
      if (!isp (0, P_RPAR)) { nd_add (c, assign ()); while (isp (0, P_COMMA)) { next (); nd_add (c, assign ()); } }
      expect (P_RPAR);
      e = c;
    }
    else if (isp (0, P_DOT) || isp (0, P_ARROW)) {
      char *k = isp (0, P_DOT) ? "." : "->";
      next ();
      if (tk (0)->kind != T_ID) perr ("expected a field name");
      e = nd2 (k, e, take ());
    }
    else if (isp (0, P_INC)) { next (); e = nd1 ("post ++", e); }
    else if (isp (0, P_DEC)) { next (); e = nd1 ("post --", e); }
    else return e;
  }
}
static struct node *primary (void)
{
  struct tok *t = tk (0);
  int k = kw (0);
  if (t->kind == T_NUM || t->kind == T_CHR) return take ();
  if (t->kind == T_STR) return string_lit ();
  if (isp (0, P_LPAR)) {
    struct node *e;
    next ();
    if (isp (0, P_LBRACE)) { e = nd1 ("stmt expr", block ()); expect (P_RPAR); return e; }
    e = expr ();
    expect (P_RPAR);
    mark_paren (e);
    return e;
  }
  if (k == K_GENERIC) {
    struct node *g = nd ("_Generic");
    next ();
    expect (P_LPAR);
    nd_add (g, assign ());
    while (isp (0, P_COMMA)) {
      struct node *a = nd ("assoc");
      next ();
      if (kw (0) == K_DEFAULT) nd_add (a, take ()); else nd_add (a, type_name ());
      expect (P_COLON);
      nd_add (a, assign ());
      nd_add (g, a);
    }
    expect (P_RPAR);
    return g;
  }
  if (k == K_OFFSETOF) {
    struct node *o = nd ("__builtin_offsetof");
    next ();
    expect (P_LPAR);
    nd_add (o, type_name ());
    expect (P_COMMA);
    if (tk (0)->kind != T_ID) perr ("expected a field name");
    nd_add (o, take ());
    for (;;) {
      if (isp (0, P_DOT)) { next (); if (tk (0)->kind != T_ID) perr ("expected a field name"); nd_add (o, nd1 (".", take ())); }
      else if (isp (0, P_LBRACK)) { next (); nd_add (o, nd1 ("[]", expr ())); expect (P_RBRACK); }
      else break;
    }
    expect (P_RPAR);
    return o;
  }
  if (k == K_VAARG || k == K_CONVERT) {
    struct node *v = nd (k == K_VAARG ? "__builtin_va_arg" : "__builtin_convertvector");
    next ();
    expect (P_LPAR);
    nd_add (v, assign ());
    expect (P_COMMA);
    nd_add (v, type_name ());
    expect (P_RPAR);
    return v;
  }
  if (k == K_TYPESCOMPAT) {
    struct node *v = nd ("__builtin_types_compatible_p");
    next ();
    expect (P_LPAR);
    nd_add (v, type_name ());
    expect (P_COMMA);
    nd_add (v, type_name ());
    expect (P_RPAR);
    return v;
  }
  if (t->kind == T_ID && k == K_NONE) return take ();
  perr ("expected an expression");
  return 0;
}
static struct node *unary (void)
{
  struct tok *t = tk (0);
  int k = kw (0);
  if (t->kind == T_P) {
    char *op = 0;
    if (t->id == P_INC || t->id == P_DEC) { op = t->id == P_INC ? "++" : "--"; next (); return nd1 (op, unary ()); }
    if (t->id == P_AMP) op = "&";
    else if (t->id == P_STAR) op = "*";
    else if (t->id == P_PLUS) op = "+";
    else if (t->id == P_MINUS) op = "-";
    else if (t->id == P_TILDE) op = "~";
    else if (t->id == P_NOT) op = "!";
    else if (t->id == P_ANDAND) { next (); if (tk (0)->kind != T_ID) perr ("expected a label"); return nd1 ("&&", take ()); }
    if (op) { next (); return nd1 (op, cast_expr ()); }
  }
  if (k == K_SIZEOF) {
    struct node *s = nd_text (t->p, t->len);
    next ();
    if (isp (0, P_LPAR) && starts_type (1)) {
      struct node *ty;
      next ();
      ty = type_name ();
      expect (P_RPAR);
      if (isp (0, P_LBRACE)) { nd_add (s, postfix (nd2 ("compound literal", ty, initializer ()))); return s; }
      nd_add (s, ty);
      return s;
    }
    nd_add (s, unary ());
    return s;
  }
  if (k == K_EXT) { next (); return nd1 ("__extension__", cast_expr ()); }
  if (k == K_REAL) { struct node *s = nd_text (t->p, t->len); next (); nd_add (s, cast_expr ()); return s; }
  return postfix (primary ());
}
static struct node *cast_expr (void)
{
  if (isp (0, P_LPAR) && starts_type (1)) {
    struct node *ty;
    next ();
    ty = type_name ();
    expect (P_RPAR);
    if (isp (0, P_LBRACE)) return postfix (nd2 ("compound literal", ty, initializer ()));
    return nd2 ("cast", ty, cast_expr ());
  }
  return unary ();
}
static int binprec (long k)
{
  struct tok *t = tk (k);
  if (t->kind != T_P) return 0;
  switch (t->id) {
  case P_OROR: return 1;
  case P_ANDAND: return 2;
  case P_OR: return 3;
  case P_XOR: return 4;
  case P_AMP: return 5;
  case P_EQ: case P_NE: return 6;
  case P_LT: case P_GT: case P_LE: case P_GE: return 7;
  case P_SHL: case P_SHR: return 8;
  case P_PLUS: case P_MINUS: return 9;
  case P_STAR: case P_DIV: case P_MOD: return 10;
  }
  return 0;
}
static struct node *binary (int min)
{
  struct node *l = cast_expr ();
  for (;;) {
    int p = binprec (0);
    struct node *n;
    if (p == 0 || p < min) return l;
    n = nd (ptext[tk (0)->id]);
    next ();
    nd_add (n, l);
    nd_add (n, binary (p + 1));
    l = n;
  }
}
static struct node *cond (void)
{
  struct node *c = binary (1);
  if (!isp (0, P_QUEST)) return c;
  next ();
  if (isp (0, P_COLON)) { next (); return nd2 ("?:", c, cond ()); }
  {
    struct node *n = nd1 ("?", c);
    nd_add (n, expr ());
    expect (P_COLON);
    nd_add (n, cond ());
    return n;
  }
}
static int assignop (long k)
{
  struct tok *t = tk (k);
  if (t->kind != T_P) return 0;
  switch (t->id) {
  case P_ASSIGN: case P_MULEQ: case P_DIVEQ: case P_MODEQ: case P_ADDEQ: case P_SUBEQ:
  case P_SHLEQ: case P_SHREQ: case P_ANDEQ: case P_XOREQ: case P_OREQ: return 1;
  }
  return 0;
}
static struct node *assign (void)
{
  struct node *l = cond ();
  if (assignop (0)) {
    struct node *n = nd (ptext[tk (0)->id]);
    next ();
    nd_add (n, l);
    nd_add (n, assign ());
    return n;
  }
  return l;
}
static struct node *expr (void)
{
  struct node *e = assign ();
  while (isp (0, P_COMMA)) { next (); e = nd2 (",", e, assign ()); }
  return e;
}

/* ---- declarations ---- */
struct dinfo { struct sym *name; struct sym **params; long nparams; int func; };
static struct node *declarator (struct dinfo *dinf, int abstract);
static struct node *decl_specs (int *flags);
static struct node *struct_body (void);

/* whether token k begins a type (a cast's, sizeof's, a parameter's) */
static int starts_type (long k)
{
  int c = kw (k);
  if (c == K_QUAL || c == K_TYPE || c == K_STRUCT || c == K_ENUM || c == K_TYPEOF || c == K_ATOMIC || c == K_BITINT
      || c == K_ALIGNAS || c == K_ATTR) return 1;
  if (c == K_EXT) return starts_type (k + 1);
  return is_typename (k);
}
static int starts_decl (long k)
{
  int c = kw (k);
  if (c == K_STORAGE || c == K_TYPEDEF || c == K_FUNC || c == K_STATICASSERT || at_attr (k)) return 1;
  return starts_type (k);
}
#define F_TYPEDEF 1
#define F_TYPE 2
static struct node *enum_spec (void)
{
  struct node *n = nd_text (tk (0)->p, tk (0)->len);
  next ();
  attributes (n);
  if (tk (0)->kind == T_ID && kw (0) == K_NONE) nd_add (n, take ());
  attributes (n);
  if (isp (0, P_COLON)) {
    int f = 0;
    struct node *b = nd (":");
    next ();
    nd_add (b, decl_specs (&f));
    nd_add (n, b);
  }
  if (isp (0, P_LBRACE)) {
    struct node *b = nd ("{");
    next ();
    while (!isp (0, P_RBRACE)) {
      struct node *e = nd ("enumerator");
      if (tk (0)->kind != T_ID) perr ("expected an enumerator");
      bind_sym (tk (0)->sym, 0);
      nd_add (e, take ());
      attributes (e);
      if (isp (0, P_ASSIGN)) { next (); nd_add (e, nd1 ("=", cond ())); }
      nd_add (b, e);
      if (!isp (0, P_COMMA)) break;
      next ();
    }
    expect (P_RBRACE);
    nd_add (n, b);
    attributes (n);
  }
  return n;
}
static struct node *struct_spec (void)
{
  struct node *n = nd_text (tk (0)->p, tk (0)->len);
  next ();
  attributes (n);
  if (tk (0)->kind == T_ID && kw (0) == K_NONE) nd_add (n, take ());
  attributes (n);
  if (isp (0, P_LBRACE)) { nd_add (n, struct_body ()); mark_off (n, tk (0 - 1)->p); attributes (n); }
  return n;
}
static struct node *decl_specs (int *flags)
{
  struct node *s = nd ("specs");
  for (;;) {
    int c = kw (0);
    struct tok *t = tk (0);
    if (c == K_TYPEDEF) { *flags |= F_TYPEDEF; nd_add (s, take ()); }
    else if (c == K_STORAGE || c == K_QUAL || c == K_FUNC) nd_add (s, take ());
    else if (c == K_TYPE) { *flags |= F_TYPE; nd_add (s, take ()); }
    else if (c == K_ATOMIC) {
      if (isp (1, P_LPAR)) {
        struct node *a = nd_text (t->p, t->len);
        next (); next ();
        nd_add (a, type_name ());
        expect (P_RPAR);
        nd_add (s, a);
        *flags |= F_TYPE;
      } else nd_add (s, take ());
    }
    else if (c == K_STRUCT) { *flags |= F_TYPE; nd_add (s, struct_spec ()); }
    else if (c == K_ENUM) { *flags |= F_TYPE; nd_add (s, enum_spec ()); }
    else if (at_attr (0)) nd_add (s, any_attribute ());
    else if (c == K_EXT) nd_add (s, take ());
    else if (c == K_TYPEOF || c == K_ALIGNAS || c == K_BITINT) {
      struct node *a = nd_text (t->p, t->len);
      next ();
      expect (P_LPAR);
      if (c != K_BITINT && starts_type (0)) nd_add (a, type_name ()); else nd_add (a, expr ());
      expect (P_RPAR);
      nd_add (s, a);
      if (c != K_ALIGNAS) *flags |= F_TYPE;
    }
    else if (c == K_NONE && t->kind == T_ID && t->sym->istype && !(*flags & F_TYPE)) { *flags |= F_TYPE; nd_add (s, take ()); }
    else return s;
  }
}
/* a parameter list, after its (: the parameters, their names in dinf */
static void params (struct node *f, struct dinfo *dinf)
{
  long mark = scope_in ();
  struct sym *names[256];
  long nn = 0;
  if (tk (0)->kind == T_ID && kw (0) == K_NONE && !tk (0)->sym->istype && (isp (1, P_COMMA) || isp (1, P_RPAR))) {
    /* an identifier list (K&R) */
    for (;;) {
      if (nn < 256) names[nn++] = tk (0)->sym;
      nd_add (f, take ());
      if (!isp (0, P_COMMA)) break;
      next ();
      if (tk (0)->kind != T_ID) perr ("expected a parameter name");
    }
  } else if (!isp (0, P_RPAR)) {
    for (;;) {
      if (isp (0, P_ELL)) { nd_add (f, take ()); break; }
      {
        int fl = 0;
        struct dinfo d;
        struct node *p = nd ("param");
        d.name = 0; d.params = 0; d.nparams = 0; d.func = 0;
        nd_add (p, decl_specs (&fl));
        if (!isp (0, P_COMMA) && !isp (0, P_RPAR)) nd_add (p, declarator (&d, 2));
        attributes (p);
        if (d.name) { bind_sym (d.name, 0); if (nn < 256) names[nn++] = d.name; }
        nd_add (f, p);
      }
      if (!isp (0, P_COMMA)) break;
      next ();
    }
  }
  scope_out (mark);
  if (dinf && !dinf->func) {
    long i = 0;
    dinf->func = 1;
    dinf->params = alloc ((nn + 1) * sizeof (struct sym *));
    while (i < nn) { dinf->params[i] = names[i]; i++; }
    dinf->nparams = nn;
  }
}
/* abstract: 0 a name, 1 none, 2 either */
static struct node *direct (struct dinfo *dinf, int abstract)
{
  struct node *d = 0;
  int named = 0;
  if (tk (0)->kind == T_ID && kw (0) == K_NONE && abstract != 1) {
    unsigned char *at = tk (0)->p;
    dinf->name = tk (0)->sym;
    d = take ();
    mark_off (d, at);
    named = 1;
  } else if (isp (0, P_LPAR) && (abstract == 0 || isp (1, P_STAR) || isp (1, P_LPAR) || isp (1, P_LBRACK) || kw (1) == K_ATTR
                                 || (abstract == 2 && tk (1)->kind == T_ID && kw (1) == K_NONE && !tk (1)->sym->istype))) {
    struct node *p = 0;
    next ();
    if (kw (0) == K_ATTR) { p = nd ("( )"); attributes (p); }
    d = declarator (dinf, abstract);
    expect (P_RPAR);
    if (nd_leaf (d) && !nd_is (d, "?") && !p) named = 1;
    if (p) { nd_add (p, d); d = p; }
  } else {
    if (abstract == 0) perr ("expected a declarator");
    d = nd ("?");
  }
  for (;;) {
    if (isp (0, P_LBRACK)) {
      struct node *a = nd1 ("[]", d);
      next ();
      while (kw (0) == K_QUAL || kw (0) == K_STORAGE || kw (0) == K_ATTR) { if (kw (0) == K_ATTR) nd_add (a, attribute ()); else nd_add (a, take ()); }
      if (isp (0, P_STAR) && isp (1, P_RBRACK)) nd_add (a, take ());
      else if (!isp (0, P_RBRACK)) nd_add (a, assign ());
      expect (P_RBRACK);
      d = a;
    } else if (isp (0, P_LPAR)) {
      struct node *f = nd1 ("()", d);
      next ();
      params (f, named ? dinf : 0);
      expect (P_RPAR);
      d = f;
      named = 0;
    } else return d;
  }
}
static struct node *declarator (struct dinfo *dinf, int abstract)
{
  if (isp (0, P_STAR)) {
    struct node *p = nd ("*"), *q = nd ("q"), *in;
    long i = 0;
    next ();
    while (kw (0) == K_QUAL || kw (0) == K_ATTR || kw (0) == K_ATOMIC) { if (kw (0) == K_ATTR) nd_add (q, attribute ()); else nd_add (q, take ()); }
    in = declarator (dinf, abstract);
    nd_add (p, in);
    while (i < q->count) { nd_add (p, q->kids[i]); i++; }
    return p;
  }
  return direct (dinf, abstract);
}
static struct node *type_name (void)
{
  int f = 0;
  struct dinfo d;
  struct node *t = nd ("type");
  d.name = 0; d.params = 0; d.nparams = 0; d.func = 0;
  nd_add (t, decl_specs (&f));
  if (!isp (0, P_RPAR) && !isp (0, P_COMMA) && !isp (0, P_COLON)) nd_add (t, declarator (&d, 1));
  return t;
}
static struct node *initializer (void)
{
  struct node *l;
  if (!isp (0, P_LBRACE)) return assign ();
  l = nd ("{}");
  next ();
  while (!isp (0, P_RBRACE)) {
    if (isp (0, P_DOT) || isp (0, P_LBRACK) || (tk (0)->kind == T_ID && isp (1, P_COLON))) {
      struct node *d = nd ("designated");
      if (tk (0)->kind == T_ID) { nd_add (d, nd1 (".", take ())); next (); }
      else {
        while (isp (0, P_DOT) || isp (0, P_LBRACK)) {
          if (isp (0, P_DOT)) { next (); if (tk (0)->kind != T_ID) perr ("expected a field name"); nd_add (d, nd1 (".", take ())); }
          else {
            struct node *lo;
            next ();
            lo = cond ();
            if (isp (0, P_ELL)) { next (); nd_add (d, nd2 ("[...]", lo, cond ())); } else nd_add (d, nd1 ("[]", lo));
            expect (P_RBRACK);
          }
        }
        if (isp (0, P_ASSIGN)) next ();
      }
      nd_add (d, initializer ());
      nd_add (l, d);
    } else nd_add (l, initializer ());
    if (!isp (0, P_COMMA)) break;
    next ();
  }
  expect (P_RBRACE);
  return l;
}
static struct node *static_assert_decl (void)
{
  struct node *n = nd ("_Static_assert");
  next ();
  expect (P_LPAR);
  nd_add (n, cond ());
  if (isp (0, P_COMMA)) { next (); nd_add (n, string_lit ()); }
  expect (P_RPAR);
  expect (P_SEMI);
  return n;
}
static struct node *asm_label (void)
{
  struct node *a = nd ("asm");
  next ();
  expect (P_LPAR);
  nd_add (a, string_lit ());
  expect (P_RPAR);
  return a;
}
/* a declaration or a function definition, its specifiers read; where: 0
   file, 1 block, 2 struct */
static struct node *decl_rest (struct node *specs, int flags, int where)
{
  struct node *d = nd1 ("decl", specs);
  int first = 1;
  if (isp (0, P_SEMI)) { next (); return d; }
  for (;;) {
    struct dinfo dinf;
    struct node *id = nd ("init decl");
    dinf.name = 0; dinf.params = 0; dinf.nparams = 0; dinf.func = 0;
    if (where == 2 && isp (0, P_COLON)) nd_add (id, nd ("?"));
    else nd_add (id, declarator (&dinf, 0));
    if (where == 2 && isp (0, P_COLON)) { next (); nd_add (id, nd1 (":", cond ())); }
    if (kw (0) == K_ASM) nd_add (id, asm_label ());
    attributes (id);
    if (dinf.name && where != 2) bind_sym (dinf.name, (flags & F_TYPEDEF) ? 1 : 0);
    if (first && where != 2 && dinf.func && (isp (0, P_LBRACE) || (starts_decl (0) && !(flags & F_TYPEDEF)))) {
      /* a function definition: its K&R declarations, its body in the scope
         of its parameters */
      struct node *f = nd1 ("fun def", specs);
      long mark = scope_in (), i = 0;
      long k = 0;
      while (k < id->count) { nd_add (f, id->kids[k]); k++; }
      while (i < dinf.nparams) { bind_sym (dinf.params[i], 0); i++; }
      while (!isp (0, P_LBRACE)) {
        int fl = 0;
        struct node *s = decl_specs (&fl);
        nd_add (f, decl_rest (s, fl, 1));
      }
      nd_add (f, block ());
      mark_off (f, tk (0 - 1)->p);
      scope_out (mark);
      return f;
    }
    if (isp (0, P_ASSIGN)) { next (); nd_add (id, nd1 ("=", initializer ())); }
    mark_off (id, tk (0 - 1)->p);
    nd_add (d, id);
    first = 0;
    if (!isp (0, P_COMMA)) break;
    next ();
  }
  expect (P_SEMI);
  return d;
}
static struct node *member (void)
{
  int f = 0;
  struct node *s;
  if (tk (0)->kind == T_DIR) return nd1 ("directive", take ());
  if (kw (0) == K_STATICASSERT) return static_assert_decl ();
  if (isp (0, P_SEMI)) return take ();
  if (kw (0) == K_EXT) { next (); return nd1 ("__extension__", member ()); }
  s = decl_specs (&f);
  return decl_rest (s, f, 2);
}
static struct node *struct_body (void)
{
  struct node *b = nd ("{");
  next ();
  while (!isp (0, P_RBRACE)) {
    if (tk (0)->kind == T_EOF) perr ("a struct without its end");
    nd_add (b, member ());
  }
  next ();
  return b;
}

/* ---- statements ---- */
static struct node *statement (void);
static struct node *block_item (void);
static struct node *asm_operands (void)
{
  struct node *c = nd (":");
  next ();
  while (!isp (0, P_COLON) && !isp (0, P_RPAR)) {
    struct node *o = nd ("operand");
    if (isp (0, P_LBRACK)) { next (); nd_add (o, nd1 ("[]", take ())); expect (P_RBRACK); }
    nd_add (o, string_lit ());
    expect (P_LPAR);
    nd_add (o, expr ());
    expect (P_RPAR);
    nd_add (c, o);
    if (!isp (0, P_COMMA)) break;
    next ();
  }
  return c;
}
static struct node *asm_stmt (void)
{
  struct node *a = nd ("asm");
  int sec = 0;
  next ();
  while (kw (0) == K_QUAL || kw (0) == K_FUNC || kw (0) == K_GOTO) nd_add (a, take ());
  expect (P_LPAR);
  nd_add (a, string_lit ());
  while (isp (0, P_COLON) && sec < 4) {
    if (sec < 2) nd_add (a, asm_operands ());
    else {
      struct node *c = nd (":");
      next ();
      while (!isp (0, P_COLON) && !isp (0, P_RPAR)) {
        if (sec == 2) nd_add (c, string_lit ()); else nd_add (c, take ());
        if (!isp (0, P_COMMA)) break;
        next ();
      }
      nd_add (a, c);
    }
    sec++;
  }
  expect (P_RPAR);
  return a;
}
static struct node *paren_expr (void) { struct node *e; expect (P_LPAR); e = expr (); expect (P_RPAR); return e; }
static struct node *statement1 (void)
{
  struct tok *t = tk (0);
  int k = kw (0);
  struct node *n;
  if (isp (0, P_LBRACE)) return block ();
  if (isp (0, P_SEMI)) return take ();
  if (t->kind == T_ID && k == K_NONE && isp (1, P_COLON)) {
    n = nd1 ("label", take ());
    next ();
    attributes (n);
    if (isp (0, P_RBRACE)) nd_add (n, nd (";")); else nd_add (n, block_item ());
    return n;
  }
  switch (k) {
  case K_CASE: {
    n = nd ("case");
    next ();
    nd_add (n, cond ());
    if (isp (0, P_ELL)) { next (); nd_add (n, cond ()); }
    expect (P_COLON);
    if (isp (0, P_RBRACE)) nd_add (n, nd (";")); else nd_add (n, block_item ());
    return n;
  }
  case K_DEFAULT:
    next ();
    expect (P_COLON);
    if (isp (0, P_RBRACE)) return nd1 ("default", nd (";"));
    return nd1 ("default", block_item ());
  case K_IF:
    n = nd ("if");
    next ();
    nd_add (n, paren_expr ());
    nd_add (n, statement ());
    if (kw (0) == K_ELSE) { next (); nd_add (n, statement ()); }
    return n;
  case K_SWITCH: n = nd ("switch"); next (); nd_add (n, paren_expr ()); nd_add (n, statement ()); return n;
  case K_WHILE: n = nd ("while"); next (); nd_add (n, paren_expr ()); nd_add (n, statement ()); return n;
  case K_DO:
    n = nd ("do");
    next ();
    nd_add (n, statement ());
    if (kw (0) != K_WHILE) perr ("expected while");
    next ();
    nd_add (n, paren_expr ());
    expect (P_SEMI);
    return n;
  case K_FOR: {
    long mark = scope_in ();
    n = nd ("for");
    next ();
    expect (P_LPAR);
    if (isp (0, P_SEMI)) nd_add (n, take ());
    else if (starts_decl (0) || kw (0) == K_EXT) nd_add (n, block_item ());
    else { nd_add (n, nd1 ("expr", expr ())); expect (P_SEMI); }
    if (isp (0, P_SEMI)) nd_add (n, take ()); else { nd_add (n, nd1 ("expr", expr ())); expect (P_SEMI); }
    if (isp (0, P_RPAR)) nd_add (n, nd (";")); else nd_add (n, nd1 ("expr", expr ()));
    expect (P_RPAR);
    nd_add (n, statement ());
    scope_out (mark);
    return n;
  }
  case K_GOTO:
    next ();
    if (isp (0, P_STAR)) { next (); n = nd1 ("goto *", expr ()); }
    else { if (tk (0)->kind != T_ID) perr ("expected a label"); n = nd1 ("goto", take ()); }
    expect (P_SEMI);
    return n;
  case K_CONTINUE: case K_BREAK: n = take (); expect (P_SEMI); return n;
  case K_RETURN:
    next ();
    if (isp (0, P_SEMI)) { next (); return nd ("return"); }
    n = nd1 ("return", expr ());
    expect (P_SEMI);
    return n;
  case K_ASM: n = asm_stmt (); expect (P_SEMI); return n;
  case K_ATTR: {
    n = nd (";");
    attributes (n);
    expect (P_SEMI);
    return n;
  }
  }
  n = nd1 ("expr", expr ());
  expect (P_SEMI);
  return n;
}
static struct node *statement (void) { unsigned char *at = tk (0)->p; struct node *n = statement1 (); mark_off (n, at); return n; }
static struct node *block_item1 (void)
{
  int k = kw (0);
  if (tk (0)->kind == T_DIR) return nd1 ("directive", take ());
  if (k == K_STATICASSERT) return static_assert_decl ();
  if (k == K_LABEL) {
    struct node *n = nd ("__label__");
    next ();
    for (;;) { if (tk (0)->kind != T_ID) perr ("expected a label"); nd_add (n, take ()); if (!isp (0, P_COMMA)) break; next (); }
    expect (P_SEMI);
    return n;
  }
  if (k == K_EXT && starts_decl (1)) { next (); return nd1 ("__extension__", block_item ()); }
  if (k == K_EXT && kw (1) == K_EXT) { next (); return nd1 ("__extension__", block_item ()); }
  if (tk (0)->kind == T_ID && k == K_NONE && isp (1, P_COLON)) return statement ();
  if (at_attr (0)) {
    /* attributes, then a ; (an attribute statement) or a declaration */
    long save = S->at;
    struct node *a = nd ("q");
    attributes (a);
    if (isp (0, P_SEMI)) { next (); a->text = (unsigned char *) ";"; a->len = 1; return a; }
    S->at = save;
  }
  if (starts_decl (0) && !(is_typename (0) && isp (1, P_COLON))) {
    int f = 0;
    struct node *s = decl_specs (&f);
    return decl_rest (s, f, 1);
  }
  return statement ();
}
static struct node *block_item (void) { unsigned char *at = tk (0)->p; struct node *n = block_item1 (); mark_off (n, at); return n; }
static struct node *block (void)
{
  struct node *b = nd ("block");
  long mark = scope_in ();
  expect (P_LBRACE);
  while (!isp (0, P_RBRACE)) {
    if (tk (0)->kind == T_EOF) perr ("a block without its end");
    nd_add (b, block_item ());
  }
  next ();
  scope_out (mark);
  return b;
}

/* ---- the unit ---- */
static struct node *external (void)
{
  int k = kw (0);
  if (tk (0)->kind == T_DIR) return nd1 ("directive", take ());
  if (isp (0, P_SEMI)) return take ();
  if (k == K_STATICASSERT) return static_assert_decl ();
  if (k == K_EXT) { next (); return nd1 ("__extension__", external ()); }
  if (k == K_ASM) { struct node *a = asm_stmt (); expect (P_SEMI); return a; }
  {
    int f = 0;
    unsigned char *at = tk (0)->p;
    struct node *s = decl_specs (&f);
    mark_off (s, at);
    return decl_rest (s, f, 0);
  }
}
static void keywords (void)
{
  long i = 0;
  char *tn[] = { "__builtin_va_list", "__int128_t", "__uint128_t", 0 };
  while (kwords[i]) {
    struct sym *s = intern ((unsigned char *) kwords[i], cstrlen (kwords[i]));
    s->kw = kclass[i];
    i++;
  }
  i = 0;
  while (tn[i]) { intern ((unsigned char *) tn[i], cstrlen (tn[i]))->istype = 1; i++; }
}
struct node *c_parse (unsigned char *src, long n, char *name)
{
  struct node *root = nd ("");
  st_init ();
  S->name = name;
  S->src = src;
  keywords ();
  lex (src, n);
  S->at = 0;
  while (tk (0)->kind != T_EOF) nd_add (root, external ());
  return root;
}
#include "cpr.c"
/* the bytes of the tree under n, its hashes worked out (FF.pm's emit) */
void nd_emit (struct node *n)
{
  unsigned char b[1];
  long i = 0;
  out_bytes (n->hash, 32);
  b[0] = n->count;
  out_bytes (b, 1);
  while (i < n->count) { nd_emit (n->kids[i]); i++; }
  b[0] = n->len;
  out_bytes (b, 1);
  out_bytes (n->text, n->len);
}
