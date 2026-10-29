# asm for riscv64 Linux: the assembler of the seed. The fourth link of the
# bootstrap, built by M1 and hex2 from hosts/riscv64/asm.M1 (made from this
# file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
# It assembles hosts/riscv64/ttpc.s, the readable seed, into the seed: the
# bytes binutils' as and ld make of it (as -march=rv64imac -mabi=lp64
# -mno-arch-attr, ld -static --no-relax -s -z noseparate-code), with no
# binutils.
#
#   asm < ttpc.s > ttpc
#
# The asm it reads: riscv64 GNU syntax as ttpc.s uses it.
#   lines      labels (name: and the local n: of 0-99, as 1b and 1f), then
#              a directive or an instruction; '#' starts a comment to the
#              end of the line
#   directives .equ name, expr  .dword .word .half .byte expr, ...
#              .ascii .asciz "text", ...  (escapes \n \t \ooo, \x as x)
#              .skip n  .balign n (not in .text)  .section name (.text
#              .rodata .data .bss)  .text .data .bss  .globl name
#   exprs      numbers (decimal, 0x hex, 0 octal), names, '.' (here), and
#              as gas: unary - ~, then * / % << >>, then | & ^, then + -,
#              and ( ); a label's address plus or minus a number, or two
#              labels of a section minus each other
#   operands   registers (x0-x31 and their ABI names, fp), numbers (exprs
#              defined before the line), offset(register), and the label
#              of a branch, jump, call or la
#   mnemonics  add sub and or xor sll srl sra slt sltu mul div divu rem
#              remu, addi andi ori xori slti sltiu slli srli srai, ld lbu
#              lb lh lhu lwu sd sb sh, beq bne blt bge bltu bgeu beqz bnez
#              bltz bgez blez bgtz bgt ble bgtu bleu, j jr jalr ret call,
#              la li mv neg not seqz snez, ecall nop
# Each instruction is encoded as gas does with the C extension (RVC):
# compressed where gas's opcode table has a compressed form first that
# its operands fit (c.add c.mv c.sub c.and c.or c.xor c.addi4spn c.addi
# c.nop c.addi16sp c.li c.andi c.slli c.srli c.srai c.ldsp c.ld c.sdsp
# c.sd c.jr c.jalr c.lui c.addiw, see each mnemonic), li as gas's
# load_const (c.lui, c.li, addi, or lui and addiw: 32-bit numbers), la
# and call as auipc and addi or jalr, and the branches and j as gas relaxes
# them: c.beqz, c.bnez and c.j when the target is near, else beq/bne,
# jal, or a branch over a jal (see relax). The output is the file ld
# makes: the ELF header, two program headers (the code: the headers,
# .text, .rodata; the data: .data, .bss), the sections, .shstrtab and six
# section headers. Each of .text .rodata .data .bss must have bytes.
#
# The input is read whole, then in two passes. Pass 1 sizes: every label
# gets its section and place, every branch and jump a record (the jumps)
# and .text is cut into gas's frags (after each branch or jump, after the
# auipc of an la, after a call); relax then gives every jump its length,
# the text labels their offsets, and layout every section its place. Pass
# 2 writes the sections into the output, which is then written whole. On
# an error it says so on stderr with the line (asm: line N: what: the
# line) and ends with status 1; else with 0.
#
# One flat file, loaded at BASE by its first program header, read and
# run; the second maps the memory it writes, VARS to the end of OUTBUF.
# RV64IM, no compressed instructions. The registers:
#   s0  VARS, the variables                 s1  the next byte of the input
#   s2  the end of the input
#   s3  the instruction's base bits (from mnemonics), s4 its other bits
#   s5  rd (or a store's source)  s6  rs1  s7  rs2 or the immediate
#   s8-s11  scratch of the instructions; sp the stack of the routines
# The routines take and give a0-a7 and use the t registers (each says
# which); a routine that calls another keeps ra on the stack, or in t5 or
# t6 when what it calls does not use them. A symbol is 48 bytes (S_*), a
# local label's definition 32 (L_*), a jump 32 (J_*), a frag 32 (F_*). A
# definition (D) is a symbol's S_value or a local label's L_value: its
# value, kind (0 a number, 1-4 the section), pass (0 not defined) and frag
# (the frag of a text label in pass 1, whose value is then its offset in
# that frag) at 0, 8, 16, 24.

    .equ BASE, 0x600000
    .equ VARS, 0x700000                 # the variables, 64 KiB
    .equ SYMS, VARS + 0x10000           # 65536 symbols
    .equ SYM_size, 48
    .equ SYMS_END, SYMS + 0x10000 * SYM_size
    .equ LOCAL_max, 4096                # definitions of each local label
    .equ LOCALS, SYMS_END               # 100 local labels
    .equ LOCALS_END, LOCALS + 100 * LOCAL_max * 32
    .equ JUMPS, LOCALS_END              # 65536 jumps
    .equ JUMPS_END, JUMPS + 0x10000 * 32
    .equ FRAGS, JUMPS_END               # 131072 frags
    .equ FRAGS_END, FRAGS + 0x20000 * 32
    .equ INPUT, FRAGS_END               # 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTBUF, INPUT_END              # 16 MiB of output
    .equ OUTBUF_END, OUTBUF + 0x1000000
    .equ ADDR, 0x10000                  # where ld places the output
    .equ SHSTRTAB_len, 36               # the section names' bytes (shstrtab)
    .equ SYS_read, 63
    .equ SYS_write, 64
    .equ SYS_exit, 93

    # a symbol: its name in the input, then its definition
    .equ S_name, 0
    .equ S_len, 8
    .equ S_value, 16
    .equ S_kind, 24
    .equ S_pass, 32
    .equ S_frag, 40
    # a definition of a local label
    .equ L_value, 0
    .equ L_kind, 8
    .equ L_pass, 16
    .equ L_frag, 24
    # a jump (a branch, j): the frag it ends, its target's definition, its
    # kind (1 j, unconditional; 2 compressed: c.beqz c.bnez c.j), its length
    .equ J_frag, 0
    .equ J_def, 8
    .equ J_kind, 16
    .equ J_len, 24
    # a frag of .text, as gas's: its address, its address after the last
    # round, its fixed bytes, then the jump that ends it, or 0
    .equ F_addr, 0
    .equ F_last, 8
    .equ F_fix, 16
    .equ F_jump, 24

    # the variables, at s0
    .equ V_pass, 0                      # the pass, 1 or 2
    .equ V_emit, 8                      # 1 in pass 2, which writes
    .equ V_sec, 16                      # the section: 1 .text 2 .rodata 3 .data 4 .bss
    .equ V_line, 24                     # the line's number
    .equ V_jump, 32                     # the next jump
    .equ V_nsym, 40                     # the next free symbol
    .equ V_exact, 48                    # 0 once an expression used a name not defined before it
    .equ V_known, 56                    # 0 once it used a name not defined at all
    .equ V_lstart, 64                   # the line's first byte
    .equ V_loc, 72                      # section s's location counter at V_loc + 8 * s
    .equ V_align, 112                   # its alignment
    .equ V_base, 152                    # its address (0 for s = 0, a number)
    .equ V_off, 192                     # its file offset
    .equ V_shstr, 232                   # the file offset of .shstrtab
    .equ V_shoff, 240                   # of the section headers
    .equ V_fend, 248                    # the file's size
    .equ V_tend, 256                    # the end of .rodata in the file: of the code segment
    .equ V_frag, 264                    # pass 1: the frag of .text being filled
    .equ V_foff, 272                    # its bytes so far
    .equ V_sret, 280                    # statement's return address
    .equ V_tsize, 288                   # .text's size, after relax
    .equ COUNTS, 400                    # local label n's definitions so far at COUNTS + 8 * n
    .equ NUMBUF, 1200                   # a decimal number, 24

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
    .dword VARS                         # p_vaddr: the variables, ..., the output
    .dword VARS                         # p_paddr: the same
    .dword 0                            # p_filesz: none, all zero
    .dword OUTBUF_END - VARS            # p_memsz: to the end of the output
    .dword 0x1000                       # p_align: a page

_start:                                 # read all of stdin into INPUT
    li      s0, VARS
    li      s2, INPUT                   # the end of what is read
read:
    li      a2, INPUT_END - 1           # a 0 stays after the input
    sub     a2, a2, s2                  # the room left
    beq     a2, zero, too_large
    li      a7, SYS_read
    li      a0, 0                       # fd 0, stdin
    mv      a1, s2                      # after what is read
    ecall
    blt     a0, zero, read_failed
    beq     a0, zero, read_all          # the end of stdin
    add     s2, s2, a0
    j       read
read_all:
    li      t0, SYMS                    # no symbols yet
    sd      t0, V_nsym(s0)
    li      t0, 2                       # .text aligned to 2 (gas, with RVC)
    sd      t0, V_align+8(s0)
    li      t0, 1                       # the others to 1, until .balign
    sd      t0, V_align+16(s0)
    sd      t0, V_align+24(s0)
    sd      t0, V_align+32(s0)
    sd      t0, V_pass(s0)              # pass 1: sizes, labels, jumps, frags
    jal     ra, pass
    jal     ra, relax                   # the jumps' lengths, the text labels
    jal     ra, layout
    li      t0, 2                       # pass 2 writes
    sd      t0, V_pass(s0)
    li      t0, 1
    sd      t0, V_emit(s0)
    jal     ra, pass
    jal     ra, headers
    li      a1, OUTBUF                  # write the output
    ld      a3, V_fend(s0)
    add     a3, a3, a1                  # its end
write:
    sub     a2, a3, a1                  # what is left
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

# A pass over the input, line by line.
pass:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    sd      zero, V_loc(s0)             # every section from 0
    sd      zero, V_loc+8(s0)
    sd      zero, V_loc+16(s0)
    sd      zero, V_loc+24(s0)
    sd      zero, V_loc+32(s0)
    addi    t0, s0, COUNTS              # no local labels yet
    addi    t1, s0, COUNTS + 800
pass_count:
    sd      zero, 0(t0)
    addi    t0, t0, 8
    bne     t0, t1, pass_count
    li      t0, JUMPS                   # from the first jump
    sd      t0, V_jump(s0)
    li      t0, FRAGS                   # and the first frag
    sd      t0, V_frag(s0)
    sd      zero, V_foff(s0)
    li      t0, 1                       # in .text
    sd      t0, V_sec(s0)
    sd      t0, V_line(s0)
    li      s1, INPUT
pass_line:
    bgeu    s1, s2, pass_end
    sd      s1, V_lstart(s0)
    jal     ra, statement
    ld      t0, V_line(s0)
    addi    t0, t0, 1
    sd      t0, V_line(s0)
    j       pass_line
pass_end:
    ld      t0, V_frag(s0)              # the last frag's fixed bytes
    ld      t1, V_foff(s0)
    sd      t1, F_fix(t0)
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

# One line, to after its newline: labels, then a directive or an
# instruction (each ends with end_line, which returns from statement).
statement:
    sd      ra, V_sret(s0)
statement_next:
    jal     ra, blanks
    lbu     a0, 0(s1)
    jal     ra, is_ident
    beq     a0, zero, end_line          # no name: only a comment may follow
    jal     ra, word                    # a1, a2
    lbu     t0, 0(s1)
    li      t1, 0x3a                    # ':': a label
    beq     t0, t1, label
    lbu     t0, 0(a1)
    li      t1, 0x2e                    # '.': a directive
    beq     t0, t1, directive
    j       insn
label:
    addi    s1, s1, 1
    jal     ra, define_label
    j       statement_next

end_line:                               # nothing but a comment until the newline, then after it
    jal     ra, blanks
    bgeu    s1, s2, end_line_done
    lbu     t0, 0(s1)
    li      t1, 0x23                    # '#'
    beq     t0, t1, end_comment
    li      t1, 0x0a                    # '\n'
    bne     t0, t1, junk
    addi    s1, s1, 1
end_line_done:
    ld      ra, V_sret(s0)
    ret
end_comment:
    addi    s1, s1, 1
    bgeu    s1, s2, end_line_done
    lbu     t0, 0(s1)
    li      t1, 0x0a
    bne     t0, t1, end_comment
    addi    s1, s1, 1
    j       end_line_done

blanks:                                 # skips spaces and tabs (uses t0, t1)
    lbu     t0, 0(s1)
    li      t1, 0x20                    # ' '
    beq     t0, t1, blanks_skip
    li      t1, 0x09                    # '\t'
    bne     t0, t1, blanks_done
blanks_skip:
    addi    s1, s1, 1
    j       blanks
