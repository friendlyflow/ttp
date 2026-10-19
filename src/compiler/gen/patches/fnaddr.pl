# fnaddr.pl: the address of a C function is a function pointer, as C's &f
# is, so that it can be called where it stands: glibc's backtrace calls
# ((void) x, &_Unwind_Backtrace) (helper, &arg), in ff a call through a
# value, : / : / cast: void x / address _Unwind_Backtrace / . / args. addr
# gave a function the type of an address of nothing; now its type is a
# function type made of its definition (TY_FUNC, the definition its node),
# and a call through such a pointer takes its result's type from the
# definition's leading type words, where a named function type (binary: /
# function / long / ...) has the word function first. Run on ttpc.ff.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# addr: a C function's definition (kind 1) is its type, at L13 where a
# global's is its dtype
edit(\$t, 'cc/addr',
    "        L13:\n          mv\n            s5\n            a0\n          call\n            dtype\n",
    asm(8, "
    L13:
    mv s5 a0
    call kind
    li 1 t0
    bne rel:L14 t0 a0
    li TY_FUNC a0
    mv s5 a1
    li 0 a2
    call newtype
    call setty
    j L9
    L14:
    mv s5 a0
    call dtype
"));

# index: a call through a function pointer skips the word function of a
# named function type, not the first type word of a definition
my $skip = "          add\n            t1\n            a0\n            a1\n          addi\n            8\n            a0\n            a0\n          call\n            typerun\n";
my $c = () = $t =~ /\Q$skip\E/g;
die "fnaddr: the result type is read $c times, not 2\n" unless $c == 2;
my $n = 0;
$t =~ s/\Q$skip\E/"          add\n            t1\n            a0\n            a1\n" . asm(10, "
    addi -16 sp sp
    sd 0 a0 sp
    sd 8 a1 sp
    ld 0 a0 a0
    call kwof
    mv a0 t2
    ld 0 sp a0
    ld 8 sp a1
    addi 16 sp sp
    li KW_function t0
    bne rel:FN" . ++$n . " t0 t2
    addi 8 a0 a0
    FN$n:
") . "          call\n            typerun\n"/ge;
save();
