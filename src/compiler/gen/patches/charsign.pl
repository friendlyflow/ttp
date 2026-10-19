# charsign.pl: C's char is signed or unsigned as the target's ABI says:
# signed on x86_64, unsigned on riscv64, aarch64 and arm. The type word
# char was u8 everywhere (code 17); now its code is the target's cc_char
# (a constant of its c: group; 17 where it has none), 65 for a signed
# char: one byte (code & 15), signed (no 16), not floating (no 32), and
# not i8 (1), so that a text still fills an array of char and is what an
# address char leaf is. ttpc reads cc_char where it reads cc_word, into
# targ_char; tyname gives it for char; a string literal is an address of
# it; the checks for a text take both char codes (u8 stays one, as before).
# Run on ttpc.ff, then (T=ttpc.defs.ff) on its definitions.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;
if ($t =~ /^c layer:\n/m) {
    once(\$t, "  TY_CHAR:\n    addi\n      17\n      zero\n      a0\n",
        "  TY_CHAR:\n    addi\n      17\n      zero\n      a0\n  TY_SCHAR:\n    addi\n      65\n      zero\n      a0\n", 'TY_CHAR');
    save();
    exit;
}

# cc_names: cc_char after cc_tls, at the end
my $names = 'cc_li_pos\x00cc_li_neg\x00cc_li_big\x00cc_arg\x00cc_sysarg\x00cc_v\x00cc_l\x00cc_x\x00cc_slot\x00cc_fixed\x00cc_word\x00cc_argoff\x00cc_entryoff\x00cc_tls\x00';
(my $plain = $names) =~ s/\\x00/\0/g;
my $off = length $plain;
once(\$t, "      $names\n", "      ${names}cc_char\\x00\n", 'cc_names');

# targ_char, after targ_word
$t =~ /^( *)targ_word:\n\1  dword\n\1    8\n/m or die "charsign: no targ_word\n";
my $i = $1;
once(\$t, "${i}targ_word:\n$i  dword\n$i    8\n", "${i}targ_word:\n$i  dword\n$i    8\n${i}targ_char:\n$i  dword\n$i    17\n", 'targ_word');

# read cc_char where cc_word is read: L10 stores targ_word, then cc_char
my $store = "        L10:\n          la\n            targ_word\n            t1\n          sd\n            0\n            t0\n            t1\n";
my $c = () = $t =~ /\Q$store\E/g;
die "charsign: the store of targ_word is there $c times\n" unless $c == 1;
$t =~ s/\Q$store\E/$store . asm(10, "
    la cc_names a0
    addi $off a0 a0
    li 7 a1
    call find_fn
    li TY_CHAR t0
    beqz L20 a0
    la cc_names a0
    addi $off a0 a0
    call tconst
    mv a0 t0
    L20:
    la targ_char t1
    sd 0 t0 t1
")/e;

# tyname: char (index 0 of cc_tynames) is targ_char
edit(\$t, 'cc/tyname',
    "        L3:\n          la\n            cc_tycodes\n            t0\n",
    asm(8, "
    L3:
    bnez L5 a0
    la targ_char t0
    ld 0 t0 a0
    j L1
    L5:
    la cc_tycodes t0
"));

# a string literal is an address of char
edit(\$t, 'cc/text',
    "        li\n          TY_CHAR\n          a1\n",
    asm(8, "
    la targ_char a1
    ld 0 a1 a1
"));

# textof: a text for a char, or an address of one, of either code
edit(\$t, 'cc/textof',
    "        li\n          TY_CHAR\n          t0\n        beq\n          rel\n            L3\n          t0\n          s5\n",
    asm(8, "
    li TY_CHAR t0
    beq rel:L3 t0 s5
    li TY_SCHAR t0
    beq rel:L3 t0 s5
"),
    "        li\n          TY_CHAR\n          t0\n        bne\n          rel\n            L1\n          t0\n          a0\n",
    asm(8, "
    li TY_CHAR t0
    beq rel:L20 t0 a0
    li TY_SCHAR t0
    bne rel:L1 t0 a0
    L20:
"));

# dtype: an array of char of either code may be given a text
edit(\$t, 'cc/dtype',
    "        li\n          TY_CHAR\n          t0\n        bne\n          rel\n            L8\n          t0\n          s7\n",
    asm(8, "
    li TY_CHAR t0
    beq rel:L20 t0 s7
    li TY_SCHAR t0
    bne rel:L8 t0 s7
    L20:
"));
save();
