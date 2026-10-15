# hosts/x86_64/ttpc.s — ttpc.s, the trust project compiler, ported to
# x86_64 assembly, without libc.
#
# FROZEN: this is stage0 of the bootstrap on an x86_64 host (see PLAN.md),
# a port of ttpc.s (riscv64), function by function: the same labels in the
# same order, the same comments, constants, messages, tables and memory
# layout. It must agree with ttpc.s byte for byte: for every input the same
# stdout, stderr, output file and exit status. ttpc.s is fully interpretive
# (the ISA it assembles for comes from the tree, exec context runs on vregs
# through exec_ops), so the port is a pure translation. Read it side by side
# with ttpc.s.
#
# ONE deliberate difference: OUT_SIZE is 1 << 20 (1 MiB) instead of
# 1 << 16, so that it can write the larger x86_64 ttpc (~95 KB). For an
# output that fits in 64 KiB nothing differs; a bigger one, where ttpc.s
# says "ttpc: output too large", is assembled here.
#
# A static Linux x86_64 program. It talks to the kernel only through
# syscall: it opens the ff file named by its first argument and loads it
# into memory as a tree of NODEs.
#
#   ttpc <file.ff>          prints the tree, one node per line
#   ttpc <file.ff> <out>    assembles it into the static executable <out>
#
# Assembling: a node whose content ends in ':' is a function, its leading
# children that are leaves are its parameters. Any other node is a call, its
# children are the arguments. The root's children are pages. The functions
# on every page but the last are definitions: instructions, macros,
# constants. The last page is the program: its functions are placed, they
# are labels whose children are emitted where they stand (nested ones are
# local labels, found innermost scope first), and its calls are emitted in
# order. Pass 1 finds every label's address, pass 2 emits.
#
# A function whose body (the children after its parameters) holds only
# fields, fixed fields (funct3:, ...) and slice calls (imm[11:0] imm), is an
# encoding: an instruction or a data word of 8 to 64 bits. A call runs in
# one of three contexts:
#
#   code   a call of an encoding is encoded and emitted, a call of any
#          other function expands its body in code context.
#   field  encoding: the fields, MSB first. A fixed field is its bits; a
#          slice call runs in exec context and leaves its value in a0, its
#          width is in its name.
#   exec   runs at assemble time on vregs. The ops of exec_ops are built
#          in, the seed; everything else is defined by the tree.
#
# An argument with children is a call, run in exec context: its value is
# a0. A leaf argument is a decimal or 0x number, a parameter, a register
# (its number in code context, its vreg in exec context), pc, a label (its
# address) or a constant (a function without parameters, run in exec
# context). The builtins: ascii, align, reserve, origin, bss (see
# code_call) and size (see exec_call).
#
# Registers are the functions "x10 a0:", their number is their child "01010".
# The output file is exactly what the program emits: its ELF header is ff
# too (elf_header in macros.ff.txt).
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
#
# The register map. The comments speak of ttpc.s's registers (a0, s4, t0,
# ...); each one is, here:
#
#   s0  %r12    parse cursor in buf             live across the whole
#   s1  %r13    end of the loaded bytes         program, as in ttpc.s
#   s2  %r14    next free NODE in nodes
#   s3  %r15    next free slot in ptrs
#   s4  %rbx    callee-saved: a function that uses it saves it at 8(%rsp)
#   s5  %rbp    callee-saved: saved at 16(%rsp)
#   s6..s11     no register: the frame slot where ttpc.s saves them, s6
#               24(%rsp), s7 32, s8 40, s9 48, s10 56, s11 64. Every
#               function has its own slots, so they need no saving.
#   a0..a4  %rdi %rsi %rdx %rcx %r8     arguments; results in a0 (%rdi) and
#               a1 (%rsi). This is ttpc's own convention, NOT System V.
#   t0 t1 t2    %rax %r10 %r11          scratch
#   t3 t4 t5 t6 %rcx %r8 %r9 %rdx       scratch, only where a3 a4 a2 are dead
#   ra          the return address that call pushes. A frame is
#               "sub $N, %rsp" with ttpc.s's N and offsets, ra's slot
#               0(%rsp) left unused.
#   a7          %rax, the syscall number. syscall takes a0 a1 a2 a3 in %rdi
#               %rsi %rdx %r10, returns in %rax (not a0) and clobbers %rcx
#               and %r11.
#
# Branches: blt/bge/bgt/ble are jl/jge/jg/jle, bltu/bgeu/bgtu are jb/jae/ja;
# lbu is movzbq.

    .code64

    .equ SYS_openat, 257
    .equ SYS_close, 3
    .equ SYS_read, 0
    .equ SYS_write, 1
    .equ SYS_exit, 60

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
    .equ CH_a, 97
    .equ CH_x, 120

    # A frame binds the parameters of a call: count, then (param NODE*,
    # value) pairs.
    .equ MAX_PARAMS, 8
    .equ FRAME_count, 0
    .equ FRAME_params, 8
    .equ FRAME_size, 8 + MAX_PARAMS * 16

    .equ VREG_a0, 10
    .equ OUT_SIZE, 1 << 20              # ttpc.s: 1 << 16 (see the header)
    .equ MAX_DEPTH, 64                  # nesting of placed functions

    # A label: a placed function, its address and the address after it.
    .equ LABEL_node, 0
    .equ LABEL_addr, 8
    .equ LABEL_end, 16
    .equ LABEL_size, 24

    # An exec op: its name, NUL-padded, and its code.
    .equ OP_name, 0
    .equ OP_code, 8
    .equ OP_size, 16

    .equ NODE_hash, 0
    .equ NODE_children_len, 32
    .equ NODE_children, 40
    .equ NODE_content_len, 48
    .equ NODE_content, 56
    .equ NODE_size, 64

    .equ BUF_SIZE, 1 << 20
    # Every node takes at least 34 bytes on disk, so a full buf holds fewer
    # than MAX_NODES nodes: the node and pointer arenas cannot overflow.
    # MAX_NODES is BUF_SIZE / 32: '/' starts a comment in x86_64-elf gas.
    .equ MAX_NODES, BUF_SIZE >> 5

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
msg_width:      .ascii "ttpc: width is not 8, 16, 32 or 64 bits: "
    .equ msg_width_len, . - msg_width
msg_moved:      .ascii "ttpc: label moved between the passes: "
    .equ msg_moved_len, . - msg_moved
msg_depth:      .ascii "ttpc: nested too deep: "
    .equ msg_depth_len, . - msg_depth
msg_bss:        .ascii "ttpc: emitted after bss\n"
    .equ msg_bss_len, . - msg_bss
hexdigits:      .ascii "0123456789abcdef"
indent:         .ascii "  "
newline:        .ascii "\n"
str_rd:         .ascii "rd"
str_pc:         .ascii "pc"
str_size:       .ascii "size"
str_ascii:      .ascii "ascii"
str_align:      .ascii "align"
str_reserve:    .ascii "reserve"
str_origin:     .ascii "origin"
str_bss:        .ascii "bss"
zero_byte:      .byte 0

    .section .data
hexbuf:         .ascii "00000000  "         # hash prefix of a printed line
    .balign 8
out_path:       .quad 0                     # argv[2], 0 when only printing
out_end:        .quad outbuf                # next free byte in outbuf
syms_end:       .quad syms                  # next free slot in syms
labels_end:     .quad labels                # next free LABEL (pass 1)
label_next:     .quad labels                # next LABEL to check (pass 2)
pass:           .quad 0                     # 1 or 2
cur_pc:         .quad 0                     # address of the next byte
in_bss:         .quad 0                     # 1 after the builtin bss
scope_depth:    .quad 0                     # placed functions in scopes

# The exec seed: the instructions that exec context runs itself, rd = v1 op
# v0, with v0 and v1 the other operands in parameter order (rs2 rs1, or imm
# rs1, or shamt rs1).
exec_ops:
    .ascii "add\0\0\0\0\0"
    .quad op_add
    .ascii "addi\0\0\0\0"
    .quad op_add
    .ascii "sub\0\0\0\0\0"
    .quad op_sub
    .ascii "and\0\0\0\0\0"
    .quad op_and
    .ascii "andi\0\0\0\0"
    .quad op_and
    .ascii "or\0\0\0\0\0\0"
    .quad op_or
    .ascii "ori\0\0\0\0\0"
    .quad op_or
    .ascii "xor\0\0\0\0\0"
    .quad op_xor
    .ascii "xori\0\0\0\0"
    .quad op_xor
    .ascii "sll\0\0\0\0\0"
    .quad op_sll
    .ascii "slli\0\0\0\0"
    .quad op_sll
    .ascii "srl\0\0\0\0\0"
    .quad op_srl
    .ascii "srli\0\0\0\0"
    .quad op_srl
    .ascii "sra\0\0\0\0\0"
    .quad op_sra
    .ascii "srai\0\0\0\0"
    .quad op_sra
    .ascii "mul\0\0\0\0\0"
    .quad op_mul
