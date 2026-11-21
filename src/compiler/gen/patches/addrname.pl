# addrname.pl: name / & address of a name defined nowhere stopped nothing:
# addr took a name that is no local and no definition (cfind) for a label of
# the function (GNU C's &&name, golabel), which golabel makes for a goto
# that comes before its label; a label never placed kept address 0 or
# another's, so the program read garbage (a data label of an asm function,
# no entry, named from C: SIGSEGV). Now golabel clears a label it makes in
# pass 1 (label ids are reused: select, jit), and frame checks, after a
# function's body in pass 1, that each label golabel made for it was placed (gocheck), else
# stops "ttpc: unknown name: <name>", as a value or a call of such a name
# did; goto to a label the function lacks stops so too. weak / name
# & address of a name defined nowhere is 0 (fault 7's rule): addr's W1
# gives 0 while weakref is set, before golabel. Test: progs/caddrname*.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/addr', asm(8, "
W1:
    mv s4 a0
    call golabel
") => asm(8, "
W1:
    la weakref t0
    ld 0 t0 t0
    beqz W1G t0
    li 0 a0
    li R_a0 a1
    call li
    li TY_ADDRESS a0
    li 0 a1
    li 0 a2
    call newtype
    call setty
    leave2
W1G:
    mv s4 a0
    call golabel
"));

edit(\$t, 'cc/golabel', asm(8, "
L3:
    li32 4096 t0
    bgeu rel:L4 t0 s6
    call newlabel
    li 24 t0
") => asm(8, "
L3:
    li32 4096 t0
    bgeu rel:L4 t0 s6
    call newlabel
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:L3Z t1 t0
    slli 3 a0 t0
    la glabels t1
    add t0 t1 t1
    sd 0 zero t1
L3Z:
    li 24 t0
"));

edit(\$t, 'cc/frame', asm(8, "
    jalr 0 s5 ra
    li 0 a0
    call seclose
") => asm(8, "
    jalr 0 s5 ra
    call gocheck
    li 0 a0
    call seclose
"));
{
    my ($from, $to) = find(\$t, 'cc/frame');
    my $f = fn('gocheck', "
    enter2
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:G9 t1 t0
    la ccs t0
    ld CC_gbase t0 s4
    ld CC_ngoto t0 s5
G1:
    bgeu rel:G9 s5 s4
    li 24 t0
    mul t0 s4 t2
    la cc_vars t3
    add t2 t3 t3
    li32 131072 t2
    add t2 t3 t3
    ld 16 t3 a0
    slli 3 a0 a0
    la glabels t1
    add a0 t1 t1
    ld 0 t1 t1
    bnez G2 t1
    la msg_name a1
    li msg_name_len a2
    ld 0 t3 a3
    ld 8 t3 a4
    j die_name
G2:
    addi 1 s4 s4
    j G1
G9:
    leave2
", 6);
    $f =~ s/^(.*\n)/$1        comment\n          after a function's body: each label golabel made for it (a goto or & address before the label, or a name defined nowhere) was placed, else ttpc stops: unknown name\n/;
    substr($t, $to, 0) = $f;
}
save();
