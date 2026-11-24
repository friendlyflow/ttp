# gtexts.pl: a global holds up to 65536 texts. gval kept the texts of the
# global being compiled (cast / char / * pointer and a leaf, a leaf alone for
# an address) in gbase's list, 1024 places before the global's bytes (gbase
# + 8448), and stopped at the 1025th, naming it: "cannot compile: -16,
# FP_INT_DOWNWARD, 4", glibc's math tests' tables (fromfp_test_data, 7718
# entries, each with its name). The list is gtexts of its own now, read by
# global (after the global's bytes) and secpool (a section's) as before. The
# master's fault 15, 2026-11-21 (the leaf only started like a number: not
# the cause). Test: progs/cmanytexts.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  weakref:\n", "  gtexts:\n    reserve\n      524288\n  weakref:\n", 'weakref');

edit(\$t, 'cc/gval',
    "          li\n            1024\n            t1\n          bgeu\n            rel\n              L8\n            t1\n            t0\n          slli\n            3\n            t0\n            t1\n          add\n            t1\n            s6\n            t1\n          sd\n            32\n            s5\n            t1\n" =>
    "          li32\n            65536\n            t1\n          bgeu\n            rel\n              L8\n            t1\n            t0\n          slli\n            3\n            t0\n            t1\n          la\n            gtexts\n            t2\n          add\n            t1\n            t2\n            t1\n          sd\n            0\n            s5\n            t1\n");
edit(\$t, 'cc/global',
    "          slli\n            3\n            s10\n            t1\n          add\n            t1\n            s9\n            t1\n          ld\n            32\n            t1\n            t1\n" =>
    "          slli\n            3\n            s10\n            t1\n          la\n            gtexts\n            t2\n          add\n            t1\n            t2\n            t1\n          ld\n            0\n            t1\n            t1\n");
edit(\$t, 'cc/secpool',
    "slli\n            3\n            s6\n            t2\n          add\n            t2\n            s4\n            t2\n          ld\n            32\n            t2\n            t2\n" =>
    "slli\n            3\n            s6\n            t2\n          la\n            gtexts\n            t3\n          add\n            t2\n            t3\n            t2\n          ld\n            0\n            t2\n            t2\n");
save();
