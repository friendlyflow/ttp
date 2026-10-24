# hex2 for x86_64 Linux: hex0 with labels. The second link of the
# bootstrap, built by hex0 from hosts/x86_64/hex2.hex0 (made from this
# file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
# It builds the seed, ttpc, from hosts/x86_64/ttpc.hex2.
#
#   hex2 < file.hex2 > file
#
# As hex0: each pair of hex digits is a byte, '#' and ';' start a comment
# to the end of the line, every other byte is skipped. And the address of
# the next byte, which starts at 0 and counts every byte written:
#   :name    defines the label name, at that address
#   %name    4 bytes, little endian: name's address minus the address
#            after them (a rel32 of x86_64's jumps, calls and (%rip))
#   !name    1 byte: the same (a rel8 of the short jumps)
#   &name    4 bytes: name's address (an abs32; a .quad's low half)
#   ^hex     the address of the next byte is this hex number (where a
#            file's addresses jump: its next segment, the labels of a bss)
# A name is every byte after the sign up to a space, tab or newline. The
# input is read whole, then twice: the first pass gives every label its
# address, the second writes. Each reference must fit in its bytes. On an
# unknown label, a label defined twice, a reference out of range, a full
# table or input and a failed read or write it says so on stderr and
# ends with status 1; else with 0.
#
# One flat file, loaded at BASE by its first program header, read and
# run; the second maps the memory it writes, LABELS to the end of INPUT.
# The registers:
#   %r12  the next byte of the input        %r13  the end of the input
#   %r14  the address of the next byte      %r15  the pass, 1 or 2
#   %rbx  the high half of a byte, or -1    %rbp  the next free label
# A label is 24 bytes: the address of its name in the input, the name's
# length, its address.

    .equ BASE, 0x600000
    .equ LABELS, 0x700000               # 65536 labels of 24 bytes
    .equ LABELS_END, LABELS + 0x10000 * 24
    .equ INPUT, 0x900000                # 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000

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
    .quad phdr - ehdr                   # e_phoff: the program headers follow
    .quad 0                             # e_shoff: no section headers
    .long 0                             # e_flags: none on x86_64
    .word 64                            # e_ehsize: this header's size
    .word 56                            # e_phentsize: a program header's size
    .word 2                             # e_phnum: two program headers
    .word 0                             # e_shentsize: no section headers
    .word 0                             # e_shnum: none
    .word 0                             # e_shstrndx: none
phdr:                                   # the program: 56 bytes
    .long 1                             # p_type: PT_LOAD
    .long 5                             # p_flags: PF_R | PF_X, read and run
    .quad 0                             # p_offset: from the file's first byte
    .quad BASE                          # p_vaddr: loaded at BASE
    .quad BASE                          # p_paddr: the same
    .quad end - ehdr                    # p_filesz: the whole file
    .quad end - ehdr                    # p_memsz: the same
    .quad 0x1000                        # p_align: a page
                                        # its memory: 56 bytes
    .long 1                             # p_type: PT_LOAD
    .long 6                             # p_flags: PF_R | PF_W, read and write
    .quad 0                             # p_offset: none of the file
    .quad LABELS                        # p_vaddr: the labels, then the input
    .quad LABELS                        # p_paddr: the same
    .quad 0                             # p_filesz: none, all zero
    .quad INPUT_END - LABELS            # p_memsz: to the end of the input
    .quad 0x1000                        # p_align: a page

_start:                                 # read all of stdin into INPUT
    mov     $INPUT, %r13d               # the end of what is read
read:
    mov     $INPUT_END, %edx
    sub     %r13d, %edx                 # the room left
    jz      too_large
    xor     %eax, %eax                  # SYS_read
    xor     %edi, %edi                  # fd 0, stdin
    mov     %r13, %rsi                  # after what is read
    syscall
    test    %rax, %rax
    jl      read_failed
    je      read_all                    # the end of stdin
    add     %rax, %r13
    jmp     read
read_all:
    mov     $LABELS, %ebp               # no labels yet
    mov     $1, %r15d                   # pass 1
