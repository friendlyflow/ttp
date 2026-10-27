# M1 for riscv64 Linux: a macro assembler, hex2 with names. The third link
# of the bootstrap, built by hex2 from hosts/riscv64/M1.hex2 (made from
# this file once by gen/mkhex.pl, a dev aid; the chain never reads this
# file). It turns hosts/riscv64/asm.M1 into hex2 text, which hex2 makes
# into asm, the assembler of the seed's asm. As stage0-posix's M1 with
# --architecture riscv64 (mescc-tools M1-macro.c, express_word).
#
#   M1 < file.M1 > file.hex2
#
# The input is tokens: bytes up to a space, tab or newline (any byte up to
# 0x20). '#' and ';' start a comment to the end of the line. A token
#   DEFINE name value   makes name a macro: every other token name, before
#                       or after, becomes the text value (hex2 text: hex
#                       digits, or a word .hex)
#   "text"              the hex of the bytes of text, then 00 (a C string;
#                       text is every byte up to the next '"')
#   'text'              text as it is (raw hex2 text, spaces too)
#   !n @n ~n            the number n in an instruction's immediate field,
#                       as a word for hex2 (.hex, XORed into the next 4
#                       bytes written: the instruction, written with that
#                       field zero): ! I (n's bits 11:0 to 31:20), @ S
#                       (11:5 to 31:25, 4:0 to 11:7), ~ U (bits 31:12 of n
#                       + 0x800, the upper part of a lui or auipc whose
#                       addi adds n's low 12 bits, signed: !n); ! and @
#                       must fit in 12 bits, ~ in 32, signed or unsigned
#   $n %n               n in 2 or 4 bytes, little endian, as hex; it must
#                       fit, signed or unsigned
#                       (n: decimal, or hex after 0x, '-' before it for a
#                       negative one)
#   :name ~name !name @name $name |name *name &name ^hex .hex
#                       hex2's labels, references, addresses and words, as
#                       they are (a sign followed by a digit or '-' is a
#                       number, above)
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
# RV64IM, no compressed instructions. The registers:
#   s2  the next byte of the input          s3  the end of the input
#   s4  the next byte of the output         s5  the pass, 1 or 2
#   s6  the next free macro
#   s7  a number's bits (12, 16 or 32)      s8  its kind (below, sized)
#   s9, s10, s11  the return address of token, put_hex and put_text
# The routines take and give a0-a3 and use the t registers; token gives a
# token as a1 (its first byte), a2 (its length), a0 = 1 at the end of the
# input. A macro is 32 bytes: the address of its name in the input, the
# name's length, the address of its value, the value's length.

    .equ BASE, 0x600000
    .equ MACROS, 0x700000               # 65536 macros of 32 bytes
    .equ MACROS_END, MACROS + 0x10000 * 32
    .equ INPUT, 0x900000                # 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTPUT, 0x1900000              # 64 MiB of output
    .equ OUTPUT_END, OUTPUT + 0x4000000
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
    .dword MACROS                       # p_vaddr: the macros, input, output
    .dword MACROS                       # p_paddr: the same
    .dword 0                            # p_filesz: none, all zero
    .dword OUTPUT_END - MACROS          # p_memsz: to the end of the output
    .dword 0x1000                       # p_align: a page

str_define:     .ascii "DEFINE"
digits:         .ascii "0123456789ABCDEF\n"
msg_unknown:    .asciz "M1: unknown macro: "
msg_twice:      .asciz "M1: macro defined twice: "
msg_range:      .asciz "M1: number out of range: "
msg_number:     .asciz "M1: not a number: "
msg_string:     .asciz "M1: string without its end"
msg_value:      .asciz "M1: DEFINE without its value"
msg_many:       .asciz "M1: too many macros"
msg_large:      .asciz "M1: input too large"
msg_long:       .asciz "M1: output too large"
msg_read:       .asciz "M1: read failed"
msg_write:      .asciz "M1: write failed"
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
    li      s6, MACROS                  # no macros yet
    li      s4, OUTPUT                  # no output yet
    li      s5, 1                       # pass 1
pass:
    li      s2, INPUT                   # from the first byte
loop:                                   # the next token
    jal     s9, token
    bne     a0, zero, pass_end
    li      t0, 6                       # DEFINE?
    bne     a2, t0, not_define
    la      t1, str_define
    mv      t2, a1
    addi    t3, a1, 6
