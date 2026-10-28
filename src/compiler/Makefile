# ttpc is plain RISC-V assembly, no libc: a static Linux riscv64 executable
# that only makes raw syscalls, built from hex0 (the hex seed, lane H, see
# HEXHOSTS) or with SEED=gnu assembled and linked by the bare-metal cross
# binutils, which also check the hex seed. On riscv64 it runs natively,
# elsewhere under qemu-riscv64. Without the cross binutils (no Nix) a
# host's own as and ld do for it.
ARCH := $(shell uname -m)
have = $(shell command -v $(1) 2>/dev/null)
native_or = $(if $(call have,$(2)as),$(2),$(if $(filter $(1),$(ARCH)),,$(2)))
CROSS   ?= $(call native_or,riscv64,riscv64-none-elf-)
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS ?= -march=rv64imac -mabi=lp64 -mno-arch-attr
QEMU    ?= $(if $(filter riscv64,$(ARCH)),,qemu-riscv64)

# The GNU twins of the ff programs (progs/riscv64/*.s): every extension ff
# encodes, no relaxation, linked with ff64.ld into ttpc's layout.
TWIN_ASFLAGS := -march=rv64imafdcv -mabi=lp64 -mno-relax
TWIN_LDFLAGS := --no-relax --no-warn-rwx-segments -T ff64.ld

# The Nix ld-wrapper injects -z relro / -z now hardening, which this static
# no-libc binary has no use for (ld warns). A non-Nix ld ignores this.
export NIX_HARDENING_ENABLE :=

# Everything built goes under the build folder of the repository.
BUILD ?= ../../build/compiler

BIN := $(BUILD)/ttpc

