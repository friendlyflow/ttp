# widename.pl: ttpc's stop for a value of a type in memory that has no room
# (wtemp, "in a function that does not name the type") says which function:
# on arm double is such a type, and a tree of all of glibc holds thousands.
# (wfn_node: the function whose body is being compiled, set where its
# temporaries are counted; a global's value, compile time's, says the last.)
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, asm(10, "
    call tpinit
    mv s4 a0
    call wgate
"), asm(10, "
    call tpinit
    la wfn_node t0
    sd 0 s4 t0
    mv s4 a0
    call wgate
"), 'wgate of a function');
edit(\$t, 'wtemp', asm(8, "
L9:
    la msg_wide a1
    li 104 a2
    li 0 a4
    j die_name
") => asm(8, "
L9:
    li 0 a4
    la wfn_node t0
    ld 0 t0 t0
    beqz L10 t0
    ld NODE_content t0 a3
    lbu NODE_content_len t0 a4
L10:
    la msg_wide a1
    li 106 a2
    j die_name
"));
once(\$t, "          ttpc: a value of a type in memory (long double; double on arm) in a function that does not name the type\n",
    "          ttpc: a value of a type in memory (long double; double on arm) in a function that does not name the type:\\x20\n", 'msg_wide');
once(\$t, "\n  wt_stmts:\n", "\n  wfn_node:\n    dword\n      0\n  wt_stmts:\n", "wfn_node");
save();
