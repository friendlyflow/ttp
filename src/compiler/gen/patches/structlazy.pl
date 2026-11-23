# structlazy.pl: a struct reached by a pointer inside another struct's layout
# waits until its size is wanted (the master's fault 19, 2026-11-23, gawk's
# instruction_block). struct laid a struct out as it made its type, so in
# exp_instruction's layout (a member a pointer to a struct that points to
# instruction_block) instruction_block was laid out while exp_instruction
# was half made, with newtype's 8 as its size: sizeof instruction_block, 8
# + 126 x 40, was 1016, and gawk's pools overlapped. Now struct lays a new
# struct out (tlay) only at depth 0 (sdepth); inside a layout the new struct
# is pending (TY_align 0), tsize and talign lay a pending struct out when its
# size or alignment is wanted (a member or an array element by value), and
# the struct at depth 0 lays out the pending ones its layout left (tpend),
# as C needs a struct whole only where it is used by value. Test:
# progs/cstructlazy.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

once(\$t, "  text_item:\n    reserve\n      8\n",
    "  text_item:\n    reserve\n      8\n  sdepth:\n    reserve\n      8\n", 'text_item');

my $lay = "          ld\n            TY_base\n            s4\n            a0\n          li\n            0\n            a1\n          li\n            -1\n            a2\n          call\n            fields\n          sd\n            TY_size\n            a0\n            s4\n          sd\n            TY_align\n            a1\n            s4\n          mv\n            s4\n            a0\n        L9:\n";
edit(\$t, 'struct', $lay => asm(10, "
    la sdepth t0
    ld 0 t0 t1
    bnez LTP t1
    mv s4 a0
    call tlay
    mv s4 a0
    call tpend
    mv s4 a0
    j L9
") . asm(8, "
LTP:
    sd TY_align zero s4
    mv s4 a0
") . "        L9:\n");

edit(\$t, 'tsize', "        ld\n          TY_size\n          a0\n          a0\n        ret\n" =>
    asm(8, "
    ld TY_align a0 t0
    beqz LZ t0
    ld TY_size a0 a0
    ret
LZ:
    j tsizep
"));
edit(\$t, 'talign', "        ld\n          TY_align\n          a0\n          a0\n        ret\n" =>
    asm(8, "
    ld TY_align a0 t0
    beqz LZ t0
    mv t0 a0
    ret
LZ:
    j talignp
"));

my ($from, $to) = find(\$t, 'struct');
substr($t, $to, 0) = join '',
  "      comment\n        tlay: lay the struct type a0 out (its size and alignment from its node's fields), one level deeper in sdepth; a0 is the type\n",
  fn('tlay', "
    enter1
    mv a0 s4
    li 8 t0
    sd TY_align t0 s4
    la sdepth t0
    ld 0 t0 t1
    addi 1 t1 t1
    sd 0 t1 t0
    ld TY_base s4 a0
    li 0 a1
    li -1 a2
    call fields
    sd TY_size a0 s4
    sd TY_align a1 s4
    la sdepth t0
    ld 0 t0 t1
    addi -1 t1 t1
    sd 0 t1 t0
    mv s4 a0
    leave1
", 6),
  "      comment\n        tpend: lay out each pending struct type (TY_align 0) after the type a0, those that a layout at depth 0 left and those they leave\n",
  fn('tpend', "
    enter1
    mv a0 s4
P1:
    addi TY_sz s4 s4
    la ccs t0
    ld CC_types t0 t1
    bgeu rel:P9 t1 s4
    ld TY_kind s4 t2
    li TY_STRUCT t3
    bne rel:P1 t3 t2
    ld TY_align s4 t2
    bnez P1 t2
    mv s4 a0
    call tlay
    j P1
P9:
    leave1
", 6),
  "      comment\n        tsizep and talignp: tsize and talign of a type with TY_align 0, a pending struct, which they lay out first\n",
  fn('tsizep', "
    enter1
    mv a0 s4
    ld TY_kind s4 t0
    li TY_STRUCT t1
    bne rel:Z1 t1 t0
    call tlay
Z1:
    ld TY_size s4 a0
    leave1
", 6),
  fn('talignp', "
    enter1
    mv a0 s4
    ld TY_kind s4 t0
    li TY_STRUCT t1
    bne rel:Z1 t1 t0
    call tlay
Z1:
    ld TY_align s4 a0
    leave1
", 6);
save();
