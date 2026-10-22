# tquiet.pl: ttpc's look ahead for a function's temporaries (tscan) finds
# every name of the body with cfind, to size the temporaries of what is in
# memory; cfind's libsym reaches what it finds in a library (libadd, an asm
# unit's reach, LB's asm label). So a field, a text or a local named as an
# unrelated library global compiled that global: string's tests reached
# libm's long double table C through a field C ("a value of a type in
# memory"). While tscan looks (tscan_quiet), libsym finds without reaching
# and finds no asm label; the compile of the body reaches what it names.
# Test: creach. Run on ttpc.ff after secpass.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  sec_at:\n    reserve\n      128\n",
    "  sec_at:\n    reserve\n      128\n  tscan_quiet:\n    reserve\n      8\n", 'sec_at');

my $find = "        mv\n          s4\n          a2\n        call\n          cfind\n";
edit(\$t, 'tscan', $find, asm(8, "
    la tscan_quiet t0
    li 1 t1
    sd 0 t1 t0
") . $find . asm(8, "
    la tscan_quiet t0
    sd 0 zero t0
"));

my $quiet = asm(10, "
    la tscan_quiet t0
    ld 0 t0 t0
    bnez L7 t0
");
edit(\$t, 'libsym',
    "        L6:\n" => "        L6:\n" . $quiet,
    "        L12:\n" => "        L12:\n" . $quiet,
    "        L8:\n          mv\n            s4\n            a0\n          call\n            LB\n          leave3\n" =>
        "        L8:\n" . asm(10, "
    la tscan_quiet t0
    ld 0 t0 t0
    beqz Q8 t0
    li 0 a0
    leave3
") . "        Q8:\n          mv\n            s4\n            a0\n          call\n            LB\n          leave3\n");
save();
