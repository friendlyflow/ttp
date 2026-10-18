#!/usr/bin/env perl
# mki.pl — the .i of an object of the reference glibc: the command that
# compiled it (from build.log) run again with -E, in the source folder it ran
# in, its output next to the build in i/. That is the C exactly as glibc's
# build compiled it for this configuration; an object of a .S gets its .s,
# the asm exactly as glibc's build assembled it; so does a syscall stub
# glibc's build makes from a template, its source fed to gcc on stdin.
#
# soft-fp/X.o, which glibc's riscv64 build does not make (long double's
# arithmetic is libgcc's there, the same soft-fp): the command of libm's
# soft-fp code (math/e_sqrtl.o) with soft-fp/X.c, in libc, and without
# __SIZEOF_INT128__: ttpc's C has no 128-bit integer, and glibc's u128 is
# then two words (math_uint128.h).
#
# So for every object whose .i has glibc's u128 as unsigned __int128
# (math_uint128.h, in printf_fp and the mpn functions it calls): it is
# preprocessed again without __SIZEOF_INT128__, and u128 is two words there
# too, the path glibc has for a target without a 128-bit integer.
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
my %gen;       # objects whose asm gcc made from C: that command
my @block;      # a command over several lines (each but the last ending in \): (echo ...; ...) | gcc ... -
while (my $l = <$log>) {
    if ($l =~ /^\(echo / || @block) {
        push @block, $l;
        next if $l =~ /\\\s*$/;
        $l = join '', @block;
        @block = ();
    }
    # an object whose asm is gcc's -S of a C file (errlist-data.S includes
    # errlist-data-aux.S, from errlist-data-gen.c): that C is its source
    if ($l =~ / -S(?:\s|$)/ && $l =~ / -o \Q$obj\E\/(\S+)-aux\.S /) { $gen{"$1.o"} //= $l; next }
    next unless $l =~ / -c / && $l =~ / -o (\S+\.o) /;
    my $o = $1;
    next unless $o =~ s/^\Q$obj\E\///;
    $cmd{$o} //= $l;
}
close $log;

my $bad = 0;
for my $o (@want) {
    my $c = $gen{$o} // $cmd{$o};
    if (!$c && $o =~ m{^soft-fp/(\w+)\.o$} && (my $t = $cmd{"math/e_sqrtl.o"})) {
        my $f = $1;
        ($c = $t) =~ s{ \.\./sysdeps/riscv/e_sqrtl\.c }{ ../soft-fp/$f.c } or die "mki: no e_sqrtl.c in its command\n";
        $c =~ s/ -DMODULE_NAME=libm / -DMODULE_NAME=libc / or die "mki: no MODULE_NAME in e_sqrtl's command\n";
        $c =~ s/ -o / -U__SIZEOF_INT128__ -o /;
        $c =~ s{ -o \S+\.o }{ -o $obj/soft-fp/$f.o };
    }
    $c or do { warn "mki: no command for $o in build.log\n"; $bad = 1; next };
    chomp $c;
    my $ext = !$gen{$o} && $c =~ m{\.S\s| -x assembler-with-cpp } ? "s" : "i";
    (my $i = "$obj/../i/$o") =~ s/\.o$/.$ext/;
    make_path(dirname($i));
    $c =~ s/ -c / -E / or $c =~ s/ -S(\s|$)/ -E$1/;
    $c =~ s/ -o \S+\.(?:o|S) / -o $i /;

    $c =~ s/ -MD -MP -MF \S+ -MT \S+//;
    my $dir = "$src/" . ($o =~ m{^soft-fp/} ? "math" : dirname($o));
    if (system('sh', '-c', "cd '$dir' && $c") != 0) { warn "mki: $o: the compiler failed\n"; $bad = 1; next }
    if ($ext eq 'i' && $c !~ / -U__SIZEOF_INT128__ / && do { open my $h, '<', $i; local $/; <$h> =~ /^typedef unsigned __int128 u128;$/m }) {
        $c =~ s/ -o / -U__SIZEOF_INT128__ -o /;
        if (system('sh', '-c', "cd '$dir' && $c") != 0) { warn "mki: $o: the compiler failed\n"; $bad = 1; next }
    }
    print "$i\n";
}
exit $bad;
