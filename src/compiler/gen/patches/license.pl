# license.pl: a license, the user's word (2026-10-19), is a comment to
# ttpc: `license` / SPDX expression / the notice, a line per child, which
# ttpc never evaluates, anywhere a comment may stand. So is_comment takes
# license too ("license" has comment's 7 bytes), code_call and exec_call
# ask is_comment instead of matching comment's name themselves, and in C
# kwof gives license the word of comment, KW_comment.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
edit(\$t, 'is_comment',
    "    la\n      str_comment\n      a1\n    li\n      7\n      a2\n    j\n      is_named\n",
    asm(4, "
    addi -16 sp sp
    sd 0 ra sp
    sd 8 a0 sp
    la str_comment a1
    li 7 a2
    call is_named
    bnez L1 a0
    ld 8 sp a0
    la str_license a1
    li 7 a2
    call is_named
    L1:
    ld 0 sp ra
    addi 16 sp sp
    ret
"));
for my $f (qw(code_call exec_call)) {
    edit(\$t, $f,
        "    la\n      str_comment\n      a1\n    li\n      7\n      a2\n    call\n      is_named\n",
        "    call\n      is_comment\n");
}
edit(\$t, 'cc/kwof',
    "        la\n          cc_kw\n          a1\n        j\n          lookup\n",
    asm(8, "
    addi -16 sp sp
    sd 0 ra sp
    sd 8 a0 sp
    la str_license a1
    li 7 a2
    call is_named
    mv a0 t0
    ld 8 sp a0
    ld 0 sp ra
    addi 16 sp sp
    bnez L1 t0
    la cc_kw a1
    j lookup
    L1:
    li KW_comment a0
    ret
"));
once(\$t, "  str_comment:\n    ascii\n      comment\n",
    "  str_comment:\n    ascii\n      comment\n  str_license:\n    ascii\n      license\n", 'str_license');
save();
