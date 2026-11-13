#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# results.sh DIR: each test of a run of findutils' tests (DIR: port.mk's
# check folder) as "NAME RESULT", for ../checktable.sh: automake's (each
# .trs file's :test-result:) and DejaGnu's (each .sum file's PASS:, FAIL:,
# UNRESOLVED:, ... lines, a test named by its suite and its line).
set -u
cd "$1" || exit 1
find . -name '*.trs' | sort | while read -r t; do
    n=${t#./}; n=${n%.trs}
    sed -n "s|^:test-result: |$n |p" "$t"
done
find . -name '*.sum' | sort | while read -r s; do
    d=${s#./}; d=${d%/*}
    sed -n -E "s#^(PASS|FAIL|XPASS|XFAIL|UNRESOLVED|UNTESTED|UNSUPPORTED|KFAIL|KPASS): (.*)\$#$d:\2 \1#p" "$s" | tr ' ' '_' | sed 's/_\([A-Z]*\)$/ \1/'
done
