#!/usr/bin/env perl
# mkwide.pl — writes progs/aarch64/wide.ff and wide.s from one table: every
# instruction of the aarch64 section at least once (immediates and offsets
# at the edges of their range), then the macros GNU as has as aliases. The
# two must assemble to the same bytes (see wide.s). It reads shared.ff to
# check that no instruction of the section is left out.
#
#   cd src/compiler && perl progs/aarch64/mkwide.pl
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../..";
use FF qw(node read_ff write_ff);

my $dir = $FindBin::Bin;
my @rows;                               # [ff tokens], gnu text
sub I { my ($ff, $gnu) = @_; push @rows, [[split " ", $ff], $gnu] }

my @cond = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le al nv);
my @W = (["", "x", 64], ["w", "w", 32]);    # name suffix, register prefix, bits

# --- data processing, immediate --------------------------------------------
for (@W) {
    my ($s, $r, $bits) = @$_;
    for my $m (qw(add adds sub subs)) {
        I("${m}i$s 4095 ${r}2 ${r}1", "$m ${r}1, ${r}2, #4095");
        I("${m}i$s.lsl12 16773120 ${r}4 ${r}3", "$m ${r}3, ${r}4, #4095, lsl #12");
    }
    my @masks = $bits == 64 ? ([1, 63, 62], [0, 1, 60], [1, 0, 0], [0, 0, 0b111100])
                            : ([0, 31, 30], [0, 3, 0b101100], [0, 0, 0], [0, 0, 0b111100]);
    my $k = 0;
    for my $m (qw(and orr eor ands)) {
        my ($n, $immr, $imms) = @{ $masks[$k++] };
        my $v = sprintf "0x%x", bitmask($n, $immr, $imms, $bits);
        I("${m}i$s " . ($bits == 64 ? "$n " : "") . "$immr $imms ${r}6 ${r}5", "$m ${r}5, ${r}6, #$v");
    }
    my $hw = $bits == 64 ? 3 : 1;
    I("movn$s $hw 65535 ${r}7", "movn ${r}7, #0xffff, lsl #" . 16 * $hw);
    I("movz$s 0 0 ${r}8", "movz ${r}8, #0, lsl #0");
    I("movk$s $hw 4660 ${r}9", "movk ${r}9, #0x1234, lsl #" . 16 * $hw);
    my $top = $bits - 1;
    I("sbfm$s $top 0 ${r}11 ${r}10", "sbfm ${r}10, ${r}11, #$top, #0");
    I("bfm$s 0 $top ${r}13 ${r}12", "bfm ${r}12, ${r}13, #0, #$top");
    I("ubfm$s 1 2 ${r}15 ${r}14", "ubfm ${r}14, ${r}15, #1, #2");
    I("extr$s ${r}18 $top ${r}17 ${r}16", "extr ${r}16, ${r}17, ${r}18, #$top");
}
I("addi 16 sp sp", "add sp, sp, #16");
I("subi 0 sp x29", "sub x29, sp, #0");
I("adr 1048575 x19", "adr x19, .+1048575");
I("adr -1048576 x20", "adr x20, .-1048576");
I("adrp 4294963200 x21", "adrp x21, .+4294963200");
I("adrp -4294967296 x22", "adrp x22, .-4294967296");

