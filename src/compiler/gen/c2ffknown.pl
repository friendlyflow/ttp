#!/usr/bin/env perl
# Copyright (C) 2026 Nico Verrijdt
# This file is part of ttp. It is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, version 3 of the License.
# It comes with no warranty. See the file LICENSE for the full text.
#
# c2ffknown.pl — c2ff-crosscheck's known departures: where csema -l writes
# on purpose what the frozen gen/c2ff.pl does not, the rule that reads
# csema's text as c2ff.pl's, each with its reason. src/glibc's
# c2ff-crosscheck (its pages, programs, units and clayer-check's units)
# compares c2ff.pl's text with csema's after it.
#
#   perl c2ffknown.pl --target T csema.ff.txt > as-c2ff.ff.txt
#
# The rules (a leaf is a line of the text, its indent kept):
#   reserved  name' is name where name is a target's instruction form that
#             csema reserves and c2ff.pl does not: since 2026-11-20 (the
#             user's choice) csema reserves every target's instruction forms
#             (S2ffRes.pm, cl_m.c's cl_reserve_target); c2ff.pl reserves
#             them on x86_64 and arm alone, riscv64's and aarch64's words
#             and registers only (aarch64's brk, ret, str, b; riscv64's add,
#             sub, or ...).
#
# Not covered yet (they still differ, each csema's on purpose; a rule for
# each is a later lane's): a function's statics named by their unit; a
# global's item `: sizeof`; C's complex arithmetic written of its parts
# (__cx_N, __mulXc3); x86_64's "=x" barrier of an asm; the call of a cast
# function; weak and with; arm's __gcc_personality_v0.
#
# A host tool (Perl).
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use S2ffRes;

my $target = 'riscv64';
if (@ARGV >= 2 && $ARGV[0] eq '--target') { (undef, $target) = splice @ARGV, 0, 2 }
die "usage: c2ffknown.pl [--target T] csema.ff.txt\n" unless @ARGV == 1;
my %beyond = $target =~ /^(riscv64|aarch64)$/ ? map { $_ => 1 } S2ffRes::forms_only($target) : ();
open my $h, '<', $ARGV[0] or die "c2ffknown: $ARGV[0]: $!\n";
while (my $l = <$h>) {
    # reserved
    $l =~ s/^( *)([A-Za-z_][A-Za-z0-9_]*)'(:?)$/$beyond{$2} ? "$1$2$3" : "$1$2'$3"/e;
    print $l;
}
