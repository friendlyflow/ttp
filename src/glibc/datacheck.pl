#!/usr/bin/env perl
# datacheck.pl — the bytes ttpc emits for glibc's globals against gcc's: each
# global (and static) with a value that gcc's objects of glibc define, found
# by its name in ttpc's program (ttpc -g: .symtab, each name's address and
# size), compared byte for byte. The round trip (glibc-roundtrip) checks the
# ff against the C as ff2c reads it back; this checks what ttpc makes of the
# same ff, where a word that ttpc reads otherwise than gcc becomes another
# value (a text that equals a function's name became its address; an address
# + sizeof became a garbage word).
#
#   perl datacheck.pl --target T [--known LIST] [--report OUT] ELF OBJDIR OBJLIST
#
# ELF is ttpc's program (with -g), OBJDIR gcc's build of glibc, OBJLIST its
# objects (allobjs.pl's lines, "lib path"; crt's first: of a name two of them
# define, a program has the first's, as glibc.ff does).
#
# How each byte is compared:
#   - plain bytes exactly, the padding inside an object too (gcc writes it as
#     0, ttpc as 0);
#   - a word gcc relocates (the object's relocations: an address, or on
#     riscv64 a difference of two labels) by what it points to, not by its
#     value: ttpc's word is looked up among ttpc's symbols, gcc's relocation
#     among the object's, and both must name the same global or static at the
#     same offset (+ addend); where gcc's points to no symbol of its own
#     (a string literal, a compound literal: .rodata.str*, a section + addend),
#     the bytes it points to are compared instead, as many as ttpc's literal
#     has (a string to its NUL). A difference of two labels (riscv64's
#     ADD/SUB pairs: gcc's jump tables of &&label - &&base) is not compared.
#   - the object's size must be the same (sizeof); its alignment is not
#     compared (gcc's object file does not record an object's alignment, and
#     ttpc lays globals out by its own rules), nor the padding between objects.
#   - an object gcc puts in .bss (zero) is compared as zero bytes.
#
# A static is found by ttpc's name for it: a file's static "x" is "x" or, where
# two units have one, "x unit"; a function's static (gcc's "x.N") is "f x"
# (f a function of the same object; "f x'" a second x in f). Where an object
# has more than one candidate for gcc's x.N, the DWARF of gcc's object says
# which function's x it is (readelf --debug-dump=info).
#
# It prints each global that differs (its name as ttpc's .symtab has it, what
# differs), each not compared (why), and the counts. With --known, the
# differences must be exactly the list's (name, digest, kind, reason by
# tabs; dcknown-<target>.txt): a new one or a listed one that no longer
# differs fails, so that the list cannot go stale. Exit 0 when they agree.
#
# A host tool (core Perl only).
use strict;
use warnings;
use Digest::SHA qw(sha1_hex);
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";

my ($target, $known, $report, $verbose, $program, @skip);
while (@ARGV && $ARGV[0] =~ /^--/) {
    my $o = shift;
    if ($o eq '--target') { $target = shift }
    elsif ($o eq '--known') { $known = shift }
    elsif ($o eq '--report') { $report = shift }
    elsif ($o eq '--verbose') { $verbose = 1 }
    elsif ($o eq '--program') { $program = shift }
    elsif ($o eq '--skip') { push @skip, shift }
    else { die "datacheck: unknown option $o\n" }
}
my ($elfpath, $objdir, $objlist) = defined $program ? (undef, @ARGV) : @ARGV;
die "usage: datacheck.pl --target T [--known LIST] [--report OUT] ELF OBJDIR OBJLIST\n"
    unless defined $objlist && defined $target;
my $readelf = $ENV{READELF} // 'readelf';

# ---- ELF ---------------------------------------------------------------------
sub slurp { my ($f) = @_; open my $h, '<:raw', $f or die "datacheck: $f: $!\n"; local $/; my $b = <$h>; $b }

