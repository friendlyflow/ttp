CC     = x86_64-elf-gcc
LD     = x86_64-elf-ld
NASM   = nasm
CFLAGS = -ffreestanding -O2 -Wall -Wextra -nostdlib -nostdinc \
         -isystem $(shell $(CC) -print-file-name=include) \
         -fno-builtin -fno-stack-protector -mno-red-zone \
         -mcmodel=large

# Default to the repo-root build tree (build/os); the root Makefile overrides
# this with an absolute path to the same place.
BUILD ?= ../../build/os

KERNEL_OBJS = $(addprefix $(BUILD)/, \
              kernel_entry.o \
              kernel_main.o  \
              vga.o          \
              tss.o          \
              syscall.o      \
              userspace.o    \
              user_program.o)

# Host tool: builds the node program `ttpc -a` assembles. Uses the host cc and
# the shared node format in the repo-root include/, not the cross toolchain.
HOSTCC  ?= cc
INCLUDE := ../../include

all: $(BUILD)/ttpos.img

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/gen_program: ff/gen_program.c $(INCLUDE)/node.h | $(BUILD)
	$(HOSTCC) -O2 -Wall -Wextra -I$(INCLUDE) ff/gen_program.c -o $@

# The node program is committed source (the "ff"), regenerated here.
ff/program.nodes: $(BUILD)/gen_program
	$(BUILD)/gen_program $@

.PHONY: nodes
nodes: ff/program.nodes

$(BUILD)/boot.bin: boot.asm | $(BUILD)
	$(NASM) -f bin $< -o $@

$(BUILD)/kernel32.bin: kernel32.asm | $(BUILD)
	$(NASM) -f bin $< -o $@

$(BUILD)/kernel_entry.o: kernel_entry.asm | $(BUILD)
	$(NASM) -f elf64 $< -o $@

$(BUILD)/%.o: %.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD)/kernel.bin: $(KERNEL_OBJS) linker.ld | $(BUILD)
	$(LD) -T linker.ld --oformat binary -o $@ $(KERNEL_OBJS)

$(BUILD)/ttpos.img: $(BUILD)/boot.bin $(BUILD)/kernel32.bin $(BUILD)/kernel.bin | $(BUILD)
	dd if=/dev/zero              of=$@ bs=512 count=2048
	dd if=$(BUILD)/boot.bin      of=$@ bs=512 seek=0  conv=notrunc
	dd if=$(BUILD)/kernel32.bin  of=$@ bs=512 seek=1  conv=notrunc
	dd if=$(BUILD)/kernel.bin    of=$@ bs=512 seek=9  conv=notrunc

test: $(BUILD)/ttpos.img
	qemu-system-x86_64 -drive format=raw,file=$(BUILD)/ttpos.img

clean:
	rm -rf $(BUILD)
