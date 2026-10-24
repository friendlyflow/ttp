# M1 for x86_64 Linux: a macro assembler, hex2 with names. The third link
# of the bootstrap, built by hex2 from hosts/x86_64/M1.hex2 (made from
# this file once by gen/mkhex.pl, a dev aid; the chain never reads this
# file). It turns hosts/x86_64/asm.M1 into hex2 text, which hex2 makes
# into asm, the assembler of the seed's asm. As stage0-posix's M1.
#
#   M1 < file.M1 > file.hex2
#
# The input is tokens: bytes up to a space, tab or newline (any byte up to
# 0x20). '#' and ';' start a comment to the end of the line. A token
#   DEFINE name value   makes name a macro: every other token name, before
#                       or after, becomes the text value (hex digits)
#   "text"              the hex of the bytes of text, then 00 (a C string;
#                       text is every byte up to the next '"')
#   'text'              text as it is (raw hex2 text, spaces too)
#   !n @n %n            the number n in 1, 2 or 4 bytes, little endian, as
#                       hex: decimal, or hex after 0x, '-' before it for a
#                       negative one; it must fit, signed or unsigned
#   :name %name !name &name ^hex
#                       hex2's labels, references and addresses, as they are
#   a macro's name      its value
#   hex digits          as they are (raw hex2 text)
# Anything else is an error. Out go the tokens' texts, each followed by a
# space, and a newline for each newline of the input: hex2 text, line by
# line as the input. The input is read whole, then twice: the first pass
# collects the macros, the second writes. On an unknown macro, a macro
# defined twice, a number that is none or does not fit, a string without
# its end, a full table, input or output and a failed read or write it
# says so on stderr and ends with status 1; else with 0.
#
# One flat file, loaded at BASE by its first program header, read and
# run; the second maps the memory it writes, MACROS to the end of OUTPUT.
# The registers:
#   %r12  the next byte of the input        %r13  the end of the input
#   %rbx  the next byte of the output       %r15  the pass, 1 or 2
#   %rbp  the next free macro
# A macro is 32 bytes: the address of its name in the input, the name's
# length, the address of its value, the value's length.

    .equ BASE, 0x600000
    .equ MACROS, 0x700000               # 65536 macros of 32 bytes
    .equ MACROS_END, MACROS + 0x10000 * 32
    .equ INPUT, 0x900000                # 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTPUT, 0x1900000              # 64 MiB of output
    .equ OUTPUT_END, OUTPUT + 0x4000000

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
    .quad MACROS                        # p_vaddr: the macros, input, output
    .quad MACROS                        # p_paddr: the same
    .quad 0                             # p_filesz: none, all zero
    .quad OUTPUT_END - MACROS           # p_memsz: to the end of the output
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
    mov     $MACROS, %ebp               # no macros yet
    mov     $OUTPUT, %ebx               # no output yet
    mov     $1, %r15d                   # pass 1
pass:
    mov     $INPUT, %r12d               # from the first byte
loop:                                   # the next token
    call    token
    jc      pass_end
    cmp     $6, %rdx                    # DEFINE?
    jne     not_define
    lea     str_define(%rip), %rdi
    mov     %rsi, %r8
    mov     %rdx, %rcx
    repe cmpsb
    mov     %r8, %rsi
    je      define
not_define:
    cmp     $1, %r15d                   # pass 1 only looks for DEFINE
    je      loop
    movzbl  (%rsi), %eax                # its first byte
    cmp     $0x22, %al                  # '"': a string
    je      string
    cmp     $0x27, %al                  # "'": raw text
    je      raw
    mov     $1, %r9d                    # '!': 1 byte
    cmp     $0x21, %al
    je      sized
    mov     $4, %r9d                    # '%': 4 bytes
    cmp     $0x25, %al
    je      sized
    mov     $2, %r9d                    # '@': 2 bytes, a number only
    cmp     $0x40, %al
    je      sized
    cmp     $0x3a, %al                  # ':' '&' '^': for hex2
    je      copy
    cmp     $0x26, %al
    je      copy
    cmp     $0x5e, %al
    je      copy
    call    find                        # a macro: its value
    jnc     expand
    mov     %rsi, %rdi                  # else only hex digits, as they are
    mov     %rdx, %rcx
hex_only:
    movzbl  (%rdi), %eax
    call    hexval
    jc      unknown
    inc     %rdi
    dec     %rcx
    jnz     hex_only
copy:                                   # the token as it is, then a space
    call    put_text
    jmp     loop
expand:
    mov     %rax, %rsi                  # its value
    mov     %rcx, %rdx
    jmp     copy

