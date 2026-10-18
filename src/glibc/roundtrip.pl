#!/usr/bin/env perl
# roundtrip.pl — glibc in ff against the C it was made of: for each C
# function of a milestone, clang's AST of what ff2c.pl writes back from the ff
# must be clang's AST of the function in glibc's .i, both normalized alike.
#
#   perl roundtrip.pl names.txt back.json
#
# names.txt is ff2c's (each body's C name, its name in glibc and its .i;
# every global's and function's name), back.json clang's AST of ff2c's C.
# Each .i's AST is the .json beside it. It prints each function that differs,
# where, and a count; it exits 1 if any differs.
#
# Normalized away, on both sides: parentheses, the casts that change nothing
# (lvalue to value, decay, no-op, one between types of one class: long and
# long long), a[i] (as *(a + i)), braces around one statement, the layout of
# case and label statements. On glibc's side, its idioms that ff writes in a
# form of its own, as c2ff.pl does: INTERNAL_SYSCALL (a statement expression
# of register variables and scall) is ff's syscall, __builtin_expect its
# first argument, __builtin_constant_p 1 for a literal and 0 else, an asm
# statement a call of the asm function c2ff makes of it (whose value, a
# long, and arguments have no C type), an atomic builtin a
# call of libatomic's function, offsetof the address of the field of a
# null pointer, a conversion of a floating value to _Bool a compare with 0,
# a function's statics globals of their own. Names come back through
# names.txt (c2ff's own names for a unit's statics, ' after reserved words).
#
# A host tool, not part of ttpc.
use strict;
use warnings;
my $json = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };

my ($namesfile, $backjson) = @ARGV;
die "usage: roundtrip.pl names.txt back.json\n" unless defined $backjson;

my (@bodies, %orig, %asmfn);
open my $h, '<', $namesfile or die "roundtrip: $namesfile: $!\n";
while (<$h>) {
    chomp;
    my ($k, $cid, $o, $unit) = split /\t/;
    if ($k eq 'asm') { $asmfn{$o} = 1; next }
    $orig{$cid} = $o;
    push @bodies, [$cid, $o, $unit, $k] if $k eq 'body' || $k eq 'failed';
}
close $h;

sub load { my ($f) = @_; open my $h, '<', $f or die "roundtrip: $f: $!\n"; local $/; $json->decode(<$h>) }
sub kids { @{ $_[0]{inner} || [] } }

# ---- types --------------------------------------------------------------------

our %tdef;                 # the typedefs of the AST at hand
our %typeof;               # what its typeof (expression) types are, where clang says
our %declty;               # the types of its functions and globals, for typeof (name)
my %cls = ('char' => 'char', 'signed char' => 'i8', 'unsigned char' => 'u8', 'short' => 'i16', 'unsigned short' => 'u16',
    'int' => 'i32', 'unsigned int' => 'u32', 'long' => 'i64', 'long long' => 'i64', 'unsigned long' => 'u64',
    'unsigned long long' => 'u64', '_Bool' => 'u8', 'float' => 'float', 'double' => 'double',
    'long double' => 'ldouble', 'void' => 'void', '__builtin_va_list' => 'va', 'va_list' => 'va', '__va_list_tag' => 'va');
