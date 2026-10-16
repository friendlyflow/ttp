#!/usr/bin/env perl
# c2ff.pl — C as ff: the definitions a program reaches in preprocessed C
# files (clang's JSON AST of each), written in ttpc's C layer, one C construct
# per ff construct (see language.ff.txt). Nothing is lowered: a construct the
# C layer has no form for stops the translation, named, with where it is.
#
#   perl c2ff.pl [--page name] tu.json=tu.i ... -- root ... > out.ff.txt
#   perl c2ff.pl --program tree tu.json=tu.i -- main > prog.ff.txt
#   perl c2ff.pl --types        (the type words, for a look)
#
# Each translation unit is its AST (from $C2FF_CLANG -x c -include
# src/glibc/clang-prelude.h -Xclang -ast-dump=json -fsyntax-only
# --target=riscv64-linux-gnu -std=gnu11 -w tu.i) and the .i it was made of
# (for what the AST leaves out: the resolver of an ifunc). The roots are the
# names to start from; what they call, the globals and types they use, comes
# too, from whichever unit defines it.
#
# Two idioms of glibc are recognized as what they are: its system call (a
# statement expression of register variables and scall) is ff's syscall, and
# __builtin_expect (a hint to the compiler) is its first argument; __extension__
# (which only quiets -pedantic) is what it marks; __builtin_constant_p is 1
# for a literal, else 0, as gcc may answer where it cannot tell.
# __builtin_memcpy and the like are calls of memcpy and the like, as gcc makes
# them where it does not expand them.
#
# With --program, what the roots reach is a program: its definitions on the
# page itself, after import / tree (glibc in ff, which has the rest), and a
# _start that exits with what main returns, which is what C's startup does
# for main without arguments.
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use JSON::PP;
use FF qw(node write_txt);

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

# The words a type run can be made of, besides the names of types.
my %scalar_word = map { $_ => 1 } (values %scalar, 'address', 'array');
my (%fntype, @fntypes);     # function types for pointers to functions
my %tagname;                # struct, union, enum tags and their ff names
my %typedef;                # typedef names and the types they stand for
my %typeof;                 # declared names and their types, for typeof
my %wanttag;                # the tags whose definitions the output needs
my (%fn, %var, %rec, %enumd, %alias, %ifunc);   # the units' definitions, by name
my %anon;                   # anonymous types of fields, by clang's spelling: [tag, ff name]

