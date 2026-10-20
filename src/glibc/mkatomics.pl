#!/usr/bin/env perl
# mkatomics.pl — writes atomics.ff.txt: libatomic's functions, which gcc
# calls for an atomic builtin it does not expand (__atomic_load_4, ...),
# for 1, 2, 4 and 8 bytes, in ttpc's C layer. c2ff turns glibc's atomic
# builtins into calls of them. A ttpc program has one thread, so plain loads
# and stores are exact; real atomics come with threads.
#
#   perl mkatomics.pl > atomics.ff.txt
#
# A host tool (core Perl only).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";
use FF qw(node ttp_license write_txt);

sub leaf { map { node($_) } @_ }
sub param { my ($n, @t) = @_; node("$n:", leaf(@t)) }
sub content { node('content', node($_[0])) }

my @fns;
for my $n (1, 2, 4, 8) {
    my $u = "u" . 8 * $n;
    my @p = (param('p', 'address', $u));
    push @fns, node("__atomic_load_$n:", leaf($u), @p, param('order', 'int'),
        node('return', content('p')));
    push @fns, node("__atomic_store_$n:", leaf('void'), @p, param('v', $u), param('order', 'int'),
        content('p'), leaf('=', 'v'));
    push @fns, node("__atomic_exchange_$n:", leaf($u), @p, param('v', $u), param('order', 'int'),
        node('old:', leaf($u), content('p')), content('p'), leaf('=', 'v'), node('return', leaf('old')));
    push @fns, node("__atomic_compare_exchange_$n:", leaf('int'), @p, param('e', 'address', $u), param('d', $u),
        param('success', 'int'), param('failure', 'int'),
        node('if', content('p'), leaf('=='), content('e'), content('p'), leaf('=', 'd'), node('return', leaf(1))),
        content('e'), leaf('='), content('p'), node('return', leaf(0)));
    for my $op (['add', '+'], ['sub', '-'], ['and', '&'], ['or', '|'], ['xor', '^'], ['nand', '&']) {
        my ($name, $c) = @$op;
        # nand is ~(old & v)
        my @new = $name eq 'nand' ? (leaf('~'), node(':', leaf('old', $c, 'v'))) : leaf('old', $c, 'v');
        push @fns, node("__atomic_fetch_${name}_$n:", leaf($u), @p, param('v', $u), param('order', 'int'),
            node('old:', leaf($u), content('p')), content('p'), leaf('='), @new, node('return', leaf('old')));
        push @fns, node("__atomic_${name}_fetch_$n:", leaf($u), @p, param('v', $u), param('order', 'int'),
            node('old:', leaf($u), content('p')), content('p'), leaf('='), @new, node('return', content('p')));
    }
}
print write_txt(node('comment', node("libatomic's functions for one thread, written by mkatomics.pl.")),
    node('atomics:', ttp_license(), @fns));
