#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# results.sh DIR: each test of a run of tar's tests (DIR: port.mk's check
# folder) as "NAME RESULT", for ../checktable.sh: autotest's testsuite.log
# has a line "N. TITLE (FILE.at:LINE): RESULT" for each test (ok, skipped
# (...), FAILED (...), expected failure (...), UNEXPECTED PASS); the name
# is N:FILE, the result in automake's words (PASS, SKIP, FAIL, XFAIL, XPASS).
set -u
f=$1/tests/testsuite.log
test -e "$f" || { echo "testsuite.log ERROR"; exit 0; }
sed -n -E 's/^([0-9]+)\. .* \(([^ ():]+)\.at:[0-9]+\): (ok|skipped|FAILED|expected failure|UNEXPECTED PASS)( .*)?$/\1:\2 \3/p' "$f" | sort -u |
    sed 's/ ok$/ PASS/; s/ skipped$/ SKIP/; s/ FAILED$/ FAIL/; s/ expected failure$/ XFAIL/; s/ UNEXPECTED PASS$/ XPASS/'
