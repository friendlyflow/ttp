// M1 for aarch64 Linux: a macro assembler, hex2 with names. The third link
// of the bootstrap, built by hex2 from hosts/aarch64/M1.hex2 (made from
// this file once by gen/mkhex.pl, a dev aid; the chain never reads this
// file). It turns hosts/aarch64/asm.M1 into hex2 text, which hex2 makes
// into asm, the assembler of the seed's asm. As stage0-posix's M1.
//
//   M1 < file.M1 > file.hex2
//
// The input is tokens: bytes up to a space, tab or newline (any byte up to
// 0x20). '#' and ';' start a comment to the end of the line. A token
//   DEFINE name value   makes name a macro: every other token name, before
//                       or after, becomes the text value (hex digits)
//   "text"              the hex of the bytes of text, then 00 (a C string;
//                       text is every byte up to the next '"')
//   'text'              text as it is (raw hex2 text, spaces too)
//   !n @n %n            the number n in 1, 2 or 4 bytes, little endian, as
//                       hex: decimal, or hex after 0x, '-' before it for a
//                       negative one; it must fit, signed or unsigned
//   :name ^~name @name ~name !name &name ^hex
//                       hex2's labels, references and addresses, as they are
//                       (after ! @ % a name, not a number)
//   a macro's name      its value
//   hex digits          as they are (raw hex2 text)
// Anything else is an error. Out go the tokens' texts, each followed by a
// space, and a newline for each newline of the input: hex2 text, line by
// line as the input. The input is read whole, then twice: the first pass
// collects the macros, the second writes. On an unknown macro, a macro
// defined twice, a number that is none or does not fit, a string without
// its end, a full table, input or output and a failed read or write it
// says so on stderr and ends with status 1; else with 0.
//
// One flat file, loaded at BASE by its first program header, read and
// run; the second maps the memory it writes, MACROS to the end of OUTPUT.
// The registers:
//   x20  the next byte of the input        x21  the end of the input
//   x22  the next byte of the output       x23  the pass, 1 or 2
//   x24  the next free macro
// A macro is 32 bytes: the address of its name in the input, the name's
// length, the address of its value, the value's length.

    .equ BASE, 0x600000
    .equ MACROS, 0x700000               // 65536 macros of 32 bytes
    .equ MACROS_END, MACROS + 0x10000 * 32
    .equ INPUT, 0x900000                // 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTPUT, 0x1900000              // 64 MiB of output
    .equ OUTPUT_END, OUTPUT + 0x4000000
    .equ SYS_read, 63
    .equ SYS_write, 64
    .equ SYS_exit, 93

// la: reg = the address of sym, as ttpc.s's
    .macro la reg, sym
    adrp    \reg, \sym
    add     \reg, \reg, :lo12:\sym
    .endm

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
    .dword MACROS                       // p_vaddr: the macros, input, output
    .dword MACROS                       // p_paddr: the same
    .dword 0                            // p_filesz: none, all zero
    .dword OUTPUT_END - MACROS          // p_memsz: to the end of the output
    .dword 0x1000                       // p_align: a page

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
    .balign 4                           // the code, 4-byte aligned (zeros)

_start:                                 // read all of stdin into INPUT
    movz    x21, #0x90, lsl #16         // INPUT: the end of what is read
read:
    movz    x2, #0x190, lsl #16         // INPUT_END
    sub     x2, x2, x21                 // the room left
    cbz     x2, too_large
    movz    x8, #SYS_read
    movz    x0, #0                      // fd 0, stdin
    orr     x1, xzr, x21                // after what is read
    svc     #0
    cmp     x0, #0
    b.lt    read_failed
    b.eq    read_all                    // the end of stdin
    add     x21, x21, x0
    b       read
read_all:
    movz    x24, #0x70, lsl #16         // MACROS: no macros yet
    movz    x22, #0x190, lsl #16        // OUTPUT: no output yet
    movz    x23, #1                     // pass 1
pass:
    movz    x20, #0x90, lsl #16         // INPUT: from the first byte
loop:                                   // the next token
    bl      token
    cbnz    x0, pass_end
    cmp     x2, #6                      // DEFINE?
    b.ne    not_define
    la      x9, str_define
    orr     x10, xzr, x1
    add     x11, x1, #6
