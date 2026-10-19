#!/usr/bin/env perl
# s2ff-arm.pl — arm asm as ff: what GNU as made of a preprocessed .S of
# glibc (its .s, from src/glibc/mki.pl), each section of code an asm
# function of ttpc's C layer, name: / asm / its instructions, which C
# reaches as it reaches a C function. One instruction per instruction, each
# the ff instruction of its encoding (A32, 16-bit Thumb, Thumb-2, VFP and
# NEON, as isa/arm.pl has them: gen/armdec.pm decodes the bytes GNU as made
# and checks that the ff instruction makes the same), operands in ff's order.
#
#   perl s2ff-arm.pl [--page name] file.s file.dump > out.ff.txt
#   perl s2ff-arm.pl --items file.s file.dump    its functions alone
#   perl s2ff-arm.pl --size file.s file.dump     the bytes of its .text
#
# file.dump is objdump -d -r -t of what GNU as made of file.s: its symbols,
# its instructions and data, and the relocations GNU as left. It is read
# rather than the source, whose macros (.macro), literal pools (ldr =x),
# pseudo-instructions (adr, push of one register) and IT blocks GNU as has
# already resolved into encodings. From the source come the aliases (X = Y,
# .set X, Y), the data of other sections and where it came from.
#
#   a section of code (.text, .init, .fini): one asm function, named by its
#                   first symbol; each other symbol in it (a function, a
#                   local one) a block label holding asm first, an entry C
#                   may call (ttpc places the function that holds it); each
#                   address a branch goes to a block label .L <hex>
#   a branch        to its label, or to the symbol of its relocation: arel
#                   (A32) or trel (Thumb) of it
#   movw, movt      of a relocation: lo16 / hi16 of the symbol plus the
#                   addend GNU as left in them (pc-relative: of S - pc + A)
#   data in code    word / its value, or what its relocation gives: an
#                   address (R_ARM_ABS32), and the GOT of the PIC glibc's
#                   asm is (GOTPC, GOT32, GOTOFF32, TLS_IE32): ttpc links no
#                   GOT, so the function carries one, .Lgot, after its code,
#                   a word for each symbol read through it
#   other sections  a zeroed object is c2ff --zero's global (its labels
#                   aliases of its first), as in s2ff.pl; words, strings and
#                   bytes an asm function of data
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt);
use armdec;

my $page = 'glibc asm';
my (@files, $size, $items);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--size') { $size = 1; next }
    if ($a eq '--items') { $items = 1; next }
    push @files, $a;
}
die "usage: s2ff-arm.pl [--page name | --items | --size] file.s file.dump\n" unless @files == 2;
my ($src, $dump) = @files;
my $where = $dump;
sub fail { die "s2ff-arm: $where: @_\n" }

# ---- the dump: symbols, sections of code, their instructions and data ------
my (%sym, %symsec);     # name -> address, section (from the symbol table)
my (%secsyms);          # section -> [[address, name], ...] (functions and labels)
my (@secs, %sec);       # sections of code in order; name -> { lines => [...] }
my $cur;
my $last;
open my $d, '<', $dump or die "s2ff-arm: cannot open $dump: $!\n";
my $insyms = 0;
while (my $l = <$d>) {
    chomp $l;
    if ($l =~ /^SYMBOL TABLE:/) { $insyms = 1; next }
    if ($insyms) {
        if ($l =~ /^([0-9a-f]{8}) (.{7}) (\S+)\t[0-9a-f]+ (.*)$/) {
            my ($addr, $flags, $s, $name) = (hex $1, $2, $3, $4);
            # (not a mapping symbol, a section's, one from elsewhere or a number)
            next if $name =~ /^\$[atd](\.\d+)?$/ || $flags =~ /d/ || $s =~ /^\*(ABS|UND)\*$/;
            $sym{$name} = $addr;
            $symsec{$name} = $s;
            # (a local label of GNU as, .L..., names no entry)
            push @{ $secsyms{$s} }, [$addr, $name] unless $name =~ /^\.L/;
            next;
        }
        $insyms = 0 if $l eq '';
        next;
    }
    if ($l =~ /^Disassembly of section (\S+):$/) {
        $cur = $1;
        push @secs, $cur unless $sec{$cur};
        $sec{$cur} //= { lines => [] };
        next;
    }
    next unless defined $cur;
    if ($l =~ /^\s*([0-9a-f]+):\t([0-9a-f]{2,8}(?: [0-9a-f]{4})?)\s*\t(\S+)\s*(.*)$/) {
        my ($addr, $hex, $op, $args) = (hex $1, $2, $3, $4);
        $last = { addr => $addr, hex => $hex, op => $op, args => $args, relocs => [] };
        push @{ $sec{$cur}{lines} }, $last;
        next;
    }
    if ($l =~ /^\s+([0-9a-f]+): (R_ARM_\w+)\t(.+)$/) {
        my ($addr, $type, $target) = (hex $1, $2, $3);
        fail "a relocation $type at $1 after no instruction" unless $last && $last->{addr} <= $addr;
        push @{ $last->{relocs} }, { addr => $addr, type => $type, target => $target };
        next;
    }
}
close $d;