# --- data processing, register ---------------------------------------------
for (@W) {
    my ($s, $r, $bits) = @$_;
    my $top = $bits - 1;
    my $k = 0;
    for my $m (qw(add adds sub subs)) {
        I("$m$s ${r}3 ${r}2 ${r}1", "$m ${r}1, ${r}2, ${r}3");
        my $sh = $k % 3;
        I("$m$s.sh $sh ${r}6 $top ${r}5 ${r}4", "$m ${r}4, ${r}5, ${r}6, " . (qw(lsl lsr asr))[$sh] . " #$top");
        my $opt = (4, 5, 6, 0)[$k];
        I("$m$s.ext w9 $opt 4 ${r}8 ${r}7", "$m ${r}7, ${r}8, w9, " . (qw(uxtb uxth uxtw uxtx sxtb sxth sxtw sxtx))[$opt] . " #4");
        $k++;
    }
    I("add$s.ext ${r}10 " . ($bits == 64 ? 7 : 6) . " 0 ${r}11 ${r}12",
      "add ${r}12, ${r}11, ${r}10, " . ($bits == 64 ? "sxtx" : "sxtw"));
    $k = 0;
    for my $m (qw(and bic orr orn eor eon ands bics)) {
        I("$m$s ${r}15 ${r}14 ${r}13", "$m ${r}13, ${r}14, ${r}15");
        my $sh = $k % 4;
        I("$m$s.sh $sh ${r}18 $top ${r}17 ${r}16", "$m ${r}16, ${r}17, ${r}18, " . (qw(lsl lsr asr ror))[$sh] . " #$top");
        $k++;
    }
    for my $m (qw(adc adcs sbc sbcs)) {
        I("$m$s ${r}21 ${r}20 ${r}19", "$m ${r}19, ${r}20, ${r}21");
    }
    I("ccmn$s ${r}23 eq ${r}22 15", "ccmn ${r}22, ${r}23, #15, eq");
    I("ccmp$s ${r}25 nv ${r}24 0", "ccmp ${r}24, ${r}25, #0, nv");
    I("ccmni$s 31 al ${r}26 1", "ccmn ${r}26, #31, #1, al");
    I("ccmpi$s 0 15 ${r}27 8", "ccmp ${r}27, #0, #8, nv");
    my $c = 0;
    for my $m (qw(csel csinc csinv csneg)) {
        I("$m$s ${r}0 $cond[$c] ${r}30 ${r}28", "$m ${r}28, ${r}30, ${r}0, $cond[$c]");
        $c += 3;
    }
    my @one = qw(rbit rev16 clz cls rev);
    push @one, "rev32" if $bits == 64;
    I("$_$s ${r}2 ${r}1", "$_ ${r}1, ${r}2") for @one;
    I("$_$s ${r}5 ${r}4 ${r}3", "$_ ${r}3, ${r}4, ${r}5") for qw(udiv sdiv lslv lsrv asrv rorv);
    I("madd$s ${r}9 ${r}10 ${r}8 ${r}7", "madd ${r}7, ${r}8, ${r}9, ${r}10");
    I("msub$s ${r}13 ${r}14 ${r}12 ${r}11", "msub ${r}11, ${r}12, ${r}13, ${r}14");
}
I("$_ w3 x4 w2 x1", "$_ x1, w2, w3, x4") for qw(smaddl smsubl umaddl umsubl);
I("$_ x7 x6 x5", "$_ x5, x6, x7") for qw(smulh umulh);

# --- branches ---------------------------------------------------------------
I("b 134217724", "b .+134217724");
I("b -134217728", "b .-134217728");
I("bl 134217724", "bl .+134217724");
I("bl -134217728", "bl .-134217728");
for (0 .. 15) {
    my $off = $_ % 2 ? -1048576 : 1048572;
    I("b.$cond[$_] $off", "b.$cond[$_] ." . ($off < 0 ? "" : "+") . $off);
}
I("b.hs -4", "b.hs .-4");
I("b.lo 8", "b.lo .+8");
I("cbz 1048572 x1", "cbz x1, .+1048572");
I("cbnz -1048576 x2", "cbnz x2, .-1048576");
I("cbzw -1048576 w3", "cbz w3, .-1048576");
I("cbnzw 1048572 w4", "cbnz w4, .+1048572");
I("tbz 63 32764 x5", "tbz x5, #63, .+32764");
I("tbnz 0 -32768 w6", "tbnz w6, #0, .-32768");
I("tbz 31 -32768 w7", "tbz w7, #31, .-32768");
I("br x16", "br x16");
I("blr x17", "blr x17");
I("ret", "ret");
I("retr x18", "ret x18");

