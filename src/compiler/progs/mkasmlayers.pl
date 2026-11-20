#!/usr/bin/env perl
# mkasmlayers.pl — writes progs/casmlayers.ff, casmlayersdefs.ff and the
# folder casmlayerslib (index.ff, lazy.ff): asm functions of each target
# past the 255 children of a node, their children in layers 0: 1: (as
# FF.pm's layers makes them), with entry blocks and a block label in the
# layers (gen/patches/asmlayers.pl).
#
#   cd src/compiler && perl progs/mkasmlayers.pl
#
# A host tool (core Perl only), not part of ttpc.
use strict; use warnings;
my $out = shift // 'progs';
my $lic = "license\n  GPL-3.0-only\n  Copyright (C) 2026 Nico Verrijdt\n  This file is part of ttp. It is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.\n  It comes with no warranty. See the file LICENSE for the full text.\n";
# per target: inc N (a0/rax/x0/r0 += N), jump to label, nop, return
my %T = (
  riscv64 => { inc => sub { ["addi", $_[0], "a0", "a0"] }, j => sub { ["j", $_[0]] }, nop => ["nop"], ret => ["ret"] },
  x86_64  => { inc => sub { ["addq.i", $_[0], "rdi"] }, j => sub { ["jmp", $_[0]] }, nop => ["nop"], ret => ["movq", "rdi", "rax"], ret2 => ["ret"] },
  aarch64 => { inc => sub { ["addi", $_[0], "x0", "x0"] }, j => sub { ["b", ["rel", [$_[0]]]] }, nop => ["nop"], ret => ["ret"] },
  arm     => { inc => sub { ["addi", 0, $_[0], "r0", "r0"] }, j => sub { ["b", ["arel", [$_[0]]]] }, nop => ["nop"], ret => ["bx", "lr"] },
);
my @targets = qw(riscv64 x86_64 aarch64 arm);
# a node: [content, children...]; an instruction [op, args...] is a node with leaf children
sub ins { my ($op, @a) = @{ $_[0] }; [$op, map { ref $_ ? $_ : [$_] } @a] }
sub txt { my ($n, $d) = @_; my ($c, @k) = @$n; ('  ' x $d) . "$c\n" . join '', map { txt($_, $d + 1) } @k }
sub layers {
    my @n = @_;
    return @n if @n <= 255;
    my $per = 255; $per *= 255 while @n > $per * 255;
    my @l;
    for (my $i = 0; $i < @n; $i += $per) { my $e = $i + $per - 1 < $#n ? $i + $per - 1 : $#n; push @l, [scalar(@l) . ':', layers(@n[$i .. $e])] }
    @l;
}
my $defs = $lic . "comment\n  A library for progs/casmlayers.ff: an asm function of each target past the 255 children of a node, its children in layers 0: 1: (the overflow of a node, transparent):\n  asm and align first in layer 0, an entry block (a block label whose first child is asm) in layer 0 and one in layer 1,\n  a plain block label in layer 1 that the function jumps to, and an asm function that jumps to the entry in layer 1.\ncasmlayersdefs:\n";
# the big function of target t, its names prefixed by x (l for the lazy folder's)
sub big {
    my ($t, $x) = @_;
    my $T = $T{$t};
    my @k = (["asm"], ["align", ["16"]], ins($T->{inc}->(1)), ins($T->{j}->("${x}over_$t")),
        # an entry in layer 0: x + 8, then on to over
        ["${x}early_$t:", ["asm"], ins($T->{inc}->(8)), ins($T->{j}->("${x}over_$t"))]);
    push @k, ins($T->{nop}) for 1 .. ($ENV{NOPS} // 300);
    push @k, ["${x}over_$t:", ins($T->{inc}->(2))];
    push @k, ["${x}mid_$t:", ["asm"], ins($T->{inc}->(4)), ins($T->{ret}), ($T->{ret2} ? ins($T->{ret2}) : ())];
    txt(["${x}big_$t:", layers(@k)], 1);
}
for my $t (@targets) {
    my $T = $T{$t};
    $defs .= big($t, '');
    $defs .= txt(["jumper_$t:", ["asm"], ins($T->{inc}->(16)), ins($T->{j}->("mid_$t"))], 1);
}
# the lazy folder: its index (the names and their file) and the file
mkdir "$out/casmlayerslib" unless -d "$out/casmlayerslib";
my $idx = $lic . "comment\n  the names the files of this folder define and the file of each: an asm function's entries too\nindex:\n";
my $lz = $lic . "comment\n  A page of progs/casmlayerslib, which progs/casmlayers.ff includes as a folder, read lazily: an asm function of each target past the 255 children of a node,\n  its entries in its layers named in the index too.\ncasmlayerslib:\n";
for my $t (@targets) {
    $lz .= big($t, 'l');
    $idx .= "  l$_" . "_$t:\n    lazy.ff\n" for qw(big early mid);
}
open my $hl, '>', "$out/casmlayerslib/index.ff.txt" or die; print $hl $idx; close $hl;
open $hl, '>', "$out/casmlayerslib/lazy.ff.txt" or die; print $hl $lz; close $hl;
open my $h, '>', "$out/casmlayersdefs.ff.txt" or die; print $h $defs; close $h;
# the program: big(0) 7 + early(0) 14 + mid(0) 4 + jumper(0) 20 + (&mid)(1) 5 = 50, the lazy folder's 7 + 14 + 4; exits r - 33 = 42
my $p = $lic . "include\n  casmlayersdefs.ff\ninclude\n  casmlayerslib\ncomment\n  An asm function past the 255 children of a node has its children in layers 0: 1: ..., which are transparent:\n  its entry blocks (a block label whose first child is asm) in a layer are names C calls and takes the address of, and asm jumps to;\n  its block labels in a layer are its own; its asm and align first in layer 0 make it an asm function placed at a multiple of 16.\n  So too in a folder included lazily (casmlayerslib), its entries named in the index. Each target calls its own (s2ff wrote such a function only up to 255 parts).\n_start:\n  void\n  r:\n    long\n    0\n  a:\n    long\n    0\n  :\n    compile time\n";
my $first = 1;
for my $t (@targets) {
    $p .= ($first ? "    if\n" : "    else if\n") . "      target\n      ==\n      $t\n      emit\n";
    $first = 0;
    $p .= "        r\n        =\n        big_$t\n          0\n        +\n        early_$t\n          0\n        +\n        mid_$t\n          0\n        +\n        jumper_$t\n          0\n        +\n        :\n          mid_$t\n          & address\n          .\n          1\n        +\n        lbig_$t\n          0\n        +\n        learly_$t\n          0\n        +\n        lmid_$t\n          0\n";
    $p .= "        a\n        =\n        cast\n          long\n        big_$t\n        & address\n";
}
$p .= "  syscall\n    SYS_exit\n    :\n      r\n      -\n      33\n      +\n      :\n        a\n        &\n        15\n";
open $h, '>', "$out/casmlayers.ff.txt" or die; print $h $p; close $h;
# each text to its tree, the text removed
for my $f ("$out/casmlayers.ff.txt", "$out/casmlayersdefs.ff.txt", "$out/casmlayerslib/index.ff.txt", "$out/casmlayerslib/lazy.ff.txt") {
    (my $ff = $f) =~ s/\.txt$//;
    system("perl gen/fftext.pl ff $f > $ff") == 0 or die "fftext: $f\n";
    unlink $f;
}
