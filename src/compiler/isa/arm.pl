# isa/arm.pl — the arm section of the shared page (mkff.pl does it): 32-bit
# ARMv7-A, little-endian, Linux EABI. A32 (data processing, multiply and
# divide, bit fields, loads and stores, branches, exclusives, barriers,
# system), VFPv3 for f32 and f64 (s0..s31, d0..d31), the 16-bit Thumb set
# and the main 32-bit Thumb-2 forms, its registers, and macros/arm.ff.txt.
# No NEON.
#
# Operands: an instruction takes GNU's operands in reverse order, the
# destination last: `add r0, r1, r2` is `add r2 r1 r0`, `ldr r0, [r1, #8]`
# is `ldr 8 r1 r0`, `strex r0, r1, [r2]` is `strex r2 r1 r0`. Each def
# below gives the GNU form; its placeholders, reversed, are the parameters.
# Exceptions: vpush/vpop take the first register then the count; ldrd,
# strd, ldrexd and strexd (A32) name only the first of their two registers.
#
# Names: GNU mnemonics, plus a suffix where GNU uses one name for several
# encodings:
#   x      register operand          xi     immediate operand
#   x.lsl x.lsr x.asr x.ror          register shifted by an amount
#   x.rrx                            register rotated through carry
#   x.lslr x.lsrr x.asrr x.rorr      register shifted by a register
#   xs                               sets the flags (adds, addsi, adds.lsl)
#   ldr ldr.pre ldr.post             [rn, #imm], [rn, #imm]!, [rn], #imm
#   ldrr ldrr.pre ldrr.post          the same with a register offset
#   ldmia.wb ...                     with writeback (rn!)
#   x.if                             conditional, the condition first (a
#                                    number or cond.eq ... cond.al); A32
#                                    only: mov mvn add sub and orr eor cmp
#                                    (x and xi), ldr str ldrb strb, movw
#                                    movt, bl bx blx, svc
#   t.x                              16-bit Thumb
#   t2.x                             32-bit Thumb-2 (both halfwords in one
#                                    32-bit encoding, the second first)
# and a few names of their own: blxi (blx label), mrs.spsr msr.spsr,
# vmov.sr vmov.rs vmov.drr vmov.rrd (s <- r, r <- s, d <- r r, r r <- d),
# vmov.f32i (immediate), vcmp.f32z (with #0), vmrs.nzcv (APSR_nzcv),
# t.addsi8 t.subsi8 (rdn, #imm8), t.cmphi (cmp of high registers), t.ldrl
# ([pc, #imm]), t.ldrsp t.strsp ([sp, #imm]), t.adr t.addsp (rd = pc / sp +
# imm), t.addspi t.subspi (sp +- imm), t2.ldr.neg ([rn, #-imm]), t2.addw.
# A32 instructions without .if are unconditional (cond = 1110); every
# condition has its branch: beq bne bcs bhs bcc blo bmi bpl bvs bvc bhi bls
# bge blt bgt ble (t.beq ... for Thumb, t2.beq ... for Thumb-2 .w).
#
# Immediates as the encodings have them:
#   - A32 data processing: imm8 and rot (GNU's `#imm8, rot`, the value
#     imm8 rotated right by rot, an even 0..30); reversed: `addi rot imm8
#     rn rd`, so `add r0, r1, #4` is `addi 0 4 r1 r0`.
#   - Thumb-2 data processing: imm12, the i:imm3:imm8 field of
#     ThumbExpandImm (0..255 is the value itself).
#   - vmov.f32i / vmov.f64i: uimm8, VFPExpandImm's field (0x70 is 1.0).
#   - Branches: imm, the offset from PC as the architecture reads it, the
#     instruction + 8 in A32, + 4 in Thumb; `arel`/`trel label` give it.
#   - Signed load/store offsets (imm): the U bit and the magnitude come from
#     the one signed operand (up[] and mag[] below). ttpc's range check
#     lets -4096 through for a 12-bit magnitude (it is encoded as -0).
#   - lsr/asr by an amount: 1..31, and 0 for 32, as the encoding has it.
#   - ubfx/sbfx take the width 1..31 (the range check stops 32).
# Registers r0..r15 (a1..a4, v1..v5, sb, sl, fp, ip, sp, lr, pc): r15 is
# also named pc, so `pc` in arm code is the register, not the current
# address; macros reach the address through exec helpers (rel, arel, trel).

package ARM;

use strict;
use warnings;
use FF qw(node call);
use ISA;

my %REG = map { $_ => 1 } qw(rd rn rm rs rt rt2 ra rdlo rdhi rdn rdm);
my $isa = ISA->new(width => sub {
    my ($name) = @_;
    return "3:0" if $REG{$name} || $name eq "cond";
    die "arm: no width for operand $name\n";
});

# What mkwide.pl reads: one entry per instruction, [name, mode, GNU form,
# params, test values, fields]. mode is a (A32), t (16-bit Thumb), t2
# (Thumb-2); the fields, MSB first, are what gen/s2ff-arm.pl decodes an
# instruction GNU as made by.
our @WIDE;

# Fields that compute their bits (not a plain slice), by name: the brackets
# give the width and the reach of their first operand, for the range check.
my (%custom, @custom);

