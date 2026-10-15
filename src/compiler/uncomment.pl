#!/usr/bin/env perl
# uncomment.pl — an ff tree without its comments (comment with its text).
#
#   perl uncomment.pl shared.ff > boot/shared.ff
#
# ttpc1 is frozen with comments known only in code: it takes no comment
# beside the groups of a section or the definitions of a group. The
# bootstrap hands it shared.ff without them (see the Makefile).
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(uncomment read_ff write_ff);

die "usage: uncomment.pl <file.ff>\n" unless @ARGV == 1;
open my $in, "<:raw", $ARGV[0] or die "uncomment: cannot open $ARGV[0]: $!\n";
my $bytes = do { local $/; <$in> };
binmode STDOUT;
print write_ff(uncomment(read_ff($bytes)));
