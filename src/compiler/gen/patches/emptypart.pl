# emptypart.pl: an empty node (content empty, no children; fftext's \e) is
# an empty part, as an empty : is, wherever an item may be empty (the
# user's, 2026-10-30): for's three parts (for / \e / \e / \e / body is
# for (;;)), an empty statement, an empty place of a global's or a local's
# list (zero, or a zero aggregate), an empty : where ttpc asks iscolon.
# Where a leaf is text (an item of a char / * pointer place) it stays the
# text "" (gempty). stmt takes it as an empty statement, forloop's condition
# as none, gval and linit as zero, iscolon as an empty :. Test: cempty.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
sub at_end { my ($name, $text) = @_; my ($f, $to) = find(\$t, $name); substr($t, $to, 0) = $text }

# iscolon: an empty leaf is an empty :
edit(\$t, 'cc/iscolon', "      iscolon:\n        lbu\n          NODE_content_len\n          a0\n          t0\n",
    "      iscolon:\n        lbu\n          NODE_content_len\n          a0\n          t0\n" . asm(8, "beqz L2 t0"));
at_end('cc/iscolon', asm(8, "
L2:
    lbu NODE_children_len a0 t0
    seqz t0 a0
    ret
"));

# stmt: an empty leaf is an empty statement (as a comment, L15)
edit(\$t, 'cc/stmt', "        L1:\n          mv\n            s4\n            a0\n          call\n            is_fn\n",
    "        L1:\n" . asm(10, "
    lbu NODE_content_len s4 t0
    lbu NODE_children_len s4 t1
    or t1 t0 t0
    beqz L15 t0
") . "          mv\n            s4\n            a0\n          call\n            is_fn\n");

# forloop: an empty condition (the leaf has no children here)
edit(\$t, 'cc/forloop', "        lbu\n          NODE_content_len\n          a0\n          t0\n        li\n          1\n          t1\n        bne\n          rel\n            L1\n",
    "        lbu\n          NODE_content_len\n          a0\n          t0\n" . asm(8, "beqz LE t0") . "        li\n          1\n          t1\n        bne\n          rel\n            L1\n");
at_end('cc/forloop', asm(8, "
LE:
    call next
    j L2
"));

# gval: an empty leaf not text is a zero item
edit(\$t, 'cc/gval', "        lbu\n          NODE_content_len\n          s5\n          t0\n        li\n          1\n          t1\n        bne\n          rel\n            LZN\n",
    "        lbu\n          NODE_content_len\n          s5\n          t0\n" . asm(8, "beqz LGE t0") . "        li\n          1\n          t1\n        bne\n          rel\n            LZN\n");
at_end('cc/gval', asm(8, "
LGE:
    mv s7 a0
    mv s5 a1
    call gempty
    beqz LZN a0
    li 0 a0
    addi 8 s4 a1
    j L9
"));

# linit: so in a local's list (the place left as the zeroed temporary has it)
edit(\$t, 'cc/linit', "          lbu\n            NODE_content_len\n            a0\n            t0\n          li\n            1\n            t1\n          bne\n            rel\n              LZ1\n",
    "          lbu\n            NODE_content_len\n            a0\n            t0\n" . asm(10, "beqz LLE t0") . "          li\n            1\n            t1\n          bne\n            rel\n              LZ1\n");
edit(\$t, 'cc/linit', "          j\n            L5\n        L3:\n", "          j\n            L5\n" . asm(10, "
LLE:
    call peek
    mv a0 a1
    mv s7 a0
    call gempty
    beqz LZ1 a0
    call next
    j L5
") . "        L3:\n");

my ($gf, $gt) = find(\$t, 'cc/gval');
substr($t, $gt, 0) = cfn('gempty', "1 if the empty leaf a1, an item of a place of type a0, is an empty part (a zero); 0 where it is text, the place a pointer that takes text", "
    enter2
    mv a0 s4
    mv a1 s5
    call isaddr
    beqz L1 a0
    mv s5 a0
    call istext
    seqz a0 a0
    leave2
L1:
    li 1 a0
    leave2
", 6);
save();
