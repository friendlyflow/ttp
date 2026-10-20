# secpass.pl: a section is placed where the first pass placed it. The
# library's list is kept from the first pass to the second, so what a
# section's globals reach (__io_vtables' _IO_str_finish, ...) was already in
# it in the second pass and came before the section, which the first pass
# placed after it: "label moved between the passes". As the TLS image does
# (tls_vars), each section remembers where in the list it was placed in the
# first pass (sec_at, by the order the sections are made in, 1 + the list's
# index; 0 not yet), cc_library's loop stops there (secbound), and secplace
# places it only once the loop is there. sec_at is cleared once per program
# (compile_page, before its passes). Run on ttpc.ff after section.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

once(\$t, "  sec_prog:\n    reserve\n      8\n", "  sec_prog:\n    reserve\n      8\n  sec_at:\n    reserve\n      128\n", 'sec_prog');

# compile_page: once per program, before its passes
my $frame = "    mv\n      s7\n      a0\n    call\n      cc_frame\n";
edit(\$t, 'compile_page', $frame, $frame . asm(4, "
    la sec_at t0
    li 16 t1
    SR1:
    sd 0 zero t0
    addi 8 t0 t0
    addi -1 t1 t1
    bnez SR1 t1
"));

# cc_library: the loop stops where a section waits; secplace knows where it is
edit(\$t, 'cc/cc_library',
    "        L51:\n          bgeu\n            rel\n              L9\n            t0\n            s4\n",
    asm(8, "
    L51:
    mv t0 a0
    call secbound
    mv a0 t0
    bgeu rel:L9 t0 s4
"),
    "        L9:\n          call\n            secplace\n",
    asm(8, "
    L9:
    mv s4 a0
    call secplace
"));

# secplace: a section the first pass placed later in the list waits
edit(\$t, 'cc/secplace',
    "        enter8\n",
    "        enter8\n" . asm(8, "
    mv a0 s10
"),
    "          ld\n            24\n            s6\n            t0\n          bnez\n            P1\n            t0\n",
    "          ld\n            24\n            s6\n            t0\n          bnez\n            P1\n            t0\n" . asm(10, "
    la sec_at t1
    addi -1 s5 t2
    slli 3 t2 t2
    add t2 t1 t1
    ld 0 t1 t2
    beqz SA1 t2
    addi -1 t2 t2
    bltu rel:P1 t2 s10
    j SA2
    SA1:
    addi 1 s10 t2
    sd 0 t2 t1
    SA2:
"));

my ($pf, $pt) = find(\$t, 'cc/secplace');
substr($t, $pt, 0) = cfn('secbound', "a0, or less: the place in the library's list where a section not placed yet was placed in the first pass", "
    la sec_vars t0
    ld 0 t0 t1
    li 0 t2
    B1:
    bgeu rel:B9 t1 t2
    slli 8 t2 t3
    add t3 t0 t3
    ld 32 t3 t4
    la sec_at t5
    slli 3 t2 t6
    add t6 t5 t5
    addi 1 t2 t2
    bnez B1 t4
    ld 0 t5 t6
    beqz B1 t6
    addi -1 t6 t6
    bltu rel:B1 t6 a0
    mv t6 a0
    j B1
    B9:
    ret
", 6);
save();
