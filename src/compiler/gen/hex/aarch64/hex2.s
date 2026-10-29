// hex2 for aarch64 Linux: hex0 with labels. The second link of the
// bootstrap, built by hex0 from hosts/aarch64/hex2.hex0 (made from this
// file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
// It builds the seed, ttpc, from hosts/aarch64/ttpc.hex2.
//
//   hex2 < file.hex2 > file
//
// As hex0: each pair of hex digits is a byte, '#' and ';' start a comment
// to the end of the line, every other byte is skipped. And the address of
// the next byte, which starts at 0 and counts every byte written:
//   :name    defines the label name, at that address
//   &name    4 bytes, little endian: name's address (an abs32; a .dword's
//            low half)
//   ^hex     the address of the next byte is this hex number (where a
//            file's addresses jump: its next segment, the labels of a bss)
//   ^~name   stage0-posix's branch (B, BL): d, name's address minus the
//            address of the next byte (the instruction's own), in 26 bits,
//            a multiple of 4; its 3 bytes are written: imm26's low 24 bits
//            (d / 4). The byte after them, written as hex, has imm26's top
//            2 bits and the opcode: 14 B and 94 BL forward, 17 and 97 back.
// and AArch64's other references, which stage0-posix's hex2 does without
// (its code loads addresses from words after it): each scatters its bits
// into an instruction's immediate field and XORs them into the next bytes
// written (the instruction, written with that field zero), as riscv64's:
//   ~name    ADRP: name's page minus the instruction's page (the low 12
//            bits of each cleared), in 33 bits: bits 13:12 to 30:29
//            (immlo), 32:14 to 23:5 (immhi)
//   !name    ADD's :lo12:, after an ADRP: name's address, its bits 11:0 to
//            21:10 (imm12); unchecked
//   @name    B.cond, CBZ, CBNZ (and LDR literal): d in 21 bits, a multiple
//            of 4, bits 20:2 to 23:5 (imm19)
// Their bit layouts are the table kinds before the code, each a list of
// (from bit, bits, to bit) as the Arm manual draws the fields. A name is
// every byte after the sign up to a space, tab or newline. The input is
// read whole, then twice: the first pass gives every label its address,
// the second writes. On an unknown label, a label defined twice, a
// reference out of range, a full table or input and a failed read or
// write it says so on stderr and ends with status 1; else with 0.
//
// One flat file, loaded at BASE by its first program header, read and
// run; the second maps the memory it writes, LABELS to the end of INPUT.
// The registers:
//   x20  the next byte of the input          x21  the end of the input
//   x22  the address of the next byte        x23  the pass, 1 or 2
//   x24  the high half of a byte, or -1      x25  the next free label
//   x26  the bits to XOR into the next bytes written, the lowest first
// A label is 24 bytes: the address of its name in the input, the name's
// length, its address.

    .equ BASE, 0x600000
    .equ LABELS, 0x700000               // 65536 labels of 24 bytes
    .equ LABELS_END, LABELS + 0x10000 * 24
    .equ INPUT, 0x900000                // 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ SYS_read, 63
    .equ SYS_write, 64
    .equ SYS_exit, 93

ehdr:                                   // the ELF header, 64 bytes
    .byte 0x7f, 0x45, 0x4c, 0x46        // e_ident: the magic, 0x7f 'E' 'L' 'F'
    .byte 2                             // EI_CLASS: ELFCLASS64
    .byte 1                             // EI_DATA: ELFDATA2LSB, little endian
    .byte 1                             // EI_VERSION: EV_CURRENT
    .byte 0                             // EI_OSABI: System V
    .byte 0, 0, 0, 0, 0, 0, 0, 0        // EI_ABIVERSION 0, then padding to 16
    .hword 2                            // e_type: ET_EXEC, an executable
    .hword 0xb7                         // e_machine: EM_AARCH64
    .word 1                             // e_version: EV_CURRENT
    .dword BASE + _start - ehdr         // e_entry: the address of _start
    .dword phdr - ehdr                  // e_phoff: the program headers follow
    .dword 0                            // e_shoff: no section headers
    .word 0                             // e_flags: none on aarch64
    .hword 64                           // e_ehsize: this header's size
    .hword 56                           // e_phentsize: a program header's size
    .hword 2                            // e_phnum: two program headers
    .hword 0                            // e_shentsize: no section headers
    .hword 0                            // e_shnum: none
    .hword 0                            // e_shstrndx: none
