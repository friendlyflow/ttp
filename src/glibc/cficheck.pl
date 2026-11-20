#!/usr/bin/env perl
# cficheck.pl — asmcfi-check's comparison: the frames of an asm part as
# glibc's compiler made them (its object) and as ttpc made them (its
# program, built with -g from the same part), per function.
#
#   perl cficheck.pl READELF TARGET ref.o SKIP prog HDR SIZE
#
# The code compared is SIZE bytes, from SKIP in the object's code section
# and from HDR in the program's file (its first PT_LOAD, at offset 0). On
# riscv64, x86_64 and aarch64 each FDE is read as readelf --debug-dump=
# frames-interp decodes it (relocations applied): where it starts, its end
# and its rows (where each starts, the CFA, each register's rule; one with
# no instructions its CIE's), so that the encodings may differ (ttpc's code
# alignment is 1, it writes DW_CFA_offset_extended_sf where gcc's
# DW_CFA_offset) but not what they say. ttpc's FDE is its procedure's, the
# asm function or entry where the object's starts (cfi words have no
# endproc): it may end later, but not past where the object's next starts. On arm each entry of
# .ARM.exidx as readelf -u decodes it: where it starts and its unwinding
# instructions' bytes (finish and the personality's index left out, which
# the encoding picks); a CANTUNWIND entry of ttpc's after a function, where the
# object has none, is not one of the object's (its linker adds those). An
# FDE or entry outside the code compared is left out. Prints the
# differences and exits 1 where there are some.
use strict;
use warnings;

my ($readelf, $target, $ref, $skip, $prog, $hdr, $size) = @ARGV;
defined $size or die "usage: cficheck.pl READELF TARGET ref.o SKIP prog HDR SIZE\n";

# the program's code: its first PT_LOAD's address plus HDR
my $base;
for (`$readelf -lW $prog`) { if (/^\s*LOAD\s+0x0+\s+0x([0-9a-f]+)/) { $base = hex($1) + $hdr; last } }
defined $base or die "cficheck: $prog: no PT_LOAD at offset 0\n";

