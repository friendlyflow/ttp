# wbinpair.pl: a 64-bit integer with a double on arm keeps its high word
# (the master's fault 23b, 2026-11-24). A floating operator whose type is
# kept in memory (arm's double) is wbin's, which converts its operands with
# wcvt; wcvt and wbin's swaps take a pair (arm's i64 and u64: r0:r1, L
# r12:lr) as one word, so y + d, d + y, d += y and y -= d dropped y's high
# word (5 for 2^33 + 5), and u64 above 2^63 -= double was wrong. Now binop,
# before wbin (L32, fwide of the result's type), converts a pair operand to
# that type with fcvt as a cast does (pconvf): the right one in V, the left
# one brought to V with fxswap (cc_swap_p, both words) around it and put
# back; wbin then has nothing of the pair left to convert.
# Test: progs/ccmpdcvt (its i64 and u64 cases above 2^32).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'binop', "        L32:\n          mv\n            s8\n            a0\n          call\n            fwide\n          bnez\n            W6\n            a0\n" =>
    "        L32:\n" . asm(10, "
    mv s8 a0
    call fwide
    beqz LPW9 a0
    mv s6 a0
    call ispair
    beqz LPW1 a0
    mv s6 a0
    mv s8 a1
    call fcvt
    mv s8 s6
") . asm(8, "
LPW1:
    mv s5 a0
    call ispair
    beqz LPW9 a0
    call push
    call fxswap
    mv s5 a0
    mv s8 a1
    call fcvt
    call popt0
    la cc_exts a0
    addi 633 a0 a0
    call seq
    mv s8 s5
LPW9:
    mv s8 a0
    call fwide
    bnez W6 a0
"));
save();
