#!/usr/bin/env perl
# csview.pl — what csema -l -S reads of the shared page, as text:
#
#   perl csview.pl shared.ff [x86_64gnu.ff] > view
#
# the Makefile's stamp of csema's outputs (CSVIEW), written only when it
# changes, so that a change of the macros' bodies alone (macros/<target>.ff.txt,
# make refresh) does not make csema translate everything again (ttpc's
# outputs depend on all of shared.ff instead).
# What csema reads (src/compiler/tools/dev/cs: cl_m.c's cl_read_shared and
# cl_reserve_target, cl_w.c's cl_typenames; keep this in step with them):
#   - a name: whose first child is struct, union, enum or function, or
#     base pcs then function (C's type words), with all under it;
#   - each registers: group (a target's registers, reserved names);
#   - the names of the instruction forms of arm's and x86_64's sections'
#     groups (data:, alu1: ...);
#   - on x86_64 all of x86_64gnu.ff (its forms, reserved names): its sha256.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";
use FF qw(read_ff write_txt is_layer);
use Digest::SHA qw(sha256_hex);

die "usage: csview.pl shared.ff [x86_64gnu.ff]\n" unless @ARGV == 1 || @ARGV == 2;
my %record = map { $_ => 1 } qw(struct union enum function);
my %forms = map { $_ => 1 } qw(data: data2: shifts: multiply: bits: memory: atomic: branch: system: vfp: a32x:
    alu1: alu2: move: unary: shift1: shift2: bit: set: cmov: stack: sse:);
sub leaf { !@{ $_[0]{children} } }
# (sec: the section n is a group of, arm: or x86_64:, through layers)
sub walk {
    my ($n, $sec) = @_;
    my $s = $n->{content};
    my @k = @{ $n->{children} };
    if ($s =~ /.:$/ && @k && leaf($k[0])
        && ($record{ $k[0]{content} } || (@k > 1 && $k[0]{content} eq 'base pcs' && leaf($k[1]) && $k[1]{content} eq 'function'))) {
        print write_txt($n);
        return;
    }
    if ($s eq 'registers:') { print write_txt($n); return; }
    print "forms $sec $s ", join(' ', map { $_->{content} } @k), "\n" if $sec && $forms{$s};
    my $in = is_layer($n) ? $sec : ($s eq 'arm:' || $s eq 'x86_64:') ? $s : undef;
    walk($_, $in) for @k;
}
sub slurp { my ($f) = @_; open my $in, '<:raw', $f or die "csview: cannot open $f: $!\n"; local $/; my $b = <$in>; $b }
binmode STDOUT;
walk(read_ff(slurp($ARGV[0])));
print "x86_64gnu.ff ", sha256_hex(slurp($ARGV[1])), "\n" if @ARGV == 2;
