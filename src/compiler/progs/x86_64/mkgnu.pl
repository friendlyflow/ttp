#!/usr/bin/env perl
# mkgnu.pl — makes progs/x86_64/gnu.ff and its GNU twin gnu.s from one
# table: every form isa/x86_64gnu.pl makes (@main::X86_GNU: its name, its
# operands with their kinds, its line for GNU as), each used once, with
# operands for which GNU as, left to itself, picks that form's encoding:
# no REX where the form has none (the first eight registers), a register
# from r8 up where it has one and no W, a displacement of the size the
# form names (0, a byte, 32 bits), rsp or r12 as the base of an s form.
#
#   perl progs/x86_64/mkgnu.pl          writes gnu.ff and gnu.s here
#
# rax (and al, eax ...) is left out of the registers: GNU as has shorter
# forms for it (add $imm, %eax; test $imm, %al). The ff is a program-only
# tree, assembled with the shared page (make x86gnu compares the bytes).
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../gen";
use FF qw(node ttp_license write_ff);

my $dir = $FindBin::Bin;
my $top = "$FindBin::Bin/../..";
our (@X86_WIDE, @X86_GNU);
my $section = do "$top/isa/x86_64.pl";
die "mkgnu: $@" if $@;
die "mkgnu: isa/x86_64.pl: $!\n" unless defined $section;

my %name = (
    q => [qw(rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15)],
    l => [qw(eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d)],
    w => [qw(ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w)],
    b => [qw(al cl dl bl spl bpl sil dil r8b r9b r10b r11b r12b r13b r14b r15b)],
    x => [map { "xmm$_" } 0 .. 15],
);
# a byte register without REX: 4..7 are ah ch dh bh
my @bn = qw(al cl dl bl ah ch dh bh);

# The values of each kind, taken in turn: registers by number.
my %vals = (
    lo    => [1, 2, 3, 6, 7, 5, 4],
    hi    => [8, 12, 13, 15, 9, 10, 11, 14],
    any   => [1, 9, 2, 12, 3, 13, 6, 14, 7, 15, 5, 8],
    blo   => [1, 2, 3, 6, 7, 5, 4],         # (cl dl bl dh bh ch ah)
    bhi   => [8, 12, 4, 13, 5, 15, 6, 7],   # (r8b r12b spl ... : REX)
    bany  => [1, 9, 2, 12, 3, 13, 4, 14, 6, 15],
    "bm0.lo" => [1, 2, 3, 6, 7], "bm0.hi" => [8, 9, 10, 11, 14, 15], bm0 => [1, 8, 2, 9, 3, 10, 6, 11, 7, 14, 15],
    "bm.lo"  => [1, 2, 3, 5, 6, 7], "bm.hi" => [8, 9, 10, 11, 13, 14, 15], bm => [1, 8, 5, 13, 2, 9, 3, 10, 6, 11, 7, 14, 15],
    "bs.lo"  => [4], "bs.hi" => [12], bs => [4, 12],
    "bx0.lo" => [0, 1, 2, 3, 4, 6, 7], "bx0.hi" => [8, 9, 10, 11, 12, 14, 15], bx0 => [0, 8, 1, 12, 2, 9, 4, 14, 6, 15],
    "base.lo" => [0, 1, 2, 3, 4, 5, 6, 7], "base.hi" => [8, 9, 12, 13, 15], base => [0, 9, 4, 13, 5, 12, 7, 15],
    "index.lo" => [0, 1, 2, 3, 5, 6, 7], "index.hi" => [8, 9, 12, 13, 15], index => [1, 9, 5, 12, 0, 15, 6],
    scale => [1, 2, 4, 8],
    d0    => [0],
    d8    => [-128, 127, -1, 64, 8],
    d32   => [-2147483648, 2147483647, 4660, 128, -129],
    i8    => [-128, 127, -1, 0],
    ib    => [-128, 127, 255],
    i16   => [-32768, 32767, 4660, 200],
    i32   => [-2147483648, 2147483647, 305419896, 1000],
    u8    => [0, 255, 63, 7],
    label => [qw(gnu_back gnu_fwd)],
);
my %next;
sub take {
    my ($k) = @_;
    my $list = $vals{$k} or die "mkgnu: no values for $k\n";
    $list->[$next{$k}++ % @$list];
}

my (@ff, @s, @page);
sub insn { my ($n, $args, $gnu) = @_; push @ff, node($n, map { node($_) } @$args); push @s, "    $gnu" }
sub block { my ($name) = @_; push @page, node("$name:", @ff); @ff = () }

push @s, "_start:";
insn("movl.i", [0, "edi"], "{rex} movl \$0, %edi");
insn("movl.i", ["SYS_exit", "eax"], "{rex} movl \$60, %eax");
insn("syscall", [], "syscall");
block("_start");
push @page, node("gnu_back:");
push @s, "gnu_back:";

my $blk = 0;
for my $f (@X86_GNU) {
    my ($name, $params, $gnu) = @$f;
    if (@ff >= 200) { block("g$blk"); $blk++ }
    push @s, "g$blk:" unless @ff;
    my @args;
    for (@$params) {
        my ($p, $k) = split /:/, $_, 2;
        my ($ff, $as);
        if ($k =~ /^([qlwb])\.acc$/) {
            $ff = $name{$1}[0];
            $as = "%$ff";
        } elsif ($k =~ /^([qlwbx])\.(lo|hi|any)$/) {
            my ($sz, $c) = ($1, $2);
            my $n = take($sz eq "b" ? "b$c" : $c);
            $ff = $sz eq "b" && $c eq "lo" ? $bn[$n] : $name{$sz}[$n];
            $as = "%$ff";
        } elsif ($k =~ /^(bm0|bm|bs|bx0|base|index)(\.(lo|hi))?$/) {
            $ff = $name{q}[take($k)];
            $as = "%$ff";
        } else {
            $ff = $as = take($k);
        }
        push @args, $ff;
        $gnu =~ s/<\Q$p\E>/$as/g;
    }
    die "mkgnu: $name: $gnu\n" if $gnu =~ /<\w+>/;
    insn($name, \@args, $gnu);
}
block("g$blk");
push @page, node("gnu_fwd:");
push @s, "gnu_fwd:";

open my $out, ">:raw", "$dir/gnu.ff" or die "mkgnu: gnu.ff: $!\n";
print $out write_ff(node("", ttp_license(),
    node("comment", node("gnu.ff: every form of isa/x86_64gnu.pl once, the encodings GNU as picks, made by mkgnu.pl with its GNU twin gnu.s. Run, it exits at once.")),
    node("origin", node("elf_base")),
    node("elf_header", map { node($_) } qw(_start file_end mem_end)),
    @page,
    node("file_end:"), node("bss"), node("mem_end:")));
close $out;

open $out, ">", "$dir/gnu.s" or die "mkgnu: gnu.s: $!\n";
print $out <<'END';
# gnu.s — progs/x86_64/gnu.ff for GNU as (x86_64-elf-as), linked with
# ff64.ld: the bytes must be the same. Made by mkgnu.pl with gnu.ff, every
# form of isa/x86_64gnu.pl once, its operands such that GNU as, left to
# itself, picks that form's encoding.
    .code64
    .globl _start
END
print $out "$_\n" for @s;
close $out;
printf "mkgnu: %d forms in %d blocks\n", scalar @X86_GNU, $blk + 1;