exec_ops_end:

    .section .bss
    .balign 8
nodes:          .skip MAX_NODES * NODE_size
ptrs:           .skip MAX_NODES * 8
syms:           .skip MAX_NODES * 8         # the function NODEs, see collect_syms
labels:         .skip MAX_NODES * LABEL_size
scopes:         .skip MAX_DEPTH * 8         # the placed functions around pc
vregs:          .skip 32 * 8                # the registers of exec context
linebuf:        .skip 24                    # hex of an emitted word
outbuf:         .skip OUT_SIZE
buf:            .skip BUF_SIZE

# Registers that live across the whole program:
#   s0  %r12  parse cursor in buf
#   s1  %r13  end of the loaded bytes
#   s2  %r14  next free NODE in nodes
#   s3  %r15  next free slot in ptrs

    .section .text
    .globl _start
_start:
    mov     0(%rsp), %rax               # argc
    cmp     $2, %rax
    jl      usage
    cmp     $3, %rax
    jg      usage
    jl      1f
    mov     24(%rsp), %r10              # argv[2]
    mov     %r10, out_path(%rip)
1:  mov     16(%rsp), %rsi              # argv[1]

    mov     $AT_FDCWD, %rdi
    mov     $O_RDONLY, %edx
    mov     $0, %r10d                   # a3
    mov     $SYS_openat, %eax
    syscall
    test    %rax, %rax
    js      open_failed
    mov     %rax, %rbx                  # fd (s4)

    # Read the whole file into buf.
    lea     buf(%rip), %r12
    mov     %r12, %r13
    mov     $BUF_SIZE, %eax
    lea     (%r12,%rax), %rbp           # end of buf (s5)
read_loop:
    cmp     %rbp, %r13
    je      too_large
    mov     %rbx, %rdi
    mov     %r13, %rsi
    mov     %rbp, %rdx
    sub     %r13, %rdx
    mov     $SYS_read, %eax
    syscall
    test    %rax, %rax
    js      read_failed
    jz      read_done
    add     %rax, %r13
    jmp     read_loop
read_done:
    mov     %rbx, %rdi
    mov     $SYS_close, %eax
    syscall

    lea     nodes(%rip), %r14
    lea     ptrs(%rip), %r15
    call    parse_node
    cmp     %r13, %r12
    jne     trailing
    mov     out_path(%rip), %rax
    test    %rax, %rax
    jnz     assemble
    mov     $0, %esi
    call    print_node

    mov     $0, %edi
    jmp     exit

# assemble: places the last page of root a0, the program, twice: pass 1
# finds the address of every label, pass 2 emits with them. Then writes
# the output file.
assemble:
    sub     $48, %rsp                   # slots for s6 s7 s8; it never returns
    mov     %rdi, 24(%rsp)              # root (s6)
    call    collect_syms
    mov     24(%rsp), %r11
    movzbq  NODE_children_len(%r11), %rax
    test    %rax, %rax
    jz      2f
    mov     NODE_children(%r11), %r10
    shl     $3, %rax
    add     %rax, %r10
    mov     -8(%r10), %rax
    mov     %rax, 32(%rsp)              # the program page (s7)
    movq    $1, 40(%rsp)                # pass (s8)
1:  mov     40(%rsp), %rax
    mov     %rax, pass(%rip)
    movq    $0, cur_pc(%rip)
    movq    $0, in_bss(%rip)
    lea     outbuf(%rip), %r10
    mov     %r10, out_end(%rip)
    lea     labels(%rip), %r10
    mov     %r10, label_next(%rip)
    mov     32(%rsp), %rax              # the page is the outermost scope
    mov     %rax, scopes(%rip)
    movq    $1, scope_depth(%rip)
    mov     32(%rsp), %rdi
    call    run_placed
    incq    40(%rsp)
    cmpq    $3, 40(%rsp)
    jne     1b
2:  call    write_output
    mov     $0, %edi
    jmp     exit

# The errors of loading, where ttpc.s has them (within branch reach of
# _start and parse_node there).
usage:
    lea     msg_usage(%rip), %rsi
    mov     $msg_usage_len, %edx
    jmp     die
open_failed:
    lea     msg_open(%rip), %rsi
    mov     $msg_open_len, %edx
    jmp     die
read_failed:
    lea     msg_read(%rip), %rsi
    mov     $msg_read_len, %edx
    jmp     die
too_large:
    lea     msg_large(%rip), %rsi
    mov     $msg_large_len, %edx
    jmp     die
truncated:
    lea     msg_truncated(%rip), %rsi
    mov     $msg_truncated_len, %edx
    jmp     die
trailing:
    lea     msg_trailing(%rip), %rsi
    mov     $msg_trailing_len, %edx
    jmp     die

# parse_node: reads the node at s0 into a new NODE, recursing on its
# children, and leaves s0 just past it. Returns the NODE in a0.
parse_node:
    sub     $32, %rsp
    mov     %rbx, 8(%rsp)               # this NODE (s4)
    mov     %rbp, 16(%rsp)              # next slot in its children array (s5)
                                        # 24(%rsp): children left to parse (s6)

    lea     33(%r12), %rax              # hash + children_len
    cmp     %r13, %rax
    ja      truncated
    mov     %r14, %rbx
    add     $NODE_size, %r14

    mov     $32, %r10d                  # copy the hash
    mov     %rbx, %r11
1:  movzbq  0(%r12), %rcx
    mov     %cl, NODE_hash(%r11)
    inc     %r12
    inc     %r11
    dec     %r10
    jnz     1b

    movzbq  0(%r12), %rax
    mov     %rax, 24(%rsp)
    inc     %r12
    mov     %al, NODE_children_len(%rbx)
    mov     %r15, %rbp
    mov     %rbp, NODE_children(%rbx)
    shl     $3, %rax
    add     %rax, %r15
2:  cmpq    $0, 24(%rsp)
    je      3f
    call    parse_node
    mov     %rdi, 0(%rbp)
    add     $8, %rbp
    decq    24(%rsp)
    jmp     2b

3:  cmp     %r13, %r12
    jae     truncated
    movzbq  0(%r12), %rax
    inc     %r12
    mov     %al, NODE_content_len(%rbx)
    mov     %r12, NODE_content(%rbx)
    add     %rax, %r12
    cmp     %r13, %r12
    ja      truncated

    mov     %rbx, %rdi
    mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $32, %rsp
    ret

# print_node: prints NODE a0 at depth a1 as "<hash[0..4] in hex>  <indent>
# <content>", then its children one level deeper.
print_node:
    sub     $48, %rsp
    mov     %rbx, 8(%rsp)               # this NODE (s4)
    mov     %rbp, 16(%rsp)              # depth (s5)
                                        # 24(%rsp): counter (s6)
                                        # 32(%rsp): next child pointer (s7)
    mov     %rdi, %rbx
    mov     %rsi, %rbp

    lea     hexbuf(%rip), %rax
    lea     hexdigits(%rip), %r10
    mov     $4, %r11d
    mov     %rbx, %rcx
1:  movzbq  NODE_hash(%rcx), %r8
    mov     %r8, %r9
    shr     $4, %r9
    add     %r10, %r9
    movzbq  0(%r9), %r9
    mov     %r9b, 0(%rax)
    and     $15, %r8
    add     %r10, %r8
    movzbq  0(%r8), %r8
    mov     %r8b, 1(%rax)
    add     $2, %rax
    inc     %rcx
    dec     %r11
    jnz     1b
    lea     hexbuf(%rip), %rsi
    mov     $10, %edx
    call    write_out

    mov     %rbp, 24(%rsp)
2:  cmpq    $0, 24(%rsp)
    je      3f
    lea     indent(%rip), %rsi
    mov     $2, %edx
    call    write_out
    decq    24(%rsp)
    jmp     2b

3:  mov     NODE_content(%rbx), %rsi
    movzbq  NODE_content_len(%rbx), %rdx
    call    write_out
    lea     newline(%rip), %rsi
    mov     $1, %edx
    call    write_out

    movzbq  NODE_children_len(%rbx), %rax
    mov     %rax, 24(%rsp)
    mov     NODE_children(%rbx), %rax
    mov     %rax, 32(%rsp)
