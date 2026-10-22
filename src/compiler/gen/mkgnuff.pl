#!/usr/bin/env perl
# mkgnuff.pl — x86_64gnu.ff: the forms GNU as picks for x86_64
# (isa/x86_64gnu.pl), a definitions tree of their own, apart from the
# shared page that every compile reads: a build of x86_64 asm (glibc's,
# progs/x86_64/gnu.ff) gives it to ttpc after shared.ff. Its page, x86_64
# gnu:, holds the forms in layers (0: 1: ...); they call the encodings of
# the x86_64 section (its gnu encodings group), in scope when the target
# is x86_64. Its root has ttp's license first, as every tree.
#
#   perl gen/mkgnuff.pl > x86_64gnu.ff
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_ff layers ttp_license);

our (@X86_WIDE, @X86_GNU, @X86_GNU_DEFS);
my $section = do "$FindBin::Bin/../isa/x86_64.pl";
die "mkgnuff: $@" if $@;
die "mkgnuff: isa/x86_64.pl: $!\n" unless defined $section;
binmode STDOUT;
print write_ff(node("", ttp_license(), node("x86_64 gnu:",
    node("comment", node("x86_64gnu.ff: the forms GNU as picks for x86_64, one per encoding (isa/x86_64gnu.pl, the user's naming scheme), for glibc's asm (s2ff). Made by gen/mkgnuff.pl; ttpc reads it after shared.ff for x86_64 asm.")),
    layers(@X86_GNU_DEFS))));
