# asm for x86_64 Linux: the assembler of the seed. The fourth link of the
# bootstrap, built by M1 and hex2 from hosts/x86_64/asm.M1 (made from this
# file once by gen/mkhex.pl, a dev aid; the chain never reads this file).
# It assembles hosts/x86_64/ttpc.s, the readable seed, into the seed: the
# bytes binutils' as and ld make of it (as -mx86-used-note=no, ld -static
# -s -z noseparate-code), with no binutils.
#
#   asm < ttpc.s > ttpc
#
# The asm it reads: x86_64 GNU syntax (AT&T) as ttpc.s uses it.
#   lines      labels (name: and the local n: of 0-99, as 1b and 1f), then
#              a directive or an instruction; '#' starts a comment to the
#              end of the line
#   directives .equ name, expr  .quad expr, ...  .byte expr, ...
#              .ascii "text", ...  (escapes \n \t \ooo, \x as x)
#              .skip n  .balign n (not in .text)  .section name (.text
#              .rodata .data .bss)  .text .data .bss  .globl name  .code64
#   exprs      numbers (decimal, 0x hex, 0 octal), names, '.' (here), and
#              as gas: unary - ~, then * << >>, then | & ^, then + -, and
#              ( ); a label's address plus or minus a number, or two labels
#              of a section minus each other
#   operands   %reg (64, 32 and 8 bits, %rip), $expr, expr(%base,%index,
#              scale) with a base and as many of the rest as needed,
#              expr(%rip), and a jump's expr, or *%reg and *memory for an
#              indirect jmp or call
#   mnemonics  add or and sub xor cmp test mov (with q, l, b), movzbq
#              movzbl lea inc dec neg not mul div idiv shl shr sar imul,
#              setcc jcc jmp call ret nop syscall
# Each instruction is encoded as gas does: the short forms where gas uses
# them (imm8, disp8, the %al/%eax/%rax forms, shift by 1, no displacement
# when it is 0) and jumps as short as they can be: every jump starts short
# and grows to rel32 while it does not fit, pass after pass, as gas relaxes
# them. The output is the file ld makes: the ELF header, two program
# headers (the code: the headers, .text, .rodata; the data: .data, .bss),
# the sections, .shstrtab and six section headers. Each of .text .rodata
# .data .bss must have bytes.
#
# The input is read whole, then in passes: the sizing passes give every
# label its place (and every jump its size) until no jump grows, then the
# sections are laid out and the last pass writes them into the output,
# which is then written whole. On an error it says so on stderr with the
# line (asm: line N: what: the line) and ends with status 1; else with 0.
#
# One flat file, loaded at BASE by its first program header, read and
# run; the second maps the memory it writes, VARS to the end of OUTBUF.
# The registers:
#   %r12  the next byte of the input        %r13  the end of the input
#   %rbp  VARS, the variables               %rbx  the operand being parsed
# A symbol is 48 bytes (SYM_*), a local label's definition 24 (L_*), an
# operand 96 (O_*).

    .equ BASE, 0x600000
    .equ VARS, 0x700000                 # the variables, 64 KiB
    .equ SYMS, VARS + 0x10000           # 65536 symbols
    .equ SYM_size, 48
    .equ SYMS_END, SYMS + 0x10000 * SYM_size
    .equ LOCAL_max, 4096                # definitions of each local label
    .equ LOCALS, SYMS_END               # 100 local labels
    .equ LOCALS_END, LOCALS + 100 * LOCAL_max * 24
    .equ JUMPS, LOCALS_END              # a byte per jump: 1 when it is long
    .equ JUMPS_END, JUMPS + 0x100000
    .equ INPUT, JUMPS_END               # 16 MiB of input
    .equ INPUT_END, INPUT + 0x1000000
    .equ OUTBUF, INPUT_END              # 16 MiB of output
    .equ OUTBUF_END, OUTBUF + 0x1000000
    .equ ADDR, 0x400000                 # where ld places the output

    # a symbol: its name in the input, the value (in its section), the
    # kind (0 a number, else the section), the pass that defined it
    .equ S_name, 0
    .equ S_len, 8
    .equ S_value, 16
    .equ S_kind, 24
    .equ S_pass, 32
    # a definition of a local label
    .equ L_value, 0
    .equ L_kind, 8
    .equ L_pass, 16
    # an operand
    .equ O_kind, 0                      # 1 register, 2 $expr, 3 memory, 4 expr
    .equ O_reg, 8                       # a register: its number, 16 %rip
    .equ O_size, 16                     # its bytes
    .equ O_rexf, 24                     # 1 for %spl %bpl %sil %dil: a REX
    .equ O_val, 32                      # the expression's value
    .equ O_vkind, 40                    # its kind
    .equ O_exact, 48                    # 1 when it is a number known here
    .equ O_known, 56                    # 1 when all its names are defined
    .equ O_base, 64                     # memory: the base register, or -1
    .equ O_index, 72                    # the index register, or -1
    .equ O_scale, 80                    # log2 of the scale
    .equ O_ind, 88                      # 1 after '*': a jump's or call's register or memory

    # the variables, at %rbp
    .equ V_pass, 0                      # the pass, from 1
    .equ V_emit, 8                      # 1 in the last pass, which writes
    .equ V_changed, 16                  # 1 when this pass needs another
    .equ V_sec, 24                      # the section: 1 .text 2 .rodata 3 .data 4 .bss
    .equ V_line, 32                     # the line's number
    .equ V_jump, 40                     # the next jump's number
    .equ V_nsym, 48                     # the next free symbol
    .equ V_exact, 56                    # 0 once an expression used a name not defined before it
    .equ V_known, 64                    # 0 once it used a name not defined at all
    .equ V_lstart, 72                   # the line's first byte
    .equ V_loc, 80                      # section s's location counter at V_loc + 8 * s
    .equ V_align, 120                   # its alignment
    .equ V_base, 160                    # its address (0 for s = 0, a number)
    .equ V_off, 200                     # its file offset
    .equ V_shstr, 240                   # the file offset of .shstrtab
    .equ V_shoff, 248                   # of the section headers
    .equ V_fend, 256                    # the file's size
    .equ V_nops, 264                    # the instruction's operands
    .equ I_size, 272                    # its operand size: 1, 4, 8, 0 not yet known
    .equ I_rex, 280                     # its REX: 8 W, 4 R, 2 X, 1 B, 0x40 one without them
    .equ I_op, 288                      # its opcode, the first byte lowest
    .equ I_oplen, 296                   # the opcode's bytes
    .equ I_hasm, 304                    # 1 with a ModRM byte
    .equ I_modrm, 312                   # the ModRM byte
    .equ I_hass, 320                    # 1 with a SIB byte
    .equ I_sib, 328                     # the SIB byte
    .equ I_disp, 336                    # the displacement
    .equ I_dsize, 344                   # its bytes: 0, 1 or 4
    .equ I_rip, 352                     # 1 when it is from %rip
    .equ I_ripval, 360                  # then the address it is to
    .equ I_imm, 368                     # the immediate (or a jump's rel)
    .equ I_isize, 376                   # its bytes: 0, 1, 4 or 8
    .equ I_dpos, 384                    # where the displacement is in IBUF
    .equ I_ext, 392                     # the mnemonic's op: an opcode, its /digit, a condition
    .equ IBUF, 400                      # the instruction's bytes, 16
    .equ OP0, 416                       # the first operand
    .equ OP1, 512                       # the second
    .equ COUNTS, 608                    # local label n's definitions so far at COUNTS + 8 * n
    .equ NUMBUF, 1408                   # a decimal number, 24
    .equ V_tend, 1432                   # the end of .rodata in the file: of the code segment

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
    .quad VARS                          # p_vaddr: the variables to the output
    .quad VARS                          # p_paddr: the same
    .quad 0                             # p_filesz: none, all zero
    .quad OUTBUF_END - VARS             # p_memsz: to the end of the output
    .quad 0x1000                        # p_align: a page

_start:                                 # read all of stdin into INPUT
    mov     $VARS, %ebp
    mov     $INPUT, %r13d               # the end of what is read
read:
    mov     $INPUT_END - 1, %edx        # a 0 stays after the input
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
    mov     $SYMS, %eax                 # no symbols yet
    mov     %rax, V_nsym(%rbp)
    mov     $1, %ecx
init_align:                             # each section aligned to 1, until .balign
    movq    $1, V_align(%rbp,%rcx,8)
    inc     %ecx
    cmp     $4, %ecx
    jbe     init_align
    movq    $1, V_pass(%rbp)
sizing:                                 # sizing passes until no jump grows
    call    pass
    cmpq    $0, V_changed(%rbp)
    je      sized
    incq    V_pass(%rbp)
    jmp     sizing
sized:
    call    layout
    incq    V_pass(%rbp)                # the last pass writes
    movq    $1, V_emit(%rbp)
    call    pass
    call    headers
    mov     $OUTBUF, %esi               # write the output
    mov     V_fend(%rbp), %rbx
    add     %rsi, %rbx                  # its end
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

# A pass over the input, line by line. Pass 1 always needs another: its
# forward references were not yet known.
pass:
    xor     %eax, %eax
    mov     %rax, V_changed(%rbp)
    cmpq    $1, V_pass(%rbp)
    jne     pass_reset
    movq    $1, V_changed(%rbp)
pass_reset:
    mov     %rax, V_jump(%rbp)          # from the first jump
    mov     $4, %ecx
pass_loc:                               # every section from 0
    mov     %rax, V_loc(%rbp,%rcx,8)
    dec     %ecx
    jns     pass_loc
    mov     $99, %ecx
pass_count:                             # no local labels yet
    mov     %rax, COUNTS(%rbp,%rcx,8)
    dec     %ecx
    jns     pass_count
    movq    $1, V_sec(%rbp)             # in .text
    movq    $1, V_line(%rbp)
    mov     $INPUT, %r12d
pass_line:
    cmp     %r13, %r12
    jae     pass_end
    mov     %r12, V_lstart(%rbp)
    call    statement
    incq    V_line(%rbp)
    jmp     pass_line
pass_end:
    ret

# One line, to after its newline: labels, then a directive or an
# instruction (each ends with end_line).
statement:
    call    blanks
    movzbl  (%r12), %eax
    call    is_ident
    jc      end_line                    # no name: only a comment may follow
    call    word                        # %rsi, %rdx
    cmpb    $0x3a, (%r12)               # ':': a label
    je      label
    cmpb    $0x2e, (%rsi)               # '.': a directive
    je      directive
    jmp     insn
label:
    inc     %r12
    call    define_label
    jmp     statement

end_line:                               # nothing but a comment until the newline, then after it
    call    blanks
    cmp     %r13, %r12
    jae     end_line_done
    movzbl  (%r12), %eax
    cmp     $0x23, %al                  # '#'
    je      end_comment
    cmp     $0x0a, %al                  # '\n'
    jne     junk
    inc     %r12
end_line_done:
    ret
end_comment:
    inc     %r12
    cmp     %r13, %r12
    jae     end_line_done
    cmpb    $0x0a, (%r12)
    jne     end_comment
    inc     %r12
    ret

at_eol:                                 # CF at a comment or the end of the line
    call    blanks
    cmp     %r13, %r12
    jae     at_eol_yes
    movzbl  (%r12), %eax
    cmp     $0x23, %al                  # '#'
    je      at_eol_yes
    cmp     $0x0a, %al                  # '\n'
    je      at_eol_yes
    clc
    ret
at_eol_yes:
    stc
    ret

blanks:                                 # skips spaces and tabs (no register changes)
    cmpb    $0x20, (%r12)               # ' '
    je      blanks_skip
    cmpb    $0x09, (%r12)               # '\t'
    jne     blanks_done
