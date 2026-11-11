#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# qwrap.sh wrap|unwrap DIR "QEMU [OPTIONS]": a package's test suite on a
# target that is not the machine's, without binfmt_misc (which needs root):
# wrap moves each program of the build (DIR, an ELF executable) to
# NAME.qbin and puts in its place a script that runs it under qemu-user,
# its argv[0] the base of the name it was called by (-0: as PATH gives it
# natively; both runs of a check are wrapped the same; called by a symlink,
# the program the link leads to: coreutils' one program); unwrap puts them
# back. The scripts are newer than the objects: make takes them as made.
set -eu
what=$1 dir=$2 qemu=$3
case $what in
wrap)
    find "$dir" -type f -perm -u+x ! -name '*.qbin' ! -name '*.so*' | while IFS= read -r f; do
        test "$(head -c 4 "$f" | od -An -tx1 | tr -d ' ')" = 7f454c46 || continue
        mv "$f" "$f.qbin"
        printf '#!/bin/sh\nexec %s -0 "${0##*/}" "$(readlink -f "$0").qbin" "$@"\n' "$qemu" > "$f"
        chmod +x "$f"
    done ;;
unwrap)
    find "$dir" -type f -name '*.qbin' | while IFS= read -r f; do
        mv "$f" "${f%.qbin}"
        touch "${f%.qbin}"
    done ;;
*) echo "usage: qwrap.sh wrap|unwrap DIR QEMU" >&2; exit 2 ;;
esac
