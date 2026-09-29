CC      = riscv64-none-elf-gcc
OBJDUMP = riscv64-none-elf-objdump
OBJCOPY = riscv64-none-elf-objcopy
QEMU    = qemu-system-riscv64
# rv64imac: what QEMU's `virt` rv64 core offers without floating point, so GCC
# never emits FP instructions (no FPU state is set up). zicsr: csrr/csrw.
# medany: code/data may live anywhere (we're at 0x80000000, beyond medlow).
CFLAGS  = -march=rv64imac_zicsr -mabi=lp64 -mcmodel=medany \
          -ffreestanding -nostdlib -O0 -Wall -Wextra \
          -fno-builtin -fno-stack-protector

# The Nix cc-wrapper injects hardening flags (-z relro/-z now) that make no
# sense for a bare-metal kernel; a non-Nix toolchain ignores this env var.
export NIX_HARDENING_ENABLE :=

# One flat RWX image is intended here: no MMU/PMP protection is set up yet.
LDFLAGS = -T linker.ld -Wl,--no-warn-rwx-segments

# Default to the repo-root build tree (build/os); the root Makefile overrides
# this with an absolute path to the same place.
BUILD ?= ../../build/os

OBJS = $(addprefix $(BUILD)/, \
       entry.o  \
       trap.o   \
       kernel.o \
       uart.o)

ELF = $(BUILD)/os.elf

# -bios none: no OpenSBI, QEMU jumps straight to 0x80000000 in M-mode.
QEMUFLAGS = -machine virt -bios none

all: $(ELF)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/%.o: %.S | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(ELF): $(OBJS) linker.ld | $(BUILD)
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@

# `virt` has no display device, so the QEMU window shows text consoles. Its
# first tab would be the QEMU monitor; -monitor none leaves the UART (serial0)
# as the only one, so the OS's output is what the window shows.
# Quit with Ctrl-D (OS poweroff) or by closing the window.
test: $(ELF)
	$(QEMU) $(QEMUFLAGS) -monitor none -kernel $(ELF)

# Same, but the UART is this terminal instead of a window (also for scripted
# runs). Quit with Ctrl-D or Ctrl-A X.
console: $(ELF)
	$(QEMU) $(QEMUFLAGS) -nographic -kernel $(ELF)

# Flat image: exactly the bytes QEMU places at 0x80000000 (no ELF headers, no
# .bss). ttpc's re-assembly of boot_flow.txt must reproduce it byte for byte.
$(BUILD)/os.bin: $(ELF)
	$(OBJCOPY) -O binary $< $@

bin: $(BUILD)/os.bin

# Regenerate boot_flow.txt — the disassembly the bootstrap compiler re-assembles
# back into the image (see DISASSEMBLY.md). Run after any change to the OS so
# the round-trip stays valid.
disasm: $(ELF)
	{ \
	  echo "[1] os.elf  file 0x0  (loads @0x80000000)  rv64 (.text + .rodata)"; \
	  $(OBJDUMP) -D -j .text -j .rodata $(ELF) | awk -f boot_flow.awk; \
	} > boot_flow.txt
	@echo "regenerated boot_flow.txt"

clean:
	rm -rf $(BUILD)

.PHONY: all bin test console disasm clean
