@ M1 for arm Linux (EABI): a macro assembler, hex2 with names. The third
@ link of the bootstrap, built by hex2 from hosts/arm/M1.hex2 (made from
@ this file once by gen/mkhex.pl, a dev aid; the chain never reads this
@ file). It turns hosts/arm/asm.M1 into hex2 text, which hex2 makes into
@ asm, the assembler of the seed's asm. As stage0-posix's M1.
@
@   M1 < file.M1 > file.hex2
@
@ The input is tokens: bytes up to a space, tab or newline (any byte up to
@ 0x20). '#' and ';' start a comment to the end of the line. A token
@   DEFINE name value   makes name a macro: every other token name, before
@                       or after, becomes the text value (hex digits)
@   "text"              the hex of the bytes of text, then 00 (a C string;
@                       text is every byte up to the next '"')
@   'text'              text as it is (raw hex2 text, spaces too)
@   !n @n %n            the number n in 1, 2 or 4 bytes, little endian, as
@                       hex: decimal, or hex after 0x, '-' before it for a
@                       negative one; it must fit, signed or unsigned
@   :name ^~name !name ~name &name ^hex
@                       hex2's labels, references and addresses, as they are
@                       (after ! @ % a name, not a number)
@   a macro's name      its value
@   hex digits          as they are (raw hex2 text)
@ Anything else is an error. Out go the tokens' texts, each followed by a
@ space, and a newline for each newline of the input: hex2 text, line by
@ line as the input. The input is read whole, then twice: the first pass
@ collects the macros, the second writes. On an unknown macro, a macro
@ defined twice, a number that is none or does not fit, a string without
@ its end, a full table, input or output and a failed read or write it
@ says so on stderr and ends with status 1; else with 0.
@
@ One flat file, loaded at BASE by its first program header, read and
@ run; the second maps the memory it writes, MACROS to the end of OUTPUT.
@ ARM state (ARMv7-A). The registers:
@   r4  the next byte of the input          r5  the end of the input
@   r6  the next byte of the output         r8  the pass, 1 or 2
@   r10 the next free macro
@   r7  the system call's number, else scratch, as r0-r3, r9, r11, r12
@ A macro is 16 bytes: the address of its name in the input, the name's
@ length, the address of its value, the value's length.

    .syntax unified
    .arch armv7-a
    .arm
    .equ BASE, 0x10000
    .equ MACROS, 0x100000               @ 65536 macros of 16 bytes
    .equ MACROS_END, MACROS + 0x10000 * 16
    .equ INPUT, 0x200000                @ 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTPUT, 0x1200000              @ 64 MiB of output
    .equ OUTPUT_END, OUTPUT + 0x4000000
    .equ SYS_read, 3
    .equ SYS_write, 4
    .equ SYS_exit, 1

@ la: reg = the address of sym, as ttpc.s's
    .macro la reg, sym
    movw    \reg, #:lower16:\sym
    movt    \reg, #:upper16:\sym
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
    .word MACROS                        @ p_vaddr: the macros, input, output
    .word MACROS                        @ p_paddr: the same
    .word 0                             @ p_filesz: none, all zero
    .word OUTPUT_END - MACROS           @ p_memsz: to the end of the output
    .word 6                             @ p_flags: PF_R | PF_W, read and write
    .word 0x1000                        @ p_align: a page

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
    mov     r10, #MACROS                @ no macros yet
    mov     r6, #OUTPUT                 @ no output yet
    mov     r8, #1                      @ pass 1
pass:
    mov     r4, #INPUT                  @ from the first byte
loop:                                   @ the next token
    bl      token
    cmp     r0, #0
    bne     pass_end
    cmp     r2, #6                      @ DEFINE?
    bne     not_define
    la      r3, str_define
    mov     r12, #0
define_byte:
    ldrb    r7, [r3, r12]
    ldrb    r0, [r1, r12]
    cmp     r7, r0
    bne     not_define
    add     r12, r12, #1
    cmp     r12, #6
    bne     define_byte
    b       define
