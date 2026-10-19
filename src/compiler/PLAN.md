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
| `hosts/riscv64/ttpc.s` | **stage0**, the frozen seed: ttpc in RISC-V assembly, built by GNU as. It no longer changes; it is the small, auditable start of the chain. |
| `ttpc1.ff` | **ttpc1**, frozen too: ttpc in ff as it was when it learned targets, a whole tree (the RV64GC pages `0:` `1:` `2:` of then, its constants `3:`, itself `4:`) in the language of stage0 and below stage0's 1 MiB. |
| `ttpc2.ff`, `ttpc2.defs.ff` | **ttpc2**, frozen: `ttpc.ff` and `ttpc.defs.ff` as they were when the seeds' 1 MiB got tight (16 Oct 2026, with C's integers and control flow), program-only. ttpc1 builds it on riscv64, each seed on its host (its whole tree is 949 KB on arm); it builds ttpc3. |
| `ttpc3.ff`, `ttpc3.defs.ff` | **ttpc3**, frozen: `ttpc.ff` and `ttpc.defs.ff` as they were when ttpc learnt layers (18 Oct 2026: a function named only by digits, `0:` `1:` ..., is the overflow of its parent), before ttpc.ff used them, which ttpc2 does not know. ttpc2 builds it on riscv64 and on each host; it builds `ttpc.ff`, which may use anything ttpc3 knows (layers too) and grow to its 32 MiB of input (BUF_SIZE) and 16 MiB of output (OUT_SIZE). |
| `ttpc.ff`, `ttpc.defs.ff` | **ttpc in ff**, the source from now on, edited in sicompass: a program of only its own (`ttpc.ff`), its constants and messages' lengths on a page of their own (`ttpc.defs.ff`), assembled on the shared page: `ttpc --target riscv64 shared.ff ttpc.defs.ff ttpc.ff out`. |
| `shared.ff` | the shared page (`perl gen/mkff.pl > shared.ff`, kept by `make refresh`): what a program-only tree is assembled with, `ttpc [--target t] shared.ff prog.ff out`. |
| `gen/mkff.pl`, `shared.ff.txt` | make `shared.ff`: what every target has and the choice of one (`shared.ff.txt`), then a section per target. |
| `gen/ISA.pm`, `isa/<target>.pl` | the instructions of each target (riscv64: RV64GC; x86_64; aarch64; arm), its registers and slices. |
| `macros/<target>.ff.txt` | each target's pseudo-instructions, `elf_header` and `frame`, its Linux system calls, and the primitives of the C layer. |
| `progs/*.ff` | test programs: the `c*` ones in the C layer, only their program, each with its `.expect` (`exit N`, then its output; `<name>.<target>.expect` where a target differs); `cws.ff` is a build file. |
| `progs/<target>/` | `exit42`, `hello`, `wide` (every instruction of the section) for that target, each with a GNU twin `.s`: in `progs/riscv64/` whole trees (the pages of then), elsewhere program-only; `mkwide.pl` writes `wide.ff` and `wide.s` from one table. |
| `ff64.ld`, `ff32.ld` | the layout ttpc gives a program, for linking the GNU twins (ELF64; ELF32 for arm). |
| `gen/FF.pm`, `gen/fftext.pl` | the ff tree for the host tools; `.ff` <-> `.ff.txt`, the text form, for reading, diffs and editing without sicompass. |
| `language.ff.txt`, `language.ff` | the language, asm and C, described as an ff tree: what can be written and what it means. |
| `hosts/<host>/ttpc.s` | **the seeds of the other hosts** (x86_64, aarch64, arm), frozen: ports of `ttpc.s`, function by function, that must agree with it byte for byte (`make seeds`), with one difference: `OUT_SIZE` 1 MiB, since ttpc for those hosts is larger than stage0's 64 KiB. |
| `rv64:` in `macros/<host>.ff.txt` | ttpc's own ops of RV64 (`rv.add`, `rv.ld`, ..., 50 or so) and its registers (`rv.a0`, ...) in the host's instructions: on x86_64 and arm the registers are 8-byte slots in memory, on aarch64 registers of its own. Also per host: `host_name`, `cc_ctargs` / `cc_call_l` / `cc_ctreg` (the bridge from compile time to ttpc), `ldword`. |
| `gen/mkhost.pl` | ttpc for a host: renames every op and register of `ttpc.ff` and the macros of `ttpc.defs.ff` it calls to `rv.<name>`, so that the one source assembles for the host. |
| `gen/mkwhole.pl` | a whole tree in the language of stage0: the target's section as pages, the shared definitions, the given pages, the exec ops, the program; only what the program reaches (stage0 reads 1 MiB). |
| `gen/frozen.pl` | a tree in the language of the frozen ttpc1 and stage0: `shared.ff` without comments (known only in code) and without `else if:` (which they take for a register). |

```
stage0 = GNU as(hosts/riscv64/ttpc.s)
ttpc1  = stage0(ttpc1.ff)       == ttpc1(ttpc1.ff)
ttpc2  = ttpc1(frozen shared.ff, ttpc2.defs.ff ttpc2.ff)
                                == ttpc2(shared.ff ttpc2.defs.ff ttpc2.ff)
ttpc3  = ttpc2(trimmed shared.ff, ttpc3.defs.ff ttpc3.ff)
                                == ttpc3(shared.ff ttpc3.defs.ff ttpc3.ff)
stage1 = ttpc3(shared.ff ttpc.defs.ff ttpc.ff)
stage2 = stage1(shared.ff ttpc.defs.ff ttpc.ff)
                                == stage1, byte for byte: the fixed point
```