4:  cmpq    $0, 24(%rsp)
    je      5f
    mov     32(%rsp), %rax
    mov     0(%rax), %rdi
    lea     1(%rbp), %rsi
    call    print_node
    addq    $8, 32(%rsp)
    decq    24(%rsp)
    jmp     4b

5:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $48, %rsp
    ret

# ---------------------------------------------------------------------------
# Names
# ---------------------------------------------------------------------------

# streq: a0 = 1 when the a1 bytes at a0 equal the a3 bytes at a2, else 0.
streq:
    cmp     %rcx, %rsi
    jne     2f
1:  test    %rsi, %rsi
    jz      3f
    movzbq  0(%rdi), %rax
    movzbq  0(%rdx), %r10
    cmp     %r10, %rax
    jne     2f
    inc     %rdi
    inc     %rdx
    dec     %rsi
    jmp     1b
2:  mov     $0, %edi
    ret
3:  mov     $1, %edi
    ret

# is_fn: a0 = 1 when NODE a0 is a function (its content ends in ':'), else 0.
is_fn:
    movzbq  NODE_content_len(%rdi), %rax
    test    %rax, %rax
    jz      1f
    mov     NODE_content(%rdi), %r10
    add     %rax, %r10
    movzbq  -1(%r10), %r10
    xor     %edi, %edi
    cmp     $CH_colon, %r10
    sete    %dil
    ret
1:  mov     $0, %edi
    ret

# param_count: a0 = the number of parameters of function NODE a0: its
# leading children that are leaves and no function.
param_count:
    sub     $32, %rsp
    mov     %rbx, 8(%rsp)               # children left (s4)
    mov     %rbp, 16(%rsp)              # next child (s5)
                                        # 24(%rsp): count (s6)
    movzbq  NODE_children_len(%rdi), %rbx
    mov     NODE_children(%rdi), %rbp
    movq    $0, 24(%rsp)
1:  test    %rbx, %rbx
    jz      2f
    mov     0(%rbp), %rdi
    movzbq  NODE_children_len(%rdi), %rax
    test    %rax, %rax
    jnz     2f
    call    is_fn
    test    %rdi, %rdi
    jnz     2f
    incq    24(%rsp)
    add     $8, %rbp
    dec     %rbx
    jmp     1b
2:  mov     24(%rsp), %rdi
    mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $32, %rsp
    ret

# is_insn: a0 = 1 when function NODE a0 is an encoding (an instruction or
# a data word), else 0: its body, the children after its parameters, is not
# empty and holds only fields, fixed fields (functions) and slice calls (a
# '[' in the name).
is_insn:
    sub     $32, %rsp
    mov     %rbx, 8(%rsp)               # fields left (s4)
    mov     %rbp, 16(%rsp)              # next field (s5)
                                        # 24(%rsp): the function (s6)
    mov     %rdi, 24(%rsp)
    call    param_count
    mov     24(%rsp), %rax
    movzbq  NODE_children_len(%rax), %rbx
    sub     %rdi, %rbx
    mov     NODE_children(%rax), %rbp
    shl     $3, %rdi
    add     %rdi, %rbp
    mov     $0, %edi
    test    %rbx, %rbx
    jz      3f
1:  mov     $1, %edi
    test    %rbx, %rbx
    jz      3f
    mov     0(%rbp), %rdi
    call    is_fn
    test    %rdi, %rdi
    jnz     2f
    mov     0(%rbp), %rax
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    mov     $CH_lbracket, %edx
    call    has_byte
    test    %rdi, %rdi
    jz      3f
2:  add     $8, %rbp
    dec     %rbx
    jmp     1b
3:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $32, %rsp
    ret

# has_byte: a0 = 1 when byte a2 is among the a1 bytes at a0, else 0.
has_byte:
1:  test    %rsi, %rsi
    jz      2f
    movzbq  0(%rdi), %rax
    cmp     %rdx, %rax
    je      3f
    inc     %rdi
    dec     %rsi
    jmp     1b
2:  mov     $0, %edi
    ret
3:  mov     $1, %edi
    ret

# collect_syms: stores every function among the children of the pages of
# root a0 in syms, but for the last page: the program, it is placed.
collect_syms:
    sub     $64, %rsp
    mov     %rbx, 8(%rsp)               # pages left (s4)
    mov     %rbp, 16(%rsp)              # next page (s5)
                                        # 24(%rsp): next free slot in syms (s6)
                                        # 32(%rsp): children of the page left (s7)
                                        # 40(%rsp): next child (s8)
    movzbq  NODE_children_len(%rdi), %rbx
    mov     NODE_children(%rdi), %rbp
    lea     syms(%rip), %rax
    mov     %rax, 24(%rsp)
    test    %rbx, %rbx
    jz      4f
    dec     %rbx                        # not the last page: it is placed
1:  test    %rbx, %rbx
    jz      4f
    mov     0(%rbp), %rax
    movzbq  NODE_children_len(%rax), %r10
    mov     %r10, 32(%rsp)
    mov     NODE_children(%rax), %r10
    mov     %r10, 40(%rsp)
2:  cmpq    $0, 32(%rsp)
    je      3f
    mov     40(%rsp), %rax
    mov     0(%rax), %rdi
    call    is_fn
    test    %rdi, %rdi
    jz      5f
    mov     40(%rsp), %rax
    mov     0(%rax), %rax
    mov     24(%rsp), %r10
    mov     %rax, 0(%r10)
    addq    $8, 24(%rsp)
5:  addq    $8, 40(%rsp)
    decq    32(%rsp)
    jmp     2b
3:  add     $8, %rbp
    dec     %rbx
    jmp     1b
4:  mov     24(%rsp), %rax
    mov     %rax, syms_end(%rip)
    mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $64, %rsp
    ret

# find_fn: a0 = the function named by the a1 bytes at a0 (its content
# without the ':'), or 0.
find_fn:
    sub     $48, %rsp
    mov     %rbx, 8(%rsp)               # next sym (s4)
    mov     %rbp, 16(%rsp)              # end of syms (s5)
                                        # 24(%rsp): name (s6)
                                        # 32(%rsp): name length (s7)
    mov     %rdi, 24(%rsp)
    mov     %rsi, 32(%rsp)
    lea     syms(%rip), %rbx
    mov     syms_end(%rip), %rbp
1:  mov     $0, %edi
    cmp     %rbp, %rbx
    je      2f
    mov     0(%rbx), %rax
    mov     NODE_content(%rax), %rdx
    movzbq  NODE_content_len(%rax), %rcx
    dec     %rcx
    mov     24(%rsp), %rdi
    mov     32(%rsp), %rsi
    call    streq
    add     $8, %rbx
    test    %rdi, %rdi
    jz      1b
    mov     -8(%rbx), %rdi
2:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $48, %rsp
    ret

# find_reg: a0 = the number of the register named by the a1 bytes at a0, or
# -1. A register is a function of two words, "x10 a0:", either one is its
# name; its number is the bits of its child.
find_reg:
    sub     $80, %rsp
    mov     %rbx, 8(%rsp)               # next sym (s4)
    mov     %rbp, 16(%rsp)              # end of syms (s5)
                                        # 24(%rsp): name (s6)
                                        # 32(%rsp): name length (s7)
                                        # 40(%rsp): the sym (s8)
                                        # 48(%rsp): its content (s9)
                                        # 56(%rsp): its length without the ':' (s10)
                                        # 64(%rsp): length of its first word (s11)
    mov     %rdi, 24(%rsp)
    mov     %rsi, 32(%rsp)
    lea     syms(%rip), %rbx
    mov     syms_end(%rip), %rbp
1:  cmp     %rbp, %rbx
    je      5f
    mov     0(%rbx), %r11
    mov     %r11, 40(%rsp)
    add     $8, %rbx
    movzbq  NODE_children_len(%r11), %rax
    test    %rax, %rax
    jz      1b
    mov     NODE_content(%r11), %rax
    mov     %rax, 48(%rsp)
    movzbq  NODE_content_len(%r11), %rax
    dec     %rax
    mov     %rax, 56(%rsp)
    movq    $0, 64(%rsp)                # find the space
2:  mov     64(%rsp), %rax
    cmp     56(%rsp), %rax
    je      1b
    add     48(%rsp), %rax
    movzbq  0(%rax), %rax
    cmp     $CH_space, %rax
    je      3f
    incq    64(%rsp)
    jmp     2b