blanks_done:
    ret

is_ident:                               # a0 = 1 if byte a0 is a letter, a digit, '_' or '.', else 0 (uses t0)
    li      t0, 0x2e                    # '.'
    beq     a0, t0, ident_yes
    li      t0, 0x5f                    # '_'
    beq     a0, t0, ident_yes
    addi    t0, a0, -0x30               # '0'-'9'
    sltiu   t0, t0, 10
    bne     t0, zero, ident_yes
    ori     t0, a0, 0x20                # 'A'-'Z' as 'a'-'z'
    addi    t0, t0, -0x61
    sltiu   t0, t0, 26
    bne     t0, zero, ident_yes
    li      a0, 0
    ret
ident_yes:
    li      a0, 1
    ret

word:                                   # a1, a2 = the name at s1, which moves after it (uses a0, t0, t5)
    mv      t5, ra
    mv      a1, s1
word_byte:
    lbu     a0, 0(s1)
    jal     ra, is_ident
    beq     a0, zero, word_end
    addi    s1, s1, 1
    j       word_byte
word_end:
    sub     a2, s1, a1
    mv      ra, t5
    ret

pack:                                   # a0 = name a1, a2 as 8 bytes (the first lowest), -1 if longer (uses t0, t1)
    li      a0, -1
    li      t0, 8
    bltu    t0, a2, pack_done
    li      a0, 0
    mv      t0, a2
pack_byte:                              # from the last byte to the first
    beq     t0, zero, pack_done
    slli    a0, a0, 8
    add     t1, a1, t0
    lbu     t1, -1(t1)
    or      a0, a0, t1
    addi    t0, t0, -1
    j       pack_byte
pack_done:
    ret

# The symbols.

define_label:                           # name a1, a2: here
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, digits                  # n: a local label
    beq     a3, zero, define_local
    jal     ra, here_def                # a3, a4, a6
    li      a5, 1                       # defined twice in a pass: an error
    jal     ra, define
    j       define_label_done
define_local:
    jal     ra, local_def
define_label_done:
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

here_def:                               # a3 = here's value, a4 its kind, a6 its frag (uses t0)
    ld      a4, V_sec(s0)
    slli    t0, a4, 3
    add     t0, t0, s0
    ld      a3, V_loc(t0)               # the section's location
    li      a6, 0
    li      t0, 1                       # pass 1 in .text: the frag and the
    bne     a4, t0, here_def_done       # offset in it
    ld      t0, V_emit(s0)
    bne     t0, zero, here_def_done
    ld      a3, V_foff(s0)
    ld      a6, V_frag(s0)
here_def_done:
    ret

define:                                 # a0 = symbol a1, a2, defined as a3 of kind a4, frag a6 (uses t0-t6)
    mv      t6, ra                      # a5 = 1: an error if defined in this pass
    jal     ra, find_sym
    bne     a0, zero, define_found
    jal     ra, sym_new
    j       define_set
define_found:
    beq     a5, zero, define_set
    ld      t0, S_pass(a0)
    ld      t1, V_pass(s0)
    beq     t0, t1, twice
define_set:
    sd      a3, S_value(a0)
    sd      a4, S_kind(a0)
    ld      t0, V_pass(s0)
    sd      t0, S_pass(a0)
    sd      a6, S_frag(a0)
    mv      ra, t6
    ret

sym_new:                                # a0 = a new symbol a1, a2, not yet defined (uses t0)
    ld      a0, V_nsym(s0)
    li      t0, SYMS_END
    bgeu    a0, t0, too_many_symbols
    addi    t0, a0, SYM_size
    sd      t0, V_nsym(s0)
    sd      a1, S_name(a0)
    sd      a2, S_len(a0)
    ret

find_sym:                               # a0 = symbol a1, a2, or 0 (uses t0-t5)
    li      a0, SYMS
    ld      t4, V_nsym(s0)
find_sym_next:
    bgeu    a0, t4, find_sym_none
    ld      t0, S_len(a0)               # the same length
    bne     t0, a2, find_sym_on
    ld      t1, S_name(a0)              # and the same bytes
    mv      t2, a1
    add     t3, a1, a2
find_sym_byte:
    beq     t2, t3, find_sym_found
    lbu     t0, 0(t1)
    lbu     t5, 0(t2)
    bne     t0, t5, find_sym_on
    addi    t1, t1, 1
    addi    t2, t2, 1
    j       find_sym_byte
find_sym_on:
    addi    a0, a0, SYM_size
    j       find_sym_next
find_sym_none:
    li      a0, 0
find_sym_found:
    ret

local_def:                              # local label a0: here (uses t0, t1, t6)
    li      t0, 100
    bgeu    a0, t0, bad_local
    slli    t0, a0, 3                   # its definitions so far: this one's number
    add     t0, t0, s0
    ld      a1, COUNTS(t0)
    addi    t1, a1, 1
    sd      t1, COUNTS(t0)
    mv      t6, ra
    jal     ra, local_entry
    jal     ra, here_def
    mv      ra, t6
    sd      a3, L_value(a0)
    sd      a4, L_kind(a0)
    ld      t0, V_pass(s0)
    sd      t0, L_pass(a0)
    sd      a6, L_frag(a0)
    ret

local_entry:                            # a0 = definition a1 of local label a0 (uses t0)
    li      t0, 100
    bgeu    a0, t0, bad_local
    li      t0, LOCAL_max               # (-1 too: below 0)
    bgeu    a1, t0, bad_local
    mul     a0, a0, t0
    add     a0, a0, a1
    slli    a0, a0, 5
    li      t0, LOCALS
    add     a0, a0, t0
    ret

local_ref:                              # a0 = the definition nf or nb of local label a0, by the last byte of a1, a2 (uses t0-t2)
    li      t0, 100
    bgeu    a0, t0, bad_local
    slli    t0, a0, 3                   # nf: the next definition of n
    add     t0, t0, s0
    ld      t2, COUNTS(t0)
    add     t1, a1, a2
    lbu     t1, -1(t1)
    li      t0, 0x66                    # 'f'
    beq     t1, t0, local_ref_entry
    addi    t2, t2, -1                  # nb: the last one
local_ref_entry:
    mv      a1, t2
    j       local_entry

digits:                                 # a0 = name a1, a2 when it is decimal digits only, a3 = 0; else a3 = 1 (uses t0-t2)
    li      a0, 0
    li      t0, 0
digits_next:
    bgeu    t0, a2, digits_done
    add     t1, a1, t0
    lbu     t1, 0(t1)
    addi    t1, t1, -0x30               # '0'-'9'
    li      t2, 10
    bgeu    t1, t2, digits_not
    mul     a0, a0, t2
    add     a0, a0, t1
    addi    t0, t0, 1
    j       digits_next
digits_done:
    li      a3, 0
    ret
digits_not:
    li      a3, 1
    ret

here:                                   # a0 = the address of the next byte, a1 its section (uses t0, t1)
    ld      a1, V_sec(s0)
    slli    t0, a1, 3
    add     t0, t0, s0
    ld      a0, V_loc(t0)
    ld      t1, V_base(t0)
    add     a0, a0, t1
    ret

# Expressions: a0 the value (with its section's address in pass 2), a1
# the kind; V_exact and V_known cleared as it says. Each level keeps its
# left side on the stack.

eval:                                   # the expression at s1
    li      t0, 1
    sd      t0, V_exact(s0)
    sd      t0, V_known(s0)
    j       expr

eval_number:                            # a0 = the expression at s1: a number known here
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, eval
    bne     a1, zero, not_number
    ld      t0, V_exact(s0)
    beq     t0, zero, not_number
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

expr:                                   # + -
    addi    sp, sp, -32
    sd      ra, 0(sp)
    jal     ra, expr_or
expr_more:
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x2b                    # '+'
    beq     t0, t1, expr_add
    li      t1, 0x2d                    # '-'
    beq     t0, t1, expr_sub
    ld      ra, 0(sp)
    addi    sp, sp, 32
    ret
expr_add:
    addi    s1, s1, 1
    sd      a0, 8(sp)
    sd      a1, 16(sp)
    jal     ra, expr_or
    ld      t0, 8(sp)                   # the left one's value
    ld      t1, 16(sp)                  # its kind
    add     a0, a0, t0
    beq     t1, zero, expr_more         # a number + x: x's kind
    bne     a1, zero, expr_kinds        # a label + a number: the label's
    mv      a1, t1
    j       expr_more
expr_sub:
    addi    s1, s1, 1
    sd      a0, 8(sp)
    sd      a1, 16(sp)
    jal     ra, expr_or
    ld      t0, 8(sp)
    ld      t1, 16(sp)
    sub     a0, t0, a0
    beq     a1, zero, expr_sub_kind     # x - a number: x's kind
    bne     a1, t1, expr_kinds          # two labels of a section: a number
    li      a1, 0
    j       expr_more
expr_sub_kind:
    mv      a1, t1
    j       expr_more
expr_kinds:
    jal     ra, kinds
    j       expr_more

kinds:                                  # an operation on labels it cannot do: fine while names are unknown (uses t0)
    li      a1, 0
    ld      t0, V_known(s0)
    beq     t0, zero, kinds_unknown
    la      a0, msg_kinds
    j       fail
kinds_unknown:
    ret

expr_or:                                # | & ^
    addi    sp, sp, -32
    sd      ra, 0(sp)
    jal     ra, expr_mul
expr_or_more:
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x7c                    # '|'
    beq     t0, t1, expr_or_op
    li      t1, 0x26                    # '&'
    beq     t0, t1, expr_or_op
    li      t1, 0x5e                    # '^'
    beq     t0, t1, expr_or_op
    ld      ra, 0(sp)
    addi    sp, sp, 32
    ret
expr_or_op:
    addi    s1, s1, 1
    sd      t0, 24(sp)                  # the operator
    sd      a0, 8(sp)
    sd      a1, 16(sp)
    jal     ra, expr_mul
    ld      t1, 16(sp)                  # numbers only
    or      t1, t1, a1
    beq     t1, zero, expr_or_numbers
    jal     ra, kinds
expr_or_numbers:
    li      a1, 0
    ld      t0, 8(sp)
    ld      t2, 24(sp)
    li      t1, 0x7c                    # '|'
    bne     t2, t1, expr_and
    or      a0, t0, a0
    j       expr_or_more
expr_and:
    li      t1, 0x26                    # '&'
    bne     t2, t1, expr_xor
    and     a0, t0, a0
    j       expr_or_more
expr_xor:
    xor     a0, t0, a0
    j       expr_or_more

expr_mul:                               # * / % << >>
    addi    sp, sp, -32
    sd      ra, 0(sp)
    jal     ra, expr_unary
expr_mul_more:
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x2a                    # '*'
    beq     t0, t1, expr_mul_op
    li      t1, 0x2f                    # '/'
    beq     t0, t1, expr_mul_op
    li      t1, 0x25                    # '%'
    beq     t0, t1, expr_mul_op
    li      t1, 0x3c                    # '<' of '<<'
    beq     t0, t1, expr_shift
    li      t1, 0x3e                    # '>' of '>>'
    beq     t0, t1, expr_shift
expr_mul_done:
    ld      ra, 0(sp)
    addi    sp, sp, 32
    ret
expr_shift:
    lbu     t1, 1(s1)                   # doubled
    bne     t1, t0, expr_mul_done
    addi    s1, s1, 1
expr_mul_op:
    addi    s1, s1, 1
    sd      t0, 24(sp)                  # the operator
    sd      a0, 8(sp)
    sd      a1, 16(sp)
    jal     ra, expr_unary
    ld      t1, 16(sp)                  # numbers only
    or      t1, t1, a1
    beq     t1, zero, expr_mul_numbers
    jal     ra, kinds
expr_mul_numbers:
    li      a1, 0
    ld      t0, 8(sp)                   # the left one
    ld      t2, 24(sp)
    li      t1, 0x2a                    # '*'
    bne     t2, t1, expr_div
    mul     a0, t0, a0
    j       expr_mul_more
expr_div:
    li      t1, 0x3c                    # '<<'
    beq     t2, t1, expr_shl
    li      t1, 0x3e                    # '>>'
    beq     t2, t1, expr_shr
    beq     a0, zero, expr_by_zero
    li      t1, 0x2f                    # '/': signed, as gas
    bne     t2, t1, expr_rem
    div     a0, t0, a0
    j       expr_mul_more
expr_rem:                               # '%'
    rem     a0, t0, a0
    j       expr_mul_more
expr_by_zero:                           # fine while names are unknown
    ld      t1, V_known(s0)
    bne     t1, zero, bad_expr
    j       expr_mul_more
