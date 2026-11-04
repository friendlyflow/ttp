#!/bin/sh
# csemacheck.sh — the check of the types and semantics of C in ff (tools/csema,
# its library tools/csem.ff) against clang: each unit, a .i that gcc
# preprocessed, read by clang (its JSON AST and its record layouts, made
# into lines by gen/clangsema.pl) and by csema -d; gen/csemacmp.pl compares
# them: every declaration's and expression's canonical type, value category,
# cast kind and folded constant, line for line, and every record layout
# clang made. With -w REF, csema's lines must also be REF's (another
# target's build of csema: they agree).
#
#   sh csemacheck.sh [-j N] [-r RUN] [-t TARGET] [-w REFDIR] CSEMA DIR unit.i ...
#
# (a unit @file: the units in that file, one to a line.)
# CLANG (the environment) is the clang command up to the unit, its target
# TARGET's (riscv64 by default):
#   $C2FF_CLANG -x c -include clang-prelude.h -Xclang -ast-dump=json
#   -Xclang -fdump-record-layouts -fsyntax-only --target=... -std=gnu11 -fgnu89-inline -w
# (-std=gnu23 for a unit gnu11 does not take). CLANGFIX (the environment, if
# set) is the sed command that makes a unit clang's copy, as src/glibc's .json
# rules do (x86_64's "%v" in asm, gcc's f128 suffix, _FloatN in a _Generic);
# CLANGVEC the units (dir/name) of gcc's intrinsics headers, whose copy goes
# through CLANGVECPL (clangvec.pl) too and which clang reads with -msse4.2;
# csema reads what clang reads. RUN runs csema (qemu-riscv64
# for riscv64's elsewhere); N units at once (4). DIR gets each unit's lines
# (name.csema, name.clang) and the comparison (name.cmp), kept where it
# fails: a line CLANG (clangsema.pl stopped), CSEMA (csema stopped), DIFF
# (csemacmp's first lines) or REF names it. A unit clang itself does not
# take (the host's headers for another target) is left out: SKIP. At the end
# a count; exit 1 if any failed.
#
# A host tool (POSIX sh, Perl).
set -u
G=$(dirname "$0")
if test "${1:-}" = --one; then
    shift
    run=$1 ref=$2 tg=$3 cs=$4 d=$5 u=$6
    b=$(printf '%s' "$u" | sed 's|^.*/i/||; s|^.*/ff/||; s|^/*||; s|/|_|g; s|\.i$||')
    # clang's copy of the unit, where it needs one
    su=$u cl=$CLANG vec=
    for v in ${CLANGVEC:-}; do case "$u" in */i/"$v".i) vec=1; cl="$CLANG -msse4.2" ;; esac; done
    if test -n "${CLANGFIX:-}$vec"; then
        su=$d/$b.clang.i
        if test -n "$vec"; then eval "${CLANGFIX:-cat}" '"$u"' | perl "$CLANGVECPL" > "$su"; else eval "$CLANGFIX" '"$u"' > "$su"; fi
    fi
    $cl "$su" > "$d/$b.out" 2> "$d/$b.err" || $(printf '%s' "$cl" | sed 's/-std=gnu11/-std=gnu23/') "$su" > "$d/$b.out" 2> "$d/$b.err" \
        || { echo "SKIP $u: $(grep -m1 error "$d/$b.err" | head -c 300)"; rm -f "$d/$b.out"; exit 0; }
    perl "$G/clangsema.pl" < "$d/$b.out" > "$d/$b.clang" 2>> "$d/$b.err" || { echo "CLANG $u: clangsema.pl: $(head -c 300 "$d/$b.err")"; rm -f "$d/$b.out"; exit 0; }
    rm -f "$d/$b.out"
    $run $cs -d -t "$tg" "$su" > "$d/$b.csema" 2>> "$d/$b.err" || { echo "CSEMA $u: $(tail -c 300 "$d/$b.err")"; exit 0; }
    if test -n "$ref"; then
        cmp -s "$d/$b.csema" "$ref/$b.csema" || { echo "REF $u: not $ref's lines"; exit 0; }
    fi
    if perl "$G/csemacmp.pl" "$d/$b.csema" "$d/$b.clang" > "$d/$b.cmp"; then
        echo "OK $u"
        test -n "${KEEP:-}" || rm -f "$d/$b.clang" "$d/$b.cmp" "$d/$b.err" "$d/$b.clang.i"
        test -n "${KEEP:-}" || test -n "$ref" || rm -f "$d/$b.csema"
    else echo "DIFF $u: $(head -1 "$d/$b.cmp")"; fi
    exit 0
fi
jobs=4 run= ref= tg=riscv64
while :; do
    case "${1:-}" in
    -j) jobs=$2; shift 2 ;;
    -r) run=$2; shift 2 ;;
    -t) tg=$2; shift 2 ;;
    -w) ref=$2; shift 2 ;;
    *) break ;;
    esac
done
test $# -ge 3 || { echo "usage: csemacheck.sh [-j N] [-r RUN] [-t TARGET] [-w REFDIR] CSEMA DIR unit.i ..." >&2; exit 2; }
cs=$1 d=$2
shift 2
test -n "${CLANG:-}" || { echo "csemacheck: CLANG is not set (the clang command up to the unit)" >&2; exit 2; }
export CLANG
mkdir -p "$d"
for u in "$@"; do case "$u" in @*) cat "${u#@}" ;; *) echo "$u" ;; esac; done | xargs -P "$jobs" -n 1 sh "$0" --one "$run" "$ref" "$tg" "$cs" "$d" > "$d/result"
n=$(grep -c '^OK' "$d/result")
s=$(grep -c '^SKIP' "$d/result")
f=$(grep -vc '^OK\|^SKIP' "$d/result")
grep -v '^OK' "$d/result"
echo "csemacheck: $n units agree with clang ($tg), $f do not, $s that clang did not take left out"
test "$f" -eq 0