3:  mov     24(%rsp), %rdi
    mov     32(%rsp), %rsi
    mov     48(%rsp), %rdx
    mov     64(%rsp), %rcx
    call    streq
    test    %rdi, %rdi
    jnz     4f
    mov     24(%rsp), %rdi
    mov     32(%rsp), %rsi
    mov     48(%rsp), %rdx
    add     64(%rsp), %rdx
    inc     %rdx
    mov     56(%rsp), %rcx
    sub     64(%rsp), %rcx
    dec     %rcx
    call    streq
    test    %rdi, %rdi
    jz      1b
4:  mov     40(%rsp), %rax
    mov     NODE_children(%rax), %rax
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    call    parse_bits
    jmp     6f
5:  mov     $-1, %rdi
6:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $80, %rsp
    ret

# ---------------------------------------------------------------------------
# Numbers
# ---------------------------------------------------------------------------

# parse_bits: a0 = the a1 binary digits at a0 ("0010011") as a number.
parse_bits:
    mov     $0, %eax
1:  test    %rsi, %rsi
    jz      2f
    movzbq  0(%rdi), %r10
    sub     $CH_zero, %r10
    shl     $1, %rax
    or      %r10, %rax
    inc     %rdi
    dec     %rsi
    jmp     1b
2:  mov     %rax, %rdi
    ret

# parse_dec: reads the decimal digits from a0 up to at most a1; a0 = their
# value, a1 = just past them.
parse_dec:
    mov     $0, %eax
    mov     $10, %r11d
1:  cmp     %rsi, %rdi
    je      2f
    movzbq  0(%rdi), %r10
    sub     $CH_zero, %r10
    cmp     %r11, %r10
    jae     2f
    imul    %r11, %rax
    add     %r10, %rax
    inc     %rdi
    jmp     1b
2:  mov     %rdi, %rsi
    mov     %rax, %rdi
    ret

# parse_hex: reads the hex digits (0-9, a-f) from a0 up to at most a1;
# a0 = their value, a1 = just past them.
parse_hex:
    mov     $0, %eax
1:  cmp     %rsi, %rdi
    je      3f
    movzbq  0(%rdi), %r10
    lea     -CH_zero(%r10), %r11
    mov     $10, %ecx
    cmp     %rcx, %r11
    jb      2f
    lea     -CH_a(%r10), %r11
    mov     $6, %ecx
    cmp     %rcx, %r11
    jae     3f
    add     $10, %r11
2:  shl     $4, %rax
    or      %r11, %rax
    inc     %rdi
    jmp     1b
3:  mov     %rdi, %rsi
    mov     %rax, %rdi
    ret

# parse_num: a0 = the a1 bytes at a0 as a number, decimal or 0x hex, with
# an optional '-', and a1 = 1; or a1 = 0 when they are no number.
parse_num:
    sub     $32, %rsp
    mov     %rbx, 8(%rsp)               # negative? (s4)
    mov     %rbp, 16(%rsp)              # first digit (s5)
                                        # 24(%rsp): end (s6)
    add     %rdi, %rsi
    mov     %rsi, 24(%rsp)
    mov     $0, %ebx
    cmp     %rsi, %rdi
    je      2f
    movzbq  0(%rdi), %rax
    cmp     $CH_minus, %rax
    jne     1f
    mov     $1, %ebx
    inc     %rdi
1:  mov     %rdi, %rbp
    mov     %rsi, %rax
    sub     %rdi, %rax                  # 0x and a digit at least?
    cmp     $3, %rax
    jl      5f
    movzbq  0(%rdi), %rax
    cmp     $CH_zero, %rax
    jne     5f
    movzbq  1(%rdi), %rax
    cmp     $CH_x, %rax
    jne     5f
    add     $2, %rdi
    add     $2, %rbp
    call    parse_hex
    jmp     6f
5:  call    parse_dec
6:  cmp     %rbp, %rsi
    je      2f                          # no digits
    cmp     24(%rsp), %rsi
    jne     2f                          # something after them
    test    %rbx, %rbx
    jz      3f
    neg     %rdi
3:  mov     $1, %esi
    jmp     4f
2:  mov     $0, %esi
4:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $32, %rsp
    ret

# slice_width: a0 = the width of the slice named by the a1 bytes at a0: the
# sum of hi-lo+1 over the segments of "imm[20|10:1|11|19:12]".
slice_width:
    sub     $64, %rsp
    mov     %rbx, 8(%rsp)               # cursor (s4)
    mov     %rbp, 16(%rsp)              # end (s5)
                                        # 24(%rsp): name (s6)
                                        # 32(%rsp): name length (s7)
                                        # 40(%rsp): width (s8)
    mov     %rdi, 24(%rsp)
    mov     %rsi, 32(%rsp)
    mov     %rdi, %rbx
    lea     (%rdi,%rsi), %rbp
    movq    $0, 40(%rsp)
1:  cmp     %rbp, %rbx
    je      9f                          # skip to just past the '['
    movzbq  0(%rbx), %rax
    inc     %rbx
    cmp     $CH_lbracket, %rax
    jne     1b
2:  mov     %rbx, %rdi                  # a segment: hi or hi:lo
    mov     %rbp, %rsi
    call    parse_dec
    cmp     %rbx, %rsi
    je      9f
    mov     %rsi, %rbx
    incq    40(%rsp)
    cmp     %rbp, %rbx
    je      9f
    movzbq  0(%rbx), %rax
    cmp     $CH_colon, %rax
    jne     3f
    mov     %rdi, 48(%rsp)              # hi
    inc     %rbx
    mov     %rbx, %rdi
    mov     %rbp, %rsi
    call    parse_dec
    cmp     %rbx, %rsi
    je      9f
    mov     %rsi, %rbx
    mov     48(%rsp), %rax
    sub     %rdi, %rax
    add     %rax, 40(%rsp)
    cmp     %rbp, %rbx
    je      9f
    movzbq  0(%rbx), %rax
3:  inc     %rbx
    cmp     $CH_bar, %rax
    je      2b
    cmp     $CH_rbracket, %rax
    jne     9f
    cmp     %rbp, %rbx
    jne     9f
    mov     40(%rsp), %rdi
    mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $64, %rsp
    ret
9:  lea     msg_slice(%rip), %rsi
    mov     $msg_slice_len, %edx
    mov     24(%rsp), %rcx
    mov     32(%rsp), %r8
    jmp     die_name

# ---------------------------------------------------------------------------
# Calls
# ---------------------------------------------------------------------------

# frame_lookup: looks up the parameter named by the a2 bytes at a1 in frame
# a0 (0: none). a0 = 1 and a1 = its value when found, else a0 = 0.
frame_lookup:
    sub     $48, %rsp
    mov     %rbx, 8(%rsp)               # pairs left (s4)
    mov     %rbp, 16(%rsp)              # next pair (s5)
                                        # 24(%rsp): name (s6)
                                        # 32(%rsp): name length (s7)
    test    %rdi, %rdi
    jz      2f
    mov     %rsi, 24(%rsp)
    mov     %rdx, 32(%rsp)
    mov     FRAME_count(%rdi), %rbx
    lea     FRAME_params(%rdi), %rbp
1:  test    %rbx, %rbx
    jz      2f
    mov     0(%rbp), %rax
    mov     NODE_content(%rax), %rdx
    movzbq  NODE_content_len(%rax), %rcx
    mov     24(%rsp), %rdi
    mov     32(%rsp), %rsi
    call    streq
    test    %rdi, %rdi
    jnz     3f
    add     $16, %rbp
    dec     %rbx
    jmp     1b
2:  mov     $0, %edi
    jmp     4f
3:  mov     8(%rbp), %rsi
4:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $48, %rsp
    ret

# eval_arg: a0 = the value of argument NODE a1 in frame a0, in context a2
# (0 code, 1 exec). An argument with children is a call that runs in exec
# context, its value is what it leaves in a0. A leaf is, in this order: a
# decimal or 0x number, a parameter, a register (its number in code
# context, its vreg in exec context), pc (the address being assembled), a
# label (its address) or a constant (a function without parameters, run in
# exec context).
eval_arg:
    sub     $64, %rsp
    mov     %rbx, 8(%rsp)               # frame (s4)
    mov     %rbp, 16(%rsp)              # the argument (s5)
                                        # 24(%rsp): context (s6)
                                        # 32(%rsp): its name (s7)
                                        # 40(%rsp): name length (s8)
                                        # 48(%rsp): a function of that name (s9)
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    mov     %rdx, 24(%rsp)
    movzbq  NODE_children_len(%rbp), %rax
    test    %rax, %rax
    jz      1f
    mov     %rbp, %rdi                  # a call
    mov     %rbx, %rsi
    call    exec_call
    jmp     7f
