#!/usr/bin/env perl
# licenses.pl — every tree has its license: a node license at its root, the
# SPDX expression first (a leaf), then the notice, a line per leaf (the
# user's form, 2026-10-19). The expression is ids of gen/spdx.txt joined by
# AND, OR, WITH (an exception after it) and parentheses. Every license in a
# tree, at any depth, has that form.
#
#   perl licenses.pl [--sidecar LICENSES] [--pages | --fragment] tree.ff|tree.ff.txt ...
#
# --sidecar names a file of `path SPDX` lines (paths from its folder) for the
# frozen files, which carry no license node: a tree it names needs none, and
# each of its ids must be known. --pages: each page of a tree made from
# source files (a child of its root, name:, holding code or a global, not
# only types or weak names; not an index) has a license of its own too, as
# c2ff and s2ff give it the header of each of its files. --fragment: a file
# of pages that join another tree (builtins.ff.txt), whose license is that
# tree's: it needs none at its root, its pages theirs (implies --pages).
# Exits 1 and names each tree that fails.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use File::Basename qw(dirname);
use File::Spec;
use FF qw(is_license kids read_ff read_txt);

my ($sidecar, $pages, $fragment);
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift;
    if ($o eq '--sidecar') { $sidecar = shift // die "licenses: --sidecar needs a file\n" }
    elsif ($o eq '--pages') { $pages = 1 }
    elsif ($o eq '--fragment') { $pages = $fragment = 1 }
    else { die "licenses: unknown option $o\n" }
}
die "usage: licenses.pl [--sidecar LICENSES] [--pages | --fragment] tree.ff|tree.ff.txt ...\n" unless @ARGV;

sub slurp { my ($f) = @_; open my $h, '<:raw', $f or die "licenses: cannot open $f: $!\n"; local $/; <$h> }

my (%id, %exception);
{
    my $ex = 0;
    for (split /\n/, slurp("$FindBin::Bin/spdx.txt")) {
        next if /^#/ || !/\S/;
        if ($_ eq 'exceptions:') { $ex = 1; next }
        ($ex ? $exception{$_} : $id{$_}) = 1;
    }
}

# An SPDX expression: what is wrong with it, or nothing.
sub spdx {
    my ($e) = @_;
    my @t = $e =~ /\(|\)|[^\s()]+/g;
    return "empty" unless @t;
    my $i = 0;
    my ($or, $and, $one);
    $one = sub {
        my $t = $t[$i++] // return "ends too early";
        if ($t eq '(') { my $w = $or->(); return $w if $w; return "no )" unless ($t[$i++] // '') eq ')'; return }
        return "unknown SPDX id $t" unless $id{ $t =~ s/\+$//r };
        if (($t[$i] // '') eq 'WITH') {
            $i++;
            my $x = $t[$i++] // return "WITH ends it";
            return "unknown SPDX exception $x" unless $exception{$x};
        }
        return;
    };
    $and = sub { my $w = $one->(); return $w if $w; while (($t[$i] // '') eq 'AND') { $i++; $w = $one->(); return $w if $w } return };
    $or = sub { my $w = $and->(); return $w if $w; while (($t[$i] // '') eq 'OR') { $i++; $w = $and->(); return $w if $w } return };
    my $w = $or->();
    return $w if $w;
    return "trailing $t[$i]" if $i < @t;
    return;
}

# What is wrong with a license node, or nothing.
sub form {
    my ($l) = @_;
    my @k = @{ $l->{children} };
    return "no notice after its SPDX expression" if @k < 2;
    return "its lines are leaves, a notice line has children: $_->{content}" for grep { @{ $_->{children} } } @k;
    my $w = spdx($k[0]{content});
    return "$w (in $k[0]{content})" if $w;
    return;
}

# A page made from source: one of its definitions (through its layers) is
# code or a global, not a type (struct, union, enum, function) or a weak name.
sub made {
    grep {
        my $c = $_->{children};
        $_->{content} =~ /:$/ && @$c && $c->[0]{content} !~ /^(?:struct|union|enum|function|weak)$/
    } kids($_[0]);
}

my (%frozen, $bad);
if ($sidecar) {
    my $dir = dirname($sidecar);
    for (split /\n/, slurp($sidecar)) {
        next if /^#/ || !/\S/;
        my ($path, $expr) = /^(\S+)\s+(.+?)\s*$/ or die "licenses: $sidecar: not `path SPDX`: $_\n";
        my $p = File::Spec->catfile($dir, $path);
        my $w = -e $p ? spdx($expr) : "no such file";
        if ($w) { print "licenses: $sidecar: $path: $w\n"; $bad = 1 }
        $frozen{ File::Spec->canonpath($p) } = $expr;
    }
}

my $n = 0;
for my $file (@ARGV) {
    next if exists $frozen{ File::Spec->canonpath($file) };
    my $bytes = slurp($file);
    my @roots = $file =~ /\.ff\.txt$/ ? read_txt($bytes, $file) : @{ read_ff($bytes)->{children} };
    my @why;
    my @l = grep { is_license($_) } @roots;
    push @why, "no license at its root" unless @l || $fragment;
    push @why, "two licenses at its root" if @l > 1;
    my $walk;
    $walk = sub {
        my ($node, $at) = @_;
        for (@{ $node->{children} }) {
            if (is_license($_)) { my $w = form($_); push @why, ($at eq "" ? "its license" : "the license in $at") . ": $w" if $w; next }
            $walk->($_, "$at/$_->{content}");
        }
    };
    $walk->({ children => \@roots }, '');
    if ($pages) {
        for my $p (grep { $_->{content} =~ /:$/ && $_->{content} ne 'index:' && made($_) } @roots) {
            push @why, "page $p->{content} has no license" unless grep { is_license($_) } kids($p);
        }
    }
    $n++;
    next unless @why;
    print "licenses: $file: $_\n" for @why;
    $bad = 1;
}
exit 1 if $bad;
print "licenses: $n trees and " . keys(%frozen) . " frozen files (" . ($sidecar // 'no sidecar') . ") have known licenses\n";
