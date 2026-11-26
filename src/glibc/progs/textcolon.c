/* Texts that end in a colon: a char array's (coreutils expand.c's
   shortopts "it:0::1::...9::", which ttpc read as a definition, the array
   empty) and texts in expressions; csema writes them as bytes.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
#include <string.h>
static char const shortopts[] = "it:0::1::2::3::4::5::6::7::8::9::";
char const usage[] = "Usage:";
static const char *pick (int i) { return i ? "b:" : "a::"; }
int main (void)
{
  printf ("%zu %s\n", strlen (shortopts), shortopts);
  printf ("%zu %s %s %s\n", strlen (usage), usage, pick (0), pick (1));
  return 0;
}
