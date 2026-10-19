# isa/x86_64gnu.pl — the forms of x86_64 that GNU as picks, for glibc's
# asm (s2ff), loaded by isa/x86_64.pl into its section. ttpc's own forms
# (isa/x86_64.pl) have one fixed size each, always with REX and with SIB
# and disp32 for memory; GNU as takes the shortest encoding, and glibc's
# bytes are its. Here each encoding is a form of its own, named for it
# (the user's scheme, 2026-10-19), and s2ff names the one whose bytes GNU
# as made:
#
#   mnemonic [. length] [. encoding] [. marks] . operands
#
#   length      VEX and EVEX only: 128 256 512
#   encoding    n: legacy without REX (no part: legacy with REX, as ttpc's
#               own forms); vex2, vex3, evex
#   marks       rev: the store opcode of a move, its operands swapped in
#               ModRM; k, kz, b: EVEX's merge mask, zeroing, broadcast
#   operands    as ttpc's own (i i8 r 1 cl ...), the memory operand a
#               letter and its displacement's size:
#                 m0 m8 m32   disp(base), no SIB
#                 s0 s8 s32   disp(base) with a SIB (base rsp or r12)
#                 x0 x8 x32   disp(base,index,scale)
#                 p           label(%rip)
#                 a32         an absolute disp32 (%fs:0x10, with fs first)
#
#   movq.m8 / 8 / rdi / rax          48 8b 47 08
#   movl.n / esi / eax               89 f0
#   movl.n.s8 / 8 / rsp / eax        8b 44 24 08
#
# The names ttpc's own forms have (a form with REX of registers only,
# .p) are theirs: their bytes are the same. In a form without REX every
# register is one of the first eight (checked: its fields take 3 bits),
# and a byte register 4..7 is ah ch dh bh.
#
# The groups are named gnu ...: trim.pl leaves them out of the shared page
# the frozen links (ttpc1, ttpc2) read, which do not assemble glibc.
# progs/x86_64/mkgnu.pl reads @main::X86_GNU, filled here as @X86_WIDE is,
# and writes the GNU twin of every form (make x86gnu).
#
# Loaded by isa/x86_64.pl (do), with its $isa ($main::X86_ISA) and helpers.

use strict;
use warnings;
use FF qw(node);

our (@X86_GNU, $X86_ISA, %X86_HAVE);
my $isa = $X86_ISA;

# A form of this file: in the current group, and its twin's line.
sub gform {
    my ($name, $params, $gnu, @body) = @_;
    return if $X86_HAVE{$name}++;
    my @names = map { (split /:/)[0] } @$params;
    push @{ $isa->{current}{children} }, node("$name:", (map { node($_) } @names), @body);
    push @X86_GNU, [$name, [@$params], $gnu];
}

# ---------------------------------------------------------------------------
# encodings: ModRM and SIB with the register fields checked to 3 bits (a
# form without REX), a SIB of its own (any mod), rel32 before an immediate
# ---------------------------------------------------------------------------

$isa->group("gnu encodings");
$isa->add("gnu encodings", node("comment",
    node("modrm.n mod reg rm: a ModRM byte whose reg and rm are among the first eight registers (a form without REX: checked). sib scale index base: a SIB byte, scale 1 2 4 8, index 100 for none; sib.n the same, checked."),
    node("rel32.1 target, rel32.2, rel32.4: target - the end of an instruction whose rel32 field at pc has 1, 2 or 4 bytes of immediate after it.")));
$isa->def("modrm.n", "mod[1:0]", "reg[2:0]", "rm[2:0]");
$isa->def("sib", "scale'[1:0]", "index'[2:0]", "base'[2:0]");
$isa->def("sib.n", "scale'[1:0]", "index[2:0]", "base[2:0]");
$isa->add("gnu encodings",
    map { node("rel32.$_:", node("target"), C("sub", "pc", "target", "a0"), C("addi", -4 - $_, "a0", "a0")) } 1, 2, 4);
