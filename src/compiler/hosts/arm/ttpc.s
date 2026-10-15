@ ttpc.s (arm) — the trust project compiler, in 32-bit ARM assembly, without
@ libc.
@
@ FROZEN: this is stage0 on an arm host, a port of ../../ttpc.s (riscv64),
@ the seed of the bootstrap (see PLAN.md). It must agree with ttpc.s byte for
@ byte: the same stdout, stderr, output file and exit status for every input.
@ It translates ttpc.s function by function, with the same labels in the same
@ order, so that an auditor can read the two side by side. There is ONE
@ deliberate difference: OUT_SIZE is 1 << 20 (1 MiB) here, 1 << 16 in ttpc.s,
@ so that this seed assembles programs that the riscv seed finds too large.
@
@ A static Linux arm program (ARMv7-A, ARM mode, EABI; run it with qemu-arm on
@ another host). It talks to the kernel only through svc: it opens the ff
@ file named by its first argument and loads it into memory as a tree of
@ NODEs.
@
@   ttpc <file.ff>          prints the tree, one node per line
@   ttpc <file.ff> <out>    assembles it into the static executable <out>
@
@ Assembling: a node whose content ends in ':' is a function, its leading
@ children that are leaves are its parameters. Any other node is a call, its
@ children are the arguments. The root's children are pages. The functions
@ on every page but the last are definitions: instructions, macros,
@ constants. The last page is the program: its functions are placed, they
@ are labels whose children are emitted where they stand (nested ones are
@ local labels, found innermost scope first), and its calls are emitted in
@ order. Pass 1 finds every label's address, pass 2 emits.
@
@ A function whose body (the children after its parameters) holds only
@ fields, fixed fields (funct3:, ...) and slice calls (imm[11:0] imm), is an
@ encoding: an instruction or a data word of 8 to 64 bits. A call runs in
@ one of three contexts:
@
@   code   a call of an encoding is encoded and emitted, a call of any
@          other function expands its body in code context.
@   field  encoding: the fields, MSB first. A fixed field is its bits; a
@          slice call runs in exec context and leaves its value in a0, its
@          width is in its name.
@   exec   runs at assemble time on vregs. The ops of exec_ops are built
@          in, the seed; everything else is defined by the tree.
@
@ An argument with children is a call, run in exec context: its value is
@ a0. A leaf argument is a decimal or 0x number, a parameter, a register
@ (its number in code context, its vreg in exec context), pc, a label (its
@ address) or a constant (a function without parameters, run in exec
@ context). The builtins: ascii, align, reserve, origin, bss (see
@ code_call) and size (see exec_call).
@
@ Registers are the functions "x10 a0:", their number is their child "01010".
@ The output file is exactly what the program emits: its ELF header is ff
@ too (elf_header in macros.ff.txt).
@
@ ff on disk, one node, depth-first (children inline, before the content):
@   hash          byte[32]
@   children_len  u8
@   children      node × children_len
@   content_len   u8
@   content       byte × content_len    // no NUL termination: may be binary
@
@ NODE in memory (64 bytes, naturally aligned), the layout of ttpc.s:
@   0   hash          byte[32]
@   32  children_len  int8
@   40  children      NODE**            // -> pointer array in ptrs
@   48  content_len   int8
@   56  content       char*             // -> into buf, not copied
@
@ The port. ttpc.s computes in 64 bits, this machine has 32. All memory
@ layouts stay those of ttpc.s (NODE, FRAME, LABEL, OP, vregs, the .dword
@ variables): a pointer is 32 bits and sits in the low word of its 8-byte
@ slot, its high word is 0 (bss starts zeroed and only the low word is ever
@ written, or a 0 is stored with it). Small counters in .dword variables
@ (pass, in_bss, scope_depth) likewise only use the low word.
@
@ Every VALUE (vregs, numbers, parameters, fields, the encoded word, widths
@ of fields, cur_pc, label addresses) is 64 bits: a register pair lo:hi,
@ always an even/odd pair (r0:r1, r2:r3, r4:r5, ...) so that ldrd/strd move
@ it. It wraps exactly as on RV64.
@
@ Register map (riscv64 -> arm):
@   a0 a1 a2 a3   r0 r1 r2 r3       arguments and results; a 64-bit a0
@                                   result is r0:r1 (see each function for
@                                   where its other 64-bit values go)
@   a4            r12 (ip)          the fifth argument (bind, die_name)
@   a7            r7                the syscall number
@   t0..t6        r0-r3, r12        scratch; lr once it is saved
@   s0 s1 s2 s3   r8 r9 r10 r11     the loading globals (parse cursor, end of
@                                   the loaded bytes, next NODE, next slot
@                                   in ptrs), only in _start and parse_node
@   s4..s11       r4..r11           callee-saved, per function as in ttpc.s
@                                   unless its comment says otherwise
@   ra            lr
@ r7 is both s7 and the syscall number: every svc site that returns saves
@ r7. Functions save their callee-saved registers and lr with push/pop (an
@ even count, so sp stays 8-byte aligned), or, where ttpc.s keeps locals at
@ fixed offsets in its frame (code_call, exec_call, execute, encode), with
@ the same frame and offsets.
@
@ The 64-bit helpers (section "64-bit values") do what RV64 does in one
@ instruction. They take the value in r0:r1 and leave the result there,
@ touch only r0-r3 and r12, and are called with bl:
@   sll64, srl64, sra64   r0:r1 shifted by r2 mod 64 (sll, srl, sra)
@   mul64                 r0:r1 = low 64 bits of r0:r1 * r2:r3 (mul)
@   remu64                r0:r1 = r0:r1 mod r2:r3, unsigned, r0:r1 when
@                         r2:r3 is 0 (remu); keeps r2:r3
@ Adds, subtracts and compares of values are inline: adds/adc, subs/sbc,
@ and equality as cmp lo + cmpeq hi. A value's sign (bltz) is its hi's.

    .syntax unified
    .arch armv7-a
    .arm

    @ la: the address of a symbol (movw/movt, no literal pool).
    .macro la rd, sym
    movw    \rd, #:lower16:\sym
    movt    \rd, #:upper16:\sym
    .endm

    .equ SYS_openat, 322
    .equ SYS_close, 6
    .equ SYS_read, 3
    .equ SYS_write, 4
    .equ SYS_exit, 1

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

    @ A frame binds the parameters of a call: count, then (param NODE*,
    @ value) pairs.
    .equ MAX_PARAMS, 8
    .equ FRAME_count, 0
    .equ FRAME_params, 8
    .equ FRAME_size, 8 + MAX_PARAMS * 16

    .equ VREG_a0, 10
    .equ OUT_SIZE, 1 << 20              @ 1 << 16 in ttpc.s: the one difference
    .equ MAX_DEPTH, 64                  @ nesting of placed functions

    @ A label: a placed function, its address and the address after it.
    .equ LABEL_node, 0
    .equ LABEL_addr, 8
    .equ LABEL_end, 16
    .equ LABEL_size, 24

    @ An exec op: its name, NUL-padded, and its code.
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
    @ Every node takes at least 34 bytes on disk, so a full buf holds fewer
    @ than MAX_NODES nodes: the node and pointer arenas cannot overflow.
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
@ Followed by the name they are about:
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
hexbuf:         .ascii "00000000  "         @ hash prefix of a printed line
    .balign 8
@ Each a .dword of ttpc.s: low word, high word.
out_path:       .word 0, 0                  @ argv[2], 0 when only printing
out_end:        .word outbuf, 0             @ next free byte in outbuf
syms_end:       .word syms, 0               @ next free slot in syms
labels_end:     .word labels, 0             @ next free LABEL (pass 1)
label_next:     .word labels, 0             @ next LABEL to check (pass 2)
pass:           .word 0, 0                  @ 1 or 2
cur_pc:         .word 0, 0                  @ address of the next byte (64 bits)
in_bss:         .word 0, 0                  @ 1 after the builtin bss
scope_depth:    .word 0, 0                  @ placed functions in scopes

