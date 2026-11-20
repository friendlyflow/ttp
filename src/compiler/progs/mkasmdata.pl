#!/usr/bin/env perl
# mkasmdata.pl — writes progs/casmdata.ff, casmdatadefs.ff and the folder
# casmdatalib (index.ff, lazy.ff): an asm function of each target whose
# data entries (a label whose first child, through its layers, is asm,
# then data: the entry form) C reads by name: one of a word, one of 300
# words, its children in layers 0: 1:, on a page and in a folder read
# lazily. (A data label without asm first is a label of its function, no
# entry: s2ff writes asm first under a global data label; the master's
# choice (B), 2026-11-20.)
#
#   cd src/compiler && perl progs/mkasmdata.pl
#
# A host tool (core Perl only), not part of ttpc.
use strict; use warnings;
my $out = shift // 'progs';
my $lic = "license\n  GPL-3.0-only\n  Copyright (C) 2026 Nico Verrijdt\n  This file is part of ttp. It is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.\n  It comes with no warranty. See the file LICENSE for the full text.\n";
my %ret = (riscv64 => [["ret"]], x86_64 => [["ret"]], aarch64 => [["ret"]], arm => [["bx", ["lr"]]]);
my @targets = qw(riscv64 x86_64 aarch64 arm);
my $N = 300;
sub txt { my ($n, $d) = @_; my ($c, @k) = @$n; ('  ' x $d) . "$c\n" . join '', map { txt($_, $d + 1) } @k }
sub layers {
    my @n = @_;
    return @n if @n <= 255;
    my $per = 255; $per *= 255 while @n > $per * 255;
    my @l;
    for (my $i = 0; $i < @n; $i += $per) { my $e = $i + $per - 1 < $#n ? $i + $per - 1 : $#n; push @l, [scalar(@l) . ':', layers(@n[$i .. $e])] }
    @l;
}
# the asm function of target t, its names prefixed by x: small (one word, v), big (N words: i * m)
sub unit {
    my ($t, $x, $v, $m) = @_;
    txt(["${x}dataunit_$t:", ["asm"], ["align", ["16"]], @{ $ret{$t} },
        ["${x}small_$t:", ["asm"], ["word", ["$v"]]],
        ["${x}big_$t:", layers(["asm"], map { ["word", [$_ * $m]] } 0 .. $N - 1)]], 1);
}
my $defs = $lic . "comment\n  A library for progs/casmdata.ff: an asm function of each target with two data entries (asm first, then data):\n  one of a word, one of $N words, past the 255 children of a node, in layers 0: 1: (asm first in layer 0).\ncasmdatadefs:\n";
my $lz = $lic . "comment\n  A page of progs/casmdatalib, which progs/casmdata.ff includes as a folder, read lazily: as progs/casmdatadefs.ff, its data entries named in the index.\ncasmdatalib:\n";
my $idx = $lic . "comment\n  the names the files of this folder define and the file of each: an asm function's data entries too\nindex:\n";
for my $t (@targets) {
    $defs .= unit($t, '', 5, 1);
    $lz .= unit($t, 'l', 7, 2);
    $idx .= "  l$_" . "_$t:\n    lazy.ff\n" for qw(dataunit small big);
}
mkdir "$out/casmdatalib" unless -d "$out/casmdatalib";
open my $h, '>', "$out/casmdatadefs.ff.txt" or die; print $h $defs; close $h;
open $h, '>', "$out/casmdatalib/index.ff.txt" or die; print $h $idx; close $h;
open $h, '>', "$out/casmdatalib/lazy.ff.txt" or die; print $h $lz; close $h;
# the program: small 5 + big[299] 299 + lsmall 7 + lbig[1] 2 + lbig[299] 598 = 911; exits 911 - 869 = 42
my $p = $lic . "include\n  casmdatadefs.ff\ninclude\n  casmdatalib\ncomment\n  The data entries of an asm function (a label whose first child is asm, then data, through its layers) are names C reads:\n  one of a word and one of $N words, its children in layers 0: 1:, on a page and in a folder read lazily (each target its own).\n  This is the form s2ff writes under a global data label; a label without asm first is the function's own.\n_start:\n  void\n  r:\n    long\n    0\n  :\n    compile time\n";
my $first = 1;
my $l = $N - 1;
for my $t (@targets) {
    $p .= ($first ? "    if\n" : "    else if\n") . "      target\n      ==\n      $t\n      emit\n";
    $first = 0;
    $p .= "        r\n        =\n" . join("        +\n", map { my ($n, $i) = @$_; "        :\n          :\n            cast\n              int\n              * pointer\n            $n\n            & address\n            +\n            $i\n          * pointer\n" } ["small_$t", 0], ["big_$t", $l], ["lsmall_$t", 0], ["lbig_$t", 1], ["lbig_$t", $l]);
}
$p .= "  syscall\n    SYS_exit\n    :\n      r\n      -\n      869\n";
open $h, '>', "$out/casmdata.ff.txt" or die; print $h $p; close $h;
for my $f ("$out/casmdata.ff.txt", "$out/casmdatadefs.ff.txt", "$out/casmdatalib/index.ff.txt", "$out/casmdatalib/lazy.ff.txt") {
    (my $ff = $f) =~ s/\.txt$//;
    system("perl gen/fftext.pl ff $f > $ff") == 0 or die "fftext: $f\n";
    unlink $f;
}