define_byte:
    ldrb    w12, [x9]
    ldrb    w13, [x10]
    cmp     x12, x13
    b.ne    not_define
    add     x9, x9, #1
    add     x10, x10, #1
    cmp     x10, x11
    b.ne    define_byte
    b       define
not_define:
    cmp     x23, #1                     // pass 1 only looks for DEFINE
    b.eq    loop
    ldrb    w9, [x1]                    // its first byte
    cmp     x9, #0x22                   // '"': a string
    b.eq    string
    cmp     x9, #0x27                   // "'": raw text
    b.eq    raw
    movz    x19, #1                     // '!': 1 byte
    cmp     x9, #0x21
    b.eq    sized
    movz    x19, #4                     // '%': 4 bytes
    cmp     x9, #0x25
    b.eq    sized
    movz    x19, #2                     // '@': 2 bytes
    cmp     x9, #0x40
    b.eq    sized
    cmp     x9, #0x3a                   // ':' '&' '^' '~': for hex2
    b.eq    copy
    cmp     x9, #0x26
    b.eq    copy
    cmp     x9, #0x5e
    b.eq    copy
    cmp     x9, #0x7e
    b.eq    copy
    bl      find                        // a macro: its value
    cbz     x0, expand
    orr     x3, xzr, x1                 // else only hex digits, as they are
    add     x4, x1, x2
hex_only:
    ldrb    w0, [x3]
    bl      hexval
    cmp     x0, #0
    b.lt    unknown
    add     x3, x3, #1
    cmp     x3, x4
    b.ne    hex_only
copy:                                   // the token as it is, then a space
    bl      put_text
    b       loop
expand:
    orr     x1, xzr, x3                 // its value
    orr     x2, xzr, x4
    b       copy

define:                                 // DEFINE name value
    bl      token                       // the name
    cbnz    x0, no_value
    orr     x25, xzr, x1
    orr     x26, xzr, x2
    bl      token                       // the value
    cbnz    x0, no_value
    cmp     x23, #1                     // stored in pass 1, skipped in pass 2
    b.ne    loop
    orr     x27, xzr, x1                // the value
    orr     x28, xzr, x2
    orr     x1, xzr, x25                // the name
    orr     x2, xzr, x26
    bl      find
    cbz     x0, twice
    movz    x9, #0x90, lsl #16          // MACROS_END
    cmp     x24, x9
    b.hs    too_many
    str     x1, [x24]                   // its name
    str     x2, [x24, #8]               // its length
    str     x27, [x24, #16]             // its value
    str     x28, [x24, #24]             // its length
    add     x24, x24, #32
    b       loop

string:                                 // "text": its bytes as hex, then 00
    add     x1, x1, #1                  // after the '"'
    sub     x2, x2, #2                  // without both '"'
    cbz     x2, string_end
string_byte:
    ldrb    w0, [x1]
    bl      put_hex
    add     x1, x1, #1
    sub     x2, x2, #1
    cbnz    x2, string_byte
string_end:
    movz    x0, #0                      // the 00
    bl      put_hex
    movz    x0, #0x20
    bl      put
    b       loop

raw:                                    // 'text': text as it is
    add     x1, x1, #1
    sub     x2, x2, #2
    bl      put_text
    b       loop

sized:                                  // !n @n %n: x19 bytes of n; else a label
    ldrb    w9, [x1, #1]                // a digit or '-' after the sign
    cmp     x9, #0x2d
    b.eq    number
    sub     x9, x9, #0x30
    cmp     x9, #9
    b.ls    number
    b       copy                        // !name @name %name: for hex2
number:
    orr     x25, xzr, x1                // the token, for a message
    orr     x26, xzr, x2
    add     x1, x1, #1                  // after the sign
    sub     x2, x2, #1
    bl      parse
    orr     x1, xzr, x25
    orr     x2, xzr, x26
    cbnz    x0, bad_number
    lsl     x9, x19, #3                 // fits: -2^(8n-1) <= n < 2^(8n)
    movz    x10, #1
    lslv    x10, x10, x9                // 2^(8n)
    lsr     x11, x10, #1                // 2^(8n-1)
    add     x12, x3, x11                // + 2^(8n-1): from 0 ...
    add     x11, x11, x10               // ... to below 2^(8n) + 2^(8n-1)
    cmp     x12, x11
    b.hs    range
number_byte:                            // the low byte first
    orr     x0, xzr, x3
    bl      put_hex
    lsr     x3, x3, #8
    sub     x19, x19, #1
    cbnz    x19, number_byte
    movz    x0, #0x20
    bl      put
    b       loop

pass_end:
    add     x23, x23, #1
    cmp     x23, #2                     // after pass 1, pass 2
    b.eq    pass
    movz    x1, #0x190, lsl #16         // OUTPUT: after pass 2, write it
write:
    sub     x2, x22, x1                 // what is left
    cbz     x2, done
    movz    x8, #SYS_write
    movz    x0, #1                      // fd 1, stdout
    svc     #0
    cmp     x0, #0
    b.le    write_failed
    add     x1, x1, x0
    b       write
done:
    movz    x0, #0                      // status 0
    b       exit

token:                                  // the next token: x1, x2, x0 = 0; x0 = 1 at the end
    cmp     x20, x21
    b.hs    no_token
    ldrb    w9, [x20]
    cmp     x9, #0x23                   // '#': a comment
    b.eq    comment
    cmp     x9, #0x3b                   // ';': a comment
    b.eq    comment
    cmp     x9, #0x20                   // a space, tab, newline, ...
    b.hi    word
    add     x20, x20, #1
    cmp     x9, #0x0a                   // a newline goes out in pass 2
    b.ne    token
    cmp     x23, #1
    b.eq    token
    movz    x10, #0x590, lsl #16        // OUTPUT_END
    cmp     x22, x10
    b.hs    too_long
    strb    w9, [x22]
    add     x22, x22, #1
    b       token
comment:                                // skip to the newline
    add     x20, x20, #1
    cmp     x20, x21
    b.hs    no_token
    ldrb    w9, [x20]
    cmp     x9, #0x0a
    b.ne    comment
    b       token
word:
    orr     x1, xzr, x20                // its first byte
    add     x20, x20, #1
    cmp     x9, #0x22                   // '"' or "'": to the same again
    b.eq    quoted
    cmp     x9, #0x27
    b.eq    quoted
word_byte:
    cmp     x20, x21
    b.hs    word_end
    ldrb    w10, [x20]
    cmp     x10, #0x20                  // ends at a space, tab, newline
    b.ls    word_end
    add     x20, x20, #1
    b       word_byte
quoted:
    cmp     x20, x21
    b.hs    unterminated
    ldrb    w10, [x20]
    cmp     x10, x9
    b.eq    quoted_end
    add     x20, x20, #1
    b       quoted
quoted_end:
    add     x20, x20, #1                // after the closing one
word_end:
    sub     x2, x20, x1
    movz    x0, #0
    ret
no_token:
    movz    x0, #1
    ret

parse:                                  // x3 = the number x1, x2, x0 = 0; x0 = 1 if none
    movz    x3, #0
    movz    x13, #0                     // 1 if negative
    cbz     x2, not_number
    ldrb    w9, [x1]
    cmp     x9, #0x2d                   // '-'
    b.ne    parse_base
    movz    x13, #1
    add     x1, x1, #1
    sub     x2, x2, #1
    cbz     x2, not_number
parse_base:
    cmp     x2, #2                      // 0x: hex
    b.ls    decimal_digit
    ldrb    w9, [x1]
    cmp     x9, #0x30
    b.ne    decimal_digit
    ldrb    w9, [x1, #1]
    cmp     x9, #0x78                   // 'x'
    b.eq    parse_hex
    cmp     x9, #0x58                   // 'X'
    b.ne    decimal_digit
parse_hex:
    add     x1, x1, #2
    sub     x2, x2, #2
hex_digit:
    ldrb    w9, [x1]
    sub     x10, x9, #0x30              // '0'-'9' to 0-9
    cmp     x10, #10
    b.lo    hex_add
    sub     x10, x9, #0x41              // 'A'-'F' to 0-5
    cmp     x10, #6
    b.lo    hex_letter
    sub     x10, x9, #0x61              // 'a'-'f' to 0-5
    cmp     x10, #6
    b.hs    not_number
hex_letter:
    add     x10, x10, #10
hex_add:
    add     x3, x10, x3, lsl #4
    add     x1, x1, #1
    sub     x2, x2, #1
    cbnz    x2, hex_digit
    b       parse_sign
decimal_digit:
    ldrb    w9, [x1]
    sub     x10, x9, #0x30              // '0'-'9'
    cmp     x10, #9
    b.hi    not_number
    movz    x11, #10
    madd    x3, x3, x11, x10
    add     x1, x1, #1
    sub     x2, x2, #1
    cbnz    x2, decimal_digit
parse_sign:
    cbz     x13, parsed
    sub     x3, xzr, x3                 // neg x3
parsed:
    movz    x0, #0
    ret
not_number:
    movz    x0, #1
    ret

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

find:                                   // x3, x4 = the value of macro x1, x2, x0 = 0; x0 = 1 if none
    movz    x9, #0x70, lsl #16          // MACROS
find_next:
    cmp     x9, x24
    b.hs    not_found
    ldr     x10, [x9, #8]               // the same length
    cmp     x10, x2
    b.ne    find_on
    ldr     x10, [x9]                   // and the same bytes
    orr     x11, xzr, x1
    add     x12, x1, x2
find_byte:
    cmp     x11, x12
    b.eq    found
    ldrb    w13, [x10]
    ldrb    w14, [x11]
    cmp     x13, x14
    b.ne    find_on
    add     x10, x10, #1
    add     x11, x11, #1
    b       find_byte
find_on:
    add     x9, x9, #32
    b       find_next
not_found:
    movz    x0, #1
    ret
found:
    ldr     x3, [x9, #16]
    ldr     x4, [x9, #24]
    movz    x0, #0
    ret

put_text:                               // writes x1, x2, then a space
    movz    x10, #0x590, lsl #16        // OUTPUT_END
put_text_byte:
    cbz     x2, put_space
    cmp     x22, x10
    b.hs    too_long
    ldrb    w9, [x1]
    strb    w9, [x22]
    add     x22, x22, #1
    add     x1, x1, #1
    sub     x2, x2, #1
    b       put_text_byte
put_space:
    movz    x0, #0x20
put:                                    // writes the byte x0
    movz    x10, #0x590, lsl #16        // OUTPUT_END
    cmp     x22, x10
    b.hs    too_long
    strb    w0, [x22]
    add     x22, x22, #1
    ret

put_hex:                                // writes the byte x0 as two hex digits
    movz    x10, #0x590, lsl #16        // OUTPUT_END
    add     x11, x22, #2
    cmp     x11, x10
    b.hi    too_long
    la      x9, digits
    ubfx    x10, x0, #4, #4             // its high half
    add     x10, x9, x10
    ldrb    w10, [x10]
    strb    w10, [x22]
    ubfx    x10, x0, #0, #4             // its low half
    add     x10, x9, x10
    ldrb    w10, [x10]
    strb    w10, [x22, #1]
    add     x22, x22, #2
    ret

unknown:
    la      x3, msg_unknown
    movz    x4, #msg_unknown_len
    b       die
twice:
    la      x3, msg_twice
    movz    x4, #msg_twice_len
    b       die
range:
    la      x3, msg_range
    movz    x4, #msg_range_len
    b       die
bad_number:
    la      x3, msg_number
    movz    x4, #msg_number_len
    b       die
unterminated:
    la      x3, msg_string
    movz    x4, #msg_string_len
    b       die_plain
no_value:
    la      x3, msg_value
    movz    x4, #msg_value_len
    b       die_plain
too_many:
    la      x3, msg_many
    movz    x4, #msg_many_len
    b       die_plain
too_large:
    la      x3, msg_large
    movz    x4, #msg_large_len
    b       die_plain
too_long:
    la      x3, msg_long
    movz    x4, #msg_long_len
    b       die_plain
read_failed:
    la      x3, msg_read
    movz    x4, #msg_read_len
    b       die_plain
write_failed:
    la      x3, msg_write
    movz    x4, #msg_write_len
die_plain:
    movz    x2, #0                      // no token
die:                                    // message x3, x4, then token x1, x2
    orr     x25, xzr, x1
    orr     x26, xzr, x2
    orr     x1, xzr, x3
    orr     x2, xzr, x4
    bl      ewrite
    orr     x1, xzr, x25
    orr     x2, xzr, x26
    bl      ewrite
    la      x1, digits                  // digits ends with the newline
    add     x1, x1, #16
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
