# Copyright (C) 2026 Nico Verrijdt. This file is part of ttp. It is free
# software under the GNU General Public License, version 3; no warranty.
#
# port.mk: a C program of the outside world (a GNU package) in ff, shared by
# every port (src/ports/<package>/Makefile sets the PKG_ variables below and
# includes it). The steps, each for GTARGET (riscv64 aarch64 x86_64 arm):
#
#   make sysroot   the target's glibc as a program sees it: the reference
#                  build's (~/.cache/ttp/glibc-gcc16, only read) installed
#                  into GB/sysroot from a copy of its obj (the copy then goes)
#   make ref       the package configured and built against it, statically,
#                  with gcc 16 (GLIBC_CC*) through ffcc as CC: gcc's program
#                  (the reference), and ffcc's record of each compile and
#                  link (REC: its command, its .i by gcc -E)
#   make units     the program's units: its link's objects and the members
#                  of its archives; each one's .i by cpp (ff) from the same
#                  command (PB/ff/i), compared with gcc's byte for byte
#   make ff        csema -l over those units into the program's tree
#                  (PB/ff/NAME.ff: its license at the root, a group per folder
#                  with each file's header), then ttpc with glibc in ff
#                  (GB/ff/glibc, src/glibc's all of glibc) -> PB/ff/NAME
#   make check     the package's own test suite (make check) twice, with
#                  gcc's program and with ttpc's in its place: the results
#                  test by test (PB/check.table), equal or not
#   make predef    PKG/predef-GTARGET.txt: gcc's predefined macros and
#                  answers for the commands of this package (as src/glibc's
#                  make predef), which cpp reads
#   make licenses  the tree's license (licenses.pl)
#
# What it costs, cold, per target: the sysroot a few minutes; all of glibc in
# ff (src/glibc's, the first time: every unit's .i, csema, s2ff of its asm)
# 30 to 60 minutes; the package's two builds and its cpp check minutes; its
# csema -l under a minute, ttpc a minute; its test suite natively a minute,
# under qemu a few. So not a ports-check step: the top Makefile's ports-sed.
#
# A package of several programs (PKG_PROGRAMS: each one's path in the
# build, its NAME the last part: bc/bc dc/dc) has a tree and a program of
# ttpc's for each; PKG_PROGRAM is the one of a package of one.
#
# Builds in PB (~/.cache/ttp/build/<worktree>/ports/PKG/GTARGET), glibc's
# side in GB (the worktree's glibc BUILD of that target, as ports-check's
# GBUILD). GLIBC_FROM=<another worktree's GBUILD>: its sysroot and all of
# glibc in ff are taken from there, only read (never made or remade here:
# they must be of the same csema and glibc in ff as this worktree's); the
# locales are still this GBUILD's. Under qemu-user on the targets that are not the machine's: the
# programs the test suite runs (the package's and its test helpers) are
# run by a binfmt-less wrapper, see QWRAP.
GTARGET ?= x86_64
TOP := $(abspath ../../..)
WT := $(notdir $(TOP))
GBUILD ?= $(HOME)/.cache/ttp/build/$(WT)/glibc
GB := $(GBUILD)$(if $(filter-out riscv64,$(GTARGET)),/$(GTARGET))
GREF := $(HOME)/.cache/ttp/glibc-gcc16$(if $(filter-out riscv64,$(GTARGET)),/$(GTARGET))/obj
PB ?= $(HOME)/.cache/ttp/build/$(WT)/ports/$(PKG)/$(GTARGET)
GLIBC_FROM ?=
GBF := $(if $(GLIBC_FROM),$(GLIBC_FROM)$(if $(filter-out riscv64,$(GTARGET)),/$(GTARGET)),$(GB))
SYSROOT := $(GBF)/sysroot
PKG_PROGRAMS ?= $(PKG_PROGRAM)
NAMES := $(notdir $(PKG_PROGRAMS))
PKG_FIRST := $(firstword $(PKG_PROGRAMS))
# (a name's program: $(call progof,NAME))
progof = $(filter %/$(1) $(1),$(PKG_PROGRAMS))
REC := $(PB)/rec
PFF := $(PB)/ff
SRCDIR := $(PB)/src
REFDIR := $(PB)/ref

