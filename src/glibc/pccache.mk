# pccache.mk (included by the Makefile, at its end) — the inputs of each goal
# of this Makefile that ports-check takes from its cache of results
# (../compiler/gen/pccache.sh and pckey.pl): `make pckey-GOAL PCOUT=file`
# makes what the inputs are made of (as GOAL's own make would, first), then
# writes the spec of GOAL's inputs on this BUILD and GTARGET, one per line,
# whose key pckey.pl computes: sha256 over their bytes. A step whose key
# has a PASS in the cache is not run again.
#
# Each goal's inputs are listed here, all of them. When in doubt, list one:
# one too many costs a needless run, one missing a false PASS. A rule or a
# variable a cached goal uses is either inside one of its #pccache< regions
# of the Makefile (their lines are in its key, but for the definitions of
# the other targets' variables: a line of x86_64's is in x86_64's keys
# alone) or listed here by its value (PCK_*VARS). Files are in the key by
# their bytes, programs in /nix/store by their paths (the store's hash).
# A file or a region that is not there is no key: the step then runs.
# Not taken from the cache: what runs code ttpc compiled (each milestone's
# check, check-O, the programs: their inputs are all of ttpc and its
# libraries), units-ready, cparse-check, csema-check, cpp-check, the
# libgcc checks.
#
# Left out on purpose: slot.sh and RUN's caps (where a command runs, not
# what it does; a step's own timeouts are in its region's lines), TTPCJ
# (ttpc -j makes the same bytes), the paths of the worktree and the BUILD
# (W and B: worktrees share their results).

# (every goal's: the roots, the target, perl and its modules' path)
PCK_TOP := $(abspath ../..)
pck_common = R W $(PCK_TOP)$(nl)R B $(abspath $(BUILD))$(nl)t GTARGET=$(GTARGET)$(nl)x perl$(nl)e PERL5LIB$(nl)
pck_f = $(foreach f,$(1),f $(abspath $(f))$(nl))
pck_t = $(foreach v,$(1),t $(v)=$($(v))$(nl))
pck_r = $(foreach r,$(1),r $(abspath Makefile) $(r) $(GTARGET)$(nl))
pck_x = $(foreach c,$(1),x $(c)$(nl))
pck_o = $(foreach f,$(1),o $(abspath $(f))$(nl))
pck_out = $(if $(PCOUT),$(file >$(PCOUT),$(1)),$(error pckey: PCOUT, the file of the spec, is not set))

# NAME-roundtrip (each milestone, each target): ff2c.pl writes the
# milestone's page back as C (from its .ff.txt, by its bytes: csema's and
# s2ff's output, whichever tools made it; ff2c reads shared.ff's type
# words too), clang reads that C (rt.json, RTFLAGS) and each unit's .i (its
# .json: CLANGFIX and clangvec.pl, libgcc's units clangfix.pl, aarch64.h
# and LCLANG), roundtrip.pl compares the two ASTs (and reads the .i),
# headers.pl the headers against GLIBC_SRC and LIBGCC_SRC (sources nothing
# writes: by their paths). ff2c and headers are the tools in ff now (FF2CT,
# HEADERST: by their bytes, as ttpc made them; the Perl beside them their
# twins). Each unit's cache (roundtrip.pl --unit-cache, $(I)/<unit>.rtn, the
# region rtn) is made of its .json and .i, roundtrip.pl, FFold.pm and
# GTARGET, all in the key already (the .json by what makes it: its .i, the
# region json and clang). Regions rt, json, rtn, ljson.
PCK_RTFILES := roundtrip.pl ../compiler/gen/ff2c.pl ../compiler/gen/headers.pl ../compiler/gen/FF.pm ../compiler/gen/FFold.pm \
	../compiler/gen/Header.pm ../compiler/gen/Words.pm ../compiler/shared.ff clang-prelude.h clangvec.pl ../libgcc/clangfix.pl ../libgcc/aarch64.h \
	$(FF2CT) $(HEADERST)
