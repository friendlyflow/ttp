CC     = x86_64-elf-gcc
LD     = x86_64-elf-ld
NASM   = nasm
# -mgeneral-regs-only: forbid GCC from emitting SSE/MMX/x87 (e.g. `pxor xmm`).
# The CPU has SSE disabled at boot, so those instructions #UD and triple-fault.
# Remove this once the kernel enables SSE in hardware (CR0.EM=0, CR4.OSFXSR=1)
# and can thus execute the full instruction set.
CFLAGS = -ffreestanding -O0 -Wall -Wextra -nostdlib -nostdinc \
         -isystem $(shell $(CC) -print-file-name=include) \
         -fno-builtin -fno-stack-protector -mno-red-zone \
         -mgeneral-regs-only -mcmodel=large

# Default to the repo-root build tree (build/os); the root Makefile overrides
# this with an absolute path to the same place.
BUILD ?= ../../build/os

KERNEL_OBJS = $(addprefix $(BUILD)/, \
              kernel_entry.o \
              kernel.o       \
              vga.o          \
              idt.o          \
              isr.o          \
              heap.o         \
              string.o       \
              keyboard.o     \
              navigator.o    \
              encode.o       \
              hash.o         \
              ata.o          \
              gen.o          \
              tss.o          \
              syscall.o      \
              userspace.o    \
              user_program.o \
              ff_blob.o)

# Host tool: builds the node program `ttpc -a` assembles. Uses the host cc and
# the shared node format in the repo-root include/, not the cross toolchain.
HOSTCC  ?= cc
INCLUDE := ../../include

all: $(BUILD)/ttpos.img

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/gen_program: ff/gen_program.c $(INCLUDE)/node.h | $(BUILD)
	NIX_HARDENING_ENABLE= $(HOSTCC) -O0 -Wall -Wextra -DTTP_HOSTED -I$(INCLUDE) ff/gen_program.c -o $@

# The node program is committed source (the "ff"), regenerated here.
ff/program.nodes: $(BUILD)/gen_program
	$(BUILD)/gen_program $@

.PHONY: nodes
nodes: ff/program.nodes

# Regenerate boot_flow.txt — the disassembly the bootstrap compiler re-assembles
# back into the image (see DISASSEMBLY.md). Run after any kernel/stage2 change so
# the round-trip stays valid. The stage2 carve offsets below are byte ranges from
# stage2.asm's NASM listing; update them if stage2.asm's *code* size changes.
OBJDUMP ?= x86_64-elf-objdump
.PHONY: disasm
disasm: $(BUILD)/boot.bin $(BUILD)/stage2.bin $(BUILD)/kernel.bin
	@dd if=$(BUILD)/stage2.bin of=/tmp/s2_16.bin   bs=1 skip=0   count=26  status=none
	@dd if=$(BUILD)/stage2.bin of=/tmp/s2_32.bin   bs=1 skip=26  count=115 status=none
	@dd if=$(BUILD)/stage2.bin of=/tmp/s2_data.bin bs=1 skip=141 count=96  status=none
	@dd if=$(BUILD)/stage2.bin of=/tmp/s2_64.bin   bs=1 skip=237 count=22  status=none
	@{ \
	  echo "[1] boot.bin       disk 0x0    (loads @0x7C00)  16-bit"; \
	  $(OBJDUMP) -D -b binary -mi386 -Mintel,addr16,data16 --adjust-vma=0x0    $(BUILD)/boot.bin; \
	  echo "[2a] stage2.bin  disk 0x200  (loads @0x10000) 16-bit"; \
	  $(OBJDUMP) -D -b binary -mi386 -Mintel,addr16,data16 --adjust-vma=0x200  /tmp/s2_16.bin; \
	  echo "[2b] stage2.bin  disk 0x21A  (loads @0x1001A) 32-bit (pmode32)"; \
	  $(OBJDUMP) -D -b binary -mi386 -Mintel               --adjust-vma=0x21A  /tmp/s2_32.bin; \
	  echo "[2c] stage2.bin  disk 0x28D  (loads @0x1008D) DATA (GDT32 + GDT64)"; \
	  $(OBJDUMP) -D -b binary -mi386 -Mintel               --adjust-vma=0x28D  /tmp/s2_data.bin; \
	  echo "[2d] stage2.bin  disk 0x2ED  (loads @0x100ED) 64-bit (long_mode)"; \
	  $(OBJDUMP) -D -b binary -mi386:x86-64 -Mintel        --adjust-vma=0x2ED  /tmp/s2_64.bin; \
	  echo "[3] kernel.bin     disk 0x1200 (loads @0x11000) 64-bit (code + .rodata)"; \
	  $(OBJDUMP) -D -b binary -mi386:x86-64 -Mintel        --adjust-vma=0x1200 $(BUILD)/kernel.bin; \
	} > boot_flow.txt
	@echo "regenerated boot_flow.txt"

$(BUILD)/boot.bin: boot.asm | $(BUILD)
	$(NASM) -f bin $< -o $@

$(BUILD)/stage2.bin: stage2.asm | $(BUILD)
	$(NASM) -f bin $< -o $@

$(BUILD)/kernel_entry.o: kernel_entry.asm | $(BUILD)
	$(NASM) -f elf64 $< -o $@

$(BUILD)/isr.o: isr.asm | $(BUILD)
	$(NASM) -f elf64 $< -o $@

# Embeds ff/program.nodes via incbin; rebuild when the node program changes.
$(BUILD)/ff_blob.o: ff_blob.asm ff/program.nodes | $(BUILD)
	$(NASM) -f elf64 $< -o $@

# The x86-64 encoder, shared with the host ttpc. The interface lives in the
# repo-root include/ (like node.h); only the .c stays with the compiler. Built
# WITHOUT TTP_HOSTED so it uses the OS's freestanding libc subset (string.c).
$(BUILD)/encode.o: ../compiler/encode.c $(INCLUDE)/encode.h | $(BUILD)
	$(CC) $(CFLAGS) -I$(INCLUDE) -c $< -o $@

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -I$(INCLUDE) -c $< -o $@

$(BUILD)/kernel.bin: $(KERNEL_OBJS) linker.ld | $(BUILD)
	$(LD) -T linker.ld --oformat binary -o $@ $(KERNEL_OBJS)

$(BUILD)/ttpos.img: $(BUILD)/boot.bin $(BUILD)/stage2.bin $(BUILD)/kernel.bin | $(BUILD)
	dd if=/dev/zero              of=$@ bs=512 count=2048
	dd if=$(BUILD)/boot.bin      of=$@ bs=512 seek=0  conv=notrunc
	dd if=$(BUILD)/stage2.bin    of=$@ bs=512 seek=1  conv=notrunc
	dd if=$(BUILD)/kernel.bin    of=$@ bs=512 seek=9  conv=notrunc

test: $(BUILD)/ttpos.img
	qemu-system-x86_64 -drive format=raw,file=$(BUILD)/ttpos.img

clean:
	rm -rf $(BUILD)
