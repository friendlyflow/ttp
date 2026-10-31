#!/usr/bin/env perl
# clangfix.pl — a copy of a libgcc .i that clang reads, each change the same
# number of bytes (c2ff finds an asm statement's text in the .i itself by
# the offsets in clang's AST): gcc's modes of libgcc's own, word_mode on
# riscv64 (__libgcc_cmp_return__, __libgcc_shift_count__: DI; SI on arm), and HF and
# HC, which clang makes __fp16, no parameter type there: _Float16 and its
# complex, as gcc has them; BF, which clang has no mode of: __bf16.
# x86_64 (--target x86_64): the suffix F128 of a _Float128 literal as Q,
# which clang has; %v in an asm template (v under AVX, nothing here: c2ff
# drops it too) as spaces; gcc's rdssp builtins of no argument as clang's of
# one, the value it keeps where no shadow stack is. (Its long double is
# x87's, as gcc builds libgcc there and as ttpc has it.)
#
#   perl clangfix.pl [--target T] x.i > x.clang.i
#
# A host tool (core Perl only).
use strict;
use warnings;
my $target = @ARGV >= 2 && $ARGV[0] eq '--target' ? (splice @ARGV, 0, 2)[1] : 'riscv64';
# (word_mode: DI, but SI on 32-bit arm)
my $word = $target eq 'arm' ? '__SI__' : '__DI__';
my %mode = (__libgcc_cmp_return__ => $word, __libgcc_shift_count__ => $word);
sub pad { my ($old, $new) = @_; $new . ' ' x (length($old) - length($new)) }
while (<>) {
    s/mode \((__libgcc_\w+__)\)/'mode (' . pad($1, $mode{$1} \/\/ die "clangfix: no mode for $1\n") . ')'/ge;
    s/(float (\w+) __attribute__ \(\(mode \(HF\)\)\))/pad($1, "_Float16 $2")/ge;
    s/(float (\w+) __attribute__ \(\(mode \(BF\)\)\))/pad($1, "__bf16 $2")/ge;
    s/(_Complex float (\w+) __attribute__ \(\(mode \(HC\)\)\))/pad($1, "_Complex _Float16 $2")/ge;
    if ($target eq 'x86_64') {
        s/([0-9]\.?)[fF]128\b/$1Q   /g;
        s/%v/  /g if /__asm__/;
        s/__builtin_ia32_rdssp([dq]) \(\)/__builtin_ia32_rdssp$1(0)/g;
    }
    print;
}