expr_shl:
    sll     a0, t0, a0
    j       expr_mul_more
expr_shr:
    sra     a0, t0, a0
    j       expr_mul_more

expr_unary:                             # - ~ ( ), a number, a name, '.'
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, blanks
    lbu     a0, 0(s1)
    li      t0, 0x2d                    # '-'
    beq     a0, t0, unary_neg
    li      t0, 0x7e                    # '~'
    beq     a0, t0, unary_not
    li      t0, 0x28                    # '('
    beq     a0, t0, unary_paren
    jal     ra, is_ident
    beq     a0, zero, bad_expr
    jal     ra, word
    lbu     t0, 0(a1)
    addi    t0, t0, -0x30               # '0'-'9': a number
    li      t1, 10
    bltu    t0, t1, unary_number
    li      t0, 1                       # '.': here
    bne     a2, t0, unary_symbol
    lbu     t0, 0(a1)
    li      t1, 0x2e
    bne     t0, t1, unary_symbol
    jal     ra, here
    j       unary_done
unary_neg:
    addi    s1, s1, 1
    jal     ra, expr_unary
    neg     a0, a0
    j       unary_number_only
unary_not:
    addi    s1, s1, 1
    jal     ra, expr_unary
    not     a0, a0
unary_number_only:
    beq     a1, zero, unary_done
    jal     ra, kinds
    j       unary_done
unary_paren:
    addi    s1, s1, 1
    jal     ra, expr
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x29                    # ')'
    bne     t0, t1, bad_expr
    addi    s1, s1, 1
    j       unary_done
unary_symbol:
    jal     ra, find_sym
    beq     a0, zero, undefined
    addi    a0, a0, S_value             # its definition
    j       unary_def
unary_number:                           # digits, then b or f: a local label's
    add     t0, a1, a2
    lbu     t0, -1(t0)
    li      t1, 0x62                    # 'b'
    beq     t0, t1, unary_local
    li      t1, 0x66                    # 'f'
    beq     t0, t1, unary_local
unary_plain:
    jal     ra, number
    bne     a3, zero, bad_number
    li      a1, 0
    j       unary_done
unary_local:
    addi    a2, a2, -1
    jal     ra, digits
    addi    a2, a2, 1
    bne     a3, zero, unary_plain
    jal     ra, local_ref
unary_def:                              # definition a0: defined before, in this pass?
    ld      t0, 16(a0)                  # its pass
    beq     t0, zero, undefined         # none yet
    ld      t1, V_pass(s0)
    beq     t0, t1, unary_exact
    sd      zero, V_exact(s0)
unary_exact:
    ld      a1, 8(a0)                   # its kind
    ld      a0, 0(a0)                   # its value
    slli    t0, a1, 3                   # plus its section's address
    add     t0, t0, s0
    ld      t0, V_base(t0)
    add     a0, a0, t0
unary_done:
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret
undefined:                              # a name not yet defined: an error in pass 2
    ld      t0, V_emit(s0)
    bne     t0, zero, not_defined
    sd      zero, V_exact(s0)
    sd      zero, V_known(s0)
    li      a0, 0
    li      a1, 0
    j       unary_done

number:                                 # a0 = the number a1, a2: decimal, 0x hex, 0 octal; a3 = 1 if none (uses t0-t4)
    li      a0, 0
    li      t0, 0                       # the next digit
    li      t2, 10                      # the base
    lbu     t1, 0(a1)
    li      t3, 0x30                    # '0'
    bne     t1, t3, number_digits
    li      t3, 1
    beq     a2, t3, number_digits
    li      t2, 8                       # 0...: octal
    li      t0, 1
    lbu     t1, 1(a1)
    ori     t1, t1, 0x20
    li      t3, 0x78                    # 0x...: hex
    bne     t1, t3, number_digits
    li      t2, 16
    li      t0, 2
    li      t3, 2
    beq     a2, t3, number_bad
number_digits:
    bgeu    t0, a2, number_done
    add     t1, a1, t0
    lbu     t1, 0(t1)
    addi    t3, t1, -0x30               # '0'-'9'
    li      t4, 10
    bltu    t3, t4, number_digit
    ori     t3, t1, 0x20                # 'a'-'f', 'A'-'F': 10-15
    addi    t3, t3, -0x57
    bltu    t3, t4, number_bad
number_digit:
    bgeu    t3, t2, number_bad          # a digit of the base
    mul     a0, a0, t2
    add     a0, a0, t3
    addi    t0, t0, 1
    j       number_digits
number_done:
    li      a3, 0
    ret
number_bad:
    li      a3, 1
    ret

# Directives.

directive:                              # a1, a2: its name
    jal     ra, pack
    la      t0, directives
directive_next:
    ld      t1, 0(t0)
    beq     t1, zero, unknown_directive
    beq     t1, a0, directive_found
    addi    t0, t0, 16
    j       directive_next
directive_found:
    ld      t1, 8(t0)                   # its routine, from directives
    la      t2, directives
    add     t1, t1, t2
    jr      t1
unknown_directive:
    la      a0, msg_directive
    j       fail

d_globl:                                # .globl name: ld starts at _start anyway
    jal     ra, blanks
    jal     ra, word
    j       end_line

d_section:                              # .section name
    jal     ra, blanks
    jal     ra, word
    jal     ra, pack
    la      t0, sections
    li      t2, 1
d_section_next:
    ld      t1, 0(t0)
    beq     t1, a0, d_section_found
    addi    t0, t0, 8
    addi    t2, t2, 1
    li      t1, 4
    bgeu    t1, t2, d_section_next
    la      a0, msg_section
    j       fail
d_section_found:
    mv      a0, t2
    j       set_section
d_text:
    li      a0, 1
    j       set_section
d_data:
    li      a0, 3
    j       set_section
d_bss:
    li      a0, 4
set_section:
    sd      a0, V_sec(s0)
    j       end_line

d_equ:                                  # .equ name, expr
    jal     ra, blanks
    jal     ra, word
    mv      s8, a1
    mv      s9, a2
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x2c                    # ','
    bne     t0, t1, bad_syntax
    addi    s1, s1, 1
    jal     ra, eval
    slli    t0, a1, 3                   # kept in its section
    add     t0, t0, s0
    ld      t0, V_base(t0)
    sub     a3, a0, t0
    mv      a4, a1
    mv      a1, s8
    mv      a2, s9
    li      a5, 0                       # may be set again
    li      a6, 0
    jal     ra, define
    ld      t0, V_exact(s0)             # not known here: never a number known here
    bne     t0, zero, end_line
    sd      zero, S_pass(a0)
    j       end_line

d_balign:                               # .balign n: zeros up to a multiple of n
    jal     ra, eval_number
    beq     a0, zero, bad_align
    addi    t0, a0, -1                  # a power of 2
    and     t1, a0, t0
    bne     t1, zero, bad_align
    ld      t2, V_sec(s0)
    li      t1, 1                       # gas pads .text with nops: not done
    beq     t2, t1, bad_align
    slli    t2, t2, 3
    add     t2, t2, s0
    ld      t1, V_align(t2)             # the section's alignment
    bgeu    t1, a0, d_balign_pad
    sd      a0, V_align(t2)
d_balign_pad:
    ld      t1, V_loc(t2)
    neg     t3, t1
    and     t3, t3, t0                  # (-loc) & (n - 1)
    add     t1, t1, t3                  # zeros: the output is zero
    sd      t1, V_loc(t2)
    j       end_line

d_skip:                                 # .skip n: n zeros
    jal     ra, eval_number
    ld      t2, V_sec(s0)
    li      t1, 1                       # in .text: a frag's bytes too
    bne     t2, t1, d_skip_loc
    ld      t1, V_foff(s0)
    add     t1, t1, a0
    sd      t1, V_foff(s0)
d_skip_loc:
    slli    t2, t2, 3
    add     t2, t2, s0
    ld      t1, V_loc(t2)
    add     t1, t1, a0
    sd      t1, V_loc(t2)
    j       end_line

d_byte:                                 # .byte expr, ...
    li      s8, 1
    j       data
d_half:                                 # .half expr, ...
    li      s8, 2
    j       data
d_word:                                 # .word expr, ...
    li      s8, 4
    j       data
d_dword:                                # .dword expr, ...
    li      s8, 8
data:
    jal     ra, eval
    mv      a1, s8
    jal     ra, emit_n
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x2c                    # ','
    bne     t0, t1, end_line
    addi    s1, s1, 1
    j       data

d_asciz:                                # .asciz "text", ...: each with a 0 after it
    li      s8, 1
    j       ascii
d_ascii:                                # .ascii "text", ...
    li      s8, 0
ascii:
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x22                    # '"'
    bne     t0, t1, bad_syntax
    addi    s1, s1, 1
ascii_byte:
    bgeu    s1, s2, bad_string
    lbu     a0, 0(s1)
    li      t1, 0x0a                    # '\n'
    beq     a0, t1, bad_string
    addi    s1, s1, 1
    li      t1, 0x22                    # '"'
    beq     a0, t1, ascii_end
    li      t1, 0x5c                    # '\'
    bne     a0, t1, ascii_put
    lbu     a0, 0(s1)
    addi    s1, s1, 1
    li      t1, 0x6e                    # \n
    bne     a0, t1, ascii_not_n
    li      a0, 0x0a
    j       ascii_put
ascii_not_n:
    li      t1, 0x74                    # \t
    bne     a0, t1, ascii_not_t
    li      a0, 0x09
    j       ascii_put
ascii_not_t:
    addi    t2, a0, -0x30               # \ooo: up to 3 octal digits
    li      t1, 8
    bgeu    t2, t1, ascii_put           # else the byte itself
    mv      a0, t2
    li      t3, 2
ascii_octal:
    lbu     t2, 0(s1)
    addi    t2, t2, -0x30
    bgeu    t2, t1, ascii_put
    slli    a0, a0, 3
    add     a0, a0, t2
    addi    s1, s1, 1
    addi    t3, t3, -1
    bne     t3, zero, ascii_octal
ascii_put:
    jal     ra, emit_byte
    j       ascii_byte
ascii_end:
    beq     s8, zero, ascii_next
    li      a0, 0
    jal     ra, emit_byte
ascii_next:
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x2c                    # ','
    bne     t0, t1, end_line
    addi    s1, s1, 1
    j       ascii

# Output.

emit_byte:                              # the byte a0 at here, in pass 2; counted (uses t0-t2)
    ld      t0, V_sec(s0)
    slli    t1, t0, 3
    add     t1, t1, s0
    ld      t2, V_emit(s0)
    beq     t2, zero, emit_byte_count
    li      t2, 4                       # not in .bss
    beq     t0, t2, in_bss
    ld      t2, V_off(t1)
    ld      t0, V_loc(t1)
    add     t2, t2, t0
    li      t0, OUTBUF
    add     t2, t2, t0
    li      t0, OUTBUF_END
    bgeu    t2, t0, output_full
    sb      a0, 0(t2)
    ld      t0, V_sec(s0)
emit_byte_count:
    ld      t2, V_loc(t1)
    addi    t2, t2, 1
    sd      t2, V_loc(t1)
    li      t2, 1                       # in .text: a frag's byte too
    bne     t0, t2, emit_byte_done
    ld      t2, V_foff(s0)
    addi    t2, t2, 1
    sd      t2, V_foff(s0)
emit_byte_done:
    ret

emit16:                                 # the 2 bytes of a0 (uses a0-a2, t0-t2, t6)
    li      a1, 2
    j       emit_n
emit32:                                 # the 4 bytes of a0 (the same)
    li      a1, 4
emit_n:                                 # a1 bytes of a0, the low one first
    mv      t6, ra
    mv      a2, a0
emit_n_byte:
    mv      a0, a2
    jal     ra, emit_byte
    srli    a2, a2, 8
    addi    a1, a1, -1
    bne     a1, zero, emit_n_byte
    mv      ra, t6
    ret

frag_break:                             # pass 1: the frag ends, with jump a0 or none (0) (uses t0, t1)
    ld      t0, V_emit(s0)
    bne     t0, zero, frag_break_done
    ld      t0, V_frag(s0)
    ld      t1, V_foff(s0)
    sd      t1, F_fix(t0)
    sd      a0, F_jump(t0)
    addi    t0, t0, 32                  # the next one
    li      t1, FRAGS_END - 32
    bgeu    t0, t1, too_many_jumps
    sd      t0, V_frag(s0)
    sd      zero, V_foff(s0)
frag_break_done:
    ret

