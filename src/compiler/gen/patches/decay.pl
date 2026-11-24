# decay.pl: a leaf under char / * pointer (or signed char's) in a local's
# item that names a local is that local, not text: textof (decl's item of a
# pointer to char) took any leaf for text, so glibc's __gettextparse (bison:
# yytype_int8 *yyss = yyssa; *yyssp = yyss) had yyss the text "yyssa" in the
# program's text, not the local array, its parser stack in read-only memory
# (x86_64, riscv64, aarch64, arm: the only 3 such items of glibc in ff).
# Now textof, called by decl (tdecl set: a cast's leaf, also textof's, stays
# text, as language.ff.txt says), looks the leaf up as a local first
# (vfind): found, the item is an expression, the local's value (an array's
# address, C's decay). Other leaves stay text (a number, any other name).
# The user's choice (A), fault 13, 2026-11-21. Test: progs/cdecay.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'textof', "        L20:\n        mv\n          s4\n          a0\n        call\n          text\n" =>
    "        L20:\n" . asm(8, "
    la tdecl t0
    ld 0 t0 t0
    beqz L21 t0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call vfind
    bnez L1 a0
") . "        L21:\n        mv\n          s4\n          a0\n        call\n          text\n");
once(\$t, "  weakref:\n", "  tdecl:\n    reserve\n      8\n  weakref:\n", 'weakref');
edit(\$t, 'cc/decl', "        mv\n          s7\n          a0\n        call\n          textof\n        beqz\n          L6\n          a0\n" =>
    asm(8, "
    la tdecl t0
    li 1 t1
    sd 0 t1 t0
") . "        mv\n          s7\n          a0\n        call\n          textof\n" . asm(8, "
    la tdecl t0
    sd 0 zero t0
") . "        beqz\n          L6\n          a0\n");
save();
