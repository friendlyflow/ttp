# locarr.pl: a local char array's leaf item is its text, as a global's
# (charitem.pl; the master's fault 12, 2026-11-21): linit compiled a: /
# array / char / 4 / abc as the expression abc (unknown name, or the value of
# the global or local abc in its first element). Now linit, filling an array
# of one-byte elements, asks istext (text_item, a number stays a char's
# value) and stores the text's bytes in the elements from the current one,
# and its NUL where there is room (C: char a[3] = "abc" has none). csema
# writes a local's text as numbers: this is the form of ff by hand.
# Test: progs/clocaltext.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $byte = "
    mv a0 s9
    mv s4 a0
    mv s6 a1
    call member
    mv a0 s8
    mv a1 s7
    mv s9 a0
    li R_a0 a1
    call li
    li TY_LONG a0
    call setty
    mv s7 a0
    call pwassign
    sub s5 s8 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s7 a0
    call store
";
my $old = "          LZ1:\n          mv\n            s7\n            a0\n          call\n            fwide\n";
my $new = "          LZ1:\n" . asm(10, "
    mv a0 s9
    lbu NODE_children_len a0 t0
    bnez LZN t0
    mv s4 a0
    call isarray
    beqz LZN a0
    ld TY_base s4 a0
    call tsize
    li 1 t0
    bne rel:LZN t0 a0
    la text_item t0
    li 1 t1
    sd 0 t1 t0
    mv s9 a0
    call istext
    la text_item t0
    sd 0 zero t0
    bnez LTX a0
") . "          LZN:\n" . asm(10, "
    mv s9 a0
") . "          mv\n            s7\n            a0\n          call\n            fwide\n";
edit(\$t, 'cc/linit', $old => $new);
edit(\$t, 'cc/linit', asm(8, "
L9:
    leave8
") => asm(8, "
L9:
    leave8
LTX:
    call next
    ld NODE_content s9 s10
    lbu NODE_content_len s9 s11
LT1:
    beqz LTZ s11
    ld TY_count s4 t0
    bge rel:LT9 t0 s6
    lbu 0 s10 a0
$byte
    addi 1 s10 s10
    addi -1 s11 s11
    addi 1 s6 s6
    j LT1
LTZ:
    ld TY_count s4 t0
    bge rel:LT9 t0 s6
    li 0 a0
$byte
    addi 1 s6 s6
LT9:
    j L1
"));
save();
