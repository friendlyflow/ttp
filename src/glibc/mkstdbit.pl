#!/usr/bin/env perl
# mkstdbit.pl — writes stdbit.ff.txt: C23's bit functions as gcc has them
# built in (__builtin_stdc_leading_zeros ... __builtin_stdc_rotate_right),
# which are type-generic: their width is their argument's type, and
# bit_floor, bit_ceil and the rotations give that type. One function for
# each of the unsigned types' widths, 8, 16, 32 and 64 bits, named for it
# (`__builtin_stdc_leading_zeros u8`): c2ff names a call so from its first
# argument's type (clang-prelude.h declares them for clang, overloaded on
# the five unsigned types). Each counts on the u64 builtins of
# builtins.ff.txt (clzll, ctzll, popcountll, which give 64 for 0), on its
# argument zero-extended (a cast to u64: riscv64's lp64d sign-extends an
# unsigned int passed as itself); bit_ceil gives 0 where the result does not fit,
# as gcc's does.
#
#   perl mkstdbit.pl > stdbit.ff.txt
#
# A host tool (core Perl only).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";
use FF qw(node ttp_license write_txt);

sub leaf { map { node($_) } @_ }
sub param { my ($n, @t) = @_; node("$n:", leaf(@t)) }
sub grp { node(':', @_) }
sub ret { node('return', @_) }
sub iff { my ($cond, @body) = @_; node('if', $cond, @body) }
sub cast { my ($t, $v) = @_; (node('cast', leaf($t)), $v) }
# a call of another of them, of the same width
sub call { my ($f, $n, @args) = @_; node("__builtin_stdc_$f u$n", @args) }

my @fns;
for my $n (8, 16, 32, 64) {
    my $t = "u$n";
    # (the type's bits, all 1: x ^ m is ~x in the type)
    my @m = $n == 64 ? leaf('ULL', '18446744073709551615') : $n == 32 ? leaf('U', '4294967295') : leaf(2 ** $n - 1);
    my @x = (param('x', $t));
    my $not = grp(leaf('x', '^'), @m);
    my $zero = grp(leaf('x', '==', 0));
    push @fns,
        node("__builtin_stdc_leading_zeros $t:", leaf('u32'), @x,
            ret(cast('u32', $n == 64 ? node('__builtin_clzll', leaf('x')) : grp(node('__builtin_clzll', cast('u64', leaf('x'))), leaf('-', 64 - $n))))),
        node("__builtin_stdc_leading_ones $t:", leaf('u32'), @x, ret(call('leading_zeros', $n, $not))),
        node("__builtin_stdc_trailing_zeros $t:", leaf('u32'), @x,
            ret(cast('u32', node('__builtin_ctzll', $n == 64 ? leaf('x') : grp(leaf('x', '|', 'ULL', 2 ** $n)))))),
        node("__builtin_stdc_trailing_ones $t:", leaf('u32'), @x, ret(call('trailing_zeros', $n, $not))),
        node("__builtin_stdc_first_leading_one $t:", leaf('u32'), @x, iff($zero, ret(leaf(0))),
            ret(call('leading_zeros', $n, leaf('x')), leaf('+', 1))),
        node("__builtin_stdc_first_leading_zero $t:", leaf('u32'), @x, ret(call('first_leading_one', $n, $not))),
        node("__builtin_stdc_first_trailing_one $t:", leaf('u32'), @x, iff($zero, ret(leaf(0))),
            ret(call('trailing_zeros', $n, leaf('x')), leaf('+', 1))),
        node("__builtin_stdc_first_trailing_zero $t:", leaf('u32'), @x, ret(call('first_trailing_one', $n, $not))),
        node("__builtin_stdc_count_ones $t:", leaf('u32'), @x, ret(cast('u32', node('__builtin_popcountll', $n == 64 ? leaf('x') : cast('u64', leaf('x')))))),
        node("__builtin_stdc_count_zeros $t:", leaf('u32'), @x, ret(leaf($n, '-'), call('count_ones', $n, leaf('x')))),
        node("__builtin_stdc_has_single_bit $t:", leaf('int'), @x, ret(call('count_ones', $n, leaf('x')), leaf('==', 1))),
        node("__builtin_stdc_bit_width $t:", leaf('u32'), @x, ret(leaf($n, '-'), call('leading_zeros', $n, leaf('x')))),
        node("__builtin_stdc_bit_floor $t:", leaf($t), @x, iff($zero, ret(leaf(0))),
            ret(leaf('ULL', 1, '<<'), grp(call('bit_width', $n, leaf('x')), leaf('-', 1)))),
        node("__builtin_stdc_bit_ceil $t:", leaf($t), @x, iff(grp(leaf('x', '<=', 1)), ret(leaf(1))),
            iff(grp(call('bit_width', $n, grp(leaf('x', '-', 1))), leaf('==', $n)), ret(leaf(0))),
            ret(leaf('ULL', 1, '<<'), call('bit_width', $n, grp(leaf('x', '-', 1)))));
    # the rotations: by n modulo the width
    for my $r (['left', '<<', '>>'], ['right', '>>', '<<']) {
        my ($dir, $a, $b) = @$r;
        my $v = grp(grp(leaf('x', $a, 'n')), leaf('|'), grp(leaf('x', $b), grp(leaf($n, '-', 'n'))));
        push @fns, node("__builtin_stdc_rotate_$dir $t:", leaf($t), @x, param('n', 'u32'),
            leaf('n', '=', 'n', '%', $n), iff(grp(leaf('n', '==', 0)), ret(leaf('x'))),
            ret($n == 64 ? $v : ($v, leaf('&'), @m)));
    }
}
print write_txt(node('comment', node("C23's bit functions, gcc's type-generic __builtin_stdc_*, one for each width, written by mkstdbit.pl.")),
    node('stdbit:', ttp_license(), @fns));
