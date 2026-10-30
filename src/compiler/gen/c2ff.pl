#!/usr/bin/env perl
# c2ff.pl — C as ff: the definitions a program reaches in preprocessed C
# files (clang's JSON AST of each), written in ttpc's C layer, one C construct
# per ff construct (see language.ff.txt). Nothing is lowered: a construct the
# C layer has no form for stops the translation, named, with where it is.
#
#   perl c2ff.pl [--page name] [--target t] tu.json=tu.i ... -- root ... > out.ff.txt
#   perl c2ff.pl --program tree [--index tree/index.ff] [--target t] tu.json=tu.i -- main > prog.ff.txt
#   perl c2ff.pl --types        (the type words, for a look)
#   perl c2ff.pl --pass [--target t] tu.json=tu.i ...   (each unit's own pass, cached)
#   an argument @file stands for the lines of file
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
# them where it does not expand them; __builtin_mempcpy is memcpy + n, which
# gcc always makes of it.
#
# With --program, what the roots reach is a program: its definitions on the
# page itself, after include / tree (glibc in ff, which has the rest, its
# startup too: start.S's _start, which calls __libc_start_main with main).
# With --start, for a target whose glibc in ff has no startup of its own
# yet, the program has a _start that exits with what main returns. With
# --index, the index.ff of the tree's folder: a weak name of the program's
# that the tree defines is the tree's, as the linker takes an object's
# definition for an undefined weak one (libsupport's mallopt), and so is a
# function of the tree's that a header has as a gnu89 extern inline one.
#
# --object before tu.json=tu.i: that unit is an object of the program,
# linked whole as ld links one (not an archive's member): its constructors
# and destructors are roots.
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
use feature 'current_sub';
use FindBin;
use lib $FindBin::Bin;
my $json_parser = eval { require JSON::XS; JSON::XS->new } || do { require JSON::PP; JSON::PP->new };
use FF qw(node layers write_txt read_ff);
use Words;
use FFold qw(ldround ratq qlit);
use Header qw(license_nodes header_of unit_label);
use Digest::SHA;
use POSIX ();

# ---- types ------------------------------------------------------------------
# A C type as clang prints it (its canonical form, desugaredQualType when
# there is one) becomes a run of ff type words. Qualifiers (const, volatile,
# restrict) have no ff form and no effect on the code, and are dropped.

my %scalar = (
    'char' => 'char',                   # signed or not as the target's ABI says (ttpc's cc_char)
    'signed char' => 'i8', 'unsigned char' => 'u8',
    'short' => 'short', 'signed short' => 'short', 'unsigned short' => 'u16',
    'int' => 'int', 'signed int' => 'int', 'signed' => 'int',
    'unsigned int' => 'u32', 'unsigned' => 'u32',
    'long' => 'long', 'signed long' => 'long', 'unsigned long' => 'u64',
    'float' => 'float', 'double' => 'double', 'long double' => 'long double',
    '__float128' => 'long double',      # x86_64's _Float128 for clang (clang-prelude.h)
    'long long' => 'i64', 'signed long long' => 'i64', 'unsigned long long' => 'u64',
    '_Bool' => 'u8', 'void' => 'void',
    # (C23's bool, the type of libgcc's C under gcc 16's gnu23: _Bool)
    'bool' => 'u8',
    '__builtin_va_list' => 'va_list',
    # (aarch64's __builtin_va_list is AAPCS64's struct; ttpc's va_list is its
    # own word, as on every target)
    'struct __va_list' => 'va_list',
    # C's complex types: the shared page's (real / z and imag / z its parts)
    '_Complex float' => 'complex float', '_Complex double' => 'complex double', '_Complex long double' => 'complex long double',
    # (x86_64's complex __float128, libgcc's TC there: complex long double too)
    '_Complex __float128' => 'complex long double', '__float128 _Complex' => 'complex long double',
    'float _Complex' => 'complex float', 'double _Complex' => 'complex double', 'long double _Complex' => 'complex long double',
);

# The words a type run can be made of, besides the names of types.
my %scalar_word = map { $_ => 1 } (values %scalar, 'address', 'array');
my (%fntype, @fntypes);     # function types for pointers to functions
my %treedefs;              # --index file: the names the program's tree defines
our $saw_i128;             # (a 128-bit integer's type met: a function of one stops, sub function)
my %treerec;               # --index file: the records its tree's types page defines
my (%recunit, %ownrec);    # a record tag's unit; a unit's own definitions of tags (reg_rec)
my %ownfnrec;              # a function's own definitions of tags its unit defines otherwise
my %recfn;                 # a tag a function's own definition registered first: that function
my %ownanon;               # a unit's own anonymous records, where another unit's at the same place differ (places)
my %owntd;                 # a unit's own typedefs, where another unit's came first
my %constint;              # a unit's const integer globals of a number (tst-random's const int nseq = 3): the counts of arrays
my %tagname;                # struct, union, enum tags and their ff names
my %typedef;                # typedef names and the types they stand for
my %errorfn;                # functions of the error attribute (by unit and id): no call of them
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

