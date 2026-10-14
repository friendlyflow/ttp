# ttpc is plain RISC-V assembly, no libc: assembled and linked with the
# bare-metal cross binutils into a static Linux riscv64 executable that only
# makes raw syscalls. On a non-RISC-V host it runs under qemu-riscv64.
CROSS   ?= riscv64-none-elf-
AS      := $(CROSS)as
LD      := $(CROSS)ld
ASFLAGS ?= -march=rv64imac -mabi=lp64
QEMU    ?= qemu-riscv64

# The Nix ld-wrapper injects -z relro / -z now hardening, which this static
# no-libc binary has no use for (ld warns). A non-Nix ld ignores this.
export NIX_HARDENING_ENABLE :=

BUILD ?= build

BIN := $(BUILD)/ttpc
OBJ := $(BUILD)/ttpc.o

# ff file that `make test` loads.
FF ?= test.ff

all: $(BIN)

$(BUILD):
	mkdir -p $(BUILD)

$(OBJ): ttpc.s | $(BUILD)
	$(AS) $(ASFLAGS) $< -o $@

$(BIN): $(OBJ)
	$(LD) -static -e _start $< -o $@

test: $(BIN)
	$(QEMU) $(BIN) $(FF)

# Regenerate the RV64GC node tree in test.ff (host Perl, see mkff.pl).
ff:
	perl mkff.pl > test.ff.tmp && mv test.ff.tmp test.ff

clean:
	rm -rf $(BUILD)

.PHONY: all test ff clean
