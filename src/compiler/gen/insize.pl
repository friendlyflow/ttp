#!/usr/bin/env perl
# insize.pl — stops a link of the chain that reads at most 4 MiB of input
# (ttpc1, ttpc2: their BUF_SIZE) before its input gets there: past 3.5
# MiB it fails, with the size of each file, so that a growing shared page
# or tree is seen while there is room, not as a truncated tree.
#
#   perl insize.pl <link> file ...     (in the Makefile, before the link runs)
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;

die "usage: insize.pl <link> file ...\n" unless @ARGV >= 2;
my ($link, @files) = @ARGV;
my $max = 3.5 * 1024 * 1024;
my $n = 0;
$n += -s $_ // die "insize: $_: $!\n" for @files;
exit 0 if $n <= $max;
die sprintf "insize: %s's input is %d bytes, past 3.5 MiB (%d) of its 4 MiB: %s\n", $link, $n, $max,
    join(', ', map { sprintf '%s %d', $_, -s $_ } @files);
