/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cs.h: the types and semantics of C (dev source of tools/csem.ff) */
struct cs_buf { unsigned char *p; long n; long room; };
struct cs_ty {
  int k;                /* TY_ */
  int q;                /* Q_ */
  struct cs_ty *to;        /* pointee, element, return, a typedef's type, complex/vector/isatomic element */
  long long n;          /* array count (-1 none, -2 variable), vector bytes, _BitInt nbits */
  struct cs_rec *rec;      /* struct, union, enum */
  struct cs_ty **ps;       /* a function's parameters (as declared, adjusted) */
  long np;
  int var, proto, noret;
  unsigned char *name;  /* a typedef's name */
  long nlen;
  long long algn;      /* a typedef's aligned (bytes), 0 none */
  int pq;               /* an array parameter's qualifiers (in its []), its pointer's */
  struct node *count;   /* a variable-length array's count as cparse has it */
  struct cs_ex *countx; /* and as an expression, where its names are looked up */
  int pcs;              /* a function type's pcs ("aapcs") */
};
struct cs_field {
  unsigned char *name; long nlen;
  struct cs_ty *t;
  long long width;      /* a bitfield's, -1 none */
  long long off;        /* nbits */
  long long algn;      /* aligned (bytes), 0 none */
  int packed;
  struct cs_field *nxt;
  long long alnmax; int hasaln;   /* its aligned attribute's largest */
  int anon;             /* C11's anonymous member */
};
/* a record's members and the records and enums defined in it, in their order (T3c) */
struct cs_inner { struct cs_rec *r; struct cs_field *f; struct cs_inner *nxt; };
struct cs_rec {
  int k;                /* TY_STRUCT, TY_UNION, TY_ENUM */
  unsigned char *tag; long tlen;
  unsigned char *loc; long llen;   /* an anonymous one's place: (anon at FILE:L:C) */
  unsigned char *td; long tdlen;   /* the typedef that names an anonymous one */
  struct cs_field *first, *last;
  int complete, packed, transparent, laid;
  long long algn;      /* aligned (bytes), 0 none */
  long long bytes, isal;   /* bytes */
  struct cs_ty *intty, *promo;        /* an enum's integer type and its promotion */
  struct cs_inner *in_first, *in_last;
  struct cs_decl **enums; long nenums;   /* an enum's constants */
  long long alnmax; int hasaln; long long tdalign;   /* its aligned attribute's largest; the aligned of the typedef that defines it */
  struct cs_rec *allnext;  /* all the unit's records and enums, in the order of their definitions */
  unsigned char *dtext; long dlen;   /* its definition's text */
  struct cs_decl *infn;    /* the function it is defined in */
  long nfn;
};
struct cs_decl {
  int k;                /* DK_ */
  unsigned char *name; long nlen;
  struct cs_ty *t;
  long long val;        /* an enumerator's */
  int sc;               /* SC_ */
  int builtin;          /* a builtin of the prelude */
  int hasbody, kr, inl;
  long long algn;
  struct cs_decl *prev;
  /* for the C layer (T3c) */
  struct cs_spec *sp;      /* its attributes */
  struct cs_ex *init;
  struct cs_st *body;
  struct cs_pdecl *ps; long np;
  long off;             /* its name's place */
  int local, tls, errfn, hasinit, uns;
  char *global;         /* a function's static: its name as a global */
  struct cs_decl *fnnext;
  struct cs_rec **tags; long ntags, roomtags;   /* the records and enums its body defines */
  struct cl_unit *unit;    /* the unit it is reached from */
  unsigned char *dtext; long dlen;   /* its definition's text, as clang's range (c2ff's def_text): from its specifiers to its last token */
};
struct cs_ex {
  int k;                /* E_ */
  int op;               /* an operator's, a cast's kind */
  struct cs_ty *t;
  int lv;               /* an lvalue */
  struct cs_ex **kid; long nk, room;
  unsigned char *name; long nlen;
  long long val; int isval; int isnull;
  struct cs_ty *lhsty, *resty;   /* CASS's computation types; sizeof's argument type */
  struct cs_decl *d;
  struct cs_field *fd;     /* a member's field */
  int arrow;
  unsigned char *text; long tlen;  /* a statement expression's lines */
  struct node *src;
  int paren;            /* the parentheses around it */
  struct cs_st *st;     /* a statement expression's block */
  struct cs_ty **tys;   /* _Generic: each association's type, 0 for its default; val the one selected, its kids x and then their values */
};
/* a statement (T3c) */
enum { S_BLOCK, S_EXPR, S_IF, S_WHILE, S_DO, S_FOR, S_SWITCH, S_CASE, S_DEFAULT, S_LABEL, S_GOTO, S_IGOTO, S_RETURN, S_ASM, S_BREAK, S_CONTINUE, S_NULL, S_DECL };
struct cs_dl { struct cs_decl *d; int kind; struct cs_ex *msg; struct cs_dl *nxt; };   /* kind 0 a declaration, 1 a _Static_assert, 2 a typedef */
struct cs_st {
  int k;
  long off;
  struct cs_ex *e, *e2, *e3;
  struct cs_st *a, *b;
  struct cs_st **kid; long nk, room;
  unsigned char *name; long nlen;
  struct cs_dl *dl, *dlast;
  struct cs_ex **ops; long nops;   /* an asm statement's operands, the outputs first */
  struct node *src;
};
/* the unit's declarations, in their order (T3c) */
enum { TOP_VAR, TOP_FN, TOP_TYPEDEF, TOP_REC, TOP_ENUM, TOP_ASM, TOP_WEAK };
struct cs_top { int k; struct cs_decl *d; struct cs_rec *r; struct node *src; struct node *specs; struct cs_top *nxt; };
void cl_options (char *page, char *glibc_src, char *libgcc_src, char *shared, char **roots, long nroots);
void cl_new_unit (char *name, int object);
void cl_finish (void);
void cl_options2 (char *program, char *indexf, int start, char **zero, long nzero, char **weak, long nweak, int keep_going);
void cs_run (struct node *root, unsigned char *src, long n, long skip, int target, int mode, char *name);
