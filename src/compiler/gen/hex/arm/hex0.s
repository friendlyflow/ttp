@ hex0 for arm Linux (EABI): hex pairs in, bytes out. The first link of
@ the bootstrap: everything after it is built from text by programs built
@ from text. Its bytes are hosts/arm/hex0.hex0, made from this file once by
@ gen/mkhex.pl (a dev aid); the chain never reads this file.
@
@   hex0 < file.hex0 > file
@
@ Each pair of hex digits (0-9, A-F, a-f) is one byte, the first digit its
@ high half. '#' and ';' start a comment to the end of the line. Every
@ other byte (spaces, newlines, ...) is skipped. At the end of stdin the
@ status is 0 (a lone last digit is dropped); a failed read or write ends
@ with status 1.
@
@ One flat file, loaded whole at BASE by its one program header: no
@ sections, no linker. ARM state (ARMv7-A, no Thumb): every instruction is
@ 4 bytes, little endian, its fields as the Arm manual draws them, its
@ condition (cond) in its top 4 bits, 1110 (al) unless it says otherwise.
@ Only the stack is written (its first byte, argc's, is the buffer of a
@ byte). The registers:
@   r4  the high half of the byte being read, or -1 before its first digit
@   r5  a digit's value
@   r7  the system call's number

    .syntax unified
    .arch armv7-a
    .arm
    .equ BASE, 0x10000
    .equ SYS_read, 3
    .equ SYS_write, 4
    .equ SYS_exit, 1

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
    .word phdr - ehdr                   @ e_phoff: the program header follows
    .word 0                             @ e_shoff: no section headers
    .word 0x05000200                    @ e_flags: EABI version 5, soft float
    .hword 52                           @ e_ehsize: this header's size
    .hword 32                           @ e_phentsize: a program header's size
    .hword 1                            @ e_phnum: one program header
    .hword 0                            @ e_shentsize: no section headers
    .hword 0                            @ e_shnum: none
    .hword 0                            @ e_shstrndx: none
phdr:                                   @ the program header, 32 bytes
    .word 1                             @ p_type: PT_LOAD
    .word 0                             @ p_offset: from the file's first byte
    .word BASE                          @ p_vaddr: loaded at BASE
    .word BASE                          @ p_paddr: the same
    .word end - ehdr                    @ p_filesz: the whole file
    .word end - ehdr                    @ p_memsz: the same, no bss
    .word 5                             @ p_flags: PF_R | PF_X, read and run
    .word 0x1000                        @ p_align: a page

_start:
    mvn     r4, #0                      @ -1: no high half yet
next:                                   @ the next byte of stdin
    bl      getc                        @ r0 = the byte
    cmp     r0, #0x23                   @ '#': a comment
    beq     comment
    cmp     r0, #0x3b                   @ ';': a comment
    beq     comment
    sub     r5, r0, #0x30               @ '0'-'9' to 0-9
    cmp     r5, #10
    blo     digit                       @ unsigned: below '0' is large
    sub     r5, r0, #0x41               @ 'A'-'F' to 0-5
    cmp     r5, #6
    blo     letter
    sub     r5, r0, #0x61               @ 'a'-'f' to 0-5
    cmp     r5, #6
    bhs     next                        @ anything else: skipped
letter:
    add     r5, r5, #10                 @ 10-15
digit:                                  @ r5 = the digit's value, 0-15
    cmp     r4, #0                      @ the first digit of a pair?
    blt     high
    add     r0, r5, r4, lsl #4          @ the second: high half, then this one
    bl      putc
    b       _start                      @ the next pair
high:
    mov     r4, r5                      @ keep it for the second
    b       next
comment:                                @ skip to the end of the line
    bl      getc
    cmp     r0, #0x0a                   @ '\n'
    bne     comment
    b       next

getc:                                   @ r0 = the next byte of stdin
    mov     r7, #SYS_read
    mov     r0, #0                      @ fd 0, stdin
    mov     r1, sp                      @ into the stack
    mov     r2, #1                      @ 1 byte
    svc     #0
    cmp     r0, #0
    blt     fail                        @ a failed read
    beq     done                        @ the end of stdin
    ldrb    r0, [sp]                    @ the byte, zero-extended
    bx      lr                          @ return

putc:                                   @ writes r0's low byte to stdout
    strb    r0, [sp]
    mov     r7, #SYS_write
    mov     r0, #1                      @ fd 1, stdout
    mov     r1, sp                      @ from the stack
    mov     r2, #1                      @ 1 byte
    svc     #0
    cmp     r0, #1                      @ written?
    bne     fail
    bx      lr

done:
    mov     r0, #0                      @ status 0
    b       exit
fail:
    mov     r0, #1                      @ status 1
exit:
    mov     r7, #SYS_exit
    svc     #0
end:
