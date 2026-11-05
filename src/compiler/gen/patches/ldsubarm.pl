# ldsubarm.pl: on arm, where a long double literal is the nearest double
# (ldlit.pl), one below the normal doubles stayed 0: hexf's bltu compared the
# shift with 63 the wrong way round (0x1p-1022L, DBL_MIN, was 0 in a function).
# Test: cwgate.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'hexf', asm(10, "
    neg t1 t1
    li 63 t4
    bltu rel:LD0 t4 t1
") => asm(10, "
    neg t1 t1
    li 63 t4
    bltu rel:LD0 t1 t4
"));
save();