not_define:
    cmp     r8, #1                      @ pass 1 only looks for DEFINE
    beq     loop
    ldrb    r7, [r1]                    @ its first byte
    cmp     r7, #0x22                   @ '"': a string
    beq     string
    cmp     r7, #0x27                   @ "'": raw text
    beq     raw
    mov     r9, #1                      @ '!': 1 byte
    cmp     r7, #0x21
    beq     sized
    mov     r9, #4                      @ '%': 4 bytes
    cmp     r7, #0x25
    beq     sized
    mov     r9, #2                      @ '@': 2 bytes
    cmp     r7, #0x40
    beq     sized
    cmp     r7, #0x3a                   @ ':' '&' '^' '~': for hex2
    beq     copy
    cmp     r7, #0x26
    beq     copy
    cmp     r7, #0x5e
    beq     copy
    cmp     r7, #0x7e
    beq     copy
    bl      find                        @ a macro: r1, r2 its value
    cmp     r0, #0
    beq     copy
    mov     r3, r1                      @ else only hex digits, as they are
    add     r12, r1, r2
hex_only:
    ldrb    r0, [r3]
    bl      hexval
    cmp     r0, #0
    blt     unknown
    add     r3, r3, #1
    cmp     r3, r12
    bne     hex_only
copy:                                   @ the token as it is, then a space
    bl      put_text
    b       loop

