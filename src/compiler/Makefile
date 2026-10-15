# ttpc is plain RISC-V assembly, no libc: assembled and linked with the
# bare-metal cross binutils into a static Linux riscv64 executable that only
# makes raw syscalls. On a non-RISC-V host it runs under qemu-riscv64.
CROSS   ?= riscv64-none-elf-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS ?= -march=rv64imac -mabi=lp64
QEMU    ?= qemu-riscv64

# The GNU twins of the ff programs (progs/*.s): every extension ff encodes,
# no relaxation, linked with ff.ld into ttpc's layout.
TWIN_ASFLAGS := -march=rv64imafdc -mabi=lp64 -mno-relax
TWIN_LDFLAGS := --no-relax --no-warn-rwx-segments -T ff.ld

# The Nix ld-wrapper injects -z relro / -z now hardening, which this static
# no-libc binary has no use for (ld warns). A non-Nix ld ignores this.
export NIX_HARDENING_ENABLE :=

BUILD ?= build

BIN := $(BUILD)/ttpc
OBJ := $(BUILD)/ttpc.o

# The ff sources, edited in sicompass. ttpc is a program of only its own,
# ttpc.ff, with its constants in ttpc.defs.ff, on the shared page
# (shared.ff, from mkff.pl): ttpc --target riscv64 shared.ff ttpc.defs.ff
# ttpc.ff out. A C program is its program alone too: ttpc shared.ff prog.ff
# out. ttpc1.ff (the frozen ttpc of the chain) and the asm programs in
# progs/ are whole trees (the shared pages of then, their own; the last
# page is what ttpc assembles); progs/<name>.s is the GNU twin of one.
TTPC_FF := ttpc.ff
TTPC_SRC := shared.ff ttpc.defs.ff ttpc.ff
TTPC1_FF := ttpc1.ff
PROGS := exit42 hello wide
CPROGS := cexit cfib cloop chello cexpr cstruct cnow cct cunroll ctasm ctmix celse casm
SHARED := shared.ff
WHOLE := $(TTPC1_FF) $(PROGS:%=progs/%.ff)
TREES := $(WHOLE) $(SHARED) ttpc.defs.ff $(TTPC_FF) $(wildcard progs/*/*.ff) $(CPROGS:%=progs/%.ff) progs/cnowfail.ff progs/creserved.ff progs/cmisplaced.ff
P := $(BUILD)/progs

all: $(BIN)

$(BUILD) $(P):
	mkdir -p $@

$(OBJ): ttpc.s | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $@

$(BIN): $(OBJ)
	$(LD) -static --no-relax -e _start $< -o $@

# Print the tree of ttpc.ff, or of FF=<file>.
FF ?= $(TTPC_FF)
test: $(BIN)
	$(QEMU) $(BIN) $(FF)

# ttpc assembles a program, its listing goes to <name>.lst.
$(P)/%.elf: progs/%.ff $(BIN) | $(P)
	$(QEMU) $(BIN) $< $@ > $(P)/$*.lst

$(P)/%.twin.bin: progs/%.s ff.ld | $(P)
	$(AS) $(TWIN_ASFLAGS) $< -o $(P)/$*.twin.o
	$(LD) $(TWIN_LDFLAGS) $(P)/$*.twin.o -o $(P)/$*.twin
	$(OBJCOPY) -O binary $(P)/$*.twin $@

.SECONDARY:

# Every tree must read back to the same bytes from its text form (which
# also checks its hashes).
roundtrip: | $(BUILD)
	@for t in $(TREES); do \
	    perl fftext.pl txt $$t > $(BUILD)/roundtrip.ff.txt && \
	    perl fftext.pl ff $(BUILD)/roundtrip.ff.txt | cmp - $$t || exit 1; \
	done
	@echo "roundtrip: $(TREES)"

# Every program, after its 120-byte ELF header, must be byte-identical to
# its GNU twin.
check: roundtrip $(PROGS:%=$(P)/%.elf) $(PROGS:%=$(P)/%.twin.bin)
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

# The bootstrap, a chain of versions. ttpc.s, assembled by GNU as, is
# stage0. ttpc1.ff, frozen like ttpc.s, is ttpc in the language of stage0,
# a whole tree below its 1 MiB: stage0 assembles it into ttpc1, which must
# assemble itself into itself, assemble every asm program and print
# ttpc1.ff exactly as stage0 does. ttpc1 assembles ttpc (TTPC_SRC) into
# stage1, stage1 assembles it into stage2: they must be the same, the fixed
# point.
BOOT := $(BUILD)/boot

$(BOOT):
	mkdir -p $@

$(BOOT)/ttpc1: $(TTPC1_FF) $(BIN) | $(BOOT)
	$(QEMU) $(BIN) $< $@ > $@.lst

$(BOOT)/ttpc1.self: $(TTPC1_FF) $(BOOT)/ttpc1
	$(QEMU) $(BOOT)/ttpc1 $< $@ > $@.lst

$(BOOT)/stage1: $(TTPC_SRC) $(BOOT)/ttpc1
	$(QEMU) $(BOOT)/ttpc1 --target riscv64 $(TTPC_SRC) $@ > $@.lst

$(BOOT)/stage2: $(TTPC_SRC) $(BOOT)/stage1
	$(QEMU) $(BOOT)/stage1 --target riscv64 $(TTPC_SRC) $@ > $@.lst

bootstrap: $(BOOT)/ttpc1.self $(BOOT)/stage2 $(PROGS:%=$(P)/%.elf)
	cmp $(BOOT)/ttpc1 $(BOOT)/ttpc1.self
	@echo "bootstrap: ttpc1 assembles itself"
	cmp $(BOOT)/stage1 $(BOOT)/stage2
	@echo "bootstrap: stage1 == stage2"
	@for p in $(PROGS); do \
	    $(QEMU) $(BOOT)/ttpc1 progs/$$p.ff $(BOOT)/$$p.elf > $(BOOT)/$$p.lst && \
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
# compile with its message, and so do creserved, which names a variable
# content, and cmisplaced, with compile time on a while.
ctime: $(P)/cnow.celf $(P)/cct.celf $(P)/ctasm.celf $(P)/ctmix.celf
	grep -qx compiling $(P)/cnow.lst
	grep -qx "asm at compile time" $(P)/ctasm.lst
	grep -qx "asm and C at compile time" $(P)/ctmix.lst
	! grep -aq compiling $(P)/cnow.celf
	! grep -aq other $(P)/cct.celf
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cnowfail.ff $(P)/cnowfail.celf 2> $(P)/cnowfail.err
	grep -q "compile time: no" $(P)/cnowfail.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/creserved.ff $(P)/creserved.celf 2> $(P)/creserved.err
	grep -q "a reserved word: content" $(P)/creserved.err
	! $(QEMU) $(BOOT)/stage2 $(SHARED) progs/cmisplaced.ff $(P)/cmisplaced.celf 2> $(P)/cmisplaced.err
	grep -q "compile time goes only first in a function or a lambda: while" $(P)/cmisplaced.err
	@echo "ctime: compile time runs and stays out of the program"

# The other targets ttpc builds for (--target). Per target: its asm
# programs (progs/<target>/*.ff, program-only trees) must be byte-identical
# to their GNU twins (progs/<target>/*.s) after the ELF header, exit42 and
# hello must run, and every C program that is not riscv64 asm must do what
# its .expect says (progs/<name>.<target>.expect where the target differs),
# compile time still running on riscv64.
TARGETS := x86_64 aarch64 arm
CPORTABLE := cexit cfib cloop chello cexpr cstruct cnow cct cunroll celse casm
# cexpr computes with u64, which a target of 4-byte words does not have.
CSKIP_arm := cexpr

CROSS_x86_64 := x86_64-elf-
TASFLAGS_x86_64 := -mindex-reg
TLDS_x86_64 := ff.ld
THDR_x86_64 := 120

CROSS_aarch64 := aarch64-none-elf-
TASFLAGS_aarch64 := -march=armv8.1-a
TLDS_aarch64 := ff.ld
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

ctest-$(1): $(patsubst %,$(P)/$(1)/%.celf,$(filter-out $(CSKIP_$(1)),$(CPORTABLE)))
	@for p in $(filter-out $(CSKIP_$(1)),$(CPORTABLE)); do \
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

targets: $(TARGETS:%=check-%) $(TARGETS:%=ctest-%)
	! $(QEMU) $(BOOT)/stage2 --target mips $(SHARED) progs/cexit.ff $(P)/mips.celf 2> $(P)/mips.err
	grep -q "compile time: mips is not a target" $(P)/mips.err
	@echo "targets: $(TARGETS) and riscv64"

# Make shared.ff again from mkff.pl, shared.ff.txt, isa/ and macros/, after
# changing any of them. The whole trees keep the shared pages they have.
refresh:
	perl mkff.pl > $(SHARED).tmp && mv $(SHARED).tmp $(SHARED)

clean:
	rm -rf $(BUILD)

.PHONY: all test roundtrip check run bootstrap ctest ctime targets refresh clean