1:  mov     NODE_content(%rbp), %rax
    mov     %rax, 32(%rsp)
    movzbq  NODE_content_len(%rbp), %rax
    mov     %rax, 40(%rsp)
    mov     32(%rsp), %rdi
    mov     40(%rsp), %rsi
    call    parse_num
    test    %rsi, %rsi
    jnz     9f
    mov     %rbx, %rdi
    mov     32(%rsp), %rsi
    mov     40(%rsp), %rdx
    call    frame_lookup
    test    %rdi, %rdi
    jz      2f
    mov     %rsi, %rdi
    jmp     9f
2:  mov     32(%rsp), %rdi
    mov     40(%rsp), %rsi
    call    find_reg
    test    %rdi, %rdi
    js      3f
    cmpq    $0, 24(%rsp)
    je      9f
    lea     vregs(%rip), %rax
    shl     $3, %rdi
    add     %rdi, %rax
    mov     0(%rax), %rdi
    jmp     9f
3:  mov     32(%rsp), %rdi
    mov     40(%rsp), %rsi
    lea     str_pc(%rip), %rdx
    mov     $2, %ecx
    call    streq
    test    %rdi, %rdi
    jz      4f
    mov     cur_pc(%rip), %rdi
    jmp     9f
4:  mov     32(%rsp), %rdi
    mov     40(%rsp), %rsi
    call    find_label
    test    %rdi, %rdi
    jz      5f
    call    label_addr
    jmp     9f
5:  mov     32(%rsp), %rdi
    mov     40(%rsp), %rsi
    call    find_fn
    test    %rdi, %rdi
    jz      8f
    mov     %rdi, 48(%rsp)
    call    is_insn
    test    %rdi, %rdi
    jnz     8f
    mov     48(%rsp), %rdi
    call    param_count
    test    %rdi, %rdi
    jnz     8f
    mov     %rbp, %rdi                  # a constant
    mov     %rbx, %rsi
    call    exec_call
7:  mov     vregs+VREG_a0*8(%rip), %rdi
9:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $64, %rsp
    ret
8:  lea     msg_name(%rip), %rsi
    mov     $msg_name_len, %edx
    mov     32(%rsp), %rcx
    mov     40(%rsp), %r8
    jmp     die_name

# bind: fills frame a4 for call a1 of function a0: each parameter with the
# value of its argument, evaluated in frame a2 and context a3.
bind:
    sub     $64, %rsp
    mov     %rbx, 8(%rsp)               # next parameter (s4)
    mov     %rbp, 16(%rsp)              # next argument (s5)
                                        # 24(%rsp): caller's frame (s6)
                                        # 32(%rsp): context (s7)
                                        # 40(%rsp): next pair in the new frame (s8)
                                        # 48(%rsp): parameters left (s9)
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    mov     %rdx, 24(%rsp)
    mov     %rcx, 32(%rsp)
    mov     %r8, 40(%rsp)
    call    param_count
    mov     %rdi, 48(%rsp)
    movzbq  NODE_children_len(%rbp), %rax
    lea     msg_args(%rip), %rsi
    mov     $msg_args_len, %edx
    cmp     48(%rsp), %rax
    jne     3f
    lea     msg_params(%rip), %rsi
    mov     $msg_params_len, %edx
    cmpq    $MAX_PARAMS, 48(%rsp)
    ja      3f
    mov     48(%rsp), %rax
    mov     40(%rsp), %r10
    mov     %rax, FRAME_count(%r10)
    addq    $FRAME_params, 40(%rsp)
    mov     NODE_children(%rbx), %rbx
    mov     NODE_children(%rbp), %rbp
1:  cmpq    $0, 48(%rsp)
    je      2f
    mov     0(%rbx), %rax
    mov     40(%rsp), %r10
    mov     %rax, 0(%r10)
    mov     24(%rsp), %rdi
    mov     0(%rbp), %rsi
    mov     32(%rsp), %rdx
    call    eval_arg
    mov     40(%rsp), %r10
    mov     %rdi, 8(%r10)
    add     $8, %rbx
    add     $8, %rbp
    addq    $16, 40(%rsp)
    decq    48(%rsp)
    jmp     1b
2:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $64, %rsp
    ret
3:  mov     NODE_content(%rbp), %rcx
    movzbq  NODE_content_len(%rbp), %r8
    jmp     die_name

# run_body: calls a2 (code_call or exec_call) with frame a1 on each child
# of NODE a0 from child a3 on, skipping the functions (definitions).
run_body:
    sub     $48, %rsp
    mov     %rbx, 8(%rsp)               # children left (s4)
    mov     %rbp, 16(%rsp)              # next child (s5)
                                        # 24(%rsp): frame (s6)
                                        # 32(%rsp): handler (s7)
    movzbq  NODE_children_len(%rdi), %rbx
    sub     %rcx, %rbx
    mov     NODE_children(%rdi), %rbp
    mov     %rcx, %rax
    shl     $3, %rax
    add     %rax, %rbp
    mov     %rsi, 24(%rsp)
    mov     %rdx, 32(%rsp)
1:  test    %rbx, %rbx
    jz      3f
    mov     0(%rbp), %rdi
    call    is_fn
    test    %rdi, %rdi
    jnz     2f
    mov     0(%rbp), %rdi
    mov     24(%rsp), %rsi
    mov     32(%rsp), %rax
    call    *%rax
2:  add     $8, %rbp
    dec     %rbx
    jmp     1b
3:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $48, %rsp
    ret

# ---------------------------------------------------------------------------
# Labels
# ---------------------------------------------------------------------------

# run_placed: runs the children of NODE a0, the program page or a placed
# function, in order: a function is placed, a call runs in code context.
run_placed:
    sub     $32, %rsp
    mov     %rbx, 8(%rsp)               # children left (s4)
    mov     %rbp, 16(%rsp)              # next child (s5)
    movzbq  NODE_children_len(%rdi), %rbx
    mov     NODE_children(%rdi), %rbp
1:  test    %rbx, %rbx
    jz      4f
    mov     0(%rbp), %rdi
    call    is_fn
    test    %rdi, %rdi
    jz      2f
    mov     0(%rbp), %rdi
    call    place
    jmp     3f
2:  mov     0(%rbp), %rdi
    mov     $0, %esi                    # no frame: placed code has no parameters
    call    code_call
3:  add     $8, %rbp
    dec     %rbx
    jmp     1b
4:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $32, %rsp
    ret

# place: places function a0 at cur_pc. Pass 1 adds it to labels, pass 2
# checks that it is still there; then its children run in its scope, and
# its end is recorded.
place:
    sub     $32, %rsp
    mov     %rbx, 8(%rsp)               # the function (s4)
    mov     %rbp, 16(%rsp)              # its LABEL (s5)
    mov     %rdi, %rbx
    lea     scope_depth(%rip), %rax     # push its scope
    mov     0(%rax), %r10
    cmp     $MAX_DEPTH, %r10
    je      3f
    lea     scopes(%rip), %r11
    mov     %r10, %rcx
    shl     $3, %rcx
    add     %rcx, %r11
    mov     %rbx, 0(%r11)
    inc     %r10
    mov     %r10, 0(%rax)
    mov     cur_pc(%rip), %r8           # t4
    mov     pass(%rip), %rax
    cmp     $1, %rax
    jne     1f
    lea     labels_end(%rip), %rax      # pass 1: a new label
    mov     0(%rax), %rbp
    lea     LABEL_size(%rbp), %r10
    mov     %r10, 0(%rax)
    mov     %rbx, LABEL_node(%rbp)
    mov     %r8, LABEL_addr(%rbp)
    jmp     2f
1:  lea     label_next(%rip), %rax      # pass 2: the same, at the same place
    mov     0(%rax), %rbp
    lea     LABEL_size(%rbp), %r10
    mov     %r10, 0(%rax)
    mov     LABEL_node(%rbp), %r10
    cmp     %rbx, %r10
    jne     4f
    mov     LABEL_addr(%rbp), %r10
    cmp     %r8, %r10
    jne     4f
2:  mov     %rbx, %rdi
    call    run_placed
    mov     cur_pc(%rip), %rax
    mov     %rax, LABEL_end(%rbp)
    decq    scope_depth(%rip)
    mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $32, %rsp
    ret
3:  lea     msg_depth(%rip), %rsi
    mov     $msg_depth_len, %edx
    jmp     5f
4:  lea     msg_moved(%rip), %rsi
    mov     $msg_moved_len, %edx
5:  mov     NODE_content(%rbx), %rcx
    movzbq  NODE_content_len(%rbx), %r8
    jmp     die_name

