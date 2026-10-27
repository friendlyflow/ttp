/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* gcc's frames for progs/unwind.c: built by gcc alone (-nostdlib, at an
   address of its own, its .eh_frame from -funwind-tables), which
   unwind.c maps and registers (__register_frame), then calls: a frame of
   gcc's between two of the program's, for each unwinder to walk. */

__attribute__ ((noinline)) int gcc_mid (int (*cb) (int), int x)
{
  int r = cb (x + 1);
  __asm__ volatile ("" ::: "memory");
  return r + 1;
}

__attribute__ ((noinline)) void gcc_forced (void (*f) (int), int x)
{
  f (x + 1);
  __asm__ volatile ("" ::: "memory");
}
