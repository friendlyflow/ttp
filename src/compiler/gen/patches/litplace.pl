# litplace.pl: a compound literal's place of a struct, union or array type
# takes its own type and its items (language.ff.txt), or an expression of
# its type, copied; any other item stops (an array's place stays as it
# was: a text for a char array). litone copied from whatever
# address another item's value was, so outer / 1 / 2 / 3, where outer's
# first place is a struct, compiled with no message and the program
# crashed (copytype read at 1). Now the expression's type must be the
# place's ("cannot compile" names the item). Test caggitem (4 targets:
# a variable and a call as a struct place of a literal).
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

edit(\$t, 'cc/litone', asm(8, "
O1:
    call peek
    call litk
    li -1 t0
    beq rel:O2 t0 a0
") => asm(8, "
O1:
    call peek
    call litk
    li -1 t0
    beq rel:O5 t0 a0
"));
edit(\$t, 'cc/litone', asm(8, "
O4:
    call bad
") => asm(8, "
O4:
    call bad
O5:
    mv s4 a0
    call isarray
    bnez O2 a0
    call peek
    mv a0 s6
    li 1 a0
    call expr
    mv s4 a0
    call wassign
    call getty
    beq rel:O2W s4 a0
    mv s6 a0
    call bad
O2W:
    neg s5 a0
    li R_t0 a1
    call li
    la cc_add_t0_s0 a0
    call seq
    mv s4 a0
    call copytype
    leave5
"));
save();
