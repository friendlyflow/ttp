# textname.pl: a leaf that is the item of an array of bytes in a global's
# initializer (a global, a struct's field, an array's element, a static
# local) is its text whatever it names: a number is a number, any other
# leaf text, though a function, a global, a local, a label or a register
# has that name (grep's matchers[] = {{ "grep", ... }} beside its function
# grep took the function's address; glibc's nss_function_name_array
# "getpwnam_r", nss_database_name_array "passwd", ...). csema writes an
# enum constant there as its number. istext, asked by ginit and gtext about
# such an item (text_item, textitem.pl), stops after parse_num. Test:
# ctextname. Run on ttpc.ff after textitem.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $num = "        call\n          parse_num\n        mv\n          a1\n          a0\n        bnez\n          L1\n          a0\n";
edit(\$t, 'istext', $num, $num . asm(8, "
    la text_item t0
    ld 0 t0 t0
    bnez L1 t0
"));
save();
