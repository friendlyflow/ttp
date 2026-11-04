/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* the native dev shim: libc in place of tools/rt.ff + fftree.ff */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdint.h>
#include "c.h"
#include <fcntl.h>
#include <sys/mman.h>
static char *heap, *heap_end;
void *alloc (long n)
{
  void *p;
  if (heap && heap + n + 16 < heap_end) { p = heap; heap += (n + 15) & ~15L; return p; }
  p = calloc (1, n ? n : 1);
  if (!p) { fputs ("out of memory\n", stderr); exit (1); }
  return p;
}
void cp_heap_file (char *path, long size)
{
  int fd = open (path, O_RDWR | O_CREAT | O_TRUNC, 0600);
  if (fd < 0 || unlink (path) || ftruncate (fd, size)) { perror (path); exit (1); }
  heap = mmap (0, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if (heap == MAP_FAILED) { perror ("mmap"); exit (1); }
  heap_end = heap + size;
}
__asm__ (".text\n.globl cp_setjmp\ncp_setjmp:\n movq %rbx,0(%rdi)\n movq %rbp,8(%rdi)\n movq %r12,16(%rdi)\n movq %r13,24(%rdi)\n movq %r14,32(%rdi)\n movq %r15,40(%rdi)\n popq %rdx\n movq %rsp,48(%rdi)\n movq %rdx,56(%rdi)\n movq $0,%rax\n jmp *%rdx\n"
  ".globl cp_longjmp\ncp_longjmp:\n movq 0(%rdi),%rbx\n movq 8(%rdi),%rbp\n movq 16(%rdi),%r12\n movq 24(%rdi),%r13\n movq 32(%rdi),%r14\n movq 40(%rdi),%r15\n movq 48(%rdi),%rsp\n movq 56(%rdi),%rdx\n movq $1,%rax\n jmp *%rdx\n");
unsigned char *cp_file (char *path, long *size)
{
  FILE *f = fopen (path, "rb"); long n; unsigned char *p;
  if (!f) { fprintf (stderr, "cannot open %s\n", path); exit (2); }
  fseek (f, 0, SEEK_END); n = ftell (f); fseek (f, 0, SEEK_SET);
  p = malloc (n + 1); if (fread (p, 1, n, f) != (size_t) n) exit (2); fclose (f); p[n] = 0; *size = n; return p;
}
long cp_write (int fd, unsigned char *p, long n) { return write (fd, p, n); }
long cp_readlink (char *path, unsigned char *buf, long room) { return readlink (path, (char *) buf, room); }
void cp_exit (int s) { exit (s); }
/* sha256 */
static const uint32_t K[64] = {0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
#define R(x,n) (((x)>>(n))|((x)<<(32-(n))))
static void blk (uint32_t *h, const unsigned char *p)
{
  uint32_t w[64], a,b,c,d,e,f,g,hh; int i;
  for (i=0;i<16;i++) w[i]=(uint32_t)p[4*i]<<24|p[4*i+1]<<16|p[4*i+2]<<8|p[4*i+3];
  for (;i<64;i++) w[i]=w[i-16]+(R(w[i-15],7)^R(w[i-15],18)^(w[i-15]>>3))+w[i-7]+(R(w[i-2],17)^R(w[i-2],19)^(w[i-2]>>10));
  a=h[0];b=h[1];c=h[2];d=h[3];e=h[4];f=h[5];g=h[6];hh=h[7];
  for (i=0;i<64;i++){uint32_t t1=hh+(R(e,6)^R(e,11)^R(e,25))+((e&f)^(~e&g))+K[i]+w[i];uint32_t t2=(R(a,2)^R(a,13)^R(a,22))+((a&b)^(a&c)^(b&c));hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
  h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
}
static void sha (const unsigned char *p, long n, unsigned char *out)
{
  uint32_t h[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
  unsigned char b[128]; long i=0, r; uint64_t bits=(uint64_t)n*8;
  for (;i+64<=n;i+=64) blk(h,p+i);
  r=n-i; memcpy(b,p+i,r); b[r++]=0x80;
  if (r>56){memset(b+r,0,64-r);blk(h,b);r=0;}
  memset(b+r,0,56-r); for(i=0;i<8;i++) b[56+i]=bits>>(56-8*i); blk(h,b);
  for(i=0;i<8;i++){out[4*i]=h[i]>>24;out[4*i+1]=h[i]>>16;out[4*i+2]=h[i]>>8;out[4*i+3]=h[i];}
}
static void rehash (struct node *n)
{
  long i; unsigned char *buf = malloc (n->count * 32 + 32);
  for (i = 0; i < n->count; i++) { rehash (n->kids[i]); memcpy (buf + 32 * i, n->kids[i]->hash, 32); }
  sha (n->text, n->len, buf + 32 * n->count);
  sha (buf, 32 * n->count + 32, n->hash);
  free (buf);
}
static void emit (struct node *n)
{
  long i; unsigned char c;
  if (n->count > 255 || n->len > 255) { fprintf (stderr, "ff: node too big\n"); exit (1); }
  out_bytes (n->hash, 32); c = n->count; out_bytes (&c, 1);
  for (i = 0; i < n->count; i++) emit (n->kids[i]);
  c = n->len; out_bytes (&c, 1); out_bytes (n->text, n->len);
}
void cp_write_ff (struct node *root) { rehash (root); nd_emit (root); out_flush (); }
static struct node *rd (unsigned char **p, unsigned char *end)
{
  struct node *n = alloc (sizeof *n); long c, i;
  if (*p + 33 > end) { fprintf (stderr, "ff: truncated\n"); exit (1); }
  memcpy (n->hash, *p, 32); *p += 32; c = *(*p)++;
  for (i = 0; i < c; i++) nd_add (n, rd (p, end));
  n->len = *(*p)++; n->text = *p; *p += n->len;
  return n;
}
struct node *cp_read_ff (unsigned char *p, long n) { return rd (&p, p + n); }
int csema_main (int, char **);
long cp_setjmp (long *), cp_longjmp (long *);
int main (int argc, char **argv) { cp_jump[0] = (long) cp_setjmp; cp_jump[1] = (long) cp_longjmp; return csema_main (argc, argv); }
