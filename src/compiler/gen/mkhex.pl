#!/usr/bin/env perl
# mkhex.pl — the commented hex texts of the hex seed (lane H), made once
# from GNU as's output: every byte with the asm line it comes from.
#
#   perl gen/mkhex.pl hex0 <prog.s> > <prog>.hex0
#   perl gen/mkhex.pl hex2 <ttpc.s> > ttpc.hex2
#   perl gen/mkhex.pl flat <prog.s> > <prog>.hex2
#   perl gen/mkhex.pl m1 <prog.s> > <prog>.M1
#
# hex0: <prog.s> is a flat program that writes its own ELF header (one
# section, no relocations, see gen/hex/x86_64/); the text is its bytes,
# a line per asm line, each with its file offset and the line. hex2:
# <prog.s> is linked as the Makefile's SEED=gnu does (as
# -mx86-used-note=no, ld -static -s -z noseparate-code); the text is the
# whole file in its order: the ELF header and program headers field by
# field, each section's lines (labels as :label, rel32 references as
# %label, rel8 as !label, absolute ones as &label, the rest written out),
# ^address where the addresses jump (the data segment, the labels of the
# bss), the section names and headers. flat: <prog.s> as for hex0, the
# text hex2 (hex2 makes M1 of M1.hex2): its lines with labels and
# references as for hex2. m1: <prog.s> as for hex0, the text M1 (M1 makes
# hex2 text of asm.M1): a DEFINE for each instruction form it uses (its
# name the instruction with its fields as $i8 $i32 d8 d32 rel, its value
# the opcode bytes before them, with a comment of what they are), then its
# lines with the fields as M1 numbers and labels. hex0, hex2 and M1 read
# the texts in the chain;
# this script and binutils are only how they were made (and checked: make
# hex). A dev aid (core Perl, binutils), not in the chain.
use strict;
use warnings;
use File::Temp qw(tempdir);

die "usage: mkhex.pl hex0|hex2|flat|m1 <prog.s>\n" unless @ARGV == 2 && $ARGV[0] =~ /^(hex[02]|flat|m1)$/;
my ($mode, $src) = @ARGV;
my $t = tempdir(CLEANUP => 1);
sub run { system(@_) == 0 or die "mkhex: @_ failed\n" }
sub out { my $c = shift; my $o = `$c`; die "mkhex: $c failed\n" if $?; $o }
sub slurp { open my $f, '<:raw', $_[0] or die "mkhex: $_[0]: $!\n"; local $/; <$f> }

run('as', '-mx86-used-note=no', "-aln=$t/l", '--listing-cont-lines=1000000', $src, '-o', "$t/o");
my $bin;
if ($mode ne 'hex2') {
    run('objcopy', '-O', 'binary', '-j', '.text', "$t/o", "$t/bin");
} else {
    run('ld', '-static', '-z', 'noseparate-code', '-e', '_start', "$t/o", '-o', "$t/u");
    run('ld', '-static', '-s', '-z', 'noseparate-code', '-e', '_start', "$t/o", '-o', "$t/bin");
}
$bin = slurp("$t/bin");

# the sections: name -> [addr, file offset, size, nobits]
my (%sec, @order);
if ($mode ne 'hex2') {
    %sec = ('.text' => [0, 0, length $bin, 0]);
    @order = ('.text');
} else {
    for (split /\n/, out("readelf -SW $t/bin")) {
        next unless /^\s*\[\s*\d+\]\s+(\.\S+)\s+(\S+)\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)/;
        $sec{$1} = [hex $3, hex $4, hex $5, $2 eq 'NOBITS'];
        push @order, $1;
    }
}

# the listing: the first offset of every line that emits
my %off;
for (split /\n/, slurp("$t/l")) {
    $off{$1} //= hex $2 if /^\s*(\d+) ([0-9a-f]{4,}) [0-9A-F]/;
}

