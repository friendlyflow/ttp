#!/bin/sh
# slot.sh — runs a heavy command (c2ff, ttpc on a big input, qemu, a glibc
# or package build) in one of the machine's shared slots, so that the lanes
# working at once never run more than three such commands together: the
# machine has 32 GB and no swap. A slot is a lock, ~/.cache/ttp/slot.N
# (N = 1..3), held with flock while the command runs; the first free one is
# taken, and when none is free it waits for one.
#
#   sh slot.sh [-v KB] [-t SECONDS] CMD ARG...
#
# -v caps the command's memory (ulimit -v, in KB: 4000000 for most, 8000000
# for qemu-arm), -t its time (timeout). A command that is already in a slot
# (TTP_SLOT set, as slot.sh sets it for what it runs) takes no second one.
# TTP_SLOTS (the folder) and TTP_NSLOTS (3) change the slots.

set -u
mem= secs=
while test $# -gt 0; do
    case $1 in
        -v) mem=$2; shift 2 ;;
        -t) secs=$2; shift 2 ;;
        --) shift; break ;;
        *) break ;;
    esac
done
test $# -gt 0 || { echo "usage: slot.sh [-v KB] [-t SECONDS] CMD ARG..." >&2; exit 2; }

run() {
    test -n "$mem" && { ulimit -v "$mem" || exit 2; }
    if test -n "$secs"; then exec timeout "$secs" "$@"; else exec "$@"; fi
}

test -n "${TTP_SLOT:-}" && run "$@"

dir=${TTP_SLOTS:-$HOME/.cache/ttp}
n=${TTP_NSLOTS:-3}
mkdir -p "$dir"
waited=
while :; do
    i=1
    while test $i -le $n; do
        exec 9>> "$dir/slot.$i"
        if flock -n 9; then
            test -n "$waited" && echo "slot.sh: got slot $i" >&2
            TTP_SLOT=$i; export TTP_SLOT
            run "$@"
        fi
        exec 9>&-
        i=$((i + 1))
    done
    test -n "$waited" || { echo "slot.sh: all $n slots busy, waiting" >&2; waited=1; }
    sleep 1
done
