#!/usr/bin/perl
# regcheck.pl shared.ff page.ff.txt...: the names a tool page defines (a
# local, a parameter, a global, a function; not a struct's or a union's
# field, not a parameter of a function type, nothing in a comment) that
# are a register of one of the four targets, a line each with its
# targets; exit 1 if there is one. ttpc
# refuses such a name on that target ("a reserved word": the user's rule,
# kept 2026-11-10, 4A). The tools' dev C is translated once, with
# riscv64's reserved names (c2ff.pl --page), and built for all four
# targets, so tools/dev/mk.sh (tools-dev-check) runs this on each page it
# makes: it names the local before one target's build stops on it.
use strict; use warnings;
use FindBin; use lib $FindBin::Bin; use FF;
my ($shared, @pages) = @ARGV;
die "usage: regcheck.pl shared.ff page.ff.txt...\n" unless $shared && @pages;
my $bin = do { open my $h, '<:raw', $shared or die "$shared: $!"; local $/; <$h> };
my ($sh) = grep { $_->{content} eq 'shared:' } @{ FF::read_ff($bin)->{children} };
die "regcheck: no shared: in $shared\n" unless $sh;
my %reg;    # a register's name -> its targets
sub flat { map { FF::is_layer($_) ? flat(@{ $_->{children} }) : $_ } @_ }
for my $sec (flat(@{ $sh->{children} })) {
    my ($tg) = $sec->{content} =~ /^(riscv64|x86_64|aarch64|arm):$/ or next;
    for my $r (grep { $_->{content} eq 'registers:' } flat(@{ $sec->{children} })) {
        for my $d (@{ $r->{children} }) {
            (my $n = $d->{content}) =~ s/:$//;
            $reg{$_}{$tg} = 1 for split ' ', $n;
        }
    }
}
die "regcheck: no registers in $shared\n" unless %reg;
my $bad = 0;
for my $p (@pages) {
    open my $f, '<', $p or die "$p: $!";
    my (@path, @first, %said);   # the ancestors' contents, each one's first child
    while (my $l = <$f>) {
        chomp $l;
        next unless $l =~ /\S/;
        my ($ind, $s) = $l =~ /^( *)(.*)$/;
        my $d = length($ind) / 2;
        splice @path, $d; splice @first, $d;
        $first[$d - 1] //= $s if $d > 0;
        push @path, $s;
        next if grep { $_ eq 'comment' || $_ eq 'license' } @path[0 .. $d - 1];
        my ($n) = $s =~ /^(\S+):$/ or next;
        next unless $reg{$n};
        next if $d > 0 && ($first[$d - 1] // '') =~ /^(struct|union|function)$/;
        next if $said{$n}++;
        print "$p: $n is a register of ", join(' ', sort keys %{ $reg{$n} }), "\n";
        $bad = 1;
    }
    close $f;
}
exit $bad;
