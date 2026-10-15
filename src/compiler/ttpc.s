# ttpc.s — the trust project compiler, in RISC-V assembly, without libc.
#
# A static Linux riscv64 program (run it with qemu-riscv64 on another host).
# It talks to the kernel only through ecall: it opens the ff file named by
# its first argument and loads it into memory as a tree of NODEs.
#
#   ttpc <file.ff>          prints the tree, one node per line
#   ttpc <file.ff> <out>    assembles it into the static executable <out>
#
# Assembling: a node whose content ends in ':' is a function, its leading
# children that are leaves are its parameters. Any other node is a call, its
# children are the arguments. The functions are the children of the root's
# children (the pages 0:, 1:, ...), the calls among those children are the
# program, assembled in order. A function with a fixed field (funct3:, ...)
# among its children is an instruction. The calls run in one of three
# contexts:
#
#   code   a call of an instruction is encoded and emitted, a call of any
#          other function expands its body in code context. An argument is
#          a parameter, a register name (its number) or a decimal number.
#   field  encoding: the instruction's fields, MSB first. A fixed field is
#          its bits; a slice call (imm[11:0] imm) runs in exec context and
#          leaves its value in a0, its width is in its name.
#   exec   runs at assemble time on vregs: a register name is that vreg.
#          Only addi, slli, srli and or are built in, the seed; everything
#          else is defined by the tree.
#
# Registers are the functions "x10 a0:", their number is their child "01010".
# The output is the code behind a fixed ELF header (one RWX PT_LOAD).
#
# ff on disk, one node, depth-first (children inline, before the content):
#   hash          byte[32]
#   children_len  u8
#   children      node × children_len
#   content_len   u8
#   content       byte × content_len    // no NUL termination: may be binary
#
# NODE in memory (64 bytes, naturally aligned):
#   0   hash          byte[32]
#   32  children_len  int8
#   40  children      NODE**            // -> pointer array in ptrs
#   48  content_len   int8
#   56  content       char*             // -> into buf, not copied

    .equ SYS_openat, 56
    .equ SYS_close, 57
    .equ SYS_read, 63
    .equ SYS_write, 64
    .equ SYS_exit, 93

    .equ AT_FDCWD, -100
    .equ O_RDONLY, 0
    .equ O_CREAT_WRONLY_TRUNC, 01 | 0100 | 01000
    .equ MODE_0755, 0755
    .equ STDOUT, 1
    .equ STDERR, 2

    .equ CH_space, 32
    .equ CH_minus, 45
    .equ CH_zero, 48
    .equ CH_colon, 58
    .equ CH_lbracket, 91
    .equ CH_rbracket, 93
    .equ CH_bar, 124

    # A frame binds the parameters of a call: count, then (param NODE*,
    # value) pairs.
    .equ MAX_PARAMS, 8
    .equ FRAME_count, 0
    .equ FRAME_params, 8
    .equ FRAME_size, 8 + MAX_PARAMS * 16

    .equ VREG_a0, 10
    .equ OUT_SIZE, 1 << 16
    .equ ELF_size, 64 + 56              # ELF header + one program header
    .equ ELF_base, 0x10000

    .equ NODE_hash, 0
    .equ NODE_children_len, 32
    .equ NODE_children, 40
    .equ NODE_content_len, 48
    .equ NODE_content, 56
    .equ NODE_size, 64

    .equ BUF_SIZE, 1 << 20
    # Every node takes at least 34 bytes on disk, so a full buf holds fewer
    # than MAX_NODES nodes: the node and pointer arenas cannot overflow.
    .equ MAX_NODES, BUF_SIZE / 32

    .section .rodata
msg_usage:      .ascii "usage: ttpc <file.ff> [<out>]\n"
    .equ msg_usage_len, . - msg_usage
msg_open:       .ascii "ttpc: cannot open file\n"
    .equ msg_open_len, . - msg_open
msg_read:       .ascii "ttpc: read failed\n"
    .equ msg_read_len, . - msg_read
msg_large:      .ascii "ttpc: file too large\n"
    .equ msg_large_len, . - msg_large
msg_truncated:  .ascii "ttpc: truncated node\n"
    .equ msg_truncated_len, . - msg_truncated
msg_trailing:   .ascii "ttpc: trailing bytes after the root node\n"
    .equ msg_trailing_len, . - msg_trailing
msg_create:     .ascii "ttpc: cannot create output file\n"
    .equ msg_create_len, . - msg_create
msg_write:      .ascii "ttpc: write failed\n"
    .equ msg_write_len, . - msg_write
msg_full:       .ascii "ttpc: output too large\n"
    .equ msg_full_len, . - msg_full
# Followed by the name they are about:
msg_function:   .ascii "ttpc: unknown function: "
    .equ msg_function_len, . - msg_function
msg_name:       .ascii "ttpc: unknown name: "
    .equ msg_name_len, . - msg_name
msg_args:       .ascii "ttpc: wrong number of arguments: "
    .equ msg_args_len, . - msg_args
msg_params:     .ascii "ttpc: too many parameters: "
    .equ msg_params_len, . - msg_params
msg_register:   .ascii "ttpc: not a register: "
    .equ msg_register_len, . - msg_register
msg_execute:    .ascii "ttpc: cannot execute: "
    .equ msg_execute_len, . - msg_execute
