#!/usr/bin/env perl
# clangsema.pl — clang's side of the check of csema (tools/csema.ff, the
# types and semantics of C in ff): clang's JSON AST of a unit
# (-ast-dump=json) and its record layouts (-fdump-record-layouts,
# written before the JSON on the same output) as the lines csema -d writes:
# every declaration and expression in the order of the tree, each with its
# type as clang spells it after typedefs and typeof are resolved (the
# canonical type), its value category, a cast's kind, a folded constant's
# value; then every record's layout. The two must be equal line for line.
#
#   perl clangsema.pl unit.out > unit.clang     (unit.out: clang's output)
#
# Left out on both sides: parentheses (ParenExpr), attributes and their
# arguments, implicit declarations (clang's builtins), the declarations of
# clang-prelude.h (which comes first), a static assertion's message, an
# InitListExpr's array filler, statements themselves (only what they hold).
# Anonymous records are named (anon at FILE:LINE:COL), their tag keyword's
# place as the line markers give it, whatever clang calls them.
#
# A host tool of the checks (Perl, JSON::XS or JSON::PP): not in the build.
use strict;
use warnings;
my $json_parser = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };

my $text = do { local $/; <STDIN> };
my $at = index($text, "\n{\n");
$at = 0 if $at < 0 && substr($text, 0, 1) eq '{';
die "clangsema: no JSON AST in the input\n" if $at < 0;
my $layouts = substr($text, 0, $at);
my $ast = $json_parser->decode(substr($text, $at));
undef $text;

# ---- types: clang's spelling parsed, typedefs resolved, printed again ----
my @tdscope = ({});         # typedef names in scope: canonical types
my %typeof;                 # a typeof (...) spelling and its type, per top-level declaration
our @typeof_scopes;        # the typeof (...) spellings of the blocks the walk is in, innermost last
my %declty;               # declared names and their types, for typeof (name)
our @tok; our $tp;

