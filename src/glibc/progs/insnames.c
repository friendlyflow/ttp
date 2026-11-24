/* C names that are instruction words of a target (csema writes them name',
   the asm's definitions s2ff writes so too: the user's choice, 2026-11-20):
   glibc's brk (aarch64's brk) and setns (x86_64's setns), and the
   program's own functions and data named like riscv64's, x86_64's,
   aarch64's and arm's instructions; each called or read, and its address
   taken. Every target prints the same.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#define _GNU_SOURCE
#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <sched.h>

/* (riscv64, x86_64, aarch64 and arm: add, sub; aarch64 and x86_64: ret;
   aarch64: b, str, orr, cbz; riscv64: lb, sd, fence; arm: ldr, mov; x86_64:
   setne, cmovz) */
static int __attribute__ ((noinline)) add (int x, int y) { return x + y; }
static int __attribute__ ((noinline)) sub (int x, int y) { return x - y; }
int __attribute__ ((noinline)) ret (int x) { return x + 1; }
int b = 7;
static const char str[] = "s-t-r";   /* (its text no name: a text leaf naming a global is read as that name, a fault of its own) */
long orr = 0x0f, lb = 3, sd = 4, ldr = 5, mov = 6, setne = 8, cmovz = 9;
static int __attribute__ ((noinline)) cbz (int x) { return x == 0; }
static int __attribute__ ((noinline)) fence (int (*f) (int, int)) { return f (40, 2); }

int main (void)
{
  int (*volatile fp) (int, int) = add;
  void *volatile a[] = { (void *) &brk, (void *) &setns, (void *) &add, (void *) &ret, (void *) &b, (void *) &orr, (void *) &cbz };
  long n = 0;
  int r, e;
  for (unsigned i = 0; i < sizeof a / sizeof a[0]; i++)
    n += a[i] != 0;
  printf ("addresses: %ld\n", n);
  printf ("calls: %d %d %d %d %d\n", add (2, 3), sub (5, 3), ret (1), cbz (0), fence (fp));
  printf ("data: %d %s %ld %ld %ld %ld %ld %ld %ld\n", b, str, orr, lb, sd, ldr, mov, setne, cmovz);
  r = brk (sbrk (0));
  printf ("brk: %d\n", r);
  errno = 0;
  r = setns (-1, 0);
  e = errno;
  printf ("setns: %d %s\n", r, e == EBADF ? "EBADF" : "other");
  return 0;
}
