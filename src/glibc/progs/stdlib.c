/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* M2: glibc's atoi, strtol and abs: bases, signs, leading space, a 0x
   prefix, where the number ends, overflow (errno ERANGE), and no digits.
   Built with gcc against libc.a and, through c2ff, with ttpc against
   stdlib.ff: both must exit with the status in stdlib.expect, a hash of
   every result. No headers, so that the two builds see the same
   declarations. */

int atoi (const char *);
long strtol (const char *, char **, int);
int abs (int);
extern __thread int errno;

static const char *const texts[] = {
  "0", "42", "-17", "  +123abc", "\t\n 0x1fG", "0777", "-0x80000000",
  "9223372036854775807", "9223372036854775808", "-9223372036854775809",
  "zz", "", "  -", "101", "7fffffff", "-0", "000123",
};
static const int bases[] = { 0, 2, 8, 10, 16, 36 };

int
main (void)
{
  unsigned long h = 0;
  int n = sizeof texts / sizeof texts[0];
  for (int i = 0; i < n; i++)
    {
      h = h * 31 + (unsigned) atoi (texts[i]);
      for (int b = 0; b < 6; b++)
        {
          char *end;
          errno = 0;
          long v = strtol (texts[i], &end, bases[b]);
          h = h * 31 + (unsigned long) v;
          h = h * 31 + (unsigned long) (end - texts[i]);
          h = h * 31 + (unsigned) errno;
        }
    }
  h = h * 31 + abs (-5) + abs (7) * 3 + abs (0) * 11;
  return (int) ((h ^ (h >> 8) ^ (h >> 16) ^ (h >> 24)) & 255);
}
