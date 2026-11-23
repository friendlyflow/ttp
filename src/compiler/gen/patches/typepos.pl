# typepos.pl: where a type is wanted, a name is the type even when a local
# of that name is in scope (the master's fault 21, the user's choice A,
# 2026-11-23): C's struct pt pt; then pt: pt, two: array pt 2, pt * pointer,
# cast pt * pointer, sizeof of a type form and a parameter p: pt. tyword
# passed over a local found first (find_label in the function's scopes) and
# gave no type, so these failed (cannot compile: array, used before it is
# declared). Now tdefonly (paramscope.pl) is up around typerun in decl (a
# declaration's type, its array element and pointer base), a cast (primary
# L60) and & address of a type (L11), isparam, ptype and fnbody (a
# parameter's type), kind and tscan (whether a node is a declaration, and
# its type), wgrp, wname, wrec and wgate (a declaration's type for the
# temporaries), gentype (_Generic), vaarg, global, and sizeof and alignof
# of a type form (more than a leaf, as csema writes array W 1 for a type W
# while a local W is in the function);
# everywhere else, a value, a member access pt x, an argument, a bare leaf
# under sizeof and a leaf with items (pt 1 2), the local still comes first.
# Test: progs/clocaltype2.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub wrapped {
    my ($ind) = @_;
    (asm($ind, "
    la tdefonly t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
"), asm($ind, "
    la tdefonly t3
    ld 0 t3 t4
    addi -1 t4 t4
    sd 0 t4 t3
"));
}
# every call typerun of the function (or only the nth, counting from 1)
sub wrap {
    my ($fn, @only) = @_;
    my ($from, $to) = find(\$t, $fn);
    my $b = substr($t, $from, $to - $from);
    my $n = 0;
    $b =~ s{^( +)call\n\1  typerun\n}{
        $n++;
        my ($inc, $dec) = wrapped(length $1);
        (!@only || grep { $_ == $n } @only) ? "$inc$1call\n$1  typerun\n$dec" : "$1call\n$1  typerun\n"
    }mge;
    die "typepos: no typerun in $fn\n" unless $n;
    substr($t, $from, $to - $from) = $b;
}
wrap('decl', 1);
wrap('isparam');
wrap('ptype');
wrap('fnbody');
wrap('kind');
wrap('tscan');
wrap($_) for qw(wgrp wname wrec wgate gentype vaarg global);

# primary: L11 (& address of a type) and L60 (cast) always; L47 (sizeof,
# alignof) only for a type form: more than one child, or a child with
# children
{
    my ($from, $to) = find(\$t, 'primary');
    my $b = substr($t, $from, $to - $from);
    for my $lab ('L11', 'L60') {
        my $at = index($b, "        $lab:\n"); die "typepos: no $lab" if $at < 0;
        my $old = "          call\n            typerun\n";
        my $i = index($b, $old, $at); die "typepos: no typerun after $lab" if $i < 0;
        my ($inc, $dec) = wrapped(10);
        substr($b, $i, length $old) = "$inc$old$dec";
    }
    my $at = index($b, "        L47:\n"); die "typepos: no L47" if $at < 0;
    my $old = "          call\n            typerun\n";
    my $i = index($b, $old, $at); die "typepos: no typerun after L47" if $i < 0;
    # a0 a1: the children; t5 (1 for a type form) kept in the stack slot of s6? no: count it again after typerun
    my $inc = asm(10, "
    sub a0 a1 t2
    li 8 t3
    li 0 t5
    bne rel:LTF1 t3 t2
    ld 0 a0 t2
    lbu NODE_children_len t2 t2
    beqz LTF2 t2
") . asm(8, "
LTF1:
    li 1 t5
    la tdefonly t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
LTF2:
    addi -16 sp sp
    sd 0 t5 sp
");
    my $dec = asm(10, "
    ld 0 sp t5
    addi 16 sp sp
    beqz LTF3 t5
    la tdefonly t3
    ld 0 t3 t4
    addi -1 t4 t4
    sd 0 t4 t3
") . asm(8, "
LTF3:
    mv a0 a0
");
    substr($b, $i, length $old) = "$inc$old$dec";
    substr($t, $from, $to - $from) = $b;
}
save();
