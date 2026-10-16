#!/usr/bin/env perl
# s2ff.pl — riscv64 asm as ff: the functions of a preprocessed .S file (the
# .s its build assembled, from src/glibc/mki.pl), each an asm function of
# ttpc's C layer, name: / asm / its instructions, which C reaches as it
# reaches a C function. One instruction per instruction, operands in ff's
# order (the encoding's, the destination last); nothing is lowered.
#
#   perl s2ff.pl [--page name] file.s file.dump > out.ff.txt
#   perl s2ff.pl --size file.s file.dump     the bytes of those instructions
#
# file.dump is what GNU as made of file.s, without relaxation, as objdump
# -d -M no-aliases prints it: where it chose a compressed instruction, the ff
# names that one (c.mv, c.add, ...), so ttpc emits the same bytes. GNU as
# picks those by size and by the distance of a branch; this takes its pick
# instead of redoing it.
#
#   label:          a function (a global label) or, inside one, a block
#                   label holding the instructions up to the next label
#   directives      .globl .type .size .cfi_* .option .align .text give no
#                   bytes of their own here and are dropped (ttpc places a
#                   function on a 2-byte boundary, as RVC allows); any other
#                   stops the translation
#   instructions    GNU's operands reversed (loads off base rd, stores off
#                   rs2 base, a branch target as rel label), the macros of
#                   macros/riscv64.ff.txt as they are; vector ones vm first
#                   (1, or 0 under v0.t), then their sources in GNU's order,
#                   the destination last; a vtype is its number
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt);

my $page = 'glibc asm';
my @files;
my $size;
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--size') { $size = 1; next }
    push @files, $a;
}
die "usage: s2ff.pl [--page name | --size] file.s file.dump\n" unless @files == 2;
my ($src, $dump) = @files;
my $where = $src;
sub fail { die "s2ff: $where: @_\n" }

