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
| `ttpc.ff` | **ttpc in ff**, the source from now on, edited in sicompass: a whole tree, the shared pages, ttpc's constants (page `3:`) and ttpc itself (page `4:`, the last). |
| `progs/*.ff` | test programs, whole trees too: `exit42`, `hello`, `wide` in asm-level ff, each with a GNU twin `.s`; the `c*` ones in the C layer, each with its `.expect` (`exit N`, then its output). |
| `mkff.pl` | the shared pages every tree starts with: the RV64GC instruction set (pages `0:`, `1:`) and `macros.ff.txt` (page `2:`). `perl mkff.pl a.ff.txt ... > new.ff` starts a new tree; `make refresh` puts changed shared pages into every tree. |
| `macros.ff.txt` | the source of shared page `2:`: `byte`/`half`/`word`/`dword`, `rel`, `pcrel_hi/lo`, the pseudo-instructions (`li`, `la`, `call`, `j`, `beqz`, ...) and `elf_header`. |
| `ff.ld` | the layout ttpc gives a program, for linking the GNU twins. |
| `FF.pm`, `fftext.pl` | the ff tree for the host tools; `.ff` <-> `.ff.txt`, the text form, for reading, diffs and editing without sicompass. |

```
stage0 = GNU as(ttpc.s)
stage1 = stage0(ttpc.ff)
stage2 = stage1(ttpc.ff)        == stage1, byte for byte: the fixed point
```

```sh
make bootstrap        # stage1 == stage2, stage1 behaves as stage0
make compiler-check   # every asm program == its GNU twin, they run; the C
                      # programs (built by stage2) do what .expect says
```

A change to ttpc is a change to `ttpc.ff` that keeps `make bootstrap`
green: stage0 builds the new stage1, which must then rebuild itself
identically. ttpc reads `.ff` directly; the text form is only for the host
tools (`perl fftext.pl txt ttpc.ff > t.ff.txt`, edit, `perl fftext.pl ff
t.ff.txt > ttpc.ff`). Whatever ttpc.ff uses, stage0 must know: new
features (the C layer, compile time) are for the programs, ttpc itself is
still written in the language of stage0. stage0 also bounds ttpc.ff to 1 MiB.

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
- **Builtins**: `ascii`, `align`, `reserve`, `origin`, `bss`, `size`, and
  `comment` (any children, text that is not evaluated: it emits nothing; not
  in stage0, so ttpc.ff itself has none).
- **Range checks** (pass 2): every operand must fit its slices, sign- or
  zero-extended from the highest bit they take; an `imm` below bit 31 only
  sign-extended (the U-type's 32-bit pattern aside), `rd'` and friends not
  checked. `pcrel_lo` and `lo` hand a 12-bit field just its 12 bits.
  stage0 has none: it assembled `ttpc.ff` before them.

### The C layer

A function on the program page whose first child is a type is C, in ff
style: no text to parse, the tree is the syntax, a node holds one thing.
ttpc lowers it straight to the instructions of the tree (pages `0:`, `1:`),
encoding them by name: values go through `a0`, the left operand of an
operator through the stack, locals below the frame pointer `s0`.

- **Items.** An operator node joins its neighbours into one infix
  expression, with C precedence: `een variabele` / `*` / `3`. Siblings
  without an operator between them are separate items: statements,
  arguments, elements. Operators: `+ - * / % << >> & | ^ == != < <= > >=`,
  `and or not ~` (and, or short-circuit), `= += -=`, `++ --`, a leading `-`.
- **`:`** is an anonymous function run in place: a block with its own
  scope, or parentheses (its value is its last item).
- **Declarations** `name:` [type] items: a local in a function, a global at
  the top of the page. Without a type it takes the type of its value; more
  items make an array, one element each; none is zero.
- **Functions** `name:` type params... statements...: a parameter is
  `name:` with only a type (or, untyped, a leaf that names nothing).
- **Types** `char` (u8) `short` `int` `long` `i8`..`i64` `u8`..`u64` `void`,
  `address` T, `array` T n, and structs: `point:` `struct` `x:` `int` ...,
  laid out as C does. A type called with a value converts it.
- **Paths** by calling: `xs` / `i` an element, `p` / `x` a field (also
  through an address), `r` / `b` / `x` both in a row. `address` / x is C's
  `&x`, `content` / p is C's `*p` (read, or written on the left of `=`).
- **Reserved**: the keywords (`address`, `content`, `if`, `while`, ...,
  `compile time`) and the type names name no variable, function or struct.
- **Statements** `if` cond body... (the next item `else` body...), `while`
  cond body..., `break`, `continue`, `return` [expr], `syscall` n args...,
  `comment` .... The condition is the leading run of nodes the operators
  join; the rest is the body.
- **Text** `char` with a leaf that names nothing: its bytes and a NUL.
- **asm**: a node naming an instruction or macro of the tree is emitted as
  it is (`ecall`, `li` / `5` / `a0`).

### compile time

`compile time`, as the first child of a function, a lambda `:`, an `if` or
any call, is metaprogramming: that runs while compiling and is not in the
program. It replaces `#define` (`LINES:` / `compile time` / `3`), `#if` (`if`
/ `compile time` / `OS` / `==` / `Android` ...: only the taken branch is
compiled), macros (`square:` / `compile time` / `x` / `x` / `*` / `x`,
called with values known while compiling), and code that writes code:
inside it `emit` subtree... puts subtrees where it stands, a `number` / expr
in them becoming that number; `fail` text stops the compile.

It runs natively, so it can do anything: ttpc assembles it, with the
whole program page (C and asm, which it may call), into its own memory past
what is emitted (`origin` and `bss` do nothing there) (programs ttpc makes have one RWX segment), in a space of labels
of its own, and calls it. Its value and what it emits are kept per node:
it runs once, in pass 1. stage0 cannot do this (GNU ld gives it no
executable bss); stage1 and later can.
