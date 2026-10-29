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
$ENV{NIX_HARDENING_ENABLE} = '';    # the Nix ld-wrapper's -z relro / -z now

die "usage: mkhex.pl hex0|hex2|flat|m1 <prog.s>\n" unless @ARGV == 2 && $ARGV[0] =~ /^(hex[02]|flat|m1)$/;
my ($mode, $src) = @ARGV;
my $t = tempdir(CLEANUP => 1);
sub run { system(@_) == 0 or die "mkhex: @_ failed\n" }
sub out { my $c = shift; my $o = `$c`; die "mkhex: $c failed\n" if $?; $o }
sub slurp { open my $f, '<:raw', $_[0] or die "mkhex: $_[0]: $!\n"; local $/; <$f> }

# the host: the folder of <prog.s>, gen/hex/<host>/ or hosts/<host>/
my $arch = $src =~ m{(?:^|/)(x86_64|riscv64|aarch64|arm)/[^/]*$} ? $1 : die "mkhex: $src is not in a folder x86_64/, riscv64/, aarch64/ or arm/\n";
my $rv = $arch eq 'riscv64';
my $a64 = $arch eq 'aarch64';
my $arm = $arch eq 'arm';
my $fixed = $rv || $a64 || $arm;    # 4-byte instructions, read from their bits
my $W = $arm ? 4 : 8;               # ELF32 or ELF64: a word of the headers
# x86_64: as the Makefile's SEED=gnu and make hex; riscv64 the same: the
# seed as -march=rv64imac (ttpc.s's ASFLAGS) without the arch attribute,
# ld without relaxing, symbols or a page of its own for the code; the
# programs (hex0 ...) RV64IM, linked at 0 (gas leaves relocations even for
# a branch in its own section).
# aarch64: as without flags; the seed ld -Ttext=0x4000b0 (the Makefile's
# SLDFLAGS_aarch64), the programs linked at 0.
# arm: as -march=armv7-a; the seed ld -T hosts/arm/ttpc.ld (SLDFLAGS_arm),
# the programs linked at 0.
my $X = $rv ? 'riscv64-none-elf-' : $a64 ? 'aarch64-none-elf-' : $arm ? 'arm-none-eabi-' : '';
(my $script = $src) =~ s{[^/]*$}{ttpc.ld};
my @as = $a64 ? () : $arm ? ('-march=armv7-a') : $rv ? ('-march=' . ($mode eq 'hex2' ? 'rv64imac' : 'rv64im'), '-mabi=lp64', '-mno-arch-attr', $mode eq 'hex2' ? () : '-mno-relax')
    : ('-mx86-used-note=no');
my @ld = $arm ? ('-static', $mode eq 'hex2' ? ('-T', $script) : ())
    : ('-static', ($rv ? '--no-relax' : ()), '-z', 'noseparate-code', ($a64 && $mode eq 'hex2' ? '-Ttext=0x4000b0' : ()));
# riscv64's gas cannot list ttpc.s (a listing makes `li a2, msg_len` of an
# .equ of `. - msg` an error): the lines' offsets come from a copy with a
# label before and after each line, assembled apart
if ($fixed) { run("${X}as", @as, $src, '-o', "$t/o") }
else { run("${X}as", @as, "-aln=$t/l", '--listing-cont-lines=1000000', $src, '-o', "$t/o") }
my $bin;
if ($mode ne 'hex2') {
    my $o = "$t/o";
    if ($fixed) { run("${X}ld", @ld, '-Ttext=0', '-e', '0', "$t/o", '-o', "$t/e"); $o = "$t/e" }
    run("${X}objcopy", '-O', 'binary', '-j', '.text', $o, "$t/bin");
} else {
    run("${X}ld", @ld, '-e', '_start', "$t/o", '-o', "$t/u");
    run("${X}ld", @ld, '-s', '-e', '_start', "$t/o", '-o', "$t/bin");
}
$bin = slurp("$t/bin");

# the sections: name -> [addr, file offset, size, nobits]
my (%sec, @order);
if ($mode ne 'hex2') {
    %sec = ('.text' => [0, 0, length $bin, 0]);
    @order = ('.text');
} else {
    for (split /\n/, out("${X}readelf -SW $t/bin")) {
        next unless /^\s*\[\s*\d+\]\s+(\.\S+)\s+(\S+)\s+([0-9a-f]+)\s+([0-9a-f]+)\s+([0-9a-f]+)/;
        $sec{$1} = [hex $3, hex $4, hex $5, $2 eq 'NOBITS'];
        push @order, $1;
    }
}

