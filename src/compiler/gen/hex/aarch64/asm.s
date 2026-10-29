// asm for aarch64 Linux: the assembler of the seed. The fourth link of the
// bootstrap, built by M1 and hex2 from hosts/aarch64/asm.M1 (made from this
// file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
// It assembles hosts/aarch64/ttpc.s, the readable seed, into the seed: the
// bytes binutils' as and ld make of it (as, ld -static -s -z
// noseparate-code -Ttext=0x4000b0), with no binutils. Its generic part
// (lines, symbols, expressions, directives, the output) is a translation
// of gen/hex/riscv64/asm.s, nearly instruction by instruction, with
// ttpc.s's register map (s0-s9 x19-x28, s10 x29, s11 x18, a0-a6 x0-x6, a7
// x8, t0-t6 x9-x15, ra x30); its instructions are AArch64's own.
//
//   asm < ttpc.s > ttpc
//
// The asm it reads: aarch64 GNU syntax as ttpc.s uses it.
//   lines      labels (name: and the local n: of 0-99, as 1b and 1f), then
//              a directive, an instruction or a macro's name; '//' starts
//              a comment to the end of the line
//   directives .equ name, expr  .dword .word .hword .byte expr, ...
//              .ascii .asciz "text", ...  (escapes \n \t \ooo, \x as x)
//              .skip n  .balign n (not in .text)  .section name (.text
//              .rodata .data .bss)  .text .data .bss  .globl name
//              .macro name param, ... (its lines up to .endm; \param in
//              them is the call's argument)
//   exprs      numbers (decimal, 0x hex, 0 octal), names, '.' (here), and
//              as gas: unary - ~, then * / % << >>, then | & ^, then + -,
//              and ( ); a label's address plus or minus a number, or two
//              labels of a section minus each other
//   operands   registers (x0-x30 xzr sp, w0-w30 wzr), #expr, [xn] and
//              [xn, #expr], :lo12:expr, a condition (cset), and the label
//              (an expr) of a branch or adrp
//   mnemonics  mov, add sub adds subs cmp neg (immediate: 12 bits, or
//              shifted by 12; a negative one the other way, as gas; with sp
//              the extended register form), and orr eor (register or
//              bitmask immediate), lsl lsr asr (immediate or register), mul
//              udiv sdiv msub, cset, ldr str ldrb strb (unsigned offset,
//              or gas's ldur, stur, ldurb, sturb for a negative or
//              unaligned one), b bl b.cond cbz cbnz, ret br blr svc, adrp
// mov is gas's: of a register orr (add #0 with sp), of a number movz, else
// movn, else orr with a bitmask immediate. Every instruction is 4 bytes,
// so the passes need no relaxing. The output is the file ld makes: the ELF
// header, two program headers (the code: the headers, .text, .rodata; the
// data: .data, .bss, placed as ld's DATA_SEGMENT_ALIGN of 64 KiB pages,
// see layout), the sections, .shstrtab and six section headers. Each of
// .text .rodata .data .bss must have bytes.
//
// The input is read whole, then in two passes. Pass 1 sizes: every label
// gets its section and place (an instruction is 4 bytes, its operands
// unread); layout then gives every section its place. Pass 2 encodes and
// writes the sections into the output, which is then written whole. On
// an error it says so on stderr with the line (asm: line N: what: the
// line) and ends with status 1; else with 0.
//
// One flat file, loaded at BASE by its first program header, read and
// run; the second maps the memory it writes, VARS to the end of OUTBUF.
// The registers:
//   x19  VARS, the variables               x20  the next byte of the input
//   x21  the end of the input
//   x22  the instruction's base bits (from mnemonics), x23 its other bits
//   x24  rd (or rt)  x25  rn  x26  rm or the immediate
//   x27-x29, x18  scratch of the instructions; sp the stack of the routines
// The routines take and give x0-x8 and use x9-x15 (each says which); a
// routine that calls another keeps x30 on the stack, or in x14 or x15 when
// what it calls does not use them. A symbol is 40 bytes (S_*), a local
// label's definition 32 (L_*), a macro 96 (MAC_*). A definition (D) is a
// symbol's S_value or a local label's L_value: its value, kind (0 a
// number, 1-4 the section) and pass (0 not defined) at 0, 8, 16.

    .equ BASE, 0x600000
    .equ VARS, 0x700000                 // the variables, 64 KiB
    .equ MACROS, VARS + 0x2000          // 16 macros
    .equ MAC_max, 16
    .equ ARGS, VARS + 0x3000            // a macro call's arguments
    .equ EXPBUF, VARS + 0x4000          // a macro's line, expanded
    .equ EXPBUF_END, VARS + 0x5000
    .equ SYMS, VARS + 0x10000           // 65536 symbols
    .equ SYM_size, 40
    .equ SYMS_END, SYMS + 0x10000 * SYM_size
    .equ LOCAL_max, 4096                // definitions of each local label
    .equ LOCALS, SYMS_END               // 100 local labels
    .equ LOCALS_END, LOCALS + 100 * LOCAL_max * 32
    .equ INPUT, LOCALS_END              // 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTBUF, INPUT_END              // 16 MiB of output
    .equ OUTBUF_END, OUTBUF + 0x1000000
    .equ ADDR, 0x400000                 // where ld places the output
    .equ SHSTRTAB_len, 36               // the section names' bytes (shstrtab)
    .equ SYS_read, 63
    .equ SYS_write, 64
    .equ SYS_exit, 93

    // a symbol: its name in the input, then its definition
    .equ S_name, 0
    .equ S_len, 8
    .equ S_value, 16
    .equ S_kind, 24
    .equ S_pass, 32
    // a definition of a local label
    .equ L_value, 0
    .equ L_kind, 8
    .equ L_pass, 16
    // a macro: its name (8 bytes), its parameters' count, then each
    // parameter's name and length, its lines' first byte and their end
    .equ MAC_name, 0
    .equ MAC_n, 8
    .equ MAC_params, 16
    .equ MAC_body, 80
    .equ MAC_end, 88
    .equ MAC_size, 96

    // the variables, at x19
    .equ V_pass, 0                      // the pass, 1 or 2
    .equ V_emit, 8                      // 1 in pass 2, which writes
    .equ V_sec, 16                      // the section: 1 .text 2 .rodata 3 .data 4 .bss
    .equ V_line, 24                     // the line's number
    .equ V_nmac, 32                     // the next free macro
    .equ V_nsym, 40                     // the next free symbol
    .equ V_exact, 48                    // 0 once an expression used a name not defined before it
    .equ V_known, 56                    // 0 once it used a name not defined at all
    .equ V_lstart, 64                   // the line's first byte
    .equ V_loc, 72                      // section s's location counter at V_loc + 8 * s
    .equ V_align, 112                   // its alignment
    .equ V_base, 152                    // its address (0 for s = 0, a number)
    .equ V_off, 192                     // its file offset
    .equ V_shstr, 232                   // the file offset of .shstrtab
    .equ V_shoff, 240                   // of the section headers
    .equ V_fend, 248                    // the file's size
    .equ V_tend, 256                    // the end of .rodata in the file: of the code segment
    .equ V_sret, 280                    // statement's return address
    .equ COUNTS, 400                    // local label n's definitions so far at COUNTS + 8 * n
    .equ NUMBUF, 1200                   // a decimal number, 24

// la: reg = the address of sym, as ttpc.s's
    .macro la reg, sym
    adrp    \reg, \sym
    add     \reg, \reg, :lo12:\sym
    .endm
// li32: reg = the 32-bit number val
    .macro li32 reg, val
    movz    \reg, #(\val) & 0xffff
    movk    \reg, #((\val) >> 16) & 0xffff, lsl #16
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
    .dword VARS                         // p_vaddr: the variables, ..., the output
    .dword VARS                         // p_paddr: the same
    .dword 0                            // p_filesz: none, all zero
    .dword OUTBUF_END - VARS            // p_memsz: to the end of the output
    .dword 0x1000                       // p_align: a page

_start:                                 // read all of stdin into INPUT
    mov     x19, #VARS
    mov     x21, #INPUT                 // the end of what is read
read:
    movz    x2, #0xffff   // INPUT_END - 1 // a 0 stays after the input
    movk    x2, #0x2c8, lsl #16
    sub     x2, x2, x21                 // the room left
    cbz     x2, too_large
    mov     x8, #SYS_read
    mov     x0, #0                      // fd 0, stdin
    mov     x1, x21                     // after what is read
    svc     #0
    cmp     x0, #0
    b.lt    read_failed
    cbz     x0, read_all                // the end of stdin
    add     x21, x21, x0
    b       read
