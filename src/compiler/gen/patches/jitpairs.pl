# jitpairs.pl (fault 27): compile time on a host whose word is 4 bytes (arm)
# computes i64, u64 and an 8-byte long as pairs, as the arm target does
# (pairs.pl): the arithmetic of a global's item worked out while compiling
# was the host's 32-bit word there (cast / i64 / 1 << 40 was a 32-bit lsl),
# and its value came back as r0 alone (a double's, in memory on arm, as its
# address), so ttpc built on arm made other bytes than on a 64-bit host.
# Now, while compiling on such a host (pairson: CC_jit and the host's name
# is arm's, 3 bytes), tyname gives i64 and u64 their pair codes, ctlong a
# long of an 8-byte target (ct_targ) i64's, numlit a literal past 32 bits a
# pair; the body of a JIT run (exprbody, pairbody) leaves its value as the
# pair r0:r1 (jitpair: a word extended by its signedness, a float's bits
# zero-extended, an 8-byte value in memory loaded), which rv.jitcall
# (macros/arm.ff.txt) keeps whole; ctrun sign-extends the word of a
# compile time function's run (its value a host long). Outside compile
# time and on 64-bit hosts nothing changes. Test: cjitpair (4 targets, and
# chello-arm: built on arm, the bytes riscv64's ttpc makes).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

{
    my ($from) = find(\$t, 'tyname');
    substr($t, $from, 0) = fn('pairson', "
    la ccs t0
    ld CC_jit t0 t0
    bnez P1 t0
    la targ_word t0
    ld 0 t0 t0
    addi -4 t0 t0
    seqz t0 t0
    ret
P1:
    li host_name_len t0
    addi -3 t0 t0
    seqz t0 t0
    ret
", 6) . fn('wide8', "
    la targ_word t0
    ld 0 t0 t0
    addi -8 t0 t0
    bnez W0 t0
    la ccs t0
    ld CC_jit t0 t0
    beqz W1 t0
    li host_name_len t0
    addi -3 t0 t0
    beqz W0 t0
W1:
    li 1 t0
    ret
W0:
    li 0 t0
    ret
", 6) . fn('jitpair', "
    enter1
    li host_name_len t0
    li 3 t1
    bne rel:J9 t1 t0
    call getty
    mv a0 s4
    call ispair
    bnez J9 a0
    mv s4 a0
    call inmem
    beqz J2 a0
    mv s4 a0
    call tsize
    li 8 t0
    bne rel:J9 t0 a0
    li 72 a0
    call load
    li 72 a0
    call setty
    j J9
J2:
    mv s4 a0
    call tscalar
    andi 32 a0 t0
    beqz J3 t0
    li TY_U32 a0
J3:
    li 0 a1
    call pext
    li 72 a0
    call setty
J9:
    leave1
", 6);
}

# tyname: i64 and u64 are pairs where pairson says so
edit(\$t, 'tyname', asm(8, "
L2:
la ccs t0
ld CC_jit t0 t0
bnez L3 t0
la targ_word t0
ld 0 t0 t0
li 8 t1
beq rel:L3 t1 t0
addi -7 a0 a0
") => asm(8, "
L2:
call pairson
beqz L3 t0
addi -7 a0 a0
"));

# ctlong: while compiling (ct_targ) on an arm host, an 8-byte target's long is i64's pair
edit(\$t, 'ctlong', asm(10, "
addi -8 t0 t0
beqz L9 t0
li 4 a0
ret
") => asm(10, "
addi -8 t0 t0
beqz LH t0
li 4 a0
ret
") . asm(8, "
LH:
li 3 t0
bne rel:L9 t0 a0
li host_name_len t0
li 3 t1
bne rel:L9 t1 t0
li 72 a0
ret
"));

# numlit: a literal past 32 bits is a pair where pairson says so
edit(\$t, 'numlit', asm(10, "
la targ_word t0
ld 0 t0 t0
li 4 t1
bne rel:L1 t1 t0
la ccs t0
ld CC_jit t0 t0
bnez L1 t0
li 64 t0
") => asm(10, "
call pairson
beqz L1 t0
li 64 t0
"));

# the bodies of a JIT run leave their value as a pair on an arm host
edit(\$t, 'exprbody', asm(8, "
call primary
") => asm(8, "
call primary
call jitpair
"));
edit(\$t, 'pairbody', asm(8, "
call expr
") => asm(8, "
call expr
call jitpair
"));

# ctrun: a compile time function's word, sign-extended on an arm host
edit(\$t, 'ctrun', asm(10, "
mv s5 a1
call jit
mv a0 s5
") => asm(10, "
mv s5 a1
addi -16 sp sp
sd 0 s5 sp
call jit
mv a0 s5
"), asm(10, "
jitcall s5
sd 8 a0 s6
") => asm(10, "
jitcall s5
sd 8 a0 s6
ld 0 sp t0
addi 16 sp sp
li host_name_len t1
li 3 t2
bne rel:JS9 t2 t1
la ctconst t1
beq rel:JS9 t1 t0
la pairconst t1
beq rel:JS9 t1 t0
la ctexpr t1
beq rel:JS9 t1 t0
ld 8 s6 t1
slli 32 t1 t1
srai 32 t1 t1
sd 8 t1 s6
") . asm(8, "
JS9:
"));
# a pair is i128 on a target of 8-byte words, but i64 while compiling on an arm host (wide8)
edit(\$t, 'cc/common', asm(10, "
la targ_word t0
ld 0 t0 t0
li 8 t2
beq rel:L21 t2 t0
") => asm(10, "
call wide8
bnez L21 t0
"));
for my $f ('ptof', 'ftop') {
    edit(\$t, $f, asm(8, "
la targ_word t0
ld 0 t0 t0
li 8 t1
beq rel:LW8 t1 t0
") => asm(8, "
call wide8
bnez LW8 t0
"));
}
edit(\$t, 'pdiv', asm(10, "
la targ_word t0
ld 0 t0 t0
li 8 t1
bne rel:L8 t1 t0
") => asm(10, "
call wide8
beqz L8 t0
"));
edit(\$t, 'ppload', asm(8, "
la targ_word t0
ld 0 t0 t0
li 8 t1
bne rel:L9 t1 t0
") => asm(8, "
call wide8
beqz L9 t0
"));
edit(\$t, 'pnarrow', asm(8, "
la targ_word t0
ld 0 t0 t0
li 8 t1
bne rel:L9 t1 t0
") => asm(8, "
call wide8
beqz L9 t0
li 8 t1
"));
save();
