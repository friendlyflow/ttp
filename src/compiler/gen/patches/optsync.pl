# optsync.pl: -O, syncsp left out where sp already is fp - depth (lane S3),
# after opt.pl, setopt.pl, optdead.pl, optli.pl and optfold.pl; run on
# ttpc.ff (in src/compiler: it reads macros/<target>.ff.txt).
#
#   syncsp (after a block, a declaration, a statement) sets sp = fp -
#   depth: li -depth into L, cc_spfp. Most of the time sp is that already.
#   With -O syncsp's li carries a name of its own (opt_syn, the layout of
#   cc_names: prim takes it for li's there, flagged by opt_insync), and
#   prim0, where every primitive is emitted (after opt's stages, so in the
#   order and form the code has), keeps what sp is: after syncsp's li of v
#   and its cc_spfp (cc_sp_s0_t0's name) sp is fp + v (opt_spk, opt_spv).
#   A next syncsp's li of the same v is then dropped, and its cc_spfp
#   after it (opt_spdrop). Any primitive that is not in a list of the
#   ones that leave sp as it is (opt_spht, a hash table of their names in
#   opt_spnm) forgets it, and so does every label, macro or byte that does
#   not come from prim0 (optflush outside prim0: labels, place, asm,
#   emit_raw, skip, ctrun, jit, generic), and each pass at its start:
#   only a straight line of primitives since the last cc_spfp keeps it.
#
#   The list is every macro of the groups c: and opt: of all four targets
#   (macros/<target>.ff.txt) but those that on any target name the stack
#   pointer (sp, rsp, wsp), push, pop, call, return or trap in their body
#   (x86_64's push, pop, call, leave, ret; jal, jalr, bl, blr, blx, svc,
#   ecall, syscall), or use a macro that does: cc_push, cc_pop, cc_drop,
#   cc_arg, cc_call*, cc_enter, cc_leave, cc_spfp, cc_syscall, ... are
#   not in it. A conditional branch is (sp is the same after it; where it
#   goes is a label). A primitive added later is in none: it forgets.
#
# The decisions depend only on the primitives' names and li's values, the
# same in both passes. Not inside compile time (CC_jit). Without -O every
# byte is as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# ---- the list: the macros of c: and opt: that leave sp as it is
my (%all, %kill, %body);
for my $k (qw(riscv64 x86_64 aarch64 arm)) {
    open my $h, '<', "macros/$k.ff.txt" or die "optsync: macros/$k.ff.txt: $!\n";
    my ($g, $m, $op, $last);
    # an instruction of a body (at 4 spaces) is done at the next one: riscv64's
    # jal and jalr into zero are a jump, into ra a call
    my $done = sub {
        $kill{$m}++ if defined $op && $op =~ /^(jal|jalr)$/ && ($last // '') ne 'zero';
        $op = $last = undef;
    };
    while (<$h>) {
        if (/^(\S+):$/) { $done->() if defined $m; $g = $1; $m = undef; next }
        if (/^  (\S+):$/) { $done->() if defined $m; $m = "$k $1"; $all{$1}++ if $g eq 'c' || $g eq 'opt'; next }
        next unless defined $m;
        if (/^( +)(\S+)$/) {
            my ($i, $w) = (length $1, $2);
            if ($i == 4) { $done->(); $op = $w } elsif ($i == 6) { $last = $w }
            $kill{$m}++ if $w =~ /^(sp|rsp|esp|wsp)$/
                || ($i == 4 && $w =~ /^(push\S*|pop\S*|call\S*|leave|enter|ret|retr|bl|blr|blx|svc|ecall|syscall|stm\S*|ldm\S*)$/);
            push @{ $body{$m} }, $w;
        }
    }
    $done->() if defined $m;
}
# a macro that uses one of them is one too (on its target)
for (my $more = 1; $more;) {
    $more = 0;
    for my $m (keys %body) {
        next if $kill{$m};
        my ($k) = split ' ', $m;
        if (grep { $kill{"$k $_"} } @{ $body{$m} }) { $kill{$m}++; $more = 1 }
    }
}
my %dead = map { (split ' ')[1] => 1 } keys %kill;
my @keep = sort grep { !$dead{$_} } keys %all;
print STDERR "optsync: forget: ", join(" ", sort grep { $dead{$_} } keys %all), "\n" if $ENV{OPTSYNC_LIST};
die "optsync: cc_spfp is not a stack pointer macro\n" unless $dead{cc_spfp} && $dead{cc_push} && $dead{cc_drop};
die "optsync: cc_ldfp_i64 not kept\n" unless grep { $_ eq 'cc_ldfp_i64' } @keep;

# the hash of a name, as prim0 has it: h = h * 31 + byte, its low 9 bits
sub h { my $h = 0; $h = ($h * 31 + ord) & 0xffffffff for split //, $_[0]; $h & 511 }
my (@slot, $blob, $off) = ((0) x 512);
$blob = "\\x00"; $off = 1;
for my $n (@keep) {
    my $i = h($n);
    $i = ($i + 1) & 511 while $slot[$i];
    $slot[$i] = $off;
    $blob .= "$n\\x00"; $off += length($n) + 1;
}
die "optsync: the names are past 32 KiB\n" if $off > 32767;
my $tab = '';
for my $d (0 .. 127) {
    my $v = join "", map { sprintf "%04x", $slot[4 * $d + 3 - $_] } 0 .. 3;
    $tab .= "    dword\n      0x$v\n";
}
my @nm;
while (length $blob > 200) { $blob =~ s/^(.{180,200}?\\x00)//s or $blob =~ s/^(.{200})//s; push @nm, $1 }
push @nm, $blob if length $blob;
my $nm = join '', map { "    ascii\n      $_\n" } @nm;

# ---- the variables (bss), after opt_jbuf
once(\$t, "  opt_jbuf:\n    reserve\n      48\n", "  opt_jbuf:\n    reserve\n      48\n" . join('', map { "  $_:\n    reserve\n      8\n" }
    qw(opt_spk opt_spv opt_spnew opt_spset opt_spdrop opt_insync opt_inprim)), 'opt_jbuf');
# ---- syncsp's names for li, and the list
once(\$t, "  cc_loads:\n", "  opt_syn:\n    ascii\n      cc_li_pos\\x00cc_li_neg\\x00cc_li_big\\x00\n  opt_spnm:\n$nm  align\n    8\n  opt_spht:\n$tab  cc_loads:\n", 'cc_loads');

# ---- syncsp: its li by opt_syn (with -O)
edit(\$t, 'syncsp', "        call\n          li\n", asm(8, "
    la opt_on t0
    ld 0 t0 t0
    la opt_insync t1
    sd 0 t0 t1
    call li
"));
$t =~ s/^(      syncsp:\n)/$1        comment\n          with -O its li by a name of its own (opt_syn): prim0 leaves it and its cc_spfp out where sp already is fp - depth (optsync.pl)\n/m or die;

# ---- prim: syncsp's li by opt_syn
edit(\$t, 'prim', "        P1:\n          j\n            opt\n", asm(8, "
    P1:
    la opt_insync t0
    ld 0 t0 t1
    beqz P2 t1
    sd 0 zero t0
    la cc_names t0
    sub t0 a0 t1
    li 30 t2
    bgeu rel:P2 t2 t1
    la opt_syn a0
    add t1 a0 a0
    P2:
    j opt
"));

# ---- prim0: what sp is, syncsp's pair dropped where it already is that
edit(\$t, 'prim0', "        bnez\n          Z9\n          t0\n        la\n          cc_names\n          t0\n", "        bnez\n          Z9\n          t0\n" . asm(8, "
    la opt_syn t0
    sub t0 a0 t1
    li 30 t2
    bgeu rel:S1 t2 t1
    la opt_spk t0
    ld 0 t0 t2
    beqz S2 t2
    la opt_spv t0
    ld 0 t0 t2
    bne rel:S2 t2 a2
    li 1 t2
    la opt_spdrop t0
    sd 0 t2 t0
    ret
    S2:
    la opt_spnew t0
    sd 0 a2 t0
    li 1 t2
    la opt_spset t0
    sd 0 t2 t0
    la cc_names a0
    add t1 a0 a0
    j S9
    S1:
    la cc_sp_s0_t0 t0
    addi 1 t0 t0
    bne rel:S3 t0 a0
    la opt_spdrop t0
    ld 0 t0 t1
    beqz S4 t1
    sd 0 zero t0
    ret
    S4:
    la opt_spset t0
    ld 0 t0 t1
    beqz S5 t1
    sd 0 zero t0
    la opt_spnew t0
    ld 0 t0 t1
    la opt_spv t0
    sd 0 t1 t0
    li 1 t1
    la opt_spk t0
    sd 0 t1 t0
    j S9
    S5:
    la opt_spk t0
    sd 0 zero t0
    j S9
    S3:
    la opt_spset t0
    sd 0 zero t0
    la opt_spdrop t0
    sd 0 zero t0
    la opt_spk t0
    ld 0 t0 t1
    beqz S9 t1
    li 0 t1
    mv a0 t2
    S6:
    lbu 0 t2 t3
    beqz S7 t3
    slli 5 t1 t4
    sub t1 t4 t1
    add t3 t1 t1
    addi 1 t2 t2
    j S6
    S7:
    andi 511 t1 t1
    S8:
    la opt_spht t2
    add t1 t2 t2
    add t1 t2 t2
    lbu 0 t2 t3
    lbu 1 t2 t4
    slli 8 t4 t4
    or t4 t3 t3
    beqz SK t3
    la opt_spnm t2
    add t3 t2 t2
    mv a0 t4
    SC:
    lbu 0 t2 t5
    lbu 0 t4 t6
    bne rel:SN t5 t6
    beqz S9 t5
    addi 1 t2 t2
    addi 1 t4 t4
    j SC
    SN:
    addi 1 t1 t1
    andi 511 t1 t1
    j S8
    SK:
    la opt_spk t0
    sd 0 zero t0
    S9:
") . "        la\n          cc_names\n          t0\n");
# prim0's macro: what optflush sees inside it is prim0's own
edit(\$t, 'prim0', "          call\n            code_call\n          leave8\n", asm(10, "
    la opt_inprim t0
    li 1 t1
    sd 0 t1 t0
    call code_call
    la opt_inprim t0
    sd 0 zero t0
    leave8
"));
$t =~ s/^(      prim0:\n        comment\n)/$1          with -O it keeps what sp is after syncsp's cc_spfp, and drops syncsp's li and cc_spfp where sp is that already; a primitive not in opt_spht forgets it (optsync.pl)\n/m or die;

# ---- optflush outside prim0 (a label, a macro or bytes of their own) forgets it
once(\$t, "  optflush:\n    comment\n      with -O, what opt holds emitted (opt_fn, its flush); every register kept but t0\n",
    "  optflush:\n    comment\n      with -O, what opt holds emitted (opt_fn, its flush); every register kept but t0\n      outside prim0 it forgets what sp is (optsync.pl)\n" . asm(4, "
    la opt_inprim t0
    ld 0 t0 t0
    bnez OS t0
    la opt_spk t0
    sd 0 zero t0
    OS:
"), 'optflush');

# ---- generic's compile and each pass: none
my $n = ($t =~ s/^( +)(la\n\1  opt_dead\n\1  t0\n\1sd\n\1  0\n\1  zero\n\1  t0\n\1la\n\1  opt_jheld\n\1  t0\n\1sd\n\1  0\n\1  zero\n\1  t0\n)/$1 . $2 . join('', map { "$1la\n$1  $_\n$1  t0\n$1sd\n$1  0\n$1  zero\n$1  t0\n" } qw(opt_spk opt_spset opt_spdrop opt_insync))/mge);
$n == 2 or die "optsync: the resets: $n\n";
save();
