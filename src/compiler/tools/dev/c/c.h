/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* the C parser's shared declarations (dev source of tools/c.ff) */
struct node { unsigned char hash[32]; long count; long room; struct node **kids; long len; unsigned char *text; };
/* the runtime (tools/rt.ff; the shim page) */
void *alloc (long n);
unsigned char *cp_file (char *path, long *size);
long cp_write (int fd, unsigned char *p, long n);
long cp_readlink (char *path, unsigned char *buf, long room);
void cp_exit (int status);
void cp_heap_file (char *path, long size);
extern long cp_jump[2];
void cp_write_ff (struct node *root);
struct node *cp_read_ff (unsigned char *p, long n);
/* c.ff: nodes, output, the parser */
struct node *nd (char *kind);
struct node *nd_text (unsigned char *p, long n);
void nd_add (struct node *n, struct node *k);
struct node *nd_kid (struct node *n, long i);
int nd_is (struct node *n, char *s);
int nd_leaf (struct node *n);
void nd_layer (struct node *n);
void nd_flat (struct node *n);
void out_bytes (unsigned char *p, long n);
void out_str (char *s);
void out_num (long v);
void out_flush (void);
void err_str (char *s);
void err_num (long v);
void err_bytes (unsigned char *p, long n);
void c_fail (char *s);
long cstrlen (char *s);
int same (unsigned char *p, long n, char *s);
struct node *c_parse (unsigned char *src, long n, char *name);
long c_off_of (struct node *n);
void *c_state_get (void);
void c_state_set (void *x);
void c_state_new (void);
long c_parens_of (struct node *n);
void c_print (struct node *root);
void nd_emit (struct node *n);
