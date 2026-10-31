#!/usr/bin/env perl
# mki.pl — the .i of an object of the reference libgcc (src/libgcc): the
# command that compiled it (from the libgcc build's build.log) run again
# with -E, in the folder it ran in, its output in i/libgcc/ of the build. That
# is the C exactly as gcc's own libgcc.a and libgcc_eh.a were compiled for
# this configuration; an object of a .S gets its .s, the asm as it was
# assembled. src/glibc/mki.pl does the same for glibc, whose build runs in
# the source's folders.
#
#   perl mki.pl <libgcc build dir> <out dir> _muldc3.o unwind-dw2.o ...
#   perl mki.pl --dry <libgcc build dir> <out dir> _muldc3.o ...
#
# --dry only prints the file each object would get (its .i or .s).
#
# A host tool (core Perl only).
use strict;
use warnings;
use File::Path qw(make_path);

my $dry = @ARGV && $ARGV[0] eq '--dry' ? shift @ARGV : undef;
die "usage: mki.pl [--dry] <libgcc build dir> <out dir> <object>...\n" unless @ARGV >= 3;
my ($dir, $out, @want) = @ARGV;

# each command once, its continued lines (\ at the end) joined
open my $log, '<', "$dir/build.log" or die "mki: cannot open $dir/build.log: $!\n";
my $all = do { local $/; <$log> };
close $log;
$all =~ s/\\\n/ /g;
my %cmd;
for my $l (split /\n/, $all) {
    next unless $l =~ / -c / && $l =~ / -o (\S+\.o) /;
    $cmd{$1} //= $l;
}

my $bad = 0;
for my $o (@want) {
    my $c = $cmd{$o} or do { warn "mki: no command for $o in $dir/build.log\n"; $bad = 1; next };
    # (an asm source: -xassembler-with-cpp, or a .S that gcc knows by its
    # name, aarch64's lse.S)
    my $ext = $c =~ / -xassembler-with-cpp / || $c =~ / -c \S+\.S\b/ ? 's' : 'i';
    (my $i = "$out/$o") =~ s/\.o$/.$ext/;
    if ($dry) { print "$i\n"; next }
    make_path($out);
    $c =~ s/ -c / -E / or die "mki: $o: no -c in its command\n";
    $c =~ s/ -o \S+\.o / -o $i /;
    $c =~ s/ -MT \S+ -MD -MP -MF \S+//;
    # build.log names the compiler and the C library's headers by their
    # store paths (BUILD/gcroots keeps them): one that is gone cannot run
    my @gone = grep { !-e $_ } $c =~ m{(/nix/store/[a-z0-9]{32}-[^/\s'"]+)}g;
    die "mki: $o: build.log's command names " . join(', ', @gone) . ", gone (nix gc): make libgcc-ref again, into a new BUILD\n" if @gone;
    if (system('sh', '-c', "cd '$dir' && $c") != 0) { warn "mki: $o: the compiler failed\n"; $bad = 1; next }
    print "$i\n";
}
exit $bad;
