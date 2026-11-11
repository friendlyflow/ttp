/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* pp.c: dev source of tools/cpp.ff, the C preprocessor: the .i that gcc 16
   -E writes, byte for byte, from the same command line (gcc's options) and
   a file of the target's predefined macros (gcc -dM -E) and answers to
   __has_builtin and its kin (--predef). Its model is libcpp's, so that the
   output is the same: tokens with the whitespace before them, macro
   contexts with the virtual location of each token (where the outermost
   macro was named, and whether the token was spelled in a system header),
   the padding tokens of an expansion, the multiple-include optimization,
   and gcc's -E printer (c-ppoutput.cc) of line markers, newlines and
   columns. Also the .s of an object of asm, gcc -E -x assembler-with-cpp
   (a .S, or stdin, -, after -x): libcpp's CLK_ASM, its set of predefined
   macros in --predef the one whose options begin with -x assembler-with-cpp. */

/* the runtime: tools/rt.ff's alloc, tools/c.ff's cp_* (the C parser's runtime: c/shim.ff.txt) and the page's
   own pp_* (pp/shim.ff.txt; the dev build's shim.c): raw syscalls, each result the kernel's, a negative errno
   when it fails; cp_file dies on a file it cannot read */
void *alloc (long n);
long pp_open (char *path);
long pp_read (long fd, unsigned char *buf, long n);
long pp_close (long fd);
unsigned char *cp_file (char *path, long *size);
long cp_write (int fd, unsigned char *p, long n);
long cp_create (char *path);
long cp_readlink (char *path, unsigned char *buf, long room);
void cp_exit (int status);

/* ---- tokens (libcpp's order: avoid_paste and the expression parser depend on it) */
enum {
  T_EQ, T_NOT, T_GREATER, T_LESS, T_PLUS, T_MINUS, T_MULT, T_DIV, T_MOD, T_AND, T_OR, T_XOR, T_RSHIFT, T_LSHIFT,
  T_COMPL, T_AND_AND, T_OR_OR, T_QUERY, T_COLON, T_COMMA, T_OPEN_PAREN, T_CLOSE_PAREN, T_EOF,
  T_EQ_EQ, T_NOT_EQ, T_GREATER_EQ, T_LESS_EQ, T_SPACESHIP, T_PLUS_EQ, T_MINUS_EQ, T_MULT_EQ, T_DIV_EQ, T_MOD_EQ,
  T_AND_EQ, T_OR_EQ, T_XOR_EQ, T_RSHIFT_EQ, T_LSHIFT_EQ,
  T_HASH, T_PASTE, T_OPEN_SQUARE, T_CLOSE_SQUARE, T_OPEN_BRACE, T_CLOSE_BRACE, T_OPEN_SPLICE, T_CLOSE_SPLICE,
  T_SEMICOLON, T_ELLIPSIS, T_PLUS_PLUS, T_MINUS_MINUS, T_DEREF, T_DOT, T_SCOPE, T_DEREF_STAR, T_DOT_STAR, T_REFLECT, T_ATSIGN,
  T_NAME, T_AT_NAME, T_NUMBER, T_CHAR, T_WCHAR, T_CHAR16, T_CHAR32, T_UTF8CHAR, T_OTHER,
  T_STRING, T_WSTRING, T_STRING16, T_STRING32, T_UTF8STRING, T_OBJC_STRING, T_HEADER_NAME, T_UNEVAL,
  T_COMMENT, T_MACRO_ARG, T_PRAGMA, T_PRAGMA_EOL, T_PADDING
};
static char *opname[] = {
  "=", "!", ">", "<", "+", "-", "*", "/", "%", "&", "|", "^", ">>", "<<",
  "~", "&&", "||", "?", ":", ",", "(", ")", "",
  "==", "!=", ">=", "<=", "<=>", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=", ">>=", "<<=",
  "#", "##", "[", "]", "{", "}", "[:", ":]",
  ";", "...", "++", "--", "->", ".", "::", "->*", ".*", "^^", "@"
};
static char *digraphs[] = { "%:", "%:%:", "<:", ":>", "<%", "%>" };

#define PREV_WHITE 1
#define DIGRAPH 2
#define STRINGIFY_ARG 4
#define PASTE_LEFT 8
#define NAMED_OP 16
#define COLON_SCOPE 128
#define SP_DIGRAPH 256
#define SP_PREV_WHITE 512
#define NO_EXPAND 1024
#define PRAGMA_OP 2048
#define BOL 4096

/* the names: their kind and flags */
#define NT_VOID 0
#define NT_USER 1
#define NT_BUILTIN 2
#define NT_ARG 3
#define N_DISABLED 1
#define N_POISONED 2
#define N_WARN 4
#define N_USED 8
enum { BT_NONE, BT_FILE, BT_FILE_NAME, BT_BASE_FILE, BT_LINE, BT_INCLUDE_LEVEL, BT_COUNTER, BT_DATE, BT_TIME, BT_TIMESTAMP,
  BT_HAS_ATTRIBUTE, BT_HAS_STD_ATTRIBUTE, BT_HAS_BUILTIN, BT_HAS_INCLUDE, BT_HAS_INCLUDE_NEXT, BT_HAS_EMBED,
  BT_HAS_FEATURE, BT_HAS_EXTENSION, BT_PRAGMA };
enum { D_NONE, D_DEFINE, D_INCLUDE, D_ENDIF, D_IFDEF, D_IF, D_ELSE, D_IFNDEF, D_UNDEF, D_LINE, D_ELIF, D_ELIFDEF,
  D_ELIFNDEF, D_ERROR, D_PRAGMA, D_WARNING, D_EMBED, D_INCLUDE_NEXT, D_IDENT, D_IMPORT, D_ASSERT, D_UNASSERT,
  D_SCCS, D_LINEMARKER };
#define F_COND 1
#define F_IF_COND 2
#define F_INCL 4
#define F_IN_I 8
static char *dnames[] = { "", "define", "include", "endif", "ifdef", "if", "else", "ifndef", "undef", "line", "elif",
  "elifdef", "elifndef", "error", "pragma", "warning", "embed", "include_next", "ident", "import", "assert",
  "unassert", "sccs", 0 };
static int dflags[] = { 0, F_IN_I, F_INCL, F_COND, F_COND | F_IF_COND, F_COND | F_IF_COND, F_COND, F_COND | F_IF_COND,
  F_IN_I, 0, F_COND, F_COND, F_COND, 0, F_IN_I, 0, F_IN_I | F_INCL, F_INCL, F_IN_I, F_INCL, 0, 0, F_IN_I, 0 };
/* the include kinds */
#define IT_INCLUDE 0
#define IT_INCLUDE_NEXT 1
#define IT_IMPORT 2
#define IT_CMDLINE 3
#define IT_MAIN 4
#define IT_DEFAULT 5

struct map {            /* an ordinary line map: a file's name, from a line on */
  unsigned char *name; long nlen;
  int sysp, depth;
  struct map *from;     /* the map of the file that included this one, at the #include */
  long inc_line;        /* the line it was included from */
  long ret_line;        /* the line of that file after the #include */
};
struct vloc {           /* a token's location: where the outermost macro was named (its own place if none) */
  struct map *m; long lno; long col;
  int sys;              /* the system-header-ness of the place it was spelled */
  int bi;               /* spelled at the built-in location (a predefined macro, a builtin's result) */
};
struct hnode;
struct tok {
  int type, flags;
  struct hnode *node;
  unsigned char *text; long len;
  long argno;
  struct tok *source;   /* a padding token's */
  long pragma;
  struct vloc loc;
};
struct macro {
  struct hnode **params; long paramc;
  int variadic, fun_like, syshdr, extra, used;
  struct tok *toks; long count;
};
struct pragma;
struct hnode {
  unsigned char *name; long len;
  struct hnode *next;
  int type, flags, builtin, dir;
  struct macro *macro;
  long argidx;
  int stype; struct macro *smacro; long sargidx;   /* while it names a parameter */
  int is_op;
};
struct pragma { struct hnode *name; char *space, *pname; int nspace, deferred, expand, kind, id; struct pragma *sub, *next; };
enum { PK_NONE, PK_ONCE, PK_PUSH, PK_POP, PK_POISON, PK_SYSHDR, PK_DEPENDENCY, PK_WARNING, PK_ERROR, PK_TARGET, PK_OPTIMIZE, PK_PUSHOPT, PK_POPOPT, PK_RESETOPT };

struct dir {
  unsigned char *name; long len;
  int sysp;
  struct dir *next;
  struct dir *hnext;    /* make_cpp_dir's table */
};
struct file {
  unsigned char *name; long nlen;    /* as named */
  unsigned char *path; long plen;    /* where it was found */
  struct dir *dir;
  unsigned char *raw; long size;     /* its bytes */
  unsigned char *clean; long clen; long *notes; long nnotes;
  int found, once_only, stack_count;
  struct hnode *cmacro;
  unsigned char *dir_name;
  struct file *next_all;
};
struct fent { unsigned char *name; long nlen; struct dir *start; struct file *f; struct fent *next; };
struct ifs { struct ifs *next; long lno; int skip_elses, was_skipping, type; struct hnode *mi_cmacro; };
struct buf {
  unsigned char *base, *cur, *lim, *line_base;
  long *notes; long nnotes, inote;
  int need_line, return_at_eof, sysp;
  struct file *file;
  struct ifs *if_stack;
  struct buf *prev;
};
struct ctx {
  struct ctx *prev;
  struct tok **t; long i, n;
  struct vloc *vl;      /* each token's location (a macro's expansion), or 0: the token's own */
  struct hnode *macro;
  int ext;
};
struct arg {
  struct tok **first; struct vloc *vl; long count;
  struct tok **exp; struct vloc *evl; long ecount; int expanded;
  struct tok *str;
  int omitted;          /* GNU's , ## __VA_ARGS__: no variable arguments at all */
};
struct pushed { struct hnode *node; int type; struct macro *macro; int builtin; struct pushed *next; };
struct has { unsigned char *key; long klen; long value; struct has *next; };
struct optset { struct optset *next; unsigned char *state; long slen; };
/* the macros of a state of #pragma GCC target and optimize: gcc's, against those of the options (--predef) */
struct tset { unsigned char *key; long klen; unsigned char **lines; long n; struct tset *next; };

#define HSIZE 65536
struct pst {
  struct hnode **tab;
  struct buf *buffer;
  struct ctx base, *ctx;
  struct map *curmap, *builtin_map, *cmdline_map;
  long lno;
  int forced;           /* the tokens lexed now get: 1 the built-in location, 2 the command line's */
  /* the state of libcpp's pfile->state */
  int in_directive, skipping, parsing_args, prevent_expansion, angled_headers, directive_wants_padding;
  int in_deferred_pragma, pragma_allow_expansion, ignore_pragma, skip_eval, va_args_ok, keep_tokens;
  int about_to_expand;
  int mi_valid; struct hnode *mi_cmacro, *mi_ind_cmacro;
  int directive; long directive_line;
  struct tok dres;      /* the directive's result */
  struct tok avoid_paste, endarg;
  struct hnode *topmost; struct vloc invocation;
  /* the token run: what cur_token[-1] is, lookaheads */
  struct tok **run; long rc, rroom, la;
  struct tok *pool; long npool;
  /* names */
  struct hnode *n_defined, *n_va_args, *n_va_opt, *n_pragma, *n_true, *n_false;
  int true_false;   /* C23 on (gcc 16's default, gnu23): true and false are 1 and 0 in #if (libcpp's true_false) */
  struct pragma *pragmas;
  struct pushed *pushed;
  struct optset *optstack;
  /* #pragma GCC target and optimize: the pragmas since the options (t ARGS ; o ARGS ...), the macros they changed */
  unsigned char *tstate; long tslen;
  unsigned char **tnames; long *tnlen; long ntnames;
  int tpending; unsigned char *targs; long talen, taroom;
  struct tset *tsets;
  unsigned char **plines; long nplines;   /* the options' predefined macros, as #define lines */
  unsigned char *key; long klen;
  /* files */
  struct dir *quote, *bracket, *no_search, *dirtab;
  struct fent **ftab;
  struct file *all_files, *main_file;
  int seen_once_only;
  unsigned char *cwd; long cwdlen;
  long counter;
  /* the printer (c-ppoutput.cc's print) */
  long src_line; int printed, first_time, prev_was_system, avoid_paste_p, in_pragma;
  struct tok *prev, *source;
  unsigned char *src_file; long src_flen;
  /* output */
  unsigned char *obuf; long on; long ofd;
  long errors;
  /* the target */
  int uchar, wchar_unsigned, wchar_bits;
  int lang_asm;         /* -x assembler-with-cpp (CLK_ASM): no $ or UTF-8 in names, no digraphs, only L'' and L"", an unknown
                           directive kept, # without a parameter kept, no #pragma or #ident printed, no line adjustments */
  struct has *has; int collect;
  struct hnode *cur_macro_node;   /* the macro being defined (diagnostics) */
};
static struct pst *pps;

/* ---- small things */
static long slen (char *s) { long n = 0; while (s[n]) n++; return n; }
static void mcopy (unsigned char *d, unsigned char *s, long n) { long i = 0; while (i < n) { d[i] = s[i]; i++; } }
static int msame (unsigned char *a, long an, unsigned char *b, long bn)
{
  long i = 0;
  if (an != bn) return 0;
  while (i < an) { if (a[i] != b[i]) return 0; i++; }
  return 1;
}
static int is (unsigned char *a, long n, char *s) { return msame (a, n, (unsigned char *) s, slen (s)); }
static unsigned char *dup (unsigned char *s, long n) { unsigned char *d = alloc (n + 1); mcopy (d, s, n); d[n] = 0; return d; }
static unsigned char *cat2 (unsigned char *a, long an, unsigned char *b, long bn)
{
  unsigned char *d = alloc (an + bn + 1);
  mcopy (d, a, an); mcopy (d + an, b, bn); d[an + bn] = 0;
  return d;
}
static int isidnum (int c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_'; }
static int isdig (int c) { return c >= '0' && c <= '9'; }
static long numtext (unsigned long v, unsigned char *b)
{
  unsigned char t[24]; long n = 0, k = 0;
  if (v == 0) t[n++] = '0';
  while (v != 0) { t[n++] = '0' + (int) (v % 10); v = v / 10; }
  while (n > 0) b[k++] = t[--n];
  return k;
}

/* ---- diagnostics' output, and the output */
static void perr_bytes (unsigned char *p, long n) { cp_write (2, p, n); }
static void perr_str (char *s) { perr_bytes ((unsigned char *) s, slen (s)); }
static void perr_num (long v)
{
  unsigned char b[24]; long k = 0;
  if (v < 0) { b[k++] = '-'; v = -v; }
  k += numtext ((unsigned long) v, b + k);
  perr_bytes (b, k);
}
static void o_flush (void)
{
  long p = 0;
  while (p < pps->on) {
    long w = cp_write (pps->ofd, pps->obuf + p, pps->on - p);
    if (w <= 0) { perr_str ("cpp: cannot write the output\n"); cp_exit (1); }
    p += w;
  }
  pps->on = 0;
}
static void o_bytes (unsigned char *p, long n)
{
  if (pps->on + n > 65536) o_flush ();
  if (n > 65536) { long w = 0; while (w < n) { long k = cp_write (pps->ofd, p + w, n - w); if (k <= 0) { perr_str ("cpp: cannot write the output\n"); cp_exit (1); } w += k; } return; }
  mcopy (pps->obuf + pps->on, p, n);
  pps->on += n;
}
static void o_ch (int c) { if (pps->on >= 65536) o_flush (); pps->obuf[pps->on++] = c; }
static void o_str (char *s) { o_bytes ((unsigned char *) s, slen (s)); }
static void o_num (long v) { unsigned char b[24]; o_bytes (b, numtext (v, b)); }

/* ---- diagnostics: gcc's text is not reproduced, only that there was one */
static void where (void)
{
  if (pps->curmap) { perr_bytes (pps->curmap->name, pps->curmap->nlen); perr_str (":"); perr_num (pps->lno); perr_str (": "); }
}
static void error (char *s) { where (); perr_str ("error: "); perr_str (s); perr_str ("\n"); pps->errors++; }
static void error2 (char *s, unsigned char *a, long n) { where (); perr_str ("error: "); perr_str (s); perr_bytes (a, n); perr_str ("\n"); pps->errors++; }
static void warning2 (char *s, unsigned char *a, long n) { where (); perr_str ("warning: "); perr_str (s); perr_bytes (a, n); perr_str ("\n"); }
static void fatal (char *s) { o_flush (); perr_str ("cpp: "); where (); perr_str (s); perr_str ("\n"); cp_exit (2); }
static void fatal2 (char *s, unsigned char *a, long n) { o_flush (); perr_str ("cpp: "); where (); perr_str (s); perr_bytes (a, n); perr_str ("\n"); cp_exit (2); }

/* ---- names */
static long hashof (unsigned char *p, long n)
{
  unsigned long h = 2166136261UL; long i = 0;
  while (i < n) { h = (h ^ p[i]) * 16777619UL; i++; }
  return (long) (h & (HSIZE - 1));
}
static struct hnode *lookup (unsigned char *p, long n)
{
  long h = hashof (p, n);
  struct hnode *e = pps->tab[h];
  while (e) { if (msame (e->name, e->len, p, n)) return e; e = e->next; }
  e = alloc (sizeof (struct hnode));
  e->name = dup (p, n); e->len = n;
  e->next = pps->tab[h]; pps->tab[h] = e;
  return e;
}
static struct hnode *lookup_s (char *s) { return lookup ((unsigned char *) s, slen (s)); }

/* ---- tokens and the run */
static struct tok *newtok (void)
{
  if (pps->npool == 0) { pps->pool = alloc (1024 * sizeof (struct tok)); pps->npool = 1024; }
  pps->npool--;
  return pps->pool++;
}
static void run_push (struct tok *t)
{
  if (pps->rc + pps->la + 2 > pps->rroom) {
    long r = pps->rroom * 2 + 256; struct tok **n = alloc (r * sizeof (struct tok *)); long i = 0;
    while (i < pps->rc + pps->la) { n[i] = pps->run[i]; i++; }
    pps->run = n; pps->rroom = r;
  }
  pps->run[pps->rc++] = t;
}
static struct tok *temp_token (void)   /* _cpp_temp_token: before the lookaheads, cur_token[-1]'s location */
{
  struct tok *t = newtok ();
  long i;
  if (pps->rc > 0) t->loc = pps->run[pps->rc - 1]->loc;
  if (pps->rc + pps->la + 2 > pps->rroom) { run_push (t); pps->rc--; }
  i = pps->rc + pps->la;
  while (i > pps->rc) { pps->run[i] = pps->run[i - 1]; i--; }
  pps->run[pps->rc++] = t;
  return t;
}
static int seen_eol (void) { return pps->rc > 0 && pps->run[pps->rc - 1]->type == T_EOF; }

/* ---- spelling */
static int spell_kind (int type)   /* 0 operator, 1 identifier, 2 literal, 3 none */
{
  if (type == T_EOF) return 3;
  if (type < T_NAME) return 0;
  if (type <= T_AT_NAME) return 1;
  if (type <= T_COMMENT) return 2;
  return 3;
}
static long spell (struct tok *t, unsigned char *d)   /* cpp_spell_token (forstring) */
{
  int k = spell_kind (t->type);
  if (k == 0) {
    char *s = (t->flags & DIGRAPH) ? digraphs[t->type - T_HASH] : opname[t->type];
    long n = slen (s); mcopy (d, (unsigned char *) s, n); return n;
  }
  if (k == 1) { mcopy (d, t->node->name, t->node->len); return t->node->len; }
  if (k == 2) { mcopy (d, t->text, t->len); return t->len; }
  return 0;
}
static long spell_len (struct tok *t)
{
  int k = spell_kind (t->type);
  if (k == 0) return 4;
  if (k == 1) return t->node->len;
  if (k == 2) return t->len;
  return 0;
}
static void out_token (struct tok *t)   /* cpp_output_token */
{
  int k = spell_kind (t->type);
  if (k == 0) {
    if (t->flags & DIGRAPH) o_str (digraphs[t->type - T_HASH]); else o_str (opname[t->type]);
  } else if (k == 1) {
    long i = 0; unsigned char *n = t->node->name;
    while (i < t->node->len) {
      if (n[i] & 0x80) {
        /* utf8_to_ucn */
        unsigned long u = 0; int len = 1; unsigned char b[10]; int j;
        int c = n[i];
        if (c >= 0xf0) { u = c & 7; len = 4; } else if (c >= 0xe0) { u = c & 15; len = 3; } else { u = c & 31; len = 2; }
        j = 1; while (j < len && i + j < t->node->len) { u = (u << 6) | (n[i + j] & 63); j++; }
        b[0] = '\\'; b[1] = 'U';
        j = 0; while (j < 8) { int d = (int) ((u >> (28 - 4 * j)) & 15); b[2 + j] = d < 10 ? '0' + d : 'a' + d - 10; j++; }
        o_bytes (b, 10);
        i += len;
      } else { o_ch (n[i]); i++; }
    }
  } else if (k == 2) {
    if (t->type == T_HEADER_NAME) o_ch ('"');
    o_bytes (t->text, t->len);
    if (t->type == T_HEADER_NAME) o_ch ('"');
  }
}

/* ---- maps and the printer (c-ppoutput.cc) */
static void quote_out (unsigned char *s, long n)   /* cpp_quote_string */
{
  long i = 0;
  while (i < n) {
    int c = s[i++];
    if (c == '\n') { o_ch ('\\'); o_ch ('n'); }
    else { if (c == '\\' || c == '"') o_ch ('\\'); o_ch (c); }
  }
}
static int print_line_1 (struct vloc *l, char *flags)
{
  if (pps->printed) o_ch ('\n');
  pps->printed = 0;
  if (l) {
    pps->src_line = l->lno;
    pps->src_file = l->m->name; pps->src_flen = l->m->nlen;
    o_str ("# "); o_num (l->lno); o_str (" \""); quote_out (l->m->name, l->m->nlen); o_ch ('"'); o_str (flags);
    if (l->sys == 2) o_str (" 3 4"); else if (l->sys == 1) o_str (" 3");
    o_ch ('\n');
    return 1;
  }
  return 0;
}
static int maybe_print_line (struct vloc *l)
{
  if (pps->printed) { o_ch ('\n'); pps->src_line++; pps->printed = 0; }
  if (l && l->lno >= pps->src_line && l->lno < pps->src_line + 8 && msame (l->m->name, l->m->nlen, pps->src_file, pps->src_flen)) {
    while (l->lno > pps->src_line) { o_ch ('\n'); pps->src_line++; }
    return 0;
  }
  return print_line_1 (l, "");
}
static int do_line_change (struct tok *t, struct vloc *l, int parsing_args)
{
  int m;
  if (t->type == T_EOF || parsing_args) return 0;
  m = maybe_print_line (l);
  pps->prev = 0; pps->source = 0;
  if (t->type != T_PRAGMA) {
    long spaces = l->col - 2;
    pps->printed = 1;
    while (--spaces >= 0) o_ch (' ');
  }
  return m;
}
static void line_change (struct tok *t, int parsing_args) { do_line_change (t, &t->loc, parsing_args); }
static void map_loc (struct map *m, long lno, struct vloc *l)
{
  l->m = m; l->lno = lno; l->col = 0; l->sys = m->sysp; l->bi = 0;
}
#define LC_ENTER 0
#define LC_LEAVE 1
#define LC_RENAME 2
static void file_change (struct map *m, int reason)   /* pp_file_change */
{
  struct vloc l;
  char *flags = "";
  map_loc (m, pps->lno, &l);
  if (pps->first_time) { print_line_1 (&l, flags); pps->first_time = 0; return; }
  if (reason == LC_ENTER) {
    struct vloc f;
    map_loc (m->from, m->inc_line, &f);
    maybe_print_line (&f);
    flags = " 1";
  } else if (reason == LC_LEAVE) flags = " 2";
  print_line_1 (&l, flags);
}
static void push_next_include (void);
static void do_file_change (int reason, unsigned char *name, long nlen, long lno, int sysp, long inc_line)
{
  struct map *m = alloc (sizeof (struct map)), *c = pps->curmap;
  if (reason == LC_ENTER) {
    m->name = name; m->nlen = nlen; m->sysp = sysp; m->depth = c ? c->depth + 1 : 1;
    m->from = c; m->inc_line = inc_line; m->ret_line = pps->lno;
  } else if (reason == LC_LEAVE) {
    struct map *f = c->from;
    m->name = f->name; m->nlen = f->nlen; m->sysp = f->sysp; m->depth = f->depth;
    m->from = f->from; m->inc_line = f->inc_line; m->ret_line = f->ret_line;
    lno = c->ret_line;
  } else {
    m->name = name; m->nlen = nlen; m->sysp = sysp;
    m->depth = c ? c->depth : 1; m->from = c ? c->from : 0;
    m->inc_line = c ? c->inc_line : 0; m->ret_line = c ? c->ret_line : 0;
  }
  pps->curmap = m; pps->lno = lno;
  file_change (m, reason);
  if (reason == LC_LEAVE && m->depth == 1) push_next_include ();
}

/* the token streamer (token_streamer::stream) */
static int avoid_paste (struct tok *ta1, struct tok *tb1);
static void pragma_name (long id, char **space, char **name);
static void pragma_early (long id);
static void run_directive (int dir, unsigned char *text, long n);
static void pragma_late (void);
static void targs_add (struct tok *t);
static void stream (struct tok *t, struct vloc *l)
{
  int is_sys, changed, marker = 0;
  if (t->type == T_PADDING) {
    pps->avoid_paste_p = 1;
    if (pps->source == 0 || (!(pps->source->flags & PREV_WHITE) && t->source == 0)) pps->source = t->source;
    return;
  }
  if (t->type == T_EOF) return;
  is_sys = l->sys != 0;
  changed = is_sys != pps->prev_was_system;
  pps->prev_was_system = is_sys;
  if (pps->avoid_paste_p) {
    if (pps->source == 0) pps->source = t;
    if (l->lno != pps->src_line && !pps->in_pragma && !pps->lang_asm) {
      marker = do_line_change (t, l, 0);
      o_ch (' '); pps->printed = 1;
    } else if ((pps->source->flags & PREV_WHITE) || (pps->prev && avoid_paste (pps->prev, t)) || (pps->prev == 0 && t->type == T_HASH)) {
      o_ch (' '); pps->printed = 1;
    }
  } else if ((t->flags & PREV_WHITE) && t->type != T_PRAGMA) {
    if (l->lno != pps->src_line && !pps->in_pragma && !pps->lang_asm) marker = do_line_change (t, l, 0);
    o_ch (' '); pps->printed = 1;
  }
  pps->avoid_paste_p = 0;
  pps->source = 0;
  pps->prev = t;
  if (t->type == T_PRAGMA) {
    char *space, *name;
    pps->in_pragma = 1;
    if (!pps->lang_asm) {   /* (should_output_pragmas) */
      maybe_print_line (&t->loc);
      o_str ("#pragma ");
      pragma_name (t->pragma, &space, &name);
      if (space) { o_str (space); o_ch (' '); }
      o_str (name);
      pps->printed = 1;
    }
    pragma_early (t->pragma);
  } else if (t->type == T_PRAGMA_EOL) {
    if (!pps->lang_asm) maybe_print_line (0);
    pps->in_pragma = 0;
    if (pps->tpending) pragma_late ();
  } else {
    if (pps->tpending) targs_add (t);
    if (!pps->in_pragma && !pps->lang_asm && !marker && changed && !l->bi) marker = do_line_change (t, l, 0);
    if (!pps->in_pragma || !pps->lang_asm) { out_token (t); pps->printed = 1; }
  }
}

/* ---- buffers */
static void clean_file (struct file *f)   /* lines spliced (backslash-newline), each splice's place kept */
{
  unsigned char *s = f->raw, *d;
  long n = f->size, i = 0, o = 0, nb = 0, nn = 0;
  while (i < n) { if (s[i] == '\\') nb++; i++; }
  d = alloc (n + 8);
  f->notes = alloc ((nb + 1) * sizeof (long));
  i = 0;
  while (i < n) {
    int c = s[i];
    if (c == '\\') {
      long j = i + 1;
      while (j < n && (s[j] == ' ' || s[j] == '\t' || s[j] == '\f' || s[j] == '\v')) j++;
      if (j < n && s[j] == '\n') { f->notes[nn++] = o; i = j + 1; continue; }
      if (j + 1 < n && s[j] == '\r' && s[j + 1] == '\n') { f->notes[nn++] = o; i = j + 2; continue; }
    }
    if (c == '\r' && i + 1 < n && s[i + 1] == '\n') { i++; continue; }
    d[o++] = c; i++;
  }
  d[o] = '\n';
  f->clean = d; f->clen = o; f->nnotes = nn;
}
static struct buf *push_buffer (unsigned char *p, long n)   /* cpp_push_buffer: p[n] is '\n' */
{
  struct buf *b = alloc (sizeof (struct buf));
  b->base = b->cur = b->line_base = p; b->lim = p + n;
  b->need_line = 1;
  b->prev = pps->buffer;
  pps->buffer = b;
  return b;
}
static void push_text (unsigned char *text, long n)   /* a stage-3 buffer, its one line ready */
{
  unsigned char *p = alloc (n + 8);
  struct buf *b;
  mcopy (p, text, n); p[n] = '\n';
  b = push_buffer (p, n);
  b->need_line = 0;
}
static void pop_file_buffer (struct file *f)   /* _cpp_pop_file_buffer */
{
  if (pps->mi_valid && f->cmacro == 0) f->cmacro = pps->mi_cmacro;
  pps->mi_valid = 0;
}
static void pop_buffer (void)
{
  struct buf *b = pps->buffer;
  struct file *inc = b->file;
  struct ifs *i = b->if_stack;
  while (i) { error ("unterminated conditional directive"); i = i->next; }
  pps->skipping = 0;
  pps->buffer = b->prev;
  if (inc) {
    inc->stack_count--;
    pop_file_buffer (inc);
    if (pps->curmap->depth > 1) do_file_change (LC_LEAVE, 0, 0, 0, 0, 0);
  }
}
static int fresh_line (void)   /* _cpp_get_fresh_line */
{
  if (pps->in_directive) return 0;
  for (;;) {
    struct buf *b = pps->buffer;
    if (!b->need_line) return 1;
    if (b->cur < b->lim) { b->line_base = b->cur; b->need_line = 0; return 1; }
    if (b->prev && !b->return_at_eof) pop_buffer ();
    else { pps->lno++; return 0; }
  }
}
static void process_notes (struct buf *b)
{
  while (b->inote < b->nnotes && b->base + b->notes[b->inote] <= b->cur) {
    b->line_base = b->base + b->notes[b->inote];
    b->inote++;
    pps->lno++;
  }
}
static void set_loc (struct tok *t, long col)
{
  if (pps->forced == 1) { t->loc.m = pps->builtin_map; t->loc.lno = 0; t->loc.col = 0; t->loc.sys = 0; t->loc.bi = 1; return; }
  if (pps->forced == 2) { t->loc.m = pps->cmdline_map; t->loc.lno = 0; t->loc.col = 0; t->loc.sys = 0; t->loc.bi = 0; return; }
  t->loc.m = pps->curmap; t->loc.lno = pps->lno; t->loc.col = col; t->loc.sys = pps->curmap->sysp; t->loc.bi = 0;
}

/* ---- the lexer (_cpp_lex_direct) */
static int utf8_len (unsigned char *p)   /* a valid UTF-8 sequence's length, or 0 */
{
  int c = p[0], n, i;
  if (c < 0xc2) return 0;
  if (c < 0xe0) n = 2; else if (c < 0xf0) n = 3; else if (c < 0xf5) n = 4; else return 0;
  i = 1;
  while (i < n) { if ((p[i] & 0xc0) != 0x80) return 0; i++; }
  return n;
}
static int ident_more (unsigned char *p)   /* forms_identifier_p: $ or UTF-8 (neither in assembler) */
{
  if (pps->lang_asm) return 0;
  if (*p == '$') return 1;
  if (*p >= 0x80) return utf8_len (p);
  return 0;
}
static void lex_identifier (struct tok *t, unsigned char *base)
{
  struct buf *b = pps->buffer;
  unsigned char *c = b->cur;
  for (;;) {
    int k;
    while (isidnum (*c)) c++;
    k = ident_more (c);
    if (!k) break;
    c += k;
  }
  b->cur = c;
  t->type = T_NAME;
  t->node = lookup (base, c - base);
  if ((t->node->flags & N_POISONED) && !pps->skipping) error2 ("attempt to use poisoned ", t->node->name, t->node->len);
}
static void lex_number (struct tok *t, unsigned char *base)
{
  struct buf *b = pps->buffer;
  unsigned char *c = b->cur;
  for (;;) {
    int k;
    while (isidnum (*c) || *c == '.' || ((*c == '+' || *c == '-') && (c[-1] == 'e' || c[-1] == 'E' || c[-1] == 'p' || c[-1] == 'P'))) c++;
    k = ident_more (c);
    if (!k) break;
    c += k;
  }
  b->cur = c;
  t->type = T_NUMBER; t->text = base; t->len = c - base;
}
static void lex_raw_string (struct tok *t, unsigned char *base, unsigned char *cur)
{
  /* cur at the R's '"': R"delim( ... )delim" (without splices undone: not in the sources this reads) */
  struct buf *b = pps->buffer;
  unsigned char *d = cur + 1, *p;
  long dlen = 0;
  int type = *base == 'L' ? T_WSTRING : *base == 'U' ? T_STRING32 : *base == 'u' ? (base[1] == '8' ? T_UTF8STRING : T_STRING16) : T_STRING;
  while (d[dlen] != '(' && d[dlen] != '\n' && dlen < 16) dlen++;
  if (d[dlen] != '(') { t->type = T_OTHER; t->text = base; t->len = 1; b->cur = base + 1; return; }
  p = d + dlen + 1;
  for (;;) {
    if (p >= b->lim) { error ("unterminated raw string"); t->type = T_OTHER; t->text = base; t->len = 1; b->cur = base + 1; return; }
    if (*p == ')' && msame (p + 1, dlen, d, dlen) && p[1 + dlen] == '"') { p += dlen + 2; break; }
    if (*p == '\n') pps->lno++;
    p++;
  }
  b->cur = p;
  t->type = type; t->text = base; t->len = p - base;
}
static void lex_string (struct tok *t, unsigned char *base)
{
  struct buf *b = pps->buffer;
  unsigned char *cur = base;
  int term = *cur++, type;
  if (term == 'L' || term == 'U') term = *cur++;
  else if (term == 'u') { term = *cur++; if (term == '8') term = *cur++; }
  if (term == 'R') { lex_raw_string (t, base, cur); return; }
  if (term == '"') type = *base == 'L' ? T_WSTRING : *base == 'U' ? T_STRING32 : *base == 'u' ? (base[1] == '8' ? T_UTF8STRING : T_STRING16) : T_STRING;
  else if (term == '\'') type = *base == 'L' ? T_WCHAR : *base == 'U' ? T_CHAR32 : *base == 'u' ? (base[1] == '8' ? T_UTF8CHAR : T_CHAR16) : T_CHAR;
  else { term = '>'; type = T_HEADER_NAME; }
  for (;;) {
    int c = *cur++;
    if (c == '\\' && !pps->angled_headers && *cur != '\n') cur++;
    else if (c == term) break;
    else if (c == '\n') {
      cur--;
      if (term == '>') { t->type = T_LESS; return; }
      type = T_OTHER;
      break;
    }
  }
  b->cur = cur;
  t->type = type; t->text = base; t->len = cur - base;
}
static void skip_block_comment (void)
{
  struct buf *b = pps->buffer;
  unsigned char *cur = b->cur;
  cur++;
  if (*cur == '/') cur++;
  for (;;) {
    int c = *cur++;
    if (c == '/') { if (cur[-2] == '*') break; }
    else if (c == '\n') {
      b->cur = cur - 1;
      process_notes (b);
      if (cur >= b->lim) { b->cur = cur - 1; error ("unterminated comment"); return; }
      pps->lno++;
      b->line_base = cur;
    }
  }
  b->cur = cur;
  process_notes (b);
}
static void skip_line_comment (void)
{
  struct buf *b = pps->buffer;
  while (*b->cur != '\n') b->cur++;
}
static struct tok *lex_direct_into (struct tok *result, int inrun)
{
  struct buf *b;
  int c = 0;
 fresh:
  result->flags = 0;
  b = pps->buffer;
  if (b->need_line) {
    if (pps->in_deferred_pragma) {
      result->type = T_PRAGMA_EOL;
      pps->in_deferred_pragma = 0;
      if (!pps->pragma_allow_expansion) pps->prevent_expansion--;
      set_loc (result, 0);
      return result;
    }
    if (!fresh_line ()) {
      result->type = T_EOF;
      set_loc (result, 0);
      if (!pps->in_directive && !pps->parsing_args) { result->flags = BOL; pop_buffer (); }
      return result;
    }
    if (!pps->keep_tokens && inrun) { pps->rc = 0; run_push (result); }
    result->flags = BOL;
    if (pps->parsing_args == 2) result->flags |= PREV_WHITE;
  }
  b = pps->buffer;
 skipped_white:
  if (b->inote < b->nnotes) process_notes (b);
  c = *b->cur++;
  set_loc (result, b->cur - b->line_base);
  result->node = 0;
  switch (c) {
  case ' ': case '\t': case '\f': case '\v': case 0:
    result->flags |= PREV_WHITE;
    while (*b->cur == ' ' || *b->cur == '\t' || *b->cur == '\f' || *b->cur == '\v' || *b->cur == 0) b->cur++;
    goto skipped_white;
  case '\n':
    if (b->cur < b->lim || pps->in_directive > 1) pps->lno++;
    b->need_line = 1;
    if (pps->in_deferred_pragma) {
      result->type = T_PRAGMA_EOL;
      result->flags &= ~PREV_WHITE;
      pps->in_deferred_pragma = 0;
      if (!pps->pragma_allow_expansion) pps->prevent_expansion--;
      return result;
    }
    goto fresh;
  case '0': case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
    lex_number (result, b->cur - 1);
    break;
  case 'L': case 'u': case 'U': case 'R':
    {
      unsigned char *p = b->cur;
      if (pps->lang_asm) { if (c == 'L' && (*p == '\'' || *p == '"')) { lex_string (result, p - 1); break; } }
      else if ((*p == '\'' && c != 'R') || *p == '"' || (*p == 'R' && c != 'R' && p[1] == '"')
          || (*p == '8' && c == 'u' && (p[1] == '"' || (p[1] == 'R' && p[2] == '"')))) {
        lex_string (result, p - 1);
        break;
      }
    }
    lex_identifier (result, b->cur - 1);
    break;
  case '\'': case '"':
    lex_string (result, b->cur - 1);
    break;
  case '/':
    c = *b->cur;
    if (c == '*') { skip_block_comment (); }
    else if (c == '/') { skip_line_comment (); }
    else if (c == '=') { b->cur++; result->type = T_DIV_EQ; break; }
    else { result->type = T_DIV; break; }
    result->flags |= PREV_WHITE;
    goto skipped_white;
  case '<':
    if (pps->angled_headers) {
      lex_string (result, b->cur - 1);
      if (result->type != T_LESS) break;
    }
    result->type = T_LESS;
    if (*b->cur == '=') b->cur++, result->type = T_LESS_EQ;
    else if (*b->cur == '<') { b->cur++; result->type = T_LSHIFT; if (*b->cur == '=') b->cur++, result->type = T_LSHIFT_EQ; }
    else if (*b->cur == ':' && !pps->lang_asm) { b->cur++; result->flags |= DIGRAPH; result->type = T_OPEN_SQUARE; }
    else if (*b->cur == '%' && !pps->lang_asm) { b->cur++; result->flags |= DIGRAPH; result->type = T_OPEN_BRACE; }
    break;
  case '>':
    result->type = T_GREATER;
    if (*b->cur == '=') b->cur++, result->type = T_GREATER_EQ;
    else if (*b->cur == '>') { b->cur++; result->type = T_RSHIFT; if (*b->cur == '=') b->cur++, result->type = T_RSHIFT_EQ; }
    break;
  case '%':
    result->type = T_MOD;
    if (*b->cur == '=') b->cur++, result->type = T_MOD_EQ;
    else if (*b->cur == ':' && !pps->lang_asm) {
      b->cur++; result->flags |= DIGRAPH; result->type = T_HASH;
      if (*b->cur == '%' && b->cur[1] == ':') b->cur += 2, result->type = T_PASTE;
    } else if (*b->cur == '>' && !pps->lang_asm) { b->cur++; result->flags |= DIGRAPH; result->type = T_CLOSE_BRACE; }
    break;
  case '.':
    result->type = T_DOT;
    if (isdig (*b->cur)) lex_number (result, b->cur - 1);
    else if (*b->cur == '.' && b->cur[1] == '.') b->cur += 2, result->type = T_ELLIPSIS;
    break;
  case '+':
    result->type = T_PLUS;
    if (*b->cur == '+') b->cur++, result->type = T_PLUS_PLUS;
    else if (*b->cur == '=') b->cur++, result->type = T_PLUS_EQ;
    break;
  case '-':
    result->type = T_MINUS;
    if (*b->cur == '>') b->cur++, result->type = T_DEREF;
    else if (*b->cur == '-') b->cur++, result->type = T_MINUS_MINUS;
    else if (*b->cur == '=') b->cur++, result->type = T_MINUS_EQ;
    break;
  case '&':
    result->type = T_AND;
    if (*b->cur == '&') b->cur++, result->type = T_AND_AND;
    else if (*b->cur == '=') b->cur++, result->type = T_AND_EQ;
    break;
  case '|':
    result->type = T_OR;
    if (*b->cur == '|') b->cur++, result->type = T_OR_OR;
    else if (*b->cur == '=') b->cur++, result->type = T_OR_EQ;
    break;
  case ':':
    result->type = T_COLON;
    if (*b->cur == ':') b->cur++, result->type = T_SCOPE;
    else if (*b->cur == '>' && !pps->lang_asm) { b->cur++; result->flags |= DIGRAPH; result->type = T_CLOSE_SQUARE; }
    break;
  case '*': result->type = T_MULT; if (*b->cur == '=') b->cur++, result->type = T_MULT_EQ; break;
  case '=': result->type = T_EQ; if (*b->cur == '=') b->cur++, result->type = T_EQ_EQ; break;
  case '!': result->type = T_NOT; if (*b->cur == '=') b->cur++, result->type = T_NOT_EQ; break;
  case '^': result->type = T_XOR; if (*b->cur == '=') b->cur++, result->type = T_XOR_EQ; break;
  case '#': result->type = T_HASH; if (*b->cur == '#') b->cur++, result->type = T_PASTE; break;
  case '?': result->type = T_QUERY; break;
  case '~': result->type = T_COMPL; break;
  case ',': result->type = T_COMMA; break;
  case '(': result->type = T_OPEN_PAREN; break;
  case ')': result->type = T_CLOSE_PAREN; break;
  case '[': result->type = T_OPEN_SQUARE; break;
  case ']': result->type = T_CLOSE_SQUARE; break;
  case '{': result->type = T_OPEN_BRACE; break;
  case '}': result->type = T_CLOSE_BRACE; break;
  case ';': result->type = T_SEMICOLON; break;
  case '@': result->type = T_ATSIGN; break;
  default:
    {
      unsigned char *base = b->cur - 1;
      if (c == '_' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')) { lex_identifier (result, base); break; }
      if (ident_more (base)) { b->cur = base + ident_more (base); lex_identifier (result, base); break; }
      if (c >= 0xc0 && utf8_len (base)) b->cur = base + utf8_len (base);
      result->type = T_OTHER; result->text = base; result->len = b->cur - base;
    }
  }
  if (b->inote < b->nnotes && b->base + b->notes[b->inote] <= b->cur) process_notes (b);
  return result;
}
static struct tok *lex_direct (void)
{
  struct tok *t = newtok ();
  run_push (t);
  return lex_direct_into (t, 1);
}

/* ---- contexts */
static void push_ctx (struct hnode *macro, struct tok **t, struct vloc *vl, long n, int ext)
{
  struct ctx *c = alloc (sizeof (struct ctx));
  c->prev = pps->ctx; c->t = t; c->vl = vl; c->n = n; c->i = 0; c->macro = macro; c->ext = ext;
  pps->ctx = c;
}
static void push_token_ctx (struct hnode *macro, struct tok *t)   /* one token, its own location */
{
  struct tok **a = alloc (sizeof (struct tok *));
  a[0] = t;
  push_ctx (macro, a, 0, 1, 0);
}
static void pop_ctx (void)
{
  struct ctx *c = pps->ctx;
  struct hnode *m = c->macro;
  if (m && (c->prev ? c->prev->macro : 0) != m) m->flags &= ~N_DISABLED;
  if (m && m == pps->topmost && c->prev == &pps->base) pps->topmost = 0;
  pps->ctx = c->prev;
}
static void backup_tokens (long n)
{
  if (pps->ctx->prev == 0) { pps->la += n; pps->rc -= n; }
  else pps->ctx->i--;
}
static struct tok *padding_token (struct tok *source)
{
  struct tok *t = temp_token ();
  t->type = T_PADDING; t->source = source; t->flags = 0;
  return t;
}

static int handle_directive (int indented);
/* _cpp_lex_token */
static struct tok *lex_token (void)
{
  struct tok *r;
  for (;;) {
    if (pps->la) { pps->la--; r = pps->run[pps->rc++]; }
    else r = lex_direct ();
    if (r->flags & BOL) {
      if (r->type == T_HASH && pps->parsing_args != 1) {
        if (handle_directive (r->flags & PREV_WHITE)) {
          if (pps->dres.type == T_PADDING) continue;
          r = &pps->dres;
        }
      } else if (pps->in_deferred_pragma) r = &pps->dres;
      if (!pps->skipping) line_change (r, pps->parsing_args);
    }
    if (pps->in_directive || pps->in_deferred_pragma) break;
    pps->mi_valid = 0;
    if (!pps->skipping || r->type == T_EOF) break;
  }
  return r;
}

/* ---- macro expansion (macro.cc) */
static int enter_macro (struct hnode *node, struct tok *result, struct vloc *loc);
static void paste_all (struct tok *lhs);
static int in_macro_expansion (void) { return pps->about_to_expand || pps->ctx->macro != 0; }
static struct tok *get_tok (struct vloc *loc)   /* cpp_get_token_1 */
{
  struct tok *r = 0;
  struct vloc vl;
  int have = 0, saved = pps->about_to_expand;
  for (;;) {
    struct ctx *c = pps->ctx;
    struct hnode *node;
    if (!c->prev) { r = lex_token (); vl = r->loc; have = 1; }
    else if (c->i < c->n) {
      r = c->t[c->i];
      if (c->vl) vl = c->vl[c->i]; else vl = r->loc;
      have = 1;
      c->i++;
      if (r->flags & PASTE_LEFT) {
        paste_all (r);
        if (pps->in_directive) continue;
        r = padding_token (r);
        goto out;
      }
    } else {
      pop_ctx ();
      if (pps->in_directive) continue;
      r = &pps->avoid_paste;
      goto out;
    }
    if (pps->in_directive && r->type == T_COMMENT) continue;
    if (r->type != T_NAME) break;
    node = r->node;
    if (node->type == NT_VOID || node->type == NT_ARG || (r->flags & NO_EXPAND)) break;
    if (!(node->flags & N_DISABLED)) {
      int ret;
      if (!in_macro_expansion ()) { pps->invocation = r->loc; pps->topmost = node; }
      if (pps->prevent_expansion) break;
      ret = enter_macro (node, r, &vl);
      if (ret) {
        if (pps->in_directive || ret == 2) continue;
        r = padding_token (r);
        goto out;
      }
    } else {
      struct tok *t = temp_token ();
      struct vloc keep = t->loc;
      *t = *r;
      t->loc = keep;
      t->flags = r->flags | NO_EXPAND;
      r = t;
    }
    break;
  }
 out:
  if (loc) { if (!have) vl = r->loc; *loc = vl; }
  pps->about_to_expand = saved;
  return r;
}
static struct tok *get_token (void) { return get_tok (0); }
static struct tok *get_token_no_padding (void)
{
  for (;;) { struct tok *t = get_token (); if (t->type != T_PADDING) return t; }
}

static void stringify_buf (unsigned char **d, long *n, long *room, long add)
{
  if (*n + add > *room) {
    long r = (*room + add) * 2; unsigned char *x = alloc (r);
    mcopy (x, *d, *n); *d = x; *room = r;
  }
}
static struct tok *stringify_arg (struct tok **first, long count)
{
  long room = 64, n = 0, i, backslash = 0;
  unsigned char *d = alloc (room);
  struct tok *source = 0, *t;
  d[n++] = '"';
  for (i = 0; i < count; i++) {
    struct tok *tk = first[i];
    int esc;
    long len;
    if (tk->type == T_PADDING) {
      if (source == 0 || (!(source->flags & PREV_WHITE) && tk->source == 0)) source = tk->source;
      continue;
    }
    esc = (tk->type >= T_CHAR && tk->type <= T_UTF8CHAR) || (tk->type >= T_STRING && tk->type <= T_UTF8STRING);
    len = spell_len (tk) * (esc ? 2 : 1) + 4;
    stringify_buf (&d, &n, &room, len + 4);
    if (n != 1) {
      if (source == 0) source = tk;
      if (source->flags & PREV_WHITE) d[n++] = ' ';
    }
    source = 0;
    if (esc) {
      unsigned char *tmp = alloc (spell_len (tk) + 8);
      long k = spell (tk, tmp), j = 0;
      while (j < k) { int c = tmp[j++]; if (c == '\n') { d[n++] = '\\'; d[n++] = 'n'; } else { if (c == '\\' || c == '"') d[n++] = '\\'; d[n++] = c; } }
    } else n += spell (tk, d + n);
    if (tk->type == T_OTHER && tk->text[0] == '\\') backslash++; else backslash = 0;
  }
  if (backslash & 1) n--;
  stringify_buf (&d, &n, &room, 2);
  d[n++] = '"';
  t = temp_token ();
  t->type = T_STRING; t->text = d; t->len = n; t->flags = 0; t->node = 0;
  return t;
}
/* paste_tokens: lhs ## rhs lexed again; 0 when they do not make one token */
static int paste_tokens (struct tok **plhs, struct tok *rhs)
{
  struct tok *lhs = *plhs, *r;
  long len = spell_len (lhs) + spell_len (rhs) + 4, n;
  unsigned char *b = alloc (len);
  struct buf *pb;
  int ok;
  n = spell (lhs, b);
  if (lhs->type == T_DIV && rhs->type != T_EQ) b[n++] = ' ';
  if (rhs->type != T_PADDING) n += spell (rhs, b + n);
  push_text (b, n);
  pb = pps->buffer;
  r = temp_token ();
  lex_direct_into (r, 0);
  ok = pb->cur == pb->lim;
  pps->buffer = pb->prev;
  if (!ok) {
    struct vloc keep = r->loc;
    *r = *lhs;
    r->loc = keep;
    r->flags &= ~PASTE_LEFT;
    *plhs = r;
    if (!pps->lang_asm) error ("pasting does not give a valid preprocessing token");
    return 0;
  }
  r->flags |= lhs->flags & PREV_WHITE;
  *plhs = r;
  return 1;
}
static void paste_all (struct tok *lhs)
{
  struct ctx *c = pps->ctx;
  struct tok *rhs = 0;
  struct vloc vl;
  struct tok **a;
  struct vloc *va;
  if (c->vl) vl = c->vl[c->i - 1]; else vl = pps->invocation;
  do {
    rhs = c->t[c->i++];
    if (!paste_tokens (&lhs, rhs)) { backup_tokens (1); break; }
  } while (rhs->flags & PASTE_LEFT);
  a = alloc (sizeof (struct tok *)); va = alloc (sizeof (struct vloc));
  a[0] = lhs; va[0] = vl;
  push_ctx (c->macro, a, va, 1, 1);
}

/* the tokens of an expansion, as tokens_buff */
struct tbuf { struct tok **t; struct vloc *vl; long n, room; };
static void tb_add (struct tbuf *b, struct tok *t, struct vloc *l)
{
  if (b->n >= b->room) {
    long r = b->room * 2 + 16, i = 0;
    struct tok **nt = alloc (r * sizeof (struct tok *)); struct vloc *nv = alloc (r * sizeof (struct vloc));
    while (i < b->n) { nt[i] = b->t[i]; nv[i] = b->vl[i]; i++; }
    b->t = nt; b->vl = nv; b->room = r;
  }
  b->t[b->n] = t;
  if (l) b->vl[b->n] = *l; else b->vl[b->n] = t->loc;
  b->n++;
}
static void mkvloc (struct vloc *exp, struct vloc *spell, struct vloc *out)   /* a body token's virtual location in a macro's map */
{
  out->m = exp->m; out->lno = exp->lno; out->col = exp->col;
  out->bi = spell->bi;
  out->sys = spell->bi ? exp->sys : spell->sys;
}
static void argvloc (struct vloc *exp, struct vloc *spell, struct vloc *out)   /* an argument token's: its own already resolved */
{
  out->m = exp->m; out->lno = exp->lno; out->col = exp->col;
  out->bi = spell->bi; out->sys = spell->sys;
}

static struct arg *collect_args (struct hnode *node, struct tok ***pragma_buf, long *npragma, long *nargs)
{
  struct macro *m = node->macro;
  long argc = m->paramc ? m->paramc : 1, n = 0, alloced = 0;
  struct arg *args = alloc (argc * sizeof (struct arg)), *arg = args;
  struct tok *t = 0;
  struct vloc vl;
  long room;
  do {
    long depth = 0, ntok = 0;
    alloced++;
    n++;
    room = 16;
    arg->first = alloc (room * sizeof (struct tok *)); arg->vl = alloc (room * sizeof (struct vloc));
    arg->count = 0; arg->expanded = 0; arg->str = 0; arg->omitted = 0;
    for (;;) {
      if (ntok + 2 > room) {
        long r = room * 2, i = 0;
        struct tok **nt = alloc (r * sizeof (struct tok *)); struct vloc *nv = alloc (r * sizeof (struct vloc));
        while (i < ntok) { nt[i] = arg->first[i]; nv[i] = arg->vl[i]; i++; }
        arg->first = nt; arg->vl = nv; room = r;
      }
      t = get_tok (&vl);
      if (t->type == T_PADDING) { if (ntok == 0) continue; }
      else if (t->type == T_OPEN_PAREN) depth++;
      else if (t->type == T_CLOSE_PAREN) { if (depth-- == 0) break; }
      else if (t->type == T_COMMA) { if (depth == 0 && !(m->variadic && n == m->paramc)) break; }
      else if (t->type == T_EOF || (t->type == T_HASH && (t->flags & BOL))) break;
      else if (t->type == T_PRAGMA && !(t->flags & PRAGMA_OP)) {
        struct tok *nt = temp_token ();
        *nt = *t;
        t = nt;
        do {
          if (*npragma % 32 == 0) {
            struct tok **x = alloc ((*npragma + 32) * sizeof (struct tok *)); long i = 0;
            while (i < *npragma) { x[i] = (*pragma_buf)[i]; i++; }
            *pragma_buf = x;
          }
          (*pragma_buf)[(*npragma)++] = t;
          if (t->type == T_PRAGMA_EOL) break;
          t = get_tok (&vl);
        } while (t->type != T_EOF);
        pps->parsing_args = 2; pps->prevent_expansion = 1;
        if (t->type == T_EOF) break;
        continue;
      }
      arg->first[ntok] = t; arg->vl[ntok] = vl;
      ntok++;
    }
    while (ntok > 0 && arg->first[ntok - 1]->type == T_PADDING) ntok--;
    arg->count = ntok;
    arg->first[ntok] = &pps->endarg; arg->vl[ntok] = t->loc;
    if (n <= m->paramc) { if (n != m->paramc) arg++; }
  } while (t->type != T_CLOSE_PAREN && t->type != T_EOF);
  if (t->type == T_EOF) {
    if (t == &pps->endarg) backup_tokens (1);
    error2 ("unterminated argument list invoking macro ", node->name, node->len);
    return 0;
  }
  if (n == 1 && m->paramc == 0 && args[0].count == 0) n = 0;
  if (n == m->paramc || (n + 1 == m->paramc && m->variadic)) {
    if (m->variadic && (n < m->paramc || (n == 1 && args[0].count == 0))) {
      args[m->paramc - 1].omitted = 1;
      if (n < m->paramc) { args[m->paramc - 1].count = 0; args[m->paramc - 1].first = alloc (sizeof (struct tok *)); args[m->paramc - 1].first[0] = &pps->endarg; args[m->paramc - 1].vl = alloc (sizeof (struct vloc)); }
    }
    *nargs = alloced;
    return args;
  }
  error2 ("wrong number of arguments to macro ", node->name, node->len);
  return 0;
}
static struct arg *funlike_invocation (struct hnode *node, struct tok ***pragma_buf, long *npragma, long *nargs)
{
  struct tok *t, *padding = 0;
  for (;;) {
    t = get_token ();
    if (t->type != T_PADDING) break;
    if (padding == 0 || padding->source == 0 || (!(padding->source->flags & PREV_WHITE) && t->source == 0)) padding = t;
  }
  if (t->type == T_OPEN_PAREN) { pps->parsing_args = 2; return collect_args (node, pragma_buf, npragma, nargs); }
  if (t->type != T_EOF || t == &pps->endarg) {
    backup_tokens (1);
    if (padding) push_token_ctx (0, padding);
  }
  return 0;
}
static void expand_arg (struct arg *a)
{
  long room = 256;
  int saved = pps->ignore_pragma;
  if (a->count == 0 || a->expanded) { a->expanded = 1; return; }
  a->expanded = 1;
  a->exp = alloc (room * sizeof (struct tok *)); a->evl = alloc (room * sizeof (struct vloc)); a->ecount = 0;
  push_ctx (0, a->first, a->vl, a->count + 1, 1);
  pps->ignore_pragma = 1;
  for (;;) {
    struct vloc l;
    struct tok *t;
    if (a->ecount + 1 >= room) {
      long r = room * 2, i = 0;
      struct tok **nt = alloc (r * sizeof (struct tok *)); struct vloc *nv = alloc (r * sizeof (struct vloc));
      while (i < a->ecount) { nt[i] = a->exp[i]; nv[i] = a->evl[i]; i++; }
      a->exp = nt; a->evl = nv; room = r;
    }
    t = get_tok (&l);
    if (t->type == T_EOF) break;
    a->exp[a->ecount] = t; a->evl[a->ecount] = l; a->ecount++;
  }
  pop_ctx ();
  pps->ignore_pragma = saved;
}
static struct tok *copy_paste_flag (struct tok *t, struct tok *src)   /* a copy with src's PASTE_LEFT */
{
  struct tok *n = temp_token ();
  struct vloc keep = n->loc;
  *n = *t;
  n->loc = keep;
  if (src->flags & PASTE_LEFT) n->flags = t->flags | PASTE_LEFT; else n->flags = t->flags & ~PASTE_LEFT;
  return n;
}
static long macro_count (struct macro *m)
{
  long i;
  if (!m->extra) return m->count;
  i = m->count;
  while (i-- > 0) if (m->toks[i].type != T_PASTE) return i + 1;
  return 0;
}
/* __VA_OPT__'s state (vaopt_state) */
struct vaopt { struct arg *arg; int variadic, last_paste, stringify, state, update; };
#define VO_ERROR 0
#define VO_DROP 1
#define VO_INCLUDE 2
#define VO_BEGIN 3
#define VO_END 4
static int vaopt_update (struct vaopt *v, struct tok *t)
{
  if (!v->variadic) return VO_INCLUDE;
  if (t->type == T_NAME && t->node == pps->n_va_opt) {
    if (v->state > 0) { error ("__VA_OPT__ may not appear in a __VA_OPT__"); return VO_ERROR; }
    v->state++;
    v->stringify = (t->flags & STRINGIFY_ARG) != 0;
    return VO_BEGIN;
  } else if (v->state == 1) {
    if (t->type != T_OPEN_PAREN) { error ("__VA_OPT__ must be followed by an open parenthesis"); return VO_ERROR; }
    v->state++;
    if (v->update == VO_ERROR) {
      if (v->arg == 0) v->update = VO_INCLUDE;
      else {
        long i = 0;
        v->update = VO_DROP;
        if (!v->arg->expanded) expand_arg (v->arg);
        while (i < v->arg->ecount) { if (v->arg->exp[i]->type != T_PADDING) { v->update = VO_INCLUDE; break; } i++; }
      }
    }
    return VO_DROP;
  } else if (v->state >= 2) {
    int was;
    if (v->state == 2 && t->type == T_PASTE) { error ("'##' cannot appear at either end of __VA_OPT__"); return VO_ERROR; }
    if (v->state == 2) v->state++;
    was = v->last_paste;
    v->last_paste = 0;
    if (t->type == T_PASTE) v->last_paste = 1;
    else if (t->type == T_OPEN_PAREN) v->state++;
    else if (t->type == T_CLOSE_PAREN) {
      v->state--;
      if (v->state == 2) {
        v->state = 0;
        if (was) { error ("'##' cannot appear at either end of __VA_OPT__"); return VO_ERROR; }
        return VO_END;
      }
    }
    return v->update;
  }
  return VO_INCLUDE;
}
static void replace_args (struct hnode *node, struct macro *m, struct arg *args, struct vloc *exp)
{
  struct tbuf b;
  long limit = macro_count (m), srci;
  struct vaopt vo;
  long vaopt_start = -1;   /* the last token before __VA_OPT__'s contents, -1 none */
  b.t = 0; b.vl = 0; b.n = 0; b.room = 0;
  for (srci = 0; srci < limit; srci++) {
    struct tok *src = &m->toks[srci];
    if (src->type == T_MACRO_ARG) {
      struct arg *a = &args[src->argno - 1];
      if (src->flags & STRINGIFY_ARG) { if (!a->str) a->str = stringify_arg (a->first, a->count); }
      else if ((src->flags & PASTE_LEFT) || (srci > 0 && (src[-1].flags & PASTE_LEFT))) ;
      else if (!a->expanded) expand_arg (a);
    }
  }
  vo.arg = &args[m->paramc - 1]; vo.variadic = m->variadic; vo.last_paste = 0; vo.stringify = 0; vo.state = 0; vo.update = VO_ERROR;
  for (srci = 0; srci < limit; srci++) {
    struct tok *src = &m->toks[srci];
    long count = 0, k;
    struct tok **from = 0;
    struct vloc *fromvl = 0;
    int paste_flag = -1;    /* the index in b of the token whose PASTE_LEFT becomes src's */
    int vs = vaopt_update (&vo, src);
    struct vloc l;
    if (vs != VO_INCLUDE) {
      if (vs == VO_BEGIN) {
        if (srci > 0 && !(src[-1].flags & PASTE_LEFT)) { struct tok *t = padding_token (src); mkvloc (exp, &t->loc, &l); tb_add (&b, t, &l); }
        vaopt_start = b.n - 1;
      } else if (vs == VO_END) {
        long start = vaopt_start;
        long pf = b.n - 1;
        vaopt_start = -1;
        if (vo.stringify) {
          long cnt = start >= 0 ? pf - start : b.n, i, j;
          long first0 = start >= 0 ? start + 1 : 0;
          struct tok *t;
          for (i = 0, j = 0; i < cnt; i++, j++) {
            struct tok *tk = b.t[first0 + i];
            if (tk->flags & PASTE_LEFT) {
              struct tok *rhs;
              do {
                rhs = b.t[first0 + ++i];
                if (!paste_tokens (&tk, rhs)) { --i; break; }
              } while (rhs->flags & PASTE_LEFT);
            }
            b.t[first0 + j] = tk;
          }
          if (j != i) { b.n -= i - j; cnt = j; }
          t = stringify_arg (b.t + first0, cnt);
          b.n -= cnt;
          if (src->flags & PASTE_LEFT) t = copy_paste_flag (t, src);
          tb_add (&b, t, 0);
          continue;
        }
        if (start >= 0 && pf == start && (b.t[start]->flags & PASTE_LEFT)) b.t[start] = copy_paste_flag (b.t[start], &pps->avoid_paste);
        if (src->flags & PASTE_LEFT) {
          while (pf >= 0 && pf != start && b.t[pf] == &pps->avoid_paste) { b.n--; pf = b.n - 1; }
          if (pf >= 0 && b.t[pf]->type != T_PADDING) b.t[pf] = copy_paste_flag (b.t[pf], src);
        } else tb_add (&b, &pps->avoid_paste, 0);
      }
      continue;
    }
    if (src->type != T_MACRO_ARG) {
      mkvloc (exp, &src->loc, &l);
      tb_add (&b, src, &l);
      continue;
    }
    {
      struct arg *a = &args[src->argno - 1];
      if (src->flags & STRINGIFY_ARG) { count = 1; from = &a->str; fromvl = 0; }
      else if (src->flags & PASTE_LEFT) { count = a->count; from = a->first; fromvl = a->vl; }
      else if (srci > 0 && (src[-1].flags & PASTE_LEFT)) {
        count = a->count; from = a->first; fromvl = a->vl;
        if (b.n != 0) {
          long last = b.n - 1;
          if (b.t[last]->type == T_COMMA && m->variadic && src->argno == m->paramc) {
            if (a->omitted) b.n--;
            else paste_flag = (int) last;
          } else if (count == 0) paste_flag = (int) last;
        }
      } else {
        count = a->ecount; from = a->exp; fromvl = a->evl;
        if (vaopt_start >= 0 && b.n - 1 == vaopt_start) {
          while (count && from[0]->type == T_PADDING) { from++; fromvl++; count--; }
        }
      }
      if ((!pps->in_directive || pps->directive_wants_padding) && srci > 0 && !(src[-1].flags & PASTE_LEFT) && !(vaopt_start >= 0 && b.n - 1 == vaopt_start)) {
        struct tok *t = padding_token (src);
        mkvloc (exp, &t->loc, &l);
        tb_add (&b, t, &l);
      }
      if (count) {
        for (k = 0; k < count; k++) {
          struct tok *tk = from[k];
          if (fromvl) argvloc (exp, &fromvl[k], &l); else argvloc (exp, &tk->loc, &l);
          tb_add (&b, tk, &l);
        }
        if (src->flags & PASTE_LEFT) paste_flag = (int) (b.n - 1);
      }
      if (!pps->in_directive && !(src->flags & PASTE_LEFT)) tb_add (&b, &pps->avoid_paste, 0);
      if (paste_flag >= 0) b.t[paste_flag] = copy_paste_flag (b.t[paste_flag], src);
    }
  }
  push_ctx (node, b.t, b.vl, b.n, 1);
}

static int builtin_macro (struct hnode *node, struct vloc *loc);
static int enter_macro (struct hnode *node, struct tok *result, struct vloc *loc)
{
  pps->mi_valid = 0;
  pps->angled_headers = 0;
  pps->about_to_expand = 1;
  if (node->type == NT_USER) {
    struct macro *m = node->macro;
    struct tok **pragma_buf = 0;
    long npragma = 0;
    if (m->fun_like) {
      struct arg *args;
      long nargs = 0;
      pps->prevent_expansion++; pps->keep_tokens++; pps->parsing_args = 1;
      args = funlike_invocation (node, &pragma_buf, &npragma, &nargs);
      pps->parsing_args = 0; pps->keep_tokens--; pps->prevent_expansion--;
      if (!args) { pps->about_to_expand = 0; return 0; }
      if (m->paramc > 0) replace_args (node, m, args, loc);
    }
    node->flags |= N_DISABLED;
    m->used = 1;
    if (m->paramc == 0) {
      long n = macro_count (m), i;
      struct tok **t = alloc ((n + 1) * sizeof (struct tok *));
      struct vloc *vl = alloc ((n + 1) * sizeof (struct vloc));
      for (i = 0; i < n; i++) { t[i] = &m->toks[i]; mkvloc (loc, &m->toks[i].loc, &vl[i]); }
      push_ctx (node, t, vl, n, 1);
    }
    if (npragma) {
      if (!pps->in_directive) push_token_ctx (0, padding_token (result));
      push_ctx (0, pragma_buf, 0, npragma, 0);
      pps->about_to_expand = 0;
      return 2;
    }
    pps->about_to_expand = 0;
    return 1;
  }
  pps->about_to_expand = 0;
  return builtin_macro (node, loc);
}

/* ---- the answers of __has_builtin and its kin: the target's gcc's (--predef) */
static long has_answer (char *kind, unsigned char *name, long n)
{
  long kl = slen (kind);
  unsigned char *key = alloc (kl + n + 2);
  struct has *h = pps->has;
  mcopy (key, (unsigned char *) kind, kl); key[kl] = ' '; mcopy (key + kl + 1, name, n);
  while (h) { if (msame (h->key, h->klen, key, kl + 1 + n)) return h->value; h = h->next; }
  if (pps->collect) {
    /* one write, as other preprocessors write theirs to the same pipe */
    unsigned char *l = alloc (kl + n + 16);
    mcopy (l, (unsigned char *) "cpp: query ", 11); mcopy (l + 11, key, kl + 1 + n); l[12 + kl + n] = '\n';
    perr_bytes (l, kl + n + 13);
    return 0;
  }
  fatal2 ("no answer in --predef for ", key, kl + 1 + n);
  return 0;
}
/* the name in __has_builtin (name) and its kin (c_common_lex_availability_macro, c_common_has_attribute) */
static long has_query (char *kind)
{
  struct tok *t = get_token_no_padding ();
  unsigned char nb[512];
  long n = 0, depth;
  if (t->type != T_OPEN_PAREN) { error ("missing '(' after __has_"); return 0; }
  t = get_token_no_padding ();
  if (t->type != T_NAME) {
    error ("macro __has_ requires an identifier");
    if (t->type == T_CLOSE_PAREN) return 0;
  } else {
    n = spell (t, nb);
    t = get_token_no_padding ();
    if (kind[0] == 'a' || kind[0] == 'c') {
      /* vendor::attr: :: (or : : with COLON_SCOPE) then a name */
      if (t->type == T_SCOPE || (t->type == T_COLON && (t->flags & COLON_SCOPE))) {
        if (t->type == T_COLON) t = get_token_no_padding ();
        t = get_token_no_padding ();
        nb[n++] = ':'; nb[n++] = ':';
        if (t->type == T_NAME && n + t->node->len < 500) n += spell (t, nb + n);
        t = get_token_no_padding ();
      }
    }
  }
  depth = 1;
  for (;;) {
    if (t->type == T_OPEN_PAREN) depth++;
    else if (t->type == T_CLOSE_PAREN) depth--;
    else if (t->type == T_EOF) break;
    if (!depth) break;
    t = get_token_no_padding ();
  }
  if (n == 0) return 0;
  return has_answer (kind, nb, n);
}

static int has_header (unsigned char *fname, long n, int angle, int type);
static long builtin_has_include (struct hnode *op, int next)
{
  struct tok *t;
  int paren, bracket, sav = pps->directive_wants_padding;
  long result = 0;
  unsigned char *fname = 0; long fn = 0;
  if (!pps->in_directive) error ("__has_include used outside of preprocessing directive");
  pps->angled_headers = 1;
  pps->directive_wants_padding = 1;
  t = get_token_no_padding ();
  paren = t->type == T_OPEN_PAREN;
  if (paren) t = get_token_no_padding (); else error ("missing '(' before __has_include operand");
  pps->angled_headers = 0;
  pps->directive_wants_padding = sav;
  bracket = t->type != T_STRING;
  if (t->type == T_STRING || t->type == T_HEADER_NAME) { fname = t->text + 1; fn = t->len - 2; }
  else if (t->type == T_LESS) {
    /* _cpp_bracket_include: the tokens to the > */
    long room = 256; unsigned char *d = alloc (room);
    for (;;) {
      t = get_token_no_padding ();
      if (t->type == T_GREATER) break;
      if (t->type == T_EOF) { error ("missing terminating > character"); break; }
      stringify_buf (&d, &fn, &room, spell_len (t) + 4);
      if (t->flags & PREV_WHITE) d[fn++] = ' ';
      fn += spell (t, d + fn);
    }
    fname = d;
  } else error ("operator __has_include requires a header-name");
  if (fname) {
    if (!pps->skip_eval && has_header (fname, fn, bracket, next ? IT_INCLUDE_NEXT : IT_INCLUDE)) result = 1;
  }
  if (paren && get_token_no_padding ()->type != T_CLOSE_PAREN) error ("missing ')' after __has_include operand");
  return result;
}
static void do_pragma_text (unsigned char *text, long n, struct vloc *loc);
static struct tok *get_pragma_string (void)
{
  struct tok *paren, *s;
  paren = get_token_no_padding ();
  if (paren->type == T_EOF) backup_tokens (1);
  if (paren->type != T_OPEN_PAREN) return 0;
  s = get_token_no_padding ();
  if (s->type == T_EOF) backup_tokens (1);
  if (s->type != T_STRING && s->type != T_WSTRING && s->type != T_STRING32 && s->type != T_STRING16 && s->type != T_UTF8STRING) return 0;
  paren = get_token_no_padding ();
  if (paren->type == T_EOF) backup_tokens (1);
  if (paren->type != T_CLOSE_PAREN) return 0;
  return s;
}
static int builtin_macro (struct hnode *node, struct vloc *loc)
{
  unsigned char b[64], *text = b;
  long n = 0, numv = 1;
  int isnum = 1;
  struct buf *pb;
  struct tok *t, **ta;
  struct vloc *va;
  if (node->builtin == BT_PRAGMA) {
    struct tok *s;
    if (pps->in_directive || pps->ignore_pragma) return 0;
    pps->keep_tokens++;
    s = get_pragma_string ();
    pps->keep_tokens--;
    pps->dres.type = T_PADDING;
    if (s) { do_pragma_text (s->text, s->len, loc); return 1; }
    error ("_Pragma takes a parenthesized string literal");
    return 0;
  }
  if (node->builtin == BT_FILE || node->builtin == BT_FILE_NAME || node->builtin == BT_BASE_FILE) {
    unsigned char *name; long nl, i, k = 0;
    if (node->builtin == BT_BASE_FILE) { name = pps->main_file->name; nl = pps->main_file->nlen; }
    else { name = pps->curmap->name; nl = pps->curmap->nlen; }
    if (node->builtin == BT_FILE_NAME) { i = nl; while (i > 0 && name[i - 1] != '/') i--; name += i; nl -= i; }
    text = alloc (nl * 2 + 3);
    text[k++] = '"';
    for (i = 0; i < nl; i++) {
      int c = name[i];
      if (c == '\n') { text[k++] = '\\'; text[k++] = 'n'; }
      else { if (c == '\\' || c == '"') text[k++] = '\\'; text[k++] = c; }
    }
    text[k++] = '"';
    n = k; isnum = 0;
  } else if (node->builtin == BT_LINE) numv = loc->lno;
  else if (node->builtin == BT_INCLUDE_LEVEL) numv = pps->curmap->depth - 1;
  else if (node->builtin == BT_COUNTER) numv = pps->counter++;
  else if (node->builtin == BT_DATE || node->builtin == BT_TIME || node->builtin == BT_TIMESTAMP) {
    fatal2 ("not reproducible: ", node->name, node->len);
  } else if (node->builtin == BT_HAS_ATTRIBUTE) numv = has_query ("attribute");
  else if (node->builtin == BT_HAS_STD_ATTRIBUTE) numv = has_query ("c_attribute");
  else if (node->builtin == BT_HAS_BUILTIN) numv = has_query ("builtin");
  else if (node->builtin == BT_HAS_FEATURE) numv = has_query ("feature");
  else if (node->builtin == BT_HAS_EXTENSION) numv = has_query ("extension");
  else if (node->builtin == BT_HAS_INCLUDE) numv = builtin_has_include (node, 0);
  else if (node->builtin == BT_HAS_INCLUDE_NEXT) numv = builtin_has_include (node, 1);
  else if (node->builtin == BT_HAS_EMBED) fatal ("__has_embed is not supported");
  if (isnum) n = numtext ((unsigned long) (unsigned int) numv, b);
  push_text (text, n);
  pb = pps->buffer;
  t = temp_token ();
  lex_direct_into (t, 0);
  pps->buffer = pb->prev;
  t->loc = *loc;
  ta = alloc (sizeof (struct tok *)); va = alloc (sizeof (struct vloc));
  ta[0] = t;
  va[0] = *loc; va[0].bi = 1;
  push_ctx (node, ta, va, 1, 1);
  return 1;
}
/* the printer's avoid_paste (cpp_avoid_paste) */
static int avoid_paste (struct tok *tk1, struct tok *tk2)
{
  int a = tk1->type, b = tk2->type, c = -1;
  if (tk1->flags & NAMED_OP) a = T_NAME;
  if (tk2->flags & NAMED_OP) b = T_NAME;
  if (tk2->flags & DIGRAPH) c = digraphs[b - T_HASH][0];
  else if (spell_kind (b) == 0) c = opname[b][0];
  if (a <= T_LSHIFT && c == '=') return 1;
  if (a == T_GREATER) return c == '>';
  if (a == T_LESS) return c == '<' || c == '%' || c == ':';
  if (a == T_PLUS) return c == '+';
  if (a == T_MINUS) return c == '-' || c == '>';
  if (a == T_DIV) return c == '/' || c == '*';
  if (a == T_MOD) return c == ':' || c == '>';
  if (a == T_AND) return c == '&';
  if (a == T_OR) return c == '|';
  if (a == T_COLON) return c == ':' || c == '>';
  if (a == T_DEREF) return c == '*';
  if (a == T_DOT) return c == '.' || c == '%' || b == T_NUMBER;
  if (a == T_HASH) return c == '#' || c == '%';
  if (a == T_NAME || a == T_PRAGMA) {
    if (b == T_NUMBER) { long i = 0; while (i < tk2->len) { if (!isidnum (tk2->text[i])) return 0; i++; } return 1; }
    return b == T_NAME || b == T_CHAR || b == T_STRING;
  }
  if (a == T_NUMBER) return b == T_NUMBER || b == T_NAME || b == T_CHAR || c == '.' || c == '+' || c == '-';
  if (a == T_OTHER) return tk1->text[0] == '\\' && b == T_NAME;
  if (a == T_LESS_EQ) return c == '>';
  return 0;
}

/* ---- #if's expressions (expr.cc): intmax_t, 64 bits on every target (long long: long is 32 on arm) */
struct num { unsigned long long v; int uns; };
struct ex { long lex_count; int saw_leading_not; int err; struct tok *t; };
static void ex_next (struct ex *e)
{
  for (;;) {
    e->t = get_token ();
    if (e->t->type != T_PADDING) break;
  }
  e->lex_count++;
}
static int ex_digit (int c, int base)
{
  int d = c >= '0' && c <= '9' ? c - '0' : c >= 'a' && c <= 'z' ? c - 'a' + 10 : c >= 'A' && c <= 'Z' ? c - 'A' + 10 : 99;
  return d < base ? d : -1;
}
static void ex_number (struct tok *t, struct num *r)   /* cpp_classify_number + cpp_interpret_integer */
{
  unsigned char *s = t->text;
  long n = t->len, i = 0, j;
  int base = 10, ok = 1, uns = 0, over = 0;
  unsigned long long v = 0;
  r->v = 0; r->uns = 0;
  if (n >= 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) { base = 16; i = 2; }
  else if (n >= 2 && s[0] == '0' && (s[1] == 'b' || s[1] == 'B')) { base = 2; i = 2; }
  else if (s[0] == '0') base = 8;
  for (j = i; j < n; j++) if (s[j] == '.' || ((s[j] == 'e' || s[j] == 'E') && base != 16) || ((s[j] == 'p' || s[j] == 'P') && base == 16)) { error ("floating constant in preprocessor expression"); return; }
  while (i < n) {
    int d = ex_digit (s[i], base);
    if (d < 0) break;
    if (v > (~0ULL - (unsigned long long) d) / (unsigned long long) base) over = 1;
    v = v * (unsigned long long) base + (unsigned long long) d;
    i++;
  }
  /* the suffix: u, l, ll (and ul ...), wb, uwb */
  {
    long u = 0, l = 0, k = i;
    while (k < n) {
      if (s[k] == 'u' || s[k] == 'U') u++;
      else if (s[k] == 'l' || s[k] == 'L') { if (k + 1 < n && s[k + 1] == s[k]) k++; l++; }
      else if ((s[k] == 'w' && k + 1 < n && s[k + 1] == 'b') || (s[k] == 'W' && k + 1 < n && s[k + 1] == 'B')) { k++; l++; }
      else { ok = 0; break; }
      k++;
    }
    if (u > 1 || l > 1) ok = 0;
    uns = u != 0;
  }
  if (!ok) { error2 ("invalid suffix on integer constant ", t->text, t->len); return; }
  if (over) error ("integer constant is too large for its type");
  else if (!uns && (long long) v < 0) uns = 1;
  r->v = v; r->uns = uns;
}
static int hexval (int c) { return c >= '0' && c <= '9' ? c - '0' : c >= 'a' && c <= 'f' ? c - 'a' + 10 : c >= 'A' && c <= 'F' ? c - 'A' + 10 : -1; }
static void ex_char (struct tok *t, struct num *r)   /* cpp_interpret_charconst */
{
  unsigned char *s = t->text, *e = t->text + t->len - 1;
  int wide = t->type != T_CHAR && t->type != T_UTF8CHAR;
  long width = wide ? (t->type == T_CHAR16 ? 16 : t->type == T_CHAR32 ? 32 : pps->wchar_bits) : 8;
  int unsignedp;
  unsigned long long res = 0, c;
  long count = 0;
  while (*s != '\'') s++;
  s++;
  while (s < e) {
    if (*s == '\\') {
      s++;
      if (*s == 'x') { c = 0; s++; while (s < e && hexval (*s) >= 0) { c = c * 16 + hexval (*s); s++; } }
      else if (*s >= '0' && *s <= '7') { int k = 0; c = 0; while (k < 3 && s < e && *s >= '0' && *s <= '7') { c = c * 8 + (*s - '0'); s++; k++; } }
      else if (*s == 'u' || *s == 'U') {
        int k = *s == 'u' ? 4 : 8; c = 0; s++;
        while (k-- > 0 && s < e) { c = c * 16 + hexval (*s); s++; }
        if (!wide && c >= 0x80) {
          /* UTF-8 bytes */
          unsigned char u[4]; int m = 0, q;
          if (c < 0x800) { u[0] = 0xc0 | (c >> 6); u[1] = 0x80 | (c & 63); m = 2; }
          else if (c < 0x10000) { u[0] = 0xe0 | (c >> 12); u[1] = 0x80 | ((c >> 6) & 63); u[2] = 0x80 | (c & 63); m = 3; }
          else { u[0] = 0xf0 | (c >> 18); u[1] = 0x80 | ((c >> 12) & 63); u[2] = 0x80 | ((c >> 6) & 63); u[3] = 0x80 | (c & 63); m = 4; }
          for (q = 0; q < m; q++) { res = (res << 8) | u[q]; count++; }
          continue;
        }
      } else {
        int x = *s++;
        c = x == 'n' ? 10 : x == 't' ? 9 : x == 'r' ? 13 : x == 'a' ? 7 : x == 'b' ? 8 : x == 'f' ? 12 : x == 'v' ? 11 : x == 'e' || x == 'E' ? 27 : (unsigned long long) x;
      }
    } else if (wide && *s >= 0xc0 && utf8_len (s)) {
      int m = utf8_len (s), q;
      c = *s & (m == 2 ? 31 : m == 3 ? 15 : 7);
      for (q = 1; q < m; q++) c = (c << 6) | (s[q] & 63);
      s += m;
    } else c = *s++;
    if (wide) res = c; else res = (res << 8) | (c & 255);
    count++;
  }
  if (wide) {
    unsignedp = t->type == T_WCHAR ? pps->wchar_unsigned : 1;
  } else {
    if (count > 1) { unsignedp = 0; width = 32; }
    else unsignedp = t->type == T_UTF8CHAR ? 1 : pps->uchar;
  }
  if (width < 64) {
    unsigned long long mask = (1ULL << width) - 1;
    if (unsignedp || !(res & (1ULL << (width - 1)))) res &= mask;
    else res |= ~mask;
  }
  r->v = res; r->uns = 0;
  if (!unsignedp && width == 32 && (res & 0x80000000ULL)) r->v = res | 0xffffffff00000000ULL;
  if (wide && unsignedp) r->uns = 0;
}
static void ex_defined (struct ex *e, struct num *r)   /* parse_defined */
{
  int paren = 0;
  struct hnode *node = 0;
  struct tok *t;
  pps->prevent_expansion++;
  t = get_token_no_padding ();
  if (t->type == T_OPEN_PAREN) { paren = 1; t = get_token_no_padding (); }
  if (t->type == T_NAME) {
    node = t->node;
    if (paren && get_token_no_padding ()->type != T_CLOSE_PAREN) { error ("missing ')' after \"defined\""); node = 0; }
  } else error ("operator \"defined\" requires an identifier");
  r->v = 0; r->uns = 0;
  if (node) {
    r->v = node->type == NT_USER || node->type == NT_BUILTIN;
    pps->mi_ind_cmacro = node;
  }
  pps->prevent_expansion--;
}
static void ex_cond (struct ex *e, struct num *r);
static void ex_comma (struct ex *e, struct num *r);
static void ex_unary (struct ex *e, struct num *r)
{
  struct tok *t = e->t;
  int ty = t->type;
  r->v = 0; r->uns = 0;
  if (e->err) return;
  if (ty == T_NUMBER) { ex_number (t, r); ex_next (e); return; }
  if (ty >= T_CHAR && ty <= T_UTF8CHAR) { ex_char (t, r); ex_next (e); return; }
  if (ty == T_NAME) {
    if (t->node == pps->n_defined) { ex_defined (e, r); ex_next (e); return; }
    if (pps->true_false && t->node == pps->n_true) r->v = 1;
    ex_next (e);
    return;
  }
  if (ty == T_OPEN_PAREN) {
    ex_next (e);
    ex_comma (e, r);
    if (e->t->type != T_CLOSE_PAREN) { if (!e->err) error ("missing ')' in expression"); e->err = 1; return; }
    ex_next (e);
    return;
  }
  if (ty == T_NOT || ty == T_MINUS || ty == T_PLUS || ty == T_COMPL) {
    if (ty == T_NOT && e->lex_count == 1) e->saw_leading_not = 1;
    ex_next (e);
    ex_unary (e, r);
    if (ty == T_NOT) { r->v = r->v == 0; r->uns = 0; }
    else if (ty == T_MINUS) r->v = 0 - r->v;
    else if (ty == T_COMPL) r->v = ~r->v;
    return;
  }
  if (ty == T_HASH) { error ("assertions are not supported"); e->err = 1; return; }
  if (!e->err) {
    if (ty == T_EOF) error ("#if with no expression");
    else { unsigned char b[64]; long n = spell (t, b); error2 ("token is not valid in preprocessor expressions: ", b, n); }
  }
  e->err = 1;
}
static int prec (int ty)
{
  if (ty == T_MULT || ty == T_DIV || ty == T_MOD) return 10;
  if (ty == T_PLUS || ty == T_MINUS) return 9;
  if (ty == T_LSHIFT || ty == T_RSHIFT) return 8;
  if (ty == T_LESS || ty == T_GREATER || ty == T_LESS_EQ || ty == T_GREATER_EQ) return 7;
  if (ty == T_EQ_EQ || ty == T_NOT_EQ) return 6;
  if (ty == T_AND) return 5;
  if (ty == T_XOR) return 4;
  if (ty == T_OR) return 3;
  if (ty == T_AND_AND) return 2;
  if (ty == T_OR_OR) return 1;
  return 0;
}
static void ex_binop (int op, struct num *a, struct num *b)
{
  int uns = a->uns || b->uns;
  unsigned long long x = a->v, y = b->v;
  if (op == T_MULT) { a->v = x * y; a->uns = uns; }
  else if (op == T_DIV || op == T_MOD) {
    if (y == 0) { if (!pps->skip_eval) error ("division by zero in #if"); a->v = 0; a->uns = uns; return; }
    if (uns) a->v = op == T_DIV ? x / y : x % y;
    else {
      long long sx = (long long) x, sy = (long long) y;
      if (sy == -1) a->v = op == T_DIV ? 0 - x : 0;
      else a->v = (unsigned long long) (op == T_DIV ? sx / sy : sx % sy);
    }
    a->uns = uns;
  }
  else if (op == T_PLUS) { a->v = x + y; a->uns = uns; }
  else if (op == T_MINUS) { a->v = x - y; a->uns = uns; }
  else if (op == T_LSHIFT || op == T_RSHIFT) {
    /* the count's sign decides, the left operand's type the result's */
    long long n = (long long) y; int left = op == T_LSHIFT;
    if (!b->uns && n < 0) { left = !left; n = -n; }
    if (b->uns && (long long) y < 0) n = 64;
    if (left) a->v = n >= 64 ? 0 : x << n;
    else if (a->uns) a->v = n >= 64 ? 0 : x >> n;
    else { long long sx = (long long) x; a->v = (unsigned long long) (n >= 64 ? (sx < 0 ? -1 : 0) : sx >> n); }
  }
  else if (op == T_LESS || op == T_GREATER || op == T_LESS_EQ || op == T_GREATER_EQ) {
    int lt, gt;
    if (uns) { lt = x < y; gt = x > y; } else { lt = (long long) x < (long long) y; gt = (long long) x > (long long) y; }
    a->v = op == T_LESS ? lt : op == T_GREATER ? gt : op == T_LESS_EQ ? !gt : !lt;
    a->uns = 0;
  }
  else if (op == T_EQ_EQ) { a->v = x == y; a->uns = 0; }
  else if (op == T_NOT_EQ) { a->v = x != y; a->uns = 0; }
  else if (op == T_AND) { a->v = x & y; a->uns = uns; }
  else if (op == T_XOR) { a->v = x ^ y; a->uns = uns; }
  else if (op == T_OR) { a->v = x | y; a->uns = uns; }
}
static void ex_bin (struct ex *e, struct num *r, int minp)
{
  ex_unary (e, r);
  for (;;) {
    int op = e->t->type, p = prec (op);
    struct num b;
    if (e->err || p == 0 || p < minp) return;
    ex_next (e);
    if (op == T_AND_AND || op == T_OR_OR) {
      int skip = op == T_AND_AND ? r->v == 0 : r->v != 0;
      if (skip) pps->skip_eval++;
      ex_bin (e, &b, p + 1);
      if (skip) pps->skip_eval--;
      r->v = op == T_AND_AND ? (r->v != 0 && b.v != 0) : (r->v != 0 || b.v != 0);
      r->uns = 0;
    } else {
      ex_bin (e, &b, p + 1);
      ex_binop (op, r, &b);
    }
  }
}
static void ex_cond (struct ex *e, struct num *r)
{
  struct num a, b;
  ex_bin (e, r, 1);
  if (e->err || e->t->type != T_QUERY) return;
  ex_next (e);
  if (r->v == 0) pps->skip_eval++;
  ex_comma (e, &a);
  if (r->v == 0) pps->skip_eval--;
  if (e->err) return;
  if (e->t->type != T_COLON) { error ("'?' without following ':'"); e->err = 1; return; }
  ex_next (e);
  if (r->v != 0) pps->skip_eval++;
  ex_cond (e, &b);
  if (r->v != 0) pps->skip_eval--;
  if (r->v != 0) { r->v = a.v; } else r->v = b.v;
  r->uns = a.uns || b.uns;
}
static void ex_comma (struct ex *e, struct num *r)
{
  ex_cond (e, r);
  while (!e->err && e->t->type == T_COMMA) { ex_next (e); ex_cond (e, r); }
}
static int parse_expr (void)   /* _cpp_parse_expr: the truth of #if's expression */
{
  struct ex e;
  struct num r;
  pps->skip_eval = 0;
  pps->mi_ind_cmacro = 0;
  e.lex_count = 0; e.saw_leading_not = 0; e.err = 0;
  ex_next (&e);
  ex_comma (&e, &r);
  if (!e.err && e.t->type != T_EOF) {
    unsigned char b[64]; long n = spell (e.t, b);
    error2 ("missing binary operator before token ", b, n);
    e.err = 1;
  }
  if (pps->mi_ind_cmacro && !(e.saw_leading_not && e.lex_count == 3)) pps->mi_ind_cmacro = 0;
  if (e.err) { pps->mi_ind_cmacro = 0; return 0; }
  return r.v != 0;
}

/* ---- files and the include path (files.cc) */
static struct dir *make_dir (unsigned char *name, long n, int sysp)   /* make_cpp_dir: one per name */
{
  struct dir *d = pps->dirtab;
  while (d) { if (msame (d->name, d->len, name, n)) return d; d = d->hnext; }
  d = alloc (sizeof (struct dir));
  d->name = dup (name, n); d->len = n; d->sysp = sysp; d->next = pps->quote;
  d->hnext = pps->dirtab; pps->dirtab = d;
  return d;
}
static long read_fd (long fd, unsigned char **out)
{
  long room = 65536, n = 0;
  unsigned char *b = alloc (room + 8);
  for (;;) {
    long r;
    if (n == room) { unsigned char *x = alloc (room * 2 + 8); mcopy (x, b, n); b = x; room *= 2; }
    r = pp_read (fd, b + n, room - n);
    if (r < 0) return r;
    if (r == 0) break;
    n += r;
  }
  *out = b;
  return n;
}
static unsigned char *realpath_of (unsigned char *path, long n, long *outn);
static int open_file (struct file *f)
{
  long fd = pp_open ((char *) f->path), n;
  unsigned char *b;
  if (fd < 0) return 0;
  n = read_fd (fd, &b);
  pp_close (fd);
  if (n < 0) return 0;   /* a directory: go on searching */
  f->raw = b; f->size = n;
  return 1;
}
static unsigned char *append_dir (struct dir *d, unsigned char *fname, long fn, long *outn)
{
  long dirlen = d->len, k = 0;
  unsigned char *p = alloc (dirlen + fn + 2);
  mcopy (p, d->name, dirlen); k = dirlen;
  if (dirlen && p[dirlen - 1] != '/') p[k++] = '/';
  mcopy (p + k, fname, fn); k += fn; p[k] = 0;
  *outn = k;
  return p;
}
static int find_in_dir (struct file *f)
{
  long n;
  unsigned char *path = append_dir (f->dir, f->name, f->nlen, &n);
  f->path = path; f->plen = n;
  if (!open_file (f)) return 0;
  if (f->dir->sysp) {
    long rn; unsigned char *r = realpath_of (path, n, &rn);
    if (r && rn < n) { f->path = r; f->plen = rn; }
  }
  return 1;
}
static struct fent *fent_find (struct fent *e, struct dir *start)
{
  while (e && e->start != start) e = e->next;
  return e;
}
static struct file *find_file (unsigned char *fname, long fn, struct dir *start, int fake)   /* _cpp_find_file */
{
  long h = hashof (fname, fn) & 4095;
  struct fent *e;
  struct file *f;
  int saw_bracket = 0, saw_quote = 0;
  struct dir *found_in_cache = 0;
  e = 0;
  {
    struct fent *x = pps->ftab[h];
    while (x) { if (msame (x->name, x->nlen, fname, fn) && x->start == start) { e = x; break; } x = x->next; }
  }
  if (e) return e->f;
  f = alloc (sizeof (struct file));
  f->name = dup (fname, fn); f->nlen = fn; f->dir = start;
  e = 0;
  if (!fake) for (;;) {
    if (find_in_dir (f)) { f->found = 1; break; }
    f->dir = f->dir->next;
    if (f->dir == 0) { f->path = f->name; f->plen = f->nlen; break; }
    if (f->dir == pps->bracket) saw_bracket = 1;
    else if (f->dir == pps->quote) saw_quote = 1;
    else continue;
    {
      struct fent *x = pps->ftab[h];
      while (x) { if (msame (x->name, x->nlen, fname, fn) && x->start == f->dir) { e = x; break; } x = x->next; }
    }
    if (e) { found_in_cache = f->dir; break; }
  }
  if (e) f = e->f;
  else { f->next_all = pps->all_files; pps->all_files = f; }
  e = alloc (sizeof (struct fent));
  e->name = f->name; e->nlen = fn; e->start = start; e->f = f; e->next = pps->ftab[h]; pps->ftab[h] = e;
  if (saw_bracket && pps->bracket != start && found_in_cache != pps->bracket) {
    e = alloc (sizeof (struct fent));
    e->name = f->name; e->nlen = fn; e->start = pps->bracket; e->f = f; e->next = pps->ftab[h]; pps->ftab[h] = e;
  }
  if (saw_quote && pps->quote != start && found_in_cache != pps->quote) {
    e = alloc (sizeof (struct fent));
    e->name = f->name; e->nlen = fn; e->start = pps->quote; e->f = f; e->next = pps->ftab[h]; pps->ftab[h] = e;
  }
  return f;
}
static unsigned char *dir_name_of (struct file *f, long *n)
{
  long i = f->plen;
  while (i > 0 && f->path[i - 1] != '/') i--;
  *n = i;
  return f->path;
}
static struct dir *search_path_head (unsigned char *fname, long fn, int angle, int type)
{
  struct file *f;
  struct dir *d;
  if ((fn > 0 && fname[0] == '/') || fn == 0) return pps->no_search;
  f = pps->buffer ? pps->buffer->file : pps->main_file;
  if (type == IT_INCLUDE_NEXT && f && f->dir && f->dir != pps->no_search) d = f->dir->next;
  else if (angle) d = pps->bracket;
  else if (type == IT_CMDLINE) return make_dir ((unsigned char *) "./", 2, 0);
  else {
    long n; unsigned char *dn = dir_name_of (f, &n);
    return make_dir (dn, n, pps->buffer ? pps->buffer->sysp : 0);
  }
  if (d == 0) error2 ("no include path in which to search for ", fname, fn);
  return d;
}
static int has_header (unsigned char *fname, long fn, int angle, int type)
{
  struct dir *d = search_path_head (fname, fn, angle, type);
  struct file *f;
  if (!d) return 0;
  f = find_file (fname, fn, d, 0);
  return f->found;
}
static int unique_contents (struct file *f)   /* has_unique_contents: the same bytes as a once-only file? */
{
  struct file *x = pps->all_files;
  if (!pps->seen_once_only) return 1;
  while (x) {
    if (x != f && x->once_only && x->found && x->size == f->size && msame (x->raw, x->size, f->raw, f->size)) return 0;
    x = x->next_all;
  }
  return 1;
}
static int stack_file (struct file *f, int type, long inc_line)
{
  int sysp = 0;
  struct buf *b;
  if (!f->found) return 0;
  if (!unique_contents (f)) return 0;
  if (pps->buffer && f->dir) sysp = pps->buffer->sysp > f->dir->sysp ? pps->buffer->sysp : f->dir->sysp;
  if (!f->clean) clean_file (f);
  f->stack_count++;
  b = push_buffer (f->clean, f->clen);
  b->notes = f->notes; b->nnotes = f->nnotes;
  b->file = f;
  b->sysp = sysp;
  pps->mi_valid = 1;
  pps->mi_cmacro = 0;
  do_file_change (LC_ENTER, f->path, f->plen, 1, sysp, inc_line);
  return 1;
}
static int stack_include (unsigned char *fname, long fn, int angle, int type)
{
  struct dir *d = search_path_head (fname, fn, angle, type);
  struct file *f;
  long inc_line;
  if (!d) return 0;
  f = find_file (fname, fn, d, 0);
  if (!f->found) {
    if (type == IT_DEFAULT) return 0;   /* gcc's preinclude, when there is none */
    fatal2 ("no such file: ", fname, fn);
  }
  if (type == IT_IMPORT) { pps->seen_once_only = 1; f->once_only = 1; if (f->stack_count) return 0; }
  if (f->once_only) return 0;
  if (f->cmacro && (f->cmacro->type == NT_USER || f->cmacro->type == NT_BUILTIN)) return 0;
  inc_line = type == IT_CMDLINE || type == IT_DEFAULT ? pps->lno : pps->lno - 1;
  return stack_file (f, type, inc_line);
}
/* realpath (3), for the canonical path of a file in a system directory */
static unsigned char *realpath_of (unsigned char *path, long n, long *outn)
{
  unsigned char *r, *rest;
  long rn = 0, i = 0, room, links = 0, restn;
  if (n == 0) return 0;
  room = n + pps->cwdlen + 4096;
  r = alloc (room);
  rest = alloc (n + 4096 + 1);
  mcopy (rest, path, n); restn = n;
  if (rest[0] != '/') { mcopy (r, pps->cwd, pps->cwdlen); rn = pps->cwdlen; }
  while (i < restn) {
    long s, seglen;
    while (i < restn && rest[i] == '/') i++;
    if (i >= restn) break;
    s = i;
    while (i < restn && rest[i] != '/') i++;
    seglen = i - s;
    if (seglen == 1 && rest[s] == '.') continue;
    if (seglen == 2 && rest[s] == '.' && rest[s + 1] == '.') { while (rn > 0 && r[rn - 1] != '/') rn--; if (rn > 0) rn--; continue; }
    if (rn + seglen + 2 > room) return 0;
    r[rn++] = '/'; mcopy (r + rn, rest + s, seglen); rn += seglen; r[rn] = 0;
    {
      unsigned char lb[4096];
      long k = cp_readlink ((char *) r, lb, 4095);
      if (k > 0) {
        unsigned char *nr;
        long tail = restn - i;
        if (++links > 40) return 0;
        nr = alloc (k + tail + 1);
        mcopy (nr, lb, k); mcopy (nr + k, rest + i, tail);
        rest = nr; restn = k + tail; i = 0;
        if (lb[0] == '/') rn = 0; else { rn -= seglen; if (rn > 0) rn--; }
      }
    }
  }
  if (rn == 0) r[rn++] = '/';
  r[rn] = 0;
  *outn = rn;
  return r;
}

/* ---- directives (directives.cc) */
static void start_directive (void)
{
  pps->in_directive = 1;
  pps->dres.type = T_PADDING;
  pps->directive_line = pps->lno;
}
static void skip_rest_of_line (void)
{
  while (pps->ctx->prev) pop_ctx ();
  if (!seen_eol ()) while (lex_token ()->type != T_EOF) ;
}
static void end_directive (int skip_line)
{
  if (pps->in_deferred_pragma) ;
  else if (skip_line) {
    skip_rest_of_line ();
    if (!pps->keep_tokens) pps->rc = 0;
  }
  pps->in_directive = 0;
  pps->angled_headers = 0;
  pps->directive = 0;
}
static void check_eol (int expand)
{
  if (!seen_eol () && (expand ? get_token () : lex_token ())->type != T_EOF) ;   /* a pedwarn: extra tokens */
}
static struct hnode *lex_macro_node (int def)
{
  struct tok *t = lex_token ();
  if (t->type == T_NAME) {
    if (def && t->node == pps->n_defined) error ("\"defined\" cannot be used as a macro name");
    else if (!(t->node->flags & N_POISONED)) return t->node;
  } else if (t->type == T_EOF) error ("no macro name given");
  else error ("macro names must be identifiers");
  return 0;
}
static void push_conditional (int skip, int type, struct hnode *cmacro)
{
  struct ifs *i = alloc (sizeof (struct ifs));
  struct buf *b = pps->buffer;
  i->lno = pps->directive_line;
  i->next = b->if_stack;
  i->skip_elses = pps->skipping || !skip;
  i->was_skipping = pps->skipping;
  i->type = type;
  i->mi_cmacro = pps->mi_valid && pps->mi_cmacro == 0 ? cmacro : 0;
  pps->skipping = skip;
  b->if_stack = i;
}
static int defined_p (struct hnode *n) { return n->type == NT_USER || n->type == NT_BUILTIN; }
static void do_ifdef (void)
{
  int skip = 1;
  if (!pps->skipping) {
    struct hnode *n = lex_macro_node (0);
    if (n) { skip = !defined_p (n); check_eol (0); }
  }
  push_conditional (skip, D_IFDEF, 0);
}
static void do_ifndef (void)
{
  int skip = 1;
  struct hnode *n = 0;
  if (!pps->skipping) {
    n = lex_macro_node (0);
    if (n) { skip = defined_p (n); check_eol (0); }
  }
  push_conditional (skip, D_IFNDEF, n);
}
static void do_if (void)
{
  int skip = 1;
  if (!pps->skipping) skip = parse_expr () == 0;
  push_conditional (skip, D_IF, pps->mi_ind_cmacro);
}
static void do_elif (void)
{
  struct ifs *i = pps->buffer->if_stack;
  if (!i) { error ("#elif without #if"); return; }
  if (i->type == D_ELSE) error ("#elif after #else");
  i->type = D_ELIF;
  if (i->skip_elses) pps->skipping = 1;
  else {
    if (pps->directive == D_ELIF) pps->skipping = !parse_expr ();
    else {
      struct hnode *n = lex_macro_node (0);
      if (n) {
        int d = defined_p (n);
        pps->skipping = pps->directive == D_ELIFDEF ? !d : d;
        check_eol (0);
      }
    }
    i->skip_elses = !pps->skipping;
  }
  i->mi_cmacro = 0;
}
static void do_else (void)
{
  struct ifs *i = pps->buffer->if_stack;
  if (!i) { error ("#else without #if"); return; }
  if (i->type == D_ELSE) error ("#else after #else");
  i->type = D_ELSE;
  pps->skipping = i->skip_elses;
  i->skip_elses = 1;
  i->mi_cmacro = 0;
}
static void do_endif (void)
{
  struct ifs *i = pps->buffer->if_stack;
  if (!i) { error ("#endif without #if"); return; }
  if (i->next == 0 && i->mi_cmacro) { pps->mi_valid = 1; pps->mi_cmacro = i->mi_cmacro; }
  pps->buffer->if_stack = i->next;
  pps->skipping = i->was_skipping;
}
/* #define */
static int save_parameter (struct hnode *n, long idx)
{
  if (n->type == NT_ARG) { error2 ("duplicate macro parameter ", n->name, n->len); return 0; }
  n->stype = n->type; n->smacro = n->macro; n->sargidx = n->argidx;
  n->type = NT_ARG; n->argidx = idx;
  return 1;
}
static void unsave_parameters (struct hnode **params, long n)
{
  long i = 0;
  while (i < n) { struct hnode *p = params[i++]; if (p->type == NT_ARG) { p->type = p->stype; p->macro = p->smacro; p->argidx = p->sargidx; } }
}
static int parse_params (struct hnode ***pp, long *np, int *variadic)
{
  long n = 0, room = 8;
  struct hnode **params = alloc (room * sizeof (struct hnode *));
  int prev_ident = 0;
  for (;;) {
    struct tok *t = lex_token ();
    if (n + 1 >= room) { struct hnode **x = alloc (room * 2 * sizeof (struct hnode *)); long i = 0; while (i < n) { x[i] = params[i]; i++; } params = x; room *= 2; }
    if (t->type == T_NAME) {
      if (prev_ident || *variadic) goto bad;
      prev_ident = 1;
      if (!save_parameter (t->node, n + 1)) goto out;
      params[n++] = t->node;
    } else if (t->type == T_CLOSE_PAREN && (prev_ident || !n || *variadic)) {
      *pp = params; *np = n; return 1;
    } else if (t->type == T_CLOSE_PAREN || t->type == T_COMMA) {
      if (!prev_ident || *variadic) goto bad;
      prev_ident = 0;
    } else if (t->type == T_ELLIPSIS) {
      if (*variadic) goto bad;
      *variadic = 1;
      if (!prev_ident) {
        if (!save_parameter (pps->n_va_args, n + 1)) goto out;
        params[n++] = pps->n_va_args;
        pps->va_args_ok = 1;
      }
    } else goto bad;
  }
 bad:
  error ("bad macro parameter list");
 out:
  *pp = params; *np = n;
  return 0;
}
static struct macro *create_definition (void)   /* create_iso_definition */
{
  struct macro *m = alloc (sizeof (struct macro));
  struct tok first, *t;
  struct hnode **params = 0;
  long nparms = 0, room = 16, extra = 0;
  int variadic = 0, following_paste = 0, ok = 0;
  struct vaopt vo;
  lex_direct_into (&first, 0);
  t = &first;
  m->syshdr = pps->buffer && pps->buffer->sysp != 0;
  if (first.flags & PREV_WHITE) ;
  else if (first.type == T_OPEN_PAREN) {
    if (!parse_params (&params, &nparms, &variadic)) goto out;
    t = 0;
  }
  m->toks = alloc (room * sizeof (struct tok));
  if (!t) { m->variadic = variadic; m->paramc = nparms; m->params = params; m->fun_like = 1; }
  else { m->toks[0] = first; t = &m->toks[0]; m->count = 1; }
  vo.arg = 0; vo.variadic = m->variadic; vo.last_paste = 0; vo.stringify = 0; vo.state = 0; vo.update = VO_ERROR;
  for (;; t = 0) {
    if (!t) {
      if (m->count + 2 > room) { struct tok *x = alloc (room * 2 * sizeof (struct tok)); long i = 0; while (i < m->count) { x[i] = m->toks[i]; i++; } m->toks = x; room *= 2; }
      t = &m->toks[m->count];
      lex_direct_into (t, 0);
      if (t->type == T_NAME && t->node->type == NT_ARG) { t->type = T_MACRO_ARG; t->argno = t->node->argidx; }
      m->count++;
    }
    if (m->count > 1 && t[-1].type == T_HASH && m->fun_like) {
      if (t->type == T_MACRO_ARG || (m->variadic && t->type == T_NAME && t->node == pps->n_va_opt)) {
        if (t->flags & PREV_WHITE) t->flags |= SP_PREV_WHITE;
        if (t[-1].flags & DIGRAPH) t->flags |= SP_DIGRAPH;
        t->flags &= ~PREV_WHITE;
        t->flags |= STRINGIFY_ARG;
        t->flags |= t[-1].flags & PREV_WHITE;
        t[-1] = t[0];
        m->count--;
        t--;
      } else if (!pps->lang_asm) { error ("'#' is not followed by a macro parameter"); goto out; }
    }
    if (t->type == T_EOF) {
      if (following_paste) { error ("'##' cannot appear at either end of a macro expansion"); goto out; }
      if (vo.state != 0) { error ("unterminated __VA_OPT__"); goto out; }
      break;
    }
    if (t->type == T_PASTE) {
      if (m->count == 1) { error ("'##' cannot appear at either end of a macro expansion"); goto out; }
      if (following_paste) { extra++; t->argno = m->count - 1; }
      else {
        m->count--;
        t[-1].flags |= PASTE_LEFT;
        if (t->flags & DIGRAPH) t[-1].flags |= SP_DIGRAPH;
        if (t->flags & PREV_WHITE) t[-1].flags |= SP_PREV_WHITE;
      }
      following_paste = 1;
    } else following_paste = 0;
    if (vaopt_update (&vo, t) == VO_ERROR) goto out;
  }
  ok = 1;
  m->count--;
  if (m->count) m->toks[0].flags &= ~PREV_WHITE;
  if (extra) {
    struct tok *tmp = alloc (extra * sizeof (struct tok));
    long ei = 0, ni = 0, i;
    for (i = 0; i < m->count; i++) { if (m->toks[i].type == T_PASTE) tmp[ei++] = m->toks[i]; else m->toks[ni++] = m->toks[i]; }
    for (i = 0; i < extra; i++) m->toks[ni + i] = tmp[i];
    m->extra = 1;
  }
 out:
  pps->va_args_ok = 0;
  unsave_parameters (params, nparms);
  return ok ? m : 0;
}
static void do_define (void)
{
  struct hnode *n = lex_macro_node (1);
  if (n) {
    struct macro *m;
    pps->cur_macro_node = n;
    m = create_definition ();
    if (m) {
      n->type = NT_USER; n->macro = m;
      if (n->len > 7 && is (n->name, 7, "__STDC_")) n->flags |= N_WARN;
    }
    n->flags &= ~N_USED;
  }
}
static void do_undef (void)
{
  struct hnode *n = lex_macro_node (1);
  if (n) {
    if (n->type == NT_USER || n->type == NT_BUILTIN) { n->type = NT_VOID; n->macro = 0; }
    n->flags &= ~N_USED;
  }
  check_eol (0);
}
/* #include */
static unsigned char *parse_include (int *angle, long *fnp)
{
  struct tok *h = get_token_no_padding ();
  unsigned char *fname = 0;
  if ((h->type == T_STRING && h->text[0] != 'R') || h->type == T_HEADER_NAME) {
    fname = dup (h->text + 1, h->len - 2); *fnp = h->len - 2;
    *angle = h->type == T_HEADER_NAME;
  } else if (h->type == T_LESS) {
    long room = 256, fn = 0; unsigned char *d = alloc (room);
    for (;;) {
      struct tok *t = get_token_no_padding ();
      if (t->type == T_GREATER) break;
      if (t->type == T_EOF) { error ("missing terminating > character"); break; }
      stringify_buf (&d, &fn, &room, spell_len (t) + 4);
      if (t->flags & PREV_WHITE) d[fn++] = ' ';
      fn += spell (t, d + fn);
    }
    fname = d; *fnp = fn; *angle = 1;
  } else { error ("#include expects \"FILENAME\" or <FILENAME>"); return 0; }
  if (pps->directive != D_PRAGMA) check_eol (1);
  return fname;
}
static void do_include_common (int type)
{
  int angle = 0;
  long fn = 0;
  unsigned char *fname;
  pps->in_directive = 2;
  fname = parse_include (&angle, &fn);
  if (!fname) return;
  if (fn == 0) { error ("empty filename in #include"); return; }
  if (pps->curmap->depth >= 200) { error ("#include nested too deeply"); return; }
  skip_rest_of_line ();
  stack_include (fname, fn, angle, type);
}
static void do_include (void) { do_include_common (IT_INCLUDE); }
static void do_import (void) { do_include_common (IT_IMPORT); }
static void do_include_next (void)
{
  int type = IT_INCLUDE_NEXT;
  if (pps->curmap->depth == 1) type = IT_INCLUDE;
  do_include_common (type);
}
/* #line and # 33 "file" */
static int str_to_line (struct tok *t, long *v)
{
  long i = 0, n = 0;
  if (t->type != T_NUMBER) return 0;
  while (i < t->len) { if (!isdig (t->text[i])) return 0; n = n * 10 + (t->text[i] - '0'); i++; }
  *v = n;
  return 1;
}
static unsigned char *unquote (struct tok *t, long *n)   /* a narrow string's text, escapes done */
{
  unsigned char *d = alloc (t->len), *s = t->text + 1, *e = t->text + t->len - 1;
  long k = 0;
  while (s < e) {
    if (*s == '\\' && s + 1 < e) {
      s++;
      if (*s >= '0' && *s <= '7') { int v = 0, c = 0; while (c < 3 && s < e && *s >= '0' && *s <= '7') { v = v * 8 + *s - '0'; s++; c++; } d[k++] = v; continue; }
      if (*s == 'n') { d[k++] = '\n'; s++; continue; }
      d[k++] = *s++;
      continue;
    }
    d[k++] = *s++;
  }
  *n = k;
  return d;
}
static void do_line (void)
{
  struct tok *t = get_token ();
  long lineno;
  unsigned char *name = pps->curmap->name; long nl = pps->curmap->nlen;
  int sysp = pps->curmap->sysp;
  if (!str_to_line (t, &lineno)) { error ("#line expects a positive integer"); return; }
  t = get_token ();
  if (t->type == T_STRING) { name = unquote (t, &nl); check_eol (1); }
  else if (t->type != T_EOF) { error ("invalid filename in #line"); return; }
  skip_rest_of_line ();
  do_file_change (LC_RENAME, name, nl, lineno, sysp, 0);
}
static void do_linemarker (void)
{
  struct tok *t;
  long lineno;
  unsigned char *name = pps->curmap->name; long nl = pps->curmap->nlen;
  int sysp = pps->curmap->sysp, reason = LC_RENAME;
  backup_tokens (1);
  t = get_token ();
  if (!str_to_line (t, &lineno)) { error ("line marker: not a positive integer"); return; }
  t = get_token ();
  if (t->type == T_STRING) {
    long flag;
    name = unquote (t, &nl);
    sysp = 0;
    t = get_token ();
    flag = 0;
    if (str_to_line (t, &flag) && flag == 1) { reason = LC_ENTER; t = get_token (); flag = 0; str_to_line (t, &flag); }
    else if (flag == 2) { reason = LC_LEAVE; t = get_token (); flag = 0; str_to_line (t, &flag); }
    if (flag == 3) { sysp = 1; t = get_token (); flag = 0; if (str_to_line (t, &flag) && flag == 4) sysp = 2; }
    pps->buffer->sysp = sysp;
  } else if (t->type != T_EOF) { error ("invalid filename in a line marker"); return; }
  skip_rest_of_line ();
  if (reason == LC_ENTER) do_file_change (LC_ENTER, name, nl, lineno, sysp, pps->lno - 1);
  else if (reason == LC_LEAVE) { do_file_change (LC_LEAVE, 0, 0, 0, 0, 0); pps->lno = lineno; pps->curmap->sysp = sysp; }
  else do_file_change (LC_RENAME, name, nl, lineno, sysp, 0);
}
static void do_diagnostic (int err)
{
  /* the rest of the line as written */
  struct buf *b = pps->buffer;
  unsigned char *s = b->cur, *e = s;
  while (*e != '\n') e++;
  where ();
  perr_str (err ? "error: #error " : "warning: #warning ");
  perr_bytes (s, e - s); perr_str ("\n");
  if (err) pps->errors++;
}
static void do_ident (void)
{
  struct tok *s = get_token ();
  if (s->type != T_STRING) error ("invalid #ident directive");
  else if (!pps->lang_asm) {   /* (cb_ident: not in assembler) */
    struct vloc l; map_loc (pps->curmap, pps->directive_line, &l);
    maybe_print_line (&l);
    o_str ("#ident "); o_bytes (s->text, s->len); o_ch ('\n');
    pps->src_line++;
  }
  check_eol (0);
}
/* #pragma */
static struct pragma *new_pragma (char *space, char *name, int deferred, int expand, int kind)
{
  struct pragma *ns = 0, *p, **chain = &pps->pragmas;
  if (space) {
    struct hnode *sn = lookup_s (space);
    ns = pps->pragmas;
    while (ns && ns->name != sn) ns = ns->next;
    if (!ns) { ns = alloc (sizeof (struct pragma)); ns->name = sn; ns->nspace = 1; ns->space = space; ns->next = pps->pragmas; pps->pragmas = ns; }
    chain = &ns->sub;
  }
  p = alloc (sizeof (struct pragma));
  p->name = lookup_s (name); p->space = space; p->pname = name; p->deferred = deferred; p->expand = expand; p->kind = kind;
  p->next = *chain; *chain = p;
  return p;
}
static struct pragma **pragma_ids;
static long npragma_ids;
static void init_pragmas (void)
{
  struct pragma *p;
  long i = 0;
  char *dspace[] = { "GCC", "GCC", "GCC", "GCC", "GCC", "GCC", 0, 0 };
  char *dname[] = { "diagnostic", "target", "optimize", "push_options", "pop_options", "reset_options", "redefine_extname", "message" };
  int dexp[] = { 0, 0, 0, 0, 0, 0, 1, 1 };
  int dkind[] = { PK_NONE, PK_TARGET, PK_OPTIMIZE, PK_PUSHOPT, PK_POPOPT, PK_RESETOPT, PK_NONE, PK_NONE };
  new_pragma (0, "once", 0, 0, PK_ONCE);
  new_pragma (0, "push_macro", 0, 0, PK_PUSH);
  new_pragma (0, "pop_macro", 0, 0, PK_POP);
  new_pragma ("GCC", "poison", 0, 0, PK_POISON);
  new_pragma ("GCC", "system_header", 0, 0, PK_SYSHDR);
  new_pragma ("GCC", "dependency", 0, 0, PK_DEPENDENCY);
  new_pragma ("GCC", "warning", 0, 0, PK_WARNING);
  new_pragma ("GCC", "error", 0, 0, PK_ERROR);
  pragma_ids = alloc (8 * sizeof (struct pragma *));
  for (i = 0; i < 8; i++) {
    p = new_pragma (dspace[i], dname[i], 1, dexp[i], dkind[i]);
    p->id = (int) i;
    pragma_ids[i] = p;
  }
  npragma_ids = 8;
}
static void pragma_name (long id, char **space, char **name)
{
  struct pragma *p = pragma_ids[id];
  *space = p->space; *name = p->pname;
}
static struct pragma *lookup_pragma (struct pragma *chain, struct hnode *n)
{
  while (chain && chain->name != n) chain = chain->next;
  return chain;
}
static void def_pragma (long lno)   /* cb_def_pragma: #pragma and the rest of the line as it is */
{
  struct vloc l;
  struct tok *t;
  map_loc (pps->curmap, lno, &l);
  maybe_print_line (&l);
  o_str ("#pragma ");
  t = get_token ();
  while (t->type != T_EOF) {
    out_token (t);
    t = get_token ();
    if (t->flags & PREV_WHITE) o_ch (' ');
  }
  o_ch ('\n');
  pps->printed = 0;
  pps->src_line++;
}
static void pragma_run (int kind);
static void do_pragma (void)
{
  struct pragma *p = 0;
  struct tok *t, *pt, ns;
  struct vloc ptl;
  long count = 1;
  pps->prevent_expansion++;
  pt = t = get_tok (&ptl);
  ns = *t;
  if (t->type == T_NAME) {
    p = lookup_pragma (pps->pragmas, t->node);
    if (p && p->nspace) {
      t = get_token ();
      if (t->type == T_NAME) p = lookup_pragma (p->sub, t->node); else p = 0;
      count = 2;
    }
  }
  if (p) {
    if (p->deferred) {
      pps->dres.loc = ptl;
      pps->dres.type = T_PRAGMA;
      pps->dres.flags = pt->flags;
      pps->dres.pragma = p->id;
      pps->dres.node = 0;
      pps->in_deferred_pragma = 1;
      pps->pragma_allow_expansion = p->expand;
      if (!p->expand) pps->prevent_expansion++;
    } else {
      line_change (pt, 0);
      if (p->expand) pps->prevent_expansion--;
      pragma_run (p->kind);
      if (p->expand) pps->prevent_expansion++;
    }
  } else if (!pps->lang_asm) {   /* (cb_def_pragma: not in assembler) */
    if (count == 1 || pps->ctx->prev == 0) backup_tokens (count);
    else {
      struct tok **a = alloc (2 * sizeof (struct tok *));
      a[0] = newtok (); *a[0] = ns; a[0]->flags |= NO_EXPAND;
      a[1] = newtok (); *a[1] = *t; a[1]->flags |= NO_EXPAND | PREV_WHITE;
      push_ctx (0, a, 0, 2, 0);
    }
    def_pragma (pps->directive_line);
  }
  pps->prevent_expansion--;
}
static void do_pragma_text (unsigned char *text, long n, struct vloc *loc)   /* destringize_and_run */
{
  unsigned char *d = alloc (n + 2), *s = text + 1 + (text[0] == 'L'), *lim = text + n - 1;
  long k = 0, count;
  struct ctx *saved_ctx = pps->ctx;
  long saved_rc = pps->rc, saved_la = pps->la, saved_room = pps->rroom;
  struct tok **saved_run = pps->run;
  struct buf *pb, *prevb;
  struct tok **toks;
  int saved_dir = pps->directive;
  while (s < lim) {
    if (*s == '\\' && (s[1] == '\\' || s[1] == '"')) s++;
    d[k++] = *s++;
  }
  pps->ctx = alloc (sizeof (struct ctx));
  pps->run = 0; pps->rroom = 0; pps->rc = 0; pps->la = 0;
  prevb = pps->buffer;
  push_text (d, k);
  pb = pps->buffer;
  pb->file = prevb->file; pb->sysp = prevb->sysp;
  start_directive ();
  pps->directive = D_PRAGMA;
  do_pragma ();
  if (pps->dres.type == T_PRAGMA) pps->dres.flags |= PRAGMA_OP;
  end_directive (1);
  pps->directive = saved_dir;
  if (pps->dres.type == T_PRAGMA) {
    long room = 50;
    toks = alloc (room * sizeof (struct tok *));
    toks[0] = newtok (); *toks[0] = pps->dres; toks[0]->loc = *loc;
    count = 1;
    do {
      struct tok *x;
      if (count == room) { struct tok **y = alloc (room * 2 * sizeof (struct tok *)); long i = 0; while (i < count) { y[i] = toks[i]; i++; } toks = y; room *= 2; }
      x = newtok (); *x = *get_token ();
      x->loc = *loc;
      x->flags |= NO_EXPAND;
      toks[count++] = x;
    } while (toks[count - 1]->type != T_PRAGMA_EOL);
  } else {
    count = 1;
    toks = alloc (sizeof (struct tok *));
    toks[0] = &pps->avoid_paste;
    {
      /* line_change (pfile->cur_token): end_directive put cur_token at the base of the run, the first
         token of this line's run */
      struct tok x;
      x.type = T_NAME; x.flags = 0;
      if (saved_rc + saved_la > 0) x.loc = saved_run[0]->loc; else x.loc = *loc;
      do_line_change (&x, &x.loc, 0);
    }
  }
  pb->file = 0;
  prevb->sysp = pb->sysp;
  pps->buffer = pb->prev;
  pps->ctx = saved_ctx;
  pps->run = saved_run; pps->rroom = saved_room; pps->rc = saved_rc; pps->la = saved_la;
  push_ctx (0, toks, 0, count, 0);
}
static void pop_macro_into (struct hnode *n, struct pushed *c)
{
  n->type = c->type; n->macro = c->macro; n->builtin = c->builtin;
  if (c->macro) {
    /* as gcc, which lexes the saved definition again here: its tokens are of this place */
    struct macro *m = alloc (sizeof (struct macro));
    long i;
    *m = *c->macro;
    m->toks = alloc ((m->count + 1) * sizeof (struct tok));
    for (i = 0; i < m->count; i++) {
      m->toks[i] = c->macro->toks[i];
      m->toks[i].loc.m = pps->curmap; m->toks[i].loc.lno = pps->lno; m->toks[i].loc.sys = pps->curmap->sysp; m->toks[i].loc.bi = 0;
    }
    n->macro = m;
  }
}
static struct hnode *push_pop_name (void)
{
  struct tok *t = get_token_no_padding ();
  struct hnode *n = 0;
  if (t->type != T_OPEN_PAREN) { error ("invalid #pragma push_macro or pop_macro"); return 0; }
  t = get_token_no_padding ();
  if (t->type != T_STRING) { error ("invalid #pragma push_macro or pop_macro"); return 0; }
  n = lookup (t->text + 1, t->len - 2);
  t = get_token_no_padding ();
  if (t->type != T_CLOSE_PAREN) { error ("invalid #pragma push_macro or pop_macro"); return 0; }
  check_eol (0);
  return n;
}
static void target_options (unsigned char *s, long n);
static void pragma_run (int kind)
{
  if (kind == PK_ONCE) { check_eol (0); pps->seen_once_only = 1; if (pps->buffer->file) pps->buffer->file->once_only = 1; }
  else if (kind == PK_PUSH) {
    struct hnode *n = push_pop_name ();
    if (n) {
      struct pushed *c = alloc (sizeof (struct pushed));
      c->node = n; c->type = n->type; c->macro = n->macro; c->builtin = n->builtin;
      c->next = pps->pushed; pps->pushed = c;
    }
  } else if (kind == PK_POP) {
    struct hnode *n = push_pop_name ();
    struct pushed *c = pps->pushed, *l = 0;
    while (n && c) {
      if (c->node == n) { if (l) l->next = c->next; else pps->pushed = c->next; pop_macro_into (n, c); break; }
      l = c; c = c->next;
    }
  } else if (kind == PK_POISON) {
    for (;;) {
      struct tok *t = lex_token ();
      if (t->type == T_EOF) break;
      if (t->type != T_NAME) { error ("invalid #pragma GCC poison directive"); break; }
      t->node->flags |= N_POISONED;
    }
  } else if (kind == PK_SYSHDR) {
    if (pps->buffer->file == pps->main_file) ;   /* ignored outside an include file */
    else {
      check_eol (0);
      skip_rest_of_line ();
      pps->buffer->sysp = 1;
      do_file_change (LC_RENAME, pps->curmap->name, pps->curmap->nlen, pps->lno, 1, 0);
    }
  } else if (kind == PK_WARNING || kind == PK_ERROR) {
    struct tok *t = get_token_no_padding ();
    where ();
    perr_str (kind == PK_ERROR ? "error: #pragma GCC error " : "warning: #pragma GCC warning ");
    if (t->type == T_STRING) perr_bytes (t->text, t->len);
    perr_str ("\n");
    if (kind == PK_ERROR) pps->errors++;
  } else if (kind == PK_DEPENDENCY) {
    int angle; long fn;
    parse_include (&angle, &fn);
  }
}
/* the early handlers of the deferred pragmas (-E): #pragma GCC target and optimize, and the stack of
   push_options, change the target's macros (gcc's handlers do as they stream the pragma's tokens: here
   its arguments are kept as they stream, and the state changes at its end) */
static void pragma_early (long id)
{
  struct pragma *p = pragma_ids[id];
  if (p->kind == PK_TARGET || p->kind == PK_OPTIMIZE || p->kind == PK_PUSHOPT || p->kind == PK_POPOPT || p->kind == PK_RESETOPT) {
    pps->tpending = p->kind;
    pps->talen = 0;
  }
}
static void targs_add (struct tok *t)
{
  long n = spell_len (t) + 2;
  if (pps->talen + n > pps->taroom) {
    long r = (pps->taroom + n) * 2; unsigned char *x = alloc (r);
    mcopy (x, pps->targs, pps->talen); pps->targs = x; pps->taroom = r;
  }
  if (pps->talen && (t->flags & PREV_WHITE)) pps->targs[pps->talen++] = ' ';
  pps->talen += spell (t, pps->targs + pps->talen);
}
static void define_line (unsigned char *x)   /* a "#define ..." line, here (gcc's handler's cpp_define) */
{
  int f = pps->forced;
  pps->forced = 0;
  run_directive (D_DEFINE, x + 8, slen ((char *) x + 8));
  pps->forced = f;
}
static long macro_name_len (unsigned char *p) { long n = 0; while (isidnum (p[n]) || p[n] == '$') n++; return n; }
static void apply_tstate (void)
{
  struct tset *t = pps->tsets;
  long i, j;
  /* back to the options' macros */
  for (i = 0; i < pps->ntnames; i++) {
    unsigned char *nm = pps->tnames[i]; long nn = pps->tnlen[i];
    struct hnode *h = lookup (nm, nn);
    unsigned char *base = 0;
    for (j = 0; j < pps->nplines; j++) {
      unsigned char *x = pps->plines[j];
      if (x && msame (x + 8, macro_name_len (x + 8), nm, nn)) { base = x; break; }
    }
    if (base) define_line (base); else { h->type = NT_VOID; h->macro = 0; }
  }
  pps->ntnames = 0;
  if (pps->tslen == 0) return;
  while (t) {
    if (t->klen == pps->klen + 1 + pps->tslen && msame (t->key, pps->klen, pps->key, pps->klen) && t->key[pps->klen] == '\t'
        && msame (t->key + pps->klen + 1, pps->tslen, pps->tstate, pps->tslen)) break;
    t = t->next;
  }
  if (!t) {
    unsigned char *l = alloc (pps->klen + pps->tslen + 16);
    mcopy (l, (unsigned char *) "cpp: target ", 12); mcopy (l + 12, pps->key, pps->klen); l[12 + pps->klen] = '\t';
    mcopy (l + 13 + pps->klen, pps->tstate, pps->tslen); l[13 + pps->klen + pps->tslen] = '\n';
    if (pps->collect) { perr_bytes (l, 14 + pps->klen + pps->tslen); return; }
    fatal2 ("no macros in --predef for the pragmas of ", l + 12, 1 + pps->klen + pps->tslen);
  }
  pps->tnames = alloc ((t->n + 1) * sizeof (unsigned char *)); pps->tnlen = alloc ((t->n + 1) * sizeof (long));
  for (i = 0; i < t->n; i++) {
    unsigned char *x = t->lines[i];
    unsigned char *nm = x[0] == '+' ? x + 9 : x + 1;
    long nn = macro_name_len (nm);
    if (x[0] == '+') define_line (x + 1);
    else { struct hnode *h = lookup (nm, nn); h->type = NT_VOID; h->macro = 0; }
    pps->tnames[pps->ntnames] = nm; pps->tnlen[pps->ntnames++] = nn;
  }
}
static void pragma_late (void)   /* at the pragma's end */
{
  int k = pps->tpending;
  pps->tpending = 0;
  if (k == PK_TARGET || k == PK_OPTIMIZE) {
    long n = pps->tslen + pps->talen + 8;
    unsigned char *x = alloc (n);
    long m = 0;
    if (pps->tslen) { mcopy (x, pps->tstate, pps->tslen); m = pps->tslen; x[m++] = ' '; x[m++] = ';'; x[m++] = ' '; }
    x[m++] = k == PK_TARGET ? 't' : 'o'; x[m++] = ' ';
    mcopy (x + m, pps->targs, pps->talen); m += pps->talen;
    pps->tstate = x; pps->tslen = m;
  } else if (k == PK_PUSHOPT) {
    struct optset *o = alloc (sizeof (struct optset));
    o->state = pps->tstate; o->slen = pps->tslen; o->next = pps->optstack; pps->optstack = o;
    return;
  } else if (k == PK_POPOPT) {
    if (!pps->optstack) { error ("#pragma GCC pop_options without a corresponding #pragma GCC push_options"); return; }
    pps->tstate = pps->optstack->state; pps->tslen = pps->optstack->slen; pps->optstack = pps->optstack->next;
  } else if (k == PK_RESETOPT) { pps->tslen = 0; pps->optstack = 0; }
  apply_tstate ();
}

static void run_directive (int dir, unsigned char *text, long n);
static int handle_directive (int indented)
{
  int dir = 0, skip = 1, was_parsing_args = pps->parsing_args, was_discarding = 0;
  struct tok *dname;
  if (was_parsing_args) { pps->parsing_args = 0; pps->prevent_expansion = 0; }
  start_directive ();
  dname = lex_token ();
  if (dname->type == T_NAME) {
    if (dname->node->dir) dir = dname->node->dir;
  } else if (dname->type == T_NUMBER && !pps->lang_asm) dir = D_LINEMARKER;   /* (not in assembler) */
  if (dir) {
    if (!(dir == D_LINEMARKER ? 0 : (dflags[dir] & F_IF_COND))) pps->mi_valid = 0;
    pps->angled_headers = dir != D_LINEMARKER && (dflags[dir] & F_INCL);
    pps->directive_wants_padding = pps->angled_headers;
    if (pps->skipping && !(dir != D_LINEMARKER && (dflags[dir] & F_COND))) dir = 0;
  } else if (dname->type == T_EOF) ;
  else if (pps->lang_asm) skip = 0;   /* an assembler's # (a comment, a pseudo-op): the line as it is */
  else if (!pps->skipping) {
    unsigned char b[256]; long n = spell (dname, b);
    error2 ("invalid preprocessing directive #", b, n);
  }
  pps->directive = dir;
  if (dir) {
    if (dir == D_DEFINE) do_define ();
    else if (dir == D_INCLUDE) do_include ();
    else if (dir == D_ENDIF) do_endif ();
    else if (dir == D_IFDEF) do_ifdef ();
    else if (dir == D_IF) do_if ();
    else if (dir == D_ELSE) do_else ();
    else if (dir == D_IFNDEF) do_ifndef ();
    else if (dir == D_UNDEF) do_undef ();
    else if (dir == D_LINE) do_line ();
    else if (dir == D_ELIF || dir == D_ELIFDEF || dir == D_ELIFNDEF) do_elif ();
    else if (dir == D_ERROR) do_diagnostic (1);
    else if (dir == D_WARNING) do_diagnostic (0);
    else if (dir == D_PRAGMA) do_pragma ();
    else if (dir == D_INCLUDE_NEXT) do_include_next ();
    else if (dir == D_IMPORT) do_import ();
    else if (dir == D_IDENT || dir == D_SCCS) do_ident ();
    else if (dir == D_LINEMARKER) do_linemarker ();
    else if (dir == D_EMBED) fatal ("#embed is not supported");
    else if (dir == D_ASSERT || dir == D_UNASSERT) fatal ("#assert is not supported");
  } else if (skip == 0) backup_tokens (1);
  end_directive (skip);
  if (was_parsing_args && !pps->in_deferred_pragma) { pps->parsing_args = 2; pps->prevent_expansion = 1; }
  if (was_discarding) pps->prevent_expansion = 1;
  return skip;
}
static void run_directive (int dir, unsigned char *text, long n)   /* run_directive: -D, -U and the predefined macros */
{
  struct buf *pb;
  push_text (text, n);
  pb = pps->buffer;
  start_directive ();
  pps->directive = dir;
  if (dir == D_DEFINE) do_define (); else if (dir == D_UNDEF) do_undef ();
  end_directive (1);
  if (pps->buffer == pb) pps->buffer = pb->prev;
}

/* ---- the command line, the predefined macros, the start (c-opts.cc, init.cc) */
struct opts {
  char *in, *out, *predef;
  char **incs; long nincs;           /* -include, in order */
  char **defs; int *defk; long ndefs; /* -D (1), -U (0), in order */
  char **iq, **ib, **is, **ia; long niq, nib, nis, nia;
  int nostdinc, g, notf;
  char **sd; int *sdk; long nsd;   /* gcc's own include directories, their kinds (--predef's sysdir) */
  char *preinc;
  unsigned char *key; long klen;
};
static void key_add (struct opts *o, char *s)
{
  long n = slen (s);
  unsigned char *k = alloc (o->klen + n + 2);
  mcopy (k, o->key, o->klen);
  if (o->klen) k[o->klen++] = ' ';
  mcopy (k + o->klen, (unsigned char *) s, n);
  o->key = k; o->klen += n;
}
static int starts (char *s, char *p) { long i = 0; while (p[i]) { if (s[i] != p[i]) return 0; i++; } return 1; }
static int lang_of (char *x)   /* -x: c or assembler-with-cpp, none (-1) */
{
  long n = slen (x);
  if (is ((unsigned char *) x, n, "c")) return 0;
  if (is ((unsigned char *) x, n, "assembler-with-cpp")) return 1;
  if (is ((unsigned char *) x, n, "none")) return -1;
  fatal2 ("only -x c and -x assembler-with-cpp are supported: -x ", (unsigned char *) x, n);
  return 0;
}
static void parse_opts (struct opts *o, int argc, char **argv)
{
  int i = 1, x = -1;   /* the -x in force: -1 none (the file's suffix decides), 0 c, 1 assembler-with-cpp */
  o->incs = alloc (argc * sizeof (char *)); o->defs = alloc (argc * sizeof (char *)); o->defk = alloc (argc * sizeof (int));
  o->iq = alloc (argc * sizeof (char *)); o->ib = alloc (argc * sizeof (char *)); o->is = alloc (argc * sizeof (char *)); o->ia = alloc (argc * sizeof (char *));
  while (i < argc) {
    char *a = argv[i];
    char *arg = 0;
    if (a[0] != '-' || a[1] == 0) {
      long n = slen (a);
      if (o->in) fatal ("two input files");
      o->in = a; i++;
      /* gcc's driver: .S and .sx are assembler-with-cpp; - (stdin) and the rest C, unless -x said */
      pps->lang_asm = x >= 0 ? x : (n > 2 && is ((unsigned char *) a + n - 2, 2, ".S")) || (n > 3 && is ((unsigned char *) a + n - 3, 3, ".sx"));
      continue;
    }
    if (starts (a, "--predef=")) { o->predef = a + 9; i++; continue; }
    if (starts (a, "--collect")) { pps->collect = 1; i++; continue; }
    if (is ((unsigned char *) a, slen (a), "-o") || is ((unsigned char *) a, slen (a), "-I") || is ((unsigned char *) a, slen (a), "-D")
        || is ((unsigned char *) a, slen (a), "-U") || is ((unsigned char *) a, slen (a), "-isystem") || is ((unsigned char *) a, slen (a), "-iquote")
        || is ((unsigned char *) a, slen (a), "-idirafter") || is ((unsigned char *) a, slen (a), "-include") || is ((unsigned char *) a, slen (a), "-imacros")
        || is ((unsigned char *) a, slen (a), "-MF") || is ((unsigned char *) a, slen (a), "-MT") || is ((unsigned char *) a, slen (a), "-MQ")
        || is ((unsigned char *) a, slen (a), "-x")) {
      if (i + 1 >= argc) fatal ("an option without its argument");
      arg = argv[i + 1];
      i += 2;
    } else i++;
    if (arg) {
      if (a[1] == 'o') o->out = arg;
      else if (a[1] == 'I') o->ib[o->nib++] = arg;
      else if (a[1] == 'D') { o->defs[o->ndefs] = arg; o->defk[o->ndefs++] = 1; }
      else if (a[1] == 'U') { o->defs[o->ndefs] = arg; o->defk[o->ndefs++] = 0; }
      else if (starts (a, "-isystem")) o->is[o->nis++] = arg;
      else if (starts (a, "-iquote")) o->iq[o->niq++] = arg;
      else if (starts (a, "-idirafter")) o->ia[o->nia++] = arg;
      else if (starts (a, "-include")) o->incs[o->nincs++] = arg;
      else if (starts (a, "-imacros")) fatal ("-imacros is not supported");
      else if (a[1] == 'x') x = lang_of (arg);
      continue;
    }
    if (a[1] == 'I') { o->ib[o->nib++] = a + 2; continue; }
    if (a[1] == 'D') { o->defs[o->ndefs] = a + 2; o->defk[o->ndefs++] = 1; continue; }
    if (a[1] == 'U') { o->defs[o->ndefs] = a + 2; o->defk[o->ndefs++] = 0; continue; }
    if (a[1] == 'W' || a[1] == 'w' || a[1] == 'M' || starts (a, "-pipe") || is ((unsigned char *) a, slen (a), "-c") || is ((unsigned char *) a, slen (a), "-E")
        || is ((unsigned char *) a, slen (a), "-S") || is ((unsigned char *) a, slen (a), "-v")) continue;
    if (starts (a, "-x")) { x = lang_of (a + 2); continue; }
    if (is ((unsigned char *) a, slen (a), "-nostdinc")) { o->nostdinc = 1; continue; }
    if (a[1] == 'g') { o->g = !is ((unsigned char *) a, slen (a), "-g0"); continue; }
    if (starts (a, "-fno-builtin-")) continue;
    if (starts (a, "-std=") || starts (a, "-ansi")) {
      /* (the last -std: true and false in #if from C23 on, as libcpp's lang_defaults) */
      char *v = a + 5;
      o->notf = !(starts (a, "-std=") && (is ((unsigned char *) v, slen (v), "c23") || is ((unsigned char *) v, slen (v), "gnu23") || is ((unsigned char *) v, slen (v), "c2x")
                  || is ((unsigned char *) v, slen (v), "gnu2x") || is ((unsigned char *) v, slen (v), "c2y") || is ((unsigned char *) v, slen (v), "gnu2y")
                  || is ((unsigned char *) v, slen (v), "iso9899:2024")));
    }
    if (a[1] == 'f' || a[1] == 'm' || a[1] == 'O' || starts (a, "-std=") || starts (a, "-ansi")) { key_add (o, a); continue; }
    fatal2 ("unknown option ", (unsigned char *) a, slen (a));
  }
  if (!o->in) fatal ("no input file");
  if (pps->lang_asm) {   /* the key of assembler's predefined macros: -x assembler-with-cpp first */
    char *k = "-x assembler-with-cpp";
    long n = slen (k);
    unsigned char *y = alloc (n + o->klen + 2);
    mcopy (y, (unsigned char *) k, n);
    if (o->klen) { y[n] = ' '; mcopy (y + n + 1, o->key, o->klen); n += 1 + o->klen; }
    o->key = y; o->klen = n;
  }
}
/* the predefined macros of these options and the answers of __has_*: the --predef file
   (predef KEY, then #define lines: the first set whole, the others +#define and -NAME against it;
   has KIND NAME VALUE) */
static unsigned char *line_end (unsigned char *p, unsigned char *e) { while (p < e && *p != '\n') p++; return p; }
static void predefine (struct opts *o)
{
  long size = 0, n;
  unsigned char *s, *e, *p;
  unsigned char **lines; long nlines = 0, i, room;
  int inset = 0, isbase = 0, found = 0, first = 1;
  if (!o->predef) fatal ("no --predef=FILE: the target's predefined macros");
  s = cp_file (o->predef, &size);
  e = s + size;
  room = 1024;
  lines = alloc (room * sizeof (unsigned char *));
  p = s;
  while (p < e) {
    unsigned char *le = line_end (p, e);
    n = le - p;
    *le = 0;
    if (n >= 7 && is (p, 7, "predef ")) {
      if (first) { first = 0; isbase = 1; inset = msame (p + 7, n - 7, o->key, o->klen); if (inset) found = 1; }
      else { isbase = 0; if (msame (p + 7, n - 7, o->key, o->klen)) { inset = 1; found = 1; } else inset = 0; }
    } else if (n > 7 && is (p, 7, "target ")) {
      /* target KEY\tSTATE: the deltas that follow, against KEY's macros */
      struct tset *t = alloc (sizeof (struct tset));
      t->key = p + 7; t->klen = n - 7; t->next = pps->tsets; pps->tsets = t;
      t->lines = alloc (64 * sizeof (unsigned char *));
      inset = 0; isbase = 0;
      {
        unsigned char *q = le + 1; long room2 = 64;
        while (q < e && (*q == '+' || *q == '-')) {
          unsigned char *qe = line_end (q, e);
          *qe = 0;
          if (t->n == room2) { unsigned char **y = alloc (room2 * 2 * sizeof (unsigned char *)); long j; for (j = 0; j < t->n; j++) y[j] = t->lines[j]; t->lines = y; room2 *= 2; }
          t->lines[t->n++] = q;
          q = qe + 1;
        }
        le = q - 1;
      }
    } else if (n > 4 && is (p, 4, "has ")) {
      /* has KIND NAME VALUE: KIND NAME is the key */
      unsigned char *v = le;
      struct has *h = alloc (sizeof (struct has));
      while (v > p && v[-1] != ' ') v--;
      h->key = p + 4; h->klen = v - 1 - (p + 4);
      h->value = 0;
      { unsigned char *q = v; while (q < le && isdig (*q)) { h->value = h->value * 10 + (*q - '0'); q++; } }
      h->next = pps->has; pps->has = h;
    } else if (n > 0 && p[0] != '#' && !(n > 8 && is (p, 8, "#define "))) {
      if (inset && !isbase && (p[0] == '+' || p[0] == '-')) {
        /* a delta: replace or remove a macro of the base set by its name */
        unsigned char *nm = p[0] == '+' ? p + 9 : p + 1;
        long nn = 0, j;
        while (isidnum (nm[nn]) || nm[nn] == '$') nn++;
        for (j = 0; j < nlines; j++) {
          unsigned char *x = lines[j];
          if (x && msame (x + 8, nn, nm, nn) && !(isidnum (x[8 + nn]) || x[8 + nn] == '$')) { lines[j] = 0; break; }
        }
        if (p[0] == '+') { if (nlines == room) { unsigned char **y = alloc (room * 2 * sizeof (unsigned char *)); for (j = 0; j < nlines; j++) y[j] = lines[j]; lines = y; room *= 2; } lines[nlines++] = p + 1; }
      }
    } else if (n > 8 && is (p, 8, "#define ") && isbase) {
      if (nlines == room) { unsigned char **y = alloc (room * 2 * sizeof (unsigned char *)); long j; for (j = 0; j < nlines; j++) y[j] = lines[j]; lines = y; room *= 2; }
      lines[nlines++] = p;
    }
    p = le + 1;
  }
  if (!found) fatal2 ("no predefined macros in --predef for the options: ", o->key, o->klen);
  pps->plines = lines; pps->nplines = nlines;
  pps->key = o->key; pps->klen = o->klen;
  pps->forced = 1;
  for (i = 0; i < nlines; i++) {
    unsigned char *x = lines[i];
    if (!x) continue;
    run_directive (D_DEFINE, x + 8, slen ((char *) x + 8));
    if (is (x + 8, 17, "__CHAR_UNSIGNED__")) pps->uchar = 1;
  }
  pps->forced = 0;
  {
    struct hnode *w = lookup_s ("__WCHAR_MIN__"), *z = lookup_s ("__SIZEOF_WCHAR_T__");
    pps->wchar_bits = 32;
    if (w->type == NT_USER && w->macro->count == 1 && w->macro->toks[0].type == T_NUMBER) pps->wchar_unsigned = 1;
    if (z->type == NT_USER && z->macro->count == 1 && z->macro->toks[0].len == 1 && z->macro->toks[0].text[0] == '2') pps->wchar_bits = 16;
  }
}
static void read_sysdirs (struct opts *o)   /* --predef's sysdir and preinclude lines */
{
  long size = 0;
  unsigned char *s, *e, *p;
  if (!o->predef) return;
  s = cp_file (o->predef, &size);
  e = s + size;
  o->sd = alloc (64 * sizeof (char *)); o->sdk = alloc (64 * sizeof (int));
  p = s;
  while (p < e) {
    unsigned char *le = line_end (p, e);
    long n = le - p;
    *le = 0;
    if (n > 9 && is (p, 7, "sysdir ") && o->nsd < 64) { o->sdk[o->nsd] = p[7] - '0'; o->sd[o->nsd++] = (char *) p + 9; }
    else if (n > 11 && is (p, 11, "preinclude ")) o->preinc = (char *) p + 11;
    p = le + 1;
  }
}
static void builtins (void)
{
  char *names[] = { "__TIMESTAMP__", "__TIME__", "__DATE__", "__FILE__", "__FILE_NAME__", "__BASE_FILE__", "__LINE__",
    "__INCLUDE_LEVEL__", "__COUNTER__", "__has_attribute", "__has_c_attribute", "__has_cpp_attribute", "__has_builtin",
    "__has_include", "__has_include_next", "__has_embed", "__has_feature", "__has_extension", "_Pragma", 0 };
  int kinds[] = { BT_TIMESTAMP, BT_TIME, BT_DATE, BT_FILE, BT_FILE_NAME, BT_BASE_FILE, BT_LINE, BT_INCLUDE_LEVEL,
    BT_COUNTER, BT_HAS_ATTRIBUTE, BT_HAS_STD_ATTRIBUTE, BT_HAS_ATTRIBUTE, BT_HAS_BUILTIN, BT_HAS_INCLUDE,
    BT_HAS_INCLUDE_NEXT, BT_HAS_EMBED, BT_HAS_FEATURE, BT_HAS_EXTENSION, BT_PRAGMA };
  long i = 0;
  while (names[i]) {
    /* (not __has_attribute, __has_c_attribute, __has_cpp_attribute, __has_builtin in assembler) */
    if (!(pps->lang_asm && (kinds[i] == BT_HAS_ATTRIBUTE || kinds[i] == BT_HAS_STD_ATTRIBUTE || kinds[i] == BT_HAS_BUILTIN))) {
      struct hnode *n = lookup_s (names[i]); n->type = NT_BUILTIN; n->builtin = kinds[i];
    }
    i++;
  }
  i = 1;
  while (dnames[i]) { lookup_s (dnames[i])->dir = (int) i; i++; }
}
/* the include chains (incpath.cc): directories that are not there dropped, then the duplicates */
static int dir_exists (char *name)
{
  long fd = pp_open (name), r;
  unsigned char b[8];
  if (fd < 0) return 0;
  r = pp_read (fd, b, 1);
  pp_close (fd);
  return r == -21;
}
struct cand { unsigned char *name; long len; unsigned char *canon; long clen; int sysp; };
static long chain_add (struct cand *c, long n, char **names, long k, int sysp)
{
  long i;
  for (i = 0; i < k; i++) {
    long l = slen (names[i]);
    if (!dir_exists (names[i])) continue;
    c[n].name = (unsigned char *) names[i]; c[n].len = l; c[n].sysp = sysp;
    c[n].canon = realpath_of ((unsigned char *) names[i], l, &c[n].clen);
    if (!c[n].canon) { c[n].canon = c[n].name; c[n].clen = l; }
    n++;
  }
  return n;
}
static int cand_eq (struct cand *a, struct cand *b) { return msame (a->canon, a->clen, b->canon, b->clen); }
static void include_chains (struct opts *o)
{
  long total = o->niq + o->nib + o->nis + o->nia + o->nsd + 1;
  struct cand *sys = alloc (total * sizeof (struct cand)), *br = alloc (total * sizeof (struct cand)), *qu = alloc (total * sizeof (struct cand));
  long ns = 0, nb = 0, nq = 0, i, j, k;
  struct dir *head = 0, *tail = 0, *d;
  ns = chain_add (sys, 0, o->is, o->nis, 1);
  if (!o->nostdinc) {
    long s0 = ns;
    for (i = 0; i < o->nsd; i++) { ns = chain_add (sys, ns, o->sd + i, 1, 1); if (ns > s0) sys[ns - 1].sysp = o->sdk[i]; s0 = ns; }
  }
  ns = chain_add (sys, ns, o->ia, o->nia, 1);
  /* the system chain without its own duplicates */
  k = 0;
  for (i = 0; i < ns; i++) { for (j = 0; j < k; j++) if (cand_eq (&sys[j], &sys[i])) break; if (j == k) sys[k++] = sys[i]; }
  ns = k;
  nb = chain_add (br, 0, o->ib, o->nib, 0);
  k = 0;
  for (i = 0; i < nb; i++) {
    for (j = 0; j < ns; j++) if (cand_eq (&sys[j], &br[i])) break;
    if (j < ns) continue;
    for (j = 0; j < k; j++) if (cand_eq (&br[j], &br[i])) break;
    if (j < k) continue;
    if (i == nb - 1 && ns > 0 && cand_eq (&br[i], &sys[0])) continue;
    br[k++] = br[i];
  }
  nb = k;
  nq = chain_add (qu, 0, o->iq, o->niq, 0);
  k = 0;
  for (i = 0; i < nq; i++) {
    for (j = 0; j < ns; j++) if (cand_eq (&sys[j], &qu[i])) break;
    if (j < ns) continue;
    for (j = 0; j < k; j++) if (cand_eq (&qu[j], &qu[i])) break;
    if (j < k) continue;
    if (i == nq - 1 && nb > 0 && cand_eq (&qu[i], &br[0])) continue;
    qu[k++] = qu[i];
  }
  nq = k;
  pps->quote = 0; pps->bracket = 0;
  for (i = 0; i < nq + nb + ns; i++) {
    struct cand *c = i < nq ? &qu[i] : i < nq + nb ? &br[i - nq] : &sys[i - nq - nb];
    d = alloc (sizeof (struct dir));
    d->name = c->name; d->len = c->len; d->sysp = c->sysp;
    if (tail) tail->next = d; else head = d;
    tail = d;
    if (i == nq) pps->bracket = d;
  }
  pps->quote = head;
  if (nq == nb + nq + ns) pps->bracket = 0;
  if (nq == 0) pps->bracket = head;
}
static struct opts *popts;
static long next_include;
static int done_preinclude;
static void push_next_include (void)
{
  if (!done_preinclude) {
    done_preinclude = 1;
    if (!popts->nostdinc && popts->preinc && stack_include ((unsigned char *) popts->preinc, slen (popts->preinc), 1, IT_DEFAULT)) return;
  }
  while (next_include < popts->nincs) {
    char *f = popts->incs[next_include++];
    if (stack_include ((unsigned char *) f, slen (f), 0, IT_CMDLINE)) return;
  }
  if (next_include == popts->nincs) {
    next_include++;
    do_file_change (LC_RENAME, pps->main_file->path, pps->main_file->plen, 1, 0, 0);
  }
}
static void scan (void)   /* scan_translation_unit */
{
  pps->source = 0;
  for (;;) {
    struct vloc l;
    struct tok *t = get_tok (&l);
    stream (t, &l);
    if (t->type == T_EOF) break;
  }
  if (pps->printed) o_ch ('\n');
}
static void get_cwd (char **envp)
{
  unsigned char b[4096];
  long n = cp_readlink ("/proc/self/cwd", b, 4095), i = 0;
  if (n <= 0) fatal ("cannot read /proc/self/cwd");
  pps->cwd = dup (b, n); pps->cwdlen = n;
  /* getpwd: $PWD when it names the same directory */
  while (envp && envp[i]) {
    if (starts (envp[i], "PWD=") && envp[i][4] == '/') {
      long pl = slen (envp[i] + 4), rn;
      unsigned char *r = realpath_of ((unsigned char *) envp[i] + 4, pl, &rn);
      if (r && msame (r, rn, pps->cwd, pps->cwdlen)) { pps->cwd = (unsigned char *) envp[i] + 4; pps->cwdlen = pl; }
      break;
    }
    i++;
  }
}
int cpp_main (int argc, char **argv)
{
  struct opts *o;
  long i;
  struct map *m;
  pps = alloc (sizeof (struct pst));
  pps->tab = alloc (HSIZE * sizeof (struct hnode *));
  pps->ftab = alloc (4096 * sizeof (struct fent *));
  pps->obuf = alloc (65536 + 16);
  pps->ofd = 1;
  pps->ctx = &pps->base;
  pps->avoid_paste.type = T_PADDING;
  pps->endarg.type = T_EOF;
  pps->src_line = 1; pps->first_time = 1; pps->src_file = (unsigned char *) ""; pps->src_flen = 0;
  pps->no_search = alloc (sizeof (struct dir));
  pps->no_search->name = (unsigned char *) ""; pps->no_search->len = 0;
  popts = o = alloc (sizeof (struct opts));
  o->key = (unsigned char *) "";
  parse_opts (o, argc, argv);
  get_cwd (argv + argc + 1);
  builtins ();
  pps->n_defined = lookup_s ("defined");
  pps->n_true = lookup_s ("true");
  pps->n_false = lookup_s ("false");
  pps->true_false = !o->notf && !pps->lang_asm;   /* (not in assembler: CLK_ASM's lang_defaults) */
  pps->n_va_args = lookup_s ("__VA_ARGS__");
  pps->n_va_opt = lookup_s ("__VA_OPT__");
  init_pragmas ();
  read_sysdirs (o);
  include_chains (o);
  if (o->out) { pps->ofd = cp_create (o->out); if (pps->ofd < 0) fatal2 ("cannot create ", (unsigned char *) o->out, slen (o->out)); }
  /* the main file, then <built-in>, <command-line> and the -include files */
  if (is ((unsigned char *) o->in, slen (o->in), "-")) {
    /* stdin: libcpp's file "" (linemap_add names it <stdin>; its directory the current one) */
    struct file *f = alloc (sizeof (struct file));
    long n;
    f->name = (unsigned char *) ""; f->path = (unsigned char *) "<stdin>"; f->plen = 7; f->dir = pps->no_search; f->found = 1;
    n = read_fd (0, &f->raw);
    if (n < 0) fatal ("cannot read stdin");
    f->size = n;
    f->next_all = pps->all_files; pps->all_files = f;
    pps->main_file = f;
  } else pps->main_file = find_file ((unsigned char *) o->in, slen (o->in), pps->no_search, 0);
  if (!pps->main_file->found) fatal2 ("no such file: ", (unsigned char *) o->in, slen (o->in));
  pps->lno = 0;
  clean_file (pps->main_file);
  {
    struct buf *b = push_buffer (pps->main_file->clean, pps->main_file->clen);
    b->notes = pps->main_file->notes; b->nnotes = pps->main_file->nnotes;
    b->file = pps->main_file;
    b->return_at_eof = 0;
    pps->main_file->stack_count = 1;
  }
  m = alloc (sizeof (struct map));
  m->name = pps->main_file->path; m->nlen = pps->main_file->plen; m->depth = 1;
  pps->curmap = m;
  file_change (m, LC_ENTER);
  if (o->g) { o_str ("# 1 \""); quote_out (pps->cwd, pps->cwdlen); o_str ("//\"\n"); }
  do_file_change (LC_RENAME, (unsigned char *) "<built-in>", 10, 0, 0, 0);
  pps->builtin_map = pps->curmap;
  predefine (o);
  do_file_change (LC_RENAME, (unsigned char *) "<command-line>", 14, 0, 0, 0);
  pps->cmdline_map = pps->curmap;
  pps->forced = 2;
  for (i = 0; i < o->ndefs; i++) {
    char *d = o->defs[i];
    long n = slen (d), k = 0;
    unsigned char *t = alloc (n + 4);
    if (o->defk[i]) {
      while (k < n && d[k] != '=') { t[k] = d[k]; k++; }
      if (k < n) { t[k] = ' '; mcopy (t + k + 1, (unsigned char *) d + k + 1, n - k - 1); }
      else { t[k++] = ' '; t[k++] = '1'; n = k; }
      run_directive (D_DEFINE, t, n);
    } else run_directive (D_UNDEF, (unsigned char *) d, n);
  }
  pps->forced = 0;
  next_include = 0;
  push_next_include ();
  scan ();
  o_flush ();
  return pps->errors ? 1 : 0;
}
