#!/usr/bin/env perl
# frozen.pl — an ff tree in the language of the frozen ttpc1 (and stage0).
#
#   perl frozen.pl shared.ff > boot/shared.ff
#
# ttpc1 knows comment only in code: it takes no comment beside the groups
# of a section or the definitions of a group. And it takes any definition
# whose name has a space and which has children for a register, so the
# declaration else if: / condition would name registers else and if. The
# bootstrap hands it shared.ff without either (see FF.pm frozen, the
# Makefile); neither emits anything.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(frozen read_ff write_ff);

die "usage: frozen.pl <file.ff>\n" unless @ARGV == 1;
open my $in, "<:raw", $ARGV[0] or die "frozen: cannot open $ARGV[0]: $!\n";
my $bytes = do { local $/; <$in> };
binmode STDOUT;
print write_ff(frozen(read_ff($bytes)));
