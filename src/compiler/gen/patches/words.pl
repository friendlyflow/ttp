# words.pl: the user's C words (2026-10-20), see gen/Words.pm and
# language.ff.txt. cast (the type its children) and the suffixes U L UL LL
# ULL are prefixes, their operand the next sibling; * pointer (C's *p) and
# & address (C's &x) postfixes, after their operand, as ++, applied left to
# right; a type run is its base (a type word, or an array node: the
# element's run and the count, none for C's []) and the * pointer leaves
# after it.
#
# cc_kw spells & address (KW_address) and * pointer (KW_content), cast
# without its colon, and the suffixes (KW_U ... KW_ULL); the offsets of
# include after & address move from 128 to 132.
#
# unary reads the prefixes (prefixw): a cast's or a suffix's operand
# converted (a leaf under char * pointer a text, as convert did); an
# operand followed by a postfix (chain): * pointer loads through it,
# & address takes its address (of a : holding a typed literal, a cast to
# one scalar word or a suffix, a temporary as before). A : as the operand
# of cast or * pointer holding one expression, or a : holding one unit (its
# prefixes, a node, its postfixes) with a prefix or a postfix, is that
# expression (operandv, inplace: C's parentheses, no scope). expr takes
# x * pointer ... = v (lvop), so do ++ and -- before and after it, addr a :
# of such a chain, goto / p / * pointer. items counts a prefix as ! and a
# postfix as ++. kind, dtype, global and gval (gv_end, the end of the items)
# read a global's items so; tscan reserves no temporary for a type (a
# definition's type run, a cast's, sizeof's, va_arg's) and one for a typed
# literal's address; decl reads a variable-length array from its array
# node; fail's items are expressions. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my @top = tree();
sub L { !@{ $_[0]{children} } }
sub kids { $_[0]{children} }
sub sig {
    my ($n) = @_;
    return $n->{content} if L($n);
    join ' ', $n->{content}, map { L($_) ? $_->{content} : $_->{content} eq 'rel' ? 'rel:' . $_->{children}[0]{content} : "{$_->{content}}" } @{ $n->{children} };
}
# the one node name: in the whole tree, the shallowest
sub fnd {
    my ($name) = @_;
    my @q = map { [$_, 1] } @top;
    my ($best, @hits);
    while (my $e = shift @q) {
        my ($n, $d) = @$e;
        last if defined $best && $d > $best;
        if ($n->{content} eq "$name:") { push @hits, $n; $best = $d; next }
        push @q, map { [$_, $d + 1] } @{ $n->{children} };
    }
    die "words: " . @hits . " of $name\n" unless @hits == 1;
    $hits[0];
}
sub parent {
    my ($x) = @_;
    my @q = ({ children => \@top });
    while (my $n = shift @q) { return $n if grep { $_ == $x } @{ $n->{children} }; push @q, @{ $n->{children} } }
    die "words: no parent of $x->{content}\n";
}
sub code { FF::read_txt(asm(0, $_[0]), 'words') }
sub fncode { my ($name, $src) = @_; FF::read_txt(fn($name, $src, 0), 'words') }
sub lines { map { s/^\s+|\s+$//gr } grep { /\S/ && !/^\s*#/ } split /\n/, $_[0] }
# where the instructions stand in list, once
sub idx {
    my ($l, @s) = @_;
    my @hits = grep { my $i = $_; !grep { $i + $_ >= @$l || sig($l->[$i + $_]) ne $s[$_] } 0 .. $#s } 0 .. $#$l;
    die "words: found " . @hits . " times, not once: @s[0 .. ($#s > 3 ? 3 : $#s)]\n" unless @hits == 1;
    $hits[0];
}
sub repl { my ($l, $old, $new) = @_; my @s = lines($old); my $i = idx($l, @s); splice @$l, $i, scalar @s, code($new) }
sub before { my ($l, $at, $new) = @_; my @s = lines($at); my $i = idx($l, @s); splice @$l, $i, 0, code($new) }
sub after { my ($l, $at, $new) = @_; my @s = lines($at); my $i = idx($l, @s); splice @$l, $i + @s, 0, code($new) }
sub lab { my ($fn, $name) = @_; my ($n) = grep { $_->{content} eq "$name:" } @{ kids($fn) }; $n // die "words: no label $name in $fn->{content}\n" }
# new functions after the function at
sub add_after { my ($at, @nodes) = @_; my $p = kids(parent($at)); my ($i) = grep { $p->[$_] == $at } 0 .. $#$p; splice @$p, $i + 1, 0, @nodes }

# --- the words ------------------------------------------------------------
{
    my $kw = fnd('cc_kw');
    my ($a, $b) = map { $_->{children}[0] } @{ kids($kw) };
    $a->{content} =~ s/:\0address\0content\0syscall\0/:\0& address\0* pointer\0syscall\0/ or die "words: cc_kw 1\n";
    $b->{content} =~ s/\0cast:\0weak\0/\0cast\0weak\0/ or die "words: cc_kw cast\n";
    $b->{content} =~ s/\0imag\0\0$/\0imag\0U\0L\0UL\0LL\0ULL\0\0/ or die "words: cc_kw end\n";
    my $n = 0;
    my $walk;
    $walk = sub {
        my ($l) = @_;
        for my $i (0 .. $#$l) {
            if ($i < $#$l && sig($l->[$i]) eq 'la cc_kw a1' && sig($l->[$i + 1]) eq 'addi 128 a1 a1') { $l->[$i + 1]{children}[0]{content} = '132'; $n++ }
            $walk->(kids($l->[$i]));
        }
    };
    $walk->(\@top);
    die "words: include's offset $n times, not 2\n" unless $n == 2;
    my $m = fnd('msg_text')->{children}[0]{children}[0];
    $m->{content} =~ s/text needs address char:/text needs char * pointer:/ or die "words: msg_text\n";
}

# --- types ----------------------------------------------------------------
{
    my $type = fnd('type');
    my $tk = kids($type);
    my $i = idx($tk, lines("enter2\nmv a0 s4\nli -1 a0\nlbu NODE_children_len s4 t0\nbnez L9 t0"));
    my @rest = splice @$tk, $i + 5;
    splice @$tk, $i;
    push @$tk, code("lbu NODE_children_len a0 t0\nbeqz tyword t0\nli -1 a0\nret");
    my $ty = { content => 'tyword:', children => [code("enter2\nmv a0 s4\nli -1 a0"), @rest] };
    repl(kids($ty), "mv s4 a0\ncall kwof\nli KW_address t0\nli 0 a1\nbeq rel:L5 t0 a0", '');
    @{ kids($ty) } = grep { $_->{content} ne 'L5:' } @{ kids($ty) };
    add_after($type, $ty);

    my $tr = fnd('typerun');
    @{ kids($tr) } = code("
    enter5
    mv a0 s4
    mv a1 s5
    li -1 a0
    bgeu rel:L9 s5 s4
    ld 0 s4 s6
    lbu NODE_children_len s6 t0
    bnez L2 t0
    mv s6 a0
    call type
    bltz L9 a0
    addi 8 s4 s4
    j L4
    # an array: its element's type run, then its count (none: C's [])
    L2:
    mv s6 a0
    call kwof
    li KW_array t0
    bne rel:TV t0 a0
    ld NODE_children s6 a0
    lbu NODE_children_len s6 t0
    slli 3 t0 t0
    add t0 a0 s8
    mv s8 a1
    call typerun
    bltz L7 a0
    mv a0 s7
    li 0 a2
    bgeu rel:L3 s8 a1
    addi 8 a1 t2
    bne rel:L7 s8 t2
    ld 0 a1 t1
    lbu NODE_children_len t1 t0
    bnez TV t0
    ld NODE_content t1 a0
    lbu NODE_content_len t1 a1
    call vfind
    bnez TV a0
    ld -8 s8 a0
    call constval
    mv a0 a2
    L3:
    mv s7 a1
    li TY_ARRAY a0
    call newtype
    addi 8 s4 s4
    # the * pointer leaves after it
    L4:
    mv s4 a1
    mv s5 a2
    call ptrsuf
    mv a1 s4
    L9:
    mv s4 a1
    leave5
    TV:
    li -1 a0
    j L9
    L7:
    mv s6 a0
    call bad
    j L9
");
    add_after($tr, fncode('ptrsuf', "
    # the type a0 under the * pointer leaves from a1 on (up to a2): the type
    # in a0, in a1 where they end
    enter3
    mv a0 s6
    mv a1 s4
    mv a2 s5
    P1:
    bgeu rel:P9 s5 s4
    ld 0 s4 a0
    lbu NODE_children_len a0 t0
    bnez P9 t0
    call kwof
    li KW_content t0
    bne rel:P9 t0 a0
    addi 8 s4 s4
    mv s6 a1
    li TY_ADDRESS a0
    li 0 a2
    call newtype
    mv a0 s6
    j P1
    P9:
    mv s6 a0
    mv s4 a1
    leave3
"), fncode('prefixw', "
    # the prefix the node a0 is: 1 * pointer, 2 & address, 3 cast, 4 + n the
    # suffix n (U L UL LL ULL); 0 none
    enter1
    mv a0 s4
    lbu NODE_children_len s4 t0
    bnez W3 t0
    call kwof
    li KW_content t0
    beq rel:W1 t0 a0
    li KW_address t0
    beq rel:W2 t0 a0
    li KW_U t0
    blt rel:W0 t0 a0
    sub t0 a0 a0
    addi 4 a0 a0
    leave1
    W1:
    li 1 a0
    leave1
    W2:
    li 2 a0
    leave1
    W3:
    call kwof
    li KW_cast t0
    bne rel:W0 t0 a0
    li 3 a0
    leave1
    W0:
    li 0 a0
    leave1
"), fncode('sufty', "
    # the type of the suffix a0 (prefixw's 4 ...): U unsigned int, L long,
    # UL unsigned long, LL long long, ULL unsigned long long
    li 4 t0
    beq rel:S4 t0 a0
    li 5 t0
    beq rel:S5 t0 a0
    li 6 t0
    beq rel:S6 t0 a0
    la ccs t0
    ld CC_jit t0 t0
    bnez S7 t0
    la targ_word t0
    ld 0 t0 t0
    li 8 t1
    beq rel:S7 t1 t0
    li 7 t0
    beq rel:S8 t0 a0
    li 88 a0
    ret
    S8:
    li 72 a0
    ret
    S7:
    li 7 t0
    beq rel:S5 t0 a0
    S6:
    li 24 a0
    ret
    S4:
    li 20 a0
    ret
    S5:
    li 8 a0
    ret
"), fncode('oneexpr', "
    # 1 if the node a0 is a : that holds one expression (not compile time,
    # not a declaration)
    enter1
    mv a0 s4
    lbu NODE_children_len s4 t0
    beqz E0 t0
    lbu NODE_content_len s4 t0
    li 1 t1
    bne rel:E0 t1 t0
    ld NODE_content s4 t0
    lbu 0 t0 t0
    li CH_colon t1
    bne rel:E0 t1 t0
    mv s4 a0
    call ctfirst
    bnez E0 a0
    ld NODE_children s4 t0
    ld 0 t0 a0
    lbu NODE_content_len a0 t0
    li 2 t1
    blt rel:E1 t1 t0
    call is_fn
    bnez E0 a0
    E1:
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call items
    addi -1 a0 a0
    seqz a0 a0
    leave1
    E0:
    li 0 a0
    leave1
"), fncode('inplace', "
    # 1 if the node a0 is a : that holds one unit (its prefixes, a node,
    # its postfixes and ++ --) with a prefix or a postfix: that expression,
    # as C's parentheses
    enter5
    mv a0 s4
    call oneexpr
    beqz I0 a0
    li 0 s7
    ld NODE_children s4 s5
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 s5 s6
    I1:
    bgeu rel:I0 s6 s5
    ld 0 s5 a0
    call prefixw
    li 3 t0
    blt rel:I2 t0 a0
    li 1 s7
    addi 8 s5 s5
    j I1
    I2:
    addi 8 s5 s5
    I3:
    bgeu rel:I8 s6 s5
    ld 0 s5 a0
    call prefixw
    li 1 t0
    beq rel:I4 t0 a0
    li 2 t0
    beq rel:I4 t0 a0
    bnez I0 a0
    ld 0 s5 a0
    call opof
    li OP_inc t0
    beq rel:I5 t0 a0
    li OP_dec t0
    beq rel:I5 t0 a0
    j I0
    I4:
    li 1 s7
    I5:
    addi 8 s5 s5
    j I3
    I8:
    mv s7 a0
    leave5
    I0:
    li 0 a0
    leave5
"), fncode('operandv', "
    # the operand of a prefix, at CC_cur: a unary, a : of one expression in
    # place (unless a postfix follows it: then the unary's)
    enter1
    call peek
    mv a0 s4
    beqz V1 a0
    call oneexpr
    beqz V1 a0
    call post2
    bnez V1 a0
    call next
    mv s4 a0
    call exprof
    leave1
    V1:
    call unary
    leave1
"), fncode('chain', "
    # an operand at CC_cur and the postfixes after it (* pointer, & address):
    # 1 in a0 if what it leaves is an address (of an object of the type),
    # else 0 (a value); a : of one expression before * pointer in place
    enter2
    call next
    mv a0 s4
    call peek
    call prefixw
    li 2 t0
    bne rel:C2 t0 a0
    # x & address: its address; of a : holding a typed literal, a temporary;
    # of a : holding a compound literal, its temporary's
    mv s4 a0
    call oneexpr
    beqz C3 a0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call tlit1
    bnez CT a0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call litk
    li -1 t0
    beq rel:C3 t0 a0
    mv s4 a0
    call exprof
    li 1 s5
    j C1
    CT:
    call next
    mv s4 a0
    call exprof
    call getty
    mv a0 s5
    call slot
    la ccs t0
    ld CC_tnext t0 t1
    add a0 t1 t1
    sd CC_tnext t1 t0
    mv t1 s4
    neg s4 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s5 a0
    call store
    neg s4 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s5 a1
    li TY_ADDRESS a0
    li 0 a2
    call newtype
    call setty
    li 0 s5
    j C1
    C3:
    mv s4 a0
    call addr
    li 1 s5
    j C1
    C2:
    mv s4 a0
    call oneexpr
    beqz C4 a0
    mv s4 a0
    call exprof
    li 0 s5
    j C1
    C4:
    mv s4 a0
    call primary
    li 0 s5
    C1:
    call peek
    beqz C9 a0
    call prefixw
    li 1 t0
    beq rel:CD t0 a0
    li 2 t0
    beq rel:CA t0 a0
    j C9
    CD:
    call next
    beqz CD1 s5
    call rvalue
    CD1:
    call getty
    call tbase
    bltz CB a0
    call setty
    li 1 s5
    j C1
    CA:
    call next
    beqz CB s5
    call getty
    mv a0 a1
    li TY_ADDRESS a0
    li 0 a2
    call newtype
    call setty
    li 0 s5
    j C1
    C9:
    mv s5 a0
    leave2
    CB:
    mv s4 a0
    call bad
"), fncode('lvop', "
    # the operator after the operand at CC_cur and its postfixes: -1 if none
    enter2
    la ccs t0
    ld CC_cur t0 s4
    ld CC_end t0 s5
    addi 8 s4 s4
    P1:
    bgeu rel:P8 s5 s4
    ld 0 s4 a0
    call prefixw
    li 1 t0
    beq rel:P2 t0 a0
    li 2 t0
    bne rel:P3 t0 a0
    P2:
    addi 8 s4 s4
    j P1
    P3:
    ld 0 s4 a0
    call opof
    leave2
    P8:
    li -1 a0
    leave2
"), fncode('post2', "
    # 1 (* pointer) or 2 (& address) if a postfix follows the node at
    # CC_cur, else 0
    enter1
    la ccs t0
    ld CC_cur t0 t1
    ld CC_end t0 t2
    addi 8 t1 t1
    li 0 a0
    bgeu rel:Z9 t2 t1
    ld 0 t1 a0
    call prefixw
    li 3 t0
    blt rel:Z9 t0 a0
    li 0 a0
    Z9:
    leave1
"), fncode('tlit1', "
    # 1 if the node a0 is a typed literal for & address's temporary: a
    # suffix, or a cast to one scalar word (not void, not char)
    enter1
    mv a0 s4
    call prefixw
    li 4 t0
    bge rel:T1 t0 a0
    li 3 t0
    bne rel:T0 t0 a0
    lbu NODE_children_len s4 t0
    li 1 t1
    bne rel:T0 t1 t0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call tyname
    bltz T0 a0
    beqz T0 a0
    li 17 t0
    beq rel:T0 t0 a0
    T1:
    li 1 a0
    leave1
    T0:
    li 0 a0
    leave1
"), fncode('pairv', "
    # the value of the two items at a0 (a cast or a suffix and its operand),
    # worked out while compiling (as a cast's node: pair_slot says where)
    la pair_slot t0
    sd 0 a0 t0
    ld 0 a0 a0
    la pairconst a1
    j ctrun
"), fncode('pairconst', "
    la pairbody a1
    j frame
"), fncode('pairbody', "
    enter3
    la pair_slot t0
    ld 0 t0 s4
    la ccs t0
    ld CC_cur t0 s5
    ld CC_end t0 s6
    sd CC_cur s4 t0
    addi 16 s4 t1
    sd CC_end t1 t0
    ld 0 s4 t1
    sd CC_self t1 t0
    li 1 a0
    call expr
    la ccs t0
    sd CC_self zero t0
    sd CC_cur s5 t0
    sd CC_end s6 t0
    leave3
"), fncode('litk', "
    # a compound literal's head, the node a0: how many items follow it (an
    # array's count, a struct's places), -2 a union's (its field's name and
    # one item), -1 none
    enter2
    mv a0 s4
    lbu NODE_children_len s4 t0
    beqz K5 t0
    call kwof
    li KW_array t0
    bne rel:K9 t0 a0
    ld NODE_children s4 t0
    lbu NODE_children_len s4 t1
    slli 3 t1 t1
    add t1 t0 t0
    ld -8 t0 t0
    lbu NODE_children_len t0 t1
    bnez K9 t1
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call parse_num
    beqz K9 a1
    leave2
    # (a struct's name: no variable is named as a type; vfind would see the
    # locals declared further, as tscan asks before them)
    K5:
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    mv s4 a2
    call cfind
    beqz K9 a0
    mv a0 s5
    call defkw
    li KW_union t0
    beq rel:K7 t0 a0
    li KW_struct t0
    bne rel:K9 t0 a0
    mv s5 a0
    call places
    leave2
    K7:
    li -2 a0
    leave2
    K9:
    li -1 a0
    leave2
"), fncode('places', "
    # the places of the struct definition a0: its named fields, an
    # anonymous struct member's places, an anonymous union one, padding none
    enter3
    mv a0 s4
    li 0 s5
    ld NODE_children s4 s6
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 s6 s4
    addi 8 s6 s6
    R1:
    bgeu rel:R9 s4 s6
    ld 0 s6 a0
    lbu NODE_content_len a0 t0
    li 1 t1
    bne rel:R2 t1 t0
    lbu NODE_children_len a0 t0
    beqz R3 t0
    ld NODE_children a0 t0
    ld 0 t0 a2
    lbu NODE_children_len a2 t0
    bnez R3 t0
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    call cfind
    beqz R3 a0
    addi -16 sp sp
    sd 0 s4 sp
    mv a0 s4
    call defkw
    li KW_union t0
    beq rel:R4 t0 a0
    li KW_struct t0
    bne rel:R5 t0 a0
    mv s4 a0
    call places
    add a0 s5 s5
    j R5
    R4:
    addi 1 s5 s5
    R5:
    ld 0 sp s4
    addi 16 sp sp
    j R3
    R2:
    addi 1 s5 s5
    R3:
    addi 8 s6 s6
    j R1
    R9:
    mv s5 a0
    leave3
"), fncode('item1', "
    # a0 after the one item at a0 (up to a1), as items counts them
    enter5
    mv a0 s4
    mv a1 s5
    li 1 s6
    li 0 s7
    L1:
    bgeu rel:L9 s5 s4
    ld 0 s4 a0
    call opof
    bltz W3 a0
    li OP_cond t0
    beq rel:W4 t0 a0
    li OP_inc t0
    beq rel:L4 t0 a0
    li OP_dec t0
    beq rel:L4 t0 a0
    li OP_muleq t0
    bge rel:L7 t0 a0
    li OP_last t0
    bgt L5 t0 a0
    L7:
    li 1 s6
    j L4
    L5:
    beqz L9 s6
    li 1 s6
    j L4
    L3:
    ld 0 s4 a0
    call kwof
    li KW_else t0
    beq rel:L4 t0 a0
    li KW_elseif t0
    beq rel:L4 t0 a0
    ld 0 s4 a0
    call prefixw
    li 3 t0
    bge rel:L5 t0 a0
    bnez L4 a0
    beqz L9 s6
    li 0 s6
    ld 0 s4 a0
    call litk
    li -1 t0
    beq rel:L4 t0 a0
    mv a0 s8
    addi 8 s4 s4
    li -2 t0
    bne rel:L61 t0 s8
    addi 8 s4 s4
    li 1 s8
    L61:
    beqz L1 s8
    mv s4 a0
    mv s5 a1
    call item1
    mv a0 s4
    addi -1 s8 s8
    j L61
    L4:
    addi 8 s4 s4
    j L1
    W3:
    beqz L3 s7
    ld 0 s4 a0
    lbu NODE_children_len a0 t0
    bnez L3 t0
    call iscolon
    beqz L3 a0
    addi -1 s7 s7
    j L7
    W4:
    addi 1 s7 s7
    j L7
    L9:
    mv s4 a0
    leave5
"), fncode('littype', "
    # the type of the compound literal whose head's slot is a0
    enter1
    ld 0 a0 t0
    lbu NODE_children_len t0 t1
    beqz Y1 t1
    addi 8 a0 a1
    call typerun
    leave1
    Y1:
    mv t0 s4
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    mv s4 a2
    call cfind
    call struct
    leave1
"), fncode('tlit', "
    # the temporaries of the compound literal at a0 (up to a1): its own if
    # a2 (a literal in its place has none), its items'; and a1 after them
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s8
    li 0 s6
    ld 0 s4 a0
    call litk
    mv a0 s7
    beqz T2 s8
    mv s4 a0
    call littype
    call tsize
    mv a0 s6
    call slot
    add a0 s6 s6
    addi -1 s6 s6
    neg a0 a0
    and a0 s6 s6
    T2:
    addi 8 s4 s4
    li -2 t0
    bne rel:T3 t0 s7
    addi 8 s4 s4
    li 1 s7
    T3:
    beqz T9 s7
    bgeu rel:T9 s5 s4
    ld 0 s4 a0
    call litk
    li -1 t0
    beq rel:T4 t0 a0
    mv s4 a0
    mv s5 a1
    li 0 a2
    call tlit
    add a0 s6 s6
    mv a1 s4
    j T5
    T4:
    mv s4 a0
    mv s5 a1
    call item1
    mv a0 s8
    T41:
    bgeu rel:T5 s8 s4
    ld 0 s4 a0
    call tscan
    add a0 s6 s6
    addi 8 s4 s4
    j T41
    T5:
    addi -1 s7 s7
    j T3
    T9:
    mv s6 a0
    mv s4 a1
    leave5
"), fncode('litone', "
    # one place of the type a0 at s0 - a1 from the item at CC_cur: a
    # compound literal's head and its items, or a value
    enter5
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call isagg
    beqz O3 a0
    # (an empty : is a zero one: the temporary is zero already)
    call peek
    lbu NODE_children_len a0 t0
    bnez O1 t0
    lbu NODE_content_len a0 t0
    li 1 t1
    bne rel:O1 t1 t0
    ld NODE_content a0 t0
    lbu 0 t0 t0
    li CH_colon t1
    bne rel:O1 t1 t0
    call next
    leave5
    O1:
    call peek
    call litk
    li -1 t0
    beq rel:O2 t0 a0
    call next
    mv s4 a0
    mv s5 a1
    call litinit
    leave5
    O3:
    mv s4 a0
    call fwide
    bnez O2 a0
    li 1 a0
    call expr
    mv s4 a0
    call pwassign
    neg s5 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s4 a0
    call store
    leave5
    O2:
    li 1 a0
    call expr
    mv s4 a0
    call wassign
    neg s5 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s4 a0
    call copytype
    leave5
"), fncode('litinit', "
    # the places of the type a0 (an array, a struct, a union) at s0 - a1
    # from the items at CC_cur, one each: a struct's named fields (an
    # anonymous struct member's in place, padding none), a union's field
    # named first
    enter8
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call isarray
    beqz N2 a0
    ld TY_count s4 s7
    li 0 s6
    N1:
    bgeu rel:N9 s7 s6
    mv s4 a0
    mv s6 a1
    call member
    mv a1 t3
    sub a0 s5 a1
    mv t3 a0
    call litone
    addi 1 s6 s6
    j N1
    N2:
    ld TY_base s4 s8
    mv s8 a0
    call defkw
    li KW_union t0
    beq rel:NU t0 a0
    lbu NODE_children_len s8 s7
    addi -1 s7 s7
    li 0 s6
    N3:
    bgeu rel:N9 s7 s6
    mv s4 a0
    mv s6 a1
    call member
    mv a0 s9
    mv a1 s10
    ld NODE_children s8 t0
    addi 1 s6 t1
    slli 3 t1 t1
    add t1 t0 t0
    ld 0 t0 t0
    lbu NODE_content_len t0 t1
    li 1 t2
    bne rel:N4 t2 t1
    mv s10 a0
    call isstruct
    beqz N5 a0
    ld TY_base s10 a0
    call defkw
    li KW_union t0
    beq rel:NB t0 a0
    mv s10 a0
    sub s9 s5 a1
    call litinit
    j N5
    N4:
    mv s10 a0
    sub s9 s5 a1
    call litone
    N5:
    addi 1 s6 s6
    j N3
    NU:
    call next
    ld NODE_content a0 a1
    lbu NODE_content_len a0 a2
    ld TY_base s4 a0
    call fields
    beqz NB a2
    mv a0 s9
    mv a1 a0
    sub s9 s5 a1
    call litone
    N9:
    leave8
    NB:
    call peek
    call bad
"), fncode('complits', "
    # a struct's or a union's compound literal, its head the leaf a0, its
    # items at CC_cur: a temporary, its address
    enter5
    mv a0 s4
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    mv s4 a2
    call cfind
    call struct
    mv a0 s5
    mv s5 a0
    call tsize
    mv a0 s6
    call slot
    add a0 s6 s6
    addi -1 s6 s6
    neg a0 a0
    and a0 s6 s6
    la ccs t0
    ld CC_tnext t0 t1
    add s6 t1 t1
    sd CC_tnext t1 t0
    mv t1 s6
    neg s6 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s5 a0
    call tsize
    li R_t1 a1
    call li
    la cc_zero a0
    call seq
    mv s5 a0
    mv s6 a1
    call litinit
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s5 a0
    call setty
    leave5
"), fncode('tfrom', "
    # where the values among the children a1 ... a2 of the node a0 begin and
    # end (a0, a1): after a definition's type run; none in a cast or an
    # array, nor in a type under sizeof or alignof; va_arg's first only
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s4 a0
    call kwof
    li KW_cast t0
    beq rel:F9 t0 a0
    li KW_array t0
    beq rel:F9 t0 a0
    li KW_sizeof t0
    beq rel:F2 t0 a0
    li KW_alignof t0
    beq rel:F2 t0 a0
    li KW_vaarg t0
    beq rel:F3 t0 a0
    lbu NODE_content_len s4 t0
    li 2 t1
    blt rel:F0 t1 t0
    mv s4 a0
    call is_fn
    beqz F0 a0
    mv s5 a0
    mv s6 a1
    call tlskip
    call typerun
    bltz F0 a0
    mv a1 a0
    mv s6 a1
    leave3
    F2:
    mv s5 a0
    mv s6 a1
    call typerun
    bltz F0 a0
    mv s6 a0
    mv s6 a1
    leave3
    F3:
    addi 8 s5 a1
    bgeu rel:F0 s6 a1
    mv s5 a0
    leave3
    F9:
    mv s6 a0
    mv s6 a1
    leave3
    F0:
    mv s5 a0
    mv s6 a1
    leave3
"));
}

# --- the end of a global's items, for a postfix after the last -------------
{
    my $op = fnd('out_path');
    add_after($op, FF::read_txt("gv_end:\n  dword\n    0\npair_slot:\n  dword\n    0\n", 'words'));
    my $gi = fnd('ginit');
    my $n = 0;
    for my $l (kids($gi), map { kids($_) } grep { !L($_) && $_->{content} =~ /:$/ } @{ kids($gi) }) {
        for (my $i = 0; $i < @$l; $i++) {
            next unless sig($l->[$i]) eq 'call gstore';
            splice @$l, $i, 0, code("la gv_end t0\nsd 0 s7 t0");
            $i += 2;
            $n++;
        }
    }
    die "words: ginit's gstore $n times, not 2\n" unless $n == 2;
}

# --- kind: a global's items ------------------------------------------------
{
    my $k = fnd('kind');
    my $l2 = kids(lab($k, 'L2'));
    after($l2, "lbu NODE_content_len a0 t3\nbeqz L2 t3", "
    call kwof
    li KW_address t0
    beq rel:L2 t0 a0
    li KW_U t0
    bge rel:LK t0 a0
    li KW_content t0
    beq rel:L3 t0 a0
    ld -8 s5 a0
    lbu NODE_content_len a0 t3
");
    my $l21 = kids(lab($k, 'L21'));
    unshift @$l21, code("
    bgeu rel:LN s4 s5
    ld 0 s5 a0
    lbu NODE_children_len a0 t0
    bnez LN t0
    call kwof
    li KW_address t0
    beq rel:LK t0 a0
    LN:
");
    # (LN holds the rest of L21)
    my ($i) = grep { $l21->[$_]{content} eq 'LN:' } 0 .. $#$l21;
    push @{ kids($l21->[$i]) }, code("ld -8 s5 a0"), splice @$l21, $i + 1;
    my $ln = kids($l21->[$i]);
    repl($ln, "li KW_cast t0\nbeq rel:L2 t0 a0", "li KW_cast t0\nbeq rel:LK t0 a0");
    # (a prefix and its operand, an operand and & address: one value)
    push @{ kids($k) }, code("LK:\naddi 8 s5 s5\nj L2");
}

# --- decl: a variable-length array's array node -----------------------------
{
    my $dc = fnd('decl');
    my $l1 = kids(lab($dc, 'L1'));
    repl($l1, "lbu NODE_children_len s4 t0\nli 3 t1\nblt rel:L1B t1 t0\nld NODE_children s4 t0\nld 0 t0 a0\ncall kwof", "
    lbu NODE_children_len s4 t0
    beqz L1B t0
    ld NODE_children s4 t0
    ld 0 t0 a0
    lbu NODE_children_len a0 t1
    li 2 t2
    blt rel:L1B t2 t1
    call kwof
");
    my $w4 = kids(lab($dc, 'W4'));
    repl($w4, "ld NODE_children s4 a0\nlbu NODE_children_len s4 t0\nslli 3 t0 t0\nadd t0 a0 s9\naddi -8 s9 a1\naddi 8 a0 a0\ncall typerun", "
    ld NODE_children s4 t0
    ld 0 t0 t0
    ld NODE_children t0 a0
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 a0 s9
    addi -8 s9 a1
    call typerun
");
}

# --- ascan: a variable-length array's array node (a function that has one
# keeps alloca top) ------------------------------------------------------------
{
    my $as = fnd('ccalloca');
    repl(kids(lab($as, 'A2')), "ld NODE_children s4 a0\nlbu NODE_children_len s4 t0\nslli 3 t0 t0\nadd t0 a0 s5\naddi 8 a0 a0\nmv s5 a1\ncall typerun", "
    ld NODE_children s4 t0
    ld 0 t0 t0
    ld NODE_children t0 a0
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 a0 s5
    mv s5 a1
    call typerun
");
}

# --- items: a prefix as !, a postfix as ++; a compound literal one item ----
{
    my $l6 = kids(lab(fnd('items'), 'L6'));
    push @$l6, code("
    ld 0 s4 a0
    call litk
    li -1 t0
    beq rel:L4 t0 a0
    mv a0 s10
    addi 8 s4 s4
    li -2 t0
    bne rel:LI1 t0 s10
    addi 8 s4 s4
    li 1 s10
    LI1:
    beqz LI2 s10
    mv s4 a0
    mv s5 a1
    call item1
    mv a0 s4
    addi -1 s10 s10
    j LI1
    LI2:
    addi -8 s4 s4
");
    my $l3 = kids(lab(fnd('items'), 'L3'));
    after($l3, "li KW_elseif t0\nbeq rel:L4 t0 a0", "
    ld 0 s4 a0
    call prefixw
    li 3 t0
    bge rel:L5 t0 a0
    bnez L4 a0
    ld 0 s4 a0
");
}

# --- unary: the prefixes, an operand's postfixes ------------------------------
{
    my $u = fnd('unary');
    my $uk = kids($u);
    after($uk, "enter5\ncall peek\nmv a0 s4\nbeqz L8 a0", "call prefixw\nli 3 t0\nbge rel:UP t0 a0\nmv s4 a0");
    # an operand with a postfix after it
    repl(kids(lab($u, 'L2')), "bgez L11 s5\ncall op2", "bgez L11 s5\ncall post2\nbnez UQ a0\ncall op2");
    # ++ and -- before an operand with a postfix
    repl(kids(lab($u, 'L12')), "call next\ncall peek\nmv a0 s4\ncall next\nli 0 s7\nj L13", "
    call next
    call peek
    mv a0 s4
    beqz L8 a0
    call post2
    bnez L12D a0
    call next
    li 0 s7
    j L13
");
    my $l13 = kids(lab($u, 'L13'));
    my $i = idx($l13, 'mv s4 a0', 'call addr');
    my @after = splice @$l13, $i + 2;
    my ($at) = grep { $uk->[$_]{content} eq 'L13:' } 0 .. $#$uk;
    splice @$uk, $at + 1, 0, { content => 'L13A:', children => \@after };
    push @$uk, code("
    L12D:
    call chain
    beqz UB a0
    li 0 s7
    j L13A
    # an operand and its postfixes; then ++ or --, or its value
    UQ:
    call chain
    beqz L9 a0
    call peek
    beqz UQ9 a0
    call opof
    li OP_inc t0
    beq rel:UQ1 t0 a0
    li OP_dec t0
    bne rel:UQ9 t0 a0
    UQ1:
    mv a0 s5
    call next
    li 1 s7
    j L13A
    UQ9:
    call rvalue
    j L9
    # a prefix: 3 cast, 4 ... a suffix
    UP:
    mv a0 s5
    call next
    li 3 t0
    beq rel:UC t0 s5
    mv s5 a0
    call sufty
    mv a0 s6
    call unary
    j UV
    UC:
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 s7
    mv s7 a1
    call typerun
    bltz L8 a0
    bne rel:L8 s7 a1
    mv a0 s6
    call peek
    beqz L8 a0
    mv a0 a1
    mv s6 a0
    call textof
    beqz UO a0
    call next
    j L9
    UO:
    call operandv
    UV:
    call getty
    mv s6 a1
    call fcvt
    mv s6 a0
    call narrow
    mv s6 a0
    call setty
    j L9
    UB:
    mv s4 a0
    call bad
");
}

# --- expr: x * pointer ... = v --------------------------------------------
{
    my $e = fnd('expr');
    my $ek = kids($e);
    after($ek, "enter8\nmv a0 s4\nli 1 t0\nbgt L1 t0 s4", "
    call post2
    beqz LP0 a0
    call lvop
    bltz L1 a0
    li OP_cond t0
    beq rel:L1 t0 a0
    addi -3 a0 t1
    li 22 t2
    bltu rel:L1 t2 t1
    mv a0 s5
    call chain
    beqz LPB a0
    j LPA
    LP0:
");
    my ($i) = grep { $ek->[$_]{content} eq 'LP0:' } 0 .. $#$ek;
    my @rest = splice @$ek, $i + 1;
    my ($j) = grep { $rest[$_]{content} =~ /^L\w+:$/ } 0 .. $#rest;
    push @{ kids($ek->[$i]) }, splice @rest, 0, $j;
    push @$ek, @rest;
    my $lp = kids($ek->[$i]);
    my $k = idx($lp, 'mv s6 a0', 'call addr');
    my @tail = splice @$lp, $k + 2;
    splice @$ek, $i + 1, 0, { content => 'LPA:', children => \@tail };
    push @$ek, code("LPB:\nmv s4 a0\ncall bad");
}

# --- primary: a : of one unit is in place; compound literals ------------------
{
    my $p = fnd('primary');
    after(kids(lab($p, 'L2')), "mv s4 a0\ncall kwof\nli KW_vapacklen t0\nbeq rel:L90 t0 a0", "
    mv s4 a0
    call litk
    li -1 t0
    beq rel:L2L t0 a0
    mv s4 a0
    call complits
    j L9
    L2L:
");
    repl(kids(lab($p, 'L10')), "mv s4 a0\ncall group\nj L9", "
    mv s4 a0
    call inplace
    beqz L10G a0
    mv s4 a0
    call exprof
    j L9
    L10G:
    mv s4 a0
    call group
    j L9
");
}

# --- addr: a : of an operand and its postfixes ----------------------------------
{
    my $a = fnd('addr');
    my $l3 = kids(lab($a, 'L3'));
    before($l3, "mv s4 a0\ncall kwof\nli KW_group t0\nbne rel:L10 t0 a0", "
    mv s4 a0
    call kwof
    li KW_group t0
    bne rel:AP0 t0 a0
    lbu NODE_children_len s4 t0
    li 2 t1
    blt rel:AP0 t1 t0
    ld NODE_children s4 t0
    ld 8 t0 a0
    call prefixw
    li 1 t0
    beq rel:AP1 t0 a0
    li 2 t0
    bne rel:AP0 t0 a0
    AP1:
    mv s4 a0
    call open
    addi -16 sp sp
    sd 0 a0 sp
    sd 8 a1 sp
    call chain
    beqz L8 a0
    call peek
    bnez L8 a0
    ld 0 sp a0
    ld 8 sp a1
    addi 16 sp sp
    call close
    j L9
    AP0:
");
}

# --- goto / p / * pointer -------------------------------------------------
{
    my $g = fnd('goto');
    repl(kids($g), "lbu NODE_children_len s4 t0\nli 1 t1\nbne rel:L1 t1 t0", "
    lbu NODE_children_len s4 t0
    li 1 t1
    bne rel:G2 t1 t0
");
    push @{ kids($g) }, code("
    G2:
    beqz L1 t0
    ld NODE_children s4 t1
    slli 3 t0 t0
    add t0 t1 t1
    ld -8 t1 a0
    call prefixw
    li 1 t0
    bne rel:L1 t0 a0
    mv s4 a0
    call open
    addi -16 sp sp
    sd 0 a0 sp
    sd 8 a1 sp
    la ccs t0
    ld CC_end t0 t1
    addi -8 t1 t1
    sd CC_end t1 t0
    call operandv
    call peek
    bnez L1 a0
    ld 0 sp a0
    ld 8 sp a1
    addi 16 sp sp
    call close
    la cc_exts a0
    addi 921 a0 a0
    call seq
    leave1
");
}

# --- gval: a global's item ------------------------------------------------
{
    my $g = fnd('gval');
    my $gk = kids($g);
    after($gk, "ld 0 s4 s5\nlbu NODE_children_len s5 t0\nbnez L10 t0", "
    mv s5 a0
    call prefixw
    li 4 t0
    bge rel:LC t0 a0
");
    # x & address: the address of x (its item ends after & address)
    after($gk, "enter5\nmv a0 s4\nmv a1 s7\nld 0 s4 s5", "
    addi 8 s4 t1
    la gv_end t0
    ld 0 t0 t0
    bgeu rel:GN0 t0 t1
    ld 0 t1 a0
    call prefixw
    li 2 t0
    bne rel:GN0 t0 a0
    mv s5 a0
    addi 8 s4 s4
    j L11
    GN0:
    ld 0 s4 s5
");
    repl(kids(lab($g, 'L10')), "ld NODE_children s5 t0\nld 0 t0 a0\nlbu NODE_children_len s5 t1\nli 2 t2\nbne rel:L11 t2 t1\nld 8 t0 s5\nj L1", "ld NODE_children s5 t0\nld 0 t0 a0");
    @{ kids(lab($g, 'L21')) } = code("
    ld NODE_children s5 a0
    lbu NODE_children_len s5 t0
    slli 3 t0 t0
    add t0 a0 s6
    mv s6 a1
    call typerun
    bltz LC a0
    bne rel:LC s6 a1
    mv a0 s8
    call isaddr
    beqz LC a0
    addi 8 s4 s4
    ld 0 s4 s5
    lbu NODE_children_len s5 t0
    bnez LV t0
    mv s8 a0
    call tbase
    li TY_CHAR t0
    beq rel:L1 t0 a0
    li TY_SCHAR t0
    beq rel:L1 t0 a0
    LV:
    mv s4 a0
    mv s8 a1
    call gval
    j L9
    LC:
    mv s4 a0
    call pairv
    addi 16 s4 a1
    j L9
");
    # (LV and LC are gval's own labels, after L21)
    {
        my $l21 = kids(lab($g, 'L21'));
        my ($i) = grep { $l21->[$_]{content} eq 'LV:' } 0 .. $#$l21;
        my @out = splice @$l21, $i;
        my ($at) = grep { $gk->[$_]{content} eq 'L21:' } 0 .. $#$gk;
        splice @$gk, $at + 1, 0, @out;
    }
    my $l20 = kids(lab($g, 'L20'));
    repl($l20, "li 3 t1\nbne rel:L12 t1 t0", "
    mv s5 a0
    call inplace
    bnez LG3 a0
    lbu NODE_children_len s5 t0
    li 2 t1
    beq rel:LG2 t1 t0
    li 4 t1
    beq rel:LG4 t1 t0
    li 3 t1
    bne rel:L12 t1 t0
");
    push @$gk, code("
    LG2:
    ld NODE_children s5 t2
    ld 0 t2 a0
    call kwof
    li KW_cast t0
    bne rel:L12 t0 a0
    j L27
    LG3:
    # (a : of one unit with a prefix or a postfix: that item, in place)
    la gv_end t0
    ld 0 t0 t1
    addi -16 sp sp
    sd 0 t1 sp
    ld NODE_children s5 a0
    lbu NODE_children_len s5 t1
    slli 3 t1 t1
    add a0 t1 t1
    sd 0 t1 t0
    mv s7 a1
    call gval
    la gv_end t0
    ld 0 sp t1
    sd 0 t1 t0
    addi 16 sp sp
    addi 8 s4 a1
    j L9
    LG4:
    ld NODE_children s5 t2
    ld 0 t2 a0
    call kwof
    li KW_cast t0
    bne rel:L12 t0 a0
    ld NODE_children s5 t2
    ld 24 t2 t3
    lbu NODE_children_len t3 t0
    bnez L12 t0
    ld NODE_content t3 a0
    lbu NODE_content_len t3 a1
    call parse_num
    beqz L12 a1
    mv a0 s6
    ld NODE_children s5 t2
    ld 16 t2 a0
    call opof
    li OP_add t0
    beq rel:L22 t0 a0
    li OP_sub t0
    bne rel:L12 t0 a0
    neg s6 s6
    j L22
");
}

# --- tscan: no temporary for a type; one for a typed literal's address -------
{
    my $s = fnd('tscan');
    my $sk = kids($s);
    repl($sk, "mv s4 a0\ncall kwof\nli KW_array t0\nbne rel:L20 t0 a0", "mv s4 a0\ncall kwof\nli KW_array t0\nbne rel:L20 t0 a0\nj L9");
    @{ kids(lab($s, 'L2')) } = code("
    ld NODE_children s4 s6
    lbu NODE_children_len s4 s7
    slli 3 s7 s7
    add s6 s7 s7
    mv s4 a0
    mv s6 a1
    mv s7 a2
    call tfrom
    mv a0 s6
    mv a1 s7
");
    @{ kids(lab($s, 'L3')) } = code("
    bgeu rel:L9 s7 s6
    addi 8 s6 t1
    bgeu rel:L31 s7 t1
    ld 0 t1 a0
    call prefixw
    li 2 t0
    bne rel:L31 t0 a0
    ld 0 s6 a0
    call oneexpr
    beqz L31 a0
    ld 0 s6 t0
    ld NODE_children t0 t0
    ld 0 t0 a0
    call tlit1
    beqz L31 a0
    call slot
    add a0 s5 s5
");
    my ($i) = grep { $sk->[$_]{content} eq 'L3:' } 0 .. $#$sk;
    splice @$sk, $i + 1, 0, code("
    L31:
    ld 0 s6 a0
    call litk
    li -1 t0
    beq rel:L32 t0 a0
    mv s6 a0
    mv s7 a1
    li 1 a2
    call tlit
    add a0 s5 s5
    mv a1 s6
    j L3
    L32:
    ld 0 s6 a0
    call tscan
    add a0 s5 s5
    addi 8 s6 s6
    j L3
");
}

# --- stmt: a prefix (a suffix) first in a statement ----------------------
{
    my $st = fnd('stmt');
    my $l3 = kids(lab($st, 'L3'));
    after($l3, "lbu NODE_children_len s4 t0\nbnez L8 t0\nmv s4 a0\ncall istext", "");
    my $i = idx($l3, lines("lbu NODE_children_len s4 t0\nbnez L8 t0"));
    splice @$l3, $i + 2, 0, code("mv s4 a0\ncall prefixw\nli 3 t0\nbge rel:L8 t0 a0");
    # a : with a postfix after it (: / p / + / 1, then * pointer) is an expression
    after(kids(lab($st, 'L1')), "lbu NODE_content_len s4 t0\nli 1 t1\nbne rel:L2 t1 t0", "call post2\nbnez L8 a0");
}

# --- complita: an array's compound literal, its items after it -------------------
{
    @{ kids(fnd('complita')) } = code("
    enter8
    mv a0 s4
    la ccs t0
    ld CC_cur t0 a1
    addi -8 a1 a0
    call typerun
    bltz AB a0
    mv a0 s5
    mv s5 a0
    call tsize
    mv a0 s6
    call slot
    add a0 s6 s6
    addi -1 s6 s6
    neg a0 a0
    and a0 s6 s6
    la ccs t0
    ld CC_tnext t0 t1
    add s6 t1 t1
    sd CC_tnext t1 t0
    mv t1 s6
    neg s6 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s5 a0
    call tsize
    li R_t1 a1
    call li
    la cc_zero a0
    call seq
    mv s5 a0
    mv s6 a1
    call litinit
    neg s6 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s5 a0
    call setty
    leave8
    AB:
    mv s4 a0
    call bad
");
}

# --- failitems: fail's items, each an expression (a cast and its value one)
{
    my $f = fnd('failitems');
    @{ kids($f) } = code("
    enter2
    mv a0 s4
    call open
    mv a0 s4
    mv a1 s5
    L1:
    call more
    beqz L2 a0
    call peek
    call kwof
    li KW_target t0
    bne rel:L3 t0 a0
    call next
    la ctputname a0
    call bridge
    j L1
    L3:
    li 1 a0
    call expr
    la ctput a0
    call bridge
    j L1
    L2:
    mv s4 a0
    mv s5 a1
    call close
    la ctend a0
    call bridge
    leave2
");
}

untree(@top);
save();
