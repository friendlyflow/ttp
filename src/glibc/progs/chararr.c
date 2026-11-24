/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A local byte array whose items are variables, as grep's main has it
   (char eolbytes[3] = { 0, eolbyte, 0 }): to ttpc a leaf item of a char
   array is its text, whatever it names, so csema writes such an item in
   a : (a number stays a leaf). Globals, locals, parameters; char, signed
   and unsigned char, _Bool; an enum constant. */
#include <stdio.h>
#include <stdbool.h>

enum { SEP = ':' };
char eolbyte = '\n';
/* (hiv, not hi: fault 22, a program global named like an asm condition, aarch64's
   hi, stopped ttpc there; see ttpcbugs3's test) */
static unsigned char hiv = 200;

static int
sum (signed char p, bool b)
{
  signed char l = -3;
  char eolbytes[3] = { 0, eolbyte, 0 };
  signed char s[4] = { p, l, -1, SEP };
  unsigned char u[2] = { hiv, (unsigned char) p };
  bool bs[2] = { b, true };
  char e[2] = { SEP, eolbyte };
  return eolbytes[0] * 1000 + eolbytes[1] + s[0] + s[1] + s[2] + s[3] + u[0] + u[1] + bs[0] + bs[1] + e[0] + e[1];
}

int
main (void)
{
  printf ("sum %d %d\n", sum (5, true), sum (-7, false));
  return 0;
}