# find_label: a0 = the placed function named by the a1 bytes at a0, or 0:
# among the functions in the innermost scope first, then outward to the
# program page.
find_label:
    sub     $48, %rsp
    mov     %rbx, 8(%rsp)               # name (s4)
    mov     %rbp, 16(%rsp)              # name length (s5)
                                        # 24(%rsp): just past the scope being searched (s6)
                                        # 32(%rsp): its children left (s7)
                                        # 40(%rsp): next child (s8)
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    mov     scope_depth(%rip), %rax
    shl     $3, %rax
    lea     scopes(%rip), %r10
    add     %rax, %r10
    mov     %r10, 24(%rsp)
1:  lea     scopes(%rip), %rax
    cmp     %rax, 24(%rsp)
    je      4f
    subq    $8, 24(%rsp)
    mov     24(%rsp), %rax
    mov     0(%rax), %rax
    movzbq  NODE_children_len(%rax), %r10
    mov     %r10, 32(%rsp)
    mov     NODE_children(%rax), %r10
    mov     %r10, 40(%rsp)
2:  cmpq    $0, 32(%rsp)
    je      1b
    mov     40(%rsp), %rax
    mov     0(%rax), %rdi
    call    is_fn
    test    %rdi, %rdi
    jz      3f
    mov     40(%rsp), %rax
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rdx
    movzbq  NODE_content_len(%rax), %rcx
    dec     %rcx
    mov     %rbx, %rdi
    mov     %rbp, %rsi
    call    streq
    test    %rdi, %rdi
    jz      3f
    mov     40(%rsp), %rax
    mov     0(%rax), %rdi
    jmp     5f
3:  addq    $8, 40(%rsp)
    decq    32(%rsp)
    jmp     2b
4:  mov     $0, %edi
5:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $48, %rsp
    ret

# label_entry: a0 = the LABEL of placed function a0, or 0 when pass 1 has
# not met it yet.
label_entry:
    lea     labels(%rip), %rax
    mov     labels_end(%rip), %r10
1:  cmp     %r10, %rax
    je      2f
    mov     LABEL_node(%rax), %r11
    cmp     %rdi, %r11
    je      3f
    add     $LABEL_size, %rax
    jmp     1b
2:  mov     $0, %edi
    ret
3:  mov     %rax, %rdi
    ret

# label_addr: a0 = the address of placed function a0 (0 when pass 1 has
# not met it yet).
label_addr:
    sub     $16, %rsp
    call    label_entry
    test    %rdi, %rdi
    jz      1f
    mov     LABEL_addr(%rdi), %rdi
1:  add     $16, %rsp
    ret

# lookup_call: a0 = the function that call a0 calls; dies when unknown.
lookup_call:
    sub     $16, %rsp
    mov     %rbx, 8(%rsp)               # the call (s4)
    mov     %rdi, %rbx
    mov     NODE_content(%rbx), %rdi
    movzbq  NODE_content_len(%rbx), %rsi
    call    find_fn
    test    %rdi, %rdi
    jz      1f
    mov     8(%rsp), %rbx
    add     $16, %rsp
    ret
1:  lea     msg_function(%rip), %rsi
    mov     $msg_function_len, %edx
    mov     NODE_content(%rbx), %rcx
    movzbq  NODE_content_len(%rbx), %r8
    jmp     die_name

    .equ CALL_frame, 32                 # the new frame on the stack
    .equ CALL_stack, (CALL_frame + FRAME_size + 15) & ~15

# code_call: runs call a0 in code context, in frame a1: an instruction is
# encoded and emitted, any other function expands its body. The builtins:
#   ascii <bytes>   emits the content of its argument as it is
#   align n         pads with zeros up to a multiple of n
#   reserve n       n zero bytes
#   origin n        the address of what follows
#   bss             from here on align and reserve only move the address
code_call:
    sub     $CALL_stack, %rsp
    mov     %rbx, 8(%rsp)               # the call (s4)
    mov     %rbp, 16(%rsp)              # caller's frame (s5)
                                        # 24(%rsp): the function (s6)
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    lea     str_ascii(%rip), %rsi
    mov     $5, %edx
    call    is_named
    test    %rdi, %rdi
    jnz     3f
    mov     %rbx, %rdi
    lea     str_align(%rip), %rsi
    mov     $5, %edx
    call    is_named
    test    %rdi, %rdi
    jnz     4f
    mov     %rbx, %rdi
    lea     str_reserve(%rip), %rsi
    mov     $7, %edx
    call    is_named
    test    %rdi, %rdi
    jnz     5f
    mov     %rbx, %rdi
    lea     str_origin(%rip), %rsi
    mov     $6, %edx
    call    is_named
    test    %rdi, %rdi
    jnz     6f
    mov     %rbx, %rdi
    lea     str_bss(%rip), %rsi
    mov     $3, %edx
    call    is_named
    test    %rdi, %rdi
    jnz     7f
    mov     %rbx, %rdi
    call    lookup_call
    mov     %rdi, 24(%rsp)
    mov     %rbx, %rsi
    mov     %rbp, %rdx
    mov     $0, %ecx
    lea     CALL_frame(%rsp), %r8
    call    bind
    mov     24(%rsp), %rdi
    call    is_insn
    test    %rdi, %rdi
    jz      1f
    mov     24(%rsp), %rdi
    lea     CALL_frame(%rsp), %rsi
    call    encode
    mov     %rbx, %rdx
    call    emit
    jmp     2f
1:  mov     24(%rsp), %rdi
    call    param_count
    mov     %rdi, %rcx
    mov     24(%rsp), %rdi
    lea     CALL_frame(%rsp), %rsi
    lea     code_call(%rip), %rdx
    call    run_body
2:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $CALL_stack, %rsp
    ret
3:  movzbq  NODE_children_len(%rbx), %rax   # ascii
    cmp     $1, %rax
    jne     wrong_args
    mov     NODE_children(%rbx), %rax
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    call    emit_raw
    jmp     2b
4:  mov     %rbx, %rdi                  # align
    mov     %rbp, %rsi
    call    one_arg
    mov     cur_pc(%rip), %rax
    mov     %rax, %r10                  # remu t1, t0, a0: RISC-V gives t0 for
    test    %rdi, %rdi                  # a0 = 0 where div would trap
    jz      8f
    xor     %edx, %edx
    div     %rdi
    mov     %rdx, %r10
8:  test    %r10, %r10
    jz      2b
    sub     %r10, %rdi
    call    skip
    jmp     2b
5:  mov     %rbx, %rdi                  # reserve
    mov     %rbp, %rsi
    call    one_arg
    call    skip
    jmp     2b
6:  mov     %rbx, %rdi                  # origin
    mov     %rbp, %rsi
    call    one_arg
    mov     %rdi, cur_pc(%rip)
    jmp     2b
7:  movzbq  NODE_children_len(%rbx), %rax   # bss
    test    %rax, %rax
    jnz     wrong_args
    movq    $1, in_bss(%rip)
    jmp     2b

# wrong_args: dies about call s4 having the wrong number of arguments.
wrong_args:
    lea     msg_args(%rip), %rsi
    mov     $msg_args_len, %edx
    mov     NODE_content(%rbx), %rcx
    movzbq  NODE_content_len(%rbx), %r8
    jmp     die_name

# one_arg: a0 = the value of the one argument of builtin call a0, in frame
# a1 and code context.
one_arg:
    sub     $16, %rsp
    mov     %rbx, 8(%rsp)               # the call (s4)
    mov     %rdi, %rbx
    movzbq  NODE_children_len(%rbx), %rax
    cmp     $1, %rax
    jne     wrong_args
    mov     %rsi, %rdi
    mov     NODE_children(%rbx), %rsi
    mov     0(%rsi), %rsi
    mov     $0, %edx
    call    eval_arg
    mov     8(%rsp), %rbx
    add     $16, %rsp
    ret

# is_named: a0 = 1 when the content of NODE a0 is the a2 bytes at a1.
is_named:
    mov     %rdx, %rcx
    mov     %rsi, %rdx
    movzbq  NODE_content_len(%rdi), %rsi
    mov     NODE_content(%rdi), %rdi
    jmp     streq

# exec_call: runs call a0 in exec context, in frame a1: an instruction is
# executed on vregs, any other function runs its body. The builtin
# size <label> leaves the size of the label in a0.
exec_call:
    sub     $CALL_stack, %rsp
    mov     %rbx, 8(%rsp)               # the call (s4)
    mov     %rbp, 16(%rsp)              # caller's frame (s5)
                                        # 24(%rsp): the function (s6)
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    lea     str_size(%rip), %rsi
    mov     $4, %edx
    call    is_named
    test    %rdi, %rdi
    jnz     3f
    mov     %rbx, %rdi
    call    lookup_call
    mov     %rdi, 24(%rsp)
    call    is_insn
    test    %rdi, %rdi
    jz      1f
    mov     24(%rsp), %rdi
    mov     %rbx, %rsi
    mov     %rbp, %rdx
    call    execute
    jmp     2f
