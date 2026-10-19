# isa/x86_64.pl — the x86_64 section of the shared page (mkff.pl does it):
# the 64-bit integer instructions, the system ones, the atomics and SSE2
# scalar floating point (no x87 arithmetic, MMX or packed SIMD; of the
# floating point state MXCSR and the x87 environment, for glibc's soft-fp),
# the registers, and macros/x86_64.ff.txt.
#
# x86 is variable length, so an instruction is a macro: a function whose
# body is calls, each emitted in turn. The small encodings (rex, modrm,
# modrm.base, modrm.sib, modrm.rip, opreg, simm8; 8 or 16 bits) and the
# data words of the shared page (byte, half, word, dword) are its parts:
#
#   addq.m: disp base rd       add disp(base), rd
#     rex 1 rd 0 base          0100 W R X B, R/X/B bit 3 of the registers
#     byte 0x03                the opcode
#     modrm.base base rd       mod 10, reg, rm 100; SIB 00 100 base
#     word disp                disp32
#
# Every form has one fixed size, whatever its operands:
#
# - Every form with a register or memory operand has a REX prefix, 0x40
#   when no bit of it is needed (GNU as: {rex}). So the byte registers are
#   al cl dl bl spl bpl sil dil r8b..r15b; ah ch dh bh do not exist here.
# - Memory is [base + disp32] or [base + index*scale + disp32], always with
#   a SIB byte and a 32-bit displacement (mod 10; index 100 for none), so
#   that every base works the same, rsp, rbp, r12 and r13 too; or
#   rip-relative to a label. scale is 1, 2, 4 or 8 and rsp is no index
#   (neither is checked).
# - Jumps to a label are rel32, the .8 forms rel8.
# - Forms without operands (the string instructions, in and out, the
#   system ones) have no REX unless they need W.
#
# Range checks: an imm8 that is sign-extended (the .i8 forms, push .i8,
# rel8) goes through simm8 and must be -128..127; byte, half and word take
# a value signed or unsigned, so an imm32 sign-extended to 64 bits is not
# checked against 0x80000000..0xffffffff. Register numbers are checked by
# rex (0..15).
#
# Names: the AT&T mnemonic with its size suffix (b w l q: 8 16 32 64 bits,
# the 16-bit forms with the 0x66 prefix), then a dot and the form when the
# operands are not all registers. Operands in AT&T order, the destination
# last; a memory operand is `disp base` (.m) or `disp base index scale`
# (.x), or a label (.p):
#
#   addq rs rd                  register, register
#   addq.i imm rd               imm32 (sign-extended), register; .i8 imm8
#   addq.m disp base rd         memory to register
#   addq.mr rs disp base        register to memory
#   addq.mi imm disp base       imm32 to memory; .mi8 imm8
#   addq.x disp base index scale rd       and .xr .xi .xi8 likewise
#   movq.p label rd, movq.pr rs label, leaq.p label rd    rip-relative
#   shlq.1 rd / shlq.i imm rd / shlq.cl rd  shift by 1, imm8, cl;
#                               .m1 .mi .mcl and .x1 .xi .xcl in memory
#   mulq rs, imulq.1 rs         one operand (rdx:rax); imulq rs rd and
#                               imulq.i imm rs rd are imul's other forms
#   call label, call.r reg, call.m disp base, call.x ..., call.p label
#                               (call *label(%rip)); jmp the same, jmp.8
#   je label (rel32), je.8 label (rel8); sete rd; cmoveq rs rd
#   movq.tocr rs cr, movq.fromcr cr rd, movq.todr, movq.fromdr
#   movd.tox rs xd, movd.fromx xs rd, movq.tox, movq.fromx (gpr <-> xmm)
#   inb.i port (in $port, %al), inb (in (%dx), %al); outb.i, outb
#   lock, rep, repe, repz, repne, repnz: prefixes, a call of their own
#   before the instruction
#   ret, ret.i imm16, int.i imm8, int3; cbw cwde cdqe cwd cdq cqo
#
# The 16 conditions: o no b ae e ne be a s ns p np l ge le g, and for j,
# j.8 and set also c nae nb nc z nz na nbe pe po nge nl ng nle.
#
# Registers: rax eax ... r15 r15d (64/32 bits), ax al ... r15w r15b (16/8),
# xmm0..xmm15, cr0 cr2 cr3 cr4 cr8, dr0..dr3 dr6 dr7; a register is its
# number, so any name of the right number works.
#
# progs/x86_64/mkwide.pl reads @main::X86_WIDE, which this file fills: per
# form its name, its operands with their kinds, and its GNU as twin.

use strict;
use warnings;
use FF qw(node);
use ISA;

my $isa = ISA->new(width => sub { die "x86_64: give the bits of $_[0]\n" });

our @X86_WIDE;          # [name, [param:kind ...], gnu template]

sub arg { my ($a) = @_; ref $a ? $a : node($a) }
sub C   { my ($name, @args) = @_; node($name, map { arg($_) } @args) }
sub hex2 { sprintf "0x%02x", $_[0] }
sub bytes { map { C("byte", hex2($_)) } @_ }

# A form: a macro in the current group, and its line for wide.
sub form {
    my ($name, $params, $gnu, @body) = @_;
    my @names = map { (split /:/)[0] } @$params;
    push @{ $isa->{current}{children} }, node("$name:", (map { node($_) } @names), @body);
    push @X86_WIDE, [$name, [@$params], $gnu];
}