phdr:                                   // the program: 56 bytes
    .word 1                             // p_type: PT_LOAD
    .word 5                             // p_flags: PF_R | PF_X, read and run
    .dword 0                            // p_offset: from the file's first byte
    .dword BASE                         // p_vaddr: loaded at BASE
    .dword BASE                         // p_paddr: the same
    .dword end - ehdr                   // p_filesz: the whole file
    .dword end - ehdr                   // p_memsz: the same
    .dword 0x1000                       // p_align: a page
                                        // its memory: 56 bytes
    .word 1                             // p_type: PT_LOAD
    .word 6                             // p_flags: PF_R | PF_W, read and write
    .dword 0                            // p_offset: none of the file
    .dword LABELS                       // p_vaddr: the labels, then the input
    .dword LABELS                       // p_paddr: the same
    .dword 0                            // p_filesz: none, all zero
    .dword INPUT_END - LABELS           // p_memsz: to the end of the input
    .dword 0x1000                       // p_align: a page

// The kinds of reference: its sign; its mode (1: name's address, not d;
// 2: the pages' d; 4: its bytes written, not XORed); the bits it must fit
// in, signed; how many low bits must be zero; its pieces, then each piece:
// the bit it starts at, its bits, the bit of the field it goes to.
kinds:
    .byte 0x5e, 4, 26, 2, 1             // '^' (^~name) B, BL: 3 bytes written
    .byte 2, 24, 0                      //   imm26[23:0], d[25:2]
    .byte 0x7e, 2, 33, 0, 2             // '~' ADRP: the pages' d
    .byte 12, 2, 29                     //   immlo, d[13:12] to 30:29
    .byte 14, 19, 5                     //   immhi, d[32:14] to 23:5
    .byte 0x21, 1, 64, 0, 1             // '!' ADD :lo12:, name's address
    .byte 0, 12, 10                     //   imm12, bits 11:0 to 21:10
    .byte 0x40, 0, 21, 2, 1             // '@' B.cond, CBZ, CBNZ: imm19
    .byte 2, 19, 5                      //   d[20:2] to 23:5
    .byte 0                             // the end of the kinds

msg_unknown:    .asciz "hex2: unknown label: "
msg_twice:      .asciz "hex2: label defined twice: "
msg_range:      .asciz "hex2: out of range: "
msg_many:       .asciz "hex2: too many labels"
msg_large:      .asciz "hex2: input too large"
msg_read:       .asciz "hex2: read failed"
msg_write:      .asciz "hex2: write failed"
newline:        .ascii "\n"
    .balign 4                           // the code, 4-byte aligned (zeros)

_start:                                 // read all of stdin into INPUT
    movz    x21, #0x90, lsl #16         // INPUT: the end of what is read
read:
    movz    x2, #0x190, lsl #16         // INPUT_END
    sub     x2, x2, x21                 // the room left
    cbz     x2, too_large
    movz    x8, #SYS_read
    movz    x0, #0                      // fd 0, stdin
    orr     x1, xzr, x21                // mov x1, x21: after what is read
    svc     #0
    cmp     x0, #0
    b.lt    read_failed
    b.eq    read_all                    // the end of stdin
    add     x21, x21, x0
    b       read
read_all:
    movz    x25, #0x70, lsl #16         // LABELS: no labels yet
    movz    x23, #1                     // pass 1
pass:
    movz    x20, #0x90, lsl #16         // INPUT: from the first byte
    movz    x22, #0                     // at address 0
    movn    x24, #0                     // -1: no high half
    movz    x26, #0                     // nothing to XOR
loop:                                   // the next byte of the input
    cmp     x20, x21
    b.hs    pass_end
    ldrb    w0, [x20]
    add     x20, x20, #1
    cmp     x0, #0x23                   // '#': a comment
    b.eq    comment
    cmp     x0, #0x3b                   // ';': a comment
    b.eq    comment
    cmp     x0, #0x3a                   // ':': a label
    b.eq    define
    cmp     x0, #0x26                   // '&': abs32
    b.eq    abs32
    cmp     x0, #0x5e                   // '^': a branch or an address
    b.eq    caret
    adr     x10, kinds                  // a reference of one of the kinds?
