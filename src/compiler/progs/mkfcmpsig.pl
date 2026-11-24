#!/usr/bin/env perl
# mkfcmpsig.pl — writes progs/cfcmpsig.ff: C's < <= > >= on floating values
# are signaling (invalid on a quiet NaN), == and != quiet, on each target:
# a quiet NaN of float and of double against 1 with each operator, the
# target's invalid flag read after each (riscv64's fflags, x86_64's MXCSR,
# aarch64's FPSR, arm's FPSCR) by asm functions of the target's own.
#   cd src/compiler && perl progs/mkfcmpsig.pl
use strict; use warnings;
my $out = shift // 'progs';
my $lic = "license\n  GPL-3.0-only\n  Copyright (C) 2026 Nico Verrijdt\n  This file is part of ttp. It is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.\n  It comes with no warranty. See the file LICENSE for the full text.\n";
# per target: the asm that reads the flags into the result register, that clears them, and the invalid flag's bit
my %T = (
  riscv64 => { get => "    csrrs\n      1\n      zero\n      a0\n    ret\n", clr => "    csrrw\n      1\n      zero\n      zero\n    ret\n", bit => 16 },
  x86_64  => { get => "    stmxcsr.m\n      -8\n      rsp\n    movl.m\n      -8\n      rsp\n      eax\n    ret\n",
               clr => "    stmxcsr.m\n      -8\n      rsp\n    andl.mi\n      -64\n      -8\n      rsp\n    ldmxcsr.m\n      -8\n      rsp\n    ret\n", bit => 1 },
  aarch64 => { get => "    mrs\n      0xda21\n      x0\n    ret\n", clr => "    msr\n      0xda21\n      xzr\n    ret\n", bit => 1 },
  arm     => { get => "    vmrs\n      r0\n    bx\n      lr\n", clr => "    vmrs\n      r0\n    bici\n      0\n      0x9f\n      r0\n      r0\n    vmsr\n      r0\n    bx\n      lr\n", bit => 1 },
);
my @targets = qw(riscv64 x86_64 aarch64 arm);
my $p = $lic . "comment\n  C's < <= > >= on floating values are signaling comparisons, invalid on a quiet NaN (x86_64's comis, aarch64's fcmpe,\n"
  . "  arm's vcmpe, riscv64's flt and fle), == and != quiet (ucomis, fcmp, vcmp, feq): a quiet NaN of float and of double\n"
  . "  against 1 with each, and math.h's isless (no comparison of a NaN, quiet), the invalid flag read after each by an asm function of\n  the target's own. Exit 42: 14 right.\n";
my $defs = $lic . "comment\n  A library for progs/cfcmpsig.ff: each target's asm that reads its floating flags (into the result register) and clears them.\ncfcmpsigdefs:\n";
for my $t (@targets) {
    $defs .= "  getfl_$t:\n    asm\n$T{$t}{get}  clrfl_$t:\n    asm\n$T{$t}{clr}";
}
$p = $lic . "include\n  cfcmpsigdefs.ff\n" . substr($p, length $lic);
my $body = sub {
    my ($t) = @_;
    my $s = '';
    for my $ty (['float', 'fn'], ['double', 'dn']) {
        my ($k, $v) = @$ty;
        for my $op (['<', 1], ['<=', 1], ['>', 1], ['>=', 1], ['==', 0], ['!=', 0]) {
            my ($o, $sig) = @$op;
            my $want = $o eq '!=' ? 1 : 0;
            $s .= "        clrfl_$t\n        v\n        =\n        :\n          $v\n          $o\n          one_$k\n"
                . "        inv\n        =\n        :\n          getfl_$t\n          &\n          $T{$t}{bit}\n"
                . "        if\n          :\n            v\n            ==\n            $want\n          &&\n          :\n            inv\n            "
                . ($sig ? "!=" : "==") . "\n            0\n          r\n          +=\n          1\n";
        }
        # (math.h's isless, as glibc's builtins.ff writes it: no comparison of a NaN, so quiet)
        $s .= "        clrfl_$t\n        v\n        =\n        0\n        if\n          :\n            $v\n            ==\n            $v\n          &&\n          :\n            one_$k\n            ==\n            one_$k\n"
            . "          v\n          =\n          :\n            $v\n            <\n            one_$k\n"
            . "        inv\n        =\n        :\n          getfl_$t\n          &\n          $T{$t}{bit}\n"
            . "        if\n          :\n            v\n            ==\n            0\n          &&\n          :\n            inv\n            ==\n            0\n          r\n          +=\n          1\n";
    }
    $s;
};
$p .= "_start:\n  void\n  r:\n    long\n    0\n  v:\n    long\n    0\n  inv:\n    long\n    0\n"
   . "  nb:\n    u32\n    0x7fc00000\n  db:\n    u64\n    0x7ff8000000000000\n"
   . "  fn:\n    float\n    :\n      :\n        cast\n          float\n          * pointer\n        nb\n        & address\n      * pointer\n"
   . "  dn:\n    double\n    :\n      :\n        cast\n          double\n          * pointer\n        db\n        & address\n      * pointer\n"
   . "  one_float:\n    float\n    1\n  one_double:\n    double\n    1\n  :\n    compile time\n";
my $first = 1;
for my $t (@targets) {
    $p .= ($first ? "    if\n" : "    else if\n") . "      target\n      ==\n      $t\n      emit\n" . $body->($t);
    $first = 0;
}
$p .= "  syscall\n    SYS_exit\n    :\n      r\n      +\n      28\n";
for my $f (["cfcmpsig", $p], ["cfcmpsigdefs", $defs]) {
    my ($n, $x) = @$f;
    open my $h, '>', "$out/$n.ff.txt" or die; print $h $x; close $h;
    system("perl gen/fftext.pl ff $out/$n.ff.txt > $out/$n.ff") == 0 or die; unlink "$out/$n.ff.txt";
}
