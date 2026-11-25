#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# rttable.sh RESULTS: a package's round trip (port.mk's PKG_ROUNDTRIP: lines
# "NAME PASS" or "NAME FAIL:what") as a table in checktable.sh's form: a
# line of counts, then each test, "equal PASS" where gcc's program and
# ttpc's agree, "differ FAIL:what" where not (what: the steps that did not:
# bytes, the two made different bytes; exit, their exit statuses differ;
# ffreads, ttpc's did not read gcc's back to the input; gccreads, the other
# way; ...).
set -u
out=$(awk '{ if ($2 == "PASS") print $1 " equal PASS"; else print $1 " differ " $2 }' "$1")
n=$(echo "$out" | grep -c .)
eq=$(echo "$out" | grep -c ' equal ')
df=$(echo "$out" | grep -c ' differ ')
echo "roundtrip: $n, equal $eq (PASS $eq, SKIP 0), differ $df, missing 0"
echo "$out"
