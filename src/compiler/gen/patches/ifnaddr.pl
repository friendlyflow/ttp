# ifnaddr.pl: the address of an ifunc (or of an alias of one) is the
# function its resolver chose, as C's &f is after glibc's apply_irel.
#
# In a function it is the value of the ifunc's slot. tst-cmp's table of
# functions, { "strcmp", strcmp }, where strcmp is an alias of the ifunc
# __libc_strcmp, stopped at "needs a type" (addr took the ifunc for a
# global and asked dtype its type). Its type is an address of the ifunc's
# result type, as a call of the ifunc has it (its type words after ifunc
# and the resolver).
#
# In a global's value (test-string.h's IMPL (memmove, 1)) the slot has no
# value yet when the program is made, and gval gave the slot's own address.
# Now the word is an IRELATIVE entry of its own, as ld makes one for it in
# a static program: the address of the word, R_*_IRELATIVE, the ifunc's
# resolver, after the entries of the slots (irelbody), so that glibc's
# apply_irel writes the resolver's choice there. gval says which ifunc
# (irw_pend), gstore adds the word (irw_vars: a count, then an address and
# the ifunc per entry), each pass anew (compile_page). Where nothing places
# the table (ttpc's own init routine, a program without glibc) such a word
# stops, named, at the end of the library (irelplace).
#
# Run on ttpc.ff, then with T=ttpc.defs.ff (its message's length).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_untyped_len:\n    size\n      msg_untyped\n",
        "  msg_untyped_len:\n    size\n      msg_untyped\n  msg_ifgaddr_len:\n    size\n      msg_ifgaddr\n", 'msg_untyped_len');
    save();
    exit;
}

# addr: an ifunc is its slot's value, before AL takes it for an asm word or
# a global
edit(\$t, 'cc/addr',
    "        L12:\n          mv\n            s5\n            a0\n          call\n            AL\n",
    asm(8, "
    L12:
    mv s5 a0
    call defkw
    li KW_ifunc t0
    bne rel:IF9 t0 a0
    mv s5 a0
    call gaddr
    li TY_LONG a0
    call load
    ld NODE_children s5 a0
    lbu NODE_children_len s5 t0
    slli 3 t0 t0
    add t0 a0 a1
    addi 16 a0 a0
    call typerun
    bgez IF8 a0
    li TY_LONG a0
    IF8:
    call setty
    j L9
    IF9:
    mv s5 a0
    call AL
"));

# gval: address name (L11) and a name where an address goes (L4), of an
# ifunc: irw_pend is the ifunc (its value stays the slot's address, which
# the entry replaces when the program starts)
my $ifpend = sub {
    my ($n) = @_;
    asm(10, "
    mv s6 a0
    call defkw
    li KW_ifunc t0
    bne rel:IG$n t0 a0
    la irw_pend t0
    sd 0 s6 t0
    IG$n:
") . "          mv\n            s6\n            a0\n";
};
# (L11 has the definition in a0, L4 in s6 already)
my $tail = "          call\n            defkw\n          li\n            KW_weak\n            t0\n          beq\n            rel\n              L41\n            t0\n            a0\n";
my $w11 = "          mv\n            a0\n            s6\n" . $tail;
my $w4 = "          mv\n            s6\n            a0\n" . $tail;
my ($from, $to) = find(\$t, 'cc/gval');
my $g = substr($t, $from, $to - $from);
once(\$g, $w11, "          mv\n            a0\n            s6\n" . $ifpend->(1) . $w11, 'gval L11');
once(\$g, $w4, $ifpend->(2) . $w4, 'gval L4');
substr($t, $from, $to - $from) = $g;

# gstore: the word at the global's address (gbase's first word) + its
# offset (s5), of the ifunc gval named, an entry
my $gv = "        call\n          gval\n        mv\n          a0\n          s6\n        mv\n          a1\n          s7\n";
edit(\$t, 'cc/gstore', $gv, $gv . asm(8, "
    la irw_pend t0
    ld 0 t0 t1
    beqz IW9 t1
    sd 0 zero t0
    la irw_vars t2
    ld 0 t2 t3
    li32 4096 t4
    bgeu rel:IW8 t4 t3
    slli 4 t3 t4
    add t4 t2 t4
    sd 16 t1 t4
    addi 1 t3 t3
    sd 0 t3 t2
    mv t4 s8
    call gbase
    ld 0 a0 t0
    add s5 t0 t0
    sd 8 t0 s8
    j IW9
    IW8:
    mv t1 a0
    call bad
    IW9:
"));

# compile_page: each pass, no entries yet
my $pass = "      la\n        pass\n        t0\n      sd\n        0\n        s8\n        t0\n";
edit(\$t, 'compile_page', $pass, $pass . "      la\n        irw_vars\n        t0\n      sd\n        0\n        zero\n        t0\n");

# irelbody: after the slots' entries, the words' (then none are left)
edit(\$t, 'cc/irelbody',
    "        E9:\n          leave5\n",
    asm(8, "
    E9:
    la irw_vars s4
    li 0 s5
    E3:
    ld 0 s4 t0
    bgeu rel:E8 t0 s5
    slli 4 s5 t1
    add t1 s4 t1
    ld 16 t1 s6
    ld 8 t1 a2
    la irel_words a0
    li 1 a1
    li 0 a5
    call prim
    la tls_prims a0
    addi 22 a0 a0
    call tconst
    mv a0 a2
    la irel_words a0
    li 1 a1
    li 0 a5
    call prim
    ld NODE_children s6 t0
    ld 8 t0 a2
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    call cfind
    beqz E4 a0
    call label_addr
    E4:
    mv a0 a2
    la irel_words a0
    li 1 a1
    li 0 a5
    call prim
    addi 1 s5 s5
    j E3
    E8:
    sd 0 zero s4
    leave5
"));

# irelplace: a word left without its entry stops
edit(\$t, 'cc/irelplace',
    "        P9:\n          leave3\n",
    asm(8, "
    P9:
    la irw_vars t0
    ld 0 t0 t1
    beqz P7 t1
    ld 16 t0 a0
    la msg_ifgaddr a1
    li msg_ifgaddr_len a2
    j diename
    P7:
    leave3
"));

# the words and the message
once(\$t, "  start_node:\n    reserve\n      NODE_size\n",
    "  start_node:\n    reserve\n      NODE_size\n  irw_pend:\n    reserve\n      8\n  irw_vars:\n    reserve\n      65544\n", 'start_node');
my ($mf, $mt) = find(\$t, 'msg_untyped');
substr($t, $mt, 0) = "      msg_ifgaddr:\n        ascii\n          ttpc: the address of an ifunc in a global's value needs glibc's IRELATIVE table (__rela_iplt_start):\\x20\n";
save();
