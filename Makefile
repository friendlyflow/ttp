# Root Makefile — calls the compiler and os sub-Makefiles, collecting their
# artifacts under ./build.
#
#   make            build everything (compiler + os)
#   make os         build the bare-metal RISC-V OS     -> build/os/os.elf
#   make compiler   build the RISC-V asm compiler      -> build/compiler/ttpc
#   make os-test    boot the OS in a qemu-system-riscv64 window
#   make os-console boot the OS with its serial console in this terminal
#   make compiler-test  load src/compiler/test.ff with ttpc under qemu-riscv64
#   make compiler-check assemble test.ff with ttpc, compare with GNU as, run it
#   make clean      remove ./build

BUILD := $(CURDIR)/build

.PHONY: all os compiler os-test os-console compiler-test compiler-check clean

all: os compiler

# Each sub-Makefile takes a BUILD override so its artifacts land in the root
# build folder instead of its own src/<x>/build.
os:
	$(MAKE) -C src/os BUILD=$(BUILD)/os

compiler:
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler

os-test:
	$(MAKE) -C src/os BUILD=$(BUILD)/os test

os-console:
	$(MAKE) -C src/os BUILD=$(BUILD)/os console

# Run ttpc (a Linux riscv64 binary) under qemu-riscv64 on an ff file.
compiler-test: compiler
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler test

# Assemble the program in test.ff, check it against GNU as and run it.
compiler-check: compiler
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler check run

clean:
	$(MAKE) -C src/os BUILD=$(BUILD)/os clean
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler clean
	rm -rf $(BUILD)
