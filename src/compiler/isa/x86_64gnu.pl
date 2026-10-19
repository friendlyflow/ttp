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
# The groups are named gnu ...; but for gnu encodings (the parts the forms
# are made of, in the section) they go in a tree of their own,
# x86_64gnu.ff (gen/mkgnuff.pl), which only a build of x86_64 asm reads
# after shared.ff: the 14864 forms are 13 MB, and every other compile on
# every target would read them. progs/x86_64/mkgnu.pl reads
# @main::X86_GNU, filled here as @X86_WIDE is, and writes the GNU twin of
# every form (make x86gnu).
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
    my ($m, $reg, $n, $imm, $mr, $sb) = @_;
    my $d = $MEM{$m};
    ($mr, $sb) = $n ? ("modrm.n", "sib.n") : ("modrm", "sib") unless $mr;
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

# ---------------------------------------------------------------------------
# VEX: AVX and AVX2 (and BMI's integer forms, the masks' moves and tests).
# vex2 (C5) where GNU as takes it: map 0F, W0, the r/m register (or a
# memory operand's base and index) among the first eight; vex3 (C4) the
# rest. R, X, B and vvvv are inverted in the prefix (rn' xn' bn' vn').
# ---------------------------------------------------------------------------

$isa->group("gnu encodings");
$isa->add("gnu encodings", node("comment",
    node("vex2.b r v l pp: the byte after C5: R inverted (bit 3 of r), vvvv inverted (v), L, pp. vex3.1 r x b m and vex3.2 w v l pp: the bytes after C4. modrm.v mod reg rm: ModRM with rm among the first eight (a vex2 form)."),
    node("rn' xn' bn' (bit 3 of a register, inverted), vn' (a register's 4 bits, inverted)")));
