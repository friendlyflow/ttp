# ISA.pm — builds the section of one target for mkff.pl: its groups of
# definitions, each instruction an encoding of fixed fields and operand
# slices (see mkff.pl for the form), the slice functions they use, and the
# groups read from macros/<target>.ff.txt.
#
#   my $isa = ISA->new(width => sub { ... });   # bits of a bare operand
#   $isa->group("integer");                     # where def puts what follows
#   $isa->def("addi", "imm[11:0]", "rs1", "funct3=000", "rd", "opcode=0010011");
#   $isa->add("registers", @nodes);             # ready-made nodes
#   my $section = $isa->section("riscv64", "macros/riscv64.ff.txt");
#
# A node holds at most 255 children: a group with more is put in layers.

package ISA;

use strict;
use warnings;
use File::Basename qw(dirname);
use FF qw(node call read_txt layers);

sub new {
    my ($class, %opt) = @_;
    bless { width => $opt{width}, slices => [], seen => {}, groups => [], current => undef }, $class;
}

# A new group, or back to one; def and add put their nodes in it.
sub group {
    my ($self, $name) = @_;
    my ($g) = grep { $_->{content} eq "$name:" } @{ $self->{groups} };
    push @{ $self->{groups} }, $g = node("$name:") unless $g;
    $self->{current} = $g;
}

sub add {
    my ($self, $name, @nodes) = @_;
    $self->group($name);
    push @{ $self->{current}{children} }, @nodes;
}

# "funct3=000" -> funct3: with child 000; "rd" -> call rd[4:0] with arg rd
# (the width callback gives the bits of a bare operand); "imm[11:0]" -> call
# imm[11:0] with arg imm.
sub field {
    my ($self, $f) = @_;
    my ($name, $bits) = split /=/, $f, 2;
    return node("$name:", node($bits)) if defined $bits;
    $name .= "[" . $self->{width}->($name) . "]" unless $name =~ /\[/;
    $name =~ /^(.+)\[/;
    push @{ $self->{slices} }, $name unless $self->{seen}{$name}++;
    call($name, $1);
}

# An instruction: the operand fields' base names, in field order, are its
# parameters, then its fields MSB first.
sub insn {
    my ($self, $name, @fields) = @_;
    my (%seen, @params);
    for (grep { !/=/ } @fields) {
        (my $p = $_) =~ s/\[.*//;
        push @params, $p unless $seen{$p}++;
    }
    node("$name:", (map { node($_) } @params), map { $self->field($_) } @fields);
}

sub def {
    my ($self, @insn) = @_;
    die "ISA: def outside a group\n" unless $self->{current};
    push @{ $self->{current}{children} }, $self->insn(@insn);
}

# "imm[20|10:1|11|19:12]" -> its function with parameter imm: one bits call
# per segment, or-ed together, the first segment in the field's top bits.
sub slice {
    my ($name) = @_;
    my ($base, $list) = $name =~ /^(.+)\[(.+)\]$/ or die "ISA: bad slice $name\n";
    my @segs = map { /^(\d+)(?::(\d+))?$/ or die "ISA: bad slice $name\n"; [$1, $2 // $1] }
        split /\|/, $list;
    my $pos = 0;
    $pos += $_->[0] - $_->[1] + 1 for @segs;
    my @args;
    for (@segs) {
        my ($hi, $lo) = @$_;
        $pos -= $hi - $lo + 1;
        push @args, [63 - $hi, 63 - $hi + $lo, $pos];
    }
    return node("$name:", node($base), call("bits", $base, @{ $args[0] })) if @args == 1;
    node("$name:", node($base),
        call("addi", 0, $base, "t1"),       # keep base, a0 is overwritten
        (map { (call("bits", "t1", @{ $args[$_] }),
                $_ ? call("or", qw(a0 t0 t0)) : call("addi", qw(0 a0 t0))) } 0 .. $#args),
        call("addi", qw(0 t0 a0)));
}

sub slurp {
    my ($file) = @_;
    open my $in, "<:raw", $file or die "ISA: cannot open $file: $!\n";
    local $/;
    <$in>;
}

# The section: its groups, the slices they use, then the groups of the
# macros file.
sub section {
    my ($self, $name, $macros) = @_;
    my @groups = @{ $self->{groups} };
    push @groups, node("slices:", map { slice($_) } @{ $self->{slices} }) if @{ $self->{slices} };
    push @groups, read_txt(slurp(dirname(__FILE__) . "/../$macros"), $macros) if $macros;
    # a group of more than a node holds is in layers (0: 1: ..., FF.pm),
    # which every scope looks through
    for (@groups) { $_->{children} = [layers(@{ $_->{children} })] }
    node("$name:", @groups);
}

1;
