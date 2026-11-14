# gsizeof.pl: a page item whose first item with children, after its type,
# is a sizeof or an alignof stops ttpc. kind takes such an item for a
# function (a global's items with children are only a :, items, a cast's
# type and value, a suffix or what comes before & address), so a global
# written g: / sv / sizeof / slot0 / slot0 (gnulib quotearg.c's
# slotvec0 = { sizeof slot0, slot0 }, glibc nptl's _thread_db_sizeof_*)
# was silently code: its bytes instructions, g / val a call ("unknown
# name: val"), &g the address of that code. As a function's first
# statement a sizeof does nothing; as a global's item it takes a :
# (: / sizeof / slot0). Now cc and the library's items (both through cc)
# stop with the item's name. Test cgsizeof (4 targets).
#
# Run on ttpc.ff, then with T=ttpc.defs.ff (its message's length).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_untyped_len:\n    size\n      msg_untyped\n",
        "  msg_untyped_len:\n    size\n      msg_untyped\n  msg_gsizeof_len:\n    size\n      msg_gsizeof\n", 'msg_untyped_len');
    save();
    exit;
}

# cc: a function (kind 1) is checked before it is placed
edit(\$t, 'cc', asm(6, "
    li 1 t0
    bne rel:L2 t0 a0
    call falign
") => asm(6, "
    li 1 t0
    bne rel:L2 t0 a0
    mv s4 a0
    call fnsizeof
    li 1 a0
    call falign
"));

# fnsizeof (a0 the item, kind 1): the first item with children after the
# type run; a sizeof or alignof there stops
my ($from, $to) = find(\$t, 'cc/kind');
substr($t, $to, 0) = fn('fnsizeof', "
    enter3
    mv a0 s4
    ld NODE_children s4 a0
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 a0 s6
    mv s6 a1
    call tlskip
    call typerun
    bltz F9 a0
    mv a1 s5
F1:
    bgeu rel:F9 s6 s5
    ld 0 s5 a0
    addi 8 s5 s5
    lbu NODE_children_len a0 t0
    beqz F1 t0
    call kwof
    li KW_sizeof t0
    beq rel:F8 t0 a0
    li KW_alignof t0
    bne rel:F9 t0 a0
F8:
    mv s4 a0
    la msg_gsizeof a1
    li msg_gsizeof_len a2
    j diename
F9:
    leave3
", 6);

my ($mf, $mt) = find(\$t, 'msg_untyped');
substr($t, $mt, 0) = "      msg_gsizeof:\n        ascii\n          ttpc: a sizeof or alignof begins this function's body; as a global's item it takes a : around it:\\x20\n";
save();