$isa->add("gnu encodings", node("comment",
    node("acc op r: the opcode op of a form whose register must be the accumulator (al ax eax rax: 0), with r 256 times over it: byte takes it only when r is 0. accr op r s: the same, op with s's low 3 bits in its own (xchg's 90+r).")),
    node("acc:", node("op"), node("r"), C("slli", 8, "r", "t0"), C("addi", "op", "t0", "a0")),
    node("accr:", node("op"), node("r"), node("s"), C("slli", 8, "r", "t0"), C("andi", 7, "s", "t1"), C("add", "t1", "t0", "t0"), C("addi", "op", "t0", "a0")));

# ---------------------------------------------------------------------------
# the parts of a legacy form: prefixes, REX (or none), opcode, ModRM, SIB,
# displacement
# ---------------------------------------------------------------------------

# The memory operands: their parameters, GNU's spelling, and the twin's
# kinds of value (mkgnu.pl): a base for m0 is none of rsp rbp r12 r13, for
# m8 m32 not rsp r12, for s rsp or r12; an index never rsp.
my %MEM = (
    m0  => { p => [qw(disp:d0 base:bm0)],  g => "<disp>(<base>)", mod => 0, sib => 0, d => 0 },
    m8  => { p => [qw(disp:d8 base:bm)],   g => "<disp>(<base>)", mod => 1, sib => 0, d => 1 },
    m32 => { p => [qw(disp:d32 base:bm)],  g => "<disp>(<base>)", mod => 2, sib => 0, d => 4 },
    s0  => { p => [qw(disp:d0 base:bs)],   g => "<disp>(<base>)", mod => 0, sib => 1, d => 0 },
    s8  => { p => [qw(disp:d8 base:bs)],   g => "<disp>(<base>)", mod => 1, sib => 1, d => 1 },
    s32 => { p => [qw(disp:d32 base:bs)],  g => "<disp>(<base>)", mod => 2, sib => 1, d => 4 },
    x0  => { p => [qw(disp:d0 base:bx0 index:index scale:scale)], g => "<disp>(<base>,<index>,<scale>)", mod => 0, sib => 2, d => 0 },
    x8  => { p => [qw(disp:d8 base:base index:index scale:scale)], g => "<disp>(<base>,<index>,<scale>)", mod => 1, sib => 2, d => 1 },
    x32 => { p => [qw(disp:d32 base:base index:index scale:scale)], g => "<disp>(<base>,<index>,<scale>)", mod => 2, sib => 2, d => 4 },
    p   => { p => [qw(target:label)],      g => "<target>(%rip)", rip => 1 },
    a32 => { p => [qw(disp:d32)],          g => "<disp>",         abs => 1 },
);
my @MEMS = qw(m0 m8 m32 s0 s8 s32 x0 x8 x32 p a32);

# ModRM (and SIB, displacement) for reg (a register operand or a digit)
# and the memory operand m; $n: no REX (checked fields); $imm: the bytes
# of an immediate after it (for p).
sub gmem {
    my ($m, $reg, $n, $imm) = @_;
    my $d = $MEM{$m};
    my ($mr, $sb) = $n ? ("modrm.n", "sib.n") : ("modrm", "sib");
    if ($d->{rip}) {
        my $rel = $imm ? C("rel32.$imm", "target") : C("rel32", "target");
        return (C($mr, 0, $reg, 5), C("word", $rel));
    }
    return (C($mr, 0, $reg, 4), C($sb, 1, 4, 5), C("word", "disp")) if $d->{abs};
    my @b;
    if ($d->{sib} == 0)    { push @b, C($mr, $d->{mod}, $reg, "base") }
    elsif ($d->{sib} == 1) { push @b, C($mr, $d->{mod}, $reg, 4), C($sb, 1, 4, "base") }
    else                   { push @b, C($mr, $d->{mod}, $reg, 4), C($sb, "scale", "index", "base") }
    push @b, C("simm8", "disp") if $d->{d} == 1;
    push @b, C("word", "disp") if $d->{d} == 4;
    @b;
}
# REX for reg and the memory operand (W, R, X, B)
sub grex {
    my ($w, $reg, $m) = @_;
    my $d = $MEM{$m};
    return C("rex", $w, $reg, 0, 0) if $d->{rip} || $d->{abs};
    return C("rex", $w, $reg, $d->{sib} == 2 ? "index" : 0, "base");
}

