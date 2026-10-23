# jitcall.pl: compile time (a global's item that is no constant, run by the
# JIT) that calls a function with no code there yet stops with its name;
# the call went to address 0 and ttpc died of it (a global's item calling
# __builtin_huge_val: tst-strtod). call: after label_addr of the function,
# jitaddr checks it in the JIT's last pass (CC_pass 2; in the first, a
# function placed later has no address yet). Test: by hand (a failing
# build is no ctest): g: double / __builtin_huge_val.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "\n  al_word:\n    ascii\n      align\n",
    "\n  al_word:\n    ascii\n      align\n  msg_jitcall:\n    ascii\n      ttpc: compile time calls what has no code yet:\\x20\n", 'al_word');

for my $l ('L5', 'L9') {
    edit(\$t, 'cc/call', asm(8, "$l:\nmv s5 a0\ncall label_addr\n") => asm(8, "$l:\nmv s5 a0\ncall label_addr\nmv s5 a1\ncall jitaddr\n"));
}
my $f = fn('jitaddr', "
    bnez J9 a0
    la ccs t0
    ld CC_jit t0 t1
    beqz J9 t1
    ld CC_pass t0 t1
    li 2 t2
    bne rel:J9 t2 t1
    ld NODE_content a1 a3
    lbu NODE_content_len a1 a4
    addi -1 a4 a4
    la msg_jitcall a1
    li 47 a2
    j die_name
J9:
    ret
", 6);
$f =~ s/^(.*\n)/$1        comment\n          a0 the address of the function a1 calls: where compile time has none, the function's name and stop\n/;
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $f;
save();
