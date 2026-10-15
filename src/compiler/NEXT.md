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
- ttpc.s is stage0 en bevroren, ttpc.ff.txt is de bron, `make bootstrap` moet groen blijven

## na de bootstrap (ttpc.ff assembleert zichzelf)
- Merkle hashes: sha256 in ttpc, de hashes van de nodes nakijken
- range checks op immediates (tot dan vangt de GNU oracle overflow)
- conditionals en loops in exec context (li die zelf zijn expansie kiest)
- native exec in plaats van de seed tabel (addi, slli, ...)
- includes / meerdere files, secties als aparte segments, het os in ff