pass:
    mov     $INPUT, %r12d               # from the first byte
    xor     %r14d, %r14d                # at address 0
    or      $-1, %rbx                   # no high half
loop:                                   # the next byte of the input
    cmp     %r13, %r12
    jae     pass_end
    movzbl  (%r12), %eax
    inc     %r12
    cmp     $0x23, %al                  # '#': a comment
    je      comment
    cmp     $0x3b, %al                  # ';': a comment
    je      comment
    cmp     $0x3a, %al                  # ':': a label
    je      define
    cmp     $0x25, %al                  # '%': rel32
    je      rel32
    cmp     $0x21, %al                  # '!': rel8
    je      rel8
    cmp     $0x26, %al                  # '&': abs32
    je      abs32
    cmp     $0x5e, %al                  # '^': an address
    je      origin
    call    hexval
    jc      loop                        # not a hex digit: skipped
    test    %rbx, %rbx                  # the first digit of a pair?
    js      high
    shl     $4, %ebx                    # the second: high half, then this one
    or      %ebx, %eax
    call    emit
    or      $-1, %rbx                   # the next pair
    jmp     loop
high:
    mov     %eax, %ebx                  # keep it for the second digit
    jmp     loop
comment:                                # skip to the end of the line
    cmp     %r13, %r12
    jae     loop
    mov     (%r12), %al
    inc     %r12
    cmp     $0x0a, %al                  # '\n'
    jne     comment
    jmp     loop
pass_end:
    inc     %r15d
    cmp     $2, %r15d                   # after pass 1, pass 2
    je      pass
    xor     %edi, %edi                  # after pass 2, status 0
    jmp     exit

define:                                 # :name
    call    name
    cmp     $1, %r15d                   # only in pass 1
    jne     loop
    call    find
    jnc     twice
    cmp     $LABELS_END, %ebp
    jae     too_many
    mov     %rsi, (%rbp)                # its name
    mov     %rdx, 8(%rbp)               # its length
    mov     %r14, 16(%rbp)              # its address
    add     $24, %rbp
    jmp     loop

rel8:                                   # !name
    mov     $1, %r9d                    # 1 byte
    jmp     relative
rel32:                                  # %name
    mov     $4, %r9d                    # 4 bytes
relative:
    lea     (%r14,%r9), %r10            # minus the address after them
    jmp     ref
abs32:                                  # &name
    mov     $4, %r9d                    # 4 bytes
    xor     %r10d, %r10d                # minus nothing
ref:                                    # %r9 bytes of name's address - %r10
    call    name
    cmp     $1, %r15d                   # pass 1 only counts them
    je      skip
    call    find
    jc      unknown
    sub     %r10, %rax
    test    %r10, %r10                  # abs32: fits in 32 bits, unsigned
    jz      unsigned
    movsbq  %al, %rcx                   # rel8: fits in 8 bits, signed
    cmp     $1, %r9d
    je      fits
    movslq  %eax, %rcx                  # rel32: fits in 32 bits, signed
    jmp     fits
unsigned:
    mov     %eax, %ecx
fits:
    cmp     %rax, %rcx                  # the same when cut to its bytes?
    jne     range
    call    emitn
    jmp     loop
skip:
    add     %r9, %r14
    jmp     loop

origin:                                 # ^hex: the address of the next byte
    xor     %r14d, %r14d
origin_digit:
    cmp     %r13, %r12
    jae     loop
    movzbl  (%r12), %eax
    call    hexval
    jc      loop                        # its end
    inc     %r12
    shl     $4, %r14
    or      %rax, %r14
    jmp     origin_digit

hexval:                                 # %al = the value of hex digit %al; CF if none
    cmp     $0x30, %al                  # below '0'
    jb      no_digit
    cmp     $0x39, %al                  # '0'-'9'
    jbe     decimal
    or      $0x20, %al                  # 'A'-'F' to 'a'-'f'
    cmp     $0x61, %al                  # below 'a'
    jb      no_digit
    cmp     $0x66, %al                  # above 'f'
    ja      no_digit
    sub     $0x27, %al                  # 'a'-'f' to 0x3a-0x3f, as if after '9'
