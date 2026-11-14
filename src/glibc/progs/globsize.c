/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A global whose value is sizeof or alignof of a type, alone or as a
   field's (glibc's nptl _thread_db_sizeof_pthread ...): csema writes it in
   a :, else ttpc took the global for a function (found by datacheck). Each
   checked against the code's own (the exit status is the number that
   fail), with no part of glibc but the builtins, built with gcc + libc.a
   and through csema --start with ttpc on every target. And a field of a
   typedef aligned more than its type (arm's __jmp_buf, int [64] aligned
   (8): struct __jmp_buf_tag was 388 bytes for gcc's 392, found by
   datacheck): csema writes the field's align. And packed: a packed field
   (resolv.h's __glibc_extension_index, an unsigned long long aligned to 4
   by it on arm), a packed record, an array of them, read and written. */

struct pair { long a; char *p; };
struct two { unsigned long x, y; };
typedef int three[3] __attribute__ ((aligned (8)));
struct tdal { char c; three a; };
struct pkf { char c; unsigned long long x __attribute__ ((packed)); int y; };
struct pkr { char c; unsigned short s; unsigned long long q; double d; } __attribute__ ((packed));
struct pkr pkarr[3];
struct pkf pkone = { 1, 0x0123456789abcdefULL, 5 };

const unsigned int size_pair = sizeof (struct pair);
unsigned long size_long = sizeof (long);
unsigned long align_long = _Alignof (long);
struct two both = { sizeof (int), _Alignof (struct pair) };
unsigned long sizes[2] = { sizeof (short), sizeof (char *) };
unsigned long size_tdal = sizeof (struct tdal);

static volatile unsigned long one = 1;

int
main (void)
{
  int f = 0;
  f += size_pair != one * sizeof (struct pair);
  f += size_long != one * sizeof (long);
  f += align_long != one * _Alignof (long);
  f += both.x != one * sizeof (int);
  f += both.y != one * _Alignof (struct pair);
  f += sizes[0] != one * sizeof (short);
  f += sizes[1] != one * sizeof (char *);
  f += sizeof (struct tdal) != 24;
  f += __builtin_offsetof (struct tdal, a) != 8;
  f += size_tdal != 24;
  f += sizeof (struct pkf) != 16 || __builtin_offsetof (struct pkf, x) != 1 || _Alignof (struct pkf) != 4;
  f += sizeof (struct pkr) != 19 || __builtin_offsetof (struct pkr, d) != 11 || _Alignof (struct pkr) != 1;
  f += pkone.x != one * 0x0123456789abcdefULL || pkone.y != 5;
  pkarr[1].q = one * 0x1122334455667788ULL;
  pkarr[2].s = one * 4660;
  pkarr[2].d = one * 2.5;
  f += pkarr[1].q != 0x1122334455667788ULL || pkarr[2].s != 4660 || (long) (pkarr[2].d * 2) != 5;
  f += (char *) &pkarr[2] - (char *) &pkarr[0] != 38;
  return f;
}
