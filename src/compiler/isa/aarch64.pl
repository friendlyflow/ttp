# isa/aarch64.pl — the aarch64 section of the shared page (mkff.pl does it):
# the A64 base instructions a program needs, without SIMD vectors (data
# processing immediate and register, branches, system, loads and stores,
# exclusives, LSE atomics, scalar floating point for s and d), its
# registers, and macros/aarch64.ff.txt.
#
# An instruction is a function: its operands are its parameters, in field
# order (MSB first), followed by its encoding fields, as in isa/riscv64.pl.
# For most instructions that puts the destination last: GNU's
# `add x0, x1, #4` is `addi 4 x1 x0`, `ldr x0, [x1, #8]` is `ldr 8 x1 x0`.
#
# Names. Each encoding has one name, GNU's mnemonic with these additions:
#   - 64-bit is the default; a `w` suffix is the 32-bit form, as RV64's
#     addw: `add` (x) and `addw` (w), `ldr` (x) and `ldrw` (w), `ldrsb`
#     (to x) and `ldrsbw` (to w), `cbz` and `cbzw`.
#   - where GNU picks the form by the operands, a letter before the `w`:
#     `i` an immediate (addi, subsi, andi, orri, ccmpi; `addiw` for w),
#     `z` a compare with #0.0 (fcmpz.s), `r` an explicit register (retr).
#   - then dot suffixes: the variant of the form, `.lsl12` (the immediate
#     shifted by 12), `.sh` (shifted register: shift amount), `.ext`
#     (extended register: option amount), `.pre` `.post` (writeback),
#     `.reg` (register offset: option scale), `.lit` (pc-relative literal);
#     for floating point the type first, as RISC-V does: `fadd.s`
#     `fadd.d`, `ldr.d.pre`, `fmov.s.w` (s from w), `scvtf.d.x` (d from x),
#     `fcvtzs.w.s` (w from s), `fcvt.d.s`.
#   - b.cond keeps GNU's spelling: b.eq ... b.nv, and b.hs b.lo.
#   - `ret` is ret x30, `retr rn` returns through rn; `nop` is the hint.
#
# Operands. A register is its name (x0..x30 and w0..w30, fp lr, sp wsp,
# xzr wzr; d s h b q v 0..31 for floating point). An offset or a branch
# displacement is in bytes: the field slice drops the low bits the
# instruction scales by (uimm[14:3] for an 8-byte ldr, imm[27:2] for b);
# adrp takes the distance between the pages (both rounded down to 4 KiB).
# A signed operand is called imm, which ttpc range-checks as signed only;
# an unsigned one uimm (ttpc lets a negative one through: mind the sign).
# Immediates are their value: addi.lsl12 takes 4096 * n (uimm[23:12]);
# movz movn movk take hw (0..3) and the 16 bits. Raw fields: logical
# immediates n immr imms, bitfields immr imms, cond (0 eq ... 15 nv, also
# the constants eq ne ... of macros:), nzcv, shift (0 lsl, 1 lsr, 2 asr,
# 3 ror), option (0 uxtb, 1 uxth, 2 uxtw, 3 uxtx/lsl, 4 sxtb, 5 sxth,
# 6 sxtw, 7 sxtx), scale (0 or 1), sysreg (op0:op1:CRn:CRm:op2, 16 bits),
# crm (the option of dsb dmb), imm8 (the 8-bit encoded fmov constant).

package ISA::aarch64;

use strict;
use warnings;
use FF qw(node);
use ISA;

my $isa = ISA->new(width => sub {
    my ($name) = @_;
    return "4:0" if $name =~ /^(rd|rn|rm|ra|rt|rt2|rs)$/;
    return "3:0" if $name =~ /^(cond|nzcv|crm)$/;
    return "5:0" if $name =~ /^(immr|imms)$/;
    return "2:0" if $name eq "option";
    return "1:0" if $name =~ /^(hw|shift)$/;
    return "0"   if $name =~ /^(n|scale)$/;
    return "7:0" if $name eq "imm8";
    return "15:0" if $name eq "sysreg";
    die "aarch64: no width for operand $name\n";
});
sub def { $isa->def(@_) }

