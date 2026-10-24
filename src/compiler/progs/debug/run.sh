#!/bin/sh
# run.sh TARGET OUTDIR: ttpc -g (gen/patches/debug.pl, ehframe.pl) for TARGET,
# checked with the tools that read it. progs/cdebug.ff, and ctls, csection
# and cdatasep (a TLS image, a named section, a round of globals):
# - without -g there are no section headers (the bytes as before);
# - readelf: the sections of each part; every symbol's name and address are
#   a label of ttpc's listing; cdebug's functions FUNC and sized, its
#   globals OBJECT; objdump -d starts deep where its symbol says;
# - .eh_frame (riscv64, x86_64, aarch64) and .ARM.exidx (arm) as readelf
#   reads them, PT_GNU_EH_FRAME (and PT_ARM_EXIDX);
# - gdb (natively on x86_64, under qemu -g elsewhere): at nohook, bt names
#   nohook deep deep vdeep deep deep _start;
# - libgcc's unwinder: progs/debug/unwind.c, by gcc against glibc's libc.a
#   (GLIBC_REF, src/glibc's reference build), walks gcc deep deep vdeep
#   deep deep gcc.
# Needs the dev shell (GLIBC_CC_<target>) and stage2 as TTPC.
set -e
t=$1 o=$2
here=$(cd "$(dirname "$0")" && pwd)
c=$here/../..
ref=${GLIBC_REF:-$HOME/.cache/ttp/glibc-gcc16}
case $t in
riscv64) cc=$GLIBC_CC; obj=$ref/obj; q=qemu-riscv64; x=riscv64-none-elf-; ga=riscv:rv64;;
x86_64) cc=$GLIBC_CC_x86_64; obj=$ref/x86_64/obj; q=; x=x86_64-elf-; ga=i386:x86-64;;
aarch64) cc=$GLIBC_CC_aarch64; obj=$ref/aarch64/obj; q=qemu-aarch64; x=aarch64-none-elf-; ga=aarch64;;
arm) cc=$GLIBC_CC_arm; obj=$ref/arm/obj; q=qemu-arm; x=arm-none-eabi-; ga=arm;;
*) echo "run.sh: no target $t"; exit 1;;
esac
fail() { echo "debug-$t: $*"; exit 1; }
ulimit -v 8000000
mkdir -p "$o"
for p in cdebug ctls csection cdatasep; do
    (cd "$c" && timeout 120 $TTPC --target $t shared.ff progs/$p.ff "$o/$p" > "$o/$p.lst" && timeout 120 $TTPC -g --target $t shared.ff progs/$p.ff "$o/$p.g" > "$o/$p.g.lst")
    readelf -h "$o/$p" | grep -q "Number of section headers: *0$" || fail "$p without -g has section headers"
    readelf -SW "$o/$p.g" > "$o/$p.sections"
    readelf -sW "$o/$p.g" > "$o/$p.symbols"
    for s in .text .symtab .strtab .shstrtab; do grep -q " $s " "$o/$p.sections" || fail "$p: no $s"; done
    # every symbol a label of the listing, at its address
    awk 'NR == FNR { if ($2 ~ /:$/) l[$1 " " substr($2, 1, length($2) - 1)] = 1; next }
        $1 ~ /^[0-9]+:$/ && $7 != "UND" && $8 !~ /^__st(art|op)_/ { a = sprintf("%016s", $2); gsub(/ /, "0", a); if (!((a " " $8) in l)) { print "not in the listing: " $0; bad = 1 } n++ }
        END { exit bad || !n }' "$o/$p.g.lst" "$o/$p.symbols" || fail "$p: symbols and listing differ"
