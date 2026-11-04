/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cparse.c: dev source of tools/cparse.ff */
#include "c.h"
int cparse_main (int argc, char **argv)
{
  long size = 0;
  unsigned char *src;
  struct node *root;
  int print = 0, a = 1;
  if (argc > 1 && same ((unsigned char *) argv[1], 2, "-p")) { print = 1; a = 2; }
  if (argc != a + 1) { err_str ("usage: cparse [-p] file.i\n"); cp_exit (2); }
  src = cp_file (argv[a], &size);
  root = c_parse (src, size, argv[a]);
  if (print) { c_print (root); out_flush (); return 0; }
  nd_layer (root);
  cp_write_ff (root);
  return 0;
}
