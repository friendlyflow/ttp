# enumtext.pl: an enum constant of a library page is no text. istext takes a
# leaf after char or u8 for a text unless it is a number, a local, a label
# of the scopes, a register or a library definition: an enum constant of
# another page (enumconst finds those) was none of them, so a char or u8
# initialized with one stopped ttpc ("text needs char * pointer:
# GMON_TAG_TIME_HIST", glibc's gmon write_hist: u_char tag =
# GMON_TAG_TIME_HIST; found by src/glibc's datacheck). Now istext asks
# enumconst too. Test cenumtext (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'istext', asm(8, "
    call find_reg
    addi 1 a0 a0
    bnez L1 a0
") => asm(8, "
    call find_reg
    addi 1 a0 a0
    bnez L1 a0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call enumconst
    bnez L1 a0
"));
save();
