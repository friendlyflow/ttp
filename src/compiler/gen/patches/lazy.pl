# lazy.pl: import of a folder (the user's choice, 2026-10-18: `import` /
# glibc, like C's headers): a folder with an index.ff (ffsplit.pl makes one
# of a library tree) is a library read lazily. ttpc reads the index, a page
# index: of name: / file, and then only what the program reaches: a reach
# over the library's definitions by their names. The texts of the program
# (every node's) are looked up among the index's names; a name found is
# reached, its file read (once: put in front of the program, as an import
# is) and its definition (an enum's for its constants, an asm function's
# for its entries) looked through in
# turn, until nothing is new. A text that is a name only by chance (a local,
# a field) reaches a little more, never less. First reached are the names
# ttpc calls by itself: __riscv_hwprobe and _start (ifnames) and the
# soft-fp of long double (cc_sfnames), which move out of the cc group to the
# page's constant data for it. A tree the program imports whole is looked
# through too.
#
# lazylib and lazyrun (and their helpers) end the assembler (layer 0), on a
# table of its own, lazy: the libraries (their folders), the files of their
# indexes (each read once), the trees imported whole, the names reached and
# not yet looked through, and the hash of the names (open addressing, 2^19
# slots: a name: node, its file, its definition once read, reached).
# ws_text, which holds the paths, grows to 64 KiB. Run on ttpc.ff, then
# (T=ttpc.defs.ff) on its definitions.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    my $c = '';
    for (['LZ_nlibs', 0], ['LZ_nfiles', 8], ['LZ_nwork', 16], ['LZ_nnames', 24], ['LZ_nstack', 32], ['LZ_libs', 64],
         ['LZ_maxlibs', 16], ['LZ_work', 320], ['LZ_maxwork', 256], ['LZ_files', 4096], ['LZ_maxfiles', 4096],
         ['LZ_stack', 262144], ['LZ_hash', 4194304], ['LZ_hmask', 16777184], ['LZ_maxnames', 262144],
         ['LZ_size', 20971520]) {
        $c .= "  $_->[0]:\n    addi\n      $_->[1]\n      zero\n      a0\n";
    }
    once(\$t, "  WS_TEXT:\n    addi\n      16384\n", "  WS_TEXT:\n    addi\n      65536\n", 'WS_TEXT');
    once(\$t, "\nmessages:\n", "\n$c" . "messages:\n", 'the end of ttpc:');
    save();
    exit;
}

sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
# the block of a function, out of the tree, its indent made $to
sub take {
    my ($name, $to) = @_;
    my ($from, $end) = find(\$t, $name);
    my $b = substr($t, $from, $end - $from, '');
    my ($ind) = $b =~ /^( *)/;
    my $d = $to - length $ind;
    join '', map { $d < 0 ? substr($_, -$d) : (' ' x $d) . $_ } split /^/, $b;
}
sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# the names the C layer calls by itself, to the page's constant data
my $ind = indent_of('cc_opseq');
my $moved = take('ifnames', $ind) . take('cc_sfnames', $ind);
after_fn('cc_opseq', $moved . "  str_index:\n    ascii\n      /index.ff\\x00\n  str_enum:\n    ascii\n      enum\n  str_items:\n    ascii\n      items\n  str_asm:\n    ascii\n      asm\n");

# the table, and room for the paths
once(\$t, "  ws_text:\n    reserve\n      16384\n", "  ws_text:\n    reserve\n      65536\n  lazy:\n    reserve\n      LZ_size\n", 'ws_text');

# program_root: the table cleared, an import of a folder, and the files
# the program needs before the program
edit(\$t, 'program_root',
    "    enter5\n    mv\n      a0\n      s4\n    mv\n      a1\n      s5\n    slli\n",
    "    enter5\n    mv\n      a0\n      s4\n    mv\n      a1\n      s5\n    call\n      lazyreset\n    slli\n",
    "      call\n        rel_path\n      call\n        tree\n      call\n        add_page\n    L7:\n",
    "      call\n        rel_path\n      call\n        lazylib\n      beqz\n        L7\n        a0\n      call\n        tree\n      call\n        lazywork\n      call\n        add_page\n    L7:\n",
    "    L6:\n      mv\n        s6\n        a0\n      call\n        add_page\n",
    "    L6:\n      mv\n        s6\n        a0\n      call\n        lazyrun\n      mv\n        s6\n        a0\n      call\n        add_page\n");

my $die = "
    la msg_trees a1
    li msg_trees_len a2
    j die";
my $hash = "
    la lazy s7
    lui LZ_hash t0
    add t0 s7 s7";
my $f = '';

$f .= cfn('lazyreset', 'the lazy table cleared, of an earlier workspace', "
    la lazy t0
    sd LZ_nwork zero t0
    sd LZ_nstack zero t0
    ld LZ_nfiles t0 t1
    beqz R9 t1
    sd LZ_nlibs zero t0
    sd LZ_nfiles zero t0
    sd LZ_nnames zero t0
    lui LZ_hash t1
    add t0 t1 t1
    li32 LZ_hmask t2
    add t1 t2 t2
    R1:
    sd 0 zero t1
    sd 8 zero t1
    sd 16 zero t1
    sd 24 zero t1
    beq rel:R9 t2 t1
    addi 32 t1 t1
    j R1
    R9:
    ret
", 2);

$f .= cfn('lazywork', 'the tree a0, imported whole, to be looked through for the names of a library (a0 kept)', "
    la lazy t0
    ld LZ_nwork t0 t1
    li LZ_maxwork t2
    bgeu rel:W9 t2 t1
    slli 3 t1 t2
    addi LZ_work t2 t2
    add t0 t2 t2
    sd 0 a0 t2
    addi 1 t1 t1
    sd LZ_nwork t1 t0
    ret
    W9:$die
", 2);

$f .= cfn('lazyhash', 'the place of the name a0 a1 (bytes, length) in the hash: its first slot, an offset', "
    li 1365 t0
    H1:
    beqz H2 a1
    lbu 0 a0 t1
    slli 5 t0 t2
    add t2 t0 t0
    add t1 t0 t0
    addi 1 a0 a0
    addi -1 a1 a1
    j H1
    H2:
    slli 5 t0 t0
    li32 LZ_hmask t1
    and t1 t0 a0
    ret
", 2);

$f .= cfn('lazyfind', 'the entry (its slot in the hash) of the name a0 a1 in the libraries, or 0', "
    enter5
    mv a0 s4
    mv a1 s5
    call lazyhash
    mv a0 s6$hash
    F1:
    add s6 s7 s8
    ld 0 s8 t0
    beqz F9 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    addi -1 a3 a3
    mv s4 a0
    mv s5 a1
    call streq
    bnez F8 a0
    addi 32 s6 s6
    li32 LZ_hmask t0
    and t0 s6 s6
    j F1
    F8:
    mv s8 a0
    leave5
    F9:
    li 0 a0
    leave5
", 2);

$f .= cfn('lazyadd', 'the name a0 (an entry name: of an index) in the hash, its file the slot a1; a name there already stays', "
    enter5
    mv a0 s4
    mv a1 s5
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    addi -1 a1 a1
    call lazyhash
    mv a0 s6$hash
    A1:
    add s6 s7 s8
    ld 0 s8 t0
    beqz A8 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call streq
    bnez A9 a0
    addi 32 s6 s6
    li32 LZ_hmask t0
    and t0 s6 s6
    j A1
    A8:
    la lazy t0
    ld LZ_nnames t0 t1
    lui LZ_maxnames t2
    bgeu rel:A7 t2 t1
    addi 1 t1 t1
    sd LZ_nnames t1 t0
    sd 0 s4 s8
    sd 8 s5 s8
    A9:
    leave5
    A7:$die
", 2);

$f .= cfn('lazyfile', 'the slot of the file a0 (a leaf, its name) of library a1: the last one, or a new one', "
    enter5
    mv a0 s4
    mv a1 s5
    la lazy s6
    ld LZ_nfiles s6 s7
    beqz N2 s7
    addi -1 s7 t0
    slli 5 t0 t0
    lui LZ_files t1
    add t1 t0 t0
    add s6 t0 s8
    ld 8 s8 t0
    bne rel:N2 s5 t0
    ld 0 s8 t0
    ld NODE_content t0 a2
    lbu NODE_content_len t0 a3
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    call streq
    beqz N2 a0
    mv s8 a0
    leave5
    N2:
    lui LZ_maxfiles t0
    bgeu rel:N9 t0 s7
    slli 5 s7 t0
    lui LZ_files t1
    add t1 t0 t0
    add s6 t0 a0
    sd 0 s4 a0
    sd 8 s5 a0
    sd 16 zero a0
    addi 1 s7 s7
    sd LZ_nfiles s7 s6
    leave5
    N9:$die
", 2);

$f .= cfn('lazyidx', 'the entries of an index under a0 (its pages, through layers) in the hash, of library a1: an entry is name: / file', "
    enter5
    mv a1 s6
    lbu NODE_children_len a0 s5
    ld NODE_children a0 s4
    I1:
    beqz I9 s5
    ld 0 s4 s7
    mv s7 a0
    call is_comment
    bnez I8 a0
    lbu NODE_children_len s7 t0
    beqz I8 t0
    li 1 t1
    bne rel:I2 t1 t0
    ld NODE_children s7 t2
    ld 0 t2 a0
    lbu NODE_children_len a0 t3
    bnez I2 t3
    mv s6 a1
    call lazyfile
    mv a0 a1
    mv s7 a0
    call lazyadd
    j I8
    I2:
    mv s7 a0
    mv s6 a1
    call lazyidx
    I8:
    addi 8 s4 s4
    addi -1 s5 s5
    j I1
    I9:
    leave5
", 2);

$f .= cfn('lazyback', 'the text pool without the 0 that ends its last text, for one to follow it', "
    la bstate t0
    ld BS_text t0 t1
    addi -1 t1 t1
    sd BS_text t1 t0
    ret
", 2);

$f .= cfn('lazylib', 'the import of the path a0 (a text that ends in 0): of a folder with an index.ff, a library, whose index is read (then 0); else a0', "
    enter8
    mv a0 s4
    li 0 s5
    B1:
    add s5 s4 t0
    lbu 0 t0 t0
    beqz B2 t0
    addi 1 s5 s5
    j B1
    B2:
    mv s4 a0
    mv s5 a1
    call savetext
    mv a0 s6
    call lazyback
    la str_index a0
    li 9 a1
    call savetext
    li AT_FDCWD a0
    mv s6 a1
    li O_RDONLY a2
    li 0 a3
    li SYS_openat a7
    ecall
    bltz B9 a0
    li SYS_close a7
    ecall
    la lazy s7
    ld LZ_nlibs s7 s8
    li LZ_maxlibs t1
    bgeu rel:B8 t1 s8
    slli 4 s8 t1
    addi LZ_libs t1 t1
    add s7 t1 t1
    sd 0 s4 t1
    sd 8 s5 t1
    addi 1 s8 t0
    sd LZ_nlibs t0 s7
    mv s6 a0
    call tree
    mv s8 a1
    call lazyidx
    li 0 a0
    leave8
    B8:$die
    B9:
    mv s4 a0
    leave8
", 2);

$f .= cfn('lazyref', 'the name a0 a1 reached: its entry, if the libraries have it, to be looked through (once)', "
    enter1
    call lazyfind
    beqz Z9 a0
    ld 24 a0 t0
    bnez Z9 t0
    li 1 t0
    sd 24 t0 a0
    la lazy t0
    ld LZ_nstack t0 t1
    lui LZ_maxnames t2
    bgeu rel:Z8 t2 t1
    slli 3 t1 t2
    lui LZ_stack t3
    add t3 t2 t2
    add t0 t2 t2
    sd 0 a0 t2
    addi 1 t1 t1
    sd LZ_nstack t1 t0
    Z9:
    leave1
    Z8:$die
", 2);

$f .= cfn('lazyscan', 'the names in the tree a0 reached (each node\'s text, all the way down)', "
    enter3
    mv a0 s4
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    beqz S2 a1
    call lazyref
    S2:
    lbu NODE_children_len s4 s5
    ld NODE_children s4 s6
    S3:
    beqz S9 s5
    ld 0 s6 a0
    call lazyscan
    addi 8 s6 s6
    addi -1 s5 s5
    j S3
    S9:
    leave3
", 2);

$f .= cfn('lazydef', 'the definition a0 of the name of a2 (a name: node) in file a1: its entry\'s, if it is that file\'s and has none yet', "
    enter3
    mv a0 s4
    mv a1 s5
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    addi -1 a1 a1
    call lazyfind
    beqz D9 a0
    ld 8 a0 t0
    bne rel:D9 s5 t0
    ld 16 a0 t0
    bnez D9 t0
    sd 16 s4 a0
    D9:
    leave3
", 2);

$f .= cfn('lazyfill', 'the definitions under a0 (a page of file a1, through its layers) in their entries: an enum\'s for its constants too, an asm function\'s for its entries', "
    enter8
    mv a1 s5
    lbu NODE_children_len a0 s6
    ld NODE_children a0 s7
    G1:
    beqz G9 s6
    ld 0 s7 s4
    mv s4 a0
    call is_layer
    beqz G2 a0
    mv s4 a0
    mv s5 a1
    call lazyfill
    j G8
    G2:
    mv s4 a0
    call is_fn
    beqz G8 a0
    mv s4 a0
    mv s5 a1
    mv s4 a2
    call lazydef
    lbu NODE_children_len s4 t0
    beqz G8 t0
    ld NODE_children s4 t0
    ld 0 t0 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    la str_enum a2
    li 4 a3
    call streq
    bnez G21 a0
    ld NODE_children s4 t0
    ld 0 t0 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    la str_asm a2
    li 3 a3
    call streq
    beqz G8 a0
    G21:
    lbu NODE_children_len s4 s8
    ld NODE_children s4 s9
    G3:
    beqz G8 s8
    ld 0 s9 a2
    ld NODE_content a2 a0
    lbu NODE_content_len a2 a1
    la str_items a2
    li 5 a3
    call streq
    beqz G5 a0
    ld 0 s9 t0
    lbu NODE_children_len t0 s10
    ld NODE_children t0 s11
    G4:
    beqz G7 s10
    ld 0 s11 a0
    call is_fn
    beqz G41 a0
    mv s4 a0
    mv s5 a1
    ld 0 s11 a2
    call lazydef
    G41:
    addi 8 s11 s11
    addi -1 s10 s10
    j G4
    G5:
    ld 0 s9 a0
    call is_fn
    beqz G7 a0
    mv s4 a0
    mv s5 a1
    ld 0 s9 a2
    call lazydef
    G7:
    addi 8 s9 s9
    addi -1 s8 s8
    j G3
    G8:
    addi 8 s7 s7
    addi -1 s6 s6
    j G1
    G9:
    leave8
", 2);

$f .= cfn('lazyload', 'the file of slot a0 read, once: put in front of the program, its definitions in their entries', "
    enter5
    mv a0 s4
    ld 16 s4 t0
    bnez L9 t0
    li 1 t0
    sd 16 t0 s4
    ld 8 s4 t1
    slli 4 t1 t1
    addi LZ_libs t1 t1
    la lazy t0
    add t0 t1 t1
    ld 0 t1 a0
    ld 8 t1 a1
    call savetext
    mv a0 s5
    call lazyback
    la str_index a0
    li 1 a1
    call savetext
    call lazyback
    ld 0 s4 t0
    ld NODE_content t0 a0
    lbu NODE_content_len t0 a1
    call savetext
    mv s5 a0
    call tree
    mv a0 s5
    call add_page
    lbu NODE_children_len s5 s6
    ld NODE_children s5 s7
    L1:
    beqz L9 s6
    ld 0 s7 a0
    call is_comment
    bnez L2 a0
    ld 0 s7 a0
    mv s4 a1
    call lazyfill
    L2:
    addi 8 s7 s7
    addi -1 s6 s6
    j L1
    L9:
    leave5
", 2);

$f .= cfn('lazyrun', 'with a library imported: what the program a0 reaches of it read, from the names ttpc calls by itself, the program\'s, those of the trees it imports whole, then of each definition reached, until none is new (a0 kept)', "
    enter3
    mv a0 s4
    la lazy t0
    ld LZ_nlibs t0 t0
    beqz U9 t0
    la ifnames a0
    li 15 a1
    call lazyref
    la ifnames a0
    addi 26 a0 a0
    li 6 a1
    call lazyref
    la cc_sfnames s5
    U2:
    lbu 0 s5 t0
    li 95 t1
    bne rel:U5 t1 t0
    mv s5 a0
    li 0 a1
    U3:
    add a1 s5 t0
    lbu 0 t0 t0
    beqz U4 t0
    addi 1 a1 a1
    j U3
    U4:
    call lazyref
    addi 16 s5 s5
    j U2
    U5:
    mv s4 a0
    call lazyscan
    U6:
    la lazy t0
    ld LZ_nwork t0 t1
    beqz U7 t1
    addi -1 t1 t1
    sd LZ_nwork t1 t0
    slli 3 t1 t1
    addi LZ_work t1 t1
    add t0 t1 t1
    ld 0 t1 a0
    call lazyscan
    j U6
    U7:
    la lazy t0
    ld LZ_nstack t0 t1
    beqz U9 t1
    addi -1 t1 t1
    sd LZ_nstack t1 t0
    slli 3 t1 t1
    lui LZ_stack t2
    add t2 t1 t1
    add t0 t1 t1
    ld 0 t1 s5
    ld 8 s5 a0
    call lazyload
    ld 16 s5 a0
    beqz U7 a0
    call lazyscan
    j U7
    U9:
    mv s4 a0
    leave3
", 2);

# at the end of the page's assembler (layer 0), after exit: in program_root
# they would put _start's and read_tree's branches to usage and read_failed
# out of a branch's reach. add_page, which they call, out of program_root
# to the page, where they see it.
my $add = take('program_root/add_page', 2);
after_fn('program_root', $add);
once(\$t, "\n1:\n", "\n$f" . "1:\n", 'the layer after the assembler');
save();