scatter:                                # a0 = value a0's pieces placed as table a1 says (uses a1, t0-t5)
    lbu     t0, 0(a1)                   # the pieces: from bit, bits, to bit
    addi    a1, a1, 1
    li      t1, 0                       # the field
scatter_piece:
    beq     t0, zero, scatter_done
    lbu     t2, 0(a1)
    lbu     t3, 1(a1)
    lbu     t4, 2(a1)
    srl     t2, a0, t2
    li      t5, 1                       # (1 << bits) - 1
    sll     t5, t5, t3
    addi    t5, t5, -1
    and     t2, t2, t5
    sll     t2, t2, t4
    or      t1, t1, t2
    addi    a1, a1, 3
    addi    t0, t0, -1
    j       scatter_piece
scatter_done:
    mv      a0, t1
    ret

fits:                                   # value a0 fits in a1 bits, signed, and is even; else an error (uses t0, t1)
    li      t0, 64
    sub     t0, t0, a1
    sll     t1, a0, t0
    sra     t1, t1, t0
    bne     t1, a0, out_of_range
    andi    t1, a0, 1
    bne     t1, zero, out_of_range
    ret

check12:                                # the immediate s7 fits in 12 bits, signed (uses t0, t1)
    li      t1, 2048
    add     t0, s7, t1
    li      t1, 4096
    bgeu    t0, t1, out_of_range
    ret

# The operands of an instruction.

p_reg:                                  # a0 = the register at s1
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, blanks
    jal     ra, word
    beq     a2, zero, bad_operand
    jal     ra, pack
    la      t0, registers               # x0-x31, then their ABI names, then fp
    li      t1, 0
p_reg_next:
    li      t2, 65
    beq     t1, t2, unknown_register
    ld      t2, 0(t0)
    beq     t2, a0, p_reg_found
    addi    t0, t0, 8
    addi    t1, t1, 1
    j       p_reg_next
p_reg_found:
    mv      a0, t1
    li      t2, 32
    bltu    a0, t2, p_reg_done
    addi    a0, a0, -32
    bltu    a0, t2, p_reg_done
    li      a0, 8                       # fp: s0
p_reg_done:
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

p_comma:                                # a ',' (uses t0, t1, t3)
    mv      t3, ra
    jal     ra, blanks
    mv      ra, t3
    lbu     t0, 0(s1)
    li      t1, 0x2c
    bne     t0, t1, bad_syntax
    addi    s1, s1, 1
    ret

p_rr:                                   # rd, rs: s5, s6
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, p_reg
    mv      s5, a0
    jal     ra, p_comma
    jal     ra, p_reg
    mv      s6, a0
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

p_rrr:                                  # rd, rs1, rs2: s5, s6, s7
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, p_rr
    jal     ra, p_comma
    jal     ra, p_reg
    mv      s7, a0
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

p_rri:                                  # rd, rs1, a number: s5, s6, s7
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, p_rr
    jal     ra, p_comma
    jal     ra, eval_number
    mv      s7, a0
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

p_rm:                                   # reg, offset(base): s5, s7, s6
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, p_reg
    mv      s5, a0
    jal     ra, p_comma
    jal     ra, eval_number
    mv      s7, a0
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x28                    # '('
    bne     t0, t1, bad_operand
    addi    s1, s1, 1
    jal     ra, p_reg
    mv      s6, a0
    jal     ra, blanks
    lbu     t0, 0(s1)
    li      t1, 0x29                    # ')'
    bne     t0, t1, bad_operand
    addi    s1, s1, 1
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

p_target:                               # a0 = the definition of the label at s1 (name, nb or nf)
    addi    sp, sp, -16
    sd      ra, 0(sp)
    jal     ra, blanks
    jal     ra, word
    beq     a2, zero, bad_operand
    lbu     t0, 0(a1)
    addi    t0, t0, -0x30               # a digit: a local label
    li      t1, 10
    bltu    t0, t1, p_target_local
    jal     ra, find_sym
    bne     a0, zero, p_target_sym
    jal     ra, sym_new                 # not yet defined
p_target_sym:
    addi    a0, a0, S_value
    j       p_target_done
p_target_local:
    add     t0, a1, a2
    lbu     t0, -1(t0)
    li      t1, 0x62                    # 'b'
    beq     t0, t1, p_target_nb
    li      t1, 0x66                    # 'f'
    bne     t0, t1, bad_operand
p_target_nb:
    addi    a2, a2, -1
    jal     ra, digits
    addi    a2, a2, 1
    bne     a3, zero, bad_operand
    jal     ra, local_ref
p_target_done:
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

# The instructions: the mnemonic's routine, with s3 its base bits and s4
# its other bits (from mnemonics). Each ends with end_line.

insn:                                   # a1, a2: the mnemonic
    jal     ra, pack
    la      t0, mnemonics
insn_next:
    ld      t1, 0(t0)
    beq     t1, zero, unknown_mnemonic
    beq     t1, a0, insn_found
    addi    t0, t0, 24
    j       insn_next
insn_found:
    lw      t1, 8(t0)                   # its routine, from mnemonics
    lwu     s3, 12(t0)
    ld      s4, 16(t0)
    la      t2, mnemonics
    add     t1, t1, t2
    jr      t1

enc_r:                                  # emits R: s3, rd s5, rs1 s6, rs2 s7
    slli    t0, s5, 7
    or      a0, s3, t0
    slli    t0, s6, 15
    or      a0, a0, t0
    slli    t0, s7, 20
    or      a0, a0, t0
    j       emit32
enc_i:                                  # emits I: s3, rd s5, rs1 s6, imm s7
    slli    t0, s5, 7
    or      a0, s3, t0
    slli    t0, s6, 15
    or      a0, a0, t0
    slli    t0, s7, 52                  # imm[11:0] to 31:20
    srli    t0, t0, 32
    or      a0, a0, t0
    j       emit32
enc_s:                                  # emits S: s3, rs1 s6, rs2 s5, imm s7
    slli    t0, s6, 15
    or      a0, s3, t0
    slli    t0, s5, 20
    or      a0, a0, t0
    andi    t0, s7, 0x1f                # imm[4:0] to 11:7
    slli    t0, t0, 7
    or      a0, a0, t0
    srli    t0, s7, 5                   # imm[11:5] to 31:25
    andi    t0, t0, 0x7f
    slli    t0, t0, 25
    or      a0, a0, t0
    j       emit32

plain_r:                                # the instruction as it is: R
    jal     ra, enc_r
    j       end_line
plain_i:                                # I
    jal     ra, enc_i
    j       end_line
plain_s:                                # S
    jal     ra, enc_s
    j       end_line
emit16_end:                             # a compressed one, a0
    jal     ra, emit16
    j       end_line
cr_emit:                                # CR: a0 | rd s5 at 11:7 | rs2 t0 at 6:2
    slli    t1, s5, 7
    or      a0, a0, t1
    slli    t0, t0, 2
    or      a0, a0, t0
    j       emit16_end
ca_emit:                                # CA: a0 | rd' s5 at 9:7 | rs2' t0 (x8-x15 as 0-7) at 4:2
    addi    t1, s5, -8
    slli    t1, t1, 7
    or      a0, a0, t1
    slli    t0, t0, 2
    or      a0, a0, t0
    j       emit16_end
ci_emit:                                # CI: a0 | rd s5 at 11:7 | imm s7 (imm[5] at 12, imm[4:0] at 6:2)
    mv      a3, a0
    slli    a0, s5, 7
    or      a3, a3, a0
    j       ci_imm
cbi_emit:                               # CB with an imm: a0 | rd' s5 at 9:7 | imm s7 as CI's
    mv      a3, a0
    addi    a0, s5, -8
    slli    a0, a0, 7
    or      a3, a3, a0
ci_imm:
    mv      a0, s7
    la      a1, k_ci
    jal     ra, scatter
    or      a0, a0, a3
    j       emit16_end
cl_emit:                                # CL, CS: a0 | t0 | base' s6 at 9:7 | reg' s5 at 4:2
    or      a0, a0, t0
    addi    t0, s6, -8
    slli    t0, t0, 7
    or      a0, a0, t0
    addi    t0, s5, -8
    slli    t0, t0, 2
    or      a0, a0, t0
    j       emit16_end

h_r:                                    # sll srl sra slt sltu mul div divu rem remu: R
    jal     ra, p_rrr
    j       plain_r

h_add:                                  # add: c.add, c.mv, else R
    jal     ra, p_rrr
    beq     s5, zero, plain_r           # each form wants rd and rs2 not x0
    bne     s6, s5, h_add_2
    beq     s7, zero, h_add_2
    mv      t0, s7                      # add rd, rd, rs: c.add rd, rs
    li      a0, 0x9002
    j       cr_emit
h_add_2:
    bne     s7, s5, h_add_3
    beq     s6, zero, h_add_3
    mv      t0, s6                      # add rd, rs, rd: c.add rd, rs
    li      a0, 0x9002
    j       cr_emit
h_add_3:
    bne     s6, zero, plain_r
    beq     s7, zero, plain_r
    mv      t0, s7                      # add rd, x0, rs: c.mv rd, rs
    li      a0, 0x8002
    j       cr_emit

h_sub:                                  # sub: c.sub rd', rd', rs2', else R
    jal     ra, p_rrr
    addi    t0, s5, -8
    li      t1, 8
    bgeu    t0, t1, plain_r
    bne     s6, s5, plain_r
    addi    t0, s7, -8
    bgeu    t0, t1, plain_r
    li      a0, 0x8c01
    j       ca_emit

h_cand:                                 # and or xor: c.and c.or c.xor (s4) rd', rd', rs' or rd', rs', rd'; else R
    jal     ra, p_rrr
    addi    t0, s5, -8
    li      t1, 8
    bgeu    t0, t1, plain_r
    bne     s6, s5, h_cand_2
    addi    t0, s7, -8
    bgeu    t0, t1, h_cand_2
    mv      a0, s4
    j       ca_emit
h_cand_2:
    bne     s7, s5, plain_r
    addi    t0, s6, -8
    bgeu    t0, t1, plain_r
    mv      a0, s4
    j       ca_emit

h_addi:                                 # addi, gas's order: c.addi4spn c.addi c.nop c.addi16sp c.li c.mv, else I
    jal     ra, p_rri
    jal     ra, check12
    addi    t0, s5, -8                  # c.addi4spn rd', sp, 4-1020 (4 n)
    li      t1, 8
    bgeu    t0, t1, h_addi_2
    li      t1, 2
    bne     s6, t1, h_addi_2
    beq     s7, zero, h_addi_2
    andi    t0, s7, 3
    bne     t0, zero, h_addi_2
    li      t1, 1024
    bgeu    s7, t1, h_addi_2
    mv      a0, s7
    la      a1, k_c4spn
    jal     ra, scatter
    addi    t0, s5, -8                  # 0x0000 | rd' at 4:2
    slli    t0, t0, 2
    or      a0, a0, t0
    j       emit16_end
h_addi_2:                               # c.addi rd, rd, -32..31 but 0, rd not x0
    bne     s5, s6, h_addi_5
    beq     s5, zero, h_addi_3
    beq     s7, zero, h_addi_4
    addi    t0, s7, 32
    li      t1, 64
    bgeu    t0, t1, h_addi_4
    li      a0, 0x0001
    j       ci_emit
h_addi_3:                               # c.nop: addi x0, x0, 0
    bne     s7, zero, h_addi_5
    li      a0, 0x0001
    j       emit16_end
h_addi_4:                               # c.addi16sp sp, sp, -512..496 (16 n) but 0
    li      t1, 2
    bne     s5, t1, h_addi_5
    beq     s7, zero, h_addi_5
    andi    t0, s7, 15
    bne     t0, zero, h_addi_5
    addi    t0, s7, 512
    li      t1, 1024
    bgeu    t0, t1, h_addi_5
    mv      a0, s7
    la      a1, k_c16sp
    jal     ra, scatter
    li      t0, 0x6101                  # rd sp at 11:7
    or      a0, a0, t0
    j       emit16_end
h_addi_5:                               # c.li rd, -32..31: addi rd, x0, imm
    bne     s6, zero, h_addi_6
    beq     s5, zero, plain_i
    addi    t0, s7, 32
    li      t1, 64
    bgeu    t0, t1, plain_i
    li      a0, 0x4001
    j       ci_emit
h_addi_6:                               # c.mv rd, rs: addi rd, rs, 0
    bne     s7, zero, plain_i
    beq     s5, zero, plain_i
    mv      t0, s6
    li      a0, 0x8002
    j       cr_emit

