# valrec.pl: a : that is a value whose value is one of its own locals of a
# type in memory that is no wide scalar of up to 16 bytes (a struct, a
# union, a complex; a wider value) has its value copied into a temporary of
# its size before the group gives its room back, V that temporary's address,
# as valgroup.pl does for a wide scalar (wtemp, 16 bytes): vgroup gave such
# a group's room back with V still its address, and the copy the statement
# made next (copytype pushes its addresses below sp) wrote over it: struct
# pt d = ({ struct pt t = q; t.x += 10; t; }) had garbage fields (riscv64,
# tests2). The temporary is the statement's (wtempn: wtemp's of a size);
# wscan reserves it: a : whose last child names a declaration of its own
# children counts that declaration's type's size (wgrp). The master's fault
# 14, 2026-11-21. Test: progs/cvalrec.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $old = "        VQ:\n        mv\n          s8\n          a0\n        call\n          fwide\n        beqz\n          V1\n          a0\n        mv\n          s8\n          a0\n        call\n          tsize\n        li\n          16\n          t0\n        bltu\n          rel\n            V1\n          a0\n          t0\n";
my $new = "        VQ:\n        mv\n          s8\n          a0\n        call\n          fwide\n        beqz\n          VK\n          a0\n        mv\n          s8\n          a0\n        call\n          tsize\n        li\n          16\n          t0\n        bltu\n          rel\n            VK\n          a0\n          t0\n";
edit(\$t, 'cc/vgroup', $old => $new);
edit(\$t, 'cc/vgroup', "        V1:\n          mv\n            s6\n            a0\n" => asm(8, "
VK:
    mv s8 a0
    call inmem
    beqz V1 a0
    mv s8 a0
    call tsize
    call wtempn
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
") . "        V1:\n          mv\n            s6\n            a0\n");
{
    my ($from, $to) = find(\$t, 'wtemp');
    my $f = fn('wtempn', "
    addi 15 a0 a0
    andi -16 a0 a0
    la wt_on t0
    ld 0 t0 t0
    bnez LW t0
    la ccs t0
    ld CC_tnext t0 t1
    add a0 t1 t1
    la lookcache t2
    ld 168 t2 t3
    bltu rel:L9 t1 t3
    sd CC_tnext t1 t0
    mv t1 a0
    ret
LW:
    la wt_next t0
    ld 0 t0 t1
    add a0 t1 t1
    la wt_lim t2
    ld 0 t2 t3
    bltu rel:L9 t1 t3
    sd 0 t1 t0
    mv t1 a0
    ret
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
", 6);
    $f =~ s/^(.*\n)/$1        comment\n          wtemp's temporary of a0 bytes (rounded up to 16): its offset below the frame, a0\n/;
    my $g = fn('wgrp', "
    enter5
    mv a0 s4
    li 0 s8
    lbu NODE_content_len s4 t0
    li 1 t1
    bne rel:G9 t1 t0
    ld NODE_content s4 t0
    lbu 0 t0 t0
    li CH_colon t1
    bne rel:G9 t1 t0
    mv s4 a0
    call flatkids
    mv a0 s5
    mv a1 s6
    bgeu rel:G9 s6 s5
    ld -8 s6 s7
    lbu NODE_children_len s7 t0
    bnez G9 t0
G1:
    bgeu rel:G9 s6 s5
    ld 0 s5 a0
    lbu NODE_content_len a0 t0
    lbu NODE_content_len s7 t1
    addi 1 t1 t1
    bne rel:G2 t1 t0
    lbu NODE_children_len a0 t0
    beqz G2 t0
    ld NODE_content a0 a2
    mv t1 a3
    addi -1 a3 a3
    ld NODE_content s7 a0
    lbu NODE_content_len s7 a1
    call streq
    bnez G3 a0
G2:
    addi 8 s5 s5
    j G1
G3:
    ld 0 s5 t0
    ld NODE_children t0 a0
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 a0 a1
    call tlskip
    call typerun
    bltz G9 a0
    mv a0 s4
    call inmem
    beqz G9 a0
    mv s4 a0
    call tsize
    addi 15 a0 a0
    andi -16 a0 s8
G9:
    mv s8 a0
    leave5
", 6);
    $g =~ s/^(.*\n)/$1        comment\n          the room a : that is a value needs for its value (valrec.pl): its last child a leaf naming a declaration among its children, of a type in memory: its size rounded up to 16, else 0\n/;
    substr($t, $to, 0) = $f . $g;
}
edit(\$t, 'wscan', asm(8, "
W0:
    mv s4 a0
    call kwof
") => asm(8, "
W0:
    mv s4 a0
    call wgrp
    add a0 s6 s6
    mv s4 a0
    call kwof
"));
save();
