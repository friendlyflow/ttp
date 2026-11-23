# bufsize.pl: ttpc's input buffer (buf, BUF_SIZE) holds 256 MB of trees,
# not 128 MB. Every tree ttpc reads, an include's pages too, goes in it, and
# past its end ttpc stops with "file too large". coreutils in ff on x86_64
# reads shared.ff (3.7 MB), x86_64gnu.ff (30.5 MB since libmvec's asm,
# 2026-11-16), coreutils.ff (34.2 MB) and include glibc (47 pages, 79.3 MB,
# its asm page 20.5 MB with libmvec's): 147.7 MB. buf is bss (reserve), so
# the cost is 128 MB more of ttpc's address space, which pages it touches
# alone. Run with T=ttpc.defs.ff. No test of its own: one needs a tree over
# 128 MB; ports-coreutils on x86_64 is the one that reads more.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  BUF_SIZE:\n    addi\n      134217728\n", "  BUF_SIZE:\n    addi\n      268435456\n", 'BUF_SIZE');
save();