# ---------------------------------------------------------------------------
# registers
# ---------------------------------------------------------------------------

my @q = qw(rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15);
my @l = qw(eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d);
my @w = qw(ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w);
my @b = qw(al cl dl bl spl bpl sil dil r8b r9b r10b r11b r12b r13b r14b r15b);
sub bin4 { sprintf "%04b", $_[0] }

$isa->add("registers",
    (map { node("$q[$_] $l[$_]:", node(bin4($_))) } 0 .. 15),
    (map { node("$w[$_] $b[$_]:", node(bin4($_))) } 0 .. 15),
    # the high bytes, 4..7 in a form without REX (isa/x86_64gnu.pl)
    (map { node("$_->[0] $_->[0]:", node(bin4($_->[1]))) } [ah => 4], [ch => 5], [dh => 6], [bh => 7]),
    (map { node("xmm$_ xmm$_:", node(bin4($_))) } 0 .. 15),
    (map { node("cr$_ cr$_:", node(bin4($_))) } 0, 2, 3, 4, 8),
    (map { node("dr$_ dr$_:", node(bin4($_))) } 0 .. 3, 6, 7),
);

# ---------------------------------------------------------------------------
# encodings: the parts of an instruction. Fields MSB first, emitted little
# endian: in a 16-bit one the ModRM byte is the low half, it comes first.
# A register operand is 4 bits, rex takes bit 3 and the ModRM/SIB fields
# bits 2:0 (their primed operands are not range checked).
# ---------------------------------------------------------------------------

$isa->group("encodings");
$isa->add("encodings", node("comment", node(
    "rex w r x b: the REX prefix, 0100 W R X B, from bit 3 of r (ModRM.reg), x (SIB.index), b (ModRM.rm or SIB.base); W 1 for 64 bits.")));
$isa->def("rex", "fixed=0100", "w[0]", "r[3]", "x[3]", "b[3]");
$isa->add("encodings", node("comment", node(
    "modrm mod reg rm: a ModRM byte; mod 3 is a register, reg a register or an opcode digit.")));
$isa->def("modrm", "mod[1:0]", "reg'[2:0]", "rm'[2:0]");
$isa->add("encodings", node("comment", node(
    "modrm.base base reg: ModRM mod 10 rm 100 and a SIB without index: [base + disp32], the disp32 follows. modrm.sib scale index base reg: [base + index*scale + disp32], scale 1 2 4 8. modrm.rip reg: [rip + disp32].")));
$isa->def("modrm.base", "ss=00", "index=100", "base'[2:0]", "mod=10", "reg'[2:0]", "rm=100");
$isa->{seen}{"scale'[1:0]"} = 1;      # its slice is below: 1 2 4 8 -> 0..3
$isa->def("modrm.sib", "scale'[1:0]", "index'[2:0]", "base'[2:0]", "mod=10", "reg'[2:0]", "rm=100");
$isa->def("modrm.rip", "mod=00", "reg'[2:0]", "rm=101");
$isa->add("encodings", node("comment", node(
    "opreg op r: an opcode with the register in its low 3 bits (push, pop, bswap, mov imm, movabs).")));
$isa->def("opreg", "op[7:3]", "r'[2:0]");
$isa->add("encodings", node("comment", node(
    "simm8 imm: a sign-extended imm8 or rel8: an operand called imm is range checked as signed only, -128..127 (byte takes 0..255 too).")));
$isa->def("simm8", "imm[7:0]");
$isa->add("encodings",
    node("comment", node("scale'[1:0]: the 2-bit SIB scale of 1, 2, 4 or 8: (scale >> 1) - (scale >> 3).")),
    node("scale'[1:0]:", node("scale'"),
        C("srli", 3, "scale'", "t0"), C("srli", 1, "scale'", "a0"), C("sub", "t0", "a0", "a0")),
    node("comment", node("rel32 target, rel8 target: target - the end of the rel32 or rel8 field that starts at pc.")),
    node("rel32:", node("target"), C("sub", "pc", "target", "a0"), C("addi", -4, "a0", "a0")),
    node("rel8:", node("target"), C("sub", "pc", "target", "a0"), C("addi", -1, "a0", "a0")),
);

# ---------------------------------------------------------------------------
# The form builders
# ---------------------------------------------------------------------------

sub rex { C("rex", @_) }

# The parts of a ModRM instruction: prefixes, rex, opcode, ModRM (and SIB,
# disp32). $reg is a register operand or an opcode digit; $rm a register
# operand, or m (disp base), x (disp base index scale), p (target).
sub modrm_body {
    my ($pre, $w, $ops, $reg, $rm) = @_;
    my @b = bytes(@$pre);
    if ($rm eq "m") {
        push @b, rex($w, $reg, 0, "base"), bytes(@$ops), C("modrm.base", "base", $reg), C("word", "disp");
    } elsif ($rm eq "x") {
        push @b, rex($w, $reg, "index", "base"), bytes(@$ops),
            C("modrm.sib", "scale", "index", "base", $reg), C("word", "disp");
    } elsif ($rm eq "p") {
        push @b, rex($w, $reg, 0, 0), bytes(@$ops), C("modrm.rip", $reg), C("word", C("rel32", "target"));
    } else {
        push @b, rex($w, $reg, 0, $rm), bytes(@$ops), C("modrm", 3, $reg, $rm);
    }
    @b;
}

