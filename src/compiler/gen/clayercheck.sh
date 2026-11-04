#!/bin/sh
# clayercheck.sh — the check of the C layer written in ff (csema -l, tools/csem.ff)
# against gen/c2ff.pl: each unit of a build, from its object's defined names
# (nm, as src/glibc's all-survey has them), written by both; their .ff.txt
# must be one byte for byte. Unit by unit: a milestone's whole page, many units
# at once, is gen/clpagecheck.sh's; c2ff.pl's --pass cache is not csema's.
#
#   sh clayercheck.sh [-j N] [-r RUN] [-t TARGET] [-v "UNITS"] [-f FF -p "PROGRAMS" [-x "INDEXED"]] -i I -o OBJ -s GLIBC_SRC -S shared.ff CSEMA DIR unit ...
#
# (a unit @file: the units in that file, one to a line.)
# unit is its path under I, without its .i (string/strlen); soft-fp's, whose
# objects are libgcc's here, from the name each defines (__addtf3). -p: the
# milestones' programs too, FF/m-prog.i against the FF/m-prog.ff.txt c2ff.pl
# wrote for the milestone (--program m; --start where that has a _start; -x:
# those with its --index FF/m/index.ff; PROGROOTS_m, the environment, more
# roots). -v: the units
# (of gcc's SSE4 intrinsics, CLANGVEC) csema reads through clang's copy, made
# here as CLANGFIX and CLANGVECPL say (src/glibc's). NM (the
# environment) is the target's nm; C2FF_ASTKEY as src/glibc exports it, so
# that c2ff.pl takes each unit's pass. DIR gets what differs (name.ff.txt
# csema's, name.ref c2ff.pl's, name.err); at the end a count; exit 1 if any
# differed or stopped. Left out: a unit whose object defines nothing (NONE),
# one c2ff.pl stops on itself (NOREF). LOBJ, the environment: libgcc's objects
# (units libgcc/x); LIBGCC_SRC its source.
#
# A host tool (POSIX sh, Perl for c2ff.pl).
set -u
G=$(cd "$(dirname "$0")" && pwd)
if test "${1:-}" = --one; then
    shift
    run=$1 tg=$2 vec=$3 I=$4 obj=$5 gsrc=$6 shared=$7 cs=$8 d=$9 u=${10}
    b=$(printf '%s' "$u" | tr / _)
    o=$obj/$u.o
    case "$u" in libgcc/*) o=$LOBJ/${u#libgcc/}.o ;; esac
    roots=$(${NM:-nm} --defined-only -g "$o" 2>/dev/null | awk 'NF == 3 { print $3 }')
    case "$u" in soft-fp/*) test -n "$roots" || roots=__${u#soft-fp/} ;; esac
    test -n "$roots" || { echo "NONE $u"; exit 0; }
    # (one c2ff.pl stops on, libgcc's of __int128 and _Float16, which its --keep-going leaves out in a milestone: nothing to compare)
    perl "$G/c2ff.pl" --target "$tg" "$I/$u.json=$I/$u.i" -- $roots > "$d/$b.ref" 2> "$d/$b.referr" || { echo "NOREF $u: $(tail -n 1 "$d/$b.referr" | head -c 200)"; exit 0; }
    in=$I/$u.i
    for v in $vec; do
        if test "$v" = "$u"; then
            in=$d/$b.clang.i
            eval "${CLANGFIX:-cat}" '"$I/$u.i"' | perl "$CLANGVECPL" > "$in"
        fi
    done
    if $run $cs -l -t "$tg" -s "$gsrc" -g "${LIBGCC_SRC:-}" -S "$shared" -n "$I/$u.i" "$in" $roots > "$d/$b.ff.txt" 2> "$d/$b.err"; then
        if cmp -s "$d/$b.ff.txt" "$d/$b.ref"; then
            echo "OK $u"
            rm -f "$d/$b.ff.txt" "$d/$b.ref" "$d/$b.err" "$d/$b.referr" "$d/$b.clang.i"
        else echo "DIFF $u: $(diff "$d/$b.ff.txt" "$d/$b.ref" | grep -c '^[<>]') lines"; fi
    else echo "STOP $u: $(tail -n 1 "$d/$b.err" | head -c 200)"; fi
    exit 0
fi
# the milestones' programs
prog_one() {
    m=$1
    f=
    grep -q '^_start:$' "$ff/$m-prog.ff.txt" && f=-T
    for x in $indexed; do test "$x" = "$m" && f="$f -I $ff/$m/index.ff"; done
    more=$(eval echo \"\${PROGROOTS_$m:-}\")
    if $run $cs -l -t "$tg" -s "$gsrc" -S "$shared" -P "$m" $f "$ff/$m-prog.i" main $more > "$d/$m-prog.ff.txt" 2> "$d/$m-prog.err"; then
        if cmp -s "$d/$m-prog.ff.txt" "$ff/$m-prog.ff.txt"; then echo "OK $m-prog"; rm -f "$d/$m-prog.ff.txt" "$d/$m-prog.err"
        else echo "DIFF $m-prog: $(diff "$d/$m-prog.ff.txt" "$ff/$m-prog.ff.txt" | grep -c '^[<>]') lines"; fi
    else echo "STOP $m-prog: $(tail -n 1 "$d/$m-prog.err" | head -c 200)"; fi
}
jobs=4 run= tg=riscv64 vec= I= obj= gsrc= shared= ff= progs= indexed=
while :; do
    case "${1:-}" in
    -j) jobs=$2; shift 2 ;;
    -r) run=$2; shift 2 ;;
    -t) tg=$2; shift 2 ;;
    -v) vec=$2; shift 2 ;;
    -i) I=$2; shift 2 ;;
    -o) obj=$2; shift 2 ;;
    -s) gsrc=$2; shift 2 ;;
    -S) shared=$2; shift 2 ;;
    -f) ff=$2; shift 2 ;;
    -p) progs=$2; shift 2 ;;
    -x) indexed=$2; shift 2 ;;
    *) break ;;
    esac
done
test $# -ge 3 || { echo "usage: clayercheck.sh [-j N] [-r RUN] [-t TARGET] [-v UNITS] -i I -o OBJ -s GLIBC_SRC -S shared.ff CSEMA DIR unit ..." >&2; exit 2; }
cs=$1 d=$2
shift 2
mkdir -p "$d"
for u in "$@"; do case "$u" in @*) cat "${u#@}" ;; *) echo "$u" ;; esac; done | xargs -P "$jobs" -n 1 sh "$0" --one "$run" "$tg" "$vec" "$I" "$obj" "$gsrc" "$shared" "$cs" "$d" > "$d/result"
for m in $progs; do prog_one "$m" >> "$d/result"; done
n=$(grep -c '^OK' "$d/result")
s=$(grep -c '^NONE' "$d/result")
r=$(grep -c '^NOREF' "$d/result")
f=$(grep -vc '^OK\|^NONE\|^NOREF' "$d/result")
grep -v '^OK\|^NONE\|^NOREF' "$d/result"
echo "clayercheck: $n units byte for byte as c2ff.pl's ($tg), $f do not; left out: $s whose objects define nothing, $r that c2ff.pl stops on (NOREF in $d/result)"
test "$f" -eq 0
