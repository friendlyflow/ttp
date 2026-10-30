#!/usr/bin/env perl
# clangvec.pl — a copy of a unit's .i for clang alone (CLANGFIX), where it
# includes gcc's intrinsics headers (<nmmintrin.h>: x86_64's strcspn-sse4.c
# and strspn-sse4.c): gcc's inline functions of them that the unit does not
# reach are made spaces, as many bytes (c2ff finds an asm statement's text
# in the .i by clang's offsets), for clang has other builtins than gcc for
# most of them (mmintrin.h's __builtin_ia32_vec_init_v2si ...). Those the
# unit reaches stay, gcc's builtins in them as clang has them too.
#
#   perl clangvec.pl unit.i > unit.clang.i
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;

local $/;
my $t = <>;
# each definition: extern __inline T __attribute__((__gnu_inline__, ...)) name (...) { ... }
# (indented too, or __inline__: avx512fp16intrin.h, avx10_2convertintrin.h)
my (@def, %def);
while ($t =~ /^[ \t]*extern\s+__inline(?:__)?\b[^{;]*?__gnu_inline__[^{;]*?\b(\w+)\s*\([^{;]*\)\s*\{/mg) {
    my ($name, $b) = ($1, $-[0]);
    my ($d, $i) = (1, pos($t));
    for (; $i < length $t && $d; $i++) { my $c = substr($t, $i, 1); $d++ if $c eq '{'; $d-- if $c eq '}' }
    push @def, [$name, $b, $i];
    $def{$name} = $#def;
    pos($t) = $i;
}
# what the rest of the unit names, then what those name in turn
my $rest = $t;
substr($rest, $_->[1], $_->[2] - $_->[1]) = ' ' x ($_->[2] - $_->[1]) for @def;
my %keep;
my @todo = grep { exists $def{$_} } $rest =~ /\b(\w+)\b/g;
while (defined(my $n = shift @todo)) {
    next if $keep{$n}++;
    my $d = $def[ $def{$n} ];
    push @todo, grep { exists $def{$_} && !$keep{$_} } substr($t, $d->[1], $d->[2] - $d->[1]) =~ /\b(\w+)\b/g;
}
# (one the unit reaches with a const int parameter, an immediate of gcc's
# builtin, _mm_cmpistri's __M, which clang wants constant: its declaration
# alone, the body spaces after a ;, and c2ff calls the builtin itself)
for my $d (@def) {
    next unless $keep{ $d->[0] };
    my $s = substr($t, $d->[1], $d->[2] - $d->[1]);
    next unless $s =~ /^[^{]*\bconst int\b/;
    my $h = index($s, '{');
    (my $body = substr($s, $h)) =~ s/[^\n]/ /g;
    substr($body, 0, 1) = ';';
    substr($t, $d->[1] + $h, length $body) = $body;
}
for my $d (@def) {
    next if $keep{ $d->[0] };
    (my $s = substr($t, $d->[1], $d->[2] - $d->[1])) =~ s/[^\n]/ /g;
    substr($t, $d->[1], $d->[2] - $d->[1]) = $s;
}
print $t;
