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
# All of glibc, a part at a time (../compiler/gen/rtall.sh): each part's normal
# forms are kept in a file of their own, no AST need stay on disk, and then
#   perl roundtrip.pl [--target t] --norm-back OUT names.txt back.json
#   perl roundtrip.pl [--target t] --norm-unit OUT names.txt unit.json file
#   perl roundtrip.pl [--target t] --join names.txt back.norm ... -- unit.norm ...
# back.json is clang's AST of one of ff2c --split's files, unit.json the name
# of a unit as names.txt has it (its .i's, with .json) and file its AST (- is
# the standard input). --join compares as above, units in the order given:
# the first unit's global, as above; a @file argument holds a list.
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
use feature 'current_sub';
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";
use FFold;
use Storable qw(nstore retrieve dclone);
use Digest::MD5 qw(md5_hex);
my $json = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };

our $target = '';
if (@ARGV >= 2 && $ARGV[0] eq '--target') { (undef, $target) = splice @ARGV, 0, 2 }
FFold::x87() if $target eq 'x86_64';
my ($norm_back, $norm_unit, $join, $unit_cache, $cached, $cachedir);
if (@ARGV >= 2 && $ARGV[0] eq '--norm-back') { (undef, $norm_back) = splice @ARGV, 0, 2 }
elsif (@ARGV >= 2 && $ARGV[0] eq '--norm-unit') { (undef, $norm_unit) = splice @ARGV, 0, 2 }
elsif (@ARGV && $ARGV[0] eq '--join') { shift @ARGV; $join = 1 }
elsif (@ARGV >= 2 && $ARGV[0] eq '--unit-cache') { (undef, $unit_cache) = splice @ARGV, 0, 2; unshift @ARGV, '/dev/null' }
# (--cached: each unit's cache (--unit-cache) where it is made, beside its
# .json, or in DIR with --cached-in DIR (DIR, then the .json's path))
if (@ARGV && $ARGV[0] eq '--cached') { shift @ARGV; $cached = 1 }
elsif (@ARGV >= 2 && $ARGV[0] eq '--cached-in') { (undef, $cachedir) = splice @ARGV, 0, 2; $cached = 1 }
@ARGV = map { /^@(.+)$/ ? do { open my $h, "<", $1 or die "roundtrip: cannot open $1: $!\n"; map { chomp; s{^\s+}{}; length ? $_ : () } <$h> } : $_ } @ARGV;
my ($namesfile, $backjson, @unitjson) = @ARGV;
# (ROUNDTRIP_NORMS=file: glibc's normal form of each function and global compared, there)
my $normsout;
if ($ENV{ROUNDTRIP_NORMS}) { open $normsout, '>', $ENV{ROUNDTRIP_NORMS} or die "roundtrip: $ENV{ROUNDTRIP_NORMS}: $!\n" }
die "usage: roundtrip.pl [--target t] [--cached] names.txt back.json [unit.json ...]\n" unless defined $backjson;

my (@bodies, %orig, %asmfn, %noproto, @globals);
open my $h, '<', $namesfile or die "roundtrip: $namesfile: $!\n";
while (<$h>) {
    chomp;
    my ($k, $cid, $o, $unit) = split /\t/;
    if ($k eq 'asm') { $asmfn{$o} = 1; next }
    if ($k eq 'noproto') { $noproto{$o} = 1; next }
    if ($k eq 'global' || $k eq 'gfailed') { push @globals, [$cid, $o, $unit, $k]; next }
    $orig{$cid} = $o;
    push @bodies, [$cid, $o, $unit, $k] if $k eq 'body' || $k eq 'failed';
}
close $h;

