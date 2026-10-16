#!/usr/bin/env perl
# c2ff.pl — C as ff: the functions a program reaches in a preprocessed C file
# (clang's JSON AST of it), written in ttpc's C layer, one C construct per ff
# construct (see language.ff.txt). Nothing is lowered: a construct the C
# layer has no form for stops the translation, and is listed.
#
#   perl c2ff.pl ast.json name... > out.ff.txt
#
# The AST is clang's: $C2FF_CLANG -Xclang -ast-dump=json -fsyntax-only
# --target=riscv64-linux-gnu -std=gnu11 file.i. The names are the functions
# to start from; what they call, the types and globals they use, comes too.
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;

# ---- types ------------------------------------------------------------------
# A C type as clang prints it (its canonical form, desugaredQualType when
# there is one) becomes a run of ff type words. Qualifiers (const, volatile,
# restrict) have no ff form and no effect on the code, and are dropped.

my %scalar = (
    'char' => 'char',                   # unsigned on riscv64
    'signed char' => 'i8', 'unsigned char' => 'u8',
    'short' => 'short', 'signed short' => 'short', 'unsigned short' => 'u16',
    'int' => 'int', 'signed int' => 'int', 'signed' => 'int',
    'unsigned int' => 'u32', 'unsigned' => 'u32',
    'long' => 'long', 'signed long' => 'long', 'unsigned long' => 'u64',
    'long long' => 'i64', 'signed long long' => 'i64', 'unsigned long long' => 'u64',
    '_Bool' => 'u8', 'void' => 'void',
    '__builtin_va_list' => 'va_list',
);

# The function types a pointer to a function needs, by their C spelling.
my (%fntype, @fntypes);

sub trim { my ($s) = @_; $s =~ s/^\s+|\s+$//g; $s }

# A C type string to a list of ff words. A pointer to a function names a
# function type of its own (fn1:, fn2:, ...), made once per spelling.
sub ctype {
    my ($t) = @_;
    $t = trim($t);
    $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
    $t = trim($t);
    $t =~ s/\s+/ /g;
    # array: base [n]
    if ($t =~ /^(.*?)\s*\[(\d+)\]((?:\[\d+\])*)$/) {
        my ($base, $n, $rest) = ($1, $2, $3);
        return ('array', ctype($base . $rest), $n);
    }
    # pointer to function: ret (*)(params)
    if ($t =~ /^(.*?)\s*\(\*\)\s*\((.*)\)$/) {
        return ('address', fntype($1, $2));
    }
    # pointer
    if ($t =~ /^(.*)\*$/) {
        my @base = ctype($1);
        return @base == 1 && $base[0] eq 'void' ? ('address') : ('address', @base);
    }
    return $scalar{$t} if exists $scalar{$t};
    return name_of($1, $2) if $t =~ /^(struct|union|enum) (\S+)$/;
    die "c2ff: no ff type for C's '$t'\n";
}

# The ff name of a struct, union or enum (C's tag namespace has its own
# names; ff has one, so the kind goes in front when the tag would clash).
my %tagname;
sub name_of { my ($kind, $tag) = @_; $tagname{"$kind $tag"} //= $tag }

sub fntype {
    my ($ret, $params) = @_;
    my $key = trim($ret) . ' (' . trim($params) . ')';
    return $fntype{$key} if $fntype{$key};
    my $name = 'fn' . (@fntypes + 1);
    $fntype{$key} = $name;
    push @fntypes, [$name, trim($ret), trim($params)];
    $name;
}

# The parameters of a function type string, split at its top-level commas.
sub params {
    my ($s) = @_;
    my @p;
    my ($depth, $cur) = (0, '');
    for my $c (split //, $s) {
        $depth++ if $c eq '(';
        $depth-- if $c eq ')';
        if ($c eq ',' && !$depth) { push @p, trim($cur); $cur = ''; next }
        $cur .= $c;
    }
    push @p, trim($cur) if trim($cur) ne '';
    @p = () if @p == 1 && $p[0] eq 'void';
    @p;
}

# ---- self-test of the type words (perl c2ff.pl --types) ----------------------
if (@ARGV && $ARGV[0] eq '--types') {
    for my $t ('const char *', 'unsigned long', 'int (*)(const void *, const void *)',
               'char [16]', 'int [3][4]', 'void *', 'struct pt *', 'signed char',
               '_Bool', 'unsigned int', 'long long', 'char **') {
        printf "%-40s %s\n", $t, join(' / ', ctype($t));
    }
    for my $f (@fntypes) {
        my ($name, $ret, $ps) = @$f;
        print "$name: function / ", join(' / ', ctype($ret)),
            map({ " / p: / " . join(' / ', ctype($_)) } params($ps)), "\n";
    }
    exit 0;
}

die "c2ff: not yet: the translation of declarations and statements\n";