blanks_skip:
    inc     %r12
    jmp     blanks
blanks_done:
    ret

is_ident:                               # CF unless %al is a letter, a digit, '_' or '.'
    cmp     $0x2e, %al                  # '.'
    je      ident_yes
    cmp     $0x5f, %al                  # '_'
    je      ident_yes
    cmp     $0x30, %al                  # below '0'
    jb      ident_no
    cmp     $0x39, %al                  # '0'-'9'
    jbe     ident_yes
    mov     %eax, %ecx
    or      $0x20, %cl                  # 'A'-'Z' as 'a'-'z'
    cmp     $0x61, %cl                  # 'a'
    jb      ident_no
    cmp     $0x7a, %cl                  # 'z'
    ja      ident_no
ident_yes:
    clc
    ret
ident_no:
    stc
    ret

word:                                   # %rsi, %rdx = the name at %r12, which moves after it
    mov     %r12, %rsi
word_byte:
    movzbl  (%r12), %eax
    call    is_ident
    jc      word_end
    inc     %r12
    jmp     word_byte
word_end:
    mov     %r12, %rdx
    sub     %rsi, %rdx
    ret

pack:                                   # %rax = name %rsi, %rdx as 8 bytes (the first lowest), -1 if longer
    mov     $-1, %rax
    cmp     $8, %rdx
    ja      pack_done
    xor     %eax, %eax
    mov     %rdx, %rcx
pack_byte:                              # from the last byte to the first
    test    %rcx, %rcx
    jz      pack_done
    shl     $8, %rax
    movzbl  -1(%rsi,%rcx), %edi
    or      %rdi, %rax
    dec     %rcx
    jmp     pack_byte
pack_done:
    ret

# The symbols.

define_label:                           # name %rsi, %rdx: here
    call    digits                      # n: a local label
    jnc     local_def
    call    here_offset                 # %rax, %rcx
    mov     $1, %r8d                    # defined twice in a pass: an error
define:                                 # symbol %rsi, %rdx = %rax of kind %rcx; %rdi = it
    push    %rax
    push    %rcx
    call    find_sym
    jnc     define_found
    mov     V_nsym(%rbp), %rdi          # a new one
    cmp     $SYMS_END, %rdi
    jae     too_many_symbols
    lea     SYM_size(%rdi), %rax
    mov     %rax, V_nsym(%rbp)
    mov     %rsi, S_name(%rdi)
    mov     %rdx, S_len(%rdi)
    jmp     define_set
define_found:
    test    %r8, %r8
    jz      define_set
    mov     V_pass(%rbp), %rax
    cmp     %rax, S_pass(%rdi)
    je      twice
define_set:
    pop     %rcx
    pop     %rax
    mov     %rax, S_value(%rdi)
    mov     %rcx, S_kind(%rdi)
    mov     V_pass(%rbp), %rax
    mov     %rax, S_pass(%rdi)
    ret

find_sym:                               # %rdi = symbol %rsi, %rdx; CF if none
    mov     $SYMS, %edi
find_sym_next:
    cmp     V_nsym(%rbp), %rdi
    jae     find_sym_none
    cmp     S_len(%rdi), %rdx           # the same length
    jne     find_sym_on
    push    %rsi
    push    %rdi
    mov     S_name(%rdi), %rdi
    mov     %rdx, %rcx
    repe cmpsb                          # and the same bytes
    pop     %rdi
    pop     %rsi
    je      find_sym_found
find_sym_on:
    add     $SYM_size, %rdi
    jmp     find_sym_next
find_sym_none:
    stc
    ret
find_sym_found:
    clc
    ret

local_def:                              # local label %rax: here
    cmp     $100, %rax
    jae     bad_local
    mov     COUNTS(%rbp,%rax,8), %rcx   # its definitions so far
    incq    COUNTS(%rbp,%rax,8)
    call    local_entry
    call    here_offset
    mov     %rax, L_value(%rdi)
    mov     %rcx, L_kind(%rdi)
    mov     V_pass(%rbp), %rax
    mov     %rax, L_pass(%rdi)
    ret

local_entry:                            # %rdi = definition %rcx of local label %rax
    cmp     $100, %rax
    jae     bad_local
    cmp     $LOCAL_max, %rcx            # (-1 too: below 0)
    jae     bad_local
    imul    $LOCAL_max, %rax, %rdi
    add     %rcx, %rdi
    imul    $24, %rdi, %rdi
    add     $LOCALS, %rdi
    ret

digits:                                 # %rax = name %rsi, %rdx when it is decimal digits only; else CF
    xor     %eax, %eax
    xor     %ecx, %ecx
digits_next:
    cmp     %rdx, %rcx
    jae     digits_done
    movzbl  (%rsi,%rcx), %edi
    sub     $0x30, %edi                 # '0'-'9'
    cmp     $9, %edi
    ja      digits_not
    imul    $10, %rax, %rax
    add     %rdi, %rax
    inc     %rcx
    jmp     digits_next
digits_done:
    clc
    ret
digits_not:
    stc
    ret

here_offset:                            # %rax = the location in section %rcx, the current one
    mov     V_sec(%rbp), %rcx
    mov     V_loc(%rbp,%rcx,8), %rax
    ret
here:                                   # %rax = the address of the next byte, %rcx its section
    call    here_offset
    add     V_base(%rbp,%rcx,8), %rax
    ret

# Expressions: %rax the value (with its section's address in the last
# pass), %rdx the kind; V_exact and V_known cleared as it says.

eval:                                   # the expression at %r12
    movq    $1, V_exact(%rbp)
    movq    $1, V_known(%rbp)
    jmp     expr

eval_number:                            # %rax = the expression at %r12: a number known here
    call    eval
    test    %rdx, %rdx
    jnz     not_number
    cmpq    $0, V_exact(%rbp)
    je      not_number
    ret

expr:                                   # + -
    call    expr_or
expr_more:
    call    blanks
    cmpb    $0x2b, (%r12)               # '+'
    je      expr_add
    cmpb    $0x2d, (%r12)               # '-'
    je      expr_sub
    ret
expr_add:
    inc     %r12
    push    %rax
    push    %rdx
    call    expr_or
    pop     %rcx                        # the left one's kind
    pop     %rsi                        # its value
    add     %rsi, %rax
    test    %rcx, %rcx                  # a number + x: x's kind
    jz      expr_more
    test    %rdx, %rdx                  # a label + a number: the label's
    jnz     expr_kinds
    mov     %rcx, %rdx
    jmp     expr_more
expr_sub:
    inc     %r12
    push    %rax
    push    %rdx
    call    expr_or
    pop     %rcx
    pop     %rsi
    sub     %rax, %rsi
    mov     %rsi, %rax
    test    %rdx, %rdx                  # x - a number: x's kind
    jz      expr_sub_kind
    cmp     %rcx, %rdx                  # two labels of a section: a number
    jne     expr_kinds
    xor     %edx, %edx
    jmp     expr_more
expr_sub_kind:
    mov     %rcx, %rdx
    jmp     expr_more
expr_kinds:
    call    kinds
    jmp     expr_more

kinds:                                  # an operation on labels it cannot do: fine while names are unknown
    xor     %edx, %edx
    cmpq    $0, V_known(%rbp)
    je      kinds_unknown
    lea     msg_kinds(%rip), %rsi
    jmp     fail
kinds_unknown:
    ret

expr_or:                                # | & ^
    call    expr_mul
expr_or_more:
    call    blanks
    movzbl  (%r12), %ecx
    cmp     $0x7c, %ecx                 # '|'
    je      expr_or_op
    cmp     $0x26, %ecx                 # '&'
    je      expr_or_op
    cmp     $0x5e, %ecx                 # '^'
    je      expr_or_op
    ret
expr_or_op:
    inc     %r12
    push    %rcx                        # the operator
    push    %rax
    push    %rdx
    call    expr_mul
    pop     %rcx
    pop     %rsi
    pop     %rdi
    or      %rdx, %rcx                  # numbers only
    jz      expr_or_numbers
    call    kinds
expr_or_numbers:
    xor     %edx, %edx
    cmp     $0x7c, %edi                 # '|'
    jne     expr_and
    or      %rsi, %rax
    jmp     expr_or_more
expr_and:
    cmp     $0x26, %edi                 # '&'
    jne     expr_xor
    and     %rsi, %rax
    jmp     expr_or_more
expr_xor:
    xor     %rsi, %rax
    jmp     expr_or_more

expr_mul:                               # * << >>
    call    expr_unary
expr_mul_more:
    call    blanks
    movzbl  (%r12), %ecx
    cmp     $0x2a, %ecx                 # '*'
    je      expr_mul_op
    cmp     $0x3c, %ecx                 # '<' of '<<'
    je      expr_shift
    cmp     $0x3e, %ecx                 # '>' of '>>'
    je      expr_shift
    ret
expr_shift:
    cmp     %cl, 1(%r12)                # doubled
    jne     expr_mul_done
    inc     %r12
expr_mul_op:
    inc     %r12
    push    %rcx
    push    %rax
    push    %rdx
    call    expr_unary
    pop     %rcx
    pop     %rsi
    pop     %rdi
    or      %rdx, %rcx                  # numbers only
    jz      expr_mul_numbers
    call    kinds
expr_mul_numbers:
    xor     %edx, %edx
    cmp     $0x2a, %edi                 # '*'
    jne     expr_shl
    imul    %rsi, %rax
    jmp     expr_mul_more
expr_shl:
    mov     %eax, %ecx
    cmp     $0x3c, %edi                 # '<<'
    jne     expr_shr
    shl     %cl, %rsi
    mov     %rsi, %rax
    jmp     expr_mul_more
expr_shr:                               # '>>'
    sar     %cl, %rsi
    mov     %rsi, %rax
    jmp     expr_mul_more
expr_mul_done:
    ret

expr_unary:                             # - ~ ( ), a number, a name, '.'
    call    blanks
    movzbl  (%r12), %eax
    cmp     $0x2d, %al                  # '-'
    je      unary_neg
    cmp     $0x7e, %al                  # '~'
    je      unary_not
    cmp     $0x28, %al                  # '('
    je      unary_paren
    call    is_ident
    jc      bad_expr
    call    word
    movzbl  (%rsi), %eax
    sub     $0x30, %eax                 # '0'-'9': a number
    cmp     $9, %eax
    jbe     unary_number
    cmp     $1, %rdx                    # '.': here
    jne     unary_symbol
    cmpb    $0x2e, (%rsi)
    jne     unary_symbol
    call    here
    mov     %rcx, %rdx
    ret
unary_neg:
    inc     %r12
    call    expr_unary
    neg     %rax
    jmp     unary_number_only
unary_not:
    inc     %r12
    call    expr_unary
    not     %rax
unary_number_only:
    test    %rdx, %rdx
    jz      unary_done
    call    kinds
unary_done:
    ret
unary_paren:
    inc     %r12
    call    expr
    call    blanks
    cmpb    $0x29, (%r12)               # ')'
    jne     bad_expr
    inc     %r12
    ret
unary_symbol:
    call    find_sym
    jc      undefined
    mov     S_pass(%rdi), %rcx          # defined before, in this pass?
    cmp     V_pass(%rbp), %rcx
    je      unary_symbol_exact
    movq    $0, V_exact(%rbp)
unary_symbol_exact:
    mov     S_kind(%rdi), %rdx
    mov     S_value(%rdi), %rax
    add     V_base(%rbp,%rdx,8), %rax
    ret
unary_number:                           # digits, then b or f: a local label's
    movzbl  -1(%rsi,%rdx), %ecx
    cmp     $0x62, %ecx                 # 'b'
    je      unary_local
    cmp     $0x66, %ecx                 # 'f'
    je      unary_local
