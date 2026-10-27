# optwide.pl: -O, stage B's one-instruction range per target (lane S3),
# after opt.pl, setopt.pl, optdead.pl, optli.pl, optfold.pl and optsync.pl;
# run on ttpc.ff, then with T=macros/<target>.ff.txt (each target, then
# make refresh).
#
#   Stage B made cc_li off, cc_addfp, the load (and the store twin) one
#   cc_ldfp_X off only for off in -255..255 (what every target encodes in
#   one instruction), cc_ldfx_X for li's cc_li_big; a local at -2048..-256
#   stayed li + add + load (in fftext and unlicense under qemu about 9% of
#   the instructions run). With -O a pattern now starts on li's cc_li_pos
#   and cc_li_neg of any value (not 0) too, and its end picks the form by
#   the target (targ_abi, cc_abi of the section) and the offset:
#     cc_ldfp_X off, one instruction, where the target encodes off in it:
#       riscv64 -2048..2047 (lb lh lw ld lbu lhu lwu, sb sh sw sd),
#       x86_64 any (disp32), arm -4095..4095 for ldr str ldrb strb and
#       -255..255 for ldrsb ldrh ldrsh strh, aarch64 -255..255 (ldur),
#       another section -255..255;
#     cc_ldfm_X off (aarch64 alone, off in -4095..-256): sub of fp into V
#       for a load (L for a store), then the load or store at it (2, not 3);
#     else cc_ldfx_X off (optfold.pl, any 32-bit offset).
#   (riscv64 and arm keep floats in V as bits: a float local is one of
#   these loads too; arm's ldrd and vldr are not in the C layer's loads.)
#
# The decisions depend only on the primitives' names, li's values (frame
# offsets, known in both passes) and the target: pass 1 and 2 make the
# same. Not inside compile time (opt holds nothing there). Without -O
# every byte is as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my @ld = qw(i8 i16 i32 i64 u8 u16 u32 u64);
my @st = qw(8 16 32 64);

if ($t =~ /^opt:\n/m) {
    my ($k) = $tf =~ m{(\w+)\.ff\.txt$};
    my %c = (riscv64 => '-2048..2047', x86_64 => 'any (disp32)',
        arm => '-4095..4095 for ldr, str, ldrb, strb and -255..255 for ldrsb, ldrh, ldrsh, strh',
        aarch64 => '-255..255; cc_ldfm_* for -4095..-256: sub of fp (V for a load, L for a store), then the load or store at it');
    die "optwide: $tf: not macros/<target>.ff.txt\n" unless $k && $c{$k};
    my ($g) = $t =~ m{^(opt:\n(?: .*\n)*)}m or die "optwide: $tf: no opt group\n";
    my $out = '';
    if ($k eq 'aarch64') {
        my %body;
        while ($g =~ /^  (cc_(?:ldfp|stfp)_\w+):\n    off\n((?:    .*\n)+?)(?=^  \S)/mg) { $body{$1} = $2 }
        for my $i (0 .. $#ld + @st) {
            my $ldst = $i < @ld;
            my ($old, $new) = $ldst ? ("cc_ldfp_$ld[$i]", "cc_ldfm_$ld[$i]") : ("cc_stfp_$st[$i - @ld]", "cc_stfm_$st[$i - @ld]");
            my $b = $body{$old} // die "optwide: $tf: no $old\n";
            my ($op) = $b =~ /^    (\S+)\n/ or die;
            $op =~ s/^(ld|st)ur/$1r/ or die "optwide: $tf: $old: $op\n";
            my $r = $ldst ? 'x0' : 'x9';
            $out .= "  $new:\n    off\n    subi\n      sub\n        off\n        zero\n        a0\n      x29\n      $r\n"
                . "    $op\n      0\n      $r\n      x0\n";
        }
    }
    my $c = "    with -O (optwide.pl) stage B's cc_ldfp_* and cc_stfp_* take off in $c{$k}.\n";
    my $cnt = $t =~ s{^(opt:\n  comment\n(?:    .*\n)+)((?: .*\n)*?)(?=^\S|\z)}{$1$c$2$out}m;
    $cnt == 1 or die "optwide: $tf: $cnt opt groups\n";
    save();
    exit;
}

# the three forms of the twelve, loads then stores (12 bytes each)
my $tab = sub { my ($l, $p) = @_; "  $l:\n    ascii\n      " . join('', map { my $s = "cc_$_"; $s . ('\x00' x (12 - length $s)) }
    (map("ld${p}_$_", @ld), map("st${p}_$_", @st))) . "\n" };
once(\$t, "  cc_loads:\n", $tab->('opt_fps', 'fp') . $tab->('opt_fms', 'fm') . $tab->('opt_fxs', 'fx') . "  cc_loads:\n", 'cc_loads');

