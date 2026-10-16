#

##
- de compiler moet in ff in sicompass komen
- ff is in een file:
RAM NODE:
  hash          byte[32]    // hash
  children_len  int8
  NODE        **children    // filled in AFTER load, not stored
  content_len   int8        // geen NULL termination! --> voor binaries
  char         *content
- ttpc wordt in ff geschreven, assembled in asm, moet bootstrappen
- kan je van asm ineens naar c like gaan in ff?

##
- het os in ff ttpc compileren
- ff samengesteld door disasm van voorbeeld os

##
- lycheepi 4a of zo, heeft geen signed boot
- usb opslaan van de code
- hd opslaan van code en binaries
- JIT of alles compileren? met libs voor elk object?

--> there is confusing as to what ttpc is, in build compiler and the asm --> see makefile

## !! compiler in riscv c met encode.c compileren --> binary --> decode.c aanpassen naar ff op sicompass met goede struct !!
## = bootstrap

## bootstrap: klaar (15 okt 2026)
- ttpc.s is stage0 en bevroren, ttpc.ff is de bron (in sicompass), `make bootstrap` moet groen blijven

## na de bootstrap (ttpc.ff assembleert zichzelf)
- Merkle hashes: sha256 in ttpc, de hashes van de nodes nakijken
- range checks op immediates: klaar (pass 2, in encode)
- de C-laag in ff-stijl en `compile time` (native, in ttpc zelf): klaar, zie PLAN.md
- conditionals en loops in exec context: `compile time` doet het nu; exec zelf blijft de seed
- ttpc.ff tegen 1 MiB (stage0): de versieketen, ttpc in de C-laag schrijven
- structs: per waarde zoals in C (16 okt 2026): `=` kopieert, een argument is een kopie (de callee kopieert van het adres dat hij krijgt), een resultaat gaat in ruimte die de caller bij het begin van zijn functie vrijhoudt; daaronder blijft het een adres
- includes / meerdere files: `import` klaar (zie build files); nog: secties als aparte segments, het os in ff
## targets (15 okt 2026)
- `--target riscv64|x86_64|aarch64|arm`: shared.ff heeft een sectie per target, de keuze is een compile time lambda op de gedeelde pagina
- de C-laag bestaat één keer: primitieven (`cc_push`, `cc_jz`, ...) per target in `c:`
- versieketen: ttpc1.ff bevroren (stage0 bouwt het), ttpc.ff + ttpc.defs.ff bouwt ttpc1
- nog te doen: i64/u64 op arm (registerparen), bereikcontrole per operand i.p.v. via namen, labels die constanten van een target verbergen, symbolen sneller opzoeken (shared.ff is 2.6 MB), ttpc zelf in de C-laag (dan ook ttpc voor andere targets)
## andere hosts (15 okt 2026)
- seeds `hosts/x86_64|aarch64|arm/ttpc.s`: ports van ttpc.s, byte voor byte gelijk (`make seeds`), enkel `OUT_SIZE` 1 MiB
- `make bootstraps`: per host seed -> stage1 == stage2 == de riscv64-keten met --target, zonder riscv64; de C-programma's draaien
- ttpc.ff blijft RV64: `mkhost.pl` maakt er `rv.<op>` van, `rv64:` per host; ttpc1 enkel op riscv64 (zijn C-laag is RV64)
- nog te doen: echte aarch64/arm hardware (cache flush van compile time is enkel onder qemu getest)
- riscv64 in dezelfde vorm (16 okt 2026): `hosts/riscv64/ttpc.s` (stage0), `progs/riscv64/` (exit42, hello, wide)
## build files (16 okt 2026)
- `ttpc build.ff`: een build file zoals in Jai, alles staat in de file: `import` / shared.ff, `workspace`, `set target`, `set output`, `add file`, `compile` (zie PLAN.md, `progs/cws.ff`)
- de workspaces lopen na de build file, één na één, elk als een eigen compile; de bomen die de build file las blijven in het geheugen
- `import` / pad vooraan op een programmapagina, ook in gewone programma's (`ttpc prog.ff out`); elk pad wordt één keer gelezen
- paden in een boom zijn vanuit de map van die boom (import, add file, set output), dus `ttpc src/compiler/progs/cws.ff` werkt vanuit elke map; paden op de command line vanuit de huidige map; "cannot open file" noemt de file
- `ttpc --print tree.ff` drukt een boom af (vroeger: één boom zonder out)
- opgelost: een lambda die liep terwijl een andere geassembleerd werd, kwam ook in diens splices terecht (`cct2`)
- ttpc.ff groeit: arm `whole.ff` is 859 KB van de 1 MiB die de seeds lezen; de pagina van ttpc.ff heeft 248 van de 255 kinderen (mkhost voegt er 4 toe), nieuwe code gaat in groepen zoals `cc:`
- nog te doen, stap 2, de message loop van Jai: compile time code die de compile van de build file overleeft. Daarvoor moet compile time een eigen code-ruimte krijgen in plaats van `outbuf` (die elke compile overschrijft), en moeten de passes van ttpc aparte, oproepbare stappen worden. Dan kan een workspace een hook noemen die elke gecompileerde functie of de afgewerkte output krijgt en er subtrees aan kan toevoegen, zoals `add_build_string` in Jai.
## expliciete types (16 okt 2026)
- een declaratie moet een type hebben, niets wordt afgeleid; een type is een rij bladeren als broers (`address` / `char`, `array` / `int` / `4`), een conversie heeft het eerste woord bovenaan; `type` (de T van C++) enkel in compile time; heel de taal staat in `language.ff.txt`
- zelf beslist, na te kijken:
  - tekst als argument is `address` / `char` / tekst (vroeger `char` / tekst)
  - een `array` / `char` / n gevuld met tekst (C's `char s[16] = "hi"`) kan nog niet
  - een compile time functie heeft geen returntype, haar waarde is een `long`
  - een workspace is een `long`: `w:` / `long` / `workspace`
- opgelost (16 okt 2026, `progs/cself.ff`): een struct met een adres van zichzelf liet ttpc crashen. Elke struct heeft nu één type, gemaakt vóór zijn velden: het veld `next` vindt het en de layout eindigt (en een veld opzoeken legt de struct niet meer telkens opnieuw uit)
  - waarom het telt: zo maak je lijsten, bomen, grafen; de gelinkte lijst van C, `struct node { long value; struct node *next; }`, is in ff:
    ```
    node:
      struct
      value:
        long
      next:
        address
        node
    ```
    `node` is de naam van de struct, `next` het adres van de volgende `node`. ff zelf is zo'n boom: NODE heeft `children`, adressen van andere NODEs; ttpc of sicompass in de C-laag heeft dus een veld als `children:` / `address` / `address` / `node` nodig
  - waarom het crasht: voor de layout van `node` leest ttpc zijn velden (`struct` -> `fields`), bij `next` lost het het type `node` op, dat opnieuw zijn velden leest, zonder einde
  - de oplossing: een adres is altijd één woord, wat het ook aanwijst; achter `address` moet een struct dus niet opgelost worden, enkel benoemd. De velden pas opzoeken wanneer een pad ze gebruikt (`p` / `next` / `value`)
## glibc.ff (16 okt 2026)
- plan: ~/.claude/plans/how-to-incorporate-the-wild-rocket.md: glibc's eigen C (een vaste release, de `.i` van zijn build voor riscv64) mechanisch in de C-laag (c2ff.pl op clang's AST), enkel wat een programma bereikt; exact = AST round trip + hetzelfde gedrag als gcc met libc.a
- fase 0, eerst de C-laag afwerken, stap 1 klaar: C's rekenregels (`progs/cint.ff`, `cint64.ff`): int en u32 wrappen op 32 bits (`cc_ext_*` na de operator), de usual arithmetic conversions, getallen getypeerd zoals in C; een operator vooraan in een lambda (`:` / `-` / ...) is een expressie, geen call
- fase 0 stap 2 klaar: for, do while, switch / case / default, goto en labels (`naam:` zonder type, houdt zijn statements), if / else als waarde (C's ?:), de komma is een lambda (`progs/cflow.ff`)
- fase 0 stap 3 klaar: *= /= %= &= |= ^= <<= >>= (via binop, ook += -=), sizeof / alignof, enums (`kleur:` / `enum` / `rood:` ...), function types (`binary:` / `function` / ...) en calls via een adres (`progs/ctypes.ff`)
- fase 0 stap 4 klaar: een struct met een adres van zichzelf
- fase 0 stap 5 klaar: unions (`naam:` / `union`), bitfields (`mode:` / `u32` / `3`, zoals gcc ze legt: nagekeken met riscv64-none-elf-gcc), `progs/cunion.ff`, `progs/cbits.ff`
- fase 0 stap 6 klaar: initializers: adressen (`address` / naam), teksten, `-` getal, `:` als expressie (compile time) of als de items van een struct, union of array erin; een globale wordt in een buffer gebouwd, een lokale eerst op nul gezet (`progs/cinit.ff`)
- fase 0 stap 7 klaar: meer dan 8 argumenten (de rest op de stack), structs per waarde (`progs/ccalls.ff`). De regel blijft: de eerste `naam:` met enkel een type zijn de parameters, een lokale vooraan heeft een waarde nodig
- fase 0 stap 8 klaar: varargs, `...` na de parameters en C's va_list, va_start, va_arg, va_end, va_copy (`progs/cvarargs.ff`, met een kleine printf); de caller duwt ook het aantal argumenten
- fase 0 stap 9 klaar: TLS, `thread local` vóór het type (`progs/ctls.ff`); met één thread is het een globale, echte blokken per thread komen met threads
- fase 0 klaar (16 okt 2026). `make decls` controleert dat elk woord, elke operator en elk type van ttpc op de gedeelde pagina gedeclareerd is: wat de editor als calls aanbiedt (zoals comment:, dat niets doet)
- versieketen (16 okt 2026): ttpc2.ff + ttpc2.defs.ff bevroren (ttpc.ff na stap 2, arm whole.ff 949 KB van de 1 MiB van de seeds). stage0 -> ttpc1 -> ttpc2 -> stage1 -> stage2; op elke host seed -> ttpc2 -> stage1 -> stage2. ttpc.ff mag nu alles wat ttpc2 kent (comment, de C-laag) en groeien tot 4 MiB invoer samen met shared.ff (2.8 MB)
