/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* libgcc's unwinder over the program's own frames: _Unwind_Backtrace from
   walk, three calls deep, names each frame by the function its FDE says it
   is in (_Unwind_FindEnclosingFunction), up to main; _Unwind_ForcedUnwind
   from g3, two calls deep, as glibc's thread cancellation does it: its stop
   function sees each frame, their CFAs rising, and longjmps out at g1's, as
   glibc's unwind_stop at a cleanup's frame. Built with gcc against libc.a
   and gcc's libgcc_eh.a, and by ttpc -g (.eh_frame, .eh_frame_hdr) against
   glibc and libgcc in ff, which finds the frames through dl_iterate_phdr. */

#include <setjmp.h>
#include <stdio.h>
#include <string.h>
#include <unwind.h>

static int walk (int);
static int f1 (int), f2 (int), f3 (int);
static void g1 (int), g2 (int), g3 (int);
int main (void);

static const struct { void *fn; const char *name; } fns[] = {
  { (void *) walk, "walk" }, { (void *) f1, "f1" }, { (void *) f2, "f2" }, { (void *) f3, "f3" },
  { (void *) g1, "g1" }, { (void *) g2, "g2" }, { (void *) g3, "g3" }, { (void *) main, "main" },
};

static const char *name_of (struct _Unwind_Context *c)
{
  void *f = _Unwind_FindEnclosingFunction ((void *) (_Unwind_GetIP (c) - 1));
  for (unsigned int i = 0; i < sizeof fns / sizeof fns[0]; i++)
    if (fns[i].fn == f)
      return fns[i].name;
  return "?";
}

static char seen[256];
static unsigned int at;

static void see (const char *n)
{
  seen[at++] = ' ';
  while (*n && at < sizeof seen - 1)
    seen[at++] = *n++;
  seen[at] = 0;
}

static _Unwind_Reason_Code trace (struct _Unwind_Context *c, void *arg)
{
  const char *n = name_of (c);
  ++*(int *) arg;
  see (n);
  return strcmp (n, "main") == 0 ? _URC_END_OF_STACK : _URC_NO_REASON;
}

static volatile int sink;

static __attribute__ ((noinline)) int walk (int x)
{
  int frames = 0;
  int r = _Unwind_Backtrace (trace, &frames);
  printf ("backtrace:%s (%d frames, %d)\n", seen, frames, r);
  return x + sink;
}
static __attribute__ ((noinline)) int f3 (int x) { return walk (x + 1) + sink + 1; }
static __attribute__ ((noinline)) int f2 (int x) { return f3 (x + 1) + sink + 1; }
static __attribute__ ((noinline)) int f1 (int x) { return f2 (x + 1) + sink + 1; }

static jmp_buf out;
static unsigned long last_cfa;
static int rising = 1;
static struct _Unwind_Exception exc;

static _Unwind_Reason_Code stop (int version, _Unwind_Action actions, _Unwind_Exception_Class cls,
                                 struct _Unwind_Exception *e, struct _Unwind_Context *c, void *param)
{
  const char *n = name_of (c);
  unsigned long cfa = _Unwind_GetCFA (c);
  if (cfa <= last_cfa)
    rising = 0;
  last_cfa = cfa;
  see (n);
  if ((actions & _UA_END_OF_STACK) || version != 1 || e != &exc || param != &exc)
    longjmp (out, 2);
  if (strcmp (n, "g1") == 0)
    longjmp (out, 1);
  return _URC_NO_REASON;
}

static __attribute__ ((noinline)) void g3 (int x)
{
  exc.exception_class = 0x7474705f66660000UL;
  sink = x;
  _Unwind_ForcedUnwind (&exc, stop, &exc);
  printf ("forced: returned\n");
}
static __attribute__ ((noinline)) void g2 (int x) { g3 (x + 1); sink = 0; }
static __attribute__ ((noinline)) void g1 (int x) { g2 (x + 1); sink = 0; }

int main (void)
{
  int r = f1 (1);
  seen[at = 0] = 0;
  int j = setjmp (out);
  if (j == 0)
    g1 (1);
  printf ("forced:%s (longjmp %d, CFAs %s)\n", seen, j, rising ? "rising" : "not rising");
  return r;
}
