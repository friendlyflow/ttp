# weakobj.pl (fault 28): a weak declaration that is no function (a: /
# weak / array / long, glibc's __rela_iplt_start) is an object: weak / a
# is its address, the definition's or ttpc's placing (irelplace) where
# there is one, else 0, as C's weak extern; as a value an array's decays
# to it, a scalar is read there. primary took every weak declaration for
# a function and called through it (a call through 0), and addr gave a
# weak declaration's address 0 of type long even where it is placed, so
# the value read address 0, also for an array. Now primary calls only
# weak / function / type (or a bare weak), and addr takes the address
# from gaddr (0 for a weak declaration nothing places) with the
# declaration's type (dtype; weak / function and a bare weak TY_FUNC), so
# rvalue decays an array. The program page's loop no longer places its
# weak declarations of data as globals: their address was that storage's
# in leafval (and now addr), 0 in gval. Test: cweakobj (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/primary', asm(10, "
call defkw
li KW_asm t0
beq rel:LWC2 t0 a0
li KW_weak t0
beq rel:LWC2 t0 a0
") => asm(10, "
call defkw
li KW_asm t0
beq rel:LWC2 t0 a0
li KW_weak t0
bne rel:LWCK t0 a0
lbu NODE_children_len s6 t0
li 2 t1
blt rel:LWC2 t1 t0
ld NODE_children s6 t0
ld 8 t0 a0
call kwof
li KW_function t0
beq rel:LWC2 t0 a0
") . asm(8, "
LWCK:
"));

edit(\$t, 'cc/addr', asm(10, "
li KW_weak t0
bne rel:L12 t0 a0
li 0 a0
li R_a0 a1
call li
li TY_LONG a0
call setty
j L9
") => asm(10, "
li KW_weak t0
bne rel:L12 t0 a0
mv s5 a0
call gaddr
lbu NODE_children_len s5 t0
li 2 t1
blt rel:L15 t1 t0
ld NODE_children s5 t0
ld 8 t0 a0
call kwof
li KW_function t0
beq rel:L15 t0 a0
j L14
"));
# (the program page's loop places no weak declaration: it is no
# definition, and its address stays 0 as in addr, leafval and gval)
edit(\$t, 'cc', "    L2:\n" . asm(6, "
mv s4 a0
call secdefer
") => "    L2:\n" . asm(6, "
mv s4 a0
call defkw
li KW_weak t0
beq rel:L8 t0 a0
mv s4 a0
call secdefer
"));
save();
