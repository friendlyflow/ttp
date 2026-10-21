# Words.pm — the C words of ff, before and now (the user's, 2026-10-20),
# for the host tools: newwords rewrites a tree of before into them
# (gen/newwords.pl), oldwords a tree in them back into the words of before,
# which the frozen ttpcs (stage0, the seeds, ttpc1, ttpc2, ttpc3) read
# (FF.pm unlicense gives them every tree so).
#
#   before                          now
#   address / x                     x, & address            C's &x
#   content / p                     p, * pointer            C's *p
#   address / char                  char / * pointer        char *
#   address (alone)                 void / * pointer        void *
#   array / int / 3                 (array / int / 3)       int [3]
#   array / address / char / 5      (array / char / * pointer / 5)
#   address / array / int / 4       (array / int / 4) / * pointer   int (*)[4]
#   cast: / T / v, long / x         (cast / T), v           (T) v
#   u64 / 2, long / 5, u32 / 7      ULL, 2  L, 5  U, 7      2ULL 5L 7U
#   address / char / p              (cast / char / * pointer), (: / p)
#   address / char / hi             (cast / char / * pointer), hi   "hi"
#   point / 1                       point, 1, 0             (point){1}
#   array / T / 3 / a / b           (array / T / 3), a, b, 0  (T[3]){a, b}
#   padding 1: / u32 / 4            : / u32 / 4             unsigned : 4
#
# Siblings in a row (a, b) are what before was one node. cast and the
# suffixes U L UL LL ULL are prefixes, their operand the next sibling;
# * pointer and & address postfixes, after their operand, as ++ (applied
# left to right); an operand of several (a run) goes in a :, and a path
# after one in a : that holds it. A type run is its base and the
# * pointer leaves after it. A compound literal is its type, then an item
# for each of its places, in a row: a struct's named fields (an anonymous
# member's in place, padding none), an array's elements; a union's is the
# union, a field's name and its item. A place that is a struct, a union or
# an array takes its own type and items in turn, a zero one zeros.
#
# A host tool (core Perl only), not part of ttpc.

package Words;

use strict;
use warnings;

sub node { my ($content, @children) = @_; { content => $content, children => \@children } }
sub layers { require FF; FF::layers(@_) }
sub leaf { !@{ $_[0]{children} } }
sub kids { @{ $_[0]{children} } }
sub is { my ($n, $w) = @_; $n && leaf($n) && $n->{content} eq $w }
# a _Generic association's name, before and now
sub gen_new { my ($w) = @_; my $n = 0; $w = "address void:" if $w eq "address:"; $n++ while $w =~ s/^address (?=.)//; $w =~ s/:$//; $w . (' * pointer' x $n) . ':' }
sub gen_old { my ($w) = @_; my $n = 0; $w =~ s/:$//; $n++ while $w =~ s/(?<=.) \* pointer$//; ('address ' x $n) . $w . ':' }

my %scalarword = map { $_ => 1 } ('char', 'short', 'int', 'long', 'i8', 'i16', 'i32', 'i64',
    'u8', 'u16', 'u32', 'u64', 'void', 'type', 'va_list', 'float', 'double', 'long double');
# ttpc's operators (cc_ops), as items() classes them
my @ops = qw(= += -= || && | ^ & == != < > <= >= << >> + - * / % ++ -- ! ~ *= /= %= &= |= ^= <<= >>= ?);
my %opix = map { $ops[$_] => $_ } 0 .. $#ops;
my %suffix = (U => 'u32', L => 'long', UL => 'u64', LL => 'i64', ULL => 'u64');
my %tosuffix = (u32 => 'U', long => 'L', u64 => 'ULL', i64 => 'LL');
my $num = qr/^-?(?:\d+|0x[0-9a-fA-F]+)$/;

# The types a tree has: its struct, union, enum and function names, and of
# each struct or union its fields (name, type run as written, padding?).
sub typenames {
    my ($t, @n) = @_;
    $t->{word}{$_} = 1 for keys %scalarword;
    for my $n (@n) {
        my @k = kids($n);
        my ($name) = $n->{content} =~ /^(.+):$/;
        if (defined $name && @k && leaf($k[0]) && $k[0]{content} =~ /^(?:struct|union|enum|function)$/) {
            my $kind = $k[0]{content};
            $t->{word}{$name} = 1;
            $t->{rec}{$name} = { kind => $kind, fields => [map { field($t, $_) } grep { $_->{content} =~ /:$/ } @k[1 .. $#k]] }
                if $kind eq 'struct' || $kind eq 'union';
        }
        typenames($t, @k);
    }
    $t;
}
sub field {
    my ($t, $f) = @_;
    my $name = $f->{content} =~ s/:$//r;
    my @run = kids($f);
    my $pad = $name =~ /^padding \d+$/ || $name eq '' && @run && leaf($run[0]) && $scalarword{ $run[0]{content} };
    { name => $name, run => \@run, pad => $pad ? 1 : 0, anon => $name eq '' && !$pad ? 1 : 0 };
}
sub newtypes { my ($t) = @_; my %c = %$t; $c{word} = { %{ $t->{word} || {} } }; $c{rec} = { %{ $t->{rec} || {} } }; \%c }

sub has_newwords {
    my ($n) = @_;
    return 1 if $n->{content} =~ /^(?:\* pointer|& address):?$/ || $n->{content} =~ / \* pointer:$/ || $n->{content} eq 'cast' && !leaf($n);
    # (a declaration's type an array node: before, array was a leaf there)
    if ($n->{content} =~ /.:$/) { my @k = kids($n); my $i = marks(\@k); return 1 if $i < @k && $k[$i]{content} eq 'array' && !leaf($k[$i]) }
    for (kids($n)) { return 1 if has_newwords($_) }
    0;
}

# ---------------------------------------------------------------------------
# The items of a run: where the one at $i ends. As ttpc's items(): an
# operand begins one, unless an operator before it joins them; ! ~ (and now
# the prefixes) begin one before an operand; ++ -- and else, else if are
# neither; ? ... : joins. $lit (the new words): a compound literal's head
# and its items are one operand.
sub is_prefix { my ($n) = @_; leaf($n) && $suffix{ $n->{content} } || $n->{content} eq 'cast' && !leaf($n) }
sub is_post { my ($n) = @_; $n && leaf($n) && ($n->{content} eq '* pointer' || $n->{content} eq '& address') }
sub item_end {
    my ($l, $i, $t, $lit) = @_;
    my ($want, $q) = (1, 0);
    while ($i < @$l) {
        my $n = $l->[$i];
        my $op = leaf($n) && exists $opix{ $n->{content} } ? $opix{ $n->{content} } : -1;
        if ($op >= 0) {
            if ($op == 33) { $q++; $want = 1 }
            elsif ($op == 21 || $op == 22) { }
            elsif ($op >= 25 || $op <= 20) { $want = 1 }
            else { return $i if !$want; $want = 1 }
            $i++;
            next;
        }
        if ($q && is($n, ':')) { $q--; $want = 1; $i++; next }
        if ($n->{content} eq 'else' || $n->{content} eq 'else if' || $lit && is_post($n)) { $i++; next }
        if ($lit && is_prefix($n)) { return $i if !$want; $want = 1; $i++; next }
        return $i if !$want;
        $want = 0;
        $i++;
        $i = lit_end($t, $l, $i - 1) if $lit;
    }
    $i;
}
# the items of a run, as lists of nodes
sub items_of {
    my ($l, $t, $lit) = @_;
    my @r;
    for (my $i = 0; $i < @$l; ) { my $e = item_end($l, $i, $t, $lit); $e = $i + 1 if $e == $i; push @r, [@$l[$i .. $e - 1]]; $i = $e }
    @r;
}
# (new words) the end of what starts at $i: a compound literal's head and
# its items, or the one node
sub lit_end {
    my ($t, $l, $i) = @_;
    my $n = $l->[$i];
    my $k = lit_count($t, $n);
    return $i + 1 unless defined $k;
    my $j = $i + 1;
    if ($k < 0) { $j++ }    # a union: a field's name, then its item
    $j = item_end($l, $j, $t, 1) for 1 .. abs $k;
    $j;
}
# how many items follow a literal's head (a union's: -1, after the field's
# name); nothing if it is none
sub lit_count {
    my ($t, $n) = @_;
    if ($n->{content} eq 'array' && !leaf($n)) {
        my $c = (kids($n))[-1];
        return leaf($c) && $c->{content} =~ /^(?:\d+|0x[0-9a-fA-F]+)$/ ? oct_or_dec($c->{content}) : undef;
    }
    return unless leaf($n) && (my $r = $t->{rec}{ $n->{content} });
    $r->{kind} eq 'union' ? -1 : scalar places($t, $n->{content});
}
sub oct_or_dec { $_[0] =~ /^0x/i ? hex $_[0] : $_[0] + 0 }
# a struct's places: its named fields, an anonymous member's in place, no
# padding: [field, ...]
sub places {
    my ($t, $name, $depth) = @_;
    die "words: anonymous members nested too deep\n" if ($depth // 0) > 32;
    map {
        $_->{pad} ? () : $_->{anon} ? do {
            my $r = $t->{rec}{ $_->{run}[0]{content} } or die "words: an anonymous member that is not a struct\n";
            $r->{kind} eq 'union' ? die "words: an anonymous union in a literal\n" : places($t, $_->{run}[0]{content}, ($depth // 0) + 1);
        } : $_
    } @{ rec($t, $name)->{fields} };
}
sub rec { my ($t, $name) = @_; $t->{rec}{$name} // die "words: not a struct or a union: $name\n" }

# ---------------------------------------------------------------------------
# before -> now
# ---------------------------------------------------------------------------

sub newwords {
    my ($types, @n) = @_;
    return @n if grep { has_newwords($_) } @n;
    my $t = newtypes($types // {});
    typenames($t, @n);
    map { regroup($t, $_, '') } map { newnode($t, $_, 'page') } @n;
}
# A node past 255 children now (a cast and its value were one node, a
# literal's zeros are written out): a declaration's items, a : of items in
# them, in items groups again; any other in layers (0: 1: ..., FF.pm)
sub regroup {
    my ($t, $n, $ctx) = @_;
    my @k = kids($n);
    my ($head, $items) = (0, $ctx eq 'items');
    if ($n->{content} =~ /.:$/ && $n->{content} ne ':') {
        my $i = marks(\@k);
        if ($i < @k && is_typeword($t, $k[$i]) && !(leaf($k[0]) && $k[0]{content} =~ /^(?:struct|union|enum)$/)) {
            my (undef, $j) = oldrun_new($t, \@k, $i);
            ($head, $items) = ($j, 1);
        }
    }
    $n->{children} = [map { regroup($t, $_, $items && ($_->{content} eq ':' || $_->{content} eq 'items') ? 'items' : '') } @k];
    return $n if @k <= 255;
    unless ($items) { $n->{children} = [layers(@k)]; return $n }
    my @v = map { $_->{content} eq 'items' && !leaf($_) ? kids($_) : $_ } @k[$head .. $#k];
    # (an item whole in one group: a cast or a suffix with its operand, a
    # compound literal's head with its items)
    my (@g, @cur);
    for (my $i = 0; $i < @v;) {
        my $e = item_end(\@v, $i, $t, 1);
        $e = $i + 1 if $e <= $i;
        die "words: an item of " . ($e - $i) . " nodes (max 255)\n" if $e - $i > 255;
        if (@cur + $e - $i > 255) { push @g, node('items', @cur); @cur = () }
        push @cur, @v[$i .. $e - 1];
        $i = $e;
    }
    push @g, node('items', @cur) if @cur;
    $n->{children} = [@k[0 .. $head - 1], @g];
    $n;
}
# the end of the type run now at $i
sub oldrun_new {
    my ($t, $l, $i) = @_;
    $i++;
    $i++ while $i < @$l && is($l->[$i], '* pointer');
    (undef, $i);
}

# the old type run at $i of l: [nodes now], the index after it
sub newrun {
    my ($t, $l, $i) = @_;
    return if $i >= @$l || !leaf($l->[$i]);
    my $w = $l->[$i]{content};
    if ($w eq 'address') {
        my ($in, $j) = newrun($t, $l, $i + 1);
        return ([@$in, node('* pointer')], $j) if $in;
        $Words::warn->($l->[$i + 1]{content}) if $Words::warn && $i + 1 < @$l && leaf($l->[$i + 1]) && $l->[$i + 1]{content} =~ /^[A-Za-z_]/;
        return ([node('void'), node('* pointer')], $i + 1);
    }
    if ($w eq 'array') {
        my ($in, $j) = newrun($t, $l, $i + 1) or return;
        return if $j >= @$l;
        # (c2ff's [] for C's T[]: no count)
        return ([node('array', @$in, is($l->[$j], '[]') ? () : newone($t, $l->[$j], 'fn'))], $j + 1);
    }
    return ([node($w)], $i + 1) if $t->{word}{$w};
    return;
}
sub newone { my ($t, $n, $c) = @_; my @r = newnode($t, $n, $c); @r == 1 ? $r[0] : node(':', @r) }

# One operand, of a prefix (pre) or a postfix: the nodes now of an old
# run, in a : unless they are one unit, a prefix's: its prefixes, a node
# and its postfixes; a postfix's: a node and its postfixes.
sub operand {
    my ($t, $pre, @k) = @_;
    return node(':', newlist($t, \@k, 'fn')) if @k != 1;
    my @r = newnode($t, $k[0], 'fn');
    my $i = 0;
    $i++ while $pre && $i < @r && is_prefix($r[$i]);
    return @r if $i < @r && !is_prefix($r[$i]) && !defined lit_count($t, $r[$i]) && !grep { !is_post($_) && !is($_, '++') && !is($_, '--') } @r[$i + 1 .. $#r];
    node(':', @r);
}
# a node of before with a path (a . among its children): the value, then
# the path, in a : that starts with the value
sub with_path {
    my ($t, $k, $f) = @_;
    my ($dot) = grep { is($k->[$_], '.') } 0 .. $#$k;
    return $f->([@$k]) unless defined $dot;
    node(':', $f->([@$k[0 .. $dot - 1]]), newlist($t, [@$k[$dot .. $#$k]], 'fn'));
}
sub textish { my ($r) = @_; @$r == 2 && leaf($r->[0]) && $r->[0]{content} =~ /^(?:char|u8|i8)$/ && is($r->[1], '* pointer') }

my %newdecl = ("address:" => "& address:", "content:" => "* pointer:", "cast::" => "cast:");
sub newnode {
    my ($t, $n, $ctx) = @_;
    my ($w, @k) = ($n->{content}, kids($n));
    # the shared page's declarations: their parameters stay
    return node($newdecl{$w}, map { node($_->{content}, kids($_)) } @k) if $newdecl{$w};
    return $n if !@k;
    # C11's _Generic: an association's name is its type run in one name
    # (address char: before, char * pointer: now)
    if ($w eq 'generic') { my ($x, @as) = @k; return node($w, newone($t, $x, 'fn'), map { node(gen_new($_->{content}), newlist($t, [kids($_)], 'fn')) } @as) }
    if ($w eq 'content') { return with_path($t, \@k, sub { (operand($t, 0, @{ $_[0] }), node('* pointer')) }) }
    if ($w eq 'address') {
        my ($r, $j) = newrun($t, \@k, 0);
        return with_path($t, \@k, sub { (operand($t, 0, @{ $_[0] }), node('& address')) }) unless $r;
        # a conversion to a pointer: a cast (a leaf under char is text)
        die "words: a conversion to the address of an array (write cast:)\n" if $r->[0]{content} eq 'array';
        my @ty = (@$r, node('* pointer'));
        return with_path($t, [@k[$j .. $#k]], sub {
            my @v = @{ $_[0] };
            @v or die "words: address of a type without a value\n";
            (node('cast', @ty), @v == 1 && leaf($v[0]) && textish(\@ty) ? $v[0] : operand($t, 1, @v));
        });
    }
    if ($w eq 'cast:') {
        my ($r, $j) = newrun($t, \@k, 0) or die "words: cast: without a type\n";
        return with_path($t, [@k[$j .. $#k]], sub {
            my @v = @{ $_[0] };
            # (cast: made no text: a leaf under char * pointer goes in a :)
            (node('cast', @$r), @v == 1 && leaf($v[0]) && textish($r) ? node(':', $v[0]) : operand($t, 1, @v));
        });
    }
    # (c2ff's typed literal of C's suffix: the suffix, then the number)
    return (node($w), $k[0]) if $suffix{$w} && @k == 1 && leaf($k[0]) && $k[0]{content} =~ $num;
    if ($t->{word}{$w} && !$t->{rec}{$w} && $w !~ /:$/) {
        # a typed literal: a suffix (int: the number); another conversion: a cast
        if (@k == 1 && leaf($k[0]) && $k[0]{content} =~ $num) {
            return (node($tosuffix{$w}), $k[0]) if $tosuffix{$w};
            my $v = $k[0]{content} =~ /^-/ ? -oct_or_dec(substr $k[0]{content}, 1) : oct_or_dec($k[0]{content});
            return $k[0] if $w eq 'int' && $v >= -2**31 && $v < 2**31 && ($k[0]{content} !~ /^0x/i || $v < 2**31);
        }
        return with_path($t, \@k, sub { (node('cast', node($w)), operand($t, 1, @{ $_[0] })) });
    }
    if ($t->{rec}{$w}) { return with_path($t, \@k, sub { new_lit($t, [node($w)], $_[0]) }) }
    if ($w eq 'array') {
        my ($r, $j) = newrun($t, [node('array'), @k], 0) or die "words: an array literal without its type\n";
        return with_path($t, [@k[$j - 1 .. $#k]], sub { new_lit($t, $r, $_[0]) });
    }
    if ($w =~ /^(.+):$/ && $w ne ':') { return newdef($t, $n, $ctx) }
    node($w, newlist($t, \@k, $ctx eq 'rec' ? 'fn' : $ctx));
}
sub newlist {
    my ($t, $l, $ctx) = @_;
    my @out;
    for (my $i = 0; $i < @$l; ) {
        my $n = $l->[$i];
        if (leaf($n) && ($n->{content} eq 'address' || $n->{content} eq 'array')) {
            my ($r, $j) = newrun($t, $l, $i);
            if ($r) { push @out, @$r; $i = $j; next }
        }
        push @out, newnode($t, $n, $ctx);
        $i++;
    }
    @out;
}
# a definition: its marks, its type run, then its items (a function's
# parameters and statements)
my %mark = map { $_ => 1 } ('thread local', 'weak', 'function', 'ifunc', 'section', 'alias', 'asm', 'struct', 'union', 'enum');
sub marks {
    my ($k) = @_;
    my $i = 0;
    while ($i < @$k && leaf($k->[$i]) && $mark{ $k->[$i]{content} }) { $i += $k->[$i]{content} =~ /^(?:ifunc|section)$/ ? 2 : 1 }
    $i > @$k ? scalar @$k : $i;
}
sub newdef {
    my ($t, $n, $ctx) = @_;
    my ($w, @k) = ($n->{content}, kids($n));
    my $i = marks(\@k);
    my $rec = @k && leaf($k[0]) && $k[0]{content} =~ /^(?:struct|union)$/;
    if ($rec) {
        # a struct's fields; c2ff's padding n: is : now
        return node($w, newlist($t, [$k[0]], 'rec'), map { my $f = newnode($t, $_, 'rec'); $f->{content} = ':' if $f->{content} =~ /^padding \d+:$/; $f } @k[1 .. $#k]);
    }
    my ($r, $j) = newrun($t, \@k, $i);
    # (a group's children are page items; a compile time function's are code)
    my $sub = $ctx eq 'page' && !$r && !(@k && is($k[0], 'compile time')) ? 'page' : 'fn';
    return node($w, newlist($t, \@k, $sub)) unless $r;
    node($w, newlist($t, [@k[0 .. $i - 1]], 'fn'), @$r, newlist($t, [@k[$j .. $#k]], 'fn'));
}
# A compound literal now: its type, then an item for each place. The
# items of before (old) are one per field, padding and an anonymous member
# (a : of its items) too.
sub new_lit {
    my ($t, $ty, $old, $depth) = @_;
    die "words: compound literals nested too deep\n" if ($depth // 0) > 32;
    my @items = items_of($old, $t, 0);
    my $h = $ty->[0];
    if ($h->{content} eq 'array' && !leaf($h)) {
        my @c = kids($h);
        my $n = oct_or_dec($c[-1]{content});
        my @e = @c[0 .. $#c - 1];
        die "words: more items than the array has elements\n" if @items > $n;
        return (@$ty, map { new_place($t, \@e, $items[$_], $depth) } 0 .. $n - 1);
    }
    my $r = $t->{rec}{ $h->{content} } or die "words: not a literal's type: $h->{content}\n";
    if ($r->{kind} eq 'union') {
        # (set through its n-th member: zeros for the members before it)
        my $f = $r->{fields}[ @items ? $#items : 0 ];
        die "words: a union literal of a member it has not\n" unless $f;
        die "words: a union literal of a member with no name\n" if $f->{name} eq '';
        my ($run) = newrun($t, $f->{run}, 0);
        return (@$ty, node($f->{name}), new_place($t, $run, $items[-1], $depth));
    }
    (@$ty, new_fields($t, $h->{content}, \@items, $depth));
}
sub new_fields {
    my ($t, $name, $items, $depth) = @_;
    my @f = @{ rec($t, $name)->{fields} };
    die "words: more items than $name has fields\n" if @$items > @f;
    my @out;
    for my $i (0 .. $#f) {
        my $f = $f[$i];
        my $it = $items->[$i];
        next if $f->{pad};
        if ($f->{anon}) {
            my @sub = $it ? ($it->[0]{content} eq ':' && @$it == 1 ? items_of([kids($it->[0])], $t, 0) : die "words: an anonymous member's item that is not a :\n") : ();
            push @out, new_fields($t, $f->{run}[0]{content}, \@sub, $depth + 1);
            next;
        }
        my ($run) = newrun($t, $f->{run}, 0);
        push @out, new_place($t, $run, $it, $depth);
    }
    @out;
}
# one place of the type run (now): its item, a zero one if none
sub new_place {
    my ($t, $run, $it, $depth) = @_;
    my $agg = @$run == 1 && ($run->[0]{content} eq 'array' && !leaf($run->[0]) || leaf($run->[0]) && $t->{rec}{ $run->[0]{content} });
    if ($agg) {
        return new_lit($t, $run, [kids($it->[0])], ($depth // 0) + 1) if $it && @$it == 1 && $it->[0]{content} eq ':' && !leaf($it->[0]);
        # (a zero one: its zeros written out, the user's)
        return new_lit($t, $run, [], ($depth // 0) + 1) unless $it;
    }
    return node(0) unless $it;
    newlist($t, $it, 'fn');
}

# ---------------------------------------------------------------------------
# now -> before
# ---------------------------------------------------------------------------

sub oldwords {
    my ($types, @n) = @_;
    my $t = newtypes($types // {});
    typenames($t, @n);
    map { oldnode($t, $_) } @n;
}
my %olddecl = reverse %newdecl;
sub is_typeword { my ($t, $n) = @_; leaf($n) && $t->{word}{ $n->{content} } || $n->{content} eq 'array' && !leaf($n) }

# the type run now at $i of l: [nodes before], the index after it
sub oldrun {
    my ($t, $l, $i) = @_;
    return if $i >= @$l || is($l->[$i], '* pointer');
    my $n = $l->[$i];
    my @r;
    if ($n->{content} eq 'array' && !leaf($n)) {
        my @c = kids($n);
        my ($in, $j) = oldrun($t, \@c, 0) or die "words: an array without its element type\n";
        @r = (node('array'), @$in, $j < @c ? oldnode1($t, $c[$j]) : node('0'));
    } elsif (leaf($n)) {
        @r = (node($n->{content}));
    } else { return }
    $i++;
    while ($i < @$l && is($l->[$i], '* pointer')) { unshift @r, node('address'); $i++ }
    (\@r, $i);
}
sub oldnode1 { my ($t, $n) = @_; my @r = oldnode($t, $n); @r == 1 ? $r[0] : die "words: one node became several: $n->{content}\n" }

# One unit of a run now at $i: its prefixes, a node (or a compound
# literal) and its postfixes; its nodes before and the index after it. A :
# that holds one expression as the operand of * pointer gives its
# children (C's parentheses), of & address stays.
sub oldunit {
    my ($t, $l, $i) = @_;
    die "words: a prefix without its operand\n" if $i >= @$l;
    my $n = $l->[$i];
    if (is_prefix($n)) { my ($v, $j) = oldprefix($t, $l, $i); return ([$v], $j) }
    my ($j, @cur, $flat);
    if (defined lit_count($t, $n)) { my ($v, $e) = oldlit($t, $l, $i); @cur = ($v); $j = $e }
    else {
        @cur = oldnode($t, $n);
        $flat = [oldvals($t, [kids($n)])] if $n->{content} eq ':' && !leaf($n) && one_item($t, [kids($n)]);
        $j = $i + 1;
    }
    while ($j < @$l && (is_post($l->[$j]) || is($l->[$j], '++') || is($l->[$j], '--'))) {
        my $w = $l->[$j]{content};
        if ($w eq '* pointer') { @cur = node('content', $flat ? @$flat : @cur) }
        elsif ($w eq '& address') {
            # (of a cast to one scalar word: its typed literal, address / (long / x))
            @cur = do { my ($ty, @v) = kids($cur[0]); node($ty->{content}, @v > 1 ? node(':', @v) : @v) }
                if @cur == 1 && $cur[0]{content} eq 'cast:' && $scalarword{ $cur[0]{children}[0]{content} // '' } && !$cur[0]{children}[0]{children}[0];
            @cur = node('address', @cur);
        }
        else { push @cur, node($w) }
        undef $flat;
        $j++;
    }
    (\@cur, $j, $flat);
}
sub one_item {
    my ($t, $l) = @_;
    return 0 unless @$l;
    return 0 if grep { $_->{content} =~ /.:$/ || $_->{content} eq 'compile time' } @$l;
    item_end($l, 0, $t, 1) == @$l;
}
# a prefix and its operand at $i: the node before
sub oldprefix {
    my ($t, $l, $i) = @_;
    my $n = $l->[$i];
    if (leaf($n)) {
        # (U, L ... without a number after them: a name, as the asm's labels)
        my $x = $l->[$i + 1];
        return (node($n->{content}), $i + 1) unless $x && leaf($x) && $x->{content} =~ $num;
        return (node($suffix{ $n->{content} }, node($x->{content})), $i + 2) unless is_post($l->[$i + 2]);
    }
    my ($v, $j, $flat) = oldunit($t, $l, $i + 1);
    $v = $flat if $flat;
    return (node($suffix{ $n->{content} }, @$v), $j) if leaf($n);
    my @c = kids($n);
    my ($r, $e) = oldrun($t, \@c, 0) or die "words: a cast without its type\n";
    die "words: a cast with more than its type\n" if $e != @c;
    # a leaf under char * pointer (u8, i8): a text, address / char / leaf
    my $x = $l->[$i + 1];
    return (node('address', @$r[1 .. $#$r], node($x->{content})), $i + 2)
        if @$r == 2 && $r->[0]{content} eq 'address' && $r->[1]{content} =~ /^(?:char|u8|i8)$/ && $j == $i + 2 && leaf($x) && !exists $opix{ $x->{content} } && !defined lit_count($t, $x);
    (node('cast:', @$r, @$v), $j);
}
# a compound literal at $i: the node before, the index after its items
sub oldlit {
    my ($t, $l, $i) = @_;
    my $n = $l->[$i];
    my $e = lit_end($t, $l, $i);
    my @rest = @$l[$i + 1 .. $e - 1];
    if ($n->{content} eq 'array') {
        my ($r) = oldrun($t, [$n], 0);
        return (node('array', @$r[1 .. $#$r], map { old_place($t, $_) } items_of(\@rest, $t, 1)), $e);
    }
    my $rec = $t->{rec}{ $n->{content} };
    if ($rec->{kind} eq 'union') {
        my $f = shift @rest;
        my ($k) = grep { $rec->{fields}[$_]{name} eq $f->{content} } 0 .. $#{ $rec->{fields} };
        die "words: a union literal of a field it has not: $f->{content}\n" unless defined $k;
        # (the members before it zeros, as c2ff wrote it before)
        my @z = map { my ($r) = oldrun($t, $rec->{fields}[$_]{run}, 0); @$r == 1 && $scalarword{ $r->[0]{content} } || $r->[0]{content} eq 'address' ? node('0') : node(':') } 0 .. $k - 1;
        return (node($n->{content}, @z, old_place($t, \@rest)), $e);
    }
    my @items = items_of(\@rest, $t, 1);
    (node($n->{content}, old_fields($t, $n->{content}, \@items)), $e);
}
# a struct's items before: one for each field, padding 0, an anonymous
# member a : of its own
sub old_fields {
    my ($t, $name, $items) = @_;
    map {
        $_->{pad} ? node('0') : $_->{anon} ? node(':', old_fields($t, $_->{run}[0]{content}, $items)) : old_place($t, shift @$items // die "words: a literal without an item for $_->{name}\n")
    } @{ rec($t, $name)->{fields} };
}
# an item of a literal: a literal in its place is a : of its items before
sub old_place {
    my ($t, $it) = @_;
    if (@$it && defined lit_count($t, $it->[0]) && lit_end($t, $it, 0) == @$it) {
        my ($v) = oldlit($t, $it, 0);
        my @c = kids($v);
        if ($v->{content} eq 'array') { my ($r) = oldrun($t, [$it->[0]], 0); splice @c, 0, @$r - 1 }
        return node(':', @c);
    }
    my @v = oldvals($t, $it);
    @v == 1 ? $v[0] : @v;
}
# a run of values now
sub oldvals {
    my ($t, $l) = @_;
    my @out;
    my $path;
    for (my $i = 0; $i < @$l; ) {
        my $n = $l->[$i];
        # (after a . the path: fields, not compound literals)
        $path = 1 if is($n, '.');
        if ($path && leaf($n) && !is_post($n) || leaf($n) && exists $opix{ $n->{content} } || is($n, 'else') || $n->{content} eq 'else if') {
            push @out, oldnode($t, $n);
            $i++;
            # (after it, as an index or a call's argument: * pointer and & address
            # of the leaf before)
            push(@out, node(is($l->[$i], '* pointer') ? 'content' : 'address', pop @out)), $i++ while $path && is_post($l->[$i]);
            next;
        }
        my ($v, $j) = oldunit($t, $l, $i);
        push @out, @$v;
        $i = $j;
    }
    @out;
}
sub has_new { my ($l) = @_; grep { is_prefix($_) || is_post($_) } @$l }
sub oldnode {
    my ($t, $n) = @_;
    my ($w, @k) = ($n->{content}, kids($n));
    return node($olddecl{$w}, map { node($_->{content}, kids($_)) } @k) if $olddecl{$w};
    return node($w) if !@k;
    if ($w eq ':') {
        # a : that holds one unit with a prefix or a postfix (a path after
        # it): that node before, the path its (C's parentheses)
        my ($dot) = grep { is($k[$_], '.') } 0 .. $#k;
        my @v = @k[0 .. ($dot // @k) - 1];
        if (@v && has_new(\@v)) {
            my ($o, $j) = oldunit($t, \@v, 0);
            if ($j == @v && @$o == 1) { push @{ $o->[0]{children} }, oldvals($t, [@k[$dot .. $#k]]) if defined $dot; return $o->[0] }
        }
    }
    if ($w eq 'generic') { my ($x, @as) = @k; return node($w, oldvals($t, [$x]), map { node(gen_old($_->{content}), oldvals($t, [kids($_)])) } @as) }
    die "words: a cast out of a run\n" if $w eq 'cast';
    die "words: an array type out of a type run\n" if $w eq 'array';
    return node($w, olddef($t, \@k)) if $w =~ /^(.+):$/ && $w ne ':';
    return node($w, is_typeword($t, $k[0]) ? oldtype($t, \@k) : oldvals($t, \@k)) if $w eq 'sizeof' || $w eq 'alignof';
    if ($w eq 'va_arg') { my ($v, $j) = oldunit($t, \@k, 0); return node($w, @$v, oldtype($t, [@k[$j .. $#k]])) }
    node($w, oldvals($t, \@k));
}
sub oldtype {
    my ($t, $l) = @_;
    my ($r, $j) = oldrun($t, $l, 0) or die "words: not a type: $l->[0]{content}\n";
    (@$r, oldvals($t, [@$l[$j .. $#$l]]));
}
sub olddef {
    my ($t, $k) = @_;
    # a struct's or a union's fields (: one of no name), their type runs
    return (node($k->[0]{content}), map { node($_->{content}, oldtype($t, [kids($_)])) } @$k[1 .. $#$k])
        if @$k && leaf($k->[0]) && $k->[0]{content} =~ /^(?:struct|union)$/;
    my $i = marks($k);
    return oldvals($t, $k) unless $i < @$k && is_typeword($t, $k->[$i]) && !(leaf($k->[0]) && $k->[0]{content} =~ /^(?:struct|union|enum)$/);
    my ($r, $j) = oldrun($t, $k, $i);
    # (an aggregate's items: a : of its own one of an aggregate in it)
    my $agg = $r->[0]{content} eq 'array' || @$r == 1 && $t->{rec}{ $r->[0]{content} };
    (oldvals($t, [@$k[0 .. $i - 1]]), @$r, $agg ? olditems($t, [@$k[$j .. $#$k]]) : oldvals($t, [@$k[$j .. $#$k]]));
}

# a declaration's items now: a : (or items) that is an item of its own is
# the items of an aggregate in it (C's braces), its own items in turn
sub olditems {
    my ($t, $l) = @_;
    my @out;
    for (my $i = 0; $i < @$l;) {
        my $e = item_end($l, $i, $t, 1);
        $e = $i + 1 if $e <= $i;
        my $n = $l->[$i];
        if ($e == $i + 1 && !leaf($n) && ($n->{content} eq ':' && !grep({ is($_, '.') } kids($n)) || $n->{content} eq 'items')) { push @out, node($n->{content}, olditems($t, [kids($n)])) }
        else { push @out, oldvals($t, [@$l[$i .. $e - 1]]) }
        $i = $e;
    }
    @out;
}

1;