msg_field:      .ascii "ttpc: fixed field without bits: "
    .equ msg_field_len, . - msg_field
msg_slice:      .ascii "ttpc: bad slice: "
    .equ msg_slice_len, . - msg_slice
msg_width:      .ascii "ttpc: width is not 16 or 32: "
    .equ msg_width_len, . - msg_width
hexdigits:      .ascii "0123456789abcdef"
indent:         .ascii "  "
newline:        .ascii "\n"
str_rd:         .ascii "rd"
str_addi:       .ascii "addi"
str_slli:       .ascii "slli"
str_srli:       .ascii "srli"
str_or:         .ascii "or"

    .section .data
hexbuf:         .ascii "00000000  "         # hash prefix of a printed line
    .balign 8
out_path:       .dword 0                    # argv[2], 0 when only printing
out_end:        .dword outbuf               # next free byte in outbuf
syms_end:       .dword syms                 # next free slot in syms

# The ELF header and its one program header: the whole file is loaded RWX
# at ELF_base, the code follows the headers. write_elf fills in the sizes.
# Kept here until the header can be written in ff itself.
elf_header:
    .byte   0x7f, 0x45, 0x4c, 0x46, 2, 1, 1, 0  # "\177ELF", 64-bit, LE, SysV
    .dword  0
    .half   2                               # e_type: ET_EXEC
    .half   243                             # e_machine: EM_RISCV
    .word   1                               # e_version
    .dword  ELF_base + ELF_size             # e_entry
    .dword  64                              # e_phoff
    .dword  0                               # e_shoff
    .word   1                               # e_flags: EF_RISCV_RVC
    .half   64                              # e_ehsize
    .half   56                              # e_phentsize
    .half   1                               # e_phnum
    .half   64, 0, 0                        # e_shentsize, e_shnum, e_shstrndx
    .word   1                               # p_type: PT_LOAD
    .word   7                               # p_flags: RWX
    .dword  0                               # p_offset
    .dword  ELF_base                        # p_vaddr
    .dword  ELF_base                        # p_paddr
elf_filesz:     .dword 0
elf_memsz:      .dword 0
    .dword  0x1000                          # p_align

    .section .bss
    .balign 8
nodes:          .skip MAX_NODES * NODE_size
ptrs:           .skip MAX_NODES * 8
syms:           .skip MAX_NODES * 8         # the function NODEs, see collect_syms
vregs:          .skip 32 * 8                # the registers of exec context
linebuf:        .skip 16                    # hex of an emitted instruction
outbuf:         .skip OUT_SIZE
buf:            .skip BUF_SIZE

# Registers that live across the whole program:
#   s0  parse cursor in buf
#   s1  end of the loaded bytes
#   s2  next free NODE in nodes
#   s3  next free slot in ptrs

    .section .text
    .globl _start
_start:
    .option push
    .option norelax
    la      gp, __global_pointer$
    .option pop

    ld      t0, 0(sp)                   # argc
    li      t1, 2
    blt     t0, t1, usage
    li      t1, 3
    bgt     t0, t1, usage
    blt     t0, t1, 1f
    ld      t1, 24(sp)                  # argv[2]
    la      t2, out_path
    sd      t1, 0(t2)
1:  ld      a1, 16(sp)                  # argv[1]

    li      a0, AT_FDCWD
    li      a2, O_RDONLY
    li      a3, 0
    li      a7, SYS_openat
    ecall
    bltz    a0, open_failed
    mv      s4, a0                      # fd

    # Read the whole file into buf.
    la      s0, buf
    mv      s1, s0
    li      t0, BUF_SIZE
    add     s5, s0, t0                  # end of buf
read_loop:
    beq     s1, s5, too_large
    mv      a0, s4
    mv      a1, s1
    sub     a2, s5, s1
    li      a7, SYS_read
    ecall
    bltz    a0, read_failed
    beqz    a0, read_done
    add     s1, s1, a0
    j       read_loop
read_done:
    mv      a0, s4
    li      a7, SYS_close
    ecall

    la      s2, nodes
    la      s3, ptrs
    call    parse_node
    bne     s0, s1, trailing
    la      t0, out_path
    ld      t0, 0(t0)
    bnez    t0, assemble
    li      a1, 0
    call    print_node

    li      a0, 0
    j       exit

# assemble: runs the calls of every page of root a0 in code context and
# writes the output file.
assemble:
    mv      s6, a0                      # root
    call    collect_syms
    lbu     s7, NODE_children_len(s6)   # pages left
    ld      s8, NODE_children(s6)       # next page
1:  beqz    s7, 2f
    ld      a0, 0(s8)
    li      a1, 0                       # no frame: a page has no parameters
    la      a2, code_call
    li      a3, 0
    call    run_body
    addi    s8, s8, 8
    addi    s7, s7, -1
    j       1b
2:  call    write_elf
    li      a0, 0
    j       exit

# parse_node: reads the node at s0 into a new NODE, recursing on its
# children, and leaves s0 just past it. Returns the NODE in a0.
parse_node:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # this NODE
    sd      s5, 16(sp)                  # next slot in its children array
    sd      s6, 24(sp)                  # children left to parse

    addi    t0, s0, 33                  # hash + children_len
    bgtu    t0, s1, truncated
    mv      s4, s2
    addi    s2, s2, NODE_size

    li      t1, 32                      # copy the hash
    mv      t2, s4
