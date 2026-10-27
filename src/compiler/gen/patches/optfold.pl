# optfold.pl: -O, a big frame offset folded into the load or store (lane
# S3), after opt.pl, setopt.pl, optdead.pl and optli.pl; run on ttpc.ff,
# then with T=macros/<target>.ff.txt (each target, then make refresh).
#
#   Stage B makes cc_li off V, cc_addfp, cc_load_X one cc_ldfp_X off (and
#   the store twin) for off in -255..255. A frame past 2 KiB has its
#   locals further away: li gives cc_li_big (prim0 then cc_li_pos32 or
#   cc_li_neg32), then cc_addfp and the load, on riscv64 lui, addiw, add,
#   ld: in stdlib-prog about 8,000. With -O stage B now starts its
#   patterns on li's cc_li_big too (its name, cc_names + 20) of a value in
#   -2^31..2^31-2049, and makes them cc_ldfx_X off and cc_stfx_N off:
#   riscv64 lui of the high part, add fp, the load or store with the low
#   12 bits (3 instructions, not 4); aarch64 movz + movk of the low 32 bits,
#   the load or store at fp + that register sign-extended (sxtw; 3, not 4);
#   arm movw + movt, the load or store at fp + that register (3, not 4);
#   x86_64 the load or store at rbp + disp32 (1, not 3). A load builds the
#   offset in V, a store in L (no one reads L after it: an L-setter
#   follows).
#
# The decisions depend only on the primitives' names and li's values,
# known in both passes (frame offsets): pass 1 and 2 make the same. Not
# inside compile time (opt holds nothing there). Without -O every byte
# is as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my @ld = qw(i8 i16 i32 i64 u8 u16 u32 u64);
my @st = qw(8 16 32 64);

# (T=macros/<target>.ff.txt, then make refresh: the twelve in the target's
# group opt:)
if ($t =~ /^opt:\n/m) {
    my ($k) = $tf =~ m{(\w+)\.ff\.txt$};
    my %c = (riscv64 => 'lui of the high part, add fp, the load or store with the low 12 bits (in V for a load, L for a store)',
        x86_64 => 'the load or store at rbp + disp32, as cc_ldfp_* and cc_stfp_*',
        aarch64 => 'movz + movk of the low 32 bits (V for a load, L for a store), the load or store at x29 + that register, sxtw',
        arm => 'movw + movt (r0 for a load, r12 for a store), the load or store at r11 + that register');
    die "optfold: $tf: not macros/<target>.ff.txt\n" unless $k && $c{$k};
    my ($g) = $t =~ m{^(opt:\n(?: .*\n)*)}m or die "optfold: $tf: no opt group\n";
    my %body;   # the target's cc_ldfp_* and cc_stfp_*: their instruction and registers
    while ($g =~ /^  (cc_(?:ldfp|stfp)_\w+):\n    off\n((?:    .*\n)+?)(?=^  \S)/mg) { $body{$1} = $2 }
    my $n = sub { my $s = ''; my $d = 0; for (@_) { $s .= ' ' x (4 + 2 * $_->[0]) . "$_->[1]\n" } $s };
    my $out = '';
    for my $i (0 .. $#ld + @st) {
        my $ldst = $i < @ld;
        my ($old, $new) = $ldst ? ("cc_ldfp_$ld[$i]", "cc_ldfx_$ld[$i]") : ("cc_stfp_$st[$i - @ld]", "cc_stfx_$st[$i - @ld]");
        my $b = $body{$old} // die "optfold: $tf: no $old\n";
        my ($op) = $b =~ /^    (\S+)\n/ or die;
        my $m;
        if ($k eq 'x86_64') {
            $m = $b;
        } elsif ($k eq 'riscv64') {
            my $r = $ldst ? 'a0' : 't0';
            $m = $n->([0, 'lui'], [1, 'hi'], [2, 'off'], [1, $r], [0, 'add'], [1, $r], [1, 's0'], [1, $r],
                [0, $op], [1, 'lo'], [2, 'off'], [1, 'a0'], [1, $ldst ? 'a0' : 't0']);
        } elsif ($k eq 'aarch64') {
            my $r = $ldst ? 'x0' : 'x9';
            (my $o = $op) =~ s/^(ld|st)ur/$1r/;
            $m = $n->([0, 'movz'], [1, '0'], [1, 'bits'], [2, 'off'], [2, '48'], [2, '48'], [2, '0'], [1, $r],
                [0, 'movk'], [1, '1'], [1, 'bits'], [2, 'off'], [2, '32'], [2, '48'], [2, '0'], [1, $r],
                [0, "$o.reg"], [1, $r], [1, '6'], [1, '0'], [1, 'x29'], [1, 'x0']);
        } else {
            my $r = $ldst ? 'r0' : 'r12';
            $m = $n->([0, 'movw'], [1, 'lo16'], [2, 'off'], [1, $r], [0, 'movt'], [1, 'hi16'], [2, 'off'], [1, $r],
                [0, "${op}r"], ($op =~ /^(ldr|str|ldrb|strb)$/ ? [1, '0'] : ()), [1, $r], [1, 'r11'], [1, 'r0']);
        }
        $out .= "  $new:\n    off\n$m";
    }
    my $c = "    cc_ldfx_* off, cc_stfx_* off (optfold.pl): as cc_ldfp_* and cc_stfp_*, for li's big offset (-2^31..2^31-2049): $c{$k}.\n";
    my $cnt = $t =~ s{^(opt:\n  comment\n(?:    .*\n)+)((?: .*\n)*?)(?=^\S|\z)}{$1$c$2$out}m;
    $cnt == 1 or die "optfold: $tf: $cnt opt groups\n";
    save();
    exit;
}

