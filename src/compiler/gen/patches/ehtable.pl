# ehtable.pl: exception tables (lane EH): C's cleanup attribute runs in a
# forced unwind (glibc's thread cancellation, _Unwind_ForcedUnwind) as gcc's
# -fexceptions makes it, and the frames are there without -g.
#
# When: a program that has the unwinder (_Unwind_ForcedUnwind,
# _Unwind_RaiseException or _Unwind_Backtrace: found by cfind, once a pass,
# eh_state bit 0) gets the frames of ehframe.pl (.eh_frame, .eh_frame_hdr,
# .ARM.exidx, the program headers in dbgarea's room) with -g or without;
# -g still adds only the debug sections. Where it also has _Unwind_Resume and
# __gcc_personality_v0 (bit 1) a C function with a cleanup gets landing pads
# and an LSDA. A program without the unwinder (progs/c*.ff) has the bytes
# of before, with -g and without; with -g and no cleanup, too. lazy's reach
# takes _Unwind_Resume and __gcc_personality_v0 with _Unwind_ForcedUnwind.
#
# Landing pads: a region is a range of code with the same stack of exit
# actions (scopeexit.pl's se stack, height > 0). It ends at sepush, around
# each seemit (the exit code of a return, break, goto, a block's end is in
# no region), at seclose, at a nested frame; the next starts after. At a
# region's end, unless an LP for the same stack was made already (eh_lpc,
# per height), the LP is compiled there: a jump over it, then sp synced, the
# exception (V, which the unwinder hands over in the first data register) in
# a local of its own, every exit action (seemit 0) and _Unwind_Resume of it,
# a C call. The LP is in no region: _Unwind_Resume's walk goes past the
# frame. Regions are (function, start, end, LP) in eh_cs, merged where one
# follows another with the same LP.
#
# Tables (dbgeh): a function with regions has an LSDA in the room past
# .ARM.exidx: LPStart and TType omitted, the call sites udata4 (fixed sizes,
# so the room is the same in both passes), each 13 bytes with action 0, the
# table's length a 2-byte uleb128. riscv64, x86_64, aarch64: its FDE (56
# bytes) points at a second CIE, "zPLR" (__gcc_personality_v0 pcrel sdata4),
# its augmentation the LSDA's address. arm (EHABI): its .ARM.exidx word is
# the prel31 of an .ARM.extab entry before the LSDA: __gcc_personality_v0's
# prel31, 0x009b8480 (vsp = r11, pop {r11, r14}); arm's .eh_frame stays.
#
# The installing frame: libgcc's uw_install_context writes the landing pad's
# registers where the context of the function that installs (the one that
# calls __builtin_eh_return: _Unwind_Resume, _Unwind_ForcedUnwind,
# _Unwind_RaiseException) says they are saved, and the personality writes
# the exception's registers through the context. A ttpc frame saves only FP
# and the return address, so such a function (found by a scan of its body)
# keeps 16 bytes below FP (eh_rsv: the data registers 0 and 1 at FP-16,
# FP-8; callee-saved registers would go below them) and its FDE says so (on
# riscv64, x86_64, aarch64; arm's EHABI installs the whole register set).
# glibc's __builtin_eh_return (builtins-<target>.ff.txt) takes them from
# there, FP from its saved slot, SP = CFA + offset.
#
# The two passes: the same tree, -g and cfind's answers give the same LPs and
# regions in both; the room is sized from counts only (LSDA functions,
# flagged functions, regions) with fixed-size encodings. With -j a sample
# (par_vars) keeps eh_ncs, eh_kl and eh_kf; eh_cs and dbg_fx are where the
# first pass wrote them, as dbg_fns' entries. Run on ttpc.ff after
# ehframe.pl, ehframerv.pl and scopeexit.pl.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

