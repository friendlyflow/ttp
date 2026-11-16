# asmfnaddr.pl: the address of an asm function is a function pointer too,
# as fnaddr.pl made a C function's, so that it can be called where it
# stands. arm's glibc backtrace calls ((void) x, &_Unwind_Backtrace)
# (helper, &arg), and there _Unwind_Backtrace is libgcc's asm
# (libunwind.S): addr gave it the type long, and the call through it
# stopped (cannot compile: :). Now its type is a function type made of its
# definition (TY_FUNC, the asm function its node), as a C function's; a
# call through it takes its result's type from the definition's leading
# type words, of which an asm function has none: a long, as a call of it
# by name gives. Run on ttpc.ff after fnaddr.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# addr (L13): an asm function (defkw asm) gets the function type a C
# function's definition (kind 1) gets
edit(\$t, 'cc/addr',
    "          call\n            kind\n          li\n            1\n            t0\n          bne\n            rel\n              L14\n            t0\n            a0\n",
    asm(10, "
    call kind
    li 1 t0
    beq rel:L15 t0 a0
    mv s5 a0
    call defkw
    li KW_asm t0
    bne rel:L14 t0 a0
") . "        L15:\n");
save();