# the listing: the first offset of every line that emits
my %off;
if (!$fixed) {
    for (split /\n/, slurp("$t/l")) {
        $off{$1} //= hex $2 if /^\s*(\d+) ([0-9a-f]{4,}) [0-9A-F]/;
    }
} else {
    my @s = split /\n/, slurp($src), -1;
    pop @s if @s && $s[-1] eq '';
    open my $m, '>', "$t/m.s" or die "mkhex: $t/m.s: $!\n";
    my $inmacro = 0;    # not in a .macro's body: its expansions would define them twice
    for (1 .. @s) {
        $inmacro = 1 if $s[$_ - 1] =~ /^\s*\.macro\b/;
        print $m $inmacro ? "$s[$_ - 1]\n" : "__mkhex_a$_:\n$s[$_ - 1]\n__mkhex_z$_:\n";
        $inmacro = 0 if $s[$_ - 1] =~ /^\s*\.endm\b/;
    }
    close $m;
    run("${X}as", @as, "$t/m.s", '-o', "$t/m.o");
    for my $j ('.text', '.rodata', '.data') {
        run("${X}objcopy", '-O', 'binary', '-j', $j, "$t/$_", "$t/$_$j") for 'o', 'm.o';
        die "mkhex: the labels of each line change $j\n" if slurp("$t/o$j") ne slurp("$t/m.o$j");
    }
    my (%ndx, %v);
    for (split /\n/, out("${X}readelf -sW $t/m.o")) {
        my @f = split;
        $v{ $f[7] } = [hex $f[1], $f[6]] if @f >= 8 && $f[7] =~ /^__mkhex_[az]\d+$/;
    }
    for my $n (1 .. @s) {
        my ($a, $z) = ($v{"__mkhex_a$n"}, $v{"__mkhex_z$n"});
        next unless $a && $z;    # a .macro's body
        $off{$n} = $a->[0] if $a->[1] eq $z->[1] && $z->[0] > $a->[0];
    }
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
    if ($a64) { $code =~ s{//.*}{} }
    elsif ($arm) { $code =~ s/^((?:[^"@]|"(?:[^"\\]|\\.)*")*)@.*/$1/ }
    else {
        $code =~ s/\s#.*//;
        $code =~ s/^#.*//;
    }
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
    for (split /\n/, out("${X}readelf -sW $t/u")) {
        my @f = split;
        next unless @f >= 8 && $f[0] =~ /^\d+:$/ && $f[6] ne 'ABS' && $f[6] ne 'UND';
        $sym{ $f[7] } = hex $f[1];
    }
    my $rs;
    for (split /\n/, out("${X}readelf -rW $t/o")) {
        $rs = $1 if /'\.rela?(\.\w+)'/;
        # arm: REL, the addend in the bytes; only the .words (the code's
        # references are read from its instructions, fields_arm)
        if ($arm && /^([0-9a-f]+)\s+[0-9a-f]+\s+(R_\w+)/) {
            $reloc{$rs}{ hex $1 } = [$2] if $2 eq 'R_ARM_ABS32';
            next;
        }
        next unless /^([0-9a-f]+)\s+[0-9a-f]+\s+(R_\w+)\s+[0-9a-f]+\s+(\S+)\s*([+-])\s*([0-9a-f]+)/;
        # riscv64: only the .dwords; the code's references are read from
        # its instructions (fields_rv)
        next if $rv && $2 ne 'R_RISCV_64';
        next if $a64 && $2 ne 'R_AARCH64_ABS64';
        my ($o, $type, $s, $sign, $a) = (hex $1, $2, $3, $4, hex $5);
        my $S = $sec{$s} ? $sec{$s}[0] : $sym{$s} // die "mkhex: no symbol $s\n";
        $reloc{$rs}{$o} = [$type, $S + ($sign eq '-' ? -$a : $a)];
    }
}

sub le { my ($v, $n) = @_; join '', map { sprintf '%02X', ($v >> 8 * $_) & 255 } 0 .. $n - 1 }
sub sx { my ($v, $n) = @_; my $m = 1 << 8 * $n; $v &= $m - 1; $v >= $m / 2 ? $v - $m : $v }
sub rd { my ($o, $n) = @_; my $v = 0; $v |= ord(substr $bin, $o + $_, 1) << 8 * $_ for 0 .. $n - 1; $v }

# riscv64: the immediates of the formats, sign-extended, and their bits
sub sxb { my ($v, $n) = @_; $v &= (1 << $n) - 1; $v >= 1 << ($n - 1) ? $v - (1 << $n) : $v }
sub bimm { my $w = shift; sxb((($w >> 31) & 1) << 12 | (($w >> 7) & 1) << 11 | (($w >> 25) & 0x3f) << 5 | (($w >> 8) & 0xf) << 1, 13) }
sub jimm { my $w = shift; sxb((($w >> 31) & 1) << 20 | (($w >> 12) & 0xff) << 12 | (($w >> 20) & 1) << 11 | (($w >> 21) & 0x3ff) << 1, 21) }
sub uimm { sxb($_[0] & 0xfffff000, 32) }
sub iimm { sxb($_[0] >> 20, 12) }
sub cbimm { my $h = shift; sxb((($h >> 12) & 1) << 8 | (($h >> 10) & 3) << 3 | (($h >> 5) & 3) << 6 | (($h >> 3) & 3) << 1 | (($h >> 2) & 1) << 5, 9) }
sub cjimm { my $h = shift; sxb((($h >> 12) & 1) << 11 | (($h >> 11) & 1) << 4 | (($h >> 9) & 3) << 8 | (($h >> 8) & 1) << 10 | (($h >> 7) & 1) << 6 | (($h >> 6) & 1) << 7 | (($h >> 3) & 7) << 1 | (($h >> 2) & 1) << 5, 12) }

# riscv64: a line's pc-relative instructions as tokens, [start, length,
# token, the bytes with the field zero]: jal $, branches @, c.j *, c.beqz
# and c.bnez |, an auipc ~ and the addi, load or jalr after it !
sub fields_rv {
    my ($l) = @_;
    my ($addr, $foff) = @{ $sec{ $l->{sec} } };
    my ($o, $e) = ($l->{off}, $l->{end});
    my (@f, @raw);
    my $tok = sub {
        my ($p, $n, $sign, $tgt, $w, $mask) = @_;
        my $name = name_at($tgt, $l->{ops});
        if (!$name) { push @raw, sprintf '%s to 0x%x', $sign, $tgt; return 0 }
        push @f, [$p, $n, "$sign$name", &le($w & ~$mask, $n)];
        return 1;
    };
    for (my $p = $o; $p < $e;) {
        my $P = $addr + $p;
        if ((ord(substr $bin, $foff + $p, 1) & 3) != 3) {
            my $h = rd($foff + $p, 2);
            my ($q, $f3) = ($h & 3, $h >> 13);
            $tok->($p, 2, '*', $P + cjimm($h), $h, 0x1ffc) if $q == 1 && $f3 == 5;
            $tok->($p, 2, '|', $P + cbimm($h), $h, 0x1c7c) if $q == 1 && $f3 >= 6;
            $p += 2;
            next;
        }
        my $w = rd($foff + $p, 4);
        my $op = $w & 0x7f;
        if ($op == 0x6f) { $tok->($p, 4, '$', $P + jimm($w), $w, 0xfffff000) }
        elsif ($op == 0x63) { $tok->($p, 4, '@', $P + bimm($w), $w, 0xfe000f80) }
        elsif ($op == 0x17) {
            my $w2 = $p + 8 <= $e ? rd($foff + $p + 4, 4) : 0;
            my $op2 = $w2 & 0x7f;
            die "mkhex: line $l->{n}: an auipc without its addi, load or jalr after it\n"
                unless ($op2 == 0x13 || $op2 == 0x03 || $op2 == 0x67) && (($w2 >> 15) & 31) == (($w >> 7) & 31);
            my $tgt = $P + uimm($w) + iimm($w2);
            my $name = name_at($tgt, $l->{ops});
            if ($name) { push @f, [$p, 4, "~$name", &le($w & 0xfff, 4)], [$p + 4, 4, "!$name", &le($w2 & 0xfffff, 4)] }
            else { push @raw, sprintf 'auipc pair to 0x%x', $tgt }
            $p += 8;
            next;
        }
        $p += 4;
    }
    return (\@f, @raw ? ' (written out: ' . join(', ', @raw) . ')' : '');
}

# riscv64: an instruction's fields as the RISC-V manual draws them, for
# the hand check of hex0's text: its 32 bits cut at the fields, MSB first,
# then what they say
my @abi = qw(zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6);
sub rvwhy {
    my ($b) = @_;
    my @r;
    for (my $p = 0; $p < length $b;) {
        my $w = 0;
        $w |= ord(substr $b, $p + $_, 1) << 8 * $_ for 0 .. 3;
        if (($w & 3) != 3) { push @r, sprintf 'compressed %016b', $w & 0xffff; $p += 2; next }
        $w &= 0xffffffff;
        my ($op, $rd, $f3, $rs1, $rs2) = ($w & 0x7f, ($w >> 7) & 31, ($w >> 12) & 7, ($w >> 15) & 31, ($w >> 20) & 31);
        my $x = sub { "x$_[0] $abi[$_[0]]" };
        my ($k, $cut, $what);
        if ($op == 0x33) { ($k, $cut, $what) = ('R', [7, 5, 5, 3, 5, 7], sprintf 'rs2 %s, rs1 %s, rd %s', $x->($rs2), $x->($rs1), $x->($rd)) }
        elsif ($op == 0x13 || $op == 0x03 || $op == 0x67 || $op == 0x73 || $op == 0x1b) { ($k, $cut, $what) = ('I', [12, 5, 3, 5, 7], sprintf 'imm %d, rs1 %s, rd %s', iimm($w), $x->($rs1), $x->($rd)) }
        elsif ($op == 0x23) { ($k, $cut, $what) = ('S', [7, 5, 5, 3, 5, 7], sprintf 'imm %d, rs2 %s, rs1 %s', sxb(($w >> 25) << 5 | $rd, 12), $x->($rs2), $x->($rs1)) }
        elsif ($op == 0x63) { ($k, $cut, $what) = ('B', [7, 5, 5, 3, 5, 7], sprintf 'imm %d, rs2 %s, rs1 %s', bimm($w), $x->($rs2), $x->($rs1)) }
        elsif ($op == 0x37 || $op == 0x17) { ($k, $cut, $what) = ('U', [20, 5, 7], sprintf 'imm 0x%x, rd %s', $w >> 12, $x->($rd)) }
        elsif ($op == 0x6f) { ($k, $cut, $what) = ('J', [20, 5, 7], sprintf 'imm %d, rd %s', jimm($w), $x->($rd)) }
        else { die sprintf "mkhex: opcode %07b\n", $op }
        my $bits = sprintf '%032b', $w;
        my @g;
        for (@$cut) { push @g, substr $bits, 0, $_, '' }
        push @r, "$k " . join(' ', @g) . ": $what";
        $p += 4;
    }
    return join '; ', @r;
}

# aarch64: a line's pc-relative instructions as tokens, [start, length,
# token, the bytes after it]: B and BL ^~ (3 bytes, then the top byte),
# B.cond, CBZ, CBNZ @, an ADRP ~ and the ADD :lo12: after it ! (each
# written with its field zero)
sub fields_a64 {
    my ($l) = @_;
    my ($addr, $foff) = @{ $sec{ $l->{sec} } };
    my ($o, $e) = ($l->{off}, $l->{end});
    my (@f, @raw);
    for (my $p = $o; $p < $e; $p += 4) {
        my $P = $addr + $p;
        my $w = rd($foff + $p, 4);
        if (($w & 0x7c000000) == 0x14000000) {
            my $tgt = $P + 4 * sxb($w & 0x3ffffff, 26);
            my $name = name_at($tgt, $l->{ops});
            if ($name) { push @f, [$p, 4, "^~$name", sprintf '%02X', $w >> 24] }
            else { push @raw, sprintf 'b to 0x%x', $tgt }
        } elsif (($w & 0xff000010) == 0x54000000 || ($w & 0x7e000000) == 0x34000000) {
            my $tgt = $P + 4 * sxb(($w >> 5) & 0x7ffff, 19);
            my $name = name_at($tgt, $l->{ops});
            if ($name) { push @f, [$p, 4, "\@$name", &le($w & ~0x00ffffe0, 4)] }
            else { push @raw, sprintf 'imm19 to 0x%x', $tgt }
        } elsif (($w & 0x9f000000) == 0x90000000) {
            my $w2 = $p + 8 <= $e ? rd($foff + $p + 4, 4) : 0;
            die "mkhex: line $l->{n}: an adrp without its add after it\n"
                unless ($w2 & 0xffc00000) == 0x91000000 && (($w2 >> 5) & 31) == ($w & 31);
            my $page = ($P & ~0xfff) + 4096 * sxb(((($w >> 5) & 0x7ffff) << 2) | (($w >> 29) & 3), 21);
            my $tgt = $page + (($w2 >> 10) & 0xfff);
            my $name = name_at($tgt, $l->{ops});
            if ($name) { push @f, [$p, 4, "~$name", &le($w & ~0x60ffffe0, 4)], [$p + 4, 4, "!$name", &le($w2 & ~0x003ffc00, 4)] }
            else { push @raw, sprintf 'adrp pair to 0x%x', $tgt }
            $p += 4;
        } elsif (($w & 0x7e000000) == 0x36000000 || ($w & 0x9f000000) == 0x10000000 || ($w & 0x3b000000) == 0x18000000) {
            die sprintf "mkhex: line %d: tbz, tbnz, adr or ldr literal (no hex2 reference for it): %s\n", $l->{n}, $l->{text};
        }
    }
    return (\@f, @raw ? ' (written out: ' . join(', ', @raw) . ')' : '');
}

# aarch64: an instruction's fields as the Arm manual draws its encoding,
# for the hand check of hex0's text: its 32 bits cut at the fields, MSB
# first, then what they say
my @cond = qw(eq ne hs lo mi pl vs vc hi ls ge lt gt le al nv);
sub a64why {
    my ($b) = @_;
    my @r;
    for (my $p = 0; $p + 4 <= length $b; $p += 4) {
        my $w = 0;
        $w |= ord(substr $b, $p + $_, 1) << 8 * $_ for 0 .. 3;
        my $f = sub { ($w >> $_[0]) & ((1 << $_[1]) - 1) };
        my ($sf, $rd, $rn, $rm) = ($w >> 31, $w & 31, ($w >> 5) & 31, ($w >> 16) & 31);
        my $X = $sf ? 'x' : 'w';
        my $x = sub { my ($n, $sp) = @_; $n == 31 ? ($sp ? 'sp' : "${X}zr") : "$X$n" };
        my ($k, $cut, $what);
        if (($w & 0x1f800000) == 0x12800000) {
            my $opc = $f->(29, 2);
            $k = ('MOVN', '?', 'MOVZ', 'MOVK')[$opc];
            ($cut, $what) = ([1, 2, 6, 2, 16, 5], sprintf 'sf %d, opc %02b %s, hw %d (lsl %d), imm16 %d, Rd %s', $sf, $opc, lc $k, $f->(21, 2), 16 * $f->(21, 2), $f->(5, 16), $x->($rd));
        } elsif (($w & 0x1f800000) == 0x11000000) {
            my ($op, $S) = ($f->(30, 1), $f->(29, 1));
            $k = ($op ? 'SUB' : 'ADD') . ($S ? 'S' : '') . ' (immediate)';
            ($cut, $what) = ([1, 1, 1, 6, 1, 12, 5, 5], sprintf 'sf %d, op %d %s, S %d, sh %d, imm12 %d, Rn %s, Rd %s', $sf, $op, $op ? 'sub' : 'add', $S, $f->(22, 1), $f->(10, 12), $x->($rn, 1), $x->($rd, !$S));
        } elsif (($w & 0x1f200000) == 0x0b000000) {
            my ($op, $S) = ($f->(30, 1), $f->(29, 1));
            $k = ($op ? 'SUB' : 'ADD') . ($S ? 'S' : '') . ' (shifted register)';
            ($cut, $what) = ([1, 1, 1, 5, 2, 1, 5, 6, 5, 5], sprintf 'sf %d, op %d, S %d, shift %s, Rm %s, imm6 %d, Rn %s, Rd %s', $sf, $op, $S, (qw(lsl lsr asr ror))[$f->(22, 2)], $x->($rm), $f->(10, 6), $x->($rn), $x->($rd));
        } elsif (($w & 0x1f000000) == 0x0a000000) {
            my $opc = $f->(29, 2);
            $k = (qw(AND ORR EOR ANDS))[$opc] . ($f->(21, 1) ? 'N' : '') . ' (shifted register)';
            ($cut, $what) = ([1, 2, 5, 2, 1, 5, 6, 5, 5], sprintf 'sf %d, opc %02b, shift %s, N %d, Rm %s, imm6 %d, Rn %s, Rd %s', $sf, $opc, (qw(lsl lsr asr ror))[$f->(22, 2)], $f->(21, 1), $x->($rm), $f->(10, 6), $x->($rn), $x->($rd));
        } elsif (($w & 0x1f800000) == 0x13000000) {
            my $opc = $f->(29, 2);
            $k = (qw(SBFM BFM UBFM ?))[$opc];
            ($cut, $what) = ([1, 2, 6, 1, 6, 6, 5, 5], sprintf 'sf %d, opc %02b, N %d, immr %d, imms %d, Rn %s, Rd %s', $sf, $opc, $f->(22, 1), $f->(16, 6), $f->(10, 6), $x->($rn), $x->($rd));
        } elsif (($w & 0x5fe00000) == 0x1ac00000) {
            my $o = $f->(10, 6);
            $k = { 2 => 'UDIV', 3 => 'SDIV', 8 => 'LSLV', 9 => 'LSRV', 10 => 'ASRV', 11 => 'RORV' }->{$o} // '?';
            ($cut, $what) = ([1, 1, 1, 8, 5, 6, 5, 5], sprintf 'sf %d, S %d, Rm %s, opcode %06b, Rn %s, Rd %s', $sf, $f->(29, 1), $x->($rm), $o, $x->($rn), $x->($rd));
        } elsif (($w & 0x1f000000) == 0x1b000000) {
            $k = $f->(15, 1) ? 'MSUB' : 'MADD';
            ($cut, $what) = ([1, 2, 5, 3, 5, 1, 5, 5, 5], sprintf 'sf %d, op31 %03b, Rm %s, o0 %d, Ra %s, Rn %s, Rd %s', $sf, $f->(21, 3), $x->($rm), $f->(15, 1), $x->($f->(10, 5)), $x->($rn), $x->($rd));
        } elsif (($w & 0x3b000000) == 0x39000000) {
            my ($size, $opc) = ($f->(30, 2), $f->(22, 2));
            $k = ($opc ? 'LDR' : 'STR') . ('B', 'H', '', '')[$size] . ' (immediate, unsigned offset)';
            $X = $size == 3 ? 'x' : 'w';
            ($cut, $what) = ([2, 3, 1, 2, 2, 12, 5, 5], sprintf 'size %02b (%d bytes), V %d, opc %02b %s, imm12 %d (offset %d), Rn %s, Rt %s', $size, 1 << $size, $f->(26, 1), $opc, $opc ? 'load' : 'store', $f->(10, 12), $f->(10, 12) << $size, $x->($rn, 1) =~ s/^w/x/r, $x->($rd));
        } elsif (($w & 0x7c000000) == 0x14000000) {
            my $imm = sxb($w & 0x3ffffff, 26);
            $k = $w >> 31 ? 'BL' : 'B';
            ($cut, $what) = ([1, 5, 26], sprintf 'op %d %s, imm26 %d (offset %d)', $w >> 31, $w >> 31 ? 'with link' : 'without link', $imm, 4 * $imm);
        } elsif (($w & 0xff000010) == 0x54000000) {
            my $imm = sxb($f->(5, 19), 19);
            $k = 'B.cond';
            ($cut, $what) = ([7, 1, 19, 1, 4], sprintf 'imm19 %d (offset %d), cond %04b %s', $imm, 4 * $imm, $w & 15, $cond[$w & 15]);
        } elsif (($w & 0x7e000000) == 0x34000000) {
            my $imm = sxb($f->(5, 19), 19);
            $k = $f->(24, 1) ? 'CBNZ' : 'CBZ';
            ($cut, $what) = ([1, 6, 1, 19, 5], sprintf 'sf %d, op %d, imm19 %d (offset %d), Rt %s', $sf, $f->(24, 1), $imm, 4 * $imm, $x->($rd));
        } elsif (($w & 0x7e000000) == 0x36000000) {
            my $imm = sxb($f->(5, 14), 14);
            $k = $f->(24, 1) ? 'TBNZ' : 'TBZ';
            $X = $sf ? 'x' : 'w';
            ($cut, $what) = ([1, 6, 1, 5, 14, 5], sprintf 'b5 %d, op %d, b40 %d (bit %d), imm14 %d (offset %d), Rt %s', $sf, $f->(24, 1), $f->(19, 5), $sf * 32 + $f->(19, 5), $imm, 4 * $imm, $x->($rd));
        } elsif (($w & 0xfe000000) == 0xd6000000) {
            my $opc = $f->(21, 4);
            $k = { 0 => 'BR', 1 => 'BLR', 2 => 'RET' }->{$opc} // '?';
            $X = 'x';
            ($cut, $what) = ([7, 4, 5, 6, 5, 5], sprintf 'opc %04b, op2 %05b, op3 %06b, Rn %s, op4 %05b', $opc, $f->(16, 5), $f->(10, 6), $x->($rn), $rd);
        } elsif (($w & 0xffe0001f) == 0xd4000001) {
            $k = 'SVC';
            ($cut, $what) = ([8, 3, 16, 3, 2], sprintf 'imm16 %d', $f->(5, 16));
        } elsif (($w & 0x1f000000) == 0x10000000) {
            my $imm = sxb(($f->(5, 19) << 2) | $f->(29, 2), 21);
            $k = $w >> 31 ? 'ADRP' : 'ADR';
            $X = 'x';
            ($cut, $what) = ([1, 2, 5, 19, 5], sprintf 'op %d, immlo %02b, immhi %d, imm %d (offset %d), Rd %s', $w >> 31, $f->(29, 2), sxb($f->(5, 19), 19), $imm, $w >> 31 ? 4096 * $imm : $imm, $x->($rd));
        } else { die sprintf "mkhex: no encoding of %08x in a64why\n", $w }
        my $bits = sprintf '%032b', $w;
        my @g;
        for (@$cut) { push @g, substr $bits, 0, $_, '' }
        push @r, "$k " . join(' ', @g) . ": $what";
    }
    return @r;
}

# arm: a line's references as tokens, [start, length, token, the bytes
# after it]: B, BL, B<cond> ^~ (3 bytes, then the top byte: cond and the
# opcode), a MOVW :lower16: ! and the MOVT :upper16: after it ~ (each
# written with its immediate zero)
my @armcond = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le al nv);
sub fields_arm {
    my ($l) = @_;
    my ($addr, $foff) = @{ $sec{ $l->{sec} } };
    my ($o, $e) = ($l->{off}, $l->{end});
    my (@f, @raw);
    for (my $p = $o; $p < $e; $p += 4) {
        my $P = $addr + $p;
        my $w = rd($foff + $p, 4);
        if (($w & 0x0e000000) == 0x0a000000 && $w >> 28 != 15) {
            my $tgt = $P + 8 + 4 * sxb($w & 0xffffff, 24);
            my $name = name_at($tgt, $l->{ops});
            if ($name) { push @f, [$p, 4, "^~$name", sprintf '%02X', $w >> 24] }
            else { push @raw, sprintf 'b to 0x%x', $tgt }
        } elsif (($w & 0x0ff00000) == 0x03000000 && $l->{ops} =~ /:lower16:|^\s*\w+\s*,/ && ($l->{mn} eq 'la' || $l->{ops} =~ /:lower16:/)) {
            my $w2 = $p + 8 <= $e ? rd($foff + $p + 4, 4) : 0;
            die "mkhex: line $l->{n}: a movw :lower16: without its movt after it\n"
                unless ($w2 & 0x0ff00000) == 0x03400000 && (($w2 >> 12) & 15) == (($w >> 12) & 15);
            my $imm = sub { (($_[0] >> 4) & 0xf000) | ($_[0] & 0xfff) };
            my $tgt = $imm->($w2) << 16 | $imm->($w);
            my $name = name_at($tgt, $l->{ops});
            if ($name) { push @f, [$p, 4, "!$name", &le($w & ~0x000f0fff, 4)], [$p + 4, 4, "~$name", &le($w2 & ~0x000f0fff, 4)] }
            else { push @raw, sprintf 'movw, movt of 0x%x', $tgt }
            $p += 4;
        } elsif (($w & 0x0f7f0000) == 0x051f0000 || ($w & 0x0fef0000) == 0x028f0000 || ($w & 0x0fef0000) == 0x024f0000) {
            die sprintf "mkhex: line %d: ldr literal or adr (no hex2 reference for it): %s\n", $l->{n}, $l->{text};
        }
    }
    return (\@f, @raw ? ' (written out: ' . join(', ', @raw) . ')' : '');
}

# arm: an instruction's fields as the Arm manual draws its encoding (ARM
# state), for the hand check of hex0's text: its 32 bits cut at the
# fields, MSB first, then what they say
my @armdp = qw(AND EOR SUB RSB ADD ADC SBC RSC TST TEQ CMP CMN ORR MOV BIC MVN);
my @armreg = (map({ "r$_" } 0 .. 12), 'sp', 'lr', 'pc');
my @armsh = qw(lsl lsr asr ror);
sub armwhy {
    my ($b) = @_;
    my @r;
    for (my $p = 0; $p + 4 <= length $b; $p += 4) {
        my $w = 0;
        $w |= ord(substr $b, $p + $_, 1) << 8 * $_ for 0 .. 3;
        my $f = sub { ($w >> $_[0]) & ((1 << $_[1]) - 1) };
        my ($cond, $rn, $rd, $rm) = ($w >> 28, $f->(16, 4), $f->(12, 4), $w & 15);
        my $c = sprintf 'cond %04b %s', $cond, $armcond[$cond];
        my ($k, $cut, $what);
        if (($w & 0x0ffffff0) == 0x012fff10 || ($w & 0x0ffffff0) == 0x012fff30) {
            $k = $f->(5, 1) ? 'BLX (register)' : 'BX';
            ($cut, $what) = ([4, 8, 12, 4, 4], "$c, Rm $armreg[$rm]");
        } elsif (($w & 0x0fb00000) == 0x03000000) {
            $k = $f->(22, 1) ? 'MOVT' : 'MOVW';
            ($cut, $what) = ([4, 8, 4, 4, 12], sprintf '%s, imm4 %d, Rd %s, imm12 %d: imm16 0x%x', $c, $f->(16, 4), $armreg[$rd], $f->(0, 12), $f->(16, 4) << 12 | $f->(0, 12));
        } elsif (($w & 0x0c000000) == 0x00000000 && !(($w & 0x02000090) == 0x00000090) && !(($w & 0x01900000) == 0x01000000)) {
            my ($I, $op, $S) = ($f->(25, 1), $f->(21, 4), $f->(20, 1));
            $k = $armdp[$op];
            my $hd = sprintf '%s, I %d, opcode %04b %s, S %d, Rn %s, Rd %s', $c, $I, $op, lc $k, $S,
                ($op == 13 || $op == 15 ? 'none' : $armreg[$rn]), ($op >= 8 && $op <= 11 ? 'none (only the flags)' : $armreg[$rd]);
            if ($I) {
                my ($rot, $i8) = ($f->(8, 4), $f->(0, 8));
                my $v = (($i8 >> 2 * $rot) | ($i8 << (32 - 2 * $rot))) & 0xffffffff;
                $k .= ' (immediate)';
                ($cut, $what) = ([4, 2, 1, 4, 1, 4, 4, 4, 8], sprintf '%s, rotate %d, imm8 %d (%d)', $hd, $rot, $i8, $v);
            } elsif ($f->(4, 1) == 0) {
                $k .= ' (register)';
                ($cut, $what) = ([4, 2, 1, 4, 1, 4, 4, 5, 2, 1, 4], sprintf '%s, imm5 %d, type %02b %s, Rm %s', $hd, $f->(7, 5), $f->(5, 2), $armsh[$f->(5, 2)], $armreg[$rm]);
            } else {
                $k .= ' (register-shifted register)';
                ($cut, $what) = ([4, 2, 1, 4, 1, 4, 4, 4, 1, 2, 1, 4], sprintf '%s, Rs %s, type %02b %s, Rm %s', $hd, $armreg[$f->(8, 4)], $f->(5, 2), $armsh[$f->(5, 2)], $armreg[$rm]);
            }
        } elsif (($w & 0x0c000000) == 0x04000000 && !(($w & 0x02000010) == 0x02000010)) {
            my ($I, $P, $U, $B, $W, $L) = map { $f->($_, 1) } 25, 24, 23, 22, 21, 20;
            $k = ($L ? 'LDR' : 'STR') . ($B ? 'B' : '') . ($I ? ' (register)' : ' (immediate)');
            my $hd = sprintf '%s, I %d, P %d, U %d %s, B %d, W %d, L %d %s, Rn %s, Rt %s', $c, $I, $P, $U, $U ? 'add' : 'subtract', $B, $W, $L, $L ? 'load' : 'store', $armreg[$rn], $armreg[$rd];
            $hd .= $P ? ($W ? ' (pre-indexed, written back)' : ' (offset)') : ' (post-indexed)';
            if ($I) { ($cut, $what) = ([4, 3, 1, 1, 1, 1, 1, 4, 4, 5, 2, 1, 4], sprintf '%s, imm5 %d, type %s, Rm %s', $hd, $f->(7, 5), $armsh[$f->(5, 2)], $armreg[$rm]) }
            else { ($cut, $what) = ([4, 3, 1, 1, 1, 1, 1, 4, 4, 12], sprintf '%s, imm12 %d', $hd, $f->(0, 12)) }
        } elsif (($w & 0x0e000000) == 0x08000000) {
            my ($P, $U, $W, $L) = map { $f->($_, 1) } 24, 23, 21, 20;
            $k = ($L ? 'LDM' : 'STM') . ($P ? 'D' : 'I') . ($U ? ($P ? 'X' : 'A') : ($P ? 'B' : 'A'));
            $k = $L ? 'LDMIA (pop)' : 'STMDB (push)' if $rn == 13 && $W && $L == $U && $L != $P;
            ($cut, $what) = ([4, 3, 1, 1, 1, 1, 1, 4, 16], sprintf '%s, P %d, U %d, S %d, W %d, L %d, Rn %s, registers {%s}', $c, $P, $U, $f->(22, 1), $W, $L, $armreg[$rn], join(', ', map { $armreg[$_] } grep { $w >> $_ & 1 } 0 .. 15));
        } elsif (($w & 0x0e000000) == 0x0a000000) {
            my $imm = sxb($w & 0xffffff, 24);
            $k = $f->(24, 1) ? 'BL' : 'B';
            ($cut, $what) = ([4, 3, 1, 24], sprintf '%s, L %d %s, imm24 %d (offset %d, from the instruction + 8)', $c, $f->(24, 1), $f->(24, 1) ? 'with link' : 'without link', $imm, 4 * $imm);
        } elsif (($w & 0x0f000000) == 0x0f000000) {
            $k = 'SVC';
            ($cut, $what) = ([4, 4, 24], sprintf '%s, imm24 %d', $c, $f->(0, 24));
        } else { die sprintf "mkhex: no encoding of %08x in armwhy\n", $w }
        my $bits = sprintf '%032b', $w;
        my @g;
        for (@$cut) { push @g, substr $bits, 0, $_, '' }
        push @r, "$k " . join(' ', @g) . ": $what";
    }
    return @r;
}

# a line's bytes as tokens: [start, length, token] for each reference
sub fields {
    my ($l) = @_;
    return fields_rv($l) if $rv && $l->{sec} eq '.text' && $l->{mn} !~ /^\./;
    return fields_a64($l) if $a64 && $l->{sec} eq '.text' && $l->{mn} !~ /^\./;
    return fields_arm($l) if $arm && $l->{sec} eq '.text' && $l->{mn} !~ /^\./;
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
        } elsif ($type eq 'R_X86_64_64' || $type eq 'R_RISCV_64' || $type eq 'R_AARCH64_ABS64' || $type eq 'R_ARM_ABS32') {
            my $v = rd($foff + $p, $W);
            my $name = $v >> 32 ? undef : name_at($v, $l->{ops});
            if ($name) { push @f, [$p, 4, "&$name"] }
            else { push @raw, sprintf 'abs%d 0x%x', 8 * $W, $v }
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
        push @tok, $_->[3] if defined $_->[3];    # riscv64: the bytes, the field zero
        $p = $_->[0] + $_->[1];
    }
    push @tok, uc unpack('H*', substr $bin, $foff + $p, $e - $p) if $e > $p;
    return join ' ', @tok;
}

sub cm { my $c = shift; $c =~ s{^(\s*)//}{$1#} if $a64; $c =~ s{^(\s*)@}{$1#} if $arm; $c =~ /^\s*#/ ? $c : "# $c" }

sub row {
    my ($code, $comment) = @_;
    return cm($comment) if $code eq '';
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
            my $b = substr $bin, $foff + $l->{off}, $l->{end} - $l->{off};
            my @b = unpack '(H32)*', $b;
            push @r, row(uc shift @b, "$a  $t"), map { uc } @b;
            push @r, row('', sprintf '%-6s%s', '', rvwhy($b)) if $rv && $l->{mn} !~ /^\./;
            push @r, map { row('', sprintf '%-6s%s', '', $_) } a64why($b) if $a64 && $l->{mn} !~ /^\./;
            push @r, map { row('', sprintf '%-6s%s', '', $_) } armwhy($b) if $arm && $l->{mn} !~ /^\./;
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

# m1 for aarch64: each instruction as stage0-posix's aarch64 M1 writes it,
# a DEFINE of all its bits named as the instruction (objdump's text, its
# first space '_', no other spaces, no '#': mov_x8,93 ldr_x0,[x0]), but a
# reference to a label: ^~label then FBRANCH FCALL (14 94, forward) or
# RBRANCH RCALL (17 97, back) for B and BL, @label then the instruction
# without the label (its imm19 zero) for B.cond, CBZ, CBNZ, ~label adrp_xN
# and !label add_xN,xN,:lo12: for la's pair
if ($mode eq 'm1' && $a64) {
    my (%def, @rows, %dis);
    for (split /\n/, out("${X}objdump -d --no-show-raw-insn $t/e")) {
        $dis{ hex $1 } = $2 if /^\s*([0-9a-f]+):\s+(\S.*?)\s*$/;
    }
    my $nm = sub {
        my $s = shift;
        $s =~ s{\s*//.*}{};
        $s =~ s/\s+/_/;
        $s =~ s/\s+//g;
        $s =~ s/#//g;
        return $s;
    };
    my $put = sub {
        my ($name, $v, $why) = @_;
        die "mkhex: $name is $def{$name}[0] and $v\n" if $def{$name} && $def{$name}[0] ne $v;
        $def{$name} //= [$v, $why];
        return $name;
    };
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
        my @tok;
        for (my $p = $l->{off}; $p < $l->{end}; $p += 4) {
            my $w = rd($p, 4);
            my $d = $dis{$p} // die sprintf "mkhex: line %d: no disassembly at 0x%x\n", $l->{n}, $p;
            if (($w & 0x7c000000) == 0x14000000) {
                my $imm = sxb($w & 0x3ffffff, 26);
                my $lab = name_at($p + 4 * $imm, $l->{ops}) // die "mkhex: line $l->{n}: no label at the target of $t\n";
                my $k = ($w >> 31 ? 'CALL' : 'BRANCH');
                die "mkhex: line $l->{n}: a branch beyond 24 bits\n" if $imm >= 1 << 23 || $imm < -(1 << 23);
                push @tok, "^~$lab", $put->(($imm >= 0 ? 'F' : 'R') . $k, sprintf('%02X', $w >> 24),
                    ($w >> 31 ? 'BL' : 'B') . ': the top byte of op 00101 imm26, after ^~label\'s 3 bytes, ' . ($imm >= 0 ? 'forward' : 'back'));
            } elsif (($w & 0xff000010) == 0x54000000 || ($w & 0x7e000000) == 0x34000000) {
                my $lab = name_at($p + 4 * sxb(($w >> 5) & 0x7ffff, 19), $l->{ops}) // die "mkhex: line $l->{n}: no label at the target of $t\n";
                (my $n = $nm->($d)) =~ s/,?[0-9a-f]+(<[^>]*>)?$//;
                $n =~ s/_$//;
                push @tok, "\@$lab", $put->($n, &le($w & ~0x00ffffe0, 4), sprintf('%s, imm19 zero (@label)', ($w & 0xff000010) == 0x54000000 ? 'B.cond: 0101010 0 imm19 0 cond ' . $cond[$w & 15] : ($w >> 24 & 1 ? 'CBNZ' : 'CBZ') . ': sf 011010 op imm19 Rt'));
            } elsif (($w & 0x9f000000) == 0x90000000) {
                my $w2 = $p + 8 <= $l->{end} ? rd($p + 4, 4) : die "mkhex: line $l->{n}: an adrp alone\n";
                die "mkhex: line $l->{n}: an adrp without its add\n" unless ($w2 & 0xffc00000) == 0x91000000 && (($w2 >> 5) & 31) == ($w & 31);
                my $page = 4096 * sxb(((($w >> 5) & 0x7ffff) << 2) | (($w >> 29) & 3), 21) + ($p & ~0xfff);
                my $lab = name_at($page + (($w2 >> 10) & 0xfff), $l->{ops}) // die "mkhex: line $l->{n}: no label at the adrp's target\n";
                my ($r, $r2) = ($w & 31, ($w2 & 31));
                push @tok, "~$lab", $put->("adrp_x$r", &le($w & ~0x60ffffe0, 4), 'ADRP: op immlo 10000 immhi Rd, the immediate zero (~label)'),
                    "!$lab", $put->("add_x$r2,x$r,:lo12:", &le($w2 & ~0x003ffc00, 4), 'ADD (immediate): imm12 zero (!label)');
                $p += 4;
            } else {
                die sprintf "mkhex: line %d: tbz, tbnz, adr or ldr literal: %s\n", $l->{n}, $t
                    if ($w & 0x7e000000) == 0x36000000 || ($w & 0x9f000000) == 0x10000000 || ($w & 0x3b000000) == 0x18000000;
                push @tok, $put->($nm->($d), &le($w, 4), '');
            }
        }
        push @rows, row(join(' ', grep { $_ ne '' } $defs, @tok), $t);
    }
    push @out, "# $src as M1 text, made by gen/mkhex.pl, as stage0-posix's aarch64",
        "# M1 writes AArch64: first a DEFINE for each instruction it uses, its 4",
        "# bytes (little endian), named as objdump writes it (its first space '_',",
        "# no other spaces, no '#'), and for the references to labels the",
        "# instruction with that field zero: FBRANCH FCALL RBRANCH RCALL the top",
        "# byte of B or BL forward or back, after hex2's ^~label (its 3 low bytes),",
        "# b.cond cbz_xN cbnz_xN after \@label (imm19), adrp_xN after ~label (its",
        "# page), add_xN,xN,:lo12: after !label (its low 12 bits). Then each asm",
        "# line: :label for its labels, then its instructions. Data is hex or a",
        "# \"string\" (its bytes, then 00). M1 reads only what is before each '#';",
        "# M1's hex2 text is made by hex2.", '#';
    push @out, map { row("DEFINE $_ $def{$_}[0]", $def{$_}[1]) } sort keys %def;
    push @out, '#', @rows;
    print "$_\n" for @out;
    exit 0;
}

# m1 for riscv64: each instruction as stage0-posix's riscv64 M1 writes
# it: its registers (rd_a0 rs1_sp rs2_t0, the fields as words) and
# immediate (!n I, @n S, ~n U) or label (@label B, $label J, ~label and
# !label an auipc pair), then its name, the DEFINE of its fixed bits
my %rvop = (0x33 => 'R', 0x13 => 'I', 0x1b => 'I', 0x03 => 'I', 0x67 => 'I', 0x73 => 'I', 0x23 => 'S', 0x63 => 'B', 0x6f => 'J', 0x37 => 'U', 0x17 => 'U');
my %rvname = (
    '33.0.0' => 'add', '33.0.32' => 'sub', '33.1.0' => 'sll', '33.2.0' => 'slt', '33.3.0' => 'sltu', '33.4.0' => 'xor',
    '33.5.0' => 'srl', '33.5.32' => 'sra', '33.6.0' => 'or', '33.7.0' => 'and', '33.0.1' => 'mul', '33.4.1' => 'div',
    '33.5.1' => 'divu', '33.6.1' => 'rem', '33.7.1' => 'remu',
    '13.0' => 'addi', '13.2' => 'slti', '13.3' => 'sltiu', '13.4' => 'xori', '13.6' => 'ori', '13.7' => 'andi',
    '13.1' => 'slli', '13.5' => 'srli', '1b.0' => 'addiw', '3.0' => 'lb', '3.1' => 'lh', '3.2' => 'lw', '3.3' => 'ld',
    '3.4' => 'lbu', '3.5' => 'lhu', '3.6' => 'lwu', '67.0' => 'jalr', '73.0' => 'ecall', '23.0' => 'sb', '23.1' => 'sh',
    '23.2' => 'sw', '23.3' => 'sd', '63.0' => 'beq', '63.1' => 'bne', '63.4' => 'blt', '63.5' => 'bge', '63.6' => 'bltu',
    '63.7' => 'bgeu', '6f' => 'jal', '37' => 'lui', '17' => 'auipc');
my %opname = (0x33 => 'OP', 0x13 => 'OP-IMM', 0x1b => 'OP-IMM-32', 0x03 => 'LOAD', 0x67 => 'JALR', 0x73 => 'SYSTEM',
    0x23 => 'STORE', 0x63 => 'BRANCH', 0x6f => 'JAL', 0x37 => 'LUI', 0x17 => 'AUIPC');
sub rvword { my $v = shift; '.' . &le($v & 0xffffffff, 4) }
sub rvnum { my $v = shift; $v < 0 ? ($v > -4096 ? $v : sprintf '-0x%x', -$v) : $v < 4096 ? $v : sprintf '0x%x', $v }
if ($mode eq 'm1' && $rv) {
    my (%def, @rows);
    my $reg = sub {
        my ($f, $n, $sh) = @_;
        my $name = "${f}_$abi[$n]";
        $def{$name} //= [rvword($n << $sh), sprintf '%s x%d %s: bits %d:%d, a word', $f, $n, $abi[$n], $sh + 4, $sh];
        return $name;
    };
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
        my @tok;
        my $pair;    # the label of an auipc, for the instruction after it
        for (my $p = $l->{off}; $p < $l->{end}; $p += 4) {
            my $w = rd($p, 4);
            my ($op, $rd, $f3, $rs1, $rs2, $f7) = ($w & 0x7f, ($w >> 7) & 31, ($w >> 12) & 7, ($w >> 15) & 31, ($w >> 20) & 31, $w >> 25);
            my $k = $rvop{$op} // die sprintf "mkhex: line %d: opcode %07b\n", $l->{n}, $op;
            my $key = sprintf '%x', $op;
            $key .= ".$f3" unless $k eq 'J' || $k eq 'U';
            $key .= '.' . ($f7 & ~0) if $k eq 'R';
            my $name = $rvname{$key} // die "mkhex: line $l->{n}: instruction $key\n";
            my $fixed = $w & ($k eq 'R' ? 0xfe00707f : $k eq 'J' || $k eq 'U' ? 0x7f : 0x707f);
            if ($name eq 'srli' && ($w >> 30) & 1) { $name = 'srai' }
            $fixed |= $w & 0x40000000 if $name eq 'srai';
            $fixed = $w if $name eq 'ecall';
            my @f;
            push @f, $reg->('rd', $rd, 7) if $rd && $k ne 'S' && $k ne 'B';
            push @f, $reg->('rs1', $rs1, 15) if $rs1 && $k ne 'U' && $k ne 'J';
            push @f, $reg->('rs2', $rs2, 20) if $rs2 && ($k eq 'R' || $k eq 'S' || $k eq 'B');
            my $P = $p;
            if ($k eq 'I' && $name ne 'ecall') {
                my $imm = $name =~ /^s[lr][la]i$/ ? $rs2 | (($w >> 20) & 32) : iimm($w);
                if (defined $pair) { push @f, "!$pair"; undef $pair }
                elsif ($imm) { push @f, '!' . rvnum($imm) }
            } elsif ($k eq 'S') {
                my $imm = sxb(($w >> 25) << 5 | $rd, 12);
                push @f, '@' . rvnum($imm) if $imm;
            } elsif ($k eq 'B' || $k eq 'J') {
                my $tgt = $P + ($k eq 'B' ? bimm($w) : jimm($w));
                my $lab = name_at($tgt, $l->{ops});
                if (!defined $lab && $k eq 'B' && $tgt == $P + 8 && $p + 8 <= $l->{end} && (rd($p + 4, 4) & 0x7f) == 0x6f) {
                    push @f, rvword($w & 0xfe000f80);    # gas's far branch: the other one over a jal, +8 as a word
                } else {
                    die "mkhex: line $l->{n}: no label at the target of $t\n" unless defined $lab;
                    push @f, ($k eq 'B' ? '@' : '$') . $lab;
                }
            } elsif ($name eq 'auipc') {
                my $w2 = $p + 8 <= $l->{end} ? rd($p + 4, 4) : die "mkhex: line $l->{n}: an auipc alone\n";
                my $lab = name_at($P + uimm($w) + iimm($w2), $l->{ops}) // die "mkhex: line $l->{n}: no label at the auipc's target\n";
                push @f, "~$lab";
                $pair = $lab;
            } elsif ($name eq 'lui') {
                push @f, '~' . sprintf('0x%x', $w & 0xfffff000);
            }
            my $why = sprintf '%s: opcode %07b %s', $k, $op, $opname{$op};
            $why .= sprintf ', funct3 %03b', $f3 unless $k eq 'J' || $k eq 'U';
            $why .= sprintf ', funct7 %07b', $f7 if $k eq 'R';
            $why .= ', bit 30: arithmetic' if $name eq 'srai';
            $why .= ', all of it' if $name eq 'ecall';
            die "mkhex: $name is $def{$name}[0] and " . &le($fixed, 4) . "\n" if $def{$name} && $def{$name}[0] ne &le($fixed, 4);
            $def{$name} //= [&le($fixed, 4), $why];
            push @tok, @f, $name;
        }
        push @rows, row(join(' ', grep { $_ ne '' } $defs, @tok), $t);
    }
    push @out, "# $src as M1 text, made by gen/mkhex.pl, as stage0-posix's riscv64",
        "# M1 writes RISC-V: first a DEFINE for each instruction it uses, its",
        "# fixed bits (opcode, funct3, funct7; little endian), and for each",
        "# register field it uses, rd_<reg> rs1_<reg> rs2_<reg>, a word (.hex,",
        "# which hex2 XORs into the next 4 bytes written). Then each asm line:",
        "# :label for its labels, then each instruction's fields, then its name:",
        "# its registers (x0 left out), its immediate (!n I, \@n S, ~n U, as",
        "# words; 0 left out) or its label (\@label B, \$label J, ~label and !label",
        "# an auipc and the instruction after it, as hex2's references; a branch",
        "# to a label out of its reach is gas's, the other branch over a jal, its",
        "# +8 the word .00040000). Data is",
        "# hex or a \"string\" (its bytes, then 00). M1 reads only what is before",
        "# each '#'; M1's hex2 text is made by hex2.", '#';
    push @out, map { row("DEFINE $_ $def{$_}[0]", $def{$_}[1]) } sort { ($a =~ /^r[ds]/) <=> ($b =~ /^r[ds]/) || $a cmp $b } keys %def;
    push @out, '#', @rows;
    print "$_\n" for @out;
    exit 0;
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
        $a64 ? ("# of the next byte (from 0, the file's first byte); ^~label writes 3",
            "# bytes, imm26's low 24 bits of B or BL (label minus the instruction's",
            "# address, / 4), the byte after them the rest; \@label (imm19 of B.cond,",
            "# CBZ, CBNZ), ~label (ADRP's page) and !label (the ADD :lo12: after it)",
            "# XOR their field into the instruction after them, written with that",
            "# field zero. hex2 reads only what is before each '#'.", '#')
        :         $rv ? ("# of the next byte (from 0, the file's first byte); a reference",
            "# (\@label B, \$label J, ~label and !label an auipc and the instruction",
            "# after it) XORs label minus the instruction's address into the",
            "# immediate field of the instruction after it, written with that field",
            "# zero. hex2 reads only what is before each '#'.", '#')
        : ("# of the next byte (from 0, the file's first byte); %label is the 4",
            "# bytes of label minus the address after them (rel32), !label the same",
            "# in 1 byte (rel8). hex2 reads only what is before each '#'.", '#');
    push @out, section_rows('.text');
    print "$_\n" for @out;
    exit 0;
}

# hex2: the ELF header and program headers, field by field
my @ehdr = (
    [16, 'e_ident', 'the magic 7f "ELF", ' . ($arm ? 'ELFCLASS32' : 'ELFCLASS64') . ', little endian, EV_CURRENT, System V, padding'],
    [2, 'e_type', 'ET_EXEC, an executable'], [2, 'e_machine', $rv ? 'EM_RISCV' : $a64 ? 'EM_AARCH64' : $arm ? 'EM_ARM' : 'EM_X86_64'], [4, 'e_version', 'EV_CURRENT'],
    [$W, 'e_entry', 'the address of _start'], [$W, 'e_phoff', 'the program headers follow'],
    [$W, 'e_shoff', 'the section headers, at the end'], [4, 'e_flags', $rv ? 'EF_RISCV_RVC, compressed instructions; the soft-float ABI' : $a64 ? 'none on aarch64' : $arm ? 'EF_ARM_EABI_VER5, EF_ARM_ABI_FLOAT_SOFT' : 'none on x86_64'],
    [2, 'e_ehsize', 'this header'], [2, 'e_phentsize', 'a program header'],
    [2, 'e_phnum', 'program headers'], [2, 'e_shentsize', 'a section header'],
    [2, 'e_shnum', 'section headers'], [2, 'e_shstrndx', 'the section of the section names']);
my @phdr = $arm ? (
    [4, 'p_type', '1: PT_LOAD'], [4, 'p_offset', 'from this file offset'],
    [4, 'p_vaddr', 'to this address'], [4, 'p_paddr', 'the same'], [4, 'p_filesz', 'bytes of the file'],
    [4, 'p_memsz', 'bytes of memory, the rest zero'], [4, 'p_flags', '4 R, 2 W, 1 X'], [4, 'p_align', 'a page']) : (
    [4, 'p_type', '1: PT_LOAD'], [4, 'p_flags', '4 R, 2 W, 1 X'], [8, 'p_offset', 'from this file offset'],
    [8, 'p_vaddr', 'to this address'], [8, 'p_paddr', 'the same'], [8, 'p_filesz', 'bytes of the file'],
    [8, 'p_memsz', 'bytes of memory, the rest zero'], [8, 'p_align', 'a page']);
my @shdr = (
    [4, 'sh_name', 'its name at this offset of .shstrtab'], [4, 'sh_type', '1 PROGBITS, 3 STRTAB, 8 NOBITS' . ($arm ? ', 0x70000003 ARM_ATTRIBUTES' : '')],
    [$W, 'sh_flags', '1 W, 2 A, 4 X'], [$W, 'sh_addr', 'its address'], [$W, 'sh_offset', 'its file offset'],
    [$W, 'sh_size', 'its size'], [4, 'sh_link', ''], [4, 'sh_info', ''], [$W, 'sh_addralign', ''],
    [$W, 'sh_entsize', '']);
my ($PH, $SH) = $arm ? (32, 40) : (56, 64);    # a program header's and a section header's size
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

my $phoff = $arm ? rd(28, 4) : rd(32, 8);
my $phnum = $arm ? rd(44, 2) : rd(56, 2);
my $shoff = $arm ? rd(32, 4) : rd(40, 8);
my $shnum = $arm ? rd(48, 2) : rd(60, 2);
my $shstr = $sec{'.shstrtab'} or die "mkhex: no .shstrtab\n";
my ($delta) = $arm ? rd($phoff + 8, 4) - rd($phoff + 4, 4) : rd($phoff + 16, 8) - rd($phoff + 8, 8);
push @out, "# $src as hex2 text, made by gen/mkhex.pl from GNU as's and ld's output:",
    "# the whole executable in the order of its bytes. :label defines a label",
    $arm ? (
    "# at the address of the next byte; &label is label's address in 4 bytes",
    "# (abs32, a .word). The code's references: ^~label (stage0-posix's B, BL",
    "# and B<cond>) writes 3 bytes, imm24, (d - 8) / 4 (d is label minus the",
    "# instruction's address, the pc reads 8 ahead), the byte after them is",
    "# cond and the opcode (EA b, EB bl, 0A beq, ...); !label and ~label XOR",
    "# label's address into the MOVW (:lower16:, its low 16 bits) and the MOVT",
    "# (:upper16:, its high 16 bits) after them, each written with its imm4",
    "# and imm12 zero;") :
    $a64 ? (
    "# at the address of the next byte; &label is label's address in 4 bytes",
    "# (abs32, the low half of a .dword). The code's references: ^~label",
    "# (stage0-posix's B and BL) writes 3 bytes, imm26's low 24 bits, d / 4",
    "# (d is label minus the instruction's address), the byte after them has",
    "# imm26's top 2 bits and the opcode; the others XOR their field into",
    "# the instruction after them, which is written with that field zero:",
    "# \@label imm19 of B.cond, CBZ, CBNZ (d / 4), ~label ADRP's page",
    "# difference, !label the ADD :lo12: after it (label's low 12 bits);") :
    $rv ? (
    "# at the address of the next byte; &label is label's address in 4 bytes",
    "# (abs32, the low half of a .dword). The code's references XOR their",
    "# field into the instruction after them, which is written with that",
    "# field zero; d is label minus the instruction's address: ~label",
    "# auipc's U (d + 0x800, its bits 31:12), !label the I of the addi, ld",
    "# or jalr after the auipc (d + 4, from the auipc, its bits 11:0), \@label",
    "# a branch's B, \$label jal's J, |label c.beqz's and c.bnez's CB, *label",
    "# c.j's CJ;") : (
    "# at the address of the next byte; %label is the 4 bytes of label minus",
    "# the address after them (rel32), !label the same in 1 byte (rel8),",
    "# &label label's address in 4 bytes (abs32, the low half of a .quad);"),
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
    push @out, fieldrows($phoff + $PH * $i, \@phdr);
}
my $pos = $phoff + $PH * $phnum;
for my $s (grep { !$sec{$_}[3] && $_ ne '.shstrtab' } @order) {
    my ($addr, $foff, $size) = @{ $sec{$s} };
    die "mkhex: $s before the file position\n" if $foff < $pos;
    if ($foff > $pos) {
        push @out, row(uc unpack('H*', substr $bin, $pos, $foff - $pos), "padding to ${s}'s file offset");
    }
    if ($s eq '.ARM.attributes') {    # not loaded: gas's build attributes for .arch armv7-a
        my @a = (1 => "format 'A'", 4 => "the subsection's length, 0x1c", 6 => '"aeabi" and its 0', 5 => 'Tag_File 1, then the length of its attributes, 0x12',
            5 => 'Tag_CPU_name 5: "7-A" and its 0', 2 => 'Tag_CPU_arch 6: 10, v7', 2 => "Tag_CPU_arch_profile 7: 'A', application",
            2 => 'Tag_ARM_ISA_use 8: 1, yes', 2 => 'Tag_THUMB_ISA_use 9: 2, Thumb-2');
        push @out, '#', "# The section $s: gas's build attributes (not loaded), as readelf -A says them";
        my $q = $foff;
        while (@a) { my ($n, $why) = splice @a, 0, 2; push @out, row(uc unpack('H*', substr $bin, $q, $n), $why); $q += $n }
        die "mkhex: $s is not as gas writes it for armv7-a\n" if $q != $foff + $size || substr($bin, $foff, $size) ne pack('H*', '411c000000616561626900011200000005372d4100060a074108010902');
        $pos = $foff + $size;
        next;
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
    my $o = $shoff + $SH * $i;
    my $nm = rd($o, 4);
    my $z = index($bin, "\0", $so + $nm);
    push @out, '#', sprintf('# Section header %d%s', $i, $i ? ': ' . substr($bin, $so + $nm, $z - $so - $nm) : '');
    push @out, fieldrows($o, \@shdr);
}
die "mkhex: bytes after the section headers\n" if $shoff + $SH * $shnum != length $bin;
print "$_\n" for @out;