# --- system -----------------------------------------------------------------
I("svc 0", "svc #0");
I("hvc 65535", "hvc #0xffff");
I("smc 1", "smc #1");
I("brk 32768", "brk #0x8000");
I("hlt 61440", "hlt #0xf000");
I("$_", "$_") for qw(nop yield wfe wfi sev sevl clrex isb eret);
I("dsb 11", "dsb ish");
I("dmb 9", "dmb ishld");
I("dsb 15", "dsb sy");
I("mrs 56962 x1", "mrs x1, tpidr_el0");
I("msr 56962 x2", "msr tpidr_el0, x2");
I("mrs 65535 x3", "mrs x3, s3_7_c15_c15_7");

# --- loads and stores ---------------------------------------------------------
# name, register of rt, the bits an offset scales by
my @ls = (["strb", "w", 0], ["ldrb", "w", 0], ["ldrsb", "x", 0], ["ldrsbw", "w", 0],
          ["strh", "w", 1], ["ldrh", "w", 1], ["ldrsh", "x", 1], ["ldrshw", "w", 1],
          ["strw", "w", 2], ["ldrw", "w", 2], ["ldrsw", "x", 2],
          ["str", "x", 3], ["ldr", "x", 3],
          ["str.s", "s", 2], ["ldr.s", "s", 2], ["str.d", "d", 3], ["ldr.d", "d", 3]);
my $k = 0;
for (@ls) {
    my ($m, $r, $sc) = @$_;
    (my $g = $m) =~ s/\.[sd]$//;
    $g =~ s/^(ldrsb|ldrsh|ldr|str)w$/$1/;
    (my $u = $m) =~ s/^(ld|st)r/$1ur/;
    (my $gu = $g) =~ s/^(ld|st)r/$1ur/;
    my $max = 4095 << $sc;
    my $t = "${r}" . (1 + $k % 29);
    my $n = "x" . (2 + $k % 27);
    $n = "sp" if $k == 5;
    I("$m $max $n $t", "$g $t, [$n, #$max]");
    I("$m 0 $n $t", "$g $t, [$n]") if $k % 4 == 0;
    I("$m.pre -256 $n $t", "$g $t, [$n, #-256]!");
    I("$m.post 255 $n $t", "$g $t, [$n], #255");
    I("$u " . ($k % 2 ? -256 : 255) . " $n $t", "$gu $t, [$n, #" . ($k % 2 ? -256 : 255) . "]");
    my $mreg = "x" . (3 + $k % 26);
    I("$m.reg $mreg 3 1 $n $t", "$g $t, [$n, $mreg, lsl #$sc]");
    (my $wreg = $mreg) =~ s/x/w/;
    I("$m.reg $wreg 6 0 $n $t", "$g $t, [$n, $wreg, sxtw]");
    $k++;
}
I("ldr.reg x3 3 0 x2 x1", "ldr x1, [x2, x3]");
I("ldrb.reg w3 2 1 x2 w1", "ldrb w1, [x2, w3, uxtw #0]");
I("ldr.lit 1048572 x1", "ldr x1, .+1048572");
I("ldrw.lit -1048576 w2", "ldr w2, .-1048576");
I("ldrsw.lit 4 x3", "ldrsw x3, .+4");
I("ldr.s.lit -4 s4", "ldr s4, .-4");
I("ldr.d.lit 1048572 d5", "ldr d5, .+1048572");
# name, register prefix, the bits an offset scales by
$k = 0;
for (["stpw", "w", 2], ["ldpw", "w", 2], ["ldpsw", "x", 2], ["stp", "x", 3], ["ldp", "x", 3],
     ["stp.s", "s", 2], ["ldp.s", "s", 2], ["stp.d", "d", 3], ["ldp.d", "d", 3]) {
    my ($m, $r, $sc) = @$_;
    (my $g = $m) =~ s/\.[sd]$//;
    $g =~ s/^(ld|st)pw$/$1p/;
    my ($max, $min) = (63 << $sc, -64 * (1 << $sc));
    my ($t, $t2, $n) = ("$r" . (1 + $k), "$r" . (11 + $k), "x" . (21 + $k));
    I("$m $max $t2 $n $t", "$g $t, $t2, [$n, #$max]");
    I("$m.pre $min $t2 $n $t", "$g $t, $t2, [$n, #$min]!");
    I("$m.post $max $t2 $n $t", "$g $t, $t2, [$n], #$max");
    $k++;
}
I("stp.pre -16 x30 sp x29", "stp x29, x30, [sp, #-16]!");
I("ldp.post 16 x30 sp x29", "ldp x29, x30, [sp], #16");

