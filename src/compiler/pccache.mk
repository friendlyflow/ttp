# pccache.mk (included by the Makefile, at its end) — compiler-check's
# tools-check-<t> through ports-check's cache of results (gen/pccache.sh,
# gen/pckey.pl, and ../glibc/pccache.mk for the steps of src/glibc): where
# TTP_PCCACHE is set (ports-check sets it, unless PC_NOCACHE=1), tools-check
# runs pc-tools-check-<t>, which takes tools-check-<t>'s PASS from the cache
# when its inputs are byte for byte those of one that passed; its line in
# compiler-check's log is then "PASS tools-check-<t> cached (<key>)".
#
# The inputs of tools-check-<t>, all of them (when in doubt, one more: a
# needless run costs time, a missing input gives a false PASS):
#  - the tools it runs, by their bytes: each of TOOLS built for <t> (made
#    first: stage2 and their pages are in them), and this machine's
#    cparse, cprint and csema, whose output is the refs (CPREF, CSREF: these
#    are not made for the key, their inputs are in it: CPUNITS, the scripts,
#    CPCC, clang and the region cpref of the Makefile);
#  - what they and the Perl read: every tree (TREES), every licensed file
#    (LICENSED, LICENSES), boot/, isa/, macros/, shared.ff.txt, the C units
#    (../glibc/progs, progs/abi: CPUNITS are their gcc -E), progs/pp,
#    progs/mki, progs/s2ff, NIST's vectors (SHAV), ../glibc's mki.pl,
#    s2ffcheck.sh, predef-riscv64.txt, builtins and atomics, clang-prelude.h,
#    ../libgcc/mki.pl;
#  - the Perl and shell that it compares with, and every module of gen/;
#  - its recipe (the define tooltarget, by its text) and the values of the
#    variables in it; programs on PATH (perl, git, the C compiler, clang,
#    qemu) by their store paths.
# Left out: RUN_<t>'s qemu is in, slot.sh is not (where a command runs, not
# what it does); the paths of the worktree (W) and the BUILD (B).

define pck_nl


endef
PCK_GEN := fftext.pl unlicense.pl trim.pl frozen.pl mkhost.pl mkwhole.pl mkff.pl decls.pl licenses.pl insize.pl ffmerge.sh \
	cparsecheck.sh csemacheck.sh clangsema.pl csemacmp.pl s2ff.pl s2ff-aarch64.pl s2ff-arm.pl ffsplit.pl headers.pl ff2c.pl $(notdir $(wildcard gen/*.pm))
PCK_FILES := $(TREES) $(LICENSED) LICENSES shared.ff.txt $(X86GNU) $(PCK_GEN:%=gen/%) ../glibc/mki.pl ../glibc/s2ffcheck.sh \
	../glibc/predef-riscv64.txt ../glibc/builtins.ff.txt ../glibc/atomics.ff.txt ../glibc/clang-prelude.h ../libgcc/mki.pl
PCK_DIRS := boot isa macros progs/pp progs/mki progs/s2ff progs/ff2c progs/abi ../glibc/progs
PCK_VARS := TOOLS TOOLT CPCC C2FF_CLANG CSCLANG PPKEY PPTEST PPTF MKITEST MKILTEST SHAVFILES TTPC_FF TTPC2_SRC TTPC3_SRC HOSTS \
	TREES LICENSED X86GNU CPUNITS
pck_out = $(if $(PCOUT),$(file >$(PCOUT),$(1)),$(error pckey: PCOUT, the file of the spec, is not set))
define pckey_tools
pckey-tools-check-$(1): $(TOOLS:%=$(TL)/$(1)/%) $(TL)/$(TOOLT)/cparse $(TL)/$(TOOLT)/cprint $(TL)/$(TOOLT)/csema $(SHAV)/want $(CPUNITS)
	@:$$(call pck_out,R W $(abspath ../..)$$(pck_nl)R B $(abspath $(BUILD))$$(pck_nl)t TARGET=$(1)$$(pck_nl)t RUN=$(RUN_$(1)) $(RUN_$(TOOLT))$$(pck_nl)$$(foreach c,perl git $$(CPCC) $$(firstword $$(C2FF_CLANG)) $(RUN_$(1)) $(RUN_$(TOOLT)),x $$(c)$$(pck_nl))e PERL5LIB$$(pck_nl)$$(foreach f,$$(TOOLS:%=$(TL)/$(1)/%) $(TL)/$(TOOLT)/cparse $(TL)/$(TOOLT)/cprint $(TL)/$(TOOLT)/csema $$(CPUNITS) $$(PCK_FILES),f $$(abspath $$(f))$$(pck_nl))$$(foreach d,$$(SHAV) $$(PCK_DIRS),d $$(abspath $$(d))$$(pck_nl))$$(foreach v,$$(PCK_VARS),t $$(v)=$$($$(v))$$(pck_nl))t tooltarget=$$(subst $$(pck_nl),\n,$$(value tooltarget))$$(pck_nl)r $(abspath Makefile) cpref $(1)$$(pck_nl))
.PHONY: pckey-tools-check-$(1)
endef
$(foreach t,$(TOOLTARGETS),$(eval $(call pckey_tools,$(t))))

# tools-check-<t> through the cache (its key's files in TL/pc), and its key
# alone (the top Makefile's pc-keys)
pc-tools-check-%:
	@sh gen/pccache.sh -i tools-check-$* $(TL)/pc '$(MAKE) --no-print-directory pckey-tools-check-$*' $(MAKE) --no-print-directory tools-check-$*
pck-tools-check-%:
	@sh gen/pccache.sh -n tools-check-$* $(or $(PCKEYDIR),$(TL)/pc) '$(MAKE) --no-print-directory pckey-tools-check-$*' true
pc-keys: $(TOOLTARGETS:%=pck-tools-check-%)
.PHONY: pc-keys
