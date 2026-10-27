# wtstmt.pl: wide temporaries (wtemp: a long double's, a vector's, 16 bytes
# a value) are reused statement by statement instead of each having its own
# room for the whole function. In a function whose type names a wide type
# (wgate), treserve gave every operator 16 bytes of the frame, never used
# again: __printf_buffer had 12.5 KB of them, past the 16 KB stacks
# tst-swapcontext1 makes.
#
# Code: stmts marks where the wide temporaries are (wt_next) before each
# statement and goes back to it after. A : that is a value (primary's group,
# GNU C's statement expression) keeps its last statement's (wt_keep, which
# the next stmts takes): the value is in them.
# Room: wlist works out the most a list of statements needs at once:
# 32 bytes for each node of a statement, 16 for a leaf that is no operator
# (cast, sizeof, alignof and array hold no values, a declaration's type run
# neither); a run of nodes that is no statement node (an expression
# statement, or several: c2ff writes a line node between two) counts whole;
# a statement node (if, while, for, return, switch, case, a declaration...)
# holds its leading items (a condition, a value, an initializer; for's first
# two runs) while its body's statements run one at a time: the leading
# items + the largest of the others; a label's statements, else's, default's
# lead none; if, else if, else in a row are one statement: each one's
# leading items + the largest of their bodies; a : is a list of its own (a
# block, or a value whose statements but the last end as they go).
# treserve takes this room as the function's wide pool (wt_on, wt_next to
# wt_lim, first in the reservation) only where it is less than before (16
# bytes for each operator of the function, never used again): a frame never
# grows. Otherwise, and outside a function body (exprbody, pairbody), it is
# as before (wtemp from CC_tnext up to lookcache 168). wtemp past the pool's
# end stops with msg_wide, as before.
# Test: cwidestmt.
our ($t, $tf); do "$ENV{PATCHLIB}" or die $@;

# ---- the state: data after x64_flags
$t =~ /^( *)x64_flags:\n\1  dword\n\1    0\n/m or die "wtstmt: no x64_flags\n";
my $vi = $1;
once(\$t, "${vi}x64_flags:\n$vi  dword\n$vi    0\n", "${vi}x64_flags:\n$vi  dword\n$vi    0\n"
    . join('', map { "$vi$_:\n$vi  dword\n$vi    0\n" } qw(wt_on wt_next wt_lim wt_keep wt_stmts)), 'x64_flags');

