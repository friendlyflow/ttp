# Root Makefile — calls the compiler and os sub-Makefiles, collecting their
# artifacts under ./build.
#
#   make            build everything (compiler + os)
#   make os         build the bare-metal x86_64 OS image -> build/os/ttpos.img
#   make compiler   build the host compiler            -> build/compiler/ttpc
#   make os-test    boot the OS image in qemu
#   make compiler-test  re-assemble boot_flow.txt with ttpc and boot it in qemu
#   make clean      remove ./build

BUILD := $(CURDIR)/build

.PHONY: all os compiler os-test compiler-test clean

all: os compiler

# Each sub-Makefile takes a BUILD override so its artifacts land in the root
# build folder instead of its own src/<x>/build.
os:
	$(MAKE) -C src/os BUILD=$(BUILD)/os

compiler:
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler

os-test:
	$(MAKE) -C src/os BUILD=$(BUILD)/os test

# Re-assemble the OS boot-flow disassembly with ttpc and boot the result.
compiler-test: compiler
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler test

clean:
	$(MAKE) -C src/os BUILD=$(BUILD)/os clean
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler clean
	rm -rf $(BUILD)
