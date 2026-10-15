#!/usr/bin/env perl
# mkwhole.pl — a whole tree, in the language of stage0 (ttpc.s), that
# assembles a program for one target: the target's section of shared.ff
# flattened into pages (a page per group), the shared definitions (bits,
# rel, the data words and slices), the pages of the definition trees, the
# exec ops and registers that assemble time runs on (riscv64: registers and
# integer), then the program as the last page. See FF.pm for the format,
# mkff.pl for the sections.
#
#   perl mkwhole.pl <target> [defs.ff ...] <prog.ff> > whole.ff
#
# ttpc for a host: perl mkwhole.pl x86_64 ttpc.defs.ff ttpc.ff, of the trees
# mkhost.pl made. prog.ff is a program of only its own (its root's children
# are the program), or a whole tree, whose last page is the program and
# whose other pages are definitions. Comments and the compile-time
# choice of a target are left out: stage0 has neither. Only
# the definitions the program reaches are kept, for stage0's 1 MiB.
#
# A host tool (core Perl only), not part of ttpc.

use strict;
use warnings;
use FindBin;
use lib $FindBin::Bin;
use FF qw(node uncomment read_ff write_ff);

die "usage: mkwhole.pl <target> [defs.ff ...] <prog.ff>\n" unless @ARGV >= 2;
my ($target, @defs_files) = @ARGV;
my $prog = pop @defs_files;

sub slurp {
    my ($file) = @_;
    open my $in, "<:raw", $file or die "mkwhole: cannot open $file: $!\n";
    local $/;
    <$in>;
}

my ($shared) = @{ uncomment(read_ff(slurp("$FindBin::Bin/shared.ff")))->{children} };
my %section = map { ($_->{content}, $_) } grep { $_->{content} =~ /^\w+:$/ && @{ $_->{children} }
    && $_->{children}[0]{content} =~ /^\w+:$/ } @{ $shared->{children} };
die "mkwhole: $target is not a target\n" unless $section{"$target:"};

# The groups of a section, each a page of its own.
sub pages {
    my ($name, @only) = @_;
    my %want = map { ("$_:" => 1) } @only;
    map { uncomment($_) } grep { !@only || $want{ $_->{content} } } @{ $section{"$name:"}{children} };
}

my $common = uncomment(node("shared:", grep { !$section{ $_->{content} } && $_->{content} ne ":" }
    @{ $shared->{children} }));

my $root = read_ff(slurp($prog));
my @kids = @{ $root->{children} };
# A whole tree: its pages are not functions of a program but pages, the
# last of which is the program.
my $whole = @kids > 1 && !grep { $_->{content} !~ /:$/ } @kids;
my $page = $whole ? $kids[-1] : node("program:", @kids);

# After the target's and the shared ones: the pages of the definition
# trees and the other pages of a whole tree, then the exec ops.
my @host = ((map { uncomment($_) } map { @{ read_ff(slurp($_))->{children} } } @defs_files),
    $whole ? map { uncomment($_) } @kids[0 .. $#kids - 1] : (),
    $target eq "riscv64" ? () : pages("riscv64", "registers", "integer"));
my @defs = (pages($target), $common, @host);

# stage0 takes a name for a register before pc: arm's r15 pc would make pc
# at assemble time a vreg. The register keeps its other name, twice (a
# register has two names).
for my $g (grep { $_->{content} eq "registers:" } @defs) {
    $_->{content} =~ s/^(\S+) pc:$/$1 $1:/ for @{ $g->{children} };
}

# One scope: stage0 finds the first function of a name, the target's. A
# call of the host's immediate ops at assemble time (andi -4096 pc a0) is
# not one of the target's of that name when their parameters do not match
# (aarch64 andi n immr imms rn rd): it becomes the register op, which
# stage0 runs the same (exec_ops: andi and and are op_and), and which every
# target defines as rm rn rd.
my %imm = (addi => "add", andi => "and", ori => "or", xori => "xor",
    slli => "sll", srli => "srl", srai => "sra");
sub params {
    my ($d) = @_;
    my @p;
    for (@{ $d->{children} }) { last if @{ $_->{children} } || $_->{content} =~ /:$/; push @p, $_->{content} }
    @p;
}
my %arity;
for my $d (map { @{ $_->{children} } } pages($target)) {
    (my $name = $d->{content}) =~ s/:$// or next;
    $arity{$name} //= [params($d)];
}
sub host_ops {
    my ($n) = @_;
    my $op = $imm{ $n->{content} };
    if ($op && $arity{ $n->{content} } && @{ $arity{ $n->{content} } } != 3
        && @{ $n->{children} } == 3) {
        my $p = $arity{$op};
        die "mkwhole: $target $op is not rm rn rd\n" if $p && "@$p" !~ /^\S+ \S+ rd$/;
        $n = node($op, @{ $n->{children} });
    }
    node($n->{content}, map { host_ops($_) } @{ $n->{children} });
}
@defs = map { host_ops($_) } @defs;

# Only what the program reaches: a definition is kept when a node of the
# program, or of a definition kept, names it (stage0 holds 1 MiB).
my %named;
sub names { my ($n) = @_; $named{ $n->{content} } = 1; names($_) for @{ $n->{children} } }
names(uncomment($page));
my %kept;
for (my $more = 1; $more;) {
    $more = 0;
    for my $d (map { @{ $_->{children} } } @defs) {
        next if $kept{$d};
        (my $name = $d->{content}) =~ s/:$//;
        next unless grep { $named{$_} } $name, split / /, $name;
        $kept{$d} = $more = 1;
        names($d);
    }
}
@defs = grep { @{ $_->{children} } }
    map { node($_->{content}, grep { $kept{$_} } @{ $_->{children} }) } @defs;

binmode STDOUT;
print write_ff(node("", @defs, host_ops(uncomment($page))));