sub load { my ($f) = @_; my $h = \*STDIN; if ($f ne '-') { open $h, '<', $f or die "roundtrip: $f: $!\n" } local $/; $json->decode(<$h>) }
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
# A variable-length array's count, from the text clang has of it, the same
# however it is parenthesized: as prefix, each name as glibc has it. Text it
# cannot read stays as it is, without spaces, and so is still compared.
sub vla_norm {
    my ($c) = @_;
    my $text = $c =~ s/\s+//gr;
    (my $t = $c) =~ s{\bsizeof\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)}{ (my $b = $1) =~ s/\\./x/g; length($b) + 1 }ge;
    my @tok;
    push @tok, $1 while $t =~ /\G\s*([A-Za-z_]\w*|\d+\b|<=|>=|==|!=|[-+*\/%<>?:(),])/gc;
    return $text unless $t =~ /\G\s*$/;
    my $r = eval { vla_binary(\@tok, 0) };
    defined $r && !@tok ? $r : $text;
}
my %vlaprec = ('?' => 1, '==' => 2, '!=' => 2, '<' => 3, '>' => 3, '<=' => 3, '>=' => 3, '+' => 4, '-' => 4, '*' => 5, '/' => 5, '%' => 5);
sub vla_binary {
    my ($tok, $min) = @_;
    my $l = vla_primary($tok);
    while (@$tok && ($vlaprec{ $tok->[0] } // 0) > $min) {
        my $op = shift @$tok;
        if ($op eq '?') {
            my $a = vla_binary($tok, 0);
            (shift(@$tok) // '') eq ':' or die;
            my $b = vla_binary($tok, 0);
            $l = "(? $l $a $b)";
        } else {
            $l = "($op $l " . vla_binary($tok, $vlaprec{$op}) . ')';
        }
    }
    $l;
}
sub vla_primary {
    my ($tok) = @_;
    my $t = shift(@$tok) // die;
    if ($t eq '(') { my $r = vla_binary($tok, 0); (shift(@$tok) // '') eq ')' or die; return $r }
    return $t if $t =~ /^\d/;
    $t =~ /^[A-Za-z_]/ or die;
    $t = our $side eq 'ff' ? $orig{$t} // $t : $t =~ s/^__builtin_((?:mem|str|stp)\w+)$/$1/r;
    return $t unless @$tok && $tok->[0] eq '(';
    shift @$tok;
    my @a;
    while (@$tok && $tok->[0] ne ')') {
        push @a, vla_binary($tok, 0);
        shift @$tok if @$tok && $tok->[0] eq ',';
    }
    (shift(@$tok) // '') eq ')' or die;
    "(call $t @a)";
}
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
    # (a 128-bit integer, under its names)
    return '__int128' if $s =~ /^(?:signed )?__int128$|^__int128_t$/;
    return 'unsigned __int128' if $s =~ /^unsigned (?:int )?__int128$|^__uint128_t$/;
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
    # (a pointer to an array, an array of function pointers, as C spells them)
    if ($s =~ /^(.*)\(\*\)((?:\[\d*\])+)$/) { my ($e, $r) = ($1, $2); $e =~ s/ $//; return 'ptr(' . tstr("$e$r") . ')' }
    if ($s =~ /\(\*\[(\d*)\]\)\s*\(/) { my $c = $1; return "arr(fnptr,$c)" }
    return 'fnptr' if $s =~ /\(\*+\)\s*\(/ || $s =~ /\(\*\)$/;
    return 'fn' if $s =~ /\)$/ && $s =~ /^[^(]+\(/ && $s !~ /^(?:struct|union|enum) \(/;
    # (T[n][m] is n of T[m]: the first count is the array's)
    if ($s =~ /^([^\[\]()]*)\[(\d*)\]((?:\[\d*\])*)$/) { my ($e, $c, $r) = ($1, $2, $3); return 'arr(' . tstr("$e$r") . ",$c)" }
    if ($s =~ /^(.*)\[(\d*)\]$/) { my ($e, $c) = ($1, $2); return 'arr(' . tstr($e) . ",$c)" }
    if ($s =~ /^(.*?)\[([^\[\]]*[A-Za-z_(][^\[\]]*)\]$/) { my ($e, $c) = ($1, $2); return 'vla(' . tstr($e) . ',' . vla_norm($c) . ')' }
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

our %staticid;
our %constid;              # a function's static consts of a literal, by id: their values
our ($side, %labels, %regvar, %local, $in_global, %enumval, %asmalias, %x87in);   # 'glibc' or 'ff'; the function's labels; the unit's register variables
sub strip { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr|ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub unparen { my ($n) = @_; $n = (kids($n))[0] while $n && ($n->{kind} // '') =~ /^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/; $n }
sub name_of {
    my ($d) = @_;
    my $n = $d->{name} // '';
    return $orig{$n} // $n if $side eq 'ff';
    return $regvar{$n} if $d->{kind} eq 'VarDecl' && $regvar{$n} && !$local{ $d->{id} };
    return $staticid{ $d->{id} } if defined $d->{id} && $staticid{ $d->{id} };
    $n =~ s/^__builtin_((?:mem|str|stp)\w+|free|malloc)$/$1/;
    # (a call of copysign or fabs: of its builtin, as c2ff writes it)
    $n = "__builtin_$n" if $n =~ /^(?:copysign|fabs)(?:[fl]|f128)?$/ && $d->{kind} eq 'FunctionDecl';
    $n = '__builtin_va_start' if $n eq '__builtin_c23_va_start';
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
        : $t eq 'long double' || $t eq 'float128' ? '(fltl ' . FFold::qlit($v->{q}, $v->{e}, 16383) . ')'
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
        # (a const integer of a number read in a global's items: the number, as c2ff)
        if ($in_global && $ck eq 'LValueToRValue' && (my $rd = (strip($n) // {})->{referencedDecl})) {
            my $v = $constid{ $rd->{id} // '' } // ($rd->{kind} eq 'VarDecl' && ($rd->{type}{qualType} // '') =~ /\bconst\b/ ? $constint{ $rd->{name} // '' } : undef);
            return "(int $v i32)" if defined $v;
        }
        # a conversion to _Bool: in ff (where it is a u8) a compare with 0
        # (what the operand is converted to first does not matter then)
        return '(tobool ' . E(unimplicit($c)) . ')' if $ck =~ /ToBoolean$/;
        # (a complex value's real part, its conversion to a real type: csema
        # writes it so, cast T / real x)
        return '(u__real ' . E($c) . ')' if $ck eq 'FloatingComplexToReal';
        # (C23's true and false, a bool's own, are c2ff's 1 and 0, a u8 there:
        # a 1 or 0 converted to a u8 is that literal, on both sides)
        if ($ck eq 'IntegralCast' && tcls($n) eq 'u8' && !$in_global && (unparen($c)->{kind} // '') eq 'IntegerLiteral' && (unparen($c)->{value} // '') =~ /^[01]$/) { return E(unparen($c)) }
        if ($ck eq 'IntegralCast' && tcls($n) eq 'u8' && ($side eq 'ff' || $k eq 'ImplicitCastExpr')) {
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
        # (clang's type of __builtin_copysignf16's parameters, __fp16: as _Float16; c2ff's casts to float16 are there)
        return E($c) if $ck eq 'FloatingCast' && tcls($n) =~ /__fp16/;
        return "(cast $ck " . (tcls($n) =~ s/__fp16/_Float16/r) . ' ' . E($c) . ')';
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
    # (x86_64's long double the x87's 64 bits; its _Float128 binary128's)
    return '(fltl ' . FFold::ldround($n->{value}, 64, -16445, 16383) . ')' if $k eq 'FloatingLiteral' && tcls($n) eq 'ldouble' && $target eq 'x86_64' && FFold::ftype($n) eq 'long double';
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
        # (! of a complex value, which clang tests as it is: csema's test of
        # its parts is that value)
        return '(u! ' . ET($c) . ')' if $op eq '!';
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
        # (csema's complex c op= b: c = c op b, of its parts)
        if ($side eq 'ff' && $n->{opcode} eq '=' && (my @x = cxlow(unparen($r))) > 2) {
            my $el = E($l);
            return "($x[1]= $el $x[3])" if $x[1] =~ m{^[-+*/]$} && $x[2] eq $el;
        }
        return "($n->{opcode} " . ET($l) . ' ' . ET($r) . ')' if $n->{opcode} =~ /^(&&|\|\|)$/;
        return "($n->{opcode} " . E($l) . ' ' . E($r) . ')';
    }
    if ($k eq 'ConditionalOperator') { my ($c, $a, $b) = kids($n); return '(?: ' . ET($c) . ' ' . E($a) . ' ' . E($b) . ')' }
    if ($k eq 'BinaryConditionalOperator') { my @k = kids($n); return '(?2 ' . E($k[0]) . ' ' . E($k[3]) . ')' }
    if ($k eq 'ArraySubscriptExpr') { my ($b, $i) = kids($n); return '(u* (+ ' . E($b) . ' ' . E($i) . '))' }
    if ($k eq 'MemberExpr') {
        my ($b) = kids($n);
        # (an anonymous member is no step of its own)
        return E($b) if ($n->{name} // '') eq '';
        return '(mem ' . ($n->{isArrow} ? '->' : '.') . ($n->{name} =~ s/'$//r) . ' ' . E($b) . ')';
    }
    # (__builtin_complex (x, 0) is x converted to the complex type, csema's
    # form of that conversion: complex T / x / 0)
    if ($k eq 'CallExpr' && ((strip((kids($n))[0]) // {})->{referencedDecl}{name} // '') eq '__builtin_complex' && kids($n) == 3 && is_zero((kids($n))[2])) {
        return "(cast FloatingRealToComplex " . tcls($n) . ' ' . E((kids($n))[1]) . ')';
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
        if (my ($f) = cxlow($n)) { return $f }
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
# csema's complex arithmetic (C's complex + - * / == != and unary - on
# their parts, as gcc does them, ttpc having no complex operator), written
# back as a statement expression: its operands in locals __cx_N first (one
# declared alone is assigned next), then the value. It is C's operator:
# __mulXc3 (re a, im a, re b, im b) is a * b, __divXc3 a / b (a real a: a,
# 0); __builtin_complex (re a + re b, im a + im b) is a + b, - a - b (a real
# operand stays real: re a + r, im a is a + r; r - re b, - im b is r - b),
# * and / of a real operand part by part; re a == re b && im a == im b is
# a == b (a real b: im a == 0), != with ||; - re a, - im a is - a; (re a,
# im a) of another type a's conversion; re a != 0 || im a != 0 its truth.
# Each operand is its local's value (a real one real, as clang has it).
# Returns (form, op, a, b), or () if it is no such statement expression.
sub cxlow {
    my ($n) = @_;
    return () unless $side eq 'ff' && ($n->{kind} // '') eq 'StmtExpr';
    my ($cs) = kids($n);
    my @s = kids($cs);
    return () unless @s >= 2;
    my %t;
    my $i = 0;
    while ($i < $#s) {
        my $st = $s[$i];
        return () unless ($st->{kind} // '') eq 'DeclStmt';
        my @v = kids($st);
        return () unless @v == 1 && ($v[0]{kind} // '') eq 'VarDecl' && ($v[0]{name} // '') =~ /^__cx_\d+$/;
        my $nm = $v[0]{name};
        my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v[0]);
        if (!$init) {
            return () unless $i + 1 < $#s;
            my $as = unparen($s[$i + 1]);
            return () unless ($as->{kind} // '') eq 'BinaryOperator' && $as->{opcode} eq '=';
            my ($l, $r) = kids($as);
            return () unless (strip($l)->{kind} // '') eq 'DeclRefExpr' && (strip($l)->{referencedDecl}{name} // '') eq $nm;
            $init = $r;
            $i++;
        }
        $t{$nm} = [$init, tcls($v[0]) !~ /_Complex/];
        $i++;
    }
    my $ct = tcls($n);
    my $part = sub {
        my $u = strip($_[0]);
        return ['zero'] if is_zero($u);
        if (($u->{kind} // '') eq 'UnaryOperator' && $u->{opcode} =~ /^__(real|imag)$/) {
            my $r = strip((kids($u))[0]);
            my $nm = ($r->{kind} // '') eq 'DeclRefExpr' ? $r->{referencedDecl}{name} // '' : '';
            return [$1 eq 'real' ? 're' : 'im', $nm] if $t{$nm} && !$t{$nm}[1];
        }
        if (($u->{kind} // '') eq 'DeclRefExpr' && $t{ $u->{referencedDecl}{name} // '' } && $t{ $u->{referencedDecl}{name} }[1]) { return ['val', $u->{referencedDecl}{name}] }
        if (($u->{kind} // '') eq 'UnaryOperator' && $u->{opcode} eq '-') { my $q = __SUB__->((kids($u))[0]); return ['neg', @$q] if $q && $q->[0] =~ /^(re|im)$/ }
        if (($u->{kind} // '') eq 'BinaryOperator') { return ['bin', $u->{opcode}, (kids($u))[0, 1]] }
        return undef;
    };
    my $opnd = sub { my ($nm) = @_; E($t{$nm}[0]) };
    my $is = sub { my ($p, $k, $nm) = @_; $p && $p->[0] eq $k && (!defined $nm || ($p->[1] // '') eq $nm) };
    my $R = strip($s[-1]);
    my $rk = $R->{kind} // '';
    my $res = sub { my ($op, $a, $b) = @_; defined $b ? ("($op $a $b)", $op, $a, $b) : ("($op $a)", $op, $a) };
    if ($rk eq 'CallExpr') {
        my ($f, @a) = kids($R);
        my $fn = (strip($f) // {})->{referencedDecl}{name} // '';
        if ($fn =~ /^__(mul|div)[sdxt]c3$/ && @a == 4) {
            my $op = $1 eq 'mul' ? '*' : '/';
            my @p = map { $part->($_) } @a;
            my @o;
            for my $j (0, 2) {
                if ($is->($p[$j], 're') && $is->($p[$j + 1], 'im', $p[$j][1])) { push @o, $opnd->($p[$j][1]) }
                elsif ($is->($p[$j], 'val') && $is->($p[$j + 1], 'zero')) { push @o, $opnd->($p[$j][1]) }
                else { return () }
            }
            return $res->($op, @o);
        }
        if ($fn eq '__builtin_complex' && @a == 2) {
            my ($x, $y) = map { $part->($_) } @a;
            return () unless $x && $y;
            # - a
            if ($x->[0] eq 'neg' && $y->[0] eq 'neg' && $x->[1] eq 're' && $y->[1] eq 'im' && $x->[2] eq $y->[2]) { return $res->('u-', $opnd->($x->[2])) }
            # a's conversion
            if ($x->[0] eq 're' && $y->[0] eq 'im' && $x->[1] eq $y->[1]) { return ("(cast FloatingComplexCast $ct " . $opnd->($x->[1]) . ')') }
            return () unless $x->[0] eq 'bin' && $x->[1] =~ m{^[-+*/]$};
            my $op = $x->[1];
            my ($l, $r) = map { $part->($_) } @$x[2, 3];
            return () unless $l && $r;
            my $yb = $y->[0] eq 'bin' && $y->[1] eq $op ? [map { $part->($_) } @$y[2, 3]] : undef;
            if ($is->($l, 're') && $is->($r, 're')) {
                return $res->($op, $opnd->($l->[1]), $opnd->($r->[1])) if $op =~ /^[-+]$/ && $yb && $is->($yb->[0], 'im', $l->[1]) && $is->($yb->[1], 'im', $r->[1]);
                return ();
            }
            if ($is->($l, 're') && $is->($r, 'val')) {
                return $res->($op, $opnd->($l->[1]), $opnd->($r->[1])) if ($op =~ /^[-+]$/ && $is->($y, 'im', $l->[1])) || ($op =~ m{^[*/]$} && $yb && $is->($yb->[0], 'im', $l->[1]) && $is->($yb->[1], 'val', $r->[1]));
                return ();
            }
            if ($is->($l, 'val') && $is->($r, 're')) {
                return $res->($op, $opnd->($l->[1]), $opnd->($r->[1])) if ($op eq '+' && $is->($y, 'im', $r->[1])) || ($op eq '-' && $y->[0] eq 'neg' && $y->[1] eq 'im' && $y->[2] eq $r->[1]) || ($op eq '*' && $yb && $is->($yb->[0], 'val', $l->[1]) && $is->($yb->[1], 'im', $r->[1]));
                return ();
            }
            return ();
        }
        return ();
    }
    if ($rk eq 'BinaryOperator' && $R->{opcode} =~ /^(&&|\|\|)$/) {
        my ($x, $y) = map { $part->($_) } kids($R);
        return () unless $x && $y && $x->[0] eq 'bin' && $y->[0] eq 'bin' && $x->[1] eq $y->[1];
        my $op = $x->[1];
        return () unless ($op eq '==' && $R->{opcode} eq '&&') || ($op eq '!=' && $R->{opcode} eq '||');
        my ($a1, $b1) = map { $part->($_) } @$x[2, 3];
        my ($a2, $b2) = map { $part->($_) } @$y[2, 3];
        return () unless $a1 && $b1 && $a2 && $b2;
        if ($op eq '!=' && $is->($a1, 're') && $is->($b1, 'zero') && $is->($a2, 'im', $a1->[1]) && $is->($b2, 'zero')) { my $v = E(unimplicit($t{ $a1->[1] }[0])); return ("(tobool $v)", 'tobool', $v) }
        my $side_of = sub { my ($p, $q) = @_; return $p->[1] if $is->($p, 're') && $is->($q, 'im', $p->[1]); return $p->[1] if $is->($p, 'val') && $is->($q, 'zero'); undef };
        my ($an, $bn) = ($side_of->($a1, $a2), $side_of->($b1, $b2));
        return () unless defined $an && defined $bn;
        return $res->($op, $opnd->($an), $opnd->($bn));
    }
    ();
}
# A value tested for truth (a condition, !, && and ||'s operands): clang
# tests a complex one as it is, csema by its parts (cxlow's tobool).
sub ET { my ($c) = @_; my @x = $c ? cxlow(unparen(strip($c))) : (); return $x[2] if ($x[1] // '') eq 'tobool'; E($c) }
sub unpromote { my ($n) = @_; $n = (kids($n))[0] while $n && (($n->{kind} // '') =~ /^(ParenExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/ || (($n->{kind} // '') eq 'ImplicitCastExpr' && ($n->{castKind} // '') !~ /ToBoolean$/)); $n }
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
# (what a normal form asks of names.txt, glibc's side: whether a name is an asm
# function, a weak one without parameters; each answer kept in %asked, so
# that a unit's cache tells where its normal forms hold)
our %asked;
sub asmfn { my ($x) = @_; my $v = $asmfn{$x} ? 1 : 0; $asked{"a $x"} = $v; $v }
sub noproto { my ($x) = @_; my $v = $noproto{$x} ? 1 : 0; $asked{"n $x"} = $v; $v }
sub is_asmfncall { my ($n) = @_; my $s = unparen($n); return 0 unless ($s->{kind} // '') eq 'CallExpr'; my $f = strip((kids($s))[0]) // {}; $f = fnaddr($f) // $f; my $d = $f->{referencedDecl} or return 0; asmfn(name_of($d)) }
# &f of a function f: its reference (a cast of it stripped before)
sub fnaddr {
    my ($c) = @_;
    return undef unless ($c->{kind} // '') eq 'UnaryOperator' && $c->{opcode} eq '&';
    my $r = strip((kids($c))[0]) // {};
    ($r->{kind} // '') eq 'DeclRefExpr' && ($r->{referencedDecl}{kind} // '') eq 'FunctionDecl' ? $r : undef;
}
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
    # (csema's call of an asm function whose value is no integer or pointer,
    # through its address cast to the declaration's pointer type, (*(T) &f)
    # (x), is the call f (x): the same prototype converts the arguments)
    $c = fnaddr($c) // $c;
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
                return "(cast BitCast ptr(void) (+ (call $mc" . join('', map { my $a = $_; $a = (kids($a))[0] while ($a->{kind} // '') =~ /CastExpr$/ && ($a->{castKind} // '') =~ /^(BitCast|NoOp)$/; ' ' . E($a) } @args) . ') ' . E($n2) . '))' if asmfn($mc);
                return "(cast BitCast ptr(void) (+ (cast BitCast ptr(u8) (call $mc" . join('', map { ' ' . E($_) } @args) . ')) ' . E($n2) . '))';
            }
            return '(int ' . ((strip($args[0])->{kind} // '') =~ /^(IntegerLiteral|CharacterLiteral)$/ ? 1 : 0) . ' i32)' if $name eq '__builtin_constant_p';
        }
        @args = ($args[0]) if $name eq '__builtin_va_start';
        # an asm function has no C type in ff: C's conversions of its arguments are not there
        @args = map { unimplicit($_) } @args if asmfn($name);
        # (a weak function's, declared without parameters on ff's side: C's
        # conversions of its arguments are not there, but a bool's, which
        # c2ff writes (x != 0))
        @args = map { unpromote($_) } @args if noproto($name);
        # (and ff's x != 0 for it, which a parameter's bool made (tobool x))
        @args = map { my $b = unparen($_); ($b->{kind} // '') eq 'BinaryOperator' && $b->{opcode} eq '!=' && is_zero((kids($b))[1])
            ? { kind => 'ImplicitCastExpr', castKind => 'IntegralToBoolean', type => $b->{type}, inner => [(kids($b))[0]] } : $_ } @args if $side eq 'ff' && noproto($name);
        # (nor its pointer arguments' conversions to void *, either side)
        @args = map { my $a = $_; $a = (kids($a))[0] while ($a->{kind} // '') =~ /^(ImplicitCastExpr|CStyleCastExpr)$/ && ($a->{castKind} // '') =~ /^(BitCast|NoOp)$/; $a } @args if asmfn($name);
        return '(asm)' if $name =~ /^_+asm_/;
        return '(syscall ' . join(' ', map { E(strip($_)) } @args) . ')' if $name eq '__ff_syscall';
        if ($side eq 'ff' && $name =~ /^__atomic_(\w+)_\d+$/ && $atomicop{$1}) { return "(atomic $1 " . join(' ', map { E(strip($_)) } @args) . ')' }
        # (and of a __builtin_mempcpy, whose sum ends in a conversion to
        # void *: memset's argument in _dl_allocate_tls_init)
        return "(call $name" . join('', map { my $e = E($_); $e =~ s/^\(cast BitCast ptr\(void\) (.*)\)$/$1/s if $side eq 'glibc' && is_mempcpy($_); ' ' . $e } @args) . ')' if asmfn($name);
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
# Does a value compute in floating point, as c2ff's fp_computes?
sub fp_computes {
    my ($n) = @_;
    my $k = $n->{kind} // '';
    my $q = $n->{type} ? $n->{type}{desugaredQualType} // $n->{type}{qualType} // '' : '';
    return 1 if $k =~ /^(?:BinaryOperator|UnaryOperator)$/ && $q =~ /^(?:float|double|long double|_Float\d+x?|__float128)$/;
    return 1 if $k =~ /CastExpr$/ && ($n->{castKind} // '') =~ /Floating/;
    !!grep { fp_computes($_) } kids($n);
}
# glibc's optimization barrier, asm ("" : "+r" (x)): c2ff makes no code of it
sub asm_barrier {
    my ($n) = @_;
    my ($t, $oc) = asm_text($n);
    # (and on x86_64, as c2ff, one with inputs alone: math_force_eval's,
    # __pthread_mutex_lock_full's; aarch64's +w too)
    defined $t && $t !~ /\S/ && ((@$oc && !grep { !/\+/ || ($target eq 'aarch64' ? !/^[=+&]*[rxw]+$/ : !/^[=+&]*[rx]+$/) } @$oc) || ($target eq 'x86_64' && !@$oc)
        # (aarch64's with inputs alone, of long doubles: math_force_eval's, as c2ff)
        || ($target eq 'aarch64' && !@$oc && (my @in = grep { $_->{kind} !~ /Attr$/ } kids($n)) && !grep { tcls($_) ne 'ldouble' } grep { $_->{kind} !~ /Attr$/ } kids($n)));
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
    # (a u16's, u"xy": an int's number converted, in the C ff2c writes)
    @c ? '(init' . join('', map { $_ == 0 ? ' (zero)' : $elem eq 'u16' ? " (cast IntegralCast u16 (int $_ i32))" : " (int $_ $elem)" } @c) . ')' : '(zero)';
}
sub is_zero_form { $_[0] =~ /^\((?:int 0 \S+|null \S+|init|zero|cast \w+ \S+ \(int 0 \S+\))\)$/ }
# A global: its type and its value, nothing an empty one
sub gnorm {
    my ($d) = @_;
    local $in_global = 1;
    my $i = var_init($d);
    $i = '(zero)' if !defined $i || is_zero_form($i);
    # (what c2ff works out: a constant sum, randtbl's &randtbl[SEP_3 + 1]; a scalar's items in braces)
    1 while $i =~ s/\(\+ \(int (\d+) i32\) \(int (\d+) i32\)\)/'(int ' . ($1 + $2) . ' i32)'/e;
    $i =~ s/\(\/ \(sizeof arr\(([^()]*(?:\([^()]*\))?[^()]*),(\d+)\)\) \(sizeof \1\)\)/(int $2 i32)/g;
    $i = $1 if $i =~ /^\(init (.*)\)$/s && balanced($1) && tcls($d) !~ /^(?:arr|rec|vla)/;
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
    my @all = @_;
    for my $ix (0 .. $#all) {
        my $n = $all[$ix];
        next unless $n && $n->{kind};
        next if $n->{cxdone};
        my $k = $n->{kind};
        # (csema's local of a struct, union or complex type whose value would be
        # written as a lone : or several items, which after it are its items:
        # declared, then assigned it; its complex arithmetic, a statement
        # expression, ?: or a comma)
        if ($side eq 'ff' && $k eq 'DeclStmt' && kids($n) == 1 && ($n->{inner}[0]{kind} // '') eq 'VarDecl' && !grep { $_->{kind} !~ /Attr$/ } kids($n->{inner}[0])) {
            my $d = $n->{inner}[0];
            my $q = $d->{type}{desugaredQualType} // $d->{type}{qualType} // '';
            my $as = $ix < $#all ? unparen($all[$ix + 1]) : undef;
            if ($q =~ /^(?:(?:const |volatile )*(?:struct|union) |.*_Complex)/ && $q !~ /[*\[(]/ && $as && ($as->{kind} // '') eq 'BinaryOperator' && $as->{opcode} eq '='
                && (strip((kids($as))[0])->{referencedDecl}{name} // '') eq ($d->{name} // '-')) {
                my $r = unparen((kids($as))[1]);
                my $rk = $r->{kind} // '';
                if (cxlow($r) || $rk =~ /^(StmtExpr|ConditionalOperator|BinaryConditionalOperator)$/ || ($rk eq 'BinaryOperator' && $r->{opcode} eq ',')) {
                    push @out, '(var ' . ($d->{name} =~ s/'$//r) . ' ' . tcls($d) . ' ' . E((kids($as))[1]) . ')';
                    $all[$ix + 1]{cxdone} = 1;
                    next;
                }
            }
        }
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
        # (csema's local of an x87 asm input that is a value, __x87_1 ...,
        # is that asm statement's operand: the statement after it, which
        # glibc's side has as (asm) or its barrier)
        if ($k eq 'DeclStmt' && $side eq 'ff' && kids($n) && !grep { ($_->{kind} // '') ne 'VarDecl' || ($_->{name} // '') !~ /^__x87_\d+$/ } kids($n)) {
            $x87in{ $_->{name} } = (grep { $_->{kind} !~ /Attr$/ } kids($_))[0] for kids($n);
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
            push @out, '(if ' . ET($c), body($t), ($e ? ('else', body($e)) : ()), ')';
            next;
        }
        if ($k eq 'WhileStmt') { my ($c, $b) = kids($n); push @out, '(while ' . ET($c), body($b), ')'; next }
        if ($k eq 'DoStmt') { my ($b, $c) = kids($n); push @out, '(do ' . ET($c), body($b), ')'; next }
        if ($k eq 'ForStmt') {
            my ($i, undef, $c, $s, $b) = kids($n);
            # an init declaring several: a block holding them and the loop (as c2ff has it)
            if ($i && $i->{kind} && $i->{kind} eq 'DeclStmt' && kids($i) > 1) {
                push @out, '{', S($i), '(for - ' . ET($c) . ' ' . effect($s), body($b), ')', '}';
                next;
            }
            push @out, '(for ' . ($i && $i->{kind} ? ($i->{kind} eq 'DeclStmt' ? join(' ', S($i)) : effect($i)) : '-') . ' ' . ET($c) . ' ' . effect($s), body($b), ')';
            next;
        }
        if ($k eq 'SwitchStmt') { my ($v, $b) = kids($n); push @out, '(switch ' . E($v), body($b), ')'; next }
        if ($k eq 'CaseStmt') { my @k = kids($n); my $sub = pop @k; push @out, '(case ' . join(' ', map { E($_) } @k) . ')', S($sub); next }
        if ($k eq 'DefaultStmt') { push @out, '(default)', S(kids($n)); next }
        # (a label's attribute, ret0: __attribute__ ((unused)), says nothing of the code: c2ff leaves it)
        if ($k eq 'LabelStmt') { push @out, '(label ' . ($labels{ $n->{declId} } // $n->{name}) . ')', S(grep { $_->{kind} !~ /Attr$/ } kids($n)); next }
        if ($k eq 'AttributedStmt') { push @out, S(grep { $_->{kind} !~ /Attr$/ } kids($n)); next }
        next if $k eq 'NullStmt';
        if ($k eq 'ReturnStmt') { push @out, '(return' . ($n->{inner} ? ' ' . E((kids($n))[0]) : '') . ')'; next }
        if ($k eq 'BreakStmt') { push @out, '(break)'; next }
        if ($k eq 'ContinueStmt') { push @out, '(continue)'; next }
        if ($k eq 'GotoStmt') { push @out, '(goto ' . ($labels{ $n->{targetLabelDeclId} } // '?') . ')'; next }
        if ($k eq 'IndirectGotoStmt') { push @out, '(goto* ' . E((kids($n))[0]) . ')'; next }
        if ($k eq 'GCCAsmStmt') {
            # (x86_64's math_opt_barrier, asm ("" : "=t" (y) : "0" (x)) of a long
            # double, "=x" of a double or a float: as csema, y = x)
            if ($side eq 'glibc' && $target eq 'x86_64') {
                my ($t, $oc, $ic) = asm_text($n);
                if (defined $t && $t !~ /\S/ && @$oc == 1 && $oc->[0] =~ /^=&?[tx]$/ && @$ic == 1 && $ic->[0] eq '0') {
                    my ($y, $x) = kids($n);
                    push @out, '(= ' . E($y) . ' ' . E($x) . ')';
                    next;
                }
            }
            if ($side eq 'glibc' && asm_barrier($n)) {
                # (what an input computes in floating point stays, its value
                # unused: c2ff's)
                push @out, map { '(cast ToVoid void ' . E($_) . ')' } grep { fp_computes($_) } kids($n) if $target eq 'x86_64' && !(asm_text($n))[1]->@*;
                next;
            }
            push @out, '(asm)';
            next;
        }
        # (an empty asm of inputs alone, math_force_eval's: csema's call of
        # its asm function, _asm___x (v) or of x87 inputs _asm___f_l
        # (&__x87_1), is glibc's barrier: what an input computes in floating
        # point, its value unused)
        if ($side eq 'ff' && $target eq 'x86_64' && (my $c = unimplicit($n)) && (unimplicit($n)->{kind} // '') eq 'CallExpr') {
            my ($f, @a) = kids($c);
            my $fd = (strip($f) // {})->{referencedDecl};
            if ($fd && (name_of($fd) // '') =~ /^_asm___/) {
                @a = map { x87in($_) } @a;
                push @out, map { '(cast ToVoid void ' . E($_) . ')' } grep { fp_computes($_) } @a;
                next;
            }
        }
        # an expression whose value is not used
        push @out, xstmt($n);
    }
    @out;
}
# An expression as a statement: a statement expression is its block (ff's :
# as a statement), a comma's operands statements of a block, one statement
# in braces that statement.
# An asm function's argument: the value of csema's x87 local whose address it is
sub x87in {
    my ($a) = @_;
    my $u = unimplicit($a);
    return $u unless ($u->{kind} // '') eq 'UnaryOperator' && $u->{opcode} eq '&';
    my $r = strip((kids($u))[0]) // {};
    my $nm = ($r->{kind} // '') eq 'DeclRefExpr' ? $r->{referencedDecl}{name} // '' : '';
    exists $x87in{$nm} ? $x87in{$nm} : $u;
}
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

# (each label by its place among them: ff's local label x 1 is C's __label__ x)
sub labels_of {
    my ($n) = @_;
    my $i = 0;
    my @l;
    my $w;
    $w = sub { my ($m) = @_; push @l, $m->{declId}, ($m->{name} =~ s/_\d+$//r) . '#' . ++$i if ($m->{kind} // '') eq 'LabelStmt'; $w->($_) for kids($m) };
    $w->($n);
    undef $w;
    @l;
}
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
# A function's statics after the first of a name (as c2ff names them): by id, name#k
sub static_ids {
    my ($fn) = @_;
    my (%k, %r, $w);
    $w = sub {
        my ($n) = @_;
        if (($n->{kind} // '') eq 'VarDecl' && ($n->{storageClass} // '') eq 'static' && defined $n->{name} && !holds($n, 'AddrLabelExpr')) {
            my $c = ++$k{ $n->{name} };
            $r{ $n->{id} } = "$n->{name}#$c" if $c > 1;
        }
        $w->($_) for kids($n);
    };
    $w->($fn);
    undef $w;
    %r;
}
sub const_ids {
    my ($n) = @_;
    my %r;
    if (($n->{kind} // '') eq 'VarDecl' && ($n->{storageClass} // '') eq 'static' && ($n->{type}{qualType} // '') =~ /\bconst\b/) {
        my ($i) = grep { $_->{kind} !~ /Attr$/ } kids($n);
        $i = (kids($i))[0] while $i && $i->{kind} =~ /^(ImplicitCastExpr|ParenExpr|ConstantExpr)$/;
        $r{ $n->{id} } = $i->{value} if $i && $i->{kind} eq 'IntegerLiteral';
    }
    (%r, map { const_ids($_) } kids($n));
}
sub local_typedefs { my ($n) = @_; (($n->{kind} // '') eq 'TypedefDecl' ? ($n->{name} => $n->{type}{qualType}) : ()), map { local_typedefs($_) } kids($n) }
sub fnorm {
    my ($fn) = @_;
    local %ltype = map { ($_->{name} => $_->{type}{qualType}) } grep { defined $_->{name} && $_->{type} } locals_decls($fn);
    local %labels = labels_of($fn);
    local %staticid = static_ids($fn) if $side eq 'glibc';
    # (a typedef in a function: __nss_hostname_digits_dots_context's host_addr_t)
    local %tdef = (%tdef, local_typedefs($fn));
    local %local = locals_of($fn);
    my @p = map { tcls($_) } grep { $_->{kind} eq 'ParmVarDecl' } kids($fn);
    my ($cs) = grep { $_->{kind} eq 'CompoundStmt' } kids($fn);
    my $f = join ' ', '(fn', retcls($fn), '(' . join(' ', @p) . ($fn->{variadic} ? ' ...' : '') . ')', S(kids($cs)), ')';
    # (a constant as a condition, ff's 1 != 0)
    $f =~ s/\(!= \(int (-?\d+) i32\) \(int 0 i32\)\)/(tobool (int $1 i32))/g;
    $f;
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
sub back_norms {
    my ($ast) = @_;
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
    push @{ $gwant{ $o =~ s/#\d+$//r } }, $g;
}
my %seen;
my %gextern;
my %gasm;
# A unit's cache (--unit-cache OUT unit.json, a make rule's): what of its AST
# a normal form reads (its functions with a body, its globals, its asm, and
# the tables made of the whole: typedefs, typeof types, the declarations'
# types, enum values, gcc's error functions), and the normal form of each of
# its functions, globals and functions' statics with what it asked of
# names.txt (%asked) when names.txt said nothing (all no). A round trip
# (--cached) reads it in place of the unit's JSON, a fraction of it, and
# takes a normal form where names.txt now answers as it did, else makes it
# again from the AST kept: the same normal forms, from a name's answers
# alone (the functions of a unit in the 10 milestones: 1 in 7 of the
# milestones' normal forms). Its stamp is roundtrip.pl's, FFold.pm's and the
# target: a cache of other code is none.
my $cache_stamp = do {
    my $d = Digest::MD5->new;
    for my $f ("$FindBin::Bin/$FindBin::Script", "$FindBin::Bin/../compiler/gen/FFold.pm") { open my $h, '<:raw', $f or die "roundtrip: $f: $!\n"; $d->addfile($h) }
    $d->add("target $target");
    $d->hexdigest;
};
sub unit_tables {
    my ($ast) = @_;
    { enumval => { enumvals($ast) }, tdef => { typedefs($ast) }, typeof => { typeofs($ast) },
      declty => { map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} =~ /^(FunctionDecl|VarDecl)$/ && defined $_->{name} && $_->{type} } kids($ast) },
      errordecl => { errordecls($ast) } };
}
sub has_body { my ($d) = @_; $d->{kind} eq 'FunctionDecl' && grep { $_->{kind} eq 'CompoundStmt' } kids($d) }
# the normal form of key (f id, g id, s id) from the cache, where names.txt
# answers as it did; else none, and the unit is read from its JSON as before
# ($umiss): a normal form made of a pristine AST, as the cache's are, may not
# be one made of what other normal forms made before touched (autovivified)
our ($ucache, $umiss);
sub cnorm {
    my ($key, $make) = @_;
    return $make->() unless $ucache;
    my $e = $ucache->{norm}{$key};
    if ($e && !grep { ($_ =~ /^a (.*)$/ ? ($asmfn{$1} ? 1 : 0) : ($noproto{ substr($_, 2) } ? 1 : 0)) != $e->{asked}{$_} } keys %{ $e->{asked} }) {
        die $e->{err} if defined $e->{err};
        return $e->{norm};
    }
    $umiss = 1;
    '';
}
sub unit_cache {
    my ($ast, $j) = @_;
    my $t = unit_tables($ast);
    my @keep = grep { has_body($_) || $_->{kind} =~ /^(VarDecl|FileScopeAsmDecl)$/ } kids($ast);
    my $pristine = dclone(\@keep);
    my %norm;
    # (each of a copy of its node, as it is in the JSON: a normal form touches the AST)
    my $one = sub { my ($k, $d, $f) = @_; local %asked; my $n = eval { $f->(dclone($d)) }; $norm{$k} = defined $n ? { norm => $n, asked => {%asked} } : { err => $@, asked => {%asked} } };
    unit_norms({ kind => 'TranslationUnitDecl', inner => \@keep }, $j, { tables => $t }, $one);
    { stamp => $cache_stamp, j => $j, keep => $pristine, tables => $t, norm => \%norm };
}
# one unit's normal forms: its functions wanted (by their C name here), its
# globals wanted, what it only declares; from a unit's cache, its tables and
# normal forms ($c); for a unit's cache, every one ($all, which makes each)
sub unit_norms {
    my ($ast, $j, $c, $all) = @_;
    my %want;
    my (%gf, %ge, %gs);
    my $t = $c ? $c->{tables} : undef;
    local $ucache = $all ? undef : $c;
    local %enumval = $t ? %{ $t->{enumval} } : enumvals($ast);
    local $side = 'glibc';
    local $unit_i = $j =~ s/\.json$/.i/r;
    local %regvar;
    local %asmalias = map { ((kids($_))[0]{value} // '') =~ /^"\s*([.\w]+)\s*=\s*([.\w]+)\s*"$/ ? ($1 => $2) : () } grep { $_->{kind} eq 'FileScopeAsmDecl' } kids($ast);
    local %tdef = $t ? %{ $t->{tdef} } : typedefs($ast);
    local %typeof = $t ? %{ $t->{typeof} } : typeofs($ast);
    local %declty = $t ? %{ $t->{declty} } : map { ($_->{name} => $_->{type}{qualType}) } grep { $_->{kind} =~ /^(FunctionDecl|VarDecl)$/ && defined $_->{name} && $_->{type} } kids($ast);
    local %errordecl = $t ? %{ $t->{errordecl} } : errordecls($ast);
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
    # (a top-level asm's .globl N and .set N, V, .equ N, V or N = V, V a number: an
    # absolute symbol the unit defines, which csema writes as a char global of value V,
    # cl_asm_absdefs: glibc's _nl_current_LC_*_used; its definition here is that)
    for my $a (grep { $_->{kind} eq 'FileScopeAsmDecl' } kids($ast)) {
        my $s = (kids($a))[0]{value} // '';
        $s =~ s/^"|"$//g;
        $s =~ s/\\[nt]/\n/g;
        my (%gl, %v);
        for my $l (split /[\n;]/, $s) {
            $l =~ s/^\s+|\s+$//g;
            if ($l =~ /^\.globl\s+([.\w]+)$/) { $gl{$1} = 1 }
            elsif ($l =~ /^\.(?:set|equ)\s+([.\w]+)\s*,\s*(-?\d+)$/ || $l =~ /^([.\w]+)\s*=\s*(-?\d+)$/) { $v{$1} = $2 }
        }
        for my $n (grep { $gl{$_} && $gwant{$_} } keys %v) {
            my $ty = { qualType => 'char' };
            $gs{$n} = gnorm({ kind => 'VarDecl', name => $n, type => $ty, inner => [{ kind => 'ImplicitCastExpr', castKind => 'IntegralCast', type => $ty,
                inner => [{ kind => 'IntegerLiteral', value => $v{$n}, type => { qualType => 'int' } }] }] });
        }
    }
    if ($all) {
        # (the cache: each function's, global's and function's static's normal form)
        for my $d (kids($ast)) {
            if (has_body($d)) {
                $all->("f $d->{id}", $d, sub { fnorm($_[0]) });
                local %staticid = static_ids($d);
                local %constid = const_ids($d);
                my @q = kids($d);
                while (my $n = shift @q) {
                    $all->("s $n->{id}", $n, sub { gnorm($_[0]) }) if ($n->{kind} // '') eq 'VarDecl' && ($n->{storageClass} // '') eq 'static';
                    push @q, kids($n);
                }
            }
            $all->("g $d->{id}", $d, sub { gnorm($_[0]) }) if $d->{kind} eq 'VarDecl' && defined $d->{name} && ($d->{storageClass} // '') ne 'extern';
        }
        return;
    }
    # its globals: a definition (an extern declaration is none), the first unit's
    for my $d (kids($ast)) {
        next unless $d->{kind} eq 'VarDecl' && defined $d->{name} && $gwant{ $d->{name} };
        # (one glibc's asm only reserves, zero, c2ff --zero: its declaration)
        if (($d->{storageClass} // '') eq 'extern') { $ge{ $d->{name} } //= '(global ' . tcls($d) . ' (zero))'; next }
        for my $g (@{ $gwant{ $d->{name} } }) {
            next if $g->[2] =~ /^in / || $gfound{ $g->[0] } || $gf{ $g->[0] };
            next if $g->[2] =~ /^unit (.+)$/ && $j !~ /\/\Q$1\E\.json$/;
            $gf{ $g->[0] } = cnorm("g $d->{id}", sub { gnorm($d) });
        }
    }
    # and its functions' statics
    for my $d (kids($ast)) {
        next unless $d->{kind} eq 'FunctionDecl' && defined $d->{name} && ($fnunit{ $d->{name} } // '') eq $j && grep { $_->{kind} eq 'CompoundStmt' } kids($d);
        local %staticid = static_ids($d);
        local %constid = const_ids($d);
        my @q = kids($d);
        while (my $n = shift @q) {
            if (($n->{kind} // '') eq 'VarDecl' && ($n->{storageClass} // '') eq 'static' && $gwant{ $n->{name} // '' }) {
                # (name#k, a later one of its name in the function)
                my $o = name_of($n);
                for my $g (@{ $gwant{ $n->{name} } }) { $gf{ $g->[0] } //= cnorm("s $n->{id}", sub { gnorm($n) }) if $g->[2] eq "in $d->{name}" && $g->[1] eq $o && !$gfound{ $g->[0] } }
            }
            push @q, kids($n);
        }
    }
    for my $b (@{ $byunit{$j} // [] }) {
        my ($cid, $o) = @$b;
        my $d = $def{$o} or next;
        $want{$cid} = cnorm("f $d->{id}", sub { fnorm($d) });
    }
    { j => $j, want => \%want, gf => \%gf, ge => \%ge, gs => \%gs };
}
# and held against the C written back
sub unit_compare {
    my ($u) = @_;
    my $j = $u->{j};
    $gfound{$_} //= $u->{gf}{$_} for keys %{ $u->{gf} };
    $gextern{$_} //= $u->{ge}{$_} for keys %{ $u->{ge} };
    $gasm{$_} //= $u->{gs}{$_} for keys %{ $u->{gs} // {} };
    for my $b (@{ $byunit{$j} // [] }) {
        my ($cid, $o) = @$b;
        my $want = $u->{want}{$cid} // do { push @diff, [$cid, "no function $o in $j"]; next };
        print $normsout "f $cid\t$want\n" if $normsout;
        my $got = $back{$cid} // do { push @diff, [$cid, 'not in the C written back']; next };
        if ($want eq $got) { $same++; next }
        push @diff, [$cid, where($want, $got)];
    }
}
if (defined $norm_back) {
    back_norms(load($backjson));
    nstore({ back => \%back, backg => \%backg }, $norm_back);
    exit 0;
}
if (defined $unit_cache) {
    my $c = unit_cache(load($backjson), $backjson);
    # (JSON, as clang's: roundtrip in ff reads it too)
    open my $o, '>:raw', "$unit_cache.$$.tmp" or die "roundtrip: $unit_cache: $!\n";
    print $o $json->encode($c);
    close $o or die "roundtrip: $unit_cache: $!\n";
    rename "$unit_cache.$$.tmp", $unit_cache or die "roundtrip: $unit_cache: $!\n";
    exit 0;
}
# a unit's AST, and its cache where it has one made of this code and after its JSON
sub cache_of { my ($j) = @_; defined $cachedir ? "$cachedir$j" =~ s/\.json$/.rtn/r : $j =~ s/\.json$/.rtn/r }
sub load_unit {
    my ($j) = @_;
    if ($cached) {
        my $f = cache_of($j);
        if (-e $f && (!-e $j || -M $f <= -M $j)) {
            my $c = load($f);
            return ({ kind => 'TranslationUnitDecl', inner => $c->{keep} }, $c) if $c->{stamp} eq $cache_stamp;
        }
    }
    (load($j), undef);
}
if (defined $norm_unit) {
    my ($j, $file) = ($backjson, $unitjson[0] // $backjson);
    nstore(unit_norms(load($file), $j), $norm_unit);
    exit 0;
}
if ($join) {
    my @l = ($backjson, @unitjson);
    my ($b) = grep { $l[$_] eq '--' } 0 .. $#l;
    die "roundtrip: --join names back.norm ... -- unit.norm ...\n" unless defined $b;
    for my $f (@l[0 .. $b - 1]) { my $r = retrieve($f); %back = (%back, %{ $r->{back} }); %backg = (%backg, %{ $r->{backg} }) }
    for (@l[$b + 1 .. $#l]) { my $u = retrieve($_); $seen{ $u->{j} } = 1; unit_compare($u) }
    # (a function of a unit that is not there)
    for my $j (grep { !$seen{$_} } sort keys %byunit) { push @diff, [$_->[0], "its unit $j was not read"] for @{ $byunit{$j} } }
}
else {
    back_norms(load($backjson));
    for my $j (grep { !$seen{$_}++ } @unitjson, sort keys %byunit) {
        my ($ua, $uc) = load_unit($j);
        local $umiss;
        my $u = unit_norms($ua, $j, $uc);
        $u = unit_norms(load($j), $j) if $umiss;
        unit_compare($u);
    }
}
# where two normal forms part
sub where {
    my ($a, $b) = @_;
    my $i = 0;
    $i++ while $i < length($a) && $i < length($b) && substr($a, $i, 1) eq substr($b, $i, 1);
    my $from = $i > 80 ? $i - 80 : 0;
    # (the digest of both whole: rtknown.pl's, a new difference in a listed function is new)
    "\n    glibc: ..." . substr($a, $from, 200) . "\n    ff:    ..." . substr($b, $from, 200) . "\n    digest: " . substr(md5_hex(do { my $s = "$a\0$b"; utf8::encode($s) if utf8::is_utf8($s); $s }), 0, 12);
}
my ($gsame, @gdiff) = (0);
for my $g (@globals) {
    my ($cid, $o, $hint, $k) = @$g;
    if ($k eq 'gfailed') { push @gdiff, [$cid, 'ff2c could not write it back']; next }
    my $want = $gfound{$cid} // $gasm{$o} // $gextern{$o} // do { push @gdiff, [$cid, "no definition of $o in glibc's units ($hint)"]; next };
    print $normsout "g $cid\t$want\n" if $normsout;
    my $got = $backg{$cid} // do { push @gdiff, [$cid, 'not in the C written back']; next };
    print "glibc: $want\nff:    $got\n" if ($ENV{ROUNDTRIP_SHOW} // '') eq $cid;
    if ($want eq $got) { $gsame++; next }
    push @gdiff, [$cid, where($want, $got)];
}
print "roundtrip: $_->[0]: $_->[1]\n" for @diff, @gdiff;
print "roundtrip: $_->[1]: ff2c could not write it back\n" for @failed;
printf "roundtrip: %d of %d functions and %d of %d globals as glibc's C\n", $same, scalar(@bodies), $gsame, scalar(@globals);
exit(@diff || @failed || @gdiff ? 1 : 0);
