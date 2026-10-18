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
# The same for aarch64 and x86_64 with GTARGET (below), each in a folder of
# its name: so far their long double (milestone ldouble), glibc's soft-fp
# from their own build, as gcc's programs there take it from libgcc:
#
#   make GTARGET=aarch64 glibc-ref ldouble-check
#
# Not under build/ like the rest: this repository lives in Dropbox, which
# renames files whose names differ only in case, and glibc makes stamp.os
# next to stamp.oS (and .os next to .oS objects). Its build is also large
# (some 300 MB) and nothing to sync.

# GTARGET: the target glibc is built and translated for, riscv64 (the
# default) or aarch64 and x86_64, whose long double needs glibc's soft-fp
# of their own (milestone ldouble). The other targets build next to
# riscv64's, in a folder of their name.
GTARGET ?= riscv64
TRIPLE := $(GTARGET)-unknown-linux-gnu
BUILD ?= $(HOME)/.cache/ttp/glibc$(if $(filter-out riscv64,$(GTARGET)),/$(GTARGET))
OBJ := $(BUILD)/obj
JOBS ?= $(shell nproc)

GLIBC_SRC ?= $(error GLIBC_SRC is not set: run this in `nix develop`)
GLIBC_HEADERS ?= $(error GLIBC_HEADERS is not set: run this in `nix develop`)
GLIBC_CC ?= $(error GLIBC_CC is not set: run this in `nix develop`)
ifneq ($(GTARGET),riscv64)
GLIBC_HEADERS := $(GLIBC_HEADERS_$(GTARGET))
GLIBC_CC := $(GLIBC_CC_$(GTARGET))
endif

# The target's binutils have its triple in their names, except where the
# target is the host's own (x86_64 here): there they have none.
XPRE := $(if $(shell command -v $(TRIPLE)-objdump),$(TRIPLE)-)

# The Nix ld-wrapper's hardening flags have no place in a libc's own build.
export NIX_HARDENING_ENABLE :=

# The binutils of the target, by name: the dev shell sets AR, NM, OBJCOPY,
# ... to the host's, which configure would take.
TOOLS := $(foreach t,AR:ar NM:nm OBJCOPY:objcopy OBJDUMP:objdump READELF:readelf RANLIB:ranlib STRIP:strip GPROF:gprof LD:ld,$(word 1,$(subst :, ,$(t)))=$(XPRE)$(word 2,$(subst :, ,$(t))))

.PHONY: glibc-ref clean

# A step that fails leaves nothing behind that make would take as made.
.DELETE_ON_ERROR:

glibc-ref: $(OBJ)/libc.a

$(OBJ)/config.status:
	mkdir -p $(OBJ)
	cd $(OBJ) && $(GLIBC_SRC)/configure \
	    --host=$(TRIPLE) --prefix=/usr \
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
# ttpc: on an x86_64 machine its own build for x86_64 (make bootstraps makes
# it), which runs natively (stdlib-prog: 1.6 s, against 6.1 s for riscv64's
# under qemu); elsewhere riscv64's under qemu. Both make the same bytes.
# The checks run in parallel: make -j.
ifeq ($(shell uname -m),x86_64)
TTPC ?= ../../build/compiler/x86_64/stage2
TTPC_RUN = $(TTPC) --target $(GTARGET)
else
TTPC ?= ../../build/compiler/boot/stage2
TTPC_RUN = qemu-riscv64 $(TTPC) --target $(GTARGET)
endif
SHARED := ../compiler/shared.ff

# Per target: the CPUs a check runs on (riscv64 with V and without), and
# the flags of a test program. On x86_64 long double is the x87's, so the
# programs are compiled with -mlong-double-128: binary128, as ttpc's long
# double is on every target, its arithmetic soft-fp's (__addtf3 ...).
comma := ,
CPUS_riscv64 := rv64 rv64,v=false
CPUS_aarch64 := max
CPUS_x86_64 := max
CPUS := $(CPUS_$(GTARGET))
PROGFLAGS_x86_64 := -mlong-double-128
PROGFLAGS := $(PROGFLAGS_$(GTARGET))
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

