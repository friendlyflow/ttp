#!/usr/bin/env perl
# addlicense.pl — gives a tree its license: the license node of
# gen/license.ff.txt (ttp's, GPL-3.0-only), or of --from <file.ff.txt>,
# becomes the first child of the root of each tree that has none. A tree is
# a .ff file or its text, a .ff.txt file (the license goes on its first
# lines, the rest stays as it is). `make licenses` checks every tree.
#
#   perl addlicense.pl [--from license.ff.txt] tree.ff|tree.ff.txt ...
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(is_license read_ff write_ff read_txt);

my $from = "$FindBin::Bin/license.ff.txt";
if (@ARGV >= 2 && $ARGV[0] eq "--from") { $from = $ARGV[1]; splice @ARGV, 0, 2 }
die "usage: addlicense.pl [--from license.ff.txt] tree.ff|tree.ff.txt ...\n" unless @ARGV;

sub slurp { my ($f) = @_; open my $h, '<:raw', $f or die "addlicense: cannot open $f: $!\n"; local $/; <$h> }
sub spit { my ($f, $b) = @_; open my $h, '>:raw', $f or die "addlicense: cannot write $f: $!\n"; print $h $b; close $h or die "addlicense: $f: $!\n" }

my $text = slurp($from);
my @lic = read_txt($text, $from);
die "addlicense: $from holds no license / SPDX / notice\n" unless @lic == 1 && is_license($lic[0]);

for my $file (@ARGV) {
    my $bytes = slurp($file);
    if ($file =~ /\.ff\.txt$/) {
        if (grep { is_license($_) } read_txt($bytes, $file)) { print "addlicense: $file has one\n"; next }
        spit($file, $text . $bytes);
    } else {
        my $root = read_ff($bytes);
        if (grep { is_license($_) } @{ $root->{children} }) { print "addlicense: $file has one\n"; next }
        unshift @{ $root->{children} }, $lic[0];
        spit($file, write_ff($root));
    }
    print "addlicense: $file\n";
}
