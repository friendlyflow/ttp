# asmalign.pl: an asm function whose first child after asm is align / n
# is placed at a multiple of n (the user's choice, 2026-10-19): s2ff writes
# the alignment glibc's ENTRY gives a function (.p2align 4 or 6), and the
# nops GNU as put inside the function count from that start. The library
# list's placing (cc_library, both places) first runs that align where the
# function goes, so its label is on the boundary; in the body it is then
# nothing. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my ($from, $to) = find(\$t, 'cc/cc_library');
my $body = substr($t, $from, $to - $from);
my $place = "          ld\n            32\n            t1\n            a0\n          la\n            run_placed\n            a1\n          call\n            place\n";
my $c = () = $body =~ /\Q$place\E/g;
die "asmalign: cc_library places $c times, not 2\n" unless $c == 2;
$body =~ s/\Q$place\E/          ld\n            32\n            t1\n            a0\n          call\n            asmalign\n          la\n            run_placed\n            a1\n          call\n            place\n/g;
substr($t, $from, $to - $from) = $body;

my ($at) = find(\$t, 'cc/cc_library');
substr($t, $at, 0) = fn('asmalign', "
    enter2
    mv a0 s4
    lbu NODE_children_len s4 t0
    li 2 t1
    blt rel:A9 t1 t0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call kwof
    li KW_asm t0
    bne rel:A9 t0 a0
    ld NODE_children s4 t0
    ld 8 t0 s5
    mv s5 a0
    la str_align a1
    li 5 a2
    call is_named
    beqz A9 a0
    mv s5 a0
    li 0 a1
    call code_call
    A9:
    mv s4 a0
    leave2
", 6);
save();
