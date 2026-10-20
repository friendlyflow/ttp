#!/usr/bin/env perl
# relmask.pl — bytes of a riscv64, aarch64 or arm .text with the fields
# relocations fill in set to 0: what GNU as left for the linker (a call's
# auipc and jalr, a GOT or TLS address; aarch64's branch, adrp and lo12
# fields) is not the assembler's to compare.
#
#   perl relmask.pl <objdump -r of the object> <.text bytes> [skip] > masked
#
# skip: the bytes the .text has before the ones given (its offsets less).
#
# A host tool (core Perl only).
use strict;
use warnings;

die "usage: relmask.pl relocs bin [skip]\n" unless @ARGV == 2 || @ARGV == 3;
my ($relocs, $bin, $skip) = @ARGV;
$skip //= 0;
open my $b, '<:raw', $bin or die "relmask: $bin: $!\n";
my $text = do { local $/; <$b> };
close $b;

# the bits a relocation's instruction takes its value in
my %mask = (
    U => 0xfffff000,    # auipc, lui
    I => 0xfff00000,    # addi, ld, jalr
    S => 0xfe000f80,    # sd, sw
    B => 0xfe000f80,    # beq ...
    J => 0xfffff000,    # jal
    CB => 0x1c7c,       # c.beqz, c.bnez
    CJ => 0x1ffc,       # c.j
    A_PAGE => 0x60ffffe0,   # aarch64 adrp: immlo, immhi
    A_LO12 => 0x003ffc00,   # add, ldr, str: imm12
    A_B26 => 0x03ffffff,    # b, bl
    A_B19 => 0x00ffffe0,    # b.cond, cbz, ldr literal
    A_B14 => 0x0007ffe0,    # tbz
    # arm
    A24 => 0x00ffffff,  # b, bl (A32)
    W => 0xffffffff,    # a word of data: an address, an offset of the GOT
    MOV => 0x000f0fff,  # movw, movt (A32)
);
sub field {
    my ($off, $kind) = @_;
    my $w = $kind =~ /^C/ ? 2 : 4;
    return if $off + $w > length $text;
    my $v = $w == 2 ? unpack('v', substr($text, $off, 2)) : unpack('V', substr($text, $off, 4));
    $v &= ~$mask{$kind} & ($w == 2 ? 0xffff : 0xffffffff);
    substr($text, $off, $w) = $w == 2 ? pack('v', $v) : pack('V', $v);
}

open my $r, '<', $relocs or die "relmask: $relocs: $!\n";
my $intext = 0;
while (<$r>) {
    $intext = $1 eq '.text' if /^RELOCATION RECORDS FOR \[(.*)\]/;
    next unless $intext && /^([0-9a-f]+)\s+(R_(?:RISCV|AARCH64|ARM)_\w+)/;
    my ($off, $type) = (hex($1) - $skip, $2);
    next if $off < 0;
    if ($type =~ /^R_RISCV_CALL(_PLT)?$/) { field($off, 'U'); field($off + 4, 'I') }
    elsif ($type =~ /_HI20$/) { field($off, 'U') }
    elsif ($type =~ /_LO12_I$/) { field($off, 'I') }
    elsif ($type =~ /_LO12_S$/) { field($off, 'S') }
    elsif ($type eq 'R_RISCV_BRANCH') { field($off, 'B') }
    elsif ($type eq 'R_RISCV_JAL') { field($off, 'J') }
    elsif ($type eq 'R_RISCV_RVC_BRANCH') { field($off, 'CB') }
    elsif ($type eq 'R_RISCV_RVC_JUMP') { field($off, 'CJ') }
    elsif ($type =~ /^R_RISCV_(RELAX|ALIGN)$/) { }
    elsif ($type =~ /^R_AARCH64_(ADR_PREL_PG_HI21|ADR_GOT_PAGE|TLSIE_ADR_GOTTPREL_PAGE21)$/) { field($off, 'A_PAGE') }
    elsif ($type =~ /^R_AARCH64_(ADD_ABS_LO12_NC|LDST\d+_ABS_LO12_NC|LD64_GOT_LO12_NC|TLSIE_LD64_GOTTPREL_LO12_NC)$/) { field($off, 'A_LO12') }
    elsif ($type =~ /^R_AARCH64_(CALL26|JUMP26)$/) { field($off, 'A_B26') }
    elsif ($type =~ /^R_AARCH64_(CONDBR19|LD_PREL_LO19)$/) { field($off, 'A_B19') }
    elsif ($type eq 'R_AARCH64_TSTBR14') { field($off, 'A_B14') }
    elsif ($type =~ /^R_ARM_(CALL|JUMP24)$/) { field($off, 'A24') }
    elsif ($type =~ /^R_ARM_(ABS32|REL32|GOTPC|GOT32|GOTOFF32|TLS_IE32|TLS_LE32)$/) { field($off, 'W') }
    elsif ($type =~ /^R_ARM_MOV[WT]_/) { field($off, 'MOV') }
    else { die "relmask: no mask for $type\n" }
}
close $r;
binmode STDOUT;
print $text;