# FDEs: start => [end, rows], each row "loc cfa reg=rule ...", from start;
# an FDE with no instructions has its CIE's row
sub fdes {
    my ($file, $from) = @_;
    my (%f, %cie, $cur, $ciecur, $b, @cols);
    my $done = sub { @{ $cur->[1] } = ("$b $cie{ $cur->[2] }") if $cur && !@{ $cur->[1] } && defined $cie{ $cur->[2] } };
    for (`$readelf --debug-dump=frames-interp $file 2>&1`) {
        chomp;
        if (/^\S+ \S+ \S+ FDE cie=(\S+) pc=([0-9a-f]+)\.\.([0-9a-f]+)/) {
            $done->(); undef $ciecur;
            ($b, my $e) = (hex($2) - $from, hex($3) - $from);
            $cur = $b >= 0 && $b < $size ? ($f{$b} = [$e, [], $1]) : undef;
            next;
        }
        if (/^(\S+) \S+ \S+ CIE/) { $done->(); undef $cur; $ciecur = $1; next }
        if (/ZERO terminator/) { $done->(); undef $cur; undef $ciecur; next }
        if (/^\s+LOC\s+(.*)$/) { @cols = split ' ', $1; next }
        if (/^([0-9a-f]{8,16})\s+(.*)$/) {
            my ($loc, @v) = (hex($1) - $from, split ' ', $2);
            my $state = join ' ', map { "$cols[$_]=" . ($v[$_] // '?') } 0 .. $#cols;
            if (defined $ciecur) { $cie{$ciecur} //= $state; next }
            push @{ $cur->[1] }, "$loc $state" if $cur;
        }
    }
    $done->();
    \%f;
}

# EHABI entries: start => its unwinding instructions' bytes (finish left
# out), or "cantunwind". An entry readelf cannot follow to its .ARM.extab
# entry (ttpc's program names no such section) is read from the file:
# personality 1's words (0x81, the words after the first, two bytes, then
# four a word)
my $load;       # the program's first PT_LOAD's address (file offset 0)
sub exidx {
    my ($file, $from) = @_;
    my (%e, $cur, $tab);
    my $extab = sub {
        my ($a) = @_;
        open my $h, '<:raw', $file or die "cficheck: $file: $!\n";
        seek $h, $a - $load, 0 or die "cficheck: $file: no $a\n";
        read($h, my $w0, 4) == 4 or die "cficheck: $file: no $a\n";
        my $w = unpack 'V', $w0;
        die sprintf("cficheck: %s: .ARM.extab entry at 0x%x is not personality 1's\n", $file, $a) unless $w >> 24 == 0x81;
        my @b = (($w >> 8) & 255, $w & 255);
        for (1 .. (($w >> 16) & 255)) { read($h, my $x, 4) == 4 or die; my $v = unpack 'V', $x; push @b, map { ($v >> $_) & 255 } 24, 16, 8, 0 }
        join ' ', map { sprintf '0x%02x', $_ } grep { $_ != 0xb0 } @b;
    };
    for (`$readelf -u $file 2>/dev/null`) {
        chomp;
        if (/^0x([0-9a-f]+)(?: <[^>]*>)?: (\S+)/) {
            my ($a, $w) = (hex($1) - $from, $2);
            $e{$cur} = $extab->($tab) if defined $cur && defined $tab && $e{$cur} eq '';
            undef $tab;
            if ($a >= 0 && $a < $size) { $cur = $a; $e{$a} = $w eq '0x1' ? 'cantunwind' : ''; $tab = hex $1 if $w =~ /^\@0x([0-9a-f]+)$/ } else { undef $cur }
            next;
        }
        next unless defined $cur;
        if (/^\s+((?:0x[0-9a-f]{2} ?)+)\s+\S/) {
            my $b = join ' ', grep { $_ ne '0xb0' } split ' ', $1;
            $e{$cur} .= ($e{$cur} eq '' || $b eq '' ? '' : ' ') . $b;
            undef $tab;
        }
    }
    $e{$cur} = $extab->($tab) if defined $cur && defined $tab && $e{$cur} eq '';
    \%e;
}

my @diff;
if ($target eq 'arm') {
    my $want = exidx($ref, $skip);
    $load = $base - $hdr;
    my $got = exidx($prog, $base);
    for my $a (sort { $a <=> $b } keys %$got) {
        next if $got->{$a} eq 'cantunwind' && !exists $want->{$a};
        push @diff, sprintf("ttpc's entry at +0x%x (%s), the object has %s", $a, $got->{$a}, exists $want->{$a} ? "($want->{$a})" : 'none')
            unless exists $want->{$a} && $want->{$a} eq $got->{$a};
    }
    for my $a (sort { $a <=> $b } grep { !exists $got->{$_} } keys %$want) {
        push @diff, sprintf("the object's entry at +0x%x (%s), ttpc has none", $a, $want->{$a});
    }
    printf "%d entries\n", scalar keys %$want unless @diff;
} else {
    my $want = fdes($ref, $skip);
    my $got = fdes($prog, $base);
    # (consecutive rows that say the same: one)
    for my $f ($want, $got) {
        for my $r (map { $_->[1] } values %$f) {
            my @k;
            for (@$r) { my ($l, $s) = split / /, $_, 2; push @k, $_ unless @k && (split / /, $k[-1], 2)[1] eq $s }
            @$r = @k;
        }
    }
    # ttpc's FDE is its procedure's, the asm function (or entry) the
    # object's starts at: it ends where that does, or later, over bytes no
    # FDE of the object's has (padding, data the function carries)
    my $show = sub { sprintf "+0x%x..+0x%x", @_ };
    my @starts = sort { $a <=> $b } keys %$want;
    for my $i (0 .. $#starts) {
        my $b = $starts[$i];
        my ($e, $wr) = @{ $want->{$b} };
        my $next = $i < $#starts ? $starts[$i + 1] : undef;
        if (!$got->{$b}) { push @diff, "the object's FDE " . $show->($b, $e) . ", ttpc has none there"; next }
        my ($ge, $gr) = @{ $got->{$b} };
        push @diff, "the object's FDE " . $show->($b, $e) . ", ttpc's " . $show->($b, $ge)
            if $ge < $e || (defined $next && $ge > $next);
        my ($w, $g) = (join("\n    ", @$wr), join("\n    ", @$gr));
        push @diff, "FDE " . $show->($b, $e) . ": the object's rows\n    $w\n  ttpc's\n    $g" if $w ne $g;
    }
    push @diff, "ttpc's FDE " . $show->($_, $got->{$_}[0]) . ", the object has none there" for grep { !$want->{$_} } sort { $a <=> $b } keys %$got;
    printf "%d FDEs\n", scalar keys %$want unless @diff;
}
if (@diff) { print "$_\n" for @diff; exit 1 }
