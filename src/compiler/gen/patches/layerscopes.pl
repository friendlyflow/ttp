# layerscopes.pl: layers (0: 1: ..., the overflow of a node, see layers.pl)
# in the other scopes, as in find_label's: a definition page's functions
# (collect_syms), a section's groups and their definitions (include), and
# the enums a C name is looked up among (enumconst). is_layer says what a
# layer is, for all of them and lfind; lpush puts a node's functions on
# syms through its layers, lgroups a section's groups; enumin is
# enumconst's scan of one scope.
our $t; do "$ENV{PATCHLIB}" or die $@;

sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
sub replace_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $from, $to - $from) = $new }
sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
# fn with a comment of one text first
sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
my $die_depth = "
    la msg_depth a1
    li msg_depth_len a2
    ld NODE_content t0 a3
    lbu NODE_content_len t0 a4
    j die_name";

# is_layer, after is_fn (which ends with ret)
after_fn('is_fn', cfn('is_layer', '1 if the node a0 is a layer, a function whose name is only digits (0: 1: ...), the overflow of its parent; else 0', "
    lbu NODE_content_len a0 t0
    ld NODE_content a0 t1
    li 2 t2
    bltu rel:Q9 t2 t0
    add t0 t1 t3
    lbu -1 t3 t3
    li CH_colon t4
    bne rel:Q9 t4 t3
    addi -1 t0 t0
    li 10 t4
    Q1:
    lbu 0 t1 t3
    addi -48 t3 t3
    bgeu rel:Q9 t4 t3
    addi 1 t1 t1
    addi -1 t0 t0
    bnez Q1 t0
    li 1 a0
    ret
    Q9:
    li 0 a0
    ret
", indent_of('is_fn')));

# lfind with it
replace_fn('lfind', cfn('lfind', "the child of a0 named as find_label's s4 s5, looking through the layers in it, a1 layers deep; 0 if there is none", "
    enter5
    mv a0 s6
    mv a1 s7
    lbu NODE_children_len a0 s8
    ld NODE_children a0 s6
    F1:
    beqz F4 s8
    ld 0 s6 a0
    call is_fn
    beqz F3 a0
    ld 0 s6 a0
    call is_layer
    beqz F2 a0
    ld 0 s6 t0
    li MAX_DEPTH t4
    bgeu rel:F6 t4 s7
    mv t0 a0
    addi 1 s7 a1
    call lfind
    beqz F3 a0
    j F5
    F2:
    ld 0 s6 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    addi -1 a3 a3
    mv s4 a0
    mv s5 a1
    call streq
    beqz F3 a0
    ld 0 s6 a0
    j F5
    F3:
    addi 8 s6 s6
    addi -1 s8 s8
    j F1
    F4:
    li 0 a0
    F5:
    leave5
    F6:$die_depth
", indent_of('lfind')));

# collect_syms: each page's functions through its layers
my ($from, $to) = find(\$t, 'collect_syms');
my $cs = substr($t, $from, $to - $from);
my $ci = indent_of('collect_syms') + 2;
my $p = ' ' x $ci;
$cs =~ s/^${p}L1:\n.*?(?=^${p}L4:\n)/asm($ci, "
    L1:
    beqz L4 s4
    ld 0 s5 a0
    mv s6 a1
    li 0 a2
    call lpush
    mv a0 s6
    addi 8 s5 s5
    addi -1 s4 s4
    j L1
")/ems or die "layerscopes: collect_syms has changed\n";
substr($t, $from, $to - $from) = $cs;
my $li = indent_of('collect_syms');
after_fn('collect_syms', cfn('lpush', 'the functions of node a0, through its layers (a2 deep), stored from a1 on; a0 is where they end', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len a0 s7
    ld NODE_children a0 s8
    P1:
    beqz P4 s7
    ld 0 s8 a0
    call is_layer
    beqz P2 a0
    ld 0 s8 t0
    li MAX_DEPTH t4
    bgeu rel:P5 t4 s6
    mv t0 a0
    mv s5 a1
    addi 1 s6 a2
    call lpush
    mv a0 s5
    j P3
    P2:
    ld 0 s8 a0
    call is_fn
    beqz P3 a0
    ld 0 s8 t0
    sd 0 t0 s5
    addi 8 s5 s5
    P3:
    addi 8 s8 s8
    addi -1 s7 s7
    j P1
    P4:
    mv s5 a0
    leave5
    P5:$die_depth
", $li) . cfn('lgroups', 'the definitions of the groups of section a0, through the layers of both (a2 deep), stored from a1 on; a0 is where they end', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    lbu NODE_children_len a0 s7
    ld NODE_children a0 s8
    P1:
    beqz P4 s7
    ld 0 s8 a0
    mv s5 a1
    call is_layer
    beqz P2 a0
    ld 0 s8 t0
    li MAX_DEPTH t4
    bgeu rel:P5 t4 s6
    mv t0 a0
    mv s5 a1
    addi 1 s6 a2
    call lgroups
    mv a0 s5
    j P3
    P2:
    ld 0 s8 a0
    mv s5 a1
    li 0 a2
    call lpush
    mv a0 s5
    P3:
    addi 8 s8 s8
    addi -1 s7 s7
    j P1
    P4:
    mv s5 a0
    leave5
    P5:$die_depth
", $li));

# include: a section's groups through lgroups
replace_fn('include', fn('include', "
    enter5
    mv a0 s4
    call is_section
    beqz L9 a0
    mv s4 a0
    la syms_end t0
    ld 0 t0 a1
    li 0 a2
    call lgroups
    mv a0 s8
    L8:
    la syms_end t0
    sd 0 s8 t0
    la targ_end t0
    sd 0 s8 t0
    L9:
    leave5
", indent_of('include')));

# enumconst: each scope through enumin
my $ei = indent_of('enumconst');
my ($ef, $et) = find(\$t, 'enumconst');
substr($t, $ef, $et - $ef) =~ /^\s*L2:\n/m or die "layerscopes: enumconst has changed\n";
replace_fn('enumconst', fn('enumconst', "
    enter8
    mv a0 s4
    mv a1 s5
    la scope_depth t0
    ld 0 t0 t0
    slli 3 t0 t0
    la scopes s6
    add t0 s6 s6
    L1:
    la scopes t0
    beq rel:L8 t0 s6
    addi -8 s6 s6
    ld 0 s6 a0
    li 0 a1
    call enumin
    bnez L9 a0
    j L1
    L8:
    mv s4 a0
    mv s5 a1
    call enumlib
    L9:
    leave8
", $ei) . cfn('enumin', "the value of enumconst's name s4 s5 among the enums of scope a0, through its layers (a1 deep); 0 if none has it", "
    enter5
    mv a0 s6
    mv a1 s7
    lbu NODE_children_len a0 s8
    ld NODE_children a0 s6
    E1:
    beqz E4 s8
    ld 0 s6 a0
    call is_layer
    beqz E2 a0
    ld 0 s6 t0
    li MAX_DEPTH t4
    bgeu rel:E6 t4 s7
    mv t0 a0
    addi 1 s7 a1
    call enumin
    bnez E5 a0
    j E3
    E2:
    ld 0 s6 a0
    call defkw
    li KW_enum t0
    bne rel:E3 t0 a0
    ld 0 s6 a0
    mv s4 a1
    mv s5 a2
    call enumfind
    bnez E5 a0
    E3:
    addi 8 s6 s6
    addi -1 s8 s8
    j E1
    E4:
    li 0 a0
    E5:
    leave5
    E6:$die_depth
", $ei + 2));
save();
