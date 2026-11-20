# Copyright (C) 2026 Nico Verrijdt
# This file is part of ttp. It is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, version 3 of the License.
# It comes with no warranty. See the file LICENSE for the full text.
#
# S2ffRes.pm — the names csema reserves on a target, which it writes name'
# (tools/dev/cs: cl_t.c's cl_reserve, cl_m.c's cl_reserve_target), for the
# Perl s2ffs (s2ff.pl, s2ffx86.pm, s2ff-aarch64.pl, s2ff-arm.pl), as
# tools/dev/s2ff/s2ff.c's resname for the C one:
#   the language's words;
#   riscv64's registers, another target's the registers group of its
#   section in shared.ff;
#   every target's instruction forms, the name: children of its
#   instruction groups there (the user's choice, 2026-11-20); on x86_64
#   x86_64gnu.ff's forms too.
# An asm definition of such a name, and each operand naming it, is name',
# as a C caller names it (setns' on x86_64, syscall' on aarch64 and arm).
# The groups as cl_m.c and s2ff.c list them. shared.ff and x86_64gnu.ff
# are read from src/compiler, next to gen/.
package S2ffRes;
use strict;
use warnings;
use FindBin;
use FF;

my @words = qw(if else while for return break continue comment address content syscall U L UL LL ULL
    array struct union enum function sizeof alignof compile emit fail number
    target include workspace switch case default goto char short int long void
    type i8 i16 i32 i64 i128 u8 u16 u32 u64 u128 float16 bfloat16 fract accum va_list va_start va_arg va_end va_copy
    alias ifunc asm items cast weak va_arg_pack va_arg_pack_len real imag generic section constructor destructor fs vector line byte half word dword);
my %groups = (
    riscv64 => [qw(integer system atomic float vector compressed)],
    x86_64 => [qw(alu1 alu2 move unary shift1 shift2 bit branch set cmov stack atomic system sse)],
    aarch64 => [qw(integer branch system memory atomic float vector sve sme)],
    arm => [qw(data data2 shifts multiply bits memory atomic branch system vfp a32x)],
);
my %res;
my $for = '';
sub slurp { my ($f) = @_; open my $h, '<:raw', $f or die "s2ff: cannot open $f: $!\n"; local $/; <$h> }
# (cl_reserve_form: a name: of letters, digits and _, a letter or _ first)
sub form { my ($s, $r) = @_; $r->{$1} = 1 if $s =~ /^([A-Za-z_][A-Za-z0-9_]*):$/ && length($s) >= 2 }
# (cl_reserve_gnu: a name: with no name: under it, a lower case letter first, is a form; else what is under it)
sub gnu {
    my ($n, $r) = @_;
    for my $x (@{ $n->{children} }) {
        my $s = $x->{content};
        if ($s =~ /^[a-z][A-Za-z0-9_]*:$/ && !grep { $_->{content} =~ /:$/ } @{ $x->{children} }) { form($s, $r) } else { gnu($x, $r) }
    }
}
# (the instruction forms alone, of a target's groups: c2ffknown.pl's)
my (%forms, %baseres);
sub init {
    my ($target) = @_;
    my %r = map { $_ => 1 } @words;
    my $dir = "$FindBin::Bin/..";
    my ($sh) = grep { $_->{content} eq 'shared:' } map { @{ $_->{children} } } FF::read_ff(slurp("$dir/shared.ff"));
    die "s2ff: no shared: in $dir/shared.ff\n" unless $sh;
    my ($sec) = grep { $_->{content} eq "$target:" } @{ $sh->{children} };
    die "s2ff: no section $target: in $dir/shared.ff\n" unless $sec;
    if ($target eq 'riscv64') {
        $r{$_} = 1 for qw(zero ra sp gp tp fp pc);
        for my $p (qw(x a s t f fa fs ft v)) { $r{"$p$_"} = 1 for 0 .. 31 }
    } else {
        my ($regs) = grep { $_->{content} eq 'registers:' } @{ $sec->{children} };
        die "s2ff: no registers: in the $target section of the shared page\n" unless $regs;
        for (@{ $regs->{children} }) { (my $c = $_->{content}) =~ s/:$//; $r{$_} = 1 for grep { length } split /\s+/, $c }
    }
    my %g = map { ("$_:" => 1) } @{ $groups{$target} };
    my %f;
    for my $x (grep { $g{ $_->{content} } } @{ $sec->{children} }) { form($_->{content}, \%f) for @{ $x->{children} } }
    %forms = %f;
    my %base = %r;
    $r{$_} = 1 for keys %f;
    if ($target eq 'x86_64') { gnu($_, \%r) for FF::read_ff(slurp("$dir/x86_64gnu.ff")) }
    %res = %r;
    %baseres = %base;
    $for = $target;
}
# the instruction forms of a target's groups that are no word or register (csema reserves them since
# 2026-11-20; c2ff.pl, frozen, reserves riscv64's and aarch64's words and registers alone)
sub forms_only {
    my ($target) = @_;
    init($target) if $for ne $target;
    grep { !$baseres{$_} } keys %forms;
}
# every name it reserves on a target
sub all_names { my ($target) = @_; init($target) if $for ne $target; keys %res }
# a name as csema writes it: name' where it reserves the name
sub name {
    my ($target, $n) = @_;
    init($target) if $for ne $target;
    return $n if $n eq '' || $n =~ /'$/ || !$res{$n};
    "$n'";
}
1;
