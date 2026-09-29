#

## Wat te maken?

- output is een binary, zou elk code object leiden naar een library?
- hoe opdeling maken tussen code en binary? bepaald deel in lijst?
- binary en meta objects?
- dus, een compiler he, een binary lezen en dan de ff te genereren om de binary van te maken
- zonder argument, ach ik weet niet zeg, 'k moet dat bootstrappen
- malloc is belangrijk
- de hash moet vroeg, maar wat is het zaadje he, de kernel kan niets en moet organisch groeien he
- eerst een editor en een terminal, de editor moet de code laten zien, de taal he, die moet alles kunnen, system en andere, in eerste instatie schipperen tussen c code en ff, maar eigenlijk moet alles in c want nog geen netwerk he, hoe ga ik dat testen, en wat met die vele drivers? overzetten van freebsd?
- geen file browser meer --> is editor
- cd verdwijnt
- wanneer ga ik volledig in ttp werken? dan moet minstes usb en liefst netwerk/wifi werken
- wanneer de merkle tree introduceren? en dan git wise veranderingen bijhouden, gewoon een diff van de node, maar kan een node dan geen diff zijn? te zien in meta?
- een netwerk om de code door te sturen, dus een server daarvoor voorzien, met mijn eigen git

##
- nodes kunnen gesorteerd worden, tenzij voor security dat die random moeten zijn, os bepaald plaats in memory afhankelijk van grootte
- op 4 kilo byte normaal structure padding of data alignment, maar dat hoeft niet he

## Claude oplossing
On-disk record — flat, no pointers

DISK NODE (packed into a 4 KB block):
  hash          byte[32]        // content address — Merkle key, collision-safe
  children_len  int32
  child_lba[]   int64 × len     // block numbers, NOT memory pointers
  content_len   int32
  content       byte × content_len   // inline; spill to extra blocks if > 4 KB

In-memory record — pointers, rebuilt on load

RAM NODE:
  id            byte[32]    // hash
  children_len  int32
  NODE        **children    // filled in AFTER load, not stored
  content_len   int32       // geen NULL termination! --> voor binaries
  char         *content
  // optional runtime-only: NODE *parent, hash, dirty flag

id = hash(content + child_ids_in_order)

## Build / run / verify

The bootstrap compiler reads `src/os/boot_flow.txt` (the objdump of the RISC-V
OS, see `src/os/DISASSEMBLY.md`), breaks each instruction into its fields and
writes the bytes into a binary image at each line's file offset. Decoding is
driven by one opcode table (`rv_ops` in `encode.c`, RV64IMAC + Zicsr +
Zifencei): a 32-bit instruction becomes opcode, funct3/funct7, rd/rs1/rs2 and
its un-scrambled immediate; a compressed (RVC) one its quadrant, funct bits,
registers and immediate, described as its 32-bit expansion. The fields are
reassembled and must reproduce the original bytes (PASS). Words that are no
such instruction (the `unimp` padding, `.insn`, reserved/HINT encodings, the
`.rodata` strings shown as code) are passed through verbatim, so the image is
faithful regardless.

Every decoded `.text` line is also re-encoded from objdump's *text* through the
node-tree assembler (`encode()`) and must give the same bytes: the encoder is
checked against the real toolchain on every run.

```sh
make os compiler && make -C src/os bin      # os.elf, flat os.bin, ttpc

# Expect 0 failed and every .text line re-encoded, e.g.:
#   ttpc: assembled 342 instruction(s) ... (304 decoded, 38 passed through,
#         0 failed; 265/265 .text lines re-encoded)
./build/compiler/ttpc src/os/boot_flow.txt build/compiler/ttpos.img
./build/compiler/ttpc -v src/os/boot_flow.txt /dev/null | less   # field breakdown

# The image must be byte-identical to os.bin (ttpc pads to 1 MiB, hence -n):
cmp -n $(stat -c%s build/os/os.bin) build/os/os.bin build/compiler/ttpos.img
make compiler-test                                     # boot it in QEMU
```

## Assembler mode (`-a`): node tree -> machine code

The inverse direction. Code is written as a **node tree** (the "ff", see
`include/node.h`): an instruction is a node whose content is the mnemonic and
whose children are its operands. Operands are leaves (a register `a0`/`x10`, a
CSR name like `mtvec`, an immediate) or a `mem` node with children
`base offset` for a load/store address: `ld a0, 8(sp)` is the node `ld` with
children `a0` and `mem(sp, 8)`. Branch and jump targets are pc-relative
offsets. The common pseudo-instructions (`li` with a 12-bit value, `mv`, `j`,
`ret`, `beqz`, `csrr`, `sext.w`, ...) are accepted, and so are explicit `c.*`
mnemonics. By default the encoder picks the compressed form whenever one fits,
as GNU as does; an `option` node with child `norvc` / `rvc` turns that off/on.

`ttpc -a` reads a serialized node program and prints each instruction's machine
code as hex, in memory order. It shares `struct insn`, the opcode table and
`assemble()` with the decoder, so the encoder and decoder agree on instruction
shape. (The x86 node program `src/os/ff/program.nodes` went away with the x86
OS; until a RISC-V one exists, the `.text` re-encode check above is the
encoder's test.)

```sh
./build/compiler/ttpc -a program.nodes       # hex, one insn per line
./build/compiler/ttpc -a -v program.nodes    # + mnemonic/operands
```
