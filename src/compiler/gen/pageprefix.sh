#!/bin/sh
# pageprefix.sh — c2ff-crosscheck's comparison of a page: FF.ff.txt, as the
# build made it with csema -l, is its license, then csema's page, then what
# follows (the asm page, the builtins); LICENSE then PAGE (gen/c2ff.pl's,
# made by the cross-check) must be its beginning, byte for byte, and what
# follows must begin a page of its own (a line not indented), or nothing.
#
#   sh pageprefix.sh NAME LICENSE PAGE FF.ff.txt [TARGET]
#
# With TARGET, FF.ff.txt is read as c2ff.pl would write it where csema departs
# on purpose (c2ffknown.pl's rules) first, next to it as FF.ff.txt.known.
# Prints one line, the same or not; exit 1 if not.
# A host tool (POSIX sh).
set -u
name=$1 lic=$2 page=$3 ff=$4
if test $# -ge 5; then perl "$(dirname "$0")/c2ffknown.pl" --target "$5" "$ff" > "$ff.known" || exit 1; ff=$ff.known; fi
a=$(wc -c < "$lic") b=$(wc -c < "$page")
if { cat "$lic" "$page"; } | cmp -s -n $((a + b)) - "$ff" && { c=$(tail -c +$((a + b + 1)) "$ff" | head -c 1); test -z "$c" || test "$c" != " "; }; then
    echo "$name: c2ff.pl's page and csema's the same, $(wc -l < "$page") lines"
else
    echo "$name: c2ff.pl's page and csema's NOT the same: $( { cat "$lic" "$page"; } | cmp - "$ff" 2>&1 | head -c 200)"
    exit 1
fi
