#!/usr/bin/env perl
# c2ff.pl — C as ff: the definitions a program reaches in preprocessed C
# files (clang's JSON AST of each), written in ttpc's C layer, one C construct
# per ff construct (see language.ff.txt). Nothing is lowered: a construct the
# C layer has no form for stops the translation, named, with where it is.
#
#   perl c2ff.pl [--page name] [--target t] tu.json=tu.i ... -- root ... > out.ff.txt
#   perl c2ff.pl --program tree [--target t] tu.json=tu.i -- main > prog.ff.txt
#   perl c2ff.pl --types        (the type words, for a look)
#
# Each translation unit is its AST (from $C2FF_CLANG -x c -include
# src/glibc/clang-prelude.h -Xclang -ast-dump=json -fsyntax-only
# --target=riscv64-linux-gnu -std=gnu11 -w tu.i; --target t for another
# target, aarch64 or x86_64, and c2ff's --target t too: its registers are
# then the names ff reserves, its asm is read) and the .i it was made of
# (for what the AST leaves out: the resolver of an ifunc). The roots are the
# names to start from; what they call, the globals and types they use, comes
# too, from whichever unit defines it.
#
# Two idioms of glibc are recognized as what they are: its system call (a
# statement expression of register variables and scall) is ff's syscall, and
# __builtin_expect (a hint to the compiler) is its first argument (a long); __extension__
# (which only quiets -pedantic) is what it marks; __builtin_constant_p is 1
# for a literal, else 0, as gcc may answer where it cannot tell.
# __builtin_memcpy and the like are calls of memcpy and the like, as gcc makes
# them where it does not expand them.
#
# With --program, what the roots reach is a program: its definitions on the
# page itself, after import / tree (glibc in ff, which has the rest), and a
# _start that exits with what main returns, which is what C's startup does
# for main without arguments.
# With --early it runs glibc's __libc_early_init (1) first, as glibc's static
# startup does (ctype, malloc's arena, ...).
# With --exit it ends with glibc's exit (main ()), as C's startup does, which
# runs the atexit functions and flushes stdio (_IO_cleanup); else SYS_exit.
#
# --zero name: an object glibc's asm only reserves, zeroed in .bss (elf/dl-debug-
# symbols.S's _r_debug_extended), is a global of the type C declares, zero.
# --weak name: a name nothing defines for a static program (the linker's
# __init_array_start, which a ttpc program has no array for; a function gcc's
# optimizer left no call of) is weak, address 0, as an undefined weak is.
#
# The ASTs (1.9 GB of JSON for M4) are read with JSON::XS, which flake.nix
# gives perl, 80 times faster than core Perl's JSON::PP, which it falls
# back on; each once, by a pass of its own that c2ff keeps next to it
# (tu.c2ff, see unit_pass), several at once (C2FF_JOBS, 3). The reach then
# reads those: M4's floats in 13 s and 300 MB, against 62 s and 950 MB
# with every AST in memory.
#
# A host tool, not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
my $json_parser = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };
use FF qw(node write_txt read_ff);
use Digest::SHA;
use POSIX ();

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
    'float' => 'float', 'double' => 'double', 'long double' => 'long double',
    'long long' => 'i64', 'signed long long' => 'i64', 'unsigned long long' => 'u64',
    '_Bool' => 'u8', 'void' => 'void',
    '__builtin_va_list' => 'va_list',
);

# The words a type run can be made of, besides the names of types.
my %scalar_word = map { $_ => 1 } (values %scalar, 'address', 'array');
my (%fntype, @fntypes);     # function types for pointers to functions
my %tagname;                # struct, union, enum tags and their ff names
my %typedef;                # typedef names and the types they stand for
my %desugar;                # a typeof (expression) as clang writes it, and the type it is
my %enumval;                # an enum constant's value, by name
my %typeof;                 # declared names and their types, for typeof
my %wanttag;                # the tags whose definitions the output needs
my (%fn, %var, %rec, %enumd, %alias, %ifunc);   # the units' definitions, by name
my %localname;              # the names of locals and parameters, which a tag must not take
my %regvar;                 # global register variables (register void *__thread_self asm ("tp")): their registers
my %anon;                   # anonymous types of fields, by clang's spelling: [tag, ff name]
our $cur_unit;              # the unit whose definition is being translated

