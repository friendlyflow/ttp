# isa/x86_64rv.pl — the hot registers of rv64: on x86_64, loaded by
# isa/x86_64.pl into its section. ttpc is written in RV64; on x86_64 the
# group rv64: (macros/x86_64.ff.txt) keeps each RV64 register in a slot of
# 8 bytes at rbx, so every register access is a memory access (on
# 2026-10-20 40% of ttpc's cycles waited on the load queue, 44-59% of its
# loads came back from a store in flight). Here the ten registers ttpc uses
# most (by perf, weighted by where the time goes) live in x86_64 registers
# of their own, %HOT, and the other ones stay in their slots.
#
# A form of a register or a slot needs other instructions, and a macro
# cannot choose between them, so mkhost.pl does: it names each op of ttpc
# by where its register operands are, rv.op.h and a letter per register
# operand in order, r in its x86_64 register, m in its slot, and passes a
# hot register as its x86_64 register (t0 as r12), any other as rv.<name>
# (its number, rv.slot gives the slot): `add a1 a0 a0` is
# `rv.add.hrrr rsi rdi rdi`, `ld 8 s11 a0` is `rv.ld.hmr 8 rv.s11 rdi`.
# Each of them has one fixed size, which is all ttpc's two passes need; a
# branch's rel is from the start of the macro, rv.backn imm n takes it from
# its jcc, n bytes in. The forms with every register in its slot are
# rv64:'s own.
#
# Where other code runs, the slots are the registers again: rv.spill puts
# the hot registers in their slots, rv.fill takes them back. rv.jitcall
# spills around the code compile time made (which writes rax ... r15 but
# rsp and rbp), cc_call_l fills around ttpc's functions it calls,
# rv.ecall.h spills and fills around rv64:'s rv.ecall (which takes a0 ...
# a7 from the slots), rv.start.h fills after rv64:'s rv.start. rax rcx rdx
# stay the scratch registers, rbx the slots, rsp the call stack, rbp
# compile time's FP.
#
# mkhost.pl reads %HOT from rv.hot: (an RV64 register, its x86_64 one),
# which no program calls.

package X86RV;

use strict;
use warnings;
use FF qw(node);

my $isa = $main::X86_ISA;

sub arg { my ($a) = @_; ref $a ? $a : node($a) }
sub C   { my ($name, @args) = @_; node($name, map { arg($_) } @args) }

my @HOT = ([t0 => "r12"], [t1 => "r13"], [a0 => "rdi"], [sp => "r14"], [a1 => "rsi"],
    [s4 => "r15"], [s6 => "r8"], [a2 => "r9"], [s5 => "r10"], [t2 => "r11"]);
my %NUM;
{
    my @n = (qw(zero ra sp gp tp t0 t1 t2 s0 s1), (map { "a$_" } 0 .. 7), (map { "s$_" } 2 .. 11), (map { "t$_" } 3 .. 6));
    @NUM{@n} = 0 .. $#n;
}
my @spill = map { C("movq.mr", $_->[1], 8 * $NUM{ $_->[0] }, "rbx") } @HOT;
my @fill = map { C("movq.m", 8 * $NUM{ $_->[0] }, "rbx", $_->[1]) } @HOT;

sub slot { node("rv.slot", node($_[0])) }
# a register operand into x86_64 register x (r: copied, m: loaded)
sub get { my ($p, $k, $x) = @_; $k eq "r" ? C("movq", $p, $x) : C("movq.m", slot($p), "rbx", $x) }
# x86_64 register x into a register operand
sub put { my ($x, $p, $k) = @_; $k eq "r" ? C("movq", $x, $p) : C("movq.mr", $x, slot($p), "rbx") }
# an operation of x86_64 with a register operand as its source: op (r) or op.m (m)
sub src { my ($op, $p, $k, $x) = @_; $k eq "r" ? C($op, $p, $x) : C("$op.m", slot($p), "rbx", $x) }