# Sizes as isa/x86_64.pl has them: prefixes, REX.W, the low opcode bit,
# the immediate's bytes; the twin's kinds of register and immediate.
my %SZ = (
    b => { pre => [],     w => 0, lo => 0, isz => 1, ik => "ib" },
    w => { pre => [0x66], w => 0, lo => 1, isz => 2, ik => "i16" },
    l => { pre => [],     w => 0, lo => 1, isz => 4, ik => "i32" },
    q => { pre => [],     w => 1, lo => 1, isz => 4, ik => "i32" },
);
sub gimm { my ($n, $p) = @_; $p //= "imm"; C({ 1 => "byte", 2 => "half", 4 => "word" }->{$n}, $p) }
sub gbytes { map { C("byte", hex2($_)) } @_ }

# The register kinds of the twin: size, then lo (one of the first eight),
# hi (r8 and up), or any.
sub rk { my ($s, $c) = @_; "$s.$c" }

# One legacy instruction in all its forms. %o:
#   nm      the name (with its size suffix, b w l q), gnu its GNU mnemonic
#   s       size (b w l q), pre the mandatory prefixes, op the opcode bytes
#   kind    RM (reg <- r/m: rs rd), MR (r/m <- reg), M (one r/m operand,
#           reg the digit), MI (r/m and an immediate), RMI (reg, r/m and
#           an immediate: imul, pshufd)
#   digit   ModRM.reg for M and MI; ik/isz the immediate's kind and bytes
#   rk/mk   the kinds of the reg operand and of the r/m register (default
#           the size's), osfx the part after the memory letter (r for MR,
#           i i8 1 cl ...), rsfx a reg-reg form's own operand part
#   mem     0: no memory forms (a register-only instruction); regonly 0:
#           no register forms (lea)
sub legacy {
    my (%o) = @_;
    my $s = $o{s};
    my $z = $SZ{$s};
    my $nm = $o{nm};
    my $gnu = $o{gnu} // $nm;
    my @pre = (@{ $z->{pre} }, @{ $o{pre} // [] });
    my @op = @{ $o{op} };
    my $w = $o{w} // $z->{w};
    my $kind = $o{kind};
    my ($rk, $mk) = ($o{rk} // $s, $o{mk} // $s);
    my ($ik, $isz) = ($o{ik}, $o{isz});
    my $osfx = $o{osfx} // { RM => "", MR => "r", M => "", MI => "i", RMI => "" }->{$kind};
    my @imm = defined $isz ? ($isz == 1 && $ik eq "i8" ? C("simm8", "imm") : gimm($isz)) : ();
    my $ig = defined $isz ? "\$<imm>, " : "";
    for my $n (0, 1) {
        next if $n && $w;                      # W needs REX
        my $cls = $n ? "lo" : "hi";
        my $ns = $n ? ".n" : "";
        # registers only
        if ($o{regonly} // 1) {
            my ($name, @p, @b, $g);
            my $rs = $o{rsfx} // ($osfx eq "r" ? "" : $osfx);
            $name = "$nm$ns" . ($rs ne "" ? ".$rs" : "");
            if ($kind eq "M" || $kind eq "MI") {
                @p = (($kind eq "MI" ? "imm:$ik" : ()), "rd:" . rk($mk, $cls));
                @b = (($n ? () : C("rex", $w, 0, 0, "rd")), gbytes(@op), C($n ? "modrm.n" : "modrm", 3, $o{digit}, "rd"));
                $g = "$gnu $ig" . ($o{gx} // "") . "<rd>";
            } elsif ($kind eq "MR") {
                @p = ("rs:" . rk($rk, $cls), "rd:" . rk($mk, $n ? "lo" : "any"));
                @b = (($n ? () : C("rex", $w, "rs", 0, "rd")), gbytes(@op), C($n ? "modrm.n" : "modrm", 3, "rs", "rd"));
                $g = "$gnu <rs>, <rd>";
            } else {   # RM, RMI
                @p = (($kind eq "RMI" ? "imm:$ik" : ()), "rs:" . rk($mk, $cls), "rd:" . rk($rk, $n ? "lo" : "any"));
                @b = (($n ? () : C("rex", $w, "rd", 0, "rs")), gbytes(@op), C($n ? "modrm.n" : "modrm", 3, "rd", "rs"));
                $g = "$gnu $ig<rs>, <rd>";
            }
            unshift @b, gbytes(@pre);
            gform($name, \@p, $g, @b, @imm);
        }
        next if defined $o{mem} && !$o{mem};
        for my $m (@MEMS) {
            my $d = $MEM{$m};
            # (a REX form of a memory operand with no register, of no W:
            # GNU as gives it no REX)
            next if !$n && !$w && $kind =~ /^(M|MI)$/ && ($d->{rip} || $d->{abs});
            my @mp = @{ $d->{p} };
            # without REX the base and index are among the first eight
            if ($n) { @mp = map { /^(base|index):/ ? "$_.lo" : $_ } @mp }
            elsif (!$w && $kind =~ /^(M|MI)$/) { @mp = map { /^base:/ ? "$_.hi" : $_ } @mp }
            my $name = "$nm$ns.$m$osfx";
            my $reg = $kind =~ /^(M|MI)$/ ? $o{digit} : $kind eq "MR" ? "rs" : "rd";
            my @p = $kind eq "MR" ? ("rs:" . rk($rk, $cls), @mp)
                  : $kind =~ /^(M|MI)$/ ? (($kind eq "MI" ? "imm:$ik" : ()), @mp)
                  : (($kind eq "RMI" ? "imm:$ik" : ()), @mp, "rd:" . rk($rk, $cls));
            # (a rex form whose only register is the reg operand, rip or
            # absolute memory, needs it high: GNU gives no REX for nothing)
            my $g = $kind eq "MR" ? "$gnu <rs>, $d->{g}" : $kind =~ /^(M|MI)$/ ? "$gnu $ig" . ($o{gx} // "") . $d->{g} : "$gnu $ig$d->{g}, <rd>";
            my $rr = $kind =~ /^(M|MI)$/ ? 0 : $reg;
            gform($name, \@p, $g, gbytes(@pre), ($n ? () : grex($w, $rr, $m)), gbytes(@op), gmem($m, $reg, $n, scalar @imm ? $isz : 0), @imm);
        }
    }
}

# ---------------------------------------------------------------------------
# the integer instructions glibc's asm has
# ---------------------------------------------------------------------------

$isa->group("gnu alu");
my @alu = qw(add or adc sbb and sub xor cmp);
for my $k (0 .. 7) {
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        my $nm = "$alu[$k]$s";
        legacy(nm => $nm, s => $s, op => [8 * $k + $z->{lo}], kind => "MR");
        legacy(nm => $nm, s => $s, op => [8 * $k + 2 + $z->{lo}], kind => "RM", mem => 1, regonly => 0);
        legacy(nm => $nm, s => $s, op => [$s eq "b" ? 0x80 : 0x81], kind => "MI", digit => $k, ik => $z->{ik}, isz => $z->{isz}, osfx => "i");
        legacy(nm => $nm, s => $s, op => [0x83], kind => "MI", digit => $k, ik => "i8", isz => 1, osfx => "i8") unless $s eq "b";
    }
}

# GNU as's short forms of the accumulator (the user's choice: the register
# stays an operand, which must be al ax eax rax): ALU and test with an
# immediate (andl.n.ai / 4095 / eax: 25 ff 0f 00 00), xchg with it (66 90)
$isa->group("gnu accumulator");
for my $k (0 .. 8) {
    my $op = $k < 8 ? $alu[$k] : "test";
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        my $opc = $k < 8 ? 8 * $k + 4 + $z->{lo} : 0xa8 + $z->{lo};
        gform("$op$s" . ($s eq "q" ? "" : ".n") . ".ai", ["imm:$z->{ik}", "rd:$s.acc"], "$op$s \$<imm>, <rd>",
            gbytes(@{ $z->{pre} }), ($s eq "q" ? gbytes(0x48) : ()), C("byte", C("acc", hex2($opc), "rd")), gimm($z->{isz}));
    }
}
for my $s (qw(w l q)) {
    my $z = $SZ{$s};
    gform("xchg$s" . ($s eq "q" ? "" : ".n") . ".a", ["rs:" . rk($s, $s eq "q" ? "any" : "lo"), "rd:$s.acc"], "xchg$s <rs>, <rd>",
        gbytes(@{ $z->{pre} }), ($s eq "q" ? C("rex", 1, 0, 0, "rs") : ()), C("byte", C("accr", "0x90", "rd", "rs")));
}

$isa->group("gnu move");
for my $s (qw(b w l q)) {
    my $z = $SZ{$s};
    legacy(nm => "mov$s", s => $s, op => [0x88 + $z->{lo}], kind => "MR");
    legacy(nm => "mov$s", s => $s, op => [0x8a + $z->{lo}], kind => "RM", regonly => 0);
    legacy(nm => "mov$s", s => $s, op => [0xc6 + $z->{lo}], kind => "MI", digit => 0, ik => $z->{ik}, isz => $z->{isz}, osfx => "i", regonly => $s eq "q");
    legacy(nm => "test$s", s => $s, op => [0x84 + $z->{lo}], kind => "MR");
    legacy(nm => "test$s", s => $s, op => [0xf6 + $z->{lo}], kind => "MI", digit => 0, ik => $z->{ik}, isz => $z->{isz}, osfx => "i");
    legacy(nm => "xchg$s", s => $s, op => [0x86 + $z->{lo}], kind => "MR");
}
# mov $imm, %reg: B8+r (B0+r for a byte), without REX where none is needed
for my $s (qw(b w l)) {
    my $z = $SZ{$s};
    gform("mov$s.n.i", ["imm:$z->{ik}", "rd:" . rk($s, "lo")], "mov$s \$<imm>, <rd>",
        gbytes(@{ $z->{pre} }), C("opreg", hex2($z->{lo} ? 0xb8 : 0xb0), "rd"), gimm($z->{isz}));
}
for my $s (qw(l q)) {
    legacy(nm => "lea$s", s => $s, op => [0x8d], kind => "RM", regonly => 0);
}
for my $x (["movzbw", "b", "w", 0x0f, 0xb6], ["movzbl", "b", "l", 0x0f, 0xb6], ["movzbq", "b", "q", 0x0f, 0xb6],
           ["movzwl", "w", "l", 0x0f, 0xb7], ["movzwq", "w", "q", 0x0f, 0xb7],
           ["movsbw", "b", "w", 0x0f, 0xbe], ["movsbl", "b", "l", 0x0f, 0xbe], ["movsbq", "b", "q", 0x0f, 0xbe],
           ["movswl", "w", "l", 0x0f, 0xbf], ["movswq", "w", "q", 0x0f, 0xbf], ["movslq", "l", "q", 0x63]) {
    my ($nm, $from, $to, @op) = @$x;
    legacy(nm => $nm, s => $to, op => \@op, kind => "RM", mk => $from, pre => []);
}

$isa->group("gnu unary");
for my $u (["inc", 0xfe, 0], ["dec", 0xfe, 1], ["not", 0xf6, 2], ["neg", 0xf6, 3],
           ["mul", 0xf6, 4], ["imul", 0xf6, 5, "1"], ["div", 0xf6, 6], ["idiv", 0xf6, 7]) {
    my ($op, $opc, $digit, $one) = @$u;
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        legacy(nm => "$op$s", s => $s, op => [$opc + $z->{lo}], kind => "M", digit => $digit,
            ($one ? (osfx => $one, rsfx => $one) : ()));
    }
}
for my $s (qw(w l q)) {
    my $z = $SZ{$s};
    legacy(nm => "imul$s", s => $s, op => [0x0f, 0xaf], kind => "RM");
    legacy(nm => "imul$s", s => $s, op => [0x69], kind => "RMI", ik => $z->{ik}, isz => $z->{isz}, osfx => "i", rsfx => "i");
    legacy(nm => "imul$s", s => $s, op => [0x6b], kind => "RMI", ik => "i8", isz => 1, osfx => "i8", rsfx => "i8");
}

$isa->group("gnu shift");
my @sh = (["rol", 0], ["ror", 1], ["rcl", 2], ["rcr", 3], ["shl", 4], ["shr", 5], ["sar", 7]);
for my $t (@sh) {
    my ($op, $digit) = @$t;
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        legacy(nm => "$op$s", s => $s, op => [0xd0 + $z->{lo}], kind => "M", digit => $digit, osfx => "1", rsfx => "1");
        legacy(nm => "$op$s", s => $s, op => [0xc0 + $z->{lo}], kind => "MI", digit => $digit, ik => "u8", isz => 1, osfx => "i", rsfx => "i");
        legacy(nm => "$op$s", s => $s, op => [0xd2 + $z->{lo}], kind => "M", digit => $digit, osfx => "cl", rsfx => "cl", gx => "%cl, ");
    }
}

$isa->group("gnu bit");
for my $t (["bsf", [], 0xbc], ["bsr", [], 0xbd], ["popcnt", [0xf3], 0xb8], ["lzcnt", [0xf3], 0xbd], ["tzcnt", [0xf3], 0xbc]) {
    my ($op, $p, $opc) = @$t;
    legacy(nm => "$op$_", s => $_, pre => $p, op => [0x0f, $opc], kind => "RM") for qw(w l q);
}
for my $t (["bt", 0xa3, 4], ["bts", 0xab, 5], ["btr", 0xb3, 6], ["btc", 0xbb, 7]) {
    my ($op, $opc, $digit) = @$t;
    for my $s (qw(w l q)) {
        legacy(nm => "$op$s", s => $s, op => [0x0f, $opc], kind => "MR");
        legacy(nm => "$op$s", s => $s, op => [0x0f, 0xba], kind => "MI", digit => $digit, ik => "u8", isz => 1, osfx => "i");
    }
}
gform("bswapl.n", ["rd:" . rk("l", "lo")], "bswapl <rd>", gbytes(0x0f), C("opreg", "0xc8", "rd"));

$isa->group("gnu branch");
my @cc = qw(o no b ae e ne be a s ns p np l ge le g);
for my $c (0 .. 15) {
    legacy(nm => "set$cc[$c]", s => "b", op => [0x0f, 0x90 + $c], kind => "M", digit => 0);
    legacy(nm => "cmov$cc[$c]$_", s => $_, op => [0x0f, 0x40 + $c], kind => "RM") for qw(w l q);
}
for my $j (["call", 2], ["jmp", 4]) {
    my ($op, $digit) = @$j;
    gform("$op.n.r", ["rs:" . rk("q", "lo")], "$op *<rs>", gbytes(0xff), C("modrm.n", 3, $digit, "rs"));
    for my $m (@MEMS) {
        next if $m eq "p";
        my @mp = map { /^(base|index):/ ? "$_.lo" : $_ } @{ $MEM{$m}{p} };
        gform("$op.n.$m", \@mp, "$op *$MEM{$m}{g}", gbytes(0xff), gmem($m, $digit, 1));
        my @hp = map { /^base:/ ? "$_.hi" : $_ } @{ $MEM{$m}{p} };
        gform("$op.$m", \@hp, "$op *$MEM{$m}{g}", grex(0, 0, $m), gbytes(0xff), gmem($m, $digit, 0)) unless $m eq "a32";
    }
}

$isa->group("gnu stack");
gform("pushq.n", ["rs:" . rk("q", "lo")], "pushq <rs>", C("opreg", "0x50", "rs"));
gform("popq.n",  ["rd:" . rk("q", "lo")], "popq <rd>",  C("opreg", "0x58", "rd"));
for my $s (qw(w l)) {
    legacy(nm => "nop$s", s => $s, op => [0x0f, 0x1f], kind => "M", digit => 0);
}

# ---------------------------------------------------------------------------
# SSE: the xmm instructions of glibc's string functions, legacy encoded
# (a mandatory 66, F2 or F3 before REX); the xmm registers are x
# ---------------------------------------------------------------------------

$isa->group("gnu sse");
# [name, prefix, opcode bytes]: xmm <- xmm/m128 (RM), the memory forms too
for my $t (["pcmpeqb", 0x66, 0x0f, 0x74], ["pcmpeqd", 0x66, 0x0f, 0x76], ["pcmpgtb", 0x66, 0x0f, 0x64],
           ["pminub", 0x66, 0x0f, 0xda], ["pmaxub", 0x66, 0x0f, 0xde], ["pminud", 0x66, 0x0f, 0x38, 0x3b],
           ["paddb", 0x66, 0x0f, 0xfc], ["psubb", 0x66, 0x0f, 0xf8], ["pand", 0x66, 0x0f, 0xdb],
           ["pandn", 0x66, 0x0f, 0xdf], ["por", 0x66, 0x0f, 0xeb], ["pxor", 0x66, 0x0f, 0xef],
           ["punpcklbw", 0x66, 0x0f, 0x60], ["punpcklwd", 0x66, 0x0f, 0x61], ["punpckldq", 0x66, 0x0f, 0x62],
           ["movdqa", 0x66, 0x0f, 0x6f], ["movdqu", 0xf3, 0x0f, 0x6f], ["movaps", undef, 0x0f, 0x28],
           ["movups", undef, 0x0f, 0x10]) {
    my ($nm, $p, @op) = @$t;
    legacy(nm => $nm, s => "l", pre => [defined $p ? $p : ()], op => \@op, kind => "RM", rk => "x", mk => "x");
}
# the stores of the moves (MR, memory only), and those that only store
for my $t (["movdqa", 0x66, 0x7f], ["movdqu", 0xf3, 0x7f], ["movaps", undef, 0x29], ["movups", undef, 0x11],
           ["movntdq", 0x66, 0xe7], ["movntps", undef, 0x2b]) {
    my ($nm, $p, $op) = @$t;
    legacy(nm => $nm, s => "l", pre => [defined $p ? $p : ()], op => [0x0f, $op], kind => "MR", rk => "x", mk => "x", regonly => 0);
}
# movhpd, movlpd: the high or low half from memory
for my $t (["movhpd", 0x16], ["movlpd", 0x12]) {
    legacy(nm => $t->[0], s => "l", pre => [0x66], op => [0x0f, $t->[1]], kind => "RM", rk => "x", mk => "x", regonly => 0);
}
# with an immediate: xmm <- xmm/m128, imm8
for my $t (["pshufd", 0x0f, 0x70], ["palignr", 0x0f, 0x3a, 0x0f], ["pcmpistri", 0x0f, 0x3a, 0x63],
           ["roundsd", 0x0f, 0x3a, 0x0b], ["roundss", 0x0f, 0x3a, 0x0a]) {
    my ($nm, @op) = @$t;
    legacy(nm => $nm, s => "l", pre => [0x66], op => \@op, kind => "RMI", rk => "x", mk => "x", ik => "u8", isz => 1, osfx => "i", rsfx => "i");
}
# byte shifts of the whole register, by an immediate
for my $t (["pslldq", 7], ["psrldq", 3]) {
    legacy(nm => $t->[0], s => "l", pre => [0x66], op => [0x0f, 0x73], kind => "MI", digit => $t->[1], mk => "x", ik => "u8", isz => 1, osfx => "i", mem => 0);
}
# between xmm and the integer registers: pmovmskb r32 <- xmm, movd and
# movq to and from xmm (.tox .fromx as ttpc's own), cvtsd2si and cvtss2si
legacy(nm => "pmovmskb", s => "l", pre => [0x66], op => [0x0f, 0xd7], kind => "RM", rk => "l", mk => "x", mem => 0);
legacy(nm => "movd", s => "l", pre => [0x66], op => [0x0f, 0x6e], kind => "RM", rk => "x", mk => "l", mem => 0, rsfx => "tox", gnu => "movd");
legacy(nm => "movd", s => "l", pre => [0x66], op => [0x0f, 0x7e], kind => "MR", rk => "x", mk => "l", mem => 0, rsfx => "fromx", gnu => "movd");
legacy(nm => "cvtsd2siq", s => "q", pre => [0xf2], op => [0x0f, 0x2d], kind => "RM", rk => "q", mk => "x", mem => 0, gnu => "cvtsd2si");
legacy(nm => "cvtss2siq", s => "q", pre => [0xf3], op => [0x0f, 0x2d], kind => "RM", rk => "q", mk => "x", mem => 0, gnu => "cvtss2si");
# movq: m64 <-> xmm (F3 0F 7E load, 66 0F D6 store)
legacy(nm => "movq", s => "l", pre => [0xf3], op => [0x0f, 0x7e], kind => "RM", rk => "x", mk => "x", regonly => 0, osfx => "tox");
legacy(nm => "movq", s => "l", pre => [0x66], op => [0x0f, 0xd6], kind => "MR", rk => "x", mk => "x", regonly => 0, osfx => "fromx");

1;
