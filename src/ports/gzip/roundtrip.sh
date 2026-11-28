#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# roundtrip.sh GCC FF "QEMU" WORK SRC (port.mk's PKG_ROUNDTRIP): gzip's
# round trip. Inputs in WORK/in: a tar of gzip's source (SRC), the
# program itself, an empty file, a file of zeros, random bytes, gzip's C.
# For each input and level: both programs compress it (-n, from stdin) and
# must make the same bytes, each decompresses the other's to the input;
# both list (-l) and test (-t) each other's; a file compressed by name
# (its name and time in the header) makes the same bytes; two members, one
# of each, decompress as one. A line "NAME PASS" or "NAME FAIL:what" each.
set -u
G=$1 F=$2 Q=$3 W=$4 S=$5
cd "$W" || exit 1
run () { $Q "$@"; }
mkdir -p in
tar -cf in/src.tar -C "$S" --sort=name --mtime=@1000000000 --owner=0 --group=0 --numeric-owner . || exit 1
cp "$G" in/prog
: > in/empty
head -c 1000000 /dev/zero > in/zeros
perl -e 'srand(1); print map { chr int rand 256 } 1 .. 300000' > in/random
cat "$S"/*.c > in/text
for f in in/*; do
    b=${f#in/}
    for o in -1 -6 -9 --rsyncable; do
        why=
        run "$G" -n $o -c < "$f" > a.g; eg=$?
        run "$F" -n $o -c < "$f" > a.f; ef=$?
        test $eg = $ef || why="$why,exit$eg/$ef"
        cmp -s a.g a.f || why="$why,bytes"
        { run "$F" -d -c < a.g > d.gf && cmp -s d.gf "$f"; } || why="$why,ffreads"
        { run "$G" -d -c < a.f > d.fg && cmp -s d.fg "$f"; } || why="$why,gccreads"
        run "$F" -t < a.g || why="$why,fftest"
        run "$G" -t < a.f || why="$why,gcctest"
        cp a.g l.gz; run "$G" -l -v l.gz > l.g 2>&1; run "$F" -l -v l.gz > l.f 2>&1
        cmp -s l.g l.f || why="$why,list"
        cat a.g a.f > m.gz
        { run "$F" -d -c < m.gz > m.f && cat "$f" "$f" | cmp -s - m.f; } || why="$why,ffmembers"
        echo "$b$o $(test -n "$why" && echo "FAIL:${why#,}" || echo PASS)"
    done
    why=
    rm -rf ng nf; mkdir ng nf; cp "$f" ng/"$b"; cp "$f" nf/"$b"; touch -d @1000000000 ng/"$b" nf/"$b"
    (cd ng && run "$G" -9 "$b"); (cd nf && run "$F" -9 "$b")
    cmp -s ng/"$b".gz nf/"$b".gz || why="$why,bytes"
    (cd ng && run "$F" -d -N "$b".gz) && cmp -s ng/"$b" "$f" || why="$why,ffreads"
    (cd nf && run "$G" -d -N "$b".gz) && cmp -s nf/"$b" "$f" || why="$why,gccreads"
    test "$(stat -c %Y ng/"$b")" = "$(stat -c %Y nf/"$b")" || why="$why,time"
    echo "$b-byname $(test -n "$why" && echo "FAIL:${why#,}" || echo PASS)"
done
