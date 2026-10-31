#!/usr/bin/env perl
# csemacmp.pl — the comparison of csema -d's lines (MINE) with clang's
# (CLANG, from clangsema.pl): the declarations and expressions line for
# line, then the record layouts, every one clang laid out (the records the
# unit needed the layout of) as csema lays it out. Each mismatch is reported
# with its kind (the line's first word) and both lines; exit 1 if any.
#
#   perl csemacmp.pl [-n MAX] MINE CLANG
#
# A host tool of the checks (Perl): not in the build.
use strict;
use warnings;
my $max = 20;
if (@ARGV && $ARGV[0] eq '-n') { shift; $max = shift }
@ARGV == 2 or die "usage: csemacmp.pl [-n MAX] MINE CLANG\n";
my ($mf, $cf) = @ARGV;
sub parts {
    my ($f) = @_;
    open my $h, '<', $f or die "csemacmp: $f: $!\n";
    my (@body, %lay, @order, $cur);
    while (my $l = <$h>) {
        chomp $l;
        if ($l =~ /^layout /) { $cur = $l; push @order, $l unless exists $lay{$l}; $lay{$l} = [] ; next }
        if (defined $cur) { push @{ $lay{$cur} }, $l; $cur = undef if $l =~ /^size /; next }
        push @body, $l;
    }
    (\@body, \%lay, \@order);
}
my ($mb, $ml) = parts($mf);
my ($cb, $cl, $co) = parts($cf);
my $bad = 0;
my %kinds;
# the lines: an LCS-free walk, resynchronised at the next equal line within a window
my ($i, $j) = (0, 0);
my @shown;
while ($i < @$mb || $j < @$cb) {
    if ($i < @$mb && $j < @$cb && $mb->[$i] eq $cb->[$j]) { $i++; $j++; next }
    # find the nearest resynchronisation
    my ($bi, $bj, $best) = (scalar @$mb, scalar @$cb, 1e9);
    for my $d (1 .. 400) {
        for my $a (0 .. $d) {
            my ($x, $y) = ($i + $a, $j + $d - $a);
            next if $x > @$mb || $y > @$cb;
            if ($x < @$mb && $y < @$cb && $mb->[$x] eq $cb->[$y] && ($x + 1 >= @$mb || $y + 1 >= @$cb || $mb->[$x + 1] eq $cb->[$y + 1])) { ($bi, $bj, $best) = ($x, $y, $d); last }
        }
        last if $best < 1e9;
    }
    my @m = @$mb[$i .. $bi - 1];
    my @c = @$cb[$j .. $bj - 1];
    my $k = ($c[0] // $m[0] // '?') =~ /^(\S+)/ ? $1 : '?';
    $kinds{$k}++;
    $bad++;
    push @shown, "lines " . ($i + 1) . "/" . ($j + 1) . " ($k):\n" . join('', map { "  csema: $_\n" } @m[0 .. ($#m > 5 ? 5 : $#m)]) . join('', map { "  clang: $_\n" } @c[0 .. ($#c > 5 ? 5 : $#c)]) if @shown < $max;
    ($i, $j) = ($bi, $bj);
}
for my $h (@$co) {
    my $c = join("\n", @{ $cl->{$h} });
    my $m = exists $ml->{$h} ? join("\n", @{ $ml->{$h} }) : undef;
    next if defined $m && $m eq $c;
    $bad++;
    $kinds{layout}++;
    push @shown, "$h:\n  csema: " . (defined $m ? join("\n  csema: ", @{ $ml->{$h} }) : '(none)') . "\n  clang: " . join("\n  clang: ", @{ $cl->{$h} }) . "\n" if @shown < $max;
}
if ($bad) {
    print "MISMATCH $bad: ", join(', ', map { "$_ $kinds{$_}" } sort { $kinds{$b} <=> $kinds{$a} } keys %kinds), "\n";
    print @shown;
    exit 1;
}
print "AGREE ", scalar(@$cb), " lines, ", scalar(@$co), " layouts\n";