# ---- wtemp: from the pool when there is one
edit(\$t, 'wtemp', "      wtemp:\n", "      wtemp:\n" . asm(8, "
    la wt_on t0
    ld 0 t0 t0
    bnez LW t0
"), "        L9:\n", asm(8, "
LW:
    la wt_next t0
    ld 0 t0 t1
    addi 16 t1 t1
    la wt_lim t2
    ld 0 t2 t3
    bltu rel:L9 t1 t3
    sd 0 t1 t0
    mv t1 a0
    ret
") . "        L9:\n");

# ---- frame: no pool at a function's start
edit(\$t, 'frame', "        sd\n          176\n          zero\n          t1\n", "        sd\n          176\n          zero\n          t1\n" . asm(8, "
    la wt_on t1
    sd 0 zero t1
    la wt_next t1
    sd 0 zero t1
    la wt_lim t1
    sd 0 zero t1
    la wt_keep t1
    sd 0 zero t1
    la wt_stmts t1
    sd 0 zero t1
"));

# ---- fnbody: its statements are a list for wlist
my $w = "          call\n            wgate\n          la\n            lookcache\n            t0\n          sd\n            160\n            a0\n            t0\n";
edit(\$t, 'fnbody', $w, $w . asm(10, "
    la wt_stmts t0
    li 1 t1
    sd 0 t1 t0
"));

# ---- stmts: each statement's wide temporaries end with it, but a value's
# last (wt_keep: primary's group; past it only lines and comments)
{
    my ($from, $to) = find(\$t, 'stmts');
    substr($t, $from, $to - $from) = fn('stmts', "
    enter5
    la ccs t0
    ld CC_cur t0 s4
    ld CC_end t0 s5
    sd CC_cur a0 t0
    sd CC_end a1 t0
    la wt_keep t0
    ld 0 t0 s7
    sd 0 zero t0
L1:
    call more
    beqz L2 a0
    la wt_next t0
    ld 0 t0 s6
    call stmt
    beqz LR s7
    la ccs t0
    ld CC_cur t0 s8
L3:
    la ccs t0
    ld CC_end t0 t1
    bgeu rel:L1 t1 s8
    ld 0 s8 a0
    li 0 a1
    call wkind
    li 4 t0
    bne rel:LR t0 a0
    addi 8 s8 s8
    j L3
LR:
    la wt_next t0
    sd 0 s6 t0
    j L1
L2:
    mv s4 a0
    mv s5 a1
    call close
    leave5
", 6);
}

# ---- primary: a : as a value keeps its last statement's temporaries
edit(\$t, 'primary', "          L10G:\n            mv\n              s4\n              a0\n            call\n              group\n            j\n              L9\n",
    "          L10G:\n" . asm(12, "
    la wt_keep t0
    li 1 t1
    sd 0 t1 t0
    mv s4 a0
    call group
    la wt_keep t0
    sd 0 zero t0
    j L9
"));

# ---- treserve: the pool where it is smaller
{
    my ($from, $to) = find(\$t, 'treserve');
    substr($t, $from, $to - $from) = fn('treserve', "
    enter8
    la abi_curfn t0
    sd 0 a2 t0
    la abi_curx t0
    sd 0 zero t0
    mv a0 s4
    slli 3 a1 t0
    add t0 a0 s5
    la wt_stmts t0
    ld 0 t0 s10
    sd 0 zero t0
    la wt_on t0
    sd 0 zero t0
    mv s4 a0
    mv s5 a1
    call tsum
    mv a0 s6
    li 0 s7
    la lookcache t0
    ld 160 t0 s9
    beqz TR2 s9
    beqz TR2 s10
    sd 160 zero t0
    mv s4 a0
    mv s5 a1
    call tsum
    mv a0 s8
    la lookcache t0
    sd 160 s9 t0
    mv s4 a0
    mv s5 a1
    li 0 a2
    li 1 a3
    call wlist
    sub s8 s6 t0
    bgeu rel:TR2 t0 a0
    mv a0 s7
    mv s8 s6
    la wt_on t0
    li 1 t1
    sd 0 t1 t0
TR2:
    call abixget
    add a0 s6 s6
    la ccs t0
    ld CC_depth t0 t1
    la wt_next t2
    sd 0 t1 t2
    add s7 t1 t1
    la wt_lim t2
    sd 0 t1 t2
    sd CC_tnext t1 t0
    add s6 t1 t2
    la lookcache t3
    sd 168 t2 t3
    add s6 s7 t3
    beqz TR9 t3
    sd CC_depth t2 t0
    call syncsp
TR9:
    leave8
", 6);
}

# ---- the new functions, in cc's layer 4
my $h = '';
# tsum: a0 a1 the nodes from a0 to a1: what treserve reserved for them
# before (tscan, tlit; the wide temporaries if lookcache 160)
$h .= fn('tsum', "
    enter3
    mv a0 s4
    mv a1 s5
    li 0 s6
L1:
    bgeu rel:L2 s5 s4
    ld 0 s4 a0
    call litk
    li -1 t0
    beq rel:LT t0 a0
    mv s4 a0
    mv s5 a1
    li 1 a2
    call tlit
    add a0 s6 s6
    mv a1 s4
    j L1
LT:
    ld 0 s4 a0
    call tscan
    add a0 s6 s6
    addi 8 s4 s4
    j L1
L2:
    mv s6 a0
    leave3
", 6);
# wkind: a0 a node, a1 1 at a statement's start: a0 0 a node of an
# expression, 1 a statement node, 2 if, 3 else or elseif, 4 a line or
# comment (no code)
$h .= fn('wkind', "
    enter2
    mv a0 s4
    mv a1 s5
    lbu NODE_content_len s4 t0
    li 4 t1
    bne rel:K1 t1 t0
    lbu NODE_children_len s4 t0
    beqz K1 t0
    li 3 t1
    bgeu rel:K1 t1 t0
    ld NODE_content s4 t0
    lbu 0 t0 t1
    li 108 t2
    bne rel:K1 t2 t1
    lbu 1 t0 t1
    li 105 t2
    bne rel:K1 t2 t1
    lbu 2 t0 t1
    li 110 t2
    bne rel:K1 t2 t1
    lbu 3 t0 t1
    li 101 t2
    bne rel:K1 t2 t1
    li 4 a0
    leave2
K1:
    mv s4 a0
    call kwof
    li KW_comment t0
    beq rel:K4 t0 a0
    li KW_if t0
    beq rel:K2 t0 a0
    li KW_else t0
    beq rel:K3 t0 a0
    li KW_elseif t0
    beq rel:K3 t0 a0
    li KW_while t0
    beq rel:KS t0 a0
    li KW_return t0
    beq rel:KS t0 a0
    li KW_break t0
    beq rel:KS t0 a0
    li KW_continue t0
    beq rel:KS t0 a0
    li KW_for t0
    beq rel:KS t0 a0
    li KW_dowhile t0
    beq rel:KS t0 a0
    li KW_switch t0
    beq rel:KS t0 a0
    li KW_case t0
    beq rel:KS t0 a0
    li KW_default t0
    beq rel:KS t0 a0
    li KW_goto t0
    beq rel:KS t0 a0
    beqz K0 s5
    lbu NODE_content_len s4 t0
    li 2 t1
    bltu rel:K0 t1 t0
    ld NODE_content s4 t1
    add t0 t1 t1
    lbu -1 t1 t1
    li 58 t2
    bne rel:K0 t2 t1
KS:
    li 1 a0
    leave2
K2:
    li 2 a0
    leave2
K3:
    li 3 a0
    leave2
K4:
    li 4 a0
    leave2
K0:
    li 0 a0
    leave2
", 6);
# wsplit: a0 a1 two nodes in a row in a list of statements, neither a
# statement node: a0 1 where a statement can start at a1 (no operator joins
# them: neither is one or a : of ?, a0 no prefix (cast, a literal's suffix
# word) nor a literal's type, a1 no postfix (* pointer, & address))
$h .= fn('wsplit', "
    enter2
    mv a0 s4
    mv a1 s5
    mv s4 a0
    call opof
    bgez N a0
    mv s5 a0
    call opof
    bgez N a0
    mv s4 a0
    call wcolon
    bnez N a0
    mv s5 a0
    call wcolon
    bnez N a0
    mv s4 a0
    call prefixw
    li 2 t0
    blt rel:N a0 t0
    mv s5 a0
    call prefixw
    addi -1 a0 t1
    li 2 t0
    bltu rel:N t0 t1
    mv s4 a0
    call litk
    li -1 t0
    bne rel:N t0 a0
    li 1 a0
    leave2
N:
    li 0 a0
    leave2
", 6);
# wcolon: a0 a node: a0 1 if it is a : without children (a ?'s)
$h .= fn('wcolon', "
    li 0 t2
    lbu NODE_children_len a0 t0
    bnez C9 t0
    lbu NODE_content_len a0 t0
    li 1 t1
    bne rel:C9 t1 t0
    ld NODE_content a0 t0
    lbu 0 t0 t0
    li 58 t1
    bne rel:C9 t1 t0
    li 1 t2
C9:
    mv t2 a0
    ret
", 6);
# wscan: a0 a node, a1 1 in an expression (a sum), 0 a statement node, 2 a
# block (a : alone in a list of statements): a0 the room of its wide
# temporaries, a1 that of its leading items (a statement node's; else a0)
$h .= fn('wscan', "
    enter8
    mv a0 s4
    mv a1 s5
    li 32 s6
    lbu NODE_children_len s4 t0
    bnez W0 t0
    mv s4 a0
    call opof
    bgez W9 a0
    li 16 s6
    j W9
W0:
    mv s4 a0
    call kwof
    mv a0 s7
    li KW_cast t0
    beq rel:W9 t0 s7
    li KW_sizeof t0
    beq rel:W9 t0 s7
    li KW_alignof t0
    beq rel:W9 t0 s7
    mv s4 a0
    call kwav
    li KW_array t0
    beq rel:W9 t0 a0
    mv s4 a0
    call flatkids
    mv a0 s8
    mv a1 s9
    mv a0 s10
    mv s4 a0
    mv s8 a1
    mv s9 a2
    call tfrom
    mv a0 s8
    mv a1 s9
    lbu NODE_content_len s4 t0
    li 1 t1
    bne rel:WC t1 t0
    ld NODE_content s4 t0
    lbu 0 t0 t0
    li 58 t1
    bne rel:WC t1 t0
    li 0 a2
    li 0 a3
    li 2 t0
    bne rel:WB t0 s5
    li 1 a3
    j WB
WC:
    li 1 t0
    beq rel:WS t0 s5
    mv s4 a0
    li 1 a1
    call wkind
    beqz WS a0
    li 4 t0
    beq rel:WS t0 a0
    li 1 a2
    li 1 a3
    li KW_for t0
    bne rel:W2 t0 s7
    li 3 a2
    j W1
W2:
    li KW_return t0
    bne rel:W4 t0 s7
    li 0 a3
    j W1
W4:
    li KW_else t0
    beq rel:W3 t0 s7
    li KW_default t0
    beq rel:W3 t0 s7
    lbu NODE_content_len s4 t0
    ld NODE_content s4 t1
    add t0 t1 t1
    lbu -1 t1 t1
    li 58 t2
    bne rel:W1 t2 t1
    beq rel:W3 s10 s8
    li 0 a3
    j W1
W3:
    li 0 a2
W1:
    mv s8 a0
    mv s9 a1
    call wlist
    add s6 a1 a1
    add s6 a0 a0
    leave8
WB:
    mv s8 a0
    mv s9 a1
    call wlist
    add s6 a0 a0
    mv a0 a1
    leave8
WS:
    bgeu rel:W9 s9 s8
    ld 0 s8 a0
    li 1 a1
    call wscan
    add a0 s6 s6
    addi 8 s8 s8
    j WS
W9:
    mv s6 a0
    mv s6 a1
    leave8
", 6);
# wlist: a0 a1 the nodes from a0 to a1, a2 how many runs lead (summed, as
# a condition, held while the rest runs), a3 1 a list of statements (an
# expression's run ends where wsplit says one can start): a0 the room of
# their wide temporaries, the leading runs' plus the largest of the
# others, a1 the leading runs'
$h .= fn('wlist', "
    enter8
    addi -16 sp sp
    sd 0 a3 sp
    mv a0 s4
    mv a1 s5
    mv a2 s6
    li 0 s7
    li 0 s8
    li 1 s9
L1:
    bgeu rel:L9 s5 s4
    ld 0 s4 a0
    mv s9 a1
    call wkind
    beqz LE a0
    li 1 s9
    li 4 t0
    beq rel:LN t0 a0
    li 2 t0
    beq rel:LC t0 a0
    ld 0 s4 a0
    li 0 a1
    beqz LS1 s6
    li 1 a1
LS1:
    call wscan
    addi 8 s4 s4
    j LR
LN:
    addi 8 s4 s4
    j L1
LC:
    li 0 s10
    li 0 s11
LC1:
    ld 0 s4 a0
    li 0 a1
    beqz LC2 s6
    li 1 a1
LC2:
    call wscan
    add a1 s10 s10
    sub a1 a0 t0
    bgeu rel:LC3 t0 s11
    mv t0 s11
LC3:
    addi 8 s4 s4
    bgeu rel:LC4 s5 s4
    ld 0 s4 a0
    li 0 a1
    call wkind
    li 3 t0
    beq rel:LC1 t0 a0
LC4:
    add s10 s11 a0
    j LR
LE:
    li 0 s11
    mv s4 s10
LE1:
    ld 0 s4 a0
    call litk
    li -1 t0
    beq rel:LE4 t0 a0
    mv s4 a0
    mv s5 a1
    li 1 a2
    call tlit
    mv a1 s9
LE5:
    bgeu rel:LE7 s9 s4
    ld 0 s4 a0
    li 1 a1
    call wscan
    add a0 s11 s11
    addi 8 s4 s4
    j LE5
LE4:
    ld 0 s4 a0
    li 1 a1
    call wscan
    add a0 s11 s11
    addi 8 s4 s4
LE7:
    bgeu rel:LE2 s5 s4
    ld 0 s4 a0
    li 0 a1
    call wkind
    bnez LE2 a0
    ld 0 sp t0
    beqz LE1 t0
    ld -8 s4 a0
    ld 0 s4 a1
    call wsplit
    beqz LE1 a0
LE2:
    li 1 s9
    ld 0 sp t0
    beqz LE3 t0
    bnez LE3 s6
    addi 8 s10 t0
    bne rel:LE3 t0 s4
    ld 0 s10 a0
    call wcolon
    bnez LE3 a0
    ld 0 s10 a0
    lbu NODE_content_len a0 t1
    li 1 t2
    bne rel:LE3 t2 t1
    ld NODE_content a0 t1
    lbu 0 t1 t1
    li 58 t2
    bne rel:LE3 t2 t1
    li 2 a1
    call wscan
    mv a0 s11
LE3:
    mv s11 a0
LR:
    beqz LR1 s6
    addi -1 s6 s6
    add a0 s7 s7
    j L1
LR1:
    bgeu rel:L1 a0 s8
    mv a0 s8
    j L1
L9:
    add s7 s8 a0
    mv s7 a1
    addi 16 sp sp
    leave8
", 6);
{
    my ($from, $to) = find(\$t, 'cc/4');
    substr($t, $to, 0) = $h;
}
save();
