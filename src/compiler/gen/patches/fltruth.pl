# fltruth.pl: a floating value as a condition is that value != 0 (the
# master's fault 36, tar on arm: double tape_length_option; ...
# tape_length_option && tape_length_option < record_size counted 0 as true).
# The conditions (jzv, jnzv: if, while, for, do while, ?:; boolv: && and ||;
# unseq's cc_not: !) tested the value's bits in a0 (a pair's in a0 a1): a
# value kept in memory (a double on arm, a long double everywhere) was its
# address, never 0, and -0.0 had bits too. Now fltruth makes a float,
# double or long double value the int of value != 0 (binop's compare with
# fcvt's 0 of its type) first: -0.0 is false, a NaN true. float16 and
# bfloat16 stay as they were (no conversion on arm). Test: progs/cfltcond.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
for my $f (qw(jzv jnzv)) {
    edit(\$t, "cc/$f", "        enter2\n        mv\n          a0\n          s4\n        call\n          getty\n" =>
        "        enter2\n        mv\n          a0\n          s4\n        call\n          fltruth\n        call\n          getty\n");
}
edit(\$t, 'cc/boolv', "        enter1\n        call\n          getty\n" => "        enter1\n        call\n          fltruth\n        call\n          getty\n");
edit(\$t, 'cc/unseq', "        enter2\n        mv\n          a0\n          s4\n        call\n          getty\n" =>
    "        enter2\n" . asm(8, "
    mv a0 s4
    la cc_not t0
    bne rel:UN1 t0 s4
    call fltruth
UN1:
    call getty
"));
{
    my ($from, $to) = find(\$t, 'cc/stmts');
    substr($t, $to, 0) = fn('fltruth', "
    enter2
    call getty
    mv a0 s4
    call fltty
    beqz F9 a0
    mv s4 a0
    call tsize
    li 2 t0
    beq rel:F9 t0 a0
    mv s4 a0
    call pushv
    li 0 a0
    li R_a0 a1
    call li
    li TY_INT a0
    call setty
    li TY_INT a0
    mv s4 a1
    call fcvt
    mv s4 a0
    call setty
    mv s4 a0
    call popv
    li 9 a0
    mv s4 a1
    mv s4 a2
    call binop
F9:
    leave2
", 6);
}
save();
