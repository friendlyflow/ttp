# gthumb.pl: a global's item that is the address of a Thumb function (arm:
# an asm function of t. instructions, glibc's strlen and strcmp) is its
# label + 1, as gaddr's code has it (isthumb) and as ld writes a Thumb
# symbol's address: a call through it (blx) runs Thumb. gval took the
# label alone, so string's test-strlen called strlen's Thumb code as ARM
# through its impls table (SIGILL; test-strcmp's SIGSEGV). Now gval's
# label_addr of a definition (an item name & address, a name, weak / name
# & address) adds isthumb of it; gpath's (a data path) stays. 0 on every
# other target: no t. instructions there. Test: cthumbitem (arm).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

my ($from, $to) = find(\$t, 'cc/gval');
my $g = substr($t, $from, $to - $from);
my ($head, $tail) = split /^(?=        gpath:\n)/m, $g, 2;
defined $tail or die "gthumb: no gpath in gval\n";
my $old = "          call\n            label_addr\n";
my $new = asm(10, "
addi -16 sp sp
sd 0 a0 sp
call label_addr
sd 8 a0 sp
ld 0 sp a0
call isthumb
ld 8 sp a1
addi 16 sp sp
add a1 a0 a0
");
my $n = () = $head =~ /\Q$old\E/g;
$n == 4 or die "gthumb: $n label_addr calls before gpath, not 4\n";
$head =~ s/\Q$old\E/$new/g;
substr($t, $from, $to - $from) = $head . $tail;
save();
