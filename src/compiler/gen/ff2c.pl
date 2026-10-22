#!/usr/bin/env perl
# ff2c.pl — ff's C layer as C: the definitions of a tree (glibc in ff, a
# milestone's .ff.txt) written back as one C translation unit, read the way
# ttpc reads them (language.ff.txt), so that clang's AST of the result can be
# held against clang's AST of the C they were made of (src/glibc/roundtrip.pl).
#
#   perl ff2c.pl tree.ff.txt out.c names.txt
#   perl ff2c.pl --pages 'glibc string,glibc stdlib' tree.ff.txt out.c names.txt
#
# With --pages, only those glibc pages' bodies and globals are written (the
# rest declared): all of glibc is held against its C a part at a time.
#
# out.c has every type, a declaration of every global and function, the body
# of every C function of the glibc pages and the definition of each of their
# globals with its items; names.txt says, for each such function, its C name
# here, its name in the C it came from and that C's .i (the comment c2ff puts
# first in each function), and for each global where glibc has it.
#
# What c2ff writes in a fixed form for what C has no other ff form of is
# written back as that C: a text it made a global (text N, wide text N) is the
# string again, a function's statics (named "function name") are its own, a
# unit's own static ("name unit") is its name. Names ff reserves come back
# without their ' . Builtins are clang's (an overflow builtin named for its
# operand types is the builtin), and ff's syscall is a call of __ff_syscall,
# which roundtrip.pl takes glibc's INTERNAL_SYSCALL for.
#
# A host tool, not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(read_txt);
use FF ();
use Header ();