# long double, through glibc's soft-fp (on riscv64 libgcc's, the same code;
# glibc's build does not make it, mki.pl preprocesses it as libm's soft-fp
# code is): the functions ttpc's C layer calls for it, which c2ff also
# reaches from the long double in the C it translates. Its own milestone:
# progs/ldouble.c needs nothing else of glibc.
SOFTFP := addtf3 subtf3 multf3 divtf3 eqtf2 getf2 letf2 negtf2 floatditf floatunditf fixtfdi fixunstfdi \
	extendsftf2 extenddftf2 trunctfsf2 trunctfdf2
# x86_64's soft-fp raises its exceptions through a function of libm's
OBJS_ldouble_x86_64 := math/sfp-exceptions
OBJS_ldouble := $(SOFTFP:%=soft-fp/%) $(OBJS_ldouble_$(GTARGET))
ASMS_ldouble :=
ROOTS_ldouble := __addtf3 __subtf3 __multf3 __divtf3 __eqtf2 __netf2 __getf2 __gttf2 __letf2 __lttf2 __negtf2 \
	__floatditf __floatunditf __fixtfdi __fixunstfdi __extendsftf2 __extenddftf2 __trunctfsf2 __trunctfdf2

# M3, malloc: malloc, free, realloc and calloc, with M2, and qsort, which
# was waiting for them.
M3 := malloc free realloc calloc qsort
OBJS_malloc := $(OBJS_stdlib) malloc/malloc stdlib/qsort \
	io/close_nocancel_nostatus misc/getsysstats elf/enbl-secure misc/mremap io/open64_nocancel nptl/cleanup_compat \
	io/read_nocancel misc/sbrk misc/brk stdlib/strtoul stdlib/strtoul_l posix/sched_cpucount \
	string/memchr string/memchr-generic string/memmove string/memmove-generic string/strncmp string/strncmp-generic \
	elf/libc_early_init time/clock_gettime ctype/ctype-info nptl/vars csu/libc-tls misc/hugepages stdlib/getrandom \
	resource/getrlimit64 misc/single_threaded nptl/pthread_mutex_conf io/close_nocancel dirent/getdents64 nptl/nptl-stack \
	io/pread64_nocancel posix/sysconf misc/getauxval posix/get_child_max misc/getclktck misc/getdtsz misc/getpagesize \
	string/strrchr string/strrchr-generic string/strstr string/strnlen string/memrchr
ASMS_malloc := $(ASMS_stdlib) misc/madvise misc/mprotect misc/sysinfo string/memchr-vector string/memmove-vector \
	string/strncmp-vector string/strrchr-vector
ROOTS_malloc := $(ROOTS_stdlib) $(M3) __libc_early_init
# the milestones whose programs run glibc's __libc_early_init first, as its
# static startup does (malloc needs its arena set up)
EARLY := malloc stdio floats

