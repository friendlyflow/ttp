#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# roundtrip.sh GCC FF "QEMU" WORK SRC (port.mk's PKG_ROUNDTRIP): xz's round
# trip. Inputs in WORK/in: a tar of XZ Utils' source (SRC), the program
# itself, an empty file, a file of zeros, random bytes, liblzma's C. For
# each input and each set of options (presets, extreme, a CRC32 or SHA-256
# check, .lzma, BCJ x86 and delta filters before LZMA2, blocks of 64 KiB in
# one thread and in two): both programs compress it (from stdin) and must
# make the same bytes, each decompresses the other's to the input and
# tests it; both list (-lvv --robot) the same; two streams, one of each,
# decompress as one. A line "NAME PASS" or "NAME FAIL:what" each.
set -u
G=$1 F=$2 Q=$3 W=$4 S=$5
cd "$W" || exit 1
run () { $Q "$@"; }
mkdir -p in
tar -cf in/src.tar -C "$S" --sort=name --mtime=@1000000000 --owner=0 --group=0 --numeric-owner src || exit 1
cp "$G" in/prog
: > in/empty
head -c 1000000 /dev/zero > in/zeros
perl -e 'srand(1); print map { chr int rand 256 } 1 .. 300000' > in/random
cat "$S"/src/liblzma/*/*.c > in/text
opts () {
    cat <<'OPTS'
p0 -0
p6 -6
p9e -9e
crc32 -6 --check=crc32
sha256 -3 --check=sha256
none -2 --check=none
lzma --format=lzma -6
x86 --x86 --lzma2=preset=6
delta --delta=dist=4 --lzma2=preset=1
blocks1 -T1 --block-size=65536 -4
blocks2 -T2 --block-size=65536 -4
OPTS
}
for f in in/*; do
    b=${f#in/}
    opts | while read -r n o; do
        why=
        case $n in lzma) d="--format=lzma -d" ;; *) d=-d ;; esac
        run "$G" $o -c < "$f" > a.g; eg=$?
        run "$F" $o -c < "$f" > a.f; ef=$?
        test $eg = $ef || why="$why,exit$eg/$ef"
        cmp -s a.g a.f || why="$why,bytes"
        { run "$F" $d -c < a.g > d.gf && cmp -s d.gf "$f"; } || why="$why,ffreads"
        { run "$G" $d -c < a.f > d.fg && cmp -s d.fg "$f"; } || why="$why,gccreads"
        if test $n != lzma; then
            run "$F" -t < a.g || why="$why,fftest"
            run "$G" -t < a.f || why="$why,gcctest"
            cp a.g l.xz; run "$G" -lvv --robot l.xz > l.g 2>&1; run "$F" -lvv --robot l.xz > l.f 2>&1
            cmp -s l.g l.f || why="$why,list"
            cat a.g a.f > m.xz
            { run "$F" -d -c < m.xz > m.f && cat "$f" "$f" | cmp -s - m.f; } || why="$why,ffstreams"
        fi
        echo "$b-$n ${why:+FAIL:${why#,}}${why:-PASS}"
    done
done
