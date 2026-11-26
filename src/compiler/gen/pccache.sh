#!/bin/sh
# pccache.sh — a step of ports-check through its cache of results: a step
# whose inputs are byte for byte those of a step that passed before (in
# any worktree) is not run again; its PASS is taken from the cache.
#
#   sh pccache.sh [-i | -n] STEP DIR 'KEYCMD' CMD ARG...
#
# KEYCMD (a make, run by sh with PCOUT=<file> after it) writes the spec of
# the step's inputs (its pckey-<step> target: src/glibc/pccache.mk,
# src/compiler/pccache.mk), whose key pckey.pl computes: sha256 over the
# bytes of every input. The cache is TTP_PCCACHE/<step>/<key> (ports-check
# sets TTP_PCCACHE, ~/.cache/ttp/check-cache, unless PC_NOCACHE=1): a PASS,
# the time it took, where it ran, and the step's small outputs (pckey.pl's
# o lines: asm-check's .asmok); beside it <key>.inputs.gz, the manifest the
# key is the hash of (zdiff two of them to see what changed). No build
# output is kept. If TTP_PCCACHE/<step>/<key> is there, the step prints
# "PASS <step> cached (<key prefix>)" and writes its outputs again;
# else CMD runs, and only on a PASS is it stored, and only if the key,
# computed again after it, is still the same (an input made again during
# the step is not the input of the key). A FAIL is never stored. Without a
# key (KEYCMD fails, an input is missing) the step runs, uncached.
#
# DIR is ports-check's CHECKLOG: STEP.log, STEP.result, STEP.slots as
# pc_step's, and STEP.spec, STEP.manifest, STEP.keylog. -i: a step inside
# another (compiler-check's tools-check-<t>): DIR holds only the key's files,
# CMD's output and the result line go to the standard output, and the
# status is CMD's. -n: only the key, and HIT or MISS (make pc-keys).
#
# Each step keeps its 20 newest entries (a hit makes its entry new again).
#
# A host tool, not part of ttpc.

set -u
inner= keyonly=
case ${1:-} in -i) inner=1; shift ;; -n) keyonly=1; shift ;; esac
test $# -ge 3 || { echo "usage: pccache.sh [-i | -n] STEP DIR 'KEYCMD' CMD ARG..." >&2; exit 2; }
step=$1 dir=$2 keycmd=$3; shift 3
gen=$(cd "$(dirname "$0")" && pwd)
cache=${TTP_PCCACHE:-}
test -n "${PC_NOCACHE:-}" && cache=
test -n "$keyonly" && test -z "$cache" && cache=$HOME/.cache/ttp/check-cache
mkdir -p "$dir"
log=$dir/$step.log result=$dir/$step.result slots=$dir/$step.slots
start=$(date +%s)
# (inside another step, its slot log)
if test -n "$inner"; then slots=${TTP_SLOTLOG:-/dev/null}; else rm -f "$slots"; fi

# the key of the step's inputs now (suffix $1), or nothing
keyof() {
    rm -f "$dir/$step.spec$1"
    TTP_SLOTLOG=$slots sh -c "$keycmd PCOUT=\"\$1\"" keycmd "$dir/$step.spec$1" > "$dir/$step.keylog$1" 2>&1 \
        && test -s "$dir/$step.spec$1" \
        && perl "$gen/pckey.pl" key "$dir/$step.spec$1" "$dir/$step.manifest$1" 2>> "$dir/$step.keylog$1"
}
say() { if test -n "$inner"; then echo "$*"; else echo "$*" >> "$log"; fi; }

key=
if test -n "$cache"; then
    key=$(keyof '') || key=
fi
entry=$cache/$step/$key
short=$(echo "$key" | cut -c1-12)

if test -n "$keyonly"; then
    if test -z "$key"; then echo "NOKEY $step (see $dir/$step.keylog)"
    elif test -f "$entry"; then echo "HIT $step ($short)"
    else echo "MISS $step ($short)"; fi
    exit 0
fi

test -n "$inner" || : > "$log"
if test -n "$cache" && test -z "$key"; then
    say "pccache: no key for $step (see $dir/$step.keylog): it runs, uncached"
fi
if test -n "$key" && test -f "$entry" && perl "$gen/pckey.pl" restore "$dir/$step.spec" "$entry" 2>> "$dir/$step.keylog"; then
    touch "$entry" "$entry.inputs.gz" 2> /dev/null
    say "pccache: $step, key $key: taken from the cache, $(sed -n 2p "$entry")"
    line="PASS $step cached ($short)"
    if test -n "$inner"; then echo "$line"; else echo "$line" | tee "$result"; fi
    exit 0
fi

if test -n "$inner"; then
    "$@"; s=$?
else
    if TTP_SLOTLOG=$slots "$@" >> "$log" 2>&1; then s=0; else s=1; fi
fi
secs=$(( $(date +%s) - start ))
if test $s -eq 0 && test -n "$key"; then
    key2=$(keyof .after) || key2=
    if test "$key2" = "$key"; then
        mkdir -p "$cache/$step"
        t=$entry.tmp.$$
        { echo "PASS $step $secs s"
          echo "ran $secs s on $(date -Iseconds) in $(basename "$(git rev-parse --show-toplevel 2> /dev/null)") at $(git rev-parse --short HEAD 2> /dev/null)"
        } > "$t" && perl "$gen/pckey.pl" save "$dir/$step.spec" "$t" 2>> "$dir/$step.keylog" \
            && gzip -c "$dir/$step.manifest" > "$t.inputs.gz" && mv "$t.inputs.gz" "$entry.inputs.gz" && mv "$t" "$entry" \
            && say "pccache: $step, key $key: stored" \
            || { rm -f "$t" "$t.inputs.gz"; say "pccache: $step: not stored"; }
        # (the 20 newest entries of the step)
        ls -t "$cache/$step" | grep -v '\.' | tail -n +21 | while read -r old; do rm -f "$cache/$step/$old" "$cache/$step/$old.inputs.gz"; done
    else
        say "pccache: $step: its inputs changed while it ran (key $key, then ${key2:-none}): not stored"
    fi
fi
if test -n "$inner"; then
    test $s -eq 0 && echo "PASS $step $secs s"
    exit $s
fi
w=$(awk '{ w += $1 } END { print w + 0 }' "$slots" 2> /dev/null || echo 0)
r=PASS; test $s -eq 0 || r=FAIL
echo "$r $step $secs s ($w s in slot queues)$(test $r = PASS || echo " log $log")" | tee "$result"
exit 0
