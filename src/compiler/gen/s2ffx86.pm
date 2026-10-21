# s2ffx86.pm — x86_64 asm as ff, the x86_64 arm of s2ff.pl (which calls it
# when the dump's format is elf64-x86-64). Each function of a preprocessed
# .S (its .s, from mki.pl) becomes an asm function of ttpc's C layer, one
# form per instruction GNU as made, its operands the source's in GNU's
# order (AT&T: the destination last). Nothing is lowered.
#
# One AT&T instruction is many encodings, and GNU as picks one of them (no
# REX or REX, VEX2 or VEX3, a displacement of 0, 8 or 32 bits, the load
# or the store opcode of a move, an imm8, the accumulator's short form):
# ttpc's x86_64 section has a form for each (isa/x86_64.pl, its own, and
# isa/x86_64gnu.pl, GNU's: the user's option C, mnemonic . length .
# encoding . marks . operands), each with its line for GNU as. Of the forms
# whose line is the source's instruction, this takes the one whose bytes
# are the bytes GNU as made (the dump, objdump -d -w: an instruction a
# line), the bytes worked out here from the form's own definition as ttpc
# emits them (its encodings: bit fields MSB first, little endian; byte,
# half, word, dword; the slices, and the range check of an operand whose
# name is not primed). The bytes a label gives (a branch, a rip-relative
# operand) are not known here and match any.
#
# Driven, as the riscv64 arm, by the source:
#
#   label:          a function (a global label), or in one a block label
#                   holding the instructions up to the next (.L, and the
#                   numeric 1: as .L1 1, .L1 2, ...); a function the one
#                   before runs on into is an entry block in it (asm first)
#   alignment       .align, .p2align, .balign: the nops GNU as put in are
#                   kept, each as the form of its bytes (cs nopw is data16,
#                   cs, nopl), in the function before them; a function GNU
#                   aligned has align / n first after asm (ttpc places it
#                   there, the user's choice A), the file's first one the
#                   section's alignment (where GNU's section starts); the
#                   padding at the end of the section is left out
#   prefixes        rep, lock, data16, cs ...: a call of their own before
#                   the instruction, also a segment of a memory operand
#                   (%fs:16 is fs, then the form), and a memory operand
#                   of 32-bit registers is addr32, then their 64-bit names
#   GNU's macros    .macro / .endm (\arg, \()), .rept / .endr, .if / .else
#                   / .endif of numbers: expanded as GNU as does
#   GOT and TLS     sym@GOTPCREL(%rip) reads a word the function carries,
#                   .Lgot sym: / dword / sym; sym@GOTTPOFF(%rip) (initial
#                   exec) .Ltls sym: / dword / sym: on x86_64 a thread
#                   local is still a global (cc_tls 0) and fs is 0, so its
#                   offset from fs is its address
#   other sections  as s2ff.pl: a zeroed object (.zero N) is c2ff --zero's
#                   global, its other labels aliases; any other bytes stop
#                   the translation
#
# s2ff.pl's --size gives the bytes of the instructions, --align the
# alignment of the first function (where ttpc places it).
#
# A host tool (core Perl only), not part of ttpc.
package s2ffx86;
use strict;
use warnings;
use FindBin;
use FF qw(node);

my $where = '';
sub fail { die "s2ff: $where: @_\n" }

# ---- the registers --------------------------------------------------------
my %REG;    # name -> [number, class]
{
    my @q = qw(rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15);
    my @l = qw(eax ecx edx ebx esp ebp esi edi r8d r9d r10d r11d r12d r13d r14d r15d);
    my @w = qw(ax cx dx bx sp bp si di r8w r9w r10w r11w r12w r13w r14w r15w);
    my @b = qw(al cl dl bl spl bpl sil dil r8b r9b r10b r11b r12b r13b r14b r15b);
    for (0 .. 15) { $REG{ $q[$_] } = [$_, 'q']; $REG{ $l[$_] } = [$_, 'l']; $REG{ $w[$_] } = [$_, 'w']; $REG{ $b[$_] } = [$_, 'b'] }
    $REG{ $_->[0] } = [$_->[1], 'b'] for [ah => 4], [ch => 5], [dh => 6], [bh => 7];
    for (0 .. 31) { $REG{"xmm$_"} = [$_, 'x']; $REG{"ymm$_"} = [$_, 'y']; $REG{"zmm$_"} = [$_, 'z'] }
    $REG{"k$_"} = [$_, 'k'] for 0 .. 7;
    $REG{"cr$_"} = [$_, 'c'] for 0, 2, 3, 4, 8;
    $REG{"dr$_"} = [$_, 'd'] for 0 .. 3, 6, 7;
}

