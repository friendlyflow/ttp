# argcount.pl: a call of a C function with another count of arguments
# than its parameters stops the compile with "wrong number of arguments:
# f". It compiled silently: too few left the missing parameters' registers
# as they were (garbage), too many were passed and ignored. call checks
# after args (argcheck): a function of ... (isvafn), a call passing
# va_arg_pack's arguments on, and a call through a pointer (a variable, a
# weak function, an ifunc) check nothing. Test: cargcount (the error),
# ctime's cargfew and cargmany.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

edit(\$t, 'cc/call', "        L2:\n          mv\n            s4\n            a0\n          mv\n            s5\n            a1\n          call\n            args\n          mv\n            a0\n            s9\n          mv\n            a1\n            s11\n",
    "        L2:\n          mv\n            s4\n            a0\n          mv\n            s5\n            a1\n          call\n            args\n          mv\n            a0\n            s9\n          mv\n            a1\n            s11\n" . asm(10, "
mv s5 a0
mv s9 a1
mv s11 a2
call argcheck
"));

my ($cf, $ct) = find(\$t, 'cc/call');
substr($t, $ct, 0) = cfn('argcheck', "stops with wrong number of arguments when a call of a0, a C function, passes a1 arguments, not its count of parameters; with a2 (va_arg_pack passed on), a0 not a function or a function of ... nothing", "
    enter3
    mv a0 s4
    mv a1 s5
    bnez L9 a2
    call kind
    li 1 t0
    bne rel:L9 t0 a0
    mv s4 a0
    call isvafn
    bnez L9 a0
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 s6
    mv s6 a1
    call tlskip
    call typerun
    mv a1 a0
    sub a0 s6 a1
    srli 3 a1 a1
    call nparams
    beq rel:L9 s5 a0
    mv s4 a0
    la msg_args a1
    li msg_args_len a2
    j diename
L9:
    leave3
", 6);
save();
