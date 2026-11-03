#!/bin/sh
# clpagecheck.sh — a whole page of the C layer written in ff (csema -l, many
# units at once) against gen/c2ff.pl's: FF/name.ff.txt, as the build made it,
# is its license, then c2ff.pl's page, then what follows (the asm page, the
# builtins); csema's page after the same license must be its beginning, byte
# for byte, and what follows must begin a page of its own.
#
#   sh clpagecheck.sh [-r RUN] -t TARGET [-v "UNITS"] -i I -s GLIBC_SRC [-g LIBGCC_SRC] -S shared.ff [-M GB] -l LICENSE -u UNITS -R ROOTS -f "FLAGS" CSEMA FF.ff.txt OUT
#
# UNITS and ROOTS are files, a unit (its path without .i) or a root to a line;
# -v: the units of I (of gcc's SSE4 intrinsics, CLANGVEC) csema reads through
# clang's copy, made here as CLANGFIX and CLANGVECPL say (src/glibc's).
# FLAGS: csema's -Z name, -W name, -k. -M GB: its heap in a file next to OUT
# (all of glibc does not fit in memory). OUT gets csema's page, OUT.err, and
# what differs is shown as a count; exit 1 if it differs or csema stopped.
#
# A host tool (POSIX sh).
set -u
run= tg=riscv64 vec= I= gsrc= lsrc= shared= lic= units= roots= flags= heap=
while :; do
    case "${1:-}" in
    -r) run=$2; shift 2 ;;
    -t) tg=$2; shift 2 ;;
    -v) vec=$2; shift 2 ;;
    -i) I=$2; shift 2 ;;
    -s) gsrc=$2; shift 2 ;;
    -g) lsrc=$2; shift 2 ;;
    -S) shared=$2; shift 2 ;;
    -M) heap=$2; shift 2 ;;
    -l) lic=$2; shift 2 ;;
    -u) units=$2; shift 2 ;;
    -R) roots=$2; shift 2 ;;
    -f) flags=$2; shift 2 ;;
    *) break ;;
    esac
done
cs=$1 ff=$2 out=$3
d=$(dirname "$out")
mkdir -p "$d"
: > "$out.read"
while read -r u; do
    r=$u.i
    case " $vec " in
    *" ${u#"$I"/} "*)
        b=$d/$(printf '%s' "${u#"$I"/}" | tr / _).clang.i
        eval "${CLANGFIX:-cat}" '"$u.i"' | perl "$CLANGVECPL" > "$b"
        r=$b=$u.i ;;
    esac
    printf '%s\n' "$r" >> "$out.read"
done < "$units"
h=
test -n "$heap" && h="-M $out.heap $heap"
s=0
# shellcheck disable=SC2086
$run $cs -l -t "$tg" -s "$gsrc" ${lsrc:+-g "$lsrc"} -S "$shared" $h $flags "@$out.read" -- "@$roots" > "$out" 2> "$out.err" || s=$?
n=$(basename "$ff" .ff.txt)
if test "$s" != 0; then echo "clpage $n ($tg): csema stopped ($s): $(tail -n 1 "$out.err" | head -c 200)"; exit 1; fi
a=$(wc -c < "$lic") b=$(wc -c < "$out")
# (what follows c2ff.pl's page: nothing, or a page's first line, not indented)
if { cat "$lic" "$out"; } | cmp -s -n $((a + b)) - "$ff" && { c=$(tail -c +$((a + b + 1)) "$ff" | head -c 1); test -z "$c" || test "$c" != " "; }; then
    echo "clpage $n ($tg): the same, $(wc -l < "$out") lines, $(wc -l < "$units") units, $(grep -c 'left out' "$out.err") left out"
    rm -f "$out.read"
else
    echo "clpage $n ($tg): NOT the same: $( { cat "$lic" "$out"; } | cmp - "$ff" | head -c 200)"
    exit 1
fi
