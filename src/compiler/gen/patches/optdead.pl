# optdead.pl: -O's fourth rewrite (lane S3), after opt.pl: dead code, and
# a jump to the label right after it.
#
#   After a cc_jmp the primitives are dropped until the next label, since
#   nothing reaches them (opt_dead), but cc_falign (the alignment before a
#   function, which a label follows). optflush clears it, so a label (any:
#   the C layer's, a macro's, the assembler's place, a function's) ends it,
#   and so does anything else that emits or reads cur_pc (emit_raw, skip,
#   code_call, ctrun, jit, generic).
#   The cc_jmp itself is held (opt_jheld, its label opt_jlab: jump records
#   the label's number in opt_jid, since the primitive has its address,
#   which pass 1 may not know): the C layer's label of that number next
#   drops it; anything else emits it first (the next primitive that is not
#   dropped, optflush).
#
# cc_leave is not one: it is a function's last primitive, after the label
# its returns jump to, and what follows it is outside the functions
# (cc_falign, the TLS image's primitives, data), live. place (the
# assembler's labels) now flushes as label does: code and data are one
# stream, so what is held goes before the label. generic and each pass
# start with neither. The decisions depend only on the primitives' names
# and the labels' numbers, so pass 1 and pass 2 make the same. Not inside
# compile time (CC_jit).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  optb_buf:\n    reserve\n      480\n", "  optb_buf:\n    reserve\n      480\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
    [opt_dead => 8], [opt_jheld => 8], [opt_jid => 8], [opt_jlab => 8], [opt_jbuf => 48]), 'optb_buf');
once(\$t, "  cc_loads:\n", "  opt_jmp:\n    ascii\n      cc_jmp\\x00\n  opt_falign:\n    ascii\n      cc_falign\\x00\n  cc_loads:\n", 'cc_loads');

my $hook = "
    addi -16 sp sp
    sd 0 ra sp
    call optflush
    ld 0 sp ra
    addi 16 sp sp
";
# a label of the assembler (a function's, place) flushes, as the C layer's
once(\$t, "  place:\n", "  place:\n" . asm(4, $hook), 'place');
# jump: the label's number
once(\$t, "      jump:\n        la\n          cc_j\n          t0\n", "      jump:\n" . asm(8, "
    la opt_jid t1
    sd 0 a0 t1
") . "        la\n          cc_j\n          t0\n", 'jump');
# label: a held cc_jmp to it is dropped
edit(\$t, 'label', "        call\n          optflush\n", "        call\n          optjl\n        call\n          optflush\n");

# optflush ends the dead code (t0 only, as optflush keeps every other register)
edit(\$t, 'optflush', "    la\n      opt_held\n      t0\n    ld\n", asm(4, "
    la opt_dead t0
    sd 0 zero t0
    la opt_held t0
") . "    ld\n");
once(\$t, "  optflush:\n", fn('optjl', "
    la opt_jheld t0
    ld 0 t0 t0
    beqz J9 t0
    la opt_jlab t0
    ld 0 t0 t0
    bne rel:J9 t0 a0
    la opt_jheld t0
    sd 0 zero t0
    J9:
    ret
") . "  optflush:\n", 'optflush');
$t =~ s/^(  optjl:\n)/$1    comment\n      a0 a label's number: a cc_jmp to it that opt holds is dropped (optdead.pl); every register kept but t0\n/m or die;

# generic's compile and each pass: none
my $n = ($t =~ s/^( +)(la\n\1  opt_n\n\1  t0\n\1sd\n\1  0\n\1  zero\n\1  t0\n)(\1la\n\1  optb_n\n\1  t0\n\1sd\n\1  0\n\1  zero\n\1  t0\n)/$1$2$3$1la\n$1  opt_dead\n$1  t0\n$1sd\n$1  0\n$1  zero\n$1  t0\n$1la\n$1  opt_jheld\n$1  t0\n$1sd\n$1  0\n$1  zero\n$1  t0\n/mg);
$n == 2 or die "optdead: the resets: $n\n";

# opt: drops a primitive while dead, but cc_falign; emits a held cc_jmp
# before any other; holds a cc_jmp, after what A and B hold
edit(\$t, 'opt', "        M1:\n          la\n            opt_a\n            t0\n          ld\n            0\n            t0\n            t0\n          bnez\n            H0\n            t0\n", asm(8, "
    M1:
    la opt_dead t0
    ld 0 t0 t0
    beqz M2 t0
    la opt_falign a2
    call cstreq
    bnez M2 a0
    leave8
    M2:
    call EJ
    mv s4 a0
    la opt_jmp a2
    call cstreq
    beqz M3 a0
    la opt_jbuf t0
    sd 0 s4 t0
    sd 8 s5 t0
    sd 16 s6 t0
    sd 24 s7 t0
    sd 32 s8 t0
    sd 40 s9 t0
    call FA
    call FB
    la opt_jid t0
    ld 0 t0 t1
    la opt_jlab t0
    sd 0 t1 t0
    li 1 t1
    la opt_jheld t0
    sd 0 t1 t0
    la opt_held t0
    sd 0 t1 t0
    la opt_dead t0
    sd 0 t1 t0
    leave8
    EJ:
    la opt_jheld t0
    ld 0 t0 t1
    bnez EJ1 t1
    ret
    EJ1:
    sd 0 zero t0
    addi -16 sp sp
    sd 0 ra sp
    la opt_jbuf t0
    ld 0 t0 a0
    ld 8 t0 a1
    ld 16 t0 a2
    ld 24 t0 a3
    ld 32 t0 a4
    ld 40 t0 a5
    call prim0
    ld 0 sp ra
    addi 16 sp sp
    ret
    M3:
    mv s4 a0
    mv s5 a1
    mv s6 a2
    mv s7 a3
    mv s8 a4
    mv s9 a5
    la opt_a t0
    ld 0 t0 t0
    bnez H0 t0
"));
# F0 (optflush's) emits a held cc_jmp after A and B
edit(\$t, 'opt', "          call\n            FB\n          la\n            opt_held\n", "          call\n            FB\n          call\n            EJ\n          la\n            opt_held\n");
save();
