# valgroup.pl: a : that is a value (primary's group, GNU C's statement
# expression ({ T y = x; y; })) of a wide type (x86_64's long double, arm's
# double, binary128: in memory, its address in V) has its value copied into
# a wide temporary before the group gives its room back, V that
# temporary's address. The value was the address of the group's room: when
# it is one of the group's locals, it lay below sp once group (scoped) had
# put CC_depth back, and what the statement did next took it at once (T s =
# ({ T y = x; y; }) zeroed and copied over it: s 0; f (({ T y = x; y; }))
# pushed the call's arguments there). glibc's math_opt_barrier (x) as an
# argument is one: x86_64's dsqrtl, dfmal, fsqrtl, ffmal (math-narrow.h),
# arm's double functions. The copy is made while the group's room is still
# its own (copytype pushes its addresses below it); the temporary is the
# statement's around it (wt_keep: the group's last statement's are kept).
# Only where the group's value is its last item, a name of one of its own
# locals (vfind past the names before it) whose declared type is wide:
# the type is the declaration's, the same in both passes (the type of a
# call ttpc has not seen yet is not). A wide temporary is 16 bytes: a wide
# value of up to 16 (a complex long double, 32, as before). vgroup is group with the copy; primary's L10G
# calls it (after wtstmt.pl). Test: progs/cvalgroup.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'primary', "            mv\n              s4\n              a0\n            call\n              group\n            la\n              wt_keep\n",
    "            mv\n              s4\n              a0\n            call\n              vgroup\n            la\n              wt_keep\n");

my ($from, $to) = find(\$t, 'group');
my $ind = (substr($t, $from) =~ /^( *)/)[0];
substr($t, $from, 0) = fn('vgroup', "
    addi -16 sp sp
    sd 0 ra sp
    call flatkids
    ld 0 sp ra
    addi 16 sp sp
    enter5
    mv a0 s8
    mv a1 s7
    la se_top t0
    ld 0 t0 s6
    la ccs t0
    ld CC_nvars t0 s4
    ld CC_depth t0 s5
    call stmts
    beq rel:V1 s8 s7
    ld -8 s7 t0
    lbu NODE_children_len t0 t1
    bnez V1 t1
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call vfind
    beqz V1 a0
    li VAR_sz t0
    mul t0 s4 t0
    la cc_vars t1
    add t0 t1 t1
    bltu rel:V1 t1 a0
    ld VAR_type a0 s8
    mv s8 a0
    call fwide
    beqz V1 a0
    mv s8 a0
    call tsize
    li 16 t0
    bltu rel:V1 a0 t0
    call wtemp
    mv a0 s7
    neg s7 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s8 a0
    call copytype
    neg s7 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s8 a0
    call setty
V1:
    mv s6 a0
    call seclose
    la ccs t0
    sd CC_nvars s4 t0
    sd CC_depth s5 t0
    call syncsp
    leave5
", length $ind);
save();
