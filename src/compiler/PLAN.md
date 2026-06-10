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

The bootstrap compiler reads `src/os/boot_flow.txt`, breaks each instruction
into its fields (opcode in its own variable, plus prefix/modrm/sib/disp/imm),
reassembles the bytes, and writes them into a binary image at each
instruction's memory address. Currently the first 3 instructions only.

```sh
# Build the compiler
make compiler

# Run it: reads boot_flow.txt, writes the binary, prints the field breakdown
./build/compiler/ttpc src/os/boot_flow.txt build/compiler/ttpos.img

# 1) Confirm the bytes landed at memory-address offset 0x7c00
xxd -s 0x7c00 -l 6 build/compiler/ttpos.img
#   expected: 00007c00: 31c0 8ed8 8ec0   1.......

# 2) Disassemble those bytes and confirm they round-trip to the original asm
dd if=build/compiler/ttpos.img bs=1 skip=$((0x7c00)) count=6 2>/dev/null \
  | ndisasm -b16 -o 0x7c00 -
#   expected:
#     00007C00  31C0   xor ax,ax
#     00007C02  8ED8   mov ds,ax
#     00007C04  8EC0   mov es,ax
```

`ndisasm` ships with `nasm` (already used by the OS build). Alternative:
`objdump -D -b binary -m i8086 --start-address=0x7c00 --adjust-vma=0x7c00 build/compiler/ttpos.img`
