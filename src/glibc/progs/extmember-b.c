/* extmember, an archive member: the external and a function that sets it.
   Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
   software under the GNU General Public License, version 3; no warranty.  */
int exit_status = 0;
void set_fail (void) { exit_status = 1; }
