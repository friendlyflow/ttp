#!/usr/bin/env perl
# ffsplit.pl — a library tree (glibc in ff: a page per glibc directory) as a
# folder that a program includes lazily (`include` / folder): a file per page,
# and index.ff, which names the file of each definition. ttpc reads the
# index first, then a file only when a name it needs is in it (see
# language.ff.txt, include).
#
#   perl ffsplit.pl <library.ff.txt> <folder>
#
# A page goes into a file named after it, without the first word of the
# first page's name: glibc elf: is elf.ff, glibc types: types.ff, builtins:
# builtins.ff; a comment before a page goes with it. The tree's license (at its root) is at the root of each file. (Pages of one name, glibc elf and glibc elf 2 as c2ff once made
# them, are one page, in layers where it holds more than 255.)
#
# index.ff is one page, index:, of name: / file for each function, global,
# type, enum constant and asm entry of the pages (in layers too). A name two files
# define is the first file's, as it is in one tree.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node kids layers read_txt write_ff);

die "usage: ffsplit.pl <library.ff.txt> <folder>\n" unless @ARGV == 2;
my ($in, $dir) = @ARGV;
open my $h, '<:raw', $in or die "ffsplit: cannot open $in: $!\n";
my @top = read_txt(do { local $/; <$h> }, $in);
close $h;

# the pages by name, in order, each with the comments before it
my (@order, %page, @comments, @license);
for my $n (@top) {
    # (the tree's license, at its root: at the root of every file too)
    if ($n->{content} eq 'license') { push @license, $n; next }
    if ($n->{content} eq 'comment') { push @comments, $n; next }
    $n->{content} =~ /^(.+):$/ or die "ffsplit: not a page: $n->{content}\n";
    my $name = $1;
    $name = $1 if $name =~ /^(.*) \d+$/ && $page{$1};
    push @order, $name unless $page{$name};
    my $p = $page{$name} //= { comments => [], children => [] };
    push @{ $p->{comments} }, @comments;
    @comments = ();
    push @{ $p->{children} }, kids($n);   # (through its layers)
}
die "ffsplit: a comment after the last page\n" if @comments;

# the names a page defines: its functions, an enum's constants (in its
# items groups too), an asm function's entries
sub constants { map { $_->{content} eq 'items' ? constants($_) : $_->{content} =~ /^(.+):$/ ? $1 : () } @{ $_[0]{children} } }
# an asm function's entries: its labels, but the local ones (.L...)
sub entries { map { $_->{content} =~ /^([^.].*):$/ ? $1 : () } @{ $_[0]{children} } }
sub names {
    map {
        my $c = $_->{children};
        $_->{content} =~ /^(.+):$/ ? ($1, (@$c && $c->[0]{content} eq 'enum' ? constants($_) : ()),
            (@$c && $c->[0]{content} eq 'asm' ? entries($_) : ())) : ()
    } @_;
}

# the first word of the first page's name, which the files leave out (glibc
# string: is string.ff)
my ($prefix) = $order[0] =~ /^(\S+) /;
$prefix //= '';
mkdir $dir or die "ffsplit: cannot make $dir: $!\n" unless -d $dir;
my (%file, %of, @index);
for my $name (@order) {
    my $f = ($name =~ /^\Q$prefix\E (.+)$/ ? $1 : $name) . '.ff';
    $f =~ tr{/ }{__};
    die "ffsplit: two pages for $f\n" if $file{$f}++;
    die "ffsplit: index.ff is the index\n" if $f eq 'index.ff';
    my $p = $page{$name};
    open my $o, '>:raw', "$dir/$f" or die "ffsplit: cannot write $dir/$f: $!\n";
    print $o write_ff(node('', @license, @{ $p->{comments} }, node("$name:", layers(@{ $p->{children} }))));
    close $o or die "ffsplit: cannot write $dir/$f: $!\n";
    for my $n (names(@{ $p->{children} })) { next if $of{$n}; $of{$n} = $f; push @index, node("$n:", node($f)) }
}
open my $o, '>:raw', "$dir/index.ff" or die "ffsplit: cannot write $dir/index.ff: $!\n";
print $o write_ff(node('', @license, node('comment', node('the names the files of this folder define and the file of each: a program that includes the folder reads a file when a name it needs is in it')),
    node('index:', layers(@index))));
close $o or die "ffsplit: cannot write $dir/index.ff: $!\n";
printf STDERR "ffsplit: %d files, %d names\n", scalar(@order), scalar(@index);
