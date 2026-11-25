#!/usr/bin/env perl
# armbuiltins.pl — builtins.ff.txt as arm has it (perl armbuiltins.pl
# builtins.ff.txt builtins-arm.ff.txt): each definition builtins-arm.ff.txt
# has too is left out of builtins.ff.txt, as arm's replaces it. builtins.ff.txt's
# ckd_ builtins of long take the exact result in an i128, a long of 8 bytes;
# arm's long is an int and arm has no i128 (ttpc: no value of them at compile
# time), so builtins-arm.ff.txt has them of an i64 (diffutils' __builtin_add_overflow
# long int int). The comments stay.
#
# A host tool (core Perl only).
use strict;
use warnings;

die "usage: armbuiltins.pl builtins.ff.txt builtins-arm.ff.txt\n" unless @ARGV == 2;
my %arm;
open my $a, '<', $ARGV[1] or die "armbuiltins: $ARGV[1]: $!\n";
while (<$a>) { $arm{$1} = 1 if /^  (\S.*):\n/ && $1 ne 'comment' }
close $a;
open my $in, '<', $ARGV[0] or die "armbuiltins: $ARGV[0]: $!\n";
my @lines = <$in>;
close $in;
# the page's children at indent 2: each a run of lines
my ($head, @parts) = ('');
my $i = 0;
$head .= $lines[$i++] while $i < @lines && $lines[$i] !~ /^  \S/;
while ($i < @lines) {
    my $p = $lines[$i++];
    $p .= $lines[$i++] while $i < @lines && $lines[$i] !~ /^  \S/;
    push @parts, $p;
}
print $head;
for my $p (@parts) {
    my ($name) = $p =~ /^  (.+):\n/;
    next if defined $name && $arm{$name};
    print $p;
}
