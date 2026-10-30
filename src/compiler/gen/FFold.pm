# FFold.pm — floating constants as gcc folds them, for c2ff.pl and
# roundtrip.pl (one rounding on both sides of the round trip):
#
#   ldround($dec, $p, $emin, $emax)  clang's decimal of a literal to the
#                                    nearest of $p bits, as binary128's
#                                    exact hex float with L (undef past
#                                    $emax)
#   ratq($n, $d, $p, $emin)          n / d to the nearest q * 2^e
#   qlit($q, $e, $emax)              q * 2^e as that hex float
#   fold($n)                         a value of clang's JSON node: literals,
#                                    gcc's infinity and NaN, integers, - and
#                                    +, conversions, a + b, a - b, each
#                                    rounded to its type (ties to even),
#                                    infinity and NaN as IEEE has them, the
#                                    zero's sign too; undef where it is no
#                                    such constant. A value is { k => num
#                                    (q * 2^e), inf or nan, neg }.
#   fty($type)                       a type's [bits, lowest exponent,
#                                    highest, literal suffix, its
#                                    infinity's exponent] (float, double,
#                                    long double as binary128)
#   ftype($n)                        the node's floating type, or ''
#                                    (clang's __float128 is float128)
#   ldinside($n)                     a long double (or float128) in the
#                                    node or under it
#   x87()                            long double as x86_64 has it, the
#                                    x87's 64 bits (float128 binary128,
#                                    with Q)
#
# A host tool (core Perl only).
package FFold;
use strict;
use warnings;
use Math::BigInt;
use Exporter 'import';
our @EXPORT_OK = qw(ldround ratq qlit fold fty ftype ldinside);