# M4, stdio: printf without floats, puts and putchar, with M3, on stdout;
# exit (main ()) flushes it, as C's startup does (EXIT: c2ff --exit).
M4 := printf puts putchar exit
OBJS_stdio := $(OBJS_malloc) $(OBJS_ldouble) stdio-common/printf libio/ioputs libio/putchar stdlib/exit \
	libio/iofwide libio/vtables libio/genops libio/putc libio/stdio stdio-common/vfprintf-internal \
	stdio-common/printf_buffer_to_file libio/stdfiles stdio-common/funlockfile nptl/libc-cleanup iconv/gconv_db \
	stdio-common/errname stdio-common/grouping_iterator libio/fileops libio/strops libio/wgenops \
	locale/lc-numeric stdio-common/printf-parsemb stdio-common/reg-printf stdio-common/printf_buffer_done \
	stdio-common/printf_buffer_pad_1 stdio-common/printf_buffer_putc_1 stdio-common/printf_buffer_write \
	stdio-common/printf_fphex stdio-common/printf_fp stdio-common/printf_function_invoke \
	stdio-common/reg-modifier stdio-common/reg-type debug/readonly-area string/_strerror \
	stdio-common/translated_number_width wcsmbs/wcrtomb wcsmbs/wcsrtombs intl/dcgettext elf/dl-readonly-area \
	stdio-common/errlist locale/SYS_libc stdio-common/printf_buffer_flush debug/readonly-area-fallback \
	stdio-common/snprintf debug/chk_fail intl/dcigettext elf/dl-find_object libio/iogetdelim libio/iofclose \
	libio/iofopen stdio-common/printf_buffer_puts_1 libio/vsnprintf wcsmbs/wcslen wcsmbs/wcsnlen \
	stdio-common/asprintf locale/localename elf/dl-addr-obj debug/fortify_fail stdlib/fpioconst io/fstat64 \
	iconv/gconv iconv/gconv_charset iconv/gconv_conf iconv/gconv_cache iconv/gconv_open iconv/gconv_dl io/getcwd \
	stdlib/getenv nss/hash-string libio/wfileops nptl/alloca_cutoff malloc/scratch_buffer_grow_preserve \
	malloc/scratch_buffer_set_array_size locale/setlocale io/lseek64 stdlib/cmp stdlib/divrem stdlib/dbl2mpn \
	stdlib/ldbl2mpn stdlib/lshift stdlib/mul stdlib/mul_1 stdlib/rshift intl/finddomain intl/loadmsgcat \
	stdio-common/printf_buffer_as_file nptl/pthread_rwlock_rdlock nptl/pthread_rwlock_unlock io/read \
	string/stpcpy string/strcpy string/strcspn string/strdup misc/tsearch wcsmbs/wmemchr wcsmbs/wmemcpy \
	wcsmbs/wmemmove wcsmbs/wmempcpy stdio-common/wprintf_buffer_putc_1 io/write io/write_nocancel stdlib/addmul_1 \
	stdlib/add_n stdlib/mul_n intl/localealias intl/explodename intl/l10nflist dirent/closedir posix/environ \
	stdlib/cxa_atexit dirent/fdopendir libio/iofgets_u io/fstatat64 iconv/gconv_builtin intl/plural-exp \
	elf/dl-libc io/lstat64 stdlib/submul_1 stdlib/sub_n io/open64 io/openat64 dirent/opendir nptl/pthread_once \
	nptl/pthread_rwlock_init dirent/readdir64 dirent/rewinddir io/stat64 string/strcasecmp_l \
	string/strcpy-generic string/strtok_r libio/vasprintf stdio-common/wprintf_buffer_flush io/fcntl_nocancel \
	intl/plural libio/iogetline elf/dl-catch elf/dl-close elf/dl-exception elf/dl-lookup elf/dl-open \
	csu/init-first string/strspn stdio-common/wprintf_buffer_to_file nptl/pthread_mutex_lock \
	nptl/pthread_mutex_unlock elf/dl-call_fini elf/dl-debug elf/dl-printf elf/dl-load elf/dl-scope \
	elf/dl-sort-maps elf/dl-thread_gscope_wait elf/dl-debug_state elf/dl-misc misc/init-misc nptl/tpp \
	elf/dl-object elf/dl-tls elf/dl-call-libc-early-init elf/dl-origin elf/dl-version elf/dl-init elf/dl-cache \
	elf/dl-deps elf/dl-reloc elf/dl-lookup-direct elf/dl-execstack elf/dl-scratch-buffer elf/dl-setup_hash \
	elf/dl-map-segment-align misc/fd_to_filename string/strsep stdio-common/errlist-data elf/rtld_static_init \
	dlfcn/dladdr dlfcn/dladdr1 dlfcn/dlclose dlfcn/dlerror dlfcn/dlinfo dlfcn/dlmopen dlfcn/dlsym dlfcn/dlvsym \
	elf/dl-addr elf/dl-sym dlfcn/libc_dlerror_result elf/dl-runtime setjmp/sigjmp signal/sigprocmask nptl/pthread_sigmask \
	dlfcn/dlopen libio/filedoalloc libio/wfiledoalloc locale/C-address locale/C-collate locale/C-identification locale/C-measurement locale/C-messages locale/C-monetary locale/C-name locale/C-numeric locale/C-paper locale/C-telephone locale/C-time termios/isatty_nostatus
ASMS_stdio := $(ASMS_malloc) setjmp/setjmp setjmp/__longjmp posix/sched_getp posix/sched_primax posix/sched_primin posix/sched_gets posix/sched_sets elf/dl-trampoline
ROOTS_stdio := $(ROOTS_malloc) $(M4)
EXIT := stdio floats
# objects glibc's asm only reserves, zeroed in .bss, that C reaches: c2ff --zero
# makes each a global of the type C declares (elf/dl-debug-symbols.S)
ZEROS_stdio := _r_debug_extended
# names nothing defines for a static program, weak (address 0) by c2ff --weak:
# the linker's bounds of .init_array and .preinit_array, which a ttpc program
# has none of (so they are empty), and dl-trampoline's _dl_runtime_profile,
# which the shared build has; gcc's optimizer left no call of it here
WEAKS_stdio := __init_array_start __init_array_end __preinit_array_start __preinit_array_end _dl_runtime_profile

