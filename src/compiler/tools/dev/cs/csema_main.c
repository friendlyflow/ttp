/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* csema.c: dev source of tools/csema.ff */
#include "c.h"
#include "cs.h"
/* clang's builtins as a unit uses them (their types as clang declares them), then clang-prelude.h's */
static char *builtins[] = {
  "long __builtin_expect (long, long);",
  "_Bool __atomic_always_lock_free (SZ, const volatile void *);",
  "_Bool __atomic_is_lock_free (SZ, const volatile void *);",
  "int __builtin_constant_p ();",
  "unsigned short __builtin_bswap16 (unsigned short);",
  "unsigned int __builtin_bswap32 (unsigned int);",
  "U64 __builtin_bswap64 (U64);",
  "int __builtin_popcount (unsigned int);", "int __builtin_popcountl (unsigned long);", "int __builtin_popcountll (unsigned long long);",
  "int __builtin_ctz (unsigned int);", "int __builtin_ctzl (unsigned long);", "int __builtin_ctzll (unsigned long long);",
  "int __builtin_clz (unsigned int);", "int __builtin_clzl (unsigned long);", "int __builtin_clzll (unsigned long long);",
  "int __builtin_ffs (int);", "int __builtin_ffsl (long);", "int __builtin_ffsll (long long);",
  "int __builtin_parity (unsigned int);", "int __builtin_parityl (unsigned long);", "int __builtin_parityll (unsigned long long);",
  "void *__builtin_mempcpy (void *, const void *, SZ);", "void *__builtin_memcpy (void *, const void *, SZ);",
  "void *__builtin_memmove (void *, const void *, SZ);", "void *__builtin_memset (void *, int, SZ);",
  "int __builtin_memcmp (const void *, const void *, SZ);", "SZ __builtin_strlen (const char *);",
  "char *__builtin_strcpy (char *, const char *);", "char *__builtin_stpcpy (char *, const char *);",
  "int __builtin_strcmp (const char *, const char *);", "char *__builtin_strchr (const char *, int);",
  "void __atomic_thread_fence (int);", "void __atomic_signal_fence (int);",
  "void *__builtin_alloca (SZ);", "void *__builtin_alloca_with_align (SZ, SZ);",
  "void __builtin_unreachable (void) __attribute__ ((__noreturn__));", "void __builtin_trap (void) __attribute__ ((__noreturn__));",
  "void __builtin_abort (void) __attribute__ ((__noreturn__));",
  "_Bool __builtin_add_overflow ();", "_Bool __builtin_sub_overflow ();", "_Bool __builtin_mul_overflow ();",
  "void __builtin_va_start (VA);", "void __builtin_va_end (VA);", "void __builtin_va_copy (VA);",
  "unsigned long long __builtin_ia32_rdtsc (void);", "__float128 __builtin_fabsf128 (__float128);",
  "int __builtin_signbit ();", "int __builtin_isnan ();", "int __builtin_isinf ();", "int __builtin_isinf_sign ();",
  "int __builtin_isfinite ();", "int __builtin_isnormal ();", "int __builtin_issignaling ();",
  "int __builtin_isless ();", "int __builtin_islessequal ();", "int __builtin_isgreater ();", "int __builtin_isgreaterequal ();",
  "int __builtin_isunordered ();", "int __builtin_islessgreater ();",
  "int __builtin_fpclassify (int, int, int, int, int, ...);",
  "void *__builtin_extract_return_addr (void *);", "void *__builtin_return_address (unsigned int);",
  "void *__builtin_frame_address (unsigned int);", "void *__builtin_thread_pointer (void);",
  "long double __builtin_huge_vall (void);", "double __builtin_huge_val (void);", "float __builtin_huge_valf (void);",
  "long double __builtin_infl (void);", "double __builtin_inf (void);", "float __builtin_inff (void);",
  "float __builtin_fmaf (float, float, float);", "double __builtin_fma (double, double, double);",
  "long double __builtin_fmal (long double, long double, long double);",
  "float __builtin_sqrtf (float);", "double __builtin_sqrt (double);", "long double __builtin_sqrtl (long double);",
  "float __builtin_fabsf (float);", "double __builtin_fabs (double);", "long double __builtin_fabsl (long double);",
  "float __builtin_fmodf (float, float);", "double __builtin_fmod (double, double);", "long double __builtin_fmodl (long double, long double);",
  "float __builtin_remainderf (float, float);", "double __builtin_remainder (double, double);", "long double __builtin_remainderl (long double, long double);",
  "float __builtin_copysignf (float, float);", "double __builtin_copysign (double, double);",
  "long double __builtin_copysignl (long double, long double);",
  "float __builtin_nanf (const char *);", "double __builtin_nan (const char *);", "long double __builtin_nanl (const char *);",
  "int __builtin_signbitf (float);", "int __builtin_signbitl (long double);",
  "void __builtin_prefetch (const void *, ...);", "SZ __builtin_object_size (const void *, int);",
  "SZ __builtin_dynamic_object_size (const void *, int);", "void *__builtin_assume_aligned (const void *, SZ, ...);",
  "int __builtin_classify_type ();", "void __builtin___clear_cache (char *, char *);",
  "float __builtin_floorf (float);", "double __builtin_floor (double);", "float __builtin_ceilf (float);", "double __builtin_ceil (double);",
  "float __builtin_truncf (float);", "double __builtin_trunc (double);", "float __builtin_roundf (float);", "double __builtin_round (double);",
  "float __builtin_roundevenf (float);", "double __builtin_roundeven (double);", "float __builtin_rintf (float);", "double __builtin_rint (double);",
  "float __builtin_nearbyintf (float);", "double __builtin_nearbyint (double);",
  "float __builtin_fmaxf (float, float);", "double __builtin_fmax (double, double);", "float __builtin_fminf (float, float);", "double __builtin_fmin (double, double);",
  "long __builtin_lrintf (float);", "long __builtin_lrint (double);", "long long __builtin_llrintf (float);", "long long __builtin_llrint (double);",
  "long __builtin_lroundf (float);", "long __builtin_lround (double);", "long long __builtin_llroundf (float);", "long long __builtin_llround (double);",
  "typedef int __csema_mid;",
  "extern int __builtin_va_arg_pack_len (void);", "extern int __builtin_va_arg_pack (void);",
  "extern double __builtin_tgmath ();",
  "__fp16 __builtin_copysignf16 (__fp16, __fp16);", "_Float16 __builtin_huge_valf16 (void);", "unsigned int __builtin_arm_get_fpscr (void);",
  "extern _Bool __builtin_add_overflow_p (unsigned long, unsigned long, unsigned long);",
  "extern _Bool __builtin_mul_overflow_p (unsigned long, unsigned long, long);",
  0
};
static char *stdc[] = {
  "u leading_zeros", "u leading_ones", "u trailing_zeros", "u trailing_ones", "u first_leading_zero", "u first_leading_one",
  "u first_trailing_zero", "u first_trailing_one", "u count_zeros", "u count_ones", "b has_single_bit", "u bit_width",
  "s bit_floor", "s bit_ceil", "r rotate_left", "r rotate_right", 0
};
static char *utypes[] = { "unsigned char", "unsigned short", "unsigned int", "unsigned long", "unsigned long long", 0 };
static char *pick (int c, char *a, char *b) { if (c) return a; return b; }
static void put (unsigned char *b, long *n, char *s, int target)
{
  while (*s) {
    if (s[0] == 'S' && s[1] == 'Z') { put (b, n, pick (target == 3, "unsigned int", "unsigned long"), 0); s += 2; continue; }
    if (s[0] == 'U' && s[1] == '6' && s[2] == '4') { put (b, n, pick (target == 3, "unsigned long long", "unsigned long"), 0); s += 3; continue; }
    if (s[0] == 'V' && s[1] == 'A' && (s[2] == ')' || s[2] == ' ')) { put (b, n, "__builtin_va_list", 0); s += 2; continue; }
    b[(*n)++] = *s++;
  }
}
/* setjmp and longjmp, each target's (tools/csema-T.ff's _start sets them): what -k cannot translate goes back to the reach */
long cp_jump[2];
/* the unit's text after the prelude, parsed and its semantics worked out; with -l its pass */
static void one_unit (char *file, char *name, int target, int mode)
{
  long bytes = 0, n = 0, i = 0;
  unsigned char *src, *buf;
  struct node *root;
  src = cp_file (file, &bytes);
  buf = alloc (bytes + 65536);
  /* the target's va_list (clang's __builtin_va_list): AAPCS64's and AAPCS's records, the SysV x86_64 one's array */
  if (target == 1) put (buf, &n, "struct __va_list_tag { unsigned int gp_offset; unsigned int fp_offset; void *overflow_arg_area; void *reg_save_area; };\ntypedef struct __va_list_tag __builtin_va_list[1];\n", 0);
  if (target == 2) put (buf, &n, "typedef float __Float32x4_t __attribute__ ((__vector_size__ (16)));\ntypedef double __Float64x2_t __attribute__ ((__vector_size__ (16)));\ntypedef int __SVFloat32_t;\ntypedef int __SVFloat64_t;\ntypedef int __SVBool_t;\ntypedef int __SVInt32_t;\ntypedef int __SVInt64_t;\ntypedef int __SVUint32_t;\ntypedef int __SVUint64_t;\n", 0);
  if (target == 2) put (buf, &n, "struct __va_list { void *__stack; void *__gr_top; void *__vr_top; int __gr_offs; int __vr_offs; };\ntypedef struct __va_list __builtin_va_list;\n", 0);
  if (target == 3) put (buf, &n, "struct __va_list { void *__ap; };\ntypedef struct __va_list __builtin_va_list;\n", 0);
  /* (x86_64's SSE4 units: what gcc's headers call and clangvec.pl leaves) */
  if (target == 1) put (buf, &n, "typedef char __csema_v16qi __attribute__ ((__vector_size__ (16)));\nint __builtin_ia32_pmovmskb128 (__csema_v16qi);\n__csema_v16qi __builtin_ia32_pshufb128 (__csema_v16qi, __csema_v16qi);\n", 0);
  while (builtins[i]) {
    /* (x86_64's va_list an array: its builtins take the pointer it decays to, va_start more) */
    if (target == 1 && same ((unsigned char *) builtins[i], 23, "void __builtin_va_start")) put (buf, &n, "void __builtin_va_start (__builtin_va_list, ...);", 0);
    else if (target == 1 && same ((unsigned char *) builtins[i], 25, "void __builtin_va_copy (V")) put (buf, &n, "void __builtin_va_copy (__builtin_va_list, __builtin_va_list);", 0);
    else put (buf, &n, builtins[i], target);
    buf[n++] = '\n';
    i++;
  }
  i = 0;
  while (stdc[i]) {
    long j = 0;
    while (utypes[j]) {
      char *s = stdc[i];
      put (buf, &n, "extern ", 0);
      if (s[0] == 'u') put (buf, &n, "unsigned int", 0); else if (s[0] == 'b') put (buf, &n, "_Bool", 0); else put (buf, &n, utypes[j], 0);
      put (buf, &n, " __builtin_stdc_", 0);
      put (buf, &n, s + 2, 0);
      put (buf, &n, " (", 0);
      put (buf, &n, utypes[j], 0);
      if (s[0] == 'r') put (buf, &n, ", unsigned int", 0);
      put (buf, &n, ") __attribute__ ((__overloadable__));\n", 0);
      j++;
    }
    i++;
  }
  if (target == 2) put (buf, &n, "extern unsigned int __builtin_aarch64_get_fpcr (void);\nextern void __builtin_aarch64_set_fpcr (unsigned int);\nextern unsigned int __builtin_aarch64_get_fpsr (void);\nextern void __builtin_aarch64_set_fpsr (unsigned int);\n", 0);
  put (buf, &n, "typedef int __csema_end;\n", 0);
  i = 0;
  while (i < bytes) { buf[n + i] = src[i]; i++; }
  root = c_parse (buf, n + bytes, file);
  cs_run (root, buf, n + bytes, n, target, mode, name);
}
/* @file: its lines, the arguments of all of glibc's units and roots */
static char **expand_args (int argc, char **argv, long *count)
{
  long room = argc + 1, n = 0, i = 0;
  char **v;
  long extra = 0;
  unsigned char **texts = alloc (argc * sizeof (unsigned char *));
  long *sizes = alloc (argc * sizeof (long));
  while (i < argc) {
    if (argv[i][0] == '@' && i > 0) {
      long j = 0;
      texts[i] = cp_file (argv[i] + 1, &sizes[i]);
      while (j < sizes[i]) { if (texts[i][j] == '\n') extra++; j++; }
      extra++;
    }
    i++;
  }
  v = alloc ((room + extra) * sizeof (char *));
  i = 0;
  while (i < argc) {
    if (argv[i][0] == '@' && i > 0) {
      long b = 0;
      while (b < sizes[i]) {
        long e;
        while (b < sizes[i] && (texts[i][b] == ' ' || texts[i][b] == '\t')) b++;
        e = b;
        while (e < sizes[i] && texts[i][e] != '\n') e++;
        if (e > b) {
          char *l = alloc (e - b + 1);
          long q = 0;
          while (q < e - b) { l[q] = texts[i][b + q]; q++; }
          v[n] = l;
          n++;
        }
        b = e + 1;
      }
    } else { v[n] = argv[i]; n++; }
    i++;
  }
  *count = n;
  return v;
}
int csema_main (int argc0, char **argv0)
{
  long a = 1, argc;
  char **argv = expand_args (argc0, argv0, &argc);
  int target = 0, mode = 0;
  char *page = "glibc", *gsrc = 0, *lsrc = 0, *shared = 0, *iname = 0, *program = 0, *indexf = 0;
  char **zero = alloc (argc * sizeof (char *)), **weak = alloc (argc * sizeof (char *));
  long nzero = 0, nweak = 0;
  int start = 0, keep_going = 0;
  while (a < argc && argv[a][0] == '-') {
    if (same ((unsigned char *) argv[a], 2, "-d")) mode = 1;
    else if (same ((unsigned char *) argv[a], 2, "-l")) mode = 2;
    else if (same ((unsigned char *) argv[a], 2, "-p") && a + 1 < argc) page = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-s") && a + 1 < argc) gsrc = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-g") && a + 1 < argc) lsrc = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-S") && a + 1 < argc) shared = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-n") && a + 1 < argc) iname = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-P") && a + 1 < argc) program = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-I") && a + 1 < argc) indexf = argv[++a];
    else if (same ((unsigned char *) argv[a], 2, "-T")) start = 1;
    else if (same ((unsigned char *) argv[a], 2, "-k")) keep_going = 1;
    else if (same ((unsigned char *) argv[a], 2, "-M") && a + 2 < argc) {
      /* (-M file GB: the heap in that file, past what memory holds) */
      char *nb = argv[a + 2];
      long gb = 0, q = 0;
      while (nb[q]) { gb = gb * 10 + (nb[q] - '0'); q++; }
      cp_heap_file (argv[a + 1], gb * 1024 * 1024 * 1024);
      a += 2;
    }
    else if (same ((unsigned char *) argv[a], 2, "-Z") && a + 1 < argc) { a++; zero[nzero] = argv[a]; nzero++; }
    else if (same ((unsigned char *) argv[a], 2, "-W") && a + 1 < argc) { a++; weak[nweak] = argv[a]; nweak++; }
    else if (same ((unsigned char *) argv[a], 2, "-t") && a + 1 < argc) {
      char *t = argv[++a];
      long tl = cstrlen (t);
      target = same ((unsigned char *) t, tl, "x86_64") ? 1 : same ((unsigned char *) t, tl, "aarch64") ? 2 : same ((unsigned char *) t, tl, "arm") ? 3 : 0;
    }
    a++;
  }
  if (mode == 2) {
    /* csema -l [-t target] [-p page] [-n name.i] -s GLIBC_SRC [-g LIBGCC_SRC] -S shared.ff file.i root ...: the C layer of what the roots reach from one unit;
       csema -l ... [-O] file.i[=name.i] ... -- root ...: from many, as c2ff.pl's tu.json=tu.i ... -- root ... (-O: the next is an object, its constructors roots) */
    long dd = a, i;
    if (a + 1 >= argc || !shared) { err_str ("usage: csema -l [-t target] [-p page] [-n name.i] -s glibc-src [-g libgcc-src] -S shared.ff file.i root ...\n"); cp_exit (2); }
    /* (an empty one is none) */
    if (gsrc && !gsrc[0]) gsrc = 0;
    if (lsrc && !lsrc[0]) lsrc = 0;
    while (dd < argc && !same ((unsigned char *) argv[dd], cstrlen (argv[dd]), "--")) dd++;
    if (dd == argc) {
      cl_options (page, gsrc, lsrc, shared, argv + a + 1, argc - a - 1);
      cl_options2 (program, indexf, start, zero, nzero, weak, nweak, keep_going);
      if (!iname) iname = argv[a];
      cl_new_unit (iname, 0);
      one_unit (argv[a], iname, target, mode);
    } else {
      int object = 0;
      cl_options (page, gsrc, lsrc, shared, argv + dd + 1, argc - dd - 1);
      cl_options2 (program, indexf, start, zero, nzero, weak, nweak, keep_going);
      i = a;
      while (i < dd) {
        char *f = argv[i], *nm = f;
        long q = 0;
        if (same ((unsigned char *) f, cstrlen (f), "-O")) { object = 1; i++; continue; }
        while (f[q] && f[q] != '=') q++;
        if (f[q]) { f[q] = 0; nm = f + q + 1; }
        cl_new_unit (nm, object);
        object = 0;
        one_unit (f, nm, target, mode);
        i++;
      }
    }
    cl_finish ();
    return 0;
  }
  if (a + 1 != argc) { err_str ("usage: csema [-d] [-t target] file.i\n"); cp_exit (2); }
  one_unit (argv[a], argv[a], target, mode);
  out_flush ();
  return 0;
}