# ---------------------------------------------------------------------------
# Registers: one name pair per number (ttpc's register form), so the
# aliases take entries of their own.
# ---------------------------------------------------------------------------

$isa->add("registers",
    (map { node("x$_ w$_:", node(sprintf "%05b", $_)) } 0 .. 30),
    node("fp x29:", node("11101")),
    node("lr x30:", node("11110")),
    node("sp wsp:", node("11111")),
    node("xzr wzr:", node("11111")),
    (map { node("d$_ s$_:", node(sprintf "%05b", $_)) } 0 .. 31),
    (map { node("h$_ b$_:", node(sprintf "%05b", $_)) } 0 .. 31),
    (map { node("q$_ v$_:", node(sprintf "%05b", $_)) } 0 .. 31),
);

my @W = (["", "1"], ["w", "0"]);        # name suffix, sf

# ---------------------------------------------------------------------------
# Data processing: immediate, register
# ---------------------------------------------------------------------------

$isa->group("integer");

for my $w (@W) {
    my ($s, $sf) = @$w;
    for my $op (["add", "00"], ["adds", "01"], ["sub", "10"], ["subs", "11"]) {
        my ($m, $opS) = @$op;
        def("${m}i$s",       "sf=$sf", "opS=$opS", "op=100010", "sh=0", "uimm[11:0]", "rn", "rd");
        def("${m}i$s.lsl12", "sf=$sf", "opS=$opS", "op=100010", "sh=1", "uimm[23:12]", "rn", "rd");
    }
    for my $op (["and", "00"], ["orr", "01"], ["eor", "10"], ["ands", "11"]) {
        my ($m, $opc) = @$op;
        def("${m}i$s", "sf=$sf", "opc=$opc", "op=100100",
            ($sf ? "n" : "n=0"), "immr", "imms", "rn", "rd");
    }
    for my $op (["movn", "00"], ["movz", "10"], ["movk", "11"]) {
        my ($m, $opc) = @$op;
        def("$m$s", "sf=$sf", "opc=$opc", "op=100101", "hw", "uimm[15:0]", "rd");
    }
    for my $op (["sbfm", "00"], ["bfm", "01"], ["ubfm", "10"]) {
        my ($m, $opc) = @$op;
        def("$m$s", "sf=$sf", "opc=$opc", "op=100110", "n=$sf", "immr", "imms", "rn", "rd");
    }
    def("extr$s", "sf=$sf", "op=00100111", "n=$sf", "o0=0", "rm", "imms", "rn", "rd");
}
def("adr",  "op=0", "imm[1:0]", "fixed=10000", "imm[20:2]", "rd");
def("adrp", "op=1", "imm[13:12]", "fixed=10000", "imm[32:14]", "rd");

