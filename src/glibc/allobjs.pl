#!/usr/bin/env perl
# allobjs.pl — every object of the static libraries glibc installs, as the
# path of its object in the reference build without .o (string/strlen), each
# once, after the name of its library:
#
#   libc string/strlen
#   libm math/s_sin
#   crt csu/start
#
# libc.a is what the stamp.o of each of the build's folders lists (glibc's
# own list of libc.a's objects); the other libraries are their archive's
# members, from the archive's folder: libm.a (math), libmvec.a (mathvec,
# on the targets that have it: x86_64, aarch64), libresolv.a (resolv),
# libBrokenLocale.a (locale), libmcheck.a (a link to malloc/mcheck-init.o);
# libg.a's one member is the build's dummy.o (an empty function, at the top
# of the build). libutil.a, libanl.a, libpthread.a, librt.a and libdl.a
# have no members (their functions are libc's since glibc 2.34).
# crt is crt1.o's parts (start.o abi-note.o init.o static-reloc.o, as the
# build links them with ld -r, on every target) and crti.o and crtn.o. libc_nonshared.a and
# the crt1 of a PIE or of profiling (Scrt1.o rcrt1.o gcrt1.o grcrt1.o
# Mcrt1.o, of .os objects) are for a dynamic or a profiled program: not
# here.
#
#   perl allobjs.pl <obj dir> [library ...]
#
# A host tool (core Perl only).
use strict;
use warnings;
use File::Find ();
use Digest::SHA;

my ($obj, @only) = @ARGV;
defined $obj or die "usage: allobjs.pl <obj dir> [library ...]\n";
my %only = map { $_ => 1 } @only;
my %seen;
sub out { my ($lib, $o) = @_; $o =~ s/\.o$//; print "$lib $o\n" unless $seen{$o}++ || (%only && !$only{$lib}) }

for my $stamp (sort glob "$obj/*/stamp.o") {
    open my $h, '<', $stamp or die "allobjs: cannot open $stamp: $!\n";
    out('libc', $_) for split ' ', do { local $/; <$h> };
}
# The objects of the build by name, for the members an archive names
# without their folder (found only where one is not in the archive's own
# folder by that name, or the archive has two of the name: aarch64's
# libmvec.a has mathvec/advsimd/acosf.o and mathvec/sve/acosf.o), not the
# dynamic loader's own copies (rtld-*).
my %byname;
sub byname {
    unless (%byname) {
        File::Find::find({ no_chdir => 1, follow => 1, wanted => sub {
            return unless /\.o$/ && -f $_;
            (my $rel = $File::Find::name) =~ s{^\Q$obj\E/}{};
            return if $rel =~ m{(?:^|/)rtld-};
            push @{ $byname{ (split m{/}, $rel)[-1] } }, $rel;
        } }, $obj);
    }
    @{ $byname{ $_[0] } // [] };
}
sub sha_file { my ($f) = @_; open my $h, '<:raw', $f or die "allobjs: $f: $!\n"; Digest::SHA->new(1)->addfile($h)->hexdigest }
# An archive's members, in order: [name, bytes] (the ar format: a 60-byte
# header before each, GNU's long names in the member //)
sub members {
    my ($a) = @_;
    open my $h, '<:raw', $a or die "allobjs: cannot open $a: $!\n";
    my $data = do { local $/; <$h> };
    substr($data, 0, 8) eq "!<arch>\n" or die "allobjs: $a: not an archive\n";
    my ($at, $long, @m) = (8, '');
    while ($at + 60 <= length $data) {
        my ($name, $size) = (substr($data, $at, 16), substr($data, $at + 48, 10));
        $size =~ s/\s+$//;
        my $body = substr($data, $at + 60, $size);
        $at += 60 + $size + ($size % 2);
        $name =~ s/\s+$//;
        if ($name eq '//') { $long = $body; next }
        next if $name eq '/' || $name eq '/SYM64/';
        $name = $1 if $name =~ m{^/(\d+)$} && substr($long, $1) =~ m{^([^\n]*?)/?\n};
        $name =~ s{/$}{};
        push @m, [$name, $body];
    }
    @m;
}
my $bad = 0;
for (['libm', 'math/libm.a'], ['libmvec', 'mathvec/libmvec.a'], ['libresolv', 'resolv/libresolv.a'],
     ['libBrokenLocale', 'locale/libBrokenLocale.a'], ['libg', 'misc/libg.a']) {
    my ($lib, $a) = @$_;
    next if $lib eq 'libmvec' && !-e "$obj/$a";
    (my $dir = $a) =~ s{/.*}{};
    my @m = members("$obj/$a");
    my %count;
    $count{ $_->[0] }++ for @m;
    for (@m) {
        my ($m, $bytes) = @$_;
        # (libg.a's one member, dummy.o, is the build's own, at its top)
        if ($lib eq 'libg') { out($lib, $m); next }
        if ($count{$m} == 1 && -f "$obj/$dir/$m") { out($lib, "$dir/$m"); next }
        # where the archive has two of a name: the object of the member's bytes
        my $want = Digest::SHA::sha1_hex($bytes);
        my @c = grep { sha_file("$obj/$_") eq $want } byname($m);
        if (@c != 1) { warn "allobjs: $lib: $m: " . (@c ? "several objects: @c" : "no object of its bytes") . "\n"; $bad = 1; next }
        out($lib, $c[0]);
    }
}
out('libmcheck', 'malloc/mcheck-init.o');
out('crt', "csu/$_.o") for qw(start abi-note init static-reloc crti crtn);
exit $bad;