my %MEM = (
    m => { params => [qw(disp:disp base:base)], gnu => "<disp>(<base>,%riz,1)" },
    x => { params => [qw(disp:disp base:base index:index scale:scale)], gnu => "<disp>(<base>,<index>,<scale>)" },
    p => { params => [qw(target:label)], gnu => "<target>(%rip)" },
);
sub mp { @{ $MEM{$_[0]}{params} } }
sub mg { $MEM{$_[0]}{gnu} }
sub pf { $_[0] eq "p" ? "{rex}" : "{disp32} {rex}" }

sub imm {
    my ($size, $p) = @_;
    $p //= "imm";
    C({ 1 => "byte", 2 => "half", 4 => "word", 8 => "dword" }->{$size}, $p);
}

# Sizes: the prefixes, REX.W, the low opcode bit (0 for bytes), imm bytes.
my %SZ = (
    b => { pre => [],     w => 0, lo => 0, isz => 1 },
    w => { pre => [0x66], w => 0, lo => 1, isz => 2 },
    l => { pre => [],     w => 0, lo => 1, isz => 4 },
    q => { pre => [],     w => 1, lo => 1, isz => 4 },
);
sub ikind { my ($s) = @_; { b => "ib", w => "i16", l => "i32", q => "i32" }->{$s} }

# ---------------------------------------------------------------------------
# alu: add or adc sbb and sub xor cmp
# ---------------------------------------------------------------------------

my @alu = qw(add or adc sbb and sub xor cmp);
for my $n (0 .. 7) {
    $isa->group($n < 4 ? "alu1" : "alu2");
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        my ($pre, $w, $lo) = ($z->{pre}, $z->{w}, $z->{lo});
        my $nm = "$alu[$n]$s";
        my $mr = [8 * $n + $lo];
        my $rmo = [8 * $n + 2 + $lo];
        my $io = [$s eq "b" ? 0x80 : 0x81];
        my $ik = ikind($s);
        form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>", modrm_body($pre, $w, $mr, "rs", "rd"));
        form("$nm.i", ["imm:$ik", "rd:$s"], "{rex} $nm \$<imm>, <rd>",
            modrm_body($pre, $w, $io, $n, "rd"), imm($z->{isz}));
        form("$nm.i8", ["imm:i8", "rd:$s"], "{rex} $nm \$<imm>, <rd>",
            modrm_body($pre, $w, [0x83], $n, "rd"), C("simm8", "imm")) unless $s eq "b";
        for my $m (qw(m x)) {
            form("$nm.$m", [mp($m), "rd:$s"], pf($m) . " $nm " . mg($m) . ", <rd>",
                modrm_body($pre, $w, $rmo, "rd", $m));
            form("$nm.${m}r", ["rs:$s", mp($m)], pf($m) . " $nm <rs>, " . mg($m),
                modrm_body($pre, $w, $mr, "rs", $m));
            form("$nm.${m}i", ["imm:$ik", mp($m)], pf($m) . " $nm \$<imm>, " . mg($m),
                modrm_body($pre, $w, $io, $n, $m), imm($z->{isz}));
            form("$nm.${m}i8", ["imm:i8", mp($m)], pf($m) . " $nm \$<imm>, " . mg($m),
                modrm_body($pre, $w, [0x83], $n, $m), C("simm8", "imm")) unless $s eq "b";
        }
    }
}

# ---------------------------------------------------------------------------
# move: mov, movabs, movzx/movsx, movsxd, lea, xchg, test
# ---------------------------------------------------------------------------

$isa->group("move");
for my $s (qw(b w l q)) {
    my $z = $SZ{$s};
    my ($pre, $w, $lo) = ($z->{pre}, $z->{w}, $z->{lo});
    my $nm = "mov$s";
    my $ik = ikind($s);
    form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>", modrm_body($pre, $w, [0x88 + $lo], "rs", "rd"));
    if ($s eq "q") {
        form("$nm.i", ["imm:i32", "rd:q"], "{rex} $nm \$<imm>, <rd>",
            modrm_body($pre, $w, [0xc7], 0, "rd"), imm(4));
    } else {
        form("$nm.i", ["imm:$ik", "rd:$s"], "{rex} $nm \$<imm>, <rd>",
            bytes(@$pre), rex(0, 0, 0, "rd"), C("opreg", hex2($lo ? 0xb8 : 0xb0), "rd"), imm($z->{isz}));
    }
    for my $m (qw(m x p)) {
        form("$nm.$m", [mp($m), "rd:$s"], pf($m) . " $nm " . mg($m) . ", <rd>",
            modrm_body($pre, $w, [0x8a + $lo], "rd", $m));
        form("$nm.${m}r", ["rs:$s", mp($m)], pf($m) . " $nm <rs>, " . mg($m),
            modrm_body($pre, $w, [0x88 + $lo], "rs", $m));
        form("$nm.${m}i", ["imm:$ik", mp($m)], pf($m) . " $nm \$<imm>, " . mg($m),
            modrm_body($pre, $w, [0xc6 + $lo], 0, $m), imm($z->{isz})) unless $m eq "p";
    }
}
form("movabsq", ["imm:i64", "rd:q"], "movabsq \$<imm>, <rd>",
    rex(1, 0, 0, "rd"), C("opreg", "0xb8", "rd"), imm(8));

