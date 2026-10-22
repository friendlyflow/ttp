#!/usr/bin/env perl
# unlicense.pl — an ff tree without its licenses (license / SPDX / notice),
# all the way down: what the frozen ttpcs read (stage0 and the seeds of the
# hosts, ttpc1, ttpc2, ttpc3), which predate the word. A license emits
# nothing, so what they make of the tree is the same; stage1 == stage2
# checks it, stage2 reading the trees with their licenses.
#
#   perl unlicense.pl [-t types.ff]... tree.ff > tree.ff
#
# Each -t tree gives its types (structs, unions, ...) too, for a tree that
# uses them: a program the types of its library pages (tools/old/, the
# Makefile). tools/unlicense.ff is the same in ff, compiled by ttpc3;
# compiler-check runs both and compares.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(unlicense unlicense1 typenames read_ff write_ff);

sub slurp { open my $in, "<:raw", $_[0] or die "unlicense: cannot open $_[0]: $!\n"; local $/; <$in> }
my @types;
push @types, unlicense1(read_ff(slurp((splice @ARGV, 0, 2)[1]))) while @ARGV > 1 && $ARGV[0] eq '-t';
die "usage: unlicense.pl [-t types.ff]... <file.ff>\n" unless @ARGV == 1;
my $bytes = slurp($ARGV[0]);
binmode STDOUT;
print write_ff(unlicense(read_ff($bytes), @types ? typenames(@types) : undef));
