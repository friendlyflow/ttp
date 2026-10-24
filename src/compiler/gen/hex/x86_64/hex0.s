# hex0 for x86_64 Linux: hex pairs in, bytes out. The first link of the
# bootstrap: everything after it is built from text by programs built from
# text. Its bytes are hosts/x86_64/hex0.hex0, made from this file once by
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
# sections, no linker. Only the stack is written. The registers:
#   %r13  the high half of the byte being read, or -1 before its first digit

    .equ BASE, 0x600000

ehdr:                                   # the ELF header, 64 bytes
    .byte 0x7f, 0x45, 0x4c, 0x46        # e_ident: the magic, 0x7f 'E' 'L' 'F'
    .byte 2                             # EI_CLASS: ELFCLASS64
    .byte 1                             # EI_DATA: ELFDATA2LSB, little endian
    .byte 1                             # EI_VERSION: EV_CURRENT
    .byte 0                             # EI_OSABI: System V
    .byte 0, 0, 0, 0, 0, 0, 0, 0        # EI_ABIVERSION 0, then padding to 16
    .word 2                             # e_type: ET_EXEC, an executable
    .word 0x3e                          # e_machine: EM_X86_64
    .long 1                             # e_version: EV_CURRENT
    .quad BASE + _start - ehdr          # e_entry: the address of _start
    .quad phdr - ehdr                   # e_phoff: the program header follows
    .quad 0                             # e_shoff: no section headers
    .long 0                             # e_flags: none on x86_64
    .word 64                            # e_ehsize: this header's size
    .word 56                            # e_phentsize: a program header's size
    .word 1                             # e_phnum: one program header
    .word 0                             # e_shentsize: no section headers
    .word 0                             # e_shnum: none
    .word 0                             # e_shstrndx: none
phdr:                                   # the program header, 56 bytes
    .long 1                             # p_type: PT_LOAD
    .long 5                             # p_flags: PF_R | PF_X, read and run
    .quad 0                             # p_offset: from the file's first byte
    .quad BASE                          # p_vaddr: loaded at BASE
    .quad BASE                          # p_paddr: the same
    .quad end - ehdr                    # p_filesz: the whole file
    .quad end - ehdr                    # p_memsz: the same, no bss
    .quad 0x1000                        # p_align: a page

_start:
    or      $-1, %r13                   # no high half yet
next:                                   # the next byte of stdin
    call    getc
    cmp     $0x23, %al                  # '#': a comment
    je      comment
    cmp     $0x3b, %al                  # ';': a comment
    je      comment
    cmp     $0x30, %al                  # below '0': skipped
    jb      next
    cmp     $0x39, %al                  # '0'-'9'
    jbe     decimal
    or      $0x20, %al                  # 'A'-'F' to 'a'-'f'
    cmp     $0x61, %al                  # below 'a': skipped
    jb      next
    cmp     $0x66, %al                  # above 'f': skipped
    ja      next
    sub     $0x27, %al                  # 'a'-'f' to 0x3a-0x3f, as if after '9'
decimal:
    sub     $0x30, %al                  # the digit's value, 0-15
    test    %r13, %r13                  # the first digit of a pair?
    js      high
    shl     $4, %r13d                   # the second: high half, then this one
    or      %r13d, %eax
    call    putc
    jmp     _start                      # the next pair
high:
    mov     %eax, %r13d                 # keep it for the second digit
    jmp     next
comment:                                # skip to the end of the line
    call    getc
    cmp     $0x0a, %al                  # '\n'
    jne     comment
    jmp     next

getc:                                   # %eax = the next byte of stdin
    xor     %eax, %eax                  # SYS_read
    push    %rax                        # 8 zero bytes: the byte lands in the lowest
    xor     %edi, %edi                  # fd 0, stdin
    mov     %rsp, %rsi                  # into the stack
    lea     1(%rax), %edx               # 1 byte
    syscall
    test    %rax, %rax
    jl      fail                        # a failed read
    je      done                        # the end of stdin
    pop     %rax                        # the byte, zero-extended
    ret

putc:                                   # writes %al to stdout
    push    %rax
    mov     $1, %eax                    # SYS_write
    mov     %eax, %edi                  # fd 1, stdout
    mov     %rsp, %rsi                  # from the stack
    mov     %eax, %edx                  # 1 byte
    syscall
    pop     %rdi
    cmp     $1, %rax                    # written?
    jne     fail
    ret

done:
    xor     %edi, %edi                  # status 0
    jmp     exit
fail:
    mov     $1, %edi                    # status 1
exit:
    mov     $60, %eax                   # SYS_exit
    syscall
end:
