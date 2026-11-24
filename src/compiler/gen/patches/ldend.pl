# ldend.pl: _end, the linker's end of the bss (ld's default script), is a
# label of each target's frame (macros/<target>.ff.txt, at mem_end); C names
# it: glibc's minimal malloc (ld.so's dl-minimal-malloc.c) starts its arena
# at &_end. A label of the frame is no definition C finds (cfind), so
# _end / & address was golabel's never-placed label: garbage before
# addrname.pl, unknown name since. Now addr's W1 takes _end, defined nowhere
# else, for the frame's label: the frame (find_fn of frame, the target's, as the wrap of a program finds it) and
# its child _end: (ldendnode), whose address gaddr gives (0 in the first
# pass, the label's in the second), as asm's. Only the name of ld's script
# glibc's C names: _end (no _edata, __bss_start, _etext on any target's
# tree). Test: progs/cldend.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  str_with:\n    ascii\n      with\n", "  str_with:\n    ascii\n      with\n  str_ldend:\n    ascii\n      _end:\n", 'str_with');

edit(\$t, 'cc/addr', asm(8, "
W1G:
    mv s4 a0
    call golabel
") => asm(8, "
W1G:
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    la str_ldend a2
    li 4 a3
    call streq
    beqz W1L a0
    la str_frame a0
    li 5 a1
    call find_fn
    beqz W1L a0
    call ldendnode
    beqz W1L a0
    call gaddr
    li TY_ADDRESS a0
    li 0 a1
    li 0 a2
    call newtype
    call setty
    leave2
W1L:
    mv s4 a0
    call golabel
"));
{
    my ($from, $to) = find(\$t, 'cc/addr');
    my $f = fn('ldendnode', "
    enter3
    lbu NODE_children_len a0 s4
    ld NODE_children a0 s5
E1:
    li 0 a0
    beqz E9 s4
    ld 0 s5 s6
    ld NODE_content s6 a0
    lbu NODE_content_len s6 a1
    la str_ldend a2
    li 5 a3
    call streq
    beqz E2 a0
    mv s6 a0
    j E9
E2:
    addi 8 s5 s5
    addi -1 s4 s4
    j E1
E9:
    leave3
", 6);
    $f =~ s/^(.*\n)/$1        comment\n          the child _end: of the frame a0 (the target's, on the shared page), else 0\n/;
    substr($t, $to, 0) = $f;
}
save();
