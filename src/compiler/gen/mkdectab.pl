#!/usr/bin/env perl
# mkdectab.pl — the decoding tables of a target's asm for s2ff (tools/s2ff.ff),
# from the Perl of its forms: what isa/<target>.pl fills for the host tools
# and leaves out of the shared page (ttpc does not need it).
#
#   perl gen/mkdectab.pl arm      > isa/arm.dec.ff.txt      @ARM::WIDE (armdec.pm's)
#   perl gen/mkdectab.pl x86_64   > isa/x86_64.dec.ff.txt   @X86_GNU, @X86_WIDE (s2ffx86.pm's)
#
# make refresh writes them (and their .ff, fftext); refresh-check proves
# the committed ones are what this makes. Each is a tree with ttp's license:
#
#   arm decode:     each instruction, in isa/arm.pl's order:
#                     name / mode (a t t2) / its GNU form / params / its
#                     parameters / signed / those its test values take below
#                     0 / fields / its fields, MSB first
#   x86_64 forms:   each form, @X86_GNU's then @X86_WIDE's:
#                     name / its GNU line / params / name:kind each
#
# in layers (0: 1: ...) past 255.
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
no warnings "once";    # (@ARM::WIDE, filled by isa/arm.pl)
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt layers ttp_license);

my $target = shift // die "usage: mkdectab.pl arm | x86_64\n";
my @items;
my $top;
if ($target eq 'arm') {
    local @INC = ($FindBin::Bin, @INC);
    do "$FindBin::Bin/../isa/arm.pl" or die "mkdectab: isa/arm.pl: " . ($@ || $!) . "\n";
    for my $e (@ARM::WIDE) {
        my ($name, $mode, $gnu, $params, $test, $fields) = @$e;
        my @signed = grep { my $t = $test && $test->{$_}; $t && grep { $_ < 0 } @$t } @$params;
        push @items, node($name, node($mode), node($gnu), node('params', map { node($_) } @$params),
            node('signed', map { node($_) } @signed), node('fields', map { node($_) } @$fields));
    }
    $top = 'arm decode:';
} elsif ($target eq 'x86_64') {
    our (@X86_WIDE, @X86_GNU, @X86_GNU_DEFS);
    my $section = do "$FindBin::Bin/../isa/x86_64.pl";
    die "mkdectab: $@" if $@;
    die "mkdectab: isa/x86_64.pl: $!\n" unless defined $section;
    for my $f (@X86_GNU, @X86_WIDE) {
        my ($name, $params, $gnu) = @$f;
        push @items, node($name, node($gnu), node('params', map { node($_) } @$params));
    }
    $top = 'x86_64 forms:';
} else { die "mkdectab: no tables of $target\n" }
print write_txt(ttp_license(), node($top,
    node('comment', node("isa/$target.dec.ff: the decoding tables of $target asm for s2ff (tools/s2ff.ff), from isa/$target.pl; made by gen/mkdectab.pl (make refresh)")),
    layers(@items)));