unary_plain:
    call    number
    jc      bad_number
    xor     %edx, %edx
    ret
unary_local:
    push    %rdx
    dec     %rdx
    call    digits
    pop     %rdx
    jc      unary_plain
    cmp     $100, %rax
    jae     bad_local
    mov     COUNTS(%rbp,%rax,8), %rcx   # nf: the next definition of n
    cmpb    $0x66, -1(%rsi,%rdx)        # 'f'
    je      unary_local_entry
    dec     %rcx                        # nb: the last one
unary_local_entry:
    call    local_entry
    mov     L_pass(%rdi), %rcx
    test    %rcx, %rcx                  # not yet defined
    jz      undefined
    cmp     V_pass(%rbp), %rcx
    je      unary_local_exact
    movq    $0, V_exact(%rbp)
unary_local_exact:
    mov     L_kind(%rdi), %rdx
    mov     L_value(%rdi), %rax
    add     V_base(%rbp,%rdx,8), %rax
    ret

undefined:                              # a name not yet defined: an error in the last pass
    cmpq    $0, V_emit(%rbp)
    jne     not_defined
    xor     %eax, %eax
    mov     %rax, V_exact(%rbp)
    mov     %rax, V_known(%rbp)
    xor     %edx, %edx
    ret

number:                                 # %rax = the number %rsi, %rdx: decimal, 0x hex, 0 octal; CF if none
    xor     %eax, %eax
    xor     %ecx, %ecx                  # the next digit
    mov     $10, %r8d                   # the base
    cmpb    $0x30, (%rsi)               # '0'
    jne     number_digits
    cmp     $1, %rdx
    je      number_digits
    mov     $8, %r8d                    # 0...: octal
    inc     %ecx
    movzbl  1(%rsi), %edi
    or      $0x20, %edi
    cmp     $0x78, %edi                 # 0x...: hex
    jne     number_digits
    mov     $16, %r8d
    inc     %ecx
    cmp     $2, %rdx
    je      number_bad
number_digits:
    cmp     %rdx, %rcx
    jae     number_done
    movzbl  (%rsi,%rcx), %edi
    sub     $0x30, %edi                 # '0'-'9'
    cmp     $9, %edi
    jbe     number_digit
    movzbl  (%rsi,%rcx), %edi
    or      $0x20, %edi                 # 'a'-'f', 'A'-'F': 10-15
    sub     $0x57, %edi
    cmp     $10, %edi
    jb      number_bad
number_digit:
    cmp     %r8, %rdi                   # a digit of the base
    jae     number_bad
    imul    %r8, %rax
    add     %rdi, %rax
    inc     %rcx
    jmp     number_digits
number_done:
    clc
    ret
number_bad:
    stc
    ret

# Directives.

directive:                              # %rsi, %rdx: its name
    call    pack
    lea     directives(%rip), %rdi
    cmp     (%rdi), %rax
    je      d_ascii
    cmp     8(%rdi), %rax
    je      d_balign
    cmp     16(%rdi), %rax
    je      d_byte
    cmp     24(%rdi), %rax
    je      d_code64
    cmp     32(%rdi), %rax
    je      d_equ
    cmp     40(%rdi), %rax
    je      d_globl
    cmp     48(%rdi), %rax
    je      d_quad
    cmp     56(%rdi), %rax
    je      d_section
    cmp     64(%rdi), %rax
    je      d_skip
    cmp     72(%rdi), %rax
    je      d_text
    cmp     80(%rdi), %rax
    je      d_data
    cmp     88(%rdi), %rax
    je      d_bss
    lea     msg_directive(%rip), %rsi
    jmp     fail

d_code64:                               # .code64: the only mode
    jmp     end_line

d_globl:                                # .globl name: ld starts at _start anyway
    call    blanks
    call    word
    jmp     end_line

d_section:                              # .section name
    call    blanks
    call    word
    call    pack
    lea     sections(%rip), %rdi
    mov     $1, %ecx
d_section_next:
    cmp     (%rdi), %rax
    je      d_section_found
    add     $8, %rdi
    inc     %ecx
    cmp     $4, %ecx
    jbe     d_section_next
    lea     msg_section(%rip), %rsi
    jmp     fail
d_section_found:
    mov     %ecx, %eax
    jmp     set_section
d_text:
    mov     $1, %eax
    jmp     set_section
d_data:
    mov     $3, %eax
    jmp     set_section
d_bss:
    mov     $4, %eax
set_section:
    mov     %rax, V_sec(%rbp)
    jmp     end_line

d_equ:                                  # .equ name, expr
    call    blanks
    call    word
    push    %rsi
    push    %rdx
    call    blanks
    cmpb    $0x2c, (%r12)               # ','
    jne     bad_syntax
    inc     %r12
    call    eval
    mov     %rdx, %rcx
    sub     V_base(%rbp,%rcx,8), %rax   # kept in its section
    pop     %rdx
    pop     %rsi
    xor     %r8d, %r8d                  # may be set again
    call    define
    cmpq    $0, V_exact(%rbp)           # not known here: never a number known here
    jne     end_line
    movq    $0, S_pass(%rdi)
    jmp     end_line

d_balign:                               # .balign n: zeros up to a multiple of n
    call    eval_number
    test    %rax, %rax
    jz      bad_align
    lea     -1(%rax), %rcx              # a power of 2
    test    %rax, %rcx
    jnz     bad_align
    mov     V_sec(%rbp), %rdx
    cmp     $1, %edx                    # gas pads .text with nops: not done
    je      bad_align
    cmp     V_align(%rbp,%rdx,8), %rax  # the section's alignment
    jbe     d_balign_pad
    mov     %rax, V_align(%rbp,%rdx,8)
d_balign_pad:
    mov     V_loc(%rbp,%rdx,8), %rcx
    neg     %rcx
    dec     %rax
    and     %rax, %rcx                  # (-loc) & (n - 1)
    add     %rcx, V_loc(%rbp,%rdx,8)    # zeros: the output is zero
    jmp     end_line

d_skip:                                 # .skip n: n zeros
    call    eval_number
    mov     V_sec(%rbp), %rdx
    add     %rax, V_loc(%rbp,%rdx,8)
    jmp     end_line

d_byte:                                 # .byte expr, ...
    mov     $1, %r9d
    jmp     data
d_quad:                                 # .quad expr, ...
    mov     $8, %r9d
data:
    push    %r9
    call    eval
    pop     %r9
    mov     %r9, %rcx
data_byte:                              # the low byte first
    push    %rax
    push    %rcx
    call    emit_byte
    pop     %rcx
    pop     %rax
    shr     $8, %rax
    dec     %rcx
    jnz     data_byte
    call    blanks
    cmpb    $0x2c, (%r12)               # ','
    jne     end_line
    inc     %r12
    jmp     data

d_ascii:                                # .ascii "text", ...
    call    blanks
    cmpb    $0x22, (%r12)               # '"'
    jne     bad_syntax
    inc     %r12
ascii_byte:
    cmp     %r13, %r12
    jae     bad_string
    movzbl  (%r12), %eax
    cmp     $0x0a, %al                  # '\n'
    je      bad_string
    inc     %r12
    cmp     $0x22, %al                  # '"'
    je      ascii_end
    cmp     $0x5c, %al                  # '\'
    jne     ascii_put
    movzbl  (%r12), %eax
    inc     %r12
    cmp     $0x6e, %al                  # \n
    jne     ascii_not_n
    mov     $0x0a, %al
    jmp     ascii_put
ascii_not_n:
    cmp     $0x74, %al                  # \t
    jne     ascii_not_t
    mov     $0x09, %al
    jmp     ascii_put
ascii_not_t:
    mov     %eax, %ecx
    sub     $0x30, %ecx                 # \ooo: up to 3 octal digits
    cmp     $7, %ecx
    ja      ascii_put                   # else the byte itself
    mov     %ecx, %eax
    mov     $2, %edx
ascii_octal:
    movzbl  (%r12), %ecx
    sub     $0x30, %ecx
    cmp     $7, %ecx
    ja      ascii_put
    shl     $3, %eax
    add     %ecx, %eax
    inc     %r12
    dec     %edx
    jnz     ascii_octal
ascii_put:
    call    emit_byte
    jmp     ascii_byte
ascii_end:
    call    blanks
    cmpb    $0x2c, (%r12)               # ','
    jne     end_line
    inc     %r12
    jmp     d_ascii

# Instructions.

insn:                                   # %rsi, %rdx: the mnemonic
    call    pack
    lea     mnemonics(%rip), %rdi
insn_next:
    cmpb    $0, 8(%rdi)                 # class 0: the end of the table
    je      unknown_mnemonic
    cmp     (%rdi), %rax
    je      insn_found
    add     $16, %rdi
    jmp     insn_next
insn_found:
    push    %rdi
    call    operands
    pop     %rdi
    movzbl  11(%rdi), %eax              # how many it takes
    cmp     V_nops(%rbp), %rax
    jne     bad_operands
    xor     %eax, %eax                  # nothing encoded yet
    mov     %rax, I_rex(%rbp)
    mov     %rax, I_oplen(%rbp)
    mov     %rax, I_hasm(%rbp)
    mov     %rax, I_modrm(%rbp)
    mov     %rax, I_hass(%rbp)
    mov     %rax, I_disp(%rbp)
    mov     %rax, I_dsize(%rbp)
    mov     %rax, I_rip(%rbp)
    mov     %rax, I_imm(%rbp)
    mov     %rax, I_isize(%rbp)
    movzbl  10(%rdi), %eax              # the size its suffix says
    mov     %rax, I_size(%rbp)
    movzbl  9(%rdi), %eax               # its op
    mov     %rax, I_ext(%rbp)
    movzbl  8(%rdi), %eax               # its class
    cmp     $1, %eax
    je      c_alu
    cmp     $2, %eax
    je      c_test
    cmp     $3, %eax
    je      c_mov
    cmp     $4, %eax
    je      c_movzx
    cmp     $5, %eax
    je      c_lea
    cmp     $6, %eax
    je      c_grp
    cmp     $7, %eax
    je      c_shift
    cmp     $8, %eax
    je      c_imul
    cmp     $9, %eax
    je      c_setcc
    cmp     $10, %eax
    je      c_jcc
    cmp     $11, %eax
    je      c_jmp
    cmp     $12, %eax
    je      c_call
    cmp     $13, %eax
    je      c_byte
    jmp     c_0f

operands:                               # the operands to the end of the line: OP0, OP1, V_nops
    movq    $0, V_nops(%rbp)
    lea     OP0(%rbp), %rbx
    call    at_eol
    jc      end_line
operands_next:
    cmpq    $2, V_nops(%rbp)
    jae     bad_operands
    call    operand
    incq    V_nops(%rbp)
    add     $96, %rbx
    call    blanks
    cmpb    $0x2c, (%r12)               # ','
    jne     end_line
    inc     %r12
    jmp     operands_next

operand:                                # the operand at %r12 into %rbx
    xor     %eax, %eax
    mov     %rax, O_kind(%rbx)
    mov     %rax, O_reg(%rbx)
    mov     %rax, O_size(%rbx)
    mov     %rax, O_rexf(%rbx)
    mov     %rax, O_val(%rbx)
    mov     %rax, O_vkind(%rbx)
    mov     %rax, O_scale(%rbx)
    mov     %rax, O_ind(%rbx)
    movq    $1, O_exact(%rbx)
    movq    $1, O_known(%rbx)
    movq    $-1, O_base(%rbx)
    movq    $-1, O_index(%rbx)
    call    blanks
    cmpb    $0x2a, (%r12)               # '*': indirect
    jne     operand_direct
    movq    $1, O_ind(%rbx)
    inc     %r12
