#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# roundtrip.sh GCC FF "QEMU" WORK SRC (port.mk's PKG_ROUNDTRIP): tar's round
# trip. The input, WORK/in: tar's src/ and doc/ (SRC), a name past 100
# bytes in a deep folder, a symbolic and a hard link, an empty folder and
# file, a sparse file, a mode of 0600, a name not ASCII, all of one time.
# For each format (gnu, oldgnu, ustar, posix, v7; posix without its
# atime/ctime and with fixed header names, its sparse file of version
# 0.0: 0.1's and 1.0's member name has the process id; posix1, sparse 1.0,
# not compared by its bytes): both programs make an archive of it (names sorted, owner
# 0, the time fixed) and must make the same bytes and list (-tv) each
# other's the same; each extracts the other's, which must be the input (its
# files, modes, times, link targets); each appends (-r) a file to a copy
# of the other's and deletes (--delete) a member from another, the same
# bytes again (not posix's delete: tar 1.35's aborts on a pax archive,
# gcc's and nixpkgs' alike). A line "NAME PASS" or "NAME FAIL:what" each.
set -u
G=$1 F=$2 Q=$3 W=$4 S=$5
cd "$W" || exit 1
export TZ=UTC0 LC_ALL=C
run () { $Q "$@"; }
mkdir -p in/t
cp -r "$S"/src "$S"/doc in/t/ || exit 1
d=in/t/deep/a-folder-with-a-long-name/another-folder-with-a-long-name/and-one-more-with-a-name-past
mkdir -p "$d"
echo long > "$d/a-file-whose-path-is-longer-than-one-hundred-bytes-of-a-ustar-name-field.txt"
ln -s ../src/tar.c in/t/deep/link-to-tar.c
ln in/t/src/tar.h in/t/deep/hard-tar.h
mkdir in/t/empty-folder; : > in/t/empty-file
echo secret > in/t/mode600; chmod 600 in/t/mode600
printf 'caf\303\251\n' > "in/t/caf$(printf '\303\251')"
dd if=/dev/zero of=in/t/sparse bs=1 count=0 seek=4194304 2> /dev/null; echo end >> in/t/sparse
printf 'start' | dd of=in/t/sparse conv=notrunc 2> /dev/null
echo extra > in/extra
find in -exec touch -h -d @1000000000 {} +
state () { (cd "$1" && find . -printf '%p %y %m %s %T@ %l\n' | sort); }
state in/t > s.in
for fmt in gnu oldgnu ustar posix posix1 v7; do
    why=
    c="--format=${fmt%1} --sort=name --mtime=@1000000000 --owner=0 --group=0 --numeric-owner"
    case $fmt in posix*) c="$c --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime" ;; esac
    sp=; case $fmt in gnu|oldgnu|posix1) sp=--sparse ;; posix) sp="--sparse --sparse-version=0.0" ;; esac
    run "$G" -cf a.g $c $sp -C in t 2> e.g; eg=$?
    run "$F" -cf a.f $c $sp -C in t 2> e.f; ef=$?
    test $eg = $ef || why="$why,exit$eg/$ef"
    cmp -s e.g e.f || why="$why,stderr"
    test $fmt = posix1 || cmp -s a.g a.f || why="$why,bytes"
    run "$G" -tvf a.f --numeric-owner > t.g 2>&1; run "$F" -tvf a.g --numeric-owner > t.f 2>&1
    cmp -s t.g t.f || why="$why,list"
    rm -rf x.gf x.fg; mkdir x.gf x.fg
    run "$F" -xf a.g -C x.gf 2> /dev/null; run "$G" -xf a.f -C x.fg 2> /dev/null
    state x.gf/t > s.gf; state x.fg/t > s.fg
    case $fmt in
    ustar|v7) # (their names stop at 100 or 255 bytes, sparse files are whole: only the two compared)
        cmp -s s.gf s.fg || why="$why,extract" ;;
    *)  cmp -s s.in s.gf || why="$why,ffextract"; cmp -s s.in s.fg || why="$why,gccextract"
        diff -r --no-dereference in/t x.gf/t > /dev/null || why="$why,ffcontent"
        diff -r --no-dereference in/t x.fg/t > /dev/null || why="$why,gcccontent" ;;
    esac
    cp a.g r.g; cp a.g r.f
    run "$G" -rf r.g $c -C in extra; run "$F" -rf r.f $c -C in extra
    test $fmt = posix1 || cmp -s r.g r.f || why="$why,append"
    case $fmt in posix*) ;; *)
        cp a.f k.g; cp a.f k.f
        run "$G" --delete -f k.g t/src/tar.c; run "$F" --delete -f k.f t/src/tar.c
        cmp -s k.g k.f || why="$why,delete" ;;
    esac
    echo "$fmt ${why:+FAIL:${why#,}}${why:-PASS}"
done