1:  mov     24(%rsp), %rdi
    mov     %rbx, %rsi
    mov     %rbp, %rdx
    mov     $1, %ecx
    lea     CALL_frame(%rsp), %r8
    call    bind
    mov     24(%rsp), %rdi
    call    param_count
    mov     %rdi, %rcx
    mov     24(%rsp), %rdi
    lea     CALL_frame(%rsp), %rsi
    lea     exec_call(%rip), %rdx
    call    run_body
2:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $CALL_stack, %rsp
    ret
3:  movzbq  NODE_children_len(%rbx), %rax   # size
    cmp     $1, %rax
    jne     wrong_args
    mov     NODE_children(%rbx), %rax
    mov     0(%rax), %rax
    mov     %rax, 24(%rsp)              # the label
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    call    find_label
    test    %rdi, %rdi
    jz      5f
    call    label_entry
    mov     $0, %eax                    # not met yet in pass 1
    test    %rdi, %rdi
    jz      4f
    mov     LABEL_end(%rdi), %rax
    mov     LABEL_addr(%rdi), %r10
    sub     %r10, %rax
4:  mov     %rax, vregs+VREG_a0*8(%rip)
    jmp     2b
5:  lea     msg_name(%rip), %rsi
    mov     $msg_name_len, %edx
    mov     24(%rsp), %rax
    mov     NODE_content(%rax), %rcx
    movzbq  NODE_content_len(%rax), %r8
    jmp     die_name

# execute: executes call a1 of instruction a0 in frame a2, on vregs: the
# parameter rd names the destination register, the other two give the
# values v0 and v1 in parameter order, and rd = v1 op v0, op found by name
# in exec_ops (the seed).
execute:
    sub     $96, %rsp
    mov     %rbx, 8(%rsp)               # the call (s4)
    mov     %rbp, 16(%rsp)              # frame (s5)
                                        # 24(%rsp): next parameter (s6)
                                        # 32(%rsp): next argument (s7)
                                        # 40(%rsp): parameters left (s8)
                                        # 48(%rsp): destination register (s9)
                                        # 56(%rsp): values so far (s10)
    # 64(%rsp), 72(%rsp): v0, v1
    mov     %rsi, %rbx
    mov     %rdx, %rbp
    mov     %rdi, 24(%rsp)
    call    param_count
    mov     %rdi, 40(%rsp)
    movzbq  NODE_children_len(%rbx), %rax
    cmp     40(%rsp), %rax
    jne     8f
    mov     24(%rsp), %rax
    mov     NODE_children(%rax), %rax
    mov     %rax, 24(%rsp)
    mov     NODE_children(%rbx), %rax
    mov     %rax, 32(%rsp)
    movq    $0, 48(%rsp)
    movq    $0, 56(%rsp)
1:  cmpq    $0, 40(%rsp)
    je      3f
    mov     24(%rsp), %rax
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    lea     str_rd(%rip), %rdx
    mov     $2, %ecx
    call    streq
    test    %rdi, %rdi
    jz      2f
    mov     32(%rsp), %rax              # rd: a register name
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    call    find_reg
    test    %rdi, %rdi
    js      7f
    mov     %rdi, 48(%rsp)
    jmp     6f
2:  cmpq    $2, 56(%rsp)
    je      9f                          # more than two values: no seed op
    mov     %rbp, %rdi
    mov     32(%rsp), %rsi
    mov     0(%rsi), %rsi
    mov     $1, %edx
    call    eval_arg
    mov     56(%rsp), %rax
    shl     $3, %rax
    add     %rsp, %rax
    mov     %rdi, 64(%rax)
    incq    56(%rsp)
6:  addq    $8, 24(%rsp)
    addq    $8, 32(%rsp)
    decq    40(%rsp)
    jmp     1b
3:  cmpq    $2, 56(%rsp)
    jne     9f
    mov     NODE_content(%rbx), %rax    # find the op by name
    mov     %rax, 24(%rsp)
    movzbq  NODE_content_len(%rbx), %rax
    mov     %rax, 32(%rsp)
    cmp     $8, %rax
    ja      9f
    lea     exec_ops(%rip), %rax
    mov     %rax, 40(%rsp)
10: lea     exec_ops_end(%rip), %rax
    cmp     %rax, 40(%rsp)
    je      9f
    mov     24(%rsp), %rdi
    mov     32(%rsp), %rsi
    mov     40(%rsp), %rdx
    mov     32(%rsp), %rcx
    call    streq
    test    %rdi, %rdi
    jz      11f
    mov     32(%rsp), %rax              # and the op's name ends there
    cmp     $8, %rax
    je      12f
    add     40(%rsp), %rax
    movzbq  0(%rax), %rax
    test    %rax, %rax
    jz      12f
11: addq    $OP_size, 40(%rsp)
    jmp     10b
12: mov     64(%rsp), %rax
    mov     72(%rsp), %r10
    mov     40(%rsp), %rcx
    mov     OP_code(%rcx), %rcx
    jmp     *%rcx
7:  lea     msg_register(%rip), %rsi
    mov     $msg_register_len, %edx
    mov     32(%rsp), %rax
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rcx
    movzbq  NODE_content_len(%rax), %r8
    jmp     die_name
8:  jmp     wrong_args
9:  lea     msg_execute(%rip), %rsi
    mov     $msg_execute_len, %edx
    mov     NODE_content(%rbx), %rcx
    movzbq  NODE_content_len(%rbx), %r8
    jmp     die_name

# The ops of exec_ops: t2 = t1 op t0, then exec_store, still in the frame
# of execute. RV64 semantics: 64-bit, mul keeps the low 64 bits, the shifts
# take the amount mod 64 (as shl/shr/sar by %cl do).
op_add:
    mov     %r10, %r11
    add     %rax, %r11
    jmp     exec_store
op_sub:
    mov     %r10, %r11
    sub     %rax, %r11
    jmp     exec_store
op_and:
    mov     %r10, %r11
    and     %rax, %r11
    jmp     exec_store
op_or:
    mov     %r10, %r11
    or      %rax, %r11
    jmp     exec_store
op_xor:
    mov     %r10, %r11
    xor     %rax, %r11
    jmp     exec_store
op_sll:
    mov     %rax, %rcx
    mov     %r10, %r11
    shl     %cl, %r11
    jmp     exec_store
op_srl:
    mov     %rax, %rcx
    mov     %r10, %r11
    shr     %cl, %r11
    jmp     exec_store
op_sra:
    mov     %rax, %rcx
    mov     %r10, %r11
    sar     %cl, %r11
    jmp     exec_store
op_mul:
    mov     %r10, %r11
    imul    %rax, %r11
# exec_store: stores t2 in the destination vreg s9 and returns from execute.
exec_store:
    mov     48(%rsp), %r10
    test    %r10, %r10
    jz      1f                          # x0 stays 0
    lea     vregs(%rip), %rax
    shl     $3, %r10
    add     %r10, %rax
    mov     %r11, 0(%rax)
1:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $96, %rsp
    ret

# ---------------------------------------------------------------------------
# Encoding and output
# ---------------------------------------------------------------------------

# encode: encodes instruction a0, its parameters bound in frame a1: a0 =
# the word, a1 = its width in bits (8, 16, 32 or 64). The fields come MSB
# first: word = word << width | value.
encode:
    sub     $80, %rsp
    mov     %rbx, 8(%rsp)               # the instruction (s4)
    mov     %rbp, 16(%rsp)              # frame (s5)
                                        # 24(%rsp): fields left (s6)
                                        # 32(%rsp): next field (s7)
                                        # 40(%rsp): word (s8)
                                        # 48(%rsp): width so far (s9)
                                        # 56(%rsp): width of this field (s10)
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    call    param_count
    movzbq  NODE_children_len(%rbx), %rax
    sub     %rdi, %rax
    mov     %rax, 24(%rsp)
    mov     NODE_children(%rbx), %rax
    shl     $3, %rdi
    add     %rdi, %rax
    mov     %rax, 32(%rsp)
    movq    $0, 40(%rsp)
    movq    $0, 48(%rsp)