operand_direct:
    movzbl  (%r12), %eax
    cmp     $0x25, %al                  # '%': a register
    je      operand_reg
    cmp     $0x24, %al                  # '$': an immediate
    je      operand_imm
    cmp     $0x28, %al                  # '(%': memory, no displacement
    jne     operand_disp
    cmpb    $0x25, 1(%r12)
    je      operand_mem
operand_disp:
    call    eval_operand
    call    blanks
    cmpb    $0x28, (%r12)               # '(': memory
    je      operand_mem
    movq    $4, O_kind(%rbx)            # else a jump's target
    ret
operand_mem:
    movq    $3, O_kind(%rbx)
    inc     %r12
    call    blanks
    cmpb    $0x2c, (%r12)               # ',': no base
    je      operand_index
    call    reg_name
    cmp     $8, %rcx                    # 64 bits, or %rip
    jne     bad_operand
    mov     %rax, O_base(%rbx)
operand_index:
    call    blanks
    cmpb    $0x2c, (%r12)               # ','
    jne     operand_close
    inc     %r12
    call    blanks
    call    reg_name
    cmp     $8, %rcx
    jne     bad_operand
    cmp     $4, %rax                    # not %rsp
    je      bad_operand
    cmp     $16, %rax                   # nor %rip
    je      bad_operand
    mov     %rax, O_index(%rbx)
    call    blanks
    cmpb    $0x2c, (%r12)               # ','
    jne     operand_close
    inc     %r12
    call    eval_number                 # the scale: 1 2 4 8, as 0 1 2 3
    xor     %ecx, %ecx
operand_scale:
    cmp     $1, %rax
    je      operand_scaled
    test    $1, %al
    jnz     bad_operand
    shr     $1, %rax
    inc     %ecx
    cmp     $3, %ecx
    jbe     operand_scale
    jmp     bad_operand
operand_scaled:
    mov     %rcx, O_scale(%rbx)
operand_close:
    call    blanks
    cmpb    $0x29, (%r12)               # ')'
    jne     bad_operand
    inc     %r12
    ret
operand_reg:
    call    reg_name
    movq    $1, O_kind(%rbx)
    mov     %rax, O_reg(%rbx)
    mov     %rcx, O_size(%rbx)
    mov     %rdx, O_rexf(%rbx)
    ret
operand_imm:
    inc     %r12
    call    eval_operand
    movq    $2, O_kind(%rbx)
    ret

eval_operand:                           # the expression at %r12 into %rbx's value
    call    eval
    mov     %rax, O_val(%rbx)
    mov     %rdx, O_vkind(%rbx)
    mov     V_known(%rbp), %rax
    mov     %rax, O_known(%rbx)
    mov     V_exact(%rbp), %rax
    test    %rdx, %rdx                  # a label's address is no number known here
    jz      eval_operand_exact
    xor     %eax, %eax
eval_operand_exact:
    mov     %rax, O_exact(%rbx)
    ret

reg_name:                               # register %name at %r12: %rax its number, %rcx its size, %rdx 1 if it needs a REX
    cmpb    $0x25, (%r12)               # '%'
    jne     bad_operand
    inc     %r12
    call    word
    call    pack
    lea     registers(%rip), %rdi
reg_next:
    cmpb    $0, 9(%rdi)                 # size 0: the end of the table
    je      unknown_register
    cmp     (%rdi), %rax
    je      reg_found
    add     $16, %rdi
    jmp     reg_next
reg_found:
    movzbl  8(%rdi), %eax
    movzbl  9(%rdi), %ecx
    movzbl  10(%rdi), %edx
    ret

# The encoding: the classes fill I_*, finish writes the bytes.

opsize:                                 # I_size: the suffix's, else the last register operand's; REX.W for 8
    mov     I_size(%rbp), %rax
    test    %rax, %rax
    jnz     opsize_set
    lea     OP1(%rbp), %rsi
    cmpq    $2, V_nops(%rbp)
    jne     opsize_first
    cmpq    $1, O_kind(%rsi)
    je      opsize_reg
opsize_first:
    lea     OP0(%rbp), %rsi
    cmpq    $1, O_kind(%rsi)
    jne     no_size
opsize_reg:
    mov     O_size(%rsi), %rax
    mov     %rax, I_size(%rbp)
opsize_set:
    cmp     $8, %rax
    jne     opsize_done
    orq     $8, I_rex(%rbp)
opsize_done:
    ret

wbit:                                   # %eax = 0 for a byte operation, else 1
    xor     %eax, %eax
    cmpq    $1, I_size(%rbp)
    je      wbit_done
    inc     %eax
wbit_done:
    ret

ext8:                                   # %eax += 8 * I_ext: an ALU opcode
    mov     I_ext(%rbp), %rcx
    shl     $3, %ecx
    add     %ecx, %eax
    ret

op1:                                    # the opcode %al
    movzbl  %al, %eax
    mov     %rax, I_op(%rbp)
    movq    $1, I_oplen(%rbp)
    ret

op2:                                    # the opcode 0F, %al
    movzbl  %al, %eax
    shl     $8, %eax
    or      $0x0f, %eax
    mov     %rax, I_op(%rbp)
    movq    $2, I_oplen(%rbp)
    ret

is_acc:                                 # ZF when operand %rdi is %al, %eax or %rax
    cmpq    $1, O_kind(%rdi)
    jne     is_acc_done
    cmpq    $0, O_reg(%rdi)
is_acc_done:
    ret

regf:                                   # register operand %rsi into ModRM's reg
    mov     O_reg(%rsi), %rax
    call    ext_field
    cmpq    $0, O_rexf(%rsi)
    je      regf_done
    orq     $0x40, I_rex(%rbp)
regf_done:
    ret

ext_field:                              # %rax into ModRM's reg (a register's number or a /digit)
    movq    $1, I_hasm(%rbp)
    mov     %eax, %ecx
    and     $7, %ecx
    shl     $3, %ecx
    or      %rcx, I_modrm(%rbp)
    test    $8, %al                     # r8-r15: REX.R
    jz      ext_field_done
    orq     $4, I_rex(%rbp)
ext_field_done:
    ret

rm:                                     # operand %rsi into ModRM's rm: a register or memory
    movq    $1, I_hasm(%rbp)
    cmpq    $1, O_kind(%rsi)
    jne     rm_mem
    mov     O_reg(%rsi), %rax
    mov     %eax, %ecx
    and     $7, %ecx
    or      $0xc0, %ecx                 # mod 11: a register
    or      %rcx, I_modrm(%rbp)
    test    $8, %al                     # r8-r15: REX.B
    jz      rm_rexf
    orq     $1, I_rex(%rbp)
rm_rexf:
    cmpq    $0, O_rexf(%rsi)
    je      rm_done
    orq     $0x40, I_rex(%rbp)
rm_done:
    ret
rm_mem:
    cmpq    $3, O_kind(%rsi)
    jne     bad_operand
    mov     O_base(%rsi), %rax
    cmp     $16, %rax                   # %rip
    je      rm_rip
    test    %rax, %rax                  # no base: not done
    js      bad_operand
    mov     O_val(%rsi), %rcx
    mov     %rcx, I_disp(%rbp)
    cmpq    $0, O_exact(%rsi)           # a label or not known: disp32
    je      rm_disp32
    test    %rcx, %rcx                  # 0: none, but from %rbp or %r13
    jnz     rm_disp8
    mov     %eax, %edx
    and     $7, %edx
    cmp     $5, %edx
    jne     rm_base
rm_disp8:
    movsbq  %cl, %rdx                   # fits in a byte: mod 01
    cmp     %rcx, %rdx
    jne     rm_disp32
    movq    $1, I_dsize(%rbp)
    orq     $0x40, I_modrm(%rbp)
    jmp     rm_base
rm_disp32:                              # mod 10
    movq    $4, I_dsize(%rbp)
    orq     $0x80, I_modrm(%rbp)
rm_base:
    test    $8, %al                     # r8-r15: REX.B
    jz      rm_base_low
    orq     $1, I_rex(%rbp)
rm_base_low:
    and     $7, %eax
    mov     O_index(%rsi), %rdx
    test    %rdx, %rdx                  # an index: a SIB
    jns     rm_sib
    cmp     $4, %eax                    # %rsp, %r12: a SIB without index
    je      rm_sib
    or      %rax, I_modrm(%rbp)
    ret
rm_sib:
    orq     $4, I_modrm(%rbp)           # rm 100: a SIB follows
    movq    $1, I_hass(%rbp)
    mov     O_scale(%rsi), %rcx
    shl     $6, %ecx
    or      %ecx, %eax                  # scale, base
    mov     $4, %ecx                    # index 100: none
    test    %rdx, %rdx
    js      rm_sib_index
    mov     %edx, %ecx
    and     $7, %ecx
    test    $8, %dl                     # r8-r15: REX.X
    jz      rm_sib_index
    orq     $2, I_rex(%rbp)
rm_sib_index:
    shl     $3, %ecx
    or      %ecx, %eax
    mov     %rax, I_sib(%rbp)
    ret
rm_rip:                                 # mod 00 rm 101: disp32 from the next instruction
    orq     $5, I_modrm(%rbp)
    movq    $4, I_dsize(%rbp)
    movq    $1, I_rip(%rbp)
    mov     O_val(%rsi), %rax
    mov     %rax, I_ripval(%rbp)
    ret

finish:                                 # the bytes of I_* into IBUF, then out
    lea     IBUF(%rbp), %rdi
    mov     I_rex(%rbp), %rax
    test    %rax, %rax
    jz      finish_op
    and     $15, %eax
    or      $0x40, %eax
    mov     %al, (%rdi)
    inc     %rdi
finish_op:
    mov     I_op(%rbp), %rax
    mov     I_oplen(%rbp), %rcx
    call    put_le
    cmpq    $0, I_hasm(%rbp)
    je      finish_disp
    mov     I_modrm(%rbp), %rax
    mov     %al, (%rdi)
    inc     %rdi
    cmpq    $0, I_hass(%rbp)
    je      finish_disp
    mov     I_sib(%rbp), %rax
    mov     %al, (%rdi)
    inc     %rdi
finish_disp:
    mov     %rdi, I_dpos(%rbp)
    mov     I_disp(%rbp), %rax
    mov     I_dsize(%rbp), %rcx
    call    put_le
    mov     I_imm(%rbp), %rax
    mov     I_isize(%rbp), %rcx
    call    put_le
    lea     IBUF(%rbp), %rsi
    mov     %rdi, %rdx
    sub     %rsi, %rdx                  # its length
    cmpq    $0, V_emit(%rbp)
    je      emit_bytes
    call    check_imm
    cmpq    $0, I_rip(%rbp)
    je      emit_bytes
    call    here_offset                 # (%rsi, %rdx stay)
    add     V_base(%rbp,%rcx,8), %rax
    add     %rdx, %rax                  # the address after it
    mov     I_ripval(%rbp), %rcx
    sub     %rax, %rcx
    movslq  %ecx, %rax                  # fits in 32 bits
    cmp     %rax, %rcx
    jne     out_of_range
    mov     I_dpos(%rbp), %rdi
    mov     %ecx, (%rdi)
emit_bytes:                             # writes %rdx bytes from %rsi
    test    %rdx, %rdx
    jz      emit_bytes_done
    movzbl  (%rsi), %eax
    call    emit_byte
    inc     %rsi
    dec     %rdx
    jmp     emit_bytes
emit_bytes_done:
    ret

check_imm:                              # the immediate fits in its bytes
    mov     I_isize(%rbp), %rcx
    mov     I_imm(%rbp), %rax
    cmp     $1, %rcx
    je      check_imm8
    cmp     $4, %rcx
    jne     check_imm_ok
    movslq  %eax, %r8                   # signed 32 bits
    cmp     %r8, %rax
    je      check_imm_ok
    cmpq    $8, I_size(%rbp)            # sign-extended to 64: only that
    je      out_of_range
    mov     %eax, %r8d                  # unsigned 32 bits
    cmp     %r8, %rax
    je      check_imm_ok
    jmp     out_of_range
