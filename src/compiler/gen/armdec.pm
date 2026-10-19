# armdec.pm — decodes an arm instruction (A32, 16-bit Thumb, Thumb-2) by
# the encodings of isa/arm.pl: the ff instruction that makes those bytes,
# its name and its operands in ttpc's order. s2ff-arm.pl reads what GNU as
# made of glibc's .S through it, so that ttpc makes the same bytes.
#
#   my $dec = armdec->new;
#   my @found = $dec->decode('a', 0xe3a0b000);   # ([name, [operand, ...]], ...)
#
# Each found instruction is checked: its operands, encoded again by the same
# fields, give the same bits. An operand is a register name (r0..r12, sp,
# lr, pc; s0.., d0..), a condition (cond.eq ...), a number, or, for a
# branch, the offset it holds (the caller makes it a label). A host tool
# (core Perl only), not part of ttpc.
package armdec;

use strict;
use warnings;
use FindBin;

my @CC = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le al);
my %REG = map { $_ => 1 } qw(rd rn rm rs rt rt2 ra rdlo rdhi rdn rdm);

sub specw { my $w = 0; for (split /\|/, $_[0]) { my ($h, $l) = /^(\d+)(?::(\d+))?$/ or die "armdec: bad spec $_[0]\n"; $w += $h - ($l // $h) + 1 } $w }
sub segs { map { /^(\d+)(?::(\d+))?$/; [$1, $2 // $1] } split /\|/, $_[0] }

sub new {
    my ($class) = @_;
    my $dir = "$FindBin::Bin/..";
    unless (@ARM::WIDE) { local @INC = ("$dir/gen", @INC); do "$dir/isa/arm.pl" or die "armdec: isa/arm.pl: " . ($@ || $!) . "\n" }
    my %by;
    for my $e (@ARM::WIDE) {
        my ($name, $mode, $gnu, $params, $test, $fields) = @$e;
        my (@f, $w);
        for my $f (@$fields) {
            if ($f =~ /^(\w+)=([01]+)$/) { push @f, { fixed => $2, w => length $2 } }
            elsif ($f =~ /^(\w+)\[([\d:|]+)\]\(([\w,]+)\)$/) { push @f, { custom => $1, spec => $2, args => [split /,/, $3], w => specw($2) } }
            elsif ($f =~ /^([\w]+)\[([\d:|]+)\]$/) { push @f, { p => $1, spec => $2, w => specw($2) } }
            elsif ($f =~ /^(\w+)$/) { push @f, { p => $1, spec => '3:0', w => 4 } }
            else { die "armdec: $name: field $f\n" }
        }
        $w += $_->{w} for @f;
        my ($mask, $val, $pos) = (0, 0, $w);
        for (@f) {
            $pos -= $_->{w};
            $_->{pos} = $pos;
            next unless defined $_->{fixed};
            $mask |= ((1 << $_->{w}) - 1) << $pos;
            $val |= oct("0b$_->{fixed}") << $pos;
        }
        # a parameter is signed where its test values go below 0
        my %signed = map { my $t = $test && $test->{$_}; ($_ => ($t && grep { $_ < 0 } @$t) ? 1 : 0) } @$params;
        my ($bmark) = $gnu =~ /\{u?imm\^(\d)\}/;
        push @{ $by{$mode} }, { name => $name, params => $params, f => \@f, mask => $mask, val => $val, w => $w,
            signed => \%signed, branch => $bmark, gnu => $gnu };
    }
    bless { by => \%by }, $class;
}

sub rname { my ($n) = @_; $n == 13 ? 'sp' : $n == 14 ? 'lr' : $n == 15 ? 'pc' : "r$n" }

# the parameters of def d for the bits v, or undef
sub fields_of {
    my ($d, $v) = @_;
    my (%p, %up, %mag, %j, %top);
    for my $f (@{ $d->{f} }) {
        next if defined $f->{fixed};
        my $bits = ($v >> $f->{pos}) & ((1 << $f->{w}) - 1);
        if (defined $f->{p} || $f->{custom} eq 'mag') {
            my $into = defined $f->{p} ? \%p : \%mag;
            my $name = defined $f->{p} ? $f->{p} : $f->{args}[0];
            my $at = $f->{w};
            for my $s (segs($f->{spec})) {
                my ($h, $l) = @$s;
                my $n = $h - $l + 1;
                $at -= $n;
                $into->{$name} //= 0;
                $into->{$name} |= (($bits >> $at) & ((1 << $n) - 1)) << $l;
                $top{$name} = $h if !defined $top{$name} || $h > $top{$name};
            }
        } elsif ($f->{custom} eq 'up') { $up{ $f->{args}[0] } = $bits }
        elsif ($f->{custom} =~ /^j[12]$/) { $j{ $f->{custom} } = $bits }
        elsif ($f->{custom} eq 'msb') { $p{_msb} = $bits }
        elsif ($f->{custom} eq 'wm1') { $p{width} = $bits + 1 }
        else { die "armdec: custom $f->{custom}\n" }
    }
    for (keys %up) { $p{$_} = $up{$_} ? $mag{$_} : -$mag{$_} }
    if (%j) {
        # Thumb-2 branch: I1 = NOT(J1 xor S), I2 = NOT(J2 xor S), S the sign
        my $s = ($p{imm} >> 24) & 1;
        $p{imm} |= ((1 ^ ($j{j1} ^ $s)) << 23) | ((1 ^ ($j{j2} ^ $s)) << 22);
        $top{imm} = 24;
    }
    $p{width} = $p{_msb} - $p{lsb} + 1 if defined $p{_msb};
    delete $p{_msb};
    for (keys %p) {
        next unless $d->{signed}{$_} && !defined $up{$_} && defined $top{$_};
        my $b = $top{$_};
        $p{$_} -= 1 << ($b + 1) if ($p{$_} >> $b) & 1;
    }
    \%p;
}

# the bits def d gives the parameters p (as ttpc encodes them)
sub encode {
    my ($d, $p) = @_;
    my $v = 0;
    for my $f (@{ $d->{f} }) {
        my $bits;
        if (defined $f->{fixed}) { $bits = oct("0b$f->{fixed}") }
        elsif (defined $f->{p} || $f->{custom} eq 'mag' || $f->{custom} eq 'msb' || $f->{custom} eq 'wm1') {
            my $x;
            if (defined $f->{p}) { $x = $p->{ $f->{p} } }
            elsif ($f->{custom} eq 'mag') { $x = abs $p->{ $f->{args}[0] } }
            elsif ($f->{custom} eq 'msb') { $x = $p->{lsb} + $p->{width} - 1 }
            else { $x = $p->{width} - 1 }
            return undef unless defined $x;
            $bits = 0;
            my $at = $f->{w};
            for my $s (segs($f->{spec})) {
                my ($h, $l) = @$s;
                my $n = $h - $l + 1;
                $at -= $n;
                $bits |= (($x >> $l) & ((1 << $n) - 1)) << $at;
            }
        } elsif ($f->{custom} eq 'up') { $bits = $p->{ $f->{args}[0] } >= 0 ? 1 : 0 }
        elsif ($f->{custom} =~ /^j([12])$/) {
            my $i = ($p->{imm} >> ($1 == 1 ? 23 : 22)) & 1;
            my $s = ($p->{imm} >> 24) & 1;
            $bits = 1 ^ ($i ^ $s);
        }
        $v |= ($bits & ((1 << $f->{w}) - 1)) << $f->{pos};
    }
    $v;
}

# The ff instructions of mode (a, t, t2) that make the bits v: each [name,
# [operands], def]; the ones without a condition first.
sub decode {
    my ($self, $mode, $v) = @_;
    my @found;
    for my $d (@{ $self->{by}{$mode} }) {
        next unless ($v & $d->{mask}) == $d->{val};
        my $p = fields_of($d, $v);
        # (cond 1111 is no condition: another space of encodings)
        next if defined $p->{cond} && $p->{cond} == 15;
        my $e = encode($d, $p);
        next unless defined $e && $e == $v;
        my @ops = map {
            my $n = $_;
            my $x = $p->{$n};
            !defined $x ? undef
            : $REG{$n} ? rname($x)
            : $n =~ /^s[dnm]$/ ? "s$x"
            : $n =~ /^d[dnm]$/ ? "d$x"
            : $n =~ /^q[dnm]$/ ? 'q' . ($x >> 1)
            : $n eq 'cond' || $n eq 'firstcond' ? "cond.$CC[$x]"
            : $n eq 'regs' ? sprintf('0x%x', $x)
            : $x
        } @{ $d->{params} };
        next if grep { !defined } @ops;
        push @found, [$d->{name}, \@ops, $d];
    }
    sort { ($a->[0] =~ /\.if$/ ? 1 : 0) <=> ($b->[0] =~ /\.if$/ ? 1 : 0) } @found;
}

1;
