/* Copyright (C) 2026 Nico Verrijdt
   This file is part of ttp. It is free software: you can redistribute it
   and/or modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation, version 3 of the License.
   It comes with no warranty. See the file LICENSE for the full text.  */

/* cl_a.c (in cs.c): asm statements and the syscall idiom on the other targets: gen/c2ff.pl's asm_stmt_other, asm_ins_other, asm_x87, syscall_idiom_x86 and _arm */
static char *cl_asm_size;   /* x86_64: the size (l, q) of the register output's C type */
static char *cl_retreg (void)
{
  if (C->target == 1) return "rax";
  if (C->target == 2) return "x0";
  return "r0";
}
static char *cl_argreg (long j)
{
  static char *x86[] = { "rdi", "rsi", "rdx", "rcx", "r8", "r9" };
  if (C->target == 1) { if (j < 6) return x86[j]; return 0; }
  if (C->target == 2) { if (j < 8) return cl_cat ("x", cl_num (j)); return 0; }
  if (j < 4) return cl_cat ("r", cl_num (j));
  return 0;
}
static long cl_nargreg (void) { if (C->target == 1) return 6; if (C->target == 2) return 8; return 4; }
static long long cl_sysreg (char *rname0, int *ok)
{
  static char *nm[] = { "fpcr", "fpsr", "tpidr_el0", "tpidrro_el0", "ctr_el0", "tpidr2_el0", "dczid_el0", "midr_el1", "cntvct_el0", "cntfrq_el0", "id_aa64pfr0_el1", "id_aa64pfr1_el1", "id_aa64zfr0_el1", "id_aa64isar0_el1", "id_aa64isar1_el1", "id_aa64mmfr1_el1", 0 };
  static int v[] = { 3,3,4,4,0, 3,3,4,4,1, 3,3,13,0,2, 3,3,13,0,3, 3,3,0,0,1, 3,3,13,0,5, 3,3,0,0,7, 3,0,0,0,0, 3,3,14,0,2, 3,3,14,0,0, 3,0,0,4,0, 3,0,0,4,1, 3,0,0,4,4, 3,0,0,6,0, 3,0,0,6,1, 3,0,0,7,1 };
  char *r = cl_copy ((unsigned char *) rname0, cstrlen (rname0));
  long i = 0;
  *ok = 1;
  while (r[i]) { r[i] = cl_lower (r[i]); i++; }
  i = 0;
  while (nm[i]) {
    if (cl_eq (r, nm[i])) return ((long long) v[5 * i] << 14) | ((long long) v[5 * i + 1] << 11) | ((long long) v[5 * i + 2] << 7) | ((long long) v[5 * i + 3] << 3) | v[5 * i + 4];
    i++;
  }
  /* s3_3_c13_c0_2 */
  if (r[0] == 's' && cl_digit (r[1]) && r[2] == '_' && cl_digit (r[3]) && r[4] == '_' && r[5] == 'c') {
    long a = r[1] - '0', b = r[3] - '0', c = 0, d = 0, at = 6;
    while (cl_digit (r[at])) { c = c * 10 + (r[at] - '0'); at++; }
    if (r[at] == '_' && r[at + 1] == 'c') {
      at += 2;
      while (cl_digit (r[at])) { d = d * 10 + (r[at] - '0'); at++; }
      if (r[at] == '_' && cl_digit (r[at + 1]) && !r[at + 2]) return ((long long) a << 14) | (b << 11) | (c << 7) | (d << 3) | (r[at + 1] - '0');
    }
  }
  *ok = 0;
  return 0;
}
static int cl_is_hexnum (char *s) { long i = 2; if (!(s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) || !s[2]) return 0; while (s[i]) { if (!(cl_digit (s[i]) || (cl_lower (s[i]) >= 'a' && cl_lower (s[i]) <= 'f'))) return 0; i++; } return 1; }
/* %name of a register: its name, else 0 */
static char *cl_pct_reg (char *s)
{
  long i = 1;
  if (s[0] != '%' || !s[1]) return 0;
  while (s[i]) { if (!cl_alpha (s[i]) && !cl_digit (s[i])) return 0; i++; }
  return s + 1;
}
/* -?\d*(%name): its displacement ("" none) and register */
static int cl_x86_mem (char *s, char **disp, char **reg)
{
  long i = 0, e;
  if (s[i] == '-') i++;
  while (cl_digit (s[i])) i++;
  if (s[i] != '(' || s[i + 1] != '%') return 0;
  e = i + 2;
  while (cl_alpha (s[e]) || cl_digit (s[e])) e++;
  if (e == i + 2 || s[e] != ')' || s[e + 1]) return 0;
  *disp = cl_copy ((unsigned char *) s, i);
  *reg = cl_copy ((unsigned char *) s + i + 2, e - i - 2);
  return 1;
}
static int cl_all_pct (char **a, long na) { long i = 0; while (i < na) { if (!cl_pct_reg (a[i])) return 0; i++; } return 1; }
static struct node *cl_pct_node (char *op, char **a, long na)
{
  struct node *n = cl_n (op);
  long i = 0;
  while (i < na) { nd_add (n, cl_n (a[i] + 1)); i++; }
  return n;
}
static int cl_in_words (char *s, char **w) { long i = 0; while (w[i]) { if (cl_eq (s, w[i])) return 1; i++; } return 0; }
static int cl_r_reg (char *s) { long i = 1; if (s[0] != 'r' || !s[1]) return 0; while (s[i]) { if (!cl_digit (s[i])) return 0; i++; } return 1; }
static void cl_ins_other (char *line, struct cl_list *o)
{
  long na;
  char **v = cl_split_ws (line, &na), *op = v[0];
  char **a = v + 1;
  na = na - 1;
  if (C->target == 2) {
    int ok;
    if (cl_eq (op, "mrs") && na == 2) { long long r = cl_sysreg (a[1], &ok); if (ok) { struct node *n = cl_n (op); nd_add (n, cl_num_node (r)); nd_add (n, cl_n (a[0])); cl_push (o, n); return; } }
    if (cl_eq (op, "msr") && na == 2) { long long r = cl_sysreg (a[0], &ok); if (ok) { struct node *n = cl_n (op); nd_add (n, cl_num_node (r)); nd_add (n, cl_n (a[1])); cl_push (o, n); return; } }
    if ((cl_eq (op, "brk") || cl_eq (op, "hlt") || cl_eq (op, "svc")) && na == 1) {
      char *x = a[0];
      if (x[0] == '#') x = x + 1;
      if (cl_is_hexnum (x)) { cl_push (o, cl_n1 (op, cl_num_node (cl_parse_num (x)))); return; }
      if (cl_all_digits (x)) { cl_push (o, cl_n1 (op, cl_n (x))); return; }
    }
    { static char *w[] = { "nop", "yield", "wfe", "wfi", "sev", "sevl", "isb", "clrex", 0 }; if (!na && cl_in_words (op, w)) { cl_push (o, cl_n (op)); return; } }
    if ((cl_eq (op, "dc") || cl_eq (op, "ic")) && na == 2 && a[1][0] == 'x' && cl_all_digits (a[1] + 1)) {
      char *z = cl_copy ((unsigned char *) a[0], cstrlen (a[0]));
      long i = 0;
      while (z[i]) { z[i] = cl_lower (z[i]); i++; }
      if (cl_eq (z, "cvau") || cl_eq (z, "ivau")) { cl_push (o, cl_n1 (cl_cat3 (op, ".", z), cl_n (a[1]))); return; }
    }
    if (cl_eq (op, ".inst") && na == 1) {
      if (cl_is_hexnum (a[0])) { cl_push (o, cl_n1 ("word", cl_num_node (cl_parse_num (a[0])))); return; }
      if (cl_all_digits (a[0])) { cl_push (o, cl_n1 ("word", cl_n (a[0]))); return; }
    }
    /* CALL_LIBC_ARM_ZA_DISABLE's: no frame notes in an asm function, x30 kept around a call */
    if (cl_starts (op, ".cfi_")) return;
    if (cl_eq (op, "mov") && na == 2 && a[0][0] == 'x' && a[0][1] && cl_all_digits (a[0] + 1) && a[1][0] == 'x' && a[1][1] && cl_all_digits (a[1] + 1)) { cl_push (o, cl_ins ("orr", a[1], "xzr", a[0])); return; }
    if (cl_eq (op, "bl") && na == 1) {
      long i = 0;
      while (a[0][i] && (cl_alpha (a[0][i]) || cl_digit (a[0][i]) || a[0][i] == '_')) i++;
      if (i && !a[0][i]) { cl_push (o, cl_n1 ("bl", cl_n1 ("rel", cl_n (a[0])))); return; }
    }
    /* a float or a double loaded from a memory operand (feraiseexcept's ldr s0, %1) */
    if (cl_eq (op, "ldr") && na == 2 && (a[0][0] == 's' || a[0][0] == 'd') && a[0][1] && cl_all_digits (a[0] + 1) && a[1][0] == '[' && a[1][1] == 'x') {
      long e = 2;
      while (cl_digit (a[1][e])) e++;
      if (e > 2 && a[1][e] == ']' && !a[1][e + 1]) {
        struct node *l = cl_n (a[0][0] == 's' ? "ldr.s" : "ldr.d");
        nd_add (l, cl_n ("0"));
        nd_add (l, cl_n (cl_copy ((unsigned char *) a[1] + 1, e - 1)));
        nd_add (l, cl_n (a[0]));
        cl_push (o, l);
        return;
      }
    }
    if (cl_eq (op, "hint") && na == 1) {
      char *x = a[0];
      if (x[0] == '#') x = x + 1;
      if (cl_all_digits (x)) {
        long long h = cl_parse_num (x);
        char *w = 0;
        if (h == 0) w = "nop"; else if (h == 1) w = "yield"; else if (h == 25) w = "paciasp"; else if (h == 29) w = "autiasp"; else if (h == 32) w = "bti"; else if (h == 34) w = "bti.c"; else if (h == 36) w = "bti.j"; else if (h == 38) w = "bti.jc"; else if (h == 40) w = "chkfeat";
        if (w) { cl_push (o, cl_n (w)); return; }
      }
    }
    if ((cl_eq (op, "dmb") || cl_eq (op, "dsb")) && na == 1) {
      static char *b[] = { "oshld", "oshst", "osh", "nshld", "nshst", "nsh", "ishld", "ishst", "ish", "ld", "st", "sy", 0 };
      static int bv[] = { 1, 2, 3, 5, 6, 7, 9, 10, 11, 13, 14, 15 };
      char *z = cl_copy ((unsigned char *) a[0], cstrlen (a[0]));
      long i = 0;
      while (z[i]) { z[i] = cl_lower (z[i]); i++; }
      i = 0;
      while (b[i]) { if (cl_eq (z, b[i])) { cl_push (o, cl_n1 (op, cl_num_node (bv[i]))); return; } i++; }
    }
    if ((cl_eq (op, "fadd") || cl_eq (op, "fsub") || cl_eq (op, "fmul") || cl_eq (op, "fdiv")) && na == 3 && (a[0][0] == 's' || a[0][0] == 'd') && a[0][0] == a[1][0] && a[0][0] == a[2][0] && cl_all_digits (a[0] + 1) && cl_all_digits (a[1] + 1) && cl_all_digits (a[2] + 1)) {
      char w[2];
      w[0] = a[0][0];
      w[1] = 0;
      cl_push (o, cl_ins (cl_cat3 (op, ".", cl_copy ((unsigned char *) w, 1)), a[2], a[1], a[0]));
      return;
    }
  } else if (C->target == 3) {
    static char *words1[] = { "uqsub8", "uadd8", "sel", "clz", "rev", "rev16", "rbit", 0 };
    static char *words2[] = { "and", "eor", "orr", "bic", "add", "sub", "rsb", 0 };
    if (cl_in_words (op, words1) && na >= 2) {
      long i = 0;
      int ok = 1;
      while (i < na) { if (!cl_r_reg (a[i])) ok = 0; i++; }
      if (ok) {
        struct node *n = cl_n (op);
        i = na - 1;
        while (i >= 0) { nd_add (n, cl_n (a[i])); i--; }
        cl_push (o, n);
        return;
      }
    }
    if (cl_in_words (op, words2) && na == 5 && cl_r_reg (a[0]) && cl_r_reg (a[1]) && cl_r_reg (a[2]) && (cl_eq (a[3], "lsl") || cl_eq (a[3], "lsr") || cl_eq (a[3], "asr") || cl_eq (a[3], "ror")) && a[4][0] == '#' && cl_all_digits (a[4] + 1)) {
      struct node *n = cl_n (cl_cat3 (op, ".", a[3]));
      nd_add (n, cl_n (a[4] + 1));
      nd_add (n, cl_n (a[2]));
      nd_add (n, cl_n (a[1]));
      nd_add (n, cl_n (a[0]));
      cl_push (o, n);
      return;
    }
    if (cl_eq (op, "vmrs") && na == 2 && cl_r_reg (a[0]) && cl_eq (a[1], "fpscr")) { cl_push (o, cl_n1 ("vmrs", cl_n (a[0]))); return; }
    if (cl_eq (op, "vmsr") && na == 2 && cl_eq (a[0], "fpscr") && cl_r_reg (a[1])) { cl_push (o, cl_n1 ("vmsr", cl_n (a[1]))); return; }
    if ((cl_eq (op, "ldc") || cl_eq (op, "ldcl")) && na == 3 && cl_eq (a[0], "p10") && cl_eq (a[1], "cr0") && a[2][0] == '[' && a[2][1] == 'r') {
      long l = cstrlen (a[2]);
      if (a[2][l - 1] == ']') {
        cl_push (o, cl_ins ("vldr.f32", "0", cl_copy ((unsigned char *) a[2] + 1, l - 2), cl_eq (op, "ldc") ? "s0" : "s1"));
        return;
      }
    }
    if (cl_eq (op, "cdp") && na == 6 && cl_eq (a[0], "p10") && (cl_eq (a[1], "8") || cl_eq (a[1], "3")) && cl_eq (a[2], "cr0") && cl_eq (a[3], "cr0") && cl_eq (a[4], "cr0") && (cl_eq (a[5], "0") || cl_eq (a[5], "1"))) {
      cl_push (o, cl_ins (cl_eq (a[1], "8") ? "vdiv.f32" : "vadd.f32", cl_eq (a[5], "1") ? "s1" : "s0", "s0", "s0"));
      return;
    }
    if (cl_eq (op, "mrc") && na == 6 && cl_eq (a[0], "p10") && cl_eq (a[1], "7") && cl_r_reg (a[2]) && cl_eq (a[3], "cr1") && cl_eq (a[4], "cr0") && cl_eq (a[5], "0")) { cl_push (o, cl_n1 ("vmrs", cl_n (a[2]))); return; }
  } else if (C->target == 1) {
    static char *words0[] = { "fwait", "hlt", "pause", "nop", "cpuid", "xgetbv", "rdtsc", "mfence", "lfence", "sfence", "fnclex", "fpatan", "syscall", 0 };
    static char *wf[] = { "fnstcw", "fldcw", "fnstsw", 0 };
    static char *wm[] = { "ldmxcsr", "stmxcsr", "fldenv", "fnstenv", 0 };
    static char *wb[] = { "bsr", "bsf", "bswap", "xchg", "lzcnt", "tzcnt", "popcnt", 0 };
    static char *wa[] = { "addl", "addq", "adcl", "adcq", "subl", "subq", "sbbl", "sbbq", "andl", "andq", "orl", "orq", "xorl", "xorq", 0 };
    char *disp, *rg;
    if (cl_eq (op, ".byte") && na) {
      long i = 0;
      int ok = 1;
      while (i < na) { if (!cl_is_hexnum (a[i]) && !cl_all_digits (a[i])) ok = 0; i++; }
      if (ok) { i = 0; while (i < na) { cl_push (o, cl_n1 ("byte", cl_n (a[i]))); i++; } return; }
    }
    if (!na && cl_in_words (op, words0)) { cl_push (o, cl_n (op)); return; }
    if (cl_in_words (op, wf) && na == 1 && cl_x86_mem (a[0], &disp, &rg) && (!disp[0] || cl_eq (disp, "0")) && !cl_eq (rg, "rsp") && !cl_eq (rg, "rbp") && !cl_eq (rg, "r12") && !cl_eq (rg, "r13")) {
      char *nm = op;
      struct node *n;
      if (!(rg[0] == 'r' && cl_digit (rg[1]))) nm = cl_cat (nm, ".n");
      n = cl_n (cl_cat (nm, ".m0"));
      nd_add (n, cl_n ("0"));
      nd_add (n, cl_n (rg));
      cl_push (o, n);
      return;
    }
    if ((cl_eq (op, "xchgl") || cl_eq (op, "xchgq")) && na == 2) {
      long m = 0 - 1;
      if (cl_x86_mem (a[0], &disp, &rg)) m = 0; else if (cl_x86_mem (a[1], &disp, &rg)) m = 1;
      if (m >= 0 && cl_pct_reg (a[1 - m])) {
        struct node *n = cl_n (cl_cat (op, ".mr"));
        nd_add (n, cl_n (cl_pct_reg (a[1 - m])));
        nd_add (n, cl_n (cs_pick (!disp[0], "0", disp)));
        nd_add (n, cl_n (rg));
        cl_push (o, n);
        return;
      }
    }
    if (na && cl_all_pct (a, na)) {
      char *ov = op;
      if (cl_in_words (ov, wb) && cl_asm_size) ov = cl_cat (ov, cl_asm_size);
      {
        long m = cstrlen (ov);
        if (m > 1 && (ov[m - 1] == 'l' || ov[m - 1] == 'q')) {
          char *base = cl_copy ((unsigned char *) ov, m - 1);
          if (cl_in_words (base, wb)) { cl_push (o, cl_pct_node (ov, a, na)); return; }
        }
      }
    }
    if ((cl_eq (op, "divq") || cl_eq (op, "mulq")) && na == 1 && cl_pct_reg (a[0])) { cl_push (o, cl_pct_node (op, a, 1)); return; }
    if (cl_in_words (op, wa) && na == 2 && cl_all_pct (a, 2)) { cl_push (o, cl_pct_node (op, a, 2)); return; }
    if ((cl_eq (op, "mov") || cl_eq (op, "movl") || cl_eq (op, "movq")) && na == 2 && cl_starts (a[0], "%fs:") && cl_all_digits (a[0] + 4)) {
      char *sz = op + 3, *dst = cl_pct_reg (a[1]);
      if (!sz[0] && cl_asm_size) sz = cl_asm_size;
      if (sz[0] && dst && (cl_eq (dst, "rax") || cl_eq (dst, "rbx") || cl_eq (dst, "rcx") || cl_eq (dst, "rdx") || cl_eq (dst, "rsi") || cl_eq (dst, "rdi"))) {
        cl_push (o, cl_n ("fs"));
        if (sz[0] == 'l') {
          struct node *n = cl_n ("movl.n.a32");
          nd_add (n, cl_n (a[0] + 4));
          nd_add (n, cl_n (cl_cat ("e", dst + 1)));
          cl_push (o, n);
        } else {
          struct node *n = cl_n ("movq.a32");
          nd_add (n, cl_n (a[0] + 4));
          nd_add (n, cl_n (dst));
          cl_push (o, n);
        }
        return;
      }
    }
    if (((( cl_eq (op, "vfmadd213ss") || cl_eq (op, "vfmadd213sd")) && na == 3) || ((cl_eq (op, "vfmaddss") || cl_eq (op, "vfmaddsd")) && na == 4)) && cl_all_pct (a, na)) {
      long i = 0;
      int ok = 1;
      while (i < na) { if (!cl_starts (a[i], "%xmm") || !cl_all_digits (a[i] + 4)) ok = 0; i++; }
      if (ok) { cl_push (o, cl_pct_node (cl_cat (op, ".vex3"), a, na)); return; }
    }
    if (cl_in_words (op, wm) && na == 1 && cl_x86_mem (a[0], &disp, &rg)) {
      struct node *n = cl_n (cl_cat (op, ".m"));
      nd_add (n, cl_n (cs_pick (!disp[0], "0", disp)));
      nd_add (n, cl_n (rg));
      cl_push (o, n);
      return;
    }
  }
  cl_fail ("the asm instruction", line);
}
static void cl_asm_tail (char *fn, struct cl_list *d) { (void) fn; (void) d; }
static char *cl_asm_name (struct cl_asm *p, char *extra)
{
  struct cs_buf nm, sg;
  long j = 0;
  char *name, *sig, *old;
  cs_b_init (&nm);
  cl_name_clean (&nm, cl_cat ("__asm_", p->tmpl));
  cs_b_byte (&nm, '_');
  while (j < p->noc) { cl_alnum (&nm, p->oc[j]); j++; }
  if (extra || C->target) cs_b_byte (&nm, '_');
  j = 0;
  while (j < p->nic) { cl_alnum (&nm, p->ic[j]); j++; }
  if (extra) { cs_b_byte (&nm, '_'); cs_b_str (&nm, extra); }
  name = cl_copy (nm.p, nm.n);
  cs_b_init (&sg);
  cs_b_str (&sg, p->tmpl);
  cs_b_str (&sg, " : ");
  j = 0;
  while (j < p->noc) { if (j) cs_b_byte (&sg, ' '); cs_b_str (&sg, p->oc[j]); j++; }
  cs_b_str (&sg, " : ");
  j = 0;
  while (j < p->nic) { if (j) cs_b_byte (&sg, ' '); cs_b_str (&sg, p->ic[j]); j++; }
  if (extra) { cs_b_str (&sg, " : "); cs_b_str (&sg, extra); }
  sig = cl_copy (sg.p, sg.n);
  old = cl_get (&C->asmsig, name);
  if (old && !cl_eq (old, sig)) return cl_asm_sha_name (name, sig);
  cl_put (&C->asmsig, name, sig);
  return name;
}
static char cl_x87_size (struct cs_ex *o)
{
  char *w = cl_tword (o);
  if (cl_eq (w, "long double")) return 't';
  if (cl_eq (w, "double")) return 'l';
  if (cl_eq (w, "float")) return 's';
  cl_fail ("an x87 asm operand of a", w);
  return 0;
}
static void cl_x87 (struct cs_st *n, struct cl_asm *p, struct cl_list *o)
{
  struct cs_ex **ops = n->ops;
  long t0 = 0 - 1, un = 0 - 1, j = 0, order[3], nord = 0, k = 0;
  struct cl_list *code = cl_l ();
  char sz[8], *tmpl = p->tmpl;
  int blank = 1;
  if (p->noc != 1 || !(cl_eq (p->oc[0], "=t") || cl_eq (p->oc[0], "=&t"))) cl_fail ("the asm constraints of the x87", p->oc[0]);
  while (j < p->nic) {
    char *c = p->ic[j];
    if ((cl_eq (c, "0") || cl_eq (c, "t")) && t0 < 0) t0 = 1 + j;
    else if (cl_eq (c, "u") && un < 0) un = 1 + j;
    else cl_fail ("the asm constraint of the x87", c);
    j++;
  }
  j = 0;
  while (tmpl[j]) { if (!cl_space (tmpl[j])) blank = 0; j++; }
  if (blank) {
    struct cl_list *in = cl_l ();
    if (t0 < 0 || un >= 0) cl_fail ("an empty x87 asm statement but of 0", 0);
    cl_push (in, cl_atom (ops[t0]));
    if (!cl_eq (cl_tword (ops[0]), cl_tword (ops[t0]))) { struct node *c = cl_cast_node (cl_ct (ops[0]->t), in); in = cl_l (); cl_push (in, c); }
    cl_itemx (ops[0], o);
    cl_push (o, cl_n ("="));
    cl_append (o, in);
    return;
  }
  j = 0;
  while (j < n->nops) {
    struct cs_ex *e = cl_strip (ops[j]);
    if (!(e->k == E_REF || e->k == E_MEM || e->k == E_IDX || (e->k == E_UN && cl_name_is (e, "*")))) cl_fail ("an x87 asm operand that is no variable", 0);
    j++;
  }
  if (un >= 0) { order[nord] = un; nord++; }
  if (t0 >= 0) { order[nord] = t0; nord++; }
  order[nord] = 0;
  nord++;
  j = 0;
  while (j < nord) { sz[j] = cl_x87_size (ops[order[j]]); j++; }
  sz[nord] = 0;
  while (k < nord - 1) {
    struct node *m = cl_n (cl_cat3 ("fld", cl_copy ((unsigned char *) sz + k, 1), ".m"));
    nd_add (m, cl_n ("0"));
    nd_add (m, cl_n (cl_argreg (k)));
    cl_push (code, m);
    k++;
  }
  {
    /* %% to %; its instructions, ; apart */
    struct cs_buf b;
    char *t;
    static char *words0[] = { "fpatan", "frndint", "f2xm1", "fscale", "fyl2x", "fyl2xp1", "fxtract", "fld1", "fldz", "fchs", "fabs", "fsqrt", "fprem", "fprem1", 0 };
    static char *words1[] = { "fld", "fxch", "fadd", "fsub", "fmul", "fdiv", 0 };
    static char *words2[] = { "faddp", "fmulp", "fsubp", "fsubrp", "fdivp", "fdivrp", 0 };
    cs_b_init (&b);
    j = 0;
    while (tmpl[j]) { if (tmpl[j] == '%' && tmpl[j + 1] == '%') j++; cs_b_byte (&b, tmpl[j]); j++; }
    t = cl_copy (b.p, b.n);
    j = 0;
    while (t[j]) {
      long e = j, na;
      char *line, **v;
      while (t[e] && t[e] != ';') e++;
      line = cl_copy ((unsigned char *) t + j, e - j);
      v = cl_split_ws (line, &na);
      if (na) {
        char *op = v[0];
        long st = 0 - 1;
        if (na == 2 && cl_starts (v[1], "%st")) {
          char *r = v[1] + 3;
          if (!r[0]) st = 0;
          else if (r[0] == '(' && cl_digit (r[1]) && r[2] == ')' && !r[3]) st = r[1] - '0';
        }
        if (cl_in_words (op, words0) && na == 1) cl_push (code, cl_n (op));
        else if (cl_eq (op, "fstp") && st >= 0) {
          if (st == 0) cl_push (code, cl_n ("fstp.st0"));
          else cl_push (code, cl_n1 ("fstp", cl_n (cl_cat ("st", cl_num (st)))));
        }
        else if (cl_in_words (op, words1) && st >= 0) cl_push (code, cl_n1 (op, cl_n (cl_cat ("st", cl_num (st)))));
        else if (cl_in_words (op, words2) && na == 1) cl_push (code, cl_n1 (op, cl_n ("st1")));
        else cl_fail ("the x87 asm instruction", line);
      }
      j = e;
      if (t[j] == ';') j++;
    }
  }
  {
    struct node *m = cl_n (cl_cat3 ("fstp", cl_copy ((unsigned char *) sz + nord - 1, 1), ".m"));
    nd_add (m, cl_n ("0"));
    nd_add (m, cl_n (cl_argreg (nord - 1)));
    cl_push (code, m);
  }
  if (un >= 0 && !p->clob1) cl_push (code, cl_n ("fstp.st0"));
  {
    char *name = cl_asm_name (p, sz);
    struct cl_list *args = cl_l ();
    if (!cl_val (&C->asmfn, name)) {
      struct cl_list *d = cl_l ();
      cl_set (&C->asmfn, name);
      cl_push (d, cl_n ("asm"));
      cl_push (d, cl_n1 ("comment", cl_n (cl_cat3 ("glibc's asm statement \"", tmpl, "\" of the x87"))));
      cl_append (d, code);
      cl_push (d, cl_n ("ret"));
      cl_out (cl_nl (cl_cat (name, ":"), d));
    }
    j = 0;
    while (j < nord) { cl_push (args, cl_n1 ("address", cl_atom (ops[order[j]]))); j++; }
    cl_push (o, cl_nl (name, args));
  }
}
/* a want of asm_stmt_other */
enum { AW_VALUE, AW_ADDRESS, AW_MEM, AW_XIN, AW_XOUT };
struct cl_want { long i; int how; char *r; long j; int hasj; };
static void cl_asm_other (struct cs_st *n, struct cl_list *o)
{
  struct cl_asm p;
  struct cs_ex **ops = n->ops;
  long nops = n->nops, i = 0, nw = 0, ret = 0 - 1, xn = 0, second = 0;
  char **text = alloc ((nops + 1) * sizeof (char *));
  char **xr = alloc ((nops + 1) * sizeof (char *)), *xw = alloc (nops + 1);
  struct cl_want *w = alloc ((nops + 1) * sizeof (struct cl_want));
  struct cl_list *code = cl_l (), *after = cl_l ();
  int blank = 1, x86 = C->target == 1;
  char *tmpl;
  long nreg = cl_nargreg ();
  long argi[128];
  int arghow[128];
  long maxarg = 0 - 1;
  long scratch_at = 0;
  char *scratch[2];
  cl_asm_ops (n, &p);
  tmpl = p.tmpl;
  i = 0;
  while (tmpl[i]) { if (!cl_space (tmpl[i])) blank = 0; i++; }
  /* an empty template whose outputs are all read and written changes nothing */
  if (blank && p.noc) {
    int all = 1;
    i = 0;
    while (i < p.noc) {
      char *c = p.oc[i];
      long q = 0;
      if (!cl_has_plus (c)) all = 0;
      while (c[q] == '=' || c[q] == '+' || c[q] == '&') q++;
      if (!c[q]) all = 0;
      while (c[q]) { if (c[q] != 'r' && c[q] != 'x' && !(C->target == 2 && c[q] == 'w')) all = 0; q++; }
      i++;
    }
    if (all) return;
  }
  if ((x86 || (C->target == 2 && nops)) && blank && !p.noc) {
    int all = 1;
    i = 0;
    while (i < nops) { if (!cl_pure (ops[i]) || (!x86 && !cl_eq (cl_tword (ops[i]), "long double"))) all = 0; i++; }
    if (all) return;
  }
  if (x86) {
    i = 0;
    while (i < p.noc) {
      char *c = p.oc[i];
      long q = 0;
      while (c[q] == '=' || c[q] == '&') q++;
      if (c[q] == 't' && !c[q + 1]) { cl_x87 (n, &p, o); return; }
      i++;
    }
  }
  cl_asm_size = 0;
  if (x86 && p.noc) {
    long f = 0 - 1;
    i = 0;
    while (i < p.noc && f < 0) {
      char *k = cl_constraint_clean (p.oc[i]);
      if (cl_eq (k, "r") || cl_eq (k, "rm") || cl_eq (k, "q")) f = i;
      i++;
    }
    if (f >= 0) {
      struct cl_list *tw = cl_ct (ops[f]->t);
      char *t = cl_join (tw);
      if (cl_eq (t, "long") || cl_eq (t, "u64") || cl_eq (t, "i64") || cl_is (tw->v[0], "address")) { if (tw->n == 1 || cl_is (tw->v[0], "address")) cl_asm_size = "q"; }
      else if (cl_eq (t, "int") || cl_eq (t, "u32") || cl_eq (t, "i32")) cl_asm_size = "l";
    }
  }
  i = 0;
  while (i < nops) {
    int out = i < p.noc;
    char *c = out ? p.oc[i] : p.ic[i - p.noc];
    char *k = cl_constraint_clean (c);
    char *fx = 0;
    if (x86) {
      struct cs_buf b;
      long q = 0;
      cs_b_init (&b);
      while (k[q]) { if (k[q] != '%') cs_b_byte (&b, k[q]); q++; }
      k = cl_copy (b.p, b.n);
      if (cl_eq (k, "rm") || cl_eq (k, "g") || cl_eq (k, "rme") || cl_eq (k, "re") || cl_eq (k, "rmi") || cl_eq (k, "ri")) k = "r";
      if (cl_eq (k, "a")) fx = "rax"; else if (cl_eq (k, "b")) fx = "rbx"; else if (cl_eq (k, "d")) fx = "rdx"; else if (cl_eq (k, "c")) fx = "rcx"; else if (cl_eq (k, "S")) fx = "rsi"; else if (cl_eq (k, "D")) fx = "rdi";
    }
    w[nw].i = i;
    w[nw].r = 0;
    w[nw].hasj = 0;
    if (x86 && !blank && (cl_eq (k, "x") || cl_eq (k, "xm") || (cl_digit (k[0]) && !k[1] && !out && xr[k[0] - '0']))) {
      char *tw = cl_tword (ops[i]);
      if (cl_has_plus (c)) cl_fail ("the asm constraint", c);
      if (!cl_eq (tw, "float") && !cl_eq (tw, "double")) cl_fail ("the asm operand of a", tw);
      if (cl_digit (k[0])) { xr[i] = xr[k[0] - '0']; xw[i] = xw[k[0] - '0']; }
      else { xr[i] = cl_cat ("xmm", cl_num (xn)); xn++; xw[i] = cl_eq (tw, "float") ? 's' : 'd'; }
      text[i] = xr[i];
      w[nw].how = out ? AW_XOUT : AW_XIN;
      nw++;
      i++;
      continue;
    }
    if (out && fx) {
      if (cl_has_plus (c)) cl_fail ("the asm constraint", c);
      w[nw].how = AW_ADDRESS;
      nw++;
      text[i] = fx;
    } else if (out && (cl_eq (k, "r") || (x86 && cl_eq (k, "x")))) {
      if (ret >= 0 && x86 && !cl_has_plus (c) && !second) {
        second = 1;
        w[nw].how = AW_ADDRESS;
        nw++;
        text[i] = "r11";
        i++;
        continue;
      }
      if (ret >= 0) cl_fail ("an asm statement with two register outputs", 0);
      ret = i;
      text[i] = cl_retreg ();
      if (cl_has_plus (c)) { w[nw].how = AW_VALUE; w[nw].r = cl_retreg (); nw++; }
    } else if (!out && cl_digit (k[0]) && !k[1]) {
      char *r = text[k[0] - '0'];
      if (!r) cl_fail ("the asm constraint", c);
      w[nw].how = AW_VALUE;
      w[nw].r = r;
      nw++;
    } else if (!out && fx) {
      w[nw].how = AW_VALUE;
      w[nw].r = fx;
      nw++;
      text[i] = fx;
    } else if (!out && (cl_eq (k, "r") || (x86 && cl_eq (k, "x")))) {
      w[nw].how = AW_VALUE;
      nw++;
    } else if (!out && cl_eq (k, "w") && C->target == 2) {
      w[nw].how = AW_VALUE;
      w[nw].r = "w";
      nw++;
    } else if (cl_eq (k, "m")) {
      w[nw].how = AW_MEM;
      nw++;
    } else cl_fail ("the asm constraint", c);
    i++;
  }
  /* the arguments: one that goes to a register that is an argument's is that argument; the others in turn */
  {
    int taken[128];
    long q = 0, nxt = 0, fpn = 0;
    while (q < 128) { taken[q] = 0; argi[q] = 0 - 1; q++; }
    q = 0;
    while (q < nw) {
      if (w[q].r) {
        long s = 0;
        while (s < nreg) { if (cl_eq (cl_argreg (s), w[q].r)) { if (!taken[s]) { w[q].j = s; w[q].hasj = 1; taken[s] = 1; } break; } s++; }
      }
      q++;
    }
    q = 0;
    while (q < nw) {
      if (!w[q].hasj && !(C->target == 2 && w[q].r && cl_eq (w[q].r, "w"))) {
        while (taken[nxt]) nxt++;
        w[q].j = nxt;
        w[q].hasj = 1;
        taken[nxt] = 1;
        nxt++;
      }
      q++;
    }
    q = 0;
    while (q < nw) { if (!w[q].hasj) { w[q].j = 100 + fpn; w[q].hasj = 1; fpn++; } q++; }
    q = 0;
    while (q < nw) { if (w[q].j >= nreg && w[q].j < 100) cl_fail ("an asm statement with too many operands", 0); q++; }
    if (fpn > 8) cl_fail ("an asm statement with too many operands", 0);
  }
  if (second) { scratch[0] = "r10"; scratch[1] = 0; } else { scratch[0] = "r10"; scratch[1] = "r11"; }
  {
    long pos = 0;
    while (pos < 128) {
      long q = 0;
      while (q < nw) {
        if (w[q].j == pos) {
          long ix = w[q].i;
          char *r = w[q].r, *a = 0;
          int how = w[q].how;
          if (pos < 100) a = cl_argreg (pos);
          argi[pos] = ix;
          arghow[pos] = how == AW_VALUE;
          if (pos > maxarg) maxarg = pos;
          if (how == AW_XIN || how == AW_XOUT) {
            char *sfx = xw[ix] == 's' ? "s" : "d";
            if (how == AW_XIN) { struct node *m = cl_n (cl_cat3 ("movs", sfx, ".n.m0")); nd_add (m, cl_n ("0")); nd_add (m, cl_n (a)); nd_add (m, cl_n (xr[ix])); cl_push (code, m); }
            else { struct node *m = cl_n (cl_cat3 ("movs", sfx, ".n.m0r")); nd_add (m, cl_n (xr[ix])); nd_add (m, cl_n ("0")); nd_add (m, cl_n (a)); cl_push (after, m); }
          } else if (how == AW_ADDRESS) {
            struct cl_list *tw = cl_ct (ops[ix]->t);
            char *t = cl_join (tw), *sz = 0;
            long v = 0;
            int inuse = 0;
            if (!x86) cl_fail ("the asm output of that target", p.oc[ix]);
            if (cl_eq (t, "int") || cl_eq (t, "u32") || cl_eq (t, "i32")) sz = "l";
            else if (cl_eq (t, "long") || cl_eq (t, "u64") || cl_eq (t, "i64") || cl_ends (t, " address") || cl_ends (t, " pointer") || cl_eq (t, "address") || cl_eq (t, "pointer")) sz = "q";
            else cl_fail ("the asm output of a", t);
            while (v < nops) { if (text[v] && cl_eq (text[v], a)) inuse = 1; v++; }
            if (inuse) {
              char *kk = scratch_at < 2 ? scratch[scratch_at] : 0;
              struct node *m;
              if (!kk) cl_fail ("an asm statement with too many outputs", 0);
              scratch_at++;
              m = cl_n ("movq");
              nd_add (m, cl_n (a));
              nd_add (m, cl_n (kk));
              cl_unshift1 (code, m);
              a = kk;
            }
            {
              struct node *m = cl_n (cl_cat3 ("mov", sz, ".mr"));
              nd_add (m, cl_n (text[ix]));
              nd_add (m, cl_n ("0"));
              nd_add (m, cl_n (a));
              cl_push (after, m);
            }
          } else if (how == AW_MEM) {
            if (x86) text[ix] = cl_cat3 ("0(%", a, ")");
            else text[ix] = cl_cat3 ("[", a, "]");
          } else if (r && cl_eq (r, "w")) {
            char *tw = cl_tword (ops[ix]), *pp;
            long fk = pos - 100, vv = 16 + fk;
            struct node *m;
            if (!cl_eq (tw, "float") && !cl_eq (tw, "double")) cl_fail ("the asm operand w of a", tw);
            pp = cs_pick (cl_eq (tw, "float"), "s", "d");
            m = cl_n (cl_cat ("fmov.", pp));
            nd_add (m, cl_n (cl_cat (pp, cl_num (fk))));
            nd_add (m, cl_n (cl_cat (pp, cl_num (vv))));
            cl_push (code, m);
            text[ix] = cl_cat (pp, cl_num (vv));
          } else if (r && !cl_eq (r, a)) {
            if (C->target == 2) { struct node *m = cl_n ("orr"); nd_add (m, cl_n (a)); nd_add (m, cl_n ("xzr")); nd_add (m, cl_n (r)); cl_push (code, m); }
            else { struct node *m = cl_n ("movq"); nd_add (m, cl_n (a)); nd_add (m, cl_n (r)); cl_push (code, m); }
          } else if (!text[ix]) text[ix] = a;
        }
        q++;
      }
      pos++;
    }
  }
  {
    /* the template: x86's %v, gcc's dialects, its operands, %% */
    struct cs_buf b;
    char *t, *t2;
    long j = 0;
    cs_b_init (&b);
    while (tmpl[j]) {
      if (tmpl[j] == '%' && tmpl[j + 1] == 'v') { j += 2; continue; }
      cs_b_byte (&b, tmpl[j]);
      j++;
    }
    t = cl_copy (b.p, b.n);
    cs_b_init (&b);
    j = 0;
    while (t[j]) {
      if (t[j] == '{') {
        long e = j + 1, bar = 0 - 1;
        while (t[e] && t[e] != '}') { if (t[e] == '|' && bar < 0) bar = e; e++; }
        if (t[e] == '}') {
          long stop = bar >= 0 ? bar : e, q = j + 1;
          while (q < stop) { cs_b_byte (&b, t[q]); q++; }
          j = e + 1;
          continue;
        }
      }
      cs_b_byte (&b, t[j]);
      j++;
    }
    t = cl_copy (b.p, b.n);
    cs_b_init (&b);
    j = 0;
    while (t[j]) {
      if (t[j] == '%') {
        long m = j + 1, v = 0, ds;
        char mod = 0;
        if (t[m] >= 'a' && t[m] <= 'z') { mod = t[m]; m++; }
        ds = m;
        while (cl_digit (t[m])) { v = v * 10 + (t[m] - '0'); m++; }
        if (m > ds) {
          char *r;
          if (v >= nops || !text[v]) cl_fail ("the asm operand", t);
          r = text[v];
          if (mod == 'w' && r[0] == 'x' && cl_all_digits (r + 1)) r = cl_cat ("w", r + 1);
          else if (mod && !(mod == 's' && r[0] == 's' && cl_digit (r[1])) && !(mod == 'd' && r[0] == 'd' && cl_digit (r[1])) && !(mod == 'x' && r[0] == 'x' && cl_digit (r[1]))) cl_fail ("the asm operand of that modifier", t);
          if (x86) {
            long q = 0;
            int paren = 0;
            while (r[q]) { if (r[q] == '(') paren = 1; q++; }
            if (!paren) cs_b_byte (&b, '%');
          }
          cs_b_str (&b, r);
          j = m;
          continue;
        }
      }
      cs_b_byte (&b, t[j]);
      j++;
    }
    t2 = cl_copy (b.p, b.n);
    cs_b_init (&b);
    j = 0;
    while (t2[j]) { if (t2[j] == '%' && t2[j + 1] == '%') j++; cs_b_byte (&b, t2[j]); j++; }
    t = cl_copy (b.p, b.n);
    j = 0;
    while (t[j]) {
      long e = j, x;
      char *line;
      int empty = 1;
      while (t[e] && t[e] != ';') e++;
      line = cl_copy ((unsigned char *) t + j, e - j);
      x = 0;
      while (line[x]) { if (!cl_space (line[x])) empty = 0; x++; }
      if (!empty) cl_ins_other (line, code);
      j = e;
      if (t[j] == ';') j++;
    }
    cl_append (code, after);
  }
  {
    char *name = cl_asm_name (&p, 0);
    struct cl_list *args = cl_l ();
    struct node *cnode;
    long j = 0, last = maxarg < 99 ? maxarg : 0 - 1;
    if (!cl_val (&C->asmfn, name)) {
      struct cl_list *d = cl_l ();
      cl_set (&C->asmfn, name);
      cl_push (d, cl_n ("asm"));
      cl_push (d, cl_n1 ("comment", cl_n (cl_cat3 ("glibc's asm statement \"", tmpl, "\""))));
      cl_append (d, code);
      cl_push (d, cl_n ("ret"));
      cl_out (cl_nl (cl_cat (name, ":"), d));
    }
    if (maxarg >= 100) {
      /* (the last below 100) */
      last = 0 - 1;
      j = 0;
      while (j < 100) { if (argi[j] >= 0) last = j; j++; }
    }
    j = 0;
    while (j < 128) {
      if (argi[j] >= 0) {
        if (arghow[j]) cl_push (args, cl_atom (ops[argi[j]]));
        else cl_push (args, cl_n1 ("address", cl_atom (ops[argi[j]])));
      } else if (j <= last) cl_push (args, cl_n ("0"));
      j++;
    }
    cnode = cl_nl (name, args);
    if (ret >= 0) { cl_itemx (ops[ret], o); cl_push (o, cl_n ("=")); }
    cl_push (o, cnode);
  }
}
/* arm's: register variables rname0 (or a1), a2 a3 a4 v1 v2 v3 the arguments, r7 the number, the asm swi 0x0 */
static long cl_arm_argno (char *r)
{
  if (cl_eq (r, "r0") || cl_eq (r, "a1")) return 0;
  if (cl_eq (r, "r1") || cl_eq (r, "a2")) return 1;
  if (cl_eq (r, "r2") || cl_eq (r, "a3")) return 2;
  if (cl_eq (r, "r3") || cl_eq (r, "a4")) return 3;
  if (cl_eq (r, "r4") || cl_eq (r, "v1")) return 4;
  if (cl_eq (r, "r5") || cl_eq (r, "v2")) return 5;
  if (cl_eq (r, "r6") || cl_eq (r, "v3")) return 6;
  return 0 - 1;
}
static void cl_syscall_arm (struct cs_st *cs, struct cl_list *o, int *found)
{
  struct cs_st *as = 0;
  struct cl_asm p;
  struct cl_map regof, reg, locals;
  long i = 0;
  regof.tab = 0; regof.count = 0; reg.tab = 0; reg.count = 0; locals.tab = 0; locals.count = 0;
  while (i < cs->nk) { if (cs->kid[i]->k == S_ASM) { as = cs->kid[i]; break; } i++; }
  if (!as) return;
  cl_asm_ops (as, &p);
  {
    char *t = p.tmpl;
    while (cl_space (*t)) t++;
    if (!cl_starts (t, "swi") || !cl_space (t[3])) return;
    t = t + 3;
    while (cl_space (*t)) t++;
    if (!cl_starts (t, "0x0") || cl_alpha (t[3]) || cl_digit (t[3])) return;
  }
  if (p.noc != 1 || !cl_eq (p.oc[0], "=r")) return;
  i = 0;
  while (i < cs->nk) {
    struct cs_st *s = cs->kid[i];
    if (s->k == S_DECL) {
      struct cs_dl *x = s->dl;
      while (x) {
        struct cs_decl *v = x->d;
        if (x->kind == 0 && v) {
          if (v->sp && v->sp->asmlabel) { cl_put (&regof, cl_dn (v), v->sp->asmlabel); if (v->init) cl_put (&reg, v->sp->asmlabel, v->init); }
          else if (v->init && v->name) cl_put (&locals, cl_dn (v), v->init);
        }
        x = x->nxt;
      }
    }
    i++;
  }
  i = 0;
  while (i < cs->nk) {
    struct cs_st *s = cs->kid[i];
    if (s->k == S_EXPR && s->e->k == E_BIN && cl_name_is (s->e, "=")) {
      struct cs_ex *l = cl_strip (cl_k (s->e, 0));
      if (l->k == E_REF && cl_has (&regof, cl_dn (l->d))) cl_put (&reg, cl_get (&regof, cl_dn (l->d)), cl_k (s->e, 1));
    }
    i++;
  }
  if (!cl_has (&reg, "r7")) cl_fail ("a syscall without its number", 0);
  {
    struct cl_list *x = cl_l ();
    struct cs_ex *byno[8];
    long a = 0;
    static char *rn[] = { "r0", "a1", "r1", "a2", "r2", "a3", "r3", "a4", "r4", "v1", "r5", "v2", "r6", "v3", 0 };
    while (a < 8) { byno[a] = 0; a++; }
    a = 0;
    while (rn[a]) { struct cs_ex *e = cl_get (&reg, rn[a]); if (e) byno[cl_arm_argno (rn[a])] = e; a++; }
    cl_itemx (cl_p (cl_get (&reg, "r7")), x);
    a = 0;
    while (a <= 6) {
      struct cs_ex *e = byno[a], *s;
      if (!e) break;
      e = cl_p (e);
      s = cl_strip (e);
      if (s->k == E_REF && cl_has (&locals, cl_dn (s->d))) e = cl_p (cl_get (&locals, cl_dn (s->d)));
      cl_itemx (e, x);
      a++;
    }
    cl_push (o, cl_nl ("syscall", x));
    *found = 1;
  }
}
/* x86_64's: register variables rdi rsi rdx r10 r8 r9 = the arguments, the asm syscall with the number in the output's place */
static void cl_syscall_x86 (struct cs_st *cs, struct cl_list *o, int *found)
{
  struct cs_st *as = 0;
  struct cl_asm p;
  struct cl_map reg, locals;
  long i = 0, nother = 0, num = 0 - 1;
  struct cs_st *other = 0;
  struct cs_ex **ops;
  reg.tab = 0; reg.count = 0; locals.tab = 0; locals.count = 0;
  while (i < cs->nk) { if (cs->kid[i]->k == S_ASM) { as = cs->kid[i]; break; } i++; }
  if (!as) return;
  cl_asm_ops (as, &p);
  ops = as->ops;
  {
    /* /^\s*syscall[\s;]*$/ */
    char *t = p.tmpl;
    while (cl_space (*t)) t++;
    if (!cl_starts (t, "syscall")) return;
    t = t + 7;
    while (cl_space (*t) || *t == ';') t++;
    if (*t) return;
  }
  if (p.noc != 1 || !cl_eq (p.oc[0], "=a")) return;
  i = 0;
  while (i < cs->nk) { if (cs->kid[i]->k != S_DECL && cs->kid[i]->k != S_ASM) { if (!other) other = cs->kid[i]; nother++; } i++; }
  {
    struct cs_ex *oute = cl_strip (ops[0]);
    struct cs_ex *last = other && other->k == S_EXPR ? cl_strip (cl_p (other->e)) : 0;
    while (last && (last->k == E_CAST || last->k == E_PAREN)) last = cl_strip (cl_k (last, 0));
    if (nother > 1) return;
    if (nother && (other != cs->kid[cs->nk - 1] || !last || last->k != E_REF || oute->k != E_REF || last->d != oute->d)) return;
  }
  i = 0;
  while (i < p.nic) { if (cl_eq (p.ic[i], "0")) { num = i; break; } i++; }
  if (num < 0) cl_fail ("a syscall without its number", 0);
  i = 0;
  while (i < cs->nk) {
    struct cs_st *s = cs->kid[i];
    if (s->k == S_DECL) {
      struct cs_dl *x = s->dl;
      while (x) {
        struct cs_decl *v = x->d;
        if (x->kind == 0 && v && v->init) {
          if (v->sp && v->sp->asmlabel) {
            char *nm = cl_dn (v);
            static char *rr[] = { "rdi", "rsi", "rdx", "r10", "r8", "r9" };
            if (nm[0] == '_' && nm[1] == 'a' && nm[2] >= '1' && nm[2] <= '6' && !nm[3]) cl_put (&reg, rr[nm[2] - '1'], v->init);
          } else if (v->name) cl_put (&locals, cl_dn (v), v->init);
        }
        x = x->nxt;
      }
    }
    i++;
  }
  i = 0;
  while (i < p.nic) {
    char *c = p.ic[i];
    char *r = 0;
    if (cl_eq (c, "D")) r = "rdi"; else if (cl_eq (c, "S")) r = "rsi"; else if (cl_eq (c, "d")) r = "rdx";
    if (r) cl_put_new (&reg, r, ops[p.noc + i]);
    i++;
  }
  {
    struct cl_list *x = cl_l ();
    static char *argr[] = { "rdi", "rsi", "rdx", "r10", "r8", "r9", 0 };
    long a = 0;
    cl_itemx (ops[p.noc + num], x);
    while (argr[a]) {
      struct cs_ex *e = cl_get (&reg, argr[a]), *s;
      if (!e) break;
      e = cl_p (e);
      s = cl_strip (e);
      if (s->k == E_REF && cl_has (&locals, cl_dn (s->d))) e = cl_p (cl_get (&locals, cl_dn (s->d)));
      cl_itemx (e, x);
      a++;
    }
    cl_push (o, cl_nl ("syscall", x));
    *found = 1;
  }
}
