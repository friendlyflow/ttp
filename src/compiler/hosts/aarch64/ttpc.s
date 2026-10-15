// ttpc.s (aarch64) — the trust project compiler, in AArch64 assembly,
// without libc.
//
// FROZEN: this is a port of ../../ttpc.s, stage0 of the bootstrap (see
// PLAN.md), from riscv64 to aarch64. It must agree with ttpc.s byte for
// byte: for every input the same stdout, the same stderr, the same output
// file and the same exit status. It is a translation, function by function
// and nearly instruction by instruction, in the same order, with the same
// labels, constants, messages, memory layout and exec_ops table, so that it
// can be audited side by side with ttpc.s. It interprets the tree like
// ttpc.s does: the ISA it assembles for comes from the tree, and exec
// context runs on vregs through exec_ops, never on the host.
//
// One deliberate difference: OUT_SIZE is 1 << 20 (1 MiB) instead of
// 1 << 16, so that it can write a larger ttpc for this host. An output
// between 64 KiB and 1 MiB makes ttpc.s die with "output too large", this
// port writes it.
//
// Register map, RISC-V -> AArch64:
//   s0-s9  x19-x28     s10  x29     s11  x18
//   a0-a6  x0-x6       a7   x8      (only ever the syscall number)
//   t0-t6  x9-x15      ra   x30     sp   sp      zero  xzr
// Without libc x29 (no frame pointer chain) and x18 (no platform use) are
// plain registers; like s10 and s11 they are saved by the functions that
// use them. x7, x16 and x17 are unused. Every frame of ttpc.s is already a
// multiple of 16 bytes, so sp stays 16-byte aligned with the same offsets.
//
// Instruction map: ld/sd -> ldr/str, lbu -> ldrb (zero-extends), sb -> strb,
// li/mv -> mov, la -> the macro la below (adrp + add :lo12:), call -> bl,
// j -> b, jalr -> blr, jr -> br, ecall -> svc #0 (number in x8, arguments
// in x0-x5, result in x0). A compare-and-branch is cmp + b.cond: beq/bne
// -> b.eq/b.ne, blt/bge/bgt and bltz/blez -> b.lt/b.ge/b.gt/b.le (signed),
// bltu/bgeu/bgtu -> b.lo/b.hs/b.hi (unsigned); beqz/bnez -> cbz/cbnz. remu
// -> udiv + msub (x mod 0 is x on both). The exec ops: add sub and orr eor
// mul are 64 bits like RV64 (mul keeps the low 64), lsl lsr asr by a
// register take the amount mod 64 like sll srl sra.
//
// What follows is the comment of ttpc.s:
//
// A static Linux program (here aarch64; run it with qemu-aarch64 on another
// host). It talks to the kernel only through svc: it opens the ff file
// named by its first argument and loads it into memory as a tree of NODEs.
//
//   ttpc <file.ff>          prints the tree, one node per line
//   ttpc <file.ff> <out>    assembles it into the static executable <out>
//
// Assembling: a node whose content ends in ':' is a function, its leading
// children that are leaves are its parameters. Any other node is a call, its
// children are the arguments. The root's children are pages. The functions
// on every page but the last are definitions: instructions, macros,
// constants. The last page is the program: its functions are placed, they
// are labels whose children are emitted where they stand (nested ones are
// local labels, found innermost scope first), and its calls are emitted in
// order. Pass 1 finds every label's address, pass 2 emits.
//
// A function whose body (the children after its parameters) holds only
// fields, fixed fields (funct3:, ...) and slice calls (imm[11:0] imm), is an
// encoding: an instruction or a data word of 8 to 64 bits. A call runs in
// one of three contexts:
//
//   code   a call of an encoding is encoded and emitted, a call of any
//          other function expands its body in code context.
//   field  encoding: the fields, MSB first. A fixed field is its bits; a
//          slice call runs in exec context and leaves its value in a0, its
//          width is in its name.
//   exec   runs at assemble time on vregs. The ops of exec_ops are built
//          in, the seed; everything else is defined by the tree.
//
// An argument with children is a call, run in exec context: its value is
// a0. A leaf argument is a decimal or 0x number, a parameter, a register
// (its number in code context, its vreg in exec context), pc, a label (its
// address) or a constant (a function without parameters, run in exec
// context). The builtins: ascii, align, reserve, origin, bss (see
// code_call) and size (see exec_call).
//
// Registers are the functions "x10 a0:", their number is their child "01010".
// (These are the registers of the target in the tree, not of this host; a0
// is the vreg VREG_a0.) The output file is exactly what the program emits:
// its ELF header is ff too (elf_header in macros.ff.txt).
//
// ff on disk, one node, depth-first (children inline, before the content):
//   hash          byte[32]
//   children_len  u8
//   children      node × children_len
//   content_len   u8
//   content       byte × content_len    // no NUL termination: may be binary
//
// NODE in memory (64 bytes, naturally aligned):
//   0   hash          byte[32]
//   32  children_len  int8
//   40  children      NODE**            // -> pointer array in ptrs
//   48  content_len   int8
//   56  content       char*             // -> into buf, not copied

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
    .equ CH_a, 97
    .equ CH_x, 120

    // A frame binds the parameters of a call: count, then (param NODE*,
    // value) pairs.
    .equ MAX_PARAMS, 8
    .equ FRAME_count, 0
    .equ FRAME_params, 8
    .equ FRAME_size, 8 + MAX_PARAMS * 16

    .equ VREG_a0, 10
    .equ OUT_SIZE, 1 << 20              // ttpc.s: 1 << 16, see the header
    .equ MAX_DEPTH, 64                  // nesting of placed functions

    // A label: a placed function, its address and the address after it.
    .equ LABEL_node, 0
    .equ LABEL_addr, 8
    .equ LABEL_end, 16
    .equ LABEL_size, 24

    // An exec op: its name, NUL-padded, and its code.
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
    // Every node takes at least 34 bytes on disk, so a full buf holds fewer
    // than MAX_NODES nodes: the node and pointer arenas cannot overflow.
    .equ MAX_NODES, BUF_SIZE / 32

// la: reg = the address of sym, as RISC-V's la.
    .macro la reg, sym
    adrp    \reg, \sym
    add     \reg, \reg, :lo12:\sym
    .endm

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
// Followed by the name they are about:
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
hexbuf:         .ascii "00000000  "         // hash prefix of a printed line
    .balign 8
out_path:       .dword 0                    // argv[2], 0 when only printing
out_end:        .dword outbuf               // next free byte in outbuf
syms_end:       .dword syms                 // next free slot in syms
labels_end:     .dword labels               // next free LABEL (pass 1)
label_next:     .dword labels               // next LABEL to check (pass 2)
pass:           .dword 0                    // 1 or 2
cur_pc:         .dword 0                    // address of the next byte
in_bss:         .dword 0                    // 1 after the builtin bss
scope_depth:    .dword 0                    // placed functions in scopes

// The exec seed: the instructions that exec context runs itself, rd = v1 op
// v0, with v0 and v1 the other operands in parameter order (rs2 rs1, or imm
// rs1, or shamt rs1).
exec_ops:
    .ascii "add\0\0\0\0\0"
    .dword op_add
    .ascii "addi\0\0\0\0"
    .dword op_add
    .ascii "sub\0\0\0\0\0"
    .dword op_sub
    .ascii "and\0\0\0\0\0"
    .dword op_and
    .ascii "andi\0\0\0\0"
    .dword op_and
    .ascii "or\0\0\0\0\0\0"
    .dword op_or
    .ascii "ori\0\0\0\0\0"
    .dword op_or
    .ascii "xor\0\0\0\0\0"
    .dword op_xor
    .ascii "xori\0\0\0\0"
    .dword op_xor
    .ascii "sll\0\0\0\0\0"
    .dword op_sll
    .ascii "slli\0\0\0\0"
    .dword op_sll
    .ascii "srl\0\0\0\0\0"
    .dword op_srl
    .ascii "srli\0\0\0\0"
    .dword op_srl
    .ascii "sra\0\0\0\0\0"
    .dword op_sra
    .ascii "srai\0\0\0\0"
    .dword op_sra
    .ascii "mul\0\0\0\0\0"
    .dword op_mul
