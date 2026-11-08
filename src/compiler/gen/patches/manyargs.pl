# manyargs.pl: a C call of 64 arguments, as args, argpush and the callee's plan
# (abi_pplan) have room for. Each ABI's call (abicall rvcall a64call x64call)
# kept a place per argument in its frame and stopped past 48 with an empty
# "cannot compile:": tst-vfprintf-user-type's asprintf of 60. The frame's
# scalars come first now, from sp + 32, where an offset fits an instruction, and
# the 64 places after them, from sp + 112; 2160 bytes, in two steps for the same
# reason. Test: cmanyargs (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

for my $f (qw(abicall rvcall a64call x64call)) {
    my ($s, $e) = find(\$t, $f);
    my $b = substr($t, $s, $e - $s);
    # (the scalars at 1568 ... 1632)
    my $n = $b =~ s/^(\s+(?:sd|ld)\n\s+)(1[56]\d\d)(\n\s+\S+\n\s+sp\n|\n\s+sp\n\s+\S+\n)/$1 . ($2 - 1536) . $3/gme;
    $n or die "manyargs: $f has no scalars\n";
    # (the places, of an index times 32 added to sp in t1)
    my $m = $b =~ s/^(\s+sd\n\s+)(32|40|48|56)(\n\s+\S+\n\s+t1\n)/$1 . ($2 + 80) . $3/gme;
    $m += $b =~ s/^(\s+ld\n\s+)(32|40|48|56)(\n\s+t1\n\s+\S+\n)/$1 . ($2 + 80) . $3/gme;
    $m >= 8 or die "manyargs: $f has $m places\n";
    # (the frame)
    my $in = ($b =~ /^(\s+)addi\n\s+-16\d\d\n\s+sp\n\s+sp\n/m)[0] // die "manyargs: $f has no frame\n";
    my $a = ($b =~ s/^\s+addi\n\s+-16\d\d\n\s+sp\n\s+sp\n/asm(length $in, "addi -2000 sp sp\naddi -160 sp sp\n")/me);
    my ($in2) = $b =~ /^(\s+)addi\n\s+16\d\d\n\s+sp\n\s+sp\n/m or die "manyargs: $f has no frame's end\n";
    $b =~ s/^\s+addi\n\s+16\d\d\n\s+sp\n\s+sp\n/asm(length $in2, "addi 2000 sp sp\naddi 160 sp sp\n")/me or die;
    # (the limit)
    $b =~ s/^(\s+li\n\s+)48(\n\s+t0\n\s+blt\n\s+rel\n\s+L\d+\n\s+t0\n\s+s8\n)/${1}65$2/m or die "manyargs: $f has no limit\n";
    substr($t, $s, $e - $s) = $b;
}
save();
