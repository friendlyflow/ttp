# lalign.pl: a local aligned past what the frame's base keeps (twice a slot,
# at most 16: arm's 8; C's aligned (32), tst-makecontext-align's struct of an
# aligned (32) double) is at a multiple of its alignment wherever the frame
# is: declare (localalign.pl) aligns it from the frame's base only, and sp
# is only 16-aligned at a call (the ABI's). Its room gets its alignment less
# a slot more below it (walocal), and its address is rounded down to the
# alignment where it is taken (vaddr: cc_and, vaddrt0: cc_andt, andt.pl):
# the frame's base, its parameters and the unwinder's frame chain stay as
# they are. A local with items (an initializer list) keeps declare's place,
# as linit writes it from the base. wa_tab holds each variable's alignment
# (0: none of its own), by its index in cc_vars; declare clears it, a
# cleanup's alias (secl) copies it.
# Test: clocalign32.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# ---- the state: data after x64_flags; cc_andt's name after cc_add_t0_s0's
$t =~ /^( *)x64_flags:\n\1  dword\n\1    0\n/m or die "lalign: no x64_flags\n";
my $vi = $1;
once(\$t, "${vi}x64_flags:\n$vi  dword\n$vi    0\n", "${vi}x64_flags:\n$vi  dword\n$vi    0\n"
    . "${vi}wa_last:\n$vi  dword\n$vi    0\n${vi}wa_tab:\n$vi  reserve\n$vi    32768\n", 'x64_flags');
once(\$t, "${vi}cc_add_t0_s0:\n$vi  ascii\n$vi    \\x00cc_addfp_l\\x00\n",
    "${vi}cc_add_t0_s0:\n$vi  ascii\n$vi    \\x00cc_addfp_l\\x00\n${vi}cc_andt_s:\n$vi  ascii\n$vi    \\x00cc_andt\\x00\n${vi}cc_and_s:\n$vi  ascii\n$vi    \\x00cc_and\\x00\n", 'cc_add_t0_s0');

# ---- declare: the alignment it chose (wa_last), the variable's own none
edit(\$t, 'declare', "        LB:\n          mv\n            t3\n            a0\n",
    "        LB:\n          mv\n            t3\n            a0\n" . asm(10, "
    la wa_last t4
    sd 0 a0 t4
"), "          sd\n            VAR_type\n            s5\n            a0\n          leave3\n",
    "          sd\n            VAR_type\n            s5\n            a0\n" . asm(10, "
    la cc_vars t0
    sub t0 a0 t1
    srli 2 t1 t1
    la wa_tab t0
    add t0 t1 t1
    sd 0 zero t1
    leave3
"));

# ---- decl: a local (a scalar, or a record or array without items) past
# the base's alignment is placed by walocal
my $tail = "          call\n            declare\n          mv\n            a0\n            s9\n";
my $sync = "          call\n            syncsp\n          mv\n            s9\n            a0\n          call\n            vaddrt0\n          mv\n            s7\n            a0\n";
{
    my ($from, $to) = find(\$t, 'decl');
    my $e = substr($t, $from, $to - $from);
    my $st = "$sync          call\n            store\n";
    my $n = $e =~ s/\Q$tail$st\E/$tail . asm(10, "
    mv s9 a0
    li 1 a1
    call walocal
") . $st/ge;
    die "lalign: decl: $n stores, not 2 (a scalar, a VLA's address)\n" unless $n == 2;
    substr($t, $from, $to - $from) = $e;
}
edit(\$t, 'decl',
    "$tail$sync          call\n            tsize\n",
    $tail . asm(10, "
    mv s9 a0
    seqz s8 a1
    call walocal
") . "$sync          call\n            tsize\n");

# ---- vaddr, vaddrt0: the address rounded down to the variable's alignment
{
    my ($from, $to) = find(\$t, 'vaddr');
    substr($t, $from, $to - $from) = fn('vaddr', "
    enter1
    mv a0 s4
    ld VAR_off s4 a0
    neg a0 a0
    li R_a0 a1
    call li
    la cc_add_s0 a0
    call seq
    mv s4 a0
    call waget
    beqz V1 a0
    neg a0 a0
    li R_t0 a1
    call li
    la cc_and_s a0
    call seq
V1:
    ld VAR_type s4 a0
    call setty
    leave1
", 6);
}
{
    my ($from, $to) = find(\$t, 'vaddrt0');
    substr($t, $from, $to - $from) = fn('vaddrt0', "
    enter1
    mv a0 s4
    ld VAR_off a0 a0
    neg a0 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s4 a0
    call waget
    beqz V9 a0
    neg a0 a0
    li R_t1 a1
    call li
    la cc_andt_s a0
    call seq
V9:
    leave1
", 6);
}

# ---- secl: a cleanup's alias has its variable's alignment
edit(\$t, 'secl', "          ld\n            VAR_type\n            s7\n            t1\n          sd\n            VAR_type\n            t1\n            t2\n",
    "          ld\n            VAR_type\n            s7\n            t1\n          sd\n            VAR_type\n            t1\n            t2\n" . asm(10, "
    la cc_vars t3
    sub t3 s7 t4
    srli 2 t4 t4
    la wa_tab t5
    add t5 t4 t4
    ld 0 t4 t4
    sub t3 t2 t6
    srli 2 t6 t6
    add t5 t6 t6
    sd 0 t4 t6
"));

# ---- the new functions, in cc's layer 4
my $h = '';
# waget: a0 a variable (in cc_vars): a0 its alignment of its own (wa_tab), 0 none
$h .= fn('waget', "
    la cc_vars t0
    sub t0 a0 t1
    srli 2 t1 t1
    la wa_tab t0
    add t0 t1 t1
    ld 0 t1 a0
    ret
", 6);
# walocal: a0 the variable declare made, a1 1 if it may be placed: where
# declare's alignment (wa_last) is past what the base keeps (twice a slot, at
# most 16: aarch64's slot is 16), its room grows by the alignment less a
# slot below it, and wa_tab has the alignment
$h .= fn('walocal', "
    enter2
    mv a0 s4
    beqz W9 a1
    la wa_last t0
    ld 0 t0 s5
    call slot
    slli 1 a0 t1
    li 16 t2
    bgeu rel:W1 t1 t2
    mv t2 t1
W1:
    bgeu rel:W9 s5 t1
    sub a0 s5 t2
    la ccs t0
    ld CC_depth t0 t1
    add t2 t1 t1
    sd CC_depth t1 t0
    la cc_vars t0
    sub t0 s4 t1
    srli 2 t1 t1
    la wa_tab t0
    add t0 t1 t1
    sd 0 s5 t1
W9:
    leave2
", 6);
{
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}
save();
