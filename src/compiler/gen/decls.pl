#!/usr/bin/env perl
# decls.pl — every name ttpc takes itself (the words of cc_kw, the operators
# of cc_ops, the types of cc_tynames in ttpc.ff) must be declared on the
# shared page (shared.ff.txt), as a function with its parameters, even when
# it does nothing (comment: ...:), so that an editor can offer a call of it.
#
#   perl decls.pl shared.ff.txt ttpc.ff
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(read_ff);

die "usage: decls.pl <shared.ff.txt> <ttpc.ff>\n" unless @ARGV == 2;
my ($txt, $ttpc) = @ARGV;

open my $h, "<", $txt or die "decls: cannot open $txt: $!\n";
my %decl;
while (<$h>) { chomp; $decl{$1} = 1 if /^(\S.*):$/ }
close $h;

open $h, "<:raw", $ttpc or die "decls: cannot open $ttpc: $!\n";
my $root = read_ff(do { local $/; <$h> });
close $h;

my $bad = 0;
for my $table (qw(cc_kw cc_ops cc_tynames)) {
    my ($node) = grep { $_->{content} eq "$table:" } @{ $root->{children} }
        or die "decls: no $table in $ttpc\n";
    my $bytes = join "", map { $_->{children}[0]{content} } @{ $node->{children} };
    my @words = grep { length } split /\0/, $bytes;
    my @missing = grep { !$decl{$_} } @words;
    print "decls: $table: not declared on the shared page: @missing\n" if @missing;
    $bad ||= @missing;
}
exit 1 if $bad;
print "decls: every word, operator and type ttpc takes is declared on the shared page\n";