h_andi:                                 # andi: c.andi rd', rd', -32..31, else I
    jal     ra, p_rri
    jal     ra, check12
    addi    t0, s5, -8
    li      t1, 8
    bgeu    t0, t1, plain_i
    bne     s6, s5, plain_i
    addi    t0, s7, 32
    li      t1, 64
    bgeu    t0, t1, plain_i
    li      a0, 0x8801
    j       cbi_emit

h_i:                                    # ori xori slti sltiu: I
    jal     ra, p_rri
    jal     ra, check12
    j       plain_i

h_slli:                                 # slli: c.slli rd, rd, 1-63 (rd not x0), else I
    jal     ra, p_rri
    li      t1, 64                      # 0-63
    bgeu    s7, t1, out_of_range
    bne     s5, s6, plain_i
    beq     s5, zero, plain_i
    beq     s7, zero, plain_i
    li      a0, 0x0002
    j       ci_emit

h_srxi:                                 # srli srai: c.srli c.srai (s4) rd', rd', 1-63, else I
    jal     ra, p_rri
    li      t1, 64
    bgeu    s7, t1, out_of_range
    addi    t0, s5, -8
    li      t1, 8
    bgeu    t0, t1, plain_i
    bne     s6, s5, plain_i
    beq     s7, zero, plain_i
    mv      a0, s4
    j       cbi_emit

h_ld:                                   # ld: c.ldsp rd, 0-504(sp) (8 n, rd not x0), c.ld rd', 0-248(rs'), else I
    jal     ra, p_rm
    jal     ra, check12
    beq     s5, zero, h_ld_2
    li      t1, 2
    bne     s6, t1, h_ld_2
    andi    t0, s7, 7
    bne     t0, zero, h_ld_2
    li      t1, 505
    bgeu    s7, t1, h_ld_2
    mv      a0, s7
    la      a1, k_cldsp
    jal     ra, scatter
    li      t0, 0x6002
    or      a0, a0, t0
    slli    t0, s5, 7
    or      a0, a0, t0
    j       emit16_end
h_ld_2:
    addi    t0, s5, -8
    li      t1, 8
    bgeu    t0, t1, plain_i
    addi    t0, s6, -8
    bgeu    t0, t1, plain_i
    andi    t0, s7, 7
    bne     t0, zero, plain_i
    li      t1, 249
    bgeu    s7, t1, plain_i
    mv      a0, s7
    la      a1, k_cld
    jal     ra, scatter
    li      t0, 0x6000
    j       cl_emit

h_sd:                                   # sd: c.sdsp rs, 0-504(sp) (8 n), c.sd rs', 0-248(rs'), else S
    jal     ra, p_rm
    jal     ra, check12
    li      t1, 2
    bne     s6, t1, h_sd_2
    andi    t0, s7, 7
    bne     t0, zero, h_sd_2
    li      t1, 505
    bgeu    s7, t1, h_sd_2
    mv      a0, s7
    la      a1, k_csdsp
    jal     ra, scatter
    li      t0, 0xe002
    or      a0, a0, t0
    slli    t0, s5, 2                   # rs2 at 6:2
    or      a0, a0, t0
    j       emit16_end
h_sd_2:
    addi    t0, s5, -8
    li      t1, 8
    bgeu    t0, t1, plain_s
    addi    t0, s6, -8
    bgeu    t0, t1, plain_s
    andi    t0, s7, 7
    bne     t0, zero, plain_s
    li      t1, 249
    bgeu    s7, t1, plain_s
    mv      a0, s7
    la      a1, k_cld
    jal     ra, scatter
    li      t0, 0xe000
    j       cl_emit

h_load:                                 # lb lbu lh lhu lwu: I
    jal     ra, p_rm
    jal     ra, check12
    j       plain_i

h_store:                                # sb sh: S
    jal     ra, p_rm
    jal     ra, check12
    j       plain_s

h_br:                                   # beq bne blt bge bltu bgeu rs1, rs2, label
    jal     ra, p_reg
    mv      s6, a0
    jal     ra, p_comma
    jal     ra, p_reg
    mv      s7, a0
    jal     ra, p_comma
    j       branch
h_bz:                                   # beqz bnez bltz bgez rs, label: rs, x0
    jal     ra, p_reg
    mv      s6, a0
    li      s7, 0
    jal     ra, p_comma
    j       branch
h_bzr:                                  # blez bgtz rs, label: x0, rs
    jal     ra, p_reg
    mv      s7, a0
    li      s6, 0
    jal     ra, p_comma
    j       branch
h_brr:                                  # bgt ble bgtu bleu rs, rt, label: rt, rs
    jal     ra, p_reg
    mv      s7, a0
    jal     ra, p_comma
    jal     ra, p_reg
    mv      s6, a0
    jal     ra, p_comma
branch:                                 # s3 the B instruction, s4 its c.beqz or c.bnez (or 0), rs1 s6, rs2 s7
    li      s8, 0                       # compressed: rs1 x8-x15, rs2 x0
    beq     s4, zero, branch_target
    bne     s7, zero, branch_target
    addi    t0, s6, -8
    li      t1, 8
    bgeu    t0, t1, branch_target
    li      s8, 2
branch_target:
    jal     ra, p_target
    mv      s9, a0
    jal     ra, jump                    # pass 2: s10 its length, s11 the target minus here
    andi    t0, s8, 2
    beq     t0, zero, branch_full
    li      t0, 2
    beq     s10, t0, branch_c
    li      t0, 4
    beq     s10, t0, branch_4           # c.beqz rs: beq rs, x0
    li      t0, 0x2000                  # 6: c.bnez over a jal (c.beqz the other way)
    xor     s4, s4, t0
    li      a0, 6
    la      a1, k_cb
    jal     ra, scatter
    or      a0, a0, s4
    addi    t0, s6, -8
    slli    t0, t0, 7
    or      a0, a0, t0
    jal     ra, emit16
    addi    s11, s11, -2                # from the jal
    j       branch_jal
branch_c:                               # c.beqz, c.bnez rs', label
    mv      a0, s11
    li      a1, 9
    jal     ra, fits
    mv      a0, s11
    la      a1, k_cb
    jal     ra, scatter
    or      a0, a0, s4
    addi    t0, s6, -8
    slli    t0, t0, 7
    or      a0, a0, t0
    j       emit16_end
branch_full:
    li      t0, 4
    beq     s10, t0, branch_4
    li      a0, 8                       # 8: the other branch over a jal
    la      a1, k_b
    jal     ra, scatter
    li      t0, 0x1000                  # beq-bne blt-bge bltu-bgeu
    xor     t0, s3, t0
    or      a0, a0, t0
    slli    t0, s6, 15
    or      a0, a0, t0
    slli    t0, s7, 20
    or      a0, a0, t0
    jal     ra, emit32
    addi    s11, s11, -4
branch_jal:                             # jal x0, label: s11 from here
    mv      a0, s11
    li      a1, 21
    jal     ra, fits
    mv      a0, s11
    la      a1, k_j
    jal     ra, scatter
    ori     a0, a0, 0x6f
    jal     ra, emit32
    j       end_line
branch_4:                               # B: s3 | rs1 | rs2 | label
    mv      a0, s11
    li      a1, 13
    jal     ra, fits
    mv      a0, s11
    la      a1, k_b
    jal     ra, scatter
    or      a0, a0, s3
    slli    t0, s6, 15
    or      a0, a0, t0
    slli    t0, s7, 20
    or      a0, a0, t0
    jal     ra, emit32
    j       end_line

h_j:                                    # j label: c.j or jal x0
    li      s8, 3                       # unconditional, compressed
    jal     ra, p_target
    mv      s9, a0
    jal     ra, jump
    li      t0, 4
    beq     s10, t0, branch_jal
    mv      a0, s11
    li      a1, 12
    jal     ra, fits
    mv      a0, s11
    la      a1, k_cj
    jal     ra, scatter
    li      t0, 0xa001
    or      a0, a0, t0
    j       emit16_end

jump:                                   # a jump of kind s8 to definition s9: pass 1 records it and ends the line
    ld      t0, V_emit(s0)
    bne     t0, zero, jump_emit
    ld      a0, V_jump(s0)              # pass 1: a new jump
    li      t1, JUMPS_END
    bgeu    a0, t1, too_many_jumps
    ld      t1, V_frag(s0)
    sd      t1, J_frag(a0)
    sd      s9, J_def(a0)
    sd      s8, J_kind(a0)
    sd      zero, J_len(a0)
    addi    t1, a0, 32
    sd      t1, V_jump(s0)
    jal     ra, frag_break              # its frag ends with it
    j       end_line
jump_emit:                              # pass 2: s10 = its length, s11 = the target minus here
    ld      t0, V_jump(s0)
    ld      s10, J_len(t0)
    addi    t0, t0, 32
    sd      t0, V_jump(s0)
    ld      t0, 8(s9)                   # the target: in .text (relax checked it)
    slli    t0, t0, 3
    add     t0, t0, s0
    ld      t0, V_base(t0)
    ld      s11, 0(s9)
    add     s11, s11, t0
    mv      t2, ra
    jal     ra, here
    mv      ra, t2
    sub     s11, s11, a0
    ret

h_jr:                                   # jr rs: c.jr (rs not x0), else jalr x0, 0(rs)
    jal     ra, p_reg
    beq     a0, zero, h_jr_x0
    slli    a0, a0, 7
    li      t0, 0x8002
    or      a0, a0, t0
    j       emit16_end
h_jr_x0:
    li      a0, 0x67
    jal     ra, emit32
    j       end_line

h_jalr:                                 # jalr rs: c.jalr (rs not x0), else jalr ra, 0(rs)
    jal     ra, p_reg
    beq     a0, zero, h_jalr_x0
    slli    a0, a0, 7
    li      t0, 0x9002
    or      a0, a0, t0
    j       emit16_end
h_jalr_x0:
    li      a0, 0xe7
    jal     ra, emit32
    j       end_line

h_ret:                                  # ret: c.jr ra
    li      a0, 0x8082
    j       emit16_end

h_nop:                                  # nop: c.nop
    li      a0, 0x0001
    j       emit16_end

h_word:                                 # ecall: s3 as it is
    mv      a0, s3
    jal     ra, emit32
    j       end_line

h_mv:                                   # mv rd, rs: c.mv (both not x0), else addi rd, rs, 0
    jal     ra, p_rr
    li      s7, 0
    beq     s5, zero, plain_i
    beq     s6, zero, plain_i
    mv      t0, s6
    li      a0, 0x8002
    j       cr_emit

h_neg:                                  # neg rd, rs: sub rd, x0, rs
    jal     ra, p_rr
    mv      s7, s6
    li      s6, 0
    j       plain_r

h_snez:                                 # snez rd, rs: sltu rd, x0, rs
    jal     ra, p_rr
    mv      s7, s6
    li      s6, 0
    j       plain_r

h_not:                                  # not rd, rs: xori rd, rs, -1
    jal     ra, p_rr
    li      s7, -1
    j       plain_i

h_seqz:                                 # seqz rd, rs: sltiu rd, rs, 1
    jal     ra, p_rr
    li      s7, 1
    j       plain_i

h_li:                                   # li rd, n: as gas's opcode table, then its load_const
    jal     ra, p_reg
    mv      s5, a0
    jal     ra, p_comma
    jal     ra, eval_number
    mv      s7, a0
    li      s6, 0
    slli    t0, s7, 52                  # c.lui rd, n >> 12: n a multiple of 4096,
    bne     t0, zero, h_li_2            # 32 bits signed
    addiw   t0, s7, 0
    bne     t0, s7, h_li_2
    slli    a0, s7, 32
    srli    a0, a0, 44                  # (n as 32 bits unsigned) >> 12
    jal     ra, clui
    beq     a0, zero, end_line
h_li_2:                                 # c.li rd, -32..31 (rd not x0)
    beq     s5, zero, h_li_3
    addi    t0, s7, 32
    li      t1, 64
    bgeu    t0, t1, h_li_3
    li      a0, 0x4001
    j       ci_emit
h_li_3:                                 # addi rd, x0, -2048..2047
    li      t1, 2048
    add     t0, s7, t1
    li      t1, 4096
    bgeu    t0, t1, h_li_4
    li      s3, 0x13
    j       plain_i
