# hex2 for riscv64 Linux: hex0 with labels. The second link of the
# bootstrap, built by hex0 from hosts/riscv64/hex2.hex0 (made from this
# file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
# It builds the seed, ttpc, from hosts/riscv64/ttpc.hex2.
#
#   hex2 < file.hex2 > file
#
# As hex0: each pair of hex digits is a byte, '#' and ';' start a comment
# to the end of the line, every other byte is skipped. And the address of
# the next byte, which starts at 0 and counts every byte written:
#   :name    defines the label name, at that address
#   &name    4 bytes, little endian: name's address (an abs32; a .dword's
#            low half)
#   ^hex     the address of the next byte is this hex number (where a
#            file's addresses jump: its next segment, the labels of a bss)
#   .hex     a word, 8 hex digits: its 4 bytes (the first pair lowest)
#            are XORed into the next bytes written, as a reference's bits
#            are (below); stage0-posix's word, which M1 writes for an
#            instruction's registers and immediates
# and RISC-V's references, as stage0-posix's hex2 has them: each takes d,
# name's address minus the address of the next byte (the instruction's
# own), scatters its bits into an instruction's immediate field and XORs
# them into the next bytes written (the instruction, written with that
# field zero):
#   ~name    U (auipc): d + 0x800, its bits 31:12 (the 0x800 makes up for
#            the low part's sign); d + 0x800 must fit in 32 bits, signed
#   !name    I (the addi, ld or jalr after an auipc): d + 4 (from the
#            auipc, 4 bytes before), its bits 11:0 into 31:20; unchecked:
#            the low part of the auipc's
#   @name    B (beq ...): d in 13 bits, even
#   $name    J (jal): d in 21 bits, even
# and two for the compressed instructions, which stage0-posix uses none of:
#   |name    CB (c.beqz, c.bnez): d in 9 bits, even
#   *name    CJ (c.j): d in 12 bits, even
# Their bit layouts are the table kinds before the code, each a list of (from
# bit, bits, to bit) as the RISC-V manual draws the formats. A name is
# every byte after the sign up to a space, tab or newline. The input is
# read whole, then twice: the first pass gives every label its address,
# the second writes. On an unknown label, a label defined twice, a
# reference out of range, a word that is not 8 hex digits, a full table
# or input and a failed read or write it says so on stderr and ends with status 1; else with 0.
#
# One flat file, loaded at BASE by its first program header, read and
# run; the second maps the memory it writes, LABELS to the end of INPUT.
# RV64I only, no compressed instructions. The registers:
#   s2  the next byte of the input          s3  the end of the input
#   s4  the address of the next byte        s5  the pass, 1 or 2
#   s6  the high half of a byte, or -1      s7  the next free label
#   s8  the bits to XOR into the next bytes written, the lowest first
# A label is 24 bytes: the address of its name in the input, the name's
# length, its address.

    .equ BASE, 0x600000
    .equ LABELS, 0x700000               # 65536 labels of 24 bytes
    .equ LABELS_END, LABELS + 0x10000 * 24
    .equ INPUT, 0x900000                # 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ SYS_read, 63
    .equ SYS_write, 64
    .equ SYS_exit, 93

ehdr:                                   # the ELF header, 64 bytes
    .byte 0x7f, 0x45, 0x4c, 0x46        # e_ident: the magic, 0x7f 'E' 'L' 'F'
    .byte 2                             # EI_CLASS: ELFCLASS64
    .byte 1                             # EI_DATA: ELFDATA2LSB, little endian
    .byte 1                             # EI_VERSION: EV_CURRENT
    .byte 0                             # EI_OSABI: System V
    .byte 0, 0, 0, 0, 0, 0, 0, 0        # EI_ABIVERSION 0, then padding to 16
    .half 2                             # e_type: ET_EXEC, an executable
    .half 0xf3                          # e_machine: EM_RISCV
    .word 1                             # e_version: EV_CURRENT
    .dword BASE + _start - ehdr         # e_entry: the address of _start
    .dword phdr - ehdr                  # e_phoff: the program headers follow
    .dword 0                            # e_shoff: no section headers
    .word 0                             # e_flags: no RVC, soft float (none used)
    .half 64                            # e_ehsize: this header's size
    .half 56                            # e_phentsize: a program header's size
    .half 2                             # e_phnum: two program headers
    .half 0                             # e_shentsize: no section headers
    .half 0                             # e_shnum: none
    .half 0                             # e_shstrndx: none
