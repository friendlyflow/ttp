#!/usr/bin/env perl
# rtknown.pl — make glibc-roundtrip's verdict: what roundtrip.pl --join and the
# files of rtall.sh report, against the target's list of what is known and
# judged (src/glibc/rtknown-<target>.txt). It passes when the two are equal; it
# names each new difference and each listed one that no longer differs, so
# that the list cannot go stale.
#
#   perl rtknown.pl LIST report result
#
# A line of LIST: name, digest, kind, reason, separated by tabs; # a comment. name
# is a function's or a global's C name as the report has it, or "file x" for a
# file written back or a unit clang did not take. digest (of both normal forms
# whole, roundtrip.pl's) is - where there are none to compare: so a new
# difference in a listed function is new too. kind: false alarm, ff2c cannot
# write, clang refuses. A new one is printed with its digest, to judge.
#
# A host tool (Perl).
use strict;
use warnings;
my ($list, $report, $result) = @ARGV;
die "usage: rtknown.pl LIST report result\n" unless defined $result;
my %kinds = ('false alarm' => 1, 'ff2c cannot write' => 1, 'clang refuses' => 1);
my %known;
if (open my $h, '<', $list) {
    while (<$h>) {
        chomp;
        next if /^\s*(?:#|$)/;
        my ($n, $g, $k, $r) = split /\t/;
        die "rtknown: $list:$.: not name, digest, kind, reason\n" unless defined $r && length $r && $kinds{$k};
        die "rtknown: $list:$.: $n twice\n" if $known{$n};
        $known{$n} = [$g, $k, $r];
    }
} else { warn "rtknown: no list $list: every difference is new\n" }
my %now;   # name => [digest, what]
open my $h, '<', $report or die "rtknown: $report: $!\n";
my $cur;
while (<$h>) {
    chomp;
    next if /^roundtrip: \d+ of /;
    if (/^roundtrip: (\S+?): ?(.*)$/) { $cur = $1; $now{$cur} = ['-', $2]; next }
    if (defined $cur && /^\s+digest: (\S+)/) { $now{$cur}[0] = $1 }
    elsif (defined $cur && /^\s+glibc: (.*)/) { $now{$cur}[1] = substr($1, 0, 160) }
}
open $h, '<', $result or die "rtknown: $result: $!\n";
while (<$h>) {
    chomp;
    next if /^OK /;
    my ($w, $b, $why) = /^(\S+) (\S+?): ?(.*)$/ or next;
    $now{"file $b"} = ['-', "$w: " . substr($why, 0, 160)];
}
my ($new, $gone) = (0, 0);
my %n;
for my $x (sort keys %now) {
    my $k = $known{$x};
    if (!$k) { print "NEW $x\t$now{$x}[0]\t$now{$x}[1]\n"; $new++ }
    elsif ($k->[0] ne $now{$x}[0]) { print "NEW $x\t$now{$x}[0]\tlisted, but not this difference (listed $k->[0]): $now{$x}[1]\n"; $new++ }
    else { $n{ $k->[1] }++ }
}
for my $x (sort keys %known) { next if $now{$x}; print "GONE $x\tlisted ($known{$x}[1]: $known{$x}[2]), no longer differs: take it off the list\n"; $gone++ }
print "rtknown: ", join(', ', map { ($n{$_} // 0) . " $_" } sort keys %kinds), " as listed; $new new, $gone gone\n";
exit($new || $gone ? 1 : 0);