# ---- the source: aliases, other sections' data, where it came from ---------
my (@aliases, @data, $file, $line);
{
    open my $s, '<', $src or die "s2ff-arm: cannot open $src: $!\n";
    my ($other, @pending, @bytes);
    my $flush = sub {
        return unless @pending;
        my ($first, @more) = @pending;
        if (@bytes) { push @data, node("$first:", node('asm'), node('comment', node("glibc-2.44 $file:$line")), @bytes) }
        push @aliases, map { node("$_:", node('alias'), node($first)) } @more;
        @pending = (); @bytes = ();
    };
    while (my $l = <$s>) {
        chomp $l;
        if ($l =~ /^# (\d+) "([^"]+)"/) { ($line, $file) = ($1 - 1, $2 =~ s{^(\.\./)+}{}r); $file = undef if $file =~ /^</; next }
        $line++;
        $l =~ s/\s*@.*$// unless $l =~ /"/;
        for my $st (split /;/, $l) {
            $st =~ s/^\s+|\s+$//g;
            next if $st eq '';
            if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/ || $st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)$/) {
                my ($x, $y) = ($1, $2);
                if ($y =~ /^-?\d+$/) { warn "s2ff-arm: $where: $x = $y, a constant, left out\n"; next }
                push @aliases, node("$x:", node('alias'), node($y));
                next;
            }
            if ($st =~ /^\.(data|bss|text|section\s+([^,\s]+)(,.*)?)$/) {
                $flush->();
                my $sn = $2 // ".$1";
                $other = $sn =~ /^\.(text|init|fini)$/ ? undef : $sn;
                next;
            }
            next unless defined $other;
            next if $st =~ /^\.(globl|global|weak|type|size|hidden|align|p2align|balign)\b/;
            if ($st =~ /^([.\w]+):$/) { $flush->() if @bytes; push @pending, $1; next }
            fail "data with no label in $other: $st" unless @pending;
            if ($st =~ /^\.(zero|space)\s+(\d+)$/) {
                my ($first, @more) = @pending;
                push @aliases, map { node("$_:", node('alias'), node($first)) } @more;
                warn "s2ff-arm: $where: $first is zero, c2ff --zero $first makes it\n";
                @pending = ();
                next;
            }
            if ($st =~ /^\.(long|word|4byte)\s+(.+)$/) { push @bytes, map { node('word', leaf($_)) } split /\s*,\s*/, $2; next }
            if ($st =~ /^\.(short|hword|2byte)\s+(.+)$/) { push @bytes, map { node('half', leaf($_)) } split /\s*,\s*/, $2; next }
            if ($st =~ /^\.byte\s+(.+)$/) { push @bytes, map { node('byte', leaf($_)) } split /\s*,\s*/, $1; next }
            if ($st =~ /^\.(string|asciz)\s+"(.*)"$/) { push @bytes, node('ascii', node(unquote($2) . "\0")); next }
            if ($st =~ /^\.ascii\s+"(.*)"$/) { push @bytes, node('ascii', node(unquote($1))); next }
            fail "bytes in $other: $st";
        }
    }
    $flush->();
    close $s;
}
sub unquote { my ($t) = @_; $t =~ s/\\(n|t|\\|"|[0-7]{1,3})/$1 eq 'n' ? "\n" : $1 eq 't' ? "\t" : $1 =~ m{^[0-7]} ? chr oct $1 : $1/ge; $t }
sub leaf { my ($v) = @_; $v =~ /^(0x[0-9a-f]+|-?\d+)$/i ? node($v =~ /^0x/i ? hex $v : $v) : node($v) }

# ---- the sections of code ----------------------------------------------------
my $dec = armdec->new;
my (@fns, $bytes);
my %RELB = map { $_ => 1 } qw(R_ARM_CALL R_ARM_JUMP24 R_ARM_THM_CALL R_ARM_THM_JUMP24 R_ARM_PLT32);
for my $s (@secs) {
    my @lines = @{ $sec{$s}{lines} };
    next unless @lines;
    my %names;          # address -> names of symbols there
    push @{ $names{ $_->[0] } }, $_->[1] for sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] } @{ $secsyms{$s} // [] };
    my $lname = sub { my ($a) = @_; $names{$a} ? $names{$a}[0] : sprintf('.L %x', $a) };
    my (%target, %got);     # addresses branches go to; symbols read through the GOT
    my @out;                # [address, node] in order
    for my $i (@lines) {
        my $at = $i->{addr};
        my $rel = $i->{relocs}[0];
        if ($i->{op} =~ /^\.(word|short|byte)$/) {
            my $w = $1;
            my $v = hex $i->{hex};
            $bytes += { word => 4, short => 2, byte => 1 }->{$w};
            my $kind = { word => 'word', short => 'half', byte => 'byte' }->{$w};
            push @out, [$at, $rel ? data_reloc($rel, $v, \%got, $lname) : node($kind, node($v))];
            next;
        }
        my ($mode, $v) = $i->{hex} =~ /^(\w{4}) (\w{4})$/ ? ('t2', hex($2) << 16 | hex($1))
            : length($i->{hex}) == 4 ? ('t', hex $i->{hex}) : ('a', hex $i->{hex});
        $bytes += $mode eq 't' ? 2 : 4;
        # of the encodings that make these bits, the one GNU names as objdump
        # does (pld rather than ldrb to pc, mvn rather than orn of pc), or
        # names without the condition objdump adds in an IT block
        my $m = $i->{args} =~ /@ \((\S+)/ ? $1 : $i->{op};
        my $score = sub { my ($g) = $_[0][2]{gnu} =~ /^(\S+)/; $g =~ s/\{cond\}//; $g eq $m ? 0 : $m =~ /^\Q$g\E(eq|ne|cs|cc|hs|lo|mi|pl|vs|vc|hi|ls|ge|lt|gt|le)(\.[nw])?$/ ? 1 : 2 };
        my ($f) = sort { $score->($a) <=> $score->($b) } $dec->decode($mode, $v);
        fail "no ff form for $i->{op} $i->{args} ($i->{hex})" unless $f;
        my ($name, $ops, $def) = @$f;
        my @ops = map { node($_) } @$ops;
        if ($def->{branch}) {
            my ($k) = grep { $def->{params}[$_] =~ /^u?imm$/ } 0 .. $#{ $def->{params} };
            my $to = $at + ($mode eq 'a' ? 8 : 4) + $ops->[$k];
            my $label;
            if ($rel && $RELB{ $rel->{type} }) { $label = $rel->{target} }
            elsif ($rel) { fail "a branch with $rel->{type}" }
            else { $label = $lname->($to); $target{$to} = 1 }
            $ops[$k] = node($mode eq 'a' ? 'arel' : 'trel', node($label));
        } elsif ($rel) {
            my ($k) = grep { $def->{params}[$_] eq 'imm16' } 0 .. $#{ $def->{params} };
            fail "$rel->{type} at $name" unless defined $k && $rel->{type} =~ /^R_ARM_MOV([WT])_(ABS_NC|ABS|PREL_NC|PREL)$/;
            my ($half, $pcrel) = ($1 eq 'W' ? 'lo16' : 'hi16', $2 =~ /PREL/);
            my $a = $ops->[$k]; $a -= 65536 if $a >= 32768;
            my $s = symbol($rel->{target}, $lname);
            my $val = $pcrel ? node('sub', node('pc'), node($s), node('a0')) : node($s);
            $val = node('addi', node($a), $val, node('a0')) if $a;
            $ops[$k] = node($half, $val);
        }
        push @out, [$at, node($name, @ops)];
    }
    # the blocks: a label at each entry and each address a branch goes to
    my ($first) = $names{ $lines[0]{addr} } ? $names{ $lines[0]{addr} }[0] : fail "no symbol at the start of $s";
    my $fn = node("$first:", node('asm'), node('comment', node('glibc-2.44 ' . ($file // $src) . " ($s)")));
    my $into = $fn;
    for my $o (@out) {
        my ($at, $n) = @$o;
        if ($at != $lines[0]{addr} && ($names{$at} || $target{$at})) {
            my $l = $lname->($at);
            $into = node("$l:", $names{$at} ? (node('asm')) : ());
            push @{ $fn->{children} }, $into;
            push @aliases, map { node("$_:", node('alias'), node($l)) } @{ $names{$at} }[1 .. $#{ $names{$at} }] if $names{$at};
        }
        push @{ $into->{children} }, $n;
    }
    push @aliases, map { node("$_:", node('alias'), node($first)) } @{ $names{ $lines[0]{addr} } }[1 .. $#{ $names{ $lines[0]{addr} } }];
    if (%got) {
        push @{ $fn->{children} }, node('.Lgot:'), map { node(".Lgot $_:", $got{$_}) } sort keys %got;
    }
    push @fns, $fn;
}

# a symbol of a relocation: _GLOBAL_OFFSET_TABLE_ is the function's .Lgot, a
# local one (.L99^B2, a numeric label of GNU as) its label here
sub symbol {
    my ($t, $lname) = @_;
    return '.Lgot' if $t eq '_GLOBAL_OFFSET_TABLE_';
    if ($t =~ /^\.L/) {
        # (objdump shows a control character of a name as ^B in a relocation)
        (my $n = $t) =~ s/\^([A-Z@\[\\\]^_])/chr(ord($1) - 64)/ge;
        defined $sym{$n} or fail "no address for the local symbol $t";
        fail "the local symbol $t is in $symsec{$n}, not yet" unless $sec{ $symsec{$n} };
        return $lname->($sym{$n});
    }
    $t;
}
# the word of data a relocation fills in
sub data_reloc {
    my ($r, $v, $got, $lname) = @_;
    my ($type, $t) = ($r->{type}, $r->{target});
    my $a = $v >= 2**31 ? $v - 2**32 : $v;
    my $plus = sub { my ($n) = @_; $a ? node('addi', node($a), $n, node('a0')) : $n };
    if ($type eq 'R_ARM_ABS32') { return node('word', $plus->(node(symbol($t, $lname)))) }
    if ($type eq 'R_ARM_REL32') { return node('word', $plus->(node('sub', node('pc'), node(symbol($t, $lname)), node('a0')))) }
    if ($type eq 'R_ARM_GOTPC') { return node('word', $plus->(node('sub', node('pc'), node('.Lgot'), node('a0')))) }
    if ($type eq 'R_ARM_GOT32') { $got->{$t} = node('word', node($t)); return node('word', $plus->(node('sub', node('.Lgot'), node(".Lgot $t"), node('a0')))) }
    if ($type eq 'R_ARM_GOTOFF32') { return node('word', $plus->(node('sub', node('.Lgot'), node(symbol($t, $lname)), node('a0')))) }
    if ($type eq 'R_ARM_TLS_IE32') { $got->{"$t tp"} = node('word', node('tprel', node($t))); return node('word', $plus->(node('sub', node('pc'), node(".Lgot $t tp"), node('a0')))) }
    fail "a word with $type";
}

if ($size) { print $bytes // 0, "\n"; exit }
# each alias once, and none of a name that is a label of the code already
my %seen;
my %entry;
my $walk; $walk = sub { for (@{ $_[0]{children} }) { $entry{ $_->{content} =~ s/:$//r } = 1 if $_->{content} =~ /:$/; $walk->($_) } };
$walk->($_) for @fns;
@aliases = grep { my $n = $_->{content} =~ s/:$//r; !$seen{$n}++ && !$entry{$n} } @aliases;
my @all = (@fns, @data, @aliases);
print $items ? write_txt(@all) : write_txt(node("$page:", @all));
