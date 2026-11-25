#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# results.sh DIR: each test of a run of gzip's tests (DIR: port.mk's check
# folder) as "NAME RESULT", for ../checktable.sh: automake's (each .trs
# file's :test-result:) and the top's check-local (PASS where it exited 0).
set -u
cd "$1" || exit 1
find . -name '*.trs' | sort | while read -r t; do
    n=${t#./}; n=${n%.trs}
    sed -n "s|^:test-result: |$n |p" "$t"
done
if test -e check-local.status; then
    test "$(cat check-local.status)" = 0 && echo "check-local PASS" || echo "check-local FAIL"
else echo "check-local ERROR"; fi
