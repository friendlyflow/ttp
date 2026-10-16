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
# clang the _FloatN types and builtins gcc has), and from the ASTs of the
# objects a milestone needs, the ff of what its roots reach (c2ff.pl). Every
# step runs under a memory cap and a timeout: an unbounded run of c2ff once
# took the machine down.
I := $(BUILD)/i
FF := $(BUILD)/ff
C2FF_CLANG ?= $(error C2FF_CLANG is not set: run this in `nix develop`)
TTPC ?= ../../build/compiler/boot/stage2
SHARED := ../compiler/shared.ff
CAP := ulimit -v 4000000;

# M1, strlen: its ifunc, the generic C, the vector asm and glibc's
# __riscv_hwprobe (which the init routine hands the resolver, as glibc's own
# startup does)
OBJS_strlen := string/strlen string/strlen-generic misc/hwprobe elf/dl-support
ASMS_strlen := string/strlen-vector
ROOTS_strlen := strlen __riscv_hwprobe

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
	    -fsyntax-only --target=riscv64-linux-gnu -std=gnu11 -w $< > $@

$(FF)/strlen.ff: $(OBJS_strlen:%=$(I)/%.json) $(ASMS_strlen:%=$(I)/%.dump) ../compiler/gen/c2ff.pl ../compiler/gen/s2ff.pl
	mkdir -p $(FF)
	$(CAP) timeout 300 perl ../compiler/gen/c2ff.pl $(foreach o,$(OBJS_strlen),$(I)/$(o).json=$(I)/$(o).i) \
	    -- $(ROOTS_strlen) > $(FF)/strlen.ff.txt
	for a in $(ASMS_strlen); do \
	    $(CAP) timeout 60 perl ../compiler/gen/s2ff.pl $(I)/$$a.s $(I)/$$a.dump >> $(FF)/strlen.ff.txt || exit 1; \
	done
	perl ../compiler/gen/fftext.pl ff $(FF)/strlen.ff.txt > $@

# Each asm part, assembled by ttpc alone (with a _start after it), is the
# bytes glibc's compiler made of it, its .text without the padding at its
# end.
asm-check: $(ASMS_strlen:%=$(I)/%.dump) $(ASMS_strlen:%=$(I)/%.bin) ../compiler/gen/s2ff.pl
	mkdir -p $(FF)
	@for a in $(ASMS_strlen); do \
	    n=$$(basename $$a); \
	    { perl ../compiler/gen/s2ff.pl $(I)/$$a.s $(I)/$$a.dump && printf '_start:\n  ebreak\n'; } > $(FF)/$$n.asm.ff.txt || exit 1; \
	    perl ../compiler/gen/fftext.pl ff $(FF)/$$n.asm.ff.txt > $(FF)/$$n.asm.ff; \
	    $(CAP) timeout 60 qemu-riscv64 $(TTPC) $(SHARED) $(FF)/$$n.asm.ff $(FF)/$$n.asm > $(FF)/$$n.asm.lst || exit 1; \
	    size=$$(perl ../compiler/gen/s2ff.pl --size $(I)/$$a.s $(I)/$$a.dump) || exit 1; \
	    head -c $$size $(I)/$$a.bin > $(FF)/$$n.want; \
	    tail -c +121 $(FF)/$$n.asm | head -c $$size | cmp - $(FF)/$$n.want || exit 1; \
	    echo "asm-check: $$a: ttpc and glibc's compiler agree ($$size bytes)"; \
	done

# progs/strlen.ff imports strlen.ff from its own folder, so both go there
strlen-check: $(FF)/strlen.ff progs/strlen.ff asm-check
	cp progs/strlen.ff $(FF)/strlen-prog.ff
	$(CAP) timeout 120 qemu-riscv64 $(TTPC) $(SHARED) $(FF)/strlen-prog.ff $(FF)/strlen-prog > $(FF)/strlen-prog.lst
	s=0; $(CAP) timeout 30 qemu-riscv64 -cpu rv64,v=false $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: glibc's strlen, generic C (-cpu rv64,v=false): 12"
	s=0; $(CAP) timeout 30 qemu-riscv64 $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: with V its resolver picks glibc's vector asm: 12"

.PHONY: strlen-check asm-check