define:                                 # DEFINE name value
    call    token                       # the name
    jc      no_value
    mov     %rsi, %r10
    mov     %rdx, %r11
    call    token                       # the value
    jc      no_value
    cmp     $1, %r15d                   # stored in pass 1, skipped in pass 2
    jne     loop
    xchg    %rsi, %r10                  # the name in %rsi, %rdx again
    xchg    %rdx, %r11
    call    find
    jnc     twice
    cmp     $MACROS_END, %ebp
    jae     too_many
    mov     %rsi, (%rbp)                # its name
    mov     %rdx, 8(%rbp)               # its length
    mov     %r10, 16(%rbp)              # its value
    mov     %r11, 24(%rbp)              # its length
    add     $32, %rbp
    jmp     loop

string:                                 # "text": its bytes as hex, then 00
    inc     %rsi                        # after the '"'
    sub     $2, %rdx                    # without both '"'
    jz      string_end
string_byte:
    movzbl  (%rsi), %eax
    call    put_hex
    inc     %rsi
    dec     %rdx
    jnz     string_byte
string_end:
    xor     %eax, %eax                  # the 00
    call    put_hex
    mov     $0x20, %al
    call    put
    jmp     loop

raw:                                    # 'text': text as it is
    inc     %rsi
    sub     $2, %rdx
    call    put_text
    jmp     loop

sized:                                  # !n @n %n: %r9 bytes of n; else a label
    movzbl  1(%rsi), %eax               # a digit or '-' after the sign
    cmp     $0x2d, %al
    je      number
    sub     $0x30, %al
    cmp     $9, %al
    jbe     number
    cmp     $2, %r9d                    # '@' only with a number
    je      unknown
    jmp     copy                        # %name !name: for hex2
number:
    push    %rsi
    push    %rdx
    inc     %rsi                        # after the sign
    dec     %rdx
    call    parse
    pop     %rdx
    pop     %rsi
    jc      bad_number
    mov     %r9d, %ecx                  # fits: -2^(8n-1) <= n < 2^(8n)
    shl     $3, %ecx
    mov     $1, %r10d
    shl     %cl, %r10                   # 2^(8n)
    mov     %r10, %r11
    shr     $1, %r11                    # 2^(8n-1)
    lea     (%rax,%r11), %rcx           # + 2^(8n-1): from 0 ...
    add     %r10, %r11                  # ... to below 2^(8n) + 2^(8n-1)
    cmp     %r11, %rcx
    jae     range
number_byte:                            # the low byte first
    push    %rax
    call    put_hex
    pop     %rax
    shr     $8, %rax
    dec     %r9d
    jnz     number_byte
    mov     $0x20, %al
    call    put
    jmp     loop

pass_end:
    inc     %r15d
    cmp     $2, %r15d                   # after pass 1, pass 2
    je      pass
    mov     $OUTPUT, %esi               # after pass 2, write the output
write:
    mov     %rbx, %rdx
    sub     %rsi, %rdx                  # what is left
    jz      done
    mov     $1, %eax                    # SYS_write
    mov     %eax, %edi                  # fd 1, stdout
    syscall
    test    %rax, %rax
    jle     write_failed
    add     %rax, %rsi
    jmp     write
done:
    xor     %edi, %edi                  # status 0
    jmp     exit

token:                                  # the next token: %rsi, %rdx; CF at the end
    cmp     %r13, %r12
    jae     no_token
    movzbl  (%r12), %eax
    cmp     $0x23, %al                  # '#': a comment
    je      comment
    cmp     $0x3b, %al                  # ';': a comment
    je      comment
    cmp     $0x20, %al                  # a space, tab, newline, ...
    ja      word
    inc     %r12
    cmp     $0x0a, %al                  # a newline goes out in pass 2
    jne     token
    cmp     $1, %r15d
    je      token
    call    put
    jmp     token
comment:                                # skip to the newline
    inc     %r12
    cmp     %r13, %r12
    jae     no_token
    cmpb    $0x0a, (%r12)
    jne     comment
    jmp     token
word:
    mov     %r12, %rsi                  # its first byte
    inc     %r12
    cmp     $0x22, %al                  # '"' or "'": to the same again
    je      quoted
    cmp     $0x27, %al
    je      quoted
word_byte:
    cmp     %r13, %r12
    jae     word_end
    cmpb    $0x20, (%r12)               # ends at a space, tab, newline
    jbe     word_end
    inc     %r12
    jmp     word_byte
quoted:
    cmp     %r13, %r12
    jae     unterminated
    cmp     (%r12), %al
    je      quoted_end
    inc     %r12
    jmp     quoted
quoted_end:
    inc     %r12                        # after the closing one
word_end:
    mov     %r12, %rdx
    sub     %rsi, %rdx
    clc
    ret
no_token:
    stc
    ret

parse:                                  # %rax = the number %rsi, %rdx; CF if none
    xor     %eax, %eax
    xor     %r8d, %r8d                  # 1 if negative
    test    %rdx, %rdx
    jz      not_number
    cmpb    $0x2d, (%rsi)               # '-'
    jne     parse_base
    inc     %r8d
    inc     %rsi
    dec     %rdx
    jz      not_number
