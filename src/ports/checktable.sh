#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# checktable.sh GCC FF [RESULTS]: a package's test suite run twice (port.mk's
# check), with gcc's program (GCC: that run's files of results) and with
# ttpc's (FF), test by test: a line of counts, then each test, "equal RESULT"
# or "differ GCCRESULT FFRESULT" (automake's results: PASS, FAIL, SKIP, XFAIL,
# XPASS, ERROR), or "missing" where one run has no result.
# RESULTS: a script of the package's (sh RESULTS DIR) that prints each test
# of a run as "NAME RESULT", for a test suite that is not automake's; by
# default each .trs file's :test-result: lines. Each run's list is kept
# beside it (GCC.results, FF.results).
set -u
g=$1 f=$2 res=${3:-}
results () { # DIR: "name result..." a line, sorted by name
    if test -n "$res"; then
        sh "$res" "$1" | sort | awk '{ n = $1; $1 = ""; r[n] = r[n] $0 } END { for (n in r) print n r[n] }' | sort
    else (cd "$1" && find . -name '*.trs' | sort | while read -r t; do
        n=${t#./}; n=${n%.trs}
        echo "$n $(sed -n 's/^:test-result: //p' "$t" | sort | tr '\n' ' ' | sed 's/ $//')"
    done); fi
}
results "$g" > "$g.results"
results "$f" > "$f.results"
out=$(awk 'NR == FNR { n = $1; $1 = ""; sub(/^ /, ""); ff[n] = $0; next }
    { n = $1; $1 = ""; sub(/^ /, ""); rf = ff[n]
      if (rf == "") print n " missing " $0
      else if (rf == $0) print n " equal " $0
      else print n " differ " $0 " " rf }' "$f.results" "$g.results")
eq=$(echo "$out" | grep -c ' equal ')
df=$(echo "$out" | grep -c ' differ ')
ms=$(echo "$out" | grep -c ' missing ')
pg=$(echo "$out" | grep -c ' equal PASS$')
sk=$(echo "$out" | grep -c ' equal SKIP$')
echo "tests: $(echo "$out" | grep -c .), equal $eq (PASS $pg, SKIP $sk), differ $df, missing $ms"
echo "$out"
