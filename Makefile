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
#                       aarch64 and arm; every tree has its
#                       license (license / SPDX / notice, make licenses)
#   make bootstrap  ttpc assembles itself from ff: ttpc1 == ttpc1(ttpc1.ff),
#                   stage1 == stage2; and so on x86_64, aarch64 and arm from
#                   their own seeds (hosts/<host>/ttpc.s), without riscv64
#   make gcroots    keep glibc's source and toolchains (GLIBC_SRC, GLIBC_CC*,
#                   GLIBC_HEADERS*, C2FF_CLANG) alive in nix gc, as
#                   ~/.cache/ttp/gcroots/<name>
#   make git-setup  register the ff diff and merge drivers (.gitattributes)
#                   in this repository's git config
#   make lane NAME=x  a worktree for a lane of work, ~/.cache/ttp/wt/x on a
#                   new branch ff/x from the current one, set up as above
#   make patch P=gen/patches/x.pl [T=ttpc.ff]  run a patch script on a
#                   tree of src/compiler (see src/compiler/gen/patchlib.pl)
#   make clean      remove ./build

BUILD := $(CURDIR)/build

.PHONY: all os compiler os-test os-console compiler-test compiler-check bootstrap gcroots git-setup lane patch clean

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
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler check licenses rvv run ctest ctime cws targets seeds

# ttpc.s (stage0) assembles ttpc in ff into stage1, stage1 assembles it into
# stage2: they must be the same. So too from the seed of each other host
# (natively on this one, under qemu-<host> on the others), whose stage1 must
# be what the riscv64 chain makes for it; then its C programs run.
bootstrap:
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler bootstraps

# The store paths of glibc's source and the toolchains src/glibc builds and
# reads it with,
# as `nix develop` sets them: glibc's build.log names its compiler and the
# kernel's headers by store path, and mki.pl runs those commands again, so
# a nix gc must not take them while the reference build is there. Each is
# a gc root, ~/.cache/ttp/gcroots/<name>, which `make gcroots` points at
# what the flake names now.
GCROOTS := $(HOME)/.cache/ttp/gcroots
GCROOT_VARS := GLIBC_SRC GLIBC_CC GLIBC_CC_aarch64 GLIBC_CC_x86_64 GLIBC_HEADERS GLIBC_HEADERS_aarch64 GLIBC_HEADERS_x86_64 GLIBC_CC_arm GLIBC_HEADERS_arm C2FF_CLANG
gcroots:
	@mkdir -p $(GCROOTS)
	@for v in $(GCROOT_VARS); do \
	    p=$$(printenv $$v) || { echo "gcroots: $$v is not set: run this in \`nix develop\`"; exit 1; }; \
	    s=$$(echo "$$p" | cut -d/ -f1-4); \
	    nix build --out-link $(GCROOTS)/$$v "$$s" || exit 1; \
	    echo "gcroots: $(GCROOTS)/$$v -> $$s"; \
	done

# ff trees are binary; git diffs them as text (fftext.pl, as textconv) and
# merges them as text (ffmerge.sh), the drivers .gitattributes names. The
# commands run from the top of the worktree, each worktree its own copy.
git-setup:
	git config diff.ff.textconv "perl src/compiler/gen/fftext.pl txt"
	git config merge.ff.name "ff trees, merged as their text (src/compiler/gen/ffmerge.sh)"
	git config merge.ff.driver "sh src/compiler/gen/ffmerge.sh %O %A %B %P"

# A lane: a worktree of its own outside Dropbox (which renames files whose
# names differ only in case, and would sync every build), on a new branch
# from the current one.
LANES := $(HOME)/.cache/ttp/wt
lane:
	@test -n "$(NAME)" || { echo "usage: make lane NAME=x"; exit 1; }
	git worktree add $(LANES)/$(NAME) -b ff/$(NAME)
	$(MAKE) -C $(LANES)/$(NAME) git-setup
	@echo "lane: $(LANES)/$(NAME) on ff/$(NAME)"

# A patch script on a tree of src/compiler (P and T relative to it).
patch:
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler patch P=$(P) $(if $(T),T=$(T))

clean:
	$(MAKE) -C src/os BUILD=$(BUILD)/os clean
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler clean
	rm -rf $(BUILD)
