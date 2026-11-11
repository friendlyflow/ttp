#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# tests.sh SRC OUT: bc's own tests, which bc has as files and no make check
# of (Test/: its functions' timing and checks, John Gilmore's signum;
# Examples/), each run by the build's bc (bc/bc, in the folder this runs in:
# port.mk's check, gcc's program or ttpc's) as `bc -l FILE` with no input,
# at most TIMEOUT seconds (300): its output and its exit status in
# OUT/NAME.out and OUT/NAME.status. bc's Test/timetest times them with
# another bc beside it; here only what they print counts, the two runs' of
# each file compared (results.sh). dc has no test of its own.
set -u
src=$1 out=$2
mkdir -p "$out"
for f in "$src"/Test/*.b "$src"/Test/BUG.bc "$src"/Test/signum "$src"/Examples/*.b; do
    n=$(basename "$(dirname "$f")")-$(basename "$f")
    s=0; timeout "${TIMEOUT:-300}" bc/bc -l "$f" < /dev/null > "$out/$n.out" 2>&1 || s=$?
    echo "$s" > "$out/$n.status"
    echo "$n: exit $s, $(wc -l < "$out/$n.out") lines"
done