# M4, floats: printf of double and long double (printf_fp, printf_fphex),
# which the stdio reach has already, and the soft-fp the program calls for
# its own long double
OBJS_floats := $(OBJS_stdio)
ASMS_floats := $(ASMS_stdio)
ROOTS_floats := $(ROOTS_stdio) $(ROOTS_ldouble)
ZEROS_floats := $(ZEROS_stdio)
WEAKS_floats := $(WEAKS_stdio)

MILESTONES := string stdlib ldouble malloc stdio floats

.PRECIOUS: $(I)/%.i $(I)/%.json $(I)/%.s $(I)/%.dump $(I)/%.bin $(FF)/%-prog.ff $(FF)/%.rt.c $(FF)/%.rt.names $(FF)/%/index.ff

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
	$(XPRE)objdump -d -M no-aliases $(I)/$*.ref.o > $(I)/$*.dump
	$(XPRE)objcopy -O binary -j .text $(I)/$*.ref.o $(I)/$*.bin

# What clang does not read of gcc's C, rewritten for clang alone in a copy of
# the .i, each to as many bytes (c2ff finds an asm statement's text in the
# .i itself by the offsets in clang's AST). x86_64: gcc's %v in an asm
# template (v under AVX, nothing here: glibc is not built for AVX) and the
# mode __libgcc_cmp_return__ (8 bytes there, as gcc says: DI).
CLANGFIX_x86_64 := sed -e 's/"%v"/""  /g' -e 's/mode (__libgcc_cmp_return__)/mode (__DI__               )/g'
CLANGFIX := $(CLANGFIX_$(GTARGET))

$(I)/%.json: $(I)/%.i clang-prelude.h
	$(if $(CLANGFIX),$(CLANGFIX) $< > $(I)/$*.clang.i)
	$(CAP) timeout 300 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=$(GTARGET)-linux-gnu $(PROGFLAGS) -std=gnu11 -fgnu89-inline -w $(if $(CLANGFIX),$(I)/$*.clang.i,$<) > $@

# A milestone's ff: c2ff's from its objects' ASTs, from its roots (and what
# its asm parts name from elsewhere: setjmp's tail __sigjmp_save), then
# s2ff's of its asm parts, then the builtins written by hand and libatomic's
# functions (atomics.ff.txt, from mkatomics.pl: perl mkatomics.pl >
# atomics.ff.txt). The asm parts share one page, glibc asm: the trees a
# program reads have 255 pages in all (c2ff makes a page per directory).
define milestone
$$(FF)/$(1).ff: $$(OBJS_$(1):%=$$(I)/%.json) $$(ASMS_$(1):%=$$(I)/%.dump) builtins.ff.txt $$(wildcard builtins-$$(GTARGET).ff.txt) atomics.ff.txt ../compiler/gen/c2ff.pl ../compiler/gen/s2ff.pl
	mkdir -p $$(FF)
	$$(CAP) timeout 300 perl ../compiler/gen/c2ff.pl --target $$(GTARGET) $$(foreach z,$$(ZEROS_$(1)),--zero $$(z)) $$(foreach w,$$(WEAKS_$(1)),--weak $$(w)) $$(foreach o,$$(OBJS_$(1)),$$(I)/$$(o).json=$$(I)/$$(o).i) \
	    -- $$(ROOTS_$(1)) $$$$(for a in $$(ASMS_$(1)); do $(XPRE)objdump -t $$(I)/$$$$a.ref.o | awk '/\*UND\*/ { print $$$$NF }'; done | sort -u) > $$(FF)/$(1).ff.txt
	$$(if $$(ASMS_$(1)),echo 'glibc asm:' >> $$(FF)/$(1).ff.txt)
	for a in $$(ASMS_$(1)); do \
	    $$(CAP) timeout 60 perl ../compiler/gen/s2ff.pl --items $$(I)/$$$$a.s $$(I)/$$$$a.dump > $$(FF)/$(1).asm.txt || exit 1; \
	    sed 's/^/  /' $$(FF)/$(1).asm.txt >> $$(FF)/$(1).ff.txt; \
	done
	cat builtins.ff.txt $$(wildcard builtins-$$(GTARGET).ff.txt) atomics.ff.txt >> $$(FF)/$(1).ff.txt
	perl ../compiler/gen/fftext.pl ff $$(FF)/$(1).ff.txt > $$@
