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
- includes / meerdere files, secties als aparte segments, het os in ff
## targets (15 okt 2026)
- `--target riscv64|x86_64|aarch64|arm`: shared.ff heeft een sectie per target, de keuze is een compile time lambda op de gedeelde pagina
- de C-laag bestaat één keer: primitieven (`cc_push`, `cc_jz`, ...) per target in `c:`
- versieketen: ttpc1.ff bevroren (stage0 bouwt het), ttpc.ff + ttpc.defs.ff bouwt ttpc1
- nog te doen: i64/u64 op arm (registerparen), bereikcontrole per operand i.p.v. via namen, labels die constanten van een target verbergen, symbolen sneller opzoeken (shared.ff is 2.6 MB), ttpc zelf in de C-laag (dan ook ttpc voor andere targets)