On x86_64, aarch64 and arm the chain starts from that host's seed and
never runs riscv64 (`make bootstraps`; natively on the host itself, under
`qemu-<host>` elsewhere). ttpc1 is not in it: its C layer still emits
RV64 by name, so its compile time can only run on riscv64. The seed builds
ttpc2, which builds ttpc3, which builds today's ttpc.ff:

```
seed   = GNU as(hosts/<host>/ttpc.s)
ttpc2  = seed(mkwhole(<host>, mkhost(<host>, ttpc2.defs.ff ttpc2.ff)))
                                == ttpc2(--target <host> shared.ff ttpc2.defs.ff' ttpc2.ff')
ttpc3  = ttpc2(--target <host> trimmed shared.ff, ttpc3.defs.ff' ttpc3.ff')
                                == ttpc3(--target <host> shared.ff ttpc3.defs.ff' ttpc3.ff')
stage1 = ttpc3(--target <host> shared.ff ttpc.defs.ff' ttpc.ff')
stage2 = stage1(--target <host> shared.ff ttpc.defs.ff' ttpc.ff')
                                == stage1 == what the riscv64 chain makes
                                   with --target <host>: two chains that
                                   share only the source
```

```sh
make bootstrap        # ttpc1, ttpc2, ttpc3 assemble themselves, stage1 == stage2
make bootstraps       # the same from the seed of x86_64, aarch64, arm; the
                      # C programs built there by stage2 run there
make seeds            # each seed agrees with ttpc.s
                      # (both run what this machine can: its own host
                      # natively, the others only if their qemu is there;
                      # without qemu-riscv64 no comparison with riscv64)
make compiler-check   # every asm program == its GNU twin, they run; the C
                      # programs (built by stage2) do what .expect says, on
                      # every target (make targets)
```

A change to ttpc is a change to `ttpc.ff` (or `ttpc.defs.ff`) that keeps
`make bootstrap` green: ttpc3 builds the new stage1, which must then
rebuild itself identically. ttpc reads `.ff` directly; the text form is only
for the host tools (`perl gen/fftext.pl txt ttpc.ff > t.ff.txt`, edit, `perl
gen/fftext.pl ff t.ff.txt > ttpc.ff`). ttpc reads several trees: `ttpc a.ff
b.ff ... prog.ff out` takes the pages of all but the last, then the last
whole as the program (its root is the page); one tree alone is read as
before, unless it begins with `include`. One tree and no output is a build
file (`ttpc build.ff`, see Build files); `ttpc --print tree.ff` prints a
tree (stage0, ttpc1 and the seeds print one tree alone). Whatever ttpc.ff
uses, ttpc3 must know (all of the language up to 18 Oct 2026, layers
included); ttpc3 reads at most 32 MiB in all (BUF_SIZE), shared.ff (3 MB)
with it, and writes at most 16 MiB (OUT_SIZE). When ttpc needs what ttpc3
does not know, or outgrows that, the chain gets a next link: freeze
ttpc.ff as ttpc4.ff. ttpc2 still reads at most 4 MiB: it gets shared.ff
trimmed to riscv64's section (and the host's) for building ttpc3.

### The language ttpc assembles

- A node ending in `:` is a function; its leading leaf children are its
  parameters. Any other node is a call; its children are the arguments.
- A definition whose name has a space and whose first child is a bit string
  is a register (`x10 a0:` / `01010`, its number), each word one of its
  names. Any other name with a space is just a name (`else if:`).
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
- **The frame.** A program page without an `origin` or `elf_header` of
  its own is assembled inside the target's `frame:` (`elf:`): `origin`, the ELF
  header, its children where `frame:` says `program`, then `file_end:`,
  `bss`, `mem_end:`. A page that lays itself out is left as it is.
- **Builtins**: `ascii`, `align`, `reserve`, `origin`, `bss`, `size`, and
  `comment` (any children, text that is not evaluated). It is the one
  comment, anywhere: in code and at assemble time it does nothing; beside
  definitions (a page, a section, a group) and among the fields of an
  encoding ttpc passes it by. It comes after a function's parameters, which
  are its leading leaves. stage0 has none and ttpc1 knows it only in code,
  so the bootstrap hands ttpc1 `shared.ff` without comments (`frozen.pl`).
  Every name ttpc takes by itself, these builtins and the C layer's keywords,
  types and operators (`cc_kw`, `cc_tynames`, `cc_ops`), is declared like any
  function directly on the shared page (`shared.ff.txt`: `comment:` / `text`,
  `if:` / `condition` / `body`, `else if:`, `long:` / `value`, `+:` / `left` /
  `right`, ...), in scope, so that each is defined before it is called. ttpc
  takes these calls itself and never runs the declarations. `make decls`
  (`gen/decls.pl`, in `make check`) fails when a word, operator or type of
  ttpc has no declaration there: they are what an editor offers as calls. In asm a C word
  is a function with an empty body: a stray `if` expands to nothing.
