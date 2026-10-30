# x87ret.pl: the SysV ABI's results of the x87's classes beside a long
# double's (x87.pl): a struct of 16 bytes whose first eightbyte is a long
# double (X87, X87UP: C's struct { long double x; }) comes back in st0, as
# a long double does (x64resclass's class 9, the struct's room; as an
# argument it stays in memory); complex long double (COMPLEX_X87) in st0,
# its real part, and st1, its imaginary one (class 10: cc_x64_rstt2 stores
# both after a call, cc_x64_rett2 loads them in a return). Run on ttpc.ff
# after x87.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }
sub esc { my $s = shift; $s =~ s/([\x00-\x1f\x7f])/sprintf "\\x%02x", ord $1/ge; $s }

# x64eb: a long double at a struct's start is x64_flags 4 (elsewhere 1:
# memory)
E('x64eb', 8, "
    li 112 t0
    beq rel:LM t0 s4
", "
    li 112 t0
    beq rel:LX87 t0 s4
");
{
    my ($from, $to) = find(\$t, 'x64eb');
    substr($t, $to, 0) = asm(8, "
LX87:
    bnez LM s5
    la x64_flags t0
    ld 0 t0 t1
    li 4 t2
    or t2 t1 t1
    sd 0 t1 t0
    j L9
");
}
# x64sclass: such a struct of 16 bytes, nothing else in it, is a0 = 9
E('x64sclass', 8, "
    andi 1 t2 t3
    bnez LM t3
", "
    andi 1 t2 t3
    bnez LM t3
    andi 4 t2 t3
    bnez LX87 t3
");
{
    my ($from, $to) = find(\$t, 'x64sclass');
    substr($t, $to, 0) = asm(8, "
LX87:
    bnez LM t1
    li 16 t0
    bne rel:LM t0 s5
    li 9 a0
    li 1 a1
    leave3
");
}
# x64class: as an argument it is in memory
E('x64class', 10, "
    li 6 t0
    beq rel:LS t0 a0
", "
    li 6 t0
    beq rel:LS t0 a0
    li 9 t0
    beq rel:LS t0 a0
");
# x64resclass: such a struct 9, complex long double 10
E('x64resclass', 10, "
    mv s4 a0
    call x64sclass
    li 6 t0
    beq rel:L9 t0 a0
", "
    ld TY_base s4 t1
    la cxn_l t0
    beq rel:LCX t0 t1
    mv s4 a0
    call x64sclass
    li 6 t0
    beq rel:L9 t0 a0
    li 9 t0
    beq rel:L9 t0 a0
");
{
    my ($from, $to) = find(\$t, 'x64resclass');
    substr($t, $to, 0) = asm(8, "
LCX:
    li 10 a0
    li 0 a1
    leave1
");
}
# x64res, x64retf: class 10's primitives
E('x64res', 10, "
    li 9 t0
    beq rel:LT9 t0 s4
", "
    li 9 t0
    beq rel:LT9 t0 s4
    li 10 t0
    beq rel:LT10 t0 s4
");
{
    my ($from, $to) = find(\$t, 'x64res');
    substr($t, $to, 0) = asm(8, "
LT10:
    la x64n_rstt2 a0
    call seq
    j L8
");
}
E('x64retf', 8, "
    li 9 t0
    la x64n_rett a0
    beq rel:L7 t0 s5
", "
    li 9 t0
    la x64n_rett a0
    beq rel:L7 t0 s5
    li 10 t0
    la x64n_rett2 a0
    beq rel:L7 t0 s5
");
{
    my $h = '';
    for my $x (['x64n_rstt2', 'cc_x64_rstt2'], ['x64n_rett2', 'cc_x64_rett2']) {
        my ($l, $n) = @$x;
        my $b = "\0$n\0";
        $b .= "\0" x (-length($b) % 8);
        $h .= "      $l:\n        ascii\n          " . esc($b) . "\n";
    }
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}
save();
