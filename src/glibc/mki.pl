#!/usr/bin/env perl
# mki.pl — the .i of an object of the reference glibc: the command that
# compiled it (from build.log) run again with -E, in the source folder it ran
# in, its output next to the build in i/. That is the C exactly as glibc's
# build compiled it for this configuration; an object of a .S gets its .s,
# the asm exactly as glibc's build assembled it; so does a syscall stub
# glibc's build makes from a template, its source fed to gcc on stdin.
#
# soft-fp/X.o, which glibc's build does not make (binary128's arithmetic is
# libgcc's, the same soft-fp): the command of libm's soft-fp code with
# soft-fp/X.c, in libc, and without __SIZEOF_INT128__ and
# __BITINT_MAXWIDTH__: ttpc's C has no 128-bit integer, and glibc's u128 is
# then two words (math_uint128.h; gcc 16, aarch64's and x86_64's here, has
# _BitInt, which it takes before __int128).
# libm's soft-fp code is math/e_sqrtl.o on riscv64 and aarch64, where long
# double is binary128, and math/e_sqrtf128.o on x86_64 (_Float128).
#
# So for every object whose .i has glibc's u128 as unsigned __int128 or
# unsigned _BitInt(128) (math_uint128.h, in printf_fp and the mpn functions
# it calls): it is preprocessed again without both, and u128 is two words there
# too, the path glibc has for a target without a 128-bit integer.
#
#   perl mki.pl <obj dir> <glibc source> string/strlen.o ...
#
# A host tool (core Perl only).
use strict;
use warnings;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Cwd ();

die "usage: mki.pl <obj dir> <glibc source> <object>...\n" unless @ARGV >= 3;
my ($obj, $src, @want) = @ARGV;
# (the folder of the build, as given: its i/ is next to obj/, also where obj
# is a link to another build's, whose build.log names its own folder)
(my $build = $obj) =~ s{/+[^/]+/*$}{};
my $real = Cwd::abs_path($obj);

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
    if ($l =~ / -S(?:\s|$)/ && $l =~ / -o (?:\Q$obj\E|\Q$real\E)\/(\S+)-aux\.S /) { $gen{"$1.o"} //= $l; next }
    next unless $l =~ / -c / && $l =~ / -o (\S+\.o) /;
    my $o = $1;
    next unless $o =~ s/^\Q$obj\E\/// || $o =~ s/^\Q$real\E\///;
    $cmd{$o} //= $l;
}
close $log;

# the command of libm's soft-fp code: of e_sqrtl or e_sqrtf128, the one
# whose source includes soft-fp (x86_64's e_sqrtl is the x87's)
sub softfp_cmd {
    for my $o ("math/e_sqrtl.o", "math/e_sqrtf128.o") {
        my $c = $cmd{$o} or next;
        my ($f) = $c =~ m{ \.\./(sysdeps/\S+/e_sqrt(?:l|f128)\.c) } or next;
        open my $h, '<', "$src/$f" or next;
        local $/;
        return $c if <$h> =~ /soft-fp/;
    }
    undef;
}

my $bad = 0;
for my $o (@want) {
    my $c = $gen{$o} // $cmd{$o};
    if (!$c && $o =~ m{^soft-fp/(\w+)\.o$} && (my $t = softfp_cmd())) {
        my $f = $1;
        ($c = $t) =~ s{ \.\./sysdeps/\S+/e_sqrt(?:l|f128)\.c }{ ../soft-fp/$f.c } or die "mki: no e_sqrt source in its command\n";
        $c =~ s/ -DMODULE_NAME=libm / -DMODULE_NAME=libc / or die "mki: no MODULE_NAME in e_sqrt's command\n";
        $c =~ s/ -o / -U__SIZEOF_INT128__ -U__BITINT_MAXWIDTH__ -o /;
        # x86_64 (sqrtf128 is all glibc builds of soft-fp there): its
        # sfp-machine.h names the comparisons' type __gcc_CMPtype_GCC, the
        # mode __libgcc_cmp_return__ it says CMPtype must match, and
        # CMPtype libgcc's name for it, __gcc_CMPtype
        $c =~ s/ -o / -D__gcc_CMPtype=__gcc_CMPtype_GCC -o / if $t =~ m{/sysdeps/x86/fpu/e_sqrtf128\.c };
        $c =~ s{ -o \S+\.o }{ -o $obj/soft-fp/$f.o };
    }
    $c or do { warn "mki: no command for $o in build.log\n"; $bad = 1; next };
    chomp $c;
    my $ext = !$gen{$o} && $c =~ m{\.S\s| -x assembler-with-cpp } ? "s" : "i";
    (my $i = "$build/i/$o") =~ s/\.o$/.$ext/;
    make_path(dirname($i));
    $c =~ s/ -c / -E / or $c =~ s/ -S(\s|$)/ -E$1/;
    $c =~ s/ -o \S+\.(?:o|S) / -o $i /;

    $c =~ s/ -MD -MP -MF \S+ -MT \S+//;
    my $dir = "$src/" . ($o =~ m{^soft-fp/} ? "math" : dirname($o));
    if (system('sh', '-c', "cd '$dir' && $c") != 0) { warn "mki: $o: the compiler failed\n"; $bad = 1; next }
    if ($ext eq 'i' && $c !~ / -U__SIZEOF_INT128__ / && do { open my $h, '<', $i; local $/; <$h> =~ /^typedef unsigned (?:__int128|_BitInt\(128\)) u128;$/m }) {
        $c =~ s/ -o / -U__SIZEOF_INT128__ -U__BITINT_MAXWIDTH__ -o /;
        if (system('sh', '-c', "cd '$dir' && $c") != 0) { warn "mki: $o: the compiler failed\n"; $bad = 1; next }
    }
    print "$i\n";
}
exit $bad;
