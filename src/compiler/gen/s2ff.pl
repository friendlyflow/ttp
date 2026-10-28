#!/usr/bin/env perl
# s2ff.pl — riscv64 asm as ff: the functions of a preprocessed .S file (the
# .s its build assembled, from src/glibc/mki.pl), each an asm function of
# ttpc's C layer, name: / asm / its instructions, which C reaches as it
# reaches a C function. One instruction per instruction, operands in ff's
# order (the encoding's, the destination last); nothing is lowered.
#
#   perl s2ff.pl [--page name] file.s file.dump > out.ff.txt
#   perl s2ff.pl --items file.s file.dump    its functions alone, for a page of
#                                            several files'
#   perl s2ff.pl --size file.s file.dump     the bytes of those instructions
#   perl s2ff.pl --header file.s ...        the license of each one's file, for
#                                            the top of their page
#   perl s2ff.pl --align file.s file.dump    x86_64: the first function's
#                                            alignment
#
# x86_64's (the dump of an elf64-x86-64 object) is s2ffx86.pm's.
#
# file.dump is what GNU as made of file.s, without relaxation, as objdump
# -d -M no-aliases prints it: where it chose a compressed instruction, the ff
# names that one (c.mv, c.add, ...), so ttpc emits the same bytes. GNU as
# picks those by size and by the distance of a branch; this takes its pick
# instead of redoing it.
#
#   label:          a function (a global label) or, inside one, a block
#                   label holding the instructions up to the next label
#   directives      .globl .weak .type .size .cfi_* .option .attribute .align .text
#                   give no bytes of their own here and are dropped (ttpc places a
#                   function on a 2-byte boundary, as RVC allows); any other
#                   stops the translation; X = Y (or .set X, Y) is an alias; in a section
#                   other than .text, .zero N is c2ff --zero's global (its
#                   other labels aliases of it), and an init array is left out
#   instructions    GNU's operands reversed (loads off base rd, stores off
#                   rs2 base, a branch target as rel label), the macros of
#                   macros/riscv64.ff.txt as they are; vector ones vm first
#                   (1, or 0 under v0.t), then their sources in GNU's order,
#                   the destination last; a vtype is its number, a constant
#                   expression its value; the F and D instructions gcc's code
#                   has (the rounding mode GNU as encoded, from the dump), a
#                   load from a symbol (op rd, sym[, rt]: auipc and the load)
#   read-only data  gcc's constants (.rodata, .srodata*: .word .dword .half .byte
#                   .zero after a label, .set X, Y + K) are asm functions of
#                   their words, each named by its label (.LC0 is "LC0 file");
#                   a .set's of a part of another is a copy of that part
#
# A host tool (core Perl only), not part of ttpc.
use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt);
use Header qw(license_nodes unit_label);