check_imm8:
    movsbq  %al, %r8
    cmp     %r8, %rax
    je      check_imm_ok
    movzbl  %al, %r8d
    cmp     %r8, %rax
    jne     out_of_range
check_imm_ok:
    ret

put_le:                                 # %rcx bytes of %rax at %rdi, the low one first
    test    %rcx, %rcx
    jz      put_le_done
    mov     %al, (%rdi)
    inc     %rdi
    shr     $8, %rax
    dec     %rcx
    jmp     put_le
put_le_done:
    ret

emit_byte:                              # the byte %al at here, in the last pass; counted
    mov     V_sec(%rbp), %rcx
    cmpq    $0, V_emit(%rbp)
    je      emit_byte_count
    cmp     $4, %ecx                    # not in .bss
    je      in_bss
    mov     V_off(%rbp,%rcx,8), %rdi
    add     V_loc(%rbp,%rcx,8), %rdi
    add     $OUTBUF, %rdi
    cmp     $OUTBUF_END, %rdi
    jae     output_full
    mov     %al, (%rdi)
emit_byte_count:
    incq    V_loc(%rbp,%rcx,8)
    ret

# The classes of the mnemonics, I_ext their op.

c_alu:                                  # add or and sub xor cmp: I_ext its /digit
    call    opsize
    lea     OP0(%rbp), %rsi
    lea     OP1(%rbp), %rdi
    cmpq    $2, O_kind(%rsi)
    je      alu_imm
    cmpq    $3, O_kind(%rsi)            # from memory: op r, r/m
    jne     alu_from_reg
    cmpq    $1, O_kind(%rdi)
    jne     bad_operand
    call    wbit
    add     $2, %eax
    call    ext8
    call    op1
    mov     %rdi, %rsi
    call    regf
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish
alu_from_reg:                           # op r/m, r
    cmpq    $1, O_kind(%rsi)
    jne     bad_operand
    call    wbit
    call    ext8
    call    op1
    call    regf
    mov     %rdi, %rsi
    call    rm
    jmp     finish
alu_imm:
    mov     O_val(%rsi), %rax
    mov     %rax, I_imm(%rbp)
    cmpq    $1, I_size(%rbp)
    jne     alu_imm_wide
    movq    $1, I_isize(%rbp)           # a byte: op al, imm8 or 80 /digit
    call    is_acc
    jne     alu_imm_byte
    mov     $4, %eax
    call    ext8
    call    op1
    jmp     finish
alu_imm_byte:
    mov     $0x80, %eax
    call    op1
    jmp     alu_imm_rm
alu_imm_wide:
    cmpq    $0, O_exact(%rsi)           # a number of a byte: 83 /digit imm8
    je      alu_imm32
    movsbq  %al, %rcx
    cmp     %rcx, %rax
    jne     alu_imm32
    movq    $1, I_isize(%rbp)
    mov     $0x83, %eax
    call    op1
    jmp     alu_imm_rm
alu_imm32:
    movq    $4, I_isize(%rbp)
    call    is_acc                      # op eax, imm32
    jne     alu_imm32_rm
    mov     $5, %eax
    call    ext8
    call    op1
    jmp     finish
alu_imm32_rm:                           # 81 /digit imm32
    mov     $0x81, %eax
    call    op1
alu_imm_rm:
    mov     I_ext(%rbp), %rax
    call    ext_field
    mov     %rdi, %rsi
    call    rm
    jmp     finish

c_test:                                 # test r, r/m; test imm, r/m
    call    opsize
    lea     OP0(%rbp), %rsi
    lea     OP1(%rbp), %rdi
    cmpq    $2, O_kind(%rsi)
    je      test_imm
    cmpq    $1, O_kind(%rsi)
    jne     bad_operand
    call    wbit
    add     $0x84, %eax
    call    op1
    call    regf
    mov     %rdi, %rsi
    call    rm
    jmp     finish
test_imm:
    mov     O_val(%rsi), %rax
    mov     %rax, I_imm(%rbp)
    mov     $4, %ecx
    cmpq    $1, I_size(%rbp)
    jne     test_imm_size
    mov     $1, %ecx
test_imm_size:
    mov     %rcx, I_isize(%rbp)
    call    is_acc                      # A8/A9 for al, eax, rax
    jne     test_imm_rm
    call    wbit
    add     $0xa8, %eax
    call    op1
    jmp     finish
test_imm_rm:                            # F6/F7 /0
    call    wbit
    add     $0xf6, %eax
    call    op1
    xor     %eax, %eax
    call    ext_field
    mov     %rdi, %rsi
    call    rm
    jmp     finish

c_mov:                                  # mov
    call    opsize
    lea     OP0(%rbp), %rsi
    lea     OP1(%rbp), %rdi
    cmpq    $2, O_kind(%rsi)
    je      mov_imm
    cmpq    $3, O_kind(%rsi)
    je      mov_load
    cmpq    $1, O_kind(%rsi)            # 88/89: mov r, r/m
    jne     bad_operand
    call    wbit
    add     $0x88, %eax
    call    op1
    call    regf
    mov     %rdi, %rsi
    call    rm
    jmp     finish
mov_load:                               # 8A/8B: mov m, r
    cmpq    $1, O_kind(%rdi)
    jne     bad_operand
    call    wbit
    add     $0x8a, %eax
    call    op1
    push    %rsi
    mov     %rdi, %rsi
    call    regf
    pop     %rsi
    call    rm
    jmp     finish
mov_imm:
    mov     O_val(%rsi), %rax
    mov     %rax, I_imm(%rbp)
    cmpq    $1, O_kind(%rdi)
    jne     mov_imm_rm
    mov     I_size(%rbp), %rax
    cmp     $8, %rax
    je      mov_imm64
    mov     %rax, I_isize(%rbp)         # B0+r imm8, B8+r imm32
    mov     $0xb8, %eax
    cmpq    $1, I_size(%rbp)
    jne     mov_imm_reg
    mov     $0xb0, %eax
mov_imm_reg:                            # the register in the opcode
    mov     O_reg(%rdi), %rcx
    test    $8, %cl                     # r8-r15: REX.B
    jz      mov_imm_low
    orq     $1, I_rex(%rbp)
mov_imm_low:
    and     $7, %ecx
    add     %ecx, %eax
    call    op1
    cmpq    $0, O_rexf(%rdi)
    je      finish
    orq     $0x40, I_rex(%rbp)
    jmp     finish
mov_imm64:                              # C7 /0 imm32, unless a number known here needs 64 bits
    cmpq    $0, O_exact(%rsi)
    je      mov_imm_rm
    mov     I_imm(%rbp), %rax
    movslq  %eax, %rcx
    cmp     %rcx, %rax
    je      mov_imm_rm
    movq    $8, I_isize(%rbp)           # B8+r imm64
    mov     $0xb8, %eax
    jmp     mov_imm_reg
mov_imm_rm:                             # C6/C7 /0
    mov     $4, %ecx
    cmpq    $1, I_size(%rbp)
    jne     mov_imm_rm_size
    mov     $1, %ecx
mov_imm_rm_size:
    mov     %rcx, I_isize(%rbp)
    call    wbit
    add     $0xc6, %eax
    call    op1
    xor     %eax, %eax
    call    ext_field
    mov     %rdi, %rsi
    call    rm
    jmp     finish

c_movzx:                                # movzbq, movzbl: 0F B6 /r
    call    opsize
    lea     OP1(%rbp), %rsi
    cmpq    $1, O_kind(%rsi)
    jne     bad_operand
    mov     I_ext(%rbp), %rax
    call    op2
    call    regf
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish

c_lea:                                  # lea m, r: 8D /r
    call    opsize
    lea     OP0(%rbp), %rsi
    cmpq    $3, O_kind(%rsi)
    jne     bad_operand
    lea     OP1(%rbp), %rsi
    cmpq    $1, O_kind(%rsi)
    jne     bad_operand
    mov     $0x8d, %eax
    call    op1
    call    regf
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish

c_grp:                                  # inc dec (FE/FF), not neg mul div idiv (F6/F7, I_ext + 0x10)
    call    opsize
    call    wbit
    add     $0xfe, %eax
    mov     I_ext(%rbp), %rcx
    test    $0x10, %cl
    jz      grp_op
    sub     $8, %eax
grp_op:
    call    op1
    mov     I_ext(%rbp), %rax
    and     $7, %eax
    call    ext_field
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish

c_shift:                                # shl shr sar: D1 by 1, C1 by imm8, D3 by %cl
    call    opsize
    lea     OP0(%rbp), %rsi
    cmpq    $2, O_kind(%rsi)
    je      shift_imm
    cmpq    $1, O_kind(%rsi)            # %cl only
    jne     bad_operand
    cmpq    $1, O_reg(%rsi)
    jne     bad_operand
    cmpq    $1, O_size(%rsi)
    jne     bad_operand
    call    wbit
    add     $0xd2, %eax
    jmp     shift_op
shift_imm:
    mov     O_val(%rsi), %rax
    cmpq    $0, O_exact(%rsi)
    je      shift_imm8
    cmp     $1, %rax
    jne     shift_imm8
    call    wbit
    add     $0xd0, %eax
    jmp     shift_op
shift_imm8:
    mov     %rax, I_imm(%rbp)
    movq    $1, I_isize(%rbp)
    call    wbit
    add     $0xc0, %eax
shift_op:
    call    op1
    mov     I_ext(%rbp), %rax
    call    ext_field
    lea     OP1(%rbp), %rsi
    call    rm
    jmp     finish

c_imul:                                 # imul r/m, r: 0F AF /r
    call    opsize
    lea     OP1(%rbp), %rsi
    cmpq    $1, O_kind(%rsi)
    jne     bad_operand
    mov     $0xaf, %eax
    call    op2
    call    regf
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish

c_setcc:                                # setcc r/m8: 0F 90+cc /0
    mov     I_ext(%rbp), %rax
    add     $0x90, %eax
    call    op2
    xor     %eax, %eax
    call    ext_field
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish

c_jmp:                                  # jmp: EB rel8, E9 rel32; FF /4 indirect
    mov     $4, %eax
    call    indirect
    mov     $0xeb, %r8d
    mov     $0xe9, %r9d
    mov     $1, %r10d
    jmp     jump
c_jcc:                                  # jcc: 70+cc rel8, 0F 80+cc rel32
    mov     I_ext(%rbp), %rax
    lea     0x70(%rax), %r8
    mov     %rax, %r9
    shl     $8, %r9
    or      $0x800f, %r9
    mov     $2, %r10d
jump:                                   # short opcode %r8, long %r9 of %r10 bytes
    lea     OP0(%rbp), %rsi
    cmpq    $4, O_kind(%rsi)
    jne     bad_operand
    mov     V_jump(%rbp), %rdi          # this jump's size
    incq    V_jump(%rbp)
    add     $JUMPS, %rdi
    cmp     $JUMPS_END, %rdi
    jae     too_many_jumps
    cmpb    $0, (%rdi)
    jne     jump_long
    xor     %ecx, %ecx
    cmpq    $0, O_known(%rsi)           # not yet defined: short
    je      jump_short
    mov     O_vkind(%rsi), %rax         # another section: long
    cmp     V_sec(%rbp), %rax
    jne     jump_grow
    call    here
    add     $2, %rax                    # the address after it
    mov     O_val(%rsi), %rcx
    sub     %rax, %rcx
    movsbq  %cl, %rax                   # fits in a byte?
    cmp     %rax, %rcx
    je      jump_short