endef
$(foreach m,$(MILESTONES),$(eval $(call milestone,$(m))))

# Each asm part, assembled by ttpc alone (with a _start after it), is the
# bytes glibc's compiler made of it, its .text without the padding at its
# end; the fields relocations fill in (relmask.pl) are the linker's, not
# compared, and what it names from elsewhere is a stand-in label after it.
asm-check: $(ASMS_stdio:%=$(I)/%.dump) $(ASMS_stdio:%=$(I)/%.bin) ../compiler/gen/s2ff.pl
	mkdir -p $(FF)
	@for a in $(ASMS_stdio); do \
	    n=$$(basename $$a); \
	    { perl ../compiler/gen/s2ff.pl $(I)/$$a.s $(I)/$$a.dump && printf '_start:\n  ebreak\n' && \
	      $(XPRE)objdump -t $(I)/$$a.ref.o | awk '/\*UND\*/ { printf "%s:\n  ebreak\n", $$NF }'; } > $(FF)/$$n.asm.ff.txt || exit 1; \
	    perl ../compiler/gen/fftext.pl ff $(FF)/$$n.asm.ff.txt > $(FF)/$$n.asm.ff; \
	    $(CAP) timeout 60 $(TTPC_RUN) $(SHARED) $(FF)/$$n.asm.ff $(FF)/$$n.asm > $(FF)/$$n.asm.lst || exit 1; \
	    size=$$(perl ../compiler/gen/s2ff.pl --size $(I)/$$a.s $(I)/$$a.dump) || exit 1; \
	    $(XPRE)objdump -r $(I)/$$a.ref.o > $(FF)/$$n.relocs; \
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
	$(CAP) timeout 120 $(TTPC_RUN) $(SHARED) $(FF)/strlen-prog.ff $(FF)/strlen-prog > $(FF)/strlen-prog.lst
	s=0; $(CAP) timeout 30 qemu-riscv64 -cpu rv64,v=false $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: glibc's strlen, generic C (-cpu rv64,v=false): 12"
	s=0; $(CAP) timeout 30 qemu-riscv64 $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: with V its resolver picks glibc's vector asm: 12"

# A test program in C, progs/NAME.c, built two ways: with gcc against
# libc.a (glibc's own startup, no builtins: each call reaches glibc), and
# through c2ff --program, with ttpc against the milestone of that name
# (each takes in the ones before it), imported as the folder NAME (the
# files of what the program reaches, read lazily). Both run with V and without; all
# four must exit with the status on the first line of progs/NAME.expect
# ("exit N") and print the rest of it.
CRTBEGIN = $(shell $(GLIBC_CC) -print-file-name=crtbeginT.o)
CRTEND = $(shell $(GLIBC_CC) -print-file-name=crtend.o)

$(FF)/%.ref: progs/%.c $(OBJ)/libc.a
	mkdir -p $(FF)
	$(CAP) timeout 120 $(GLIBC_CC) -O2 -fno-builtin $(PROGFLAGS) -c $< -o $(FF)/$*.ref.o
	$(CAP) timeout 120 $(GLIBC_CC) -static -nostdlib -o $@ $(OBJ)/csu/crt1.o $(OBJ)/csu/crti.o $(CRTBEGIN) \
	    $(FF)/$*.ref.o -Wl,--start-group $(OBJ)/libc.a -lgcc -lgcc_eh -Wl,--end-group $(CRTEND) $(OBJ)/csu/crtn.o

# A milestone as a folder that a program imports lazily (ffsplit.pl): a file
# per page and index.ff, the file of each name; ttpc reads only the files
# of what the program reaches.
$(FF)/%/index.ff: $(FF)/%.ff ../compiler/gen/ffsplit.pl
	rm -rf $(FF)/$*
	$(CAP) timeout 120 perl ../compiler/gen/ffsplit.pl $(FF)/$*.ff.txt $(FF)/$*

