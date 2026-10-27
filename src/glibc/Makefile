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
#   make glibc-ref     configure and build  -> ~/.cache/ttp/glibc-gcc16/obj
#
# The folder is named for the compiler: build.log holds its store path,
# which mki.pl runs again, so a build lives only as long as that gcc. The
# flake pins gcc 16 (gcc16, not nixpkgs' default gcc), and glibc-ref makes
# the build's own nix gc roots for its compiler, the kernel's headers and
# the source (BUILD/gcroots). When the flake moves to another gcc, the
# reference is built again in a folder of its name (and mki.pl says so
# when build.log's compiler is gone). ~/.cache/ttp/glibc is the build of
# gcc 15.2 (2026-10-16), whose compiler nix gc took.
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
# libatomic's functions: the target's real ones where it has them (mkatomics.pl)
ATOMICS = $(firstword $(wildcard atomics-$(GTARGET).ff.txt) atomics.ff.txt)
# arm is 32-bit armv7-a with hard-float EABI: gcc's triple and clang's
# target say so (clang's arm-linux-gnu alone would be soft-float armv4t)
TRIPLE_arm := armv7l-unknown-linux-gnueabihf
TRIPLE := $(or $(TRIPLE_$(GTARGET)),$(GTARGET)-unknown-linux-gnu)
CTARGET_arm := armv7a-linux-gnueabihf -mfloat-abi=hard -mfpu=vfpv3-d16
CTARGET := $(or $(CTARGET_$(GTARGET)),$(GTARGET)-linux-gnu)
BUILD ?= $(HOME)/.cache/ttp/glibc-gcc16$(if $(filter-out riscv64,$(GTARGET)),/$(GTARGET))
OBJ := $(BUILD)/obj
# a make that calls itself without end stops here (MAKELEVEL counts the
# makes above this one; glibc's own, deeper, never read this file)
ifneq ($(filter-out 0 1 2 3 4 5 6 7 8,$(or $(MAKELEVEL),0)),)
$(error make nested $(MAKELEVEL) deep: does a rule call make without end?)
endif
# glibc builds at most 4 at once: with the slots, nproc (12) per build froze
# the machine once (2026-10-20); the cgroup caps in slot.sh bound the rest
JOBS ?= 4

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

.PHONY: glibc-ref build-gcroots clean

# A step that fails leaves nothing behind that make would take as made.
.DELETE_ON_ERROR:

glibc-ref: $(OBJ)/libc.a build-gcroots

