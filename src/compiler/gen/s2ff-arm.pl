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
#   perl s2ff-arm.pl crti.s crti.dump --then crtn.s crtn.dump
#                        crti's _init and _fini (.init, .fini) ended by
#                        crtn's .init and .fini, as the linker joins them
#   --zero name          the objects c2ff --zero makes (else a zero object's
#                        aliases, which then name nothing, are left out)
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
#                   GOT, so the file carries one: "<file> got", and a
#                   word "<file> got <symbol>" for each symbol read through it
#   other sections  a zeroed object is c2ff --zero's global (its labels
#                   aliases of its first), as in s2ff.pl; words, strings and
#                   bytes an asm function of data
#   .weak X         X undefined here (crti's __gmon_start__): X: / weak /
#                   function / void, address 0; a branch to it goes to a
#                   trap the function carries (.Lweak X: / udf 0)
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt);
use armdec;

my $page = 'glibc asm';
my (@files, $size, $items, @then, %zeroed);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--then') { @then = splice @ARGV, 0, 2; next }
    if ($a eq '--zero') { $zeroed{ shift @ARGV } = 1; next }
    if ($a eq '--size') { $size = 1; next }
    if ($a eq '--items') { $items = 1; next }
    push @files, $a;
}
die "usage: s2ff-arm.pl [--page name | --items | --size] [--zero name] file.s file.dump [--then crtn.s crtn.dump]\n" unless @files == 2;
my ($src, $dump) = @files;
my $where = $dump;
sub fail { die "s2ff-arm: $where: @_\n" }