# movzx, movsx, movsxd: [name, source size, dest size, opcode bytes]
for my $x (["movzbw", "b", "w", 0x0f, 0xb6], ["movzbl", "b", "l", 0x0f, 0xb6], ["movzbq", "b", "q", 0x0f, 0xb6],
           ["movzwl", "w", "l", 0x0f, 0xb7], ["movzwq", "w", "q", 0x0f, 0xb7],
           ["movsbw", "b", "w", 0x0f, 0xbe], ["movsbl", "b", "l", 0x0f, 0xbe], ["movsbq", "b", "q", 0x0f, 0xbe],
           ["movswl", "w", "l", 0x0f, 0xbf], ["movswq", "w", "q", 0x0f, 0xbf], ["movslq", "l", "q", 0x63]) {
    my ($nm, $from, $to, @op) = @$x;
    my ($pre, $w) = ($SZ{$to}{pre}, $SZ{$to}{w});
    form($nm, ["rs:$from", "rd:$to"], "{rex} $nm <rs>, <rd>", modrm_body($pre, $w, \@op, "rd", "rs"));
    for my $m (qw(m x)) {
        form("$nm.$m", [mp($m), "rd:$to"], pf($m) . " $nm " . mg($m) . ", <rd>",
            modrm_body($pre, $w, \@op, "rd", $m));
    }
}

for my $s (qw(l q)) {
    for my $m (qw(m x p)) {
        form("lea$s.$m", [mp($m), "rd:$s"], pf($m) . " lea$s " . mg($m) . ", <rd>",
            modrm_body([], $SZ{$s}{w}, [0x8d], "rd", $m));
    }
}

for my $s (qw(b w l q)) {
    my $z = $SZ{$s};
    my ($pre, $w, $lo) = ($z->{pre}, $z->{w}, $z->{lo});
    form("xchg$s", ["rs:$s", "rd:$s"], "{rex} xchg$s <rs>, <rd>", modrm_body($pre, $w, [0x86 + $lo], "rs", "rd"));
    for my $m (qw(m x)) {
        form("xchg$s.${m}r", ["rs:$s", mp($m)], pf($m) . " xchg$s <rs>, " . mg($m),
            modrm_body($pre, $w, [0x86 + $lo], "rs", $m));
    }
    my $ik = ikind($s);
    form("test$s", ["rs:$s", "rd:$s"], "{rex} test$s <rs>, <rd>", modrm_body($pre, $w, [0x84 + $lo], "rs", "rd"));
    form("test$s.i", ["imm:$ik", "rd:$s"], "{rex} test$s \$<imm>, <rd>",
        modrm_body($pre, $w, [0xf6 + $lo], 0, "rd"), imm($z->{isz}));
    for my $m (qw(m x)) {
        form("test$s.${m}r", ["rs:$s", mp($m)], pf($m) . " test$s <rs>, " . mg($m),
            modrm_body($pre, $w, [0x84 + $lo], "rs", $m));
        form("test$s.${m}i", ["imm:$ik", mp($m)], pf($m) . " test$s \$<imm>, " . mg($m),
            modrm_body($pre, $w, [0xf6 + $lo], 0, $m), imm($z->{isz}));
    }
}

# ---------------------------------------------------------------------------
# unary: inc dec not neg, mul imul div idiv (one operand), imul (two and
# three), the sign extensions of rax
# ---------------------------------------------------------------------------

$isa->group("unary");
for my $u (["inc", 0xfe, 0], ["dec", 0xfe, 1], ["not", 0xf6, 2], ["neg", 0xf6, 3],
           ["mul", 0xf6, 4], ["imul", 0xf6, 5, ".1"], ["div", 0xf6, 6], ["idiv", 0xf6, 7]) {
    my ($op, $opc, $digit, $one) = @$u;
    $one //= "";
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        my $nm = "$op$s";
        form("$nm$one", ["rd:$s"], "{rex} $nm <rd>", modrm_body($z->{pre}, $z->{w}, [$opc + $z->{lo}], $digit, "rd"));
        for my $m (qw(m x)) {
            my $f = $one ? "${one}$m" : ".$m";
            form("$nm$f", [mp($m)], pf($m) . " $nm " . mg($m),
                modrm_body($z->{pre}, $z->{w}, [$opc + $z->{lo}], $digit, $m));
        }
    }
}
for my $s (qw(w l q)) {
    my $z = $SZ{$s};
    my $nm = "imul$s";
    form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>", modrm_body($z->{pre}, $z->{w}, [0x0f, 0xaf], "rd", "rs"));
    for my $m (qw(m x)) {
        form("$nm.$m", [mp($m), "rd:$s"], pf($m) . " $nm " . mg($m) . ", <rd>",
            modrm_body($z->{pre}, $z->{w}, [0x0f, 0xaf], "rd", $m));
    }
    form("$nm.i", ["imm:" . ikind($s), "rs:$s", "rd:$s"], "{rex} $nm \$<imm>, <rs>, <rd>",
        modrm_body($z->{pre}, $z->{w}, [0x69], "rd", "rs"), imm($z->{isz}));
    form("$nm.i8", ["imm:i8", "rs:$s", "rd:$s"], "{rex} $nm \$<imm>, <rs>, <rd>",
        modrm_body($z->{pre}, $z->{w}, [0x6b], "rd", "rs"), C("simm8", "imm"));
}
form("cbw",  [], "cbtw", bytes(0x66, 0x98));
form("cwde", [], "cwtl", bytes(0x98));
form("cdqe", [], "cltq", bytes(0x48, 0x98));
form("cwd",  [], "cwtd", bytes(0x66, 0x99));
form("cdq",  [], "cltd", bytes(0x99));
form("cqo",  [], "cqto", bytes(0x48, 0x99));