# --- exclusives, acquire / release, LSE atomics -------------------------------
for (["b", "w"], ["h", "w"], ["w", "w"], ["", "x"]) {
    my ($s, $r) = @$_;
    my $g = $s eq "w" ? "" : $s;
    I("stxr$s w1 x3 ${r}2", "stxr$g w1, ${r}2, [x3]");
    I("stlxr$s w4 sp ${r}5", "stlxr$g w4, ${r}5, [sp]");
    I("ldxr$s x7 ${r}6", "ldxr$g ${r}6, [x7]");
    I("ldaxr$s x9 ${r}8", "ldaxr$g ${r}8, [x9]");
    I("stlr$s x11 ${r}10", "stlr$g ${r}10, [x11]");
    I("ldar$s x13 ${r}12", "ldar$g ${r}12, [x13]");
}
for (["w", "w"], ["", "x"]) {
    my ($s, $r) = @$_;
    I("stxp$s w1 ${r}3 x4 ${r}2", "stxp w1, ${r}2, ${r}3, [x4]");
    I("stlxp$s w5 ${r}7 x8 ${r}6", "stlxp w5, ${r}6, ${r}7, [x8]");
    I("ldxp$s ${r}10 x11 ${r}9", "ldxp ${r}9, ${r}10, [x11]");
    I("ldaxp$s ${r}13 x14 ${r}12", "ldaxp ${r}12, ${r}13, [x14]");
}
$k = 0;
for my $m (qw(ldadd ldclr ldeor ldset ldsmax ldsmin ldumax ldumin swp cas)) {
    for my $o ("", "a", "l", "al") {
        for (["b", "w"], ["h", "w"], ["w", "w"], ["", "x"]) {
            my ($s, $r) = @$_;
            my $g = $s eq "w" ? "" : $s;
            my ($rs, $rt, $rn) = ("${r}" . ($k % 30), "${r}" . (($k + 7) % 30), "x" . (($k + 13) % 30));
            I("$m$o$s $rs $rn $rt", "$m$o$g $rs, $rt, [$rn]");
            $k++;
        }
    }
}

# --- floating point -------------------------------------------------------------
for my $p (qw(s d)) {
    I("$_.$p ${p}2 ${p}1", "$_ ${p}1, ${p}2")
        for qw(fmov fabs fneg fsqrt frintn frintp frintm frintz frinta frintx frinti);
    I("fmovi.$p " . ($p eq "s" ? "63 s3" : "255 d3"), "fmov ${p}3, #" . ($p eq "s" ? "31.0" : "-1.9375"));
    I("fmovi.$p 112 ${p}4", "fmov ${p}4, #1.0");
    I("$_.$p ${p}7 ${p}6 ${p}5", "$_ ${p}5, ${p}6, ${p}7")
        for qw(fmul fdiv fadd fsub fmax fmin fmaxnm fminnm fnmul);
    I("$_.$p ${p}10 ${p}11 ${p}9 ${p}8", "$_ ${p}8, ${p}9, ${p}10, ${p}11")
        for qw(fmadd fmsub fnmadd fnmsub);
    I("fcmp.$p ${p}13 ${p}12", "fcmp ${p}12, ${p}13");
    I("fcmpe.$p ${p}15 ${p}14", "fcmpe ${p}14, ${p}15");
    I("fcmpz.$p ${p}16", "fcmp ${p}16, #0.0");
    I("fcmpez.$p ${p}17", "fcmpe ${p}17, #0.0");
    I("fccmp.$p ${p}19 ne ${p}18 15", "fccmp ${p}18, ${p}19, #15, ne");
    I("fccmpe.$p ${p}21 nv ${p}20 0", "fccmpe ${p}20, ${p}21, #0, nv");
    I("fcsel.$p ${p}24 lt ${p}23 ${p}22", "fcsel ${p}22, ${p}23, ${p}24, lt");
    for my $r (qw(w x)) {
        I("$_.$p.$r ${r}26 ${p}25", "$_ ${p}25, ${r}26") for qw(scvtf ucvtf);
        I("$_.$r.$p ${p}28 ${r}27", "$_ ${r}27, ${p}28")
            for qw(fcvtns fcvtnu fcvtas fcvtau fcvtps fcvtpu fcvtms fcvtmu fcvtzs fcvtzu);
    }
}
I("fcvt.d.s s30 d29", "fcvt d29, s30");
I("fcvt.s.d d31 s0", "fcvt s0, d31");
I("fmov.s.w w1 s2", "fmov s2, w1");
I("fmov.w.s s3 w4", "fmov w4, s3");
I("fmov.d.x x5 d6", "fmov d6, x5");
I("fmov.x.d d7 x8", "fmov x8, d7");