# the names of the big forms, as opt_ldfps and opt_stfps (12 bytes each)
once(\$t, "  cc_loads:\n", "  opt_ldfxs:\n    ascii\n      " . join('', map { my $s = "cc_ldfx_$_"; $s . ('\x00' x (12 - length $s)) } @ld)
    . "\n  opt_stfxs:\n    ascii\n      " . join('', map { my $s = "cc_stfx_$_"; $s . ('\x00' x (12 - length $s)) } @st) . "\n  cc_loads:\n", 'cc_loads');

# SB: a pattern also starts on li's cc_li_big of a 32-bit value
edit(\$t, 'opt', asm(10, "
    beqz BO s9
    beqz BO s6
    addi 255 s6 t0
"), asm(10, "
    beqz BO s9
    la cc_names t0
    addi 20 t0 t0
    bne rel:BG t0 s4
    slli 32 s6 t0
    srai 32 t0 t0
    bne rel:BO t0 s6
    li32 2048 t1
    add t1 s6 t1
    slli 32 t1 t0
    srai 32 t0 t0
    bne rel:BO t0 t1
    j B0
") . asm(8, "
    BG:
    beqz BO s6
    addi 255 s6 t0
"));
# the load and the store: the big forms where the pattern's li is li's cc_li_big
for (['ldfps', 'ldfxs', 'BG1'], ['stfps', 'stfxs', 'BG2']) {
    my ($s, $b, $l) = @$_;
    edit(\$t, 'opt', asm(10, "
        la opt_$s t0
        add t0 a0 a0
    "), asm(10, "
        la opt_$s t0
        la optb_buf t1
        ld 0 t1 t1
        la cc_names t2
        addi 20 t2 t2
        bne rel:$l t2 t1
        la opt_$b t0
    ") . asm(8, "
        $l:
        add t0 a0 a0
    "));
}
$t =~ s/^(      opt:\n        comment\n)/$1          with -O stage B also folds li's cc_li_big of a 32-bit frame offset: cc_ldfx_* off, cc_stfx_* off (optfold.pl)\n/m or die;
save();