1:  lbu     t3, 0(s0)
    sb      t3, NODE_hash(t2)
    addi    s0, s0, 1
    addi    t2, t2, 1
    addi    t1, t1, -1
    bnez    t1, 1b

    lbu     s6, 0(s0)
    addi    s0, s0, 1
    sb      s6, NODE_children_len(s4)
    mv      s5, s3
    sd      s5, NODE_children(s4)
    slli    t0, s6, 3
    add     s3, s3, t0
2:  beqz    s6, 3f
    call    parse_node
    sd      a0, 0(s5)
    addi    s5, s5, 8
    addi    s6, s6, -1
    j       2b

3:  bgeu    s0, s1, truncated
    lbu     t0, 0(s0)
    addi    s0, s0, 1
    sb      t0, NODE_content_len(s4)
    sd      s0, NODE_content(s4)
    add     s0, s0, t0
    bgtu    s0, s1, truncated

    mv      a0, s4
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, 32
    ret

# print_node: prints NODE a0 at depth a1 as "<hash[0..4] in hex>  <indent>
# <content>", then its children one level deeper.
print_node:
    addi    sp, sp, -48
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # this NODE
    sd      s5, 16(sp)                  # depth
    sd      s6, 24(sp)                  # counter
    sd      s7, 32(sp)                  # next child pointer
    mv      s4, a0
    mv      s5, a1

    la      t0, hexbuf
    la      t1, hexdigits
    li      t2, 4
    mv      t3, s4
1:  lbu     t4, NODE_hash(t3)
    srli    t5, t4, 4
    add     t5, t1, t5
    lbu     t5, 0(t5)
    sb      t5, 0(t0)
    andi    t4, t4, 15
    add     t4, t1, t4
    lbu     t4, 0(t4)
    sb      t4, 1(t0)
    addi    t0, t0, 2
    addi    t3, t3, 1
    addi    t2, t2, -1
    bnez    t2, 1b
    la      a1, hexbuf
    li      a2, 10
    call    write_out

    mv      s6, s5
2:  beqz    s6, 3f
    la      a1, indent
    li      a2, 2
    call    write_out
    addi    s6, s6, -1
    j       2b

3:  ld      a1, NODE_content(s4)
    lbu     a2, NODE_content_len(s4)
    call    write_out
    la      a1, newline
    li      a2, 1
    call    write_out

    lbu     s6, NODE_children_len(s4)
    ld      s7, NODE_children(s4)
4:  beqz    s6, 5f
    ld      a0, 0(s7)
    addi    a1, s5, 1
    call    print_node
    addi    s7, s7, 8
    addi    s6, s6, -1
    j       4b

5:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    addi    sp, sp, 48
    ret

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------

# streq: a0 = 1 when the a1 bytes at a0 equal the a3 bytes at a2, else 0.
streq:
    bne     a1, a3, 2f
1:  beqz    a1, 3f
    lbu     t0, 0(a0)
    lbu     t1, 0(a2)
    bne     t0, t1, 2f
    addi    a0, a0, 1
    addi    a2, a2, 1
    addi    a1, a1, -1
    j       1b
2:  li      a0, 0
    ret
3:  li      a0, 1
    ret

# is_fn: a0 = 1 when NODE a0 is a function (its content ends in ':'), else 0.
is_fn:
    lbu     t0, NODE_content_len(a0)
    beqz    t0, 1f
    ld      t1, NODE_content(a0)
    add     t1, t1, t0
    lbu     t1, -1(t1)
    addi    t1, t1, -CH_colon
    seqz    a0, t1
    ret
1:  li      a0, 0
    ret

# param_count: a0 = the number of parameters of function NODE a0: its
# leading children that are leaves and no function.
param_count:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # children left
    sd      s5, 16(sp)                  # next child
    sd      s6, 24(sp)                  # count
    lbu     s4, NODE_children_len(a0)
    ld      s5, NODE_children(a0)
    li      s6, 0
1:  beqz    s4, 2f
    ld      a0, 0(s5)
    lbu     t0, NODE_children_len(a0)
    bnez    t0, 2f
    call    is_fn
    bnez    a0, 2f
    addi    s6, s6, 1
    addi    s5, s5, 8
    addi    s4, s4, -1
    j       1b
2:  mv      a0, s6
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, 32
    ret

# is_insn: a0 = 1 when function NODE a0 is an instruction, that is when it
# has a fixed field (a function) among its children, else 0.
is_insn:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # children left
    sd      s5, 16(sp)                  # next child
    lbu     s4, NODE_children_len(a0)
    ld      s5, NODE_children(a0)
1:  li      a0, 0
    beqz    s4, 2f
    ld      a0, 0(s5)
    call    is_fn
    bnez    a0, 2f
    addi    s5, s5, 8
    addi    s4, s4, -1
    j       1b
2:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    addi    sp, sp, 32
    ret

# collect_syms: stores every function among the children of the pages of
# root a0 in syms.
collect_syms:
    addi    sp, sp, -64
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # pages left
    sd      s5, 16(sp)                  # next page
    sd      s6, 24(sp)                  # next free slot in syms
    sd      s7, 32(sp)                  # children of the page left
    sd      s8, 40(sp)                  # next child
    lbu     s4, NODE_children_len(a0)
    ld      s5, NODE_children(a0)
    la      s6, syms
