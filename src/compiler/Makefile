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

# ff file that `make test` prints.
FF ?= test.ff

# The programs in progs/. A program's tree is the ISA, macros.ff.txt, its
# constants (progs/<name>.consts.ff.txt, when there is one) and itself, the
# last page; progs/<name>.s is its GNU twin.
PROGS := exit42 hello wide
P := $(BUILD)/progs

all: $(BIN)

$(BUILD) $(P):
	mkdir -p $@

$(OBJ): ttpc.s | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $@

$(BIN): $(OBJ)
	$(LD) -static --no-relax -e _start $< -o $@

test: $(BIN)
	$(QEMU) $(BIN) $(FF)

$(P)/%.ff: progs/%.ff.txt macros.ff.txt $(wildcard progs/*.consts.ff.txt) mkff.pl FF.pm | $(P)
	perl mkff.pl macros.ff.txt $(wildcard progs/$*.consts.ff.txt) $< > $@

# ttpc assembles a program, its listing goes to <name>.lst.
$(P)/%.elf: $(P)/%.ff $(BIN)
	$(QEMU) $(BIN) $< $@ > $(P)/$*.lst

$(P)/%.twin.bin: progs/%.s ff.ld | $(P)
	$(AS) $(TWIN_ASFLAGS) $< -o $(P)/$*.twin.o
	$(LD) $(TWIN_LDFLAGS) $(P)/$*.twin.o -o $(P)/$*.twin
	$(OBJCOPY) -O binary $(P)/$*.twin $@

.SECONDARY:

# The text form of test.ff must read back to the same bytes.
roundtrip: | $(BUILD)
	perl fftext.pl txt $(FF) > $(BUILD)/roundtrip.ff.txt
	perl fftext.pl ff $(BUILD)/roundtrip.ff.txt | cmp - $(FF)

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

# Regenerate test.ff: the RV64GC node tree, the macros and the exit-42
# program (host Perl, see mkff.pl and FF.pm).
ff:
	perl mkff.pl macros.ff.txt progs/exit42.ff.txt > test.ff.tmp && mv test.ff.tmp test.ff

clean:
	rm -rf $(BUILD)

.PHONY: all test roundtrip check run ff clean
