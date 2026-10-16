#!/usr/bin/env perl
# mkwide.pl — writes progs/arm/wide.ff and its GNU twin progs/arm/wide.s from
# one table, the instructions of isa/arm.pl (@ARM::WIDE: each with its GNU
# form and the operand values to test). Every instruction of the arm section
# appears at least once, its immediates and offsets at the edges of their
# range; the A32 ones first, then the Thumb ones (.thumb in wide.s).
#
#   perl progs/arm/mkwide.pl          (from src/compiler)
#
# A node holds at most 255 children: _start holds the instructions in parts
# (local labels) of 250.
#
# Registers that a test does not give are spread over r0..r12, lr (r0..r7
# for 16-bit Thumb, s0..s31 and d0..d31 for VFP), distinct within one
# instruction. Each t.it is followed by the conditional moves its block
# needs (t.mov, which GNU as wants conditional there). A host tool, core
# Perl only.

use strict;
use warnings;
use FindBin;
my $dir;
BEGIN { $dir = "$FindBin::Bin/../.." }
use lib "$dir/gen";
use FF qw(node write_ff);

my $section = do {
    do "$dir/isa/arm.pl" or die "mkwide: isa/arm.pl: " . ($@ || $!) . "\n";
};

my @CC = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le al);
my %BAR = (15 => "sy", 14 => "st", 11 => "ish", 10 => "ishst", 7 => "nsh", 6 => "nshst", 3 => "osh", 2 => "oshst");
my %RREG = map { $_ => 1 } qw(rd rn rm rs rt rt2 ra rdlo rdhi rdn rdm);

sub rname { my ($n) = @_; $n == 13 ? "sp" : $n == 14 ? "lr" : $n == 15 ? "pc" : "r$n" }

sub reglist {
    my ($mask) = @_;
    "{" . join(", ", map { rname($_) } grep { $mask >> $_ & 1 } 0 .. 15) . "}";
}

sub thumb_imm {
    my ($i) = @_;
    my $b = $i & 0xff;
    if (($i >> 10) == 0) {
        my $m = ($i >> 8) & 3;
        return $m == 0 ? $b : $m == 1 ? $b << 16 | $b : $m == 2 ? $b << 24 | $b << 8 : $b * 0x01010101;
    }
    my ($v, $r) = (0x80 | ($i & 0x7f), $i >> 7);
    (($v >> $r) | ($v << (32 - $r))) & 0xffffffff;
}

sub vfp_imm {
    my ($i) = @_;
    my $n = (($i >> 4) & 3) + (($i >> 6) & 1 ? -3 : 1);
    my $v = (16 + ($i & 15)) / 16 * 2 ** $n;
    sprintf "%s%.10g", ($i & 0x80 ? "-" : ""), $v;
}

sub kind {
    my ($p) = @_;
    return "r" if $RREG{$p};
    return "s" if $p =~ /^s[dnm]$/;
    return "d" if $p =~ /^d[dnm]$/;
    "n";
}

my (@ff, @arm, @thumb);

for my $e (@ARM::WIDE) {
    my ($name, $mode, $gnu, $params, $test) = @$e;
    my $count = 1;
    for (@$params) { $count = @{ $test->{$_} } if $test->{$_} && @{ $test->{$_} } > $count }
    for my $k (0 .. $count - 1) {
        my %v;
        for my $i (0 .. $#$params) {
            my $p = $params->[$i];
            if ($test->{$p}) { $v{$p} = $test->{$p}[$k % @{ $test->{$p} }]; next }
            my $kind = kind($p);
            die "mkwide: $name: no test value for $p\n" if $kind eq "n";
            if ($kind eq "r") {
                if ($mode eq "t") { $v{$p} = (3 * $k + 3 * $i + 1) % 8 }
                else { my @pool = (0 .. 12, 14); $v{$p} = $pool[(3 * $k + 5 * $i + 1) % @pool] }
            } else { $v{$p} = (7 * $k + 11 * $i + 31) % 32 }
        }
        # ff: the call, its operands as ttpc reads them
        my @args = map {
            my $p = $_;
            my $kind = kind($p);
            $kind eq "r" ? rname($v{$p}) : $kind eq "s" ? "s$v{$p}" : $kind eq "d" ? "d$v{$p}"
            : $p =~ /^(cond|firstcond)$/ ? "cond.$CC[$v{$p}]"
            : $p eq "regs" ? sprintf("0x%x", $v{$p}) : $v{$p}
        } @$params;
        push @ff, [$name, @args];
        # GNU
        (my $g = $gnu) =~ s/\{(\w+)([^}]*)\}/render($name, $1, $2, \%v)/ge;
        push @{ $mode eq "a" ? \@arm : \@thumb }, $g;
        if ($name eq "t.it") {
            my ($c, $mask) = ($v{firstcond}, $v{mask});
            my $len = it_len($mask);
            for my $j (1 .. $len) {
                my $cj = $j == 1 || (($mask >> (4 - $j + 1)) & 1) == ($c & 1) ? $c : $c ^ 1;
                push @ff, ["t.mov", "r9", "r8"];
                push @thumb, "mov$CC[$cj] r8, r9";
            }
        }
    }
}