h_li_4:                                 # lui rd, upper; addiw rd, rd, lower (if not 0)
    addiw   t0, s7, 0                   # 32 bits signed only
    bne     t0, s7, out_of_range
    slli    s8, s7, 52                  # lower: n's low 12 bits, signed
    srai    s8, s8, 52
    sub     a0, s7, s8                  # upper: the rest, as 32 bits unsigned >> 12
    slli    a0, a0, 32
    srli    a0, a0, 44
    mv      s9, a0
    jal     ra, clui
    beq     a0, zero, h_li_lower        # c.lui, else lui:
    slli    a0, s9, 12
    ori     a0, a0, 0x37
    slli    t0, s5, 7
    or      a0, a0, t0
    jal     ra, emit32
h_li_lower:                             # (rd x0: gas's addiw anyway, its hi_reg 0)
    bne     s8, zero, h_li_addi
    bne     s5, zero, end_line
h_li_addi:
    mv      s7, s8
    beq     s5, zero, h_li_addiw        # c.addiw rd, -32..31 (rd not x0)
    addi    t0, s7, 32
    li      t1, 64
    bgeu    t0, t1, h_li_addiw
    li      a0, 0x2001
    j       ci_emit
h_li_addiw:
    li      s3, 0x1b                    # addiw rd, rd, lower
    mv      s6, s5
    j       plain_i

clui:                                   # emits c.lui rd s5, a0 if gas would (a0 1-31 or 0xfffe0-0xfffff, rd not x0 or sp); a0 = 0 if it did, else 1
    beq     s5, zero, clui_no
    li      t0, 2
    beq     s5, t0, clui_no
    beq     a0, zero, clui_no
    li      t0, 0x20
    bltu    a0, t0, clui_yes
    li      t0, 0xfffe0
    bltu    a0, t0, clui_no
    li      t0, 0x100000
    bgeu    a0, t0, clui_no
clui_yes:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    la      a1, k_ci
    jal     ra, scatter
    li      t0, 0x6001
    or      a0, a0, t0
    slli    t0, s5, 7
    or      a0, a0, t0
    jal     ra, emit16
    ld      ra, 0(sp)
    addi    sp, sp, 16
    li      a0, 0
    ret
clui_no:
    li      a0, 1
    ret

h_la:                                   # la rd, label: auipc rd; addi rd, rd (a frag ends after the auipc)
    jal     ra, p_reg
    mv      s5, a0
    jal     ra, p_comma
    jal     ra, eval
    mv      s7, a0
    ld      t0, V_emit(s0)
    bne     t0, zero, h_la_emit
    li      a0, 0                       # pass 1: its 8 bytes
    jal     ra, emit32
    li      a0, 0
    jal     ra, frag_break
    li      a0, 0
    jal     ra, emit32
    j       end_line
h_la_emit:
    beq     a1, zero, bad_operand       # a label
    jal     ra, hi_lo                   # s9 auipc's, s10 the addi's
    li      a0, 0x17
    or      a0, a0, s9
    slli    t0, s5, 7
    or      a0, a0, t0
    jal     ra, emit32
    li      a0, 0x13
    or      a0, a0, s10
    slli    t0, s5, 7
    or      a0, a0, t0
    slli    t0, s5, 15
    or      a0, a0, t0
    jal     ra, emit32
    j       end_line

h_call:                                 # call label: auipc ra; jalr ra, ra (a frag ends after it)
    jal     ra, eval
    mv      s7, a0
    ld      t0, V_emit(s0)
    bne     t0, zero, h_call_emit
    li      a0, 0                       # pass 1: its 8 bytes
    jal     ra, emit32
    li      a0, 0
    jal     ra, emit32
    li      a0, 0
    jal     ra, frag_break
    j       end_line
h_call_emit:
    beq     a1, zero, bad_operand
    jal     ra, hi_lo
    li      a0, 0x97                    # auipc ra
    or      a0, a0, s9
    jal     ra, emit32
    li      a0, 0x80e7                  # jalr ra, lo(ra)
    or      a0, a0, s10
    jal     ra, emit32
    j       end_line

hi_lo:                                  # target s7 minus here: s9 = auipc's bits 31:12, s10 = the low 12 at 31:20 (uses t0-t2)
    mv      t2, ra
    jal     ra, here
    mv      ra, t2
    sub     t0, s7, a0                  # d
    li      t1, 0x800                   # d + 0x800: fits in 32 bits, signed
    add     t1, t0, t1
    addiw   a0, t1, 0
    bne     a0, t1, out_of_range
    srli    s9, t1, 12                  # its bits 31:12
    slli    s9, s9, 44
    srli    s9, s9, 32
    slli    s10, t0, 52                 # d's bits 11:0 to 31:20
    srli    s10, s10, 32
    ret

# Relaxing, as gas's relax_segment does it for .text (riscv's
# relaxed_branch_length): each round first gives every frag the address
# after those before it, a jump the length its target's address then
# says (a frag after it at its address of the last round, 0 in the
# first), then passes over the frags, each moving by what the jumps
# before it grew in this pass and its jump getting the length the
# addresses say, until a pass changes no length; rounds until no frag
# moves. A length: c.beqz, c.bnez and c.j 2 when the target is within
# -256..255 (c.j -2048..2047) bytes of the jump; else 4 when it is
# within -4096..4095 (a branch; j always), the compressed one as beq,
# bne or jal; else 6, c.bnez or c.beqz over a jal, or 8, the other
# branch over a jal. Then the text labels get their offsets in .text.

relax:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    li      a0, JUMPS                   # every target defined, in .text
    ld      a1, V_jump(s0)
relax_check:
    bgeu    a0, a1, relax_round
    ld      t0, J_def(a0)
    ld      t1, 16(t0)
    beq     t1, zero, undefined_target
    ld      t1, 8(t0)
    li      t2, 1
    bne     t1, t2, bad_target
    addi    a0, a0, 32
    j       relax_check
relax_round:
    li      a0, FRAGS
    ld      a1, V_frag(s0)              # the last frag
    li      a2, 0                       # the address
relax_guess:
    sd      a2, F_addr(a0)
    ld      t0, F_fix(a0)
    add     a2, a2, t0
    ld      a3, F_jump(a0)
    beq     a3, zero, relax_guess_next
    jal     ra, jlen                    # a4
    sd      a4, J_len(a3)
    add     a2, a2, a4
relax_guess_next:
    addi    a0, a0, 32
    bgeu    a1, a0, relax_guess
relax_pass:
    li      a5, 0                       # the growth so far
    li      a6, 0                       # 1 if a length changed
    li      a0, FRAGS
relax_frag:
    ld      t0, F_addr(a0)
    add     t0, t0, a5
    sd      t0, F_addr(a0)
    ld      a3, F_jump(a0)
    beq     a3, zero, relax_frag_next
    jal     ra, jlen
    ld      t0, J_len(a3)
    sub     t1, a4, t0
    beq     t1, zero, relax_frag_next
    sd      a4, J_len(a3)
    add     a5, a5, t1
    li      a6, 1
relax_frag_next:
    addi    a0, a0, 32
    bgeu    a1, a0, relax_frag
    bne     a6, zero, relax_pass
    li      a0, FRAGS                   # did a frag move since the last round?
    li      a6, 0
relax_moved:
    ld      t0, F_addr(a0)
    ld      t1, F_last(a0)
    beq     t0, t1, relax_moved_next
    sd      t0, F_last(a0)
    li      a6, 1
relax_moved_next:
    addi    a0, a0, 32
    bgeu    a1, a0, relax_moved
    bne     a6, zero, relax_round
    ld      t0, F_addr(a1)              # .text's size: the end of the last frag
    ld      t1, F_fix(a1)
    add     t0, t0, t1
    sd      t0, V_loc+8(s0)
    sd      t0, V_tsize(s0)
    li      a0, SYMS + S_value          # the text labels: frag + offset
    ld      a1, V_nsym(s0)
relax_syms:
    bgeu    a0, a1, relax_locals
    jal     ra, place_def
    addi    a0, a0, SYM_size
    j       relax_syms
relax_locals:
    li      a2, 0                       # local label n
relax_local:
    slli    t0, a2, 3                   # its definitions
    add     t0, t0, s0
    ld      a3, COUNTS(t0)
    li      t0, LOCAL_max * 32
    mul     a0, a2, t0
    li      t0, LOCALS
    add     a0, a0, t0
relax_local_def:
    beq     a3, zero, relax_local_next
    jal     ra, place_def
    addi    a0, a0, 32
    addi    a3, a3, -1
    j       relax_local_def
relax_local_next:
    addi    a2, a2, 1
    li      t0, 100
    bne     a2, t0, relax_local
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

place_def:                              # definition a0 of a text label: its offset in .text (uses t0, t1)
    ld      t0, 8(a0)
    li      t1, 1
    bne     t0, t1, place_def_done
    ld      t0, 16(a0)
    beq     t0, zero, place_def_done
    ld      t0, 24(a0)                  # its frag's address, plus its offset in it
    beq     t0, zero, place_def_done    # (none: an .equ)
    ld      t0, F_addr(t0)
    ld      t1, 0(a0)
    add     t1, t1, t0
    sd      t1, 0(a0)
place_def_done:
    ret

jlen:                                   # a4 = the length of jump a3 at the frags' addresses now (uses t0-t5)
    ld      t0, J_def(a3)               # the target's address
    ld      t1, 24(t0)
    ld      t1, F_addr(t1)
    ld      t2, 0(t0)
    add     t1, t1, t2
    ld      t0, J_frag(a3)              # minus the jump's
    ld      t2, F_addr(t0)
    ld      t3, F_fix(t0)
    add     t2, t2, t3
    sub     t1, t1, t2
    ld      t3, J_kind(a3)
    andi    t4, t3, 1                   # j: 4, a branch: 8, unless near
    li      a4, 8
    beq     t4, zero, jlen_c
    li      a4, 4
jlen_c:
    andi    t5, t3, 2                   # compressed: 2 within half its reach
    beq     t5, zero, jlen_4
    li      t5, 256
    beq     t4, zero, jlen_c_reach
    li      t5, 2048
jlen_c_reach:
    add     t2, t1, t5
    slli    t5, t5, 1
    bgeu    t2, t5, jlen_4
    li      a4, 2
    ret
jlen_4:                                 # within a branch's reach: 4
    li      t5, 4096
    add     t2, t1, t5
    li      t5, 8192
    bgeu    t2, t5, jlen_6
    li      a4, 4
    ret
jlen_6:                                 # beyond: c.b over a jal 6; j stays 4
    bne     t4, zero, jlen_done
    andi    t5, t3, 2
    beq     t5, zero, jlen_done
    li      a4, 6
jlen_done:
    ret

# The file, as ld lays it out.

layout:                                 # every section's file offset and address, as ld places them
    mv      t6, ra
    li      a0, 0xb0                    # after the ELF header and two program headers
    li      a1, 1
    jal     ra, place                   # .text
    li      a1, 2
    jal     ra, place                   # .rodata: the end of the code segment
    sd      a0, V_tend(s0)
    li      t0, ADDR                    # its address v
    add     a0, a0, t0
    mv      a3, a0
    li      t0, 0xfff
    and     a4, a0, t0
    li      a1, 0x1000
    jal     ra, alignup
    add     a0, a0, a4                  # the data segment from the next page on: v2
    sub     a5, a0, a3                  # v2 - v: its addresses after its file offsets
    ld      a1, V_align+24(s0)
    jal     ra, alignup
    sd      a0, V_base+24(s0)           # .data
    li      t0, ADDR
    sub     t1, a0, t0
    sub     t1, t1, a5
    sd      t1, V_off+24(s0)
    ld      t0, V_loc+24(s0)
    add     a0, a0, t0
    ld      a1, V_align+32(s0)
    jal     ra, alignup
    sd      a0, V_base+32(s0)           # .bss
    ld      a0, V_off+24(s0)            # its file offset, and .shstrtab's: the end
    ld      t0, V_loc+24(s0)            # of .data (ld's, though .bss be aligned)
    add     a0, a0, t0
    sd      a0, V_off+32(s0)
    sd      a0, V_shstr(s0)
    addi    a0, a0, SHSTRTAB_len        # then the section headers
    li      a1, 8
    jal     ra, alignup
    sd      a0, V_shoff(s0)
    addi    a0, a0, 6 * 64
    sd      a0, V_fend(s0)
    li      t0, OUTBUF_END - OUTBUF
    bltu    t0, a0, output_full
    mv      ra, t6
    ret

place:                                  # section a1 from file offset a0, aligned; a0 = its end (uses a1, a2, t0)
    slli    a2, a1, 3
    add     a2, a2, s0
    ld      a1, V_align(a2)
    mv      t0, ra
    jal     ra, alignup
    mv      ra, t0
    sd      a0, V_off(a2)
    li      t0, ADDR
    add     t0, t0, a0
    sd      t0, V_base(a2)
    ld      t0, V_loc(a2)
    add     a0, a0, t0
    ret

