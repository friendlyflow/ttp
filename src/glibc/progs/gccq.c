/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* gccrt on x86_64: gcc's code calling libgcc's __multc3 and __divtc3, the
   complex float128 (_Complex __float128, in memory by the SysV ABI) of four
   binary128 operands. Built by gcc alone and linked as asm (s2ff) into both
   programs: in ttpc's program it calls libgcc's functions in ff, in gcc's
   gcc's libgcc.a. Its operands come and its results go through memory as
   bits, so this side's calls are the ones checked. */

typedef _Complex _Float128 cq;
typedef _Float128 tf;
cq __multc3 (tf, tf, tf, tf);
cq __divtc3 (tf, tf, tf, tf);

static void
put (cq z, unsigned long long *r)
{
  union { cq z; unsigned long long u[4]; } v;
  v.z = z;
  r[0] = v.u[0]; r[1] = v.u[1]; r[2] = v.u[2]; r[3] = v.u[3];
}

static tf
get (const unsigned long long *p)
{
  tf x;
  __builtin_memcpy (&x, p, sizeof x);
  return x;
}

/* p: the four operands' bits, two words each; r: the product's and the
   quotient's, four words each */
void
gccq_muldiv (const unsigned long long *p, unsigned long long *r)
{
  tf a = get (p), b = get (p + 2), c = get (p + 4), d = get (p + 6);
  put (__multc3 (a, b, c, d), r);
  put (__divtc3 (a, b, c, d), r + 4);
}