for my $w (@W) {
    my ($s, $sf) = @$w;
    for my $op (["add", "00"], ["adds", "01"], ["sub", "10"], ["subs", "11"]) {
        my ($m, $opS) = @$op;
        def("$m$s",     "sf=$sf", "opS=$opS", "op=01011", "shift=00", "x=0", "rm", "amount=000000", "rn", "rd");
        def("$m$s.sh",  "sf=$sf", "opS=$opS", "op=01011", "shift", "x=0", "rm", "amount[5:0]", "rn", "rd");
        def("$m$s.ext", "sf=$sf", "opS=$opS", "op=01011", "opt=00", "x=1", "rm", "option", "amount[2:0]", "rn", "rd");
    }
    for my $op (["and", "00", "0"], ["bic", "00", "1"], ["orr", "01", "0"], ["orn", "01", "1"],
                ["eor", "10", "0"], ["eon", "10", "1"], ["ands", "11", "0"], ["bics", "11", "1"]) {
        my ($m, $opc, $n) = @$op;
        def("$m$s",    "sf=$sf", "opc=$opc", "op=01010", "shift=00", "n=$n", "rm", "amount=000000", "rn", "rd");
        def("$m$s.sh", "sf=$sf", "opc=$opc", "op=01010", "shift", "n=$n", "rm", "amount[5:0]", "rn", "rd");
    }
    for my $op (["adc", "00"], ["adcs", "01"], ["sbc", "10"], ["sbcs", "11"]) {
        my ($m, $opS) = @$op;
        def("$m$s", "sf=$sf", "opS=$opS", "op=11010000", "rm", "x=000000", "rn", "rd");
    }
    for my $op (["ccmn", "0"], ["ccmp", "1"]) {
        my ($m, $o) = @$op;
        def("$m$s",  "sf=$sf", "op=$o", "S=1", "x=11010010", "rm", "cond", "x=00", "rn", "o3=0", "nzcv");
        def("${m}i$s", "sf=$sf", "op=$o", "S=1", "x=11010010", "uimm[4:0]", "cond", "x=10", "rn", "o3=0", "nzcv");
    }
    for my $op (["csel", "0", "00"], ["csinc", "0", "01"], ["csinv", "1", "00"], ["csneg", "1", "01"]) {
        my ($m, $o, $o2) = @$op;
        def("$m$s", "sf=$sf", "op=$o", "S=0", "x=11010100", "rm", "cond", "op2=$o2", "rn", "rd");
    }
    my @one = (["rbit", "000000"], ["rev16", "000001"], ["clz", "000100"], ["cls", "000101"]);
    push @one, $sf ? (["rev32", "000010"], ["rev", "000011"]) : (["rev", "000010"]);
    for my $op (@one) {
        my ($m, $opc) = @$op;
        def("$m$s", "sf=$sf", "x=1011010110", "x=00000", "opcode=$opc", "rn", "rd");
    }
    for my $op (["udiv", "000010"], ["sdiv", "000011"], ["lslv", "001000"],
                ["lsrv", "001001"], ["asrv", "001010"], ["rorv", "001011"]) {
        my ($m, $opc) = @$op;
        def("$m$s", "sf=$sf", "x=0011010110", "rm", "opcode=$opc", "rn", "rd");
    }
    def("madd$s", "sf=$sf", "x=0011011", "op31=000", "rm", "o0=0", "ra", "rn", "rd");
    def("msub$s", "sf=$sf", "x=0011011", "op31=000", "rm", "o0=1", "ra", "rn", "rd");
}
for my $op (["smaddl", "001", "0"], ["smsubl", "001", "1"], ["umaddl", "101", "0"], ["umsubl", "101", "1"]) {
    my ($m, $op31, $o0) = @$op;
    def($m, "sf=1", "x=0011011", "op31=$op31", "rm", "o0=$o0", "ra", "rn", "rd");
}
def("smulh", "sf=1", "x=0011011", "op31=010", "rm", "o0=0", "ra=11111", "rn", "rd");
def("umulh", "sf=1", "x=0011011", "op31=110", "rm", "o0=0", "ra=11111", "rn", "rd");

# ---------------------------------------------------------------------------
# Branches
# ---------------------------------------------------------------------------

$isa->group("branch");

def("b",  "op=000101", "imm[27:2]");
def("bl", "op=100101", "imm[27:2]");
my @cond = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le al nv);
def("b.$cond[$_]", "op=01010100", "imm[20:2]", "o0=0", sprintf("cond=%04b", $_)) for 0 .. 15;
def("b.hs", "op=01010100", "imm[20:2]", "o0=0", "cond=0010");
def("b.lo", "op=01010100", "imm[20:2]", "o0=0", "cond=0011");
for my $w (@W) {
    my ($s, $sf) = @$w;
    def("cbz$s",  "sf=$sf", "op=0110100", "imm[20:2]", "rt");
    def("cbnz$s", "sf=$sf", "op=0110101", "imm[20:2]", "rt");
}
def("tbz",  "bit[5]", "op=0110110", "bit[4:0]", "imm[15:2]", "rt");
def("tbnz", "bit[5]", "op=0110111", "bit[4:0]", "imm[15:2]", "rt");
def("br",   "op=1101011000011111000000", "rn", "x=00000");
def("blr",  "op=1101011000111111000000", "rn", "x=00000");
def("retr", "op=1101011001011111000000", "rn", "x=00000");
def("ret",  "insn=11010110010111110000001111000000");

# ---------------------------------------------------------------------------
# System
# ---------------------------------------------------------------------------

