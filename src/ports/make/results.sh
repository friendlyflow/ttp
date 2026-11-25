#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# results.sh DIR: each test of a run of make's tests (DIR: port.mk's check
# folder) as "NAME RESULT", for ../checktable.sh: run_make_tests.pl's log
# (test-suite.log) has a line "CATEGORY ...... STATUS" for each (ok (N
# passed), FAILED (P/N passed), N/A): PASS, FAIL:P/N, SKIP.
set -u
f=$1/test-suite.log
test -e "$f" || { echo "test-suite.log ERROR"; exit 0; }
sed -n -E 's#^([A-Za-z0-9_/.-]+) \.+ (ok|FAILED|N/A)( +\(([0-9/]+) passed\)| +\(no tests found!\))?$#\1 \2 \4#p' "$f" |
    sed -E 's/ ok [0-9]*$/ PASS/; s/ N\/A $/ SKIP/; s/ FAILED ([0-9]+\/[0-9]+)$/ FAIL:\1/; s/ FAILED $/ FAIL/'
