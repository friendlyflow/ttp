#!/usr/bin/env perl
# mkff.pl — the shared page of an ff tree: what every target has
# (shared.ff.txt: the data words, bits, rel, the choice of a target), and
# one section per target (isa/<target>.pl: its instructions, registers and
# macros/<target>.ff.txt). See FF.pm for both formats.
#
#   perl mkff.pl > shared.ff                   the shared page alone: what a
#                                              program of only its own is
#                                              assembled with (ttpc shared.ff
#                                              prog.ff out)
#   perl mkff.pl [page.ff.txt ...] > new.ff    a new tree: the shared page,
#                                              then one page per text file
#
# A host tool (core Perl only), not part of ttpc.
#
# Functions and calls: a node ending in ':' is a function, its leading
# children without ':' are its parameters. A node without ':' is a call, its
# children are the arguments, bound by position to the parameters of the
# function of that name. A call of an instruction assembles to its machine
# code, a call of any other function expands in place.
#
# A section is a function whose children are groups (registers:, integer:,
# float:, macros:, ...), each a function holding definitions, so that no
# node has more than 255 children. ttpc puts the definitions of the section
# that --target chooses in scope, see the end of shared.ff.txt.
#
# The trees made before the targets (ttpc.ff, progs/riscv64/exit42.ff,
# hello.ff, wide.ff) keep the shared pages of then, RV64GC alone as pages
# 0: 1: 2:.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_ff read_txt);

my @TARGETS = qw(riscv64 x86_64 aarch64 arm);

sub slurp {
    my ($file) = @_;
    open my $in, "<:raw", $file or die "mkff: cannot open $file: $!\n";
    local $/;
    <$in>;
}

sub section {
    my ($target) = @_;
    my $file = "$FindBin::Bin/isa/$target.pl";
    my $section = do $file;
    die "mkff: $file: $@" if $@;
    die "mkff: $file: $!\n" unless defined $section;
    $section;
}

my $shared = node("shared:",
    read_txt(slurp("$FindBin::Bin/shared.ff.txt"), "shared.ff.txt"),
    map { section($_) } @TARGETS);

binmode STDOUT;
print write_ff(node("", $shared, map { node("$_:", read_txt(slurp($_), $_)) } @ARGV));
