# cmpdcvt.pl: an assignment or a local's value converts to its left side's
# type, as a cast does (the master's fault 23, 2026-11-24, found by tests2,
# and the user's choice A for = and a declaration's value): C's long long
# y; double d; y -= d; is y = (long long) ((double) y - d), y = d is y =
# (long long) d, double e = i is (double) i. expr made the value (a
# compound one with binop, in double by the usual arithmetic conversions)
# and stored it as y's type with no conversion (wassign only converts to a
# wide float), and so did decl (a local's value) and linit (a local
# aggregate's item): the double's bits were stored as the integer and the
# integer's as the double (0 for 100 - 48.0 on riscv64, x86_64 and
# aarch64; arm wrong for large values). Now where the value or the type is
# floating (fltty), fcvt converts the value to the type (s7), as a cast
# does; an integer truncates toward zero: in expr at L3 (= and the compound
# ones), decl at L8, linit at L4 after its expr. Test: progs/ccmpdcvt.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cvt {
    my ($ind) = @_;
    asm($ind + 2, "
    call getty
    call fltty
    bnez LQC a0
    mv s7 a0
    call fltty
    beqz LQ9 a0
") . asm($ind, "
LQC:
    call getty
    mv s7 a1
    call fcvt
    mv s7 a0
    call setty
LQ9:
    mv s7 s7
");
}
edit(\$t, 'cc/expr', "          call\n            binop\n        L3:\n" => "          call\n            binop\n        L3:\n" . cvt(8));
edit(\$t, 'cc/decl', "        L8:\n          mv\n            s7\n            a0\n          call\n            pwassign\n" =>
    "        L8:\n" . cvt(8) . "          mv\n            s7\n            a0\n          call\n            pwassign\n");
edit(\$t, 'cc/linit', "        L4:\n          li\n            1\n            a0\n          call\n            expr\n          mv\n            s7\n            a0\n          call\n            pwassign\n" =>
    "        L4:\n          li\n            1\n            a0\n          call\n            expr\n" . cvt(8) . "          mv\n            s7\n            a0\n          call\n            pwassign\n");
save();