jump_grow:                              # long from now on, and another pass
    cmpq    $0, V_emit(%rbp)
    jne     unstable
    movb    $1, (%rdi)
    movq    $1, V_changed(%rbp)
jump_long:
    mov     %r9, I_op(%rbp)
    mov     %r10, I_oplen(%rbp)
    lea     4(%r10), %rdx
    jmp     jump_rel
jump_short:
    mov     %r8, %rax
    call    op1
    mov     %rcx, I_imm(%rbp)
    movq    $1, I_isize(%rbp)
    jmp     finish

c_call:                                 # call: E8 rel32; FF /2 indirect
    mov     $2, %eax
    call    indirect
    lea     OP0(%rbp), %rsi
    cmpq    $4, O_kind(%rsi)
    jne     bad_operand
    mov     $0xe8, %eax
    call    op1
    mov     $5, %edx
jump_rel:                               # a rel32 to the target from the end, %rdx bytes long
    movq    $4, I_isize(%rbp)
    cmpq    $0, V_emit(%rbp)
    je      finish
    mov     O_vkind(%rsi), %rax         # in this section
    cmp     V_sec(%rbp), %rax
    jne     bad_target
    mov     %rdx, %r11
    call    here
    add     %r11, %rax
    mov     O_val(%rsi), %rcx
    sub     %rax, %rcx
    mov     %rcx, I_imm(%rbp)
    jmp     finish

indirect:                               # *operand: FF /%eax, and back to the line's end
    cmpq    $0, OP0+O_ind(%rbp)
    je      indirect_done
    pop     %rcx                        # not back to the caller
    call    ext_field
    mov     $0xff, %eax
    call    op1
    lea     OP0(%rbp), %rsi
    call    rm
    jmp     finish
indirect_done:
    ret

c_byte:                                 # ret: its opcode
    mov     I_ext(%rbp), %rax
    call    op1
    jmp     finish
c_0f:                                   # syscall: 0F, its opcode
    mov     I_ext(%rbp), %rax
    call    op2
    jmp     finish

# The output file.

layout:                                 # every section's file offset and address, as ld places them
    mov     $0xb0, %eax                 # after the ELF header and two program headers
    mov     $1, %ecx
    call    place                       # .text
    mov     $2, %ecx
    call    place                       # .rodata: the end of the code segment
    mov     %rax, V_tend(%rbp)
    add     $ADDR, %rax                 # its address v
    mov     %rax, %rdx
    mov     %eax, %r8d
    and     $0xfff, %r8d
    mov     $0x1000, %ecx
    call    alignup
    add     %r8, %rax                   # the data segment from the next page on: v2
    mov     %rax, %r9
    sub     %rdx, %r9                   # v2 - v: its addresses after its file offsets
    mov     V_align+24(%rbp), %rcx
    call    alignup
    mov     %rax, V_base+24(%rbp)       # .data
    mov     %rax, %rdx
    sub     $ADDR, %rdx
    sub     %r9, %rdx
    mov     %rdx, V_off+24(%rbp)
    add     V_loc+24(%rbp), %rax
    mov     V_align+32(%rbp), %rcx
    call    alignup
    mov     %rax, V_base+32(%rbp)       # .bss
    mov     V_off+24(%rbp), %rax        # its file offset, and .shstrtab's: the end
    add     V_loc+24(%rbp), %rax        # of .data (ld's, though .bss be aligned)
    mov     %rax, V_off+32(%rbp)
    mov     %rax, V_shstr(%rbp)
    add     $shstrtab_len, %rax         # then the section headers
    mov     $8, %ecx
    call    alignup
    mov     %rax, V_shoff(%rbp)
    add     $6 * 64, %rax
    mov     %rax, V_fend(%rbp)
    cmp     $OUTBUF_END - OUTBUF, %rax
    ja      output_full
    ret

place:                                  # section %rcx from file offset %rax, aligned; %rax = its end
    push    %rcx
    mov     V_align(%rbp,%rcx,8), %rcx
    call    alignup
    pop     %rcx
    mov     %rax, V_off(%rbp,%rcx,8)
    lea     ADDR(%rax), %rdx
    mov     %rdx, V_base(%rbp,%rcx,8)
    add     V_loc(%rbp,%rcx,8), %rax
    ret

alignup:                                # %rax up to a multiple of %rcx, a power of 2
    dec     %rcx
    add     %rcx, %rax
    not     %rcx
    and     %rcx, %rax
    ret

headers:                                # the ELF header, the program headers, .shstrtab, the section headers
    mov     $1, %ecx
headers_bytes:                          # each section has bytes
    cmpq    $0, V_loc(%rbp,%rcx,8)
    je      empty_section
    inc     %ecx
    cmp     $4, %ecx
    jbe     headers_bytes
    mov     V_base+32(%rbp), %rax       # ld's script ends .bss at a multiple of 8
    add     V_loc+32(%rbp), %rax        # (its address)
    mov     $8, %ecx
    call    alignup
    sub     V_base+32(%rbp), %rax
    mov     %rax, V_loc+32(%rbp)
    mov     $OUTBUF, %edi
    lea     elf_headers(%rip), %rsi
    mov     $0xb0, %ecx
    rep movsb
    lea     str_start(%rip), %rsi       # e_entry: _start
    mov     $6, %edx
    call    find_sym
    jc      no_start
    mov     S_kind(%rdi), %rcx
    mov     S_value(%rdi), %rax
    add     V_base(%rbp,%rcx,8), %rax
    mov     $OUTBUF, %edi
    mov     %rax, 24(%rdi)
    mov     V_shoff(%rbp), %rax         # e_shoff
    mov     %rax, 40(%rdi)
    mov     V_tend(%rbp), %rax          # the code: p_filesz, p_memsz
    mov     %rax, 96(%rdi)
    mov     %rax, 104(%rdi)
    mov     V_off+24(%rbp), %rax        # the data: p_offset
    mov     %rax, 128(%rdi)
    mov     V_base+24(%rbp), %rax       # p_vaddr, p_paddr
    mov     %rax, 136(%rdi)
    mov     %rax, 144(%rdi)
    mov     V_loc+24(%rbp), %rax        # p_filesz: .data
    mov     %rax, 152(%rdi)
    mov     V_base+32(%rbp), %rax       # p_memsz: to the end of .bss
    add     V_loc+32(%rbp), %rax
    sub     V_base+24(%rbp), %rax
    mov     %rax, 160(%rdi)
    mov     V_shstr(%rbp), %rdi         # .shstrtab
    add     $OUTBUF, %rdi
    lea     shstrtab(%rip), %rsi
    mov     $shstrtab_len, %ecx
    rep movsb
    mov     V_shoff(%rbp), %rdi         # the section headers
    add     $OUTBUF, %rdi
    mov     %rdi, %rdx
    lea     section_headers(%rip), %rsi
    mov     $6 * 64, %ecx
    rep movsb
    mov     %rdx, %rdi
    mov     $1, %ecx
headers_section:                        # 1-4: .text .rodata .data .bss
    add     $64, %rdi
    mov     V_base(%rbp,%rcx,8), %rax   # sh_addr
    mov     %rax, 16(%rdi)
    mov     V_off(%rbp,%rcx,8), %rax    # sh_offset
    mov     %rax, 24(%rdi)
    mov     V_loc(%rbp,%rcx,8), %rax    # sh_size
    mov     %rax, 32(%rdi)
    mov     V_align(%rbp,%rcx,8), %rax  # sh_addralign
    mov     %rax, 48(%rdi)
    inc     %ecx
    cmp     $4, %ecx
    jbe     headers_section
    mov     V_shstr(%rbp), %rax         # 5: .shstrtab's sh_offset
    mov     %rax, 88(%rdi)
    ret

# The errors: asm: line N: what: the line.

junk:
    lea     msg_junk(%rip), %rsi
    jmp     fail
twice:
    lea     msg_twice(%rip), %rsi
    jmp     fail
too_many_symbols:
    lea     msg_symbols(%rip), %rsi
    jmp     fail
too_many_jumps:
    lea     msg_jumps(%rip), %rsi
    jmp     fail
bad_local:
    lea     msg_local(%rip), %rsi
    jmp     fail
not_number:
    lea     msg_not_number(%rip), %rsi
    jmp     fail
bad_number:
    lea     msg_number(%rip), %rsi
    jmp     fail
bad_expr:
    lea     msg_expr(%rip), %rsi
    jmp     fail
not_defined:
    lea     msg_undefined(%rip), %rsi
    jmp     fail
bad_syntax:
    lea     msg_syntax(%rip), %rsi
    jmp     fail
bad_align:
    lea     msg_align(%rip), %rsi
    jmp     fail
bad_string:
    lea     msg_string(%rip), %rsi
    jmp     fail
unknown_mnemonic:
    lea     msg_mnemonic(%rip), %rsi
    jmp     fail
unknown_register:
    lea     msg_register(%rip), %rsi
    jmp     fail
bad_operands:
    lea     msg_operands(%rip), %rsi
    jmp     fail
bad_operand:
    lea     msg_operand(%rip), %rsi
    jmp     fail
no_size:
    lea     msg_size(%rip), %rsi
    jmp     fail
out_of_range:
    lea     msg_range(%rip), %rsi
    jmp     fail
bad_target:
    lea     msg_target(%rip), %rsi
    jmp     fail
unstable:
    lea     msg_unstable(%rip), %rsi
    jmp     fail
in_bss:
    lea     msg_bss(%rip), %rsi
    jmp     fail
fail:                                   # message %rsi (a C string) about the line
    push    %rsi
    lea     msg_line(%rip), %rsi
    call    eputs
    mov     V_line(%rbp), %rax
    call    eputn
    lea     msg_colon(%rip), %rsi
    call    eputs
    pop     %rsi
    call    eputs
    lea     msg_colon(%rip), %rsi
    call    eputs
    mov     V_lstart(%rbp), %rsi        # the line
    mov     %rsi, %rdx
fail_line:
    cmp     %r13, %rdx
    jae     fail_line_end
    cmpb    $0x0a, (%rdx)
    je      fail_line_end
    inc     %rdx
    jmp     fail_line
fail_line_end:
    sub     %rsi, %rdx
    call    ewrite
    jmp     die_end

output_full:
    lea     msg_full(%rip), %rsi
    jmp     die
empty_section:
    lea     msg_empty(%rip), %rsi
    jmp     die
no_start:
    lea     msg_start(%rip), %rsi
    jmp     die
too_large:
    lea     msg_large(%rip), %rsi
    jmp     die
read_failed:
    lea     msg_read(%rip), %rsi
    jmp     die
write_failed:
    lea     msg_write(%rip), %rsi
die:                                    # asm: message %rsi
    push    %rsi
    lea     msg_asm(%rip), %rsi
    call    eputs
    pop     %rsi
    call    eputs
die_end:
    lea     msg_newline(%rip), %rsi
    call    eputs
    mov     $1, %edi                    # status 1
exit:
    mov     $60, %eax                   # SYS_exit
    syscall

eputs:                                  # writes the C string %rsi to stderr
    mov     %rsi, %rdx
eputs_len:
    cmpb    $0, (%rdx)
    je      eputs_end
    inc     %rdx
    jmp     eputs_len
eputs_end:
    sub     %rsi, %rdx
ewrite:                                 # writes %rsi, %rdx to stderr
    mov     $1, %eax                    # SYS_write
    mov     $2, %edi                    # fd 2, stderr
    syscall
    ret

eputn:                                  # writes %rax in decimal to stderr
    lea     NUMBUF+24(%rbp), %rdi
    mov     $10, %ecx
