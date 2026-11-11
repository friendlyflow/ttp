# gfold.pl: a global's item that gval cannot work out stops ttpc, with the
# node it names, where it was a silent wrong word: gval's last way for a
# : of an expression (L12) runs it at compile time (ctrun), right for
# numbers, but for an address (a text after cast / char / * pointer, a
# global's or a function's name) it took the compiler's own address of
# the node: glibc nss_module.c's
# __nss_shlib_revision, LIBNSS_FILES_SO + (: sizeof / array / char / 16),
# was 0x1b3d276f, and getgrgid's module_load (nsswitch.conf's group: files
# [success=merge] systemd) died in asprintf. gaddrin finds such a node in a
# : (its value the node to name, 0 if none). And the address + offset of
# gval (: / an address / + or - / n, the address a name or cast / type and
# a value), whose n had to be a number, takes a : of a number too (ctrun,
# as L12; LGO, LGO4), so __nss_shlib_revision is the
# text's address + 16 (then L22, as for a number). msg_gfold in
# ttpc.defs.ff (msg_gfold_len): run on
# ttpc.ff after localabel.pl, then with T=ttpc.defs.ff. Test: cgfold
# (cgfoldfail stops).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_items_len:\n    size\n      msg_items\n",
        "  msg_items_len:\n    size\n      msg_items\n  msg_gfold_len:\n    size\n      msg_gfold\n", 'msg_items_len');
    save();
    exit;
}

once(\$t, "      msg_items:\n        ascii\n          ttpc: several items need array:\\x20\n",
    "      msg_items:\n        ascii\n          ttpc: several items need array:\\x20\n"
    . "      msg_gfold:\n        ascii\n          ttpc: a global's item holds an address ttpc cannot work out in an expression:\\x20\n", 'msg_items');

# gaddrin: a0 a node; a0 the node in it that names an address or a value
# of the program (a global's or a function's name, not a type's, an enum
# constant's or a field's after .; the value after a cast to a pointer
# that is no number: a text), not looking into sizeof, alignof or a cast's
# type, or 0. A cast of a number to a pointer, as offsetof's (cast / T /
# * pointer, 0) . field, is a number ctrun works out.
once(\$t, "\n      gval:\n", "\n" . fn('gaddrin', "
    enter5
    mv a0 s4
    call kwof
    li KW_sizeof t0
    beq rel:GA0 t0 a0
    li KW_alignof t0
    beq rel:GA0 t0 a0
    li 0 s5
GA2:
    lbu NODE_children_len s4 t0
    bge rel:GA0 t0 s5
    ld NODE_children s4 t0
    slli 3 s5 t1
    add t1 t0 t0
    ld 0 t0 s6
    mv s6 a0
    call kwof
    mv a0 s7
    li KW_sizeof t0
    beq rel:GAN t0 s7
    li KW_alignof t0
    beq rel:GAN t0 s7
    li KW_cast t0
    beq rel:GAC t0 s7
    bgez GAR s7
    lbu NODE_content_len s6 a1
    beqz GAR a1
    ld NODE_content s6 a0
    call parse_num
    bnez GAN a1
    ld NODE_content s6 a0
    lbu NODE_content_len s6 a1
    call enumconst
    bnez GAN a0
    beqz GAF s5
    ld NODE_children s4 t0
    slli 3 s5 t1
    add t1 t0 t0
    ld -8 t0 t1
    lbu NODE_content_len t1 t2
    li 1 t3
    bne rel:GAF t3 t2
    ld NODE_content t1 t2
    lbu 0 t2 t2
    li 46 t3
    beq rel:GAN t3 t2
GAF:
    ld NODE_content s6 a0
    lbu NODE_content_len s6 a1
    mv s6 a2
    call cfind
    beqz GAR a0
    call defkw
    li KW_struct t0
    beq rel:GAR t0 a0
    li KW_union t0
    beq rel:GAR t0 a0
    li KW_enum t0
    beq rel:GAR t0 a0
    mv s6 a0
    j GA9
GAR:
    mv s6 a0
    call gaddrin
    bnez GA9 a0
GAN:
    addi 1 s5 s5
    j GA2
GAC:
    li 0 s8
GC1:
    lbu NODE_children_len s6 t0
    bge rel:GAN t0 s8
    ld NODE_children s6 t0
    slli 3 s8 t1
    add t1 t0 t0
    ld 0 t0 a0
    call kwof
    li KW_content t0
    beq rel:GC2 t0 a0
    addi 1 s8 s8
    j GC1
GC2:
    lbu NODE_children_len s4 t0
    addi 1 s5 t1
    bge rel:GAN t0 t1
    ld NODE_children s4 t0
    slli 3 t1 t1
    add t1 t0 t0
    ld 0 t0 s7
    lbu NODE_children_len s7 t0
    bnez GAN t0
    ld NODE_content s7 a0
    lbu NODE_content_len s7 a1
    call parse_num
    bnez GAN a1
    mv s7 a0
    j GA9
GA0:
    li 0 a0
GA9:
    leave5
", 6) . "      gval:\n", 'gval');

my $third = "          ld\n            NODE_children\n            s5\n            t2\n          ld\n            16\n            t2\n            t3\n          lbu\n            NODE_children_len\n            t3\n            t0\n          bnez\n            L12\n            t0\n";
my $num = "          call\n            parse_num\n          beqz\n            L12\n            a1\n          mv\n            a0\n            s6\n";
my $load = "          ld\n            NODE_content\n            t3\n            a0\n          lbu\n            NODE_content_len\n            t3\n            a1\n";
edit(\$t, 'gval',
    $third . $load . $num, ($third =~ s/            L12\n            t0\n$/            LGO\n            t0\n/r) . $load . $num,
    "          ld\n            24\n            t2\n            t3\n          lbu\n            NODE_children_len\n            t3\n            t0\n          bnez\n            L12\n            t0\n",
    "          ld\n            24\n            t2\n            t3\n          lbu\n            NODE_children_len\n            t3\n            t0\n          bnez\n            LGO4\n            t0\n",
    "        L12:\n", "        L12:\n" . asm(10, "
    mv s5 a0
    call gaddrin
    bnez LGB a0
"),
    "        L21:\n", asm(8, "
LGO:
    ld NODE_children s5 t2
    ld 16 t2 a0
    call gaddrin
    bnez LGB a0
    ld NODE_children s5 t2
    ld 16 t2 a0
    la ctconst a1
    call ctrun
    mv a0 s6
    ld NODE_children s5 t2
    ld 8 t2 a0
    call opof
    li OP_add t0
    beq rel:L22 t0 a0
    li OP_sub t0
    bne rel:L12 t0 a0
    neg s6 s6
    j L22
LGO4:
    ld NODE_children s5 t2
    ld 24 t2 a0
    call gaddrin
    bnez LGB a0
    ld NODE_children s5 t2
    ld 24 t2 a0
    la ctconst a1
    call ctrun
    mv a0 s6
    ld NODE_children s5 t2
    ld 16 t2 a0
    call opof
    li OP_add t0
    beq rel:L22 t0 a0
    li OP_sub t0
    bne rel:L12 t0 a0
    neg s6 s6
    j L22
LGB:
    la msg_gfold a1
    li msg_gfold_len a2
    j diename
") . "        L21:\n");
save();
