#!/usr/bin/env perl
# relmask.pl — bytes of a riscv64 or arm .text with the fields relocations fill in
# set to 0: what GNU as left for the linker (a call's auipc and jalr, a
# GOT or TLS address) is not the assembler's to compare.
#
#   perl relmask.pl <objdump -r of the object> <.text bytes> > masked
#
# A host tool (core Perl only).
use strict;
use warnings;

die "usage: relmask.pl relocs bin\n" unless @ARGV == 2;
my ($relocs, $bin) = @ARGV;
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
    next unless $intext && /^([0-9a-f]+)\s+(R_(?:RISCV|ARM)_\w+)/;
    my ($off, $type) = (hex $1, $2);
    if ($type =~ /^R_RISCV_CALL(_PLT)?$/) { field($off, 'U'); field($off + 4, 'I') }
    elsif ($type =~ /_HI20$/) { field($off, 'U') }
    elsif ($type =~ /_LO12_I$/) { field($off, 'I') }
    elsif ($type =~ /_LO12_S$/) { field($off, 'S') }
    elsif ($type eq 'R_RISCV_BRANCH') { field($off, 'B') }
    elsif ($type eq 'R_RISCV_JAL') { field($off, 'J') }
    elsif ($type eq 'R_RISCV_RVC_BRANCH') { field($off, 'CB') }
    elsif ($type eq 'R_RISCV_RVC_JUMP') { field($off, 'CJ') }
    elsif ($type =~ /^R_RISCV_(RELAX|ALIGN)$/) { }
    elsif ($type =~ /^R_ARM_(CALL|JUMP24)$/) { field($off, 'A24') }
    elsif ($type =~ /^R_ARM_(ABS32|REL32|GOTPC|GOT32|GOTOFF32|TLS_IE32|TLS_LE32)$/) { field($off, 'W') }
    elsif ($type =~ /^R_ARM_MOV[WT]_/) { field($off, 'MOV') }
    else { die "relmask: no mask for $type\n" }
}
close $r;
binmode STDOUT;
print $text;
