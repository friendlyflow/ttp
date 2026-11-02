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
   glibc and libgcc in ff, which finds the frames through dl_iterate_phdr.
   Then the same over frames of gcc's and the program's mixed: FILE
   (progs/unwind-gcc.c, by gcc alone) is mapped where it says, its .eh_frame
   registered (__register_frame), and its gcc_mid and gcc_forced call back
   into the program, whose walks pass through gcc's frame. */

#ifdef __arm__
#define _GNU_SOURCE     /* (link.h's dl_iterate_phdr) */
#endif
#include <elf.h>
#include <fcntl.h>
#include <setjmp.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <unwind.h>
#ifdef __ARM_EABI_UNWINDER__
#include <link.h>
#endif

/* (an ELF of the target's word: arm's 32 bits) */
#if __SIZEOF_POINTER__ == 8
typedef Elf64_Ehdr Ehdr; typedef Elf64_Phdr Phdr; typedef Elf64_Shdr Shdr; typedef Elf64_Sym Sym;
#else
typedef Elf32_Ehdr Ehdr; typedef Elf32_Phdr Phdr; typedef Elf32_Shdr Shdr; typedef Elf32_Sym Sym;
#endif

#ifndef __ARM_EABI_UNWINDER__
void __register_frame (void *);
#else
/* arm's EHABI unwinder has no __register_frame and no
   _Unwind_FindEnclosingFunction: it asks __gnu_Unwind_Find_exidx for the
   index table of an address (glibc's, which takes the program's,
   PT_ARM_EXIDX, from dl_iterate_phdr), here the program's own: gcc's part's
   .ARM.exidx where the address is in its text, else the program's as
   glibc's does; a function is the nearest of fns at or below the address */
static unsigned long gcc_lo, gcc_hi, gcc_exidx, gcc_nexidx;
struct find { unsigned long pc, exidx; int n; };
static int find_phdr (struct dl_phdr_info *info, size_t size, void *arg)
{
  struct find *f = arg;
  const ElfW(Phdr) *load = 0, *exidx = 0;
  for (int i = 0; i < info->dlpi_phnum; i++)
    {
      const ElfW(Phdr) *p = &info->dlpi_phdr[i];
      if (p->p_type == PT_LOAD && f->pc >= info->dlpi_addr + p->p_vaddr && f->pc < info->dlpi_addr + p->p_vaddr + p->p_memsz)
        load = p;
      if (p->p_type == PT_ARM_EXIDX)
        exidx = p;
    }
  if (!load || !exidx)
    return 0;
  f->exidx = info->dlpi_addr + exidx->p_vaddr;
  f->n = exidx->p_memsz / 8;
  return 1;
}
_Unwind_Ptr __gnu_Unwind_Find_exidx (_Unwind_Ptr pc, int *count)
{
  if (pc >= gcc_lo && pc < gcc_hi)
    {
      *count = gcc_nexidx;
      return gcc_exidx;
    }
  struct find f = { pc, 0, 0 };
  if (dl_iterate_phdr (find_phdr, &f) <= 0)
    return 0;
  *count = f.n;
  return f.exidx;
}
#endif

static int walk (int);
static int f1 (int), f2 (int), f3 (int);
static void g1 (int), g2 (int), g3 (int);
int main (int, char **);

static int cb (int);
static void g1m (int);

static struct { void *fn; const char *name; } fns[] = {
  { (void *) walk, "walk" }, { (void *) f1, "f1" }, { (void *) f2, "f2" }, { (void *) f3, "f3" },
  { (void *) g1, "g1" }, { (void *) g2, "g2" }, { (void *) g3, "g3" }, { (void *) main, "main" },
  { (void *) cb, "cb" }, { (void *) g1m, "g1m" }, { 0, "gcc_mid" }, { 0, "gcc_forced" },
};

static const char *name_of (struct _Unwind_Context *c)
{
#ifndef __ARM_EABI_UNWINDER__
  void *f = _Unwind_FindEnclosingFunction ((void *) (_Unwind_GetIP (c) - 1));
  for (unsigned int i = 0; i < sizeof fns / sizeof fns[0]; i++)
    if (fns[i].fn == f)
      return fns[i].name;
  return "?";
#else
  unsigned long ip = _Unwind_GetIP (c) - 1, best = 0;
  const char *n = "?";
  for (unsigned int i = 0; i < sizeof fns / sizeof fns[0]; i++)
    if ((unsigned long) fns[i].fn <= ip && (unsigned long) fns[i].fn > best)
      {
        best = (unsigned long) fns[i].fn;
        n = fns[i].name;
      }
  return n;
#endif
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
  if (strcmp (n, "g1") == 0 || strcmp (n, "g1m") == 0)
    longjmp (out, 1);
  return _URC_NO_REASON;
}

static __attribute__ ((noinline)) void g3 (int x)
{
  memcpy (&exc.exception_class, "\0\0ff_ptt", 8);
  sink = x;
  _Unwind_ForcedUnwind (&exc, stop, &exc);
  printf ("forced: returned\n");
}
static __attribute__ ((noinline)) void g2 (int x) { g3 (x + 1); sink = 0; }
static __attribute__ ((noinline)) void g1 (int x) { g2 (x + 1); sink = 0; }

/* gcc's part: its PT_LOAD mapped where it says, its .eh_frame registered,
   gcc_mid and gcc_forced found by its symbols */
static unsigned char file[1 << 16];
static int (*gcc_mid) (int (*) (int), int);
static void (*gcc_forced) (void (*) (int), int);

static int load (const char *path)
{
  int fd = open (path, O_RDONLY);
  if (fd < 0 || read (fd, file, sizeof file) <= 0)
    return 0;
  Ehdr *e = (Ehdr *) file;
  Phdr *ph = (Phdr *) (file + e->e_phoff);
  for (int i = 0; i < e->e_phnum; i++)
    if (ph[i].p_type == PT_LOAD)
      {
        unsigned long lo = ph[i].p_vaddr & ~4095UL;
        unsigned long len = ph[i].p_vaddr + ph[i].p_memsz - lo;
        if (mmap ((void *) lo, len, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0) != (void *) lo)
          return 0;
        memcpy ((void *) ph[i].p_vaddr, file + ph[i].p_offset, ph[i].p_filesz);
      }
  Shdr *sh = (Shdr *) (file + e->e_shoff);
  const char *shstr = (const char *) file + sh[e->e_shstrndx].sh_offset;
  for (int i = 0; i < e->e_shnum; i++)
    {
      if (strcmp (shstr + sh[i].sh_name, ".eh_frame") == 0)
#ifndef __ARM_EABI_UNWINDER__
        __register_frame ((void *) sh[i].sh_addr);
#else
        ;
      if (strcmp (shstr + sh[i].sh_name, ".ARM.exidx") == 0)
        gcc_exidx = sh[i].sh_addr, gcc_nexidx = sh[i].sh_size / 8;
      if (strcmp (shstr + sh[i].sh_name, ".text") == 0)
        gcc_lo = sh[i].sh_addr, gcc_hi = sh[i].sh_addr + sh[i].sh_size;
#endif
      if (sh[i].sh_type == SHT_SYMTAB)
        {
          Sym *sym = (Sym *) (file + sh[i].sh_offset);
          const char *str = (const char *) file + sh[sh[i].sh_link].sh_offset;
          for (unsigned long k = 0; k < sh[i].sh_size / sizeof *sym; k++)
            for (unsigned int f = 0; f < sizeof fns / sizeof fns[0]; f++)
              if (!fns[f].fn && strcmp (str + sym[k].st_name, fns[f].name) == 0)
                fns[f].fn = (void *) sym[k].st_value;
        }
    }
  gcc_mid = (int (*) (int (*) (int), int)) fns[10].fn;
  gcc_forced = (void (*) (void (*) (int), int)) fns[11].fn;
  return gcc_mid && gcc_forced;
}

static __attribute__ ((noinline)) int cb (int x)
{
  int frames = 0;
  seen[at = 0] = 0;
  int r = _Unwind_Backtrace (trace, &frames);
  printf ("mixed backtrace:%s (%d frames, %d)\n", seen, frames, r);
  return x + sink;
}
static __attribute__ ((noinline)) void g1m (int x) { gcc_forced (g3, x + 1); sink = 0; }

int main (int argc, char **argv)
{
  int r = f1 (1);
  seen[at = 0] = 0;
  int j = setjmp (out);
  if (j == 0)
    g1 (1);
  printf ("forced:%s (longjmp %d, CFAs %s)\n", seen, j, rising ? "rising" : "not rising");
  if (argc < 2 || !load (argv[1]))
    {
      printf ("no frames of gcc's\n");
      return 1;
    }
  r += gcc_mid (cb, 1);
  seen[at = 0] = 0;
  last_cfa = 0;
  j = setjmp (out);
  if (j == 0)
    g1m (1);
  printf ("mixed forced:%s (longjmp %d, CFAs %s)\n", seen, j, rising ? "rising" : "not rising");
  return r;
}