sub elf {
    my ($path) = @_;
    my $b = slurp($path);
    die "datacheck: $path: not ELF\n" unless substr($b, 0, 4) eq "\x7fELF";
    my $c64 = ord(substr($b, 4, 1)) == 2;
    my %e = (path => $path, b => $b, c64 => $c64);
    my ($type, $mach, $ver, $entry, $phoff, $shoff, $flags, $ehsize, $phes, $phnum, $shes, $shnum, $shstrndx) =
        $c64 ? unpack('v v V Q< Q< Q< V v v v v v v', substr($b, 16, 48))
             : unpack('v v V V V V V v v v v v v', substr($b, 16, 36));
    $e{machine} = $mach;
    my @sh;
    for my $i (0 .. $shnum - 1) {
        my %s;
        @s{qw(name type flags addr offset size link info align entsize)} = $c64
            ? unpack('V V Q< Q< Q< Q< V V Q< Q<', substr($b, $shoff + $i * $shes, 64))
            : unpack('V V V V V V V V V V', substr($b, $shoff + $i * $shes, 40));
        $s{idx} = $i;
        push @sh, \%s;
    }
    my $shstr = $sh[$shstrndx];
    for my $s (@sh) { $s->{name} = cstr($b, $shstr->{offset} + $s->{name}) }
    $e{sh} = \@sh;
    # the symbols
    my @sym;
    for my $s (grep { $_->{type} == 2 } @sh) {
        my $str = $sh[$s->{link}];
        my $es = $c64 ? 24 : 16;
        for my $i (0 .. $s->{size} / $es - 1) {
            my %y;
            if ($c64) { @y{qw(name info other shndx value size)} = unpack('V C C v Q< Q<', substr($b, $s->{offset} + $i * $es, 24)) }
            else { @y{qw(name value size info other shndx)} = unpack('V V V C C v', substr($b, $s->{offset} + $i * $es, 16)) }
            $y{name} = cstr($b, $str->{offset} + $y{name});
            $y{type} = $y{info} & 15;
            $y{bind} = $y{info} >> 4;
            $y{idx} = $i;
            push @sym, \%y;
        }
        last;
    }
    $e{sym} = \@sym;
    # the relocations, by the section they apply to
    for my $s (grep { $_->{type} == 4 || $_->{type} == 9 } @sh) {
        my $rela = $s->{type} == 4;
        my $es = $c64 ? ($rela ? 24 : 16) : ($rela ? 12 : 8);
        my @r;
        for my $i (0 .. $s->{size} / $es - 1) {
            my $p = $s->{offset} + $i * $es;
            my ($off, $info, $add);
            if ($c64) { ($off, $info, $add) = unpack($rela ? 'Q< Q< q<' : 'Q< Q<', substr($b, $p, $es)) }
            else { ($off, $info, $add) = unpack($rela ? 'V V l<' : 'V V', substr($b, $p, $es)) }
            push @r, { off => $off, sym => $c64 ? $info >> 32 : $info >> 8, type => $c64 ? $info & 0xffffffff : $info & 255,
                       add => $add, rela => $rela };
        }
        push @{ $e{rel}{ $s->{info} } }, @r;
    }
    \%e;
}
sub cstr { my ($b, $o) = @_; my $e = index($b, "\0", $o); substr($b, $o, $e - $o) }

# ---- the relocations a global's words have ------------------------------------
# kind abs (the address of S + A), pcrel (S + A - P), diff (a label's
# difference, riscv64's ADD/SUB), and the word's size
my %RELOC = (
    62 => { 1 => ['abs', 8], 10 => ['abs', 4], 11 => ['abs', 4], 2 => ['pcrel', 4], 24 => ['pcrel', 8] },   # x86_64
    183 => { 257 => ['abs', 8], 258 => ['abs', 4], 260 => ['pcrel', 8], 261 => ['pcrel', 4] },                # aarch64
    243 => { 2 => ['abs', 8], 1 => ['abs', 4], 57 => ['pcrel', 4],
             33 => ['diff', 1], 34 => ['diff', 2], 35 => ['diff', 4], 36 => ['diff', 8],
             37 => ['diff', 1], 38 => ['diff', 2], 39 => ['diff', 4], 40 => ['diff', 8],
             54 => ['diff', 1], 55 => ['diff', 2], 56 => ['diff', 4], 52 => ['diff', 1], 53 => ['diff', 1] },  # riscv64
    40 => { 2 => ['abs', 4], 38 => ['abs', 4], 3 => ['pcrel', 4] },                                          # arm
);

