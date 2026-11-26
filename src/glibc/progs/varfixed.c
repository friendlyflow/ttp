/* glibc's syscall, declared variadic (unistd.h: long syscall (long, ...)),
   whose riscv64 definition (syscall.c) takes 7 longs, called with fewer
   (xz's sandbox's landlock calls): csema calls it as declared, through a
   pointer of that type; every target prints the same.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
int main (void)
{
  long a = syscall (SYS_getpid) > 0, b = syscall (SYS_getppid) > 0;
  printf ("%ld %ld\n", a, b);
  return 0;
}
