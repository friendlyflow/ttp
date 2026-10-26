# localtalign.pl: a local whose type is aligned past a slot (a long double,
# a struct of one, a struct with an aligned (16) field) at a multiple of
# that alignment, as its explicit align n (localalign.pl) was: declare
# takes the larger of the two. The frame's base is 16-aligned where the
# target's ABI keeps the stack so (riscv64's lp64d, aarch64, x86_64), so up
# to 16 holds (tst-makecontext2's long double _ld was 8 off; arm's 8). Past 16
# (tst-makecontext-align's aligned (32)) the frame's base would need
# aligning first: not done. After localalign.pl. Test: cldalign.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $old = asm(8, "
L1:
    mv a0 s6
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call alval
    la ccs t0
");
edit(\$t, 'cc/declare', $old, asm(8, "
L1:
    mv a0 s6
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 a1
    call alval
    addi -16 sp sp
    sd 0 a0 sp
    mv s5 a0
    call talign
    sd 8 a0 sp
    call slot
    mv a0 t2
    ld 8 sp a0
    ld 0 sp t3
    addi 16 sp sp
    bge rel:LB a0 t2
    bgeu rel:LB a0 t3
    mv a0 t3
LB:
    mv t3 a0
    la ccs t0
"));
save();