sub tstr {
    my ($s) = @_;
    $s = noattr($s);
    $s =~ s/\b(const|volatile|restrict|__restrict)\b//g;
    $s =~ s/\s+/ /g;
    $s =~ s/^ | $//g;
    $s =~ s/ (\*|\[)/$1/g;
    $s =~ s/\bsigned (char)\b/signed $1/;
    $s =~ s/\b(?:long int)\b/long/g;
    $s =~ s/\b(?:short int)\b/short/g;
    $s =~ s/\bunsigned\b(?! (?:char|short|int|long))/unsigned int/g;
    return tstr($tdef{$s}) if exists $tdef{$s};
    return tstr($typeof{$s}) if exists $typeof{$s};
    # (typeof (name): the type of what the unit declares by that name)
    return tstr($declty{$1}) if $s =~ /^(?:typeof|__typeof__) \(\s*(\w+)\s*\)$/ && exists $declty{$1};
    return '?typeof' if $s =~ /^(?:typeof|__typeof__) \(/ && $s =~ /\)$/;
    # (an anonymous record's spelling, union __mbstate_t::(unnamed at f.h:3:5), is a record)
    return 'rec' if $s =~ /^(?:struct|union)\b[^*\[]*\((?:unnamed|anonymous)\b[^()]*\)$/;
    return 'enum' if $s =~ /^enum\b[^*\[]*\((?:unnamed|anonymous)\b[^()]*\)$/;
    return 'fnptr' if $s =~ /\(\*+\)\s*\(/ || $s =~ /\(\*\)$/;
    return 'fn' if $s =~ /\)$/ && $s =~ /^[^(]+\(/ && $s !~ /^(?:struct|union|enum) \(/;
    return 'arr(' . tstr($1) . ",$2)" if $s =~ /^(.*)\[(\d*)\]$/;
    return 'vla(' . tstr($1) . ')' if $s =~ /^(.*?)\[([^\[\]]*[A-Za-z_(][^\[\]]*)\]$/;
    if ($s =~ /^(.*)\*$/) { my $to = tstr($1); return $to eq 'fn' ? 'fnptr' : "ptr($to)" }
    return $cls{$s} if exists $cls{$s};
    return 'rec' if $s =~ /^(?:struct|union)\b/;
    return 'enum' if $s =~ /^enum\b/;
    return 'u64' if $s eq 'unsigned long int';
    "?$s";
}
sub tcls { my ($n) = @_; my $t = $n->{type} or return '-'; tstr($t->{desugaredQualType} // $t->{qualType}) }
sub noattr {
    my ($s) = @_;
    while ($s =~ /__attribute__\s*\(/g) {
        my $b = $-[0];
        my ($d, $i) = (0, pos($s) - 1);
        for (; $i < length $s; $i++) { my $c = substr($s, $i, 1); $d++ if $c eq '('; $d-- if $c eq ')'; last if !$d }
        substr($s, $b, $i + 1 - $b) = '';
        pos($s) = $b;
    }
    $s;
}
sub retcls {
    my ($fn) = @_;
    my $s = noattr($fn->{type}{desugaredQualType} // $fn->{type}{qualType});
    $s =~ s/\s+$//;
    my ($d, $i) = (0, length($s) - 1);
    for (; $i >= 0; $i--) { my $c = substr($s, $i, 1); $d++ if $c eq ')'; $d-- if $c eq '('; last if !$d }
    tstr(substr($s, 0, $i));
}

# ---- the normal form ------------------------------------------------------------

our ($side, %labels, %regvar, %local);   # 'glibc' or 'ff'; the function's labels; the unit's register variables
sub strip { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr|ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub unparen { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub name_of {
    my ($d) = @_;
    my $n = $d->{name} // '';
    return $orig{$n} // $n if $side eq 'ff';
    return $regvar{$n} if $d->{kind} eq 'VarDecl' && $regvar{$n} && !$local{ $d->{id} };
    $n =~ s/^__builtin_((?:mem|str|stp)\w+|free|malloc)$/$1/;
    $n = '__builtin_va_start' if $n eq '__builtin_c23_va_start';
    $n;
}
my %castdrop = map { $_ => 1 } qw(LValueToRValue NoOp ArrayToPointerDecay FunctionToPointerDecay BuiltinFnToFnPtr);
my %atomicop = map { $_ => 1 } qw(exchange load store compare_exchange fetch_add fetch_sub fetch_and fetch_or fetch_xor fetch_nand
    add_fetch sub_fetch and_fetch or_fetch xor_fetch nand_fetch);

sub E {
    my ($n) = @_;
    return '-' unless $n && $n->{kind};
    my $k = $n->{kind};
    return E((kids($n))[0]) if $k =~ /^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/;
    if ($k eq 'ImplicitCastExpr' || $k eq 'CStyleCastExpr') {
        my ($c) = kids($n);
        my $ck = $n->{castKind} // '';
        # a conversion to _Bool: in ff (where it is a u8) a compare with 0
        # (what the operand is converted to first does not matter then)
        return '(tobool ' . E(unimplicit($c)) . ')' if $ck =~ /ToBoolean$/;
        if ($ck eq 'IntegralCast' && tcls($n) eq 'u8' && $side eq 'ff') {
            my $b = unparen($c);
            if ($b->{kind} eq 'BinaryOperator' && $b->{opcode} eq '!=' && is_zero((kids($b))[1])) { return '(tobool ' . E(unimplicit((kids($b))[0])) . ')' }
        }
        # a null pointer, however its casts go
        if (($ck eq 'BitCast' || $ck eq 'NullToPointer') && is_null($n)) { return '(null ' . tcls($n) . ')' }
        return E($c) if $castdrop{$ck};
        # (and an asm function's value is a long: C's conversion of it is not there)
        return E($c) if $k eq 'ImplicitCastExpr' && is_asmfncall($c);
        # (c2ff gives an atomic's value C's type again, over libatomic's uN)
        return E($c) if $side eq 'ff' && is_atomiccall($c);
        return E($c) if tcls($n) eq tcls($c) && $ck ne 'ToVoid';
        # (ttpc makes every enum an int, C one of no negative constant an
        # unsigned: the same value either way)
        return E($c) if $ck eq 'IntegralCast' && (tcls($n) eq 'enum' || tcls($c) eq 'enum');
        # offsetof as ff has it: the field's address in a T at 0
        if ($ck eq 'PointerToIntegral' && is_offsetof($c)) { return '(offsetof)' }
        # long double has no literal of its own in ff: a double's, cast
        if ($ck eq 'FloatingCast' && strip($c)->{kind} eq 'FloatingLiteral') { return '(flt ' . flt(strip($c)->{value}) . ')' }
        return "(cast $ck " . tcls($n) . ' ' . E($c) . ')';
    }
    return '(int ' . ($n->{value} // 0) . ' ' . tcls($n) . ')' if $k eq 'IntegerLiteral';
    return '(int ' . $n->{value} . ' i32)' if $k eq 'CharacterLiteral';
    return '(flt ' . flt($n->{value}) . ')' if $k eq 'FloatingLiteral';
    return '(str ' . str($n->{value}) . ')' if $k eq 'StringLiteral';
    return E((kids($n))[0]) if $k eq 'PredefinedExpr';
    if ($k eq 'DeclRefExpr') { return '(ref ' . name_of($n->{referencedDecl}) . ')' }
    if ($k eq 'UnaryOperator') {
        my ($c) = kids($n);
        my $op = $n->{opcode};
        # (+x is x, its promotion left to the operator that takes it)
        return E($op eq '+' ? unimplicit($c) : $c) if $op eq '+' || $op eq '__extension__';
        # a function's address is the function (its decay is dropped too)
        return E($c) if $op eq '&' && (strip($c)->{kind} // '') eq 'DeclRefExpr' && (strip($c)->{referencedDecl}{kind} // '') eq 'FunctionDecl';
        return "(u$op" . ($n->{isPostfix} ? 'post' : '') . ' ' . E($c) . ')';
    }
    if ($k eq 'BinaryOperator' && $n->{opcode} eq ',') { return seqform(seq($n)) }
    if ($k eq 'BinaryOperator' || $k eq 'CompoundAssignOperator') {
        my ($l, $r) = kids($n);
        # an asm statement's output, which ff sets from its asm function
        return '(asm)' if $side eq 'ff' && $n->{opcode} eq '=' && is_asmcall($r);
        # (an asm function's value is a long in ff: the other operand without
        # C's conversion to it)
        $r = unimplicit($r) if is_asmfncall(unimplicit($l));
        $l = unimplicit($l) if is_asmfncall(unimplicit($r));
        # (an enum is an int in ttpc, in C maybe an unsigned: the other operand
        # without its conversion)
        if (tcls(unimplicit($l)) eq 'enum' || tcls(unimplicit($r)) eq 'enum') { ($l, $r) = (unimplicit($l), unimplicit($r)) }
        return "($n->{opcode} " . E($l) . ' ' . E($r) . ')';
    }
    if ($k eq 'ConditionalOperator') { my ($c, $a, $b) = kids($n); return '(?: ' . E($c) . ' ' . E($a) . ' ' . E($b) . ')' }
    if ($k eq 'BinaryConditionalOperator') { my @k = kids($n); return '(?2 ' . E($k[0]) . ' ' . E($k[3]) . ')' }
    if ($k eq 'ArraySubscriptExpr') { my ($b, $i) = kids($n); return '(u* (+ ' . E($b) . ' ' . E($i) . '))' }
    if ($k eq 'MemberExpr') {
        my ($b) = kids($n);
        # (an anonymous member is no step of its own)
        return E($b) if ($n->{name} // '') eq '';
        return '(mem ' . ($n->{isArrow} ? '->' : '.') . ($n->{name} =~ s/'$//r) . ' ' . E($b) . ')';
    }
    return call($n) if $k eq 'CallExpr';
    return atomic($n) if $k eq 'AtomicExpr';
    return '(offsetof)' if $k eq 'OffsetOfExpr';
    if ($k eq 'UnaryExprOrTypeTraitExpr') {
        my $w = $n->{name} =~ /align/i ? 'alignof' : $n->{name};
        my $t = $n->{argType} ? tstr($n->{argType}{desugaredQualType} // $n->{argType}{qualType}) : tcls((kids($n))[0]);
        return "($w $t)";
    }
    if ($k eq 'StmtExpr') {
        my ($cs) = kids($n);
        if ($side eq 'glibc') { my $s = syscall_idiom($cs); return $s if $s }
        return seqform(S(kids($cs)));
    }
    return '(clit ' . tcls($n) . ' ' . E((kids($n))[0]) . ')' if $k eq 'CompoundLiteralExpr';
    return init($n) if $k eq 'InitListExpr';
    return '(zero)' if $k eq 'ImplicitValueInitExpr';
    return '(va_arg ' . tcls($n) . ' ' . E((kids($n))[0]) . ')' if $k eq 'VAArgExpr';
    return "(addrlabel " . ($labels{ $n->{labelDeclId} } // '?') . ')' if $k eq 'AddrLabelExpr';
    return '(asm)' if $k eq 'GCCAsmStmt';
    "(?$k)";
}
sub unimplicit { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ImplicitCastExpr|ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub seqform { my (@i) = @_; @i == 1 ? $i[0] : '(seq ' . join(' ', @i) . ')' }
sub seq { my ($n) = @_; my $s = unparen($n); return ($s->{kind} eq 'BinaryOperator' && $s->{opcode} eq ',') ? map { seq($_) } kids($s) : E($n) }
sub flt { my ($v) = @_; my $x = $v =~ /^0x/i ? hexf($v) : 0 + $v; sprintf '%.17g', $x }
sub hexf { my ($v) = @_; $v =~ /^(-?)0x([0-9a-f]*)(?:\.([0-9a-f]*))?p([-+]?\d+)/i or return $v; my ($s, $i, $f, $e) = ($1, $2, $3 // '', $4); my $m = hex($i || 0); $m += hex(substr($f, $_, 1)) / 16 ** ($_ + 1) for 0 .. length($f) - 1; ($s ? -1 : 1) * $m * 2 ** $e }
my %esc = (n => 10, t => 9, r => 13, a => 7, b => 8, f => 12, v => 11, e => 27, '"' => 34, "'" => 39, '\\' => 92, '?' => 63);
sub str {
    my ($v) = @_;
    my $p = $v =~ s/^(L|u8|u|U)?"// ? ($1 // '') : '';
    $v =~ s/"$//;
    my @b;
    while ($v ne '') {
        if ($v =~ s/^\\x([0-9a-fA-F]+)//) { push @b, hex $1 }
        elsif ($v =~ s/^\\([0-7]{1,3})//) { push @b, oct $1 }
        elsif ($v =~ s/^\\u([0-9a-fA-F]{4})// || $v =~ s/^\\U([0-9a-fA-F]{8})//) { push @b, hex $1 }
        elsif ($v =~ s/^\\(.)//s) { push @b, $esc{$1} // ord $1 }
        else { $v =~ s/^(.)//s; my $c = $1; if ($p ne '' && $p ne 'u8') { utf8::decode($c); push @b, ord $c } else { push @b, ord $c } }
    }
    ($p ne '' && $p ne 'u8' ? 'w' : '') . join(',', @b);
}
sub is_atomiccall { my ($n) = @_; my $s = unparen($n); ($s->{kind} // '') eq 'CallExpr' && ((strip((kids($s))[0]) // {})->{referencedDecl}{name} // '') =~ /^__atomic_\w+_\d+$/ }
sub is_asmfncall { my ($n) = @_; my $s = unparen($n); return 0 unless ($s->{kind} // '') eq 'CallExpr'; my $d = (strip((kids($s))[0]) // {})->{referencedDecl} or return 0; $asmfn{ name_of($d) } }
sub is_zero { my ($n) = @_; my $s = strip($n); ($s->{kind} // '') =~ /^(IntegerLiteral|FloatingLiteral)$/ && $s->{value} == 0 }
sub is_null {
    my ($n) = @_;
    my $null = 0;
    while ($n && ($n->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr|ParenExpr)$/) { $null = 1 if ($n->{castKind} // '') eq 'NullToPointer'; $n = (kids($n))[0] }
    $null && ($n->{kind} // '') eq 'IntegerLiteral' && $n->{value} == 0;
}
sub is_asmcall { my ($n) = @_; my $s = strip($n); $s && $s->{kind} eq 'CallExpr' && ((strip((kids($s))[0]) // {})->{referencedDecl}{name} // '') =~ /^_+asm_/ }
sub is_offsetof {
    my ($n) = @_;
    my $s = unparen($n);
    return 0 unless $s->{kind} eq 'UnaryOperator' && $s->{opcode} eq '&';
    $s = unparen((kids($s))[0]);
    $s = unparen((kids($s))[0]) while $s->{kind} =~ /^(MemberExpr|ArraySubscriptExpr)$/;
    $s->{kind} =~ /CastExpr$/ && (strip($s)->{kind} // '') eq 'IntegerLiteral' && strip($s)->{value} == 0;
}
sub call {
    my ($n) = @_;
    my ($callee, @args) = kids($n);
    my $c = strip($callee);
    $c = strip((kids($c))[0]) while $c->{kind} eq 'UnaryOperator' && $c->{opcode} eq '*';
    my $name = $c->{kind} eq 'DeclRefExpr' && ($c->{referencedDecl}{kind} // '') eq 'FunctionDecl' ? name_of($c->{referencedDecl}) : undef;
    if (defined $name) {
        if ($side eq 'glibc') {
            return E($args[0]) if $name eq '__builtin_expect';
            return '(int ' . ((strip($args[0])->{kind} // '') =~ /^(IntegerLiteral|CharacterLiteral)$/ ? 1 : 0) . ' i32)' if $name eq '__builtin_constant_p';
        }
        @args = ($args[0]) if $name eq '__builtin_va_start';
        # an asm function has no C type in ff: C's conversions of its arguments are not there
        @args = map { unimplicit($_) } @args if $asmfn{$name};
        return '(asm)' if $name =~ /^_+asm_/;
        return '(syscall ' . join(' ', map { E(strip($_)) } @args) . ')' if $name eq '__ff_syscall';
        if ($side eq 'ff' && $name =~ /^__atomic_(\w+)_\d+$/ && $atomicop{$1}) { return "(atomic $1 " . join(' ', map { E(strip($_)) } @args) . ')' }
        return "(call $name" . join('', map { ' ' . E($_) } @args) . ')';
    }
    '(call* ' . E($c) . join('', map { ' ' . E($_) } @args) . ')';
}
# gcc's atomic builtins: in ff a call of libatomic's function for the size
# (c2ff's order of the arguments)
sub atomic {
    my ($n) = @_;
    my ($p, $o, @v) = kids($n);
    my $a = $n->{name} =~ s/^__atomic_//r;
    $a =~ s/_n$//;
    my @a = $a eq 'load' ? ($p, $o) : $a eq 'compare_exchange' ? ($p, $v[0], $v[2], $o, $v[1]) : ($p, $v[0], $o);
    "(atomic $a " . join(' ', map { E(strip($_)) } @a) . ')';
}
sub init {
    my ($n) = @_;
    my @k = kids($n);
    @k = @{ $n->{array_filler} }[1 .. $#{ $n->{array_filler} }] if !@k && $n->{array_filler};
    my @i = map { my $e = E($_); $e =~ /^\(int 0 [^)]*\)$|^\(cast \w+ \S+ \(int 0 [^)]*\)\)$|^\(init\)$/ ? '(zero)' : $e } @k;
    pop @i while @i && $i[-1] eq '(zero)';
    my $f = $n->{field} ? ' .' . ($n->{field}{name} // '') : '';
    return '(zero)' if !@i && !$f;
    "(init$f" . join('', map { " $_" } @i) . ')';
}

# glibc's INTERNAL_SYSCALL: register variables a7 = number, a0 ... = the
# arguments, scall (c2ff's syscall_idiom)
sub syscall_idiom {
    my ($cs) = @_;
    my @st = kids($cs);
    my ($inner) = grep { $_->{kind} eq 'CompoundStmt' } @st;
    return undef unless $inner && grep { $_->{kind} eq 'GCCAsmStmt' } kids($inner);
    my %reg;
    for my $s (grep { $_->{kind} eq 'DeclStmt' } kids($inner)) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            next unless $lab && $init;
            my $reg = $lab->{label} // (($v->{name} // '') =~ /^__(a[0-7])$/ ? $1 : undef);
            $reg{$reg} = $init if defined $reg;
        }
    }
    return undef unless $reg{a7};
    my %l;
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st) {
        for my $v (kids($s)) { my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v); $l{ $v->{name} } = $init if $init }
    }
    my @a;
    for my $i (0 .. 5) {
        my $e = $reg{"a$i"} or last;
        my $s = strip($e);
        $e = $l{ $s->{referencedDecl}{name} } if $s->{kind} eq 'DeclRefExpr' && $l{ $s->{referencedDecl}{name} };
        push @a, E(strip($e));
    }
    '(syscall ' . join(' ', E(strip($reg{a7})), @a) . ')';
}

sub holds { my ($n, $k) = @_; (($n->{kind} // '') eq $k) || grep { holds($_, $k) } kids($n) }
# Statements, as a list.
sub S {
    my @out;
    for my $n (@_) {
        next unless $n && $n->{kind};
        my $k = $n->{kind};
        if ($k eq 'CompoundStmt') {
            # (one statement in braces is that statement: c2ff writes C's
            # parentheses as :, which is a block as a statement)
            push @out, brace(S(kids($n)));
            next;
        }
        if ($k eq 'DeclStmt') {
            for my $d (kids($n)) {
                next unless $d->{kind} eq 'VarDecl';
                next if ($d->{storageClass} // '') eq 'extern';
                next if ($d->{storageClass} // '') eq 'static' && !holds($d, 'AddrLabelExpr');
                my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($d);
                # a char array set from a text: the text's codes, the zeros at its end the rest
                my $i = $init ? E($init) : undef;
                if ($i && $i =~ /^\(str ([\d,]*)\)$/ && (my $codes = $1) && tcls($d) =~ /^arr/) { my @c = split /,/, $codes; pop @c while @c && $c[-1] == 0; $i = '(init' . join('', map { " (int $_ " . 'char)' } @c) . ')' }
                if ($i && $i =~ /^\(init/ && tcls($d) =~ /^arr\((char|u8|i8),/) { $i =~ s/\(cast IntegralCast (?:char|u8|i8) (\(int \d+) i32\)\)/$1 char)/g; $i =~ s/\(int (\d+) (?:u8|i8)\)/(int $1 char)/g }
                push @out, '(var ' . ($d->{name} =~ s/'$//r) . ' ' . tcls($d) . (defined $i ? " $i" : '') . ')';
            }
            next;
        }
        if ($k eq 'IfStmt') {
            my @k = kids($n);
            my ($c, $t, $e) = $n->{hasElse} ? @k : (@k, undef);
            push @out, '(if ' . E($c), body($t), ($e ? ('else', body($e)) : ()), ')';
            next;
        }
        if ($k eq 'WhileStmt') { my ($c, $b) = kids($n); push @out, '(while ' . E($c), body($b), ')'; next }
        if ($k eq 'DoStmt') { my ($b, $c) = kids($n); push @out, '(do ' . E($c), body($b), ')'; next }
        if ($k eq 'ForStmt') {
            my ($i, undef, $c, $s, $b) = kids($n);
            # an init declaring several: a block holding them and the loop (as c2ff has it)
            if ($i && $i->{kind} && $i->{kind} eq 'DeclStmt' && kids($i) > 1) {
                push @out, '{', S($i), '(for - ' . E($c) . ' ' . effect($s), body($b), ')', '}';
                next;
            }
            push @out, '(for ' . ($i && $i->{kind} ? ($i->{kind} eq 'DeclStmt' ? join(' ', S($i)) : effect($i)) : '-') . ' ' . E($c) . ' ' . effect($s), body($b), ')';
            next;
        }
        if ($k eq 'SwitchStmt') { my ($v, $b) = kids($n); push @out, '(switch ' . E($v), body($b), ')'; next }
        if ($k eq 'CaseStmt') { my @k = kids($n); my $sub = pop @k; push @out, '(case ' . join(' ', map { E($_) } @k) . ')', S($sub); next }
        if ($k eq 'DefaultStmt') { push @out, '(default)', S(kids($n)); next }
        if ($k eq 'LabelStmt') { push @out, "(label $n->{name})", S(kids($n)); next }
        if ($k eq 'AttributedStmt') { push @out, S(grep { $_->{kind} !~ /Attr$/ } kids($n)); next }
        next if $k eq 'NullStmt';
        if ($k eq 'ReturnStmt') { push @out, '(return' . ($n->{inner} ? ' ' . E((kids($n))[0]) : '') . ')'; next }
        if ($k eq 'BreakStmt') { push @out, '(break)'; next }
        if ($k eq 'ContinueStmt') { push @out, '(continue)'; next }
        if ($k eq 'GotoStmt') { push @out, '(goto ' . ($labels{ $n->{targetLabelDeclId} } // '?') . ')'; next }
        if ($k eq 'IndirectGotoStmt') { push @out, '(goto* ' . E((kids($n))[0]) . ')'; next }
        if ($k eq 'GCCAsmStmt') { push @out, '(asm)'; next }
        # an expression whose value is not used
        push @out, xstmt($n);
    }
    @out;
}
# An expression as a statement: a statement expression is its block (ff's :
# as a statement), a comma's operands statements of a block, one statement
# in braces that statement.
sub xstmt {
    my ($n) = @_;
    my $u = unimplicit($n);
    $u = unimplicit((kids($u))[0]) while ($u->{kind} // '') eq 'UnaryOperator' && $u->{opcode} eq '__extension__';
    my @s;
    if (($u->{kind} // '') eq 'StmtExpr' && !($side eq 'glibc' && syscall_idiom((kids($u))[0]))) { @s = S(kids((kids($u))[0])) }
    elsif (($u->{kind} // '') eq 'BinaryOperator' && $u->{opcode} eq ',') { @s = map { xstmt($_) } kids($u) }
    else { return effect($n) }
    brace(@s);
}
# Statements in braces, but one statement or one block alone as it is.
sub brace {
    my (@s) = @_;
    return @s if @s == 1 && $s[0] !~ /^\(var /;
    if (@s && $s[0] eq '{') {
        my $d = 0;
        for my $i (0 .. $#s) { $d++ if $s[$i] eq '{'; $d-- if $s[$i] eq '}'; return @s if !$d && $i == $#s; last if !$d }
    }
    ('{', @s, '}');
}
# A statement's body: the statements of its braces, or the one statement.
sub body { my ($b) = @_; return () unless $b && $b->{kind}; $b->{kind} eq 'CompoundStmt' ? S(kids($b)) : S($b) }
# An expression for its effect: x++ and ++x alike.
sub effect {
    my ($n) = @_;
    return '-' unless $n && $n->{kind};
    my $s = unparen($n);
    return '(u' . $s->{opcode} . ' ' . E((kids($s))[0]) . ')' if $s->{kind} eq 'UnaryOperator' && $s->{opcode} =~ /^(\+\+|--)$/;
    return '(seq ' . join(' ', map { effect($_) } kids($s)) . ')' if $s->{kind} eq 'BinaryOperator' && $s->{opcode} eq ',';
    E($n);
}

sub labels_of { my ($n) = @_; (($n->{kind} // '') eq 'LabelStmt' ? ($n->{declId} => $n->{name}) : ()), map { labels_of($_) } kids($n) }
sub locals_of { my ($n) = @_; (($n->{kind} // '') =~ /^(ParmVarDecl|VarDecl)$/ ? ($n->{id} => 1) : ()), map { locals_of($_) } kids($n) }
sub fnorm {
    my ($fn) = @_;
    local %labels = labels_of($fn);
    local %local = locals_of($fn);
    my @p = map { tcls($_) } grep { $_->{kind} eq 'ParmVarDecl' } kids($fn);
    my ($cs) = grep { $_->{kind} eq 'CompoundStmt' } kids($fn);
    join ' ', '(fn', retcls($fn), '(' . join(' ', @p) . ($fn->{variadic} ? ' ...' : '') . ')', S(kids($cs)), ')';
}

# The typedefs of a unit: name, the type it stands for
sub typedefs { my ($ast) = @_; map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} eq 'TypedefDecl' } kids($ast) }
sub typeofs {
    my ($ast) = @_;
    my %t;
    my @q = ($ast);
    while (my $n = shift @q) {
        my $ty = $n->{type};
        $t{ $ty->{qualType} } //= $ty->{desugaredQualType} if $ty && defined $ty->{desugaredQualType} && $ty->{qualType} =~ /typeof/;
        push @q, @{ $n->{inner} || [] };
    }
    %t;
}

# ---- the comparison -----------------------------------------------------------

my %back;
{
    my $ast = load($backjson);
    local $side = 'ff';
    local %tdef = typedefs($ast);
    local %typeof = typeofs($ast);
    local %declty = map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} =~ /^(FunctionDecl|VarDecl)$/ && defined $_->{name} && $_->{type} } kids($ast);
    for my $d (kids($ast)) {
        next unless $d->{kind} eq 'FunctionDecl' && grep { $_->{kind} eq 'CompoundStmt' } kids($d);
        $back{ $d->{name} } = fnorm($d);
    }
}
my %byunit;
push @{ $byunit{ $_->[2] } }, $_ for grep { $_->[3] eq 'body' } @bodies;
my ($same, @diff) = (0);
my @failed = grep { $_->[3] eq 'failed' } @bodies;
for my $unit (sort keys %byunit) {
    (my $j = $unit) =~ s/\.i$/.json/;
    my $ast = load($j);
    local $side = 'glibc';
    local %regvar;
    local %tdef = typedefs($ast);
    local %typeof = typeofs($ast);
    local %declty = map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} =~ /^(FunctionDecl|VarDecl)$/ && defined $_->{name} && $_->{type} } kids($ast);
    my %def;
    for my $d (kids($ast)) {
        if ($d->{kind} eq 'VarDecl' && ($d->{storageClass} // '') eq 'register' && (my ($l) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($d))) {
            $regvar{ $d->{name} } = $d->{mangledName} // $l->{label};
        }
        $def{ $d->{name} } = $d if $d->{kind} eq 'FunctionDecl' && grep { $_->{kind} eq 'CompoundStmt' } kids($d);
    }
    for my $b (@{ $byunit{$unit} }) {
        my ($cid, $o) = @$b;
        my $d = $def{$o} or do { push @diff, [$cid, "no function $o in $unit"]; next };
        my $want = fnorm($d);
        my $got = $back{$cid} // do { push @diff, [$cid, 'not in the C written back']; next };
        if ($want eq $got) { $same++; next }
        push @diff, [$cid, where($want, $got)];
    }
}
# where two normal forms part
sub where {
    my ($a, $b) = @_;
    my $i = 0;
    $i++ while $i < length($a) && $i < length($b) && substr($a, $i, 1) eq substr($b, $i, 1);
    my $from = $i > 80 ? $i - 80 : 0;
    "\n    glibc: ..." . substr($a, $from, 200) . "\n    ff:    ..." . substr($b, $from, 200);
}
print "roundtrip: $_->[0]: $_->[1]\n" for @diff;
print "roundtrip: $_->[1]: ff2c could not write it back\n" for @failed;
printf "roundtrip: %d of %d functions as glibc's C\n", $same, scalar(@bodies);
exit(@diff || @failed ? 1 : 0);
