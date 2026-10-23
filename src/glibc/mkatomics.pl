#!/usr/bin/env perl
# mkatomics.pl — writes atomics.ff.txt: libatomic's functions, which gcc
# calls for an atomic builtin it does not expand (__atomic_load_4, ...),
# for 1, 2, 4 and 8 bytes, in ttpc's C layer. c2ff turns glibc's atomic
# builtins into calls of them. A ttpc program has one thread, so plain loads
# and stores are exact; real atomics come with threads.
#
#   perl mkatomics.pl > atomics.ff.txt
#   perl mkatomics.pl riscv64 > atomics-riscv64.ff.txt
#
# With a target, real atomics in its asm, as gcc makes them (riscv64: amo
# for 4 and 8 bytes, lr/sc for nand and compare-exchange, and on the
# aligned word for 1 and 2 bytes, aq and rl on each, fences around plain
# loads and stores): glibc's threads and processes that share memory (a
# process-shared barrier: tst-arc4random-fork lost updates of its out with
# the plain ones). A result of fewer bits than a word is zero-extended.
#
# A host tool (core Perl only).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../compiler/gen";
use FF qw(node ttp_license write_txt);

sub leaf { map { node($_) } @_ }
sub param { my ($n, @t) = @_; node("$n:", leaf(@t)) }
# C's *p: p, then * pointer
sub content { (node($_[0]), node('* pointer')) }

my $target = shift // '';
if ($target eq 'riscv64') { rv64(); exit 0 }
die "mkatomics: no real atomics for $target yet\n" if $target ne '';

my @fns;
for my $n (1, 2, 4, 8) {
    my $u = "u" . 8 * $n;
    my @p = (param('p', $u, '* pointer'));
    push @fns, node("__atomic_load_$n:", leaf($u), @p, param('order', 'int'),
        node('return', content('p')));
    push @fns, node("__atomic_store_$n:", leaf('void'), @p, param('v', $u), param('order', 'int'),
        content('p'), leaf('=', 'v'));
    push @fns, node("__atomic_exchange_$n:", leaf($u), @p, param('v', $u), param('order', 'int'),
        node('old:', leaf($u), content('p')), content('p'), leaf('=', 'v'), node('return', leaf('old')));
    push @fns, node("__atomic_compare_exchange_$n:", leaf('int'), @p, param('e', $u, '* pointer'), param('d', $u),
        param('success', 'int'), param('failure', 'int'),
        node('if', content('p'), leaf('=='), content('e'), content('p'), leaf('=', 'd'), node('return', leaf(1))),
        content('e'), leaf('='), content('p'), node('return', leaf(0)));
    for my $op (['add', '+'], ['sub', '-'], ['and', '&'], ['or', '|'], ['xor', '^'], ['nand', '&']) {
        my ($name, $c) = @$op;
        # nand is ~(old & v)
        my @new = $name eq 'nand' ? (leaf('~'), node(':', leaf('old', $c, 'v'))) : leaf('old', $c, 'v');
        push @fns, node("__atomic_fetch_${name}_$n:", leaf($u), @p, param('v', $u), param('order', 'int'),
            node('old:', leaf($u), content('p')), content('p'), leaf('='), @new, node('return', leaf('old')));
        push @fns, node("__atomic_${name}_fetch_$n:", leaf($u), @p, param('v', $u), param('order', 'int'),
            node('old:', leaf($u), content('p')), content('p'), leaf('='), @new, node('return', content('p')));
    }
}
print write_txt(node('comment', node("libatomic's functions for one thread, written by mkatomics.pl.")),
    node('atomics:', ttp_license(), @fns));