# the source lines: section, labels, mnemonic and operands
my @src = split /\n/, slurp($src), -1;
pop @src if @src && $src[-1] eq '';
my $cur = '.text';
my (@line, %bysec, %count);
my $last = '';
for my $n (1 .. @src) {
    my $s = $src[$n - 1];
    my $code = $s;
    $code =~ s/\s#.*//;
    $code =~ s/^#.*//;
    if ($code =~ /^\s*\.section\s+(\.\w+)/) { $cur = $1 }
    elsif ($code =~ /^\s*\.(text|data|bss)\b/) { $cur = ".$1" }
    my $l = { n => $n, text => $s, sec => $cur, labels => [] };
    while ($code =~ s/^\s*([A-Za-z_.][\w.]*|\d+):(?!\S)//) {
        my $name = $1;
        if ($name =~ /^\d+$/) {
            my $base = "$last.$name";
            my $k = ++$count{$base};
            push @{ $l->{labels} }, { name => $k == 1 ? $base : "$base.$k", num => $name };
        } else {
            $last = $name;
            push @{ $l->{labels} }, { name => $name };
        }
    }
    ($l->{mn}, $l->{ops}) = $code =~ /^\s*([.a-z][\w.]*)\s*(.*?)\s*$/ ? ($1, $2) : ('', '');
    $l->{off} = $off{$n};
    push @line, $l;
    push @{ $bysec{$cur} }, $l;
}

# every line's bytes and every label's address
my (%at, %label);
for my $s (keys %bysec) {
    my $L = $bysec{$s};
    die "mkhex: $s lines but no section\n" unless $sec{$s} || !grep { defined $_->{off} } @$L;
    next unless $sec{$s};
    my ($addr, $foff, $size, $nobits) = @{ $sec{$s} };
    my $next = $size;
    for my $l (reverse @$L) {
        if (defined $l->{off}) { $l->{end} = $next; $next = $l->{off} }
        $l->{at} = $next;
        for (@{ $l->{labels} }) {
            $_->{addr} = $addr + $next;
            die "mkhex: label $_->{name} twice\n" if $label{ $_->{name} };
            $label{ $_->{name} } = $_;
            push @{ $at{ $_->{addr} } }, $_;
        }
    }
}

# the name for a reference to addr whose operand text is ops
sub name_at {
    my ($addr, $ops) = @_;
    my $c = $at{$addr} or return;
    for (@$c) { return $_->{name} if !defined $_->{num} && $ops =~ /(?<![\w.])\Q$_->{name}\E(?![\w.])/ }
    for (@$c) { return $_->{name} if defined $_->{num} && $ops =~ /(?<![\w.])\Q$_->{num}\E[fb]\b/ }
    return;
}

# hex2: the references (relocations, branches, rip-relative ones in .text)
my %reloc;    # section -> offset -> [type, target]
if ($mode eq 'hex2') {
    my %sym;
    for (split /\n/, out("readelf -sW $t/u")) {
        my @f = split;
        next unless @f >= 8 && $f[0] =~ /^\d+:$/ && $f[6] ne 'ABS' && $f[6] ne 'UND';
        $sym{ $f[7] } = hex $f[1];
    }
    my $rs;
    for (split /\n/, out("readelf -rW $t/o")) {
        $rs = $1 if /'\.rela(\.\w+)'/;
        next unless /^([0-9a-f]+)\s+[0-9a-f]+\s+(R_X86_64_\w+)\s+[0-9a-f]+\s+(\S+)\s*([+-])\s*([0-9a-f]+)/;
        my ($o, $type, $s, $sign, $a) = (hex $1, $2, $3, $4, hex $5);
        my $S = $sec{$s} ? $sec{$s}[0] : $sym{$s} // die "mkhex: no symbol $s\n";
        $reloc{$rs}{$o} = [$type, $S + ($sign eq '-' ? -$a : $a)];
    }
}

sub le { my ($v, $n) = @_; join '', map { sprintf '%02X', ($v >> 8 * $_) & 255 } 0 .. $n - 1 }
sub sx { my ($v, $n) = @_; my $m = 1 << 8 * $n; $v &= $m - 1; $v >= $m / 2 ? $v - $m : $v }
sub rd { my ($o, $n) = @_; my $v = 0; $v |= ord(substr $bin, $o + $_, 1) << 8 * $_ for 0 .. $n - 1; $v }

