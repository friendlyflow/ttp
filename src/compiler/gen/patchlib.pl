# patchlib.pl — the helpers of the patch scripts (gen/patches/*.pl) that
# change ttpc.ff (or ttpc.defs.ff). A change to ttpc is made as a script,
# committed, so that it can be replayed on another branch when a merge of
# the tree conflicts. A script edits the text form of the tree (fftext.pl,
# one node per line, two spaces per level):
#
#   our $t; do "$ENV{PATCHLIB}" or die $@;
#   edit(\$t, 'stmt', $old, $new);        # $old must be in stmt exactly once
#   save();
#
# and is run on a tree by
#
#   make patch P=gen/patches/x.pl [T=ttpc.ff]    (in src/compiler)
#
# which dumps T to text, runs the script on it (PATCHLIB is this file, the
# text file its first argument) and converts the text back into T.
#
# The helpers:
#
#   asm($indent, $src)   the text of instructions, written one per line as
#                        `op arg arg ...` (operands in ttpc's order,
#                        destination last); `name:` alone on a line is a
#                        label, whose instructions follow nested under it;
#                        rel:X is the call rel / X; blank lines and # lines
#                        are skipped. $indent is the indent of the first
#                        level, in spaces.
#   fn($name, $src)      a function name: holding asm($src), at the level of
#                        the cc group's helpers (indent 2); fn($name, $src,
#                        $indent) at any other level.
#   find(\$t, $name)     the text of the one function name: (any depth) up
#                        to the next line at its level or above; a path
#                        'cc/stmt' names it under its ancestors. Dies when
#                        there is none or more than one.
#   edit(\$t, $name, $old => $new, ...)
#                        in function name (as find), each $old replaced by
#                        $new; each $old must be there exactly once.
#   once(\$s, $old, $new, $what)
#                        $old replaced by $new in $s, exactly once.
#   save()               writes $t back to the text file.
use strict; use warnings;
our ($t, $tf);
$tf = $ARGV[0] // die "patchlib: no text file to patch\n";
{ open my $h, '<', $tf or die "$tf: $!"; local $/; $t = <$h>; close $h }

sub asm {
    my ($ind, $src) = @_;
    my ($out, $in) = ('', 0);
    for my $l (split /\n/, $src) {
        $l =~ s/^\s+|\s+$//g;
        next if $l eq '' || $l =~ /^#/;
        if ($l =~ /^(\S+):$/) { $out .= ' ' x $ind . "$1:\n"; $in = 2; next }
        my ($op, @a) = split ' ', $l;
        my $p = ' ' x ($ind + $in);
        $out .= "$p$op\n";
        $out .= /^rel:(.*)$/ ? "$p  rel\n$p    $1\n" : "$p  $_\n" for @a;
    }
    $out;
}

sub fn { my ($name, $body, $ind) = @_; $ind //= 2; ' ' x $ind . "$name:\n" . asm($ind + 2, $body) }

sub once {
    my ($s, $o, $n, $w) = @_;
    my $c = () = $$s =~ /\Q$o\E/g;
    die "patchlib: $w: found $c times, not once\n" unless $c == 1;
    $$s =~ s/\Q$o\E/$n/;
}

# The block of the one function name: under the path of its ancestors.
sub find {
    my ($t, $path) = @_;
    my @path = split m{/}, $path;
    my ($from, $to, $depth) = (0, length $$t, -1);
    for my $name (@path) {
        my @hits;
        my $text = substr($$t, $from, $to - $from);
        while ($text =~ /^((?: )*)\Q$name\E:\n/mg) {
            my ($ind, $start, $head) = ($1, $-[0], $+[0] - $-[0]);   # copied: a match below resets $1
            my $d = length($ind) / 2;
            next if $d <= $depth;
            my $rest = substr($text, $start + $head);
            my $w = 2 * $d; my $len = $rest =~ /^ {0,$w}(?! )/m ? $-[0] : length $rest;
            push @hits, [$from + $start, $from + $start + $head + $len, $d];
        }
        # under an ancestor, only the nearest level counts
        if (@hits) { my $min = (sort { $a <=> $b } map { $_->[2] } @hits)[0]; @hits = grep { $_->[2] == $min } @hits if $depth >= 0 }
        die "patchlib: no function $name in $path\n" unless @hits;
        die "patchlib: " . @hits . " functions $name in $path, name it by its path (a/b)\n" if @hits > 1;
        ($from, $to, $depth) = @{ $hits[0] };
    }
    ($from, $to);
}

sub edit {
    my ($t, $name, @pairs) = @_;
    my ($from, $to) = find($t, $name);
    my $e = substr($$t, $from, $to - $from);
    while (@pairs) { my ($o, $n) = splice @pairs, 0, 2; once(\$e, $o, $n, $name) }
    substr($$t, $from, $to - $from) = $e;
}

sub save { open my $h, '>', $tf or die "$tf: $!"; print $h $t; close $h or die "$tf: $!" }
1;