# ---- the forms: ttpc's x86_64 section and GNU's -----------------------------
# %DEF: every definition by name (encodings, slices, forms); %BYMN: the
# forms by the mnemonic of their GNU line, each its name, its parameters'
# kinds, its operands' patterns, its place (GNU's forms first)
my (%DEF, %BYMN, $loaded);
sub load {
    return if $loaded++;
    local (@main::X86_WIDE, @main::X86_GNU, @main::X86_GNU_DEFS);
    # (in main, whose names the file's are, as for mkgnuff.pl)
    my $section = do { package main; do "$FindBin::Bin/../isa/x86_64.pl" };
    die "s2ff: isa/x86_64.pl: $@" if $@;
    die "s2ff: isa/x86_64.pl: $!\n" unless defined $section;
    my $add;
    $add = sub { for (@_) { if (FF::is_layer($_)) { $add->(@{ $_->{children} }) } elsif ($_->{content} =~ /^(\S+):$/) { $DEF{$1} //= $_ } } };
    $add->(@{ $_->{children} }) for @{ $section->{children} };
    $add->(@main::X86_GNU_DEFS);
    my $i = 0;
    for my $f (@main::X86_GNU, @main::X86_WIDE) {
        my ($name, $params, $gnu) = @$f;
        (my $g = $gnu) =~ s/^\s*(\{[a-z0-9]+\}\s*)+//;
        my ($mn, $ops) = $g =~ /^(\S+)\s*(.*)$/ or die "s2ff: $name: $gnu\n";
        my @pats;
        for my $o (split_ops($ops)) {
            $o =~ s/\s+//g;
            my (@names, $re);
            $re = '';
            my @parts = split /(<[^>]+>)/, $o;
            for my $j (0 .. $#parts) {
                my $part = $parts[$j];
                # (a displacement is all before the last group: -(32*1)(%rsi))
                if ($part =~ /^<(.+)>$/) { push @names, $1; $re .= ($parts[$j + 1] // '') =~ /^\(/ ? '(.*)' : '(.*?)' }
                else { $re .= quotemeta $part }
            }
            push @pats, [qr/^$re$/, \@names];
        }
        push @{ $BYMN{ lc $mn } }, { name => $name, kinds => [map { [split /:/, $_, 2] } @$params], pats => \@pats, order => $i++ };
    }
}

# ---- the bytes of a form, from its definition ---------------------------------
# A value is a number, or undef where a label gives it (not known here).
sub is_field { my ($c) = @_; ($c->{content} =~ /:$/ && @{ $c->{children} } == 1) || $c->{content} =~ /\[[\d:|]+\]$/ }
my %PB;
sub params_body {
    my ($d) = @_;
    return @{ $PB{$d} } if $PB{$d};
    my @c = @{ $d->{children} };
    my $n = 0;
    $n++ while $n < @c && !@{ $c[$n]{children} };
    @{ $PB{$d} = [[map { $_->{content} } @c[0 .. $n - 1]], [@c[$n .. $#c]]] };
}
my %KIND;    # a definition: bits (fields), ops (a value, a0) or emit (calls)
my %OPS = map { $_ => 1 } qw(sub add addi slli srli srai andi ori xori or and xor bits srl sra sll);
sub kind_of {
    my ($name) = @_;
    return $KIND{$name} if $KIND{$name};
    my $d = $DEF{$name} or fail "ttpc's x86_64 section has no $name";
    my (undef, $body) = params_body($d);
    $KIND{$name} = (grep { is_field($_) } @$body) ? 'bits' : (grep { $OPS{ $_->{content} } } @$body) ? 'ops' : 'emit';
}
sub numlit {
    my ($s) = @_;
    return hex($s) if $s =~ /^0x[0-9a-f]+$/i;
    return -hex($1) if $s =~ /^-0x([0-9a-f]+)$/i;
    return $s + 0 if $s =~ /^-?\d+$/;
    undef;
}
sub leafval {
    my ($s, $env) = @_;
    return $env->{$s} if exists $env->{$s};
    my $n = numlit($s);
    return $n if defined $n;
    return $REG{$s}[0] if $REG{$s};
    return undef if $s eq 'pc';
    fail "a value of no meaning here: $s";
}
sub argval {
    my ($a, $env) = @_;
    return leafval($a->{content}, $env) unless @{ $a->{children} };
    callval($a->{content}, map { argval($_, $env) } @{ $a->{children} });
}
# a definition of ops, run with its parameters bound: a0
sub callval {
    my ($name, @args) = @_;
    my $d = $DEF{$name} or fail "ttpc's x86_64 section has no $name";
    my ($params, $body) = params_body($d);
    my %r;
    @r{@$params} = @args;
    my $v = sub {
        my ($s) = @_;
        return $r{$s} if exists $r{$s};
        return 0 if $s eq 'zero';
        my $n = numlit($s);
        return $n if defined $n;
        return undef if $s eq 'pc';
        fail "$name: a value of no meaning here: $s";
    };
    for my $op (@$body) {
        my $o = $op->{content};
        my @a = map { $_->{content} } @{ $op->{children} };
        if ($o eq 'bits') {
            my ($x, $sl, $sr, $sc) = map { $v->($_) } @a;
            $r{a0} = defined $x ? (((($x << $sl) & ~0) >> $sr) << $sc) & ~0 : undef;
            next;
        }
        $OPS{$o} or fail "$name: an op of no meaning here: $o";
        my ($vx, $vy) = ($v->($a[0]), $v->($a[1]));
        my $dst = $a[2];
        if (!defined $vx || !defined $vy) { $r{$dst} = undef; next }
        my $res;
        if ($o eq 'srli' || $o eq 'srl') { $res = ($vy & ~0) >> $vx }
        else {
            use integer;
            $res = $o eq 'sub' ? $vy - $vx
                 : $o eq 'add' ? $vx + $vy
                 : $o eq 'addi' ? $vy + $vx
                 : $o eq 'slli' || $o eq 'sll' ? $vy << $vx
                 : $o eq 'srai' || $o eq 'sra' ? $vy >> $vx
                 : $o eq 'andi' || $o eq 'and' ? $vx & $vy
                 : $o eq 'ori' || $o eq 'or' ? $vx | $vy
                 : $vx ^ $vy;
        }
        $r{$dst} = $res;
    }
    $r{a0};
}
sub slice_width { my $w = 0; for (split /\|/, $_[0]) { my ($h, $l) = /^(\d+)(?::(\d+))?$/; $w += $h - ($l // $h) + 1 } $w }
my %SIZE = (byte => 1, half => 2, word => 4, dword => 8);
# the bytes of one call of a form's body into out; 0 where an operand is
# out of its field's range (ttpc would stop)
sub emit {
    my ($c, $env, $out) = @_;
    my $name = $c->{content};
    if (my $sz = $SIZE{$name}) {
        my $v = argval($c->{children}[0], $env);
        my $b = 8 * $sz;
        return 0 if defined $v && $b < 64 && ($v < -(1 << ($b - 1)) || $v >= (1 << $b));
        push @$out, map { defined $v ? ($v >> (8 * $_)) & 0xff : undef } 0 .. $sz - 1;
        return 1;
    }
    my $k = kind_of($name);
    my ($params, $body) = params_body($DEF{$name});
    my %e;
    @e{@$params} = map { argval($_, $env) } @{ $c->{children} };
    if ($k eq 'bits') {
        my ($v, $w) = (0, 0);
        for my $f (@$body) {
            if ($f->{content} =~ /^(.*):$/) {
                my $bits = $f->{children}[0]{content};
                $v = defined $v ? ($v << length $bits) | oct("0b$bits") : undef;
                $w += length $bits;
                next;
            }
            my ($base, $spec) = $f->{content} =~ /^(.+)\[([\d:|]+)\]$/ or fail "$name: field $f->{content}";
            my $fw = slice_width($spec);
            my $x = argval($f->{children}[0], \%e);
            my $fv;
            if (defined $x) {
                # the range of an operand not primed: -2^hi .. 2^(hi+1) - 1,
                # one called imm signed only
                if ($base !~ /'$/ && $spec =~ /^(\d+)(:0)?$/ && (defined $2 || $1 == 0)) {
                    my $hi = $1;
                    return 0 if $x < -(1 << $hi) || $x >= ($base eq 'imm' ? 1 << $hi : 1 << ($hi + 1));
                }
                if ($DEF{ $f->{content} }) { $fv = callval($f->{content}, $x) }
                else { my ($h, $l) = $spec =~ /^(\d+)(?::(\d+))?$/ or fail "$name: no slice $f->{content}"; $fv = $x >> ($l // $h) }
                $fv &= (1 << $fw) - 1 if defined $fv;
            }
            $v = defined $v && defined $fv ? ($v << $fw) | $fv : undef;
            $w += $fw;
        }
        $w % 8 == 0 or fail "$name: $w bits";
        push @$out, map { defined $v ? ($v >> (8 * $_)) & 0xff : undef } 0 .. $w / 8 - 1;
        return 1;
    }
    fail "$name: a value, not bytes" if $k eq 'ops';
    for my $b (@$body) { emit($b, \%e, $out) or return 0 }
    1;
}

# ---- the source's operands ---------------------------------------------------
sub split_ops {
    my ($s) = @_;
    my @o;
    my ($cur, $depth) = ('', 0);
    for my $c (split //, $s) {
        $depth++ if $c eq '(' || $c eq '{';
        $depth-- if $c eq ')' || $c eq '}';
        if ($c eq ',' && !$depth) { push @o, $cur; $cur = ''; next }
        $cur .= $c;
    }
    push @o, $cur if $cur =~ /\S/;
    s/^\s+|\s+$//g for @o;
    @o;
}
# a number, or a constant expression of numbers, as GNU as takes it
sub num {
    my ($v) = @_;
    return undef unless defined $v && $v =~ /\d/ && $v =~ /^[\s\da-fx()+\-*\/%<>&|~^]+$/i;
    # (a hex number past 2^63 is negative: 0xfffffffffffffff0 is -16)
    (my $e = $v) =~ s/\b0x([0-9a-f]+)\b/unpack('q', pack('Q', hex($1)))/gie;
    $e =~ /^[\s\d()+\-*\/%<>&|~^]+$/ or return undef;
    my $n = eval "use integer; $e";
    $n;
}

my %numeric;    # how many times each numeric label has come so far
sub label {
    my ($o) = @_;
    $o =~ s/\@(PLT|plt)$//;
    $o =~ s/\x01/ /g;
    return ".L$1 " . (($numeric{$1} // 0) + ($2 eq 'f' ? 1 : 0)) if $o =~ /^(\d+)([fb])$/;
    $o;
}
# an operand as the value (for the bytes) and the leaf (for the ff) of a
# parameter of kind k; () where it is not one of that kind
sub bindop {
    my ($k, $s) = @_;
    if ($k =~ /^([qlwbxyzkcd])(?:\.(lo|hi|any|ev|acc))?$/ || $k =~ /^(bm0|bm|bs|bx0|base|index)(?:\.(lo|hi))?$/) {
        my ($cls, $sub) = ($1, $2 // '');
        $cls = 'q' if length $cls > 1;
        $s =~ /^%(\w+)$/ && $REG{$1} or return ();
        my ($n, $c) = @{ $REG{$1} };
        return () unless $c eq $cls;
        return () if $sub eq 'acc' && $n != 0;
        return ($n, $1);
    }
    if ($k eq 'st.any') {
        return (0, 'st0') if $s eq '%st';
        return ($1, "st$1") if $s =~ /^%st\((\d)\)$/;
        return ();
    }
    if ($k eq 'scale') { return () unless $s =~ /^[1248]$/; return ($s + 0, $s) }
    if ($k =~ /^label8?$/) {
        return () if $s eq '' || $s =~ /^[%\$(*]/ || $s =~ /[(),{}]/;
        return (undef, label($s));
    }
    # an immediate or a displacement: a number, or a symbol (a relocation)
    return () if $s =~ /^%/;
    $s = 0 if $s eq '' && $k =~ /^d/;
    return () if $s eq '';
    my $v = num($s);
    if (defined $v) {
        # GNU as takes 0xffffffff as -1 where the operand is 32 bits (16, 8)
        return ($v, $v) unless $k =~ /^[iu]/;
        return ([$v, $v], map { [$v - $_, $v - $_] } grep { $v >= $_ / 2 && $v < $_ } 2**32, 2**16, 2**8);
    }
    return () if $s =~ /[(),{}]/ || $s !~ /^[.\w\x01]+$/;
    (undef, label($s));
}

# the forms whose GNU line is the instruction: [form, values, leaves]
sub matches {
    my ($mn, @o) = @_;
    my @r;
    FORM: for my $f (@{ $BYMN{$mn} // [] }) {
        next unless @{ $f->{pats} } == @o;
        my %cap;
        for my $i (0 .. $#o) {
            my ($re, $names) = @{ $f->{pats}[$i] };
            my @c = $o[$i] =~ $re or next FORM;
            @cap{@$names} = @c if @$names;
        }
        # each parameter's value and leaf (an immediate: some, one taken)
        my @alts = ([{}, []]);
        for my $pk (@{ $f->{kinds} }) {
            my ($p, $k) = @$pk;
            next FORM unless exists $cap{$p};
            my @b = bindop($k, $cap{$p}) or next FORM;
            @b = ([@b]) unless ref $b[0];
            @alts = map { my $a = $_; map { [{ %{ $a->[0] }, $p => $_->[0] }, [@{ $a->[1] }, $_->[1]]] } @b } @alts;
        }
        push @r, map { [$f, @$_] } @alts;
    }
    @r;
}
sub bytes_of {
    my ($f, $val) = @_;
    my $d = $DEF{ $f->{name} } or fail "no definition of the form $f->{name}";
    my (undef, $body) = params_body($d);
    my @out;
    for (@$body) { emit($_, $val, \@out) or return () }
    @out;
}
sub same {
    my ($want, $got) = @_;
    return 0 unless @$want == @$got;
    for (0 .. $#$want) { return 0 if defined $got->[$_] && $got->[$_] != $want->[$_] }
    1;
}
sub hexes { join ' ', map { sprintf '%02x', $_ } @_ }

# the prefixes GNU as takes as words of their own: their call and byte
my %PREFIX = (rep => ['rep', 0xf3], repe => ['repe', 0xf3], repz => ['repz', 0xf3], repne => ['repne', 0xf2],
    repnz => ['repnz', 0xf2], lock => ['lock', 0xf0], data16 => ['data16', 0x66], notrack => ['notrack', 0x3e], addr32 => ['addr32', 0x67],
    cs => ['cs', 0x2e], ds => ['ds', 0x3e], fs => ['fs', 0x64], gs => ['gs', 0x65]);
# GNU's other names of a mnemonic, which the dump does not give back
my %ALIAS = (retq => 'ret', jmpq => 'jmp', callq => 'call', sal => 'shl', salb => 'shlb', salw => 'shlw', sall => 'shll', salq => 'shlq');

# one instruction: its prefixes' calls and the form whose bytes are GNU's
sub translate {
    my ($mn, $ops, $bytes, $dumpasm, @pre) = @_;
    my ($dumpmn, $dumpops) = ($dumpasm // '') =~ /^(?:(?:rep\w*|lock|data16|notrack|cs|ds|fs|gs|bnd)\s+)*(\S+)\s*(.*)$/;
    my @o = map { (my $x = $_) =~ s/\s+//g; $x } @$ops;
    for (@o) {
        # a segment of a memory operand: a call before the form
        push @pre, $1 if s/^%(cs|ds|fs|gs):// || s/^\*%(cs|ds|fs|gs):/*/;
        # (base,index) is (base,index,1)
        s/\((%\w+),(%\w+)\)$/($1,$2,1)/;
    }
    # a memory operand of 32-bit registers: addr32 (67), then the form of
    # their 64-bit names (leal -1(%ecx), %edx)
    if (grep { /\(%(e[a-z]{2}|r\d+d)\b/ } @o) {
        for (@o) { s/(?<=[(,])%(e[a-z]{2}|r\d+d)\b/'%' . (grep { $REG{$_}[1] eq 'q' && $REG{$_}[0] == $REG{$1}[0] } keys %REG)[0]/ge }
        push @pre, 'addr32';
    }
    my @want = @$bytes;
    for my $p (@pre) {
        fail "GNU as put the prefix $p elsewhere: " . hexes(@$bytes) unless @want && $want[0] == $PREFIX{$p}[1];
        shift @want;
    }
    my @keys = ($mn, $ALIAS{$mn} // (), map { "$mn$_" } qw(b w l q));
    push @keys, $dumpmn, map { "$dumpmn$_" } qw(b w l q) if $dumpmn;
    # the operands as written; and GNU's other ways of them: a shift by
    # $1 is the form of one operand (d1 e1), xchg either way round (92)
    my @alt = (\@o);
    push @alt, [@o[1 .. $#o]] if $o[0] && $o[0] eq '$1' && $mn =~ /^(rol|ror|rcl|rcr|shl|sal|shr|sar)[bwlq]?$/;
    push @alt, [reverse @o] if $mn =~ /^xchg[bwlq]?$/;
    push @alt, ['%ax'] if !@o && $mn =~ /^fn?stsw$/;
    my (%seen, @hit);
    for my $k (grep { !$seen{$_}++ } @keys) {
        for my $os (@alt) {
            for my $m (matches($k, @$os)) {
                my @b = bytes_of($m->[0], $m->[1]);
                push @hit, $m if @b && same(\@want, \@b);
            }
        }
        last if @hit;
    }
    # (pmovmskb %xmm1, %rdx is GNU's of %edx: objdump's operands, where
    # the source's have no symbol)
    if (!@hit && $dumpops && !grep { (my $x = $_) =~ s/%\w+|\b0x[0-9a-f]+\b|\d+//gi; $x =~ /[a-z_.]/i } @o) {
        my @d = map { (my $x = $_) =~ s/\s+//g; $x =~ s/^%(cs|ds|fs|gs)://; $x } split_ops($dumpops);
        for my $k (do { my %s2; grep { !$s2{$_}++ } $dumpmn, map { "$dumpmn$_" } qw(b w l q) }) {
            for my $m (matches($k, @d)) {
                my @b = bytes_of($m->[0], $m->[1]);
                push @hit, $m if @b && same(\@want, \@b);
            }
            last if @hit;
        }
    }
    unless (@hit) {
        my %t;
        my @near = grep { !$t{$_}++ } map { $_->[0]{name} } map { matches($_, @o) } grep { $BYMN{$_} } keys %seen;
        fail "no form of $mn @{[join ', ', @$ops]} makes GNU's " . hexes(@want)
            . (@near ? " (of @near[0 .. ($#near < 5 ? $#near : 5)])" : " (ttpc has no form of it)");
    }
    my ($m) = sort { $a->[0]{order} <=> $b->[0]{order} } @hit;
    ((map { node($PREFIX{$_}[0]) } @pre), node($m->[0]{name}, map { node($_) } @{ $m->[2] }));
}

# ---- the dump: the bytes and objdump's text of each instruction -------------
sub read_dump {
    my ($dump) = @_;
    open my $d, '<', $dump or die "s2ff: cannot open $dump: $!\n";
    my (@made, $sec, %secs);
    while (<$d>) {
        if (/^Disassembly of section (\S+):/) { $sec = $1; next }
        next unless /^\s*([0-9a-f]+):\t([0-9a-f ]+?)\s*(?:\t(.*))?$/;
        my ($addr, $hex, $asm) = (hex $1, $2, $3 // '');
        $asm =~ s/\s*#.*//;
        $asm =~ s/\s+<[^>]*>\s*$//;
        my @b = map { hex } split ' ', $hex;
        if ($asm eq '' && @made) { push @{ $made[-1]{bytes} }, @b; next }
        $secs{$sec}++;
        push @made, { addr => $addr, bytes => \@b, asm => $asm };
    }
    close $d;
    fail "code in more than one section: @{[sort keys %secs]}" if keys %secs > 1;
    @made;
}

# ---- the source walk -----------------------------------------------------------
my (@made, $n, $pos, @fns, $fn, $block, $other, @pending, %datadef, $ends, %got, %tls, $align, $maxalign, @prefix, %macro, @sections);
my (%rodata, $roblob, %ro, @carry, %roset);    # read-only data: a label's bytes, the labels a function names
sub take {
    my $m = $made[$n++] or fail "GNU as made fewer instructions than the source has";
    fail sprintf("GNU's next instruction is at 0x%x, the source's at 0x%x", $m->{addr}, $pos) unless $m->{addr} == $pos;
    $pos += @{ $m->{bytes} };
    $m;
}
sub into { ($block // $fn)->{children} }
# the end of a function: the words its GOT and TLS operands read
sub finish {
    push @carry, [$fn, [sort keys %ro]] if $fn && %ro;
    %ro = ();
    return unless $fn && (%tls || %got);
    push @{ $fn->{children} }, node('align', node(8)),
        (map { node(".Ltls $_:", node('dword', node($_))) } sort keys %tls),
        (map { node(".Lgot $_:", node('dword', node($_))) } sort keys %got);
    %tls = %got = ();
}
# the nops GNU as put in, up to the next multiple of a (if at most max)
sub pad {
    my ($a, $max) = @_;
    return unless $a > 1;
    $maxalign = $a if $a > ($maxalign // 1);
    my $to = ($pos + $a - 1) & ~($a - 1);
    return if defined $max && $to - $pos > $max;
    while ($pos < $to) {
        fail "padding outside a function" unless $fn;
        push @{ into() }, padnode(take());
    }
    fail "GNU's padding runs past the alignment" if $pos > $to;
}
# a nop GNU as put in, the form of objdump's text
sub padnode {
    my ($m) = @_;
    my ($mn, $rest) = $m->{asm} =~ /^(\S+)\s*(.*)$/ or fail "padding with no text";
    my @pre;
    while ($PREFIX{$mn}) { push @pre, $mn; ($mn, $rest) = $rest =~ /^(\S+)\s*(.*)$/ }
    my @ops = split_ops($rest);
    my @r = eval { translate($mn, \@ops, $m->{bytes}, undef, @pre) };
    return @r if @r;
    # (cs nopw: its 66 first, data16 cs nopl)
    @r = eval { translate('nopl', \@ops, $m->{bytes}, undef, 'data16', @pre) } if $mn eq 'nopw';
    return @r if @r;
    fail "padding of no form: $m->{asm} (" . hexes(@{ $m->{bytes} }) . ")";
}

sub run {
    my ($mode, $src, $dump) = @_;
    load();
    $where = $src;
    @made = read_dump($dump);
    ($n, $pos, $ends, $maxalign, $fn, $block, $other, $align) = (0, 0, 1);
    (@fns, @pending, %datadef, %numeric, %got, %tls, %macro, @sections, @prefix, %rodata, %ro, @carry, %roset) = ();
    undef $roblob;
    open my $s, '<', $src or die "s2ff: cannot open $src: $!\n";
    my ($file, $line) = ('', 0);
    my @src;
    while (my $l = <$s>) {
        chomp $l;
        if ($l =~ /^# (\d+) "([^"]+)"/) { ($line, $file) = ($1 - 1, $2 =~ s{^(\.\./)+}{}r); next }
        # (gcc's marks around an asm statement: # 0 "" 2, #APP, #NO_APP)
        next if $l =~ /^\s*#/;
        $line++;
        $l =~ s/\s*#.*$// unless $l =~ /"/;
        push @src, [$l, $file, $line];
    }
    close $s;
    walk_lines(\@src, 0);
    finish();
    # each function carries the read-only data it names, after its code
    for my $c (@carry) {
        my ($f, $labels) = @$c;
        rodata_set($_) for @$labels;
        my @l = grep { $rodata{$_} } @$labels or next;
        push @{ $f->{children} }, map { (node('align', node(16)), node("$_:", @{ $rodata{$_} })) } @l;
    }
    fail "a prefix with no instruction after it: @prefix" if @prefix;
    # what is left is the padding GNU as put at the end of the section
    pop @made while @made > $n && $made[-1]{asm} =~ /^((data16|cs)\s+)*(nop\w*|xchg\s+%ax,%ax)\b/;
    fail "GNU as made " . scalar(@made) . " instructions, the source $n" unless $n == @made;
    # the first function starts where GNU's section does, at its alignment
    my ($first) = grep { @{ $_->{children} } && $_->{children}[0]{content} eq 'asm' } @fns;
    if ($first && ($maxalign // 1) > 1) {
        my $c = $first->{children};
        if (@$c > 1 && $c->[1]{content} eq 'align') { $c->[1]{children}[0]{content} = $maxalign }
        else { splice @$c, 1, 0, node('align', node($maxalign)) }
    }
    return $pos if $mode eq 'size';
    return $maxalign // 1 if $mode eq 'align';
    merge_runons();
    \@fns;
}

# the lines of the source, GNU's macros expanded: .macro name args / .endm
# (\arg and \() in its lines), .rept n / .endr, .if expr / .else / .endif
sub walk_lines {
    my ($src, $depth) = @_;
    fail "macros nested past 50" if $depth > 50;
    my $i = 0;
    my @cond;     # each .if: [taking, taken, the outer one taking]
    my $body = sub {
        my ($open, $close) = @_;
        my (@b, $nest);
        $nest = 0;
        while ($i < @$src) {
            my $x = $src->[$i++];
            $nest++ if $x->[0] =~ /^\s*$open\b/;
            if ($x->[0] =~ /^\s*$close\b/) { return \@b unless $nest; $nest-- }
            push @b, $x;
        }
        fail "no $close";
    };
    while ($i < @$src) {
        my ($l, $file, $line) = @{ $src->[$i++] };
        $where = "$file:$line";
        (my $t = $l) =~ s/^\s+|\s+$//g;
        my $off = @cond && !$cond[-1][0];
        if ($t =~ /^\.macro\s+([\w.]+)\s*,?\s*(.*)$/i) {
            my ($name, $args) = ($1, $2);
            my $b = $body->('\.macro', '\.endm');
            $macro{ lc $name } = [[map { [split /=/, $_, 2] } grep { $_ ne '' } split /[\s,]+/, $args], $b] unless $off;
            next;
        }
        if ($t =~ /^\.rept\s+(.*)$/) {
            my $count = $1;
            my $b = $body->('\.(?:rept|irp|irpc)', '\.endr');
            next if $off;
            my $c = num($count) // fail ".rept of $count";
            walk_lines($b, $depth + 1) for 1 .. $c;
            next;
        }
        if ($t =~ /^\.if(eq|ne|gt|ge|lt|le)?\s+(.*)$/) {
            my ($k, $e) = ($1 // '', $2);
            my $v = $off ? 0 : num($e) // fail ".if of $e";
            my $take = $k eq '' || $k eq 'ne' ? $v != 0 : $k eq 'eq' ? $v == 0 : $k eq 'gt' ? $v > 0 : $k eq 'ge' ? $v >= 0 : $k eq 'lt' ? $v < 0 : $v <= 0;
            push @cond, [!$off && $take, !$off && $take, !$off];
            next;
        }
        if ($t =~ /^\.else\b/) { fail ".else with no .if" unless @cond; $cond[-1][0] = $cond[-1][2] && !$cond[-1][1]; next }
        if ($t =~ /^\.endif\b/) { fail ".endif with no .if" unless @cond; pop @cond; next }
        next if $off;
        fail ".err: GNU as stops here" if $t =~ /^\.err\b/;
        for my $st (split /;/, $l) {
            $st =~ s/^\s+|\s+$//g;
            next if $st eq '';
            # a macro's use: its lines, its arguments in them
            my ($w, $rest) = $st =~ /^([\w.]+)\s*(.*)$/;
            if (defined $w && $macro{ lc $w }) {
                my ($p, $b) = @{ $macro{ lc $w } };
                my @a = split_ops($rest);
                @a = split ' ', $rest if @a == 1 && @$p > 1;
                my %v;
                $v{ $p->[$_][0] } = $a[$_] // $p->[$_][1] // '' for 0 .. $#$p;
                my @x;
                for (@$b) {
                    (my $bl = $_->[0]) =~ s/\\(\w+)/exists $v{$1} ? $v{$1} : "\\$1"/ge;
                    $bl =~ s/\\\(\)//g;
                    push @x, [$bl, $file, $line];
                }
                walk_lines(\@x, $depth + 1);
                next;
            }
            walk_stmt($st, $file, $line);
        }
    }
    fail ".if with no .endif" if @cond;
}

sub section {
    my ($sec) = @_;
    if ($sec =~ /^\.text(\.|$)/) { $other = undef; return }
    $other = $sec;
    @pending = ();
    undef $roblob;
}

# the next bytes of read-only data: of the labels just before them (one
# list for all of them), or after the last ones
sub rodata_add {
    my ($d) = @_;
    if (@pending) { $roblob = []; $rodata{$_} = $roblob for @pending; @pending = () }
    fail "read-only bytes with no label" unless $roblob;
    push @$roblob, $d;
}
# X of .set X, Y+n: Y's bytes from n on (n at the start of one of them)
sub rodata_set {
    my ($x) = @_;
    return if $rodata{$x} || !$roset{$x};
    my ($y, $off) = @{ $roset{$x} };
    rodata_set($y);
    my $b = $rodata{$y} or return;
    my %sz = (byte => 1, half => 2, word => 4, dword => 8);
    my $i = 0;
    while ($off > 0) {
        my $d = $b->[$i++] or fail "$x: past the bytes of $y";
        my $k = $sz{ $d->{content} } or fail "$x: $y+$roset{$x}[1] inside its $d->{content}";
        $off -= $k;
    }
    fail "$x: $y+$roset{$x}[1] inside a word of it" if $off < 0;
    $rodata{$x} = [@$b[$i .. $#$b]];
}
sub walk_stmt {
    my ($st, $file, $line) = @_;
    # sections: code (.text, .text.x) or another
    if ($st =~ /^\.(text|data|bss)$/) { push @sections, $other; section(".$1"); return }
    if ($st =~ /^\.section\s+"?([^",\s]+)"?/) { push @sections, $other; section($1); return }
    if ($st eq '.previous') { my $p = pop @sections; push @sections, $other; $other = $p; return }
    if (defined $other) {
        return if $st =~ /^\.(globl|global|weak|type|size|hidden|protected|align|p2align|balign|cfi_\w+|ident)\b/;
        if ($st =~ /^([.\w]+):$/) { push @pending, $1; undef $roblob; return }
        if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/) { push @fns, node("$1:", node('alias'), node($2)) if $datadef{$2}; return }
        # read-only data (gcc's constants, a string): its label's bytes, as
        # data each function that names it carries (its labels are its own)
        if ($other =~ /^\.rodata/) {
            # (.set X, Y+n: X's bytes are Y's from n on, gcc's constants shared)
            if ($st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)\s*(?:\+\s*(\d+))?$/) { $roset{$1} = [$2, $3 // 0]; return }
            if ($st =~ /^\.(string|asciz|ascii)\s+"((?:[^"\\]|\\.)*)"$/) {
                my ($k, $t) = ($1, $2);
                my %e = (n => "\n", t => "\t", r => "\r", f => "\f", b => "\b", '"' => '"', '\\' => '\\');
                $t =~ s/\\(?:([0-7]{1,3})|x([0-9a-fA-F]{1,2})|(.))/defined $1 ? chr oct $1 : defined $2 ? chr hex $2 : $e{$3} \/\/ fail "an escape \\$3"/ge;
                $t .= "\0" unless $k eq 'ascii';
                rodata_add(node('ascii', node($t)));
                return;
            }
            if ($st =~ /^\.(byte|value|short|2byte|word|long|int|4byte|quad|8byte|zero|skip)\s+(-?(?:0x[0-9a-fA-F]+|\d+))$/) {
                my ($k, $v) = ($1, $2);
                $v = $v =~ /^(-?)0x(.*)$/i ? ($1 ? -hex $2 : hex $2) : $v;
                return rodata_add(node('reserve', node($v))) if $k =~ /^(zero|skip)$/;
                my ($dir, $bits) = @{ { byte => ['byte', 8], value => ['half', 16], short => ['half', 16], '2byte' => ['half', 16], word => ['half', 16],
                    long => ['word', 32], int => ['word', 32], '4byte' => ['word', 32], quad => ['dword', 64], '8byte' => ['dword', 64] }->{$k} };
                $v += 2 ** $bits if $v < 0;
                rodata_add(node($dir, node($v)));
                return;
            }
        }
        if ($st =~ /^\.(zero|space)\s+(\d+)$/ && @pending) {
            my ($first, @more) = @pending;
            $datadef{$_} = 1 for @pending;
            push @fns, map { node("$_:", node('alias'), node($first)) } @more;
            warn "s2ff: $where: $first is zero, c2ff --zero $first makes it\n";
            @pending = ();
            return;
        }
        fail "bytes in $other: $st";
    }
    # labels at the front of the statement
    while ($st =~ s/^([.\w\$]+):\s*//) {
        my $name = $1;
        $name = ".L$name " . ++$numeric{$name} if $name =~ /^\d+$/;
        if ($name =~ /^\.L/) {
            fail "a label outside a function: $name" unless $fn;
            $block = node("$name:");
            push @{ $fn->{children} }, $block;
        } elsif ($fn && !$ends) {
            # the function before runs on into this one: an entry in it
            $block = node("$name:", node('asm'), node('comment', node("glibc-2.44 $file:$line")));
            push @{ $fn->{children} }, $block;
            undef $align;
        } else {
            finish();
            $fn = node("$name:", node('asm'), (defined $align ? node('align', node($align)) : ()), node('comment', node("glibc-2.44 $file:$line")));
            push @fns, $fn;
            undef $block;
            undef $align;
            $ends = 0;
        }
    }
    return if $st eq '';
    # X = Y, .set X, Y: another name for Y
    if ($st =~ /^([.\w]+)\s*=\s*([.\w]+)$/ || $st =~ /^\.set\s+([.\w]+)\s*,\s*([.\w]+)$/) { push @fns, node("$1:", node('alias'), node($2)); return }
    my ($op, $rest) = $st =~ /^(\S+)\s*(.*)$/;
    if ($op =~ /^\./) {
        if ($op =~ /^\.(p2align|align|balign)$/) {
            my @a = split_ops($rest);
            my $x = num($a[0]) // fail "$op of $a[0]";
            my $a = $op eq '.p2align' ? 1 << $x : $x;
            pad($a, defined $a[2] && $a[2] ne '' ? num($a[2]) : undef);
            $align = $a;     # (before a function's label: its alignment)
            return;
        }
        return if $op =~ /^\.(globl|global|weak|hidden|protected|type|size|cfi_\w+|loc|file|ident|code64|att_syntax)$/;
        fail "a directive with no ff form: $st";
    }
    undef $align;
    fail "an instruction outside a function: $st" unless $fn;
    $op = lc $op;
    # a prefix: a call of its own, its byte the first of GNU's next instruction
    while ($PREFIX{$op}) {
        push @prefix, $op;
        return if $rest eq '';
        ($op, $rest) = $rest =~ /^(\S+)\s*(.*)$/;
        $op = lc $op;
    }
    my @ops = split_ops($rest);
    # GOT and TLS words: read from the function's own (\x01: a space)
    for (@ops) {
        if (/^([.\w]+)\@GOTPCREL\(%rip\)$/i) { $got{$1} = 1; $_ = ".Lgot\x01$1(%rip)" }
        elsif (/^([.\w]+)\@GOTTPOFF\(%rip\)$/i) { $tls{$1} = 1; $_ = ".Ltls\x01$1(%rip)" }
        elsif (/\@/) { fail "a relocation with no ff form: $_" }
        $ro{$1} = 1 if /^([.\w]+)(?:[-+]\d+)?\(%rip\)$/ || /^\$(\.L\w+)$/;
    }
    my $m = take();
    my @pre = @prefix;
    @prefix = ();
    my @nodes = translate($op, \@ops, $m->{bytes}, $m->{asm}, @pre);
    push @{ into() }, @nodes;
    $ends = $nodes[-1]{content} =~ /^(ret|jmp|ud2|hlt)(\.|$)/ ? 1 : 0;
}

# A function that jumps to a block of the (asm) function after it: the two
# are one asm function, the second's name an entry in it (as s2ff.pl)
sub merge_runons {
    my $targets = sub {
        my ($f) = @_;
        my (@t, $w);
        $w = sub { for (@{ $_[0]{children} }) { push @t, $_->{children}[0]{content} if $_->{content} =~ /^(j[a-z]+|call)(\.8)?$/ && @{ $_->{children} }; $w->($_) } };
        $w->($f);
        @t;
    };
    my $isasm = sub { @{ $_[0]{children} } && $_[0]{children}[0]{content} eq 'asm' };
    for (my $i = 0; $i + 1 < @fns; $i++) {
        my $f = $fns[$i];
        next unless $isasm->($f);
        # (the next asm function: aliases may come between)
        my ($j) = grep { $isasm->($fns[$_]) } $i + 1 .. $#fns;
        next unless defined $j;
        my $g = $fns[$j];
        my %in_g = map { $_->{content} =~ s/:$//r => 1 } grep { $_->{content} =~ /^\.L.*:$/ } @{ $g->{children} };
        next unless grep { $in_g{$_} } $targets->($f);
        my (undef, @rest) = grep { $_->{content} ne 'align' } @{ $g->{children} };
        my (@own, @later);
        for (@rest) { if (@later || ($_->{content} =~ /:$/ && $_ != $rest[0])) { push @later, $_ } else { push @own, $_ } }
        push @{ $f->{children} }, node($g->{content}, node('asm'), @own), @later;
        splice @fns, $j, 1;
        $i = -1;     # (again from the first: it may jump into what g took in)
    }
}
1;
