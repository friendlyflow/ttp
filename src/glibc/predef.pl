#!/usr/bin/env perl
# predef.pl — what the C preprocessor in ff (src/compiler/tools/cpp.ff)
# takes from gcc, as text (cpp --predef=predef-<target>.txt):
#
#   predef OPTIONS     gcc 16's predefined macros (gcc -dM -E -nostdinc
#                      OPTIONS) for each set of options the build's commands
#                      use; the first set whole, the others as +#define and
#                      -NAME against it
#   sysdir SYSP DIR    gcc's own include directories (gcc -v -E), for a
#                      command without -nostdinc, SYSP its kind (1: " 3" in
#                      line markers, 2: " 3 4")
#   preinclude FILE    the header gcc includes first (stdc-predef.h)
#   has KIND NAME N    gcc's answer to __has_KIND (NAME) (QUERIES' has lines)
#   target OPTIONS<tab>STATE   the macros after #pragma GCC target and
#                      optimize (STATE: t ARGS ; o ARGS ...), as +#define
#                      and -NAME against OPTIONS' (QUERIES' target lines:
#                      gcc -E -dD shows each #define and #undef of them)
#
# OPTIONS is a command's options but its files, -I, -D, -U, -include and
# their kin, -W, -M, -g, -nostdinc and -fno-builtin-* (cpp makes the same
# key of them). QUERIES is what cpp --collect wrote of the units (the names
# __has_builtin and its kin ask for, the states of the target pragmas):
# make predef runs it until there are no more.
#
#   perl predef.pl GCC [--queries FILE] [--key "OPTIONS"]... LOG... > predef-<target>.txt
#
# A host tool of the cross-check (core Perl): gcc makes the answers once,
# the file is committed, cpp reads it.
use strict;
use warnings;

my ($gcc, $qf, @keys, %seen);
$gcc = shift @ARGV or die "usage: predef.pl GCC [--queries FILE] [--key OPTIONS]... LOG...\n";
my @logs;
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--queries') { $qf = shift @ARGV }
    elsif ($a eq '--key') { push @keys, shift @ARGV }
    else { push @logs, $a }
}
sub key_of {   # (as cpp's parse_opts)
    my @a = split ' ', shift; shift @a;
    my @key;
    for (my $i = 0; $i < @a; $i++) {
        my $x = $a[$i];
        if ($x =~ /^-(o|I|D|U|isystem|iquote|idirafter|include|imacros|MF|MT|MQ|x)$/) { $i++; next }
        next if $x !~ /^-/ || $x =~ /^-(I|D|U|W|w|M|x|g|fno-builtin-)/ || $x =~ /^-(pipe|c|E|S|v|nostdinc)$/;
        return undef if $x =~ /^-[Bf]?(plugin|specs)/;
        if ($x =~ /^-(f|m|O|std=|ansi)/) { push @key, $x; next }
        die "predef: an option cpp does not know: $x\n";
    }
    join ' ', @key;
}
my %count;
for my $log (@logs) {
    open my $l, '<', $log or die "predef: cannot open $log: $!\n";
    my $all = do { local $/; <$l> };
    $all =~ s/\\\n/ /g;
    for my $c (split /\n/, $all) {
        $c =~ s/^\s+//;
        next unless $c =~ m{^/\S*gcc\s};
        next unless ($c =~ / -c / && $c =~ / -o \S+\.o[sS]? /) || ($c =~ / -S(\s|$)/ && $c =~ / -o \S+-aux\.S /);
        next if $c =~ / -x ?assembler/ || ($c =~ /\.S\s/ && $c !~ /-aux\.S\s/);
        my $k = key_of($c);
        $count{$k}++ if defined $k;
    }
}
push @keys, sort { $count{$b} <=> $count{$a} || $a cmp $b } keys %count;
@keys = grep { !$seen{$_}++ } @keys;
die "predef: no commands\n" unless @keys;

