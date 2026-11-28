# deftype.pl: a local does not hide a type from a library definition the
# program reaches (the master's fault 30, tar's uname_to_uid: struct passwd
# *passwd; passwd = getpwnam (uname) stopped "wrong number of arguments:
# getpwnam"). libsym, which reaches a library name the code uses, told a
# function or global from an asm entry by the type its definition starts
# with (typerun) in the scopes of the code at hand, so the caller's local
# passwd hid glibc's type passwd of getpwnam's result: getpwnam was taken
# for an asm entry, and its call went through code_call, whose binding
# counted the definition's children as a macro's; and dtype, the type of a
# definition (a call's result, a global's type for primary, leafval, addr,
# gval), read it the same way ("needs a type: getpwnam"). Now the typerun
# of both runs with tdefonly (paramscope.pl's rule, as kind and argcheck
# have it): a local or a label of the function at hand is passed over and
# the type is looked up past its scopes. A program's own type of the same
# first word (passwd struct prog) plays no part. Test: progs/cpwlocal (+defs).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc/libsym', "          tlskip\n        call\n          typerun\n        bltz\n          L8\n          a0\n" =>
    "          tlskip\n" . asm(8, "
    la tdefonly t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
    call typerun
    la tdefonly t3
    ld 0 t3 t4
    addi -1 t4 t4
    sd 0 t4 t3
    bltz L8 a0
"));
edit(\$t, 'cc/dtype', "        call\n          tlskip\n        call\n          typerun\n        mv\n          a0\n          s7\n" =>
    "        call\n          tlskip\n" . asm(8, "
    la tdefonly t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
    call typerun
    la tdefonly t3
    ld 0 t3 t4
    addi -1 t4 t4
    sd 0 t4 t3
    mv a0 s7
"));
save();
