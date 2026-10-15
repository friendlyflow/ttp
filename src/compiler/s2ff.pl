#!/usr/bin/env perl
# s2ff.pl — translates ttpc.s (GNU as, the subset it uses) into ff: its
# constants page and its program page, in the text form (see FF.pm).
#
#   perl s2ff.pl ttpc.s ttpc.consts.ff.txt ttpc.ff.txt
#
# A host tool for the bootstrap: once ttpc.ff assembles itself it is the
# source, and this is no longer needed. The translation is mechanical, so
# that ttpc assembling the result gives the same bytes as GNU as and ld -T
# ff.ld give for ttpc.s:
#
#   .equ X, expr     X: with body addi <value> zero a0; X, . - Y: size Y
#   label:           a placed function holding the code up to the next
#                    label; a numeric label (1:) is nested in the global
#                    label before it, as L1 (L1_2, ... when 1: comes again)
#   sections         .text, .rodata, .data, .bss in that order, each from a
#                    multiple of 8, between the ELF header and file_end:,
#                    bss and mem_end:
#   .ascii .byte .half .word .dword .balign .skip
#                    ascii, byte, half, word, dword, align, reserve
#   instructions     the operands in ff's order (the reverse of GNU's, the
#                    stores aside), a branch target as rel <label>, an
#                    expression as its value; the pseudo-instructions are
#                    the macros of macros.ff.txt

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node write_txt);

die "usage: s2ff.pl <file.s> <consts.ff.txt> <prog.ff.txt>\n" unless @ARGV == 3;
my ($src, $consts_out, $prog_out) = @ARGV;
open my $in, "<", $src or die "s2ff: cannot open $src: $!\n";
my @lines = <$in>;
my $where;
sub fail { die "s2ff: $where: @_\n" }

# ---------------------------------------------------------------------------
# Pass 1: statements, labels, constants
# ---------------------------------------------------------------------------

my (%equ, @consts);                     # constant values; their nodes
my %sections = map { $_ => [] } qw(.text .rodata .data .bss);
my %offset = map { $_ => 0 } keys %sections;
my %label_at;                           # global label -> [section, offset]
my $section = ".text";

sub value {
    my ($e) = @_;
    $e =~ s/^\s+|\s+$//g;
    fail "no value in '$e'" if $e eq "";
    (my $x = $e) =~ s/\b([A-Za-z_]\w*)\b/exists $equ{$1} ? "($equ{$1})" : fail "unknown constant $1"/ge;
    fail "bad expression '$e'" if $x =~ /[^\s\d()+\-*\/<>&|~^xa-fA-F]/;
    my $v = eval "use integer; $x";
    fail "bad expression '$e'" unless defined $v;
    $v;
}

sub unquote {
    my ($s) = @_;
    $s =~ /^"((?:[^"\\]|\\.)*)"$/ or fail "bad string $s";
    my $body = $1;
    my %esc = (n => "\n", t => "\t", 0 => "\0", "\\" => "\\", '"' => '"');
    $body =~ s/\\(.)/exists $esc{$1} ? $esc{$1} : fail "bad escape \\$1"/ge;
    $body;
}

# Operands, split at the commas outside parentheses and quotes.
sub operands {
    my ($s) = @_;
    my @ops;
    my ($cur, $depth, $quote) = ("", 0, 0);
    for my $c (split //, $s) {
        if ($quote) { $quote = 0 if $c eq '"' }
        elsif ($c eq '"') { $quote = 1 }
        elsif ($c eq "(") { $depth++ }
        elsif ($c eq ")") { $depth-- }
        elsif ($c eq "," && !$depth) { push @ops, $cur; $cur = ""; next }
        $cur .= $c;
    }
    push @ops, $cur if $cur =~ /\S/;
    map { s/^\s+|\s+$//gr } @ops;
}

my %size = (".byte" => 1, ".half" => 2, ".word" => 4, ".dword" => 8);
my $line_no = 0;
for (@lines) {
    $line_no++;
    $where = "$src:$line_no";
    my $text = $_;
    $text =~ s/("(?:[^"\\]|\\.)*")|#.*/$1 \/\/ ""/ge;    # comments, not in strings
    $text =~ s/\s+$//;
    while ($text =~ s/^\s*([A-Za-z_]\w*|\d+):\s*//) {
        my $name = $1;
        push @{ $sections{$section} }, { label => $name, where => $where };
        $label_at{$name} = [$section, $offset{$section}] unless $name =~ /^\d/;
    }
    next if $text eq "";
    $text =~ /^\s*(\S+)\s*(.*)$/;
    my ($op, $rest) = ($1, $2);
    if ($op eq ".equ") {
        my ($name, $e) = $rest =~ /^(\w+)\s*,\s*(.*)$/ or fail "bad .equ";
        if ($e =~ /^\.\s*-\s*(\w+)$/) {
            my $at = $label_at{$1} or fail "unknown label $1";
            fail "$1 is in another section" if $at->[0] ne $section;
            $equ{$name} = $offset{$section} - $at->[1];
            push @consts, node("$name:", node("size", node($1)));
        } else {
            $equ{$name} = value($e);
            push @consts, node("$name:", node("addi", node($equ{$name}), node("zero"), node("a0")));
        }
        next;
    }
    if ($op eq ".section") {
        fail "unknown section $rest" unless $sections{$rest};
        $section = $rest;
        next;
    }
    next if $op eq ".globl";
    my $stmt = { op => $op, ops => [operands($rest)], where => $where };
    push @{ $sections{$section} }, $stmt;
    if ($op eq ".ascii") { $offset{$section} += length unquote($rest) }
    elsif ($size{$op}) { $offset{$section} += $size{$op} * @{ $stmt->{ops} } }
    elsif ($op eq ".balign") { my $a = value($rest); $offset{$section} += -$offset{$section} % $a }
    elsif ($op eq ".skip") { $offset{$section} += value($rest) }
    elsif ($op =~ /^\./) { fail "unsupported directive $op" }
    else { $offset{$section} += $op =~ /^(call|la)$/ ? 8 : 4 }
}

