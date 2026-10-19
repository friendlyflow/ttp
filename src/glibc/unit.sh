#!/bin/sh
# unit.sh — c2ff's pass of one C object (tu.c2ff, see c2ff.pl's unit_pass),
# made only where it is not the pass of its .i already: then clang's AST of
# it is made for the pass, and deleted after (all of glibc's take some
# 16 GB). That part takes one of the machine's shared slots (slot.sh, with
# a memory cap and a timeout); the look at the cache takes none.
#
#   sh unit.sh <target> <tu.i> <tu.json> <clang's input> <clang command ...>
#
# clang's input is the .i, or the copy of it the Makefile made for clang
# (CLANGFIX), deleted with the AST.
c2ff=../compiler/gen/c2ff.pl
if test "$1" = --heavy; then
    shift
    t=$1 i=$2 json=$3 src=$4
    shift 4
    s=0; "$@" "$src" > "$json" && perl $c2ff --pass --target "$t" "$json=$i" || s=$?
    rm -f "$json"
    exit $s
fi
t=$1 i=$2 json=$3 src=$4
s=0; (ulimit -v 4000000; timeout 120 perl $c2ff --pass --target "$t" "$json=$i") 2> /dev/null || s=$?
if test $s -eq 3; then
    s=0; sh ../compiler/gen/slot.sh -v 4000000 -t 600 sh unit.sh --heavy "$@" || s=$?
    test $s -eq 0 || echo "unit.sh: $i: no pass (exit $s)"
elif test $s -ne 0; then
    echo "unit.sh: $i: c2ff --pass: exit $s"
fi
test "$src" = "$i" || rm -f "$src"
exit $s
