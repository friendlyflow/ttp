# asmalignpage.pl: an asm function of the program page whose first child
# after asm is align / n is placed at a multiple of n, as one of a library
# page is (asmalign.pl, the user's choice of 2026-10-19). cc_library ran
# asmalign before placing a library's function; the program page's items go
# through cc, which gives an asm function (kind 0) back to the assembler to
# place where it stands: its align was then padding inside the function,
# after its label, and a call ran into the padding (zeros: SIGILL on
# riscv64). Now cc runs asmalign on such an item before the assembler
# places it; in the body the align is then nothing.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc', asm(4, "
L1:
    mv s4 a0
    call kind
    beqz L9 a0
") => asm(4, "
L1:
    mv s4 a0
    call kind
    beqz LAL a0
"), asm(4, "
L9:
    leave2
") => asm(4, "
L9:
    leave2
LAL:
    mv s4 a0
    call asmalign
    li 0 a0
    leave2
"));
save();