$(FF)/%-prog.ff: progs/%.c clang-prelude.h ../compiler/gen/c2ff.pl
	mkdir -p $(FF)
	$(CAP) timeout 60 $(GLIBC_CC) -E -P $(PROGFLAGS) $< -o $(FF)/$*-prog.i
	$(CAP) timeout 120 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=$(GTARGET)-linux-gnu $(PROGFLAGS) -std=gnu11 -w $(FF)/$*-prog.i > $(FF)/$*-prog.json
	$(CAP) timeout 120 perl ../compiler/gen/c2ff.pl --target $(GTARGET) --program $* $(if $(filter $*,$(EARLY)),--early) $(if $(filter $*,$(EXIT)),--exit) $(FF)/$*-prog.json=$(FF)/$*-prog.i -- main > $(FF)/$*-prog.ff.txt
	perl ../compiler/gen/fftext.pl ff $(FF)/$*-prog.ff.txt > $@

$(FF)/%-prog: $(FF)/%-prog.ff $(FF)/%/index.ff $(TTPC)
	$(CAP) timeout 900 $(TTPC_RUN) $(SHARED) $< $@ > $@.lst

# what a check expects: progs/NAME.expect, or progs/NAME.<target>.expect
# where the target's glibc differs (soft-fp's NaNs: riscv64 makes them
# canonical, aarch64 and x86_64 keep a NaN's payload, x86_64's sign is 1)
expect = $(firstword $(wildcard progs/$(1).$(GTARGET).expect) progs/$(1).expect)

define check
$(1)-check: $$(FF)/$(1).ref $$(FF)/$(1)-prog $$(call expect,$(1)) $(if $(filter riscv64,$(GTARGET)),asm-check)
	@want=$$$$(head -n 1 $$(call expect,$(1)) | cut -d" " -f2); \
	tail -n +2 $$(call expect,$(1)) > $$(FF)/$(1).want; \
	for b in $(1).ref $(1)-prog; do \
	    for cpu in $$(CPUS); do \
	        s=0; $$(CAP) timeout 60 qemu-$$(GTARGET) -cpu $$$$cpu $$(FF)/$$$$b > $$(FF)/$$$$b.out || s=$$$$?; \
	        test $$$$s -eq $$$$want || { echo "$(1)-check: $$$$b on $$$$cpu: exit status $$$$s, not $$$$want"; exit 1; }; \
	        cmp -s $$(FF)/$$$$b.out $$(FF)/$(1).want || { echo "$(1)-check: $$$$b on $$$$cpu: wrong output"; diff $$(FF)/$$$$b.out $$(FF)/$(1).want | head; exit 1; }; \
	    done; \
	done; \
	echo "$(1)-check: gcc + libc.a and ttpc + glibc in ff agree$(comma)$(if $(filter riscv64,$(GTARGET)), with V and without, on $(GTARGET)): exit $$$$want"
.PHONY: $(1)-check
endef
$(foreach m,$(MILESTONES),$(eval $(call check,$(m))))

# The round trip, the other proof of "exact": the C functions of a milestone,
# written back as C from its ff (ff2c.pl, which reads ff as ttpc does), have
# the AST of glibc's own, each against its .i's (roundtrip.pl). The
# addresses of asm functions, which have no C type in ff, are let through.
$(FF)/%.rt.c $(FF)/%.rt.names &: $(FF)/%.ff ../compiler/gen/ff2c.pl
	$(CAP) timeout 300 perl ../compiler/gen/ff2c.pl $(FF)/$*.ff.txt $(FF)/$*.rt.c $(FF)/$*.rt.names

$(FF)/%.rt.json: $(FF)/%.rt.c
	$(CAP) timeout 600 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json -fsyntax-only --target=$(GTARGET)-linux-gnu $(PROGFLAGS) -std=gnu11 -w \
	    -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion $< > $@

define roundtrip
$(1)-roundtrip: $$(FF)/$(1).rt.json $$(FF)/$(1).rt.names roundtrip.pl
	$$(CAP) timeout 900 perl roundtrip.pl $$(FF)/$(1).rt.names $$(FF)/$(1).rt.json $$(OBJS_$(1):%=$$(I)/%.json)
.PHONY: $(1)-roundtrip
endef
$(foreach m,$(MILESTONES),$(eval $(call roundtrip,$(m))))
glibc-roundtrip: floats-roundtrip

.PHONY: strlen-check asm-check glibc-roundtrip
