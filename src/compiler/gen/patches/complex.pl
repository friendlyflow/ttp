# complex.pl: C's complex types (the user's choice, 2026-10-19): complex
# float, complex double and complex long double are structs of the shared
# page (shared.ff.txt), their parts the fields real part and imag part; the
# word real / z is the lvalue of z's real part, imag / z of its imaginary
# part, read or written (C's __real__ and __imag__). With complexdefs.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# the words, after va_arg_pack_len
once(\$t, "va_arg_pack\\x00va_arg_pack_len\\x00\\x00\n", "va_arg_pack\\x00va_arg_pack_len\\x00real\\x00imag\\x00\\x00\n", 'cc_kw');
# the names of the parts, as fields
once(\$t, "\n  cc_tynames:\n", "\n  cc_cxnames:\n    ascii\n      real part\\x00imag part\\x00\n  cc_tynames:\n", 'cc_tynames');

my $part = sub {
    my ($label, $off) = @_;
    "
$label:
    mv s4 a0
    call exprof
    call getty
    mv a0 s5
    call isstruct
    beqz L8 a0
    ld TY_base s5 a0
    la cc_cxnames a1
" . ($off ? "    addi $off a1 a1\n" : '') . "    li 9 a2
    call fields
    beqz L8 a2
    mv a1 s5
    li R_t1 a1
    call li
    la cc_add_t1 a0
    call seq
    mv s5 a0
    call setty
    j L9
";
};

# addr: real / z and imag / z, the part's address and type
edit(\$t, 'addr',
    "          call\n            kwof\n          li\n            KW_content\n            t0\n          bne\n",
    "          call\n            kwof\n" . asm(10, "
    li KW_real t0
    beq rel:LR t0 a0
    li KW_imag t0
    beq rel:LI t0 a0
") . "          li\n            KW_content\n            t0\n          bne\n",
    "        AC9:\n          li\n            0\n            a0\n          leave1\n",
    "        AC9:\n          li\n            0\n            a0\n          leave1\n" . asm(8, $part->('LR', 0) . $part->('LI', 10)));

# primary: their values
edit(\$t, 'primary',
    "          li\n            KW_content\n            t0\n          beq\n            rel\n              L12\n",
    asm(10, "
    li KW_real t0
    beq rel:LR t0 a0
    li KW_imag t0
    beq rel:LR t0 a0
") . "          li\n            KW_content\n            t0\n          beq\n            rel\n              L12\n",
    "        L61:\n          mv\n            s4\n            a0\n          call\n            bad\n",
    "        L61:\n          mv\n            s4\n            a0\n          call\n            bad\n" . asm(8, "
LR:
    mv s4 a0
    call addr
    call rvalue
    j L9
"));
save();