# ---------------------------------------------------------------------------
# Numeric labels: each definition gets a name in its global label, each
# reference the name of the definition it means.
# ---------------------------------------------------------------------------

for my $items (values %sections) {
    my ($global, %count, @defs);
    for my $i (0 .. $#$items) {
        my $it = $items->[$i];
        next unless defined $it->{label};
        if ($it->{label} !~ /^\d+$/) { $global = $it->{label}; %count = (); next }
        $where = $it->{where};
        fail "numeric label $it->{label}: outside a global label" unless defined $global;
        my $n = $it->{label};
        my $k = ++$count{$n};
        $it->{name} = $k == 1 ? "L$n" : "L${n}_$k";
        $it->{global} = $global;
        push @defs, [$i, $n, $it];
    }
    $global = undef;
    for my $i (0 .. $#$items) {
        my $it = $items->[$i];
        if (defined $it->{label}) { $global = $it->{label} if $it->{label} !~ /^\d+$/; next }
        $where = $it->{where};
        for (@{ $it->{ops} }) {
            next unless /^(\d+)([bf])$/;
            my ($n, $dir) = ($1, $2);
            my ($def) = $dir eq "b"
                ? reverse(grep { $_->[1] eq $n && $_->[0] < $i } @defs)
                : grep { $_->[1] eq $n && $_->[0] > $i } @defs;
            fail "no label for $_" unless $def;
            fail "$_ reaches into $def->[2]{global}, outside $global: use a global label"
                if $def->[2]{global} ne $global;
            $_ = $def->[2]{name};
        }
    }
}

# ---------------------------------------------------------------------------
# Pass 2: ff nodes
# ---------------------------------------------------------------------------

my %reg = map { $_ => 1 } qw(zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5
    a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6 fp), map { "x$_" } 0 .. 31;
my %label = map { $_ => 1 } keys %label_at;
$label{$_->{name}} = 1 for grep { $_->{name} } map { @$_ } values %sections;

# An operand as an argument: a register, label, constant or number as it
# is; any other expression as its value.
sub arg {
    my ($e) = @_;
    return node($e) if $reg{$e} || $label{$e} || exists $equ{$e} || $e =~ /^-?(\d+|0x[0-9a-fA-F]+)$/;
    node(value($e));
}

sub reg { my ($r) = @_; fail "not a register: $r" unless $reg{$r}; node($r) }

sub target { my ($l) = @_; fail "not a label: $l" unless $label{$l}; $l }

sub rel { node("rel", node(target($_[0]))) }

# "off(base)" -> (off, base)
sub mem {
    my ($m) = @_;
    $m =~ /^(.*)\((\w+)\)$/ or fail "not an address: $m";
    (arg($1 eq "" ? "0" : $1), reg($2));
}

sub want { my ($ops, $n) = @_; fail "want $n operands" unless @$ops == $n }

my %R = map { $_ => 1 } qw(add sub sll slt sltu xor srl sra or and mul mulh mulhsu
    mulhu div divu rem remu addw subw sllw srlw sraw mulw divw divuw remw remuw);
my %I = map { $_ => 1 } qw(addi slti sltiu xori ori andi slli srli srai addiw slliw
    srliw sraiw);
