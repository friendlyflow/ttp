# paramscope.pl: a local does not hide a type from another function's
# parameters or a struct's members (the master's fault 20, 2026-11-23,
# coreutils' utimensat with a local named timespec). argcheck counted the
# callee's parameters with typerun in the caller's scopes, so a local of the
# caller named as a parameter's type (gnulib's struct timespec timespec[2],
# glibc's __utimensat's tsp64: timespec * pointer; C's struct pt pt; g (pt))
# hid the type and the parameter was no parameter: wrong number of arguments;
# fields (a struct's layout and its member lookups) read its members' types
# in the scopes of the function at hand the same way, and so did call's
# ABI steps after the arguments (a struct passed by value) and argpush's
# ptype. Now tdefonly counts the argcheck, fields, ptype in argpush and
# call (after its args) at work, and while it is not 0 tyword passes over
# a hit of find_label that is no definition (a local, a goto label: not
# struct, union, enum or function) and looks again past the function's
# scopes (scope_depth 1: the page, the program's groups, then the library); in the function's
# own code a local still comes first (sizeof timespec is the local's).
# Test: progs/cparamscope.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  text_item:\n    reserve\n      8\n",
    "  text_item:\n    reserve\n      8\n  tdefonly:\n    reserve\n      8\n", 'text_item');

edit(\$t, 'tyword',
    "        call\n          isdef\n        beqz\n          L6\n          a0\n        mv\n          s5\n          a0\n" =>
    "        call\n          isdef\n        beqz\n          LQ\n          a0\n        LD:\n          mv\n            s5\n            a0\n",
    "        L6:\n" => asm(8, "
LQ:
    la tdefonly t0
    ld 0 t0 t0
    beqz L6 t0
    la scope_depth t0
    ld 0 t0 t1
    li 1 t2
    bgeu rel:L6 t1 t2
    mv t1 s5
    sd 0 t2 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call find_label
    la scope_depth t0
    sd 0 s5 t0
    bnez LR a0
    mv s4 a0
    call libtype
    beqz L6 a0
LR:
    mv a0 s5
    call isdef
    beqz L6 a0
    j LD
") . "        L6:\n");

my $inc = asm(8, "
    la tdefonly t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
");
my $dec = asm(10, "
    la tdefonly t3
    ld 0 t3 t4
    addi -1 t4 t4
    sd 0 t4 t3
");
edit(\$t, 'fields', "        enter8\n" => "        enter8\n$inc",
    "        L9:\n          leave8\n" => "        L9:\n$dec          leave8\n");
edit(\$t, 'argcheck', "        enter3\n" => "        enter3\n$inc",
    "        L9:\n          leave3\n" => "        L9:\n$dec          leave3\n");
my $dec8 = asm(8, "
    la tdefonly t3
    ld 0 t3 t4
    addi -1 t4 t4
    sd 0 t4 t3
");
edit(\$t, 'argpush', "        call\n          ptype\n" => "$inc        call\n          ptype\n$dec8");
save();
