#!/bin/sh
# cltests.sh — the C layer written in ff (csema -l --program) against
# gen/c2ff.pl on every test program of glibc that a tests build has, byte for byte:
# the test's objects (-O, --object), libsupport's, from main, including glibc in
# ff. src/glibc's clayer-tests; it costs a c2ff.pl and a csema of each test
# (5 to 30 s a test; 45 minutes for 508 at -j3), so not a ports-check step.
#
#   sh cltests.sh [-r RUN] [-j N] -t TARGET -s GLIBC_SRC [-g LIBGCC_SRC] -S shared.ff -T TBUILD -x INDEX [-J STATICS] [-I] [-a "AREAS"] CSEMA OUT
#
# TBUILD: the tests build (its AREA.mk, its i/). INDEX, STATICS: glibc in ff's.
# -I: the program has a _start of its own (c2ff's --start, csema's -T). Each
# test's what differs stays in OUT; OUT/result has a line for each: OK, DIFF
# (the lines that differ), STOP (csema's message), NOREF (c2ff.pl's). The
# passes are what make's rule left: run this after make has made them, or a
# stale pass shows as a difference. Exit 1 if any is not OK.
#
# A host tool (POSIX sh).
set -u
if test "${1:-}" = --one; then
    shift
    env_o=$1 x=$2 area=${x%%/*} t=${x##*/}
    # shellcheck disable=SC1090
    . "$env_o/env"
    M=$TB/$area.mk
    objs=$(grep "^TOBJS_$t :=" "$M" | sed 's/^[^=]*= //')
    sup=$(grep '^SUPPORT :=' "$M" | sed 's/^SUPPORT := //')
    args= jargs=
    for o in $objs; do args="$args -O $TB/i/$o.i"; jargs="$jargs --object $TB/i/$o.json=$TB/i/$o.i"; done
    for o in $sup; do args="$args $TB/i/$o.i"; jargs="$jargs $TB/i/$o.json=$TB/i/$o.i"; done
    ref=$env_o/$t.ref
    # shellcheck disable=SC2086
    if ! timeout 300 perl "$GEN/c2ff.pl" --target "$TG" --program glibc --index "$IDX" ${ST:+--statics "$ST"} ${OWNSTART:+--start} $jargs -- main > "$ref" 2> "$env_o/$t.referr"; then
        echo "NOREF $x $(tail -n 1 "$env_o/$t.referr" | cut -c1-160)"
        exit 0
    fi
    # shellcheck disable=SC2086
    if ! timeout 120 $RUN "$CS" -l -t "$TG" -s "$GS" ${LS:+-g "$LS"} -S "$SH" -P glibc -I "$IDX" ${ST:+-J "$ST"} ${OWNSTART:+-T} $args -- main > "$env_o/$t.ff.txt" 2> "$env_o/$t.err"; then
        echo "STOP $x $(tail -n 1 "$env_o/$t.err" | cut -c1-160)"
    elif cmp -s "$env_o/$t.ff.txt" "$ref"; then
        echo "OK $x"
        rm -f "$env_o/$t.ff.txt" "$env_o/$t.err" "$ref" "$env_o/$t.referr"
    else
        echo "DIFF $x $(diff "$env_o/$t.ff.txt" "$ref" | grep -c '^[<>]')"
    fi
    exit 0
fi
RUN= J=3 TG=riscv64 GS= LS= SH= TB= IDX= ST= OWNSTART= areas="stdlib string stdio-common"
while :; do
    case "${1:-}" in
    -r) RUN=$2; shift 2 ;;
    -j) J=$2; shift 2 ;;
    -t) TG=$2; shift 2 ;;
    -s) GS=$2; shift 2 ;;
    -g) LS=$2; shift 2 ;;
    -S) SH=$2; shift 2 ;;
    -T) TB=$2; shift 2 ;;
    -x) IDX=$2; shift 2 ;;
    -J) ST=$2; shift 2 ;;
    -I) OWNSTART=1; shift ;;
    -a) areas=$2; shift 2 ;;
    *) break ;;
    esac
done
CS=$1 O=$2
GEN=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$O"
{
    for v in RUN TG GS LS SH TB IDX ST OWNSTART CS GEN; do
        eval "val=\$$v"
        printf "%s='%s'\n" "$v" "$val"
    done
} > "$O/env"
: > "$O/result"
for area in $areas; do
    for t in $(grep '^TESTS :=' "$TB/$area.mk" | sed 's/^TESTS := //'); do echo "$area/$t"; done
done | xargs -P "$J" -n 1 sh "$0" --one "$O" >> "$O/result"
echo "clayer-tests ($TG): $(grep -c '^OK' "$O/result") the same, $(grep -c '^DIFF' "$O/result") differ, $(grep -c '^STOP' "$O/result") csema stopped, $(grep -c '^NOREF' "$O/result") c2ff.pl stopped, of $(wc -l < "$O/result"): $O/result"
! grep -qv '^OK' "$O/result"