eputn_digit:                            # the last digit first
    xor     %edx, %edx
    div     %rcx
    add     $0x30, %dl
    dec     %rdi
    mov     %dl, (%rdi)
    test    %rax, %rax
    jnz     eputn_digit
    mov     %rdi, %rsi
    lea     NUMBUF+24(%rbp), %rdx
    sub     %rsi, %rdx
    jmp     ewrite

# The tables. A name is 8 bytes, NUL-padded; a mnemonic then its class,
# op, the size its suffix says (0: from a register) and its operands.

directives:
    .ascii  ".ascii\0\0", ".balign\0", ".byte\0\0\0", ".code64\0"
    .ascii  ".equ\0\0\0\0", ".globl\0\0", ".quad\0\0\0", ".section"
    .ascii  ".skip\0\0\0", ".text\0\0\0", ".data\0\0\0", ".bss\0\0\0\0"
sections:                               # 1-4
    .ascii  ".text\0\0\0", ".rodata\0", ".data\0\0\0", ".bss\0\0\0\0"

registers:                              # name, number, bytes, 1 if it needs a REX
    .ascii  "rax\0\0\0\0\0"
    .byte   0, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rcx\0\0\0\0\0"
    .byte   1, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rdx\0\0\0\0\0"
    .byte   2, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rbx\0\0\0\0\0"
    .byte   3, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rsp\0\0\0\0\0"
    .byte   4, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rbp\0\0\0\0\0"
    .byte   5, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rsi\0\0\0\0\0"
    .byte   6, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rdi\0\0\0\0\0"
    .byte   7, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r8\0\0\0\0\0\0"
    .byte   8, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r9\0\0\0\0\0\0"
    .byte   9, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r10\0\0\0\0\0"
    .byte   10, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r11\0\0\0\0\0"
    .byte   11, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r12\0\0\0\0\0"
    .byte   12, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r13\0\0\0\0\0"
    .byte   13, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r14\0\0\0\0\0"
    .byte   14, 8, 0, 0, 0, 0, 0, 0
    .ascii  "r15\0\0\0\0\0"
    .byte   15, 8, 0, 0, 0, 0, 0, 0
    .ascii  "rip\0\0\0\0\0"
    .byte   16, 8, 0, 0, 0, 0, 0, 0
    .ascii  "eax\0\0\0\0\0"
    .byte   0, 4, 0, 0, 0, 0, 0, 0
    .ascii  "ecx\0\0\0\0\0"
    .byte   1, 4, 0, 0, 0, 0, 0, 0
    .ascii  "edx\0\0\0\0\0"
    .byte   2, 4, 0, 0, 0, 0, 0, 0
    .ascii  "ebx\0\0\0\0\0"
    .byte   3, 4, 0, 0, 0, 0, 0, 0
    .ascii  "esp\0\0\0\0\0"
    .byte   4, 4, 0, 0, 0, 0, 0, 0
    .ascii  "ebp\0\0\0\0\0"
    .byte   5, 4, 0, 0, 0, 0, 0, 0
    .ascii  "esi\0\0\0\0\0"
    .byte   6, 4, 0, 0, 0, 0, 0, 0
    .ascii  "edi\0\0\0\0\0"
    .byte   7, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r8d\0\0\0\0\0"
    .byte   8, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r9d\0\0\0\0\0"
    .byte   9, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r10d\0\0\0\0"
    .byte   10, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r11d\0\0\0\0"
    .byte   11, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r12d\0\0\0\0"
    .byte   12, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r13d\0\0\0\0"
    .byte   13, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r14d\0\0\0\0"
    .byte   14, 4, 0, 0, 0, 0, 0, 0
    .ascii  "r15d\0\0\0\0"
    .byte   15, 4, 0, 0, 0, 0, 0, 0
    .ascii  "al\0\0\0\0\0\0"
    .byte   0, 1, 0, 0, 0, 0, 0, 0
    .ascii  "cl\0\0\0\0\0\0"
    .byte   1, 1, 0, 0, 0, 0, 0, 0
    .ascii  "dl\0\0\0\0\0\0"
    .byte   2, 1, 0, 0, 0, 0, 0, 0
    .ascii  "bl\0\0\0\0\0\0"
    .byte   3, 1, 0, 0, 0, 0, 0, 0
    .ascii  "spl\0\0\0\0\0"
    .byte   4, 1, 1, 0, 0, 0, 0, 0
    .ascii  "bpl\0\0\0\0\0"
    .byte   5, 1, 1, 0, 0, 0, 0, 0
    .ascii  "sil\0\0\0\0\0"
    .byte   6, 1, 1, 0, 0, 0, 0, 0
    .ascii  "dil\0\0\0\0\0"
    .byte   7, 1, 1, 0, 0, 0, 0, 0
    .ascii  "r8b\0\0\0\0\0"
    .byte   8, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r9b\0\0\0\0\0"
    .byte   9, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r10b\0\0\0\0"
    .byte   10, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r11b\0\0\0\0"
    .byte   11, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r12b\0\0\0\0"
    .byte   12, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r13b\0\0\0\0"
    .byte   13, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r14b\0\0\0\0"
    .byte   14, 1, 0, 0, 0, 0, 0, 0
    .ascii  "r15b\0\0\0\0"
    .byte   15, 1, 0, 0, 0, 0, 0, 0
    .quad   0, 0                        # the end

