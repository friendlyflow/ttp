# HANDOFF: lane A-x86 (all of glibc in ff, x86_64). Last increment: s2ff for x86_64 (done). Read this first.

You are a fresh agent continuing this lane. Work ONLY in ~/.cache/ttp/wt/a-x86 (branch ff/a-x86, pushed).
ttp: ff is the user's own language (a tree format plus a C layer, compiled by ttpc). glibc's C goes to ff via
src/compiler/gen/c2ff.pl, its .S via s2ff (byte-exact to GNU as), checked against gcc + libc.a, natively on x86_64.

## Safety first
Merge origin/ports before any heavy command:
`git -c merge.ff.driver='sh src/compiler/gen/ffmerge.sh %O %A %B %P' merge origin/ports`.
Ports has the memory caps: slot.sh runs each slotted command in a systemd scope inside ttp.slice (18G total), nesting past 8 stops, glibc JOBS is 4. Every heavy step goes through slot.sh; never `-j$(nproc)`; never write into ~/.cache/ttp/glibc-gcc16 or ~/.cache/ttp/glibc. `make ports-check` now builds in a folder of the worktree's own by default.

## State (2026-10-20, after the s2ff increment)
- **In ports from this lane:** char signed on x86_64 (TY_SCHAR 65); the generic C set (fnaddr, vlasize, arraylit, paths, builtins); groupdot; asm functions placed at `align` / n (the user's choice A); the GNU as forms of src/compiler/x86_64gnu.ff (gen/mkgnuff.pl, isa/x86_64gnu.pl, the user's naming scheme mnemonic.length.encoding.marks.operands).
- **Done here (ff/a-x86: commit 181e659, and the HANDOFF commit after it):**
  - **s2ff for x86_64:** src/compiler/gen/s2ffx86.pm, called by s2ff.pl for an elf64-x86-64 dump. Driven by the .s (labels, sections, `.macro`/`.rept`/`.if` expanded). For each instruction it takes, of the forms whose GNU line is the instruction (isa/x86_64.pl's own and isa/x86_64gnu.pl's), the one whose bytes equal GNU's. The bytes come from the form's own definition in ttpc's section, evaluated in Perl: bit fields, slices, range checks; labels match any byte.
    - Alignment nops are kept as their forms (`cs nopw` is data16, cs, nopl). An aligned function has `align` / n first; the first function of a file gets the section's alignment.
    - Prefixes, segments (`%fs:`) and 32-bit addresses (addr32) are calls of their own.
    - `sym@GOTPCREL` / `sym@GOTTPOFF` read `.Lgot` / `.Ltls` words the function carries. A `.Ltls` word is the symbol's address: on x86_64 a thread local is still a global and fs is 0.
    - A function that jumps into the next asm function's blocks takes that function in as an entry, across aliases. `--align` gives the first function's alignment.
  - **asm-check on x86_64** (src/glibc/Makefile): the code's own section (codesec: .text.avx2 ...); relmask.pl knows x86_64's relocations; ASMTRAP int3; ASMHDR 120, rounded up to the first function's alignment; the .s must make glibc's own object. ASMCHECK_x86_64 is ALL_ASM minus ASMSKIP_x86_64, which lists the skipped objects by reason. `asm-x86_64` is in `make ports-check`.
  - **New forms:** EVEX vmovd/vmovq (xmm16+), masked stores of the EVEX moves, and EVEX vbroadcastss. `make x86gnu` agrees on all 15184 forms. x86_64gnu.ff now has ttp's license at its root and is in `make licenses`.
- **all-asm: 335 of 756 asm objects byte for byte** (331 of the 370 outside libmvec; `make ports-check` all PASS on 2026-10-20, asm-x86_64 checking those 331, mostly waiting on slots: 31 min). The rest, by reason:
  - libmvec (mathvec/, 382): no forms yet for SSE/AVX packed floats (mulpd, addpd, vfmadd213pd, vinsertf128, vmovupd, movsd/movss, andps.n, vgetmantpd {sae} ...); most also have .rodata tables.
  - Data in another section (30): .rodata constants (strcasecmp's vectors, libm's long double constants), jump tables of label differences (`.int .LExit1 - .LExitTable`: strcpy-sse2-unaligned and kin, strcmp-sse2/sse4_2), a string (____longjmp_chk).
  - Other (9): crti/crtn (.init/.fini); csu/start (stays c2ff --start); jrcxz (add_n, sub_n: no rel8 form, and mkgnu has no label8 values for the twin); `leaq (, %rdx, 4)` with no base (wcsncmp-avx2, -rtm); `sym+352(%rip)` (dl-trampoline: no ff for an address plus an offset).
- **The C ABI:** cc_abi (A-arm's) is in ports. x86_64 still uses ttpc's own convention, so start.S stays under c2ff --start.

## Next
1. SysV ABI for x86_64 on cc_abi (as A-arm did for arm), so C calls glibc's asm and asm calls C.
2. x86_64 startup: start.S through s2ff (its GOTPCREL call), crti/crtn (two sections, as aarch64's --then); fs TLS (cc_tls 1 on x86_64, a PT_TLS image, arch_prctl, a variant II tprel; then s2ff's `.Ltls` words become tprel / sym); cpu_features and the ifuncs (init_cpu_features, the multiarch resolvers picking sse2/avx2/evex).
3. The milestones on x86_64 (string stdlib malloc stdio floats args, as LINKED_aarch64), with their asm, and their round trips.
4. c2ff: the user's `fs` type word (a %fs-relative pointer) and `vector` types (__m128i ... for the C of the ifunc'd string functions).
5. Smaller s2ff gaps: data sections (these need the user's words for a label difference, `.LExit1 - .LExitTable`, and for sym+offset); jrcxz.8 (a form in isa/x86_64.pl, where mkwide has label8); lea with no base; then libmvec's packed-float forms (the bulk: 382 objects).

## Rules
- **Paths:** always `cd ~/.cache/ttp/wt/a-x86 &&` inside each command, because the cwd may reset.
- **Syntax:** any new user-facing syntax is the user's choice, via the master, with 2-4 options as node lines.
- **Others:** two other lanes (riscv64 glibc tests, T1 tools in ff) run at the same time; share the slots.
- **Reporting:** report only at blockers, questions and READY. Be honest about failures.
- **Commits:** no Co-Authored-By. Push your branch only.
