# vecops.pl: GNU C's vectors on every target, element by element where a
# target has no instruction for them, as gcc makes them without SIMD.
# After vector.pl (the type, x86_64's | ^ & == != with SSE2).
#
#   typerun   a vector is a type on every target, not x86_64's alone; on
#             the others it is in memory as a struct of its elements (its
#             ABI a struct's: ttpc's own calls)
#   index     a vector's subscript, v . i (C's v[i]): the element at the
#             vector's address + i * the element's size, an lvalue of the
#             element's type, as an array's (sincosf_poly.h's p->s2c3[0],
#             v2df_to_sf's v4sf[0])
#   vbin      every operator of two vectors of one type but x86_64's | ^ &
#             == != (SSE2, vector.pl): vgen
#   vgen      the operator a0 of a vector type a1, the operands' types a2
#             a3 (L the left one, V the right one: a vector's address, a
#             scalar's value, converted to the element's type and used for
#             each element, gcc's v << 2, v * 2.0), element by element: each
#             pair of elements loaded (or, of a type in memory, its
#             address), binop of the element's type, its result stored
#             into a wide temporary (16 bytes, two for 32) at the
#             element's offset; a comparison's element is 0 or -1 (gcc's:
#             its 1 negated). V the temporary's address, the vector's type.
#             Both addresses wait on the stack (push), read back by the
#             depth (fpword), as copyst does.
# Test: progs/cvecops (every target).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
sub reasm {
    my ($name, $old, $new) = @_;
    my ($from, $to) = find(\$t, $name);
    my $e = substr($t, $from, $to - $from);
    my ($ind) = grep { my $o = asm($_, $old); () = $e =~ /^\Q$o\E/mg } map { indent_of($name) + $_ } 2, 4, 6, 8, 10;
    defined $ind or die "vecops: $name: not found\n";
    once(\$e, asm($ind, $old), asm($ind, $new), $name);
    substr($t, $from, $to - $from) = $e;
}
sub add_block { my ($name, $src) = @_; after_fn($name, asm(indent_of($name) + 2, $src)) }

# the primitives by name (seq)
once(\$t, "  cc_jalr_t0:\n    ascii\n      \\x00cc_call_l\\x00\n",
    "  cc_jalr_t0:\n    ascii\n      \\x00cc_call_l\\x00\n  str_vswap:\n    ascii\n      \\x00cc_swap\\x00\n", 'cc_jalr_t0');

