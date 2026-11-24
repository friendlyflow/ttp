# voidcast.pl: cast / void of a value converts nothing: the value is
# worked out for its effects and then dropped (C's (void) x). unary's
# prefix cast (UV: cast / void, then the value) and convert's (the value
# under it) took void, type code 0, as one more scalar type, so a
# floating value was
# converted to an integer first (riscv64's fcvt.l.d), which raises the
# Invalid exception for a NaN and Inexact for a fraction. glibc's
# iscanonical, ((void) (__typeof (x)) (x), 1), raised Invalid for a
# signaling NaN (math's test-double-iscanonical ...). Test: cvoidcast
# (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'convert', asm(8, "
L2:
    call getty
") => asm(8, "
L2:
    beqz L2V s5
    call getty
"));
{
    my ($from, $to) = find(\$t, 'convert');
    # (after the function's last instruction: a void target's type, then its end)
    substr($t, $to, 0) = asm(8, "
L2V:
    mv s5 a0
    call setty
    j L9
");
}
edit(\$t, 'unary', asm(8, "
UV:
    call getty
") => asm(8, "
UV:
    beqz UVV s6
    call getty
"));
{
    my ($from, $to) = find(\$t, 'unary');
    substr($t, $to, 0) = asm(8, "
UVV:
    mv s6 a0
    call setty
    j L9
");
}
save();
