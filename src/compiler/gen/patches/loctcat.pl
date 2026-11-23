# loctcat.pl: text leaves in a row are one text in a local's char array too,
# as C's "ab" "cd" and a text over 255 bytes (several leaves of at most 255
# bytes); found with fault 17's test, 2026-11-23. A global's gtext went on
# through every following item that istext takes (text_item set); a local's
# linit wrote each text leaf with its own NUL at LTZ and the next leaf from
# the element after it, so char l[5] = "ab" "cd" was a b 0 c d. Now LTZ
# first looks at the next item: a leaf that istext takes (text_item set, as
# gtext) goes on at LTX as the same text; otherwise the NUL as before (LTN).
# Test: progs/ccharsole.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/linit', "        LTZ:\n" => "        LTZ:\n" . asm(10, "
    call more
    beqz LTN a0
    call peek
    lbu NODE_children_len a0 t0
    bnez LTN t0
    mv a0 s9
    la text_item t0
    li 1 t1
    sd 0 t1 t0
    mv s9 a0
    call istext
    la text_item t0
    sd 0 zero t0
    bnez LTX a0
") . "        LTN:\n");
save();