phdr:                                   # the program: 56 bytes
    .word 1                             # p_type: PT_LOAD
    .word 5                             # p_flags: PF_R | PF_X, read and run
    .dword 0                            # p_offset: from the file's first byte
    .dword BASE                         # p_vaddr: loaded at BASE
    .dword BASE                         # p_paddr: the same
    .dword end - ehdr                   # p_filesz: the whole file
    .dword end - ehdr                   # p_memsz: the same
    .dword 0x1000                       # p_align: a page
                                        # its memory: 56 bytes
    .word 1                             # p_type: PT_LOAD
    .word 6                             # p_flags: PF_R | PF_W, read and write
    .dword 0                            # p_offset: none of the file
    .dword LABELS                       # p_vaddr: the labels, then the input
    .dword LABELS                       # p_paddr: the same
    .dword 0                            # p_filesz: none, all zero
    .dword INPUT_END - LABELS           # p_memsz: to the end of the input
    .dword 0x1000                       # p_align: a page


# The kinds of reference: its sign, the bits d must fit in (signed), 1 if
# d must be even, its pieces, the addend (2 bytes), then each piece: the
# bit of d it starts at, its bits, the bit of the field it goes to.
kinds:
    .byte 0x7e, 32, 0, 1                # '~' U: d + 0x800
    .half 0x800
    .byte 12, 20, 12                    #   imm[31:12] to 31:12
    .byte 0x21, 64, 0, 1                # '!' I: d + 4, unchecked
    .half 4
    .byte 0, 12, 20                     #   imm[11:0] to 31:20
    .byte 0x40, 13, 1, 4                # '@' B
    .half 0
    .byte 1, 4, 8                       #   imm[4:1] to 11:8
    .byte 5, 6, 25                      #   imm[10:5] to 30:25
    .byte 11, 1, 7                      #   imm[11] to 7
    .byte 12, 1, 31                     #   imm[12] to 31
    .byte 0x24, 21, 1, 4                # '$' J
    .half 0
    .byte 1, 10, 21                     #   imm[10:1] to 30:21
    .byte 11, 1, 20                     #   imm[11] to 20
    .byte 12, 8, 12                     #   imm[19:12] to 19:12
    .byte 20, 1, 31                     #   imm[20] to 31
    .byte 0x7c, 9, 1, 5                 # '|' CB
    .half 0
    .byte 1, 2, 3                       #   offset[2:1] to 4:3
    .byte 3, 2, 10                      #   offset[4:3] to 11:10
    .byte 5, 1, 2                       #   offset[5] to 2
    .byte 6, 2, 5                       #   offset[7:6] to 6:5
    .byte 8, 1, 12                      #   offset[8] to 12
    .byte 0x2a, 12, 1, 8                # '*' CJ
    .half 0
    .byte 1, 3, 3                       #   offset[3:1] to 5:3
    .byte 4, 1, 11                      #   offset[4] to 11
    .byte 5, 1, 2                       #   offset[5] to 2
    .byte 6, 1, 7                       #   offset[6] to 7
    .byte 7, 1, 6                       #   offset[7] to 6
    .byte 8, 2, 9                       #   offset[9:8] to 10:9
    .byte 10, 1, 8                      #   offset[10] to 8
    .byte 11, 1, 12                     #   offset[11] to 12
    .byte 0                             # the end of the kinds

msg_unknown:    .asciz "hex2: unknown label: "
msg_twice:      .asciz "hex2: label defined twice: "
msg_range:      .asciz "hex2: out of range: "
msg_many:       .asciz "hex2: too many labels"
msg_word:       .asciz "hex2: a word is 8 hex digits"
msg_large:      .asciz "hex2: input too large"
msg_read:       .asciz "hex2: read failed"
msg_write:      .asciz "hex2: write failed"
newline:        .ascii "\n"
    .balign 4                           # the code, 4-byte aligned (zeros)

_start:                                 # read all of stdin into INPUT
    li      s3, INPUT                   # the end of what is read
read:
    li      a2, INPUT_END
    sub     a2, a2, s3                  # the room left
    beq     a2, zero, too_large
    li      a7, SYS_read
    li      a0, 0                       # fd 0, stdin
    mv      a1, s3                      # after what is read
    ecall
    blt     a0, zero, read_failed
    beq     a0, zero, read_all          # the end of stdin
    add     s3, s3, a0
    j       read
read_all:
    li      s7, LABELS                  # no labels yet
    li      s5, 1                       # pass 1
pass:
    li      s2, INPUT                   # from the first byte
    li      s4, 0                       # at address 0
    li      s6, -1                      # no high half
    li      s8, 0                       # nothing to XOR
