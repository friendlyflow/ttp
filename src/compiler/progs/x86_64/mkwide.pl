#!/usr/bin/env perl
# mkwide.pl — makes progs/x86_64/wide.ff and its GNU twin wide.s from one
# table: every form of the x86_64 section, as isa/x86_64.pl lists them in
# @main::X86_WIDE (its name, its operands with their kinds, its line for
# GNU as). Each form is used once, its operands taken in turn from lists
# of edge values: displacements and immediates at the ends of their range,
# r12, r13, r15, rsp and rbp as a base, high registers as an index.
#
#   perl progs/x86_64/mkwide.pl          writes wide.ff and wide.s here
#
# rax is left out of the registers: GNU as has shorter forms for it (add
# $imm, %rax; xchg %rax, %reg; test $imm, %al) where ff keeps one form.
# The immediates of an imm32 or imm16 form do not fit 8 bits, and shift
# counts are not 1, for the same reason. The rel8 jumps go to a label next
# to them; at the end two reach -128 and +127.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../gen";
use FF qw(node ttp_license write_ff);

my $dir = $FindBin::Bin;
my $top = "$FindBin::Bin/../..";
our @X86_WIDE;
my $section = do "$top/isa/x86_64.pl";
die "mkwide: $@" if $@;
die "mkwide: isa/x86_64.pl: $!\n" unless defined $section;

my @q = qw(rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15);
my @l = qw(eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d);
my @w = qw(ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w);
my @b = qw(al cl dl bl spl bpl sil dil r8b r9b r10b r11b r12b r13b r14b r15b);
my %names = (q => \@q, l => \@l, w => \@w, b => \@b, x => [map { "xmm$_" } 0 .. 15],
             c => [map { "cr$_" } 0 .. 15], d => [map { "dr$_" } 0 .. 15]);

# The values of each kind, taken in turn: registers by number.
my %vals = (
    gpr   => [12, 13, 15, 8, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 14],
    x     => [15, 8, 0, 12, 13, 1, 7, 9, 2, 14, 3, 10, 4, 11, 5, 6],
    c     => [0, 2, 3, 4, 8],
    d     => [0, 1, 2, 3, 6, 7],
    base  => [12, 13, 15, 4, 5, 8, 3, 11, 7, 1],
    index => [15, 9, 12, 5, 13, 1, 6, 8, 14],
    scale => [1, 2, 4, 8],
    disp  => [-2147483648, 2147483647, 0, -1, 127, -128, 4660],
    i8    => [-128, 127, -1, 0],
    ib    => [-128, 127, 255],
    i16   => [-32768, 32767, 4660, 200],
    i32   => [-2147483648, 2147483647, 305419896, 1000],
    i64   => ["9223372036854775807", "-9223372036854775808", "1311768467463790320"],
    u8    => [0, 255, 63, 7],
    u16   => [65535, 0, 4660],
    label => [qw(wide_back wide_fwd)],
);
my %next;
sub take {
    my ($k) = @_;
    my $list = $vals{$k} or die "mkwide: no values for $k\n";
    $list->[$next{$k}++ % @$list];
}

# A node holds at most 255 children: the program page is a few labels and
# blocks, placed labels whose children are the forms (at most 200 each, a
# near label in the block of its jump). wide_back and wide_fwd are on the
# page itself, so that every block sees them.
my (@ff, @s, @page);
sub label { my ($l) = @_; push @ff, node("$l:"); push @s, "$l:" }
sub insn  { my ($n, $args, $gnu) = @_; push @ff, node($n, map { node($_) } @$args); push @s, "    $gnu" }
sub block {
    my ($name) = @_;
    push @page, node("$name:", @ff);
    @ff = ();
}

push @s, "_start:";
insn("movl.i", [0, "edi"], "{rex} movl \$0, %edi");
insn("movl.i", ["SYS_exit", "eax"], "{rex} movl \$60, %eax");
insn("syscall", [], "syscall");
block("_start");
push @page, node("wide_back:");
push @s, "wide_back:";

my $local = 0;
my $blk = 0;
for my $f (@X86_WIDE) {
    my ($name, $params, $gnu) = @$f;
    if (@ff >= 200) { block("w$blk"); $blk++ }
    push @s, "w$blk:" unless @ff;
    my (@args, $after);
    for (@$params) {
        my ($p, $k) = split /:/;
        my ($ff, $as);
        if ($names{$k}) {
            my $n = take($k =~ /^[qlwb]$/ ? "gpr" : $k);
            $ff = $as = $names{$k}[$n];
            $as = "%$as";
        } elsif ($k =~ /^(base|index)$/) {
            $ff = $q[take($k)];
            $as = "%$ff";
        } elsif ($k eq "label8") {
            $ff = $as = "near" . $local++;
            if ($local % 2) { label($ff) } else { $after = $ff }
        } else {
            $ff = $as = take($k);
        }
        push @args, $ff;
        $gnu =~ s/<\Q$p\E>/$as/g;
    }
    die "mkwide: $name: $gnu\n" if $gnu =~ /<\w+>/;
    insn($name, \@args, $gnu);
    label($after) if $after;
}
block("w$blk");

# rel8 at the ends of its range.
push @s, "edge:";
label("edge_back");
push @ff, node("reserve", node(126)); push @s, "    .skip 126";
insn("jmp.8", ["edge_back"], "{disp8} jmp edge_back");
insn("jmp.8", ["edge_fwd"], "{disp8} jmp edge_fwd");
push @ff, node("reserve", node(127)); push @s, "    .skip 127";
label("edge_fwd");
block("edge");
push @page, node("wide_fwd:");
push @s, "wide_fwd:";

my $tree = node("", ttp_license(),
    node("comment", node("wide.ff: every form of the x86_64 section once, made by mkwide.pl with its GNU twin wide.s. Run, it exits at once.")),
    node("origin", node("elf_base")),
    node("elf_header", map { node($_) } qw(_start file_end mem_end)),
    @page,
    node("file_end:"), node("bss"), node("mem_end:"));
open my $out, ">:raw", "$dir/wide.ff" or die "mkwide: wide.ff: $!\n";
print $out write_ff($tree);
close $out;

open $out, ">", "$dir/wide.s" or die "mkwide: wide.s: $!\n";
print $out <<'END';
# wide.s — progs/x86_64/wide.ff for GNU as (x86_64-elf-as -mindex-reg),
# linked with ff64.ld: the bytes must be the same. Made by mkwide.pl with
# wide.ff, every form of the x86_64 section once. {rex}, {disp32} and
# %riz (no index) make GNU as pick the one form ff has.
    .code64
    .globl _start
END
print $out "$_\n" for @s;
close $out;
printf "mkwide: %d forms in %d blocks\n", scalar @X86_WIDE, $blk + 1;
