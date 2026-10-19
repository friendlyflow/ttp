# Header.pm — the license header of a source file, for the host tools that
# turn glibc's sources into ff (c2ff.pl, s2ff.pl) and back (ff2c.pl), and
# for the check that the round trip keeps it (headers.pl).
#
# clang's AST has no comments, and the .i or .s mki.pl makes has none
# either, so the header is read from the source itself: the file the .i's
# first line marker names, in the folder its second one names (glibc's
# build runs in obj/<dir> on ../<path>). The header is the file's leading
# comment, the first /* ... */ block before any code. In ff it is
#
#   license
#     SPDX expression (from the header's words: spdx below)
#     the header, a line per child
#
# A header in glibc's own form (/* on its first line, three spaces before
# each other one, "  */" after its last word) is written without those
# marks, as text; any other is written as it is, its first line starting
# with /*. header_text gives the source's bytes back from either.
#
# A host tool (core Perl only), not part of ttpc.

package Header;

use strict;
use warnings;
use Exporter qw(import);
use FF ();
use File::Spec;

our @EXPORT_OK = qw(source_of leading_comment leading_header spdx notice_lines header_text header_of shown_path real_path GENERATED NOHEADER license_nodes);

# The source file of a .i or .s (its first two line markers), or nothing
# for a generated one (<stdin>: a system call from syscalls.list).
sub source_of {
    my ($file) = @_;
    open my $h, '<', $file or die "header: cannot open $file: $!\n";
    my $l1 = <$h> // '';
    my $l2 = <$h> // '';
    close $h;
    my ($src) = $l1 =~ /^# 0 "(.*)"$/ or return;
    return if $src =~ /^</;
    my ($cwd) = $l2 =~ /^# 1 "(.*?)\/*"$/;
    resolve($cwd, $src);
}

# The leading comment of C or asm source text: its first /* ... */ before
# any code, with what follows it on its last line; nothing if it has none.
sub leading_comment {
    my ($text) = @_;
    $text =~ m{\A\s*(/\*.*?\*/)}s ? $1 : undef;
}

# The SPDX expression of a header, from its words: of each of its comments
# that names a license, joined by AND (resolv's base64.c is ISC AND MIT),
# an exception's comment WITH the one before it (Bison's); nothing when one
# names a license not known here.
sub spdx {
    my ($h) = @_;
    my @ids;
    # (a comment that only says whose it is, granting nothing, names none)
    for my $b (grep { licensed($_) && /licen[cs]e|permission|permitted|redistribut|granted/i } $h =~ m{/\*.*?\*/}gs) {
        if ($b =~ /special exception/i && $b =~ /Bison parser skeleton/i && @ids) { $ids[-1] .= ' WITH Bison-exception-2.2'; next }
        my $id = spdx_one($b) // return;
        push @ids, $id unless grep { $_ eq $id } @ids;
    }
    @ids ? join(' AND ', @ids) : undef;
}

# The license one comment names.
sub spdx_one {
    my ($h) = @_;
    # (without the comment marks: /*, */ and the * that starts a line)
    (my $t = $h) =~ s{/\*|\*/}{ }g;
    $t =~ s/^[ \t]*\*+//mg;
    $t =~ s/\s+/ /g;
    my $later = $t =~ /(?:any later version|or later version|either version \S+ of the License, or)/i;
    my $lic;
    if ($t =~ /The Inner Net License, Version 2\.00/i) {
        $lic = 'Inner-Net-2.0';
    } elsif ($t =~ /GNU (?:Lesser|Library) General Public License/i) {
        my ($v) = $t =~ /(?:Lesser|Library) General Public License.{0,80}?version (\d(?:\.\d)?)/i;
        $v //= ($t =~ /Lesser/i ? '2.1' : '2');
        $v = "$v.0" unless $v =~ /\./;
        $lic = "LGPL-$v-" . ($later ? 'or-later' : 'only');
    } elsif ($t =~ /GNU General Public License/i) {
        my ($v) = $t =~ /General Public License.{0,80}?version (\d)/i;
        $v //= 2;
        $lic = "GPL-$v.0-" . ($later ? 'or-later' : 'only');
    } elsif ($t =~ /Developed at SunPro/i && $t =~ /freely granted, provided that this notice is preserved/i) {
        $lic = 'SunPro';
    } elsif ($t =~ /Permission to use, copy, modify, and(?:\/or)? distribute this software for any purpose with or without fee is hereby granted/i) {
        $lic = 'ISC';
    } elsif ($t =~ /Permission is hereby granted, free of charge, to any person obtaining a copy/i) {
        $lic = 'MIT';
    } elsif ($t =~ /Redistribution and use in source and binary forms/i) {
        my $n = () = $t =~ /(?:^| )\d\. /g;
        $lic = $t =~ /advertising materials/i ? 'BSD-4-Clause' : $n >= 3 || $t =~ /endorse or promote/i ? 'BSD-3-Clause' : 'BSD-2-Clause';
    }
    return unless $lic;
    return "$lic WITH GCC-exception-2.0" if $t =~ /unlimited permission to link the compiled version of this file/i;
    $lic;
}

