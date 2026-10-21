#!/usr/bin/env perl
# newwords.pl — rewrites ff trees from the C words of before into the
# user's (2026-10-20, gen/Words.pm):
#
#   before                       now
#   address / x                  x, & address          C's &x
#   content / p                  p, * pointer          C's *p
#   address / char               char / * pointer      char *
#   address (alone)              void / * pointer      void *
#   array / int / 3              (array / int / 3)     int [3]
#   cast: / T / v, long / x      (cast / T), v         (T) v
#   u64 / 2, u32 / 7             ULL, 2  U, 7          2ULL 7U
#   address / char / hi          (cast / char / * pointer), hi   "hi"
#   point / 1                    point, 1, 0           (point){1}
#   padding 1: / u32 / 4         : / u32 / 4           unsigned : 4
#
# A tree in the new words already stays as it is (it has * pointer,
# & address or a cast node), so running it twice changes nothing. A lane
# with trees of its own runs it on them after merging (in src/compiler):
#
#   perl newwords.pl [-n] [-t lib.ff ...] [-T name ...] tree.ff|tree.ff.txt ...
#
# rewrites each tree in place and names the ones it changed; -n only names
# them. A leaf after address is a type if it is a C scalar or a struct,
# union, enum or function name of the tree, of a tree it includes, of a -t
# tree (a library it uses some other way) or a -T name; otherwise address
# alone was void *, which it says when that leaf is a name (a type of a
# library not given?).
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(read_ff write_ff read_txt write_txt);
use Words;

my ($dry, %types, @files);
# the shared page's types (the complex ones) are every tree's
{ my (undef, $s) = load("$FindBin::Bin/../shared.ff"); Words::typenames(\%types, @$s) }
# the trees a tree includes (include / file, beside it), and theirs
sub included {
    my ($f, $n, $seen) = @_;
    (my $dir = $f) =~ s{[^/]*$}{};
    my @t;
    for my $i (grep { $_->{content} eq 'include' } map { ($_, @{ $_->{children} }) } @$n) {
        for my $g (map { $dir . $_->{content} } @{ $i->{children} }) {
            next if $seen->{$g}++ || !-e $g;
            my (undef, $m) = eval { load($g) } or next;    # (one that does not read, no types)
            push @t, @$m, included($g, $m, $seen);
        }
    }
    @t;
}
sub load {
    my ($f) = @_;
    open my $h, '<:raw', $f or die "newwords: cannot open $f: $!\n";
    my $b = do { local $/; <$h> };
    # a fragment (a page's children, indented one level: glibc's builtins)
    return (frag => [read_txt("fragment\n$b", $f)], $b) if $f =~ /\.txt$/ && $b =~ /^  /;
    $f =~ /\.txt$/ ? (txt => [read_txt($b, $f)], $b) : (ff => [read_ff($b)], $b);
}
while (@ARGV) {
    my $a = shift;
    if ($a eq '-n') { $dry = 1 }
    elsif ($a eq "-T") { $types{word}{ shift // die "newwords: -T needs a name\n" } = 1 }
    elsif ($a eq '-t') {
        my $f = shift // die "newwords: -t needs a tree\n";
        my (undef, $n) = load($f);
        Words::typenames(\%types, @$n);
    }
    else { push @files, $a }
}
die "usage: newwords.pl [-n] [-t lib.ff ...] [-T name ...] tree.ff|tree.ff.txt ...\n" unless @files;
for my $f (@files) {
    local $Words::warn = sub { warn "newwords: $f: address $_[0]: void *, $_[0] not a type it knows\n" };
    my ($kind, $n, $b) = load($f);
    my $t = Words::newtypes(\%types);
    Words::typenames($t, included($f, $n, {}));
    my @new = Words::newwords($t, @$n);
    my $out = $kind eq 'txt' ? write_txt(@new) : $kind eq 'frag' ? write_txt(@new) =~ s/^fragment\n//r : write_ff($new[0]);
    next if $out eq $b;
    print "newwords: $f\n";
    next if $dry;
    open my $h, '>:raw', $f or die "newwords: cannot write $f: $!\n";
    print $h $out;
    close $h or die "newwords: $f: $!\n";
}