my $page = 'glibc asm';
my @files;
my $size;
my $items;
my $alignopt;             # --align (x86_64): the first function's alignment
my $header;
my (@zero, @then);               # --header file.s ...: the license of each one's file (Header.pm)
while (@ARGV) {
    my $a = shift @ARGV;
    if ($a eq '--page') { $page = shift @ARGV; next }
    if ($a eq '--size') { $size = 1; next }
    if ($a eq '--items') { $items = 1; next }
    if ($a eq '--header') { $header = 1; next }
    if ($a eq '--align') { $alignopt = 1; next }
    # (x86_64: c2ff --zero's objects; crtn's .s and dump, the end of crti's)
    if ($a eq '--zero') { push @zero, shift @ARGV; next }
    if ($a eq '--then') { @then = splice @ARGV, 0, 2; next }
    push @files, $a;
}
if ($header) { print write_txt(license_nodes(@files)); exit }
die "usage: s2ff.pl [--page name | --items | --size] file.s file.dump\n" unless @files == 2;
my ($src, $dump) = @files;
my $where = $src;
sub fail { die "s2ff: $where: @_\n" }
# the name of gcc's local data label as an asm function's (.LC0 of x.s: LC0 x)
my %dlabel;
sub dname { my ($l) = @_; $dlabel{$l} ? ($l =~ s/^\.//r) . ' ' . ($src =~ s{.*/}{}r =~ s/\.\w+$//r) : $l }

# x86_64 (the dump says so) has its own arm, s2ffx86.pm: one AT&T
# instruction is many encodings there, and it takes the form whose bytes
# are GNU's (--align: the alignment of the first function)
if (do { open my $h, "<", $dump or die "s2ff: cannot open $dump: $!\n"; local $/; <$h> } =~ /file format elf64-x86-64/) {
    require s2ffx86;
    my %opt = (zero => \@zero, @then ? (then => \@then) : ());
    if ($size || $alignopt) { print s2ffx86::run($size ? "size" : "align", $src, $dump, %opt), "\n"; exit }
    my $out = s2ffx86::run("ff", $src, $dump, %opt);
    print $items ? write_txt(@$out) : write_txt(node("$page:", license_nodes($src), @$out));
    exit;
}

# ---- what GNU as made: the size and the canonical form of each instruction
my @made;
open my $d, '<', $dump or die "s2ff: cannot open $dump: $!\n";
while (<$d>) {
    next unless /^\s*([0-9a-f]+):\t([0-9a-f ]+?)\s*\t(\S+)\s*(.*)$/;
    push @made, { bytes => length($2 =~ s/ //gr) / 2, op => $3, args => $4, enc => hex($2 =~ s/ //gr) };
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
# a number, or a constant expression of numbers, as GNU as takes it
sub isnum { $_[0] =~ /\d/ && $_[0] =~ /^[\s\da-fx()+\-*\/%<>&|~^]+$/i }
sub num {
    my ($v) = @_;
    isnum($v) or fail "not a number: $v";
    (my $e = $v) =~ s/\b0x([0-9a-f]+)\b/hex($1)/gie;
    $e =~ /^[\s\d()+\-*\/%<>&|~^]+$/ or fail "not a number: $v";
    my $n = eval "use integer; $e";
    defined $n or fail "not a number: $v";
    $n;
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
    return node(num($o)) if isnum($o);
    return node($o);
}
sub ins { my ($op, @a) = @_; node($op, map { ref $_ ? $_ : leaf($_) } @a) }
sub rel { node('rel', node($_[0])) }

my %rtype = map { $_ => 1 } qw(add sub and or xor sll srl sra slt sltu addw subw sllw srlw sraw
    mul mulh mulhu mulhsu div divu rem remu mulw divw divuw remw remuw);
my %itype = map { $_ => 1 } qw(addi andi ori xori slti sltiu slli srli srai addiw slliw srliw sraiw);
my %load = map { $_ => 1 } qw(lb lh lw ld lbu lhu lwu flw fld);
my %store = map { $_ => 1 } qw(sb sh sw sd fsw fsd);
my %btype = map { $_ => 1 } qw(beq bne blt bge bltu bgeu);
# the macros of macros/riscv64.ff.txt, which take GNU's operands reversed
my %macro = map { $_ => 1 } qw(mv li neg seqz j jr ret beqz bnez bltz bgez blez bgtz bgt ble bgtu bleu csrr);
my %vmask = map { $_ => 1 } qw(vmseq vmsne vmsltu vmsleu vmsgtu vadd vsub vand vor vxor vrgather
    vredmaxu vredminu vredsum vredor);

# a source instruction GNU as left at 4 bytes (its encoding $cur_enc)
my $cur_enc = 0;
sub full {
    my ($op, @o) = @_;
    return ins($op, $csr{$o[1]} // num($o[1]), $o[0]) if $op eq 'csrr';
    return ins($op) if $op =~ /^(ecall|ebreak|fence\.i)$/ && !@o;
    my $vm = 1;
    if (@o && $o[-1] eq 'v0.t') { pop @o; $vm = 0 }
    # (add, and, or, xor of an immediate: GNU as takes them for addi ...,
    # getcontext's add a2, a0, 40)
    return ins("${op}i", reverse @o) if $op =~ /^(add|and|or|xor)$/ && @o == 3 && $o[2] =~ /^-?(?:0x[0-9a-f]+|\d+)$/i;
    return ins($op, reverse @o) if $rtype{$op} || $itype{$op} || $macro{$op};
    # jal [rd,] target (rd ra where it is left out: setcontext's jal __setcontext)
    return ins('jal', rel($o[-1]), @o == 2 ? $o[0] : 'ra') if $op eq 'jal' && @o <= 2 && !isnum($o[-1]);
    # jalr rs (ra the link), jalr rd, off(rs), jalr rd, rs, off
    if ($op eq 'jalr') {
        return ins($op, 0, $o[0], 'ra') if @o == 1;
        return ins($op, mem($o[1]), $o[0]) if @o == 2;
        return ins($op, num($o[2]), $o[1], $o[0]);
    }
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
    # the float CSR, fcsr (3): frsr rd is csrrs rd, fcsr, zero, fssr [rd,] rs
    # csrrw rd (or zero), fcsr, rs (getcontext, setcontext)
    return ins('csrrs', 3, 'zero', $o[0]) if $op eq 'frsr' || $op eq 'frcsr';
    return ins('csrrw', 3, $o[-1], @o == 2 ? $o[0] : 'zero') if $op eq 'fssr' || $op eq 'fscsr';
    # F and D (gcc's code): ff's operands in field order, the rounding mode
    # GNU as encoded (the dump's bits 14:12)
    my $rm = ($cur_enc >> 12) & 7;
    return ins($op, $o[2], $o[1], $rm, $o[0]) if $op =~ /^f(add|sub|mul|div)\.[sd]$/;
    return ins($op, $o[3], $o[2], $o[1], $rm, $o[0]) if $op =~ /^f(n?madd|n?msub)\.[sd]$/;
    return ins($op, $o[1], $rm, $o[0]) if $op =~ /^f(sqrt\.[sd]|cvt\.\w+\.\w+)$/;
    return ins($op, $o[2], $o[1], $o[0]) if $op =~ /^f(sgnjn?|sgnjx|min|max|eq|lt|le)\.[sd]$/;
    return ins($op, $o[1], $o[0]) if $op =~ /^f(class\.[sd]|mv\.x\.[wd]|mv\.[wd]\.x)$/;
    return ins("fsgnj$1.$2", $o[1], $o[1], $o[0]) if $op =~ /^f(?|mv()|neg(n)|abs(x))\.([sd])$/;
    return ins("f$1.$2", $o[1], $o[2], $o[0]) if $op =~ /^f(?|gt(lt)|ge(le))\.([sd])$/;
    return ins('csrrs', 1, 'zero', $o[0]) if $op eq 'frflags';
    return ins('csrrw', 1, $o[-1], @o == 2 ? $o[0] : 'zero') if $op eq 'fsflags';
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
    if ($op =~ /^c\.(ld|lw|fld)$/) { my ($off, $base) = mem($o[1]); return ins($op, $off, $base, $o[0]) }
    if ($op =~ /^c\.(sd|sw|fsd)$/) { my ($off, $base) = mem($o[1]); return ins($op, $off, $base, $o[0]) }
    if ($op =~ /^c\.(ldsp|lwsp|sdsp|swsp|fldsp|fsdsp)$/) { my ($off) = mem($o[1]); return ins($op, $off, $o[0]) }
    if ($op eq 'c.lui') { my $v = num($o[1]) << 12; $v -= 2**32 if $v >= 2**31; return ins($op, $v, $o[0]) }
    return ins($op, num($o[2]), $o[0]) if $op eq 'c.addi4spn';
    return ins($op, num($o[1])) if $op eq 'c.addi16sp';
    return ins($op) if $op =~ /^c\.(nop|ebreak)$/;
    fail "no ff form for $op";
}

# an instruction of a li as GNU as made it, from its dump
sub canon {
    my ($m) = @_;
    return short($m) if $m->{bytes} == 2;
    # (without objdump's note of the value, addiw a0,a0,273 # 4111 <...>)
    my @o = split_ops($m->{args} =~ s/\s*#.*$//r);
    if ($m->{op} eq 'lui') { my $v = num($o[1]) << 12; $v -= 2**32 if $v >= 2**31; return ins('lui', $v, $o[0]) }
    return ins($m->{op}, num($o[2]), $o[1], $o[0]) if $m->{op} =~ /^(addi|addiw)$/;
    fail "no ff form for $m->{op} in a li";
}

# ---- the source --------------------------------------------------------------
my (@fns, $fn, $block, $file, $line);
($file, $line) = ($src =~ s{.*/}{}r, 0);     # (a .s of gcc's has no line marks)
# (the name of its tree, glibc-2.44, or gcc-16.2.0 for libgcc's, whose
# files are named from gcc's folder)
my $label = unit_label($src);
my $n = 0;
my $pos = 0;        # the bytes GNU as made so far
my $ends = 1;       # the last instruction does not run on (a return, a jump)
my %tls;            # a function's thread-locals, as la.tls.ie reads them
my %got;            # the addresses a function's pic la reads, its GOT entries
my %numeric;        # how many times each numeric label (1:) has come so far
my $other;          # another section than .text, while in one
my @pending;        # its labels so far, before the bytes they name
my %datadef;        # the labels of data that is there (zero objects)
my (@dobjs, $dobj, @dset);  # gcc's read-only data: its objects, the one being filled, its .set names
# GNU as's next instruction, its bytes counted; whether it ends a function
sub take {
    my $m = $made[$n++] or fail "GNU as made fewer instructions than $src has";
    $pos += $m->{bytes};
    $ends = $m->{op} =~ /^c\.(jr|j)$/ || ($m->{op} =~ /^(jal|jalr)$/ && $m->{args} =~ /^zero\b/) ? 1 : 0;
    $m;
}
# the end of a function: the words its la.tls.ie read (each thread local's
# offset from tp) and its pic la's (addresses)
sub finish {
    return unless $fn && (%tls || %got);
    push @{ $fn->{children} }, node('align', node(8)), (map { node(".Ltls $_:", node('dword', node('tprel', node($_)))) } sort keys %tls),
        map { node(".Lgot $_:", node('dword', node($_))) } sort keys %got;
    %tls = %got = ();
}
# gcc's read-only data labels, known before the code that names them
{
    open my $p, '<', $src or die "s2ff: cannot open $src: $!\n";
    my $sec = '.text';
    while (<$p>) {
        $sec = $2 // ".$1" if /^\s*\.(data|bss|text|section\s+([^,\s]+))/;
        $sec = '.text' if /^\s*\.text\b/;
        next unless $sec =~ /^\.s?rodata/;
        $dlabel{$1} = 1 if /^([.\w]+):/ || /^\s*\.set\s+([.\w]+)\s*,/;
    }
}
open my $s, '<', $src or die "s2ff: cannot open $src: $!\n";
while (my $l = <$s>) {
    chomp $l;
    if ($l =~ /^# (\d+) "([^"]*)"/) { ($line, $file) = ($1 - 1, $2 =~ s{^(\.\./)+}{}r =~ s{^gcc-[\d.]+/}{}r); next }
    $line++;
    # a # starts a comment (.S's own, kept by cpp: dl-trampoline's), outside a text
    $l =~ s/\s*#.*$// unless $l =~ /"/;
    $where = "$src ($file:$line)";
    for my $st (split /;/, $l) {
        $st =~ s/^\s+|\s+$//g;
        next if $st eq '';
        # another section than .text: data. A zeroed object (.zero N, as
        # dl-rseq-symbols.S's __rseq_size) is a global of the type C declares,
        # zero, which c2ff --zero makes (its own name, the first label); its
        # other labels are aliases of it here; a label with no bytes after it (start.S's
        # __data_start) has no place. An init array (start.S's .preinit_array,
        # load_gp, which _start has run) is left out: a program ttpc makes
        # has none (their bounds are weak, 0). Any other bytes stop the
        # translation.
        if ($st =~ /^\.(data|bss|section\s+([^,\s]+)(,.*)?)$/) {
            my $sec = $2 // ".$1";
            if ($sec eq '.text') { $other = undef; next }
            $other = $sec;
            @pending = ();
            undef $dobj;
            warn "s2ff: $where: $sec left out\n" if $sec =~ /^\.(pre)?init_array$|^\.fini_array$/;
            next;
        }
        if ($st eq '.text') { $other = undef; next }
        if (defined $other) {
            next if $st =~ /^\.(globl|global|weak|type|size|hidden|align|p2align|balign|ident|file)\b/;
            if ($st =~ /^([.\w]+):$/) { push @pending, $1; undef $dobj; next }
            # (an alias of a label with no bytes, start.S's data_start, has
            # nothing to name)
            if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/) { push @fns, node("$1:", node('alias'), node($2)) if $datadef{$2}; next }
            next if $other =~ /^\.(pre)?init_array$|^\.fini_array$/ && $st =~ /^\.dc\.a\s+[.\w]+$/;
            # gcc's read-only data: an object per label, of its bytes
            if ($other =~ /^\.s?rodata/) {
                if ($st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)(?:\s*\+\s*(\d+))?$/) { push @dset, [$1, $2, $3 // 0]; next }
                if ($st =~ /^\.(byte|half|2byte|word|4byte|dword|8byte|zero)\s+(-?\w+)$/) {
                    my ($k, $v) = ($1, $2);
                    if (@pending) {
                        $dobj = { name => shift @pending, bytes => [], sec => $other };
                        push @dobjs, $dobj;
                        push @dset, map { [$_, $dobj->{name}, 0] } @pending;
                        @pending = ();
                    }
                    fail "data without a label: $st" unless $dobj;
                    my $n = { byte => 1, half => 2, '2byte' => 2, word => 4, '4byte' => 4, dword => 8, '8byte' => 8 }->{$k};
                    if ($k eq 'zero') { push @{ $dobj->{bytes} }, (0) x num($v) }
                    else { my $x = num($v); push @{ $dobj->{bytes} }, map { ($x >> (8 * $_)) & 255 } 0 .. $n - 1 }
                    next;
                }
            }
            if ($st =~ /^\.(zero|space)\s+(\d+)$/ && @pending) {
                my ($first, @more) = @pending;
                $datadef{$_} = 1 for @pending;
                push @fns, map { node("$_:", node('alias'), node($first)) } @more;
                warn "s2ff: $where: $first is zero, c2ff --zero $first makes it\n";
                @pending = ();
                next;
            }
            fail "bytes in $other: $st";
        }
        while ($st =~ s/^([.\w]+):\s*//) {
            my $name = $1;
            # GNU's numeric labels (1:, 1f the next, 1b the one before): each a
            # label of its own, .L1 1, .L1 2, ...
            $name = ".L$name " . ++$numeric{$name} if $name =~ /^\d+$/;
            if ($name =~ /^\.L/) {
                fail "label $name outside a function" unless $fn;
                $block = node("$name:");
                push @{$fn->{children}}, $block;
            } elsif ($fn && !$ends) {
                # the function before runs on into this one: it holds it, as
                # a label, so that they are placed together; asm first (which
                # in asm is nothing) makes it an entry C may call: ttpc places
                # the function that holds it
                $block = node("$name:", node('asm'), node('comment', node("$label $file:$line")));
                push @{$fn->{children}}, $block;
            } else {
                finish();
                $fn = node("$name:", node('asm'), node('comment', node("$label $file:$line")));
                push @fns, $fn;
                undef $block;
                $ends = 0;      # none of its own yet: it runs on into what follows
            }
        }
        next if $st eq '';
        # X = Y (a weak_alias), or .set X, Y (vfork's __vfork): another name for Y
        if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/ || $st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)$/) { push @fns, node("$1:", node('alias'), node($2)); next }
        my ($op, $rest) = $st =~ /^(\S+)\s*(.*)$/;
        if ($op =~ /^\./) {
            # the nops GNU as put in to align a function, kept where it runs
            # on into it
            if ($op =~ /^\.(p2)?align$/ && $fn) {
                my $a = 2**num((split_ops($rest))[0]);
                while ($pos % $a && $made[$n] && $made[$n]{op} =~ /^(c\.addi|c\.nop|addi)$/ && $made[$n]{args} =~ /^zero,(zero,)?0$/) {
                    my $m = take();
                    push @{($block // $fn)->{children}}, $m->{bytes} == 2 ? node('c.nop') : ins('addi', 0, 'zero', 'zero');
                    $ends = 0;
                }
                next;
            }
            next if $op =~ /^\.(globl|global|weak|hidden|type|size|align|p2align|text|attribute|cfi_\w+|file|ident)$/;
            next if $op eq '.option' && $rest =~ /^(push|pop|arch\b.*|norelax|relax|pic|nopic|rvc|norvc)$/;
            fail "a directive with no ff form: $st";
        }
        fail "an instruction outside a function: $st" unless $fn;
        $op = { scall => 'ecall', sbreak => 'ebreak', 'fmv.s.x' => 'fmv.w.x', 'fmv.x.s' => 'fmv.x.w' }->{$op} // $op;    # GNU's old names
        # (a call through the PLT, name@plt, is a call of name: a static
        # program has no PLT)
        my @o = map { /^(\d+)([fb])$/ ? ".L$1 " . (($numeric{$1} // 0) + ($2 eq 'f' ? 1 : 0)) : s/\@plt$//r } split_ops($rest);
        my $into = ($block // $fn)->{children};
        # li is what GNU as made of it for its value (addi, or lui and addiw)
        if ($op eq 'li') {
            my $v = num($o[1]);
            my $count = $v >= -2048 && $v < 2048 ? 1 : ($v & 0xfff) == 0 ? 1 : 2;
            fail "li of $v, wider than 32 bits" unless $v >= -2**31 && $v < 2**31;
            if ($count == 1 && $made[$n]{op} =~ /^(addi|c\.li)$/) {
                my $m = take();
                push @$into, $m->{bytes} == 2 ? short($m) : full($op, @o);
            } else {
                push @$into, canon(take()) for 1 .. $count;
            }
            next;
        }
        # la.tls.ie: the thread-local's offset from tp, from a word the
        # function carries (tprel: its offset in the TLS image, as ld puts
        # it in the GOT)
        if ($op eq 'la.tls.ie') {
            take(); take();
            my $w = ".Ltls $o[1]";
            $tls{ $o[1] } = 1;
            push @$into, ins('auipc', node('pcrel_hi', node($w)), $o[0]), ins('ld', node('pcrel_lo', node($w)), $o[0], $o[0]);
            next;
        }
        # la under .option pic: GNU as loads the address from the GOT (auipc,
        # ld); here from a word the function carries, as for la.tls.ie
        if ($op eq 'la' && $made[$n] && $made[$n + 1] && $made[$n]{op} eq 'auipc' && $made[$n + 1]{op} eq 'ld') {
            take(); take();
            my $w = ".Lgot $o[1]";
            $got{ $o[1] } = 1;
            push @$into, ins('auipc', node('pcrel_hi', node($w)), $o[0]), ins('ld', node('pcrel_lo', node($w)), $o[0], $o[0]);
            next;
        }
        # la (and lla, which is la without pic), auipc and addi: the macro's
        if ($op eq 'la' || $op eq 'lla') { take(); take(); push @$into, ins('la', dname($o[1]), $o[0]); next }
        # a load from a symbol (gcc's -mno-explicit-relocs: fld fa5, .LC0, a5;
        # ld a1, .LC1): auipc, then the load from its low part
        if ($load{$op} && @o >= 2 && $o[1] !~ /\(/ && !isnum($o[1])) {
            take(); take();
            my ($w, $rt) = (dname($o[1]), $o[2] // $o[0]);
            push @$into, ins('auipc', node('pcrel_hi', node($w)), $rt), ins($op, node('pcrel_lo', node($w)), $rt, $o[0]);
            next;
        }
        my $m = take();
        # a call or a tail is two instructions, the macro's
        if ($op =~ /^(call|tail)$/) { take(); push @$into, node($op, node($o[-1])); next }
        my $i;
        if ($m->{bytes} == 2) {
            my ($target) = grep { /^\.L/ } @o;
            # (or a function's own name: setjmp's j __sigsetjmp)
            $target //= $o[-1] if $m->{op} =~ /^c\.(j|beqz|bnez)$/;
            $i = short($m, $target);
        } else {
            $cur_enc = $m->{enc};
            $i = full($op, @o);
        }
        push @$into, $i;
    }
}
close $s;
finish();
# gcc's read-only data: an asm function of its words (bytes for a rest),
# a .set name a copy of the part it names
{
    my %by = map { $_->{name} => $_ } @dobjs;
    for (@dset) {
        my ($x, $y, $k) = @$_;
        my $o = $by{$y} or fail "a .set of $y, which is no data";
        my @b = @{ $o->{bytes} };
        fail ".set $x: past $y" if $k > @b;
        push @dobjs, $by{$x} = { name => $x, bytes => [@b[$k .. $#b]], sec => $o->{sec} };
    }
    for my $o (@dobjs) {
        my @b = @{ $o->{bytes} };
        my @w;
        while (@b >= 4) { my @q = splice @b, 0, 4; push @w, node('word', node($q[0] | $q[1] << 8 | $q[2] << 16 | $q[3] << 24)) }
        push @w, map { node('byte', node($_)) } @b;
        push @fns, node(dname($o->{name}) . ':', node('asm'), node('comment', node("gcc's $o->{sec}")), @w);
    }
}
# what is left is the padding GNU as puts at the end of the section
pop @made while @made > $n && $made[-1]{op} =~ /^c\.(addi|nop)$|^addi$/ && $made[-1]{args} =~ /^zero,(zero,)?0$/;
fail "GNU as made " . scalar(@made) . " instructions, $src has $n" unless $n == @made;
if ($size) { my $b = 0; $b += $_->{bytes} for @made; print "$b\n"; exit }
# A function that jumps to a block label of the function after it (setjmp.S's
# _setjmp: j __sigsetjmp, which runs on from setjmp): the two are one asm
# function, the second's name a block label in it, as a block label is
# known only inside its function.
{
    my $blocks = sub { my ($f) = @_; map { $_->{content} =~ s/:$//r } grep { @{ $_->{children} } && $_->{content} =~ /:$/ && $_->{children}[0]{content} =~ /^(asm|comment)$/ } @{ $f->{children} } };
    my $targets = sub { my ($f) = @_; my @t; my $w; $w = sub { for (@{ $_[0]{children} }) { push @t, $_->{children}[0]{content} if $_->{content} eq 'rel'; $w->($_) } }; $w->($f); @t };
    for (my $i = 0; $i + 1 < @fns; $i++) {
        my ($f, $g) = @fns[$i, $i + 1];
        next unless @{ $f->{children} } && $f->{children}[0]{content} eq 'asm' && @{ $g->{children} } && $g->{children}[0]{content} eq 'asm';
        my %in_g = map { $_ => 1 } $blocks->($g);
        next unless grep { $in_g{$_} } $targets->($f);
        my (undef, @rest) = @{ $g->{children} };
        # g's own instructions as a block of its name, then its blocks
        my (@own, @later);
        for (@rest) { if (@later || (@{ $_->{children} } && $_->{content} =~ /:$/ && $_ != $rest[0])) { push @later, $_ } else { push @own, $_ } }
        push @{ $f->{children} }, node($g->{content}, @own), @later;
        splice @fns, $i + 1, 1;
        $i--;
    }
}
print $items ? write_txt(@fns) : write_txt(node("$page:", license_nodes($src), @fns));
