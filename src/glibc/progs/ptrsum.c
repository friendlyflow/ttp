/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* A global's item that is an address plus or minus numbers, more than one,
   as coreutils cat.c's line_num_print = line_buf + LINE_COUNTER_BUF_LEN - 8,
   or a number and an address, numfmt.c's 1 + zero_and_valid_suffixes: ttpc's
   gval folds an address and one number after it and stopped on the others
   (an address ttpc cannot work out); csema writes the address and their sum. */
#include <stdio.h>

#define LEN 20
static char line_buf[LEN] = "abcdefghijklmnopqrs";
static char *print = line_buf + LEN - 8;
static char *start = line_buf + LEN - 3;
static int arr[10] = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90 };
static int *mid = arr + 7 - 2 + 1;
static int *one = arr + 1;
static char const zero_suf[] = "0KkMG";
static char const *suf = 1 + zero_suf;

int
main (void)
{
  printf ("%s %s %d %d %s\n", print, start, *mid, *one, suf);
  return 0;
}
