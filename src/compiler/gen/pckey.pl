#!/usr/bin/env perl
# pckey.pl — the key of a step that ports-check may take from its cache of
# results (pccache.sh): sha256 over a manifest of exactly the step's inputs,
# which a spec lists, one per line (the Makefile's pckey-<step>, written
# with $(file)):
#
#   R NAME DIR    a root: a path under DIR is written NAME/..., the longest
#                 root first (W the worktree, B the BUILD), so that worktrees
#                 and BUILDs of other names share their keys
#   f PATH        a file: its bytes (sha256)
#   d DIR         every file under DIR, in order, each as f
#   x CMD         a program as PATH finds it: one in /nix/store by its path
#                 (the store's hash stands for its bytes), any other by its
#                 bytes
#   e NAME        an environment variable's value, its roots written as above
#   t TEXT        a text (a make variable's value), its roots written as above
#   r FILE NAME T the lines of a Makefile between "#pccache< NAME" and
#                 "#pccache> NAME", continued lines joined, without comments,
#                 blank lines and the definitions of the other targets'
#                 variables than T's (X_aarch64 := ... when T is x86_64): a
#                 target's line is in that target's keys alone
#   o PATH        an output of the step, kept with its result and written
#                 again where a step is taken from the cache (asm-check's
#                 .asmok); not part of the key
#
#   perl pckey.pl key SPEC MANIFEST     prints the key, writes the manifest
#   perl pckey.pl save SPEC ENTRY       appends the outputs to ENTRY
#   perl pckey.pl restore SPEC ENTRY    writes the outputs ENTRY holds
#
# A missing input (a file, a region, a program) is an error, exit 1: the
# step then runs, never taken from the cache on a key that lacks it.
#
# A host tool, not part of ttpc.

use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
use File::Find ();