1:  beqz    s4, 4f
    ld      t0, 0(s5)
    lbu     s7, NODE_children_len(t0)
    ld      s8, NODE_children(t0)
2:  beqz    s7, 3f
    ld      a0, 0(s8)
    call    is_fn
    beqz    a0, 5f
    ld      t0, 0(s8)
    sd      t0, 0(s6)
    addi    s6, s6, 8
5:  addi    s8, s8, 8
    addi    s7, s7, -1
    j       2b
3:  addi    s5, s5, 8
    addi    s4, s4, -1
    j       1b
4:  la      t0, syms_end
    sd      s6, 0(t0)
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    ld      s8, 40(sp)
    addi    sp, sp, 64
    ret

# find_fn: a0 = the function named by the a1 bytes at a0 (its content
# without the ':'), or 0.
find_fn:
    addi    sp, sp, -48
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # next sym
    sd      s5, 16(sp)                  # end of syms
    sd      s6, 24(sp)                  # name
    sd      s7, 32(sp)                  # name length
    mv      s6, a0
    mv      s7, a1
    la      s4, syms
    la      s5, syms_end
    ld      s5, 0(s5)
1:  li      a0, 0
    beq     s4, s5, 2f
    ld      t0, 0(s4)
    ld      a2, NODE_content(t0)
    lbu     a3, NODE_content_len(t0)
    addi    a3, a3, -1
    mv      a0, s6
    mv      a1, s7
    call    streq
    addi    s4, s4, 8
    beqz    a0, 1b
    ld      a0, -8(s4)
2:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    addi    sp, sp, 48
    ret

# find_reg: a0 = the number of the register named by the a1 bytes at a0, or
# -1. A register is a function of two words, "x10 a0:", either one is its
# name; its number is the bits of its child.
find_reg:
    addi    sp, sp, -80
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # next sym
    sd      s5, 16(sp)                  # end of syms
    sd      s6, 24(sp)                  # name
    sd      s7, 32(sp)                  # name length
    sd      s8, 40(sp)                  # the sym
    sd      s9, 48(sp)                  # its content
    sd      s10, 56(sp)                 # its length without the ':'
    sd      s11, 64(sp)                 # length of its first word
    mv      s6, a0
    mv      s7, a1
    la      s4, syms
    la      s5, syms_end
    ld      s5, 0(s5)
1:  beq     s4, s5, 5f
    ld      s8, 0(s4)
    addi    s4, s4, 8
    lbu     t0, NODE_children_len(s8)
    beqz    t0, 1b
    ld      s9, NODE_content(s8)
    lbu     s10, NODE_content_len(s8)
    addi    s10, s10, -1
    li      s11, 0                      # find the space
2:  beq     s11, s10, 1b
    add     t0, s9, s11
    lbu     t0, 0(t0)
    li      t1, CH_space
    beq     t0, t1, 3f
    addi    s11, s11, 1
    j       2b
3:  mv      a0, s6
    mv      a1, s7
    mv      a2, s9
    mv      a3, s11
    call    streq
    bnez    a0, 4f
    mv      a0, s6
    mv      a1, s7
    add     a2, s9, s11
    addi    a2, a2, 1
    sub     a3, s10, s11
    addi    a3, a3, -1
    call    streq
    beqz    a0, 1b
4:  ld      t0, NODE_children(s8)
    ld      t0, 0(t0)
    ld      a0, NODE_content(t0)
    lbu     a1, NODE_content_len(t0)
    call    parse_bits
    j       6f
5:  li      a0, -1
6:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    ld      s8, 40(sp)
    ld      s9, 48(sp)
    ld      s10, 56(sp)
    ld      s11, 64(sp)
    addi    sp, sp, 80
    ret

# ---------------------------------------------------------------------------
# Numbers
# ---------------------------------------------------------------------------

# parse_bits: a0 = the a1 binary digits at a0 ("0010011") as a number.
parse_bits:
    li      t0, 0
1:  beqz    a1, 2f
    lbu     t1, 0(a0)
    addi    t1, t1, -CH_zero
    slli    t0, t0, 1
    or      t0, t0, t1
    addi    a0, a0, 1
    addi    a1, a1, -1
    j       1b
2:  mv      a0, t0
    ret

# parse_dec: reads the decimal digits from a0 up to at most a1; a0 = their
# value, a1 = just past them.
parse_dec:
    li      t0, 0
    li      t2, 10
1:  beq     a0, a1, 2f
    lbu     t1, 0(a0)
    addi    t1, t1, -CH_zero
    bgeu    t1, t2, 2f
    mul     t0, t0, t2
    add     t0, t0, t1
    addi    a0, a0, 1
    j       1b
2:  mv      a1, a0
    mv      a0, t0
    ret

# parse_num: a0 = the a1 bytes at a0 as a decimal number with an optional
# '-', and a1 = 1; or a1 = 0 when they are no number.
parse_num:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # negative?
    sd      s5, 16(sp)                  # first digit
    sd      s6, 24(sp)                  # end
    add     a1, a0, a1
    mv      s6, a1
    li      s4, 0
    beq     a0, a1, 2f
    lbu     t0, 0(a0)
    li      t1, CH_minus
    bne     t0, t1, 1f
    li      s4, 1
    addi    a0, a0, 1
