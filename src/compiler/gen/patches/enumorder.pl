# enumorder.pl: an enum constant of another page no longer hides a
# definition that comes before that page. leafval and gval look a leaf up
# as an enum constant (enumconst) before as a definition (cfind), and
# enumconst went from the scopes' enums to every definition page's
# (enumlib): glibc's enum constant string (locale/localeinfo.h's value_type,
# 1, on glibc's types page) won over tst-strxfrm's own global
# `char const string[]`, so strxfrm (NULL, string, 0) got 1 (lane
# tables-loc, x86_64). Now, after the scopes' enums:
#   the program's code: the enums of the program page's groups (pgenums;
#   the user's 1A), then a definition find_label finds (the program page,
#   its groups) stops the lookup, as cfind will find it;
#   library code (lib_grp, libscope.pl): not the program page's enums (a
#   library's C never sees them: they are the program's unit's, and an
#   enum constant has no linkage), its own group's enums, then a
#   definition of its own group stops the lookup;
# then every definition page's enums, as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'enumconst', asm(8, "
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
    la lib_grp t0
    ld 0 t0 a0
    beqz L7 a0
    li 0 a1
    call enumin
    bnez L9 a0
L7:
    mv s4 a0
    mv s5 a1
    call enumlib
") => asm(8, "
L1:
    la scopes t0
    la lib_grp t1
    ld 0 t1 t1
    beqz L2 t1
    addi 8 t0 t0
L2:
    beq rel:L8 t0 s6
    addi -8 s6 s6
    ld 0 s6 a0
    li 0 a1
    call enumin
    bnez L9 a0
    j L1
L8:
    la lib_grp t0
    ld 0 t0 a0
    beqz L5 a0
    li 0 a1
    call enumin
    bnez L9 a0
    la lib_grp t0
    ld 0 t0 a0
    li 0 a1
    call libl
    bnez L6 a0
    j L7
L5:
    la sec_prog t0
    ld 0 t0 a0
    beqz L4 a0
    li 0 a1
    call pgenums
    bnez L9 a0
L4:
    mv s4 a0
    mv s5 a1
    call find_label
    bnez L6 a0
L7:
    mv s4 a0
    mv s5 a1
    call enumlib
    j L9
L6:
    li 0 a0
"));
my ($from, $to) = find(\$t, 'enumconst/enumin');
my $f = fn('pgenums', "
    enter5
    mv a0 s6
    mv a1 s7
    lbu NODE_children_len a0 s8
    ld NODE_children a0 s6
P1:
    li 0 a0
    beqz P9 s8
    ld 0 s6 a0
    call is_layer
    beqz P2 a0
    li MAX_DEPTH t4
    bgeu rel:P3 t4 s7
    ld 0 s6 a0
    addi 1 s7 a1
    call pgenums
    bnez P9 a0
    j P3
P2:
    ld 0 s6 a0
    call is_group
    beqz P3 a0
    ld 0 s6 a0
    li 0 a1
    call enumin
    bnez P9 a0
P3:
    addi 8 s6 s6
    addi -1 s8 s8
    j P1
P9:
    leave5
", 8);
$f =~ s/^(.*\n)/$1          comment\n            the value of enumconst's name s4 s5 among the enums of a group among the children of a0 (the program page), through its layers (a1 deep); 0 if none has it\n/;
substr($t, $to, 0) = $f;
save();
