# gitemcall.pl: a global's item that calls a function of the program
# (g: long / : / f / 4) stops naming g and f: a global's item calls no
# function of the program while compiling (language.ff.txt; the user's
# rule: none defined after it, and today's JIT of an item has the code of
# no function of the page). gval took such a call as a path (gpath) and
# stopped with "cannot compile: f". Test: cgitemcall (4 targets, a build
# that must stop).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "\n  al_word:\n    ascii\n      align\n",
    "\n  al_word:\n    ascii\n      align\n  msg_gcall:\n    ascii\n      ttpc: a global's item may not call a function of the program at compile time:\\x20\n  msg_gcalls:\n    ascii\n      \\x20calls\\x20\n", 'al_word');

edit(\$t, 'cc/gval', asm(8, "
L28:
lbu NODE_children_len s5 t0
beqz L12 t0
ld NODE_content s5 a0
lbu NODE_content_len s5 a1
mv s5 a2
call cfind
beqz L12 a0
mv s5 a0
call gpath
addi 8 s4 a1
j L9
") => asm(8, "
L28:
lbu NODE_children_len s5 t0
beqz L12 t0
ld NODE_content s5 a0
lbu NODE_content_len s5 a1
mv s5 a2
call cfind
beqz L12 a0
call kind
li 1 t0
beq rel:GCF t0 a0
mv s5 a0
call gpath
addi 8 s4 a1
j L9
") . asm(8, "
GCF:
la scope_depth t0
ld 0 t0 t1
addi -1 t1 t1
slli 3 t1 t1
la scopes t2
add t1 t2 t2
ld 0 t2 s7
li STDERR a0
la msg_gcall a1
li 78 a2
li SYS_write a7
ecall
li STDERR a0
ld NODE_content s7 a1
lbu NODE_content_len s7 a2
add a2 a1 t0
lbu -1 t0 t0
li 58 t1
bne rel:GC2 t1 t0
addi -1 a2 a2
") . asm(8, "
GC2:
li SYS_write a7
ecall
la msg_gcalls a1
li 7 a2
ld NODE_content s5 a3
lbu NODE_content_len s5 a4
j die_name
"));
save();