$isa->group("system");

for my $op (["svc", "000", "01"], ["hvc", "000", "10"], ["smc", "000", "11"],
            ["brk", "001", "00"], ["hlt", "010", "00"]) {
    my ($m, $opc, $ll) = @$op;
    def($m, "op=11010100", "opc=$opc", "uimm[15:0]", "op2=000", "ll=$ll");
}
for my $op (["nop", "000"], ["yield", "001"], ["wfe", "010"], ["wfi", "011"], ["sev", "100"], ["sevl", "101"]) {
    my ($m, $op2) = @$op;
    def($m, "op=11010101000000110010", "crm=0000", "op2=$op2", "rt=11111");
}
def("clrex", "op=11010101000000110011", "crm=1111", "op2=010", "rt=11111");
def("dsb",   "op=11010101000000110011", "crm", "op2=100", "rt=11111");
def("dmb",   "op=11010101000000110011", "crm", "op2=101", "rt=11111");
def("isb",   "op=11010101000000110011", "crm=1111", "op2=110", "rt=11111");
def("msr",   "op=1101010100", "l=0", "sysreg", "rt");
def("mrs",   "op=1101010100", "l=1", "sysreg", "rt");
def("eret",  "insn=11010110100111110000001111100000");

# ---------------------------------------------------------------------------
# Loads and stores
# ---------------------------------------------------------------------------

$isa->group("memory");

# name, size, V, opc, the bits an offset scales by
my @ls = (
    ["strb", "00", 0, "00", 0], ["ldrb", "00", 0, "01", 0],
    ["ldrsb", "00", 0, "10", 0], ["ldrsbw", "00", 0, "11", 0],
    ["strh", "01", 0, "00", 1], ["ldrh", "01", 0, "01", 1],
    ["ldrsh", "01", 0, "10", 1], ["ldrshw", "01", 0, "11", 1],
    ["strw", "10", 0, "00", 2], ["ldrw", "10", 0, "01", 2], ["ldrsw", "10", 0, "10", 2],
    ["str", "11", 0, "00", 3], ["ldr", "11", 0, "01", 3],
    ["str.s", "10", 1, "00", 2], ["ldr.s", "10", 1, "01", 2],
    ["str.d", "11", 1, "00", 3], ["ldr.d", "11", 1, "01", 3],
);
for (@ls) {
    my ($m, $size, $v, $opc, $sc) = @$_;
    (my $u = $m) =~ s/^(ld|st)r/$1ur/;          # ldrsb -> ldursb, str.d -> stur.d
    my $hi = 11 + $sc;
    def($m,        "size=$size", "op=111", "v=$v", "x=01", "opc=$opc", "uimm[$hi:$sc]", "rn", "rt");
    def("$m.pre",  "size=$size", "op=111", "v=$v", "x=00", "opc=$opc", "x=0", "imm[8:0]", "x=11", "rn", "rt");
    def("$m.post", "size=$size", "op=111", "v=$v", "x=00", "opc=$opc", "x=0", "imm[8:0]", "x=01", "rn", "rt");
    def($u,        "size=$size", "op=111", "v=$v", "x=00", "opc=$opc", "x=0", "imm[8:0]", "x=00", "rn", "rt");
    def("$m.reg",  "size=$size", "op=111", "v=$v", "x=00", "opc=$opc", "x=1", "rm", "option", "scale", "x=10", "rn", "rt");
}
for (["ldrw.lit", "00", 0], ["ldr.lit", "01", 0], ["ldrsw.lit", "10", 0], ["ldr.s.lit", "00", 1], ["ldr.d.lit", "01", 1]) {
    my ($m, $opc, $v) = @$_;
    def($m, "opc=$opc", "op=011", "v=$v", "x=00", "imm[20:2]", "rt");
}
# name, opc, V, L, the bits an offset scales by
for (["stpw", "00", 0, 0, 2], ["ldpw", "00", 0, 1, 2], ["ldpsw", "01", 0, 1, 2],
     ["stp", "10", 0, 0, 3], ["ldp", "10", 0, 1, 3],
     ["stp.s", "00", 1, 0, 2], ["ldp.s", "00", 1, 1, 2],
     ["stp.d", "01", 1, 0, 3], ["ldp.d", "01", 1, 1, 3]) {
    my ($m, $opc, $v, $l, $sc) = @$_;
    my $hi = 6 + $sc;
    for (["", "010"], [".pre", "011"], [".post", "001"]) {
        my ($sfx, $mode) = @$_;
        def("$m$sfx", "opc=$opc", "op=101", "v=$v", "mode=$mode", "l=$l", "imm[$hi:$sc]", "rt2", "rn", "rt");
    }
}