# opt_spht (optsync.pl, the names that leave sp as it is) gets aarch64's
# cc_ldfm_* and cc_stfm_* (x29, x0, x9 only): sp stays known across them
{
    my $re = qr/^(  opt_spnm:\n(?:    ascii\n      .*\n)+)(  align\n    8\n  opt_spht:\n)((?:    dword\n      0x[0-9a-f]{16}\n){128})/m;
    my ($nm, $mid, $tab) = $t =~ $re or die "optwide: no opt_spnm, opt_spht\n";
    my $blob = join '', $nm =~ /^      (.*)$/mg;
    $blob =~ s/\\x00/\0/g;
    my @slot;
    my @d = $tab =~ /0x([0-9a-f]{16})/g;
    for my $d (0 .. 127) { $slot[4 * $d + $_] = hex substr($d[$d], (3 - $_) * 4, 4) for 0 .. 3 }
    sub hh { my $h = 0; $h = ($h * 31 + ord) & 0xffffffff for split //, $_[0]; $h & 511 }
    my $add = '';
    for my $n (map("cc_ldfm_$_", @ld), map("cc_stfm_$_", @st)) {
        die "optwide: $n is in opt_spnm already\n" if index($blob, "\0$n\0") >= 0;
        my $i = hh($n);
        $i = ($i + 1) & 511 while $slot[$i];
        $slot[$i] = length $blob;
        $blob .= "$n\0"; $add .= "$n\\x00";
    }
    die "optwide: the names are past 32 KiB\n" if length $blob > 32767;
    $tab = join '', map { my $d = $_; "    dword\n      0x" . join('', map { sprintf "%04x", $slot[4 * $d + 3 - $_] } 0 .. 3) . "\n" } 0 .. 127;
    $t =~ s/$re/$1    ascii\n      $add\n$2$tab/ or die;
}

# SB: a pattern starts on li's cc_li_pos, cc_li_neg (any value but 0) or
# cc_li_big, of a value in -2^31..2^31-2049
edit(\$t, 'opt', asm(10, "
    beqz BO s9
    la cc_names t0
    addi 20 t0 t0
    bne rel:BG t0 s4
    slli 32 s6 t0
"), asm(10, "
    beqz BO s9
    beqz BO s6
    slli 32 s6 t0
"), asm(10, "
    j B0
") . asm(8, "
    BG:
    beqz BO s6
    addi 255 s6 t0
    li 511 t1
    bgeu rel:BO t1 t0
    la opt_lipos a2
"), asm(10, "
    la cc_names t0
    addi 20 t0 t0
    beq rel:B0 t0 s4
    la opt_lipos a2
"));
# the load and the store: SEL picks the form
edit(\$t, 'opt', asm(10, "
    li 12 t0
    mul t0 a0 a0
    la opt_ldfps t0
    la optb_buf t1
    ld 0 t1 t1
    la cc_names t2
    addi 20 t2 t2
    bne rel:BG1 t2 t1
    la opt_ldfxs t0
") . asm(8, "
    BG1:
    add t0 a0 a0
"), asm(10, "
    la optb_buf t0
    ld 16 t0 a2
    call SEL
"), asm(10, "
    li 12 t0
    mul t0 a0 a0
    la opt_stfps t0
    la optb_buf t1
    ld 0 t1 t1
    la cc_names t2
    addi 20 t2 t2
    bne rel:BG2 t2 t1
    la opt_stfxs t0
") . asm(8, "
    BG2:
    add t0 a0 a0
"), asm(10, "
    addi 8 a0 a0
    la optb_buf t0
    ld 16 t0 a2
    call SEL
"), asm(10, "
    addi 512 sp sp
    ret
"), asm(10, "
    addi 512 sp sp
    ret
") . asm(8, "
    # SEL: a0 the kind (0..7 the loads of opt_lds, 8..11 the stores of
    # opt_sts), a2 the frame offset -> a0 the name of its form: cc_ldfp_*
    # or cc_stfp_* where the target (targ_abi: 1 arm, 2 aarch64, 3 x86_64,
    # 4 riscv64) encodes the offset in the instruction, aarch64's cc_ldfm_*
    # or cc_stfm_* for -4095..-256, else cc_ldfx_* or cc_stfx_*
    SEL:
    la opt_fps t3
    la targ_abi t0
    ld 0 t0 t0
    li 3 t1
    beq rel:SR t1 t0
    li 255 t4
    li 4 t1
    bne rel:S1 t1 t0
    li32 2047 t4
    li32 -2048 t5
    j S3
    S1:
    li 1 t1
    bne rel:S2 t1 t0
    # arm: ldr, str, ldrb, strb (i32 i64 u8 u32 u64, 8 32 64) take 4095
    li32 3548 t1
    srl a0 t1 t1
    andi 1 t1 t1
    beqz S2 t1
    li32 4095 t4
    S2:
    sub t4 zero t5
    S3:
    blt rel:S4 t5 a2
    blt rel:S4 a2 t4
    j SR
    S4:
    la opt_fxs t3
    li 2 t1
    bne rel:SR t1 t0
    bge rel:SR zero a2
    li32 -4095 t1
    blt rel:SR t1 a2
    la opt_fms t3
    SR:
    li 12 t1
    mul t1 a0 a0
    add t3 a0 a0
    ret
"));
$t =~ s/^(      opt:\n        comment\n)/$1          with -O stage B takes each target's one-instruction offsets, aarch64 sub + load to -4095 (optwide.pl)\n/m or die;
save();