done
grep -q " \.data " "$o/cdebug.sections" || fail "cdebug: no .data"
grep -q " \.tdata " "$o/ctls.sections" || fail "ctls: no .tdata"
grep -q " impls " "$o/csection.sections" || fail "csection: no section impls"
for b in __start_impls __stop_impls; do grep -q " $b$" "$o/csection.symbols" || fail "csection: no $b"; done
grep -q " \.data " "$o/cdatasep.sections" || fail "cdatasep: no .data"
for f in deep vdeep nohook _start; do grep -Eq " [1-9][0-9]* FUNC +GLOBAL +DEFAULT +[0-9]+ $f\$" "$o/cdebug.symbols" || fail "cdebug: $f is no sized FUNC"; done
for g in hook count; do grep -Eq " OBJECT +GLOBAL +DEFAULT +[0-9]+ $g\$" "$o/cdebug.symbols" || fail "cdebug: $g is no OBJECT"; done
d=$(awk '$8 == "deep" { print $2 }' "$o/cdebug.symbols" | sed 's/^0*//')
${x}objdump -d "$o/cdebug.g" | grep -Eq "^0*$d <deep>:" || fail "objdump -d does not start deep at $d"
readelf -lW "$o/cdebug.g" | grep -q GNU_EH_FRAME || fail "no PT_GNU_EH_FRAME"
readelf -wf "$o/cdebug.g" > "$o/cdebug.frames"
test "$(grep -c " FDE " "$o/cdebug.frames")" -ge 4 || fail "cdebug: fewer than 4 FDEs"
grep -q "Entries in search table: 0x[4-9]" "$o/cdebug.frames" || fail "cdebug: .eh_frame_hdr's table"
if test $t = arm; then
    readelf -lW "$o/cdebug.g" | grep -q ARM_EXIDX || fail "no PT_ARM_EXIDX"
    readelf -u "$o/cdebug.g" | grep -A3 "<deep>:" | grep -q "vsp = r11" || fail ".ARM.exidx: deep"
fi
# gdb's backtrace from nohook
printf 'set pagination off\nset confirm off\nset architecture %s\n%s\nbreak nohook\n%s\nbt\nkill\n' $ga \
    "$(test -n "$q" && echo "target remote :PORT")" "$(test -n "$q" && echo continue || echo run)" > "$o/bt.gdb"
if test -n "$q"; then
    port=$((20000 + $$ % 20000))
    sed -i "s/PORT/$port/" "$o/bt.gdb"
    timeout 60 $q -g $port "$o/cdebug.g" > /dev/null 2>&1 &
    sleep 1
fi
timeout 60 gdb -q -batch -nx -x "$o/bt.gdb" "$o/cdebug.g" > "$o/bt.out" 2>&1 || :
wait
grep "^#" "$o/bt.out" | sed 's/.* in \([^ ]*\) .*/\1/' | paste -sd' ' > "$o/bt.names"
test "$(cat "$o/bt.names")" = "nohook deep deep vdeep deep deep _start" || { cat "$o/bt.out"; fail "gdb's bt: $(cat "$o/bt.names")"; }
# libgcc's unwinder
test -f "$obj/libc.a" || fail "no glibc reference build in $obj (make -C src/glibc glibc-ref)"
"$cc" -O1 -funwind-tables -c "$here/unwind.c" -o "$o/unwind.o"
"$cc" -static -nostdlib -Wl,-Ttext-segment=0x20000000 -o "$o/unwind" "$obj/csu/crt1.o" "$obj/csu/crti.o" "$("$cc" -print-file-name=crtbeginT.o)" "$o/unwind.o" \
    -Wl,--start-group "$obj/libc.a" -lgcc -lgcc_eh -Wl,--end-group "$("$cc" -print-file-name=crtend.o)" "$obj/csu/crtn.o"
timeout 20 $q "$o/unwind" "$o/cdebug.g" | paste -sd' ' > "$o/unwind.out"
test "$(cat "$o/unwind.out")" = "gcc deep deep vdeep deep deep gcc deep 3: 10" || fail "libgcc's walk: $(cat "$o/unwind.out")"
echo "debug-$t: sections, symbols as the listing, objdump, frames; gdb: $(cat "$o/bt.names"); libgcc: $(cat "$o/unwind.out")"
