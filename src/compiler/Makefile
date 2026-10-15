# ttpc is plain RISC-V assembly, no libc: assembled and linked with the
# bare-metal cross binutils into a static Linux riscv64 executable that only
# makes raw syscalls. On a non-RISC-V host it runs under qemu-riscv64.
CROSS   ?= riscv64-none-elf-
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
ASFLAGS ?= -march=rv64imac -mabi=lp64
QEMU    ?= qemu-riscv64

# The Nix ld-wrapper injects -z relro / -z now hardening, which this static
# no-libc binary has no use for (ld warns). A non-Nix ld ignores this.
export NIX_HARDENING_ENABLE :=

BUILD ?= build

BIN := $(BUILD)/ttpc
OBJ := $(BUILD)/ttpc.o

# ff file that `make test` loads and `make asm` assembles into OUT.
FF ?= test.ff
OUT := $(BUILD)/out

all: $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

$(OBJ): ttpc.s | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $@

$(BIN): $(OBJ)
	$(LD) -static -e _start $< -o $@

test: $(BIN)
	$(QEMU) $(BIN) $(FF)

# Assemble the program in FF into the executable OUT.
asm: $(BIN)
	$(QEMU) $(BIN) $(FF) $(OUT)

# Run OUT: the program in test.ff exits with 42.
run: asm
	$(QEMU) $(OUT); s=$$?; echo "exit status $$s"; test $$s -eq 42

# The code in OUT (after its 120-byte ELF header) must be byte-identical to
# GNU as assembling the same program, check.s.
$(BUILD)/check.bin: check.s | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $(BUILD)/check.o
	$(OBJCOPY) -O binary -j .text $(BUILD)/check.o $@

check: asm $(BUILD)/check.bin
	tail -c +121 $(OUT) | cmp - $(BUILD)/check.bin
	@echo "check: ttpc and GNU as agree"

# Regenerate the RV64GC node tree in test.ff (host Perl, see mkff.pl).
ff:
	perl mkff.pl > test.ff.tmp && mv test.ff.tmp test.ff

clean:
	rm -rf $(BUILD)

.PHONY: all test asm run check ff clean
