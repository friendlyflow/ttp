# glibc in ff: glibc's own C, the part a program reaches, translated into
# ttpc's C layer (see ~/.claude/plans/how-to-incorporate-the-wild-rocket.md
# and src/compiler/NEXT.md).
#
# This first step builds the reference glibc once, from the source flake.nix
# pins (GLIBC_SRC, upstream glibc-2.44) for riscv64 Linux, with the cross
# gcc unwrapped (GLIBC_CC) and the kernel's headers (GLIBC_HEADERS), all set
# by `nix develop`. build.log keeps the command that compiled each object:
# run again with -E it gives that object's .i, the C exactly as this
# configuration compiles it, which the translator reads (-save-temps would
# do it in the build, but the static and shared compiles of one source
# would share their temporaries). libc.a and crt1.o are for building the
# same programs with gcc, to compare with.
#
#   make glibc-ref     configure and build  -> ~/.cache/ttp/glibc/obj
#
# Not under build/ like the rest: this repository lives in Dropbox, which
# renames files whose names differ only in case, and glibc makes stamp.os
# next to stamp.oS (and .os next to .oS objects). Its build is also large
# (some 300 MB) and nothing to sync.

BUILD ?= $(HOME)/.cache/ttp/glibc
OBJ := $(BUILD)/obj
JOBS ?= $(shell nproc)

GLIBC_SRC ?= $(error GLIBC_SRC is not set: run this in `nix develop`)
GLIBC_HEADERS ?= $(error GLIBC_HEADERS is not set: run this in `nix develop`)
GLIBC_CC ?= $(error GLIBC_CC is not set: run this in `nix develop`)

# The Nix ld-wrapper's hardening flags have no place in a libc's own build.
export NIX_HARDENING_ENABLE :=

# The binutils of the target, by name: the dev shell sets AR, NM, OBJCOPY,
# ... to the host's, which configure would take.
TOOLS := $(foreach t,AR:ar NM:nm OBJCOPY:objcopy OBJDUMP:objdump READELF:readelf RANLIB:ranlib STRIP:strip GPROF:gprof LD:ld,$(word 1,$(subst :, ,$(t)))=riscv64-unknown-linux-gnu-$(word 2,$(subst :, ,$(t))))

.PHONY: glibc-ref clean

# A step that fails leaves nothing behind that make would take as made.
.DELETE_ON_ERROR:

glibc-ref: $(OBJ)/libc.a

$(OBJ)/config.status:
	mkdir -p $(OBJ)
	cd $(OBJ) && $(GLIBC_SRC)/configure \
	    --host=riscv64-unknown-linux-gnu --prefix=/usr \
	    --with-headers=$(GLIBC_HEADERS) \
	    --disable-werror --disable-nscd --disable-timezone-tools \
	    CC="$(GLIBC_CC)" CXX= $(TOOLS) > configure.log 2>&1 \
	    || { tail -30 configure.log; exit 1; }

$(OBJ)/libc.a: $(OBJ)/config.status
	$(MAKE) -C $(OBJ) -j$(JOBS) > $(OBJ)/build.log 2>&1 \
	    || { tail -40 $(OBJ)/build.log; exit 1; }
	@echo "glibc-ref: $(OBJ)/libc.a, each object's command in $(OBJ)/build.log"

clean:
	rm -rf $(BUILD)

# ---- glibc in ff, step by step ----------------------------------------------
# An object's .i (mki.pl), its AST (clang with clang-prelude.h, which gives
# clang the _FloatN types and builtins gcc has, and -fgnu89-inline as
# glibc's build has it), and from the ASTs of the
# objects a milestone needs, the ff of what its roots reach (c2ff.pl). Every
# step runs under a memory cap and a timeout: an unbounded run of c2ff once
# took the machine down.
I := $(BUILD)/i
FF := $(BUILD)/ff
C2FF_CLANG ?= $(error C2FF_CLANG is not set: run this in `nix develop`)
TTPC ?= ../../build/compiler/boot/stage2
SHARED := ../compiler/shared.ff
CAP := ulimit -v 4000000;

# M1, string: strlen, memcpy, memset, strcmp and strchr, each its ifunc, its
# generic C and its asm (vector; memcpy also for fast misaligned access),
# and glibc's __riscv_hwprobe (which the init routine hands the resolvers,
# as glibc's own startup does)
M1 := strlen memcpy memset strcmp strchr
OBJS_string := $(foreach f,$(M1),string/$(f) string/$(f)-generic) string/wordcopy string/strchrnul misc/hwprobe elf/dl-support
ASMS_string := $(M1:%=string/%-vector) string/memcpy_noalignment
ROOTS_string := $(M1) __riscv_hwprobe

