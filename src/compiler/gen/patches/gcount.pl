# gcount.pl: an array whose count is a global variable is a variable-length
# array, as C has it (int buf[n] of a global n): typerun took the name
# for a constant (constval: the global's address), so the array's size,
# and the code after it, moved between the passes ("label moved"). Now
# typerun fails on such a count (gcount: the name a global, kind 2), as
# it does on a local's, and decl takes the VLA path (W4), which works the
# count out where the array is declared. c2ff wrote such a count in a :
# for ttpc; it needs no longer. Test: cvlaglob.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

my $at = "          call\n            vfind\n          bnez\n            TV\n            a0\n";
edit(\$t, 'cc/typerun', $at, $at . asm(10, "
    ld -8 s8 a0
    call gcount
    bnez TV a0
"));
my ($f, $to) = find(\$t, 'cc/typerun');
substr($t, $to, 0) = cfn('gcount', "1 if the leaf a0, an array's count, names a global variable (a VLA's count), else 0", "
    enter1
    lbu NODE_content_len a0 a1
    ld NODE_content a0 a0
    call find_label
    beqz L9 a0
    call kind
    addi -2 a0 a0
    seqz a0 a0
L9:
    leave1
", 6);
save();
