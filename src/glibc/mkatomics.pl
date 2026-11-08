#!/usr/bin/env perl
# mkatomics.pl — writes atomics.ff.txt: libatomic's functions, which gcc
# calls for an atomic builtin it does not expand (__atomic_load_4, ...),
# for 1, 2, 4 and 8 bytes, in ttpc's C layer. c2ff turns glibc's atomic
# builtins into calls of them. A ttpc program has one thread, so plain loads
# and stores are exact; real atomics come with threads.
#
#   perl mkatomics.pl > atomics.ff.txt
#   perl mkatomics.pl riscv64 > atomics-riscv64.ff.txt
#   perl mkatomics.pl x86_64 > atomics-x86_64.ff.txt
#
# With a target, real atomics in its asm, as gcc makes them (riscv64: amo
# for 4 and 8 bytes, lr/sc for nand and compare-exchange, and on the
# aligned word for 1 and 2 bytes, aq and rl on each, fences around plain
# loads and stores): glibc's threads and processes that share memory (a
# process-shared barrier: tst-arc4random-fork lost updates of its out with
# the plain ones). A result of fewer bits than a word is zero-extended.
# (aarch64: ldaxr and stlxr around each read-modify-write, ldar and stlr for
# plain loads and stores, as gcc's without LSE; each CPU has them.)
# (arm: ldrex and strex and their sizes around each read-modify-write, dmb ish
# before and after, plain loads and stores of up to 4 bytes between dmb ish, 8
# bytes through ldrexd and strexd, as gcc's for armv7-a. An 8-byte value is in a
# pair of registers, r2 and r3 after the pointer.)
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
if ($target eq 'x86_64') { x64(); exit 0 }
if ($target eq 'aarch64') { a64(); exit 0 }
if ($target eq 'arm') { arm(); exit 0 }
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
        my @k = map { /^(a?rel):(.*)$/ ? node($1, node($2)) : node($_) } @a;
        my $i = node($op, @k);
        if ($lab) { push @{ $lab->{children} }, $i } else { push @top, $i }
    }
    node("$name:", node('asm'), @top);
}
# ---- x86_64 -------------------------------------------------------------
# As gcc makes them, seq_cst whatever the order: a load is a mov, a store an
# xchg, exchange an xchg, compare-exchange lock cmpxchg, add and sub lock xadd,
# the rest a loop of lock cmpxchg. p in rdi, the value in rsi, compare-exchange's
# e in rsi and d in rdx (SysV); a result of fewer bits than a word zero-extended.
sub x64 {
    my @f;
    my %s = (1 => 'b', 2 => 'w', 4 => 'l', 8 => 'q');
    my %ax = (1 => 'al', 2 => 'ax', 4 => 'eax', 8 => 'rax');
    my %cx = (1 => 'cl', 2 => 'cx', 4 => 'ecx', 8 => 'rcx');
    my %dx = (1 => 'dl', 2 => 'dx', 4 => 'edx', 8 => 'rdx');
    my %si = (1 => 'sil', 2 => 'si', 4 => 'esi', 8 => 'rsi');
    my %lmem = (1 => 'movzbl.m', 2 => 'movzwl.m', 4 => 'movl.m', 8 => 'movq.m');
    my %lreg = (1 => 'movzbl', 2 => 'movzwl', 4 => 'movl', 8 => 'movq');
    for my $n (1, 2, 4, 8) {
        my $s = $s{$n};
        # the register of the result: eax for fewer than 8 bytes, zero-extended
        my $r = $n == 8 ? 'rax' : 'eax';
        my $load = "$lmem{$n} 0 rdi $r";
        my $zxsi = "$lreg{$n} $si{$n} $r";
        my $zxcx = "$lreg{$n} $cx{$n} $r";
        push @f, asmfn("__atomic_load_$n", "$load\nret");
        push @f, asmfn("__atomic_store_$n", "xchg$s.mr $si{$n} 0 rdi\nret");
        push @f, asmfn("__atomic_exchange_$n", "xchg$s.mr $si{$n} 0 rdi\n$zxsi\nret");
        my $lmov = "$lmem{$n} 0 rsi $r";
        push @f, asmfn("__atomic_compare_exchange_$n", "
            $lmov
            lock
            cmpxchg$s.mr $dx{$n} 0 rdi
            jne.8 L1
            movl.i 1 eax
            ret
            L1:
            mov$s.mr $ax{$n} 0 rsi
            movl.i 0 eax
            ret");
        for my $op (qw(add sub)) {
            my $neg = $op eq 'sub' ? "negq rsi\n" : '';
            push @f, asmfn("__atomic_fetch_${op}_$n", "${neg}lock\nxadd$s.mr $si{$n} 0 rdi\n$zxsi\nret");
            push @f, asmfn("__atomic_${op}_fetch_$n", "${neg}movq rsi rcx\nlock\nxadd$s.mr $si{$n} 0 rdi\naddq rsi rcx\n$zxcx\nret");
        }
        for my $op (qw(and or xor nand)) {
            my $x = $op eq 'nand' ? "andq rsi rcx\nnotq rcx" : "${op}q rsi rcx";
            my $loop = "
                $load
                L1:
                movq rax rcx
                $x
                lock
                cmpxchg$s.mr $cx{$n} 0 rdi
                jne.8 L1";
            # (fetch: what cmpxchg found, in al ... rax, which it left there)
            push @f, asmfn("__atomic_fetch_${op}_$n", "$loop\n$lreg{$n} $ax{$n} $r\nret");
            push @f, asmfn("__atomic_${op}_fetch_$n", "$loop\n$zxcx\nret");
        }
    }
    print write_txt(node('comment', node("libatomic's functions in x86_64's atomics (lock cmpxchg, lock xadd, xchg), written by mkatomics.pl.")),
        node('atomics:', ttp_license(), @f));
}
sub a64 {
    my @f;
    # the size's suffix, its register for the value, the load and store of a
    # plain memory operand, the zero extension of a result (ubfm immr imms)
    my %sf = (1 => 'b', 2 => 'h', 4 => 'w', 8 => '');
    my %ls = (1 => ['ldrb', 'strb'], 2 => ['ldrh', 'strh'], 4 => ['ldrw', 'strw'], 8 => ['ldr', 'str']);
    my %zx = (1 => 7, 2 => 15, 4 => 31);
    # (in ttpc's order, the destination last: op rm rn rd)
    my %new = (add => "add x1 x10 x11", sub => "sub x1 x10 x11", and => "and x1 x10 x11", or => "orr x1 x10 x11",
        xor => "eor x1 x10 x11", nand => "and x1 x10 x11\norn x11 xzr x11");
    for my $n (1, 2, 4, 8) {
        my $s = $sf{$n};
        my $r = $n == 8 ? 'x' : 'w';
        my ($ld, $st) = @{ $ls{$n} };
        my $rmw = sub { my ($body) = @_; "L1:\nldaxr$s x0 ${r}10\n$body\nstlxr$s w12 x0 ${r}11\ncbnzw rel:L1 w12" };
        my $res11 = $n == 8 ? "orr x11 xzr x0" : "ubfm 0 $zx{$n} x11 x0";
        push @f, asmfn("__atomic_load_$n", "ldar$s x0 ${r}0\nret");
        push @f, asmfn("__atomic_store_$n", "stlr$s x0 ${r}1\nret");
        push @f, asmfn("__atomic_exchange_$n", "L1:\nldaxr$s x0 ${r}10\nstlxr$s w12 x0 ${r}1\ncbnzw rel:L1 w12\norr x10 xzr x0\nret");
        # compare-exchange: x1 the expected's address, x2 the desired
        push @f, asmfn("__atomic_compare_exchange_$n", "
            $ld 0 x1 ${r}9
            L1:
            ldaxr$s x0 ${r}10
            subs x9 x10 xzr
            b.ne rel:L2
            stlxr$s w12 x0 ${r}2
            cbnzw rel:L1 w12
            movz 0 1 x0
            ret
            L2:
            clrex
            $st 0 x1 ${r}10
            movz 0 0 x0
            ret");
        for my $op (qw(add sub and or xor nand)) {
            push @f, asmfn("__atomic_fetch_${op}_$n", $rmw->($new{$op}) . "\norr x10 xzr x0\nret");
            push @f, asmfn("__atomic_${op}_fetch_$n", $rmw->($new{$op}) . "\n$res11\nret");
        }
    }
    print write_txt(node('comment', node("libatomic's functions in aarch64's atomics (ldaxr and stlxr, ldar and stlr), written by mkatomics.pl aarch64.")),
        node('atomics:', ttp_license(), @f));
}
sub arm {
    my @f;
    # dmb ish; the loads and stores of each size; the zero extension of a
    # result of fewer bits than a word
    my $dmb = "dmb 11";
    my %ex = (1 => 'b', 2 => 'h', 4 => '');
    my %ls = (1 => ['ldrb', 'strb'], 2 => ['ldrh', 'strh'], 4 => ['ldr', 'str']);
    my %zx = (1 => "uxtb 0 r3 r3\n", 2 => "uxth 0 r3 r3\n", 4 => '');
    # (in ttpc's order, the destination last)
    my %new = (add => "add r1 r2 r3", sub => "sub r1 r2 r3", and => "and r1 r2 r3", or => "orr r1 r2 r3",
        xor => "eor r1 r2 r3", nand => "and r1 r2 r3\nmvn r3 r3");
    for my $n (1, 2, 4) {
        my $x = $ex{$n};
        my ($ld, $st) = @{ $ls{$n} };
        push @f, asmfn("__atomic_load_$n", "$dmb\n$ld 0 r0 r0\n$dmb\nret");
        push @f, asmfn("__atomic_store_$n", "$dmb\n$st 0 r0 r1\n$dmb\nret");
        # r0 the pointer, r1 the value, r2 the old, r3 the new, r12 strex's status
        my $rmw = sub { my ($body) = @_; "$dmb\nL1:\nldrex$x r0 r2\n$body\nstrex$x r0 r3 r12\ncmpi 0 0 r12\nbne arel:L1\n$dmb" };
        push @f, asmfn("__atomic_exchange_$n", $rmw->("mov r1 r3") . "\nmov r2 r0\nret");
        # compare-exchange: r1 the expected's address, r2 the desired, r3 the
        # expected, r12 the old (once equal to the expected, strex's status)
        push @f, asmfn("__atomic_compare_exchange_$n", "
            $ld 0 r1 r3
            $dmb
            L1:
            ldrex$x r0 r12
            cmp r3 r12
            bne arel:L2
            strex$x r0 r2 r12
            cmpi 0 0 r12
            bne arel:L1
            $dmb
            movi 0 1 r0
            ret
            L2:
            clrex
            $dmb
            $st 0 r1 r12
            movi 0 0 r0
            ret");
        for my $op (qw(add sub and or xor nand)) {
            push @f, asmfn("__atomic_fetch_${op}_$n", $rmw->($new{$op}) . "\nmov r2 r0\nret");
            push @f, asmfn("__atomic_${op}_fetch_$n", $rmw->($new{$op}) . "\n$zx{$n}mov r3 r0\nret");
        }
    }
    # 8 bytes: r0 the pointer, r2 and r3 the value (AAPCS: an even pair), the
    # result in r0 and r1. A load is ldrexd alone, one copy on armv7-a.
    push @f, asmfn("__ff_atomic_load_8", "$dmb\nldrexd r0 r0\nclrex\n$dmb\nret");
    my $xchg = "mov r0 r12\n$dmb\nL1:\nldrexd r12 r0\nstrexd r12 r2 r1\ncmpi 0 0 r1\nbne arel:L1\n$dmb";
    push @f, asmfn("__ff_atomic_store_8", "$xchg\nret");
    # (the old in r4 and r5, strexd's status in r0, which ends as the result)
    push @f, asmfn("__ff_atomic_exchange_8", "
        push 48
        mov r0 r12
        $dmb
        L1:
        ldrexd r12 r4
        strexd r12 r2 r0
        cmpi 0 0 r0
        bne arel:L1
        $dmb
        mov r4 r0
        mov r5 r1
        pop 48
        ret");
    # r12 the pointer, r0 and r1 the old, r4 and r5 the new, r6 strexd's status
    my %new8 = (add => "adds r2 r0 r4\nadc r3 r1 r5", sub => "subs r2 r0 r4\nsbc r3 r1 r5",
        and => "and r2 r0 r4\nand r3 r1 r5", or => "orr r2 r0 r4\norr r3 r1 r5",
        xor => "eor r2 r0 r4\neor r3 r1 r5", nand => "and r2 r0 r4\nand r3 r1 r5\nmvn r4 r4\nmvn r5 r5");
    for my $op (qw(add sub and or xor nand)) {
        my $body = "push 112\nmov r0 r12\n$dmb\nL1:\nldrexd r12 r0\n$new8{$op}\nstrexd r12 r4 r6\ncmpi 0 0 r6\nbne arel:L1\n$dmb\n";
        push @f, asmfn("__ff_atomic_fetch_${op}_8", $body . "pop 112\nret");
        push @f, asmfn("__ff_atomic_${op}_fetch_8", $body . "mov r4 r0\nmov r5 r1\npop 112\nret");
    }
    # compare-exchange: r1 the expected's address, r2 and r3 the desired, r6
    # and r7 the expected, r4 and r5 the old, r12 strexd's status
    push @f, asmfn("__ff_atomic_compare_exchange_8", "
        push 240
        ldrd 0 r1 r6
        $dmb
        L1:
        ldrexd r0 r4
        cmp r6 r4
        cmp.if cond.eq r7 r5
        bne arel:L2
        strexd r0 r2 r12
        cmpi 0 0 r12
        bne arel:L1
        $dmb
        movi 0 1 r0
        pop 240
        ret
        L2:
        clrex
        $dmb
        strd 0 r1 r4
        movi 0 0 r0
        pop 240
        ret");
    # The C types of the 8-byte ones: an asm function's value is a word, and an
    # int given for a u64 is no pair. libatomic's names are C functions of
    # these types, which call them through pointers of their function types.
    my @pv = (param('p', 'u64', '* pointer'));
    push @f, node('__ff_atomic8_load:', leaf('function', 'u64'), @pv);
    push @f, node('__ff_atomic8_store:', leaf('function', 'void'), @pv, param('v', 'u64'));
    push @f, node('__ff_atomic8_op:', leaf('function', 'u64'), @pv, param('v', 'u64'));
    push @f, node('__ff_atomic8_cas:', leaf('function', 'int'), @pv, param('e', 'u64', '* pointer'), param('d', 'u64'));
    my $wrap = sub {
        my ($name, $type, $ret, $params, @args) = @_;
        my @call = (node('f', map { node($_) } @args));
        push @f, node("__atomic_$name:", leaf($ret), @$params,
            node('f:', leaf("__ff_atomic8_$type", '* pointer', "__ff_atomic_$name", '& address')),
            $ret eq 'void' ? @call : node('return', @call));
    };
    $wrap->('load_8', 'load', 'u64', [@pv, param('order', 'int')], 'p');
    $wrap->('store_8', 'store', 'void', [@pv, param('v', 'u64'), param('order', 'int')], 'p', 'v');
    $wrap->('exchange_8', 'op', 'u64', [@pv, param('v', 'u64'), param('order', 'int')], 'p', 'v');
    $wrap->('compare_exchange_8', 'cas', 'int', [@pv, param('e', 'u64', '* pointer'), param('d', 'u64'), param('success', 'int'), param('failure', 'int')], 'p', 'e', 'd');
    for my $op (qw(add sub and or xor nand)) {
        $wrap->("${_}_8", 'op', 'u64', [@pv, param('v', 'u64'), param('order', 'int')], 'p', 'v') for "fetch_$op", "${op}_fetch";
    }
    print write_txt(node('comment', node("libatomic's functions in arm's atomics (ldrex and strex, dmb ish), written by mkatomics.pl arm.")),
        node('atomics:', ttp_license(), @f));
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
