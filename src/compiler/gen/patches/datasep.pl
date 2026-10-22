# datasep.pl: a program's writable globals apart from its code. A global
# of a program the frame lays out (not compile time's JIT) is placed
# where it is reached, between the functions, so its page holds code too:
# under qemu-user each write to such a page throws its translated code
# away (a loop that writes a global ran 2000 times slower). Now such a
# global, neither of a section nor a thread local, is put off (datadefer,
# into data_vars) and at the end of the library's list (cc_library's L9,
# after the sections and the TLS image) dataplace places all those put off
# together, from the next page (4096), and the code placed after them
# (reached from their initializers) starts on a page of its own again
# (falign, data_state's open flag). Each such round remembers in the first
# pass where in the list it was placed (data_at, 1 + the list's index; 0
# not yet), and the second pass's loop stops there (databound), as
# secpass.pl does for the sections. Past 16383 globals in a round, or 255
# rounds, a global is placed where it is reached, as before. The frame's
# one PT_LOAD (RWX) stays. Run on ttpc.ff after secpass.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my $c = ' ' x ($ind + 2) . "comment\n" . ' ' x ($ind + 4) . "$text\n";
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}

# data_vars: the count, then the globals put off; data_state: placing,
# open (code placed next starts a page), the round
once(\$t, "  tls_vars:\n    reserve\n      32784\n",
    "  tls_vars:\n    reserve\n      32784\n  data_vars:\n    reserve\n      131080\n  data_state:\n    reserve\n      24\n  data_at:\n    reserve\n      2048\n", 'tls_vars');

# compile_page: once per program, before its passes
my $frame = "    call\n      cc_frame\n";
edit(\$t, 'compile_page', $frame, $frame . asm(4, "
    la data_at t0
    li 256 t1
    DR1:
    sd 0 zero t0
    addi 8 t0 t0
    addi -1 t1 t1
    bnez DR1 t1
"));

# compile_page: each pass, none put off yet
my $secv = "      la\n        sec_vars\n        t0\n      sd\n        0\n        zero\n        t0\n";
edit(\$t, 'compile_page', $secv, $secv . asm(6, "
    la data_vars t0
    sd 0 zero t0
    la data_state t0
    sd 0 zero t0
    sd 8 zero t0
    sd 16 zero t0
"));

# cc: a writable global is put off
my $tlsd = "      call\n        tlsdefer\n      bnez\n        L8\n        a0\n";
edit(\$t, 'cc', $tlsd, $tlsd . asm(6, "
    mv s4 a0
    call datadefer
    bnez L8 a0
"));

# cc_library: the loop stops where a round of them waits; they are placed
# after the sections and the TLS image
edit(\$t, 'cc/cc_library',
    "          call\n            secbound\n",
    "          call\n            secbound\n          call\n            databound\n",
    "          call\n            tlsplace\n          bnez\n            L5\n            a0\n",
    "          call\n            tlsplace\n          bnez\n            L5\n            a0\n" . asm(10, "
    mv s4 a0
    call dataplace
    bnez L5 a0
"));

# falign: code after a round of globals starts a page
edit(\$t, 'cc/falign',
    "        enter1\n",
    "        enter1\n" . asm(8, "
    la ccs t0
    ld CC_jit t0 t0
    bnez F1 t0
    la data_state t0
    ld 8 t0 t1
    beqz F1 t1
    sd 8 zero t0
    call pagepad
    F1:
"));

my ($pf, $pt) = find(\$t, 'cc/tlsplace');
substr($t, $pt, 0) = cfn('datadefer', "1 if the global a0 is put off for dataplace (a program the frame lays out, while none is placed: not of a section, not a thread local, its round not full); else 0", "
    enter1
    mv a0 s4
    la ccs t0
    ld CC_jit t0 t0
    bnez D8 t0
    la data_state t0
    ld 0 t0 t1
    bnez D8 t1
    ld 16 t0 t1
    li 255 t2
    bgeu rel:D8 t2 t1
    la sec_placing t0
    ld 0 t0 t0
    bnez D8 t0
    la tls_vars t0
    ld 8 t0 t0
    bnez D8 t0
    call libbase
    ld 8 a0 t0
    beqz D8 t0
    la data_vars t0
    ld 0 t0 t1
    li32 16383 t2
    bgeu rel:D8 t2 t1
    addi 1 t1 t1
    sd 0 t1 t0
    slli 3 t1 t1
    add t1 t0 t1
    sd 0 s4 t1
    li 1 a0
    leave1
    D8:
    li 0 a0
    leave1
", 6) . cfn('pagepad', "skips to the next page (4096)", "
    la cur_pc t0
    ld 0 t0 t0
    neg t0 a0
    li32 4095 t1
    and t1 a0 a0
    j pad
", 6) . cfn('databound', "a0, or less: the place in the library's list where the first pass placed the round of globals put off not placed yet", "
    la data_state t1
    ld 16 t1 t1
    li 255 t2
    bgeu rel:B9 t2 t1
    la data_at t2
    slli 3 t1 t1
    add t1 t2 t2
    ld 0 t2 t3
    beqz B9 t3
    addi -1 t3 t3
    bgeu rel:B9 a0 t3
    mv t3 a0
    B9:
    ret
", 6) . cfn('dataplace', "the globals put off, if any (then 1, else 0), at a0, the library's place, or where the first pass placed them: from the next page, then code from the next page again", "
    enter3
    mv a0 s6
    la data_vars s4
    ld 0 s4 t0
    beqz X9 t0
    la data_state t0
    ld 16 t0 t1
    la data_at t2
    slli 3 t1 t1
    add t1 t2 t2
    ld 0 t2 t3
    beqz X1 t3
    addi -1 t3 t3
    bltu rel:X9 t3 s6
    j X2
    X1:
    addi 1 s6 t3
    sd 0 t3 t2
    X2:
    call pagepad
    la data_state t0
    li 1 t1
    sd 0 t1 t0
    li 0 s5
    X3:
    ld 0 s4 t0
    bgeu rel:X4 t0 s5
    addi 1 s5 t1
    slli 3 t1 t1
    add t1 s4 t1
    ld 0 t1 a0
    call cc
    addi 1 s5 s5
    j X3
    X4:
    sd 0 zero s4
    la data_state t0
    sd 0 zero t0
    li 1 t1
    sd 8 t1 t0
    ld 16 t0 t1
    addi 1 t1 t1
    sd 16 t1 t0
    li 1 a0
    leave3
    X9:
    li 0 a0
    leave3
", 6);
save();