1:  cmpq    $0, 24(%rsp)
    je      4f
    mov     32(%rsp), %rax
    mov     0(%rax), %rdi
    call    is_fn
    mov     32(%rsp), %rax
    mov     0(%rax), %rax
    test    %rdi, %rdi
    jz      2f
    movzbq  NODE_children_len(%rax), %r10   # a fixed field: its child is its bits
    test    %r10, %r10
    jz      8f
    mov     NODE_children(%rax), %r10
    mov     0(%r10), %r10
    mov     NODE_content(%r10), %rdi
    movzbq  NODE_content_len(%r10), %rsi
    mov     %rsi, 56(%rsp)
    call    parse_bits
    jmp     3f
2:  mov     %rax, %rdi                  # a slice call: run it, value in a0
    mov     %rbp, %rsi
    call    exec_call
    mov     32(%rsp), %rax
    mov     0(%rax), %rax
    mov     NODE_content(%rax), %rdi
    movzbq  NODE_content_len(%rax), %rsi
    call    slice_width
    mov     %rdi, 56(%rsp)
    mov     vregs+VREG_a0*8(%rip), %rdi
3:  cmpq    $64, 56(%rsp)
    je      10f                         # a 64-bit field is the whole word
    mov     56(%rsp), %rcx              # sll by s10: the amount mod 64
    mov     $1, %eax
    shl     %cl, %rax
    dec     %rax
    and     %rax, %rdi
    shlq    %cl, 40(%rsp)
10: or      %rdi, 40(%rsp)
    mov     56(%rsp), %rax
    add     %rax, 48(%rsp)
    addq    $8, 32(%rsp)
    decq    24(%rsp)
    jmp     1b
4:  mov     48(%rsp), %rax
    cmp     $8, %rax
    je      5f
    cmp     $16, %rax
    je      5f
    cmp     $32, %rax
    je      5f
    cmp     $64, %rax
    jne     9f
5:  mov     40(%rsp), %rdi
    mov     48(%rsp), %rsi
    mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $80, %rsp
    ret
8:  lea     msg_field(%rip), %rsi
    mov     $msg_field_len, %edx
    mov     NODE_content(%rax), %rcx
    movzbq  NODE_content_len(%rax), %r8
    jmp     die_name
9:  lea     msg_width(%rip), %rsi
    mov     $msg_width_len, %edx
    mov     NODE_content(%rbx), %rcx
    movzbq  NODE_content_len(%rbx), %r8
    jmp     die_name

# emit: emits the a1-bit word a0, little endian, and in pass 2 prints it
# as "<hex>  <name of call a2>".
emit:
    sub     $48, %rsp
    mov     %rbx, 8(%rsp)               # word (s4)
    mov     %rbp, 16(%rsp)              # width (s5)
                                        # 24(%rsp): the call (s6)
    # 32(%rsp): the word in memory
    mov     %rdi, %rbx
    mov     %rsi, %rbp
    mov     %rdx, 24(%rsp)
    mov     %rbx, 32(%rsp)
    lea     32(%rsp), %rdi
    mov     %rbp, %rsi
    shr     $3, %rsi
    call    emit_raw
    mov     pass(%rip), %rax
    cmp     $2, %rax
    jne     5f
    lea     linebuf(%rip), %rax
    lea     hexdigits(%rip), %r10
    mov     %rbp, %r11
    shr     $2, %r11                    # hex digits
    lea     -4(%rbp), %rcx              # shift of the next one
3:  test    %r11, %r11
    jz      4f
    mov     %rbx, %r8
    shr     %cl, %r8
    and     $15, %r8
    add     %r10, %r8
    movzbq  0(%r8), %r8
    mov     %r8b, 0(%rax)
    inc     %rax
    sub     $4, %rcx
    dec     %r11
    jmp     3b
4:  mov     $CH_space, %r8d
    mov     %r8b, 0(%rax)
    mov     %r8b, 1(%rax)
    add     $2, %rax
    lea     linebuf(%rip), %rsi
    mov     %rax, %rdx
    sub     %rsi, %rdx
    call    write_out
    mov     24(%rsp), %rax
    mov     NODE_content(%rax), %rsi
    movzbq  NODE_content_len(%rax), %rdx
    call    write_out
    lea     newline(%rip), %rsi
    mov     $1, %edx
    call    write_out
5:  mov     8(%rsp), %rbx
    mov     16(%rsp), %rbp
    add     $48, %rsp
    ret

# emit_raw: appends the a1 bytes at a0 to outbuf and moves cur_pc past
# them.
emit_raw:
    mov     in_bss(%rip), %rax
    test    %rax, %rax
    jnz     emitted_in_bss
    lea     out_end(%rip), %rdx         # t6
    mov     0(%rdx), %rax
    lea     outbuf(%rip), %r10
    mov     $OUT_SIZE, %r11d
    add     %r11, %r10
    lea     (%rax,%rsi), %rcx
    cmp     %r10, %rcx
    ja      out_full
    lea     cur_pc(%rip), %r8
    mov     0(%r8), %r9
    add     %rsi, %r9
    mov     %r9, 0(%r8)
1:  test    %rsi, %rsi
    jz      2f
    movzbq  0(%rdi), %r11
    mov     %r11b, 0(%rax)
    inc     %rdi
    inc     %rax
    dec     %rsi
    jmp     1b
2:  mov     %rax, 0(%rdx)
    ret

# skip: moves cur_pc a0 bytes on: by emitting zero bytes, or after bss
# only the address.
skip:
    sub     $16, %rsp
    mov     %rbx, 8(%rsp)               # bytes left (s4)
    mov     %rdi, %rbx
    mov     in_bss(%rip), %rax
    test    %rax, %rax
    jz      1f
    lea     cur_pc(%rip), %rax
    mov     0(%rax), %r10
    add     %rbx, %r10
    mov     %r10, 0(%rax)
    jmp     2f
1:  test    %rbx, %rbx
    jz      2f
    lea     zero_byte(%rip), %rdi
    mov     $1, %esi
    call    emit_raw
    dec     %rbx
    jmp     1b
2:  mov     8(%rsp), %rbx
    add     $16, %rsp
    ret

# write_output: writes outbuf, everything emitted, to the file out_path.
write_output:
    sub     $16, %rsp
    mov     %rbx, 8(%rsp)               # fd (s4)
    mov     $AT_FDCWD, %rdi
    mov     out_path(%rip), %rsi
    mov     $O_CREAT_WRONLY_TRUNC, %edx
    mov     $MODE_0755, %r10d           # a3
    mov     $SYS_openat, %eax
    syscall
    test    %rax, %rax
    js      create_failed
    mov     %rax, %rbx
    mov     %rax, %rdi                  # a0: the fd, as ecall leaves it
    lea     outbuf(%rip), %rsi
    mov     out_end(%rip), %rdx
    sub     %rsi, %rdx
    call    write_all
    mov     %rbx, %rdi
    mov     $SYS_close, %eax
    syscall
    mov     8(%rsp), %rbx
    add     $16, %rsp
    ret

# write_all: writes the a2 bytes at a1 to fd a0, however many writes it
# takes. (The fd stays in a0: syscall does not change %rdi.)
write_all:
1:  test    %rdx, %rdx
    jz      2f
    mov     $SYS_write, %eax
    syscall
    test    %rax, %rax
    jle     write_failed
    add     %rax, %rsi
    sub     %rax, %rdx
    jmp     1b
2:  ret

# write_out: writes a2 bytes at a1 to stdout.
write_out:
    mov     $STDOUT, %edi
    mov     $SYS_write, %eax
    syscall
    ret

create_failed:
    lea     msg_create(%rip), %rsi
    mov     $msg_create_len, %edx
    jmp     die
write_failed:
    lea     msg_write(%rip), %rsi
    mov     $msg_write_len, %edx
    jmp     die
out_full:
    lea     msg_full(%rip), %rsi
    mov     $msg_full_len, %edx
    jmp     die
emitted_in_bss:
    lea     msg_bss(%rip), %rsi
    mov     $msg_bss_len, %edx
    jmp     die

# die_name: writes the a2-byte message at a1 and the a4-byte name at a3 to
# stderr, then a newline, and exits with status 1.
die_name:
    mov     %rcx, %rbx                  # syscall clobbers %rcx
    mov     %r8, %rbp
    mov     $STDERR, %edi
    mov     $SYS_write, %eax
    syscall
    mov     $STDERR, %edi
    mov     %rbx, %rsi
    mov     %rbp, %rdx
    mov     $SYS_write, %eax
    syscall
    lea     newline(%rip), %rsi
    mov     $1, %edx

# die: writes the a2-byte message at a1 to stderr and exits with status 1.
die:
    mov     $STDERR, %edi
    mov     $SYS_write, %eax
    syscall
    mov     $1, %edi
exit:
    mov     $SYS_exit, %eax
    syscall
