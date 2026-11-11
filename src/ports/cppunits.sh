#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# cppunits.sh [--collect] "CPP" PREDEF ROOT REC OUT UNITS: the .i of each
# unit (UNITS: units.sh's list) by the C preprocessor in ff, from the
# command ffcc recorded (REC/u/unit.cmd: its folder, its arguments), run
# in the same folder as gcc's -E was, into OUT/unit.i; then compared with
# gcc's, REC/u/unit.i, byte for byte. Exit 1 if one differs or failed.
# --collect: cpp --collect (the questions it has no answer to, for make
# predef), nothing compared.
set -u
collect=
test "$1" = --collect && { collect=--collect; shift; }
cpp=$1 predef=$2 root=$3 rec=$4 out=$5 units=$6
same=0 differ=0 failed=0
for u in $(sed 's/^-O //' "$units"); do
    mkdir -p "$out/$(dirname "$u")"
    set -- ; first=1 skip=
    while IFS= read -r a; do
        if test -n "$first"; then cwd=$a; first=; continue; fi
        if test -n "$skip"; then skip=; continue; fi
        case $a in -o) skip=1 ;; -o*) ;; *) set -- "$@" "$a" ;; esac
    done < "$rec/u/$u.cmd"
    if ! (cd "$cwd" && $cpp $collect --predef="$predef" "$@" -o "$out/$u.i"); then
        failed=$((failed + 1)); echo "failed: $u"; continue
    fi
    test -n "$collect" && continue
    if cmp -s "$out/$u.i" "$rec/u/$u.i"; then same=$((same + 1))
    else differ=$((differ + 1)); echo "differ: $u"; diff "$rec/u/$u.i" "$out/$u.i" | head -10; fi
done
test -n "$collect" && exit 0
echo "cpp: $same units as gcc's .i, $differ differ, $failed failed"
test $differ = 0 && test $failed = 0
