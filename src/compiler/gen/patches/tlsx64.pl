# tlsx64.pl: thread locals in the TLS image on x86_64 too, TLS variant II:
# the thread pointer (fs) points at the thread's TCB, its struct pthread,
# and the image is just below it, so a thread local's offset is from the
# image's end, below 0, as glibc's static TLS and GNU ld have it (tpoff).
# A new constant of every target says which:
#
#   cc_tlsend   1 where a thread local's offset is from __tls_end (x86_64),
#               0 where it is from __tls_start (riscv64, aarch64, arm)
#
# On a target with cc_tlsend, tlsplace puts __tls_end at the image's
# alignment (64: glibc rounds the image's size up to it, and the image
# ends at the thread pointer) and 4 KiB of zeros after it, the TCB of a C
# _start of the program's own (fs points at __tls_end: tpinit, cc_settls),
# where glibc's code finds the thread's struct pthread (THREAD_SELF, at
# fs + 16); tlsaddr takes a thread local's offset from __tls_end, tpinit
# gives cc_settls __tls_end's address. Other targets make the same bytes.
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
# within function $name, the instructions $old (asm form) become $new
sub reasm {
    my ($name, $old, $new) = @_;
    my ($from, $to) = find(\$t, $name);
    my $e = substr($t, $from, $to - $from);
    my ($ind) = grep { my $o = asm($_, $old); () = $e =~ /^\Q$o\E/mg } map { indent_of($name) + $_ } 2, 4, 6, 8;
    defined $ind or die "tlsx64: $name: not found\n";
    once(\$e, asm($ind, $old), asm($ind, $new), $name);
    substr($t, $from, $to - $from) = $e;
}

once(\$t, "      \\x00cc_addtls\\x00\\x00cc_settls\\x00cc_irel\\x00\n", "      \\x00cc_addtls\\x00\\x00cc_settls\\x00cc_irel\\x00cc_tlsend\\x00\n", 'tls_prims');

reasm('tlsaddr', "
    la tls_names a0
    li 11 a1
    call find_fn
", "
    call tlsbase
    call find_fn
");
reasm('tpinit', "
    la tls_names a0
    li 11 a1
    call find_fn
", "
    call tlsbase
    call find_fn
");
reasm('tlsplace', "
    la tls_names a0
    addi 11 a0 a0
    li 9 a1
    call find_fn
    beqz T9 a0
    la irelnone a1
    call place
", "
    call tlsalign
    la tls_names a0
    addi 11 a0 a0
    li 9 a1
    call find_fn
    beqz T9 a0
    la irelnone a1
    call place
    call tlstcb
");

my $ind = indent_of('tpinit');
my $f = '';
$f .= cfn('tlsend', "1 where a thread local's offset is from __tls_end, the target's cc_tlsend (TLS variant II: x86_64); else 0", "
    enter1
    la tls_prims a0
    addi 30 a0 a0
    call tconst
    leave1
", $ind);
$f .= cfn('tlsbase', 'the label a thread local\'s offset is from: a0 its name, a1 its length: __tls_end where cc_tlsend is 1, else __tls_start', "
    enter1
    call tlsend
    mv a0 t0
    la tls_names a0
    li 11 a1
    beqz B8 t0
    addi 11 a0 a0
    li 9 a1
    B8:
    leave1
", $ind);
$f .= cfn('tlsalign', 'before __tls_end, where cc_tlsend is 1: align 64, the image\'s alignment, so that it ends at the thread pointer', "
    enter1
    call tlsend
    beqz Z8 a0
    la irel_words a0
    addi 6 a0 a0
    li 1 a1
    li 64 a2
    li 0 a5
    call prim
    Z8:
    leave1
", $ind);
$f .= cfn('tlstcb', 'after __tls_end, where cc_tlsend is 1: 4 KiB of zeros, the TCB (struct pthread) of a C _start of the program\'s own', "
    enter1
    call tlsend
    beqz Z8 a0
    la irel_words a0
    addi 12 a0 a0
    li 1 a1
    li32 4096 a2
    li 0 a5
    call prim
    Z8:
    leave1
", $ind);
after_fn('tpinit', $f);
save();
