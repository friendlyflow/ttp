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

## Bootstrap

ttpc assembles itself from ff. The pieces, all in this folder:

| file | what |
|---|---|
| `ttpc.s` | **stage0**, the frozen seed: ttpc in RISC-V assembly, built by GNU as. It no longer changes; it is the small, auditable start of the chain. |
| `ttpc.consts.ff.txt`, `ttpc.ff.txt` | **ttpc in ff**, the source from now on: its constants and its program page, in the text form (`fftext.pl` converts to and from `.ff`). |
| `mkff.pl` | writes an ff tree: the RV64GC instruction set (pages `0:`, `1:`), then one page per `.ff.txt` file. |
| `macros.ff.txt` | the shared page: `byte`/`half`/`word`/`dword`, `rel`, `pcrel_hi/lo`, the pseudo-instructions (`li`, `la`, `call`, `j`, `beqz`, ...) and `elf_header`. |
| `progs/` | test programs (`exit42`, `hello`, `wide`), each with a GNU twin `.s`. |
| `ff.ld` | the layout ttpc gives a program, for linking the GNU twins. |
| `FF.pm`, `fftext.pl` | the ff tree for the host tools; `.ff` <-> `.ff.txt`. |

```
stage0 = GNU as(ttpc.s)
stage1 = stage0(ttpc.ff)        == GNU as(ttpc.s) in ff.ld's layout (make oracle)
stage2 = stage1(ttpc.ff)        == stage1, byte for byte: the fixed point
```

```sh
make bootstrap        # stage1 == stage2, stage1 behaves as stage0, the oracle
make compiler-check   # every program == its GNU twin, exit42 and hello run
```

A change to ttpc is a change to `ttpc.ff.txt` (eventually `ttpc.ff` in
sicompass) that keeps `make bootstrap` green: stage0 builds the new stage1,
which must then rebuild itself identically. `make oracle` holds only while
`ttpc.ff.txt` is still the translation of `ttpc.s`; drop it from the root
`bootstrap` target with the first change to `ttpc.ff.txt`.

### The language ttpc assembles

- A node ending in `:` is a function; its leading leaf children are its
  parameters. Any other node is a call; its children are the arguments.
- The root's children are pages. Every page but the last holds definitions;
  the last page is the program: its functions are **placed** labels whose
  children are emitted where they stand (block form, nested ones are local
  labels), its calls are emitted in order. Two passes: the first finds the
  labels, the second emits.
- A function whose body holds only fields (fixed `name:` bits and slice
  calls `imm[11:0] imm`) is an **encoding**: an instruction or a data word.
- **Contexts**: code (encode and emit, or expand a macro), field (the fields
  of an encoding, MSB first) and exec (assemble time, on virtual registers;
  the ALU ops of `exec_ops` are the seed).
- **Arguments**: a nested call (run in exec, its value is `a0`), a number
  (decimal or `0x`), a parameter, a register, `pc`, a label or a constant.
- **Builtins**: `ascii`, `align`, `reserve`, `origin`, `bss`, `size`.
- No range checks yet: a branch farther than its reach is silently wrong.
  The oracle caught nine of those in `ttpc.s`; keep error stubs near their
  users.
