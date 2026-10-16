#!/usr/bin/env perl
# mkrvv.pl — makes progs/riscv64/rvv.ff and its GNU twin rvv.s from one
# table: every vector instruction of the riscv64 section (isa/riscv64.pl,
# group vector), unmasked and, where it has a mask, under v0.t, and csrr
# of vl. ff takes the operands in field order, the destination last; vm is
# 1 unmasked, 0 under v0.t; a vtype is a number (e8, m2, ta, ma is 193).
#
#   perl progs/riscv64/mkrvv.pl          writes rvv.ff and rvv.s here
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../gen";
use FF qw(node write_ff);

my $dir = $FindBin::Bin;
my @rows;       # [ff name, [ff operands], gnu line]
sub row { push @rows, [@_] }

# vtype: vma<<7 | vta<<6 | sew<<3 | lmul
my %sew = (e8 => 0, e16 => 1, e32 => 2, e64 => 3);
my %lmul = (m1 => 0, m2 => 1, m4 => 2, m8 => 3, mf8 => 5, mf4 => 6, mf2 => 7);
sub vtype { my ($s, $l, $ta, $ma) = @_; ($ma eq 'ma') << 7 | ($ta eq 'ta') << 6 | $sew{$s} << 3 | $lmul{$l} }

for my $t (['e8', 'm2', 'ta', 'ma'], ['e64', 'm1', 'tu', 'mu'], ['e16', 'mf2', 'ta', 'mu'], ['e32', 'm8', 'tu', 'ma']) {
    my $z = vtype(@$t);
    row('vsetvli', [$z, 'a0', 'a2'], "vsetvli a2, a0, " . join(', ', @$t));
    row('vsetivli', [$z, 31, 'a5'], "vsetivli a5, 31, " . join(', ', @$t));
}
row('vsetvl', ['a1', 'a0', 'a2'], 'vsetvl a2, a0, a1');

for my $n (8, 16, 32, 64) {
    for my $m (1, 0) {
        my $t = $m ? '' : ', v0.t';
        row("vle$n.v", [$m, 'a1', 'v8'], "vle$n.v v8, (a1)$t");
        row("vle${n}ff.v", [$m, 'a3', 'v30'], "vle${n}ff.v v30, (a3)$t");
        row("vse$n.v", [$m, 's1', 'v16'], "vse$n.v v16, (s1)$t");
    }
}

my @vv = qw(vmseq vmsne vmsltu vmsleu vadd vsub vand vor vxor vrgather);
my @vx = qw(vmseq vmsne vmsltu vmsleu vmsgtu vadd vsub vand vor vxor vrgather);
my @vi = qw(vmseq vmsne vmsleu vmsgtu vadd vand vor vxor);
for my $m (1, 0) {
    my $t = $m ? '' : ', v0.t';
    row("$_.vv", [$m, 'v4', 'v6', 'v2'], "$_.vv v2, v4, v6$t") for @vv;
    row("$_.vx", [$m, 'v10', 't6', 'v12'], "$_.vx v12, v10, t6$t") for @vx;
    row("$_.vi", [$m, 'v14', -16, 'v20'], "$_.vi v20, v14, -16$t") for @vi;
    row("$_.vi", [$m, 'v14', 15, 'v20'], "$_.vi v20, v14, 15$t") for @vi;
    row('vrgather.vi', [$m, 'v14', $_, 'v20'], "vrgather.vi v20, v14, $_$t") for 0, 31;
    row("$_.vs", [$m, 'v24', 'v26', 'v28'], "$_.vs v28, v24, v26$t") for qw(vredmaxu vredminu vredsum vredor);
    row('vcpop.m', [$m, 'v2', 'a4'], "vcpop.m a4, v2$t");
    row('vfirst.m', [$m, 'v2', 'a4'], "vfirst.m a4, v2$t");
    row("$_.m", [$m, 'v6', 'v8'], "$_.m v8, v6$t") for qw(vmsbf vmsof vmsif);
    row('vid.v', [$m, 'v31'], "vid.v v31$t");
}
row('vmv.v.v', ['v3', 'v1'], 'vmv.v.v v1, v3');
row('vmv.v.x', ['a7', 'v1'], 'vmv.v.x v1, a7');
row('vmv.v.i', [-7, 'v1'], 'vmv.v.i v1, -7');
row('vmv.x.s', ['v9', 'a0'], 'vmv.x.s a0, v9');
row('vmv.s.x', ['t3', 'v9'], 'vmv.s.x v9, t3');
row("$_.mm", ['v5', 'v7', 'v1'], "$_.mm v1, v5, v7") for qw(vmandn vmand vmor vmxor vmorn vmnand vmnor vmxnor);
row('csrr', [0xc20, 'a2'], 'csrr a2, vl');
row('csrr', [0xc22, 't0'], 'csrr t0, vlenb');

my $ff = node('_start:', node('comment', node('Every vector instruction of the riscv64 section, unmasked and under v0.t, with its GNU twin rvv.s (written by mkrvv.pl).')),
    map { my ($n, $ops) = @$_; node($n, map { node($_) } @$ops) } @rows);
open my $h, '>:raw', "$dir/rvv.ff" or die "mkrvv: rvv.ff: $!\n";
print $h write_ff(node('', $ff));
close $h;
open $h, '>', "$dir/rvv.s" or die "mkrvv: rvv.s: $!\n";
print $h "# The GNU twin of rvv.ff (written by mkrvv.pl).\n\t.option norvc\n\t.text\n\t.globl _start\n_start:\n";
print $h "\t$_->[2]\n" for @rows;
close $h;
printf "mkrvv: %d instructions\n", scalar @rows;