# M2, stdlib: atoi, strtol and abs, with M1. strtol takes the locale (the C
# locale's tables, reached through the thread's locale pointer), errno, the
# grouping check and memcmp. qsort waits for malloc (M3): it reaches it.
M2 := atoi strtol abs
OBJS_stdlib := $(OBJS_string) $(M2:%=stdlib/%) stdlib/strtol_l stdlib/grouping csu/errno ctype/ctype_l \
	locale/C-ctype locale/C_name locale/global-locale locale/xlocale string/memcmp string/memcmp-generic \
	wcsmbs/wcsmbsload iconv/gconv_simple iconv/gconv_trans csu/libc-start assert/__libc_assert_fail \
	stdio-common/_fitoa_word libio/libc_fatal stdio-common/itoa-digits stdio-common/itoa-udigits \
	misc/mmap64 misc/setvmaname stdlib/abort string/mempcpy locale/lc-ctype \
	posix/_exit signal/libc_sigaction nptl/pthread_kill nptl/pthread_rwlock_wrlock signal/raise elf/dl-tunables nptl/pthread_self nptl/futex-internal nptl/lowlevellock nptl/cancellation $(EXTRA_C)
ASMS_stdlib := $(ASMS_string) string/memcmp-vector misc/munmap csu/sysdep posix/getpid misc/gettid nptl/syscall_cancel $(EXTRA_ASM)
ROOTS_stdlib := $(ROOTS_string) $(M2)

MILESTONES := string stdlib

.PRECIOUS: $(I)/%.i $(I)/%.json $(I)/%.s $(I)/%.dump $(I)/%.bin

$(I)/%.i: $(OBJ)/libc.a mki.pl
	$(CAP) timeout 120 perl mki.pl $(OBJ) $(GLIBC_SRC) $*.o > /dev/null

# An object of a .S: its .s (mki.pl again), and what glibc's compiler makes
# of it without relaxation, as instructions (for s2ff.pl, which takes the
# compressed ones GNU as picked) and as the bytes of its .text, which ttpc
# must make too.
$(I)/%.s: $(OBJ)/libc.a mki.pl
	$(CAP) timeout 120 perl mki.pl $(OBJ) $(GLIBC_SRC) $*.o > /dev/null

$(I)/%.dump $(I)/%.bin: $(I)/%.s
	$(CAP) timeout 60 $(GLIBC_CC) -c -mno-relax -x assembler $< -o $(I)/$*.ref.o
	riscv64-unknown-linux-gnu-objdump -d -M no-aliases $(I)/$*.ref.o > $(I)/$*.dump
	riscv64-unknown-linux-gnu-objcopy -O binary -j .text $(I)/$*.ref.o $(I)/$*.bin

$(I)/%.json: $(I)/%.i clang-prelude.h
	$(CAP) timeout 300 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=riscv64-linux-gnu -std=gnu11 -fgnu89-inline -w $< > $@

# A milestone's ff: c2ff's from its objects' ASTs, from its roots, then
# s2ff's of its asm parts, then the builtins written by hand and libatomic's
# functions (atomics.ff.txt, from mkatomics.pl: perl mkatomics.pl >
# atomics.ff.txt).
define milestone
$$(FF)/$(1).ff: $$(OBJS_$(1):%=$$(I)/%.json) $$(ASMS_$(1):%=$$(I)/%.dump) builtins.ff.txt atomics.ff.txt ../compiler/gen/c2ff.pl ../compiler/gen/s2ff.pl
	mkdir -p $$(FF)
	$$(CAP) timeout 300 perl ../compiler/gen/c2ff.pl $$(foreach o,$$(OBJS_$(1)),$$(I)/$$(o).json=$$(I)/$$(o).i) \
	    -- $$(ROOTS_$(1)) > $$(FF)/$(1).ff.txt
	for a in $$(ASMS_$(1)); do \
	    $$(CAP) timeout 60 perl ../compiler/gen/s2ff.pl $$(I)/$$$$a.s $$(I)/$$$$a.dump >> $$(FF)/$(1).ff.txt || exit 1; \
	done
	cat builtins.ff.txt atomics.ff.txt >> $$(FF)/$(1).ff.txt
	perl ../compiler/gen/fftext.pl ff $$(FF)/$(1).ff.txt > $$@
endef
$(foreach m,$(MILESTONES),$(eval $(call milestone,$(m))))