sub defs { my ($key, $file) = @_; $file //= '/dev/null'; my @l = `$gcc -dM -E -nostdinc $key -x c $file`; die "predef: gcc failed: $key\n" if $?; chomp @l; @l }
sub name { $_[0] =~ /^#define (\S+?)(\(|\s|$)/ ? $1 : die "predef: not a #define: $_[0]\n" }
sub delta { my ($b, $d) = @_; my $o = '';
    for my $n (sort keys %$d) { $o .= "+$d->{$n}\n" if !exists $b->{$n} || $b->{$n} ne $d->{$n} }
    for my $n (sort keys %$b) { $o .= "-$n\n" unless exists $d->{$n} }
    $o }

print "# gcc 16's predefined macros for each set of options, its include directories and answers (src/glibc/predef.pl; make predef)\n";
my @base = defs($keys[0]); my %b = map { name($_) => $_ } @base;
print "predef $keys[0]\n", map { "$_\n" } @base;
for my $key (@keys[1 .. $#keys]) {
    my %d = map { name($_) => $_ } defs($key);
    print "predef $key\n", delta(\%b, \%d);
}

# gcc's include directories, each one's kind from a line marker of a header first found there
{
    my @v = `$gcc -v -E -x c /dev/null -o /dev/null 2>&1`;
    my ($in, @dirs);
    for (@v) { chomp; if (/^#include <\.\.\.> search starts here:/) { $in = 1; next } if (/^End of search list/) { $in = 0 } push @dirs, $1 if $in && /^ (\S+)$/ }
    my %taken;
    for my $d (@dirs) {
        opendir my $dh, $d or die "predef: cannot read $d\n";
        my @h = sort grep { /\.h$/ && -f "$d/$_" && !$taken{$_} } readdir $dh;
        $taken{$_} = 1 for grep { /\.h$/ } readdir $dh;
        my $sysp;
        for my $h (@h) {
            open my $f, '>', "/tmp/predef.$$.c" or die; print $f "#include <$h>\n"; close $f;
            my @o = `$gcc -E -x c /tmp/predef.$$.c 2>/dev/null`;
            for (@o) { if (/^# 1 "\Q$d\E\/\Q$h\E" 1( 3( 4)?)?$/) { $sysp = $2 ? 2 : $1 ? 1 : 0; last } }
            last if defined $sysp;
        }
        unlink "/tmp/predef.$$.c";
        # (a directory with no header of its own, as an empty include-fixed: what kind it is shows nowhere)
        $sysp //= 1;
        print "sysdir $sysp $d\n";
        opendir $dh, $d; $taken{$_} = 1 for grep { /\.h$/ } readdir $dh;
    }
    my @e = `$gcc -E -x c /dev/null 2>/dev/null`;
    for (@e) { if (/^# 1 "\S*\/([^\/"]+)" 1/) { print "preinclude $1\n"; last } }
}

if ($qf) {
    open my $q, '<', $qf or die "predef: cannot open $qf\n";
    my @all = grep { /\S/ } map { chomp; $_ } <$q>;
    my @q = grep { !/^target / } @all;
    my %op = (builtin => '__has_builtin', attribute => '__has_attribute', c_attribute => '__has_c_attribute', feature => '__has_feature', extension => '__has_extension');
    if (@q) {
        my $src = join '', map { my ($kind, $n) = split ' ', $_, 2; die "predef: a query of no kind: $_\n" unless $op{$kind}; "$op{$kind}($n)\n" } @q;
        open my $f, '>', "/tmp/predef.$$.c" or die; print $f $src; close $f;
        my @out = grep { !/^#/ && /\S/ } `$gcc -E -nostdinc $keys[0] /tmp/predef.$$.c`; unlink "/tmp/predef.$$.c";
        die "predef: gcc failed on the queries\n" if $? || @out != @q;
        chomp @out;
        print "has $q[$_] $out[$_]\n" for 0 .. $#q;
    }
    for my $t (grep { /^target / } @all) {
        my ($key, $state) = $t =~ /^target (.*?)\t(.*)$/ or die "predef: $t\n";
        my %kd = map { name($_) => $_ } defs($key);
        open my $f, '>', "/tmp/predef.$$.c" or die;
        for my $p (split / ; /, $state) { my ($w, $args) = $p =~ /^([to]) (.*)$/ or die "predef: $p\n"; print $f "#pragma GCC ", ($w eq 't' ? 'target' : 'optimize'), " $args\n" }
        close $f;
        # (-dM shows none of it: gcc runs a pragma's handler as -E prints the
        # pragma; -dD prints each #define and #undef as it happens)
        my @l = `$gcc -E -dD -nostdinc $key -x c /tmp/predef.$$.c`; die "predef: gcc failed: $key $state\n" if $?; unlink "/tmp/predef.$$.c";
        my %d = %kd; my $after = 0;
        for (@l) { chomp;
            if (/^#pragma GCC (target|optimize)/) { $after = 1; next }
            next unless $after;
            if (/^#define /) { $d{name($_)} = $_ } elsif (/^#undef (\S+)/) { delete $d{$1} }
        }
        print "target $key\t$state\n", delta(\%kd, \%d);
    }
}
