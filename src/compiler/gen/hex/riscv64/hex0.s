# hex0 for riscv64 Linux: hex pairs in, bytes out. The first link of the
# bootstrap: everything after it is built from text by programs built from
# text. Its bytes are hosts/riscv64/hex0.hex0, made from this file once by
# gen/mkhex.pl (a dev aid); the chain never reads this file.
#
#   hex0 < file.hex0 > file
#
# Each pair of hex digits (0-9, A-F, a-f) is one byte, the first digit its
# high half. '#' and ';' start a comment to the end of the line. Every
# other byte (spaces, newlines, ...) is skipped. At the end of stdin the
# status is 0 (a lone last digit is dropped); a failed read or write ends
# with status 1.
#
# One flat file, loaded whole at BASE by its one program header: no
# sections, no linker. RV64I only, no compressed instructions: every
# instruction is 4 bytes, its fields as the RISC-V manual draws them. Only
# the stack is written (its first byte, argc's, is the buffer of a byte).
# The registers:
#   s1  the high half of the byte being read, or -1 before its first digit

    .equ BASE, 0x600000
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
    .dword phdr - ehdr                  # e_phoff: the program header follows
    .dword 0                            # e_shoff: no section headers
    .word 0                             # e_flags: no RVC, soft float (none used)
    .half 64                            # e_ehsize: this header's size
    .half 56                            # e_phentsize: a program header's size
    .half 1                             # e_phnum: one program header
    .half 0                             # e_shentsize: no section headers
    .half 0                             # e_shnum: none
    .half 0                             # e_shstrndx: none
phdr:                                   # the program header, 56 bytes
    .word 1                             # p_type: PT_LOAD
    .word 5                             # p_flags: PF_R | PF_X, read and run
    .dword 0                            # p_offset: from the file's first byte
    .dword BASE                         # p_vaddr: loaded at BASE
    .dword BASE                         # p_paddr: the same
    .dword end - ehdr                   # p_filesz: the whole file
    .dword end - ehdr                   # p_memsz: the same, no bss
    .dword 0x1000                       # p_align: a page

_start:
    li      s1, -1                      # addi s1, zero, -1: no high half yet
next:                                   # the next byte of stdin
    jal     ra, getc                    # a0 = the byte
    li      t0, 0x23                    # '#': a comment
    beq     a0, t0, comment
    li      t0, 0x3b                    # ';': a comment
    beq     a0, t0, comment
    addi    t0, a0, -0x30               # '0'-'9' to 0-9
    li      t1, 10
    bltu    t0, t1, digit               # unsigned: below '0' is large
    ori     t0, a0, 0x20                # 'A'-'F' to 'a'-'f'
    addi    t0, t0, -0x57               # 'a'-'f' to 10-15
    addi    t2, t0, -10                 # 0-5 for 'a'-'f'
    li      t1, 6
    bltu    t2, t1, digit
    j       next                        # anything else: skipped
digit:                                  # t0 = the digit's value, 0-15
    blt     s1, zero, high              # the first digit of a pair?
    slli    s1, s1, 4                   # the second: high half, then this one
    or      a0, s1, t0
    jal     ra, putc
    j       _start                      # the next pair
high:
    mv      s1, t0                      # addi s1, t0, 0: keep it for the second
    j       next
comment:                                # skip to the end of the line
    jal     ra, getc
    li      t0, 0x0a                    # '\n'
    bne     a0, t0, comment
    j       next

getc:                                   # a0 = the next byte of stdin
    li      a7, SYS_read
    li      a0, 0                       # fd 0, stdin
    mv      a1, sp                      # into the stack
    li      a2, 1                       # 1 byte
    ecall
    blt     a0, zero, fail              # a failed read
    beq     a0, zero, done              # the end of stdin
    lbu     a0, 0(sp)                   # the byte, zero-extended
    ret                                 # jalr zero, 0(ra)

putc:                                   # writes a0's low byte to stdout
    sb      a0, 0(sp)
    li      a7, SYS_write
    li      a0, 1                       # fd 1, stdout
    mv      a1, sp                      # from the stack
    li      a2, 1                       # 1 byte
    ecall
    li      t0, 1                       # written?
    bne     a0, t0, fail
    ret

done:
    li      a0, 0                       # status 0
    j       exit
fail:
    li      a0, 1                       # status 1
exit:
    li      a7, SYS_exit
    ecall
end:
