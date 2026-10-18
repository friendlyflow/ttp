# tls.pl: real thread locals, where the target says so (cc_tls, 1 on
# riscv64): a thread local is in the TLS image, at its offset from the
# thread pointer, as gcc and ld lay it out (riscv64: variant I, tp points
# at the image of the thread's block), not a global of its own.
#
# The C layer puts off each thread local it meets (tlsdefer, in cc's way to
# a global) and lays them out together after the library list, at the end of
# cc_library (tlsplace): __tls_start (aligned to 64), the thread locals in
# the order they were met, __tls_end; then the list goes on with what their
# values reached (a thread local reached only so stops the compile:
# msg_tlslate), and the IRELATIVE table ends it. The target's frame names the two in its
# PT_TLS program header (macros/riscv64.ff.txt), which glibc's static
# startup reads (__libc_setup_tls copies the image into the thread's block
# and sets tp). Where C reaches a thread local (gaddr), its address is tp +
# its offset in the image (tlsaddr: the offset by cc_li_big, of one size in
# both passes, then cc_addreg tp). A C _start of the program's own, with no
# glibc to set tp, points tp at the image itself (tpinit), the block of its
# one thread: 4 KiB of zeros go before it, where glibc's code finds the
# thread's struct pthread below tp (THREAD_SELF, 1.8 KiB on riscv64), as
# one thread that nothing has set has it. Compile time (the JIT, for the host) and a program that lays
# itself out (origin, elf_header: no frame, no PT_TLS) keep thread locals
# as globals. cc_names gains cc_tls (at 109).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# (T=ttpc.defs.ff: its message's length)
if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  msg_below_len:\n    size\n      msg_below\n", "  msg_below_len:\n    size\n      msg_below\n  msg_tlslate_len:\n    size\n      msg_tlslate\n", 'msg_below_len');
    save();
    exit;
}

sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

once(\$t, 'cc_word\x00cc_argoff\x00cc_entryoff\x00' . "\n", 'cc_word\x00cc_argoff\x00cc_entryoff\x00cc_tls\x00' . "\n", 'cc_names');
after_fn('irel_words', "  tls_names:\n    ascii\n      __tls_start__tls_end\n  msg_tlslate:\n    ascii\n      ttpc: a thread local reached only from a thread local's value:\\x20\n");
once(\$t, "  start_node:\n    reserve\n      NODE_size\n", "  start_node:\n    reserve\n      NODE_size\n  tls_vars:\n    reserve\n      32784\n", 'start_node');