1:  mv      s5, a0
    call    parse_dec
    beq     a1, s5, 2f                  # no digits
    bne     a1, s6, 2f                  # something after them
    beqz    s4, 3f
    neg     a0, a0
3:  li      a1, 1
    j       4f
2:  li      a1, 0
4:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, 32
    ret

# slice_width: a0 = the width of the slice named by the a1 bytes at a0: the
# sum of hi-lo+1 over the segments of "imm[20|10:1|11|19:12]".
slice_width:
    addi    sp, sp, -64
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # cursor
    sd      s5, 16(sp)                  # end
    sd      s6, 24(sp)                  # name
    sd      s7, 32(sp)                  # name length
    sd      s8, 40(sp)                  # width
    mv      s6, a0
    mv      s7, a1
    mv      s4, a0
    add     s5, a0, a1
    li      s8, 0
1:  beq     s4, s5, 9f                  # skip to just past the '['
    lbu     t0, 0(s4)
    addi    s4, s4, 1
    li      t1, CH_lbracket
    bne     t0, t1, 1b
2:  mv      a0, s4                      # a segment: hi or hi:lo
    mv      a1, s5
    call    parse_dec
    beq     a1, s4, 9f
    mv      s4, a1
    addi    s8, s8, 1
    beq     s4, s5, 9f
    lbu     t0, 0(s4)
    li      t1, CH_colon
    bne     t0, t1, 3f
    sd      a0, 48(sp)                  # hi
    addi    s4, s4, 1
    mv      a0, s4
    mv      a1, s5
    call    parse_dec
    beq     a1, s4, 9f
    mv      s4, a1
    ld      t0, 48(sp)
    sub     t0, t0, a0
    add     s8, s8, t0
    beq     s4, s5, 9f
    lbu     t0, 0(s4)
3:  addi    s4, s4, 1
    li      t1, CH_bar
    beq     t0, t1, 2b
    li      t1, CH_rbracket
    bne     t0, t1, 9f
    bne     s4, s5, 9f
    mv      a0, s8
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    ld      s8, 40(sp)
    addi    sp, sp, 64
    ret
9:  la      a1, msg_slice
    li      a2, msg_slice_len
    mv      a3, s6
    mv      a4, s7
    j       die_name

# ---------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------

# frame_lookup: looks up the parameter named by the a2 bytes at a1 in frame
# a0 (0: none). a0 = 1 and a1 = its value when found, else a0 = 0.
frame_lookup:
    addi    sp, sp, -48
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # pairs left
    sd      s5, 16(sp)                  # next pair
    sd      s6, 24(sp)                  # name
    sd      s7, 32(sp)                  # name length
    beqz    a0, 2f
    mv      s6, a1
    mv      s7, a2
    ld      s4, FRAME_count(a0)
    addi    s5, a0, FRAME_params
1:  beqz    s4, 2f
    ld      t0, 0(s5)
    ld      a2, NODE_content(t0)
    lbu     a3, NODE_content_len(t0)
    mv      a0, s6
    mv      a1, s7
    call    streq
    bnez    a0, 3f
    addi    s5, s5, 16
    addi    s4, s4, -1
    j       1b
2:  li      a0, 0
    j       4f
3:  ld      a1, 8(s5)
4:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    addi    sp, sp, 48
    ret

# eval_arg: a0 = the value of the argument named by the a2 bytes at a1, in
# frame a0: a parameter, a register or a decimal number. A register is its
# number in code context (a3 = 0), its vreg in exec context (a3 = 1).
eval_arg:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # name
    sd      s5, 16(sp)                  # name length
    sd      s6, 24(sp)                  # context
    mv      s4, a1
    mv      s5, a2
    mv      s6, a3
    call    frame_lookup
    beqz    a0, 1f
    mv      a0, a1
    j       3f
1:  mv      a0, s4
    mv      a1, s5
    call    find_reg
    bltz    a0, 2f
    beqz    s6, 3f
    la      t0, vregs
    slli    a0, a0, 3
    add     t0, t0, a0
    ld      a0, 0(t0)
    j       3f
2:  mv      a0, s4
    mv      a1, s5
    call    parse_num
    beqz    a1, 4f
3:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, 32
    ret
4:  la      a1, msg_name
    li      a2, msg_name_len
    mv      a3, s4
    mv      a4, s5
    j       die_name

# bind: fills frame a4 for call a1 of function a0: each parameter with the
# value of its argument, evaluated in frame a2 and context a3.
bind:
    addi    sp, sp, -64
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # next parameter
    sd      s5, 16(sp)                  # next argument
    sd      s6, 24(sp)                  # caller's frame
    sd      s7, 32(sp)                  # context
    sd      s8, 40(sp)                  # next pair in the new frame
    sd      s9, 48(sp)                  # parameters left
    mv      s4, a0
    mv      s5, a1
    mv      s6, a2
    mv      s7, a3
    mv      s8, a4
    call    param_count
    mv      s9, a0
    lbu     t0, NODE_children_len(s5)
    la      a1, msg_args
    li      a2, msg_args_len
    bne     t0, s9, 3f
    li      t0, MAX_PARAMS
    la      a1, msg_params
    li      a2, msg_params_len
    bgtu    s9, t0, 3f
    sd      s9, FRAME_count(s8)
    addi    s8, s8, FRAME_params
    ld      s4, NODE_children(s4)
    ld      s5, NODE_children(s5)