decimal:
    sub     $0x30, %al                  # 0-15, no carry
    ret
no_digit:
    stc
    ret

name:                                   # %rsi, %rdx = the name at %r12, after it
    mov     %r12, %rsi
name_byte:
    cmp     %r13, %r12
    jae     name_end
    cmpb    $0x20, (%r12)               # ends at a space, tab, newline
    jbe     name_end
    inc     %r12
    jmp     name_byte
name_end:
    mov     %r12, %rdx
    sub     %rsi, %rdx
    ret

find:                                   # %rax = the address of name %rsi, %rdx; CF if none
    mov     $LABELS, %r8d
find_next:
    cmp     %rbp, %r8
    jae     not_found
    cmp     8(%r8), %rdx                # the same length
    jne     find_on
    mov     (%r8), %rdi
    mov     %rdx, %rcx
    push    %rsi
    repe cmpsb                          # and the same bytes
    pop     %rsi
    je      found
find_on:
    add     $24, %r8
    jmp     find_next
not_found:
    stc
    ret
found:
    mov     16(%r8), %rax
    clc
    ret

emitn:                                  # writes the %r9 low bytes of %rax
    push    %rax
    call    emit
    pop     %rax
    shr     $8, %rax
    dec     %r9d
    jnz     emitn
    ret

emit:                                   # writes %al in pass 2, counts it
    inc     %r14
    cmp     $1, %r15d
    je      emitted
    push    %rax
    mov     $1, %eax                    # SYS_write
    mov     %eax, %edi                  # fd 1, stdout
    mov     %rsp, %rsi                  # from the stack
    mov     %eax, %edx                  # 1 byte
    syscall
    pop     %rdi
    cmp     $1, %rax                    # written?
    jne     write_failed
emitted:
    ret

unknown:
    lea     msg_unknown(%rip), %r8
    mov     $msg_unknown_len, %r9d
    jmp     die
twice:
    lea     msg_twice(%rip), %r8
    mov     $msg_twice_len, %r9d
    jmp     die
range:
    lea     msg_range(%rip), %r8
    mov     $msg_range_len, %r9d
    jmp     die
too_many:
    lea     msg_many(%rip), %r8
    mov     $msg_many_len, %r9d
    jmp     die_plain
too_large:
    lea     msg_large(%rip), %r8
    mov     $msg_large_len, %r9d
    jmp     die_plain
read_failed:
    lea     msg_read(%rip), %r8
    mov     $msg_read_len, %r9d
    jmp     die_plain
write_failed:
    lea     msg_write(%rip), %r8
    mov     $msg_write_len, %r9d
die_plain:
    xor     %edx, %edx                  # no name
die:                                    # message %r8, %r9, then name %rsi, %rdx
    push    %rdx
    push    %rsi
    mov     %r8, %rsi
    mov     %r9, %rdx
    call    ewrite
    pop     %rsi
    pop     %rdx
    call    ewrite
    lea     newline(%rip), %rsi
    mov     $1, %edx
    call    ewrite
    mov     $1, %edi                    # status 1
exit:
    mov     $60, %eax                   # SYS_exit
    syscall
ewrite:                                 # writes %rsi, %rdx to stderr
    mov     $1, %eax                    # SYS_write
    mov     $2, %edi                    # fd 2, stderr
    syscall
    ret

msg_unknown:    .ascii "hex2: unknown label: "
    .equ msg_unknown_len, . - msg_unknown
msg_twice:      .ascii "hex2: label defined twice: "
    .equ msg_twice_len, . - msg_twice
msg_range:      .ascii "hex2: out of range: "
    .equ msg_range_len, . - msg_range
msg_many:       .ascii "hex2: too many labels"
    .equ msg_many_len, . - msg_many
msg_large:      .ascii "hex2: input too large"
    .equ msg_large_len, . - msg_large
msg_read:       .ascii "hex2: read failed"
    .equ msg_read_len, . - msg_read
msg_write:      .ascii "hex2: write failed"
    .equ msg_write_len, . - msg_write
newline:        .ascii "\n"
end:
