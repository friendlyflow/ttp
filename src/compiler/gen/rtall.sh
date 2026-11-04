#!/bin/sh
# rtall.sh — the round trip of all of glibc in ff (src/glibc's glibc-roundtrip):
# every function and global of its page, written back as C by ff2c.pl a unit at
# a time (--split), clang's AST of that against clang's AST of glibc's unit, by
# roundtrip.pl. No AST stays on disk: each goes through a pipe into its normal
# forms (DIR/back/name.norm, DIR/unit/name.norm), kept while what they come from
# has not changed, and at the end --join compares them.
#
#   sh rtall.sh [-j N] [-t TARGET] -u UNITS FF.ff.txt DIR
#
# UNITS is FF/glibc.units (a unit's json=i to a line). The environment:
# CLANGB, the clang command up to a file written back (as the milestones' .rt.c);
# CLANGU, up to a unit (as their .json), and CLANGL up to a unit of libgcc;
# CLANGFIX, CLANGVEC, CLANGVECPL as src/glibc has them. N files at once (4).
# DIR/result has a line for each file: OK, or BACK name / UNIT name: why;
# DIR/report roundtrip.pl's differences and count. Exit 1 if anything differs
# or any file failed.
#
# A host tool (POSIX sh, Perl, clang).
set -u
G=$(cd "$(dirname "$0")" && pwd)
RT=$G/../../glibc/roundtrip.pl
if test "${1:-}" = --back; then
    tg=$2 d=$3 f=$4
    b=$(basename "$f" .c)
    n=$d/back/$b.norm
    if test -s "$n" && test "$n" -nt "$RT" && cmp -s "$f" "$d/back/$b.done"; then echo "OK back $b"; exit 0; fi
    rm -f "$n"
    { $CLANGB "$f" 2> "$d/back/$b.err"; echo $? > "$d/back/$b.rc"; } | sed 's/"__Sync_/"__sync_/g' | perl "$RT" --target "$tg" --norm-back "$n" "$d/names" - 2>> "$d/back/$b.err" || { echo "BACK $b: roundtrip.pl: $(tail -n 1 "$d/back/$b.err" | head -c 300)"; rm -f "$n"; exit 0; }
    if test "$(cat "$d/back/$b.rc")" != 0; then echo "BACK $b: clang: $(grep -m1 'error:' "$d/back/$b.err" | head -c 300)"; rm -f "$n"; exit 0; fi
    rm -f "$d/back/$b.rc" "$d/back/$b.err"
    cp "$f" "$d/back/$b.done"
    echo "OK back $b"
    exit 0
fi
if test "${1:-}" = --unit; then
    tg=$2 d=$3 l=$4
    j=${l%%=*} u=${l#*=}
    b=$(printf '%s' "$u" | sed 's|\.i$||; s|^.*/i/||; s|^.*/ff/||; s|^/*||; s|/|_|g')
    n=$d/unit/$b.norm
    if test -s "$n" && test "$n" -nt "$RT" && test "$n" -nt "$d/names.unit"; then echo "OK unit $b"; exit 0; fi
    rm -f "$n"
    in=$u cl=$CLANGU
    case "$u" in
    */i/libgcc/*)
        cl=$CLANGL in=$d/unit/$b.clang.i
        perl "$G/../../libgcc/clangfix.pl" --target "$tg" "$u" > "$in" ;;
    *)
        vec=
        for v in ${CLANGVEC:-}; do case "$u" in */i/"$v".i) vec=1; cl="$cl -msse4.2" ;; esac; done
        if test -n "${CLANGFIX:-}$vec"; then
            in=$d/unit/$b.clang.i
            if test -n "$vec"; then eval "${CLANGFIX:-cat}" '"$u"' | perl "$CLANGVECPL" > "$in"; else eval "$CLANGFIX" '"$u"' > "$in"; fi
        fi ;;
    esac
    { $cl "$in" 2> "$d/unit/$b.err"; echo $? > "$d/unit/$b.rc"; } | perl "$RT" --target "$tg" --norm-unit "$n" "$d/names" "$j" - 2>> "$d/unit/$b.err" || { echo "UNIT $b: roundtrip.pl: $(tail -n 1 "$d/unit/$b.err" | head -c 300)"; rm -f "$n" "$d/unit/$b.clang.i"; exit 0; }
    test "$in" = "$u" || rm -f "$in"
    if test "$(cat "$d/unit/$b.rc")" != 0; then echo "UNIT $b: clang: $(grep -m1 'error:' "$d/unit/$b.err" | head -c 300)"; rm -f "$n"; exit 0; fi
    rm -f "$d/unit/$b.rc" "$d/unit/$b.err"
    echo "OK unit $b"
    exit 0
fi
jobs=4 tg=riscv64 units=
while :; do
    case "${1:-}" in
    -j) jobs=$2; shift 2 ;;
    -t) tg=$2; shift 2 ;;
    -u) units=$2; shift 2 ;;
    *) break ;;
    esac
done
test $# -eq 2 && test -n "$units" || { echo "usage: rtall.sh [-j N] [-t TARGET] -u UNITS FF.ff.txt DIR" >&2; exit 2; }
ff=$1 d=$2
export CLANGB CLANGU CLANGL
mkdir -p "$d/back" "$d/unit"
perl "$G/ff2c.pl" --target "$tg" --split "$d/c" "$ff" "$d/chunks" "$d/names" 2> "$d/ff2c.err" || { echo "rtall: ff2c stopped: $(tail -n 1 "$d/ff2c.err" | head -c 300)"; exit 1; }
# (arm's libgcc defines the __sync functions, clang's builtins: __Sync_ in the C clang reads, as the milestones')
test "$tg" = arm && sed -i 's/\b__sync_/__Sync_/g' "$d"/c/*.c
# (a unit's normal forms hold for the same names)
cmp -s "$d/names" "$d/names.unit" || cp "$d/names" "$d/names.unit"
cat "$d/chunks" | xargs -P "$jobs" -n 1 sh "$0" --back "$tg" "$d" > "$d/result"
cat "$units" | xargs -P "$jobs" -n 1 sh "$0" --unit "$tg" "$d" >> "$d/result"
sed 's|^.*/||; s|\.c$||; s|^|'"$d"'/back/|; s|$|.norm|' "$d/chunks" > "$d/back.list"
sed 's|^.*=||; s|\.i$||; s|^.*/i/||; s|^.*/ff/||; s|^/*||; s|/|_|g; s|^|'"$d"'/unit/|; s|$|.norm|' "$units" > "$d/unit.list"
# (those of a file that failed are not there: named in result, their functions not in the count)
{ for f in $(cat "$d/back.list"); do test -s "$f" && echo "$f"; done; } > "$d/back.have"
{ for f in $(cat "$d/unit.list"); do test -s "$f" && echo "$f"; done; } > "$d/unit.have"
s=0
perl "$RT" --target "$tg" --join "$d/names" "@$d/back.have" -- "@$d/unit.have" > "$d/report" || s=$?
f=$(grep -vc '^OK' "$d/result")
grep -v '^OK' "$d/result" | head -40
tail -n 1 "$d/report"
echo "rtall ($tg): $(grep -c '^OK back' "$d/result") files written back and $(grep -c '^OK unit' "$d/result") units read, $f failed; differences in $d/report"
test "$f" -eq 0 && test "$s" -eq 0
