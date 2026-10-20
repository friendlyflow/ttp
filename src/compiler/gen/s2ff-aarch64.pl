#!/usr/bin/env perl
# s2ff-aarch64.pl — aarch64 asm as ff: the functions of a preprocessed .S
# file (the .s its build assembled, from src/glibc/mki.pl), each an asm
# function of ttpc's C layer, name: / asm / its instructions, as s2ff.pl
# makes them for riscv64. One instruction per instruction, named and with
# its operands as ttpc's aarch64 section has them (isa/aarch64.pl: field
# order, the destination last); nothing is lowered.
#
#   perl s2ff-aarch64.pl [--page name] file.s file.dump > out.ff.txt
#   perl s2ff-aarch64.pl --items file.s file.dump    its functions alone
#   perl s2ff-aarch64.pl --size file.s file.dump     the bytes of those instructions
#   perl s2ff-aarch64.pl --skip file.s file.dump     the bytes of padding before them
#   perl s2ff-aarch64.pl crti.Ls crti.dump --then crtn.Ls crtn.dump
#                        crti's functions, its _init and _fini ended by
#                        crtn's .init and .fini, as the linker joins them
#   perl s2ff-aarch64.pl --locals file.s > file.Ls  numeric labels named
#
# GNU as's macros (.macro, .if, .rept), its aliases (mov, cmp, lsl, ...,
# which name other instructions) and .inst words are as GNU as made them:
# the instructions are read from what it made of the file, file.dump, by
# objdump -d -r -t -M no-aliases of the object assembled with -L (local
# labels kept in the symbol table) from file.Ls, the .s whose numeric
# labels (1:, 1f, 1b) --locals has named .L1__1, .L1__2, ... (the ff's
# .L1 1, .L1 2, as s2ff.pl has them). Each instruction word is decoded by
# the instructions of ttpc's aarch64 section itself: the one whose fixed
# fields it has (the most specific; between equals, GNU's name), its
# operands its fields' values, a register by the name objdump prints for
# it; that name must start with the mnemonic objdump prints (or be one of
# the hints or sys forms it names). Where a relocation fills a field, the
# operand is its symbol: rel / name (a branch or a call), pagerel / name
# (adrp), lo12 / name (the add or load after it); a GOT entry's adrp and
# ldr read a word the function carries (.Lgot name: / dword / name). A
# branch to a label of the file is rel / label.
#
#   labels          a function is a global label or a local one not .L
#                   (and not GNU's mapping symbols $x $d); a .L label in it
#                   a block label holding the instructions up to the next;
#                   a function the one before runs on into (its last
#                   instruction not a b, br or ret) is an entry block in it
#                   (asm first), as in s2ff.pl; X = Y and .set X, Y aliases
#   padding         the nops GNU as put in to align are kept in the
#                   function before them, those at the end of the section
#                   dropped (ttpc places a function on a 4-byte boundary)
#   .weak X         X undefined here (crti's __gmon_start__): X: / weak /
#                   function / void, at 0 unless something defines it
#   --zero name     the objects c2ff --zero makes (else a zero object's
#                   aliases, which then name nothing, are left out)
#   other sections  .data .bss .section: a zeroed object (.zero N) is c2ff
#                   --zero's global, its other labels aliases; an init
#                   array is left out; any other bytes stop the translation
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt);

my $page = 'glibc asm';
my @files;
my ($size, $items, $locals, $skipopt, @then, %zeroed);
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--size') { $size = 1; next }
    if ($a eq '--items') { $items = 1; next }
    if ($a eq '--locals') { $locals = 1; next }
    if ($a eq '--skip') { $skipopt = 1; next }
    if ($a eq '--then') { @then = splice @ARGV, 0, 2; next }
    if ($a eq '--zero') { $zeroed{ shift @ARGV } = 1; next }
    push @files, $a;
}
my $src = $files[0] // die "usage: s2ff-aarch64.pl [--page name | --items | --size] file.s file.dump | --locals file.s\n";
my $where = $src;
sub fail { die "s2ff: $where: @_\n" }