# A placeholder of a GNU form, {p} or {p how}, with the value of p.
sub render {
    my ($name, $p, $how, $v) = @_;
    my %v = %$v;
    my $x = $v{$p};
    my $kind = kind($p);
    return $how eq "+1" ? rname($x + 1)
    : $how eq "|rot" ? sprintf("0x%x", (($x >> $v{rot}) | ($x << (32 - $v{rot}))) & 0xffffffff)
    : $how =~ /^\^(\d)$/ ? sprintf(".%+d", $x + $1)
    : $how eq "~" ? sprintf("0x%x", thumb_imm($x))
    : $how =~ /^%(f32|f64)$/ ? vfp_imm($x)
    : $how eq "~n" ? do { my $r = substr($p, 0, 1); $v{n} == 1 ? "{$r$x}" : "{$r$x-$r" . ($x + $v{n} - 1) . "}" }
    : $kind eq "r" ? rname($x) : $kind eq "s" ? "s$x" : $kind eq "d" ? "d$x"
    : $p eq "regs" ? reglist($x)
    : $p eq "option" ? $BAR{$x}
    : $p eq "cond" || $p eq "firstcond" ? $CC[$x]
    : $p eq "mask" && $name eq "t.it" ? it_mask($v{firstcond}, $x)
    : $p eq "mask" ? join("", map { $x >> (3 - $_) & 1 ? (qw(f s x c))[$_] : () } 0 .. 3)
    : $p eq "aif" ? join("", map { $x >> (2 - $_) & 1 ? (qw(a i f))[$_] : () } 0 .. 2)
    : $x
    ;
}

# The length of an IT block: 4 - the trailing zeros of its mask.
sub it_len { my ($m) = @_; 4 - (grep { $m >> $_ & 1 } 0 .. 3)[0] }

# it{mask}: the t and e of the instructions after the first, from the mask
sub it_mask {
    my ($c, $mask) = @_;
    my $len = it_len($mask);
    join "", map { (($mask >> (4 - $_ + 1)) & 1) == ($c & 1) ? "t" : "e" } 2 .. $len;
}

# The Thumb part must end on a word, as the program does.
my $tbytes = 0;
for (@ff) { $tbytes += $_->[0] =~ /^t\./ ? 2 : $_->[0] =~ /^t2\./ ? 4 : 0 }
if ($tbytes % 4) { push @ff, ["t.nop"]; push @thumb, "nop" }

my $prog = node("",
    node("comment", node("wide: every instruction of the arm section, made by progs/arm/mkwide.pl with its GNU twin wide.s. A32 first, then Thumb.")),
    node("origin", node("elf_base")),
    node("elf_header", map { node($_) } qw(_start file_end mem_end)),
    node("_start:", map { my $i = $_; node("part$i:", map { my ($n, @a) = @$_; node($n, map { node($_) } @a) }
        @ff[$i * 250 .. ($i * 250 + 249 < $#ff ? $i * 250 + 249 : $#ff)]) } 0 .. $#ff / 250),
    node("file_end:"), node("bss"), node("mem_end:"));

open my $o, ">:raw", "$FindBin::Bin/wide.ff" or die "mkwide: wide.ff: $!\n";
print $o write_ff($prog);
close $o;

open $o, ">", "$FindBin::Bin/wide.s" or die "mkwide: wide.s: $!\n";
print $o <<'EOF';
@ wide.s — progs/arm/wide.ff for GNU as, made with it by mkwide.pl: every
@ instruction of the arm section, offsets at the edges of their range.
@ Linked with ff32.ld, its bytes must equal what ttpc writes after its
@ 84-byte ELF header.
    .syntax unified
    .arch armv7-a
    .arch_extension idiv
    .fpu vfpv3
    .text
    .globl _start
    .arm
_start:
EOF
print $o "    $_\n" for @arm;
print $o "    .thumb\n";
print $o "    $_\n" for @thumb;
close $o;
printf "mkwide: %d instructions (%d of the section)\n", scalar(@ff), scalar(@ARM::WIDE);