kind:
    ldrb    w9, [x10]                   // its sign, 0 after the last
    cbz     x9, digit
    cmp     x0, x9
    b.eq    reference
    ldrb    w11, [x10, #4]              // its pieces, 3 bytes each
    add     x10, x10, #5                // after its 5 bytes
    add     x10, x10, x11
    add     x10, x10, x11
    add     x10, x10, x11
    b       kind
digit:
    bl      hexval                      // x0 = its value, or -1
    cmp     x0, #0
    b.lt    loop                        // not a hex digit: skipped
    cmp     x24, #0                     // the first digit of a pair?
    b.lt    high
    add     x0, x0, x24, lsl #4         // the second: high half, then this one
    bl      emit
    movn    x24, #0                     // the next pair
    b       loop
high:
    orr     x24, xzr, x0                // keep it for the second digit
    b       loop
comment:                                // skip to the end of the line
    cmp     x20, x21
    b.hs    loop
    ldrb    w0, [x20]
    add     x20, x20, #1
    cmp     x0, #0x0a                   // '\n'
    b.ne    comment
    b       loop
pass_end:
    add     x23, x23, #1
    cmp     x23, #2                     // after pass 1, pass 2
    b.eq    pass
    movz    x0, #0                      // after pass 2, status 0
    b       exit

define:                                 // :name
    bl      name
    cmp     x23, #1                     // only in pass 1
    b.ne    loop
    bl      find
    cbnz    x0, twice
    movz    x9, #0x88, lsl #16          // LABELS_END
    cmp     x25, x9
    b.hs    too_many
    str     x1, [x25]                   // its name
    str     x2, [x25, #8]               // its length
    str     x22, [x25, #16]             // its address
    add     x25, x25, #24
    b       loop

abs32:                                  // &name
    bl      name
    cmp     x23, #1                     // pass 1 only counts its 4 bytes
    b.eq    skip4
    bl      find
    cbz     x0, unknown
    ldr     x27, [x0, #16]              // its address
    lsr     x9, x27, #32                // fits in 32 bits, unsigned
    cbnz    x9, range
    movz    x28, #4                     // 4 bytes, the lowest first
emit_bytes:                             // the x28 low bytes of x27
    orr     x0, xzr, x27
    bl      emit
    lsr     x27, x27, #8
    sub     x28, x28, #1
    cbnz    x28, emit_bytes
    b       loop
skip4:
    add     x22, x22, #4
    b       loop

caret:                                  // ^~name or ^hex
    cmp     x20, x21
    b.hs    loop
    ldrb    w0, [x20]
    cmp     x0, #0x7e                   // '~': a branch
    b.ne    origin
    add     x20, x20, #1
    adr     x10, kinds                  // the kind '^', the first
reference:                              // a kind's sign, x10 = the kind
    bl      name                        // (name and find keep x10)
    ldrb    w13, [x10, #1]              // its mode
    cmp     x23, #1                     // pass 1: its 3 bytes, or none
    b.ne    reference_find
    tbz     w13, #2, loop
    add     x22, x22, #3
    b       loop
reference_find:
    bl      find
    cbz     x0, unknown
    ldr     x0, [x0, #16]               // its address
    tbnz    w13, #0, reference_fits     // 1: the address itself
    orr     x11, xzr, x22               // the next byte's address
    tbz     w13, #1, reference_d
    lsr     x0, x0, #12                 // 2: their pages
    lsl     x0, x0, #12
    lsr     x11, x11, #12
    lsl     x11, x11, #12
reference_d:
    sub     x0, x0, x11                 // d
reference_fits:
    ldrb    w9, [x10, #2]               // fits in that many bits, signed:
    movz    x11, #64
    sub     x11, x11, x9
    lslv    x12, x0, x11                // the same, cut to them
    asrv    x12, x12, x11
    cmp     x12, x0
    b.ne    range
    ldrb    w9, [x10, #3]               // its low bits zero
    movz    x11, #1
    lslv    x11, x11, x9
    sub     x11, x11, #1
    ands    xzr, x11, x0                // tst x11, x0
    b.ne    range
    ldrb    w11, [x10, #4]              // its pieces
    add     x10, x10, #5
    movz    x12, #0                     // the field
piece:
    cbz     x11, pieces_done
    ldrb    w14, [x10]                  // from bit
    ldrb    w15, [x10, #1]              // bits
    ldrb    w3, [x10, #2]               // to bit
    lsrv    x4, x0, x14
    movz    x5, #1                      // (1 << bits) - 1
    lslv    x5, x5, x15
    sub     x5, x5, #1
    and     x4, x4, x5
    lslv    x4, x4, x3
    orr     x12, x12, x4
    add     x10, x10, #3
    sub     x11, x11, #1
    b       piece
pieces_done:
    tbnz    w13, #2, reference_bytes
    eor     x26, x26, x12               // into the next bytes written
    b       loop
reference_bytes:                        // 4: its 3 bytes
    orr     x27, xzr, x12
    movz    x28, #3
    b       emit_bytes

origin:                                 // ^hex: the address of the next byte
    movz    x22, #0
origin_digit:
    cmp     x20, x21
    b.hs    loop
    ldrb    w0, [x20]
    bl      hexval
    cmp     x0, #0
    b.lt    loop                        // its end
    add     x20, x20, #1
    add     x22, x0, x22, lsl #4
    b       origin_digit

hexval:                                 // x0 = the value of hex digit x0, or -1
    sub     x9, x0, #0x30               // '0'-'9' to 0-9
    cmp     x9, #10
    b.lo    hexval_done
    sub     x9, x0, #0x41               // 'A'-'F' to 0-5
    cmp     x9, #6
    b.lo    hexval_letter
    sub     x9, x0, #0x61               // 'a'-'f' to 0-5
    cmp     x9, #6
    b.lo    hexval_letter
    movn    x0, #0                      // none: -1
    ret
hexval_letter:
    add     x9, x9, #10                 // 10-15
hexval_done:
    orr     x0, xzr, x9
    ret

name:                                   // x1, x2 = the name at x20, x20 after it
    orr     x1, xzr, x20
name_byte:
    cmp     x20, x21
    b.hs    name_end
    ldrb    w9, [x20]
    cmp     x9, #0x20                   // ends at a space, tab, newline
    b.ls    name_end
    add     x20, x20, #1
    b       name_byte
name_end:
    sub     x2, x20, x1
    ret

find:                                   // x0 = the label of name x1, x2, or 0
    movz    x0, #0x70, lsl #16          // LABELS
find_next:
    cmp     x0, x25
    b.hs    not_found
    ldr     x9, [x0, #8]                // the same length
    cmp     x9, x2
    b.ne    find_on
    ldr     x11, [x0]                   // and the same bytes
    orr     x12, xzr, x1
    add     x14, x1, x2
find_byte:
    cmp     x12, x14
    b.eq    found
    ldrb    w9, [x11]
    ldrb    w15, [x12]
    cmp     x9, x15
    b.ne    find_on
    add     x11, x11, #1
    add     x12, x12, #1
    b       find_byte
find_on:
    add     x0, x0, #24
    b       find_next
not_found:
    movz    x0, #0
found:
    ret

emit:                                   // writes x0 XOR x26's low byte in pass 2, counts it
    add     x22, x22, #1
    eor     x0, x0, x26
    lsr     x26, x26, #8
    cmp     x23, #1
    b.eq    emitted
    strb    w0, [sp]                    // from the stack
    movz    x8, #SYS_write
    movz    x0, #1                      // fd 1, stdout
    add     x1, sp, #0                  // mov x1, sp
    movz    x2, #1                      // 1 byte
    svc     #0
    cmp     x0, #1                      // written?
    b.ne    write_failed
emitted:
    ret

unknown:
    adr     x3, msg_unknown
    b       die
twice:
    adr     x3, msg_twice
    b       die
range:
    adr     x3, msg_range
    b       die
too_many:
    adr     x3, msg_many
    b       die_plain
too_large:
    adr     x3, msg_large
    b       die_plain
read_failed:
    adr     x3, msg_read
    b       die_plain
write_failed:
    adr     x3, msg_write
die_plain:
    movz    x2, #0                      // no name
die:                                    // message x3 (to its 0), then name x1, x2
    orr     x4, xzr, x3
die_length:
    ldrb    w9, [x4]
    cbz     x9, die_write
    add     x4, x4, #1
    b       die_length
die_write:
    sub     x4, x4, x3
    orr     x27, xzr, x1
    orr     x28, xzr, x2
    orr     x1, xzr, x3
    orr     x2, xzr, x4
    bl      ewrite
    orr     x1, xzr, x27
    orr     x2, xzr, x28
    bl      ewrite
    adr     x1, newline
    movz    x2, #1
    bl      ewrite
    movz    x0, #1                      // status 1
exit:
    movz    x8, #SYS_exit
    svc     #0
ewrite:                                 // writes x1, x2 to stderr
    movz    x8, #SYS_write
    movz    x0, #2                      // fd 2, stderr
    svc     #0
    ret
end:
