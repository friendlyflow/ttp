#!/usr/bin/env perl
# mkhost.pl — ttpc for a host that is not riscv64. ttpc is written in RV64;
# the host's section has a group rv64: with an instruction rv.op for each
# op of RV64 that ttpc uses, written in the host's instructions. This makes
# a copy of ttpc's trees in which every op at the level of code is rv.op,
# so that the same program assembles for the host. See FF.pm for the
# format, macros/<host>.ff.txt for rv64:.
#
#   perl mkhost.pl <host> <outdir> <tree.ff> ...
#
# The last tree is the program: a program of only its own (ttpc.ff) or a
# whole tree, whose last page is (ttpc1.ff). The others, and the other
# pages of a whole tree, are definitions (ttpc.defs.ff): a definition that
# the program calls at the level of code (enter1, leave1, ...) is renamed
# inside too; the constants (SYS_openat, ...) run at assemble time, on the
# host's exec ops, and stay as they are. Each tree is written to
# <outdir>/<its name>.
#
# Its register operands are renamed too, a0 to rv.a0: a host names its own
# registers (aarch64 s0, arm a1, x86_64 sp), rv64: says where RV64's are.
#
# Besides: _start begins with rv.start rvregs rvstack_end, and before
# mem_end the program gets rvregs (the slots of the registers) and rvstack
# (the call stack). An op of riscv64's section that rv64: does not have is
# an error: rv64: must have every op ttpc uses.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use File::Basename qw(basename);
use FF qw(node read_ff write_ff);

die "usage: mkhost.pl <host> <outdir> <tree.ff> ...\n" unless @ARGV >= 3;
my ($host, $outdir, @files) = @ARGV;

sub slurp {
    my ($file) = @_;
    open my $in, "<:raw", $file or die "mkhost: cannot open $file: $!\n";
    local $/;
    <$in>;
}

my ($shared) = @{ read_ff(slurp("$FindBin::Bin/shared.ff"))->{children} };
my %section = map { ($_->{content}, $_) } @{ $shared->{children} };
die "mkhost: $host is not a target\n" unless $section{"$host:"};

# The names a section defines, by group.
sub defined_in {
    my ($name, @groups) = @_;
    my %want = map { ("$_:" => 1) } @groups;
    my %names;
    for my $g (@{ $section{"$name:"}{children} }) {
        next if @groups && !$want{ $g->{content} };
        for (@{ $g->{children} }) { (my $n = $_->{content}) =~ s/:$// or next; $names{$n} = 1 }
    }
    %names;
}
my %rv = map { s/^rv\.// ? ($_ => 1) : () } keys %{ { defined_in($host, "rv64") } };
die "mkhost: $host has no rv64: group\n" unless %rv;
my %riscv = defined_in("riscv64", qw(integer system atomic float compressed macros));
my %reg = defined_in("riscv64", "registers");
my %names = map { ($_ => 1) } map { split / / } keys %reg;

my @trees = map { read_ff(slurp($_)) } @files;
my $root = $trees[-1];
my $whole = @{ $root->{children} } > 1 && !grep { $_->{content} !~ /:$/ } @{ $root->{children} };
my $page = $whole ? $root->{children}[-1] : $root;
my @defpages = ((map { @{ $_->{children} } } @trees[0 .. $#trees - 1]),
    $whole ? @{ $root->{children} }[0 .. $#{ $root->{children} } - 1] : ());

my %macro;                              # name -> the definition
for my $p (@defpages) {
    for (@{ $p->{children} }) { (my $n = $_->{content}) =~ s/:$// or next; $macro{$n} //= $_ }
}

# The calls at the level of code under a node: the children of a placed
# function that are not functions (those are labels), and in a definition,
# its body after the parameters.
my %done;
sub code {
    my ($n, $skip) = @_;
    my $i = 0;
    for my $c (@{ $n->{children} }) {
        next if $i++ < $skip;
        if ($c->{content} =~ /:$/) { code($c, 0); next }
        my $name = $c->{content};
        if ($rv{$name}) {
            $c->{content} = "rv.$name";
            $names{ $_->{content} } && !@{ $_->{children} } and $_->{content} = "rv.$_->{content}"
                for @{ $c->{children} };
        }
        elsif (my $d = $macro{$name}) {
            next if $done{$d}++;
            my $params = 0;
            for (@{ $d->{children} }) { last if @{ $_->{children} } || $_->{content} =~ /:$/; $params++ }
            code($d, $params);
        }
        elsif ($riscv{$name}) { die "mkhost: $host rv64: has no rv.$name\n" }
    }
}
code($page, 0);

my ($start) = grep { $_->{content} eq "_start:" } @{ $page->{children} };
die "mkhost: no _start\n" unless $start;
unshift @{ $start->{children} }, node("rv.start", node("rvregs"), node("rvstack_end"));
my ($end) = grep { $page->{children}[$_]{content} eq "mem_end:" } 0 .. $#{ $page->{children} };
die "mkhost: no mem_end\n" unless defined $end;
splice @{ $page->{children} }, $end, 0,
    node("align", node("16")),
    node("rvregs:", node("reserve", node("256"))),
    node("rvstack:", node("reserve", node("0x100000"))),
    node("rvstack_end:");

for my $i (0 .. $#files) {
    my $out = "$outdir/" . basename($files[$i]);
    open my $fh, ">:raw", $out or die "mkhost: cannot write $out: $!\n";
    print $fh write_ff($trees[$i]);
}
