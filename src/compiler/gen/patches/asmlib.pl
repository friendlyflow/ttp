# asmlib.pl: a library page's asm looks a name up in its own library first
# (the master's fault 22, the user's choice (b), 2026-11-24). find_label
# looked at the program page (the bottom scope, and its groups) before
# find_fn looked at the target's section, the shared page and the library
# pages, so a program's global hi (u8 hi) hid aarch64's condition hi in
# glibc's asm (ccmpiw 1 hi w3 0: "out of range: ccmpi"). Now, while
# run_placed places the asm of a library definition, lib_asm is its page's
# top-level node (libgrp; it stays 0 on the program page and is 0 while
# ccg compiles C), and a name an operand or a call names is looked up:
# the scopes of the definition (its own labels), its library (lib_asm's
# definitions through the layers, then in its groups: asmlib), the
# target's section and the shared page and the other library pages
# (find_fn as before), and only then the program page (its definitions,
# then its groups). find_fn's caches key on lib_asm too. The C layer's
# lookup does not change: ccg clears lib_asm while cc runs. Test:
# progs/casmlib (+ casmliblib/).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# the variable
once(\$t, "  lib_grp:\n    dword\n      0\n", "  lib_grp:\n    dword\n      0\n  lib_asm:\n    dword\n      0\n", 'lib_asm');

