/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cprint.c: dev source of tools/cprint.ff */
#include "c.h"
int cprint_main (int argc, char **argv)
{
  long size = 0;
  unsigned char *src;
  struct node *root;
  if (argc != 2) { err_str ("usage: cprint file.ff\n"); cp_exit (2); }
  src = cp_file (argv[1], &size);
  root = cp_read_ff (src, size);
  nd_flat (root);
  c_print (root);
  out_flush ();
  return 0;
}
