# limits.pl: ttpc's limits four times larger, for programs ten times
# floats' and more (floats-prog reads 12 MB of glibc in ff): its input
# (BUF_SIZE, all trees together) and output (OUT_SIZE), and the areas that
# grow with the input: nodes, their pointers, syms, labels, the C layer's
# types; the files on the command line (MAX_FILES, roots), the trees
# read (MAX_TREES, trees) and the trees whose pages a program has
# (MAX_PAGES, page_roots: 255, the most a node of pages holds). Run on
# ttpc.ff, then (T=ttpc.defs.ff) on its definitions.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
if ($t =~ /^ttpc:\n/m) {
    for (['BUF_SIZE', 33554432, 134217728], ['OUT_SIZE', 16777216, 67108864], ['MAX_FILES', 16, 64],
         ['MAX_TREES', 32, 128], ['MAX_PAGES', 64, 255]) {
        my ($name, $old, $new) = @$_;
        once(\$t, "  $name:\n    addi\n      $old\n", "  $name:\n    addi\n      $new\n", $name);
    }
} else {
    for (['nodes', 67108864, 268435456], ['ptrs', 8388608, 33554432], ['syms', 8388608, 33554432],
         ['labels', 25165824, 100663296], ['roots', 128, 512], ['cc_types', 33554432, 134217728],
         ['trees', 512, 2048], ['page_roots', 512, 2040]) {
        my ($name, $old, $new) = @$_;
        $t =~ /^( *)\Q$name\E:\n\1  reserve\n\1    \Q$old\E\n/m or die "limits: $name is not $old\n";
        my $i = $1;
        once(\$t, "$i$name:\n$i  reserve\n$i    $old\n", "$i$name:\n$i  reserve\n$i    $new\n", $name);
    }
}
save();
