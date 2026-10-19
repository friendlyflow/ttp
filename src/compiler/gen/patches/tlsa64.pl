# tlsa64.pl: thread locals in the TLS image on aarch64 too, and the
# IRELATIVE table of every target's glibc startup. What tls.pl and start.pl
# wrote for riscv64 alone now goes through the target's primitives:
#
#   cc_addtls   V += the address of the thread's TLS image (riscv64: tp;
#               aarch64: tpidr_el0 + 64, its TCB's 16 bytes rounded up to
#               the image's alignment, 64, as glibc's static TLS has it)
#   cc_settls   the thread's TLS image is V (a C _start of the program's own)
#   cc_irel     the type of an IRELATIVE relocation (riscv64 58, aarch64
#               1032, x86_64 37, arm 160)
#
# tlsaddr (a thread local's address) emitted cc_addreg 4 (riscv64's tp),
# tpinit cc_setreg 4, irelbody the word 58: they emit cc_addtls, cc_settls
# and cc_irel's value. Their names are tls_prims, after tls_names.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
# within function $name, the instructions $old (asm form) become $new
sub reasm {
    my ($name, $old, $new) = @_;
    my ($from, $to) = find(\$t, $name);
    my $e = substr($t, $from, $to - $from);
    # the indent of the instructions: the function's + 2, or deeper in a block
    $e =~ /^( *)/ or die;
    my ($ind) = grep { my $o = asm($_, $old); () = $e =~ /^\Q$o\E/mg } map { length($1) + $_ } 2, 4, 6;
    defined $ind or die "tlsa64: $name: not found\n";
    my ($o, $n) = (asm($ind, $old), asm($ind, $new));
    once(\$e, $o, $n, $name);
    substr($t, $from, $to - $from) = $e;
}

after_fn('tls_names', "  tls_prims:\n    ascii\n      \\x00cc_addtls\\x00\\x00cc_settls\\x00cc_irel\\x00\n");

reasm('cc/tlsaddr', "
    la cc_addreg a0
    li 4 a1
    call seq
", "
    la tls_prims a0
    call seq
");
reasm('cc/tpinit', "
    la cc_mv_to a0
    li 4 a1
    call seq
", "
    la tls_prims a0
    addi 11 a0 a0
    call seq
");
reasm('cc/irelbody', "
    la irel_words a0
    li 1 a1
    li 58 a2
", "
    la tls_prims a0
    addi 22 a0 a0
    call tconst
    mv a0 a2
    la irel_words a0
    li 1 a1
");
save();
