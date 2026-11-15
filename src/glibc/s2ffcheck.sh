#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# s2ffcheck.sh: tools/s2ff.ff against the Perl it is (gen/s2ff.pl,
# s2ff-aarch64.pl, s2ff-arm.pl) on asm objects, each run of both in each
# of the ways the build runs them: stdout, stderr, the exit status and the
# --facts file must be the same, byte for byte (make s2ff-crosscheck).
#
#   sh s2ffcheck.sh -t TARGET -p 'PERL CMD' -f 'FF CMD' -o OUT -s SSRC \
#       [-z 'NAME...'] [-l 'PLT...'] STEM...
#
# A stem is an object's path without its extension (its .s, SSRC, .dump);
# a crti's runs have --then its crtn's. The ways: --facts, --items, --size,
# the page, --items with -z's --zero and -l's --plt (the pages' runs); on
# aarch64 also --skip and --locals of the .s, on x86_64 --align. Prints a
# line for each run that differs (-x: also the runs that stop: no file, a
# file that is not there), and the count; exit 1 if one did. OUT
# (a folder) keeps the last run of each.
set -u
t= p= f= o= s=.s z= l= x=
while getopts t:p:f:o:s:z:l:x c; do
    case $c in
    x) x=1 ;; t) t=$OPTARG ;; p) p=$OPTARG ;; f) f=$OPTARG ;; o) o=$OPTARG ;; s) s=$OPTARG ;; z) z=$OPTARG ;; l) l=$OPTARG ;;
    *) echo "usage: s2ffcheck.sh -t target -p perl -f ff -o out [-s ssrc] [-z names] [-l plts] stem..." >&2; exit 2 ;;
    esac
done
shift $((OPTIND - 1))
test -n "$o" && test -n "$p" && test -n "$f" || { echo "s2ffcheck.sh: -o, -p and -f are needed" >&2; exit 2; }
mkdir -p "$o/p" "$o/f"
zo=; for w in $z; do zo="$zo --zero $w"; done
for w in $l; do zo="$zo --plt $w"; done
runs=0 bad=0
# run WHO ARGS...: one run of the Perl (p) or the ff (f) into $o/WHO/out and err
run() { w=$1; shift; st=0; $(test $w = p && echo "$p" || echo "$f") "$@" > "$o/$w/out" 2> "$o/$w/err" || st=$?; echo "exit $st" >> "$o/$w/err"; }
same() {
    runs=$((runs + 1))
    run p "$@"; run f "$@"
    if ! cmp -s "$o/p/out" "$o/f/out" || ! cmp -s "$o/p/err" "$o/f/err"; then
        echo "s2ff-crosscheck: differs: $*"; bad=$((bad + 1))
    fi
}
n=0
for a in "$@"; do
    n=$((n + 1))
    then=; case $a in */crti) then="--then ${a%crti}crtn$s ${a%crti}crtn.dump" ;; esac
    if test "$t" = aarch64; then same --locals "$a.s"; fi
    # --facts: its file too (each made empty first: a run that writes none leaves it so)
    runs=$((runs + 1))
    : > "$o/p/facts"; : > "$o/f/facts"
    run p --facts "$o/p/facts" "$a$s" "$a.dump" $then; run f --facts "$o/f/facts" "$a$s" "$a.dump" $then
    if ! cmp -s "$o/p/out" "$o/f/out" || ! cmp -s "$o/p/err" "$o/f/err" || ! cmp -s "$o/p/facts" "$o/f/facts"; then
        echo "s2ff-crosscheck: differs: --facts $a"; bad=$((bad + 1))
    fi
    same --items "$a$s" "$a.dump" $then
    same --size "$a$s" "$a.dump" $then
    same "$a$s" "$a.dump" $then
    same --items $zo "$a$s" "$a.dump" $then
    if test "$t" = aarch64; then same --skip "$a$s" "$a.dump" $then; fi
    if test "$t" = x86_64; then same --align "$a$s" "$a.dump" $then; fi
done
if test -n "$x"; then same; same "$o/none.s" "$o/none.dump"; same --size "$o/none.s"; fi
echo "s2ff-crosscheck: $n objects, $runs runs of each tool, $bad differ"
test $bad = 0