sub lex_type {
    my ($s) = @_;
    my @t;
    while (length $s) {
        $s =~ s/^\s+//;
        last unless length $s;
        if ($s =~ /^(__attribute__\s*)\(\(/) {
            # balanced
            my $d = 0; my $i = length($1);
            for (; $i < length $s; $i++) { my $c = substr($s, $i, 1); $d++ if $c eq '('; if ($c eq ')') { $d--; if ($d == 0) { $i++; last } } }
            push @t, ['attr', substr($s, 0, $i)]; $s = substr($s, $i); next;
        }
        if ($s =~ /^((?:typeof|__typeof__|typeof_unqual|__typeof_unqual__)\s*)\(/) {
            my $d = 0; my $i = length($1);
            for (; $i < length $s; $i++) { my $c = substr($s, $i, 1); $d++ if $c eq '('; if ($c eq ')') { $d--; if ($d == 0) { $i++; last } } }
            push @t, ['typeof', substr($s, 0, $i)]; $s = substr($s, $i); next;
        }
        if ($s =~ /^\((?:unnamed|anonymous)(?: struct| union| enum)? at ([^()]*)\)/) {
            push @t, ['anon', "(anon at $1)"]; $s = substr($s, length $&); next;
        }
        if ($s =~ /^(\.\.\.|::|[A-Za-z_][A-Za-z_0-9]*|[0-9]+|.)/s) { push @t, ['w', $1]; $s = substr($s, length $1); next }
    }
    @t;
}
sub tk { my ($k) = @_; my $t = $tok[$tp + ($k // 0)]; $t ? $t->[1] : '' }
sub tkind { my ($k) = @_; my $t = $tok[$tp + ($k // 0)]; $t ? $t->[0] : '' }

my %qualword = (const => 'const', volatile => 'volatile', restrict => 'restrict', __restrict => 'restrict');
my %basic = map { $_ => 1 } qw(void char short int long float double signed unsigned _Bool bool _Complex __int128 _Float16 __fp16 __bf16 __float128 __ibm128 _Float128 _BitInt);

sub qual_add { my ($t, %q) = @_; return $t unless %q;
    my $k = $t->{k};
    if ($k eq 'arr') { return { %$t, of => qual_add($t->{of}, %q) } }
    if ($k eq 'fn') { return $t }
    my %n = %{ $t->{q} || {} }; $n{$_} = 1 for keys %q;
    return { %$t, q => \%n };
}
sub unqual { my ($t) = @_; return $t if $t->{k} eq 'arr' || !%{ $t->{q} || {} }; return { %$t, q => {} } }

# a parameter's type in a function type: no top-level qualifiers, arrays and functions as pointers
sub param_adjust {
    my ($t) = @_;
    return { k => 'ptr', to => $t->{of}, q => {} } if $t->{k} eq 'arr';
    return { k => 'ptr', to => $t, q => {} } if $t->{k} eq 'fn';
    unqual($t);
}

sub parse_specs {
    my %q; my @words; my $base;
    for (;;) {
        my $w = tk(); my $kd = tkind();
        last if $w eq '' || $w eq '*' || $w eq '(' || $w eq '[' || $w eq ')' || $w eq ',' || $w eq '...';
        if ($kd eq 'attr') {
            # a vector's size before its element type; another attribute (address_space, ...) kept as a word
            # (aarch64's NEON vectors, the same as gcc's of their size)
            if ($w =~ /^__attribute__\s*\(\(neon_(?:poly)?vector_type\((\d+)\)\)\)$/) { $tp++; my $n = $1; my $rest = parse_specs(); return qual_add({ k => 'vec', n => $n, of => $rest }, %q) }
            if ($w =~ /^__attribute__\s*\(\(__vector_size__\((\d+) \* sizeof\((.*)\)\)\)\)$/s) { $tp++; my ($n, $e) = ($1, $2); my $et = parse_type_str($e); my $rest = parse_specs(); return qual_add({ k => 'vec', n => $n, of => $rest // $et }, %q) }
            if ($w =~ /noreturn/) { last }
            # (x86_64's address spaces, __seg_fs and __seg_gs: a qualifier)
            if ($w =~ /^__attribute__\(\(address_space\(\d+\)\)\)$/) { $q{$w} = 1; $tp++; next }
            push @words, $w; $tp++; next;
        }
        if ($kd eq 'typeof') {
            $tp++;
            my $r;
            # (the innermost block's first: the same spelling is another type in another block, glibc's atomics' __typeof (*mem))
            for my $sc (reverse @typeof_scopes) { $r //= $sc->{$w} }
            $r //= $typeof{$w} // $typeof{ $w =~ s/^__typeof__/typeof/r } // typeof_inner($w);
            $base = $r;
            next;
        }
        if ($qualword{$w}) { $q{ $qualword{$w} } = 1; $tp++; next }
        if ($w eq '_Atomic' && tk(1) eq '(') {
            $tp += 2; my $in = parse_type(); $tp++;   # ')'
            $base = { k => 'atomic', of => $in, q => {} }; next;
        }
        if ($w eq 'struct' || $w eq 'union' || $w eq 'enum') {
            $tp++;
            my $name = '';
            for (;;) {
                if (tkind() eq 'anon') { $name = tk(); $tp++; last }
                if (tk() =~ /^[A-Za-z_]/ && tk(1) eq '::') { $tp += 2; next }  # a scope
                $name = tk(); $tp++; last;
            }
            $base = { k => 'tag', tag => $w, name => $name, q => {} }; next;
        }
        if ($basic{$w}) { push @words, $w; $tp++; next }
        # (aarch64's sizeless SVE types and clang's tuples of them: builtin names)
        if (!$base && !@words && $w =~ /^(?:__SV\w+_t|__clang_sv\w+_t|__mfp8)$/) { $tp++; $base = { k => 'b', name => $w, q => {} }; next }
        if (!$base && !@words && $w =~ /^[A-Za-z_]/) {
            $tp++;
            my $t = lookup_td($w);
            $base = $t // { k => 'b', name => "?$w", q => {} };
            next;
        }
        last;
    }
    if (@words) {
        my $n = join(' ', @words);
        $n = basic_name($n);
        $base = { k => 'b', name => $n, q => {} };
    }
    return undef unless $base;
    return qual_add($base, %q);
}
sub basic_name {
    my ($n) = @_;
    $n =~ s/\bsigned // if $n =~ /\bsigned (short|int|long|__int128)/;
    $n =~ s/^signed$/int/;
    $n =~ s/ int$// if $n =~ /^(unsigned |)(short|long|long long) int$/;
    $n = 'unsigned int' if $n eq 'unsigned';
    $n = '_Bool' if $n eq 'bool';
    $n = "_Complex $1" if $n =~ /^(.*) _Complex$/;
    $n;
}
sub typeof_inner {
    my ($w) = @_;
    # typeof (T) of a type: parse it
    my ($in) = $w =~ /^\S+?\s*\((.*)\)$/s;
    # typeof (name): the declared name's type
    return $declty{$1} if $in =~ /^\s*\(*\s*([A-Za-z_]\w*)\s*\)*\s*$/ && $declty{$1};
    # typeof (*name): what the name points to
    if ($in =~ /^\s*\*\s*\(*\s*([A-Za-z_]\w*)\s*\)*\s*$/ && $declty{$1} && $declty{$1}{k} eq 'ptr') { return $declty{$1}{to} }
    my @save = @tok; my $sp = $tp;
    my $r = eval { parse_type_str($in) };
    @tok = @save; $tp = $sp;
    return $r if $r && $r->{k} ne 'b' || ($r && $r->{name} !~ /^\?/);
    return { k => 'b', name => "?$w", q => {} };
}
sub lookup_td {
    my ($w) = @_;
    for (my $i = $#tdscope; $i >= 0; $i--) { return $tdscope[$i]{$w} if exists $tdscope[$i]{$w} }
    return undef;
}
sub parse_params {
    # after '(': parameters, then ')'
    my @p; my $var = 0; my $proto = 1;
    if (tk() eq ')') { $tp++; return (\@p, 0, 0) }
    for (;;) {
        if (tk() eq '...') { $var = 1; $tp++; last }
        my $t = parse_type();
        push @p, $t;
        last unless tk() eq ',';
        $tp++;
    }
    $tp++;   # ')'
    @p = () if @p == 1 && $p[0]{k} eq 'b' && $p[0]{name} eq 'void' && !%{ $p[0]{q} };
    (\@p, $var, $proto);
}
sub parse_absdecl {
    # returns a function from the base type to the declared type
    my @ptrs;
    while (tk() eq '*') {
        $tp++;
        my %q;
        while ($qualword{ tk() } || (tkind() eq 'attr')) { if (tkind() eq 'attr') { $q{ tk() } = 1 } else { $q{ $qualword{ tk() } } = 1 } $tp++ }
        push @ptrs, \%q;
    }
    my $inner = sub { $_[0] };
    if (tk() eq '(' && (tk(1) eq '*' || tk(1) eq '(' || tk(1) eq '^')) { $tp++; $inner = parse_absdecl(); $tp++ }
    my @suf;
    for (;;) {
        if (tk() eq '[') {
            $tp++; my $n = '';
            while (tk() ne ']' && tk() ne '') { $n .= tk(); $tp++ }
            $tp++;
            # (a variable length array's bound, an expression: [*])
            $n = '*' if $n ne '' && $n !~ /^\d+$/;
            push @suf, ['arr', $n];
        } elsif (tk() eq '(') {
            $tp++;
            my ($p, $var, $proto) = parse_params();
            my $nr = 0;
            while (tkind() eq 'attr') { $nr = 1 if tk() =~ /noreturn/; $tp++ }
            push @suf, ['fn', $p, $var, $proto, $nr];
        } else { last }
    }
    return sub {
        my ($t) = @_;
        for my $q (@ptrs) { $t = { k => 'ptr', to => $t, q => $q } }
        for my $s (reverse @suf) {
            if ($s->[0] eq 'arr') { $t = { k => 'arr', of => $t, n => $s->[1], q => {} } }
            else { $t = { k => 'fn', ret => unqual($t), p => [map { param_adjust($_) } @{ $s->[1] }], var => $s->[2], proto => $s->[3], nr => $s->[4], q => {} } }
        }
        $inner->($t);
    };
}
sub parse_type {
    my $b = parse_specs() // { k => 'b', name => '?', q => {} };
    my $d = parse_absdecl();
    # a trailing noreturn of a function type
    my $t = $d->($b);
    while (tkind() eq 'attr') { $t = { %$t, nr => 1 } if $t->{k} eq 'fn' && tk() =~ /noreturn/; $tp++ }
    $t;
}
sub parse_type_str {
    my ($s) = @_;
    local @tok = lex_type($s);
    local $tp = 0;
    my $t = parse_type();
    $t;
}
my %canon_cache;
sub canon {
    my ($s) = @_;
    return undef unless defined $s;
    return '<builtin>' if $s =~ /^</;
    my $t = parse_type_str($s);
    tstr($t);
}
sub qstr { my ($q) = @_; join(' ', (grep { $q->{$_} } qw(const volatile restrict)), sort grep { /^__attribute__/ } keys %$q) }
sub tstr {
    my ($t, $in) = @_;
    $in //= '';
    my $k = $t->{k};
    if ($k eq 'ptr') {
        my $q = join(' ', grep { $t->{q}{$_} } qw(const volatile restrict));
        my $attrs = join(' ', grep { /^__attribute__/ } sort keys %{ $t->{q} });
        my $p = '*' . ($q ne '' ? $q : '') . ($attrs ne '' ? " $attrs" : '');
        $p .= ' ' if ($q ne '' || $attrs ne '') && $in ne '';
        $p .= $in;
        $p = "($p)" if $t->{to}{k} eq 'arr' || $t->{to}{k} eq 'fn';
        return tstr($t->{to}, $p);
    }
    if ($k eq 'arr') { return tstr($t->{of}, "$in\[$t->{n}]") }
    if ($k eq 'fn') {
        my $ps = $t->{proto} ? (@{ $t->{p} } ? join(', ', map { tstr($_) } @{ $t->{p} }) . ($t->{var} ? ', ...' : '') : ($t->{var} ? '...' : 'void')) : '';
        return tstr($t->{ret}, "$in($ps)" . ($t->{nr} ? ' __attribute__((noreturn))' : ''));
    }
    my $b;
    if ($k eq 'b') { $b = $t->{name} }
    elsif ($k eq 'tag') { $b = "$t->{tag} $t->{name}" }
    elsif ($k eq 'atomic') { $b = '_Atomic(' . tstr($t->{of}) . ')' }
    elsif ($k eq 'vec') { $b = "__attribute__((__vector_size__($t->{n} * sizeof(" . tstr($t->{of}) . ')))) ' . tstr(unqual($t->{of})) }
    my $q = qstr($t->{q});
    $b = "$q $b" if $q ne '';
    return $in eq '' ? $b : $in =~ /^\[/ ? "$b$in" : "$b $in";
}
sub qt { my ($t) = @_; canon($t->{desugaredQualType} // $t->{qualType}) }
sub ty {
    my ($n) = @_;
    my $t = $n->{type} or return '-';
    my $s = $t->{desugaredQualType} // $t->{qualType};
    return '-' unless defined $s;
    return canon($s);
}

# ---- the walk ----
my @out;
sub line { push @out, join(' ', @_) }
my %skipkind = map { $_ => 1 } qw(EmptyDecl LabelDecl IndirectFieldDecl FileScopeAsmDecl UsingDecl);

sub decl_typeofs {
    # the typeof (...) spellings in a declaration, and their types (with a
    # map and a block: that block's own, not its inner blocks')
    my ($n, $map, $top) = @_;
    $map //= \%typeof;
    return unless ref $n eq 'HASH';
    for my $f (qw(type argType computeLHSType computeResultType)) {
        my $t = $n->{$f} or next;
        my $q = $t->{qualType} // next;
        if ($q =~ /^(?:typeof|__typeof__|typeof_unqual|__typeof_unqual__)\s*\(/ && defined $t->{desugaredQualType}) {
            # the whole spelling (no declarator after it) only
            my @t = lex_type($q);
            if (@t == 1) { $map->{ $t[0][1] } //= parse_type_str($t->{desugaredQualType}) }
        }
    }
    return if $top && ($n->{kind} // '') eq 'CompoundStmt';
    decl_typeofs($_, $map, 1) for @{ $n->{inner} || [] };
}
sub typedef_of {
    my ($n) = @_;
    my $t = $n->{type};
    my $q = $t->{qualType};
    my $r = parse_type_str($q);
    if ($r->{k} eq 'b' && $r->{name} =~ /^\?/ && defined $t->{desugaredQualType}) { $r = parse_type_str($t->{desugaredQualType}) }
    $tdscope[-1]{ $n->{name} } = $r;
}

sub walk {
    my ($n) = @_;
    return unless ref $n eq 'HASH' && %$n;
    my $k = $n->{kind} // '';
    if ($n->{isImplicit} && $k eq 'TypedefDecl') { typedef_of($n); return }
    return if $k =~ /Attr$/ || $k =~ /Type$/ || $n->{isImplicit} || $skipkind{$k};
    my @in = @{ $n->{inner} || [] };
    # (an InitListExpr with an array filler: the filler, then its inits, as array_filler)
    @in = @{ $n->{array_filler} }[1 .. $#{ $n->{array_filler} }] if $k eq 'InitListExpr' && $n->{array_filler};
    if ($k eq 'FunctionDecl') {
        # (its parameters first: a later one's typeof (an earlier one))
        for my $p (@in) { $declty{ $p->{name} } = parse_type_str($p->{type}{desugaredQualType} // $p->{type}{qualType}) if ($p->{kind} // '') eq 'ParmVarDecl' && defined $p->{name} && $p->{type} }
    }
    $declty{ $n->{name} } = parse_type_str($n->{type}{desugaredQualType} // $n->{type}{qualType}) if ($k eq 'VarDecl' || $k eq 'ParmVarDecl' || $k eq 'FunctionDecl') && defined $n->{name} && $n->{type};
    if ($k eq 'TypedefDecl') { typedef_of($n); line('typedef', $n->{name}, tstr($tdscope[-1]{ $n->{name} })); return }
    if ($k eq 'RecordDecl') {
        if ($n->{completeDefinition}) { line('record', $n->{tagUsed}, $n->{name} // '-') }
        walk($_) for @in;
        return;
    }
    if ($k eq 'FieldDecl') { line('field', $n->{name} // '-', ty($n), $n->{isBitfield} ? 'bits' : ()); walk($_) for @in; return }
    if ($k eq 'EnumDecl') { line('enum', $n->{name} // '-') if @in; walk($_) for @in; return }
    if ($k eq 'EnumConstantDecl') { line('enumerator', $n->{name}, ty($n)); walk($_) for @in; return }
    if ($k eq 'FunctionDecl') {
        push @tdscope, {};
        line('function', $n->{name}, ty($n), $n->{storageClass} // ());
        walk($_) for @in;
        pop @tdscope;
        return;
    }
    if ($k eq 'ParmVarDecl') { line('param', $n->{name} // '-', ty($n)); return }
    if ($k eq 'VarDecl') { line('var', $n->{name}, ty($n), $n->{storageClass} // ()); walk($_) for @in; return }
    if ($k eq 'StaticAssertDecl') { line('static_assert'); walk($in[0]); return }
    if ($k eq 'CompoundStmt') {
        my %m;
        decl_typeofs($_, \%m, 1) for @in;
        push @tdscope, {};
        push @typeof_scopes, \%m;
        walk($_) for @in;
        pop @typeof_scopes;
        pop @tdscope;
        return;
    }
    if ($k =~ /Stmt$/ || $k eq 'TranslationUnitDecl') { walk($_) for @in; return }
    # expressions
    if ($k eq 'ParenExpr') { walk($_) for @in; return }
    my @x;
    my $vc = $n->{valueCategory} // '-';
    if ($k eq 'ImplicitCastExpr') { line('ICE', $n->{castKind}, ty($n), $vc) }
    elsif ($k eq 'CStyleCastExpr') { line('CAST', $n->{castKind}, ty($n), $vc) }
    elsif ($k eq 'DeclRefExpr') { line('REF', $n->{referencedDecl}{name} // '-', ty($n), $vc) }
    elsif ($k eq 'IntegerLiteral') { line('INT', $n->{value}, ty($n)) }
    elsif ($k eq 'CharacterLiteral') { line('CHR', $n->{value}, ty($n)) }
    elsif ($k eq 'FloatingLiteral') { line('FLT', ty($n)) }
    elsif ($k eq 'StringLiteral') { line('STR', ty($n), $vc) }
    elsif ($k eq 'UnaryOperator') { line('UN', ($n->{isPostfix} ? 'post' : '') . $n->{opcode}, ty($n), $vc) }
    elsif ($k eq 'BinaryOperator') { line('BIN', $n->{opcode}, ty($n), $vc) }
    elsif ($k eq 'CompoundAssignOperator') { line('CASS', $n->{opcode}, ty($n), $vc, qt($n->{computeLHSType}), qt($n->{computeResultType})) }
    elsif ($k eq 'ConditionalOperator') { line('COND', ty($n), $vc) }
    elsif ($k eq 'BinaryConditionalOperator') { line('BCOND', ty($n), $vc) }
    elsif ($k eq 'OpaqueValueExpr') { line('OVE', ty($n), $vc); return }
    elsif ($k eq 'CallExpr') { line('CALL', ty($n), $vc) }
    elsif ($k eq 'MemberExpr') { line('MEM', ($n->{name} // '') eq '' ? '-' : $n->{name}, $n->{isArrow} ? '->' : '.', ty($n), $vc) }
    elsif ($k eq 'ArraySubscriptExpr') { line('IDX', ty($n), $vc) }
    elsif ($k eq 'UnaryExprOrTypeTraitExpr') { line('SIZEOF', $n->{name}, ty($n), $n->{argType} ? qt($n->{argType}) : ()) }
    elsif ($k eq 'ConstantExpr') { line('CONST', $n->{value} // '-', ty($n), $vc) }
    elsif ($k eq 'InitListExpr') { line('INIT', ty($n), $vc) }
    elsif ($k eq 'ImplicitValueInitExpr') { line('IVI', ty($n)) }
    elsif ($k eq 'CompoundLiteralExpr') { line('CLIT', ty($n), $vc) }
    elsif ($k eq 'StmtExpr') { line('STMTX', ty($n), $vc) }
    elsif ($k eq 'OffsetOfExpr') { line('OFFSETOF', ty($n)) }
    elsif ($k eq 'VAArgExpr') { line('VAARG', ty($n), $vc) }
    elsif ($k eq 'PredefinedExpr') { line('PREDEF', $n->{name}, ty($n), $vc) }
    elsif ($k eq 'AddrLabelExpr') { line('ADDRLABEL', ty($n)) }
    elsif ($k eq 'AtomicExpr') { line('ATOMIC', $n->{name} // '-', ty($n), $vc) }
    elsif ($k eq 'TypeTraitExpr') { line('TRAIT', ty($n)) }
    else { line($k, ty($n), $vc) }
    walk($_) for @in;
}

my @top = @{ $ast->{inner} || [] };
# the prelude's declarations first (clang-prelude.h: builtins of gcc's)
my $i = 0;
typedef_of($_) for grep { ($_->{kind} // '') eq 'TypedefDecl' && $_->{isImplicit} } @top;
$i++ while $i < @top && ($top[$i]{isImplicit} || (($top[$i]{kind} // '') eq 'FunctionDecl' && ($top[$i]{name} // '') =~ /^__builtin_/));
for my $d (@top[$i .. $#top]) {
    %typeof = ();
    decl_typeofs($d);
    walk($d);
}
print "$_\n" for @out;

# ---- the layouts, as csema writes them ----
my $skiplay = 0;
for my $l (split /\n/, $layouts) {
    if ($l =~ /^\s*0 \| (?:struct|union) (__NSConstantString_tag|__va_list_tag|__va_list)$/) { $skiplay = 1; next }
    if ($l =~ /^\*\*\* Dumping/) { $skiplay = 0 }
    next if $skiplay;
    next if $l =~ /^\*\*\* Dumping AST Record Layout/ || $l !~ /\S/;
    $l =~ s/\((?:unnamed|anonymous)(?: struct| union| enum)? at ([^()]*)\)/(anon at $1)/g;
    $l =~ s/(struct|union) \w+::\(anon/$1 (anon/g;
    if ($l =~ /^\s*(\S+) \| (\S.*)$/) {
        # a record: struct or union and its tag, or (anon at FILE:LINE:COL), or the typedef name of an anonymous one
        my ($o, $r) = ($1, $2);
        $r = "td $r" unless $r =~ /^(?:struct|union) /;
        print "layout $o $r\n";
        next;
    }
    if ($l =~ /^\s*\| \[sizeof=(\d+), align=(\d+)\]$/) { print "size $1 align $2\n"; next }
    if ($l =~ /^\s*(\S+) \| (\s*)(.*)$/) {
        # a field: its offset (bits of a bitfield), its depth, its name (the type left out: csema's fields have theirs above)
        my ($off, $ind, $rest) = ($1, $2, $3);
        my $name = $rest =~ /\s$/ ? '-' : $rest =~ /^(?:const |volatile )*(?:struct|union) \(anon at [^()]*\)\s*(\S*)$/ ? ($1 eq '' ? '-' : $1) : $rest =~ /(\S+)$/ ? $1 : '-';
        my $d = length($ind) / 2;
        print "at $off $d $name\n";
        next;
    }
    print "? $l\n";
}