TRIPLE_arm := armv7l-unknown-linux-gnueabihf
TRIPLE := $(or $(TRIPLE_$(GTARGET)),$(GTARGET)-unknown-linux-gnu)
GCC_riscv64 = $(GLIBC_CC)
GCC = $(or $(GCC_$(GTARGET)),$(GLIBC_CC_$(GTARGET)))
KHEADERS_riscv64 = $(GLIBC_HEADERS)
KHEADERS = $(or $(KHEADERS_$(GTARGET)),$(GLIBC_HEADERS_$(GTARGET)))
GCCINC = $(shell $(GCC) -print-file-name=include)
# the target's binutils by name (on x86_64, the host's: theirs have no prefix)
XPRE = $(if $(shell command -v $(TRIPLE)-objdump),$(TRIPLE)-)
# the headers: gcc's own, then glibc's (installed) and the kernel's, never
# the C library gcc was built against (its native system header dir)
PKG_CPPFLAGS = -nostdinc -isystem $(GCCINC) -isystem $(SYSROOT)/usr/include -isystem $(KHEADERS)
# static, glibc's startup files and libc.a from the sysroot (its lib64 on
# x86_64, lib64/lp64d on riscv64: where libc.a is), libgcc gcc's
SYSLIB = $(patsubst %/,%,$(dir $(firstword $(wildcard $(SYSROOT)/usr/lib*/libc.a $(SYSROOT)/usr/lib*/*/libc.a))))
PKG_LDFLAGS = -static -B$(SYSLIB)/ -L$(SYSLIB)

FFCC := $(abspath ../ffcc)
export FFCC_GCC = $(GCC)
export FFCC_ROOT = $(REFDIR)

ifeq ($(shell uname -m),x86_64)
TTPC ?= $(TOP)/build/compiler/x86_64/stage2
CPTOOLS ?= $(TOP)/build/compiler/tools/x86_64
CPRUN :=
else
TTPC ?= $(TOP)/build/compiler/boot/stage2
CPTOOLS ?= $(TOP)/build/compiler/tools/riscv64
CPRUN := qemu-riscv64
endif
TTPCJ ?= 4
TTPC_RUN = $(CPRUN) $(TTPC) -j$(TTPCJ) --target $(GTARGET)
CSEMA := $(CPTOOLS)/csema
CPP := $(CPTOOLS)/cpp
SHARED := $(TOP)/src/compiler/shared.ff $(if $(filter x86_64,$(GTARGET)),$(TOP)/src/compiler/x86_64gnu.ff)
PREDEF := $(CURDIR)/predef-$(GTARGET).txt
SLOT := sh $(TOP)/src/compiler/gen/slot.sh
CAPKB_arm := 8000000
CAPKB := $(or $(CAPKB_$(GTARGET)),4000000)
RUN := $(SLOT) -v $(CAPKB)
# a make of another package, without this make's variables (MAKEFLAGS
# carries GTARGET, PKG, ... down into it) and at most 4 jobs
SUBMAKE := env -u MAKEFLAGS -u MFLAGS -u MAKELEVEL -u MAKEOVERRIDES make
JOBS ?= 4
GLIBCJ ?= 3
NATIVE := $(filter $(shell uname -m),$(GTARGET))
GLIBCMAKE = $(MAKE) --no-print-directory -C $(TOP)/src/glibc BUILD=$(GB) $(if $(filter-out riscv64,$(GTARGET)),GTARGET=$(GTARGET))

.DELETE_ON_ERROR:
.PHONY: sysroot ref units ff check predef predef-check licenses FORCE

# ---- the sysroot: glibc installed as a program's build sees it
# (PERL: config.make's is the store path of the reference build's day, which
# nix gc may have taken; the manual's install runs it)
sysroot: $(SYSROOT)/.installed
$(SYSROOT)/.installed:
	$(if $(GLIBC_FROM),{ echo "port.mk: no sysroot in GLIBC_FROM's $(GBF)"; exit 1; })
	test -e $(GREF)/libc.a || { echo "port.mk: no reference glibc $(GREF)"; exit 1; }
	rm -rf $(GB)/sysroot.obj $(SYSROOT); mkdir -p $(GB)
	cp -a $(GREF)/. $(GB)/sysroot.obj
	$(RUN) -t 3600 $(SUBMAKE) -C $(GB)/sysroot.obj -j$(JOBS) install install_root=$(SYSROOT) PERL=$$(command -v perl) > $(GB)/sysroot.log 2>&1 \
	    || { tail -30 $(GB)/sysroot.log; exit 1; }
	rm -rf $(GB)/sysroot.obj
	ls $(SYSROOT)/usr/lib*/libc.a $(SYSROOT)/usr/lib*/*/libc.a 2> /dev/null | grep -q . || { echo "port.mk: no libc.a in $(SYSROOT)"; exit 1; }
	$(SYSROOTSCRIPTS)
	touch $@
# (the linker scripts installed, x86_64's libm.a: GROUP ( /usr/lib64/libm-2.44.a
# /usr/lib64/libmvec.a ), their paths made the sysroot's, which gcc is not
# told of: gawk links -lm)
SYSROOTSCRIPTS = for f in $$(grep -l -s '^/\* GNU ld script' $(SYSROOT)/usr/lib*/*.a $(SYSROOT)/usr/lib*/*/*.a); do \
	    sed -i 's| /usr/lib| $(SYSROOT)/usr/lib|g' $$f || exit 1; done
sysroot-scripts:
	$(SYSROOTSCRIPTS)

# ---- the locales a test suite asks for (PKG_LOCALES: source:charmap:name),
# made from glibc's own locale sources (as the sysroot has them) by nixpkgs'
# localedef of glibc 2.44 (LOCALEDEF, nix develop's) into GBUILD/locales,
# one set for every target (glibc's locale files differ by endianness
# alone: all four are little-endian); the checks run with LOCPATH there, as
# a static program finds no /usr/lib/locale of its glibc on this machine
LOCALEDEF ?= $(error LOCALEDEF is not set: run this in `nix develop`)
LOCALES := $(GBUILD)/locales
$(LOCALES)/.made-$(PKG): $(SYSROOT)/.installed
	mkdir -p $(LOCALES)
	for l in $(PKG_LOCALES); do src=$${l%%:*}; rest=$${l#*:}; cm=$${rest%%:*}; name=$${rest#*:}; \
	    test -e $(LOCALES)/$$name/LC_CTYPE && continue; \
	    I18NPATH=$(SYSROOT)/usr/share/i18n $(LOCALEDEF) -c --no-archive -i $$src -f $$cm $(LOCALES)/$$name; \
	    test -e $(LOCALES)/$$name/LC_CTYPE || { echo "port.mk: localedef made no $$name"; exit 1; }; \
	done
	touch $@

# ---- the reference build, gcc's, and ffcc's record of it
ref: $(REFDIR)/$(PKG_FIRST)
$(SRCDIR)/configure: $(PKG_SRC)
	rm -rf $(SRCDIR); mkdir -p $(SRCDIR)
	tar -xf $(PKG_SRC) -C $(SRCDIR) --strip-components=1
	touch $@
$(REFDIR)/config.status: $(SRCDIR)/configure $(SYSROOT)/.installed $(FFCC)
	rm -rf $(REFDIR) $(REC); mkdir -p $(REFDIR)
	cd $(REFDIR) && $(RUN) -t 1800 $(SRCDIR)/configure --host=$(TRIPLE) $(PKG_CONFIGURE) \
	    CC=$(FFCC) CPPFLAGS="$(PKG_CPPFLAGS) $(PKG_DEFINES)" LDFLAGS="$(PKG_LDFLAGS)" AR=$(XPRE)ar RANLIB=$(XPRE)ranlib > configure.log 2>&1 \
	    || { tail -30 configure.log; exit 1; }
$(REFDIR)/$(PKG_FIRST): $(REFDIR)/config.status
	rm -rf $(REC); mkdir -p $(REC)
	cd $(REFDIR) && FFCC_REC=$(REC) $(RUN) -t 3600 $(SUBMAKE) -j$(JOBS) $(PKG_BUILDFLAGS) > build.log 2>&1 || { tail -30 build.log; exit 1; }
	for p in $(PKG_PROGRAMS); do \
	    test -e $(REC)/l/$$p.cmd || { echo "port.mk: ffcc has no record of $$p's link"; exit 1; }; \
	    cp -p $(REFDIR)/$$p $(REFDIR)/$$p.gcc; \
	done

# ---- each program's units: its link's objects (-O: their constructors are
# roots) and its archives' members (PFF/NAME.units); each unit of them all
# (PFF/units) by cpp from its command, its .i compared with gcc's
# (from the link's record, not the program: the check puts another in its place)
$(PFF)/%.units: $(REC)/l/$(PKG_FIRST).cmd ../units.sh
	mkdir -p $(PFF)
	sh ../units.sh $(REFDIR) $(REC) $(REC)/l/$(call progof,$*).cmd > $@.tmp
	mv $@.tmp $@
$(PFF)/units: $(NAMES:%=$(PFF)/%.units)
	sed 's/^-O //' $^ | sort -u > $@.tmp
	mv $@.tmp $@
units: $(PFF)/units.same
$(PFF)/units.same: $(PFF)/units ../cppunits.sh $(PREDEF) | $(CPP)
	$(RUN) -t 1800 sh ../cppunits.sh "$(CPRUN) $(CPP)" $(PREDEF) $(REFDIR) $(REC) $(PFF)/i $(PFF)/units > $(PFF)/units.cpp.log 2>&1 \
	    || { tail -20 $(PFF)/units.cpp.log; exit 1; }
	tail -1 $(PFF)/units.cpp.log
	touch $@

# ---- the ff build: csema -l, then ttpc against all of glibc in ff
CSFLAGS = -t $(GTARGET) -s $(SRCDIR) -S $(TOP)/src/compiler/shared.ff
# (PKG_DEFINES: the package's own -D for both builds, gcc's and ttpc's, as
# configure takes them in CPPFLAGS: coreutils' -DNO_ASM, longlong.h's C)
PKG_DEFINES ?=
# (PKG_CSHEAP: GB of address space for csema's heap, in a file, -M, as all
# of glibc's in src/glibc: coreutils' 500 units need more than 9 GB)
PKG_CSHEAP ?=
# (all of glibc in ff, src/glibc's, in GB: its obj the reference's, as
# ports-check's pc-gbuild links it)
$(REC)/l/$(PKG_FIRST).cmd: | $(REFDIR)/$(PKG_FIRST)
# (src/glibc's make decides whether it is up to date: csema, the units, ...;
# GLIBC_FROM's is only there)
$(GBF)/ff/glibc/index.ff: $(if $(GLIBC_FROM),,FORCE)
	$(if $(GLIBC_FROM),{ echo "port.mk: no glibc in ff in GLIBC_FROM's $(GBF)"; exit 1; })
	test -e $(GB)/obj || { mkdir -p $(GB) && ln -sfn $$(readlink -f $(GREF)) $(GB)/obj; }
	$(GLIBCMAKE) -j$(GLIBCJ) $@
ff: $(NAMES:%=$(PFF)/%)
$(PFF)/%.ff: $(PFF)/units.same $(PFF)/%.units $(GBF)/ff/glibc/index.ff $(CSEMA) $(CURDIR)/license.ff.txt
	ln -sfn $(GBF)/ff/glibc $(PFF)/glibc
	cp $(CURDIR)/license.ff.txt $(PFF)/$*.ff.txt
	sed 's|^\(-O \)\?\(.*\)$$|\1$(PFF)/i/\2.i=\2.i|' $(PFF)/$*.units | tr ' ' '\n' > $(PFF)/$*.csunits
	$(RUN) -v $(if $(PKG_CSHEAP),70000000,9000000) -t 3600 $(CPRUN) $(CSEMA) -l $(CSFLAGS) $(if $(PKG_CSHEAP),-M $(PFF)/$*.heap $(PKG_CSHEAP)) -p $* -N $(PKG)-$(PKG_VERSION) $(PKG_LICENSE) COPYING -B $(REFDIR) \
	    -P glibc -I $(GBF)/ff/glibc/index.ff -J $(GBF)/ff/glibc.statics @$(PFF)/$*.csunits -- main >> $(PFF)/$*.ff.txt 2> $(PFF)/$*.csema.err \
	    || { tail -5 $(PFF)/$*.csema.err; exit 1; }
	perl $(TOP)/src/compiler/gen/fftext.pl ff $(PFF)/$*.ff.txt > $@
$(NAMES:%=$(PFF)/%): $(PFF)/%: $(PFF)/%.ff $(TTPC) $(SHARED)
	$(RUN) -t 3600 $(TTPC_RUN) -g $(SHARED) $< $@ > $@.lst
# (the tree's license at its root; its groups hold each file's header, as
# a program's tree, not a library's pages: its types are at the top)
licenses: $(NAMES:%=$(PFF)/%.ff)
	for n in $(NAMES); do perl $(TOP)/src/compiler/gen/licenses.pl $(CURDIR)/license.ff.txt $(PFF)/$$n.ff || exit 1; done

# ---- the check: the package's test suite with gcc's program, then ttpc's
# (each run's logs kept: PB/check-gcc, PB/check-ff); the table of both
# The program in the build is gcc's (PKG_PROGRAM.gcc, kept by ref) or
# ttpc's for the run, then gcc's again, each made newer than its objects so
# that make check takes it as it is; off the machine's own target, every
# program of the target in the build runs under qemu-user (../qwrap.sh:
# each a script that execs qemu, no binfmt needed), for the run only.
QEMU := $(if $(NATIVE),,qemu-$(GTARGET))
# what make check is (PKG_CHECKTARGET), how long it may take, and the files
# of its results kept (by find's tests; automake's .trs and .log by default)
# (PKG_CHECKRUN: the command of the run, in the build's folder, where it is
# not make's: $* is gcc or ff, the run's results go in PB/check-$*)
PKG_CHECKTARGET ?= check
PKG_CHECKRUN ?= $(SUBMAKE) -j$(JOBS) $(PKG_CHECKTARGET) $(PKG_BUILDFLAGS) $(PKG_CHECKFLAGS)
PKG_CHECKSECS ?= 3600
PKG_CHECKFILES ?= -name '*.trs' -o -name '*.log'
QWRAP = $(if $(QEMU),sh ../qwrap.sh $(1) $(REFDIR) "$(QEMU) $(QEMUFLAGS)",:)
check: $(PB)/check.table
$(PB)/check-%.done: $(REFDIR)/$(PKG_FIRST) $(if $(PKG_LOCALES),$(LOCALES)/.made-$(PKG))
	@echo "check: make check with $*'s $(NAMES)"
	for p in $(PKG_PROGRAMS); do \
	    cp $(if $(filter ff,$*),$(PFF)/$$(basename $$p),$(REFDIR)/$$p.gcc) $(REFDIR)/$$p && touch $(REFDIR)/$$p || exit 1; \
	done
	rm -rf $(PB)/check-$*; mkdir -p $(PB)/check-$*
	cd $(REFDIR) && $(RUN) -t 1800 $(SUBMAKE) -j$(JOBS) $(PKG_BUILDFLAGS) $(PKG_CHECKPROGS) > $(PB)/check-$*/build.log 2>&1
	$(call QWRAP,wrap)
	-cd $(REFDIR) && LOCPATH=$(LOCALES) $(RUN) -t $(PKG_CHECKSECS) $(PKG_CHECKRUN) > $(PB)/check-$*/make.log 2>&1
	$(call QWRAP,unwrap)
	for p in $(PKG_PROGRAMS); do cp $(REFDIR)/$$p.gcc $(REFDIR)/$$p && touch $(REFDIR)/$$p; done
	cd $(REFDIR) && find . \( $(PKG_CHECKFILES) \) -newer $(PB)/check-$*/build.log | tar -cf - -T - | tar -xf - -C $(PB)/check-$*
	touch $@
$(PB)/check-ff.done: $(NAMES:%=$(PFF)/%) $(PB)/check-gcc.done
$(PB)/check.table: $(PB)/check-gcc.done $(PB)/check-ff.done ../checktable.sh $(PKG_RESULTS)
	sh ../checktable.sh $(PB)/check-gcc $(PB)/check-ff $(PKG_RESULTS) > $@
	head -1 $@

# ---- cpp's predefined macros for this package's commands (src/glibc/predef.pl)
predef: $(PFF)/units
	@set -e; d=$(PB)/predef; rm -rf $$d; mkdir -p $$d; : > $$d/queries; \
	for pass in 1 2 3 4 5; do \
	    perl $(TOP)/src/glibc/predef.pl $(GCC) --queries $$d/queries $(REC)/build.log > $$d/predef.txt; \
	    sh ../cppunits.sh --collect "$(CPRUN) $(CPP)" $$d/predef.txt $(REFDIR) $(REC) $$d/i $(PFF)/units 2>&1 \
	        | sed -n 's/^cpp: query //p; s/^cpp: \(target .*\)/\1/p' | sort -u > $$d/new; \
	    test -s $$d/new || break; \
	    sort -u $$d/new $$d/queries > $$d/q; mv $$d/q $$d/queries; \
	    echo "predef: pass $$pass, $$(wc -l < $$d/new) questions without gcc's answer"; \
	done; \
	test ! -s $$d/new || { echo "predef: still questions after 5 passes"; exit 1; }; \
	cp $$d/predef.txt $(PREDEF); echo "predef: $(PREDEF)"
