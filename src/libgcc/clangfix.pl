#!/usr/bin/env perl
# clangfix.pl — a copy of a libgcc .i that clang reads, each change the same
# number of bytes (c2ff finds an asm statement's text in the .i itself by
# the offsets in clang's AST): gcc's modes of libgcc's own, word_mode on
# riscv64 (__libgcc_cmp_return__, __libgcc_shift_count__: DI), and HF and
# HC, which clang makes __fp16, no parameter type there: _Float16 and its
# complex, as gcc has them; BF, which clang has no mode of: __bf16.
#
#   perl clangfix.pl x.i > x.clang.i
#
# A host tool (core Perl only).
use strict;
use warnings;
my %mode = (__libgcc_cmp_return__ => '__DI__', __libgcc_shift_count__ => '__DI__');
sub pad { my ($old, $new) = @_; $new . ' ' x (length($old) - length($new)) }
while (<>) {
    s/mode \((__libgcc_\w+__)\)/'mode (' . pad($1, $mode{$1} \/\/ die "clangfix: no mode for $1\n") . ')'/ge;
    s/(float (\w+) __attribute__ \(\(mode \(HF\)\)\))/pad($1, "_Float16 $2")/ge;
    s/(float (\w+) __attribute__ \(\(mode \(BF\)\)\))/pad($1, "__bf16 $2")/ge;
    s/(_Complex float (\w+) __attribute__ \(\(mode \(HC\)\)\))/pad($1, "_Complex _Float16 $2")/ge;
    print;
}