# The ff sources, edited in sicompass. ttpc is a program of only its own,
# ttpc.ff, with its constants in ttpc.defs.ff, on the shared page
# (shared.ff, from tools/mkff.ff: make refresh): ttpc --target riscv64 shared.ff ttpc.defs.ff
# ttpc.ff out. A C program is its program alone too: ttpc shared.ff prog.ff
# out. ttpc1.ff (the frozen ttpc of the chain) and the asm programs in
# progs/riscv64/ are whole trees (the shared pages of then, their own; the
# last page is what ttpc assembles); progs/riscv64/<name>.s is the GNU twin
# of one.
TTPC_FF := ttpc.ff
TTPC_SRC := shared.ff ttpc.defs.ff ttpc.ff
TTPC1_FF := ttpc1.ff
TTPC2_SRC := ttpc2.defs.ff ttpc2.ff
TTPC3_SRC := ttpc3.defs.ff ttpc3.ff
PROGS := exit42 hello wide
CPROGS := cexit cfib cloop chello cexpr cstruct cnow cct cct2 cunroll ctasm ctmix celse casm casm2 casmfail cstring cscope cint cint64 cflow ctypes cself cunion cbits cinit ccalls cvarargs ctls clib cifunc cifuncaddr cifunclib ccomplit casmfn cincdec cparen cdot cgroups ccast caddrc cweak cifvalue cvapack cfloat cfloats cfloats32 cgnu cpath ccond clabels calloca caddrlit canon casmentry cloopsp cvamem cnullary clayers clayerslib clazy ctlstp cpair cpaircall cpairmul cchar cfnaddr cvlasize carraylit clicense calign cldlit cgroupdot casmalign ccomplex cbodylayers cgeneric csection creach cldneg ctextitem cemptyitem cctor cnarrowret cdatasep cenumtype ctlitstmt calignattr ccleanup chexinf cvaptr cdebug cline cldalign cglobroom cwidestmt clocalign32
SHARED := shared.ff
# the forms GNU as picks for x86_64, for its asm alone (gen/mkgnuff.pl)
X86GNU := x86_64gnu.ff
WHOLE := $(TTPC1_FF) $(PROGS:%=progs/riscv64/%.ff)
TREES := $(WHOLE) $(SHARED) ttpc.defs.ff $(TTPC_FF) $(TTPC2_SRC) $(TTPC3_SRC) $(filter-out $(WHOLE) progs/clazylib/never.ff,$(wildcard progs/*/*.ff)) $(wildcard tools/*.ff) $(wildcard isa/*.ff) $(CPROGS:%=progs/%.ff) progs/cnowfail.ff progs/creserved.ff progs/cmisplaced.ff \
	progs/cws.ff progs/cinclude.ff progs/cwsnofile.ff progs/cwsplace.ff progs/cincludelate.ff \
	progs/clibdefs.ff progs/cpathdefs.ff progs/cifuncdefs.ff progs/casmfndefs.ff progs/casmaligndefs.ff progs/casmentrydefs.ff progs/cweakdefs.ff progs/clayerslibdefs.ff progs/cuntyped.ff progs/citems.ff progs/cchartext.ff progs/ctypeout.ff progs/cbelow.ff progs/creachdefs.ff progs/ctextitemdefs.ff progs/cctordefs.ff language.ff
P := $(BUILD)/progs

# The trees as the frozen ttpcs read them (stage0 and the seeds of the
# hosts, ttpc1, ttpc2, ttpc3): without their licenses, a word younger than
# they are, and in the C words of before (tools/unlicense.ff, as
# gen/unlicense.pl). A license emits nothing, so what they make is the same;
# stage1 makes stage2 from the trees with their licenses, and stage1 ==
# stage2 checks it. The unlicense that makes them is ttp's own, in ff:
# ttpc3 compiles it from tools/old/ (below), so no Perl is in the chain.
BOOT := $(BUILD)/boot
NL := $(BUILD)/nl
$(NL)/%.ff: %.ff $(BOOT)/unlicense
	@mkdir -p $(dir $@)
	$(QEMU) $(BOOT)/unlicense $< > $@.tmp && mv $@.tmp $@

# What the links before ttpc3 read, and ttpc3 reads the tools in, committed
# (each a copy of what ttp's tools make of a source, without its license
# root: its license is in LICENSES; copies-check checks that the ff tools and
# the Perl make each of them, and `make copies` makes them again after its
# source changed):
#   boot/riscv64/shared.ff  ttpc1's shared page (linking ttpc2): shared.ff
#                           unlicensed, trimmed to riscv64, frozen
#   boot/riscv64/shared1.ff ttpc2's (ttpc2.self, ttpc3) and ttpc3's when it
#                           compiles the tools: unlicensed, trimmed to riscv64
#   boot/<host>/shared1.ff  the same on a host: trimmed to riscv64 and it
#   boot/<host>/ttpc2.ff, ttpc2.defs.ff, ttpc3.ff, ttpc3.defs.ff
#                           ttpc2 and ttpc3 for a host (mkhost <host>), which
#                           the host's seed and ttpc2 read before its ttpc3
#   boot/<host>/whole.ff    the whole tree of the host's ttpc2 that its seed
#                           assembles (mkwhole <host> of mkhost's ttpc2)
#   tools/old/<tool>.ff     ttp's tools in the C words of before, which ttpc3
#                           reads (unlicense -t OLDTYPES tools/<tool>.ff)
HOSTBOOT := ttpc2.ff ttpc2.defs.ff ttpc3.ff ttpc3.defs.ff whole.ff
BOOTCOPY := boot/riscv64/shared.ff boot/riscv64/shared1.ff $(foreach h,x86_64 aarch64 arm,boot/$(h)/shared1.ff $(HOSTBOOT:%=boot/$(h)/%))
OLDTOOLS := rt sha256 fftree words unlicense mk mkhost
OLDLIB := $(foreach t,rt sha256 fftree words,tools/old/$(t).ff)
OLDMK := $(OLDLIB) tools/old/mk.ff
OLDTYPES := $(foreach t,rt sha256 fftree words mk,-t tools/$(t).ff)
COPIES := $(BOOTCOPY) $(OLDTOOLS:%=tools/old/%.ff)

all: $(BIN)

$(BUILD) $(P):
	mkdir -p $@

# Print the tree of ttpc.ff, or of FF=<file>.
FF ?= $(TTPC_FF)
test: $(BIN)
	$(QEMU) $(BIN) $(FF)

# ttpc assembles a program, its listing goes to <name>.lst.
$(P)/%.elf: $(NL)/progs/riscv64/%.ff $(BIN) | $(P)
	$(QEMU) $(BIN) $< $@ > $(P)/$*.lst

$(P)/%.twin.bin: progs/riscv64/%.s ff64.ld | $(P)
	$(AS) $(TWIN_ASFLAGS) $< -o $(P)/$*.twin.o
	$(LD) $(TWIN_LDFLAGS) $(P)/$*.twin.o -o $(P)/$*.twin
	$(OBJCOPY) -O binary $(P)/$*.twin $@

.SECONDARY:

# Every tree must read back to the same bytes from its text form (which
# also checks its hashes).
roundtrip: | $(BUILD)
	@for t in $(TREES); do \
	    perl gen/fftext.pl txt $$t > $(BUILD)/roundtrip.ff.txt && \
	    perl gen/fftext.pl ff $(BUILD)/roundtrip.ff.txt | cmp - $$t || exit 1; \
	done
	@echo "roundtrip: $(TREES)"

# Every tree has its license at its root (license / SPDX expression / the
# notice, a line per child), its SPDX ids known to gen/spdx.txt; the frozen
# files, which stay as they are, have theirs in LICENSES. A tree with an
# unknown id fails. licenses is tools/licenses.ff, built by stage2 ($(CT),
# see TOOLLIB); gen/licenses.pl, the second implementation, gives the same
# in tools-check. The rules of decls and licenses are after CT.
LICENSED := $(TREES) $(COPIES) $(X86GNU) shared.ff.txt $(wildcard macros/*.ff.txt) language.ff.txt gen/license.ff.txt

# Every program, after its 120-byte ELF header, must be byte-identical to
# its GNU twin.
check: roundtrip decls $(PROGS:%=$(P)/%.elf) $(PROGS:%=$(P)/%.twin.bin)
	@for p in $(PROGS); do \
	    tail -c +121 $(P)/$$p.elf | cmp - $(P)/$$p.twin.bin || exit 1; \
	    echo "check: $$p: ttpc and GNU as agree"; \
	done

# The programs that run do what they should.
run: $(P)/exit42.elf $(P)/hello.elf
	$(QEMU) $(P)/exit42.elf; s=$$?; echo "exit42: exit status $$s"; test $$s -eq 42
	$(QEMU) $(P)/hello.elf > $(P)/hello.out
	printf 'hello, ff\nhello, ff\nhello, ff\n' | cmp - $(P)/hello.out
	@echo "hello: prints its three lines"

# The bootstrap, a chain of versions. ttpc.s (hosts/riscv64/), as the hex
# seed makes it (or GNU as, SEED=gnu), is stage0. ttpc1.ff, frozen like ttpc.s, is ttpc in the
# language of stage0, a whole tree below its 1 MiB: stage0 assembles it
# into ttpc1, which must assemble itself into itself, assemble every asm
# program and print ttpc1.ff exactly as stage0 does. ttpc1 assembles ttpc2
# (TTPC2_SRC, ttpc.ff frozen when the seeds' 1 MiB got tight), which must
# assemble itself into itself; ttpc2 assembles ttpc3 (TTPC3_SRC, ttpc.ff
# frozen when it learnt layers, 0: 1: ..., before using them), which must
# assemble itself into itself; ttpc3 assembles ttpc (TTPC_SRC) into stage1,
# stage1 assembles it into stage2: they must be the same, the fixed point.
# ttpc1 gets shared.ff in its own language
# (frozen): without the comments, which it knows only in code, and
# without else if:, which it would take for a register. Neither emits
# anything: stage1 is the same. ttpc1 and ttpc2 get it with only the
# sections they assemble with (trim), for their 4 MiB of input, and
# insize (copies-check: tools/insize.ff, as gen/insize.pl) stops a link of
# theirs whose input passes 3.5 MiB.
# Both are committed copies (boot/riscv64/, above): they come before ttpc3,
# which is the first link to compile ttp's tools (tools/old/: unlicense,
# for the NL trees of stage1 and of ttpc3.self). Which link reads what:
#   stage0  ttpc1.ff (frozen, no license) -> ttpc1
#   ttpc1   boot/riscv64/shared.ff, TTPC2_SRC -> ttpc2
#   ttpc2   boot/riscv64/shared1.ff, TTPC2_SRC -> ttpc2.self; TTPC3_SRC -> ttpc3
#   ttpc3   boot/riscv64/shared1.ff, tools/old/ -> boot/unlicense
#   ttpc3   NL trees (boot/unlicense) -> ttpc3.self, stage1
#   stage1  the trees as they are -> stage2

$(BOOT):
	mkdir -p $@

$(BOOT)/ttpc1: $(TTPC1_FF) $(BIN) | $(BOOT)
	$(QEMU) $(BIN) $< $@ > $@.lst

$(BOOT)/ttpc1.self: $(TTPC1_FF) $(BOOT)/ttpc1
	$(QEMU) $(BOOT)/ttpc1 $< $@ > $@.lst

$(BOOT)/ttpc2: boot/riscv64/shared.ff $(TTPC2_SRC) $(BOOT)/ttpc1
	$(QEMU) $(BOOT)/ttpc1 --target riscv64 boot/riscv64/shared.ff $(TTPC2_SRC) $@ > $@.lst

# ttpc1 and ttpc2 read at most 4 MiB: they get shared.ff with only riscv64's
# section (trim), which is all that emits anything for them.
$(BOOT)/ttpc2.self: boot/riscv64/shared1.ff $(TTPC2_SRC) $(BOOT)/ttpc2
	$(QEMU) $(BOOT)/ttpc2 --target riscv64 boot/riscv64/shared1.ff $(TTPC2_SRC) $@ > $@.lst

$(BOOT)/ttpc3: $(TTPC3_SRC) $(BOOT)/ttpc2 boot/riscv64/shared1.ff
	$(QEMU) $(BOOT)/ttpc2 --target riscv64 boot/riscv64/shared1.ff $(TTPC3_SRC) $@ > $@.lst

# ttp's unlicense, compiled by ttpc3 from its copy in the words of before
$(BOOT)/unlicense: $(OLDLIB) tools/old/unlicense.ff boot/riscv64/shared1.ff $(BOOT)/ttpc3
	$(QEMU) $(BOOT)/ttpc3 --target riscv64 boot/riscv64/shared1.ff $(OLDLIB) tools/old/unlicense.ff $@ > $@.lst
	chmod +x $@

$(BOOT)/ttpc3.self: $(NL)/$(SHARED) $(TTPC3_SRC) $(BOOT)/ttpc3
	$(QEMU) $(BOOT)/ttpc3 --target riscv64 $(NL)/$(SHARED) $(TTPC3_SRC) $@ > $@.lst

$(BOOT)/stage1: $(TTPC_SRC:%=$(NL)/%) $(BOOT)/ttpc3
	$(QEMU) $(BOOT)/ttpc3 --target riscv64 $(TTPC_SRC:%=$(NL)/%) $@ > $@.lst

$(BOOT)/stage2: $(TTPC_SRC) $(BOOT)/stage1
	$(QEMU) $(BOOT)/stage1 --target riscv64 $(TTPC_SRC) $@ > $@.lst

bootstrap: $(BOOT)/ttpc1.self $(BOOT)/ttpc2.self $(BOOT)/ttpc3.self $(BOOT)/stage2 $(PROGS:%=$(P)/%.elf)
	cmp $(BOOT)/ttpc1 $(BOOT)/ttpc1.self
	@echo "bootstrap: ttpc1 assembles itself"
	cmp $(BOOT)/ttpc2 $(BOOT)/ttpc2.self
	@echo "bootstrap: ttpc2 assembles itself"
	cmp $(BOOT)/ttpc3 $(BOOT)/ttpc3.self
	@echo "bootstrap: ttpc3 assembles itself"
	cmp $(BOOT)/stage1 $(BOOT)/stage2
	@echo "bootstrap: stage1 == stage2"
	@for p in $(PROGS); do \
	    $(QEMU) $(BOOT)/ttpc1 $(NL)/progs/riscv64/$$p.ff $(BOOT)/$$p.elf > $(BOOT)/$$p.lst && \
	    cmp $(BOOT)/$$p.elf $(P)/$$p.elf && cmp $(BOOT)/$$p.lst $(P)/$$p.lst || exit 1; \
	done
	$(QEMU) $(BIN) $(TTPC1_FF) > $(BOOT)/tree0.txt
	$(QEMU) $(BOOT)/ttpc1 $(TTPC1_FF) | cmp - $(BOOT)/tree0.txt
	@echo "bootstrap: ttpc1 assembles and prints like stage0"

# The C programs (progs/c*.ff) use the C layer, which ttpc.s predates:
# stage2, ttpc as ttpc.ff makes it, assembles them. Each must exit with the
# status on the first line of progs/<name>.expect ("exit N") and print the
# rest of it. A C program is only its program: the shared pages come from
# shared.ff.
$(P)/%.celf: progs/%.ff $(SHARED) $(BOOT)/stage2 | $(P)
	$(QEMU) $(BOOT)/stage2 $(TTPCFLAGS) $(SHARED) $< $@ > $(P)/$*.lst

# The vector instructions (RVV 1.0), which ttpc.s predates: stage2
# assembles progs/riscv64/rvv.ff, a program-only tree that mkrvv.pl writes
# with its GNU twin rvv.s, every instruction unmasked and under v0.t. They
# must be byte-identical after the ELF header (as far as the twin goes: the
# frame's program headers follow the program).
$(P)/rvv.velf: progs/riscv64/rvv.ff $(SHARED) $(BOOT)/stage2 | $(P)
	$(QEMU) $(BOOT)/stage2 $(SHARED) $< $@ > $(P)/rvv.lst

rvv: $(P)/rvv.velf $(P)/rvv.twin.bin
	tail -c +121 $(P)/rvv.velf | head -c $$(wc -c < $(P)/rvv.twin.bin) | cmp - $(P)/rvv.twin.bin
	@echo "rvv: ttpc and GNU as agree on the vector instructions"

# The instructions of aarch64 that glibc's asm needs beyond the base
# (Advanced SIMD, SVE, SME, MTE, MOPS, the q registers, hints): stage2
# assembles progs/aarch64/simd.ff, which mksimd.pl writes with its GNU twin
# simd.s; byte-identical after the ELF header, as rvv.
$(P)/aarch64/simd.twin.bin: progs/aarch64/simd.s $(TLDS_aarch64) | $(P)/aarch64
	$(CROSS_aarch64)as -march=armv9.4-a+sve+sme+memtag+mops $< -o $(P)/aarch64/simd.twin.o
	$(CROSS_aarch64)ld --no-relax --no-warn-rwx-segments -T $(TLDS_aarch64) $(P)/aarch64/simd.twin.o -o $(P)/aarch64/simd.twin
	$(CROSS_aarch64)objcopy -O binary $(P)/aarch64/simd.twin $@

simd: $(P)/aarch64/simd.elf $(P)/aarch64/simd.twin.bin
	tail -c +121 $(P)/aarch64/simd.elf | head -c $$(wc -c < $(P)/aarch64/simd.twin.bin) | cmp - $(P)/aarch64/simd.twin.bin
	@echo "simd: ttpc and GNU as agree on aarch64's SIMD, SVE, SME, MTE and MOPS instructions"

ctest: $(CPROGS:%=$(P)/%.celf)
	@for p in $(CPROGS); do \
	    tail -n +2 progs/$$p.expect > $(P)/$$p.want; \
	    $(QEMU) $(P)/$$p.celf > $(P)/$$p.out; s=$$?; \
	    want=$$(head -n 1 progs/$$p.expect | cut -d" " -f2); \
	    test $$s -eq $$want || { echo "ctest: $$p: exit status $$s, not $$want"; exit 1; }; \
	    cmp $(P)/$$p.out $(P)/$$p.want || { echo "ctest: $$p: wrong output"; exit 1; }; \
	    echo "ctest: $$p"; \
	done

# compile time: cnow prints while it is compiled and none of that is in
# the program, ctasm does so by calling asm of its page, ctmix with asm
# and C mixed in one compile-time function, cct keeps only the branch its
# condition takes (a lambda with if, else and emit), cnowfail fails to
# compile with its message, and so do creserved, which declares a variable
# named * pointer, cmisplaced, with compile time on a while, cuntyped, a global declaration
# without a type, citems, several items on a long, cchartext, text in a
# char, ctypeout, type outside compile time, and cbelow, a local used
# above its declaration; cvecx64, x86_64's vector test, stops riscv64's
# ttpc (vectors are x86_64's alone).
ctime: $(P)/cnow.celf $(P)/cct.celf $(P)/ctasm.celf $(P)/ctmix.celf
	grep -qx compiling $(P)/cnow.lst
	grep -qx "asm at compile time" $(P)/ctasm.lst
	grep -qx "asm and C at compile time" $(P)/ctmix.lst
	! grep -aq compiling $(P)/cnow.celf
	! grep -aq other $(P)/cct.celf
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cnowfail.ff $(P)/cnowfail.celf 2> $(P)/cnowfail.err
	grep -q "compile time: no" $(P)/cnowfail.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/creserved.ff $(P)/creserved.celf 2> $(P)/creserved.err
	grep -q "a reserved word: \* pointer" $(P)/creserved.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cmisplaced.ff $(P)/cmisplaced.celf 2> $(P)/cmisplaced.err
	grep -q "compile time goes only first in a function or a lambda: while" $(P)/cmisplaced.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cvecx64.ff $(P)/cvecx64.celf 2> $(P)/cvecx64.err
	grep -q "vector, of the SysV ABI of x86_64, on another target: vector$$" $(P)/cvecx64.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cuntyped.ff $(P)/cuntyped.celf 2> $(P)/cuntyped.err
	grep -q "needs a type: n$$" $(P)/cuntyped.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/citems.ff $(P)/citems.celf 2> $(P)/citems.err
	grep -q "several items need array: n$$" $(P)/citems.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cchartext.ff $(P)/cchartext.celf 2> $(P)/cchartext.err
	grep -q "text needs char \* pointer: oops$$" $(P)/cchartext.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/ctypeout.ff $(P)/ctypeout.celf 2> $(P)/ctypeout.err
	grep -q "type goes only in compile time: type$$" $(P)/ctypeout.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cbelow.ff $(P)/cbelow.celf 2> $(P)/cbelow.err
	grep -q "used before it is declared: x$$" $(P)/cbelow.err
	@echo "ctime: compile time runs and stays out of the program"

# Build files. progs/cws.ff is one, run as ttpc progs/cws.ff with nothing
# else on the command line, here from the build folder (its paths are from
# its own folder): it includes ../shared.ff and makes three workspaces,
# chello for riscv64 and for x86_64 and cexit with the name it gets without
# set output (next to cws.ff), each the bytes the command line makes.
# cwsdebug.ff makes chello twice, with set debug (as -g) and without; run
# with -g, both as -g (gsame); cwsopt.ff so with set optimise (as -O) and
# cfib, run with -O both as -O. cwsjobs.ff so with set jobs (as -j 4: the same bytes),
# run with -j3 both the same again. cinclude is chello including its shared page,
# --print prints a tree as stage0 does, and cwsnofile, cwsplace and cincludelate fail to compile
# with their message. cws.ff writes into ../../../build/compiler/progs, the
# default BUILD.
# gsame A B: the -g file A is B up to B's .debug_abbrev (past the ELF
# header: its program, symbols and their names; the line table names the
# trees by their paths, which differ in a build file)
gsame = n=$$(readelf -SW $(2) | sed -n 's/.* \.debug_abbrev  *PROGBITS  *[0-9a-f]* \([0-9a-f]*\) .*/\1/p'); test -n "$$n" && cmp -i 64 -n $$((0x$$n - 64)) $(1) $(2) && readelf -SW $(1) | grep -q ' \.debug_line '
cws: $(P)/chello.celf $(P)/x86_64/chello.celf $(P)/cexit.celf $(P)/cfib.celf
	rm -f progs/cexit
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 $(CURDIR)/progs/cws.ff > cws.lst
	mv progs/cexit $(P)/cws-cexit
	cmp $(P)/cws-riscv64 $(P)/chello.celf
	cmp $(P)/cws-x86_64 $(P)/x86_64/chello.celf
	cmp $(P)/cws-cexit $(P)/cexit.celf
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 $(CURDIR)/progs/cwsdebug.ff > cwsdebug.lst
	$(QEMU) $(BOOT)/stage2 -g $(SHARED) progs/chello.ff $(P)/chello.g > $(P)/chello.g.lst
	cmp $(P)/cwsdebug $(P)/chello.celf
	$(call gsame,$(P)/cwsdebug-g,$(P)/chello.g)
	rm $(P)/cwsdebug $(P)/cwsdebug-g
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 -g $(CURDIR)/progs/cwsdebug.ff > cwsdebug.lst
	$(call gsame,$(P)/cwsdebug,$(P)/chello.g)
	$(call gsame,$(P)/cwsdebug-g,$(P)/chello.g)
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 $(CURDIR)/progs/cwsopt.ff > cwsopt.lst
	$(QEMU) $(BOOT)/stage2 -O $(SHARED) progs/cfib.ff $(P)/cfib.O > $(P)/cfib.O.lst
	! cmp -s $(P)/cfib.O $(P)/cfib.celf
	cmp $(P)/cwsopt $(P)/cfib.celf
	cmp $(P)/cwsopt-O $(P)/cfib.O
	rm $(P)/cwsopt $(P)/cwsopt-O
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 -O $(CURDIR)/progs/cwsopt.ff > cwsopt.lst
	cmp $(P)/cwsopt $(P)/cfib.O
	cmp $(P)/cwsopt-O $(P)/cfib.O
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 $(CURDIR)/progs/cwsjobs.ff > cwsjobs.lst
	cmp $(P)/cwsjobs $(P)/cfib.celf
	cmp $(P)/cwsjobs-j $(P)/cfib.celf
	rm $(P)/cwsjobs $(P)/cwsjobs-j
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 -j3 $(CURDIR)/progs/cwsjobs.ff > cwsjobs.lst
	cmp $(P)/cwsjobs $(P)/cfib.celf
	cmp $(P)/cwsjobs-j $(P)/cfib.celf
	$(QEMU) $(BOOT)/stage2 progs/cinclude.ff $(P)/cinclude.celf > $(P)/cinclude.lst
	cmp $(P)/cinclude.celf $(P)/chello.celf
	$(QEMU) $(BOOT)/stage2 --print progs/chello.ff > $(P)/chello.print
	$(QEMU) $(BIN) progs/chello.ff | cmp - $(P)/chello.print
	! $(QEMU) $(BOOT)/stage2 progs/cwsnofile.ff 2> $(P)/cwsnofile.err
	grep -q "a workspace needs a file" $(P)/cwsnofile.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cwsplace.ff $(P)/cwsplace.celf 2> $(P)/cwsplace.err
	grep -q "cannot compile: set target" $(P)/cwsplace.err
	! $(QEMU) $(BOOT)/stage2 progs/cincludelate.ff $(P)/cincludelate.celf 2> $(P)/cincludelate.err
	grep -q "include goes first" $(P)/cincludelate.err
	@echo "cws: a build file runs its workspaces, include reads a tree"

# The other targets ttpc builds for (--target). Per target: its asm
# programs (progs/<target>/*.ff, program-only trees) must be byte-identical
# to their GNU twins (progs/<target>/*.s) after the ELF header, exit42 and
# hello must run, and every C program that is not riscv64 asm must do what
# its .expect says (progs/<name>.<target>.expect where the target differs),
# compile time still running on riscv64.
TARGETS := x86_64 aarch64 arm
CPORTABLE := cexit cfib cloop chello cexpr cstruct cnow cct cct2 cunroll celse casm casm2 cstring cscope cint cint64 cflow ctypes cself cunion cbits cinit ccalls cvarargs ctls clib cifunc cifuncaddr cifunclib ccomplit cincdec cparen cdot cgroups ccast caddrc cweak cifvalue cvapack cfloat cfloats cfloats32 cgnu cpath ccond clabels calloca caddrlit canon cloopsp cvamem cnullary clayers clayerslib clazy cpair cpaircall cpairmul cchar cfnaddr cvlasize carraylit calign cldlit cgroupdot casmalign ccomplex cbodylayers cgeneric csection cglobcast creach cldneg ctextitem cemptyitem cctor cnarrowret cenumtype ctlitstmt calignattr ccleanup chexinf cvaptr cdebug cline cldalign cglobroom cwidestmt clocalign32
# cgnu has bitfields of u64, which arm does not have yet (a pair as the unit).
CSKIP_arm := cgnu
# C tests of one target only, beside the portable ones
CONLY_aarch64 := ctlsa64
CONLY_x86_64 := ctlsx64 cfsx64 cvecx64
CONLY_arm := ctlsarm

# clazy includes the folder progs/clazylib (its index.ff and a file per
# page), which it reads lazily: never.ff, which it must not read, is no tree.
CLAZY := $(wildcard progs/clazylib/*.ff)
$(P)/clazy.celf $(TARGETS:%=$(P)/%/clazy.celf): $(CLAZY)

CROSS_x86_64 := x86_64-elf-
TASFLAGS_x86_64 := -mindex-reg
TLDS_x86_64 := ff64.ld
THDR_x86_64 := 120

CROSS_aarch64 := aarch64-none-elf-
TASFLAGS_aarch64 := -march=armv8.1-a
TLDS_aarch64 := ff64.ld
THDR_aarch64 := 120

CROSS_arm := arm-none-eabi-
TASFLAGS_arm :=
TLDS_arm := ff32.ld
THDR_arm := 84

define target
$(P)/$(1):
	mkdir -p $$@

$(P)/$(1)/%.elf: progs/$(1)/%.ff $(SHARED) $(BOOT)/stage2 | $(P)/$(1)
	$(QEMU) $(BOOT)/stage2 --target $(1) $(SHARED) $$< $$@ > $(P)/$(1)/$$*.lst

$(P)/$(1)/%.twin.bin: progs/$(1)/%.s $(TLDS_$(1)) | $(P)/$(1)
	$(CROSS_$(1))as $(TASFLAGS_$(1)) $$< -o $(P)/$(1)/$$*.twin.o
	$(CROSS_$(1))ld --no-relax --no-warn-rwx-segments -T $(TLDS_$(1)) $(P)/$(1)/$$*.twin.o -o $(P)/$(1)/$$*.twin
	$(CROSS_$(1))objcopy -O binary $(P)/$(1)/$$*.twin $$@

$(P)/$(1)/%.celf: progs/%.ff $(SHARED) $(BOOT)/stage2 | $(P)/$(1)
	$(QEMU) $(BOOT)/stage2 --target $(1) $(TTPCFLAGS) $(SHARED) $$< $$@ > $(P)/$(1)/$$*.lst

check-$(1): $(PROGS:%=$(P)/$(1)/%.elf) $(PROGS:%=$(P)/$(1)/%.twin.bin)
	@for p in $(PROGS); do \
	    tail -c +$$$$(($(THDR_$(1)) + 1)) $(P)/$(1)/$$$$p.elf | cmp - $(P)/$(1)/$$$$p.twin.bin || exit 1; \
	    echo "check-$(1): $$$$p: ttpc and GNU as agree"; \
	done
	qemu-$(1) $(P)/$(1)/exit42.elf; test $$$$? -eq 42
	qemu-$(1) $(P)/$(1)/hello.elf > $(P)/$(1)/hello.out
	printf 'hello, ff\nhello, ff\nhello, ff\n' | cmp - $(P)/$(1)/hello.out
	@echo "check-$(1): exit42 and hello run"

ctest-$(1): $(patsubst %,$(P)/$(1)/%.celf,$(filter-out $(CSKIP_$(1)),$(CPORTABLE)) $(CONLY_$(1)))
	@for p in $(filter-out $(CSKIP_$(1)),$(CPORTABLE)) $(CONLY_$(1)); do \
	    e=progs/$$$$p.$(1).expect; test -f $$$$e || e=progs/$$$$p.expect; \
	    tail -n +2 $$$$e > $(P)/$(1)/$$$$p.want; \
	    qemu-$(1) $(P)/$(1)/$$$$p.celf > $(P)/$(1)/$$$$p.out; s=$$$$?; \
	    want=$$$$(head -n 1 $$$$e | cut -d" " -f2); \
	    test $$$$s -eq $$$$want || { echo "ctest-$(1): $$$$p: exit status $$$$s, not $$$$want"; exit 1; }; \
	    cmp $(P)/$(1)/$$$$p.out $(P)/$(1)/$$$$p.want || { echo "ctest-$(1): $$$$p: wrong output"; exit 1; }; \
	    echo "ctest-$(1): $$$$p"; \
	done
	grep -qx compiling $(P)/$(1)/cnow.lst
	! grep -aq compiling $(P)/$(1)/cnow.celf

.PHONY: check-$(1) ctest-$(1)
endef
$(foreach t,$(TARGETS),$(eval $(call target,$(t))))

# -j: each ctest, for riscv64 and for every target, compiled with -j0 (one
# process that checks the second pass against the first's samples) and -j6
# (the second pass on six) is the bytes and listing of one process; cnow,
# cct, ctasm and ctmix run compile time in the first pass, which the
# second's shares then take up. On x86_64 by its own stage2.
JTTPC := $(if $(filter x86_64,$(ARCH)),$(BUILD)/x86_64/stage2,$(QEMU) $(BOOT)/stage2)
ctest-j: $(CPROGS:%=$(P)/%.celf) $(foreach t,$(TARGETS),$(patsubst %,$(P)/$(t)/%.celf,$(filter-out $(CSKIP_$(t)),$(CPORTABLE)) $(CONLY_$(t)))) $(if $(filter x86_64,$(ARCH)),$(BUILD)/x86_64/stage2,$(BOOT)/stage2)
	@set -e; d=$(P)/j; mkdir -p $$d; \
	one() { for j in 0 6; do \
	    $(JTTPC) -j$$j --target $$1 $(TTPCFLAGS) $(SHARED) progs/$$2.ff $$d/$$2.$$1.$$j > $$d/$$2.$$1.$$j.lst; \
	    cmp $$d/$$2.$$1.$$j $$3.celf; cmp $$d/$$2.$$1.$$j.lst $$3.lst; done; rm -f $$d/$$2.$$1.*; }; \
	for p in $(CPROGS); do one riscv64 $$p $(P)/$$p; done; \
	$(foreach t,$(TARGETS),for p in $(filter-out $(CSKIP_$(t)),$(CPORTABLE)) $(CONLY_$(t)); do one $(t) $$p $(P)/$(t)/$$p; done;) \
	echo "ctest-j: every ctest on riscv64 $(TARGETS), with -j0 and -j6 the bytes and listing of one process"

# the forms GNU as picks for glibc's asm (isa/x86_64gnu.pl): every one in
# progs/x86_64/gnu.ff (mkgnu.pl), byte for byte its GNU twin gnu.s
$(P)/x86_64/gnu.elf: progs/x86_64/gnu.ff $(SHARED) $(X86GNU) $(BOOT)/stage2 | $(P)/x86_64
	$(QEMU) $(BOOT)/stage2 --target x86_64 $(SHARED) $(X86GNU) $< $@ > $(P)/x86_64/gnu.lst
x86gnu: $(P)/x86_64/gnu.elf $(P)/x86_64/gnu.twin.bin
	tail -c +$$(($(THDR_x86_64) + 1)) $(P)/x86_64/gnu.elf | cmp - $(P)/x86_64/gnu.twin.bin
	@echo "x86gnu: ttpc and GNU as agree on every form of isa/x86_64gnu.pl (gnu.s)"
.PHONY: x86gnu

# The calls by each target's C ABI, against gcc (progs/abi/run.sh): gcc's
# functions of many shapes (by s2ff) and C translated by c2ff, built by
# ttpc into one program, call each other; every check must say ok: arm
# (the AAPCS, gen/patches/abi.pl), aarch64 (AAPCS64, abia64.pl),
# x86_64 (the SysV ABI, abix64.pl; natively, without qemu) and riscv64
# (lp64d, abirv.pl).
ABI_TARGETS := arm aarch64 x86_64 riscv64
abi: $(BOOT)/stage2 $(SHARED)
	@for t in $(ABI_TARGETS); do TTPC="$(QEMU) $(BOOT)/stage2" sh progs/abi/run.sh $$t $(P)/abi-$$t > $(P)/abi-$$t.log 2>&1 || { cat $(P)/abi-$$t.log; exit 1; }; tail -n 1 $(P)/abi-$$t.log; done

# -g (gen/patches/debug.pl, ehframe.pl): the section headers, symbols and
# frames of progs/cdebug.ff (and ctls, csection, cdatasep), as readelf,
# objdump, gdb and libgcc's unwinder read them (progs/debug/run.sh), and its
# line table (dwarfline.pl) as gdb's break, list and addr2line read it, on
# every target: gdb natively on x86_64, under qemu -g on the others.
DEBUG_TARGETS := riscv64 x86_64 aarch64 arm
debug: $(BOOT)/stage2 $(SHARED)
	@for t in $(DEBUG_TARGETS); do TTPC="$(QEMU) $(BOOT)/stage2" sh progs/debug/run.sh $$t $(P)/debug-$$t > $(P)/debug-$$t.log 2>&1 || { cat $(P)/debug-$$t.log; exit 1; }; tail -n 1 $(P)/debug-$$t.log; done

# -O (gen/patches/opt.pl, the peephole): every C program of ctest and
# ctest-<target>, built with -O into progs-O, against the same .expect
# files; TTPCFLAGS are the flags of stage2 for the C programs.
TTPCFLAGS ?=
check-O:
	$(MAKE) --no-print-directory P=$(BUILD)/progs-O TTPCFLAGS=-O ctest $(TARGETS:%=ctest-%)
.PHONY: check-O

targets: $(TARGETS:%=check-%) $(TARGETS:%=ctest-%) x86gnu
	! $(QEMU) $(BOOT)/stage2 --target mips $(SHARED) progs/cexit.ff $(P)/mips.celf 2> $(P)/mips.err
	grep -q "compile time: mips is not a target" $(P)/mips.err
	@echo "targets: $(TARGETS) and riscv64"

# The bootstrap on the other hosts, without riscv64. hosts/<host>/ttpc.s is
# the seed there, a port of ttpc.s (with OUT_SIZE 1 MiB): it must agree
# with ttpc.s on everything ttpc.s does (seed-<host>). ttpc is written in
# RV64: mkhost (tools/mkhost.ff, as gen/mkhost.pl) makes its ops rv.op,
# which the host's rv64: group defines in the host's instructions, and
# mkwhole (tools/mkwhole.ff, as gen/mkwhole.pl) makes of that a whole tree
# in the language of the seed, of ttpc2 (the whole tree of ttpc.ff would no
# longer fit the seed's 1 MiB). The seed assembles it into ttpc2, which
# assembles itself into itself and ttpc3 (mkhost's too), which assembles
# itself into itself and ttpc into stage1; stage1 assembles ttpc
# into stage2: the same, and the same as what the riscv64
# chain makes with --target <host> (cross), two chains that share nothing
# but the source. Then stage2 builds the C programs for its own host, which
# must do what their .expect says. On the host itself all of it runs
# without qemu.
HOSTS := x86_64 aarch64 arm
RUN_x86_64 := $(if $(filter x86_64,$(ARCH)),,qemu-x86_64)
RUN_aarch64 := $(if $(filter aarch64 arm64,$(ARCH)),,qemu-aarch64)
RUN_arm := $(if $(filter armv7l armv8l,$(ARCH)),,qemu-arm)
# What this machine runs: a host natively or under its qemu; riscv64 the same.
# Without qemu only its own host is bootstrapped, and not compared with the
# riscv64 chain. The seed takes the cross binutils, or the host's own.
can = $(if $(RUN_$(1)),$(call have,$(RUN_$(1))),yes)
CAN_RISCV := $(if $(QEMU),$(call have,$(QEMU)),yes)
RUNNABLE := $(foreach h,$(HOSTS),$(if $(call can,$(h)),$(h)))
SEEDCROSS_x86_64 := $(call native_or,x86_64,x86_64-elf-)
SEEDCROSS_aarch64 := $(call native_or,aarch64,aarch64-none-elf-)
SEEDCROSS_arm := $(call native_or,armv7l,arm-none-eabi-)
SASFLAGS_x86_64 := -mx86-used-note=no
SASFLAGS_aarch64 :=
SASFLAGS_arm := -march=armv7-a
SLDFLAGS_x86_64 := -s -z noseparate-code
# The hex seed (lane H): on the hosts of HEXHOSTS the chain builds the seed
# without binutils, from hosts/<host>/hex0, a binary of a few hundred bytes
# that is its commented text hex0.hex0 (make hex checks both): hex0 makes
# hex2 of hex2.hex0, hex2 makes M1 of M1.hex2, M1 and hex2 make asm of
# asm.M1, and asm assembles the readable seed ttpc.s into the seed.
# SEED=hex: hex2 makes the seed of ttpc.hex2 instead (the stepping stone);
# SEED=gnu: binutils' as and ld make it of ttpc.s, as on the other hosts.
# All three give the same bytes (make hex): on x86_64 as and ld without
# the GNU property note, the symbols (which name the object file) and the
# page of its own for the code, so that the cross and the native binutils
# agree.
# riscv64 (the bootstrap's own seed, $(BIN)) has hex0, hex2 and ttpc.hex2
# so far: SEED=asm takes ttpc.hex2 there (ASMHOSTS have M1 and asm). Its
# binutils' seed is as -mno-arch-attr (the attribute's string names the
# version of binutils) and ld -s -z noseparate-code, so the cross and the
# native binutils agree too.
SEED ?= asm
HEXHOSTS := x86_64 riscv64
ASMHOSTS := x86_64
seedkind = $(if $(filter $(1),$(HEXHOSTS)),$(if $(filter asm,$(SEED)),$(if $(filter $(1),$(ASMHOSTS)),asm,hex),$(SEED)),gnu)
RUN_riscv64 := $(QEMU)
SEED_FF := ttpc1.ff $(PROGS:%=$(NL)/progs/riscv64/%.ff)

# the NL trees a host's chain makes with its own unlicense
NLHOST := $(SHARED) ttpc.defs.ff $(TTPC_FF)

define host

$(BUILD)/$(1):
	mkdir -p $$@

$(BUILD)/$(1)/seed.gnu: hosts/$(1)/ttpc.s | $(BUILD)/$(1)
	$(SEEDCROSS_$(1))as $(SASFLAGS_$(1)) $$< -o $$@.o
	$(SEEDCROSS_$(1))ld -static $(SLDFLAGS_$(1)) -e _start $$@.o -o $$@

$(BUILD)/$(1)/seed: $(BUILD)/$(1)/seed.$(call seedkind,$(1))
	cp $$< $$@

# The links before the host's ttpc3 read committed copies (boot/<host>/,
# see NL above): its seed the whole tree of ttpc2 (whole.ff), its ttpc2
# ttpc2 and ttpc3 as mkhost makes them. The host's ttpc3 compiles ttp's
# mkhost (tools/old/, as its unlicense), which makes stage1's ttpc for the
# host ($(BUILD)/<host>/ttpc.ff, ttpc.defs.ff): no Perl in the chain.
$(BUILD)/$(1)/mkhost: $(OLDMK) tools/old/mkhost.ff boot/$(1)/shared1.ff $(BUILD)/$(1)/ttpc3
	$(RUN_$(1)) $(BUILD)/$(1)/ttpc3 --target $(1) boot/$(1)/shared1.ff $(OLDMK) tools/old/mkhost.ff $$@ > $$@.lst
	chmod +x $$@

$(BUILD)/$(1)/ttpc.ff: $(BUILD)/$(1)/nl/$(TTPC_FF) $(BUILD)/$(1)/nl/ttpc.defs.ff $(SHARED) $(BUILD)/$(1)/mkhost | $(BUILD)/$(1)
	$(RUN_$(1)) $(BUILD)/$(1)/mkhost -s $(SHARED) $(1) $(BUILD)/$(1) $(BUILD)/$(1)/nl/ttpc.defs.ff $(BUILD)/$(1)/nl/$(TTPC_FF)

$(BUILD)/$(1)/ttpc.defs.ff: $(BUILD)/$(1)/ttpc.ff

$(BUILD)/$(1)/ttpc2: boot/$(1)/whole.ff $(BUILD)/$(1)/seed
	$(RUN_$(1)) $(BUILD)/$(1)/seed $$< $$@ > $$@.lst

$(BUILD)/$(1)/ttpc2.self: $(BUILD)/$(1)/ttpc2 boot/$(1)/shared1.ff boot/$(1)/ttpc2.defs.ff boot/$(1)/ttpc2.ff
	$(RUN_$(1)) $$< --target $(1) boot/$(1)/shared1.ff boot/$(1)/ttpc2.defs.ff boot/$(1)/ttpc2.ff $$@ > $$@.lst

$(BUILD)/$(1)/ttpc3: $(BUILD)/$(1)/ttpc2 boot/$(1)/ttpc3.ff boot/$(1)/ttpc3.defs.ff boot/$(1)/shared1.ff
	$(RUN_$(1)) $$< --target $(1) boot/$(1)/shared1.ff boot/$(1)/ttpc3.defs.ff boot/$(1)/ttpc3.ff $$@ > $$@.lst

# the host's own unlicense, compiled by its ttpc3 (as the riscv64 chain's),
# and the trees it makes for its ttpc3.self and stage1
$(BUILD)/$(1)/unlicense: $(OLDLIB) tools/old/unlicense.ff boot/$(1)/shared1.ff $(BUILD)/$(1)/ttpc3
	$(RUN_$(1)) $(BUILD)/$(1)/ttpc3 --target $(1) boot/$(1)/shared1.ff $(OLDLIB) tools/old/unlicense.ff $$@ > $$@.lst
	chmod +x $$@

$(BUILD)/$(1)/nl/%.ff: %.ff $(BUILD)/$(1)/unlicense
	@mkdir -p $$(dir $$@)
	$(RUN_$(1)) $(BUILD)/$(1)/unlicense $$< > $$@.tmp && mv $$@.tmp $$@

$(BUILD)/$(1)/ttpc3.self: $(BUILD)/$(1)/ttpc3 $(BUILD)/$(1)/nl/$(SHARED)
	$(RUN_$(1)) $$< --target $(1) $(BUILD)/$(1)/nl/$(SHARED) boot/$(1)/ttpc3.defs.ff boot/$(1)/ttpc3.ff $$@ > $$@.lst

$(BUILD)/$(1)/stage1: $(BUILD)/$(1)/ttpc3 $(BUILD)/$(1)/ttpc.ff $(BUILD)/$(1)/nl/$(SHARED)
	$(RUN_$(1)) $$< --target $(1) $(BUILD)/$(1)/nl/$(SHARED) $(BUILD)/$(1)/ttpc.defs.ff $(BUILD)/$(1)/ttpc.ff $$@ > $$@.lst

$(BUILD)/$(1)/stage2: $(BUILD)/$(1)/stage1
	$(RUN_$(1)) $$< --target $(1) $(SHARED) $(BUILD)/$(1)/ttpc.defs.ff $(BUILD)/$(1)/ttpc.ff $$@ > $$@.lst

$(BUILD)/$(1)/cross: $(BOOT)/stage2 $(BUILD)/$(1)/ttpc.ff
	$(QEMU) $(BOOT)/stage2 --target $(1) $(SHARED) $(BUILD)/$(1)/ttpc.defs.ff $(BUILD)/$(1)/ttpc.ff $$@ > $$@.lst

# The seed against ttpc.s: the same output, listing, errors and status.
seed-$(1): $(BUILD)/$(1)/seed $(BIN) $(SEED_FF) | $(BUILD)/$(1)
	@set -e; d=$(BUILD)/$(1)/seedcheck; mkdir -p $$$$d; \
	head -c 1000 $(NL)/progs/riscv64/exit42.ff > $$$$d/truncated.ff; \
	cat $(NL)/progs/riscv64/exit42.ff $(NL)/progs/riscv64/exit42.ff > $$$$d/trailing.ff; \
	run() { n=$$$$1; shift; \
	    s=0; $(QEMU) $(BIN) "$$$$@" $$$$d/$$$$n.out0 > $$$$d/$$$$n.1 2> $$$$d/$$$$n.2 || s=$$$$?; echo $$$$s > $$$$d/$$$$n.3; \
	    s=0; $(RUN_$(1)) $(BUILD)/$(1)/seed "$$$$@" $$$$d/$$$$n.out1 > $$$$d/$$$$n.4 2> $$$$d/$$$$n.5 || s=$$$$?; echo $$$$s > $$$$d/$$$$n.6; \
	    cmp $$$$d/$$$$n.1 $$$$d/$$$$n.4; cmp $$$$d/$$$$n.2 $$$$d/$$$$n.5; cmp $$$$d/$$$$n.3 $$$$d/$$$$n.6; \
	    if test -f $$$$d/$$$$n.out0; then cmp $$$$d/$$$$n.out0 $$$$d/$$$$n.out1; else test ! -f $$$$d/$$$$n.out1; fi; \
	    echo "seed-$(1): $$$$n: as ttpc.s"; }; \
	for f in $(SEED_FF); do run $$$$(basename $$$$f .ff) $$$$f; done; \
	pr() { n=$$$$1; shift; \
	    s=0; $(QEMU) $(BIN) "$$$$@" > $$$$d/$$$$n.1 2> $$$$d/$$$$n.2 || s=$$$$?; echo $$$$s > $$$$d/$$$$n.3; \
	    s=0; $(RUN_$(1)) $(BUILD)/$(1)/seed "$$$$@" > $$$$d/$$$$n.4 2> $$$$d/$$$$n.5 || s=$$$$?; echo $$$$s > $$$$d/$$$$n.6; \
	    cmp $$$$d/$$$$n.1 $$$$d/$$$$n.4; cmp $$$$d/$$$$n.2 $$$$d/$$$$n.5; cmp $$$$d/$$$$n.3 $$$$d/$$$$n.6; \
	    echo "seed-$(1): $$$$n: as ttpc.s"; }; \
	pr print-ttpc1 ttpc1.ff; pr print-hello $(NL)/progs/riscv64/hello.ff; pr toolarge $(SHARED); pr usage; \
	pr toomany a b c; pr missing $$$$d/none.ff; pr truncated $$$$d/truncated.ff; pr trailing $$$$d/trailing.ff

bootstrap-$(1): $(BUILD)/$(1)/ttpc2.self $(BUILD)/$(1)/ttpc3.self $(BUILD)/$(1)/stage2 $(if $(CAN_RISCV),$(BUILD)/$(1)/cross $(NLHOST:%=$(NL)/%))
	cmp $(BUILD)/$(1)/ttpc2 $(BUILD)/$(1)/ttpc2.self
	@echo "bootstrap-$(1): from its seed, ttpc2 assembles itself"
	cmp $(BUILD)/$(1)/ttpc3 $(BUILD)/$(1)/ttpc3.self
	@echo "bootstrap-$(1): from its seed, ttpc3 assembles itself"
	cmp $(BUILD)/$(1)/stage1 $(BUILD)/$(1)/stage2
	@echo "bootstrap-$(1): from its seed, stage1 == stage2"
	$(if $(CAN_RISCV),cmp $(BUILD)/$(1)/stage1 $(BUILD)/$(1)/cross,@echo "bootstrap-$(1): no $(QEMU) here, not compared with the riscv64 chain")
	$(if $(CAN_RISCV),@echo "bootstrap-$(1): == the riscv64 chain's ttpc for $(1)")
	$(if $(CAN_RISCV),@for f in $(NLHOST); do cmp $(BUILD)/$(1)/nl/$$$$f $(NL)/$$$$f || exit 1; done; echo "bootstrap-$(1): its unlicense makes the trees as the riscv64 chain's")

# The C programs, built by stage2 for its own host and run there.
# casm, casm2 and casmfail also for riscv64: compile time runs on the host,
# its asm is riscv64's.
chello-$(1): $(BUILD)/$(1)/stage2
	@set -e; d=$(BUILD)/$(1)/c; mkdir -p $$$$d; \
	for p in $(filter-out $(CSKIP_$(1)),$(CPORTABLE)); do \
	    e=progs/$$$$p.$(1).expect; test -f $$$$e || e=progs/$$$$p.expect; \
	    $(RUN_$(1)) $(BUILD)/$(1)/stage2 --target $(1) $(SHARED) progs/$$$$p.ff $$$$d/$$$$p > $$$$d/$$$$p.lst; \
	    tail -n +2 $$$$e > $$$$d/$$$$p.want; \
	    s=0; $(RUN_$(1)) $$$$d/$$$$p > $$$$d/$$$$p.out || s=$$$$?; \
	    want=$$$$(head -n 1 $$$$e | cut -d" " -f2); \
	    test $$$$s -eq $$$$want || { echo "chello-$(1): $$$$p: exit status $$$$s, not $$$$want"; exit 1; }; \
	    cmp $$$$d/$$$$p.out $$$$d/$$$$p.want; \
	    echo "chello-$(1): $$$$p"; \
	done; \
	grep -qx compiling $$$$d/cnow.lst; ! grep -aq compiling $$$$d/cnow
	$(if $(CAN_RISCV),@set -e; d=$(BUILD)/$(1)/c; for p in casm casm2 casmfail; do \
	    $(RUN_$(1)) $(BUILD)/$(1)/stage2 --target riscv64 $(SHARED) progs/$$$$p.ff $$$$d/$$$$p.riscv64 > $$$$d/$$$$p.riscv64.lst; \
	    s=0; $(QEMU) $$$$d/$$$$p.riscv64 || s=$$$$?; \
	    want=$$$$(head -n 1 progs/$$$$p.expect | cut -d" " -f2); \
	    test $$$$s -eq $$$$want || { echo "chello-$(1): $$$$p for riscv64: exit status $$$$s instead of $$$$want"; exit 1; }; \
	    echo "chello-$(1): $$$$p built on $(1) for riscv64"; \
	done)
	@echo "chello-$(1): the C programs, built on $(1) by its own ttpc, run"

.PHONY: seed-$(1) bootstrap-$(1) chello-$(1)
endef
$(foreach h,$(HOSTS),$(eval $(call host,$(h))))

# The hex seed of a host of HEXHOSTS: hex0 makes hex2, hex2 the seed of
# ttpc.hex2; on a host of ASMHOSTS (below) hex2 makes M1 of M1.hex2 (a
# macro assembler, as stage0-posix's), M1 the hex2 text of asm.M1 and hex2
# of it asm, the seed's assembler, and asm the seed of ttpc.s. hex-<host>
# checks hex0 and hex2 against their texts without comments (what a
# person can check by hand: the hex digits before each '#' or ';', as od
# prints the binary), that hex0 makes itself of hex0.hex0 and that the
# seed of ttpc.hex2 is the one binutils makes of ttpc.s; hexasm-<host>
# that M1 and asm are what binutils makes of their sources
# gen/hex/<host>/M1.s and asm.s (dev aids, which gen/mkhex.pl made M1.hex2
# and asm.M1 of) and that asm's seed is binutils' too.
define hexhost

$(BUILD)/$(1)/hex2: hosts/$(1)/hex0 hosts/$(1)/hex2.hex0 | $(BUILD)/$(1)
	$(RUN_$(1)) hosts/$(1)/hex0 < hosts/$(1)/hex2.hex0 > $$@.tmp
	chmod +x $$@.tmp
	mv $$@.tmp $$@

$(BUILD)/$(1)/seed.hex: $(BUILD)/$(1)/hex2 hosts/$(1)/ttpc.hex2
	$(RUN_$(1)) $(BUILD)/$(1)/hex2 < hosts/$(1)/ttpc.hex2 > $$@.tmp
	chmod +x $$@.tmp
	mv $$@.tmp $$@

hex-$(1): $(BUILD)/$(1)/hex2 $(BUILD)/$(1)/seed.hex $(BUILD)/$(1)/seed.gnu
	@set -e; d=$(BUILD)/$(1)/hex; mkdir -p $$$$d; \
	for f in hex0 hex2; do sed 's/[#;].*//' hosts/$(1)/$$$$f.hex0 | tr -cd 0-9A-Fa-f | tr A-F a-f > $$$$d/$$$$f.text; done; \
	od -An -v -tx1 hosts/$(1)/hex0 | tr -cd 0-9a-f | cmp - $$$$d/hex0.text; \
	echo "hex-$(1): hex0 ($$$$(wc -c < hosts/$(1)/hex0) bytes) is hex0.hex0 without its comments"; \
	$(RUN_$(1)) hosts/$(1)/hex0 < hosts/$(1)/hex0.hex0 > $$$$d/hex0.self; cmp $$$$d/hex0.self hosts/$(1)/hex0; \
	echo "hex-$(1): hex0 makes itself of hex0.hex0"; \
	od -An -v -tx1 $(BUILD)/$(1)/hex2 | tr -cd 0-9a-f | cmp - $$$$d/hex2.text; \
	echo "hex-$(1): hex2 ($$$$(wc -c < $(BUILD)/$(1)/hex2) bytes), made by hex0, is hex2.hex0 without its comments"; \
	cmp $(BUILD)/$(1)/seed.hex $(BUILD)/$(1)/seed.gnu; \
	echo "hex-$(1): hex2 makes of ttpc.hex2 ($$$$(wc -l < hosts/$(1)/ttpc.hex2) lines) the seed binutils makes of ttpc.s ($$$$(wc -c < $(BUILD)/$(1)/seed.gnu) bytes)"

.PHONY: hex-$(1)
endef
$(foreach h,$(HEXHOSTS),$(eval $(call hexhost,$(h))))

# M1 and asm on a host of ASMHOSTS (H5): hexasm-<host> checks them and
# their seed.
define asmhost

$(BUILD)/$(1)/M1: $(BUILD)/$(1)/hex2 hosts/$(1)/M1.hex2
	$(RUN_$(1)) $(BUILD)/$(1)/hex2 < hosts/$(1)/M1.hex2 > $$@.tmp
	chmod +x $$@.tmp
	mv $$@.tmp $$@

$(BUILD)/$(1)/asm: $(BUILD)/$(1)/M1 $(BUILD)/$(1)/hex2 hosts/$(1)/asm.M1
	$(RUN_$(1)) $(BUILD)/$(1)/M1 < hosts/$(1)/asm.M1 > $$@.hex2
	$(RUN_$(1)) $(BUILD)/$(1)/hex2 < $$@.hex2 > $$@.tmp
	chmod +x $$@.tmp
	mv $$@.tmp $$@

$(BUILD)/$(1)/seed.asm: $(BUILD)/$(1)/asm hosts/$(1)/ttpc.s
	$(RUN_$(1)) $(BUILD)/$(1)/asm < hosts/$(1)/ttpc.s > $$@.tmp
	chmod +x $$@.tmp
	mv $$@.tmp $$@

hexasm-$(1): hex-$(1) $(BUILD)/$(1)/M1 $(BUILD)/$(1)/asm $(BUILD)/$(1)/seed.asm $(BUILD)/$(1)/seed.gnu
	@set -e; d=$(BUILD)/$(1)/hex; mkdir -p $$$$d; \
	for f in M1 asm; do $(SEEDCROSS_$(1))as $(SASFLAGS_$(1)) gen/hex/$(1)/$$$$f.s -o $$$$d/$$$$f.o; \
	$(SEEDCROSS_$(1))objcopy -O binary -j .text $$$$d/$$$$f.o $$$$d/$$$$f.gnu; cmp $(BUILD)/$(1)/$$$$f $$$$d/$$$$f.gnu; done; \
	echo "hex-$(1): M1 ($$$$(wc -c < $(BUILD)/$(1)/M1) bytes), made by hex2 of M1.hex2 ($$$$(wc -l < hosts/$(1)/M1.hex2) lines), is what binutils makes of gen/hex/$(1)/M1.s"; \
	echo "hex-$(1): asm ($$$$(wc -c < $(BUILD)/$(1)/asm) bytes), made by M1 and hex2 of asm.M1 ($$$$(wc -l < hosts/$(1)/asm.M1) lines), is what binutils makes of gen/hex/$(1)/asm.s"; \
	cmp $(BUILD)/$(1)/seed.asm $(BUILD)/$(1)/seed.gnu; \
	echo "hex-$(1): asm makes of ttpc.s ($$$$(wc -l < hosts/$(1)/ttpc.s) lines) that seed too"

.PHONY: hexasm-$(1)
endef
$(foreach h,$(ASMHOSTS),$(eval $(call asmhost,$(h))))

# riscv64's seed: as the other hosts', in $(BUILD)/riscv64; $(BIN) is it.
$(BUILD)/riscv64:
	mkdir -p $@

$(BUILD)/riscv64/seed.gnu: hosts/riscv64/ttpc.s | $(BUILD)/riscv64
	$(AS) $(ASFLAGS) $< -o $@.o
	$(LD) -static --no-relax -s -z noseparate-code -e _start $@.o -o $@

$(BIN): $(BUILD)/riscv64/seed.$(call seedkind,riscv64)
	cp $< $@

hex: $(foreach h,$(HEXHOSTS),$(if $(call can,$(h)),hex-$(h) $(if $(filter $(h),$(ASMHOSTS)),hexasm-$(h))))
	@echo "hex: $(foreach h,$(HEXHOSTS),$(if $(call can,$(h)),$(h)))"

# seeds needs ttpc.s to compare with; bootstraps is riscv64 (make bootstrap)
# and every other host this machine runs, from its own seed.
seeds: $(if $(CAN_RISCV),$(RUNNABLE:%=seed-%))
	@echo "seeds: $(if $(CAN_RISCV),$(RUNNABLE) agree with ttpc.s,no $(QEMU) here to run ttpc.s)"
bootstraps: $(if $(CAN_RISCV),bootstrap) $(RUNNABLE:%=bootstrap-%) $(RUNNABLE:%=chello-%)
	@echo "bootstraps: $(strip $(if $(CAN_RISCV),riscv64) $(RUNNABLE))$(if $(filter-out $(RUNNABLE),$(HOSTS)),; not here (no qemu): $(filter-out $(RUNNABLE),$(HOSTS)))"

# ttp's own tools, in ff's C layer instead of Perl (tools/*.ff, compiled by
# stage2): the runtime (tools/rt.ff: raw Linux system calls, no libc, an
# allocator, buffered output), sha256 (tools/sha256.ff) and the ff tree
# (tools/fftree.ff: FF.pm's .ff and .ff.txt reader and writer, the Merkle
# hash), the C words of before (tools/words.ff: Words.pm's oldwords) and
# the host trees (tools/mk.ff: a map of names, FF.pm's frozen, kids and
# holder) and the files (tools/files.ff: errno as Perl's $!, -e, -s,
# canonpath, catfile, dirname, a run of bytes that grows) are library pages;
# each tool is a program with them: fftext as gen/fftext.pl, sha256sum as
# coreutils', unlicense, trim, frozen, mkhost, mkwhole, mkff, decls,
# licenses and insize as gen/unlicense.pl, trim.pl, frozen.pl, mkhost.pl,
# mkwhole.pl, mkff.pl, decls.pl, licenses.pl and insize.pl, ffmerge as
# gen/ffmerge.sh (git merge-file in a child process, each conversion in one).
# $(TL)/<target>/<tool> is one for that target, TOOLT the target this machine runs natively (riscv64 under
# qemu on another). The Perl versions stay, a second implementation:
# tools-check runs sha256sum on NIST's vectors (and Digest::SHA on more),
# fftext and fftext.pl both ways on every tree, unlicense and unlicense.pl on
# every tree (output, messages, status), trim and frozen as the bootstrap
# uses them, mkhost and mkwhole on every tree of the host chains, mkff on
# the shared page and a tree of pages, decls and licenses on what `make
# decls` and `make licenses` check and on trees that fail them, insize on
# the inputs of the links before ttpc3, ffmerge and ffmerge.sh on merges
# (clean, conflicts, a merged text that is not a tree, inputs that are not
# trees, an empty or missing base, the same tree on both sides: the files,
# messages and status), for each target here.
# Which link compiles each: stage2 all of them ($(TL)); ttpc3 unlicense too,
# from tools/old/ ($(BOOT)/unlicense, $(BUILD)/<host>/unlicense), for the
# trees of the chain after it, and a host's ttpc3 mkhost ($(BUILD)/<host>/
# mkhost), for its stage1's ttpc. trim, frozen and mkwhole, and mkhost for
# ttpc2 and ttpc3, make only the committed copies of the links before
# ttpc3 (boot/), so stage2's are enough; so is it for decls, licenses and
# insize, which check the trees after the build, and ffmerge (`make
# git-setup` keeps gen/ffmerge.sh as the driver: a fresh worktree has no
# stage2 yet).
# mkff (tools/mkff.ff, as gen/mkff.pl) makes the shared page: shared.ff.txt,
# a section per target, macros/<target>.ff.txt. A target's forms are an ff
# page (isa/<target>.ff, as isa/<target>.pl) that tools/isa.ff (gen/ISA.pm's
# builder) makes the section's groups of; MKFFLIB are those pages, all four
# targets'. `make refresh` runs it; tools-check runs mkff.pl too (with
# gen/ISA.pm and isa/<target>.pl, the second implementation) and compares.
# mkff runs after stage2 exists (it builds it): the chain reads the
# committed shared.ff and never makes it.
# TOOLFLAGS: stage2 builds them with -O (the user's choice, 2026-10-24);
# ttpc3's from tools/old/ stay without (the frozen ttpc3 has no -O), and so
# do stage1 and stage2.
TOOLFLAGS := -O
TOOLLIB := tools/rt.ff tools/sha256.ff tools/fftree.ff tools/words.ff tools/mk.ff tools/files.ff
MKFFLIB := tools/isa.ff isa/riscv64.ff isa/x86_64.ff isa/aarch64.ff isa/arm.ff
TOOLS := fftext sha256sum unlicense trim frozen mkhost mkwhole mkff decls licenses insize ffmerge
TL := $(BUILD)/tools
RUN_riscv64 := $(QEMU)
TOOLT := $(or $(filter x86_64 riscv64,$(ARCH)),$(if $(filter aarch64 arm64,$(ARCH)),aarch64),$(if $(filter armv7l armv8l,$(ARCH)),arm),riscv64)
TOOLTARGETS := $(if $(CAN_RISCV),riscv64) $(RUNNABLE)
SHAV := $(TL)/vectors
SHAVFILES := abc empty m448 m896 million $(foreach n,0 1 55 56 63 64 65 119 120 127 128 1000 65536 65537,r$(n))

define tooltarget
$(TL)/$(1)/%: tools/%.ff $(TOOLLIB) $(SHARED) $(BOOT)/stage2
	@mkdir -p $$(dir $$@)
	$(QEMU) $(BOOT)/stage2 --target $(1) $(TOOLFLAGS) $(SHARED) $(TOOLLIB) $$< $$@ > $$@.lst
	chmod +x $$@

$(TL)/$(1)/mkff: tools/mkff.ff $(TOOLLIB) $(MKFFLIB) $(SHARED) $(BOOT)/stage2
	@mkdir -p $$(dir $$@)
	$(QEMU) $(BOOT)/stage2 --target $(1) $(TOOLFLAGS) $(SHARED) $(TOOLLIB) $(MKFFLIB) $$< $$@ > $$@.lst
	chmod +x $$@

tools-check-$(1): $(TOOLS:%=$(TL)/$(1)/%) $(SHAV)/want
	cd $(SHAV) && $(RUN_$(1)) $(abspath $(TL))/$(1)/sha256sum $(SHAVFILES) > ../$(1).sha
	cmp $(TL)/$(1).sha $(SHAV)/want
	@echo "tools-check-$(1): sha256 agrees with NIST's vectors and Digest::SHA"
	@for t in $(TREES); do \
	    perl gen/fftext.pl txt $$$$t > $(TL)/$(1).pl.txt && \
	    $(RUN_$(1)) $(TL)/$(1)/fftext txt $$$$t | cmp - $(TL)/$(1).pl.txt && \
	    $(RUN_$(1)) $(TL)/$(1)/fftext ff $(TL)/$(1).pl.txt | cmp - $$$$t || { echo "tools-check-$(1): fftext: $$$$t"; exit 1; }; \
	done
	@echo "tools-check-$(1): fftext and fftext.pl agree on $(words $(TREES)) trees, both ways"
	@for t in $(TREES); do \
	    s=0; perl gen/unlicense.pl $$$$t > $(TL)/$(1).pl.ff 2> $(TL)/$(1).pl.err || s=$$$$?; \
	    f=0; $(RUN_$(1)) $(TL)/$(1)/unlicense $$$$t > $(TL)/$(1).ul.ff 2> $(TL)/$(1).ul.err || f=$$$$?; \
	    test $$$$s = $$$$f && cmp -s $(TL)/$(1).pl.ff $(TL)/$(1).ul.ff && cmp -s $(TL)/$(1).pl.err $(TL)/$(1).ul.err || { echo "tools-check-$(1): unlicense: $$$$t"; exit 1; }; \
	done
	@echo "tools-check-$(1): unlicense and unlicense.pl agree on $(words $(TREES)) trees"
	@set -e; perl gen/unlicense.pl $(SHARED) > $(TL)/$(1).nl.ff; \
	for k in riscv64 "riscv64 x86_64" "riscv64 aarch64" "riscv64 arm"; do \
	    perl gen/trim.pl $(TL)/$(1).nl.ff $$$$k > $(TL)/$(1).pl.ff; \
	    $(RUN_$(1)) $(TL)/$(1)/trim $(TL)/$(1).nl.ff $$$$k | cmp - $(TL)/$(1).pl.ff; \
	    perl gen/frozen.pl $(TL)/$(1).pl.ff > $(TL)/$(1).fz.ff; \
	    $(RUN_$(1)) $(TL)/$(1)/frozen $(TL)/$(1).pl.ff | cmp - $(TL)/$(1).fz.ff; \
	done
	@echo "tools-check-$(1): trim and frozen agree with trim.pl and frozen.pl on the shared pages of the bootstrap"
	@set -e; d=$(TL)/$(1).mk; rm -rf $$$$d; mkdir -p $$$$d/nl; \
	for t in ttpc.defs.ff $(TTPC_FF); do perl gen/unlicense.pl $$$$t > $$$$d/nl/$$$$t; done; \
	for h in $(HOSTS); do \
	    mkdir -p $$$$d/$$$$h/pl $$$$d/$$$$h/ff; \
	    for s in "$(TTPC2_SRC)" "$(TTPC3_SRC)" "$$$$d/nl/ttpc.defs.ff $$$$d/nl/$(TTPC_FF)"; do \
	        perl gen/mkhost.pl $$$$h $$$$d/$$$$h/pl $$$$s; \
	        $(RUN_$(1)) $(TL)/$(1)/mkhost -s $(SHARED) $$$$h $$$$d/$$$$h/ff $$$$s; \
	        for f in $$$$s; do cmp $$$$d/$$$$h/pl/$$$$(basename $$$$f) $$$$d/$$$$h/ff/$$$$(basename $$$$f); done; \
	    done; \
	    perl gen/mkwhole.pl $$$$h $$$$d/$$$$h/pl/ttpc2.defs.ff $$$$d/$$$$h/pl/ttpc2.ff > $$$$d/$$$$h/whole.pl; \
	    $(RUN_$(1)) $(TL)/$(1)/mkwhole -s $(SHARED) $$$$h $$$$d/$$$$h/pl/ttpc2.defs.ff $$$$d/$$$$h/pl/ttpc2.ff | cmp - $$$$d/$$$$h/whole.pl; \
	done; \
	perl gen/mkwhole.pl riscv64 $(TTPC2_SRC) > $$$$d/whole.pl; \
	$(RUN_$(1)) $(TL)/$(1)/mkwhole -s $(SHARED) riscv64 $(TTPC2_SRC) | cmp - $$$$d/whole.pl; \
	for k in mkhost mkwhole; do \
	    s=0; perl gen/$$$$k.pl mips $$$$d ttpc2.ff > /dev/null 2> $$$$d/pl.err || s=$$$$?; \
	    f=0; $(RUN_$(1)) $(TL)/$(1)/$$$$k -s $(SHARED) mips $$$$d ttpc2.ff > /dev/null 2> $$$$d/ff.err || f=$$$$?; \
	    test $$$$s = $$$$f; cmp $$$$d/pl.err $$$$d/ff.err; \
	done
	@echo "tools-check-$(1): mkhost and mkwhole agree with mkhost.pl and mkwhole.pl on the trees of the host chains"
	@set -e; perl gen/mkff.pl > $(TL)/$(1).shared.pl; \
	$(RUN_$(1)) $(TL)/$(1)/mkff | cmp - $(TL)/$(1).shared.pl; \
	perl gen/mkff.pl gen/license.ff.txt macros/riscv64.ff.txt > $(TL)/$(1).shared.pl; \
	$(RUN_$(1)) $(TL)/$(1)/mkff gen/license.ff.txt macros/riscv64.ff.txt | cmp - $(TL)/$(1).shared.pl
	@echo "tools-check-$(1): mkff and mkff.pl make the same shared page (every section from isa/<target>.ff), and the same tree of pages"
	@set -e; d=$(TL)/$(1).dl; rm -rf $$$$d; mkdir -p $$$$d; \
	same() { k=$$$$1; shift; \
	    s=0; perl gen/$$$$k.pl "$$$$@" > $$$$d/pl.out 2> $$$$d/pl.err || s=$$$$?; \
	    f=0; $(RUN_$(1)) $(TL)/$(1)/$$$$k "$$$$@" > $$$$d/ff.out 2> $$$$d/ff.err || f=$$$$?; \
	    test $$$$s = $$$$f && cmp -s $$$$d/pl.out $$$$d/ff.out && cmp -s $$$$d/pl.err $$$$d/ff.err || { echo "tools-check-$(1): $$$$k $$$$*: $$$$s $$$$f"; exit 1; }; }; \
	awk '/^[^ ]/ { d = $$$$0 == "comment:" || $$$$0 == "+=:" || $$$$0 == "long:" } !d' shared.ff.txt > $$$$d/shared.ff.txt; \
	same decls shared.ff.txt $(TTPC_FF); same decls $$$$d/shared.ff.txt $(TTPC_FF); same decls shared.ff.txt $(SHARED); same decls $$$$d/none $(TTPC_FF); \
	printf 'license\n  MIT OR (ISC\n  a notice\nx:\n  license\n    Foo WITH Bar\n    n\n  y\n    license\n      MIT\nc:\n  f:\n    long\nt:\n  s:\n    struct\n' > $$$$d/a.ff.txt; \
	printf 'x:\n  long\nlicense\n  MIT WITH LLVM-exception\n  n\n    m\n' > $$$$d/b.ff.txt; \
	printf '# frozen\na.ff.txt  MIT\n./none.ff GPL-3.0-only\nb.ff.txt (MIT) AND\n' > $$$$d/sc; \
	printf 'license\n  GPL-3.0-or-whatever\n  a notice\n' > $$$$d/bad.ff.txt; \
	same licenses --sidecar LICENSES $(LICENSED); same licenses $$$$d/bad.ff.txt; \
	same licenses --pages $$$$d/a.ff.txt $$$$d/b.ff.txt; same licenses --fragment $$$$d/b.ff.txt; same licenses --sidecar $$$$d/sc $$$$d/a.ff.txt $$$$d/b.ff.txt; \
	same licenses --fragment ../glibc/builtins.ff.txt ../glibc/atomics.ff.txt; same licenses $$$$d/a.ff.txt $$$$d/none; same licenses --pages $(TTPC_FF)
	@echo "tools-check-$(1): decls and licenses agree with decls.pl and licenses.pl (output, messages, status) on the trees they check and on ones that fail"
	@set -e; d=$(TL)/$(1).dl; \
	same() { k=$$$$1; shift; \
	    s=0; perl gen/$$$$k.pl "$$$$@" > $$$$d/pl.out 2> $$$$d/pl.err || s=$$$$?; \
	    f=0; $(RUN_$(1)) $(TL)/$(1)/$$$$k "$$$$@" > $$$$d/ff.out 2> $$$$d/ff.err || f=$$$$?; \
	    test $$$$s = $$$$f && cmp -s $$$$d/pl.out $$$$d/ff.out && cmp -s $$$$d/pl.err $$$$d/ff.err || { echo "tools-check-$(1): $$$$k $$$$*: $$$$s $$$$f"; exit 1; }; }; \
	same insize ttpc1 boot/riscv64/shared.ff $(TTPC2_SRC); same insize ttpc2 boot/riscv64/shared1.ff $(TTPC3_SRC); \
	for h in $(HOSTS); do same insize ttpc2 boot/$$$$h/shared1.ff boot/$$$$h/ttpc3.defs.ff boot/$$$$h/ttpc3.ff; done; \
	same insize ttpc2 $(SHARED) $(SHARED); same insize ttpc2 $(SHARED) $$$$d/none
	@echo "tools-check-$(1): insize agrees with insize.pl on the links before ttpc3, on too much and on a file that is not there"
	@set -e; d=$(abspath $(TL))/$(1).fm; rm -rf $$$$d; mkdir -p $$$$d/in $$$$d/tmp; \
	ff() { perl gen/fftext.pl ff /dev/stdin > $$$$d/in/$$$$1; }; \
	printf 'a:\n  long\n  1\nb:\n  long\n  2\nc:\n  long\n  3\n' | ff base.ff; \
	printf 'a:\n  long\n  10\nb:\n  long\n  2\nc:\n  long\n  3\n' | ff o.ff; \
	printf 'a:\n  long\n  1\nb:\n  long\n  2\nc:\n  long\n  30\n' | ff t.ff; \
	printf 'a:\n  long\n  11\nb:\n  long\n  2\nc:\n  long\n  3\n' | ff t2.ff; \
	{ echo a; seq -f '  k%g' 254; } | ff b3.ff; { echo a; echo '  first'; seq -f '  k%g' 254; } | ff o3.ff; { echo a; seq -f '  k%g' 254; echo '  last'; } | ff t3.ff; \
	printf 'not a tree\n' > $$$$d/in/bad.ff; : > $$$$d/in/empty.ff; head -c 40 $$$$d/in/o.ff > $$$$d/in/cut.ff; \
	perl -Igen -MFF=node,write_ff -e 'binmode STDOUT; print write_ff(node("x", node("y")))' > $$$$d/in/root.ff; \
	same() { for w in sh ff; do \
	    rm -rf $$$$d/$$$$w; mkdir $$$$d/$$$$w; for f in "$$$$1" "$$$$2" "$$$$3"; do if test -e $$$$d/in/$$$$f; then cp $$$$d/in/$$$$f $$$$d/$$$$w/; fi; done; \
	    if test $$$$w = sh; then c="sh $(abspath gen/ffmerge.sh)"; else c="$(RUN_$(1)) $(abspath $(TL))/$(1)/ffmerge"; fi; \
	    s=0; (cd $$$$d/$$$$w && TMPDIR=$$$$d/tmp $$$$c "$$$$@" > out 2> err) || s=$$$$?; echo $$$$s > $$$$d/$$$$w/status; \
	    sed -i 's|/ffmerge\.[A-Za-z0-9]*/|/T/|g' $$$$d/$$$$w/err; done; \
	    diff -r $$$$d/sh $$$$d/ff > /dev/null && test -z "$$$$(ls $$$$d/tmp)" || { echo "tools-check-$(1): ffmerge $$$$*"; exit 1; }; }; \
	same base.ff o.ff t.ff; same base.ff o.ff t2.ff; same base.ff o.ff t2.ff sub/o.ff; same b3.ff o3.ff t3.ff; \
	same base.ff bad.ff t.ff; same bad.ff o.ff t.ff; same base.ff o.ff cut.ff; same base.ff root.ff t.ff; \
	same empty.ff o.ff t.ff; same none.ff o.ff t.ff; same empty.ff o.ff t2.ff; same base.ff o.ff o.ff; same o.ff o.ff o.ff; same base.ff none.ff t.ff
	@echo "tools-check-$(1): ffmerge agrees with ffmerge.sh on clean merges, conflicts, a merged text that is not a tree, inputs that are not trees, an empty or missing base and the same tree on both sides"
endef
$(foreach t,riscv64 $(HOSTS),$(eval $(call tooltarget,$(t))))

# NIST's vectors (FIPS 180-2, appendix B: abc, 448 and 896 bits, a million
# a), the empty message and random ones about the block's edges: what
# Digest::SHA makes of them, after it agrees with NIST.
$(SHAV)/want:
	@mkdir -p $(SHAV)
	cd $(SHAV) && printf abc > abc && printf '' > empty && \
	    printf abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq > m448 && \
	    printf abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu > m896 && \
	    perl -e 'print "a" x 1000000' > million && \
	    perl -e 'srand 1; for (@ARGV) { open my $$f, ">:raw", "r$$_" or die; print $$f join "", map { chr int rand 256 } 1 .. $$_ }' 0 1 55 56 63 64 65 119 120 127 128 1000 65536 65537
	cd $(SHAV) && perl -MDigest::SHA=sha256_hex -e 'for (@ARGV) { open my $$f, "<:raw", $$_ or die; local $$/; print sha256_hex(<$$f> // ""), "  $$_\n" }' $(SHAVFILES) > want.tmp
	printf '%s\n' ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad \
	    e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 \
	    248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1 \
	    cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1 \
	    cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0 > $(SHAV)/nist.want
	head -n 5 $(SHAV)/want.tmp | cut -d' ' -f1 | cmp - $(SHAV)/nist.want
	mv $(SHAV)/want.tmp $@

tools: $(TOOLS:%=$(TL)/$(TOOLT)/%)
tools-check: $(TOOLTARGETS:%=tools-check-%)

# The committed copies (boot/, tools/old/, see NL above), made again by
# stage2's tools after a source of theirs changed: shared.ff, a tool.
CT := $(TL)/$(TOOLT)
RUNT := $(RUN_$(TOOLT))

# Every name ttpc takes itself (its words, operators and types) is declared
# on the shared page, with its parameters, even one that does nothing
# (comment:), so that an editor can offer a call of it. decls is
# tools/decls.ff, built by stage2 ($(CT), see TOOLLIB); gen/decls.pl, the
# second implementation, gives the same in tools-check.
decls: $(CT)/decls
	@$(RUNT) $(CT)/decls shared.ff.txt $(TTPC_FF)

# The licenses of the trees (LICENSED, above).
licenses: $(CT)/licenses | $(BUILD)
	@$(RUNT) $(CT)/licenses --sidecar LICENSES $(LICENSED)
	@printf 'license\n  GPL-3.0-or-whatever\n  a notice\n' > $(BUILD)/badlicense.ff.txt
	@! $(RUNT) $(CT)/licenses $(BUILD)/badlicense.ff.txt > $(BUILD)/badlicense.out
	@grep -q "unknown SPDX id GPL-3.0-or-whatever" $(BUILD)/badlicense.out
	@echo "licenses: a tree with an unknown SPDX id fails"

copies: $(CT)/unlicense $(CT)/trim $(CT)/frozen $(CT)/mkhost $(CT)/mkwhole
	@set -e; $(RUNT) $(CT)/unlicense $(SHARED) > $(TL)/copies.nl.ff; \
	$(RUNT) $(CT)/trim $(TL)/copies.nl.ff riscv64 > boot/riscv64/shared1.ff; \
	$(RUNT) $(CT)/frozen boot/riscv64/shared1.ff > boot/riscv64/shared.ff; \
	for h in $(HOSTS); do \
	    $(RUNT) $(CT)/trim $(TL)/copies.nl.ff riscv64 $$h > boot/$$h/shared1.ff; \
	    $(RUNT) $(CT)/mkhost -s $(SHARED) $$h boot/$$h $(TTPC2_SRC); \
	    $(RUNT) $(CT)/mkhost -s $(SHARED) $$h boot/$$h $(TTPC3_SRC); \
	    $(RUNT) $(CT)/mkwhole -s $(SHARED) $$h boot/$$h/ttpc2.defs.ff boot/$$h/ttpc2.ff > boot/$$h/whole.ff; \
	done; \
	for t in $(OLDTOOLS); do $(RUNT) $(CT)/unlicense $(OLDTYPES) tools/$$t.ff > tools/old/$$t.ff; done
	@echo "copies: $(COPIES)"

# Each committed copy is what the ff tools (stage2's, and ttpc3's unlicense)
# and the Perl make of its source, and each tree ttpc3's unlicense makes for
# the chain is what unlicense.pl makes, so is what a host's ttpc3's mkhost
# makes for its stage1 what mkhost.pl makes; the links before ttpc3 get at
# most 3.5 MiB (insize, as insize.pl in tools-check).
copies-check: $(CT)/unlicense $(CT)/trim $(CT)/frozen $(CT)/mkhost $(CT)/mkwhole $(CT)/insize $(BOOT)/unlicense $(TTPC_SRC:%=$(NL)/%) $(PROGS:%=$(NL)/progs/riscv64/%.ff) $(RUNNABLE:%=$(BUILD)/%/ttpc.ff)
	@set -e; d=$(TL)/copies; mkdir -p $$d; \
	perl gen/unlicense.pl $(SHARED) > $$d/nl.pl; $(RUNT) $(CT)/unlicense $(SHARED) | cmp - $$d/nl.pl; \
	$(QEMU) $(BOOT)/unlicense $(SHARED) | cmp - $$d/nl.pl; \
	for k in riscv64 x86_64 aarch64 arm; do \
	    if test $$k = riscv64; then a=riscv64; else a="riscv64 $$k"; fi; \
	    perl gen/trim.pl $$d/nl.pl $$a | cmp - boot/$$k/shared1.ff; \
	    $(RUNT) $(CT)/trim $$d/nl.pl $$a | cmp - boot/$$k/shared1.ff; \
	done; \
	perl gen/frozen.pl boot/riscv64/shared1.ff | cmp - boot/riscv64/shared.ff; \
	$(RUNT) $(CT)/frozen boot/riscv64/shared1.ff | cmp - boot/riscv64/shared.ff; \
	echo "copies-check: boot/: ttpc1's and ttpc2's shared pages, as the ff tools and the Perl make them"; \
	for h in $(HOSTS); do \
	    rm -rf $$d/$$h; mkdir -p $$d/$$h/pl $$d/$$h/ff; \
	    for s in "$(TTPC2_SRC)" "$(TTPC3_SRC)"; do \
	        perl gen/mkhost.pl $$h $$d/$$h/pl $$s; $(RUNT) $(CT)/mkhost -s $(SHARED) $$h $$d/$$h/ff $$s; \
	    done; \
	    for f in ttpc2.ff ttpc2.defs.ff ttpc3.ff ttpc3.defs.ff; do cmp $$d/$$h/pl/$$f boot/$$h/$$f; cmp $$d/$$h/ff/$$f boot/$$h/$$f; done; \
	    perl gen/mkwhole.pl $$h boot/$$h/ttpc2.defs.ff boot/$$h/ttpc2.ff | cmp - boot/$$h/whole.ff; \
	    $(RUNT) $(CT)/mkwhole -s $(SHARED) $$h boot/$$h/ttpc2.defs.ff boot/$$h/ttpc2.ff | cmp - boot/$$h/whole.ff; \
	done; \
	echo "copies-check: boot/<host>/: the hosts' ttpc2, ttpc3 and whole tree, as the ff tools and the Perl make them"; \
	for h in $(RUNNABLE); do \
	    mkdir -p $$d/$$h/st; perl gen/mkhost.pl $$h $$d/$$h/st $(BUILD)/$$h/nl/ttpc.defs.ff $(BUILD)/$$h/nl/$(TTPC_FF); \
	    cmp $$d/$$h/st/ttpc.defs.ff $(BUILD)/$$h/ttpc.defs.ff; cmp $$d/$$h/st/$(TTPC_FF) $(BUILD)/$$h/$(TTPC_FF); \
	done; \
	echo "copies-check: the mkhost of each host's ttpc3 ($(RUNNABLE)) makes its stage1's ttpc as mkhost.pl"; \
	for t in $(OLDTOOLS); do \
	    perl gen/unlicense.pl $(OLDTYPES) tools/$$t.ff | cmp - tools/old/$$t.ff; \
	    $(RUNT) $(CT)/unlicense $(OLDTYPES) tools/$$t.ff | cmp - tools/old/$$t.ff; \
	    $(QEMU) $(BOOT)/unlicense $(OLDTYPES) tools/$$t.ff | cmp - tools/old/$$t.ff; \
	done; \
	echo "copies-check: tools/old/: the tools in the words of before, as the ff tools and the Perl make them"; \
	for t in $(TTPC_SRC) $(PROGS:%=progs/riscv64/%.ff); do perl gen/unlicense.pl $$t | cmp - $(NL)/$$t; done; \
	echo "copies-check: ttpc3's unlicense makes the trees of the chain as unlicense.pl"
	$(RUNT) $(CT)/insize ttpc1 boot/riscv64/shared.ff $(TTPC2_SRC)
	$(RUNT) $(CT)/insize ttpc2 boot/riscv64/shared1.ff $(TTPC2_SRC)
	$(RUNT) $(CT)/insize ttpc2 boot/riscv64/shared1.ff $(TTPC3_SRC)
	@for h in $(HOSTS); do \
	    $(RUNT) $(CT)/insize ttpc2 boot/$$h/shared1.ff boot/$$h/ttpc2.defs.ff boot/$$h/ttpc2.ff && \
	    $(RUNT) $(CT)/insize ttpc2 boot/$$h/shared1.ff boot/$$h/ttpc3.defs.ff boot/$$h/ttpc3.ff || exit 1; \
	done

# Make shared.ff again from shared.ff.txt, isa/*.ff and macros/, after
# changing any of them: mkff (tools/mkff.ff, this machine's, see MKFFLIB),
# built by stage2 with the shared page of before; mkff.pl, ISA.pm and
# isa/*.pl make the same in tools-check. x86_64gnu.ff is still made by
# gen/mkgnuff.pl (from isa/x86_64gnu.pl's forms, outside the chain: only a
# build of x86_64 asm reads it). The whole trees keep the shared pages they have.
refresh: $(CT)/mkff
	$(RUNT) $(CT)/mkff > $(SHARED).tmp && mv $(SHARED).tmp $(SHARED)
	perl gen/mkgnuff.pl > $(X86GNU).tmp && mv $(X86GNU).tmp $(X86GNU)

# The committed shared.ff and x86_64gnu.ff are what refresh makes of their
# sources (made again in a folder of their own): a source changed without
# refresh, or shared.ff patched alone (which the next refresh would drop),
# fails here.
refresh-check: $(CT)/mkff
	@set -e; d=$(TL)/refresh; rm -rf $$d; mkdir -p $$d; \
	$(RUNT) $(CT)/mkff > $$d/$(SHARED); \
	cmp $$d/$(SHARED) $(SHARED) || { echo "refresh-check: $(SHARED) is not what make refresh makes of shared.ff.txt, macros/ and isa/"; exit 1; }; \
	perl gen/mkgnuff.pl > $$d/$(X86GNU); \
	cmp $$d/$(X86GNU) $(X86GNU) || { echo "refresh-check: $(X86GNU) is not what make refresh makes of isa/x86_64gnu.pl"; exit 1; }; \
	echo "refresh-check: $(SHARED) and $(X86GNU) are what make refresh makes"

# A change of ttpc is a patch script (gen/patches/*.pl, see gen/patchlib.pl),
# committed with the tree it changes, so that it can be replayed when a
# merge of the tree conflicts: T (ttpc.ff) is dumped to text, the script
# P edits the text, and the text becomes T again. A text tree (T=*.txt:
# macros/<target>.ff.txt, then make refresh) the script edits as it is.
T ?= $(TTPC_FF)
patch: | $(BUILD)
	@test -n "$(P)" || { echo "usage: make patch P=gen/patches/x.pl [T=ttpc.ff]"; exit 1; }
ifneq ($(filter %.txt,$(T)),)
	PATCHLIB=$(CURDIR)/gen/patchlib.pl perl $(P) $(T)
else
	perl gen/fftext.pl txt $(T) > $(BUILD)/patch.ff.txt
	PATCHLIB=$(CURDIR)/gen/patchlib.pl perl $(P) $(BUILD)/patch.ff.txt
	perl gen/fftext.pl ff $(BUILD)/patch.ff.txt > $(BUILD)/patch.ff
	mv $(BUILD)/patch.ff $(T)
endif
	@echo "patch: $(P) on $(T)"

clean:
	rm -rf $(BUILD)

.PHONY: all test roundtrip decls check rvv simd run bootstrap ctest ctime cws targets seeds hex bootstraps refresh refresh-check patch clean licenses abi debug tools tools-check copies copies-check $(foreach t,riscv64 $(HOSTS),tools-check-$(t))
