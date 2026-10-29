@ hex2 for arm Linux (EABI): hex0 with labels. The second link of the
@ bootstrap, built by hex0 from hosts/arm/hex2.hex0 (made from this file
@ once by gen/mkhex.pl, a dev aid; the chain never reads this file). It
@ builds the seed, ttpc, from hosts/arm/ttpc.hex2.
@
@   hex2 < file.hex2 > file
@
@ As hex0: each pair of hex digits is a byte, '#' and ';' start a comment
@ to the end of the line, every other byte is skipped. And the address of
@ the next byte, which starts at 0 and counts every byte written:
@   :name    defines the label name, at that address
@   &name    4 bytes, little endian: name's address (an abs32)
@   ^hex     the address of the next byte is this hex number (where a
@            file's addresses jump: its next segment, the labels of a bss)
@   ^~name   stage0-posix's branch (B, BL, B<cond>): d, name's address
@            minus the address of the next byte (the instruction's own)
@            minus 8 (the pc reads 8 ahead), in 26 bits, a multiple of 4;
@            its 3 bytes are written: imm24 (d / 4). The byte after them,
@            written as hex, is cond and the opcode: EA B, EB BL, 0A BEQ,
@            1A BNE, ...
@ and ARM's other references, which stage0-posix's hex2 does without (its
@ code loads addresses from words after it): each scatters its bits into
@ an instruction's immediate field and XORs them into the next bytes
@ written (the instruction, written with that field zero), as riscv64's
@ and aarch64's:
@   !name    MOVW's :lower16:: name's address, its bits 11:0 to 11:0
@            (imm12), 15:12 to 19:16 (imm4)
@   ~name    MOVT's :upper16:: its bits 27:16 to 11:0, 31:28 to 19:16
@ Their bit layouts are the table kinds before the code, each a list of
@ (from bit, bits, to bit) as the Arm manual draws the fields. A name is
@ every byte after the sign up to a space, tab or newline. The input is
@ read whole, then twice: the first pass gives every label its address,
@ the second writes. On an unknown label, a label defined twice, a
@ reference out of range, a full table or input and a failed read or
@ write it says so on stderr and ends with status 1; else with 0.
@
@ One flat file, loaded at BASE by its first program header, read and
@ run; the second maps the memory it writes, LABELS to the end of INPUT.
@ ARM state (ARMv7-A): every instruction is 4 bytes, its condition in its
@ top 4 bits. The registers:
@   r4  the next byte of the input          r5  the end of the input
@   r6  the address of the next byte        r8  the pass, 1 or 2
@   r9  the high half of a byte, or -1      r10 the next free label
@   r11 the bits to XOR into the next bytes written, the lowest first
@   r7  the system call's number, else scratch, as r0-r3, r12 and lr
@ A label is 12 bytes: the address of its name in the input, the name's
@ length, its address.

    .syntax unified
    .arch armv7-a
    .arm
    .equ BASE, 0x10000
    .equ LABELS, 0x100000               @ 65536 labels of 12 bytes
    .equ LABELS_END, LABELS + 0x10000 * 12
    .equ INPUT, 0x200000                @ 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ SYS_read, 3
    .equ SYS_write, 4
    .equ SYS_exit, 1

@ la: reg = the address of sym (movw, movt: its low and high 16 bits)
    .macro la reg, sym
    movw    \reg, #:lower16:(BASE + \sym - ehdr)
    movt    \reg, #:upper16:(BASE + \sym - ehdr)
    .endm

ehdr:                                   @ the ELF header, 52 bytes
    .byte 0x7f, 0x45, 0x4c, 0x46        @ e_ident: the magic, 0x7f 'E' 'L' 'F'
    .byte 1                             @ EI_CLASS: ELFCLASS32
    .byte 1                             @ EI_DATA: ELFDATA2LSB, little endian
    .byte 1                             @ EI_VERSION: EV_CURRENT
    .byte 0                             @ EI_OSABI: System V
    .byte 0, 0, 0, 0, 0, 0, 0, 0        @ EI_ABIVERSION 0, then padding to 16
    .hword 2                            @ e_type: ET_EXEC, an executable
    .hword 40                           @ e_machine: EM_ARM
    .word 1                             @ e_version: EV_CURRENT
    .word BASE + _start - ehdr          @ e_entry: the address of _start
    .word phdr - ehdr                   @ e_phoff: the program headers follow
    .word 0                             @ e_shoff: no section headers
    .word 0x05000200                    @ e_flags: EABI version 5, soft float
    .hword 52                           @ e_ehsize: this header's size
    .hword 32                           @ e_phentsize: a program header's size
    .hword 2                            @ e_phnum: two program headers
    .hword 0                            @ e_shentsize: no section headers
    .hword 0                            @ e_shnum: none
    .hword 0                            @ e_shstrndx: none
phdr:                                   @ the program: 32 bytes
    .word 1                             @ p_type: PT_LOAD
    .word 0                             @ p_offset: from the file's first byte
    .word BASE                          @ p_vaddr: loaded at BASE
    .word BASE                          @ p_paddr: the same
    .word end - ehdr                    @ p_filesz: the whole file
    .word end - ehdr                    @ p_memsz: the same
    .word 5                             @ p_flags: PF_R | PF_X, read and run
    .word 0x1000                        @ p_align: a page
                                        @ its memory: 32 bytes
    .word 1                             @ p_type: PT_LOAD
    .word 0                             @ p_offset: none of the file
    .word LABELS                        @ p_vaddr: the labels, then the input
    .word LABELS                        @ p_paddr: the same
    .word 0                             @ p_filesz: none, all zero
    .word INPUT_END - LABELS            @ p_memsz: to the end of the input
    .word 6                             @ p_flags: PF_R | PF_W, read and write
    .word 0x1000                        @ p_align: a page

@ The kinds of reference: its sign; its mode (1: name's address, not d;
@ 4: its bytes written, not XORed); the bits it must fit in, signed; how
@ many low bits must be zero; what d has subtracted (the pc's 8); its
@ pieces, then each piece: the bit it starts at, its bits, the bit of the
@ field it goes to.
kinds:
    .byte 0x5e, 4, 26, 2, 8, 1          @ '^' (^~name) B, BL: 3 bytes written
    .byte 2, 24, 0                      @   imm24, d[25:2]
    .byte 0x21, 1, 32, 0, 0, 2          @ '!' MOVW :lower16:, name's address
    .byte 0, 12, 0                      @   imm12, bits 11:0
    .byte 12, 4, 16                     @   imm4, bits 15:12 to 19:16
    .byte 0x7e, 1, 32, 0, 0, 2          @ '~' MOVT :upper16:, name's address
    .byte 16, 12, 0                     @   imm12, bits 27:16 to 11:0
    .byte 28, 4, 16                     @   imm4, bits 31:28 to 19:16
    .byte 0                             @ the end of the kinds

msg_unknown:    .asciz "hex2: unknown label: "
msg_twice:      .asciz "hex2: label defined twice: "
msg_range:      .asciz "hex2: out of range: "
msg_many:       .asciz "hex2: too many labels"
msg_large:      .asciz "hex2: input too large"
msg_read:       .asciz "hex2: read failed"
msg_write:      .asciz "hex2: write failed"
newline:        .ascii "\n"
    .balign 4                           @ the code, 4-byte aligned (zeros)

_start:                                 @ read all of stdin into INPUT
    mov     r5, #INPUT                  @ the end of what is read
read:
    mov     r2, #INPUT_END
    subs    r2, r2, r5                  @ the room left
    beq     too_large
    mov     r7, #SYS_read
    mov     r0, #0                      @ fd 0, stdin
    mov     r1, r5                      @ after what is read
    svc     #0
    cmp     r0, #0
    blt     read_failed
    beq     read_all                    @ the end of stdin
    add     r5, r5, r0
    b       read
read_all:
    mov     r10, #LABELS                @ no labels yet
    mov     r8, #1                      @ pass 1
pass:
    mov     r4, #INPUT                  @ from the first byte
    mov     r6, #0                      @ at address 0
    mvn     r9, #0                      @ -1: no high half
    mov     r11, #0                     @ nothing to XOR
loop:                                   @ the next byte of the input
    cmp     r4, r5
    bhs     pass_end
    ldrb    r0, [r4], #1                @ and r4 after it
    cmp     r0, #0x23                   @ '#': a comment
    beq     comment
    cmp     r0, #0x3b                   @ ';': a comment
    beq     comment
    cmp     r0, #0x3a                   @ ':': a label
    beq     define
    cmp     r0, #0x26                   @ '&': abs32
    beq     abs32
    cmp     r0, #0x5e                   @ '^': a branch or an address
    beq     caret
    adr     r3, kinds                   @ a reference of one of the kinds?
kind:
    ldrb    r1, [r3]                    @ its sign, 0 after the last
    cmp     r1, #0
    beq     digit
    cmp     r0, r1
    beq     reference
    ldrb    r1, [r3, #5]                @ its pieces, 3 bytes each
    add     r3, r3, #6                  @ after its 6 bytes
    add     r1, r1, r1, lsl #1
    add     r3, r3, r1
    b       kind
digit:
    bl      hexval                      @ r0 = its value, or -1
    cmp     r0, #0
    blt     loop                        @ not a hex digit: skipped
    cmp     r9, #0                      @ the first digit of a pair?
    blt     high
    add     r0, r0, r9, lsl #4          @ the second: high half, then this one
    bl      emit
    mvn     r9, #0                      @ the next pair
    b       loop
high:
    mov     r9, r0                      @ keep it for the second digit
    b       loop
comment:                                @ skip to the end of the line
    cmp     r4, r5
    bhs     loop
    ldrb    r0, [r4], #1
    cmp     r0, #0x0a                   @ '\n'
    bne     comment
    b       loop
pass_end:
    add     r8, r8, #1
    cmp     r8, #2                      @ after pass 1, pass 2
    beq     pass
    mov     r0, #0                      @ after pass 2, status 0
    b       exit

define:                                 @ :name
    bl      name
    cmp     r8, #1                      @ only in pass 1
    bne     loop
    bl      find
    cmp     r0, #0
    bne     twice
    cmp     r10, #LABELS_END
    bhs     too_many
    str     r1, [r10]                   @ its name
    str     r2, [r10, #4]               @ its length
    str     r6, [r10, #8]               @ its address
    add     r10, r10, #12
    b       loop

abs32:                                  @ &name
    bl      name
    cmp     r8, #1                      @ pass 1 only counts its 4 bytes
    addeq   r6, r6, #4
    beq     loop
    bl      find
    cmp     r0, #0
    beq     unknown
    ldr     r12, [r0, #8]               @ its address
    mov     r3, #4                      @ 4 bytes, the lowest first
emit_bytes:                             @ the r3 low bytes of r12
    mov     r0, r12
    bl      emit
    lsr     r12, r12, #8
    subs    r3, r3, #1
    bne     emit_bytes
    b       loop

caret:                                  @ ^~name or ^hex
    cmp     r4, r5
    bhs     loop
    ldrb    r0, [r4]
    cmp     r0, #0x7e                   @ '~': a branch
    bne     origin
    add     r4, r4, #1
    adr     r3, kinds                   @ the kind '^', the first
reference:                              @ a kind's sign, r3 = the kind
    bl      name                        @ (name and find keep r3)
    cmp     r8, #1                      @ pass 1: its 3 bytes, or none
    bne     reference_find
    ldrb    r12, [r3, #1]               @ its mode
    tst     r12, #4
    addne   r6, r6, #3
    b       loop
reference_find:
    bl      find
    cmp     r0, #0
    beq     unknown
    ldr     r0, [r0, #8]                @ its address
    ldrb    r12, [r3, #1]               @ its mode
    tst     r12, #1                     @ 1: the address itself
    bne     reference_fits
    sub     r0, r0, r6                  @ d: from the next byte's address
    ldrb    r1, [r3, #4]                @ less the pc's 8
    sub     r0, r0, r1
reference_fits:
    ldrb    r1, [r3, #2]                @ fits in that many bits, signed:
    rsb     r1, r1, #32
    lsl     r2, r0, r1                  @ the same, cut to them
    asr     r2, r2, r1
    cmp     r2, r0
    bne     range
    ldrb    r1, [r3, #3]                @ its low bits zero
    mov     r2, #1
    lsl     r2, r2, r1
    sub     r2, r2, #1
    tst     r2, r0
    bne     range
    ldrb    r1, [r3, #5]                @ its pieces
    add     r3, r3, #6
    mov     r2, #0                      @ the field
piece:
    cmp     r1, #0
    beq     pieces_done
    ldrb    r7, [r3]                    @ from bit
    lsr     r7, r0, r7
    ldrb    lr, [r3, #1]                @ bits: cut to them
    rsb     lr, lr, #32
    lsl     r7, r7, lr
    lsr     r7, r7, lr
    ldrb    lr, [r3, #2]                @ to bit
    orr     r2, r2, r7, lsl lr
    add     r3, r3, #3
    sub     r1, r1, #1
    b       piece
pieces_done:
    tst     r12, #4
    bne     reference_bytes
    eor     r11, r11, r2                @ into the next bytes written
    b       loop
reference_bytes:                        @ 4: its 3 bytes
    mov     r12, r2
    mov     r3, #3
    b       emit_bytes

origin:                                 @ ^hex: the address of the next byte
    mov     r6, #0
origin_digit:
    cmp     r4, r5
    bhs     loop
    ldrb    r0, [r4]
    bl      hexval
    cmp     r0, #0
    blt     loop                        @ its end
    add     r4, r4, #1
    add     r6, r0, r6, lsl #4
    b       origin_digit

hexval:                                 @ r0 = the value of hex digit r0, or -1 (uses r7)
    sub     r7, r0, #0x30               @ '0'-'9' to 0-9
    cmp     r7, #10
    blo     hexval_done
    sub     r7, r0, #0x41               @ 'A'-'F' to 0-5
    cmp     r7, #6
    blo     hexval_letter
    sub     r7, r0, #0x61               @ 'a'-'f' to 0-5
    cmp     r7, #6
    blo     hexval_letter
    mvn     r0, #0                      @ none: -1
    bx      lr
hexval_letter:
    add     r7, r7, #10                 @ 10-15
hexval_done:
    mov     r0, r7
    bx      lr

name:                                   @ r1, r2 = the name at r4, r4 after it (uses r7)
    mov     r1, r4
name_byte:
    cmp     r4, r5
    bhs     name_end
    ldrb    r7, [r4]
    cmp     r7, #0x20                   @ ends at a space, tab, newline
    bls     name_end
    add     r4, r4, #1
    b       name_byte
name_end:
    sub     r2, r4, r1
    bx      lr

find:                                   @ r0 = the label of name r1, r2, or 0 (uses r7, r12)
    push    {r4, r5}
    mov     r0, #LABELS
find_next:
    cmp     r0, r10
    bhs     not_found
    ldr     r7, [r0, #4]                @ the same length
    cmp     r7, r2
    bne     find_on
    ldr     r12, [r0]                   @ and the same bytes
    mov     r4, #0
find_byte:
    cmp     r4, r2
    beq     found
    ldrb    r7, [r12, r4]
    ldrb    r5, [r1, r4]
    cmp     r7, r5
    bne     find_on
    add     r4, r4, #1
    b       find_byte
find_on:
    add     r0, r0, #12
    b       find_next
not_found:
    mov     r0, #0
found:
    pop     {r4, r5}
    bx      lr

emit:                                   @ writes r0 XOR r11's low byte in pass 2, counts it (uses r1, r2, r7)
    add     r6, r6, #1
    eor     r0, r0, r11
    lsr     r11, r11, #8
    cmp     r8, #1
    bxeq    lr
    strb    r0, [sp]                    @ from the stack
    mov     r7, #SYS_write
    mov     r0, #1                      @ fd 1, stdout
    mov     r1, sp
    mov     r2, #1                      @ 1 byte
    svc     #0
    cmp     r0, #1                      @ written?
    bne     write_failed
    bx      lr

unknown:
    la      r3, msg_unknown
    b       die
twice:
    la      r3, msg_twice
    b       die
range:
    la      r3, msg_range
    b       die
too_many:
    la      r3, msg_many
    b       die_plain
too_large:
    la      r3, msg_large
    b       die_plain
read_failed:
    la      r3, msg_read
    b       die_plain
write_failed:
    la      r3, msg_write
die_plain:
    mov     r2, #0                      @ no name
die:                                    @ message r3 (to its 0), then name r1, r2
    mov     r12, r3
die_length:
    ldrb    r7, [r12]
    cmp     r7, #0
    addne   r12, r12, #1
    bne     die_length
    sub     r12, r12, r3
    mov     r4, r1
    mov     r5, r2
    mov     r1, r3
    mov     r2, r12
    bl      ewrite
    mov     r1, r4
    mov     r2, r5
    bl      ewrite
    la      r1, newline
    mov     r2, #1
    bl      ewrite
    mov     r0, #1                      @ status 1
exit:
    mov     r7, #SYS_exit
    svc     #0
ewrite:                                 @ writes r1, r2 to stderr
    mov     r7, #SYS_write
    mov     r0, #2                      @ fd 2, stderr
    svc     #0
    bx      lr
end:
