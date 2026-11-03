# complexq.pl: the type word complex float128 (the user's choice, 2026-11-02;
# C's _Complex __float128), beside complex float, complex double and complex
# long double: a word after what cc_tynames has, a struct type of ttpc's own whose fields real
# part and imag part are float128s, 32 bytes, in memory by every ABI. ~ of one
# flips the top bit of its last four bytes as ~ of binary128's complex long
# double does, on x86_64 too, where complex long double's is the x87's sign
# (x87.pl). After complexty.pl, complexops.pl and x87.pl. Test: ccomplexq.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# the word after what cc_tynames has (a node holds 255 bytes: in an ascii of
# its own), tyname its struct before the checks of the words before it
$t =~ /^ *cc_tynames:\n(.*?)^  cc_tycodes:/ms or die 'cc_tynames';
my $tl = $1;
my $idx = (() = $tl =~ /\\x00/g) - 1;
$tl =~ /([^\n]*)\\x00\\x00\n\z/ or die 'cc_tynames end';
my $last = $1;
once(\$t, "$last\\x00\\x00\n", "$last\\x00\n    ascii\n      complex float128\\x00\\x00\n", 'cc_tynames');
edit(\$t, 'tyname', asm(8, "
    call lookup
    bltz L1 a0
") => asm(8, "
    call lookup
    bltz L1 a0
    li $idx t0
    beq rel:LCQ t0 a0
"));
{
    my ($from, $to) = find(\$t, 'tyname');
    substr($t, $to, 0) = asm(8, "
LCQ:
    la cxn_q a0
    call struct
    leave1
");
}

my $node = sub {
    my ($label, $text, @kids) = @_;
    my $s = "  $label:\n    reserve\n      32\n    dword\n      " . scalar(@kids) . "\n    dword\n      " . (@kids ? "${label}_k" : 0)
        . "\n    dword\n      " . length($text) . "\n    dword\n      ${label}_t\n";
    $s .= "  ${label}_k:\n" . join('', map { "    dword\n      $_\n" } @kids) if @kids;
    $s;
};
my %texts = (cxn_q_t => 'complex float128:', cxn_qr_t => 'real part:', cxn_qi_t => 'imag part:', cxn_qty_t => 'float128');
my $data = $node->('cxn_q', 'complex float128:', 'cxn_struct', 'cxn_qr', 'cxn_qi')
    . $node->('cxn_qr', 'real part:', 'cxn_qty') . $node->('cxn_qi', 'imag part:', 'cxn_qty') . $node->('cxn_qty', 'float128')
    . join('', map { "  $_:\n    ascii\n      $texts{$_}\n" } sort keys %texts);
once(\$t, "  cxn_struct:\n", "$data  align\n    8\n  cxn_struct:\n", 'cxn_struct');

# ~: x87.pl's two checks that a 32 bytes' complex on x86_64 is the x87's
# now also that it is not this one (s6 its type)
{
    my ($s, $e) = find(\$t, 'unary');
    my $b = substr($t, $s, $e - $s);
    my $old = asm(10, "
    addi -32 s7 t2
    seqz t2 t2
    and t2 t0 t0
");
    my $n = 0;
    $n++ while $b =~ /\Q$old\E/g;
    $n == 2 or die "complexq: unary has $n of x87.pl's checks\n";
    my $new = $old . asm(10, "
    ld TY_base s6 t1
    la cxn_q t2
    sub t2 t1 t1
    seqz t1 t1
    addi -1 t1 t1
    and t1 t0 t0
");
    $b =~ s/\Q$old\E/$new/g;
    substr($t, $s, $e - $s) = $b;
}
save();
