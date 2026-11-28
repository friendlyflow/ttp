# vapackfix.pl: a call ending in va_arg_pack whose arguments before it are
# not its function's own stops with a message that says so (the master's
# fault 34). x64call, a64call and rvcall (whose va_arg_pack passes on the
# registers the function kept and its incoming stack, vapackstk.pl) and
# abicall (arm) take only fixed arguments that sit where the function's own
# did (the same registers, none on the stack); another call stopped with
# bad(0): "cannot compile: " and no name. Now vafixbad names the callee
# (or says a function pointer). Test: progs/cvapackfixfail (ctime, every target).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $msg = "ttpc: va_arg_pack goes last in a call whose arguments before it are its function's own (as many, of the same kinds; none on the stack): ";
for my $f (qw(x64call a64call rvcall)) {
    edit(\$t, $f, "        LX:\n          li\n            0\n            a0\n          call\n            bad\n" =>
        "        LX:\n          mv\n            s5\n            a0\n          call\n            vafixbad\n");
}
edit(\$t, 'abicall', "          beqz\n            L4\n            t1\n          li\n            0\n            a0\n          call\n            bad\n" =>
    "          beqz\n            L4\n            t1\n          mv\n            s5\n            a0\n          call\n            vafixbad\n");
{
    my ($from, $to) = find(\$t, 'cc/stmts');
    my $esc = $msg; $esc =~ s/ $/\\x20/;
    substr($t, $to, 0) = fn('vafixbad', "
    la VM a1
    li " . length($msg) . " a2
    bnez VN a0
    j die
VN:
    ld NODE_content a0 a3
    lbu NODE_content_len a0 a4
    add a4 a3 t0
    lbu -1 t0 t0
    addi -58 t0 t0
    seqz t0 t0
    sub t0 a4 a4
    j die_name
", 6) . "        VM:\n          ascii\n            $esc\n          align\n            4\n";
}
save();
