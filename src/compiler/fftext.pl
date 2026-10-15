#!/usr/bin/env perl
# fftext.pl — converts between an ff tree (.ff) and its text form (.ff.txt).
#
#   perl fftext.pl txt file.ff      > file.ff.txt
#   perl fftext.pl ff  file.ff.txt  > file.ff
#
# The text form is one node per line, indented two spaces per level, with
# the root's children at the left margin (see FF.pm). Both directions are
# lossless: ff -> txt -> ff gives the same bytes. As a git diff driver:
#
#   git config diff.ff.textconv "perl src/compiler/fftext.pl txt"
#   echo '*.ff diff=ff' >> .git/info/attributes

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node read_ff write_ff read_txt write_txt);

my ($to, $file) = @ARGV;
die "usage: fftext.pl txt|ff <file>\n" unless @ARGV == 2 && $to =~ /^(txt|ff)$/;
open my $in, "<:raw", $file or die "fftext: cannot open $file: $!\n";
my $bytes = do { local $/; <$in> };
binmode STDOUT;

if ($to eq "txt") {
    my $root = read_ff($bytes);
    die "fftext: the root of $file has content, the text form has no room for it\n"
        if $root->{content} ne "";
    print write_txt(@{ $root->{children} });
} else {
    print write_ff(node("", read_txt($bytes, $file)));
}
