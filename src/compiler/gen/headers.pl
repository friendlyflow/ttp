#!/usr/bin/env perl
# headers.pl — the round trip of the license headers: each file's header,
# as ff2c.pl writes it back from a tree (/* ff2c: the header of <file> */
# and the header after it), is the header of that file in glibc's source
# (GLIBC_SRC), byte for byte; and every unit a written function comes
# from (names.txt) has the header of its file there. clang's AST has no
# comments, so roundtrip.pl cannot see them: this does.
#
#   perl headers.pl out.c names.txt
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use Header qw(header_of header_text leading_header real_path GENERATED NOHEADER NOHEADER_GCC);

die "usage: headers.pl out.c names.txt\n" unless @ARGV == 2;
my ($cfile, $names) = @ARGV;

sub slurp { my ($f) = @_; open my $h, '<:raw', $f or die "headers: cannot open $f: $!\n"; local $/; <$h> }

# the headers ff2c wrote, in its order
my (%got, $cur, $bad);
for my $l (split /\n/, slurp($cfile), -1) {
    if ($l =~ m{^/\* ff2c: the header of (.+) \*/$}) { $cur = $1; $got{$cur} = undef; next }
    if ($l eq '/* ff2c: the end of the headers */') { last }
    next unless defined $cur;
    $got{$cur} = defined $got{$cur} ? "$got{$cur}\n$l" : $l;
}

for my $f (sort keys %got) {
    my $text = $got{$f} // '';
    my $why;
    if ($text eq header_text(GENERATED)) {
        $why = "the line of a generated stub for a file" unless $f eq '<stdin>';
    } elsif ($text eq header_text(NOHEADER) || $text eq header_text(NOHEADER_GCC)) {
        $why = "it has a header, ff says none" if defined leading_header(slurp(real_path($f)));
    } else {
        my $want = leading_header(slurp(real_path($f)));
        $why = !defined $want ? "it has no header" : $want ne $text ? "its header is not what ff2c wrote" : undef;
    }
    next unless $why;
    print "headers: $f: $why\n";
    $bad = 1;
}

# every unit of a function or global written has its file's header
my (%unit, $n);
for (split /\n/, slurp($names)) {
    my @f = split /\t/;
    $unit{ $f[3] } = 1 if @f >= 4 && $f[0] eq 'body' && $f[3] =~ /\.i$/;
}
for my $u (sort keys %unit) {
    $n++;
    my $f = header_of($u)->{file};
    next if exists $got{$f};
    print "headers: $u: no header of $f in $cfile\n";
    $bad = 1;
}
exit 1 if $bad;
printf "headers: %d files' headers as glibc has them, for the %d units of the functions\n", scalar(keys %got), $n // 0;
