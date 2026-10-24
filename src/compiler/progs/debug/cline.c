/* SPDX-License-Identifier: GPL-3.0-only
 * Copyright (C) 2026 Nico Verrijdt
 * This file is part of ttp. It is free software: you can redistribute it
 * and/or modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation, version 3 of the License.
 * It comes with no warranty. See the file LICENSE for the full text.
 *
 * cline.c: the C that progs/cline.ff is a translation of, its line nodes
 * the places of its statements here (as c2ff writes them from clang's),
 * so that ttpc -g's line table names this file: progs/debug/run.sh. */
void sys_exit(long status);   /* ff's syscall / SYS_exit / status */
long twice(long x)
{
  long y = x + x;
  return y;
}

long add3(long n)
{
  long r = twice(n);
  if (r > 10)
    r = r + 1;
  return r + 2;
}

void _start(void)
{
  long v = add3(20);
  sys_exit(v);
}
