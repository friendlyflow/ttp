/* innerenum, unit b: the same struct name and constant names, of other
   values (liblzma's stream_encoder.c against stream_decoder.c), and main.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
typedef struct {
  long pad;
  enum { SEQ_INDEX = 7, SEQ_HEADER, SEQ_FOOTER = 20, SEQ_BLOCK } sequence;
} coder;
extern int a_run (void);
static int b_run (void)
{
  coder c = { 0, SEQ_HEADER };
  int s = c.sequence;
  c.sequence = SEQ_BLOCK;
  s = s * 100 + c.sequence;
  c.sequence = SEQ_INDEX;
  return s * 100 + c.sequence + SEQ_FOOTER;
}
int main (void)
{
  printf ("a: %d\nb: %d\n", a_run (), b_run ());
  printf ("sizes: %zu\n", sizeof (coder));
  return 0;
}
