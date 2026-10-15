#!/usr/bin/env perl
# mkff.pl — writes test.ff: the RV64GC instruction set as an ff node tree.
#
#   perl mkff.pl > test.ff
#
# A host tool (core Perl only), not part of ttpc. The ff format is the one of
# the sicompass text editor (texteditor-plugin-sicompass/src/ff.rs): a node
# is written depth-first as
#
#   hash[32] · children_len u8 · children · content_len u8 · content
#
# with hash = sha256(child_0.hash ‖ … ‖ child_n.hash ‖ sha256(content)).
#
# Functions and calls: a node ending in ':' is a function, its leading
# children without ':' are its parameters. A node without ':' is a call, its
# children are the arguments, bound by position to the parameters of the
# function of that name. An argument is a parameter name of the enclosing
# function, a register (a0, t0, ...) or a decimal number. A function returns
# its value in a0; t0 and t1 are scratch. A call of an instruction (addi,
# slli, ...) assembles to that instruction's machine word, a call of any
# other function expands in place.
#
# The tree: comment:, the registers (x0..x31, f0..f31, each with its 5-bit
# number as child), bits:, the slice functions, then every instruction
# (RV64I, Zifencei, Zicsr, the privileged mret/sret/wfi/sfence.vma, M, A, F,
# D, C). A node holds at most 255 children, so the list is split over the
# root's children 0:, 1:, ... The last root child holds the program: the
# calls that ttpc assembles, in order.
#
# An instruction is a function: its operands (rd, rs1, imm, ...) are its
# parameters, in field order, followed by its encoding fields in bit order,
# MSB first. A fixed field (opcode, funct*, ...) is a definition with its bits
# as child; an operand field is a call of a slice function with the operand
# as arg: imm[20|10:1|11|19:12] imm, and for a bare operand the bits it
# takes, rd[4:0] rd or rs1'[2:0] rs1'. So every field shows its width, and
# the parameters are exactly the leading children that are leaves.
#
#   bits: value left right pos   a0 = ((value << left) >> right) << pos
#
# moves bits hi:lo of value to bit pos for left = 63-hi, right = 63-hi+lo.
# A slice function base[seg|seg|...]: base returns its field: one bits call
# per segment, or-ed together, the first segment in the field's top bits.

use strict;
use warnings;
use Digest::SHA qw(sha256);

sub node { my ($content, @children) = @_; { content => $content, children => \@children } }

sub call { my ($name, @args) = @_; node($name, map { node($_) } @args) }

# Slice names (imm[11:0], ...) in order of first use, each gets a function.
my (@slices, %slices);

# The bits of a bare operand field, so that it is a slice like imm[11:0]:
# a register is 5 bits, a primed one (rd', x8..x15) its low 3.
sub operand_bits {
    my ($name) = @_;
    return "2:0"  if $name =~ /'/ || $name eq "rm";
    return "4:0"  if $name =~ m{^(rd|rs1|rs2|rs3|rd/rs1)$};
    return "11:0" if $name eq "csr";
    return "3:0"  if $name =~ /^(fm|pred|succ)$/;
    return "0"    if $name =~ /^(aq|rl)$/;
    die "mkff: no width for operand $name\n";
}

