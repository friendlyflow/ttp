# ttpc.s — the trust project compiler, in RISC-V assembly, without libc.
#
# A static Linux riscv64 program (run it with qemu-riscv64 on another host).
# It talks to the kernel only through ecall: it opens the ff file named by
# its first argument, loads it into memory as a tree of NODEs and prints
# that tree, one node per line.
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
    .equ STDOUT, 1
    .equ STDERR, 2

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
msg_usage:      .ascii "usage: ttpc <file.ff>\n"
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
hexdigits:      .ascii "0123456789abcdef"
indent:         .ascii "  "
newline:        .ascii "\n"

    .section .data
hexbuf:         .ascii "00000000  "         # hash prefix of a printed line

    .section .bss
    .balign 8
nodes:          .skip MAX_NODES * NODE_size
ptrs:           .skip MAX_NODES * 8
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
    ld      a1, 16(sp)                  # argv[1]

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
    li      a1, 0
    call    print_node

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

# die: writes the a2-byte message at a1 to stderr and exits with status 1.
die:
    li      a0, STDERR
    li      a7, SYS_write
    ecall
    li      a0, 1
exit:
    li      a7, SYS_exit
    ecall