# ---- the dump: symbols, sections of code, their instructions and data ------
my (%sym, %symsec);     # name -> address, section (from the symbol table)
my (%secsyms, %secend);  # section -> [[address, name], ...] (functions and labels); its end
my (@secs, %sec);       # sections of code in order; name -> { lines => [...] }
my (%undef);             # names the symbol table has undefined
# (crtn's, --then: its sections' instructions after crti's, from its end on)
sub readdump {
my ($dump, $then) = @_;
my %base;
if ($then) {
    for my $s (@secs) {
        my $e = $secend{$s} // 0;
        for my $i (@{ $sec{$s}{lines} }) { my $n = $i->{addr} + ($i->{hex} =~ / / ? 4 : length($i->{hex}) / 2); $e = $n if $n > $e }
        $base{$s} = $e;
    }
}
my $cur;
my $last;
open my $d, '<', $dump or die "s2ff-arm: cannot open $dump: $!\n";
my $insyms = 0;
while (my $l = <$d>) {
    chomp $l;
    if ($l =~ /^SYMBOL TABLE:/) { $insyms = 1; next }
    if ($insyms) {
        if ($l =~ /^([0-9a-f]{8}) (.{7}) (\S+)\t([0-9a-f]+) (.*)$/) {
            my ($addr, $flags, $s, $size, $name) = (hex $1, $2, $3, hex $4, $5);
            next if $then;
            $name =~ s/^\.(hidden|protected|internal) //;
            $undef{$name} = 1 if $s eq '*UND*';
            # (a section's end, past its last symbol's bytes: objdump shows zeros as ...)
            $secend{$s} = $addr + $size if !defined $secend{$s} || $addr + $size > $secend{$s};
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
        fail "$dump: $cur, which the file before it has not" if $then && !$sec{$cur};
        push @secs, $cur unless $sec{$cur};
        $sec{$cur} //= { lines => [] };
        next;
    }
    next unless defined $cur;
    if ($l =~ /^\s*([0-9a-f]+):\t([0-9a-f]{2,8}(?: [0-9a-f]{4})?)\s*\t(\S+)\s*(.*)$/) {
        my ($addr, $hex, $op, $args) = (hex $1, $2, $3, $4);
        $addr += $base{$cur} // 0;
        $last = { addr => $addr, hex => $hex, op => $op, args => $args, relocs => [] };
        push @{ $sec{$cur}{lines} }, $last;
        next;
    }
    if ($l =~ /^\s+([0-9a-f]+): (R_ARM_\w+)\t(.+)$/) {
        my ($addr, $type, $target) = (hex $1, $2, $3);
        $addr += $base{$cur} // 0;
        fail "a relocation $type at $1 after no instruction" unless $last && $last->{addr} <= $addr;
        push @{ $last->{relocs} }, { addr => $addr, type => $type, target => $target };
        next;
    }
}
close $d;
}
readdump($dump);
readdump($then[1], 1) if @then;
$secend{$_} = undef for @then ? @secs : ();

# ---- the source: aliases, other sections' data, where it came from ---------
# A section of data is a block, an asm function of data named by its first
# label (a local one, .L..., by this file and it); each other label in it
# is its place there (%dlab: the block, the offset), which a relocation of
# the code reaches as the block plus the offset.
my (@aliases, @data, $file, $line, %dlab, %got, %weakref, %srcalias);
(my $base = $src) =~ s{.*/}{}; $base =~ s/\.s$//;
# the offset of a symbol's word in the file's GOT
sub gotoff { my ($t) = @_; $got{$t} = node('word', node($t)); node('sub', node("$base got"), node("$base got $t"), node('a0')) }
{
    open my $s, '<', $src or die "s2ff-arm: cannot open $src: $!\n";
    my ($other, $blk, %numeric, @stack);
    my $close = sub {
        return unless $blk;
        if (@{ $blk->{nodes} }) {
            push @data, node("$blk->{name}:", node('asm'), node('comment', node('glibc-2.44 ' . ($blk->{file} // $src))), @{ $blk->{nodes} });
            for (@{ $blk->{labels} }) {
                my ($l, $o) = @$_;
                next if $l eq $blk->{name};
                if ($l =~ /^\.L/) { $dlab{$l} = [$blk->{name}, $o] }
                elsif ($o == 0) { push @aliases, node("$l:", node('alias'), node($blk->{name})) }
                else { fail "the label $l at $o in a block of data" }
            }
        } elsif (@{ $blk->{labels} }) {
            # labels with no bytes after them (start.S's __data_start, ...): only aliases
            my ($first) = map { $_->[0] } grep { $_->[0] !~ /^\.L/ } @{ $blk->{labels} };
            push @aliases, map { node("$_->[0]:", node('alias'), node($first)) } grep { $_->[0] !~ /^\.L/ && $_->[0] ne $first } @{ $blk->{labels} } if $first;
        }
        undef $blk;
    };
    my $label = sub {
        my ($l, $o) = @_;
        $blk //= { name => undef, off => 0, nodes => [], labels => [], file => $file };
        $o //= $blk->{off};
        if (!defined $blk->{name} && $o == 0) { $blk->{name} = $l =~ /^\.L/ ? "$base $l" : $l }
        push @{ $blk->{labels} }, [$l, $o];
    };
    my $put = sub {
        my ($n, $size) = @_;
        fail "data with no label in $other" unless $blk && defined $blk->{name};
        push @{ $blk->{nodes} }, $n;
        $blk->{off} += $size;
    };
    while (my $l = <$s>) {
        chomp $l;
        if ($l =~ /^# (\d+) "([^"]+)"/) { ($line, $file) = ($1 - 1, $2 =~ s{^(\.\./)+}{}r); $file = undef if $file =~ /^</; next }
        $line++;
        $l =~ s/\s*@.*$// unless $l =~ /"/;
        for my $st (split /;/, $l) {
            $st =~ s/^\s+|\s+$//g;
            next if $st eq '';
            if (defined $other && $st =~ /^\.set\s+([.\w]+)\s*,\s*\.\s*\+\s*(\d+)$/) { $label->($1, ($blk ? $blk->{off} : 0) + $2); next }
            if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/ || $st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)$/) {
                my ($x, $y) = ($1, $2);
                if ($y =~ /^-?\d+$/) { warn "s2ff-arm: $where: $x = $y, a constant, left out\n"; next }
                push @aliases, node("$x:", node('alias'), node($y));
                $srcalias{$x} = 1;
                next;
            }
            # GNU's numeric labels (99:) are .L99^B1, .L99^B2 ... in its object
            if ($st =~ s/^(\d+):\s*//) { my $n = ".L$1\x02" . ++$numeric{$1}; $label->($n) if defined $other && $other !~ /^\.debug_/; redo if $st ne ''; next }
            next if $st =~ /^\.(ident|file)\b/;
            if ($st =~ /^\.pushsection\s+([^,\s]+)/) { $close->(); push @stack, $other; my $sn = $1; $other = $sn =~ /^\.(text|init|fini)$/ ? undef : $sn; next }
            if ($st =~ /^\.popsection$/) { $close->(); $other = pop @stack; next }
            if ($st =~ /^\.(data|bss|text|section\s+([^,\s]+)(,.*)?)$/) {
                $close->();
                my $sn = $2 // ".$1";
                $other = $sn =~ /^\.(text|init|fini)$/ || $sn =~ /^\.note/ ? undef : $sn;
                next;
            }
            $weakref{$1} = 1 if $st =~ /^\.weak\s+([.\w]+)$/;
            next unless defined $other;
            # (debugging data, lib1funcs.S's own .debug_frame: not the
            # program's, ttpc writes its own)
            next if $other =~ /^\.debug_/;
            next if $st =~ /^\.(globl|global|weak|type|size|hidden)\b/;
            if ($st =~ /^\.(p2align|align|balign)\s+(\d+)/) {
                my $a = $1 eq 'balign' ? $2 : 2**$2;
                if (!$blk || !@{ $blk->{nodes} }) { $blk //= { name => undef, off => 0, nodes => [], labels => [], file => $file }; $blk->{align} = $a; push @{ $blk->{nodes} }, node('align', node($a)) if $a > 4; next }
                $put->(node('byte', node(0)), 1) while $blk->{off} % $a;
                next;
            }
            if ($st =~ /^([.\w]+):$/) { $label->($1); next }
            if ($st =~ /^\.(zero|space)\s+(\d+)$/ && $blk && !grep { $_->{content} ne 'align' } @{ $blk->{nodes} }) {
                my @ls = grep { $_->[0] !~ /^\.L/ } @{ $blk->{labels} };
                if (@ls) {
                    my ($first, @more) = map { $_->[0] } @ls;
                    push @aliases, map { node("$_:", node('alias'), node($first)) } @more if !%zeroed || $zeroed{$first};
                    warn "s2ff-arm: $where: $first is zero, c2ff --zero $first makes it\n";
                    undef $blk;
                    next;
                }
            }
            if ($st =~ /^\.(zero|space)\s+(\d+)$/) { $put->(node('byte', node(0)), 1) for 1 .. $2; next }
            if ($st =~ /^\.(long|word|4byte)\s+(.+)$/) { $put->(node('word', /^([.\w]+)\(GOT\)$/ ? gotoff($1) : leaf($_)), 4) for split /\s*,\s*/, $2; next }
            if ($st =~ /^\.(short|hword|2byte)\s+(.+)$/) { $put->(node('half', leaf($_)), 2) for split /\s*,\s*/, $2; next }
            if ($st =~ /^\.byte\s+(.+)$/) { $put->(node('byte', leaf($_)), 1) for split /\s*,\s*/, $1; next }
            if ($st =~ /^\.(string|asciz)\s+"(.*)"$/) { my $t = unquote($2) . "\0"; $put->(node('ascii', node($t)), length $t); next }
            if ($st =~ /^\.ascii\s+"(.*)"$/) { my $t = unquote($1); $put->(node('ascii', node($t)), length $t); next }
            fail "bytes in $other: $st";
        }
    }
    $close->();
    close $s;
}
sub unquote { my ($t) = @_; $t =~ s/\\(n|t|\\|"|[0-7]{1,3})/$1 eq 'n' ? "\n" : $1 eq 't' ? "\t" : $1 =~ m{^[0-7]} ? chr oct $1 : $1/ge; $t }
sub leaf { my ($v) = @_; $v =~ /^(0x[0-9a-f]+|-?\d+)$/i ? node($v =~ /^0x/i ? hex $v : $v) : node($v) }

# ---- the sections of code ----------------------------------------------------
my $dec = armdec->new;
my (@fns, $bytes, %weakb);
my %RELB = map { $_ => 1 } qw(R_ARM_CALL R_ARM_JUMP24 R_ARM_THM_CALL R_ARM_THM_JUMP24 R_ARM_PLT32);
for my $s (@secs) {
    my @lines = @{ $sec{$s}{lines} };
    next unless @lines;
    my %names;          # address -> names of symbols there
    # (a name the source makes an alias, index = strchr, after the others:
    # the function is strchr)
    push @{ $names{ $_->[0] } }, $_->[1] for sort { $a->[0] <=> $b->[0] || ($srcalias{ $a->[1] } // 0) <=> ($srcalias{ $b->[1] } // 0) || $a->[1] cmp $b->[1] } @{ $secsyms{$s} // [] };
    # (a section that starts before its first symbol, with instructions of
    # its own, sigrestorer.S's nop for the unwinder, strcmp.S's tail: a
    # local name of it)
    $names{ $lines[0]{addr} } //= ["$base $s"];
    my $lname = sub { my ($a) = @_; $names{$a} ? $names{$a}[0] : sprintf('.L %x', $a) };
    my (%target);     # addresses branches go to
    my @out;                # [address, node] in order
    # the zeros objdump leaves out (...): words of 0, the bytes of a gap
    my $next = $lines[0]{addr};
    my $zeros = sub {
        my ($to) = @_;
        while ($next < $to) {
            my $w = $next % 4 == 0 && $to - $next >= 4 ? 4 : 1;
            push @out, [$next, node($w == 4 ? 'word' : 'byte', node(0))];
            $bytes += $w;
            $next += $w;
        }
    };
    for my $i (@lines) {
        my $at = $i->{addr};
        $zeros->($at);
        $next = $at + ($i->{hex} =~ /^(\w{4}) (\w{4})$/ ? 4 : length($i->{hex}) / 2);
        my $rel = $i->{relocs}[0];
        if ($i->{op} =~ /^\.(word|short|byte)$/) {
            my $w = $1;
            my $v = hex $i->{hex};
            $bytes += { word => 4, short => 2, byte => 1 }->{$w};
            my $kind = { word => 'word', short => 'half', byte => 'byte' }->{$w};
            push @out, [$at, $rel ? data_reloc($rel, $v, $lname) : node($kind, node($v))];
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
            if ($rel && $RELB{ $rel->{type} } && $weakref{ $rel->{target} } && $undef{ $rel->{target} }) { $label = ".Lweak $rel->{target}"; $weakb{ $rel->{target} } = 1 }
            elsif ($rel && $RELB{ $rel->{type} }) { $label = $rel->{target} }
            elsif ($rel) { fail "a branch with $rel->{type}" }
            else { $label = $lname->($to); $target{$to} = 1 }
            $ops[$k] = node($mode eq 'a' ? 'arel' : 'trel', node($label));
        } elsif ($rel) {
            my ($k) = grep { $def->{params}[$_] eq 'imm16' } 0 .. $#{ $def->{params} };
            fail "$rel->{type} at $name" unless defined $k && $rel->{type} =~ /^R_ARM_MOV([WT])_(ABS_NC|ABS|PREL_NC|PREL)$/;
            my ($half, $pcrel) = ($1 eq 'W' ? 'lo16' : 'hi16', $2 =~ /PREL/);
            my $a = $ops->[$k]; $a -= 65536 if $a >= 32768;
            my $s = symbol($rel->{target}, $lname);
            my $val = $pcrel ? node('sub', node('pc'), $s, node('a0')) : $s;
            $val = node('addi', node($a), $val, node('a0')) if $a;
            $ops[$k] = node($half, $val);
        }
        push @out, [$at, node($name, @ops)];
    }
    $zeros->($secend{$s}) if defined $secend{$s};
    # the blocks: a label at each entry and each address a branch goes to
    my ($first) = @{ $names{ $lines[0]{addr} } };
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
    push @{ $fn->{children} }, map { node(".Lweak $_:", node('udf', node(0))) } sort keys %weakb;
    %weakb = ();
    push @fns, $fn;
}

# a symbol of a relocation: _GLOBAL_OFFSET_TABLE_ is the file's GOT, a
# local one (.L99^B2, a numeric label of GNU as) its label here
sub symbol {
    my ($t, $lname) = @_;
    return node("$base got") if $t eq '_GLOBAL_OFFSET_TABLE_';
    # (objdump shows a control character of a name as ^B in a relocation)
    $t =~ s/\^([A-Z@\[\\\]^_])/chr(ord($1) - 64)/ge;
    if ($dlab{$t}) {
        my ($b, $o) = @{ $dlab{$t} };
        return $o ? node('addi', node($o), node($b), node('a0')) : node($b);
    }
    if ($t =~ /^\.L/) {
        # (objdump shows a control character of a name as ^B in a relocation)
        (my $n = $t) =~ s/\^([A-Z@\[\\\]^_])/chr(ord($1) - 64)/ge;
        defined $sym{$n} or fail "no address for the local symbol $t";
        fail "the local symbol $t is in $symsec{$n}, not yet" unless $sec{ $symsec{$n} };
        return node($lname->($sym{$n}));
    }
    node($t);
}
# the word of data a relocation fills in
sub data_reloc {
    my ($r, $v, $lname) = @_;
    my ($type, $t) = ($r->{type}, $r->{target});
    my $a = $v >= 2**31 ? $v - 2**32 : $v;
    my $plus = sub { my ($n) = @_; $a ? node('addi', node($a), $n, node('a0')) : $n };
    if ($type eq 'R_ARM_ABS32') { return node('word', $plus->(symbol($t, $lname))) }
    if ($type eq 'R_ARM_REL32') { return node('word', $plus->(node('sub', node('pc'), symbol($t, $lname), node('a0')))) }
    if ($type eq 'R_ARM_GOTPC') { return node('word', $plus->(node('sub', node('pc'), node("$base got"), node('a0')))) }
    if ($type eq 'R_ARM_GOT32') { return node('word', $plus->(gotoff($t))) }
    if ($type eq 'R_ARM_GOTOFF32') { return node('word', $plus->(node('sub', node("$base got"), symbol($t, $lname), node('a0')))) }
    if ($type eq 'R_ARM_TLS_IE32') { $got{"$t tp"} = node('word', node('tprel', node($t))); return node('word', $plus->(node('sub', node('pc'), node("$base got $t tp"), node('a0')))) }
    fail "a word with $type";
}

if ($size) { print $bytes // 0, "\n"; exit }
# the GOT: its start, then a word for each symbol read through it, each a
# function of data, placed where the code names it (the code reads it at
# its offset from the start: it may be anywhere); the word of a weak name
# left undefined a C global, its address (0), as asm names no C weak
if (%got) {
    push @data, node("$base got:", node('asm'), node('align', node(4)));
    push @data, map { $weakref{$_} && $undef{$_} ? node("$base got $_:", node('void'), node('* pointer'), node($_), node('& address'))
        : node("$base got $_:", node('asm'), $got{$_}) } sort keys %got;
}
# a weak name the file declares and does not define (crti's __gmon_start__)
push @fns, map { node("$_:", node('weak'), node('function'), node('void')) } sort grep { $undef{$_} } keys %weakref;
# each alias once, and none of a name that is a function or a label of the
# code already (strchr.S's index = strchr, where index, first by name, is
# the function: strchr its alias, not both ways round)
my %seen;
my %entry = map { ($_->{content} =~ s/:$//r => 1) } @fns;
my $walk; $walk = sub { for (@{ $_[0]{children} }) { $entry{ $_->{content} =~ s/:$//r } = 1 if $_->{content} =~ /:$/; $walk->($_) } };
$walk->($_) for @fns;
@aliases = grep { my $n = $_->{content} =~ s/:$//r; !$seen{$n}++ && !$entry{$n} } @aliases;
my @all = (@fns, @data, @aliases);
print $items ? write_txt(@all) : write_txt(node("$page:", @all));