1:  beqz    s9, 2f
    ld      t0, 0(s4)
    sd      t0, 0(s8)
    ld      t0, 0(s5)
    mv      a0, s6
    ld      a1, NODE_content(t0)
    lbu     a2, NODE_content_len(t0)
    mv      a3, s7
    call    eval_arg
    sd      a0, 8(s8)
    addi    s4, s4, 8
    addi    s5, s5, 8
    addi    s8, s8, 16
    addi    s9, s9, -1
    j       1b
2:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    ld      s8, 40(sp)
    ld      s9, 48(sp)
    addi    sp, sp, 64
    ret
3:  ld      a3, NODE_content(s5)
    lbu     a4, NODE_content_len(s5)
    j       die_name

# run_body: calls a2 (code_call or exec_call) with frame a1 on each child
# of NODE a0 from child a3 on, skipping the functions (definitions).
run_body:
    addi    sp, sp, -48
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # children left
    sd      s5, 16(sp)                  # next child
    sd      s6, 24(sp)                  # frame
    sd      s7, 32(sp)                  # handler
    lbu     s4, NODE_children_len(a0)
    sub     s4, s4, a3
    ld      s5, NODE_children(a0)
    slli    t0, a3, 3
    add     s5, s5, t0
    mv      s6, a1
    mv      s7, a2
1:  beqz    s4, 3f
    ld      a0, 0(s5)
    call    is_fn
    bnez    a0, 2f
    ld      a0, 0(s5)
    mv      a1, s6
    jalr    s7
2:  addi    s5, s5, 8
    addi    s4, s4, -1
    j       1b
3:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    addi    sp, sp, 48
    ret

# lookup_call: a0 = the function that call a0 calls; dies when unknown.
lookup_call:
    addi    sp, sp, -16
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # the call
    mv      s4, a0
    ld      a0, NODE_content(s4)
    lbu     a1, NODE_content_len(s4)
    call    find_fn
    beqz    a0, 1f
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    addi    sp, sp, 16
    ret
1:  la      a1, msg_function
    li      a2, msg_function_len
    ld      a3, NODE_content(s4)
    lbu     a4, NODE_content_len(s4)
    j       die_name

    .equ CALL_frame, 32                 # the new frame on the stack
    .equ CALL_stack, (CALL_frame + FRAME_size + 15) & ~15

# code_call: runs call a0 in code context, in frame a1: an instruction is
# encoded and emitted, any other function expands its body.
code_call:
    addi    sp, sp, -CALL_stack
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # the call
    sd      s5, 16(sp)                  # caller's frame
    sd      s6, 24(sp)                  # the function
    mv      s4, a0
    mv      s5, a1
    call    lookup_call
    mv      s6, a0
    mv      a1, s4
    mv      a2, s5
    li      a3, 0
    addi    a4, sp, CALL_frame
    call    bind
    mv      a0, s6
    call    is_insn
    beqz    a0, 1f
    mv      a0, s6
    addi    a1, sp, CALL_frame
    call    encode
    mv      a2, s4
    call    emit
    j       2f
1:  mv      a0, s6
    call    param_count
    mv      a3, a0
    mv      a0, s6
    addi    a1, sp, CALL_frame
    la      a2, code_call
    call    run_body
2:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, CALL_stack
    ret

# exec_call: runs call a0 in exec context, in frame a1: an instruction is
# executed on vregs, any other function runs its body.
exec_call:
    addi    sp, sp, -CALL_stack
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # the call
    sd      s5, 16(sp)                  # caller's frame
    sd      s6, 24(sp)                  # the function
    mv      s4, a0
    mv      s5, a1
    call    lookup_call
    mv      s6, a0
    call    is_insn
    beqz    a0, 1f
    mv      a0, s6
    mv      a1, s4
    mv      a2, s5
    call    execute
    j       2f
1:  mv      a0, s6
    mv      a1, s4
    mv      a2, s5
    li      a3, 1
    addi    a4, sp, CALL_frame
    call    bind
    mv      a0, s6
    call    param_count
    mv      a3, a0
    mv      a0, s6
    addi    a1, sp, CALL_frame
    la      a2, exec_call
    call    run_body
2:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, CALL_stack
    ret

# execute: executes call a1 of instruction a0 in frame a2, on vregs: the
# parameter rd names the destination register, the other two give the
# values v0 and v1 in parameter order, and rd = v1 op v0. The seed: only
# addi, slli, srli and or.
execute:
    addi    sp, sp, -96
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # the call
    sd      s5, 16(sp)                  # frame
    sd      s6, 24(sp)                  # next parameter
    sd      s7, 32(sp)                  # next argument
    sd      s8, 40(sp)                  # parameters left
    sd      s9, 48(sp)                  # destination register
    sd      s10, 56(sp)                 # values so far
    # 64(sp), 72(sp): v0, v1
    mv      s4, a1
    mv      s5, a2
    mv      s6, a0
    call    param_count
    mv      s8, a0
    lbu     t0, NODE_children_len(s4)
    bne     t0, s8, 8f
    ld      s6, NODE_children(s6)
    ld      s7, NODE_children(s4)
    li      s9, 0
    li      s10, 0
1:  beqz    s8, 3f
    ld      t0, 0(s6)
    ld      a0, NODE_content(t0)
    lbu     a1, NODE_content_len(t0)
    la      a2, str_rd
    li      a3, 2
    call    streq
    ld      t0, 0(s7)
    ld      a1, NODE_content(t0)
    lbu     a2, NODE_content_len(t0)
    beqz    a0, 2f
    mv      a0, a1                      # rd: a register name
    mv      a1, a2
    call    find_reg
    bltz    a0, 7f
    mv      s9, a0
    j       6f
2:  li      t0, 2
    beq     s10, t0, 9f                 # more than two values: no seed op
    mv      a0, s5
    li      a3, 1
    call    eval_arg
    slli    t0, s10, 3
    add     t0, sp, t0
    sd      a0, 64(t0)
    addi    s10, s10, 1
6:  addi    s6, s6, 8
    addi    s7, s7, 8
    addi    s8, s8, -1
    j       1b
3:  ld      s6, NODE_content(s4)        # pick the op by name
    lbu     s7, NODE_content_len(s4)
    mv      a0, s6
    mv      a1, s7
    la      a2, str_addi
    li      a3, 4
    call    streq
    ld      t0, 64(sp)
    ld      t1, 72(sp)
    add     t2, t1, t0
    bnez    a0, 4f
    mv      a0, s6
    mv      a1, s7
    la      a2, str_slli
    li      a3, 4
    call    streq
    ld      t0, 64(sp)
    ld      t1, 72(sp)
    sll     t2, t1, t0
    bnez    a0, 4f
    mv      a0, s6
    mv      a1, s7
    la      a2, str_srli
    li      a3, 4
    call    streq
    ld      t0, 64(sp)
    ld      t1, 72(sp)
    srl     t2, t1, t0
    bnez    a0, 4f
    mv      a0, s6
    mv      a1, s7
    la      a2, str_or
    li      a3, 2
    call    streq
    ld      t0, 64(sp)
    ld      t1, 72(sp)
    or      t2, t1, t0
    beqz    a0, 9f
4:  li      t0, 2
    bne     s10, t0, 9f
    beqz    s9, 5f                      # x0 stays 0
    la      t0, vregs
    slli    t1, s9, 3
    add     t0, t0, t1
    sd      t2, 0(t0)
5:  ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    ld      s8, 40(sp)
    ld      s9, 48(sp)
    ld      s10, 56(sp)
    addi    sp, sp, 96
    ret
7:  la      a1, msg_register
    li      a2, msg_register_len
    ld      t0, 0(s7)
    ld      a3, NODE_content(t0)
    lbu     a4, NODE_content_len(t0)
    j       die_name
8:  la      a1, msg_args
    li      a2, msg_args_len
    j       1f
9:  la      a1, msg_execute
    li      a2, msg_execute_len
1:  ld      a3, NODE_content(s4)
    lbu     a4, NODE_content_len(s4)
    j       die_name

# ---------------------------------------------------------------------------
# Encoding and output
# ---------------------------------------------------------------------------

# encode: encodes instruction a0, its parameters bound in frame a1: a0 =
# the machine word, a1 = its width (16 or 32). The fields come MSB first:
# word = word << width | value.
encode:
    addi    sp, sp, -80
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # the instruction
    sd      s5, 16(sp)                  # frame
    sd      s6, 24(sp)                  # fields left
    sd      s7, 32(sp)                  # next field
    sd      s8, 40(sp)                  # word
    sd      s9, 48(sp)                  # width so far
    sd      s10, 56(sp)                 # width of this field
    mv      s4, a0
    mv      s5, a1
    call    param_count
    lbu     s6, NODE_children_len(s4)
    sub     s6, s6, a0
    ld      s7, NODE_children(s4)
    slli    a0, a0, 3
    add     s7, s7, a0
    li      s8, 0
    li      s9, 0
1:  beqz    s6, 4f
    ld      a0, 0(s7)
    call    is_fn
    ld      t0, 0(s7)
    beqz    a0, 2f
    lbu     t1, NODE_children_len(t0)   # a fixed field: its child is its bits
    beqz    t1, 8f
    ld      t1, NODE_children(t0)
    ld      t1, 0(t1)
    ld      a0, NODE_content(t1)
    lbu     a1, NODE_content_len(t1)
    mv      s10, a1
    call    parse_bits
    j       3f
2:  mv      a0, t0                      # a slice call: run it, value in a0
    mv      a1, s5
    call    exec_call
    ld      t0, 0(s7)
    ld      a0, NODE_content(t0)
    lbu     a1, NODE_content_len(t0)
    call    slice_width
    mv      s10, a0
    la      t0, vregs
    ld      a0, VREG_a0*8(t0)
3:  li      t0, 1
    sll     t0, t0, s10
    addi    t0, t0, -1
    and     a0, a0, t0
    sll     s8, s8, s10
    or      s8, s8, a0
    add     s9, s9, s10
    addi    s7, s7, 8
    addi    s6, s6, -1
    j       1b
4:  li      t0, 16
    beq     s9, t0, 5f
    li      t0, 32
    bne     s9, t0, 9f
5:  mv      a0, s8
    mv      a1, s9
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    ld      s7, 32(sp)
    ld      s8, 40(sp)
    ld      s9, 48(sp)
    ld      s10, 56(sp)
    addi    sp, sp, 80
    ret
