/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A struct passed by value between the program and glibc: div, ldiv,
   lldiv and imaxdiv return one, inet_ntoa takes a struct in_addr. The
   program's record from glibc's headers is the tree's own (csema names it
   as the tree does; a copy named prog was another type to ttpc, and
   d = div (10, 3) took the call as d's first field: stdlib's testdiv). A
   record the program defines under a name of the tree but with other
   fields, struct in6addrinfo here (glibc's own is resolv's), stays the
   program's own. imaxdiv waits: glibc's is an alias of ldiv, so the tree's
   call returns ldiv_t into the program's imaxdiv_t (another record).  */
#include <arpa/inet.h>
#include <inttypes.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>

struct in6addrinfo { char c; long x; };

int
main (void)
{
  div_t d = div (10, 3);
  ldiv_t l = ldiv (-10L, 3L);
  lldiv_t ll = lldiv (100LL, 7LL);
  struct in_addr a;
  struct in6addrinfo o = { 'x', 42 };
  a.s_addr = htonl (0x7f000001);
  printf ("div %d %d, ldiv %ld %ld, lldiv %lld %lld, imaxdiv waiting\n",
          d.quot, d.rem, l.quot, l.rem, ll.quot, ll.rem);
  printf ("inet_ntoa %s, own %c %ld\n", inet_ntoa (a), o.c, o.x);
  return 0;
}
