#!/usr/bin/env perl
# mkmanytexts.pl — writes progs/cmanytexts.ff: a global array of 1101 char * pointer items, 1100 texts (that start like
# numbers, as glibc's math tests' names: -16, FP_INT_DOWNWARD, 4) and a 0, the null pointer; such texts as a declaration's
# item and a call's argument too (gtexts.pl: a global's texts were 1024 at most).
#   cd src/compiler && perl progs/mkmanytexts.pl
use strict; use warnings;
my $out = shift // 'progs';
my $lic = "license\n  GPL-3.0-only\n  Copyright (C) 2026 Nico Verrijdt\n  This file is part of ttp. It is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, version 3 of the License.\n  It comes with no warranty. See the file LICENSE for the full text.\n";
my @t = map { my $k = $_ % 4; $k == 0 ? "-$_, FP_INT_DOWNWARD, 4" : $k == 1 ? "+$_, 0xf.ffffffffffff8p+1020" : $k == 2 ? "0x4p-1024, $_" : "0x8$_, FP_INT_TONEAREST, 1" } 0 .. 1099;
my $p = $lic . "comment\n  A global of more than 1024 texts (gtexts.pl: the 1025th stopped the compile, naming it), texts that start like numbers\n  (glibc's math tests' names) as a global's items, a declaration's item and a call's argument; a whole number, 0, stays the null pointer.\n";
$p .= "strlen:\n  long\n  s:\n    char\n    * pointer\n  n:\n    long\n    0\n  while\n    s\n      n\n    n\n    ++\n  return\n    n\n";
$p .= "tab:\n  array\n    char\n    * pointer\n    1101\n";
my @items = ((map { "    cast\n      char\n      * pointer\n    $_\n" } @t), "    0\n");
while (@items) { my @g = splice @items, 0, 120; $p .= "  items\n" . join("", @g) }
my ($last, $l99) = ($t[1099], length $t[1099]);
$p .= "_start:\n  void\n  r:\n    long\n    0\n  p:\n    char\n    * pointer\n    -16, FP_INT_DOWNWARD, 4\n";
$p .= "  if\n    strlen\n      :\n        :\n          tab\n          +\n          1099\n        * pointer\n    ==\n    $l99\n    r\n    +=\n    20\n";
$p .= "  if\n    :\n      :\n        tab\n        +\n        1100\n      * pointer\n    ==\n    0\n    r\n    +=\n    10\n";
$p .= "  if\n    strlen\n      p\n    ==\n    23\n    r\n    +=\n    6\n";
$p .= "  if\n    strlen\n      cast\n        char\n        * pointer\n      +0, 0xf.ffffffffffff8p+1020\n    ==\n    27\n    r\n    +=\n    6\n";
$p .= "  syscall\n    SYS_exit\n    r\n";
open my $h, '>', "$out/cmanytexts.ff.txt" or die; print $h $p; close $h;
system("perl gen/fftext.pl ff $out/cmanytexts.ff.txt > $out/cmanytexts.ff") == 0 or die; unlink "$out/cmanytexts.ff.txt";
