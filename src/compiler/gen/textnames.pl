#!/usr/bin/env perl
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# textnames.pl [-k KNOWN] [-g] TREE.ff... : the text items of byte arrays in
# globals' initializers (a global of char, i8 or u8 elements, a struct's
# field of them, an array's element: their leaves, after the type run) that
# are also a name the trees define: a function, a global or an enum
# constant. ttpc reads such a leaf as text whatever it names (textname.pl;
# before it, the name won: glibc nss's nss_function_name_array "getpwnam_r"
# was getpwnam_r's address), and csema writes an enum constant that is a
# byte's item as its number (nss's per_database_defaults), so a leaf there
# that names an enum constant is either a text (gaih_inet_typeproto's
# "raw") or a constant some tool wrote as its name: each one is judged.
#
# The trees are one program, or one library of pages, whose names see each
# other; -g: each tree on its own. Prints each one found, "GLOBAL[.FIELD]
# TEXT KIND" (KIND fn, global or enum); with -k, KNOWN's lines (the same
# three words, then why: # lines and blank ones skipped) are those judged,
# and the exit status is 1 where one is found that KNOWN has not.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(read_ff);

my ($known, $each);
while (@ARGV && $ARGV[0] =~ /^-/) {
    my $o = shift;
    if ($o eq '-k') { $known = shift }
    elsif ($o eq '-g') { $each = 1 }
    else { die "usage: textnames.pl [-k KNOWN] [-g] TREE.ff...\n" }
}
die "usage: textnames.pl [-k KNOWN] [-g] TREE.ff...\n" unless @ARGV;

my %skip = map { $_ => 1 } qw(comment line license);
my %kw = map { $_ => 1 } qw(struct union enum);
my $num = qr/^-?(?:0x[0-9a-fA-F.]+(?:p[-+]?\d+)?[a-zA-Z]*|[0-9][0-9.]*(?:[eE][-+]?\d+)?[a-zA-Z]*)$/;

sub c { $_[0]{content} }
sub ch { @{ $_[0]{children} } }
sub nonskip { grep { !$skip{ c($_) } } @_ }
# a type run: its first node, then the * pointer nodes after it
sub typerun {
    my @n = @_;
    return ([], []) unless @n;
    my $i = 1;
    $i++ while $i < @n && c($n[$i]) eq '* pointer';
    ([@n[0 .. $i - 1]], [@n[$i .. $#n]]);
}

my (%defs, %types, %enumc, @globals);
sub is_group {
    my ($n) = @_;
    my @k = nonskip(ch($n));
    return 0 unless @k;
    return 0 if $kw{ c($k[0]) } || c($k[0]) eq 'align';
    for (@k) { return 0 unless c($_) =~ /:$/ }
    return scalar grep { ch($_) } @k;
}
sub scan {
    my ($n, $file) = @_;
    for my $k (ch($n)) {
        my $name = c($k);
        next unless $name =~ /^(.+):$/;
        $name = $1;
        if ($name =~ /^[0-9]+$/ || is_group($k)) { scan($k, $file); next }
        my @c = nonskip(ch($k));
        if (@c && ($kw{ c($c[0]) } || (c($c[0]) eq 'align' && @c > 1 && $kw{ c($c[1]) }))) {
            my $kind = $kw{ c($c[0]) } ? c($c[0]) : c($c[1]);
            my @fields;
            for my $fd (@c[($kw{ c($c[0]) } ? 1 : 2) .. $#c]) {
                next unless c($fd) =~ /^(.+):$/;
                my $f = $1;
                if ($kind eq 'enum') { $enumc{$f} = 1 }
                else { push @fields, [$f, (typerun(grep { c($_) ne 'align' } ch($fd)))[0]] }
            }
            $types{$name} = [$kind, \@fields];
            $defs{$name} //= 'type';
            next;
        }
        my (undef, $rest) = typerun(@c);
        if (grep({ c($_) eq 'line' || c($_) eq 'return' } ch($k)) || grep({ c($_) =~ /^.+:$/ } @$rest)) {
            $defs{$name} = 'fn';
        } else {
            $defs{$name} = 'global';
            push @globals, [$name, $k];
        }
    }
}

my @found;
sub bytetype { my ($t) = @_; @$t == 1 && c($t->[0]) =~ /^(?:char|i8|u8)$/ && !ch($t->[0]) }
sub aggregate { my ($t) = @_; @$t && (c($t->[0]) eq 'array' || (@$t == 1 && $types{ c($t->[0]) } && $types{ c($t->[0]) }[0] ne 'enum')) }
sub init {
    my ($tr, $items, $where) = @_;
    return if !@$tr || @$tr > 1;
    my $t = $tr->[0];
    if (c($t) eq 'array' && ch($t)) {
        my ($et) = typerun(ch($t));
        if (bytetype($et)) {
            for my $it (@$items) {
                my $s = c($it);
                next if ch($it) || $s eq '' || $s =~ $num;
                if ($enumc{$s}) { push @found, "$where $s enum" }
                elsif ($defs{$s} && $defs{$s} ne 'type') { push @found, "$where $s $defs{$s}" }
            }
            return;
        }
        if (aggregate($et)) { init($et, [ch($_)], $where) for grep { c($_) eq ':' } @$items }
        return;
    }
    my $ty = $types{ c($t) } or return;
    my ($kind, $fields) = @$ty;
    return if $kind eq 'enum';
    my @f = $kind eq 'union' ? ($fields->[0] // ()) : @$fields;
    for my $i (0 .. $#f) {
        last if $i > $#$items;
        my ($fname, $ftr) = @{ $f[$i] };
        init($ftr, [ch($items->[$i])], "$where.$fname") if aggregate($ftr) && c($items->[$i]) eq ':';
    }
}
sub run {
    %defs = %types = %enumc = (); @globals = ();
    for my $file (@_) {
        open my $fh, '<:raw', $file or die "textnames.pl: $file: $!\n";
        my $bytes = do { local $/; <$fh> };
        scan(read_ff($bytes), $file);
    }
    for my $g (@globals) {
        my ($tr, $items) = typerun(nonskip(ch($g->[1])));
        init($tr, $items, $g->[0]);
    }
}
if ($each) { run($_) for @ARGV } else { run(@ARGV) }

my %judged;
if ($known) {
    open my $k, '<', $known or die "textnames.pl: $known: $!\n";
    while (<$k>) {
        next if /^\s*(#|$)/;
        my @w = split ' ';
        $judged{"@w[0 .. 2]"} = 1;
    }
}
my %seen;
my $new = 0;
for my $f (@found) {
    next if $seen{$f}++;
    my $j = $judged{$f};
    $new++ if $known && !$j;
    print $known ? ($j ? "known $f\n" : "NEW $f\n") : "$f\n";
}
print "textnames: ", scalar(keys %seen), " text items that are names, $new not judged\n";
exit($new ? 1 : 0);
