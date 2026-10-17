#!/usr/bin/env perl
# mki.pl — the .i of an object of the reference glibc: the command that
# compiled it (from build.log) run again with -E, in the source folder it ran
# in, its output next to the build in i/. That is the C exactly as glibc's
# build compiled it for this configuration; an object of a .S gets its .s,
# the asm exactly as glibc's build assembled it; so does a syscall stub
# glibc's build makes from a template, its source fed to gcc on stdin.
#
#   perl mki.pl <obj dir> <glibc source> string/strlen.o ...
#
# A host tool (core Perl only).
use strict;
use warnings;
use File::Path qw(make_path);
use File::Basename qw(dirname);

die "usage: mki.pl <obj dir> <glibc source> <object>...\n" unless @ARGV >= 3;
my ($obj, $src, @want) = @ARGV;

open my $log, '<', "$obj/build.log" or die "mki: cannot open $obj/build.log: $!\n";
my %cmd;
my @block;      # a command that feeds gcc its source: (echo ...; ...) | gcc ... -
while (my $l = <$log>) {
    if ($l =~ /^\(echo / || @block) {
        push @block, $l;
        next unless $l =~ /^\) \| /;
        $l = join '', @block;
        @block = ();
    }
    next unless $l =~ / -c / && $l =~ / -o (\S+\.o) /;
    my $o = $1;
    next unless $o =~ s/^\Q$obj\E\///;
    $cmd{$o} //= $l;
}
close $log;

my $bad = 0;
for my $o (@want) {
    my $c = $cmd{$o} or do { warn "mki: no command for $o in build.log\n"; $bad = 1; next };
    chomp $c;
    my $ext = $c =~ m{\.S\s| -x assembler-with-cpp } ? "s" : "i";
    (my $i = "$obj/../i/$o") =~ s/\.o$/.$ext/;
    make_path(dirname($i));
    $c =~ s/ -c / -E /;
    $c =~ s/ -o \S+\.o / -o $i /;
    $c =~ s/ -MD -MP -MF \S+ -MT \S+//;
    my $dir = "$src/" . dirname($o);
    if (system('sh', '-c', "cd '$dir' && $c") != 0) { warn "mki: $o: the compiler failed\n"; $bad = 1; next }
    print "$i\n";
}
exit $bad;
