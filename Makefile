# Root Makefile — calls the compiler and os sub-Makefiles, collecting their
# artifacts under ./build.
#
#   make            build everything (compiler + os)
#   make os         build the bare-metal RISC-V OS     -> build/os/os.elf
#   make compiler   build the RISC-V asm compiler      -> build/compiler/ttpc
#   make os-test    boot the OS in a qemu-system-riscv64 window
#   make os-console boot the OS with its serial console in this terminal
#   make compiler-test  print the tree of src/compiler/ttpc.ff with ttpc
#   make compiler-check assemble the programs in src/compiler/progs, compare
#                       them with GNU as and run them, for riscv64, x86_64,
#                       aarch64 and arm
#   make bootstrap  ttpc assembles itself from ff: ttpc1 == ttpc1(ttpc1.ff),
#                   stage1 == stage2; and so on x86_64, aarch64 and arm from
#                   their own seeds (hosts/<host>/ttpc.s), without riscv64
#   make clean      remove ./build

BUILD := $(CURDIR)/build

.PHONY: all os compiler os-test os-console compiler-test compiler-check bootstrap clean

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

# Assemble the programs, check them against GNU as and run them; build and
# run the C programs; the seeds of the other hosts agree with ttpc.s.
compiler-check: compiler
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler check rvv run ctest ctime cws targets seeds

# ttpc.s (stage0) assembles ttpc in ff into stage1, stage1 assembles it into
# stage2: they must be the same. So too from the seed of each other host
# (natively on this one, under qemu-<host> on the others), whose stage1 must
# be what the riscv64 chain makes for it; then its C programs run.
bootstrap:
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler bootstraps

clean:
	$(MAKE) -C src/os BUILD=$(BUILD)/os clean
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler clean
	rm -rf $(BUILD)
