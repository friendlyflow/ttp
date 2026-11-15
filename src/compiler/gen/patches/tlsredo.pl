# tlsredo.pl: every thread local is in the TLS image, also one that only
# what comes after the image reaches. cc_library lays out the image once
# (tlsplace, after the list's code and sections, before the data put off);
# a thread local reached after that (from a function that only a global's
# value reaches, a vtable's entry: glibc's _nl_current_LC_CTYPE, errno
# through datacheck's program; or from a thread local's own value) stopped
# ttpc: "a thread local reached only from a thread local's value". Placing
# the image after the data instead (tlslast.pl, taken back) moved what a
# thread local's value reaches (glibc's __resp = &_res) between the passes.
#
# Now the first pass that meets such a thread local goes on without it and
# is run again (tls_redo; at most 8 times, then the stop as before). The
# library's list lives through the passes and holds, after the image's
# place, every thread local the pass before reached there: tlsplace takes
# those into the image too (after the ones put off before it, in the
# list's order), and when the list comes to one of them later, tlsdefer
# finds it placed (its label, of this pass) and leaves it. What their
# values reach goes on the list after them, and may bring more thread
# locals: one more first pass, till none is new. The second pass meets the
# list as the last first pass left it, so its image is the same. A program
# without such a thread local runs its passes as before. Test ctlslate
# (4 targets). Run on ttpc.ff after tls.pl, datasep.pl and par.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
sub replace_fn {
    my ($name, $new) = @_;
    my ($from, $to) = find(\$t, $name);
    substr($t, $from, $to - $from) = $new;
}
my ($from) = find(\$t, 'tlsdefer');
substr($t, $from) =~ /^( *)/;
my $ind = length $1;

# tls_redo: 1 when this first pass met a thread local after the image;
# then the count of first passes run again
once(\$t, "  tls_vars:\n    reserve\n      32784\n", "  tls_vars:\n    reserve\n      32784\n  tls_redo:\n    reserve\n      16\n", 'tls_vars');

replace_fn('tlsdefer', cfn('tlsdefer', 'the global a0, if it is a thread local of the TLS image, put off for tlsplace (then 1); one the image of this pass already holds, left (then 1); else 0', "
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
    li32 32776 t1
    add t1 t0 t1
    ld 0 t1 t1
    beqz D6 t1
    mv s4 a0
    call label_entry
    bnez D5 a0
    D6:
    la tls_vars t0
    ld 0 t0 t1
    li32 4094 t2
    bgeu rel:D7 t2 t1
    slli 3 t1 t2
    add t2 t0 t2
    sd 16 s4 t2
    addi 1 t1 t1
    sd 0 t1 t0
    D5:
    li 1 a0
    leave2
    D8:
    li 0 a0
    leave2
    D7:
    la msg_trees a1
    li msg_trees_len a2
    j die
", $ind));

replace_fn('tlsplace', cfn('tlsplace', 'the TLS image, once (then 1, else 0): __tls_start (aligned to 64), the thread locals put off, those the list holds after the image\'s place, __tls_end; empty without thread locals; one put off after it: the first pass again (tls_redo)', "
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
    call libfind
    beqz T9 a0
    la irelnone a1
    call place
    la tls_vars s4
    li 1 t0
    sd 8 t0 s4
    call libbase
    mv a0 s6
    li32 32768 t1
    add t1 s4 t1
    ld 0 t1 s7
    S1:
    ld 0 s6 t0
    bgeu rel:S9 t0 s7
    slli 3 s7 t1
    add t1 s6 t1
    ld 32 t1 s8
    mv s8 a0
    call istls
    beqz S2 a0
    ld 0 s4 t1
    li32 4094 t2
    bgeu rel:T11 t2 t1
    slli 3 t1 t2
    add t2 s4 t2
    sd 16 s8 t2
    addi 1 t1 t1
    sd 0 t1 s4
    S2:
    addi 1 s7 s7
    j S1
    S9:
    li 0 s5
    T1:
    ld 0 s4 t0
    bgeu rel:T2 t0 s5
    slli 3 s5 t1
    add t1 s4 t1
    ld 16 t1 a0
    call ccg
    addi 1 s5 s5
    j T1
    T2:
    sd 8 zero s4
    sd 0 zero s4
    call tlsalign
    la tls_names a0
    addi 11 a0 a0
    li 9 a1
    call libfind
    beqz T9 a0
    la irelnone a1
    call place
    call tlstcb
    li 1 a0
    leave5
    T7:
    ld 0 s4 t0
    bnez T8 t0
    T9:
    li 0 a0
    leave5
    T8:
    la pass t0
    ld 0 t0 t0
    li 1 t1
    bne rel:T10 t1 t0
    la tls_redo t0
    ld 8 t0 t1
    li 8 t2
    bgeu rel:T10 t2 t1
    li 1 t1
    sd 0 t1 t0
    sd 0 zero s4
    li 0 a0
    leave5
    T10:
    la tls_vars t0
    ld 16 t0 s4
    la msg_tlslate a1
    li msg_tlslate_len a2
    ld NODE_content s4 a3
    lbu NODE_content_len s4 a4
    j die_name
    T11:
    la msg_trees a1
    li msg_trees_len a2
    j die
", $ind));

# compile_page: a first pass that met a thread local after the image runs
# again, its labels placed anew and the C layer's per-pass counts cleared
# (cc does when CC_pass is not this pass: the global labels' count, which
# -j's samples compare), not under compile time's JIT
edit(\$t, 'compile_page',
    "      call\n        run_placed\n      addi\n        1\n        s8\n        s8\n",
    "      call\n        run_placed\n" . asm(6, "
    li 1 t0
    bne rel:TX1 t0 s8
    la ccs t0
    ld CC_jit t0 t0
    bnez TX1 t0
    la tls_redo t0
    ld 0 t0 t1
    beqz TX1 t1
    sd 0 zero t0
    ld 8 t0 t1
    addi 1 t1 t1
    sd 8 t1 t0
    la labels_base t1
    ld 0 t1 t1
    la labels_end t2
    sd 0 t1 t2
    la ccs t0
    sd CC_pass zero t0
    j L1
") . "    TX1:\n      addi\n        1\n        s8\n        s8\n");
save();
