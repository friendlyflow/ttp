# pairexact.pl: a pair (i64 and u64 on arm, pairs.pl) is its two type codes
# exactly, 0x48 and 0x58 ((code | 16) == 88), not any code with the bit 0x40:
# x86_64's signed char is 65 (charsign.pl), which the bit alone took for a
# pair. ispair, tsize, talign and opseq test it so.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub E { my ($fn, $ind, @p) = @_; edit(\$t, $fn, map { asm($ind, $_) } @p) }

E('cc/ispair', 8, "
    andi 64 a0 a0
    srli 6 a0 a0
    ret
", "
    li 16 t0
    or t0 a0 a0
    addi -88 a0 a0
    seqz a0 a0
    ret
");
for my $f ('cc/tsize', 'cc/talign') {
    E($f, 10, "
        andi 64 a0 t0
        bnez L2 t0
    ", "
        li 16 t0
        or t0 a0 t0
        li 88 t1
        beq rel:L2 t1 t0
    ");
}
E('cc/opseq', 8, "
    andi 64 a0 t2
    beqz L1 t2
", "
    li 16 t2
    or t2 a0 t2
    li 88 t3
    bne rel:L1 t3 t2
");
save();