# ---- riscv64 ------------------------------------------------------------
# An asm function of lines, `op a b ...` in ttpc's order (destination last),
# `L:` a label holding the lines after it.
sub asmfn {
    my ($name, $text) = @_;
    my (@top, $lab);
    for my $l (split /\n/, $text) {
        $l =~ s/^\s+|\s+$//g;
        next if $l eq '';
        if ($l =~ /^(\w+):$/) { $lab = node("$1:"); push @top, $lab; next }
        my ($op, @a) = split ' ', $l;
        my @k = map { /^rel:(.*)$/ ? node('rel', node($1)) : node($_) } @a;
        my $i = node($op, @k);
        if ($lab) { push @{ $lab->{children} }, $i } else { push @top, $i }
    }
    node("$name:", node('asm'), @top);
}
sub rv64 {
    my @f;
    my %ld = (1 => 'lbu', 2 => 'lhu', 4 => 'lwu', 8 => 'ld');
    my %st = (1 => 'sb', 2 => 'sh', 4 => 'sw', 8 => 'sd');
    my %amo = (add => 'amoadd', and => 'amoand', or => 'amoor', xor => 'amoxor');
    my %rop = (add => 'add', sub => 'sub', and => 'and', or => 'or', xor => 'xor');
    for my $n (1, 2, 4, 8) {
        my $zx = $n == 4 ? "slli 32 a0 a0\nsrli 32 a0 a0\n" : '';
        # load and store: plain, between fences (rw,rw before; r,rw after a
        # load, rw,rw after a store)
        push @f, asmfn("__atomic_load_$n", "fence 0 3 3\n$ld{$n} 0 a0 a0\nfence 0 2 3\nret");
        push @f, asmfn("__atomic_store_$n", "fence 0 3 1\n$st{$n} 0 a1 a0\nfence 0 3 3\nret");
        if ($n >= 4) {
            my $s = $n == 4 ? 'w' : 'd';
            my $lw = $n == 4 ? 'lw' : 'ld';
            push @f, asmfn("__atomic_exchange_$n", "amoswap.$s 1 1 a1 a0 a0\n${zx}ret");
            push @f, asmfn("__atomic_compare_exchange_$n", "
                $lw 0 a1 a3
                L1:
                lr.$s 1 1 a0 t0
                bne rel:L2 a3 t0
                sc.$s 1 1 a2 a0 t6
                bnez L1 t6
                li 1 a0
                ret
                L2:
                $st{$n} 0 t0 a1
                li 0 a0
                ret");
            for my $op (qw(add sub and or xor)) {
                my $pre = $op eq 'sub' ? "neg a1 t1\n" : '';
                my $amo = $op eq 'sub' ? "amoadd.$s 1 1 t1 a0 t0" : "$amo{$op}.$s 1 1 a1 a0 t0";
                push @f, asmfn("__atomic_fetch_${op}_$n", "$pre$amo\nmv t0 a0\n${zx}ret");
                push @f, asmfn("__atomic_${op}_fetch_$n", "$pre$amo\n$rop{$op} a1 t0 a0\n${zx}ret");
            }
            for my $w (['fetch_nand', 't0'], ['nand_fetch', 't2']) {
                push @f, asmfn("__atomic_$w->[0]_$n", "
                    L1:
                    lr.$s 1 1 a0 t0
                    and a1 t0 t2
                    xori -1 t2 t2
                    sc.$s 1 1 t2 a0 t6
                    bnez L1 t6
                    mv $w->[1] a0
                    ${zx}ret");
            }
            next;
        }
        # 1 and 2 bytes: lr/sc on the aligned word that holds them: t3 the
        # field's shift, a4 its mask, t4 the mask in place, t5 its complement;
        # t1 the old field, t2 the new one
        my $mask = $n == 1 ? 255 : 65535;
        my $setup = "
            andi 3 a0 t3
            slli 3 t3 t3
            andi -4 a0 a0
            li32 $mask a4
            sll t3 a4 t4
            xori -1 t4 t5
            and a4 a1 a1";
        my $put = "
            and a4 t2 t2
            sll t3 t2 t6
            and t5 t0 a5
            or t6 a5 a5
            sc.w 1 1 a5 a0 t6
            bnez L1 t6";
        my $get = "lr.w 1 1 a0 t0\nsrl t3 t0 t1\nand a4 t1 t1";
        my %new = (add => "add a1 t1 t2", sub => "sub a1 t1 t2", and => "and a1 t1 t2", or => "or a1 t1 t2",
            xor => "xor a1 t1 t2", nand => "and a1 t1 t2\nxori -1 t2 t2");
        push @f, asmfn("__atomic_exchange_$n", "$setup\nL1:\n$get\nmv a1 t2\n$put\nmv t1 a0\nret");
        for my $op (qw(add sub and or xor nand)) {
            push @f, asmfn("__atomic_fetch_${op}_$n", "$setup\nL1:\n$get\n$new{$op}\n$put\nmv t1 a0\nret");
            push @f, asmfn("__atomic_${op}_fetch_$n", "$setup\nL1:\n$get\n$new{$op}\n$put\nand a4 t2 a0\nret");
        }
        # compare-exchange: a1 the expected's address, a2 the desired
        push @f, asmfn("__atomic_compare_exchange_$n", "
            mv a1 a6
            mv a2 a1
            $setup
            $ld{$n} 0 a6 a3
            L1:
            $get
            bne rel:L2 a3 t1
            mv a1 t2
            $put
            li 1 a0
            ret
            L2:
            $st{$n} 0 t1 a6
            li 0 a0
            ret");
    }
    print write_txt(node('comment', node("libatomic's functions in riscv64's atomics (aq and rl), written by mkatomics.pl riscv64.")),
        node('atomics:', ttp_license(), @f));
}