my %bytes = (movq => 3, "movq.m" => 8, cmpq => 3, "cmpq.m" => 8, "cmpq.mr" => 8, testq => 3);
sub size { my $n = 0; $n += $bytes{ $_->{content} } // die "x86_64rv: the size of $_->{content}\n" for @_; $n }

my %groups;     # group => [definitions]
# The forms of op, one per choice of r and m for its register parameters
# (regs): the body's (k: param => r or m); with every one m, rv64:'s own
# form, unless the body is always its own (own: it spills, fills).
sub def {
    my ($group, $op, $params, $regs, $body, $own) = @_;
    my @r = @$regs;
    for my $i (0 .. 2 ** @r - 1) {
        my %k = map { ($r[$_] => ($i >> $_ & 1 ? "r" : "m")) } 0 .. $#r;
        my $kinds = join "", map { $k{$_} } @r;
        my @body = !@r || $own || $kinds =~ /r/ ? $body->(\%k) : C("rv.$op", @$params);
        push @{ $groups{$group} }, node("rv.$op.h$kinds:", (map { node($_) } @$params), @body);
    }
}

# --- rv64alu: what computes a register ---------------------------------------

# rs2 rs1 rd: in rd itself when rs2 is no register of its own (rd may be
# rs1), else in rax (rd may be rs2)
for (["add", "addq"], ["sub", "subq"], ["and", "andq"], ["or", "orq"], ["xor", "xorq"], ["mul", "imulq"]) {
    my ($op, $x) = @$_;
    def("rv64alu", $op, [qw(rs2 rs1 rd)], [qw(rs2 rs1 rd)], sub {
        my ($k) = @_;
        return (get("rs1", $k->{rs1}, "rd"), src($x, "rs2", "m", "rd")) if $k->{rd} eq "r" && $k->{rs2} eq "m";
        (get("rs1", $k->{rs1}, "rax"), src($x, "rs2", $k->{rs2}, "rax"), put("rax", "rd", $k->{rd}));
    });
}
# the shifts by a register: the amount in rcx first, then in rd itself or rax
for (["sll", "shlq"], ["srl", "shrq"], ["sra", "sarq"]) {
    my ($op, $x) = @$_;
    def("rv64alu", $op, [qw(rs2 rs1 rd)], [qw(rs2 rs1 rd)], sub {
        my ($k) = @_;
        my $w = $k->{rd} eq "r" ? "rd" : "rax";
        (get("rs2", $k->{rs2}, "rcx"), get("rs1", $k->{rs1}, $w), C("$x.cl", $w), $w eq "rax" ? put("rax", "rd", "m") : ());
    });
}
# divu, remu: rv64:'s, with its operands from where they are
for (["divu", "rax", 9], ["remu", "rdx", 5]) {
    my ($op, $res, $skip) = @$_;
    def("rv64alu", $op, [qw(rs2 rs1 rd)], [qw(rs2 rs1 rd)], sub {
        my ($k) = @_;
        (get("rs2", $k->{rs2}, "rcx"), get("rs1", $k->{rs1}, "rax"), C("xorq", "rdx", "rdx"), C("testq", "rcx", "rcx"),
            C("je.8", C("addi", 7, "pc", "a0")), C("divq", "rcx"), C("jmp.8", C("addi", $skip, "pc", "a0")),
            $op eq "divu" ? C("movq.i", -1, "rax") : C("movq", "rax", "rdx"), put($res, "rd", $k->{rd}));
    });
}
def("rv64alu", "sltu", [qw(rs2 rs1 rd)], [qw(rs2 rs1 rd)], sub {
    my ($k) = @_;
    my $cmp = $k->{rs1} eq "r" ? src("cmpq", "rs2", $k->{rs2}, "rs1")
        : $k->{rs2} eq "r" ? C("cmpq.mr", "rs2", slot("rs1"), "rbx")
        : (get("rs1", "m", "rax"), src("cmpq", "rs2", "m", "rax"));
    ($cmp, C("setb", "al"), C("movzbq", "al", "rax"), put("rax", "rd", $k->{rd}));
});
# imm rs1 rd: addi of registers is a lea; else in rd itself when rs1 is in
# its slot, or in rax
for (["addi", "addq.i"], ["andi", "andq.i"], ["slli", "shlq.i"], ["srli", "shrq.i"], ["srai", "sarq.i"]) {
    my ($op, $x) = @$_;
    my $imm = $op =~ /^s/ ? "shamt" : "imm";
    def("rv64alu", $op, [$imm, qw(rs1 rd)], [qw(rs1 rd)], sub {
        my ($k) = @_;
        if ($op eq "addi" && $k->{rs1} eq "r") {
            return C("leaq.m", "imm", "rs1", "rd") if $k->{rd} eq "r";
            return (C("leaq.m", "imm", "rs1", "rax"), put("rax", "rd", "m"));
        }
        return (get("rs1", "m", "rd"), C($x, $imm, "rd")) if $k->{rd} eq "r" && $k->{rs1} eq "m";
        (get("rs1", $k->{rs1}, "rax"), C($x, $imm, "rax"), put("rax", "rd", $k->{rd}));
    });
}
def("rv64alu", "seqz", [qw(rs rd)], [qw(rs rd)], sub {
    my ($k) = @_;
    my @t = $k->{rs} eq "r" ? C("testq", "rs", "rs") : (get("rs", "m", "rax"), C("testq", "rax", "rax"));
    (@t, C("sete", "al"), C("movzbq", "al", "rax"), put("rax", "rd", $k->{rd}));
});
def("rv64alu", "neg", [qw(rs rd)], [qw(rs rd)], sub {
    my ($k) = @_;
    return (get("rs", $k->{rs}, "rd"), C("negq", "rd")) if $k->{rd} eq "r";
    (get("rs", $k->{rs}, "rax"), C("negq", "rax"), put("rax", "rd", "m"));
});
def("rv64alu", "mv", [qw(rs rd)], [qw(rs rd)], sub {
    my ($k) = @_;
    return C("movq", "rs", "rd") if $k->{rs} eq "r" && $k->{rd} eq "r";
    return put("rs", "rd", "m") if $k->{rs} eq "r";
    get("rs", "m", "rd");
});
for my $op (qw(li li32)) {
    def("rv64alu", $op, [qw(imm rd)], ["rd"], sub { C("movq.i", "imm", "rd") });
}
def("rv64alu", "lui", [qw(imm rd)], ["rd"], sub { C("movq.i", C("rv.lui32", "imm"), "rd") });
def("rv64alu", "la", [qw(sym rd)], ["rd"], sub { C("leaq.p", "sym", "rd") });

# --- rv64mem: loads and stores --------------------------------------------------

for (["ld", "movq.m"], ["ldword", "movq.m"], ["lbu", "movzbq.m"]) {
    my ($op, $x) = @$_;
    def("rv64mem", $op, [qw(imm rs1 rd)], [qw(rs1 rd)], sub {
        my ($k) = @_;
        my $w = $k->{rd} eq "r" ? "rd" : "rax";
        my @base = $k->{rs1} eq "r" ? ("rs1") : (get("rs1", "m", "rcx"), "rcx");
        my $b = pop @base;
        (@base, C($x, "imm", $b, $w), $w eq "rax" ? put("rax", "rd", "m") : ());
    });
}
for (["sd", "movq.mr", "rax"], ["sb", "movb.mr", "al"]) {
    my ($op, $x, $acc) = @$_;
    def("rv64mem", $op, [qw(imm rs2 rs1)], [qw(rs2 rs1)], sub {
        my ($k) = @_;
        my (@c, $b, $v) = ();
        if ($k->{rs1} eq "m") { push @c, get("rs1", "m", "rcx"); $b = "rcx" } else { $b = "rs1" }
        if ($k->{rs2} eq "m") { push @c, get("rs2", "m", "rax"); $v = $acc } else { $v = "rs2" }
        (@c, C($x, $v, "imm", $b));
    });
}

# --- rv64jump: branches, calls, the system ------------------------------------

# rel imm rs2 rs1: compare rs1 with rs2, imm from the start of the macro
for (["beq", "je"], ["bne", "jne"], ["blt", "jl"], ["bge", "jge"], ["bltu", "jb"], ["bgeu", "jae"]) {
    my ($op, $j) = @$_;
    def("rv64jump", $op, [qw(imm rs2 rs1)], [qw(rs2 rs1)], sub {
        my ($k) = @_;
        my $cmp = $k->{rs1} eq "r" ? src("cmpq", "rs2", $k->{rs2}, "rs1") : C("cmpq.mr", "rs2", slot("rs1"), "rbx");
        ($cmp, C($j, C("rv.backn", "imm", size($cmp))));
    });
}
# target rt rs: compare rs with rt
for (["bgt", "jg"], ["ble", "jle"], ["bgtu", "ja"]) {
    my ($op, $j) = @$_;
    def("rv64jump", $op, [qw(target rt rs)], [qw(rt rs)], sub {
        my ($k) = @_;
        ($k->{rs} eq "r" ? src("cmpq", "rt", $k->{rt}, "rs") : C("cmpq.mr", "rt", slot("rs"), "rbx"), C($j, "target"));
    });
}
for (["beqz", "je"], ["bnez", "jne"], ["bltz", "jl"], ["bgez", "jge"], ["blez", "jle"]) {
    my ($op, $j) = @$_;
    def("rv64jump", $op, [qw(target rs)], ["rs"], sub { (C("testq", "rs", "rs"), C($j, "target")) });
}
def("rv64jump", "j", ["target"], [], sub { C("jmp", "target") });
def("rv64jump", "call", ["target"], [], sub { C("call", "target") });
def("rv64jump", "ret", [], [], sub { C("ret.i", 0) });
def("rv64jump", "fence.i", [], [], sub { C("align", 1) });
def("rv64jump", "jr", ["rs"], ["rs"], sub { C("jmp.r", "rs") });
def("rv64jump", "jalr", [qw(imm rs1 rd)], [qw(rs1 rd)], sub {
    my ($k) = @_;
    return C("rv.jalr", qw(imm rs1 rd)) if $k->{rs1} eq "m";
    (C("leaq.m", "imm", "rs1", "rax"), C("call.r", "rax"));
});
def("rv64jump", "jitcall", ["rs"], ["rs"], sub {
    my ($k) = @_;
    (@spill, $k->{rs} eq "r" ? C("call.r", "rs") : C("call.m", slot("rs"), "rbx"), C("movq.mr", "rax", 8 * $NUM{a0}, "rbx"), @fill);
}, 1);
# (a body that began with a leaf would make it a parameter: the spill first)
def("rv64jump", "ecall", [], [], sub { (@spill, node("rv.ecall"), @fill) });
def("rv64jump", "start", [qw(regs stack)], [], sub { (C("rv.start", qw(regs stack)), @fill) });

$isa->add("rv64alu", @{ $groups{rv64alu} });
$isa->add("rv64mem", @{ $groups{rv64mem} });
$isa->add("rv64jump", @{ $groups{rv64jump} },
    node("rv.backn:", node("imm"), node("n"), C("sub", qw(n pc a0)), C("add", qw(imm a0 a0))),
    node("rv.spill:", @spill),
    node("rv.fill:", @fill),
    node("rv.hot:", map { C($_->[0], $_->[1]) } @HOT));

1;
