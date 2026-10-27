# andt.pl (on macros/<target>.ff.txt, then make refresh): cc_andt, t0 =
# t0 and t1: the address of a local aligned past what the frame's base
# keeps (lalign.pl), its address rounded down to its alignment (t1 its
# negative). Run on each target's macros: make patch P=gen/patches/andt.pl
# T=macros/riscv64.ff.txt (and x86_64, aarch64, arm).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my %seq = (
    riscv64 => "and t1 t0 t0\n",
    x86_64 => "andq r11 r10\n",
    aarch64 => "and x10 x9 x9\n",
    arm => "and r8 r12 r12\n",
);
my ($tg) = $tf =~ m{(\w+)\.ff\.txt$};
die "andt: $tf: not macros/<target>.ff.txt\n" unless $tg && $seq{$tg};
once(\$t, "\n  cc_and:\n", "\n" . fn('cc_andt', $seq{$tg}) . "  cc_and:\n", 'cc_and');
save();