define_byte:
    beq     t2, t3, define
    lbu     t4, 0(t1)
    lbu     t5, 0(t2)
    bne     t4, t5, not_define
    addi    t1, t1, 1
    addi    t2, t2, 1
    j       define_byte
not_define:
    li      t0, 1                       # pass 1 only looks for DEFINE
    beq     s5, t0, loop
    lbu     a0, 0(a1)                   # its first byte
    li      t0, 0x22                    # '"': a string
    beq     a0, t0, string
    li      t0, 0x27                    # "'": raw text
    beq     a0, t0, raw
    li      s7, 12                      # '!': I, 12 bits
    li      s8, 0
    li      t0, 0x21
    beq     a0, t0, sized
    li      s8, 1                       # '@': S, 12 bits
    li      t0, 0x40
    beq     a0, t0, sized
    li      s7, 32                      # '~': U, 32 bits
    li      s8, 2
    li      t0, 0x7e
    beq     a0, t0, sized
    li      s7, 16                      # '$': 2 bytes
    li      s8, 3
    li      t0, 0x24
    beq     a0, t0, sized
    li      s7, 32                      # '%': 4 bytes, a number only
    li      s8, 4
    li      t0, 0x25
    beq     a0, t0, sized
    li      t0, 0x3a                    # ':' '|' '*' '&' '^' '.': for hex2
    beq     a0, t0, copy
    li      t0, 0x7c
    beq     a0, t0, copy
    li      t0, 0x2a
    beq     a0, t0, copy
    li      t0, 0x26
    beq     a0, t0, copy
    li      t0, 0x5e
    beq     a0, t0, copy
    li      t0, 0x2e
    beq     a0, t0, copy
    jal     ra, find                    # a macro: its value
    bne     a0, zero, expand
    mv      t1, a1                      # else only hex digits, as they are
    add     t2, a1, a2
hex_only:
    lbu     a0, 0(t1)
    jal     ra, hexval                  # (keeps t1, t2)
    blt     a0, zero, unknown
    addi    t1, t1, 1
    bne     t1, t2, hex_only
copy:                                   # the token as it is, then a space
    jal     s11, put_text
    j       loop
expand:
    ld      a1, 16(a0)                  # its value
    ld      a2, 24(a0)
    j       copy

define:                                 # DEFINE name value
    jal     s9, token                   # the name
    bne     a0, zero, no_value
    mv      a3, a1
    mv      t6, a2
    jal     s9, token                   # the value
    bne     a0, zero, no_value
    li      t0, 1                       # stored in pass 1, skipped in pass 2
    bne     s5, t0, loop
    mv      t4, a1                      # the value
    mv      t5, a2
    mv      a1, a3                      # the name
    mv      a2, t6
    jal     ra, find                    # (keeps t4, t5)
    bne     a0, zero, twice
    li      t0, MACROS_END
    bgeu    s6, t0, too_many
    sd      a1, 0(s6)                   # its name
    sd      a2, 8(s6)                   # its length
    sd      t4, 16(s6)                  # its value
    sd      t5, 24(s6)                  # its length
    addi    s6, s6, 32
    j       loop

string:                                 # "text": its bytes as hex, then 00
    addi    a1, a1, 1                   # after the '"'
    addi    a2, a2, -2                  # without both '"'
    add     a3, a1, a2                  # the end
string_byte:
    beq     a1, a3, string_end
    lbu     a0, 0(a1)
    jal     s10, put_hex                # (keeps a1, a3)
    addi    a1, a1, 1
    j       string_byte
string_end:
    li      a0, 0                       # the 00
    jal     s10, put_hex
    li      a0, 0x20
    jal     ra, put
    j       loop

raw:                                    # 'text': text as it is
    addi    a1, a1, 1
    addi    a2, a2, -2
    j       copy

sized:                                  # !n @n ~n $n %n: n of kind s8; else a label
    lbu     a0, 1(a1)                   # a digit or '-' after the sign
    li      t0, 0x2d
    beq     a0, t0, number
    addi    a0, a0, -0x30
    li      t0, 10
    bltu    a0, t0, number
    li      t0, 4                       # '%' only with a number
    beq     s8, t0, unknown
    j       copy                        # ~name !name @name $name: for hex2