sub cfn {
    my ($name, $text, $src, $ind) = @_;
    my $f = fn($name, $src, $ind);
    my @l;
    while (length $text > 240) { $text =~ s/^(.{1,240}) //s or die "cfn: $name\n"; push @l, $1 }
    push @l, $text;
    my $c = ' ' x ($ind + 2) . "comment\n" . join('', map { ' ' x ($ind + 4) . "$_\n" } @l);
    $f =~ s/^(.*\n)/$1$c/;
    $f;
}
sub bytes {
    my ($name, $text, @b) = @_;
    push @b, 0 while @b % 8;
    my $s = '';
    while (@b) { my @d = splice @b, 0, 8; $s .= "    dword\n      " . sprintf("0x%016x", unpack 'Q<', pack 'C8', @d) . "\n" }
    "  align\n    8\n  $name:\n    comment\n      $text\n$s";
}

# ---- the variables (bss), after debug.pl's
once(\$t, "  dbg_shs:\n    reserve\n      8192\n",
    "  dbg_shs:\n    reserve\n      8192\n" . join('', map { "  $_->[0]:\n    reserve\n      $_->[1]\n" }
        [eh_state => 8], [eh_rec => 8], [eh_ncs => 8], [eh_kl => 8], [eh_kf => 8], [eh_rs => 8], [eh_rh => 8],
        [eh_inlp => 8], [eh_ro => 8], [eh_fnon => 8], [eh_persn => 8], [eh_sp => 8], [eh_stk => 512], [eh_lpc => 2048],
        [eh_snap => 24], [eh_nodes => 256], [eh_vname => 8], [eh_kids => 8], [eh_callp => 8],
        [eh_cs => 32 * 65536], [dbg_fx => 8 * 65536]), 'dbg_shs');

# ---- -j (par.pl): a sample keeps the counts too; the entries of eh_cs and
# dbg_fx, as dbg_fns', are where the first pass put them
edit(\$t, 'par_vars', asm(4, "
    dword 1
    dword dbg_lines
    dword 0
    dword 8
"), asm(4, "
    dword 1
    dword dbg_lines
    dword 0
    dword 8
    dword 1
    dword eh_ncs
    dword 0
    dword 8
    dword 1
    dword eh_kl
    dword 0
    dword 8
    dword 1
    dword eh_kf
    dword 0
    dword 8
"));

# ---- the names, after scopeexit.pl's words
once(\$t, "\n  cl_word:\n    ascii\n      cleanup\n",
    "\n  cl_word:\n    ascii\n      cleanup\n" . join('', map { "  $_->[0]:\n    ascii\n      $_->[1]\n" }
        [eh_ufn => '_Unwind_ForcedUnwind'], [eh_urx => '_Unwind_RaiseException'], [eh_ubt => '_Unwind_Backtrace'],
        [eh_ures => '_Unwind_Resume'], [eh_pers => '__gcc_personality_v0'], [eh_ehr => '__builtin_eh_return']), 'cl_word');

# ---- each pass starts with none
edit(\$t, 'compile_page', asm(6, "
    la dbg_regs t0
    sd 0 zero t0
"), asm(6, "
    la dbg_regs t0
    sd 0 zero t0
    li -1 t1
    la eh_state t0
    sd 0 t1 t0
    la eh_ro t0
    sd 0 zero t0
    la eh_rec t0
    sd 0 zero t0
    la eh_ncs t0
    sd 0 zero t0
    la eh_kl t0
    sd 0 zero t0
    la eh_kf t0
    sd 0 zero t0
    la eh_inlp t0
    sd 0 zero t0
    la eh_fnon t0
    sd 0 zero t0
    la eh_sp t0
    sd 0 zero t0
"));

# ---- lazy's reach: _Unwind_ForcedUnwind takes the landing pads' names along
edit(\$t, 'lazyref', asm(4, "
    enter1
    call lazyfind
"), asm(4, "
    enter1
    call ehlazy
    call lazyfind
"));

# ---- the frame: a nested one ends the region of its outer one; the record
# of a function, its flag, its room
edit(\$t, 'cc/frame', asm(8, "
    enter3
    mv a0 s4
    mv a1 s5
"), asm(8, "
    enter3
    mv a0 s4
    mv a1 s5
    call ehframe0
"), asm(8, "
    call dbgrowf
    call dbgfn0
"), asm(8, "
    call dbgrowf
    call ehon
    mv s4 a0
    call dbgfn0
"), asm(8, "
    la cc_enterva a2
    call abiseq
    mv s4 a0
    jalr 0 s5 ra
"), asm(8, "
    la cc_enterva a2
    call abiseq
    mv s4 a0
    call ehbody
    mv s4 a0
    jalr 0 s5 ra
"), asm(8, "
    la se_top t0
    sd 0 s6 t0
    leave3
"), asm(8, "
    la se_top t0
    sd 0 s6 t0
    call ehframe1
    leave3
"));

# ---- the se stack's changes end a region and start the next
edit(\$t, 'cc/secl', asm(8, "
C1:
    la se_names t0
"), asm(8, "
C1:
    call ehclose
    la se_names t0
"), asm(10, "call sepush") . "        C9:\n", asm(10, "call sepush\ncall ehpush1") . "        C9:\n");
edit(\$t, 'cc/seemit', asm(8, "
    enter2
    mv a0 s4
"), asm(8, "
    enter2
    mv a0 s4
    call ehclose
"), asm(8, "
E9:
    leave2
"), asm(8, "
E9:
    call ehopen
    leave2
"));
edit(\$t, 'cc/seclose', asm(8, "
K9:
    leave1
"), asm(8, "
K9:
    call ehclose
    call ehopen
    leave1
"));
edit(\$t, 'cc/segoto', asm(8, "
G0:
    la se_top t0
"), asm(8, "
G0:
    call ehclose
    la se_top t0
"), asm(8, "
G9:
    mv s4 a0
    call jump
"), asm(8, "
G9:
    call ehopen
    mv s4 a0
    call jump
"));

# ---- debug.pl's record and room: with the unwinder too
edit(\$t, 'dbgfn0', asm(4, "
    la dbg_on t0
    ld 0 t0 t0
    beqz B9 t0
"), asm(4, "
    la eh_rec t0
    ld 0 t0 t0
    beqz B9 t0
"), asm(4, "
    sd 24 zero t3
"), asm(4, "
    sd 24 zero t3
    la dbg_fx t4
    slli 3 t1 t5
    add t5 t4 t4
    sd 0 zero t4
"));
edit(\$t, 'dbgfn1', asm(4, "
    la dbg_on t0
    ld 0 t0 t0
    beqz B9 t0
    la dbg_fns t0
"), asm(4, "
    la dbg_fns t0
"));
edit(\$t, 'cc/dbgarea', asm(4 + 4, "
    enter2
    la dbg_on t0
    ld 0 t0 t0
    beqz A9 t0
"), asm(8, "
    enter2
    call ehon
    beqz A9 a0
"), asm(10, "
    la dbg_area t0
    la cur_pc t1
"), asm(10, "
    call ehroom
    add a0 s5 s5
    la dbg_area t0
    la cur_pc t1
"));
edit(\$t, 'dbgwrite', asm(4, "
    enter1
    la dbg_on t0
    ld 0 t0 t0
    beqz W9 t0
"), asm(4, "
    enter1
    call ehwon
    beqz W9 a0
"), asm(4, "
    call dbgeh
"), asm(4, "
    call dbgeh
    la dbg_on t0
    ld 0 t0 t0
    beqz W9 t0
"));

# ---- dbgeh: the second CIE, FDEs of 48 or 56 bytes, the LSDAs, arm's extab
edit(\$t, 'dbgeh', asm(6, "
    addi 32 t2 t2
    sd 200 t2 s4
"), asm(6, "
    addi 32 t2 t2
    mv t2 s5
    call ehx
    add a0 s5 t2
    sd 200 t2 s4
"), asm(6, "
    li 0 s7
    li 0 s8
    li 0 s9
"), asm(6, "
    mv s6 a0
    call ehinit
    li 0 s7
    li 0 s8
    li 0 s9
"), asm(6, "
    li 48 t0
    mul t0 s8 t0
    ld 184 s4 t1
    add t1 t0 t0
    addi 24 t0 s5
"), asm(6, "
    addi -1 s7 a0
    ld 8 s10 a1
    call ehfde0
    ld 256 s4 s5
"), asm(6, "
    li 44 a0
    call dput4
    ld 184 s4 t0
"), asm(6, "
    call ehflen
    call dput4
    call ehcie
    mv a0 t0
"), asm(6, "
    li 0 a0
    call dput1
    slli 5 s11 t0
"), asm(6, "
    call ehaug
    slli 5 s11 t0
"), asm(6, "
    addi 17 s5 a0
    call dptr
    li 7 t0
"), asm(6, "
    ld 272 s4 a0
    add s5 a0 a0
    call dptr
    li 7 t0
"), asm(6, "
    addi 17 s5 a0
    add t4 a0 a0
"), asm(6, "
    ld 272 s4 a0
    add s5 a0 a0
    add t4 a0 a0
"), asm(6, "
    sub t0 s5 a0
    call dput4
    addi 1 s8 s8
"), asm(6, "
    sub t0 s5 a0
    call dput4
    addi 1 s8 s8
    call ehnext
"), asm(6, "
    ld 8 s10 a0
    li32 -2137291648 a1
"), asm(6, "
    call ehxword
    mv a0 a1
    ld 8 s10 a0
"), asm(6, "
    li 48 t0
    mul t0 s8 t0
    ld 184 s4 t1
    add t1 t0 a0
    addi 24 a0 a0
"), asm(6, "
    ld 256 s4 a0
"), asm(6, "
    li 48 t0
    mul t0 s8 t0
    addi 28 t0 t0
    sd 192 t0 s4
"), asm(6, "
    ld 256 s4 t0
    ld 184 s4 t1
    sub t1 t0 t0
    addi 4 t0 t0
    sd 192 t0 s4
"));

# ---- the compile time's part, in the cc group (before irelplace)
my $fns = cfn('ehon', "1 where this pass records the frames of the function compiled now (dbg_fns): with -g, or where the program has the unwinder (ehcheck, once a pass; not in compile time's JIT): eh_rec", "
    enter1
    la dbg_on t0
    ld 0 t0 s4
    la ccs t0
    ld CC_jit t0 t0
    bnez K8 t0
    la eh_state t0
    ld 0 t0 a0
    bgez K1 a0
    call ehcheck
K1:
    andi 1 a0 a0
    or s4 a0 s4
K8:
    la eh_rec t0
    sd 0 s4 t0
    mv s4 a0
    leave1
", 6)
. cfn('ehcheck', "eh_state: bit 0 where the program has _Unwind_ForcedUnwind, _Unwind_RaiseException or _Unwind_Backtrace (frames for every function), bit 1 where it also has _Unwind_Resume and __gcc_personality_v0 (landing pads, LSDAs; eh_persn); a0 the state", "
    enter2
    li 0 s4
    la eh_ufn a0
    li 20 a1
    call ehfind
    bnez C1 a0
    la eh_urx a0
    li 22 a1
    call ehfind
    bnez C1 a0
    la eh_ubt a0
    li 17 a1
    call ehfind
    beqz C9 a0
C1:
    li 1 s4
    la eh_ures a0
    li 14 a1
    call ehfind
    beqz C9 a0
    la eh_pers a0
    li 20 a1
    call ehfind
    beqz C9 a0
    la eh_persn t0
    sd 0 a0 t0
    li 3 s4
    call ehnodes
C9:
    la eh_state t0
    sd 0 s4 t0
    mv s4 a0
    leave2
", 6)
. cfn('ehfind', "the definition of the name a0 a1 (bytes, length) as a C call finds it (cfind), or 0", "
    enter2
    mv a0 s4
    mv a1 s5
    la eh_nodes a2
    sd NODE_content s4 a2
    sb NODE_content_len s5 a2
    sb NODE_children_len zero a2
    mv s4 a0
    mv s5 a1
    call cfind
    leave2
", 6)
. cfn('ehnodes', "the nodes of a landing pad's call: _Unwind_Resume with the local \\x02e, its exception (eh_callp the call's node)", "
    la eh_nodes t0
    addi NODE_size t0 t1
    la eh_vname t2
    li 2 t3
    sb 0 t3 t2
    li 101 t3
    sb 1 t3 t2
    sd NODE_content t2 t1
    li 2 t3
    sb NODE_content_len t3 t1
    sb NODE_children_len zero t1
    addi NODE_size t1 t4
    la eh_ures t2
    sd NODE_content t2 t4
    li 14 t3
    sb NODE_content_len t3 t4
    li 1 t3
    sb NODE_children_len t3 t4
    la eh_kids t2
    sd 0 t1 t2
    sd NODE_children t2 t4
    la eh_callp t2
    sd 0 t4 t2
    ret
", 6)
. cfn('ehframe0', "a frame starts: the region of an outer one ends, its function kept on eh_stk", "
    enter1
    call ehclose
    la eh_sp t0
    ld 0 t0 t1
    slli 3 t1 t3
    la eh_stk t4
    add t3 t4 t4
    la eh_fnon t5
    ld 0 t5 t6
    li 64 t2
    bgeu rel:F1 t2 t1
    sd 0 t6 t4
F1:
    addi 1 t1 t1
    sd 0 t1 t0
    sd 0 zero t5
    call ehclr
    leave1
", 6)
. cfn('ehframe1', "a frame ends: the outer function's back from eh_stk, its region goes on", "
    enter1
    la eh_ro t0
    sd 0 zero t0
    la eh_sp t0
    ld 0 t0 t1
    addi -1 t1 t1
    sd 0 t1 t0
    li 0 t6
    li 64 t2
    bgeu rel:F1 t2 t1
    slli 3 t1 t3
    la eh_stk t4
    add t3 t4 t4
    ld 0 t4 t6
F1:
    la eh_fnon t5
    sd 0 t6 t5
    call ehclr
    call ehopen
    leave1
", 6)
. cfn('ehclr', "no landing pad made yet for any height (eh_lpc)", "
    la eh_lpc t0
    li 256 t1
L1:
    sd 0 zero t0
    addi 8 t0 t0
    addi -1 t1 t1
    bnez L1 t1
    ret
", 6)
. cfn('ehbody', "after the prologue of function a0 (kept): with landing pads in the program and the function in dbg_fns (the last entry), eh_fnon its index + 1; one whose body calls __builtin_eh_return keeps 16 bytes below FP (eh_rsv, dbg_fx bit 1)", "
    enter3
    mv a0 s4
    la eh_state t0
    ld 0 t0 t0
    bltz B9 t0
    andi 2 t0 t0
    beqz B9 t0
    la ccs t0
    ld CC_jit t0 t0
    bnez B9 t0
    la dbg_fns t0
    ld 0 t0 t1
    beqz B9 t1
    addi -1 t1 s6
    li 24 t2
    mul t2 s6 t2
    add t2 t0 t2
    ld 8 t2 t3
    bne rel:B9 t3 s4
    ld 24 t2 t3
    bnez B9 t3
    addi 1 s6 t0
    la eh_fnon t1
    sd 0 t0 t1
    la targ_abi t0
    ld 0 t0 t0
    li 1 t1
    beq rel:B9 t1 t0
    mv s4 a0
    call ehscan
    beqz B9 a0
    la dbg_fx t0
    slli 3 s6 t1
    add t1 t0 t0
    ld 0 t0 t1
    li 2 t2
    or t1 t2 t2
    sd 0 t2 t0
    bnez B2 t1
    la eh_kf t3
    ld 0 t3 t4
    addi 1 t4 t4
    sd 0 t4 t3
B2:
    la ccs t0
    ld CC_depth t0 t1
    addi 16 t1 t1
    sd CC_depth t1 t0
    call syncsp
B9:
    mv s4 a0
    leave3
", 6)
. cfn('ehscan', "1 where a node under a0 (or a0) is __builtin_eh_return, else 0", "
    enter3
    mv a0 s4
    lbu NODE_content_len s4 t0
    li 19 t1
    bne rel:S2 t1 t0
    ld NODE_content s4 a0
    li 19 a1
    la eh_ehr a2
    li 19 a3
    call streq
    bnez S9 a0
S2:
    lbu NODE_children_len s4 s5
    ld NODE_children s4 s6
S3:
    li 0 a0
    beqz S9 s5
    ld 0 s6 a0
    call ehscan
    bnez S9 a0
    addi 8 s6 s6
    addi -1 s5 s5
    j S3
S9:
    leave3
", 6)
. cfn('ehmark', "a0 = cur_pc at a label of its own (what -O holds is out)", "
    enter1
    call newlabel
    call label
    la cur_pc t0
    ld 0 t0 a0
    leave1
", 6)
. cfn('ehopen', "a region starts here: of the function eh_fnon, with the stack as it is (height > 0), not inside a landing pad", "
    enter1
    la eh_inlp t0
    ld 0 t0 t0
    bnez O9 t0
    la eh_fnon t0
    ld 0 t0 t0
    beqz O9 t0
    la se_top t0
    ld 0 t0 s4
    beqz O9 s4
    la eh_rh t0
    sd 0 s4 t0
    call ehmark
    la eh_rs t0
    sd 0 a0 t0
    la eh_ro t0
    li 1 t1
    sd 0 t1 t0
O9:
    leave1
", 6)
. cfn('ehpush1', "after sepush: the landing pads of the heights from the new top on are of another stack now; a region starts", "
    la se_top t0
    ld 0 t0 t1
    la eh_lpc t0
    slli 3 t1 t2
    add t2 t0 t0
    li 256 t3
P1:
    bgeu rel:P9 t3 t1
    sd 0 zero t0
    addi 8 t0 t0
    addi 1 t1 t1
    j P1
P9:
    j ehopen
", 6)
. cfn('ehclose', "the open region ends here: its landing pad (made now unless the stack's is there), its entry in eh_cs", "
    enter3
    la eh_inlp t0
    ld 0 t0 t0
    bnez X9 t0
    la eh_ro t0
    ld 0 t0 t1
    beqz X9 t1
    sd 0 zero t0
    la eh_rs t0
    ld 0 t0 s4
    call ehmark
    mv a0 s5
    bgeu rel:X9 s5 s4
    la eh_rh t0
    ld 0 t0 t1
    slli 3 t1 t1
    la eh_lpc t2
    add t1 t2 s6
    ld 0 s6 a2
    bnez X2 a2
    call ehlp
    sd 0 a0 s6
    mv a0 a2
X2:
    mv s4 a0
    mv s5 a1
    call ehrec
X9:
    leave3
", 6)
. cfn('ehlp', "a landing pad for the stack as it is, jumped over: the exception (V) in a local of its own, every exit action, _Unwind_Resume of it; a0 its address", "
    enter5
    la eh_inlp t0
    li 1 t1
    sd 0 t1 t0
    call newlabel
    mv a0 s4
    call jump
    call newlabel
    call label
    la cur_pc t0
    ld 0 t0 s5
    la ccs t0
    ld CC_depth t0 s6
    ld CC_nvars t0 s7
    la eh_nodes a0
    addi NODE_size a0 a0
    li TY_LONG a1
    call declare
    mv a0 s8
    call syncsp
    mv s8 a0
    call vaddrt0
    li TY_LONG a0
    call store
    li 0 a0
    call seemit
    la eh_callp a0
    addi 8 a0 a1
    call stmts
    la ccs t0
    sd CC_depth s6 t0
    sd CC_nvars s7 t0
    mv s4 a0
    call label
    la eh_inlp t0
    sd 0 zero t0
    mv s5 a0
    leave5
", 6)
. cfn('ehrec', "the region a0..a1 of function eh_fnon, its landing pad a2: an entry of eh_cs (32 bytes: function, start, end, LP), or the last one longer; dbg_fx bit 0, eh_kl and eh_kf count", "
    la eh_fnon t0
    ld 0 t0 t6
    addi -1 t6 t6
    la eh_ncs t0
    ld 0 t0 t1
    la eh_cs t2
    beqz R2 t1
    addi -1 t1 t3
    slli 5 t3 t3
    add t3 t2 t3
    ld 0 t3 t4
    bne rel:R2 t4 t6
    ld 16 t3 t4
    bne rel:R2 t4 a0
    ld 24 t3 t4
    bne rel:R2 t4 a2
    sd 16 a1 t3
    ret
R2:
    li32 65536 t4
    bgeu rel:R9 t4 t1
    slli 5 t1 t3
    add t3 t2 t3
    sd 0 t6 t3
    sd 8 a0 t3
    sd 16 a1 t3
    sd 24 a2 t3
    addi 1 t1 t1
    sd 0 t1 t0
    la dbg_fx t2
    slli 3 t6 t3
    add t3 t2 t2
    ld 0 t2 t3
    andi 1 t3 t4
    bnez R9 t4
    li 1 t4
    or t3 t4 t4
    sd 0 t4 t2
    la eh_kl t5
    ld 0 t5 t4
    addi 1 t4 t4
    sd 0 t4 t5
    bnez R9 t3
    la eh_kf t5
    ld 0 t5 t4
    addi 1 t4 t4
    sd 0 t4 t5
R9:
    ret
", 6)
. cfn('ehroom', "dbgarea's room for the tables, a0 bytes more: the LSDAs (20 a function and 13 a region at most), and but on arm the second CIE and 8 bytes more an FDE of dbg_fx; the counts kept in eh_snap for dbgeh", "
    la eh_kl t0
    ld 0 t0 t1
    la eh_kf t0
    ld 0 t0 t2
    la eh_ncs t0
    ld 0 t0 t3
    la eh_snap t0
    sd 0 t1 t0
    sd 8 t2 t0
    sd 16 t3 t0
    li 20 t4
    mul t4 t1 a0
    li 13 t4
    mul t4 t3 t4
    add t4 a0 a0
    addi 7 a0 a0
    andi -8 a0 a0
    la targ_abi t0
    ld 0 t0 t0
    li 1 t5
    beq rel:R9 t5 t0
    slli 3 t2 t4
    add t4 a0 a0
    beqz R9 t1
    addi 32 a0 a0
R9:
    ret
", 6);
my ($pf, $pt) = find(\$t, 'cc/irelplace');
substr($t, $pt, 0) = $fns;

# ---- the writer's part, at the end of layer 0
my $code = cfn('ehlazy', "lazyref's name a0 a1 (kept): with _Unwind_ForcedUnwind, _Unwind_Resume and __gcc_personality_v0 are reached too", "
    enter3
    mv a0 s4
    mv a1 s5
    li 20 t0
    bne rel:Z9 t0 s5
    mv s4 a0
    li 20 a1
    la eh_ufn a2
    li 20 a3
    call streq
    beqz Z9 a0
    la eh_ures a0
    li 14 a1
    call lazyref
    la eh_pers a0
    li 20 a1
    call lazyref
Z9:
    mv s4 a0
    mv s5 a1
    leave3
", 2)
. cfn('ehwon', "1 where write_output writes the frames: with -g, or the unwinder (eh_state bit 0)", "
    la dbg_on t0
    ld 0 t0 a0
    la eh_state t0
    ld 0 t0 t1
    bltz W9 t1
    andi 1 t1 t1
    or t1 a0 a0
W9:
    ret
", 2)
. cfn('ehx', "the bytes .eh_frame has more (0 on arm): the second CIE where a function has an LSDA, 8 an FDE of dbg_fx", "
    la dbg_st t0
    ld 216 t0 t1
    li 3 t2
    li 0 a0
    beq rel:X9 t2 t1
    la eh_snap t0
    ld 0 t0 t1
    ld 8 t0 t2
    slli 3 t2 a0
    beqz X9 t1
    addi 32 a0 a0
X9:
    ret
", 2)
. cfn('ehinit', "dbgeh's start, a0 its count of functions: dbg_st 304 the second CIE (after the first), 256 the next FDE, 288 the next LSDA (past .ARM.exidx), 280 __gcc_personality_v0's address; the second CIE written where it is", "
    enter3
    mv a0 s5
    la dbg_st s4
    li 0 s6
    ld 184 s4 t0
    addi 24 t0 t0
    sd 304 t0 s4
    ld 216 s4 t0
    li 3 t1
    beq rel:I1 t1 t0
    la eh_snap t0
    ld 0 t0 t0
    beqz I1 t0
    li 1 s6
I1:
    ld 304 s4 t0
    slli 5 s6 t1
    add t1 t0 t0
    sd 256 t0 s4
    ld 200 s4 t0
    ld 216 s4 t1
    li 3 t2
    bne rel:I2 t2 t1
    slli 4 s5 t3
    add t3 t0 t0
I2:
    addi 7 t0 t0
    andi -8 t0 t0
    sd 288 t0 s4
    sd 280 zero s4
    la eh_state t0
    ld 0 t0 t0
    bltz I3 t0
    andi 2 t0 t0
    beqz I3 t0
    la eh_persn t0
    ld 0 t0 a0
    call label_addr
    sd 280 a0 s4
I3:
    beqz I9 s6
    ld 304 s4 a0
    call dptr
    sd 80 a0 s4
    ld 216 s4 t0
    slli 5 t0 t0
    la eh_cie2 a0
    add t0 a0 a0
    li 32 a1
    call dcopy
    ld 304 s4 a0
    addi 19 a0 a0
    call dptr
    sd 80 a0 s4
    ld 304 s4 t0
    addi 19 t0 t0
    ld 280 s4 a0
    sub t0 a0 a0
    call dput4
I9:
    leave3
", 2)
. cfn('ehfde0', "before the FDE of function a0 (dbg_fns' index) at a1: its LSDA written (dbg_st 296, else 0); 264 its FDE's flags (dbg_fx's, 0 on arm), 272 where its instructions start in it; an FDE with flags (56 bytes) zeroed first", "
    enter5
    mv a0 s5
    mv a1 s6
    la dbg_st s4
    sd 296 zero s4
    sd 264 zero s4
    li 17 t0
    sd 272 t0 s4
    la dbg_fx t0
    slli 3 s5 t1
    add t1 t0 t0
    ld 0 t0 s7
    andi 1 s7 t0
    beqz D1 t0
    mv s5 a0
    mv s6 a1
    call ehlsda
    sd 296 a0 s4
D1:
    ld 216 s4 t0
    li 3 t1
    beq rel:D9 t1 t0
    sd 264 s7 s4
    li 17 t2
    andi 1 s7 t0
    beqz D2 t0
    addi 4 t2 t2
D2:
    andi 2 s7 t0
    beqz D3 t0
    addi 4 t2 t2
D3:
    sd 272 t2 s4
    beqz D9 s7
    ld 256 s4 a0
    call dptr
    li 56 t0
D4:
    sb 0 zero a0
    addi 1 a0 a0
    addi -1 t0 t0
    bnez D4 t0
D9:
    leave5
", 2)
. cfn('ehflen', "the FDE's length: 44, 52 with flags", "
    la dbg_st t0
    ld 264 t0 t1
    li 44 a0
    beqz F9 t1
    li 52 a0
F9:
    ret
", 2)
. cfn('ehcie', "the CIE of the FDE: the second where it has an LSDA", "
    la dbg_st t0
    ld 264 t0 t1
    andi 1 t1 t1
    ld 184 t0 a0
    beqz F9 t1
    ld 304 t0 a0
F9:
    ret
", 2)
. cfn('ehcur', "a0 = the address at dbgeh's cursor (dbg_st 80)", "
    la dbg_st t0
    ld 80 t0 t1
    la outbuf t2
    sub t2 t1 t1
    ld 16 t0 t2
    add t2 t1 a0
    ret
", 2)
. cfn('ehaug', "the FDE's augmentation at the cursor: its length (0, or 4 and the LSDA's address, pcrel); with bit 1 the instructions of eh_rsv: data registers 0 and 1 at CFA - 32 and CFA - 24", "
    enter2
    la dbg_st s4
    ld 264 s4 s5
    andi 1 s5 t0
    bnez A1 t0
    li 0 a0
    call dput1
    j A2
A1:
    li 4 a0
    call dput1
    call ehcur
    ld 296 s4 t0
    sub a0 t0 a0
    call dput4
A2:
    andi 2 s5 t0
    beqz A9 t0
    ld 216 s4 t0
    li 0 s5
    bnez A3 t0
    li 10 s5
A3:
    addi 128 s5 a0
    call dput1
    li 4 a0
    call dput1
    addi 129 s5 a0
    call dput1
    li 3 a0
    call dput1
A9:
    leave2
", 2)
. cfn('ehnext', "past the FDE: dbg_st 256 48 or 56 bytes on", "
    la dbg_st t0
    ld 264 t0 t1
    li 48 t2
    beqz N1 t1
    li 56 t2
N1:
    ld 256 t0 t1
    add t2 t1 t1
    sd 256 t1 t0
    ret
", 2)
. cfn('ehxword', "arm: the second word of the function's .ARM.exidx entry: the compact frame's, or the prel31 of its .ARM.extab entry (dbg_st 296)", "
    la dbg_st t0
    ld 296 t0 t1
    li32 -2137291648 a0
    beqz W9 t1
    ld 200 t0 t2
    ld 208 t0 t3
    add t3 t2 t2
    addi 4 t2 t2
    sub t2 t1 a0
    slli 33 a0 a0
    srli 33 a0 a0
W9:
    ret
", 2)
. cfn('ehlsda', "the LSDA of function a0 (dbg_fns' index) at a1 at dbg_st 288 (on arm its .ARM.extab entry first), its regions of eh_cs (1260 at most); 288 past it, 8-aligned; a0 its address", "
    enter8
    mv a0 s5
    mv a1 s6
    la dbg_st s4
    ld 80 s4 s11
    ld 288 s4 s7
    la eh_ncs t0
    ld 0 t0 s8
    li 0 s10
    la eh_cs t1
    mv s8 t2
L1:
    beqz L2 t2
    ld 0 t1 t3
    addi 32 t1 t1
    addi -1 t2 t2
    bne rel:L1 t3 s5
    addi 1 s10 s10
    j L1
L2:
    li 1260 t0
    bgeu rel:L3 s10 t0
    mv t0 s10
L3:
    mv s7 a0
    call dptr
    sd 80 a0 s4
    ld 216 s4 t0
    li 3 t1
    bne rel:L4 t1 t0
    ld 280 s4 a0
    sub s7 a0 a0
    slli 33 a0 a0
    srli 33 a0 a0
    call dput4
    li32 10192000 a0
    call dput4
L4:
    li 255 a0
    call dput1
    li 255 a0
    call dput1
    li 3 a0
    call dput1
    li 13 t0
    mul t0 s10 a0
    andi 127 a0 a0
    addi 128 a0 a0
    call dput1
    li 13 t0
    mul t0 s10 a0
    srli 7 a0 a0
    call dput1
    la eh_cs s9
L5:
    beqz L8 s10
    beqz L8 s8
    ld 0 s9 t0
    bne rel:L6 t0 s5
    ld 8 s9 a0
    sub s6 a0 a0
    call dput4
    ld 16 s9 a0
    ld 8 s9 t0
    sub t0 a0 a0
    call dput4
    ld 24 s9 a0
    sub s6 a0 a0
    call dput4
    li 0 a0
    call dput1
    addi -1 s10 s10
L6:
    addi 32 s9 s9
    addi -1 s8 s8
    j L5
L8:
    call ehcur
    addi 7 a0 a0
    andi -8 a0 a0
    sd 288 a0 s4
    sd 80 s11 s4
    mv s7 a0
    leave8
", 2);

# the second CIE of each target (32 bytes): "zPLR", P pcrel sdata4 (its 4
# bytes at 19, dbgeh fills them), L and R pcrel sdata4; riscv64, x86_64,
# aarch64 (and a place of arm's, never written)
my @cie = (
    [0x78, 0x01, 0x0c, 0x02, 0x00],
    [0x78, 0x10, 0x0c, 0x07, 0x08, 0x90, 0x01],
    [0x78, 0x1e, 0x0c, 0x1f, 0x00],
    [0x7c, 0x0e, 0x0c, 0x0d, 0x00],
);
my @cb;
for (@cie) {
    my ($da, $ra, @init) = @$_;
    my @c = (28, 0, 0, 0, 0, 0, 0, 0, 1, map({ ord } split //, 'zPLR'), 0, 1, $da, $ra, 7, 0x1b, 0, 0, 0, 0, 0x1b, 0x1b, @init);
    die "ehtable.pl: personality not at 19\n" unless $c[18] == 0x1b && $c[23] == 0x1b;
    push @c, 0 while @c < 32;
    die "ehtable.pl: CIE of " . @c . " bytes\n" if @c != 32;
    push @cb, @c;
}
$code .= bytes('eh_cie2', 'the second CIE of each target (32 bytes): riscv64, x86_64, aarch64, arm', @cb);
once(\$t, "\n1:\n", "\n${code}1:\n", 'the end of layer 0');
save();
