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
- structs: geen kopie per waarde, als parameter enkel via address
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
- nog te doen: echte aarch64/arm hardware (cache flush van compile time is enkel onder qemu getest), riscv64 ook als host in dezelfde vorm (`hosts/`, `progs/riscv64/`)
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
- nog te doen: een struct met een adres van zichzelf laat ttpc crashen (was al zo vóór de expliciete types)
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
