# casescope.pl: a declaration in a case's or default's body is the switch
# body's, as in C (case and default are labels in the switch's block): a
# later case uses it and assigns it. case compiled its body scoped (its own
# block) and default as a group (scoped too), so a later case's use was no local: as a
# value "unknown name", as an lvalue (& address, x = ...) golabel's label
# never placed, a store to a garbage address (glibc's elf_machine_rela,
# x86_64's dl-machine.h: fmt declared in R_X86_64_PC32's case, assigned in
# the later ones); now, since addrname.pl, unknown name. Now case (by stmts) and default
# (flatkids, then stmts) compile their body in the switch body's scope; a case's label
# already sets sp to the depth there (syncsp), so the room of a declaration
# jumped past is the same (its initializer has not run, as in C). The
# switch's own scoped ends them all. Test: progs/ccasescope.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/case', asm(8, "
    la ccs t0
    ld CC_cur t0 a0
    ld CC_end t0 a1
    call scoped
    mv s6 a0
    mv s7 a1
    call close
") => asm(8, "
    la ccs t0
    ld CC_cur t0 a0
    ld CC_end t0 a1
    call stmts
    call syncsp
    mv s6 a0
    mv s7 a1
    call close
"));
edit(\$t, 'cc/default', asm(8, "
    mv s4 a0
    call group
    leave3
") => asm(8, "
    mv s4 a0
    call flatkids
    call stmts
    call syncsp
    leave3
"));
save();