read_all:
    mov     x9, #SYMS                   // no symbols yet
    str     x9, [x19, #V_nsym]
    mov     x9, #4                      // .text aligned to 4 (gas's)
    str     x9, [x19, #V_align+8]
    mov     x9, #1                      // the others to 1, until .balign
    str     x9, [x19, #V_align+16]
    str     x9, [x19, #V_align+24]
    str     x9, [x19, #V_align+32]
    str     x9, [x19, #V_pass]          // pass 1: sizes and labels
    bl      pass
    bl      layout
    mov     x9, #2                      // pass 2 writes
    str     x9, [x19, #V_pass]
    mov     x9, #1
    str     x9, [x19, #V_emit]
    bl      pass
    bl      headers
    mov     x1, #OUTBUF                 // write the output
    ldr     x3, [x19, #V_fend]
    add     x3, x3, x1                  // its end
write:
    sub     x2, x3, x1                  // what is left
    cbz     x2, done
    mov     x8, #SYS_write
    mov     x0, #1                      // fd 1, stdout
    svc     #0
    cmp     x0, #0
    b.le    write_failed
    add     x1, x1, x0
    b       write
done:
    mov     x0, #0                      // status 0
    b       exit

// A pass over the input, line by line.
pass:
    sub     sp, sp, #16
    str     x30, [sp]
    str     xzr, [x19, #V_loc]          // every section from 0
    str     xzr, [x19, #V_loc+8]
    str     xzr, [x19, #V_loc+16]
    str     xzr, [x19, #V_loc+24]
    str     xzr, [x19, #V_loc+32]
    add     x9, x19, #MACROS - VARS     // no macros yet
    str     x9, [x19, #V_nmac]
    add     x9, x19, #COUNTS            // no local labels yet
    add     x10, x19, #COUNTS + 800
pass_count:
    str     xzr, [x9]
    add     x9, x9, #8
    cmp     x9, x10
    b.ne    pass_count
    mov     x9, #1                      // in .text
    str     x9, [x19, #V_sec]
    str     x9, [x19, #V_line]
    mov     x20, #INPUT
pass_line:
    cmp     x20, x21
    b.hs    pass_end
    str     x20, [x19, #V_lstart]
    bl      statement
    ldr     x9, [x19, #V_line]
    add     x9, x9, #1
    str     x9, [x19, #V_line]
    b       pass_line
pass_end:
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

// One line, to after its newline: labels, then a directive or an
// instruction (each ends with end_line, which returns from statement).
statement:
    str     x30, [x19, #V_sret]
statement_next:
    bl      blanks
    ldrb    w0, [x20]
    bl      is_ident
    cbz     x0, end_line                // no name: only a comment may follow
    bl      word                        // x1, x2
    ldrb    w9, [x20]
    mov     x10, #0x3a                  // ':': a label
    cmp     x9, x10
    b.eq    label
    ldrb    w9, [x1]
    mov     x10, #0x2e                  // '.': a directive
    cmp     x9, x10
    b.eq    directive
    b       insn
label:
    add     x20, x20, #1
    bl      define_label
    b       statement_next

end_line:                               // nothing but a comment until the newline, then after it
    bl      blanks
    cmp     x20, x21
    b.hs    end_line_done
    ldrb    w9, [x20]
    mov     x10, #0x2f                  // '//'
    cmp     x9, x10
    b.ne    end_line_nl
    ldrb    w9, [x20, #1]
    cmp     x9, x10
    b.eq    end_comment
    b       junk
end_line_nl:
    mov     x10, #0x0a                  // '\n'
    cmp     x9, x10
    b.ne    junk
    add     x20, x20, #1
end_line_done:
    ldr     x30, [x19, #V_sret]
    ret
end_comment:
    add     x20, x20, #1
    cmp     x20, x21
    b.hs    end_line_done
    ldrb    w9, [x20]
    mov     x10, #0x0a
    cmp     x9, x10
    b.ne    end_comment
    add     x20, x20, #1
    b       end_line_done

blanks:                                 // skips spaces and tabs (uses x9, x10)
    ldrb    w9, [x20]
    mov     x10, #0x20                  // ' '
    cmp     x9, x10
    b.eq    blanks_skip
    mov     x10, #0x09                  // '\t'
    cmp     x9, x10
    b.ne    blanks_done
blanks_skip:
    add     x20, x20, #1
    b       blanks
blanks_done:
    ret

is_ident:                               // x0 = 1 if byte x0 is a letter, a digit, '_' or '.', else 0 (uses x9)
    mov     x9, #0x2e                   // '.'
    cmp     x0, x9
    b.eq    ident_yes
    mov     x9, #0x5f                   // '_'
    cmp     x0, x9
    b.eq    ident_yes
    sub     x9, x0, #0x30               // '0'-'9'
    cmp     x9, #10
    cset    x9, lo
    cbnz    x9, ident_yes
    orr     x9, x0, #0x20               // 'A'-'Z' as 'a'-'z'
    sub     x9, x9, #0x61
    cmp     x9, #26
    cset    x9, lo
    cbnz    x9, ident_yes
    mov     x0, #0
    ret
ident_yes:
    mov     x0, #1
    ret

word:                                   // x1, x2 = the name at x20, which moves after it (uses x0, x9, x14)
    mov     x14, x30
    mov     x1, x20
word_byte:
    ldrb    w0, [x20]
    bl      is_ident
    cbz     x0, word_end
    add     x20, x20, #1
    b       word_byte
word_end:
    sub     x2, x20, x1
    mov     x30, x14
    ret

pack:                                   // x0 = name x1, x2 as 8 bytes (the first lowest), -1 if longer (uses x9, x10)
    mov     x0, #-1
    mov     x9, #8
    cmp     x9, x2
    b.lo    pack_done
    mov     x0, #0
    mov     x9, x2
pack_byte:                              // from the last byte to the first
    cbz     x9, pack_done
    lsl     x0, x0, #8
    add     x10, x1, x9
    ldrb    w10, [x10, #-1]
    orr     x0, x0, x10
    sub     x9, x9, #1
    b       pack_byte
pack_done:
    ret

// The symbols.

define_label:                           // name x1, x2: here
    sub     sp, sp, #16
    str     x30, [sp]
    bl      digits                      // n: a local label
    cbz     x3, define_local
    bl      here_def                    // x3, x4
    mov     x5, #1                      // defined twice in a pass: an error
    bl      define
    b       define_label_done
define_local:
    bl      local_def
define_label_done:
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

here_def:                               // x3 = here's value, x4 its kind (uses x9)
    ldr     x4, [x19, #V_sec]
    lsl     x9, x4, #3
    add     x9, x9, x19
    ldr     x3, [x9, #V_loc]            // the section's location
    ret

define:                                 // x0 = symbol x1, x2, defined as x3 of kind x4 (uses x9-x15)
    mov     x15, x30                    // x5 = 1: an error if defined in this pass
    bl      find_sym
    cbnz    x0, define_found
    bl      sym_new
    b       define_set
define_found:
    cbz     x5, define_set
    ldr     x9, [x0, #S_pass]
    ldr     x10, [x19, #V_pass]
    cmp     x9, x10
    b.eq    twice
define_set:
    str     x3, [x0, #S_value]
    str     x4, [x0, #S_kind]
    ldr     x9, [x19, #V_pass]
    str     x9, [x0, #S_pass]
    mov     x30, x15
    ret

sym_new:                                // x0 = a new symbol x1, x2, not yet defined (uses x9)
    ldr     x0, [x19, #V_nsym]
    mov     x9, #SYMS_END
    cmp     x0, x9
    b.hs    too_many_symbols
    add     x9, x0, #SYM_size
    str     x9, [x19, #V_nsym]
    str     x1, [x0, #S_name]
    str     x2, [x0, #S_len]
    ret

find_sym:                               // x0 = symbol x1, x2, or 0 (uses x9-x14)
    mov     x0, #SYMS
    ldr     x13, [x19, #V_nsym]
find_sym_next:
    cmp     x0, x13
    b.hs    find_sym_none
    ldr     x9, [x0, #S_len]            // the same length
    cmp     x9, x2
    b.ne    find_sym_on
    ldr     x10, [x0, #S_name]          // and the same bytes
    mov     x11, x1
    add     x12, x1, x2
find_sym_byte:
    cmp     x11, x12
    b.eq    find_sym_found
    ldrb    w9, [x10]
    ldrb    w14, [x11]
    cmp     x9, x14
    b.ne    find_sym_on
    add     x10, x10, #1
    add     x11, x11, #1
    b       find_sym_byte
find_sym_on:
    add     x0, x0, #SYM_size
    b       find_sym_next
find_sym_none:
    mov     x0, #0
find_sym_found:
    ret

local_def:                              // local label x0: here (uses x9, x10, x15)
    mov     x9, #100
    cmp     x0, x9
    b.hs    bad_local
    lsl     x9, x0, #3                  // its definitions so far: this one's number
    add     x9, x9, x19
    ldr     x1, [x9, #COUNTS]
    add     x10, x1, #1
    str     x10, [x9, #COUNTS]
    mov     x15, x30
    bl      local_entry
    bl      here_def
    mov     x30, x15
    str     x3, [x0, #L_value]
    str     x4, [x0, #L_kind]
    ldr     x9, [x19, #V_pass]
    str     x9, [x0, #L_pass]
    ret

local_entry:                            // x0 = definition x1 of local label x0 (uses x9)
    mov     x9, #100
    cmp     x0, x9
    b.hs    bad_local
    mov     x9, #LOCAL_max              // (-1 too: below 0)
    cmp     x1, x9
    b.hs    bad_local
    mul     x0, x0, x9
    add     x0, x0, x1
    lsl     x0, x0, #5
    mov     x9, #LOCALS
    add     x0, x0, x9
    ret

local_ref:                              // x0 = the definition nf or nb of local label x0, by the last byte of x1, x2 (uses x9-x11)
    mov     x9, #100
    cmp     x0, x9
    b.hs    bad_local
    lsl     x9, x0, #3                  // nf: the next definition of n
    add     x9, x9, x19
    ldr     x11, [x9, #COUNTS]
    add     x10, x1, x2
    ldrb    w10, [x10, #-1]
    mov     x9, #0x66                   // 'f'
    cmp     x10, x9
    b.eq    local_ref_entry
    sub     x11, x11, #1                // nb: the last one
local_ref_entry:
    mov     x1, x11
    b       local_entry

digits:                                 // x0 = name x1, x2 when it is decimal digits only, x3 = 0; else x3 = 1 (uses x9-x11)
    mov     x0, #0
    mov     x9, #0
digits_next:
    cmp     x9, x2
    b.hs    digits_done
    add     x10, x1, x9
    ldrb    w10, [x10]
    sub     x10, x10, #0x30             // '0'-'9'
    mov     x11, #10
    cmp     x10, x11
    b.hs    digits_not
    mul     x0, x0, x11
    add     x0, x0, x10
    add     x9, x9, #1
    b       digits_next
digits_done:
    mov     x3, #0
    ret
digits_not:
    mov     x3, #1
    ret

here:                                   // x0 = the address of the next byte, x1 its section (uses x9, x10)
    ldr     x1, [x19, #V_sec]
    lsl     x9, x1, #3
    add     x9, x9, x19
    ldr     x0, [x9, #V_loc]
    ldr     x10, [x9, #V_base]
    add     x0, x0, x10
    ret

// Expressions: x0 the value (with its section's address in pass 2), x1
// the kind; V_exact and V_known cleared as it says. Each level keeps its
// left side on the stack.

eval:                                   // the expression at x20
    mov     x9, #1
    str     x9, [x19, #V_exact]
    str     x9, [x19, #V_known]
    b       expr

eval_number:                            // x0 = the expression at x20: a number known here
    sub     sp, sp, #16
    str     x30, [sp]
    bl      eval
    cbnz    x1, not_number
    ldr     x9, [x19, #V_exact]
    cbz     x9, not_number
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

expr:                                   // + -
    sub     sp, sp, #32
    str     x30, [sp]
    bl      expr_or
expr_more:
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x2b                  // '+'
    cmp     x9, x10
    b.eq    expr_add
    mov     x10, #0x2d                  // '-'
    cmp     x9, x10
    b.eq    expr_sub
    ldr     x30, [sp]
    add     sp, sp, #32
    ret
expr_add:
    add     x20, x20, #1
    str     x0, [sp, #8]
    str     x1, [sp, #16]
    bl      expr_or
    ldr     x9, [sp, #8]                // the left one's value
    ldr     x10, [sp, #16]              // its kind
    add     x0, x0, x9
    cbz     x10, expr_more              // a number + x: x's kind
    cbnz    x1, expr_kinds              // a label + a number: the label's
    mov     x1, x10
    b       expr_more
expr_sub:
    add     x20, x20, #1
    str     x0, [sp, #8]
    str     x1, [sp, #16]
    bl      expr_or
    ldr     x9, [sp, #8]
    ldr     x10, [sp, #16]
    sub     x0, x9, x0
    cbz     x1, expr_sub_kind           // x - a number: x's kind
    cmp     x1, x10                     // two labels of a section: a number
    b.ne    expr_kinds
    mov     x1, #0
    b       expr_more
expr_sub_kind:
    mov     x1, x10
    b       expr_more
expr_kinds:
    bl      kinds
    b       expr_more

kinds:                                  // an operation on labels it cannot do: fine while names are unknown (uses x9)
    mov     x1, #0
    ldr     x9, [x19, #V_known]
    cbz     x9, kinds_unknown
    la      x0, msg_kinds
    b       fail
kinds_unknown:
    ret

expr_or:                                // | & ^
    sub     sp, sp, #32
    str     x30, [sp]
    bl      expr_mul
expr_or_more:
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x7c                  // '|'
    cmp     x9, x10
    b.eq    expr_or_op
    mov     x10, #0x26                  // '&'
    cmp     x9, x10
    b.eq    expr_or_op
    mov     x10, #0x5e                  // '^'
    cmp     x9, x10
    b.eq    expr_or_op
    ldr     x30, [sp]
    add     sp, sp, #32
    ret
expr_or_op:
    add     x20, x20, #1
    str     x9, [sp, #24]               // the operator
    str     x0, [sp, #8]
    str     x1, [sp, #16]
    bl      expr_mul
    ldr     x10, [sp, #16]              // numbers only
    orr     x10, x10, x1
    cbz     x10, expr_or_numbers
    bl      kinds
expr_or_numbers:
    mov     x1, #0
    ldr     x9, [sp, #8]
    ldr     x11, [sp, #24]
    mov     x10, #0x7c                  // '|'
    cmp     x11, x10
    b.ne    expr_and
    orr     x0, x9, x0
    b       expr_or_more
expr_and:
    mov     x10, #0x26                  // '&'
    cmp     x11, x10
    b.ne    expr_xor
    and     x0, x9, x0
    b       expr_or_more
expr_xor:
    eor     x0, x9, x0
    b       expr_or_more

expr_mul:                               // * / % << >>
    sub     sp, sp, #32
    str     x30, [sp]
    bl      expr_unary
expr_mul_more:
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x2a                  // '*'
    cmp     x9, x10
    b.eq    expr_mul_op
    mov     x10, #0x2f                  // '/', but not '//' (a comment)
    cmp     x9, x10
    b.eq    expr_slash
    mov     x10, #0x25                  // '%'
    cmp     x9, x10
    b.eq    expr_mul_op
    mov     x10, #0x3c                  // '<' of '<<'
    cmp     x9, x10
    b.eq    expr_shift
    mov     x10, #0x3e                  // '>' of '>>'
    cmp     x9, x10
    b.eq    expr_shift
expr_mul_done:
    ldr     x30, [sp]
    add     sp, sp, #32
    ret
expr_slash:
    ldrb    w10, [x20, #1]
    cmp     x10, x9
    b.ne    expr_mul_op
    b       expr_mul_done
expr_shift:
    ldrb    w10, [x20, #1]              // doubled
    cmp     x10, x9
    b.ne    expr_mul_done
    add     x20, x20, #1
expr_mul_op:
    add     x20, x20, #1
    str     x9, [sp, #24]               // the operator
    str     x0, [sp, #8]
    str     x1, [sp, #16]
    bl      expr_unary
    ldr     x10, [sp, #16]              // numbers only
    orr     x10, x10, x1
    cbz     x10, expr_mul_numbers
    bl      kinds
expr_mul_numbers:
    mov     x1, #0
    ldr     x9, [sp, #8]                // the left one
    ldr     x11, [sp, #24]
    mov     x10, #0x2a                  // '*'
    cmp     x11, x10
    b.ne    expr_div
    mul     x0, x9, x0
    b       expr_mul_more
expr_div:
    mov     x10, #0x3c                  // '<<'
    cmp     x11, x10
    b.eq    expr_shl
    mov     x10, #0x3e                  // '>>'
    cmp     x11, x10
    b.eq    expr_shr
    cbz     x0, expr_by_zero
    mov     x10, #0x2f                  // '/': signed, as gas
    cmp     x11, x10
    b.ne    expr_rem
    sdiv    x0, x9, x0
    b       expr_mul_more
expr_rem:                               // '%'
    sdiv    x16, x9, x0
    msub    x0, x16, x0, x9
    b       expr_mul_more
expr_by_zero:                           // fine while names are unknown
    ldr     x10, [x19, #V_known]
    cbnz    x10, bad_expr
    b       expr_mul_more
expr_shl:
    lsl     x0, x9, x0
    b       expr_mul_more
expr_shr:
    asr     x0, x9, x0
    b       expr_mul_more

expr_unary:                             // - ~ ( ), a number, a name, '.'
    sub     sp, sp, #16
    str     x30, [sp]
    bl      blanks
    ldrb    w0, [x20]
    mov     x9, #0x2d                   // '-'
    cmp     x0, x9
    b.eq    unary_neg
    mov     x9, #0x7e                   // '~'
    cmp     x0, x9
    b.eq    unary_not
    mov     x9, #0x28                   // '('
    cmp     x0, x9
    b.eq    unary_paren
    bl      is_ident
    cbz     x0, bad_expr
    bl      word
    ldrb    w9, [x1]
    sub     x9, x9, #0x30               // '0'-'9': a number
    mov     x10, #10
    cmp     x9, x10
    b.lo    unary_number
    mov     x9, #1                      // '.': here
    cmp     x2, x9
    b.ne    unary_symbol
    ldrb    w9, [x1]
    mov     x10, #0x2e
    cmp     x9, x10
    b.ne    unary_symbol
    bl      here
    b       unary_done
unary_neg:
    add     x20, x20, #1
    bl      expr_unary
    neg     x0, x0
    b       unary_number_only
unary_not:
    add     x20, x20, #1
    bl      expr_unary
    mvn     x0, x0
unary_number_only:
    cbz     x1, unary_done
    bl      kinds
    b       unary_done
unary_paren:
    add     x20, x20, #1
    bl      expr
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x29                  // ')'
    cmp     x9, x10
    b.ne    bad_expr
    add     x20, x20, #1
    b       unary_done
unary_symbol:
    bl      find_sym
    cbz     x0, undefined
    add     x0, x0, #S_value            // its definition
    b       unary_def
unary_number:                           // digits, then b or f: a local label's
    add     x9, x1, x2
    ldrb    w9, [x9, #-1]
    mov     x10, #0x62                  // 'b'
    cmp     x9, x10
    b.eq    unary_local
    mov     x10, #0x66                  // 'f'
    cmp     x9, x10
    b.eq    unary_local
unary_plain:
    bl      number
    cbnz    x3, bad_number
    mov     x1, #0
    b       unary_done
unary_local:
    sub     x2, x2, #1
    bl      digits
    add     x2, x2, #1
    cbnz    x3, unary_plain
    bl      local_ref
unary_def:                              // definition x0: defined before, in this pass?
    ldr     x9, [x0, #16]               // its pass
    cbz     x9, undefined               // none yet
    ldr     x10, [x19, #V_pass]
    cmp     x9, x10
    b.eq    unary_exact
    str     xzr, [x19, #V_exact]
unary_exact:
    ldr     x1, [x0, #8]                // its kind
    ldr     x0, [x0]                    // its value
    lsl     x9, x1, #3                  // plus its section's address
    add     x9, x9, x19
    ldr     x9, [x9, #V_base]
    add     x0, x0, x9
unary_done:
    ldr     x30, [sp]
    add     sp, sp, #16
    ret
undefined:                              // a name not yet defined: an error in pass 2
    ldr     x9, [x19, #V_emit]
    cbnz    x9, not_defined
    str     xzr, [x19, #V_exact]
    str     xzr, [x19, #V_known]
    mov     x0, #0
    mov     x1, #0
    b       unary_done

number:                                 // x0 = the number x1, x2: decimal, 0x hex, 0 octal; x3 = 1 if none (uses x9-x13)
    mov     x0, #0
    mov     x9, #0                      // the next digit
    mov     x11, #10                    // the base
    ldrb    w10, [x1]
    mov     x12, #0x30                  // '0'
    cmp     x10, x12
    b.ne    number_digits
    mov     x12, #1
    cmp     x2, x12
    b.eq    number_digits
    mov     x11, #8                     // 0...: octal
    mov     x9, #1
    ldrb    w10, [x1, #1]
    orr     x10, x10, #0x20
    mov     x12, #0x78                  // 0x...: hex
    cmp     x10, x12
    b.ne    number_digits
    mov     x11, #16
    mov     x9, #2
    mov     x12, #2
    cmp     x2, x12
    b.eq    number_bad
number_digits:
    cmp     x9, x2
    b.hs    number_done
    add     x10, x1, x9
    ldrb    w10, [x10]
    sub     x12, x10, #0x30             // '0'-'9'
    mov     x13, #10
    cmp     x12, x13
    b.lo    number_digit
    orr     x12, x10, #0x20             // 'a'-'f', 'A'-'F': 10-15
    sub     x12, x12, #0x57
    cmp     x12, x13
    b.lo    number_bad
number_digit:
    cmp     x12, x11                    // a digit of the base
    b.hs    number_bad
    mul     x0, x0, x11
    add     x0, x0, x12
    add     x9, x9, #1
    b       number_digits
number_done:
    mov     x3, #0
    ret
number_bad:
    mov     x3, #1
    ret

// Directives.

directive:                              // x1, x2: its name
    bl      pack
    la      x9, directives
directive_next:
    ldr     x10, [x9]
    cbz     x10, unknown_directive
    cmp     x10, x0
    b.eq    directive_found
    add     x9, x9, #16
    b       directive_next
directive_found:
    ldr     x10, [x9, #8]               // its routine, from directives
    la      x11, directives
    add     x10, x10, x11
    br      x10
unknown_directive:
    la      x0, msg_directive
    b       fail

d_globl:                                // .globl name: ld starts at _start anyway
    bl      blanks
    bl      word
    b       end_line

d_section:                              // .section name
    bl      blanks
    bl      word
    bl      pack
    la      x9, sections
    mov     x11, #1
d_section_next:
    ldr     x10, [x9]
    cmp     x10, x0
    b.eq    d_section_found
    add     x9, x9, #8
    add     x11, x11, #1
    mov     x10, #4
    cmp     x10, x11
    b.hs    d_section_next
    la      x0, msg_section
    b       fail
d_section_found:
    mov     x0, x11
    b       set_section
d_text:
    mov     x0, #1
    b       set_section
d_data:
    mov     x0, #3
    b       set_section
d_bss:
    mov     x0, #4
set_section:
    str     x0, [x19, #V_sec]
    b       end_line

d_equ:                                  // .equ name, expr
    bl      blanks
    bl      word
    mov     x27, x1
    mov     x28, x2
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x2c                  // ','
    cmp     x9, x10
    b.ne    bad_syntax
    add     x20, x20, #1
    bl      eval
    lsl     x9, x1, #3                  // kept in its section
    add     x9, x9, x19
    ldr     x9, [x9, #V_base]
    sub     x3, x0, x9
    mov     x4, x1
    mov     x1, x27
    mov     x2, x28
    mov     x5, #0                      // may be set again
    bl      define
    ldr     x9, [x19, #V_exact]         // not known here: never a number known here
    cbnz    x9, end_line
    str     xzr, [x0, #S_pass]
    b       end_line

d_balign:                               // .balign n: zeros up to a multiple of n
    bl      eval_number
    cbz     x0, bad_align
    sub     x9, x0, #1                  // a power of 2
    and     x10, x0, x9
    cbnz    x10, bad_align
    ldr     x11, [x19, #V_sec]
    mov     x10, #1                     // gas pads .text with nops: not done
    cmp     x11, x10
    b.eq    bad_align
    lsl     x11, x11, #3
    add     x11, x11, x19
    ldr     x10, [x11, #V_align]        // the section's alignment
    cmp     x10, x0
    b.hs    d_balign_pad
    str     x0, [x11, #V_align]
d_balign_pad:
    ldr     x10, [x11, #V_loc]
    neg     x12, x10
    and     x12, x12, x9                // (-loc) & (n - 1)
    add     x10, x10, x12               // zeros: the output is zero
    str     x10, [x11, #V_loc]
    b       end_line

d_skip:                                 // .skip n: n zeros
    bl      eval_number
    ldr     x11, [x19, #V_sec]
    lsl     x11, x11, #3
    add     x11, x11, x19
    ldr     x10, [x11, #V_loc]
    add     x10, x10, x0
    str     x10, [x11, #V_loc]
    b       end_line

d_byte:                                 // .byte expr, ...
    mov     x27, #1
    b       data
d_half:                                 // .half expr, ...
    mov     x27, #2
    b       data
d_word:                                 // .word expr, ...
    mov     x27, #4
    b       data
d_dword:                                // .dword expr, ...
    mov     x27, #8
data:
    bl      eval
    mov     x1, x27
    bl      emit_n
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x2c                  // ','
    cmp     x9, x10
    b.ne    end_line
    add     x20, x20, #1
    b       data

d_asciz:                                // .asciz "text", ...: each with a 0 after it
    mov     x27, #1
    b       ascii
d_ascii:                                // .ascii "text", ...
    mov     x27, #0
ascii:
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x22                  // '"'
    cmp     x9, x10
    b.ne    bad_syntax
    add     x20, x20, #1
ascii_byte:
    cmp     x20, x21
    b.hs    bad_string
    ldrb    w0, [x20]
    mov     x10, #0x0a                  // '\n'
    cmp     x0, x10
    b.eq    bad_string
    add     x20, x20, #1
    mov     x10, #0x22                  // '"'
    cmp     x0, x10
    b.eq    ascii_end
    mov     x10, #0x5c                  // '\'
    cmp     x0, x10
    b.ne    ascii_put
    ldrb    w0, [x20]
    add     x20, x20, #1
    mov     x10, #0x6e                  // \n
    cmp     x0, x10
    b.ne    ascii_not_n
    mov     x0, #0x0a
    b       ascii_put
ascii_not_n:
    mov     x10, #0x74                  // \t
    cmp     x0, x10
    b.ne    ascii_not_t
    mov     x0, #0x09
    b       ascii_put
ascii_not_t:
    sub     x11, x0, #0x30              // \ooo: up to 3 octal digits
    mov     x10, #8
    cmp     x11, x10                    // else the byte itself
    b.hs    ascii_put
    mov     x0, x11
    mov     x12, #2
ascii_octal:
    ldrb    w11, [x20]
    sub     x11, x11, #0x30
    cmp     x11, x10
    b.hs    ascii_put
    lsl     x0, x0, #3
    add     x0, x0, x11
    add     x20, x20, #1
    sub     x12, x12, #1
    cbnz    x12, ascii_octal
ascii_put:
    bl      emit_byte
    b       ascii_byte
ascii_end:
    cbz     x27, ascii_next
    mov     x0, #0
    bl      emit_byte
ascii_next:
    bl      blanks
    ldrb    w9, [x20]
    mov     x10, #0x2c                  // ','
    cmp     x9, x10
    b.ne    end_line
    add     x20, x20, #1
    b       ascii

// Output.

emit_byte:                              // the byte x0 at here, in pass 2; counted (uses x9-x11)
    ldr     x9, [x19, #V_sec]
    lsl     x10, x9, #3
    add     x10, x10, x19
    ldr     x11, [x19, #V_emit]
    cbz     x11, emit_byte_count
    mov     x11, #4                     // not in .bss
    cmp     x9, x11
    b.eq    in_bss
    ldr     x11, [x10, #V_off]
    ldr     x9, [x10, #V_loc]
    add     x11, x11, x9
    mov     x9, #OUTBUF
    add     x11, x11, x9
    mov     x9, #OUTBUF_END
    cmp     x11, x9
    b.hs    output_full
    strb    w0, [x11]
    ldr     x9, [x19, #V_sec]
emit_byte_count:
    ldr     x11, [x10, #V_loc]
    add     x11, x11, #1
    str     x11, [x10, #V_loc]
    ret

emit16:                                 // the 2 bytes of x0 (uses x0-x2, x9-x11, x15)
    mov     x1, #2
    b       emit_n
emit32:                                 // the 4 bytes of x0 (the same)
    mov     x1, #4
emit_n:                                 // x1 bytes of x0, the low one first
    mov     x15, x30
    mov     x2, x0
emit_n_byte:
    mov     x0, x2
    bl      emit_byte
    lsr     x2, x2, #8
    sub     x1, x1, #1
    cbnz    x1, emit_n_byte
    mov     x30, x15
    ret

// Macros.

d_macro:                                // .macro name param, ...: its lines up to .endm
    ldr     x27, [x19, #V_nmac]
    add     x9, x19, #MACROS - VARS
    add     x9, x9, #MAC_max * MAC_size
    cmp     x27, x9
    b.hs    too_many_macros
    bl      blanks
    bl      word
    cbz     x2, bad_syntax
    bl      pack
    str     x0, [x27, #MAC_name]
    mov     x28, #0                     // its parameters
d_macro_param:
    bl      blanks
    ldrb    w9, [x20]
    cmp     x9, #0x0a                   // '\n': the end of its line
    b.eq    d_macro_body
    cmp     x9, #0x2f                   // '//': a comment
    b.eq    d_macro_body
    cbz     x28, d_macro_name
    bl      p_comma
    bl      blanks
d_macro_name:
    bl      word
    cbz     x2, bad_syntax
    cmp     x28, #4
    b.hs    bad_syntax
    add     x9, x27, #MAC_params
    add     x9, x9, x28, lsl #4
    str     x1, [x9]
    str     x2, [x9, #8]
    add     x28, x28, #1
    b       d_macro_param
d_macro_body:
    str     x28, [x27, #MAC_n]
    bl      skip_line                   // its lines from the next one on
    str     x20, [x27, #MAC_body]
d_macro_line:
    cmp     x20, x21
    b.hs    bad_syntax                  // no .endm
    mov     x29, x20                    // the line's first byte
    bl      blanks
    bl      word
    bl      pack
    la      x9, str_endm
    ldr     x9, [x9]
    cmp     x0, x9
    b.eq    d_macro_end
    bl      skip_line
    ldr     x9, [x19, #V_line]
    add     x9, x9, #1
    str     x9, [x19, #V_line]
    b       d_macro_line
d_macro_end:
    str     x29, [x27, #MAC_end]
    add     x27, x27, #MAC_size
    str     x27, [x19, #V_nmac]
    b       end_line

d_endm:                                 // .endm without its .macro
    b       bad_syntax

skip_line:                              // x20 after the next newline (uses x9)
    cmp     x20, x21
    b.hs    skip_line_done
    ldrb    w9, [x20]
    add     x20, x20, #1
    cmp     x9, #0x0a
    b.ne    skip_line
skip_line_done:
    ret

expand:                                 // macro x27 called: its arguments, then its lines
    mov     x28, #0                     // the arguments
    ldr     x29, [x27, #MAC_n]
expand_arg:
    cmp     x28, x29
    b.hs    expand_lines
    cbz     x28, expand_first
    bl      p_comma
expand_first:
    bl      blanks
    mov     x1, x20                     // to a ',', a newline or '//'
expand_arg_byte:
    cmp     x20, x21
    b.hs    expand_arg_end
    ldrb    w9, [x20]
    cmp     x9, #0x2c
    b.eq    expand_arg_end
    cmp     x9, #0x0a
    b.eq    expand_arg_end
    cmp     x9, #0x2f
    b.eq    expand_arg_end
    add     x20, x20, #1
    b       expand_arg_byte
expand_arg_end:
    mov     x2, x20                     // without the blanks after it
expand_arg_trim:
    cmp     x2, x1
    b.eq    expand_arg_store
    ldrb    w9, [x2, #-1]
    cmp     x9, #0x20
    b.eq    expand_arg_back
    cmp     x9, #0x09
    b.ne    expand_arg_store
expand_arg_back:
    sub     x2, x2, #1
    b       expand_arg_trim
expand_arg_store:
    sub     x2, x2, x1
    add     x9, x19, #ARGS - VARS
    add     x9, x9, x28, lsl #4
    str     x1, [x9]
    str     x2, [x9, #8]
    add     x28, x28, #1
    b       expand_arg
expand_lines:
    sub     sp, sp, #48                 // what the lines' statements change
    ldr     x9, [x19, #V_sret]
    str     x9, [sp]
    ldr     x9, [x19, #V_lstart]
    str     x9, [sp, #8]
    str     x20, [sp, #16]              // the rest of the call's line
    str     x21, [sp, #24]
    str     x27, [sp, #32]              // the macro
    ldr     x9, [x27, #MAC_body]
    str     x9, [sp, #40]               // its next line
expand_line:
    ldr     x3, [sp, #40]
    ldr     x27, [sp, #32]
    ldr     x9, [x27, #MAC_end]
    cmp     x3, x9
    b.hs    expand_done
    li32    x4, EXPBUF                  // the line, \param as its argument
expand_byte:
    li32    x9, EXPBUF_END
    cmp     x4, x9
    b.hs    bad_syntax
    ldrb    w5, [x3]
    add     x3, x3, #1
    cmp     x5, #0x5c                   // '\'
    b.eq    expand_param
    strb    w5, [x4]
    add     x4, x4, #1
    cmp     x5, #0x0a
    b.ne    expand_byte
    str     x3, [sp, #40]
    li32    x20, EXPBUF
    mov     x21, x4
    str     x20, [x19, #V_lstart]
    bl      statement
    b       expand_line
expand_param:                           // \name: the argument of parameter name
    mov     x20, x3
    bl      word                        // x1, x2
    mov     x3, x20
    ldr     x27, [sp, #32]
    ldr     x6, [x27, #MAC_n]
    add     x7, x27, #MAC_params
    add     x8, x19, #ARGS - VARS
expand_find:
    cbz     x6, bad_syntax              // no such parameter
    ldr     x10, [x7, #8]
    cmp     x10, x2
    b.ne    expand_find_on
    ldr     x10, [x7]
    mov     x11, #0
expand_cmp:
    cmp     x11, x2
    b.eq    expand_found
    ldrb    w12, [x10, x11]
    ldrb    w13, [x1, x11]
    cmp     x12, x13
    b.ne    expand_find_on
    add     x11, x11, #1
    b       expand_cmp
expand_find_on:
    add     x7, x7, #16
    add     x8, x8, #16
    sub     x6, x6, #1
    b       expand_find
expand_found:                           // its argument's bytes
    ldr     x10, [x8]
    ldr     x11, [x8, #8]
expand_copy:
    cbz     x11, expand_byte
    li32    x9, EXPBUF_END
    cmp     x4, x9
    b.hs    bad_syntax
    ldrb    w12, [x10]
    strb    w12, [x4]
    add     x4, x4, #1
    add     x10, x10, #1
    sub     x11, x11, #1
    b       expand_copy
expand_done:
    ldr     x9, [sp]
    str     x9, [x19, #V_sret]
    ldr     x9, [sp, #8]
    str     x9, [x19, #V_lstart]
    ldr     x20, [sp, #16]
    ldr     x21, [sp, #24]
    add     sp, sp, #48
    b       end_line

// The instructions: the mnemonic's routine, with x22 its base bits and x23
// its other bits (from mnemonics). Pass 1 only counts its 4 bytes. Each
// ends with end_line.

insn:                                   // x1, x2: the mnemonic, or a macro's name
    bl      pack
    add     x27, x19, #MACROS - VARS
    ldr     x9, [x19, #V_nmac]
insn_macro:
    cmp     x27, x9
    b.hs    insn_table
    ldr     x10, [x27, #MAC_name]
    cmp     x10, x0
    b.eq    expand
    add     x27, x27, #MAC_size
    b       insn_macro
insn_table:
    la      x9, mnemonics
insn_next:
    ldr     x10, [x9]
    cbz     x10, unknown_mnemonic
    cmp     x10, x0
    b.eq    insn_found
    add     x9, x9, #24
    b       insn_next
insn_found:
    ldr     x10, [x19, #V_emit]
    cbz     x10, insn_count
    ldrsw   x10, [x9, #8]               // its routine, from mnemonics
    ldr     w22, [x9, #12]
    ldr     x23, [x9, #16]
    la      x11, mnemonics
    add     x10, x10, x11
    br      x10
insn_count:                             // pass 1: its 4 bytes, the rest of the line unread
    cmp     x20, x21
    b.hs    insn_counted
    ldrb    w9, [x20]
    cmp     x9, #0x0a
    b.eq    insn_counted
    add     x20, x20, #1
    b       insn_count
insn_counted:
    mov     x0, #0
    bl      emit32
    b       end_line

// The operands (pass 2).

p_reg:                                  // x0 = the register at x20, x1 its class: 0 x or xzr, 1 w or wzr, 2 sp (uses x2, x9-x11, x14)
    sub     sp, sp, #16
    str     x30, [sp]
    bl      blanks
    bl      word
    cbz     x2, bad_operand
    bl      pack
    la      x9, registers               // x0-x30 xzr sp, then w0-w30 wzr
    mov     x10, #0
p_reg_next:
    cmp     x10, #65
    b.eq    unknown_register
    ldr     x11, [x9]
    cmp     x11, x0
    b.eq    p_reg_found
    add     x9, x9, #8
    add     x10, x10, #1
    b       p_reg_next
p_reg_found:
    mov     x0, x10
    mov     x1, #0
    cmp     x10, #32
    b.lo    p_reg_done                  // x0-x30, xzr
    mov     x0, #31
    mov     x1, #2
    b.eq    p_reg_done                  // sp
    sub     x0, x10, #33                // w0-w30, wzr
    mov     x1, #1
p_reg_done:
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

p_comma:                                // a ',' (uses x9, x10, x12)
    mov     x12, x30
    bl      blanks
    mov     x30, x12
    ldrb    w9, [x20]
    mov     x10, #0x2c
    cmp     x9, x10
    b.ne    bad_syntax
    add     x20, x20, #1
    ret

p_byte:                                 // x0 = the next byte after blanks (uses x9, x10, x12)
    mov     x12, x30
    bl      blanks
    mov     x30, x12
    ldrb    w0, [x20]
    ret

p_expect:                               // the byte x0 after blanks (uses x9, x10, x12, x13)
    mov     x13, x0
    mov     x12, x30
    bl      blanks
    mov     x30, x12
    ldrb    w9, [x20]
    cmp     x9, x13
    b.ne    bad_operand
    add     x20, x20, #1
    ret

p_imm:                                  // x0 = #expr, a number
    sub     sp, sp, #16
    str     x30, [sp]
    mov     x0, #0x23                   // '#'
    bl      p_expect
    bl      eval
    cbnz    x1, not_number
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

p_addr:                                 // x0 = expr, an address (a label's, plus or minus a number), x1 its section
    sub     sp, sp, #16
    str     x30, [sp]
    bl      blanks
    bl      eval
    cbz     x1, bad_operand
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

p_rd:                                   // rd: x24, its class x27
    mov     x15, x30
    bl      p_reg
    mov     x24, x0
    mov     x27, x1
    mov     x30, x15
    ret

p_rn:                                   // , rn: x25, its class x28
    mov     x15, x30
    bl      p_comma
    bl      p_reg
    mov     x25, x0
    mov     x28, x1
    mov     x30, x15
    ret

p_rm:                                   // , rm: x26
    mov     x15, x30
    bl      p_comma
    bl      p_reg
    mov     x26, x0
    mov     x30, x15
    ret

sf:                                     // x22 |= sf, 1 << 31 unless class x27 is w (uses x9)
    and     x9, x27, #1
    eor     x9, x9, #1
    orr     x22, x22, x9, lsl #31
    ret

emit_rd:                                // x22 | rd, then end_line
    orr     x0, x22, x24
emit_end:                               // the instruction x0, then end_line
    bl      emit32
    b       end_line

emit_rn:                                // x22 | rn << 5 | rd, then end_line
    orr     x22, x22, x25, lsl #5
    b       emit_rd

emit_rm:                                // x22 | rm << 16 | rn << 5 | rd, then end_line
    orr     x22, x22, x26, lsl #16
    b       emit_rn

// The instructions' routines.

h_mov:                                  // mov rd, rm | mov rd, #n
    bl      p_rd
    bl      p_comma
    bl      p_byte
    cmp     x0, #0x23                   // '#'
    b.eq    h_mov_imm
    bl      p_reg
    mov     x25, x0
    orr     x9, x27, x1
    and     x9, x9, #2
    cbnz    x9, h_mov_sp
    mov     x26, x0                     // orr rd, zr, rm
    mov     x25, #31
    li32    x22, 0x2a000000
    bl      sf
    b       emit_rm
h_mov_sp:                               // with sp: add rd, rn, #0
    li32    x22, 0x91000000
    b       emit_rn
h_mov_imm:
    and     x9, x27, #3                 // x only
    cbnz    x9, bad_operand
    bl      p_imm
    mov     x26, x0
    li32    x22, 0xd2800000             // movz: n in one of its 16-bit parts
    bl      wide
    cbz     x1, h_mov_wide
    mvn     x26, x26                    // movn: ~n in one
    li32    x22, 0x92800000
    bl      wide
    cbz     x1, h_mov_wide
    mvn     x0, x26                     // orr rd, zr, #bitmask
    bl      bitmask
    cmn     x0, #1
    b.eq    out_of_range
    li32    x22, 0xb20003e0
    orr     x22, x22, x0, lsl #10
    b       emit_rd
h_mov_wide:                             // hw, imm16
    orr     x22, x22, x0
    b       emit_rd

wide:                                   // x0 = x26 as hw << 21 | imm16 << 5, x1 = 0; x1 = 1 if more than one part (uses x9, x10)
    mov     x10, #0                     // hw
wide_part:
    lsl     x9, x10, #4                 // its part's shift
    lsr     x0, x26, x9
    and     x0, x0, #0xffff
    lsl     x0, x0, x9
    cmp     x0, x26
    b.eq    wide_yes
    add     x10, x10, #1
    cmp     x10, #4
    b.ne    wide_part
    mov     x1, #1
    ret
wide_yes:
    lsr     x0, x26, x9
    lsl     x0, x0, #5
    orr     x0, x0, x10, lsl #21
    mov     x1, #0
    ret

bitmask:                                // x0 = n's bitmask immediate, N:immr:imms (13 bits), or -1 (uses x1, x9-x15)
    mov     x1, x0
    cbz     x1, bitmask_none
    cmn     x1, #1
    b.eq    bitmask_none
    mov     x9, #64                     // the element's size e: 64 32 ... 2
bitmask_size:
    movn    x10, #0                     // its mask
    cmp     x9, #64
    b.eq    bitmask_mask
    mov     x10, #1
    lsl     x10, x10, x9
    sub     x10, x10, #1
bitmask_mask:
    and     x11, x1, x10                // the element
    mov     x12, x11                    // repeated to 64 bits
    mov     x13, x9
bitmask_rep:
    cmp     x13, #64
    b.hs    bitmask_check
    lsl     x14, x12, x13
    orr     x12, x12, x14
    add     x13, x13, x13
    b       bitmask_rep
bitmask_check:
    cmp     x12, x1
    b.ne    bitmask_smaller
    mov     x13, #0                     // a rotation r that makes it ones from bit 0
bitmask_rot:
    lsl     x14, x11, x13
    sub     x15, x9, x13
    lsr     x15, x11, x15
    orr     x14, x14, x15
    and     x14, x14, x10
    add     x15, x14, #1
    tst     x14, x15
    b.eq    bitmask_found
    add     x13, x13, #1
    cmp     x13, x9
    b.ne    bitmask_rot
bitmask_smaller:
    lsr     x9, x9, #1
    cmp     x9, #2
    b.hs    bitmask_size
bitmask_none:
    movn    x0, #0
    ret
bitmask_found:                          // x14 = 2^k - 1: N, immr r, imms
    clz     x15, x14
    mov     x0, #64
    sub     x15, x0, x15                // k
    sub     x15, x15, #1                // imms: (~(e - 1) << 1) & 0x3f | (k - 1)
    sub     x0, x9, #1
    mvn     x0, x0
    lsl     x0, x0, #1
    and     x0, x0, #0x3f
    orr     x0, x0, x15
    orr     x0, x0, x13, lsl #6         // immr
    cmp     x9, #64
    b.ne    bitmask_n
    orr     x0, x0, #0x1000             // N for 64
bitmask_n:
    ret

h_cmp:                                  // cmp rn, op: subs zr, rn, op
    bl      p_reg
    mov     x25, x0
    mov     x28, x1
    mov     x27, x1
    mov     x24, #31
    b       h_addsub_op

h_neg:                                  // neg rd, rm: sub rd, zr, rm
    bl      p_rd
    bl      p_rm
    mov     x25, #31
    bl      sf
    b       emit_rm

h_addsub:                               // add sub adds subs rd, rn, op (x22 its op and S bits)
    bl      p_rd
    bl      p_rn
h_addsub_op:
    bl      p_comma
    bl      p_byte
    cmp     x0, #0x23                   // '#'
    b.eq    h_addsub_imm
    cmp     x0, #0x3a                   // ':lo12:'
    b.eq    h_addsub_lo12
    bl      p_reg
    mov     x26, x0
    bl      sf
    orr     x9, x27, x28                // with sp: extended register, uxtx
    and     x9, x9, #2
    cbnz    x9, h_addsub_ext
    li32    x9, 0x0b000000
    orr     x22, x22, x9
    b       emit_rm
h_addsub_ext:
    li32    x9, 0x0b206000
    orr     x22, x22, x9
    b       emit_rm
h_addsub_imm:
    bl      p_imm
    cmp     x0, #0                      // a negative one: the other way, as gas
    b.ge    h_addsub_pos
    neg     x0, x0
    eor     x22, x22, #0x40000000
h_addsub_pos:
    cmp     x0, #4096
    b.lo    h_addsub_12
    and     x9, x0, #0xfff              // else shifted by 12
    cbnz    x9, out_of_range
    lsr     x0, x0, #12
    cmp     x0, #4096
    b.hs    out_of_range
    orr     x22, x22, #0x400000         // sh
h_addsub_12:
    orr     x22, x22, x0, lsl #10
    li32    x9, 0x11000000
    orr     x22, x22, x9
    bl      sf
    b       emit_rn
h_addsub_lo12:
    add     x20, x20, #1
    la      x1, str_lo12                // "lo12:"
    mov     x2, #5
h_addsub_lo12_byte:
    ldrb    w9, [x20]
    ldrb    w10, [x1]
    cmp     x9, x10
    b.ne    bad_operand
    add     x20, x20, #1
    add     x1, x1, #1
    sub     x2, x2, #1
    cbnz    x2, h_addsub_lo12_byte
    bl      p_addr
    and     x0, x0, #0xfff
    b       h_addsub_12

h_logic:                                // and orr eor rd, rn, op (x22 its opc)
    bl      p_rd
    bl      p_rn
    bl      p_comma
    bl      p_byte
    cmp     x0, #0x23                   // '#'
    b.eq    h_logic_imm
    bl      p_reg
    mov     x26, x0
    li32    x9, 0x0a000000
    orr     x22, x22, x9
    bl      sf
    b       emit_rm
h_logic_imm:
    and     x9, x27, #3                 // x only
    cbnz    x9, bad_operand
    bl      p_imm
    bl      bitmask
    cmn     x0, #1
    b.eq    out_of_range
    orr     x22, x22, x0, lsl #10
    li32    x9, 0x92000000
    orr     x22, x22, x9
    b       emit_rn

h_shift:                                // lsl lsr asr rd, rn, op (x22 its register form, x23 0 lsl 1 lsr 2 asr)
    bl      p_rd
    bl      p_rn
    bl      p_comma
    bl      p_byte
    cmp     x0, #0x23                   // '#'
    b.eq    h_shift_imm
    bl      p_reg
    mov     x26, x0
    bl      sf
    b       emit_rm
h_shift_imm:                            // ubfm, sbfm: x only
    and     x9, x27, #3
    cbnz    x9, bad_operand
    bl      p_imm
    cmp     x0, #64
    b.hs    out_of_range
    li32    x22, 0xd340fc00             // ubfm rd, rn, #s, #63: lsr
    orr     x22, x22, x0, lsl #16
    cmp     x23, #1
    b.eq    emit_rn
    li32    x22, 0x9340fc00             // sbfm rd, rn, #s, #63: asr
    orr     x22, x22, x0, lsl #16
    cmp     x23, #2
    b.eq    emit_rn
    neg     x9, x0                      // ubfm rd, rn, #(-s mod 64), #(63 - s): lsl
    and     x9, x9, #63
    mov     x10, #63
    sub     x10, x10, x0
    li32    x22, 0xd3400000
    orr     x22, x22, x9, lsl #16
    orr     x22, x22, x10, lsl #10
    b       emit_rn

h_rrr:                                  // mul udiv sdiv rd, rn, rm (x22 its bits)
    bl      p_rd
    bl      p_rn
    bl      p_rm
    bl      sf
    b       emit_rm

h_msub:                                 // msub rd, rn, rm, ra
    bl      p_rd
    bl      p_rn
    bl      p_rm
    bl      p_comma
    bl      p_reg
    orr     x22, x22, x0, lsl #10
    bl      sf
    b       emit_rm

h_cset:                                 // cset rd, cond: csinc rd, zr, zr, !cond
    bl      p_rd
    bl      p_comma
    bl      blanks
    bl      word
    bl      pack
    la      x9, conds
    mov     x10, #0
h_cset_next:
    cmp     x10, #16
    b.eq    bad_operand
    ldr     x11, [x9]
    cmp     x11, x0
    b.eq    h_cset_found
    add     x9, x9, #8
    add     x10, x10, #1
    b       h_cset_next
h_cset_found:
    eor     x10, x10, #1
    orr     x22, x22, x10, lsl #12
    bl      sf
    b       emit_rd

h_ldst:                                 // ldr str ldrb strb rt, [rn{, #n}] (x22 the unsigned offset form, x23 the size's log2)
    bl      p_rd
    cmp     x23, #3                     // ldr, str of a w: 4 bytes
    b.ne    h_ldst_rt
    and     x9, x27, #1
    cbz     x9, h_ldst_rt
    eor     x22, x22, #0x40000000
    mov     x23, #2
h_ldst_rt:
    bl      p_comma
    mov     x0, #0x5b                   // '['
    bl      p_expect
    bl      p_reg
    mov     x25, x0
    and     x9, x1, #1                  // a base of 64 bits
    cbnz    x9, bad_operand
    mov     x26, #0
    bl      p_byte
    cmp     x0, #0x2c                   // ', #n'
    b.ne    h_ldst_end
    add     x20, x20, #1
    bl      p_imm
    mov     x26, x0
h_ldst_end:
    mov     x0, #0x5d                   // ']'
    bl      p_expect
    cmp     x26, #0                     // unsigned, scaled, 12 bits
    b.lt    h_ldst_unscaled
    lsr     x9, x26, x23
    lsl     x10, x9, x23
    cmp     x10, x26
    b.ne    h_ldst_unscaled
    cmp     x9, #4096
    b.hs    h_ldst_unscaled
    orr     x22, x22, x9, lsl #10
    b       emit_rn
h_ldst_unscaled:                        // ldur stur ldurb sturb: 9 bits, signed
    add     x9, x26, #256
    cmp     x9, #512
    b.hs    out_of_range
    and     w22, w22, #0xfeffffff
    and     x9, x26, #0x1ff
    orr     x22, x22, x9, lsl #12
    b       emit_rn

h_b:                                    // b bl label (x22 its bits)
    bl      p_text
    asr     x0, x0, #2
    mov     x1, #26
    bl      fits
    and     x0, x0, #0x3ffffff
    orr     x0, x0, x22
    b       emit_end

h_bcond:                                // b.cond label (x22 its bits)
    mov     x24, #0
h_bcond_target:
    bl      p_text
    asr     x0, x0, #2
    mov     x1, #19
    bl      fits
    and     x0, x0, #0x7ffff
    orr     x22, x22, x0, lsl #5
    b       emit_rd

h_cbz:                                  // cbz cbnz rt, label (x22 its bits)
    bl      p_rd
    bl      sf
    bl      p_comma
    b       h_bcond_target

p_text:                                 // x0 = a .text label minus here, a multiple of 4 (uses x1-x3, x9-x15)
    sub     sp, sp, #16
    str     x30, [sp]
    bl      p_addr
    cmp     x1, #1
    b.ne    bad_target
    mov     x3, x0
    bl      here
    sub     x0, x3, x0
    and     x9, x0, #3
    cbnz    x9, out_of_range
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

fits:                                   // value x0 fits in x1 bits, signed; else an error (uses x9, x10)
    mov     x9, #64
    sub     x9, x9, x1
    lsl     x10, x0, x9
    asr     x10, x10, x9
    cmp     x10, x0
    b.ne    out_of_range
    ret

h_adrp:                                 // adrp rd, label: its page minus here's
    bl      p_rd
    bl      p_comma
    bl      p_addr
    mov     x3, x0
    bl      here
    lsr     x0, x0, #12
    lsr     x3, x3, #12
    sub     x0, x3, x0
    mov     x1, #21
    bl      fits
    and     x9, x0, #3                  // immlo
    orr     x22, x22, x9, lsl #29
    lsr     x9, x0, #2                  // immhi
    and     x9, x9, #0x7ffff
    orr     x22, x22, x9, lsl #5
    b       emit_rd

h_ret:                                  // ret {rn}: x30 without one
    mov     x25, #30
    bl      p_byte
    cmp     x0, #0x0a
    b.eq    h_ret_emit
    cmp     x0, #0x2f
    b.eq    h_ret_emit
    bl      p_reg
    mov     x25, x0
h_ret_emit:
    mov     x24, #0
    b       emit_rn

h_br:                                   // br blr rn (x22 its bits)
    bl      p_reg
    mov     x25, x0
    mov     x24, #0
    b       emit_rn

h_svc:                                  // svc #n
    bl      p_imm
    lsr     x9, x0, #16
    cbnz    x9, out_of_range
    orr     x0, x22, x0, lsl #5
    b       emit_end

layout:                                 // every section's file offset and address, as ld places them
    mov     x15, x30
    mov     x0, #0xb0                   // after the ELF header and two program headers
    mov     x1, #1
    bl      place                       // .text
    mov     x1, #2
    bl      place                       // .rodata: the end of the code segment
    str     x0, [x19, #V_tend]
    mov     x9, #ADDR                   // its address v
    add     x3, x0, x9
    mov     x0, x3                      // ld's DATA_SEGMENT_ALIGN (0x10000, 0x1000):
    mov     x1, #0x10000                // v up to 64 KiB (x6), plus v's low 16 bits,
    bl      alignup
    mov     x6, x0
    and     x9, x3, #0xffff
    add     x5, x6, x9                  // the data segment's base (x5)
    mov     x0, x5
    bl      data_place                  // x0 = its end
    neg     x9, x5                      // a page saved, as lang_size_segment: the
    and     x9, x9, #0xfff              // bytes before the base's next 4 KiB page,
    and     x10, x0, #0xfff             // the bytes after the end's last one, both
    cbz     x9, layout_files            // there, the two in other pages, and no
    cbz     x10, layout_files           // more than a page together: from v up to
    lsr     x11, x5, #12                // 4 KiB in the 64 KiB after v's instead
    lsr     x12, x0, #12
    cmp     x11, x12
    b.eq    layout_files
    add     x9, x9, x10
    cmp     x9, #0x1000
    b.hi    layout_files
    add     x9, x3, #0xfff
    and     x9, x9, #0xf000
    add     x0, x6, x9
    bl      data_place
layout_files:                           // .data's file offset: from the code's end,
    ldr     x9, [x19, #V_base+24]       // the same as its address in 64 KiB
    ldr     x10, [x19, #V_tend]
    sub     x11, x9, x10
    and     x11, x11, #0xffff
    add     x0, x10, x11
    str     x0, [x19, #V_off+24]
    ldr     x9, [x19, #V_loc+24]        // .bss's file offset, and .shstrtab's: the end
    add     x0, x0, x9                  // of .data (ld's, though .bss be aligned)
    str     x0, [x19, #V_off+32]
    str     x0, [x19, #V_shstr]
    add     x0, x0, #SHSTRTAB_len       // then the section headers
    mov     x1, #8
    bl      alignup
    str     x0, [x19, #V_shoff]
    add     x0, x0, #6 * 64
    str     x0, [x19, #V_fend]
    mov     x9, #OUTBUF_END - OUTBUF
    cmp     x9, x0
    b.lo    output_full
    mov     x30, x15
    ret

data_place:                             // .data, then .bss from address x0; x0 = the end, as ld's script (uses x1, x9, x14)
    mov     x14, x30
    ldr     x1, [x19, #V_align+24]
    bl      alignup
    str     x0, [x19, #V_base+24]       // .data
    ldr     x9, [x19, #V_loc+24]
    add     x0, x0, x9
    ldr     x1, [x19, #V_align+32]
    bl      alignup
    str     x0, [x19, #V_base+32]       // .bss
    ldr     x9, [x19, #V_loc+32]        // its end at a multiple of 8
    add     x0, x0, x9
    mov     x1, #8
    bl      alignup
    mov     x30, x14
    ret

place:                                  // section x1 from file offset x0, aligned; x0 = its end (uses x1, x2, x9)
    lsl     x2, x1, #3
    add     x2, x2, x19
    ldr     x1, [x2, #V_align]
    mov     x9, x30
    bl      alignup
    mov     x30, x9
    str     x0, [x2, #V_off]
    mov     x9, #ADDR
    add     x9, x9, x0
    str     x9, [x2, #V_base]
    ldr     x9, [x2, #V_loc]
    add     x0, x0, x9
    ret

alignup:                                // x0 up to a multiple of x1, a power of 2 (uses x1)
    sub     x1, x1, #1
    add     x0, x0, x1
    mvn     x1, x1
    and     x0, x0, x1
    ret

headers:                                // the ELF header, the program headers, .shstrtab, the section headers
    sub     sp, sp, #16
    str     x30, [sp]
    add     x9, x19, #V_loc+8           // each section has bytes
    add     x10, x19, #V_loc+40
headers_bytes:
    ldr     x11, [x9]
    cbz     x11, empty_section
    add     x9, x9, #8
    cmp     x9, x10
    b.ne    headers_bytes
    ldr     x0, [x19, #V_base+32]       // ld's script ends .bss at a multiple of 8
    ldr     x9, [x19, #V_loc+32]        // (its address)
    add     x0, x0, x9
    mov     x1, #8
    bl      alignup
    ldr     x9, [x19, #V_base+32]
    sub     x0, x0, x9
    str     x0, [x19, #V_loc+32]
    mov     x0, #OUTBUF
    la      x1, elf_headers
    mov     x2, #0xb0
    bl      copy
    la      x1, str_start               // e_entry: _start
    mov     x2, #6
    bl      find_sym
    cbz     x0, no_start
    ldr     x9, [x0, #S_pass]
    cbz     x9, no_start
    ldr     x9, [x0, #S_kind]
    lsl     x9, x9, #3
    add     x9, x9, x19
    ldr     x9, [x9, #V_base]
    ldr     x10, [x0, #S_value]
    add     x10, x10, x9
    mov     x0, #OUTBUF
    str     x10, [x0, #24]
    ldr     x9, [x19, #V_shoff]         // e_shoff
    str     x9, [x0, #40]
    ldr     x9, [x19, #V_tend]          // the code: p_filesz, p_memsz
    str     x9, [x0, #96]
    str     x9, [x0, #104]
    ldr     x9, [x19, #V_off+24]        // the data: p_offset
    str     x9, [x0, #128]
    ldr     x9, [x19, #V_base+24]       // p_vaddr, p_paddr
    str     x9, [x0, #136]
    str     x9, [x0, #144]
    ldr     x9, [x19, #V_loc+24]        // p_filesz: .data
    str     x9, [x0, #152]
    ldr     x9, [x19, #V_base+32]       // p_memsz: to the end of .bss
    ldr     x10, [x19, #V_loc+32]
    add     x9, x9, x10
    ldr     x10, [x19, #V_base+24]
    sub     x9, x9, x10
    str     x9, [x0, #160]
    ldr     x0, [x19, #V_shstr]         // .shstrtab
    mov     x9, #OUTBUF
    add     x0, x0, x9
    la      x1, shstrtab
    mov     x2, #SHSTRTAB_len
    bl      copy
    ldr     x0, [x19, #V_shoff]         // the section headers
    mov     x9, #OUTBUF
    add     x0, x0, x9
    mov     x3, x0
    la      x1, section_headers
    mov     x2, #6 * 64
    bl      copy
    mov     x1, #1
headers_section:                        // 1-4: .text .rodata .data .bss
    add     x3, x3, #64
    lsl     x2, x1, #3
    add     x2, x2, x19
    ldr     x9, [x2, #V_base]           // sh_addr
    str     x9, [x3, #16]
    ldr     x9, [x2, #V_off]            // sh_offset
    str     x9, [x3, #24]
    ldr     x9, [x2, #V_loc]            // sh_size
    str     x9, [x3, #32]
    ldr     x9, [x2, #V_align]          // sh_addralign
    str     x9, [x3, #48]
    add     x1, x1, #1
    mov     x9, #5
    cmp     x1, x9
    b.ne    headers_section
    ldr     x9, [x19, #V_shstr]         // 5: .shstrtab's sh_offset
    str     x9, [x3, #88]
    ldr     x30, [sp]
    add     sp, sp, #16
    ret

copy:                                   // x2 bytes from x1 to x0 (uses x0-x2, x9)
    cbz     x2, copy_done
    ldrb    w9, [x1]
    strb    w9, [x0]
    add     x0, x0, #1
    add     x1, x1, #1
    sub     x2, x2, #1
    b       copy
copy_done:
    ret

// The errors: asm: line N: what: the line.

junk:
    la      x0, msg_junk
    b       fail
twice:
    la      x0, msg_twice
    b       fail
too_many_symbols:
    la      x0, msg_symbols
    b       fail
too_many_macros:
    la      x0, msg_macros
    b       fail
bad_local:
    la      x0, msg_local
    b       fail
not_number:
    la      x0, msg_not_number
    b       fail
bad_number:
    la      x0, msg_number
    b       fail
bad_expr:
    la      x0, msg_expr
    b       fail
not_defined:
    la      x0, msg_undefined
    b       fail
bad_syntax:
    la      x0, msg_syntax
    b       fail
bad_align:
    la      x0, msg_align
    b       fail
bad_string:
    la      x0, msg_string
    b       fail
unknown_mnemonic:
    la      x0, msg_mnemonic
    b       fail
unknown_register:
    la      x0, msg_register
    b       fail
bad_operand:
    la      x0, msg_operand
    b       fail
out_of_range:
    la      x0, msg_range
    b       fail
bad_target:
    la      x0, msg_target
    b       fail
in_bss:
    la      x0, msg_bss
fail:                                   // message x0 (a C string) about the line
    mov     x27, x0
    la      x1, msg_line
    bl      eputs
    ldr     x0, [x19, #V_line]
    bl      eputn
    la      x1, msg_colon
    bl      eputs
    mov     x1, x27
    bl      eputs
    la      x1, msg_colon
    bl      eputs
    ldr     x1, [x19, #V_lstart]        // the line, to its newline
    mov     x2, x1
fail_line:
    cmp     x2, x21
    b.hs    fail_line_end
    ldrb    w9, [x2]
    mov     x10, #0x0a
    cmp     x9, x10
    b.eq    fail_line_end
    add     x2, x2, #1
    b       fail_line
fail_line_end:
    sub     x2, x2, x1
    bl      ewrite
    la      x1, msg_newline
    bl      eputs
    mov     x0, #1
    b       exit
output_full:
    la      x0, msg_full
    b       die
empty_section:
    la      x0, msg_empty
    b       die
no_start:
    la      x0, msg_start
    b       die
too_large:
    la      x0, msg_large
    b       die
read_failed:
    la      x0, msg_read
    b       die
write_failed:
    la      x0, msg_write
die:                                    // asm: message x0
    mov     x27, x0
    la      x1, msg_asm
    bl      eputs
    mov     x1, x27
    bl      eputs
    la      x1, msg_newline
    bl      eputs
    mov     x0, #1                      // status 1
exit:
    mov     x8, #SYS_exit
    svc     #0

eputs:                                  // writes the C string x1 to stderr
    mov     x2, x1
eputs_len:
    ldrb    w9, [x2]
    cbz     x9, eputs_end
    add     x2, x2, #1
    b       eputs_len
eputs_end:
    sub     x2, x2, x1
ewrite:                                 // writes x1, x2 to stderr
    mov     x8, #SYS_write
    mov     x0, #2                      // fd 2, stderr
    svc     #0
    ret

eputn:                                  // writes x0 in decimal to stderr
    add     x1, x19, #NUMBUF + 24       // the last digit first, from the end
    mov     x2, x1
    mov     x10, #10
eputn_digit:
    udiv    x16, x0, x10
    msub    x9, x16, x10, x0
    add     x9, x9, #0x30
    sub     x1, x1, #1
    strb    w9, [x1]
    udiv    x0, x0, x10
    cbnz    x0, eputn_digit
    sub     x2, x2, x1
    b       ewrite

// The tables, 8-byte aligned: names as 8 bytes, the first lowest, 0 after
// the name; a routine as its offset from its table.
    .balign 8
directives:                             // name, its routine
    .ascii ".ascii\0\0"
    .dword d_ascii - directives
    .ascii ".asciz\0\0"
    .dword d_asciz - directives
    .ascii ".balign\0"
    .dword d_balign - directives
    .ascii ".byte\0\0\0"
    .dword d_byte - directives
    .ascii ".hword\0\0"
    .dword d_half - directives
    .ascii ".word\0\0\0"
    .dword d_word - directives
    .ascii ".dword\0\0"
    .dword d_dword - directives
    .ascii ".equ\0\0\0\0"
    .dword d_equ - directives
    .ascii ".globl\0\0"
    .dword d_globl - directives
    .ascii ".section"
    .dword d_section - directives
    .ascii ".skip\0\0\0"
    .dword d_skip - directives
    .ascii ".text\0\0\0"
    .dword d_text - directives
    .ascii ".data\0\0\0"
    .dword d_data - directives
    .ascii ".bss\0\0\0\0"
    .dword d_bss - directives
    .ascii ".macro\0\0"
    .dword d_macro - directives
    .ascii ".endm\0\0\0"
    .dword d_endm - directives
    .dword 0

sections:                               // 1-4
    .ascii ".text\0\0\0"
    .ascii ".rodata\0"
    .ascii ".data\0\0\0"
    .ascii ".bss\0\0\0\0"

registers:                              // x0-x30 xzr sp, then w0-w30 wzr
    .ascii "x0\0\0\0\0\0\0", "x1\0\0\0\0\0\0", "x2\0\0\0\0\0\0", "x3\0\0\0\0\0\0"
    .ascii "x4\0\0\0\0\0\0", "x5\0\0\0\0\0\0", "x6\0\0\0\0\0\0", "x7\0\0\0\0\0\0"
    .ascii "x8\0\0\0\0\0\0", "x9\0\0\0\0\0\0", "x10\0\0\0\0\0", "x11\0\0\0\0\0"
    .ascii "x12\0\0\0\0\0", "x13\0\0\0\0\0", "x14\0\0\0\0\0", "x15\0\0\0\0\0"
    .ascii "x16\0\0\0\0\0", "x17\0\0\0\0\0", "x18\0\0\0\0\0", "x19\0\0\0\0\0"
    .ascii "x20\0\0\0\0\0", "x21\0\0\0\0\0", "x22\0\0\0\0\0", "x23\0\0\0\0\0"
    .ascii "x24\0\0\0\0\0", "x25\0\0\0\0\0", "x26\0\0\0\0\0", "x27\0\0\0\0\0"
    .ascii "x28\0\0\0\0\0", "x29\0\0\0\0\0", "x30\0\0\0\0\0", "xzr\0\0\0\0\0"
    .ascii "sp\0\0\0\0\0\0", "w0\0\0\0\0\0\0", "w1\0\0\0\0\0\0", "w2\0\0\0\0\0\0"
    .ascii "w3\0\0\0\0\0\0", "w4\0\0\0\0\0\0", "w5\0\0\0\0\0\0", "w6\0\0\0\0\0\0"
    .ascii "w7\0\0\0\0\0\0", "w8\0\0\0\0\0\0", "w9\0\0\0\0\0\0", "w10\0\0\0\0\0"
    .ascii "w11\0\0\0\0\0", "w12\0\0\0\0\0", "w13\0\0\0\0\0", "w14\0\0\0\0\0"
    .ascii "w15\0\0\0\0\0", "w16\0\0\0\0\0", "w17\0\0\0\0\0", "w18\0\0\0\0\0"
    .ascii "w19\0\0\0\0\0", "w20\0\0\0\0\0", "w21\0\0\0\0\0", "w22\0\0\0\0\0"
    .ascii "w23\0\0\0\0\0", "w24\0\0\0\0\0", "w25\0\0\0\0\0", "w26\0\0\0\0\0"
    .ascii "w27\0\0\0\0\0", "w28\0\0\0\0\0", "w29\0\0\0\0\0", "w30\0\0\0\0\0"
    .ascii "wzr\0\0\0\0\0"

conds:                                  // 0-15, the conditions
    .ascii "eq\0\0\0\0\0\0", "ne\0\0\0\0\0\0", "hs\0\0\0\0\0\0", "lo\0\0\0\0\0\0"
    .ascii "mi\0\0\0\0\0\0", "pl\0\0\0\0\0\0", "vs\0\0\0\0\0\0", "vc\0\0\0\0\0\0"
    .ascii "hi\0\0\0\0\0\0", "ls\0\0\0\0\0\0", "ge\0\0\0\0\0\0", "lt\0\0\0\0\0\0"
    .ascii "gt\0\0\0\0\0\0", "le\0\0\0\0\0\0", "al\0\0\0\0\0\0", "nv\0\0\0\0\0\0"

mnemonics:                              // name, its routine, its base bits, its other bits
    .ascii "mov\0\0\0\0\0"
    .word   h_mov - mnemonics, 0x00000000
    .dword  0
    .ascii "add\0\0\0\0\0"
    .word   h_addsub - mnemonics, 0x00000000
    .dword  0
    .ascii "sub\0\0\0\0\0"
    .word   h_addsub - mnemonics, 0x40000000
    .dword  0
    .ascii "adds\0\0\0\0"
    .word   h_addsub - mnemonics, 0x20000000
    .dword  0
    .ascii "subs\0\0\0\0"
    .word   h_addsub - mnemonics, 0x60000000
    .dword  0
    .ascii "cmp\0\0\0\0\0"
    .word   h_cmp - mnemonics, 0x60000000
    .dword  0
    .ascii "neg\0\0\0\0\0"
    .word   h_neg - mnemonics, 0x4b000000
    .dword  0
    .ascii "and\0\0\0\0\0"
    .word   h_logic - mnemonics, 0x00000000
    .dword  0
    .ascii "orr\0\0\0\0\0"
    .word   h_logic - mnemonics, 0x20000000
    .dword  0
    .ascii "eor\0\0\0\0\0"
    .word   h_logic - mnemonics, 0x40000000
    .dword  0
    .ascii "lsl\0\0\0\0\0"
    .word   h_shift - mnemonics, 0x1ac02000
    .dword  0
    .ascii "lsr\0\0\0\0\0"
    .word   h_shift - mnemonics, 0x1ac02400
    .dword  1
    .ascii "asr\0\0\0\0\0"
    .word   h_shift - mnemonics, 0x1ac02800
    .dword  2
    .ascii "mul\0\0\0\0\0"
    .word   h_rrr - mnemonics, 0x1b007c00
    .dword  0
    .ascii "udiv\0\0\0\0"
    .word   h_rrr - mnemonics, 0x1ac00800
    .dword  0
    .ascii "sdiv\0\0\0\0"
    .word   h_rrr - mnemonics, 0x1ac00c00
    .dword  0
    .ascii "msub\0\0\0\0"
    .word   h_msub - mnemonics, 0x1b008000
    .dword  0
    .ascii "cset\0\0\0\0"
    .word   h_cset - mnemonics, 0x1a9f07e0
    .dword  0
    .ascii "ldr\0\0\0\0\0"
    .word   h_ldst - mnemonics, 0xf9400000
    .dword  3
    .ascii "str\0\0\0\0\0"
    .word   h_ldst - mnemonics, 0xf9000000
    .dword  3
    .ascii "ldrb\0\0\0\0"
    .word   h_ldst - mnemonics, 0x39400000
    .dword  0
    .ascii "strb\0\0\0\0"
    .word   h_ldst - mnemonics, 0x39000000
    .dword  0
    .ascii "b\0\0\0\0\0\0\0"
    .word   h_b - mnemonics, 0x14000000
    .dword  0
    .ascii "bl\0\0\0\0\0\0"
    .word   h_b - mnemonics, 0x94000000
    .dword  0
    .ascii "b.eq\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000000
    .dword  0
    .ascii "b.ne\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000001
    .dword  0
    .ascii "b.hs\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000002
    .dword  0
    .ascii "b.lo\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000003
    .dword  0
    .ascii "b.mi\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000004
    .dword  0
    .ascii "b.pl\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000005
    .dword  0
    .ascii "b.vs\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000006
    .dword  0
    .ascii "b.vc\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000007
    .dword  0
    .ascii "b.hi\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000008
    .dword  0
    .ascii "b.ls\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000009
    .dword  0
    .ascii "b.ge\0\0\0\0"
    .word   h_bcond - mnemonics, 0x5400000a
    .dword  0
    .ascii "b.lt\0\0\0\0"
    .word   h_bcond - mnemonics, 0x5400000b
    .dword  0
    .ascii "b.gt\0\0\0\0"
    .word   h_bcond - mnemonics, 0x5400000c
    .dword  0
    .ascii "b.le\0\0\0\0"
    .word   h_bcond - mnemonics, 0x5400000d
    .dword  0
    .ascii "b.al\0\0\0\0"
    .word   h_bcond - mnemonics, 0x5400000e
    .dword  0
    .ascii "b.nv\0\0\0\0"
    .word   h_bcond - mnemonics, 0x5400000f
    .dword  0
    .ascii "b.cs\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000002
    .dword  0
    .ascii "b.cc\0\0\0\0"
    .word   h_bcond - mnemonics, 0x54000003
    .dword  0
    .ascii "cbz\0\0\0\0\0"
    .word   h_cbz - mnemonics, 0x34000000
    .dword  0
    .ascii "cbnz\0\0\0\0"
    .word   h_cbz - mnemonics, 0x35000000
    .dword  0
    .ascii "ret\0\0\0\0\0"
    .word   h_ret - mnemonics, 0xd65f0000
    .dword  0
    .ascii "br\0\0\0\0\0\0"
    .word   h_br - mnemonics, 0xd61f0000
    .dword  0
    .ascii "blr\0\0\0\0\0"
    .word   h_br - mnemonics, 0xd63f0000
    .dword  0
    .ascii "svc\0\0\0\0\0"
    .word   h_svc - mnemonics, 0xd4000001
    .dword  0
    .ascii "adrp\0\0\0\0"
    .word   h_adrp - mnemonics, 0x90000000
    .dword  0
    .dword  0
elf_headers:                            // ld's: the ELF header and the two program headers, 0xb0 bytes
    .byte   0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0    // e_ident: 0x7f "ELF", 64-bit, little endian, version 1, System V
    .byte   0, 0, 0, 0, 0, 0, 0, 0              // padding
    .hword  2                           // e_type: ET_EXEC
    .hword  0xb7                        // e_machine: EM_AARCH64
    .word   1                           // e_version
    .dword  0                           // e_entry: _start (headers)
    .dword  0x40                        // e_phoff: the program headers follow
    .dword  0                           // e_shoff: the section headers (headers)
    .word   0                           // e_flags: none on aarch64
    .hword  0x40                        // e_ehsize
    .hword  0x38                        // e_phentsize
    .hword  2                           // e_phnum
    .hword  0x40                        // e_shentsize
    .hword  6                           // e_shnum: 0 .text .rodata .data .bss .shstrtab
    .hword  5                           // e_shstrndx: .shstrtab
    .word   1                           // p_type: PT_LOAD, the code
    .word   5                           // p_flags: R X
    .dword  0                           // p_offset: from the file's first byte
    .dword  ADDR                        // p_vaddr
    .dword  ADDR                        // p_paddr
    .dword  0                           // p_filesz: to the end of .rodata (headers)
    .dword  0                           // p_memsz: the same (headers)
    .dword  0x10000                     // p_align: 64 KiB
    .word   1                           // p_type: PT_LOAD, the data
    .word   6                           // p_flags: R W
    .dword  0                           // p_offset: .data's (headers)
    .dword  0                           // p_vaddr: .data's address (headers)
    .dword  0                           // p_paddr: the same (headers)
    .dword  0                           // p_filesz: .data (headers)
    .dword  0                           // p_memsz: to the end of .bss (headers)
    .dword  0x10000                     // p_align: 64 KiB

section_headers:                        // the six, without what headers fills in
    .dword  0, 0, 0, 0, 0, 0, 0, 0      // 0: none
    .word   0x0b, 1                     // 1: .text: its name, SHT_PROGBITS
    .dword  6, 0, 0, 0                  // SHF_ALLOC | SHF_EXECINSTR; addr, offset, size
    .word   0, 0                        // sh_link, sh_info
    .dword  0, 0                        // sh_addralign, sh_entsize
    .word   0x11, 1                     // 2: .rodata, SHT_PROGBITS
    .dword  2, 0, 0, 0                  // SHF_ALLOC
    .word   0, 0
    .dword  0, 0
    .word   0x19, 1                     // 3: .data, SHT_PROGBITS
    .dword  3, 0, 0, 0                  // SHF_WRITE | SHF_ALLOC
    .word   0, 0
    .dword  0, 0
    .word   0x1f, 8                     // 4: .bss, SHT_NOBITS
    .dword  3, 0, 0, 0                  // SHF_WRITE | SHF_ALLOC
    .word   0, 0
    .dword  0, 0
    .word   0x01, 3                     // 5: .shstrtab, SHT_STRTAB
    .dword  0, 0, 0, shstrtab_end - shstrtab  // no flags, address; offset; size
    .word   0, 0
    .dword  1, 0                        // sh_addralign 1

shstrtab:                               // the section names, as ld orders them
    .ascii  "\0.shstrtab\0.text\0.rodata\0.data\0.bss\0"
shstrtab_end:

    .balign 8
str_endm:       .ascii ".endm\0\0\0"
str_lo12:       .ascii "lo12:"
str_start:      .ascii "_start"
msg_asm:        .asciz "asm: "
msg_line:       .asciz "asm: line "
msg_colon:      .asciz ": "
msg_newline:    .asciz "\n"
msg_junk:       .asciz "junk at the end of the line"
msg_twice:      .asciz "label defined twice"
msg_symbols:    .asciz "too many symbols"
msg_macros:     .asciz "too many macros"
msg_local:      .asciz "bad local label"
msg_not_number: .asciz "not a number known here"
msg_number:     .asciz "bad number"
msg_expr:       .asciz "bad expression"
msg_kinds:      .asciz "not a number or a label plus a number"
msg_undefined:  .asciz "undefined name"
msg_syntax:     .asciz "syntax error"
msg_align:      .asciz "bad .balign"
msg_string:     .asciz "bad string"
msg_directive:  .asciz "unknown directive"
msg_section:    .asciz "unknown section"
msg_mnemonic:   .asciz "unknown mnemonic"
msg_register:   .asciz "unknown register"
msg_operand:    .asciz "bad operand"
msg_range:      .asciz "out of range"
msg_target:     .asciz "a branch to another section"
msg_bss:        .asciz "bytes in .bss"
msg_full:       .asciz "output too large"
msg_empty:      .asciz ".text, .rodata, .data and .bss each need bytes"
msg_start:      .asciz "no _start"
msg_large:      .asciz "input too large"
msg_read:       .asciz "read failed"
msg_write:      .asciz "write failed"
end:
