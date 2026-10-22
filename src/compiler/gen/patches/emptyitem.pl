# emptyitem.pl: an empty : as a scalar item of a global (C's {}, a zero;
# c2ff writes one where a designated initializer leaves a gap, as locale's
# _nl_value_type_LC_CTYPE) is 0 in gval; it went to the compile time JIT
# ("unknown name: :"). So too an item of a local's literal (linit: the
# local is zero before its items).
# Test: cemptyitem. Run on ttpc.ff after textitem.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $leaf = "        bnez\n          L10\n          t0\n";
edit(\$t, 'gval', $leaf, $leaf . asm(8, "
    lbu NODE_content_len s5 t0
    li 1 t1
    bne rel:LZN t1 t0
    ld NODE_content s5 t0
    lbu 0 t0 t0
    li 58 t1
    bne rel:LZN t1 t0
    li 0 a0
    addi 8 s4 a1
    j L9
LZN:
    mv s5 a0
"));
my $wide = "          mv\n            s7\n            a0\n          call\n            fwide\n";
edit(\$t, 'linit', $wide, asm(10, "
    call peek
    lbu NODE_children_len a0 t0
    bnez LZ1 t0
    lbu NODE_content_len a0 t0
    li 1 t1
    bne rel:LZ1 t1 t0
    ld NODE_content a0 t0
    lbu 0 t0 t0
    li CH_colon t1
    bne rel:LZ1 t1 t0
    call next
    j L5
LZ1:
") . $wide);
save();
