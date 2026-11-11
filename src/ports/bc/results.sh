#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# results.sh DIR: each test of a run of tests.sh (DIR/out: its OUT) as "NAME
# exit=STATUS output=SHA256", for ../checktable.sh: the two runs' of a test
# are equal where bc exited alike and printed the same bytes.
set -u
for s in "$1"/out/*.status; do
    test -e "$s" || continue
    n=$(basename "$s" .status)
    echo "$n exit=$(cat "$s") output=$(sha256sum < "$1/out/$n.out" | cut -c1-16)"
done
