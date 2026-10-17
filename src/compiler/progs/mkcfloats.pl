#!/usr/bin/env perl
# mkcfloats.pl — writes progs/cfloats.ff: C's floating point checked value
# by value against what Perl computes (IEEE double; a float is a double
# rounded to float, exact for + - * / of floats). Each check is a number;
# the program exits with the first that fails, 0 when none does.
#
#   perl progs/mkcfloats.pl | perl gen/fftext.pl ff /dev/stdin > progs/cfloats.ff
#   perl progs/mkcfloats.pl --word 4 | perl gen/fftext.pl ff /dev/stdin > progs/cfloats32.ff
#
# What it checks: + - * / on float and double, the six comparisons (with
# a NaN too), negation (of 0 as well: -0), infinities and NaN as results,
# and cast: between float, double, long and u64, at the edges of rounding
# (2^63 and up for u64, the sticky bit). A NaN's bits and a conversion out
# of range differ between targets (C leaves them open), so they are not
# compared.
#
# A host tool (core Perl only).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../gen";
use FF qw(node write_txt);

sub leaf { map { node($_) } @_ }
sub f32 { unpack 'f', pack 'f', $_[0] }
sub inf { 9**9**9 }
my $nan = inf() - inf();
my $w4 = @ARGV && $ARGV[0] eq '--word' && $ARGV[1] == 4;
sub isnan { $_[0] != $_[0] }
# the sign of a value, -0 too (Perl dies dividing by 0)
sub neg { sprintf('%g', $_[0]) =~ /^-/ }

# a literal of type t (double or float), or a node list giving its value
sub lit {
    my ($v, $t) = @_;
    my $s = sprintf '%a', abs $v;
    $s .= 'f' if $t eq 'float';
    return neg($v) ? (leaf('-'), leaf($s)) : leaf($s);
}

my @checks;    # [number, nodes of the test (true when it fails)]
my $n = 0;
sub check { my @cond = @_; push @checks, [++$n, @cond] }

# r: a node list giving a value of type t; want: the value it should be
sub want_value {
    my ($t, $want, @r) = @_;
    my $e = node(':', @r);
    if (isnan($want)) { check($e, leaf('==', ), $e) }
    elsif ($want == inf()) { check($e, leaf('!=', 'inf' . ($t eq 'float' ? 'f' : ''))) }
    elsif ($want == -inf()) { check($e, leaf('!=', 'ninf' . ($t eq 'float' ? 'f' : ''))) }
    elsif ($want == 0) {
        # 0 or -0: equal to 0, and 1 / it the infinity of its sign
        check($e, leaf('!=', '0'));
        my $one = $t eq 'float' ? '0x1p+0f' : '0x1p+0';
        my $i = neg($want) ? 'ninf' : 'inf';
        check(leaf($one, '/'), $e, leaf('!=', $i . ($t eq 'float' ? 'f' : '')));
    }
    else { check($e, leaf('!='), node(':', lit($want, $t))) }
}

my @vars;      # [name, type, value nodes]
my %var;
sub var {
    my ($t, $v) = @_;
    my $key = "$t " . ($t =~ /^(long|u64|u32)$/ ? $v : isnan($v) ? 'nan' : sprintf '%a', $v);
    return $var{$key} if $var{$key};
    my $name = ($t eq 'float' ? 'fv' : $t eq 'double' ? 'dv' : $t eq 'long' ? 'lv' : 'uv') . scalar @vars;
    my @init;
    if ($t eq 'long') { my $m = abs $v; $m = sprintf '%.0f', $m if $m =~ /e/i; @init = $v < 0 ? leaf('-', $m) : leaf($m) }
    elsif ($t eq 'u64' || $t eq 'u32') { @init = node($t, leaf($v)) }
    elsif (isnan($v)) { @init = leaf('inf' . ($t eq 'float' ? 'f' : ''), '-', 'inf' . ($t eq 'float' ? 'f' : '')) }
    elsif ($v == inf()) { @init = leaf('inf' . ($t eq 'float' ? 'f' : '')) }
    elsif ($v == -inf()) { @init = leaf('ninf' . ($t eq 'float' ? 'f' : '')) }
    else { @init = lit($v, $t) }
    push @vars, [$name, $t, @init];
    $var{$key} = $name;
}

my @dv = (1.5, -2.25, 3, 0.1, 1e300, 1e-300, 2**-1074, 0x1.fffffffffffffp+1023, 7, -0.0);
my @fv = map { f32($_) } (1.5, -2.25, 3, 0.1, 1e30, 1e-30, 0x1.fffffep+127, 7, -0.0);

