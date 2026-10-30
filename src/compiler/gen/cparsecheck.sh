#!/bin/sh
# cparsecheck.sh — the check of the C parser in ff (tools/cparse and
# tools/cprint, their library tools/c.ff): each unit, a .i that gcc
# preprocessed, parsed by cparse into its ff tree, the tree written back as
# C by cprint (each operator's operation in parentheses), and the .i and that
# C compiled by gcc alike (CFLAGS): the same bytes in every section, the
# same relocations and the same symbols, or the tree was wrong. With -w
# REF, the tree and the C must also be REF's bytes (another target's build
# of the tools: they agree).
#
#   sh cparsecheck.sh [-j N] [-r RUN] [-w REFDIR] CPARSE CPRINT CC DIR unit.i ...
#
# RUN runs the tools (qemu-riscv64 for riscv64's elsewhere); N units at once
# (4). DIR gets each unit's tree (name.ff) and C (name.c), kept where it
# fails: a line PARSE, PRINT, GCC (gcc took the .i but not the C), DIFF
# (other code; DIR/name.a.dump and .b.dump) or REF names it. At the end a
# count; exit 1 if any failed. A unit gcc itself does not take is left out
# (counted).
#
# A host tool (POSIX sh and binutils).
set -u
CFLAGS=${CFLAGS:--std=gnu11 -fgnu89-inline -O2 -fkeep-inline-functions -fkeep-static-functions -w -c -x cpp-output}
if test "${1:-}" = --one; then
    shift
    run=$1 ref=$2 p=$3 q=$4 cc=$5 d=$6 u=$7
    b=$(printf '%s' "$u" | sed 's|^.*/i/||; s|^.*/ff/||; s|^/*||; s|/|_|g; s|\.i$||')
    $run $p "$u" > "$d/$b.ff" 2> "$d/$b.err" || { echo "PARSE $u: $(head -c 300 "$d/$b.err")"; exit 0; }
    $run $q "$d/$b.ff" > "$d/$b.c" 2>> "$d/$b.err" || { echo "PRINT $u: $(head -c 300 "$d/$b.err")"; exit 0; }
    if test -n "$ref"; then
        cmp -s "$d/$b.ff" "$ref/$b.ff" && cmp -s "$d/$b.c" "$ref/$b.c" || { echo "REF $u: not $ref's tree or C"; exit 0; }
    fi
    $cc $CFLAGS "$u" -o "$d/$b.a.o" 2> /dev/null || { echo "SKIP $u"; rm -f "$d/$b.a.o"; exit 0; }
    $cc $CFLAGS "$d/$b.c" -o "$d/$b.b.o" 2> "$d/$b.gcc" || { echo "GCC $u: $(grep -m1 error "$d/$b.gcc" | head -c 300)"; exit 0; }
    dump() {
        for s in $(readelf -SW "$1" | sed -n 's/^ *\[ *[0-9]*\] \([^ ]*\) .*/\1/p' | grep -v '^\.rela\|^\.comment$\|^\.symtab$\|^\.strtab$\|^\.shstrtab$'); do
            echo "== $s"; objdump -s -j "$s" "$1" 2> /dev/null | tail -n +5
        done
        readelf -rW "$1" | tail -n +2 | sed 's/ at offset 0x[0-9a-f]*//'
        nm "$1"
    }
    dump "$d/$b.a.o" > "$d/$b.a.dump"
    dump "$d/$b.b.o" > "$d/$b.b.dump"
    if cmp -s "$d/$b.a.dump" "$d/$b.b.dump"; then
        echo "OK $u"
        rm -f "$d/$b.a.o" "$d/$b.b.o" "$d/$b.a.dump" "$d/$b.b.dump" "$d/$b.err" "$d/$b.gcc"
    else echo "DIFF $u: $d/$b.a.dump $d/$b.b.dump"; fi
    exit 0
fi
jobs=4 run= ref=
while :; do
    case "${1:-}" in
    -j) jobs=$2; shift 2 ;;
    -r) run=$2; shift 2 ;;
    -w) ref=$2; shift 2 ;;
    *) break ;;
    esac
done
test $# -ge 5 || { echo "usage: cparsecheck.sh [-j N] [-r RUN] [-w REFDIR] CPARSE CPRINT CC DIR unit.i ..." >&2; exit 2; }
p=$1 q=$2 cc=$3 d=$4
shift 4
mkdir -p "$d"
for u in "$@"; do echo "$u"; done | xargs -P "$jobs" -n 1 sh "$0" --one "$run" "$ref" "$p" "$q" "$cc" "$d" > "$d/result"
n=$(grep -c '^OK' "$d/result")
s=$(grep -c '^SKIP' "$d/result")
f=$(grep -vc '^OK\|^SKIP' "$d/result")
grep -v '^OK\|^SKIP' "$d/result"
echo "cparsecheck: $n units parsed, printed and compiled by gcc to the same code, $f failed, $s that gcc did not take left out"
test "$f" -eq 0
