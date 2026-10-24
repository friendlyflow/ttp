# setopt.pl: the word set optimise w of a build file: workspace w compiles
# with -O (opt.pl), as set debug w gives it -g (setdebug.pl). A workspace
# has a field more, WS_opt (after WS_debug; WS_size 168). optflag records
# the command line's -O in opt_cli as well; ws_build sets opt_on for each
# workspace to opt_cli or its WS_opt, so a build file run with -O still
# gives it to all of its workspaces, and one without to those that ask.
# Run on ttpc.ff after opt.pl and setdebug.pl, then with T=ttpc.defs.ff
# (KW_setopt 64).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_setdebug:\n    addi\n      63\n      zero\n      a0\n",
        "  KW_setdebug:\n    addi\n      63\n      zero\n      a0\n  KW_setopt:\n    addi\n      64\n      zero\n      a0\n", 'KW_setdebug');
    once(\$t, "  WS_size:\n    addi\n      160\n", "  WS_opt:\n    addi\n      160\n      zero\n      a0\n  WS_size:\n    addi\n      168\n", 'WS_size');
    save();
    exit;
}

# the word, after set debug
once(\$t, "      set debug\\x00\\x00\n", "      set debug\\x00set optimise\\x00\\x00\n", 'cc_kw');
once(\$t, "  ws_table:\n    reserve\n      2560\n", "  ws_table:\n    reserve\n      2688\n", 'ws_table');
once(\$t, "  opt_on:\n    reserve\n      8\n", "  opt_on:\n    reserve\n      8\n  opt_cli:\n    reserve\n      8\n", 'opt_on');

# its call, as set debug's: wsop with ws_opt and one argument
edit(\$t, 'primary',
    "          li\n            KW_setdebug\n            t0\n          beq\n            rel\n              L58\n            t0\n            a0\n",
    "          li\n            KW_setdebug\n            t0\n          beq\n            rel\n              L58\n            t0\n            a0\n" . asm(10, "
    li KW_setopt t0
    beq rel:OP1 t0 a0
"),
    "        L58:\n", asm(8, "
    OP1:
    la ws_opt a1
    li 1 a2
    j L44
") . "        L58:\n");

once(\$t, "      ws_compile:\n", fn('ws_opt', "
    enter1
    call ws_args
    li 1 t0
    sd WS_opt t0 a0
    li 0 a0
    leave1
", 6) . "      ws_compile:\n", 'ws_compile');

# -O on the command line: opt_cli too
edit(\$t, 'optflag', "    la\n      opt_on\n      t0\n    li\n      1\n      t1\n    sd\n      0\n      t1\n      t0\n",
    "    la\n      opt_on\n      t0\n    li\n      1\n      t1\n    sd\n      0\n      t1\n      t0\n" . asm(4, "
    la opt_cli t0
    sd 0 t1 t0
"));

# each workspace: opt_on is opt_cli or its own
edit(\$t, 'ws_build', "      ld\n        WS_out\n        s4\n        a0\n", asm(6, "
    la opt_cli t0
    ld 0 t0 t1
    ld WS_opt s4 t2
    or t2 t1 t1
    la opt_on t0
    sd 0 t1 t0
") . "      ld\n        WS_out\n        s4\n        a0\n");
save();
