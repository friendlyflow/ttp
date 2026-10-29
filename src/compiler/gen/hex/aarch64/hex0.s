// hex0 for aarch64 Linux: hex pairs in, bytes out. The first link of the
// bootstrap: everything after it is built from text by programs built from
// text. Its bytes are hosts/aarch64/hex0.hex0, made from this file once by
// gen/mkhex.pl (a dev aid); the chain never reads this file.
//
//   hex0 < file.hex0 > file
//
// Each pair of hex digits (0-9, A-F, a-f) is one byte, the first digit its
// high half. '#' and ';' start a comment to the end of the line. Every
// other byte (spaces, newlines, ...) is skipped. At the end of stdin the
// status is 0 (a lone last digit is dropped); a failed read or write ends
// with status 1.
//
// One flat file, loaded whole at BASE by its one program header: no
// sections, no linker. Every instruction is 4 bytes, little endian, its
// fields as the Arm manual draws them. Only the stack is written (its
// first byte, argc's, is the buffer of a byte). The registers:
//   x19  the high half of the byte being read, or -1 before its first digit
//   x9   a digit's value

    .equ BASE, 0x600000
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
    .dword phdr - ehdr                  // e_phoff: the program header follows
    .dword 0                            // e_shoff: no section headers
    .word 0                             // e_flags: none on aarch64
    .hword 64                           // e_ehsize: this header's size
    .hword 56                           // e_phentsize: a program header's size
    .hword 1                            // e_phnum: one program header
    .hword 0                            // e_shentsize: no section headers
    .hword 0                            // e_shnum: none
    .hword 0                            // e_shstrndx: none
phdr:                                   // the program header, 56 bytes
    .word 1                             // p_type: PT_LOAD
    .word 5                             // p_flags: PF_R | PF_X, read and run
    .dword 0                            // p_offset: from the file's first byte
    .dword BASE                         // p_vaddr: loaded at BASE
    .dword BASE                         // p_paddr: the same
    .dword end - ehdr                   // p_filesz: the whole file
    .dword end - ehdr                   // p_memsz: the same, no bss
    .dword 0x1000                       // p_align: a page

_start:
    movn    x19, #0                     // mov x19, #-1: no high half yet
next:                                   // the next byte of stdin
    bl      getc                        // x0 = the byte
    cmp     x0, #0x23                   // '#': a comment
    b.eq    comment
    cmp     x0, #0x3b                   // ';': a comment
    b.eq    comment
    sub     x9, x0, #0x30               // '0'-'9' to 0-9
    cmp     x9, #10
    b.lo    digit                       // unsigned: below '0' is large
    sub     x9, x0, #0x41               // 'A'-'F' to 0-5
    cmp     x9, #6
    b.lo    letter
    sub     x9, x0, #0x61               // 'a'-'f' to 0-5
    cmp     x9, #6
    b.hs    next                        // anything else: skipped
letter:
    add     x9, x9, #10                 // 10-15
digit:                                  // x9 = the digit's value, 0-15
    cmp     x19, #0                     // the first digit of a pair?
    b.lt    high
    add     x0, x9, x19, lsl #4         // the second: high half, then this one
    bl      putc
    b       _start                      // the next pair
high:
    orr     x19, xzr, x9                // mov x19, x9: keep it for the second
    b       next
comment:                                // skip to the end of the line
    bl      getc
    cmp     x0, #0x0a                   // '\n'
    b.ne    comment
    b       next

getc:                                   // x0 = the next byte of stdin
    movz    x8, #SYS_read
    movz    x0, #0                      // fd 0, stdin
    add     x1, sp, #0                  // mov x1, sp: into the stack
    movz    x2, #1                      // 1 byte
    svc     #0
    cmp     x0, #0
    b.lt    fail                        // a failed read
    b.eq    done                        // the end of stdin
    ldrb    w0, [sp]                    // the byte, zero-extended
    ret                                 // to x30

putc:                                   // writes x0's low byte to stdout
    strb    w0, [sp]
    movz    x8, #SYS_write
    movz    x0, #1                      // fd 1, stdout
    add     x1, sp, #0                  // from the stack
    movz    x2, #1                      // 1 byte
    svc     #0
    cmp     x0, #1                      // written?
    b.ne    fail
    ret

done:
    movz    x0, #0                      // status 0
    b       exit
fail:
    movz    x0, #1                      // status 1
exit:
    movz    x8, #SYS_exit
    svc     #0
end:
