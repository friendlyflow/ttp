#!/usr/bin/env perl
# x87builtins.pl — builtins.ff.txt as x86_64 has it (perl x87builtins.pl
# builtins.ff.txt): there long double is the x87's (gen/patches/x87.pl) and
# _Float128 ttpc's float128, binary128. builtins.ff.txt's long double
# builtins are binary128's: each also becomes float128's, its words and its
# name made so (__builtin_isnan long double -> __builtin_isnan float128,
# __builtin_fabsl -> __builtin_fabsf128: c2ff names a call so), and those
# that read the format's bits are left out as long double's, which
# builtins-x86_64.ff.txt has for the x87 (the rest work on the values, so
# they stay as they are for long double too).
#
# A host tool (core Perl only).
use strict;
use warnings;

my @bits = ('__builtin_isnan long double', '__builtin_isinf_sign long double', '__builtin_signbit long double',
    '__builtin_fpclassify long double', '__builtin_fabsl', '__builtin_copysignl', '__builtin_huge_vall', '__builtin_nanl');
my %bits = map { $_ => 1 } @bits;
# a definition's float128 name
sub f128 { my ($s) = @_; $s =~ s/ long double\b/ float128/g; $s =~ s/\b(__builtin_(?:fabs|copysign|signbit|huge_val|nan))l\b/$1f128/g; $s =~ s/\blong double\b/float128/g; $s }

die "usage: x87builtins.pl builtins.ff.txt\n" unless @ARGV == 1;
open my $in, '<', $ARGV[0] or die "x87builtins: $ARGV[0]: $!\n";
my @lines = <$in>;
close $in;
# the page's children at indent 2: each a run of lines (a comment and the
# definition after it go together)
my ($head, @parts) = ('');
my $i = 0;
$head .= $lines[$i++] while $i < @lines && $lines[$i] !~ /^  \S/;
while ($i < @lines) {
    my $p = $lines[$i++];
    $p .= $lines[$i++] while $i < @lines && $lines[$i] !~ /^  \S/;
    push @parts, $p;
}
my %found;
print $head;
for (my $k = 0; $k < @parts; $k++) {
    my $p = $parts[$k];
    my ($name) = $p =~ /^  (.+):\n/;
    if (defined $name && $p =~ /long double/) {
        $found{$name} = 1;
        print $p unless $bits{$name};
        print f128($p);
        next;
    }
    # (the comment of a definition left out: its float128 one's)
    my ($next) = $k + 1 < @parts ? $parts[$k + 1] =~ /^  (.+):\n/ : ();
    print $p =~ /^  comment\n/ && defined $next && $bits{$next} ? f128($p) : $p;
}
$found{$_} or die "x87builtins: no $_ in $ARGV[0]\n" for @bits;
