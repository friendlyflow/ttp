# hexinf.pl: a hex float one exponent past its type's range is its IEEE
# bits (the user's choice A, 2026-10-23): without a fraction infinity
# (0x1p+1024, float 0x1p+128f, long double 0x1p+16384L), with one a NaN
# (0x1.8p+1024: the quiet NaN); a negative one is - before it, as any. C's
# HUGE_VAL, INFINITY and NAN in a constant (gcc folds __builtin_huge_val,
# __builtin_inff, __builtin_nanf), which c2ff writes so: strtod's and
# strfrom's tests' tables. hexf: the biased exponent may be the all-ones
# one (float and double, L28; binary128, LU). Where long double is double
# (arm, 4-byte words), binary128's all-ones exponent is double's: its
# fraction's top 52 bits, a NaN kept quiet (LDI); a finite one past double
# stays infinity. Test: chexinf.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'hexf',
    asm(8, "L28:\nbgeu rel:L8 t3 s9\n") => asm(8, "L28:\nbltu rel:L8 s9 t3\n"),
    asm(10, "li32 32767 t1\nbgeu rel:L8 t1 t0\n") => asm(10, "li32 32767 t1\nbltu rel:L8 t0 t1\n"),
    asm(8, "LDI:\nli 2047 t1\nslli 52 t1 a0\nj LDE\n") => asm(8, "
LDI:
    li 2047 t1
    slli 52 t1 a0
    li32 16384 t1
    bne rel:LDE t1 t0
    slli 16 s6 t2
    or s7 t2 t3
    beqz LDE t3
    srli 16 t2 t2
    slli 4 t2 t2
    srli 60 s7 t3
    or t3 t2 t2
    li 1 t4
    slli 51 t4 t4
    or t4 t2 t2
    or t2 a0 a0
    j LDE
"));
save();