# Each asm part, assembled by ttpc alone (with a _start after it), is the
# bytes glibc's compiler made of it, its .text without the padding at its
# end; the fields relocations fill in (relmask.pl) are the linker's, not
# compared, and what it names from elsewhere is a stand-in label after it.
asm-check: $(ASMS_stdlib:%=$(I)/%.dump) $(ASMS_stdlib:%=$(I)/%.bin) ../compiler/gen/s2ff.pl
	mkdir -p $(FF)
	@for a in $(ASMS_stdlib); do \
	    n=$$(basename $$a); \
	    { perl ../compiler/gen/s2ff.pl $(I)/$$a.s $(I)/$$a.dump && printf '_start:\n  ebreak\n' && \
	      riscv64-unknown-linux-gnu-objdump -t $(I)/$$a.ref.o | awk '/\*UND\*/ { printf "%s:\n  ebreak\n", $$NF }'; } > $(FF)/$$n.asm.ff.txt || exit 1; \
	    perl ../compiler/gen/fftext.pl ff $(FF)/$$n.asm.ff.txt > $(FF)/$$n.asm.ff; \
	    $(CAP) timeout 60 qemu-riscv64 $(TTPC) $(SHARED) $(FF)/$$n.asm.ff $(FF)/$$n.asm > $(FF)/$$n.asm.lst || exit 1; \
	    size=$$(perl ../compiler/gen/s2ff.pl --size $(I)/$$a.s $(I)/$$a.dump) || exit 1; \
	    riscv64-unknown-linux-gnu-objdump -r $(I)/$$a.ref.o > $(FF)/$$n.relocs; \
	    head -c $$size $(I)/$$a.bin > $(FF)/$$n.want.raw; \
	    tail -c +121 $(FF)/$$n.asm | head -c $$size > $(FF)/$$n.got.raw; \
	    perl relmask.pl $(FF)/$$n.relocs $(FF)/$$n.want.raw > $(FF)/$$n.want || exit 1; \
	    perl relmask.pl $(FF)/$$n.relocs $(FF)/$$n.got.raw > $(FF)/$$n.got || exit 1; \
	    cmp $(FF)/$$n.got $(FF)/$$n.want || exit 1; \
	    echo "asm-check: $$a: ttpc and glibc's compiler agree ($$size bytes)"; \
	done

# progs/strlen.ff imports string.ff from its own folder, so both go there
strlen-check: $(FF)/string.ff progs/strlen.ff asm-check
	cp progs/strlen.ff $(FF)/strlen-prog.ff
	$(CAP) timeout 120 qemu-riscv64 $(TTPC) $(SHARED) $(FF)/strlen-prog.ff $(FF)/strlen-prog > $(FF)/strlen-prog.lst
	s=0; $(CAP) timeout 30 qemu-riscv64 -cpu rv64,v=false $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: glibc's strlen, generic C (-cpu rv64,v=false): 12"
	s=0; $(CAP) timeout 30 qemu-riscv64 $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: with V its resolver picks glibc's vector asm: 12"

# A test program in C, progs/NAME.c, built two ways: with gcc against
# libc.a (glibc's own startup, no builtins: each call reaches glibc), and
# through c2ff --program, with ttpc against NAME.ff, the milestone of that
# name (each takes in the ones before it). Both run with V and without; all
# four must exit with the status in progs/NAME.expect.
CRTBEGIN = $(shell $(GLIBC_CC) -print-file-name=crtbeginT.o)
CRTEND = $(shell $(GLIBC_CC) -print-file-name=crtend.o)

$(FF)/%.ref: progs/%.c $(OBJ)/libc.a
	mkdir -p $(FF)
	$(CAP) timeout 120 $(GLIBC_CC) -O2 -fno-builtin -c $< -o $(FF)/$*.ref.o
	$(CAP) timeout 120 $(GLIBC_CC) -static -nostdlib -o $@ $(OBJ)/csu/crt1.o $(OBJ)/csu/crti.o $(CRTBEGIN) \
	    $(FF)/$*.ref.o -Wl,--start-group $(OBJ)/libc.a -lgcc -lgcc_eh -Wl,--end-group $(CRTEND) $(OBJ)/csu/crtn.o

$(FF)/%-prog.ff: progs/%.c clang-prelude.h ../compiler/gen/c2ff.pl
	mkdir -p $(FF)
	$(CAP) timeout 60 $(GLIBC_CC) -E -P $< -o $(FF)/$*-prog.i
	$(CAP) timeout 120 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=riscv64-linux-gnu -std=gnu11 -w $(FF)/$*-prog.i > $(FF)/$*-prog.json
	$(CAP) timeout 120 perl ../compiler/gen/c2ff.pl --program $*.ff $(FF)/$*-prog.json=$(FF)/$*-prog.i -- main > $(FF)/$*-prog.ff.txt
	perl ../compiler/gen/fftext.pl ff $(FF)/$*-prog.ff.txt > $@

$(FF)/%-prog: $(FF)/%-prog.ff $(FF)/%.ff $(TTPC)
	$(CAP) timeout 900 qemu-riscv64 $(TTPC) $(SHARED) $< $@ > $@.lst

define check
$(1)-check: $$(FF)/$(1).ref $$(FF)/$(1)-prog progs/$(1).expect asm-check
	@want=$$$$(head -n 1 progs/$(1).expect | cut -d" " -f2); \
	for b in $(1).ref $(1)-prog; do \
	    for cpu in rv64 rv64,v=false; do \
	        s=0; $$(CAP) timeout 60 qemu-riscv64 -cpu $$$$cpu $$(FF)/$$$$b || s=$$$$?; \
	        test $$$$s -eq $$$$want || { echo "$(1)-check: $$$$b on $$$$cpu: exit status $$$$s, not $$$$want"; exit 1; }; \
	    done; \
	done; \
	echo "$(1)-check: gcc + libc.a and ttpc + glibc in ff agree, with V and without: exit $$$$want"
.PHONY: $(1)-check
endef
$(foreach m,$(MILESTONES),$(eval $(call check,$(m))))

.PHONY: strlen-check asm-check
