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

# The ff sources: ttpc itself and the programs in progs/, each a whole tree
# (the shared pages from mkff.pl, then its own; the last page is what ttpc
# assembles), edited in sicompass. progs/<name>.s is a program's GNU twin.
TTPC_FF := ttpc.ff
PROGS := exit42 hello wide
CPROGS := cexit cfib cloop chello cexpr cstruct cnow cct cunroll ctasm ctmix
TREES := $(TTPC_FF) $(PROGS:%=progs/%.ff) $(CPROGS:%=progs/%.ff) progs/cnowfail.ff progs/creserved.ff
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

# The bootstrap. ttpc.s, assembled by GNU as, is stage0. ttpc.ff is
# assembled by stage0 into stage1 and by stage1 into stage2, which must be
# the same: the fixed point. stage1 must also assemble every program and
# print ttpc.ff exactly as stage0 does.
BOOT := $(BUILD)/boot

$(BOOT):
	mkdir -p $@

$(BOOT)/stage1: $(TTPC_FF) $(BIN) | $(BOOT)
	$(QEMU) $(BIN) $< $@ > $@.lst

$(BOOT)/stage2: $(TTPC_FF) $(BOOT)/stage1
	$(QEMU) $(BOOT)/stage1 $< $@ > $@.lst

bootstrap: $(BOOT)/stage2 $(PROGS:%=$(P)/%.elf)
	cmp $(BOOT)/stage1 $(BOOT)/stage2
	@echo "bootstrap: stage1 == stage2"
	@for p in $(PROGS); do \
	    $(QEMU) $(BOOT)/stage1 progs/$$p.ff $(BOOT)/$$p.elf > $(BOOT)/$$p.lst && \
	    cmp $(BOOT)/$$p.elf $(P)/$$p.elf && cmp $(BOOT)/$$p.lst $(P)/$$p.lst || exit 1; \
	done
	$(QEMU) $(BIN) $(TTPC_FF) > $(BOOT)/tree0.txt
	$(QEMU) $(BOOT)/stage1 $(TTPC_FF) | cmp - $(BOOT)/tree0.txt
	@echo "bootstrap: stage1 assembles and prints like stage0"

# The C programs (progs/c*.ff) use the C layer, which ttpc.s predates:
# stage2, ttpc as ttpc.ff makes it, assembles them. Each must exit with the
# status on the first line of progs/<name>.expect ("exit N") and print the
# rest of it.
$(P)/%.celf: progs/%.ff $(BOOT)/stage2 | $(P)
	$(QEMU) $(BOOT)/stage2 $< $@ > $(P)/$*.lst

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
# condition takes, cnowfail fails to compile with its message, and so does
# creserved, which names a variable content.
ctime: $(P)/cnow.celf $(P)/cct.celf $(P)/ctasm.celf $(P)/ctmix.celf
	grep -qx compiling $(P)/cnow.lst
	grep -qx "asm at compile time" $(P)/ctasm.lst
	grep -qx "asm and C at compile time" $(P)/ctmix.lst
	! grep -aq compiling $(P)/cnow.celf
	! grep -aq other $(P)/cct.celf
	! $(QEMU) $(BOOT)/stage2 progs/cnowfail.ff $(P)/cnowfail.celf 2> $(P)/cnowfail.err
	grep -q "compile time: no" $(P)/cnowfail.err
	! $(QEMU) $(BOOT)/stage2 progs/creserved.ff $(P)/creserved.celf 2> $(P)/creserved.err
	grep -q "a reserved word: content" $(P)/creserved.err
	@echo "ctime: compile time runs and stays out of the program"

# Put the current shared pages (the ISA from mkff.pl, macros.ff.txt) into
# every tree, after changing either of them.
refresh:
	perl mkff.pl --refresh $(TREES)

clean:
	rm -rf $(BUILD)

.PHONY: all test roundtrip check run bootstrap ctest ctime refresh clean
