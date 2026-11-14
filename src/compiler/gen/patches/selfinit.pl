# selfinit.pl: a scalar local is declared before its item is worked out, as
# C's scope of a declarator begins before its initializer: glibc's
# sem_open, int state = __pthread_setcancelstate (PTHREAD_CANCEL_DISABLE,
# &state), stopped ttpc ("used before it is declared: state": decl worked
# out the call first, where state was no local yet and became a global's
# label; found by src/glibc's datacheck). Now decl declares it first (as it
# did for a struct, union or array), then works out the item and stores it.
# Test cselfinit (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'decl', asm(8, "
    beqz L5 s8
    call peek
") => asm(8, "
    mv s4 a0
    mv s7 a1
    call declare
    mv a0 s9
    mv s9 a0
    li 1 a1
    call walocal
    call syncsp
    beqz L5 s8
    call peek
"), asm(8, "
L8:
    mv s7 a0
    call pwassign
    mv s4 a0
    mv s7 a1
    call declare
    mv a0 s9
    mv s9 a0
    li 1 a1
    call walocal
    call syncsp
    mv s9 a0
    call vaddrt0
") => asm(8, "
L8:
    mv s7 a0
    call pwassign
    mv s9 a0
    call vaddrt0
"));
save();