parse_base:
    cmp     $2, %rdx                    # 0x: hex
    jbe     decimal_digit
    cmpb    $0x30, (%rsi)
    jne     decimal_digit
    movzbl  1(%rsi), %ecx
    or      $0x20, %cl                  # 'X' as 'x'
    cmp     $0x78, %cl
    jne     decimal_digit
    add     $2, %rsi
    sub     $2, %rdx
hex_digit:
    mov     %rax, %rcx
    movzbl  (%rsi), %eax
    call    hexval
    jc      not_number
    shl     $4, %rcx
    or      %rcx, %rax
    inc     %rsi
    dec     %rdx
    jnz     hex_digit
    jmp     parse_sign
decimal_digit:
    movzbl  (%rsi), %ecx
    sub     $0x30, %ecx                 # '0'-'9'
    cmp     $9, %ecx
    ja      not_number
    imul    $10, %rax, %rax
    add     %rcx, %rax
    inc     %rsi
    dec     %rdx
    jnz     decimal_digit
parse_sign:
    test    %r8d, %r8d
    jz      parsed
    neg     %rax
parsed:
    clc
    ret
not_number:
    stc
    ret

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

find:                                   # %rax, %rcx = the value of macro %rsi, %rdx; CF if none
    mov     $MACROS, %r8d
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
    add     $32, %r8
    jmp     find_next
not_found:
    stc
    ret
found:
    mov     16(%r8), %rax
    mov     24(%r8), %rcx
    clc
    ret

put_text:                               # writes %rsi, %rdx, then a space
    test    %rdx, %rdx
    jz      put_space
    movzbl  (%rsi), %eax
    call    put
    inc     %rsi
    dec     %rdx
    jmp     put_text
put_space:
    mov     $0x20, %al
put:                                    # writes the byte %al
    cmp     $OUTPUT_END, %ebx
    jae     too_long
    mov     %al, (%rbx)
    inc     %rbx
    ret

put_hex:                                # writes the byte %al as two hex digits
    push    %rax
    shr     $4, %al
    call    put_digit
    pop     %rax
    and     $15, %al
put_digit:
    lea     digits(%rip), %rcx
    movzbl  %al, %eax
    mov     (%rcx,%rax), %al
    jmp     put

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
bad_number:
    lea     msg_number(%rip), %r8
    mov     $msg_number_len, %r9d
    jmp     die
unterminated:
    lea     msg_string(%rip), %r8
    mov     $msg_string_len, %r9d
    jmp     die_plain
no_value:
    lea     msg_value(%rip), %r8
    mov     $msg_value_len, %r9d
    jmp     die_plain
too_many:
    lea     msg_many(%rip), %r8
    mov     $msg_many_len, %r9d
    jmp     die_plain
too_large:
    lea     msg_large(%rip), %r8
    mov     $msg_large_len, %r9d
    jmp     die_plain
too_long:
    lea     msg_long(%rip), %r8
    mov     $msg_long_len, %r9d
    jmp     die_plain
read_failed:
    lea     msg_read(%rip), %r8
    mov     $msg_read_len, %r9d
    jmp     die_plain
write_failed:
    lea     msg_write(%rip), %r8
    mov     $msg_write_len, %r9d
die_plain:
    xor     %edx, %edx                  # no token
die:                                    # message %r8, %r9, then token %rsi, %rdx
    push    %rdx
    push    %rsi
    mov     %r8, %rsi
    mov     %r9, %rdx
    call    ewrite
    pop     %rsi
    pop     %rdx
    call    ewrite
    lea     digits(%rip), %rsi          # digits ends with the newline
    add     $16, %rsi
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

str_define:     .ascii "DEFINE"
digits:         .ascii "0123456789ABCDEF\n"
msg_unknown:    .ascii "M1: unknown macro: "
    .equ msg_unknown_len, . - msg_unknown
msg_twice:      .ascii "M1: macro defined twice: "
    .equ msg_twice_len, . - msg_twice
msg_range:      .ascii "M1: number out of range: "
    .equ msg_range_len, . - msg_range
msg_number:     .ascii "M1: not a number: "
    .equ msg_number_len, . - msg_number
msg_string:     .ascii "M1: string without its end"
    .equ msg_string_len, . - msg_string
msg_value:      .ascii "M1: DEFINE without its value"
    .equ msg_value_len, . - msg_value
msg_many:       .ascii "M1: too many macros"
    .equ msg_many_len, . - msg_many
msg_large:      .ascii "M1: input too large"
    .equ msg_large_len, . - msg_large
msg_long:       .ascii "M1: output too large"
    .equ msg_long_len, . - msg_long
msg_read:       .ascii "M1: read failed"
    .equ msg_read_len, . - msg_read
msg_write:      .ascii "M1: write failed"
    .equ msg_write_len, . - msg_write
end:
