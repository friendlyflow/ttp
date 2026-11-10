#!/usr/bin/env bash
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# cppcheck.sh: the C preprocessor in ff (src/compiler/tools/cpp.ff) against
# gcc -E, unit by unit, byte for byte: each unit's .i made by cpp from the
# command of the reference build (mki.pl --cpp, PREDEF its predefined
# macros) against gcc's .i, REF/x.i (made by mki.pl), or with -g gcc's made
# here and now (the cross-check over all of glibc: nothing kept but the
# list). OUT/result: same, differ or fail for each unit; OUT/d/x.diff the
# first lines of each difference. Exit 1 if one differs or failed.
#
#   bash cppcheck.sh [-g] [-j N] [-l LOG]... [-k MKI] TOOL PREDEF OBJ SRC OUT REF UNITS...
#
# TOOL may be a command with its runner (qemu-riscv64 cpp). Units are named
# as their objects without .o (string/strlen); -l LOG takes the commands
# from LOG instead of build.log (mki.pl --log: glibc's tests). -k MKI: its
# mki.pl (libgcc's: ../libgcc/mki.pl, OBJ its build dir, SRC its out dir).
set -eu
gcc= jobs=1 logs= mki=
while :; do
    case "${1:-}" in
    -k) mki=$(readlink -f "$2"); shift 2 ;;
    -g) gcc=1; shift ;;
    -j) jobs=$2; shift 2 ;;
    -l) logs="$logs --log $2"; shift 2 ;;
    *) break ;;
    esac
done
tool=$1 predef=$(readlink -f "$2") obj=$3 src=$4 out=$5 ref=$6
shift 6
test -n "$mki" || mki=$(cd "$(dirname "$0")" && pwd)/mki.pl
case "$out" in /*) ;; *) out=$PWD/$out ;; esac
rm -rf "$out"
mkdir -p "$out/chunks"
for u in "$@"; do echo "$u.o"; done | split -l 40 - "$out/chunks/c"
export gcc tool predef obj src out ref mki logs
work() {
    b=$(basename "$1")
    if test -n "$gcc"; then perl "$mki" $logs --out "$out/g.$b" "$obj" "$src" $(cat "$1") > /dev/null 2> "$out/g.$b.err" || true; r=$out/g.$b; else r=$ref; fi
    perl "$mki" $logs --cpp "$tool" --predef "$predef" --out "$out/c.$b" "$obj" "$src" $(cat "$1") > /dev/null 2> "$out/c.$b.err" || true
    for o in $(cat "$1"); do
        i=${o%.o}.i
        if ! test -s "$r/$i"; then echo "noref $i"
        elif ! test -s "$out/c.$b/$i"; then echo "fail $i"
        elif cmp -s "$r/$i" "$out/c.$b/$i"; then echo "same $i"
        else echo "differ $i"; mkdir -p "$out/d/$(dirname "$i")"; diff "$r/$i" "$out/c.$b/$i" | head -40 > "$out/d/$i.diff" || true; fi
    done
    rm -rf "$out/c.$b" "$out/g.$b"
}
export -f work 2> /dev/null || true
ls "$out/chunks"/* | xargs -P "$jobs" -I{} bash -c 'work {}' > "$out/result"
same=$(grep -c '^same' "$out/result" || true)
differ=$(grep -c '^differ' "$out/result" || true)
fail=$(grep -c '^fail' "$out/result" || true)
noref=$(grep -c '^noref' "$out/result" || true)
echo "cppcheck: $same same, $differ differ, $fail failed, $noref without gcc's .i, of $#"
test "$differ" = 0 && test "$fail" = 0
