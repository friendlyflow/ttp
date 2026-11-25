# rjassign.pl: x = setjmp (...) works out x's address after the call (the
# master's fault 26: gawk 5.4's minrx.c:1883 if ((err = setjmp
# (c->errjmp)) != 0) died on the second return). expr pushed the address
# of the left side before it compiled the right one; a function that
# returns twice saved the stack pointer below that slot, the calls after
# its first return wrote over the slot, and at the second return (after
# longjmp) the store went through what they had left there. Now a plain =
# whose right side is a call of a function that returns twice, by its name
# as gcc knows them (setjmp, sigsetjmp, savectx, vfork, getcontext,
# qsetjmp, with _ or __ before it, and __builtin_setjmp), compiles the
# right side first, pushes its value, works out the address, and swaps
# the two (pop, push, a0 = 0 + t0) before the store as before
# (rjassign). Test: progs/csetjmp (+ csetjmpdefs: a setjmp and a longjmp
# of each target).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

edit(\$t, 'expr',
    "          mv\n            s6\n            a0\n          call\n            addr\n        LPA:\n" =>
    asm(10, "
    mv s5 a0
    mv s6 a1
    call rjassign
    mv a1 s7
    bnez L3 a0
    mv s6 a0
    call addr
") . "        LPA:\n");

my @names = map { ($_, "_$_", "__$_") } qw(setjmp sigsetjmp savectx vfork getcontext qsetjmp);
my $tab = join('', map { "$_\\x00" } @names, '__builtin_setjmp') . '\\x00';
{
    my ($from, $to) = find(\$t, 'expr');
    substr($t, $to, 0) =
      cfn('rjassign', "expr's x = f (...) for an f that returns twice (rjname), a0 the operator (0 is =), a1 x: the call first, its value pushed, then x's address, swapped; a0 1 (a1 x's type) when it did, else 0 and nothing done", "
    enter5
    mv a1 s4
    li 0 s5
    bnez R9 a0
    la ccs t0
    ld CC_cur t0 t1
    ld CC_end t0 t2
    addi 8 t1 t1
    bgeu rel:R9 t2 t1
    ld 0 t1 a0
    beqz R9 a0
    call rjname
    bltz R9 a0
    call next
    li 1 a0
    call expr
    call getty
    mv a0 s6
    call push
    mv s4 a0
    call addr
    call getty
    mv a0 s7
    call popt0
    call push
    li 0 a0
    li R_a0 a1
    call li
    la cc_add_t0 a0
    call seq
    mv s6 a0
    call setty
    li 1 s5
R9:
    mv s5 a0
    mv s7 a1
    leave5
", 6) .
      cfn('rjname', "the index of the function a0 names among those that return twice (gcc's special_function_p), or -1", "
    la rj_names a1
    j lookup
rj_names:
    ascii $tab
    align 4
", 6);
}
save();
