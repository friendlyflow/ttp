#!/usr/bin/env perl
# trim.pl — shared.ff with the sections of only some targets: what ttpc2
# reads to assemble ttpc for one of them. ttpc2 is frozen with 4 MiB of
# input, and the sections of all four targets with ttpc.ff came to more.
# The other sections are kept empty, their names in place. A section emits
# nothing unless it is the target's (or assemble time's, riscv64's), so what
# ttpc2 makes is the same: stage1 == stage2 checks it.
#
#   perl trim.pl shared.ff riscv64 [host] > shared.ff
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(read_ff write_ff);

die "usage: trim.pl shared.ff target ...\n" unless @ARGV >= 2;
my ($file, @keep) = @ARGV;
my %keep = map { ("$_:" => 1) } @keep;
my %section = map { ("$_:" => 1) } qw(riscv64 x86_64 aarch64 arm);
open my $h, '<:raw', $file or die "trim: $file: $!\n";
my $root = read_ff(do { local $/; <$h> });
close $h;
my ($page) = grep { $_->{content} eq 'shared:' } @{ $root->{children} } or die "trim: no shared: page\n";
# the others stay, empty: their names are values (target == x86_64)
$_->{children} = [] for grep { $section{ $_->{content} } && !$keep{ $_->{content} } } @{ $page->{children} };
binmode STDOUT;
print write_ff($root);
