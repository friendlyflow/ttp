/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* The user and group databases through nss in a static program (the
   machine's /etc/passwd and /etc/group, nss's files): getpwnam, getpwuid,
   getgrgid of root, as coreutils' id, ls -l and stat ask them. nss finds a
   database by its name and a module's function by its name, from tables of
   texts (nss_database_name_array "passwd", nss_function_name_array
   "getpwnam_r"), and a database's default from per_database_defaults, an
   array of bytes of enum constants: ttpc took those texts for the names of
   the functions and globals of the same names (textname.pl), and csema
   writes those constants as numbers. */
#include <grp.h>
#include <pwd.h>
#include <stdio.h>

int
main (void)
{
  struct passwd *p = getpwnam ("root");
  struct passwd *u = getpwuid (0);
  struct group *g = getgrgid (0);
  int bad = 0;
  if (p) printf ("getpwnam root: uid %d gid %d dir %s\n", (int) p->pw_uid, (int) p->pw_gid, p->pw_dir);
  else { printf ("getpwnam root: none\n"); bad = 1; }
  if (u) printf ("getpwuid 0: %s\n", u->pw_name);
  else { printf ("getpwuid 0: none\n"); bad = 1; }
  if (g) printf ("getgrgid 0: %s\n", g->gr_name);
  else { printf ("getgrgid 0: none\n"); bad = 1; }
  return bad;
}