# ---------------------------------------------------------------------------
# shift: rol ror rcl rcr shl shr sar by 1, imm8 or cl
# ---------------------------------------------------------------------------

my @sh = (["rol", 0], ["ror", 1], ["rcl", 2], ["rcr", 3], ["shl", 4], ["shr", 5], ["sar", 7]);
for my $i (0 .. $#sh) {
    my ($op, $digit) = @{ $sh[$i] };
    $isa->group($i < 4 ? "shift1" : "shift2");
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        my ($pre, $w, $lo) = ($z->{pre}, $z->{w}, $z->{lo});
        my $nm = "$op$s";
        form("$nm.1", ["rd:$s"], "{rex} $nm <rd>", modrm_body($pre, $w, [0xd0 + $lo], $digit, "rd"));
        form("$nm.i", ["imm:u8", "rd:$s"], "{rex} $nm \$<imm>, <rd>",
            modrm_body($pre, $w, [0xc0 + $lo], $digit, "rd"), imm(1));
        form("$nm.cl", ["rd:$s"], "{rex} $nm %cl, <rd>", modrm_body($pre, $w, [0xd2 + $lo], $digit, "rd"));
        for my $m (qw(m x)) {
            form("$nm.${m}1", [mp($m)], pf($m) . " $nm " . mg($m), modrm_body($pre, $w, [0xd0 + $lo], $digit, $m));
            form("$nm.${m}i", ["imm:u8", mp($m)], pf($m) . " $nm \$<imm>, " . mg($m),
                modrm_body($pre, $w, [0xc0 + $lo], $digit, $m), imm(1));
            form("$nm.${m}cl", [mp($m)], pf($m) . " $nm %cl, " . mg($m), modrm_body($pre, $w, [0xd2 + $lo], $digit, $m));
        }
    }
}

# ---------------------------------------------------------------------------
# bit: shld shrd, bt bts btr btc, bsf bsr popcnt lzcnt tzcnt, bswap
# ---------------------------------------------------------------------------

$isa->group("bit");
for my $d (["shld", 0xa4], ["shrd", 0xac]) {
    my ($op, $opc) = @$d;
    for my $s (qw(w l q)) {
        my $z = $SZ{$s};
        my $nm = "$op$s";
        form("$nm.i", ["imm:u8", "rs:$s", "rd:$s"], "{rex} $nm \$<imm>, <rs>, <rd>",
            modrm_body($z->{pre}, $z->{w}, [0x0f, $opc], "rs", "rd"), imm(1));
        form("$nm.cl", ["rs:$s", "rd:$s"], "{rex} $nm %cl, <rs>, <rd>",
            modrm_body($z->{pre}, $z->{w}, [0x0f, $opc + 1], "rs", "rd"));
        for my $m (qw(m x)) {
            form("$nm.${m}i", ["imm:u8", "rs:$s", mp($m)], pf($m) . " $nm \$<imm>, <rs>, " . mg($m),
                modrm_body($z->{pre}, $z->{w}, [0x0f, $opc], "rs", $m), imm(1));
            form("$nm.${m}cl", ["rs:$s", mp($m)], pf($m) . " $nm %cl, <rs>, " . mg($m),
                modrm_body($z->{pre}, $z->{w}, [0x0f, $opc + 1], "rs", $m));
        }
    }
}
for my $t (["bt", 0xa3, 4], ["bts", 0xab, 5], ["btr", 0xb3, 6], ["btc", 0xbb, 7]) {
    my ($op, $opc, $digit) = @$t;
    for my $s (qw(w l q)) {
        my $z = $SZ{$s};
        my $nm = "$op$s";
        form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>", modrm_body($z->{pre}, $z->{w}, [0x0f, $opc], "rs", "rd"));
        form("$nm.i", ["imm:u8", "rd:$s"], "{rex} $nm \$<imm>, <rd>",
            modrm_body($z->{pre}, $z->{w}, [0x0f, 0xba], $digit, "rd"), imm(1));
        for my $m (qw(m x)) {
            form("$nm.${m}r", ["rs:$s", mp($m)], pf($m) . " $nm <rs>, " . mg($m),
                modrm_body($z->{pre}, $z->{w}, [0x0f, $opc], "rs", $m));
            form("$nm.${m}i", ["imm:u8", mp($m)], pf($m) . " $nm \$<imm>, " . mg($m),
                modrm_body($z->{pre}, $z->{w}, [0x0f, 0xba], $digit, $m), imm(1));
        }
    }
}
for my $t (["bsf", [], 0xbc], ["bsr", [], 0xbd], ["popcnt", [0xf3], 0xb8], ["lzcnt", [0xf3], 0xbd], ["tzcnt", [0xf3], 0xbc]) {
    my ($op, $p, $opc) = @$t;
    for my $s (qw(w l q)) {
        my $z = $SZ{$s};
        my $nm = "$op$s";
        my @pre = (@{ $z->{pre} }, @$p);
        form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>", modrm_body(\@pre, $z->{w}, [0x0f, $opc], "rd", "rs"));
        for my $m (qw(m x)) {
            form("$nm.$m", [mp($m), "rd:$s"], pf($m) . " $nm " . mg($m) . ", <rd>",
                modrm_body(\@pre, $z->{w}, [0x0f, $opc], "rd", $m));
        }
    }
}
form("bswapl", ["rd:l"], "{rex} bswapl <rd>", rex(0, 0, 0, "rd"), bytes(0x0f), C("opreg", "0xc8", "rd"));
form("bswapq", ["rd:q"], "{rex} bswapq <rd>", rex(1, 0, 0, "rd"), bytes(0x0f), C("opreg", "0xc8", "rd"));