# The build's own nix gc roots, BUILD/gcroots/{CC,HEADERS,SRC}: what its
# build.log names by store path, alive as long as the build is (also for an
# obj/ linked from another build of the same compiler).
build-gcroots:
	mkdir -p $(BUILD)/gcroots
	for p in CC:$(GLIBC_CC) HEADERS:$(GLIBC_HEADERS) SRC:$(GLIBC_SRC); do \
	    nix build --out-link $(BUILD)/gcroots/$${p%%:*} $$(echo $${p#*:} | cut -d/ -f1-4) || exit 1; \
	done

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
# (and on x86_64 the forms GNU as picks, for glibc's asm: x86_64gnu.ff)
SHARED := ../compiler/shared.ff $(if $(filter x86_64,$(GTARGET)),../compiler/x86_64gnu.ff)

# Per target: the CPUs a check runs on (riscv64 with V and without), and
# the flags of a test program. On x86_64 long double is the x87's, so the
# programs are compiled with -mlong-double-128: binary128, as ttpc's long
# double is on every target, its arithmetic soft-fp's (__addtf3 ...).
comma := ,
CPUS_riscv64 := rv64 rv64,v=false
# aarch64: SVE and MOPS (max), the same without SVE, none of them
# (cortex-a57), and SVE at 512 and 256 bits (a64fx, neoverse-v1), whose
# ifuncs pick glibc's other string asm (memcpy_a64fx, memcpy_sve ...)
CPUS_aarch64 := max max,sve=off cortex-a57 a64fx neoverse-v1
# x86_64: AVX2 (max), SSE4.2 and no AVX (Nehalem), SSE2 alone (qemu64),
# whose ifuncs pick glibc's avx2, sse4_2 and sse2 asm (qemu's TCG has no
# AVX-512: the evex asm is checked by asm-check alone)
CPUS_x86_64 := max Nehalem qemu64
# arm: armv7-a with NEON and VFPv4 at their newest (max) and a Cortex-A15
CPUS_arm := max cortex-a15
CPUS := $(CPUS_$(GTARGET))
PROGFLAGS_x86_64 := -mlong-double-128
PROGFLAGS := $(PROGFLAGS_$(GTARGET))
# Every heavy step (mki.pl, clang, c2ff, gcc, ttpc, qemu) runs as RUN -t
# SECONDS command: in one of the machine's shared slots (slot.sh), under a
# memory cap and a timeout. A make run in a slot already (TTP_SLOT set) takes
# no second one; one outside them (make -j) runs a step wherever a slot is
# free, so as many at once as there are free slots.
# qemu-arm reserves the 32-bit address space (guest_base): 8 GB there
CAPKB_arm := 8000000
CAPKB := $(or $(CAPKB_$(GTARGET)),4000000)
RUN := sh ../compiler/gen/slot.sh -v $(CAPKB)

# M1, string: strlen, memcpy, memset, strcmp and strchr, each its ifunc, its
# generic C and its asm (vector; memcpy also for fast misaligned access),
# and glibc's __riscv_hwprobe (which the init routine hands the resolvers,
# as glibc's own startup does)
M1 := strlen memcpy memset strcmp strchr
OBJS_string := $(foreach f,$(M1),string/$(f) string/$(f)-generic) string/wordcopy string/strchrnul misc/hwprobe elf/dl-support
ASMS_string := $(M1:%=string/%-vector) string/memcpy_noalignment
ROOTS_string := $(M1) $(ROOTS_string_$(GTARGET))
ROOTS_string_riscv64 := __riscv_hwprobe

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
# (arm's long double is double, by its EABI: no soft-fp)
OBJS_ldouble := $(if $(filter arm,$(GTARGET)),,$(SOFTFP:%=soft-fp/%)) $(OBJS_ldouble_$(GTARGET))
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

# M4, stdio: printf without floats, puts and putchar, with M3, on stdout;
# exit (main ()) flushes it, as C's startup does.
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
# its own long double (on x86_64 also strfromf128, glibc's printf_fp of
# binary128: progs/floats.c)
OBJS_floats := $(OBJS_stdio)
ASMS_floats := $(ASMS_stdio)
ROOTS_floats_x86_64 := strfromf128
ROOTS_floats := $(ROOTS_stdio) $(ROOTS_ldouble) $(ROOTS_floats_$(GTARGET))
ZEROS_floats := $(ZEROS_stdio)
WEAKS_floats := $(WEAKS_stdio)

# args: a program of argc, argv and an environment variable, through
# glibc's startup (below), with what stdio has
OBJS_args := $(OBJS_stdio)
ASMS_args := $(ASMS_stdio)
ROOTS_args := $(ROOTS_stdio) getenv
ZEROS_args := $(ZEROS_stdio)
WEAKS_args := $(WEAKS_stdio)
RUN_args := one two three
RUNENV_args := FF_ARGS=hello

# gnuc: gcc's builtins and the GNU C forms beyond the other milestones
# (progs/gnuc.c: float classification and quiet comparisons, fabs,
# copysign, inf, nan, fma, sqrt, the overflow builtins, a pointer to an
# array, and riscv64's asm statements with "f" and "i" operands), with
# long double's soft-fp
OBJS_gnuc := $(OBJS_ldouble)
CFLAGS_gnuc := -fno-math-errno
ASMS_gnuc :=
# (x86_64's __builtin_fma and __builtin_fmaf call libm's fma and fmaf, as
# gcc does: builtins-x86_64.ff.txt)
ROOTS_gnuc_x86_64 := fma fmaf
ROOTS_gnuc := $(ROOTS_ldouble) $(ROOTS_gnuc_$(GTARGET))

# unwind: libgcc's own unwinder in ff (src/libgcc: libgcc_eh's unwind-dw2.c,
# unwind-dw2-fde-dip.c and unwind-c.c, translated as glibc's units are,
# $(I)/libgcc), linked as gcc links libgcc_eh.a into a static program, with
# glibc's dl_iterate_phdr, which finds the program's .eh_frame_hdr
# (PT_GNU_EH_FRAME): progs/unwind.c's _Unwind_Backtrace and
# _Unwind_ForcedUnwind walk its frames, ttpc's with -g (.eh_frame), as gcc's
# libgcc walks gcc's. Its tree has libgcc's license too (license-libgcc.ff.txt).
LIBGCC_EH := unwind-dw2 unwind-dw2-fde-dip unwind-c
OBJS_unwind := elf/dl-iteratephdr $(LIBGCC_EH:%=libgcc/%)
ASMS_unwind :=
ROOTS_unwind := $(ROOTS_stdio) _Unwind_Backtrace _Unwind_ForcedUnwind _Unwind_GetIP _Unwind_GetCFA _Unwind_FindEnclosingFunction _setjmp longjmp
ZEROS_unwind := $(ZEROS_stdio)
WEAKS_unwind := $(WEAKS_stdio)
LICENSE_unwind := license-libgcc.ff.txt
TTPCFLAGS_unwind := -g

# gccrt: libgcc's own functions in ff (src/libgcc, as unwind's), called by
# name (progs/gccrt.c): complex multiply and divide, the integer helpers,
# the powers to an int and soft-fp's conversions, each result's bits
# printed, as gcc's libgcc.a gives them.
OBJS_gccrt := $(addprefix libgcc/,_muldc3 _divdc3 _mulsc3 _divsc3 _multc3 _divtc3 _popcountsi2 _popcount_tab _clzsi2 _clz _ctzsi2 \
	_ffssi2 _paritysi2 _clrsbsi2 _bswapsi2 _bswapdi2 _absvsi2 _addvsi3 _subvsi3 _mulvsi3 _powidf2 _powisf2 _powitf2 \
	_fixunsdfsi _fixunssfsi floatsitf floatunsitf fixtfsi fixunstfsi unordtf2 divdf3 divsf3 __gcc_bcmp)
ASMS_gccrt :=
ROOTS_gccrt := $(ROOTS_stdio) __mulsc3 __divsc3 __muldc3 __divdc3 __multc3 __divtc3 __popcountdi2 __clzdi2 __ctzdi2 __ffsdi2 \
	__paritydi2 __clrsbdi2 __bswapsi2 __bswapdi2 __absvsi2 __absvdi2 __addvsi3 __addvdi3 __subvdi3 __mulvsi3 __powidf2 \
	__powisf2 __powitf2 __fixunsdfdi __fixunssfdi __floatsitf __floatunsitf __fixtfsi __fixunstfsi __unordtf2 __divdf3 __divsf3 \
	__gcc_bcmp $(ROOTS_ldouble)
ZEROS_gccrt := $(ZEROS_stdio)
WEAKS_gccrt := $(WEAKS_stdio)
LICENSE_gccrt := license-libgcc.ff.txt

MILESTONES := string stdlib ldouble malloc stdio floats args gnuc unwind gccrt

# glibc's own startup, on riscv64, for the program of every milestone:
# start.S's _start (crt1.o's, with csu/static-reloc and csu/init) calls
# __libc_start_main, which sets up the auxv, tunables, TLS, stdio and
# atexit, runs main (argc, argv, envp) and exits with exit (), which runs
# the atexit functions and flushes stdio. So each milestone has stdio's
# objects too, and these, from its root _start. Of the linker's own names,
# ttpc's frame has __global_pointer$ and ttpc's IRELATIVE table
# __rela_iplt_start and __rela_iplt_end; weak (address 0) are the bounds of
# .fini_array, which a ttpc program has none of, __ehdr_start, which glibc
# reads only when the kernel gives no AT_PHDR (Linux always does), and
# _startup_fatal_not_constant, a name glibc leaves undefined on purpose
# (gcc's optimizer keeps no call of it). dl-rseq-symbols.S's two objects
# are zero (c2ff --zero), their other names aliases (s2ff). Another target
# has no startup in ff yet: its programs have a _start of their own (c2ff
# --start).
GLIBC_START := $(filter riscv64 aarch64 x86_64 arm,$(GTARGET))
# (on x86_64 and arm for their milestones of LINKED_x86_64 and LINKED_arm)
startms = $(if $(GLIBC_START),$(if $(filter x86_64 arm,$(GTARGET)),$(filter $(1),$(LINKED_$(GTARGET))),1))
OBJS_start := csu/static-reloc csu/init csu/check_fds elf/dl-early_allocate nptl/nptl_deallocate_tsd nptl/nptl_nthreads \
	elf/dl-tls_init_tp stdlib/setenv elf/dl-execstack-tunable nptl/pthread_keys
ASMS_start := csu/start elf/dl-rseq-symbols
ROOTS_start := _start
ZEROS_start := __rseq_size __rseq_offset
WEAKS_start := __fini_array_start __fini_array_end _startup_fatal_not_constant __ehdr_start
# a milestone's own, then (riscv64) stdio's and the startup's, each once in
# its first place
uniq = $(strip $(if $(1),$(firstword $(1)) $(call uniq,$(filter-out $(firstword $(1)),$(1)))))
with_start = $(call uniq,$($(1)_$(2)) $(if $(call startms,$(2)),$($(1)_stdio) $($(1)_start)))

# aarch64: a milestone's objects are those its program's gcc build links
# (linkobjs.pl, from the link map of NAME.ref: the members of libc.a gcc's
# static program has), with crt1.o's C (static-reloc, init), start.S and
# crti.S (crtn.S ends crti's _init and _fini: s2ff-aarch64.pl --then), and
# glibc's soft-fp (ldouble's: gcc's program takes long double's arithmetic
# from libgcc). c2ff translates what the roots reach of them.
# (each C object's AST is c2ff's pass of it, all-units', not its JSON)
UNITDEP_aarch64 := c2ff
UNITDEP_x86_64 := c2ff
UNITDEP_arm := c2ff
UNITDEP := $(or $(UNITDEP_$(GTARGET)),json)
LINKED_aarch64 := string stdlib ldouble malloc stdio floats args
# (x86_64 the same way: start.S, crti.S and crtn.S through s2ff, as aarch64's)
LINKED_x86_64 := string stdlib ldouble malloc stdio floats args gnuc
# (arm the same way: start.S, crti.S and crtn.S through s2ff-arm, as aarch64's)
LINKED_arm := string stdlib ldouble malloc stdio floats args
LINKED := $(LINKED_$(GTARGET))
# and the C objects c2ff reaches that gcc's optimizer left no call of
# (ctype_l's __toupper_l, abs, putc; check_fds, which riscv64's startup has too)
OBJS_crt := $(OBJS_start) ctype/ctype_l stdlib/abs libio/putc
ASMS_crt := csu/start csu/crti
ifneq ($(LINKED),)
-include $(LINKED:%=$(FF)/%.objs.mk)
endif
# (elf/dl-debug-symbols.S only reserves _r_debug_extended, c2ff --zero's,
# with _r_debug an alias of it: left out, as on riscv64)
ASMS_skip := elf/dl-debug-symbols
objs_of = $(if $(filter $(2),$(LINKED)),$(filter-out $(ASMS_skip) $(OBJS_skip_$(GTARGET)),$(call uniq,$($(1)_link_$(2)) $($(1)_crt) $(if $(filter OBJS,$(1)),$(OBJS_ldouble)))),$(call with_start,$(1),$(2)))

.PRECIOUS: $(FF)/%.map $(FF)/%.objs.mk $(I)/%.i $(I)/%.json $(I)/%.c2ff $(I)/%.one $(I)/%.s $(I)/%.Ls $(I)/%.dump $(I)/%.bin $(FF)/%-prog.ff $(FF)/%.rt.c $(FF)/%.rt.names $(FF)/%/index.ff

$(I)/%.i: $(OBJ)/libc.a mki.pl
	$(RUN) -t 120 perl mki.pl $(OBJ) $(GLIBC_SRC) $*.o > /dev/null

# An object of a .S: its .s (mki.pl again), and what glibc's compiler makes
# of it without relaxation, as instructions (for s2ff.pl, which takes the
# compressed ones GNU as picked) and as the bytes of its .text, which ttpc
# must make too. Per target: riscv64's relaxation off and its
# instructions without aliases; x86_64's each on one line (-w), its bytes
# with it, which s2ff reads the encoding GNU as picked from.
ASREF_riscv64 := -mno-relax
DUMPOPT_riscv64 := -M no-aliases
DUMPOPT_x86_64 := -w
# (arm's with its symbols and relocations: the literal pools' words)
DUMPOPT_arm := -r -t
$(I)/%.s: $(OBJ)/libc.a mki.pl
	$(RUN) -t 120 perl mki.pl $(OBJ) $(GLIBC_SRC) $*.o > /dev/null

#
# aarch64 (s2ff-aarch64.pl): the instructions are read from the object
# alone, as GNU as made them (its macros, aliases, .inst words), and its
# labels from the symbol table: the .s with its numeric labels named
# (.Ls, s2ff-aarch64.pl --locals) is assembled with -L, which keeps local
# labels, and dumped with its relocations and symbols. Its .text is the
# same bytes as glibc's own object's (asm-check compares them too).
S2FF_riscv64 := ../compiler/gen/s2ff.pl
S2FF_aarch64 := ../compiler/gen/s2ff-aarch64.pl
S2FF_arm := ../compiler/gen/s2ff-arm.pl
S2FF := $(or $(S2FF_$(GTARGET)),../compiler/gen/s2ff.pl)
# the file s2ff reads: riscv64 the .s itself, aarch64 the .Ls (not .L.s:
# that would be an .s of an object x.L, which mki.pl would be asked for)
SSRC_riscv64 := .s
SSRC_aarch64 := .Ls
SSRC := $(or $(SSRC_$(GTARGET)),.s)
ASREF_aarch64 := -Wa,-L
DUMPOPT_aarch64 := -r -t -M no-aliases

$(I)/%.Ls: $(I)/%.s $(S2FF_aarch64)
	perl $(S2FF_aarch64) --locals $< > $@

$(I)/%.dump $(I)/%.bin: $(I)/%$(SSRC)
	$(RUN) -t 60 $(GLIBC_CC) -c $(ASREF_$(GTARGET)) -x assembler $< -o $(I)/$*.ref.o
	$(XPRE)objdump -d $(DUMPOPT_$(GTARGET)) $(I)/$*.ref.o > $(I)/$*.dump
	$(XPRE)objcopy -O binary -j $(call codesec,$(I)/$*.ref.o) $(I)/$*.ref.o $(I)/$*.bin

# the section of an object's code: .text, but on x86_64 the one it has
# (glibc's multiarch asm is in .text.avx2, .text.evex ...: one an object)
codesec = $(if $(filter x86_64,$(GTARGET)),$$($(XPRE)objdump -h $(1) | awk '$$2 ~ /^\.text/ && $$3 !~ /^0+$$/ { s = $$2 } END { print s ? s : ".text" }'),.text)

# What clang does not read of gcc's C, rewritten for clang alone in a copy of
# the .i, each to as many bytes (c2ff finds an asm statement's text in the
# .i itself by the offsets in clang's AST). x86_64: gcc's %v in an asm
# template (v under AVX, nothing here: glibc is not built for AVX) and the
# mode __libgcc_cmp_return__ (8 bytes there, as gcc says: DI); the f128 or
# F128 suffix of a _Float128 literal (after a digit, or a digit and a
# point: u.f128 is a field), which clang lacks (L: binary128 here
# too); and gcc's _FloatN as associations of a _Generic, besides float,
# double and long double, which for clang are those again (clang-prelude.h):
# other types there, which no float matches.
CLANGFIX_x86_64 := sed -e 's/"%v"/""  /g' -e 's/mode (__libgcc_cmp_return__)/mode (__DI__               )/g' \
	-e 's/\([0-9]\.\?\)[fF]128\b/\1L   /g' -e 's/_Float32:/short   :/g' -e 's/_Float64:/char    :/g' \
	-e 's/_Float32x:/_Bool    :/g' -e 's/_Float64x:/unsigned :/g'
CLANGFIX := $(CLANGFIX_$(GTARGET))
# (x86_64's units of gcc's SSE4.2 intrinsics, <nmmintrin.h>: clang reads
# them with -msse4.2, gcc's inline functions they do not reach left out of
# its copy, clangvec.pl)
CLANGVEC_x86_64 := string/strcspn-sse4 string/strspn-sse4
CLANGVEC := $(CLANGVEC_$(GTARGET))
vecfix = $(if $(filter $(1),$(CLANGVEC)),| perl clangvec.pl)
vecflag = $(if $(filter $(1),$(CLANGVEC)),-msse4.2)

$(I)/%.json: $(I)/%.i clang-prelude.h
	$(if $(CLANGFIX),$(CLANGFIX) $< $(call vecfix,$*) > $(I)/$*.clang.i)
	$(RUN) -t 300 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=$(CTARGET) $(PROGFLAGS) $(call vecflag,$*) -std=gnu11 -fgnu89-inline -w $(if $(CLANGFIX),$(I)/$*.clang.i,$<) > $@

# A milestone's ff: c2ff's from its objects' ASTs, from its roots (and what
# its asm parts name from elsewhere: setjmp's tail __sigjmp_save), then
# s2ff's of its asm parts, then the builtins written by hand, C23's bit
# functions (stdbit.ff.txt, from mkstdbit.pl: perl mkstdbit.pl >
# stdbit.ff.txt) and libatomic's functions (atomics.ff.txt, from mkatomics.pl: perl mkatomics.pl >
# atomics.ff.txt; a target with real atomics has its own, ATOMICS:
# atomics-riscv64.ff.txt, perl mkatomics.pl riscv64). The asm parts share
# one page, glibc asm: the trees a
# program reads have 255 pages in all (c2ff makes a page per directory);
# past 255 items it is in layers (LAYERS, below: x86_64's string has 283).
# The tree's license (license.ff.txt) is at its root, and each page first
# has the license of each file it is made of, its header (c2ff, s2ff
# --header; ../compiler/gen/Header.pm).
define milestone
OBJS_all_$(1) := $$(call objs_of,OBJS,$(1))
ASMS_all_$(1) := $$(call objs_of,ASMS,$(1))
$$(FF)/$(1).ff: $$(OBJS_all_$(1):%=$$(I)/%.$$(UNITDEP)) $$(ASMS_all_$(1):%=$$(I)/%.dump) $$(if $$(filter csu/crti,$$(ASMS_all_$(1))),$$(I)/csu/crtn.dump) builtins.ff.txt stdbit.ff.txt $$(wildcard builtins-$$(GTARGET).ff.txt) $$(ATOMICS) license.ff.txt ../compiler/gen/c2ff.pl ../compiler/gen/Words.pm ../compiler/gen/s2ff.pl $$(S2FF) ../compiler/gen/Header.pm
	mkdir -p $$(FF)
	cp $$(or $$(LICENSE_$(1)),license.ff.txt) $$(FF)/$(1).ff.txt
	$$(RUN) -t 300 perl ../compiler/gen/c2ff.pl --target $$(GTARGET) $$(foreach z,$$(call with_start,ZEROS,$(1)),--zero $$(z)) $$(foreach w,$$(call with_start,WEAKS,$(1)),--weak $$(w)) $$(foreach o,$$(OBJS_all_$(1)),$$(I)/$$(o).json=$$(I)/$$(o).i) \
	    -- $$(ROOTS_$(1)) $$(if $$(call startms,$(1)),$$(ROOTS_start)) $$$$(for a in $$(ASMS_all_$(1)); do $(XPRE)objdump -t $$(I)/$$$$a.ref.o | awk '/\*UND\*/ { print $$$$NF }'; done | sort -u) >> $$(FF)/$(1).ff.txt
	echo 'glibc asm:' > $$(FF)/$(1).asm.page.txt
	$$(if $$(ASMS_all_$(1)),perl ../compiler/gen/s2ff.pl --header $$(ASMS_all_$(1):%=$$(I)/%.s) | sed 's/^/  /' >> $$(FF)/$(1).asm.page.txt)
	for a in $$(ASMS_all_$(1)); do \
	    then=; test $$$$a = csu/crti && then="--then $$(I)/csu/crtn$$(SSRC) $$(I)/csu/crtn.dump"; \
	    $$(RUN) -t 60 perl $$(S2FF) --items $$(if $$(filter aarch64 x86_64 arm,$$(GTARGET)),$$(foreach z,$$(call with_start,ZEROS,$(1)),--zero $$(z))) $$(I)/$$$$a$$(SSRC) $$(I)/$$$$a.dump $$$$then > $$(FF)/$(1).asm.txt || exit 1; \
	    sed 's/^/  /' $$(FF)/$(1).asm.txt >> $$(FF)/$(1).asm.page.txt; \
	done
	$$(if $$(ASMS_all_$(1)),$$(LAYERS) $$(FF)/$(1).asm.page.txt >> $$(FF)/$(1).ff.txt)
	cat builtins.ff.txt stdbit.ff.txt $$(wildcard builtins-$$(GTARGET).ff.txt) $$(ATOMICS) >> $$(FF)/$(1).ff.txt
	perl ../compiler/gen/fftext.pl ff $$(FF)/$(1).ff.txt > $$@
endef
$(foreach m,$(MILESTONES),$(eval $(call milestone,$(m))))

# Each asm part, assembled by ttpc alone (with a _start after it; start.S's
# own is its page's), is the
# bytes glibc's compiler made of it, its .text without the padding at its
# end; the fields relocations fill in (relmask.pl) are the linker's, not
# compared, and what it names from elsewhere is a stand-in label after it.
ASMCHECK_riscv64 = $(ASMS_stdio) csu/start
# (aarch64: every asm object of glibc, but crti and crtn, whose .init and
# .fini are not .text)
ASMCHECK_aarch64 = $(filter-out csu/crti csu/crtn,$(ALL_ASM))
# (x86_64: every asm object of glibc but those s2ff makes no ff of yet,
# by reason: libmvec's (mathvec/: SSE and AVX's packed floats, mulpd
# vfmadd213pd vinsertf128 ..., have no forms yet, and most have tables in
# .rodata); crti and crtn (.init and .fini, not .text: s2ff --then makes
# their ff, the milestones run it))
ASMSKIP_x86_64 = $(filter mathvec/%,$(ALL_ASM)) csu/crti csu/crtn
ASMCHECK_x86_64 = $(filter-out $(ASMSKIP_x86_64),$(ALL_ASM))
# (arm: as aarch64, every asm object but crti and crtn)
ASMCHECK_arm = $(filter-out csu/crti csu/crtn,$(ALL_ASM))
ASMCHECK ?= $(or $(ASMCHECK_$(GTARGET)),$(ASMS_stdio))
# (made by a make of its own: aarch64's list is all of glibc's asm, which
# this Makefile works out only after this rule)
asm-check:
	@$(MAKE) --no-print-directory $(ASMCHECK:%=$(I)/%.asmok)
	@for a in $(ASMCHECK); do cat $(I)/$$a.asmok; done

# one asm part's check: $(I)/x.asmok holds what it found, made only where
# ttpc and glibc's compiler agree. Per target: the instruction of a
# stand-in label (ASMTRAP) and where ttpc's code starts in its output
# (ASMHDR, after the ELF and program headers). relmask.pl knows riscv64's,
# aarch64's and arm's relocations; s2ff.pl reads riscv64's GNU as,
# s2ff-aarch64.pl aarch64's (from the .Ls: SSRC), s2ff-arm.pl arm's
# (S2FF). On aarch64 the bytes start after the padding before the first
# label (s2ff-aarch64.pl --skip: strncmp's nops), and the .s must make
# glibc's own object (the same .text).
ASMTRAP_riscv64 := ebreak
ASMHDR_riscv64 := 120
ASMTRAP_aarch64 := brk\n    0
ASMHDR_aarch64 := 120
ASMTRAP_arm := udf\n    0
ASMHDR_arm := 84
# x86_64: the first function at its alignment after the headers (s2ff
# --align), the code in the one section the object has (codesec)
ASMTRAP_x86_64 := int3
ASMHDR_x86_64 := 120
ASMTRAP = $(or $(ASMTRAP_$(GTARGET)),$(error asm-check: no ASMTRAP_$(GTARGET) yet))
ASMHDR = $(or $(ASMHDR_$(GTARGET)),$(error asm-check: no ASMHDR_$(GTARGET) yet))
# (x86_64's s2ff also reads the forms of isa/, ttpc also x86_64gnu.ff)
S2FFDEPS_x86_64 := ../compiler/gen/s2ffx86.pm ../compiler/isa/x86_64.pl ../compiler/isa/x86_64gnu.pl
$(I)/%.asmok: $(I)/%.dump $(I)/%.bin $(S2FF) $(S2FFDEPS_$(GTARGET)) $(SHARED) $(TTPC)
	@rm -f $@; a=$(I)/$*; \
	{ perl $(S2FF) $$a$(SSRC) $$a.dump && printf '_start:\n  $(ASMTRAP)\n' && \
	  $(XPRE)objdump -t $$a.ref.o | awk '/\*UND\*/ { printf "%s:\n  $(ASMTRAP)\n", $$NF }'; } > $$a.asm.ff.txt || exit 1; \
	perl ../compiler/gen/fftext.pl ff $$a.asm.ff.txt > $$a.asm.ff; \
	$(RUN) -t 60 $(TTPC_RUN) $(SHARED) $$a.asm.ff $$a.asm > $$a.asm.lst || exit 1; \
	size=$$(perl $(S2FF) --size $$a$(SSRC) $$a.dump) || exit 1; \
	skip=$(if $(filter aarch64,$(GTARGET)),$$(perl $(S2FF) --skip $$a$(SSRC) $$a.dump) || exit 1,0); \
	hdr=$(if $(filter x86_64,$(GTARGET)),$$(perl $(S2FF) --align $$a$(SSRC) $$a.dump | awk '{ print int(($(ASMHDR) + $$1 - 1) / $$1) * $$1 }') || exit 1,$(ASMHDR)); \
	sec=$(call codesec,$$a.ref.o); \
	$(if $(filter aarch64 x86_64,$(GTARGET)),$(XPRE)objcopy -O binary -j $$sec $(OBJ)/$*.o $$a.glibc.bin && \
	    cmp -s $$a.glibc.bin $$a.bin || { echo "asm-check: $*: the .s does not make glibc's object"; exit 1; };) \
	$(XPRE)objdump -r $$a.ref.o > $$a.relocs; \
	tail -c +$$((skip + 1)) $$a.bin | head -c $$size > $$a.want.raw; \
	tail -c +$$((hdr + 1)) $$a.asm | head -c $$size > $$a.got.raw; \
	perl relmask.pl $$a.relocs $$a.want.raw $$skip $$sec > $$a.want || exit 1; \
	perl relmask.pl $$a.relocs $$a.got.raw $$skip $$sec > $$a.got || exit 1; \
	cmp $$a.got $$a.want || exit 1; \
	echo "asm-check: $*: ttpc and glibc's compiler agree ($$size bytes)" > $@

# progs/strlen.ff includes string.ff from its own folder, so both go there
strlen-check: $(FF)/string.ff progs/strlen.ff asm-check
	cp progs/strlen.ff $(FF)/strlen-prog.ff
	$(RUN) -t 120 $(TTPC_RUN) $(SHARED) $(FF)/strlen-prog.ff $(FF)/strlen-prog > $(FF)/strlen-prog.lst
	s=0; $(RUN) -t 30 qemu-riscv64 -cpu rv64,v=false $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: glibc's strlen, generic C (-cpu rv64,v=false): 12"
	s=0; $(RUN) -t 30 qemu-riscv64 $(FF)/strlen-prog || s=$$?; test $$s -eq 12
	@echo "strlen-check: with V its resolver picks glibc's vector asm: 12"

# A test program in C, progs/NAME.c, built two ways: with gcc against
# libc.a (glibc's own startup, no builtins: each call reaches glibc), and
# through c2ff --program, with ttpc against the milestone of that name
# (each takes in the ones before it), included as the folder NAME (the
# files of what the program reaches, read lazily). Both run with V and without; all
# four must exit with the status on the first line of progs/NAME.expect
# ("exit N") and print the rest of it.
# (x86_64's gnuc with libm.a too: gcc calls fma and fmaf there, which it
# makes no instruction of without FMA, as glibc's own libm is built)
REFLIBS_gnuc_x86_64 = $(OBJ)/math/libm.a
CRTBEGIN = $(shell $(GLIBC_CC) -print-file-name=crtbeginT.o)
CRTEND = $(shell $(GLIBC_CC) -print-file-name=crtend.o)

$(FF)/%.ref $(FF)/%.map &: progs/%.c $(OBJ)/libc.a
	mkdir -p $(FF)
	$(RUN) -t 120 $(GLIBC_CC) -O2 -fno-builtin $(PROGFLAGS) $(CFLAGS_$*) -c $< -o $(FF)/$*.ref.o
	$(RUN) -t 120 $(GLIBC_CC) -static -nostdlib -Wl,-Map=$(FF)/$*.map -o $(FF)/$*.ref $(OBJ)/csu/crt1.o $(OBJ)/csu/crti.o $(CRTBEGIN) \
	    $(FF)/$*.ref.o -Wl,--start-group $(OBJ)/libc.a $(REFLIBS_$*_$(GTARGET)) -lgcc -lgcc_eh -Wl,--end-group $(CRTEND) $(OBJ)/csu/crtn.o

# what a milestone's program links of glibc (aarch64's milestones)
$(FF)/%.objs.mk: $(FF)/%.map linkobjs.pl allobjs.pl mki.pl
	perl linkobjs.pl $* $(FF)/$*.map $(OBJ) $(GLIBC_SRC) > $@

# A milestone as a folder that a program includes lazily (ffsplit.pl): a file
# per page and index.ff, the file of each name; ttpc reads only the files
# of what the program reaches.
$(FF)/%/index.ff: $(FF)/%.ff ../compiler/gen/ffsplit.pl
	rm -rf $(FF)/$*
	$(RUN) -t 120 perl ../compiler/gen/ffsplit.pl $(FF)/$*.ff.txt $(FF)/$*

$(FF)/%-prog.ff: progs/%.c clang-prelude.h ../compiler/gen/c2ff.pl ../compiler/gen/Words.pm
	mkdir -p $(FF)
	$(RUN) -t 60 $(GLIBC_CC) -E $(PROGFLAGS) $< -o $(FF)/$*-prog.i
	$(RUN) -t 120 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=$(CTARGET) $(PROGFLAGS) -std=gnu11 -w $(FF)/$*-prog.i > $(FF)/$*-prog.json
	$(RUN) -t 120 perl ../compiler/gen/c2ff.pl --target $(GTARGET) --program $* $(if $(filter $*,$(OWNSTART)),--start,$(if $(call startms,$*),,--start)) $(FF)/$*-prog.json=$(FF)/$*-prog.i -- main > $(FF)/$*-prog.ff.txt
	perl ../compiler/gen/fftext.pl ff $(FF)/$*-prog.ff.txt > $@

$(FF)/%-prog: $(FF)/%-prog.ff $(FF)/%/index.ff $(TTPC)
	$(RUN) -t 900 $(TTPC_RUN) $(TTPCFLAGS_$*) $(SHARED) $< $@ > $@.lst

# what a check expects: progs/NAME.expect, or progs/NAME.<target>.expect
# where the target's glibc differs (soft-fp's NaNs: riscv64 makes them
# canonical, aarch64 and x86_64 keep a NaN's payload, x86_64's sign is 1;
# gnuc: riscv64's program hashes its asm statements' results too)
expect = $(firstword $(wildcard progs/$(1).$(GTARGET).expect) progs/$(1).expect)

define check
$(1)-check: $$(FF)/$(1).ref $$(FF)/$(1)-prog $$(call expect,$(1)) $(if $(filter riscv64 aarch64,$(GTARGET)),asm-check)
	@want=$$$$(head -n 1 $$(call expect,$(1)) | cut -d" " -f2); \
	tail -n +2 $$(call expect,$(1)) > $$(FF)/$(1).want; \
	for b in $(1).ref $(1)-prog; do \
	    for cpu in $$(CPUS); do \
	        s=0; $$(RUN) -t 60 $$(if $$(RUNENV_$(1)),env $$(RUNENV_$(1))) qemu-$$(GTARGET) -cpu $$$$cpu $$(FF)/$$$$b $$(RUN_$(1)) > $$(FF)/$$$$b.out || s=$$$$?; \
	        test $$$$s -eq $$$$want || { echo "$(1)-check: $$$$b on $$$$cpu: exit status $$$$s, not $$$$want"; exit 1; }; \
	        cmp -s $$(FF)/$$$$b.out $$(FF)/$(1).want || { echo "$(1)-check: $$$$b on $$$$cpu: wrong output"; diff $$(FF)/$$$$b.out $$(FF)/$(1).want | head; exit 1; }; \
	    done; \
	done; \
	echo "$(1)-check: gcc + libc.a and ttpc + glibc in ff agree$(comma)$(if $(filter riscv64,$(GTARGET)), with V and without,) on $(GTARGET) ($$(CPUS)): exit $$$$want"
.PHONY: $(1)-check
endef
$(foreach m,$(MILESTONES),$(eval $(call check,$(m))))

# -O (ttpc's peephole, ../compiler/gen/patches/opt.pl): each milestone's
# program built with -O (NAME-prog-O), against the same expect as its check;
# check-O: every milestone of the target (riscv64's MILESTONES, else LINKED).
$(FF)/%-prog-O: $(FF)/%-prog.ff $(FF)/%/index.ff $(TTPC)
	$(RUN) -t 900 $(TTPC_RUN) -O $(TTPCFLAGS_$*) $(SHARED) $< $@ > $@.lst
define checkO
$(1)-check-O: $$(FF)/$(1)-prog-O $$(FF)/$(1)-prog $$(call expect,$(1))
	@want=$$$$(head -n 1 $$(call expect,$(1)) | cut -d" " -f2); \
	tail -n +2 $$(call expect,$(1)) > $$(FF)/$(1).want; \
	for cpu in $$(CPUS); do \
	    s=0; $$(RUN) -t 60 $$(if $$(RUNENV_$(1)),env $$(RUNENV_$(1))) qemu-$$(GTARGET) -cpu $$$$cpu $$(FF)/$(1)-prog-O $$(RUN_$(1)) > $$(FF)/$(1)-prog-O.out || s=$$$$?; \
	    test $$$$s -eq $$$$want || { echo "$(1)-check-O: on $$$$cpu: exit status $$$$s, not $$$$want"; exit 1; }; \
	    cmp -s $$(FF)/$(1)-prog-O.out $$(FF)/$(1).want || { echo "$(1)-check-O: on $$$$cpu: wrong output"; diff $$(FF)/$(1)-prog-O.out $$(FF)/$(1).want | head; exit 1; }; \
	done; \
	echo "$(1)-check-O: ttpc -O + glibc in ff as gcc + libc.a on $(GTARGET) ($$(CPUS)): exit $$$$want, $$$$(wc -c < $$(FF)/$(1)-prog-O) bytes, without -O $$$$(wc -c < $$(FF)/$(1)-prog)"
.PHONY: $(1)-check-O
endef
$(foreach m,$(MILESTONES),$(eval $(call checkO,$(m))))
CHECKO_MS := $(if $(filter riscv64,$(GTARGET)),$(MILESTONES),$(LINKED))
check-O: $(CHECKO_MS:%=%-check-O)
.PHONY: check-O

# The round trip, the other proof of "exact": the C functions of a milestone,
# written back as C from its ff (ff2c.pl, which reads ff as ttpc does), have
# the AST of glibc's own, each against its .i's (roundtrip.pl). The
# addresses of asm functions, which have no C type in ff, are let through.
$(FF)/%.rt.c $(FF)/%.rt.names &: $(FF)/%.ff ../compiler/gen/ff2c.pl ../compiler/gen/Words.pm
	$(RUN) -t 300 perl ../compiler/gen/ff2c.pl --target $(GTARGET) $(FF)/$*.ff.txt $(FF)/$*.rt.c $(FF)/$*.rt.names

# (x86_64's with SSE4.2: the builtins of gcc's intrinsics that strcspn-sse4's C calls)
RTFLAGS_x86_64 := -msse4.2
$(FF)/%.rt.json: $(FF)/%.rt.c
	$(RUN) -t 600 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json -fsyntax-only --target=$(CTARGET) $(PROGFLAGS) $(RTFLAGS_$(GTARGET)) -std=gnu11 -w \
	    -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion $< > $@

define roundtrip
$(1)-roundtrip: $$(FF)/$(1).rt.json $$(FF)/$(1).rt.names roundtrip.pl $$(OBJS_all_$(1):%=$$(I)/%.json)
	$$(RUN) -t 900 perl roundtrip.pl --target $$(GTARGET) $$(FF)/$(1).rt.names $$(FF)/$(1).rt.json $$(OBJS_all_$(1):%=$$(I)/%.json)
	$$(RUN) -t 300 perl ../compiler/gen/headers.pl $$(FF)/$(1).rt.c $$(FF)/$(1).rt.names
.PHONY: $(1)-roundtrip
endef
$(foreach m,$(MILESTONES),$(eval $(call roundtrip,$(m))))
glibc-roundtrip: floats-roundtrip

.PHONY: strlen-check asm-check glibc-roundtrip

# The licenses (../compiler/gen/licenses.pl): glibc's trees here (their
# pages' licenses: builtins, atomics), and of a milestone its tree, its
# folder (each file and the index) and its program, each with its license
# at its root and every page made from source with the license of each
# file it is made of. glibc-licenses checks every milestone made.
LICENSES_PL := perl ../compiler/gen/licenses.pl
licenses:
	$(LICENSES_PL) --fragment builtins.ff.txt stdbit.ff.txt atomics.ff.txt $(wildcard atomics-*.ff.txt)
	$(LICENSES_PL) license.ff.txt progs/strlen.ff
define licenses
$(1)-licenses: $$(FF)/$(1).ff $$(FF)/$(1)/index.ff $$(FF)/$(1)-prog.ff
	$$(LICENSES_PL) --pages $$(FF)/$(1).ff $$(FF)/$(1)/*.ff
	$$(LICENSES_PL) $$(FF)/$(1)-prog.ff
.PHONY: $(1)-licenses
endef
$(foreach m,$(MILESTONES),$(eval $(call licenses,$(m))))
glibc-licenses: licenses $(MILESTONES:%=%-licenses)
.PHONY: licenses glibc-licenses

# ---- glibc's C constructs, on their own -------------------------------------
# progs/generic.c holds the constructs of glibc's C that c2ff and ttpc took
# in for all of glibc (a path from an expression, a call through a comma's
# value, sizeof of a VLA, a label's attribute, array compound literals,
# gcc's ffs and overflow builtins), each checked: it exits with the number
# that fail. It needs no part of glibc but the builtins, so it is built
# against a folder of them alone, with a _start of its own (c2ff --start)
# on every target, and as every check with gcc + libc.a; generic-roundtrip
# writes its ff back as C and compares the ASTs, as for a milestone.
# progs/stdbit.c, the same way: C23's bit functions (gcc's type-generic
# __builtin_stdc_*, stdbit.ff.txt's) on each unsigned type, against plain
# counts of the bits, on every target (arm too: stdbit-check).
OWNSTART := generic stdbit
$(FF)/generic.ff $(FF)/stdbit.ff: $(FF)/%.ff: builtins.ff.txt stdbit.ff.txt $(wildcard builtins-$(GTARGET).ff.txt) $(ATOMICS) license.ff.txt
	mkdir -p $(FF)
	cat license.ff.txt builtins.ff.txt stdbit.ff.txt $(wildcard builtins-$(GTARGET).ff.txt) $(ATOMICS) > $(FF)/$*.ff.txt
	perl ../compiler/gen/fftext.pl ff $(FF)/$*.ff.txt > $@
$(eval $(call check,generic))
$(eval $(call check,stdbit))
GENERIC_FNS := main levels second add2 via_comma vla_size label_attr count arrlit const_counts leaf tag_names many many_sum specials_bad text_ptr
generic-roundtrip: $(FF)/generic-prog.ff roundtrip.pl ../compiler/gen/ff2c.pl
	$(RUN) -t 120 perl ../compiler/gen/c2ff.pl --target $(GTARGET) $(FF)/generic-prog.json=$(FF)/generic-prog.i -- $(GENERIC_FNS) > $(FF)/generic-unit.ff.txt
	$(RUN) -t 120 perl ../compiler/gen/ff2c.pl --target $(GTARGET) $(FF)/generic-unit.ff.txt $(FF)/generic.rt.c $(FF)/generic.rt.names
	$(RUN) -t 120 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json -fsyntax-only --target=$(CTARGET) $(PROGFLAGS) -std=gnu11 -w \
	    -Wno-error=incompatible-function-pointer-types -Wno-error=int-conversion $(FF)/generic.rt.c > $(FF)/generic.rt.json
	$(RUN) -t 300 perl roundtrip.pl --target $(GTARGET) $(FF)/generic.rt.names $(FF)/generic.rt.json $(FF)/generic-prog.json
	$(RUN) -t 120 perl ../compiler/gen/headers.pl $(FF)/generic.rt.c $(FF)/generic.rt.names
.PHONY: generic-roundtrip

# ---- every check at once --------------------------------------------------------
# make -jN all-checks: what the ports branch is checked with on GTARGET, the
# checks that do not need each other at once, each heavy step in a slot of
# its own (RUN). On riscv64 and aarch64 each milestone's check and round
# trip (aarch64's and x86_64's milestones: LINKED); on each,
# the generic program's check and round trip. What they all read is made
# first, once (units-ready): the ASTs and asm parts of the milestones'
# objects, the asm check, and c2ff's pass of each unit, which each
# milestone's c2ff would otherwise make at the same time as the others.
# (aarch64's units are that pass already, UNITDEP c2ff, which deletes the
# AST: the ASTs the round trips read are made after it; the make that
# reads this Makefile has made its milestones' objs.mk. The asm check
# comes after the asm parts it reads.)
CHECK_MS_riscv64 := $(MILESTONES)
CHECK_MS_aarch64 := $(LINKED_aarch64)
CHECK_MS_x86_64 := $(LINKED_x86_64)
CHECK_MS_arm := $(LINKED_arm)
CHECK_MS := $(or $(CHECK_MS_$(GTARGET)),ldouble)
ALLCHECKS_riscv64 := $(MILESTONES:%=%-check) $(MILESTONES:%=%-roundtrip)
ALLCHECKS_aarch64 := $(LINKED_aarch64:%=%-check) $(LINKED_aarch64:%=%-roundtrip)
ALLCHECKS_x86_64 := $(LINKED_x86_64:%=%-check) $(LINKED_x86_64:%=%-roundtrip)
ALLCHECKS_arm := $(LINKED_arm:%=%-check) $(LINKED_arm:%=%-roundtrip)
# (no generic program on arm: progs/generic.c takes a long for 64 bits)
ALLCHECKS := $(or $(ALLCHECKS_$(GTARGET)),ldouble-check) $(if $(filter arm,$(GTARGET)),,generic-check generic-roundtrip)
CHECK_OBJS = $(sort $(foreach m,$(CHECK_MS),$(OBJS_all_$(m))))
CHECK_ASMS = $(sort $(foreach m,$(CHECK_MS),$(ASMS_all_$(m))))
units-ready: $(CHECK_OBJS:%=$(I)/%.$(UNITDEP)) $(CHECK_ASMS:%=$(I)/%.dump) $(if $(filter csu/crti,$(CHECK_ASMS)),$(I)/csu/crtn.dump)
	$(if $(filter json,$(UNITDEP)),$(RUN) -t 900 perl ../compiler/gen/c2ff.pl --pass --target $(GTARGET) $(foreach o,$(CHECK_OBJS),$(I)/$(o).json=$(I)/$(o).i))
	$(if $(filter c2ff,$(UNITDEP)),@$(MAKE) --no-print-directory $(CHECK_OBJS:%=$(I)/%.json))
	$(if $(filter riscv64 aarch64,$(GTARGET)),@$(MAKE) --no-print-directory asm-check)
all-checks:
	@$(MAKE) --no-print-directory units-ready
	@$(MAKE) --no-print-directory -k $(ALLCHECKS)
.PHONY: units-ready all-checks

# ---- all of glibc --------------------------------------------------------------
# Every object of the static libraries glibc installs for GTARGET
# (allobjs.pl: libc.a, libm.a, libmvec.a where there is one, libresolv.a,
# libBrokenLocale.a, libg.a, libmcheck.a, and crt1.o's parts, crti.o and
# crtn.o; libutil.a, libanl.a, libpthread.a, librt.a and libdl.a are
# empty), each C object as c2ff's pass of its AST (tu.c2ff), each asm
# object as its .s and what glibc's compiler made of it.
#
#   make all-units       the .i or .s of each, and each C object's pass
#
# A C object's AST is made for its pass and then deleted (all of glibc's
# take some 16 GB): c2ff takes its pass while the .i is the same, and the
# pass is made again only where c2ff's pass itself changed (c2ff exits 3:
# the AST is made again; unit.sh). Each object's heavy step runs in one of
# the machine's shared slots (slot.sh), make -j3 at most.
SLOT := $(RUN)
ALLOBJS = $(shell perl allobjs.pl $(OBJ) | cut -d' ' -f2)
# (worked out once, where a target needs it)
ALLFILES = $(eval ALLFILES := $(shell perl mki.pl --dry $(OBJ) $(GLIBC_SRC) $(ALLOBJS:%=%.o)))$(ALLFILES)
# (and long double's soft-fp, as the ldouble milestone has it: libgcc's on
# a gcc build, glibc's own code, which ttpc's long double calls)
ALL_C = $(patsubst $(I)/%.i,%,$(filter %.i,$(ALLFILES))) $(SOFTFP:%=soft-fp/%)
ALL_ASM = $(patsubst $(I)/%.s,%,$(filter %.s,$(ALLFILES)))
# crt1.o's parts, crti.o and crtn.o, which a program links before libc.a:
# their definitions are the ones of a name libc.a defines too
# (_dl_relocate_static_pie, static-reloc's, not static PIE's)
ALL_CRT = $(shell perl allobjs.pl $(OBJ) crt | cut -d' ' -f2)

CLANG_AST = $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	-fsyntax-only --target=$(CTARGET) $(PROGFLAGS) -std=gnu11 -fgnu89-inline -w

$(I)/%.c2ff: $(I)/%.i clang-prelude.h ../compiler/gen/c2ff.pl unit.sh
	@$(if $(CLANGFIX),$(CLANGFIX) $< $(call vecfix,$*) > $(I)/$*.clang.i;) \
	sh unit.sh $(GTARGET) $< $(I)/$*.json $(if $(CLANGFIX),$(I)/$*.clang.i,$<) $(CLANG_AST) $(call vecflag,$*)
	@touch $@

all-units: $(ALL_C:%=$(I)/%.c2ff) $(ALL_ASM:%=$(I)/%.dump)
	@echo "all-units: $(words $(ALL_C)) C objects, $(words $(ALL_ASM)) asm objects"
.PHONY: all-units

# Each C object alone (all-survey): c2ff of its pass, from the names its
# object defines (nm), as what c2ff makes of it ($(I)/x.one.ff.txt) or why
# it cannot yet ($(I)/x.one.err, its last line c2ff's message); the names
# it takes from other objects are left out (c2ff says so). A count of the
# objects done and the reasons of the others, most first.
# An object that defines nothing (riscv64's dirent/readdir.o: readdir64's
# object defines readdir too) has nothing to translate.
$(I)/%.one: $(I)/%.c2ff ../compiler/gen/c2ff.pl
	@roots=$$($(XPRE)nm --defined-only -g $(OBJ)/$*.o | awk 'NF == 3 { print $$3 }'); s=0; \
	if test -z "$$roots"; then echo "all-survey: $*: defines nothing" > $(I)/$*.one.err; : > $(I)/$*.one.ff.txt; \
	else $(SLOT) -t 300 perl ../compiler/gen/c2ff.pl --target $(GTARGET) $(I)/$*.json=$(I)/$*.i \
	    -- $$roots > $(I)/$*.one.ff.txt 2> $(I)/$*.one.err || s=$$?; fi; \
	echo $$s > $@

all-survey: $(ALL_C:%=$(I)/%.one)
	@cd $(I) && n=0; ok=0; for o in $(ALL_C); do n=$$((n + 1)); test "$$(cat $$o.one)" = 0 && ok=$$((ok + 1)); done; \
	echo "all-survey: $$ok of $$n C objects in ff"; \
	for o in $(ALL_C); do test "$$(cat $$o.one)" = 0 || { tail -n 1 $$o.one.err | sed -e 's/ (at .*//' -e 's/^c2ff: //'; }; done | sort | uniq -c | sort -rn | head -60
.PHONY: all-survey

# Each asm object's check (all-asm, with make -k): how many agree, and the
# others.
all-asm:
	-@$(MAKE) -k --no-print-directory $(ALL_ASM:%=$(I)/%.asmok) > $(I)/all-asm.log 2>&1
	@n=0; ok=0; for a in $(ALL_ASM); do n=$$((n + 1)); if test -e $(I)/$$a.asmok; then ok=$$((ok + 1)); else echo "all-asm: $$a: not yet"; fi; done; \
	echo "all-asm: $$ok of $$n asm objects byte for byte (make's output in $(I)/all-asm.log)"
.PHONY: all-asm

# All of glibc in ff (glibc.ff, and the folder glibc/ a program includes):
# c2ff's of every C object, from every name the objects define (nm) and
# what the asm objects name from elsewhere, then s2ff's of every asm
# object, then the builtins and libatomic's functions, as a milestone's
# (its license at its root, each page's files' headers). The roots are in
# $(FF)/glibc.roots, one per line, the units in $(FF)/glibc.units, crt's
# first (ALL_CRT: a name two units define is the first's). What c2ff cannot
# translate yet is left out (--keep-going): its reasons are in
# $(FF)/glibc.c2ff.err, "c2ff: left out: name: why".
# (the asm page, with its headers more than 255 items, in layers: LAYERS)
LAYERS := perl -I../compiler/gen -MFF=node,layers,read_txt,write_txt -0777 -ne \
	'print write_txt(map { node($$_->{content}, layers(@{ $$_->{children} })) } read_txt($$_, $$ARGV))'
ZEROS_glibc := $(ZEROS_stdio) $(ZEROS_start) _r_debug
# libgcc_eh's unwinder, which a static program has from gcc (glibc's
# __pthread_unwind, backtrace): on riscv64 builtins-riscv64.ff.txt's, which
# walks ttpc's frames; elsewhere not in ff yet, its names weak (address 0),
# as for a program that never unwinds
UNWIND_glibc := $(if $(filter riscv64,$(GTARGET)),,_Unwind_ForcedUnwind _Unwind_GetCFA _Unwind_Backtrace _Unwind_GetIP)
WEAKS_glibc := $(WEAKS_stdio) $(WEAKS_start) $(UNWIND_glibc)
$(FF)/glibc.roots: $(ALL_C:%=$(I)/%.c2ff) $(ALL_ASM:%=$(I)/%.dump)
	mkdir -p $(FF)
	{ for o in $(ALL_C); do $(XPRE)nm --defined-only -g $(OBJ)/$$o.o | awk 'NF == 3 { print $$3 }'; done; \
	  for a in $(ALL_ASM); do $(XPRE)objdump -t $(I)/$$a.ref.o | awk '/\*UND\*/ { print $$NF }'; done; \
	  for r in $(ROOTS_ldouble); do echo $$r; done; } | sort -u > $@
	for o in $(filter $(ALL_CRT),$(ALL_C)) $(filter-out $(ALL_CRT),$(ALL_C)); do echo "$(I)/$$o.json=$(I)/$$o.i"; done > $(FF)/glibc.units

$(FF)/glibc.ff: $(FF)/glibc.roots builtins.ff.txt stdbit.ff.txt $(wildcard builtins-$(GTARGET).ff.txt) $(ATOMICS) license.ff.txt ../compiler/gen/c2ff.pl ../compiler/gen/Words.pm ../compiler/gen/s2ff.pl ../compiler/gen/Header.pm
	cp license.ff.txt $(FF)/glibc.ff.txt
	$(SLOT) -v 6000000 -t 3600 perl ../compiler/gen/c2ff.pl --keep-going --target $(GTARGET) $(foreach z,$(ZEROS_glibc),--zero $(z)) $(foreach w,$(WEAKS_glibc),--weak $(w)) \
	    @$(FF)/glibc.units -- @$(FF)/glibc.roots >> $(FF)/glibc.ff.txt 2> $(FF)/glibc.c2ff.err \
	    || { tail -5 $(FF)/glibc.c2ff.err; exit 1; }
	echo 'glibc asm:' > $(FF)/glibc.asm.page.txt
	perl ../compiler/gen/s2ff.pl --header $(ALL_ASM:%=$(I)/%.s) | sed 's/^/  /' >> $(FF)/glibc.asm.page.txt
	for a in $(ALL_ASM); do \
	    $(RUN) -t 60 perl ../compiler/gen/s2ff.pl --items $(I)/$$a.s $(I)/$$a.dump > $(FF)/glibc.asm.txt || exit 1; \
	    sed 's/^/  /' $(FF)/glibc.asm.txt >> $(FF)/glibc.asm.page.txt; \
	done
	$(LAYERS) $(FF)/glibc.asm.page.txt >> $(FF)/glibc.ff.txt
	cat builtins.ff.txt stdbit.ff.txt $(wildcard builtins-$(GTARGET).ff.txt) $(ATOMICS) >> $(FF)/glibc.ff.txt
	perl ../compiler/gen/fftext.pl ff $(FF)/glibc.ff.txt > $@

# the list of a kind of object, for a look at it: make print-ALL_ASM
print-%:
	@echo $($*)

# ---- libgcc in ff -----------------------------------------------------------------
# libgcc, gcc's runtime (src/libgcc), as glibc above: gcc 16's own source as
# flake.nix pins it (nixpkgs' gcc16, the derivation of GLIBC_CC, its
# patches applied), libgcc.a and libgcc_eh.a built for GTARGET as gcc's
# are, with GLIBC_CC itself and the C library's headers gcc's libgcc was
# built with (LIBGCC_HEADERS), in a folder of its own, LBUILD (not under
# glibc's BUILD: one libgcc for all of them). Every object's .text is the
# same as gcc's own libgcc.a's (../libgcc/mkref.sh checks it). build.log
# keeps each command, which ../libgcc/mki.pl runs again with -E: the .i of
# each object in $(I)/libgcc (a .S's .s), whose AST clang makes of a copy
# (../libgcc/clangfix.pl: gcc's modes of libgcc's own, HF, HC and BF) as
# gnu23, the C gcc 16 compiles libgcc's C as.
#
#   make libgcc-ref      gcc's source, configured; libgcc built -> LOBJ
#
# The tree, $(FF)/libgcc.ff (pages gcc libgcc: and gcc asm:, as glibc.ff's
# glibc string: ...): c2ff of every C object of libgcc.a and libgcc_eh.a,
# from every name they define, and s2ff of the asm objects, then the
# builtins, as a milestone's; its license at its root
# (../libgcc/license.ff.txt), each page with its files' headers. What c2ff
# cannot translate yet is left out (--keep-going), with why, in
# $(FF)/libgcc.c2ff.err: _Float16 and __bf16 (HF, BF), the trapping
# arithmetic of 128 bits. clang reads neither atomic.c (it redefines gcc's
# __sync builtins) nor strub.c (__builtin_stack_address, which clang lacks).
# Only riscv64 so far.
LBUILD ?= $(HOME)/.cache/ttp/build/libgcc/$(GTARGET)
LOBJ := $(LBUILD)/build/$(TRIPLE)/libgcc
export LIBGCC_SRC := $(LBUILD)/gcc-16.2.0
LI := $(I)/libgcc
# (the objects of libgcc.a and libgcc_eh.a, worked out once where needed)
LIBGCC_MEMBERS = $(eval LIBGCC_MEMBERS := $(shell for a in libgcc.a libgcc_eh.a; do $(XPRE)ar t $(LOBJ)/$$a 2> /dev/null; done | sed 's/\.o$$//'))$(LIBGCC_MEMBERS)
LIBGCC_ASM := save-restore muldi3 div
LIBGCC_NOCLANG := atomic strub
LIBGCC_C = $(filter-out $(LIBGCC_ASM) $(LIBGCC_NOCLANG),$(LIBGCC_MEMBERS))

libgcc-ref: $(LOBJ)/libgcc.a
$(LOBJ)/libgcc.a:
	$(RUN) -t 3600 sh ../libgcc/mkref.sh $(LBUILD) $(abspath ../..) $(TRIPLE) $(JOBS)
	mkdir -p $(LBUILD)/gcroots
	nix build --out-link $(LBUILD)/gcroots/HEADERS $$(echo $(LIBGCC_HEADERS) | cut -d/ -f1-4)
	nix build --out-link $(LBUILD)/gcroots/CC $$(echo $(GLIBC_CC) | cut -d/ -f1-4)

.PRECIOUS: $(LI)/%.i $(LI)/%.s $(LI)/%.json
$(LI)/%.i: $(LOBJ)/libgcc.a ../libgcc/mki.pl
	$(RUN) -t 120 perl ../libgcc/mki.pl $(LOBJ) $(LI) $*.o > /dev/null
$(LI)/%.s: $(LOBJ)/libgcc.a ../libgcc/mki.pl
	$(RUN) -t 120 perl ../libgcc/mki.pl $(LOBJ) $(LI) $*.o > /dev/null
$(LI)/%.json: $(LI)/%.i ../libgcc/clangfix.pl clang-prelude.h
	perl ../libgcc/clangfix.pl $< > $(LI)/$*.clang.i
	$(RUN) -t 300 $(C2FF_CLANG) -x c -include clang-prelude.h -Xclang -ast-dump=json \
	    -fsyntax-only --target=$(CTARGET) -std=gnu23 -fgnu89-inline -w $(LI)/$*.clang.i > $@

$(FF)/libgcc.roots $(FF)/libgcc.units &: $(LIBGCC_C:%=$(LI)/%.json) $(LIBGCC_ASM:%=$(LI)/%.dump)
	mkdir -p $(FF)
	for o in $(filter-out $(LIBGCC_NOCLANG),$(LIBGCC_MEMBERS)); do $(XPRE)nm --defined-only -g $(LOBJ)/$$o.o | awk 'NF == 3 { print $$3 }'; done | sort -u > $(FF)/libgcc.roots
	for o in $(LIBGCC_C); do echo "$(LI)/$$o.json=$(LI)/$$o.i"; done > $(FF)/libgcc.units

$(FF)/libgcc.ff: $(FF)/libgcc.roots $(FF)/libgcc.units builtins.ff.txt stdbit.ff.txt $(wildcard builtins-$(GTARGET).ff.txt) $(ATOMICS) ../libgcc/license.ff.txt ../compiler/gen/c2ff.pl ../compiler/gen/Words.pm ../compiler/gen/s2ff.pl ../compiler/gen/Header.pm
	cp ../libgcc/license.ff.txt $(FF)/libgcc.ff.txt
	$(RUN) -t 900 perl ../compiler/gen/c2ff.pl --keep-going --page gcc --target $(GTARGET) @$(FF)/libgcc.units -- @$(FF)/libgcc.roots \
	    >> $(FF)/libgcc.ff.txt 2> $(FF)/libgcc.c2ff.err || { tail -5 $(FF)/libgcc.c2ff.err; exit 1; }
	echo 'gcc asm:' > $(FF)/libgcc.asm.page.txt
	perl ../compiler/gen/s2ff.pl --header $(LIBGCC_ASM:%=$(LI)/%.s) | sed 's/^/  /' >> $(FF)/libgcc.asm.page.txt
	for a in $(LIBGCC_ASM); do \
	    $(RUN) -t 60 perl ../compiler/gen/s2ff.pl --items $(LI)/$$a.s $(LI)/$$a.dump > $(FF)/libgcc.asm.txt || exit 1; \
	    sed 's/^/  /' $(FF)/libgcc.asm.txt >> $(FF)/libgcc.asm.page.txt; \
	done
	$(LAYERS) $(FF)/libgcc.asm.page.txt >> $(FF)/libgcc.ff.txt
	cat builtins.ff.txt stdbit.ff.txt $(wildcard builtins-$(GTARGET).ff.txt) $(ATOMICS) >> $(FF)/libgcc.ff.txt
	perl ../compiler/gen/fftext.pl ff $(FF)/libgcc.ff.txt > $@
	@echo "libgcc.ff: $$(grep -c '^c2ff: left out' $(FF)/libgcc.c2ff.err) names left out, why in $(FF)/libgcc.c2ff.err"

# The tree's own checks: libgcc-roundtrip, its C written back (ff2c) has
# the AST of libgcc's own, function by function; libgcc-licenses, its
# license at its root and each page's files' headers (also of its folder,
# the files a program includes). Its functions are checked by the milestone
# gccrt (above), against gcc's libgcc.a.
OBJS_all_libgcc = $(LIBGCC_C:%=libgcc/%)
$(eval $(call roundtrip,libgcc))
libgcc-licenses: $(FF)/libgcc.ff $(FF)/libgcc/index.ff
	$(LICENSES_PL) --pages $(FF)/libgcc.ff $(FF)/libgcc/*.ff
libgcc-checks: libgcc-roundtrip libgcc-licenses
.PHONY: libgcc-ref libgcc-checks libgcc-licenses

# ---- glibc's own tests -----------------------------------------------------------
# The tests of an area of glibc (AREA: one of its directories, string,
# stdlib, ...), its programs tst-*, built two ways and run, as a
# milestone's program is: what glibc's build makes of each, linked
# statically with gcc against libc.a and libsupport (glibc's library for its
# tests), and through c2ff, the test's C and libsupport's in ff, with ttpc
# against all of glibc in ff (the folder glibc, above). Each runs with V and
# without (CPUS); a test is equal where every run exits with the same status
# and prints the same, on stdout and stderr. The table, TBUILD/AREA.table:
# a line of counts, then each test, equal (and glibc's word for its
# status: PASS, UNSUPPORTED, FAIL), differ (how) or not yet (the step and
# why).
#
#   make tests-ref AREA=string
#
# glibc's build makes the tests: make check of the area with
# run-built-tests=no compiles and links them and runs none (its own checks
# of the headers fail without a run, and are not ours). make check writes
# into its build, so the tests have a glibc-ref of their own, TBUILD
# (BUILD/tests, some 1 GB, minutes; BUILD's obj may be another build's),
# whose libsupport (libsupport_nonshared.a) they take too. The area's log,
# TOBJ/AREA.log, has each test's link command, and so its objects
# (tests.pl mk, TBUILD/AREA.mk); the .i of each, and of libsupport's
# objects (build.log), is its command again with -E (mki.pl --log), its
# c2ff pass as for all of glibc. Each test's steps (gcc's link, c2ff,
# ttpc, the runs) go on where one fails, and its result says which did:
# TFF/test.result, the steps' logs next to it.
TESTS_PATTERN ?= tst-*
TBUILD := $(BUILD)/tests
TOBJ := $(TBUILD)/obj
TI := $(TBUILD)/i
TFF := $(TBUILD)/ff/$(AREA)
TLOGS := --log $(TOBJ)/build.log --log $(TOBJ)/$(AREA).log

# The inner make builds glibc alone, with AREA empty: AREA would come down
# in MAKEFLAGS, and with it the -include below, whose .mk needs a libc.a of
# TBUILD's own tests, one folder deeper, and so on without end (on
# 2026-10-20 that froze the machine). A tests build within a tests build,
# or a make nested past MAKELEVEL 8, stops (the guards below).
$(TOBJ)/libc.a:
	$(RUN) -t 3600 $(MAKE) --no-print-directory BUILD=$(TBUILD) AREA= glibc-ref

$(TOBJ)/$(AREA).log: | $(TOBJ)/libc.a
	-$(RUN) -t 3600 $(MAKE) -C $(TOBJ) -k -j$(JOBS) subdirs=$(AREA) check run-built-tests=no > $@.tmp 2>&1
	mv $@.tmp $@

$(TBUILD)/$(AREA).mk: $(TOBJ)/$(AREA).log tests.pl
	perl tests.pl mk $(TOBJ) $(AREA) '$(TESTS_PATTERN)' > $@.tmp
	mv $@.tmp $@

ifneq ($(AREA),)
ifneq ($(filter %/tests,$(BUILD)),)
$(error AREA=$(AREA) in a tests build ($(BUILD)): its tests would be one folder deeper, without end)
endif
-include $(TBUILD)/$(AREA).mk
endif

.PRECIOUS: $(TI)/%.i $(TI)/%.c2ff $(TFF)/%-prog.ff $(TFF)/%.ref $(TFF)/%-prog

$(TI)/%.i: mki.pl | $(TOBJ)/$(AREA).log
	$(RUN) -t 120 perl mki.pl $(TLOGS) $(TOBJ) $(GLIBC_SRC) $*.o > /dev/null

# (a test's .i for clang: on riscv64 the suffixes of gcc's _FloatN literals,
# f32 f64 f32x f64x f128, which clang lacks, as the C types they are there,
# each the same length, so that the offsets stay: strtod's and strfrom's
# tests; glibc's own units have none that it translates)
TCLANGFIX_riscv64 := sed -e 's/\([0-9]\.\?\)[fF]32x\b/\1    /g' -e 's/\([0-9]\.\?\)[fF]64x\b/\1L   /g' \
	-e 's/\([0-9]\.\?\)[fF]32\b/\1f  /g' -e 's/\([0-9]\.\?\)[fF]64\b/\1   /g' -e 's/\([0-9]\.\?\)[fF]128\b/\1L   /g'
TCLANGFIX = $(or $(CLANGFIX),$(TCLANGFIX_$(GTARGET)))
$(TI)/%.c2ff: $(TI)/%.i clang-prelude.h ../compiler/gen/c2ff.pl unit.sh
	@$(if $(TCLANGFIX),$(TCLANGFIX) $< > $(TI)/$*.clang.i;) \
	sh unit.sh $(GTARGET) $< $(TI)/$*.json $(if $(TCLANGFIX),$(TI)/$*.clang.i,$<) $(CLANG_AST)
	@touch $@

# libsupport's passes, once for all tests (one that fails is the c2ff step's
# reason of each test that needs it)
$(TI)/support.ready: $(TBUILD)/$(AREA).mk
	-@$(MAKE) --no-print-directory -k $(SUPPORT:%=$(TI)/%.c2ff)
	@touch $@

# gcc's: glibc's objects of the test, glibc's startup, libsupport, and the
# libraries of glibc it is linked with as static ones (BUILD's: the glibc
# in ff is made of them). A name of libc's that the test defines too
# (tst-strerror-fail's malloc) is the test's, as in glibc's own run of it,
# where it interposes (the linker takes the first definition).
$(TFF)/%.ref: $(OBJ)/libc.a $(TBUILD)/$(AREA).mk
	mkdir -p $(TFF)
	$(RUN) -t 120 $(GLIBC_CC) -static -nostdlib -Wl,--allow-multiple-definition -o $@ $(OBJ)/csu/crt1.o $(OBJ)/csu/crti.o $(CRTBEGIN) \
	    $(TFILES_$*:%=$(TOBJ)/%) $(TOBJ)/support/libsupport_nonshared.a \
	    -Wl,--start-group $(TLIBS_$*:%=$(OBJ)/%.a) $(OBJ)/libc.a -lgcc -lgcc_eh -Wl,--end-group $(CRTEND) $(OBJ)/csu/crtn.o

# ttpc's: c2ff of the test's objects and libsupport's, from main, the
# program including glibc in ff (TFF/glibc, a link to FF/glibc), whose
# index says which of the program's weak names glibc defines
.SECONDEXPANSION:
$(TFF)/%-prog.ff: $$(foreach o,$$(TOBJS_$$*),$(TI)/$$(o).c2ff) $(TI)/support.ready $(FF)/glibc/index.ff ../compiler/gen/c2ff.pl ../compiler/gen/Words.pm
	mkdir -p $(TFF)
	ln -sfn $(abspath $(FF))/glibc $(TFF)/glibc
	$(RUN) -t 300 perl ../compiler/gen/c2ff.pl --target $(GTARGET) --program glibc --index $(FF)/glibc/index.ff $(if $(GLIBC_START),,--start) \
	    $(foreach o,$(TOBJS_$*),--object $(TI)/$(o).json=$(TI)/$(o).i) $(foreach o,$(SUPPORT),$(TI)/$(o).json=$(TI)/$(o).i) -- main > $(TFF)/$*-prog.ff.txt
	perl ../compiler/gen/fftext.pl ff $(TFF)/$*-prog.ff.txt > $@

$(TFF)/%-prog: $(TFF)/%-prog.ff $(FF)/glibc/index.ff $(TTPC)
	$(RUN) -t 900 $(TTPC_RUN) $(SHARED) $< $@ > $@.lst

# a test's result: its steps, each to its log, the first that fails the
# result's reason; then the runs (tests.pl run), stdin the test's .input
# where glibc's source has one
TSTEP = $(MAKE) --no-print-directory $(TFF)/$*$(1) > $(TFF)/$*.$(2).log 2>&1 || \
	{ echo "not yet: $(3): $$(perl tests.pl why $(TFF)/$*.$(2).log)" > $@; exit 0; }
$(TFF)/%.result: $(TBUILD)/$(AREA).mk $(TI)/support.ready $(FF)/glibc/index.ff $(TTPC) tests.pl
	@mkdir -p $(TFF)
	@if test -n "$(filter $*,$(TBROKEN))"; then echo "not yet: glibc's build did not make it (TOBJ/$(AREA).log)" > $@; exit 0; fi; \
	$(call TSTEP,.ref,ref,gcc's link); \
	$(call TSTEP,-prog.ff,c2ff,c2ff); \
	$(call TSTEP,-prog,ttpc,ttpc); \
	in=$(GLIBC_SRC)/$(AREA)/$*.input; test -e $$in || in=/dev/null; \
	perl tests.pl run $(TFF) $* $$in $(RUN) -t 600 -- qemu-$(GTARGET) $(CPUS) > $@

# (the .mk first: where glibc's tests build failed, it stops here, before
# a make of each test would try that build again)
tests-ref: $(if $(AREA),$(TBUILD)/$(AREA).mk)
	@test -n "$(AREA)" || { echo "tests-ref: which area? make tests-ref AREA=string"; exit 1; }
	@test -s $(TBUILD)/$(AREA).mk || { echo "tests-ref: no $(TBUILD)/$(AREA).mk"; exit 1; }
	@$(MAKE) --no-print-directory $(TESTS:%=$(TFF)/%.result)
	@perl tests.pl table $(AREA) $(GTARGET) $(TFF) $(TESTS) > $(TBUILD)/$(AREA).table
	@cat $(TBUILD)/$(AREA).table
.PHONY: tests-ref