# ---- every target --------------------------------------------------------------
reasm('typerun', "
    VV:
    la targ_abi t0
    ld 0 t0 t0
    li 3 t1
    bne rel:VS t1 t0
", "
    VV:
");

# ---- a vector's subscript --------------------------------------------------------
reasm('index', "
    call isstruct
    bnez L3 a0
    mv s7 a0
    call isaddr
    beqz L8 a0
", "
    call isstruct
    bnez L3 a0
    mv s7 a0
    call isvector
    bnez LV a0
    mv s7 a0
    call isaddr
    beqz L8 a0
");
add_block('index', "
    LV:
    call push
    li 1 a0
    call expr
    ld TY_base s7 a0
    mv a0 s8
    call tsize
    li R_t1 a1
    call li
    la cc_mul_a0_t1 a0
    call seq
    call popt0
    la cc_add_t0 a0
    call seq
    mv s8 a0
    call setty
    j L4
");

# ---- the operators: element by element -----------------------------------------
reasm('vbin', "
    mv s5 a0
    call isvector
    beqz VX a0
    mv s6 a0
    call isvector
    beqz VX a0
", "
    mv s5 a0
    call isvector
    beqz VM a0
    mv s6 a0
    call isvector
    beqz VM a0
");
reasm('vbin', "
    bne rel:VX t3 a0
    ld TY_base s5 a0
", "
    bne rel:VX t3 a0
    li 16 t0
    bltu rel:VP t0 s4
    li 19 t0
    bltu rel:VP s4 t0
    j VQ
    VP:
    la targ_abi t0
    ld 0 t0 t0
    li 3 t1
    bne rel:VQ t1 t0
    li 5 t0
    bltu rel:VQ t0 s4
    li 9 t0
    bltu rel:VQ s4 t0
    j VR
    VQ:
    mv s4 a0
    mv s5 a1
    mv s5 a2
    mv s6 a3
    call vgen
    leave3
    VR:
    ld TY_base s5 a0
");
# a vector and a scalar (either side): the scalar for each element (gcc's)
add_block('vbin', "
    VM:
    mv s5 a0
    call isvector
    mv s5 a1
    bnez VM1 a0
    mv s6 a1
    VM1:
    mv s4 a0
    mv s5 a2
    mv s6 a3
    call vgen
    leave3
");
after_fn('vbin', fn('vgen', "
    enter8
    addi -32 sp sp
    sd 16 a2 sp
    sd 24 a3 sp
    sd 8 zero sp
    mv a0 s4
    mv a1 s5
    ld TY_base s5 s6
    mv a2 a0
    call isvector
    bnez G0 a0
    li 1 t0
    sd 8 t0 sp
    G0:
    ld 24 sp a0
    call isvector
    bnez G00 a0
    li 2 t0
    sd 8 t0 sp
    G00:
    mv s6 a0
    call tsize
    mv a0 s7
    mv s5 a0
    call tsize
    mv a0 s8
    call wtemp
    mv a0 s9
    li 32 t0
    bne rel:G1 t0 s8
    call wtemp
    mv a0 s9
    G1:
    call push
    la ccs t0
    ld CC_depth t0 t1
    sd 0 t1 sp
    la str_vswap a0
    call seq
    call push
    la ccs t0
    ld CC_depth t0 s11
    li 0 s10
    GL:
    bgeu rel:GD s8 s10
    mv s11 a0
    call fpword
    ld 8 sp t0
    li 1 t1
    beq rel:GS1 t1 t0
    mv s10 a0
    li R_t0 a1
    call li
    la cc_add_t0 a0
    call seq
    mv s6 a0
    call fwide
    bnez G2 a0
    mv s6 a0
    call load
    G2:
    call push
    ld 0 sp a0
    call fpword
    ld 8 sp t0
    li 2 t1
    beq rel:GS2 t1 t0
    mv s10 a0
    li R_t0 a1
    call li
    la cc_add_t0 a0
    call seq
    mv s6 a0
    call fwide
    bnez G3 a0
    mv s6 a0
    call load
    G3:
    call popt0
    mv s4 a0
    mv s6 a1
    mv s6 a2
    call binop
    li 8 t0
    bltu rel:G4 t0 s4
    li 13 t0
    bltu rel:G4 s4 t0
    la cc_neg a0
    call seq
    G4:
    neg s9 a0
    add s10 a0 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s6 a0
    call fwide
    bnez G5 a0
    mv s6 a0
    call store
    j G6
    G5:
    mv s6 a0
    call copytype
    G6:
    add s7 s10 s10
    j GL
    GD:
    call popt0
    call popt0
    neg s9 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s5 a0
    call setty
    addi 32 sp sp
    leave8
    GS1:
    ld 16 sp a0
    mv s6 a1
    call fcvt
    j G2
    GS2:
    ld 24 sp a0
    mv s6 a1
    call fcvt
    j G3
", indent_of('vbin')));

# ---- riscv64's and aarch64's ABI: a vector is a struct of its bytes, its
# words in integer registers (or memory), never a struct of floats (rvflat,
# hfa: 0 for a vector), as ttpc calls ttpc's (arm's and x86_64's had theirs)
for my $f (qw(rvresclass rvclass a64resclass a64class)) {
    my $done = 0;
    for my $r (qw(s4 s5)) {
        next unless eval { reasm($f, "
    ld TY_kind $r t1
    li TY_STRUCT t0
", "
    ld TY_kind $r t1
    li TY_VECTOR t0
    xor t1 t0 t2
    seqz t2 t2
    li -3 t0
    mul t0 t2 t2
    add t2 t1 t1
    li TY_STRUCT t0
"); 1 };
        $done = 1;
    }
    $done or die "vecops: $f: no kind check\n";
}
# (the wrappers before rvflat's: hfa's own group of the tree is full)
my ($rf) = find(\$t, 'rvflat');
my $rind = (substr($t, $rf) =~ /^( *)/)[0];
for my $f (qw(rvflat hfa)) {
    my ($from) = find(\$t, $f);
    my $ind = (substr($t, $from) =~ /^( *)/)[0];
    once(\$t, "\n$ind$f:\n", "\n$ind${f}0:\n", $f);
}
($rf) = find(\$t, 'rvflat0');
substr($t, $rf, 0) = join '', map { fn($_, "
    lui TY_REC t0
    bltu rel:W1 t0 a0
    ld TY_kind a0 t1
    li TY_VECTOR t0
    bne rel:W1 t0 t1
    li 0 a0
    ret
    W1:
    j ${_}0
", length $rind) } qw(rvflat hfa);
save();