# --- macros that GNU as has as aliases ------------------------------------------
I("mov x2 x1", "mov x1, x2");
I("movw w4 w3", "mov w3, w4");
I("mov.sp sp x5", "mov x5, sp");
I("mvn x7 x6", "mvn x6, x7");
I("mvnw w9 w8", "mvn w8, w9");
I("neg x11 x10", "neg x10, x11");
I("negw w13 w12", "neg w12, w13");
I("negs x15 x14", "negs x14, x15");
I("cmp x17 x16", "cmp x16, x17");
I("cmpw w19 w18", "cmp w18, w19");
I("cmpi 4095 x20", "cmp x20, #4095");
I("cmpiw 0 w21", "cmp w21, #0");
I("cmn x23 x22", "cmn x22, x23");
I("cmnw w25 w24", "cmn w24, w25");
I("cmni 1 x26", "cmn x26, #1");
I("cmniw 7 w27", "cmn w27, #7");
I("tst x1 x28", "tst x28, x1");
I("tstw w3 w2", "tst w2, w3");
I("tsti 1 0 7 x4", "tst x4, #0xff");
I("lsl 1 x6 x5", "lsl x5, x6, #1");
I("lsl 63 x6 x5", "lsl x5, x6, #63");
I("lslw 31 w8 w7", "lsl w7, w8, #31");
I("lsr 63 x10 x9", "lsr x9, x10, #63");
I("lsrw 1 w12 w11", "lsr w11, w12, #1");
I("asr 3 x14 x13", "asr x13, x14, #3");
I("asrw 31 w16 w15", "asr w15, w16, #31");
I("ror 17 x18 x17", "ror x17, x18, #17");
I("rorw 5 w20 w19", "ror w19, w20, #5");
I("sxtb w22 x21", "sxtb x21, w22");
I("sxth w24 x23", "sxth x23, w24");
I("sxtw w26 x25", "sxtw x25, w26");
I("uxtb w28 w27", "uxtb w27, w28");
I("uxth w1 w0", "uxth w0, w1");
I("uxtw w3 w2", "mov w2, w3");
I("mul x6 x5 x4", "mul x4, x5, x6");
I("mulw w9 w8 w7", "mul w7, w8, w9");
I("mneg x12 x11 x10", "mneg x10, x11, x12");
I("smull w15 w14 x13", "smull x13, w14, w15");
I("umull w18 w17 x16", "umull x16, w17, w18");
I("cset eq x19", "cset x19, eq");
I("csetm lt x20", "csetm x20, lt");
I("cinc hi x22 x21", "cinc x21, x22, hi");
I("cneg ge x24 x23", "cneg x23, x24, ge");
I("li 0x123456789abcdef0 x25", "movz x25, #0xdef0\n    movk x25, #0x9abc, lsl #16\n    movk x25, #0x5678, lsl #32\n    movk x25, #0x1234, lsl #48");
I("li -2 x26", "movz x26, #0xfffe\n    movk x26, #0xffff, lsl #16\n    movk x26, #0xffff, lsl #32\n    movk x26, #0xffff, lsl #48");
I("liw 0x80000001 w27", "movz w27, #1\n    movk w27, #0x8000, lsl #16");
I("la _start x28", "adrp x28, _start\n    add x28, x28, :lo12:_start");
I("j _start", "b _start");
I("call _start", "bl _start");

