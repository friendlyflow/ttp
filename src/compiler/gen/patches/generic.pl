# generic.pl: C11's _Generic as the C layer's word generic (the user's
# choice, 2026-10-20):
#
#   generic
#     x
#     address char:
#       f
#     default:
#       g
#
# Its first child is the controlling expression, the others the
# associations, each a node named by its type words and a colon, holding
# its value, and default:. The value is that of the association whose type
# is x's (after C's lvalue conversion: an array is the address of its
# element, a function its address), else default's. x is not evaluated:
# its code is made for its type and taken back (the C layer's state, the
# assembler's place and labels as they were before it; the types it made
# stay). ttpc has no const, so a type C tells apart by a qualifier alone is
# one type here: the first such association is taken. An association's
# name is split into its type words, each a node, which typerun reads as
# the type words of a definition: "address " as often as the name starts
# with it, then the rest as one type name (long, struct x, fn1, long
# double, ...), which may have spaces of its own. (With the pointer words,
# base type first and then * pointer, the split is at a " * pointer" at
# the end instead: only gentype's loop changes.) With genericdefs in ttpc.defs.ff (KW_generic
# 52): run on ttpc.ff, then with T=ttpc.defs.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_imag:\n    addi\n      51\n      zero\n      a0\n",
        "  KW_imag:\n    addi\n      51\n      zero\n      a0\n  KW_generic:\n    addi\n      52\n      zero\n      a0\n", 'KW_imag');
    save();
    exit;
}

# the word, after imag
once(\$t, "va_arg_pack_len\\x00real\\x00imag\\x00\\x00\n", "va_arg_pack_len\\x00real\\x00imag\\x00generic\\x00\\x00\n", 'cc_kw');
once(\$t, "\n  cc_tynames:\n", "\n  gen_words:\n    ascii\n      default:address \\x00\n  cc_tynames:\n", 'cc_tynames');

