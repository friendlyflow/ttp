# packed.pl: the word packed (the user's choice, 2026-11-12): first under a
# field's name, before its type, the field aligned to 1 (C's packed field
# attribute); right after struct or union, every field of the record, so the
# record aligned to 1 too (C's packed record). An align raises it still.
# glibc's resolv.h has unsigned long long __glibc_extension_index
# __attribute__ ((packed)) in struct __res_state's _u._ext, which csema
# could not write: on arm ttpc aligned it to 8, so struct __res_state was
# 520 bytes aligned to 8 for gcc's 512 aligned to 4, and struct pthread 1280
# for 1248 (found by src/glibc's datacheck).
#   ispacked   a0 a node: 1 if it is the leaf packed
#   pkskip     a0 a field's run (a1 its end, kept): past a packed first
#   recpacked  a0 a record (struct or union): 1 if packed is among the
#              align and packed right after its kind
#   fldalign   a2 the record now (gdalign's 0): 1 where the field or its record is
#              packed, then raised to the field's align
#   fields     skips a packed among the record's first items, a field's run
#              past its packed for typerun, and gives fldalign its record
# Test cpacked (4 targets).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  al_word:\n", "  pk_word:\n    ascii\n      packed\n  al_word:\n", 'pk_word');

{
    my ($fa, $fb) = find(\$t, 'alskip');
    substr($t, $fb, 0) = fn('ispacked', "
    enter1
    mv a0 s4
    lbu NODE_children_len s4 t0
    bnez P9 t0
    lbu NODE_content_len s4 a1
    li 6 t1
    bne rel:P9 t1 a1
    ld NODE_content s4 a0
    la pk_word a2
    li 6 a3
    call streq
    leave1
P9:
    li 0 a0
    leave1
", 6) . fn('pkskip', "
    enter2
    mv a0 s4
    mv a1 s5
    bgeu rel:Q9 s5 s4
    ld 0 s4 a0
    call ispacked
    beqz Q9 a0
    addi 8 s4 s4
Q9:
    mv s4 a0
    mv s5 a1
    leave2
", 6) . fn('recpacked', "
    enter2
    mv a0 s4
    ld NODE_children s4 s5
    lbu NODE_children_len s4 t0
    slli 3 t0 t0
    add t0 s5 s4
    addi 8 s5 s5
R1:
    bgeu rel:R8 s4 s5
    ld 0 s5 a0
    call ispacked
    bnez R9 a0
    mv s5 a0
    mv s4 a1
    call alval
    beqz R8 a0
    addi 8 s5 s5
    j R1
R8:
    li 0 a0
R9:
    leave2
", 6);
}

edit(\$t, 'fldalign', asm(8, "
    enter2
    mv a1 s4
    call talign
    mv a0 s5
    ld NODE_children s4 a0
") => asm(8, "
    enter3
    mv a1 s4
    mv a2 s6
    call talign
    mv a0 s5
    lbu NODE_children_len s4 t1
    beqz F4 t1
    ld NODE_children s4 t0
    ld 0 t0 a0
    call ispacked
    bnez F2 a0
F4:
    beqz F3 s6
    mv s6 a0
    call recpacked
    beqz F3 a0
F2:
    li 1 s5
F3:
    ld NODE_children s4 a0
"), asm(8, "
    add t0 a0 a1
    call alval
") => asm(8, "
    add t0 a0 a1
    call pkskip
    call alval
"), asm(8, "
F1:
    mv s5 a0
    leave2
") => asm(8, "
F1:
    mv s5 a0
    leave3
"));

edit(\$t, 'fields', asm(8, "
L1:
    beqz L8 s7
    mv s8 a0
    addi 8 s8 a1
    call alval
    beqz LA1 a0
    bgeu rel:LA0 a0 s10
    mv a0 s10
") => asm(8, "
L1:
    beqz L8 s7
    mv s8 a0
    addi 8 s8 a1
    call alval
    bnez LA2 a0
    ld 0 s8 a0
    call ispacked
    beqz LA1 a0
    li 1 a0
LA2:
    bgeu rel:LA0 a0 s10
    mv a0 s10
"), asm(8, "
U1:
    beqz U8 s7
    mv s8 a0
    addi 8 s8 a1
    call alval
    beqz UA1 a0
    bgeu rel:UA0 a0 s10
    mv a0 s10
") => asm(8, "
U1:
    beqz U8 s7
    mv s8 a0
    addi 8 s8 a1
    call alval
    bnez UA2 a0
    ld 0 s8 a0
    call ispacked
    beqz UA1 a0
    li 1 a0
UA2:
    bgeu rel:UA0 a0 s10
    mv a0 s10
"), asm(10, "
    add t1 a0 a1
    sd 72 a1 sp
    call typerun
") => asm(10, "
    add t1 a0 a1
    sd 72 a1 sp
    call pkskip
    call typerun
"), asm(10, "
    add t1 a0 a1
    call typerun
") => asm(10, "
    add t1 a0 a1
    call pkskip
    call typerun
"));
# (gdalign's, a global's, with none)
edit(\$t, 'gdalign', asm(8, "
    mv s4 a1
    call fldalign
") => asm(8, "
    mv s4 a1
    li 0 a2
    call fldalign
"));
# (each call of fldalign in fields with its record, s4)
{
    my ($fa, $fb) = find(\$t, 'fields');
    my $f = substr($t, $fa, $fb - $fa);
    (my $g = $f) =~ s/\n( +)call\n +fldalign\n/\n$1mv\n$1  s4\n$1  a2\n$1call\n$1  fldalign\n/g;
    my $n = () = $g =~ /fldalign/g;
    die "packed: fields calls fldalign $n times, not 3\n" unless $n == 3;
    once(\$t, $f, $g, 'fields');
}
save();
