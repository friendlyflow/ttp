# sfname.pl: a runtime function ttpc calls (cc_sfnames: binary128's soft-fp,
# __addtf3 ..., the conversions of float16 and bfloat16, __extendhfsf2 ...)
# that the program and its libraries do not define stops with its name.
# a64wcall, x64wcall and rvwcall called bad with node 0 ("cannot compile: "
# and no name: coreutils on x86_64, its glibc tree without libgcc's
# __extendhfsf2, took a debugger to find); wcall's own path (arm) named it,
# as long double's, which float16's and float128's are not. Now all four
# say "ttpc: no definition of the runtime function <name>" (44 bytes before
# the name, msg_sf's, where wcall had 45 for the old text).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "      msg_sf:\n        ascii\n          ttpc: long double needs the soft-fp function\\x20\n",
    "      msg_sf:\n        ascii\n          ttpc: no definition of the runtime function\\x20\n", 'msg_sf');
edit(\$t, 'wcall', asm(10, "
    la msg_sf a1
    li 45 a2
") => asm(10, "
    la msg_sf a1
    li 44 a2
"));
for my $w (qw(a64wcall x64wcall rvwcall)) {
    edit(\$t, $w, asm(8, "
    bnez L0 a0
    li 0 a0
    call bad
") => asm(8, "
    bnez L0 a0
    mv s11 a0
    call strlen
    mv a0 a4
    mv s11 a3
    la msg_sf a1
    li 44 a2
    j die_name
"));
}
save();
