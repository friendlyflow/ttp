# fnegqseq.pl (on macros/<target>.ff.txt, then make refresh): cc_fneg_q, -
# of a long double in memory (a0's address) into the temporary at the
# frame's base + t1, whose address it leaves in a0: the low word copied,
# the high word's bit 63 flipped (riscv64 and aarch64 through a double
# register's fneg, which keeps a NaN's bits; x86_64 btc); on arm, whose
# long double is double, cc_fneg_dm's. See fnegq.pl. Run on each target's
# macros: make patch P=gen/patches/fnegqseq.pl T=macros/riscv64.ff.txt (and
# x86_64, aarch64, arm).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my %seq = (
    riscv64 => "add t1 s0 t1\nld 0 a0 t0\nsd 0 t0 t1\nld 8 a0 t0\nfmv.d.x t0 ft0\nfsgnjn.d ft0 ft0 ft0\nfmv.x.d ft0 t0\nsd 8 t0 t1\nmv t1 a0\n",
    x86_64 => "addq rbp r11\nmovq.m 0 rax r10\nmovq.mr r10 0 r11\nmovq.m 8 rax r10\nbtcq.i 63 r10\nmovq.mr r10 8 r11\nmovq r11 rax\n",
    aarch64 => "add x29 x10 x10\nldr 0 x0 x9\nstr 0 x10 x9\nldr 8 x0 x9\nfmov.d.x x9 d16\nfneg.d d16 d16\nfmov.x.d d16 x9\nstr 8 x10 x9\nmov x10 x0\n",
    arm => "vldr.64 0 r0 d6\nvneg.f64 d6 d6\nadd r8 r11 r8\nvstr.64 0 r8 d6\nmov r8 r0\n",
);
# in the target's c: group: before its cc_cvt_d_l (arm's cc_cvt_dm_l)
my ($tg) = $tf =~ m{(\w+)\.ff\.txt$};
die "fnegqseq: $tf: not macros/<target>.ff.txt\n" unless $tg && $seq{$tg};
my $mark = $tg eq 'arm' ? "  cc_cvt_dm_l:\n" : "  cc_cvt_d_l:\n";
once(\$t, "\n$mark", "\n" . fn('cc_fneg_q', $seq{$tg}) . $mark, $mark);
save();
