# fsword.pl: the user's type word fs (2026-10-21, option A): gcc's named
# address space __seg_fs on x86_64, memory at fs + the pointer's value. It
# comes in a type run after the type it qualifies and before the * pointer
# that points at it, in C's order: pthread / fs / * pointer is struct
# pthread __seg_fs *, pthread / * pointer / fs / * pointer is struct
# pthread *__seg_fs *.
#
# A value of a type with fs is its flat address: a cast to a type run
# with fs of a number (a value of an integer type: glibc's THREAD_SELF,
# THREAD_GETMEM and THREAD_SETMEM cast 0 or an offset) adds the thread
# pointer's base, cc_addtls (x86_64: fs's TCB, which points at itself);
# a cast of an address (one already in fs: THREAD_SELF's
# *(struct pthread *__seg_fs *) &...->header.self) keeps it. The type is
# otherwise the type without fs. cc_kw gains fs (KW_fs, 59, after the
# literal suffixes, which the checks for KW_U and on keep apart).
#
#   ptrsuf    takes fs in the * pointer run and notes it (cc_fsrun)
#   tskip     skips it as a * pointer
#   typerun   clears the note first
#   convert   (primary's cast) takes the note of its type run before its
#             operand (whose own casts note theirs), and after it calls
#             fsconv; so does unary's (a cast as a prefix)
#   fsconv    a0 the operand's type: where the note is set and a0 is an
#             integer type, V += the thread pointer (cc_addtls)
#   prefixw   fs is no postfix word; kind: fs is a type word there
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# (T=ttpc.defs.ff: the constant KW_fs)
if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_U:\n    addi\n      54\n      zero\n      a0\n", "  KW_U:\n    addi\n      54\n      zero\n      a0\n  KW_fs:\n    addi\n      59\n      zero\n      a0\n", 'KW_U');
    save();
    exit;
}

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
    defined $ind or die "fsword: $name: not found\n";
    once(\$e, asm($ind, $old), asm($ind, $new), $name);
    substr($t, $from, $to - $from) = $e;
}
# a block (a label and its instructions) at the end of function $name
sub add_block { my ($name, $src) = @_; after_fn($name, asm(indent_of($name) + 2, $src)) }

once(\$t, "ULL\\x00\\x00\n", "ULL\\x00fs\\x00\\x00\n", 'cc_kw');
once(\$t, "  start_node:\n    reserve\n      NODE_size\n", "  start_node:\n    reserve\n      NODE_size\n  cc_fsrun:\n    reserve\n      8\n", 'start_node');

reasm('ptrsuf', "
    li KW_content t0
    bne rel:P9 t0 a0
", "
    li KW_fs t0
    beq rel:PF t0 a0
    li KW_content t0
    bne rel:P9 t0 a0
");
add_block('ptrsuf', "
    PF:
    addi 8 s4 s4
    la cc_fsrun t0
    li 1 t1
    sd 0 t1 t0
    j P1
");
reasm('tskip', "
    li KW_content t0
    bne rel:Z9 t0 a0
", "
    li KW_fs t0
    beq rel:ZF t0 a0
    li KW_content t0
    bne rel:Z9 t0 a0
");
add_block('tskip', "
    ZF:
    addi 8 s4 s4
    j Z4
");
reasm('typerun', "
    enter5
    mv a0 s4
", "
    enter5
    la cc_fsrun t0
    sd 0 zero t0
    mv a0 s4
");
reasm('convert', "
    enter5
    mv a0 s4
", "
    enter5
    la cc_fsrun t0
    ld 0 t0 t1
    sd 0 zero t0
    addi -16 sp sp
    sd 0 t1 sp
    mv a0 s4
");
reasm('convert', "
    call getty
    mv s5 a1
    call fcvt
", "
    call getty
    ld 0 sp a2
    call fsconv
    mv s5 a1
    call fcvt
");
reasm('convert', "
    call close
    leave5
", "
    call close
    addi 16 sp sp
    leave5
");
# unary's cast (UC, a prefix: its operand the next sibling): the note of
# its type run in s8 (free there) before the operand, fsconv after it;
# UP's suffix literals come to UV too, with s8 0
reasm('unary', "
    mv a0 s5
    call next
    li 3 t0
    beq rel:UC t0 s5
", "
    mv a0 s5
    call next
    li 0 s8
    li 3 t0
    beq rel:UC t0 s5
");
reasm('unary', "
    call typerun
    bltz L8 a0
    bne rel:L8 s7 a1
", "
    call typerun
    la cc_fsrun t0
    ld 0 t0 s8
    sd 0 zero t0
    bltz L8 a0
    bne rel:L8 s7 a1
");
reasm('unary', "
    call getty
    mv s6 a1
    call fcvt
", "
    call getty
    mv s8 a2
    call fsconv
    mv s6 a1
    call fcvt
");
reasm('prefixw', "
    li KW_U t0
    blt rel:W0 t0 a0
", "
    li KW_fs t0
    beq rel:W0 t0 a0
    li KW_U t0
    blt rel:W0 t0 a0
");
reasm('kind', "
    li KW_U t0
    bge rel:LK t0 a0
", "
    li KW_fs t0
    beq rel:L2 t0 a0
    li KW_U t0
    bge rel:LK t0 a0
");

after_fn('convert', cfn('fsconv', "a cast's operand of the type a0, its type run with fs where a2 is 1: a number (an integer type) becomes its address in fs, V += the thread pointer (cc_addtls); a0 kept", "
    enter2
    mv a0 s4
    beqz F9 a2
    li32 TY_REC t0
    bgeu rel:F9 t0 s4
    li TY_FLOAT t0
    beq rel:F9 t0 s4
    li TY_DOUBLE t0
    beq rel:F9 t0 s4
    li TY_LDOUBLE t0
    beq rel:F9 t0 s4
    la tls_prims a0
    call seq
    F9:
    mv s4 a0
    leave2
", indent_of('convert')));
save();