sub trim { my ($s) = @_; $s =~ s/^\s+|\s+$//g; $s }

# A C type string to a list of ff words. A pointer to a function names a
# function type of its own (fn1:, fn2:, ...), made once per spelling.
our $ctype_depth = 0;
sub ctype {
    my ($t) = @_;
    local $ctype_depth = $ctype_depth + 1;
    die "c2ff: a type that does not end: $t\n" if $ctype_depth > 100;
    $t = trim($t);
    # an attribute (noreturn, ...) says nothing of the type's layout
    $t =~ s/\s*__attribute__\s*(\(\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)\))?//g;
    $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
    $t = trim($t);
    $t =~ s/\s+/ /g;
    # an array of function pointers, ret (*[n]) (params): the init arrays'
    # void (*[]) (int, char **, char **)
    if ($t =~ /^(.*?)\s*\(\*\s*\[(\d*)\]\)\s*\((.*)\)$/) {
        return ('array', 'address', fntype($1, $3), $2 eq '' ? 0 : $2);
    }
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
    return ctype($desugar{$t}) if exists $desugar{$t};
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
        return $tagname{"$1 $2"} //= $var{$2} || $fn{$2} || $localname{$2} ? "$2 $1" : ffname($2);
    }
    # glibc's array check (array_length): sizeof (struct { _Static_assert
    # (...); }), a struct clang writes no declaration of; it has no fields
    if ($t =~ /^struct \(unnamed at / && $cur_unit && $cur_unit->{text} =~ /sizeof \(struct \{ _Static_assert/ && (my $k = anon_key($t))) {
        (my $name = "struct at $k") =~ s/:\d+$//;
        $anon{$k} = ["struct $name", $name];
        $rec{"struct $name"} //= { kind => 'RecordDecl', tagUsed => 'struct', inner => [] };
        $wanttag{"struct $name"} = 1;
        return $tagname{"struct $name"} //= $name;
    }
    # an anonymous enum that names no global (dl-close's static enum { ... }
    # dl_close_state, in a function): what ttpc makes of every enum, an int
    return 'int' if $t =~ /^enum \(unnamed at /;
    die "c2ff: no ff type for C's '$t'\n";
}

# A type with its typedef names and typeof (name) at the top replaced by what
# they stand for.
sub expand {
    my ($t) = @_;
    for (1 .. 50) {
        $t = trim($t);
        $t =~ s/\s*__attribute__\s*(\(\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)\))?//g;
        $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
        $t = trim($t);
        if (exists $typedef{$t}) { $t = $typedef{$t}; next }
        if ($t =~ /^(?:typeof|__typeof__) \(\s*(\S+?)\s*\)$/ && exists $typeof{$1}) { $t = $typeof{$1}; next }
        if (exists $desugar{$t}) { $t = $desugar{$t}; next }
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
    # clang's spelling of an anonymous type, struct (unnamed struct at f.c:9:3),
    # and a typeof (expression) are no function types
    return undef if $t =~ /^(?:struct|union|enum) \((?:unnamed|anonymous)\b/;
    if ($t =~ /^(?:typeof|__typeof__) \(/) {
        # (one whose ( closes at the end)
        my ($d, $i) = (0, index($t, '('));
        for (; $i < length $t; $i++) { my $c = substr($t, $i, 1); $d++ if $c eq '('; $d-- if $c eq ')'; last if !$d }
        return undef if $i == length($t) - 1;
    }
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
    alias ifunc asm items cast weak va_arg_pack va_arg_pack_len zero ra sp gp tp fp pc
), map({ ("x$_", "a$_", "s$_", "t$_", "f$_", "fa$_", "fs$_", "ft$_") } 0 .. 31);
# --target T: the target the .i were made for, riscv64 if not given. On
# another the registers reserved are its own: the names of the registers
# group of its section in shared.ff.
my $target = 'riscv64';
sub reserve_target {
    my ($t) = @_;
    open my $h, '<:raw', "$FindBin::Bin/../shared.ff" or die "c2ff: cannot open shared.ff: $!\n";
    my ($shared) = @{ read_ff(do { local $/; <$h> })->{children} };
    my ($sec) = grep { $_->{content} eq "$t:" } @{ $shared->{children} } or die "c2ff: $t is not a target\n";
    my ($regs) = grep { $_->{content} eq 'registers:' } @{ $sec->{children} } or die "c2ff: $t has no registers\n";
    delete $reserved{$_} for grep { /^(?:x|a|s|t|f|fa|fs|ft)\d+$|^(?:zero|ra|sp|gp|tp|fp|pc)$/ } keys %reserved;
    for (@{ $regs->{children} }) { (my $c = $_->{content}) =~ s/:$//; $reserved{$_} = 1 for split ' ', $c }
}
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

# A unit's AST, from its JSON.
sub ast_of {
    my ($json) = @_;
    open my $h, '<', $json or die "c2ff: cannot open $json: $!\n";
    my $ast = $json_parser->decode(do { local $/; <$h> });
    close $h;
    $ast;
}

my $page = 'glibc';
my $program;
my $early;                 # --early: _start runs glibc's __libc_early_init (1) before main
my $exit;                  # --exit: _start ends with glibc's exit (main ()), not SYS_exit
my %zero;                  # --zero name: glibc's asm only reserves it (zeroed, in .bss)
my %forceweak;             # --weak name: nothing defines it for a static program
my (@units, @roots);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--program') { $program = shift @ARGV; next }
    if ($a eq '--early') { $early = 1; next }
    if ($a eq '--exit') { $exit = 1; next }
    if ($a eq '--zero') { $zero{ shift @ARGV } = 1; next }
    if ($a eq '--weak') { $forceweak{ shift @ARGV } = 1; next }
    if ($a eq '--target') { $target = shift @ARGV; next }
    if ($a eq '--') { @roots = @ARGV; last }
    my ($json, $i) = split /=/, $a, 2;
    push @units, { json => $json, i => $i };
}
die "usage: c2ff.pl [--page name | --program tree] [--target t] tu.json=tu.i ... -- root ...\n" unless @units && @roots;
reserve_target($target) if $target ne 'riscv64';

my %enumof;                 # each enum constant's enum, as a tag
my $lastanon;               # the last anonymous record or enum at the top of a unit
my %weak;                   # names declared weak (#pragma weak), their declarations
my %recid;                  # complete records by id, the anonymous ones too
my %enumid;                 # enums by id
# an enum's constants bring it in where they are used; one with no name is
# named after its first constant. A function's own enums too (qsort's enum {
# SWAP_GENERIC_SIZE = 32 }), as globals.
# The value C gives an enum constant, worked out by clang (a ConstantExpr, under
# the conversion to int where it needs one: vfprintf's WORK_BUFFER_SIZE =
# 1000 / sizeof (CHAR_T)), else undef.
sub enum_value {
    my ($c) = @_;
    my ($e) = grep { $_->{kind} !~ /Attr$/ } kids($c);
    $e = (kids($e))[0] while $e && $e->{kind} =~ /^(ImplicitCastExpr|ParenExpr)$/;
    $e && $e->{kind} eq 'ConstantExpr' ? $e->{value} : undef;
}
sub index_enum {
    my ($d) = @_;
    $enumid{$d->{id}} = $d;
    my @c = grep { $_->{kind} eq 'EnumConstantDecl' } @{ $d->{inner} || [] };
    my $tag = defined $d->{name} ? "enum $d->{name}" : @c ? "enum $c[0]{name} enum" : undef;
    return unless defined $tag;
    $enumd{$tag} //= $d;
    $tagname{$tag} //= defined $d->{name} ? ffname($d->{name}) : "$c[0]{name} enum";
    $enumof{ $_->{name} } //= $tag for @c;
    # the constants' values: clang's ConstantExpr where C gives one, else the
    # one before and 1
    my $v = -1;
    for my $c (@c) {
        my $e = enum_value($c);
        $v = defined $e ? $e : $v + 1;
        $enumval{ $c->{name} } //= $v;
    }
}
# A static that another unit defines differently (csu/libc-start's and
# elf/dl-init's call_init) is that unit's own, named for it: call_init
# elf/dl-init; the unit's references take that name. The same text twice
# (a header's static inline) is one function.
my %own;
sub def_text {
    my ($d, $u) = @_;
    my ($b, $e) = map { $_->{offset} // ($_->{expansionLoc} // {})->{offset} } $d->{range}{begin}, $d->{range}{end};
    defined $b && defined $e ? substr($u->{text}, $b, $e - $b) : '';
}
sub own_name {
    my ($map, $name, $d, $u) = @_;
    my $old = $map->{$name} or return $name;
    return $name if $old->[1] == $u || ($d->{storageClass} // '') ne 'static' || ($old->[0]{storageClass} // '') ne 'static';
    return $name if def_text($d, $u) eq def_text($old->[0], $old->[1]);
    $own{$u}{$name} = "$name " . unit_name($u);
}
sub own { my ($name) = @_; $cur_unit && $own{$cur_unit} && $own{$cur_unit}{$name} // $name }
sub inner_tags { my ($n) = @_; (($n->{kind} // '') =~ /^(EnumDecl|RecordDecl)$/ ? $n : ()), map { inner_tags($_) } @{ $n->{inner} || [] } }
units_ready(@units);
for my $u (@units) {
    # clang's ids are addresses, unique in one unit only: a typedef's
    # anonymous tag is found among its own unit's (an id of another unit's
    # enum made pthread_rwlockattr_t's union an enum)
    %recid = ();
    %enumid = ();
    my $ast = unit_of($u);
    open my $h, '<', $u->{i} or die "c2ff: cannot open $u->{i}: $!\n";
    $u->{text} = do { local $/; <$h> };
    close $h;
    places($ast->{ff_places});
    my $file = '';
    for my $d (@{ $ast->{inner} }) {
        $file = $d->{loc}{file} if $d->{loc} && $d->{loc}{file};
        $file = $d->{loc}{expansionLoc}{file} if $d->{loc} && $d->{loc}{expansionLoc} && $d->{loc}{expansionLoc}{file};
        $d->{file} = $file;
        next if $d->{isImplicit};
        $recid{$d->{id}} = $d if $d->{kind} eq 'RecordDecl' && $d->{completeDefinition};
        $enumid{$d->{id}} = $d if $d->{kind} eq 'EnumDecl';
        index_enum($d) if $d->{kind} eq 'EnumDecl';
        # an anonymous struct, union or enum that is a global's type is named
        # after it (_nl_C_LC_CTYPE_class_upper struct)
        if ($d->{kind} =~ /^(RecordDecl|EnumDecl)$/ && ($d->{name} // '') eq '') { $lastanon = $d; next }
        if ($d->{kind} eq 'VarDecl' && $lastanon && defined $d->{name} && (my $key = anon_key($d->{type}{qualType} // ''))) {
            my $kind = $lastanon->{kind} eq 'EnumDecl' ? 'enum' : $lastanon->{tagUsed};
            my $tn = "$d->{name} $kind";
            $anon{$key} //= ["$kind $tn", $tn];
            # (an enum's constants are then its: one name for one enum, not also
            # the one index_enum gave it after its first constant)
            if ($kind eq 'enum') {
                $enumd{"enum $tn"} //= $lastanon;
                $tagname{ $anon{$key}[0] } //= $anon{$key}[1];
                $enumof{ $_->{name} } = $anon{$key}[0] for grep { $_->{kind} eq 'EnumConstantDecl' } @{ $lastanon->{inner} || [] };
            } else { $rec{"$kind $tn"} //= $lastanon; anon_fields($lastanon, $tn) }
        }
        my $name = $d->{name} // next;
        # weak, or a function gcc's error attribute keeps from being called
        if (($d->{storageClass} // '') eq 'register' && (my ($l) = grep { $_->{kind} eq 'AsmLabelAttr' } @{ $d->{inner} || [] })) {
            # (clang has the register as the name it is known by in asm)
            $regvar{$name} = $d->{mangledName} // $l->{label} // stop('a register variable without its register', $d);
            next;
        }
        $weak{$name} //= $d if $d->{kind} =~ /^(VarDecl|FunctionDecl)$/ && ($forceweak{$name} || grep { $_->{kind} =~ /^(WeakAttr|ErrorAttr)$/ } @{ $d->{inner} || [] });
        if ($d->{kind} eq 'TypedefDecl') {
            my $own = $d->{inner} && $d->{inner}[0]{ownedTagDecl};
            if ($own && ($own->{name} // '') eq '' && (my $e = $enumid{ $own->{id} })) {
                # a typedef of an anonymous enum: the enum takes its name
                $enumd{"enum $name"} //= $e;
                $tagname{"enum $name"} //= ffname($name);
                $typedef{$name} //= "enum $name";
                $enumof{ $_->{name} } = "enum $name" for grep { $_->{kind} eq 'EnumConstantDecl' } @{ $e->{inner} || [] };
            } elsif ($own && ($own->{name} // '') eq '' && $recid{ $own->{id} }) {
                # a typedef of an anonymous struct or union: the record is its tag
                $rec{ $d->{type}{qualType} } //= $recid{ $own->{id} };
                anon_fields($recid{ $own->{id} }, $name);
                # (a typedef that other units leave void, opaque behind an address,
                # takes the struct: _IO_lock_t outside and inside libio's lock)
                $typedef{$name} = $d->{type}{qualType} if ($typedef{$name} // 'void') eq 'void';
            } else {
                $typedef{$name} = qt($d) if ($typedef{$name} // 'void') eq 'void';
            }
        }
        $typeof{$name} //= qt($d) if $d->{kind} =~ /^(FunctionDecl|VarDecl)$/ && $d->{type};
        my @in = @{ $d->{inner} || [] };
        if ($d->{kind} eq 'FunctionDecl') {
            if (my ($a) = grep { $_->{kind} eq 'AliasAttr' } @in) { $alias{$name} = [$a->{aliasee}, $u]; next }
            if (my ($r) = grep { $_->{kind} eq 'IFuncAttr' } @in) { $ifunc{$name} = [$d, $u, resolver($u, $r)]; next }
            if (grep { $_->{kind} eq 'CompoundStmt' } @in) { my $k = own_name(\%fn, $name, $d, $u); $fn{$k} //= [$d, $u] }
            # (and under address a local named as a tag would be the type: struct
            # msort_param msort_param in qsort)
            # (both found by the unit's own pass, unit_pass)
            $localname{$_} = 1 for @{ $d->{ff_locals} };
            # its own enums and records (getrandom's struct vgetrandom_opaque_params), as globals
            for my $t (@{ $d->{ff_tags} }) {
                if ($t->{kind} eq 'EnumDecl') { index_enum($t) }
                elsif ($t->{completeDefinition}) {
                    $recid{$t->{id}} = $t;
                    if (defined $t->{name} && $t->{name} ne '') { $rec{"$t->{tagUsed} $t->{name}"} //= $t; anon_fields($t, $t->{name}) }
                }
            }
        } elsif ($d->{kind} eq 'VarDecl') {
            if (my ($a) = grep { $_->{kind} eq 'AliasAttr' } @in) { $alias{$name} = [$a->{aliasee}, $u]; next }
            if (($d->{storageClass} // '') ne 'extern' || $zero{$name}) { my $k = own_name(\%var, $name, $d, $u); $var{$k} //= [$d, $u] }
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

# Any other anonymous struct or union (in a sizeof, a cast) is named after
# its place: struct at __libc_assert_fail.c:29. Clang's JSON leaves out a
# location's file and line where they are the previous one's, so the walk
# keeps them, in the order clang wrote them. The unit's own pass
# (unit_pass) makes the list of what it finds, in order: [key, kind, name,
# node] for such a record, [typeof, type] for a typeof; places takes them
# in, in the order of the units, as the walk once did.
sub anon_places {
    my ($ast) = @_;
    my (@found, %seen);
    my ($file, $line) = ('', 0);
    my ($actual, $delta) = (0, 0);   # the .i's line, and it less the presumed one
    my $walk;
    # one location as clang writes it: a macro's spelling, then its expansion
    my $at = sub {
        my ($l) = @_;
        for my $p ($l->{spellingLoc} // (), $l->{expansionLoc} // $l) {
            # the type's spelling has the place the # line markers give. clang
            # writes presumedLine where it differs from the .i's line and from
            # the last it wrote: without one the place follows the .i's line
            # where the two have been the same (no markers: a -P program), else
            # stays (dl-reloc's struct in a macro)
            $file = $p->{presumedFile} // $p->{file} if defined($p->{presumedFile} // $p->{file});
            if (defined $p->{presumedLine}) { $line = $p->{presumedLine}; $delta = ($p->{line} // $actual) - $line }
            elsif (defined $p->{line} && !$delta) { $line = $p->{line} }
            $actual = $p->{line} if defined $p->{line};
        }
    };
    $walk = sub {
        my ($n) = @_;
        my $l = $n->{loc} // {};
        $at->($l);
        $l = $l->{expansionLoc} // $l;
        if (($n->{kind} // '') eq 'RecordDecl' && ($n->{name} // '') eq '' && $n->{completeDefinition} && defined $l->{col}) {
            (my $base = $file) =~ s{.*/}{};
            my $key = "$base:$line:$l->{col}";
            push @found, [$key, $n->{tagUsed}, "$n->{tagUsed} at $base:$line", $n] unless $seen{"anon $key"}++;
        }
        # what a typeof (expression) is, where clang says it (libio's vtable
        # check has typeof (((struct _IO_FILE_plus){}).vtable) *, without it)
        if ((my $ty = $n->{type}) && $n->{type}{qualType}) {
            push @found, [$ty->{qualType}, $ty->{desugaredQualType}]
                if defined $ty->{desugaredQualType} && $ty->{qualType} =~ /^(?:typeof|__typeof__) \(/ && !$seen{"typeof $ty->{qualType}"}++;
        }
        # after a node's place, clang writes its range: a line it leaves out
        # later may be one of these
        $at->($_) for grep { $_ } $n->{range}{begin}, $n->{range}{end};
        $walk->($_) for @{ $n->{inner} || [] };
    };
    $walk->($ast);
    undef $walk;
    \@found;
}
# ---- each unit's own pass, cached --------------------------------------------
# What c2ff needs of a unit that no other unit changes is worked out once,
# one unit at a time, and kept next to its AST: tu.c2ff, the unit's AST as
# Storable has it, without the bodies of its functions (tu.c2ff.bodies,
# each read when the reach takes its function), with the anonymous records'
# places (anon_places) and each function's locals and own tags. The first
# line of tu.c2ff is its key: c2ff's own hash and the AST's (its size and
# time first: a JSON made again, the same, is not done again). The units
# without one are done in parallel, C2FF_JOBS at once (3), each its own
# process with one AST in memory, so the reach itself reads no JSON.
use Storable qw(nfreeze thaw);
my $self_hash;
sub unit_file { (my $f = $_[0]{json}) =~ s/\.json$//; "$f.c2ff" }
sub json_key {
    my ($u, $full) = @_;
    $self_hash //= Digest::SHA->new(256)->addfile("$FindBin::Bin/c2ff.pl")->hexdigest;
    my @st = stat $u->{json} or die "c2ff: cannot open $u->{json}: $!\n";
    ("c2ff unit 1 $self_hash", "$st[7] $st[9]", $full ? Digest::SHA->new(256)->addfile($u->{json})->hexdigest : ());
}
# The key of the unit's cache, if it is the AST's of now: else undef.
sub unit_fresh {
    my ($u) = @_;
    my $file = unit_file($u);
    open my $h, '<:raw', $file or return;
    my $line = <$h> // return;
    chomp $line;
    my ($self, $stamp, $hash) = split / \| /, $line;
    my ($s, $t) = json_key($u);
    return unless defined $hash && $self eq $s;
    return $h if $stamp eq $t;
    my (undef, undef, $now) = json_key($u, 1);
    return unless $now eq $hash;
    # (the same AST, made again: its new stamp)
    my $rest = do { local $/; <$h> };
    close $h;
    write_unit($file, "$s | $t | $hash\n", $rest);
    open $h, '<:raw', $file or die "c2ff: cannot open $file: $!\n";
    <$h>;
    $h;
}
sub write_unit {
    my ($file, @parts) = @_;
    open my $o, '>:raw', "$file.$$" or die "c2ff: cannot write $file.$$: $!\n";
    print $o @parts;
    close $o or die "c2ff: cannot write $file.$$: $!\n";
    rename "$file.$$", $file or die "c2ff: cannot rename $file.$$: $!\n";
}
sub unit_pass {
    my ($u) = @_;
    my $file = unit_file($u);
    my ($s, $t, $hash) = json_key($u, 1);
    my $ast = ast_of($u->{json});
    $ast->{ff_places} = anon_places($ast);
    my ($bodies, $at) = ('', 0);
    for my $d (@{ $ast->{inner} }) {
        # (what nothing reads after anon_places: the places inside a type,
        # but where a message says where it is)
        if (($d->{kind} // '') =~ /^(RecordDecl|EnumDecl|TypedefDecl)$/) { unplace($_) for @{ $d->{inner} || [] } }
        next unless ($d->{kind} // '') eq 'FunctionDecl';
        $d->{ff_locals} = [map { $_->{name} } grep { defined $_->{name} } locals($d)];
        $d->{ff_tags} = [inner_tags($d)];
        # (a declaration's parameters: its type has them)
        $d->{inner} = [grep { $_->{kind} ne 'ParmVarDecl' } @{ $d->{inner} }]
            if $d->{inner} && !grep { $_->{kind} eq 'CompoundStmt' } @{ $d->{inner} };
        for my $k (@{ $d->{inner} || [] }) {
            next unless $k->{kind} eq 'CompoundStmt';
            my $b = nfreeze($k);
            $bodies .= $b;
            $k = { kind => 'CompoundStmt', ff_body => [$at, length $b] };
            $at += length $b;
        }
    }
    write_unit("$file.bodies", $bodies);
    write_unit($file, "$s | $t | $hash\n", nfreeze($ast));
}
sub unplace { my ($n) = @_; delete @$n{qw(loc range)}; unplace($_) for @{ $n->{inner} || [] } }
sub units_ready {
    my @todo = grep { !unit_fresh($_) } @_;
    my $jobs = $ENV{C2FF_JOBS} || 3;
    my %pid;
    while (@todo || %pid) {
        while (@todo && keys %pid < $jobs) {
            my $u = shift @todo;
            my $pid = fork // die "c2ff: cannot fork: $!\n";
            if (!$pid) { eval { unit_pass($u); 1 } or do { print STDERR $@; POSIX::_exit(1) }; POSIX::_exit(0) }
            $pid{$pid} = $u;
        }
        my $pid = wait;
        last if $pid < 0;
        my $u = delete $pid{$pid} or next;
        die "c2ff: the pass of $u->{json} failed\n" if $?;
    }
}
# A unit's AST from its cache; a function's body when the reach takes it.
sub unit_of {
    my ($u) = @_;
    my $h = unit_fresh($u) or die "c2ff: no pass of $u->{json}\n";
    my $ast = thaw(do { local $/; <$h> });
    close $h;
    $ast;
}
# (a copy: the body goes when its function is done)
sub body_of {
    my ($d, $u) = @_;
    $d = { %$d, inner => [@{ $d->{inner} || [] }] };
    for my $k (@{ $d->{inner} }) {
        my $at = $k->{ff_body} or next;
        unless ($u->{bodies}) { open $u->{bodies}, '<:raw', unit_file($u) . '.bodies' or die "c2ff: cannot open the bodies of $u->{json}: $!\n" }
        sysseek $u->{bodies}, $at->[0], 0 or die "c2ff: cannot seek in the bodies of $u->{json}\n";
        sysread($u->{bodies}, my $b, $at->[1]) == $at->[1] or die "c2ff: cannot read the bodies of $u->{json}\n";
        $k = thaw($b);
    }
    $d;
}
sub places {
    for (@{ $_[0] }) {
        if (@$_ == 2) { $desugar{ $_->[0] } //= $_->[1]; next }
        my ($key, $kind, $name, $n) = @$_;
        next if $anon{$key};
        $anon{$key} = ["$kind $name", $name];
        $rec{"$kind $name"} //= $n;
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
our %staticname;            # a function's statics, by id: their names as globals
our $cur_global;            # the global whose items are being translated
our $in_global;             # a global's items are being translated
our %literals;              # its compound literals so far, by global
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

# long double's arithmetic is glibc's soft-fp (the functions gcc calls from
# libgcc for it): the one ttpc's C layer calls for an operation, a negation
# or a conversion is reached as a call is. Targets of 64-bit words for now
# (DI: 64 bits): riscv64, aarch64, x86_64.
my %sfop = ('+' => 'add', '-' => 'sub', '*' => 'mul', '/' => 'div');
my %sfcmp = ('==' => 'eq', '!=' => 'ne', '<' => 'lt', '>' => 'gt', '<=' => 'le', '>=' => 'ge');
# its floating type, from clang's spelling (ctype is not asked: it brings in
# the types it is shown)
sub tword { my ($n) = @_; return '' unless $n && $n->{type}; (my $q = qt($n)) =~ s/\b(const|volatile)\s+//g; $q =~ /^(float|double|long double)$/ ? $q : '' }
sub isld { tword($_[0]) eq 'long double' }
# the ff words of an operand's type, after C's conversions (ctype)
sub tword_int { my ($n) = @_; join ' ', ctype(qt($n)) }
# an integer type of a conversion to or from long double: unsigned?
sub unsigned_t { my ($n) = @_; my ($t) = ctype(qt($n)); $t =~ /^(u\d+|char)$/ }
sub softfp {
    my ($n) = @_;
    my $k = $n->{kind} // '';
    if ($k eq 'BinaryOperator' || $k eq 'CompoundAssignOperator') {
        my $op = $n->{opcode};
        my $ld = isld((kids($n))[0]) || isld((kids($n))[1]);
        if ($k eq 'CompoundAssignOperator') { $op =~ s/=$//; $ld ||= ($n->{computeResultType}{qualType} // '') eq 'long double' }
        want("__$sfop{$op}tf3") if $ld && $sfop{$op};
        want("__$sfcmp{$op}tf2") if $ld && $sfcmp{$op};
    } elsif ($k eq 'UnaryOperator' && $n->{opcode} eq '-' && isld($n)) {
        want('__negtf2');
    } elsif ($k eq 'CStyleCastExpr' || ($k eq 'ImplicitCastExpr'
            && ($n->{castKind} // '') =~ /^(IntegralToFloating|FloatingToIntegral|FloatingCast)$/)) {
        my ($to, $from) = (tword($n), tword((kids($n))[0]));
        return if $to eq $from || ($to ne 'long double' && $from ne 'long double');
        if ($to eq 'long double') {
            want($from eq 'float' ? '__extendsftf2' : $from eq 'double' ? '__extenddftf2'
                : '__float' . (unsigned_t((kids($n))[0]) ? 'un' : '') . 'ditf');
        } else {
            want($to eq 'float' ? '__trunctfsf2' : $to eq 'double' ? '__trunctfdf2'
                : '__fix' . (unsigned_t($n) ? 'uns' : '') . 'tfdi');
        }
    } elsif ($k eq 'ImplicitCastExpr' && ($n->{castKind} // '') eq 'FloatingToBoolean' && isld((kids($n))[0])) {
        want($_) for '__netf2', '__extenddftf2';
    }
}

# A GCC asm statement (glibc's own, riscv64; asm_stmt_other below for
# the other targets). clang's JSON has its operands
# but not its text: the template and the constraints come from the .i. Its
# instructions become an asm function of their own, the statement a call of
# it: a register input is an argument (a0 ...), a memory operand (A, m) the
# address of its lvalue as one, the register output (one at most; +r is
# also an argument) what it returns, from t0. Its instructions: the CSRs'
# (soft-fp's sfp-machine.h: frrm, csrs fflags, ...), lr, sc and the AMOs
# (glibc's atomics).
my %asmfn;
# one asm function per name: two statements that would share one stop
my %asmsig;
sub asm_once { my ($name, $sig, $n) = @_; stop("two asm statements named $name", $n) if ($asmsig{$name} //= $sig) ne $sig }
# the overflow builtins builtins.ff.txt has, by name and operand types
my %ovf = map { ($_ => 1) } map { "__builtin_add_overflow $_" } 'u64 u64 u64', 'u32 u32 u32', 'u32 u32 u64', 'u32 u64 u64', 'u64 int u32', 'u64 u64 int', 'int int int';
$ovf{"__builtin_mul_overflow $_"} = 1 for 'u64 u64 u64', 'u32 u64 u64', 'u64 int u32';
my %csrno = (fflags => 1, frm => 2, fcsr => 3);
sub asm_ins {
    my ($n, $op, @a) = @_;
    my $csr = sub { my ($c) = @_; $csrno{$c} // ($c =~ /^\d+$/ ? $c : stop("the CSR $c", $n)) };
    my $base = sub { my ($m) = @_; $m =~ /^(-?\d*)\((\w+)\)$/ && ($1 eq '' || $1 == 0) or stop("the asm memory operand $m", $n); node($2) };
    return node('csrrs', node(2), node('zero'), node($a[0])) if $op eq 'frrm' && @a == 1;
    return node('csrrw', node(2), node($a[0]), node('zero')) if $op eq 'fsrm' && @a == 1;
    return node('csrrs', node(1), node('zero'), node($a[0])) if $op eq 'frflags' && @a == 1;
    return node('csrrw', node(1), node($a[0]), node('zero')) if $op eq 'fsflags' && @a == 1;
    return node('csrrs', node($csr->($a[1])), node('zero'), node($a[0])) if $op eq 'csrr' && @a == 2;
    return node("csrr$1", node($csr->($a[0])), node($a[1]), node('zero')) if $op =~ /^csr([wsc])$/ && @a == 2;
    # lr, sc and the AMOs, their .aq and .rl the bits before the registers
    if ($op =~ /^(lr|sc|amo(?:swap|add|xor|and|or|min|max|minu|maxu))\.([wd])((?:\.aq|\.rl|\.aqrl)*)$/) {
        # (the parts kept first: a match on one of them sets $1 ... anew)
        my ($ins, $w, $bits) = ($1, $2, $3);
        my ($name, $aq, $rl) = ("$ins.$w", ($bits =~ /aq/ ? 1 : 0), ($bits =~ /rl/ ? 1 : 0));
        return node($name, node($aq), node($rl), $base->($a[1]), node($a[0])) if $ins eq 'lr' && @a == 2;
        return node($name, node($aq), node($rl), node($a[1]), $base->($a[2]), node($a[0])) if @a == 3;
    }
    # .insn i 0x0f, 0, x0, x0, imm: a fence by its fields (fm, pred, succ in imm),
    # glibc's spin hint (0x010: fence w, 0, Zihintpause's pause)
    if ($op eq '.insn' && "@a" =~ /^i 0x0f 0 x0 x0 (0x[0-9a-f]+|\d+)$/i) {
        my $v = $1;
        my $imm = oct($v =~ /^0x/i ? $v : "0$v") & 0xfff;
        return node('fence', node($imm >> 8), node(($imm >> 4) & 15), node($imm & 15));
    }
    stop("the asm instruction $op", $n);
}
# An asm statement's text from the .i: its template (\t a space, \n a ;),
# the constraints of its outputs and inputs, and its operands (clang's).
sub asm_parts {
    my ($n) = @_;
    my $b = $n->{range}{begin}{offset} // $n->{range}{begin}{expansionLoc}{offset};
    defined $b && $cur_unit or stop('an asm statement without its place in the .i', $n);
    (my $s = substr($cur_unit->{text}, $b, 4000)) =~ s/^#.*\n//mg;
    $s =~ s/^\s*(?:__asm__|__asm|asm)\s*(?:(?:__volatile__|__volatile|volatile)\s*)?\(//
        or stop('an asm statement: ' . substr($s, 0, 40), $n);
    # up to its closing parenthesis, in parts at the colons outside strings and parentheses
    my ($depth, $instr, $esc, @parts) = (0, 0, 0, '');
    for my $c (split //, $s) {
        if ($instr) { $parts[-1] .= $c; if ($esc) { $esc = 0 } elsif ($c eq '\\') { $esc = 1 } elsif ($c eq '"') { $instr = 0 } next }
        if ($c eq '"') { $instr = 1 } elsif ($c eq '(') { $depth++ } elsif ($c eq ')') { last if $depth == 0; $depth-- }
        if ($c eq ':' && $depth == 0) { push @parts, ''; next }
        $parts[-1] .= $c;
    }
    my ($tmpl, $outs, $ins) = @parts;
    my $template = join '', $tmpl =~ /"((?:[^"\\]|\\.)*)"/g;
    $template =~ s/\\t/ /g;
    $template =~ s/\\n/;/g;
    my @oc = ($outs // '') =~ /"([^"]*)"/g;
    my @ic = ($ins // '') =~ /"([^"]*)"/g;
    my @ops = kids($n);
    @ops == @oc + @ic or stop('an asm statement whose operands are not its text\'s', $n);
    ($template, \@oc, \@ic, \@ops);
}
sub asm_stmt {
    my ($n) = @_;
    return asm_stmt_other($n) if $target ne 'riscv64';
    my ($template, $ocr, $icr, $opsr) = asm_parts($n);
    my @oc = @$ocr;
    my @ic = @$icr;
    my @ops = @$opsr;
    my (@arg, @text, $ret);
    for my $i (0 .. $#ops) {
        my $c = $i < @oc ? $oc[$i] : $ic[$i - @oc];
        (my $k = $c) =~ s/[=+&]//g;
        if ($k =~ /^[rJK]+$/ && $i < @oc) {
            # the register output
            stop('an asm statement with two register outputs', $n) if defined $ret;
            $ret = $i;
            push @text, 't0';
            push @arg, [$i, 'value', $c =~ /\+/] if $c =~ /\+/;
        } elsif ($k =~ /^[rJK]+$/) {
            push @arg, [$i, 'value'];
            push @text, 'a' . $#arg;
        } elsif ($k =~ /^\d$/ && $i >= @oc && defined $ret && $k == $ret) {
            # an input in the register output's place (dl-lookup's "0"):
            # its value there first, as for +r
            push @arg, [$i, 'value', 1];
            push @text, 't0';
        } elsif ($k =~ /^[Am]$/) {
            push @arg, [$i, 'address'];
            push @text, ($k eq 'A' ? '(a' . $#arg . ')' : '0(a' . $#arg . ')');
        } else {
            stop("the asm constraint $c", $n);
        }
    }
    (my $t = $template) =~ s/%z?(\d+)/$text[$1] \/\/ stop("the asm operand %$1", $n)/ge;
    my @code;
    # a +r output: its value from its argument
    for my $j (0 .. $#arg) { push @code, node('mv', node("a$j"), node('t0')) if $arg[$j][2] }
    push @code, map { my ($op, @a) = split /[\s,]+/; asm_ins($n, $op, @a) } grep { /\S/ } map { s/^\s+|\s+$//gr } split /;/, $t;
    push @code, node('mv', node('t0'), node('a0')) if defined $ret;
    (my $name = "__asm_$template") =~ s/[^A-Za-z0-9]+/_/g;
    $name .= '_' . join '', map { (my $k = $_) =~ s/[^A-Za-z0-9]//g; $k } @oc, '_', @ic;
    asm_once($name, "$template : @oc : @ic", $n);
    push @out, [$cur_unit, node("$name:", node('asm'), node('comment', node("glibc's asm statement \"$template\"")), @code, node('ret'))]
        unless $asmfn{$name}++;
    my @args = map { my ($i, $how) = @$_; $how eq 'address' ? node('address', atom($ops[$i])) : atom($ops[$i]) } @arg;
    my $call = @args ? node($name, @args) : node($name);
    return defined $ret ? (item(expr($ops[$ret])), node('='), $call) : $call;
}

# The same on the other targets (--target), for what glibc's soft-fp has
# there: an input in a register is an argument, in the target's argument
# registers (aarch64 x0 ..., x86_64 rdi rsi rdx rcx r8 r9), a memory operand
# its address as one, the register output the function's value (x0, rax).
# aarch64's FP/SIMD operand (w, a float) is moved from its argument to s16
# ... (sfp-machine.h's fdiv, fadd ... that raise its exceptions); x86_64's
# x operand, only in an empty template (sfp-exceptions.c: the division is
# the C around it), passes through a register as it is.
my %argregs = (aarch64 => [map { "x$_" } 0 .. 7], x86_64 => [qw(rdi rsi rdx rcx r8 r9 r12 r13)]);
my %retreg = (aarch64 => 'x0', x86_64 => 'rax');
my %fpsysreg = (fpcr => 0xDA20, fpsr => 0xDA21);
sub asm_ins_other {
    my ($n, $op, @a) = @_;
    if ($target eq 'aarch64') {
        return node('mrs', node($fpsysreg{$a[1]}), node($a[0])) if $op eq 'mrs' && @a == 2 && defined $fpsysreg{$a[1]};
        if ($op =~ /^f(?:add|sub|mul|div)$/ && @a == 3 && "@a" =~ /^([sd])\d+ [sd]\d+ [sd]\d+$/) {
            my $w = $1;
            stop("the asm instruction $op @a", $n) unless "@a" =~ /^$w\d+ $w\d+ $w\d+$/;
            return node("$op.$w", node($a[2]), node($a[1]), node($a[0]));
        }
    } elsif ($target eq 'x86_64') {
        return node('fwait') if $op eq 'fwait' && !@a;
        return node($op, node($1)) if $op =~ /^(?:div|mul)q$/ && @a == 1 && $a[0] =~ /^%(\w+)$/;
        if ($op =~ /^(?:ldmxcsr|stmxcsr|fldenv|fnstenv)$/ && @a == 1 && $a[0] =~ /^(-?\d*)\(%(\w+)\)$/) {
            return node("$op.m", node($1 eq '' ? 0 : $1), node($2));
        }
    }
    stop("the asm instruction $op", $n);
}
sub asm_stmt_other {
    my ($n) = @_;
    my $regs = $argregs{$target} or stop("an asm statement on $target", $n);
    my ($template, $oc, $ic, $ops) = asm_parts($n);
    my %fixed = $target eq 'x86_64' ? (a => 'rax', d => 'rdx', c => 'rcx', S => 'rsi', D => 'rdi') : ();
    # each operand: what it is, and the register it wants (x86's a, d ...)
    my (@want, $ret, @code, @after, %text);
    for my $i (0 .. $#$ops) {
        my $out = $i < @$oc;
        my $c = $out ? $oc->[$i] : $ic->[$i - @$oc];
        (my $k = $c) =~ s/[=+&]//g;
        $k = 'r' if $k eq 'rm' && $target eq 'x86_64';
        if ($out && $fixed{$k}) {
            # an output in a fixed register: stored through its address after
            stop("the asm constraint $c", $n) if $c =~ /\+/;
            push @want, [$i, 'address'];
            $text{$i} = $fixed{$k};
        } elsif ($out && ($k eq 'r' || ($k eq 'x' && $target eq 'x86_64'))) {
            # the register output: the function's value (+: it goes in first, as an argument)
            stop('an asm statement with two register outputs', $n) if defined $ret;
            $ret = $i;
            $text{$i} = $retreg{$target};
            push @want, [$i, 'value', $retreg{$target}] if $c =~ /\+/;
        } elsif (!$out && $k =~ /^\d$/) {
            # an input in an output's place
            my $r = $text{$k} // stop("the asm constraint $c", $n);
            push @want, [$i, 'value', $r];
        } elsif (!$out && $fixed{$k}) {
            push @want, [$i, 'value', $fixed{$k}];
            $text{$i} = $fixed{$k};
        } elsif (!$out && ($k eq 'r' || ($k eq 'x' && $target eq 'x86_64'))) {
            push @want, [$i, 'value'];
        } elsif (!$out && $k eq 'w' && $target eq 'aarch64') {
            push @want, [$i, 'value', 'w'];
        } elsif ($k eq 'm') {
            push @want, [$i, 'mem'];
        } else {
            stop("the asm constraint $c", $n);
        }
    }
    # the arguments: one that goes to a register that is an argument's is
    # that argument, so that no move overwrites another; the others in turn
    my %slotof = map { ($regs->[$_] => $_) } 0 .. $#$regs;
    my (@slot, %taken);
    for my $w (@want) { my $r = $w->[2]; next unless defined $r && defined $slotof{$r} && !$taken{ $slotof{$r} }; $w->[3] = $slotof{$r}; $taken{ $slotof{$r} } = 1 }
    my $next = 0;
    for my $w (@want) { next if defined $w->[3]; $next++ while $taken{$next}; $w->[3] = $next; $taken{$next++} = 1 }
    stop('an asm statement with too many operands', $n) if grep { $_->[3] > $#$regs } @want;
    my @arg;
    for my $w (sort { $a->[3] <=> $b->[3] } @want) {
        my ($i, $how, $r, $j) = @$w;
        my $a = $regs->[$j];
        $arg[$j] = [$i, $how eq 'value' ? 'value' : 'address'];
        if ($how eq 'address') {
            push @after, $target eq 'x86_64' ? node('movq.mr', node($text{$i}), node(0), node($a)) : stop("the asm output $oc->[$i]", $n);
        } elsif ($how eq 'mem') {
            $text{$i} = $target eq 'x86_64' ? "0(%$a)" : "[$a]";
        } elsif (defined $r && $r eq 'w') {
            # aarch64's FP/SIMD operand, a float or a double, from its argument
            my $t = tword($ops->[$i]);
            stop("the asm operand w of a $t", $n) unless $t eq 'float' || $t eq 'double';
            my $v = 16 + $j;
            push @code, $t eq 'float' ? node('fmov.s.w', node("w$j"), node("s$v")) : node('fmov.d.x', node($a), node("d$v"));
            $text{$i} = ($t eq 'float' ? 's' : 'd') . $v;
        } elsif (defined $r && $r ne $a) {
            push @code, $target eq 'aarch64' ? node('orr', node($a), node('xzr'), node($r)) : node('movq', node($a), node($r));
        } else {
            $text{$i} //= $a;
        }
    }
    @arg = grep { defined } @arg;
    # the template: x86's %v (v under AVX, nothing here: glibc is not built
    # for AVX) and gcc's dialects, {att|intel} or {att}
    (my $t = $template) =~ s/%v//g;
    $t =~ s/\{([^|}]*)\|[^}]*\}/$1/g;
    $t =~ s/\{([^}]*)\}/$1/g;
    $t =~ s{%([a-z]?)(\d+)}{
        my ($m, $i) = ($1, $2);
        my $r = $text{$i} // stop("the asm operand %$m$i", $n);
        if ($m eq 'w' && $r =~ /^x(\d+)$/) { $r = "w$1" }
        elsif ($m ne '' && !($m eq 's' && $r =~ /^s\d/) && !($m eq 'd' && $r =~ /^d\d/) && !($m eq 'x' && $r =~ /^x\d/)) { stop("the asm operand %$m$i", $n) }
        $target eq 'x86_64' && $r !~ /\(/ ? "%$r" : $r;
    }ge;
    push @code, map { my ($op, @a) = split /[\s,]+/; asm_ins_other($n, $op, @a) } grep { /\S/ } map { s/^\s+|\s+$//gr } split /;/, $t;
    push @code, @after;
    (my $name = "__asm_$template") =~ s/[^A-Za-z0-9]+/_/g;
    $name .= '_' . join('', map { s/[^A-Za-z0-9]//gr } @$oc) . '_' . join('', map { s/[^A-Za-z0-9]//gr } @$ic);
    asm_once($name, "$template : @$oc : @$ic", $n);
    push @out, [$cur_unit, node("$name:", node('asm'), node('comment', node("glibc's asm statement \"$template\"")), @code, node('ret'))]
        unless $asmfn{$name}++;
    my @args = map { my ($i, $how) = @$_; $how eq 'address' ? node('address', atom($ops->[$i])) : atom($ops->[$i]) } @arg;
    my $call = @args ? node($name, @args) : node($name);
    return defined $ret ? (item(expr($ops->[$ret])), node('='), $call) : $call;
}

sub expr {
    my ($n) = @_;
    my $k = $n->{kind};
    softfp($n);
    # GNU's &&L, the address of a label of the function
    return node('address', node(ffname($label{ $n->{labelDeclId} } // stop('the address of no label', $n)))) if $k eq 'AddrLabelExpr';
    # in a global's items, an array field that decays to its first element's
    # address (dl-support's .l_scope = _dl_main_map.l_scope_mem): the address of
    # the path, the same address, as ttpc takes an item
    if ($in_global && $k eq 'ImplicitCastExpr' && ($n->{castKind} // '') eq 'ArrayToPointerDecay' && strip((kids($n))[0])->{kind} =~ /^(MemberExpr|ArraySubscriptExpr)$/) {
        return node('address', expr((kids($n))[0]));
    }
    # a function as a value is its address (a function name alone is a call in ff)
    return node('address', expr((kids($n))[0])) if $k eq 'ImplicitCastExpr' && ($n->{castKind} // '') eq 'FunctionToPointerDecay';
    # the conversions C makes between integers and floating types, and
    # between those, are written out, as a cast is
    if ($k eq 'ImplicitCastExpr' && ($n->{castKind} // '') =~ /^(IntegralToFloating|FloatingToIntegral|FloatingCast)$/) {
        return cast_node([ctype(qt($n))], item(expr((kids($n))[0])));
    }
    # C's conversion to _Bool (in ff a u8) gives 0 or 1: the value compared
    # with 0 (the low byte of the value would be has_zero_eq's mask, 0 for a
    # zero byte above the first). long double has no literal of its own: 0, a
    # double, converts
    if ($k =~ /^(ImplicitCastExpr|CStyleCastExpr)$/ && ($n->{castKind} // '') =~ /^(Integral|Pointer|Floating)ToBoolean$/) {
        my ($e) = kids($n);
        my $zero = $1 eq 'Floating' ? hexfloat(0, isld($e) ? 'double' : qt($e)) : 0;
        return node(':', operand($e, $prec{'!='}, 0), node('!='), node($zero));
    }
    return expr((kids($n))[0]) if $k =~ /^(ImplicitCastExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/;
    return node(':', expr((kids($n))[0])) if $k eq 'ParenExpr';
    if ($k eq 'IntegerLiteral') {
        # a literal keeps its type (2UL is a u64): an int is a plain number,
        # another type a typed literal, the type word over the number
        my @t = ctype(qt($n));
        return @t == 1 && $t[0] ne 'int' ? node($t[0], node($n->{value})) : node($n->{value});
    }
    return node($n->{value}) if $k eq 'CharacterLiteral';
    if ($k eq 'FloatingLiteral' && isld($n)) {
        # a long double literal that a double holds exactly: that double, cast
        my $v = 0 + $n->{value};
        sprintf('%.17g', $v) eq $n->{value} || $v == 0 && $n->{value} =~ /^0(\.0*)?$/ or stop("the long double literal $n->{value}", $n);
        want('__extenddftf2');
        return node('cast:', node('long double'), node(hexfloat($v, 'double')));
    }
    return node(hexfloat($n->{value}, qt($n))) if $k eq 'FloatingLiteral';
    return wide_text($n) if $k eq 'StringLiteral' && $n->{value} =~ /^(L|u|U)"/;
    return string_value($n) if $k eq 'StringLiteral';
    # __func__ and its kin: the function's name, as the string clang has for it
    if ($k eq 'PredefinedExpr') { my ($l) = kids($n); $l && $l->{kind} eq 'StringLiteral' or stop('a PredefinedExpr', $n); return string_value($l) }
    if ($k eq 'DeclRefExpr') {
        my $d = $n->{referencedDecl};
        $wanttag{ $enumof{ $d->{name} } } = 1 if $d->{kind} eq 'EnumConstantDecl' && $enumof{ $d->{name} };
        # (by unit and id: clang's ids are unique in one unit only)
        return node($staticname{"$cur_unit $d->{id}"}) if $d->{kind} eq 'VarDecl' && $staticname{"$cur_unit $d->{id}"};
        # a global register variable is its register (tp for THREAD_SELF)
        return node($regvar{ $d->{name} }) if $d->{kind} eq 'VarDecl' && !$local{ $d->{id} } && $regvar{ $d->{name} };
        # a function, or a variable that is not this function's own: a global
        # (this unit's own static, if another unit has one of its name)
        if ($d->{kind} eq 'FunctionDecl' || ($d->{kind} eq 'VarDecl' && !$local{ $d->{id} })) { my $g = own($d->{name}); want($g); return node(ffname($g)) }
        return node(ffname($d->{name}));
    }
    if ($k eq 'OffsetOfExpr') {
        # C's offsetof: clang's JSON has not its parts, the .i has them. As
        # C's own macro has it: the address of the field of a T at 0, a number
        my $b = $n->{range}{begin}{offset} // $n->{range}{begin}{expansionLoc}{offset};
        defined $b && $cur_unit or stop('an offsetof without its place in the .i', $n);
        (my $s = substr($cur_unit->{text}, $b, 2000)) =~ s/^#.*\n//mg;
        $s =~ s/^\s*__builtin_offsetof\s*\(\s*// or stop('an offsetof: ' . substr($s, 0, 40), $n);
        my ($depth, $at, @part) = (0, 0, '');
        for my $c (split //, $s) {
            if ($c eq '(' || $c eq '[') { $depth++ } elsif ($c eq ')' || $c eq ']') { last if $depth == 0; $depth-- }
            if ($c eq ',' && $depth == 0) { push @part, ''; next }
            $part[-1] .= $c;
        }
        @part == 2 or stop('an offsetof of ' . scalar(@part) . ' parts', $n);
        my ($type, $member) = map { s/^\s+|\s+$//gr } @part;
        my @path = map { /^\[(\d+)\]$/ ? node($1) : node(ffname($_)) } $member =~ /(\w+|\[\d+\])/g;
        return node('cast:', node('u64'),
            node('address', node('address', (map { node($_) } ctype($type)), node('0'), node('.'), @path)));
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
        # in a global's items, the address of an element of a global array is
        # the array and that many elements on, as C has it (&a[i] is a + i),
        # the form ttpc works out while compiling (__io_vtables[IO_FILE_JUMPS])
        my $s = strip($e);
        $s = strip((kids($s))[0]) while $s->{kind} eq 'ParenExpr';     # (stdfiles' &(__io_vtables[...]))
        if ($op eq '&' && $in_global && $s->{kind} eq 'ArraySubscriptExpr') {
            my ($b, $i) = kids($s);
            # (the index a number, as ttpc wants it there: an enum constant its value)
            my $x = strip($i);
            my @i = $x->{kind} eq 'DeclRefExpr' && $x->{referencedDecl}{kind} eq 'EnumConstantDecl' && defined $enumval{ $x->{referencedDecl}{name} }
                ? node($enumval{ $x->{referencedDecl}{name} }) : item(expr($i));
            return node(':', expr($b), node('+'), @i) if strip($b)->{kind} eq 'DeclRefExpr';
        }
        return node('address', expr($e)) if $op eq '&';
        return (node($op), atom($e)) if $op eq '-' || $op eq '!' || $op eq '~';
        return $n->{isPostfix} ? (atom($e), node($op)) : (node($op), atom($e)) if $op eq '++' || $op eq '--';
        return expr($e) if $op eq '+';
        return expr($e) if $op eq '__extension__';     # only quiets gcc's -pedantic
        stop("the operator $op", $n);
    }
    if ($k eq 'CStyleCastExpr') {
        return cast_node([ctype(qt($n))], item(expr((kids($n))[0])));
    }
    if ($k eq 'ArraySubscriptExpr' || $k eq 'MemberExpr') {
        # a path from a variable: its elements and fields in a row, xs i x
        my @path;
        my $base = $n;
        while (1) {
            # (an anonymous member, C11's, is no step: ttpc finds its fields in it)
            if ($base->{kind} eq 'MemberExpr') { unshift @path, node(ffname($base->{name})) if ($base->{name} // '') ne ''; $base = strip((kids($base))[0]); next }
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
        if ($c->{kind} =~ /^(MemberExpr|ArraySubscriptExpr)$/) {
            # through a function pointer at the end of a path: p / fn / x is
            # p->fn (x), its arguments after the path's fields and indexes
            my @p = expr($c);
            @p == 1 && @{ $p[0]{children} } or stop('a call through a path that is not one node', $n);
            # (without arguments, a . after the path: the field alone is its value)
            push @{ $p[0]{children} }, @args ? map { item(expr($_)) } @args : node('.');
            return @p;
        }
        if ($c->{kind} =~ /^(CStyleCastExpr|ConditionalOperator|CallExpr)$/) {
            # through a function pointer that is a value, not a variable (dl-fini's
            # ((fini_t) array[i]) ()): the value, a ., then the arguments
            my @p = expr($c);
            @p = node(':', @p) if @p > 1;    # (a conditional)
            @p == 1 or stop('a call through ' . $c->{kind} . ' of several nodes', $n);
            push @{ $p[0]{children} }, node('.'), map { item(expr($_)) } @args;
            return @p;
        }
        $c->{kind} eq 'DeclRefExpr' or stop('a call through ' . $c->{kind}, $n);
        my $name = $c->{referencedDecl}{name};
        # (its value a long, as its first argument is made one)
        return cast_node([ctype(qt($n))], item(expr($args[0]))) if $name eq '__builtin_expect';
        if ($name eq '__builtin_constant_p') {
            # gcc's answer where it cannot tell is 0, and code that asks must
            # mean the same either way: 1 for a literal, else 0
            return node(strip($args[0])->{kind} =~ /^(IntegerLiteral|CharacterLiteral)$/ ? 1 : 0);
        }
        # a builtin of a libc function is a call of it, as gcc makes one
        # where it does not expand the builtin
        $name = $1 if $name =~ /^__builtin_((?:mem|str|stp)\w+|free|malloc)$/;
        # gcc's alloca: ttpc's, C on the shared page, which the function gives
        # back when it returns
        return node('alloca', map { item(expr($_)) } @args) if $name eq '__builtin_alloca';
        # gcc's type-generic overflow builtins: one function in builtins.ff.txt
        # for each set of operand types glibc uses, named for them
        # (__builtin_add_overflow u32 u32 u32)
        if ($name =~ /^__builtin_(add|mul)_overflow$/) {
            my @t = map { tword_int($_) } @args;
            my $sig = "@t" =~ /^(\S+) (\S+) address (\S+)$/ ? "$1 $2 $3" : '';
            $ovf{"$name $sig"} or stop("$name on @t", $n);
            return node("$name $sig", map { item(expr($_)) } @args);
        }
        # gcc's type-generic float classification, in builtins.ff.txt, one
        # function for each floating type (printf_fp has double and long double)
        if ($name =~ /^__builtin_(isnan|isinf_sign|signbit)$/) {
            my $t = tword_int($args[0]);
            $t =~ /^(double|long double)$/ or stop("$name on $t", $n);
            return node("$name $t", item(expr($args[0])));
        }
        # C's va_ words, as clang has them
        return node('va_start', item(expr($args[0]))) if $name eq '__builtin_va_start' || $name eq '__builtin_c23_va_start';
        return node('va_end', item(expr($args[0]))) if $name eq '__builtin_va_end';
        return node('va_copy', item(expr($args[0])), item(expr($args[1]))) if $name eq '__builtin_va_copy';
        # GNU C's passing on of a variadic function's own extra arguments
        return node('va_arg_pack') if $name eq '__builtin_va_arg_pack';
        return node('va_arg_pack_len') if $name eq '__builtin_va_arg_pack_len';
        # the builtins glibc in ff has by hand (src/glibc/builtins.ff.txt)
        return node($name, map { item(expr($_)) } @args) if $name =~ /^__builtin_(stdc_rotate_right|stdc_rotate_left|unreachable|trap|return_address|extract_return_addr|clz|clzl|clzll|ctz|ctzl|ctzll|popcount|popcountl|popcountll|bswap16|bswap32|bswap64|stdc_count_ones|stdc_bit_width|stdc_leading_zeros|stdc_trailing_zeros|stdc_has_single_bit|stdc_bit_ceil|add_overflow|mul_overflow|add_overflow_p)$/ || $name eq '__atomic_always_lock_free';
        # and those of one target (builtins-<target>.ff.txt)
        return node($name) if $name eq '__builtin_aarch64_get_fpcr' && $target eq 'aarch64' && !@args;
        stop("the builtin $name", $n) if $name =~ /^__builtin_/;
        $name = own($name) if $c->{referencedDecl}{kind} eq 'FunctionDecl';
        want($name) if $c->{referencedDecl}{kind} eq 'FunctionDecl' && $name !~ /^__builtin_/;
        # a call through a variable without arguments: a . after it (the
        # variable alone is its value; pthread_once's init_routine (), the
        # atexit functions of exit)
        if ($c->{referencedDecl}{kind} ne 'FunctionDecl' && !@args) { my ($v) = expr($c); push @{ $v->{children} }, node('.'); return $v }
        return node(ffname($name), map { item(expr($_)) } @args);
    }
    if ($k eq 'AtomicExpr') {
        # gcc's atomic builtins: a call of libatomic's function for the size,
        # as gcc makes where it does not expand one (glibc in ff has them in
        # builtins.ff.txt)
        my ($p, $o, @v) = kids($n);
        my $a = $n->{name};
        # (libatomic's functions take and give u8 ... u64: the value is C's
        # type again, an enum's or an int's, as the builtin has it)
        my @t = ctype(qt($n));
        return cast_node([@t], atomic_call($n, $a, $p, $o, @v)) unless "@t" eq 'void' || "@t" =~ /^(u8|u16|u32|u64)$/;
        return atomic_call($n, $a, $p, $o, @v);
    }
    if ($k eq 'VAArgExpr') { my ($ap) = kids($n); return node('va_arg', item(expr($ap)), map { node($_) } ctype(qt($n))) }
    # C's c ? a : b, a leaf ? and a leaf : among the siblings, between = and ||
    # in precedence, right to left (ttpc gives both branches the type C
    # does); GNU C's a ?: b is ? and : in a row, a worked out once
    if ($k eq 'BinaryConditionalOperator') {
        my ($common, undef, undef, $b) = kids($n);
        return (operand($common, 2, 0), node('?'), node(':'), operand($b, 1.5, 1));
    }
    if ($k eq 'ConditionalOperator') {
        my ($c, $a, $b) = kids($n);
        return (operand($c, 2, 0), node('?'), operand($a, 2, 0), node(':'), operand($b, 1.5, 1));
    }
    if ($k eq 'StmtExpr') {
        my ($cs) = kids($n);
        my @sys = syscall_idiom($cs);
        return @sys ? @sys : node(':', body($cs));
    }
    if ($k eq 'CompoundLiteralExpr') {
        # in a global's items it is a static object of its own (dl-support's
        # &(struct link_map *) { &_dl_main_map }): a global, named for that one
        if (defined $cur_global) {
            my $g = ffname($cur_global) . ' literal ' . ++$literals{$cur_global};
            push @out, [$cur_unit, decl({ kind => 'VarDecl', type => $n->{type}, inner => [kids($n)] }, 1, $g)];
            return node($g);
        }
        my @t = ctype(qt($n));
        @t == 1 && (!$scalar_word{$t[0]} || $t[0] ne 'address' && $t[0] ne 'array') or stop('a compound literal of ' . qt($n), $n);
        # (one of a scalar type is a typed literal, u32 / 0; ttpc gives
        # address / u32 / 0 a temporary, C's &(unsigned int){0})
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

# The call of libatomic's function for an atomic builtin
sub atomic_call {
    {
        my ($n, $a, $p, $o, @v) = @_;
        return node("__atomic_exchange_" . csize(qt($n)), item(expr($p)), item(expr($v[0])), item(expr($o))) if $a eq '__atomic_exchange_n';
        return node("__atomic_load_" . csize(qt($n)), item(expr($p)), item(expr($o))) if $a eq '__atomic_load_n';
        return node("__atomic_store_" . csize(qt($v[0])), item(expr($p)), item(expr($v[0])), item(expr($o))) if $a eq '__atomic_store_n';
        # clang's order: ptr, success, expected, failure, desired, weak
        return node("__atomic_compare_exchange_" . csize(qt($v[2])), item(expr($p)), item(expr($v[0])), item(expr($v[2])), item(expr($o)), item(expr($v[1])))
            if $a eq '__atomic_compare_exchange_n';
        return node("${1}_" . csize(qt($n)), item(expr($p)), item(expr($v[0])), item(expr($o)))
            if $a =~ /^(__atomic_(?:fetch_(?:add|sub|and|or|xor|nand)|(?:add|sub|and|or|xor|nand)_fetch))$/;
        stop("the atomic $a", $n);
    }
}

# The bytes of a scalar or an address: what the atomics need
my %wsize = (char => 1, i8 => 1, u8 => 1, short => 2, i16 => 2, u16 => 2, int => 4, i32 => 4, u32 => 4,
    long => 8, i64 => 8, u64 => 8, address => 8);
sub csize { my ($t) = @_; return 4 if $t =~ /^enum\b/; my ($w) = ctype($t); $wsize{$w} // die "c2ff: no size for $t\n" }

# A floating constant as an exact hex float, from its bits (f after a
# float's): what ttpc reads without rounding
sub hexfloat {
    my ($v, $type) = @_;
    my ($t) = ctype($type);
    # a float literal above FLT_MAX by less than half its last place is
    # FLT_MAX, as C rounds it (sfp-machine.h's 3.40282347E+38); Perl's pack
    # makes it inf
    $v = ($v < 0 ? -1 : 1) * 3.4028234663852886e38
        if $t eq 'float' && abs($v) > 3.4028234663852886e38 && abs($v) < 3.4028235677973366e38;
    my ($bits, $m, $bias, $suffix) = $t eq 'float' ? (unpack('L<', pack('f<', $v)), 23, 127, 'f') :
        $t eq 'double' ? (unpack('Q<', pack('d<', $v)), 52, 1023, '') : die "c2ff: a constant of $type\n";
    my $e = $bits >> $m & ($t eq 'float' ? 0xff : 0x7ff);
    my $f = $bits & ((1 << $m) - 1);
    fail_float($v) if $e == ($t eq 'float' ? 0xff : 0x7ff);
    my $digits = int(($m + 3) / 4);
    my $hex = sprintf "%0*x", $digits, $f << (4 * $digits - $m);
    $hex =~ s/0+$//;
    my ($lead, $exp) = $e == 0 ? (0, 1 - $bias) : (1, $e - $bias);
    return "0x0p+0$suffix" if $e == 0 && $f == 0;
    sprintf "0x%d%sp%+d%s", $lead, ($hex eq '' ? '' : ".$hex"), $exp, $suffix;
}
sub fail_float { die "c2ff: a constant with no hex form: $_[0]\n" }

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
    # (a node's text holds no NUL: gconv's alias list, texts with NULs between)
    return () if $s =~ /\0/;
    for (@p) { return () unless utf8::decode(my $u = $_) && !($array && /^-?(?:0x[0-9a-f]+|\d+)$/i) }
    @p;
}
# A wide literal as an address: an array of its elements, a global of its
# own (as a compiler lays a literal out), wide text 1, 2, ...
my $nwide = 0;
sub wide_text {
    my ($n) = @_;
    my $name = 'wide text ' . ++$nwide;
    my @t = ctype(qt($n));
    my @e = wide($n);
    pop @e while @e && $e[-1] == 0;
    push @out, [$cur_unit, node("$name:", map({ node($_) } @t), grouped(255 - @t, map { node($_) } @e))];
    node('address', node($name));
}
sub texts {
    my ($n) = @_;
    my $s = bytes($n);
    return node('') if $s eq '';
    my @p = pieces($s) or stop('a text that is not UTF-8 text', $n);
    map { node($_) } @p;
}
# A string literal as a value: address / char / its text. But a text that ff
# reads as something else (an operator: __dcigettext's "/", a word ff
# reserves), holds a NUL (which a node's text cannot) or is longer than a
# node's 255 bytes (a __PRETTY_FUNCTION__: a value is one text) is a global
# char array of its own, text 1, 2, ..., and the value the address of its
# first char.
my $ntext = 0;
# cast: type value; under address / char (or u8) a leaf is a text, so a leaf
# value goes in a : (printf-parse's (const char *) format)
sub cast_node {
    my ($t, @v) = @_;
    @v = node(':', @v) if "@$t" =~ /^address (char|u8)$/ && @v == 1 && !@{ $v[0]{children} };
    node('cast:', map({ node($_) } @$t), @v);
}
sub string_value {
    my ($n) = @_;
    my $s = bytes($n);
    return node('address', node('char'), texts($n)) unless $isop{$s} || $s =~ /^(?:\?|:|\.|\.\.\.)$/ || $reserved{$s} || $s =~ /\0/ || length($s) > 255;
    my $name = 'text ' . ++$ntext;
    my @c = (unpack('C*', $s), 0);
    push @out, [$cur_unit, node("$name:", node('array'), node('char'), node(scalar @c), grouped(252, map { node($_) } @c))];
    node('address', node($name, node('0')));
}
# A wide literal's elements (L"", u"", U""): each escape one element, each
# character its code point
sub wide {
    my ($n) = @_;
    my $s = $n->{value};
    $s =~ s/^(?:L|u8|u|U)"|"$//g;
    my @e;
    while ($s ne '') {
        if ($s =~ s/^\\x([0-9a-fA-F]+)//) { push @e, hex $1 }
        elsif ($s =~ s/^\\u([0-9a-fA-F]{4})// || $s =~ s/^\\U([0-9a-fA-F]{8})//) { push @e, hex $1 }
        elsif ($s =~ s/^\\([0-7]{1,3})//) { push @e, oct $1 }
        elsif ($s =~ s/^\\(.)//) { my $c = $esc{$1} // stop("the escape \\$1", $n); push @e, ord $c }
        else { $s =~ s/^(.)//s; my $c = $1; utf8::decode($c); push @e, ord $c }
    }
    @e;
}
# What sets a char array: its text, or where that cannot be text, its bytes
# as numbers; the zeros at the end are the rest, which is 0. A wide literal
# sets a wchar_t array: its elements as numbers.
sub array_text {
    my ($n) = @_;
    if ($n->{value} =~ /^(L|u|U)"/) {
        my @e = wide($n);
        pop @e while @e && $e[-1] == 0;
        return map { node($_) } @e;
    }
    my $s = bytes($n);
    $s =~ s/\0+$//;
    return () if $s eq '';
    # (a local takes no text leaves, ttpc fills only a global's array with text:
    # its codes, as dl-map-segments' char bssname[80] = " glibc: .bss")
    my @p = $in_global ? pieces($s, 1) : ();
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
    # a conditional (1.5) in a : where what holds it binds tighter; not as the
    # else branch of another (right to left) nor as the value of an =
    return node(':', @e) if $s->{kind} =~ /^(Binary)?ConditionalOperator$/ && (1.5 < $p || (!$right && 1.5 == $p));
    @e;
}

# The LabelStmts under a node.
sub labels { my ($n) = @_; (($n->{kind} // '') eq 'LabelStmt' ? $n : ()), map { labels($_) } kids($n) }
# Whether a node of that kind is under n.
sub holds { my ($n, $k) = @_; (($n->{kind} // '') eq $k) || grep { holds($_, $k) } kids($n) }
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

# A block's statements. (A local declared first in a function without a
# value would be one more parameter, but the comment that says where the
# function comes from ends them.)
sub body {
    my ($cs) = @_;
    map { stmt($_) } kids($cs);
}

sub stmt {
    my ($n) = @_;
    my $k = $n->{kind};
    return node(':', body($n)) if $k eq 'CompoundStmt';
    # a local extern declaration names the global: nothing of its own
    return map {
        my $d = $_;
        if ($d->{kind} eq 'StaticAssertDecl') {
            # C's _Static_assert: clang has checked it (the .i would not parse
            # otherwise) and it makes no code; it stays as a comment, its text
            my (undef, $m) = kids($d);
            my $text = $m ? join('', map { $_->{content} } texts($m)) : '';
            node('comment', node("_Static_assert, checked by clang: $text"));
        } elsif ($d->{kind} eq 'TypedefDecl') {
            # a typedef in a function (dl-load's d_tag_utype): what it stands
            # for, as a unit's own typedefs are; it makes no code
            $typedef{ $d->{name} } //= qt($d);
            ();
        } elsif ($d->{kind} eq 'LabelDecl') {
            # GNU's __label__ (a local label of a macro's): a label of the
            # function, as every label in ff is
            ();
        } elsif ($d->{kind} =~ /^(RecordDecl|EnumDecl)$/) {
            # a struct, union or enum declared in a function: a type of the
            # unit, named for its place as an anonymous one is, where used
            ();
        } elsif (($d->{storageClass} // '') eq 'extern') {
            $weak{ $d->{name} } //= $d if grep { $_->{kind} =~ /^(WeakAttr|ErrorAttr)$/ } @{ $d->{inner} || [] };
            want($d->{name});
            ();
        } elsif (($d->{storageClass} // '') eq 'static' && !holds($d, 'AddrLabelExpr')) {
            # a static of a function lives as long as the program: a global,
            # named for its function (hugepages' mode_always)
            my $g = ffname($cur_fn) . ' ' . ffname($d->{name});
            $staticname{"$cur_unit $d->{id}"} = $g;
            push @out, [$cur_unit, decl($d, 1, $g)];
            ();
        } else {
            # the one lowering: a static holding the addresses of the function's
            # labels (vfprintf's jump tables, const) is set where it stands, as a
            # local: a global cannot name them, they are addresses only inside it
            decl($d);
        }
    } kids($n) if $k eq 'DeclStmt';
    return node('return', $n->{inner} ? item(expr((kids($n))[0])) : ()) if $k eq 'ReturnStmt';
    return asm_stmt($n) if $k eq 'GCCAsmStmt';
    return ifs('if', $n) if $k eq 'IfStmt';
    if ($k eq 'WhileStmt') { my ($c, $b) = kids($n); return node('while', item(expr($c)), sub_body($b)) }
    if ($k eq 'DoStmt') { my ($b, $c) = kids($n); return node('do while', item(expr($c)), sub_body($b)) }
    if ($k eq 'ForStmt') {
        # clang's parts: init, a condition variable, cond, inc, body ({} when absent)
        my ($i, undef, $c, $s, $b) = kids($n);
        # an init declaring several (dl-load's *ph = phdr, *ph_end = ...): their
        # scope is the loop, as C has it, so a block holds them and the loop
        my @i = clause($i, 1);
        return node(':', @i, node('for', node(':'), clause($c), clause($s, 1), sub_body($b))) if $i && $i->{kind} && $i->{kind} eq 'DeclStmt' && @i > 1;
        return node('for', @i, clause($c), clause($s, 1), sub_body($b));
    }
    if ($k eq 'SwitchStmt') {
        my ($v, $b) = kids($n);
        return node('switch', item(expr($v)), cases($b->{kind} eq 'CompoundStmt' ? kids($b) : $b));
    }
    return labelled($n) if $k eq 'CaseStmt' || $k eq 'DefaultStmt';
    return node(ffname($n->{name}) . ':', stmt((kids($n))[0])) if $k eq 'LabelStmt';
    return node('goto', node(ffname($label{ $n->{targetLabelDeclId} } // stop('a goto to no label', $n)))) if $k eq 'GotoStmt';
    # GNU's goto *p: to the address p holds (a label's, &&L)
    return node('goto', node('content', expr((kids($n))[0]))) if $k eq 'IndirectGotoStmt';
    # a statement under an attribute (__attribute__ ((fallthrough)), a hint to
    # the compiler): the statement
    return map { stmt($_) } grep { $_->{kind} !~ /Attr$/ } kids($n) if $k eq 'AttributedStmt';
    return node('break') if $k eq 'BreakStmt';
    return node('continue') if $k eq 'ContinueStmt';
    return () if $k eq 'NullStmt';
    return effect($n) if $k =~ /Expr$|Operator$|Literal$/;
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
    my (@pre, @out);
    for my $s (@_) {
        if ($s->{kind} eq 'CaseStmt' || $s->{kind} eq 'DefaultStmt') { push @out, labelled($s); next }
        # before the first case only declarations without a value, which the
        # whole body sees (exit's function pointers): what they do is nothing
        if (!@out) {
            stop('a statement before the first case', $s)
                unless $s->{kind} eq 'DeclStmt' && !grep { $_->{init} || kids($_) } kids($s);
            push @pre, stmt($s);
            next;
        }
        push @{ $out[-1]{children} }, stmt($s);
    }
    (@pre, @out);
}
# A case or default and what clang puts under it: its first statement, or
# the next case.
sub labelled {
    my ($n) = @_;
    my @k = kids($n);
    my $sub = pop @k;
    # GNU's case range, case lo ... hi: its two values
    my @head = $n->{kind} ne 'CaseStmt' ? node('default')
        : @k == 2 ? node('case', item(expr($k[0])), node('...'), item(expr($k[1])))
        : node('case', item(expr($k[0])));
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
    my ($v, $global, $name) = @_;
    $v->{kind} eq 'VarDecl' or stop('a declaration of ' . $v->{kind}, $v);
    # a variable-length array (iofwide's wchar_t to_buf[max]): array, the
    # element's type and the count, which clang has only as text in the type
    if (!$global && qt($v) =~ /^(.*?) ?\[([^\[\]]*[A-Za-z_][^\[\]]*)\]$/) {
        my ($elem, $count) = ($1, $2);
        my @c = vla_count($count, $v);
        return node(ffname($v->{name}) . ':', node('array'), map({ node($_) } ctype($elem)), @c > 1 ? node(':', @c) : @c);
    }
    my @t = ctype(qt($v));
    my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
    local $in_global = $global;
    my @i = $init ? init($init) : ();
    # a global takes each item as one node
    @i = node(':', @i) if $global && @i > 1 && strip($init)->{kind} ne 'InitListExpr' && !bare_string($init);
    # under address / char a leaf is text: a value that starts with a leaf goes
    # in a : (vfprintf's char *workend = work_buffer + WORK_BUFFER_SIZE)
    @i = node(':', @i) if "@t" =~ /^address (char|u8)$/ && @i && !@{ $i[0]{children} } && !bare_string($init);
    # (a thread-local one, __thread, stays a global: with one thread that is
    # the same, and glibc's asm reaches it as s2ff has la.tls.ie, tp 0)
    node(($name // ffname($v->{name})) . ':', map({ node($_) } @t), grouped(255 - @t, @i));
}
# A variable-length array's count from its text: names (its locals), numbers,
# + - * / and parentheses, as ff infix.
sub vla_count {
    my ($text, $v) = @_;
    my @stack = ([]);
    for my $tok ($text =~ /\s*([A-Za-z_]\w*|\d+|[-+*\/()])/g) {
        if ($tok eq '(') { push @stack, []; next }
        if ($tok eq ')') { my $in = pop @stack; push @{ $stack[-1] }, node(':', @$in); next }
        push @{ $stack[-1] }, node($tok =~ /^[A-Za-z_]/ ? ffname($tok) : $tok);
    }
    @stack == 1 && @{ $stack[0] } or stop("the count of a variable-length array: $text", $v);
    @{ $stack[0] };
}
sub init {
    my ($n) = @_;
    my $s = strip($n);
    # a char array set from one text in braces, { "..." } (gconv's builtin_aliases):
    # as the text alone, which C makes it
    if ($s->{kind} eq 'InitListExpr' && (my @k = kids($s)) == 1) { if (my $str = bare_string($k[0])) { return array_text($str) } }
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
    # a union set through a member not its first (plural-exp's .val.args):
    # ttpc sets members by place, a union's all at 0, so zeros come first for
    # the members before it, then its item, as C leaves the rest zero
    my @before = union_before($l);
    (@before, map { init_item($_) } @k);
}
sub union_before {
    my ($l) = @_;
    my $f = $l->{field} or return ();
    my $t = expand(qt($l));
    $t =~ /^union\b/ or return ();
    my $r = $rec{$t} // do { my $a = $anon{ anon_key($t) // '' }; $a && $rec{ $a->[0] } } or return ();
    my @fs = grep { $_->{kind} eq 'FieldDecl' } @{ $r->{inner} || [] };
    my ($k) = grep { ($fs[$_]{name} // '') eq ($f->{name} // '') } 0 .. $#fs;      # (an unnamed one: errname's)
    defined $k or stop('a union set through a member it has not: ' . ($f->{name} // '?'), $l);
    map { my @t = ctype(qt($fs[$_])); @t == 1 && $scalar_word{$t[0]} || $t[0] eq 'address' ? node(0) : node(':') } 0 .. $k - 1;
}
sub init_item {
    my ($n) = @_;
    my $s = strip($n);
    return node(':', grouped(255, init_items($s))) if $s->{kind} eq 'InitListExpr';
    if (my $str = bare_string($n)) {
        # a field's text in a : of its own: text leaves in a row are one text
        # (C's "ab" "cd"), and errname's fields are texts side by side; its
        # codes where a text such as "0" would read as a number; "" an empty :
        return node(':', grouped(255, array_text($str)));
    }
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
        ($d->{variadic} ? node('...') : ()),
        node('comment', node("glibc-2.44 $d->{file}")),
        body($cs));
}

sub next_name {
    return shift @todo if @todo;
    while (@roots) { my $r = shift @roots; return $r unless $done{$r}++ }
    undef;
}
while (defined(my $name = next_name())) {
    if (my $a = $alias{$name}) { push @out, [$a->[1], node(ffname($name) . ':', node('alias'), node(ffname($a->[0])))]; want($a->[0]); next }
    if (my $f = $ifunc{$name}) {
        my ($d, $u, $r) = @$f;
        my ($ret, $ps) = split_fn(expand(qt($d)));
        defined $ret or die "c2ff: the type of $name: " . qt($d) . "\n";
        my $i = 0;
        push @out, [$u, node(ffname($name) . ':', node('ifunc'), node(ffname($r)), map({ node($_) } ctype($ret)),
            map({ $i++; node("p$i:", map { node($_) } ctype($_)) } params($ps)))];
        want($r);
        next;
    }
    if (my $f = $fn{$name}) { local $cur_unit = $f->[1]; push @out, [$f->[1], function($name, body_of(@$f))]; next }
    if (my $v = $var{$name}) { local $cur_unit = $v->[1]; local $cur_global = $name; push @out, [$v->[1], decl($v->[0], 1, $name ne $v->[0]{name} ? ffname($name) : undef)]; next }
    # a weak name nothing defines: its address is 0 (ttpc's weak)
    if (my $w = $weak{$name}) {
        # (said, so that the reach can add what defines it where an object
        # it links references it strongly, as the linker does: vtables'
        # pragma weak _IO_file_doallocate, which stdio.o needs)
        warn "c2ff: weak, address 0: $name\n";
        if ($w->{kind} eq 'FunctionDecl') {
            my ($ret) = split_fn(expand(qt($w)));
            push @out, [undef, node(ffname($name) . ':', node('weak'), node('function'), map { node($_) } ctype($ret))];
        } else {
            push @out, [undef, node(ffname($name) . ':', node('weak'), map { node($_) } ctype(qt($w)))];
        }
        next;
    }
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
        # (a variadic one's ... a leaf after its parameters, as a function's)
        map({ $_ eq '...' ? node('...') : do { $i++; node("p$i:", map { node($_) } ctype($_)) } } params($ps)));
}
while (my @t = grep { !$tdone{$_} } sort keys %wanttag) {
    for my $tag (@t) {
        $tdone{$tag} = 1;
        # a tag C only declares (struct rtld_catch;) is an incomplete type, used
        # through an address: a struct without fields
        my $d = $rec{$tag} // $enumd{$tag} // ($tag =~ /^(struct|union) / ? { kind => 'RecordDecl', tagUsed => $1, inner => [] } : undef)
            or do { warn "c2ff: no definition of $tag\n"; next };
        my ($kind) = $tag =~ /^(\S+)/;
        if ($kind eq 'enum') {
            # a constant keeps its value where C gives it one (clang has worked it out)
            unshift @types, node($tagname{$tag} . ':', node('enum'), grouped(254, map {
                my $v = enum_value($_);
                node(ffname($_->{name}) . ':', defined $v ? node($v) : ())
            } grep { $_->{kind} eq 'EnumConstantDecl' } kids($d)));
        } else {
            # a bitfield: its type run, then its width (one with no name, padding,
            # takes its bits under a name of its own)
            my $pad = 0;
            unshift @types, node($tagname{$tag} . ':', node($kind), map {
                my $f = $_;
                my @w;
                if ($f->{isBitfield}) {
                    my ($c) = grep { $_->{kind} eq 'ConstantExpr' } kids($f);
                    defined $c && defined $c->{value} or stop('a bitfield without its width', $f);
                    $c->{value} > 0 or stop('a bitfield of width 0', $f);
                    @w = node($c->{value});
                }
                # (an unnamed field that is not a bitfield is C11's anonymous struct
                # or union, its fields the record's own: : as before)
                my $name = defined $f->{name} && $f->{name} ne '' ? ffname($f->{name}) : $f->{isBitfield} ? 'padding ' . ++$pad : undef;
                node((defined $name ? "$name:" : ':'), (map { node($_) } ctype(qt($f))), @w)
            } grep { $_->{kind} eq 'FieldDecl' } kids($d));
        }
    }
}
}

# glibc in ff is a page per glibc directory (string, stdio-common, ...), its
# types in one of their own, the weak names in another: a node holds 255
# children, so a longer page goes on as name 2, name 3, ...
sub unit_name { my ($u) = @_; return 'weak' unless $u; (my $n = $u->{i}) =~ s{^.*/([^/]+/[^/]+)\.i$}{$1}; $n }
sub groups {
    my ($name, @n) = @_;
    my @g;
    for (my $i = 0; $i < @n; $i += 255) { push @g, node(($i ? "$name " . ($i / 255 + 1) : $name) . ':', @n[$i .. ($i + 254 < $#n ? $i + 254 : $#n)]) }
    @g;
}
if (defined $program) {
    # glibc's startup is left out, so __libc_setup_tls does not run: tp points
    # into a zeroed block instead, where THREAD_SELF (tp less a struct pthread
    # and its tcbhead_t, 1.8 KiB) finds a zeroed struct pthread, as one thread
    # that nothing has set has it (malloc's SINGLE_THREAD_P reads it). On
    # riscv64 only for now: another target's thread pointer is no register
    # of C (tpidr_el0, fs), and its milestones so far (ldouble) need none
    my $tcb = $target eq 'riscv64';
    print write_txt(node('import', node($program)), @types, (map { $_->[1] } @out),
        ($tcb ? node('__ff_tcb:', node('array'), node('u64'), node('1024')) : ()),
        node('_start:', node('void'), ($tcb ? (node('tp'), node('='), node('cast:', node('u64'), node('address', node('__ff_tcb'))),
            node('+'), node('4096')) : ()), ($early ? node('__libc_early_init', node('1')) : ()),
            ($exit ? node('exit', node('main')) : node('syscall', node('SYS_exit'), node('main')))));
} else {
    my (@order, %by);
    # (by directory, not by unit: the trees a program reads have 255 pages in
    # all, and M4 has more units than that; each function's comment names its
    # unit)
    for (@out) { my $g = unit_name($_->[0]) =~ s{/.*}{}r; push @order, $g unless $by{$g}; push @{ $by{$g} }, $_->[1] }
    print write_txt(groups("$page types", @types), map { groups("$page $_", @{ $by{$_} }) } @order);
}
warn "c2ff: renamed: " . join(', ', map { "$_ -> $renamed{$_}" } sort keys %renamed) . "\n" if %renamed;