# ---- what GNU as made: the size and the canonical form of each instruction
my @made;
open my $d, '<', $dump or die "s2ff: cannot open $dump: $!\n";
while (<$d>) {
    next unless /^\s*([0-9a-f]+):\t([0-9a-f ]+?)\s*\t(\S+)\s*(.*)$/;
    push @made, { bytes => length($2 =~ s/ //gr) / 2, op => $3, args => $4 };
}
close $d;

# ---- operands --------------------------------------------------------------
sub split_ops {
    my ($s) = @_;
    my @ops;
    my ($cur, $depth) = ('', 0);
    for my $c (split //, $s) {
        $depth++ if $c eq '(';
        $depth-- if $c eq ')';
        if ($c eq ',' && !$depth) { push @ops, $cur; $cur = ''; next }
        $cur .= $c;
    }
    push @ops, $cur if $cur =~ /\S/;
    s/^\s+|\s+$//g for @ops;
    @ops;
}

my %abi = (fp => 's0', map { ("x$_" => (qw(zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7
    s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6))[$_]) } 0 .. 31);
sub reg { my ($r) = @_; $abi{$r} // $r }
sub num {
    my ($v) = @_;
    return hex($v) if $v =~ /^0x[0-9a-f]+$/i;
    return -hex($1) if $v =~ /^-0x([0-9a-f]+)$/i;
    return $v if $v =~ /^-?\d+$/;
    fail "not a number: $v";
}
# off(base) of a load or store
sub mem { my ($m) = @_; $m =~ /^(.*)\((\w+)\)$/ or fail "not off(base): $m"; (num($1 eq '' ? 0 : $1), reg($2)) }

my %csr = (vstart => 0x008, vxsat => 0x009, vxrm => 0x00a, vcsr => 0x00f,
    vl => 0xc20, vtype => 0xc21, vlenb => 0xc22);
my %sew = (e8 => 0, e16 => 1, e32 => 2, e64 => 3);
my %lmul = (m1 => 0, m2 => 1, m4 => 2, m8 => 3, mf8 => 5, mf4 => 6, mf2 => 7);
sub vtype {
    my ($s, $l, $ta, $ma) = @_;
    defined $sew{$s} && defined $lmul{$l} or fail "not a vtype: @_";
    (($ma // '') eq 'ma') << 7 | (($ta // '') eq 'ta') << 6 | $sew{$s} << 3 | $lmul{$l};
}

# a leaf for each operand; a register, a number, or a label of the function
sub leaf {
    my ($o) = @_;
    return node(reg($o)) if $o =~ /^[a-z][a-z0-9]*$/ && !exists $csr{$o};
    return node(num($o)) if $o =~ /^-?(0x)?[0-9a-f]+$/i;
    return node($o);
}
sub ins { my ($op, @a) = @_; node($op, map { ref $_ ? $_ : leaf($_) } @a) }
sub rel { node('rel', node($_[0])) }

my %rtype = map { $_ => 1 } qw(add sub and or xor sll srl sra slt sltu addw subw sllw srlw sraw
    mul mulh mulhu mulhsu div divu rem remu mulw divw divuw remw remuw);
my %itype = map { $_ => 1 } qw(addi andi ori xori slti sltiu slli srli srai addiw slliw srliw sraiw);
my %load = map { $_ => 1 } qw(lb lh lw ld lbu lhu lwu);
my %store = map { $_ => 1 } qw(sb sh sw sd);
my %btype = map { $_ => 1 } qw(beq bne blt bge bltu bgeu);
# the macros of macros/riscv64.ff.txt, which take GNU's operands reversed
my %macro = map { $_ => 1 } qw(mv li neg seqz j jr ret beqz bnez bltz bgez blez bgtz bgt ble bgtu bleu csrr);
my %vmask = map { $_ => 1 } qw(vmseq vmsne vmsltu vmsleu vmsgtu vadd vsub vand vor vxor vrgather
    vredmaxu vredminu vredsum vredor);

# a source instruction GNU as left at 4 bytes
sub full {
    my ($op, @o) = @_;
    return ins($op, $csr{$o[1]} // num($o[1]), $o[0]) if $op eq 'csrr';
    my $vm = 1;
    if (@o && $o[-1] eq 'v0.t') { pop @o; $vm = 0 }
    return ins($op, reverse @o) if $rtype{$op} || $itype{$op} || $macro{$op};
    return ins($op, mem($o[1]), $o[0]) if $load{$op};
    if ($store{$op}) { my ($off, $base) = mem($o[1]); return ins($op, $off, $o[0], $base) }
    return ins($op, rel($o[2]), $o[1], $o[0]) if $btype{$op};
    # the aliases GNU as takes for one instruction
    return ins('slt', 'zero', $o[1], $o[0]) if $op eq 'sltz';
    return ins('slt', $o[1], 'zero', $o[0]) if $op eq 'sgtz';
    return ins('sltu', $o[1], 'zero', $o[0]) if $op eq 'snez';
    return ins('xori', -1, $o[1], $o[0]) if $op eq 'not';
    return ins('subw', $o[1], 'zero', $o[0]) if $op eq 'negw';
    return ins('addiw', 0, $o[1], $o[0]) if $op eq 'sext.w';
    # vector
    return ins($op, vtype(@o[2 .. $#o]), $o[1], $o[0]) if $op eq 'vsetvli';
    return ins($op, vtype(@o[2 .. $#o]), num($o[1]), $o[0]) if $op eq 'vsetivli';
    return ins($op, $o[2], $o[1], $o[0]) if $op eq 'vsetvl';
    if ($op =~ /^v[ls]e\d+(ff)?\.v$/) { $o[1] =~ /^\((\w+)\)$/ or fail "not (base): $o[1]"; return ins($op, $vm, $1, $o[0]) }
    if ($op =~ /^(\w+)\.(vv|vx|vi|vs)$/ && $vmask{$1}) { return ins($op, $vm, $o[1], $o[2], $o[0]) }
    return ins($op, $vm, $o[1], $o[0]) if $op =~ /^(vfirst|vcpop|vmsbf|vmsof|vmsif)\.m$/;
    return ins($op, $vm, $o[0]) if $op eq 'vid.v';
    return ins($op, $o[1], $o[0]) if $op =~ /^vmv\.(v\.[vxi]|x\.s|s\.x)$/;
    return ins($op, $o[1], $o[2], $o[0]) if $op =~ /^vm\w+\.mm$/;
    fail "no ff form for $op";
}

# an instruction GNU as compressed, in its canonical form; a branch target
# is the source's label
sub short {
    my ($m, $label) = @_;
    my ($op, @o) = ($m->{op}, split_ops($m->{args} =~ s/\s*<.*>$//r));
    return ins($op, @o) if $op =~ /^c\.(mv|add|sub|xor|or|and|subw|addw)$/;
    return ins($op, $o[0]) if $op =~ /^c\.(jr|jalr)$/;
    return ins($op, @o[1, 0]) if $op =~ /^c\.(li|addi|addiw|slli|srli|srai|andi)$/;
    return ins($op, rel($label), $o[0]) if $op =~ /^c\.(beqz|bnez)$/;
    return ins($op, rel($label)) if $op eq 'c.j';
    if ($op =~ /^c\.(ld|lw)$/) { my ($off, $base) = mem($o[1]); return ins($op, $off, $base, $o[0]) }
    if ($op =~ /^c\.(sd|sw)$/) { my ($off, $base) = mem($o[1]); return ins($op, $off, $base, $o[0]) }
    if ($op =~ /^c\.(ldsp|lwsp|sdsp|swsp)$/) { my ($off) = mem($o[1]); return ins($op, $off, $o[0]) }
    return ins($op, num($o[2]), $o[0]) if $op eq 'c.addi4spn';
    return ins($op, num($o[1])) if $op eq 'c.addi16sp';
    return ins($op) if $op =~ /^c\.(nop|ebreak)$/;
    fail "no ff form for $op";
}

# ---- the source --------------------------------------------------------------
my (@fns, $fn, $block, $file, $line);
my $n = 0;
open my $s, '<', $src or die "s2ff: cannot open $src: $!\n";
while (my $l = <$s>) {
    chomp $l;
    if ($l =~ /^# (\d+) "([^"]+)"/) { ($line, $file) = ($1 - 1, $2 =~ s{^(\.\./)+}{}r); next }
    $line++;
    $where = "$src ($file:$line)";
    for my $st (split /;/, $l) {
        $st =~ s/^\s+|\s+$//g;
        next if $st eq '';
        while ($st =~ s/^([.\w]+):\s*//) {
            my $name = $1;
            if ($name =~ /^\.L/) {
                fail "label $name outside a function" unless $fn;
                $block = node("$name:");
                push @{$fn->{children}}, $block;
            } else {
                $fn = node("$name:", node('asm'), node('comment', node("glibc-2.44 $file:$line")));
                push @fns, $fn;
                undef $block;
            }
        }
        next if $st eq '';
        my ($op, $rest) = $st =~ /^(\S+)\s*(.*)$/;
        if ($op =~ /^\./) {
            next if $op =~ /^\.(globl|global|type|size|align|p2align|text|cfi_\w+)$/;
            next if $op eq '.option' && $rest =~ /^(push|pop|arch\b.*|norelax|relax)$/;
            fail "a directive with no ff form: $st";
        }
        fail "an instruction outside a function: $st" unless $fn;
        my $m = $made[$n++] or fail "GNU as made fewer instructions than $src has";
        my @o = split_ops($rest);
        my $i;
        if ($m->{bytes} == 2) {
            my ($target) = grep { /^\.L/ } @o;
            $i = short($m, $target);
        } else {
            $i = full($op, @o);
        }
        push @{($block // $fn)->{children}}, $i;
    }
}
close $s;
# what is left is the padding GNU as puts at the end of the section
pop @made while @made > $n && $made[-1]{op} =~ /^c\.(addi|nop)$|^addi$/ && $made[-1]{args} =~ /^zero,(zero,)?0$/;
fail "GNU as made " . scalar(@made) . " instructions, $src has $n" unless $n == @made;
if ($size) { my $b = 0; $b += $_->{bytes} for @made; print "$b\n"; exit }
print write_txt(node("$page:", @fns));
