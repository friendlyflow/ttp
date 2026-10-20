#!/bin/sh
# run.sh TARGET OUTDIR: the ABI test (abi.h): abi_gcc.c by gcc and s2ff,
# abi_main.c by c2ff, both by ttpc into one program, run; every check must say ok.
# Needs the dev shell (GLIBC_CC_<target>, C2FF_CLANG) and stage2 as TTPC.
set -e
t=$1 o=$2
here=$(cd "$(dirname "$0")" && pwd)
c=$here/../..
mkdir -p "$o"
case $t in
arm) cc=$GLIBC_CC_arm; ct="armv7a-linux-gnueabihf -mfloat-abi=hard -mfpu=vfpv3-d16"; x=armv7l-unknown-linux-gnueabihf-; s2ff=s2ff-arm.pl; q="qemu-arm";;
*) echo "run.sh: no ABI test for $t yet"; exit 1;;
esac
ulimit -v 8000000
"$cc" -O1 -fno-pic -fno-asynchronous-unwind-tables -fno-unwind-tables -S "$here/abi_gcc.c" -o "$o/abi_gcc.s"
"$cc" -c -x assembler "$o/abi_gcc.s" -o "$o/abi_gcc.o"
${x}objdump -d -r -t "$o/abi_gcc.o" > "$o/abi_gcc.dump"
perl "$c/gen/$s2ff" --page 'abi gcc' "$o/abi_gcc.s" "$o/abi_gcc.dump" > "$o/abi_gcc.ff.txt"
perl "$c/gen/fftext.pl" ff "$o/abi_gcc.ff.txt" > "$o/abi_gcc.ff"
timeout 60 "$C2FF_CLANG" -x c -Xclang -ast-dump=json -fsyntax-only --target=$ct -std=gnu11 -w -I"$here" "$here/abi_main.c" > "$o/abi_main.json"
"$cc" -E -P -I"$here" "$here/abi_main.c" > "$o/abi_main.i"
# (c2ff's program includes a library folder: here gcc's functions are a tree of their own)
timeout 120 perl "$c/gen/c2ff.pl" --target $t --program abitest --start "$o/abi_main.json=$here/abi_main.c" -- main $(grep -o "^[a-z0-9_ ]* \(cb_[a-z0-9_]*\) (" "$here/abi_main.c" | sed "s/.* \(cb_[a-z0-9_]*\) (/\1/") 2> "$o/abi_main.c2ff.err" | sed -e '/^include$/,+1d' > "$o/abi_main.ff.txt"
perl "$c/gen/fftext.pl" ff "$o/abi_main.ff.txt" > "$o/abi_main.ff"
(cd "$c" && timeout 120 $TTPC --target $t shared.ff "$o/abi_gcc.ff" "$o/abi_main.ff" "$o/abitest" > "$o/abitest.lst")
s=0; timeout 20 $q "$o/abitest" > "$o/abitest.out" || s=$?
cat "$o/abitest.out"
echo "abi-$t: exit $s"
test $s -eq 0
