# startparam.pl: in _start a local first in the body with only its type
# is a local, not a parameter (the user's choice, 2026-11-14): nothing
# calls _start. Elsewhere such a local is one more parameter
# (language.ff.txt), so _start: / void / p: / big made p a parameter of
# the program's entry: on riscv64 and aarch64 a struct of more than 16
# bytes goes by its address, a0 or x0 at the entry, and writing p crashed
# the program; on x86_64 and arm it was the stack's words. No message
# (datacheck's tests kept such locals out of _start). Now fnbody counts no
# parameters for _start (startnp) and its loop over them stops at that
# count, so those declarations are the body's, as a later local with only
# its type is (the same frame slot, alignment and zeros). Test cstartparam
# (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/fnbody', asm(10, "
    call nparams
    mv a0 s11
") => asm(10, "
    call nparams
    mv s4 a1
    call startnp
    mv a0 s11
"));
edit(\$t, 'cc/fnbody', asm(8, "
L1:
    beqz L2 s5
") => asm(8, "
L1:
    beqz L2 s5
    bge rel:L2 s11 s7
"));

# startnp (a0 the count of parameters, a1 the function): 0 for _start
my ($from, $to) = find(\$t, 'cc/fnbody');
substr($t, $to, 0) = fn('startnp', "
    enter1
    mv a0 s4
    lbu NODE_content_len a1 t0
    li 7 t1
    bne rel:P9 t1 t0
    ld NODE_content a1 a0
    li 6 a1
    la ifnames a2
    addi 26 a2 a2
    li 6 a3
    call streq
    beqz P9 a0
    li 0 s4
P9:
    mv s4 a0
    leave1
", 6);
save();