# "funct3=000" -> funct3: with child 000; "rd" -> call rd[4:0] with arg rd;
# "imm[11:0]" -> call imm[11:0] with arg imm.
sub field {
    my ($name, $bits) = split /=/, $_[0], 2;
    return node("$name:", node($bits)) if defined $bits;
    $name .= "[" . operand_bits($name) . "]" unless $name =~ /\[/;
    $name =~ /^(.+)\[/;
    push @slices, $name unless $slices{$name}++;
    call($name, $1);
}

# The operand fields' base names, in field order, are the parameters.
sub insn {
    my ($name, @fields) = @_;
    my (%seen, @params);
    for (grep { !/=/ } @fields) {
        (my $p = $_) =~ s/\[.*//;
        push @params, $p unless $seen{$p}++;
    }
    node("$name:", (map { node($_) } @params), map { field($_) } @fields);
}

# ---------------------------------------------------------------------------
# Bit slices
# ---------------------------------------------------------------------------

my $bits = node("bits:", (map { node($_) } qw(value left right pos)),
    call("slli", qw(left value a0)),        # drop the bits above hi
    call("srli", qw(right a0 a0)),          # hi:lo down to bit 0
    call("slli", qw(pos a0 a0)));           # and up to pos

# "imm[20|10:1|11|19:12]" -> its function with parameter imm.
sub slice {
    my ($name) = @_;
    my ($base, $list) = $name =~ /^(.+)\[(.+)\]$/ or die "mkff: bad slice $name\n";
    my @segs = map { /^(\d+)(?::(\d+))?$/ or die "mkff: bad slice $name\n"; [$1, $2 // $1] }
        split /\|/, $list;
    my $pos = 0;
    $pos += $_->[0] - $_->[1] + 1 for @segs;
    my @args;
    for (@segs) {
        my ($hi, $lo) = @$_;
        $pos -= $hi - $lo + 1;
        push @args, [63 - $hi, 63 - $hi + $lo, $pos];
    }
    return node("$name:", node($base), call("bits", $base, @{ $args[0] })) if @args == 1;
    node("$name:", node($base),
        call("addi", 0, $base, "t1"),       # keep base, a0 is overwritten
        (map { (call("bits", "t1", @{ $args[$_] }),
                $_ ? call("or", qw(a0 t0 t0)) : call("addi", qw(0 a0 t0))) } 0 .. $#args),
        call("addi", qw(0 t0 a0)));
}

# ---------------------------------------------------------------------------
# Registers
# ---------------------------------------------------------------------------

my @xabi = qw(zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7
              s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6);
my @fabi = qw(ft0 ft1 ft2 ft3 ft4 ft5 ft6 ft7 fs0 fs1 fa0 fa1 fa2 fa3 fa4 fa5
              fa6 fa7 fs2 fs3 fs4 fs5 fs6 fs7 fs8 fs9 fs10 fs11 ft8 ft9 ft10 ft11);

my @registers = (
    (map { node("x$_ $xabi[$_]:", node(sprintf "%05b", $_)) } 0 .. 31),
    (map { node("f$_ $fabi[$_]:", node(sprintf "%05b", $_)) } 0 .. 31),
);

# ---------------------------------------------------------------------------
# 32-bit formats: field lists, MSB first
# ---------------------------------------------------------------------------

sub R    { my ($f7, $f3, $op) = @_; ("funct7=$f7", "rs2", "rs1", "funct3=$f3", "rd", "opcode=$op") }
sub I    { my ($f3, $op) = @_; ("imm[11:0]", "rs1", "funct3=$f3", "rd", "opcode=$op") }
sub S    { my ($f3, $op) = @_; ("imm[11:5]", "rs2", "rs1", "funct3=$f3", "imm[4:0]", "opcode=$op") }
sub B    { my ($f3) = @_; ("imm[12|10:5]", "rs2", "rs1", "funct3=$f3", "imm[4:1|11]", "opcode=1100011") }
sub U    { my ($op) = @_; ("imm[31:12]", "rd", "opcode=$op") }
sub J    { ("imm[20|10:1|11|19:12]", "rd", "opcode=1101111") }
sub SH64 { my ($f6, $f3) = @_; ("funct6=$f6", "shamt[5:0]", "rs1", "funct3=$f3", "rd", "opcode=0010011") }
sub SHW  { my ($f7, $f3) = @_; ("funct7=$f7", "shamt[4:0]", "rs1", "funct3=$f3", "rd", "opcode=0011011") }
sub SYS  { my ($f12) = @_; ("funct12=$f12", "rs1=00000", "funct3=000", "rd=00000", "opcode=1110011") }
sub CSR  { my ($f3) = @_; ("csr", "rs1", "funct3=$f3", "rd", "opcode=1110011") }
sub CSRI { my ($f3) = @_; ("csr", "uimm[4:0]", "funct3=$f3", "rd", "opcode=1110011") }
sub AMO  { my ($f5, $f3) = @_; ("funct5=$f5", "aq", "rl", "rs2", "rs1", "funct3=$f3", "rd", "opcode=0101111") }
sub LR   { my ($f3) = @_; ("funct5=00010", "aq", "rl", "rs2=00000", "rs1", "funct3=$f3", "rd", "opcode=0101111") }
sub R4   { my ($f2, $op) = @_; ("rs3", "funct2=$f2", "rs2", "rs1", "rm", "rd", "opcode=$op") }
sub FR   { my ($f7, $f3) = @_; R($f7, $f3, "1010011") }                 # fixed funct3
sub FRM  { my ($f7) = @_; ("funct7=$f7", "rs2", "rs1", "rm", "rd", "opcode=1010011") }
sub FU   { my ($f7, $rs2) = @_; ("funct7=$f7", "rs2=$rs2", "rs1", "rm", "rd", "opcode=1010011") }
sub FUX  { my ($f7, $f3) = @_; ("funct7=$f7", "rs2=00000", "rs1", "funct3=$f3", "rd", "opcode=1010011") }

# ---------------------------------------------------------------------------
# Instructions
# ---------------------------------------------------------------------------

my @insns;
sub def { push @insns, insn(@_) }

# RV64I
def("lui",   U("0110111"));
def("auipc", U("0010111"));
def("jal",   J());
def("jalr",  I("000", "1100111"));
def("beq",  B("000")); def("bne",  B("001"));
def("blt",  B("100")); def("bge",  B("101"));
def("bltu", B("110")); def("bgeu", B("111"));
def("lb",  I("000", "0000011")); def("lh",  I("001", "0000011"));
def("lw",  I("010", "0000011")); def("ld",  I("011", "0000011"));
def("lbu", I("100", "0000011")); def("lhu", I("101", "0000011"));
def("lwu", I("110", "0000011"));
def("sb", S("000", "0100011")); def("sh", S("001", "0100011"));
def("sw", S("010", "0100011")); def("sd", S("011", "0100011"));
def("addi",  I("000", "0010011")); def("slti", I("010", "0010011"));
def("sltiu", I("011", "0010011")); def("xori", I("100", "0010011"));
def("ori",   I("110", "0010011")); def("andi", I("111", "0010011"));
def("slli", SH64("000000", "001"));
def("srli", SH64("000000", "101"));
def("srai", SH64("010000", "101"));
def("add",  R("0000000", "000", "0110011")); def("sub", R("0100000", "000", "0110011"));
def("sll",  R("0000000", "001", "0110011")); def("slt", R("0000000", "010", "0110011"));
def("sltu", R("0000000", "011", "0110011")); def("xor", R("0000000", "100", "0110011"));
def("srl",  R("0000000", "101", "0110011")); def("sra", R("0100000", "101", "0110011"));
def("or",   R("0000000", "110", "0110011")); def("and", R("0000000", "111", "0110011"));
def("fence", "fm", "pred", "succ", "rs1=00000", "funct3=000", "rd=00000", "opcode=0001111");
def("ecall",  SYS("000000000000"));
def("ebreak", SYS("000000000001"));
def("addiw", I("000", "0011011"));
def("slliw", SHW("0000000", "001"));
def("srliw", SHW("0000000", "101"));
def("sraiw", SHW("0100000", "101"));
def("addw", R("0000000", "000", "0111011")); def("subw", R("0100000", "000", "0111011"));
def("sllw", R("0000000", "001", "0111011")); def("srlw", R("0000000", "101", "0111011"));
def("sraw", R("0100000", "101", "0111011"));

# Zifencei
def("fence.i", "imm[11:0]=000000000000", "rs1=00000", "funct3=001", "rd=00000", "opcode=0001111");

# Zicsr
def("csrrw",  CSR("001"));  def("csrrs",  CSR("010"));  def("csrrc",  CSR("011"));
def("csrrwi", CSRI("101")); def("csrrsi", CSRI("110")); def("csrrci", CSRI("111"));

# Privileged
def("mret", SYS("001100000010"));
def("sret", SYS("000100000010"));
def("wfi",  SYS("000100000101"));
def("sfence.vma", "funct7=0001001", "rs2", "rs1", "funct3=000", "rd=00000", "opcode=1110011");

# M
my @m = (["mul", "000"], ["mulh", "001"], ["mulhsu", "010"], ["mulhu", "011"],
         ["div", "100"], ["divu", "101"], ["rem", "110"], ["remu", "111"]);
def($_->[0], R("0000001", $_->[1], "0110011")) for @m;
def("${\ $_->[0]}w", R("0000001", $_->[1], "0111011")) for grep { $_->[0] =~ /^(mul|div|divu|rem|remu)$/ } @m;

# A: .w then .d
for my $w (["w", "010"], ["d", "011"]) {
    my ($sfx, $f3) = @$w;
    def("lr.$sfx", LR($f3));
    def("sc.$sfx", AMO("00011", $f3));
    def("amoswap.$sfx", AMO("00001", $f3));
    def("amoadd.$sfx",  AMO("00000", $f3));
    def("amoxor.$sfx",  AMO("00100", $f3));
    def("amoand.$sfx",  AMO("01100", $f3));
    def("amoor.$sfx",   AMO("01000", $f3));
    def("amomin.$sfx",  AMO("10000", $f3));
    def("amomax.$sfx",  AMO("10100", $f3));
    def("amominu.$sfx", AMO("11000", $f3));
    def("amomaxu.$sfx", AMO("11100", $f3));
}

# F then D: the low two bits of funct7 (and funct2) select the format.
for my $p (["s", "00", "010", "w"], ["d", "01", "011", "d"]) {
    my ($t, $fmt, $width, $mv) = @$p;
    def("fl$mv", I($width, "0000111"));
    def("fs$mv", S($width, "0100111"));
    def("fmadd.$t",  R4($fmt, "1000011"));
    def("fmsub.$t",  R4($fmt, "1000111"));
    def("fnmsub.$t", R4($fmt, "1001011"));
    def("fnmadd.$t", R4($fmt, "1001111"));
    def("fadd.$t",  FRM("00000$fmt"));
    def("fsub.$t",  FRM("00001$fmt"));
    def("fmul.$t",  FRM("00010$fmt"));
    def("fdiv.$t",  FRM("00011$fmt"));
    def("fsqrt.$t", FU("01011$fmt", "00000"));
    def("fsgnj.$t",  FR("00100$fmt", "000"));
    def("fsgnjn.$t", FR("00100$fmt", "001"));
    def("fsgnjx.$t", FR("00100$fmt", "010"));
    def("fmin.$t", FR("00101$fmt", "000"));
    def("fmax.$t", FR("00101$fmt", "001"));
    if ($t eq "d") {
        def("fcvt.s.d", FU("0100000", "00001"));
        def("fcvt.d.s", FU("0100001", "00000"));
    }
    def("feq.$t", FR("10100$fmt", "010"));
    def("flt.$t", FR("10100$fmt", "001"));
    def("fle.$t", FR("10100$fmt", "000"));
    def("fclass.$t", FUX("11100$fmt", "001"));
    def("fcvt.w.$t",  FU("11000$fmt", "00000"));
    def("fcvt.wu.$t", FU("11000$fmt", "00001"));
    def("fcvt.l.$t",  FU("11000$fmt", "00010"));
    def("fcvt.lu.$t", FU("11000$fmt", "00011"));
    def("fcvt.$t.w",  FU("11010$fmt", "00000"));
    def("fcvt.$t.wu", FU("11010$fmt", "00001"));
    def("fcvt.$t.l",  FU("11010$fmt", "00010"));
    def("fcvt.$t.lu", FU("11010$fmt", "00011"));
    def("fmv.x.$mv", FUX("11100$fmt", "000"));
    def("fmv.$mv.x", FUX("11110$fmt", "000"));
}

# C (RV64C + compressed D), 16-bit, MSB first. Registers written rd' etc.
# are the 3-bit x8..x15 / f8..f15 fields.
# Quadrant 0
def("c.addi4spn", "funct3=000", "nzuimm[5:4|9:6|2|3]", "rd'", "op=00");
def("c.fld", "funct3=001", "uimm[5:3]", "rs1'", "uimm[7:6]", "rd'", "op=00");
def("c.lw",  "funct3=010", "uimm[5:3]", "rs1'", "uimm[2|6]", "rd'", "op=00");
def("c.ld",  "funct3=011", "uimm[5:3]", "rs1'", "uimm[7:6]", "rd'", "op=00");
def("c.fsd", "funct3=101", "uimm[5:3]", "rs1'", "uimm[7:6]", "rs2'", "op=00");
def("c.sw",  "funct3=110", "uimm[5:3]", "rs1'", "uimm[2|6]", "rs2'", "op=00");
def("c.sd",  "funct3=111", "uimm[5:3]", "rs1'", "uimm[7:6]", "rs2'", "op=00");
# Quadrant 1
def("c.nop",   "funct3=000", "imm[5]=0", "rd=00000", "imm[4:0]=00000", "op=01");
def("c.addi",  "funct3=000", "nzimm[5]", "rd/rs1", "nzimm[4:0]", "op=01");
def("c.addiw", "funct3=001", "imm[5]", "rd/rs1", "imm[4:0]", "op=01");
def("c.li",    "funct3=010", "imm[5]", "rd", "imm[4:0]", "op=01");
def("c.addi16sp", "funct3=011", "nzimm[9]", "rd=00010", "nzimm[4|6|8:7|5]", "op=01");
def("c.lui",   "funct3=011", "nzimm[17]", "rd", "nzimm[16:12]", "op=01");
def("c.srli",  "funct3=100", "nzuimm[5]", "funct2=00", "rd'/rs1'", "nzuimm[4:0]", "op=01");
def("c.srai",  "funct3=100", "nzuimm[5]", "funct2=01", "rd'/rs1'", "nzuimm[4:0]", "op=01");
def("c.andi",  "funct3=100", "imm[5]", "funct2=10", "rd'/rs1'", "imm[4:0]", "op=01");
def("c.sub",  "funct6=100011", "rd'/rs1'", "funct2=00", "rs2'", "op=01");
def("c.xor",  "funct6=100011", "rd'/rs1'", "funct2=01", "rs2'", "op=01");
def("c.or",   "funct6=100011", "rd'/rs1'", "funct2=10", "rs2'", "op=01");
def("c.and",  "funct6=100011", "rd'/rs1'", "funct2=11", "rs2'", "op=01");
def("c.subw", "funct6=100111", "rd'/rs1'", "funct2=00", "rs2'", "op=01");
def("c.addw", "funct6=100111", "rd'/rs1'", "funct2=01", "rs2'", "op=01");
def("c.j",    "funct3=101", "imm[11|4|9:8|10|6|7|3:1|5]", "op=01");
def("c.beqz", "funct3=110", "imm[8|4:3]", "rs1'", "imm[7:6|2:1|5]", "op=01");
def("c.bnez", "funct3=111", "imm[8|4:3]", "rs1'", "imm[7:6|2:1|5]", "op=01");
# Quadrant 2
def("c.slli",  "funct3=000", "nzuimm[5]", "rd/rs1", "nzuimm[4:0]", "op=10");
def("c.fldsp", "funct3=001", "uimm[5]", "rd", "uimm[4:3|8:6]", "op=10");
def("c.lwsp",  "funct3=010", "uimm[5]", "rd", "uimm[4:2|7:6]", "op=10");
def("c.ldsp",  "funct3=011", "uimm[5]", "rd", "uimm[4:3|8:6]", "op=10");
def("c.jr",     "funct4=1000", "rs1", "rs2=00000", "op=10");
def("c.mv",     "funct4=1000", "rd", "rs2", "op=10");
def("c.ebreak", "funct4=1001", "rd=00000", "rs2=00000", "op=10");
def("c.jalr",   "funct4=1001", "rs1", "rs2=00000", "op=10");
def("c.add",    "funct4=1001", "rd/rs1", "rs2", "op=10");
def("c.fsdsp", "funct3=101", "uimm[5:3|8:6]", "rs2", "op=10");
def("c.swsp",  "funct3=110", "uimm[5:2|7:6]", "rs2", "op=10");
def("c.sdsp",  "funct3=111", "uimm[5:3|8:6]", "rs2", "op=10");

# ---------------------------------------------------------------------------
# Program: the calls ttpc assembles, after the definitions
# ---------------------------------------------------------------------------

my @program = (
    call("addi", qw(42 zero a0)),           # li a0, 42
    call("addi", qw(93 zero a7)),           # li a7, SYS_exit
    call("ecall"),                          # exit(42); the rest only checks encodings
    call("sd", qw(-8 a0 sp)),               # sd a0, -8(sp)
    call("ld", qw(16 sp s0)),               # ld s0, 16(sp)
    call("lui", qw(305418240 t0)),          # lui t0, 0x12345
    call("beq", qw(16 a1 a0)),              # beq a0, a1, .+16
    call("jal", qw(-12 ra)),                # jal ra, .-12
    call("slli", qw(3 a0 a0)),              # slli a0, a0, 3
    call("sub", qw(a1 a0 a0)),              # sub a0, a0, a1
    call("c.addi", qw(-1 a0)),              # c.addi a0, -1
    call("c.ld", qw(8 s0 a0)),              # c.ld a0, 8(s0)
    call("c.mv", qw(a0 a1)),                # c.mv a0, a1
);

# ---------------------------------------------------------------------------
# Tree, hashes, bytes
# ---------------------------------------------------------------------------

my @items = (node("comment:"), @registers, $bits, (map { slice($_) } @slices), @insns);
my @pages;
push @pages, node(scalar(@pages) . ":", splice(@items, 0, 255)) while @items;
push @pages, node(scalar(@pages) . ":", @program);
my $root = node("", @pages);

sub rehash {
    my ($n) = @_;
    my $d = Digest::SHA->new(256);
    $d->add(rehash($_)) for @{ $n->{children} };
    $d->add(sha256($n->{content}));
    $n->{hash} = $d->digest;
}

sub emit {
    my ($n) = @_;
    my $count = @{ $n->{children} };
    my $len = length $n->{content};
    die "mkff: $n->{content} has $count children (max 255)\n" if $count > 255;
    die "mkff: $n->{content} is $len bytes (max 255)\n" if $len > 255;
    join "", $n->{hash}, chr($count), (map { emit($_) } @{ $n->{children} }),
        chr($len), $n->{content};
}

rehash($root);
binmode STDOUT;
print emit($root);
