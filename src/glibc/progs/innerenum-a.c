/* innerenum, unit a: a struct type of this unit with an anonymous enum in a
   field (liblzma's stream coders: enum { SEQ_STREAM_HEADER, ... } sequence;),
   its constants of the same names as unit b's of other values, and one of
   its own (SEQ_ERROR, decoder_mt's): csema names this unit's with it.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
typedef struct {
  enum { SEQ_HEADER, SEQ_BLOCK, SEQ_INDEX, SEQ_FOOTER, SEQ_ERROR } sequence;
  int n;
} coder;
static int step (coder *c)
{
  switch (c->sequence)
    {
    case SEQ_HEADER: c->sequence = SEQ_BLOCK; break;
    case SEQ_BLOCK: c->sequence = SEQ_INDEX; break;
    case SEQ_INDEX: c->sequence = SEQ_FOOTER; break;
    case SEQ_FOOTER: c->sequence = SEQ_ERROR; break;
    default: break;
    }
  return c->sequence;
}
int a_run (void)
{
  coder c = { SEQ_HEADER, 0 };
  int s = 0;
  while (c.sequence != SEQ_ERROR) s = s * 10 + step (&c);
  return s * 10 + (int) SEQ_FOOTER;
}