loop:                                   # the next byte of the input
    bgeu    s2, s3, pass_end
    lbu     a0, 0(s2)
    addi    s2, s2, 1
    li      t0, 0x23                    # '#': a comment
    beq     a0, t0, comment
    li      t0, 0x3b                    # ';': a comment
    beq     a0, t0, comment
    li      t0, 0x3a                    # ':': a label
    beq     a0, t0, define
    li      t0, 0x26                    # '&': abs32
    beq     a0, t0, abs32
    li      t0, 0x5e                    # '^': an address
    beq     a0, t0, origin
    li      t0, 0x2e                    # '.': a word
    beq     a0, t0, word
    la      t1, kinds                   # a reference of one of the kinds?
kind:
    lbu     t0, 0(t1)                   # its sign, 0 after the last
    beq     t0, zero, digit
    beq     a0, t0, reference
    lbu     t2, 3(t1)                   # its pieces, 3 bytes each
    addi    t1, t1, 6                   # after its 6 bytes
    add     t1, t1, t2
    add     t1, t1, t2
    add     t1, t1, t2
    j       kind
digit:
    jal     ra, hexval                  # a0 = its value, or -1
    blt     a0, zero, loop              # not a hex digit: skipped
    blt     s6, zero, high              # the first digit of a pair?
    slli    s6, s6, 4                   # the second: high half, then this one
    or      a0, a0, s6
    jal     ra, emit
    li      s6, -1                      # the next pair
    j       loop
high:
    mv      s6, a0                      # keep it for the second digit
    j       loop
comment:                                # skip to the end of the line
    bgeu    s2, s3, loop
    lbu     a0, 0(s2)
    addi    s2, s2, 1
    li      t0, 0x0a                    # '\n'
    bne     a0, t0, comment
    j       loop
pass_end:
    addi    s5, s5, 1
    li      t0, 2                       # after pass 1, pass 2
    beq     s5, t0, pass
    li      a0, 0                       # after pass 2, status 0
    j       exit

define:                                 # :name
    jal     ra, name
    li      t0, 1                       # only in pass 1
    bne     s5, t0, loop
    jal     ra, find
    bne     a0, zero, twice
    li      t0, LABELS_END
    bgeu    s7, t0, too_many
    sd      a1, 0(s7)                   # its name
    sd      a2, 8(s7)                   # its length
    sd      s4, 16(s7)                  # its address
    addi    s7, s7, 24
    j       loop

abs32:                                  # &name
    jal     ra, name
    li      t0, 1                       # pass 1 only counts its 4 bytes
    beq     s5, t0, skip4
    jal     ra, find
    beq     a0, zero, unknown
    ld      s9, 16(a0)                  # its address
    srli    t0, s9, 32                  # fits in 32 bits, unsigned
    bne     t0, zero, range
    li      s10, 4                      # 4 bytes, the lowest first
emit4:
    andi    a0, s9, 0xff
    jal     ra, emit
    srli    s9, s9, 8
    addi    s10, s10, -1
    bne     s10, zero, emit4
    j       loop
skip4:
    addi    s4, s4, 4
    j       loop

reference:                              # a kind's sign, t1 = the kind
    jal     ra, name                    # (name and find keep t1)
    li      t0, 1                       # pass 1: no bytes of its own
    beq     s5, t0, loop
    jal     ra, find
    beq     a0, zero, unknown
    ld      a0, 16(a0)                  # its address
    sub     a0, a0, s4                  # d: minus the next byte's
    lbu     t0, 4(t1)                   # plus the kind's addend, 2 bytes
    lbu     t2, 5(t1)                   # (bytes: the table is not aligned)
    slli    t2, t2, 8
    or      t0, t0, t2
    add     a0, a0, t0
    lbu     t0, 1(t1)                   # fits in that many bits, signed:
    li      t2, 64
    sub     t2, t2, t0
    sll     t3, a0, t2                  # the same, cut to them
    sra     t3, t3, t2
    bne     t3, a0, range
    lbu     t0, 2(t1)                   # 1: must be even
    and     t0, t0, a0
    bne     t0, zero, range
    lbu     t2, 3(t1)                   # its pieces
    addi    t1, t1, 6
    li      t3, 0                       # the field
piece:
    beq     t2, zero, pieces_done
    lbu     t4, 0(t1)                   # from bit
    lbu     t5, 1(t1)                   # bits
    lbu     t6, 2(t1)                   # to bit
    srl     a3, a0, t4
    li      a4, 1                       # (1 << bits) - 1
    sll     a4, a4, t5
    addi    a4, a4, -1
    and     a3, a3, a4
    sll     a3, a3, t6
    or      t3, t3, a3
    addi    t1, t1, 3
    addi    t2, t2, -1
    j       piece
pieces_done:
    xor     s8, s8, t3                  # into the next bytes written
    j       loop

origin:                                 # ^hex: the address of the next byte
    li      s4, 0
