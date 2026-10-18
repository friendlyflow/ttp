# start.pl: glibc's own startup in a C program (src/glibc, riscv64): its
# entry is the library's _start (start.S, an asm function), and its ifuncs
# are resolved by glibc's apply_irel, as in a static program gcc and ld
# make, from the IRELATIVE table ttpc makes as the linker does.
#
# cc_library first looks up _start (startlib): the program's own, a label
# of its page, or else the library's, which the lookup puts on the list to
# be placed, as any name C reaches. A program without ttpc's own init
# routine (which a C _start of the program's calls: startinit) gets the
# IRELATIVE table instead, after everything the library list placed (so
# that it is as long in both passes: irelplace), if the library
# declares glibc's __rela_iplt_start (weak, apply_irel's): that weak
# declaration placed as the label of the table, aligned to 8, an Elf64_Rela
# per ifunc (the address of its slot, R_RISCV_IRELATIVE 58, its resolver;
# irelbody), then __rela_iplt_end's declaration placed after it. apply_irel
# calls each resolver with hwcap and __riscv_hwprobe, as ttpc's init
# routine did, and stores what it returns in the slot. (The table is
# riscv64's Elf64_Rela: the other targets come with their glibc startup.)
# The frame's elf_header names _start before cc_library places it: in the
# first pass, eval_arg takes a library definition not placed yet as a
# label to come.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# the names, the words it emits, a node to look a name up by
after_fn('str_asm', "  irel_names:\n    ascii\n      __rela_iplt_start__rela_iplt_end\n  irel_words:\n    ascii\n      dword\\x00align\\x00reserve\\x00\n");
once(\$t, "  lazy:\n    reserve\n      LZ_size\n", "  lazy:\n    reserve\n      LZ_size\n  start_node:\n    reserve\n      NODE_size\n", 'lazy');

# cc_library: _start first; the table where ttpc's own init routine is not
edit(\$t, 'cc/cc_library',
    "        enter3\n        call\n          libbase\n",
    "        enter3\n        call\n          startlib\n        call\n          libbase\n",
    "        L9:\n          leave3\n",
    "        L9:\n          call\n            irelplace\n          leave3\n");

my $ind = indent_of('cc/cc_library');
my $f = '';
$f .= cfn('startlib', "the program's entry, _start: its own (a label of its page) or the library's, which the lookup puts on the list", "
    enter1
    la ifnames a0
    addi 26 a0 a0
    li 6 a1
    la start_node a2
    sb NODE_children_len zero a2
    sb NODE_content_len a1 a2
    sd NODE_content a0 a2
    call cfind
    leave1
", $ind);
$f .= cfn('irelfind', 'the library\'s weak declaration of the name a0 a1 (__rela_iplt_start, __rela_iplt_end), or 0', "
    enter2
    la start_node a2
    sb NODE_children_len zero a2
    sb NODE_content_len a1 a2
    sd NODE_content a0 a2
    call cfind
    beqz Q9 a0
    mv a0 s4
    call defkw
    li KW_weak t0
    bne rel:Q8 t0 a0
    mv s4 a0
    leave2
    Q8:
    li 0 a0
    Q9:
    leave2
", $ind);
$f .= cfn('irelplace', 'the IRELATIVE table, where glibc\'s apply_irel finds it: __rela_iplt_start, an entry per ifunc, __rela_iplt_end (none with ttpc\'s own init routine)', "
    enter3
    call libbase
    ld 8 a0 t0
    li 2 t1
    beq rel:P9 t1 t0
    la irel_names s4
    mv s4 a0
    li 17 a1
    call irelfind
    beqz P9 a0
    mv a0 s5
    la irel_words a0
    addi 6 a0 a0
    li 1 a1
    li 8 a2
    li 0 a5
    call prim
    mv s5 a0
    la irelbody a1
    call place
    addi 17 s4 a0
    li 15 a1
    call irelfind
    beqz P9 a0
    la irelnone a1
    call place
    P9:
    leave3
", $ind);
$f .= cfn('irelbody', 'an Elf64_Rela per ifunc: the address of its slot, R_RISCV_IRELATIVE (58), its resolver', "
    enter5
    call libbase
    mv a0 s4
    li 0 s5
    E1:
    ld 24 s4 t0
    bgeu rel:E9 t0 s5
    slli 3 s5 t1
    li32 524320 t2
    add t2 s4 t2
    add t1 t2 t2
    ld 0 t2 s6
    mv s6 a0
    call label_addr
    mv a0 a2
    la irel_words a0
    li 1 a1
    li 0 a5
    call prim
    la irel_words a0
    li 1 a1
    li 58 a2
    li 0 a5
    call prim
    ld NODE_children s6 t0
    ld 8 t0 a2
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    call cfind
    beqz E2 a0
    call label_addr
    E2:
    mv a0 a2
    la irel_words a0
    li 1 a1
    li 0 a5
    call prim
    addi 1 s5 s5
    j E1
    E9:
    leave5
", $ind);
$f .= cfn('irelnone', 'nothing: __rela_iplt_end is only a label', "
    ret
", $ind);
after_fn('cc/cc_library', $f);

# eval_arg: a definition of the library not placed yet, in the first
# pass, is a label still to come (0), as a label of the program page is
# there; not a constant to run. Such a definition (a C function or global,
# a thread local, an asm function: the frame's _start, start.S's) starts
# with a word (its type, thread local, asm), a constant with an instruction.
edit(\$t, 'eval_arg',
    "      call\n        label_addr\n      bnez\n        L9\n        a0\n      mv\n        s9\n        a0\n      lbu\n",
    "      call\n        label_addr\n      bnez\n        L9\n        a0\n" . asm(6, "
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:L50 t1 t0
    lbu NODE_children_len s9 t0
    beqz L50 t0
    ld NODE_children s9 t0
    ld 0 t0 t0
    lbu NODE_children_len t0 t0
    bnez L50 t0
    li 0 a0
    j L9
") . "    L50:\n      mv\n        s9\n        a0\n      lbu\n");
# ifslot: the resolver of an ifunc is reached when its slot is placed, so
# that the library list places it (ttpc's own init routine reached it, the
# IRELATIVE table comes after the list)
edit(\$t, 'cc/ifslot',
    "        enter1\n        call\n          ifadd\n",
    "        enter1\n" . asm(8, "
    mv a0 s4
    call ifadd
    ld NODE_children s4 t0
    ld 8 t0 a2
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    call cfind
"));
save();