# ---------------------------------------------------------------------------
# branch: jcc, jmp, call, ret; set: setcc; cmov: cmovcc
# ---------------------------------------------------------------------------

my @cc = qw(o no b ae e ne be a s ns p np l ge le g);
my %alias = (c => 2, nae => 2, nb => 3, nc => 3, z => 4, nz => 5, na => 6, nbe => 7,
             pe => 10, po => 11, nge => 12, nl => 13, ng => 14, nle => 15);
my @conds = ((map { [$cc[$_], $_] } 0 .. 15),
             map { [$_, $alias{$_}] } sort { $alias{$a} <=> $alias{$b} || $a cmp $b } keys %alias);

$isa->group("branch");
for (@conds) {
    my ($c, $n) = @$_;
    form("j$c", ["target:label"], "{disp32} j$c <target>",
        bytes(0x0f, 0x80 + $n), C("word", C("rel32", "target")));
    form("j$c.8", ["target:label8"], "{disp8} j$c <target>",
        bytes(0x70 + $n), C("simm8", C("rel8", "target")));
}
form("jmp", ["target:label"], "{disp32} jmp <target>", bytes(0xe9), C("word", C("rel32", "target")));
form("jmp.8", ["target:label8"], "{disp8} jmp <target>", bytes(0xeb), C("simm8", C("rel8", "target")));
form("call", ["target:label"], "call <target>", bytes(0xe8), C("word", C("rel32", "target")));
for my $j (["call", 2], ["jmp", 4]) {
    my ($op, $digit) = @$j;
    form("$op.r", ["rs:q"], "{rex} $op *<rs>", modrm_body([], 0, [0xff], $digit, "rs"));
    for my $m (qw(m x)) {
        form("$op.$m", [mp($m)], pf($m) . " $op *" . mg($m), modrm_body([], 0, [0xff], $digit, $m));
    }
    form("$op.p", ["target:label"], "$op *<target>(%rip)",
        bytes(0xff), C("modrm.rip", $digit), C("word", C("rel32", "target")));
}
form("ret", [], "ret", bytes(0xc3));
form("ret.i", ["imm:u16"], "ret \$<imm>", bytes(0xc2), imm(2));

$isa->group("set");
for (@conds) {
    my ($c, $n) = @$_;
    form("set$c", ["rd:b"], "{rex} set$c <rd>", modrm_body([], 0, [0x0f, 0x90 + $n], 0, "rd"));
    for my $m (qw(m x)) {
        form("set$c.$m", [mp($m)], pf($m) . " set$c " . mg($m), modrm_body([], 0, [0x0f, 0x90 + $n], 0, $m));
    }
}

$isa->group("cmov");
for my $n (0 .. 15) {
    for my $s (qw(w l q)) {
        my $z = $SZ{$s};
        my $nm = "cmov$cc[$n]$s";
        form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>",
            modrm_body($z->{pre}, $z->{w}, [0x0f, 0x40 + $n], "rd", "rs"));
        for my $m (qw(m x)) {
            form("$nm.$m", [mp($m), "rd:$s"], pf($m) . " $nm " . mg($m) . ", <rd>",
                modrm_body($z->{pre}, $z->{w}, [0x0f, 0x40 + $n], "rd", $m));
        }
    }
}

# ---------------------------------------------------------------------------
# stack and string: push pop, pushfq popfq, movs stos lods cmps scas, and
# the prefixes
# ---------------------------------------------------------------------------

$isa->group("stack");
form("pushq", ["rs:q"], "{rex} pushq <rs>", rex(0, 0, 0, "rs"), C("opreg", "0x50", "rs"));
form("popq",  ["rd:q"], "{rex} popq <rd>",  rex(0, 0, 0, "rd"), C("opreg", "0x58", "rd"));
form("pushq.i", ["imm:i32"], "pushq \$<imm>", bytes(0x68), imm(4));
form("pushq.i8", ["imm:i8"], "pushq \$<imm>", bytes(0x6a), C("simm8", "imm"));
for my $m (qw(m x)) {
    form("pushq.$m", [mp($m)], pf($m) . " pushq " . mg($m), modrm_body([], 0, [0xff], 6, $m));
    form("popq.$m",  [mp($m)], pf($m) . " popq " . mg($m),  modrm_body([], 0, [0x8f], 0, $m));
}
form("pushfq", [], "pushfq", bytes(0x9c));
form("popfq",  [], "popfq",  bytes(0x9d));