- **Range checks** (pass 2): every operand must fit its slices, sign- or
  zero-extended from the highest bit they take; an `imm` below bit 31 only
  sign-extended (the U-type's 32-bit pattern aside), `rd'` and friends not
  checked. `pcrel_lo` and `lo` hand a 12-bit field just its 12 bits.
  stage0 has none: it assembled `ttpc.ff` before them.

### The C layer

A function on the program page whose first child is a type is C, in ff
style: no text to parse, the tree is the syntax, a node holds one thing.
ttpc lowers it to the **primitives** of the target (see Targets): values go
through V, the left operand of an operator through the stack, locals below
the frame pointer. The C layer is written once, for every target. All of
the language, asm and C, is described as an ff tree in `language.ff.txt`
(`language.ff` for sicompass).
- **Items.** An operator node joins its neighbours into one infix
  expression, with C precedence: `een variabele` / `*` / `3`. Siblings
  without an operator between them are separate items: statements,
  arguments, elements. Operators: `+ - * / % << >> & | ^ == != < <= > >=`,
  `&& || ! ~` (&&, || short-circuit), `= += -= *= /= %= &= |= ^= <<= >>=`
  (a compound one is the operator on the variable and the value, so `p` /
  `+=` / `2` counts elements of an address), `++ --`, a leading `-`. An
  operator first in an item starts an expression, in a lambda too
  (`:` / `-` / `16` ...).
  `and` and `or` are the instructions of the tree (bitwise, with operands).
- **`:`** is an anonymous function run in place: a block with its own
  scope, or parentheses (its value is its last item).
- **Declarations** `name:` type items: a local in a function, a global at
  the top of the page. The type is required and nothing is derived from the
  value ("needs a type"). No item is zero, one is the value; several only
  on an array (one element each, the rest zero, no more than its count) or
  a struct (one field each), elsewhere "several items need array". A field
  or element that is a struct, union or array takes a `:` holding its items
  (C's inner braces, `progs/cinit.ff`), and what has no item is zero (a
  local aggregate is zeroed first). A global is built in a staging buffer
  and written at once, the texts its items name right after it; its items
  are worked out while compiling: a number or constant, `-` and one,
  `address` / a global or function, a text, or a `:` expression (run by
  compile time). A page item whose items have children only as `:` or
  `address` is a global; any other is a function.
- **Functions** `name:` type params... statements...: a parameter is
  `name:` with a type and nothing else. A function without parameters is
  called by its name alone (`address` / f is its address); `name:` in a
  body is a declaration (a label without a type), never a function. `return` is a value too: as an
  item it leaves the function there. The parameters are the leading
  `name:` nodes with only a type, so a local first in a body needs a value
  (`r:` / `point` / `0`) or a statement before it (the user kept this rule,
  16 Oct 2026). A call puts its first 8 arguments in registers and leaves
  the others on its stack during the call: the callee reads one at FP +
  `cc_argoff` + (n-1-i) slots (`progs/ccalls.ff`). Structs go by value:
  `=` copies (`copyst`, a word at a time where the alignment allows), `a:`
  / `point` / `b` starts as a copy, a struct argument is passed by address
  and the callee copies it into its parameter, and a struct result goes
  into space the caller keeps for it (all of a function's, reserved at its
  start by `treserve`), its address pushed after the arguments; `return`
  copies into it.
  A leaf `...` after the parameters makes a function variadic
  (`progs/cvarargs.ff`): a call to it pushes its arguments, then their
  count (then a struct result's address) and loads no registers; the
  callee finds argument i at FP + `cc_argoff` + (1 + result) slots +
  (n-1-i) slots, n read at run time (`argaddr`). An argument of a type kept in
  memory goes as its value, its object's address, which `vaarg` loads
  from the slot as a word. `va_list` is a word,
  `va_start` / ap points it at the first argument after the parameters,
  `va_arg` / ap / type reads one and steps ap down a slot, `va_end` does
  nothing, `va_copy` / to / from copies.
- **Library C** (`progs/clib.ff`, `progs/clibdefs.ff`): a C function or
  global on a definition page (an included tree, as glibc is) is
  compiled when the program reaches it, and only then. Where `find_label`
  (the scopes being placed) finds nothing, the C layer's lookups (`cfind`)
  take the definition pages' C definition of that name (`libsym`: never a
  word, operator or type of ttpc; `libtype` for a type, `enumlib` for an
  enum's constant), and put a function or global on a list. `cc_frame`
  puts a marker after the program's items, and there `cc` compiles the
  list, which grows as its definitions reach more. The list lives across
  passes, so each pass emits the same definitions in the same order.
- **alias and ifunc** (`progs/cifunc.ff`, `progs/cifunclib.ff`): `name:` /
  `alias` / target is another name for target (a lookup takes the target).
  `name:` / `ifunc` / resolver / type / parameters is a function chosen when
  the program starts: it is a word, and a call goes through it. At the
  library marker an init routine calls each resolver with (hwcap,
  `__riscv_hwprobe` or 0, 0), as glibc's riscv startup does, and keeps what
  it returns in that word; hwcap is AT_HWCAP of the auxiliary vector
  (`ifunc hwcap`, C on the shared page, compiled where it is used). A C
  `_start` of a framed program calls the routine first, with the stack it
  began with (FP + `cc_entryoff`); without ifuncs the routine is empty.
  The routine's place among the library definitions is fixed the first
  time, so that both passes emit the same.
  A program whose `_start` is the library's (glibc's start.S, which calls
  `__libc_start_main`) gets no routine: ttpc makes the IRELATIVE table a
  static link has instead, after the library definitions: `__rela_iplt_start`
  (the weak declaration glibc's `apply_irel` reads), an Elf64_Rela per ifunc
  (its word, R_RISCV_IRELATIVE, its resolver), `__rela_iplt_end`; glibc's
  startup resolves them itself, after its TLS (`gen/patches/start.pl`). A
  resolver is reached with its ifunc's word.
- **Asm functions** (`progs/casmfn.ff`, `progs/casmfndefs.ff`): `name:` /
  `asm` / instructions is a function in asm, its instructions and block
  labels placed as the asm of a page is. On a definition page it goes on
  the library list when C reaches it (`libsym`) and is placed at the
  marker (`libcc`), as library C is. C calls it by name and takes its
  address, as a long (`dtype`). `asm` itself is a word of the shared page
  that emits nothing. glibc's `.S` functions come this way, by
  `gen/s2ff.pl`.
- **++ and -- as in C** (`progs/cincdec.ff`): `x` / `++` is C's x++, its
  value the old x; a leading `++` / `x` is C's ++x, its value the new x
  (the user's choice, 16 Oct 2026). `unary` stores the new value either
  way, and for x ++ takes the step back in V.
- **Parenthesized lvalues** (`progs/cparen.ff`): a `:` holding one item
  stands for that item where an address is needed (`addr`), as C's `(len)
  = len % 8` in glibc's memcpy.
- **Casts and text** (`progs/ccast.ff`, the user's rule, 16 Oct 2026):
  `cast:` / type / value is C's cast (`primary` converts the value; as a
  statement it is `(void) x`), and under `address` / `char` a leaf is
  text whatever it reads as, so `address` / `char` / `3` is "3" (`textof`).
  `cast` is a reserved word (`KW_cast`, its word `cast:` in `cc_kw`).
- **A path from an expression** (`progs/cdot.ff`): a `.` leaf among a
  node's children; the node cut there is the value (`index` evaluates a
  copy of the node with fewer children), the path after it walks on.
- **Items groups and char arrays from text** (`progs/cgroups.ff`): a list
  longer than a node holds comes in `items` groups (a declaration's items,
  a `:` group's, an enum's constants: `ginit` splices them, `enumfind`
  looks inside); text leaves in a row fill a char array (`gtext`).
- **Address constants** (`progs/caddrc.ff`): in a global, a name in an
  address field is its address, `cast:` to an address type is its value's,
  `:` / X / `+` / N adds N of what X points at, and `address` of a path is
  its label and offsets (`gpath`, a block of `gval`'s own). A flexible
  array member takes the items after it: `gput` keeps how far the global
  reaches and `global` lays it out again at that size. A global's `:` item
  is assembled without the program page (`ctconst`, as `ctexpr` but `jit`
  leaves the page out): a glibc page made each item cost the whole page.
- **Weak** (`progs/cweak.ff`): `name:` / `weak` / type declares a global
  that may stay undefined, C's `#pragma weak` (`tlskip` skips the word);
  its address is 0 in code and in a global's items, and `weak` /
  `function` / type is a function, called through 0 (`call`, `leafval`).
  c2ff writes one for a weak name, or a function gcc's `error` attribute
  keeps from being called, that no unit defines.
- **`va_arg_pack`** (`progs/cvapack.ff`, the user's choice): in a variadic
  function, the last argument of a call to another passes its own extra
  arguments on, at run time: `args` pushes them in a loop, `call` pushes
  the count then and sets sp again with `syncsp`; `va_arg_pack_len` is
  their count (`vapackm`, which `libcc` made room for in the cc group).
- **An if with no body** (`progs/cifvalue.ff`) is GNU C's `a ?: b`.
- **Asm functions reach what they name**: `libsym` looks up each leaf of
  a reached asm function (`asmreach`) and moves the function after them
  on the list; `eval_arg` names a placed library definition by its label
  and a C alias by its target.
- **Floating point** (`progs/cfloat.ff`, the user's choice: all of it now):
  `float`, `double` and `long double` are type words, codes 0x24, 0x28 and
  0x30 (bit 5 marks floating point), 4, 8 and 16 bytes on every target
  (`tsize` and `talign` read them from the code, not `word8`). A value is
  its bits in V. `binop` takes a floating path (both operands converted to
  the wider type, then the target's primitive from the table at `cc_exts`
  + 121), `fcvt` converts V between two types (`convert`, so `cast:`),
  `unary` negates, and `hexf` reads a literal, an exact hex float. riscv64
  has the primitives (macros/riscv64.ff.txt, F and D); aarch64, x86_64
  (SSE2) and arm (VFP) and long double (glibc's soft-fp) come next. A
  floating type larger than a word is in memory as a struct is (`fwide`:
  long double, and double on arm).
- **Compound literals** (`progs/ccomplit.ff`): a struct or union name with
  items, used as a value, is a temporary of that type, C's `(point){1, 2}`
  as `point` / `1` / `2`: its space is reserved at the start of the
  function (`tscan` counts it), zeroed and filled as a declaration is
  (`complit`); its value is its address, as a struct's is.
- **Conditionals** (`progs/ccond.ff`): `c` / `?` / `a` / `:` / `b` among
  siblings is C's `c ? a : b`, right to left, between `=` and `||`
  (`OP_cond`); `c` / `?` / `:` / `b` is GNU C's `c ?: b`.
- **Labels as values** (`progs/clabels.ff`): `address` / L is the address
  of label L (`label_addr`, given the definition node), `goto` / `content`
  / p jumps to it through `cc_jv` (every target), as glibc's vfprintf
  jump tables need.
- **alloca and variable-length arrays** (`progs/calloca.ff`, the user's
  choice: a real alloca): `alloca` is C on the shared page, from a stack
  of 8 MiB it maps (`alloca top`); a function that calls it or holds an
  `array` / T / n with n a value (`ccalloca` in cc) saves `alloca top` in
  its frame and gives the space back when it returns.
- **Addresses of literals** (`progs/caddrlit.ff`): `address` over a typed
  literal (the literal under the type word) or over a compound literal is
  the address of a temporary holding it; an array element or field of a
  floating type kept in memory takes a value (`linit`).
- **Anonymous members** (`progs/canon.ff`): a field `:` with a struct or
  union type; `fields`, asked for a name that is not its own, looks into
  it and adds its offset.
- **Asm entries** (`progs/casmentry.ff`, `progs/casmentrydefs.ff`): a block
  label of an asm function whose first child is `asm` is a name of its
  own; `libsym` finds it among the asm functions and places the one
  holding it (setjmp.S's `__sigsetjmp`, inside `_setjmp`).
- **The stack after a loop** (`progs/cloopsp.ff`): each label of while, do
  while and for syncs sp (`syncsp`), since a break or continue leaves a
  block whose locals made the stack deeper.
- **Thread-local** (`progs/ctls.ff`, `progs/ctlstp.ff`): `thread local`
  first under a global's name, before its type (`errno:` / `thread local` /
  `int` / `0`). Where the target says so (`cc_tls`: riscv64 so far) it is in
  the TLS image, as gcc and ld lay it out (variant I: at its offset from tp):
  ttpc puts the thread locals off and lays them out after the library list,
  between `__tls_start` (aligned to 64, after 4 KiB of zeros) and
  `__tls_end`, which the frame's PT_TLS program header names; a use is tp +
  its offset (`tprel`, also s2ff's for la.tls.ie). glibc's startup
  (`__libc_setup_tls`) copies the image into the thread's block and sets
  tp; a C `_start` of the program's own points tp at the image, the zeros
  below it the struct pthread glibc's code finds there. Elsewhere (and in
  compile time, and in a program that lays itself out) it is a global
  (`gen/patches/tls.pl`). Stage A brings x86_64's variant II (fs) and
  aarch64's tpidr_el0 with their glibc startup; a second thread waits for
  pthread_create (clone, nptl's stack setup), which no milestone reaches.
- **Scope** is the tree: a name is looked up from where it stands, up
  through its ancestors, innermost first. The page's functions and globals
  are seen everywhere on it; a body, an `if`/`else`/`while` body and a
  lambda are blocks, a local is seen from below its declaration to the end
  of its block ("used before it is declared" above it), an inner one hides
  an outer one, and a callee does not see its caller's locals.
- **Types** are a run of leaf siblings, one word per node: `char` (u8)
  `short` `int` `long` `i8`..`i64` `u8`..`u64` `void`, `address` T (alone,
  the address of nothing), `array` T n (`array` `array` `int` `3` `4`), and
  structs: `point:` `struct` `x:` `int` ..., laid out as C does; `type`
  only in compile time. `long` and `address` are a word of the target (8
  bytes; 4 on arm, where `i64` and `u64` are a pair of registers: see
  Targets). A type with a value converts it, the first word of the type on
  top, the rest of the type and the value its children: `long` / x,
  `address` / `char` / p. A struct may hold an address of itself (`next:` /
  `address` / `node`, `progs/cself.ff`): each struct has one type, made
  before its fields are laid out, so the field finds it.
- **Unions** (`progs/cunion.ff`): `word:` / `union` / fields, as a struct
  whose fields all start at 0, as large as its largest. **Bitfields**
  (`progs/cbits.ff`): a field's type and then its width, `mode:` / `u32` /
  `3`, packed into units of its type as gcc does; a struct is laid out in
  bits. Its type (`TY_BITS`) is read by loading the unit and shifting it
  left and back, written by reading the unit, putting the value in its bits
  and writing it back (`bitload`, `bitstore`).
- **Enums** (`progs/ctypes.ff`): `color:` / `enum` / `red:` / `green:` / `5`
  ...: the name is a type, an `int`; a constant has its value (a number or
  a constant, `-` before it) or one more than the one before, and is seen
  where the enum is (enums on the page; in a function a `name:` without a
  type is a label). **Function types**: `binary:` / `function` / return
  type / parameters; `address` / `binary` points to one, and a variable or
  global of that type with arguments calls through it (`cc_calll`: the
  address is pushed, then the arguments, then it goes to L). `sizeof` and
  `alignof` / a type run or a variable: an unsigned long.
- **Arithmetic** is C's (`progs/cint.ff`, `cint64.ff`): `char` and `short`
  become `int`, then the usual conversions give both operands one type (8
  bytes if either has them, unsigned if an 8-byte one is; else `u32` if
  either is, else `int`); a shift has its left operand's type, a
  comparison and `!` are `int`. A value is as wide as its type: `int` and
  `u32` wrap at 32 bits (`cc_ext_<type>` after the operator), and so are
  cut a store's value, `= += -= ++ --` and a conversion; operands that
  meet as `u32` are zero-extended first (`cc_uw`). A number is an `int`
  if it fits, else a `long`; in hex the first of `int`, `u32`, `long`,
  `u64` it fits. On arm (a `long` of 4 bytes) `u32` with `long` is `u32`,
  C's unsigned long there, and a number that does not fit 32 bits is an
  `i64` (or `u64`).
- **Paths** by calling: `xs` / `i` an element, `p` / `x` a field (also
  through an address), `r` / `b` / `x` both in a row. `address` / x, x not a
  type, is C's `&x`, `content` / p is C's `*p` (read, or written on the left of `=`).
- **Reserved**: the keywords (`address`, `content`, `if`, `else if`,
  `while`, `for`, `do while`, `switch`, `case`, `default`, `goto`, ...,
  `compile time`, `target`), the type names and the register
  names of the target name no variable, function or struct (`type` among
  the type names).
- **Statements** `if` cond body... (the next item `else` body..., or `else
  if` cond body..., which chains), `while` cond body..., `break`,
  `continue`, `return` [expr], `syscall` n args... (n: `SYS_write`,
  `SYS_exit`, ... of the target),
  `comment` .... The condition is the leading run of nodes the operators
  join; the rest is the body. `for` first condition step body...: three
  items, then the body (`progs/cflow.ff`); a declaration as the first is
  the loop's own, an empty `:` is an empty part (an empty condition loops
  for ever). `do while` cond body...: the body first. `switch` value
  body...: `case` value body..., `default` body..., fall through as in C,
  `break` leaves the switch; each case tests where it stands, the first
  test is jumped to, a failed one jumps to the next, the last to the
  default. A label is `name:` without a type in a function: it holds its
  statements and `goto` / name jumps to it, from anywhere in the
  function (a label sets SP for its block). `if`/`else` are a value too,
  C's `?:` (the last item of the branch taken); C's comma is a lambda.
- **Text** `address` `char` and a leaf that names nothing: its bytes and a
  NUL, the value their address; a declaration `my string:` / `address` /
  `char` / `this is a string`, an argument `address` / `char` / text.
  `char` with text is an error ("text needs address char").
- **asm**: a node naming an instruction or macro of the target is emitted
  as it is (`ecall`, `li` / `5` / `a0`). asm belongs to one target: guard
  it with compile time (`progs/casm.ff`: `if` / `target` / `==` / `x86_64`
  / `emit` ...).
- **Registers** are names in C too: reading `t2` is its value now, `t2` /
  `=` (`+=`, `-=`) / expr writes it, which is how values pass between C and
  asm. C itself uses V, L, X (on riscv64 `a0`, `t0`, `t1`: reading them
  gives what it left there) and SP, FP; it does not write the registers of
  `cc_fixed` (on riscv64 `zero`, `ra`, `sp`, `s0`). Register names, too,
  belong to one target.

### compile time

`compile time` goes only first in a function or a lambda `:`; anywhere else
it is an error. That function or lambda is metaprogramming: it runs while
compiling and is not in the program. Inside it is ordinary code (`if`,
`else`, `while`, calls) and `emit` subtree..., which puts those subtrees in
the program where the lambda stands (a `number` / expr in them becomes that
number); `fail` item... stops the compile, printing its items (text, or
`target`: the name --target gave).

- `#define`: a named function, `LINES:` / `compile time` / `3`; a use of
  `LINES` is its value.
- macros: a named function with parameters, `square:` / `compile time` /
  `x:` / `type` / `x` / `*` / `x`; a call `square` / `7` in the program runs
  while compiling (its arguments known then) and is its value. `type`, C++'s
  T, is a word of any type: the function is assembled once, not per type.
- `#if`, generated code: a lambda, `:` / `compile time` / `if` / `OS` /
  `==` / `Android` / `emit` ... / `else` / `emit` ...: only what it emits
  is in the program. A lambda also has a value, its last item.

It runs natively, so it can do anything: ttpc assembles it, with the whole
program page (C and asm, which it may call), into its own memory past what
is emitted (programs ttpc makes have one RWX segment; `origin` and `bss` do
nothing there), in a space of labels of its own, and calls it. Its value
and what it emits are kept per node: it runs once, in pass 1. A lambda
that runs while another one is assembled splices only its own code
(`cct2`). stage0 cannot do this (GNU ld gives it no executable bss); ttpc1
and later can. Compile time runs on the machine ttpc runs on, its host,
whatever the target: the asm it calls is the host's asm, and asm on the
program page it would assemble with it must be the host's too (`ctasm`,
`ctmix` are riscv64 asm, so they compile only on riscv64).

### Build files

`ttpc [--target t] build.ff`, one tree and no output, runs a build file,
as Jai's build programs do: what to read, for which targets, which files,
where the output goes, all of it is in the file.

- **`include`** / path (`import` until 18 Oct 2026, the user renamed it "to stay more C"), first on a program page (comments may come
  before it), reads that tree and puts its pages in front of the program,
  as the trees before it on the command line do. ttpc reads each path once:
  a tree included or added again is the one already in memory (shared.ff
  fits only once in ttpc's 4 MiB of input). Elsewhere `include` does
  nothing; after other items it is an error. Any program may include:
  `ttpc progs/cinclude.ff out` (`include` / `../shared.ff`) is `ttpc
  shared.ff progs/chello.ff out`.
- **`include`** / folder, a folder with an `index.ff` (the user's choice,
  18 Oct 2026, like C's headers), is a library read lazily: its index is
  a page `index:` of `name:` / file, and ttpc reads only the files of what
  the program reaches. The program's node texts (each node's) are looked
  up among the index's names; a name found is reached, its file read once
  (in front of the program, as an include) and its definition looked
  through in turn (an enum's for its constants, an asm function's for its
  entries), until nothing is new; first the names ttpc calls by itself
  (`__riscv_hwprobe`, `_start`, the soft-fp of long double). A text that
  is a name by chance reaches a little more, never less. `gen/ffsplit.pl`
  makes the folder of a library tree, a file per page (glibc's milestones:
  `make -C src/glibc` makes `NAME/`, which `NAME-prog` includes);
  `progs/clazy.ff` includes `progs/clazylib`, whose `never.ff` is no tree
  and is never read.
- **A build file** is a program page. ttpc runs its top-level lambdas `:`
  / `compile time`, with the whole page, so they can call its C
  functions; it assembles and writes nothing of its own.
- **Workspaces**, words of compile time:
  - `w:` / `workspace` makes one; its value names it.
  - `set target` / w / section (`x86_64`, `target`, ...): without it,
    the target of the build.
  - `set output` / w / path: without it, the name of its last file without
    its folder and `.ff`, next to the build file.
  - `add file` / w / path, as often as needed: the last file is the
    program, the ones before it its definition pages, as on the command
    line.
  - `compile` / w queues it.

  A path in a tree is from that tree's folder: `include` from the file it
  stands in, `set output` and `add file` from the file of the code that
  runs them, so `ttpc src/compiler/progs/cws.ff` works from any folder;
  paths on the command line are from the folder ttpc runs in. Text is
  copied when the word runs, so a loop or a C function can make the paths (`progs/cws.ff`: a function `hello` / section / path called
  for two targets).
- **After the build file** ttpc assembles each compiled workspace, in the
  order they were made, as a compile of its own (new labels, C and compile
  time from the start, the trees the build file read kept). Workspaces that
  their compile time makes run too. At most 16 workspaces, 15 files each,
  32 different files in all.
- `make cws`: `progs/cws.ff` builds `chello` for riscv64 and x86_64 and
  `cexit` by its default name, each byte for byte what the command line
  makes, on every host, run from the build folder.
- **Not yet: Jai's message loop**, a hook in the build file that sees each
  compiled function or the finished output and can add to it while a
  workspace compiles (see NEXT.md).

### Targets

`ttpc --target <name> shared.ff prog.ff out` (riscv64 without it) builds
for riscv64, x86_64, aarch64 or arm. ttpc itself runs on any of them (see
Bootstrap): the one it was built for is its *host* (`host_name` of that
section), what --target names the *target*.

- **The shared page** (`shared.ff`, from `mkff.pl`): what every target has
  (`shared.ff.txt`: `byte` `half` `word` `dword`, `bits`, `rel`), then one
  **section** per target, a function whose children are **groups**
  (`registers:`, `integer:`, `float:`, ..., `macros:`, `elf:`, `linux:`,
  `c:`), each holding definitions (a node holds at most 255 children);
  comments may stand among the groups and the definitions. The
  instructions come from `isa/<target>.pl` (with `ISA.pm`), the rest from
  `macros/<target>.ff.txt`.
- **Choosing**: the shared page ends in a compile-time lambda, `if` /
  `target` / `==` / `riscv64` / `riscv64` / `else if` ... / `else` / `fail`.
  `target` is the section `--target` names (0 if there is none); calling a
  section while compiling puts its definitions in scope, like an include.
  A section, as a value, is its node.
- **Scopes**: the program is assembled with the target's definitions, then
  the shared ones; compile time with the host's, since it runs natively.
  The assemble-time ops (`exec`: `add` `addi` `slli` ... on `a0` `t0` `t1`)
  are always riscv64's: ttpc interprets them, on any host, so `bits`, `rel`
  and the slices work for every target.
- **Linux**: each section names its system calls, `SYS_write`, `SYS_exit`,
  ...; a C program says `syscall` / `SYS_exit` / n.
- **frame:**, `elf_header`, `elf_base`, `from_base` are per target (`elf:`).

#### The primitives of the C layer

ttpc's C layer is written once: it emits **primitives**, macros each target
defines in its `c:` group, called with numbers (or, for a register, the
name of a constant). Its machine: **V** the value (and what a function
returns), **L** the left operand, **X** a scale or a count, **FP** the
frame, **SP** the stack, whose **slot** is what a push takes. V, L, X are
registers of the target, named by the constants `cc_v` `cc_l` `cc_x` (their
numbers); L and X are not argument registers. Sizes never vary with the
operands: pass 1 and pass 2 must lay out the same.

| primitive | does |
|---|---|
| `cc_v` `cc_l` `cc_x` | constants: the register numbers of V, L, X |
| `cc_slot` | constant: bytes per push (8; 16 on aarch64, 4 on arm) |
| `cc_word` | constant: bytes of a `long` and an `address` (8; 4 on arm) |
| `cc_fixed` | constant: a bit per register C must not write (sp, fp, ...) |
| `cc_push` / `cc_pop` | SP -= slot, [SP] = V / L = [SP], SP += slot |
| `cc_drop n` | SP += n |
| `cc_spfp` | SP = FP + L |
| `cc_enter` / `cc_leave` | prologue (save the return address and FP, FP = SP) / epilogue and return |
| `cc_jz t` `cc_jnz t` `cc_jmp t` | to the address t if V == 0, V != 0, always |
| `cc_call t` | call the address t |
| `cc_global t` | V = the address t |
| `cc_text n` | V = the address right after this primitive, then go on n bytes further (the text in between) |
| `cc_li_pos v r` `cc_li_neg v r` `cc_li_big v r` | register r = v, for 0..2047, -2048..-1, anything |
| `cc_getreg r` `cc_setreg r` | V = register r / register r = V |
| `cc_addreg r` `cc_subreg r` | V = r + V / V = r - V |
| `cc_param i` | V = the i-th argument register |
| `cc_arg i off` / `cc_sysarg i off` | the i-th argument register of a call / of a system call = [SP + off] |
| `cc_syscall` | pop the number into the system call's register, make the call, V = its result |
| `cc_addfp` / `cc_addfp_l` | V += FP / L += FP |
| `cc_addx` `cc_mulx` `cc_mulx_l` | V += X, V *= X, L *= X |
| `cc_ptrdiff` | V = (L - V) / X |
| `cc_zero` | X bytes at L = 0 (X >= 1; L, X change) |
| `cc_bool` `cc_neg` `cc_not` `cc_inv` | V = V != 0, -V, V == 0, ~V |
| `cc_add` `cc_sub` `cc_mul` `cc_div` `cc_divu` `cc_rem` `cc_remu` `cc_and` `cc_or` `cc_xor` `cc_shl` `cc_shr` `cc_sar` | V = L op V |
| `cc_eq` `cc_ne` `cc_lt` `cc_ltu` `cc_gt` `cc_gtu` `cc_le` `cc_leu` `cc_ge` `cc_geu` | V = L op V, 1 or 0 |
| `cc_ext_i8` `cc_ext_i16` `cc_ext_i32`, `cc_ext_u8` `cc_ext_u16` `cc_ext_u32` | V = V as that type, sign- or zero-extended from its size (on arm the 32-bit ones are empty) |
| `cc_uw` | V and L zero-extended from 32 bits (empty on arm) |
| `cc_calll` | call the address in L, the arguments in their registers |
| `cc_load_i8` ... `cc_load_i64`, `cc_load_u8` ... `cc_load_u64` | V = the value at the address V, extended |
| `cc_store_8` ... `cc_store_64` | [L] = V |
| `cc_li_p lo hi`, `cc_push_p`, `cc_pop_p`, `cc_load_p`, `cc_store_p` | arm only, a pair (below): V = the two words, push V, pop L, V = [V], [L] = V |
| `cc_ext_p` `cc_ext_pu`, `cc_ext_lp` `cc_ext_lpu` | arm: V's (L's) word widened to a pair, with its sign or with zeros |
| `cc_add_p` `cc_sub_p` `cc_mul_p` `cc_div_p` `cc_divu_p` `cc_rem_p` `cc_remu_p` `cc_shl_p` `cc_shr_p` `cc_sar_p` `cc_and_p` `cc_or_p` `cc_xor_p`, `cc_eq_p` ... `cc_geu_p`, `cc_neg_p` `cc_inv_p` `cc_not_p` `cc_bool_p` `cc_addx_p`, `cc_jz_p t` `cc_jnz_p t` | arm: the operators on pairs, V = L op V (a compare gives an int) |

Every section also has `cc_ctargs`, `cc_call_l` and `cc_ctreg`, which only
compile time uses, on that host: the bridge from its code back into ttpc.

The targets' choices (see each `c:` group):

| | V L X | FP | slot, word | call arguments | system call |
|---|---|---|---|---|---|
| riscv64 | a0 t0 t1 | s0 | 8, 8 | a0..a7 | a7, a0..a5, `ecall` |
| x86_64 | rax r10 r11 | rbp | 8, 8 | rdi rsi rdx rcx r8 r9 r12 r13 | rax, rdi rsi rdx r10 r8 r9, `syscall` |
| aarch64 | x0 x9 x10 | x29 | 16, 8 | x0..x7 | x8, x0..x5, `svc 0` |
| arm (A32) | r0 r12 r8 | r11 | 4, 4 | r0..r7 | r7, r0..r6, `svc 0` |

**i64 and u64 on arm** are a pair of registers (gen/patches/pairs.pl, the
user's choice): their own type codes, 0x48 and 0x58 (the pair bit 0x40), 8
bytes aligned to 8 as the AAPCS has them, where elsewhere `i64` is `long`. V
is r0 (the low word) with r1, L is r12 with r9; a pair takes two slots on
the stack, the low word first, as in memory. The pair primitives may use
r2..r6, which hold nothing between primitives. r9 and r12 are free for it
because ttpc links the whole program itself: no veneers, no platform use of
r9. C's conversions widen the other operand of an operator, and the value of
=, a declaration, an initializer's item, return and a cast (`pwiden`,
`pwassign`, `fcvt`); a condition tests both words. In a call
(gen/patches/pairs2.pl) an argument is converted to its parameter's type
where the callee is known, and r0..r7 take the arguments in order, a pair
the next even pair (r0:r1, r2:r3, r4:r5, r6:r7, as the AAPCS aligns it); from
the first that does not fit, it and the rest are on the stack, all of them
pushed, as past 8 arguments. A variadic call pushes the count of its slots;
va_arg of a pair takes two. The result is V, r0:r1. / and % of pairs are a
shift-subtract loop in the primitive, as libgcc's __aeabi_uldivmod computes
them (gcc calls it; ttpc's program has no libgcc).

A division by zero is not the same everywhere (riscv64 and aarch64 give -1,
arm 0, x86_64 traps), nor a shift by the word size or more.

#### Known limits

- In a macro's arguments a label of the program comes before a constant of
  the target: a C variable named like a target constant (`hs`, `eq`, ...)
  hides it there. The primitives of the C layer use only numbers and
  register names, which C cannot take.
- Range checks know an operand's reach from the brackets of its slices, and
  sign only from the name `imm` (checked as signed, below bit 31): operands
  that are unsigned, or computed by fields of their own, are checked
  loosely or by naming tricks (x86's `reg'`, arm's `up[12]`).
- Register names in C stand for their numbers: only the general registers
  mean what they say (x86's `xmm4` is register 4, rsp, and refused; names
  starting with `f` are not C registers at all, a riscv64 rule).
- A node holds 255 children: a big program page is split into placed
  labels (the `wide` programs do).
- `shared.ff` holds all four targets (about 2.6 MB); every build reads it,
  and symbol lookup is linear.