number:
    jal     ra, parse                   # a0 = n, of a1 + 1, a2 - 1
    bne     a3, zero, bad_number
    li      t0, 1                       # fits: -2^(s7-1) <= n < 2^s7
    sll     t0, t0, s7                  # 2^s7
    srli    t1, t0, 1                   # 2^(s7-1)
    add     t2, a0, t1                  # + 2^(s7-1): from 0 ...
    add     t1, t1, t0                  # ... to below 2^s7 + 2^(s7-1)
    bgeu    t2, t1, range
    li      t0, 3                       # $ %: the bytes of n
    bgeu    s8, t0, bytes
    beq     s8, zero, word_i
    li      t0, 1
    beq     s8, t0, word_s
    li      t0, 0x800                   # U: (n + 0x800) & 0xfffff000
    add     a0, a0, t0
    srli    a0, a0, 12
    slli    a0, a0, 12
    j       word
word_i:                                 # I: n's bits 11:0 to 31:20
    slli    a0, a0, 52
    srli    a0, a0, 32
    j       word
word_s:                                 # S: 11:5 to 31:25, 4:0 to 11:7
    andi    t0, a0, 0x1f
    slli    t0, t0, 7
    srli    a0, a0, 5
    andi    a0, a0, 0x7f
    slli    a0, a0, 25
    or      a0, a0, t0
word:                                   # .hex: the 4 bytes of a0, the low first
    mv      a3, a0
    li      a0, 0x2e
    jal     ra, put
    mv      a0, a3
    li      s7, 32
bytes:                                  # s7 / 8 bytes of a0, the low first
    mv      a3, a0
number_byte:
    andi    a0, a3, 0xff
    jal     s10, put_hex                # (keeps a1, a3)
    srli    a3, a3, 8
    addi    s7, s7, -8
    bne     s7, zero, number_byte
    li      a0, 0x20
    jal     ra, put
    j       loop

pass_end:
    addi    s5, s5, 1
    li      t0, 2                       # after pass 1, pass 2
    beq     s5, t0, pass
    li      a1, OUTPUT                  # after pass 2, write the output
write:
    sub     a2, s4, a1                  # what is left
    beq     a2, zero, done
    li      a7, SYS_write
    li      a0, 1                       # fd 1, stdout
    ecall
    bge     zero, a0, write_failed
    add     a1, a1, a0
    j       write
done:
    li      a0, 0                       # status 0
    j       exit

token:                                  # the next token: a1, a2; a0 = 1 at the end
    bgeu    s2, s3, no_token
    lbu     a0, 0(s2)
    li      t0, 0x23                    # '#': a comment
    beq     a0, t0, comment
    li      t0, 0x3b                    # ';': a comment
    beq     a0, t0, comment
    li      t0, 0x20                    # a space, tab, newline, ...
    bltu    t0, a0, word_start
    addi    s2, s2, 1
    li      t0, 0x0a                    # a newline goes out in pass 2
    bne     a0, t0, token
    li      t0, 1
    beq     s5, t0, token
    jal     ra, put
    j       token
comment:                                # skip to the newline
    addi    s2, s2, 1
    bgeu    s2, s3, no_token
    lbu     t1, 0(s2)
    li      t0, 0x0a
    bne     t1, t0, comment
    j       token
word_start:
    mv      a1, s2                      # its first byte
    addi    s2, s2, 1
    li      t0, 0x22                    # '"' or "'": to the same again
    beq     a0, t0, quoted
    li      t0, 0x27
    beq     a0, t0, quoted
word_byte:
    bgeu    s2, s3, word_end
    lbu     t1, 0(s2)
    li      t0, 0x20                    # ends at a space, tab, newline
    bgeu    t0, t1, word_end
    addi    s2, s2, 1
    j       word_byte
quoted:
    bgeu    s2, s3, unterminated
    lbu     t1, 0(s2)
    addi    s2, s2, 1                   # after it (the closing one too)
    bne     t1, a0, quoted
word_end:
    sub     a2, s2, a1
    li      a0, 0
    jr      s9
no_token:
    li      a0, 1
    jr      s9

parse:                                  # a0 = the number a1 + 1, a2 - 1; a3 = 1 if none
    addi    t3, a1, 1                   # after the sign
    add     t4, a1, a2                  # the end
    li      a0, 0
    li      t5, 0                       # 1 if negative
    beq     t3, t4, not_number
    lbu     t1, 0(t3)
    li      t0, 0x2d                    # '-'
    bne     t1, t0, parse_base
    li      t5, 1
    addi    t3, t3, 1
    beq     t3, t4, not_number