@ The exec seed: the instructions that exec context runs itself, rd = v1 op
@ v0, with v0 and v1 the other operands in parameter order (rs2 rs1, or imm
@ rs1, or shamt rs1). The code pointer is the .dword of ttpc.s: the address
@ and a 0 high word, so OP_size stays 16.
exec_ops:
    .ascii "add\0\0\0\0\0"
    .word   op_add, 0
    .ascii "addi\0\0\0\0"
    .word   op_add, 0
    .ascii "sub\0\0\0\0\0"
    .word   op_sub, 0
    .ascii "and\0\0\0\0\0"
    .word   op_and, 0
    .ascii "andi\0\0\0\0"
    .word   op_and, 0
    .ascii "or\0\0\0\0\0\0"
    .word   op_or, 0
    .ascii "ori\0\0\0\0\0"
    .word   op_or, 0
    .ascii "xor\0\0\0\0\0"
    .word   op_xor, 0
    .ascii "xori\0\0\0\0"
    .word   op_xor, 0
    .ascii "sll\0\0\0\0\0"
    .word   op_sll, 0
    .ascii "slli\0\0\0\0"
    .word   op_sll, 0
    .ascii "srl\0\0\0\0\0"
    .word   op_srl, 0
    .ascii "srli\0\0\0\0"
    .word   op_srl, 0
    .ascii "sra\0\0\0\0\0"
    .word   op_sra, 0
    .ascii "srai\0\0\0\0"
    .word   op_sra, 0
    .ascii "mul\0\0\0\0\0"
    .word   op_mul, 0
exec_ops_end:

    .section .bss
    .balign 8
nodes:          .skip MAX_NODES * NODE_size
ptrs:           .skip MAX_NODES * 8
syms:           .skip MAX_NODES * 8         @ the function NODEs, see collect_syms
labels:         .skip MAX_NODES * LABEL_size
scopes:         .skip MAX_DEPTH * 8         @ the placed functions around pc
vregs:          .skip 32 * 8                @ the registers of exec context
linebuf:        .skip 24                    @ hex of an emitted word
outbuf:         .skip OUT_SIZE
buf:            .skip BUF_SIZE

@ Registers that live across the loading (s0..s3 of ttpc.s):
@   r8   parse cursor in buf
@   r9   end of the loaded bytes
@   r10  next free NODE in nodes
@   r11  next free slot in ptrs

    .section .text
    .globl _start
_start:
    ldr     r0, [sp]                    @ argc
    cmp     r0, #2
    blt     usage
    cmp     r0, #3
    bgt     usage
    blt     1f
    ldr     r1, [sp, #12]               @ argv[2]
    la      r2, out_path
    str     r1, [r2]
1:  ldr     r1, [sp, #8]                @ argv[1]

    mov     r0, #AT_FDCWD
    mov     r2, #O_RDONLY
    mov     r3, #0
    movw    r7, #SYS_openat
    svc     #0
    cmp     r0, #0
    blt     open_failed
    mov     r4, r0                      @ fd

    @ Read the whole file into buf.
    la      r8, buf
    mov     r9, r8
    add     r5, r8, #BUF_SIZE           @ end of buf
read_loop:
    cmp     r9, r5
    beq     too_large
    mov     r0, r4
    mov     r1, r9
    sub     r2, r5, r9
    mov     r7, #SYS_read
    svc     #0
    cmp     r0, #0
    blt     read_failed
    beq     read_done
    add     r9, r9, r0
    b       read_loop
read_done:
    mov     r0, r4
    mov     r7, #SYS_close
    svc     #0

    la      r10, nodes
    la      r11, ptrs
    bl      parse_node
    cmp     r8, r9
    bne     trailing
    la      r1, out_path
    ldr     r1, [r1]
    cmp     r1, #0
    bne     assemble
    mov     r1, #0
    bl      print_node

    mov     r0, #0
    b       exit

@ assemble: places the last page of root r0, the program, twice: pass 1
@ finds the address of every label, pass 2 emits with them. Then writes
@ the output file.
assemble:
    mov     r6, r0                      @ root
    bl      collect_syms
    ldrb    r0, [r6, #NODE_children_len]
    cmp     r0, #0
    beq     2f
    ldr     r1, [r6, #NODE_children]
    add     r1, r1, r0, lsl #3
    ldr     r7, [r1, #-8]               @ the program page
    mov     r8, #1                      @ pass
1:  la      r0, pass
    str     r8, [r0]
    la      r0, cur_pc
    mov     r2, #0
    mov     r3, #0
    strd    r2, r3, [r0]
    la      r0, in_bss
    str     r2, [r0]
    la      r0, out_end
    la      r1, outbuf
    str     r1, [r0]
    la      r0, label_next
    la      r1, labels
    str     r1, [r0]
    la      r0, scopes                  @ the page is the outermost scope
    str     r7, [r0]
    la      r0, scope_depth
    mov     r1, #1
    str     r1, [r0]
    mov     r0, r7
    bl      run_placed
    add     r8, r8, #1
    cmp     r8, #3
    bne     1b
2:  bl      write_output
    mov     r0, #0
    b       exit

@ The errors of loading (kept here, next to _start and parse_node, as in
@ ttpc.s, where they had to be within branch reach).
usage:
    la      r1, msg_usage
    mov     r2, #msg_usage_len
    b       die
open_failed:
    la      r1, msg_open
    mov     r2, #msg_open_len
    b       die
read_failed:
    la      r1, msg_read
    mov     r2, #msg_read_len
    b       die
too_large:
    la      r1, msg_large
    mov     r2, #msg_large_len
    b       die
truncated:
    la      r1, msg_truncated
    mov     r2, #msg_truncated_len
    b       die
trailing:
    la      r1, msg_trailing
    mov     r2, #msg_trailing_len
    b       die

@ parse_node: reads the node at r8 into a new NODE, recursing on its
@ children, and leaves r8 just past it. Returns the NODE in r0.
parse_node:
    push    {r4, r5, r6, lr}
    @ r4 this NODE, r5 next slot in its children array, r6 children left
    @ to parse

    add     r0, r8, #33                 @ hash + children_len
    cmp     r0, r9
    bhi     truncated
    mov     r4, r10
    add     r10, r10, #NODE_size

    mov     r1, #32                     @ copy the hash
    mov     r2, r4
1:  ldrb    r3, [r8]
    strb    r3, [r2, #NODE_hash]
    add     r8, r8, #1
    add     r2, r2, #1
    subs    r1, r1, #1
    bne     1b

    ldrb    r6, [r8]
    add     r8, r8, #1
    strb    r6, [r4, #NODE_children_len]
    mov     r5, r11
    str     r5, [r4, #NODE_children]
    add     r11, r11, r6, lsl #3
2:  cmp     r6, #0
    beq     3f
    bl      parse_node
    str     r0, [r5]
    add     r5, r5, #8
    sub     r6, r6, #1
    b       2b

3:  cmp     r8, r9
    bhs     truncated
    ldrb    r0, [r8]
    add     r8, r8, #1
    strb    r0, [r4, #NODE_content_len]
    str     r8, [r4, #NODE_content]
    add     r8, r8, r0
    cmp     r8, r9
    bhi     truncated

    mov     r0, r4
    pop     {r4, r5, r6, pc}

@ print_node: prints NODE r0 at depth r1 as "<hash[0..4] in hex>  <indent>
@ <content>", then its children one level deeper.
print_node:
    push    {r4, r5, r6, r7, r8, lr}
    @ r4 this NODE, r5 depth, r6 counter, r7 next child pointer
    mov     r4, r0
    mov     r5, r1

    la      r0, hexbuf
    la      r1, hexdigits
    mov     r2, #4
    mov     r3, r4
1:  ldrb    r12, [r3, #NODE_hash]
    lsr     lr, r12, #4
    ldrb    lr, [r1, lr]
    strb    lr, [r0]
    and     r12, r12, #15
    ldrb    r12, [r1, r12]
    strb    r12, [r0, #1]
    add     r0, r0, #2
    add     r3, r3, #1
    subs    r2, r2, #1
    bne     1b
    la      r1, hexbuf
    mov     r2, #10
    bl      write_out

    mov     r6, r5
2:  cmp     r6, #0
    beq     3f
    la      r1, indent
    mov     r2, #2
    bl      write_out
    sub     r6, r6, #1
    b       2b

3:  ldr     r1, [r4, #NODE_content]
    ldrb    r2, [r4, #NODE_content_len]
    bl      write_out
    la      r1, newline
    mov     r2, #1
    bl      write_out

    ldrb    r6, [r4, #NODE_children_len]
    ldr     r7, [r4, #NODE_children]
4:  cmp     r6, #0
    beq     5f
    ldr     r0, [r7]
    add     r1, r5, #1
    bl      print_node
    add     r7, r7, #8
    sub     r6, r6, #1
    b       4b

5:  pop     {r4, r5, r6, r7, r8, pc}

@ ---------------------------------------------------------------------------
@ Names
@ ---------------------------------------------------------------------------

@ streq: r0 = 1 when the r1 bytes at r0 equal the r3 bytes at r2, else 0.
streq:
    cmp     r1, r3
    bne     2f
1:  cmp     r1, #0
    beq     3f
    ldrb    r3, [r0]
    ldrb    r12, [r2]
    cmp     r3, r12
    bne     2f
    add     r0, r0, #1
    add     r2, r2, #1
    sub     r1, r1, #1
    b       1b
2:  mov     r0, #0
    bx      lr
3:  mov     r0, #1
    bx      lr

@ is_fn: r0 = 1 when NODE r0 is a function (its content ends in ':'), else 0.
is_fn:
    ldrb    r1, [r0, #NODE_content_len]
    cmp     r1, #0
    beq     1f
    ldr     r2, [r0, #NODE_content]
    add     r2, r2, r1
    ldrb    r2, [r2, #-1]
    cmp     r2, #CH_colon
    moveq   r0, #1
    movne   r0, #0
    bx      lr
1:  mov     r0, #0
    bx      lr

@ param_count: r0 = the number of parameters of function NODE r0: its
@ leading children that are leaves and no function.
param_count:
    push    {r4, r5, r6, lr}
    @ r4 children left, r5 next child, r6 count
    ldrb    r4, [r0, #NODE_children_len]
    ldr     r5, [r0, #NODE_children]
    mov     r6, #0
1:  cmp     r4, #0
    beq     2f
    ldr     r0, [r5]
    ldrb    r1, [r0, #NODE_children_len]
    cmp     r1, #0
    bne     2f
    bl      is_fn
    cmp     r0, #0
    bne     2f
    add     r6, r6, #1
    add     r5, r5, #8
    sub     r4, r4, #1
    b       1b
2:  mov     r0, r6
    pop     {r4, r5, r6, pc}

@ is_insn: r0 = 1 when function NODE r0 is an encoding (an instruction or
@ a data word), else 0: its body, the children after its parameters, is not
@ empty and holds only fields, fixed fields (functions) and slice calls (a
@ '[' in the name).
is_insn:
    push    {r4, r5, r6, lr}
    @ r4 fields left, r5 next field, r6 the function
    mov     r6, r0
    bl      param_count
    ldrb    r4, [r6, #NODE_children_len]
    sub     r4, r4, r0
    ldr     r5, [r6, #NODE_children]
    add     r5, r5, r0, lsl #3
    mov     r0, #0
    cmp     r4, #0
    beq     3f
1:  mov     r0, #1
    cmp     r4, #0
    beq     3f
    ldr     r0, [r5]
    bl      is_fn
    cmp     r0, #0
    bne     2f
    ldr     r1, [r5]
    ldr     r0, [r1, #NODE_content]
    ldrb    r1, [r1, #NODE_content_len]
    mov     r2, #CH_lbracket
    bl      has_byte
    cmp     r0, #0
    beq     3f
2:  add     r5, r5, #8
    sub     r4, r4, #1
    b       1b
3:  pop     {r4, r5, r6, pc}

@ has_byte: r0 = 1 when byte r2 is among the r1 bytes at r0, else 0.
has_byte:
1:  cmp     r1, #0
    beq     2f
    ldrb    r3, [r0]
    cmp     r3, r2
    beq     3f
    add     r0, r0, #1
    sub     r1, r1, #1
    b       1b
2:  mov     r0, #0
    bx      lr
3:  mov     r0, #1
    bx      lr

@ collect_syms: stores every function among the children of the pages of
@ root r0 in syms, but for the last page: the program, it is placed.
collect_syms:
    push    {r4, r5, r6, r7, r8, lr}
    @ r4 pages left, r5 next page, r6 next free slot in syms, r7 children
    @ of the page left, r8 next child
    ldrb    r4, [r0, #NODE_children_len]
    ldr     r5, [r0, #NODE_children]
    la      r6, syms
    cmp     r4, #0
    beq     4f
    sub     r4, r4, #1                  @ not the last page: it is placed
1:  cmp     r4, #0
    beq     4f
    ldr     r0, [r5]
    ldrb    r7, [r0, #NODE_children_len]
    ldr     r8, [r0, #NODE_children]
2:  cmp     r7, #0
    beq     3f
    ldr     r0, [r8]
    bl      is_fn
    cmp     r0, #0
    beq     5f
    ldr     r0, [r8]
    str     r0, [r6]
    add     r6, r6, #8
5:  add     r8, r8, #8
    sub     r7, r7, #1
    b       2b
3:  add     r5, r5, #8
    sub     r4, r4, #1
    b       1b
4:  la      r0, syms_end
    str     r6, [r0]
    pop     {r4, r5, r6, r7, r8, pc}

@ find_fn: r0 = the function named by the r1 bytes at r0 (its content
@ without the ':'), or 0.
find_fn:
    push    {r4, r5, r6, r7, r8, lr}
    @ r4 next sym, r5 end of syms, r6 name, r7 name length
    mov     r6, r0
    mov     r7, r1
    la      r4, syms
    la      r5, syms_end
    ldr     r5, [r5]
1:  mov     r0, #0
    cmp     r4, r5
    beq     2f
    ldr     r12, [r4]
    ldr     r2, [r12, #NODE_content]
    ldrb    r3, [r12, #NODE_content_len]
    sub     r3, r3, #1
    mov     r0, r6
    mov     r1, r7
    bl      streq
    add     r4, r4, #8
    cmp     r0, #0
    beq     1b
    ldr     r0, [r4, #-8]
2:  pop     {r4, r5, r6, r7, r8, pc}

@ find_reg: r0:r1 = the number of the register named by the r1 bytes at r0,
@ or -1. A register is a function of two words, "x10 a0:", either one is
@ its name; its number is the bits of its child (64 bits, see parse_bits).
find_reg:
    push    {r4-r12, lr}
    @ r4 next sym, r5 end of syms, r6 name, r7 name length, r8 the sym,
    @ r9 its content, r10 its length without the ':', r11 length of its
    @ first word (r12 only keeps sp 8-byte aligned)
    mov     r6, r0
    mov     r7, r1
    la      r4, syms
    la      r5, syms_end
    ldr     r5, [r5]
1:  cmp     r4, r5
    beq     5f
    ldr     r8, [r4]
    add     r4, r4, #8
    ldrb    r0, [r8, #NODE_children_len]
    cmp     r0, #0
    beq     1b
    ldr     r9, [r8, #NODE_content]
    ldrb    r10, [r8, #NODE_content_len]
    sub     r10, r10, #1
    mov     r11, #0                     @ find the space
2:  cmp     r11, r10
    beq     1b
    ldrb    r0, [r9, r11]
    cmp     r0, #CH_space
    beq     3f
    add     r11, r11, #1
    b       2b
3:  mov     r0, r6
    mov     r1, r7
    mov     r2, r9
    mov     r3, r11
    bl      streq
    cmp     r0, #0
    bne     4f
    mov     r0, r6
    mov     r1, r7
    add     r2, r9, r11
    add     r2, r2, #1
    sub     r3, r10, r11
    sub     r3, r3, #1
    bl      streq
    cmp     r0, #0
    beq     1b
4:  ldr     r0, [r8, #NODE_children]
    ldr     r0, [r0]
    ldrb    r1, [r0, #NODE_content_len]
    ldr     r0, [r0, #NODE_content]
    bl      parse_bits
    b       6f
5:  mvn     r0, #0
    mvn     r1, #0
6:  pop     {r4-r12, pc}

@ ---------------------------------------------------------------------------
@ Numbers
@ ---------------------------------------------------------------------------

@ parse_bits: r0:r1 = the r1 binary digits at r0 ("0010011") as a number.
@ As in ttpc.s, each byte less '0' is a 64-bit signed digit, or'ed in.
parse_bits:
    mov     r2, #0                      @ the number, lo
    mov     r3, #0                      @ and hi
1:  cmp     r1, #0
    beq     2f
    ldrb    r12, [r0]
    sub     r12, r12, #CH_zero
    adds    r2, r2, r2                  @ << 1
    adc     r3, r3, r3
    orr     r2, r2, r12
    orr     r3, r3, r12, asr #31        @ the digit's sign extension
    add     r0, r0, #1
    sub     r1, r1, #1
    b       1b
2:  mov     r0, r2
    mov     r1, r3
    bx      lr

@ parse_dec: reads the decimal digits from r0 up to at most r1; r0:r1 =
@ their value (mod 2^64), r2 = just past them.
parse_dec:
    push    {r4, r5, r6, lr}
    @ r4:r5 the value, r6 10
    mov     r4, #0
    mov     r5, #0
    mov     r6, #10
1:  cmp     r0, r1
    beq     2f
    ldrb    r3, [r0]
    sub     r3, r3, #CH_zero
    cmp     r3, #10
    bhs     2f
    umull   r2, r12, r4, r6             @ value * 10
    mla     r5, r5, r6, r12
    adds    r4, r2, r3                  @ + digit
    adc     r5, r5, #0
    add     r0, r0, #1
    b       1b
2:  mov     r2, r0
    mov     r0, r4
    mov     r1, r5
    pop     {r4, r5, r6, pc}

@ parse_hex: reads the hex digits (0-9, a-f) from r0 up to at most r1;
@ r0:r1 = their value (mod 2^64), r2 = just past them.
parse_hex:
    mov     r2, #0                      @ the value, lo
    mov     r3, #0                      @ and hi
1:  cmp     r0, r1
    beq     3f
    ldrb    r12, [r0]
    sub     r12, r12, #CH_zero
    cmp     r12, #10
    blo     2f
    sub     r12, r12, #CH_a - CH_zero
    cmp     r12, #6
    bhs     3f
    add     r12, r12, #10
2:  lsl     r3, r3, #4                  @ << 4
    orr     r3, r3, r2, lsr #28
    orr     r2, r12, r2, lsl #4
    add     r0, r0, #1
    b       1b
3:  mov     r12, r0
    mov     r0, r2
    mov     r1, r3
    mov     r2, r12
    bx      lr

@ parse_num: r0:r1 = the r1 bytes at r0 as a number, decimal or 0x hex,
@ with an optional '-', and r2 = 1; or r2 = 0 when they are no number.
parse_num:
    push    {r4, r5, r6, lr}
    @ r4 negative?, r5 first digit, r6 end
    add     r1, r0, r1
    mov     r6, r1
    mov     r4, #0
    cmp     r0, r1
    beq     2f
    ldrb    r2, [r0]
    cmp     r2, #CH_minus
    bne     1f
    mov     r4, #1
    add     r0, r0, #1
1:  mov     r5, r0
    sub     r2, r1, r0                  @ 0x and a digit at least?
    cmp     r2, #3
    blt     5f
    ldrb    r2, [r0]
    cmp     r2, #CH_zero
    bne     5f
    ldrb    r2, [r0, #1]
    cmp     r2, #CH_x
    bne     5f
    add     r0, r0, #2
    add     r5, r5, #2
    bl      parse_hex
    b       6f
5:  bl      parse_dec
6:  cmp     r2, r5                      @ no digits
    beq     2f
    cmp     r2, r6                      @ something after them
    bne     2f
    cmp     r4, #0
    beq     3f
    rsbs    r0, r0, #0                  @ neg
    rsc     r1, r1, #0
3:  mov     r2, #1
    b       4f
2:  mov     r2, #0
4:  pop     {r4, r5, r6, pc}

@ slice_width: r0:r1 = the width of the slice named by the r1 bytes at r0:
@ the sum of hi-lo+1 over the segments of "imm[20|10:1|11|19:12]", in 64
@ bits.
slice_width:
    push    {r4-r10, lr}
    sub     sp, sp, #8
    @ r4 cursor, r5 end, r6 name, r7 name length, r8:r9 width; 0(sp): hi
    mov     r6, r0
    mov     r7, r1
    mov     r4, r0
    add     r5, r0, r1
    mov     r8, #0
    mov     r9, #0
1:  cmp     r4, r5                      @ skip to just past the '['
    beq     9f
    ldrb    r0, [r4]
    add     r4, r4, #1
    cmp     r0, #CH_lbracket
    bne     1b
2:  mov     r0, r4                      @ a segment: hi or hi:lo
    mov     r1, r5
    bl      parse_dec
    cmp     r2, r4
    beq     9f
    mov     r4, r2
    adds    r8, r8, #1
    adc     r9, r9, #0
    cmp     r4, r5
    beq     9f
    ldrb    r2, [r4]
    cmp     r2, #CH_colon
    bne     3f
    strd    r0, r1, [sp]                @ hi
    add     r4, r4, #1
    mov     r0, r4
    mov     r1, r5
    bl      parse_dec
    cmp     r2, r4
    beq     9f
    mov     r4, r2
    ldrd    r2, r3, [sp]
    subs    r2, r2, r0
    sbc     r3, r3, r1
    adds    r8, r8, r2
    adc     r9, r9, r3
    cmp     r4, r5
    beq     9f
    ldrb    r2, [r4]
3:  add     r4, r4, #1
    cmp     r2, #CH_bar
    beq     2b
    cmp     r2, #CH_rbracket
    bne     9f
    cmp     r4, r5
    bne     9f
    mov     r0, r8
    mov     r1, r9
    add     sp, sp, #8
    pop     {r4-r10, pc}
9:  la      r1, msg_slice
    mov     r2, #msg_slice_len
    mov     r3, r6
    mov     r12, r7
    b       die_name

@ ---------------------------------------------------------------------------
@ 64-bit values: what RV64 does in one instruction. Value in r0:r1, result
@ in r0:r1; they touch only r0-r3 and r12. (A register-specified LSL or LSR
@ by 32 to 255 gives 0, ASR by 32 to 255 the sign.)
@ ---------------------------------------------------------------------------

@ sll64: r0:r1 <<= r2 mod 64.
sll64:
    and     r2, r2, #63
    lsl     r1, r1, r2
    sub     r3, r2, #32                 @ n >= 32: lo << (n - 32)
    orr     r1, r1, r0, lsl r3
    rsb     r3, r2, #32                 @ n < 32: lo >> (32 - n)
    orr     r1, r1, r0, lsr r3
    lsl     r0, r0, r2
    bx      lr

@ srl64: r0:r1 >>= r2 mod 64, logical.
srl64:
    and     r2, r2, #63
    lsr     r0, r0, r2
    sub     r3, r2, #32                 @ n >= 32: hi >> (n - 32)
    orr     r0, r0, r1, lsr r3
    rsb     r3, r2, #32                 @ n < 32: hi << (32 - n)
    orr     r0, r0, r1, lsl r3
    lsr     r1, r1, r2
    bx      lr

@ sra64: r0:r1 >>= r2 mod 64, arithmetic.
sra64:
    and     r2, r2, #63
    lsr     r0, r0, r2
    rsb     r3, r2, #32                 @ n < 32: hi << (32 - n)
    orr     r0, r0, r1, lsl r3
    subs    r3, r2, #32                 @ n >= 32: hi >> (n - 32), signed
    orrpl   r0, r0, r1, asr r3
    asr     r1, r1, r2
    bx      lr

@ mul64: r0:r1 = the low 64 bits of r0:r1 * r2:r3.
mul64:
    mul     r12, r0, r3                 @ lo * hi'
    mla     r12, r1, r2, r12            @ + hi * lo'
    umull   r0, r1, r0, r2              @ lo * lo'
    add     r1, r1, r12
    bx      lr

@ remu64: r0:r1 = r0:r1 mod r2:r3, unsigned; r0:r1 when r2:r3 is 0, as
@ remu. Keeps r2:r3. Restoring division, one bit at a time.
remu64:
    orrs    r12, r2, r3
    bxeq    lr
    push    {r4, r5, r6, lr}
    mov     r4, #0                      @ the remainder
    mov     r5, #0
    mov     r6, #64
1:  adds    r0, r0, r0                  @ remainder:dividend <<= 1
    adcs    r1, r1, r1
    adcs    r4, r4, r4
    adcs    r5, r5, r5
    bcs     2f                          @ past 64 bits: surely >= divisor
    cmp     r4, r2
    sbcs    r12, r5, r3
    bcc     3f
2:  subs    r4, r4, r2
    sbc     r5, r5, r3
3:  subs    r6, r6, #1
    bne     1b
    mov     r0, r4
    mov     r1, r5
    pop     {r4, r5, r6, pc}

@ ---------------------------------------------------------------------------
@ Calls
@ ---------------------------------------------------------------------------

@ frame_lookup: looks up the parameter named by the r2 bytes at r1 in frame
@ r0 (0: none). r0 = 1 and r2:r3 = its value when found, else r0 = 0.
frame_lookup:
    push    {r4, r5, r6, r7, r8, lr}
    @ r4 pairs left, r5 next pair, r6 name, r7 name length
    cmp     r0, #0
    beq     2f
    mov     r6, r1
    mov     r7, r2
    ldr     r4, [r0, #FRAME_count]
    add     r5, r0, #FRAME_params
1:  cmp     r4, #0
    beq     2f
    ldr     r12, [r5]
    ldr     r2, [r12, #NODE_content]
    ldrb    r3, [r12, #NODE_content_len]
    mov     r0, r6
    mov     r1, r7
    bl      streq
    cmp     r0, #0
    bne     3f
    add     r5, r5, #16
    sub     r4, r4, #1
    b       1b
2:  mov     r0, #0
    b       4f
3:  ldrd    r2, r3, [r5, #8]
4:  pop     {r4, r5, r6, r7, r8, pc}

@ eval_arg: r0:r1 = the value of argument NODE r1 in frame r0, in context
@ r2 (0 code, 1 exec). An argument with children is a call that runs in
@ exec context, its value is what it leaves in a0. A leaf is, in this order:
@ a decimal or 0x number, a parameter, a register (its number in code
@ context, its vreg in exec context), pc (the address being assembled), a
@ label (its address) or a constant (a function without parameters, run in
@ exec context).
eval_arg:
    push    {r4-r10, lr}
    @ r4 frame, r5 the argument, r6 context, r7 its name, r8 name length,
    @ r9 a function of that name
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    ldrb    r0, [r5, #NODE_children_len]
    cmp     r0, #0
    beq     1f
    mov     r0, r5                      @ a call
    mov     r1, r4
    bl      exec_call
    b       7f
1:  ldr     r7, [r5, #NODE_content]
    ldrb    r8, [r5, #NODE_content_len]
    mov     r0, r7
    mov     r1, r8
    bl      parse_num
    cmp     r2, #0
    bne     9f
    mov     r0, r4
    mov     r1, r7
    mov     r2, r8
    bl      frame_lookup
    cmp     r0, #0
    beq     2f
    mov     r0, r2
    mov     r1, r3
    b       9f
2:  mov     r0, r7
    mov     r1, r8
    bl      find_reg
    cmp     r1, #0                      @ bltz
    blt     3f
    cmp     r6, #0
    beq     9f
    la      r2, vregs
    add     r2, r2, r0, lsl #3
    ldrd    r0, r1, [r2]
    b       9f
3:  mov     r0, r7
    mov     r1, r8
    la      r2, str_pc
    mov     r3, #2
    bl      streq
    cmp     r0, #0
    beq     4f
    la      r2, cur_pc
    ldrd    r0, r1, [r2]
    b       9f
4:  mov     r0, r7
    mov     r1, r8
    bl      find_label
    cmp     r0, #0
    beq     5f
    bl      label_addr
    b       9f
5:  mov     r0, r7
    mov     r1, r8
    bl      find_fn
    cmp     r0, #0
    beq     8f
    mov     r9, r0
    bl      is_insn
    cmp     r0, #0
    bne     8f
    mov     r0, r9
    bl      param_count
    cmp     r0, #0
    bne     8f
    mov     r0, r5                      @ a constant
    mov     r1, r4
    bl      exec_call
7:  la      r2, vregs
    ldrd    r0, r1, [r2, #VREG_a0*8]
9:  pop     {r4-r10, pc}
8:  la      r1, msg_name
    mov     r2, #msg_name_len
    mov     r3, r7
    mov     r12, r8
    b       die_name

@ bind: fills frame r12 for call r1 of function r0: each parameter with the
@ value of its argument, evaluated in frame r2 and context r3.
bind:
    push    {r4-r10, lr}
    @ r4 next parameter, r5 next argument, r6 caller's frame, r7 context,
    @ r8 next pair in the new frame, r9 parameters left
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    mov     r8, r12
    bl      param_count
    mov     r9, r0
    ldrb    r0, [r5, #NODE_children_len]
    la      r1, msg_args
    mov     r2, #msg_args_len
    cmp     r0, r9
    bne     3f
    la      r1, msg_params
    mov     r2, #msg_params_len
    cmp     r9, #MAX_PARAMS
    bhi     3f
    mov     r0, r9
    mov     r1, #0
    strd    r0, r1, [r8, #FRAME_count]
    add     r8, r8, #FRAME_params
    ldr     r4, [r4, #NODE_children]
    ldr     r5, [r5, #NODE_children]
1:  cmp     r9, #0
    beq     2f
    ldr     r0, [r4]
    mov     r1, #0
    strd    r0, r1, [r8]
    mov     r0, r6
    ldr     r1, [r5]
    mov     r2, r7
    bl      eval_arg
    strd    r0, r1, [r8, #8]
    add     r4, r4, #8
    add     r5, r5, #8
    add     r8, r8, #16
    sub     r9, r9, #1
    b       1b
2:  pop     {r4-r10, pc}
3:  ldr     r3, [r5, #NODE_content]
    ldrb    r12, [r5, #NODE_content_len]
    b       die_name

@ run_body: calls r2 (code_call or exec_call) with frame r1 on each child
@ of NODE r0 from child r3 on, skipping the functions (definitions).
run_body:
    push    {r4, r5, r6, r7, r8, lr}
    @ r4 children left, r5 next child, r6 frame, r7 handler
    ldrb    r4, [r0, #NODE_children_len]
    sub     r4, r4, r3
    ldr     r5, [r0, #NODE_children]
    add     r5, r5, r3, lsl #3
    mov     r6, r1
    mov     r7, r2
1:  cmp     r4, #0
    beq     3f
    ldr     r0, [r5]
    bl      is_fn
    cmp     r0, #0
    bne     2f
    ldr     r0, [r5]
    mov     r1, r6
    blx     r7
2:  add     r5, r5, #8
    sub     r4, r4, #1
    b       1b
3:  pop     {r4, r5, r6, r7, r8, pc}

@ ---------------------------------------------------------------------------
@ Labels
@ ---------------------------------------------------------------------------

@ run_placed: runs the children of NODE r0, the program page or a placed
@ function, in order: a function is placed, a call runs in code context.
run_placed:
    push    {r4, r5, r6, lr}
    @ r4 children left, r5 next child
    ldrb    r4, [r0, #NODE_children_len]
    ldr     r5, [r0, #NODE_children]
1:  cmp     r4, #0
    beq     4f
    ldr     r0, [r5]
    bl      is_fn
    cmp     r0, #0
    beq     2f
    ldr     r0, [r5]
    bl      place
    b       3f
2:  ldr     r0, [r5]
    mov     r1, #0                      @ no frame: placed code has no parameters
    bl      code_call
3:  add     r5, r5, #8
    sub     r4, r4, #1
    b       1b
4:  pop     {r4, r5, r6, pc}

@ place: places function r0 at cur_pc. Pass 1 adds it to labels, pass 2
@ checks that it is still there; then its children run in its scope, and
@ its end is recorded.
place:
    push    {r4, r5, r6, lr}
    @ r4 the function, r5 its LABEL
    mov     r4, r0
    la      r0, scope_depth             @ push its scope
    ldr     r1, [r0]
    cmp     r1, #MAX_DEPTH
    beq     3f
    la      r2, scopes
    str     r4, [r2, r1, lsl #3]
    add     r1, r1, #1
    str     r1, [r0]
    la      r2, cur_pc
    ldrd    r2, r3, [r2]                @ cur_pc (t4 of ttpc.s)
    la      r0, pass
    ldr     r0, [r0]
    cmp     r0, #1
    bne     1f
    la      r0, labels_end              @ pass 1: a new label
    ldr     r5, [r0]
    add     r1, r5, #LABEL_size
    str     r1, [r0]
    str     r4, [r5, #LABEL_node]
    strd    r2, r3, [r5, #LABEL_addr]
    b       2f
1:  la      r0, label_next              @ pass 2: the same, at the same place
    ldr     r5, [r0]
    add     r1, r5, #LABEL_size
    str     r1, [r0]
    ldr     r1, [r5, #LABEL_node]
    cmp     r1, r4
    bne     4f
    ldrd    r0, r1, [r5, #LABEL_addr]
    cmp     r0, r2
    cmpeq   r1, r3
    bne     4f
2:  mov     r0, r4
    bl      run_placed
    la      r0, cur_pc
    ldrd    r0, r1, [r0]
    strd    r0, r1, [r5, #LABEL_end]
    la      r0, scope_depth
    ldr     r1, [r0]
    sub     r1, r1, #1
    str     r1, [r0]
    pop     {r4, r5, r6, pc}
3:  la      r1, msg_depth
    mov     r2, #msg_depth_len
    b       5f
4:  la      r1, msg_moved
    mov     r2, #msg_moved_len
5:  ldr     r3, [r4, #NODE_content]
    ldrb    r12, [r4, #NODE_content_len]
    b       die_name

@ find_label: r0 = the placed function named by the r1 bytes at r0, or 0:
@ among the functions in the innermost scope first, then outward to the
@ program page.
find_label:
    push    {r4, r5, r6, r7, r8, lr}
    @ r4 name, r5 name length, r6 just past the scope being searched, r7
    @ its children left, r8 next child
    mov     r4, r0
    mov     r5, r1
    la      r0, scope_depth
    ldr     r0, [r0]
    la      r6, scopes
    add     r6, r6, r0, lsl #3
1:  la      r0, scopes
    cmp     r6, r0
    beq     4f
    sub     r6, r6, #8
    ldr     r0, [r6]
    ldrb    r7, [r0, #NODE_children_len]
    ldr     r8, [r0, #NODE_children]
2:  cmp     r7, #0
    beq     1b
    ldr     r0, [r8]
    bl      is_fn
    cmp     r0, #0
    beq     3f
    ldr     r12, [r8]
    ldr     r2, [r12, #NODE_content]
    ldrb    r3, [r12, #NODE_content_len]
    sub     r3, r3, #1
    mov     r0, r4
    mov     r1, r5
    bl      streq
    cmp     r0, #0
    beq     3f
    ldr     r0, [r8]
    b       5f
3:  add     r8, r8, #8
    sub     r7, r7, #1
    b       2b
4:  mov     r0, #0
5:  pop     {r4, r5, r6, r7, r8, pc}

@ label_entry: r0 = the LABEL of placed function r0, or 0 when pass 1 has
@ not met it yet.
label_entry:
    la      r1, labels
    la      r2, labels_end
    ldr     r2, [r2]
1:  cmp     r1, r2
    beq     2f
    ldr     r3, [r1, #LABEL_node]
    cmp     r3, r0
    beq     3f
    add     r1, r1, #LABEL_size
    b       1b
2:  mov     r0, #0
    bx      lr
3:  mov     r0, r1
    bx      lr

@ label_addr: r0:r1 = the address of placed function r0 (0 when pass 1 has
@ not met it yet).
label_addr:
    push    {r4, lr}
    bl      label_entry
    mov     r1, #0
    cmp     r0, #0
    beq     1f
    ldrd    r0, r1, [r0, #LABEL_addr]
1:  pop     {r4, pc}

@ lookup_call: r0 = the function that call r0 calls; dies when unknown.
lookup_call:
    push    {r4, lr}
    @ r4 the call
    mov     r4, r0
    ldr     r0, [r4, #NODE_content]
    ldrb    r1, [r4, #NODE_content_len]
    bl      find_fn
    cmp     r0, #0
    beq     1f
    pop     {r4, pc}
1:  la      r1, msg_function
    mov     r2, #msg_function_len
    ldr     r3, [r4, #NODE_content]
    ldrb    r12, [r4, #NODE_content_len]
    b       die_name

    .equ CALL_frame, 32                 @ the new frame on the stack
    .equ CALL_stack, (CALL_frame + FRAME_size + 15) & ~15

@ code_call: runs call r0 in code context, in frame r1: an instruction is
@ encoded and emitted, any other function expands its body. The builtins:
@   ascii <bytes>   emits the content of its argument as it is
@   align n         pads with zeros up to a multiple of n
@   reserve n       n zero bytes
@   origin n        the address of what follows
@   bss             from here on align and reserve only move the address
code_call:
    sub     sp, sp, #CALL_stack
    str     lr, [sp, #0]
    str     r4, [sp, #8]                @ the call
    str     r5, [sp, #16]               @ caller's frame
    str     r6, [sp, #24]               @ the function
    mov     r4, r0
    mov     r5, r1
    la      r1, str_ascii
    mov     r2, #5
    bl      is_named
    cmp     r0, #0
    bne     3f
    mov     r0, r4
    la      r1, str_align
    mov     r2, #5
    bl      is_named
    cmp     r0, #0
    bne     4f
    mov     r0, r4
    la      r1, str_reserve
    mov     r2, #7
    bl      is_named
    cmp     r0, #0
    bne     5f
    mov     r0, r4
    la      r1, str_origin
    mov     r2, #6
    bl      is_named
    cmp     r0, #0
    bne     6f
    mov     r0, r4
    la      r1, str_bss
    mov     r2, #3
    bl      is_named
    cmp     r0, #0
    bne     7f
    mov     r0, r4
    bl      lookup_call
    mov     r6, r0
    mov     r1, r4
    mov     r2, r5
    mov     r3, #0
    add     r12, sp, #CALL_frame
    bl      bind
    mov     r0, r6
    bl      is_insn
    cmp     r0, #0
    beq     1f
    mov     r0, r6
    add     r1, sp, #CALL_frame
    bl      encode
    mov     r3, r4
    bl      emit
    b       2f
1:  mov     r0, r6
    bl      param_count
    mov     r3, r0
    mov     r0, r6
    add     r1, sp, #CALL_frame
    la      r2, code_call
    bl      run_body
2:  ldr     lr, [sp, #0]
    ldr     r4, [sp, #8]
    ldr     r5, [sp, #16]
    ldr     r6, [sp, #24]
    add     sp, sp, #CALL_stack
    bx      lr
3:  ldrb    r0, [r4, #NODE_children_len] @ ascii
    cmp     r0, #1
    bne     wrong_args
    ldr     r0, [r4, #NODE_children]
    ldr     r0, [r0]
    ldrb    r1, [r0, #NODE_content_len]
    ldr     r0, [r0, #NODE_content]
    bl      emit_raw
    b       2b
4:  mov     r0, r4                      @ align
    mov     r1, r5
    bl      one_arg
    mov     r2, r0                      @ n
    mov     r3, r1
    la      r0, cur_pc
    ldrd    r0, r1, [r0]
    bl      remu64                      @ cur_pc mod n, n kept in r2:r3
    orrs    r12, r0, r1
    beq     2b
    subs    r0, r2, r0
    sbc     r1, r3, r1
    bl      skip
    b       2b
5:  mov     r0, r4                      @ reserve
    mov     r1, r5
    bl      one_arg
    bl      skip
    b       2b
6:  mov     r0, r4                      @ origin
    mov     r1, r5
    bl      one_arg
    la      r2, cur_pc
    strd    r0, r1, [r2]
    b       2b
7:  ldrb    r0, [r4, #NODE_children_len] @ bss
    cmp     r0, #0
    bne     wrong_args
    la      r0, in_bss
    mov     r1, #1
    str     r1, [r0]
    b       2b

@ wrong_args: dies about call r4 having the wrong number of arguments.
wrong_args:
    la      r1, msg_args
    mov     r2, #msg_args_len
    ldr     r3, [r4, #NODE_content]
    ldrb    r12, [r4, #NODE_content_len]
    b       die_name

@ one_arg: r0:r1 = the value of the one argument of builtin call r0, in
@ frame r1 and code context.
one_arg:
    push    {r4, lr}
    @ r4 the call
    mov     r4, r0
    ldrb    r0, [r4, #NODE_children_len]
    cmp     r0, #1
    bne     wrong_args
    mov     r0, r1
    ldr     r1, [r4, #NODE_children]
    ldr     r1, [r1]
    mov     r2, #0
    bl      eval_arg
    pop     {r4, pc}

@ is_named: r0 = 1 when the content of NODE r0 is the r2 bytes at r1.
is_named:
    mov     r3, r2
    mov     r2, r1
    ldrb    r1, [r0, #NODE_content_len]
    ldr     r0, [r0, #NODE_content]
    b       streq

@ exec_call: runs call r0 in exec context, in frame r1: an instruction is
@ executed on vregs, any other function runs its body. The builtin
@ size <label> leaves the size of the label in a0.
exec_call:
    sub     sp, sp, #CALL_stack
    str     lr, [sp, #0]
    str     r4, [sp, #8]                @ the call
    str     r5, [sp, #16]               @ caller's frame
    str     r6, [sp, #24]               @ the function
    mov     r4, r0
    mov     r5, r1
    la      r1, str_size
    mov     r2, #4
    bl      is_named
    cmp     r0, #0
    bne     3f
    mov     r0, r4
    bl      lookup_call
    mov     r6, r0
    bl      is_insn
    cmp     r0, #0
    beq     1f
    mov     r0, r6
    mov     r1, r4
    mov     r2, r5
    bl      execute
    b       2f
1:  mov     r0, r6
    mov     r1, r4
    mov     r2, r5
    mov     r3, #1
    add     r12, sp, #CALL_frame
    bl      bind
    mov     r0, r6
    bl      param_count
    mov     r3, r0
    mov     r0, r6
    add     r1, sp, #CALL_frame
    la      r2, exec_call
    bl      run_body
2:  ldr     lr, [sp, #0]
    ldr     r4, [sp, #8]
    ldr     r5, [sp, #16]
    ldr     r6, [sp, #24]
    add     sp, sp, #CALL_stack
    bx      lr
3:  ldrb    r0, [r4, #NODE_children_len] @ size
    cmp     r0, #1
    bne     wrong_args
    ldr     r0, [r4, #NODE_children]
    ldr     r6, [r0]                    @ the label
    ldr     r0, [r6, #NODE_content]
    ldrb    r1, [r6, #NODE_content_len]
    bl      find_label
    cmp     r0, #0
    beq     5f
    bl      label_entry
    mov     r2, #0                      @ not met yet in pass 1
    mov     r3, #0
    cmp     r0, #0
    beq     4f
    ldrd    r2, r3, [r0, #LABEL_end]
    ldrd    r0, r1, [r0, #LABEL_addr]
    subs    r2, r2, r0
    sbc     r3, r3, r1
4:  la      r1, vregs
    strd    r2, r3, [r1, #VREG_a0*8]
    b       2b
5:  la      r1, msg_name
    mov     r2, #msg_name_len
    ldr     r3, [r6, #NODE_content]
    ldrb    r12, [r6, #NODE_content_len]
    b       die_name

@ execute: executes call r1 of instruction r0 in frame r2, on vregs: the
@ parameter rd names the destination register, the other two give the
@ values v0 and v1 in parameter order, and rd = v1 op v0, op found by name
@ in exec_ops (the seed).
execute:
    sub     sp, sp, #96
    str     lr, [sp, #0]
    str     r4, [sp, #8]                @ the call
    str     r5, [sp, #16]               @ frame
    str     r6, [sp, #24]               @ next parameter
    str     r7, [sp, #32]               @ next argument
    str     r8, [sp, #40]               @ parameters left
    str     r9, [sp, #48]               @ destination register, lo
    str     r10, [sp, #56]              @ values so far
    @ 64(sp), 72(sp): v0, v1
    str     r11, [sp, #80]              @ destination register, hi
    mov     r4, r1
    mov     r5, r2
    mov     r6, r0
    bl      param_count
    mov     r8, r0
    ldrb    r0, [r4, #NODE_children_len]
    cmp     r0, r8
    bne     8f
    ldr     r6, [r6, #NODE_children]
    ldr     r7, [r4, #NODE_children]
    mov     r9, #0
    mov     r11, #0
    mov     r10, #0
1:  cmp     r8, #0
    beq     3f
    ldr     r12, [r6]
    ldr     r0, [r12, #NODE_content]
    ldrb    r1, [r12, #NODE_content_len]
    la      r2, str_rd
    mov     r3, #2
    bl      streq
    cmp     r0, #0
    beq     2f
    ldr     r12, [r7]                   @ rd: a register name
    ldr     r0, [r12, #NODE_content]
    ldrb    r1, [r12, #NODE_content_len]
    bl      find_reg
    cmp     r1, #0                      @ bltz
    blt     7f
    mov     r9, r0
    mov     r11, r1
    b       6f
2:  cmp     r10, #2
    beq     9f                          @ more than two values: no seed op
    mov     r0, r5
    ldr     r1, [r7]
    mov     r2, #1
    bl      eval_arg
    add     r12, sp, r10, lsl #3
    strd    r0, r1, [r12, #64]
    add     r10, r10, #1
6:  add     r6, r6, #8
    add     r7, r7, #8
    sub     r8, r8, #1
    b       1b
3:  cmp     r10, #2
    bne     9f
    ldr     r6, [r4, #NODE_content]     @ find the op by name
    ldrb    r7, [r4, #NODE_content_len]
    cmp     r7, #8
    bhi     9f
    la      r8, exec_ops
10: la      r0, exec_ops_end
    cmp     r8, r0
    beq     9f
    mov     r0, r6
    mov     r1, r7
    mov     r2, r8
    mov     r3, r7
    bl      streq
    cmp     r0, #0
    beq     11f
    cmp     r7, #8                      @ and the op's name ends there
    beq     12f
    ldrb    r0, [r8, r7]
    cmp     r0, #0
    beq     12f
11: add     r8, r8, #OP_size
    b       10b
12: ldrd    r2, r3, [sp, #64]           @ v0
    ldrd    r0, r1, [sp, #72]           @ v1
    ldr     r12, [r8, #OP_code]
    bx      r12
7:  la      r1, msg_register
    mov     r2, #msg_register_len
    ldr     r12, [r7]
    ldr     r3, [r12, #NODE_content]
    ldrb    r12, [r12, #NODE_content_len]
    b       die_name
8:  b       wrong_args
9:  la      r1, msg_execute
    mov     r2, #msg_execute_len
    ldr     r3, [r4, #NODE_content]
    ldrb    r12, [r4, #NODE_content_len]
    b       die_name

@ The ops of exec_ops: r0:r1 = v1 (r0:r1) op v0 (r2:r3), then exec_store,
@ still in the frame of execute.
op_add:
    adds    r0, r0, r2
    adc     r1, r1, r3
    b       exec_store
op_sub:
    subs    r0, r0, r2
    sbc     r1, r1, r3
    b       exec_store
op_and:
    and     r0, r0, r2
    and     r1, r1, r3
    b       exec_store
op_or:
    orr     r0, r0, r2
    orr     r1, r1, r3
    b       exec_store
op_xor:
    eor     r0, r0, r2
    eor     r1, r1, r3
    b       exec_store
op_sll:
    bl      sll64
    b       exec_store
op_srl:
    bl      srl64
    b       exec_store
op_sra:
    bl      sra64
    b       exec_store
op_mul:
    bl      mul64
@ exec_store: stores r0:r1 in the destination vreg r9 (r11 its high word)
@ and returns from execute.
exec_store:
    orrs    r12, r9, r11                @ x0 stays 0
    beq     1f
    la      r12, vregs
    add     r12, r12, r9, lsl #3
    strd    r0, r1, [r12]
1:  ldr     lr, [sp, #0]
    ldr     r4, [sp, #8]
    ldr     r5, [sp, #16]
    ldr     r6, [sp, #24]
    ldr     r7, [sp, #32]
    ldr     r8, [sp, #40]
    ldr     r9, [sp, #48]
    ldr     r10, [sp, #56]
    ldr     r11, [sp, #80]
    add     sp, sp, #96
    bx      lr

@ ---------------------------------------------------------------------------
@ Encoding and output
@ ---------------------------------------------------------------------------

@ encode: encodes instruction r0, its parameters bound in frame r1: r0:r1 =
@ the word, r2 = its width in bits (8, 16, 32 or 64). The fields come MSB
@ first: word = word << width | value.
encode:
    sub     sp, sp, #96
    str     lr, [sp, #0]
    str     r4, [sp, #8]                @ the instruction
    str     r5, [sp, #16]               @ frame
    str     r6, [sp, #24]               @ fields left
    str     r7, [sp, #32]               @ next field
    str     r8, [sp, #40]               @ word, lo (r8:r9)
    str     r9, [sp, #48]               @ word, hi
    str     r10, [sp, #56]              @ width so far, lo (r10:r11)
    str     r11, [sp, #64]              @ width so far, hi
    @ 72(sp): width of this field (s10), 64 bits; 80(sp): its value
    mov     r4, r0
    mov     r5, r1
    bl      param_count
    ldrb    r6, [r4, #NODE_children_len]
    sub     r6, r6, r0
    ldr     r7, [r4, #NODE_children]
    add     r7, r7, r0, lsl #3
    mov     r8, #0
    mov     r9, #0
    mov     r10, #0
    mov     r11, #0
1:  cmp     r6, #0
    beq     4f
    ldr     r0, [r7]
    bl      is_fn
    ldr     r12, [r7]
    cmp     r0, #0
    beq     2f
    ldrb    r1, [r12, #NODE_children_len] @ a fixed field: its child is its bits
    cmp     r1, #0
    beq     8f
    ldr     r1, [r12, #NODE_children]
    ldr     r1, [r1]
    ldr     r0, [r1, #NODE_content]
    ldrb    r2, [r1, #NODE_content_len]
    mov     r3, #0
    strd    r2, r3, [sp, #72]
    mov     r1, r2
    bl      parse_bits
    b       3f
2:  mov     r0, r12                     @ a slice call: run it, value in a0
    mov     r1, r5
    bl      exec_call
    ldr     r12, [r7]
    ldr     r0, [r12, #NODE_content]
    ldrb    r1, [r12, #NODE_content_len]
    bl      slice_width
    strd    r0, r1, [sp, #72]
    la      r2, vregs
    ldrd    r0, r1, [r2, #VREG_a0*8]
3:  ldrd    r2, r3, [sp, #72]
    cmp     r2, #64
    cmpeq   r3, #0
    beq     10f                         @ a 64-bit field is the whole word
    strd    r0, r1, [sp, #80]
    mov     r0, #1                      @ value &= (1 << width) - 1
    mov     r1, #0
    bl      sll64
    subs    r0, r0, #1
    sbc     r1, r1, #0
    ldrd    r2, r3, [sp, #80]
    and     r2, r2, r0
    and     r3, r3, r1
    strd    r2, r3, [sp, #80]
    mov     r0, r8                      @ word <<= width
    mov     r1, r9
    ldr     r2, [sp, #72]
    bl      sll64
    mov     r8, r0
    mov     r9, r1
    ldrd    r0, r1, [sp, #80]
10: orr     r8, r8, r0
    orr     r9, r9, r1
    ldrd    r2, r3, [sp, #72]
    adds    r10, r10, r2
    adc     r11, r11, r3
    add     r7, r7, #8
    sub     r6, r6, #1
    b       1b
4:  cmp     r11, #0
    bne     9f
    cmp     r10, #8
    cmpne   r10, #16
    cmpne   r10, #32
    cmpne   r10, #64
    bne     9f
5:  mov     r0, r8
    mov     r1, r9
    mov     r2, r10
    ldr     lr, [sp, #0]
    ldr     r4, [sp, #8]
    ldr     r5, [sp, #16]
    ldr     r6, [sp, #24]
    ldr     r7, [sp, #32]
    ldr     r8, [sp, #40]
    ldr     r9, [sp, #48]
    ldr     r10, [sp, #56]
    ldr     r11, [sp, #64]
    add     sp, sp, #96
    bx      lr
8:  la      r1, msg_field
    mov     r2, #msg_field_len
    ldr     r3, [r12, #NODE_content]
    ldrb    r12, [r12, #NODE_content_len]
    b       die_name
9:  la      r1, msg_width
    mov     r2, #msg_width_len
    ldr     r3, [r4, #NODE_content]
    ldrb    r12, [r4, #NODE_content_len]
    b       die_name

@ emit: emits the r2-bit word r0:r1, little endian, and in pass 2 prints it
@ as "<hex>  <name of call r3>".
emit:
    push    {r4-r10, lr}
    sub     sp, sp, #8
    @ r4:r5 word, r6 width, r7 the call; r8 next byte of linebuf, r9 hex
    @ digits left, r10 shift of the next one; 0(sp): the word in memory
    mov     r4, r0
    mov     r5, r1
    mov     r6, r2
    mov     r7, r3
    strd    r4, r5, [sp]
    mov     r0, sp
    lsr     r1, r6, #3
    bl      emit_raw
    la      r0, pass
    ldr     r0, [r0]
    cmp     r0, #2
    bne     5f
    la      r8, linebuf
    lsr     r9, r6, #2                  @ hex digits
    sub     r10, r6, #4                 @ shift of the next one
3:  cmp     r9, #0
    beq     4f
    mov     r0, r4
    mov     r1, r5
    mov     r2, r10
    bl      srl64
    and     r0, r0, #15
    la      r1, hexdigits
    ldrb    r0, [r1, r0]
    strb    r0, [r8]
    add     r8, r8, #1
    sub     r10, r10, #4
    sub     r9, r9, #1
    b       3b
4:  mov     r0, #CH_space
    strb    r0, [r8]
    strb    r0, [r8, #1]
    add     r8, r8, #2
    la      r1, linebuf
    sub     r2, r8, r1
    bl      write_out
    ldr     r1, [r7, #NODE_content]
    ldrb    r2, [r7, #NODE_content_len]
    bl      write_out
    la      r1, newline
    mov     r2, #1
    bl      write_out
5:  add     sp, sp, #8
    pop     {r4-r10, pc}

@ emit_raw: appends the r1 bytes at r0 to outbuf and moves cur_pc past
@ them.
emit_raw:
    push    {r4, lr}
    la      r2, in_bss
    ldr     r2, [r2]
    cmp     r2, #0
    bne     emitted_in_bss
    la      r4, out_end
    ldr     r2, [r4]
    la      r3, outbuf
    add     r3, r3, #OUT_SIZE
    add     r12, r2, r1
    cmp     r12, r3
    bhi     out_full
    la      r3, cur_pc
    ldr     r12, [r3]
    adds    r12, r12, r1
    str     r12, [r3]
    ldr     r12, [r3, #4]
    adc     r12, r12, #0
    str     r12, [r3, #4]
1:  cmp     r1, #0
    beq     2f
    ldrb    r3, [r0]
    strb    r3, [r2]
    add     r0, r0, #1
    add     r2, r2, #1
    sub     r1, r1, #1
    b       1b
2:  str     r2, [r4]
    pop     {r4, pc}

@ skip: moves cur_pc r0:r1 bytes on: by emitting zero bytes, or after bss
@ only the address.
skip:
    push    {r4, r5, r6, lr}
    @ r4:r5 bytes left
    mov     r4, r0
    mov     r5, r1
    la      r0, in_bss
    ldr     r0, [r0]
    cmp     r0, #0
    beq     1f
    la      r0, cur_pc
    ldrd    r2, r3, [r0]
    adds    r2, r2, r4
    adc     r3, r3, r5
    strd    r2, r3, [r0]
    b       2f
1:  orrs    r0, r4, r5
    beq     2f
    la      r0, zero_byte
    mov     r1, #1
    bl      emit_raw
    subs    r4, r4, #1
    sbc     r5, r5, #0
    b       1b
2:  pop     {r4, r5, r6, pc}

@ write_output: writes outbuf, everything emitted, to the file out_path.
write_output:
    push    {r4, r5, r7, lr}
    @ r4 fd
    mov     r0, #AT_FDCWD
    la      r1, out_path
    ldr     r1, [r1]
    movw    r2, #O_CREAT_WRONLY_TRUNC
    movw    r3, #MODE_0755
    movw    r7, #SYS_openat
    svc     #0
    cmp     r0, #0
    blt     create_failed
    mov     r4, r0
    la      r1, outbuf
    la      r0, out_end
    ldr     r2, [r0]
    sub     r2, r2, r1
    mov     r0, r4
    bl      write_all
    mov     r0, r4
    mov     r7, #SYS_close
    svc     #0
    pop     {r4, r5, r7, pc}

@ write_all: writes the r2 bytes at r1 to fd r0, however many writes it
@ takes.
write_all:
    push    {r7, lr}
    mov     r3, r0
1:  cmp     r2, #0
    beq     2f
    mov     r0, r3
    mov     r7, #SYS_write
    svc     #0
    cmp     r0, #0
    ble     write_failed
    add     r1, r1, r0
    sub     r2, r2, r0
    b       1b
2:  pop     {r7, pc}

@ write_out: writes r2 bytes at r1 to stdout.
write_out:
    push    {r7, lr}
    mov     r0, #STDOUT
    mov     r7, #SYS_write
    svc     #0
    pop     {r7, pc}

create_failed:
    la      r1, msg_create
    mov     r2, #msg_create_len
    b       die
write_failed:
    la      r1, msg_write
    mov     r2, #msg_write_len
    b       die
out_full:
    la      r1, msg_full
    mov     r2, #msg_full_len
    b       die
emitted_in_bss:
    la      r1, msg_bss
    mov     r2, #msg_bss_len
    b       die

@ die_name: writes the r2-byte message at r1 and the r12-byte name at r3 to
@ stderr, then a newline, and exits with status 1.
die_name:
    mov     r4, r3
    mov     r5, r12
    mov     r0, #STDERR
    mov     r7, #SYS_write
    svc     #0
    mov     r0, #STDERR
    mov     r1, r4
    mov     r2, r5
    mov     r7, #SYS_write
    svc     #0
    la      r1, newline
    mov     r2, #1

@ die: writes the r2-byte message at r1 to stderr and exits with status 1.
die:
    mov     r0, #STDERR
    mov     r7, #SYS_write
    svc     #0
    mov     r0, #1
exit:
    mov     r7, #SYS_exit
    svc     #0
