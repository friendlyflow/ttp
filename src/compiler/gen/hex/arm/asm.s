@ asm for arm Linux (EABI): the assembler of the seed. The fourth link of
@ the bootstrap, built by M1 and hex2 from hosts/arm/asm.M1 (made from this
@ file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
@ It assembles hosts/arm/ttpc.s, the readable seed, into the seed: the
@ bytes binutils' as -march=armv7-a and ld -static -s -T hosts/arm/ttpc.ld
@ make of it, with no binutils. Its generic part (lines, symbols,
@ expressions, directives, macros, the output) follows
@ gen/hex/aarch64/asm.s routine by routine, in 32 bits; its instructions
@ are ARM's own (ARM state, ARMv7-A).
@
@   asm < ttpc.s > ttpc
@
@ The asm it reads: arm GNU syntax (unified) as ttpc.s uses it.
@   lines      labels (name: and the local n: of 0-99, as 1b and 1f), then
@              a directive, an instruction or a macro's name; '@' starts a
@              comment to the end of the line
@   directives .equ name, expr  .word .hword .byte expr, ...  .ascii
@              .asciz "text", ...  (escapes \n \t \ooo, \x as x)  .skip n
@              .balign n (not in .text)  .section name (.text .rodata
@              .data .bss)  .text .data .bss  .globl name  .syntax .arch
@              .arm (read as the Makefile's as -march=armv7-a)  .macro name
@              param, ... (its lines up to .endm; \param in them is the
@              call's argument)
@   exprs      numbers (decimal, 0x hex, 0 octal), names, '.' (here), and
@              as gas: unary - ~, then * / % << >>, then | & ^, then + -,
@              and ( ); a label's address plus or minus a number, or two
@              labels of a section minus each other
@   operands   registers (r0-r15, sp lr pc ip fp), #expr, #:lower16:expr
@              #:upper16:expr, a shifted register (rm, lsl|lsr|asr|ror #n
@              or rs), [rn], [rn, #expr] (! written back), [rn], #expr,
@              [rn, rm{, shift #n}], {register list, r4-r11}, the label of a
@              branch
@   mnemonics  and eor sub rsb add adc sbc rsc orr bic (s), mov mvn (s),
@              tst teq cmp cmn, lsl lsr asr ror, movw movt, mul mla umull,
@              ldr ldrb str strb, ldrd strd, push pop, b bl bx blx svc;
@              each with a condition after it (eq ne cs hs cc lo mi pl vs
@              vc hi ls ge lt gt le al)
@ An immediate is gas's: 8 bits rotated by the fewest even bits, else the
@ other instruction of the pair (add sub, cmp cmn negated; mov mvn, and
@ bic, adc sbc inverted), else for mov of 0-0xffff movw. push and pop of
@ one register are gas's str and ldr. Every instruction is 4 bytes, so the
@ passes need no relaxing (and there is no literal pool). The output is
@ the file ld makes with ttpc.ld: the ELF header, two program headers
@ (the code: the headers, .text, .rodata; the data: .data, .bss, on the
@ next page at the same offset in it), the sections, .ARM.attributes (as
@ gas writes it for armv7-a), .shstrtab and seven section headers. Each
@ of .text .rodata .data .bss must have bytes.
@
@ The input is read whole, then in two passes. Pass 1 sizes: every label
@ gets its section and place (an instruction is 4 bytes, its operands
@ unread); layout then gives every section its place. Pass 2 encodes and
@ writes the sections into the output, which is then written whole. On
@ an error it says so on stderr with the line (asm: line N: what: the
@ line) and ends with status 1; else with 0.
@
@ One flat file, loaded at BASE by its first program header, read and
@ run; the second maps the memory it writes, VARS to the end of OUTBUF.
@ The registers:
@   r9   VARS, the variables          r10  the next byte of the input
@   r11  the end of the input
@   r4   the instruction being built (its base bits and condition, from
@        mnemonics), r5 its other bits, r6-r8 scratch of the instructions
@   r7   the system call's number (where one is made)
@ The routines take and give r0-r3 and use r12 (each says which, and what
@ else it keeps on the stack); those that call another keep lr on the
@ stack. The expressions keep r4-r8 (their left sides on the stack). A
@ symbol is 20 bytes (S_*), a local label's definition 12 (L_*), a macro
@ 64 (MAC_*). A definition (D) is a symbol's S_value or a local label's
@ L_value: its value, kind (0 a number, 1-4 the section) and pass (0 not
@ defined) at 0, 4, 8.

    .syntax unified
    .arch armv7-a
    .arm
    .equ BASE, 0x10000
    .equ VARS, 0x100000                 @ the variables, 64 KiB
    .equ MACROS, VARS + 0x2000          @ 16 macros
    .equ MAC_max, 16
    .equ ARGS, VARS + 0x3000            @ a macro call's arguments
    .equ EXPBUF, VARS + 0x4000          @ a macro's line, expanded
    .equ EXPBUF_END, VARS + 0x5000
    .equ SYMS, VARS + 0x10000           @ 65536 symbols
    .equ SYM_size, 20
    .equ SYMS_END, SYMS + 0x10000 * SYM_size
    .equ LOCAL_max, 4096                @ definitions of each local label
    .equ LOCALS, SYMS_END               @ 100 local labels
    .equ LOCALS_END, LOCALS + 100 * LOCAL_max * 12
    .equ INPUT, LOCALS_END              @ 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTBUF, INPUT_END              @ 16 MiB of output
    .equ OUTBUF_END, OUTBUF + 0x1000000
    .equ ADDR, 0x10000                  @ where ld places the output (ttpc.ld)
    .equ HDRS, 52 + 2 * 32              @ the ELF header and program headers
    .equ ATTR_len, 29                   @ .ARM.attributes' bytes
    .equ SHSTRTAB_len, 52               @ the section names' bytes (.shstrtab)
    .equ SHDRS, 7 * 40                  @ the section headers
    .equ SYS_read, 3
    .equ SYS_write, 4
    .equ SYS_exit, 1

    @ a symbol: its name in the input, then its definition
    .equ S_name, 0
    .equ S_len, 4
    .equ S_value, 8
    .equ S_kind, 12
    .equ S_pass, 16
    @ a definition of a local label
    .equ L_value, 0
    .equ L_kind, 4
    .equ L_pass, 8
    @ a macro: its name (8 bytes), its parameters' count, then each
    @ parameter's name and length, its lines' first byte and their end
    .equ MAC_name, 0
    .equ MAC_n, 8
    .equ MAC_params, 12
    .equ MAC_body, 48
    .equ MAC_end, 52
    .equ MAC_size, 64

    @ the variables, at r9
    .equ V_pass, 0                      @ the pass, 1 or 2
    .equ V_emit, 4                      @ 1 in pass 2, which writes
    .equ V_sec, 8                       @ the section: 1 .text 2 .rodata 3 .data 4 .bss
    .equ V_line, 12                     @ the line's number
    .equ V_nmac, 16                     @ the next free macro
    .equ V_nsym, 20                     @ the next free symbol
    .equ V_exact, 24                    @ 0 once an expression used a name not defined before it
    .equ V_known, 28                    @ 0 once it used a name not defined at all
    .equ V_lstart, 32                   @ the line's first byte
    .equ V_loc, 40                      @ section s's location counter at V_loc + 4 * s
    .equ V_align, 60                    @ its alignment
    .equ V_base, 80                     @ its address (0 for s = 0, a number)
    .equ V_off, 100                     @ its file offset
    .equ V_attr, 120                    @ the file offset of .ARM.attributes
    .equ V_shstr, 124                   @ of .shstrtab
    .equ V_shoff, 128                   @ of the section headers
    .equ V_fend, 132                    @ the file's size
    .equ V_tend, 136                    @ the end of .rodata in the file: of the code segment
    .equ V_sret, 140                    @ statement's return address
    .equ COUNTS, 400                    @ local label n's definitions so far at COUNTS + 4 * n
    .equ NUMBUF, 800                    @ a decimal number, 12

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
    .word VARS                          @ p_vaddr: the variables, ..., the output
    .word VARS                          @ p_paddr: the same
    .word 0                             @ p_filesz: none, all zero
    .word OUTBUF_END - VARS             @ p_memsz: to the end of the output
    .word 6                             @ p_flags: PF_R | PF_W, read and write
    .word 0x1000                        @ p_align: a page

_start:                                 @ read all of stdin into INPUT
    mov     r9, #VARS
    mov     r11, #INPUT                 @ the end of what is read
read:
    mov     r2, #INPUT_END              @ a 0 stays after the input
    sub     r2, r2, #1
    subs    r2, r2, r11                 @ the room left
    beq     too_large
    mov     r7, #SYS_read
    mov     r0, #0                      @ fd 0, stdin
    mov     r1, r11                     @ after what is read
    svc     #0
    cmp     r0, #0
    blt     read_failed
    beq     read_all                    @ the end of stdin
    add     r11, r11, r0
    b       read
read_all:
    mov     r0, #SYMS                   @ no symbols yet
    str     r0, [r9, #V_nsym]
    mov     r0, #4                      @ .text aligned to 4 (gas's, for ARM code)
    str     r0, [r9, #V_align+4]
    mov     r0, #1                      @ the others to 1, until .balign
    str     r0, [r9, #V_align+8]
    str     r0, [r9, #V_align+12]
    str     r0, [r9, #V_align+16]
    str     r0, [r9, #V_pass]           @ pass 1: sizes and labels
    bl      pass
    bl      layout
    mov     r0, #2                      @ pass 2 writes
    str     r0, [r9, #V_pass]
    mov     r0, #1
    str     r0, [r9, #V_emit]
    bl      pass
    bl      headers
    mov     r1, #OUTBUF                 @ write the output
    ldr     r3, [r9, #V_fend]
    add     r3, r3, r1                  @ its end
write:
    subs    r2, r3, r1                  @ what is left
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

@ A pass over the input, line by line.
pass:
    push    {r4, lr}
    mov     r0, #0                      @ every section from 0
    str     r0, [r9, #V_loc]
    str     r0, [r9, #V_loc+4]
    str     r0, [r9, #V_loc+8]
    str     r0, [r9, #V_loc+12]
    str     r0, [r9, #V_loc+16]
    add     r1, r9, #MACROS - VARS      @ no macros yet
    str     r1, [r9, #V_nmac]
    add     r1, r9, #COUNTS             @ no local labels yet
    add     r2, r9, #COUNTS + 400
pass_count:
    str     r0, [r1], #4
    cmp     r1, r2
    bne     pass_count
    mov     r0, #1                      @ in .text
    str     r0, [r9, #V_sec]
    str     r0, [r9, #V_line]
    mov     r10, #INPUT
pass_line:
    cmp     r10, r11
    bhs     pass_end
    str     r10, [r9, #V_lstart]
    bl      statement
    ldr     r0, [r9, #V_line]
    add     r0, r0, #1
    str     r0, [r9, #V_line]
    b       pass_line
pass_end:
    pop     {r4, pc}

@ One line, to after its newline: labels, then a directive or an
@ instruction (each ends with end_line, which returns from statement).
statement:
    str     lr, [r9, #V_sret]
statement_next:
    bl      blanks
    mov     r0, r12
    bl      is_ident
    cmp     r0, #0
    beq     end_line                    @ no name: only a comment may follow
    bl      word                        @ r1, r2
    ldrb    r0, [r10]
    cmp     r0, #0x3a                   @ ':': a label
    beq     label
    ldrb    r0, [r1]
    cmp     r0, #0x2e                   @ '.': a directive
    beq     directive
    b       insn
label:
    add     r10, r10, #1
    bl      define_label
    b       statement_next

end_line:                               @ nothing but a comment until the newline, then after it
    bl      blanks
    cmp     r10, r11
    bhs     end_line_done
    cmp     r12, #0x40                  @ '@': a comment
    beq     end_comment
    cmp     r12, #0x0a                  @ '\n'
    bne     junk
    add     r10, r10, #1
end_line_done:
    ldr     lr, [r9, #V_sret]
    bx      lr
end_comment:
    add     r10, r10, #1
    cmp     r10, r11
    bhs     end_line_done
    ldrb    r12, [r10]
    cmp     r12, #0x0a
    bne     end_comment
    add     r10, r10, #1
    b       end_line_done

blanks:                                 @ skips spaces and tabs; r12 = the byte after them
    ldrb    r12, [r10]
    cmp     r12, #0x20                  @ ' '
    cmpne   r12, #0x09                  @ '\t'
    bxne    lr
    add     r10, r10, #1
    b       blanks

is_ident:                               @ r0 = 1 if byte r0 is a letter, a digit, '_' or '.', else 0 (uses r12)
    cmp     r0, #0x2e                   @ '.'
    cmpne   r0, #0x5f                   @ '_'
    beq     ident_yes
    sub     r12, r0, #0x30              @ '0'-'9'
    cmp     r12, #10
    blo     ident_yes
    orr     r12, r0, #0x20              @ 'A'-'Z' as 'a'-'z'
    sub     r12, r12, #0x61
    cmp     r12, #26
    blo     ident_yes
    mov     r0, #0
    bx      lr
ident_yes:
    mov     r0, #1
    bx      lr

word:                                   @ r1, r2 = the name at r10, which moves after it (uses r0, r12)
    push    {lr}
    mov     r1, r10
word_byte:
    ldrb    r0, [r10]
    bl      is_ident
    cmp     r0, #0
    addne   r10, r10, #1
    bne     word_byte
    sub     r2, r10, r1
    pop     {pc}

pack:                                   @ r0, r3 = name r1, r2 as 8 bytes (the first lowest), -1 if longer (uses r12)
    mvn     r0, #0
    mvn     r3, #0
    cmp     r2, #8
    bxhi    lr
    push    {r4, r5}
    mov     r0, #0
    mov     r3, #0
    mov     r12, #0
pack_byte:
    cmp     r12, r2
    beq     pack_done
    ldrb    r4, [r1, r12]
    and     r5, r12, #3                 @ its place in its word
    lsl     r5, r5, #3
    cmp     r12, #4
    orrlo   r0, r0, r4, lsl r5
    orrhs   r3, r3, r4, lsl r5
    add     r12, r12, #1
    b       pack_byte
pack_done:
    pop     {r4, r5}
    bx      lr

@ The symbols.

define_label:                           @ name r1, r2: here
    push    {lr}
    bl      digits                      @ n: a local label
    cmp     r3, #0
    beq     define_label_local
    bl      here_def                    @ r0, r3
    mov     r12, #1                     @ defined twice in a pass: an error
    bl      define
    pop     {pc}
define_label_local:
    bl      local_def
    pop     {pc}

here_def:                               @ r3 = here's value, r0 its kind
    ldr     r0, [r9, #V_sec]
    add     r3, r9, r0, lsl #2
    ldr     r3, [r3, #V_loc]            @ the section's location
    bx      lr

define:                                 @ r0 = symbol r1, r2, defined as r3 of kind r0 (r12 = 1: an error if defined in this pass; uses r3, r12)
    push    {r4, r5, r6, lr}
    mov     r4, r0
    mov     r5, r12
    mov     r6, r3
    bl      find_sym
    cmp     r0, #0
    bne     define_found
    bl      sym_new
    b       define_set
define_found:
    cmp     r5, #0
    beq     define_set
    ldr     r3, [r0, #S_pass]
    ldr     r12, [r9, #V_pass]
    cmp     r3, r12
    beq     twice
define_set:
    str     r6, [r0, #S_value]
    str     r4, [r0, #S_kind]
    ldr     r3, [r9, #V_pass]
    str     r3, [r0, #S_pass]
    pop     {r4, r5, r6, pc}

sym_new:                                @ r0 = a new symbol r1, r2, not yet defined (uses r3)
    ldr     r0, [r9, #V_nsym]
    mov     r3, #SYMS_END
    cmp     r0, r3
    bhs     too_many_symbols
    add     r3, r0, #SYM_size
    str     r3, [r9, #V_nsym]
    str     r1, [r0, #S_name]
    str     r2, [r0, #S_len]
    bx      lr

find_sym:                               @ r0 = symbol r1, r2, or 0 (uses r3, r12)
    push    {r4, r5, r6, lr}
    mov     r0, #SYMS
    ldr     r6, [r9, #V_nsym]
find_sym_next:
    cmp     r0, r6
    movhs   r0, #0
    pophs   {r4, r5, r6, pc}
    ldr     r3, [r0, #S_len]            @ the same length
    cmp     r3, r2
    bne     find_sym_on
    ldr     r3, [r0, #S_name]           @ and the same bytes
    mov     r12, #0
find_sym_byte:
    cmp     r12, r2
    popeq   {r4, r5, r6, pc}
    ldrb    r4, [r3, r12]
    ldrb    r5, [r1, r12]
    cmp     r4, r5
    bne     find_sym_on
    add     r12, r12, #1
    b       find_sym_byte
find_sym_on:
    add     r0, r0, #SYM_size
    b       find_sym_next

local_def:                              @ local label r0: here (uses r1, r3, r12)
    push    {lr}
    cmp     r0, #100
    bhs     bad_local
    add     r12, r9, r0, lsl #2         @ its definitions so far: this one's number
    ldr     r1, [r12, #COUNTS]
    add     r3, r1, #1
    str     r3, [r12, #COUNTS]
    bl      local_entry
    mov     r12, r0
    bl      here_def
    str     r3, [r12, #L_value]
    str     r0, [r12, #L_kind]
    ldr     r3, [r9, #V_pass]
    str     r3, [r12, #L_pass]
    pop     {pc}

local_entry:                            @ r0 = definition r1 of local label r0 (uses r3)
    cmp     r0, #100
    bhs     bad_local
    cmp     r1, #LOCAL_max              @ (-1 too: below 0)
    bhs     bad_local
    mov     r3, #LOCAL_max
    mla     r0, r3, r0, r1
    add     r0, r0, r0, lsl #1          @ 12 bytes each
    lsl     r0, r0, #2
    add     r0, r0, #LOCALS
    bx      lr

local_ref:                              @ r0 = the definition nf or nb of local label r0, by the last byte of r1, r2 (uses r1, r3, r12)
    cmp     r0, #100
    bhs     bad_local
    add     r12, r9, r0, lsl #2         @ nf: the next definition of n
    ldr     r3, [r12, #COUNTS]
    add     r12, r1, r2
    ldrb    r12, [r12, #-1]
    cmp     r12, #0x66                  @ 'f'
    subne   r3, r3, #1                  @ nb: the last one
    mov     r1, r3
    b       local_entry

digits:                                 @ r0 = name r1, r2 when it is decimal digits only, r3 = 0; else r3 = 1 (uses r12)
    mov     r0, #0
    mov     r3, #0
digits_next:
    cmp     r3, r2
    movhs   r3, #0
    bxhs    lr
    ldrb    r12, [r1, r3]
    sub     r12, r12, #0x30             @ '0'-'9'
    cmp     r12, #10
    movhs   r3, #1
    bxhs    lr
    add     r0, r0, r0, lsl #2          @ times 10, plus the digit
    add     r0, r12, r0, lsl #1
    add     r3, r3, #1
    b       digits_next

here:                                   @ r0 = the address of the next byte, r1 its section (uses r12)
    ldr     r1, [r9, #V_sec]
    add     r12, r9, r1, lsl #2
    ldr     r0, [r12, #V_loc]
    ldr     r12, [r12, #V_base]
    add     r0, r0, r12
    bx      lr

@ Expressions: r0 the value (with its section's address in pass 2), r1
@ the kind; V_exact and V_known cleared as it says. Each level keeps its
@ left side in r4, r5 and its operator in r6, which it keeps on the
@ stack (uses r2, r3, r12).

eval:                                   @ the expression at r10
    mov     r0, #1
    str     r0, [r9, #V_exact]
    str     r0, [r9, #V_known]
    b       expr

eval_number:                            @ r0 = the expression at r10: a number known here
    push    {lr}
    bl      eval
    cmp     r1, #0
    bne     not_number
    ldr     r1, [r9, #V_exact]
    cmp     r1, #0
    beq     not_number
    pop     {pc}

expr:                                   @ + -
    push    {r4, r5, r6, lr}
    bl      expr_or
expr_more:
    bl      blanks
    cmp     r12, #0x2b                  @ '+'
    beq     expr_add
    cmp     r12, #0x2d                  @ '-'
    beq     expr_sub
    pop     {r4, r5, r6, pc}
expr_add:
    add     r10, r10, #1
    mov     r4, r0                      @ the left one's value
    mov     r5, r1                      @ its kind
    bl      expr_or
    add     r0, r0, r4
    cmp     r5, #0
    beq     expr_more                   @ a number + x: x's kind
    cmp     r1, #0
    bne     expr_kinds                  @ a label + a number: the label's
    mov     r1, r5
    b       expr_more
expr_sub:
    add     r10, r10, #1
    mov     r4, r0
    mov     r5, r1
    bl      expr_or
    sub     r0, r4, r0
    cmp     r1, #0                      @ x - a number: x's kind
    moveq   r1, r5
    beq     expr_more
    cmp     r1, r5                      @ two labels of a section: a number
    bne     expr_kinds
    mov     r1, #0
    b       expr_more
expr_kinds:
    bl      kinds
    b       expr_more

kinds:                                  @ an operation on labels it cannot do: fine while names are unknown (uses r12)
    mov     r1, #0
    ldr     r12, [r9, #V_known]
    cmp     r12, #0
    bxeq    lr
    la      r0, msg_kinds
    b       fail

expr_or:                                @ | & ^
    push    {r4, r5, r6, lr}
    bl      expr_mul
expr_or_more:
    bl      blanks
    cmp     r12, #0x7c                  @ '|'
    cmpne   r12, #0x26                  @ '&'
    cmpne   r12, #0x5e                  @ '^'
    popne   {r4, r5, r6, pc}
    add     r10, r10, #1
    mov     r6, r12                     @ the operator
    mov     r4, r0
    mov     r5, r1
    bl      expr_mul
    orrs    r5, r5, r1                  @ numbers only
    blne    kinds
    mov     r1, #0
    cmp     r6, #0x7c                   @ '|'
    orreq   r0, r4, r0
    cmp     r6, #0x26                   @ '&'
    andeq   r0, r4, r0
    cmp     r6, #0x5e                   @ '^'
    eoreq   r0, r4, r0
    b       expr_or_more

expr_mul:                               @ * / % << >>
    push    {r4, r5, r6, lr}
    bl      expr_unary
expr_mul_more:
    bl      blanks
    cmp     r12, #0x2a                  @ '*'
    cmpne   r12, #0x2f                  @ '/'
    cmpne   r12, #0x25                  @ '%'
    beq     expr_mul_op
    cmp     r12, #0x3c                  @ '<' of '<<'
    cmpne   r12, #0x3e                  @ '>' of '>>'
    popne   {r4, r5, r6, pc}
    ldrb    r3, [r10, #1]               @ doubled
    cmp     r3, r12
    popne   {r4, r5, r6, pc}
    add     r10, r10, #1
expr_mul_op:
    add     r10, r10, #1
    mov     r6, r12                     @ the operator
    mov     r4, r0
    mov     r5, r1
    bl      expr_unary
    orrs    r5, r5, r1                  @ numbers only
    blne    kinds
    mov     r1, #0
    cmp     r6, #0x2a                   @ '*'
    muleq   r0, r4, r0
    beq     expr_mul_more
    cmp     r6, #0x3c                   @ '<<'
    lsleq   r0, r4, r0
    beq     expr_mul_more
    cmp     r6, #0x3e                   @ '>>': arithmetic, as gas
    asreq   r0, r4, r0
    beq     expr_mul_more
    cmp     r0, #0                      @ '/' '%' by 0: fine while names are unknown
    beq     expr_by_zero
    mov     r1, r0
    mov     r0, r4
    bl      sdivmod                     @ signed, as gas
    cmp     r6, #0x25                   @ '%': the remainder
    moveq   r0, r1
    mov     r1, #0
    b       expr_mul_more
expr_by_zero:
    ldr     r12, [r9, #V_known]
    cmp     r12, #0
    bne     bad_expr
    b       expr_mul_more

sdivmod:                                @ r0 = r0 / r1, r1 = r0 % r1, signed, to 0 as C; r1 not 0 (uses r2, r3, r12)
    push    {r4, lr}
    eor     r4, r0, r1                  @ the quotient's sign
    mov     r12, r0                     @ the remainder's: the dividend's
    cmp     r0, #0
    rsblt   r0, r0, #0
    cmp     r1, #0
    rsblt   r1, r1, #0
    mov     r2, #0                      @ the remainder
    mov     r3, #32                     @ a bit of the quotient at a time
sdivmod_bit:
    lsls    r0, r0, #1                  @ the dividend's next bit into the remainder
    adc     r2, r2, r2
    cmp     r2, r1
    subhs   r2, r2, r1
    orrhs   r0, r0, #1                  @ and the quotient's into r0
    subs    r3, r3, #1
    bne     sdivmod_bit
    cmp     r4, #0
    rsblt   r0, r0, #0
    mov     r1, r2
    cmp     r12, #0
    rsblt   r1, r1, #0
    pop     {r4, pc}

expr_unary:                             @ - ~ ( ), a number, a name, '.'
    push    {lr}
    bl      blanks
    cmp     r12, #0x2d                  @ '-'
    beq     unary_neg
    cmp     r12, #0x7e                  @ '~'
    beq     unary_not
    cmp     r12, #0x28                  @ '('
    beq     unary_paren
    mov     r0, r12
    bl      is_ident
    cmp     r0, #0
    beq     bad_expr
    bl      word
    ldrb    r0, [r1]
    sub     r0, r0, #0x30               @ '0'-'9': a number
    cmp     r0, #10
    blo     unary_number
    cmp     r2, #1                      @ '.': here
    bne     unary_symbol
    ldrb    r0, [r1]
    cmp     r0, #0x2e
    bne     unary_symbol
    bl      here
    pop     {pc}
unary_neg:
    add     r10, r10, #1
    bl      expr_unary
    rsb     r0, r0, #0
    b       unary_number_only
unary_not:
    add     r10, r10, #1
    bl      expr_unary
    mvn     r0, r0
unary_number_only:
    cmp     r1, #0
    blne    kinds
    pop     {pc}
unary_paren:
    add     r10, r10, #1
    bl      expr
    bl      blanks
    cmp     r12, #0x29                  @ ')'
    bne     bad_expr
    add     r10, r10, #1
    pop     {pc}
unary_symbol:
    bl      find_sym
    cmp     r0, #0
    beq     undefined
    add     r0, r0, #S_value            @ its definition
    b       unary_def
unary_number:                           @ digits, then b or f: a local label's
    add     r3, r1, r2
    ldrb    r3, [r3, #-1]
    cmp     r3, #0x62                   @ 'b'
    cmpne   r3, #0x66                   @ 'f'
    beq     unary_local
unary_plain:
    bl      number
    cmp     r3, #0
    bne     bad_number
    mov     r1, #0
    pop     {pc}
unary_local:
    sub     r2, r2, #1
    bl      digits
    add     r2, r2, #1
    cmp     r3, #0
    bne     unary_plain
    bl      local_ref
unary_def:                              @ definition r0: defined before, in this pass?
    ldr     r3, [r0, #8]                @ its pass
    cmp     r3, #0
    beq     undefined                   @ none yet
    ldr     r12, [r9, #V_pass]
    cmp     r3, r12
    movne   r3, #0
    strne   r3, [r9, #V_exact]
    ldr     r1, [r0, #4]                @ its kind
    ldr     r0, [r0]                    @ its value
    add     r12, r9, r1, lsl #2         @ plus its section's address
    ldr     r12, [r12, #V_base]
    add     r0, r0, r12
    pop     {pc}
undefined:                              @ a name not yet defined: an error in pass 2
    ldr     r12, [r9, #V_emit]
    cmp     r12, #0
    bne     not_defined
    mov     r0, #0
    str     r0, [r9, #V_exact]
    str     r0, [r9, #V_known]
    mov     r1, #0
    pop     {pc}

number:                                 @ r0 = the number r1, r2: decimal, 0x hex, 0 octal; r3 = 1 if none (uses r12)
    push    {r4, r5}
    mov     r0, #0
    mov     r3, #0                      @ the next digit
    mov     r4, #10                     @ the base
    ldrb    r12, [r1]
    cmp     r12, #0x30                  @ '0'
    bne     number_digits
    cmp     r2, #1
    beq     number_digits
    mov     r4, #8                      @ 0...: octal
    mov     r3, #1
    ldrb    r12, [r1, #1]
    orr     r12, r12, #0x20
    cmp     r12, #0x78                  @ 0x...: hex
    bne     number_digits
    mov     r4, #16
    mov     r3, #2
    cmp     r2, #2
    beq     number_bad
number_digits:
    cmp     r3, r2
    bhs     number_done
    ldrb    r12, [r1, r3]
    sub     r5, r12, #0x30              @ '0'-'9'
    cmp     r5, #10
    blo     number_digit
    orr     r5, r12, #0x20              @ 'a'-'f', 'A'-'F': 10-15
    sub     r5, r5, #0x57
    cmp     r5, #10
    blo     number_bad
number_digit:
    cmp     r5, r4                      @ a digit of the base
    bhs     number_bad
    mla     r0, r4, r0, r5
    add     r3, r3, #1
    b       number_digits
number_done:
    mov     r3, #0
    pop     {r4, r5}
    bx      lr
number_bad:
    mov     r3, #1
    pop     {r4, r5}
    bx      lr

@ Directives.

directive:                              @ r1, r2: its name
    bl      pack
    la      r12, directives
directive_next:
    ldr     r1, [r12]
    cmp     r1, #0
    beq     unknown_directive
    ldr     r2, [r12, #4]
    cmp     r1, r0
    cmpeq   r2, r3
    beq     directive_found
    add     r12, r12, #12
    b       directive_next
directive_found:
    ldr     r1, [r12, #8]               @ its routine, from directives
    la      r2, directives
    add     r1, r1, r2
    bx      r1
unknown_directive:
    la      r0, msg_directive
    b       fail

d_globl:                                @ .globl name: ld starts at _start anyway
    bl      blanks
    bl      word
    b       end_line

d_ignore:                               @ .syntax unified, .arch armv7-a, .arm: as -march=armv7-a
    ldrb    r12, [r10]
    cmp     r12, #0x0a                  @ the rest of the line, to a comment
    cmpne   r12, #0x40
    beq     end_line
    cmp     r10, r11
    bhs     end_line
    add     r10, r10, #1
    b       d_ignore

d_section:                              @ .section name
    bl      blanks
    bl      word
    bl      pack
    la      r12, sections
    mov     r1, #1
d_section_next:
    ldr     r2, [r12], #4
    cmp     r2, r0
    ldr     r2, [r12], #4
    cmpeq   r2, r3
    moveq   r0, r1
    beq     set_section
    add     r1, r1, #1
    cmp     r1, #4
    bls     d_section_next
    la      r0, msg_section
    b       fail
d_text:
    mov     r0, #1
    b       set_section
d_data:
    mov     r0, #3
    b       set_section
d_bss:
    mov     r0, #4
set_section:
    str     r0, [r9, #V_sec]
    b       end_line

d_equ:                                  @ .equ name, expr
    bl      blanks
    bl      word
    mov     r4, r1
    mov     r5, r2
    bl      blanks
    cmp     r12, #0x2c                  @ ','
    bne     bad_syntax
    add     r10, r10, #1
    bl      eval
    add     r12, r9, r1, lsl #2         @ kept in its section
    ldr     r12, [r12, #V_base]
    sub     r3, r0, r12
    mov     r0, r1
    mov     r1, r4
    mov     r2, r5
    mov     r12, #0                     @ may be set again
    bl      define
    ldr     r12, [r9, #V_exact]         @ not known here: never a number known here
    cmp     r12, #0
    streq   r12, [r0, #S_pass]
    b       end_line

d_balign:                               @ .balign n: zeros up to a multiple of n
    bl      eval_number
    cmp     r0, #0
    beq     bad_align
    sub     r3, r0, #1                  @ a power of 2
    tst     r0, r3
    bne     bad_align
    ldr     r1, [r9, #V_sec]
    cmp     r1, #1                      @ gas pads .text with nops: not done
    beq     bad_align
    add     r1, r9, r1, lsl #2
    ldr     r2, [r1, #V_align]          @ the section's alignment
    cmp     r2, r0
    strlo   r0, [r1, #V_align]
    ldr     r2, [r1, #V_loc]
    rsb     r12, r2, #0
    and     r12, r12, r3                @ (-loc) & (n - 1)
    add     r2, r2, r12                 @ zeros: the output is zero
    str     r2, [r1, #V_loc]
    b       end_line

d_skip:                                 @ .skip n: n zeros
    bl      eval_number
    ldr     r1, [r9, #V_sec]
    add     r1, r9, r1, lsl #2
    ldr     r2, [r1, #V_loc]
    add     r2, r2, r0
    str     r2, [r1, #V_loc]
    b       end_line

d_byte:                                 @ .byte expr, ...
    mov     r4, #1
    b       data
d_hword:                                @ .hword expr, ...
    mov     r4, #2
    b       data
d_word:                                 @ .word expr, ...
    mov     r4, #4
data:
    bl      eval
    mov     r1, r4
    bl      emit_n
    bl      blanks
    cmp     r12, #0x2c                  @ ','
    bne     end_line
    add     r10, r10, #1
    b       data

d_asciz:                                @ .asciz "text", ...: each with a 0 after it
    mov     r4, #1
    b       ascii
d_ascii:                                @ .ascii "text", ...
    mov     r4, #0
ascii:
    bl      blanks
    cmp     r12, #0x22                  @ '"'
    bne     bad_syntax
    add     r10, r10, #1
ascii_byte:
    cmp     r10, r11
    bhs     bad_string
    ldrb    r0, [r10]
    cmp     r0, #0x0a                   @ '\n'
    beq     bad_string
    add     r10, r10, #1
    cmp     r0, #0x22                   @ '"'
    beq     ascii_end
    cmp     r0, #0x5c                   @ '\'
    bne     ascii_put
    ldrb    r0, [r10]
    add     r10, r10, #1
    cmp     r0, #0x6e                   @ \n
    moveq   r0, #0x0a
    beq     ascii_put
    cmp     r0, #0x74                   @ \t
    moveq   r0, #0x09
    beq     ascii_put
    sub     r1, r0, #0x30               @ \ooo: up to 3 octal digits
    cmp     r1, #8                      @ else the byte itself
    bhs     ascii_put
    mov     r0, r1
    mov     r2, #2
ascii_octal:
    ldrb    r1, [r10]
    sub     r1, r1, #0x30
    cmp     r1, #8
    bhs     ascii_put
    add     r0, r1, r0, lsl #3
    add     r10, r10, #1
    subs    r2, r2, #1
    bne     ascii_octal
ascii_put:
    bl      emit_byte
    b       ascii_byte
ascii_end:
    cmp     r4, #0
    movne   r0, #0
    blne    emit_byte
    bl      blanks
    cmp     r12, #0x2c                  @ ','
    bne     end_line
    add     r10, r10, #1
    b       ascii

@ Output.

emit_byte:                              @ the byte r0 at here, in pass 2; counted (uses r3, r12)
    ldr     r3, [r9, #V_sec]
    add     r12, r9, r3, lsl #2         @ the section's variables
    ldr     r3, [r12, #V_loc]
    add     r3, r3, #1
    str     r3, [r12, #V_loc]
    ldr     r3, [r9, #V_emit]
    cmp     r3, #0
    bxeq    lr
    ldr     r3, [r9, #V_sec]
    cmp     r3, #4                      @ not in .bss
    beq     in_bss
    ldr     r3, [r12, #V_loc]           @ at its file offset, before the count
    ldr     r12, [r12, #V_off]
    add     r3, r3, r12
    sub     r3, r3, #1
    add     r3, r3, #OUTBUF
    cmp     r3, #OUTBUF_END
    bhs     output_full
    strb    r0, [r3]
    bx      lr

emit32:                                 @ the 4 bytes of r0 (uses r0-r3, r12)
    mov     r1, #4
emit_n:                                 @ r1 bytes of r0, the low one first
    push    {lr}
    mov     r2, r0
emit_n_byte:
    mov     r0, r2
    bl      emit_byte
    lsr     r2, r2, #8
    subs    r1, r1, #1
    bne     emit_n_byte
    pop     {pc}

@ Macros.

d_macro:                                @ .macro name param, ...: its lines up to .endm
    ldr     r4, [r9, #V_nmac]
    add     r0, r9, #MACROS - VARS + MAC_max * MAC_size
    cmp     r4, r0
    bhs     too_many_macros
    bl      blanks
    bl      word
    cmp     r2, #0
    beq     bad_syntax
    bl      pack
    str     r0, [r4, #MAC_name]
    str     r3, [r4, #MAC_name+4]
    mov     r5, #0                      @ its parameters
d_macro_param:
    bl      blanks
    cmp     r12, #0x0a                  @ '\n': the end of its line
    cmpne   r12, #0x40                  @ '@': a comment
    beq     d_macro_body
    cmp     r5, #0
    beq     d_macro_name
    bl      p_comma
d_macro_name:
    bl      word
    cmp     r2, #0
    beq     bad_syntax
    cmp     r5, #4
    bhs     bad_syntax
    add     r0, r4, #MAC_params
    add     r0, r0, r5, lsl #3
    str     r1, [r0]
    str     r2, [r0, #4]
    add     r5, r5, #1
    b       d_macro_param
d_macro_body:
    str     r5, [r4, #MAC_n]
    bl      skip_line                   @ its lines from the next one on
    str     r10, [r4, #MAC_body]
d_macro_line:
    cmp     r10, r11
    bhs     bad_syntax                  @ no .endm
    mov     r6, r10                     @ the line's first byte
    bl      blanks
    bl      word
    bl      pack
    la      r1, str_endm
    ldr     r2, [r1]
    ldr     r1, [r1, #4]
    cmp     r0, r2
    cmpeq   r3, r1
    beq     d_macro_end
    bl      skip_line
    ldr     r0, [r9, #V_line]
    add     r0, r0, #1
    str     r0, [r9, #V_line]
    b       d_macro_line
d_macro_end:
    str     r6, [r4, #MAC_end]
    add     r4, r4, #MAC_size
    str     r4, [r9, #V_nmac]
    b       end_line

d_endm:                                 @ .endm without its .macro
    b       bad_syntax

skip_line:                              @ r10 after the next newline (uses r12)
    cmp     r10, r11
    bxhs    lr
    ldrb    r12, [r10], #1
    cmp     r12, #0x0a
    bne     skip_line
    bx      lr

expand:                                 @ macro r4 called: its arguments, then its lines
    mov     r5, #0                      @ the arguments
    ldr     r6, [r4, #MAC_n]
expand_arg:
    cmp     r5, r6
    bhs     expand_lines
    cmp     r5, #0
    beq     expand_first
    bl      p_comma
expand_first:
    bl      blanks
    mov     r1, r10                     @ to a ',', a newline or '@'
expand_arg_byte:
    cmp     r10, r11
    bhs     expand_arg_end
    ldrb    r12, [r10]
    cmp     r12, #0x2c
    cmpne   r12, #0x0a
    cmpne   r12, #0x40
    beq     expand_arg_end
    add     r10, r10, #1
    b       expand_arg_byte
expand_arg_end:
    mov     r2, r10                     @ without the blanks after it
expand_arg_trim:
    cmp     r2, r1
    beq     expand_arg_store
    ldrb    r12, [r2, #-1]
    cmp     r12, #0x20
    cmpne   r12, #0x09
    subeq   r2, r2, #1
    beq     expand_arg_trim
expand_arg_store:
    sub     r2, r2, r1
    add     r0, r9, #ARGS - VARS
    add     r0, r0, r5, lsl #3
    str     r1, [r0]
    str     r2, [r0, #4]
    add     r5, r5, #1
    b       expand_arg
expand_lines:                           @ what the lines' statements change, on the stack:
    ldr     r0, [r9, #V_sret]           @ 0 statement's return, 4 the line's start,
    ldr     r1, [r9, #V_lstart]         @ 8 the macro's next line, 12 the macro,
    ldr     r2, [r4, #MAC_body]         @ 16, 20 the rest of the call's line
    push    {r0, r1, r2, r4, r10, r11}
expand_line:
    ldr     r3, [sp, #8]
    ldr     r4, [sp, #12]
    ldr     r0, [r4, #MAC_end]
    cmp     r3, r0
    bhs     expand_done
    add     r5, r9, #EXPBUF - VARS      @ the line, \param as its argument
expand_byte:
    add     r0, r9, #EXPBUF_END - VARS
    cmp     r5, r0
    bhs     bad_syntax
    ldrb    r6, [r3], #1
    cmp     r6, #0x5c                   @ '\'
    beq     expand_param
    strb    r6, [r5], #1
    cmp     r6, #0x0a
    bne     expand_byte
    str     r3, [sp, #8]
    add     r10, r9, #EXPBUF - VARS
    mov     r11, r5
    str     r10, [r9, #V_lstart]
    bl      statement
    b       expand_line
expand_param:                           @ \name: the argument of parameter name
    mov     r10, r3
    bl      word                        @ r1, r2
    mov     r3, r10
    ldr     r4, [sp, #12]
    ldr     r6, [r4, #MAC_n]
    add     r7, r4, #MAC_params
    add     r8, r9, #ARGS - VARS
expand_find:
    cmp     r6, #0
    beq     bad_syntax                  @ no such parameter
    ldr     r0, [r7, #4]
    cmp     r0, r2
    bne     expand_find_on
    ldr     r0, [r7]
    mov     r12, #0
expand_cmp:
    cmp     r12, r2
    beq     expand_found
    ldrb    r4, [r0, r12]
    ldrb    lr, [r1, r12]
    cmp     r4, lr
    bne     expand_find_on
    add     r12, r12, #1
    b       expand_cmp
expand_find_on:
    add     r7, r7, #8
    add     r8, r8, #8
    sub     r6, r6, #1
    b       expand_find
expand_found:                           @ its argument's bytes
    ldr     r0, [r8]
    ldr     r1, [r8, #4]
expand_copy:
    cmp     r1, #0
    beq     expand_byte
    add     r12, r9, #EXPBUF_END - VARS
    cmp     r5, r12
    bhs     bad_syntax
    ldrb    r12, [r0], #1
    strb    r12, [r5], #1
    sub     r1, r1, #1
    b       expand_copy
expand_done:
    pop     {r0, r1, r2, r4, r10, r11}
    str     r0, [r9, #V_sret]
    str     r1, [r9, #V_lstart]
    b       end_line

@ The instructions: the mnemonic's routine, with r4 its base bits and its
@ condition, r5 its other bits (from mnemonics). Pass 1 only counts its 4
@ bytes. Each ends with end_line.

insn:                                   @ r1, r2: the mnemonic, or a macro's name
    bl      pack
    add     r4, r9, #MACROS - VARS
    ldr     r5, [r9, #V_nmac]
insn_macro:
    cmp     r4, r5
    bhs     insn_table
    ldr     r6, [r4, #MAC_name]
    ldr     r7, [r4, #MAC_name+4]
    cmp     r6, r0
    cmpeq   r7, r3
    beq     expand
    add     r4, r4, #MAC_size
    b       insn_macro
insn_table:
    mov     r8, #0xe0000000             @ al: always
    bl      mnemonic
    cmp     r5, #0
    bne     insn_found
    cmp     r2, #2                      @ else a condition after a mnemonic
    bls     unknown_mnemonic
    sub     r2, r2, #2
    bl      pack
    bl      mnemonic
    add     r2, r2, #2
    cmp     r5, #0
    beq     unknown_mnemonic
    bl      cond
insn_found:
    ldr     r0, [r9, #V_emit]
    cmp     r0, #0
    beq     insn_count
    ldr     r0, [r5, #8]                @ its routine, from mnemonics
    ldr     r4, [r5, #12]
    orr     r4, r4, r8
    ldr     r5, [r5, #16]
    la      r1, mnemonics
    add     r0, r0, r1
    bx      r0
insn_count:                             @ pass 1: its 4 bytes, the rest of the line unread
    cmp     r10, r11
    bhs     insn_counted
    ldrb    r0, [r10]
    cmp     r0, #0x0a
    addne   r10, r10, #1
    bne     insn_count
insn_counted:
    mov     r0, #0
    bl      emit32
    b       end_line

mnemonic:                               @ r5 = the entry of mnemonics of name r0, r3, or 0 (uses r6, r7)
    la      r5, mnemonics
mnemonic_next:
    ldr     r6, [r5]
    cmp     r6, #0
    moveq   r5, #0
    bxeq    lr
    ldr     r7, [r5, #4]
    cmp     r6, r0
    cmpeq   r7, r3
    bxeq    lr
    add     r5, r5, #20
    b       mnemonic_next

cond:                                   @ r8 = the condition of the last 2 bytes of r1, r2, in bits 31:28 (uses r0, r3, r6)
    add     r0, r1, r2
    ldrb    r3, [r0, #-2]
    ldrb    r0, [r0, #-1]
    orr     r0, r3, r0, lsl #8
    la      r6, conds
cond_next:
    ldr     r3, [r6], #4
    cmp     r3, #0
    beq     unknown_mnemonic
    eor     r8, r3, r0
    lsls    r8, r8, #16
    bne     cond_next
    lsr     r8, r3, #16
    lsl     r8, r8, #28
    bx      lr

insn_emit:                              @ the instruction r4
    mov     r0, r4
    bl      emit32
    b       end_line

@ The operands (pass 2).

p_reg:                                  @ r0 = the number of the register at r10 (uses r1-r3, r12)
    push    {lr}
    bl      blanks
    bl      word
    bl      pack
    cmp     r3, #0
    bne     unknown_register
    tst     r0, #0xff000000             @ 3 bytes at most
    bne     unknown_register
    la      r12, registers
p_reg_next:
    ldr     r1, [r12], #4
    cmp     r1, #0
    beq     unknown_register
    eor     r2, r1, r0
    lsls    r2, r2, #8
    bne     p_reg_next
    lsr     r0, r1, #24                 @ its number, after its name
    pop     {pc}

p_comma:                                @ skips blanks, a ',' and the blanks after it; r12 = the byte after them
    ldrb    r12, [r10]
    cmp     r12, #0x20
    cmpne   r12, #0x09
    addeq   r10, r10, #1
    beq     p_comma
    cmp     r12, #0x2c                  @ ','
    bne     bad_syntax
    add     r10, r10, #1
    b       blanks

p_hash:                                 @ skips blanks and a '#' (uses r12)
    ldrb    r12, [r10]
    cmp     r12, #0x20
    cmpne   r12, #0x09
    addeq   r10, r10, #1
    beq     p_hash
    cmp     r12, #0x23                  @ '#'
    bne     bad_operand
    add     r10, r10, #1
    bx      lr

p_number:                               @ r0 = #expr, a number (uses r1-r3, r12)
    push    {lr}
    bl      p_hash
    bl      eval
    cmp     r1, #0
    bne     bad_operand
    pop     {pc}

p_op2:                                  @ operand 2 into r4: #imm, or rm with an optional shift (uses r0-r3, r12)
    push    {lr}
    bl      blanks
    cmp     r12, #0x23                  @ '#'
    beq     p_op2_imm
    bl      p_reg
    orr     r4, r4, r0                  @ rm
    bl      p_shift
    pop     {pc}
p_op2_imm:
    bl      p_number
    bl      dp_imm
    pop     {pc}

p_shift:                                @ an optional ", lsl|lsr|asr|ror #n" or "..., rs" into r4 (uses r0-r3, r12)
    push    {lr}
    bl      blanks
    cmp     r12, #0x2c                  @ ','
    popne   {pc}
    add     r10, r10, #1
    bl      blanks
    bl      word
    bl      pack
    cmp     r3, #0
    bne     bad_operand
    la      r12, shifts
    mov     r1, #0                      @ its type
p_shift_next:
    ldr     r2, [r12], #4
    cmp     r2, #0
    beq     bad_operand
    cmp     r2, r0
    addne   r1, r1, #1
    bne     p_shift_next
    orr     r4, r4, r1, lsl #5
    bl      p_amount
    pop     {pc}

p_amount:                               @ a shift's amount into r4: #n (lsl 0-31, lsr asr 1-32, ror 1-31) or rs (uses r0-r3, r12)
    push    {lr}
    bl      blanks
    cmp     r12, #0x23                  @ '#'
    bne     p_amount_reg
    bl      p_number
    cmp     r0, #32
    bhi     out_of_range
    bne     p_amount_imm
    and     r1, r4, #0x60               @ 32: lsr and asr as 0
    cmp     r1, #0x20
    cmpne   r1, #0x40
    bne     out_of_range
    mov     r0, #0
p_amount_imm:
    orr     r4, r4, r0, lsl #7
    pop     {pc}
p_amount_reg:
    bl      p_reg
    orr     r4, r4, r0, lsl #8
    orr     r4, r4, #0x10
    pop     {pc}

dp_imm:                                 @ the immediate r0 into data instruction r4, as gas (uses r0-r3, r12)
    push    {lr}
    mov     r2, r0
    bl      arm_imm                     @ 8 bits rotated?
    cmp     r0, #0
    bge     dp_imm_done
    ubfx    r3, r4, #21, #4             @ else the other of its pair, negated or inverted
    la      r12, negates
    ldrb    r12, [r12, r3]
    tst     r12, #0x10
    rsbne   r0, r2, #0
    tst     r12, #0x20
    mvnne   r0, r2
    tst     r12, #0x30
    beq     dp_imm_movw
    bl      arm_imm
    cmp     r0, #0
    blt     dp_imm_movw
    bic     r4, r4, #0x01e00000         @ the other opcode
    and     r12, r12, #15
    orr     r4, r4, r12, lsl #21
dp_imm_done:
    orr     r4, r4, #0x02000000         @ I: an immediate
    orr     r4, r4, r0
    pop     {pc}
dp_imm_movw:                            @ else for mov (S 0) of 0-0xffff: movw
    ubfx    r3, r4, #20, #5             @ its opcode and S
    cmp     r3, #0x1a                   @ mov, S 0
    bne     out_of_range
    cmp     r2, #0x10000
    bhs     out_of_range
    bic     r4, r4, #0x00f00000
    orr     r4, r4, #0x02000000
    and     r0, r2, #0xf000             @ imm4
    orr     r4, r4, r0, lsl #4
    bic     r0, r2, #0xf000             @ imm12
    orr     r4, r4, r0
    pop     {pc}

arm_imm:                                @ r0 = r0 as 8 bits rotated right by the fewest even bits (rotate:imm8), or -1 (uses r1, r3)
    cmp     r0, #0x100
    bxlo    lr
    mov     r3, #2
arm_imm_rot:
    rsb     r1, r3, #32
    ror     r1, r0, r1                  @ r0 rotated left by r3
    cmp     r1, #0x100
    blo     arm_imm_found
    add     r3, r3, #2
    cmp     r3, #32
    blo     arm_imm_rot
    mvn     r0, #0
    bx      lr
arm_imm_found:
    orr     r0, r1, r3, lsl #7          @ rotate r3 / 2
    bx      lr

@ The instructions' routines.

h_dp:                                   @ and eor sub rsb add adc sbc rsc orr bic: rd, rn, op2
    bl      p_reg
    orr     r4, r4, r0, lsl #12
    bl      p_comma
    bl      p_reg
    orr     r4, r4, r0, lsl #16
    bl      p_comma
    bl      p_op2
    b       insn_emit

h_mov:                                  @ mov mvn: rd, op2
    bl      p_reg
    orr     r4, r4, r0, lsl #12
    bl      p_comma
    bl      p_op2
    b       insn_emit

h_cmp:                                  @ tst teq cmp cmn: rn, op2
    bl      p_reg
    orr     r4, r4, r0, lsl #16
    bl      p_comma
    bl      p_op2
    b       insn_emit

h_shift:                                @ lsl lsr asr ror: rd, rm, #n or rs, as mov's shifted rm
    bl      p_reg
    orr     r4, r4, r0, lsl #12
    bl      p_comma
    bl      p_reg
    orr     r4, r4, r0
    orr     r4, r4, r5                  @ its type
    bl      p_comma
    bl      p_amount
    b       insn_emit

h_movw:                                 @ movw movt: rd, #imm16, #:lower16:expr or #:upper16:expr
    bl      p_reg
    orr     r4, r4, r0, lsl #12
    bl      p_comma
    bl      p_hash
    ldrb    r12, [r10]
    cmp     r12, #0x3a                  @ ':'
    bne     h_movw_plain
    add     r10, r10, #1
    bl      word
    bl      pack
    la      r12, str_lower16
    ldr     r1, [r12]
    ldr     r2, [r12, #4]
    cmp     r0, r1
    cmpeq   r3, r2
    moveq   r6, #0                      @ the low half
    beq     h_movw_colon
    ldr     r1, [r12, #8]
    ldr     r2, [r12, #12]
    cmp     r0, r1
    cmpeq   r3, r2
    bne     bad_operand
    mov     r6, #16                     @ the high half
h_movw_colon:
    ldrb    r12, [r10]
    cmp     r12, #0x3a                  @ ':'
    bne     bad_operand
    add     r10, r10, #1
    bl      eval                        @ a number or an address
    lsr     r0, r0, r6
    lsl     r0, r0, #16
    lsr     r0, r0, #16
    b       h_movw_put
h_movw_plain:
    bl      eval
    cmp     r1, #0
    bne     bad_operand
    cmp     r0, #0x10000
    bhs     out_of_range
h_movw_put:
    and     r1, r0, #0xf000             @ imm4
    orr     r4, r4, r1, lsl #4
    bic     r0, r0, #0xf000             @ imm12
    orr     r4, r4, r0
    b       insn_emit

h_mul:                                  @ mul mla umull: registers, each at its bit (r5: their count, then each bit / 4)
    and     r6, r5, #15
    lsr     r5, r5, #4
    b       h_mul_reg
h_mul_next:
    bl      p_comma
h_mul_reg:
    bl      p_reg
    and     r1, r5, #15
    lsl     r1, r1, #2
    orr     r4, r4, r0, lsl r1
    lsr     r5, r5, #4
    subs    r6, r6, #1
    bne     h_mul_next
    b       insn_emit

h_mem:                                  @ ldr ldrb str strb: rt, [rn{, #expr}]{!}, [rn], #expr or [rn, rm{, shift #n}]
    bl      p_reg
    orr     r4, r4, r0, lsl #12
    bl      p_comma
    cmp     r12, #0x5b                  @ '['
    bne     bad_operand
    add     r10, r10, #1
    bl      p_reg
    orr     r4, r4, r0, lsl #16
    bl      blanks
    cmp     r12, #0x5d                  @ ']'
    beq     h_mem_post
    bl      p_comma
    cmp     r12, #0x23                  @ '#'
    bne     h_mem_reg
    bl      p_number
    bl      offset12
    orr     r4, r4, #0x01000000         @ P: an offset
    bl      blanks
    cmp     r12, #0x5d                  @ ']'
    bne     bad_operand
    add     r10, r10, #1
    bl      blanks
    cmp     r12, #0x21                  @ '!': written back
    orreq   r4, r4, #0x00200000
    addeq   r10, r10, #1
    b       insn_emit
h_mem_reg:                              @ [rn, rm{, shift #n}]
    bl      p_reg
    orr     r4, r4, r0
    orr     r4, r4, #0x03800000         @ a register (I), P, U
    bl      p_shift
    bl      blanks
    cmp     r12, #0x5d                  @ ']'
    bne     bad_operand
    add     r10, r10, #1
    b       insn_emit
h_mem_post:                             @ [rn], or [rn], #expr (post-indexed)
    add     r10, r10, #1
    bl      blanks
    cmp     r12, #0x2c                  @ ','
    orrne   r4, r4, #0x01800000         @ [rn]: P, U, offset 0
    bne     insn_emit
    bl      p_comma
    bl      p_number
    bl      offset12
    b       insn_emit

offset12:                               @ offset r0 into r4: U, imm12
    cmp     r0, #0
    orrge   r4, r4, #0x00800000         @ U: added
    rsblt   r0, r0, #0
    cmp     r0, #0x1000
    bhs     out_of_range
    orr     r4, r4, r0
    bx      lr

h_memd:                                 @ ldrd strd: rt, rt+1, [rn{, #expr}]
    bl      p_reg
    orr     r4, r4, r0, lsl #12
    add     r6, r0, #1
    bl      p_comma
    bl      p_reg
    cmp     r0, r6
    bne     bad_operand
    bl      p_comma
    cmp     r12, #0x5b                  @ '['
    bne     bad_operand
    add     r10, r10, #1
    bl      p_reg
    orr     r4, r4, r0, lsl #16
    orr     r4, r4, #0x01000000         @ P: an offset
    bl      blanks
    cmp     r12, #0x5d                  @ ']'
    orreq   r4, r4, #0x00800000         @ [rn]: U, offset 0
    beq     h_memd_end
    bl      p_comma
    bl      p_number
    cmp     r0, #0
    orrge   r4, r4, #0x00800000         @ U: added
    rsblt   r0, r0, #0
    cmp     r0, #0x100
    bhs     out_of_range
    and     r1, r0, #0xf0               @ imm4H
    orr     r4, r4, r1, lsl #4
    and     r0, r0, #15                 @ imm4L
    orr     r4, r4, r0
    bl      blanks
    cmp     r12, #0x5d                  @ ']'
    bne     bad_operand
h_memd_end:
    add     r10, r10, #1
    b       insn_emit

h_push:                                 @ push pop: {registers}; of one, gas's str or ldr (r5)
    bl      blanks
    cmp     r12, #0x7b                  @ '{'
    bne     bad_operand
    add     r10, r10, #1
    mov     r6, #0                      @ the registers
h_push_reg:
    bl      p_reg
    mov     r7, r0                      @ from
    bl      blanks
    cmp     r12, #0x2d                  @ '-': to
    movne   r0, r7
    bne     h_push_bits
    add     r10, r10, #1
    bl      p_reg
    cmp     r0, r7
    blo     bad_operand
h_push_bits:
    mov     r1, #1
    orr     r6, r6, r1, lsl r7
    add     r7, r7, #1
    cmp     r7, r0
    bls     h_push_bits
    bl      blanks
    cmp     r12, #0x2c                  @ ','
    addeq   r10, r10, #1
    beq     h_push_reg
    cmp     r12, #0x7d                  @ '}'
    bne     bad_operand
    add     r10, r10, #1
    sub     r0, r6, #1                  @ several: stmdb sp!, ldmia sp!
    tst     r0, r6
    orrne   r4, r4, r6
    bne     insn_emit
    clz     r0, r6                      @ one: str rt, [sp, #-4]!, ldr rt, [sp], #4
    rsb     r0, r0, #31
    orr     r4, r5, r8
    orr     r4, r4, r0, lsl #12
    b       insn_emit

h_b:                                    @ b bl: label
    bl      blanks
    bl      eval
    cmp     r1, #1                      @ in .text
    bne     bad_target
    mov     r6, r0
    bl      here
    sub     r0, r6, r0                  @ from the instruction + 8, in words
    sub     r0, r0, #8
    tst     r0, #3
    bne     bad_target
    asr     r0, r0, #2
    lsl     r1, r0, #8                  @ in 24 bits
    cmp     r0, r1, asr #8
    bne     out_of_range
    bic     r0, r0, #0xff000000
    orr     r4, r4, r0
    b       insn_emit

h_bx:                                   @ bx blx: rm
    bl      p_reg
    orr     r4, r4, r0
    b       insn_emit

h_svc:                                  @ svc #imm24
    bl      p_number
    cmp     r0, #0x1000000
    bhs     out_of_range
    orr     r4, r4, r0
    b       insn_emit

@ Output: the places of the sections, then the headers.

layout:                                 @ the sections' places, from their sizes, as ld -T ttpc.ld
    push    {r4, r5, r6, lr}
    mov     r0, #HDRS                   @ after the headers: .text, .rodata
    mov     r1, #1
    bl      place
    mov     r1, #2
    bl      place
    str     r0, [r9, #V_tend]           @ the code's end in the file,
    add     r4, r0, #ADDR               @ and its address e:
    ubfx    r5, r4, #0, #12             @ ALIGN(0x1000) + (e & 0xfff)
    add     r6, r4, #0x1000
    sub     r6, r6, #1
    lsr     r6, r6, #12
    lsl     r6, r6, #12
    add     r6, r6, r5
    mov     r0, r6                      @ .data, aligned
    ldr     r1, [r9, #V_align+12]
    bl      alignup
    str     r0, [r9, #V_base+12]
    sub     r3, r0, r6                  @ its file offset: the code's end plus
    ldr     r2, [r9, #V_tend]           @ the same padding
    add     r3, r3, r2
    str     r3, [r9, #V_off+12]
    ldr     r2, [r9, #V_loc+12]
    add     r0, r0, r2
    ldr     r1, [r9, #V_align+16]       @ .bss, aligned
    bl      alignup
    str     r0, [r9, #V_base+16]
    add     r3, r3, r2                  @ its file offset, .ARM.attributes', the end of .data
    str     r3, [r9, #V_off+16]
    str     r3, [r9, #V_attr]
    add     r3, r3, #ATTR_len           @ then .shstrtab
    str     r3, [r9, #V_shstr]
    add     r0, r3, #SHSTRTAB_len       @ then the section headers
    mov     r1, #4
    bl      alignup
    str     r0, [r9, #V_shoff]
    add     r0, r0, #SHDRS
    str     r0, [r9, #V_fend]
    cmp     r0, #OUTBUF_END - OUTBUF
    bhi     output_full
    pop     {r4, r5, r6, pc}

place:                                  @ section r1 from file offset r0, aligned; r0 = its end (uses r1, r2)
    push    {lr}
    add     r2, r9, r1, lsl #2
    ldr     r1, [r2, #V_align]
    bl      alignup
    str     r0, [r2, #V_off]
    add     r1, r0, #ADDR
    str     r1, [r2, #V_base]
    ldr     r1, [r2, #V_loc]
    add     r0, r0, r1
    pop     {pc}

alignup:                                @ r0 up to a multiple of r1, a power of 2 (uses r1)
    sub     r1, r1, #1
    add     r0, r0, r1
    bic     r0, r0, r1
    bx      lr

headers:                                @ the ELF header, the program headers, .ARM.attributes, .shstrtab, the section headers
    push    {r4, lr}
    mov     r1, #4                      @ each section has bytes
headers_bytes:
    add     r0, r9, r1, lsl #2
    ldr     r0, [r0, #V_loc]
    cmp     r0, #0
    beq     empty_section
    subs    r1, r1, #1
    bne     headers_bytes
    mov     r0, #OUTBUF
    la      r1, elf_headers
    mov     r2, #HDRS
    bl      copy
    la      r1, str_start               @ e_entry: _start
    mov     r2, #6
    bl      find_sym
    cmp     r0, #0
    beq     no_start
    ldr     r1, [r0, #S_pass]
    cmp     r1, #0
    beq     no_start
    ldr     r1, [r0, #S_kind]
    add     r1, r9, r1, lsl #2
    ldr     r1, [r1, #V_base]
    ldr     r2, [r0, #S_value]
    add     r2, r2, r1
    mov     r0, #OUTBUF
    str     r2, [r0, #24]
    ldr     r1, [r9, #V_shoff]          @ e_shoff
    str     r1, [r0, #32]
    ldr     r1, [r9, #V_tend]           @ the code: p_filesz, p_memsz
    str     r1, [r0, #52+16]
    str     r1, [r0, #52+20]
    ldr     r1, [r9, #V_off+12]         @ the data: p_offset
    str     r1, [r0, #84+4]
    ldr     r1, [r9, #V_base+12]        @ p_vaddr, p_paddr
    str     r1, [r0, #84+8]
    str     r1, [r0, #84+12]
    ldr     r1, [r9, #V_loc+12]         @ p_filesz: .data
    str     r1, [r0, #84+16]
    ldr     r1, [r9, #V_base+16]        @ p_memsz: to the end of .bss
    ldr     r2, [r9, #V_loc+16]
    add     r1, r1, r2
    ldr     r2, [r9, #V_base+12]
    sub     r1, r1, r2
    str     r1, [r0, #84+20]
    ldr     r0, [r9, #V_attr]           @ .ARM.attributes, then .shstrtab
    add     r0, r0, #OUTBUF
    la      r1, attributes
    mov     r2, #ATTR_len + SHSTRTAB_len
    bl      copy
    ldr     r0, [r9, #V_shoff]          @ the section headers
    add     r0, r0, #OUTBUF
    mov     r4, r0
    la      r1, section_headers
    mov     r2, #SHDRS
    bl      copy
    mov     r1, #1
headers_section:                        @ 1-4: .text .rodata .data .bss
    add     r4, r4, #40
    add     r2, r9, r1, lsl #2
    ldr     r0, [r2, #V_base]           @ sh_addr
    str     r0, [r4, #12]
    ldr     r0, [r2, #V_off]            @ sh_offset
    str     r0, [r4, #16]
    ldr     r0, [r2, #V_loc]            @ sh_size
    str     r0, [r4, #20]
    ldr     r0, [r2, #V_align]          @ sh_addralign
    str     r0, [r4, #32]
    add     r1, r1, #1
    cmp     r1, #5
    bne     headers_section
    ldr     r0, [r9, #V_attr]           @ 5: .ARM.attributes' sh_offset
    str     r0, [r4, #40+16]
    ldr     r0, [r9, #V_shstr]          @ 6: .shstrtab's
    str     r0, [r4, #80+16]
    pop     {r4, pc}

copy:                                   @ r2 bytes from r1 to r0 (uses r0-r2, r12)
    subs    r2, r2, #1
    bxlo    lr
    ldrb    r12, [r1], #1
    strb    r12, [r0], #1
    b       copy

@ The errors: asm: line N: what: the line.

junk:
    la      r0, msg_junk
    b       fail
twice:
    la      r0, msg_twice
    b       fail
too_many_symbols:
    la      r0, msg_symbols
    b       fail
too_many_macros:
    la      r0, msg_macros
    b       fail
bad_local:
    la      r0, msg_local
    b       fail
not_number:
    la      r0, msg_not_number
    b       fail
bad_number:
    la      r0, msg_number
    b       fail
bad_expr:
    la      r0, msg_expr
    b       fail
not_defined:
    la      r0, msg_undefined
    b       fail
bad_syntax:
    la      r0, msg_syntax
    b       fail
bad_align:
    la      r0, msg_align
    b       fail
bad_string:
    la      r0, msg_string
    b       fail
unknown_mnemonic:
    la      r0, msg_mnemonic
    b       fail
unknown_register:
    la      r0, msg_register
    b       fail
bad_operand:
    la      r0, msg_operand
    b       fail
out_of_range:
    la      r0, msg_range
    b       fail
bad_target:
    la      r0, msg_target
    b       fail
in_bss:
    la      r0, msg_bss
fail:                                   @ message r0 (a C string) about the line
    mov     r4, r0
    la      r1, msg_line
    bl      eputs
    ldr     r0, [r9, #V_line]
    bl      eputn
    la      r1, msg_colon
    bl      eputs
    mov     r1, r4
    bl      eputs
    la      r1, msg_colon
    bl      eputs
    ldr     r1, [r9, #V_lstart]         @ the line, to its newline
    mov     r2, r1
fail_line:
    cmp     r2, r11
    bhs     fail_line_end
    ldrb    r12, [r2]
    cmp     r12, #0x0a
    addne   r2, r2, #1
    bne     fail_line
fail_line_end:
    sub     r2, r2, r1
    bl      ewrite
    la      r1, msg_newline
    bl      eputs
    mov     r0, #1
    b       exit
output_full:
    la      r0, msg_full
    b       die
empty_section:
    la      r0, msg_empty
    b       die
no_start:
    la      r0, msg_start
    b       die
too_large:
    la      r0, msg_large
    b       die
read_failed:
    la      r0, msg_read
    b       die
write_failed:
    la      r0, msg_write
die:                                    @ asm: message r0
    mov     r4, r0
    la      r1, msg_asm
    bl      eputs
    mov     r1, r4
    bl      eputs
    la      r1, msg_newline
    bl      eputs
    mov     r0, #1                      @ status 1
exit:
    mov     r7, #SYS_exit
    svc     #0

eputs:                                  @ writes the C string r1 to stderr (uses r0, r2, r7, r12)
    mov     r2, r1
eputs_len:
    ldrb    r12, [r2]
    cmp     r12, #0
    addne   r2, r2, #1
    bne     eputs_len
    sub     r2, r2, r1
ewrite:                                 @ writes r1, r2 to stderr (uses r0, r7)
    mov     r7, #SYS_write
    mov     r0, #2                      @ fd 2, stderr
    svc     #0
    bx      lr

eputn:                                  @ writes r0 in decimal to stderr (uses r0-r3, r7, r12)
    add     r1, r9, #NUMBUF + 12        @ the last digit first, from the end
    movw    r12, #0xcccd                @ n / 10 = (n * 0xcccccccd) >> 35
    movt    r12, #0xcccc
eputn_digit:
    umull   r3, r2, r0, r12
    lsr     r2, r2, #3
    add     r3, r2, r2, lsl #2          @ the digit: n - 10 * (n / 10)
    sub     r3, r0, r3, lsl #1
    add     r3, r3, #0x30
    strb    r3, [r1, #-1]!
    movs    r0, r2
    bne     eputn_digit
    add     r2, r9, #NUMBUF + 12
    sub     r2, r2, r1
    b       ewrite

@ The tables, 4-byte aligned: names as 8 bytes, the first lowest, 0 after
@ the name; a routine as its offset from its table.
    .balign 4
directives:                             @ name, its routine
    .ascii ".ascii\0\0"
    .word d_ascii - directives
    .ascii ".asciz\0\0"
    .word d_asciz - directives
    .ascii ".balign\0"
    .word d_balign - directives
    .ascii ".byte\0\0\0"
    .word d_byte - directives
    .ascii ".hword\0\0"
    .word d_hword - directives
    .ascii ".word\0\0\0"
    .word d_word - directives
    .ascii ".equ\0\0\0\0"
    .word d_equ - directives
    .ascii ".globl\0\0"
    .word d_globl - directives
    .ascii ".section"
    .word d_section - directives
    .ascii ".skip\0\0\0"
    .word d_skip - directives
    .ascii ".text\0\0\0"
    .word d_text - directives
    .ascii ".data\0\0\0"
    .word d_data - directives
    .ascii ".bss\0\0\0\0"
    .word d_bss - directives
    .ascii ".macro\0\0"
    .word d_macro - directives
    .ascii ".endm\0\0\0"
    .word d_endm - directives
    .ascii ".syntax\0"
    .word d_ignore - directives
    .ascii ".arch\0\0\0"
    .word d_ignore - directives
    .ascii ".arm\0\0\0\0"
    .word d_ignore - directives
    .word 0

sections:                               @ 1-4
    .ascii ".text\0\0\0"
    .ascii ".rodata\0"
    .ascii ".data\0\0\0"
    .ascii ".bss\0\0\0\0"

registers:                              @ its name (3 bytes), its number
    .ascii "r0\0\0", "r1\0\1", "r2\0\2", "r3\0\3", "r4\0\4", "r5\0\5", "r6\0\6", "r7\0\7"
    .ascii "r8\0\10", "r9\0\11", "r10\12", "r11\13", "r12\14", "r13\15", "r14\16", "r15\17"
    .ascii "sp\0\15", "lr\0\16", "pc\0\17", "ip\0\14", "fp\0\13"
    .word 0

conds:                                  @ its name (2 bytes), its number, 0
    .ascii "eq\0\0", "ne\1\0", "cs\2\0", "hs\2\0", "cc\3\0", "lo\3\0", "mi\4\0", "pl\5\0"
    .ascii "vs\6\0", "vc\7\0", "hi\10\0", "ls\11\0", "ge\12\0", "lt\13\0", "gt\14\0", "le\15\0"
    .ascii "al\16\0"
    .word 0

shifts:                                 @ 0-3, the shifts' types
    .ascii "lsl\0", "lsr\0", "asr\0", "ror\0"
    .word 0

negates:                                @ each opcode's other: 0x10 | it negated, 0x20 | it inverted, 0 none
    .byte 0x2e, 0, 0x14, 0, 0x12, 0x26, 0x25, 0    @ and eor sub rsb add adc sbc rsc
    .byte 0, 0, 0x1b, 0x1a, 0, 0x2f, 0x20, 0x2d    @ tst teq cmp cmn orr mov bic mvn

mnemonics:                              @ name, its routine, its base bits, its other bits
    .ascii "and\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00000000, 0
    .ascii "ands\0\0\0\0"
    .word h_dp - mnemonics, 0x00100000, 0
    .ascii "eor\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00200000, 0
    .ascii "eors\0\0\0\0"
    .word h_dp - mnemonics, 0x00300000, 0
    .ascii "sub\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00400000, 0
    .ascii "subs\0\0\0\0"
    .word h_dp - mnemonics, 0x00500000, 0
    .ascii "rsb\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00600000, 0
    .ascii "rsbs\0\0\0\0"
    .word h_dp - mnemonics, 0x00700000, 0
    .ascii "add\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00800000, 0
    .ascii "adds\0\0\0\0"
    .word h_dp - mnemonics, 0x00900000, 0
    .ascii "adc\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00a00000, 0
    .ascii "adcs\0\0\0\0"
    .word h_dp - mnemonics, 0x00b00000, 0
    .ascii "sbc\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00c00000, 0
    .ascii "sbcs\0\0\0\0"
    .word h_dp - mnemonics, 0x00d00000, 0
    .ascii "rsc\0\0\0\0\0"
    .word h_dp - mnemonics, 0x00e00000, 0
    .ascii "rscs\0\0\0\0"
    .word h_dp - mnemonics, 0x00f00000, 0
    .ascii "orr\0\0\0\0\0"
    .word h_dp - mnemonics, 0x01800000, 0
    .ascii "orrs\0\0\0\0"
    .word h_dp - mnemonics, 0x01900000, 0
    .ascii "bic\0\0\0\0\0"
    .word h_dp - mnemonics, 0x01c00000, 0
    .ascii "bics\0\0\0\0"
    .word h_dp - mnemonics, 0x01d00000, 0
    .ascii "tst\0\0\0\0\0"
    .word h_cmp - mnemonics, 0x01100000, 0
    .ascii "teq\0\0\0\0\0"
    .word h_cmp - mnemonics, 0x01300000, 0
    .ascii "cmp\0\0\0\0\0"
    .word h_cmp - mnemonics, 0x01500000, 0
    .ascii "cmn\0\0\0\0\0"
    .word h_cmp - mnemonics, 0x01700000, 0
    .ascii "mov\0\0\0\0\0"
    .word h_mov - mnemonics, 0x01a00000, 0
    .ascii "movs\0\0\0\0"
    .word h_mov - mnemonics, 0x01b00000, 0
    .ascii "mvn\0\0\0\0\0"
    .word h_mov - mnemonics, 0x01e00000, 0
    .ascii "mvns\0\0\0\0"
    .word h_mov - mnemonics, 0x01f00000, 0
    .ascii "lsl\0\0\0\0\0"
    .word h_shift - mnemonics, 0x01a00000, 0x00
    .ascii "lsr\0\0\0\0\0"
    .word h_shift - mnemonics, 0x01a00000, 0x20
    .ascii "asr\0\0\0\0\0"
    .word h_shift - mnemonics, 0x01a00000, 0x40
    .ascii "ror\0\0\0\0\0"
    .word h_shift - mnemonics, 0x01a00000, 0x60
    .ascii "movw\0\0\0\0"
    .word h_movw - mnemonics, 0x03000000, 0
    .ascii "movt\0\0\0\0"
    .word h_movw - mnemonics, 0x03400000, 0
    .ascii "mul\0\0\0\0\0"                  @ rd 16, rn 0, rm 8
    .word h_mul - mnemonics, 0x00000090, 0x02043
    .ascii "mla\0\0\0\0\0"                  @ rd 16, rn 0, rm 8, ra 12
    .word h_mul - mnemonics, 0x00200090, 0x32044
    .ascii "umull\0\0\0"                    @ rdlo 12, rdhi 16, rn 0, rm 8
    .word h_mul - mnemonics, 0x00800090, 0x20434
    .ascii "ldr\0\0\0\0\0"
    .word h_mem - mnemonics, 0x04100000, 0
    .ascii "ldrb\0\0\0\0"
    .word h_mem - mnemonics, 0x04500000, 0
    .ascii "str\0\0\0\0\0"
    .word h_mem - mnemonics, 0x04000000, 0
    .ascii "strb\0\0\0\0"
    .word h_mem - mnemonics, 0x04400000, 0
    .ascii "ldrd\0\0\0\0"
    .word h_memd - mnemonics, 0x004000d0, 0
    .ascii "strd\0\0\0\0"
    .word h_memd - mnemonics, 0x004000f0, 0
    .ascii "push\0\0\0\0"                   @ stmdb sp!; of one, str rt, [sp, #-4]!
    .word h_push - mnemonics, 0x092d0000, 0x052d0004
    .ascii "pop\0\0\0\0\0"                  @ ldmia sp!; of one, ldr rt, [sp], #4
    .word h_push - mnemonics, 0x08bd0000, 0x049d0004
    .ascii "b\0\0\0\0\0\0\0"
    .word h_b - mnemonics, 0x0a000000, 0
    .ascii "bl\0\0\0\0\0\0"
    .word h_b - mnemonics, 0x0b000000, 0
    .ascii "bx\0\0\0\0\0\0"
    .word h_bx - mnemonics, 0x012fff10, 0
    .ascii "blx\0\0\0\0\0"
    .word h_bx - mnemonics, 0x012fff30, 0
    .ascii "svc\0\0\0\0\0"
    .word h_svc - mnemonics, 0x0f000000, 0
    .word 0

elf_headers:                            @ ld's: the ELF header and the two program headers, 116 bytes
    .byte   0x7f, 0x45, 0x4c, 0x46, 1, 1, 1, 0    @ e_ident: 0x7f "ELF", 32-bit, little endian, version 1, System V
    .byte   0, 0, 0, 0, 0, 0, 0, 0              @ padding
    .hword  2                           @ e_type: ET_EXEC
    .hword  40                          @ e_machine: EM_ARM
    .word   1                           @ e_version
    .word   0                           @ e_entry: _start (headers)
    .word   52                          @ e_phoff: the program headers follow
    .word   0                           @ e_shoff: the section headers (headers)
    .word   0x05000200                  @ e_flags: EABI version 5, soft float
    .hword  52                          @ e_ehsize
    .hword  32                          @ e_phentsize
    .hword  2                           @ e_phnum
    .hword  40                          @ e_shentsize
    .hword  7                           @ e_shnum: 0 .text .rodata .data .bss .ARM.attributes .shstrtab
    .hword  6                           @ e_shstrndx: .shstrtab
    .word   1                           @ p_type: PT_LOAD, the code
    .word   0                           @ p_offset: from the file's first byte
    .word   ADDR                        @ p_vaddr
    .word   ADDR                        @ p_paddr
    .word   0                           @ p_filesz: to the end of .rodata (headers)
    .word   0                           @ p_memsz: the same (headers)
    .word   5                           @ p_flags: R X
    .word   0x1000                      @ p_align: a page
    .word   1                           @ p_type: PT_LOAD, the data
    .word   0                           @ p_offset: .data's (headers)
    .word   0                           @ p_vaddr: .data's address (headers)
    .word   0                           @ p_paddr: the same (headers)
    .word   0                           @ p_filesz: .data (headers)
    .word   0                           @ p_memsz: to the end of .bss (headers)
    .word   6                           @ p_flags: R W
    .word   0x1000                      @ p_align: a page

section_headers:                        @ the seven, without what headers fills in
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0    @ 0: none
    .word   0x0b, 1, 6, 0, 0, 0, 0, 0, 0, 0 @ 1: .text: its name, SHT_PROGBITS, SHF_ALLOC | SHF_EXECINSTR
    .word   0x11, 1, 2, 0, 0, 0, 0, 0, 0, 0 @ 2: .rodata, SHT_PROGBITS, SHF_ALLOC
    .word   0x19, 1, 3, 0, 0, 0, 0, 0, 0, 0 @ 3: .data, SHT_PROGBITS, SHF_WRITE | SHF_ALLOC
    .word   0x1f, 8, 3, 0, 0, 0, 0, 0, 0, 0 @ 4: .bss, SHT_NOBITS, SHF_WRITE | SHF_ALLOC
    .word   0x24, 0x70000003, 0, 0, 0, ATTR_len, 0, 0, 1, 0  @ 5: .ARM.attributes, SHT_ARM_ATTRIBUTES; size; sh_addralign 1
    .word   0x01, 3, 0, 0, 0, SHSTRTAB_len, 0, 0, 1, 0       @ 6: .shstrtab, SHT_STRTAB

attributes:                             @ .ARM.attributes as gas writes it for armv7-a, then .shstrtab
    .ascii  "A"                         @ format 'A'
    .word   0x1c                        @ the subsection's length
    .ascii  "aeabi\0"
    .byte   1                           @ Tag_File
    .word   0x12                        @ its attributes' length
    .ascii  "\0057-A\0"                 @ Tag_CPU_name "7-A"
    .byte   6, 10, 7, 0x41, 8, 1, 9, 2  @ Tag_CPU_arch v7, Tag_CPU_arch_profile 'A', Tag_ARM_ISA_use 1, Tag_THUMB_ISA_use 2
shstrtab:                               @ the section names, as ld orders them
    .ascii  "\0.shstrtab\0.text\0.rodata\0.data\0.bss\0.ARM.attributes\0"

    .balign 4
str_endm:       .ascii ".endm\0\0\0"
str_lower16:    .ascii "lower16\0"
str_upper16:    .ascii "upper16\0"
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
