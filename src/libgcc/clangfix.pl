#!/usr/bin/env perl
# clangfix.pl — a copy of a libgcc .i that clang reads, each change the same
# number of bytes (c2ff finds an asm statement's text in the .i itself by
# the offsets in clang's AST): gcc's modes of libgcc's own, word_mode on
# riscv64 (__libgcc_cmp_return__, __libgcc_shift_count__: DI; SI on arm), and HF and
# HC, which clang makes __fp16, no parameter type there: _Float16 and its
# complex, as gcc has them; BF, which clang has no mode of: __bf16.
# arm (--target arm): __sync_ names as __Sync_ (linux-atomic.c's own);
# libgcc2.c's functions of pcs ("aapcs") declared with it first.
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
my @lines = <>;
# (arm's libgcc2.c gives AEABI's four functions pcs ("aapcs") after
# libgcc2.h declared them without it, which clang refuses: their plain
# declarations as spaces, and each one's own declaration before the
# typeof of it that makes its AEABI alias)
my %pcs;
if ($target eq 'arm') { for (@lines) { $pcs{$1} = 1 while /\b(\w+) \([^()]*\)(?: __asm__\("\w+"\))? __attribute__\(\(pcs\("aapcs"\)\)\)/g } }
# (arm's fixed-bit.c: its modes of _Fract as clang's types, with -ffixed-point;
# clang has no 64-bit _Fract, the mode DQ, which only moves through memcpy in
# these functions: long long there, its ABI (a pair), and no word of ff's. All
# before its first typedef is blanked, keeping the offsets: its headers make
# a thousand ASTs of megabytes.)
my %fixed = (QQ => 'short _Fract', UQQ => 'unsigned short _Fract', HQ => '_Fract', UHQ => 'unsigned _Fract',
    SQ => 'long _Fract', USQ => 'unsigned long _Fract', DQ => 'long long', UDQ => 'unsigned long long',
    HA => 'short _Accum', UHA => 'unsigned short _Accum', SA => '_Accum', USA => 'unsigned _Accum',
    DA => 'long _Accum', UDA => 'unsigned long _Accum');
if (grep { /^typedef _Fract QQtype / } @lines) {
    my ($first) = grep { $lines[$_] =~ /^typedef int QItype / } 0 .. $#lines;
    defined $first or die "clangfix: fixed-bit.c: no QItype\n";
    for my $i (0 .. $first - 1) { $lines[$i] =~ s/[^\n]/ /g }
    # (what it declares from before: in the blank room)
    my $decl = 'void *memcpy (void *, const void *, unsigned int);';
    my $room = 0;
    for my $i (0 .. $first - 1) { next if length($lines[$i]) <= length($decl); substr($lines[$i], 0, length $decl) = $decl; $room = 1; last }
    $room or die "clangfix: fixed-bit.c: no room\n";
    for my $i ($first .. $#lines) { $lines[$i] =~ s/[^\n]/ /g if $lines[$i] =~ /^#/ }
    # (an unsigned mode's INTunion has unsigned members, another type than a
    # signed mode's of the same name, which c2ff takes for one: its own name,
    # of the same length)
    if (grep { /^  UDItype ll;/ } @lines) { for (@lines) { s/\bINTunion\b/INTunioU/g; s/\bINTstruct\b/INTstrucU/g } }
    for (@lines) {
        s/^(typedef (?:unsigned )?_Fract (\w+)type __attribute__ \(\(mode \(\w+\)\)\);)/pad($1, "typedef $fixed{$2} $2type;")/e;
    }
}
for (@lines) {
    if (%pcs) {
        s/^(extern \w+ (\w+) \(\w+\);)/$pcs{$2} ? ' ' x length($1) : $1/e;
        s/(typeof \((\w+)\) \w+ __attribute__\(\(alias \([^()]*\)\)\);) (extern \w+ \2 \(\w+\) __attribute__\(\(pcs\("aapcs"\)\)\);)/$3 $1/;
    }
    s/mode \((__libgcc_\w+__)\)/'mode (' . pad($1, $mode{$1} \/\/ die "clangfix: no mode for $1\n") . ')'/ge;
    s/(float (\w+) __attribute__ \(\(mode \(HF\)\)\))/pad($1, "_Float16 $2")/ge;
    s/(float (\w+) __attribute__ \(\(mode \(BF\)\)\))/pad($1, "__bf16 $2")/ge;
    s/(_Complex float (\w+) __attribute__ \(\(mode \(HC\)\)\))/pad($1, "_Complex _Float16 $2")/ge;
    # (arm's linux-atomic.c defines the __sync functions, which clang has
    # as builtins: __Sync_ here, its AST's names __sync_ again, Makefile)
    s/\b__sync_/__Sync_/g if $target eq 'arm';
    if ($target eq 'x86_64') {
        s/([0-9]\.?)[fF]128\b/$1Q   /g;
        s/%v/  /g if /__asm__/;
        s/__builtin_ia32_rdssp([dq]) \(\)/__builtin_ia32_rdssp$1(0)/g;
    }
    print;
}