# a line's bytes as tokens: [start, length, token] for each reference
sub fields {
    my ($l) = @_;
    my ($addr, $foff) = @{ $sec{ $l->{sec} } };
    my ($o, $e) = ($l->{off}, $l->{end});
    my (@f, @raw, $rel);
    for my $p ($o .. $e - 1) {
        my $r = $reloc{ $l->{sec} }{$p} or next;
        $rel = 1;
        my ($type, $T) = @$r;
        my $P = $addr + $p;
        if ($type eq 'R_X86_64_PC32') {
            # the target as the field says, from the address after it; an
            # immediate after the field (k bytes) takes it from further on
            my $k = $addr + $e - ($P + 4);
            my $tgt = sx(rd($foff + $p, 4), 4) + $P + 4;
            my $name = $k == 0 ? name_at($tgt, $l->{ops}) : undef;
            if ($name) { push @f, [$p, 4, "%$name"] }
            else { my $to = $tgt + $k; push @raw, sprintf('rel32 to %s', name_at($to, $l->{ops}) // sprintf '0x%x', $to) . ($k ? ", from the end of the instruction, $k bytes after the field" : '') }
        } elsif ($type eq 'R_X86_64_64') {
            my $v = rd($foff + $p, 8);
            my $name = $v >> 32 ? undef : name_at($v, $l->{ops});
            if ($name) { push @f, [$p, 4, "&$name"] }
            else { push @raw, sprintf 'abs64 0x%x', $v }
        } else { die "mkhex: relocation $type\n" }
    }
    my $len = $e - $o;
    if (!$rel && $l->{sec} eq '.text' && $l->{mn} =~ /^(j[a-z]+|call|loop\w*)$/ && $l->{ops} !~ /^\*/) {
        my $n = $len == 2 ? 1 : 4;
        my $tgt = $addr + $e + sx(rd($foff + $e - $n, $n), $n);
        my $name = name_at($tgt, $l->{ops});
        die "mkhex: line $l->{n}: no label at the target of $l->{text}\n" unless $name;
        push @f, [$e - $n, $n, ($n == 1 ? '!' : '%') . $name];
    } elsif (!$rel && $l->{sec} eq '.text' && $l->{ops} =~ /\(%rip\)/) {
        my $tgt = $addr + $e + sx(rd($foff + $e - 4, 4), 4);
        my $name = name_at($tgt, $l->{ops});
        if ($name) { push @f, [$e - 4, 4, "%$name"] }
        else { push @raw, sprintf 'rel32 to 0x%x', $tgt }
    }
    return (\@f, @raw ? ' (written out: ' . join(', ', @raw) . ')' : '');
}

# the hex text of the bytes [o, e) of a section, with fields
sub hexline {
    my ($foff, $o, $e, @f) = @_;
    my @tok;
    my $p = $o;
    for (sort { $a->[0] <=> $b->[0] } @f) {
        push @tok, uc unpack('H*', substr $bin, $foff + $p, $_->[0] - $p) if $_->[0] > $p;
        push @tok, $_->[2];
        $p = $_->[0] + $_->[1];
    }
    push @tok, uc unpack('H*', substr $bin, $foff + $p, $e - $p) if $e > $p;
    return join ' ', @tok;
}

sub cm { $_[0] =~ /^\s*#/ ? $_[0] : "# $_[0]" }

sub row {
    my ($code, $comment) = @_;
    return $comment =~ /^\s*#/ ? $comment : "# $comment" if $code eq '';
    my $w = $mode eq 'hex0' ? 24 : 40;
    return $code if $comment eq '';
    return sprintf "%-*s # %s", $w - 1, $code, $comment;
}

my @out;
my $lic = <<'EOF';
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software: you can redistribute it and/or modify it under the terms of the
# GNU General Public License as published by the Free Software Foundation,
# version 3 of the License. It comes with no warranty. See the file LICENSE
# for the full text.
#
EOF
push @out, split /\n/, $lic;

# a section's lines; hex data wraps at 16 bytes, the asm line on the first
sub section_rows {
    my ($s) = @_;
    my ($addr, $foff, $size, $nobits) = @{ $sec{$s} };
    my @r;
    for my $l (@{ $bysec{$s} }) {
        my $t = $l->{text};
        my $defs = join ' ', map { ":$_->{name}" } @{ $l->{labels} };
        if ($nobits) {
            push @r, row(sprintf('^%08X %s', $addr + $l->{at}, $defs), $t) and next if $defs ne '';
            push @r, $t eq '' ? '' : cm($t);
            next;
        }
        if ($mode eq 'hex0') {
            my $a = sprintf '%04x', $l->{at};
            if (!defined $l->{off}) { push @r, $t eq '' ? '' : @{ $l->{labels} } ? "# $a  $t" : cm($t); next }
            my @b = unpack '(H32)*', substr $bin, $foff + $l->{off}, $l->{end} - $l->{off};
            push @r, row(uc shift @b, "$a  $t"), map { uc } @b;
            next;
        }
        if (!defined $l->{off}) {
            push @r, $defs ne '' ? row($defs, $t) : $t eq '' ? '' : cm($t);
            next;
        }
        my ($f, $note) = fields($l);
        if (@$f || $note ne '') {
            push @r, row(join(' ', grep { $_ ne '' } $defs, hexline($foff, $l->{off}, $l->{end}, @$f)), $t . $note);
        } else {
            my @b = unpack '(H32)*', substr $bin, $foff + $l->{off}, $l->{end} - $l->{off};
            push @r, row(join(' ', grep { $_ ne '' } $defs, uc shift @b), $t), map { uc } @b;
        }
    }
    return @r;
}

if ($mode eq 'hex0') {
    push @out, "# $src as hex0 text, made by gen/mkhex.pl: each line the bytes of",
        "# one asm line, then its file offset and the line. hex0 reads only the",
        "# hex digits before each '#'.", '#';
    push @out, section_rows('.text');
    print "$_\n" for @out;
    exit 0;
}


# m1: an instruction's bytes split as x86_64 encodes them: the prefixes,
# REX, the opcode, ModRM and SIB (the DEFINE's value), then the
# displacement, then the immediate or a jump's rel (the fields).
my %nomodrm = map { $_ => 1 } (0x50 .. 0x5f, 0x70 .. 0x7f, 0x90 .. 0x99, 0xa4 .. 0xa9, 0xb0 .. 0xbf,
    0xc3, 0xc9, 0xe8, 0xe9, 0xeb, 0xf8, 0xf9, 0xfc, map { ($_ * 8 + 4, $_ * 8 + 5) } 0 .. 7);
sub decode {
    my ($b) = @_;
    my @b = map { ord } split //, $b;
    my ($i, @why) = (0);
    while ($i < @b && $b[$i] =~ /^(102|242|243)$/) { push @why, sprintf('%02X %s', $b[$i], { 102 => 'operand size', 242 => 'repne', 243 => 'rep' }->{ $b[$i] }); $i++ }
    if ($i < @b && $b[$i] >= 0x40 && $b[$i] <= 0x4f) {
        my $r = $b[$i++];
        push @why, 'REX' . join('', map { $r & $_->[0] ? ".$_->[1]" : '' } [8, 'W'], [4, 'R'], [2, 'X'], [1, 'B']);
    }
    my ($op, $two) = ($b[$i], 0);
    if ($op == 0x0f) { $two = 1; $op = $b[$i + 1]; $i += 2; push @why, sprintf '0F %02X', $op }
    else { $i++; push @why, sprintf '%02X', $op }
    my ($disp, $rel, $rip) = (0, 0, 0);
    my $modrm = $two ? !($op == 0x05 || ($op >= 0x80 && $op <= 0x8f)) : !$nomodrm{$op};
    $rel = 1 if !$two && ($op >= 0x70 && $op <= 0x7f || $op == 0xe8 || $op == 0xe9 || $op == 0xeb);
    $rel = 1 if $two && $op >= 0x80 && $op <= 0x8f;
    if ($modrm) {
        my $m = $b[$i++];
        my ($mod, $reg, $rm) = ($m >> 6, ($m >> 3) & 7, $m & 7);
        push @why, sprintf 'ModRM %02b %03b %03b', $mod, $reg, $rm;
        if ($mod != 3 && $rm == 4) {
            my $s = $b[$i++];
            push @why, sprintf 'SIB %02b %03b %03b', $s >> 6, ($s >> 3) & 7, $s & 7;
            $disp = 4 if $mod == 0 && ($s & 7) == 5;
        }
        $disp = 1 if $mod == 1;
        $disp = 4 if $mod == 2;
        ($disp, $rip) = (4, 1) if $mod == 0 && $rm == 5;
    }
    return ($i, $disp, @b - $i - $disp, $rel, $rip, join(', ', @why));
}

sub m1num {
    my ($v, $n) = @_;
    my $sign = { 1 => '!', 2 => '@', 4 => '%' }->{$n} // die "mkhex: a field of $n bytes\n";
    return $sign . ($v < 0 ? ($v > -4096 ? $v : sprintf '-0x%x', -$v) : $v < 4096 ? $v : sprintf '0x%x', $v);
}

if ($mode eq 'm1') {
    my (%def, @rows);
    my ($addr, $foff) = (0, 0);
    for my $l (@{ $bysec{'.text'} }) {
        my $t = $l->{text};
        die "mkhex: line $l->{n}: a local label\n" if grep { defined $_->{num} } @{ $l->{labels} };
        my $defs = join ' ', map { ":$_->{name}" } @{ $l->{labels} };
        if (!defined $l->{off}) {
            push @rows, $defs ne '' ? row($defs, $t) : $t eq '' ? '' : cm($t);
            next;
        }
        my $b = substr $bin, $l->{off}, $l->{end} - $l->{off};
        if ($l->{mn} =~ /^\./) {
            my $str = $l->{mn} eq '.asciz' && $l->{ops} =~ /^"([^"\\]*)"$/ ? $1 : undef;
            if (defined $str && "$str\0" eq $b && $str !~ /[\s'"]/) { push @rows, row(join(' ', grep { $_ ne '' } $defs, "\"$str\""), $t); next }
            my @h = unpack '(H32)*', $b;
            push @rows, row(join(' ', grep { $_ ne '' } $defs, uc shift @h), $t), map { uc } @h;
            next;
        }
        my ($n, $d, $k, $rel, $rip, $why) = decode($b);
        my @ops = split /,\s*(?![^()]*\))/, $l->{ops};
        my $name = $l->{mn};
        my @tok;
        if ($rel) {
            my $tgt = $l->{end} + sx(rd($l->{end} - $k, $k), $k);
            my $lab = name_at($tgt, $l->{ops}) // die "mkhex: line $l->{n}: no label at the target of $t\n";
            $name .= $k == 1 ? '8' : '32' unless $name eq 'call';
            @tok = (($k == 1 ? '!' : '%') . $lab);
            @ops = ();
            $why .= ", then rel$k: " . ($k == 1 ? '!' : '%') . 'label';
        } else {
            if ($d) {
                if ($rip) {
                    die "mkhex: line $l->{n}: (%rip) with an immediate after it\n" if $k;
                    my $tgt = $l->{end} + sx(rd($l->{off} + $n, 4), 4);
                    my $lab = name_at($tgt, $l->{ops}) // die "mkhex: line $l->{n}: no label at the (%rip) of $t\n";
                    push @tok, "%$lab";
                    $why .= ', then rel32 from the end: %label';
                } else {
                    push @tok, m1num(sx(rd($l->{off} + $n, $d), $d), $d);
                    $why .= ", then disp" . 8 * $d;
                }
            }
            if ($k) {
                if ($k == 8) { push @tok, m1num(sx(rd($l->{off} + $n + $d, 4), 4), 4), m1num(sx(rd($l->{off} + $n + $d + 4, 4), 4), 4) }
                else { push @tok, m1num(sx(rd($l->{off} + $n + $d, $k), $k), $k) }
                $why .= ", then imm" . 8 * $k;
            }
        }
        for (@ops) {
            if (/^\*?%(\w+)$/) { s/%//; next }
            next if /^[a-z]+$/ && $l->{mn} =~ /^rep/;    # rep movsb, repe cmpsb
            if (/^\$(.*)$/) { $_ = $k ? '$i' . 8 * $k : "\$$1"; next }
            if (/^\*?(.*?)\((.*)\)$/) {
                my ($x, $r) = ($1, $2);
                $r =~ s/%//g;
                $r =~ s/\s+//g;
                my $star = /^\*/ ? '*' : '';
                $_ = $star . ($rip ? 'rel' : $d ? 'd' . 8 * $d : '') . "($r)";
                next;
            }
            die "mkhex: line $l->{n}: operand $_ of $t\n";
        }
        $name .= '_' . join(',', @ops) if @ops;
        $name =~ s/\s+/_/g;
        my $v = uc unpack 'H*', substr $b, 0, $n;
        die "mkhex: $name is $def{$name}[0] and $v\n" if $def{$name} && $def{$name}[0] ne $v;
        $def{$name} //= [$v, $why];
        push @rows, row(join(' ', grep { $_ ne '' } $defs, $name, @tok), $t);
    }
    push @out, "# $src as M1 text, made by gen/mkhex.pl. First a DEFINE for each",
        "# instruction form it uses: its name is the instruction (the registers",
        "# without %), its fields named by their size: \$i8 \$i32 an immediate, d8",
        "# d32 a displacement, rel(rip) a displacement to a label, and jcc8 jcc32",
        "# a jump with its rel8 or rel32; its value is the bytes before the",
        "# fields, with what they are as a comment (the Intel manual's names).",
        "# Then each asm line: :label for its labels, the DEFINE's name, then its",
        "# fields in their order: !n \@n %n a number of 1, 2 or 4 bytes, %label a",
        "# rel32 to label from the end of the field, !label a rel8. Data is hex",
        "# or a \"string\" (its bytes, then 00). M1 reads only what is before",
        "# each '#'; M1's hex2 text is made by hex2.", '#';
    push @out, map { row("DEFINE $_ $def{$_}[0]", $def{$_}[1]) } sort keys %def;
    push @out, '#', @rows;
    print "$_\n" for @out;
    exit 0;
}

if ($mode eq 'flat') {
    push @out, "# $src as hex2 text, made by gen/mkhex.pl: each line the bytes of",
        "# one asm line, then the line. :label defines a label at the address",
        "# of the next byte (from 0, the file's first byte); %label is the 4",
        "# bytes of label minus the address after them (rel32), !label the same",
        "# in 1 byte (rel8). hex2 reads only what is before each '#'.", '#';
    push @out, section_rows('.text');
    print "$_\n" for @out;
    exit 0;
}

# hex2: the ELF header and program headers, field by field
my @ehdr = (
    [16, 'e_ident', 'the magic 7f "ELF", ELFCLASS64, little endian, EV_CURRENT, System V, padding'],
    [2, 'e_type', 'ET_EXEC, an executable'], [2, 'e_machine', 'EM_X86_64'], [4, 'e_version', 'EV_CURRENT'],
    [8, 'e_entry', 'the address of _start'], [8, 'e_phoff', 'the program headers follow'],
    [8, 'e_shoff', 'the section headers, at the end'], [4, 'e_flags', 'none on x86_64'],
    [2, 'e_ehsize', 'this header'], [2, 'e_phentsize', 'a program header'],
    [2, 'e_phnum', 'program headers'], [2, 'e_shentsize', 'a section header'],
    [2, 'e_shnum', 'section headers'], [2, 'e_shstrndx', 'the section of the section names']);
my @phdr = (
    [4, 'p_type', '1: PT_LOAD'], [4, 'p_flags', '4 R, 2 W, 1 X'], [8, 'p_offset', 'from this file offset'],
    [8, 'p_vaddr', 'to this address'], [8, 'p_paddr', 'the same'], [8, 'p_filesz', 'bytes of the file'],
    [8, 'p_memsz', 'bytes of memory, the rest zero'], [8, 'p_align', 'a page']);
my @shdr = (
    [4, 'sh_name', 'its name at this offset of .shstrtab'], [4, 'sh_type', '1 PROGBITS, 3 STRTAB, 8 NOBITS'],
    [8, 'sh_flags', '1 W, 2 A, 4 X'], [8, 'sh_addr', 'its address'], [8, 'sh_offset', 'its file offset'],
    [8, 'sh_size', 'its size'], [4, 'sh_link', ''], [4, 'sh_info', ''], [8, 'sh_addralign', ''],
    [8, 'sh_entsize', '']);
sub fieldrows {
    my ($o, $fs) = @_;
    my @r;
    for (@$fs) {
        my ($n, $name, $why) = @$_;
        my $v = $n <= 8 ? rd($o, $n) : undef;
        my $c = $name . (defined $v ? sprintf(' = 0x%x', $v) : '') . ($why ne '' ? ": $why" : '');
        push @r, row(uc unpack('H*', substr $bin, $o, $n), $c);
        $o += $n;
    }
    return @r;
}

my $phoff = rd(32, 8);
my $phnum = rd(56, 2);
my $shoff = rd(40, 8);
my $shnum = rd(60, 2);
my $shstr = $sec{'.shstrtab'} or die "mkhex: no .shstrtab\n";
my ($delta) = rd($phoff + 16, 8) - rd($phoff + 8, 8);
push @out, "# $src as hex2 text, made by gen/mkhex.pl from GNU as's and ld's output:",
    "# the whole executable in the order of its bytes. :label defines a label",
    "# at the address of the next byte; %label is the 4 bytes of label minus",
    "# the address after them (rel32), !label the same in 1 byte (rel8),",
    "# &label label's address in 4 bytes (abs32, the low half of a .quad);",
    "# ^address sets the address of the next byte (where the file and the",
    "# addresses part: the data segment, the labels of the bss). Every other",
    "# pair of hex digits is a byte; '#' and ';' start a comment to the end of",
    "# the line. A reference that is not to a label alone (label+8, or with",
    "# an immediate after it) is written out. Each line is followed by the asm",
    "# line of $src it comes from; hex2 reads only what is before the '#'.",
    '#', row(sprintf('^%08X', $delta), 'the first byte of the file is at this address'),
    '#', '# The ELF header';
push @out, fieldrows(0, \@ehdr);
for my $i (0 .. $phnum - 1) {
    push @out, '#', "# Program header $i";
    push @out, fieldrows($phoff + 56 * $i, \@phdr);
}
my $pos = $phoff + 56 * $phnum;
for my $s (grep { !$sec{$_}[3] && $_ ne '.shstrtab' } @order) {
    my ($addr, $foff, $size) = @{ $sec{$s} };
    die "mkhex: $s before the file position\n" if $foff < $pos;
    if ($foff > $pos) {
        push @out, row(uc unpack('H*', substr $bin, $pos, $foff - $pos), "padding to ${s}'s file offset");
    }
    if ($addr - $foff != $delta) {
        $delta = $addr - $foff;
        push @out, row(sprintf('^%08X', $addr), "$s is at this address (another segment)");
    }
    push @out, '#', "# The section $s, from here its lines of $src";
    push @out, section_rows($s);
    $pos = $foff + $size;
}
for my $s (grep { $sec{$_}[3] } @order) {
    push @out, '#', "# The section $s: no bytes in the file, only its labels";
    push @out, section_rows($s);
}
my ($sa, $so, $ss) = @{$shstr};
die "mkhex: .shstrtab not after the sections\n" if $so < $pos;
push @out, row(uc unpack('H*', substr $bin, $pos, $so - $pos), 'padding') if $so > $pos;
push @out, '#', '# The section .shstrtab: the names of the sections';
my $p = $so;
while ($p < $so + $ss) {
    my $z = index($bin, "\0", $p);
    $z = $so + $ss - 1 if $z < 0 || $z >= $so + $ss;
    my $str = substr $bin, $p, $z - $p;
    push @out, row(uc unpack('H*', substr $bin, $p, $z - $p + 1), $str eq '' ? '""' : "\"$str\"");
    $p = $z + 1;
}
$pos = $so + $ss;
push @out, row(uc unpack('H*', substr $bin, $pos, $shoff - $pos), 'padding to the section headers') if $shoff > $pos;
for my $i (0 .. $shnum - 1) {
    my $o = $shoff + 64 * $i;
    my $nm = rd($o, 4);
    my $z = index($bin, "\0", $so + $nm);
    push @out, '#', sprintf('# Section header %d%s', $i, $i ? ': ' . substr($bin, $so + $nm, $z - $so - $nm) : '');
    push @out, fieldrows($o, \@shdr);
}
die "mkhex: bytes after the section headers\n" if $shoff + 64 * $shnum != length $bin;
print "$_\n" for @out;
