#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# checktable.sh GCC FF: a package's test suite run twice (port.mk's check),
# with gcc's program (GCC: that run's .trs and .log files) and with ttpc's
# (FF), test by test: a line of counts, then each test, "equal RESULT" or
# "differ GCCRESULT FFRESULT" (automake's results: PASS, FAIL, SKIP, XFAIL,
# XPASS, ERROR), or "missing" where one run has no result.
set -u
g=$1 f=$2
eq=0 df=0 ms=0
out=$(cd "$g" && find . -name '*.trs' | sort | while read -r t; do
    n=${t#./}; n=${n%.trs}
    rg=$(sed -n 's/^:test-result: //p' "$g/$t" | sort | tr '\n' ' ' | sed 's/ $//')
    if test -e "$f/$t"; then rf=$(sed -n 's/^:test-result: //p' "$f/$t" | sort | tr '\n' ' ' | sed 's/ $//'); else rf=; fi
    if test -z "$rf"; then echo "$n missing $rg"
    elif test "$rg" = "$rf"; then echo "$n equal $rg"
    else echo "$n differ $rg $rf"; fi
done)
eq=$(echo "$out" | grep -c ' equal ')
df=$(echo "$out" | grep -c ' differ ')
ms=$(echo "$out" | grep -c ' missing ')
pg=$(echo "$out" | grep -c ' equal PASS$')
sk=$(echo "$out" | grep -c ' equal SKIP$')
echo "tests: $(echo "$out" | grep -c .), equal $eq (PASS $pg, SKIP $sk), differ $df, missing $ms"
echo "$out"