# cc: a global that is a thread local, put off
edit(\$t, 'cc',
    "    L2:\n      mv\n        s4\n        a0\n      call\n        dtype\n      call\n        talign\n",
    "    L2:\n" . asm(6, "
    mv s4 a0
    call tlsdefer
    bnez L8 a0
") . "      mv\n        s4\n        a0\n      call\n        dtype\n      call\n        talign\n");
# cc_library: the thread locals, last
# (the thread locals' values may reach more of the library: the list goes
# on after them, then the IRELATIVE table)
edit(\$t, 'cc/cc_library',
    "        enter3\n        call\n          startlib\n",
    "        enter3\n        la\n          tls_vars\n          t0\n        li32\n          32776\n          t1\n        add\n          t1\n          t0\n          t0\n        sd\n          0\n          zero\n          t0\n        call\n          startlib\n",
    "        L9:\n          call\n            irelplace\n          leave3\n",
    "        L9:\n          call\n            tlsplace\n          bnez\n            L5\n            a0\n          call\n            irelplace\n          leave3\n");
# gaddr: a thread local's address from tp
edit(\$t, 'cc/gaddr',
    "        enter1\n        mv\n          a0\n          s4\n        call\n          label_addr\n",
    "        enter1\n        mv\n          a0\n          s4\n        call\n          tlsaddr\n        bnez\n          G9\n          a0\n        mv\n          s4\n          a0\n        call\n          label_addr\n");
{
    my ($from, $to) = find(\$t, 'cc/gaddr');
    substr($t, $to, 0) = "        G9:\n          leave1\n";
}
# fnbody: a C _start's tp
edit(\$t, 'cc/fnbody',
    "          call\n            startinit\n",
    "          call\n            startinit\n          mv\n            s4\n            a0\n          call\n            tpinit\n");

# The library list lives through both passes (cc_frame makes it once): in
# the second pass it already holds what the first pass's thread locals
# reached, after the image. So the list's place of the image is kept
# (tls_vars + 32768, the first pass's count when it was laid out; cc_frame
# clears it), and the second pass's loop stops there for the image, as
# initpos does for ttpc's own init routine.
edit(\$t, 'cc_frame',
    "    sd\n      24\n      zero\n      a0\n    lbu\n      NODE_children_len\n      s4\n      s5\n",
    "    sd\n      24\n      zero\n      a0\n" . asm(4, "
    la tls_vars t1
    li32 32768 t2
    add t2 t1 t1
    li -1 t2
    sd 0 t2 t1
") . "    lbu\n      NODE_children_len\n      s4\n      s5\n");
edit(\$t, 'cc/cc_library',
    "        L5:\n          ld\n            0\n            s5\n            t0\n          bgeu\n            rel\n              L9\n            t0\n            s4\n",
    "        L5:\n" . asm(10, "
    ld 0 s5 t0
    la tls_vars t1
    li32 32776 t2
    add t2 t1 t2
    ld 0 t2 t3
    bnez L51 t3
    ld -8 t2 t3
    bltz L51 t3
    bgeu rel:L51 t0 t3
    mv t3 t0
") . "        L51:\n          bgeu\n            rel\n              L9\n            t0\n            s4\n");

my $ind = indent_of('cc/cc_library');
my $f = '';
$f .= cfn('tlson', '1 where thread locals are in the TLS image: the target\'s cc_tls, in a program the frame lays out (whose library list cc_library places them with), not in compile time\'s JIT', "
    enter1
    la ccs t0
    ld CC_jit t0 t0
    bnez Y8 t0
    call libbase
    ld 8 a0 t0
    beqz Y8 t0
    la cc_names a0
    addi 109 a0 a0
    call tconst
    leave1
    Y8:
    li 0 a0
    leave1
", $ind);
$f .= cfn('istls', '1 if the global a0 is a thread local (thread local first, or after weak)', "
    enter2
    mv a0 s4
    li 0 s5
    lbu NODE_children_len s4 t0
    li 2 t1
    bltu rel:X1 t1 t0
    mv t1 t0
    X1:
    beqz X8 t0
    mv t0 s5
    ld NODE_children s4 s4
    X2:
    ld 0 s4 a0
    lbu NODE_children_len a0 t0
    bnez X3 t0
    call kwof
    li KW_tls t0
    beq rel:X9 t0 a0
    X3:
    addi 8 s4 s4
    addi -1 s5 s5
    bnez X2 s5
    X8:
    li 0 a0
    leave2
    X9:
    li 1 a0
    leave2
", $ind);
$f .= cfn('tlsdefer', 'the global a0, if it is a thread local of the TLS image, put off for tlsplace (then 1); else 0', "
    enter2
    mv a0 s4
    call tlson
    beqz D8 a0
    la tls_vars t0
    ld 8 t0 t0
    bnez D8 t0
    mv s4 a0
    call istls
    beqz D8 a0
    la tls_vars t0
    ld 0 t0 t1
    li32 4094 t2
    bgeu rel:D7 t2 t1
    slli 3 t1 t2
    add t2 t0 t2
    sd 16 s4 t2
    addi 1 t1 t1
    sd 0 t1 t0
    li 1 a0
    leave2
    D8:
    li 0 a0
    leave2
    D7:
    la msg_trees a1
    li msg_trees_len a2
    j die
", $ind);
$f .= cfn('tlsplace', 'the TLS image, once (then 1, else 0): __tls_start (aligned to 64), the thread locals put off, __tls_end; empty without thread locals', "
    enter5
    call tlson
    beqz T9 a0
    la tls_vars s4
    li32 32776 t1
    add t1 s4 t1
    ld 0 t1 t2
    bnez T7 t2
    li 1 t2
    sd 0 t2 t1
    ld -8 t1 t2
    bgez T6 t2
    call libbase
    ld 0 a0 t2
    la tls_vars s4
    li32 32768 t1
    add t1 s4 t1
    sd 0 t2 t1
    T6:
    la irel_words a0
    addi 6 a0 a0
    li 1 a1
    li 64 a2
    li 0 a5
    call prim
    la irel_words a0
    addi 12 a0 a0
    li 1 a1
    li32 4096 a2
    li 0 a5
    call prim
    la tls_names a0
    li 11 a1
    call find_fn
    beqz T9 a0
    la irelnone a1
    call place
    la tls_vars s4
    li 1 t0
    sd 8 t0 s4
    li 0 s5
    T1:
    ld 0 s4 t0
    bgeu rel:T2 t0 s5
    slli 3 s5 t1
    add t1 s4 t1
    ld 16 t1 a0
    call cc
    addi 1 s5 s5
    j T1
    T2:
    sd 8 zero s4
    sd 0 zero s4
    la tls_names a0
    addi 11 a0 a0
    li 9 a1
    call find_fn
    beqz T9 a0
    la irelnone a1
    call place
    li 1 a0
    leave5
    T7:
    ld 0 s4 t0
    bnez T8 t0
    T9:
    li 0 a0
    leave5
    T8:
    la tls_vars t0
    ld 16 t0 s4
    la msg_tlslate a1
    li msg_tlslate_len a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
", $ind);
$f .= cfn('tlsaddr', 'the address of the global a0, if it is a thread local of the TLS image: tp + its offset in the image (then 1); else 0', "
    enter3
    mv a0 s4
    call tlson
    beqz A8 a0
    mv s4 a0
    call istls
    beqz A8 a0
    mv s4 a0
    call label_addr
    mv a0 s5
    la tls_names a0
    li 11 a1
    call find_fn
    beqz A8 a0
    call label_addr
    sub a0 s5 a2
    la cc_names a0
    addi 20 a0 a0
    li 2 a1
    la cc_names a5
    addi 47 a5 a5
    call prim
    la cc_addreg a0
    li 4 a1
    call seq
    li 1 a0
    leave3
    A8:
    li 0 a0
    leave3
", $ind);
$f .= cfn('tpinit', 'a C _start (the function a0) of a program with the TLS image: tp points at the image, the block of its one thread', "
    enter2
    mv a0 s4
    call tlson
    beqz P8 a0
    ld NODE_content s4 a0
    lbu NODE_content_len s4 a1
    la ifnames a2
    addi 26 a2 a2
    li 7 a3
    call streq
    beqz P8 a0
    la tls_names a0
    li 11 a1
    call find_fn
    beqz P8 a0
    call gaddr
    la cc_mv_to a0
    li 4 a1
    call seq
    P8:
    leave2
", $ind);
after_fn('cc/cc_library', $f);
save();
