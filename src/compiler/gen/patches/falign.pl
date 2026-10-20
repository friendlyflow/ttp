# falign.pl: every function starts where its target wants instructions:
# before ttpc places a function (a C one, cc; an asm one of the library,
# cc_library; ttpc's own init routine), it
# emits the target's cc_falign: aarch64 and arm align to 4 (A64's and
# A32's instructions are 4 bytes; Thumb's 2), riscv64 to 2 (RVC's), x86_64
# to 1 (any byte), which emits nothing. A function after data
# of an odd size (glibc's asm carries its text: __arm_za_disable's
# message) started at 2 mod 4 on aarch64: SIGILL. Test: progs/calign.ff.
# (Not the asm of a page: run_placed places its block labels too, which a
# function runs on into.)
# The name is align_prims, after tls_prims; falign emits it.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub after_fn { my ($name, $new) = @_; my ($from, $to) = find(\$t, $name); substr($t, $to, 0) = $new }
sub indent_of { my ($from) = find(\$t, $_[0]); substr($t, $from) =~ /^( *)/; length $1 }
# within function $name, each of the instructions $old (asm form, at one
# of the indents in it) becomes $new; $count of them
sub reasm {
    my ($name, $old, $new, $count) = @_;
    my ($from, $to) = find(\$t, $name);
    my $e = substr($t, $from, $to - $from);
    $e =~ /^( *)/ or die;
    my $base = length $1;
    my $n = 0;
    for my $i (map { $base + $_ } 2, 4, 6, 8) {
        my ($o, $w) = (asm($i, $old), asm($i, $new));
        $n += $e =~ s/^\Q$o\E/$w/mg;
    }
    die "falign: $name: $n of the instructions, not $count\n" unless $n == $count;
    substr($t, $from, $to - $from) = $e;
}

after_fn('tls_prims', "  align_prims:\n    ascii\n      \\x00cc_falign\\x00\n");

# a C function, in cc
reasm('cc', "
    mv s4 a0
    la function a1
    call place
", "
    call falign
    mv s4 a0
    la function a1
    call place
", 1);
# the library's asm functions, and ttpc's own init routine
reasm('cc/cc_library', "
    slli 3 s4 t1
    add t1 s5 t1
    ld 32 t1 a0
    la run_placed a1
    call place
", "
    call falign
    slli 3 s4 t1
    add t1 s5 t1
    ld 32 t1 a0
    la run_placed a1
    call place
", 2);
reasm('cc/cc_library', "
    call initnode
    la ifinit a1
    call place
", "
    call falign
    call initnode
    la ifinit a1
    call place
", 1);

my $ind = indent_of('cc/cc_library');
after_fn('cc/cc_library', fn('falign', "
    enter1
    la align_prims a0
    call seq
    leave1
", $ind));
save();
