# setjobs.pl: the word set jobs w n of a build file: workspace w compiles
# with -j n (par.pl), as set optimise w gives it -O (setopt.pl). A
# workspace has a field more, WS_jobs (after WS_opt; WS_size 176): n + 1,
# 0 none. jflag records the command line's -j n in par_cli (n + 1); ws_build
# gives each workspace par_cli's, else its WS_jobs (parset), so a build file
# run with -j n gives it to all of its workspaces, and one without to those
# that ask. Run on ttpc.ff after par.pl and setopt.pl, then with
# T=ttpc.defs.ff (KW_setjobs 65).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_setopt:\n    addi\n      64\n      zero\n      a0\n",
        "  KW_setopt:\n    addi\n      64\n      zero\n      a0\n  KW_setjobs:\n    addi\n      65\n      zero\n      a0\n", 'KW_setopt');
    once(\$t, "  WS_size:\n    addi\n      168\n", "  WS_jobs:\n    addi\n      168\n      zero\n      a0\n  WS_size:\n    addi\n      176\n", 'WS_size');
    save();
    exit;
}

# the word, after set optimise
once(\$t, "      set debug\\x00set optimise\\x00\\x00\n", "      set debug\\x00set optimise\\x00set jobs\\x00\\x00\n", 'cc_kw');
once(\$t, "  ws_table:\n    reserve\n      2688\n", "  ws_table:\n    reserve\n      2816\n", 'ws_table');

# its call: wsop with ws_jobs and two arguments
edit(\$t, 'primary',
    "          li\n            KW_setopt\n            t0\n          beq\n            rel\n              OP1\n            t0\n            a0\n",
    "          li\n            KW_setopt\n            t0\n          beq\n            rel\n              OP1\n            t0\n            a0\n" . asm(10, "
    li KW_setjobs t0
    beq rel:OP2 t0 a0
"),
    "        OP1:\n", asm(8, "
    OP2:
    la ws_jobs a1
    li 2 a2
    j L44
") . "        OP1:\n");

once(\$t, "      ws_compile:\n", fn('ws_jobs', "
    enter1
    call ws_args
    addi 1 a1 a1
    sd WS_jobs a1 a0
    li 0 a0
    leave1
", 6) . "      ws_compile:\n", 'ws_compile');

# each workspace: -j as par_cli, else its own
edit(\$t, "ws_build", "      ld\n        WS_out\n        s4\n        a0\n", "      call\n        parws\n      ld\n        WS_out\n        s4\n        a0\n");
once(\$t, "  parset:\n", "  parws:\n    comment\n      ws_build, the workspace s4: par_n and par_chk as the command line's -j (par_cli), else its set jobs, else none\n" . asm(4, "
    la par_cli t0
    ld 0 t0 t6
    bnez WJ1 t6
    ld WS_jobs s4 t6
    WJ1:
    la par_n t0
    sd 0 zero t0
    la par_chk t0
    sd 0 zero t0
    beqz WJ2 t6
    addi -1 t6 t6
    j parset
    WJ2:
    ret
") . "  parset:\n", "parset");
save();