sub kids { @{ $_[0]{inner} || [] } }
sub ftype {
    my ($n) = @_;
    return '' unless $n && $n->{type};
    (my $q = $n->{type}{desugaredQualType} // $n->{type}{qualType} // '') =~ s/\b(const|volatile)\s+//g;
    $q =~ /^(float|double|long double)$/ ? $q : $q eq '__float128' ? 'float128' : '';
}
sub ldinside { my ($n) = @_; return 1 if ftype($n) =~ /^(long double|float128)$/; grep { ldinside($_) } kids($n) }
my %fty = (float => [24, -149, 127, 'f', '128f'], double => [53, -1074, 1023, '', '1024'],
    'long double' => [113, -16494, 16383, 'L', '16384L'], float128 => [113, -16494, 16383, 'Q', '16384Q']);
sub fty { $fty{ $_[0] // '' } }
sub x87 { $fty{'long double'} = [64, -16445, 16383, 'L', '16384L'] }

# clang's decimal: n / d, or undef
sub dec {
    my ($s) = @_;
    $s =~ /^([0-9]*)(?:\.([0-9]*))?(?:[eE]([-+]?[0-9]+))?$/ or return;
    my ($i, $f, $e) = ($1, $2 // '', $3 // 0);
    my $m = Math::BigInt->new(($i . $f) =~ s/^0+(?=.)//r);
    my $e10 = $e - length $f;
    $e10 >= 0 ? ($m * Math::BigInt->new(10)->bpow($e10), Math::BigInt->new(1)) : ($m, Math::BigInt->new(10)->bpow(-$e10));
}
sub ldround {
    my ($s, $p, $emin, $emax) = @_;
    my ($n, $d) = dec($s) or die "c2ff: a long double literal that is no decimal: $s\n";
    return '0x0p+0L' if $n->is_zero;
    qlit(ratq($n, $d, $p, $emin), $emax);
}
# n / d (n > 0) to the nearest q * 2^e2, q of $p bits (ties to even), e2 no
# lower than $emin
sub ratq {
    my ($n, $d, $p, $emin) = @_;
    my $bits = sub { length($_[0]->as_bin) - 2 };
    # e2: value / 2^e2 in [2^(p-1), 2^p)
    my $e2 = $bits->($n) - $bits->($d) - $p;
    my $div = sub {
        my ($e2) = @_;
        my ($nn, $dd) = ($n->copy, $d->copy);
        if ($e2 >= 0) { $dd->blsft($e2) } else { $nn->blsft(-$e2) }
        my ($qq, $r) = $nn->copy->bdiv($dd);
        # round to nearest, ties to even
        my $c = ($r * 2)->bcmp($dd);
        $qq->binc if $c > 0 || ($c == 0 && $qq->is_odd);
        $qq;
    };
    my $top = Math::BigInt->new(2)->bpow($p - 1);
    my $over = Math::BigInt->new(2)->bpow($p);
    $e2++ while ($div->($e2))->bcmp($over) >= 0;
    $e2-- while ($div->($e2))->bcmp($top) < 0 && $e2 > $emin;
    $e2 = $emin if $e2 < $emin;
    my $q = $div->($e2);
    if ($q->bcmp($over) >= 0) { $e2++; $q = $div->($e2) }
    ($q, $e2);
}
# q * 2^e2 as binary128's exact hex float with L; undef where its top bit
# is past $emax
sub qlit {
    my ($q, $e2, $emax) = @_;
    return '0x0p+0L' if $q->is_zero;
    # q * 2^e2, as binary128 writes it: its top bit the leading 1, or, below
    # binary128's normal range, a subnormal 0x0.<digits>p-16382
    my $lead = length($q->as_bin) - 3;
    my $exp = $e2 + $lead;
    return undef if $exp > $emax;
    my $g = $q->copy;
    if ($exp >= -16382) {
        $g->bsub(Math::BigInt->new(2)->bpow($lead));
        $g->blsft(112 - $lead);
        my $hex = substr($g->as_hex, 2);
        $hex = ('0' x (28 - length $hex)) . $hex;
        $hex =~ s/0+$//;
        return sprintf "0x1%sp%+dL", ($hex eq '0' || $hex eq '' ? '' : ".$hex"), $exp;
    }
    $g->blsft($e2 + 16494);
    my $hex = substr($g->as_hex, 2);
    $hex = ('0' x (28 - length $hex)) . $hex;
    $hex =~ s/0+$//;
    sprintf "0x0.%sp-16382L", $hex;
}

sub zero { +{ k => 'num', neg => $_[0] // 0, q => Math::BigInt->new(0), e => 0 } }
sub flip { my ($v) = @_; +{ %$v, neg => $v->{neg} ? 0 : 1 } }
# the value rounded to the type
sub round {
    my ($v, $t) = @_;
    return undef unless $v && fty($t);
    return $v unless $v->{k} eq 'num' && !$v->{q}->is_zero;
    my ($p, $emin, $emax) = @{ fty($t) };
    my $one = Math::BigInt->new(1);
    my ($n, $d) = $v->{e} >= 0 ? ($v->{q}->copy->blsft($v->{e}), $one) : ($v->{q}->copy, $one->copy->blsft(-$v->{e}));
    my ($q, $e) = ratq($n, $d, $p, $emin);
    return { k => 'inf', neg => $v->{neg} } if !$q->is_zero && $e + length($q->as_bin) - 3 > $emax;
    return { k => 'num', neg => $v->{neg}, q => $q, e => $e };
}
sub fold {
    my ($n) = @_;
    my $k = $n->{kind} // '';
    my @c = kids($n);
    return fold($c[0]) if $k =~ /^(ParenExpr|ConstantExpr)$/ && @c == 1;
    if ($k eq 'FloatingLiteral') {
        my ($nn, $dd) = dec($n->{value} // '') or return undef;
        return zero() if $nn->is_zero;
        my $t = fty(ftype($n)) or return undef;
        my ($q, $e) = ratq($nn, $dd, $t->[0], $t->[1]);
        return { k => 'inf', neg => 0 } if !$q->is_zero && $e + length($q->as_bin) - 3 > $t->[2];
        return { k => 'num', neg => 0, q => $q, e => $e };
    }
    if ($k eq 'IntegerLiteral') {
        my $v = Math::BigInt->new($n->{value} // return undef);
        return { k => 'num', neg => $v->is_neg ? 1 : 0, q => $v->copy->babs, e => 0 };
    }
    if ($k eq 'CallExpr') {
        # gcc's __builtin_huge_val, inf, nan ("")
        my ($f, @a) = @c;
        $f = (kids($f))[0] while $f && ($f->{kind} // '') =~ /^(ImplicitCastExpr|ParenExpr)$/;
        my $name = (($f // {})->{referencedDecl} // {})->{name} // '';
        return { k => 'inf', neg => 0 } if $name =~ /^__builtin_(?:huge_val|inf)[fl]?$/ && !@a;
        if ($name =~ /^__builtin_nan[fl]?$/ && @a == 1) {
            my $s = $a[0];
            $s = (kids($s))[0] while ($s->{kind} // '') =~ /^(ImplicitCastExpr|ParenExpr)$/;
            return { k => 'nan', neg => 0 } if ($s->{kind} // '') eq 'StringLiteral' && ($s->{value} // '') eq '""';
        }
        return undef;
    }
    if ($k eq 'ImplicitCastExpr' || $k eq 'CStyleCastExpr') {
        my $ck = $n->{castKind} // '';
        return undef unless $ck =~ /^(FloatingCast|IntegralToFloating|NoOp)$/ && @c == 1;
        my $v = fold($c[0]);
        return $ck eq 'NoOp' ? $v : round($v, ftype($n));
    }
    if ($k eq 'UnaryOperator' && ($n->{opcode} // '') =~ /^[-+]$/ && @c == 1) {
        my $v = fold($c[0]) // return undef;
        return $n->{opcode} eq '+' ? $v : flip($v);
    }
    if ($k eq 'BinaryOperator' && ($n->{opcode} // '') =~ /^[-+]$/ && @c == 2) {
        my ($a, $b) = (fold($c[0]), fold($c[1]));
        return undef unless $a && $b && fty(ftype($n));
        $b = flip($b) if $n->{opcode} eq '-';
        return $a if $a->{k} eq 'nan';
        return $b if $b->{k} eq 'nan';
        if ($a->{k} eq 'inf' || $b->{k} eq 'inf') {
            return { k => 'nan', neg => 0 } if $a->{k} eq 'inf' && $b->{k} eq 'inf' && $a->{neg} != $b->{neg};
            return $a->{k} eq 'inf' ? $a : $b;
        }
        my $e = $a->{e} < $b->{e} ? $a->{e} : $b->{e};
        my $x = $a->{q}->copy->blsft($a->{e} - $e);
        $x->bneg if $a->{neg};
        my $y = $b->{q}->copy->blsft($b->{e} - $e);
        $y->bneg if $b->{neg};
        my $z = $x + $y;
        # (an exact zero: -0 only of -0 and -0, as round to nearest has it)
        return zero($a->{neg} && $b->{neg} ? 1 : 0) if $z->is_zero;
        return round({ k => 'num', neg => $z->is_neg ? 1 : 0, q => $z->copy->babs, e => $e }, ftype($n));
    }
    undef;
}
1;
