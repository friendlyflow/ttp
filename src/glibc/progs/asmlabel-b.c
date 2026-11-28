/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* asmlabel-a.c's functions and variable, used by their C names under its labels */
#include <stdio.h>
#include <unistd.h>
extern int show (const char *, ...) __asm__ ("rpl_show");
extern int twice (int) __asm__ ("rpl_twice");
extern int count __asm__ ("rpl_count");
const char *mine (void);
int main (void)
{
  char *argv[] = { "p", "-x", "val", 0 };
  int c = getopt (3, argv, "x:");
  int (*p) (int) = twice;
  count += 2;
  show ("%d %d %d %c %s %s\n", twice (21), p (3), count, c, optarg, mine ());
  return 0;
}
