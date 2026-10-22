# complexty.pl: C's complex types built into ttpc, as long double is (the
# user's choice, 2026-10-19): the type words complex float, complex double
# and complex long double (cc_tynames 18, 19, 20) are struct types whose
# definition is ttpc's own, nodes in its data (cxn_*: a struct of the fields
# real part and imag part, of the part's type), which struct makes the
# type record of; nothing of it is on the shared page, which declares the
# words only. So copies, arguments and results are a struct's, and real /
# z and imag / z (complex.pl) find the parts as fields. No new type code:
# the types are records. After complex.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "long double\\x00\\x00\n", "long double\\x00complex float\\x00complex double\\x00complex long double\\x00\\x00\n", 'cc_tynames');

edit(\$t, 'tyname',
    "        call\n          lookup\n        bltz\n          L1\n          a0\n",
    "        call\n          lookup\n        bltz\n          L1\n          a0\n" . asm(8, "
    li 18 t0
    bge rel:LCX t0 a0
"));
{
    my ($from, $to) = find(\$t, 'tyname');
    substr($t, $to, 0) = asm(8, "
LCX:
    addi -18 a0 a0
    slli 3 a0 a0
    la cx_nodes t0
    add t0 a0 a0
    ld 0 a0 a0
    call struct
    leave1
");
}

# the nodes, as ttpc's reader lays a node out (NODE_size 64: the hash, the
# count of children, their array, the content's length, the content)
my $node = sub {
    my ($label, $text, @kids) = @_;
    my $s = "  $label:\n    reserve\n      32\n    dword\n      " . scalar(@kids) . "\n    dword\n      " . (@kids ? "${label}_k" : 0)
        . "\n    dword\n      " . length($text) . "\n    dword\n      ${label}_t\n";
    $s .= "  ${label}_k:\n" . join('', map { "    dword\n      $_\n" } @kids) if @kids;
    $s;
};
my $data = "  align\n    8\n  cx_nodes:\n    dword\n      cxn_f\n    dword\n      cxn_d\n    dword\n      cxn_l\n";
my %texts;
for (['f', 'float'], ['d', 'double'], ['l', 'long double']) {
    my ($k, $ty) = @$_;
    $data .= $node->("cxn_$k", "complex $ty:", 'cxn_struct', "cxn_${k}r", "cxn_${k}i");
    $data .= $node->("cxn_${k}r", 'real part:', "cxn_${k}ty");
    $data .= $node->("cxn_${k}i", 'imag part:', "cxn_${k}ty");
    $data .= $node->("cxn_${k}ty", $ty);
    $texts{"cxn_${k}_t"} = "complex $ty:";
    $texts{"cxn_${k}r_t"} = 'real part:';
    $texts{"cxn_${k}i_t"} = 'imag part:';
    $texts{"cxn_${k}ty_t"} = $ty;
}
$data .= $node->('cxn_struct', 'struct');
$texts{cxn_struct_t} = 'struct';
$data .= join '', map { "  $_:\n    ascii\n      $texts{$_}\n" } sort keys %texts;
$data .= "  align\n    8\n";
once(\$t, "\n  cc_cxnames:\n", "\n$data  cc_cxnames:\n", 'cc_cxnames');
save();
