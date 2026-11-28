/* innerenum, unit c: the struct name again, defined otherwise (its own, named
   with the unit), its field's enum of a constant of unit a's value and one of
   its own only (liblzma's stream_decoder_mt.c: SEQ_ERROR, ttpc unknown name).
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
typedef struct {
  char tag;
  enum { SEQ_HEADER, SEQ_C_ONLY = 9 } sequence;
} coder;
int c_run (void)
{
  coder c = { 'c', SEQ_HEADER };
  int s = c.sequence;
  c.sequence = SEQ_C_ONLY;
  return s * 10 + c.sequence;
}