# The lines a header is written as in ff: without its comment marks if it
# is in glibc's form, else as it is.
sub notice_lines {
    my ($h) = @_;
    my @l = split /\n/, $h, -1;
    if ($l[0] =~ m{^/\* (\S.*)$} && $l[-1] =~ /\S  \*\/$/) {
        my @c = @l;
        $c[0] =~ s{^/\* }{};
        $c[-1] =~ s{  \*/$}{};
        my $ok = 1;
        for my $i (1 .. $#c) { if ($c[$i] eq '') { next } elsif ($c[$i] =~ /^   (\S.*)$/) { $c[$i] = $1 } else { $ok = 0 } }
        $ok &&= !grep { /\*\// || /\s$/ } @c;
        if ($ok && header_text(@c) eq $h) { return @c }
    }
    @l;
}

# The header's text again, from its lines in ff.
sub header_text {
    my (@l) = @_;
    return join "\n", @l if $l[0] =~ m{^/\*};
    my @c = @l;
    $c[0] = "/* $c[0]";
    $_ = $_ eq '' ? '' : "   $_" for @c[1 .. $#c];
    $c[-1] .= "  */";
    join "\n", @c;
}

# The line a stub of syscalls.list has for a header, when no file of it has
# one (glibc's COPYING.LIB): the user's choice, 2026-10-19.
use constant GENERATED => 'generated from syscalls.list; glibc-2.44 COPYING.LIB';
# and a source that begins with code, no comment (glibc's stdlib/inlines.c)
use constant NOHEADER => 'no header of its own; glibc-2.44 COPYING.LIB';

# A path resolved against a folder, without its .. parts.
sub resolve {
    my ($cwd, $p) = @_;
    # (without a folder of its own, gcc -E of a program: where the tool runs)
    $p = defined $cwd ? "$cwd/$p" : File::Spec->rel2abs($p) unless $p =~ m{^/};
    1 while $p =~ s{/(?!\.\./)[^/]+/\.\./}{/};
    $p =~ s{//+}{/}g;
    $p;
}

# The files of C or asm a .i or .s is made of (its line markers), first
# the source itself, each once: no header (.h), nothing generated
# (<stdin>, <built-in>).
sub files_of {
    my ($file) = @_;
    open my $h, '<', $file or die "header: cannot open $file: $!\n";
    my $l1 = <$h> // '';
    my $l2 = <$h> // '';
    my ($cwd) = $l2 =~ /^# 1 "(.*?)\/*"$/;
    my (@f, %seen);
    for my $l ($l1, <$h>) {
        next unless $l =~ /^# \d+ "([^"<][^"]*\.[cS])"/;
        my $p = resolve($cwd, $1);
        push @f, $p unless $seen{$p}++;
    }
    close $h;
    @f;
}

# Words a header has where it names a license: one c2ff cannot name stops it.
sub licensed { $_[0] =~ /licen[cs]e|copyright|permission|redistribut/i }

# The header of source text: its leading comments, one after another (with
# what is between them), up to the first that names a license and those
# right after it that do too (Bison's exception); or its first comment alone
# when none does; nothing when it begins with code.
sub leading_header {
    my ($text) = @_;
    my ($first) = $text =~ m{\A(\s*)/\*}s or return;
    my $at = length $first;
    my ($end, $head, $lic);
    while (substr($text, $at) =~ m{\A(/\*.*?\*/)}s) {
        my $block = $1;
        $end = $at + length $block;
        $head //= $end;
        if (licensed($block)) { $lic = $end } elsif (defined $lic) { last }
        substr($text, $end) =~ m{\A(\s*)} ;
        my $ws = $1;
        last unless substr($text, $end + length $ws, 2) eq '/*';
        $at = $end + length $ws;
    }
    substr($text, length $first, ($lic // $head) - length $first);
}

# A file as a page names it: from glibc's source folder (GLIBC_SRC), else
# as it is (a file the build made, in obj/).
sub shown_path {
    my ($p) = @_;
    my $src = $ENV{GLIBC_SRC};
    return $p unless defined $src;
    $src =~ s{/+$}{};
    $p =~ m{^\Q$src\E/(.*)$} ? $1 : $p;
}
sub real_path {
    my ($p) = @_;
    return $p if $p =~ m{^/};
    defined $ENV{GLIBC_SRC} or die "header: GLIBC_SRC is not set: run this in `nix develop`\n";
    "$ENV{GLIBC_SRC}/$p";
}

sub slurp { my ($f) = @_; open my $h, '<:raw', $f or die "header: cannot open $f: $!\n"; local $/; <$h> }

# The license of what a .i or .s holds: { file => as a page names it,
# spdx => expression, lines => the header as ff lines }. The header of its
# source, else of the first file of C or asm it includes that has one (a
# wrapper's #include <stdlib/strtol.c>, a stub's syscall-template.S), else
# its source's own leading comment, under glibc's COPYING.LIB
# (LGPL-2.1-or-later), or NOHEADER where it has none (GENERATED for a
# stub). Dies on a header that names a license this does not know, and on a
# line ff cannot hold.
sub header_of {
    my ($ifile) = @_;
    my $src = source_of($ifile);
    my @files = files_of($ifile);
    my $first;
    for my $f (@files) {
        my $h = leading_header(slurp($f)) // next;
        my $x = spdx($h);
        if (!$x) {
            die "header: $f: its header names a license this cannot name (add it to spdx in gen/Header.pm)\n" if licensed($h);
            $first //= [$f, $h] if defined $src && $f eq $src;
            next;
        }
        return { file => shown_path($f), spdx => $x, lines => [lines_ok($f, notice_lines($h))] };
    }
    return { file => shown_path($first->[0]), spdx => 'LGPL-2.1-or-later', lines => [lines_ok($first->[0], notice_lines($first->[1]))] } if $first;
    return { file => '<stdin>', spdx => 'LGPL-2.1-or-later', lines => [GENERATED] } unless defined $src;
    { file => shown_path($src), spdx => 'LGPL-2.1-or-later', lines => [NOHEADER] };
}

sub lines_ok {
    my ($f, @l) = @_;
    for (@l) {
        die "header: $f: a line of " . length($_) . " bytes, more than a node holds (255)\n" if length > 255;
        my $t = $_;
        die "header: $f: a line that is not UTF-8\n" unless utf8::decode($t);
    }
    @l;
}

# The licenses of the files a page is made of (.i or .s each), as ff: for
# each file once, in the order of their names, a comment naming it, then its
# license (the user's choice, 2026-10-19).
sub license_nodes {
    my (@ifiles) = @_;
    my %h;
    for my $i (@ifiles) { my $x = header_of($i); $h{ $x->{file} } //= $x }
    map {
        my $x = $h{$_};
        (FF::node('comment', FF::node("glibc-2.44 $x->{file}")),
         FF::node('license', map { FF::node($_) } $x->{spdx}, @{ $x->{lines} }))
    } sort keys %h;
}

1;
