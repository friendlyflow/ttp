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
#   deep deep gcc;
# - the line table (.debug_line, gen/patches/dwarfline.pl): gdb's break
#   deep and break progs/cdebug.ff.txt:53 stop at the lines of the tree's
#   text (fftext.pl txt) that start deep's first statement and the return
#   at 53, list shows those lines, and addr2line gives the same file and
#   line for each address gdb stops at; the C view the same for
#   progs/cline.ff, its line nodes progs/debug/cline.c's lines, whose bytes
#   without -g are the tree's without them.
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
grep "^#" "$o/bt.out" | sed -E 's/^#[0-9]+ +(0x[0-9a-f]+ in )?([^ ]+) .*/\2/' | paste -sd' ' > "$o/bt.names"
test "$(cat "$o/bt.names")" = "nohook deep deep vdeep deep deep _start" || { cat "$o/bt.out"; fail "gdb's bt: $(cat "$o/bt.names")"; }
# libgcc's unwinder
test -f "$obj/libc.a" || fail "no glibc reference build in $obj (make -C src/glibc glibc-ref)"
"$cc" -O1 -funwind-tables -c "$here/unwind.c" -o "$o/unwind.o"
"$cc" -static -nostdlib -Wl,-Ttext-segment=0x20000000 -o "$o/unwind" "$obj/csu/crt1.o" "$obj/csu/crti.o" "$("$cc" -print-file-name=crtbeginT.o)" "$o/unwind.o" \
    -Wl,--start-group "$obj/libc.a" -lgcc -lgcc_eh -Wl,--end-group "$("$cc" -print-file-name=crtend.o)" "$obj/csu/crtn.o"
