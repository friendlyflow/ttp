# vector.pl: the user's type node vector (2026-10-22, option 1): gcc's
# vector types (__v16qi, __m128i: vector_size (16)) in the shape of array,
# its element's type run, then the count of its elements: vector / char /
# 16 is C's char __attribute__ ((vector_size (16))), vector / long long /
# 2 is __m128i. A vector is a value in memory, as a struct (its address in
# V, copied by =, a parameter, a result), 16 bytes aligned to its size; by
# the SysV ABI it goes in one xmm register, as a long double (x64sclass's
# class 5). The operators | ^ & == != of two vectors of one size work
# element by element (cc_vor ... cc_vneb: SSE2 on x86_64, the result in a
# temporary of the function, wtemp); a cast between vector types keeps the
# bits. A vector literal is the array temporary with vector at its head
# (vector / char / 16, then its 16 items). x86_64's alone for now: on
# another target a vector stops ttpc (msg_vector). cc_kw gains vector
# (KW_vector, 62, after fs); the type kind TY_VECTOR is 6.
#
#   typerun   vector / T / n: vectype, one TY_VECTOR record for each (on
#             x86_64; else stop)
#   newtype   its size the elements', its alignment its size
#   teq       two vectors are one type where their counts and elements are
#   inmem     a vector is in memory, as a struct
#   kwav      kwof, but vector is array: where its shape is array's (tskip,
#             tfrom, tscan, litk: a type run, a literal's count)
#   primary   a vector node as a value is its literal (complita)
#   litinit, member   a vector's items are its elements, as an array's
#   binop     an operator of vectors: vbin
#   wgate     a function that names a vector has the temporaries (wtemp)
#   x64class, x64resclass   a vector is class 5 (an xmm register) and its
#             result class 8 (xmm0), as a long double
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# (T=ttpc.defs.ff: the constants KW_vector, TY_VECTOR)
if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_fs:\n    addi\n      61\n      zero\n      a0\n", "  KW_fs:\n    addi\n      61\n      zero\n      a0\n  KW_vector:\n    addi\n      62\n      zero\n      a0\n", 'KW_fs');
    once(\$t, "  TY_BITS:\n    addi\n      5\n      zero\n      a0\n", "  TY_BITS:\n    addi\n      5\n      zero\n      a0\n  TY_VECTOR:\n    addi\n      6\n      zero\n      a0\n", 'TY_BITS');
    save();
    exit;
}

sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
# within function $name, the instructions $old (asm form) become $new
sub reasm {
    my ($name, $old, $new) = @_;
    my ($from, $to) = find(\$t, $name);
    my $e = substr($t, $from, $to - $from);
    my ($ind) = grep { my $o = asm($_, $old); () = $e =~ /^\Q$o\E/mg } map { indent_of($name) + $_ } 2, 4, 6, 8;
    defined $ind or die "vector: $name: not found\n";
    once(\$e, asm($ind, $old), asm($ind, $new), $name);
    substr($t, $from, $to - $from) = $e;
}
# a block (a label and its instructions) at the end of function $name
sub add_block { my ($name, $src) = @_; after_fn($name, asm(indent_of($name) + 2, $src)) }

once(\$t, "destructor\\x00fs\\x00\\x00\n", "destructor\\x00fs\\x00vector\\x00\\x00\n", 'cc_kw');

# the message of a vector on a target without them
my $msg = 'ttpc: vector, of the SysV ABI of x86_64, on another target:\x20';
(my $mlen = $msg) =~ s/\\x20/ /;
$mlen = length $mlen;
once(\$t, "      msg_below:\n        ascii\n          ttpc: used before it is declared:\\x20\n",
    "      msg_below:\n        ascii\n          ttpc: used before it is declared:\\x20\n      msg_vector:\n        ascii\n          $msg\n", 'msg_below');

# the primitives of the operators, as the C layer's other names (seq)
once(\$t, "  cc_jalr_t0:\n    ascii\n      \\x00cc_call_l\\x00\n",
    "  cc_jalr_t0:\n    ascii\n      \\x00cc_call_l\\x00\n" . join('', map { "  str_$_:\n    ascii\n      \\x00cc_$_\\x00\n" } qw(vor vxor vand veqb veqw veqd vneb vnew vned)), 'cc_jalr_t0');