alignup:                                # a0 up to a multiple of a1, a power of 2 (uses a1)
    addi    a1, a1, -1
    add     a0, a0, a1
    not     a1, a1
    and     a0, a0, a1
    ret

headers:                                # the ELF header, the program headers, .shstrtab, the section headers
    addi    sp, sp, -16
    sd      ra, 0(sp)
    ld      t0, V_loc+8(s0)             # pass 2 wrote what relax said
    ld      t1, V_tsize(s0)
    bne     t0, t1, unstable
    addi    t0, s0, V_loc+8             # each section has bytes
    addi    t1, s0, V_loc+40
headers_bytes:
    ld      t2, 0(t0)
    beq     t2, zero, empty_section
    addi    t0, t0, 8
    bne     t0, t1, headers_bytes
    ld      a0, V_base+32(s0)           # ld's script ends .bss at a multiple of 8
    ld      t0, V_loc+32(s0)            # (its address)
    add     a0, a0, t0
    li      a1, 8
    jal     ra, alignup
    ld      t0, V_base+32(s0)
    sub     a0, a0, t0
    sd      a0, V_loc+32(s0)
    li      a0, OUTBUF
    la      a1, elf_headers
    li      a2, 0xb0
    jal     ra, copy
    la      a1, str_start               # e_entry: _start
    li      a2, 6
    jal     ra, find_sym
    beq     a0, zero, no_start
    ld      t0, S_pass(a0)
    beq     t0, zero, no_start
    ld      t0, S_kind(a0)
    slli    t0, t0, 3
    add     t0, t0, s0
    ld      t0, V_base(t0)
    ld      t1, S_value(a0)
    add     t1, t1, t0
    li      a0, OUTBUF
    sd      t1, 24(a0)
    ld      t0, V_shoff(s0)             # e_shoff
    sd      t0, 40(a0)
    ld      t0, V_tend(s0)              # the code: p_filesz, p_memsz
    sd      t0, 96(a0)
    sd      t0, 104(a0)
    ld      t0, V_off+24(s0)            # the data: p_offset
    sd      t0, 128(a0)
    ld      t0, V_base+24(s0)           # p_vaddr, p_paddr
    sd      t0, 136(a0)
    sd      t0, 144(a0)
    ld      t0, V_loc+24(s0)            # p_filesz: .data
    sd      t0, 152(a0)
    ld      t0, V_base+32(s0)           # p_memsz: to the end of .bss
    ld      t1, V_loc+32(s0)
    add     t0, t0, t1
    ld      t1, V_base+24(s0)
    sub     t0, t0, t1
    sd      t0, 160(a0)
    ld      a0, V_shstr(s0)             # .shstrtab
    li      t0, OUTBUF
    add     a0, a0, t0
    la      a1, shstrtab
    li      a2, SHSTRTAB_len
    jal     ra, copy
    ld      a0, V_shoff(s0)             # the section headers
    li      t0, OUTBUF
    add     a0, a0, t0
    mv      a3, a0
    la      a1, section_headers
    li      a2, 6 * 64
    jal     ra, copy
    li      a1, 1
headers_section:                        # 1-4: .text .rodata .data .bss
    addi    a3, a3, 64
    slli    a2, a1, 3
    add     a2, a2, s0
    ld      t0, V_base(a2)              # sh_addr
    sd      t0, 16(a3)
    ld      t0, V_off(a2)               # sh_offset
    sd      t0, 24(a3)
    ld      t0, V_loc(a2)               # sh_size
    sd      t0, 32(a3)
    ld      t0, V_align(a2)             # sh_addralign
    sd      t0, 48(a3)
    addi    a1, a1, 1
    li      t0, 5
    bne     a1, t0, headers_section
    ld      t0, V_shstr(s0)             # 5: .shstrtab's sh_offset
    sd      t0, 88(a3)
    ld      ra, 0(sp)
    addi    sp, sp, 16
    ret

copy:                                   # a2 bytes from a1 to a0 (uses a0-a2, t0)
    beq     a2, zero, copy_done
    lbu     t0, 0(a1)
    sb      t0, 0(a0)
    addi    a0, a0, 1
    addi    a1, a1, 1
    addi    a2, a2, -1
    j       copy
copy_done:
    ret

# The errors: asm: line N: what: the line.

junk:
    la      a0, msg_junk
    j       fail
twice:
    la      a0, msg_twice
    j       fail
too_many_symbols:
    la      a0, msg_symbols
    j       fail
too_many_jumps:
    la      a0, msg_jumps
    j       fail
bad_local:
    la      a0, msg_local
    j       fail
not_number:
    la      a0, msg_not_number
    j       fail
bad_number:
    la      a0, msg_number
    j       fail
bad_expr:
    la      a0, msg_expr
    j       fail
not_defined:
    la      a0, msg_undefined
    j       fail
bad_syntax:
    la      a0, msg_syntax
    j       fail
bad_align:
    la      a0, msg_align
    j       fail
bad_string:
    la      a0, msg_string
    j       fail
unknown_mnemonic:
    la      a0, msg_mnemonic
    j       fail
unknown_register:
    la      a0, msg_register
    j       fail
bad_operand:
    la      a0, msg_operand
    j       fail
out_of_range:
    la      a0, msg_range
    j       fail
in_bss:
    la      a0, msg_bss
fail:                                   # message a0 (a C string) about the line
    mv      s8, a0
    la      a1, msg_line
    jal     ra, eputs
    ld      a0, V_line(s0)
    jal     ra, eputn
    la      a1, msg_colon
    jal     ra, eputs
    mv      a1, s8
    jal     ra, eputs
    la      a1, msg_colon
    jal     ra, eputs
    ld      a1, V_lstart(s0)            # the line, to its newline
    mv      a2, a1
fail_line:
    bgeu    a2, s2, fail_line_end
    lbu     t0, 0(a2)
    li      t1, 0x0a
    beq     t0, t1, fail_line_end
    addi    a2, a2, 1
    j       fail_line
fail_line_end:
    sub     a2, a2, a1
    jal     ra, ewrite
    la      a1, msg_newline
    jal     ra, eputs
    li      a0, 1
    j       exit
undefined_target:
    la      a0, msg_undefined
    j       die
bad_target:
    la      a0, msg_target
    j       die
unstable:
    la      a0, msg_unstable
    j       die
output_full:
    la      a0, msg_full
    j       die
empty_section:
    la      a0, msg_empty
    j       die
no_start:
    la      a0, msg_start
    j       die
too_large:
    la      a0, msg_large
    j       die
read_failed:
    la      a0, msg_read
    j       die
write_failed:
    la      a0, msg_write
die:                                    # asm: message a0
    mv      s8, a0
    la      a1, msg_asm
    jal     ra, eputs
    mv      a1, s8
    jal     ra, eputs
    la      a1, msg_newline
    jal     ra, eputs
    li      a0, 1                       # status 1
exit:
    li      a7, SYS_exit
    ecall

eputs:                                  # writes the C string a1 to stderr
    mv      a2, a1
eputs_len:
    lbu     t0, 0(a2)
    beq     t0, zero, eputs_end
    addi    a2, a2, 1
    j       eputs_len
eputs_end:
    sub     a2, a2, a1
ewrite:                                 # writes a1, a2 to stderr
    li      a7, SYS_write
    li      a0, 2                       # fd 2, stderr
    ecall
    ret

eputn:                                  # writes a0 in decimal to stderr
    addi    a1, s0, NUMBUF + 24         # the last digit first, from the end
    mv      a2, a1
    li      t1, 10
eputn_digit:
    remu    t0, a0, t1
    addi    t0, t0, 0x30
    addi    a1, a1, -1
    sb      t0, 0(a1)
    divu    a0, a0, t1
    bne     a0, zero, eputn_digit
    sub     a2, a2, a1
    j       ewrite

# The tables, 8-byte aligned: names as 8 bytes, the first lowest, 0 after
# the name; a routine as its offset from its table.
    .balign 8
directives:                             # name, its routine
    .ascii ".ascii\0\0"
    .dword d_ascii - directives
    .ascii ".asciz\0\0"
    .dword d_asciz - directives
    .ascii ".balign\0"
    .dword d_balign - directives
    .ascii ".byte\0\0\0"
    .dword d_byte - directives
    .ascii ".half\0\0\0"
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
    .dword 0

sections:                               # 1-4
    .ascii ".text\0\0\0"
    .ascii ".rodata\0"
    .ascii ".data\0\0\0"
    .ascii ".bss\0\0\0\0"

registers:                              # x0-x31, then the ABI names of x0-x31, then fp (x8)
    .ascii "x0\0\0\0\0\0\0", "x1\0\0\0\0\0\0", "x2\0\0\0\0\0\0", "x3\0\0\0\0\0\0"
    .ascii "x4\0\0\0\0\0\0", "x5\0\0\0\0\0\0", "x6\0\0\0\0\0\0", "x7\0\0\0\0\0\0"
    .ascii "x8\0\0\0\0\0\0", "x9\0\0\0\0\0\0", "x10\0\0\0\0\0", "x11\0\0\0\0\0"
    .ascii "x12\0\0\0\0\0", "x13\0\0\0\0\0", "x14\0\0\0\0\0", "x15\0\0\0\0\0"
    .ascii "x16\0\0\0\0\0", "x17\0\0\0\0\0", "x18\0\0\0\0\0", "x19\0\0\0\0\0"
    .ascii "x20\0\0\0\0\0", "x21\0\0\0\0\0", "x22\0\0\0\0\0", "x23\0\0\0\0\0"
    .ascii "x24\0\0\0\0\0", "x25\0\0\0\0\0", "x26\0\0\0\0\0", "x27\0\0\0\0\0"
    .ascii "x28\0\0\0\0\0", "x29\0\0\0\0\0", "x30\0\0\0\0\0", "x31\0\0\0\0\0"
    .ascii "zero\0\0\0\0", "ra\0\0\0\0\0\0", "sp\0\0\0\0\0\0", "gp\0\0\0\0\0\0"
    .ascii "tp\0\0\0\0\0\0", "t0\0\0\0\0\0\0", "t1\0\0\0\0\0\0", "t2\0\0\0\0\0\0"
    .ascii "s0\0\0\0\0\0\0", "s1\0\0\0\0\0\0", "a0\0\0\0\0\0\0", "a1\0\0\0\0\0\0"
    .ascii "a2\0\0\0\0\0\0", "a3\0\0\0\0\0\0", "a4\0\0\0\0\0\0", "a5\0\0\0\0\0\0"
    .ascii "a6\0\0\0\0\0\0", "a7\0\0\0\0\0\0", "s2\0\0\0\0\0\0", "s3\0\0\0\0\0\0"
    .ascii "s4\0\0\0\0\0\0", "s5\0\0\0\0\0\0", "s6\0\0\0\0\0\0", "s7\0\0\0\0\0\0"
    .ascii "s8\0\0\0\0\0\0", "s9\0\0\0\0\0\0", "s10\0\0\0\0\0", "s11\0\0\0\0\0"
    .ascii "t3\0\0\0\0\0\0", "t4\0\0\0\0\0\0", "t5\0\0\0\0\0\0", "t6\0\0\0\0\0\0"
    .ascii "fp\0\0\0\0\0\0"