# ---- ttpc's program -------------------------------------------------------------
my $T = defined $program ? { sym => [], sh => [], machine => 0, c64 => 1 } : elf($elfpath);
my $c64 = $T->{c64};
my $wsz = $c64 ? 8 : 4;
my $arm = $T->{machine} == 40;
my (%tglob, %tloc, @tsized, %tzero);
for my $y (@{ $T->{sym} }) {
    next if $y->{shndx} == 0 || $y->{shndx} >= 0xff00 || $y->{name} eq '';
    next unless $y->{type} <= 2;      # NOTYPE, OBJECT, FUNC
    if ($y->{bind} == 0) { push @{ $tloc{ $y->{name} } }, $y } else { $tglob{ $y->{name} } = $y }
    if ($y->{size} > 0) { push @tsized, $y } else { push @{ $tzero{ $y->{value} } }, $y }
}
@tsized = sort { $a->{value} <=> $b->{value} || $b->{size} <=> $a->{size} } @tsized;
# ttpc's bytes at an address (a section's, 0 where it has none in the file)
sub tbytes {
    my ($addr, $n) = @_;
    for my $s (@{ $T->{sh} }) {
        next unless $s->{flags} & 2 && $addr >= $s->{addr} && $addr + $n <= $s->{addr} + $s->{size};
        return "\0" x $n if $s->{type} == 8;
        return substr($T->{b}, $s->{offset} + $addr - $s->{addr}, $n);
    }
    undef;
}
# the symbol of ttpc's that holds an address: [symbol, offset in it]
sub tsym_at {
    my ($a) = @_;
    my ($lo, $hi) = (0, $#tsized);
    while ($lo <= $hi) { my $m = ($lo + $hi) >> 1; if ($tsized[$m]{value} <= $a) { $lo = $m + 1 } else { $hi = $m - 1 } }
    for (my $i = $hi; $i >= 0 && $i > $hi - 8; $i--) {
        my $y = $tsized[$i];
        return [$y, $a - $y->{value}] if $a < $y->{value} + $y->{size};
    }
    return [$tzero{$a}[0], 0] if $tzero{$a};
    undef;
}
# a name of ttpc's for no object of C's: a literal (text N, wide text N,
# f literal N), the GOT's slots
sub anon { $_[0] =~ /(?:^|\s)(?:wide )?text \d+$|(?:^| )literal \d+$|^\.L/ }

# ---- gcc's objects ------------------------------------------------------------------
my @objs;
{ open my $h, "<", $objlist or die "datacheck: $objlist: $!\n"; my @l = map { [split] } <$h>; @objs = map { $_->[1] } (grep({ $_->[0] eq "crt" } @l), grep({ $_->[0] ne "crt" } @l)) }
my (%gdef, @gsyms);   # a global's definitions in order; every object symbol with a value
my %G;                 # object => its ELF
for my $o (@objs) {
    my $f = "$objdir/$o.o";
    next unless -e $f;
    my $E = $G{$o} = elf($f);
    my $sh = $E->{sh};
    for my $y (@{ $E->{sym} }) {
        next if $y->{shndx} == 0 || $y->{shndx} >= 0xff00 || $y->{name} eq '';
        push @{ $gdef{ $y->{name} } }, [$o, $y] if $y->{bind} != 0;
        next unless $y->{type} == 1 || $y->{type} == 6 || ($y->{type} == 0 && !($sh->[ $y->{shndx} ]{flags} & 4));
        next unless $y->{size} > 0;
        push @gsyms, [$o, $y];
    }
}
# a global's definition a program has: the first strong one, else the first
sub gfirst { my ($n) = @_; my $d = $gdef{$n} or return; (grep { $_->[1]{bind} == 1 } @$d)[0] // $d->[0] }

# --program FF (a BUILD's FF, with glibc.ff.txt, glibc/index.ff and
# glibc.csema.err): instead, the C program that names every global gcc's
# objects define that glibc in ff defines too (its index, but its types,
# weak names, builtins and libatomic's), each the first strong one, but
# what reaches a name csema left out (glibc.csema.err: ttpc would stop at
# it) or a name of --skip (what ttpc cannot compile yet: it says so,
# without the function's name). main's code takes the address of each (by
# code, not by an initializer: ttpc places the thread locals after the
# functions code reaches, and stops at one only data reaches), and so
# ttpc compiles each, what each reaches and every static of each function
# it reaches. (What reaches what: the words of each definition of
# glibc.ff.txt that name another, but a word that is a local's or a
# field's name anywhere.)
if (defined $program) {
    require FF;
    my ($ix) = grep { $_->{content} eq "index:" } map { @{ $_->{children} } } FF::read_ff(slurp("$program/glibc/index.ff"));
    die "datacheck: $program/glibc/index.ff: no index:\n" unless $ix;
    my %skip = map { $_ => 1 } qw(types.ff weak.ff builtins.ff stdbit.ff atomics.ff);
    my %in;
    for my $e (FF::kids($ix)) {
        (my $n = $e->{content}) =~ s/:$//;
        my ($f) = map { $_->{content} } FF::kids($e);
        $in{$n} = 1 if defined $f && !$skip{$f};
    }
    # what each definition of the tree names (glibc.ff.txt: a page's
    # children, through its layers), and what reaches a name left out
    my %left = map { $_ => 1 } @skip;
    { open my $h, '<', "$program/glibc.csema.err" or die "datacheck: $program/glibc.csema.err: $!\n"; while (<$h>) { $left{$1} = 1 if /^csema: left out: (.+)$/ } }
    my (%uses, %locals, @stack, $def);
    open my $h, '<', "$program/glibc.ff.txt" or die "datacheck: $program/glibc.ff.txt: $!\n";
    while (my $l = <$h>) {
        chomp $l;
        my ($sp, $c) = $l =~ /^( *)(.*)$/;
        my $d = length($sp) / 2;
        $#stack = $d - 1;
        $stack[$d] = $c;
        next if $d == 0;
        if (!defined $def || $d <= $def->[1]) {
            # a page's child, past its layers: a definition
            my @p = @stack[1 .. $d];
            my $i = 0;
            $i++ while $i < @p && $p[$i] =~ /^\d+:$/;
            if ($stack[0] =~ /^glibc .*:$/ && $i == $#p && $c =~ /^(.+):$/) { $def = [$1, $d]; next }
            undef $def if defined $def && $d <= $def->[1];
        }
        next unless $def;
        # (a local's declaration, "x:" in a body: x is no global there)
        if ($c =~ /^(.+):$/) { $locals{ $def->[0] }{$1} = 1 } else { $uses{ $def->[0] }{$c} = 1 }
    }
    close $h;
    # (a word that is a local or a field anywhere is no edge: a path's fields
    # are words as a call is)
    my %decl = map { %$_ } values %locals;
    for my $f (keys %uses) { delete @{ $uses{$f} }{ grep { $decl{$_} } keys %{ $uses{$f} } } }
    my %rev;
    for my $f (keys %uses) { for my $u (keys %{ $uses{$f} }) { push @{ $rev{$u} }, $f if $uses{$u} || $left{$u} } }
    my %bad = %left;
    my @q = keys %left;
    my %why;
    while (defined(my $n = shift @q)) { for my $f (@{ $rev{$n} // [] }) { next if $bad{$f}++; $why{$f} = $n; push @q, $f } }
    if ($ENV{DATACHECK_WHY}) { my $n = $ENV{DATACHECK_WHY}; my @p = ($n); push @p, $n = $why{$n} while defined $why{$n}; print STDERR "datacheck: @p\n" }
    my @names = sort grep {
        my $d = gfirst($_);
        /^[A-Za-z_]\w*$/ && $in{$_} && !$bad{$_}
    } keys %gdef;
    my @tls = grep { gfirst($_)->[1]{type} == 6 } @names;
    @names = grep { gfirst($_)->[1]{type} != 6 } @names;
    my $nb = grep { $bad{$_} && $in{$_} } keys %gdef;
    print STDERR "datacheck: the program names " . scalar(@names) . " globals and " . scalar(@tls) . " thread locals; $nb not, as they reach what csema left out or --skip (" . join(', ', sort keys %left) . ")\n";
    print "extern char $_;\n" for @names;
    print "extern __thread char $_;\n" for @tls;
    print "char *volatile datacheck_p;\nint main (void) {\n";
    print "  datacheck_p = &$_;\n" for @names;
    print "  datacheck_p = &$_;\n" for @tls;
    print "  return 0;\n}\n";
    exit 0;
}

# per object: its functions' names, its symbols by section for lookups
my (%ofuncs, %osec);
sub oinfo {
    my ($o) = @_;
    return if $ofuncs{$o};
    my $E = $G{$o};
    $ofuncs{$o} = { map { $_->{name} => 1 } grep { $_->{type} == 2 && $_->{shndx} && $_->{shndx} < 0xff00 } @{ $E->{sym} } };
    for my $y (@{ $E->{sym} }) {
        next if $y->{shndx} == 0 || $y->{shndx} >= 0xff00 || $y->{name} eq '' || $y->{type} > 2 && $y->{type} != 6;
        push @{ $osec{$o}{ $y->{shndx} } }, $y;
    }
}
# gcc's symbol of an object that holds a section's offset: [symbol, offset in it]
sub gsym_at {
    my ($o, $sec, $off) = @_;
    oinfo($o);
    my $best;
    for my $y (@{ $osec{$o}{$sec} // [] }) {
        my $v = $y->{value} & ($arm && $y->{type} == 2 ? ~1 : ~0);
        next unless $off >= $v && ($off < $v + $y->{size} || $off == $v && $y->{size} == 0 && $y->{type} == 0);
        $best = $y if !$best || $y->{size} > 0 && ($best->{size} == 0 || $y->{bind} > $best->{bind});
    }
    $best ? [$best, $off - ($best->{value} & ($arm && $best->{type} == 2 ? ~1 : ~0))] : undef;
}

# The DWARF of an object: each of its function statics (gcc's x.N) and the
# function whose it is, by address (DW_OP_addr, the object's offset): x =>
# offset => function
my %dwarf;
sub dwarf {
    my ($o) = @_;
    return $dwarf{$o} if $dwarf{$o};
    my %d;
    open my $h, '-|', $readelf, '--debug-dump=info', "$objdir/$o.o" or die "datacheck: readelf: $!\n";
    my (@stack, $cur);
    while (<$h>) {
        if (/^\s*<(\d+)><\w+>: Abbrev Number: (\d+)(?: \((DW_TAG_\w+)\))?/) {
            my ($depth, $tag) = ($1, $3 // '');
            $#stack = $depth - 1 if @stack > $depth;
            $cur = { tag => $tag, depth => $depth };
            $stack[$depth] = $cur;
            next;
        }
        next unless $cur;
        if (/DW_AT_name\s*:\s*(?:\(indirect[^)]*\):\s*)?(\S+)\s*$/) { $cur->{name} = $1 }
        elsif (/DW_AT_location\s*:.*DW_OP_addr: (\w+)/) {
            next unless $cur->{tag} eq 'DW_TAG_variable' && defined $cur->{name};
            my ($f) = map { $_->{name} } grep { $_ && $_->{tag} eq 'DW_TAG_subprogram' && defined $_->{name} } reverse @stack[0 .. $cur->{depth} - 1];
            $d{ $cur->{name} }{ hex $1 } = $f if defined $f;
        }
    }
    close $h;
    $dwarf{$o} = \%d;
}

# ttpc's name of gcc's symbol: the names it may have (a global's own; a
# static's, as above), and why it has none
sub tnames {
    my ($o, $y) = @_;
    my $n = $y->{name};
    if ($y->{bind} != 0) { return $tglob{$n} ? ($tglob{$n}) : () }
    oinfo($o);
    if ($n =~ /^(.+)\.(\d+)$/) {
        my $v = $1;
        my @c;
        for my $tn (keys %tloc) {
            my @w = grep { !m{/} || 0 } split / /, $tn;
            my ($unit) = grep { m{/} } split / /, $tn;
            next if defined $unit && $unit ne $o;
            next unless @w == 2 && $w[1] =~ /^\Q$v\E'*$/ && $ofuncs{$o}{ $w[0] };
            push @c, map { [$_, $w[0]] } @{ $tloc{$tn} };
        }
        if (@c > 1) {
            # the DWARF's function of this x.N
            my $f = dwarf($o)->{$v}{ $y->{value} };
            my @f = defined $f ? grep { $_->[1] eq $f } @c : ();
            if (@f > 1) {
                # x and x' in one function: in the order gcc numbers them (.N)
                my @same = sort { $a->[0]{name} cmp $b->[0]{name} } @f;   # x, x', x''
                my @gn = sort { $a <=> $b } map { /\.(\d+)$/ ? $1 : () } grep { /^\Q$v\E\.\d+$/ && (dwarf($o)->{$v}{ gsym_byname($o, $_)->{value} } // '') eq $f } map { $_->{name} } @{ $G{$o}{sym} };
                my ($N) = $n =~ /\.(\d+)$/;
                my ($k) = grep { $gn[$_] == $N } 0 .. $#gn;
                @f = defined $k && $same[$k] ? ($same[$k]) : ();
            }
            @c = @f;
        }
        return map { $_->[0] } @c;
    }
    my @c = (@{ $tloc{"$n $o"} // [] });
    @c = @{ $tloc{$n} // [] } unless @c;
    # (a static that ttpc has as a global: a name of ff's that is unique)
    @c = ($tglob{$n}) if !@c && $tglob{$n} && !$gdef{$n};
    @c;
}
sub gsym_byname { my ($o, $n) = @_; (grep { $_->{name} eq $n } @{ $G{$o}{sym} })[0] }

# ---- the comparison ---------------------------------------------------------------
sub hexs { join ' ', map { sprintf '%02x', ord } split //, $_[0] }
sub uword { my ($b, $n) = @_; $n == 8 ? unpack('Q<', $b) : $n == 4 ? unpack('V', $b) : $n == 2 ? unpack('v', $b) : ord $b }
sub sword { my ($v, $n) = @_; return $v if $n == 8; $v >= 2 ** ($n * 8 - 1) ? $v - 2 ** ($n * 8) : $v }
# gcc's own names of what C has no name for: a compound literal, a switch's
# table, __func__ (ttpc's are literals, without a name of C's)
sub gccown { $_[0] =~ /^(__compound_literal|CSWTCH|__func__|__PRETTY_FUNCTION__|__FUNCTION__)\.\d+$/ ? $1 : undef }
# gcc's target of a relocation: {names => ttpc's names of it, off} (a global
# or static of C's), {lit => [object, section, offset, length]} (a literal),
# or {zero} (an undefined weak name)
sub gtarget {
    my ($o, $r, $inplace) = @_;
    my $E = $G{$o};
    my $y = $E->{sym}[ $r->{sym} ];
    my $add = $r->{rela} ? $r->{add} : $inplace;
    if ($y->{shndx} == 0) {
        my $d = gfirst($y->{name});
        return { zero => 1, desc => "$y->{name} (undefined)", name => $y->{name} } unless $d;
        return gnamed($d->[0], $d->[1], $add);
    }
    if ($y->{type} == 3) {       # a section's symbol: what holds the offset
        my $off = $y->{value} + $add;
        my $s = gsym_at($o, $y->{shndx}, $off);
        return gnamed($o, $s->[0], $s->[1]) if $s && $s->[0]{size} > 0;
        return glit($o, $y->{shndx}, $off);
    }
    if ($y->{bind} != 0) { my $d = gfirst($y->{name}); return gnamed($d->[0], $d->[1], $add) }
    return gnamed($o, $y, $add);
}
sub gnamed {
    my ($o, $y, $add) = @_;
    return { %{ glit($o, $y->{shndx}, $y->{value} + $add, $y->{value} + $y->{size}) }, desc => "$y->{name}+$add ($o)" } if gccown($y->{name});
    # (and its aliases: the names of the same place in its object)
    oinfo($o);
    my @a = grep { $_->{value} == $y->{value} && $_->{type} == $y->{type} && $_->{size} == $y->{size} } @{ $osec{$o}{ $y->{shndx} } // [] };
    @a = ($y) unless @a;
    my %t = map { $_->{name} => 1 } map { tnames($o, $_) } @a;
    { names => [sort keys %t], off => $add, func => $y->{type} == 2, desc => $y->{name} . ($add ? "+$add" : '') . ($y->{bind} ? '' : " ($o)") };
}
# a literal of gcc's at a section's offset, to its end: a string's NUL (a
# .rodata.strN.N: N bytes of 0), else the next place the object names in
# that section (a symbol, a relocation's target), its trailing zeros but
# one taken off (the padding to the next one's alignment)
my %marks;
sub glit {
    my ($o, $sec, $off, $end) = @_;
    my $E = $G{$o};
    my $s = $E->{sh}[$sec];
    my $desc = "$s->{name}+$off";
    my $data = $s->{type} == 8 ? "\0" x $s->{size} : substr($E->{b}, $s->{offset}, $s->{size});
    if (!defined $end && $s->{flags} & 0x20) {
        my $es = $s->{entsize} || 1;
        for (my $i = $off; $i + $es <= $s->{size}; $i += $es) { if (substr($data, $i, $es) eq "\0" x $es) { $end = $i + $es; last } }
    }
    if (!defined $end) {
        unless ($marks{$o}) {
            my %m;
            for my $y (@{ $E->{sym} }) { push @{ $m{ $y->{shndx} } }, $y->{value} if $y->{shndx} && $y->{shndx} < 0xff00 && $y->{type} != 3 }
            for my $rs (values %{ $E->{rel} }) {
                for my $r (@$rs) {
                    my $y = $E->{sym}[ $r->{sym} ];
                    push @{ $m{ $y->{shndx} } }, $y->{value} + ($r->{rela} ? $r->{add} : 0) if $y->{type} == 3;
                }
            }
            $marks{$o} = { map { $_ => [sort { $a <=> $b } @{ $m{$_} }] } keys %m };
        }
        ($end) = grep { $_ > $off } @{ $marks{$o}{$sec} // [] };
        $end //= $s->{size};
        my $b = substr($data, $off, $end - $off);
        $b =~ s/\0\0+$/\0/;
        $end = $off + length $b;
    }
    { lit => [$o, $sec, $off, $end - $off], desc => $desc };
}
sub tdesc { my ($a) = @_; my $s = tsym_at($a); $s ? $s->[0]{name} . ($s->[1] ? "+$s->[1]" : '') : sprintf('0x%x (no symbol)', $a) }
sub printable { my ($s) = @_; $s =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ge; length $s > 60 ? substr($s, 0, 60) . '...' : $s }

# gcc's bytes of an object's section from an offset, and ttpc's at an
# address, compared as above: the differences
sub cmprange {
    my ($o, $sec, $goff, $ta0, $len, $depth) = @_;
    my $E = $G{$o};
    my $s = $E->{sh}[$sec];
    my $gb = $s->{type} == 8 ? "\0" x $len : substr($E->{b}, $s->{offset} + $goff, $len);
    my $tb = tbytes($ta0, $len);
    return (sprintf('ttpc has no %d bytes at 0x%x', $len, $ta0)) unless defined $tb;
    my (@diff, %skip);
    for my $r (sort { $a->{off} <=> $b->{off} } grep { $_->{off} >= $goff && $_->{off} < $goff + $len } @{ $E->{rel}{$sec} // [] }) {
        my $k = $RELOC{ $T->{machine} }{ $r->{type} };
        my $p = $r->{off} - $goff;
        if (!$k) { push @diff, "+$p: relocation type $r->{type}, not known here"; next }
        my ($how, $w) = @$k;
        $skip{$_} = 1 for $p .. $p + $w - 1;
        next if $how eq 'diff' || $p + $w > $len;
        my $tv = uword(substr($tb, $p, $w), $w);
        my $inplace = $r->{rela} ? 0 : sword(uword(substr($gb, $p, $w), $w), $w);
        my $gt = gtarget($o, $r, $inplace);
        my $ta = $how eq 'pcrel' ? ($ta0 + $p + sword($tv, $w)) % (2 ** ($wsz * 8)) : $tv;
        if ($gt->{zero}) {
            push @diff, "+$p: ttpc " . tdesc($ta) . ", gcc 0 ($gt->{desc})" unless $ta == 0 || tdesc($ta) eq $gt->{name};
            next;
        }
        my $ts = tsym_at($ta);
        if ($arm && $ta & 1 && (!$ts || $ts->[1] == 1)) { my $s2 = tsym_at($ta - 1); $ts = [$s2->[0], 1] if $s2 && $s2->[0]{type} == 2 && $s2->[1] == 0 }
        if ($gt->{names}) {
            # (arm: a Thumb function's address has bit 0 set in gcc's)
            my $ok = $ts && grep({ $_ eq $ts->[0]{name} } @{ $gt->{names} })
                && ($arm && $gt->{func} ? ($ts->[1] | 1) == ($gt->{off} | 1) : $ts->[1] == $gt->{off});
            push @diff, "+$p: ttpc " . tdesc($ta) . ", gcc $gt->{desc}" . (@{ $gt->{names} } ? '' : ' (no name in ttpc\'s program)') unless $ok;
            next;
        }
        # a literal: its bytes, compared alike (to a depth of 3)
        my ($go, $gs, $gl, $n) = @{ $gt->{lit} };
        if ($ts && !anon($ts->[0]{name}) && !$ts->[1] && $ts->[0]{size} >= $n) {
            # (ttpc's is an object of C's: gcc's literal is not that)
            my $tl = tbytes($ta, $n) // '';
            push @diff, "+$p: ttpc " . tdesc($ta) . ", gcc a literal $gt->{desc} \"" . printable(gbytes($go, $gs, $gl, $n)) . '"';
            next;
        }
        next if $depth >= 3;
        my @d = cmprange($go, $gs, $gl, $ta, $n, $depth + 1);
        push @diff, "+$p: ttpc " . tdesc($ta) . " \"" . printable(tbytes($ta, $n) // '') . "\", gcc $gt->{desc} \"" . printable(gbytes($go, $gs, $gl, $n)) . '"' . ($depth ? '' : ' (' . join('; ', @d) . ')') if @d;
    }
    # the plain bytes
    my ($first, $last, $nd);
    for my $i (0 .. $len - 1) {
        next if $skip{$i} || substr($tb, $i, 1) eq substr($gb, $i, 1);
        $nd++;
        $first //= $i;
        $last = $i;
    }
    if (defined $first) {
        my ($a, $b) = ($first - $first % $wsz, $last - $last % $wsz + $wsz);
        $b = $a + 4 * $wsz if $b > $a + 4 * $wsz;
        $b = $len if $b > $len;
        my $ds = "bytes: $nd differ from +$first" . ($last > $first ? " to +$last" : '') . ", at +$a ttpc " . hexs(substr($tb, $a, $b - $a)) . ', gcc ' . hexs(substr($gb, $a, $b - $a));
        # (where ttpc has an address where gcc has bytes: whose)
        if ($first % $wsz == 0 && $first + $wsz <= $len) {
            my $v = uword(substr($tb, $first, $wsz), $wsz);
            my $sy = $v > 0x1000 ? tsym_at($v) : undef;
            $ds .= " (ttpc's word is the address " . tdesc($v) . ")" if $sy;
        }
        push @diff, $ds;
    }
    @diff;
}
sub gbytes { my ($o, $sec, $off, $n) = @_; my $s = $G{$o}{sh}[$sec]; return "\0" x $n if $s->{type} == 8; substr($G{$o}{b}, $s->{offset} + $off, $n) }

my (%res, @lines);
my %count = map { $_ => 0 } qw(compared equal differ notcomp);
my %why;
sub notcomp { my ($n, $w, $more) = @_; $count{notcomp}++; $why{$w}++; push @lines, "not compared: $n: $w" . ($more ? " ($more)" : '') if $verbose }

my %done;
for my $g (@gsyms) {
    my ($o, $y) = @$g;
    my $E = $G{$o};
    my $sec = $E->{sh}[ $y->{shndx} ];
    my $n = $y->{name};
    my $id = $y->{bind} ? $n : "$n ($o)";
    my $kind = $sec->{type} == 8 ? 'zero' : 'init';
    if ($y->{bind} != 0) {
        my $d = gfirst($n);
        if ($d->[0] ne $o) { notcomp($id, "a second definition (the program's is the first strong one)", "the program's is $d->[0]'s"); next }
    }
    if ($sec->{name} =~ /^\.gnu\.warning/) { notcomp($id, 'a link warning (.gnu.warning)'); next }
    if ($n =~ /^DW\.ref\./) { notcomp($id, "gcc's own (DW.ref: its unwind tables' word of the personality routine)"); next }
    if (my $w = gccown($n)) { notcomp($id, "gcc's own ($w: ttpc's is a literal, compared where it is pointed to)"); next }
    if ($sec->{flags} & 4) { notcomp($id, 'code (a symbol in an executable section)'); next }
    my @t = tnames($o, $y);
    if (!@t) {
        notcomp($id, $y->{bind} ? "not in ttpc's program (not reached, or not in ff)" : "a static ttpc's program has no name for (not reached, not in ff, or gcc's own)");
        next;
    }
    if (@t > 1) { notcomp($id, 'more than one of ttpc\'s statics may be it', join(', ', map { $_->{name} } @t)); next }
    my $t = $t[0];
    next if $done{"$t->{name}\0$t->{value}"}++;
    $count{compared}++;
    $count{"compared $kind"}++;
    my @diff;
    # ttpc's .symtab gives each object its place up to the next name's (the
    # literals of its initializer, which ttpc puts right after it, are in
    # it): a size short of gcc's is a difference, a longer one is not
    my $sz = $y->{size};
    my $m = $t->{size} < $sz ? $t->{size} : $sz;
    push @diff, "size: ttpc's place is $t->{size} bytes, gcc's object $sz (the next name of ttpc's: " . tdesc($t->{value} + $t->{size}) . ")" if $t->{size} < $sz;
    push @diff, cmprange($o, $y->{shndx}, $y->{value}, $t->{value}, $m, 0);
    if (@diff) {
        $count{differ}++;
        $count{"differ $kind"}++;
        $res{ $t->{name} } = [$id, $kind, join('; ', @diff)];
    } else { $count{equal}++; $count{"equal $kind"}++ }
}

# what ttpc's program has that no object of gcc's names (a static gcc dropped)
my %seen = map { $_ => 1 } keys %done;
my $tonly = 0;
for my $y (@tsized) { next unless $y->{type} == 1 && !anon($y->{name}) && !$done{"$y->{name}\0$y->{value}"}; $tonly++ }

# ---- the report ---------------------------------------------------------------------
my $out;
if (defined $report) { open $out, '>', $report or die "datacheck: $report: $!\n" } else { $out = \*STDOUT }
for my $k (sort keys %res) { print $out "datacheck: $k: $res{$k}[0], $res{$k}[1]: $res{$k}[2]\n" }
print $out "$_\n" for @lines;
for my $w (sort { $why{$b} <=> $why{$a} || $a cmp $b } keys %why) { print $out "datacheck: not compared: $why{$w}: $w\n" }
printf $out "datacheck ($target): %d compared (%d with a value, %d zero): %d equal, %d differ (%d with a value, %d zero); %d of gcc's not compared; %d objects of ttpc's program no object of gcc's names\n",
    $count{compared}, $count{'compared init'} // 0, $count{'compared zero'} // 0, $count{equal}, $count{differ}, $count{'differ init'} // 0, $count{'differ zero'} // 0, $count{notcomp}, $tonly;

# ---- against the known list -------------------------------------------------------------
exit 0 unless defined $known;
my %k;
my %kinds = ('miscompile' => 1, 'false alarm' => 1, 'gcc otherwise' => 1);
if (open my $h, '<', $known) {
    while (<$h>) {
        chomp;
        next if /^\s*(?:#|$)/;
        my ($n, $g, $kd, $r) = split /\t/;
        die "datacheck: $known:$.: not name, digest, kind, reason\n" unless defined $r && length $r && $kinds{$kd};
        $k{$n} = $g;
    }
} else { warn "datacheck: no list $known: every difference is new\n" }
my $bad = 0;
for my $n (sort keys %res) {
    my $g = substr(sha1_hex($res{$n}[2]), 0, 12);
    if (!exists $k{$n}) { print "datacheck: new: $n\t$g\t$res{$n}[2]\n"; $bad++ }
    elsif ($k{$n} ne $g) { print "datacheck: changed: $n\t$g (listed $k{$n})\t$res{$n}[2]\n"; $bad++ }
}
for my $n (sort keys %k) { next if $res{$n}; print "datacheck: listed but the same now: $n\n"; $bad++ }
print $bad ? "datacheck ($target): $bad not as listed in $known\n" : "datacheck ($target): the differences are the ${known}'s (" . scalar(keys %k) . ")\n";
exit($bad ? 1 : 0);