# DecodeBitMasks: the 64- or 32-bit value of a logical immediate.
sub bitmask {
    my ($n, $immr, $imms, $bits) = @_;
    my $len = 6;
    $len-- while $len > 0 && !((($n << 6) | (~$imms & 63)) >> $len & 1);
    my $esize = 1 << $len;
    my $s = $imms & ($esize - 1);
    my $r = $immr & ($esize - 1);
    my $mask = $esize == 64 ? ~0 : (1 << $esize) - 1;
    my $welem = $s + 1 == 64 ? ~0 : (1 << ($s + 1)) - 1;
    my $elem = $r ? (($welem >> $r) | ($welem << ($esize - $r))) & $mask : $welem;
    my $v = 0;
    $v |= $elem << $_ for grep { $_ % $esize == 0 } 0 .. $bits - 1;
    $bits == 64 ? $v : $v & 0xffffffff;
}

# Every instruction of the section is in the table.
open my $in, "<:raw", "$dir/../../shared.ff" or die "mkwide: shared.ff: $!\n";
my $root = read_ff(do { local $/; <$in> });
my ($shared) = @{ $root->{children} };
my ($section) = grep { $_->{content} eq "aarch64:" } @{ $shared->{children} };
die "mkwide: no aarch64: in shared.ff\n" unless $section;
my %used = map { $_->[0][0] => 1 } @rows;
my @missing;
for my $g (@{ $section->{children} }) {
    next unless $g->{content} =~ /^(integer|branch|system|memory|atomic|float):$/;
    for (@{ $g->{children} }) {
        (my $name = $_->{content}) =~ s/:$//;
        push @missing, $name unless $used{$name};
    }
}
die "mkwide: not in the table: @missing\n" if @missing;

# wide.ff: the program alone, laid out by itself as progs/wide.ff's last page.
my @prog = (node("comment", node("progs/aarch64/wide.ff, made by mkwide.pl: every instruction of the aarch64 section, offsets at the edges of their range, then macros. wide.s is its GNU twin.")),
    node("origin", node("elf_base")),
    node("elf_header", map { node($_) } qw(_start file_end mem_end)),
    blocks(),
    node("file_end:"), node("bss"), node("mem_end:"));
open my $ff, ">:raw", "$dir/wide.ff" or die "mkwide: wide.ff: $!\n";
print $ff write_ff(node("", @prog));
close $ff;

open my $s, ">", "$dir/wide.s" or die "mkwide: wide.s: $!\n";
print $s <<'EOF';
# wide.s — progs/aarch64/wide.ff for GNU as, made with it by mkwide.pl:
# every instruction of the aarch64 section, offsets at the edges of their
# range, then the macros GNU has as aliases. Assembled with
# -march=armv8.1-a (LSE), linked with ff.ld, its bytes must equal what
# ttpc --target aarch64 makes of wide.ff after the 120-byte ELF header.
    .globl _start
_start:
EOF
print $s "    $_->[1]\n" for @rows;
close $s;
printf "mkwide: %d lines\n", scalar @rows;

# A node holds at most 255 children: _start and then wide1, wide2, ...,
# labels placed one after the other, 200 instructions each.
sub blocks {
    my @b;
    for (my $i = 0; $i < @rows; $i += 200) {
        my @part = @rows[$i .. ($i + 199 < $#rows ? $i + 199 : $#rows)];
        push @b, node(($i ? "wide" . $i / 200 : "_start") . ":",
            map { my ($n, @a) = @{ $_->[0] }; node($n, map { node($_) } @a) } @part);
    }
    @b;
}