sub trim { my ($s) = @_; $s =~ s/^\s+|\s+$//g; $s }

# A C type string to a list of ff words. A pointer to a function names a
# function type of its own (fn1:, fn2:, ...), made once per spelling.
our $ctype_depth = 0;
sub ctype {
    my ($t) = @_;
    local $ctype_depth = $ctype_depth + 1;
    die "c2ff: a type that does not end: $t\n" if $ctype_depth > 100;
    $t = trim($t);
    $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
    $t = trim($t);
    $t =~ s/\s+/ /g;
    if ($t =~ /^(.*?)\s*\[(\d*)\]((?:\[\d+\])*)$/) {
        # T[] (a flexible array member, an extern array) has no elements of
        # its own: 0
        my ($base, $n, $rest) = ($1, $2, $3);
        return ('array', ctype($base . $rest), $n eq '' ? 0 : $n);
    }
    return ('address', fntype($1, $2)) if $t =~ /^(.*?)\s*\(\*\)\s*\((.*)\)$/;
    if ($t =~ /^(.*)\*$/) {
        my $base = expand($1);
        my ($r, $p) = split_fn($base);
        return defined $r ? ('address', fntype($r, $p)) : ('address', ctype($base));
    }
    return $scalar{$t} if exists $scalar{$t};
    return ctype($typedef{$t}) if exists $typedef{$t};
    return ctype($typeof{$1}) if $t =~ /^(?:typeof|__typeof__) \(\s*(\S+?)\s*\)$/ && exists $typeof{$1};
    if (my $a = $anon{ anon_key($t) // '' }) {
        my ($tag, $name) = @$a;
        $wanttag{$tag} = 1;
        return $tagname{$tag} //= $name;
    }
    if ($t =~ /^(struct|union|enum) (\S+)$/) {
        $wanttag{"$1 $2"} = 1;
        # C keeps tags apart from other names, ff does not: a tag that is
        # also a global's or a function's name is named with its kind
        return $tagname{"$1 $2"} //= $var{$2} || $fn{$2} ? "$2 $1" : ffname($2);
    }
    die "c2ff: no ff type for C's '$t'\n";
}

# A type with its typedef names and typeof (name) at the top replaced by what
# they stand for.
sub expand {
    my ($t) = @_;
    for (1 .. 50) {
        $t = trim($t);
        $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
        $t = trim($t);
        if (exists $typedef{$t}) { $t = $typedef{$t}; next }
        if ($t =~ /^(?:typeof|__typeof__) \(\s*(\S+?)\s*\)$/ && exists $typeof{$1}) { $t = $typeof{$1}; next }
        last;
    }
    $t;
}

# A function type, ret (params), as its return type and its parameters; else
# undef. The parameters are the last balanced ( ) at the end.
sub split_fn {
    my ($t) = @_;
    $t = trim($t);
    return undef unless $t =~ /\)$/;
    my $depth = 0;
    for (my $i = length($t) - 1; $i >= 0; $i--) {
        my $c = substr($t, $i, 1);
        $depth++ if $c eq ')';
        $depth-- if $c eq '(';
        next if $depth;
        my $ret = trim(substr($t, 0, $i));
        return undef if $ret eq '' || $ret =~ /\(\*\)$/;
        return ($ret, substr($t, $i + 1, length($t) - $i - 2));
    }
    undef;
}

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

sub qt { my ($n) = @_; my $t = $n->{type} or die "c2ff: no type\n"; $t->{desugaredQualType} // $t->{qualType} }

# ---- names ------------------------------------------------------------------
# ff reserves its words, type names and the registers of riscv64; a C name
# that is one gets a ' after it (type -> type'), which no C name has.

my %reserved = map { $_ => 1 } qw(
    if else while for return break continue comment address content syscall
    array struct union enum function sizeof alignof compile emit fail number
    target import workspace switch case default goto char short int long void
    type i8 i16 i32 i64 u8 u16 u32 u64 va_list va_start va_arg va_end va_copy
    alias ifunc asm items cast zero ra sp gp tp fp pc
), map({ ("x$_", "a$_", "s$_", "t$_", "f$_", "fa$_", "fs$_", "ft$_") } 0 .. 31);
my %renamed;
sub ffname {
    my ($n) = @_;
    return $n unless $reserved{$n};
    $renamed{$n} = "$n'";
}

if (@ARGV && $ARGV[0] eq '--types') {
    for my $t ('const char *', 'unsigned long', 'int (*)(const void *, const void *)',
               'char [16]', 'int [3][4]', 'void *', 'struct pt *', 'signed char', '_Bool') {
        printf "%-40s %s\n", $t, join(' / ', ctype($t));
    }
    exit 0;
}

# ---- the units --------------------------------------------------------------

my $page = 'glibc';
my $program;
my (@units, @roots);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--program') { $program = shift @ARGV; next }
    if ($a eq '--') { @roots = @ARGV; last }
    my ($json, $i) = split /=/, $a, 2;
    push @units, { json => $json, i => $i };
}
die "usage: c2ff.pl [--page name | --program tree] tu.json=tu.i ... -- root ...\n" unless @units && @roots;

my %enumof;                 # each enum constant's enum, as a tag
my $lastanon;               # the last anonymous record or enum at the top of a unit
my %recid;                  # complete records by id, the anonymous ones too
for my $u (@units) {
    open my $h, '<', $u->{json} or die "c2ff: cannot open $u->{json}: $!\n";
    my $ast = JSON::PP->new->decode(do { local $/; <$h> });
    close $h;
    open $h, '<', $u->{i} or die "c2ff: cannot open $u->{i}: $!\n";
    $u->{text} = do { local $/; <$h> };
    close $h;
    my $file = '';
    for my $d (@{ $ast->{inner} }) {
        $file = $d->{loc}{file} if $d->{loc} && $d->{loc}{file};
        $file = $d->{loc}{expansionLoc}{file} if $d->{loc} && $d->{loc}{expansionLoc} && $d->{loc}{expansionLoc}{file};
        $d->{file} = $file;
        next if $d->{isImplicit};
        $recid{$d->{id}} = $d if $d->{kind} eq 'RecordDecl' && $d->{completeDefinition};
        if ($d->{kind} eq 'EnumDecl') {
            # an enum's constants bring it in where they are used; one with no
            # name is named after its first constant
            my @c = grep { $_->{kind} eq 'EnumConstantDecl' } @{ $d->{inner} || [] };
            my $tag = defined $d->{name} ? "enum $d->{name}" : @c ? "enum $c[0]{name} enum" : undef;
            if (defined $tag) {
                $enumd{$tag} //= $d;
                $tagname{$tag} //= defined $d->{name} ? ffname($d->{name}) : "$c[0]{name} enum";
                $enumof{ $_->{name} } //= $tag for @c;
            }
        }
        # an anonymous struct, union or enum that is a global's type is named
        # after it (_nl_C_LC_CTYPE_class_upper struct)
        if ($d->{kind} =~ /^(RecordDecl|EnumDecl)$/ && ($d->{name} // '') eq '') { $lastanon = $d; next }
        if ($d->{kind} eq 'VarDecl' && $lastanon && defined $d->{name} && (my $key = anon_key($d->{type}{qualType} // ''))) {
            my $kind = $lastanon->{kind} eq 'EnumDecl' ? 'enum' : $lastanon->{tagUsed};
            my $tn = "$d->{name} $kind";
            $anon{$key} //= ["$kind $tn", $tn];
            if ($kind eq 'enum') { $enumd{"enum $tn"} //= $lastanon } else { $rec{"$kind $tn"} //= $lastanon; anon_fields($lastanon, $tn) }
        }
        my $name = $d->{name} // next;
        if ($d->{kind} eq 'TypedefDecl') {
            my $own = $d->{inner} && $d->{inner}[0]{ownedTagDecl};
            if ($own && ($own->{name} // '') eq '' && $recid{ $own->{id} }) {
                # a typedef of an anonymous struct or union: the record is its tag
                $rec{ $d->{type}{qualType} } //= $recid{ $own->{id} };
                anon_fields($recid{ $own->{id} }, $name);
                $typedef{$name} //= $d->{type}{qualType};
            } else {
                $typedef{$name} //= qt($d);
            }
        }
        $typeof{$name} //= qt($d) if $d->{kind} =~ /^(FunctionDecl|VarDecl)$/ && $d->{type};
        my @in = @{ $d->{inner} || [] };
        if ($d->{kind} eq 'FunctionDecl') {
            if (my ($a) = grep { $_->{kind} eq 'AliasAttr' } @in) { $alias{$name} = [$a->{aliasee}, $u]; next }
            if (my ($r) = grep { $_->{kind} eq 'IFuncAttr' } @in) { $ifunc{$name} = [$d, $u, resolver($u, $r)]; next }
            $fn{$name} //= [$d, $u] if grep { $_->{kind} eq 'CompoundStmt' } @in;
        } elsif ($d->{kind} eq 'VarDecl') {
            if (my ($a) = grep { $_->{kind} eq 'AliasAttr' } @in) { $alias{$name} = [$a->{aliasee}, $u]; next }
            $var{$name} //= [$d, $u] if ($d->{storageClass} // '') ne 'extern';
        } elsif ($d->{kind} eq 'RecordDecl' && $d->{completeDefinition}) {
            $rec{"$d->{tagUsed} $name"} //= $d;
            anon_fields($d, $name);
        } elsif ($d->{kind} eq 'EnumDecl') {
            $enumd{"enum $name"} //= $d;
        }
    }
}

# The anonymous enum, struct or union that is the type of a field gets a name
# from where it stands: the record's, then the field's (__locale_data
# alloc). Records inside records too.
sub anon_fields {
    my ($r, $rname) = @_;
    my $last;
    for my $k (@{ $r->{inner} || [] }) {
        if ($k->{kind} =~ /^(RecordDecl|EnumDecl)$/) {
            $last = $k;
            # a named record or enum inside a record is seen as one outside it, as in C
            if (($k->{name} // '') ne '') {
                if ($k->{kind} eq 'EnumDecl') { $enumd{"enum $k->{name}"} //= $k }
                elsif ($k->{completeDefinition}) { $rec{"$k->{tagUsed} $k->{name}"} //= $k; anon_fields($k, $k->{name}) }
            }
            next;
        }
        next unless $k->{kind} eq 'FieldDecl' && defined $k->{name} && $last && ($last->{name} // '') eq '';
        my $key = anon_key($k->{type}{qualType} // '') // next;
        my $kind = $last->{kind} eq 'EnumDecl' ? 'enum' : $last->{tagUsed};
        my $name = "$rname $k->{name}";
        $anon{$key} = ["$kind $name", $name];
        if ($kind eq 'enum') { $enumd{"enum $name"} //= $last } else { $rec{"$kind $name"} //= $last; anon_fields($last, $name) }
        undef $last;
    }
}

# Clang spells one anonymous type in more than one way (enum (unnamed enum at
# ../include/../locale/localeinfo.h:54:3), enum __locale_data::(unnamed at
# ../locale/localeinfo.h:54:3)): what they share is where it is.
sub anon_key { $_[0] =~ /\((?:unnamed|anonymous)(?: \w+)? at (?:[^():]*\/)?([^\/():]+):(\d+):(\d+)\)/ ? "$1:$2:$3" : undef }

# The resolver of an ifunc: clang's JSON does not print it, the .i has it.
sub resolver {
    my ($u, $attr) = @_;
    my $b = $attr->{range}{begin}{offset} // $attr->{range}{begin}{expansionLoc}{offset};
    defined $b or die "c2ff: an ifunc without its place in the .i\n";
    my $s = substr($u->{text}, $b, 400);
    $s =~ /ifunc\s*\(\s*((?:"[^"]*"\s*)+)\)/ or die "c2ff: no resolver in '$s'\n";
    join '', $1 =~ /"([^"]*)"/g;
}

# ---- expressions ----------------------------------------------------------------

my (@out, %done, @todo);
our %local;                 # the ids of the locals and parameters of the function
our %label;                 # the names of its labels, by id
sub want { my ($n) = @_; push @todo, $n unless $done{$n}++ }

sub where { my ($n) = @_; my $l = $n->{range}{begin} // $n->{loc} // {}; $l = $l->{expansionLoc} // $l; ($l->{file} // '') . ':' . ($l->{line} // '?') }
our $cur_fn = '';           # the function being translated, for messages
sub stop { my ($what, $n) = @_; die "c2ff: not yet: $what (at " . where($n) . ($cur_fn ne '' ? ", in $cur_fn" : '') . ")\n" }

my %prec = ('=' => 1, '+=' => 1, '-=' => 1, '*=' => 1, '/=' => 1, '%=' => 1, '&=' => 1, '|=' => 1,
    '^=' => 1, '<<=' => 1, '>>=' => 1, '||' => 2, '&&' => 3, '|' => 4, '^' => 5, '&' => 6,
    '==' => 7, '!=' => 7, '<' => 8, '>' => 8, '<=' => 8, '>=' => 8, '<<' => 9, '>>' => 9,
    '+' => 10, '-' => 10, '*' => 11, '/' => 11, '%' => 11);
my %isop = map { $_ => 1 } (keys %prec, qw(! ~ ++ --));

sub kids { @{ $_[0]{inner} || [] } }
sub strip {     # through what means nothing in ff
    my ($n) = @_;
    $n = (kids($n))[0] while $n->{kind} =~ /^(ImplicitCastExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/;
    $n;
}

# An item: sibling nodes that ttpc reads as one expression. One that would
# begin with an operator goes in a :, so that it does not join the one
# before it.
sub item { my @n = @_; @n && $isop{ $n[0]{content} } && !@{ $n[0]{children} } ? (node(':', @n)) : @n }
# One node: the value in a : unless it is one already.
sub atom { my @e = expr($_[0]); @e == 1 ? @e : node(':', @e) }

sub expr {
    my ($n) = @_;
    my $k = $n->{kind};
    # a function as a value is its address (a function name alone is a call in ff)
    return node('address', expr((kids($n))[0])) if $k eq 'ImplicitCastExpr' && ($n->{castKind} // '') eq 'FunctionToPointerDecay';
    return expr((kids($n))[0]) if $k =~ /^(ImplicitCastExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/;
    return node(':', expr((kids($n))[0])) if $k eq 'ParenExpr';
    return node($n->{value}) if $k eq 'IntegerLiteral' || $k eq 'CharacterLiteral';
    return node('address', node('char'), texts($n)) if $k eq 'StringLiteral';
    if ($k eq 'DeclRefExpr') {
        my $d = $n->{referencedDecl};
        $wanttag{ $enumof{ $d->{name} } } = 1 if $d->{kind} eq 'EnumConstantDecl' && $enumof{ $d->{name} };
        # a function, or a variable that is not this function's own: a global
        want($d->{name}) if $d->{kind} eq 'FunctionDecl' || ($d->{kind} eq 'VarDecl' && !$local{ $d->{id} });
        return node(ffname($d->{name}));
    }
    if ($k eq 'BinaryOperator' || $k eq 'CompoundAssignOperator') {
        my $op = $n->{opcode};
        my ($l, $r) = kids($n);
        return node(':', item(expr($l)), item(expr($r))) if $op eq ',';
        $prec{$op} or stop("the operator $op", $n);
        return (operand($l, $prec{$op}, 0), node($op), operand($r, $prec{$op}, 1));
    }
    if ($k eq 'UnaryOperator') {
        my $op = $n->{opcode};
        my ($e) = kids($n);
        return node('content', expr($e)) if $op eq '*';
        return node('address', expr($e)) if $op eq '&';
        return (node($op), atom($e)) if $op eq '-' || $op eq '!' || $op eq '~';
        return $n->{isPostfix} ? (atom($e), node($op)) : (node($op), atom($e)) if $op eq '++' || $op eq '--';
        return expr($e) if $op eq '+';
        return expr($e) if $op eq '__extension__';     # only quiets gcc's -pedantic
        stop("the operator $op", $n);
    }
    if ($k eq 'CStyleCastExpr') {
        return node('cast:', map({ node($_) } ctype(qt($n))), item(expr((kids($n))[0])));
    }
    if ($k eq 'ArraySubscriptExpr' || $k eq 'MemberExpr') {
        # a path from a variable: its elements and fields in a row, xs i x
        my @path;
        my $base = $n;
        while (1) {
            if ($base->{kind} eq 'MemberExpr') { unshift @path, node(ffname($base->{name})); $base = strip((kids($base))[0]); next }
            if ($base->{kind} eq 'ArraySubscriptExpr' && strip((kids($base))[0])->{kind} =~ /^(DeclRefExpr|MemberExpr|ArraySubscriptExpr)$/) {
                my ($b, $i) = kids($base);
                unshift @path, item(expr($i));
                $base = strip($b);
                next;
            }
            last;
        }
        # parentheses around the base say nothing more here, and a : holds
        # only its items
        $base = strip((kids($base))[0]) while $base->{kind} eq 'ParenExpr';
        if ($base->{kind} eq 'DeclRefExpr' && @path) {
            my ($b) = expr($base);      # which also wants a global
            push @{ $b->{children} }, @path;
            return $b;
        }
        # a path from an expression: after a . among the base node's children
        if (@path && $base != $n) {
            my @b = expr($base);
            @b == 1 or stop('a path from ' . $base->{kind} . ' of several nodes', $n);
            push @{ $b[0]{children} }, node('.'), @path;
            return @b;
        }
        if ($k eq 'ArraySubscriptExpr' && $base == $n) {
            my ($b, $i) = kids($n);
            return node('content', node(':', expr($b), node('+'), item(expr($i))));
        }
        stop('a path from ' . $base->{kind}, $n);
    }
    if ($k eq 'CallExpr') {
        my ($callee, @args) = kids($n);
        my $c = strip($callee);
        # (*f) (...) calls what f points at, as f (...) does
        $c = strip((kids($c))[0]) while $c->{kind} eq 'ParenExpr' || ($c->{kind} eq 'UnaryOperator' && $c->{opcode} eq '*');
        $c->{kind} eq 'DeclRefExpr' or stop('a call through ' . $c->{kind}, $n);
        my $name = $c->{referencedDecl}{name};
        return expr($args[0]) if $name eq '__builtin_expect';
        if ($name eq '__builtin_constant_p') {
            # gcc's answer where it cannot tell is 0, and code that asks must
            # mean the same either way: 1 for a literal, else 0
            return node(strip($args[0])->{kind} =~ /^(IntegerLiteral|CharacterLiteral)$/ ? 1 : 0);
        }
        # a builtin of a libc function is a call of it, as gcc makes one
        # where it does not expand the builtin
        $name = $1 if $name =~ /^__builtin_((?:mem|str|stp)\w+)$/;
        stop("the builtin $name", $n) if $name =~ /^__builtin_/;
        want($name) if $c->{referencedDecl}{kind} eq 'FunctionDecl' && $name !~ /^__builtin_/;
        return node(ffname($name), map { item(expr($_)) } @args);
    }
    if ($k eq 'ConditionalOperator') {
        my ($c, $a, $b) = kids($n);
        return (node('if', item(expr($c)), item(expr($a))), node('else', item(expr($b))));
    }
    if ($k eq 'StmtExpr') {
        my ($cs) = kids($n);
        my @sys = syscall_idiom($cs);
        return @sys ? @sys : node(':', body($cs));
    }
    if ($k eq 'CompoundLiteralExpr') {
        my @t = ctype(qt($n));
        @t == 1 && !$scalar_word{$t[0]} or stop('a compound literal of ' . qt($n), $n);
        return node($t[0], init((kids($n))[0]));
    }
    if ($k eq 'UnaryExprOrTypeTraitExpr') {
        my $w = $n->{name};
        my $t = $n->{argType} ? ($n->{argType}{desugaredQualType} // $n->{argType}{qualType}) : qt((kids($n))[0]);
        $w = 'alignof' if $w eq '__alignof' || $w eq '_Alignof';   # GNU's and C11's spellings, one on riscv64
        return node($w, map { node($_) } ctype($t)) if $w eq 'sizeof' || $w eq 'alignof';
        stop("the trait $w", $n);
    }
    stop($k, $n);
}

# A string literal's bytes, C's escapes undone, as text leaves of at most 255
# bytes each (a node's text holds no more), which ff reads in a row as one,
# like C's "ab" "cd".
my %esc = (n => "\n", t => "\t", r => "\r", a => "\a", b => "\b", f => "\f", v => "\x0b",
    '"' => '"', "'" => "'", '\\' => '\\', '?' => '?', e => "\e");
sub bytes {
    my ($n) = @_;
    my $s = $n->{value};
    $s =~ s/^"|"$//g;
    $s =~ s/\\(?:([0-7]{1,3})|x([0-9a-fA-F]+)|(.))/defined $1 ? chr(oct $1) : defined $2 ? chr(hex $2) : ($esc{$3} \/\/ stop("the escape \\$3", $n))/ge;
    $s;
}
# Text leaves hold UTF-8 (an ff node's text is): the pieces, or nothing when
# they cannot be text. Under address / char any leaf is text; among a char
# array's items one that reads as a number is a number ($array).
sub pieces {
    my ($s, $array) = @_;
    my @p = unpack '(a255)*', $s;
    for (@p) { return () unless utf8::decode(my $u = $_) && !($array && /^-?(?:0x[0-9a-f]+|\d+)$/i) }
    @p;
}
sub texts {
    my ($n) = @_;
    my $s = bytes($n);
    return node('') if $s eq '';
    my @p = pieces($s) or stop('a text that is not UTF-8 text', $n);
    map { node($_) } @p;
}
# What sets a char array: its text, or where that cannot be text, its bytes
# as numbers; the zeros at the end are the rest, which is 0.
sub array_text {
    my ($n) = @_;
    my $s = bytes($n);
    $s =~ s/\0+$//;
    return () if $s eq '';
    my @p = pieces($s, 1);
    @p ? map({ node($_) } @p) : map({ node($_) } unpack 'C*', $s);
}
# A string literal that sets a char array: under no decay to an address.
sub bare_string {
    my ($n) = @_;
    $n = (kids($n))[0] while $n->{kind} eq 'ParenExpr' || ($n->{kind} eq 'ImplicitCastExpr' && ($n->{castKind} // '') ne 'ArrayToPointerDecay');
    $n->{kind} eq 'StringLiteral' ? $n : undef;
}
# Items for a node that holds $room more children: as they are, or in items
# groups of at most 255 when there are more.
sub grouped {
    my ($room, @items) = @_;
    return @items if @items <= $room;
    my @g;
    push @g, node('items', splice @items, 0, 255) while @items;
    @g;
}

# An operand of a binary operator: in a : where it binds less than the
# operator (C's own parentheses are a : already).
sub operand {
    my ($n, $p, $right) = @_;
    my $s = strip($n);
    my @e = expr($n);
    if (($s->{kind} eq 'BinaryOperator' || $s->{kind} eq 'CompoundAssignOperator') && $s->{opcode} ne ',') {
        my $q = $prec{ $s->{opcode} } // 0;
        return node(':', @e) if $q < $p || ($right && $q == $p && $p != 1);
    }
    return node(':', @e) if $s->{kind} eq 'ConditionalOperator';
    @e;
}

our $cur_unit;
# The LabelStmts under a node.
sub labels { my ($n) = @_; (($n->{kind} // '') eq 'LabelStmt' ? $n : ()), map { labels($_) } kids($n) }
# The ParmVarDecls and VarDecls under a node (a function's own).
sub locals { my ($n) = @_; (($n->{kind} // '') =~ /^(ParmVarDecl|VarDecl)$/ ? $n : ()), map { locals($_) } kids($n) }

# glibc's INTERNAL_SYSCALL on riscv: register variables a7 = number, a0 ...
# = the arguments, the asm scall, the result from a0.
sub syscall_idiom {
    my ($cs) = @_;
    my @st = kids($cs);
    my ($inner) = grep { $_->{kind} eq 'CompoundStmt' } @st;
    return () unless $inner && grep { $_->{kind} eq 'GCCAsmStmt' } kids($inner);
    my %reg;
    for my $s (grep { $_->{kind} eq 'DeclStmt' } kids($inner)) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            next unless $lab && $init;
            # glibc's macro names each variable after its register: __a7, __a0, ...
            my $reg = $lab->{label} // (($v->{name} // '') =~ /^__(a[0-7])$/ ? $1 : undef);
            $reg{$reg} = $init if defined $reg;
        }
    }
    return () unless $reg{a7};
    my %local;      # the _argN of the outer block, by name
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st) {
        for my $v (kids($s)) { my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v); $local{ $v->{name} } = $init if $init }
    }
    my @args;
    for my $i (0 .. 5) {
        my $e = $reg{"a$i"} or last;
        my $s = strip($e);
        $e = $local{ $s->{referencedDecl}{name} } if $s->{kind} eq 'DeclRefExpr' && $local{ $s->{referencedDecl}{name} };
        push @args, item(expr($e));
    }
    node('syscall', item(expr($reg{a7})), @args);
}

# ---- statements ---------------------------------------------------------------

# A function's statements: a local declared before any statement without a
# value would be one more parameter; a comment ends the parameters.
sub body {
    my ($cs, $fnhead) = @_;
    my @out;
    my $lead = $fnhead;
    for my $s (kids($cs)) {
        my @st = stmt($s);
        if ($lead && $s->{kind} eq 'DeclStmt' && grep { $_->{content} =~ /:$/ && !has_value($_) } @st) {
            push @out, node('comment', node('locals'));
            $lead = 0;
        }
        $lead = 0 unless $s->{kind} eq 'DeclStmt';
        push @out, @st;
    }
    @out;
}
# A declaration with a value: something after its type words.
sub has_value { my ($d) = @_; my @c = @{ $d->{children} }; scalar grep { @{ $_->{children} } || !$scalar_word{ $_->{content} } } @c }

sub stmt {
    my ($n) = @_;
    my $k = $n->{kind};
    return node(':', body($n)) if $k eq 'CompoundStmt';
    # a local extern declaration names the global: nothing of its own
    return map { ($_->{storageClass} // '') eq 'extern' ? do { want($_->{name}); () } : decl($_) } kids($n) if $k eq 'DeclStmt';
    return node('return', $n->{inner} ? item(expr((kids($n))[0])) : ()) if $k eq 'ReturnStmt';
    return ifs('if', $n) if $k eq 'IfStmt';
    if ($k eq 'WhileStmt') { my ($c, $b) = kids($n); return node('while', item(expr($c)), sub_body($b)) }
    if ($k eq 'DoStmt') { my ($b, $c) = kids($n); return node('do while', item(expr($c)), sub_body($b)) }
    if ($k eq 'ForStmt') {
        # clang's parts: init, a condition variable, cond, inc, body ({} when absent)
        my ($i, undef, $c, $s, $b) = kids($n);
        return node('for', clause($i, 1), clause($c), clause($s, 1), sub_body($b));
    }
    if ($k eq 'SwitchStmt') {
        my ($v, $b) = kids($n);
        return node('switch', item(expr($v)), cases($b->{kind} eq 'CompoundStmt' ? kids($b) : $b));
    }
    return labelled($n) if $k eq 'CaseStmt' || $k eq 'DefaultStmt';
    return node(ffname($n->{name}) . ':', stmt((kids($n))[0])) if $k eq 'LabelStmt';
    return node('goto', node(ffname($label{ $n->{targetLabelDeclId} } // stop('a goto to no label', $n)))) if $k eq 'GotoStmt';
    return node('break') if $k eq 'BreakStmt';
    return node('continue') if $k eq 'ContinueStmt';
    return () if $k eq 'NullStmt';
    return effect($n) if $k =~ /Expr$|Operator$/;
    stop($k, $n);
}
# An expression for what it does, its value unused: x++ is ++x then.
sub effect {
    my ($n) = @_;
    my $s = strip($n);
    return (atom((kids($s))[0]), node($s->{opcode})) if $s->{kind} eq 'UnaryOperator' && $s->{opcode} =~ /^(\+\+|--)$/;
    return node(':', map { effect($_) } kids($s)) if $s->{kind} eq 'BinaryOperator' && $s->{opcode} eq ',';
    item(expr($n));
}
# One part of a for: one item (a declaration, or an expression), an empty
# : when there is none.
sub clause {
    my ($n, $effect) = @_;
    return node(':') unless $n && $n->{kind};
    return stmt($n) if $n->{kind} eq 'DeclStmt';
    $effect ? effect($n) : item(expr($n));
}
# The body of a switch: each case holds the statements up to the next one,
# as clang has them after it; case 2: case 3: is two cases, the first empty.
sub cases {
    my @out;
    for my $s (@_) {
        if ($s->{kind} eq 'CaseStmt' || $s->{kind} eq 'DefaultStmt') { push @out, labelled($s); next }
        stop('a statement before the first case', $s) unless @out;
        push @{ $out[-1]{children} }, stmt($s);
    }
    @out;
}
# A case or default and what clang puts under it: its first statement, or
# the next case.
sub labelled {
    my ($n) = @_;
    my @k = kids($n);
    my $sub = pop @k;
    my @head = $n->{kind} eq 'CaseStmt' ? node('case', item(expr($k[0]))) : node('default');
    return (@head, labelled($sub)) if $sub->{kind} eq 'CaseStmt' || $sub->{kind} eq 'DefaultStmt';
    push @{ $head[0]{children} }, stmt($sub);
    @head;
}
sub sub_body { my ($s) = @_; $s->{kind} eq 'CompoundStmt' ? body($s) : stmt($s) }
sub ifs {
    my ($word, $n) = @_;
    my @k = kids($n);
    my ($c, $t, $e) = $n->{hasElse} ? @k : (@k, undef);
    my @r = node($word, item(expr($c)), sub_body($t));
    push @r, ($e->{kind} eq 'IfStmt' ? ifs('else if', $e) : node('else', sub_body($e))) if $e;
    @r;
}

sub decl {
    my ($v, $global) = @_;
    $v->{kind} eq 'VarDecl' or stop('a declaration of ' . $v->{kind}, $v);
    my @t = ctype(qt($v));
    my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
    my @i = $init ? init($init) : ();
    # a global takes each item as one node
    @i = node(':', @i) if $global && @i > 1 && strip($init)->{kind} ne 'InitListExpr' && !bare_string($init);
    # under address / char a leaf is text: a value that is a leaf goes in a :
    @i = node(':', @i) if "@t" =~ /^address (char|u8)$/ && @i == 1 && !@{ $i[0]{children} } && !bare_string($init);
    node(ffname($v->{name}) . ':', map({ node($_) } @t), grouped(255 - @t, @i));
}
sub init {
    my ($n) = @_;
    my $s = strip($n);
    return init_items($s) if $s->{kind} eq 'InitListExpr';
    if (my $str = bare_string($n)) { return array_text($str) }
    item(expr($n));
}
# The items of an initializer list. Clang fills the fields not named with
# ImplicitValueInitExpr: at the end they are the zero ff gives the rest, in
# between a 0 (or an empty : for an aggregate) keeps the places.
sub init_items {
    my ($l) = @_;
    my @k = kids($l);
    # clang's JSON puts a list's items after its filler, in array_filler, when
    # it has one; an implicit filler is the zero ff gives the rest
    if (!@k && $l->{array_filler}) {
        my ($f, @i) = @{ $l->{array_filler} };
        $f->{kind} eq 'ImplicitValueInitExpr' or stop('an array filler of ' . $f->{kind}, $l);
        @k = @i;
    }
    pop @k while @k && $k[-1]{kind} eq 'ImplicitValueInitExpr';
    map { init_item($_) } @k;
}
sub init_item {
    my ($n) = @_;
    my $s = strip($n);
    return node(':', grouped(255, init_items($s))) if $s->{kind} eq 'InitListExpr';
    if (my $str = bare_string($n)) { return array_text($str) }
    if ($s->{kind} eq 'ImplicitValueInitExpr') { my @t = ctype(qt($s)); return @t == 1 && $scalar_word{$t[0]} || $t[0] eq 'address' ? node(0) : node(':') }
    # an item of a list is one node
    my @e = item(expr($n));
    @e > 1 ? node(':', @e) : @e;
}

# ---- definitions ----------------------------------------------------------------

sub function {
    my ($name, $d) = @_;
    local $cur_fn = $name;
    local %local = map { ($_->{id} => 1) } locals($d);
    local %label = map { ($_->{declId} => $_->{name}) } labels($d);
    my ($ret) = split_fn(expand(qt($d)));
    defined $ret or die "c2ff: not a function type: " . qt($d) . "\n";
    my @p = grep { $_->{kind} eq 'ParmVarDecl' } kids($d);
    my ($cs) = grep { $_->{kind} eq 'CompoundStmt' } kids($d);
    my $i = 0;
    node(ffname($name) . ':', map({ node($_) } ctype($ret)),
        map({ $i++; node(ffname($_->{name} // "p$i") . ':', map { node($_) } ctype(qt($_))) } @p),
        node('comment', node("glibc-2.44 $d->{file}")),
        body($cs, 1));
}

sub next_name {
    return shift @todo if @todo;
    while (@roots) { my $r = shift @roots; return $r unless $done{$r}++ }
    undef;
}
while (defined(my $name = next_name())) {
    if (my $a = $alias{$name}) { push @out, node(ffname($name) . ':', node('alias'), node(ffname($a->[0]))); want($a->[0]); next }
    if (my $f = $ifunc{$name}) {
        my ($d, $u, $r) = @$f;
        my ($ret, $ps) = split_fn(expand(qt($d)));
        defined $ret or die "c2ff: the type of $name: " . qt($d) . "\n";
        my $i = 0;
        push @out, node(ffname($name) . ':', node('ifunc'), node(ffname($r)), map({ node($_) } ctype($ret)),
            map({ $i++; node("p$i:", map { node($_) } ctype($_)) } params($ps)));
        want($r);
        next;
    }
    if (my $f = $fn{$name}) { local $cur_unit = $f->[1]; push @out, function($name, $f->[0]); next }
    if (my $v = $var{$name}) { push @out, decl($v->[0], 1); next }
    warn "c2ff: no definition of $name, left out\n";
}

# the types the definitions use, before them
my @types;
# the function types and the tags bring in more of each other: until none
# is new
my ($fdone, %tdone) = (0);
while ($fdone < @fntypes || grep { !$tdone{$_} } keys %wanttag) {
while ($fdone < @fntypes) {
    my ($name, $ret, $ps) = @{ $fntypes[$fdone++] };
    my $i = 0;
    push @types, node("$name:", node('function'), map({ node($_) } ctype($ret)),
        map({ $i++; node("p$i:", map { node($_) } ctype($_)) } params($ps)));
}
while (my @t = grep { !$tdone{$_} } sort keys %wanttag) {
    for my $tag (@t) {
        $tdone{$tag} = 1;
        my $d = $rec{$tag} // $enumd{$tag} or do { warn "c2ff: no definition of $tag\n"; next };
        my ($kind) = $tag =~ /^(\S+)/;
        if ($kind eq 'enum') {
            # a constant keeps its value where C gives it one (clang has worked it out)
            unshift @types, node($tagname{$tag} . ':', node('enum'), grouped(254, map {
                my ($v) = grep { $_->{kind} eq 'ConstantExpr' } kids($_);
                node(ffname($_->{name}) . ':', defined $v && defined $v->{value} ? node($v->{value}) : ())
            } grep { $_->{kind} eq 'EnumConstantDecl' } kids($d)));
        } else {
            unshift @types, node($tagname{$tag} . ':', node($kind),
                map { node(ffname($_->{name}) . ':', map { node($_) } ctype(qt($_))) } grep { $_->{kind} eq 'FieldDecl' } kids($d));
        }
    }
}
}

if (defined $program) {
    print write_txt(node('import', node($program)), @types, @out,
        node('_start:', node('void'), node('syscall', node('SYS_exit'), node('main'))));
} else {
    print write_txt(node("$page:", @types, @out));
}
warn "c2ff: renamed: " . join(', ', map { "$_ -> $renamed{$_}" } sort keys %renamed) . "\n" if %renamed;