mnemonics:                              # name, its routine, its base bits, its other bits (a compressed form's)
    .ascii "add\0\0\0\0\0"
    .word h_add - mnemonics, 0x00000033
    .dword 0
    .ascii "sub\0\0\0\0\0"
    .word h_sub - mnemonics, 0x40000033
    .dword 0
    .ascii "and\0\0\0\0\0"
    .word h_cand - mnemonics, 0x00007033
    .dword 0x8c61                       # c.and
    .ascii "or\0\0\0\0\0\0"
    .word h_cand - mnemonics, 0x00006033
    .dword 0x8c41                       # c.or
    .ascii "xor\0\0\0\0\0"
    .word h_cand - mnemonics, 0x00004033
    .dword 0x8c21                       # c.xor
    .ascii "sll\0\0\0\0\0"
    .word h_r - mnemonics, 0x00001033
    .dword 0
    .ascii "srl\0\0\0\0\0"
    .word h_r - mnemonics, 0x00005033
    .dword 0
    .ascii "sra\0\0\0\0\0"
    .word h_r - mnemonics, 0x40005033
    .dword 0
    .ascii "slt\0\0\0\0\0"
    .word h_r - mnemonics, 0x00002033
    .dword 0
    .ascii "sltu\0\0\0\0"
    .word h_r - mnemonics, 0x00003033
    .dword 0
    .ascii "mul\0\0\0\0\0"
    .word h_r - mnemonics, 0x02000033
    .dword 0
    .ascii "div\0\0\0\0\0"
    .word h_r - mnemonics, 0x02004033
    .dword 0
    .ascii "divu\0\0\0\0"
    .word h_r - mnemonics, 0x02005033
    .dword 0
    .ascii "rem\0\0\0\0\0"
    .word h_r - mnemonics, 0x02006033
    .dword 0
    .ascii "remu\0\0\0\0"
    .word h_r - mnemonics, 0x02007033
    .dword 0
    .ascii "addi\0\0\0\0"
    .word h_addi - mnemonics, 0x00000013
    .dword 0
    .ascii "andi\0\0\0\0"
    .word h_andi - mnemonics, 0x00007013
    .dword 0
    .ascii "ori\0\0\0\0\0"
    .word h_i - mnemonics, 0x00006013
    .dword 0
    .ascii "xori\0\0\0\0"
    .word h_i - mnemonics, 0x00004013
    .dword 0
    .ascii "slti\0\0\0\0"
    .word h_i - mnemonics, 0x00002013
    .dword 0
    .ascii "sltiu\0\0\0"
    .word h_i - mnemonics, 0x00003013
    .dword 0
    .ascii "slli\0\0\0\0"
    .word h_slli - mnemonics, 0x00001013
    .dword 0
    .ascii "srli\0\0\0\0"
    .word h_srxi - mnemonics, 0x00005013
    .dword 0x8001                       # c.srli
    .ascii "srai\0\0\0\0"
    .word h_srxi - mnemonics, 0x40005013
    .dword 0x8401                       # c.srai
    .ascii "ld\0\0\0\0\0\0"
    .word h_ld - mnemonics, 0x00003003
    .dword 0
    .ascii "lbu\0\0\0\0\0"
    .word h_load - mnemonics, 0x00004003
    .dword 0
    .ascii "lb\0\0\0\0\0\0"
    .word h_load - mnemonics, 0x00000003
    .dword 0
    .ascii "lh\0\0\0\0\0\0"
    .word h_load - mnemonics, 0x00001003
    .dword 0
    .ascii "lhu\0\0\0\0\0"
    .word h_load - mnemonics, 0x00005003
    .dword 0
    .ascii "lwu\0\0\0\0\0"
    .word h_load - mnemonics, 0x00006003
    .dword 0
    .ascii "sd\0\0\0\0\0\0"
    .word h_sd - mnemonics, 0x00003023
    .dword 0
    .ascii "sb\0\0\0\0\0\0"
    .word h_store - mnemonics, 0x00000023
    .dword 0
    .ascii "sh\0\0\0\0\0\0"
    .word h_store - mnemonics, 0x00001023
    .dword 0
    .ascii "beq\0\0\0\0\0"
    .word h_br - mnemonics, 0x00000063
    .dword 0xc001                       # c.beqz
    .ascii "bne\0\0\0\0\0"
    .word h_br - mnemonics, 0x00001063
    .dword 0xe001                       # c.bnez
    .ascii "blt\0\0\0\0\0"
    .word h_br - mnemonics, 0x00004063
    .dword 0
    .ascii "bge\0\0\0\0\0"
    .word h_br - mnemonics, 0x00005063
    .dword 0
    .ascii "bltu\0\0\0\0"
    .word h_br - mnemonics, 0x00006063
    .dword 0
    .ascii "bgeu\0\0\0\0"
    .word h_br - mnemonics, 0x00007063
    .dword 0
    .ascii "beqz\0\0\0\0"
    .word h_bz - mnemonics, 0x00000063
    .dword 0xc001                       # c.beqz
    .ascii "bnez\0\0\0\0"
    .word h_bz - mnemonics, 0x00001063
    .dword 0xe001                       # c.bnez
    .ascii "bltz\0\0\0\0"
    .word h_bz - mnemonics, 0x00004063
    .dword 0
    .ascii "bgez\0\0\0\0"
    .word h_bz - mnemonics, 0x00005063
    .dword 0
    .ascii "blez\0\0\0\0"
    .word h_bzr - mnemonics, 0x00005063
    .dword 0
    .ascii "bgtz\0\0\0\0"
    .word h_bzr - mnemonics, 0x00004063
    .dword 0
    .ascii "bgt\0\0\0\0\0"
    .word h_brr - mnemonics, 0x00004063
    .dword 0
    .ascii "ble\0\0\0\0\0"
    .word h_brr - mnemonics, 0x00005063
    .dword 0
    .ascii "bgtu\0\0\0\0"
    .word h_brr - mnemonics, 0x00006063
    .dword 0
    .ascii "bleu\0\0\0\0"
    .word h_brr - mnemonics, 0x00007063
    .dword 0
    .ascii "j\0\0\0\0\0\0\0"
    .word h_j - mnemonics, 0
    .dword 0
    .ascii "jr\0\0\0\0\0\0"
    .word h_jr - mnemonics, 0
    .dword 0
    .ascii "jalr\0\0\0\0"
    .word h_jalr - mnemonics, 0
    .dword 0
    .ascii "ret\0\0\0\0\0"
    .word h_ret - mnemonics, 0
    .dword 0
    .ascii "call\0\0\0\0"
    .word h_call - mnemonics, 0
    .dword 0
    .ascii "la\0\0\0\0\0\0"
    .word h_la - mnemonics, 0
    .dword 0
    .ascii "li\0\0\0\0\0\0"
    .word h_li - mnemonics, 0
    .dword 0
    .ascii "mv\0\0\0\0\0\0"
    .word h_mv - mnemonics, 0x00000013
    .dword 0
    .ascii "neg\0\0\0\0\0"
    .word h_neg - mnemonics, 0x40000033
    .dword 0
    .ascii "not\0\0\0\0\0"
    .word h_not - mnemonics, 0x00004013
    .dword 0
    .ascii "seqz\0\0\0\0"
    .word h_seqz - mnemonics, 0x00003013
    .dword 0
    .ascii "snez\0\0\0\0"
    .word h_snez - mnemonics, 0x00003033
    .dword 0
    .ascii "ecall\0\0\0"
    .word h_word - mnemonics, 0x00000073
    .dword 0
    .ascii "nop\0\0\0\0\0"
    .word h_nop - mnemonics, 0
    .dword 0
    .dword 0

# The immediates' bit layouts, as the RISC-V manual draws the formats: the
# pieces, then each piece: the bit of the value it starts at, its bits,
# the bit of the instruction it goes to.
k_b:                                    # B: beq ...
    .byte 4, 1, 4, 8, 5, 6, 25, 11, 1, 7, 12, 1, 31
k_j:                                    # J: jal
    .byte 4, 1, 10, 21, 11, 1, 20, 12, 8, 12, 20, 1, 31
k_cb:                                   # CB: c.beqz c.bnez
    .byte 5, 1, 2, 3, 3, 2, 10, 5, 1, 2, 6, 2, 5, 8, 1, 12
k_cj:                                   # CJ: c.j
    .byte 8, 1, 3, 3, 4, 1, 11, 5, 1, 2, 6, 1, 7, 7, 1, 6, 8, 2, 9, 10, 1, 8, 11, 1, 12
k_ci:                                   # CI: c.addi c.li c.andi c.slli c.lui ...: imm[4:0] at 6:2, imm[5] at 12
    .byte 2, 0, 5, 2, 5, 1, 12
k_c16sp:                                # c.addi16sp: nzimm[4|6|8:7|5] at 6:2, [9] at 12
    .byte 5, 4, 1, 6, 6, 1, 5, 7, 2, 3, 5, 1, 2, 9, 1, 12
k_c4spn:                                # c.addi4spn: nzuimm[5:4|9:6|2|3] at 12:5
    .byte 4, 4, 2, 11, 6, 4, 7, 2, 1, 6, 3, 1, 5
k_cldsp:                                # c.ldsp: uimm[5] at 12, [4:3|8:6] at 6:2
    .byte 3, 5, 1, 12, 3, 2, 5, 6, 3, 2
k_csdsp:                                # c.sdsp: uimm[5:3|8:6] at 12:7
    .byte 2, 3, 3, 10, 6, 3, 7
k_cld:                                  # c.ld c.sd: uimm[5:3] at 12:10, [7:6] at 6:5
    .byte 2, 3, 3, 10, 6, 2, 5

    .balign 8
elf_headers:                            # ld's: the ELF header and the two program headers, 0xb0 bytes
    .byte   0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0    # e_ident: 0x7f "ELF", 64-bit, little endian, version 1, System V
    .byte   0, 0, 0, 0, 0, 0, 0, 0              # padding
    .half   2                           # e_type: ET_EXEC
    .half   0xf3                        # e_machine: EM_RISCV
    .word   1                           # e_version
    .dword  0                           # e_entry: _start (headers)
    .dword  0x40                        # e_phoff: the program headers follow
    .dword  0                           # e_shoff: the section headers (headers)
    .word   1                           # e_flags: EF_RISCV_RVC; the soft-float ABI
    .half   0x40                        # e_ehsize
    .half   0x38                        # e_phentsize
    .half   2                           # e_phnum
    .half   0x40                        # e_shentsize
    .half   6                           # e_shnum: 0 .text .rodata .data .bss .shstrtab
    .half   5                           # e_shstrndx: .shstrtab
    .word   1                           # p_type: PT_LOAD, the code
    .word   5                           # p_flags: R X
    .dword  0                           # p_offset: from the file's first byte
    .dword  ADDR                        # p_vaddr
    .dword  ADDR                        # p_paddr
    .dword  0                           # p_filesz: to the end of .rodata (headers)
    .dword  0                           # p_memsz: the same (headers)
    .dword  0x1000                      # p_align
    .word   1                           # p_type: PT_LOAD, the data
    .word   6                           # p_flags: R W
    .dword  0                           # p_offset: .data's (headers)
    .dword  0                           # p_vaddr: .data's address (headers)
    .dword  0                           # p_paddr: the same (headers)
    .dword  0                           # p_filesz: .data (headers)
    .dword  0                           # p_memsz: to the end of .bss (headers)
    .dword  0x1000                      # p_align

section_headers:                        # the six, without what headers fills in
    .dword  0, 0, 0, 0, 0, 0, 0, 0      # 0: none
    .word   0x0b, 1                     # 1: .text: its name, SHT_PROGBITS
    .dword  6, 0, 0, 0                  # SHF_ALLOC | SHF_EXECINSTR; addr, offset, size
    .word   0, 0                        # sh_link, sh_info
    .dword  0, 0                        # sh_addralign, sh_entsize
    .word   0x11, 1                     # 2: .rodata, SHT_PROGBITS
    .dword  2, 0, 0, 0                  # SHF_ALLOC
    .word   0, 0
    .dword  0, 0
    .word   0x19, 1                     # 3: .data, SHT_PROGBITS
    .dword  3, 0, 0, 0                  # SHF_WRITE | SHF_ALLOC
    .word   0, 0
    .dword  0, 0
    .word   0x1f, 8                     # 4: .bss, SHT_NOBITS
    .dword  3, 0, 0, 0                  # SHF_WRITE | SHF_ALLOC
    .word   0, 0
    .dword  0, 0
    .word   0x01, 3                     # 5: .shstrtab, SHT_STRTAB
    .dword  0, 0, 0, shstrtab_end - shstrtab  # no flags, address; offset; size
    .word   0, 0
    .dword  1, 0                        # sh_addralign 1

shstrtab:                               # the section names, as ld orders them
    .ascii  "\0.shstrtab\0.text\0.rodata\0.data\0.bss\0"
shstrtab_end:

str_start:      .ascii "_start"
msg_asm:        .asciz "asm: "
msg_line:       .asciz "asm: line "
msg_colon:      .asciz ": "
msg_newline:    .asciz "\n"
msg_junk:       .asciz "junk at the end of the line"
msg_twice:      .asciz "label defined twice"
msg_symbols:    .asciz "too many symbols"
msg_jumps:      .asciz "too many jumps"
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
msg_target:     .asciz "a branch or jump to another section"
msg_unstable:   .asciz "the text changed size after relaxing"
msg_bss:        .asciz "bytes in .bss"
msg_full:       .asciz "output too large"
msg_empty:      .asciz ".text, .rodata, .data and .bss each need bytes"
msg_start:      .asciz "no _start"
msg_large:      .asciz "input too large"
msg_read:       .asciz "read failed"
msg_write:      .asciz "write failed"
end:
