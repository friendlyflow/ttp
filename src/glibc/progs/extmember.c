/* extmember, the program's unit: an external of one name in two archive
   members of the same text (coreutils' expand-common.c in expand's and
   unexpand's archives: int exit_status, a name all of glibc in ff has too),
   which the program reads: one, the first member's, as gcc's link takes it.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
#include <stdio.h>
extern int exit_status;
extern void set_fail (void);
int main (void) { set_fail (); printf ("%d\n", exit_status); return 0; }
