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
## glibc.ff, de pijplijn (16 okt 2026)
- flake.nix pint glibc-2.44 van ftp.gnu.org (narHash in flake.lock) en geeft de riscv64 cross gcc (zonder wrapper, GLIBC_CC), de kernel headers, bison, python3 en clang zonder wrapper (C2FF_CLANG)
- `make -C src/glibc glibc-ref` bouwt de referentie-glibc in ~/.cache/ttp/glibc (niet in Dropbox: die hernoemt stamp.os naast stamp.oS); `src/glibc/mki.pl` maakt de .i van een object met zijn commando uit build.log en -E
- de C-laag compileert C van een geïmporteerde boom als het programma ze bereikt (`progs/clib.ff`): wat glibc.ff nodig heeft
- gekozen: multi-arch blijft (strlen e.a. kiezen bij het laden: ifunc met riscv_hwprobe, vector-asm of generieke C); ttpc krijgt `naam:` / `alias` / doel en `naam:` / `ifunc` / resolver; de resolvers lopen vóór `_start` met hwcap (auxv) en glibc's __riscv_hwprobe, zoals glibc's eigen opstart
- alias en ifunc in ttpc klaar (`progs/cifunc.ff`, `progs/cifunclib.ff`): de resolvers lopen vóór `_start` met (hwcap uit auxv, __riscv_hwprobe of 0, 0); qemu-riscv64 meldt V (ook met -cpu max), dus de resolvers kiezen daar de vector-asm: RVV is nodig; `-cpu rv64,v=false` test de generieke C. De LicheePi 4A (TH1520, RVV 0.7.1) meldt geen V
- nog te doen: de vector-instructies (RVV) in ttpc's riscv64 (de vector-asm van glibc); c2ff.pl (gen/c2ff.pl: de C-types zijn er, de rest nog niet); s2ff voor glibc's .S; M1 string
## glibc's strlen in ff (16 okt 2026)
- `gen/c2ff.pl` vertaalt glibc's C (clang's JSON AST van de .i, met `src/glibc/clang-prelude.h`) naar de C-laag: wat de wortels bereiken, over meerdere .i heen; typedef en typeof lost het zelf op, een anonieme struct of union van een typedef krijgt diens naam, glibc's syscall-idioom (registervariabelen en scall) wordt `syscall`
- de reach van `strlen` + `__riscv_hwprobe` (de alias, de ifunc en zijn resolver, de generieke C, glibc's hwprobe met zijn syscall, `_dl_vdso_riscv_hwprobe` uit dl-support) loopt: `make -C src/glibc strlen-check` geeft 12 met `-cpu rv64,v=false` en kiest met V de vector-variant (nog een stand-in die 99 geeft, in `src/glibc/progs/strlen.ff`, niet in glibc)
- daarvoor nieuw in ttpc: compound literals (`point` / 1 / 2), want glibc geeft NULL aan een transparent union
- c2ff liep 3 keer eindeloos (een typedef die naar zichzelf wees) en legde de machine plat: alles draait nu met een geheugenlimiet en timeout, ctype heeft een dieptegrens
- RVV 1.0 in ttpc's riscv64 (`isa/riscv64.pl`, groep `vector`: vsetvli, laden en opslaan, vergelijken, rekenen, reducties, maskers, vmv, vfirst/vcpop) en `csrr`: `progs/riscv64/rvv.ff` met GNU-tweeling `rvv.s` (beide uit `mkrvv.pl`, 146 instructies, met en zonder v0.t), `make rvv`
- asm-functies in de C-laag: `naam:` / `asm` / instructies, geplaatst als asm, op een definitiepagina alleen als C ze bereikt; C roept ze aan en neemt hun adres (`progs/casmfn.ff`)
- `gen/s2ff.pl` vertaalt glibc's .s (mki.pl maakt die nu ook van een .S) naar asm-functies: elke instructie één op één, en waar GNU as een gecomprimeerde koos (te zien in zijn objdump zonder relaxatie) dezelfde c.*; `make -C src/glibc asm-check`: ttpc maakt dezelfde 38 bytes als glibc's compiler voor `__strlen_vector`
- `make -C src/glibc strlen-check` geeft nu ook met V 12: de resolver kiest glibc's eigen vector-asm (de stand-in is weg)
- M1 klaar: strlen, memcpy, memset, strcmp en strchr, elk zijn ifunc, generieke C (met wordcopy en strchrnul) en asm (vector; memcpy ook zonder alignment); `make -C src/glibc string-check`: progs/string.c met gcc + libc.a en via `c2ff --program` met ttpc + glibc in ff geven met en zonder V dezelfde 38; `asm-check`: alle zes asm-delen byte voor byte gelijk
- daarvoor nieuw: in c2ff for, switch/case/default, labels en goto, x++ als waarde; in s2ff constante expressies en .attribute; in ttpc `++ x` vóór de naam (C's ++x), `x ++` met de oude waarde (C's x++, keuze van de gebruiker), en `:` om één lvalue
- zonder V kiest memcpy's resolver onder qemu memcpy_noalignment (qemu meldt snelle misaligned toegang), dus progs/string.c roept ook `__memcpy_generic` zelf aan: zo loopt ook de generieke C (wordcopy, met goto in de lus)
- M2 stdlib (atoi, strtol, abs; qsort wacht op malloc, het bereikt het): `make -C src/glibc stdlib-check` vergelijkt progs/stdlib.c (gcc + libc.a: 120); de milestones zijn nu templates (string, stdlib), elk met de vorige erin
- daarvoor nieuw in de C-laag, elk met een test: `cast:` / type / waarde (C's cast) en onder address char is een blad tekst (keuze van de gebruiker); `.` in de kinderen van een knoop voor een pad van een expressie; `items`-groepen voor lijsten langer dan 255 (ook enum-constanten); tekstbladen op rij vullen een char-array; adresconstanten in globals (cast, + N, adres van een pad), flexibele array-leden; OUT_SIZE 16 MiB; een `:` in een global zonder de programmapagina gejit
- daarvoor nieuw in c2ff: alle C-escapes, tekst of bytes voor char-arrays (ff-tekst is UTF-8), groepen, `.`-paden, __extension__, __builtin_constant_p, __builtin_mem*/str* als aanroep, anonieme enums/structs naar hun plaats, geneste tags, aliassen van variabelen, enum-waarden, array_filler, lokale extern, -fgnu89-inline
- M2 klaar: atoi, strtol en abs: `make -C src/glibc stdlib-check` geeft met en zonder V 120, net als gcc + libc.a; de reach loopt via de C-locale door gconv, assert, abort, signalen, pthread en tunables (45 C-objecten, 12 asm-delen, alle byte voor byte gelijk in asm-check)
- daarvoor nieuw in ttpc: `weak` (ook functies: weak / function / type), `va_arg_pack`, if zonder body (a ?: b), asm-functies die bereiken wat ze noemen, floating point op riscv64 (float, double, long double als types; + - * /, vergelijkingen, -, cast:), grotere buffers (invoer 32 MiB, knopen 64 MiB)
- daarvoor nieuw in c2ff/s2ff: groepen per bron (glibc string/strlen, ...), libatomic-aanroepen (atomics.ff.txt uit mkatomics.pl), builtins.ff.txt, getypte literals (2UL is u64 / 2), hex floats, wide literals, ... na de parameters, syscall-stubs, tail/call/li, numerieke labels, val-door tussen functies, la.tls.ie
- floating point op alle doelen en long double: zie hieronder
- daarna M3 (malloc, free, realloc) en qsort, dat malloc bereikt
- het adres van een ifunc (`address` / memcpy) geeft nog "needs a type"
## bouwtijd (17 okt 2026)
- de glibc-checks gebruiken op een x86_64-machine ttpc's eigen x86_64-build (TTPC_RUN, door make bootstraps gemaakt), die native loopt; elders riscv64's onder qemu; beide maken dezelfde bytes
- geprofileerd met perf (perf en gdb staan in flake.nix): 99% van de 32 miljoen lookups (kwof, opof, tyname) kwam uit enumlib, dat voor elke naam alle syms afliep (defkw) op zoek naar de 14 enums
- nu: lookup, find_fn, find_reg en enumlib hebben een cache van hun antwoord, met als sleutel de bytes van de naam (tot 32, in het item; een langere naam gaat zonder cache), de lengte en de tabel of het bereik; niet de knoop of het adres van de tekst, want prim_node, prim_text en knopen op de stack krijgen andere namen (de eerste cache op de knoop gaf in cdot "unknown name: x"); enumlib vraagt daarachter alleen de enums van syms, een lijst die het na collect_syms één keer maakt
- stdlib-prog: 17,7 s native (5 minuten onder qemu) wordt 1,6 s (6,1 s onder qemu), dezelfde bytes; `make -j` werkt: compiler-check 20 s, met -j6 12 s; string-check en stdlib-check samen 2 s
## floating point overal (17 okt 2026)
- x86_64 (SSE2: xmm0 L, xmm1 V; naar en van u64 met halveren en de sticky bit, of min 2^63) en aarch64 (s16/d16, s17/d17; fcmp en cset met mi en ls voor < en <=) hebben de 33 primitieven van riscv64
- arm: een float in een woord (VFP s14, s15); een double is groter dan een woord en staat in het geheugen, zoals een struct (keuze van de gebruiker): V is zijn adres, de primitieven cc_fadd_dm ... laden d6 en d7 en schrijven in een tijdelijke plaats in het frame (X + fp)
- long double (16 bytes) staat overal in het geheugen; + - * /, vergelijken, - en de conversies roepen soft-fp aan, zoals gcc libgcc aanroept (__addtf3 ... __trunctfdf2, keuze van de gebruiker: glibc's soft-fp)
- in de C-laag: inmem (struct, of een floating type groter dan een woord) waar isstruct over de waarde ging; een functie die zo'n type noemt (wgate: het woord, of een global of functie ervan) reserveert 16 bytes per operator, cast:, floating literal en declaratie met waarde (wcount, in tscan); wtemp stopt met een melding als dat niet zo is
- tests: progs/cfloats (mkcfloats.pl: 233 waarden tegen Perl's IEEE, rond 2^63, NaN, -0, afronding met de sticky bit) op de 64-bit-doelen, cfloats32 (228, zonder u64) ook op arm; een mutant zonder sticky bit faalt
- glibc: milestone ldouble, 16 bestanden van glibc's soft-fp (mki.pl maakt hun .i met het commando van libm's e_sqrtl, in libc en zonder __SIZEOF_INT128__: u128 is dan glibc's eigen twee woorden); `make -C src/glibc ldouble-check`: progs/ldouble.c (39 resultaten, hun bits gehasht) geeft 115, net als gcc + libc.a + libgcc
- daarvoor in c2ff: asm-statements (de tekst uit de .i, operanden in registers) worden asm-functies (CSR's: frrm, csrs fflags, ...), __label__, lokale struct/union, bitfields met hun breedte (die ontbraken!), case-bereiken (case 1 ... 63), long double-operaties bereiken hun soft-fp-functie, long double literals die een double exact is
- daarvoor in ttpc: case lo ... hi; een global met een getypte literal (u64 / 2) is een variabele (was een functie); het masker van een bitfield van 64 bits (1 << 64 is 1 op RV64)
- mki.pl verloor alle commando's na regel 13738 van build.log (een (echo ...) > bestand-blok zonder ) | gcc); een blok eindigt nu bij de eerste regel zonder backslash
- ttpc2 leest 4 MiB: trim.pl geeft het shared.ff met alleen de secties waarmee het assembleert (de andere leeg); stage1 == stage2 bewijst dat het niets verandert
- bekend, al eerder zo: compile time's emit van target-instructies vindt onder een andere host (native x86_64 ttpc, doel riscv64) alleen de instructies van de host als een functie twee compile-time-blokken heeft (jit compileert de pagina opnieuw); asm-functies hebben dat probleem niet
- nog te doen: long double op x86_64, aarch64 en arm (soft-fp voor die doelen: glibc in ff is riscv64), globals van long double met een waarde, va_arg van een double op arm
## M3 malloc (18 okt 2026)
- M3 klaar: malloc, free, realloc, calloc en qsort: `make -C src/glibc malloc-check`: progs/malloc.c (200 blokken van veel groottes, gaten, realloc groter en kleiner, 1 MiB boven de mmap-drempel naar 3 MiB, calloc's nullen, qsort van 1000 longs; gehasht wordt de inhoud, nooit een adres) geeft met en zonder V 108, net als gcc + libc.a; de reach: 96 C-objecten, 19 asm-delen, alle byte voor byte gelijk in asm-check
- glibc's opstart blijft weg, maar malloc heeft er twee stukken van: `_start` zet tp op een blok `__ff_tcb` (THREAD_SELF ligt onder tp, SINGLE_THREAD_P leest daar) en roept met `c2ff --program --early` (EARLY in de Makefile) `__libc_early_init (1)` op, dat ctype, de single-thread-vlag, pthread's standaarden en getrandom zet en `__ptmalloc_init` roept
- daarvoor in c2ff: OffsetOfExpr (het pad uit de .i), asm-statements met geheugenoperanden (A, m: het adres als argument) en `+r`, lr/sc en amo* met .aq/.rl; een aanroep via een pad (p->f (x)); lokale enums en structs, lokale statics als globals "fn naam"; registervariabelen (`__thread_self` is tp); een tag die een lokale, een variabele of een functie heet wordt "naam struct"; de builtins popcount, ctz, bswap, stdc_*, add/mul_overflow
- daarvoor in ttpc: een functie-adres langs een pad aanroepen (`p` / add / x / y; test progs/cpath.ff); cast: en een lege : maken van een library-item een global (tcache, main_arena waren functies); elke global eindigt op 8 bytes (een global van één byte zette de code erna op een oneven adres: SIGILL)
- bouwtijd: c2ff bewaart elke AST naast zijn JSON als Storable (x.sto; JSON::PP leest 2,7 MB/s, Storable 50 keer sneller): een milestone in c2ff 6,5 s in plaats van minuten; `--store` maakt alleen de cache, de Makefile doet dat na clang, zes tegelijk met -j6
- nog te doen: arrays van functie-adressen in c2ff's ctype (`int (*[2]) (int, int)`); daarna M4 stdio (printf zonder floats, puts)
