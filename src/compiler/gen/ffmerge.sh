#!/bin/sh
# ffmerge.sh — a git merge driver for ff trees (.ff). A tree is binary, but
# fftext.pl turns it into text and back without loss (one node per line,
# indented by depth), so a merge of two trees is a merge of their texts:
# base, ours and theirs to text, git merge-file, and the result back to ff
# into ours. `make git-setup` registers it (.gitattributes: *.ff merge=ff):
#
#   git config merge.ff.driver "sh src/compiler/gen/ffmerge.sh %O %A %B %P"
#
#   sh ffmerge.sh <base> <ours> <theirs> [<path>]
#
# Two branches that change different nodes merge cleanly. A conflict leaves
# ours as it was (still a valid tree, so the build sees no half merge), the
# text with git's markers in <path>.conflict.ff.txt and exits 1. Resolve it
# there, then
#
#   perl src/compiler/gen/fftext.pl ff <path>.conflict.ff.txt > <path>
#   rm <path>.conflict.ff.txt; git add <path>
#
# A text that does not read back as a tree (a marker left in it, a bad
# indent) is a conflict too. An empty base (a tree added on both sides) is
# an empty text.

set -u
base=$1 ours=$2 theirs=$3 path=${4:-$2}
fftext="perl $(dirname "$0")/fftext.pl"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/ffmerge.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT

totext() {
    if test -s "$1"; then
        $fftext txt "$1" > "$2" || { echo "ffmerge: $path: $1 is not an ff tree" >&2; exit 2; }
    else
        : > "$2"
    fi
}
totext "$base" "$tmp/base"
totext "$ours" "$tmp/ours"
totext "$theirs" "$tmp/theirs"

git merge-file -L ours -L base -L theirs "$tmp/ours" "$tmp/base" "$tmp/theirs"
status=$?
if test $status -eq 0 && $fftext ff "$tmp/ours" > "$tmp/merged" 2> "$tmp/err"; then
    cp "$tmp/merged" "$ours"
    exit 0
fi
cp "$tmp/ours" "$path.conflict.ff.txt"
if test $status -eq 0; then
    echo "ffmerge: $path: the merged text is not a tree: $(cat "$tmp/err")" >&2
else
    echo "ffmerge: $path: $status conflict(s), resolve them in $path.conflict.ff.txt" >&2
fi
echo "ffmerge: then: perl src/compiler/gen/fftext.pl ff $path.conflict.ff.txt > $path" >&2
exit 1
