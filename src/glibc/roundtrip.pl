#!/usr/bin/env perl
# roundtrip.pl — glibc in ff against the C it was made of: for each C
# function of a milestone, clang's AST of what ff2c.pl writes back from the ff
# must be clang's AST of the function in glibc's .i, both normalized alike.
#
#   perl roundtrip.pl [--target t] names.txt back.json unit.json ...
#
# --target arm: arm's unsigned long is a u32 (c2ff's), and its
# INTERNAL_SYSCALL the register variables r0 ... r6 and r7, swi 0x0.
# The globals too: each glibc global of the ff, its type and its items,
# against its definition in glibc's units (unit.json ...: the milestone's).
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
# a call of a function of gcc's error attribute declared in a function
# (__errordecl) none, (void) 0,
# a function's statics globals of their own. Names come back through
# names.txt (c2ff's own names for a unit's statics, ' after reserved words).
#
# A host tool, not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";
use FFold;
my $json = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };

our $target = '';
if (@ARGV >= 2 && $ARGV[0] eq '--target') { (undef, $target) = splice @ARGV, 0, 2 }
my ($namesfile, $backjson, @unitjson) = @ARGV;
die "usage: roundtrip.pl [--target t] names.txt back.json [unit.json ...]\n" unless defined $backjson;

my (@bodies, %orig, %asmfn, @globals);
open my $h, '<', $namesfile or die "roundtrip: $namesfile: $!\n";
while (<$h>) {
    chomp;
    my ($k, $cid, $o, $unit) = split /\t/;
    if ($k eq 'asm') { $asmfn{$o} = 1; next }
    if ($k eq 'global' || $k eq 'gfailed') { push @globals, [$cid, $o, $unit, $k]; next }
    $orig{$cid} = $o;
    push @bodies, [$cid, $o, $unit, $k] if $k eq 'body' || $k eq 'failed';
}
close $h;

sub load { my ($f) = @_; open my $h, '<', $f or die "roundtrip: $f: $!\n"; local $/; $json->decode(<$h>) }
sub kids { @{ $_[0]{inner} || [] } }

# ---- types --------------------------------------------------------------------

our %tdef;                 # the typedefs of the AST at hand
our $typeof_depth = 0;     # (tstr through typeof_expr, at most 8 deep)
our %typeof;               # what its typeof (expression) types are, where clang says
our %declty;               # the types of its functions and globals, for typeof (name)
our %errordecl;            # functions of gcc's error attribute declared in a function (by id): a call of one is none, as c2ff has it
our %constint;             # glibc's side: the unit's const integer globals of a number, an array's count as c2ff takes them (tst-random's long rnd[nseq][nrnd])
my %cls = ('char' => 'char', 'signed char' => 'i8', 'unsigned char' => 'u8', 'short' => 'i16', 'unsigned short' => 'u16',
    'int' => 'i32', 'unsigned int' => 'u32', 'long' => 'i64', 'long long' => 'i64', 'unsigned long' => 'u64',
    'unsigned long long' => 'u64', '_Bool' => 'u8', 'bool' => 'u8', 'float' => 'float', 'double' => 'double',
    'long double' => 'ldouble', '__float128' => 'ldouble', 'void' => 'void', '__builtin_va_list' => 'va', 'va_list' => 'va', '__va_list_tag' => 'va');
