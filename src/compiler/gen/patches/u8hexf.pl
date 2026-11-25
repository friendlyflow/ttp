# u8hexf.pl: a char, u8 or i8 given a hex floating literal converts it
# (rule A, the user's choice): g: u8 / 0x1.8p+1 stopped "text needs char *
# pointer: 0x1.8p+1", as textof asked istext of a scalar char's leaf, and
# istext takes every leaf that is no number, no name and no register for a
# text; dtype (a global's) asked istext alike. Now textof and dtype first ask hexf: a float or double literal is a value,
# which gval (gcvt.pl) or the cast converts toward zero (3). Text under
# char * pointer is as before (a C string "0x1p+3" stays text). Test:
# progs/ccmpdcvt (gu8, gs8, gc8, lu8).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'cc/textof',
    "        L3:\n          mv\n            s4\n            a0\n          call\n            istext\n" =>
    "        L3:\n" . asm(10, "
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call hexf
    bnez L1 a1
    mv s4 a0
    call istext
"));
edit(\$t, 'cc/dtype',
    "        L20:\n        ld\n          0\n          s6\n          a0\n        call\n          istext\n" =>
    "        L20:\n" . asm(8, "
    ld 0 s6 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call hexf
    bnez L8 a1
    ld 0 s6 a0
    call istext
"));
save();