for my $t (["movs", 0xa4], ["cmps", 0xa6], ["stos", 0xaa], ["lods", 0xac], ["scas", 0xae]) {
    my ($op, $opc) = @$t;
    form("${op}b", [], "${op}b", bytes($opc));
    form("${op}w", [], "${op}w", bytes(0x66, $opc + 1));
    form("${op}l", [], "${op}l", bytes($opc + 1));
    form("${op}q", [], "${op}q", bytes(0x48, $opc + 1));
}
form("lock",  [], "lock",  bytes(0xf0));
form("rep",   [], "rep",   bytes(0xf3));
form("repe",  [], "repe",  bytes(0xf3));
form("repz",  [], "repz",  bytes(0xf3));
form("repne", [], "repne", bytes(0xf2));
form("repnz", [], "repnz", bytes(0xf2));

# ---------------------------------------------------------------------------
# atomic: xadd cmpxchg cmpxchg16b (with lock before them), the fences
# ---------------------------------------------------------------------------

$isa->group("atomic");
for my $t (["xadd", 0xc0], ["cmpxchg", 0xb0]) {
    my ($op, $opc) = @$t;
    for my $s (qw(b w l q)) {
        my $z = $SZ{$s};
        my $nm = "$op$s";
        form($nm, ["rs:$s", "rd:$s"], "{rex} $nm <rs>, <rd>",
            modrm_body($z->{pre}, $z->{w}, [0x0f, $opc + $z->{lo}], "rs", "rd"));
        for my $m (qw(m x)) {
            form("$nm.${m}r", ["rs:$s", mp($m)], pf($m) . " $nm <rs>, " . mg($m),
                modrm_body($z->{pre}, $z->{w}, [0x0f, $opc + $z->{lo}], "rs", $m));
        }
    }
}
for my $m (qw(m x)) {
    form("cmpxchg16b.$m", [mp($m)], pf($m) . " cmpxchg16b " . mg($m), modrm_body([], 1, [0x0f, 0xc7], 1, $m));
}
form("mfence", [], "mfence", bytes(0x0f, 0xae, 0xf0));
form("lfence", [], "lfence", bytes(0x0f, 0xae, 0xe8));
form("sfence", [], "sfence", bytes(0x0f, 0xae, 0xf8));
form("pause",  [], "pause",  bytes(0xf3, 0x90));

# ---------------------------------------------------------------------------
# system
# ---------------------------------------------------------------------------

$isa->group("system");
for my $t (["syscall", 0x0f, 0x05], ["sysretq", 0x48, 0x0f, 0x07],
           ["int3", 0xcc], ["hlt", 0xf4], ["nop", 0x90], ["cli", 0xfa], ["sti", 0xfb],
           ["cld", 0xfc], ["std", 0xfd], ["clc", 0xf8], ["stc", 0xf9], ["cmc", 0xf5],
           ["cpuid", 0x0f, 0xa2], ["rdtsc", 0x0f, 0x31], ["rdtscp", 0x0f, 0x01, 0xf9],
           ["rdmsr", 0x0f, 0x32], ["wrmsr", 0x0f, 0x30], ["iretq", 0x48, 0xcf],
           ["swapgs", 0x0f, 0x01, 0xf8], ["wbinvd", 0x0f, 0x09]) {
    my ($nm, @op) = @$t;
    form($nm, [], $nm, bytes(@op));
}
form("sysret", [], "sysretl", bytes(0x0f, 0x07));
# the floating point state glibc's soft-fp reads and sets (sfp-machine.h,
# sfp-exceptions.c): SSE's MXCSR, the x87 environment
for my $t (["ldmxcsr", [0x0f, 0xae], 2], ["stmxcsr", [0x0f, 0xae], 3],
           ["fldenv", [0xd9], 4], ["fnstenv", [0xd9], 6]) {
    my ($nm, $opc, $digit) = @$t;
    for my $m (qw(m x)) {
        form("$nm.$m", [mp($m)], pf($m) . " $nm " . mg($m), modrm_body([], 0, $opc, $digit, $m));
    }
}
form("fwait", [], "fwait", bytes(0x9b));
form("int.i", ["imm:u8"], "int \$<imm>", bytes(0xcd), imm(1));
for my $s (qw(w l)) {
    my $z = $SZ{$s};
    form("nop$s", ["rd:$s"], "{rex} nop$s <rd>", modrm_body($z->{pre}, 0, [0x0f, 0x1f], 0, "rd"));
    for my $m (qw(m x)) {
        form("nop$s.$m", [mp($m)], pf($m) . " nop$s " . mg($m), modrm_body($z->{pre}, 0, [0x0f, 0x1f], 0, $m));
    }
}
for my $t (["sgdt", 0x01, 0], ["sidt", 0x01, 1], ["lgdt", 0x01, 2], ["lidt", 0x01, 3], ["invlpg", 0x01, 7],
           ["lldt", 0x00, 2], ["ltr", 0x00, 3]) {
    my ($nm, $opc, $digit) = @$t;
    if ($opc == 0) {
        form($nm, ["rs:w"], "{rex} $nm <rs>", modrm_body([], 0, [0x0f, $opc], $digit, "rs"));
    }
    for my $m (qw(m x)) {
        form("$nm.$m", [mp($m)], pf($m) . " $nm " . mg($m), modrm_body([], 0, [0x0f, $opc], $digit, $m));
    }
}
for my $t (["cr", "c", 0x20], ["dr", "d", 0x21]) {
    my ($r, $k, $opc) = @$t;
    form("movq.to$r", ["rs:q", "$r:$k"], "{rex} mov <rs>, <$r>",
        rex(0, $r, 0, "rs"), bytes(0x0f, $opc + 2), C("modrm", 3, $r, "rs"));
    form("movq.from$r", ["$r:$k", "rd:q"], "{rex} mov <$r>, <rd>",
        rex(0, $r, 0, "rd"), bytes(0x0f, $opc), C("modrm", 3, $r, "rd"));
}
for my $s (qw(b w l)) {
    my @p = @{ $SZ{$s}{pre} };
    my $lo = $SZ{$s}{lo};
    my $acc = { b => "%al", w => "%ax", l => "%eax" }->{$s};
    form("in$s.i",  ["port:u8"], "in$s \$<port>, $acc",  bytes(@p, 0xe4 + $lo), imm(1, "port"));
    form("in$s",    [],          "in$s (%dx), $acc",     bytes(@p, 0xec + $lo));
    form("out$s.i", ["port:u8"], "out$s $acc, \$<port>", bytes(@p, 0xe6 + $lo), imm(1, "port"));
    form("out$s",   [],          "out$s $acc, (%dx)",    bytes(@p, 0xee + $lo));
}

