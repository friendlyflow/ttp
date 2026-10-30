# ctemitval.pl: the value of a lambda that emits is the value of what it
# emits, as the emitted subtrees stand where the lambda is (: / compile
# time / emit / 7 is 7). ctval compiled the splices, then overwrote a0 with
# the JIT's own return (an address of the compile's: garbage), on any page.
# Now it keeps the splices' value when there are any (CT_lnspl of ctrun's
# result), and gives the JIT's return only to a lambda that emits nothing.
# Test: cctemit.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/ctval', "        enter1\n        call\n          ctrun\n        mv\n          a0\n          s4\n        call\n          splices\n",
    asm(8, "
    enter2
    call ctrun
    mv a0 s4
    la cts t0
    ld CT_lnspl t0 s5
    call splices
    bnez L9 s5
"), "        leave1\n", asm(8, "
L9:
    leave2
"));
save();
