#!/bin/sh
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# units.sh ROOT REC LINK.cmd: the units of a program ffcc recorded the link of
# (port.mk), one a line, each the object's path under ROOT without .o: an
# object of the link itself as "-O unit" (its constructors are roots, as
# csema -l's -O), then each member of its archives (ar t), which csema
# takes only as far as the roots reach, as the linker does.
set -eu
root=$1 rec=$2 cmd=$3
skip= first=1 objs= arcs=
while IFS= read -r a; do
    if test -n "$first"; then cwd=$a; first=; continue; fi
    if test -n "$skip"; then skip=; continue; fi
    case $a in
        -o|-L|-T|-Xlinker|-z) skip=1 ;;
        -*) ;;
        *.o) objs="$objs $a" ;;
        *.a) arcs="$arcs $a" ;;
        *) echo "units.sh: an input of the link it does not know: $a" >&2; exit 1 ;;
    esac
done < "$cmd"
rel () { case $1 in /*) p=$1 ;; *) p=$cwd/$1 ;; esac; p=$(realpath -m "$p"); echo "${p#"$(realpath -m "$root")"/}"; }
for o in $objs; do r=$(rel "$o"); echo "-O ${r%.o}"; done
for a in $arcs; do
    d=$(dirname "$(rel "$a")")
    case $a in /*) p=$a ;; *) p=$cwd/$a ;; esac
    # (a member by its name alone: its object in the archive's folder or one below, lib/malloc/...)
    for m in $(ar t "$p"); do
        f=$(cd "$rec/u" && find "$d" -name "${m%.o}.cmd")
        test $(echo "$f" | grep -c .) = 1 || { echo "units.sh: $m of $a: not one object of ffcc's: $f" >&2; exit 1; }
        echo "${f%.cmd}"
    done
done