# Perl computes a whole number with integers, which have no -0: a zero
# result gets its sign from IEEE's rules
my $NZ = -0.0;
sub zs { my ($r, $neg) = @_; $r != 0 ? $r : $neg ? $NZ : 0.0 }
my %op = ('+' => sub { zs($_[0] + $_[1], neg($_[0]) && neg($_[1])) },
          '-' => sub { zs($_[0] - $_[1], neg($_[0]) && !neg($_[1])) },
          '*' => sub { zs($_[0] * $_[1], (neg($_[0]) xor neg($_[1]))) },
          '/' => sub { $_[1] == 0 ? ($_[0] == 0 || isnan($_[0]) ? $nan : ((neg($_[0]) xor neg($_[1])) ? -inf() : inf())) : zs($_[0] / $_[1], (neg($_[0]) xor neg($_[1]))) });
my @pairs = ([0, 1], [1, 2], [3, 0], [4, 4], [5, 5], [6, 0], [7, 7], [8, 9], [1, 9], [2, 3]);
for my $t (['double', \@dv, sub { $_[0] }], ['float', \@fv, \&f32]) {
    my ($ty, $vals, $round) = @$t;
    for my $p (@pairs) {
        my ($a, $b) = @{$vals}[@$p];
        next unless defined $a && defined $b;
        for my $o ('+', '-', '*', '/') {
            want_value($ty, $round->($op{$o}->($a, $b)), leaf(var($ty, $a), $o, var($ty, $b)));
        }
    }
    # the comparisons, a NaN among them
    my @cv = (@{$vals}[0 .. 3], $nan, -0.0, 0.0);
    my %cmp = ('<' => sub { $_[0] < $_[1] }, '<=' => sub { $_[0] <= $_[1] }, '>' => sub { $_[0] > $_[1] },
               '>=' => sub { $_[0] >= $_[1] }, '==' => sub { $_[0] == $_[1] }, '!=' => sub { $_[0] != $_[1] });
    for my $p ([0, 1], [1, 0], [2, 2], [4, 0], [0, 4], [4, 4], [5, 6]) {
        my ($a, $b) = @cv[@$p];
        for my $o ('<', '<=', '>', '>=', '==', '!=') {
            my $w = $cmp{$o}->($a, $b) ? 1 : 0;
            check(leaf(var($ty, $a), $o, var($ty, $b), '!=', $w));
        }
    }
    # negation
    for my $v (@{$vals}[0, 1], 0.0, $NZ) { want_value($ty, zs(-$v, !neg($v)), leaf('-', var($ty, $v))) }
}

# conversions between the floating types and the integers: long and u64, or
# with --word 4 (a target of 4-byte words, where long is 4 bytes and u64 is
# not) long and u32
if ($w4) {
    for my $v (1.5, -2.75, 2e9, -2e9, 0x1.fffffcp+30) {
        check(node('cast:', leaf('long', var('double', $v))), leaf('!=', var('long', int $v)));
    }
    for my $v (1.5, 3e9, 0x1p+31, 0x1.fffffffcp+31) {
        check(node('cast:', leaf('u32', var('double', $v))), leaf('!='), node('u32', leaf(sprintf '%.0f', int $v)));
    }
    for my $v (f32(1.5), f32(-2.75), f32(3e9), f32(0x1p+31), f32(0x1.fffffep+31)) {
        my ($t, $w) = $v < 0 ? ('long', int $v) : ('u32', sprintf '%.0f', int $v);
        check(node('cast:', leaf($t, var('float', $v))), leaf('!='), $t eq 'u32' ? node('u32', leaf($w)) : leaf(var('long', $w)));
    }
    for my $v (3, -7, 16777217, -16777219, 33554435, 2147483647, -2147483647) {
        my $s = $v < 0 ? -1 : 1;
        want_value('double', $s * u64_to(abs($v), 53), node('cast:', leaf('double', var('long', $v))));
        want_value('float', $s * u64_to(abs($v), 24), node('cast:', leaf('float', var('long', $v))));
    }
    for my $u ('4294967295', '2147483648', '2147483649', '4294967168', '3000000001', '16777217') {
        want_value('double', u64_to($u, 53), node('cast:', leaf('double', var('u32', $u))));
        want_value('float', u64_to($u, 24), node('cast:', leaf('float', var('u32', $u))));
    }
} else {
for my $v (1.5, -2.75, 1e18, -1e18, 0x1.fffffffffffffp+62) {
    my $w = int $v;
    check(node('cast:', leaf('long', var('double', $v))), leaf('!=', var('long', $w)));
}
for my $v (1.5, 1e18, 0x1p+63, 0x1.8p+63, 0x1.fffffffffffffp+63) {
    my $w = sprintf '%.0f', int $v;
    check(node('cast:', leaf('u64', var('double', $v))), leaf('!='), node('u64', leaf($w)));
}
for my $v (f32(1.5), f32(-2.75), f32(1e18), f32(0x1p+63), f32(0x1.fffffep+63)) {
    my ($t, $w) = $v < 0 ? ('long', int $v) : ('u64', sprintf '%.0f', int $v);
    check(node('cast:', leaf($t, var('float', $v))), leaf('!='), $t eq 'u64' ? node('u64', leaf($w)) : leaf(var('long', $w)));
}
# long and u64 to double and float: rounding to nearest, ties to even
my @lv = (3, -7, 9007199254740993, 9007199254740995, -4611686018427388929, 4611686018427388416, 16777217, -16777219);
for my $v (@lv) {
    my $s = $v < 0 ? -1 : 1;
    want_value('double', $s * u64_to(abs($v), 53), node('cast:', leaf('double', var('long', $v))));
    want_value('float', $s * u64_to(abs($v), 24), node('cast:', leaf('float', var('long', $v))));
}
# u64 at 2^63 and up, where the top bit is set: the sticky bit decides
for my $u ('9223372036854775808', '9223372586610589697', '9223372586610589696', '18446744073709551615',
           '9223372036854777857', '9223372036854777856', '12345678901234567891') {
    my ($d, $f) = (u64_to($u, 53), u64_to($u, 24));
    want_value('double', $d, node('cast:', leaf('double', var('u64', $u))));
    want_value('float', $f, node('cast:', leaf('float', var('u64', $u))));
}
}
# float and double between them
for my $v (1.5, 0.1, 1e300, -1e-300, 0x1.fffffefffffffp+0, 0x1.ffffff0000001p+0) {
    want_value('float', f32($v), node('cast:', leaf('float', var('double', $v))));
}
for my $v (map { f32($_) } 0.1, -2.25, 3e38) { want_value('double', $v, node('cast:', leaf('double', var('float', $v)))) }

