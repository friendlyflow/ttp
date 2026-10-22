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
# TTP_SLOTS (the folder) and TTP_NSLOTS (3) change the slots. With
# TTP_SLOTLOG set, each command that takes a slot adds a line to that file:
# the seconds it waited for one, and the command.
#
# ulimit -v caps one process, never their sum, and what a slotted command
# starts runs in that slot without a lock of its own: on 2026-10-20 a make
# that called itself without end froze the machine, which has no swap. So a
# command that takes a slot also runs in a systemd user scope of its own,
# capped at TTP_SCOPEMAX (8G), inside the slice ttp.slice, capped at
# TTP_SLICEMAX (18G) for all slots together. Past a cap the kernel kills that
# command and what it started, not the desktop. Nesting past TTP_MAXDEPTH (8)
# stops with a message: a command that calls itself without end.

set -u
depth=$(( ${TTP_DEPTH:-0} + 1 ))
if test "$depth" -gt "${TTP_MAXDEPTH:-8}"; then
    echo "slot.sh: nested $depth deep, past TTP_MAXDEPTH: does a command call itself without end? $*" | cut -c1-300 >&2
    exit 3
fi
TTP_DEPTH=$depth; export TTP_DEPTH
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

# A timed command runs in a session of its own (setsid); when it ends, at its
# timeout or not, what is left of that session is killed. A process group is
# not enough: glibc's test driver forks the test into a group of its own
# (setpgid), and on 2026-10-22 such a child, reparented when timeout killed
# its qemu, ran 18 minutes past its timeout at full CPU. (pgrep -s 0: the
# processes of the session; $$ is the sh that waits.)
timed='t=$1; shift; timeout "$t" "$@"; s=$?
    for p in $(pgrep -s 0); do test "$p" = $$ || kill -9 "$p" 2> /dev/null; done
    exit $s'

run() {
    test -n "$mem" && { ulimit -v "$mem" || exit 2; }
    if test -n "$secs"; then exec setsid -w sh -c "$timed" timed "$secs" "$@"; else exec "$@"; fi
}

# the scope of a command that takes a slot: its own cap, in ttp.slice, whose
# cap covers all slots (set once, persistent in ~/.config/systemd/user.control)
scoped() {
    if command -v systemd-run > /dev/null && systemctl --user show-environment > /dev/null 2>&1; then
        if test "$(systemctl --user show ttp.slice -p MemoryMax --value 2> /dev/null)" = infinity; then
            systemctl --user set-property ttp.slice MemoryMax="${TTP_SLICEMAX:-18G}" MemorySwapMax=0 2> /dev/null
        fi
        test -n "$mem" && { ulimit -v "$mem" || exit 2; }
        # (timed inside the scope; systemd-run would read the $ of a command
        # as its environment variables, and $$ as $)
        test -n "$secs" && set -- setsid -w sh -c "$timed" timed "$secs" "$@"
        set -- systemd-run --user --scope --quiet --collect --expand-environment=no --slice=ttp.slice \
            -p MemoryMax="${TTP_SCOPEMAX:-8G}" -p MemorySwapMax=0 -- "$@"
        exec "$@"
    fi
    echo "slot.sh: no systemd user session, so no memory scope: $*" | cut -c1-200 >&2
    run "$@"
}

test -n "${TTP_SLOT:-}" && run "$@"

dir=${TTP_SLOTS:-$HOME/.cache/ttp}
n=${TTP_NSLOTS:-3}
mkdir -p "$dir"
waited=
start=$(date +%s)
while :; do
    i=1
    while test $i -le $n; do
        exec 9>> "$dir/slot.$i"
        if flock -n 9; then
            test -n "$waited" && echo "slot.sh: got slot $i" >&2
            test -n "${TTP_SLOTLOG:-}" && echo "$(( $(date +%s) - start )) $*" | cut -c1-200 >> "$TTP_SLOTLOG"
            TTP_SLOT=$i; export TTP_SLOT
            scoped "$@"
        fi
        exec 9>&-
        i=$((i + 1))
    done
    test -n "$waited" || { echo "slot.sh: all $n slots busy, waiting" >&2; waited=1; }
    sleep 1
done
