# setdebug.pl: the word set debug w of a build file: workspace w compiles
# with -g (debug.pl), as the command line's -g does. A workspace has a
# field more, WS_debug (after its files; WS_size 160). dbgflag records the
# command line's -g in dbg_cli as well; ws_build sets dbg_on for each
# workspace to dbg_cli or its WS_debug, so a build file run with -g still
# gives it to all of its workspaces, and one without to those that ask.
# Run on ttpc.ff after debug.pl, then with T=ttpc.defs.ff (KW_setdebug 63).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_vector:\n    addi\n      62\n      zero\n      a0\n",
        "  KW_vector:\n    addi\n      62\n      zero\n      a0\n  KW_setdebug:\n    addi\n      63\n      zero\n      a0\n", 'KW_vector');
    once(\$t, "  WS_size:\n    addi\n      152\n", "  WS_debug:\n    addi\n      152\n      zero\n      a0\n  WS_size:\n    addi\n      160\n", 'WS_size');
    save();
    exit;
}

# the word, after vector
once(\$t, "fs\\x00vector\\x00\\x00\n", "fs\\x00vector\\x00\n    ascii\n      set debug\\x00\\x00\n", 'cc_kw');
once(\$t, "  ws_table:\n    reserve\n      2432\n", "  ws_table:\n    reserve\n      2560\n", 'ws_table');
once(\$t, "  dbg_on:\n    reserve\n      8\n", "  dbg_on:\n    reserve\n      8\n  dbg_cli:\n    reserve\n      8\n", 'dbg_on');

# its call, as compile's: wsop with ws_debug and one argument
edit(\$t, 'primary',
    "          li\n            KW_compile\n            t0\n          beq\n            rel\n              L43\n            t0\n            a0\n",
    "          li\n            KW_compile\n            t0\n          beq\n            rel\n              L43\n            t0\n            a0\n" . asm(10, "
    li KW_setdebug t0
    beq rel:L58 t0 a0
"),
    "        L43:\n", asm(8, "
    L58:
    la ws_debug a1
    li 1 a2
    j L44
") . "        L43:\n");

once(\$t, "      ws_compile:\n", fn('ws_debug', "
    enter1
    call ws_args
    li 1 t0
    sd WS_debug t0 a0
    li 0 a0
    leave1
", 6) . "      ws_compile:\n", 'ws_compile');

# -g on the command line: dbg_cli too
edit(\$t, 'dbgflag', "    la\n      dbg_on\n      t0\n    li\n      1\n      t1\n    sd\n      0\n      t1\n      t0\n",
    "    la\n      dbg_on\n      t0\n    li\n      1\n      t1\n    sd\n      0\n      t1\n      t0\n" . asm(4, "
    la dbg_cli t0
    sd 0 t1 t0
"));

# each workspace: dbg_on is dbg_cli or its own
edit(\$t, 'ws_build', "      ld\n        WS_out\n        s4\n        a0\n", asm(6, "
    la dbg_cli t0
    ld 0 t0 t1
    ld WS_debug s4 t2
    or t2 t1 t1
    la dbg_on t0
    sd 0 t1 t0
") . "      ld\n        WS_out\n        s4\n        a0\n");
save();
