# ttpc is plain RISC-V assembly, no libc: assembled and linked with the
# bare-metal cross binutils into a static Linux riscv64 executable that only
# makes raw syscalls. On riscv64 it runs natively, elsewhere under qemu-riscv64.
# Without the cross binutils (no Nix) a host's own as and ld do for it.
ARCH := $(shell uname -m)
have = $(shell command -v $(1) 2>/dev/null)
native_or = $(if $(call have,$(2)as),$(2),$(if $(filter $(1),$(ARCH)),,$(2)))
CROSS   ?= $(call native_or,riscv64,riscv64-none-elf-)
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS ?= -march=rv64imac -mabi=lp64
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
OBJ := $(BUILD)/ttpc.o

# The ff sources, edited in sicompass. ttpc is a program of only its own,
# ttpc.ff, with its constants in ttpc.defs.ff, on the shared page
# (shared.ff, from mkff.pl): ttpc --target riscv64 shared.ff ttpc.defs.ff
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
CPROGS := cexit cfib cloop chello cexpr cstruct cnow cct cct2 cunroll ctasm ctmix celse casm casm2 casmfail cstring cscope cint cint64 cflow ctypes cself cunion cbits cinit ccalls cvarargs ctls clib cifunc cifuncaddr cifunclib ccomplit casmfn cincdec cparen cdot cgroups ccast caddrc cweak cifvalue cvapack cfloat cfloats cfloats32 cgnu cpath ccond clabels calloca caddrlit canon casmentry cloopsp cvamem cnullary clayers clayerslib clazy ctlstp cpair cpaircall cpairmul cchar cfnaddr cvlasize carraylit clicense calign cldlit cgroupdot casmalign ccomplex cbodylayers cgeneric csection creach cldneg ctextitem cemptyitem
SHARED := shared.ff
# the forms GNU as picks for x86_64, for its asm alone (gen/mkgnuff.pl)
X86GNU := x86_64gnu.ff
WHOLE := $(TTPC1_FF) $(PROGS:%=progs/riscv64/%.ff)
TREES := $(WHOLE) $(SHARED) ttpc.defs.ff $(TTPC_FF) $(TTPC2_SRC) $(TTPC3_SRC) $(filter-out $(WHOLE) progs/clazylib/never.ff,$(wildcard progs/*/*.ff)) $(CPROGS:%=progs/%.ff) progs/cnowfail.ff progs/creserved.ff progs/cmisplaced.ff \
	progs/cws.ff progs/cinclude.ff progs/cwsnofile.ff progs/cwsplace.ff progs/cincludelate.ff \
	progs/clibdefs.ff progs/cpathdefs.ff progs/cifuncdefs.ff progs/casmfndefs.ff progs/casmaligndefs.ff progs/casmentrydefs.ff progs/cweakdefs.ff progs/clayerslibdefs.ff progs/cuntyped.ff progs/citems.ff progs/cchartext.ff progs/ctypeout.ff progs/cbelow.ff progs/creachdefs.ff progs/ctextitemdefs.ff language.ff
P := $(BUILD)/progs

# The trees as the frozen ttpcs read them (stage0 and the seeds of the
# hosts, ttpc1, ttpc2, ttpc3): without their licenses, a word younger than
# they are (gen/unlicense.pl). A license emits nothing, so what they make is
# the same; stage1 makes stage2 from the trees with their licenses, and
# stage1 == stage2 checks it.
NL := $(BUILD)/nl
$(NL)/%.ff: %.ff gen/unlicense.pl gen/FF.pm
	@mkdir -p $(dir $@)
	perl gen/unlicense.pl $< > $@

all: $(BIN)

$(BUILD) $(P):
	mkdir -p $@

$(OBJ): hosts/riscv64/ttpc.s | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $@

$(BIN): $(OBJ)
	$(LD) -static --no-relax -e _start $< -o $@

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

# Every name ttpc takes itself (its words, operators and types) is declared
# on the shared page, with its parameters, even one that does nothing
# (comment:), so that an editor can offer a call of it.
decls:
	@perl gen/decls.pl shared.ff.txt $(TTPC_FF)

# Every tree has its license at its root (license / SPDX expression / the
# notice, a line per child), its SPDX ids known to gen/spdx.txt; the frozen
# files, which stay as they are, have theirs in LICENSES. A tree with an
# unknown id fails.
LICENSED := $(TREES) $(X86GNU) shared.ff.txt $(wildcard macros/*.ff.txt) language.ff.txt gen/license.ff.txt
licenses: | $(BUILD)
	@perl gen/licenses.pl --sidecar LICENSES $(LICENSED)
	@printf 'license\n  GPL-3.0-or-whatever\n  a notice\n' > $(BUILD)/badlicense.ff.txt
	@! perl gen/licenses.pl $(BUILD)/badlicense.ff.txt > $(BUILD)/badlicense.out
	@grep -q "unknown SPDX id GPL-3.0-or-whatever" $(BUILD)/badlicense.out
	@echo "licenses: a tree with an unknown SPDX id fails"

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

# The bootstrap, a chain of versions. ttpc.s (hosts/riscv64/), assembled
# by GNU as, is stage0. ttpc1.ff, frozen like ttpc.s, is ttpc in the
# language of stage0, a whole tree below its 1 MiB: stage0 assembles it
# into ttpc1, which must assemble itself into itself, assemble every asm
# program and print ttpc1.ff exactly as stage0 does. ttpc1 assembles ttpc2
# (TTPC2_SRC, ttpc.ff frozen when the seeds' 1 MiB got tight), which must
# assemble itself into itself; ttpc2 assembles ttpc3 (TTPC3_SRC, ttpc.ff
# frozen when it learnt layers, 0: 1: ..., before using them), which must
# assemble itself into itself; ttpc3 assembles ttpc (TTPC_SRC) into stage1,
# stage1 assembles it into stage2: they must be the same, the fixed point.
# ttpc1 gets shared.ff in its own language
# (frozen.pl): without the comments, which it knows only in code, and
# without else if:, which it would take for a register. Neither emits
# anything: stage1 is the same. ttpc1 and ttpc2 get it with only the
# sections they assemble with (trim.pl), for their 4 MiB of input, and
# insize.pl stops a link of theirs whose input passes 3.5 MiB.
BOOT := $(BUILD)/boot

$(BOOT):
	mkdir -p $@

$(BOOT)/ttpc1: $(TTPC1_FF) $(BIN) | $(BOOT)
	$(QEMU) $(BIN) $< $@ > $@.lst

$(BOOT)/ttpc1.self: $(TTPC1_FF) $(BOOT)/ttpc1
	$(QEMU) $(BOOT)/ttpc1 $< $@ > $@.lst

$(BOOT)/shared.ff: $(BOOT)/shared1.ff gen/frozen.pl gen/FF.pm | $(BOOT)
	perl gen/frozen.pl $< > $@

$(BOOT)/ttpc2: $(BOOT)/shared.ff $(TTPC2_SRC) $(BOOT)/ttpc1 gen/insize.pl
	perl gen/insize.pl ttpc1 $(BOOT)/shared.ff $(TTPC2_SRC)
	$(QEMU) $(BOOT)/ttpc1 --target riscv64 $(BOOT)/shared.ff $(TTPC2_SRC) $@ > $@.lst

$(BOOT)/ttpc2.self: $(BOOT)/shared1.ff $(TTPC2_SRC) $(BOOT)/ttpc2 gen/insize.pl
	perl gen/insize.pl ttpc2 $(BOOT)/shared1.ff $(TTPC2_SRC)
	$(QEMU) $(BOOT)/ttpc2 --target riscv64 $(BOOT)/shared1.ff $(TTPC2_SRC) $@ > $@.lst

# ttpc1 and ttpc2 read at most 4 MiB: they get shared.ff with only riscv64's
# section (trim.pl), which is all that emits anything for them.
$(BOOT)/shared1.ff: $(NL)/$(SHARED) gen/trim.pl gen/FF.pm | $(BOOT)
	perl gen/trim.pl $< riscv64 > $@

$(BOOT)/ttpc3: $(TTPC3_SRC) $(BOOT)/ttpc2 $(BOOT)/shared1.ff gen/insize.pl
	perl gen/insize.pl ttpc2 $(BOOT)/shared1.ff $(TTPC3_SRC)
	$(QEMU) $(BOOT)/ttpc2 --target riscv64 $(BOOT)/shared1.ff $(TTPC3_SRC) $@ > $@.lst

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
	$(QEMU) $(BOOT)/stage2 $(SHARED) $< $@ > $(P)/$*.lst

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
# above its declaration.
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
# set output (next to cws.ff), each the bytes the command line makes. cinclude is chello including its shared page, --print prints a tree
# as stage0 does, and cwsnofile, cwsplace and cincludelate fail to compile
# with their message. cws.ff writes into ../../../build/compiler/progs, the
# default BUILD.
cws: $(P)/chello.celf $(P)/x86_64/chello.celf $(P)/cexit.celf
	rm -f progs/cexit
	cd $(P) && $(QEMU) $(abspath $(BOOT))/stage2 $(CURDIR)/progs/cws.ff > cws.lst
	mv progs/cexit $(P)/cws-cexit
	cmp $(P)/cws-riscv64 $(P)/chello.celf
	cmp $(P)/cws-x86_64 $(P)/x86_64/chello.celf
	cmp $(P)/cws-cexit $(P)/cexit.celf
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
CPORTABLE := cexit cfib cloop chello cexpr cstruct cnow cct cct2 cunroll celse casm casm2 cstring cscope cint cint64 cflow ctypes cself cunion cbits cinit ccalls cvarargs ctls clib cifunc cifuncaddr cifunclib ccomplit cincdec cparen cdot cgroups ccast caddrc cweak cifvalue cvapack cfloat cfloats cfloats32 cgnu cpath ccond clabels calloca caddrlit canon cloopsp cvamem cnullary clayers clayerslib clazy cpair cpaircall cpairmul cchar cfnaddr cvlasize carraylit calign cldlit cgroupdot casmalign ccomplex cbodylayers cgeneric csection cglobcast creach cldneg ctextitem cemptyitem
# cgnu has bitfields of u64, which arm does not have yet (a pair as the unit).
CSKIP_arm := cgnu
# C tests of one target only, beside the portable ones
CONLY_aarch64 := ctlsa64

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
	$(QEMU) $(BOOT)/stage2 --target $(1) $(SHARED) $$< $$@ > $(P)/$(1)/$$*.lst

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
# (the AAPCS, gen/patches/abi.pl) and aarch64 (AAPCS64, abia64.pl).
ABI_TARGETS := arm aarch64
abi: $(BOOT)/stage2 $(SHARED)
	@for t in $(ABI_TARGETS); do TTPC="$(QEMU) $(BOOT)/stage2" sh progs/abi/run.sh $$t $(P)/abi-$$t > $(P)/abi-$$t.log 2>&1 || { cat $(P)/abi-$$t.log; exit 1; }; tail -n 1 $(P)/abi-$$t.log; done

targets: $(TARGETS:%=check-%) $(TARGETS:%=ctest-%) x86gnu
	! $(QEMU) $(BOOT)/stage2 --target mips $(SHARED) progs/cexit.ff $(P)/mips.celf 2> $(P)/mips.err
	grep -q "compile time: mips is not a target" $(P)/mips.err
	@echo "targets: $(TARGETS) and riscv64"

# The bootstrap on the other hosts, without riscv64. hosts/<host>/ttpc.s is
# the seed there, a port of ttpc.s (with OUT_SIZE 1 MiB): it must agree
# with ttpc.s on everything ttpc.s does (seed-<host>). ttpc is written in
# RV64: mkhost.pl makes its ops rv.op, which the host's rv64: group defines
# in the host's instructions, and mkwhole.pl makes of that a whole tree in
# the language of the seed, of ttpc2 (the whole tree of ttpc.ff would no
# longer fit the seed's 1 MiB). The seed assembles it into ttpc2, which
# assembles itself into itself and ttpc3 (mkhost.pl's too), which assembles
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
SASFLAGS_x86_64 :=
SASFLAGS_aarch64 :=
SASFLAGS_arm := -march=armv7-a
SEED_FF := ttpc1.ff $(PROGS:%=$(NL)/progs/riscv64/%.ff)

define host

$(BUILD)/$(1):
	mkdir -p $$@

$(BUILD)/$(1)/seed: hosts/$(1)/ttpc.s | $(BUILD)/$(1)
	$(SEEDCROSS_$(1))as $(SASFLAGS_$(1)) $$< -o $$@.o
	$(SEEDCROSS_$(1))ld -static -e _start $$@.o -o $$@

$(BUILD)/$(1)/ttpc.ff: $(NL)/$(TTPC_FF) $(NL)/ttpc.defs.ff $(SHARED) gen/mkhost.pl | $(BUILD)/$(1)
	perl gen/mkhost.pl $(1) $(BUILD)/$(1) $(NL)/ttpc.defs.ff $(NL)/$(TTPC_FF)

$(BUILD)/$(1)/ttpc.defs.ff: $(BUILD)/$(1)/ttpc.ff

$(BUILD)/$(1)/ttpc2.ff: $(TTPC2_SRC) $(SHARED) gen/mkhost.pl | $(BUILD)/$(1)
	perl gen/mkhost.pl $(1) $(BUILD)/$(1) $(TTPC2_SRC)

$(BUILD)/$(1)/ttpc2.defs.ff: $(BUILD)/$(1)/ttpc2.ff

$(BUILD)/$(1)/whole.ff: $(BUILD)/$(1)/ttpc2.ff $(BUILD)/$(1)/ttpc2.defs.ff gen/mkwhole.pl
	perl gen/mkwhole.pl $(1) $(BUILD)/$(1)/ttpc2.defs.ff $(BUILD)/$(1)/ttpc2.ff > $$@

$(BUILD)/$(1)/ttpc2: $(BUILD)/$(1)/whole.ff $(BUILD)/$(1)/seed
	$(RUN_$(1)) $(BUILD)/$(1)/seed $$< $$@ > $$@.lst

$(BUILD)/$(1)/ttpc2.self: $(BUILD)/$(1)/ttpc2 $(BUILD)/$(1)/shared1.ff gen/insize.pl
	perl gen/insize.pl ttpc2 $(BUILD)/$(1)/shared1.ff $(BUILD)/$(1)/ttpc2.defs.ff $(BUILD)/$(1)/ttpc2.ff
	$(RUN_$(1)) $$< --target $(1) $(BUILD)/$(1)/shared1.ff $(BUILD)/$(1)/ttpc2.defs.ff $(BUILD)/$(1)/ttpc2.ff $$@ > $$@.lst

$(BUILD)/$(1)/shared1.ff: $(NL)/$(SHARED) gen/trim.pl gen/FF.pm | $(BUILD)/$(1)
	perl gen/trim.pl $$< riscv64 $(1) > $$@

$(BUILD)/$(1)/ttpc3.ff: $(TTPC3_SRC) $(SHARED) gen/mkhost.pl | $(BUILD)/$(1)
	perl gen/mkhost.pl $(1) $(BUILD)/$(1) $(TTPC3_SRC)

$(BUILD)/$(1)/ttpc3.defs.ff: $(BUILD)/$(1)/ttpc3.ff

$(BUILD)/$(1)/ttpc3: $(BUILD)/$(1)/ttpc2 $(BUILD)/$(1)/ttpc3.ff $(BUILD)/$(1)/ttpc3.defs.ff $(BUILD)/$(1)/shared1.ff gen/insize.pl
	perl gen/insize.pl ttpc2 $(BUILD)/$(1)/shared1.ff $(BUILD)/$(1)/ttpc3.defs.ff $(BUILD)/$(1)/ttpc3.ff
	$(RUN_$(1)) $$< --target $(1) $(BUILD)/$(1)/shared1.ff $(BUILD)/$(1)/ttpc3.defs.ff $(BUILD)/$(1)/ttpc3.ff $$@ > $$@.lst

$(BUILD)/$(1)/ttpc3.self: $(BUILD)/$(1)/ttpc3 $(NL)/$(SHARED)
	$(RUN_$(1)) $$< --target $(1) $(NL)/$(SHARED) $(BUILD)/$(1)/ttpc3.defs.ff $(BUILD)/$(1)/ttpc3.ff $$@ > $$@.lst

$(BUILD)/$(1)/stage1: $(BUILD)/$(1)/ttpc3 $(BUILD)/$(1)/ttpc.ff $(NL)/$(SHARED)
	$(RUN_$(1)) $$< --target $(1) $(NL)/$(SHARED) $(BUILD)/$(1)/ttpc.defs.ff $(BUILD)/$(1)/ttpc.ff $$@ > $$@.lst

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

bootstrap-$(1): $(BUILD)/$(1)/ttpc2.self $(BUILD)/$(1)/ttpc3.self $(BUILD)/$(1)/stage2 $(if $(CAN_RISCV),$(BUILD)/$(1)/cross)
	cmp $(BUILD)/$(1)/ttpc2 $(BUILD)/$(1)/ttpc2.self
	@echo "bootstrap-$(1): from its seed, ttpc2 assembles itself"
	cmp $(BUILD)/$(1)/ttpc3 $(BUILD)/$(1)/ttpc3.self
	@echo "bootstrap-$(1): from its seed, ttpc3 assembles itself"
	cmp $(BUILD)/$(1)/stage1 $(BUILD)/$(1)/stage2
	@echo "bootstrap-$(1): from its seed, stage1 == stage2"
	$(if $(CAN_RISCV),cmp $(BUILD)/$(1)/stage1 $(BUILD)/$(1)/cross,@echo "bootstrap-$(1): no $(QEMU) here, not compared with the riscv64 chain")
	$(if $(CAN_RISCV),@echo "bootstrap-$(1): == the riscv64 chain's ttpc for $(1)")

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

# seeds needs ttpc.s to compare with; bootstraps is riscv64 (make bootstrap)
# and every other host this machine runs, from its own seed.
seeds: $(if $(CAN_RISCV),$(RUNNABLE:%=seed-%))
	@echo "seeds: $(if $(CAN_RISCV),$(RUNNABLE) agree with ttpc.s,no $(QEMU) here to run ttpc.s)"
bootstraps: $(if $(CAN_RISCV),bootstrap) $(RUNNABLE:%=bootstrap-%) $(RUNNABLE:%=chello-%)
	@echo "bootstraps: $(strip $(if $(CAN_RISCV),riscv64) $(RUNNABLE))$(if $(filter-out $(RUNNABLE),$(HOSTS)),; not here (no qemu): $(filter-out $(RUNNABLE),$(HOSTS)))"

# Make shared.ff again from mkff.pl, shared.ff.txt, isa/ and macros/, after
# changing any of them. The whole trees keep the shared pages they have.
refresh:
	perl gen/mkff.pl > $(SHARED).tmp && mv $(SHARED).tmp $(SHARED)
	perl gen/mkgnuff.pl > $(X86GNU).tmp && mv $(X86GNU).tmp $(X86GNU)

# A change of ttpc is a patch script (gen/patches/*.pl, see gen/patchlib.pl),
# committed with the tree it changes, so that it can be replayed when a
# merge of the tree conflicts: T (ttpc.ff) is dumped to text, the script
# P edits the text, and the text becomes T again.
T ?= $(TTPC_FF)
patch: | $(BUILD)
	@test -n "$(P)" || { echo "usage: make patch P=gen/patches/x.pl [T=ttpc.ff]"; exit 1; }
	perl gen/fftext.pl txt $(T) > $(BUILD)/patch.ff.txt
	PATCHLIB=$(CURDIR)/gen/patchlib.pl perl $(P) $(BUILD)/patch.ff.txt
	perl gen/fftext.pl ff $(BUILD)/patch.ff.txt > $(BUILD)/patch.ff
	mv $(BUILD)/patch.ff $(T)
	@echo "patch: $(P) on $(T)"

clean:
	rm -rf $(BUILD)

.PHONY: all test roundtrip decls check rvv simd run bootstrap ctest ctime cws targets seeds bootstraps refresh patch clean licenses abi