PCK_RTVARS := CTARGET PROGFLAGS C2FF_CLANG CLANGFIX CLANGVEC RTFLAGS_$(GTARGET) LCLANG_$(GTARGET) LCLANGVEC_$(GTARGET) LIBGCC_FIXEDC GLIBC_SRC LIBGCC_SRC
define pckey_roundtrip
pckey-$(1)-roundtrip: $$(FF)/$(1).ff $$(OBJS_all_$(1):%=$$(I)/%.i)
	@:$$(call pck_out,$$(pck_common)$$(call pck_f,$$(FF)/$(1).ff.txt $$(OBJS_all_$(1):%=$$(I)/%.i) $$(PCK_RTFILES))$$(call pck_t,$$(PCK_RTVARS) OBJS_all_$(1))$$(call pck_r,rt json rtn ljson)$$(call pck_x,$$(firstword $$(C2FF_CLANG))))
.PHONY: pckey-$(1)-roundtrip
endef
$(foreach m,$(MILESTONES),$(eval $(call pckey_roundtrip,$(m))))

# asm-check (each target): each part of ASMCHECK, s2ff's ff of its .s (.Ls
# on aarch64) and .dump, assembled by ttpc, against what glibc's compiler
# made of the .s (.dump, .bin, .ref.o, made before the key; on aarch64 and
# x86_64 also glibc's own object), relmask.pl, objdump and objcopy. Its
# outputs, each part's .asmok, are kept with its PASS and written again on
# a hit, so that units-ready and the checks that need asm-check find them
# made. Regions asm, s2ff.
PCK_ASMVARS := ASMCHECK ASMTRAP ASMHDR SSRC S2FF S2FFH TTPC_RUN SHARED FFTEXT XPRE CPRUN
pck_asmpart = $(I)/$(1).s $(I)/$(1)$(SSRC) $(I)/$(1).dump $(I)/$(1).bin $(I)/$(1).ref.o \
	$(if $(filter aarch64 x86_64,$(GTARGET)),$(if $(filter libgcc/%,$(1)),$(LOBJ)/$(patsubst libgcc/%,%,$(1)),$(OBJ)/$(1)).o)
# (the parts' .dump made by a make of its own, as asm-check's: the list is
# all of glibc's asm on aarch64, x86_64 and arm, known only after the
# Makefile, and too long for one command)
pck_asm = $(pck_common)$(call pck_f,$(foreach a,$(ASMCHECK),$(call pck_asmpart,$(a))) $(S2FFDEPS) $(SHARED) $(TTPC) $(FFTEXTT) relmask.pl)$(call pck_t,$(PCK_ASMVARS))$(call pck_r,asm s2ff)$(call pck_x,$(XPRE)objdump $(XPRE)objcopy $(CPRUN) $(filter qemu-%,$(TTPC_RUN)))$(call pck_o,$(ASMCHECK:%=$(I)/%.asmok))
pckey-asm-check pckey-asmcfi-check:
	@:$(if $(PCOUT),,$(error pckey: PCOUT, the file of the spec, is not set))$(file >$(PCOUT).made,$(foreach a,$(ASMCHECK),$(I)/$(a).dump$(nl)))
	@xargs -r -a $(PCOUT).made $(MAKE) --no-print-directory
	@:$(call pck_out,$(pck_asm)$(if $(filter pckey-asmcfi-check,$@),$(pck_cfi)))
# asmcfi-check (aarch64's, x86_64's and arm's asm step): asm-check's inputs
# and outputs, and each part of ASMCFICHECK built again by ttpc with -g
# (from the .asm.ff and .facts asm-check made of the inputs above; ttpc's
# frames, asmcfi.pl, are ttpc's bytes) against the frames of the .ref.o:
# cficheck.pl and readelf. Its .cfiok, after the .asmok (so that each is
# newer than its .asmok), kept and written again on a hit. ASMCFIKNOWN and
# the rules are in the region asm.
pck_cfi = $(call pck_f,cficheck.pl)$(call pck_t,ASMCFICHECK)$(call pck_x,$(XPRE)readelf)$(call pck_o,$(ASMCFICHECK:%=$(I)/%.cfiok))
.PHONY: pckey-asm-check pckey-asmcfi-check
