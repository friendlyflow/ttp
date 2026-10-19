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
#   make ports-check  every check of the ports branch, the independent ones
#                   at once: PASS or FAIL and the time of each
#   make clean      remove ./build

BUILD := $(CURDIR)/build

.PHONY: all os compiler os-test os-console compiler-test compiler-check bootstrap gcroots git-setup lane patch ports-check clean

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
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler check licenses rvv run ctest ctime cws targets seeds abi

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

# Every check of the ports branch, as one command for the master and the
# lanes: bootstrap first (nothing runs without its ttpc); then at once
# compiler-check, riscv64's glibc (units-ready, then each milestone's check
# followed by its round trip, and the generic program's), and aarch64's and
# x86_64's (ldouble's check, then the generic program's). Each step prints
# PASS or FAIL and its time as it ends, its output in CHECKLOG/<step>.log,
# and at the end all of them in order; make fails if one did. Each heavy
# command takes a slot of its own (src/compiler/gen/slot.sh), so
# PCJOBS steps (6) wait for at most the machine's three slots.
#   GBUILD   riscv64's glibc BUILD (the others' are GBUILD/<target>): by
#            default the worktree's own, ~/.cache/ttp/build/<worktree>/glibc,
#            never the shared ~/.cache/ttp/glibc-gcc16 another check may be
#            reading. Made where it is not there yet: obj/ a link to the
#            shared reference build's (read only), riscv64's i/ a copy of the
#            shared one's (make then makes again what is older than its
#            sources).
#   PC_STEPS some of the steps only (with what they need first), e.g.
#            make ports-check PC_STEPS="compiler-check floats-roundtrip"
CHECKLOG ?= $(HOME)/.cache/ttp/check/$(notdir $(CURDIR))
PCJOBS ?= 6
GBUILD ?= $(HOME)/.cache/ttp/build/$(notdir $(CURDIR))/glibc
GLIBC_REF := $(HOME)/.cache/ttp/glibc-gcc16
PC_SLOT := sh src/compiler/gen/slot.sh -v 8000000 -t 3600
PC_MS := $(shell sed -n 's/^MILESTONES := //p' src/glibc/Makefile)
PC_GLIBC = $(MAKE) --no-print-directory -C src/glibc BUILD=$(GBUILD)$(if $(1),/$(1)) $(if $(1),GTARGET=$(1))
PC_STEPS := bootstrap compiler-check units-riscv64 $(foreach m,$(PC_MS),$(m)-check $(m)-roundtrip) generic-riscv64 \
	ldouble-aarch64 generic-aarch64 ldouble-x86_64 generic-x86_64
# $(call pc_step,name,command): the step, PASS or FAIL in CHECKLOG/name.result,
# with its time and how much of it its commands waited for a slot
pc_step = @s=$$(date +%s); if TTP_SLOTLOG=$(CHECKLOG)/$(1).slots $(2) > $(CHECKLOG)/$(1).log 2>&1; then r=PASS; else r=FAIL; fi; \
	w=$$(awk '{ w += $$1 } END { print w + 0 }' $(CHECKLOG)/$(1).slots 2> /dev/null || echo 0); \
	echo "$$r $(1) $$(( $$(date +%s) - s )) s ($$w s in slot queues)$$(test $$r = PASS || echo " log $(CHECKLOG)/$(1).log")" | tee $(CHECKLOG)/$(1).result

ports-check:
	@rm -rf $(CHECKLOG) && mkdir -p $(CHECKLOG)
	@s=$$(date +%s); $(MAKE) --no-print-directory -j$(PCJOBS) $(PC_STEPS:%=pc-%); \
	echo "ports-check: $$(( $$(date +%s) - s )) s, logs in $(CHECKLOG)"; \
	ok=1; for t in $(PC_STEPS); do cat $(CHECKLOG)/$$t.result 2> /dev/null || echo "SKIP $$t"; grep -qs '^PASS' $(CHECKLOG)/$$t.result || ok=; done; \
	test -n "$$ok"

pc-bootstrap:
	$(call pc_step,bootstrap,$(PC_SLOT) $(MAKE) -j1 bootstrap)
	@grep -q '^PASS' $(CHECKLOG)/bootstrap.result
pc-compiler-check: pc-bootstrap
	$(call pc_step,compiler-check,$(PC_SLOT) $(MAKE) -j1 compiler-check)
# the BUILDs, where they are not there yet
pc-gbuild:
	@test "$(abspath $(GBUILD))" != "$(abspath $(GLIBC_REF))" || { echo "ports-check: GBUILD is the shared $(GLIBC_REF): give it a folder of its own"; exit 1; }
	@for t in riscv64 aarch64 x86_64; do \
	    d=$(GBUILD)$$(test $$t = riscv64 || echo /$$t); s=$(GLIBC_REF)$$(test $$t = riscv64 || echo /$$t); \
	    test -e $$d/obj && continue; \
	    mkdir -p $$d && ln -sfn $$(readlink -f $$s/obj) $$d/obj || exit 1; \
	    if test $$t = riscv64 && test -d $$s/i && ! test -e $$d/i; then cp -a $$s/i $$d/i || exit 1; fi; \
	    echo "ports-check: $$d, obj from $$s"; \
	done
pc-units-riscv64: pc-bootstrap pc-gbuild
	$(call pc_step,units-riscv64,$(call PC_GLIBC) units-ready)
define pc_milestone
pc-$(1)-check: pc-units-riscv64
	$$(call pc_step,$(1)-check,$$(call PC_GLIBC) $(1)-check)
pc-$(1)-roundtrip: pc-$(1)-check
	$$(call pc_step,$(1)-roundtrip,$$(call PC_GLIBC) $(1)-roundtrip)
endef
$(foreach m,$(PC_MS),$(eval $(call pc_milestone,$(m))))
pc-generic-riscv64: pc-units-riscv64
	$(call pc_step,generic-riscv64,$(call PC_GLIBC) generic-check generic-roundtrip)
define pc_target
pc-ldouble-$(1): pc-bootstrap pc-gbuild
	$$(call pc_step,ldouble-$(1),$$(call PC_GLIBC,$(1)) ldouble-check)
pc-generic-$(1): pc-ldouble-$(1)
	$$(call pc_step,generic-$(1),$$(call PC_GLIBC,$(1)) generic-check generic-roundtrip)
endef
$(foreach t,aarch64 x86_64,$(eval $(call pc_target,$(t))))
.PHONY: $(PC_STEPS:%=pc-%) pc-gbuild

clean:
	$(MAKE) -C src/os BUILD=$(BUILD)/os clean
	$(MAKE) -C src/compiler BUILD=$(BUILD)/compiler clean
	rm -rf $(BUILD)