for my $n (qw(rn' xn' bn')) {
    $isa->{seen}{"$n\[0:0]"} = 1;
    $isa->add("gnu encodings", node("$n\[0:0]:", node($n), C("srli", 3, $n, "a0"), C("andi", 1, "a0", "a0"), C("xori", 1, "a0", "a0")));
}
$isa->{seen}{"vn'[3:0]"} = 1;
$isa->add("gnu encodings", node("vn'[3:0]:", node("vn'"), C("xori", 15, "vn'", "a0"), C("andi", 15, "a0", "a0")));
$isa->def("vex2.b", "rn'[0:0]", "vn'[3:0]", "l[0:0]", "pp[1:0]");
$isa->def("vex3.1", "rn'[0:0]", "xn'[0:0]", "bn'[0:0]", "mm[4:0]");
$isa->def("vex3.2", "w[0:0]", "vn'[3:0]", "l[0:0]", "pp[1:0]");
$isa->def("modrm.v", "mod[1:0]", "reg'[2:0]", "rm[2:0]");

my %PP = ("" => 0, 66 => 1, f3 => 2, f2 => 3);
my %LEN = (128 => 0, 256 => 1, lig => 0, lz => 0, 1 => 1);
my %VK = (128 => "x", 256 => "y");

# One VEX instruction in all its forms. %o:
#   nm gnu     the name and GNU's mnemonic
#   pp map w   66 f3 f2 or "", 1 (0F) 2 (0F38) 3 (0F3A), W
#   lens       [128, 256], or [lig] (no length part: scalar, L 0), or
#              [lz] (L 0, the integer forms), or [1] (L 1, no part: kord)
#   op         the opcode byte
#   kind       RVM: reg <- vvvv, r/m (AT&T: r/m, vvvv, reg); RM: reg <- r/m;
#              MR: r/m <- reg; RMV: reg <- r/m, vvvv (shlx: vvvv, r/m,
#              reg); VM: vvvv <- r/m, reg a digit (blsmsk)
#   rk vk mk   the kinds of reg, vvvv, r/m (x y: by the length; l q k)
#   mem        0: no memory forms; regs 0: no register forms; rev: the
#              register form is the store opcode's (.rev)
#   digit      ModRM.reg for VM
sub vexf {
    my (%o) = @_;
    my $nm = $o{nm};
    my $gnu = $o{gnu} // $nm;
    my ($pp, $map, $w) = ($PP{ $o{pp} // "" }, $o{map} // 1, $o{w} // 0);
    for my $len (@{ $o{lens} }) {
        my $L = $LEN{$len};
        my $lp = $len =~ /^\d\d\d$/ ? ".$len" : "";
        my $vec = $VK{$len} // "x";
        my ($rk, $vk, $mk) = map { my $k = $o{$_} // "v"; $k eq "v" ? $vec : $k } qw(rk vk mk);
        for my $enc (qw(vex2 vex3)) {
            next if $enc eq "vex2" && ($map != 1 || $w);
            my $v2 = $enc eq "vex2";
            my $pre = $v2 ? "" : "{vex3} ";
            my $kind = $o{kind};
            # the operands: reg, vvvv, r/m (a register or memory)
            my ($reg, $vv) = $kind eq "VM" ? ($o{digit}, "vd") : ("rd", ($kind =~ /^(RVM|RMV)$/ ? "vs" : 0));
            $reg = "rs" if $kind eq "MR";
            my $rmname = $kind eq "MR" ? "rd" : "rs";
            my $vreg = $kind eq "VM" ? "vd" : "vs";
            my $prefix = sub {
                my ($rm, $x, $b) = @_;
                $v2 ? (gbytes(0xc5), C("vex2.b", $reg, $vv, $L, $pp))
                    : (gbytes(0xc4), C("vex3.1", $reg, $x, $b, $map), C("vex3.2", $w, $vv, $L, $pp));
            };
            my @imm = defined $o{isz} ? C("byte", "imm") : ();
            my $ig = @imm ? "\$<imm>, " : "";
            my @ip = @imm ? ("imm:u8") : ();
            # the order of the operands, AT&T's, as params and in GNU's line
            my $ops = sub {
                my ($rmp, $rmg) = @_;     # the r/m's params and spelling
                my $c2 = $v2 ? "lo" : "any";
                my $rv = "$vreg:" . rk($vk, "any");
                my $rr = "$reg:" . rk($rk, "any");
                return ([@ip, @$rmp, $rv, $rr], "$ig$rmg, <$vreg>, <$reg>") if $kind eq "RVM";
                return ([@ip, $rv, @$rmp, $rr], "$ig<$vreg>, $rmg, <$reg>") if $kind eq "RMV";
                return ([@ip, @$rmp, $rr], "$ig$rmg, <$reg>") if $kind eq "RM";
                return ([@ip, $rr, @$rmp], "$ig<$reg>, $rmg") if $kind eq "MR";
                return ([@ip, @$rmp, $rv], "$ig$rmg, <$vreg>") if $kind eq "VM";
                die "vexf: $kind\n";
            };
            if ($o{regs} // 1) {
                my $c2 = $v2 ? "lo" : "any";
                my ($p, $g) = $ops->(["$rmname:" . rk($mk, $c2)], "<$rmname>");
                my $name = "$nm$lp.$enc" . ($o{rev} ? ".rev" : "") . ($o{rsfx} ? ".$o{rsfx}" : "");
                gform($name, $p, $pre . ($o{rev} ? "{store} " : "") . "$gnu $g",
                    $prefix->($rmname, 0, $rmname), gbytes($o{op}), C($v2 ? "modrm.v" : "modrm", 3, $reg, $rmname), @imm);
            }
            next if defined $o{mem} && !$o{mem};
            for my $m (@MEMS) {
                next if $m eq "a32";
                my $d = $MEM{$m};
                my @mp = @{ $d->{p} };
                @mp = map { /^(base|index):/ ? "$_.lo" : $_ } @mp if $v2;
                my ($p, $g) = $ops->(\@mp, $d->{g});
                my ($x, $b) = $d->{rip} ? (0, 0) : ($d->{sib} == 2 ? "index" : 0, "base");
                gform("$nm$lp.$enc.$m" . ($o{osfx} // ""), $p, "$pre$gnu $g", $prefix->(undef, $x, $b), gbytes($o{op}),
                    gmem($m, $reg, 0, @imm ? 1 : 0, $v2 ? "modrm.v" : "modrm", $v2 ? "sib.n" : "sib"), @imm);
            }
        }
    }
}

$isa->group("gnu avx");
for my $t (["vpaddb", 1, 0xfc], ["vpsubb", 1, 0xf8], ["vpand", 1, 0xdb], ["vpandn", 1, 0xdf], ["vpor", 1, 0xeb],
           ["vpxor", 1, 0xef], ["vpcmpeqb", 1, 0x74], ["vpcmpeqd", 1, 0x76], ["vpcmpgtb", 1, 0x64], ["vpminub", 1, 0xda],
           ["vpmaxub", 1, 0xde], ["vpminud", 2, 0x3b], ["vpshufb", 2, 0x00]) {
    my ($nm, $map, $op) = @$t;
    vexf(nm => $nm, pp => 66, map => $map, lens => [128, 256], op => $op, kind => "RVM");
}
for my $t (["vmovdqa", 66, 0x6f, 0x7f], ["vmovdqu", "f3", 0x6f, 0x7f], ["vmovaps", "", 0x28, 0x29], ["vmovups", "", 0x10, 0x11]) {
    my ($nm, $pp, $ld, $st) = @$t;
    vexf(nm => $nm, pp => $pp, lens => [128, 256], op => $ld, kind => "RM");
    vexf(nm => $nm, pp => $pp, lens => [128, 256], op => $st, kind => "MR", rev => 1, mem => 0);
    vexf(nm => $nm, pp => $pp, lens => [128, 256], op => $st, kind => "MR", regs => 0, osfx => "r");
}
vexf(nm => "vmovntdq", pp => 66, lens => [128, 256], op => 0xe7, kind => "MR", regs => 0, osfx => "r");
for my $t (["vpbroadcastb", 0x78], ["vpbroadcastd", 0x58], ["vbroadcastss", 0x18]) {
    vexf(nm => $t->[0], pp => 66, map => 2, lens => [128, 256], op => $t->[1], kind => "RM", mk => "x");
}
vexf(nm => "vpmovmskb", pp => 66, lens => [128, 256], op => 0xd7, kind => "RM", rk => "l", mem => 0);
# the scalar moves: vmovd and vmovq between xmm and r32/r64 or memory
vexf(nm => "vmovd", pp => 66, lens => ["lig"], op => 0x6e, kind => "RM", mk => "l", rsfx => "tox", osfx => "tox");
vexf(nm => "vmovd", pp => 66, lens => ["lig"], op => 0x7e, kind => "MR", mk => "l", rsfx => "fromx", osfx => "fromx");
vexf(nm => "vmovq", pp => 66, w => 1, lens => ["lig"], op => 0x6e, kind => "RM", mk => "q", mem => 0, rsfx => "tox");
vexf(nm => "vmovq", pp => 66, w => 1, lens => ["lig"], op => 0x7e, kind => "MR", mk => "q", mem => 0, rsfx => "fromx");
vexf(nm => "vmovq", pp => "f3", lens => ["lig"], op => 0x7e, kind => "RM", regs => 0, osfx => "tox");
vexf(nm => "vmovq", pp => 66, lens => ["lig"], op => 0xd6, kind => "MR", regs => 0, osfx => "fromx");
gform("vzeroupper", [], "vzeroupper", gbytes(0xc5, 0xf8, 0x77));
gform("vzeroall", [], "vzeroall", gbytes(0xc5, 0xfc, 0x77));

# the masks: kmov between k and r32/r64, kortest, kord (VEX, L0; kord L1)
$isa->group("gnu mask");
vexf(nm => "kmovd", pp => "f2", lens => ["lz"], op => 0x92, kind => "RM", rk => "k", mk => "l", mem => 0, rsfx => "tok", gnu => "kmovd");
vexf(nm => "kmovd", pp => "f2", lens => ["lz"], op => 0x93, kind => "RM", rk => "l", mk => "k", mem => 0, rsfx => "fromk", gnu => "kmovd");
vexf(nm => "kmovq", pp => "f2", w => 1, lens => ["lz"], op => 0x92, kind => "RM", rk => "k", mk => "q", mem => 0, rsfx => "tok", gnu => "kmovq");
vexf(nm => "kmovq", pp => "f2", w => 1, lens => ["lz"], op => 0x93, kind => "RM", rk => "q", mk => "k", mem => 0, rsfx => "fromk", gnu => "kmovq");
for my $t (["kortestb", 66, 0], ["kortestw", "", 0], ["kortestd", 66, 1], ["kortestq", "", 1]) {
    vexf(nm => $t->[0], pp => $t->[1], w => $t->[2], lens => ["lz"], op => 0x98, kind => "RM", rk => "k", mk => "k", mem => 0);
}
for my $t (["kord", 66, 1], ["korq", "", 1], ["kordb", 66, 0], ["korw", "", 0]) {
    next if $t->[0] eq "kordb";
    vexf(nm => $t->[0], pp => $t->[1], w => $t->[2], lens => [1], op => 0x45, kind => "RVM", rk => "k", vk => "k", mk => "k", mem => 0);
}

# BMI: the integer forms in VEX (map 0F38, vex3 only), sizes by W
$isa->group("gnu bmi");
for my $s (qw(l q)) {
    my $w = $s eq "q" ? 1 : 0;
    vexf(nm => "andn$s", gnu => "andn", map => 2, w => $w, lens => ["lz"], op => 0xf2, kind => "RVM", rk => $s, vk => $s, mk => $s);
    vexf(nm => "bzhi$s", gnu => "bzhi", map => 2, w => $w, lens => ["lz"], op => 0xf5, kind => "RMV", rk => $s, vk => $s, mk => $s);
    vexf(nm => "blsmsk$s", gnu => "blsmsk", map => 2, w => $w, lens => ["lz"], op => 0xf3, kind => "VM", digit => 2, vk => $s, mk => $s);
    vexf(nm => "shlx$s", gnu => "shlx", pp => 66, map => 2, w => $w, lens => ["lz"], op => 0xf7, kind => "RMV", rk => $s, vk => $s, mk => $s);
    vexf(nm => "shrx$s", gnu => "shrx", pp => "f2", map => 2, w => $w, lens => ["lz"], op => 0xf7, kind => "RMV", rk => $s, vk => $s, mk => $s);
    vexf(nm => "sarx$s", gnu => "sarx", pp => "f3", map => 2, w => $w, lens => ["lz"], op => 0xf7, kind => "RMV", rk => $s, vk => $s, mk => $s);
}

# ---------------------------------------------------------------------------
# EVEX: AVX-512 (and AVX-512VL's 128 and 256), the forms glibc's evex and
# avx512 string functions have: 62 P0 P1 P2, then the opcode. P0 R X B R'
# 0 0 m m, P1 W vvvv 1 pp, P2 z L'L b V' aaa; R X B R' V' vvvv inverted.
# A register's bit 4 is R' (reg), X (r/m) or V' (vvvv). A disp8 is the
# displacement over N, the bytes of the memory operand (disp8*N): the
# form takes the displacement itself. Marks: k, the mask register after
# the destination (aaa); kz the same, zeroing (z); without, aaa 0.
# ---------------------------------------------------------------------------

$isa->group("gnu encodings");
$isa->add("gnu encodings", node("comment",
    node("evex.0 r x b r4 m: P0, x the index's bit 3 (memory); evex.0r r x4 b r4 m: P0 of a register form, x4 the r/m register's bit 4. evex.1 w v pp: P1. evex.2 z ll v4 aaa: P2. r4n' x4n' v4n': a register's bit 4, inverted."),
    node("dN'[7:0] disp: a displacement over N (2 4 8 16 32 64), EVEX's compressed disp8.")));
for my $n (qw(r4n' x4n' v4n')) {
    $isa->{seen}{"$n\[0:0]"} = 1;
    $isa->add("gnu encodings", node("$n\[0:0]:", node($n), C("srli", 4, $n, "a0"), C("andi", 1, "a0", "a0"), C("xori", 1, "a0", "a0")));
}
for my $k (1 .. 6) {
    my $n = 2**$k;
    $isa->{seen}{"d$n'[7:0]"} = 1;
    $isa->add("gnu encodings", node("d$n'[7:0]:", node("d$n'"), C("srai", $k, "d$n'", "a0")));
}
$isa->def("evex.0", "rn'[0:0]", "xn'[0:0]", "bn'[0:0]", "r4n'[0:0]", "zz=00", "mm[1:0]");
$isa->def("evex.0r", "rn'[0:0]", "x4n'[0:0]", "bn'[0:0]", "r4n'[0:0]", "zz=00", "mm[1:0]");
$isa->def("evex.1", "w[0:0]", "vn'[3:0]", "one=1", "pp[1:0]");
$isa->def("evex.2", "z[0:0]", "ll[1:0]", "bb=0", "v4n'[0:0]", "aaa[2:0]");

my %ELEN = (128 => [0, "x"], 256 => [1, "y"], 512 => [2, "z"]);
# the twin's class of a register kind: a vector any of 32, else any
sub evc { $_[0] =~ /^[xyz]$/ ? "ev" : "any" }

# One EVEX instruction in all its forms. %o as for vexf (nm gnu pp map w
# op kind rk vk mk mem regs rev osfx), and:
#   lens   of 128 256 512;  n  the disp8's N: a number, or the length's
#          bytes (default); imm  an immediate the mnemonic stands for
#          (vpcmpneqb: vpcmpb with 4); isz  an immediate operand (1)
sub evexf {
    my (%o) = @_;
    my $nm = $o{nm};
    my $gnu = $o{gnu} // $nm;
    my ($pp, $map, $w) = ($PP{ $o{pp} // "" }, $o{map} // 1, $o{w} // 0);
    my $kind = $o{kind};
    for my $len (@{ $o{lens} }) {
        my ($ll, $vec) = @{ $ELEN{$len} };
        my $N = $o{n} // $len / 8;
        my ($rk, $vk, $mk) = map { my $k = $o{$_} // "v"; $k eq "v" ? $vec : $k } qw(rk vk mk);
        for my $mask ("", "k", "kz") {
            next if $mask && $kind eq "MR" && !$o{rev};
            next if $mask eq "kz" && ($o{rk} // "") eq "k";    # (a mask is never zeroed into)
            my $mp = $mask ? ".$mask" : "";
            my $reg = $kind eq "MR" ? "rs" : "rd";
            my $rmname = $kind eq "MR" ? "rd" : "rs";
            my $vv = $kind eq "RVM" ? "vs" : 0;
            my $dst = $kind eq "MR" ? $rmname : $reg;
            my @mkp = $mask ? ("mk:k.any") : ();
            my $mg = $mask ? "{<mk>}" . ($mask eq "kz" ? "{z}" : "") : "";
            my @imm = defined $o{imm} ? C("byte", $o{imm}) : defined $o{isz} ? C("byte", "imm") : ();
            my @ip = defined $o{isz} ? ("imm:u8") : ();
            my $ig = defined $o{isz} ? "\$<imm>, " : "";
            my $ops = sub {
                my ($rmp, $rmg) = @_;
                my $rv = "vs:" . rk($vk, evc($vk));
                my $rr = "$reg:" . rk($rk, evc($rk));
                return ([@ip, @$rmp, $rv, $rr, @mkp], "$ig$rmg, <vs>, <$reg>$mg") if $kind eq "RVM";
                return ([@ip, @$rmp, $rr, @mkp], "$ig$rmg, <$reg>$mg") if $kind eq "RM";
                return ([@ip, $rr, @$rmp, @mkp], "$ig<$reg>, $rmg$mg") if $kind eq "MR";
                die "evexf: $kind\n";
            };
            my $p2 = sub { C("evex.2", $mask eq "kz" ? 1 : 0, $ll, $vv, $mask ? "mk" : 0) };
            if ($o{regs} // 1) {
                my ($p, $g) = $ops->(["$rmname:" . rk($mk, evc($mk))], "<$rmname>");
                gform("$nm.$len.evex" . ($kind eq "MR" ? ".rev" : "") . $mp . ($o{rsfx} ? ".$o{rsfx}" : ""), $p, "{evex} " . ($kind eq "MR" ? "{store} " : "") . "$gnu $g",
                    gbytes(0x62), C("evex.0r", $reg, $rmname, $rmname, $reg, $map), C("evex.1", $w, $vv, $pp), $p2->(),
                    gbytes($o{op}), C("modrm", 3, $reg, $rmname), @imm);
            }
            next if defined $o{mem} && !$o{mem};
            next if $mask && $kind eq "MR";
            for my $m (@MEMS) {
                next if $m eq "a32";
                my $d = $MEM{$m};
                my @mp = map { /^disp:d8$/ ? "disp:d8x$N" : /^disp:d32$/ ? "disp:d32e" : $_ } @{ $d->{p} };
                my ($p, $g) = $ops->(\@mp, $d->{g});
                my ($x, $b) = $d->{rip} ? (0, 0) : ($d->{sib} == 2 ? "index" : 0, "base");
                my @m = gmem($m, $reg, 0, scalar @imm ? 1 : 0);
                # disp8: the displacement over N
                @m = map { $_->{content} eq "simm8" && $N > 1 ? C("byte", C("d$N'[7:0]", "disp")) : $_ } @m;
                gform("$nm.$len.evex$mp.$m" . ($o{osfx} // ""), $p, "{evex} $gnu $g",
                    gbytes(0x62), C("evex.0", $reg, $x, $b, $reg, $map), C("evex.1", $w, $vv, $pp), $p2->(),
                    gbytes($o{op}), @m, @imm);
            }
        }
    }
}

$isa->group("gnu avx512");
my @L3 = (128, 256, 512);
for my $t (["vmovdqu64", "f3", 1, 0x6f, 0x7f], ["vmovdqu32", "f3", 0, 0x6f, 0x7f], ["vmovdqu8", "f2", 0, 0x6f, 0x7f],
           ["vmovdqa64", 66, 1, 0x6f, 0x7f], ["vmovdqa32", 66, 0, 0x6f, 0x7f], ["vmovups", "", 0, 0x10, 0x11],
           ["vmovaps", "", 0, 0x28, 0x29]) {
    my ($nm, $pp, $w, $ld, $st) = @$t;
    evexf(nm => $nm, pp => $pp, w => $w, lens => \@L3, op => $ld, kind => "RM");
    evexf(nm => $nm, pp => $pp, w => $w, lens => \@L3, op => $st, kind => "MR", rev => 1, mem => 0);
    evexf(nm => $nm, pp => $pp, w => $w, lens => \@L3, op => $st, kind => "MR", regs => 0, osfx => "r");
}
evexf(nm => "vmovntdq", pp => 66, lens => \@L3, op => 0xe7, kind => "MR", regs => 0, osfx => "r");
# into a mask: the compares and tests
for my $t (["vpcmpeqb", 66, 1, 0, 0x74], ["vpcmpeqd", 66, 1, 0, 0x76],
           ["vptestmb", 66, 2, 0, 0x26], ["vptestmd", 66, 2, 0, 0x27], ["vptestnmb", "f3", 2, 0, 0x26], ["vptestnmd", "f3", 2, 0, 0x27]) {
    my ($nm, $pp, $map, $w, $op) = @$t;
    evexf(nm => $nm, pp => $pp, map => $map, w => $w, lens => \@L3, op => $op, kind => "RVM", rk => "k");
}
# vpcmp[u]b and vpcmp[u]d by their predicate: GNU's names for the immediate
my @pred = (["eq", 0], ["lt", 1], ["le", 2], ["neq", 4], ["nlt", 5], ["nle", 6]);
for my $t (["b", 0x3f, 0], ["ub", 0x3e, 0], ["d", 0x1f, 0], ["ud", 0x1e, 0]) {
    my ($sfx, $op, $w) = @$t;
    for my $pr (@pred) {
        next if $pr->[0] eq "eq" && ($sfx eq "b" || $sfx eq "d");    # (vpcmpeqb has its own opcode)
        evexf(nm => "vpcmp$pr->[0]$sfx", pp => 66, map => 3, w => $w, lens => \@L3, op => $op, kind => "RVM", rk => "k", imm => $pr->[1]);
    }
}
for my $t (["vpminub", 1, 0, 0xda], ["vpmaxub", 1, 0, 0xde], ["vpminud", 2, 0, 0x3b], ["vpaddb", 1, 0, 0xfc], ["vpsubb", 1, 0, 0xf8],
           ["vpxorq", 1, 1, 0xef], ["vpxord", 1, 0, 0xef], ["vporq", 1, 1, 0xeb], ["vpandq", 1, 1, 0xdb], ["vpandnq", 1, 1, 0xdf],
           ["vpshufb", 2, 0, 0x00]) {
    my ($nm, $map, $w, $op) = @$t;
    evexf(nm => $nm, pp => 66, map => $map, w => $w, lens => \@L3, op => $op, kind => "RVM");
}
evexf(nm => "vpternlogd", pp => 66, map => 3, w => 0, lens => \@L3, op => 0x25, kind => "RVM", isz => 1);
# broadcasts: from a byte or a dword of memory or xmm, or from r32
evexf(nm => "vpbroadcastb", pp => 66, map => 2, lens => \@L3, op => 0x78, kind => "RM", mk => "x", n => 1);
evexf(nm => "vpbroadcastd", pp => 66, map => 2, lens => \@L3, op => 0x58, kind => "RM", mk => "x", n => 4);
evexf(nm => "vpbroadcastb", pp => 66, map => 2, lens => \@L3, op => 0x7a, kind => "RM", mk => "l", mem => 0, rsfx => "fromr");
evexf(nm => "vpbroadcastd", pp => 66, map => 2, lens => \@L3, op => 0x7c, kind => "RM", mk => "l", mem => 0, rsfx => "fromr");

# ---------------------------------------------------------------------------
# x87 (libm's long double of the x87, the floating point state) and the
# rest glibc's asm has: the state saves (fxsave, xsave ...), prefetch, the
# MXCSR. A memory operand's form is M's (the digit in ModRM.reg), its size
# in the mnemonic (s l t: 32 64 80 bits; for integers s l ll: 16 32 64);
# st(i) is sti.
# ---------------------------------------------------------------------------

$isa->group("gnu x87");
for my $t (["flds", 0xd9, 0], ["fldl", 0xdd, 0], ["fldt", 0xdb, 5], ["fsts", 0xd9, 2], ["fstl", 0xdd, 2],
           ["fstps", 0xd9, 3], ["fstpl", 0xdd, 3], ["fstpt", 0xdb, 7],
           ["filds", 0xdf, 0], ["fildl", 0xdb, 0], ["fildll", 0xdf, 5], ["fists", 0xdf, 2], ["fistl", 0xdb, 2],
           ["fistps", 0xdf, 3], ["fistpl", 0xdb, 3], ["fistpll", 0xdf, 7],
           ["fadds", 0xd8, 0], ["faddl", 0xdc, 0], ["fmuls", 0xd8, 1], ["fmull", 0xdc, 1], ["fcoms", 0xd8, 2], ["fcoml", 0xdc, 2],
           ["fcomps", 0xd8, 3], ["fcompl", 0xdc, 3], ["fsubs", 0xd8, 4], ["fsubl", 0xdc, 4], ["fsubrs", 0xd8, 5], ["fsubrl", 0xdc, 5],
           ["fdivs", 0xd8, 6], ["fdivl", 0xdc, 6], ["fdivrs", 0xd8, 7], ["fdivrl", 0xdc, 7],
           ["fnstcw", 0xd9, 7], ["fldcw", 0xd9, 5], ["fnstsw", 0xdd, 7], ["fnstenv", 0xd9, 6], ["fldenv", 0xd9, 4],
           ["fstcw", [0x9b, 0xd9], 7], ["fstsw", [0x9b, 0xdd], 7], ["fstenv", [0x9b, 0xd9], 6]) {
    my ($nm, $op, $digit) = @$t;
    my @op = ref $op ? @$op : ($op);
    my @pre = @op > 1 ? ($op[0]) : ();
    legacy(nm => $nm, s => "l", pre => \@pre, op => [$op[-1]], kind => "M", digit => $digit, regonly => 0);
}
# st(i): [name, opcode, base of the second byte, GNU's operands]
for my $t (["fld", 0xd9, 0xc0, "<rs>"], ["fst", 0xdd, 0xd0, "<rs>"], ["fstp", 0xdd, 0xd8, "<rs>"], ["fxch", 0xd9, 0xc8, "<rs>"],
           ["ffree", 0xdd, 0xc0, "<rs>"], ["ffreep", 0xdf, 0xc0, "<rs>"], ["fucom", 0xdd, 0xe0, "<rs>"], ["fucomp", 0xdd, 0xe8, "<rs>"],
           ["fcom", 0xd8, 0xd0, "<rs>"], ["fcomp", 0xd8, 0xd8, "<rs>"],
           ["fcomi", 0xdb, 0xf0, "<rs>, %st"], ["fcomip", 0xdf, 0xf0, "<rs>, %st"], ["fucomi", 0xdb, 0xe8, "<rs>, %st"], ["fucomip", 0xdf, 0xe8, "<rs>, %st"],
           ["fadd", 0xd8, 0xc0, "<rs>, %st"], ["fmul", 0xd8, 0xc8, "<rs>, %st"], ["fsub", 0xd8, 0xe0, "<rs>, %st"], ["fsubr", 0xd8, 0xe8, "<rs>, %st"],
           ["fdiv", 0xd8, 0xf0, "<rs>, %st"], ["fdivr", 0xd8, 0xf8, "<rs>, %st"],
           # (AT&T's sub and subr, div and divr to st(i) are the other opcode's)
           ["fadd.tost", 0xdc, 0xc0, "%st, <rs>"], ["fmul.tost", 0xdc, 0xc8, "%st, <rs>"], ["fsub.tost", 0xdc, 0xe0, "%st, <rs>"],
           ["fsubr.tost", 0xdc, 0xe8, "%st, <rs>"], ["fdiv.tost", 0xdc, 0xf0, "%st, <rs>"], ["fdivr.tost", 0xdc, 0xf8, "%st, <rs>"],
           ["faddp", 0xde, 0xc0, "%st, <rs>"], ["fmulp", 0xde, 0xc8, "%st, <rs>"], ["fsubp", 0xde, 0xe0, "%st, <rs>"],
           ["fsubrp", 0xde, 0xe8, "%st, <rs>"], ["fdivp", 0xde, 0xf0, "%st, <rs>"], ["fdivrp", 0xde, 0xf8, "%st, <rs>"]) {
    my ($nm, $op, $b, $g) = @$t;
    (my $gnu = $nm) =~ s/\..*//;
    gform($nm, ["rs:st.any"], "$gnu $g", gbytes($op), C("opreg", hex2($b), "rs"));
}
for my $t (["fld1", 0xd9, 0xe8], ["fldz", 0xd9, 0xee], ["fldl2e", 0xd9, 0xea], ["fldl2t", 0xd9, 0xe9], ["fldlg2", 0xd9, 0xec],
           ["fldln2", 0xd9, 0xed], ["fldpi", 0xd9, 0xeb], ["f2xm1", 0xd9, 0xf0], ["fscale", 0xd9, 0xfd], ["fprem", 0xd9, 0xf8],
           ["fprem1", 0xd9, 0xf5], ["frndint", 0xd9, 0xfc], ["fxam", 0xd9, 0xe5], ["fxtract", 0xd9, 0xf4], ["fyl2x", 0xd9, 0xf1],
           ["fyl2xp1", 0xd9, 0xf9], ["fabs", 0xd9, 0xe1], ["fchs", 0xd9, 0xe0], ["fsqrt", 0xd9, 0xfa], ["fsin", 0xd9, 0xfe],
           ["fcos", 0xd9, 0xff], ["fsincos", 0xd9, 0xfb], ["fptan", 0xd9, 0xf2], ["fpatan", 0xd9, 0xf3], ["ftst", 0xd9, 0xe4],
           ["fcompp", 0xde, 0xd9], ["fucompp", 0xda, 0xe9], ["fnclex", 0xdb, 0xe2], ["fninit", 0xdb, 0xe3], ["fdecstp", 0xd9, 0xf6],
           ["fincstp", 0xd9, 0xf7]) {
    my ($nm, @b) = @$t;
    gform($nm, [], $nm, gbytes(@b));
}
gform("fnstsw.ai", ["rd:w.acc"], "fnstsw <rd>", gbytes(0xdf), C("byte", C("acc", "0xe0", "rd")));
gform("fstsw.ai", ["rd:w.acc"], "fstsw <rd>", gbytes(0x9b, 0xdf), C("byte", C("acc", "0xe0", "rd")));

$isa->group("gnu system");
for my $t (["fxsave", 0x0f, 0xae, 0], ["fxrstor", 0x0f, 0xae, 1], ["xsave", 0x0f, 0xae, 4], ["xrstor", 0x0f, 0xae, 5],
           ["xsavec", 0x0f, 0xc7, 4], ["ldmxcsr", 0x0f, 0xae, 2], ["stmxcsr", 0x0f, 0xae, 3],
           ["prefetcht0", 0x0f, 0x18, 1], ["prefetcht1", 0x0f, 0x18, 2], ["prefetcht2", 0x0f, 0x18, 3], ["prefetchnta", 0x0f, 0x18, 0]) {
    my ($nm, @op) = @$t;
    my $digit = pop @op;
    legacy(nm => $nm, s => "l", op => \@op, kind => "M", digit => $digit, regonly => 0);
}
for my $t (["xsave64", 0x0f, 0xae, 4], ["xrstor64", 0x0f, 0xae, 5], ["xsavec64", 0x0f, 0xc7, 4], ["fxsave64", 0x0f, 0xae, 0], ["fxrstor64", 0x0f, 0xae, 1]) {
    my ($nm, @op) = @$t;
    my $digit = pop @op;
    legacy(nm => $nm, s => "q", op => \@op, kind => "M", digit => $digit, regonly => 0);
}
for my $t (["movbel", "l", 0xf0, 0xf1], ["movbeq", "q", 0xf0, 0xf1]) {
    my ($nm, $s, $ld, $st) = @$t;
    legacy(nm => $nm, s => $s, op => [0x0f, 0x38, $ld], kind => "RM", regonly => 0, gnu => "movbe");
    legacy(nm => $nm, s => $s, op => [0x0f, 0x38, $st], kind => "MR", regonly => 0, gnu => "movbe");
}
for my $t (["xtest", 0x0f, 0x01, 0xd6], ["xgetbv", 0x0f, 0x01, 0xd0], ["rdpkru", 0x0f, 0x01, 0xee], ["wrpkru", 0x0f, 0x01, 0xef],
           ["endbr64", 0xf3, 0x0f, 0x1e, 0xfa]) {
    my ($nm, @b) = @$t;
    gform($nm, [], $nm, gbytes(@b));
}
# the prefixes GNU as writes before an instruction, each a call of its own
for my $t (["fs", 0x64], ["gs", 0x65], ["cs", 0x2e], ["ds", 0x3e], ["data16", 0x66], ["addr32", 0x67], ["notrack", 0x3e]) {
    gform($t->[0], [], sprintf(".byte 0x%02x", $t->[1]), gbytes($t->[1]));
}

1;