parse_base:
    sub     t0, t4, t3                  # 0x and a digit at least: hex
    li      t1, 2
    bgeu    t1, t0, decimal_digit
    lbu     t1, 0(t3)
    li      t0, 0x30
    bne     t1, t0, decimal_digit
    lbu     t1, 1(t3)
    ori     t1, t1, 0x20                # 'X' as 'x'
    li      t0, 0x78
    bne     t1, t0, decimal_digit
    addi    t3, t3, 2
hex_digit:
    mv      t6, a0
    lbu     a0, 0(t3)
    mv      t2, ra
    jal     ra, hexval
    mv      ra, t2
    blt     a0, zero, not_number
    slli    t6, t6, 4
    or      a0, a0, t6
    addi    t3, t3, 1
    bne     t3, t4, hex_digit
    j       parse_sign
decimal_digit:
    lbu     t1, 0(t3)
    addi    t1, t1, -0x30               # '0'-'9'
    li      t0, 10
    bgeu    t1, t0, not_number
    li      t0, 10
    mul     a0, a0, t0
    add     a0, a0, t1
    addi    t3, t3, 1
    bne     t3, t4, decimal_digit
parse_sign:
    beq     t5, zero, parsed
    neg     a0, a0
parsed:
    li      a3, 0
    ret
not_number:
    li      a3, 1
    ret

hexval:                                 # a0 = the value of hex digit a0, or -1 (uses t0)
    addi    a0, a0, -0x30               # '0'-'9' to 0-9
    li      t0, 10
    bltu    a0, t0, hexval_done
    ori     a0, a0, 0x20                # 'A'-'F' to 'a'-'f' (0x11-0x16 to 0x31-0x36)
    addi    a0, a0, -0x31               # 'a'-'f' to 0-5
    li      t0, 6
    bgeu    a0, t0, no_digit
    addi    a0, a0, 10                  # 10-15
hexval_done:
    ret
no_digit:
    li      a0, -1
    ret

find:                                   # a0 = the macro of name a1, a2, or 0 (uses t0-t3, t6)
    li      a0, MACROS
find_next:
    bgeu    a0, s6, not_found
    ld      t0, 8(a0)                   # the same length
    bne     t0, a2, find_on
    ld      t1, 0(a0)                   # and the same bytes
    mv      t2, a1
    add     t3, a1, a2
find_byte:
    beq     t2, t3, found
    lbu     t0, 0(t1)
    lbu     t6, 0(t2)
    bne     t0, t6, find_on
    addi    t1, t1, 1
    addi    t2, t2, 1
    j       find_byte
find_on:
    addi    a0, a0, 32
    j       find_next
not_found:
    li      a0, 0
found:
    ret

put_text:                               # writes a1, a2, then a space (returns by s11)
    add     a3, a1, a2
put_text_byte:
    beq     a1, a3, put_text_end
    lbu     a0, 0(a1)
    jal     ra, put
    addi    a1, a1, 1
    j       put_text_byte
put_text_end:
    li      a0, 0x20
    jal     ra, put
    jr      s11

put_hex:                                # writes the byte a0 as two hex digits (returns by s10)
    andi    t2, a0, 15
    srli    a0, a0, 4
    la      t1, digits
    add     a0, a0, t1
    lbu     a0, 0(a0)
    jal     ra, put                     # (keeps t1, t2)
    add     a0, t2, t1
    lbu     a0, 0(a0)
    jal     ra, put
    jr      s10

put:                                    # writes the byte a0 (uses t0)
    li      t0, OUTPUT_END
    bgeu    s4, t0, too_long
    sb      a0, 0(s4)
    addi    s4, s4, 1
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
bad_number:
    la      a3, msg_number
    j       die
unterminated:
    la      a3, msg_string
    j       die_plain
no_value:
    la      a3, msg_value
    j       die_plain
too_many:
    la      a3, msg_many
    j       die_plain
too_large:
    la      a3, msg_large
    j       die_plain
too_long:
    la      a3, msg_long
    j       die_plain
read_failed:
    la      a3, msg_read
    j       die_plain
write_failed:
    la      a3, msg_write
die_plain:
    li      a2, 0                       # no token
die:                                    # message a3 (to its 0), then token a1, a2
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
    la      a1, digits                  # digits ends with the newline
    addi    a1, a1, 16
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