origin_digit:
    bgeu    s2, s3, loop
    lbu     a0, 0(s2)
    jal     ra, hexval
    blt     a0, zero, loop              # its end
    addi    s2, s2, 1
    slli    s4, s4, 4
    or      s4, s4, a0
    j       origin_digit

word:                                   # .hex: 8 hex digits, XORed into s8
    li      a3, 0                       # the word
    li      a4, 4                       # the bit the next digit goes to:
word_digit:                             # 4 0 12 8 20 16 28 24, pair by pair
    bgeu    s2, s3, bad_word
    lbu     a0, 0(s2)
    addi    s2, s2, 1
    jal     ra, hexval                  # (keeps a3, a4)
    blt     a0, zero, bad_word
    sll     a0, a0, a4
    or      a3, a3, a0
    andi    t0, a4, 4                   # a pair's high half: then its low
    addi    a4, a4, -4
    bne     t0, zero, word_digit
    addi    a4, a4, 16                  # its low half: the next pair's high
    li      t0, 32                      # after the fourth pair, 36: done
    bltu    a4, t0, word_digit
    xor     s8, s8, a3                  # into the next bytes written
    j       loop

hexval:                                 # a0 = the value of hex digit a0, or -1
    addi    t0, a0, -0x30               # '0'-'9' to 0-9
    li      t2, 10
    bltu    t0, t2, hexval_done
    ori     t0, a0, 0x20                # 'A'-'F' to 'a'-'f'
    addi    t0, t0, -0x57               # 'a'-'f' to 10-15
    addi    t2, t0, -10                 # 0-5 for 'a'-'f'
    li      t3, 6
    bltu    t2, t3, hexval_done
    li      t0, -1                      # none
hexval_done:
    mv      a0, t0
    ret

name:                                   # a1, a2 = the name at s2, s2 after it
    mv      a1, s2
name_byte:
    bgeu    s2, s3, name_end
    lbu     t0, 0(s2)
    li      t2, 0x20                    # ends at a space, tab, newline
    bgeu    t2, t0, name_end
    addi    s2, s2, 1
    j       name_byte
name_end:
    sub     a2, s2, a1
    ret

find:                                   # a0 = the label of name a1, a2, or 0
    li      a0, LABELS
find_next:
    bgeu    a0, s7, not_found
    ld      t0, 8(a0)                   # the same length
    bne     t0, a2, find_on
    ld      t2, 0(a0)                   # and the same bytes
    mv      t3, a1
    add     t4, a1, a2
find_byte:
    beq     t3, t4, found
    lbu     t5, 0(t2)
    lbu     t6, 0(t3)
    bne     t5, t6, find_on
    addi    t2, t2, 1
    addi    t3, t3, 1
    j       find_byte
find_on:
    addi    a0, a0, 24
    j       find_next
not_found:
    li      a0, 0
found:
    ret

emit:                                   # writes a0 XOR s8's low byte in pass 2, counts it
    addi    s4, s4, 1
    andi    t0, s8, 0xff
    xor     a0, a0, t0
    srli    s8, s8, 8
    li      t0, 1
    beq     s5, t0, emitted
    sb      a0, 0(sp)                   # from the stack
    li      a7, SYS_write
    li      a0, 1                       # fd 1, stdout
    mv      a1, sp
    li      a2, 1                       # 1 byte
    ecall
    li      t0, 1                       # written?
    bne     a0, t0, write_failed
emitted:
    ret

unknown:
    la      a3, msg_unknown
    j       die
twice:
    la      a3, msg_twice
    j       die
range:
    la      a3, msg_range
    j       die
too_many:
    la      a3, msg_many
    j       die_plain
bad_word:
    la      a3, msg_word
    j       die_plain
too_large:
    la      a3, msg_large
    j       die_plain
read_failed:
    la      a3, msg_read
    j       die_plain
write_failed:
    la      a3, msg_write
die_plain:
    li      a2, 0                       # no name
die:                                    # message a3 (to its 0), then name a1, a2
    mv      a4, a3
die_length:
    lbu     t0, 0(a4)
    beq     t0, zero, die_write
    addi    a4, a4, 1
    j       die_length
die_write:
    sub     a4, a4, a3
    mv      s9, a1
    mv      s10, a2
    mv      a1, a3
    mv      a2, a4
    jal     ra, ewrite
    mv      a1, s9
    mv      a2, s10
    jal     ra, ewrite
    la      a1, newline
    li      a2, 1
    jal     ra, ewrite
    li      a0, 1                       # status 1
exit:
    li      a7, SYS_exit
    ecall
ewrite:                                 # writes a1, a2 to stderr
    li      a7, SYS_write
    li      a0, 2                       # fd 2, stderr
    ecall
    ret
end:
