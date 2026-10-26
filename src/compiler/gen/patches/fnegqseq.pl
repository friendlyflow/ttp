# fnegqseq.pl (on shared.ff): cc_fneg_q, - of a long double in memory
# (a0's address) into the temporary at the frame's base + t1, whose
# address it leaves in a0: the low word copied, the high word's bit 63
# flipped (riscv64 and aarch64 through a double register's fneg, which
# keeps a NaN's bits; x86_64 btc); on arm, whose long double is double,
# cc_fneg_dm's. See fnegq.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my %seq = (
    riscv64 => "add t1 s0 t1\nld 0 a0 t0\nsd 0 t0 t1\nld 8 a0 t0\nfmv.d.x t0 ft0\nfsgnjn.d ft0 ft0 ft0\nfmv.x.d ft0 t0\nsd 8 t0 t1\nmv t1 a0\n",
    x86_64 => "addq rbp r11\nmovq.m 0 rax r10\nmovq.mr r10 0 r11\nmovq.m 8 rax r10\nbtcq.i 63 r10\nmovq.mr r10 8 r11\nmovq r11 rax\n",
    aarch64 => "add x29 x10 x10\nldr 0 x0 x9\nstr 0 x10 x9\nldr 8 x0 x9\nfmov.d.x x9 d16\nfneg.d d16 d16\nfmov.x.d d16 x9\nstr 8 x10 x9\nmov x10 x0\n",
    arm => "vldr.64 0 r0 d6\nvneg.f64 d6 d6\nadd r8 r11 r8\nvstr.64 0 r8 d6\nmov r8 r0\n",
);
# each target's c: group, in the page's order: before its cc_cvt_d_l
# (arm's cc_cvt_dm_l)
my $pos = 0;
for my $tg (qw(riscv64 x86_64 aarch64 arm)) {
    my $mark = $tg eq 'arm' ? "\n      cc_cvt_dm_l:\n" : "\n      cc_cvt_d_l:\n";
    my $i = index($t, $mark, $pos);
    die "fnegqseq: no $mark for $tg\n" if $i < 0;
    my $s = "\n" . fn('cc_fneg_q', $seq{$tg}, 6);
    $s =~ s/\n$//;
    substr($t, $i, 0) = $s;
    $pos = $i + length($s) + length($mark);
}
save();