my %only;      # --pages a,b: only these glibc pages' bodies and globals
if (@ARGV && $ARGV[0] eq '--pages') { shift @ARGV; $only{$_} = 1 for split /,/, shift @ARGV }
my ($in, $out, $namesout) = @ARGV;
die "usage: ff2c.pl [--pages page,...] tree.ff.txt out.c names.txt\n" unless defined $namesout;
my @top = do { open my $h, '<', $in or die "ff2c: $in: $!\n"; local $/; read_txt(<$h>, $in) };
# The C words now (Words.pm): read in the words of before, which the rest of
# ff2c knows; a : field of a scalar type (C's unnamed bitfield) is padding n:
# again
{
    require Words;
    my $t = {};
    { open my $h, '<:raw', "$FindBin::Bin/../shared.ff" or die "ff2c: shared.ff: $!\n"; local $/; Words::typenames($t, FF::read_ff(<$h>)) }
    # (through the layers of a node past 255, 0: 1: ...: one list again)
    my $flat;
    $flat = sub { my ($n) = @_; $n->{children} = [map { FF::is_layer($_) ? @{ $flat->($_)->{children} } : $flat->($_) } @{ $n->{children} }]; $n };
    $flat->($_) for @top;
    @top = Words::oldwords($t, @top);
    my %scalar = map { $_ => 1 } qw(char short int long i8 i16 i32 i64 u8 u16 u32 u64);
    my $pad;
    $pad = sub {
        my ($n) = @_;
        my $k = $n->{children};
        if (@$k && !@{ $k->[0]{children} } && $k->[0]{content} =~ /^(?:struct|union)$/) {
            my $i = 0;
            for (@$k[1 .. $#$k]) { $_->{content} = 'padding ' . ++$i . ':' if $_->{content} eq ':' && @{ $_->{children} } && $scalar{ $_->{children}[0]{content} } }
        }
        $pad->($_) for @$k;
    };
    $pad->($_) for @top;
}

sub kids { @{ $_[0]{children} } }
sub leaf { !@{ $_[0]{children} } }
sub c { $_[0]{content} }
sub fail { my ($what, $n) = @_; die "ff2c: $what" . ($n ? " (at " . c($n) . ")" : '') . (our $cur_fn ? " in $cur_fn" : '') . "\n" }

# ---- names ------------------------------------------------------------------

my %cid;        # ff name -> C identifier
my %taken;
my %ckw = map { $_ => 1 } qw(auto break case char const continue default do double else enum extern float for goto
    if inline int long register restrict return short signed sizeof static struct switch typedef union unsigned
    void volatile while _Bool _Complex _Imaginary _Alignas _Alignof _Atomic _Generic _Noreturn _Static_assert _Thread_local);
sub cid {
    my ($n) = @_;
    return $cid{$n} if exists $cid{$n};
    (my $s = $n) =~ s/'$//;
    $s =~ s/[^A-Za-z0-9_]/_/g;
    $s = "_$s" if $s =~ /^\d/ || $ckw{$s};
    my $b = $s;
    my $k = 1;
    $s = $b . '_' . ++$k while $taken{$s};
    $taken{$s} = 1;
    $cid{$n} = $s;
}

# ---- the definitions --------------------------------------------------------

my %scalar = (char => 'char', short => 'short', int => 'int', long => 'long', i8 => 'signed char', i16 => 'short',
    i32 => 'int', i64 => 'long long', u8 => 'unsigned char', u16 => 'unsigned short', u32 => 'unsigned int',
    u64 => 'unsigned long', void => 'void', float => 'float', double => 'double', 'long double' => 'long double',
    va_list => '__builtin_va_list', 'complex float' => '_Complex float', 'complex double' => '_Complex double',
    'complex long double' => '_Complex long double');
my (%rec, %enum, %fntype, %fn, %var, %econst, @order);
my %glibcpage;   # functions of the glibc pages (their bodies are written)
my @headers;    # the license of each file a page is made of: [its name, its lines]

for my $page (@top) {
    next if c($page) eq 'comment' || c($page) eq 'license';
    my $glibc = c($page) =~ /^glibc / && c($page) ne 'glibc asm:' && (!%only || $only{ c($page) =~ s/:$//r });
    # (each license after a comment naming its file: that file's header)
    { my @k = FF::kids($page);
      for my $i (1 .. $#k) {
          next unless c($k[$i]) eq 'license' && c($k[$i - 1]) eq 'comment' && @{ $k[$i - 1]{children} };
          my ($f) = c($k[$i - 1]{children}[0]) =~ /^glibc-\S+ (.+)$/ or next;
          my (undef, @l) = map { c($_) } kids($k[$i]);
          push @headers, [$f, \@l];
      } }
    # (a page's definitions through its layers, 0: 1: ...)
    my $al;
    for my $d (FF::kids($page)) {
        undef $al;
        next if c($d) eq 'comment' || c($d) eq 'license';
        (my $name = c($d)) =~ s/:$// or fail('not a definition', $d);
        my @k = kids($d);
        my $w = @k ? c($k[0]) : '';
        # a global's align n first (C's aligned attribute): the words after it as before
        if ($w eq 'align' && !leaf($k[0])) { $al = c((kids($k[0]))[0]); shift @k; $w = @k ? c($k[0]) : '' }
        push @order, $name;
        if ($w eq 'struct' || $w eq 'union') { $rec{$name} = { kind => $w, node => $d }; next }
        if ($w eq 'enum') {
            $enum{$name} = $d;
            $econst{ c($_) =~ s/:$//r } //= $name for grep { c($_) =~ /:$/ } map { c($_) eq 'items' ? kids($_) : $_ } @k[1 .. $#k];
            next;
        }
        if ($w eq 'function' && $page && c($page) =~ /types/) { $fntype{$name} = $d; next }
        if ($w eq 'alias') { $fn{$name} = { kind => 'alias', target => c($k[1]) }; next }
        if ($w eq 'ifunc') { $fn{$name} = { kind => 'ifunc', node => $d, from => 2 }; next }
        if ($w eq 'asm') {
            $fn{$name} = { kind => 'asm' };
            # (and each entry of it, a block whose first child is asm)
            for my $b (grep { !leaf($_) && c($_) =~ /^(.+):$/ && c((kids($_))[0]) eq 'asm' } @k) { (my $e = c($b)) =~ s/:$//; $fn{$e} //= { kind => 'asm' }; push @order, $e }
            next;
        }
        if ($w eq 'weak') {
            if (@k > 1 && c($k[1]) eq 'function') { $fn{$name} = { kind => 'weak', node => $d, from => 2 } }
            else { $var{$name} = { node => $d, from => 1, weak => 1 } }
            next;
        }
        # a constructor or destructor (and its priority): C's attribute
        if ($w eq 'constructor' || $w eq 'destructor') {
            my @p = kids($k[0]);
            $fn{$name} = { kind => 'c', node => $d, from => 1, ctor => $w . (@p ? '(' . c($p[0]) . ')' : '') };
            $glibcpage{$name} = 1 if $glibc;
            next;
        }
        if ($w eq 'thread local') { $var{$name} = { node => $d, from => 1, tls => 1, glibc => $glibc }; next }
        # a global of a named section; its bounds __start_ and __stop_ of
        # the name are arrays of its type, as C declares them
        if ($w eq 'section') {
            my $sec = c($k[1]);
            $var{$name} = { node => $d, from => 2, glibc => $glibc, section => $sec };
            for my $b ("__start_$sec", "__stop_$sec") { next if $var{$b}; $var{$b} = { bound => $name }; push @order, $b }
            next;
        }
        if (is_function($d)) { $fn{$name} = { kind => 'c', node => $d, from => 0 }; $glibcpage{$name} = 1 if $glibc }
        else { $var{$name} = { node => $d, from => 0, glibc => $glibc } }
    } continue {
        # (past its align)
        (my $name = c($d)) =~ s/:$//;
        if (defined $al && $var{$name} && $var{$name}{node} == $d) { $var{$name}{from}++; $var{$name}{align} = $al }
    }
}

# A page item is a global when its items have children only as :, address,
# cast: or a typed literal; else a function (language.ff.txt).
sub is_function {
    my ($d) = @_;
    for my $k (kids($d)) {
        next if leaf($k);
        my $w = c($k);
        next if $w eq ':' || $w eq 'address' || $w eq 'cast:' || $w eq 'items' || $w eq 'align';
        next if (exists $scalar{$w} || $rec{$w}) && !grep { !leaf($_) } kids($k);
        return 1;
    }
    0;
}

# ---- types ------------------------------------------------------------------
# A type is [scalar => 'int'], [ptr => T or undef (void)], [arr => T, count
# node], [rec => name], [enum => name], [fn => name], [fs => T] (x86_64's
# __seg_fs: T in fs), [vec => T, count node] (a vector, gcc's vector_size).

sub is_typeword {
    my ($w) = @_;
    exists $scalar{$w} || $w eq 'address' || $w eq 'array' || $w eq 'vector' || $w eq 'fs' || $rec{$w} || $enum{$w} || $fntype{$w};
}

# The type run at $$i of a list of nodes.
sub ptype {
    my ($l, $i) = @_;
    my $n = $l->[$$i] // fail('a type that ends early');
    my $w = c($n);
    $$i++;
    return [scalar => $w] if exists $scalar{$w};
    return [rec => $w] if $rec{$w};
    return [enum => $w] if $enum{$w};
    return [fn => $w] if $fntype{$w};
    if ($w eq 'address') {
        # address alone: the address of nothing, void *
        return [ptr => undef] if $$i >= @$l || !leaf($l->[$$i]) || !is_typeword(c($l->[$$i]));
        return [ptr => ptype($l, $i)];
    }
    return [fs => ptype($l, $i)] if $w eq 'fs';
    if ($w eq 'array') {
        my $t = ptype($l, $i);
        my $count = $l->[$$i++] // fail('an array without its count');
        return [arr => $t, $count];
    }
    if ($w eq 'vector') {
        my $t = ptype($l, $i);
        my $count = $l->[$$i++] // fail('a vector without its count');
        return [vec => $t, $count];
    }
    fail("not a type: $w", $n);
}
sub tstr { my ($t) = @_; join ' ', @$t }   # (for messages)

# A declarator: the type as C writes it around name.
sub cdecl {
    my ($t, $name, $count) = @_;
    $name //= '';
    my $k = $t->[0];
    return "$scalar{$t->[1]} $name" =~ s/\s+$//r if $k eq 'scalar';
    return "struct " . cid($t->[1]) . " $name" =~ s/\s+$//r if $k eq 'rec' && $rec{ $t->[1] }{kind} eq 'struct';
    return "union " . cid($t->[1]) . " $name" =~ s/\s+$//r if $k eq 'rec';
    return "enum " . cid($t->[1]) . " $name" =~ s/\s+$//r if $k eq 'enum';
    return cid($t->[1]) . " $name" =~ s/\s+$//r if $k eq 'fn';
    if ($k eq 'ptr') {
        my $to = $t->[1] // [scalar => 'void'];
        my $inner = "*$name";
        $inner = "($inner)" if $to->[0] eq 'arr';
        return cdecl($to, $inner);
    }
    # (C's qualifier after the type it qualifies: struct p __seg_fs *x,
    # struct p *__seg_fs *x)
    return cdecl($t->[1], "__seg_fs $name" =~ s/\s+$//r, $count) if $k eq 'fs';
    if ($k eq 'arr') {
        my $n = $count // count_text($t->[2]);
        return cdecl($t->[1], "$name\[$n\]");
    }
    # (a vector as clang spells it: __attribute__((__vector_size__(16 * sizeof(char)))) char)
    if ($k eq 'vec') {
        my $e = ctype($t->[1]);
        return "__attribute__((__vector_size__(" . count_text($t->[2]) . " * sizeof($e)))) $e $name" =~ s/\s+$//r;
    }
    die;
}
# An array's count: a number, a constant, or (a local's) a value.
sub count_text {
    my ($n) = @_;
    return '' if leaf($n) && c($n) eq '0' && our $extern_arrays;
    return cname(c($n)) if leaf($n) && $econst{ c($n) };
    return c($n) if leaf($n);
    expr_item([kids($n)]);
}
sub ctype { cdecl($_[0], '') }

# The fields of a record, with anonymous members (:) looked into.
sub fields {
    my ($name) = @_;
    my $r = $rec{$name} or return ();
    my @f;
    my $pad = 0;
    for my $f (kids($r->{node})) {
        my $w = c($f);
        next if $w eq 'struct' || $w eq 'union' || $w eq 'comment' || $w eq 'align';
        (my $fname = $w) =~ s/:$//;
        my @l = kids($f);
        my $i = 0;
        # (align n first: C's aligned attribute)
        my $al = @l && c($l[0]) eq 'align' && !leaf($l[0]) ? c((kids($l[0]))[0]) : undef;
        $i = 1 if defined $al;
        my $t = ptype(\@l, \$i);
        my $bits = $i < @l ? c($l[$i]) : undef;
        push @f, { name => $fname, type => $t, bits => $bits, align => $al };
    }
    @f;
}
my %fieldcache;
sub field {
    my ($rname, $f) = @_;
    for my $x (@{ $fieldcache{$rname} //= [fields($rname)] }) {
        return $x->{type} if $x->{name} eq $f;
        if ($x->{name} eq '' && $x->{type}[0] eq 'rec') { my $t = field($x->{type}[1], $f); return $t if $t }
    }
    undef;
}

# ---- what a name is ---------------------------------------------------------

our (@scope, $cur_fn, $cur_last);   # the locals' scopes; the function; its last parameter
sub local_type { my ($n) = @_; for my $s (reverse @scope) { return $s->{$n} if exists $s->{$n} } undef }
sub gtype {
    my ($n) = @_;
    return gtype($fn{$n}{target}) if $fn{$n} && $fn{$n}{kind} eq 'alias' && !$fn{ $fn{$n}{target} };
    my $v = $var{$n} or return undef;
    return $v->{type} //= [arr => gtype($v->{bound}), { content => '0', children => [] }] if $v->{bound};
    my @l = kids($v->{node});
    my $i = $v->{from};
    $v->{type} //= ptype(\@l, \$i);
}
# A function's return type, parameters and whether it is variadic.
sub sig {
    my ($n) = @_;
    my $f = $fn{$n} or return undef;
    return sig($f->{target}) if $f->{kind} eq 'alias';
    return $f->{sig} if $f->{sig};
    if ($f->{kind} eq 'asm') { return $f->{sig} = { ret => [scalar => 'long'], params => undef } }
    my @l = kids($f->{node});
    my $i = $f->{from};
    my $ret = ptype(\@l, \$i);
    return $f->{sig} = { ret => $ret, params => undef } if $f->{kind} eq 'weak';
    my (@p, $va);
    while ($i < @l) {
        my $p = $l[$i];
        if (leaf($p) && c($p) eq '...') { $va = 1; $i++; next }
        last unless c($p) =~ /^(.+):$/ && !leaf($p);
        my $pn = $1;
        my @pl = kids($p);
        my $j = 0;
        last unless is_typeword(c($pl[0]));
        my $t = ptype(\@pl, \$j);
        last if $j < @pl;      # a value after the type: a local, not a parameter
        push @p, [$pn, $t];
        $i++;
    }
    $f->{sig} = { ret => $ret, params => \@p, va => $va, body => $i };
}
sub fnptr_sig {
    my ($t) = @_;
    $t = $t->[1] if $t && $t->[0] eq 'ptr' && $t->[1];
    # (a function's own address, C's &f: its definition's result)
    return { ret => sig($t->[1])->{ret} } if $t && $t->[0] eq 'fndef' && sig($t->[1]);
    return undef unless $t && $t->[0] eq 'fn';
    my @l = kids($fntype{ $t->[1] });
    my $i = 1;
    my $ret = ptype(\@l, \$i);
    { ret => $ret };
}

# A name in C: a local's, else a global's, function's or constant's.
sub cname { my ($n) = @_; local_type($n) ? cid_local($n) : cid($n) }
my %localcid;
sub cid_local { my ($n) = @_; (my $s = $n) =~ s/'$//; $s =~ s/[^A-Za-z0-9_]/_/g; $s = "_$s" if $ckw{$s}; $s }

# ---- expressions ------------------------------------------------------------

my %prec = ('=' => 1, '+=' => 1, '-=' => 1, '*=' => 1, '/=' => 1, '%=' => 1, '&=' => 1, '|=' => 1,
    '^=' => 1, '<<=' => 1, '>>=' => 1, '?' => 1.5, '||' => 2, '&&' => 3, '|' => 4, '^' => 5, '&' => 6,
    '==' => 7, '!=' => 7, '<' => 8, '>' => 8, '<=' => 8, '>=' => 8, '<<' => 9, '>>' => 9,
    '+' => 10, '-' => 10, '*' => 11, '/' => 11, '%' => 11);
my %prefix = map { $_ => 1 } qw(- ! ~ ++ --);
sub isbin { my ($n) = @_; leaf($n) && exists $prec{ c($n) } }

# The items of a list of nodes: each an expression the operators join, or a
# node alone.
sub items {
    my (@n) = @_;
    my (@items, $cur, $want, $q);   # $want: an operand comes next; $q: the ?s open in the item
    for my $n (@n) {
        my $w = c($n);
        my $isop = leaf($n) && (exists $prec{$w} || ($w eq ':' && $q));
        if ($cur && $want) { push @$cur, $n; $q++ if leaf($n) && $w eq '?'; $q-- if leaf($n) && $w eq ':' && $q; $want = leaf($n) && ($prefix{$w} || $isop) ? 1 : 0; next }
        if ($cur && leaf($n) && ($w eq '++' || $w eq '--')) { push @$cur, $n; next }      # x ++
        if ($cur && $isop) { push @$cur, $n; $q++ if $w eq '?'; $q-- if $w eq ':'; $want = 1; next }
        push @items, $cur if $cur;
        $cur = [$n];
        $q = leaf($n) && $w eq '?' ? 1 : 0;
        $want = leaf($n) && ($prefix{$w} || exists $prec{$w}) ? 1 : 0;
    }
    push @items, $cur if $cur;
    @items;
}

# An expression: [C text, type or undef].
sub expr_item { (expr(@_))[0] }
sub expr {
    my ($nodes) = @_;
    my @t = @$nodes;
    my $pos = 0;
    my ($s, $t) = binary(\@t, \$pos, 0);
    fail('more after an expression', $t[$pos]) if $pos < @t;
    ($s, $t);
}
sub binary {
    my ($l, $pos, $min) = @_;
    my ($s, $t) = unary($l, $pos);
    while ($$pos < @$l) {
        my $op = $l->[$$pos];
        last unless isbin($op);
        my $w = c($op);
        my $p = $prec{$w};
        last if $p < $min;
        $$pos++;
        if ($w eq '?') {
            # c ? a : b, GNU's c ?: b
            if ($$pos < @$l && leaf($l->[$$pos]) && c($l->[$$pos]) eq ':') {
                $$pos++;
                my ($b, $bt) = binary($l, $pos, 1.5);
                ($s, $t) = ("($s ?: $b)", $t);
                next;
            }
            my ($a, $at) = binary($l, $pos, 1);
            leaf($l->[$$pos] // fail('a ? without its :')) && c($l->[$$pos]) eq ':' or fail('a ? without its :', $l->[$$pos]);
            $$pos++;
            my ($b, $bt) = binary($l, $pos, 1.5);
            ($s, $t) = ("($s ? $a : $b)", $at // $bt);
            next;
        }
        my $right = $p == 1 ? $p : $p + 1;       # = is right to left
        my ($r, $rt) = binary($l, $pos, $right);
        my $nt = $p == 1 ? $t : ($w eq '+' || $w eq '-') ? (is_ptr($t) && !is_ptr($rt) ? $t : $w eq '+' && is_ptr($rt) ? $rt : undef) : undef;
        ($s, $t) = ("($s $w $r)", $nt);
    }
    ($s, $t);
}
sub is_ptr { my ($t) = @_; $t = nofs($t); $t && ($t->[0] eq 'ptr' || $t->[0] eq 'arr') }
# a type without its fs (x86_64's __seg_fs: the same type in fs)
sub nofs { my ($t) = @_; $t = $t->[1] while $t && $t->[0] eq 'fs'; $t }
sub unary {
    my ($l, $pos) = @_;
    my $n = $l->[$$pos] // fail('an operand missing');
    if (leaf($n) && $prefix{ c($n) }) {
        $$pos++;
        my $w = c($n);
        my ($s, $t) = unary($l, $pos);
        return ("($w$s)", $w eq '++' || $w eq '--' ? $t : undef);
    }
    $$pos++;
    my ($s, $t) = operand($n);
    # x ++
    while ($$pos < @$l && leaf($l->[$$pos]) && (c($l->[$$pos]) eq '++' || c($l->[$$pos]) eq '--')) {
        $s = "($s" . c($l->[$$pos]) . ")";
        $$pos++;
    }
    ($s, $t);
}

# Text leaves as a C string.
sub cstring {
    my ($bytes, $wide) = @_;
    my $s = '';
    for my $c (unpack 'C*', $bytes) {
        $s .= $c == 34 ? '\\"' : $c == 92 ? '\\\\' : ($c >= 32 && $c < 127) ? chr($c) : sprintf('\\%03o', $c);
    }
    "\"$s\"";
}
sub text_of { my (@n) = @_; my $s = join '', map { c($_) } @n; utf8::encode($s) if utf8::is_utf8($s); $s }

# The items of a global's array, as numbers: a text global's bytes.
# A global's items, after its type
sub items_of { my ($n) = @_; my $v = $var{$n}; my @l = kids($v->{node}); my $i = $v->{from}; ptype(\@l, \$i); map { $_->{content} eq 'items' ? kids($_) : $_ } @l[$i .. $#l] }
sub global_items { my ($n) = @_; my $v = $var{$n} or return; my @l = kids($v->{node}); my $i = $v->{from}; ptype(\@l, \$i); map { $_->{content} =~ /^items$/ ? kids($_) : $_ } @l[$i .. $#l] }

sub operand {
    my ($n) = @_;
    my $w = c($n);
    my @k = kids($n);
    # a path from an expression: the node cut at the ., the rest a path
    if (my ($dot) = grep { leaf($k[$_]) && c($k[$_]) eq '.' } 0 .. $#k) {
        my ($s, $t) = operand({ content => $w, children => [@k[0 .. $dot - 1]] });
        # (a function's address with nothing after the . is called without arguments)
        if ($dot == $#k && (my $f = fnptr_sig($t))) { return ("($s)()", $f->{ret}) }
        return path("($s)", $t, [@k[$dot + 1 .. $#k]]);
    }
    if (!@k) {
        return ($w, [scalar => 'int']) if $w =~ /^-?(?:0x[0-9a-fA-F]+|\d+)$/;
        return ($w, [scalar => 'long double']) if $w =~ /^-?0x[0-9a-f.]+p[-+]\d+L$/i;
        return ($w, [scalar => $w =~ /f$/ ? 'float' : 'double']) if $w =~ /^-?0x[0-9a-f.]+p[-+]\d+f?$/i;
        return ('__builtin_va_arg_pack()', undef) if $w eq 'va_arg_pack';
        return ('__builtin_va_arg_pack_len()', undef) if $w eq 'va_arg_pack_len';
        return ('tp', [ptr => undef]) if $w eq 'tp';
        if (my $t = local_type($w)) { return (cid_local($w), $t) }
        return ("$w()", undef) if clang_builtin($w);
        # (a compound literal c2ff made a global of its own: the literal again)
        if ($w =~ / literal \d+$/ && $var{$w}) { my $t = gtype($w); return ('((' . ctype($t) . ')' . init_list($t, [items_of($w)]) . ')', $t) }
        if (my $t = gtype($w)) { return (cid($w), $t) }
        return (cid($w), [enum => $econst{$w}]) if $econst{$w};
        # a function named alone is called
        if (my $s = sig($w)) { return (callee($w) . '()', $s->{ret}) }
        fail("an unknown name $w");
    }
    if ($w eq ':') {
        my @e = elements(@k);
        # (its value is its last item's: a : there is one too, not a block)
        my @st = map { @$_ == 1 && c($_->[0]) eq ':' && !leaf($_->[0]) ? ['expr', operand($_->[0])] : stmt_of($_) } @e[0 .. $#e - 1];
        push @st, @{ $e[-1] } == 1 && c($e[-1][0]) eq ':' && !leaf($e[-1][0]) ? ['expr', operand($e[-1][0])] : stmt_of($e[-1]) if @e;
        return ("($st[0][1])", $st[0][2]) if @st == 1 && $st[0][0] eq 'expr';
        if (!grep { $_->[0] ne 'expr' } @st) { return ('(' . join(', ', map { $_->[1] } @st) . ')', $st[-1][2]) }
        my $last = $st[-1][0] eq 'expr' ? $st[-1][2] : undef;
        return ('({ ' . join(' ', map { $_->[0] eq 'expr' ? "$_->[1];" : $_->[1] } @st) . ' })', $last);
    }
    if ($w eq 'address') {
        # (a : around one item is that item: address / : / free is &(free))
        @k = kids($k[0]) while @k == 1 && c($k[0]) eq ':' && kids($k[0]) == 1;
        my $f = $k[0];
        if (leaf($f) && is_typeword(c($f)) && !local_type(c($f)) && !gtype(c($f))) {
            my $i = 0;
            my $t = ptype(\@k, \$i);
            my @rest = @k[$i .. $#k];
            if ($t->[0] eq 'scalar' && ($t->[1] eq 'char' || $t->[1] eq 'u8') && @rest && !grep { !leaf($_) } @rest) {
                return (cstring(text_of(@rest)), [ptr => $t]);
            }
            @rest or fail('address of a type without a value', $n);
            my ($v) = expr([@rest]);
            return ("((" . ctype([ptr => $t]) . ")($v))", [ptr => $t]);
        }
        if (!leaf($f) && exists $scalar{ c($f) } && !local_type(c($f)) && @k == 1) {
            # (a scalar's: C's &(unsigned int){0})
            return ('(&(' . ctype([scalar => c($f)]) . '){' . expr_item([kids($f)]) . '})', [ptr => [scalar => c($f)]]);
        }
        if (!leaf($f) && is_typeword(c($f)) && !local_type(c($f)) && !gtype(c($f)) && @k == 1) {
            # a typed literal's or a compound literal's address
            my ($s, $t) = operand($f);
            return ("(&$s)", [ptr => $t]);
        }
        # a text c2ff made a global: the string again
        if (@k == 1 && c($f) =~ /^text \d+$/ && kids($f) == 1 && c((kids($f))[0]) eq '0') {
            my @b = map { c($_) } global_items(c($f));
            pop @b if @b && $b[-1] eq '0';
            return (cstring(pack 'C*', @b), [ptr => [scalar => 'char']]);
        }
        if (@k == 1 && leaf($f) && c($f) =~ /^wide text \d+$/) {
            my $t = gtype(c($f));
            my @e = map { c($_) } global_items(c($f));
            my $p = { 'u32' => 'U', 'int' => 'L', 'u16' => 'u' }->{ $t->[1][1] } // 'L';
            return ($p . '"' . join('', map { sprintf '\\x%x', $_ } @e) . '"', [ptr => $t->[1]]);
        }
        # a label's address (GNU C's &&L); a function's
        if (@k == 1 && leaf($f) && !local_type(c($f)) && our $labels->{ c($f) }) { return ('(&&' . cid_local(c($f)) . ')', [ptr => undef]) }
        if (@k == 1 && leaf($f) && !local_type(c($f)) && !gtype(c($f)) && sig(c($f))) { return ('(&' . callee(c($f)) . ')', [ptr => [fndef => c($f)]]) }
        # a name c2ff left out (an asm variant no milestone has): as an asm function
        if (@k == 1 && leaf($f) && !local_type(c($f)) && !gtype(c($f)) && !$econst{ c($f) }) { $fn{ c($f) } = { kind => 'asm', missing => 1 }; push @order, c($f); return ('(&' . cid(c($f)) . ')', [ptr => undef]) }
        my ($s, $t) = expr([@k]);
        return ("(&$s)", [ptr => $t]);
    }
    # a complex value's parts: C's __real__ and __imag__
    if ($w eq 'real' || $w eq 'imag') {
        my ($s, $t) = expr([@k]);
        return ("(__${w}__ ($s))", $t && $t->[0] eq 'scalar' && $t->[1] =~ /^complex (.+)$/ ? [scalar => $1] : undef);
    }
    if ($w eq 'content') {
        my ($s, $t) = expr([@k]);
        my $to = $t && $t->[0] eq 'ptr' ? $t->[1] : $t && $t->[0] eq 'arr' ? $t->[1] : undef;
        return ("(*$s)", $to);
    }
    # C11's _Generic: an association's name is its type, address as often as
    # it says and then one type name
    if ($w eq 'generic') {
        my ($x, @as) = @k;
        my ($xs) = expr([$x]);
        my (@parts, $rt);
        for my $as (@as) {
            (my $name = c($as)) =~ s/:$//;
            my ($v, $vt) = expr([kids($as)]);
            $rt //= $vt;
            if ($name eq 'default') { push @parts, "default: $v"; next }
            my @w;
            push @w, { content => 'address', children => [] } while $name =~ s/^address (?=.)//;
            push @w, { content => $name, children => [] };
            my $i = 0;
            push @parts, ctype(ptype(\@w, \$i)) . ": $v";
        }
        return ("_Generic($xs, " . join(', ', @parts) . ")", $rt);
    }
    if ($w eq 'cast:') {
        my $i = 0;
        my $t = ptype(\@k, \$i);
        my ($v) = expr([@k[$i .. $#k]]);
        return ("((" . ctype($t) . ")($v))", $t);
    }
    if ($w eq 'sizeof' || $w eq 'alignof') {
        # of a variable (a variable-length array's)
        if (@k == 1 && leaf($k[0]) && (local_type(c($k[0])) || gtype(c($k[0])))) {
            return (($w eq 'sizeof' ? 'sizeof' : '_Alignof') . '(' . (operand($k[0]))[0] . ')', [scalar => 'u64']);
        }
        my $i = 0;
        my $t = ptype(\@k, \$i);
        return (($w eq 'sizeof' ? 'sizeof' : '_Alignof') . '(' . ctype($t) . ')', [scalar => 'u64']);
    }
    # an array compound literal: array / its element's type / its count / items
    if ($w eq 'array' || $w eq 'vector') {
        my @l = ({ content => $w, children => [] }, @k);
        my $i = 0;
        my $t = ptype(\@l, \$i);
        return ('((' . ctype($t) . ')' . init_list($t, [@l[$i .. $#l]]) . ')', $t);
    }
    if ($w eq 'syscall') { return ('__ff_syscall(' . join(', ', map { expr_item($_) } items(@k)) . ')', [scalar => 'long']) }
    if ($w eq 'va_arg') {
        my @i = items(@k);
        my $ap = expr_item(shift @i);
        my $j = 0;
        my $t = ptype([map { @$_ } @i], \$j);
        return ("__builtin_va_arg($ap, " . ctype($t) . ")", $t);
    }
    return ('__builtin_va_start(' . expr_item([@k]) . ", $cur_last)", undef) if $w eq 'va_start';
    return ('__builtin_va_end(' . expr_item([@k]) . ')', undef) if $w eq 'va_end';
    return ('__builtin_va_copy(' . join(', ', map { expr_item($_) } items(@k)) . ')', undef) if $w eq 'va_copy';
    return ('__builtin_alloca(' . expr_item([@k]) . ')', [ptr => undef]) if $w eq 'alloca';
    # a type with a value: a typed literal, a conversion, a compound literal
    if (exists $scalar{$w} && !local_type($w)) {
        my $t = [scalar => $w];
        if (@k == 1 && leaf($k[0]) && c($k[0]) =~ /^\d+$|^0x[0-9a-f]+$/i) {
            my $sfx = { u64 => 'UL', long => 'L', i64 => 'LL', u32 => 'U', int => '' }->{$w};
            return (c($k[0]) . $sfx, $t) if defined $sfx;
        }
        my ($v) = expr([@k]);
        return ("((" . ctype($t) . ")($v))", $t);
    }
    if ($rec{$w} && !local_type($w) && !gtype($w)) {
        my $t = [rec => $w];
        return ("((" . ctype($t) . ")" . init_list($t, [@k]) . ")", $t);
    }
    # a call
    # (x86_64's pcmpistri of an immediate, c2ff's of gcc's _mm_cmpistri,
    # _mm_cmpistrc, _mm_cmpistrz: those again, the immediate last)
    if ($w =~ /^__builtin_ia32_pcmpistr(i|ic|iz)128 (0x[0-9a-f]+)$/) {
        my $f = '_mm_cmpistr' . { i => 'i', ic => 'c', iz => 'z' }->{$1};
        return ("$f(" . join(', ', (map { expr_item($_) } items(@k)), $2) . ')', [scalar => 'int']);
    }
    if (!local_type($w) && !gtype($w) && (sig($w) || $w =~ /^__builtin_/)) {
        my $s = sig($w);
        return (callee($w) . '(' . join(', ', map { expr_item($_) } items(@k)) . ')', $s ? $s->{ret} : undef);
    }
    # a path from a variable
    my ($s, $t) = operand({ content => $w, children => [] });
    path($s, $t, [@k]);
}

# A function's name as called: a builtin's as clang has it.
sub callee {
    my ($w) = @_;
    return $1 if $w =~ /^(__builtin_\w+)(?: .*)?$/;
    return $w if clang_builtin($w);
    cid($w);
}

# Elements and fields after a value: s the C so far, t its type.
sub path {
    my ($s, $t, $l) = @_;
    my @l = @$l;
    while (@l) {
        my $n = $l[0];
        $t = nofs($t);
        my $pt = $t && $t->[0] eq 'ptr' ? nofs($t->[1]) : undef;
        my $rt = $t && $t->[0] eq 'rec' ? $t->[1] : $pt && $pt->[0] eq 'rec' ? $pt->[1] : undef;
        if (defined $rt && leaf($n) && (my $ft = field($rt, c($n)))) {
            $s = "($s" . ($t->[0] eq 'ptr' ? '->' : '.') . cid_local(c($n)) . ")";
            $t = $ft;
            shift @l;
            next;
        }
        if (my $f = fnptr_sig($t)) {
            # through a function's address: the rest are its arguments
            return ("($s)(" . join(', ', map { expr_item($_) } items(@l)) . ")", $f->{ret});
        }
        my ($first) = items(@l);
        splice @l, 0, scalar @$first;
        my ($i) = expr($first);
        $s = "($s\[$i\])";
        $t = $t && ($t->[0] eq 'ptr' || $t->[0] eq 'arr') ? $t->[1] : undef;
    }
    ($s, $t);
}

# The items of an initializer of type t, as C's braces.
sub init_list {
    my ($t, $l) = @_;
    my @i = map { c($_) eq 'items' ? kids($_) : $_ } @$l;
    my @items = items(@i);
    # a char array set from text
    if ($t->[0] eq 'arr' && $t->[1][0] eq 'scalar' && $t->[1][1] =~ /^(char|u8|i8)$/ && @i && !grep { !leaf($_) || c($_) =~ /^-?(?:0x[0-9a-f]+|\d+)$/i } @i) {
        return cstring(text_of(@i));
    }
    my @fl = $t->[0] eq 'rec' ? @{ $fieldcache{ $t->[1] } //= [fields($t->[1])] } : ();
    @fl = grep { !defined $_->{bits} || $_->{name} !~ /^padding \d+$/ } @fl;
    my @parts;
    for my $k (0 .. $#items) {
        # (a flexible array member, the last field, array T 0, takes the items after it)
        if ($t->[0] eq 'rec' && $k == $#fl && $fl[$k]{type}[0] eq 'arr' && c($fl[$k]{type}[2]) eq '0' && $k < $#items) {
            push @parts, '{' . join(', ', map { init_item($fl[$k]{type}[1], $_) } @items[$k .. $#items]) . '}';
            last;
        }
        my $et = $t->[0] =~ /^(?:arr|vec)$/ ? $t->[1] : $fl[$k] ? $fl[$k]{type} : undef;
        push @parts, init_item($et, $items[$k]);
    }
    # a union set through a member not its first: ttpc sets by place, zeros first
    if ($t->[0] eq 'rec' && $rec{ $t->[1] }{kind} eq 'union' && @parts > 1) {
        return '{ .' . cid_local($fl[$#parts]{name}) . " = $parts[-1] }";
    }
    '{' . join(', ', @parts) . '}';
}
sub init_item {
    my ($t, $it) = @_;
    if (@$it == 1 && c($it->[0]) eq ':' && $t && ($t->[0] eq 'rec' || $t->[0] eq 'arr')) { return init_list($t, [kids($it->[0])]) }
    expr_item($it);
}

# ---- statements -------------------------------------------------------------

my %stmtword = map { $_ => 1 } ('if', 'else', 'else if', 'while', 'do while', 'for', 'switch', 'case', 'default',
    'return', 'goto', 'break', 'continue', 'comment');

# The elements of a body: statement nodes, declarations, labels, and
# expression items.
sub elements {
    my (@n) = @_;
    my @e;
    my @run;
    for my $n (@n) {
        my $w = c($n);
        my $is_stmt = $stmtword{$w} && !(local_type($w)) || ($w =~ /.:$/ && $w ne 'cast:');
        if ($is_stmt && (!@run || !(isbin($run[-1]) || ($prefix{ c($run[-1]) } && leaf($run[-1]))))) {
            push @e, items(@run) if @run;
            @run = ();
            push @e, [$n];
            next;
        }
        push @run, $n;
    }
    push @e, items(@run) if @run;
    @e;
}

my $ind = '    ';
# One element as C: [kind, text, type].
sub stmt_of {
    my ($e) = @_;
    my $n = $e->[0];
    my $w = c($n);
    if (@$e == 1 && $w =~ /^(.+):$/ && $w ne ':' && $w ne 'cast:') {
        my $name = $1;
        my @k = kids($n);
        if (@k && leaf($k[0]) && is_typeword(c($k[0])) && !local_type(c($k[0]))) { return ['decl', decl($name, $n)] }
        # a label: its statements after it
        my @s = map { stmt_of($_) } elements(@k);
        return ['stmt', cid_local($name) . ': ' . (@s ? join(' ', map { text($_) } @s) : ';')];
    }
    if (@$e == 1 && $stmtword{$w}) { return ['stmt', control($n)] }
    if (@$e == 1 && $w eq ':' ) {
        push @scope, {};
        my @s = map { stmt_of($_) } elements(kids($n));
        pop @scope;
        # (a : as a statement is a block)
        return ['stmt', '{ ' . join(' ', map { text($_) } @s) . ' }'];
    }
    my ($s, $t) = expr($e);
    ['expr', $s, $t];
}
sub text { my ($s) = @_; $s->[0] eq 'expr' ? "$s->[1];" : $s->[1] }
sub block {
    my (@n) = @_;
    push @scope, {};
    my @s = map { text(stmt_of($_)) } elements(@n);
    pop @scope;
    '{ ' . join(' ', @s) . ' }';
}

sub decl {
    my ($name, $n) = @_;
    my @k = kids($n);
    my $i = 0;
    my $t = ptype(\@k, \$i);
    my @init = @k[$i .. $#k];
    my $vla;
    if ($t->[0] eq 'arr' && !(leaf($t->[2]) && (c($t->[2]) =~ /^\d+$/ || $econst{ c($t->[2]) }))) { $vla = 1 }
    $scope[-1]{$name} = $t;
    my $d = cdecl($t, cid_local($name));
    return "$d;" unless @init;
    if ($t->[0] eq 'arr' || ($t->[0] eq 'rec' && !copy_of($t, \@init))) { return "$d = " . init_list($t, \@init) . ';' }
    "$d = " . expr_item([@init]) . ';';
}
# Whether a struct's one item is a value of its type (a copy).
sub copy_of {
    my ($t, $init) = @_;
    my @i = items(@$init);
    return 0 unless @i == 1;
    return 0 if @{ $i[0] } == 1 && c($i[0][0]) eq ':';
    my (undef, $it) = eval { expr($i[0]) };
    $it && $it->[0] eq 'rec' && $it->[1] eq $t->[1];
}

our @pending_else;
sub control {
    my ($n) = @_;
    my $w = c($n);
    my @k = kids($n);
    return 'break;' if $w eq 'break';
    return 'continue;' if $w eq 'continue';
    return '' if $w eq 'comment';
    if ($w eq 'return') { return @k ? 'return ' . expr_item([@k]) . ';' : 'return;' }
    if ($w eq 'goto') {
        return 'goto *' . expr_item([kids($k[0])]) . ';' if c($k[0]) eq 'content';
        return 'goto ' . cid_local(c($k[0])) . ';';
    }
    if ($w eq 'if' || $w eq 'else if') {
        my ($cond, @rest) = items_head(@k);
        return ($w eq 'else if' ? 'else if' : 'if') . ' (' . expr_item($cond) . ') ' . block(@rest);
    }
    return 'else ' . block(@k) if $w eq 'else';
    if ($w eq 'while') { my ($cond, @rest) = items_head(@k); return 'while (' . expr_item($cond) . ') ' . block(@rest) }
    if ($w eq 'do while') { my ($cond, @rest) = items_head(@k); return 'do ' . block(@rest) . ' while (' . expr_item($cond) . ');' }
    if ($w eq 'for') {
        push @scope, {};
        my @e = elements(@k);
        my @part = splice @e, 0, 3;
        # (an empty : an empty part; one with items their value, C's comma)
        my @p = map { my $x = $_; @$x == 1 && c($x->[0]) eq ':' ? (leaf($x->[0]) ? '' : (operand($x->[0]))[0]) : do { my $s = stmt_of($x); $s->[0] eq 'decl' ? $s->[1] =~ s/;$//r : $s->[1] } } @part;
        my $body = block(map { @$_ } @e);
        pop @scope;
        return "for ($p[0]; $p[1]; $p[2]) $body";
    }
    if ($w eq 'switch') {
        my ($v, @rest) = items_head(@k);
        push @scope, {};
        my @s = map { text(stmt_of($_)) } elements(@rest);
        pop @scope;
        return 'switch (' . expr_item($v) . ') { ' . join(' ', @s) . ' }';
    }
    if ($w eq 'case') {
        my @e = elements(@k);
        my $head = 'case ' . expr_item(shift @e);
        if (@e && @{ $e[0] } == 1 && c($e[0][0]) eq '...') { shift @e; $head .= ' ... ' . expr_item(shift @e) }
        my @s = map { text(stmt_of($_)) } @e;
        return "$head: " . (@s ? join(' ', @s) : ';');
    }
    if ($w eq 'default') { my @s = map { text(stmt_of($_)) } elements(@k); return 'default: ' . (@s ? join(' ', @s) : ';') }
    fail("the statement $w", $n);
}
# The first item of a list, then the nodes after it.
sub items_head {
    my (@k) = @_;
    my ($first) = items(@k);
    ($first, @k[scalar(@$first) .. $#k]);
}

# ---- the unit ---------------------------------------------------------------

my @c;
push @c, '/* made by ff2c.pl from ' . ($in =~ s{.*/}{}r) . ' */';
# the header of each file, as the file has it (gen/headers.pl checks them)
push @c, map { ("/* ff2c: the header of $_->[0] */", Header::header_text(@{ $_->[1] })) } @headers;
push @c, '/* ff2c: the end of the headers */' if @headers;
push @c, 'long __ff_syscall(long, ...);', 'extern void *tp;';
# (gcc's SSE4.2 compares of an immediate, <smmintrin.h>'s, whose calls c2ff makes builtins)
push @c, map { "int _mm_cmpistr$_(__attribute__((__vector_size__(2 * sizeof(long long)))) long long, __attribute__((__vector_size__(2 * sizeof(long long)))) long long, const int);" } qw(i c z);
# the records first as names, so that each may point at any
push @c, map { "$rec{$_}{kind} " . cid($_) . ';' } grep { $rec{$_} } @order;
# the enums: a constant's value where it has one
# (a constant two enums of the tree have is the first's: C has one of each)
for my $e (grep { $enum{$_} } @order) {
    my @k = kids($enum{$e});
    my @cs = grep { c($_) =~ /:$/ && $econst{ c($_) =~ s/:$//r } eq $e } map { c($_) eq 'items' ? kids($_) : $_ } @k[1 .. $#k];
    push @c, 'enum ' . cid($e) . ' { ' . (@cs ? join(', ', map { my @v = kids($_); cid(c($_) =~ s/:$//r) . (@v ? ' = ' . join('', map { c($_) } @v) : '') } @cs) : cid($e) . '__none') . ' };';
}
# the function types
for my $f (grep { $fntype{$_} } @order) {
    my @l = kids($fntype{$f});
    my $i = 1;
    my $ret = ptype(\@l, \$i);
    my (@p, $va);
    for my $p (@l[$i .. $#l]) {
        if (c($p) eq '...') { $va = 1; next }
        my @pl = kids($p);
        my $j = 0;
        push @p, ctype(ptype(\@pl, \$j));
    }
    push @p, '...' if $va;
    push @c, 'typedef ' . cdecl($ret, cid($f) . '(' . (@p ? join(', ', @p) : 'void') . ')') . ';';
}
# the records' fields, each after those it holds by value
my %rdone;
sub rec_deps {
    my ($r) = @_;
    for my $f (@{ $fieldcache{$r} //= [fields($r)] }) {
        my $t = $f->{type};
        $t = $t->[1] while $t->[0] eq 'arr';
        next unless $t->[0] eq 'rec';
        # an anonymous member is written where it stands: what it holds first
        if ($f->{name} eq '') { rec_deps($t->[1]) } else { emit_rec($t->[1]) }
    }
}
# A record's fields in braces; an anonymous member (C11's) as its own
# fields in braces of their own, as C writes one
sub rec_body {
    my ($r) = @_;
    my @fl = @{ $fieldcache{$r} //= [fields($r)] };
    '{ ' . join(' ', map {
        my $f = $_;
        # (the last field, array T 0, is a flexible array member: T x[])
        local our $extern_arrays = $f == $fl[-1];
        if ($f->{name} eq '' && $f->{type}[0] eq 'rec') { "$rec{ $f->{type}[1] }{kind} " . rec_body($f->{type}[1]) . ';' }
        else {
            my $nm = $f->{name} =~ /^padding \d+$/ && defined $f->{bits} ? '' : cid_local($f->{name});
            cdecl($f->{type}, $nm) . (defined $f->{bits} ? " : $f->{bits}" : '') . (defined $f->{align} ? " __attribute__((aligned($f->{align})))" : '') . ';';
        }
    } @fl) . ' }';
}
sub emit_rec {
    my ($r) = @_;
    return if $rdone{$r}++;
    rec_deps($r);
    # (a record's own align, after struct: C's aligned attribute after its braces)
    my ($al) = map { c((kids($_))[0]) } grep { c($_) eq 'align' && !leaf($_) } kids($rec{$r}{node});
    push @c, "$rec{$r}{kind} " . cid($r) . ' ' . rec_body($r) . (defined $al ? " __attribute__((aligned($al)))" : '') . ';';
}
emit_rec($_) for grep { $rec{$_} } @order;
# the globals
{
    local our $extern_arrays = 1;
    for my $v (grep { $var{$_} && !clang_builtin($_) } @order) {
        my $t = gtype($v);
        push @c, ($var{$v}{tls} ? 'extern __thread ' : 'extern ') . cdecl($t, cid($v)) . ($var{$v}{weak} ? ' __attribute__((weak))' : '') . ';';
    }
}
# the functions
sub proto {
    my ($name) = @_;
    my $s = sig($name);
    my $ps = !defined $s->{params} ? '' : @{ $s->{params} } || $s->{va} ? join(', ', (map { ctype($_->[1]) } @{ $s->{params} }), $s->{va} ? '...' : ()) : 'void';
    cdecl($s->{ret}, cid($name) . "($ps)");
}
for my $f (grep { $fn{$_} && $fn{$_}{kind} ne 'alias' && !clang_builtin($_) } @order) {
    push @c, proto($f) . ($fn{$f}{kind} eq 'weak' ? ' __attribute__((weak))' : '') . ($fn{$f}{ctor} ? " __attribute__(($fn{$f}{ctor}))" : '') . ';';
}
for my $f (grep { $fn{$_} && $fn{$_}{kind} eq 'alias' } @order) {
    my $t = $fn{$f}{target};
    push @c, $var{$t} ? "extern __typeof__(" . cid($t) . ") " . cid($f) . ';' : proto($f) . ';';
}
# the glibc pages' globals, with their items (but those c2ff makes of a
# text or a compound literal, which come back where they are named)
my @gnames;
for my $v (grep { $var{$_} && $var{$_}{glibc} && !$var{$_}{weak} && $_ !~ /^(?:wide )?text \d+$| literal \d+$/ } @order) {
    my $t = gtype($v);
    my @items = items_of($v);
    my $init = !@items ? '' : ($t->[0] eq 'arr' || $t->[0] eq 'rec') ? ' = ' . init_list($t, \@items) : ' = ' . expr_item([map { c($_) eq 'items' ? kids($_) : $_ } @items]);
    local $cur_fn = $v;
    my $sec = $var{$v}{section} ? " __attribute__((section(\"$var{$v}{section}\")))" : '';
    $sec .= " __attribute__((aligned($var{$v}{align})))" if defined $var{$v}{align};
    my $ok = eval { push @c, ($var{$v}{tls} ? '__thread ' : '') . cdecl($t, cid($v)) . "$sec$init;"; 1 };
    warn $@ unless $ok;
    # (where glibc has it: a unit's own static in that unit, a function's static in that function)
    my $hint = $v =~ /^\S+ (\S+\/\S+)$/ ? "unit $1" : $v =~ /^(\S+) \S+$/ && $fn{$1} ? 'in ' . orig($1) : '-';
    push @gnames, join("\t", $ok ? 'global' : 'gfailed', cid($v), orig($v), $hint);
}
# the bodies
my (@names, @cbody);
push @names, @gnames;
for my $f (grep { $glibcpage{$_} } @order) {
    local $cur_fn = $f;
    my $s = sig($f);
    my @l = kids($fn{$f}{node});
    my ($unit) = map { c((kids($_))[0]) =~ /^glibc-\S+ (\S+)$/ ? $1 : () } grep { c($_) eq 'comment' } @l[$s->{body} .. $#l];
    local @scope = ({ map { ($_->[0] => $_->[1]) } @{ $s->{params} } });
    local $cur_last = @{ $s->{params} } ? cid_local($s->{params}[-1][0]) : '';
    local our $labels = { map { $_ => 1 } labels_in(@l[$s->{body} .. $#l]) };
    my $ps = @{ $s->{params} } || $s->{va} ? join(', ', (map { cdecl($_->[1], cid_local($_->[0])) } @{ $s->{params} }), $s->{va} ? '...' : ()) : 'void';
    my $body = eval { block(@l[$s->{body} .. $#l]) };
    if (!defined $body) { warn $@; push @names, join("\t", 'failed', cid($f), orig($f), $unit // '-'); next }
    push @cbody, cdecl($s->{ret}, cid($f) . "($ps)") . " $body";
    push @names, join("\t", 'body', cid($f), orig($f), $unit // '-');
}
# clang's own builtins, which C does not declare
sub clang_builtin { $_[0] =~ /^__builtin_|^__atomic_(?:always_lock_free|is_lock_free|thread_fence|signal_fence)$/ }
# The labels of a body: name: nodes that are no declaration
sub labels_in {
    map {
        my $n = $_;
        my @k = kids($n);
        (c($n) =~ /^(.+):$/ && c($n) ne 'cast:' && !(@k && leaf($k[0]) && is_typeword(c($k[0]))) ? "$1" : ()), labels_in(@k)
    } @_;
}
# The name a function had in C: without c2ff's ' and its unit.
sub orig {
    my ($n) = @_;
    return $1 if $n =~ /^(\S+) \S+\/\S+$/;
    # a function's static: its own name
    return $2 =~ s/'$//r if $n =~ /^(\S+) (\S+)$/ && $fn{$1};
    $n =~ s/'$//r;
}

# (the names c2ff left out, found in the bodies, before them)
push @c, map { 'long ' . cid($_) . '();' } grep { $fn{$_} && $fn{$_}{missing} } @order;
push @c, @cbody;
open my $h, '>', $out or die "ff2c: $out: $!\n";
print $h join("\n", @c), "\n";
close $h;
push @names, map { join("\t", 'name', cid($_), orig($_)) } grep { $var{$_} || $fn{$_} } @order;
# (and the enum constants c2ff named with their unit: C's name for them)
push @names, map { join("\t", 'name', cid($_), orig($_)) } grep { /^\S+ \S+\/\S+$/ } sort keys %econst;
push @names, map { join("\t", 'asm', cid($_), orig($_)) } grep { $fn{$_} && $fn{$_}{kind} eq 'asm' } @order;
# (and the aliases of asm functions, which C calls as they are: aarch64's
# stpcpy of __stpcpy)
sub asm_target { my ($n, $d) = @_; return 0 if $d > 8 || !$fn{$n}; return 1 if $fn{$n}{kind} eq 'asm'; $fn{$n}{kind} eq 'alias' && asm_target($fn{$n}{target}, $d + 1) }
push @names, map { join("\t", 'asm', cid($_), orig($_)) } grep { $fn{$_} && $fn{$_}{kind} eq 'alias' && asm_target($_, 0) } @order;
open $h, '>', $namesout or die "ff2c: $namesout: $!\n";
print $h map { "$_\n" } @names;
close $h;
