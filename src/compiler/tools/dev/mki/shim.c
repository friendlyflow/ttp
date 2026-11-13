/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* the native dev shim: libc in place of tools/rt.ff, tools/c.ff's cp_* and mki/shim.ff.txt */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
void *alloc (long n) { void *p = calloc (1, n ? n : 1); if (!p) { fputs ("out of memory\n", stderr); exit (1); } return p; }
long cp_write (int fd, unsigned char *p, long n) { long r = write (fd, p, n); return r < 0 ? -errno : r; }
long cp_readlink (char *path, unsigned char *buf, long room) { long r = readlink (path, (char *) buf, room); return r < 0 ? -errno : r; }
void cp_exit (int s) { exit (s); }
long mk_open (char *path) { long fd = open (path, O_RDONLY); return fd < 0 ? -errno : fd; }
long mk_exists (char *path) { long fd = open (path, O_PATH); return fd < 0 ? -errno : fd; }
long mk_read (long fd, unsigned char *buf, long n) { long r = read (fd, buf, n); return r < 0 ? -errno : r; }
long mk_close (long fd) { return close (fd); }
long mk_mkdir (char *path) { return mkdir (path, 0777) < 0 ? -errno : 0; }
long mk_run (char *path, char **argv, char **envp)
{
  int st; pid_t p = fork ();
  if (p == 0) { execve (path, argv, envp); _exit (127); }
  if (p < 0 || waitpid (p, &st, 0) < 0) return -1;
  return st;
}
int mki_main (int, char **);
int main (int argc, char **argv) { return mki_main (argc, argv); }
