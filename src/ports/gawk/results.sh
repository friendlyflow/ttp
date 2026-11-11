#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# results.sh DIR: each test of a run of gawk's test suite (DIR: port.mk's
# check folder, make.log and the test/_NAME files it left) as "NAME PASS"
# or "NAME FAIL", for ../checktable.sh: each test's rule says its name on a
# line of its own, and a test that failed leaves _NAME (its output) behind.
set -u
names=$(sed -n '/^======== Starting basic tests/,$p' "$1/make.log" | grep -E '^[A-Za-z0-9_+-]+$' | sort -u)
for n in $names; do
    if test -e "$1/test/_$n"; then echo "$n FAIL"; else echo "$n PASS"; fi
done
