# stexpr.pl: a : that holds a declaration among its children is a statement
# expression (GNU C's ({ T t = q; ...; t; }), csema's : / t: ... / t), never a
# struct's braces: clself (decl's one item, a : alone that is no compound
# literal of the type: its first field's braces, selfcl.pl) took it for
# braces, so struct pt d = ({ struct pt t = q; t.x += 10; t; }) put the
# group's address in d.x and zeros in y and z. Now clself says no for such
# a : (stexpr), and decl compiles it as an expression and copies it, as an
# assignment did; vgroup keeps its value (valrec.pl). Part of the master's
# fault 14, 2026-11-21. Test: progs/cvalrec.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/clself', "        call\n          cllit\n        seqz\n          a0\n          a0\n" =>
    "        call\n          cllit\n        seqz\n          a0\n          a0\n" . asm(8, "
    beqz D9 a0
    mv s4 a0
    call stexpr
    seqz a0 a0
"));
{
    my ($from, $to) = find(\$t, 'cc/clself');
    my $f = fn('stexpr', "
    enter3
    call flatkids
    mv a0 s4
    mv a1 s5
    li 0 s6
E1:
    bgeu rel:E9 s5 s4
    ld 0 s4 t0
    lbu NODE_children_len t0 t1
    beqz E2 t1
    lbu NODE_content_len t0 t1
    beqz E2 t1
    ld NODE_content t0 t2
    add t1 t2 t2
    lbu -1 t2 t2
    li CH_colon t3
    bne rel:E2 t3 t2
    li 1 s6
    j E9
E2:
    addi 8 s4 s4
    j E1
E9:
    mv s6 a0
    leave3
", 6);
    $f =~ s/^(.*\n)/$1        comment\n          1 when the : a0 holds a declaration (a child x: with children): a statement expression, no braces\n/;
    substr($t, $to, 0) = $f;
}
save();
