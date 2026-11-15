/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* the native dev shim: libc in place of tools/rt.ff, tools/c.ff's cp_* and s2ff/shim.ff.txt */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
void *alloc (long n) { void *p = calloc (1, n ? n : 1); if (!p) { fputs ("out of memory\n", stderr); exit (1); } return p; }
long cp_write (int fd, unsigned char *p, long n) { long r = write (fd, p, n); return r < 0 ? -errno : r; }
long cp_create (char *path) { long fd = open (path, O_WRONLY | O_CREAT | O_TRUNC, 0666); return fd < 0 ? -errno : fd; }
long cp_readlink (char *path, unsigned char *buf, long room) { long r = readlink (path, (char *) buf, room); return r < 0 ? -errno : r; }
void cp_exit (int s) { exit (s); }
long s2_open (char *path) { long fd = open (path, O_RDONLY); return fd < 0 ? -errno : fd; }
long s2_exists (char *path) { long fd = open (path, O_PATH); return fd < 0 ? -errno : fd; }
long s2_read (long fd, unsigned char *buf, long n) { long r = read (fd, buf, n); return r < 0 ? -errno : r; }
long s2_close (long fd) { return close (fd); }
int s2ff_main (int, char **);
int main (int argc, char **argv) { return s2ff_main (argc, argv); }
