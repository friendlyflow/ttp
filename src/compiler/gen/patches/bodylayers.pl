# bodylayers.pl: a function's statements past what a node holds come in
# layers, 0: 1: ... (the user's overflow of a node, language.ff.txt), each
# holding whole statements (c2ff: glibc's __ieee754_powl has 464 nodes):
# fnbody, which hands the statements after the parameters to treserve,
# ccalloca and stmts as a run of node pointers, makes that run with each
# layer's children in its place (in cc_flat, a bump area).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'fnbody',
    "        L11:\n          mv\n            s4\n            a0\n          call\n            startinit\n",
    asm(8, "
L11:
    call LFX
    mv s4 a0
    call startinit
"));
{
    my ($from, $to) = find(\$t, 'fnbody');
    substr($t, $to, 0) = asm(8, "
LFX:
    # s6, s5: the statements' pointers and their count, a layer's
    # children in its place
    addi -16 sp sp
    sd 0 ra sp
    slli 3 s5 a1
    add s6 a1 a1
    mv s6 a2
    j LF1
LF1:
    bgeu rel:LF9 a1 a2
    ld 0 a2 a0
    call is_layer
    bnez LF2 a0
    addi 8 a2 a2
    j LF1
LF2:
    la cc_flatp t0
    ld 0 t0 a5
    bnez LF3 a5
    la cc_flat a5
    j LF3
LF3:
    # (a fresh start where the area has less than 64 KiB left)
    la cc_flat t1
    li32 983040 t2
    add t2 t1 t2
    bltu rel:LF4 t2 a5
    mv t1 a5
    j LF4
LF4:
    mv a5 a4
    mv s6 a2
    j LF5
LF5:
    bgeu rel:LF7 a1 a2
    ld 0 a2 a0
    mv a0 a7
    call is_layer
    bnez LF6 a0
    sd 0 a7 a5
    addi 8 a5 a5
    addi 8 a2 a2
    j LF5
LF6:
    ld NODE_children a7 t5
    lbu NODE_children_len a7 t6
    slli 3 t6 t6
    add t5 t6 t6
    j LF61
LF61:
    bgeu rel:LF62 t6 t5
    ld 0 t5 t0
    sd 0 t0 a5
    addi 8 a5 a5
    addi 8 t5 t5
    j LF61
LF62:
    addi 8 a2 a2
    j LF5
LF7:
    la cc_flatp t0
    sd 0 a5 t0
    mv a4 s6
    sub a4 a5 s5
    srli 3 s5 s5
    j LF9
LF9:
    ld 0 sp ra
    addi 16 sp sp
    ret
");
}
once(\$t, "\n  ccs:\n", "\n  cc_flatp:\n    reserve\n      8\n  cc_flat:\n    reserve\n      1048576\n  ccs:\n", 'ccs');
save();