timeout 20 $q "$o/unwind" "$o/cdebug.g" | paste -sd' ' > "$o/unwind.out"
test "$(cat "$o/unwind.out")" = "gcc deep deep vdeep deep deep gcc deep 3: 10" || fail "libgcc's walk: $(cat "$o/unwind.out")"
# the line table: gdb's breakpoints by function and by line, list, addr2line
for s in .debug_abbrev .debug_info .debug_line; do grep -q " $s " "$o/cdebug.sections" || fail "cdebug: no $s"; done
mkdir -p "$o/progs"
perl "$c/gen/fftext.pl" txt "$c/progs/cdebug.ff" > "$o/progs/cdebug.ff.txt"
# lines PROG FILE TEXT FUNC LINE AT: gdb stops at FUNC at LINE of FILE (its
# first statement) and at AT, list shows those lines of TEXT, bt is at AT,
# addr2line names the file and line of each breakpoint as gdb does
lines() {
    p=$1 f=$2 txt=$3 fn=$4 l1=$5 l2=$6
    printf 'set pagination off\nset confirm off\nset architecture %s\ndirectory %s\ndirectory %s\n%s\nbreak %s\nbreak %s:%s\n%s\ninfo line *$pc\ndelete 1\ncontinue\ninfo line *$pc\nbt 1\nlist %s,%s\nlist %s,%s\nkill\n' $ga "$o" "$c" \
        "$(test -n "$q" && echo "target remote :PORT")" $fn $f $l2 "$(test -n "$q" && echo continue || echo run)" $l1 $l1 $l2 $l2 > "$o/$p.line.gdb"
    if test -n "$q"; then
        port=$((20000 + ($$ + 7) % 20000))
        sed -i "s/PORT/$port/" "$o/$p.line.gdb"
        timeout 60 $q -g $port "$o/$p.g" > /dev/null 2>&1 &
        sleep 1
    fi
    timeout 60 gdb -q -batch -nx -x "$o/$p.line.gdb" "$o/$p.g" > "$o/$p.line.out" 2>&1 || :
    wait
    for l in $l1 $l2; do
        grep -Eq "^Line $l of \"(\./)*$f\" (starts at|is at) address" "$o/$p.line.out" || { cat "$o/$p.line.out"; fail "$p: gdb does not stop at line $l of $f"; }
        grep -qF "$l	$(sed -n ${l}p "$txt")" "$o/$p.line.out" || { cat "$o/$p.line.out"; fail "$p: gdb's list $l is not line $l of $f"; }
    done
    grep -q "^#0 .*$fn .* at .*$f:$l2" "$o/$p.line.out" || { cat "$o/$p.line.out"; fail "$p: gdb's bt at line $l2"; }
    n=0
    for a in $(sed -n 's/^Breakpoint [0-9]* at \(0x[0-9a-f]*\): file .*/\1/p' "$o/$p.line.out"); do
        g=$(sed -n "s/^Breakpoint [0-9]* at $a: file \([^,]*\), line \([0-9]*\)\./\1:\2/p" "$o/$p.line.out" | norm)
        b=$(${x}addr2line -e "$o/$p.g" $a | norm)
        test "$g" = "$b" || fail "$p: addr2line $a: $b, gdb: $g"
        n=$((n + 1))
    done
    test $n = 2 || { cat "$o/$p.line.out"; fail "$p: gdb set $n breakpoints, not 2"; }
}
norm() { sed 's,^\(\./\)*,,'; }
# the ff view: cdebug's lines in its tree's text
lines cdebug progs/cdebug.ff.txt "$o/progs/cdebug.ff.txt" deep 42 53
# the C view: progs/cline.ff's line nodes, progs/debug/cline.c's lines;
# without -g the bytes of the tree without them
(cd "$c" && timeout 120 $TTPC --target $t shared.ff progs/cline.ff "$o/cline" > "$o/cline.lst" && timeout 120 $TTPC -g --target $t shared.ff progs/cline.ff "$o/cline.g" > "$o/cline.g.lst")
perl "$c/gen/fftext.pl" txt "$c/progs/cline.ff" | perl -0pe 's/^( *)line\n(?:\1  .*\n)+//mg' > "$o/cline0.ff.txt"
! grep -q "^ *line$" "$o/cline0.ff.txt" || fail "cline: line nodes left"
perl "$c/gen/fftext.pl" ff "$o/cline0.ff.txt" > "$o/cline0.ff"
(cd "$c" && timeout 120 $TTPC --target $t shared.ff "$o/cline0.ff" "$o/cline0" > "$o/cline0.lst")
cmp "$o/cline" "$o/cline0" || fail "cline: its line nodes change its bytes without -g"
s=0; timeout 20 $q "$o/cline" || s=$?
test $s = 43 || fail "cline: exit $s, not 43"
lines cline progs/debug/cline.c "$c/progs/debug/cline.c" twice 14 15
lines cline progs/debug/cline.c "$c/progs/debug/cline.c" add3 20 22
# c2ff writes those line nodes of cline.c (riscv64: one clang AST does)
if test $t = riscv64 && test -n "$C2FF_CLANG"; then
    mkdir -p "$o/c2ff"
    cp "$c/progs/debug/cline.c" "$o/c2ff/"
    (cd "$o/c2ff" && $C2FF_CLANG -E cline.c -o cline.i && $C2FF_CLANG -x c -include "$c/../glibc/clang-prelude.h" -Xclang -ast-dump=json \
        -fsyntax-only --target=riscv64-linux-gnu -std=gnu11 -w cline.i > cline.json)
    (cd "$o/c2ff" && perl "$c/gen/c2ff.pl" cline.json=cline.i -- add3 > cline.ff.txt)
    # (each function's line nodes, a file by its name)
    lns() { perl -ne 'chomp; if (/^ *(twice|add3|_start):$/) { $f = $1; next } if (/^( *)line$/) { $d = length $1; $l = 1; print "\n$f"; next } if ($l && /^( *)(.*)$/ && length $1 > $d) { (my $x = $2) =~ s{.*/}{}; print " $x"; next } $l = 0; END { print "\n" }' "$1" | grep . | sort -s -k1,1; }
    perl "$c/gen/fftext.pl" txt "$c/progs/cline.ff" > "$o/c2ff/want.ff.txt"
    lns "$o/c2ff/want.ff.txt" | grep -v "^_start" > "$o/c2ff/want.lines"
    lns "$o/c2ff/cline.ff.txt" > "$o/c2ff/got.lines"
    cmp "$o/c2ff/want.lines" "$o/c2ff/got.lines" || { diff "$o/c2ff/want.lines" "$o/c2ff/got.lines"; fail "c2ff's line nodes of cline.c are not progs/cline.ff's"; }
fi
echo "debug-$t: sections, symbols as the listing, objdump, frames; gdb: $(cat "$o/bt.names"); libgcc: $(cat "$o/unwind.out"); lines: ff view (cdebug.ff.txt), C view (cline.c), list, addr2line; cline as without its line nodes$(test -f "$o/c2ff/got.lines" && echo ", as c2ff writes them")"
