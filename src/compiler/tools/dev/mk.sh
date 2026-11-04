#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# mk.sh: the C layer tools' pages from their dev C. The committed tools/*.ff
# are the truth, and what the build reads; the C here is what they are made
# from: c/ tools/c.ff, cparse.ff, cprint.ff; cs/ tools/csem.ff, csema.ff,
# csema-<target>.ff (cs/ takes c/c.h). Through clang + gen/c2ff.pl --page,
# then each folder's mkpages.py, fftext and addlicense, all in build/dev.
#
#   sh src/compiler/tools/dev/mk.sh [-i] [-n] [c] [cs]
#
# Without -i: compares what it made with tools/, exit 1 if any differs (make
# tools-dev-check; a change of gen/c2ff.pl can show here too). -i: installs it
# in tools/, by a rename. -n: also a gcc build of each for fast work,
# build/dev/c/cparse, build/dev/cs/csema. The folder here is only read; every
# output goes to build/dev. It stops on a source that is empty or under half
# its committed size: an accident, get it back with git checkout.
# Needs nix develop's clang (it enters nix develop if C2FF_CLANG is not set).
set -eu
install= native=
while :; do
    case "${1:-}" in
    -i) install=1; shift ;;
    -n) native=1; shift ;;
    *) break ;;
    esac
done
if test -z "${C2FF_CLANG:-}"; then
    exec nix develop "$(dirname "$0")/../../../.." -c sh "$0" ${install:+-i} ${native:+-n} "$@"
fi
D=$(cd "$(dirname "$0")" && pwd)
C=$(cd "$D/../.." && pwd)
R=$(cd "$C/../.." && pwd)
OUT=$R/build/dev
case "$OUT/" in "$D"/*) echo "mk.sh: its output $OUT is in its source" >&2; exit 2 ;; esac

# ---- sources as they should be
for f in "$D"/c/* "$D"/cs/*; do
    test -s "$f" || { echo "mk.sh: $f is empty: git checkout it" >&2; exit 2; }
    was=$(git -C "$D" cat-file -s "HEAD:./${f#"$D"/}" 2> /dev/null || echo 0)
    now=$(wc -c < "$f")
    test $((now * 2)) -ge "$was" || { echo "mk.sh: $f is $now bytes, committed $was: an accident? git checkout it" >&2; exit 2; }
done

# made in a fresh folder of copies
fresh() { rm -rf "$OUT/$1"; mkdir -p "$OUT/$1"; cp "$D/$1"/* "$OUT/$1"/; }
units() { # the units' .i and clang's AST of them, in riscv64's C (the C has no type that differs by target)
    for u in "$@"; do
        "$C2FF_CLANG" -E "$u.c" -o "$u.i"
        "$C2FF_CLANG" -x c -Xclang -ast-dump=json -fsyntax-only --target=riscv64-linux-gnu -std=gnu11 -w "$u.i" > "$u.json"
    done
}
pages() { # the pages made, each made ff with its license: installed or compared
    b=0
    for p in "$@"; do
        perl "$C/gen/fftext.pl" ff "$p.ff.txt" > "$p.ff"
        perl "$C/gen/addlicense.pl" "$p.ff" > /dev/null
        if test -n "$install"; then
            cp "$p.ff" "$C/tools/.$p.ff.new" && mv "$C/tools/.$p.ff.new" "$C/tools/$p.ff"
            echo "mk.sh: tools/$p.ff"
        elif cmp -s "$p.ff" "$C/tools/$p.ff"; then
            echo "mk.sh: tools/$p.ff as its C makes it"
        else
            echo "mk.sh: tools/$p.ff is not what its C makes (build/dev/$w); sh src/compiler/tools/dev/mk.sh -i if it should be"
            b=1
        fi
    done
    return $b
}

bad=0
for w in ${*:-c cs}; do
    case $w in
    c)
        fresh c
        cd "$OUT/c"
        units c cparse_main cprint_main
        perl "$C/gen/c2ff.pl" --page cparse --target riscv64 c.json=c.i cparse_main.json=cparse_main.i cprint_main.json=cprint_main.i -- \
            cparse_main cprint_main c_off_of c_state_new c_state_get c_state_set c_parens_of nd_emit > all.ff.txt 2> c2ff.err
        python3 mkpages.py
        pages c cparse cprint || bad=1
        if test -n "$native"; then gcc -O1 -w -o cparse shim.c c.c cparse_main.c cprint_main.c; fi
        ;;
    cs)
        fresh cs
        cp "$D/c/c.h" "$D/c/c.c" "$D/c/cpr.c" "$OUT/cs"/
        cd "$OUT/cs"
        units cs csema_main
        perl "$C/gen/c2ff.pl" --page csema --target riscv64 cs.json=cs.i csema_main.json=csema_main.i -- csema_main > all.ff.txt 2> c2ff.err
        python3 mkpages.py
        pages csem csema csema-riscv64 csema-x86_64 csema-aarch64 csema-arm || bad=1
        if test -n "$native"; then gcc -O1 -w -o csema shim.c c.c cs.c csema_main.c; fi
        ;;
    *) echo "usage: mk.sh [-i] [-n] [c] [cs]" >&2; exit 2 ;;
    esac
done
exit $bad