# The classes: 1 ALU (op its /digit), 2 test, 3 mov, 4 movzx (op the
# second opcode byte), 5 lea, 6 FE/FF or F6/F7 (op its /digit, + 0x10 for
# F6/F7), 7 shifts (op its /digit), 8 imul, 9 setcc (op the condition),
# 10 jcc (the condition), 11 jmp, 12 call, 13 one opcode byte (op), 14 0F
# then op.
mnemonics:
    .ascii  "add\0\0\0\0\0"
    .byte   1, 0, 0, 2, 0, 0, 0, 0
    .ascii  "addq\0\0\0\0"
    .byte   1, 0, 8, 2, 0, 0, 0, 0
    .ascii  "addl\0\0\0\0"
    .byte   1, 0, 4, 2, 0, 0, 0, 0
    .ascii  "addb\0\0\0\0"
    .byte   1, 0, 1, 2, 0, 0, 0, 0
    .ascii  "or\0\0\0\0\0\0"
    .byte   1, 1, 0, 2, 0, 0, 0, 0
    .ascii  "orq\0\0\0\0\0"
    .byte   1, 1, 8, 2, 0, 0, 0, 0
    .ascii  "orl\0\0\0\0\0"
    .byte   1, 1, 4, 2, 0, 0, 0, 0
    .ascii  "orb\0\0\0\0\0"
    .byte   1, 1, 1, 2, 0, 0, 0, 0
    .ascii  "and\0\0\0\0\0"
    .byte   1, 4, 0, 2, 0, 0, 0, 0
    .ascii  "andq\0\0\0\0"
    .byte   1, 4, 8, 2, 0, 0, 0, 0
    .ascii  "andl\0\0\0\0"
    .byte   1, 4, 4, 2, 0, 0, 0, 0
    .ascii  "andb\0\0\0\0"
    .byte   1, 4, 1, 2, 0, 0, 0, 0
    .ascii  "sub\0\0\0\0\0"
    .byte   1, 5, 0, 2, 0, 0, 0, 0
    .ascii  "subq\0\0\0\0"
    .byte   1, 5, 8, 2, 0, 0, 0, 0
    .ascii  "subl\0\0\0\0"
    .byte   1, 5, 4, 2, 0, 0, 0, 0
    .ascii  "subb\0\0\0\0"
    .byte   1, 5, 1, 2, 0, 0, 0, 0
    .ascii  "xor\0\0\0\0\0"
    .byte   1, 6, 0, 2, 0, 0, 0, 0
    .ascii  "xorq\0\0\0\0"
    .byte   1, 6, 8, 2, 0, 0, 0, 0
    .ascii  "xorl\0\0\0\0"
    .byte   1, 6, 4, 2, 0, 0, 0, 0
    .ascii  "xorb\0\0\0\0"
    .byte   1, 6, 1, 2, 0, 0, 0, 0
    .ascii  "cmp\0\0\0\0\0"
    .byte   1, 7, 0, 2, 0, 0, 0, 0
    .ascii  "cmpq\0\0\0\0"
    .byte   1, 7, 8, 2, 0, 0, 0, 0
    .ascii  "cmpl\0\0\0\0"
    .byte   1, 7, 4, 2, 0, 0, 0, 0
    .ascii  "cmpb\0\0\0\0"
    .byte   1, 7, 1, 2, 0, 0, 0, 0
    .ascii  "test\0\0\0\0"
    .byte   2, 0, 0, 2, 0, 0, 0, 0
    .ascii  "testq\0\0\0"
    .byte   2, 0, 8, 2, 0, 0, 0, 0
    .ascii  "testl\0\0\0"
    .byte   2, 0, 4, 2, 0, 0, 0, 0
    .ascii  "testb\0\0\0"
    .byte   2, 0, 1, 2, 0, 0, 0, 0
    .ascii  "mov\0\0\0\0\0"
    .byte   3, 0, 0, 2, 0, 0, 0, 0
    .ascii  "movq\0\0\0\0"
    .byte   3, 0, 8, 2, 0, 0, 0, 0
    .ascii  "movl\0\0\0\0"
    .byte   3, 0, 4, 2, 0, 0, 0, 0
    .ascii  "movb\0\0\0\0"
    .byte   3, 0, 1, 2, 0, 0, 0, 0
    .ascii  "movzbq\0\0"
    .byte   4, 0xb6, 8, 2, 0, 0, 0, 0
    .ascii  "movzbl\0\0"
    .byte   4, 0xb6, 4, 2, 0, 0, 0, 0
    .ascii  "lea\0\0\0\0\0"
    .byte   5, 0, 0, 2, 0, 0, 0, 0
    .ascii  "leaq\0\0\0\0"
    .byte   5, 0, 8, 2, 0, 0, 0, 0
    .ascii  "inc\0\0\0\0\0"
    .byte   6, 0, 0, 1, 0, 0, 0, 0
    .ascii  "incq\0\0\0\0"
    .byte   6, 0, 8, 1, 0, 0, 0, 0
    .ascii  "incl\0\0\0\0"
    .byte   6, 0, 4, 1, 0, 0, 0, 0
    .ascii  "incb\0\0\0\0"
    .byte   6, 0, 1, 1, 0, 0, 0, 0
    .ascii  "dec\0\0\0\0\0"
    .byte   6, 1, 0, 1, 0, 0, 0, 0
    .ascii  "decq\0\0\0\0"
    .byte   6, 1, 8, 1, 0, 0, 0, 0
    .ascii  "decl\0\0\0\0"
    .byte   6, 1, 4, 1, 0, 0, 0, 0
    .ascii  "decb\0\0\0\0"
    .byte   6, 1, 1, 1, 0, 0, 0, 0
    .ascii  "not\0\0\0\0\0"
    .byte   6, 0x12, 0, 1, 0, 0, 0, 0
    .ascii  "notq\0\0\0\0"
    .byte   6, 0x12, 8, 1, 0, 0, 0, 0
    .ascii  "neg\0\0\0\0\0"
    .byte   6, 0x13, 0, 1, 0, 0, 0, 0
    .ascii  "negq\0\0\0\0"
    .byte   6, 0x13, 8, 1, 0, 0, 0, 0
    .ascii  "mul\0\0\0\0\0"
    .byte   6, 0x14, 0, 1, 0, 0, 0, 0
    .ascii  "mulq\0\0\0\0"
    .byte   6, 0x14, 8, 1, 0, 0, 0, 0
    .ascii  "div\0\0\0\0\0"
    .byte   6, 0x16, 0, 1, 0, 0, 0, 0
    .ascii  "divq\0\0\0\0"
    .byte   6, 0x16, 8, 1, 0, 0, 0, 0
    .ascii  "idiv\0\0\0\0"
    .byte   6, 0x17, 0, 1, 0, 0, 0, 0
    .ascii  "idivq\0\0\0"
    .byte   6, 0x17, 8, 1, 0, 0, 0, 0
    .ascii  "shl\0\0\0\0\0"
    .byte   7, 4, 0, 2, 0, 0, 0, 0
    .ascii  "shlq\0\0\0\0"
    .byte   7, 4, 8, 2, 0, 0, 0, 0
    .ascii  "shll\0\0\0\0"
    .byte   7, 4, 4, 2, 0, 0, 0, 0
    .ascii  "shr\0\0\0\0\0"
    .byte   7, 5, 0, 2, 0, 0, 0, 0
    .ascii  "shrq\0\0\0\0"
    .byte   7, 5, 8, 2, 0, 0, 0, 0
    .ascii  "shrl\0\0\0\0"
    .byte   7, 5, 4, 2, 0, 0, 0, 0
    .ascii  "sar\0\0\0\0\0"
    .byte   7, 7, 0, 2, 0, 0, 0, 0
    .ascii  "sarq\0\0\0\0"
    .byte   7, 7, 8, 2, 0, 0, 0, 0
    .ascii  "sarl\0\0\0\0"
    .byte   7, 7, 4, 2, 0, 0, 0, 0
    .ascii  "imul\0\0\0\0"
    .byte   8, 0, 0, 2, 0, 0, 0, 0
    .ascii  "imulq\0\0\0"
    .byte   8, 0, 8, 2, 0, 0, 0, 0
    .ascii  "seto\0\0\0\0"
    .byte   9, 0, 1, 1, 0, 0, 0, 0
    .ascii  "setno\0\0\0"
    .byte   9, 1, 1, 1, 0, 0, 0, 0
    .ascii  "setb\0\0\0\0"
    .byte   9, 2, 1, 1, 0, 0, 0, 0
    .ascii  "setc\0\0\0\0"
    .byte   9, 2, 1, 1, 0, 0, 0, 0
    .ascii  "setae\0\0\0"
    .byte   9, 3, 1, 1, 0, 0, 0, 0
    .ascii  "setnc\0\0\0"
    .byte   9, 3, 1, 1, 0, 0, 0, 0
    .ascii  "sete\0\0\0\0"
    .byte   9, 4, 1, 1, 0, 0, 0, 0
    .ascii  "setz\0\0\0\0"
    .byte   9, 4, 1, 1, 0, 0, 0, 0
    .ascii  "setne\0\0\0"
    .byte   9, 5, 1, 1, 0, 0, 0, 0
    .ascii  "setnz\0\0\0"
    .byte   9, 5, 1, 1, 0, 0, 0, 0
    .ascii  "setbe\0\0\0"
    .byte   9, 6, 1, 1, 0, 0, 0, 0
    .ascii  "seta\0\0\0\0"
    .byte   9, 7, 1, 1, 0, 0, 0, 0
    .ascii  "sets\0\0\0\0"
    .byte   9, 8, 1, 1, 0, 0, 0, 0
    .ascii  "setns\0\0\0"
    .byte   9, 9, 1, 1, 0, 0, 0, 0
    .ascii  "setl\0\0\0\0"
    .byte   9, 0xc, 1, 1, 0, 0, 0, 0
    .ascii  "setge\0\0\0"
    .byte   9, 0xd, 1, 1, 0, 0, 0, 0
    .ascii  "setle\0\0\0"
    .byte   9, 0xe, 1, 1, 0, 0, 0, 0
    .ascii  "setg\0\0\0\0"
    .byte   9, 0xf, 1, 1, 0, 0, 0, 0
    .ascii  "jo\0\0\0\0\0\0"
    .byte   10, 0, 0, 1, 0, 0, 0, 0
    .ascii  "jno\0\0\0\0\0"
    .byte   10, 1, 0, 1, 0, 0, 0, 0
    .ascii  "jb\0\0\0\0\0\0"
    .byte   10, 2, 0, 1, 0, 0, 0, 0
    .ascii  "jc\0\0\0\0\0\0"
    .byte   10, 2, 0, 1, 0, 0, 0, 0
    .ascii  "jnae\0\0\0\0"
    .byte   10, 2, 0, 1, 0, 0, 0, 0
    .ascii  "jae\0\0\0\0\0"
    .byte   10, 3, 0, 1, 0, 0, 0, 0
    .ascii  "jnb\0\0\0\0\0"
    .byte   10, 3, 0, 1, 0, 0, 0, 0
    .ascii  "jnc\0\0\0\0\0"
    .byte   10, 3, 0, 1, 0, 0, 0, 0
    .ascii  "je\0\0\0\0\0\0"
    .byte   10, 4, 0, 1, 0, 0, 0, 0
    .ascii  "jz\0\0\0\0\0\0"
    .byte   10, 4, 0, 1, 0, 0, 0, 0
    .ascii  "jne\0\0\0\0\0"
    .byte   10, 5, 0, 1, 0, 0, 0, 0
    .ascii  "jnz\0\0\0\0\0"
    .byte   10, 5, 0, 1, 0, 0, 0, 0
    .ascii  "jbe\0\0\0\0\0"
    .byte   10, 6, 0, 1, 0, 0, 0, 0
    .ascii  "jna\0\0\0\0\0"
    .byte   10, 6, 0, 1, 0, 0, 0, 0
    .ascii  "ja\0\0\0\0\0\0"
    .byte   10, 7, 0, 1, 0, 0, 0, 0
    .ascii  "jnbe\0\0\0\0"
    .byte   10, 7, 0, 1, 0, 0, 0, 0
    .ascii  "js\0\0\0\0\0\0"
    .byte   10, 8, 0, 1, 0, 0, 0, 0
    .ascii  "jns\0\0\0\0\0"
    .byte   10, 9, 0, 1, 0, 0, 0, 0
    .ascii  "jp\0\0\0\0\0\0"
    .byte   10, 0xa, 0, 1, 0, 0, 0, 0
    .ascii  "jnp\0\0\0\0\0"
    .byte   10, 0xb, 0, 1, 0, 0, 0, 0
    .ascii  "jl\0\0\0\0\0\0"
    .byte   10, 0xc, 0, 1, 0, 0, 0, 0
    .ascii  "jnge\0\0\0\0"
    .byte   10, 0xc, 0, 1, 0, 0, 0, 0
    .ascii  "jge\0\0\0\0\0"
    .byte   10, 0xd, 0, 1, 0, 0, 0, 0
    .ascii  "jnl\0\0\0\0\0"
    .byte   10, 0xd, 0, 1, 0, 0, 0, 0
    .ascii  "jle\0\0\0\0\0"
    .byte   10, 0xe, 0, 1, 0, 0, 0, 0
    .ascii  "jng\0\0\0\0\0"
    .byte   10, 0xe, 0, 1, 0, 0, 0, 0
    .ascii  "jg\0\0\0\0\0\0"
    .byte   10, 0xf, 0, 1, 0, 0, 0, 0
    .ascii  "jnle\0\0\0\0"
    .byte   10, 0xf, 0, 1, 0, 0, 0, 0
    .ascii  "jmp\0\0\0\0\0"
    .byte   11, 0, 0, 1, 0, 0, 0, 0
    .ascii  "call\0\0\0\0"
    .byte   12, 0, 0, 1, 0, 0, 0, 0
    .ascii  "ret\0\0\0\0\0"
    .byte   13, 0xc3, 0, 0, 0, 0, 0, 0
    .ascii  "nop\0\0\0\0\0"
    .byte   13, 0x90, 0, 0, 0, 0, 0, 0
    .ascii  "syscall\0"
    .byte   14, 0x05, 0, 0, 0, 0, 0, 0
    .quad   0, 0                        # the end

elf_headers:                            # ld's: the ELF header and the two program headers, 0xb0 bytes
    .byte   0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0    # e_ident: 0x7f "ELF", 64-bit, little endian, version 1, System V
    .byte   0, 0, 0, 0, 0, 0, 0, 0              # padding
    .word   2                           # e_type: ET_EXEC
    .word   0x3e                        # e_machine: EM_X86_64
    .long   1                           # e_version
    .quad   0                           # e_entry: _start (headers)
    .quad   0x40                        # e_phoff: the program headers follow
    .quad   0                           # e_shoff: the section headers (headers)
    .long   0                           # e_flags
    .word   0x40                        # e_ehsize
    .word   0x38                        # e_phentsize
    .word   2                           # e_phnum
    .word   0x40                        # e_shentsize
    .word   6                           # e_shnum: 0 .text .rodata .data .bss .shstrtab
    .word   5                           # e_shstrndx: .shstrtab
    .long   1                           # p_type: PT_LOAD, the code
    .long   5                           # p_flags: R X
    .quad   0                           # p_offset: from the file's first byte
    .quad   ADDR                        # p_vaddr
    .quad   ADDR                        # p_paddr
    .quad   0                           # p_filesz: to the end of .rodata (headers)
    .quad   0                           # p_memsz: the same (headers)
    .quad   0x1000                      # p_align
    .long   1                           # p_type: PT_LOAD, the data
    .long   6                           # p_flags: R W
    .quad   0                           # p_offset: .data's (headers)
    .quad   0                           # p_vaddr: .data's address (headers)
    .quad   0                           # p_paddr: the same (headers)
    .quad   0                           # p_filesz: .data (headers)
    .quad   0                           # p_memsz: to the end of .bss (headers)
    .quad   0x1000                      # p_align

shstrtab:                               # the section names, as ld orders them
    .ascii  "\0.shstrtab\0.text\0.rodata\0.data\0.bss\0"
    .equ shstrtab_len, . - shstrtab

section_headers:                        # the six, without what headers fills in
    .quad   0, 0, 0, 0, 0, 0, 0, 0      # 0: none
    .long   0x0b, 1                     # 1: .text: its name, SHT_PROGBITS
    .quad   6, 0, 0, 0                  # SHF_ALLOC | SHF_EXECINSTR; addr, offset, size
    .long   0, 0                        # sh_link, sh_info
    .quad   0, 0                        # sh_addralign, sh_entsize
    .long   0x11, 1                     # 2: .rodata, SHT_PROGBITS
    .quad   2, 0, 0, 0                  # SHF_ALLOC
    .long   0, 0
    .quad   0, 0
    .long   0x19, 1                     # 3: .data, SHT_PROGBITS
    .quad   3, 0, 0, 0                  # SHF_WRITE | SHF_ALLOC
    .long   0, 0
    .quad   0, 0
    .long   0x1f, 8                     # 4: .bss, SHT_NOBITS
    .quad   3, 0, 0, 0                  # SHF_WRITE | SHF_ALLOC
    .long   0, 0
    .quad   0, 0
    .long   0x01, 3                     # 5: .shstrtab, SHT_STRTAB
    .quad   0, 0, 0, shstrtab_len       # no flags, address; offset; size
    .long   0, 0
    .quad   1, 0                        # sh_addralign 1

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
msg_operands:   .asciz "wrong number of operands"
msg_operand:    .asciz "bad operand"
msg_size:       .asciz "operand size unknown"
msg_range:      .asciz "out of range"
msg_target:     .asciz "jump to another section"
msg_unstable:   .asciz "jump changed in the last pass"
msg_bss:        .asciz "bytes in .bss"
msg_full:       .asciz "output too large"
msg_empty:      .asciz ".text, .rodata, .data and .bss each need bytes"
msg_start:      .asciz "no _start"
msg_large:      .asciz "input too large"
msg_read:       .asciz "read failed"
msg_write:      .asciz "write failed"
end:
