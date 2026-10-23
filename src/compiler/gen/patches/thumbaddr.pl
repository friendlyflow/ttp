# thumbaddr.pl: the address of a Thumb asm function as a value is its
# label + 1, as ld makes a Thumb function's address (bit 0, the state a bx
# or blx through it enters). arm's memchr resolver returned
# &__memchr_neon even, the ifunc's slot held it, and the call through it
# (blx) ran the Thumb code as A32: SIGILL in arm's stdio. gaddr, the address
# of a global or a function: + isthumb of its definition (0 but for an asm
# function whose first instruction is t. or t2., arm's Thumb). A direct
# call of one is cc_callt's blx to its label, as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'gaddr',
    "        L1:\n          mv\n            a0\n            a1\n          la\n            cc_auipc_a0\n            a0\n          call\n            seq\n          leave1\n",
    asm(8, "
    L1:
    addi -16 sp sp
    sd 0 a0 sp
    mv s4 a0
    call isthumb
    ld 0 sp a1
    addi 16 sp sp
    add a0 a1 a1
    la cc_auipc_a0 a0
    call seq
    leave1
"));
save();