# ---------------------------------------------------------------------------
# Exclusives, load-acquire / store-release, LSE atomics
# ---------------------------------------------------------------------------

$isa->group("atomic");

my @sz = (["b", "00"], ["h", "01"], ["w", "10"], ["", "11"]);
for (@sz) {
    my ($s, $size) = @$_;
    def("stxr$s",  "size=$size", "x=001000", "o2=0", "l=0", "o1=0", "rs", "o0=0", "rt2=11111", "rn", "rt");
    def("stlxr$s", "size=$size", "x=001000", "o2=0", "l=0", "o1=0", "rs", "o0=1", "rt2=11111", "rn", "rt");
    def("ldxr$s",  "size=$size", "x=001000", "o2=0", "l=1", "o1=0", "rs=11111", "o0=0", "rt2=11111", "rn", "rt");
    def("ldaxr$s", "size=$size", "x=001000", "o2=0", "l=1", "o1=0", "rs=11111", "o0=1", "rt2=11111", "rn", "rt");
    def("stlr$s",  "size=$size", "x=001000", "o2=1", "l=0", "o1=0", "rs=11111", "o0=1", "rt2=11111", "rn", "rt");
    def("ldar$s",  "size=$size", "x=001000", "o2=1", "l=1", "o1=0", "rs=11111", "o0=1", "rt2=11111", "rn", "rt");
}
for (["w", "10"], ["", "11"]) {
    my ($s, $size) = @$_;
    def("stxp$s",  "size=$size", "x=001000", "o2=0", "l=0", "o1=1", "rs", "o0=0", "rt2", "rn", "rt");
    def("stlxp$s", "size=$size", "x=001000", "o2=0", "l=0", "o1=1", "rs", "o0=1", "rt2", "rn", "rt");
    def("ldxp$s",  "size=$size", "x=001000", "o2=0", "l=1", "o1=1", "rs=11111", "o0=0", "rt2", "rn", "rt");
    def("ldaxp$s", "size=$size", "x=001000", "o2=0", "l=1", "o1=1", "rs=11111", "o0=1", "rt2", "rn", "rt");
}
my @order = (["", "0", "0"], ["a", "1", "0"], ["l", "0", "1"], ["al", "1", "1"]);
for my $op (["ldadd", "0", "000"], ["ldclr", "0", "001"], ["ldeor", "0", "010"], ["ldset", "0", "011"],
            ["ldsmax", "0", "100"], ["ldsmin", "0", "101"], ["ldumax", "0", "110"], ["ldumin", "0", "111"],
            ["swp", "1", "000"]) {
    my ($m, $o3, $opc) = @$op;
    for my $o (@order) {
        my ($os, $a, $r) = @$o;
        for (@sz) {
            my ($s, $size) = @$_;
            def("$m$os$s", "size=$size", "x=111000", "a=$a", "r=$r", "x=1", "rs", "o3=$o3", "opc=$opc", "x=00", "rn", "rt");
        }
    }
}
for my $o (["", "0", "0"], ["a", "1", "0"], ["l", "0", "1"], ["al", "1", "1"]) {
    my ($os, $l, $o0) = @$o;
    for (@sz) {
        my ($s, $size) = @$_;
        def("cas$os$s", "size=$size", "x=001000", "o2=1", "l=$l", "o1=1", "rs", "o0=$o0", "rt2=11111", "rn", "rt");
    }
}

# ---------------------------------------------------------------------------
# Scalar floating point, s (type 00) and d (type 01)
# ---------------------------------------------------------------------------

$isa->group("float");