# primary: generic is generic's
edit(\$t, 'cc/primary',
    "          li\n            KW_sizeof\n            t0\n          beq\n            rel\n              L47\n            t0\n            a0\n",
    "          li\n            KW_sizeof\n            t0\n          beq\n            rel\n              L47\n            t0\n            a0\n"
    . asm(10, "
    li KW_generic t0
    beq rel:LGN t0 a0
"),
    "        L9:\n          leave3\n",
    asm(8, "
    LGN:
    mv s4 a0
    call generic
    j L9
") . "        L9:\n          leave3\n");

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
my $fns = cfn('generic', "the value of generic a0: its association of x's type, else default's; x itself only for its type", "
    enter8
    mv a0 s4
    addi -288 sp sp
    # the state before x: the C layer's (ccs), the assembler's place and labels
    la ccs a0
    mv sp a1
    li CC_size a2
    call gcopy
    la cur_pc t0
    ld 0 t0 t1
    sd 192 t1 sp
    la out_end t0
    ld 0 t0 t1
    sd 200 t1 sp
    la label_next t0
    ld 0 t0 t1
    sd 208 t1 sp
    la in_bss t0
    ld 0 t0 t1
    sd 216 t1 sp
    # x alone, as an expression (a node of its own, x its one child), for its type
    addi 224 sp a0
    sb NODE_content_len zero a0
    li 1 t0
    sb NODE_children_len t0 a0
    ld NODE_children s4 t1
    sd NODE_children t1 a0
    call exprof
    call getty
    mv a0 s5
    # taken back, but for the types it made
    la ccs t0
    ld CC_types t0 s6
    mv sp a0
    la ccs a1
    li CC_size a2
    call gcopy
    la ccs t0
    sd CC_types s6 t0
    ld 192 sp t1
    la cur_pc t0
    sd 0 t1 t0
    ld 200 sp t1
    la out_end t0
    sd 0 t1 t0
    ld 208 sp t1
    la label_next t0
    sd 0 t1 t0
    ld 216 sp t1
    la in_bss t0
    sd 0 t1 t0
    addi 288 sp sp
    # C's lvalue conversion
    mv s5 a0
    call isarray
    beqz GA a0
    li TY_ADDRESS a0
    ld TY_base s5 a1
    li 0 a2
    call newtype
    mv a0 s5
    GA:
    mv s5 a0
    li TY_FUNC t1
    call iskind
    beqz GB a0
    li TY_ADDRESS a0
    mv s5 a1
    li 0 a2
    call newtype
    mv a0 s5
    GB:
    # the associations: s6 the one of x's type, s7 default's
    li 0 s6
    li 0 s7
    li 1 s8
    GL:
    lbu NODE_children_len s4 t0
    bgeu rel:GE t0 s8
    ld NODE_children s4 t0
    slli 3 s8 t1
    add t1 t0 t1
    ld 0 t1 s9
    addi 1 s8 s8
    ld NODE_content s9 a0
    lbu NODE_content_len s9 a1
    la gen_words a2
    li 8 a3
    call streq
    beqz GD a0
    mv s9 s7
    j GL
    GD:
    mv s9 a0
    call gentype
    bltz GX a0
    mv s5 a1
    call teq
    beqz GL a0
    mv s9 s6
    GE:
    bnez GC s6
    mv s7 s6
    bnez GC s6
    mv s4 a0
    call bad
    GC:
    mv s6 a0
    call exprof
    leave8
    GX:
    mv s9 a0
    call bad
", 6)
. cfn('gentype', "the type of the association a0's name, read by typerun from its words as nodes: address as often as it says, then a type name; below 0 if none", "
    enter5
    ld NODE_content a0 s4
    lbu NODE_content_len a0 s5
    addi -1 s5 s5
    addi -672 sp sp
    li 0 s6
    mv sp s7
    T1:
    li 8 t0
    bgeu rel:T2 s5 t0
    bgeu rel:T2 t0 s6
    mv s4 a0
    li 8 a1
    la gen_words a2
    addi 8 a2 a2
    li 8 a3
    call streq
    beqz T2 a0
    sb NODE_children_len zero s7
    li 7 t0
    sb NODE_content_len t0 s7
    la gen_words t0
    addi 8 t0 t0
    sd NODE_content t0 s7
    slli 3 s6 t1
    add t1 sp t1
    addi 576 t1 t1
    sd 0 s7 t1
    addi 64 s7 s7
    addi 1 s6 s6
    addi 8 s4 s4
    addi -8 s5 s5
    j T1
    T2:
    sb NODE_children_len zero s7
    sb NODE_content_len s5 s7
    sd NODE_content s4 s7
    slli 3 s6 t1
    add t1 sp t1
    addi 576 t1 t1
    sd 0 s7 t1
    addi 576 sp a0
    addi 1 s6 t0
    slli 3 t0 t0
    add t0 a0 a1
    call typerun
    addi 672 sp sp
    leave5
", 6)
. cfn('teq', "1 if the types a0 and a1 are the same type, else 0", "
    Q0:
    beq rel:Q1 a0 a1
    lui TY_REC t0
    bltu rel:Q8 t0 a0
    bltu rel:Q8 t0 a1
    ld TY_kind a0 t1
    ld TY_kind a1 t2
    bne rel:Q8 t1 t2
    li TY_ADDRESS t3
    beq rel:Q2 t3 t1
    li TY_ARRAY t3
    bne rel:Q3 t3 t1
    ld TY_count a0 t4
    ld TY_count a1 t5
    bne rel:Q8 t4 t5
    Q2:
    ld TY_base a0 a0
    ld TY_base a1 a1
    j Q0
    Q3:
    ld TY_base a0 t4
    ld TY_base a1 t5
    beq rel:Q1 t4 t5
    Q8:
    li 0 a0
    ret
    Q1:
    li 1 a0
    ret
", 6)
. cfn('gcopy', "a2 bytes, a word at a time, from a0 to a1", "
    C1:
    beqz C9 a2
    ld 0 a0 t0
    sd 0 t0 a1
    addi 8 a0 a0
    addi 8 a1 a1
    addi -8 a2 a2
    j C1
    C9:
    ret
", 6);
my ($af, $at) = find(\$t, 'cc/addr');
substr($t, $at, 0) = $fns;
save();
