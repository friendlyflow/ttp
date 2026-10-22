# enumtype.pl: an enum constant has the type gcc gives it, by its value:
# int where it fits one, else unsigned int where it fits that, else long,
# else unsigned long (C23's rule, and GNU C's for an enum whose values do
# not fit int). It was always int: tst-memmove-overflow's
# allocation_size, 2 GiB + 8 MiB, made allocation_size - 1 negative, and
# memmove copied past its buffer. A number is typed so already (numlit);
# an enum constant now as a hexadecimal number is, which is gcc's rule for
# an enum. Test: cenumtype.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'leafval', "          call\n            enumconst\n          beqz\n            L60\n            a0\n          mv\n            a1\n            a0\n          li\n            R_a0\n            a1\n          call\n            li\n          li\n            TY_INT\n            a0\n", asm(10, "
call enumconst
beqz L60 a0
mv a1 s5
mv a1 a0
li R_a0 a1
call li
li TY_INT a0
slli 32 s5 t0
srai 32 t0 t0
beq rel:L8 t0 s5
li TY_U32 a0
srli 32 s5 t0
beqz L8 t0
li TY_LONG a0
bgez L8 s5
li TY_U64 a0
"));
save();