for my $t (["s", "00"], ["d", "01"]) {
    my ($p, $type) = @$t;
    my @f = ("x=00011110", "type=$type", "x=1");
    for my $op (["fmov", "000000"], ["fabs", "000001"], ["fneg", "000010"], ["fsqrt", "000011"],
                ["frintn", "001000"], ["frintp", "001001"], ["frintm", "001010"], ["frintz", "001011"],
                ["frinta", "001100"], ["frintx", "001110"], ["frinti", "001111"]) {
        def("$op->[0].$p", @f, "opcode=$op->[1]", "x=10000", "rn", "rd");
    }
    def($p eq "s" ? "fcvt.d.s" : "fcvt.s.d", @f, "opcode=" . ($p eq "s" ? "000101" : "000100"), "x=10000", "rn", "rd");
    def("fmovi.$p", @f, "imm8", "x=100", "x=00000", "rd");
    for my $op (["fmul", "0000"], ["fdiv", "0001"], ["fadd", "0010"], ["fsub", "0011"],
                ["fmax", "0100"], ["fmin", "0101"], ["fmaxnm", "0110"], ["fminnm", "0111"], ["fnmul", "1000"]) {
        def("$op->[0].$p", @f, "rm", "opcode=$op->[1]", "x=10", "rn", "rd");
    }
    for my $op (["fmadd", "0", "0"], ["fmsub", "0", "1"], ["fnmadd", "1", "0"], ["fnmsub", "1", "1"]) {
        def("$op->[0].$p", "x=00011111", "type=$type", "o1=$op->[1]", "rm", "o0=$op->[2]", "ra", "rn", "rd");
    }
    def("fcmp.$p",   @f, "rm", "x=001000", "rn", "opc=00000");
    def("fcmpz.$p",  @f, "rm=00000", "x=001000", "rn", "opc=01000");
    def("fcmpe.$p",  @f, "rm", "x=001000", "rn", "opc=10000");
    def("fcmpez.$p", @f, "rm=00000", "x=001000", "rn", "opc=11000");
    def("fccmp.$p",  @f, "rm", "cond", "x=01", "rn", "op=0", "nzcv");
    def("fccmpe.$p", @f, "rm", "cond", "x=01", "rn", "op=1", "nzcv");
    def("fcsel.$p",  @f, "rm", "cond", "x=11", "rn", "rd");
    # Between the general registers and this one: sf, rmode, opcode.
    for my $g (["w", "0"], ["x", "1"]) {
        my ($r, $sf) = @$g;
        my @c = ("sf=$sf", "x=0011110", "type=$type", "x=1");
        def("scvtf.$p.$r", @c, "rmode=00", "opcode=010", "x=000000", "rn", "rd");
        def("ucvtf.$p.$r", @c, "rmode=00", "opcode=011", "x=000000", "rn", "rd");
        for my $op (["fcvtns", "00", "000"], ["fcvtnu", "00", "001"], ["fcvtas", "00", "100"], ["fcvtau", "00", "101"],
                    ["fcvtps", "01", "000"], ["fcvtpu", "01", "001"], ["fcvtms", "10", "000"], ["fcvtmu", "10", "001"],
                    ["fcvtzs", "11", "000"], ["fcvtzu", "11", "001"]) {
            def("$op->[0].$r.$p", @c, "rmode=$op->[1]", "opcode=$op->[2]", "x=000000", "rn", "rd");
        }
    }
}
# fmov between a general register and one of the same size, bits unchanged.
def("fmov.s.w", "sf=0", "x=0011110", "type=00", "x=1", "rmode=00", "opcode=111", "x=000000", "rn", "rd");
def("fmov.w.s", "sf=0", "x=0011110", "type=00", "x=1", "rmode=00", "opcode=110", "x=000000", "rn", "rd");
def("fmov.d.x", "sf=1", "x=0011110", "type=01", "x=1", "rmode=00", "opcode=111", "x=000000", "rn", "rd");
def("fmov.x.d", "sf=1", "x=0011110", "type=01", "x=1", "rmode=00", "opcode=110", "x=000000", "rn", "rd");

$isa->section("aarch64", "macros/aarch64.ff.txt");
