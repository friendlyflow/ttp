# secpad.pl: a section's globals follow each other at their own type's
# alignment, as ld lays out a section, not each at 8 bytes as ttpc's other
# globals end: on arm csection's struct of three words is 12 bytes, and
# __stop_impls - __start_impls was 4 for 3 (global's L7 and cc's padding
# after placing a global skip it while secplace places, sec_placing; secplace
# pads to 8 after the section's texts). Run on ttpc.ff after secpass.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/global', "        L7:\n          la\n            cur_pc\n            t0\n", asm(8, "
    L7:
    la sec_placing t1
    ld 0 t1 t1
    bnez L9 t1
    la cur_pc t0
"));

my $placed = "      la\n        global\n        a1\n      call\n        place\n";
edit(\$t, 'cc', $placed, $placed . asm(6, "
    la sec_placing t0
    ld 0 t0 t0
    bnez L8 t0
"));
save();
