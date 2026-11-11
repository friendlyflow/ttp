# localabel.pl: a "name:" statement whose first child is a leaf that names a
# local is a label, not a declaration of that type: a local hides a struct
# type of its name (language.ff.txt), here too. glibc's __printf_buffer
# (vfprintf-process-arg.c) has a local group and "do_flag_quote: group = 1";
# a program with C's struct group (grp.h: coreutils' id, ls -l, stat) made
# decl take group for that type, a declaration of do_flag_quote ("cannot
# compile: ="). decl asks vfind about such a leaf after open, before
# typerun. Test: clocalabel.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my $head = "      decl:\n        enter8\n        mv\n          a0\n          s4\n        call\n          open\n        mv\n          a0\n          s5\n        mv\n          a1\n          s6\n";
once(\$t, $head, $head . asm(8, "
    lbu NODE_children_len s4 t0
    beqz LV1 t0
    ld NODE_children s4 t0
    ld 0 t0 t1
    lbu NODE_children_len t1 t2
    bnez LV1 t2
    ld NODE_content t1 a0
    lbu NODE_content_len t1 a1
    call vfind
    bnez L1 a0
LV1:
    mv s5 a0
"), 'decl');
save();