# ---- --locals: the numeric labels named ------------------------------------
# GNU as keeps no numeric label in the symbol table, even with -L: each gets
# a name of its own, .L<n>__<k> for the k-th definition of n:, and 1f, 1b
# the one after, the one before. (Only outside a .macro: a label in a
# macro's body would be defined by each expansion.)
if ($locals) {
    open my $s, '<', $src or die "s2ff: cannot open $src: $!\n";
    my %count;
    my $inmacro = 0;
    while (my $l = <$s>) {
        if ($l =~ /^#/) { print $l; next }
        my @st = split /;/, $l, -1;
        for (@st) {
            $inmacro = 1 if /^\s*\.macro\b/;
            $inmacro = 0 if /^\s*\.endm\b/;
            next if $inmacro;
            # definitions first, so that 1b after 1: on one line is this one
            my $out = '';
            my $rest = $_;
            while ($rest =~ s/^(\s*)(\d+):/$1/) { my $n = $2; $count{$n}++; $out .= ".L${n}__$count{$n}:" }
            $rest =~ s/(?<![.\w])(\d+)([fb])\b/".L$1__" . (($count{$1} \/\/ 0) + ($2 eq 'f' ? 1 : 0))/ge
                if $rest =~ /^\s*[a-z]/ && $rest !~ /^\s*\./;
            $_ = $out . $rest;
        }
        print join ';', @st;
    }
    exit;
}
@files == 2 or die "usage: s2ff-aarch64.pl [--page name | --items | --size] file.s file.dump\n";
my $dump = $files[1];

# ---- ttpc's aarch64 instructions: fixed fields and operand slices -----------
my @defs;
my %inverse;    # a def's operand of a computed field: the operand from the field
my %computed = (shr16 => sub { 16 - $_[0] });
{
    my $section = do "$FindBin::Bin/../isa/aarch64.pl";
    die "s2ff: isa/aarch64.pl: $@" if $@;
    for my $g (@{ $section->{children} }) {
        next if $g->{content} =~ /^(registers|slices|macros|elf|c|linux|rv64):$/;
        for my $d (@{ $g->{children} }) {
            my ($name) = $d->{content} =~ /^(.+):$/ or next;
            next if $name =~ /\[/;     # a field's function (shr16[6:0])
            my (@params, @fields);
            for my $k (@{ $d->{children} }) {
                if (!@{ $k->{children} }) { push @params, $k->{content}; next }
                if ($k->{content} =~ /^(\w+):$/) { push @fields, [fixed => $k->{children}[0]{content}]; next }
                $k->{content} =~ /^(\w+)\[(\d+)(?::(\d+))?\]$/ or die "s2ff: isa: $name: field $k->{content}\n";
                my ($fn, $hi, $lo, $p) = ($1, $2, $3 // $2, $k->{children}[0]{content});
                # a computed field: its operand from its bits
                if ($fn ne $p) { $inverse{$name}{$p} = $computed{$fn} // die "s2ff: isa: $name: no inverse of $fn\n" }
                push @fields, [slice => $p, $hi, $lo];
            }
            my ($pos, $mask, $value, %slices, %top) = (32, 0, 0);
            for my $f (@fields) {
                if ($f->[0] eq 'fixed') {
                    my $w = length $f->[1];
                    $pos -= $w;
                    $mask |= ((1 << $w) - 1) << $pos;
                    $value |= oct("0b$f->[1]") << $pos;
                } else {
                    my ($p, $hi, $lo) = @$f[1 .. 3];
                    $pos -= $hi - $lo + 1;
                    push @{ $slices{$p} }, [$pos, $hi, $lo];
                    $top{$p} = $hi if !defined $top{$p} || $hi > $top{$p};
                }
            }
            die "s2ff: isa: $name has $pos bits left\n" if $pos;
            push @defs, { name => $name, params => \@params, mask => $mask, value => $value, slices => \%slices,
                top => \%top, bits => unpack('%32b*', pack('N', $mask)) };
        }
    }
}
my %regparam = map { $_ => 1 } qw(rd rn rm ra rt rt2 rs zd zn zm zt pd pn pm pg);
my @cond = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le al nv);
# what objdump calls an instruction ttpc has by another name
my %named = (hint => qr/^(nop|bti(\.\w+)?|paciasp|autiasp|chkfeat)$/, sys => qr/^(dc\.\w+|gcsss1)$/,
    sysl => qr/^(gcsss2|gcspopm)$/);
sub pcrel { $_[0] =~ /^(b|bl|b\.\w+|cbn?zw?|tbn?z|adrp?|\S+\.lit)$/ }

sub decode {
    my ($word, $m) = @_;
    my @c = grep { ($word & $_->{mask}) == $_->{value} } @defs;
    fail "no ff form for $m->{op} $m->{args} (" . sprintf('%08x', $word) . ")" unless @c;
    my $best = (sort { $b <=> $a } map { $_->{bits} } @c)[0];
    @c = grep { $_->{bits} == $best } @c;
    my ($d) = ((grep { $_->{name} eq $m->{op} } @c), @c);
    my $ok = index($d->{name}, $m->{op}) == 0 || ($named{ $m->{op} } && $d->{name} =~ $named{ $m->{op} });
    fail "ttpc's $d->{name} for $m->{op} $m->{args}" unless $ok;
    my %v;
    for my $p (@{ $d->{params} }) {
        my $v = 0;
        for (@{ $d->{slices}{$p} }) {
            my ($pos, $hi, $lo) = @$_;
            $v |= (($word >> $pos) & ((1 << ($hi - $lo + 1)) - 1)) << $lo;
        }
        $v -= 1 << ($d->{top}{$p} + 1) if $p eq 'imm' && $v >> $d->{top}{$p} & 1;
        $v = $inverse{ $d->{name} }{$p}->($v) if $inverse{ $d->{name} } && $inverse{ $d->{name} }{$p};
        $v{$p} = $v;
    }
    ($d, \%v);
}

# ---- what GNU as made --------------------------------------------------------
# The instructions of the code sections (.text; crti's and crtn's .init and
# .fini), in the dump's order, and (of the file itself) its symbols.
my (%sym, %sect, %type, %bind);
my %code = map { $_ => 1 } qw(.text .init .fini);
sub readdump {
    my ($file, $symbols) = @_;
    my @made;
    open my $d, '<', $file or die "s2ff: cannot open $file: $!\n";
    my $insec = '';
    while (<$d>) {
        chomp;
        # the symbol table: value, flags, section, size, name
        if ($symbols && /^([0-9a-f]{16}) (.{7}) (\S+)\t[0-9a-f]+ (.+)$/) {
            my ($v, $flags, $sec, $name) = (hex $1, $2, $3, $4);
            $name =~ s/^\.(hidden|protected|internal) //;
            next if $name =~ /^\$[xd]/ || $flags =~ /d/ || $sec eq '*ABS*';
            $sect{$name} = $sec;
            next if $sec eq '*UND*';
            $bind{$name} = $flags =~ /^[gwu!]/ || substr($flags, 1, 1) eq 'w' ? 'global' : 'local';
            $type{$name} = $flags =~ /F/ ? 'function' : $flags =~ /O/ ? 'object' : '';
            push @{ $sym{$sec}{$v} }, $name;
            next;
        }
        $insec = $1 if /^Disassembly of section (\S+):/;
        next unless $code{$insec};
        if (/^\s*([0-9a-f]+):\t([0-9a-f]{8}) \t(\S+)\s*(.*?)\s*$/) {
            my ($a, $w, $op, $args) = (hex $1, hex $2, $3, $4);
            $args =~ s/\s*\/\/.*$//;
            $args =~ s/\s*<[^>]*>$//;
            push @made, { sec => $insec, addr => $a, word => $w, op => $op, args => $args };
            next;
        }
        if (/^\s*([0-9a-f]+): (R_AARCH64_\w+)\s+(\S+)$/) {
            my ($a, $t, $s) = (hex $1, $2, $3);
            fail "a relocation of $s at $a outside an instruction" unless @made && $made[-1]{addr} == $a;
            # (a local label is named by its section and offset: .text+0x34)
            if ($s =~ /^(\.[\w.]+)(?:\+0x([0-9a-f]+))?$/ && !exists $sect{$s}) { $s = [$1, hex($2 // 0)] }
            elsif ($s =~ /[+-]0x/) { fail "a relocation $t of $s with an addend" }
            $made[-1]{reloc} = [$t, $s];
        }
    }
    close $d;
    @made;
}
my @all = readdump($dump, 1);
my @made = grep { $_->{sec} eq '.text' } @all;
# the padding at the end of the section
pop @made while @made && $made[-1]{op} eq 'hint' && $made[-1]{args} eq '#0x0' && !($sym{'.text'}{ $made[-1]{addr} });
# the padding before the first label (ENTRY_ALIGN_AND_PAD: strncmp's nops)
my $skip = 0;
while (@made && $made[0]{op} eq 'hint' && $made[0]{args} eq '#0x0' && !$sym{'.text'}{ $made[0]{addr} }) { shift @made; $skip += 4 }
if ($size) { print 4 * @made, "\n"; exit }
if ($skipopt) { print "$skip\n"; exit }
push @made, grep { $_->{sec} ne '.text' } @all;

# ---- the source: where each label is, its aliases, its other sections ---------
my (%line, %alias, @fns, @data, %rodata, %weakref);
{
    open my $s, '<', $src or die "s2ff: cannot open $src: $!\n";
    my ($file, $ln, $other, @pending, %datadef, %count) = ('', 0);
    my $inmacro = 0;
    while (my $l = <$s>) {
        chomp $l;
        if ($l =~ /^# (\d+) "([^"]+)"/) { ($ln, $file) = ($1 - 1, $2 =~ s{^(\.\./)+}{}r); next }
        $ln++;
        $l =~ s/\s*\/\/.*$// unless $l =~ /"/;
        $where = "$src ($file:$ln)";
        for my $st (split /;/, $l) {
            $st =~ s/^\s+|\s+$//g;
            next if $st eq '';
            $inmacro = 1 if $st =~ /^\.macro\b/;
            if ($inmacro) { $inmacro = 0 if $st =~ /^\.endm\b/; next }
            if ($st =~ /^\.(data|bss|section\s+([^,\s]+)(,.*)?)$/ || $st =~ /^\.(previous)$/) {
                my $sec = $2 // ".$1";
                $sec = '.text' if $sec eq '.previous';
                if ($code{$sec}) { $other = undef; next }
                $other = $sec;
                @pending = ();
                warn "s2ff: $where: $sec left out\n" if $sec =~ /^\.(pre)?init_array$|^\.fini_array$/;
                next;
            }
            if ($st eq '.text') { $other = undef; next }
            if (defined $other) {
                next if $st =~ /^\.(globl|global|weak|type|size|hidden|align|p2align|balign)\b/;
                if ($st =~ /^([.\w]+):$/) { push @pending, $1; next }
                if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/) { push @data, node("$1:", node('alias'), node($2)) if $datadef{$2}; next }
                next if $other =~ /^\.(pre)?init_array$|^\.fini_array$/ && $st =~ /^\.(dc\.a|xword|quad)\s+[.\w]+$/;
                # read-only text (__arm_za_disable's message): its label's
                # bytes, which the function that names it carries
                if ($other =~ /^\.rodata/ && $st =~ /^\.(string|asciz|ascii)\s+"((?:[^"\\]|\\.)*)"$/ && @pending) {
                    my ($k, $t) = ($1, $2);
                    my %e = (n => "\n", t => "\t", r => "\r", '"' => '"', '\\' => '\\');
                    $t =~ s/\\(?:([0-7]{1,3})|x([0-9a-fA-F]{1,2})|(.))/defined $1 ? chr oct $1 : defined $2 ? chr hex $2 : $e{$3} \/\/ fail "an escape \\$3"/ge;
                    $t .= "\0" unless $k eq 'ascii';
                    $rodata{$_} = [node('ascii', node($t))] for @pending;
                    @pending = ();
                    next;
                }
                # (a zero word is one too: start.S's __data_start, .long 0)
                $st = '.zero ' . { long => 4, word => 4, quad => 8, xword => 8, byte => 1, hword => 2 }->{$1} if $st =~ /^\.(long|word|quad|xword|byte|hword)\s+0$/;
                if ($st =~ /^\.(zero|space)\s+(\d+)$/ && @pending) {
                    my ($first, @more) = @pending;
                    # (its aliases only where c2ff --zero makes it, --zero here
                    # too: start.S's __data_start, which no C declares, is not)
                    if (!%zeroed || $zeroed{$first}) {
                        $datadef{$_} = 1 for @pending;
                        push @data, map { node("$_:", node('alias'), node($first)) } @more;
                    }
                    warn "s2ff: $where: $first is zero, c2ff --zero $first makes it\n";
                    @pending = ();
                    next;
                }
                fail "bytes in $other: $st";
            }
            while ($st =~ s/^([.\w]+):\s*//) {
                my $name = $1;
                $line{$name} //= "$file:$ln";
            }
            next if $st eq '';
            if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/ || $st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)$/) { $alias{$1} = $2; next }
            $weakref{$1} = 1 if $st =~ /^\.weak\s+([.\w]+)$/;
        }
    }
    close $s;
    $where = $src;
}

# ---- the functions -----------------------------------------------------------
sub ffname { my ($n) = @_; $n =~ s/^\.L(\d+)__(\d+)$/.L$1 $2/; $n }
my %at;         # "section address" -> its labels
for my $sec (keys %code) { for my $a (keys %{ $sym{$sec} || {} }) { $at{"$sec $a"} = [grep { !exists $alias{$_} } @{ $sym{$sec}{$a} }] } }
my %labelat;    # an address a branch may name
for my $k (keys %at) { my ($l) = sort { ($a =~ /^\.L/) <=> ($b =~ /^\.L/) } @{ $at{$k} }; $labelat{$k} = $l if defined $l }
my ($fn, $block, $ends, %got, %ro, %rodone, %weakb);
my @weakgot;    # GOT words of a weak name nothing here defines: C globals
sub finish {
    push @{ $fn->{children} }, map { node(".Lweak $_:", node('brk', node(0))) } sort keys %weakb if $fn;
    %weakb = ();
    return unless $fn && (%got || %ro);
    # (a word of the function holds a name's address; a weak name nothing
    # defines (crti's __gmon_start__) is 0, as ttpc's C has it, so its word
    # is a C global: address / void / address / name)
    my @weak = grep { $weakref{$_} && ($sect{$_} // '') eq '*UND*' } keys %got;
    delete @got{@weak};
    push @weakgot, map { node(".Lgot $_:", node('address'), node('void'), node('address', node($_))) } sort @weak;
    push @{ $fn->{children} }, node('align', node(8)), map { node(".Lgot $_:", node('dword', node($_))) } sort keys %got if %got;
    # (text ends where it ends: what follows the function starts on 8 again)
    push @{ $fn->{children} }, (map { node(ffname($_) . ':', @{ $rodata{$_} }) } sort keys %ro), node('align', node(8)) if %ro;
    %got = %ro = ();
}
# a relocation's symbol: a name, or a label of the file by its section and
# offset (read-only text then carried by the function)
sub symof {
    my ($s) = @_;
    return $s unless ref $s;
    my ($sec, $off) = @$s;
    my ($l) = sort { ($a =~ /^\.L/) <=> ($b =~ /^\.L/) } grep { !exists $alias{$_} } @{ $sym{$sec}{$off} || [] };
    defined $l or fail "no label at $sec+$off";
    if ($sec ne '.text') {
        $rodata{$l} or fail "$l in $sec: no bytes for it";
        $ro{$l} = 1 unless $rodone{$l}++;
    }
    ffname($l);
}
sub leaf { node($_[0]) }
my %fnof;       # a function's node by its name
sub emit;
my $cursec = '';
for my $m (@made) {
    # (a function never runs on into another section: crti's _init, _fini)
    ($ends, $cursec) = (1, $m->{sec}) if $m->{sec} ne $cursec;
    for my $name (sort { ($a =~ /^\.L/) <=> ($b =~ /^\.L/) || $a cmp $b } @{ $at{"$m->{sec} $m->{addr}"} || [] }) {
        my $c = node('comment', node('glibc-2.44 ' . ($line{$name} // $src)));
        if ($name =~ /^\.L/) {
            fail "label $name outside a function" unless $fn;
            $block = node(ffname($name) . ':');
            push @{ $fn->{children} }, $block;
        } elsif ($fn && !$ends) {
            $block = node("$name:", node('asm'), $c);
            push @{ $fn->{children} }, $block;
        } else {
            finish();
            $fn = node("$name:", node('asm'), $c);
            $fnof{$name} = $fn;
            push @fns, $fn;
            undef $block;
        }
    }
    fail "an instruction outside a function at $m->{addr}" unless $fn;
    emit($m);
}
finish();
# crtn's .init and .fini (--then crtn.Ls crtn.dump): the end of crti's
# _init and _fini, the functions of those sections there, as the linker
# puts crtn's after crti's
if (@then) {
    for my $m (readdump($then[1], 0)) {
        next if $m->{sec} eq '.text';
        my ($name) = @{ $at{"$m->{sec} 0"} || [] } or fail "no function of $m->{sec} for $then[0]";
        ($fn, $block) = ($fnof{$name}, undef);
        emit($m);
    }
}
sub emit {
    my ($m) = @_;
    my ($def, $v) = decode($m->{word}, $m);
    # the registers by the names objdump gives them
    my @tok;
    while ($m->{args} =~ /(?<![\w.])([xwvqdshbzp])(\d+)\b|\b(sp|wsp|xzr|wzr)\b/g) {
        push @tok, defined $3 ? [$3, 31] : ["$1$2", $2];
    }
    my @ops;
    my ($rt, $rs) = @{ $m->{reloc} || [] };
    $rs = symof($rs) if defined $rs;
    for my $p (@{ $def->{params} }) {
        my $val = $v->{$p};
        if ($regparam{$p}) {
            my ($i) = grep { $tok[$_] && $tok[$_][1] == $val } 0 .. $#tok;
            # (xzr where objdump names none: gcspopm)
            if (!defined $i && $val == 31) { push @ops, leaf('xzr'); next }
            defined $i or fail "no register $val in $m->{op} $m->{args}";
            push @ops, leaf($tok[$i][0]);
            undef $tok[$i];
            next;
        }
        if ($p eq 'imm' && pcrel($def->{name})) {
            # (a branch to a weak name nothing defines, crti's b __gmon_start__
            # after its cbz: to a trap the function carries, .Lweak name)
            if ($rt && $rt =~ /^R_AARCH64_(CALL26|JUMP26|CONDBR19|TSTBR14)$/ && $weakref{$rs} && ($sect{$rs} // '') eq '*UND*') { $weakb{$rs} = 1; push @ops, node('rel', leaf(".Lweak $rs")); next }
            if ($rt && $rt =~ /^R_AARCH64_(CALL26|JUMP26|CONDBR19|TSTBR14)$/) { push @ops, node('rel', leaf($rs)); next }
            if ($rt && $rt eq 'R_AARCH64_ADR_PREL_PG_HI21') { push @ops, node('pagerel', leaf($rs)); next }
            if ($rt && $rt eq 'R_AARCH64_ADR_GOT_PAGE') { $got{$rs} = 1; push @ops, node('pagerel', leaf(".Lgot $rs")); next }
            fail "a relocation $rt in $m->{op}" if $rt;
            my $to = $def->{name} eq 'adrp' ? ($m->{addr} & ~4095) + $val : $m->{addr} + $val;
            my $l = $labelat{"$m->{sec} $to"} // fail "$m->{op} $m->{args}: no label at $to";
            push @ops, node($def->{name} eq 'adrp' ? 'pagerel' : 'rel', leaf(ffname($l)));
            next;
        }
        if ($p eq 'uimm' && $rt && $rt =~ /^R_AARCH64_(ADD_ABS_LO12_NC|LDST(8|16|32|64|128)_ABS_LO12_NC)$/) { push @ops, node('lo12', leaf($rs)); next }
        if ($p eq 'uimm' && $rt && $rt eq 'R_AARCH64_LD64_GOT_LO12_NC') { $got{$rs} = 1; push @ops, node('lo12', leaf(".Lgot $rs")); next }
        if ($p eq 'cond') { push @ops, leaf($cond[$val]); next }
        push @ops, leaf($val);
    }
    fail "a relocation $rt in $m->{op} $m->{args}, no operand of it" if $rt && !grep { @{ $_->{children} } } @ops;
    push @{ ($block // $fn)->{children} }, node($def->{name}, @ops);
    $ends = $def->{name} =~ /^(b|br|ret|retr)$/ ? 1 : 0;
}
# aliases: X = Y, of a function here
push @fns, map { node("$_:", node('alias'), node($alias{$_})) } sort grep { exists $sect{$_} || 1 } keys %alias;
push @fns, @data;
# a weak name the file declares and does not define (crti's __gmon_start__):
# a function that may stay undefined, at 0
push @fns, map { node("$_:", node('weak'), node('function'), node('void')) } sort grep { ($sect{$_} // '') eq '*UND*' } keys %weakref;
push @fns, @weakgot;
# A function that jumps to a block label of a function after it (setjmp.S:
# setjmp's b 1f, to a label in __sigsetjmp): the functions from it to that
# one are one asm function, each later one's name an entry block in it
# (asm first, its own instructions, then its blocks after it), as a block
# label is known only inside its function (s2ff.pl's rule).
{
    my $isasm = sub { @{ $_[0]{children} } && $_[0]{children}[0]{content} eq 'asm' };
    my $blocks = sub { my ($f) = @_; my @b; my $w; $w = sub { for (@{ $_[0]{children} }) { if ($_->{content} =~ /^(.+):$/ && @{ $_->{children} }) { push @b, $1; $w->($_) } } }; $w->($f); @b };
    my $targets = sub { my ($f) = @_; my @t; my $w; $w = sub { for (@{ $_[0]{children} }) { push @t, $_->{children}[0]{content} if $_->{content} eq 'rel'; $w->($_) } }; $w->($f); @t };
    for (my $i = 0; $i + 1 < @fns; $i++) {
        next unless $isasm->($fns[$i]);
        my %t = map { $_ => 1 } $targets->($fns[$i]);
        my $last;
        for (my $j = $i + 1; $j < @fns && $isasm->($fns[$j]); $j++) { $last = $j if grep { $t{$_} } $blocks->($fns[$j]) }
        next unless defined $last;
        for my $g (splice @fns, $i + 1, $last - $i) {
            my ($asm, @rest) = @{ $g->{children} };
            my (@own, @later);
            for (@rest) { if (@later || ($_->{content} =~ /:$/ && @{ $_->{children} } && $_->{content} ne 'comment')) { push @later, $_ } else { push @own, $_ } }
            push @{ $fns[$i]{children} }, node($g->{content}, $asm, @own), @later;
        }
        $i--;
    }
}
print $items ? write_txt(@fns) : write_txt(node("$page:", @fns));
