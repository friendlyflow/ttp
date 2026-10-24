# vaderef.pl: va_arg of x * pointer (C's va_arg (*ap, long): printf's
# positional arguments, va_arg (*ap_savep, type)) where va_list is a pointer
# (riscv64, arm): vaop makes x * pointer one node, * pointer with x under
# it, whose value leafval does not know (it gave the pointer's size, 8: the
# program crashed loading from address 8); primary takes it, as any one
# node's value. Test: cvaptr (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'vaarg',
    asm(10, "bnez VAP a0\nmv s5 a0\ncall leafval\ncall push\n") => asm(10, "bnez VAP a0\nmv s5 a0\ncall primary\ncall push\n"));
# arm's own va_arg (abivaarg: AAPCS's 8-aligned doubles and pairs) the same
edit(\$t, 'abivaarg', asm(8, "mv s4 a0\ncall leafval\nli 4 s6\n") => asm(8, "mv s4 a0\ncall primary\nli 4 s6\n"));
save();
