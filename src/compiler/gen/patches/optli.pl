# optli.pl: -O, the inline 8-byte constants (lane S3), after opt.pl,
# setopt.pl and optdead.pl; run on ttpc.ff, then with T=ttpc.defs.ff and
# T=macros/<target>.ff.txt (each target, then make refresh).
#
#   li gives a value past -2048..2047 to cc_li_big, on riscv64 auipc, ld,
#   j +12 and the 8 bytes (20 bytes, 3 instructions): in stdlib-prog 21,000
#   of them, nearly all frame offsets (sp = fp - depth, a local at fp - off)
#   of the frames past 2 KiB. Their value is known in both passes (li
#   already picks cc_li_pos, cc_li_neg or cc_li_big by it), so with -O prim0
#   (the last step, after opt's stages) makes li's cc_li_big of a value in
#   -2^31..2^31-2049 cc_li_pos32 (not negative) or cc_li_neg32: riscv64 lui
#   + addiw (8 bytes), aarch64 movz + movk or movn + movk (2 instructions,
#   not 4), x86_64 movq.i (7 bytes, not 10); arm's cc_li_big is movw + movt
#   already, its two are the same. A cc_li_big is li's when its name is
#   li's own (cc_names + 20): every other caller hands a name of its own.
#
#   The TLS offset (tlsaddr: a thread local's offset in the TLS image,
#   negative on x86_64) pass 1 may not know, so with -O it is cc_li_pos32
#   or cc_li_neg32 by its sign, which have one size on every target: pass
#   1 may pick the other, never another size. Pass 2 stops where it is not
#   in -2^31..2^31-2049 (an image past 2 GiB). Without -O it is cc_li_big
#   by a name of its own.
#
# The decisions depend only on the value li has in both passes (the TLS
# offset's only between two forms of one size): pass 1 and 2 lay out the
# same. Not inside compile time (CC_jit). Without -O every byte is as before.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# (T=macros/<target>.ff.txt, then make refresh: the two in the target's
# group opt:)
if ($t =~ /^opt:\n/m) {
    my %m = (
        riscv64 => [("lui\n  hi\n    value\n  rd\naddiw\n  lo\n    value\n  rd\n  rd\n") x 2],
        x86_64 => [("movq.i\n  value\n  rd\n") x 2],
        aarch64 => ["movz\n  0\n  bits\n    value\n    48\n    48\n    0\n  rd\nmovk\n  1\n  bits\n    value\n    32\n    48\n    0\n  rd\n",
            "movn\n  1\n  bits\n    xori\n      -1\n      value\n      a0\n    32\n    48\n    0\n  rd\nmovk\n  0\n  bits\n    value\n    48\n    48\n    0\n  rd\n"],
        arm => [("movw\n  lo16\n    value\n  rd\nmovt\n  hi16\n    value\n  rd\n") x 2],
    );
    my %c = (riscv64 => 'lui + addiw', x86_64 => 'movq.i, a sign-extended imm32',
        aarch64 => 'movz + movk (pos32), movn + movk (neg32)', arm => "movw + movt, as cc_li_big (arm's values are 32-bit)");
    my ($k) = $tf =~ m{(\w+)\.ff\.txt$};
    die "optli: $tf: not macros/<target>.ff.txt\n" unless $k && $m{$k};
    my $in = sub { join '', map { "    $_\n" } split /\n/, $_[0] };
    my $n = $t =~ s{^opt:\n  comment\n((?:    .*\n)+)((?: .*\n)*?)(?=^\S|\z)}{
        "opt:\n  comment\n$1    cc_li_pos32 value rd, cc_li_neg32 value rd (optli.pl): rd = value, li's constant in 2048..2^31-2049 or -2^31..-2049 (and the TLS offset): $c{$k}.\n$2"
            . "  cc_li_pos32:\n    value\n    rd\n" . $in->($m{$k}[0]) . "  cc_li_neg32:\n    value\n    rd\n" . $in->($m{$k}[1]);
    }me;
    $n == 1 or die "optli: $tf: $n opt groups\n";
    save();
    exit;
}

# (T=ttpc.defs.ff: its message's length)
if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_tlslate_len:\n    size\n      msg_tlslate\n", "  msg_tlslate_len:\n    size\n      msg_tlslate\n  msg_tlsbig_len:\n    size\n      msg_tlsbig\n", 'msg_tlslate_len');
    save();
    exit;
}

once(\$t, "  opt_libig:\n    ascii\n      cc_li_big\\x00\n", "  opt_libig:\n    ascii\n      cc_li_big\\x00\n" . join('', map { "  $_->[0]:\n    ascii\n      $_->[1]\n" }
    [opt_lip32 => 'cc_li_pos32\x00'], [opt_lin32 => 'cc_li_neg32\x00'], [opt_libigt => 'cc_li_big\x00']), 'opt_libig');
once(\$t, "  msg_tlslate:\n    ascii\n", "  msg_tlsbig:\n    ascii\n      ttpc: a thread local past 2 GiB in the TLS image, with -O:\\x20\n  msg_tlslate:\n    ascii\n", 'msg_tlslate');

# prim0: li's cc_li_big of a 32-bit value
once(\$t, "      prim0:\n        enter8\n", "      prim0:\n" . asm(8, "
    la opt_on t0
    ld 0 t0 t0
    beqz Z9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez Z9 t0
    la cc_names t0
    addi 20 t0 t0
    bne rel:Z9 t0 a0
    slli 32 a2 t0
    srai 32 t0 t0
    bne rel:Z9 t0 a2
    li32 2048 t1
    add t1 a2 t1
    slli 32 t1 t0
    srai 32 t0 t0
    bne rel:Z9 t0 t1
    la opt_lip32 a0
    bltz Z8 a2
    j Z9
    Z8:
    la opt_lin32 a0
    Z9:
") . "        enter8\n", 'prim0');
$t =~ s/^(      prim0:\n)/$1        comment\n          with -O li's cc_li_big of a value in -2^31..2^31-2049 is cc_li_pos32 or cc_li_neg32 (optli.pl), outside compile time\n/m or die;

# tlsaddr: the offset by cc_li_pos32 or cc_li_neg32, of one size on every
# target: pass 1 may pick the other (its offset may be wrong), not another size
edit(\$t, 'tlsaddr', "        la\n          cc_names\n          a0\n        addi\n          20\n          a0\n          a0\n", asm(8, "
    la opt_libigt a0
    la opt_on t0
    ld 0 t0 t0
    beqz T9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez T9 t0
    la opt_lip32 a0
    bltz T7 a2
    j T6
    T7:
    la opt_lin32 a0
    T6:
    la pass t0
    ld 0 t0 t0
    li 2 t1
    bne rel:T9 t1 t0
    slli 32 a2 t0
    srai 32 t0 t0
    bne rel:T8 t0 a2
    li32 2048 t1
    add t1 a2 t1
    slli 32 t1 t0
    srai 32 t0 t0
    beq rel:T9 t0 t1
    T8:
    la msg_tlsbig a1
    li msg_tlsbig_len a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
    T9:
"));

save();
