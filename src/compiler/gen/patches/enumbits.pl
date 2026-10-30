# enumbits.pl: a bitfield of an enum's type is unsigned, as gcc has it,
# when none of the enum's constants is negative (gcc's enum is then an
# unsigned int); with a negative one it stays signed (an int). ttpc read
# every enum bitfield as signed: mode / 2 holding 3 read as -1. fields
# types a bitfield's base by enumbits (the type run's last node an enum
# name, enumneg over its constants and items groups). Test: cenumbits.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

my $at = "          sd\n            72\n            a0\n            sp\n          ld\n            0\n            a1\n            a0\n          call\n            constval\n";
edit(\$t, 'cc/fields', $at, asm(10, "call enumbits") . $at);

my ($ff, $ft) = find(\$t, 'cc/fields');
substr($t, $ft, 0) = cfn('enumbits', "a bitfield's base: a0, the type, or unsigned int where it is int and the type run's last node (a1 the one after it, kept) names an enum without a negative constant", "
    enter3
    mv a0 s4
    mv a1 s6
    li TY_INT t0
    bne rel:L9 t0 a0
    ld -8 a1 s5
    lbu NODE_children_len s5 t0
    bnez L9 t0
    ld NODE_content s5 a0
    lbu NODE_content_len s5 a1
    call find_label
    bnez L1 a0
    mv s5 a0
    call libtype
    beqz L9 a0
L1:
    mv a0 s5
    call isdef
    beqz L9 a0
    mv s5 a0
    call defkw
    li KW_enum t0
    bne rel:L9 t0 a0
    mv s5 a0
    call enumneg
    bnez L9 a0
    li TY_U32 s4
L9:
    mv s4 a0
    mv s6 a1
    leave3
", 6) . cfn('enumneg', "1 if a constant of the enum a0 (or of an items group in it) is negative, else 0", "
    enter3
    lbu NODE_children_len a0 s5
    ld NODE_children a0 s4
L1:
    li 0 a0
    beqz L9 s5
    ld 0 s4 s6
    lbu NODE_children_len s6 t0
    beqz L2 t0
    ld NODE_content s6 t1
    lbu NODE_content_len s6 t2
    add t2 t1 t1
    lbu -1 t1 t1
    li CH_colon t3
    beq rel:L3 t3 t1
    mv s6 a0
    call enumneg
    bnez L9 a0
    j L2
L3:
    mv s6 a0
    call enumv
    bltz L8 a0
L2:
    addi 8 s4 s4
    addi -1 s5 s5
    j L1
L8:
    li 1 a0
L9:
    leave3
", 6);
save();
