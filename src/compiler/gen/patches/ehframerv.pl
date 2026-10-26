# ehframerv.pl: -g's .eh_frame for riscv64's variadic functions under the
# lp64d ABI (abirv.pl): cc_enter_va keeps a0..a7 above the return address
# and the old frame pointer, the CFA is the frame pointer + 80. A sixth
# frame (5, after arm's variadic 4) of dbg_fde and dbg_tpar: cc_enter_va's
# first word (addi sp, sp, -80), a prologue of 48 bytes (the CFA sp + 80,
# ra at CFA - 72, s0 at CFA - 80, then s0 + 80), cc_leave_va's epilogue as
# cc_leave's with 80; dbgeh takes it on riscv64 where a function starts
# with that word (it had none: libgcc's walk stopped past one, debug's
# vdeep). After ehframe.pl and abirv.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub dw { my @b = @_; push @b, 0 while @b % 8; my $s = ''; while (@b) { my @d = splice @b, 0, 8; $s .= "    dword\n      " . sprintf("0x%016x", unpack 'Q<', pack 'C8', @d) . "\n" } $s }
my @pro = (0x44, 0x0e, 0x50, 0x64, 0x81, 0x09, 0x44, 0x88, 0x0a, 0x44, 0x0d, 0x08);
my @epi = (0x0c, 0x02, 0x50, 0x48, 0xc1, 0xc8, 0x44, 0x0e, 0x00);
my @f = (0, 0, @pro, 0x04, 0, 0, 0, 0, @epi);
push @f, 0 while @f < 32;
my @p = (unpack('C4', pack 'V', 0xfb010113), unpack('C4', pack 'V', 0x00008067), 48, 16, 2 + @pro + 1, 1, 0, 0, 0, 0);
for ([dbg_fde => dw(@f)], [dbg_tpar => dw(@p)]) {
    my ($l, $add) = @$_;
    $t =~ /^  \Q$l\E:\n(?:    .*\n|      .*\n)*/m or die "ehframerv: no $l\n";
    my $end = $+[0];
    substr($t, $end, 0) = $add;
}
$t =~ s/(per frame \(16 bytes\): the first word of cc_enter, the last of cc_leave)/$1 (riscv64, x86_64, aarch64, arm, arm variadic, riscv64 variadic)/ or die "ehframerv: no dbg_tpar comment\n";
edit(\$t, 'dbgeh', asm(6, "
    mv a0 s5
    li 3 t0
    bne rel:E3 t0 s11
"), asm(6, "
    mv a0 s5
    bnez ER s11
    la dbg_tpar a0
    addi 80 a0 a0
    li 4 a1
    call drd
    bne rel:E3 a0 s5
    li 5 s11
    j E3
") . asm(4, "
ER:
    li 3 t0
    bne rel:E3 t0 s11
"));
# (kinds 3 and 4 are arm's, which have .ARM.exidx entries; 5 is not)
edit(\$t, 'dbgeh', asm(6, "
    addi 1 s8 s8
    li 3 t0
    bltu rel:E2 t0 s11
"), asm(6, "
    addi 1 s8 s8
    li 5 t0
    beq rel:E2 t0 s11
    li 3 t0
    bltu rel:E2 t0 s11
"));
save();