sub segs {
    my ($list) = @_;
    my @segs = map { /^(\d+)(?::(\d+))?$/ or die "arm: bad bits $list\n"; [$1, $2 // $1] } split /\|/, $list;
    my $pos = 0;
    $pos += $_->[0] - $_->[1] + 1 for @segs;
    map { my ($hi, $lo) = @$_; $pos -= $hi - $lo + 1; [63 - $hi, 63 - $hi + $lo, $pos] } @segs;
}

# The bits of t1 for the field list, as ISA.pm's slices do it.
sub bits_of_t1 {
    my @args = segs(@_);
    return call("bits", "t1", @{ $args[0] }) if @args == 1;
    ((map { (call("bits", "t1", @{ $args[$_] }),
             $_ ? call("or", qw(a0 t0 t0)) : call("addi", qw(0 a0 t0))) } 0 .. $#args),
     call("addi", qw(0 t0 a0)));
}

sub custom_def {
    my ($fn, $bits) = @_;
    my $name = "$fn\[$bits\]";
    return if $custom{$name}++;
    my @body;
    if ($fn eq "up") {            # U: 1 for imm >= 0
        @body = (node("imm"), call("srai", qw(63 imm a0)), call("addi", qw(1 a0 a0)));
    } elsif ($fn eq "mag") {      # bits of |imm|
        @body = (node("imm"), call("srai", qw(63 imm t0)), call("xor", qw(t0 imm a0)),
                 call("sub", qw(t0 a0 t1)), bits_of_t1($bits));
    } elsif ($fn eq "j1" || $fn eq "j2") {   # NOT(I xor S), I = bit 23 / 22, S = bit 24
        @body = (node("imm"), call("srai", $bits, "imm", "t0"), call("srai", qw(24 imm a0)),
                 call("xor", qw(a0 t0 a0)), call("xori", qw(1 a0 a0)));
    } elsif ($fn eq "msb") {      # lsb + width - 1
        @body = (node("lsb"), node("width"), call("add", qw(width lsb a0)), call("addi", qw(-1 a0 a0)));
    } elsif ($fn eq "wm1") {      # width - 1
        @body = (node("width"), call("addi", qw(-1 width a0)));
    } else { die "arm: no custom field $fn\n" }
    push @custom, node("$name:", @body);
}

# A field: "x=0101" fixed, "rd" a register (4 bits), "imm[11:0]" a slice,
# "up[12](imm)" a custom field with its operands.
sub field {
    my ($f) = @_;
    if ($f =~ /^(\w+)\[([\d:|]+)\]\(([\w,]+)\)$/) {
        custom_def($1, $2);
        return call("$1\[$2\]", split /,/, $3);
    }
    $isa->field($f);
}

# The parameters of a GNU form: its placeholders, reversed.
sub params_of {
    my ($gnu) = @_;
    my (%seen, @p);
    while ($gnu =~ /\{(\w+)[^}]*\}/g) { push @p, $1 unless $seen{$1}++ }
    reverse @p;
}

# def(name, mode, GNU form, {param => [test values], params => [...]}, fields...)
sub def {
    my ($name, $mode, $gnu, $test, @fields) = @_;
    $test ||= {};
    my @params = $test->{params} ? @{ $test->{params} } : params_of($gnu);
    my %used;
    for (@fields) {
        next if /=/;
        if (/^\w+\[[\d:|]+\]\(([\w,]+)\)$/) { $used{$_}++ for split /,/, $1 }
        else { (my $p = $_) =~ s/\[.*//; $used{$p}++ }
    }
    for (@params) { die "arm: $name: parameter $_ in no field\n" unless $used{$_} }
    for (keys %used) { my $u = $_; die "arm: $name: field operand $u not a parameter\n" unless grep { $_ eq $u } @params }
    die "arm: $name: more than 8 parameters\n" if @params > 8;
    push @{ $isa->{current}{children} }, node("$name:", (map { node($_) } @params), map { field($_) } @fields);
    push @WIDE, [$name, $mode, $gnu, \@params, $test, [@fields]];
}

# A32: the condition first, always (1110) and, with $if, a twin name.if
# with the condition as the first operand. AX gives a form the twin where
# %IFX names it: the conditional forms glibc's arm asm has (s2ff-arm.pl).
my %IFX = map { $_ => 1 } qw(subsi rsbi add.lsr strb.pre strb.post ldrb.pre ldrb.post ldr.post str.post
    ldrh.post strh.post ldrd.post stmia.wb);
my @CONDS = qw(eq ne cs cc mi pl vs vc hi ls ge lt gt le);
sub A {
    my ($name, $gnu, $test, @fields) = @_;
    def($name, "a", $gnu, $test, "cond=1110", @fields);
}
sub Aif {
    my ($name, $gnu, $test, @fields) = @_;
    A($name, $gnu, $test, @fields);
    my %t = %{ $test || {} };
    $t{params} = ["cond", $t{params} ? @{ $t{params} } : params_of($gnu)];
    $t{cond} = [0, 13, 8];
    (my $g = $gnu) =~ s/^(\S+)/$1\{cond}/;
    def("$name.if", "a", $g, \%t, "cond", @fields);
}
sub AX { $IFX{$_[0]} ? Aif(@_) : A(@_) }
# Thumb-2: the halfword with the opcode, then the second; emitted as one
# little-endian word, so the second halfword's fields come first.
sub T2 {
    my ($name, $gnu, $test, $hw1, $hw2) = @_;
    def($name, "t2", $gnu, $test, @$hw2, @$hw1);
}
sub T { def($_[0], "t", @_[1 .. $#_]) }

# ---------------------------------------------------------------------------
# Registers
# ---------------------------------------------------------------------------

my @alias = qw(a1 a2 a3 a4 v1 v2 v3 v4 v5 sb sl fp ip sp lr pc);
$isa->add("registers",
    (map { node("r$_ $alias[$_]:", node(sprintf "%04b", $_)) } 0 .. 15),
    (map { node("s$_ s$_:", node(sprintf "%05b", $_)) } 0 .. 31),
    (map { node("d$_ d$_:", node(sprintf "%05b", $_)) } 0 .. 31),
    # a NEON quadword qN is the doublewords d2N, d2N+1: its fields are d2N's
    (map { node("q$_ q$_:", node(sprintf "%05b", 2 * $_)) } 0 .. 15),
);
my @condnames = (eq => 0, ne => 1, cs => 2, hs => 2, cc => 3, lo => 3, mi => 4, pl => 5,
                 vs => 6, vc => 7, hi => 8, ls => 9, ge => 10, lt => 11, gt => 12, le => 13, al => 14);
$isa->add("conds",
    node("comment", node("The conditions by name, for the .if forms and t.it: a number 0..14.")),
    map { my $i = $_ * 2; node("cond.$condnames[$i]:", call("addi", $condnames[$i + 1], "zero", "a0")) }
        0 .. @condnames / 2 - 1);

# ---------------------------------------------------------------------------
# A32 data processing
# ---------------------------------------------------------------------------

my %DP = (and => "0000", eor => "0001", sub => "0010", rsb => "0011", add => "0100",
          adc => "0101", sbc => "0110", rsc => "0111", tst => "1000", teq => "1001",
          cmp => "1010", cmn => "1011", orr => "1100", mov => "1101", bic => "1110", mvn => "1111");
my %SH = (lsl => "00", lsr => "01", asr => "10", ror => "11");
my %IF = map { $_ => 1 } qw(mov mvn add sub cmp and orr eor);
my $IMM  = { imm8 => [255, 1, 0x3f], rot => [30, 0, 2] };
my $SHI  = { sh => [1, 31] };

for my $group (["data", qw(and eor sub rsb add adc sbc rsc)], ["data2", qw(orr bic mov mvn tst teq cmp cmn)]) {
    my ($g, @ops) = @$group;
    $isa->group($g);
    for my $op (@ops) {
        my $cmp = $op =~ /^(tst|teq|cmp|cmn)$/;
        my $mov = $op =~ /^(mov|mvn)$/;
        for my $s ($cmp ? (1) : (0, 1)) {
            my $m = $op . ($s && !$cmp ? "s" : "");
            my $ops = $cmp ? "{rn}, " : $mov ? "{rd}, " : "{rd}, {rn}, ";
            my @rr = ($cmp ? "rn" : $mov ? "rn=0000" : "rn", $cmp ? "rd=0000" : "rd");
            my $twin = $IF{$op} && ($cmp || !$s) ? \&Aif : \&AX;
            $twin->("${m}i", "$m $ops#{imm8}, {rot}", $IMM, "op=001", "opcode=$DP{$op}", "s=$s", @rr, "rot[4:1]", "imm8[7:0]");
            $twin->($m, "$m $ops\{rm}", undef, "op=000", "opcode=$DP{$op}", "s=$s", @rr, "sh=00000", "type=00", "r=0", "rm");
            for my $t (qw(lsl lsr asr ror)) {
                AX("$m.$t", "$m $ops\{rm}, $t #{sh}", $SHI, "op=000", "opcode=$DP{$op}", "s=$s", @rr, "sh[4:0]", "type=$SH{$t}", "r=0", "rm");
            }
            A("$m.rrx", "$m $ops\{rm}, rrx", undef, "op=000", "opcode=$DP{$op}", "s=$s", @rr, "sh=00000", "type=11", "r=0", "rm");
            for my $t (qw(lsl lsr asr ror)) {
                A("$m.${t}r", "$m $ops\{rm}, $t {rs}", undef, "op=000", "opcode=$DP{$op}", "s=$s", @rr, "rs", "z=0", "type=$SH{$t}", "r=1", "rm");
            }
        }
    }
}

$isa->group("shifts");
# The shifts by their own names, as GNU writes them (mov with a shift).
for my $s (0, 1) {
    my $x = $s ? "s" : "";
    for my $t (qw(lsl lsr asr ror)) {
        A("$t${x}i", "$t$x {rd}, {rm}, #{sh}", $SHI, "op=000", "opcode=1101", "s=$s", "rn=0000", "rd", "sh[4:0]", "type=$SH{$t}", "r=0", "rm");
        A("$t$x", "$t$x {rd}, {rm}, {rs}", undef, "op=000", "opcode=1101", "s=$s", "rn=0000", "rd", "rs", "z=0", "type=$SH{$t}", "r=1", "rm");
    }
    A("rrx$x", "rrx$x {rd}, {rm}", undef, "op=000", "opcode=1101", "s=$s", "rn=0000", "rd", "sh=00000", "type=11", "r=0", "rm");
}

# ---------------------------------------------------------------------------
# A32 multiply, divide, moves of 16 bits, bit operations
# ---------------------------------------------------------------------------

$isa->group("multiply");
for my $s (0, 1) {
    my $x = $s ? "s" : "";
    A("mul$x", "mul$x {rd}, {rn}, {rm}", undef, "op=000000", "a=0", "s=$s", "rd", "z=0000", "rm", "x=1001", "rn");
    A("mla$x", "mla$x {rd}, {rn}, {rm}, {ra}", undef, "op=000000", "a=1", "s=$s", "rd", "ra", "rm", "x=1001", "rn");
    for my $l (["umull", "00"], ["umlal", "01"], ["smull", "10"], ["smlal", "11"]) {
        A("$l->[0]$x", "$l->[0]$x {rdlo}, {rdhi}, {rn}, {rm}", undef, "op=00001", "ua=$l->[1]", "s=$s", "rdhi", "rdlo", "rm", "x=1001", "rn");
    }
}
A("mls", "mls {rd}, {rn}, {rm}, {ra}", undef, "op=00000110", "rd", "ra", "rm", "x=1001", "rn");
A("sdiv", "sdiv {rd}, {rn}, {rm}", undef, "op=01110001", "rd", "x=1111", "rm", "y=0001", "rn");
A("udiv", "udiv {rd}, {rn}, {rm}", undef, "op=01110011", "rd", "x=1111", "rm", "y=0001", "rn");
my $IMM16 = { imm16 => [0, 65535, 0x1234] };
Aif("movw", "movw {rd}, #{imm16}", $IMM16, "op=00110000", "imm16[15:12]", "rd", "imm16[11:0]");
Aif("movt", "movt {rd}, #{imm16}", $IMM16, "op=00110100", "imm16[15:12]", "rd", "imm16[11:0]");

$isa->group("bits");
A("clz",   "clz {rd}, {rm}",   undef, "op=00010110", "x=1111", "rd", "y=1111", "z=0001", "rm");
A("rev",   "rev {rd}, {rm}",   undef, "op=01101011", "x=1111", "rd", "y=1111", "z=0011", "rm");
A("rev16", "rev16 {rd}, {rm}", undef, "op=01101011", "x=1111", "rd", "y=1111", "z=1011", "rm");
A("revsh", "revsh {rd}, {rm}", undef, "op=01101111", "x=1111", "rd", "y=1111", "z=1011", "rm");
A("rbit",  "rbit {rd}, {rm}",  undef, "op=01101111", "x=1111", "rd", "y=1111", "z=0011", "rm");
my $ROT = { rot => [8, 24, 16] };
for my $x (["sxtb", "01101010"], ["sxth", "01101011"], ["uxtb", "01101110"], ["uxth", "01101111"]) {
    A($x->[0], "$x->[0] {rd}, {rm}, ror #{rot}", $ROT, "op=$x->[1]", "x=1111", "rd", "rot[4:3]", "z=000111", "rm");
}
my $BF = { lsb => [0, 31, 4], width => [32, 1, 8] };
A("bfc", "bfc {rd}, #{lsb}, #{width}", $BF, "op=0111110", "msb[4:0](lsb,width)", "rd", "lsb[4:0]", "x=0011111");
A("bfi", "bfi {rd}, {rn}, #{lsb}, #{width}", $BF, "op=0111110", "msb[4:0](lsb,width)", "rd", "lsb[4:0]", "x=001", "rn");
my $BX = { lsb => [0, 31, 4], width => [31, 1, 8] };
A("ubfx", "ubfx {rd}, {rn}, #{lsb}, #{width}", $BX, "op=0111111", "wm1[4:0](width)", "rd", "lsb[4:0]", "x=101", "rn");
A("sbfx", "sbfx {rd}, {rn}, #{lsb}, #{width}", $BX, "op=0111101", "wm1[4:0](width)", "rd", "lsb[4:0]", "x=101", "rn");

# ---------------------------------------------------------------------------
# A32 loads and stores
# ---------------------------------------------------------------------------

$isa->group("memory");
my $OFF12 = { imm => [-4095, 4095, 0] };
my $OFFR  = { sh => [0, 31, 2] };
my $OFFRP = { sh => [1, 31] };
for my $x (["str", 0, 0], ["ldr", 0, 1], ["strb", 1, 0], ["ldrb", 1, 1]) {
    my ($m, $b, $l) = @$x;
    Aif($m, "$m {rt}, [{rn}, #{imm}]", $OFF12, "op=010", "p=1", "up[12](imm)", "b=$b", "w=0", "l=$l", "rn", "rt", "mag[11:0](imm)");
    AX("$m.pre",  "$m {rt}, [{rn}, #{imm}]!", $OFF12, "op=010", "p=1", "up[12](imm)", "b=$b", "w=1", "l=$l", "rn", "rt", "mag[11:0](imm)");
    AX("$m.post", "$m {rt}, [{rn}], #{imm}",  $OFF12, "op=010", "p=0", "up[12](imm)", "b=$b", "w=0", "l=$l", "rn", "rt", "mag[11:0](imm)");
    A("${m}r",      "$m {rt}, [{rn}, {rm}, lsl #{sh}]",  $OFFR,  "op=011", "p=1", "u=1", "b=$b", "w=0", "l=$l", "rn", "rt", "sh[4:0]", "type=00", "z=0", "rm");
    A("${m}r.pre",  "$m {rt}, [{rn}, {rm}, lsl #{sh}]!", $OFFRP, "op=011", "p=1", "u=1", "b=$b", "w=1", "l=$l", "rn", "rt", "sh[4:0]", "type=00", "z=0", "rm");
    A("${m}r.post", "$m {rt}, [{rn}], {rm}, lsl #{sh}",  $OFFRP, "op=011", "p=0", "u=1", "b=$b", "w=0", "l=$l", "rn", "rt", "sh[4:0]", "type=00", "z=0", "rm");
}
my $OFF8 = { imm => [-255, 255, 0] };
my $DT   = { rt => [0, 10, 4], rn => [3, 12, 1] };
my $DT8  = { %$OFF8, %$DT };
for my $x (["strh", 0, "1011"], ["ldrd", 0, "1101"], ["strd", 0, "1111"],
           ["ldrh", 1, "1011"], ["ldrsb", 1, "1101"], ["ldrsh", 1, "1111"]) {
    my ($m, $l, $sh) = @$x;
    my $d = $m =~ /d$/;
    my $rt = $d ? "{rt}, {rt+1}" : "{rt}";
    my $t8 = $d ? $DT8 : $OFF8;
    my $tr = $d ? { rt => [0, 10], rn => [3, 12], rm => [5, 1] } : undef;
    A($m,        "$m $rt, [{rn}, #{imm}]",  $t8, "op=000", "p=1", "up[8](imm)", "i=1", "w=0", "l=$l", "rn", "rt", "mag[7:4](imm)", "x=$sh", "mag[3:0](imm)");
    A("$m.pre",  "$m $rt, [{rn}, #{imm}]!", $t8, "op=000", "p=1", "up[8](imm)", "i=1", "w=1", "l=$l", "rn", "rt", "mag[7:4](imm)", "x=$sh", "mag[3:0](imm)");
    AX("$m.post", "$m $rt, [{rn}], #{imm}",  $t8, "op=000", "p=0", "up[8](imm)", "i=1", "w=0", "l=$l", "rn", "rt", "mag[7:4](imm)", "x=$sh", "mag[3:0](imm)");
    A("${m}r",      "$m $rt, [{rn}, {rm}]",  $tr, "op=000", "p=1", "u=1", "i=0", "w=0", "l=$l", "rn", "rt", "z=0000", "x=$sh", "rm");
    A("${m}r.pre",  "$m $rt, [{rn}, {rm}]!", $tr, "op=000", "p=1", "u=1", "i=0", "w=1", "l=$l", "rn", "rt", "z=0000", "x=$sh", "rm");
    A("${m}r.post", "$m $rt, [{rn}], {rm}",  $tr, "op=000", "p=0", "u=1", "i=0", "w=0", "l=$l", "rn", "rt", "z=0000", "x=$sh", "rm");
}
my $LM = { rn => [0, 12], regs => [0x5ffe, 0x0ffe] };
for my $x (["ia", "01"], ["ib", "11"], ["da", "00"], ["db", "10"]) {
    my ($am, $pu) = @$x;
    for my $l (0, 1) {
        my $m = ($l ? "ldm" : "stm") . $am;
        A($m,       "$m {rn}, {regs}",  $LM, "op=100", "pu=$pu", "s=0", "w=0", "l=$l", "rn", "regs[15:0]");
        AX("$m.wb",  "$m {rn}!, {regs}", $LM, "op=100", "pu=$pu", "s=0", "w=1", "l=$l", "rn", "regs[15:0]");
    }
}
A("push", "push {regs}", { regs => [0x5ff0, 0x0003] }, "op=100100101101", "regs[15:0]");
A("pop",  "pop {regs}",  { regs => [0x9ff0, 0x0003] }, "op=100010111101", "regs[15:0]");

$isa->group("atomic");
my $EX = { rt => [0, 10], rn => [3, 12] };
A("ldrex",  "ldrex {rt}, [{rn}]",  undef, "op=00011001", "rn", "rt", "x=111110011111");
A("ldrexb", "ldrexb {rt}, [{rn}]", undef, "op=00011101", "rn", "rt", "x=111110011111");
A("ldrexh", "ldrexh {rt}, [{rn}]", undef, "op=00011111", "rn", "rt", "x=111110011111");
A("ldrexd", "ldrexd {rt}, {rt+1}, [{rn}]", $EX, "op=00011011", "rn", "rt", "x=111110011111");
A("strex",  "strex {rd}, {rt}, [{rn}]",  undef, "op=00011000", "rn", "rd", "x=11111001", "rt");
A("strexb", "strexb {rd}, {rt}, [{rn}]", undef, "op=00011100", "rn", "rd", "x=11111001", "rt");
A("strexh", "strexh {rd}, {rt}, [{rn}]", undef, "op=00011110", "rn", "rd", "x=11111001", "rt");
A("strexd", "strexd {rd}, {rt}, {rt+1}, [{rn}]", { rt => [0, 10], rn => [3, 12], rd => [5, 1] },
  "op=00011010", "rn", "rd", "x=11111001", "rt");
def("clrex", "a", "clrex", undef, "x=11110101011111111111000000011111");
my $OPT = { option => [15, 14, 11, 10, 7, 6, 3, 2] };
def("dmb", "a", "dmb {option}", $OPT, "x=1111010101111111111100000101", "option[3:0]");
def("dsb", "a", "dsb {option}", $OPT, "x=1111010101111111111100000100", "option[3:0]");
def("isb", "a", "isb {option}", { option => [15] }, "x=1111010101111111111100000110", "option[3:0]");

# ---------------------------------------------------------------------------
# A32 branches and system
# ---------------------------------------------------------------------------

$isa->group("branch");
my $B24 = { imm => [-33554432, 33554428, 0] };
A("b", "b {imm^8}", $B24, "op=1010", "imm[25:2]");
Aif("bl", "bl {imm^8}", $B24, "op=1011", "imm[25:2]");
my %cc = (eq => 0, ne => 1, cs => 2, hs => 2, cc => 3, lo => 3, mi => 4, pl => 5, vs => 6,
          vc => 7, hi => 8, ls => 9, ge => 10, lt => 11, gt => 12, le => 13);
my @CC = qw(eq ne cs hs cc lo mi pl vs vc hi ls ge lt gt le);
for my $c (@CC) {
    def("b$c", "a", "b$c {imm^8}", $B24, sprintf("cond=%04b", $cc{$c}), "op=1010", "imm[25:2]");
}
Aif("bx",  "bx {rm}",  undef, "op=000100101111111111110001", "rm");
Aif("blx", "blx {rm}", undef, "op=000100101111111111110011", "rm");
def("blxi", "a", "blx {imm^8}", { imm => [-33554432, 33554430, 2] }, "op=1111101", "imm[1]", "imm[25:2]");

$isa->group("system");
Aif("svc", "svc #{uimm}", { uimm => [0, 0xffffff] }, "op=1111", "uimm[23:0]");
A("mrs",      "mrs {rd}, cpsr", undef, "op=00010000", "x=1111", "rd", "z=000000000000");
A("mrs.spsr", "mrs {rd}, spsr", undef, "op=00010100", "x=1111", "rd", "z=000000000000");
my $MSK = { mask => [8, 9, 15] };
A("msr",      "msr cpsr_{mask}, {rm}", $MSK, "op=00010010", "mask[3:0]", "x=111100000000", "rm");
A("msr.spsr", "msr spsr_{mask}, {rm}", $MSK, "op=00010110", "mask[3:0]", "x=111100000000", "rm");
my $MSKI = { %$MSK, %$IMM, params => [qw(rot imm8 mask)] };
A("msri",      "msr cpsr_{mask}, #{imm8|rot}", $MSKI, "op=00110010", "mask[3:0]", "x=1111", "rot[4:1]", "imm8[7:0]");
A("msri.spsr", "msr spsr_{mask}, #{imm8|rot}", $MSKI, "op=00110110", "mask[3:0]", "x=1111", "rot[4:1]", "imm8[7:0]");
my $AIF = { aif => [7, 1, 4] };
def("cpsie", "a", "cpsie {aif}", $AIF, "op=111100010000", "imod=10", "m=0", "x=00000000", "aif[2:0]", "z=0", "mode=00000");
def("cpsid", "a", "cpsid {aif}", $AIF, "op=111100010000", "imod=11", "m=0", "x=00000000", "aif[2:0]", "z=0", "mode=00000");
def("cps", "a", "cps #{mode}", { mode => [16, 31, 19] }, "op=111100010000", "imod=00", "m=1", "x=00000000", "aif=000", "z=0", "mode[4:0]");
my $i = 0;
A($_, $_, undef, "op=0011001000001111000000000", sprintf("hint=%03b", $i++)) for qw(nop yield wfe wfi sev);
def("bkpt", "a", "bkpt #{uimm}", { uimm => [0, 65535, 0x1234] }, "op=111000010010", "uimm[15:4]", "x=0111", "uimm[3:0]");
def("udf",  "a", "udf #{uimm}",  { uimm => [0, 65535, 0x1234] }, "op=111001111111", "uimm[15:4]", "x=1111", "uimm[3:0]");

# ---------------------------------------------------------------------------
# VFPv3: f32 on s0..s31, f64 on d0..d31
# ---------------------------------------------------------------------------

$isa->group("vfp");
# The register fields: a single sN is Vx = N[4:1], its extra bit N[0]; a
# double dN is Vx = N[3:0], its extra bit N[4].
sub vD { $_[0] =~ /^s/ ? ("$_[0]\[0]", "$_[0]\[4:1]") : ("$_[0]\[4]", "$_[0]\[3:0]") }
sub vV { $_[0] =~ /^s/ ? "$_[0]\[4:1]" : "$_[0]\[3:0]" }
sub vX { $_[0] =~ /^s/ ? "$_[0]\[0]" : "$_[0]\[4]" }
for my $p (["f32", "0", "s"], ["f64", "1", "d"]) {
    my ($t, $sz, $r) = @$p;
    my ($d, $n, $m) = ("${r}d", "${r}n", "${r}m");
    for my $x (["vmla", "0", "00", "0"], ["vmls", "0", "00", "1"], ["vnmul", "0", "10", "1"],
               ["vmul", "0", "10", "0"], ["vadd", "0", "11", "0"], ["vsub", "0", "11", "1"],
               ["vdiv", "1", "00", "0"]) {
        my ($op, $o1, $o2, $o3) = @$x;
        A("$op.$t", "$op.$t {$d}, {$n}, {$m}", undef, "op=1110", "o1=$o1", vX($d), "o2=$o2", vV($n), vV($d),
          "x=101", "sz=$sz", vX($n), "o3=$o3", vX($m), "z=0", vV($m));
    }
    for my $x (["vmov", "0000", "01"], ["vabs", "0000", "11"], ["vneg", "0001", "01"],
               ["vsqrt", "0001", "11"], ["vcmp", "0100", "01"], ["vcmpe", "0100", "11"]) {
        my ($op, $opc2, $o) = @$x;
        A("$op.$t", "$op.$t {$d}, {$m}", undef, "op=11101", vX($d), "o2=11", "opc2=$opc2", vV($d),
          "x=101", "sz=$sz", "o=$o", vX($m), "z=0", vV($m));
    }
    for my $x (["vcmp", "01"], ["vcmpe", "11"]) {
        A("$x->[0].${t}z", "$x->[0].$t {$d}, #0", undef, "op=11101", vX($d), "o2=11", "opc2=0101", vV($d),
          "x=101", "sz=$sz", "o=$x->[1]", "z=000000");
    }
    A("vmov.${t}i", "vmov.$t {$d}, #{uimm8%$t}", { uimm8 => [0x70, 0x00, 0xff, 0x80] }, "op=11101", vX($d), "o2=11",
      "uimm8[7:4]", vV($d), "x=101", "sz=$sz", "z=0000", "uimm8[3:0]");
    # vcvt between integer (in a single) and this format
    A("vcvt.s32.$t", "vcvt.s32.$t {sd}, {$m}", undef, "op=11101", vX("sd"), "o2=11", "opc2=1101", vV("sd"),
      "x=101", "sz=$sz", "o=11", vX($m), "z=0", vV($m));
    A("vcvt.u32.$t", "vcvt.u32.$t {sd}, {$m}", undef, "op=11101", vX("sd"), "o2=11", "opc2=1100", vV("sd"),
      "x=101", "sz=$sz", "o=11", vX($m), "z=0", vV($m));
    A("vcvt.$t.s32", "vcvt.$t.s32 {$d}, {sm}", undef, "op=11101", vX($d), "o2=11", "opc2=1000", vV($d),
      "x=101", "sz=$sz", "o=11", vX("sm"), "z=0", vV("sm"));
    A("vcvt.$t.u32", "vcvt.$t.u32 {$d}, {sm}", undef, "op=11101", vX($d), "o2=11", "opc2=1000", vV($d),
      "x=101", "sz=$sz", "o=01", vX("sm"), "z=0", vV("sm"));
}
A("vcvt.f64.f32", "vcvt.f64.f32 {dd}, {sm}", undef, "op=11101", vX("dd"), "o2=11", "opc2=0111", vV("dd"),
  "x=101", "sz=0", "o=11", vX("sm"), "z=0", vV("sm"));
A("vcvt.f32.f64", "vcvt.f32.f64 {sd}, {dm}", undef, "op=11101", vX("sd"), "o2=11", "opc2=0111", vV("sd"),
  "x=101", "sz=1", "o=11", vX("dm"), "z=0", vV("dm"));
my $VOFF = { imm => [-1020, 1020, 0] };
for my $p (["32", "0", "sd"], ["64", "1", "dd"]) {
    my ($w, $sz, $d) = @$p;
    A("vldr.$w", "vldr.$w {$d}, [{rn}, #{imm}]", $VOFF, "op=1101", "up[10](imm)", vX($d), "x=01", "rn", vV($d),
      "y=101", "sz=$sz", "mag[9:2](imm)");
    A("vstr.$w", "vstr.$w {$d}, [{rn}, #{imm}]", $VOFF, "op=1101", "up[10](imm)", vX($d), "x=00", "rn", vV($d),
      "y=101", "sz=$sz", "mag[9:2](imm)");
}
my $VPS = { params => ["sd", "n"], sd => [0, 16, 31], n => [32, 16, 1] };
my $VPD = { params => ["dd", "n"], dd => [0, 16, 8, 31], n => [16, 16, 8, 1] };
A("vpush.32", "vpush.32 {sd~n}", $VPS, "op=11010", vX("sd"), "x=101101", vV("sd"), "y=1010", "n[7:0]");
A("vpop.32",  "vpop.32 {sd~n}",  $VPS, "op=11001", vX("sd"), "x=111101", vV("sd"), "y=1010", "n[7:0]");
A("vpush.64", "vpush.64 {dd~n}", $VPD, "op=11010", vX("dd"), "x=101101", vV("dd"), "y=1011", "n[6:0]", "z=0");
A("vpop.64",  "vpop.64 {dd~n}",  $VPD, "op=11001", vX("dd"), "x=111101", vV("dd"), "y=1011", "n[6:0]", "z=0");
A("vmov.sr", "vmov {sn}, {rt}", undef, "op=1110000", "o=0", vV("sn"), "rt", "x=1010", vX("sn"), "y=0010000");
A("vmov.rs", "vmov {rt}, {sn}", undef, "op=1110000", "o=1", vV("sn"), "rt", "x=1010", vX("sn"), "y=0010000");
A("vmov.drr", "vmov {dm}, {rt}, {rt2}", undef, "op=1100010", "o=0", "rt2", "rt", "x=101100", vX("dm"), "y=1", vV("dm"));
A("vmov.rrd", "vmov {rt}, {rt2}, {dm}", undef, "op=1100010", "o=1", "rt2", "rt", "x=101100", vX("dm"), "y=1", vV("dm"));
A("vmrs", "vmrs {rt}, fpscr", undef, "op=111011110001", "rt", "x=101000010000");
A("vmrs.nzcv", "vmrs APSR_nzcv, fpscr", undef, "op=111011110001", "rt=1111", "x=101000010000");
A("vmsr", "vmsr fpscr, {rt}", undef, "op=111011100001", "rt", "x=101000010000");

# ---------------------------------------------------------------------------
# What glibc's arm asm has besides: preload, parallel bytes, coprocessor
# moves and loads (mrc; iWMMXt's ldcl/stcl in setjmp), VFP load/store
# multiple, and the NEON of memcpy_neon and memchr_neon. A NEON operation
# on quadwords takes qN (its d2N's fields); a structure load or store
# names its first register, its alignment (al: 0, or 1 2 3 for :64 :128
# :256) and the base it writes back (!).
# ---------------------------------------------------------------------------

$isa->group("a32x");
def("pld", "a", "pld [{rn}, #{imm}]", $OFF12, "op=11110101", "up[12](imm)", "x=101", "rn", "y=1111", "mag[11:0](imm)");
A("uqsub8", "uqsub8 {rd}, {rn}, {rm}", undef, "op=01100110", "rn", "rd", "x=11111111", "rm");
A("uadd8", "uadd8 {rd}, {rn}, {rm}", undef, "op=01100101", "rn", "rd", "x=11111001", "rm");
A("sel", "sel {rd}, {rn}, {rm}", undef, "op=01101000", "rn", "rd", "x=11111011", "rm");
my $CP = { coproc => [15, 14], opc1 => [0, 7], crn => [13, 0], crm => [0, 15], opc2 => [3, 0] };
A("mrc", "mrc p{coproc}, {opc1}, {rt}, c{crn}, c{crm}, {opc2}", $CP, "op=1110", "opc1[2:0]", "x=1", "crn[3:0]", "rt", "coproc[3:0]", "opc2[2:0]", "y=1", "crm[3:0]");
A("mcr", "mcr p{coproc}, {opc1}, {rt}, c{crn}, c{crm}, {opc2}", $CP, "op=1110", "opc1[2:0]", "x=0", "crn[3:0]", "rt", "coproc[3:0]", "opc2[2:0]", "y=1", "crm[3:0]");
my $CPL = { coproc => [1, 14], crd => [10, 15, 0], uimm => [8, 0, 1020] };
A("ldcl.post", "ldcl p{coproc}, c{crd}, [{rn}], #{uimm}", $CPL, "op=110", "p=0", "u=1", "n=1", "w=1", "l=1", "rn", "crd[3:0]", "coproc[3:0]", "uimm[9:2]");
A("stcl.post", "stcl p{coproc}, c{crd}, [{rn}], #{uimm}", $CPL, "op=110", "p=0", "u=1", "n=1", "w=1", "l=0", "rn", "crd[3:0]", "coproc[3:0]", "uimm[9:2]");
# (and ldc2/stc2, unconditional (1111), libgcc's libunwind.S's iWMMXt
# control registers)
def("ldc2.post", "a", "ldc2 p{coproc}, c{crd}, [{rn}], #{uimm}", $CPL, "op=1111110", "p=0", "u=1", "n=0", "w=1", "l=1", "rn", "crd[3:0]", "coproc[3:0]", "uimm[9:2]");
def("stc2.post", "a", "stc2 p{coproc}, c{crd}, [{rn}], #{uimm}", $CPL, "op=1111110", "p=0", "u=1", "n=0", "w=1", "l=0", "rn", "crd[3:0]", "coproc[3:0]", "uimm[9:2]");
my $VLM = { params => ["dd", "n", "rn"], dd => [8, 0, 16], n => [8, 1, 16] };
A("vldmia.64", "vldmia {rn}!, {dd~n}", $VLM, "op=11001", vX("dd"), "w=1", "l=1", "rn", vV("dd"), "x=1011", "n[6:0]", "z=0");
A("vstmia.64", "vstmia {rn}!, {dd~n}", $VLM, "op=11001", vX("dd"), "w=1", "l=0", "rn", vV("dd"), "x=1011", "n[6:0]", "z=0");
# (without writeback, and the FLDMX/FSTMX format of the same, whose
# imm8 is odd: libgcc's libunwind.S's saves and restores of d0..d31)
A("vldmia.64n", "vldmia {rn}, {dd~n}", $VLM, "op=11001", vX("dd"), "w=0", "l=1", "rn", vV("dd"), "x=1011", "n[6:0]", "z=0");
A("vstmia.64n", "vstmia {rn}, {dd~n}", $VLM, "op=11001", vX("dd"), "w=0", "l=0", "rn", vV("dd"), "x=1011", "n[6:0]", "z=0");
A("fldmiax", "fldmiax {rn}, {dd~n}", $VLM, "op=11001", vX("dd"), "w=0", "l=1", "rn", vV("dd"), "x=1011", "n[6:0]", "z=1");
A("fstmiax", "fstmiax {rn}, {dd~n}", $VLM, "op=11001", vX("dd"), "w=0", "l=0", "rn", vV("dd"), "x=1011", "n[6:0]", "z=1");
A("vmov.32rd", "vmov.32 {rt}, {dn}[{lane}]", { lane => [0, 1] }, "op=1110", "u=0", "o=0", "lane[0]", "l=1", vV("dn"), "rt", "x=1011", vX("dn"), "opc2=00", "y=1", "z=0000");
A("vdup.8q", "vdup.8 {qd}, {rt}", undef, "op=11101", "b=1", "q=1", "z=0", vV("qd"), "rt", "x=1011", vX("qd"), "y=0", "e=0", "w=1", "v=0000");
# NEON operations: A32 1111 001U, Thumb-2 111U 1111, then the same
my @NEON;
sub N3 {   # name, GNU, U, the bits 21:20, the opcode bits 11:8, Q, the registers' prefix (d or q)
    my ($name, $gnu, $u, $sz, $opc, $q, $r) = @_;
    my ($d, $n, $m) = map { "$r$_" } qw(d n m);
    my @rest = ("z=0", vX($d), "sz=$sz", vV($n), vV($d), "opc=$opc", vX($n), "q=$q", vX($m), "o=1", vV($m));
    def($name, "a", $gnu, undef, "op=1111001", "u=$u", @rest);
    push @NEON, ["t2.$name", $gnu, undef, ["op=111", "u=$u", "x=1111", @rest[0 .. 3]], [@rest[4 .. $#rest]]];
}
N3("vand.q", "vand {qd}, {qn}, {qm}", 0, "00", "0001", 1, "q");
N3("vand.d", "vand {dd}, {dn}, {dm}", 0, "00", "0001", 0, "d");
N3("vorr.q", "vorr {qd}, {qn}, {qm}", 0, "10", "0001", 1, "q");
N3("vorr.d", "vorr {dd}, {dn}, {dm}", 0, "10", "0001", 0, "d");
N3("vceq.i8.q", "vceq.i8 {qd}, {qn}, {qm}", 1, "00", "1000", 1, "q");
N3("vpadd.i8", "vpadd.i8 {dd}, {dn}, {dm}", 0, "00", "1011", 0, "d");
# vld1.8 / vst1.8 of 1 to 4 doublewords, the base written back: A32 1111 0100, Thumb-2 1111 1001
my %VT = (1 => "0111", 2 => "1010", 3 => "0110", 4 => "0010");
for my $l (1, 0) {
    my $op = $l ? "vld1.8" : "vst1.8";
    for my $k (1 .. 4) {
        # (the alignments GNU as takes: :64 for one or three, up to :128 for two, :256 for four)
        my $t = { params => ["al", "rn", "dd"], al => [[0, 1], [0, 1, 2], [0, 1], [0, 1, 2, 3]]->[$k - 1], dd => [0, 4, 8, 28 - $k] };
        my @rest = ("z=0", vX("dd"), "l=$l", "y=0", "rn", vV("dd"), "type=$VT{$k}", "size=00", "al[1:0]", "rm=1101");
        def("$op.$k", "a", "$op {dd~$k}, [{rn}{al@}]!", $t, "op=11110100", @rest);
        push @NEON, ["t2.$op.$k", "$op {dd~$k}, [{rn}{al@}]!", $t, ["op=11111001", @rest[0 .. 4]], [@rest[5 .. $#rest]]];
    }
}

# ---------------------------------------------------------------------------
# Thumb, 16 bits: low registers r0..r7 are 3-bit fields
# ---------------------------------------------------------------------------

$isa->group("thumb");
my %T = (rd => "rd[2:0]", rn => "rn[2:0]", rm => "rm[2:0]", rt => "rt[2:0]", rdn => "rdn[2:0]", rdm => "rdm[2:0]");
sub lo { map { $T{$_} // $_ } @_ }
my $SH5 = { uimm => [1, 31] };
T("t.lslsi", "lsls {rd}, {rm}, #{uimm}", $SH5, lo("op=00000", "uimm[4:0]", "rm", "rd"));
T("t.lsrsi", "lsrs {rd}, {rm}, #{uimm}", $SH5, lo("op=00001", "uimm[4:0]", "rm", "rd"));
T("t.asrsi", "asrs {rd}, {rm}, #{uimm}", $SH5, lo("op=00010", "uimm[4:0]", "rm", "rd"));
T("t.adds", "adds {rd}, {rn}, {rm}", undef, lo("op=0001100", "rm", "rn", "rd"));
T("t.subs", "subs {rd}, {rn}, {rm}", undef, lo("op=0001101", "rm", "rn", "rd"));
T("t.addsi", "adds {rd}, {rn}, #{uimm}", { uimm => [0, 7] }, lo("op=0001110", "uimm[2:0]", "rn", "rd"));
T("t.subsi", "subs {rd}, {rn}, #{uimm}", { uimm => [0, 7] }, lo("op=0001111", "uimm[2:0]", "rn", "rd"));
my $U8 = { uimm => [0, 255] };
T("t.movsi",  "movs {rd}, #{uimm}", $U8, lo("op=00100", "rd", "uimm[7:0]"));
T("t.cmpi",   "cmp {rn}, #{uimm}",  $U8, lo("op=00101", "rn", "uimm[7:0]"));
T("t.addsi8", "adds {rdn}, #{uimm}", $U8, lo("op=00110", "rdn", "uimm[7:0]"));
T("t.subsi8", "subs {rdn}, #{uimm}", $U8, lo("op=00111", "rdn", "uimm[7:0]"));
my $j = 0;
for my $m (qw(ands eors lsls lsrs asrs adcs sbcs rors tst rsbs cmp cmn orrs muls bics mvns)) {
    my $op = sprintf "op=010000%04b", $j++;
    if    ($m =~ /^(tst|cmp|cmn)$/) { T("t.$m", "$m {rn}, {rm}", undef, lo($op, "rm", "rn")) }
    elsif ($m eq "rsbs") { T("t.rsbs", "rsbs {rd}, {rn}, #0", undef, lo($op, "rn", "rd")) }
    elsif ($m eq "mvns") { T("t.mvns", "mvns {rd}, {rm}", undef, lo($op, "rm", "rd")) }
    elsif ($m eq "muls") { T("t.muls", "muls {rdm}, {rn}, {rdm}", undef, lo($op, "rn", "rdm")) }
    else  { T("t.$m", "$m {rdn}, {rm}", undef, lo($op, "rm", "rdn")) }
}
my $HI = { rdn => [8, 12, 1], rd => [8, 12, 1], rn => [8, 12, 1], rm => [9, 14, 10] };
T("t.add",   "add {rdn}, {rm}", $HI, "op=01000100", "rdn[3]", "rm[3:0]", "rdn[2:0]");
T("t.cmphi", "cmp {rn}, {rm}",  $HI, "op=01000101", "rn[3]",  "rm[3:0]", "rn[2:0]");
T("t.mov",   "mov {rd}, {rm}",  $HI, "op=01000110", "rd[3]",  "rm[3:0]", "rd[2:0]");
T("t.bx",    "bx {rm}",  undef, "op=010001110", "rm[3:0]", "z=000");
T("t.blx",   "blx {rm}", undef, "op=010001111", "rm[3:0]", "z=000");
T("t.ldrl",  "ldr {rt}, [pc, #{uimm}]", { uimm => [0, 1020] }, lo("op=01001", "rt", "uimm[9:2]"));
$j = 0;
for my $m (qw(str strh strb ldrsb ldr ldrh ldrb ldrsh)) {
    T("t.${m}r", "$m {rt}, [{rn}, {rm}]", undef, lo(sprintf("op=0101%03b", $j++), "rm", "rn", "rt"));
}
T("t.str",  "str {rt}, [{rn}, #{uimm}]",  { uimm => [0, 124] }, lo("op=01100", "uimm[6:2]", "rn", "rt"));
T("t.ldr",  "ldr {rt}, [{rn}, #{uimm}]",  { uimm => [0, 124] }, lo("op=01101", "uimm[6:2]", "rn", "rt"));
T("t.strb", "strb {rt}, [{rn}, #{uimm}]", { uimm => [0, 31] },  lo("op=01110", "uimm[4:0]", "rn", "rt"));
T("t.ldrb", "ldrb {rt}, [{rn}, #{uimm}]", { uimm => [0, 31] },  lo("op=01111", "uimm[4:0]", "rn", "rt"));
T("t.strh", "strh {rt}, [{rn}, #{uimm}]", { uimm => [0, 62] },  lo("op=10000", "uimm[5:1]", "rn", "rt"));
T("t.ldrh", "ldrh {rt}, [{rn}, #{uimm}]", { uimm => [0, 62] },  lo("op=10001", "uimm[5:1]", "rn", "rt"));
my $SP8 = { uimm => [0, 1020] };
T("t.strsp", "str {rt}, [sp, #{uimm}]", $SP8, lo("op=10010", "rt", "uimm[9:2]"));
T("t.ldrsp", "ldr {rt}, [sp, #{uimm}]", $SP8, lo("op=10011", "rt", "uimm[9:2]"));
T("t.adr",   "add {rd}, pc, #{uimm}",    $SP8, lo("op=10100", "rd", "uimm[9:2]"));
T("t.addsp", "add {rd}, sp, #{uimm}",   $SP8, lo("op=10101", "rd", "uimm[9:2]"));
T("t.addspi", "add sp, sp, #{uimm}", { uimm => [0, 508] }, "op=101100000", "uimm[8:2]");
T("t.subspi", "sub sp, sp, #{uimm}", { uimm => [0, 508] }, "op=101100001", "uimm[8:2]");
T("t.cbz",  "cbz {rn}, {uimm^4}",  { uimm => [0, 126] }, lo("op=101100", "uimm[6]", "x=1", "uimm[5:1]", "rn"));
T("t.cbnz", "cbnz {rn}, {uimm^4}", { uimm => [0, 126] }, lo("op=101110", "uimm[6]", "x=1", "uimm[5:1]", "rn"));
$j = 0;
T("t.$_", "$_ {rd}, {rm}", undef, lo(sprintf("op=10110010%02b", $j++), "rm", "rd")) for qw(sxth sxtb uxth uxtb);
T("t.push", "push {regs}", { regs => [0x40ff, 0x0001, 0x4000] }, "op=1011010", "regs[14]", "regs[7:0]");
T("t.pop",  "pop {regs}",  { regs => [0x80ff, 0x0080, 0x8000] }, "op=1011110", "regs[15]", "regs[7:0]");
T("t.cpsie", "cpsie {aif}", $AIF, "op=10110110011", "im=0", "z=0", "aif[2:0]");
T("t.cpsid", "cpsid {aif}", $AIF, "op=10110110011", "im=1", "z=0", "aif[2:0]");
T("t.rev",   "rev {rd}, {rm}",   undef, lo("op=1011101000", "rm", "rd"));
T("t.rev16", "rev16 {rd}, {rm}", undef, lo("op=1011101001", "rm", "rd"));
T("t.revsh", "revsh {rd}, {rm}", undef, lo("op=1011101011", "rm", "rd"));
T("t.bkpt", "bkpt #{uimm}", $U8, "op=10111110", "uimm[7:0]");
T("t.it", "it{mask} {firstcond}", { params => ["firstcond", "mask"], firstcond => [0, 13, 1], mask => [8, 4, 12] },
  "op=10111111", "firstcond[3:0]", "mask[3:0]");
$j = 0;
T("t.$_", $_, undef, sprintf("op=10111111%04b0000", $j++)) for qw(nop yield wfe wfi sev);
my $TLM = { rn => [0, 7], regs => [0xfe, 0x7f] };
T("t.stmia", "stmia {rn}!, {regs}", $TLM, lo("op=11000", "rn", "regs[7:0]"));
T("t.ldmia", "ldmia {rn}!, {regs}", $TLM, lo("op=11001", "rn", "regs[7:0]"));
my $B8 = { imm => [-256, 254, 0] };
for my $c (@CC) {
    T("t.b$c", "b$c {imm^4}", $B8, sprintf("op=1101%04b", $cc{$c}), "imm[8:1]");
}
T("t.udf", "udf #{uimm}", $U8, "op=11011110", "uimm[7:0]");
T("t.svc", "svc #{uimm}", $U8, "op=11011111", "uimm[7:0]");
T("t.b", "b {imm^4}", { imm => [-2048, 2046, 0] }, "op=11100", "imm[11:1]");

# ---------------------------------------------------------------------------
# Thumb-2, 32 bits
# ---------------------------------------------------------------------------

$isa->group("thumb2");
my %TDP = (and => "0000", bic => "0001", orr => "0010", orn => "0011", eor => "0100",
           add => "1000", adc => "1010", sbc => "1011", sub => "1101", rsb => "1110");
my %TDPX = (tst => "and", teq => "eor", cmn => "add", cmp => "sub", mov => "orr", mvn => "orn");
my $TIMM = { imm12 => [0x0ff, 0x1a5, 0x25a, 0x3c3, 0xfff, 0x400] };
my @tops = qw(and bic orr orn eor add adc sbc sub rsb mov mvn tst teq cmn cmp);
for my $op (@tops) {
    my $cmp = $op =~ /^(tst|teq|cmp|cmn)$/;
    my $mov = $op =~ /^(mov|mvn)$/;
    my $code = $TDP{$TDPX{$op} // $op};
    for my $s ($cmp ? (1) : (0, 1)) {
        my $m = $op . ($s && !$cmp ? "s" : "");
        my $ops = $cmp ? "{rn}, " : $mov ? "{rd}, " : "{rd}, {rn}, ";
        my $rn = $mov ? "rn=1111" : "rn";
        my $rd = $cmp ? "rd=1111" : "rd";
        T2("t2.${m}i", "$m.w $ops#{imm12~}", $TIMM,
           ["op=11110", "imm12[11]", "z=0", "opcode=$code", "s=$s", $rn],
           ["z=0", "imm12[10:8]", $rd, "imm12[7:0]"]);
        $isa->group("thumb2r");
        T2("t2.$m", "$m.w $ops\{rm}", undef,
           ["op=1110101", "opcode=$code", "s=$s", $rn], ["z=0", "sh=000", $rd, "sh=00", "type=00", "rm"]);
        for my $t (qw(lsl lsr asr ror)) {
            T2("t2.$m.$t", "$m.w $ops\{rm}, $t #{sh}", $SHI,
               ["op=1110101", "opcode=$code", "s=$s", $rn], ["z=0", "sh[4:2]", $rd, "sh[1:0]", "type=$SH{$t}", "rm"]);
        }
        $isa->group("thumb2");
    }
}
my $U12 = { uimm => [0, 4095, 0x123] };
T2("t2.addw", "addw {rd}, {rn}, #{uimm}", $U12, ["op=11110", "uimm[11]", "x=100000", "rn"], ["z=0", "uimm[10:8]", "rd", "uimm[7:0]"]);
T2("t2.subw", "subw {rd}, {rn}, #{uimm}", $U12, ["op=11110", "uimm[11]", "x=101010", "rn"], ["z=0", "uimm[10:8]", "rd", "uimm[7:0]"]);
T2("t2.movw", "movw {rd}, #{imm16}", $IMM16, ["op=11110", "imm16[11]", "x=100100", "imm16[15:12]"], ["z=0", "imm16[10:8]", "rd", "imm16[7:0]"]);
T2("t2.movt", "movt {rd}, #{imm16}", $IMM16, ["op=11110", "imm16[11]", "x=101100", "imm16[15:12]"], ["z=0", "imm16[10:8]", "rd", "imm16[7:0]"]);
for my $s (0, 1) {
    my $x = $s ? "s" : "";
    for my $t (qw(lsl lsr asr ror)) {
        T2("t2.$t$x", "$t$x.w {rd}, {rn}, {rm}", undef, ["op=111110100", "type=$SH{$t}", "s=$s", "rn"], ["x=1111", "rd", "z=0000", "rm"]);
    }
}
T2("t2.mul", "mul.w {rd}, {rn}, {rm}", undef, ["op=111110110000", "rn"], ["x=1111", "rd", "z=0000", "rm"]);
T2("t2.mla", "mla {rd}, {rn}, {rm}, {ra}", undef, ["op=111110110000", "rn"], ["ra", "rd", "z=0000", "rm"]);
T2("t2.mls", "mls {rd}, {rn}, {rm}, {ra}", undef, ["op=111110110000", "rn"], ["ra", "rd", "z=0001", "rm"]);
for my $x (["smull", "000"], ["umull", "010"], ["smlal", "100"], ["umlal", "110"]) {
    T2("t2.$x->[0]", "$x->[0] {rdlo}, {rdhi}, {rn}, {rm}", undef, ["op=111110111$x->[1]", "rn"], ["rdlo", "rdhi", "z=0000", "rm"]);
}
T2("t2.sdiv", "sdiv {rd}, {rn}, {rm}", undef, ["op=111110111001", "rn"], ["x=1111", "rd", "y=1111", "rm"]);
T2("t2.udiv", "udiv {rd}, {rn}, {rm}", undef, ["op=111110111011", "rn"], ["x=1111", "rd", "y=1111", "rm"]);
T2("t2.clz",   "clz {rd}, {rm}",   undef, ["op=111110101011", "rm"], ["x=1111", "rd", "y=1000", "rm"]);
T2("t2.rbit",  "rbit {rd}, {rm}",  undef, ["op=111110101001", "rm"], ["x=1111", "rd", "y=1010", "rm"]);
T2("t2.rev",   "rev.w {rd}, {rm}", undef, ["op=111110101001", "rm"], ["x=1111", "rd", "y=1000", "rm"]);
T2("t2.rev16", "rev16.w {rd}, {rm}", undef, ["op=111110101001", "rm"], ["x=1111", "rd", "y=1001", "rm"]);
T2("t2.revsh", "revsh.w {rd}, {rm}", undef, ["op=111110101001", "rm"], ["x=1111", "rd", "y=1011", "rm"]);
for my $x (["sxth", "000"], ["uxth", "001"], ["sxtb", "100"], ["uxtb", "101"]) {
    T2("t2.$x->[0]", "$x->[0].w {rd}, {rm}, ror #{rot}", $ROT, ["op=111110100", "o=$x->[1]", "x=1111"], ["y=1111", "rd", "z=10", "rot[4:3]", "rm"]);
}
T2("t2.bfc", "bfc {rd}, #{lsb}, #{width}", $BF, ["op=1111001101101111"], ["z=0", "lsb[4:2]", "rd", "lsb[1:0]", "y=0", "msb[4:0](lsb,width)"]);
T2("t2.bfi", "bfi {rd}, {rn}, #{lsb}, #{width}", $BF, ["op=111100110110", "rn"], ["z=0", "lsb[4:2]", "rd", "lsb[1:0]", "y=0", "msb[4:0](lsb,width)"]);
T2("t2.ubfx", "ubfx {rd}, {rn}, #{lsb}, #{width}", $BX, ["op=111100111100", "rn"], ["z=0", "lsb[4:2]", "rd", "lsb[1:0]", "y=0", "wm1[4:0](width)"]);
T2("t2.sbfx", "sbfx {rd}, {rn}, #{lsb}, #{width}", $BX, ["op=111100110100", "rn"], ["z=0", "lsb[4:2]", "rd", "lsb[1:0]", "y=0", "wm1[4:0](width)"]);

$isa->group("thumb2m");
my $NEG = { uimm => [1, 255] };
my $PP = { imm => [-255, 255] };
for my $x (["str", "1000", "1100", "0100"], ["strb", "1000", "1000", "0000"], ["strh", "1000", "1010", "0010"],
           ["ldr", "1000", "1101", "0101"], ["ldrb", "1000", "1001", "0001"], ["ldrh", "1000", "1011", "0011"],
           ["ldrsb", "1001", "1001", "0001"], ["ldrsh", "1001", "1011", "0011"]) {
    my ($m, $hi, $i12, $i8) = @$x;
    T2("t2.$m", "$m.w {rt}, [{rn}, #{uimm}]", $U12, ["op=1111$hi", "x=$i12", "rn"], ["rt", "uimm[11:0]"]);
    T2("t2.$m.neg", "$m {rt}, [{rn}, #-{uimm}]", $NEG, ["op=1111$hi", "x=$i8", "rn"], ["rt", "pw=1100", "uimm[7:0]"]);
    T2("t2.$m.pre", "$m {rt}, [{rn}, #{imm}]!", $PP, ["op=1111$hi", "x=$i8", "rn"], ["rt", "p=11", "up[8](imm)", "w=1", "mag[7:0](imm)"]);
    T2("t2.$m.post", "$m {rt}, [{rn}], #{imm}", $PP, ["op=1111$hi", "x=$i8", "rn"], ["rt", "p=10", "up[8](imm)", "w=1", "mag[7:0](imm)"]);
    T2("t2.${m}r", "$m.w {rt}, [{rn}, {rm}, lsl #{sh}]", { sh => [0, 3, 1] }, ["op=1111$hi", "x=$i8", "rn"], ["rt", "z=000000", "sh[1:0]", "rm"]);
}
my $TD = { imm => [-1020, 1020, 0] };
for my $x (["strd", 0], ["ldrd", 1]) {
    my ($m, $l) = @$x;
    T2("t2.$m", "$m {rt}, {rt2}, [{rn}, #{imm}]", $TD, ["op=1110100", "p=1", "up[10](imm)", "x=1", "w=0", "l=$l", "rn"], ["rt", "rt2", "mag[9:2](imm)"]);
    T2("t2.$m.pre", "$m {rt}, {rt2}, [{rn}, #{imm}]!", $TD, ["op=1110100", "p=1", "up[10](imm)", "x=1", "w=1", "l=$l", "rn"], ["rt", "rt2", "mag[9:2](imm)"]);
    T2("t2.$m.post", "$m {rt}, {rt2}, [{rn}], #{imm}", $TD, ["op=1110100", "p=0", "up[10](imm)", "x=1", "w=1", "l=$l", "rn"], ["rt", "rt2", "mag[9:2](imm)"]);
}
my $TLMW = { rn => [0, 12], regs => [0x5ffe, 0x0006] };
for my $x (["stmia", "01", 0], ["ldmia", "01", 1], ["stmdb", "10", 0], ["ldmdb", "10", 1]) {
    my ($m, $pu, $l) = @$x;
    T2("t2.$m", "$m.w {rn}, {regs}", $TLMW, ["op=1110100", "pu=$pu", "z=0", "w=0", "l=$l", "rn"], ["regs[15:0]"]);
    T2("t2.$m.wb", "$m.w {rn}!, {regs}", $TLMW, ["op=1110100", "pu=$pu", "z=0", "w=1", "l=$l", "rn"], ["regs[15:0]"]);
}
T2("t2.push", "push.w {regs}", { regs => [0x5fff, 0x0300] }, ["op=1110100100101101"], ["regs[15:0]"]);
T2("t2.pop",  "pop.w {regs}",  { regs => [0x9fff, 0x0300] }, ["op=1110100010111101"], ["regs[15:0]"]);
T2("t2.ldrex", "ldrex {rt}, [{rn}, #{uimm}]", { uimm => [0, 1020] }, ["op=111010000101", "rn"], ["rt", "x=1111", "uimm[9:2]"]);
T2("t2.strex", "strex {rd}, {rt}, [{rn}, #{uimm}]", { uimm => [0, 1020] }, ["op=111010000100", "rn"], ["rt", "rd", "uimm[9:2]"]);
T2("t2.dmb", "dmb {option}", $OPT, ["op=1111001110111111"], ["x=100011110101", "option[3:0]"]);
T2("t2.dsb", "dsb {option}", $OPT, ["op=1111001110111111"], ["x=100011110100", "option[3:0]"]);
T2("t2.isb", "isb {option}", { option => [15] }, ["op=1111001110111111"], ["x=100011110110", "option[3:0]"]);
my $B24T = { imm => [-16777216, 16777214, 0] };
T2("t2.b",  "b.w {imm^4}", $B24T, ["op=11110", "imm[24]", "imm[21:12]"], ["x=10", "j1[23](imm)", "y=1", "j2[22](imm)", "imm[11:1]"]);
T2("t2.bl", "bl {imm^4}",  $B24T, ["op=11110", "imm[24]", "imm[21:12]"], ["x=11", "j1[23](imm)", "y=1", "j2[22](imm)", "imm[11:1]"]);
my $B20 = { imm => [-1048576, 1048574, 0] };
for my $c (@CC) {
    T2("t2.b$c", "b$c.w {imm^4}", $B20, ["op=11110", "imm[20]", sprintf("cond=%04b", $cc{$c}), "imm[17:12]"],
       ["x=10", "imm[18]", "y=0", "imm[19]", "imm[11:1]"]);
}

T2("t2.uadd8", "uadd8 {rd}, {rn}, {rm}", undef, ["op=111110101000", "rn"], ["x=1111", "rd", "y=0100", "rm"]);
T2("t2.sel", "sel {rd}, {rn}, {rm}", undef, ["op=111110101010", "rn"], ["x=1111", "rd", "y=1000", "rm"]);
T2("t2.nop", "nop.w", undef, ["op=1111001110101111"], ["x=1000000000000000"]);
T2("t2.pld", "pld [{rn}, #{uimm}]", $U12, ["op=111110001001", "rn"], ["x=1111", "uimm[11:0]"]);

# Thumb-2's VFP and NEON: the A32 encoding with 1110 for the condition (VFP)
# or the NEON prefix moved (above): the same bits, the first halfword the
# top one
$isa->group("thumb2v");
T2(@$_) for @NEON;
sub vfp2 {   # a Thumb-2 twin of a VFP A32 def: its fields after cond, split in halfwords
    my ($name, $gnu, $test, @f) = @_;
    my (@hw1, @hw2);
    my $w = 4;   # (op=1110 first)
    for (@f) {
        my $n = /=([01]+)$/ ? length $1 : /\[([\d:|]+)\]/ ? ARMdec_w($1) : 4;
        if ($w < 16 && $w + $n > 16) {
            /^(\w+)=([01]+)$/ or die "arm: $name: field $_ across the halfwords\n";
            my $k = 16 - $w;
            push @hw1, "$1=" . substr($2, 0, $k);
            push @hw2, "${1}2=" . substr($2, $k);
        } elsif ($w < 16) { push @hw1, $_ } else { push @hw2, $_ }
        $w += $n;
    }
    T2($name, $gnu, $test, ["op=1110", @hw1], \@hw2);
}
sub ARMdec_w { my $w = 0; for (split /\|/, $_[0]) { my ($h, $l) = /^(\d+)(?::(\d+))?$/; $w += $h - ($l // $h) + 1 } $w }
vfp2("t2.vmov.drr", "vmov {dm}, {rt}, {rt2}", undef, "op=1100010", "o=0", "rt2", "rt", "x=101100", vX("dm"), "y=1", vV("dm"));
vfp2("t2.vmov.rrd", "vmov {rt}, {rt2}, {dm}", undef, "op=1100010", "o=1", "rt2", "rt", "x=101100", vX("dm"), "y=1", vV("dm"));
vfp2("t2.vmov.32rd", "vmov.32 {rt}, {dn}[{lane}]", { lane => [0, 1] }, "op=1110", "u=0", "o=0", "lane[0]", "l=1", vV("dn"), "rt", "x=1011", vX("dn"), "opc2=00", "y=1", "z=0000");
vfp2("t2.vdup.8q", "vdup.8 {qd}, {rt}", undef, "op=11101", "b=1", "q=1", "z=0", vV("qd"), "rt", "x=1011", vX("qd"), "y=0", "e=0", "w=1", "v=0000");
vfp2("t2.vpush.64", "vpush.64 {dd~n}", $VPD, "op=11010", vX("dd"), "x=101101", vV("dd"), "y=1011", "n[6:0]", "z=0");
vfp2("t2.vpop.64",  "vpop.64 {dd~n}",  $VPD, "op=11001", vX("dd"), "x=111101", vV("dd"), "y=1011", "n[6:0]", "z=0");

$isa->add("fields",
    node("comment", node("Fields that compute their bits: up[n] the U bit of a signed offset (1 for imm >= 0), mag[..] bits of its magnitude, j1/j2 the J bits of a Thumb-2 branch, msb lsb + width - 1, wm1 width - 1. The bracket gives the reach of the operand, for the range check.")),
    @custom);

$isa->section("arm", "macros/arm.ff.txt");