$cls{'unsigned long'} = 'u32' if $target eq 'arm';
sub tstr {
    my ($s) = @_;
    $s = noattr($s);
    $s =~ s/\b(const|volatile|restrict|__restrict)\b//g;
    $s =~ s/\s+/ /g;
    $s =~ s/^ | $//g;
    $s =~ s/ (\*|\[)/$1/g;
    $s =~ s/\bsigned (char)\b/signed $1/;
    $s =~ s/\[([A-Za-z_]\w*)\]/'[' . ($constint{$1} \/\/ $1) . ']'/ge if %constint;
    $s =~ s/\b(?:long int)\b/long/g;
    $s =~ s/\b(?:short int)\b/short/g;
    $s =~ s/\bunsigned\b(?! (?:char|short|int|long))/unsigned int/g;
    # (x86_64's __float128, libgcc's TF: a long double in ff, its complex too)
    $s =~ s/\b__float128\b/long double/g if $target eq 'x86_64';
    return tstr($tdef{$s}) if exists $tdef{$s};
    return tstr($typeof{$s}) if exists $typeof{$s};
    # (typeof (name): the type of what the unit declares by that name)
    return tstr($declty{$1}) if $s =~ /^(?:typeof|__typeof__) \(\s*(\w+)\s*\)$/ && exists $declty{$1};
    # (typeof of an expression, as c2ff's typeof_expr: x86_64's THREAD_GETMEM,
    # __typeof (*descr) __seg_fs *, descr THREAD_SELF or a local)
    if ($typeof_depth < 8 && $s =~ /^(?:typeof|__typeof__|__typeof)\s*(\((?:[^()]++|(?1))*\))(.*)$/) {
        my ($e, $rest) = (substr($1, 1, -1), $2);
        my $t = typeof_expr($e);
        local $typeof_depth = $typeof_depth + 1;
        return tstr("$t$rest") if defined $t && "$t$rest" ne $s;
    }
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
    return $target eq 'arm' ? 'u32' : 'u64' if $s eq 'unsigned long int';
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

our ($side, %labels, %regvar, %local, $in_global, %enumval, %asmalias);   # 'glibc' or 'ff'; the function's labels; the unit's register variables
sub strip { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr|ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub unparen { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub name_of {
    my ($d) = @_;
    my $n = $d->{name} // '';
    return $orig{$n} // $n if $side eq 'ff';
    return $regvar{$n} if $d->{kind} eq 'VarDecl' && $regvar{$n} && !$local{ $d->{id} };
    $n =~ s/^__builtin_((?:mem|str|stp)\w+|free|malloc)$/$1/;
    # (a call of copysign or fabs: of its builtin, as c2ff writes it)
    $n = "__builtin_$n" if $n =~ /^(?:copysign|fabs)[fl]?$/ && $d->{kind} eq 'FunctionDecl';
    $n = '__builtin_va_start' if $n eq '__builtin_c23_va_start';
    # (x86_64's builtins of __float128: their long double ones, as c2ff writes them)
    $n = "$1l" if $n =~ /^(__builtin_(?:fabs|copysign|huge_val|inf|nan|nans))f128$/ && $target eq 'x86_64';
    # (a unit's asm ("memset = __memset_generic"): its calls of memset are
    # of __memset_generic, as c2ff writes them)
    $n = $asmalias{$n} if $d->{kind} eq 'FunctionDecl' && exists $asmalias{$n};
    $n;
}
my %castdrop = map { $_ => 1 } qw(LValueToRValue NoOp ArrayToPointerDecay FunctionToPointerDecay BuiltinFnToFnPtr);
my %atomicop = map { $_ => 1 } qw(exchange load store compare_exchange fetch_add fetch_sub fetch_and fetch_or fetch_xor fetch_nand
    add_fetch sub_fetch and_fetch or_fetch xor_fetch nand_fetch);

# inf or nan where n is a call of gcc's __builtin_huge_val, inf or nan ("")
# (of any floating type), under floating conversions; else undef
sub special_float {
    my ($n) = @_;
    $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ParenExpr|ConstantExpr)$/
        || ($n->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr)$/ && ($n->{castKind} // '') =~ /^(FloatingCast|NoOp)$/;
    return unless $n && ($n->{kind} // '') eq 'CallExpr';
    my $d = (strip((kids($n))[0]) // {})->{referencedDecl} or return;
    my $name = $d->{name} // '';
    return 'inf' if $name =~ /^__builtin_(?:huge_val|inf)(?:[fl]|f128)?$/;
    return 'nan' if $name =~ /^__builtin_nan(?:[fl]|f128)?$/;
    return;
}
# a value of FFold's as E has the literal of its type
sub fconst {
    my ($v, $t) = @_;
    my $x = $v->{k} ne 'num' ? "(fspecial $v->{k} " . tstr($t) . ')'
        : $t eq 'long double' ? '(fltl ' . FFold::qlit($v->{q}, $v->{e}, 16383) . ')'
        : '(flt ' . sprintf('%.17g', $v->{q}->numify * 2**$v->{e}) . ')';
    $v->{neg} ? "(u- $x)" : $x;
}
sub E {
    my ($n) = @_;
    return '-' unless $n && $n->{kind};
    my $k = $n->{kind};
    return E((kids($n))[0]) if $k =~ /^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/;
    # (in a global's value gcc's infinity or NaN, converted or not, is the
    # literal of its type there, as c2ff writes it; ff2c writes it back as
    # the builtin of that type)
    if ($in_global && (my $sp = special_float($n))) { return "(fspecial $sp " . tcls($n) . ')' }
    # (a global's floating constant of long double, as c2ff works it out:
    # FFold's, the same on both sides)
    if ($in_global && $target ne 'arm' && $k =~ /^(BinaryOperator|UnaryOperator|CStyleCastExpr|ImplicitCastExpr)$/
        && FFold::fty(FFold::ftype($n)) && FFold::ldinside($n) && (my $v = FFold::fold($n))) { return fconst($v, FFold::ftype($n)) }
    if ($k eq 'ImplicitCastExpr' || $k eq 'CStyleCastExpr') {
        my ($c) = kids($n);
        my $ck = $n->{castKind} // '';
        # a conversion to _Bool: in ff (where it is a u8) a compare with 0
        # (what the operand is converted to first does not matter then)
        return '(tobool ' . E(unimplicit($c)) . ')' if $ck =~ /ToBoolean$/;
        # (C23's true and false, a bool's own, are c2ff's 1 and 0, a u8 there:
        # a 1 or 0 converted to a u8 is that literal, on both sides)
        if ($ck eq 'IntegralCast' && tcls($n) eq 'u8' && !$in_global && (unparen($c)->{kind} // '') eq 'IntegerLiteral' && (unparen($c)->{value} // '') =~ /^[01]$/) { return E(unparen($c)) }
        if ($ck eq 'IntegralCast' && tcls($n) eq 'u8' && $side eq 'ff') {
            my $b = unparen($c);
            if ($b->{kind} eq 'BinaryOperator' && $b->{opcode} eq '!=' && is_zero((kids($b))[1])) { return '(tobool ' . E(unimplicit((kids($b))[0])) . ')' }
        }
        # a null pointer, however its casts go
        if (($ck eq 'BitCast' || $ck eq 'NullToPointer') && is_null($n)) { return '(null ' . tcls($n) . ')' }
        return E($c) if $castdrop{$ck};
        # (in a global's items &array, which C converts to its element's address, is the array)
        if ($in_global && $ck eq 'BitCast' && $k eq 'ImplicitCastExpr') { my $u = unparen($c); return E($c) if ($u->{kind} // '') eq 'UnaryOperator' && $u->{opcode} eq '&' && tcls(unparen((kids($u))[0])) =~ /^arr\(/ }
        # (and an asm function's value is a long: C's conversion of it is not
        # there; ff2c writes the conversion back where ff has it: aarch64's
        # stpcpy, strchr are asm)
        return E($c) if ($k eq 'ImplicitCastExpr' || $side eq 'ff') && is_asmfncall($c);
        # (nor of a value made of one, + 1, on either side: aarch64's string
        # functions are asm, and __builtin_thread_pointer)
        return E($c) if $ck =~ /^(BitCast|IntegralToPointer|PointerToIntegral|IntegralCast|NoOp)$/ && asm_valued($c);
        return E($c) if $ck eq 'IntegralCast' && is_syscallv($c);
        # (an unsigned int widened to 64 bits, which c2ff writes as a cast
        # where it is a call's argument: lp64d passes an unsigned int
        # sign-extended; the same value either way)
        return E($c) if $ck eq 'IntegralCast' && tcls($c) eq 'u32' && tcls($n) =~ /^[iu]64$/;
        # (an int literal of a 32-bit type, that int or its unsigned, is its
        # value: aarch64's wchar_t is unsigned, L'\n' 10 either way)
        return E($c) if $ck eq 'IntegralCast' && tcls($n) =~ /^[iu]32$/ && small_literal($c);
        # (so is __builtin_types_compatible_p's, the int c2ff makes of it:
        # strfrom-skeleton's info.is_binary128, an unsigned bitfield)
        return E($c) if $ck eq 'IntegralCast' && tcls($n) =~ /^[iu]32$/ && (unparen($c)->{kind} // '') eq 'TypeTraitExpr';
        # (0 is 0 in any integer type: ?:'s arms, one a long of an asm function)
        return '(int 0 i32)' if $ck eq 'IntegralCast' && small_literal($c) && unparen($c)->{value} == 0;
        # (a call of an asm function, whose value ff has as a long, made void)
        return E($c) if $ck eq 'ToVoid' && is_asmfncall($c);
        # (c2ff gives an atomic's value C's type again, over libatomic's uN)
        return E($c) if $side eq 'ff' && is_atomiccall($c);
        return E($c) if tcls($n) eq tcls($c) && $ck ne 'ToVoid';
        # (ttpc makes every enum an int, C one of no negative constant an
        # unsigned: the same value either way)
        # (but an anonymous enum of a block is an int in ff, c2ff's: a value
        # of another type converted to it is converted to an int there)
        return "(cast IntegralCast i32 " . E($c) . ')' if $side eq 'glibc' && $ck eq 'IntegralCast' && tcls($n) eq 'enum' && tcls($c) !~ /^(enum|i32)$/
            && (($n->{type}{desugaredQualType} // $n->{type}{qualType} // '') =~ /^enum \((?:unnamed|anonymous)\b/);
        return E($c) if $ck eq 'IntegralCast' && (tcls($n) eq 'enum' || tcls($c) eq 'enum');
        # (an enum constant converted: libgcc's enum register_rule of C23's
        # underlying type unsigned char, its constants in a switch on a u8,
        # where ff's enum is an int)
        return E($c) if $ck eq 'IntegralCast' && (unparen($c)->{kind} // '') eq 'DeclRefExpr' && (unparen($c)->{referencedDecl}{kind} // '') eq 'EnumConstantDecl';
        # offsetof as ff has it: the field's address in a T at 0
        if ($ck eq 'PointerToIntegral' && is_offsetof($c)) { return '(offsetof)' }
        # a double literal cast to long double: the literal
        if ($ck eq 'FloatingCast' && strip($c)->{kind} eq 'FloatingLiteral') { return '(flt ' . flt(strip($c)->{value}) . ')' }
        return "(cast $ck " . tcls($n) . ' ' . E($c) . ')';
    }
    return '(int ' . ($n->{value} // 0) . ' ' . (small_literal($n) ? 'i32' : tcls($n)) . ')' if $k eq 'IntegerLiteral';
    # (C23's true and false, libgcc's C: c2ff's 1 and 0)
    return '(int ' . ($n->{value} ? 1 : 0) . ' i32)' if $k eq 'CXXBoolLiteralExpr';
    # (__builtin_types_compatible_p: the constant c2ff makes of it)
    if ($k eq 'TypeTraitExpr') {
        my @t = map { my $q = $_->{type}{desugaredQualType} // $_->{type}{qualType} // ''; $q =~ s/\b(const|volatile|restrict)\b//g; $q =~ s/\s+/ /g; $q =~ s/^ | $//g; $q } kids($n);
        return '(int ' . (@t == 2 && $t[0] ne '' && $t[0] eq $t[1] ? 1 : 0) . ' ' . tcls($n) . ')';
    }
    # ('\xff' where char is signed is -1, as c2ff writes it: clang has 4294967295)
    return '(u- (int ' . (2**32 - $n->{value}) . ' i32))' if $k eq 'CharacterLiteral' && $n->{value} >= 2**31 && (($n->{type} // {})->{qualType} // '') eq 'int';
    return '(int ' . $n->{value} . ' i32)' if $k eq 'CharacterLiteral';
    # (a long double literal, binary128: clang's decimal of it, every digit)
    # (a long double literal, binary128: its exact hex, of clang's decimal
    # of it; a float's its value as a float)
    return '(fltl ' . FFold::ldround($n->{value}, 113, -16494, 16383) . ')' if $k eq 'FloatingLiteral' && tcls($n) eq 'ldouble' && $target ne 'arm';
    return '(fltl ' . $n->{value} . ')' if $k eq 'FloatingLiteral' && tcls($n) eq 'ldouble';
    if ($k eq 'FloatingLiteral' && FFold::ftype($n) eq 'float' && (my $v = FFold::fold($n))) { return fconst($v, 'float') }
    return '(flt ' . flt($n->{value}) . ')' if $k eq 'FloatingLiteral';
    return '(str ' . str($n->{value}) . ')' if $k eq 'StringLiteral';
    return E((kids($n))[0]) if $k eq 'PredefinedExpr';
    if ($k eq 'DeclRefExpr') {
        # (an enum constant in a global's items is its value, as c2ff writes it there)
        return "(int $enumval{ $n->{referencedDecl}{name} } i32)" if $in_global && ($n->{referencedDecl}{kind} // '') eq 'EnumConstantDecl' && defined $enumval{ $n->{referencedDecl}{name} };
        return '(ref ' . name_of($n->{referencedDecl}) . ')';
    }
    if ($k eq 'UnaryOperator') {
        my ($c) = kids($n);
        my $op = $n->{opcode};
        # (+x is x, its promotion left to the operator that takes it)
        return E($op eq '+' ? unimplicit($c) : $c) if $op eq '+' || $op eq '__extension__';
        # &*x is x (&a[i] is a + i)
        if ($op eq '&') { my $e = E($c); return $1 if $e =~ /^\(u\* (.*)\)$/s && balanced($1) }
        # in a global's items an array's address is where it begins, as its decay
        return E($c) if $op eq '&' && $in_global && tcls(unparen($c)) =~ /^arr\(/;
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
sub is_mempcpy { my ($n) = @_; my $s = unparen($n); ($s->{kind} // '') eq 'CallExpr' && ((strip((kids($s))[0]) // {})->{referencedDecl}{name} // '') eq '__builtin_mempcpy' }
sub is_asmfncall { my ($n) = @_; my $s = unparen($n); return 0 unless ($s->{kind} // '') eq 'CallExpr'; my $d = (strip((kids($s))[0]) // {})->{referencedDecl} or return 0; $asmfn{ name_of($d) } }
# (arm's syscall, whose value c2ff has as a long, glibc's an int: its
# conversions to either are not compared)
sub is_syscallv {
    my ($n) = @_;
    return 0 unless $target eq 'arm';
    my $s = unparen($n);
    $s = unparen((kids($s))[0]) while ($s->{kind} // '') eq 'ImplicitCastExpr' && ($s->{castKind} // '') eq 'IntegralCast';
    my $k = $s->{kind} // '';
    return $side eq 'glibc' && defined syscall_idiom((kids($s))[0]) if $k eq 'StmtExpr';
    return 0 unless $k eq 'CallExpr';
    my $d = (strip((kids($s))[0]) // {})->{referencedDecl} or return 0;
    ($d->{name} // '') eq '__ff_syscall';
}
sub asm_valued {
    my ($n) = @_;
    my $s = unparen($n);
    $s = unparen((kids($s))[0]) while ($s->{kind} // '') eq 'ImplicitCastExpr';
    return 1 if is_asmfncall($s);
    return 1 if ($s->{kind} // '') eq 'BinaryOperator' && $s->{opcode} =~ /^[-+]$/ && (asm_valued((kids($s))[0]) || asm_valued((kids($s))[1]));
    return 1 if ($s->{kind} // '') eq 'ConditionalOperator' && grep { asm_valued($_) } (kids($s))[1, 2];
    0;
}
sub small_literal { my ($n) = @_; my $s = unparen($n); ($s->{kind} // '') =~ /^(IntegerLiteral|CharacterLiteral)$/ && tcls($s) =~ /^[iu]32$/ && $s->{value} >= 0 && $s->{value} < 2**31 }
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
    # (through an array member's element too: libgcc's offsetof (_Unwind_FrameState, regs.how[0]))
    $s = unparen((kids($s))[0]) while $s->{kind} =~ /^(MemberExpr|ArraySubscriptExpr)$/ || $s->{kind} eq 'ImplicitCastExpr' && ($s->{castKind} // '') eq 'ArrayToPointerDecay';
    $s->{kind} =~ /CastExpr$/ && (strip($s)->{kind} // '') eq 'IntegerLiteral' && strip($s)->{value} == 0;
}
# The functions of gcc's error attribute declared in a function (__errordecl:
# alloc_buffer's asserts, __libc_message_wrapper's __libc_message_error), by id
sub errordecls {
    my ($ast) = @_;
    my (%e, @q);
    @q = map { kids($_) } kids($ast);
    while (my $n = shift @q) {
        push @q, kids($n);
        $e{ $n->{id} } = 1 if ($n->{kind} // '') eq 'FunctionDecl' && grep { ($_->{kind} // '') eq 'ErrorAttr' } kids($n);
    }
    %e;
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
            return '(cast ToVoid void (int 0 i32))' if $errordecl{ $c->{referencedDecl}{id} // '' };
            # __builtin_mempcpy (d, s, n): memcpy (d, s, n) + n, as gcc makes
            # it and c2ff writes it (the unit's memcpy; n without its
            # conversion to size_t)
            if (($c->{referencedDecl}{name} // '') eq '__builtin_mempcpy' && @args == 3) {
                my $n2 = $args[2];
                $n2 = (kids($n2))[0] if $n2->{kind} eq 'ImplicitCastExpr' && ($n2->{castKind} // '') eq 'IntegralCast';
                my $mc = $asmalias{memcpy} // 'memcpy';
                # (memcpy an asm function, aarch64's: no conversions around it)
                return "(cast BitCast ptr(void) (+ (call $mc" . join('', map { my $a = $_; $a = (kids($a))[0] while ($a->{kind} // '') =~ /CastExpr$/ && ($a->{castKind} // '') =~ /^(BitCast|NoOp)$/; ' ' . E($a) } @args) . ') ' . E($n2) . '))' if $asmfn{$mc};
                return "(cast BitCast ptr(void) (+ (cast BitCast ptr(u8) (call $mc" . join('', map { ' ' . E($_) } @args) . ')) ' . E($n2) . '))';
            }
            return '(int ' . ((strip($args[0])->{kind} // '') =~ /^(IntegerLiteral|CharacterLiteral)$/ ? 1 : 0) . ' i32)' if $name eq '__builtin_constant_p';
        }
        @args = ($args[0]) if $name eq '__builtin_va_start';
        # an asm function has no C type in ff: C's conversions of its arguments are not there
        @args = map { unimplicit($_) } @args if $asmfn{$name};
        # (nor its pointer arguments' conversions to void *, either side)
        @args = map { my $a = $_; $a = (kids($a))[0] while ($a->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr)$/ && ($a->{castKind} // '') =~ /^(BitCast|NoOp)$/; $a } @args if $asmfn{$name};
        return '(asm)' if $name =~ /^_+asm_/;
        return '(syscall ' . join(' ', map { E(strip($_)) } @args) . ')' if $name eq '__ff_syscall';
        if ($side eq 'ff' && $name =~ /^__atomic_(\w+)_\d+$/ && $atomicop{$1}) { return "(atomic $1 " . join(' ', map { E(strip($_)) } @args) . ')' }
        # (and of a __builtin_mempcpy, whose sum ends in a conversion to
        # void *: memset's argument in _dl_allocate_tls_init)
        return "(call $name" . join('', map { my $e = E($_); $e =~ s/^\(cast BitCast ptr\(void\) (.*)\)$/$1/s if $side eq 'glibc' && is_mempcpy($_); ' ' . $e } @args) . ')' if $asmfn{$name};
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
    # (an array of chars or wide chars set from one text in braces: the text)
    return text_codes($n, E($k[0])) if @k == 1 && tcls($n) =~ /^arr\(/ && (unparen($k[0])->{kind} // '') eq 'StringLiteral';
    my $elem = tcls($n) =~ /^arr\((char|u8|i8),/ ? 'char' : '';
    my @i = map {
        my $u = unparen($_);
        # (a text setting an array, not decayed to an address: its codes)
        my $e = ($u->{kind} // '') eq 'StringLiteral' ? text_codes($u, E($u)) : E($_);
        # (in a char array a number is a char, however converted)
        if ($elem) { $e =~ s/^\(cast IntegralCast (?:char|u8|i8) \(int (-?\d+) i32\)\)$/(int $1 char)/; $e =~ s/^\(int (-?\d+) (?:u8|i8)\)$/(int $1 char)/ }
        is_zero_form($e) ? '(zero)' : $e;
    } @k;
    pop @i while @i && $i[-1] eq '(zero)';
    my $f = $n->{field} ? ' .' . ($n->{field}{name} // '') : '';
    return '(zero)' if !@i;
    "(init$f" . join('', map { " $_" } @i) . ')';
}

# glibc's INTERNAL_SYSCALL: register variables a7 = number, a0 ... = the
# arguments, scall (c2ff's syscall_idiom); aarch64's x8 = the number, x0
# ... the arguments (x0 set by an assignment after its declaration), svc 0
sub syscall_idiom {
    my ($cs) = @_;
    return syscall_idiom_arm($cs) if $target eq 'arm';
    my $x86 = syscall_idiom_x86($cs);
    return $x86 if defined $x86;
    my @st = kids($cs);
    my ($inner) = grep { $_->{kind} eq 'CompoundStmt' } @st;
    return undef unless $inner && grep { $_->{kind} eq 'GCCAsmStmt' } kids($inner);
    my (%reg, %regof);
    for my $s (grep { $_->{kind} eq 'DeclStmt' } kids($inner)) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            next unless $lab;
            my $reg = $lab->{label} // (($v->{name} // '') =~ /^(?:__(a[0-7])|_(x[0-8]))$/ ? $1 // $2 : undef);
            next unless defined $reg;
            $regof{ $v->{id} } = $reg;
            $reg{$reg} = $init if $init;
        }
    }
    for my $s (grep { $_->{kind} eq 'BinaryOperator' && ($_->{opcode} // '') eq '=' } kids($inner)) {
        my ($l, $r) = kids($s);
        $l = strip($l);
        $reg{ $regof{ $l->{referencedDecl}{id} } } //= $r if ($l->{kind} // '') eq 'DeclRefExpr' && $regof{ $l->{referencedDecl}{id} // '' };
    }
    my ($nr, $ar) = $reg{a7} ? ('a7', 'a') : $reg{x8} ? ('x8', 'x') : return undef;
    my %l;
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st, kids($inner)) {
        for my $v (kids($s)) { my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v); $l{ $v->{name} } = $init if $init && !$regof{ $v->{id} } }
    }
    my @a;
    for my $i (0 .. 5) {
        my $e = $reg{"$ar$i"} or last;
        my $s = strip($e);
        $e = $l{ $s->{referencedDecl}{name} } if $s->{kind} eq 'DeclRefExpr' && $l{ $s->{referencedDecl}{name} };
        push @a, E(strip($e));
    }
    '(syscall ' . join(' ', E(strip($reg{$nr})), @a) . ')';
}

# x86_64's INTERNAL_SYSCALL, as c2ff's syscall_idiom_x86 takes it: in the
# statement expression only declarations (register variables rdi rsi rdx
# r10 r8 r9 = the arguments, from the __argN before them), the asm syscall
# ("=a" the result, "0" the number) and the result last; inputs in rdi rsi
# rdx by their constraints (D S d) too.
sub syscall_idiom_x86 {
    my ($cs) = @_;
    my @st = kids($cs);
    my @asm = grep { $_->{kind} eq 'GCCAsmStmt' } @st;
    return undef unless @asm == 1;
    my ($template, $oc, $ic) = asm_text($asm[0]);
    return undef unless defined $template && $template =~ /^\s*syscall[\s;]*$/ && @$oc == 1 && $oc->[0] eq '=a';
    my @ops = kids($asm[0]);
    my ($num) = grep { $ic->[$_] eq '0' } 0 .. $#$ic;
    return undef unless defined $num;
    my @other = grep { $_->{kind} ne 'DeclStmt' && $_->{kind} ne 'GCCAsmStmt' } @st;
    return undef if @other > 1;
    if (@other) {
        my $last = strip($other[0]);
        return undef unless $other[0] == $st[-1] && ($last->{kind} // '') eq 'DeclRefExpr' && ($last->{referencedDecl}{id} // '') eq (strip($ops[0])->{referencedDecl}{id} // '-');
    }
    my (%reg, %l);
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            next unless $init;
            if ($lab) { my $r = $lab->{label} // (($v->{name} // '') =~ /^_a([1-6])$/ ? (qw(rdi rsi rdx r10 r8 r9))[$1 - 1] : undef); $reg{$r} = $init if defined $r }
            elsif (defined $v->{name}) { $l{ $v->{name} } = $init }
        }
    }
    my %creg = (D => 'rdi', S => 'rsi', d => 'rdx');
    for my $j (0 .. $#$ic) { my $r = $creg{ $ic->[$j] } or next; $reg{$r} //= $ops[@$oc + $j] }
    my @a;
    for my $r (qw(rdi rsi rdx r10 r8 r9)) {
        my $e = $reg{$r} or last;
        my $s = strip($e);
        $e = $l{ $s->{referencedDecl}{name} } if ($s->{kind} // '') eq 'DeclRefExpr' && $l{ $s->{referencedDecl}{name} };
        push @a, E(strip($e));
    }
    '(syscall ' . join(' ', E(strip($ops[@$oc + $num])), @a) . ')';
}
our ($unit_i, $itext_of, $itext) = ('', '', '');
# arm's INTERNAL_SYSCALL, as c2ff's syscall_idiom_arm takes it: register
# variables r0 (or a1), a2 a3 a4 v1 v2 v3 the arguments, r7 the number, each
# set by its declaration or an assignment after it (from the _aNtmp before
# them), the asm swi 0x0 with the output "=r"
sub syscall_idiom_arm {
    my ($cs) = @_;
    my @st = kids($cs);
    my @asm = grep { $_->{kind} eq 'GCCAsmStmt' } @st;
    return undef unless @asm == 1;
    my ($template, $oc) = asm_text($asm[0]);
    return undef unless defined $template && $template =~ /^\s*swi\s+0x0\b/ && @$oc == 1 && $oc->[0] eq '=r';
    my %argno = (r0 => 0, a1 => 0, r1 => 1, a2 => 1, r2 => 2, a3 => 2, r3 => 3, a4 => 3, r4 => 4, v1 => 4, r5 => 5, v2 => 5, r6 => 6, v3 => 6);
    my (%regof, %reg, %l);
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            if ($lab) { my $r = asm_label($lab) // next; $regof{ $v->{name} } = $r; $reg{$r} = $init if $init }
            elsif ($init && defined $v->{name}) { $l{ $v->{name} } = $init }
        }
    }
    for my $s (grep { $_->{kind} eq 'BinaryOperator' && ($_->{opcode} // '') eq '=' } @st) {
        my ($lhs, $rhs) = kids($s);
        $lhs = strip($lhs);
        next unless ($lhs->{kind} // '') eq 'DeclRefExpr' && defined $regof{ $lhs->{referencedDecl}{name} // '' };
        $reg{ $regof{ $lhs->{referencedDecl}{name} } } = $rhs;
    }
    return undef unless defined $reg{r7};
    my %byno = map { ($argno{$_} => $reg{$_}) } grep { defined $argno{$_} } keys %reg;
    my @a;
    for my $i (0 .. 6) {
        my $e = $byno{$i} or last;
        my $s = strip($e);
        $e = $l{ $s->{referencedDecl}{name} } if ($s->{kind} // '') eq 'DeclRefExpr' && $l{ $s->{referencedDecl}{name} };
        push @a, E(strip($e));
    }
    '(syscall ' . join(' ', E(strip($reg{r7})), @a) . ')';
}
# a register variable's register: from the .i where its attribute begins,
# asm ("r0") or "r0" (clang's AST has no label)
sub asm_label {
    my ($a) = @_;
    return $a->{label} if defined $a->{label};
    my $b = $a->{range}{begin}{offset} // ($a->{range}{begin}{expansionLoc} // {})->{offset};
    return undef unless defined $b && $unit_i ne '' && -e $unit_i;
    if ($itext_of ne $unit_i) { open my $h, '<', $unit_i or return undef; local $/; $itext = <$h>; $itext_of = $unit_i }
    substr($itext, $b, 80) =~ /^(?:(?:__asm__|__asm|asm)\s*\(\s*)?"(\w+)"/ ? $1 : undef;
}
# An asm statement's template and constraints, from the unit's .i (next to
# its AST, at the offset clang gives), as c2ff reads them (asm_parts).
sub asm_text {
    my ($n) = @_;
    my $b = $n->{range}{begin}{offset} // ($n->{range}{begin}{expansionLoc} // {})->{offset};
    return () unless defined $b && $unit_i ne '' && -e $unit_i;
    if ($itext_of ne $unit_i) { open my $h, '<', $unit_i or return (); local $/; $itext = <$h>; $itext_of = $unit_i }
    (my $s = substr($itext, $b, 4000)) =~ s/^#.*\n//mg;
    $s =~ s/^\s*(?:__asm__|__asm|asm)\s*(?:(?:__volatile__|__volatile|volatile)\s*)?\(// or return ();
    my ($depth, $instr, $esc, @parts) = (0, 0, 0, '');
    for my $c (split //, $s) {
        if ($instr) { $parts[-1] .= $c; if ($esc) { $esc = 0 } elsif ($c eq '\\') { $esc = 1 } elsif ($c eq '"') { $instr = 0 } next }
        if ($c eq '"') { $instr = 1 } elsif ($c eq '(') { $depth++ } elsif ($c eq ')') { last if $depth == 0; $depth-- }
        if ($c eq ':' && $depth == 0) { push @parts, ''; next }
        $parts[-1] .= $c;
    }
    my ($tmpl, $outs, $ins) = @parts;
    my $template = join '', ($tmpl // '') =~ /"((?:[^"\\]|\\.)*)"/g;
    $template =~ s/\\t/ /g;
    $template =~ s/\\n/;/g;
    ($template, [($outs // '') =~ /"([^"]*)"/g], [($ins // '') =~ /"([^"]*)"/g]);
}
# glibc's optimization barrier, asm ("" : "+r" (x)): c2ff makes no code of it
sub asm_barrier {
    my ($n) = @_;
    my ($t, $oc) = asm_text($n);
    defined $t && $t !~ /\S/ && @$oc && !grep { !/\+/ || !/^[=+&]*[rx]+$/ } @$oc;
}

# A declaration's value: a char array set from a text as the text's codes, the
# zeros at its end the rest
sub var_init {
    my ($d) = @_;
    my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($d);
    return undef unless $init;
    my $u = unparen($init);
    return text_codes($d, E($u)) if ($u->{kind} // '') eq 'StringLiteral' && tcls($d) =~ /^arr\(/;
    E($init);
}
# A text that sets an array: its codes as the array's items, the zeros at its
# end the rest
sub text_codes {
    my ($n, $str) = @_;
    my ($w, $codes) = $str =~ /^\(str (w?)([-\d,]*)\)$/ or return $str;
    my ($elem) = tcls($n) =~ /^arr\((\w+),/;
    $elem = 'char' if !$w || $elem =~ /^(u8|i8)$/;
    # (a wide text's codes are small literals: aarch64's wchar_t is a u32)
    $elem = 'i32' if $elem =~ /^[iu]32$/;
    my @c = split /,/, $codes;
    pop @c while @c && $c[-1] == 0;
    @c ? '(init' . join('', map { $_ == 0 ? ' (zero)' : " (int $_ $elem)" } @c) . ')' : '(zero)';
}
sub is_zero_form { $_[0] =~ /^\((?:int 0 \S+|null \S+|init|zero|cast \w+ \S+ \(int 0 \S+\))\)$/ }
# A global: its type and its value, nothing an empty one
sub gnorm {
    my ($d) = @_;
    local $in_global = 1;
    my $i = var_init($d);
    $i = '(zero)' if !defined $i || is_zero_form($i);
    # (an anonymous enum is an int in ff)
    '(global ' . (tcls($d) =~ s/^enum$/i32/r) . " $i)";
}
sub balanced { my ($s) = @_; my $d = 0; for my $c (split //, $s) { $d++ if $c eq '('; $d--, ($d < 0 and return 0) if $c eq ')' } !$d }
# The values of an AST's enum constants (clang's, else one more than the one before)
sub enumvals {
    my ($ast) = @_;
    my %v;
    my @q = ($ast);
    while (my $n = shift @q) {
        if (($n->{kind} // '') eq 'EnumDecl') {
            my $x = -1;
            for my $c (grep { $_->{kind} eq 'EnumConstantDecl' } kids($n)) {
                my ($e) = grep { $_->{kind} !~ /Attr$/ } kids($c);
                $e = (kids($e))[0] while $e && $e->{kind} =~ /^(ImplicitCastExpr|ParenExpr)$/;
                $x = $e && $e->{kind} eq 'ConstantExpr' ? $e->{value} : $x + 1;
                $v{ $c->{name} } //= $x;
            }
            next;
        }
        push @q, @{ $n->{inner} || [] };
    }
    %v;
}
sub holds { my ($n, $k) = @_; (($n->{kind} // '') eq $k) || grep { holds($_, $k) } kids($n) }
# Statements, as a list.
sub S {
    my @out;
    for my $n (@_) {
        next unless $n && $n->{kind};
        my $k = $n->{kind};
        if ($k eq 'CompoundStmt') {
            # (c2ff's x = setjmp (...) through a local of its own, returns
            # twice, is that assignment)
            my @c = kids($n);
            my ($v) = @c == 2 && $c[0]{kind} eq 'DeclStmt' ? kids($c[0]) : ();
            my $as = @c == 2 ? unparen($c[1]) : undef;
            if ($side eq 'ff' && $v && ($v->{name} // '') =~ /^returns_?twice$/ && $as->{kind} eq 'BinaryOperator' && $as->{opcode} eq '=') {
                my ($l, $r) = kids($as);
                my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
                my $rr = strip($r);
                if ($init && $rr->{kind} eq 'DeclRefExpr' && ($rr->{referencedDecl}{name} // '') eq $v->{name}) {
                    push @out, '(= ' . E($l) . ' ' . E($init) . ')';
                    next;
                }
            }
            # (one statement in braces is that statement: c2ff writes C's
            # parentheses as :, which is a block as a statement)
            push @out, brace(S(@c));
            next;
        }
        if ($k eq 'DeclStmt') {
            for my $d (kids($n)) {
                next unless $d->{kind} eq 'VarDecl';
                next if ($d->{storageClass} // '') eq 'extern';
                next if ($d->{storageClass} // '') eq 'static' && !holds($d, 'AddrLabelExpr');
                my $i = var_init($d);
                push @out, '(var ' . ($d->{name} =~ s/'$//r) . ' ' . (tcls($d) =~ s/^enum$/i32/r) . (defined $i ? " $i" : '') . ')';
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
        # (a label's attribute, ret0: __attribute__ ((unused)), says nothing of the code: c2ff leaves it)
        if ($k eq 'LabelStmt') { push @out, "(label $n->{name})", S(grep { $_->{kind} !~ /Attr$/ } kids($n)); next }
        if ($k eq 'AttributedStmt') { push @out, S(grep { $_->{kind} !~ /Attr$/ } kids($n)); next }
        next if $k eq 'NullStmt';
        if ($k eq 'ReturnStmt') { push @out, '(return' . ($n->{inner} ? ' ' . E((kids($n))[0]) : '') . ')'; next }
        if ($k eq 'BreakStmt') { push @out, '(break)'; next }
        if ($k eq 'ContinueStmt') { push @out, '(continue)'; next }
        if ($k eq 'GotoStmt') { push @out, '(goto ' . ($labels{ $n->{targetLabelDeclId} } // '?') . ')'; next }
        if ($k eq 'IndirectGotoStmt') { push @out, '(goto* ' . E((kids($n))[0]) . ')'; next }
        if ($k eq 'GCCAsmStmt') { push @out, '(asm)' unless $side eq 'glibc' && asm_barrier($n); next }
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
sub locals_decls { my ($n) = @_; (($n->{kind} // '') =~ /^(ParmVarDecl|VarDecl)$/ ? $n : ()), map { locals_decls($_) } kids($n) }
sub locals_of { my ($n) = @_; (($n->{kind} // '') =~ /^(ParmVarDecl|VarDecl)$/ ? ($n->{id} => 1) : ()), map { locals_of($_) } kids($n) }
our %ltype;

sub typeof_expr {
    my ($e) = @_;
    $e =~ s/__attribute__\s*\(\(address_space\(257\)\)\)//g;
    $e =~ s/^\s+|\s+$//g;
    ($e = $1) =~ s/^\s+|\s+$//g while $e =~ /^(\((?:[^()]++|(?1))*\))$/ && $e =~ /^\((.*)\)$/s;
    return $ltype{$e} if exists $ltype{$e};
    return $declty{$e} if exists $declty{$e};
    if ($e =~ /^\*(.*)$/s) {
        my $t = typeof_expr($1) // return undef;
        $t = noattr($t);
        $t =~ s/\s*\b(?:const|volatile)\s*$//;
        return $t =~ /^(.*?)\s*\*$/ ? $1 : undef;
    }
    return $1 =~ s/^\s+|\s+$//gr if $e =~ /^\(([^()]*\*)\s*\)\s*\S/;
    undef;
}
sub fnorm {
    my ($fn) = @_;
    local %ltype = map { ($_->{name} => $_->{type}{qualType}) } grep { defined $_->{name} && $_->{type} } locals_decls($fn);
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

my (%back, %backg);
{
    my $ast = load($backjson);
    local $side = 'ff';
    local %tdef = typedefs($ast);
    local %typeof = typeofs($ast);
    local %declty = map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} =~ /^(FunctionDecl|VarDecl)$/ && defined $_->{name} && $_->{type} } kids($ast);
    local %enumval = enumvals($ast);
    for my $d (kids($ast)) {
        if ($d->{kind} eq 'VarDecl' && ($d->{storageClass} // '') ne 'extern') { $backg{ $d->{name} } = gnorm($d); next }
        next unless $d->{kind} eq 'FunctionDecl' && grep { $_->{kind} eq 'CompoundStmt' } kids($d);
        $back{ $d->{name} } = fnorm($d);
    }
}
my %byunit;
push @{ $byunit{ $_->[2] =~ s/\.i$/.json/r } }, $_ for grep { $_->[3] eq 'body' } @bodies;
my %fnunit = map { ($_->[1] => $_->[2] =~ s/\.i$/.json/r) } @bodies;
my ($same, @diff) = (0);
my @failed = grep { $_->[3] eq 'failed' } @bodies;
# the globals wanted: by name, a unit's own in that unit, a function's static in it
my (%gwant, %gfound);
for my $g (grep { $_->[3] eq 'global' } @globals) {
    my ($cid, $o, $hint) = @$g;
    push @{ $gwant{$o} }, $g;
}
my %seen;
my %gextern;
for my $j (grep { !$seen{$_}++ } @unitjson, sort keys %byunit) {
    my $ast = load($j);
    local %enumval = enumvals($ast);
    local $side = 'glibc';
    local $unit_i = $j =~ s/\.json$/.i/r;
    local %regvar;
    local %asmalias = map { ((kids($_))[0]{value} // '') =~ /^"\s*([.\w]+)\s*=\s*([.\w]+)\s*"$/ ? ($1 => $2) : () } grep { $_->{kind} eq 'FileScopeAsmDecl' } kids($ast);
    local %tdef = typedefs($ast);
    local %typeof = typeofs($ast);
    local %declty = map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} =~ /^(FunctionDecl|VarDecl)$/ && defined $_->{name} && $_->{type} } kids($ast);
    local %errordecl = errordecls($ast);
    local %constint = map {
        my ($e) = grep { $_->{kind} !~ /Attr$/ } kids($_);
        $e = (kids($e))[0] while $e && $e->{kind} =~ /^(ImplicitCastExpr|ParenExpr|ConstantExpr)$/;
        $e && $e->{kind} eq 'IntegerLiteral' ? ($_->{name} => $e->{value}) : ()
    } grep { $_->{kind} eq 'VarDecl' && ($_->{type}{qualType} // '') =~ /^const (?:(?:unsigned |signed )?(?:char|short|int|long|long long)(?: int)?|unsigned)$/ && ($_->{init} // '') eq 'c' } kids($ast);
    my %def;
    for my $d (kids($ast)) {
        if ($d->{kind} eq 'VarDecl' && ($d->{storageClass} // '') eq 'register' && (my ($l) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($d))) {
            $regvar{ $d->{name} } = $d->{mangledName} // $l->{label};
        }
        $def{ $d->{name} } = $d if $d->{kind} eq 'FunctionDecl' && grep { $_->{kind} eq 'CompoundStmt' } kids($d);
    }
    # its globals: a definition (an extern declaration is none), the first unit's
    for my $d (kids($ast)) {
        next unless $d->{kind} eq 'VarDecl' && defined $d->{name} && $gwant{ $d->{name} };
        # (one glibc's asm only reserves, zero, c2ff --zero: its declaration)
        if (($d->{storageClass} // '') eq 'extern') { $gextern{ $d->{name} } //= '(global ' . tcls($d) . ' (zero))'; next }
        for my $g (@{ $gwant{ $d->{name} } }) {
            next if $g->[2] =~ /^in / || $gfound{ $g->[0] };
            next if $g->[2] =~ /^unit (.+)$/ && $j !~ /\/\Q$1\E\.json$/;
            $gfound{ $g->[0] } = gnorm($d);
        }
    }
    # and its functions' statics
    for my $d (kids($ast)) {
        next unless $d->{kind} eq 'FunctionDecl' && defined $d->{name} && ($fnunit{ $d->{name} } // '') eq $j && grep { $_->{kind} eq 'CompoundStmt' } kids($d);
        my @q = kids($d);
        while (my $n = shift @q) {
            if (($n->{kind} // '') eq 'VarDecl' && ($n->{storageClass} // '') eq 'static' && $gwant{ $n->{name} // '' }) {
                for my $g (@{ $gwant{ $n->{name} } }) { $gfound{ $g->[0] } //= gnorm($n) if $g->[2] eq "in $d->{name}" }
            }
            push @q, kids($n);
        }
    }
    for my $b (@{ $byunit{$j} // [] }) {
        my ($cid, $o) = @$b;
        my $d = $def{$o} or do { push @diff, [$cid, "no function $o in $j"]; next };
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
my ($gsame, @gdiff) = (0);
for my $g (@globals) {
    my ($cid, $o, $hint, $k) = @$g;
    if ($k eq 'gfailed') { push @gdiff, [$cid, 'ff2c could not write it back']; next }
    my $want = $gfound{$cid} // $gextern{$o} // do { push @gdiff, [$cid, "no definition of $o in glibc's units ($hint)"]; next };
    my $got = $backg{$cid} // do { push @gdiff, [$cid, 'not in the C written back']; next };
    print "glibc: $want\nff:    $got\n" if ($ENV{ROUNDTRIP_SHOW} // '') eq $cid;
    if ($want eq $got) { $gsame++; next }
    push @gdiff, [$cid, where($want, $got)];
}
print "roundtrip: $_->[0]: $_->[1]\n" for @diff, @gdiff;
print "roundtrip: $_->[1]: ff2c could not write it back\n" for @failed;
printf "roundtrip: %d of %d functions and %d of %d globals as glibc's C\n", $same, scalar(@bodies), $gsame, scalar(@globals);
exit(@diff || @failed || @gdiff ? 1 : 0);
