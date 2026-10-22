# fwdarr.pl: in the first pass, a name an expression of asm reads (the
# compile time addi of a symbol plus an offset, the user's choice B:
# leaq.p / addi / 512 / _nl_C_LC_CTYPE_tolower / a0 / r11) whose
# definition is not placed yet is 0 there, as a function's or a scalar
# global's is, also where the definition is an array's or a vector's (its
# first child a node with children): before, it was run as a macro (its
# items: "wrong number of arguments"). datasep.pl places writable globals
# at the end of the library's list, after the asm that names them.
#   eval_arg   fwdc of the definition's first child
#   fwdc       1 for a leaf, an array node or a vector node (by its
#              text: the assembler has no kwof)
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'eval_arg', join('', map { "      $_\n" } (
    "ld", "  NODE_children", "  s9", "  t0",
    "ld", "  0", "  t0", "  t0",
    "lbu", "  NODE_children_len", "  t0", "  t0",
    "bnez", "  L50", "  t0")),
    join('', map { "      $_\n" } (
    "ld", "  NODE_children", "  s9", "  t0",
    "ld", "  0", "  t0", "  a0",
    "call", "  fwdc",
    "beqz", "  L50", "  a0")));
my ($from, $to) = find(\$t, 'eval_arg');
my $ind = (substr($t, $from) =~ /^( *)/)[0];
substr($t, $to, 0) = fn('fwdc', "
    addi -16 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    mv a0 s4
    lbu NODE_children_len a0 t0
    beqz FW1 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    la str_array a2
    li 5 a3
    call streq
    bnez FW1 a0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    la str_vector a2
    li 6 a3
    call streq
    j FW9
    FW1:
    li 1 a0
    FW9:
    ld 0 sp ra
    ld 8 sp s4
    addi 16 sp sp
    ret
    str_array:
    ascii array
    str_vector:
    ascii vector
    align 4
", length $ind);
save();
