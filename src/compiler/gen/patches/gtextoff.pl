# gtextoff.pl: a global's address plus an offset that is no number (C's
# &"libnss_files.so.2"[sizeof ("libnss_files.so") - 1], nss_module.c's
# __nss_shlib_revision; an array's address + sizeof x) is that address
# plus the offset's value. gval took : / cast / T / X / + / N, and
# : / X / + / N, as an address and an offset for a number N only; any
# other N went to the compile-time run, whose value is the address of
# ttpc's own copy of the text (in the compiler's heap): the program's
# pointer was garbage (posix's tst-wordexp-tilde: getpwnam's NSS module
# name, strlen of it, SIGSEGV, 4 targets). Now an offset with children
# is an item that gval works out (as gsizeof.pl's : / sizeof / x), then
# scaled as a number is. Test: cgtextoff (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

for my $k ([4, 24, 16], [3, 16, 8]) {
    my ($n, $at, $op) = @$k;
    my $num = "
lbu NODE_children_len t3 t0
bnez L12 t0
ld NODE_content t3 a0
lbu NODE_content_len t3 a1
call parse_num
beqz L12 a1
mv a0 s6
";
    edit(\$t, 'cc/gval',
        asm(10, "ld $at t2 t3$num") . asm(10, "ld NODE_children s5 t2\nld $op t2 a0\n")
        => asm(10, "ld $at t2 t3" . ($num =~ s/bnez L12 t0/bnez GTO$n t0/r) . "j GTB$n\n")
        # (the offset's value: gval on that item)
        . asm(10, "GTO$n:\nld NODE_children s5 a0\naddi $at a0 a0\nmv s7 a1\ncall gval\nmv a0 s6\n")
        . asm(10, "GTB$n:\nld NODE_children s5 t2") . asm(10, "ld $op t2 a0\n"));
}
save();
