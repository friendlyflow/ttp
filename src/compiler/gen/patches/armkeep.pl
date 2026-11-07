# armkeep.pl (on macros/arm.ff.txt, then make refresh): ttpc's C on arm
# keeps r4..r11 and d8..d15 as the AAPCS has them, callee-saved, so that
# gcc's code which calls ttpc's (qsort's comparator, a signal handler,
# libgcc's unwinder, any callback) finds its values there again.
#
# Before this, X (a scale or count) was r8, the high word of L (a pair) r9,
# and a system call's arguments 4..6 went through r8, r9 and r10, none of
# them saved. Now X and L's high word are lr, which every function's
# prologue (cc_enter) keeps and its epilogue loads into pc, so the body may
# write it: the two are never live at once (no primitive uses both; checked
# on all of glibc's arm code, -O and not). A system call's arguments are
# loaded into s0..s6 (VFP, caller-saved) and moved into r0..r6 after r4..r7
# are pushed. Saving r8 and r9 in each prologue instead would cost two
# words of stack and their stores and loads in every call, a new frame
# layout (cc_argoff 16) and new unwind rules; this costs nothing outside a
# system call, and in one 4 instructions (7 vmovs where 3 movs were).
#
#   make patch P=gen/patches/armkeep.pl T=macros/arm.ff.txt
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

die "armkeep: $tf: not macros/arm.ff.txt\n" unless $tf =~ m{arm\.ff\.txt$};
my $c0 = index($t, "\nc:\n");
my $c1 = index($t, "\nopt:\n");
die "armkeep: no c: section before opt:\n" unless $c0 >= 0 && $c1 > $c0;

# r8 and r9 in the C layer's primitives become lr (cc_syscall is new below)
my $c = substr($t, $c0, $c1 - $c0);
my ($m, $n, $out) = ('', 0, '');
for my $l (split /^/, $c) {
    $m = $1 if $l =~ /^  (\w+):\n/;
    $m = '' if $l =~ /^  comment\n/;
    $n++ if $m ne 'cc_syscall' && $l =~ s/^(\s+)r[89]\n/$1lr\n/;
    $out .= $l;
}
die "armkeep: no r8 or r9 in the C layer: already done?\n" unless $n;
substr($t, $c0, $c1 - $c0) = $out;

once(\$t, "X a scale or count (r8), FP the frame (r11), SP the stack (sp), LR the return address (lr).",
    "X a scale or count (lr), FP the frame (r11), SP the stack (sp), LR the return address (lr).\n"
  . "    The AAPCS's callee-saved registers are kept (gen/patches/armkeep.pl): C writes none of r4..r10 or d8..d15 but in a primitive that pushes and pops them (cc_div_p, cc_syscall, ...), and r11 only as cc_enter and cc_leave do.\n"
  . "    lr is saved by cc_enter and loaded into pc by cc_leave, so the body may write it: X and L's high word are lr, never live at once.",
    'the header');
once(\$t, "  cc_x:\n    addi\n      8\n", "  cc_x:\n    addi\n      14\n", 'cc_x');
once(\$t, "L is r12 with r9; X stays r8.", "L is r12 with lr (X too: the two are never live at once).", 'the pair comment');
once(\$t, "    r9 and r12 are free for this because ttpc links the whole program itself: no veneers (which may use r12) and no platform use of r9.\n",
    "    r12 is free for this because ttpc links the whole program itself: no veneers (which may use r12).\n", 'the pair comment, r9');

once(\$t, "  cc_sysreg:\n    i\n    srli\n      2\n      i\n      a0\n    slli\n      2\n      a0\n      a0\n    add\n      a0\n      i\n      a0\n",
    "  comment\n"
  . "    A system call (svc 0): its number in r7, its arguments in r0..r6. cc_sysreg i: argument i is loaded into s<i> (VFP, which holds nothing between primitives) by cc_sysarg i off, from SP + off.\n"
  . "    cc_syscall: r4..r7 pushed, r0..r6 = s0..s6, r7 = the number (the slot above the pushed ones), svc 0, r4..r7 popped, the number dropped.\n"
  . "    So the callee-saved r4..r7 are kept, and nothing of r8..r10 is written.\n"
  . "  cc_sysreg:\n    i\n    addi\n      0\n      i\n      a0\n", 'cc_sysreg');
once(\$t, "  cc_sysarg:\n    i\n    off\n    ldr\n      off\n      sp\n      cc_sysreg\n        i\n",
    "  cc_sysarg:\n    i\n    off\n    vldr.32\n      off\n      sp\n      cc_sysreg\n        i\n", 'cc_sysarg');
once(\$t, "  cc_syscall:\n    push\n      0xf0\n    mov\n      r8\n      r4\n    mov\n      r9\n      r5\n    mov\n      r10\n      r6\n",
    "  cc_syscall:\n    push\n      0xf0\n" . join('', map { "    vmov.rs\n      s$_\n      r$_\n" } 0 .. 6), 'cc_syscall');
save();