8:  la      a1, msg_field
    li      a2, msg_field_len
    ld      a3, NODE_content(t0)
    lbu     a4, NODE_content_len(t0)
    j       die_name
9:  la      a1, msg_width
    li      a2, msg_width_len
    ld      a3, NODE_content(s4)
    lbu     a4, NODE_content_len(s4)
    j       die_name

# emit: appends the a1-bit word a0 to outbuf, little endian, and prints it
# as "<hex>  <name of call a2>".
emit:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # word
    sd      s5, 16(sp)                  # width
    sd      s6, 24(sp)                  # the call
    mv      s4, a0
    mv      s5, a1
    mv      s6, a2
    la      t6, out_end
    ld      t0, 0(t6)
    la      t1, outbuf
    li      t2, OUT_SIZE
    add     t1, t1, t2
    srli    t3, s5, 3                   # bytes
    add     t4, t0, t3
    bgtu    t4, t1, out_full
    mv      t5, s4
1:  beqz    t3, 2f
    sb      t5, 0(t0)
    srli    t5, t5, 8
    addi    t0, t0, 1
    addi    t3, t3, -1
    j       1b
2:  sd      t0, 0(t6)
    la      t0, linebuf
    la      t1, hexdigits
    srli    t2, s5, 2                   # hex digits
    addi    t3, s5, -4                  # shift of the next one
3:  beqz    t2, 4f
    srl     t4, s4, t3
    andi    t4, t4, 15
    add     t4, t1, t4
    lbu     t4, 0(t4)
    sb      t4, 0(t0)
    addi    t0, t0, 1
    addi    t3, t3, -4
    addi    t2, t2, -1
    j       3b
4:  li      t4, CH_space
    sb      t4, 0(t0)
    sb      t4, 1(t0)
    addi    t0, t0, 2
    la      a1, linebuf
    sub     a2, t0, a1
    call    write_out
    ld      a1, NODE_content(s6)
    lbu     a2, NODE_content_len(s6)
    call    write_out
    la      a1, newline
    li      a2, 1
    call    write_out
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    ld      s6, 24(sp)
    addi    sp, sp, 32
    ret

# write_elf: writes elf_header with its sizes filled in, then outbuf, to
# the file out_path.
write_elf:
    addi    sp, sp, -32
    sd      ra, 0(sp)
    sd      s4, 8(sp)                   # fd
    sd      s5, 16(sp)                  # code size
    la      t0, out_end
    ld      t0, 0(t0)
    la      t1, outbuf
    sub     s5, t0, t1
    addi    t0, s5, ELF_size
    la      t1, elf_filesz
    sd      t0, 0(t1)
    la      t1, elf_memsz
    sd      t0, 0(t1)
    li      a0, AT_FDCWD
    la      a1, out_path
    ld      a1, 0(a1)
    li      a2, O_CREAT_WRONLY_TRUNC
    li      a3, MODE_0755
    li      a7, SYS_openat
    ecall
    bltz    a0, create_failed
    mv      s4, a0
    la      a1, elf_header
    li      a2, ELF_size
    call    write_all
    mv      a0, s4
    la      a1, outbuf
    mv      a2, s5
    call    write_all
    mv      a0, s4
    li      a7, SYS_close
    ecall
    ld      ra, 0(sp)
    ld      s4, 8(sp)
    ld      s5, 16(sp)
    addi    sp, sp, 32
    ret

# write_all: writes the a2 bytes at a1 to fd a0, however many writes it
# takes.
write_all:
    mv      t0, a0
1:  beqz    a2, 2f
    mv      a0, t0
    li      a7, SYS_write
    ecall
    blez    a0, write_failed
    add     a1, a1, a0
    sub     a2, a2, a0
    j       1b
2:  ret

# write_out: writes a2 bytes at a1 to stdout.
write_out:
    li      a0, STDOUT
    li      a7, SYS_write
    ecall
    ret

usage:
    la      a1, msg_usage
    li      a2, msg_usage_len
    j       die
open_failed:
    la      a1, msg_open
    li      a2, msg_open_len
    j       die
read_failed:
    la      a1, msg_read
    li      a2, msg_read_len
    j       die
too_large:
    la      a1, msg_large
    li      a2, msg_large_len
    j       die
truncated:
    la      a1, msg_truncated
    li      a2, msg_truncated_len
    j       die
trailing:
    la      a1, msg_trailing
    li      a2, msg_trailing_len
    j       die
create_failed:
    la      a1, msg_create
    li      a2, msg_create_len
    j       die
write_failed:
    la      a1, msg_write
    li      a2, msg_write_len
    j       die
out_full:
    la      a1, msg_full
    li      a2, msg_full_len
    j       die

# die_name: writes the a2-byte message at a1 and the a4-byte name at a3 to
# stderr, then a newline, and exits with status 1.
die_name:
    mv      s4, a3
    mv      s5, a4
    li      a0, STDERR
    li      a7, SYS_write
    ecall
    li      a0, STDERR
    mv      a1, s4
    mv      a2, s5
    li      a7, SYS_write
    ecall
    la      a1, newline
    li      a2, 1

# die: writes the a2-byte message at a1 to stderr and exits with status 1.
die:
    li      a0, STDERR
    li      a7, SYS_write
    ecall
    li      a0, 1
exit:
    li      a7, SYS_exit
    ecall
