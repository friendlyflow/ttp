# selfcl.pl: a struct or union that starts from a : holding a compound
# literal of its own type is a copy of it, as language.ff.txt says (a
# declaration with a struct of its type starts as a copy), in a local, a
# local's field and a global. A : was taken for the inner braces of the
# first field, so c: / rel / : / (rel / 5 / 6) gave the items rel 5 6 to
# the fields: the first field got the temporary's address, the rest stayed
# zero, with no message (gnulib parse-datetime.y's relative_time
# rel_time_0 = RELATIVE_TIME_0, the macro a parenthesized compound
# literal). A copy from a variable (b: / rel / a) was right already.
#
# cllit (a0 an item, a1 a type): 1 where the item is a : whose first item
# is a leaf that is a compound literal of a struct of that type itself
# (litk: its places; a local named so is none), 2 of a union, else 0.
# decl: a local's one item that is such a : (clself) is compiled as the
# expression it is and copied, as a struct variable's is. linit: a field
# of a local whose item is such a : is copied from it (as a wide field's
# expression is). global and ginit: a struct global's one item, or a
# struct field's, that is such a : gives the literal's items after its
# type to the struct (clitems), which are those of a global's struct where
# its fields are scalars; a union's literal (it names its field) or a
# struct's with a struct, union or array field (its own type first, an
# anonymous member's fields in place) stops, named, where the global was
# silently wrong. A : whose first item is no compound literal of the type
# stays the inner braces of the first field. Test cselfcl (4 targets).
#
# Run on ttpc.ff, then with T=ttpc.defs.ff (its message's length).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_untyped_len:\n    size\n      msg_untyped\n",
        "  msg_untyped_len:\n    size\n      msg_untyped\n  msg_clglob_len:\n    size\n      msg_clglob\n", 'msg_untyped_len');
    save();
    exit;
}

# decl: a local's one item
edit(\$t, 'cc/decl', asm(10, "
    call peek
    call colonalone
    bnez L14 a0
") => asm(10, "
    call peek
    mv s7 a1
    call clself
    bnez L14 a0
"));

# linit: a field of a struct, union or array type
edit(\$t, 'cc/linit', asm(10, "
    mv s7 a0
    call isagg
    beqz L4 a0
    call peek
    call iscolon
    beqz L3 a0
") => asm(10, "
    mv s7 a0
    call isagg
    beqz L4 a0
    call peek
    mv s7 a1
    call cllit
    bnez W1 a0
    call peek
    call iscolon
    beqz L3 a0
"));

# ginit: a struct field's :
edit(\$t, 'cc/ginit', asm(10, "
    ld 0 s6 a0
    call iscolon
    beqz L3 a0
    ld 0 s6 t0
    ld NODE_children t0 a2
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 a2 a3
") => asm(10, "
    ld 0 s6 a0
    call iscolon
    beqz L3 a0
    ld 0 s6 a0
    mv s9 a1
    call clitems
    mv a0 t5
    ld 0 s6 t0
    ld NODE_children t0 a2
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 a2 a3
    slli 3 t5 t5
    add t5 a2 a2
"));

# global: its one item
edit(\$t, 'cc/global', asm(8, "
L4:
    mv s7 a0
    li 0 a1
    mv s6 a2
    mv s5 a3
    call ginit
") => asm(8, "
L4:
    mv s6 a0
    mv s5 a1
    mv s7 a2
    call clunwrap
    mv a0 s6
    mv a1 s5
    mv s7 a0
    li 0 a1
    mv s6 a2
    mv s5 a3
    call ginit
"));

my ($from, $to) = find(\$t, 'cc/colonalone');
substr($t, $to, 0) = fn('cllit', "
    enter3
    mv a0 s4
    mv a1 s5
    call iscolon
    beqz C9 a0
    li 0 a0
    lbu NODE_children_len s4 t0
    beqz C9 t0
    ld NODE_children s4 s6
    ld 0 s6 a0
    lbu NODE_children_len a0 t0
    bnez C8 t0
    call litk
    li -1 t0
    beq rel:C8 t0 a0
    mv a0 s4
    mv s6 a0
    addi 8 s6 a1
    call typerun
    bne rel:C8 s5 a0
    li 1 a0
    bgez C9 s4
    li 2 a0
    leave3
C8:
    li 0 a0
C9:
    leave3
", 6) . fn('clself', "
    enter2
    mv a0 s4
    mv a1 s5
    call colonalone
    beqz D9 a0
    mv s4 a0
    mv s5 a1
    call cllit
    seqz a0 a0
D9:
    leave2
", 6) . fn('clunwrap', "
    enter3
    mv a0 s4
    mv a1 s5
    sub s4 s5 t0
    li 8 t1
    bne rel:U9 t1 t0
    ld 0 s4 a0
    mv a2 a1
    call clitems
    beqz U9 a0
    ld 0 s4 t0
    ld NODE_children t0 s4
    lbu NODE_children_len t0 t1
    slli 3 t1 t1
    add t1 s4 s5
    addi 8 s4 s4
U9:
    mv s4 a0
    mv s5 a1
    leave3
", 6) . fn('clitems', "
    enter5
    mv a0 s4
    mv a1 s5
    call cllit
    beqz I9 a0
    li 1 t0
    bne rel:I8 t0 a0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call litk
    mv a0 s6
    li 0 s7
I1:
    bgeu rel:I7 s6 s7
    mv s5 a0
    mv s7 a1
    call member
    mv a1 s8
    mv s8 a0
    call isagg
    beqz I2 a0
    li TY_LDOUBLE t0
    beq rel:I2 t0 s8
    li 112 t0
    beq rel:I2 t0 s8
    li TY_DOUBLE t0
    bne rel:I8 t0 s8
I2:
    addi 1 s7 s7
    j I1
I7:
    li 1 a0
    leave5
I8:
    ld NODE_children s4 t0
    ld 0 t0 a0
    la msg_clglob a1
    li msg_clglob_len a2
    j diename
I9:
    leave5
", 6);

my ($mf, $mt) = find(\$t, 'msg_untyped');
substr($t, $mt, 0) = "      msg_clglob:\n        ascii\n          ttpc: a global from a compound literal of its own type takes it only for a struct of scalar fields; write its items instead:\\x20\n";
save();