my %L = map { $_ => 1 } qw(lb lh lw ld lbu lhu lwu);
my %S = map { $_ => 1 } qw(sb sh sw sd);
my %B = map { $_ => 1 } qw(beq bne blt bge bltu bgeu);
my %Z = map { $_ => 1 } qw(beqz bnez bltz bgez blez bgtz);
my %B2 = map { $_ => 1 } qw(bgt ble bgtu bleu);
my %data = (".byte" => "byte", ".half" => "half", ".word" => "word", ".dword" => "dword");

sub translate {
    my ($st) = @_;
    my ($op, @o) = ($st->{op}, @{ $st->{ops} });
    $where = $st->{where};
    return node("ascii", node(unquote($o[0]))) if $op eq ".ascii";
    return map { node($data{$op}, arg($_)) } @o if $data{$op};
    return node("align", arg($o[0])) if $op eq ".balign";
    return node("reserve", arg($o[0])) if $op eq ".skip";
    if ($R{$op}) { want(\@o, 3); return node($op, reg($o[2]), reg($o[1]), reg($o[0])) }
    if ($I{$op}) { want(\@o, 3); return node($op, arg($o[2]), reg($o[1]), reg($o[0])) }
    if ($L{$op}) { want(\@o, 2); my ($off, $base) = mem($o[1]); return node($op, $off, $base, reg($o[0])) }
    if ($S{$op}) { want(\@o, 2); my ($off, $base) = mem($o[1]); return node($op, $off, reg($o[0]), $base) }
    if ($B{$op}) { want(\@o, 3); return node($op, rel($o[2]), reg($o[1]), reg($o[0])) }
    if ($Z{$op}) { want(\@o, 2); return node($op, node(target($o[1])), reg($o[0])) }
    if ($B2{$op}) { want(\@o, 3); return node($op, node(target($o[2])), reg($o[1]), reg($o[0])) }
    return node("ecall") if $op eq "ecall";
    return node("ret") if $op eq "ret";
    if ($op eq "j" || $op eq "call") { want(\@o, 1); return node($op, node(target($o[0]))) }
    if ($op eq "jr") { want(\@o, 1); return node("jr", reg($o[0])) }
    if ($op eq "jalr") {
        return node("jalr", node(0), reg($o[0]), node("ra")) if @o == 1;
        want(\@o, 2);
        my ($off, $base) = mem($o[1]);
        return node("jalr", $off, $base, reg($o[0]));
    }
    if ($op eq "jal") {
        return node("jal", rel($o[0]), node("ra")) if @o == 1;
        want(\@o, 2);
        return node("jal", rel($o[1]), reg($o[0]));
    }
    if ($op eq "la") { want(\@o, 2); return node("la", node(target($o[1])), reg($o[0])) }
    if ($op =~ /^(mv|neg|seqz)$/) { want(\@o, 2); return node($op, reg($o[1]), reg($o[0])) }
    if ($op eq "li") {
        want(\@o, 2);
        my $v = value($o[1]);
        return node("li", arg($o[1]), reg($o[0])) if $v >= -2048 && $v < 2048;
        fail "li of $v: more than 32 bits" if $v < -2**31 || $v >= 2**31;
        return node(($v & 0xfff) ? "li32" : "lui", arg($o[1]), reg($o[0]));
    }
    fail "unsupported instruction $op";
}

# Every section as top-level nodes: a global label holds what follows it,
# up to the next global label; a numeric label holds what follows it, up to
# the next label.
sub blocks {
    my ($items) = @_;
    my (@top, $global, $local);
    for my $it (@$items) {
        if (defined $it->{label}) {
            if ($it->{name}) { $local = node("$it->{name}:"); push @{ $global->{children} }, $local }
            else { $global = node("$it->{label}:"); $local = undef; push @top, $global }
            next;
        }
        my $into = $local // $global;
        if ($into) { push @{ $into->{children} }, translate($it) }
        else { push @top, translate($it) }
    }
    @top;
}

sub section {
    my ($name) = @_;
    my @nodes = blocks($sections{$name});
    @nodes ? (node("align", node(8)), @nodes) : ();
}

my @program = (
    node("origin", node("elf_base")),
    node("elf_header", node("_start"), node("file_end"), node("mem_end")),
    blocks($sections{".text"}),
    section(".rodata"),
    section(".data"),
    node("file_end:"),
    node("bss"),
    section(".bss"),
    node("mem_end:"),
);

sub save {
    my ($file, @nodes) = @_;
    open my $out, ">", $file or die "s2ff: cannot write $file: $!\n";
    binmode $out;
    print $out write_txt(@nodes);
}

save($consts_out, @consts);
save($prog_out, @program);