# the names of the records' fields (as ff names them), made again when there
# are more records
my (%fieldname, $nfieldrec);
sub is_fieldname {
    my ($n) = @_;
    if (($nfieldrec // -1) != keys %rec) {
        %fieldname = ();
        for my $r (values %rec) { $fieldname{ ffname($_->{name}) } = 1 for grep { ($_->{kind} // '') eq 'FieldDecl' && defined $_->{name} && $_->{name} ne '' } @{ $r->{inner} || [] } }
        $nfieldrec = keys %rec;
    }
    $fieldname{$n};
}
# A C type string to a list of ff words. A pointer to a function names a
# function type of its own (fn1:, fn2:, ...), made once per spelling.
our $ctype_depth = 0;
# an array's count that is a const integer global of the unit: its number
sub constcounts {
    my ($t) = @_;
    return $t unless $cur_unit && $constint{$cur_unit} && $t =~ /\[[A-Za-z_]/;
    $t =~ s/\[([A-Za-z_]\w*)\]/'[' . ($constint{$cur_unit}{$1} \/\/ $1) . ']'/ger;
}
sub ctype {
    my ($t) = @_;
    local $ctype_depth = $ctype_depth + 1;
    die "c2ff: a type that does not end: $t\n" if $ctype_depth > 100;
    $t = trim($t);
    # (C11's _Atomic (T) is T here: its loads and stores plain ones, which an
    # aligned word's are on the targets; a read-modify-write of one is not
    # atomic: tst-setcontext6's flags of a signal handler)
    $t = trim($t =~ s/_Atomic\s*\(([^()]*)\)/$1/gr =~ s/\b_Atomic\b//gr) if $t =~ /_Atomic/;
    $t = typeof_subst($t) if $t =~ /typeof/;
    $t = vector_mark($t);
    # (x86_64's __seg_fs, clang's address space 257: the user's fs, a type
    # word after the type it qualifies, here a prefix as address is: fs / T)
    $t =~ s/__attribute__\s*\(\(address_space\(257\)\)\)/ __seg_fs /g;
    # an attribute (noreturn, ...) says nothing of the type's layout
    $t =~ s/\s*__attribute__\s*(\(\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)\))?//g;
    $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
    $t = trim($t);
    $t =~ s/\s+/ /g;
    $t = constcounts($t);
    # (T *__seg_fs: the pointer in fs; __seg_fs T: T in fs, after the
    # pointers below, which bind first: __seg_fs struct p * is (__seg_fs
    # struct p) *)
    return ('fs', ctype($1)) if $t =~ /^(.*\S)\s*\b__seg_fs$/;
    # (x86_64's va_list, before the arrays and pointers: %scalar has it)
    return $scalar{$t} if $t =~ /^struct __va_list_tag\b/ && exists $scalar{$t};
    # an array of function pointers, ret (*[n]) (params): the init arrays'
    # void (*[]) (int, char **, char **)
    if ($t =~ /^(.*?)\s*\(\*\s*\[(\d*)\]\)\s*\((.*)\)$/) {
        return ('array', 'address', fntype($1, $3), $2 eq '' ? '[]' : $2);
    }
    # a pointer to an array, T (*)[n]: what an array of arrays parameter
    # is (libm's const double c[][2])
    return ('address', ctype("$1$2")) if $t =~ /^(.*?)\s*\(\*\)\s*((?:\[\d+\])+)$/;
    if ($t =~ /^(.*?)\s*\[(\d*)\]((?:\[\d+\])*)$/) {
        # T[] (a flexible array member, an extern array) has no elements of
        # its own: no count ([] until Words.pm writes it)
        my ($base, $n, $rest) = ($1, $2, $3);
        return ('array', ctype($base . $rest), $n eq '' ? '[]' : $n);
    }
    # (a declarator in parentheses of its own, as the source has them:
    # regex's reg_errcode_t ((*)(void *, bin_tree_t *)))
    $t = "$1 $2" while $t =~ /^(.*?\S)\s*\((\(\*\)\s*\(.*\))\)$/;
    return ('address', fntype($1, $2)) if $t =~ /^(.*?)\s*\(\*\)\s*\((.*)\)$/;
    if ($t =~ /^(.*)\*$/) {
        my $base = expand($1);
        my ($r, $p) = split_fn($base);
        return defined $r ? ('address', fntype($r, $p)) : ('address', ctype($base));
    }
    # (a vector, gcc's vector_size (x86_64's __m128i, __v16qi): vector, its
    # element's type, the count of its elements)
    return ('vector', ctype($2), $1) if $t =~ /^__vector_(\d+)\s+(.*?)\s*$/;
    return ('fs', ctype($1)) if $t =~ /^__seg_fs\s+(.*)$/;
    return ('fs', ctype("$1 $2")) if $t =~ /^(.*?)\s*\b__seg_fs\b\s*(.*)$/;
    return $scalar{$t} if exists $scalar{$t};
    # (x86_64's x87 long double, gcc's XF and XC, which libgcc's C has there
    # (-mlong-double-80): ../../libgcc/clangfix.pl's records __x87ld and
    # __x87lc; ttpc has no type of it yet, so what uses one is left out)
    die "c2ff: x87's 80-bit long double (gcc's XF on x86_64): ttpc has no such type yet\n" if $t =~ /^(?:struct )?__x87l[dc]$/;
    # (__int128, x86_64's, which ttpc has no integer of: its 16 bytes as two
    # u64, for the layout of the audit interface's La_x86_64_regs and
    # La_x86_64_retval, which no code of a static program reads; arithmetic
    # on one stops ttpc)
    if ($t =~ /^(?:__int128_t|__uint128_t|(?:unsigned )?__int128)$/) { $saw_i128 = 1; return ('array', 'u64', 2) }
    return ctype($owntd{$cur_unit}{$t}) if $cur_unit && $owntd{$cur_unit} && exists $owntd{$cur_unit}{$t};
    return ctype($typedef{$t}) if exists $typedef{$t};
    return ctype($desugar{$t}) if exists $desugar{$t};
    return ctype($typeof{$1}) if $t =~ /^(?:typeof|__typeof__) \(\s*(\S+?)\s*\)$/ && exists $typeof{$1};
    if (my $a = own_anon($t) || $anon{ anon_key($t) // '' }) {
        my ($tag, $name) = @$a;
        $wanttag{$tag} = 1;
        return $tagname{$tag} //= $name;
    }
    if ($t =~ /^(struct|union|enum) (\S+)$/) {
        # (a function's own definition of the tag)
        if ($cur_unit && $main::cur_fn && $ownfnrec{$cur_unit} && (my $own = ($ownfnrec{$cur_unit}{$main::cur_fn} // {})->{"$1 $2"})) {
            $wanttag{$own} = 1;
            return $tagname{$own} //= ffname($2) . " " . ffname($main::cur_fn);
        }
        # (a unit's own definition of the tag, reg_rec)
        if ($cur_unit && $ownrec{$cur_unit} && (my $own = $ownrec{$cur_unit}{"$1 $2"})) {
            $wanttag{$own} = 1;
            return $tagname{$own} //= ffname($2) . ' ' . unit_name($cur_unit);
        }
        $wanttag{"$1 $2"} = 1;
        # C keeps tags apart from other names, ff does not: a tag that is
        # also a global's, a function's or a field's name is named with its
        # kind (a struct's name as a value is its compound literal); so is a
        # program's tag that its tree (--index) has too, whose code must keep
        # its own (the public headers' struct _IO_FILE has _lock as a void *,
        # libio's own an _IO_lock_t *)
        # (an alias's name too: glibc's weak alias sigaction of __sigaction,
        # struct sigaction's tag took its name and a program's call of it)
        # (a program's, with --index, "name kind prog": glibc's units name
        # theirs so too, unit-local, and a unit found the program's:
        # tst-grouping_iterator's lc_ctype_data struct, whose fcts field was
        # the program's empty gconv_fcts struct)
        return $tagname{"$1 $2"} //= $var{$2} || $fn{$2} || $alias{$2} || $localname{$2} || is_fieldname(ffname($2)) || $treedefs{ ffname($2) }
            ? (%treedefs ? "$2 $1 prog" : "$2 $1") : ffname($2);
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
# The type of a typeof of an expression clang leaves as text in a type
# (x86_64's THREAD_GETMEM: __typeof (*descr) __seg_fs *, descr THREAD_SELF,
# *(struct pthread *__seg_fs *) ...): a name's declared type, a cast's
# type, one pointer less for a *; undef where it is none of those.
our %ltypeof;
sub typeof_expr {
    my ($e) = @_;
    $e = trim($e);
    $e = trim($1) while $e =~ /^(\((?:[^()]++|(?1))*\))$/ && $e =~ /^\((.*)\)$/s;
    return $ltypeof{$e} if exists $ltypeof{$e};
    return $typeof{$e} if exists $typeof{$e};
    if ($e =~ /^\*(.*)$/s) {
        my $t = typeof_expr($1) // return undef;
        $t = expand($t);
        $t =~ s/\s*\b(?:__seg_fs|const|volatile)\s*$//;
        return $t =~ /^(.*?)\s*\*$/ ? $1 : undef;
    }
    # a cast: (T) then its operand
    return trim($1) if $e =~ /^(\((?:[^()]++|(?1))*\))/ && $e =~ /^\(([^()]*\*)\s*\)\s*\S/;
    # an element, x[i]: of an array its element (the first count gone), of
    # an address what it points to (array_foreach's __typeof ((array)[0]))
    if ($e =~ /^(.*?\S)\s*(\[(?:[^\[\]]++|(?2))*\])$/s) {
        my $t = typeof_expr($1) // return undef;
        $t = expand($t);
        return trim("$1 $2") if $t =~ /^([^\[]*?)\s*\[[^\[\]]*\]\s*(.*)$/;
        return $1 if $t =~ /^(.*?)\s*\*$/;
        return undef;
    }
    undef;
}
sub typeof_subst {
    my ($t) = @_;
    $t =~ s/__attribute__\s*\(\(address_space\(257\)\)\)/ __seg_fs /g;
    $t =~ s{\b(?:typeof|__typeof__|__typeof)\s*(\((?:[^()]++|(?1))*\))}{ my $r = typeof_expr(substr($1, 1, -1)); defined $r ? $r : $& }ge;
    $t;
}
# clang's spelling of a vector type, __attribute__((__vector_size__(16 *
# sizeof(char)))) char, as __vector_16 char, which no attribute's removal
# takes away
sub vector_mark { my ($t) = @_; $t =~ s/__attribute__\(\(__vector_size__\((\d+) \* sizeof\(([^()]*)\)\)\)\)\s*/__vector_$1 /g; $t }
sub expand {
    my ($t) = @_;
    $t = typeof_subst($t) if $t =~ /typeof/;
    for (1 .. 50) {
        $t = vector_mark(trim($t));
        $t =~ s/\s*__attribute__\s*(\(\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)\))?//g;
        $t =~ s/\b(const|volatile|restrict|__restrict)\b//g;
        $t = trim($t);
        if ($cur_unit && $owntd{$cur_unit} && exists $owntd{$cur_unit}{$t}) { $t = $owntd{$cur_unit}{$t}; next }
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
    # (with --index, not a name of the tree's own: its code would take the
    # program's function type for its own fnN)
    our $fnlast //= 0;
    1 while $treedefs{ 'fn' . ++$fnlast };
    my $name = "fn$fnlast";
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
# ff reserves its words, type names and the registers of riscv64 (its
# vector registers v0 ... v31 too: libm's v1), and address and content,
# the words of before that the tree is made in (Words.pm); a C name
# that is one gets a ' after it (type -> type'), which no C name has.

my %reserved = map { $_ => 1 } qw(
    if else while for return break continue comment address content syscall U L UL LL ULL
    array struct union enum function sizeof alignof compile emit fail number
    target include workspace switch case default goto char short int long void
    type i8 i16 i32 i64 u8 u16 u32 u64 va_list va_start va_arg va_end va_copy
    alias ifunc asm items cast weak va_arg_pack va_arg_pack_len real imag generic section constructor destructor fs vector line zero ra sp gp tp fp pc
), map({ ("x$_", "a$_", "s$_", "t$_", "f$_", "fa$_", "fs$_", "ft$_", "v$_") } 0 .. 31);
# --target T: the target the .i were made for, riscv64 if not given. On
# another the registers reserved are its own: the names of the registers
# group of its section in shared.ff.
my $target = 'riscv64';
sub reserve_target {
    my ($t) = @_;
    open my $h, '<:raw', "$FindBin::Bin/../shared.ff" or die "c2ff: cannot open shared.ff: $!\n";
    my ($shared) = grep { $_->{content} eq "shared:" } @{ read_ff(do { local $/; <$h> })->{children} };
    my ($sec) = grep { $_->{content} eq "$t:" } @{ $shared->{children} } or die "c2ff: $t is not a target\n";
    my ($regs) = grep { $_->{content} eq 'registers:' } @{ $sec->{children} } or die "c2ff: $t has no registers\n";
    delete $reserved{$_} for grep { /^(?:x|a|s|t|f|fa|fs|ft|v)\d+$|^(?:zero|ra|sp|gp|tp|fp|pc)$/ } keys %reserved;
    for (@{ $regs->{children} }) { (my $c = $_->{content}) =~ s/:$//; $reserved{$_} = 1 for split ' ', $c }
    # (and on x86_64 its instructions' names, which C's names would hide
    # nothing of: ttpc found the lock prefix for localealias.c's lock, so
    # __libc_lock_lock (lock) took 0's address; pause, setns, fadd ... too;
    # its groups of instructions, isa/x86_64.pl's, and x86_64gnu.ff's)
    if ($t eq 'x86_64') {
        my %insgroup = map { $_ => 1 } qw(alu1 alu2 move unary shift1 shift2 bit branch set cmov stack atomic system sse);
        my @forms = map { @{ $_->{children} } } grep { $insgroup{ $_->{content} =~ s/:$//r } } @{ $sec->{children} };
        if (open my $g, '<:raw', "$FindBin::Bin/../x86_64gnu.ff") {
            my @todo = @{ read_ff(do { local $/; <$g> })->{children} };
            while (my $x = shift @todo) { $x->{content} =~ /^[a-z]\w*:$/ && !grep { $_->{content} =~ /:$/ } @{ $x->{children} } ? push @forms, $x : push @todo, @{ $x->{children} } }
        }
        for (@forms) { $reserved{$1} = 1 if $_->{content} =~ /^([A-Za-z_]\w*):$/ }
    }
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
my $start;                 # --start: a _start of the program's own, SYS_exit (main ())
my %zero;                  # --zero name: glibc's asm only reserves it (zeroed, in .bss)
my %forceweak;             # --weak name: nothing defines it for a static program
my %section;               # a named section: its globals (their keys in %var), in their order
my (%ctor, %ctors_of);      # a constructor or destructor (by key): its word and priority; a unit's
my (@units, @roots);
my $object = 0;          # --object: the next unit is an object, linked whole (its constructors are roots)
my $passonly;              # --pass: only each unit's own pass (unit_pass), made where it is not
our $keep_going;           # --keep-going: what cannot be translated yet is left out (leave_out)
# (@file: the arguments in a file, one a line: all of glibc's units and
# roots are past what one command line holds)
@ARGV = map { /^@(.+)$/ ? do { open my $h, '<', $1 or die "c2ff: cannot open $1: $!\n"; map { chomp; length ? $_ : () } <$h> } : $_ } @ARGV;
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--program') { $program = shift @ARGV; next }
    if ($a eq '--start') { $start = 1; next }
    if ($a eq '--zero') { $zero{ shift @ARGV } = 1; next }
    if ($a eq '--weak') { $forceweak{ shift @ARGV } = 1; next }
    if ($a eq '--index') {
        my $f = shift @ARGV;
        open my $h, '<:raw', $f or die "c2ff: cannot open $f: $!\n";
        my ($index) = grep { $_->{content} eq 'index:' } @{ read_ff(do { local $/; <$h> })->{children} } or die "c2ff: $f has no index\n";
        $treedefs{ $_->{content} =~ s/:$//r } = 1 for FF::kids($index);
        # (and the records its types page defines, types.ff next to it: one
        # the program only declares is the tree's, not an empty one of the
        # program's, which ttpc would take for the tree's too: libgcc's
        # struct _Unwind_Context, which unwind.h only names)
        (my $tf = $f) =~ s{[^/]*$}{types.ff};
        if (open my $t, '<:raw', $tf) {
            my $tree = read_ff(do { local $/; <$t> });
            my @d = map { FF::kids($_) } @{ $tree->{children} };
            @d = map { $_->{content} =~ /^\d+:$/ ? FF::kids($_) : $_ } @d while grep { $_->{content} =~ /^\d+:$/ } @d;
            for (@d) { my @k = FF::kids($_); $treerec{ $_->{content} =~ s/:$//r } = 1 if @k > 1 && $k[0]{content} =~ /^(struct|union)$/ }
        }
        next;
    }
    if ($a eq '--target') { $target = shift @ARGV; next }
    if ($a eq '--pass') { $passonly = 1; next }
    if ($a eq '--keep-going') { $keep_going = 1; next }
    if ($a eq '--object') { $object = 1; next }
    if ($a eq '--') { @roots = @ARGV; last }
    my ($json, $i) = split /=/, $a, 2;
    push @units, { json => $json, i => $i, object => $object };
    $object = 0;
}
die "usage: c2ff.pl [--page name | --program tree] [--target t] tu.json=tu.i ... -- root ...\n" unless @units && (@roots || $passonly);
reserve_target($target) if $target ne 'riscv64';
# arm is ILP32: an unsigned long is its 4-byte word, a u32 there
$scalar{'unsigned long'} = 'u32' if $target eq 'arm';
# and its va_list is the AAPCS's struct __va_list (a pointer), ttpc's va_list
@scalar{'__va_list', 'struct __va_list'} = ('va_list', 'va_list') if $target eq 'arm';
# and x86_64's is the SysV ABI's struct __va_list_tag[1], a parameter of it
# its address: ttpc's va_list, which is that struct on x86_64 and goes as
# its address (gen/patches/abix64.pl)
@scalar{'struct __va_list_tag[1]', 'struct __va_list_tag *'} = ('va_list', 'va_list') if $target eq 'x86_64';

my %enumof;                 # each enum constant's enum, as a tag
my (%enumref, %enumunit);   # the uses of each enum constant and its first unit (enum_rename)
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
# (an enum's definition, its constants: not a declaration of it that came
# first, nss_status's in a header that only names it)
sub enum_consts { grep { $_->{kind} eq 'EnumConstantDecl' } @{ $_[0]{inner} || [] } }
sub set_enumd {
    my ($tag, $d) = @_;
    $enumd{$tag} = $d if !$enumd{$tag} || !enum_consts($enumd{$tag}) && enum_consts($d) || enum_more($enumd{$tag}, $d);
}
# (another unit's definition with every constant of the first, of the same
# value, and more: glibc's dwarf2.h's enum dwarf_location_atom ends at
# DW_OP_nop, gcc's, libgcc's unwinder's, has the GNU ones too)
sub enum_vals { my ($d) = @_; my $v = -1; map { my $e = enum_value($_); $v = defined $e ? $e : $v + 1; ($_->{name} => $v) } enum_consts($d) }
sub enum_more {
    my ($old, $new) = @_;
    my %o = enum_vals($old);
    my %n = enum_vals($new);
    return 0 unless keys %n > keys %o;
    for (keys %o) { return 0 unless exists $n{$_} && $n{$_} == $o{$_} }
    1;
}
sub index_enum {
    my ($d) = @_;
    $enumid{$d->{id}} = $d;
    my @c = grep { $_->{kind} eq 'EnumConstantDecl' } @{ $d->{inner} || [] };
    my $tag = defined $d->{name} ? "enum $d->{name}" : @c ? "enum $c[0]{name} enum" : undef;
    return unless defined $tag;
    set_enumd($tag, $d);
    # (a named one's name ctype gives, once every local's name is known: a
    # tag that is also a local's takes its kind, wordexp's enum action action)
    $tagname{$tag} //= "$c[0]{name} enum" unless defined $d->{name};
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
    # (a program's static whose name its tree (--index) defines: a name of
    # the program's own, as C keeps it apart, so that neither takes the
    # other's; tst-strerror_l-strings' loc, strptime_l's enum constant loc)
    return $own{$u}{$name} = "$name " . unit_name($u) if %treedefs && ($d->{storageClass} // '') eq 'static' && $treedefs{ ffname($name) };
    my $old = $map->{$name} or return $name;
    return $name if $old->[1] == $u || ($d->{storageClass} // '') ne 'static' || ($old->[0]{storageClass} // '') ne 'static';
    return $name if def_text($d, $u) eq def_text($old->[0], $old->[1]);
    $own{$u}{$name} = "$name " . unit_name($u);
}
# A record tag's definition (key "struct x"). The first is everyone's; a
# unit that defines the tag otherwise (its own struct locked_FILE, as
# memstream.c and fmemopen.c each have) has its own, named with the unit
# (x libio/memstream), as its own static is: 1 where it is the first.
sub reg_rec {
    my ($key, $d, $u) = @_;
    if (!$rec{$key}) { $rec{$key} = $d; $recunit{$key} = $u; return 1 }
    return 0 if !$recunit{$key} || $recunit{$key} == $u || def_text($d, $u) eq def_text($rec{$key}, $recunit{$key});
    my $own = "$key " . unit_name($u);
    $rec{$own} //= $d;
    $recunit{$own} //= $u;
    $ownrec{$u}{$key} = $own;
    0;
}
sub own { my ($name) = @_; $cur_unit && $own{$cur_unit} && $own{$cur_unit}{$name} // $name }
sub inner_tags { my ($n) = @_; (($n->{kind} // '') =~ /^(EnumDecl|RecordDecl)$/ ? $n : ()), map { inner_tags($_) } @{ $n->{inner} || [] } }
units_ready(@units);
exit 0 if $passonly;
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
    places($ast->{ff_places}, $u);
    my $file = '';
    for my $d (@{ $ast->{inner} }) {
        $file = $d->{loc}{file} if $d->{loc} && $d->{loc}{file};
        $file = $d->{loc}{expansionLoc}{file} if $d->{loc} && $d->{loc}{expansionLoc} && $d->{loc}{expansionLoc}{file};
        # (the unit's own .i where its AST was made: a BUILD moved since
        # keeps its pass, which names the .i of then)
        $file = $u->{i} if $file ne $u->{i} && $file =~ m{/i/(.+?)(\.clang)?\.i$} && $u->{i} =~ m{/i/\Q$1\E(?:\.clang)?\.i$};
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
        # asm ("memset = __memset_generic") at the top of a unit (riscv's
        # dl-symbol-redir-ifunc.h, in what runs before the ifuncs are
        # resolved): the unit's calls of memset are calls of __memset_generic
        if ($d->{kind} eq 'FileScopeAsmDecl') {
            my ($str) = grep { $_->{kind} eq 'StringLiteral' } @{ $d->{inner} || [] };
            $own{$u}{$1} = $2 if $str && ($str->{value} // '') =~ /^"\s*([.\w]+)\s*=\s*([.\w]+)\s*"$/;
            next;
        }
        my $name = $d->{name} // next;
        # a program's function C names by another asm name (__REDIRECT: XSI's
        # strerror_r is __xpg_strerror_r, C23's strtol __isoc23_strtol): the
        # unit's calls are of that name, as gcc's are (not glibc's hidden __GI_
        # names: the function's own). Not in glibc itself, whose redirects
        # (stpcpy to __stpcpy) name aliases of the same function, and whose C
        # the round trip holds the ff to.
        if (defined $program && $d->{kind} eq 'FunctionDecl' && defined $d->{mangledName} && $d->{mangledName} ne $name && $d->{mangledName} !~ /^__GI_/
            && grep { $_->{kind} eq 'AsmLabelAttr' } @{ $d->{inner} || [] }) {
            $own{$u}{$name} = $d->{mangledName};
        }
        # weak, or a function gcc's error attribute keeps from being called
        if (($d->{storageClass} // '') eq 'register' && (my ($l) = grep { $_->{kind} eq 'AsmLabelAttr' } @{ $d->{inner} || [] })) {
            # (clang has the register as the name it is known by in asm)
            $regvar{$name} = $d->{mangledName} // $l->{label} // stop('a register variable without its register', $d);
            next;
        }
        $weak{$name} //= $d if $d->{kind} =~ /^(VarDecl|FunctionDecl)$/ && ($forceweak{$name} || grep { $_->{kind} =~ /^(WeakAttr|ErrorAttr)$/ } @{ $d->{inner} || [] });
        if ($d->{kind} eq 'TypedefDecl') {
            my $own = $d->{inner} && $d->{inner}[0]{ownedTagDecl};
            # (a typedef's aligned attribute: its record's own, where it names
            # one it defines, __pthread_unwind_buf_t; another's is not kept)
            if ($own && $recid{ $own->{id} } && defined(my $al = align_attr($d))) { $recid{ $own->{id} }{ff_align} = max_align($recid{ $own->{id} }{ff_align}, $al) }
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
                $owntd{$u}{$name} = $d->{type}{qualType} if $typedef{$name} ne $d->{type}{qualType};
            } else {
                $typedef{$name} = qt($d) if ($typedef{$name} // 'void') eq 'void';
                # (a unit's own typedef of the name: strxfrm_l.c's and
                # strcoll_l.c's locale_data_t, each its own struct)
                $owntd{$u}{$name} = qt($d) if $typedef{$name} ne qt($d) && qt($d) ne 'void';
            }
        }
        $typeof{$name} //= qt($d) if $d->{kind} =~ /^(FunctionDecl|VarDecl)$/ && $d->{type};
        my @in = @{ $d->{inner} || [] };
        if ($d->{kind} eq 'FunctionDecl') {
            if (my ($a) = grep { $_->{kind} eq 'AliasAttr' } @in) { $alias{$name} = [$a->{aliasee}, $u]; next }
            if (my ($r) = grep { $_->{kind} eq 'IFuncAttr' } @in) { $ifunc{$name} = [$d, $u, resolver($u, $r)]; next }
            # (a program's gnu89 extern inline function, a header's, is no
            # definition where its tree has the function: gcc never emits it,
            # and its body may only inline, error.h's error with
            # __builtin_va_arg_pack)
            my $inline_only = %treedefs && $d->{inline} && ($d->{storageClass} // '') eq 'extern' && $treedefs{ ffname($name) };
            my $fk;
            if (!$inline_only && grep { $_->{kind} eq 'CompoundStmt' } @in) {
                my $k = $fk = own_name(\%fn, $name, $d, $u);
                $fn{$k} //= [$d, $u];
                # a constructor or destructor: run by the start code, so a
                # root wherever its unit is linked (as an archive member is)
                if (my ($c) = grep { $_->{kind} =~ /^(?:Con|De)structorAttr$/ } @in) {
                    $ctor{$k} = [$c->{kind} eq 'ConstructorAttr' ? 'constructor' : 'destructor', ctor_priority($u, $c)];
                    push @{ $ctors_of{$u} }, $k;
                }
            }
            # (and under address a local named as a tag would be the type: struct
            # msort_param msort_param in qsort)
            # (both found by the unit's own pass, unit_pass)
            $localname{$_} = 1 for @{ $d->{ff_locals} };
            # its own enums and records (getrandom's struct vgetrandom_opaque_params), as globals
            for my $t (@{ $d->{ff_tags} }) {
                if ($t->{kind} eq 'EnumDecl') { index_enum($t) }
                elsif ($t->{completeDefinition}) {
                    $recid{$t->{id}} = $t;
                    next unless defined $t->{name} && $t->{name} ne '';
                    my $key = "$t->{tagUsed} $t->{name}";
                    # (a tag that another function of the unit defines
                    # otherwise is this function's own, named with it:
                    # tst-makecontext-align's struct aligned of check_align_16
                    # and of check_align_32)
                    if (defined $fk && $rec{$key} && ($recunit{$key} // 0) == $u && def_text($t, $u) ne def_text($rec{$key}, $u)) {
                        my $own = "$key " . ffname($fk);
                        $rec{$own} //= $t;
                        $recunit{$own} //= $u;
                        $ownfnrec{$u}{$fk}{$key} = $own;
                        next;
                    }
                    if (reg_rec($key, $t, $u)) { anon_fields($t, $t->{name}); $recfn{$key} = $fk if defined $fk }
                }
            }
        } elsif ($d->{kind} eq 'VarDecl') {
            if (my ($a) = grep { $_->{kind} eq 'AliasAttr' } @in) { $alias{$name} = [$a->{aliasee}, $u]; next }
            # (a const integer global of a number: in C not a constant, so an
            # array of it as count is of variable length, the same as of the
            # number; tst-random's long rnd[nseq][nrnd])
            if (qt($d) =~ /^const (?:(?:unsigned |signed )?(?:char|short|int|long|long long)(?: int)?|unsigned)$/ && ($d->{init} // '') eq 'c'
                && (my ($i) = grep { $_->{kind} !~ /Attr$/ } @in)) {
                my $v = int_const($i);
                $constint{$u}{$name} = $v if defined $v;
            }
            if (($d->{storageClass} // '') ne 'extern' || $zero{$name}) {
                my $k = own_name(\%var, $name, $d, $u);
                # (a global of a named section: reached with the section's bounds)
                if (!$var{$k} && (my ($s) = grep { $_->{kind} eq 'SectionAttr' && $_->{section_name} =~ /^[A-Za-z_]\w*$/ } @in)) { push @{ $section{ $s->{section_name} } }, $k }
                $var{$k} //= [$d, $u];
            }
        } elsif ($d->{kind} eq 'RecordDecl' && $d->{completeDefinition}) {
            my $key = "$d->{tagUsed} $name";
            # (a tag a function of the unit defined first, otherwise, is that
            # function's own, the unit's the global one: libgcc's union
            # unaligned of read_encoded_value_with_base and of read_pointer ...)
            if (defined(my $f = $recfn{$key})) {
                delete $recfn{$key};
                if (($recunit{$key} // 0) == $u && def_text($d, $u) ne def_text($rec{$key}, $u)) {
                    my $own = "$key " . ffname($f);
                    $rec{$own} //= $rec{$key};
                    $recunit{$own} //= $u;
                    $ownfnrec{$u}{$f}{$key} = $own;
                    $rec{$key} = $d;
                    anon_fields($d, $name);
                    next;
                }
            }
            reg_rec($key, $d, $u) and anon_fields($d, $name);
        } elsif ($d->{kind} eq 'EnumDecl') {
            set_enumd("enum $name", $d);
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
                if ($k->{kind} eq 'EnumDecl') { set_enumd("enum $k->{name}", $k) }
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
# line of tu.c2ff is its key: the hash of the pass's own code (the subs it
# runs, from c2ff.pl's text: a change elsewhere in c2ff keeps every
# unit's pass) and the AST's (its size and time first: a JSON made again,
# the same, is not done again), then the .i's (the same way). The units
# without one are done in parallel, C2FF_JOBS at once (3), each its own
# process with one AST in memory, so the reach itself reads no JSON.
# Without its JSON (all of glibc's ASTs take some 16 GB: each is deleted
# once its pass is made, `c2ff.pl --pass tu.json=tu.i ...` makes only
# that) a unit's pass is taken while its .i is the same.
use Storable qw(nfreeze thaw);
my $self_hash;
sub unit_file { (my $f = $_[0]{json}) =~ s/\.json$//; "$f.c2ff" }
# (the pass's code: these subs, as c2ff.pl has them)
my @pass_subs = qw(unit_pass anon_places anon_key locals kids inner_tags unplace);
sub pass_hash {
    open my $h, '<', "$FindBin::Bin/c2ff.pl" or die "c2ff: cannot read c2ff.pl: $!\n";
    my $text = do { local $/; <$h> };
    my $d = Digest::SHA->new(256);
    # (a sub of one line, or up to its closing brace)
    for my $s (@pass_subs) { $text =~ /^(sub \Q$s\E\b[^\n]*\}\n|sub \Q$s\E\b.*?^\}\n)/ms or die "c2ff: no sub $s\n"; $d->add($1) }
    $d->hexdigest;
}
# (the .i's size and time, then its hash: an .i made again, the same,
# keeps its pass)
sub istamp {
    my ($u, $full) = @_;
    my @st = stat $u->{i} or die "c2ff: cannot open $u->{i}: $!\n";
    $full ? ("$st[7] $st[9]", Digest::SHA->new(256)->addfile($u->{i})->hexdigest) : "$st[7] $st[9]";
}
sub ikey { join ' | ', istamp($_[0], 1) }
sub json_key {
    my ($u, $full) = @_;
    $self_hash //= pass_hash();
    my @st = stat $u->{json} or die "c2ff: cannot open $u->{json}: $!\n";
    ("c2ff unit 2 $self_hash", "$st[7] $st[9]", $full ? Digest::SHA->new(256)->addfile($u->{json})->hexdigest : ());
}
# The key of the unit's cache, if it is the AST's of now: else undef.
sub unit_fresh {
    my ($u) = @_;
    my $file = unit_file($u);
    open my $h, '<:raw', $file or return;
    my $line = <$h> // return;
    chomp $line;
    my ($self, $stamp, $hash, $ist, $ihash) = split / \| /, $line;
    return unless defined $ihash;
    # (no JSON: the pass of the same .i)
    unless (-e $u->{json}) {
        $self_hash //= pass_hash();
        return unless $self eq "c2ff unit 2 $self_hash";
        return $h if $ist eq istamp($u);
        my ($t, $now) = istamp($u, 1);
        return unless $now eq $ihash;
        my $rest = do { local $/; <$h> };
        close $h;
        write_unit($file, "$self | $stamp | $hash | $t | $ihash\n", $rest);
        open $h, '<:raw', $file or die "c2ff: cannot open $file: $!\n";
        <$h>;
        return $h;
    }
    my ($s, $t) = json_key($u);
    return unless $self eq $s;
    return $h if $stamp eq $t;
    my (undef, undef, $now) = json_key($u, 1);
    return unless $now eq $hash;
    # (the same AST, made again: its new stamp)
    my $rest = do { local $/; <$h> };
    close $h;
    write_unit($file, "$s | $t | $hash | " . ikey($u) . "\n", $rest);
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
    # a declaration inside a function, of a name defined outside it (an
    # extern in a block: dl-support's __ehdr_start, startup.h's
    # _startup_fatal_not_constant), is one of the unit's as well
    # (a declaration only: a gnu89 extern inline definition at the top is
    # the unit's already)
    my $externs = sub {
        my ($n) = @_;
        return () unless ref $n eq 'HASH';
        (($n->{kind} // '') =~ /^(VarDecl|FunctionDecl)$/ && ($n->{storageClass} // '') eq 'extern'
            && !(grep { $_->{kind} eq 'CompoundStmt' } @{ $n->{inner} || [] }) ? $n : ()),
            map { __SUB__->($_) } @{ $n->{inner} || [] };
    };
    push @{ $ast->{inner} }, map { $externs->($_) } map { @{ $_->{inner} } }
        grep { ($_->{kind} // '') eq 'FunctionDecl' && $_->{inner} && grep { $_->{kind} eq 'CompoundStmt' } @{ $_->{inner} } } @{ $ast->{inner} };
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
    write_unit($file, "$s | $t | $hash | " . ikey($u) . "\n", nfreeze($ast));
}
sub unplace { my ($n) = @_; delete @$n{qw(loc range)}; unplace($_) for @{ $n->{inner} || [] } }
sub units_ready {
    my @todo = grep { !unit_fresh($_) } @_;
    # (a unit whose AST is gone and whose pass is not of its .i, or not of
    # this c2ff's pass: exit 3, its AST is to be made again)
    if (my @gone = grep { !-e $_->{json} } @todo) {
        print STDERR "c2ff: no AST and no pass of $_->{json}: make it again\n" for @gone;
        exit 3;
    }
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
    my ($found, $u) = @_;
    for (@$found) {
        if (@$_ == 2) { $desugar{ $_->[0] } //= $_->[1]; next }
        my ($key, $kind, $name, $n) = @$_;
        if (my $a = $anon{$key}) {
            # (the same place in another unit, defined otherwise there: a
            # skeleton included with another type, strfrom-skeleton.c's union
            # of FLOAT, a double in strfromd's and a long double in
            # strfroml's): that unit's own, named with it
            my ($r, $ru) = ($rec{ $a->[0] }, $recunit{ $a->[0] });
            next if !$u || !$r || !$ru || $ru == $u || def_text($n, $u) eq def_text($r, $ru);
            my $own = "$name " . unit_name($u);
            $ownanon{$u}{$key} = ["$kind $own", $own];
            $rec{"$kind $own"} //= $n;
            $recunit{"$kind $own"} //= $u;
            next;
        }
        $anon{$key} = ["$kind $name", $name];
        $rec{"$kind $name"} //= $n;
        $recunit{"$kind $name"} //= $u;
    }
}

# a unit's own anonymous record of type spelling t (places), or none
sub own_anon { my ($t) = @_; $cur_unit && $ownanon{$cur_unit} && $ownanon{$cur_unit}{ anon_key($t) // '' } }
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

# The priority of a constructor or destructor (constructor (101)): the JSON
# has none, the .i has it; undef without one.
sub ctor_priority {
    my ($u, $attr) = @_;
    my $b = $attr->{range}{begin}{offset} // $attr->{range}{begin}{expansionLoc}{offset};
    return undef unless defined $b;
    substr($u->{text}, $b, 80) =~ /^(?:__)?(?:con|de)structor(?:__)?\s*\(\s*(\d+)\s*\)/ ? $1 + 0 : undef;
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
# gcc's __builtin_tgmath (tgmath.h's): its functions, then the arguments; the
# call is the one of the function of the type of the arguments that differ
# in type between the functions (float, double, else long double; an
# integer is a double), so ldexp (v, exp) of a float v is ldexpf. clang-
# prelude.h declares it without parameters, so clang made a float argument
# a double: the call made again, of the chosen function, with the
# arguments' own values converted to its parameters.
sub tgmath {
    my ($n, @args) = @_;
    my @f;
    push @f, shift @args while @args && strip($args[0])->{kind} eq 'DeclRefExpr' && qt(strip($args[0])) =~ /\(/;
    @f >= 3 && @args or stop('__builtin_tgmath without functions and arguments', $n);
    my @ft = map { qt(strip($_)) } @f;
    my $params = sub { $_[0] =~ /\((.*)\)$/ ? split(/, /, $1) : () };
    my @p0 = $params->($ft[0]);
    my @p1 = $params->($ft[1]);
    $ft[0] =~ /^float \(/ && $ft[1] =~ /^double \(/ && $ft[2] =~ /^long double \(/ && @p0 == @args && @p1 == @args
        or stop('__builtin_tgmath of other functions than of float, double, long double', $n);
    my $bare = sub { (my $t = qt($_[0])) =~ s/\b(const|volatile)\s+//g; $t };
    # an argument's value before the promotion of an unprototyped call
    my @v = map {
        my $a = $_;
        $a = (kids($a))[0] while $a->{kind} eq 'ImplicitCastExpr' && ($a->{castKind} // '') eq 'FloatingCast' && $bare->((kids($a))[0]) eq 'float';
        $a
    } @args;
    my $rank = 0;
    for my $i (0 .. $#v) {
        next if $p0[$i] eq $p1[$i];
        my $t = $bare->($v[$i]);
        stop('__builtin_tgmath of a complex argument', $n) if $t =~ /_Complex/;
        my $r = $t eq 'float' ? 0 : $t eq 'long double' ? 2 : 1;
        $rank = $r if $r > $rank;
    }
    my @p = $params->($ft[$rank]);
    my ($ret) = $ft[$rank] =~ /^(.*?) \(/;
    my $isf = sub { $_[0] =~ /^(float|double|long double)$/ };
    my @a = map {
        my ($a, $t) = ($v[$_], $p[$_]);
        my $from = $bare->($a);
        $from eq $t ? $a
            : { kind => 'ImplicitCastExpr', type => { qualType => $t }, inner => [$a],
                castKind => $isf->($t) ? ($isf->($from) ? 'FloatingCast' : 'IntegralToFloating') : 'IntegralCast' }
    } 0 .. $#v;
    return { kind => 'CallExpr', type => { qualType => $ret }, inner => [$f[$rank], @a] };
}
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
# (__float128, x86_64's binary128 where long double is x87's: libgcc's TF, a long double here)
sub tword { my ($n) = @_; return '' unless $n && $n->{type}; (my $q = qt($n)) =~ s/\b(const|volatile)\s+//g; $q = 'long double' if $q eq '__float128'; $q =~ /^(float|double|long double)$/ ? $q : '' }
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
        if ($k eq 'CompoundAssignOperator') { $op =~ s/=$//; $ld ||= ($n->{computeResultType}{qualType} // '') =~ /^(?:long double|__float128)$/ }
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
        want('__netf2');
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
# An asm statement's function, by its name: two statements whose names
# meet but whose text differs ("" : "+m" and "" : "=m", libm's math_opt_barrier
# and its kin) get names of their own, the second the name with a few hex
# digits of its text's hash.
sub asm_once {
    my ($name, $sig, $n) = @_;
    return $name if ($asmsig{$name} //= $sig) eq $sig;
    my $h = substr(Digest::SHA::sha1_hex($sig), 0, 6);
    ($asmsig{"${name}_$h"} //= $sig) eq $sig or stop("two asm statements named ${name}_$h", $n);
    "${name}_$h";
}
# the overflow builtins builtins.ff.txt has, by name and operand types
my %ovf = map { ($_ => 1) } map { "__builtin_add_overflow $_" } 'u64 u64 u64', 'u32 u32 u32', 'u32 u32 u64', 'u32 u64 u64', 'u64 int u32', 'u64 u64 int', 'int int int', 'long int long', 'long long long', 'u64 u32 u64', 'u64 int u64';
$ovf{"__builtin_mul_overflow $_"} = 1 for 'u64 u64 u64', 'u32 u64 u64', 'u64 int u32', 'int int int';
$ovf{"__builtin_sub_overflow $_"} = 1 for 'long long long', 'int long int', 'long int long';
# (and builtins-arm.ff.txt's, of arm's 32-bit size_t)
my %ovf_arm = map { ($_ => 1) } (map { "__builtin_mul_overflow $_" } 'u32 u32 u32', 'u32 int u32'), map { "__builtin_add_overflow $_" } 'u32 int u32', 'u64 u32 int';
my %csrno = (fflags => 1, frm => 2, fcsr => 3);
our $asm_rd_out;
my @xreg = qw(zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6);
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
    # the whole fcsr: frsr rd, fssr rs (fenv's)
    return node('csrrs', node(3), node('zero'), node($a[0])) if $op eq 'frsr' && @a == 1;
    return node('csrrw', node(3), node($a[0]), node('zero')) if $op eq 'fssr' && @a == 1;
    # csrrw/csrrs/csrrc rd, csr, rs; of an immediate csrrwi ... as GNU as
    # takes it (feholdexcept's csrrc of the flags it clears)
    if ($op =~ /^csrr[wsc]$/ && @a == 3) {
        return node("${op}i", node($csr->($a[1])), node($a[2]), node($a[0])) if $a[2] =~ /^\d+$/;
        return node($op, node($csr->($a[1])), node($a[2]), node($a[0]));
    }
    # the float instructions of libm's asm: fclass, fmin and fmax, and the
    # conversions, a rounding mode after their source (dyn, 7, where none is
    # given, as GNU as takes it)
    my %rm = (rne => 0, rtz => 1, rdn => 2, rup => 3, rmm => 4, dyn => 7);
    return node($op, node($a[1]), node($a[0])) if $op =~ /^fclass\.[sd]$/ && @a == 2;
    return node($op, node($a[2]), node($a[1]), node($a[0])) if $op =~ /^f(?:min|max)\.[sd]$/ && @a == 3;
    if ($op =~ /^fcvt\.(?:[wl]u?\.[sd]|[sd]\.[wl]u?)$/ && (@a == 2 || @a == 3)) {
        my $m = @a == 3 ? $rm{ $a[2] } // stop("the rounding mode $a[2]", $n) : 7;
        return node($op, node($a[1]), node($m), node($a[0]));
    }
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
    # .insn 0x<word> of a CSR read, csrrs rd, csr, zero (libgcc's riscv_vlenb,
    # csrr of vlenb, into its register variable): that instruction; where
    # the statement's register output is that variable (its template names
    # no operand), rd is the output, which the asm function returns from t0
    if ($op eq '.insn' && @a == 1 && $a[0] =~ /^0x([0-9a-f]{8})$/i) {
        my $w = hex $1;
        if (($w & 0x707f) == 0x2073 && (($w >> 15) & 31) == 0) {
            my $rd = $xreg[($w >> 7) & 31];
            return (node('csrrs', node($w >> 20), node('zero'), node($rd)), ($asm_rd_out ? node('mv', node($rd), node('t0')) : ()));
        }
    }
    stop("the asm instruction $op", $n);
}
# An asm statement's text from the .i: its template (\t a space, \n a ;),
# the constraints of its outputs and inputs, and its operands (clang's).
sub size_class { my %s = (u64 => 8, long => 8, i64 => 8, u32 => 4, int => 4, i32 => 4); $s{ $_[0] } }
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
    # (an output cast to an integer of its own size, gcc's lvalue there:
    # x86_64's longlong.h and sfp-machine.h, "=r" ((UDItype) (q)): the
    # variable itself)
    for my $i (0 .. $#oc) {
        my $o = $ops[$i];
        next unless $o->{kind} eq 'CStyleCastExpr';
        my $in = strip((kids($o))[0]);
        my ($to, $from) = (tword_int($o), tword_int($in));
        $ops[$i] = $in if $to eq $from || ("$to $from" =~ /^(\S+) (\S+)$/ && size_class($1) && size_class($1) eq size_class($2));
    }
    ($template, \@oc, \@ic, \@ops);
}
sub asm_stmt {
    my ($n) = @_;
    return asm_stmt_other($n) if $target ne 'riscv64';
    my ($template, $ocr, $icr, $opsr) = asm_parts($n);
    my @oc = @$ocr;
    my @ic = @$icr;
    my @ops = @$opsr;
    my (@arg, @text, $ret, $fret, @fmv);
    # (by the lp64d ABI an argument in a register: a float or double in fa0
    # ..., any other in a0 ..., each counted apart)
    my ($ni, $nf) = (0, 0);
    # a float operand's width, s or d
    my $fw = sub { my ($o) = @_; my $t = tword($o); $t eq 'float' ? 's' : $t eq 'double' ? 'd' : stop("an asm operand \"f\" of type " . qt($o), $n) };
    for my $i (0 .. $#ops) {
        my $c = $i < @oc ? $oc[$i] : $ic[$i - @oc];
        (my $k = $c) =~ s/[=+&]//g;
        if ($k eq 'f' && $i < @oc && $c !~ /\+/) {
            # a float register output (libm's fcvt.d.l, fmin.d): ft0, its bits
            # the asm function's value, which C puts in the operand's own bits
            stop('an asm statement with two register outputs', $n) if defined $ret;
            $ret = $i;
            $fret = $fw->($ops[$i]);
            push @text, 'ft0';
        } elsif ($k eq 'f' && $i >= @oc) {
            # a float register input: an argument, in its fa register
            $fw->($ops[$i]);
            push @arg, [$i, 'value', 0, 'fa' . $nf++];
            push @text, $arg[-1][3];
        } elsif ($k eq 'i' && $i >= @oc) {
            # an immediate: its value, worked out (an integer constant
            # expression: feholdexcept's flags or'ed together)
            my $v = int_const($ops[$i]);
            defined $v or stop('an asm operand "i" that is no constant', $n);
            push @text, $v;
        } elsif ($k =~ /^[rJK]+$/ && $i < @oc) {
            # the register output
            stop('an asm statement with two register outputs', $n) if defined $ret;
            $ret = $i;
            push @text, 't0';
            push @arg, [$i, 'value', 1, 'a' . $ni++] if $c =~ /\+/;
        } elsif ($k =~ /^[rJK]+$/) {
            push @arg, [$i, 'value', 0, 'a' . $ni++];
            push @text, $arg[-1][3];
        } elsif ($k =~ /^\d$/ && $i >= @oc && defined $ret && $k == $ret) {
            # an input in the register output's place (dl-lookup's "0"):
            # its value there first, as for +r
            push @arg, [$i, 'value', 1, 'a' . $ni++];
            push @text, 't0';
        } elsif ($k =~ /^[Am]$/) {
            push @arg, [$i, 'address', 0, 'a' . $ni++];
            push @text, ($k eq 'A' ? "($arg[-1][3])" : "0($arg[-1][3])");
        } else {
            stop("the asm constraint $c", $n);
        }
    }
    (my $t = $template) =~ s/%z?(\d+)/$text[$1] \/\/ stop("the asm operand %$1", $n)/ge;
    my @code;
    # a +r output: its value from its argument
    for my $j (0 .. $#arg) { push @code, node('mv', node($arg[$j][3]), node('t0')) if $arg[$j][2] }
    push @code, @fmv;
    # (a register output its template does not name: an instruction's own
    # register, .insn's)
    local $asm_rd_out = defined $ret && $template !~ /%/;
    push @code, map { my ($op, @a) = split /[\s,]+/; asm_ins($n, $op, @a) } grep { /\S/ } map { s/^\s+|\s+$//gr } split /;/, $t;
    push @code, node('fmv.x.' . ($fret eq 's' ? 'w' : 'd'), node('ft0'), node('t0')) if $fret;
    push @code, node('mv', node('t0'), node('a0')) if defined $ret;
    (my $name = "__asm_$template") =~ s/[^A-Za-z0-9]+/_/g;
    $name .= '_' . join '', map { (my $k = $_) =~ s/[^A-Za-z0-9]//g; $k } @oc, '_', @ic;
    $name = asm_once($name, "$template : @oc : @ic", $n);
    push @out, [$cur_unit, node("$name:", node('asm'), node('comment', node("glibc's asm statement \"$template\"")), @code, node('ret'))]
        unless $asmfn{$name}++;
    my @args = map { my ($i, $how) = @$_; $how eq 'address' ? node('address', atom($ops[$i])) : atom($ops[$i]) } @arg;
    my $call = @args ? node($name, @args) : node($name);
    # (a float output: the value's bits are the operand's, *(u64 *) &x = ...)
    return (node('content', cast_node(['address', $fret eq 's' ? 'u32' : 'u64'], node('address', atom($ops[$ret])))), node('='), $call) if $fret;
    return defined $ret ? (item(expr($ops[$ret])), node('='), $call) : $call;
}

# The same on the other targets (--target), for what glibc's soft-fp has
# there: an input in a register is an argument, in the target's argument
# registers (aarch64 x0 ..., x86_64 rdi rsi rdx rcx r8 r9), a memory operand
# its address as one, the register output the function's value (x0, rax).
# aarch64's FP/SIMD operand (w, a float) comes in s0, s1 ... by AAPCS64 and
# is moved to s16 ... (sfp-machine.h's fdiv, fadd ... that raise its
# exceptions); x86_64's
# x operand, in an empty template (sfp-exceptions.c: the division is the C
# around it), passes through a register as it is; in a template with
# instructions (libm's fma: vfmadd213sd), one of a float or a double is an
# xmm register of its own, through its address.
my %argregs = (aarch64 => [map { "x$_" } 0 .. 7], x86_64 => [qw(rdi rsi rdx rcx r8 r9)], arm => [map { "r$_" } 0 .. 3]);
my %retreg = (aarch64 => 'x0', x86_64 => 'rax', arm => 'r0');
# aarch64's system registers as mrs and msr take them: op0 op1 CRn CRm op2
# in 16 bits (tpidr_el0 56962), by name or as GNU's s3_3_c13_c0_2
my %sysreg = (fpcr => [3, 3, 4, 4, 0], fpsr => [3, 3, 4, 4, 1], tpidr_el0 => [3, 3, 13, 0, 2],
    tpidrro_el0 => [3, 3, 13, 0, 3], ctr_el0 => [3, 3, 0, 0, 1], tpidr2_el0 => [3, 3, 13, 0, 5], dczid_el0 => [3, 3, 0, 0, 7],
    midr_el1 => [3, 0, 0, 0, 0], cntvct_el0 => [3, 3, 14, 0, 2], cntfrq_el0 => [3, 3, 14, 0, 0],
    id_aa64pfr0_el1 => [3, 0, 0, 4, 0], id_aa64pfr1_el1 => [3, 0, 0, 4, 1], id_aa64zfr0_el1 => [3, 0, 0, 4, 4],
    id_aa64isar0_el1 => [3, 0, 0, 6, 0], id_aa64isar1_el1 => [3, 0, 0, 6, 1], id_aa64mmfr1_el1 => [3, 0, 0, 7, 1]);
sub sysreg {
    my ($r) = @_;
    my $f = $sysreg{ lc $r } // ($r =~ /^s(\d)_(\d)_c(\d+)_c(\d+)_(\d)$/i ? [$1, $2, $3, $4, $5] : return undef);
    $f->[0] << 14 | $f->[1] << 11 | $f->[2] << 7 | $f->[3] << 3 | $f->[4];
}
my %fpsysreg = (fpcr => 0xDA20, fpsr => 0xDA21);
our $asm_size;      # x86_64: the size (l, q) of the register output's C type
sub asm_ins_other {
    my ($n, $op, @a) = @_;
    if ($target eq 'aarch64') {
        return node('mrs', node(sysreg($a[1])), node($a[0])) if $op eq 'mrs' && @a == 2 && defined sysreg($a[1]);
        return node('msr', node(sysreg($a[0])), node($a[1])) if $op eq 'msr' && @a == 2 && defined sysreg($a[0]);
        # an immediate (brk #1000: abort's trap), none (yield, isb), a
        # barrier's option (dmb ish)
        return node($op, node($1 =~ /^0x/i ? hex $1 : $1)) if $op =~ /^(?:brk|hlt|svc)$/ && @a == 1 && $a[0] =~ /^#?(0x[0-9a-f]+|\d+)$/i;
        return node($op) if $op =~ /^(?:nop|yield|wfe|wfi|sev|sevl|isb|clrex)$/ && !@a;
        # a hint by its number: ttpc names the ones it has (hint 40 is chkfeat)
        my %hint = (0 => 'nop', 1 => 'yield', 25 => 'paciasp', 29 => 'autiasp', 32 => 'bti', 34 => 'bti.c', 36 => 'bti.j', 38 => 'bti.jc', 40 => 'chkfeat');
        return node($hint{$1}) if $op eq 'hint' && @a == 1 && $a[0] =~ /^#?(\d+)$/ && $hint{$1};
        my %barrier = (oshld => 1, oshst => 2, osh => 3, nshld => 5, nshst => 6, nsh => 7, ishld => 9, ishst => 10, ish => 11, ld => 13, st => 14, sy => 15);
        return node($op, node($barrier{ lc $a[0] })) if $op =~ /^(?:dmb|dsb)$/ && @a == 1 && defined $barrier{ lc $a[0] };
        if ($op =~ /^f(?:add|sub|mul|div)$/ && @a == 3 && "@a" =~ /^([sd])\d+ [sd]\d+ [sd]\d+$/) {
            my $w = $1;
            stop("the asm instruction $op @a", $n) unless "@a" =~ /^$w\d+ $w\d+ $w\d+$/;
            return node("$op.$w", node($a[2]), node($a[1]), node($a[0]));
        }
    } elsif ($target eq 'arm') {
        # A32's instructions on registers alone (string-fza.h's uqsub8, sel,
        # uadd8; clz, rev): isa/arm.pl's operands, GNU's reversed
        return node($op, map { node($_) } reverse @a)
            if $op =~ /^(?:uqsub8|uadd8|sel|clz|rev|rev16|rbit)$/ && @a >= 2 && !grep { !/^r\d+$/ } @a;
        # data processing with its last register shifted by an amount
        # (string-fzi's eor %0, %1, %1, ror #16): x.ror sh rm rn rd
        return node("$op.$a[3]", node($1), map { node($_) } reverse @a[0 .. 2])
            if $op =~ /^(?:and|eor|orr|bic|add|sub|rsb)$/ && @a == 5 && !grep { !/^r\d+$/ } @a[0 .. 2] && $a[3] =~ /^(?:lsl|lsr|asr|ror)$/ && $a[4] =~ /^#(\d+)$/;
        # the FP status and control register (get_rounding_mode, fesetround)
        return node('vmrs', node($a[0])) if $op eq 'vmrs' && @a == 2 && $a[0] =~ /^r\d+$/ && $a[1] eq 'fpscr';
        return node('vmsr', node($a[1])) if $op eq 'vmsr' && @a == 2 && $a[0] eq 'fpscr' && $a[1] =~ /^r\d+$/;
    } elsif ($target eq 'x86_64') {
        # an instruction as its bytes (libgcc's cpuinfo.h: xgetbv as .byte
        # 0x0f, 0x01, 0xd0, for an old assembler)
        return map { node('byte', node($_)) } @a if $op eq '.byte' && @a && !grep { !/^(?:0x[0-9a-f]+|\d+)$/i } @a;
        # instructions without operands (ABORT_INSTRUCTION's hlt, the spin
        # loops' pause, cpuid with its fixed registers)
        return node($op) if !@a && $op =~ /^(?:fwait|hlt|pause|nop|cpuid|xgetbv|rdtsc|mfence|lfence|sfence|fnclex|fpatan|syscall)$/;
        # the x87 control and status words in memory (get_rounding_mode's
        # fnstcw): GNU as's forms (x86_64gnu.ff), without REX for rax..rdi
        if ($op =~ /^(?:fnstcw|fldcw|fnstsw)$/ && @a == 1 && $a[0] =~ /^0?\(%(\w+)\)$/ && $1 !~ /^(?:rsp|rbp|r12|r13)$/) {
            my $r = $1;
            return node($op . ($r =~ /^r\d/ ? '' : '.n') . '.m0', node(0), node($r));
        }
        # xchg of a register and memory (THREAD_GSCOPE_RESET_FLAG's xchgl
        # with the thread's gscope_flag: its address, an argument)
        if ($op =~ /^xchg[lq]$/ && @a == 2) {
            my ($m) = grep { $a[$_] =~ /^-?\d*\(%\w+\)$/ } 0 .. 1;
            if (defined $m && $a[1 - $m] =~ /^%(\w+)$/) {
                my $r = $1;
                $a[$m] =~ /^(-?\d*)\(%(\w+)\)$/;
                return node("$op.mr", node($r), node($1 eq '' ? 0 : $1), node($2));
            }
        }
        # an integer instruction on registers: ttpc's name has the size,
        # GNU's may leave it to the operands (bsr %1, %0: the C type of the
        # register output's, $asm_size)
        if (@a && !grep { !/^%\w+$/ } @a) {
            my $o = $op;
            $o .= $asm_size if $o =~ /^(?:bsr|bsf|bswap|xchg|lzcnt|tzcnt|popcnt)$/ && $asm_size;
            return node($o, map { node(s/^%//r) } @a) if $o =~ /^(?:bsr|bsf|bswap|xchg|lzcnt|tzcnt|popcnt)[lq]$/;
        }
        return node($op, node($1)) if $op =~ /^(?:div|mul)q$/ && @a == 1 && $a[0] =~ /^%(\w+)$/;
        # the ALU's operations of two registers (libgcc's soft-fp: add and
        # adc, sub and sbb of two-word fractions), GNU's operands in order
        return node($op, map { node(s/^%//r) } @a) if $op =~ /^(?:add|adc|sub|sbb|and|or|xor)[lq]$/ && @a == 2 && !grep { !/^%\w+$/ } @a;
        # a load of the TCB's word at an offset into the register output
        # (x86_cpu_cet_active's mov %fs:72, %0 of an unsigned int): the fs
        # prefix, then mov's absolute form, as GNU as makes it (64 8b 04 25)
        if ($op =~ /^mov[lq]?$/ && @a == 2 && $a[0] =~ /^%fs:(\d+)$/) {
            my ($s, $d) = (substr($op, 3) || $asm_size // '', $1);
            if ($s && $a[1] =~ /^%(r(?:[abcd]x|[sd]i))$/) {
                my $r = $1;
                return (node('fs'), $s eq 'l' ? node('movl.n.a32', node($d), node($r =~ s/^r/e/r)) : node('movq.a32', node($d), node($r)));
            }
        }
        # FMA on xmm registers (libm's fma and fmaf): FMA3's 213 form and
        # FMA4's, both VEX3 (x86_64gnu.ff)
        if ((($op =~ /^vfmadd213s[sd]$/ && @a == 3) || ($op =~ /^vfmadds[sd]$/ && @a == 4)) && !grep { !/^%xmm\d+$/ } @a) {
            return node("$op.vex3", map { node(s/^%//r) } @a);
        }
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
    # an empty template whose outputs are all read and written (+r: the
    # optimization barriers of dl-new-hash.h) changes nothing: no code
    return () if $template !~ /\S/ && @$oc && !grep { !/\+/ || !/^[=+&]*[rx]+$/ } @$oc;
    # and one with inputs alone (math_force_eval's "" : : "f" (x) of a long
    # double on x86_64, "x" of a float), of values with no effects: none
    return () if $target eq 'x86_64' && $template !~ /\S/ && !@$oc && !grep { !pure($_) } @$ops;
    # (rbx too: the C layer keeps nothing in it across a call)
    my %fixed = $target eq 'x86_64' ? (a => 'rax', b => 'rbx', d => 'rdx', c => 'rcx', S => 'rsi', D => 'rdi') : ();
    local $asm_size;
    if ($target eq 'x86_64' && @$oc) {
        my ($first) = grep { ($oc->[$_] =~ s/[=+&]//gr) =~ /^(r|rm|q)$/ } 0 .. $#$oc;
        my $t = defined $first ? tword_int($ops->[$first]) : '';
        $asm_size = $t =~ /^(long|u64|i64|address)$/ ? 'q' : $t =~ /^(int|u32|i32)$/ ? 'l' : undef;
    }
    # each operand: what it is, and the register it wants (x86's a, d ...)
    my (@want, $ret, @code, @after, %text, $second);
    # (x86_64's x operands of a float or a double in a template that has
    # instructions, libm's fma: each in an xmm register of its own, xmm0
    # up, loaded from its address and an output stored there after; an
    # input in an output's place, "0", loaded into the output's)
    my (%xreg, $xn);
    for my $i (0 .. $#$ops) {
        my $out = $i < @$oc;
        my $c = $out ? $oc->[$i] : $ic->[$i - @$oc];
        (my $k = $c) =~ s/[=+&]//g;
        # (x86_64: % marks an operand commutative with the next, which says
        # nothing here; an input that may be a register, memory or an
        # immediate is in a register: libgcc's sfp-machine.h, "rme")
        $k =~ s/%//g if $target eq 'x86_64';
        $k = 'r' if ($k eq 'rm' || $k eq 'g' || $k eq 'rme' || $k eq 're' || $k eq 'rmi' || $k eq 'ri') && $target eq 'x86_64';
        if ($target eq 'x86_64' && $template =~ /\S/ && ($k =~ /^xm?$/ || ($k =~ /^\d$/ && !$out && $xreg{$k}))) {
            stop("the asm constraint $c", $n) if $c =~ /\+/;
            my $t = tword($ops->[$i]);
            my $w = $t eq 'float' ? 's' : $t eq 'double' ? 'd' : stop("the asm operand $c of a $t", $n);
            $xreg{$i} = $k =~ /^\d$/ ? $xreg{$k} : ['xmm' . ($xn++ // 0), $w];
            $text{$i} = $xreg{$i}[0];
            push @want, [$i, $out ? 'xout' : 'xin'];
            next;
        }
        if ($out && $fixed{$k}) {
            # an output in a fixed register: stored through its address after
            stop("the asm constraint $c", $n) if $c =~ /\+/;
            push @want, [$i, 'address'];
            $text{$i} = $fixed{$k};
        } elsif ($out && ($k eq 'r' || ($k eq 'x' && $target eq 'x86_64'))) {
            # the register output: the function's value (+: it goes in first, as an argument)
            # (x86_64: a second one in r11, stored through its address after,
            # as an output in a fixed register: libgcc's soft-fp, add and
            # adc of two words)
            if (defined $ret && $target eq 'x86_64' && $c !~ /\+/ && !$second++) {
                push @want, [$i, 'address'];
                $text{$i} = 'r11';
                next;
            }
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
    # (aarch64's FP/SIMD operands come in v0, v1 ... by AAPCS64, counted
    # apart from the x registers: after the others, from 100 on here)
    my ($next, $fpn) = (0, 0);
    for my $w (@want) { next if defined $w->[3] || ($target eq 'aarch64' && ($w->[2] // '') eq 'w'); $next++ while $taken{$next}; $w->[3] = $next; $taken{$next++} = 1 }
    for my $w (@want) { next if defined $w->[3]; $w->[3] = 100 + $fpn++ }
    stop('an asm statement with too many operands', $n) if grep { $_->[3] > $#$regs && $_->[3] < 100 } @want or $fpn > 8;
    my @arg;
    my @scratch = $second ? qw(r10) : qw(r10 r11);
    for my $w (sort { $a->[3] <=> $b->[3] } @want) {
        my ($i, $how, $r, $j) = @$w;
        my $a = $j < 100 ? $regs->[$j] : undef;
        $arg[$j] = [$i, $how eq 'value' ? 'value' : 'address'];
        if ($how =~ /^x(in|out)$/) {
            my ($x, $w) = @{ $xreg{$i} };
            push @code, node("movs$w.n.m0", node(0), node($a), node($x)) if $how eq 'xin';
            push @after, node("movs$w.n.m0r", node($x), node(0), node($a)) if $how eq 'xout';
        } elsif ($how eq 'address') {
            stop("the asm output $oc->[$i]", $n) unless $target eq 'x86_64';
            # stored by its C type's size (cpuid's are 32 bits); an address
            # in a register the instructions write (cpuid's rcx, rdx) is
            # kept in r10 or r11 until then
            my $t = tword_int($ops->[$i]);
            my $s = $t =~ /^(int|u32|i32)$/ ? 'l' : $t =~ /^(long|u64|i64)$/ || $t =~ /\b(address|pointer)$/ ? 'q' : stop("the asm output $oc->[$i] of a $t", $n);
            if (grep { $_ eq $a } values %text) {
                my $k = shift @scratch // stop('an asm statement with too many outputs', $n);
                unshift @code, node('movq', node($a), node($k));
                $a = $k;
            }
            push @after, node("mov$s.mr", node($text{$i}), node(0), node($a));
        } elsif ($how eq 'mem') {
            $text{$i} = $target eq 'x86_64' ? "0(%$a)" : "[$a]";
        } elsif (defined $r && $r eq 'w') {
            # aarch64's FP/SIMD operand, a float or a double, from its
            # argument's register (s or d k, AAPCS64's), to s or d 16 + k
            my $t = tword($ops->[$i]);
            stop("the asm operand w of a $t", $n) unless $t eq 'float' || $t eq 'double';
            my $k = $j - 100;
            my ($p, $v) = ($t eq 'float' ? 's' : 'd', 16 + $k);
            push @code, node("fmov.$p", node("$p$k"), node("$p$v"));
            $text{$i} = "$p$v";
        } elsif (defined $r && $r ne $a) {
            push @code, $target eq 'aarch64' ? node('orr', node($a), node('xzr'), node($r)) : node('movq', node($a), node($r));
        } else {
            $text{$i} //= $a;
        }
    }
    # (an argument register no operand takes, before one that is taken:
    # xgetbv's "c" (0) is the fourth, rcx, after two outputs, a 0 between)
    my ($lastarg) = grep { defined $arg[$_] } reverse 0 .. ($#arg < 99 ? $#arg : 99);
    $arg[$_] //= ['zero'] for 0 .. ($lastarg // -1);
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
    # (gcc's %% for a register or segment's own %: x86's %%fs)
    $t =~ s/%%/%/g;
    push @code, map { my ($op, @a) = split /[\s,]+/; asm_ins_other($n, $op, @a) } grep { /\S/ } map { s/^\s+|\s+$//gr } split /;/, $t;
    push @code, @after;
    (my $name = "__asm_$template") =~ s/[^A-Za-z0-9]+/_/g;
    $name .= '_' . join('', map { s/[^A-Za-z0-9]//gr } @$oc) . '_' . join('', map { s/[^A-Za-z0-9]//gr } @$ic);
    $name = asm_once($name, "$template : @$oc : @$ic", $n);
    push @out, [$cur_unit, node("$name:", node('asm'), node('comment', node("glibc's asm statement \"$template\"")), @code, node('ret'))]
        unless $asmfn{$name}++;
    my @args = map { my ($i, $how) = @$_; $i eq 'zero' ? node(0) : $how eq 'address' ? node('address', atom($ops->[$i])) : atom($ops->[$i]) } @arg;
    my $call = @args ? node($name, @args) : node($name);
    return defined $ret ? (item(expr($ops->[$ret])), node('='), $call) : $call;
}

sub expr {
    my ($n) = @_;
    my $k = $n->{kind};
    softfp($n);
    if ($in_global && $target ne 'arm' && $k =~ /^(BinaryOperator|UnaryOperator|CStyleCastExpr|ImplicitCastExpr)$/
        && FFold::fty(tword($n)) && FFold::ldinside($n) && (my $v = FFold::fold($n))) {
        my @f = femit($v, tword($n));
        return @f if @f;
    }
    # GNU's &&L, the address of a label of the function
    return node('address', node(label_name($label{ $n->{labelDeclId} } // stop('the address of no label', $n)))) if $k eq 'AddrLabelExpr';
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
    # on arm, where a long long is a pair of registers and a word is not, the
    # conversion of a narrower integer to it too (ttpc keeps a word's value in
    # one register, without the high word a pair needs)
    if ($target eq 'arm' && $k eq 'ImplicitCastExpr' && ($n->{castKind} // '') eq 'IntegralCast') {
        my @to = ctype(qt($n));
        my @from = ctype(qt((kids($n))[0]));
        return cast_node(\@to, item(expr((kids($n))[0]))) if "@to" =~ /^[iu]64$/ && "@from" !~ /^[iu]64$/;
    }
    if ($k eq 'ImplicitCastExpr' && ($n->{castKind} // '') =~ /^(IntegralToFloating|FloatingToIntegral|FloatingCast)$/) {
        # (in a global's value, a float or double literal made long double is
        # the long double literal of its value, which binary128 holds
        # exactly: ttpc has no conversion to run there, libm's zero = 0.0)
        my $e = strip((kids($n))[0]);
        if ($in_global && defined(my $lit = special_float((kids($n))[0], $n))) { return node($lit) }
        if ($in_global && isld($n) && $e->{kind} eq 'FloatingLiteral' && (my $t = tword($e)) =~ /^(float|double)$/) {
            return node($target eq 'arm' || $t eq 'double' ? ldround($e->{value}, 53, -1074, 1023) : ldround($e->{value}, 24, -149, 127));
        }
        if ($in_global && defined(my $lit = narrowlit($n, $e))) { return node($lit) }
        return cast_node([ctype(qt($n))], item(expr((kids($n))[0])));
    }
    # C's conversion to _Bool (in ff a u8) gives 0 or 1: the value compared
    # with 0 (the low byte of the value would be has_zero_eq's mask, 0 for a
    # zero byte above the first). long double has no literal of its own: 0, a
    # double, converts
    if ($k =~ /^(ImplicitCastExpr|CStyleCastExpr)$/ && ($n->{castKind} // '') =~ /^(Integral|Pointer|Floating)ToBoolean$/) {
        my ($e) = kids($n);
        my $zero = $1 ne 'Floating' ? 0 : isld($e) ? ldhexfloat('0') : hexfloat(0, qt($e));
        return node(':', operand($e, $prec{'!='}, 0), node('!='), node($zero));
    }
    return expr((kids($n))[0]) if $k =~ /^(ImplicitCastExpr|ConstantExpr|FullExpr|ExprWithCleanups)$/;
    return node(':', expr((kids($n))[0])) if $k eq 'ParenExpr';
    if ($k eq 'IntegerLiteral') {
        # a literal keeps its type: an int is a plain number, C's suffixes
        # (2UL) their word and then the number, another type a cast
        my $c = qt($n) =~ s/^\s+|\s+$//gr;
        my %suffix = ('unsigned int' => 'U', 'long' => 'L', 'unsigned long' => 'UL', 'long long' => 'LL', 'unsigned long long' => 'ULL');
        return node($suffix{$c}, node($n->{value})) if $suffix{$c};
        my @t = ctype(qt($n));
        return @t == 1 && $t[0] ne 'int' ? node($t[0], node($n->{value})) : node($n->{value});
    }
    # C23's true and false (libgcc's C, gnu23), clang's C++ bool literal: 1 and 0
    return node($n->{value} ? 1 : 0) if $k eq 'CXXBoolLiteralExpr';
    # (a char literal is an int: '\xff' where char is signed, x86_64's, is -1,
    # which clang's JSON has as 4294967295)
    return node($n->{value} >= 2**31 && qt($n) eq 'int' ? $n->{value} - 2**32 : $n->{value}) if $k eq 'CharacterLiteral';
    # GNU C's __builtin_types_compatible_p (strfromd's float or double): a
    # constant, 1 where the two types are one (their qualifiers aside), as
    # gcc answers it
    if ($k eq 'TypeTraitExpr') {
        my @t = kids($n);
        @t == 2 && ($n->{type}{qualType} // '') eq 'int' or stop('TypeTraitExpr', $n);
        return node(types_compatible(@t) ? 1 : 0);
    }
    # a long double literal: its exact hex float, with C's L (binary128,
    # rounded from clang's decimal as C rounds it)
    return node(ldhexfloat($n->{value})) if $k eq 'FloatingLiteral' && isld($n);
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
        if ($d->{kind} eq 'EnumConstantDecl') {
            # (kept, to be named with its unit where a global has its name: enum_rename)
            my $r = node(ffname($d->{name}));
            push @{ $enumref{ $d->{name} } }, $r;
            $enumunit{ $d->{name} } //= $cur_unit;
            return $r;
        }
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
        # (a size_t: arm's a u32)
        return node('cast:', node($target eq 'arm' ? 'u32' : 'u64'),
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
            # (or a constant: random.c's &randtbl[SEP_3 + 1], &randtbl[sizeof
            # (randtbl) / sizeof (randtbl[0])], which ttpc works out only as a
            # number)
            my $x = strip($i);
            my $c = int_const($i);
            my @i = $x->{kind} eq 'DeclRefExpr' && $x->{referencedDecl}{kind} eq 'EnumConstantDecl' && defined $enumval{ $x->{referencedDecl}{name} }
                ? node($enumval{ $x->{referencedDecl}{name} }) : defined $c ? node($c) : item(expr($i));
            return node(':', expr($b), node('+'), @i) if strip($b)->{kind} eq 'DeclRefExpr';
        }
        return node('address', expr($e)) if $op eq '&';
        return (node($op), atom($e)) if $op eq '-' || $op eq '!' || $op eq '~';
        return $n->{isPostfix} ? (atom($e), node($op)) : (node($op), atom($e)) if $op eq '++' || $op eq '--';
        return expr($e) if $op eq '+';
        return expr($e) if $op eq '__extension__';     # only quiets gcc's -pedantic
        # a complex value's parts: real / z, imag / z
        return node('real', item(expr($e))) if $op eq '__real';
        return node('imag', item(expr($e))) if $op eq '__imag';
        stop("the operator $op", $n);
    }
    if ($k eq 'CStyleCastExpr') {
        if ($in_global && defined(my $lit = narrowlit($n, strip((kids($n))[0])))) { return node($lit) }
        return cast_node([ctype(qt($n))], item(expr((kids($n))[0])));
    }
    # C11's _Generic: generic / x / an association per type (its type words
    # and a colon, holding its value) / default:; ttpc picks the one of x's
    # type (clang's inner: x, x's type, then the associations)
    if ($k eq 'GenericSelectionExpr') {
        my ($x, @as) = grep { $_->{kind} || exists $_->{associationKind} } kids($n);
        my @a;
        for my $as (grep { exists $_->{associationKind} } @as) {
            my @in = kids($as);
            if ($as->{associationKind} eq 'default') { push @a, node('default:', expr($in[-1])); next }
            my $t = $in[0]{type} or stop("an association without a type", $n);
            push @a, node(join(' ', ctype($t->{desugaredQualType} // $t->{qualType})) . ':', expr($in[-1]));
        }
        return node('generic', atom($x), @a);
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
                # (an element that is a record: an index other than a number
                # in a : of its own, as a name there that is one of its
                # fields would be read as that field, p x: arc4random-fork's
                # indexes[run * processes + process_index] of struct index's
                # run)
                my @ix = item(expr($i));
                @ix = node(':', @ix) if (@ix > 1 || $ix[0]{content} !~ /^\d/) && $ix[0]{content} ne ':'
                    && ($base->{type}{desugaredQualType} // $base->{type}{qualType} // '') =~ /^(?:const |volatile )*(?:struct|union) /;
                unshift @path, @ix;
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
            # (a value of several nodes, x - 1, is a : of them: aarch64's
            # THREAD_SELF, ((struct pthread *) tp - 1)->tid)
            @b = node(':', @b) if @b > 1;
            push @{ $b[0]{children} }, node('.'), @path;
            return @b;
        }
        if ($k eq 'ArraySubscriptExpr' && $base == $n) {
            my ($b, $i) = kids($n);
            # (an index of several nodes in a : of its own: p[a - b] is p + (a - b), not
            # (p + a) - b, whose pointer arithmetic is another: memstream's
            # (*mp->bufloc)[fp->_IO_write_ptr - fp->_IO_write_base])
            return node('content', node(':', expr($b), node('+'), atom($i)));
        }
        stop('a path from ' . $base->{kind}, $n);
    }
    if ($k eq 'CallExpr') {
        my ($callee, @args) = kids($n);
        my $c = strip($callee);
        # (*f) (...) calls what f points at, as f (...) does; a _Generic's
        # call is of the association clang selected (tst-scanf-format-real.h's
        # _Generic (v, float: strtof, ...) (s, &e))
        while (1) {
            $c = strip((kids($c))[0]) while $c->{kind} eq 'ParenExpr' || ($c->{kind} eq 'UnaryOperator' && $c->{opcode} eq '*');
            last unless $c->{kind} eq 'GenericSelectionExpr';
            my ($as) = grep { $_->{selected} } kids($c) or stop('a _Generic with no association selected', $n);
            $c = strip((kids($as))[-1]);
        }
        if ($c->{kind} =~ /^(MemberExpr|ArraySubscriptExpr)$/) {
            # through a function pointer at the end of a path: p / fn / x is
            # p->fn (x), its arguments after the path's fields and indexes
            my @p = expr($c);
            @p == 1 && @{ $p[0]{children} } or stop('a call through a path that is not one node', $n);
            # (without arguments, a . after the path: the field alone is its value)
            push @{ $p[0]{children} }, @args ? map { arg($_) } @args : node('.');
            return @p;
        }
        if ($c->{kind} =~ /^(CStyleCastExpr|ConditionalOperator|CallExpr|BinaryOperator)$/) {
            # through a function pointer that is a value, not a variable (dl-fini's
            # ((fini_t) array[i]) (), backtrace's ((void) x, &_Unwind_Backtrace)
            # (...)): the value, a ., then the arguments
            my @p = expr($c);
            @p = node(':', @p) if @p > 1;    # (a conditional, an operator's)
            @p == 1 or stop('a call through ' . $c->{kind} . ' of several nodes', $n);
            push @{ $p[0]{children} }, node('.'), map { arg($_) } @args;
            return @p;
        }
        $c->{kind} eq 'DeclRefExpr' or stop('a call through ' . $c->{kind}, $n);
        return cast_node(['void'], node('0')) if $errorfn{"$cur_unit $c->{referencedDecl}{id}"};
        my $name = $c->{referencedDecl}{name};
        # (its value a long, as its first argument is made one)
        return cast_node([ctype(qt($n))], item(expr($args[0]))) if $name eq '__builtin_expect';
        return expr(tgmath($n, @args)) if $name eq '__builtin_tgmath';
        # (in a global's value, gcc's infinity or NaN is its literal, as gcc
        # folds it: ttpc's global items call nothing)
        if ($in_global && defined(my $lit = special_float($n, $n))) { return node($lit) }
        if ($name eq '__builtin_constant_p') {
            # gcc's answer where it cannot tell is 0, and code that asks must
            # mean the same either way: 1 for a literal, else 0
            return node(strip($args[0])->{kind} =~ /^(IntegerLiteral|CharacterLiteral)$/ ? 1 : 0);
        }
        # __builtin_mempcpy (d, s, n) is memcpy (d, s, n) + n, as gcc always
        # makes it (no glibc object calls mempcpy for it): a call of the
        # unit's memcpy (dl-tls's, before the ifuncs are resolved, is
        # __memcpy_generic). n is taken twice, so it must have no effects.
        if ($name eq '__builtin_mempcpy') {
            @args == 3 or stop('__builtin_mempcpy without 3 arguments', $n);
            pure($args[2]) or stop('__builtin_mempcpy of a count with effects', $n);
            my $mc = own('memcpy');
            want($mc);
            return cast_node(['address', 'void'], node(':', cast_node(['address', 'u8'],
                node(ffname($mc), map { arg($_) } @args)), node('+'), atom($args[2])));
        }
        # a builtin of a libc function is a call of it, as gcc makes one
        # where it does not expand the builtin
        $name = $1 if $name =~ /^__builtin_((?:mem|str|stp)\w+|free|malloc)$/;
        # and the other way: a libm function gcc always expands, as its
        # builtin (s_scalbn's copysign, which libc.a has no function of)
        $name = "__builtin_$name" if $name =~ /^(?:copysign|fabs)[fl]?$/;
        # (x86_64's _Float128 builtins and copysignf128 / fabsf128: ttpc's
        # long double is binary128, _Float128 is long double in ff)
        $name =~ s/^(?:__builtin_)?(copysign|fabs)f128$/__builtin_$1l/;
        $name =~ s/^(__builtin_(?:huge_val|inf|nan|nans|signbit))f128$/$1l/;
        # gcc's alloca: ttpc's, C on the shared page, which the function gives
        # back when it returns
        return node('alloca', map { arg($_) } @args) if $name eq '__builtin_alloca';
        # gcc's type-generic overflow builtins: one function in builtins.ff.txt
        # for each set of operand types glibc uses, named for them
        # (__builtin_add_overflow u32 u32 u32)
        if ($name =~ /^__builtin_(add|sub|mul)_overflow$/) {
            my @t = map { tword_int($_) } @args;
            my $sig = "@t" =~ /^(\S+) (\S+) address (\S+)$/ ? "$1 $2 $3" : '';
            $ovf{"$name $sig"} || ($target eq 'arm' && $ovf_arm{"$name $sig"}) or stop("$name on @t", $n);
            return node("$name $sig", map { arg($_) } @args);
        }
        # gcc's type-generic float classification, in builtins.ff.txt, one
        # function for each floating type (printf_fp has double and long double)
        # (and C's classification and quiet comparisons, a function for each
        # of the three types; fpclassify's type is its last argument's)
        if ($name =~ /^__builtin_(isnan|isinf_sign|isinf|signbit|isfinite|isunordered|isless|islessequal|isgreater|isgreaterequal|fpclassify)$/) {
            my $t = tword_int($name eq '__builtin_fpclassify' ? $args[-1] : $args[0]);
            $t =~ /^(float|double|long double)$/ or stop("$name on $t", $n);
            return node("$name $t", map { arg($_) } @args);
        }
        # C's va_ words, as clang has them
        return node('va_start', item(expr($args[0]))) if $name eq '__builtin_va_start' || $name eq '__builtin_c23_va_start';
        return node('va_end', item(expr($args[0]))) if $name eq '__builtin_va_end';
        return node('va_copy', item(expr($args[0])), item(expr($args[1]))) if $name eq '__builtin_va_copy';
        # GNU C's passing on of a variadic function's own extra arguments
        return node('va_arg_pack') if $name eq '__builtin_va_arg_pack';
        return node('va_arg_pack_len') if $name eq '__builtin_va_arg_pack_len';
        # the builtins glibc in ff has by hand (src/glibc/builtins.ff.txt)
        # C23's bit functions, gcc's type-generic __builtin_stdc_*: one of
        # stdbit.ff.txt for each width, named for the first argument's type
        # (clang's overload of it, clang-prelude.h's; a unit whose pass was
        # made with one of a word has the argument's conversion to it: the
        # type under that)
        if ($name =~ /^__builtin_stdc_(leading|trailing|first_leading|first_trailing|count)_(zeros?|ones?)$|^__builtin_stdc_(has_single_bit|bit_width|bit_floor|bit_ceil|rotate_left|rotate_right)$/) {
            my $a = $args[0];
            $a = (kids($a))[0] while ($a->{kind} // '') eq 'ImplicitCastExpr' && ($a->{castKind} // '') eq 'IntegralCast';
            my $w = tword_int($a);
            $w =~ /^u(8|16|32|64)$/ or stop("$name on $w", $n);
            return node("$name $w", map { arg($_) } @args);
        }
        # (arm's __builtin_add_overflow_p on its words, unsigned ints)
        return node("$name u32", map { arg($_) } @args) if $name eq '__builtin_add_overflow_p' && $target eq 'arm';
        return node($name, map { arg($_) } @args) if $name =~ /^__builtin_(unreachable|trap|return_address|frame_address|extract_return_addr|clz|clzl|clzll|ctz|ctzl|ctzll|popcount|popcountl|popcountll|bswap16|bswap32|bswap64|add_overflow|mul_overflow|add_overflow_p|mul_overflow_p|thread_pointer|fabsf?|fabsl|copysignf?|copysignl|signbitf|signbitl|inff|huge_valf?|huge_vall|nanf?|nanl|fmaf?|sqrtf?|ffs|ffsl|ffsll)$/ || $name eq '__atomic_always_lock_free';
        # and those of one target (builtins-<target>.ff.txt)
        # (riscv64's for libgcc's unwinder, unwind-dw2.c: its frame and registers)
        # (and x86_64's: its shadow stack's too, which libgcc's unwinder reads, and the cache's)
        return node($name, map { arg($_) } @args) if $name =~ /^__builtin_(unwind_init|dwarf_cfa|dwarf_sp_column|eh_return|eh_return_data_regno|frob_return_addr|init_dwarf_reg_size_table)$/ && $target =~ /^(?:riscv64|x86_64)$/;
        return node($name, map { arg($_) } @args) if $name =~ /^__builtin_(?:ia32_rdsspq|ia32_incsspq|__clear_cache)$/ && $target eq 'x86_64';
        return node($name) if $name eq '__builtin_aarch64_get_fpcr' && $target eq 'aarch64' && !@args;
        return node($name) if $name =~ /^__builtin_ia32_(rdtsc|pause|xbegin|xend|xtest)$/ && $target eq 'x86_64' && !@args;
        return node($name, map { arg($_) } @args) if $name =~ /^__builtin_ia32_(pmovmskb128|pshufb128)$/ && $target eq 'x86_64';
        # gcc's _mm_cmpistri, _mm_cmpistrc, _mm_cmpistrz (<smmintrin.h>, whose
        # bodies clangvec.pl leaves out): the builtin of its immediate, a
        # function of builtins-x86_64.ff.txt for each (pcmpistri $imm)
        if ($name =~ /^_mm_cmpistr([icz])$/ && $target eq 'x86_64' && @args == 3) {
            my $imm = int_const($args[2]);
            defined $imm or stop("$name of an immediate that is no constant", $n);
            return node(sprintf('__builtin_ia32_pcmpistr%s128 0x%x', { i => 'i', c => 'ic', z => 'iz' }->{$1}, $imm), map { arg($_) } @args[0, 1]);
        }
        stop("the builtin $name", $n) if $name =~ /^__builtin_/;
        $name = own($name) if $c->{referencedDecl}{kind} eq 'FunctionDecl';
        want($name) if $c->{referencedDecl}{kind} eq 'FunctionDecl' && $name !~ /^__builtin_/;
        # a call through a variable without arguments: a . after it (the
        # variable alone is its value; pthread_once's init_routine (), the
        # atexit functions of exit)
        if ($c->{referencedDecl}{kind} ne 'FunctionDecl' && !@args) { my ($v) = expr($c); push @{ $v->{children} }, node('.'); return $v }
        # (through a function's static, its name as a global: tst-strerror-fail's
        # original_malloc)
        my $sn = $c->{referencedDecl}{kind} eq 'VarDecl' && $staticname{"$cur_unit $c->{referencedDecl}{id}"};
        return node($sn || ffname($name), map { arg($_) } @args);
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
        # (one of constants that holds an anonymous union, arm's mutex
        # initializer _RTLD_LOCK_RECURSIVE_INITIALIZER, whose __spins and
        # __list ttpc takes in a global's items, not in a temporary's: a
        # global of its own, the value copied from it)
        if ($cur_fn ne '' && anon_union_init((kids($n))[0]) && const_init((kids($n))[0])) {
            my $g = ffname($cur_fn) . ' literal ' . ++$literals{$cur_fn};
            push @out, [$cur_unit, decl({ kind => 'VarDecl', type => $n->{type}, inner => [kids($n)] }, 1, $g)];
            return node($g);
        }
        my @t = ctype(qt($n));
        # of an array (popen's (char *const[]){ "sh", "-c", ... }): as a typed
        # literal, the type's first word on top, the rest of the type and then
        # the items under it
        return node('array', map({ node($_) } @t[1 .. $#t]), init((kids($n))[0])) if $t[0] eq 'array';
        # (and of a vector, _mm_set_epi8's (__v16qi){ ... }: as an array's)
        return node('vector', map({ node($_) } @t[1 .. $#t]), init((kids($n))[0])) if $t[0] eq 'vector';
        @t == 1 && (!$scalar_word{$t[0]} || $t[0] ne 'address' && $t[0] ne 'array') or stop('a compound literal of ' . qt($n), $n);
        # (one of a scalar type is a typed literal, u32 / 0; ttpc gives
        # address / u32 / 0 a temporary, C's &(unsigned int){0})
        # (an empty one, C23's and GNU's {}, is {0}: support_blob_repeat_free's
        # *blob = (struct support_blob_repeat) {})
        my @i = init((kids($n))[0]);
        return node($t[0], @i ? @i : node('0'));
    }
    if ($k eq 'UnaryExprOrTypeTraitExpr') {
        my $w = $n->{name};
        my $t = $n->{argType} ? ($n->{argType}{desugaredQualType} // $n->{argType}{qualType}) : qt((kids($n))[0]);
        $w = 'alignof' if $w eq '__alignof' || $w eq '_Alignof';   # GNU's and C11's spellings, one on riscv64
        # of a variable-length array (gmon's sizeof (buf)): of the variable,
        # whose size ttpc keeps from its declaration
        if (!$n->{argType} && $w eq 'sizeof' && $t =~ /\[[^\[\]]*[A-Za-z_][^\[\]]*\]$/) {
            my $v = strip((kids($n))[0]);
            $v = strip((kids($v))[0]) while $v->{kind} eq 'ParenExpr';
            return node('sizeof', expr($v)) if $v->{kind} eq 'DeclRefExpr';
        }
        return node($w, map { node($_) } ctype($t)) if $w eq 'sizeof' || $w eq 'alignof';
        stop("the trait $w", $n);
    }
    stop($k, $n);
}

# Whether an initializer list holds one of an anonymous union, and whether
# all its items are constants (numbers, enum constants, zeros).
sub anon_union_init {
    my ($n) = @_;
    return 0 unless ($n->{kind} // '') eq 'InitListExpr';
    return 1 if qt($n) =~ /^union .*\((?:unnamed|anonymous)\b/;
    grep { anon_union_init($_) } kids($n);
}
sub const_init {
    my ($n) = @_;
    my $k = $n->{kind} // '';
    return !grep { !const_init($_) } kids($n) if $k eq 'InitListExpr';
    return 1 if $k eq 'ImplicitValueInitExpr' || defined int_const($n);
    my $s = strip($n);
    ($s->{kind} // '') eq 'DeclRefExpr' && ($s->{referencedDecl}{kind} // '') eq 'EnumConstantDecl';
}

# The call of libatomic's function for an atomic builtin
# The value of an integer constant expression (literals, parentheses, casts,
# + - * & | ^ << >> ~ and unary -), or undef.
sub int_const {
    my ($n) = @_;
    my $k = $n->{kind} // '';
    return $n->{value} if $k =~ /^(IntegerLiteral|ConstantExpr)$/ && defined $n->{value} && $n->{value} =~ /^-?\d+$/;
    return int_const((kids($n))[0]) if $k =~ /^(ParenExpr|ImplicitCastExpr|CStyleCastExpr|ConstantExpr)$/;
    if ($k eq 'UnaryOperator') {
        my $v = int_const((kids($n))[0]) // return;
        $v += 0;
        return $n->{opcode} eq '-' ? -$v : $n->{opcode} eq '~' ? ~$v : $n->{opcode} eq '+' ? $v : undef;
    }
    # sizeof of a scalar, or of an array of scalars
    if ($k eq 'UnaryExprOrTypeTraitExpr' && ($n->{name} // '') eq 'sizeof') {
        my $t = $n->{argType} ? ($n->{argType}{desugaredQualType} // $n->{argType}{qualType}) : (kids($n))[0] ? qt((kids($n))[0]) : undef;
        defined $t or return;
        $t =~ s/\b(const|volatile)\b//g;
        $t = trim($t);
        my $count = $t =~ s/\s*\[(\d+)\]$// ? $1 : 1;
        my $z = eval { csize($t) } // return;
        return $count * $z;
    }
    if ($k eq 'BinaryOperator') {
        # (as numbers: | on two strings, as JSON has them, is a string's)
        my ($a, $b) = map { int_const($_) } kids($n);
        return unless defined $a && defined $b;
        ($a, $b) = ($a + 0, $b + 0);
        use integer;
        my $o = $n->{opcode};
        return $o eq '|' ? $a | $b : $o eq '&' ? $a & $b : $o eq '^' ? $a ^ $b : $o eq '+' ? $a + $b : $o eq '-' ? $a - $b
            : $o eq '*' ? $a * $b : $o eq '<<' ? $a << $b : $o eq '>>' ? $a >> $b : $o eq '/' && $b ? $a / $b : undef;
    }
    undef;
}
# Two types of a type trait, one type: their canonical spellings, without
# qualifiers, the same
sub types_compatible {
    my @t = map { my $q = $_->{type}{desugaredQualType} // $_->{type}{qualType} // ''; $q =~ s/\b(const|volatile|restrict)\b//g; $q =~ s/\s+/ /g; trim($q) } @_;
    $t[0] ne '' && $t[0] eq $t[1];
}
sub atomic_call {
    {
        my ($n, $a, $p, $o, @v) = @_;
        return node("__atomic_exchange_" . csize(qt($n)), item(expr($p)), item(expr($v[0])), item(expr($o))) if $a eq '__atomic_exchange_n';
        return node("__atomic_load_" . csize(qt($n)), item(expr($p)), item(expr($o))) if $a eq '__atomic_load_n';
        return node("__atomic_store_" . csize(qt($v[0])), item(expr($p)), item(expr($v[0])), item(expr($o))) if $a eq '__atomic_store_n';
        # gcc's generic __atomic_load (p, ret, o) and __atomic_store (p, val,
        # o), of a value of any type (libgcc's btree, a struct of bit
        # fields): libatomic's generic function, with the size of *p first
        # (builtins.ff.txt's)
        if ($a eq '__atomic_load' || $a eq '__atomic_store') {
            (my $t = qt($p)) =~ s/\s*\*\s*$// or stop("$a of no pointer", $n);
            return node($a, node('sizeof', map { node($_) } ctype($t)), item(expr($p)), item(expr($v[0])), item(expr($o)));
        }
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
# A long double literal from clang's decimal: binary128's exact hex float,
# 0x1.<28 hex digits at most>p<e>L (a subnormal 0x0.<digits>p-16382L, zero
# 0x0p+0L), the nearest value, ties to even, as C rounds a literal.
use Math::BigInt;
sub ldhexfloat {
    my ($s) = @_;
    # (where long double is double, arm's EABI: the double nearest, written
    # as the same hex float, which binary128 holds exactly)
    if ($target eq 'arm') {
        my $d = ldround($s, 53, -1074, 1023);
        return defined $d ? $d : die "c2ff: a long double literal past a double: $s\n";
    }
    ldround($s, 113, -16494, 16383) // die "c2ff: a long double literal past the largest: $s\n";
}
# (ldround, ratq, qlit: FFold.pm's)
# (in a global's value, a long double literal made double or float is the
# literal of its value rounded to that type, as gcc folds it: glibc's
# DBL_MIN is ((double) 2.2250738585072014e-308L), tst-strtod-underflow's
# volatile double d = DBL_MIN; ttpc would convert it by soft-fp's
# __trunctfdf2, which compile time has no code of)
sub narrowlit {
    my ($n, $e) = @_;
    return undef unless $e->{kind} eq 'FloatingLiteral' && isld($e) && $target ne 'arm';
    my $to = tword($n);
    my $l = $to eq 'double' ? ldround($e->{value}, 53, -1074, 1023) : $to eq 'float' ? ldround($e->{value}, 24, -149, 127) : undef;
    return undef unless defined $l;
    $l =~ s/L$/$to eq 'float' ? 'f' : ''/e;
    $l;
}
# A global's value of floating constants that involves long double (riscv64,
# x86_64, aarch64: soft-fp, whose functions compile time has no code of)
# worked out here, as gcc folds it (FFold.pm's fold: strtod's and strfrom's
# tests' INFINITY + 0.0L, -NAN + 0.0L), written as the literal of its type
# (- before it where it is negative)
sub femit {
    my ($v, $t) = @_;
    my (undef, undef, $emax, $suf, $sp) = @{ FFold::fty($t) };
    my $l = $v->{k} eq 'nan' ? "0x1.8p+$sp" : $v->{k} eq 'inf' ? "0x1p+$sp"
        : $v->{q}->is_zero ? "0x0p+0$suf" : (qlit($v->{q}, $v->{e}, $emax) // return) =~ s/L$/$suf/r;
    $v->{neg} ? node(':', node('-'), node($l)) : node($l);
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
# reserves), holds a NUL (which a node's text cannot), bytes that are not UTF-8
# (tst-sprintf's, tst-grouping_iterator's) or is longer than a
# node's 255 bytes (a __PRETTY_FUNCTION__: a value is one text) is a global
# char array of its own, text 1, 2, ..., and the value the address of its
# first char.
my $ntext = 0;
my %text_item;
# cast: type value; under address / char (or u8) a leaf is a text, so a leaf
# value goes in a : (printf-parse's (const char *) format)
# an expression without effects: names, members, constants, and what C
# makes of them without calls, assignments or ++
sub pure {
    my ($n) = @_;
    my $k = $n->{kind} // '';
    return 0 if $k =~ /^(CallExpr|CompoundAssignOperator|StmtExpr)$/;
    return 0 if $k eq 'BinaryOperator' && ($n->{opcode} // '') eq '=';
    return 0 if $k eq 'UnaryOperator' && ($n->{opcode} // '') =~ /^(\+\+|--)$/;
    !grep { !pure($_) } kids($n);
}
sub cast_node {
    my ($t, @v) = @_;
    # (a value of one node that is a leaf in the words of now: content x
    # and address x become x * pointer, x & address, whose x would be text)
    @v = node(':', @v) if "@$t" =~ /^address (char|u8)$/ && @v == 1 && (!@{ $v[0]{children} } || $v[0]{content} =~ /^(?:content|address)$/);
    node('cast:', map({ node($_) } @$t), @v);
}
sub string_value {
    my ($n) = @_;
    my $s = bytes($n);
    return node('address', node('char'), texts($n)) unless $isop{$s} || $s =~ /^(?:\?|:|\.|\.\.\.)$/ || $reserved{$s} || $s =~ /\0/ || length($s) > 255 || ($s ne '' && !pieces($s));
    # (one item per text and unit: glibc's tests name their variables as
    # texts, #ret, which x86_64 reserves, 360 times in tst-printf-intn)
    my $name = $text_item{"$cur_unit\0$s"} //= do {
        my $nm = 'text ' . ++$ntext;
        my @c = (unpack('C*', $s), 0);
        push @out, [$cur_unit, node("$nm:", node('array'), node('char'), node(scalar @c), grouped(252, map { node($_) } @c))];
        $nm;
    };
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
# gcc's infinity or NaN builtin of a constant (__builtin_huge_val, inf, nan
# (""): HUGE_VAL, INFINITY, NAN), as type t: the hex float one exponent
# past its range (the user's choice A, 2026-10-23): 0x1p+1024 infinity,
# 0x1.8p+1024 the quiet NaN (float 128f, long double 16384L), of the type
# of node t; else undef
sub special_float {
    my ($n, $t) = @_;
    my $s = $n;
    $s = (kids($s))[0] while ($s->{kind} // '') =~ /^(ImplicitCastExpr|ConstantExpr|ParenExpr)$/;
    return unless ($s->{kind} // '') eq 'CallExpr';
    my ($c, @args) = kids($s);
    $c = strip($c);
    my $name = ($c->{kind} // '') eq 'DeclRefExpr' ? $c->{referencedDecl}{name} // '' : '';
    my $nan = $name =~ /^__builtin_nan(?:[fl]|f128)?$/ ? 1 : $name =~ /^__builtin_(?:huge_val|inf)(?:[fl]|f128)?$/ ? 0 : return;
    if ($nan) {
        return if @args != 1;
        my $str = $args[0];
        $str = (kids($str))[0] while ($str->{kind} // '') =~ /^(ImplicitCastExpr|ParenExpr)$/;
        return if ($str->{kind} // '') ne 'StringLiteral' || ($str->{value} // '') ne '""';
    } else { return if @args }
    my $w = tword($t);
    my $e = $w eq 'float' ? '128f' : $w eq 'double' ? '1024' : $w eq 'long double' ? '16384L' : return;
    $nan ? "0x1.8p+$e" : "0x1p+$e";
}
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

# A label's name. C keeps labels apart from other names, ff does not: a
# label named as a tag, a typedef, a global or a function is written with
# a ' after it, as a name ff reserves is (__tzfile_compute's leap:, where
# struct leap is the type of leaps, whose fields a path then missed).
sub label_name {
    my ($name) = @_;
    my $f = ffname($name);
    return $f if $f =~ /'$/;
    $rec{"struct $name"} || $rec{"union $name"} || $enumd{"enum $name"} || exists $typedef{$name} || $var{$name} || $fn{$name} ? "$f'" : $f;
}
# The LabelStmts under a node.
sub labels { my ($n) = @_; (($n->{kind} // '') eq 'LabelStmt' ? $n : ()), map { labels($_) } kids($n) }
# Whether a node of that kind is under n.
sub holds { my ($n, $k) = @_; (($n->{kind} // '') eq $k) || grep { holds($_, $k) } kids($n) }
# The ParmVarDecls and VarDecls under a node (a function's own).
sub locals { my ($n) = @_; (($n->{kind} // '') =~ /^(ParmVarDecl|VarDecl)$/ ? $n : ()), map { locals($_) } kids($n) }

# glibc's INTERNAL_SYSCALL on riscv: register variables a7 = number, a0 ...
# = the arguments, the asm scall, the result from a0. On aarch64 x8 = the
# number, x0 ... the arguments (x0 given its value by an assignment after
# its declaration, _x0 = _x0tmp), the asm svc 0.
sub syscall_idiom {
    my ($cs) = @_;
    return syscall_idiom_x86($cs) if $target eq 'x86_64';
    return syscall_idiom_arm($cs) if $target eq 'arm';
    my ($nr, $ar) = $target eq 'aarch64' ? ('x8', 'x') : ('a7', 'a');
    my @st = kids($cs);
    my ($inner) = grep { $_->{kind} eq 'CompoundStmt' } @st;
    return () unless $inner && grep { $_->{kind} eq 'GCCAsmStmt' } kids($inner);
    my (%reg, %regof);
    for my $s (grep { $_->{kind} eq 'DeclStmt' } kids($inner)) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            next unless $lab;
            # glibc's macro names each variable after its register: __a7, __a0, ...
            # (aarch64: _x8, _x0, ...)
            my $reg = $lab->{label} // (($v->{name} // '') =~ /^(?:__(a[0-7])|_(x[0-8]))$/ ? $1 // $2 : undef);
            next unless defined $reg;
            $regof{ $v->{id} } = $reg;
            $reg{$reg} = $init if $init;
        }
    }
    # (a register variable's value by an assignment: aarch64's _x0 = _x0tmp)
    for my $s (grep { $_->{kind} eq 'BinaryOperator' && ($_->{opcode} // '') eq '=' } kids($inner)) {
        my ($l, $r) = kids($s);
        $l = strip($l);
        $reg{ $regof{ $l->{referencedDecl}{id} } } //= $r if $l->{kind} eq 'DeclRefExpr' && $regof{ $l->{referencedDecl}{id} // '' };
    }
    return () unless $reg{$nr};
    my %local;      # the _argN of the outer block, by name
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st, grep { $_->{kind} eq 'DeclStmt' } kids($inner)) {
        for my $v (kids($s)) { my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v); $local{ $v->{name} } = $init if $init && !$regof{ $v->{id} } }
    }
    my @args;
    for my $i (0 .. 5) {
        my $e = $reg{"$ar$i"} or last;
        my $s = strip($e);
        $e = $local{ $s->{referencedDecl}{name} } if $s->{kind} eq 'DeclRefExpr' && $local{ $s->{referencedDecl}{name} };
        push @args, item(expr($e));
    }
    node('syscall', item(expr($reg{$nr})), @args);
}
# a register variable's register (clang's AST has no label of an
# AsmLabelAttr: from the .i, asm ("r0") or "r0" where the attribute begins)
sub asm_label {
    my ($a) = @_;
    return $a->{label} if defined $a->{label};
    my $b = $a->{range}{begin}{offset} // $a->{range}{begin}{expansionLoc}{offset};
    return undef unless defined $b && $cur_unit;
    substr($cur_unit->{text}, $b, 80) =~ /^(?:(?:__asm__|__asm|asm)\s*\(\s*)?"(\w+)"/ ? $1 : undef;
}
# arm's (sysdeps/unix/sysv/linux/arm/sysdep.h): register variables r0 (or
# a1), a2 a3 a4 v1 v2 v3 (r1 ... r6) the arguments, r7 the number, each set
# by its declaration or by an assignment after it (from the _aNtmp before
# them), the asm swi 0x0 with the output "=r" r0, the result that output.
sub syscall_idiom_arm {
    my ($cs) = @_;
    my @st = kids($cs);
    my ($asm) = grep { $_->{kind} eq 'GCCAsmStmt' } @st;
    return () unless $asm;
    my ($template, $oc, $ic, $ops) = asm_parts($asm);
    return () unless $template =~ /^\s*swi\s+0x0\b/ && @$oc == 1 && $oc->[0] eq '=r';
    my %argno = (r0 => 0, a1 => 0, r1 => 1, a2 => 1, r2 => 2, a3 => 2, r3 => 3, a4 => 3, r4 => 4, v1 => 4, r5 => 5, v2 => 5, r6 => 6, v3 => 6);
    my (%regof, %reg, %local);
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            if ($lab) { my $r = asm_label($lab) // next; $regof{ $v->{name} } = $r; $reg{$r} = $init if $init }
            elsif ($init && defined $v->{name}) { $local{ $v->{name} } = $init }
        }
    }
    for my $s (grep { $_->{kind} eq 'BinaryOperator' && $_->{opcode} eq '=' } @st) {
        my ($l, $r) = kids($s);
        $l = strip($l);
        next unless $l->{kind} eq 'DeclRefExpr' && defined $regof{ $l->{referencedDecl}{name} };
        $reg{ $regof{ $l->{referencedDecl}{name} } } = $r;
    }
    defined $reg{r7} or stop('a syscall without its number', $asm);
    my @args;
    my %byno = map { ($argno{$_} => $reg{$_}) } grep { defined $argno{$_} } keys %reg;
    for my $i (0 .. 6) {
        my $e = $byno{$i} or last;
        my $s = strip($e);
        $e = $local{ $s->{referencedDecl}{name} } if $s->{kind} eq 'DeclRefExpr' && $local{ $s->{referencedDecl}{name} };
        push @args, item(expr($e));
    }
    node('syscall', item(expr($reg{r7})), @args);
}
# x86_64's: register variables rdi rsi rdx r10 r8 r9 = the arguments (from
# the __argN before them), the asm syscall with the number its input in the
# output's place ("0", the output "=a" rax), the result that output.
sub syscall_idiom_x86 {
    my ($cs) = @_;
    my @st = kids($cs);
    my ($asm) = grep { $_->{kind} eq 'GCCAsmStmt' } @st;
    return () unless $asm;
    my ($template, $oc, $ic, $ops) = asm_parts($asm);
    return () unless $template =~ /^\s*syscall[\s;]*$/ && @$oc == 1 && $oc->[0] eq '=a';
    # (only declarations, the asm and the output last: INTERNAL_SYSCALL's;
    # TLS_INIT_TP's sets the TCB's words first and gives _result == 0, its
    # asm an asm function of its own)
    my @other = grep { $_->{kind} ne 'DeclStmt' && $_->{kind} ne 'GCCAsmStmt' } @st;
    my $outid = (strip($ops->[0])->{referencedDecl} // {})->{id} // '';
    my $last = @other ? strip($other[0]) : undef;
    $last = strip((kids($last))[0]) while $last && $last->{kind} =~ /^(CStyleCastExpr|ParenExpr)$/;
    return () if @other > 1 || (@other && ($other[0] != $st[-1] || (($last->{referencedDecl} // {})->{id} // '-') ne $outid));
    my ($num) = grep { $ic->[$_] eq '0' } 0 .. $#$ic;
    defined $num or stop('a syscall without its number', $asm);
    my (%reg, %local);
    for my $s (grep { $_->{kind} eq 'DeclStmt' } @st) {
        for my $v (kids($s)) {
            my ($lab) = grep { $_->{kind} eq 'AsmLabelAttr' } kids($v);
            my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
            next unless $init;
            if ($lab) { my $r = $lab->{label} // (($v->{name} // '') =~ /^_a([1-6])$/ ? (qw(rdi rsi rdx r10 r8 r9))[$1 - 1] : undef); $reg{$r} = $init if defined $r } elsif (defined $v->{name}) { $local{ $v->{name} } = $init }
        }
    }
    # (or inputs in them by their constraints, D S d: TLS_INIT_TP's
    # arch_prctl (ARCH_SET_FS, the TCB))
    my %creg = (D => 'rdi', S => 'rsi', d => 'rdx');
    for my $j (0 .. $#$ic) { my $r = $creg{ $ic->[$j] } or next; $reg{$r} //= $ops->[@$oc + $j] }
    my @args;
    for my $r (qw(rdi rsi rdx r10 r8 r9)) {
        my $e = $reg{$r} or last;
        my $s = strip($e);
        $e = $local{ $s->{referencedDecl}{name} } if $s->{kind} eq 'DeclRefExpr' && $local{ $s->{referencedDecl}{name} };
        push @args, item(expr($e));
    }
    node('syscall', item(expr($ops->[@$oc + $num])), @args);
}

# ---- statements ---------------------------------------------------------------

# A block's statements. (A local declared first in a function without a
# value would be one more parameter, but the comment that says where the
# function comes from ends them.)
sub body {
    my ($cs) = @_;
    map { lstmt($_) } kids($cs);
}

# ---- the C places of statements -------------------------------------------------
# Before a statement of a list (a block, a function's body, a case, an if's
# or a loop's body of one statement) a line says where it begins in the C
# (ttpc -g's line table, the C view): line / file / number where the file is
# not the one before (the first of a function always), line / number where
# only the line is. The place is the .i's line of its offset as the .i's
# line markers (# N "file") make it; none for a statement without an offset
# or before any marker. A block of more than a node holds keeps its own
# statements without them.
our ($lfile, $lline) = ('', 0);   # the place of the line before, in this function
sub iplace {
    my ($off) = @_;
    my $u = $cur_unit;
    return unless defined $off && $u && defined $u->{text};
    unless ($u->{nl}) {
        my $t = $u->{text};
        my @nl = (0);
        push @nl, pos($t) while $t =~ /\n/g;
        my @m;
        while ($t =~ /^# (\d+) "((?:[^"\\]|\\.)*)"/mg) { push @m, [lindex(\@nl, $-[0]), $1, $2] }
        @$u{qw(nl marks)} = (\@nl, \@m);
    }
    my $li = lindex($u->{nl}, $off);
    my $m = $u->{marks};
    my ($lo, $hi) = (0, scalar @$m);
    while ($lo < $hi) { my $mid = ($lo + $hi) >> 1; if ($m->[$mid][0] < $li) { $lo = $mid + 1 } else { $hi = $mid } }
    return unless $lo;
    my ($k, $n, $f) = @{ $m->[$lo - 1] };
    $f =~ s/\\(.)/$1/g;
    ($f, $n + $li - $k - 1);
}
# (the index of the line that holds offset off: the last start at or before it)
sub lindex {
    my ($nl, $off) = @_;
    my ($lo, $hi) = (0, scalar @$nl);
    while ($lo < $hi) { my $mid = ($lo + $hi) >> 1; if ($nl->[$mid] <= $off) { $lo = $mid + 1 } else { $hi = $mid } }
    $lo - 1;
}
sub offset_of { my ($l) = @_; $l && ($l->{offset} // ($l->{expansionLoc} // {})->{offset}) }
sub line_at {
    my ($off) = @_;
    my ($f, $n) = iplace($off) or return ();
    return () if length($f) > 255 || ($f eq $lfile && $n == $lline);
    my @l = $f eq $lfile ? node('line', node($n)) : node('line', node($f), node($n));
    ($lfile, $lline) = ($f, $n);
    @l;
}
sub lstmt {
    my ($n) = @_;
    (line_at(offset_of($n->{range}{begin})), stmt($n));
}
sub is_line { my ($n) = @_; $n->{content} eq 'line' && @{ $n->{children} } }

sub stmt {
    my ($n) = @_;
    my $k = $n->{kind};
    if ($k eq 'CompoundStmt') {
        my @b = body($n);
        if (@b > 255) { @b = grep { !is_line($_) } @b; $lfile = '' }
        return node(':', @b);
    }
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
            # (gcc's __errordecl, a function of the error attribute: a call of
            # it is an error where gcc does not take it away, so a call that
            # stays is never reached: none (alloc_buffer's asserts, whose
            # __builtin_constant_p is 0 here: they called glibc's error ())
            if (grep { $_->{kind} eq 'ErrorAttr' } @{ $d->{inner} || [] }) { $errorfn{"$cur_unit $d->{id}"} = 1 }
            else {
                $weak{ $d->{name} } //= $d if grep { $_->{kind} eq 'WeakAttr' } @{ $d->{inner} || [] };
                want($d->{name});
            }
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
    # (a label's attribute, ret0: __attribute__ ((unused)), says nothing of its code)
    if ($k eq 'LabelStmt') {
        my ($s) = grep { $_->{kind} !~ /Attr$/ } kids($n);
        # (a declaration after a label, C23's, libgcc's btree_lookup restart:
        # struct btree_node *iter: the label alone, then the declaration, whose
        # scope is the block's, not the label's)
        return (node(label_name($n->{name}) . ':'), stmt($s)) if $s && $s->{kind} eq 'DeclStmt';
        return node(label_name($n->{name}) . ':', stmt($s));
    }
    return node('goto', node(label_name($label{ $n->{targetLabelDeclId} } // stop('a goto to no label', $n)))) if $k eq 'GotoStmt';
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
# A call's argument: its value; one that C converts from unsigned int to a
# wider integer (a parameter of 8 bytes) as that cast, written: ttpc passes
# an argument by its own type, and riscv64's lp64d sign-extends an unsigned
# int (stdbit's __builtin_clzll (x) of a u32 x)
sub arg {
    my ($a) = @_;
    if ($a->{kind} eq 'ImplicitCastExpr' && ($a->{castKind} // '') eq 'IntegralCast') {
        my ($v) = kids($a);
        my @to = ctype(qt($a));
        my @from = ctype(qt($v));
        return cast_node([@to], item(expr($v))) if "@from" =~ /^(?:u32|unsigned int)$/ && "@to" =~ /^(?:u64|long|i64|unsigned long|long long|unsigned long long)$/;
    }
    item(expr($a));
}
# An expression for what it does, its value unused: x++ is ++x then.
# (x = setjmp (...), a function that returns twice: its value first into a
# local of its own, then x; ttpc keeps x's address on the stack across the
# call, which the second return finds overwritten: start_thread's
# not_first_call, where pthread_cancel's longjmp comes back)
sub effect {
    my ($n) = @_;
    my $s = strip($n);
    return (atom((kids($s))[0]), node($s->{opcode})) if $s->{kind} eq 'UnaryOperator' && $s->{opcode} =~ /^(\+\+|--)$/;
    if ($s->{kind} eq 'BinaryOperator' && $s->{opcode} eq '=' && returns_twice((kids($s))[1])) {
        my ($l, $r) = kids($s);
        return node(':', node('returns twice:', map({ node($_) } ctype(qt($r))), item(expr($r))), expr($l), node('='), node('returns twice'));
    }
    return node(':', map { effect($_) } kids($s)) if $s->{kind} eq 'BinaryOperator' && $s->{opcode} eq ',';
    item(expr($n));
}
# a call of a function that returns twice (setjmp's, getcontext, vfork)
sub returns_twice {
    my $c = strip($_[0] // return 0);
    return 0 unless $c->{kind} eq 'CallExpr';
    my $f = strip((kids($c))[0] // return 0);
    $f->{kind} eq 'DeclRefExpr' && ($f->{referencedDecl}{name} // '') =~ /^(?:_?setjmp|__sigsetjmp|sigsetjmp|__builtin_setjmp|_?_?getcontext|vfork|__vfork)$/;
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
        push @{ $out[-1]{children} }, lstmt($s);
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
    push @{ $head[0]{children} }, lstmt($sub);
    @head;
}
sub sub_body { my ($s) = @_; $s->{kind} eq 'CompoundStmt' ? body($s) : lstmt($s) }
sub ifs {
    my ($word, $n) = @_;
    my @k = kids($n);
    my ($c, $t, $e) = $n->{hasElse} ? @k : (@k, undef);
    my @r = node($word, item(expr($c)), sub_body($t));
    push @r, ($e->{kind} eq 'IfStmt' ? ifs('else if', $e) : node('else', sub_body($e))) if $e;
    @r;
}

# C's aligned attribute of a declaration (its largest n; aligned without n
# is the target's largest alignment), else undef: ff's align n, first
sub align_attr {
    my ($d) = @_;
    my $n;
    for my $a (grep { $_->{kind} eq 'AlignedAttr' } @{ $d->{inner} || [] }) {
        my ($e) = @{ $a->{inner} || [] };
        my $v = !$e || !%$e ? alignas($a) // ($target eq 'arm' ? 8 : 16) : $e->{value};
        defined $v && $v =~ /^\d+$/ or stop('an aligned attribute of no number', $d);
        $n = $v if !defined $n || $v > $n;
    }
    $n;
}
# _Alignas (type), whose JSON has neither n nor the type (the .i has it):
# the alignment of the type, a scalar's; undef for aligned without n
sub alignas {
    my ($a) = @_;
    my $b = $a->{range}{begin}{offset} // ($a->{range}{begin}{expansionLoc} // {})->{offset};
    return undef unless defined $b && $cur_unit;
    substr($cur_unit->{text}, $b, 200) =~ /^(?:_Alignas|alignas)\s*\(\s*([^()]*?)\s*\)/ or return undef;
    my $t = $1;
    return $t + 0 if $t =~ /^\d+$/;
    my ($w, @more) = ctype($t);
    # (a floating type's too: tst-random-bz30584's _Alignas (double))
    my %fl = (float => 4, double => 8, 'long double' => $target eq 'arm' ? 8 : 16);
    my $n = !@more && ($target eq 'arm' && $w =~ /^(?:long|address)$/ ? 4 : $wsize{$w} // $fl{$w});
    $n or stop("_Alignas of $t, no scalar", $a);
    $n;
}
sub max_align { my ($a, $b) = @_; !defined $a ? $b : !defined $b ? $a : $a > $b ? $a : $b }
sub align_node { my ($n) = @_; defined $n ? node('align', node($n)) : () }
sub cleanup_node {
    my ($v) = @_;
    my ($a) = grep { $_->{kind} eq 'CleanupAttr' } @{ $v->{inner} || [] } or return ();
    my $f = $a->{cleanup_function} or stop('a cleanup attribute without its function', $v);
    my $g = own($f->{name});
    want($g);
    node('cleanup', node(ffname($g)));
}
sub decl {
    my ($v, $global, $name) = @_;
    $v->{kind} eq 'VarDecl' or stop('a declaration of ' . $v->{kind}, $v);
    # a variable-length array (iofwide's wchar_t to_buf[max]): array, the
    # element's type and the count, which clang has only as text in the type
    if (!$global && constcounts(qt($v)) =~ /^(.*?) ?\[([^\[\]]*[A-Za-z_][^\[\]]*)\]$/) {
        my ($elem, $count) = ($1, $2);
        my @c = vla_count($count, $v);
        # (a count of one name in a : too: a global's name alone there, as
        # arc4random-thread's static outer_threads, ttpc takes for a constant,
        # its address, which moves between its passes)
        return node(ffname($v->{name}) . ':', node('array'), map({ node($_) } ctype($elem)), @c > 1 || $c[0]{content} !~ /^\d+$/ ? node(':', @c) : @c);
    }
    my @t = ctype(qt($v));
    my ($init) = grep { $_->{kind} !~ /Attr$/ } kids($v);
    local $in_global = $global;
    my @i = $init ? init($init) : ();
    # (a local's = {}: zero, an empty : for it, which a local with no items
    # would not be)
    @i = node(':') if !$global && !@i && $init && strip($init)->{kind} eq 'InitListExpr';
    # a global takes each item as one node
    @i = node(':', @i) if $global && @i > 1 && strip($init)->{kind} ne 'InitListExpr' && !bare_string($init);
    # under address / char a leaf is text: a value that starts with a leaf goes
    # in a : (vfprintf's char *workend = work_buffer + WORK_BUFFER_SIZE)
    # (content x and address x too: in the words of now x * pointer and
    # x & address, whose x is a leaf: gconv's const unsigned char *inptr =
    # *inptrp was the text "inptrp", which its loops then wrote over)
    @i = node(':', @i) if "@t" =~ /^address (char|u8)$/ && @i && (!@{ $i[0]{children} } || $i[0]{content} =~ /^(?:content|address)$/) && !bare_string($init);
    # a thread-local one, __thread, is ff's thread local (ttpc lays it out in
    # the TLS image, where the target has one)
    my @tls = $global && $v->{tls} ? node('thread local') : ();
    # a global of a named section (section ("impls")): ttpc places it with
    # the others of the section, between __start_impls and __stop_impls. A
    # section whose name is no C name (glibc's .data.rel.ro) has no bounds
    # (ld defines them for a C name only) and nothing to keep together in a
    # static program: no section there
    my ($sec) = $global ? grep { $_->{kind} eq 'SectionAttr' && $_->{section_name} =~ /^[A-Za-z_]\w*$/ } kids($v) : ();
    unshift @tls, node('section'), node($sec->{section_name}) if $sec;
    # (a local's cleanup attribute: cleanup / f, after its align: f is
    # called with its address at each exit of its block; glibc's
    # _IO_acquire_lock, which unlocks a FILE so)
    unshift @tls, cleanup_node($v) unless $global;
    # (an aligned attribute or _Alignas first: a global's, a local's,
    # qsort's _Alignas (uint64_t) char tmp[1024])
    unshift @tls, align_node(align_attr($v));
    node(($name // ffname($v->{name})) . ':', @tls, map({ node($_) } @t), grouped(255 - @t - @tls, @i));
}
# A variable-length array's count from its text: names (its locals), numbers,
# + - * / and parentheses, as ff infix.
sub vla_count {
    my ($text, $v) = @_;
    # (sizeof of a string, its bytes and the 0: sysconf's sizeof ("/POSIX_V6_"))
    $text =~ s{\bsizeof\s*\(\s*"((?:[^"\\]|\\.)*)"\s*\)}{ (my $b = $1) =~ s/\\./x/g; length($b) + 1 }ge;
    stop("the count of a variable-length array: $text", $v) if $text =~ /["']|\bsizeof\b/;
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
    my $r = $rec{$t} // do { my $a = own_anon($t) || $anon{ anon_key($t) // '' }; $a && $rec{ $a->[0] } } or return ();
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
    # (an enum's is a number too: x86_64's link_map l_property, a bitfield)
    if ($s->{kind} eq 'ImplicitValueInitExpr') { my @t = ctype(qt($s)); return @t == 1 && $scalar_word{$t[0]} || $t[0] eq 'address' || expand(qt($s)) =~ /^enum\b/ ? node(0) : node(':') }
    # an item of a list is one node
    my @e = item(expr($n));
    @e > 1 ? node(':', @e) : @e;
}

# ---- definitions ----------------------------------------------------------------

sub function {
    my ($name, $d) = @_;
    local $cur_fn = $name;
    local %local = map { ($_->{id} => 1) } locals($d);
    # (the types of its locals by name, for a typeof of one: typeof_expr)
    local %ltypeof = map { ($_->{name} => qt($_)) } grep { $_->{name} && $_->{type} } locals($d);
    local %label = map { ($_->{declId} => $_->{name}) } labels($d);
    my ($ret) = split_fn(expand(qt($d)));
    defined $ret or die "c2ff: not a function type: " . qt($d) . "\n";
    # (a function of 128-bit integers, its value, a parameter or a local:
    # ttpc has no such integer, and c2ff's two u64 of one are its layout
    # only: libgcc's TImode helpers, __multi3 ..., stop, once translated)
    local $saw_i128 = 0;
    my @p = grep { $_->{kind} eq 'ParmVarDecl' } kids($d);
    my ($cs) = grep { $_->{kind} eq 'CompoundStmt' } kids($d);
    my $i = 0;
    my @head = (map({ node($_) } ctype($ret)),
        map({ $i++; node(ffname($_->{name} // "p$i") . ':', map { node($_) } ctype(qt($_))) } @p),
        ($d->{variadic} ? node('...') : ()),
        # (the .i, not the copy of it clang read: CLANGFIX; after the name
        # of its tree, glibc-2.44, gcc-16.2.0 for libgcc's)
        node('comment', node(do { my $f = $d->{file} =~ s/\.clang\.i$/.i/r; unit_label($f) . " $f" })));
    # (constructor or destructor first, its priority under it: the user's
    # choice, 2026-10-21)
    my $c = $ctor{$name};
    unshift @head, node($c->[0], defined $c->[1] ? node($c->[1]) : ()) if $c;
    # (the function's place first, with its file: where its name is)
    local ($lfile, $lline) = ('', 0);
    my @at = line_at(offset_of($d->{loc}));
    my $f = node(ffname($name) . ':', @head, stmt_layers(scalar @head, (@at ? [@at] : ()), map { [lstmt($_)] } kids($cs)));
    stop("a function of __int128 values, which ttpc has no integer of", $d) if $saw_i128;
    $f;
}
# A function's statements, each a run of nodes: past what a node holds
# (255, with the head before them), in layers 0: 1: ... of whole
# statements, as ttpc reads them (a layer's children are its parent's).
sub stmt_layers {
    my ($head, @st) = @_;
    my $n = 0;
    $n += @$_ for @st;
    return map { @$_ } @st if $head + $n <= 255;
    my (@layers, @cur);
    for my $s (@st) {
        if (@cur + @$s > 255) { push @layers, node(scalar(@layers) . ':', @cur); @cur = () }
        push @cur, @$s;
    }
    push @layers, node(scalar(@layers) . ':', @cur) if @cur;
    die "c2ff: a function too long for layers of one level\n" if $head + @layers > 255;
    @layers;
}

sub next_name {
    return shift @todo if @todo;
    while (@roots) { my $r = shift @roots; return $r unless $done{$r}++ }
    undef;
}
# (--keep-going: a definition c2ff cannot translate yet is left out, said
# on stderr with why, and the rest goes on: all of glibc while a few of
# its objects wait)
my %left_out;              # (their ff names: an alias of one is left out too)
sub leave_out {
    my ($name) = @_;
    die $@ unless $keep_going;
    $left_out{ ffname($name) } = 1;
    (my $why = $@) =~ s/\n+$//;
    warn "c2ff: left out: $name: $why\n";
}
# (a program's own texts, text N and wide text N, from 100001: glibc's units
# have theirs from 1, and a unit's text 5 found the program's, which was
# another: C-numeric's decimal point "." was "" in tst-strtod2)
($ntext, $nwide) = (100000, 100000) if defined $program;
# (an object's constructors and destructors are roots: the start code runs
# them, whatever names the object: tst-putenv's module of a constructor alone)
want($_) for map { @{ $ctors_of{$_} // [] } } grep { $_->{object} } @units;
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
    if (my $f = $fn{$name}) {
        local $cur_unit = $f->[1];
        want($_) for @{ $ctors_of{ $f->[1] } // [] };
        eval { push @out, [$f->[1], function($name, body_of(@$f))]; 1 } or leave_out($name);
        next;
    }
    if (my $v = $var{$name}) {
        local $cur_unit = $v->[1];
        want($_) for @{ $ctors_of{ $v->[1] } // [] };
        local $cur_global = $name;
        eval { push @out, [$v->[1], decl($v->[0], 1, $name ne $v->[0]{name} ? ffname($name) : undef)]; 1 } or leave_out($name);
        next;
    }
    # a weak name nothing defines: its address is 0 (ttpc's weak); one the
    # program's tree defines is the tree's
    if ($weak{$name} && $treedefs{ ffname($name) }) { warn "c2ff: weak, the tree's: $name\n"; next }
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
    # a section's bounds, which ttpc defines where it places the section (as
    # ld does): the section's globals come with them
    if ($name =~ /^__(?:start|stop)_(\w+)$/ && $section{$1}) { want($_) for @{ $section{$1} }; next }
    warn "c2ff: no definition of $name, left out\n";
}
# (an alias of what was left out is left out too: libgcc's __nehf2, of
# __eqhf2, a function of _Float16)
{
    my @a;
    while (@a = grep { @{ $_->[1]{children} } == 2 && $_->[1]{children}[0]{content} eq 'alias' && $left_out{ $_->[1]{children}[1]{content} } } @out) {
        my %drop = map { $_ => 1 } @a;
        for (@a) { (my $n = $_->[1]{content}) =~ s/:$//; $left_out{$n} = 1; warn "c2ff: left out: $n: an alias of $_->[1]{children}[1]{content}, left out\n" }
        @out = grep { !$drop{$_} } @out;
    }
}

# An enum constant whose name a function or global of the tree has too (a
# block's enum { null, data, inst, uni } of dl-cacheinfo.h, vfprintf's static
# null): C keeps them apart by scope, ff by name, so the constant is named
# with the unit it is used in (null csu/libc-start), its uses too.
my %defname = map { $_->[1]{content} =~ /^(.*):$/ ? ($1 => 1) : () } @out;
sub enum_rename {
    my ($c) = @_;
    my $n = ffname($c);
    return $n unless $defname{$n} && $enumunit{$c};
    my $new = ffname("$c " . unit_name($enumunit{$c}));
    $_->{content} = $new for @{ $enumref{$c} || [] };
    $new;
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
        # (its fields' types as its unit has them)
        local $cur_unit = $recunit{$tag} // $cur_unit;
        # a tag C only declares (struct rtld_catch;) is an incomplete type, used
        # through an address: a struct without fields
        my $d = $rec{$tag} // $enumd{$tag} // ($tag =~ /^(struct|union) / ? { kind => 'RecordDecl', tagUsed => $1, inner => [] } : undef)
            or do { warn "c2ff: no definition of $tag\n"; next };
        my ($kind) = $tag =~ /^(\S+)/;
        next if defined $program && $tag =~ /^(?:struct|union) [A-Za-z_]\w*$/ && !$rec{$tag} && $treerec{ join ' ', ctype($tag) };
        if ($kind eq 'enum') {
            # (its name, where no ctype of it gave it yet: index_enum leaves it)
            ctype($tag) unless defined $tagname{$tag};
            # a constant keeps its value where C gives it one (clang has worked it out)
            unshift @types, node($tagname{$tag} . ':', node('enum'), grouped(254, map {
                my $v = enum_value($_);
                node(enum_rename($_->{name}) . ':', defined $v ? node($v) : ())
            } grep { $_->{kind} eq 'EnumConstantDecl' } kids($d)));
        } else {
            # a bitfield: its type run, then its width (one with no name, padding,
            # takes its bits under a name of its own)
            my $pad = 0;
            # (a bitfield of width 0 last, unwind-arm-common.h's long long
            # int :0, aligns the record as its type: no field, the record's
            # align)
            my @fd = grep { $_->{kind} eq 'FieldDecl' } kids($d);
            my $zalign;
            while (@fd && $fd[-1]{isBitfield} && !(defined $fd[-1]{name} && $fd[-1]{name} ne '')
                && grep { $_->{kind} eq 'ConstantExpr' && defined $_->{value} && $_->{value} == 0 } kids($fd[-1])) {
                my %size = (char => 1, i8 => 1, u8 => 1, short => 2, i16 => 2, u16 => 2, int => 4, i32 => 4, u32 => 4, i64 => 8, u64 => 8, long => $target eq 'arm' ? 4 : 8);
                my $t = join ' ', ctype(qt(pop @fd));
                $zalign = max_align($zalign, $size{$t} // stop("a bitfield of width 0 of a $t", $d));
            }
            unshift @types, node($tagname{$tag} . ':', node($kind), align_node(max_align(max_align(align_attr($d), $d->{ff_align}), $zalign)), map {
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
                node((defined $name ? "$name:" : ':'), align_node(align_attr($f)), (map { node($_) } ctype(qt($f))), @w)
            } @fd);
        }
    }
}
}

# glibc in ff is a page per glibc directory (string, stdio-common, ...), its
# types in one of their own, the weak names in another: a node holds 255
# children, so a longer page holds them in layers (0: 1: ..., the user's
# overflow of a node, see FF.pm layers).
sub unit_name { my ($u) = @_; return 'weak' unless $u; (my $n = $u->{i}) =~ s{^.*/([^/]+/[^/]+)\.i$}{$1}; $n }
sub groups { my ($name, @n) = @_; node("$name:", layers(@n)) }
# the words now (Words.pm): what was made in the words of before, written in
# them; the types the shared page's and the output's own
{
    my $t = {};
    { open my $h, '<:raw', "$FindBin::Bin/../shared.ff" or die "c2ff: shared.ff: $!\n"; local $/; Words::typenames($t, read_ff(<$h>)) }
    my @n = Words::newwords($t, @types, map { $_->[1] } @out);
    @types = splice @n, 0, scalar @types;
    $out[$_][1] = $n[$_] for 0 .. $#out;
}
if (defined $program) {
    # (its license first: its file's header, Header.pm)
    my $lic = header_of($units[0]{i});
    print write_txt(node('license', map { node($_) } $lic->{spdx}, @{ $lic->{lines} }), node('include', node($program)), @types, (map { $_->[1] } @out),
        ($start ? node('_start:', node('void'), node('syscall', node('SYS_exit'), node('main'))) : ()));
} else {
    my (@order, %by);
    # (by directory, not by unit: the trees a program reads have 255 pages in
    # all, and M4 has more units than that; each function's comment names its
    # unit)
    my %units;
    for (@out) { my $g = unit_name($_->[0]) =~ s{/.*}{}r; push @order, $g unless $by{$g}; push @{ $by{$g} }, $_->[1]; $units{$g}{ $_->[0]{i} } = 1 if $_->[0] }
    # each page first has the license of each file it is made of (Header.pm)
    print write_txt(groups("$page types", @types), map { groups("$page $_", license_nodes(sort keys %{ $units{$_} || {} }), @{ $by{$_} }) } @order);
}
warn "c2ff: renamed: " . join(', ', map { "$_ -> $renamed{$_}" } sort keys %renamed) . "\n" if %renamed;
