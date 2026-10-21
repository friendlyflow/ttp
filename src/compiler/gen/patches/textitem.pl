# textitem.pl: a leaf that is the item of an array of bytes in a global's
# initializer is its text even where a library defines that name: glibc's
# _nl_C_name is "C", and libm's long double table C made it the address of
# that table, compiled as asm ("unknown function: 0x1.62e4...L"). istext
# skips its find_fn (a library's definition) while ginit and gtext ask it
# about such an item (text_item); a name of the program, a local, a label or a
# register is still no text. Test: ctextitem. Run on ttpc.ff after
# ldneg.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  tscan_quiet:\n    reserve\n      8\n",
    "  tscan_quiet:\n    reserve\n      8\n  text_item:\n    reserve\n      8\n", 'tscan_quiet');

my $ask = "          ld\n            0\n            s6\n            a0\n          call\n            istext\n";
$t =~ s/\Q$ask\E/asm(10, "
    la text_item t0
    li 1 t1
    sd 0 t1 t0
") . $ask . asm(10, "
    la text_item t0
    sd 0 zero t0
")/ge == 3 or die "textitem: ginit and gtext ask istext 3 times\n";

my $fn = "        ld\n          NODE_content\n          s4\n          a0\n        lbu\n          NODE_content_len\n          s4\n          a1\n        call\n          find_fn\n";
edit(\$t, 'istext', $fn, asm(8, "
    la text_item t0
    ld 0 t0 t0
    bnez L1 t0
") . $fn);
save();
