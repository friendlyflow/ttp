# valpath.pl: a : of a wide value (valgroup.pl's vgroup) whose last item is
# a path into one of the group's own locals (t / a, a field of a struct
# local of the group) has its value copied out too, before the group gives
# its room back: vgroup copied only a name of one of them, so arm's
# vv: double / (: / (t: pt / pz) / (t / a)) read t's a after its room was
# given back (wrong on arm, whose double is in memory; tests2's armgrp). The
# type copied is the path's, the expression's (getty), the same in both
# passes: a local's field. Test: progs/cvalgroup.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'vgroup', asm(8, "
    ld -8 s7 t0
    lbu NODE_children_len t0 t1
    bnez V1 t1
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call vfind
    beqz V1 a0
    li VAR_sz t0
    mul t0 s4 t0
    la cc_vars t1
    add t0 t1 t1
    bltu rel:V1 t1 a0
    ld VAR_type a0 s8
") => asm(8, "
    ld -8 s7 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    lbu NODE_children_len t0 s8
    call vfind
    beqz V1 a0
    li VAR_sz t0
    mul t0 s4 t0
    la cc_vars t1
    add t0 t1 t1
    bltu rel:V1 t1 a0
    bnez VP s8
    ld VAR_type a0 s8
    j VQ
VP:
    call getty
    mv a0 s8
VQ:
"));
save();