# ---- the type ------------------------------------------------------------------
reasm('typerun', "
    call kwof
    li KW_array t0
    bne rel:TV t0 a0
", "
    call kwof
    li KW_vector t0
    beq rel:VV t0 a0
    li KW_array t0
    bne rel:TV t0 a0
");
add_block('typerun', "
    VV:
    la targ_abi t0
    ld 0 t0 t0
    li 3 t1
    bne rel:VS t1 t0
    ld NODE_children s6 a0
    lbu NODE_children_len s6 t0
    slli 3 t0 t0
    add t0 a0 s8
    mv s8 a1
    call typerun
    bltz L7 a0
    mv a0 s7
    addi 8 a1 t2
    bne rel:L7 s8 t2
    ld 0 a1 t1
    lbu NODE_children_len t1 t0
    bnez L7 t0
    ld -8 s8 a0
    call constval
    mv a0 a2
    beqz L7 a2
    mv s7 a1
    call vectype
    addi 8 s4 s4
    j L4
    VS:
    mv s6 a0
    la msg_vector a1
    li $mlen a2
    j diename
");
reasm('newtype', "
    li TY_ARRAY t0
    bne rel:L1 t0 a0
", "
    li TY_VECTOR t0
    beq rel:LV t0 a0
    li TY_ARRAY t0
    bne rel:L1 t0 a0
");
add_block('newtype', "
    LV:
    mv a1 s5
    mv a2 s6
    mv s5 a0
    call tsize
    mul s6 a0 a0
    sd TY_size a0 s4
    sd TY_align a0 s4
    mv s4 a0
    leave3
");
reasm('teq', "
    li TY_ARRAY t3
    bne rel:Q3 t3 t1
", "
    li TY_VECTOR t3
    beq rel:QV t3 t1
    li TY_ARRAY t3
    bne rel:Q3 t3 t1
");
add_block('teq', "
    QV:
    ld TY_count a0 t4
    ld TY_count a1 t5
    bne rel:Q8 t4 t5
    j Q2
");
reasm('inmem', "
    li TY_STRUCT t1
    j iskind
", "
    ld TY_kind a0 t1
    li TY_VECTOR t2
    beq rel:LV t2 t1
    li TY_STRUCT t1
    j iskind
");
add_block('inmem', "
    LV:
    li 1 a0
    ret
");
after_fn('inmem', join '',
    cfn('isvector', '1 where the type a0 is a vector, else 0', "
        lui TY_REC t0
        bltu rel:IV1 t0 a0
        bltz IV1 a0
        ld TY_kind a0 t0
        li TY_VECTOR t1
        sub t1 t0 t0
        seqz t0 a0
        ret
        IV1:
        li 0 a0
        ret
    ", 6),
    cfn('vectype', 'the vector of a2 elements of the type a1: one record for each (a declaration of one is the type of its value, as a struct)', "
        la cc_types t0
        la ccs t1
        ld CC_types t1 t1
        VT1:
        bgeu rel:VT9 t1 t0
        ld TY_kind t0 t2
        li TY_VECTOR t3
        bne rel:VT2 t3 t2
        ld TY_base t0 t2
        bne rel:VT2 a1 t2
        ld TY_count t0 t2
        bne rel:VT2 a2 t2
        mv t0 a0
        ret
        VT2:
        addi TY_sz t0 t0
        j VT1
        VT9:
        li TY_VECTOR a0
        j newtype
    ", 6),
    cfn('isvarr', '1 where the type a0 is an array or a vector (whose items are its elements), else 0', "
        lui TY_REC t0
        bltu rel:IA1 t0 a0
        bltz IA1 a0
        ld TY_kind a0 t0
        li TY_ARRAY t1
        beq rel:IA2 t1 t0
        li TY_VECTOR t1
        beq rel:IA2 t1 t0
        IA1:
        li 0 a0
        ret
        IA2:
        li 1 a0
        ret
    ", 6),
    cfn('kwav', 'kwof of the node a0, but KW_array for vector: where a vector has the shape of an array', "
        enter1
        call kwof
        li KW_vector t0
        bne rel:KA9 t0 a0
        li KW_array a0
        KA9:
        leave1
    ", 6),
    cfn('fwidev', '1 where a value of the type a0 is in a temporary of the function (wtemp): wide (fwide) or a vector', "
        enter1
        mv a0 s4
        call fwide
        bnez FV1 a0
        mv s4 a0
        call isvector
        FV1:
        leave1
    ", 6));

# ---- the shape of array: a type run, a literal's count ------------------------
reasm('tskip', "
    call kwof
    li KW_array t0
    bne rel:Z8 t0 a0
", "
    call kwav
    li KW_array t0
    bne rel:Z8 t0 a0
");
reasm('tfrom', "
    call kwof
    li KW_cast t0
", "
    call kwav
    li KW_cast t0
");
reasm('tscan', "
    call kwof
    li KW_array t0
    bne rel:L20 t0 a0
", "
    call kwav
    li KW_array t0
    bne rel:L20 t0 a0
");
reasm('litk', "
    call kwof
    li KW_array t0
    bne rel:K9 t0 a0
", "
    call kwav
    li KW_array t0
    bne rel:K9 t0 a0
");
reasm('primary', "
    li KW_array t0
    beq rel:L57 t0 a0
", "
    li KW_array t0
    beq rel:L57 t0 a0
    li KW_vector t0
    beq rel:L57 t0 a0
");
reasm('litinit', "
    mv s4 a0
    call isarray
    beqz N2 a0
", "
    mv s4 a0
    call isvarr
    beqz N2 a0
");
reasm('member', "
    mv a0 s4
    mv a1 s5
    call isarray
", "
    mv a0 s4
    mv a1 s5
    call isvarr
");
reasm('wgate', "
    call typerun
    bltz L9 a0
    call fwide
    bnez L8 a0
", "
    call typerun
    bltz L9 a0
    call fwidev
    bnez L8 a0
");
reasm('wgate', "
    enter3
    mv a0 s4
", "
    enter3
    mv a0 s4
    call kwof
    li KW_vector t0
    beq rel:L8 t0 a0
");

# ---- the operators -------------------------------------------------------------
reasm('binop', "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
", "
    enter5
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s5 a0
    call isvector
    bnez VB a0
    mv s6 a0
    call isvector
    bnez VB a0
");
add_block('binop', "
    VB:
    mv s4 a0
    mv s5 a1
    mv s6 a2
    call vbin
    leave5
");
after_fn('binop', cfn('vbin', 'the operator a0 of two vectors, the types a1 and a2 (L the left one\'s address, V the right one\'s): | ^ & == != element by element, into a temporary (wtemp), V its address; one size, the elements\' for == and != (1, 2 or 4 bytes)', "
    enter3
    mv a0 s4
    mv a1 s5
    mv a2 s6
    mv s5 a0
    call isvector
    beqz VX a0
    mv s6 a0
    call isvector
    beqz VX a0
    mv s5 a0
    call tsize
    mv a0 t3
    addi -16 sp sp
    sd 0 t3 sp
    mv s6 a0
    call tsize
    ld 0 sp t3
    addi 16 sp sp
    bne rel:VX t3 a0
    ld TY_base s5 a0
    call tsize
    mv a0 t3
    la str_vor s6
    li 5 t0
    beq rel:VG t0 s4
    la str_vxor s6
    li 6 t0
    beq rel:VG t0 s4
    la str_vand s6
    li 7 t0
    beq rel:VG t0 s4
    li OP_eq t0
    beq rel:VE t0 s4
    li 9 t0
    beq rel:VN t0 s4
    VX:
    li 0 a0
    call bad
    VE:
    la str_veqb s6
    li 1 t0
    beq rel:VG t0 t3
    la str_veqw s6
    li 2 t0
    beq rel:VG t0 t3
    la str_veqd s6
    li 4 t0
    beq rel:VG t0 t3
    j VX
    VN:
    la str_vneb s6
    li 1 t0
    beq rel:VG t0 t3
    la str_vnew s6
    li 2 t0
    beq rel:VG t0 t3
    la str_vned s6
    li 4 t0
    beq rel:VG t0 t3
    j VX
    VG:
    call wtemp
    neg a0 a0
    li R_t1 a1
    call li
    mv s6 a0
    call seq
    mv s5 a0
    call setty
    leave3
", 6));

# ---- the SysV ABI: one xmm register, as a long double ----------------------------
reasm('x64class', "
    ld TY_kind s5 t1
    li TY_STRUCT t0
    bne rel:LI t0 t1
", "
    ld TY_kind s5 t1
    li TY_VECTOR t0
    beq rel:LQ t0 t1
    li TY_STRUCT t0
    bne rel:LI t0 t1
");
reasm('x64resclass', "
    ld TY_kind s4 t1
    li TY_STRUCT t0
", "
    ld TY_kind s4 t1
    li TY_VECTOR t0
    beq rel:LV t0 t1
    li TY_STRUCT t0
");
add_block('x64resclass', "
    LV:
    li 8 a0
    li 0 a1
    leave1
");
save();
