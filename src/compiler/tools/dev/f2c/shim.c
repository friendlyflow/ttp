/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* the native dev shim: libc in place of tools/rt.ff, tools/c.ff's cp_*,
   fftree.ff's reader and f2c/shim.ff.txt; the C words of before from
   gen/Words.pm itself (perl, F2C_GEN the folder of gen/), where the page
   has words.ff's */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <ctype.h>
struct node { unsigned char hash[32]; long count; long room; struct node **kids; long len; unsigned char *text; };
void *alloc (long n) { void *p = calloc (1, n ? n : 1); if (!p) { fputs ("out of memory\n", stderr); exit (1); } return p; }
long cp_write (int fd, unsigned char *p, long n) { long r = write (fd, p, n); return r < 0 ? -errno : r; }
long cp_create (char *path) { long fd = open (path, O_WRONLY | O_CREAT | O_TRUNC, 0666); return fd < 0 ? -errno : fd; }
long cp_readlink (char *path, unsigned char *buf, long room) { long r = readlink (path, (char *) buf, room); return r < 0 ? -errno : r; }
void cp_exit (int s) { exit (s); }
long s2_open (char *path) { long fd = open (path, O_RDONLY); return fd < 0 ? -errno : fd; }
long s2_exists (char *path) { long fd = open (path, O_PATH); return fd < 0 ? -errno : fd; }
long s2_read (long fd, unsigned char *buf, long n) { long r = read (fd, buf, n); return r < 0 ? -errno : r; }
long s2_close (long fd) { return close (fd); }
long f2_mkdir (char *path) { return mkdir (path, 0777) < 0 ? -errno : 0; }

static void add (struct node *n, struct node *k)
{
  if (n->count == n->room) { n->room = n->room * 2 + 4; n->kids = realloc (n->kids, n->room * sizeof *n->kids); }
  n->kids[n->count++] = k;
}
/* FF.pm's read_txt (its unescape and its messages) */
struct node *f2_read_txt (unsigned char *p, long n, char *name)
{
  struct node *root = alloc (sizeof *root), **stack = alloc ((n / 2 + 2) * sizeof *stack);
  long at = 0, line = 0, depth = 0, top = 0;
  while (at < n) {
    long e = at, ind = 0, d, i;
    unsigned char *t;
    struct node *x;
    while (e < n && p[e] != '\n') e++;
    line++;
    if (e == at) { fprintf (stderr, "ff: empty line at %s:%ld\n", name, line); exit (255); }
    while (at + ind < e && p[at + ind] == ' ') ind++;
    if (ind % 2) { fprintf (stderr, "ff: odd indent at %s:%ld\n", name, line); exit (255); }
    d = ind / 2;
    if (d > top) { fprintf (stderr, "ff: indent jumps at %s:%ld\n", name, line); exit (255); }
    x = alloc (sizeof *x);
    t = alloc (e - at - ind + 1);
    x->text = t;
    if (e - at - ind == 2 && p[at + ind] == '\\' && p[at + ind + 1] == 'e') x->len = 0;
    else for (i = at + ind; i < e; i++) {
      if (p[i] != '\\') { t[x->len++] = p[i]; continue; }
      i++;
      if (i < e && p[i] == '\\') t[x->len++] = '\\';
      else if (i < e && p[i] == 'n') t[x->len++] = '\n';
      else if (i + 2 < e && p[i] == 'x' && isxdigit (p[i + 1]) && isxdigit (p[i + 2])) { char h[3] = { p[i + 1], p[i + 2], 0 }; t[x->len++] = strtol (h, 0, 16); i += 2; }
      else { fprintf (stderr, "ff: bad escape \\%c at %s:%ld\n", i < e ? p[i] : ' ', name, line); exit (255); }
    }
    if (d) add (stack[d - 1], x); else add (root, x);
    stack[d] = x;
    top = d + 1;
    depth = d;
    at = e + 1;
  }
  (void) depth;
  return root;
}
static struct node *rd (unsigned char **p, unsigned char *end)
{
  struct node *n = alloc (sizeof *n); long c, i;
  if (*p + 33 > end) { fprintf (stderr, "ff: truncated node\n"); exit (255); }
  memcpy (n->hash, *p, 32); *p += 32; c = *(*p)++;
  for (i = 0; i < c; i++) add (n, rd (p, end));
  n->len = *(*p)++; n->text = *p; *p += n->len;
  return n;
}
struct node *f2_read_ff (unsigned char *p, long n) { return rd (&p, p + n); }
static void wtxt (FILE *f, struct node *n, int d)
{
  long i;
  for (i = 0; i < d; i++) fputs ("  ", f);
  if (!n->len) fputs ("\\e", f);
  for (i = 0; i < n->len; i++) {
    unsigned c = n->text[i];
    if (c == '\\') fputs ("\\\\", f);
    else if (c == '\n') fputs ("\\n", f);
    else if (c < 32 || c == 127 || (c == ' ' && (i == 0 || i == n->len - 1))) fprintf (f, "\\x%02x", c);
    else fputc (c, f);
  }
  fputc ('\n', f);
  for (i = 0; i < n->count; i++) wtxt (f, n->kids[i], d + 1);
}
struct node *f2_oldwords (struct node *root, struct node *shared, long arm)
{
  char tr[] = "/tmp/f2c-tree-XXXXXX", sh[] = "/tmp/f2c-shared-XXXXXX", ou[] = "/tmp/f2c-old-XXXXXX", cmd[4096];
  char *gen = getenv ("F2C_GEN");
  FILE *f;
  long i, n;
  unsigned char *p;
  close (mkstemp (tr)); close (mkstemp (sh)); close (mkstemp (ou));
  f = fopen (tr, "w"); for (i = 0; i < root->count; i++) wtxt (f, root->kids[i], 0); fclose (f);
  f = fopen (sh, "w"); for (i = 0; i < shared->count; i++) wtxt (f, shared->kids[i], 0); fclose (f);
  snprintf (cmd, sizeof cmd, "perl -I%s -MFF -MWords -e 'sub rd { open my $h, \"<:raw\", $_[0] or die; local $/; FF::read_txt(<$h> // \"\", $_[0]) } "
    "my $t = {}; Words::typenames($t, rd($ARGV[0])); Words::long32() if $ARGV[3]; open my $o, \">:raw\", $ARGV[2] or die; print $o FF::write_txt(Words::oldwords($t, rd($ARGV[1])))' %s %s %s %ld",
    gen ? gen : "gen", sh, tr, ou, arm);
  if (system (cmd) != 0) { fprintf (stderr, "f2c shim: perl failed\n"); exit (1); }
  f = fopen (ou, "rb"); fseek (f, 0, SEEK_END); n = ftell (f); fseek (f, 0, SEEK_SET); p = malloc (n + 1); if (fread (p, 1, n, f) != (size_t) n) exit (1); fclose (f);
  unlink (tr); unlink (sh); unlink (ou);
  return f2_read_txt (p, n, "oldwords");
}
int ff2c_main (int, char **);
int main (int argc, char **argv) { return ff2c_main (argc, argv); }