# ccg: no lib_asm while C compiles
edit(\$t, 'ccg', "    call\n      cc\n" => asm(4, "
    la lib_asm t0
    ld 0 t0 s5
    sd 0 zero t0
    call cc
    la lib_asm t0
    sd 0 s5 t0
"));

# run_placed: lib_asm from the definition placed when none is set yet,
# the one before it again at its end
edit(\$t, 'run_placed',
    "    sd\n      16\n      s5\n      sp\n" => "    sd\n      16\n      s5\n      sp\n" . asm(4, "
    la lib_asm t0
    ld 0 t0 t1
    sd 24 t1 sp
    call asmlibset
"),
    "    L4:\n      ld\n        0\n        sp\n        ra\n" => "    L4:\n" . asm(6, "
    ld 24 sp t1
    la lib_asm t0
    sd 0 t1 t0
    ld 0 sp ra
"));

# find_fn: lib_asm in the cache keys; its library before the sections
edit(\$t, 'find_fn',
    "    mv\n      a3\n      s8\n    li\n      0\n      s6\n" => asm(4, "
    mv a3 s8
    la lib_asm t0
    ld 0 t0 t0
    xor t0 s8 s8
    li 0 s6
"),
    "    M1:\n      mv\n        s4\n        a0\n" => "    M1:\n" . asm(6, "
    call asmlib
    bnez M2 a0
    mv s4 a0
"));

# find_label: in a library's asm, the bottom scope (the program page in its
# frame) and the program page's groups after find_fn's places
{
    my ($from, $to) = find(\$t, 'find_label');
    my $lf = index($t, "\n    lfind:\n", $from);
    die "asmlib: no lfind in find_label\n" unless $lf > $from && $lf < $to;
    substr($t, $from, $lf + 1 - $from) = "  find_label:\n" . asm(4, "
    addi -48 sp sp
    sd 0 ra sp
    sd 8 s4 sp
    sd 16 s5 sp
    sd 24 s6 sp
    sd 32 s7 sp
    sd 40 s8 sp
    mv a0 s4
    mv a1 s5
    la scope_depth t0
    ld 0 t0 t0
    slli 3 t0 t0
    la scopes s6
    add t0 s6 s6
    la lib_asm t0
    ld 0 t0 s7
    la scopes s8
    beqz L1 s7
    addi 8 s8 s8
L1:
    bgeu rel:L4 s6 s8
    addi -8 s6 s6
    ld 0 s6 a0
    li 0 a1
    li 0 a2
    call clfind
    beqz L1 a0
    j L5
L4:
    beqz L7 s7
    mv s4 a0
    mv s5 a1
    call find_fn
    bnez L6 a0
    la scope_depth t0
    ld 0 t0 t0
    beqz L7 t0
    la scopes t0
    ld 0 t0 a0
    li 0 a1
    li 0 a2
    call clfind
    bnez L5 a0
L7:
    la sec_prog t0
    ld 0 t0 a0
    beqz L6 a0
    li 0 a1
    li 1 a2
    call clfind
    j L5
L6:
    li 0 a0
L5:
    ld 0 sp ra
    ld 8 sp s4
    ld 16 sp s5
    ld 24 sp s6
    ld 32 sp s7
    ld 40 sp s8
    addi 48 sp sp
    ret
");
}

# libsym: the names of a library asm definition are reached (asmreach's
# cfind) in the order the assembler will look them up: with lib_asm and
# lib_grp its group, and the scopes down to the bottom one (the program
# page in its frame), else a program's kval kept the library's kval from
# being placed (asmreachl)
edit(\$t, 'libsym', "          mv\n            s5\n            a0\n          call\n            asmreach\n          call\n            libbase\n" =>
    "          mv\n            s5\n            a0\n          call\n            asmreachl\n          call\n            libbase\n");
{
    # asmreach's labels (R1 ...) are its siblings: asmreachl goes before it
    my ($from, $to) = find(\$t, 'asmreach');
    substr($t, $from, 0) = cfn('asmreachl', "asmreach of the library asm a0 as the assembler looks its names up: lib_asm and lib_grp its group (libgrp), the scopes but the bottom one out of sight (when it has a group)", "
    enter5
    mv a0 s4
    la lib_asm t0
    ld 0 t0 s5
    la lib_grp t0
    ld 0 t0 s6
    la scope_depth t0
    ld 0 t0 s7
    call libgrp
    beqz A8 a0
    la lib_asm t0
    sd 0 a0 t0
    la lib_grp t0
    sd 0 a0 t0
    beqz A8 s7
    la scope_depth t0
    li 1 t1
    sd 0 t1 t0
A8:
    mv s4 a0
    call asmreach
    la lib_asm t0
    sd 0 s5 t0
    la lib_grp t0
    sd 0 s6 t0
    la scope_depth t0
    sd 0 s7 t0
    leave5
", 8);
}

# the helpers, after libgrp
{
    my ($from, $to) = find(\$t, 'libgrp');
    substr($t, $to, 0) =
      cfn('asmlibset', "lib_asm = libgrp(a0) when it is 0 (run_placed: the library a definition's asm is in); a0 kept", "
    enter2
    mv a0 s4
    la lib_asm t0
    ld 0 t0 t0
    bnez S9 t0
    call libgrp
    la lib_asm t0
    sd 0 a0 t0
S9:
    mv s4 a0
    leave2
", 2) .
      cfn('asmlib', "the definition named s4 s5 (find_fn's name) in lib_asm (the library of the asm placed), through its layers, else in its groups; 0 if none, or lib_asm is 0", "
    enter2
    la lib_asm t0
    ld 0 t0 a0
    beqz A9 a0
    li 0 a1
    li 0 a2
    call alfind
    bnez A9 a0
    la lib_asm t0
    ld 0 t0 a0
    li 0 a1
    li 1 a2
    call alfind
A9:
    leave2
", 2) .
      cfn('alfind', "the child of a0 named s4 s5 (a definition), through the layers of a0 (a1 deep); with a2 1 the one in a group among them (one level, as find_label's pgroups); 0 if none", "
    enter8
    mv a0 s6
    mv a1 s7
    mv a2 s9
    lbu NODE_children_len s6 s8
    ld NODE_children s6 s6
F1:
    li 0 a0
    beqz F9 s8
    ld 0 s6 a0
    call is_fn
    beqz F3 a0
    ld 0 s6 a0
    call is_layer
    beqz F2 a0
    li MAX_DEPTH t4
    bgeu rel:F3 t4 s7
    ld 0 s6 a0
    addi 1 s7 a1
    mv s9 a2
    call alfind
    bnez F9 a0
    j F3
F2:
    bnez F4 s9
    ld 0 s6 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    addi -1 a3 a3
    mv s4 a0
    mv s5 a1
    call streq
    beqz F3 a0
    ld 0 s6 a0
    j F9
F4:
    ld 0 s6 a0
    call is_group
    beqz F3 a0
    ld 0 s6 a0
    li 0 a1
    li 0 a2
    call alfind
    bnez F9 a0
F3:
    addi 8 s6 s6
    addi -1 s8 s8
    j F1
F9:
    leave8
", 2);
}
save();
