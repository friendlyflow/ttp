/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* md5.c: Digest::MD5 (RFC 1321), for roundtrip.c: the stamp of a unit's
   cache, and where's digest of two normal forms. */

struct md5 { unsigned int h[4]; unsigned char b[64]; long nb; unsigned long len; };
static unsigned int md5_k[64] = {
  0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
  0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
  0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
  0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
  0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
  0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
  0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
  0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391 };
static int md5_r[64] = {
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21 };
static struct md5 *md5_new (void)
{
  struct md5 *m = alloc (sizeof (struct md5));
  m->h[0] = 0x67452301; m->h[1] = 0xefcdab89; m->h[2] = 0x98badcfe; m->h[3] = 0x10325476;
  return m;
}
static void md5_block (struct md5 *m, unsigned char *p)
{
  unsigned int w[16], a = m->h[0], b = m->h[1], c = m->h[2], d = m->h[3], f, t;
  long i, gi;
  for (i = 0; i < 16; i++) w[i] = (unsigned int) p[4 * i] | (unsigned int) p[4 * i + 1] << 8 | (unsigned int) p[4 * i + 2] << 16 | (unsigned int) p[4 * i + 3] << 24;
  for (i = 0; i < 64; i++) {
    if (i < 16) { f = (b & c) | (~b & d); gi = i; }
    else if (i < 32) { f = (d & b) | (~d & c); gi = (5 * i + 1) % 16; }
    else if (i < 48) { f = b ^ c ^ d; gi = (3 * i + 5) % 16; }
    else { f = c ^ (b | ~d); gi = (7 * i) % 16; }
    t = d; d = c; c = b;
    f = f + a + md5_k[i] + w[gi];
    b = b + (f << md5_r[i] | f >> (32 - md5_r[i]));
    a = t;
  }
  m->h[0] += a; m->h[1] += b; m->h[2] += c; m->h[3] += d;
}
static void md5_add (struct md5 *m, unsigned char *p, long n)
{
  long i;
  m->len += (unsigned long) n;
  for (i = 0; i < n; i++) {
    m->b[m->nb++] = p[i];
    if (m->nb == 64) { md5_block (m, m->b); m->nb = 0; }
  }
}
static struct str *md5_hex (struct md5 *m)   /* hexdigest */
{
  unsigned char pad[72], len8[8];
  unsigned long bits = m->len * 8;
  long i, k = m->nb < 56 ? 56 - m->nb : 120 - m->nb;
  struct str *o = s_of ("");
  static char *hx = "0123456789abcdef";
  for (i = 0; i < 72; i++) pad[i] = 0;
  pad[0] = 0x80;
  for (i = 0; i < 8; i++) len8[i] = (unsigned char) (bits >> (8 * i));
  md5_add (m, pad, k);
  md5_add (m, len8, 8);
  for (i = 0; i < 16; i++) { unsigned int x = m->h[i / 4] >> (8 * (i % 4)) & 255; s_chr (o, hx[x >> 4]); s_chr (o, hx[x & 15]); }
  return o;
}