exec_ops_end:

    .section .bss
    .balign 8
nodes:          .skip MAX_NODES * NODE_size
ptrs:           .skip MAX_NODES * 8
syms:           .skip MAX_NODES * 8         // the function NODEs, see collect_syms
labels:         .skip MAX_NODES * LABEL_size
scopes:         .skip MAX_DEPTH * 8         // the placed functions around pc
vregs:          .skip 32 * 8                // the registers of exec context
linebuf:        .skip 24                    // hex of an emitted word
outbuf:         .skip OUT_SIZE
buf:            .skip BUF_SIZE

// Registers that live across the whole program:
//   x19 (s0)  parse cursor in buf
//   x20 (s1)  end of the loaded bytes
//   x21 (s2)  next free NODE in nodes
//   x22 (s3)  next free slot in ptrs

    .section .text
    .globl _start
_start:
    ldr     x9, [sp, #0]                // argc
    cmp     x9, #2
    b.lt    usage
    cmp     x9, #3
    b.gt    usage
    b.lt    1f
    ldr     x10, [sp, #24]              // argv[2]
    la      x11, out_path
    str     x10, [x11, #0]
1:  ldr     x1, [sp, #16]               // argv[1]

    mov     x0, #AT_FDCWD
    mov     x2, #O_RDONLY
    mov     x3, #0
    mov     x8, #SYS_openat
    svc     #0
    cmp     x0, #0
    b.lt    open_failed
    mov     x23, x0                     // fd

    // Read the whole file into buf.
    la      x19, buf
    mov     x20, x19
    mov     x9, #BUF_SIZE
    add     x24, x19, x9                // end of buf
read_loop:
    cmp     x20, x24
    b.eq    too_large
    mov     x0, x23
    mov     x1, x20
    sub     x2, x24, x20
    mov     x8, #SYS_read
    svc     #0
    cmp     x0, #0
    b.lt    read_failed
    cbz     x0, read_done
    add     x20, x20, x0
    b       read_loop
read_done:
    mov     x0, x23
    mov     x8, #SYS_close
    svc     #0

    la      x21, nodes
    la      x22, ptrs
    bl      parse_node
    cmp     x19, x20
    b.ne    trailing
    la      x9, out_path
    ldr     x9, [x9, #0]
    cbnz    x9, assemble
    mov     x1, #0
    bl      print_node

    mov     x0, #0
    b       exit

// assemble: places the last page of root x0, the program, twice: pass 1
// finds the address of every label, pass 2 emits with them. Then writes
// the output file.
assemble:
    mov     x25, x0                     // root
    bl      collect_syms
    ldrb    w9, [x25, #NODE_children_len]
    cbz     x9, 2f
    ldr     x10, [x25, #NODE_children]
    lsl     x9, x9, #3
    add     x10, x10, x9
    ldr     x26, [x10, #-8]             // the program page
    mov     x27, #1                     // pass
1:  la      x9, pass
    str     x27, [x9, #0]
    la      x9, cur_pc
    str     xzr, [x9, #0]
    la      x9, in_bss
    str     xzr, [x9, #0]
    la      x9, out_end
    la      x10, outbuf
    str     x10, [x9, #0]
    la      x9, label_next
    la      x10, labels
    str     x10, [x9, #0]
    la      x9, scopes                  // the page is the outermost scope
    str     x26, [x9, #0]
    la      x9, scope_depth
    mov     x10, #1
    str     x10, [x9, #0]
    mov     x0, x26
    bl      run_placed
    add     x27, x27, #1
    cmp     x27, #3
    b.ne    1b
2:  bl      write_output
    mov     x0, #0
    b       exit

// The errors of loading (in ttpc.s within branch reach, 4 KiB, of _start
// and parse_node).
usage:
    la      x1, msg_usage
    mov     x2, #msg_usage_len
    b       die
open_failed:
    la      x1, msg_open
    mov     x2, #msg_open_len
    b       die
read_failed:
    la      x1, msg_read
    mov     x2, #msg_read_len
    b       die
too_large:
    la      x1, msg_large
    mov     x2, #msg_large_len
    b       die
truncated:
    la      x1, msg_truncated
    mov     x2, #msg_truncated_len
    b       die
trailing:
    la      x1, msg_trailing
    mov     x2, #msg_trailing_len
    b       die

// parse_node: reads the node at x19 into a new NODE, recursing on its
// children, and leaves x19 just past it. Returns the NODE in x0.
parse_node:
    sub     sp, sp, #32
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // this NODE
    str     x24, [sp, #16]              // next slot in its children array
    str     x25, [sp, #24]              // children left to parse

    add     x9, x19, #33                // hash + children_len
    cmp     x9, x20
    b.hi    truncated
    mov     x23, x21
    add     x21, x21, #NODE_size

    mov     x10, #32                    // copy the hash
    mov     x11, x23
1:  ldrb    w12, [x19, #0]
    strb    w12, [x11, #NODE_hash]
    add     x19, x19, #1
    add     x11, x11, #1
    sub     x10, x10, #1
    cbnz    x10, 1b

    ldrb    w25, [x19, #0]
    add     x19, x19, #1
    strb    w25, [x23, #NODE_children_len]
    mov     x24, x22
    str     x24, [x23, #NODE_children]
    lsl     x9, x25, #3
    add     x22, x22, x9
2:  cbz     x25, 3f
    bl      parse_node
    str     x0, [x24, #0]
    add     x24, x24, #8
    sub     x25, x25, #1
    b       2b

3:  cmp     x19, x20
    b.hs    truncated
    ldrb    w9, [x19, #0]
    add     x19, x19, #1
    strb    w9, [x23, #NODE_content_len]
    str     x19, [x23, #NODE_content]
    add     x19, x19, x9
    cmp     x19, x20
    b.hi    truncated

    mov     x0, x23
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #32
    ret

// print_node: prints NODE x0 at depth x1 as "<hash[0..4] in hex>  <indent>
// <content>", then its children one level deeper.
print_node:
    sub     sp, sp, #48
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // this NODE
    str     x24, [sp, #16]              // depth
    str     x25, [sp, #24]              // counter
    str     x26, [sp, #32]              // next child pointer
    mov     x23, x0
    mov     x24, x1

    la      x9, hexbuf
    la      x10, hexdigits
    mov     x11, #4
    mov     x12, x23
1:  ldrb    w13, [x12, #NODE_hash]
    lsr     x14, x13, #4
    add     x14, x10, x14
    ldrb    w14, [x14, #0]
    strb    w14, [x9, #0]
    and     x13, x13, #15
    add     x13, x10, x13
    ldrb    w13, [x13, #0]
    strb    w13, [x9, #1]
    add     x9, x9, #2
    add     x12, x12, #1
    sub     x11, x11, #1
    cbnz    x11, 1b
    la      x1, hexbuf
    mov     x2, #10
    bl      write_out

    mov     x25, x24
2:  cbz     x25, 3f
    la      x1, indent
    mov     x2, #2
    bl      write_out
    sub     x25, x25, #1
    b       2b

3:  ldr     x1, [x23, #NODE_content]
    ldrb    w2, [x23, #NODE_content_len]
    bl      write_out
    la      x1, newline
    mov     x2, #1
    bl      write_out

    ldrb    w25, [x23, #NODE_children_len]
    ldr     x26, [x23, #NODE_children]
4:  cbz     x25, 5f
    ldr     x0, [x26, #0]
    add     x1, x24, #1
    bl      print_node
    add     x26, x26, #8
    sub     x25, x25, #1
    b       4b

5:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    add     sp, sp, #48
    ret

// ---------------------------------------------------------------------------
// Names
// ---------------------------------------------------------------------------

// streq: x0 = 1 when the x1 bytes at x0 equal the x3 bytes at x2, else 0.
streq:
    cmp     x1, x3
    b.ne    2f
1:  cbz     x1, 3f
    ldrb    w9, [x0, #0]
    ldrb    w10, [x2, #0]
    cmp     x9, x10
    b.ne    2f
    add     x0, x0, #1
    add     x2, x2, #1
    sub     x1, x1, #1
    b       1b
2:  mov     x0, #0
    ret
3:  mov     x0, #1
    ret

// is_fn: x0 = 1 when NODE x0 is a function (its content ends in ':'), else 0.
is_fn:
    ldrb    w9, [x0, #NODE_content_len]
    cbz     x9, 1f
    ldr     x10, [x0, #NODE_content]
    add     x10, x10, x9
    ldrb    w10, [x10, #-1]
    subs    x10, x10, #CH_colon
    cset    x0, eq                      // seqz
    ret
1:  mov     x0, #0
    ret

// param_count: x0 = the number of parameters of function NODE x0: its
// leading children that are leaves and no function.
param_count:
    sub     sp, sp, #32
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // children left
    str     x24, [sp, #16]              // next child
    str     x25, [sp, #24]              // count
    ldrb    w23, [x0, #NODE_children_len]
    ldr     x24, [x0, #NODE_children]
    mov     x25, #0
1:  cbz     x23, 2f
    ldr     x0, [x24, #0]
    ldrb    w9, [x0, #NODE_children_len]
    cbnz    x9, 2f
    bl      is_fn
    cbnz    x0, 2f
    add     x25, x25, #1
    add     x24, x24, #8
    sub     x23, x23, #1
    b       1b
2:  mov     x0, x25
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #32
    ret

// is_insn: x0 = 1 when function NODE x0 is an encoding (an instruction or
// a data word), else 0: its body, the children after its parameters, is not
// empty and holds only fields, fixed fields (functions) and slice calls (a
// '[' in the name).
is_insn:
    sub     sp, sp, #32
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // fields left
    str     x24, [sp, #16]              // next field
    str     x25, [sp, #24]              // the function
    mov     x25, x0
    bl      param_count
    ldrb    w23, [x25, #NODE_children_len]
    sub     x23, x23, x0
    ldr     x24, [x25, #NODE_children]
    lsl     x0, x0, #3
    add     x24, x24, x0
    mov     x0, #0
    cbz     x23, 3f
1:  mov     x0, #1
    cbz     x23, 3f
    ldr     x0, [x24, #0]
    bl      is_fn
    cbnz    x0, 2f
    ldr     x9, [x24, #0]
    ldr     x0, [x9, #NODE_content]
    ldrb    w1, [x9, #NODE_content_len]
    mov     x2, #CH_lbracket
    bl      has_byte
    cbz     x0, 3f
2:  add     x24, x24, #8
    sub     x23, x23, #1
    b       1b
3:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #32
    ret

// has_byte: x0 = 1 when byte x2 is among the x1 bytes at x0, else 0.
has_byte:
1:  cbz     x1, 2f
    ldrb    w9, [x0, #0]
    cmp     x9, x2
    b.eq    3f
    add     x0, x0, #1
    sub     x1, x1, #1
    b       1b
2:  mov     x0, #0
    ret
3:  mov     x0, #1
    ret

// collect_syms: stores every function among the children of the pages of
// root x0 in syms, but for the last page: the program, it is placed.
collect_syms:
    sub     sp, sp, #64
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // pages left
    str     x24, [sp, #16]              // next page
    str     x25, [sp, #24]              // next free slot in syms
    str     x26, [sp, #32]              // children of the page left
    str     x27, [sp, #40]              // next child
    ldrb    w23, [x0, #NODE_children_len]
    ldr     x24, [x0, #NODE_children]
    la      x25, syms
    cbz     x23, 4f
    sub     x23, x23, #1                // not the last page: it is placed
1:  cbz     x23, 4f
    ldr     x9, [x24, #0]
    ldrb    w26, [x9, #NODE_children_len]
    ldr     x27, [x9, #NODE_children]
2:  cbz     x26, 3f
    ldr     x0, [x27, #0]
    bl      is_fn
    cbz     x0, 5f
    ldr     x9, [x27, #0]
    str     x9, [x25, #0]
    add     x25, x25, #8
5:  add     x27, x27, #8
    sub     x26, x26, #1
    b       2b
3:  add     x24, x24, #8
    sub     x23, x23, #1
    b       1b
4:  la      x9, syms_end
    str     x25, [x9, #0]
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    add     sp, sp, #64
    ret

// find_fn: x0 = the function named by the x1 bytes at x0 (its content
// without the ':'), or 0.
find_fn:
    sub     sp, sp, #48
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // next sym
    str     x24, [sp, #16]              // end of syms
    str     x25, [sp, #24]              // name
    str     x26, [sp, #32]              // name length
    mov     x25, x0
    mov     x26, x1
    la      x23, syms
    la      x24, syms_end
    ldr     x24, [x24, #0]
1:  mov     x0, #0
    cmp     x23, x24
    b.eq    2f
    ldr     x9, [x23, #0]
    ldr     x2, [x9, #NODE_content]
    ldrb    w3, [x9, #NODE_content_len]
    sub     x3, x3, #1
    mov     x0, x25
    mov     x1, x26
    bl      streq
    add     x23, x23, #8
    cbz     x0, 1b
    ldr     x0, [x23, #-8]
2:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    add     sp, sp, #48
    ret

// find_reg: x0 = the number of the register named by the x1 bytes at x0, or
// -1. A register is a function of two words, "x10 a0:", either one is its
// name; its number is the bits of its child.
find_reg:
    sub     sp, sp, #80
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // next sym
    str     x24, [sp, #16]              // end of syms
    str     x25, [sp, #24]              // name
    str     x26, [sp, #32]              // name length
    str     x27, [sp, #40]              // the sym
    str     x28, [sp, #48]              // its content
    str     x29, [sp, #56]              // its length without the ':'
    str     x18, [sp, #64]              // length of its first word
    mov     x25, x0
    mov     x26, x1
    la      x23, syms
    la      x24, syms_end
    ldr     x24, [x24, #0]
1:  cmp     x23, x24
    b.eq    5f
    ldr     x27, [x23, #0]
    add     x23, x23, #8
    ldrb    w9, [x27, #NODE_children_len]
    cbz     x9, 1b
    ldr     x28, [x27, #NODE_content]
    ldrb    w29, [x27, #NODE_content_len]
    sub     x29, x29, #1
    mov     x18, #0                     // find the space
2:  cmp     x18, x29
    b.eq    1b
    add     x9, x28, x18
    ldrb    w9, [x9, #0]
    cmp     x9, #CH_space
    b.eq    3f
    add     x18, x18, #1
    b       2b
3:  mov     x0, x25
    mov     x1, x26
    mov     x2, x28
    mov     x3, x18
    bl      streq
    cbnz    x0, 4f
    mov     x0, x25
    mov     x1, x26
    add     x2, x28, x18
    add     x2, x2, #1
    sub     x3, x29, x18
    sub     x3, x3, #1
    bl      streq
    cbz     x0, 1b
4:  ldr     x9, [x27, #NODE_children]
    ldr     x9, [x9, #0]
    ldr     x0, [x9, #NODE_content]
    ldrb    w1, [x9, #NODE_content_len]
    bl      parse_bits
    b       6f
5:  mov     x0, #-1
6:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    ldr     x28, [sp, #48]
    ldr     x29, [sp, #56]
    ldr     x18, [sp, #64]
    add     sp, sp, #80
    ret

// ---------------------------------------------------------------------------
// Numbers
// ---------------------------------------------------------------------------

// parse_bits: x0 = the x1 binary digits at x0 ("0010011") as a number.
parse_bits:
    mov     x9, #0
1:  cbz     x1, 2f
    ldrb    w10, [x0, #0]
    sub     x10, x10, #CH_zero
    lsl     x9, x9, #1
    orr     x9, x9, x10
    add     x0, x0, #1
    sub     x1, x1, #1
    b       1b
2:  mov     x0, x9
    ret

// parse_dec: reads the decimal digits from x0 up to at most x1; x0 = their
// value, x1 = just past them.
parse_dec:
    mov     x9, #0
    mov     x11, #10
1:  cmp     x0, x1
    b.eq    2f
    ldrb    w10, [x0, #0]
    sub     x10, x10, #CH_zero
    cmp     x10, x11
    b.hs    2f
    mul     x9, x9, x11
    add     x9, x9, x10
    add     x0, x0, #1
    b       1b
2:  mov     x1, x0
    mov     x0, x9
    ret

// parse_hex: reads the hex digits (0-9, a-f) from x0 up to at most x1;
// x0 = their value, x1 = just past them.
parse_hex:
    mov     x9, #0
1:  cmp     x0, x1
    b.eq    3f
    ldrb    w10, [x0, #0]
    sub     x11, x10, #CH_zero
    mov     x12, #10
    cmp     x11, x12
    b.lo    2f
    sub     x11, x10, #CH_a
    mov     x12, #6
    cmp     x11, x12
    b.hs    3f
    add     x11, x11, #10
2:  lsl     x9, x9, #4
    orr     x9, x9, x11
    add     x0, x0, #1
    b       1b
3:  mov     x1, x0
    mov     x0, x9
    ret

// parse_num: x0 = the x1 bytes at x0 as a number, decimal or 0x hex, with
// an optional '-', and x1 = 1; or x1 = 0 when they are no number.
parse_num:
    sub     sp, sp, #32
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // negative?
    str     x24, [sp, #16]              // first digit
    str     x25, [sp, #24]              // end
    add     x1, x0, x1
    mov     x25, x1
    mov     x23, #0
    cmp     x0, x1
    b.eq    2f
    ldrb    w9, [x0, #0]
    cmp     x9, #CH_minus
    b.ne    1f
    mov     x23, #1
    add     x0, x0, #1
1:  mov     x24, x0
    sub     x9, x1, x0                  // 0x and a digit at least?
    cmp     x9, #3
    b.lt    5f
    ldrb    w9, [x0, #0]
    cmp     x9, #CH_zero
    b.ne    5f
    ldrb    w9, [x0, #1]
    cmp     x9, #CH_x
    b.ne    5f
    add     x0, x0, #2
    add     x24, x24, #2
    bl      parse_hex
    b       6f
5:  bl      parse_dec
6:  cmp     x1, x24                     // no digits
    b.eq    2f
    cmp     x1, x25                     // something after them
    b.ne    2f
    cbz     x23, 3f
    neg     x0, x0
3:  mov     x1, #1
    b       4f
2:  mov     x1, #0
4:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #32
    ret

// slice_width: x0 = the width of the slice named by the x1 bytes at x0: the
// sum of hi-lo+1 over the segments of "imm[20|10:1|11|19:12]".
slice_width:
    sub     sp, sp, #64
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // cursor
    str     x24, [sp, #16]              // end
    str     x25, [sp, #24]              // name
    str     x26, [sp, #32]              // name length
    str     x27, [sp, #40]              // width
    mov     x25, x0
    mov     x26, x1
    mov     x23, x0
    add     x24, x0, x1
    mov     x27, #0
1:  cmp     x23, x24                    // skip to just past the '['
    b.eq    9f
    ldrb    w9, [x23, #0]
    add     x23, x23, #1
    cmp     x9, #CH_lbracket
    b.ne    1b
2:  mov     x0, x23                     // a segment: hi or hi:lo
    mov     x1, x24
    bl      parse_dec
    cmp     x1, x23
    b.eq    9f
    mov     x23, x1
    add     x27, x27, #1
    cmp     x23, x24
    b.eq    9f
    ldrb    w9, [x23, #0]
    cmp     x9, #CH_colon
    b.ne    3f
    str     x0, [sp, #48]               // hi
    add     x23, x23, #1
    mov     x0, x23
    mov     x1, x24
    bl      parse_dec
    cmp     x1, x23
    b.eq    9f
    mov     x23, x1
    ldr     x9, [sp, #48]
    sub     x9, x9, x0
    add     x27, x27, x9
    cmp     x23, x24
    b.eq    9f
    ldrb    w9, [x23, #0]
3:  add     x23, x23, #1
    cmp     x9, #CH_bar
    b.eq    2b
    cmp     x9, #CH_rbracket
    b.ne    9f
    cmp     x23, x24
    b.ne    9f
    mov     x0, x27
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    add     sp, sp, #64
    ret
9:  la      x1, msg_slice
    mov     x2, #msg_slice_len
    mov     x3, x25
    mov     x4, x26
    b       die_name

// ---------------------------------------------------------------------------
// Calls
// ---------------------------------------------------------------------------

// frame_lookup: looks up the parameter named by the x2 bytes at x1 in frame
// x0 (0: none). x0 = 1 and x1 = its value when found, else x0 = 0.
frame_lookup:
    sub     sp, sp, #48
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // pairs left
    str     x24, [sp, #16]              // next pair
    str     x25, [sp, #24]              // name
    str     x26, [sp, #32]              // name length
    cbz     x0, 2f
    mov     x25, x1
    mov     x26, x2
    ldr     x23, [x0, #FRAME_count]
    add     x24, x0, #FRAME_params
1:  cbz     x23, 2f
    ldr     x9, [x24, #0]
    ldr     x2, [x9, #NODE_content]
    ldrb    w3, [x9, #NODE_content_len]
    mov     x0, x25
    mov     x1, x26
    bl      streq
    cbnz    x0, 3f
    add     x24, x24, #16
    sub     x23, x23, #1
    b       1b
2:  mov     x0, #0
    b       4f
3:  ldr     x1, [x24, #8]
4:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    add     sp, sp, #48
    ret

// eval_arg: x0 = the value of argument NODE x1 in frame x0, in context x2
// (0 code, 1 exec). An argument with children is a call that runs in exec
// context, its value is what it leaves in a0. A leaf is, in this order: a
// decimal or 0x number, a parameter, a register (its number in code
// context, its vreg in exec context), pc (the address being assembled), a
// label (its address) or a constant (a function without parameters, run in
// exec context).
eval_arg:
    sub     sp, sp, #64
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // frame
    str     x24, [sp, #16]              // the argument
    str     x25, [sp, #24]              // context
    str     x26, [sp, #32]              // its name
    str     x27, [sp, #40]              // name length
    str     x28, [sp, #48]              // a function of that name
    mov     x23, x0
    mov     x24, x1
    mov     x25, x2
    ldrb    w9, [x24, #NODE_children_len]
    cbz     x9, 1f
    mov     x0, x24                     // a call
    mov     x1, x23
    bl      exec_call
    b       7f
1:  ldr     x26, [x24, #NODE_content]
    ldrb    w27, [x24, #NODE_content_len]
    mov     x0, x26
    mov     x1, x27
    bl      parse_num
    cbnz    x1, 9f
    mov     x0, x23
    mov     x1, x26
    mov     x2, x27
    bl      frame_lookup
    cbz     x0, 2f
    mov     x0, x1
    b       9f
2:  mov     x0, x26
    mov     x1, x27
    bl      find_reg
    cmp     x0, #0
    b.lt    3f
    cbz     x25, 9f
    la      x9, vregs
    lsl     x0, x0, #3
    add     x9, x9, x0
    ldr     x0, [x9, #0]
    b       9f
3:  mov     x0, x26
    mov     x1, x27
    la      x2, str_pc
    mov     x3, #2
    bl      streq
    cbz     x0, 4f
    la      x9, cur_pc
    ldr     x0, [x9, #0]
    b       9f
4:  mov     x0, x26
    mov     x1, x27
    bl      find_label
    cbz     x0, 5f
    bl      label_addr
    b       9f
5:  mov     x0, x26
    mov     x1, x27
    bl      find_fn
    cbz     x0, 8f
    mov     x28, x0
    bl      is_insn
    cbnz    x0, 8f
    mov     x0, x28
    bl      param_count
    cbnz    x0, 8f
    mov     x0, x24                     // a constant
    mov     x1, x23
    bl      exec_call
7:  la      x9, vregs
    ldr     x0, [x9, #VREG_a0*8]
9:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    ldr     x28, [sp, #48]
    add     sp, sp, #64
    ret
8:  la      x1, msg_name
    mov     x2, #msg_name_len
    mov     x3, x26
    mov     x4, x27
    b       die_name

// bind: fills frame x4 for call x1 of function x0: each parameter with the
// value of its argument, evaluated in frame x2 and context x3.
bind:
    sub     sp, sp, #64
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // next parameter
    str     x24, [sp, #16]              // next argument
    str     x25, [sp, #24]              // caller's frame
    str     x26, [sp, #32]              // context
    str     x27, [sp, #40]              // next pair in the new frame
    str     x28, [sp, #48]              // parameters left
    mov     x23, x0
    mov     x24, x1
    mov     x25, x2
    mov     x26, x3
    mov     x27, x4
    bl      param_count
    mov     x28, x0
    ldrb    w9, [x24, #NODE_children_len]
    la      x1, msg_args
    mov     x2, #msg_args_len
    cmp     x9, x28
    b.ne    3f
    mov     x9, #MAX_PARAMS
    la      x1, msg_params
    mov     x2, #msg_params_len
    cmp     x28, x9
    b.hi    3f
    str     x28, [x27, #FRAME_count]
    add     x27, x27, #FRAME_params
    ldr     x23, [x23, #NODE_children]
    ldr     x24, [x24, #NODE_children]
1:  cbz     x28, 2f
    ldr     x9, [x23, #0]
    str     x9, [x27, #0]
    mov     x0, x25
    ldr     x1, [x24, #0]
    mov     x2, x26
    bl      eval_arg
    str     x0, [x27, #8]
    add     x23, x23, #8
    add     x24, x24, #8
    add     x27, x27, #16
    sub     x28, x28, #1
    b       1b
2:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    ldr     x28, [sp, #48]
    add     sp, sp, #64
    ret
3:  ldr     x3, [x24, #NODE_content]
    ldrb    w4, [x24, #NODE_content_len]
    b       die_name

// run_body: calls x2 (code_call or exec_call) with frame x1 on each child
// of NODE x0 from child x3 on, skipping the functions (definitions).
run_body:
    sub     sp, sp, #48
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // children left
    str     x24, [sp, #16]              // next child
    str     x25, [sp, #24]              // frame
    str     x26, [sp, #32]              // handler
    ldrb    w23, [x0, #NODE_children_len]
    sub     x23, x23, x3
    ldr     x24, [x0, #NODE_children]
    lsl     x9, x3, #3
    add     x24, x24, x9
    mov     x25, x1
    mov     x26, x2
1:  cbz     x23, 3f
    ldr     x0, [x24, #0]
    bl      is_fn
    cbnz    x0, 2f
    ldr     x0, [x24, #0]
    mov     x1, x25
    blr     x26
2:  add     x24, x24, #8
    sub     x23, x23, #1
    b       1b
3:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    add     sp, sp, #48
    ret

// ---------------------------------------------------------------------------
// Labels
// ---------------------------------------------------------------------------

// run_placed: runs the children of NODE x0, the program page or a placed
// function, in order: a function is placed, a call runs in code context.
run_placed:
    sub     sp, sp, #32
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // children left
    str     x24, [sp, #16]              // next child
    ldrb    w23, [x0, #NODE_children_len]
    ldr     x24, [x0, #NODE_children]
1:  cbz     x23, 4f
    ldr     x0, [x24, #0]
    bl      is_fn
    cbz     x0, 2f
    ldr     x0, [x24, #0]
    bl      place
    b       3f
2:  ldr     x0, [x24, #0]
    mov     x1, #0                      // no frame: placed code has no parameters
    bl      code_call
3:  add     x24, x24, #8
    sub     x23, x23, #1
    b       1b
4:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    add     sp, sp, #32
    ret

// place: places function x0 at cur_pc. Pass 1 adds it to labels, pass 2
// checks that it is still there; then its children run in its scope, and
// its end is recorded.
place:
    sub     sp, sp, #32
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the function
    str     x24, [sp, #16]              // its LABEL
    mov     x23, x0
    la      x9, scope_depth             // push its scope
    ldr     x10, [x9, #0]
    mov     x11, #MAX_DEPTH
    cmp     x10, x11
    b.eq    3f
    la      x11, scopes
    lsl     x12, x10, #3
    add     x11, x11, x12
    str     x23, [x11, #0]
    add     x10, x10, #1
    str     x10, [x9, #0]
    la      x13, cur_pc
    ldr     x13, [x13, #0]
    la      x9, pass
    ldr     x9, [x9, #0]
    mov     x10, #1
    cmp     x9, x10
    b.ne    1f
    la      x9, labels_end              // pass 1: a new label
    ldr     x24, [x9, #0]
    add     x10, x24, #LABEL_size
    str     x10, [x9, #0]
    str     x23, [x24, #LABEL_node]
    str     x13, [x24, #LABEL_addr]
    b       2f
1:  la      x9, label_next              // pass 2: the same, at the same place
    ldr     x24, [x9, #0]
    add     x10, x24, #LABEL_size
    str     x10, [x9, #0]
    ldr     x10, [x24, #LABEL_node]
    cmp     x10, x23
    b.ne    4f
    ldr     x10, [x24, #LABEL_addr]
    cmp     x10, x13
    b.ne    4f
2:  mov     x0, x23
    bl      run_placed
    la      x9, cur_pc
    ldr     x9, [x9, #0]
    str     x9, [x24, #LABEL_end]
    la      x9, scope_depth
    ldr     x10, [x9, #0]
    sub     x10, x10, #1
    str     x10, [x9, #0]
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    add     sp, sp, #32
    ret
3:  la      x1, msg_depth
    mov     x2, #msg_depth_len
    b       5f
4:  la      x1, msg_moved
    mov     x2, #msg_moved_len
5:  ldr     x3, [x23, #NODE_content]
    ldrb    w4, [x23, #NODE_content_len]
    b       die_name

// find_label: x0 = the placed function named by the x1 bytes at x0, or 0:
// among the functions in the innermost scope first, then outward to the
// program page.
find_label:
    sub     sp, sp, #48
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // name
    str     x24, [sp, #16]              // name length
    str     x25, [sp, #24]              // just past the scope being searched
    str     x26, [sp, #32]              // its children left
    str     x27, [sp, #40]              // next child
    mov     x23, x0
    mov     x24, x1
    la      x9, scope_depth
    ldr     x9, [x9, #0]
    lsl     x9, x9, #3
    la      x25, scopes
    add     x25, x25, x9
1:  la      x9, scopes
    cmp     x25, x9
    b.eq    4f
    sub     x25, x25, #8
    ldr     x9, [x25, #0]
    ldrb    w26, [x9, #NODE_children_len]
    ldr     x27, [x9, #NODE_children]
2:  cbz     x26, 1b
    ldr     x0, [x27, #0]
    bl      is_fn
    cbz     x0, 3f
    ldr     x9, [x27, #0]
    ldr     x2, [x9, #NODE_content]
    ldrb    w3, [x9, #NODE_content_len]
    sub     x3, x3, #1
    mov     x0, x23
    mov     x1, x24
    bl      streq
    cbz     x0, 3f
    ldr     x0, [x27, #0]
    b       5f
3:  add     x27, x27, #8
    sub     x26, x26, #1
    b       2b
4:  mov     x0, #0
5:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    add     sp, sp, #48
    ret

// label_entry: x0 = the LABEL of placed function x0, or 0 when pass 1 has
// not met it yet.
label_entry:
    la      x9, labels
    la      x10, labels_end
    ldr     x10, [x10, #0]
1:  cmp     x9, x10
    b.eq    2f
    ldr     x11, [x9, #LABEL_node]
    cmp     x11, x0
    b.eq    3f
    add     x9, x9, #LABEL_size
    b       1b
2:  mov     x0, #0
    ret
3:  mov     x0, x9
    ret

// label_addr: x0 = the address of placed function x0 (0 when pass 1 has
// not met it yet).
label_addr:
    sub     sp, sp, #16
    str     x30, [sp, #0]
    bl      label_entry
    cbz     x0, 1f
    ldr     x0, [x0, #LABEL_addr]
1:  ldr     x30, [sp, #0]
    add     sp, sp, #16
    ret

// lookup_call: x0 = the function that call x0 calls; dies when unknown.
lookup_call:
    sub     sp, sp, #16
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the call
    mov     x23, x0
    ldr     x0, [x23, #NODE_content]
    ldrb    w1, [x23, #NODE_content_len]
    bl      find_fn
    cbz     x0, 1f
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    add     sp, sp, #16
    ret
1:  la      x1, msg_function
    mov     x2, #msg_function_len
    ldr     x3, [x23, #NODE_content]
    ldrb    w4, [x23, #NODE_content_len]
    b       die_name

    .equ CALL_frame, 32                 // the new frame on the stack
    .equ CALL_stack, (CALL_frame + FRAME_size + 15) & ~15

// code_call: runs call x0 in code context, in frame x1: an instruction is
// encoded and emitted, any other function expands its body. The builtins:
//   ascii <bytes>   emits the content of its argument as it is
//   align n         pads with zeros up to a multiple of n
//   reserve n       n zero bytes
//   origin n        the address of what follows
//   bss             from here on align and reserve only move the address
code_call:
    sub     sp, sp, #CALL_stack
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the call
    str     x24, [sp, #16]              // caller's frame
    str     x25, [sp, #24]              // the function
    mov     x23, x0
    mov     x24, x1
    la      x1, str_ascii
    mov     x2, #5
    bl      is_named
    cbnz    x0, 3f
    mov     x0, x23
    la      x1, str_align
    mov     x2, #5
    bl      is_named
    cbnz    x0, 4f
    mov     x0, x23
    la      x1, str_reserve
    mov     x2, #7
    bl      is_named
    cbnz    x0, 5f
    mov     x0, x23
    la      x1, str_origin
    mov     x2, #6
    bl      is_named
    cbnz    x0, 6f
    mov     x0, x23
    la      x1, str_bss
    mov     x2, #3
    bl      is_named
    cbnz    x0, 7f
    mov     x0, x23
    bl      lookup_call
    mov     x25, x0
    mov     x1, x23
    mov     x2, x24
    mov     x3, #0
    add     x4, sp, #CALL_frame
    bl      bind
    mov     x0, x25
    bl      is_insn
    cbz     x0, 1f
    mov     x0, x25
    add     x1, sp, #CALL_frame
    bl      encode
    mov     x2, x23
    bl      emit
    b       2f
1:  mov     x0, x25
    bl      param_count
    mov     x3, x0
    mov     x0, x25
    add     x1, sp, #CALL_frame
    la      x2, code_call
    bl      run_body
2:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #CALL_stack
    ret
3:  ldrb    w9, [x23, #NODE_children_len]   // ascii
    mov     x10, #1
    cmp     x9, x10
    b.ne    wrong_args
    ldr     x9, [x23, #NODE_children]
    ldr     x9, [x9, #0]
    ldr     x0, [x9, #NODE_content]
    ldrb    w1, [x9, #NODE_content_len]
    bl      emit_raw
    b       2b
4:  mov     x0, x23                     // align
    mov     x1, x24
    bl      one_arg
    la      x9, cur_pc
    ldr     x9, [x9, #0]
    udiv    x10, x9, x0                 // remu x10, x9, x0
    msub    x10, x10, x0, x9
    cbz     x10, 2b
    sub     x0, x0, x10
    bl      skip
    b       2b
5:  mov     x0, x23                     // reserve
    mov     x1, x24
    bl      one_arg
    bl      skip
    b       2b
6:  mov     x0, x23                     // origin
    mov     x1, x24
    bl      one_arg
    la      x9, cur_pc
    str     x0, [x9, #0]
    b       2b
7:  ldrb    w9, [x23, #NODE_children_len]   // bss
    cbnz    x9, wrong_args
    la      x9, in_bss
    mov     x10, #1
    str     x10, [x9, #0]
    b       2b

// wrong_args: dies about call x23 having the wrong number of arguments.
wrong_args:
    la      x1, msg_args
    mov     x2, #msg_args_len
    ldr     x3, [x23, #NODE_content]
    ldrb    w4, [x23, #NODE_content_len]
    b       die_name

// one_arg: x0 = the value of the one argument of builtin call x0, in frame
// x1 and code context.
one_arg:
    sub     sp, sp, #16
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the call
    mov     x23, x0
    ldrb    w9, [x23, #NODE_children_len]
    mov     x10, #1
    cmp     x9, x10
    b.ne    wrong_args
    mov     x0, x1
    ldr     x1, [x23, #NODE_children]
    ldr     x1, [x1, #0]
    mov     x2, #0
    bl      eval_arg
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    add     sp, sp, #16
    ret

// is_named: x0 = 1 when the content of NODE x0 is the x2 bytes at x1.
is_named:
    mov     x3, x2
    mov     x2, x1
    ldrb    w1, [x0, #NODE_content_len]
    ldr     x0, [x0, #NODE_content]
    b       streq

// exec_call: runs call x0 in exec context, in frame x1: an instruction is
// executed on vregs, any other function runs its body. The builtin
// size <label> leaves the size of the label in a0.
exec_call:
    sub     sp, sp, #CALL_stack
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the call
    str     x24, [sp, #16]              // caller's frame
    str     x25, [sp, #24]              // the function
    mov     x23, x0
    mov     x24, x1
    la      x1, str_size
    mov     x2, #4
    bl      is_named
    cbnz    x0, 3f
    mov     x0, x23
    bl      lookup_call
    mov     x25, x0
    bl      is_insn
    cbz     x0, 1f
    mov     x0, x25
    mov     x1, x23
    mov     x2, x24
    bl      execute
    b       2f
1:  mov     x0, x25
    mov     x1, x23
    mov     x2, x24
    mov     x3, #1
    add     x4, sp, #CALL_frame
    bl      bind
    mov     x0, x25
    bl      param_count
    mov     x3, x0
    mov     x0, x25
    add     x1, sp, #CALL_frame
    la      x2, exec_call
    bl      run_body
2:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #CALL_stack
    ret
3:  ldrb    w9, [x23, #NODE_children_len]   // size
    mov     x10, #1
    cmp     x9, x10
    b.ne    wrong_args
    ldr     x9, [x23, #NODE_children]
    ldr     x25, [x9, #0]               // the label
    ldr     x0, [x25, #NODE_content]
    ldrb    w1, [x25, #NODE_content_len]
    bl      find_label
    cbz     x0, 5f
    bl      label_entry
    mov     x9, #0                      // not met yet in pass 1
    cbz     x0, 4f
    ldr     x9, [x0, #LABEL_end]
    ldr     x10, [x0, #LABEL_addr]
    sub     x9, x9, x10
4:  la      x10, vregs
    str     x9, [x10, #VREG_a0*8]
    b       2b
5:  la      x1, msg_name
    mov     x2, #msg_name_len
    ldr     x3, [x25, #NODE_content]
    ldrb    w4, [x25, #NODE_content_len]
    b       die_name

// execute: executes call x1 of instruction x0 in frame x2, on vregs: the
// parameter rd names the destination register, the other two give the
// values v0 and v1 in parameter order, and rd = v1 op v0, op found by name
// in exec_ops (the seed).
execute:
    sub     sp, sp, #96
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the call
    str     x24, [sp, #16]              // frame
    str     x25, [sp, #24]              // next parameter
    str     x26, [sp, #32]              // next argument
    str     x27, [sp, #40]              // parameters left
    str     x28, [sp, #48]              // destination register
    str     x29, [sp, #56]              // values so far
    // [sp, #64], [sp, #72]: v0, v1
    mov     x23, x1
    mov     x24, x2
    mov     x25, x0
    bl      param_count
    mov     x27, x0
    ldrb    w9, [x23, #NODE_children_len]
    cmp     x9, x27
    b.ne    8f
    ldr     x25, [x25, #NODE_children]
    ldr     x26, [x23, #NODE_children]
    mov     x28, #0
    mov     x29, #0
1:  cbz     x27, 3f
    ldr     x9, [x25, #0]
    ldr     x0, [x9, #NODE_content]
    ldrb    w1, [x9, #NODE_content_len]
    la      x2, str_rd
    mov     x3, #2
    bl      streq
    cbz     x0, 2f
    ldr     x9, [x26, #0]               // rd: a register name
    ldr     x0, [x9, #NODE_content]
    ldrb    w1, [x9, #NODE_content_len]
    bl      find_reg
    cmp     x0, #0
    b.lt    7f
    mov     x28, x0
    b       6f
2:  mov     x9, #2
    cmp     x29, x9
    b.eq    9f                          // more than two values: no seed op
    mov     x0, x24
    ldr     x1, [x26, #0]
    mov     x2, #1
    bl      eval_arg
    lsl     x9, x29, #3
    add     x9, sp, x9
    str     x0, [x9, #64]
    add     x29, x29, #1
6:  add     x25, x25, #8
    add     x26, x26, #8
    sub     x27, x27, #1
    b       1b
3:  mov     x9, #2
    cmp     x29, x9
    b.ne    9f
    ldr     x25, [x23, #NODE_content]   // find the op by name
    ldrb    w26, [x23, #NODE_content_len]
    mov     x9, #8
    cmp     x26, x9
    b.hi    9f
    la      x27, exec_ops
10: la      x9, exec_ops_end
    cmp     x27, x9
    b.eq    9f
    mov     x0, x25
    mov     x1, x26
    mov     x2, x27
    mov     x3, x26
    bl      streq
    cbz     x0, 11f
    mov     x9, #8                      // and the op's name ends there
    cmp     x26, x9
    b.eq    12f
    add     x9, x27, x26
    ldrb    w9, [x9, #0]
    cbz     x9, 12f
11: add     x27, x27, #OP_size
    b       10b
12: ldr     x9, [sp, #64]
    ldr     x10, [sp, #72]
    ldr     x12, [x27, #OP_code]
    br      x12
7:  la      x1, msg_register
    mov     x2, #msg_register_len
    ldr     x9, [x26, #0]
    ldr     x3, [x9, #NODE_content]
    ldrb    w4, [x9, #NODE_content_len]
    b       die_name
8:  b       wrong_args
9:  la      x1, msg_execute
    mov     x2, #msg_execute_len
    ldr     x3, [x23, #NODE_content]
    ldrb    w4, [x23, #NODE_content_len]
    b       die_name

// The ops of exec_ops: x11 = x10 op x9 (t2 = t1 op t0), then exec_store,
// still in the frame of execute. All 64 bits, as RV64: mul keeps the low
// 64 bits, the shifts take their amount mod 64.
op_add:
    add     x11, x10, x9
    b       exec_store
op_sub:
    sub     x11, x10, x9
    b       exec_store
op_and:
    and     x11, x10, x9
    b       exec_store
op_or:
    orr     x11, x10, x9
    b       exec_store
op_xor:
    eor     x11, x10, x9
    b       exec_store
op_sll:
    lsl     x11, x10, x9
    b       exec_store
op_srl:
    lsr     x11, x10, x9
    b       exec_store
op_sra:
    asr     x11, x10, x9
    b       exec_store
op_mul:
    mul     x11, x10, x9
// exec_store: stores x11 in the destination vreg x28 and returns from
// execute.
exec_store:
    cbz     x28, 1f                     // x0 stays 0
    la      x9, vregs
    lsl     x10, x28, #3
    add     x9, x9, x10
    str     x11, [x9, #0]
1:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    ldr     x28, [sp, #48]
    ldr     x29, [sp, #56]
    add     sp, sp, #96
    ret

// ---------------------------------------------------------------------------
// Encoding and output
// ---------------------------------------------------------------------------

// encode: encodes instruction x0, its parameters bound in frame x1: x0 =
// the word, x1 = its width in bits (8, 16, 32 or 64). The fields come MSB
// first: word = word << width | value.
encode:
    sub     sp, sp, #80
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // the instruction
    str     x24, [sp, #16]              // frame
    str     x25, [sp, #24]              // fields left
    str     x26, [sp, #32]              // next field
    str     x27, [sp, #40]              // word
    str     x28, [sp, #48]              // width so far
    str     x29, [sp, #56]              // width of this field
    mov     x23, x0
    mov     x24, x1
    bl      param_count
    ldrb    w25, [x23, #NODE_children_len]
    sub     x25, x25, x0
    ldr     x26, [x23, #NODE_children]
    lsl     x0, x0, #3
    add     x26, x26, x0
    mov     x27, #0
    mov     x28, #0
1:  cbz     x25, 4f
    ldr     x0, [x26, #0]
    bl      is_fn
    ldr     x9, [x26, #0]
    cbz     x0, 2f
    ldrb    w10, [x9, #NODE_children_len]   // a fixed field: its child is its bits
    cbz     x10, 8f
    ldr     x10, [x9, #NODE_children]
    ldr     x10, [x10, #0]
    ldr     x0, [x10, #NODE_content]
    ldrb    w1, [x10, #NODE_content_len]
    mov     x29, x1
    bl      parse_bits
    b       3f
2:  mov     x0, x9                      // a slice call: run it, value in a0
    mov     x1, x24
    bl      exec_call
    ldr     x9, [x26, #0]
    ldr     x0, [x9, #NODE_content]
    ldrb    w1, [x9, #NODE_content_len]
    bl      slice_width
    mov     x29, x0
    la      x9, vregs
    ldr     x0, [x9, #VREG_a0*8]
3:  mov     x9, #64
    cmp     x29, x9
    b.eq    10f                         // a 64-bit field is the whole word
    mov     x9, #1
    lsl     x9, x9, x29
    sub     x9, x9, #1
    and     x0, x0, x9
    lsl     x27, x27, x29
10: orr     x27, x27, x0
    add     x28, x28, x29
    add     x26, x26, #8
    sub     x25, x25, #1
    b       1b
4:  mov     x9, #8
    cmp     x28, x9
    b.eq    5f
    mov     x9, #16
    cmp     x28, x9
    b.eq    5f
    mov     x9, #32
    cmp     x28, x9
    b.eq    5f
    mov     x9, #64
    cmp     x28, x9
    b.ne    9f
5:  mov     x0, x27
    mov     x1, x28
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    ldr     x26, [sp, #32]
    ldr     x27, [sp, #40]
    ldr     x28, [sp, #48]
    ldr     x29, [sp, #56]
    add     sp, sp, #80
    ret
8:  la      x1, msg_field
    mov     x2, #msg_field_len
    ldr     x3, [x9, #NODE_content]
    ldrb    w4, [x9, #NODE_content_len]
    b       die_name
9:  la      x1, msg_width
    mov     x2, #msg_width_len
    ldr     x3, [x23, #NODE_content]
    ldrb    w4, [x23, #NODE_content_len]
    b       die_name

// emit: emits the x1-bit word x0, little endian, and in pass 2 prints it
// as "<hex>  <name of call x2>".
emit:
    sub     sp, sp, #48
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // word
    str     x24, [sp, #16]              // width
    str     x25, [sp, #24]              // the call
    // [sp, #32]: the word in memory
    mov     x23, x0
    mov     x24, x1
    mov     x25, x2
    str     x23, [sp, #32]
    add     x0, sp, #32
    lsr     x1, x24, #3
    bl      emit_raw
    la      x9, pass
    ldr     x9, [x9, #0]
    mov     x10, #2
    cmp     x9, x10
    b.ne    5f
    la      x9, linebuf
    la      x10, hexdigits
    lsr     x11, x24, #2                // hex digits
    sub     x12, x24, #4                // shift of the next one
3:  cbz     x11, 4f
    lsr     x13, x23, x12
    and     x13, x13, #15
    add     x13, x10, x13
    ldrb    w13, [x13, #0]
    strb    w13, [x9, #0]
    add     x9, x9, #1
    sub     x12, x12, #4
    sub     x11, x11, #1
    b       3b
4:  mov     x13, #CH_space
    strb    w13, [x9, #0]
    strb    w13, [x9, #1]
    add     x9, x9, #2
    la      x1, linebuf
    sub     x2, x9, x1
    bl      write_out
    ldr     x1, [x25, #NODE_content]
    ldrb    w2, [x25, #NODE_content_len]
    bl      write_out
    la      x1, newline
    mov     x2, #1
    bl      write_out
5:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    ldr     x24, [sp, #16]
    ldr     x25, [sp, #24]
    add     sp, sp, #48
    ret

// emit_raw: appends the x1 bytes at x0 to outbuf and moves cur_pc past
// them.
emit_raw:
    la      x9, in_bss
    ldr     x9, [x9, #0]
    cbnz    x9, emitted_in_bss
    la      x15, out_end
    ldr     x9, [x15, #0]
    la      x10, outbuf
    mov     x11, #OUT_SIZE
    add     x10, x10, x11
    add     x12, x9, x1
    cmp     x12, x10
    b.hi    out_full
    la      x13, cur_pc
    ldr     x14, [x13, #0]
    add     x14, x14, x1
    str     x14, [x13, #0]
1:  cbz     x1, 2f
    ldrb    w11, [x0, #0]
    strb    w11, [x9, #0]
    add     x0, x0, #1
    add     x9, x9, #1
    sub     x1, x1, #1
    b       1b
2:  str     x9, [x15, #0]
    ret

// skip: moves cur_pc x0 bytes on: by emitting zero bytes, or after bss
// only the address.
skip:
    sub     sp, sp, #16
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // bytes left
    mov     x23, x0
    la      x9, in_bss
    ldr     x9, [x9, #0]
    cbz     x9, 1f
    la      x9, cur_pc
    ldr     x10, [x9, #0]
    add     x10, x10, x23
    str     x10, [x9, #0]
    b       2f
1:  cbz     x23, 2f
    la      x0, zero_byte
    mov     x1, #1
    bl      emit_raw
    sub     x23, x23, #1
    b       1b
2:  ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    add     sp, sp, #16
    ret

// write_output: writes outbuf, everything emitted, to the file out_path.
write_output:
    sub     sp, sp, #16
    str     x30, [sp, #0]
    str     x23, [sp, #8]               // fd
    mov     x0, #AT_FDCWD
    la      x1, out_path
    ldr     x1, [x1, #0]
    mov     x2, #O_CREAT_WRONLY_TRUNC
    mov     x3, #MODE_0755
    mov     x8, #SYS_openat
    svc     #0
    cmp     x0, #0
    b.lt    create_failed
    mov     x23, x0
    la      x1, outbuf
    la      x9, out_end
    ldr     x2, [x9, #0]
    sub     x2, x2, x1
    bl      write_all
    mov     x0, x23
    mov     x8, #SYS_close
    svc     #0
    ldr     x30, [sp, #0]
    ldr     x23, [sp, #8]
    add     sp, sp, #16
    ret

// write_all: writes the x2 bytes at x1 to fd x0, however many writes it
// takes.
write_all:
    mov     x9, x0
1:  cbz     x2, 2f
    mov     x0, x9
    mov     x8, #SYS_write
    svc     #0
    cmp     x0, #0
    b.le    write_failed
    add     x1, x1, x0
    sub     x2, x2, x0
    b       1b
2:  ret

// write_out: writes x2 bytes at x1 to stdout.
write_out:
    mov     x0, #STDOUT
    mov     x8, #SYS_write
    svc     #0
    ret

create_failed:
    la      x1, msg_create
    mov     x2, #msg_create_len
    b       die
write_failed:
    la      x1, msg_write
    mov     x2, #msg_write_len
    b       die
out_full:
    la      x1, msg_full
    mov     x2, #msg_full_len
    b       die
emitted_in_bss:
    la      x1, msg_bss
    mov     x2, #msg_bss_len
    b       die

// die_name: writes the x2-byte message at x1 and the x4-byte name at x3 to
// stderr, then a newline, and exits with status 1.
die_name:
    mov     x23, x3
    mov     x24, x4
    mov     x0, #STDERR
    mov     x8, #SYS_write
    svc     #0
    mov     x0, #STDERR
    mov     x1, x23
    mov     x2, x24
    mov     x8, #SYS_write
    svc     #0
    la      x1, newline
    mov     x2, #1

// die: writes the x2-byte message at x1 to stderr and exits with status 1.
die:
    mov     x0, #STDERR
    mov     x8, #SYS_write
    svc     #0
    mov     x0, #1
exit:
    mov     x8, #SYS_exit
    svc     #0
