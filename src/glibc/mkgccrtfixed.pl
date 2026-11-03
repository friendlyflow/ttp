#!/usr/bin/env perl
# mkgccrtfixed.pl: the checks of arm's fixed-bit.c (progs/gccrt-fixed.h) from
# the prototypes in its units' .i: each function called on three patterns of
# bits, its result's bits printed.
#   perl mkgccrtfixed.pl LI/*.clang.i > progs/gccrt-fixed.h
use strict; use warnings;
my %proto;
for my $f (@ARGV) {
    open my $h, '<', $f or die "$f: $!";
    my ($name) = $f =~ m{/(_\w+)\.clang\.i$} or next;
    my %ext;
    while (<$h>) { $ext{$2} = [$1, $3] if /^extern (.+?) ?(__gnu_\w+) \((.*)\);/ }
    seek $h, 0, 0;
    my $prev = '';
    while (<$h>) { if (/^(__gnu_\w+) \(/) { my $n = $1; $proto{$n} = $ext{$n} if $prev =~ /\S/ && $ext{$n} } $prev = $_ }
}
my %fx = (QQ => 'short _Fract', UQQ => 'unsigned short _Fract', HQ => '_Fract', UHQ => 'unsigned _Fract', SQ => 'long _Fract', USQ => 'unsigned long _Fract',
    DQ => 'long long', UDQ => 'unsigned long long', HA => 'short _Accum', UHA => 'unsigned short _Accum', SA => '_Accum', USA => 'unsigned _Accum',
    DA => 'long _Accum', UDA => 'unsigned long _Accum');
my %in = (QI => 'signed char', UQI => 'unsigned char', HI => 'short', UHI => 'unsigned short', SI => 'int', USI => 'unsigned int', DI => 'long long', UDI => 'unsigned long long');
print "/* made by src/glibc/mkgccrtfixed.pl: arm's fixed-bit.c, every function */\n";
print "typedef $fx{$_} ${_}type;\n" for sort keys %fx;
print "typedef $in{$_} ${_}type;\n" for sort keys %in;
print "typedef float SFtype;\ntypedef double DFtype;\ntypedef int word_type;\n";
for my $m (sort keys %fx) {
    print "union fxu$m { ${m}type f; unsigned long long u; };\n";
    print "static ${m}type fxm$m (unsigned long long p) { union fxu$m v; v.u = p; return v.f; }\n";
    print "static unsigned long long fxb$m (${m}type x) { union fxu$m v; v.u = 0; v.f = x; return v.u; }\n";
}
for my $f (sort keys %proto) { my ($r, $a) = @{ $proto{$f} }; print "extern $r $f ($a);\n" }
my @p = ('0x3535353535353535ULL', '0x8181818181818181ULL', '0x0101010101017f01ULL');
my @q = ('0x2121212121212121ULL', '0x0303030303030303ULL', '0xc1c1c1c1c1c1c1c1ULL');
my @fl = ('0.3', '0.0625', '0.4375');
my @body;
for my $f (sort keys %proto) {
    my ($r, $a) = @{ $proto{$f} };
    my @a = $a eq 'void' ? () : split /\s*,\s*/, $a;
    for my $k (0 .. 2) {
        my @v; my @pre; my @post; my $i = 0;
        my $neg = $f =~ /fract(?:uns)?(?:sf|df)/ ? 0 : 0;
        for my $t (@a) {
            my $v = $i ? $q[$k] : $p[$k];
            if ($t =~ /^(\w+)type$/ && $fx{$1}) { push @v, "fxm$1 ($v)" }
            elsif ($t =~ /^(\w+)type$/ && $in{$1}) { push @v, "($t) $v" }
            elsif ($t eq 'SFtype' || $t eq 'DFtype') { my $s = $t eq 'SFtype' ? 'f' : ''; push @v, "$fl[$k]$s" }
            elsif ($t eq 'word_type') { push @v, $k + 1 - ($f =~ /helper/ && $i == 2 ? $k + 1 - ($k & 1) : 0) }
            elsif ($t =~ /^(\w+type) \*$/) { my $n = "x$i"; push @pre, "$1 $n = ($1) $v;"; push @v, "&$n"; push @post, "w ((unsigned long long) $n);" }
            else { die "$f: $t\n" }
            $i++;
        }
        my $call = "$f (" . join(', ', @v) . ')';
        my $out = $r eq 'void' ? "$call;"
            : $r =~ /^(\w+)type$/ && $fx{$1} ? "w (fxb$1 ($call));"
            : $r eq 'SFtype' ? "f ($call);" : $r eq 'DFtype' ? "d ($call);"
            : "w ((unsigned long long) $call);";
        push @body, '{ ' . join(' ', @pre, $out, @post) . ' }';
    }
}
my $n = 0;
my @fns;
while (@body) {
    my @b = splice @body, 0, 60;
    print "static void fxt$n (void) {\n  double wg = 0.0; (void) wg;\n", map({ "  $_\n" } @b), "}\n";
    push @fns, "fxt$n ();"; $n++;
}
print "static void fxall (void) { ", join(' ', @fns), " }\n";
