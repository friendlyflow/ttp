#!/usr/bin/env perl
# linkobjs.pl — the objects of glibc a program's gcc build links (the
# members of libc.a its link map lists, ld -Map), as the make variables of
# a milestone: its C objects and its asm objects, each the path of its
# object in the reference build without .o (allobjs.pl's names), C or asm
# as mki.pl --dry says.
#
#   perl linkobjs.pl <name> <link map> <obj dir> <glibc source> > name.objs.mk
#
# gives OBJS_link_<name> := ... and ASMS_link_<name> := .... What gcc's
# static program has is what glibc in ff must have for it: the same
# members, of which c2ff then translates what the program reaches.
#
# A host tool (core Perl only).
use strict;
use warnings;
use FindBin;

die "usage: linkobjs.pl <name> <link map> <obj dir> <glibc source>\n" unless @ARGV == 4;
my ($name, $map, $obj, $src) = @ARGV;

# the members: libc.a(x.o) in the map's list of archive members included
my %member;
open my $m, '<', $map or die "linkobjs: cannot open $map: $!\n";
while (<$m>) {
    last if /^(Discarded input sections|Memory Configuration)/;
    $member{$1} = 1 while /\blibc\.a\(([^)]+\.o)\)/g;
}
close $m;

# a member by its name: its path (allobjs.pl's list)
my %path;
open my $a, '-|', 'perl', "$FindBin::Bin/allobjs.pl", $obj, 'libc' or die "linkobjs: allobjs.pl: $!\n";
while (<$a>) {
    my (undef, $p) = split ' ';
    (my $b = $p) =~ s{^.*/}{};
    $path{"$b.o"} //= $p;
}
close $a or die "linkobjs: allobjs.pl failed\n";
my @objs = map { $path{$_} // die "linkobjs: $_ is no object of libc.a\n" } sort keys %member;

# C or asm, as mki.pl would make it
my (@c, @s);
open my $d, '-|', 'perl', "$FindBin::Bin/mki.pl", '--dry', $obj, $src, map { "$_.o" } @objs or die "linkobjs: mki.pl: $!\n";
while (<$d>) {
    chomp;
    if (m{/i/(.+)\.i$}) { push @c, $1 } elsif (m{/i/(.+)\.s$}) { push @s, $1 } else { die "linkobjs: mki.pl --dry: $_\n" }
}
close $d or die "linkobjs: mki.pl --dry failed\n";
print "OBJS_link_$name := @c\nASMS_link_$name := @s\n";