# ---------------------------------------------------------------------------
# sse: SSE2 scalar float, xmm registers as xs (source) and xd (destination)
# ---------------------------------------------------------------------------

$isa->group("sse");
# A reg/mem -> xmm (or gpr) operation: name, prefixes, REX.W, opcode, the
# kinds of source and destination.
sub sse {
    my ($nm, $pre, $w, $opc, $sk, $dk, $gnu, $nomem) = @_;
    $gnu //= $nm;
    form($nm, ["rs:$sk", "rd:$dk"], "{rex} $gnu <rs>, <rd>", modrm_body($pre, $w, [0x0f, $opc], "rd", "rs"));
    return if $nomem;
    for my $m (qw(m x)) {
        form("$nm.$m", [mp($m), "rd:$dk"], pf($m) . " $gnu " . mg($m) . ", <rd>",
            modrm_body($pre, $w, [0x0f, $opc], "rd", $m));
    }
}
for my $t (["s", 0xf3], ["d", 0xf2]) {
    my ($p, $pb) = @$t;
    sse("movs$p", [$pb], 0, 0x10, "x", "x");
    for my $m (qw(m x)) {
        form("movs$p.${m}r", ["rs:x", mp($m)], pf($m) . " movs$p <rs>, " . mg($m),
            modrm_body([$pb], 0, [0x0f, 0x11], "rs", $m));
    }
    for my $o (["add", 0x58], ["sub", 0x5c], ["mul", 0x59], ["div", 0x5e], ["sqrt", 0x51], ["min", 0x5d], ["max", 0x5f]) {
        sse("$o->[0]s$p", [$pb], 0, $o->[1], "x", "x");
    }
    sse("cvtsi2s${p}l", [$pb], 0, 0x2a, "l", "x");
    sse("cvtsi2s${p}q", [$pb], 1, 0x2a, "q", "x");
    sse("cvtts${p}2sil", [$pb], 0, 0x2c, "x", "l", "cvtts${p}2si");
    sse("cvtts${p}2siq", [$pb], 1, 0x2c, "x", "q", "cvtts${p}2si");
}
sse("cvtss2sd", [0xf3], 0, 0x5a, "x", "x");
sse("cvtsd2ss", [0xf2], 0, 0x5a, "x", "x");
sse("ucomiss", [], 0, 0x2e, "x", "x");
sse("ucomisd", [0x66], 0, 0x2e, "x", "x");
sse("comiss",  [], 0, 0x2f, "x", "x");
sse("comisd",  [0x66], 0, 0x2f, "x", "x");
for my $o (["and", 0x54], ["andn", 0x55], ["or", 0x56], ["xor", 0x57]) {
    sse("$o->[0]ps", [], 0, $o->[1], "x", "x");
    sse("$o->[0]pd", [0x66], 0, $o->[1], "x", "x");
}
sse("movaps", [], 0, 0x28, "x", "x", undef, 1);
sse("movapd", [0x66], 0, 0x28, "x", "x", undef, 1);
for my $s (["d", 0, "l"], ["q", 1, "q"]) {
    my ($sfx, $w, $k) = @$s;
    form("mov$sfx.tox", ["rs:$k", "xd:x"], "{rex} mov$sfx <rs>, <xd>",
        modrm_body([0x66], $w, [0x0f, 0x6e], "xd", "rs"));
    form("mov$sfx.fromx", ["xs:x", "rd:$k"], "{rex} mov$sfx <xs>, <rd>",
        modrm_body([0x66], $w, [0x0f, 0x7e], "xs", "rd"));
}

# the forms GNU as picks, for glibc's asm (isa/x86_64gnu.pl), named apart
# from the ones above
{
    our $X86_ISA = $isa;
    our %X86_HAVE = map { ($_->[0] => 1) } @X86_WIDE;
    (my $dir = __FILE__) =~ s{[^/]*$}{};
    do "${dir}x86_64gnu.pl" or die "x86_64: x86_64gnu.pl: " . ($@ || $!) . "\n";
}

$isa->section("x86_64", "macros/x86_64.ff.txt");
