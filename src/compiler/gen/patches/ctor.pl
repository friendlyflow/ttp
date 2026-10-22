# ctor.pl: constructor and destructor (the user's choice, 2026-10-21): the
# first node under a function, before its type, with its priority (0 to
# 65535) under it or none,
#
#   init:
#     constructor
#       101
#     void
#     ...
#
# C's __attribute__ ((constructor (101))). ttpc lays the addresses of the
# constructors out between __init_array_start and __init_array_end, those
# of the destructors between __fini_array_start and __fini_array_end, by
# priority, lower first, those without one last, as ld does; the start code
# walks them (glibc's call_init, its exit). Once per program, before its
# passes (ctscan, from the first cc of the program: compile_page sees none
# of cc's helpers), each definition of the program's page (and one level of
# its groups) and of the library's pages (syms) that has one is noted
# (ct_tab: the definition, its priority, 0 constructor or 1 destructor, 1
# of the program) and the word taken off it, so that the rest of ttpc sees
# a plain function; the library's ones are put on the list each pass
# (ctroots), so every one is compiled. The four bounds are names ttpc
# makes itself (cfind, before any other definition, so before glibc's weak
# declarations of them): each a global of no bytes, an array of the type
# glibc declares it with (its weak / array / type), else of void *
# pointer, with 0 elements (ctbound; glibc's own node, which every lookup
# finds, made so in ctscan, never on the list); at the end of the library, before the
# sections, once a pass, where there is any constructor or bound (ctplace),
# each bound is placed as a label, the addresses as words between. With
# ctordefs in ttpc.defs.ff (KW_constructor 59, KW_destructor 60, after the suffixes U ... ULL): run on
# ttpc.ff after emptyitem.pl, then with T=ttpc.defs.ff. Test: cctor.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

if ($t =~ /^ttpc:\n/m) {
    once(\$t, "  KW_U:\n    addi\n      54\n      zero\n      a0\n",
        "  KW_U:\n    addi\n      54\n      zero\n      a0\n  KW_constructor:\n    addi\n      59\n      zero\n      a0\n  KW_destructor:\n    addi\n      60\n      zero\n      a0\n", 'KW_U');
    save();
    exit;
}

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# the words, after the suffixes; the bounds' names and the words of their nodes
once(\$t, "section\\x00U\\x00L\\x00UL\\x00LL\\x00ULL\\x00\\x00\n", "section\\x00U\\x00L\\x00UL\\x00LL\\x00ULL\\x00constructor\\x00destructor\\x00\\x00\n", 'cc_kw');
once(\$t, "\n  gen_words:\n", "\n  ct_words:\n    ascii\n      __init_array_start__init_array_end__fini_array_start__fini_array_endarrayvoid* pointer0\n  gen_words:\n", 'gen_words');
once(\$t, "  text_item:\n    reserve\n      8\n", "  text_item:\n    reserve\n      8\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
    [ct_n => 8], [ct_scanned => 8], [ct_tab => 8192], [ct_used => 8], [ct_placed => 8], [ct_built => 32], [ct_bptr => 32], [ct_bnodes => 256], [ct_bkids => 32],
    [ct_anodes => 256], [ct_akids => 320], [ct_void => 64], [ct_ptr => 64], [ct_zero => 64], [ct_buf => 8]), 'text_item');

# cfind: a bound is ttpc's, before any definition of it
edit(\$t, 'cc/cfind', "        enter1\n        mv\n          a2\n          s4\n", "        enter1\n        mv\n          a2\n          s4\n" . asm(8, "
    li 16 t0
    beq rel:CQ1 t0 a1
    li 18 t0
    bne rel:CQ9 t0 a1
CQ1:
    addi -16 sp sp
    sd 0 a0 sp
    sd 8 a1 sp
    call ctname
    bltz CQ8 a0
    call ctbound
    addi 16 sp sp
    leave1
CQ8:
    ld 0 sp a0
    ld 8 sp a1
    addi 16 sp sp
    mv s4 a2
CQ9:
    mv s4 a2
"));

# compile_page: once per program, before its passes, the constructors;
# each pass, none placed yet
edit(\$t, 'compile_page', "      bnez\n        SR1\n        t1\n", "      bnez\n        SR1\n        t1\n    la\n      ct_scanned\n      t0\n    sd\n      0\n      zero\n      t0\n");
# cc: (compile_page cannot call into cc's helpers) the first definition of
# a program scans for them, before it is compiled
once(\$t, "    L21:\n    enter2\n    mv\n      a0\n      s4\n", "    L21:\n    enter2\n    mv\n      a0\n      s4\n" . asm(4, "
    la ct_scanned t0
    ld 0 t0 t1
    bnez CS1 t1
    li 1 t1
    sd 0 t1 t0
    call ctscan
CS1:
    mv s4 a0
"), 'cc');
my $sv = "      la\n        sec_vars\n        t0\n      sd\n        0\n        zero\n        t0\n";
edit(\$t, 'compile_page', $sv, $sv . "      la\n        ct_placed\n        t0\n      sd\n        0\n        zero\n        t0\n");

# startlib: the library's constructors are on the list
edit(\$t, 'cc/startlib', "        call\n          cfind\n        leave1\n", "        call\n          cfind\n        call\n          ctroots\n        leave1\n");

# libadd: a bound is placed by ctplace, never from the list
edit(\$t, 'cc/libadd', "        enter2\n        mv\n          a0\n          s4\n", "        enter2\n        mv\n          a0\n          s4\n" . asm(8, "
    la ct_bptr t0
    li 4 t1
LB1:
    ld 0 t0 t2
    beq rel:L9 t2 s4
    addi 8 t0 t0
    addi -1 t1 t1
    bnez LB1 t1
"));

# cc_library: the arrays, before the sections
edit(\$t, 'cc/cc_library', "        L9:\n          mv\n            s4\n            a0\n          call\n            secplace\n",
    "        L9:\n          call\n            ctplace\n          mv\n            s4\n            a0\n          call\n            secplace\n");

my $fns = cfn('ctword', "the name of bound a0 (0 __init_array_start, 1 its end, 2 __fini_array_start, 3 its end): a0 a1", "
    andi 1 a0 t0
    srli 1 a0 t1
    la ct_words t2
    li 34 t3
    mul t3 t1 t3
    add t3 t2 t2
    li 18 a1
    beqz CW1 t0
    addi 18 t2 t2
    li 16 a1
CW1:
    mv t2 a0
    ret
", 6)
. cfn('ctname', "which bound the name a0 a1 is (0 to 3), else -1", "
    enter3
    mv a0 s4
    mv a1 s5
    li 0 s6
C1:
    li 4 t0
    bgeu rel:C8 t0 s6
    mv s6 a0
    call ctword
    mv a0 a2
    mv a1 a3
    mv s4 a0
    mv s5 a1
    call streq
    bnez C9 a0
    addi 1 s6 s6
    j C1
C8:
    li -1 a0
    leave3
C9:
    mv s6 a0
    leave3
", 6)
. cfn('ctbound', "the node of bound a0, made the first time: glibc's weak / array / type... of the name made name / (array / type... / 0), else a node of ttpc's, of void * pointer", "
    enter8
    mv a0 s4
    la ct_built t1
    slli 3 s4 t0
    add t0 t1 s6
    ld 0 s6 t0
    bnez B9 t0
    li 1 t0
    sd 0 t0 s6
    la ct_anodes s7
    slli 6 s4 t0
    add t0 s7 s7
    la ct_akids s8
    li 80 t0
    mul t0 s4 t0
    add t0 s8 s8
    la ct_words t0
    addi 68 t0 t0
    sd NODE_content t0 s7
    li 5 t0
    sb NODE_content_len t0 s7
    sd NODE_children s8 s7
    li 0 s9
    mv s4 a0
    call ctword
    call find_fn
    beqz B5 a0
    mv a0 s10
    lbu NODE_children_len s10 t0
    li 2 t1
    bne rel:B5 t1 t0
    ld NODE_children s10 t0
    ld 0 t0 a0
    call kwof
    li KW_weak t0
    bne rel:B5 t0 a0
    ld NODE_children s10 t0
    ld 8 t0 s11
    mv s11 a0
    call kwof
    li KW_array t0
    bne rel:B5 t0 a0
    lbu NODE_children_len s11 t0
    beqz B5 t0
    li 10 t1
    bgeu rel:B5 t1 t0
    mv s10 s5
    ld NODE_children s11 t1
B3:
    ld 0 t1 t2
    slli 3 s9 t3
    add t3 s8 t3
    sd 0 t2 t3
    addi 1 s9 s9
    addi 8 t1 t1
    addi -1 t0 t0
    bnez B3 t0
    j B6
B5:
    la ct_bnodes s5
    slli 6 s4 t0
    add t0 s5 s5
    mv s4 a0
    call ctword
    sd NODE_content a0 s5
    sb NODE_content_len a1 s5
    la ct_words t3
    la ct_void t2
    addi 73 t3 t4
    sd NODE_content t4 t2
    li 4 t4
    sb NODE_content_len t4 t2
    sb NODE_children_len zero t2
    sd 0 t2 s8
    la ct_ptr t2
    addi 77 t3 t4
    sd NODE_content t4 t2
    li 9 t4
    sb NODE_content_len t4 t2
    sb NODE_children_len zero t2
    sd 8 t2 s8
    li 2 s9
B6:
    la ct_words t3
    la ct_zero t2
    addi 86 t3 t4
    sd NODE_content t4 t2
    li 1 t4
    sb NODE_content_len t4 t2
    sb NODE_children_len zero t2
    slli 3 s9 t3
    add t3 s8 t3
    sd 0 t2 t3
    addi 1 s9 s9
    sb NODE_children_len s9 s7
    li 1 t0
    sb NODE_children_len t0 s5
    la ct_bkids t1
    slli 3 s4 t2
    add t2 t1 t1
    sd 0 s7 t1
    sd NODE_children t1 s5
    la ct_bptr t1
    slli 3 s4 t2
    add t2 t1 t1
    sd 0 s5 t1
B9:
    la ct_used t0
    li 1 t1
    sd 0 t1 t0
    la ct_bptr t1
    slli 3 s4 t2
    add t2 t1 t1
    ld 0 t1 a0
    leave8
", 6)
. cfn('ctone', "the definition a0 (a1: 1 of the program's page): noted where its first node is constructor or destructor, and that node taken off it", "
    enter3
    mv a0 s4
    mv a1 s5
    lbu NODE_children_len s4 t0
    li 2 t1
    bltu rel:O9 t1 t0
    ld NODE_children s4 t0
    ld 0 t0 a0
    call kwof
    li KW_constructor t0
    li 0 s6
    beq rel:O2 t0 a0
    li KW_destructor t0
    li 1 s6
    bne rel:O9 t0 a0
O2:
    la ct_n t0
    ld 0 t0 t1
    li 256 t2
    bgeu rel:O8 t2 t1
    la ct_tab t2
    slli 5 t1 t3
    add t3 t2 t2
    addi 1 t1 t1
    sd 0 t1 t0
    sd 0 s4 t2
    sd 16 s6 t2
    sd 24 s5 t2
    li32 65536 t3
    sd 8 t3 t2
    ld NODE_children s4 t0
    ld 0 t0 t0
    lbu NODE_children_len t0 t1
    beqz O3 t1
    addi -16 sp sp
    sd 0 t2 sp
    ld NODE_children t0 t1
    ld 0 t1 t1
    ld NODE_content t1 a0
    lbu NODE_content_len t1 a1
    call parse_num
    ld 0 sp t2
    addi 16 sp sp
    beqz O8 a1
    sd 8 a0 t2
O3:
    ld NODE_children s4 t0
    addi 8 t0 t0
    sd NODE_children t0 s4
    lbu NODE_children_len s4 t0
    addi -1 t0 t0
    sb NODE_children_len t0 s4
O9:
    leave3
O8:
    mv s4 a0
    call bad
", 6)
. cfn('ctscan', "the constructors and destructors of the program's page (and one level under it: kind stops at asm) and of the library's pages, once per program", "
    enter8
    la ct_n t0
    sd 0 zero t0
    la ct_used t0
    sd 0 zero t0
    la ct_built t0
    sd 0 zero t0
    sd 8 zero t0
    sd 16 zero t0
    sd 24 zero t0
    la ct_bptr t0
    sd 0 zero t0
    sd 8 zero t0
    sd 16 zero t0
    sd 24 zero t0
    la sec_prog t0
    ld 0 t0 s4
    beqz S5 s4
    lbu NODE_children_len s4 s5
    ld NODE_children s4 s6
S1:
    beqz S5 s5
    ld 0 s6 s7
    mv s7 a0
    li 1 a1
    call ctone
    lbu NODE_children_len s7 s8
    ld NODE_children s7 s9
S2:
    beqz S4 s8
    ld 0 s9 a0
    li 1 a1
    call ctone
    addi 8 s9 s9
    addi -1 s8 s8
    j S2
S4:
    addi 8 s6 s6
    addi -1 s5 s5
    j S1
S5:
    la syms s4
    la syms_end t0
    ld 0 t0 s5
S6:
    bgeu rel:S9 s5 s4
    ld 0 s4 a0
    li 0 a1
    call ctone
    addi 8 s4 s4
    j S6
S9:
    li 0 s4
S10:
    li 4 t0
    bgeu rel:S12 t0 s4
    mv s4 a0
    call ctword
    call find_fn
    beqz S11 a0
    mv s4 a0
    call ctbound
S11:
    addi 1 s4 s4
    j S10
S12:
    leave8
", 6)
. cfn('ctroots', "the library's constructors and destructors on the list", "
    enter3
    la ct_n t0
    ld 0 t0 s4
    la ct_tab s5
R1:
    beqz R9 s4
    ld 24 s5 t0
    bnez R2 t0
    ld 0 s5 a0
    call libadd
R2:
    addi 32 s5 s5
    addi -1 s4 s4
    j R1
R9:
    leave3
", 6)
. cfn('ctnone', "place's runner for a bound: nothing, its label only", "
    ret
", 6)
. cfn('ctplace', "once a pass, where there is a constructor, a destructor or a bound: the bounds as labels, the addresses as words between them, lower priority first", "
    enter8
    la ct_placed t0
    ld 0 t0 t1
    bnez P9 t1
    la ct_n t0
    ld 0 t0 t1
    la ct_used t2
    ld 0 t2 t2
    or t2 t1 t1
    beqz P9 t1
    la ct_placed t0
    li 1 t1
    sd 0 t1 t0
    la targ_word t0
    ld 0 t0 s10
    la cur_pc t0
    ld 0 t0 t0
    neg t0 a0
    addi -1 s10 t1
    and t1 a0 a0
    call pad
    li 0 s4
P1:
    li 2 t0
    bgeu rel:P9 t0 s4
    slli 1 s4 a0
    call ctbound
    la ctnone a1
    call place
    li -1 s5
P2:
    li 1 s6
    slli 40 s6 s6
    la ct_n t0
    ld 0 t0 t1
    la ct_tab t2
P3:
    beqz P4 t1
    ld 16 t2 t3
    bne rel:P31 t3 s4
    ld 8 t2 t3
    bge rel:P31 t3 s5
    bge rel:P31 s6 t3
    mv t3 s6
P31:
    addi 32 t2 t2
    addi -1 t1 t1
    j P3
P4:
    li 1 t0
    slli 40 t0 t0
    beq rel:P8 t0 s6
    la ct_n t0
    ld 0 t0 s7
    la ct_tab s8
P5:
    beqz P7 s7
    ld 16 s8 t0
    bne rel:P6 t0 s4
    ld 8 s8 t0
    bne rel:P6 t0 s6
    ld 0 s8 a0
    call label_addr
    la ct_buf t0
    sd 0 a0 t0
    la ct_buf a0
    mv s10 a1
    call emit_raw
P6:
    addi 32 s8 s8
    addi -1 s7 s7
    j P5
P7:
    mv s6 s5
    j P2
P8:
    slli 1 s4 a0
    addi 1 a0 a0
    call ctbound
    la ctnone a1
    call place
    addi 1 s4 s4
    j P1
P9:
    leave8
", 6);
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $fns;
save();