define:                                 @ DEFINE name value
    bl      token                       @ the name
    cmp     r0, #0
    bne     no_value
    cmp     r10, #MACROS_END            @ kept in the next free macro
    bhs     too_many
    str     r1, [r10]                   @ its name
    str     r2, [r10, #4]               @ its length
    bl      token                       @ the value
    cmp     r0, #0
    bne     no_value
    cmp     r8, #1                      @ stored in pass 1, skipped in pass 2
    bne     loop
    str     r1, [r10, #8]               @ its value
    str     r2, [r10, #12]              @ its length
    ldr     r1, [r10]                   @ the name: not yet a macro?
    ldr     r2, [r10, #4]
    bl      find
    cmp     r0, #0
    ldreq   r1, [r10]                   @ (find gave its value)
    ldreq   r2, [r10, #4]
    beq     twice
    add     r10, r10, #16
    b       loop

string:                                 @ "text": its bytes as hex, then 00
    add     r1, r1, #1                  @ after the '"'
    subs    r2, r2, #2                  @ without both '"'
    beq     string_end
string_byte:
    ldrb    r0, [r1]
    bl      put_hex
    add     r1, r1, #1
    subs    r2, r2, #1
    bne     string_byte
string_end:
    mov     r0, #0                      @ the 00
    bl      put_hex
    mov     r0, #0x20
    bl      put
    b       loop

raw:                                    @ 'text': text as it is
    add     r1, r1, #1
    sub     r2, r2, #2
    bl      put_text
    b       loop

sized:                                  @ !n @n %n: r9 bytes of n; else a label
    ldrb    r7, [r1, #1]                @ a digit or '-' after the sign
    cmp     r7, #0x2d
    beq     number
    sub     r7, r7, #0x30
    cmp     r7, #9
    bls     number
    b       copy                        @ !name @name %name: for hex2
number:
    mov     r11, r1                     @ the token, for a message
    mov     r12, r2
    add     r1, r1, #1                  @ after the sign
    sub     r2, r2, #1
    bl      parse
    mov     r1, r11
    mov     r2, r12
    cmp     r0, #0
    bne     bad_number
    cmp     r9, #4                      @ 4 bytes: any 32-bit number
    beq     number_byte
    lsl     r7, r9, #3                  @ fits: -2^(8n-1) <= n < 2^(8n)
    mov     r0, #1
    lsl     r0, r0, r7                  @ 2^(8n)
    lsr     r7, r0, #1                  @ 2^(8n-1)
    add     r12, r3, r7                 @ + 2^(8n-1): from 0 ...
    add     r7, r7, r0                  @ ... to below 2^(8n) + 2^(8n-1)
    cmp     r12, r7
    bhs     range
number_byte:                            @ the low byte first
    mov     r0, r3
    bl      put_hex
    lsr     r3, r3, #8
    subs    r9, r9, #1
    bne     number_byte
    mov     r0, #0x20
    bl      put
    b       loop

pass_end:
    add     r8, r8, #1
    cmp     r8, #2                      @ after pass 1, pass 2
    beq     pass
    mov     r1, #OUTPUT                 @ after pass 2, write it
write:
    subs    r2, r6, r1                  @ what is left
    beq     done
    mov     r7, #SYS_write
    mov     r0, #1                      @ fd 1, stdout
    svc     #0
    cmp     r0, #0
    ble     write_failed
    add     r1, r1, r0
    b       write
done:
    mov     r0, #0                      @ status 0
    b       exit

token:                                  @ the next token: r1, r2, r0 = 0; r0 = 1 at the end (uses r7)
    cmp     r4, r5
    bhs     no_token
    ldrb    r7, [r4]
    cmp     r7, #0x23                   @ '#': a comment
    beq     comment
    cmp     r7, #0x3b                   @ ';': a comment
    beq     comment
    cmp     r7, #0x20                   @ a space, tab, newline, ...
    bhi     word
    add     r4, r4, #1
    cmp     r7, #0x0a                   @ a newline goes out in pass 2
    bne     token
    cmp     r8, #1
    beq     token
    cmp     r6, #OUTPUT_END
    bhs     too_long
    strb    r7, [r6], #1
    b       token
comment:                                @ skip to the newline
    add     r4, r4, #1
    cmp     r4, r5
    bhs     no_token
    ldrb    r7, [r4]
    cmp     r7, #0x0a
    bne     comment
    b       token
word:
    mov     r1, r4                      @ its first byte
    add     r4, r4, #1
    cmp     r7, #0x22                   @ '"' or "'": to the same again
    beq     quoted
    cmp     r7, #0x27
    beq     quoted
word_byte:
    cmp     r4, r5
    bhs     word_end
    ldrb    r0, [r4]
    cmp     r0, #0x20                   @ ends at a space, tab, newline
    bls     word_end
    add     r4, r4, #1
    b       word_byte
quoted:
    cmp     r4, r5
    bhs     unterminated
    ldrb    r0, [r4]
    cmp     r0, r7
    beq     quoted_end
    add     r4, r4, #1
    b       quoted
quoted_end:
    add     r4, r4, #1                  @ after the closing one
word_end:
    sub     r2, r4, r1
    mov     r0, #0
    bx      lr
no_token:
    mov     r0, #1
    bx      lr

parse:                                  @ r3 = the number r1, r2, r0 = 0; r0 = 1 if none (uses r7)
    mov     r3, #0
    mov     r0, #0                      @ 1 if negative
    cmp     r2, #0
    beq     not_number
    ldrb    r7, [r1]
    cmp     r7, #0x2d                   @ '-'
    bne     parse_base
    mov     r0, #1
    add     r1, r1, #1
    subs    r2, r2, #1
    beq     not_number
parse_base:
    cmp     r2, #2                      @ 0x: hex
    bls     decimal_digit
    ldrb    r7, [r1]
    cmp     r7, #0x30
    bne     decimal_digit
    ldrb    r7, [r1, #1]
    cmp     r7, #0x78                   @ 'x'
    cmpne   r7, #0x58                   @ 'X'
    bne     decimal_digit
    add     r1, r1, #2
    sub     r2, r2, #2
hex_digit:
    ldrb    r7, [r1]
    sub     r7, r7, #0x30               @ '0'-'9' to 0-9
    cmp     r7, #10
    blo     hex_add
    sub     r7, r7, #0x11               @ 'A'-'F' to 0-5
    cmp     r7, #6
    blo     hex_letter
    sub     r7, r7, #0x20               @ 'a'-'f' to 0-5
    cmp     r7, #6
    bhs     not_number
hex_letter:
    add     r7, r7, #10
hex_add:
    add     r3, r7, r3, lsl #4
    add     r1, r1, #1
    subs    r2, r2, #1
    bne     hex_digit
    b       parse_sign
decimal_digit:
    ldrb    r7, [r1]
    sub     r7, r7, #0x30               @ '0'-'9'
    cmp     r7, #9
    bhi     not_number
    add     r3, r3, r3, lsl #2          @ times 10, plus the digit
    add     r3, r7, r3, lsl #1
    add     r1, r1, #1
    subs    r2, r2, #1
    bne     decimal_digit
parse_sign:
    cmp     r0, #0
    rsbne   r3, r3, #0                  @ negative
    mov     r0, #0
    bx      lr
not_number:
    mov     r0, #1
    bx      lr

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

find:                                   @ r1, r2 = the value of macro r1, r2, r0 = 0; r0 = 1 if none (uses r3, r7, r9, r11, r12)
    mov     r3, #MACROS
find_next:
    cmp     r3, r10
    bhs     not_found
    ldr     r7, [r3, #4]                @ the same length
    cmp     r7, r2
    bne     find_on
    ldr     r12, [r3]                   @ and the same bytes
    mov     r9, #0
find_byte:
    cmp     r9, r2
    beq     found
    ldrb    r7, [r12, r9]
    ldrb    r11, [r1, r9]
    cmp     r7, r11
    bne     find_on
    add     r9, r9, #1
    b       find_byte
find_on:
    add     r3, r3, #16
    b       find_next
not_found:
    mov     r0, #1
    bx      lr
found:
    ldr     r1, [r3, #8]
    ldr     r2, [r3, #12]
    mov     r0, #0
    bx      lr

put_text:                               @ writes r1, r2, then a space (uses r0, r7)
    cmp     r2, #0
    beq     put_space
    cmp     r6, #OUTPUT_END
    bhs     too_long
    ldrb    r7, [r1], #1
    strb    r7, [r6], #1
    sub     r2, r2, #1
    b       put_text
put_space:
    mov     r0, #0x20
put:                                    @ writes the byte r0
    cmp     r6, #OUTPUT_END
    bhs     too_long
    strb    r0, [r6], #1
    bx      lr

put_hex:                                @ writes the byte r0 as two hex digits (uses r7, r12)
    add     r7, r6, #2
    cmp     r7, #OUTPUT_END
    bhi     too_long
    la      r12, digits
    ubfx    r7, r0, #4, #4              @ its high half
    ldrb    r7, [r12, r7]
    strb    r7, [r6]
    and     r7, r0, #15                 @ its low half
    ldrb    r7, [r12, r7]
    strb    r7, [r6, #1]
    add     r6, r6, #2
    bx      lr

unknown:
    la      r3, msg_unknown
    mov     r12, #msg_unknown_len
    b       die
twice:
    la      r3, msg_twice
    mov     r12, #msg_twice_len
    b       die
range:
    la      r3, msg_range
    mov     r12, #msg_range_len
    b       die
bad_number:
    la      r3, msg_number
    mov     r12, #msg_number_len
    b       die
unterminated:
    la      r3, msg_string
    mov     r12, #msg_string_len
    b       die_plain
no_value:
    la      r3, msg_value
    mov     r12, #msg_value_len
    b       die_plain
too_many:
    la      r3, msg_many
    mov     r12, #msg_many_len
    b       die_plain
too_large:
    la      r3, msg_large
    mov     r12, #msg_large_len
    b       die_plain
too_long:
    la      r3, msg_long
    mov     r12, #msg_long_len
    b       die_plain
read_failed:
    la      r3, msg_read
    mov     r12, #msg_read_len
    b       die_plain
write_failed:
    la      r3, msg_write
    mov     r12, #msg_write_len
die_plain:
    mov     r2, #0                      @ no token
die:                                    @ message r3, r12, then token r1, r2
    mov     r4, r1
    mov     r5, r2
    mov     r1, r3
    mov     r2, r12
    bl      ewrite
    mov     r1, r4
    mov     r2, r5
    bl      ewrite
    la      r1, digits                  @ digits ends with the newline
    add     r1, r1, #16
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
