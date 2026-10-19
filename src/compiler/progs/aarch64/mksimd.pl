#!/usr/bin/env perl
# mksimd.pl — makes progs/aarch64/simd.ff and its GNU twin simd.s from one
# table: the instructions of the aarch64 section that glibc's asm needs
# beyond the base (isa/aarch64.pl: groups vector, sve, sme, tags and copies,
# and the q, b, h loads and stores, pairs, prefetch, hints and sys forms),
# each with operands of its own. ff takes the operands in field order, the
# destination last (see isa/aarch64.pl).
#
#   perl progs/aarch64/mksimd.pl          writes simd.ff and simd.s here
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

# Advanced SIMD
row("$_.16b", [qw(v0 v1 v3)], "$_ v3.16b, v1.16b, v0.16b") for qw(cmeq cmhs umaxp uminp addp sshl and bic orr eor bit);
row("$_.16b", [qw(v7 v30 v12)], "$_ v12.16b, v30.16b, v7.16b") for qw(cmeq umaxp and);
row('cmeqz.16b', [qw(v1 v3)], 'cmeq v3.16b, v1.16b, #0');
row('cmeqz.8b', [qw(v1 v3)], 'cmeq v3.8b, v1.8b, #0');
row('cmltz.16b', [qw(v31 v2)], 'cmlt v2.16b, v31.16b, #0');
row('addhn.8b', [qw(v0 v1 v3)], 'addhn v3.8b, v1.8h, v0.8h');
row('ushr.16b', [5, qw(v1 v3)], 'ushr v3.16b, v1.16b, #3');
row('ushr.16b', [0, qw(v1 v3)], 'ushr v3.16b, v1.16b, #8');
row('shrn.8b', [6, qw(v1 v3)], 'shrn v3.8b, v1.8h, #2');
row('shrn.8b', [4, qw(v2 v0)], 'shrn v0.8b, v2.8h, #4');
row('dup.16b', [qw(w1 v3)], 'dup v3.16b, w1');
row('dup.4s', [qw(w9 v3)], 'dup v3.4s, w9');
row('movi.16b', [90, 'v3'], 'movi v3.16b, #0x5a');
row('movi.16b', [255, 'v29'], 'movi v29.16b, #0xff');
row('mvni.4s', [90, 'v3'], 'mvni v3.4s, #0x5a');
row('mvni.4s.lsl8', [90, 'v3'], 'mvni v3.4s, #0x5a, lsl 8');
row('bici.8h', [90, 'v3'], 'bic v3.8h, #0x5a');
row('bici.8h.lsl8', [15, 'v4'], 'bic v4.8h, #0xf, lsl 8');
row('tbl.16b.x2', [qw(v1 v4 v3)], 'tbl v3.16b, {v4.16b, v5.16b}, v1.16b');
row('ld1.16b', [qw(x1 v3)], 'ld1 {v3.16b}, [x1]');
row('ld1.16b.post', [qw(x1 v3)], 'ld1 {v3.16b}, [x1], #16');
row('ld1.16b.x2', [qw(x1 v3)], 'ld1 {v3.16b, v4.16b}, [x1]');
row('ld1.16b.x2.post', [qw(x5 v30)], 'ld1 {v30.16b, v31.16b}, [x5], #32');
row('ld1.2d.x2', [qw(sp v3)], 'ld1 {v3.2d, v4.2d}, [sp]');
row('ld1.2d.x2.post', [qw(sp v3)], 'ld1 {v3.2d, v4.2d}, [sp], #32');

# q, b and h registers in memory (s and d were there)
row('ldr.q', [qw(32 x1 q3)], 'ldr q3, [x1, #32]');
row('str.q', [qw(65520 sp q31)], 'str q31, [sp, #65520]');
row('ldr.q.pre', [qw(32 x1 q3)], 'ldr q3, [x1, #32]!');
row('str.q.pre', [qw(-256 x1 q3)], 'str q3, [x1, #-256]!');
row('ldr.q.post', [qw(32 x1 q3)], 'ldr q3, [x1], #32');
row('str.q.post', [qw(255 x1 q3)], 'str q3, [x1], #255');
row('ldr.q.reg', [qw(x2 3 0 x1 q3)], 'ldr q3, [x1, x2]');
row('str.q.reg', [qw(x2 3 1 x1 q3)], 'str q3, [x1, x2, lsl #4]');
row('ldur.q', [qw(-3 x1 q3)], 'ldur q3, [x1, #-3]');
row('stur.q', [qw(17 x1 q3)], 'stur q3, [x1, #17]');
row('ldp.q', [qw(32 q4 x1 q3)], 'ldp q3, q4, [x1, #32]');
row('stp.q', [qw(-1024 q4 sp q3)], 'stp q3, q4, [sp, #-1024]');
row('ldp.q.pre', [qw(32 q4 x1 q3)], 'ldp q3, q4, [x1, #32]!');
row('stp.q.pre', [qw(1008 q0 x1 q0)], 'stp q0, q0, [x1, #1008]!');
row('ldp.q.post', [qw(32 q4 x1 q3)], 'ldp q3, q4, [x1], #32');
row('stp.q.post', [qw(64 q9 x2 q8)], 'stp q8, q9, [x2], #64');
row('str.b', [qw(0 x1 b3)], 'str b3, [x1]');
row('ldr.b', [qw(4095 x1 b3)], 'ldr b3, [x1, #4095]');
row('stur.h', [qw(-1 x1 h3)], 'stur h3, [x1, #-1]');
row('ldr.h', [qw(8190 x1 h3)], 'ldr h3, [x1, #8190]');
row('str.s.reg', [qw(x2 3 1 x1 s3)], 'str s3, [x1, x2, lsl #2]');
row('ldnp', [qw(16 x4 x1 x3)], 'ldnp x3, x4, [x1, #16]');
row('stnp', [qw(-512 x4 sp x3)], 'stnp x3, x4, [sp, #-512]');
row('prfm', [qw(4352 x3 16)], 'prfm pstl1keep, [x3, #4352]');
row('prfm', [qw(0 x3 0)], 'prfm pldl1keep, [x3]');

# hints and sys forms by their names
row('bti', [], 'bti');
row('bti.c', [], 'bti c');
row('bti.j', [], 'bti j');
row('bti.jc', [], 'bti jc');
row('paciasp', [], 'paciasp');
row('autiasp', [], 'autiasp');
row('chkfeat', [], 'hint 40');
row('dc.zva', ['x3'], 'dc zva, x3');
row('dc.gva', ['x3'], 'dc gva, x3');
row('dc.gzva', ['x3'], 'dc gzva, x3');
row('gcsss1', ['x3'], 'sys #3, c7, c7, #2, x3');
row('gcsss2', ['xzr'], 'sysl xzr, #3, c7, c7, #3');
row('gcspopm', ['x4'], 'sysl x4, #3, c7, c7, #1');

# SVE
row('whilelo.b', [qw(x3 x2 p1)], 'whilelo p1.b, x2, x3');
row('whilelo.b', [qw(xzr x9 p15)], 'whilelo p15.b, x9, xzr');
row('ld1b', [qw(0 p1 x1 z3)], 'ld1b {z3.b}, p1/z, [x1]');
row('ld1b', [qw(-2 p1 x1 z3)], 'ld1b {z3.b}, p1/z, [x1, #-2, mul vl]');
row('ld1b', [qw(7 p7 sp z31)], 'ld1b {z31.b}, p7/z, [sp, #7, mul vl]');
row('ld1b.reg', [qw(x2 p1 x1 z3)], 'ld1b {z3.b}, p1/z, [x1, x2]');
row('st1b', [qw(-8 p1 x1 z3)], 'st1b {z3.b}, p1, [x1, #-8, mul vl]');
row('st1b', [qw(0 p0 x0 z0)], 'st1b {z0.b}, p0, [x0]');
row('st1b.reg', [qw(x2 p1 x1 z3)], 'st1b {z3.b}, p1, [x1, x2]');
row('cmpne.b', [qw(z4 p1 z3 p2)], 'cmpne p2.b, p1/z, z3.b, z4.b');
row('cmphi.b', [qw(z4 p1 z3 p2)], 'cmphi p2.b, p1/z, z3.b, z4.b');
row('ptrue.b', [qw(31 p2)], 'ptrue p2.b');
row('ptrue.b', [qw(1 p9)], 'ptrue p9.b, vl1');
row('cntb', [qw(0 31 x3)], 'cntb x3');
row('cntb', [qw(2 31 x3)], 'cntb x3, all, mul #3');
row('dup.b', [qw(w1 z3)], 'dup z3.b, w1');

# SME
row('addsvl', [qw(x1 -2 x3)], 'addsvl x3, x1, #-2');
row('addsvl', [qw(sp 31 sp)], 'addsvl sp, sp, #31');
row('str.za', [qw(1 x1 5)], 'str za[w13, 5], [x1, #5, mul vl]');
row('str.za', [qw(0 sp 0)], 'str za[w12, 0], [sp]');
row('smstop', [], 'smstop');
row('smstop.za', [], 'smstop za');

# MTE and MOPS
for my $m (qw(stg stzg st2g stz2g)) {
    row($m, [qw(32 x1 x3)], "$m x3, [x1, #32]");
    row("$m.pre", [qw(-4096 sp x3)], "$m x3, [sp, #-4096]!");
    row("$m.post", [qw(4080 x1 sp)], "$m sp, [x1], #4080");
}
row($_, [qw(x1 x2 x3)], "$_ [x3]!, [x1]!, x2!") for qw(cpyfp cpyfm cpyfe cpyp cpym cpye);
row($_, [qw(x1 x2 x3)], "$_ [x3]!, x2!, x1") for qw(setp setm sete);

my $ff = node('_start:', node('comment', node('The instructions glibc\'s aarch64 asm needs beyond the base, with their GNU twin simd.s (written by mksimd.pl).')),
    map { my ($n, $ops) = @$_; node($n, map { node($_) } @$ops) } @rows);
open my $h, '>:raw', "$dir/simd.ff" or die "mksimd: simd.ff: $!\n";
print $h write_ff(node('', $ff));
close $h;
open $h, '>', "$dir/simd.s" or die "mksimd: simd.s: $!\n";
print $h "// The GNU twin of simd.ff (written by mksimd.pl).\n\t.text\n\t.globl _start\n_start:\n";
print $h "\t$_->[2]\n" for @rows;
close $h;
printf "mksimd: %d instructions\n", scalar @rows;
