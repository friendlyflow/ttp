# asmentry.pl: asm names an entry of another asm function (a block label
# whose first child is asm, s2ff's for a function that runs on into the
# next): x86_64's __strncasecmp_l_evex jumps to __strcasecmp_l_evex, an
# entry of __strcasecmp_evex (strcmp-evex.S's OVERFLOW_STRCMP; avx2 and
# avx2_rtm too). C reached such a name already (casmentry), asm did not:
# eval_arg found only the labels in scope and the functions ("unknown
# name"). Now, before it stops, the placed labels: one named so whose
# first child is asm is its address.
#   eval_arg   entryfind where the name is no label in scope, no function
#   entryfind  the label record of the entry named a0 a1, or 0
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'eval_arg', "    L8:\n      la\n        msg_name\n",
    asm(4, "
    L8:
    mv s7 a0
    mv s8 a1
    call entryfind
    beqz L81 a0
    ld LABEL_addr a0 a0
    j L9
    L81:
    la msg_name a1
") =~ s/\n      la\n        msg_name\n        a1\n\z/\n      la\n        msg_name\n/r);
my ($from, $to) = find(\$t, 'eval_arg');
my $ind = (substr($t, $from) =~ /^( *)/)[0];
substr($t, $to, 0) = fn('entryfind', "
    addi -48 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    mv a0 s4
    mv a1 s5
    la labels_base t0
    ld 0 t0 s6
    EF1:
    la labels_end t0
    ld 0 t0 t0
    beq rel:EF8 s6 t0
    ld LABEL_node s6 s7
    lbu NODE_content_len s7 t0
    addi 1 s5 t1
    bne rel:EF7 t1 t0
    ld NODE_content s7 t2
    add s5 t2 t2
    lbu 0 t2 t2
    li 58 t1
    bne rel:EF7 t1 t2
    lbu NODE_children_len s7 t0
    beqz EF7 t0
    ld NODE_children s7 t0
    ld 0 t0 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    la str_asm a2
    li 3 a3
    call streq
    beqz EF7 a0
    ld NODE_content s7 a0
    mv s5 a1
    mv s4 a2
    mv s5 a3
    call streq
    beqz EF7 a0
    mv s6 a0
    j EF9
    EF7:
    addi LABEL_size s6 s6
    j EF1
    EF8:
    li 0 a0
    EF9:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    addi 48 sp sp
    ret
", length $ind);
save();