my ($mode, $spec, $out) = @ARGV;
my @targets = qw(riscv64 aarch64 x86_64 arm);
# (perl pckey.pl region FILE NAME TARGET: the text of a region as a key has it)
if (($mode // '') eq 'region' && @ARGV == 4) { print region(@ARGV[1 .. 3]), "\n"; exit 0 }
die "usage: pckey.pl key|save|restore SPEC FILE\n" unless defined $out && $mode =~ /^(key|save|restore)$/;

open my $sh, '<', $spec or die "pckey: $spec: $!\n";
# (make's foreach puts a space before each line but the first)
my @spec = map { chomp; s/^\s+//; length ? $_ : () } <$sh>;
close $sh;

my @roots = sort { length $b->[1] <=> length $a->[1] } map { /^R (\S+) (\S+)$/ ? [$1, $2 =~ s{/+$}{}r] : () } @spec;
sub label {
    my ($p) = @_;
    for (@roots) { my ($n, $d) = @$_; return "$n" . substr($p, length $d) if $p eq $d || index($p, "$d/") == 0 }
    $p;
}
sub text {
    my ($t) = @_;
    for (@roots) { my ($n, $d) = @$_; $t =~ s/\Q$d\E(?![A-Za-z0-9_.-])/$n/g }
    $t;
}
sub file_sha {
    my ($p) = @_;
    -f $p or die "pckey: $p: no such file\n";
    Digest::SHA->new(256)->addfile($p, 'b')->hexdigest;
}

my @outputs = map { /^o (.+)$/ ? $1 : () } @spec;

if ($mode eq 'save') {
    open my $e, '>>:raw', $out or die "pckey: $out: $!\n";
    for my $p (@outputs) {
        open my $h, '<:raw', $p or die "pckey: output $p: $!\n";
        local $/; my $b = <$h> // '';
        printf $e "== %s %d\n%s\n", label($p), length $b, $b;
    }
    exit 0;
}
if ($mode eq 'restore') {
    open my $e, '<:raw', $out or die "pckey: $out: $!\n";
    local $/; my $all = <$e>;
    my %kept;
    while ($all =~ /^== (\S+) (\d+)\n/mg) { my ($l, $n) = ($1, $2); $kept{$l} = substr($all, pos($all), $n); pos($all) += $n + 1 }
    for my $p (@outputs) { exists $kept{ label($p) } or die "pckey: the cache holds no " . label($p) . "\n" }
    for my $p (@outputs) {
        open my $h, '>:raw', "$p.pc$$" or die "pckey: $p: $!\n";
        print $h $kept{ label($p) }; close $h or die "pckey: $p: $!\n";
        rename "$p.pc$$", $p or die "pckey: $p: $!\n";
    }
    exit 0;
}

# a region of a Makefile, for target $t
sub region {
    my ($file, $name, $t) = @_;
    open my $h, '<', $file or die "pckey: $file: $!\n";
    my $all = do { local $/; <$h> };
    $all =~ s/\\\n/ /g;
    my ($in, $found, @l) = (0, 0);
    my $others = join '|', map { quotemeta } grep { $_ ne $t } @targets;
    for (split /\n/, $all) {
        if (/^#pccache< (\S+)\s*$/ && $1 eq $name) { die "pckey: $file: region $name twice\n" if $found; $in = $found = 1; next }
        if (/^#pccache> (\S+)\s*$/ && $1 eq $name) { $in = 0; next }
        next unless $in;
        next if /^\s*(#|$)/;
        next if /^\s*(?:override\s+|export\s+)?[A-Za-z0-9_.-]*_(?:$others)(?:_[A-Za-z0-9_.-]+)?\s*(?::{1,3}=|\+=|\?=|!=|=)/;
        push @l, $_;
    }
    die "pckey: $file: no region $name\n" unless $found;
    die "pckey: $file: region $name has no end\n" if $in;
    join "\n", @l;
}

my (@m, %seen);
for (@spec) {
    my ($k, $v) = /^(\S) (.*)$/ or die "pckey: $spec: what is this line: $_\n";
    if ($k eq 'R' || $k eq 'o') { next }
    if ($k eq 'f') { next if $seen{"f $v"}++; push @m, "f " . label($v) . " " . file_sha($v) }
    elsif ($k eq 'd') {
        -d $v or die "pckey: $v: no such folder\n";
        my @f;
        File::Find::find({ no_chdir => 1, wanted => sub { push @f, $_ if -f $_ } }, $v);
        for (sort @f) { next if $seen{"f $_"}++; push @m, "f " . label($_) . " " . file_sha($_) }
    }
    elsif ($k eq 'x') {
        next if $seen{"x $v"}++;
        my $p = $v =~ m{/} ? $v : (grep { -x "$_/$v" && -f "$_/$v" } split /:/, $ENV{PATH} // '')[0];
        die "pckey: $v: not on PATH\n" unless defined $p;
        $p = "$p/$v" unless $v =~ m{/};
        my $r = readlink_f($p);
        push @m, "x $v " . ($r =~ m{^/nix/store/} ? $r : label($r) . " " . file_sha($r));
    }
    elsif ($k eq 'e') { push @m, "e $v=" . text($ENV{$v} // '') }
    elsif ($k eq 't') { push @m, "t " . text($v) }
    elsif ($k eq 'r') {
        my ($file, $name, $t) = split / /, $v;
        defined $t or die "pckey: $spec: r FILE NAME TARGET: $v\n";
        push @m, "r " . label($file) . " $name $t " . sha256_hex(region($file, $name, $t));
    }
    else { die "pckey: $spec: what is this line: $_\n" }
}

sub readlink_f {
    my ($p) = @_;
    for (1 .. 40) {
        my $l = readlink $p;
        return $p unless defined $l;
        $p = $l =~ m{^/} ? $l : ($p =~ s{[^/]*$}{}r) . $l;
    }
    die "pckey: $p: links without end\n";
}

my $manifest = join("\n", @m) . "\n";
open my $mh, '>', $out or die "pckey: $out: $!\n";
print $mh $manifest;
close $mh;
print sha256_hex($manifest), "\n";