# u64_to(decimal, bits): the value rounded to a binary of that many bits,
# to nearest, ties to even, as a Perl number (exact: it fits a double)
sub u64_to {
    my ($dec, $bits) = @_;
    # the value in 32-bit halves
    my ($hi, $lo) = (0, 0);
    for my $c (split //, $dec) {
        my $l = $lo * 10 + $c;
        $lo = $l % 2**32;
        $hi = $hi * 10 + int($l / 2**32);
    }
    my $top = 63;
    $top-- while $top >= 0 && !(($top >= 32 ? $hi >> ($top - 32) : $lo >> $top) & 1);
    my $drop = $top + 1 - $bits;
    return $hi * 2**32 + $lo if $drop <= 0;
    my $bit = sub { my $i = shift; ($i >= 32 ? $hi >> ($i - 32) : $lo >> $i) & 1 };
    my $kept = 0;
    $kept = $kept * 2 + $bit->($_) for reverse $drop .. $top;
    my $half = $bit->($drop - 1);
    my $sticky = 0;
    $sticky ||= $bit->($_) for 0 .. $drop - 2;
    $kept++ if $half && ($sticky || ($kept & 1));
    return $kept * 2**$drop;
}

die "too many checks for an exit status: $n\n" if $n > 255;

# the program: the variables, then the checks in functions of 60
my @fns;
my @body;
for my $c (@checks) {
    my ($k, @cond) = @$c;
    push @body, node('if', node(':', @cond), node('bad', leaf($k)));
    if (@body == 60) { push @fns, [@body]; @body = () }
}
push @fns, [@body] if @body;
my @out = (
    node('comment', leaf("C's floating point checked against Perl's IEEE double, written by mkcfloats.pl: arithmetic, comparisons (a NaN too), negation, infinities, cast: between float, double, long and " . ($w4 ? "u32 (for a target of 4-byte words)" : "u64") . " at the edges of rounding.")),
    node('first:', leaf('long', '0')),
    node('bad:', leaf('void'), node('n:', leaf('long')),
        node('if', node(':', leaf('first', '==', '0')), leaf('first', '=', 'n'))),
    node('inf:', leaf('double')), node('ninf:', leaf('double')),
    node('inff:', leaf('float')), node('ninff:', leaf('float')),
    (map { node("$_->[0]:", leaf($_->[1])) } @vars),
);
# the statements that give the variables their values, in functions of up
# to 240 nodes
my @init = ([leaf('inf', '=', '0x1p+1023', '*', '0x1p+1')], [leaf('ninf', '=', '-', 'inf')],
    [leaf('inff', '=', '0x1p+127f', '*', '0x1p+1f')], [leaf('ninff', '=', '-', 'inff')]);
push @init, [leaf($_->[0], '='), @{$_}[2 .. $#$_]] for @vars;
my @inits = ([]);
for my $s (@init) {
    push @inits, [] if @{ $inits[-1] } + @$s > 240;
    push @{ $inits[-1] }, @$s;
}
my $i = 0;
push @out, node('init' . $i++ . ':', leaf('void'), @$_) for @inits;
$i = 0;
push @out, node('checks' . $i++ . ':', leaf('void'), @$_) for @fns;
push @out, node('_start:', leaf('void'), leaf(map({ "init$_" } 0 .. $#inits), map({ "checks$_" } 0 .. $#fns)),
    node('syscall', leaf('SYS_exit', 'first')));
print write_txt(@out);
