#!/usr/bin/env perl
# unlicense.pl — an ff tree without its licenses (license / SPDX / notice),
# all the way down: what the frozen ttpcs read (stage0 and the seeds of the
# hosts, ttpc1, ttpc2, ttpc3), which predate the word. A license emits
# nothing, so what they make of the tree is the same; stage1 == stage2
# checks it, stage2 reading the trees with their licenses.
#
#   perl unlicense.pl tree.ff > tree.ff
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(unlicense read_ff write_ff);

die "usage: unlicense.pl <file.ff>\n" unless @ARGV == 1;
open my $in, "<:raw", $ARGV[0] or die "unlicense: cannot open $ARGV[0]: $!\n";
my $bytes = do { local $/; <$in> };
binmode STDOUT;
print write_ff(unlicense(read_ff($bytes)));
